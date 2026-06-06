local tf_lang, UpdateTFLanguageStrings, GetTFLanguageString
if CLIENT then
	UpdateTFLanguageStrings = function(lang)
		tf_lang = file.Read("resource/tf_english.txt", "tf")
		tf_lang = util.KeyValuesToTable(tf_lang, true, false).tokens
		local langs = { //list of gmod-supported languages from https://wiki.facepunch.com/gmod/Addon_Localization#supportedlanguages
			bg = "bulgarian",
			cs = "czech",
			da = "danish",
			de = "german",
			el = "greek",
			//en = "english",
			["en-PT"] = "pirate",
			["es-ES"] = "spanish", //tf2 also has tf_latam
			//et 	Estonian
			fi = "finnish",
			fr = "french",
			//he 	Hebrew
			//hr 	Croatian
			hu = "hungarian",
			it = "italian",
			ja = "japanese",
			ko = "korean", //tf2 has both tf_korean and tf_koreana translations available, what's the difference? is this the right one to use?
			//lt 	Lithuanian
			nl = "dutch",
			no = "norwegian",
			pl = "polish",
			["pt-BR"] = "brazilian",
			["pt-PT"] = "portuguese",
			ru = "russian",
			//sk 	Slovak
			["sv-SE"] = "swedish",
			th = "thai",
			tr = "turkish",
			uk = "ukrainian",
			//vi 	Vietnamese
			["zh-CN"] = "schinese",
			["zh-TW"] = "tchinese"
		}
		if langs[lang] then
			lang = file.Read("resource/tf_" .. langs[lang] ..".txt", "tf")
			lang = util.KeyValuesToTable(lang, true, false).tokens
			table.Merge(tf_lang, lang)
		end
		//MsgN("language is now ", lang)
		//note: conveniently, the context menu and all of its contents are reset upon changing languages, so we don't have to worry 
		//about resetting the browser to prevent odd behavior caused by controls still using values from the previous language
	end
	cvars.AddChangeCallback("gmod_language", function(_,_,new) UpdateTFLanguageStrings(new) end, "TF2ItemBrowser")
	UpdateTFLanguageStrings(GetConVar("gmod_language"):GetString())

	GetTFLanguageString = function(str, return_str_on_fail)
		local result = ""
		if return_str_on_fail then result = str end
		if !isstring(str) then return result end

		result = tf_lang[string.TrimLeft(string.lower(str), "#")] or result
		return result
	end
end










local classes = {"(any)", "scout", "soldier", "pyro", "demoman", "heavy", "engineer", "medic", "sniper", "spy", "none"}
//our favorite black scottish cyclops is called "demoman" in all item definition keys (used_by_classes, model_player_per_class, etc.), 
//"demo" in model paths, and either one interchangably in equip region names. dumb!!!
for k, v in ipairs (classes) do
	local shortname = v
	if v == "demoman" then shortname = "demo" end
	classes[k] = {shortname = shortname, longname = v}
end


local _s = file.Read("scripts/items/items_game.txt", "tf")
local s = util.KeyValuesToTable(_s, false, true)
local s2 = util.KeyValuesToTablePreserveOrder(_s, false, true)


//inject custom values into a few items
s.prefabs.paintkit_base._paintkit = true //custom value for filter
s.prefabs.tournament_medal._tm = true //custom value for filter

//TODO:
//
//these items have existing models in the files, but aren't assigned in the schema; add them anyway
//models/props_halloween/flask_bottle.mdl
//models/props_halloween/flask_erlenmeyer.mdl
//models/props_halloween/flask_florence.mdl
//models/props_halloween/flask_tub.mdl
//models/props_halloween/flask_tube.mdl
//models/props_halloween/flask_vial.mdl
//models/props_halloween/hwn_spellbook_incomplete.mdl
//models/props_halloween/hwn_spellbook_page.mdl
//models/props_halloween/hwn_spellbook_magazine.mdl
//models/workshop/cases/invasion_case/invasion_key.mdl
//models/crafting/halloween2015_gargoyle_key.mdl
//models/crafting/ticket_summer2015.mdl
//models/crafting/ticket_tough_break.mdl
//models/player/items/crafting/bundle_of_taunts.mdl //eehh, broken materials
//models/player/items/crafting/crate_variation.mdl //eehh, broken materials
//maybe change spy watches to use these instead, just because they spawn better; the default models are viewmodels so they aren't attachable either way
//models/weapons/c_models/c_spy_watch.mdl
//models/weapons/c_models/c_leather_watch/parts/c_leather_watch.mdl
//models/weapons/c_models/c_pocket_watch/parts/c_pocket_watch.mdl
//
//maybe better backpack icons for:
//28 TF_WEAPON_BUILDER - this is called "PDA" but its model is engi's toolbox
//1155 TF_WEAPON_PASSTIME GUN - this is the pass time jack, currently uses wrench icon
//1057 MvM GateBotLight Scout (and the others) - missing textures
//30143 tw_demobot_armor (and the others) - placeholder white circle
//
//just remove v.static_attrs.paintkit_proto_def_index from 9536 Paintkit, to make the paintkit filter below run faster
//all eyelander reskins have an australium style that doesn't do anything, get rid of these
//maybe inject a value into most stock weapons to tell it to get rid of the team selector unless it's relevant (i.e. festivized)


//Make items inherit values from prefabs, which themselves inherit values from other prefabs, and so on
local tab = {}
local function InheritPrefabValues(k, v, ptab, ptabname)
	//Go through prefabs of prefabs recursively
	if ptab.prefab then
		for k2, v2 in ipairs (string.Explode(" ", ptab.prefab)) do
			if !s.prefabs[v2] then MsgN("TF2ItemSchema: ", k, " ", v.name, ptabname, " tried to get invalid prefab \"", v2, "\"") continue end
			InheritPrefabValues(k, v, s.prefabs[v2], ptabname .. " " .. v2)
		end
	end
	for k2, v2 in pairs (ptab) do
		--[[if tab[k][k2] != nil and tab[k][k2] != v2 then
			if istable(tab[k][k2]) and istable(v2) then
				MsgN(k, " ", v.name, ":", ptabname, " overrid table ", k2)
				PrintTable(tab[k][k2])
				MsgN("with values from")
				PrintTable(v2)
			else
				MsgN(k, " ", v.name, ":", ptabname, " overrid value ", k2, " from ", tab[k][k2], " to ", v2)
			end			
		end]]
		if istable(tab[k][k2]) and istable(v2) then
			//If both values are tables, don't just squash the whole table with the new one, instead only replace values that changed
			table.Merge(tab[k][k2], v2)
		elseif istable(v2) then
			tab[k][k2] = table.Copy(v2)
		else
			tab[k][k2] = v2
		end
	end
	//TODO: try tab2 test again, just using table.Merge(tab2[k], ptab)
end
for k, v in pairs (s.items) do
	tab[k] = {}
	InheritPrefabValues(k, v, v, "")
end
s.items = tab


//test: get all possible keys in item tables
--[[local t = {}
for k, v in pairs (s.items) do
	local function tabletest(tabletofill, tabletocheck, dospew)
		for k, v in pairs (tabletocheck) do
			tabletofill[k] = tabletofill[k] or {}
			if istable(v) and k != "bundle" and k != "attributes" then
				tabletest(tabletofill[k], tabletocheck[k])
			end
		end
	end
	tabletest(t, v)
end
PrintTable(t)]]


local bad_values = {"public_prefab", "qc_template", "triangle_budget_lod0", "triangle_budget_lod1", "triangle_budget_lod2"}
local visuals_tabs = {"visuals", "visuals_red", "visuals_blu"}
local used_equip_regions = {}
local items_by_name = {}

for k, v in pairs (s.items) do
	//clear useless items
	if v.equip_type == "account" //contracts
	or (v.static_attrs and v.static_attrs.paintkit_proto_def_index and (v.item_class != "tool" or v.static_attrs.paintkit_proto_def_index > 0)) //war paint items; the second part is a hack because the generic paintkit base item (which we want) uses protodef 0, but so does the first pre-JI pre-skinned weapon, 15013 concealedkiller_pistol_redrockroscoe, which we don't want
	then 
		s.items[k] = nil
		continue
	end

	//save memory by clearing useless values
	for _, k in pairs (bad_values) do
		v[k] = nil
	end


	//Some items have a singular equip_region string instead of an equip_regions table; make these all uniform
	if !v.equip_regions and isstring(v.equip_region) then //If equip_region (singular) is a table instead of a string, it isn't applied (example: 30238 Chicken Kiev) https://wiki.teamfortress.com/wiki/Equip_region#Bugs
		v.equip_regions = {[v.equip_region] = 1}
	end
	v.equip_region = nil
	//Also check which equip regions are actually used, so we can filter out unused ones (soldier_gloves, spy_coat)
	if v.equip_regions then
		for k, _ in pairs (v.equip_regions) do
			used_equip_regions[k] = true
		end
	end


	//1067 The Grandmaster has the unique item_class value "tf_wearable_levelable_item", which makes it cycle through bodygroups 
	//as the player gets kills (https://wiki.teamfortress.com/wiki/Grandmaster); catch these and turn them into styles instead
	if v.item_class == "tf_wearable_levelable_item" then
		//dumb hard-coded silliness - this one item definition has a single defined style,
		//so make our custom killstreak styles all variants of this one style
		local base_style = table.Copy(v.visuals.styles[0])
		for i = 0, 5 do
			local tab = {
				bodygroup = {name = "level", submodel_index = i}
			}
			if CLIENT then tab.name = GetTFLanguageString("TF_ScoreBoard_KillsLabel", true) .. " " .. i end
			table.Merge(tab, base_style)
			v.visuals.styles[i] = tab
		end
		//Note: 1899 World Traveler has unique value visuals.code_controlled_bodygroup which we could also convert to styles, but this is unused 
		//in TF2 and the bodygroup submodels are a bit broken, so ignore this (https://wiki.teamfortress.com/wiki/World_Traveler%27s_Hat)
	end
	//Clear visuals tables that don't contain anything useful, so that we can clear out items with no useful visual 
	//data at the end of this function (example: noisemakers have "visuals" tables containing only sound paths)
	for _, v2 in pairs (visuals_tabs) do
		if v[v2] then
			if !(v[v2].attached_models or v[v2].attached_models_festive or v[v2].attached_particlesystems or v[v2].material_override 
			or v[v2].playback_activity or v[v2].player_bodygroups or v[v2].player_poseparam or v[v2].skin or v[v2].styles 
			or v[v2].use_per_class_bodygroups or v[v2].wm_bodygroup_override) then
				v[v2] = nil
			end
		end
		//Note: there's also a fourth table, visuals_mvm_boss, which contains overrides used only by 
		//mvm giants, but the 2 instances of this only contain sounds, so we don't care about these
	end


	//TODO: handle extra_wearable and extra_wearable_vm:
	//- if an item only has an extra_wearable and not a model_player(_per_class), then change it into one (a few spellbooks)
	//- if an item has an extra_wearable that's the same as its model_player, then get rid of it (sniper shields, maybe more)
	//- if an item has an extra_wearable_vm, then get rid of its extra_wearable and convert the _vm to visuals.attached_models (botkillers)


	if v.model_player == "" then v.model_player = nil end
	if v.model_player then
		//Some items like cases have valid models to spawn but no class; dump these into a special "none" class category
		//(all of these use model_player, none of them use model_player_per_class)
		if !v.used_by_classes then 
			v.used_by_classes = {none = 1}
		end
	end
	//clear items that still have no class assigned after the above check, which means they have no model (these are items that only exist 
	//in the backpack like tools, craft items, stamps, most crates+keys); also clear items that have a class assigned, but have no model or 
	//other visual data (store bundles, invisible action items like damaged capacitor, class craft tokens)
	if !v.used_by_classes then
		//MsgN("group 1: ", k, " ", v.name)
		s.items[k] = nil
	elseif (!v.model_player and !v.model_player_per_class and !v.extra_wearable and !v.visuals and !v.taunt) then
		//MsgN("group 2: ", k, " ", v.name)
		s.items[k] = nil
	end


	//Item sets and collections list items by name, not id, so they need to be able to retrieve the item id by name
	items_by_name[v.name] = k
end


//s.equip_regions has multiple "shared" keys that are subtables filled with many different class-specific strings, but these get clobbered by util.KeyValuesToTable, 
//so we have to rescue them. also use this chance to get the implementation order, because it makes the equip region list look nicer.
local tab = {}
for _, class in ipairs (classes) do //sort these by class so we can filter them easily + print class-based ones in class order
	tab[class.longname] = {}
end
//Also use this opportunity to process item sets and collections in implementation order
local sets = {}
local collections = {}

for k, v in ipairs (s2) do
	if v.Key == "equip_regions_list" then
		for k2, v2 in ipairs (v.Value) do
			if istable(v2.Value) then
				for k3, v3 in pairs (v2.Value) do
					for _, class in ipairs (classes) do
						if string.StartsWith(v3.Key, class.shortname) or string.StartsWith(v3.Key, class.longname) then
							if used_equip_regions[v3.Key] then table.insert(tab[class.longname], v3.Key) end
							break
						end
					end
						
				end
			else
				if used_equip_regions[v2.Key] then table.insert(tab["(any)"], v2.Key) end
			end
		end
	elseif v.Key == "item_sets" then
		for k2, v2 in ipairs (v.Value) do
			local add_set = false //exclude sets that don't contain any spawnable items
			for k3, _ in pairs (s.item_sets[v2.Key].items) do
				if s.items[items_by_name[k3]] then
					add_set = true
					s.items[items_by_name[k3]]._item_set = v2.Key
					//Also keep track of which classes we should show this set for
					s.item_sets[v2.Key]._classes = s.item_sets[v2.Key]._classes or {}
					for k, _ in pairs (s.items[items_by_name[k3]].used_by_classes) do
						s.item_sets[v2.Key]._classes[k] = true
					end
				end
			end
			if add_set then table.insert(sets, v2.Key) end
		end
	elseif v.Key == "item_collections" then
		for k2, v2 in ipairs (v.Value) do
			local add_set = false //exclude sets that don't contain any spawnable items
			for k3, v3 in pairs (s.item_collections[v2.Key].items) do
				//collections are either formatted as a table of items like sets,
				//or a table of item subtables sorted by rarity.
				if istable(v3) then
					for k4, _ in pairs (v3) do
						if s.items[items_by_name[k4]] then
							add_set = true
							s.items[items_by_name[k4]]._item_collection = v2.Key
							s.items[items_by_name[k4]]._rarity = k3
							//Also keep track of which classes we should show this set for
							s.item_collections[v2.Key]._classes = s.item_collections[v2.Key]._classes or {}
							for k, _ in pairs (s.items[items_by_name[k4]].used_by_classes) do
								s.item_collections[v2.Key]._classes[k] = true
							end
						end
					end
				else
					if s.items[items_by_name[k3]] then
						add_set = true
						s.items[items_by_name[k3]]._item_collection = v2.Key
						//Also keep track of which classes we should show this set for
						s.item_collections[v2.Key]._classes = s.item_collections[v2.Key]._classes or {}
						for k, _ in pairs (s.items[items_by_name[k3]].used_by_classes) do
							s.item_collections[v2.Key]._classes[k] = true
						end
					end
				end
			end
			if add_set then table.insert(collections, v2.Key) end
		end
	end
end
s.equip_regions_list = tab


TF2Items = s










//Convenience funcs for accessing item info

local function GetVisualsValue(i, team, val)
	//note: some team-specific tables contain a "use_visualsblock_as_base" value but this doesn't seem to change anything; 
	//judging by quickfix/vaccinator, the team-specific tables always fall back to using values from the main visuals table
	if !team and i.visuals_red and i.visuals_red[val] then
		return i.visuals_red[val]
	elseif team and i.visuals_blu and i.visuals_blu[val] then
		return i.visuals_blu[val]
	elseif i.visuals and i.visuals[val] then
		return i.visuals[val]
	end
end

local function GetClassModelWithBasename(tab, class)
	//note: if this table contains both basename and class-specific strings, the class-specific ones take priority
	//(example: 987 The Merc's Muffler has a manually defined "engineer" path with ".../all_winter_scarf_engy.mdl",
	//so it doesn't use basename to auto-generate one with ".../all_winter_scarf_engineer.mdl" like the other classes)
	if !tab then
		return
	elseif tab[class] then
		return tab[class]
	elseif tab.basename then
		for _, _class in ipairs (classes) do
			if class == _class.longname then
				return string.Replace(tab.basename, "%s", _class.shortname)
			end
		end
	end
end

//Given an item id, class, team, and style, return the model, skin, and bodygroups to use.
local function GetItemModelVisuals(i, class, team, style)

	i = TF2Items.items[i]
	local model, skin, item_bg, ply_bg = nil, nil, {}, {}

	//First go through standard values on the item
	model = GetClassModelWithBasename(i.model_player_per_class, class) or i.model_player
	skin = i.default_skin or GetVisualsValue(i, team, "skin")
	local classbg = GetVisualsValue(i, team, "use_per_class_bodygroups")
	if classbg and classbg == 1 then
		classbg = {scout = 0, sniper = 1, soldier = 2, demoman = 3, medic = 4, heavy = 5, pyro = 6, spy = 7, engineer = 8}
		item_bg["class"] = classbg[class]
	end
	for k, v in pairs (GetVisualsValue(i, team, "player_bodygroups") or {}) do
		ply_bg[k] = v //v can be 0, such as in prefab item_bak_fear_monger
	end
	local num_bg_k, num_bg_v = GetVisualsValue(i, team, "wm_bodygroup_override"), GetVisualsValue(i, team, "wm_bodygroup_state_override")
	if num_bg_k and num_bg_v then
		//only used by 528 The Short Circuit and 524 The Purity Fist; this key is a bodygroup id number instead
		//of a bodygroup name, so we'll have to add special handling just for these two items, oh boy!
		ply_bg[num_bg_k] = num_bg_v
	end
	//note: there's also visuals.show_player_bodygroup_name, only used by 1098 The Classic with value "bullets"; 
	//i don't think this does anything, because if it did, it would make the classic show the sleeper's darts

	//Now get overrides from style
	if i.visuals and i.visuals.styles then //this is never contained in visuals_red/visuals_blu
		style = i.visuals.styles[style]
		if !team and style.model_player_per_class_red then
			model = GetClassModelWithBasename(style.model_player_per_class_red, class)
		elseif team and style.model_player_per_class_blue then
			model = GetClassModelWithBasename(style.model_player_per_class_blue, class)
		elseif style.model_player_per_class then
			model = GetClassModelWithBasename(style.model_player_per_class, class)
		elseif style.model_player then
			model = style.model_player
		end
		//note: 1033 The TF2VRH has a unique style.model_player_per_class_alt table for alternate models to use in vr mode, but 
		//there's already a second style that uses these alternate models regardless, so this is useless, we don't care about it
		if !team and style.skin_red then
			skin = style.skin_red
		elseif team and style.skin_blu then
			skin = style.skin_blu
		elseif style.skin then
			skin = style.skin
		end
		if style.bodygroup then
			//currently it's only possible to have to change one bodygroup at a time
			item_bg[style.bodygroup.name] = style.bodygroup.submodel_index
		end
		if style.additional_hidden_bodygroups then
			for k, v in pairs (style.additional_hidden_bodygroups) do
				ply_bg[k] = v
			end
		end
	end

	if skin == nil then
		if !team then skin = 0 else skin = 1 end //by default, red team uses skin 0, and blu team uses skin 1
	end
	if model then
		skin = math.min(skin, util.GetModelInfo(model).SkinCount - 1)
	else
		model = ""
	end

	return model, skin, item_bg, ply_bg

end










local BrowserInputs, BrowserInputs_bits, WriteItemDataTable, ReadItemDataTable //define these here so that window/icon code can access them

if CLIENT then

	local LoadoutItemPopupBorder = GWEN.CreateTextureBorder(0, 0, 64, 64, 11, 11, 11, 11, Material("vgui/button_holder_central.vmt"))
	local GrayDialogBorder = GWEN.CreateTextureBorder(0, 0, 256, 128, 24, 24, 24, 24, Material("vgui/loadout_rect.vmt"))
	local TFThinLineBorder = GWEN.CreateTextureBorder(0, 0, 128, 128, 24, 24, 24, 24, Material("hud/tournament_panel_brown.vmt"))
	local OutlinedGreyBox = GWEN.CreateTextureBorder(0, 0, 128, 64, 24, 24, 24, 0, Material("vgui/loadout_round_rect_selected.vmt"))
	local item_icon_w = 64
	local item_icon_scale = item_icon_w/121 //tf2 backpack panels are 121x94 (???); scale ours down proportionately
	local item_icon_h = 94*item_icon_scale
	local item_icon_gap = 5
	local betweenitems = 8
	local betweencategories = 20
	local spinner = Material("vgui/animated/tf2_logo_hourglass.vmt")
	local close_button = Material("vgui/close_button.vmt")
	surface.CreateFont("TF2ItemBrowser_ItemName", {
		font = "TF2 Build",
		size = 20, //these are really wimpy units; this matches the size of the item names when spectating players
		extended = true
	})
	surface.CreateFont("TF2ItemBrowser_ItemDesc", {
		font = "TF2 Secondary",
		size = 18, //on the tf2 backpack screen, desc text is 15px high, but to match our smaller item name text, this is 11px high instead
		extended = true
	})
	local gui_colors = {
		bgcol		= Color(42,39,37,255), //eyedropped from tf2 loadout screen, don't know what the material is
		RedSolid	= Color(192,28,0,255),
	}
	local quality_colors = {
		normal		= Color(178,178,178,255),
		rarity1		= Color(77,116,85,255), //genuine
		rarity2		= Color(141,131,75,255), //"customized (unused)""
		rarity3		= Color(204,204,250,255), //"artisan"
		rarity4		= Color(134,80,172,255), //unusual
		vintage		= Color(71,98,145,255),
		unique		= Color(255,215,0,255),
		community	= Color(112,176,74,255),
		developer	= Color(165,15,121,255),
		selfmade	= Color(112,176,74,255),
		customized	= Color(71,98,145,255),
		strange		= Color(207,106,50,255),
		completed	= Color(134,80,172,255),
		haunted		= Color(56,243,171,255),
		collectors	= Color(170,0,0,255),
		paintkitweapon	= Color(250,250,250,255),
	}
	local rarity_colors = {
		default		= Color(131,126,119,255),
		common		= Color(176,195,217,255),
		uncommon	= Color(94,152,217,255),
		rare		= Color(75,105,255,255),
		mythical	= Color(136,71,255,255),
		legendary	= Color(211,44,230,255),
		ancient		= Color(235,75,75,255),
	}
	local desc_colors = {
		level		= Color(117,107,94,255),
		neutral		= Color(235,226,202,255),
		positive	= Color(153,204,255,255),
		negative	= Color(255,64,64,255),
		--[[ItemSetName		= Color(225,255,15,255),
		ItemSetItemEquipped	= Color(149,175,12,255),
		ItemSetItemMissing	= Color(139,137,137,255),
		ItemIsotope		= Color(225,255,15,255),
		ItemBundleItem		= Color(149,175,12,255),
		ItemLimitedUse		= Color(0,160,0,255),
		ItemFlag		= Color(117,107,94,255),]]
		ItemLimitedQuantity	= Color(225,209,0,255),
	}
	local snd_hover = "ui/item_info_mouseover.wav"
	local snd_click = "tf_buttonclick.wav" //custom path because this gets overridden by hl2 sound
	local snd_release = "tf_buttonclickrelease.wav" //^
	local function AddTFButtonSounds(pnl)
		function pnl:OnCursorEntered()
			surface.PlaySound(snd_hover)
		end
		function pnl:OnDepressed()
			surface.PlaySound(snd_click)
		end
		function pnl:OnReleased()
			surface.PlaySound(snd_release)
		end
	end

	//dubiously appropriated from https://gist.github.com/Be1zebub/26b5d8e8ee5ead9a92f691aa2cdf58b5
	local GetTextSize = surface.GetTextSize
	local sub, gsub = string.sub, string.gsub
	local function charWrap(text, remainingWidth, maxWidth)
		local totalWidth = 0

		text = gsub(text, ".", function(char)
			totalWidth = totalWidth + GetTextSize(char)

			if totalWidth >= remainingWidth then
				totalWidth = GetTextSize(char)
				remainingWidth = maxWidth
				return "\n" .. char
			end

			return char
		end)

		return text, totalWidth
	end
	local function textWrap(text, font, maxWidth)
		local totalWidth = 0

		surface.SetFont(font)
		local spaceWidth = GetTextSize(" ")

		text = gsub(text, "(%s?[%S]+)", function(word)
			local char = sub(word, 1, 1)
			if char == "\n" or char == "\t" then
				totalWidth = 0
			end

			local wordlen = GetTextSize(word)
			totalWidth = totalWidth + wordlen

			if wordlen >= maxWidth then
				local splitWord, splitPoint = charWrap(word, maxWidth - (totalWidth - wordlen), maxWidth)
				totalWidth = splitPoint
				return splitWord
			elseif totalWidth < maxWidth then
				return word
			end

			if char == " " then
				totalWidth = wordlen - spaceWidth
				return "\n" .. sub(word, 2)
			end

			totalWidth = wordlen
			return "\n" .. word
		end)

		return text
	end

	
	CreateClientConVar("cl_tf2itembrowser_advbone", "0", true, false, "Use advanced bonemerge to attach items", 0, 1)

	list.Set("DesktopWindows", "TF2ItemBrowser", {
		title		= "TF2 Items", //"TF2 Item Browser" is just ever-so-slighly too long to fit, hrmph
		icon		= "games/16/tf.png", //TODO: temp, make one that's the correct size later
		width		= 935,
		height		= 650,
		onewindow	= true,
		init		= function(widgetIcon, window)

			window:SetTitle("TF2 Item Browser")
			window:SetIcon("games/16/tf.png")

			local right_holder = vgui.Create("DPanel", window)
			right_holder.Paint = function() end
			local scroll = vgui.Create("DScrollPanel", right_holder)
			right_holder:SetWide(scroll.VBar:GetWide() + ((item_icon_w+item_icon_gap)*10))
			right_holder:Dock(RIGHT)
			scroll:Dock(FILL)

			local iconlist = vgui.Create("DPanel", scroll) //(note: this was a DIconLayout before, but since we already know the size of every icon, it's a lot faster to just use simple math to set the list height and icon locations, instead of all the performance-heavy size calculations used by DIconLayout)
			iconlist.Paint = function() end

			local old_OnChildAdded = scroll.OnChildAdded
			scroll.OnChildAdded = nil //don't dock the loading icon inside the scroll panel, just place it on top of it
			local iconlist_loading = vgui.Create("DPanel", scroll)
			iconlist_loading:Dock(FILL)
			//iconlist_loading:SetZPos(10) //this needs to render above the iconlist
			iconlist_loading:SetMouseInputEnabled(false)
			function iconlist_loading:Paint(w, h)
				if !window.icons_to_add then return end

				local w, h = scroll:GetSize()
				surface.SetDrawColor(gui_colors.bgcol.r, gui_colors.bgcol.g, gui_colors.bgcol.b, 192)
				surface.DrawRect(0,0,w,h)
	
				local mid_w, mid_h = (w-scroll.VBar:GetWide()-item_icon_gap)/2, h/2
				GrayDialogBorder(mid_w-50, mid_h-50, 100, 100)
				surface.SetMaterial(spinner)
				surface.DrawTexturedRect(mid_w-50, mid_h-50, 100, 100)
				//TODO: this is okay, but i want to do better. add a progress bar and text listing tostring(window.icons_to_add_key-1) .. "/" .. tostring(#window.icons_to_add)
			end
			scroll.OnChildAdded = old_OnChildAdded


			local left_holder = vgui.Create("DPanel", window)
			left_holder:DockPadding(24,24,24,24)
			left_holder:Dock(FILL)

			function left_holder:Paint(w,h)
				TFThinLineBorder(0,0,w,h)
			end

			local filters = vgui.Create("DScrollPanel", left_holder)
			filters:Dock(FILL)
			window.filters = filters


			TF2ItemBrowser = window
			function window:Paint(w, h)
				surface.SetDrawColor(gui_colors.bgcol)
				surface.DrawRect(0,0,w,h)
			end
			window:SetSizable(true)
			local p1, _, p2, _ = window:GetDockPadding()
			local p3, _, p4, _ = left_holder:GetDockPadding()
			window:SetMinWidth(p1 + p2 + p3 + p4 + filters.VBar:GetWide() + scroll:GetWide())


			//ugly temporary filter options

			local search = vgui.Create("DTextEntry", filters)
			search:SetHeight(20)
			search:Dock(TOP)
			search:DockMargin(0,0,0,betweencategories)
			search:SetPlaceholderText("#spawnmenu.search")
			search:SetTooltip("#spawnmenu.enter_search")
			filters.search = search
			search.OnEnter = function()
				window.RebuildIconList()
			end
			local searchbutton = search:Add("DImageButton")
			searchbutton:SetImage("icon16/magnifier.png")
			searchbutton:Dock(RIGHT)
			searchbutton:DockMargin(4,2,4,2)
			searchbutton:SetSize(16,16)
			searchbutton:SetTooltip("#spawnmenu.press_search")
			searchbutton.DoClick = function()
				search.OnEnter()
			end

			local function AddDropdownFilter(label, populatefunc, select_extras)
				local drop = vgui.Create("Panel", filters)
				drop.Label = vgui.Create("DLabel", drop)
				drop.Label:SetText(label)
				drop.Label:Dock(LEFT)
				drop.Combo = vgui.Create("DComboBox", drop)
				drop.Combo:SetHeight(25)
				drop.Combo:Dock(FILL)
				drop:SetHeight(25)
				drop:Dock(TOP)
				drop:DockMargin(0,0,0,betweenitems)
				function drop.PerformLayout(_, w, h)
					drop.Label:SetWide(w / 2.4)
				end
				drop.Combo:SetSortItems(false)
				populatefunc(drop.Combo)
				function drop.Combo.OnSelect(_, index, value, data)
					if select_extras then select_extras() end
					window.RebuildIconList()
				end
				function drop.Combo:OnMenuOpened(menu)
					//Add a checkmark to the currently selected option.
					//GetChild uses the number of children including spacers, while SetSelectedID uses the number of children
					//not including spacers, so we have to loop through the whole list like this until we've gone through enough
					//non-spacer children to find the correct one.
					local sel = drop.Combo:GetSelectedID()
					local sel_read = 0
					for i = 1, menu:ChildCount() do
						local child = menu:GetChild(i)
						if child:GetName() == "DMenuOption" then
							sel_read = sel_read + 1
							if sel_read == sel then
								child:SetChecked(true)
								break
							end
						end
					end
				end
				return drop.Combo
			end

			filters.class = AddDropdownFilter("Class", function(self)
				for k, v in ipairs (classes) do //add all classes in order
					self:AddChoice(string.NiceName(v.longname), v.longname, v.longname == "(any)")
					if k == 1 or k == 10 then self:AddSpacer() end
				end
			end, function() 
				filters.equip_region:RebuildControls()
				filters.item_set:RebuildControls()
			end)

			filters.item_type = AddDropdownFilter("Item Type", function(self) 
				for k, v in ipairs ({"(any)", "weapon", "cosmetic", "taunt", "other"}) do
					self:AddChoice(string.NiceName(v), v, v == "(any)")
					if k == 1 then self:AddSpacer() end
				end
			end)

			local equip_regions_populate = function(self)
				local _, old_choice = self:GetSelected()
				old_choice = old_choice or "(any)"
				self.IsRebuilding = true
				self:Clear()
				self:AddChoice("(any)", "(any)", old_choice == "(any)")
				for _, class in ipairs (classes) do //add class-based equip regions in class order
					//If we have a class selected, filter out equip regions for other classes
					local _, selected_class = filters.class:GetSelected()
					selected_class = selected_class or "(any)"
					if selected_class == "(any)" or class.longname == "(any)" or selected_class == class.longname then
						self:AddSpacer()
						for k, v in ipairs (TF2Items.equip_regions_list[class.longname]) do
							self:AddChoice(string.NiceName(v), v, old_choice == v)
						end
					end
				end
				//if we had a class-specific region selected, and then switched to a class that doesn't have it, revert to "(any)"
				local _, check = self:GetSelected()
				if check == nil then self:ChooseOptionID(1) end
				self.IsRebuilding = nil
			end
			filters.equip_region = AddDropdownFilter("Equip Region", equip_regions_populate)
			filters.equip_region.RebuildControls = equip_regions_populate //make this func externally accessible so we can rebuild it when picking a new class

			local item_sets_populate = function(self)
				local _, old_choice = self:GetSelected()
				old_choice = old_choice or "(any)"
				self.IsRebuilding = true
				self:Clear()
				self:AddChoice("(any)", "(any)", old_choice == "(any)")
				//If we have a class selected, only show sets containing items for that class
				local _, selected_class = filters.class:GetSelected()
				selected_class = selected_class or "(any)"
				local added_spacer = false
				for _, v in ipairs (sets) do
					if selected_class == "(any)" or TF2Items.item_sets[v]._classes[selected_class] then
						if !added_spacer then self:AddSpacer() added_spacer = true end
						self:AddChoice(GetTFLanguageString(TF2Items.item_sets[v].name, true) or v, v, old_choice == v)
					end
				end
				added_spacer = false
				for _, v in ipairs (collections) do
					if selected_class == "(any)" or TF2Items.item_collections[v]._classes[selected_class] then
						if !added_spacer then self:AddSpacer() added_spacer = true end
						self:AddChoice(GetTFLanguageString(TF2Items.item_collections[v].name, true) or v, v, old_choice == v)
					end
				end
				//if we had a class-specific set selected, and then switched to a class that doesn't have it, revert to "(any)"
				local _, check = self:GetSelected()
				if check == nil then self:ChooseOptionID(1) end
				self.IsRebuilding = nil
			end
			filters.item_set = AddDropdownFilter("Set/Collection", item_sets_populate)
			filters.item_set:GetParent():DockMargin(0,0,0,betweencategories)
			filters.item_set.RebuildControls = item_sets_populate //make this func externally accessible so we can rebuild it when picking a new class
			
			local check = vgui.Create("DCheckBoxLabel", filters)
			check:SetText("Hide conflicting items")
			check:SetHeight(15)
			check:Dock(TOP)
			check:DockMargin(0,0,0,betweencategories)
			filters.conflicting = check
			//TODO: gray this out or something unless we're in equip mode, because the concept of conflicting items only applies there
			check.OnChange = function(_, val)
				//TODO: update filters? or just set visibilty of existing panels? this option might be impractical, DIconLayout doesn't like it when icons start off hidden.
			end

			local function AddIncludeExcludeFilter(label) //variant of checkboxes with both (+ (must include)) and (- (must exclude)) options
				local self = vgui.Create("DPanel", filters)
				self:SetTall(15)
				self.Button1 = vgui.Create("DCheckBox", self)
				self.Button1.OnChange = function(_, val) self:OnChange(val, self.Button1) end
				self.Button2 = vgui.Create("DCheckBox", self)
				self.Button2.OnChange = function(_, val) self:OnChange(val, self.Button2) end
				local _oldpaint = self.Button2.Paint
				function self.Button2:Paint(w,h)
					//ugly temporary visuals for exclude button
					_oldpaint(self,w,h)
					surface.SetDrawColor(255,64,0,128)
					surface.DrawRect(0,0,w,h)
				end
				self.Label = vgui.Create("DLabel", self)
				self.Label:SetText(label)
				self.Label:SetMouseInputEnabled(true)
				self.Label.DoClick = function()
					//cycle through all 3 states when label is clicked
					local v = self:GetValue()
					if v == 0 then self.Button1:SetValue(true)
					elseif v == 1 then self.Button2:SetValue(true)
					else self.Button2:SetValue(false) end
				end 
				self.Paint = function() end
				function self:PerformLayout()
					self.Button1:SetSize(15, 15)
					self.Button1:SetPos(0, math.floor((self:GetTall() - self.Button1:GetTall()) / 2))

					self.Button2:SetSize(15, 15)
					self.Button2:SetPos(self.Button1:GetWide() + 2, math.floor((self:GetTall() - self.Button2:GetTall()) / 2))

					self.Label:SizeToContents()
					self.Label:SetPos(self.Button1:GetWide() + 2 + self.Button2:GetWide() + 9, math.floor((self:GetTall() - self.Label:GetTall()) / 2))
				end
				function self:GetValue()
					if self.Button1:GetChecked() then return 1
					elseif self.Button2:GetChecked() then return -1
					else return 0 end
				end
				function self:OnChange(val, button)
					//don't let include and exclude both be checked at once
					if val then
						if button == self.Button1 and self.Button2:GetChecked() then
							self.Button2:SetChecked(false)
						elseif button == self.Button2 and self.Button1:GetChecked() then
							self.Button1:SetChecked(false)
						end
					end
					window.RebuildIconList()
				end
				self:Dock(TOP)
				self:DockMargin(0,0,0,betweenitems)
				return self
			end

			filters.multi_class = AddIncludeExcludeFilter("Multi-class")
			filters.holiday = AddIncludeExcludeFilter("Holiday restricted")
			filters.paint = AddIncludeExcludeFilter("Paintable")
			filters.warpaint = AddIncludeExcludeFilter("War Paintable")
			//This kind of sucks, ordinarily i'd just make this a separate item type, but we need to be able to 
			//filter them out by default when item type is set to "(all)", because there's so many of them (over
			//75% of all spawnable items) that they severely impact performance while building the icon list.
			filters.tm = AddIncludeExcludeFilter("Tournament medals")
			filters.tm:DockMargin(0,0,0,betweencategories)
			filters.tm.Button2:SetChecked(true)
			filters.custom = AddIncludeExcludeFilter("Custom items")

			local button = vgui.Create("DButton", filters)
			button:SetText("Add custom item...")
			button:SetHeight(20)
			button:Dock(TOP)
			button:DockMargin(0,0,0,0)
			button.DoClick = function()
				//TODO: open custom item dialog
			end
			AddTFButtonSounds(button)


			window.RebuildIconList = function(clicked)
				if filters.equip_region.IsRebuilding or filters.item_set.IsRebuilding then return end

				window.icons = {}
				window.icons_to_add = {}
				window.icons_to_add_key = 1
				local item_slot_types = {
					primary = "weapon",
					secondary = "weapon",
					melee = "weapon",
					pda = "weapon",
					pda2 = "weapon",
					building = "weapon",
					head = "cosmetic", 
					misc = "cosmetic",
					taunt = "taunt"
				}
				local function DoIncludeExcludeFilter(f, criteria)
					return (f == 1 and !criteria) or (f == -1 and criteria)
				end
				local f = search:GetText()
				if f then
					if f == "" then
						f = nil
					else
						f = f:lower()
					end
				end
				for k, v in pairs (TF2Items.items) do
					//this filter is on by default and catches >75% of items, so check this first
					if DoIncludeExcludeFilter(filters.tm:GetValue(), v._tm) then continue end

					//keep the search filter simple, only search by base name
					if f and !(GetTFLanguageString(v.item_name, true):lower():find(f, 1, true)) then continue end
					
					local _, f = filters.class:GetSelected()
					if f != "(any)" and !v.used_by_classes[f] then continue end

					local _, f = filters.item_type:GetSelected()
					if f != "(any)" and ((f == "other" and v.item_slot and item_slot_types[v.item_slot]) 
					or (f != "other" and (!v.item_slot or item_slot_types[v.item_slot] != f))) then continue end

					local _, f = filters.equip_region:GetSelected()
					if f != "(any)" and (!v.equip_regions or !v.equip_regions[f]) then continue end

					local _, f = filters.item_set:GetSelected()
					if f != "(any)" and (v._item_set != f and v._item_collection != f) then continue end

					if DoIncludeExcludeFilter(filters.multi_class:GetValue(), table.Count(v.used_by_classes) > 1)
					or DoIncludeExcludeFilter(filters.holiday:GetValue(), v.holiday_restriction)
					or DoIncludeExcludeFilter(filters.paint:GetValue(), v.capabilities and v.capabilities.paintable == 1)
					or DoIncludeExcludeFilter(filters.warpaint:GetValue(), v._paintkit)
					//TODO: filter for custom items when we add those at the end
					then continue end

					table.insert(window.icons_to_add, k)
				end
				//Clear the icon list, and resize it to the height of the new list
				iconlist:Clear()
				local rows = math.floor((#window.icons_to_add-1)/10)+1
				iconlist:SetHeight((rows*item_icon_h) + ((rows-1)*item_icon_gap))
				iconlist:SetWidth((10*item_icon_w) + (9*item_icon_gap))
				//Update scrollbar; scroll back to the top, and prevent scrolling or clicking on list items until we're done loading
				scroll:InvalidateLayout()
				scroll.VBar:SetScroll(0)
				scroll:SetMouseInputEnabled(false)
				//MsgN(#window.icons_to_add, " icons to add")
			end
			window.RebuildIconList()


			local old_Think = window.Think
			window.ImageQueue = {}
			//this one is global so it carries over between windows
			TF2ItemBrowser_ImageQueuedBefore = TF2ItemBrowser_ImageQueuedBefore or {}
			local iconsperframe = 100
			function window:Think(...)
				if self.icons_to_add and self.icons_to_add_key then
					for k = self.icons_to_add_key, self.icons_to_add_key + iconsperframe - 1 do
						local v = self.icons_to_add[k]
						if v then
							local item = iconlist:Add("TF2ItemIcon")
							local col = (k-1)%10
							local row = math.floor((k-1)/10)
							item:SetPos(col*(item_icon_w+item_icon_gap), row*(item_icon_h+item_icon_gap))
							item:SetItemID(v)
							self.icons[v] = item
						else
							//We've gone through the whole table, so we're done here, get rid of it
							self.icons_to_add = nil
							self.icons_to_add_key = nil
							//Allow the list to be scrolled and clicked on now that it's fully loaded
							scroll:SetMouseInputEnabled(true)
							break
						end
					end
					//MsgN("self.icons_to_add_key = ", self.icons_to_add_key)
					if self.icons_to_add_key then self.icons_to_add_key = self.icons_to_add_key + iconsperframe end
				else
					for k, v in ipairs (self.ImageQueue) do
						table.remove(self.ImageQueue, k)
						if IsValid(v.pnl) then
							v.pnl.mat = Material(v.img .. ".vmt")
							if !TF2ItemBrowser_ImageQueuedBefore[v.img] then
								TF2ItemBrowser_ImageQueuedBefore[v.img] = true 
								break
							end
						end
					end
					//MsgN("#self.ImageQueue = ", #self.ImageQueue)
				end
				//if our selected entity is deleted, then update the attached item list
				if self.atticons_holder and self.atticons_holder:IsVisible() and !IsValid(self:GetEntity()) then
					self:SetEntity(NULL)
				end
				old_Think(self, ...)
			end


			local atticons_holder = vgui.Create("DPanel", right_holder)
			atticons_holder:DockPadding(0,10,0,0)
			atticons_holder:Dock(BOTTOM)
			window.atticons_holder = atticons_holder
			function atticons_holder:Paint(w,h)
				OutlinedGreyBox(-24,0,w+48,h) //no corners, just the top border
			end

			//This also has a scrollbar just in case some goofball wants to attach more than 10 items to one model
			local atticons = vgui.Create("DHorizontalScroller", atticons_holder)
			atticons:SetHeight(item_icon_h)
			atticons:SetOverlap(-item_icon_gap)
			atticons:Dock(BOTTOM)
			window.atticons = atticons
			atticons.icons = {}
			atticons.Label = vgui.Create("DLabel", atticons_holder)
			atticons.Label:SetText("")
			atticons.Label:SetWide(right_holder:GetWide())
			atticons.Label:SetPos(6,6)
			atticons_holder:SetTall(item_icon_h + atticons.Label:GetTall() + 8)//(item_icon_h+3+item_icon_gap)

			function atticons:AddItem(ent, data, forceopen)
				local item
				if !IsValid(atticons.icons[ent]) then
				item = vgui.Create("TF2ItemIcon")
					atticons.icons[ent] = item
					item.entity = ent
					atticons:AddPanel(item)
				else item = atticons.icons[ent] end

				item:SetItemID(data.i)
				item.data = data
				
				if forceopen then
					atticons:ScrollToChild(item)
					item.OpenNextFrame = true
				end
			end

			local attopts = vgui.Create("DPanel", left_holder)
			attopts.Paint = function() end
			attopts:Dock(BOTTOM)
			window.attopts = attopts

			local text = vgui.Create("DLabel", left_holder) //SizeToContents gets finicky with this one if we put it inside attopts
			text:SetWrap(true)
			text:SetContentAlignment(5)
			text:SetAutoStretchVertical(true)
			text:SetText("Right-click a model in the context menu to select it and attach items.")
			text:Dock(BOTTOM)
			text:DockMargin(0,0,0,betweenitems)
			attopts.emptytext = text

			local button = vgui.Create("DButton", attopts)
			button:SetText("")
			button:SetHeight(20)
			button:Dock(TOP)
			button:DockMargin(0,0,0,betweenitems)
			attopts.deselect = button
			button.DoClick = function()
				window:SetEntity(NULL)
			end
			AddTFButtonSounds(button)

			local drop = AddDropdownFilter("Attach with:", function(self)
				local b = GetConVar("cl_tf2itembrowser_advbone"):GetBool()
				self:AddChoice("Easy Bonemerge", false, !b)
				self:AddChoice("Adv. Bonemerge", true, b)
			end)
			drop:GetParent():SetParent(attopts)
			drop:GetParent():Dock(TOP)
			function drop.OnSelect(_, index, value, data)
				//is there really no easy number-to-bool func in glua?
				local b = 0
				if data then b = 1 end
				LocalPlayer():ConCommand("cl_tf2itembrowser_advbone " .. b)
			end

			//TODO: make this use red/blu team icons later
			local check = vgui.Create("DCheckBoxLabel", attopts)
			check:SetText("BLU")
			check:SetHeight(15)
			check:Dock(TOP)
			check:DockMargin(0,0,0,betweenitems)
			attopts.team = check
			check.OnChange = function(_, val)
				local ent = window:GetEntity()
				if IsValid(ent) then
					local skintoset
					if ent:GetSkin() % 2 != 0 then
						if !val then skintoset = ent:GetSkin()-1 end //don't change the skin if ent's skin got desynced
					else
						if val then skintoset = ent:GetSkin()+1 end
					end
					if skintoset != nil then
						window:DoInput("attach_skin", skintoset)
					end

					for ent, pnl in pairs (atticons.icons) do
						if !IsValid(pnl) or !IsValid(ent) then
							atticons.icons[ent] = nil 
						else
							if pnl.data.team != val then
								pnl.data.team = val
								TF2ItemBrowser:DoInput("attach_item_modify", ent, pnl.data)
							end
						end
					end
				end
				if window.SpawnPanel and window.SpawnPanel.ModelPanel then
					window.SpawnPanel.ModelPanel.Refresh()
				end

			end

			attopts:InvalidateLayout(true)
			attopts:SizeToChildren(false,true)

			AccessorFunc(window, "m_Entity", "Entity")
			function window:SetEntity(ent)
				window.m_Entity = ent
				atticons:Clear()
				if IsValid(self.SpawnPanel) then self.SpawnPanel:Remove() end

				if IsValid(ent) then
					atticons_holder:SetVisible(true)
					right_holder:InvalidateLayout()

					attopts.emptytext:SetVisible(false)
					attopts.deselect:SetVisible(true)
					attopts:InvalidateLayout(true)
					attopts:SizeToChildren(false,true)

					local mdl = string.GetFileFromFilename(ent:GetModel())
					//Try to figure out what class the model is, and set the class filter to match
					for k, v in ipairs (classes) do
						if k == 1 or k == 11 then continue end
						if string.find(mdl, v.shortname, 1, true) then
							filters.class:ChooseOptionID(k) //TODO: make sure this works
						end
					end
					atticons.Label:SetText("Attached to " .. mdl .. ":")
					attopts.deselect:SetText("Deselect " .. mdl)

					attopts.team:SetChecked(ent:GetSkin() % 2 != 0)

					net.Start("TF2ItemBrowser_AttachedItems_GetFromSv", true)
						net.WriteEntity(ent)
					net.SendToServer()
				else
					atticons_holder:SetVisible(false)
					right_holder:InvalidateLayout()

					attopts.emptytext:SetVisible(true)
					attopts.deselect:SetVisible(false)
					attopts:InvalidateLayout(true)
					attopts:SizeToChildren(false,true)
				end
			end


			function window:DoInput(input, ...)

				net.Start("TF2ItemBrowser_Input_SendToSv", true) //use unreliable channel; if network is clogged, better to not spawn one prop than to crash the server
				
					local args = {...}
	
					net.WriteUInt(BrowserInputs[input], BrowserInputs_bits)

					if string.StartsWith(input, "attach_") then
						net.WriteEntity(self:GetEntity())
					end

					if input == "item_spawn" then

						WriteItemDataTable(args[1]) //item data table
						
					elseif input == "attach_item_spawn" then

						WriteItemDataTable(args[1]) //item data table
						net.WriteBool(GetConVar("cl_tf2itembrowser_advbone"):GetBool())

					elseif input == "attach_item_modify" then

						net.WriteEntity(args[1]) //item ent to modify
						WriteItemDataTable(args[2]) //item data table

					elseif input == "attach_item_remove" then
					
						net.WriteEntity(args[1]) //item ent to remove

					elseif input == "attach_skin" then

						net.WriteUInt(args[1], 8) //skin id

					end

				net.SendToServer()

			end

		end
	})










	local PANEL = {}

	AccessorFunc(PANEL, "m_iItemID", "ItemID")

	PANEL.data = {} //if this item icon is for an existing attached item, this tab will be populated with the item's settings. otherwise, this tab will be empty and the icon will use default values.

	function PANEL:Init()

		self:SetSize(item_icon_w, item_icon_h)
		self:SetDoubleClickingEnabled(false)
		self:SetText("")

		self.quality = "unique"
		self.rarity = nil
		self.sound_pressed = "ui/item_default_pickup.wav"
		self.sound_drop = "ui/item_default_drop.wav"

	end

	function PANEL:SetItemID(i)

		self.m_iItemID = i
		self.ImageToQueue = TF2Items.items[i].image_inventory
		self.quality = TF2Items.items[i].item_quality or self.quality
		self.rarity = TF2Items.items[i]._rarity or self.rarity
		self.sound_pressed = TF2Items.items[i].mouse_pressed_sound or self.sound_pressed
		self.sound_drop = TF2Items.items[i].drop_sound or self.sound_drop

		self.itemname = self:UpdateItemName()
		self.itemdesc = self:UpdateItemDescription()
		
	end

	function PANEL:UpdateItemName()

		//based on https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L610, it's a whopper
		//this is probably way overengineered for our use case, but oh well!

		local i = TF2Items.items[self:GetItemID()]
		if !i then return "Unknown Item" end

		local useProperName = true
		local ignoreWear = false
		local ignoreQuality = false
		if self.paintkit and self.quality != "strange" and self.quality != "selfmade" then
			ignoreQuality = true
		end
		
		// Start with the base name.
		local itemName = GetTFLanguageString(i.item_name, true) or "Unknown Item"

		//tf2 code here sets killstreak values, but this addon won't be doing those unless rubat implements $sheenmap someday

		if self.festivized then useProperName = false end

		local quality = ""
		if !ignoreQuality then 
			if self.quality != "normal" and self.quality != "paintkitweapon" then //tf2 code here checks nQuality > 0, which only filters out normal quality (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_constants.h#L516)
				if self.quality == "unique" then
					if useProperName and i.propername == 1 then 
						quality = GetTFLanguageString("TF_Unique_Prepend_Proper")
					end
				else // Any quality besides unique ignores "proper name" articles.
					quality = GetTFLanguageString(self.quality)
					if quality != "" then quality = quality .. GetTFLanguageString("#Rarity_Spacer") end
				end
			end

			//tf2 code here sets strange ranks, which we don't care about, but also prepends strange rank onto strange unusual weapons,
			//which in our use cases, only applies to weapons with both an unusual effect and a stat clock enabled.
			if self.quality != "strange" and self.statclock then
				quality = GetTFLanguageString("strange") .. " " .. quality
			end
			//TODO: we might actually care about ranks if we're getting the correct name for token/gargoyle rank styles? or maybe just lump that in with australium? come back to this later.
		end

		local australium_skin = ""
		if self.australium then australium_skin = GetTFLanguageString("ItemNameAustralium") end
		//TODO: "self.australium" might not be how we implement this, come back to this later

		local festivized = ""
		if self.festivized then festivized = GetTFLanguageString("ItemNameFestive") end

		local qualityFormat
		if (self.quality == "normal" or self.quality == "unique" or self.quality == "paintkitweapon" or ignoreQuality) and self.quality != "selfmade" then
			qualityformat = GetTFLanguageString("ItemNameNormalOrUniqueQualityFormat")
		else
			qualityformat = GetTFLanguageString("ItemNameQualityFormat")
		end

		//loc_scpy_safe( szQuality, CConstructLocalizedString( pLocalizationProvider->Find( pszQualityFormat ), szQuality, szIsFestivized, szKillStreak, szAustraliumSkin, szDuckBadge ) );
		// Strange Unusual Festive Killstreak Australium ducks
		qualityformat = string.Replace(qualityformat, "%s1", quality)
		qualityformat = string.Replace(qualityformat, "%s2", festivized)
		qualityformat = string.Replace(qualityformat, "%s3", "") //killstreak
		qualityformat = string.Replace(qualityformat, "%s4", australium_skin)
		qualityformat = string.Replace(qualityformat, "%s5", "") //duck journal rank
		quality = qualityformat

		if self.paintkit then
			//TODO: tf2 code here gets localized paintkit name and concatenates it with itemName here; these names aren't stored in 
			//normal localization files, maybe we can grab them from the war paints gmod addon, which reads them from protodefs?
			//https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L1001
		end

		//note: in the tf2 code, at the very top of this method, "ItemNameFormat" is set as the default value, and a comment mentions 
		//using a different format for names with an article, but it never actually does this or changes this value anywhere
		local format = GetTFLanguageString("ItemNameFormat")
		if format != "" then
			format = string.Replace(format, "%s1", quality)
			format = string.Replace(format, "%s2", itemName)
			format = string.Replace(format, "%s3", "") //craft index
			format = string.Replace(format, "%s4", "") //crate series
			format = string.Replace(format, "%s5", "") //tool target name
			format = string.Replace(format, "%s6", "") //dynamic recipe output name
			return format
		else
			return "Unknown Item"
		end

	end

	function PANEL:UpdateItemDescription()

		//based on CEconItemDescription::GenerateDescriptionLines https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L347

		local desc = {}
		local i = TF2Items.items[self:GetItemID()]
		if !i then return desc end

		if i._rarity then
			//Item rarity; based on CEconItemDescription::Generate_ItemRarityDesc https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L1521
			
			local tooltip = "TFUI_InvTooltip_Rarity"
			if !self.wear then tooltip = "TFUI_InvTooltip_RarityNoWear" end //TODO: we might end up storing paintkit wear differently, come back to this
			tooltip = GetTFLanguageString(tooltip)
			if tooltip != "" then
				tooltip = string.Replace(tooltip, "%s1", GetTFLanguageString(TF2Items.rarities[i._rarity].loc_key))
				tooltip = string.Replace(tooltip, "%s2", GetTFLanguageString(i.item_type_name))
				tooltip = string.Replace(tooltip, "%s3", "") //TODO: convert wear value (however we end up storing it) to localization string from this table https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_constants.cpp#L200-L208
				table.insert(desc, {str = tooltip, col = rarity_colors[i._rarity]})
			end
		else
			//Item level; based on CEconItemDescription::Generate_ItemLevelDesc, which calls CEconItemDescription::Generate_ItemLevelDesc_Default (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L1252);
			//the former also has a use case for showing strange ranks in place of levels, but this addon doesn't need those
			
			local typeName = GetTFLanguageString(i.item_type_name)
			if typeName != "" then
				local level = math.random(i.min_ilevel or 1, i.max_ilevel or 1)

				//tf2 code has a case here where if an item has no typeName, the attribute "force_level_display" can 
				//make it use the "ItemTypeDescNoLevel" format (just "Level X") instead of returning nothing (or doing 
				//any of the below checks), but nothing in items_game uses this attribute, so don't bother

				//tf2 code here also has a case for items with a override_item_level_desc_string attribute that makes
				//them use the "ItemTypeDescCustomLevelString_MvMTour" format (Tour No. X typeName) but nothing uses this

				if i.static_attrs and i.static_attrs["limited quantity item"] == 1 then
					local format = GetTFLanguageString("ItemTypeDescLimited")
					if format != "" then
						format = string.Replace(format, "%s1", level)
						format = string.Replace(format, "%s2", typeName)
						format = string.Replace(format, "%s3", GetTFLanguageString("LimitedQualityDesc"))
						table.insert(desc, {str = format, col = desc_colors.ItemLimitedQuantity})
					end
				else
					local format = GetTFLanguageString("ItemTypeDesc")
					if format != "" then
						format = string.Replace(format, "%s1", level)
						format = string.Replace(format, "%s2", typeName)
						table.insert(desc, {str = format, col = desc_colors.level})
					end
				end
			end
		end

		//TODO: tf2 code does a bunch of other stuff here, go through these and see which ones we care about
		//Generate_CraftTag( pLocalizationProvider, pEconItem );
		//Generate_StyleDesc( pLocalizationProvider, pEconItem );
		//Generate_Painted( pLocalizationProvider, pEconItem );
		//Generate_HolidayRestriction( pLocalizationProvider, pEconItem );	
		//Generate_SaxxyAwardDesc( pLocalizationProvider, pEconItem );
		//Generate_VisibleAttributes( pLocalizationProvider, pEconItem );
		//Generate_QualityDesc( pLocalizationProvider, pEconItem );	

		//Item description; based on CEconItemDescription::Generate_ItemDesc https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L1575
		if i.item_description then
			local item_desc = GetTFLanguageString(i.item_description)
			if item_desc != "" then table.insert(desc, {str = item_desc, col = desc_colors.neutral}) end
		end
		//This method also does a list of styles here
		//TODO: get back to this once styles are implemented https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L1607-L1622

		//TODO: tf2 code does even more stuff here, go through these and see which ones we care about
		//Generate_Bundle( pLocalizationProvider, pEconItem );
		//Generate_GiftedBy( pLocalizationProvider, pEconItem );
		//Generate_DuelingMedal( pLocalizationProvider, pEconItem );
		//Generate_MapContributor( pLocalizationProvider, pEconItem );
		//Generate_MapStampBundleTooltip( pLocalizationProvider, pEconItem );
		//Generate_FriendlyHat( pLocalizationProvider, pEconItem );
		//Generate_SquadSurplusClaimedBy( pLocalizationProvider, pEconItem );
		//Generate_MvmChallenges( pLocalizationProvider, pEconItem );
		//Generate_DynamicRecipe( pLocalizationProvider, pEconItem );
		//Generate_XifierToolTargetItem( pLocalizationProvider, pEconItem );
		//Generate_LootListDesc( pLocalizationProvider, pEconItem );
		//Generate_EventDetail( pLocalizationProvider, pEconItem );
		//Generate_ItemSetDesc( pLocalizationProvider, pEconItem );
		//Generate_UnusualifierEffectList( pLocalizationProvider, pEconItem );
		//Generate_CollectionDesc( pLocalizationProvider, pEconItem );
		//Generate_BonusContentDesc( pLocalizationProvider, pEconItem );
		//Generate_ExpirationDesc( pLocalizationProvider, pEconItem );
		//Generate_DropPeriodDesc( pLocalizationProvider, pEconItem ); 
		//Generate_MarketInformation( pLocalizationProvider, pEconItem );
		//Generate_DirectX8Warning( pLocalizationProvider, pEconItem );

		return desc

	end

	local popup_w = 480 //keep the width consistent between popup panels, so that when we switch from mouseoverpanel to spawnpanel, the above func maintains the same horizontal position
	local popup_pad = 25 //34 would match the padding in tf2's backpack screen, but our text is smaller (13px, from 18px), so scale it down proportionately

	function PANEL:AddItemText(pnl, text, font, col)
		
		local h = 0
		for _, v in ipairs (string.Explode("\n", textWrap(text, font, popup_w-(popup_pad*2)))) do
			local label = pnl:Add("DLabel")
			label:Dock(TOP)
			label:SetFont(font)
			label:SetText(v)
			label:SetTextColor(col)
			label:SetAutoStretchVertical(true)
			label:SetContentAlignment(5)
			local _, _h = surface.GetTextSize(v)
			h = h + _h
		end
		return h

	end

	function PANEL:PositionPopupPanel(pnl)

		//Keeps a popup panel contained within its parent TF2ItemBrowser, but also centered on this item icon
		local w, h = pnl:GetSize()
		local x, y = TF2ItemBrowser:ScreenToLocal(self:LocalToScreen(self:GetWide()/2, self:GetTall()))
		local b_w, b_h = TF2ItemBrowser:GetSize()

		x = x-(w/2) //by default, the panel is positioned below the icon
		local is_on_side
		if x < 0 then
			//if the left side of the panel goes beyond the left side of the browser, then move it to the right of the icon
			x = x + (self:GetWide()/2)+(w/2)
			y = y - (self:GetTall()/2)-(h/2)
			is_on_side = true
		elseif x+w > b_w then 
			//if the right side of the panel goes beyond the right side of the browser, then move it to the left of the icon
			x = x - (self:GetWide()/2)-(w/2)
			y = y - (self:GetTall()/2)-(h/2)
			is_on_side = true
		elseif y+h > b_h and (y-self:GetTall()-h) < 0 then
			//if the panel is too tall to fit above or below the icon, then center it the browser over the icon (edge case for clicking on icons in middle of the browser)
			y = (b_h/2)-(h/2)
		end
		
		//if the bottom of the panel goes beyond the bottom of the browser...
		if y+h > b_h then 
			if is_on_side then
				//...and we've moved it to the side of the icon, then push it upward
				y = y-((y+h)-b_h)
			else
				//...and it's positioned below the icon, then reposition it above the icon
				y = y-self:GetTall()-h
			end
		end
		//if the top of the panel goes beyond the top of the browser, then push it downward
		if y < 0 then 
			y = 0
		end

		pnl:SetPos(x, y)

	end

	function PANEL:CreateMouseOverPanel()

		if IsValid(TF2ItemBrowser.MouseOverPanel) then TF2ItemBrowser.MouseOverPanel:Remove() end

		local pnl = vgui.Create("DPanel", TF2ItemBrowser)
		TF2ItemBrowser.MouseOverPanel = pnl
		pnl.Owner = self

		pnl:DockPadding(popup_pad,popup_pad,popup_pad,popup_pad) 
		local h = popup_pad*2 + self:AddItemText(pnl, self.itemname, "TF2ItemBrowser_ItemName", rarity_colors[self.rarity] or quality_colors[self.quality])
		for _, v in ipairs (self.itemdesc) do
			h = h + self:AddItemText(pnl, v.str, "TF2ItemBrowser_ItemDesc", v.col)
		end
		--[[pnl:SetWide(popup_w)
		pnl:InvalidateLayout(true)
		pnl:SizeToChildren(false,true)]]
		pnl:SetSize(popup_w,h) //this returns better height for items with descriptions??
		self:PositionPopupPanel(pnl)
		
		function pnl:Paint(w,h)
			LoadoutItemPopupBorder(0,0,w,h)
		end

	end

	function PANEL:CreateSpawnPanel()

		local _i = self:GetItemID()
		local i = TF2Items.items[_i]
		local betweenitems = 8

		if IsValid(TF2ItemBrowser.SpawnPanel) then
			if TF2ItemBrowser.SpawnPanel.Owner == self then
				return
			else
				TF2ItemBrowser.SpawnPanel:Remove()
			end
		end

		local pnl = vgui.Create("DPanel", TF2ItemBrowser)
		TF2ItemBrowser.SpawnPanel = pnl
		pnl.Owner = self

		pnl:DockPadding(popup_pad,popup_pad,popup_pad,popup_pad) 
		self:AddItemText(pnl, self.itemname, "TF2ItemBrowser_ItemName", rarity_colors[self.rarity] or quality_colors[self.quality])
		
		local mdl_container = pnl:Add("DPanel")
		mdl_container:SetSize(300,300)
		side_margins = (popup_w-300-popup_pad-popup_pad)/2 //force this panel to stay a square, and align all the other controls with it
		mdl_container:DockMargin(side_margins,betweencategories-5,side_margins,betweencategories)
		mdl_container:Dock(TOP)
		function mdl_container:Paint(w,h)
			GrayDialogBorder(0,0,w,h)
		end
		local mdl = mdl_container:Add("DAdjustableModelPanel")
		pnl.ModelPanel = mdl
		mdl.FarZ = 32768
		mdl:DockMargin(3,3,3,3) //set precisely to cut off the modelpanel at the edges of the GrayDialogBorder
		mdl:Dock(FILL)
		mdl.LayoutEntity = function() mdl:GetEntity():FrameAdvance(FrameTime()) end //disable default spinning-model behavior
		function mdl.Refresh()
			local _team = self.data.team //data.team and the selector are intended to always be the same, but could potentially get desynced i.e. if a player manually merges a mismatched item to something 
			if _team == nil then _team = TF2ItemBrowser.attopts.team:GetChecked() end 
			local _, _class = pnl.class:GetSelected()
			local style = 0
			if pnl.style then _, _style = pnl.style:GetSelected() end
			local model, skin, item_bg = GetItemModelVisuals(_i, _class, _team, _style)
			//TODO: use class model as a fallback if we click on something like fists or gunslinger, or no model for stuff like taunts

			mdl:SetModel(model)
			local ent = mdl:GetEntity()
			if IsValid(ent) then
				ent:SetSkin(skin)
				for k, v in pairs (item_bg) do
					ent:SetBodygroup(ent:FindBodygroupByName(k), v)
				end

				//don't recenter the camera if the model didn't change
				if model != mdl.old_model then
					local pos = ent:GetPos()
					local ang = ent:GetAngles()

					local tab = PositionSpawnIcon(ent, pos, true)

					ent:SetAngles(ang)
					if tab then
						mdl:SetCamPos(tab.origin)
						mdl:SetFOV(tab.fov)
						mdl:SetLookAng(tab.angles)
					end
				end
				mdl.old_model = model
			end

			//Hide the class selector if all classes use the same model (i.e. medals)
			//Also compare the bodygroups because of use_per_class_bodygroups.
			if pnl.class then
				local should_show_class = false
				for k, v in pairs (i.used_by_classes) do
					if k != _class then 
						local model2, _, item_bg2 = GetItemModelVisuals(_i, k, TF2ItemBrowser.attopts.team:GetChecked(), _style)
						for k, v in pairs (item_bg2) do
							//make sure this is changing a bodygroup that actually exists; a whole bunch of 
							//badges like the dueling badges have useless bodygroup setters for some reason
							if ent:FindBodygroupByName(k) != -1 and item_bg[k] != item_bg2[k] then
								item_bg2 = true
								break
							end
						end
						if (model != model2) or isbool(item_bg2) then
							should_show_class = true
							break
						end
					end
				end
				//Instead of hiding the class selector, keep it visible but grayed out, so that players can see what class an item belongs to
				if table.Count(i.used_by_classes) > 1 then
					//If there are multiple selectable classes that use the same model, change the display text on the dropdown to list them
					if !should_show_class and pnl.class:IsEnabled() then
						if table.Count(i.used_by_classes) == 9 then
							//if it's used by all classes (i.e. medals), just show "(any)"
							pnl.class:SetText("(any)")
							
						else
							local text
							for k, v in ipairs (classes) do //add class options in class order; this kind of sucks for listing a lot of classes but oh well
								if i.used_by_classes[v.longname] then
									if text then
										text = text .. ", "
									else
										text = ""
									end
									text = text .. string.NiceName(v.longname)
								end
							end
							pnl.class:SetText(text)
						end
					elseif should_show_class and !pnl.class:IsEnabled() then
						pnl.class:SetText(string.NiceName(_class))
					end
				end
				pnl.class:SetEnabled(should_show_class)
				pnl.class:GetParent().Label:SetEnabled(should_show_class)
			end
		end

		local function AddDropdown(label, populatefunc, select_extras)
			local drop = vgui.Create("Panel", pnl)
			drop.Label = vgui.Create("DLabel", drop)
			drop.Label:SetText(label)
			drop.Label:Dock(LEFT)
			drop.Combo = vgui.Create("DComboBox", drop)
			drop.Combo:SetHeight(25)
			drop.Combo:Dock(FILL)
			drop:SetHeight(25)
			drop:Dock(TOP)
			drop:DockMargin(side_margins,0,side_margins,betweenitems)
			function drop.PerformLayout(_, w, h)
				drop.Label:SetWide(w / 2.4)
			end
			drop.Combo:SetSortItems(false)
			populatefunc(drop.Combo)
			function drop.Combo.OnSelect(_, index, value, data)
				drop.Combo.value = data
				if IsValid(self.entity) then TF2ItemBrowser:DoInput("attach_item_modify", self.entity, pnl.GetItemDataTable()) end
				mdl.Refresh()
			end
			function drop.Combo:OnMenuOpened(menu)
				//Add a checkmark to the currently selected option.
				//GetChild uses the number of children including spacers, while SetSelectedID uses the number of children
				//not including spacers, so we have to loop through the whole list like this until we've gone through enough
				//non-spacer children to find the correct one.
				local sel = drop.Combo:GetSelectedID()
				local sel_read = 0
				for i = 1, menu:ChildCount() do
					local child = menu:GetChild(i)
					if child:GetName() == "DMenuOption" then
						sel_read = sel_read + 1
						if sel_read == sel then
							child:SetChecked(true)
							break
						end
					end
				end
			end
			return drop.Combo
		end

		pnl.class = AddDropdown("Class", function(drop)
			local first, _, f = nil, nil, self.data.class
			if f != nil then
				f = classes[f].longname
			else
				_, f = TF2ItemBrowser.filters.class:GetSelected()
				if f == "(any)" then f = nil end
			end
			if f == nil then first = true end
			for k, v in ipairs (classes) do //add class options in class order
				if i.used_by_classes[v.longname] then
					drop:AddChoice(string.NiceName(v.longname), v.longname, first or f == v.longname)
					first = nil
				end
			end
		end)

		if i.visuals and i.visuals.styles and table.Count(i.visuals.styles) > 1 then
			pnl.style = AddDropdown("Style", function(drop)
				local first, f = nil, self.data.style
				if f == nil then first = true end
				for k, v in SortedPairs (i.visuals.styles) do //this starts from 0 so we can't do ipairs
					local name = GetTFLanguageString(v.name, true)
					drop:AddChoice(name or "PLACEHOLDER " .. k, k, first or f == k)
					first = nil
				end
			end)
		end

		//TODO: currently we get the team value from the selector in TF2ItemBrowser because it's intended to always be the same, and 
		//updates all attached items when it's changed, but what if they get desynced somehow? do we need to add handling for that?

		local button = vgui.Create("DButton", pnl)
		if IsValid(self.entity) then
			button:SetText("Remove!")
			button:SetColor(Color(255,100,100,255))
		elseif IsValid(TF2ItemBrowser:GetEntity()) then
			button:SetText("Attach!")
		else
			button:SetText("Spawn!")
		end
		button:SetHeight(20)
		button:Dock(TOP)
		button:DockMargin(side_margins,betweencategories-betweenitems,side_margins,betweencategories)
		AddTFButtonSounds(button)
		button:SetDoubleClickingEnabled(false) //make the button spam-clickable like spawnicons
		button.DoClick = function()
			if IsValid(self.entity) then
				TF2ItemBrowser:DoInput("attach_item_remove", self.entity)
			elseif IsValid(TF2ItemBrowser:GetEntity()) then
				TF2ItemBrowser:DoInput("attach_item_spawn", pnl.GetItemDataTable())
			else
				TF2ItemBrowser:DoInput("item_spawn", pnl.GetItemDataTable())
			end
			surface.PlaySound(self.sound_drop)
		end

		function pnl.GetItemDataTable()
			//translate class name back to id number
			local _, _class = pnl.class:GetSelected()
			for k, class in ipairs (classes) do
				if class.longname == _class then
					_class = k
					break
				end
			end
			local _style = 0 
			if pnl.style then _, _style = pnl.style:GetSelected() end

			local data = {
				i = self:GetItemID(),
				class = _class,
				team = TF2ItemBrowser.attopts.team:GetChecked(),
				style = _style,
			}
			if IsValid(self.entity) then self.data = data end
			//MsgN("pnl.GetItemDataTable got table:")
			//PrintTable(data)
			return data
		end
		
		pnl:SetWide(popup_w)
		pnl:InvalidateLayout(true)
		pnl:SizeToChildren(false,true)
		mdl.Refresh()
		self:PositionPopupPanel(pnl)
		function pnl:Paint(w,h)
			LoadoutItemPopupBorder(0,0,w,h)
		end

		local close = vgui.Create("DImageButton", pnl)
		close:SetSize(25,25)
		close:SetPos(popup_w-25-10, 10)
		close:SetMaterial(close_button)
		close:SetColor(gui_colors.RedSolid)
		AddTFButtonSounds(close)
		function close:DoClick()
			pnl:Remove()
		end

	end

	//dumb modified version of GWEN.CreateTextureBorder (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/derma/derma_gwen.lua#L6-L56),
	//used to scale down the tf2 backpack textures to match our tiny backpack icons
	local function GWEN_CreateTextureBorderScaled(_xo, _yo, _wo, _ho, l, t, r, b, material_override, scale)

		local mat = SKIN && SKIN.GwenTexture || material_override
		if ( material_override && !material_override:IsError() ) then mat = material_override end

		return function( x, y, w, h, col )

			local tex = mat:GetTexture( "$basetexture" )
			local texW, texH = tex:Width(), tex:Height()

			local _x = _xo / texW
			local _y = _yo / texH
			local _w = _wo / texW
			local _h = _ho / texH

			surface.SetMaterial( mat )
			if ( col ) then
				surface.SetDrawColor( col.r, col.g, col.b, col.a )
			else
				surface.SetDrawColor( 255, 255, 255, 255 )
			end

			local halfW, halfH = w / 2, h / 2
			local left = math.min( l, math.ceil( halfW ) )
			local right = math.min( r, math.floor( halfW ) )
			local top = math.min( t, math.ceil( halfH ) )
			local bottom = math.min( b, math.floor( halfH ) )

			local _l = left / texW
			local _t = top / texH
			local _r = right / texW
			local _b = bottom / texH

			//the only change
			left = math.Round(left * scale)
			right = math.Round(right * scale)
			top = math.Round(top * scale)
			bottom = math.Round(bottom * scale)

			-- top
			surface.DrawTexturedRectUV( x, y, left, top, _x, _y, _x + _l, _y + _t )
			surface.DrawTexturedRectUV( x + left, y, w - left - right, top, _x + _l, _y, _x + _w - _r, _y + _t )
			surface.DrawTexturedRectUV( x + w - right, y, right, top, _x + _w - _r, _y, _x + _w, _y + _t )

			-- middle
			surface.DrawTexturedRectUV( x, y + top, left, h - top - bottom, _x, _y + _t, _x + _l, _y + _h - _b )
			surface.DrawTexturedRectUV( x + left, y + top, w - left - right, h - top - bottom, _x + _l, _y + _t, _x + _w - _r, _y + _h - _b )
			surface.DrawTexturedRectUV( x + w - right, y + top, right, h - top - bottom, _x + _w - _r, _y + _t, _x + _w, _y + _h - _b )

			-- bottom
			surface.DrawTexturedRectUV( x, y + h - bottom, left, bottom, _x, _y + _h - _b, _x + _l, _y + _h )
			surface.DrawTexturedRectUV( x + left, y + h - bottom, w - left - right, bottom, _x + _l, _y + _h - _b, _x + _w - _r, _y + _h )
			surface.DrawTexturedRectUV( x + w - right, y + h - bottom, right, bottom, _x + _w - _r, _y + _h - _b, _x + _w, _y + _h )

		end

	end
	local BackpackItemBorder = GWEN_CreateTextureBorderScaled(0, 0, 256, 128, 24, 24, 24, 24, Material("vgui/backpack_rect.vmt"), item_icon_scale)
	local BackpackItemMouseOverBorder = GWEN_CreateTextureBorderScaled(0, 0, 256, 128, 24, 24, 24, 24, Material("vgui/backpack_rect_mouseover.vmt"), item_icon_scale)
	local BackpackItemSelectedBorder = GWEN_CreateTextureBorderScaled(0, 0, 256, 128, 24, 24, 24, 24, Material("vgui/backpack_rect_selected.vmt"), item_icon_scale)
	//more here if we decide to do quality colors https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/client/econ/backpack_panel.cpp#L69

	function PANEL:Paint(w, h)

		if self.OpenNextFrame then
			self:CreateSpawnPanel()
			self.OpenNextFrame = nil
		end

		if self:IsHovered() and !IsValid(TF2ItemBrowser.SpawnPanel) then
			if !IsValid(TF2ItemBrowser.MouseOverPanel) or TF2ItemBrowser.MouseOverPanel.Owner != self then
				local time = CurTime()
				self.HoverTime = self.HoverTime or time
				if time - self.HoverTime > 0.1 then
					self:CreateMouseOverPanel()
				end
			end
		else
			self.HoverTime = nil
			if IsValid(TF2ItemBrowser.MouseOverPanel) and TF2ItemBrowser.MouseOverPanel.Owner == self then
				TF2ItemBrowser.MouseOverPanel:Remove()
			end
		end

		if (IsValid(TF2ItemBrowser.SpawnPanel) and TF2ItemBrowser.SpawnPanel.Owner == self) or IsValid(self.menu) or self:IsDown() then
			BackpackItemSelectedBorder(0,0,w,h)
		elseif self:IsHovered() then
			BackpackItemMouseOverBorder(0,0,w,h)
		else
			BackpackItemBorder(0,0,w,h)
		end

		if self.mat then
			surface.SetDrawColor(255,255,255,255)
			surface.SetMaterial(self.mat)
			//these panels are a bit shorter than they are wide, so cut off the bottom and top of the material to center it
			local diff = (1-(h/w))/2
			surface.DrawTexturedRectUV(0,0,w,h,0,0+diff,1,1-diff)
		elseif self.ImageToQueue then
			if TF2ItemBrowser_ImageQueuedBefore[self.ImageToQueue] then
				self.mat = Material(self.ImageToQueue .. ".vmt")
			else
				table.insert(TF2ItemBrowser.ImageQueue, {pnl = self, img = self.ImageToQueue})
			end
			self.ImageToQueue = nil
		else
			//show loading icon
			surface.SetMaterial(spinner)
			surface.DrawTexturedRect((w/2)-(h/2), 0, h, h)
		end

	end

	function PANEL:Think()

		if self.entity != nil and !IsValid(self.entity) then
			self:Remove()
			return
		end

	end

	function PANEL:DoClick()

		surface.PlaySound(self.sound_pressed)
		self:CreateSpawnPanel()

	end

	function PANEL:DoRightClick()

		//TODO: this is just a place to put this debug option for now; reformat this later? add more options?
		local menu = DermaMenu()

		local opt = menu:AddOption("Print item data in console", function()
			MsgN(self:GetItemID(), " ", TF2Items.items[self:GetItemID()].name)
			PrintTable(TF2Items.items[self:GetItemID()])
			MsgN("")
		end)
		opt:SetIcon("icon16/page_copy.png")

		self.menu = menu
		menu:Open()

	end

	AddTFButtonSounds(PANEL)

	function PANEL:OnRemove()

		if IsValid(TF2ItemBrowser.SpawnPanel) and TF2ItemBrowser.SpawnPanel.Owner == self then
			TF2ItemBrowser.SpawnPanel:Remove()
		end

		if self.entity and TF2ItemBrowser.atticons.icons[self.entity] == self then
			TF2ItemBrowser.atticons.icons[self.entity] = nil
			TF2ItemBrowser.atticons:InvalidateLayout()
		end

	end

	vgui.Register("TF2ItemIcon", PANEL, "DButton")

end










//Networking for browser inputs
BrowserInputs = {
	[0] = "item_spawn",
	"attach_item_spawn",
	"attach_item_modify",
	"attach_item_remove",
	"attach_skin",
}
BrowserInputs_bits = 3 //max 7
BrowserInputs = table.Flip(BrowserInputs)
//How this works:
//- table.Flip sets the table to {channel_sequence = 0}, and so on
//- net.Write retrieves the corresponding number of a string with BrowserInputs[input], then sends that number
//- net.Read gets the number, then retrieves its corresponding string with table.KeyFromValue(BrowserInputs, input)
//This lets us add as many networkable strings to this table as we want, without having to manually assign each one a number.

WriteItemDataTable = function(data)
	net.WriteUInt(data.i, 15)
	net.WriteUInt(data.class, 4)
	net.WriteBool(data.team)
	net.WriteUInt(data.style, 4)
end

ReadItemDataTable = function()
	return {
		i = net.ReadUInt(15),
		class = net.ReadUInt(4),
		team = net.ReadBool(),
		style = net.ReadUInt(4),
	}
end

if SERVER then

	util.AddNetworkString("TF2ItemBrowser_Input_SendToSv")
	util.AddNetworkString("TF2ItemBrowser_AttachedItems_GetFromSv")
	util.AddNetworkString("TF2ItemBrowser_AttachedItem_SendToCl")

	net.Receive("TF2ItemBrowser_Input_SendToSv", function(_, ply)

		local input = net.ReadUInt(BrowserInputs_bits)
		if !input then return end
		input = table.KeyFromValue(BrowserInputs, input)

		local ent
		if string.StartsWith(input, "attach_") then
			ent = net.ReadEntity()
		end

		if input == "item_spawn" or input == "attach_item_spawn" then

			local data = ReadItemDataTable()
			local model, skin, item_bg, ply_bg = GetItemModelVisuals(data.i, classes[data.class].longname, data.team, data.style)

			//Spawn the item using the retrieved model, skin and bodygroups. To do this, we mostly just emulate sandbox's CCSpawn function
			//and the various functions it calls (gamemodes/sandbox/gamemode/commands.lua) This is worth doing because it makes sure we run
			//all of the relevant hooks that might want to catch us spawning the prop, and also lets us reuse all of DoPlayerEntitySpawn's 
			//"spawn the prop where the player is looking, and make sure it isn't stuck" code.
			if !IsValid(ply) or (!ply:Alive() and !ply:IsAdmin()) or !gamemode.Call("PlayerSpawnObject", ply, model, skin) or !util.IsValidModel(model) then return end
			//emulate GMODSpawnProp for props, GMODSpawnEffect for effects; these are very similar
			local is_effect = !util.IsValidProp(model)
			if (is_effect and !gamemode.Call("PlayerSpawnEffect", ply, model)) or (!is_effect and !gamemode.Call("PlayerSpawnProp", ply, model)) then return end
			local e = "prop_physics"
			if is_effect then e = "prop_effect" end
			e = DoPlayerEntitySpawn(ply, e, model, skin)
			if !IsValid(e) then return end
			if !is_effect then
				gamemode.Call("PlayerSpawnedProp", ply, model, e)
				FixInvalidPhysicsObject(e)
				DoPropSpawnedEffect(e)

				undo.Create("prop_physics")
					undo.SetPlayer(ply)
					undo.AddEntity(e)
				undo.Finish("#prop_physics (" .. tostring(model) .. ")")
				ply:AddCleanup("props", e)
			else
				gamemode.Call("PlayerSpawnedEffect", ply, model, e)
				if IsValid(e.AttachedEntity) then DoPropSpawnedEffect(e.AttachedEntity) end

				undo.Create("prop_effect")
					undo.SetPlayer(ply)
					undo.AddEntity(e)
				undo.Finish("#prop_effect (" .. tostring(model) .. ")")
				ply:AddCleanup("effects", e)
			end

			local e2 = e
			if IsValid(e.AttachedEntity) then e2 = e.AttachedEntity end
			for k, v in pairs (item_bg) do
				e2:SetBodygroup(e2:FindBodygroupByName(k), v)
			end

			duplicator.StoreEntityModifier(e2, "TF2ItemBrowser_Item", data)

			if input == "attach_item_spawn" then
				for k, v in pairs (ply_bg) do
					//when attaching a new item, we can keep this simple, and just change the ply_bg's the item has listed
					if isstring(k) then k = ent:FindBodygroupByName(k) end //on some items, k is a number already
					ent:SetBodygroup(k, v)
				end
				if net.ReadBool() then
					local old_e = e
					e = CreateAdvBonemergeEntity(e, ent, ply, false, false, true)
					if !IsValid(e) then return end
					local const = constraint.AdvBoneMerge(ent, e, ply)
					undo.Create("AdvBonemerge")
						undo.AddEntity(const)  //the constraint entity will unmerge newent upon being removed
						undo.SetPlayer(ply)
					undo.Finish("Adv. Bonemerge (" .. model .. ")")
					old_e:Remove()
				else
					e = rb655_ApplyBonemerge(e2, ent) //unlike advbone, this one expects AttachedEntity for prop_effects
					undo.Create("bonemerge")
						undo.AddEntity(e)
						undo.SetPlayer(ply)
					undo.Finish()
				end
				//timer.Simple(0.1, function() //do this on a timer so the entity isn't still null on the client's end
				//	if !IsValid(e) then return end
					net.Start("TF2ItemBrowser_AttachedItem_SendToCl")
						net.WriteEntity(e)
						net.WriteBool(true) //open upon received
						WriteItemDataTable(data)
					net.Send(ply)
				//end
			end

		elseif input == "attach_item_modify" then

			local e = net.ReadEntity()
			local data = ReadItemDataTable()
			local model, skin, item_bg, ply_bg = GetItemModelVisuals(data.i, classes[data.class].longname, data.team, data.style)

			if !IsValid(e) or e:GetParent() != ent then return end

			if model != e:GetModel() then
				e:SetModel(model)
				//For advbonemerge ents, replace the boneinfo table with a new one, because the new model's bones might not match
				if e.AdvBone_BoneInfo then
					e.AdvBone_BoneInfo = nil
					e.AdvBone_BoneInfo = CreateAdvBoneInfoTable(e, ent, false, true)
					//Make sure the clients get the new boneinfo table
					net.Start("AdvBone_EntBoneInfoTableUpdate_SendToCl")
						net.WriteEntity(e)
					net.Broadcast()
				end
			end
			e:SetSkin(skin)
			for k, v in pairs (item_bg) do
				e:SetBodygroup(e:FindBodygroupByName(k), v)
				//don't worry about reverting unlisted item_bg's back to 0, no existing items that use this feature require us to check for these
			end

			//Check if the bodygroup changes this item applies to the parent ent were modified
			local tab = e:GetTable()
			if tab.EntityMods and tab.EntityMods.TF2ItemBrowser_Item then
				tab = tab.EntityMods.TF2ItemBrowser_Item
				local _, _, _, ply_bg_old = GetItemModelVisuals(tab.i, classes[tab.class].longname, tab.team, tab.style)
				local all_keys = {}
				table.Merge(all_keys, ply_bg)
				table.Merge(all_keys, ply_bg_old)
				for k, _ in pairs (all_keys) do
					if ent:FindBodygroupByName(k) != -1 and ply_bg[k] != ply_bg_old[k] then
						//If this item's ply_bg's have changed, then we need to reset the parent ent's bodygroups from scratch. 
						//For example, even if this item no longer disables one bodygroup, some other attached item may still 
						//be disabling it. Instead, we have to go through every attached item, and apply their ply_bg's again 
						//to a blank slate parent ent.
						for i = 0, ent:GetNumBodyGroups() do
							ent:SetBodygroup(i, 0)
						end
						for k, child in ipairs (ent:GetChildren()) do
							tab = child:GetTable()
							if tab.EntityMods and tab.EntityMods.TF2ItemBrowser_Item then
								local child_ply_bg
								if child == e then 
									child_ply_bg = ply_bg 
								else 
									tab = tab.EntityMods.TF2ItemBrowser_Item
									_, _, _, child_ply_bg = GetItemModelVisuals(tab.i, classes[tab.class].longname, tab.team, tab.style)
								end
								for k, v in pairs (child_ply_bg) do
									if isstring(k) then k = ent:FindBodygroupByName(k) end //on some items, k is a number already
									ent:SetBodygroup(k, v)
								end
							end
						end
						break
					end
				end
			end

			duplicator.StoreEntityModifier(e, "TF2ItemBrowser_Item", data)

		elseif input == "attach_item_remove" then

			local e = net.ReadEntity()
			if !IsValid(e) or e:GetParent() != ent or e:IsPlayer() then return end
			if !hook.Run("CanTool", ply, {Entity = e}, "remover", ply:GetTool("remover"), 1) then return end
			//TODO: what other hooks should we check to make sure this player is allowed to remove this entity? sandbox doesn't seem to have anything else obvious.

			//Check if this item was applying any bodygroup changes to the parent ent that we want to revert
			local tab = e:GetTable()
			if tab.EntityMods and tab.EntityMods.TF2ItemBrowser_Item then
				tab = tab.EntityMods.TF2ItemBrowser_Item
				local _, _, _, ply_bg = GetItemModelVisuals(tab.i, classes[tab.class].longname, tab.team, tab.style)
				for k, _ in pairs (ply_bg) do
					//If any ply_bg's were changed, then do the same routine as attach_item_modify above; get every attached 
					//item other than the one we're removing, and apply their ply_bg's again to a blank slate parent ent.
					for i = 0, ent:GetNumBodyGroups() do
						ent:SetBodygroup(i, 0)
					end
					for k, child in ipairs (ent:GetChildren()) do
						tab = child:GetTable()
						if child != e and tab.EntityMods and tab.EntityMods.TF2ItemBrowser_Item then
							tab = tab.EntityMods.TF2ItemBrowser_Item
							_, _, _, ply_bg = GetItemModelVisuals(tab.i, classes[tab.class].longname, tab.team, tab.style)
							for k, v in pairs (ply_bg) do
								if isstring(k) then k = ent:FindBodygroupByName(k) end //on some items, k is a number already
								ent:SetBodygroup(k, v)
							end
						end
					end
					break
				end
			end

			e:Remove()

		elseif input ==  "attach_skin" then

			ent:SetSkin(net.ReadUInt(8))

		end

	end)

	//i don't *think* this is necessary?
	//duplicator.RegisterEntityModifier("TF2ItemBrowser_Item", function(ply, ent, data)
	//	duplicator.StoreEntityModifier(ent, "TF2ItemBrowser_Item", data)
	//end)

	net.Receive("TF2ItemBrowser_AttachedItems_GetFromSv", function(_, ply)
		local ent = net.ReadEntity()
		if !IsValid(ent) then return end
		for _, ent2 in ipairs (ent:GetChildren()) do
			if ent2.EntityMods and ent2.EntityMods.TF2ItemBrowser_Item then
				local data = ent2.EntityMods.TF2ItemBrowser_Item
				net.Start("TF2ItemBrowser_AttachedItem_SendToCl", true)
					net.WriteEntity(ent2)
					net.WriteBool(false) //don't open upon received
					WriteItemDataTable(data)
				net.Send(ply)
			end
		end
	end)

else
	
	net.Receive("TF2ItemBrowser_AttachedItem_SendToCl", function()
		local ent = net.ReadEntity()
		local forceopen = net.ReadBool()
		local data = ReadItemDataTable()
		if !IsValid(ent) or !IsValid(TF2ItemBrowser) then return end
		local par = TF2ItemBrowser:GetEntity()
		if !IsValid(par) or ent:GetParent() != par then return end

		TF2ItemBrowser.atticons:AddItem(ent, data, forceopen)
	end)

end

properties.Add("tf2itembrowser_select", {
	MenuLabel = "Select with TF2 Item Browser",
	Order = 1,
	MenuIcon = "games/16/tf.png",
	AppendSpacer = true, //doesn't work, lame
	
	Filter = function(self, ent, ply)
		if !IsValid(TF2ItemBrowser) or !IsValid(ent) then return false end
		if !(ent:LookupBone("bip_pelvis") or (IsValid(ent.AttachedEntity) and ent.AttachedEntity:LookupBone("bip_pelvis"))) then return false end //make sure it has the right skeleton to attach tf2 items to
		if !gamemode.Call("CanProperty", ply, "tf2itembrowser_select", ent) then return false end
		return true
	end,

	Action = function(self, ent)
		TF2ItemBrowser:SetEntity(ent)
	end
})