local tf_lang = file.Read("resource/tf_english.txt", "tf")
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
local lang = GetConVar("gmod_language"):GetString()
if langs[lang] then
	lang = file.Read("resource/tf_" .. langs[lang] ..".txt", "tf")
	lang = util.KeyValuesToTable(lang, true, false).tokens
	table.Merge(tf_lang, lang)
end

local function GetTFLanguageString(str, return_str_on_fail)
	local result = ""
	if return_str_on_fail then result = str end
	if !isstring(str) then return result end

	result = tf_lang[string.TrimLeft(string.lower(str), "#")] or result
	return result
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
//
//add some value to the tournament medal prefab that we can filter for
//
//maybe better backpack icons for:
//1155 TF_WEAPON_PASSTIME GUN - this is the pass time jack, currently uses wrench icon
//1057 MvM GateBotLight Scout (and the others) - missing textures
//30143 tw_demobot_armor (and the others) - placeholder white circle
//
//just remove v.static_attrs.paintkit_proto_def_index from 9536 Paintkit, to make the paintkit filter below run faster


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

	//TODO: handle extra_wearable and extra_wearable_vm:
	//- if an item only has an extra_wearable and not a model_player(_per_class), then change it into one (a few spellbooks)
	//- if an item has an extra_wearable that's the same as its model_player, then get rid of it (sniper shields, maybe more)
	//- if an item has an extra_wearable_vm, then get rid of its extra_wearable and convert the _vm to visuals.attached_models (botkillers)


	if v.model_player == "" then v.model_player = nil end
	if v.model_player_per_class then //takes priority over v.model_player, not that anything has both except 378 The Team Captain
		if v.model_player_per_class.basename then
			for _, class in ipairs (classes) do
				//if this table contains both basename and class-specific strings, the class-specific ones take priority
				//(example: 987 The Merc's Muffler has a manually defined "engineer" path with ".../all_winter_scarf_engy.mdl",
				//so it doesn't use basename to auto-generate one with ".../all_winter_scarf_engineer.mdl" like the other classes)
				if v.used_by_classes[class.longname] and !v.model_player_per_class[class.longname] then
					v.model_player_per_class[class.longname] = string.Replace(v.model_player_per_class.basename, "%s", class.shortname)
				end
			end
	 	end
	elseif v.model_player then
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
	elseif (!v.model_player and !v.model_player_per_class and !extra_wearable and !v.visuals and !v.taunt) then
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










if CLIENT then

	local bgcol = Color(42,39,37,255) //eyedropped from tf2 loadout screen, don't know what the material is
	local LoadoutItemPopupBorder = GWEN.CreateTextureBorder(0, 0, 64, 64, 11, 11, 11, 11, Material("vgui/button_holder_central.vmt"))
	local GrayDialogBorder = GWEN.CreateTextureBorder(0, 0, 256, 128, 24, 24, 24, 24, Material("vgui/loadout_rect.vmt"))
	local TFThinLineBorder = GWEN.CreateTextureBorder(0, 0, 128, 128, 24, 24, 24, 24, Material("hud/tournament_panel_brown.vmt"))
	local item_icon_w = 64
	local item_icon_scale = item_icon_w/121 //tf2 backpack panels are 121x94 (???); scale ours down proportionately
	local item_icon_h = 94*item_icon_scale
	local item_icon_gap = 5
	local spinner = Material("vgui/animated/tf2_logo_hourglass.vmt")
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
		ItemFlag		= Color(117,107,94,255),
		ItemLimitedQuantity	= Color(225,209,0,255),]]
	}

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

	
	list.Set("DesktopWindows", "TF2ItemBrowser", {
		title		= "TF2 Item Browser",
		icon		= "games/16/tf.png", //TODO: temp
		width		= 960, //TODO: better values later
		height		= 700,
		onewindow	= true,
		init		= function(widgetIcon, window)

			local scroll = vgui.Create("DScrollPanel", window)
			scroll:SetWide(scroll.VBar:GetWide() + ((item_icon_w+item_icon_gap)*10))
			scroll:Dock(RIGHT)

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
				surface.SetDrawColor(bgcol.r, bgcol.g, bgcol.b, 192)
				surface.DrawRect(0,0,w,h)
	
				local mid_w, mid_h = (w-scroll.VBar:GetWide()-item_icon_gap)/2, h/2
				GrayDialogBorder(mid_w-50, mid_h-50, 100, 100)
				surface.SetMaterial(spinner)
				surface.DrawTexturedRect(mid_w-50, mid_h-50, 100, 100)
				//TODO: this is okay, but i want to do better. add a progress bar and text listing tostring(window.icons_to_add_key-1) .. "/" .. tostring(#window.icons_to_add)
			end
			scroll.OnChildAdded = old_OnChildAdded


			local filters_holder = vgui.Create("DPanel", window)
			filters_holder:DockPadding(24,24,24,24)
			filters_holder:Dock(FILL)

			function filters_holder:Paint(w,h)
				TFThinLineBorder(0,0,w,h)
			end

			local filters = vgui.Create("DScrollPanel", filters_holder)
			filters:Dock(FILL)


			TF2ItemBrowser = window
			function window:Paint(w, h)
				surface.SetDrawColor(bgcol)
				surface.DrawRect(0,0,w,h)
			end
			window:SetSizable(true)
			local p1, _, p2, _ = window:GetDockPadding()
			local p3, _, p4, _ = filters_holder:GetDockPadding()
			window:SetMinWidth(p1 + p2 + p3 + p4 + filters.VBar:GetWide() + scroll:GetWide())


			//ugly temporary filter options
			local betweenitems = 8
			local betweencategories = 20

			local search = vgui.Create("DTextEntry", filters)
			search:SetHeight(20)
			search:Dock(TOP)
			search:DockMargin(0,0,0,betweencategories)
			search:SetPlaceholderText("#spawnmenu.search")
			search:SetTooltip("#spawnmenu.enter_search")
			filters.search = search
			search.OnEnter = function()
				//TODO: update filters
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

			//make this use red/blu team icons later
			local check = vgui.Create("DCheckBoxLabel", filters)
			check:SetText("BLU")
			check:SetHeight(15)
			check:Dock(TOP)
			check:DockMargin(0,0,0,betweencategories)
			filters.team = check
			check.OnChange = function(_, val)
				//TODO: if in equip mode, update skins of equipped items
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
				for k, v in ipairs (classes) do
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
				for _, class in ipairs (classes) do
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
				for k, v in pairs (TF2Items.items) do
					//this filter is on by default and catches >75% of items, so check this first
					if DoIncludeExcludeFilter(filters.tm:GetValue(), v._tm) then continue end

					//TODO: search bar filter by name (+ other text too?)
					
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
				old_Think(self, ...)
			end

		end
	})










	local PANEL = {}

	AccessorFunc(PANEL, "m_iItemID", "ItemID" )

	function PANEL:Init()

		self:SetSize(item_icon_w, item_icon_h)
		self:SetDoubleClickingEnabled(false)
		self:SetText("")

		self.quality = "unique"
		self.rarity = nil

	end

	function PANEL:SetItemID(i)

		self.m_iItemID = i
		self.ImageToQueue = TF2Items.items[i].image_inventory
		self.quality = TF2Items.items[i].item_quality or self.quality
		self.rarity = TF2Items.items[i]._rarity or self.rarity //TODO: populate this value in the item defs by going through collections

		self.itemname = self:UpdateItemName()
		
	end

	function PANEL:UpdateItemName()

		//based on https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L610, it's a whopper
		//this is probably way overengineered for our use case, but oh well!

		local i = self:GetItemID()
		if !TF2Items.items[i] then return "Unknown Item" end

		local useProperName = true
		local ignoreWear = false
		local ignoreQuality = false
		if self.paintkit and self.quality != "strange" and self.quality != "selfmade" then
			ignoreQuality = true
		end
		
		// Start with the base name.
		local itemName = GetTFLanguageString(TF2Items.items[i].item_name, true) or "Unknown Item"

		//tf2 code here sets killstreak values, but this addon won't be doing those unless rubat implements $sheenmap someday

		if self.festivized then useProperName = false end

		local quality = ""
		if !ignoreQuality then 
			if self.quality != "normal" and self.quality != "paintkitweapon" then //tf2 code here checks nQuality > 0, which only filters out normal quality (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_constants.h#L516)
				if self.quality == "unique" then
					if useProperName and TF2Items.items[i].propername == 1 then 
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

	function PANEL:CreateMouseOverPanel()

		if IsValid(TF2ItemBrowser.MouseOverPanel) then TF2ItemBrowser.MouseOverPanel:Remove() end

		local pnl = vgui.Create("DPanel", TF2ItemBrowser)
		TF2ItemBrowser.MouseOverPanel = pnl
		pnl.Owner = self

		local pad = 25 //34 would match the padding in tf2's backpack screen, but our text is smaller (13px, from 18px), so scale it down proportionately
		pnl:DockPadding(pad,pad,pad,pad) 
		local w, h = 420, pad*2
		local function AddText(text, font, col)
			for _, v in ipairs (string.Explode("\n", textWrap(text, font, w-(pad*2)))) do
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
		end
		AddText(self.itemname, "TF2ItemBrowser_ItemName", rarity_colors[self.rarity] or quality_colors[self.quality])
		//TODO: real level and description text
		AddText("Level 7 Boxing Gloves", "TF2ItemBrowser_ItemDesc", desc_colors.level)
		AddText("On Kill: 5 seconds of 100% critical chance\nAlso Here's Another Line", "TF2ItemBrowser_ItemDesc", desc_colors.positive)
		pnl:SetSize(w,h)

		local x, y = TF2ItemBrowser:ScreenToLocal(self:LocalToScreen(self:GetWide()/2, self:GetTall()))
		local b_w, b_h = TF2ItemBrowser:GetSize()
		x = math.max(0,x-w/2) //center the panel with the icon, but don't let the left side of the panel go beyond the left side of the browser
		if x+w > b_w then //if the right side of the panel goes beyond the right side of the browser, then move it left
			x = x - ((x+w)-b_w)
		end
		if y+h > b_h then //if the bottom of the panel goes beyond the bottom of the browser, then move it above the item icon
			y = y-self:GetTall()-h
		end
		pnl:SetPos(x, y)
		
		function pnl:Paint(w,h)
			LoadoutItemPopupBorder(0,0,w,h)
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

		if self:IsHovered() then
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

		if self:IsDown() then
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

	function PANEL:DoClick()

		//test
		MsgN(self:GetItemID(), " ", TF2Items.items[self:GetItemID()].name)
		PrintTable(TF2Items.items[self:GetItemID()])
		MsgN("")

	end

	vgui.Register("TF2ItemIcon", PANEL, "DButton")

end