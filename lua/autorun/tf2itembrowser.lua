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
//"demo" in all model paths, and either one interchangably in equip region names. dumb!!!
for k, v in ipairs (classes) do
	local shortname = v
	if v == "demoman" then shortname = "demo" end
	classes[k] = {shortname = shortname, longname = v}
end


local _s = file.Read("scripts/items/items_game.txt", "tf")
local s = util.KeyValuesToTable(_s, false, true)
local s2 = util.KeyValuesToTablePreserveOrder(_s, false, true)

//some item defs contain multiple of the same subtable, but util.KeyValuesToTable squashes all but the last one, so we have to retrieve them using
//util.KeyValuesToTablePreserveOrder. evidently, TF2 reads the information from all of them, example: 31553 El Gigante's Gunbelt, which has one 
//"visuals" table containing only bodygroups, and another "visuals" table containing only styles, both of which are used in TF2.
local done = 0
for k, v in ipairs (s2) do
	if v.Key == "items" or v.Key == "prefabs" then
		local function ReadOrderedTableMergingSubTables(tab)
			if !istable(tab) then
				return tab
			else
				local res = {}
				local stupid_zero_fix //KeyValuesToTablePreserveOrder breaks keys called "0" https://github.com/Facepunch/garrysmod-issues/issues/6891
				for k, v in ipairs (tab) do
					local res_v = ReadOrderedTableMergingSubTables(v.Value)
					v.Key = tonumber(v.Key) or v.Key //these are all strings by default, even if they should be numbers
					if v.Key == 0 then
						stupid_zero_fix = true
					elseif v.Key == 1 and !stupid_zero_fix then
						v.Key = 0
						stupid_zero_fix = true
					end
					if !res[v.Key] or !istable(res_v) then
						res[v.Key] = res_v
					else
						table.Merge(res[v.Key], res_v)
					end
				end
				return res
			end
		end
		s[v.Key] = ReadOrderedTableMergingSubTables(v.Value)
		done = done + 1
		if done == 2 then break end
	end
end


//inject custom values into a few items

local function SafeAmendItem(i, expected_name, func)
	local found_name
	if s.items[i] then found_name = s.items[i].name end
	if found_name != expected_name then
		MsgN("WARNING: TF2ItemBrowser tried to amend item ", i, " ", expected_name, ", but found ", i, " ", found_name, " at this index! Item schema must have been updated, make sure this addon's changes aren't outdated!")
	end
	local tab = s.items[i]
	tab = func(tab) or tab
	if tab == "remove" then tab = nil end
	s.items[i] = tab
end

//custom values for filters
s.prefabs.paintkit_base._paintkit = true
s.prefabs.tournament_medal._tm = true

//Almost all stock weapons have two variants - the default items, which are located at the top of the list, and the "Upgradeable" items, which are 
//exactly the same except they're unique-quality and contain extra info for customization like paintkits and australiums... and are located much 
//further down the list. We want to get rid of the less useful copies and only show the upgradable ones, but keep them at the top of the list 
//because that's the intuitive place to look for them, so instead we *replace* all the stock variants with the upgradable variants.
for _, tab in ipairs ({
	{0, "TF_WEAPON_BAT", 190, "Upgradeable TF_WEAPON_BAT"},
	{1, "TF_WEAPON_BOTTLE", 191, "Upgradeable TF_WEAPON_BOTTLE"},
	{2, "TF_WEAPON_FIREAXE", 192, "Upgradeable TF_WEAPON_FIREAXE"},
	{3, "TF_WEAPON_CLUB", 193, "Upgradeable TF_WEAPON_CLUB"},
	{4, "TF_WEAPON_KNIFE", 194, "Upgradeable TF_WEAPON_KNIFE"},
	{5, "TF_WEAPON_FISTS", 195, "Upgradeable TF_WEAPON_FISTS"},
	{6, "TF_WEAPON_SHOVEL", 196, "Upgradeable TF_WEAPON_SHOVEL"},
	{7, "TF_WEAPON_WRENCH", 197, "Upgradeable TF_WEAPON_WRENCH"},
	{8, "TF_WEAPON_BONESAW", 198, "Upgradeable TF_WEAPON_BONESAW"},
	{9, "TF_WEAPON_SHOTGUN_PRIMARY", 199, "Upgradeable TF_WEAPON_SHOTGUN_PRIMARY"},
	{13, "TF_WEAPON_SCATTERGUN", 200, "Upgradeable TF_WEAPON_SCATTERGUN"},
	{14, "TF_WEAPON_SNIPERRIFLE", 201, "Upgradeable TF_WEAPON_SNIPERRIFLE"},
	{15, "TF_WEAPON_MINIGUN", 202, "Upgradeable TF_WEAPON_MINIGUN"},
	{16, "TF_WEAPON_SMG", 203, "Upgradeable TF_WEAPON_SMG"},
	{17, "TF_WEAPON_SYRINGEGUN_MEDIC", 204, "Upgradeable TF_WEAPON_SYRINGEGUN_MEDIC"},
	{18, "TF_WEAPON_ROCKETLAUNCHER", 205, "Upgradeable TF_WEAPON_ROCKETLAUNCHER"},
	{19, "TF_WEAPON_GRENADELAUNCHER", 206, "Upgradeable TF_WEAPON_GRENADELAUNCHER"},
	{20, "TF_WEAPON_PIPEBOMBLAUNCHER", 207, "Upgradeable TF_WEAPON_PIPEBOMBLAUNCHER"},
	{21, "TF_WEAPON_FLAMETHROWER", 208, "Upgradeable TF_WEAPON_FLAMETHROWER"},
	{22, "TF_WEAPON_PISTOL", 209, "Upgradeable TF_WEAPON_PISTOL"},
	{24, "TF_WEAPON_REVOLVER", 210, "Upgradeable TF_WEAPON_REVOLVER"},
	{25, "TF_WEAPON_PDA_ENGINEER_BUILD", 737, "Upgradeable TF_WEAPON_PDA_ENGINEER_BUILD"},
	{29, "TF_WEAPON_MEDIGUN", 211, "Upgradeable TF_WEAPON_MEDIGUN"},
	{30, "TF_WEAPON_INVIS", 212, "Upgradeable TF_WEAPON_INVIS"},
	{735, "TF_WEAPON_BUILDER_SPY", 736, "Upgradeable TF_WEAPON_BUILDER_SPY"},
	{31, nil, 735, "Upgradeable TF_WEAPON_BUILDER_SPY"}, //move the sapper into the unused 31 slot so it's not all the way down there
	//these two action items weren't converted into stock until after release, but the stock variant is the only one that 
	//the game gives to players now, so do the opposite and move the stock variant into the earlier unique variant's spot
	{489, "Power Up Canteen (MvM)", 1163, "Default Power Up Canteen (MvM)"},
	{1070, "Basic Spellbook", 1132, "TF_WEAPON_SPELLBOOK"},
}) do
	//MsgN("trying to change ", tab[1], " ", tab[2], " into ", tab[3], " ", tab[4])
	SafeAmendItem(tab[1], tab[2], function(i)
		local tab2 = table.Copy(s.items[tab[3]])
		tab2.item_quality = "normal"
		return tab2
	end)
	SafeAmendItem(tab[3], tab[4], function(i) return "remove" end)
end

//this stock item is called "PDA" and uses the destruction pda icon, but its model is engi's toolbox
SafeAmendItem(28, "TF_WEAPON_BUILDER", function(i) 
	i.item_name =--[["#LoadoutSlot_Building"]] "Toolbox" //not localized! bad!!
	i.item_type_name = "#LoadoutSlot_Building"
	i.image_inventory = "backpack/weapons/w_models/w_toolbox"
end)

//remove redundant copies of items
for _, tab in ipairs ({
	{10, "TF_WEAPON_SHOTGUN_SOLDIER"},
	{11, "TF_WEAPON_SHOTGUN_HWG"},
	{12, "TF_WEAPON_SHOTGUN_PYRO"},
	{23, "TF_WEAPON_PISTOL_SCOUT"},
	{743, "Autogrant Pyrovision Goggles"}, //copy of 744 "Pyrovision Goggles"
	{831, "Promo Red-Tape Recorder"}, //copies of 810-817, non-promo versions of the same items
	{832, "Promo Huo Long Heatmaker"},
	{833, "Promo Flying Guillotine"},
	{834, "Promo Neon Annihilator"},
	{835, "Promo Triad Trinket"},
	{836, "Promo Champ Stamp"},
	{837, "Promo Marxman"},
	{838, "Promo Human Cannonball"},
	//{1184, "Gloves of Running Urgently MvM"}, //visually the same as 239 "Gloves of Running Urgently" but has different attributes
	{30739, "Promo Fear Monger"}, //copy of 30724 "Fear Monger"
	{30740, "Promo Arkham Cowl"}, //copy of 30720 "Arkham Cowl"
	{30741, "Promo The Firefly"}, //copy of 30721 "The Firefly"
	{8936, "Halloween Spellbook Page (Achievement)"}, //copy of 8935 "Halloween Spellbook Page" except it applies different spellbook page in TF2
}) do
	SafeAmendItem(tab[1], tab[2], function(i) return "remove" end)
end

//these items have existing models in the files, but aren't assigned in the schema; add them anyway
s.prefabs.spell_base_footprints.model_player = "models/props_halloween/flask_bottle.mdl"
s.prefabs.voice_spell_base.model_player = "models/props_halloween/flask_erlenmeyer.mdl"
s.prefabs.spell_base.model_player = "models/props_halloween/flask_florence.mdl"
s.prefabs.spell_base_pumpkinbombs.model_player = "models/props_halloween/flask_tub.mdl"
SafeAmendItem(8925, "Halloween Spell: Spectral Flame", function(i) i.model_player = "models/props_halloween/flask_tube.mdl" end)
SafeAmendItem(8921, "Halloween Spell: Exorcism", function(i) i.model_player = "models/props_halloween/flask_vial.mdl" end)
SafeAmendItem(1068, "Halloween Unfilled Spellbook", function(i) i.model_player = "models/props_halloween/hwn_spellbook_incomplete.mdl" end)
s.prefabs.halloween2013_spellbookpage.model_player = "models/props_halloween/hwn_spellbook_page.mdl"
SafeAmendItem(1070, "TF_WEAPON_SPELLBOOK", function(i) i.model_player = "models/props_halloween/hwn_spellbook_magazine.mdl" end)
SafeAmendItem(5821, "Invasion Key", function(i) i.model_player = "models/workshop/cases/invasion_case/invasion_key.mdl" end)
SafeAmendItem(5827, "Halloween 2015 Key", function(i) i.model_player = "models/crafting/halloween2015_gargoyle_key.mdl" end)
SafeAmendItem(5808, "Unused Summer 2015 Operation Pass", function(i) i.model_player = "models/crafting/ticket_summer2015.mdl" end)
SafeAmendItem(5829, "Unused Operation Tough Break Pass", function(i) i.model_player = "models/crafting/ticket_tough_break.mdl" end)
//SafeAmendItem(2129, "Love & War Taunt Bundle", function(i) i.model_player = "models/player/items/crafting/bundle_of_taunts.mdl" end) //eehh, broken materials
//SafeAmendItem(5734, "Supply Crate Ration", function(i) i.model_player = "models/player/items/crafting/crate_variation.mdl" end) //eehh, broken materials; there's 7 more of these, and one of them uses a different skin which is only partially broken
//change spy watches to use these armless separated models instead, just because they spawn better; the defaults are 
//viewmodels so they aren't attachable either way. none of the watch reskins have models like these, unfortunately.
SafeAmendItem(30, "Upgradeable TF_WEAPON_INVIS", function(i) i.model_player = "models/weapons/c_models/c_spy_watch.mdl" end)
SafeAmendItem(60, "The Cloak and Dagger", function(i) i.model_player = "models/weapons/c_models/c_leather_watch/parts/c_leather_watch.mdl" end)
SafeAmendItem(59, "The Dead Ringer", function(i) i.model_player = "models/weapons/c_models/c_pocket_watch/parts/c_pocket_watch.mdl" end)

//remove paintkit attribute from the generic paintkit tool item so that it doesn't get filtered out with all the paintkit weapons/tools below
SafeAmendItem(9536, "Paintkit", function(i) i.static_attrs.paintkit_proto_def_index = nil end)

//remove the existing models for the hatless scout/engie/sniper so that we use the fallback instead; advbonemerge doesn't like these 
//models and won't be able to do unusuals with them, also if we do fallbacks then we can show the playermodel in the spawn window
SafeAmendItem(111, "Baseball Bill's Sports Shine", function(i) i.model_player = nil end)
SafeAmendItem(117, "Ritzy Rick's Hair Fixative", function(i) i.model_player = nil end)
SafeAmendItem(118, "Texas Slim's Dome Shine", function(i) i.model_player = nil end)

//TODO: better backpack icons (and names?) for:
//1155 TF_WEAPON_PASSTIME GUN - this is the pass time jack, currently uses wrench icon and no name
//1057 MvM GateBotLight Scout (and the others) - missing textures and all use the same name
//30143 tw_demobot_armor (and the others) - placeholder white circle


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


//these weapon reskins unintentionally inherit australium styles that don't work from their base weapons, get rid of them
//(this has to be done after InheritPrefabValues because some (not all) of these come from prefabs)
SafeAmendItem(266, "The Horseless Headless Horseman's Headtaker", function(i) i.visuals.styles = nil end)
SafeAmendItem(482, "Nessie's Nine Iron", function(i) i.visuals.styles = nil end)
SafeAmendItem(1082, "Festive Eyelander", function(i) i.visuals.styles = nil end)
SafeAmendItem(1085, "Festive Black Box", function(i) i.visuals.styles = nil end)
SafeAmendItem(1149, "Festive SMG 2014", function(i) i.visuals.styles = nil end)


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
	or (v.static_attrs and v.static_attrs.paintkit_proto_def_index) //war paint items
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
	//Add submodels for soldier banners
	elseif v.item_class == "tf_weapon_buff_item" then
		local banners = { //banner models are hard-coded by buff type (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/tf/tf_weapon_buff_item.cpp#L40-L46)
			[1] = "models/weapons/c_models/c_buffbanner/c_buffbanner.mdl",
			[2] = "models/workshop/weapons/c_models/c_battalion_buffbanner/c_battalion_buffbanner.mdl",
			[3] = "models/workshop_partner/weapons/c_models/c_shogun_warbanner/c_shogun_warbanner.mdl",
		}
		v.extra_wearable_2 = banners[v.attributes["mod soldier buff type"].value] //silly custom "extra_wearable_2" value for additional wearable
	//Add submodel and selectable inactive/active styles for 1101 The B.A.S.E. Jumper
	elseif v.item_class == "tf_weapon_parachute" then
		v.visuals = v.visuals or {}
		v.visuals.styles = {
			[0] = {
				name = "#TF_Quest_Status_Inactive", //Inactive
				_anim = {attached = "ACT_PARACHUTE_RETRACT_IDLE"}
			},
			[1] = {
				name = "#QuestLog_Active", //"Active"
				model_player = "models/workshop/weapons/c_models/c_paratooper_pack/c_paratrooper_pack_open.mdl", //parachute model paths seem to be hard-coded as well (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/tf/tf_weapon_buff_item.cpp#L45-L49)
				_anim = {attached = "ACT_PARACHUTE_DEPLOY_IDLE"}
			}
		}
		v.visuals.attached_models = {
			[0] = {
				model = "models/workshop/weapons/c_models/c_paratooper_pack/c_paratrooper_parachute.mdl"
			}
		}
	//Add placement/placed styles for sappers
	elseif (v.item_class == "tf_weapon_builder" and v.used_by_classes.spy) or v.item_class == "tf_weapon_sapper" then
		local name = string.sub(string.StripExtension(string.GetFileFromFilename(v.model_world or v.model_player)), 3)
		v.visuals = v.visuals or {}
		v.visuals.styles = {
			[0] = {
				name = "#Normal"
			},
			[1] = {
				name = "#TR_Eng_MoveTitle", //Building Placement
				model_player = "models/buildables/" .. name .. "_placement.mdl" //these are hard-coded based on the item model in tf2 code (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/server/tf/tf_obj_sapper.cpp#L396)
			},
			[2] = {
				name = "#TR_Eng1_SpyRemoveTitle", //Sapped Buildings; not the best name, but there aren't any strings for words like "placed, built, attached, deployed"
				model_player = "models/buildables/" .. name .. "_placed.mdl"
			},
		}
	//Add selectable inactive/active styles for 1179 The Thermal Thruster
	elseif v.item_class == "tf_weapon_rocketpack" then
		v.visuals = v.visuals or {}
		v.visuals.styles = {
			[0] = {
				name = "#TF_Quest_Status_Inactive", //Inactive
				_anim = {item = "ACT_ITEM_UNDEPLOYED_IDLE"}
			},
			[1] = {
				name = "#QuestLog_Active", //"Active"
				_anim = {item = "ACT_ITEM_DEPLOYED_IDLE"}
			}
		}
	end
	//Catch items that have a visuals.playback_activity table (148 "Engineer Welding Mask" and 745 "The Infernal Orchestrina") and convert those to selectable styles
	if v.visuals and v.visuals.playback_activity then
		v.visuals.styles = {
			[0] = {
				name = "#Normal",
				_anim = {item = v.visuals.playback_activity.on_spawn}
			}
		}
		if v.visuals.playback_activity.start_building then
			v.visuals.styles[1] = {
				name = "#Hud_Menu_Build_Title", //Build
				_anim = {item = v.visuals.playback_activity.start_building}
			}
		elseif v.visuals.playback_activity.start_taunting then
			v.visuals.styles[1] = {
				name = "#Hud_Menu_Taunt_Title", //Taunt
				_anim = {item = v.visuals.playback_activity.start_taunting}
			}
		end
	end
	//Clear visuals tables that don't contain anything useful, so that we can clear out items with no useful visual 
	//data at the end of this function (example: noisemakers have "visuals" tables containing only sound paths)
	for _, v2 in pairs (visuals_tabs) do
		if v[v2] then
			if !(v[v2].attached_models or v[v2].attached_models_festive or v[v2].attached_particlesystems or v[v2].material_override or v[v2].player_bodygroups 
			or v[v2].player_poseparam or v[v2].skin or v[v2].styles or v[v2].use_per_class_bodygroups or v[v2].wm_bodygroup_override) then
				v[v2] = nil
			end
		end
		//Note: there's also a fourth table, visuals_mvm_boss, which contains overrides used only by 
		//mvm giants, but the 2 instances of this only contain sounds, so we don't care about these
	end


	//Grab style names and prefixes for australiums and campaign ranks
	if CLIENT and v.visuals and v.visuals.styles then
		for k2, v2 in pairs (v.visuals.styles) do
			if !v2.name and v2.image_inventory then
				local name, strange_prefix, aus_prefix
				if string.StartsWith(v2.image_inventory, "backpack/player/items/crafting/coin_summer2015")
				or string.StartsWith(v2.image_inventory, "backpack/player/items/crafting/stamp_winter2016") then
					if string.EndsWith(v2.image_inventory, "_gravel") then
						strange_prefix = "#KillEater_OperationContractRank0"
					elseif string.EndsWith(v2.image_inventory, "_bronze") then
						strange_prefix = "#KillEater_OperationContractRank1"
					elseif string.EndsWith(v2.image_inventory, "_silver") then
						strange_prefix = "#KillEater_OperationContractRank2"
					elseif string.EndsWith(v2.image_inventory, "_gold") then
						strange_prefix = "#KillEater_OperationContractRank3"
					end
				elseif string.StartsWith(v2.image_inventory, "backpack/player/items/crafting/hwn2015_gargoyle") then
					if string.EndsWith(v2.image_inventory, "_stone") then
						strange_prefix = "#KillEater_HalloweenSoulsRank0"
					elseif string.EndsWith(v2.image_inventory, "_bronze") then
						strange_prefix = "#KillEater_HalloweenSoulsRank1"
					elseif string.EndsWith(v2.image_inventory, "_silver") then
						strange_prefix = "#KillEater_HalloweenSoulsRank2"
					elseif string.EndsWith(v2.image_inventory, "_gold") then
						strange_prefix = "#KillEater_HalloweenSoulsRank3"
					end
				elseif string.StartsWith(v2.image_inventory, "backpack/player/items/cyoa_pda/cyoa_pda") then
					if string.EndsWith(v2.image_inventory, "_bronze") then
						strange_prefix = "#KillEater_ContractPointsEarnedRank1"
					elseif string.EndsWith(v2.image_inventory, "_silver") then
						strange_prefix = "#KillEater_ContractPointsEarnedRank2"
					elseif string.EndsWith(v2.image_inventory, "_gold") then
						strange_prefix = "#KillEater_ContractPointsEarnedRank3"
					else //the contracker's first style has no suffix
						strange_prefix = "#KillEater_ContractPointsEarnedRank0"
					end
				else
					if string.EndsWith(v2.image_inventory, "_gold") then
						aus_prefix = true
						name = string.Trim(GetTFLanguageString("ItemNameAustralium", true))
					end
				end
				if strange_prefix then name = string.Trim(GetTFLanguageString(strange_prefix, true)) end
				v.visuals.styles[k2].name = name
				v.visuals.styles[k2].strange_prefix = strange_prefix
				v.visuals.styles[k2].aus_prefix = aus_prefix
			end
		end
	end


	v.model_player = v.model_world or v.model_player //a few items (hot hand) have a model_world that's different from model_player (which is a viewmodel instead), so use the worldmodel
	if v.model_player == "" then v.model_player = nil end
	//if an item only has an extra_wearable and not a model_player(_per_class), then change it into one (base jumper, diary, spellbook)
	if v.extra_wearable and !v.model_player and !v.model_player_per_class then
		v.model_player = v.extra_wearable
		v.extra_wearable = nil
	end
	//if an item has an extra_wearable that's the same as its model_player, then get rid of it (sniper shields and thruster)
	if v.extra_wearable and v.extra_wearable == v.model_player then
		v.extra_wearable = nil
	end
	//if an item has an extra_wearable_vm, then it's actually treated like a visuals.attached_models entry, so convert it to one (botkillers) 
	//(https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/tf/tf_weaponbase.cpp#L1018-L1022) if i remember correctly,
	//this is a contrivance to get around the fact that in tf2, attached_models don't support jigglebones or something like that
	if v.extra_wearable_vm then
		local attach = {model = v.extra_wearable or v.extra_wearable_vm}
		if v.visuals_red and v.visuals_red.attached_models then
			table.insert(v.visuals_red.attached_models, table.Count(v.visuals_red.attached_models), attach) //the table.Count thing is an awkward way of sorting these into a sequential table starting with 0, which lua doesn't do by default
			table.insert(v.visuals_blu.attached_models, table.Count(v.visuals_blu.attached_models), attach)
		else
			v.visuals = v.visuals or {}
			v.visuals.attached_models = v.visuals.attached_models or {}
			table.insert(v.visuals.attached_models, table.Count(v.visuals.attached_models), attach)
		end
		v.extra_wearable = nil
		v.extra_wearable_vm = nil
	end
	//Taunts: I'd like to use animprops to play these animations (especially to sync up big taunt props like the chair, or a second playermodel for
	//partner taunts), but all the animation references use .vcd scene paths, which are all compiled into a single large scenes.image file, which 
	//means we'd have to either:
	//A: write an entire scenes.image file parser, which would be quite the undertaking
	//or B: manually hard-code every past and future taunt item, forever.
	//For now, let's just use these to spawn taunt props.
	if v.taunt and !v.taunt.custom_taunt_prop_per_class then v.taunt = nil end


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
	elseif (!v.model_player and !v.model_player_per_class and !v.visuals and !v.taunt) then
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

//Given an item data table with id, class, team, style, returns a table with the models, skin, and bodygroups to use.
local function GetItemModelVisuals(data)

	local i = TF2Items.items[data.id]
	local vis = {
		models = {},
		skin = nil,
		item_bg = {},
		ply_bg = {}
	}
	local model

	//First go through standard values on the item
	model = GetClassModelWithBasename(i.model_player_per_class, data.class) or i.model_player
	vis.skin = i.default_skin or GetVisualsValue(i, data.team, "skin")
	local classbg = GetVisualsValue(i, data.team, "use_per_class_bodygroups")
	if classbg and classbg == 1 then
		classbg = {scout = 0, sniper = 1, soldier = 2, demoman = 3, medic = 4, heavy = 5, pyro = 6, spy = 7, engineer = 8}
		vis.item_bg["class"] = classbg[data.class]
	end
	for k, v in pairs (GetVisualsValue(i, data.team, "player_bodygroups") or {}) do
		vis.ply_bg[k] = v //v can be 0, such as in prefab item_bak_fear_monger
	end
	local num_bg_k, num_bg_v = GetVisualsValue(i, data.team, "wm_bodygroup_override"), GetVisualsValue(i, data.team, "wm_bodygroup_state_override")
	if num_bg_k and num_bg_v then
		//only used by 528 The Short Circuit and 524 The Purity Fist; this key is a bodygroup id number instead
		//of a bodygroup name, so we'll have to add special handling just for these two items, oh boy!
		vis.ply_bg[num_bg_k] = num_bg_v
	end
	//note: there's also visuals.show_player_bodygroup_name, only used by 1098 The Classic with value "bullets"; 
	//i don't think this does anything, because if it did, it would make the classic show the sleeper's darts

	//Now get overrides from style
	if i.visuals and i.visuals.styles then //this is never contained in visuals_red/visuals_blu
		local style = i.visuals.styles[data.style]
		if !data.team and style.model_player_per_class_red then
			model = GetClassModelWithBasename(style.model_player_per_class_red, data.class)
		elseif data.team and style.model_player_per_class_blue then
			model = GetClassModelWithBasename(style.model_player_per_class_blue, data.class)
		elseif style.model_player_per_class then
			model = GetClassModelWithBasename(style.model_player_per_class, data.class)
		elseif style.model_player then
			model = style.model_player
		end
		//note: 1033 The TF2VRH has a unique style.model_player_per_class_alt table for alternate models to use in vr mode, but 
		//there's already a second style that uses these alternate models regardless, so this is useless, we don't care about it
		if !data.team and style.skin_red then
			vis.skin = style.skin_red
		elseif data.team and style.skin_blu then
			vis.skin = style.skin_blu
		elseif style.skin then
			vis.skin = style.skin
		end
		if style.bodygroup then
			//currently it's only possible to have to change one bodygroup at a time
			vis.item_bg[style.bodygroup.name] = style.bodygroup.submodel_index
		end
		if style.additional_hidden_bodygroups then
			for k, v in pairs (style.additional_hidden_bodygroups) do
				vis.ply_bg[k] = v
			end
		end
	end

	if vis.skin == nil then
		//by default, red team uses skin 0, and blu team uses skin 1
		if !data.team then vis.skin = 0 else vis.skin = 1 end 
	end
	vis.models.item = model //can be nil
	local att = GetVisualsValue(i, data.team, "attached_models")
	if att then
		vis.models.attached = {}
		for k, v in SortedPairs (att) do
			table.insert(vis.models.attached, v.model)
		end
	end
	local att = GetVisualsValue(i, data.team, "attached_models_festive")
	if att then
		vis.models.attached_festive = {}
		for k, v in SortedPairs (att) do
			table.insert(vis.models.attached_festive, v.model)
		end
	end
	vis.models.wearable = i.extra_wearable
	vis.models.wearable_2 = i.extra_wearable_2
	if i.taunt and i.taunt.custom_taunt_prop_per_class then vis.models.taunt_prop = i.taunt.custom_taunt_prop_per_class[data.class] end
	if i.static_attrs then
		vis.models.stat_clock = i.static_attrs.weapon_uses_stattrak_module
		vis.stat_clock_scale = i.static_attrs.weapon_stattrak_module_scale
	end

	return vis

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
			window.Right = right_holder
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
				for k, v in ipairs ({"(any)", "weapon", "cosmetic", --[["taunt",]] "other"}) do
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
					//taunt = "taunt"
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
							item.data = v //this will be populated with the default data table for this item once the icon renders
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

				item:SetData(data)
				
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
				if IsValid(window.SpawnPanel) then
					window.SpawnPanel.Refresh()
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
							filters.class:ChooseOptionID(k)
							break
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

					if input == "item_spawn" or input == "attach_item_spawn" then

						WriteItemDataTable(args[1]) //item data table
						net.WriteBool(GetConVar("cl_tf2itembrowser_advbone"):GetBool())

					elseif input == "attach_item_modify" then

						WriteItemDataTable(args[2]) //item data table
						net.WriteBool(GetConVar("cl_tf2itembrowser_advbone"):GetBool())
						net.WriteEntity(args[1]) //item ent to modify

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

	function PANEL:Init()

		self:SetSize(item_icon_w, item_icon_h)
		self:SetDoubleClickingEnabled(false)
		self:SetText("")

	end

	function PANEL:SetData(data)

		if data then
			self.data = data
		else
			//this can be called with no arg just to make the panel acknowledge changes made to the data table
			data = self.data
		end
		local i = TF2Items.items[data.id]

		//submodels that aren't used by this item are set to nil instead of false, so that we know not to add controls for them
		local vis = GetItemModelVisuals(data)
		if !vis.models.item then data.models.item = nil end
		if !vis.models.wearable then data.models.wearable = nil end
		if !vis.models.wearable_2 then data.models.wearable_2 = nil end
		if !vis.models.taunt_prop then data.models.taunt_prop = nil
		elseif !vis.models.item then data.models.taunt_prop = true end
		if !vis.models.attached_festive then data.models.attached_festive = nil end
		if !vis.models.stat_clock then data.models.stat_clock = nil end

		local img_override
		if i.visuals and i.visuals.styles then
			img_override = i.visuals.styles[data.style].image_inventory
			self.strange_prefix = i.visuals.styles[data.style].strange_prefix
			self.aus_prefix = i.visuals.styles[data.style].aus_prefix
		end 
		img_override = img_override or i.image_inventory
		if !self.mat or self.mat:GetName() != img_override then
			self.mat = nil
			self.ImageToQueue = img_override
		end
		local quality_override
		if data.todo_replace_with_actual_unusual_effect_data_value then //TODO: unusual effect
			quality_override = "unusual"
		elseif data.models.stat_clock or self.aus_prefix then
			quality_override = "strange"
		elseif i.item_quality == "normal" and data.models.attached_festive then
			quality_override = "unique"
		end
		self.quality = quality_override or i.item_quality or "unique"
		self.rarity = i._rarity or nil
		self.sound_pressed = i.mouse_pressed_sound or "ui/item_default_pickup.wav"
		self.sound_drop = i.drop_sound or "ui/item_default_drop.wav"

		self.itemname = self:UpdateItemName()
		self.itemdesc = self:UpdateItemDescription()

	end

	function PANEL:SetDefaultData()

		//When the icon is first created, it's only assigned an id number, and then when the icon becomes visible, Paint calls this func
		//to populate the data table. This is so we don't have to run all this a thousand times at once for icons we might not even use.
		local id = self.data
		if istable(id) then id = self.data.id end
		local i = TF2Items.items[id]

		local _, class = TF2ItemBrowser.filters.class:GetSelected()
		if class == "(any)" then
			//go through classes in order, default to the first one that can use this item
			for k, v in ipairs (classes) do 
				if i.used_by_classes[v.longname] then
					class = v.longname
					break
				end
			end
		end

		local style = 0
		if i.visuals and i.visuals.styles then
			//default to the first style listed; i THINK this is always 0 but let's make extra sure
			for k, v in SortedPairs (i.visuals.styles) do //this starts from 0 so we can't do ipairs
				style = k
				break
			end
		end

		self:SetData({
			id = id, 
			class = class, 
			team = TF2ItemBrowser.attopts.team:GetChecked(),
			style = style,

			models = {
				item = true,
				wearable = true,
				wearable_2 = false,
				taunt_prop = false,
				attached_festive = false,
				stat_clock = false,
			},
		})

	end

	function PANEL:UpdateItemName()

		//based on https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L610, it's a whopper
		//this is probably way overengineered for our use case, but oh well!

		local i = TF2Items.items[self.data.id]
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

		if self.data.models.attached_festive then useProperName = false end

		local quality = ""
		if !ignoreQuality then 
			if self.strange_prefix then
				quality = GetTFLanguageString(self.strange_prefix) .. GetTFLanguageString("Strange_Spacer") //yeah, no check for valid string on this one
			elseif self.quality != "normal" and self.quality != "paintkitweapon" then //tf2 code here checks nQuality > 0, which only filters out normal quality (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_constants.h#L516)
				if self.quality == "unique" then
					if useProperName and i.propername == 1 then 
						quality = GetTFLanguageString("TF_Unique_Prepend_Proper")
					end
				else // Any quality besides unique ignores "proper name" articles.
					quality = GetTFLanguageString(self.quality)
					if quality != "" then quality = quality .. GetTFLanguageString("#Rarity_Spacer") end
				end
			end

			//tf2 code here sets strange ranks, which we only care about for campaign ranks and handle above, 
			//but also prepends strange rank onto strange unusual items, which in our use cases, only applies 
			//to weapons with both an unusual effect and a stat clock enabled.
			if self.quality != "strange" and self.data.models.stat_clock then
				quality = GetTFLanguageString("strange") .. " " .. quality
			end
		end

		local australium_skin = ""
		if self.aus_prefix then
			australium_skin = GetTFLanguageString("ItemNameAustralium")
		end

		local festivized = ""
		if self.data.models.attached_festive then festivized = GetTFLanguageString("ItemNameFestive") end

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
		local i = TF2Items.items[self.data.id]
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
			//the former also has a use case for showing strange ranks in place of levels, but this addon doesn't need those; 
			//all we need from that method is the stat clock attrib, which we'll do below.
			
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

		//do statclocks here; in tf2 code, this is done by Generate_ItemLevelDesc calling Generate_ItemLevelDesc_StrangeNameAndStats
		//even if it has a rarity instead; in our case, we can have statclocks even on non-paintkit items, so don't replace the 
		//standard Level X Thing text with this, even if that's what the tf2 code would do if that were possible
		if self.data.models.stat_clock then
			local rank = GetTFLanguageString("Attrib_stattrakmodule")
			if rank != "" then
				rank = string.Replace(rank, "%s1", GetTFLanguageString("KillEaterRank0"))
			end
			table.insert(desc, {str = rank, col = quality_colors.strange})
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

		//Keeps a popup panel contained within the right side of TF2ItemBrowser (never cover up the options list 
		//on the left side) but also centered on this item icon to the extent it can without going out-of-bounds.
		local w, h = pnl:GetSize()
		local x, y = TF2ItemBrowser.Right:ScreenToLocal(self:LocalToScreen(self:GetWide()/2, self:GetTall()))
		local b_w, b_h = TF2ItemBrowser.Right:GetSize()

		//by default, the panel is positioned below the icon, but won't go past the left side of the browser
		x = math.max(0,x-(w/2)) 
		//if the right side of the panel goes past the right side of the browser, then move it left
		if x+w > b_w then x = x - (x+w-b_w) end
		
		//if the icon is scrolled below the bottom of the list, then move the panel to the bottom of the browser
		if y > b_h then
			y = b_h-h
		//if the icon is scrolled above the top of the list, then move the panel to the top of the browser
		elseif y < 0 then
			y = 0
		//if the icon is visible, but the bottom of the panel goes beyond the bottom of the browser...
		elseif y+h > b_h then
			//...and it's too tall to fit above or below the icon, then center it the browser over the icon 
			//(edge case for clicking on icons in middle of the browser)
			if (y-self:GetTall()-h) < 0 then 
				y = (b_h/2)-(h/2)
			//...and it can fit above the icon, then reposition it above the icon
			else
				y = y-self:GetTall()-h
			end
		end

		pnl:SetPos(x, y)

	end

	function PANEL:CreateMouseOverPanel()

		if IsValid(TF2ItemBrowser.MouseOverPanel) then TF2ItemBrowser.MouseOverPanel:Remove() end

		local pnl = vgui.Create("DPanel", TF2ItemBrowser.Right)
		TF2ItemBrowser.MouseOverPanel = pnl
		pnl.Owner = self
		pnl:SetMouseInputEnabled(false)

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
		self.popup = pnl
		
		function pnl:Paint(w,h)
			self.Owner:PositionPopupPanel(self)
			LoadoutItemPopupBorder(0,0,w,h)
		end

	end

	function PANEL:CreateSpawnPanel()

		local i = TF2Items.items[self.data.id]
		local betweenitems = 8

		if IsValid(TF2ItemBrowser.SpawnPanel) then
			if TF2ItemBrowser.SpawnPanel.Owner == self then
				return
			else
				TF2ItemBrowser.SpawnPanel:Remove()
			end
		end

		local pnl = vgui.Create("DPanel", TF2ItemBrowser.Right)
		TF2ItemBrowser.SpawnPanel = pnl
		pnl.Owner = self

		pnl:DockPadding(popup_pad,popup_pad,popup_pad,popup_pad)
		local name_container = pnl:Add("DPanel")
		name_container:Dock(TOP)
		name_container.Paint = function() end
		//this will be populated in pnl.Refresh()
		
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
		mdl.models = {}
		function mdl:PostDrawModel(ent)
			//Render all additional models
			for k, v in ipairs (self.models) do
				if v != ent then
					v:DrawModel()
					v:FrameAdvance( --[[( RealTime() - self.LastPaint ) * self.m_fAnimSpeed]] )
				end
			end
		end

		function pnl.Refresh()
			name_container:Clear()
			self:AddItemText(name_container, self.itemname, "TF2ItemBrowser_ItemName", rarity_colors[self.rarity] or quality_colors[self.quality])
			name_container:InvalidateLayout(true)
			name_container:SizeToChildren(false, true)

			if !IsValid(ent) then self.data.team = TF2ItemBrowser.attopts.team:GetChecked() end //update this every time we open or refresh the panel, since it can change after the icon has been created
			local vis = GetItemModelVisuals(self.data)

			mdl.previous_models = {}
			for k, v in ipairs (mdl.models) do
				mdl.previous_models[k] = v:GetModel()
				v:Remove()
			end
			mdl.models = {}

			local submodels = {}
			if self.data.models.item then
				table.insert(submodels, {role = "item"})
				for k, v in ipairs (vis.models.attached or {}) do
					table.insert(submodels, {role = "attached", attach_num = k})
				end
				if self.data.models.attached_festive then
					for k, v in ipairs (vis.models.attached_festive) do
						table.insert(submodels, {role = "attached_festive", attach_num = k})
					end
				end
				if self.data.models.stat_clock then table.insert(submodels, {role = "stat_clock"}) end
			end
			if self.data.models.wearable then table.insert(submodels, {role = "wearable"}) end
			if self.data.models.wearable_2 then table.insert(submodels, {role = "wearable_2"}) end
			if self.data.models.taunt_prop then table.insert(submodels, {role = "taunt_prop"}) end
			if #submodels == 0 and table.Count(vis.models) == 0 then table.insert(submodels, {role = "no_model_fallback"}) end
			local offset_height_base, offset_height, docamera
			for k, v in ipairs (submodels) do
				local ent
				if v.role == "no_model_fallback" then
					//if this item has no model to show (it only changes bodygroups like gunslinger or service medal),
					//then instead show a preview of the playermodel with bodygroups changed.
					local model, skin = "", 0
					if IsValid(TF2ItemBrowser:GetEntity()) then
						model = TF2ItemBrowser:GetEntity():GetModel()
					else
						for k, v in ipairs (classes) do //convert long class name to short class name
							if self.data.class == v.longname then
								model = "models/player/" .. v.shortname .. ".mdl"
								break
							end
						end
					end
					if self.data.team then skin = 1 end
					ent = ClientsideModel(model, RENDERGROUP_OTHER)
					if !IsValid(ent) then return end

					ent:SetSkin(skin)
					for k, v in pairs (vis.ply_bg) do
						if isstring(k) then k = ent:FindBodygroupByName(k) end //on some items, k is a number already
						ent:SetBodygroup(k, v)
					end
				else
					local model = vis.models[v.role]
					if v.attach_num then
						model = model[v.attach_num]
					end
					ent = ClientsideModel(model, RENDERGROUP_OTHER)
					if !IsValid(ent) then return end

					ent:SetSkin(vis.skin)
					if v.role == "item" then
						for k, v in pairs (vis.item_bg) do
							ent:SetBodygroup(ent:FindBodygroupByName(k), v)
						end
						local mins, maxs = ent:GetRenderBounds()
						offset_height_base = maxs.z
					elseif v.attach_num then
						ent:SetParent(mdl.Entity)
						ent:AddEffects(EF_BONEMERGE)
					elseif v.role == "stat_clock" then
						ent:SetParent(mdl.Entity)
						ent:AddEffects(EF_BONEMERGE)
						local scl = vis.stat_clock_scale or 1
						ent:ManipulateBoneScale(ent:LookupBone("c_weapon_stattrack"), Vector(scl,scl,scl))
						//TODO: *maybe* let players set the number shown by the stat clock? this is a really tiny
						//detail, and it would need both its own gui and either a bunch of new materials or a whole 
						//custom matproxy, is this worth the trouble?
					else
						//If we're rendering both the base item and wearables, then reposition wearables above the item
						if offset_height_base then
							local mins, maxs = ent:GetRenderBounds()
							offset_height = offset_height_base - mins.z
						end
						if offset_height then
							ent:SetPos(Vector(0,0,offset_height))
						end
					end

					if i.visuals and i.visuals.styles and i.visuals.styles[self.data.style] then
						local anim = i.visuals.styles[self.data.style]._anim
						if anim and anim[v.role] then
							//we have to give the engine a nudge here to make it load the sequence info for the model, 
							//otherwise LookupSequence won't return anything useful until we spawn the model in the world
							ent:GetSequenceInfo(0)

							ent:ResetSequence(ent:LookupSequence(anim[v.role]))
							docamera = true
							local info = ent:GetSequenceInfo(ent:LookupSequence(anim[v.role]))
							ent:SetRenderBounds(info.bbmin, info.bbmax)
						end
					end
				end
				ent:SetNoDraw(true)
				ent:SetIK(false)
				if k == 1 then mdl.Entity = ent end
				table.insert(mdl.models, ent)
			end

			//don't recenter the camera if the models or animation didn't change
			if !docamera then docamera = #mdl.models != #mdl.previous_models end
			if !docamera then
				for k, v in ipairs (mdl.models) do
					if v:GetModel() != mdl.previous_models[k] then
						docamera = true
						break
					end
				end
			end
			if docamera then
				//copy of PositionSpawnIcon from lua\includes\util\client.lua, except we get the combined bounds of all models
				local mn, mx
				for k, v in ipairs (mdl.models) do
					local mn2, mx2 = v:GetRenderBounds()
					mn2 = mn2 + v:GetPos()
					mx2 = mx2 + v:GetPos()
					if !mn then
						mn, mx = mn2, mx2
					else
						mn.x = math.min(mn.x,mn2.x)
						mn.y = math.min(mn.y,mn2.y)
						mn.z = math.min(mn.z,mn2.z)
						mx.x = math.max(mx.x,mx2.x)
						mx.y = math.max(mx.y,mx2.y)
						mx.z = math.max(mx.z,mx2.z)
					end
				end
				if mn then
					local middle = ( mn + mx ) * 0.5
					local size = math.max( 0, mx.x - mn.x, mx.y - mn.y, mx.z - mn.z )

					//copy of local function RenderSpawnIcon_Prop from lua\includes\util\client.lua, only slightly adapted
						
					if ( size < 900 ) then
						size = size * ( 1 - ( size / 900 ) )
					else
						size = size * ( 1 - ( size / 4096 ) )
					end

					size = math.Clamp( size, 5, 1000 )

					local ViewAngle = Angle( 25, 220, 0 )
					local ViewPos = --[[pos +]] ViewAngle:Forward() * size * -15
					local view = {}

					view.fov		= 4 + size * 0.04
					view.origin		= ViewPos + middle
					//view.znear		= 1
					//view.zfar		= ViewPos:Distance( pos ) + size * 2
					view.angles		= ViewAngle

					//Apply the changes to the camera
					mdl:SetCamPos(view.origin)
					mdl:SetFOV(view.fov)
					mdl:SetLookAng(view.angles)
				end
			end

			//Hide the class selector if all classes use the same model (i.e. medals)
			//Also compare the bodygroups because of use_per_class_bodygroups.
			local should_show_class = false
			for k, v in pairs (i.used_by_classes) do
				if k != self.data.class then
					local vis2 = GetItemModelVisuals({id = self.data.id, class = k, team = self.data.team, style = self.data.style})
					if IsValid(mdl.models[1]) then //this will be checking the wrong model if there's no base item, but whatever, no items with bodygroup changes have wearables currently
						for k, v in pairs (vis2.item_bg) do
							//make sure this is changing a bodygroup that actually exists; a whole bunch of 
							//badges like the dueling badges have useless bodygroup setters for some reason
							if mdl.models[1]:FindBodygroupByName(k) != -1 and vis.item_bg[k] != vis2.item_bg[k] then
								should_show_class = true
								break
							end
						end
						if should_show_class then break end
					end
					for k, v in pairs (vis2.models) do
						if vis.models[k] != v then
							should_show_class = true
							break
						end
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
					pnl.class:SetText(string.NiceName(self.data.class))
				end
			end
			pnl.class:SetEnabled(should_show_class)
			pnl.class:GetParent().Label:SetEnabled(should_show_class)

			pnl:InvalidateLayout(true)
			pnl:SizeToChildren(false,true)
			self:PositionPopupPanel(pnl)
		end
		
		function pnl.OnSettingChanged()
			self:SetData()
			pnl.Refresh()
			if IsValid(self.entity) then TF2ItemBrowser:DoInput("attach_item_modify", self.entity, self.data) end
		end	

		local checks = vgui.Create("Panel", pnl) //container for submodel controls
		checks:SetHeight(15)
		checks:Dock(TOP)
		checks.checks = {}
		for k, v in SortedPairs (self.data.models) do
			local check = vgui.Create("DCheckBoxLabel", checks)
			check.model = k
			local text = string.NiceName(k)
			if k == "attached_festive" then text = "Festivizer" end
			check:SetText(text)
			check:SetHeight(15)
			check:Dock(LEFT)
			check:SetChecked(v)
			check.OnChange = function(_, val)
				self.data.models[k] = val
				pnl.OnSettingChanged()
			end
			table.insert(checks.checks, check)
		end
		checks:DockMargin(side_margins,0,side_margins,betweencategories)
		function checks:PerformLayout(w, h)
			for _, v in ipairs (checks.checks) do
				v:SetWide(w / #checks.checks) //draw these side-by-side so as to not take up too much space
			end
		end
		checks:InvalidateLayout()
		if #checks.checks < 2 then
			//if there's only one submodel then we don't need these
			checks:Remove()
		elseif self.data.models.wearable == nil and self.data.models.wearable_2 == nil and self.data.models.taunt_prop == nil then
			//if we only have the base item and optional attachments, then we don't need the option for the base item
			for k, v in ipairs (checks.checks) do
				if v.model == "item" then
					table.remove(checks.checks, k)
					v:Remove()
					break
				end
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
				if select_extras then select_extras(data) end
				drop.Combo.value = data
				pnl.OnSettingChanged()
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
			for k, v in ipairs (classes) do //add class options in class order
				if i.used_by_classes[v.longname] then
					drop:AddChoice(string.NiceName(v.longname), v.longname, self.data.class == v.longname)
				end
			end
		end, function(data)
			self.data.class = data
		end)

		if i.visuals and i.visuals.styles and table.Count(i.visuals.styles) > 1 then
			AddDropdown("Style", function(drop)
				for k, v in SortedPairs (i.visuals.styles) do //this starts from 0 so we can't do ipairs
					local name = GetTFLanguageString(v.name, true)
					if !name and k == 0 then name = GetTFLanguageString("#Normal") end //assume this is the non-australium style for weapons with australium
					drop:AddChoice(name or "BAD UNHANDLED STYLE " .. k, k, self.data.style == k)
				end
			end, function(data)
				self.data.style = data
			end)
		end

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
				TF2ItemBrowser:DoInput("attach_item_spawn", self.data)
			else
				TF2ItemBrowser:DoInput("item_spawn", self.data)
			end
			surface.PlaySound(self.sound_drop)
		end
		
		pnl:SetWide(popup_w)
		pnl.Refresh()
		self.popup = pnl
		function pnl:Paint(w,h)
			self.Owner:PositionPopupPanel(self)
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

		//If this itemicon doesn't correspond to an entity, then revert any changes when we close the spawn panel
		function pnl.OnRemove()
			if !IsValid(self.entity) and IsValid(self) then self:SetDefaultData() end //don't run this when the itemicon is being deleted
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

		//This is a newly created icon being drawn for the first time, populate its data table
		if isnumber(self.data) then self:SetDefaultData() end

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
			MsgN(self.data.id, " ", TF2Items.items[self.data.id].name)
			PrintTable(TF2Items.items[self.data.id])
			MsgN("")
		end)
		opt:SetIcon("icon16/page_copy.png")

		self.menu = menu
		menu:Open()

	end

	AddTFButtonSounds(PANEL)

	function PANEL:OnRemove()

		if IsValid(self.popup) then self.popup:Remove() end

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
	net.WriteUInt(data.id, 15)
	//translate class name back to id number
	for k, class in ipairs (classes) do
		if class.longname == data.class then
			net.WriteUInt(k, 4)
			break
		end
	end
	net.WriteBool(data.team)
	net.WriteUInt(data.style, 4)

	net.WriteBool(data.models.item)
	net.WriteBool(data.models.wearable)
	net.WriteBool(data.models.wearable_2)
	net.WriteBool(data.models.taunt_prop)
	net.WriteBool(data.models.attached_festive)
	net.WriteBool(data.models.stat_clock)
end

ReadItemDataTable = function()
	return {
		id = net.ReadUInt(15),
		class = classes[net.ReadUInt(4)].longname,
		team = net.ReadBool(),
		style = net.ReadUInt(4),

		models = {
			item = net.ReadBool(),
			wearable = net.ReadBool(),
			wearable_2 = net.ReadBool(),
			taunt_prop = net.ReadBool(),
			attached_festive = net.ReadBool(),
			stat_clock = net.ReadBool(),
		},
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

		local ent, data, vis, merge_type, submodels
		if string.StartsWith(input, "attach_") then
			ent = net.ReadEntity()
		end

		if input == "item_spawn" or input == "attach_item_spawn" or input == "attach_item_modify" then
			data = ReadItemDataTable()
			vis = GetItemModelVisuals(data)
			merge_type = net.ReadBool()

			submodels = {}
			if data.models.item then
				table.insert(submodels, {role = "item"})
				for k, v in ipairs (vis.models.attached or {}) do
					table.insert(submodels, {role = "attached", attach_num = k})
				end
				if data.models.attached_festive then
					for k, v in ipairs (vis.models.attached_festive) do
						table.insert(submodels, {role = "attached_festive", attach_num = k})
					end
				end
				if data.models.stat_clock then table.insert(submodels, {role = "stat_clock"}) end
			end
			if data.models.wearable then table.insert(submodels, {role = "wearable"}) end
			if data.models.wearable_2 then table.insert(submodels, {role = "wearable_2"}) end
			if data.models.taunt_prop then table.insert(submodels, {role = "taunt_prop"}) end
			if #submodels == 0 then table.insert(submodels, {role = "no_model_fallback"}) end
		end

		//Spawn the item using the retrieved model, skin and bodygroups. To do this, we mostly just emulate sandbox's CCSpawn function
		//and the various functions it calls (gamemodes/sandbox/gamemode/commands.lua) This is worth doing because it makes sure we run
		//all of the relevant hooks that might want to catch us spawning the prop, and also lets us reuse all of DoPlayerEntitySpawn's 
		//"spawn the prop where the player is looking, and make sure it isn't stuck" code.
		local function CreateItemEntity(model, skin, item_bg, parent)

			if !gamemode.Call("PlayerSpawnObject", ply, model, skin) or !util.IsValidModel(model) 
			or (parent != nil and !IsValid(parent)) then return end
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
				//DoPropSpawnedEffect(e)

				undo.Create("prop_physics")
					undo.SetPlayer(ply)
					undo.AddEntity(e)
				undo.Finish("#prop_physics (" .. tostring(model) .. ")")
				ply:AddCleanup("props", e)
			else
				gamemode.Call("PlayerSpawnedEffect", ply, model, e)
				//if IsValid(e.AttachedEntity) then DoPropSpawnedEffect(e.AttachedEntity) end

				undo.Create("prop_effect")
					undo.SetPlayer(ply)
					undo.AddEntity(e)
				undo.Finish("#prop_effect (" .. tostring(model) .. ")")
				ply:AddCleanup("effects", e)
			end

			local e2 = e
			if IsValid(e.AttachedEntity) then e2 = e.AttachedEntity end
			if item_bg then
				for k, v in pairs (item_bg) do
					e2:SetBodygroup(e2:FindBodygroupByName(k), v)
				end
			end

			duplicator.StoreEntityModifier(e2, "TF2ItemBrowser_Item", data)

			//test to make sure undo/entitymod stuff works properly with animprops; 
			//TODO: reuse this when we implement features we actually need animprops for
			--[[DisablePropCreateEffect = true
			e = ConvertEntityToAnimprop(e, ply, true, false, false)
			DisablePropCreateEffect = nil]]
			
			if IsValid(parent) then
				if merge_type then
					local old_e = e
					e = CreateAdvBonemergeEntity(e, parent, ply, false, false, true)
					if !IsValid(e) then return end
					local const = constraint.AdvBoneMerge(parent, e, ply)
					if e != old_e then old_e:Remove() end
				else
					e = rb655_ApplyBonemerge(e2, parent) //unlike advbone, this one expects AttachedEntity for prop_effects
				end
			end

			return e

		end

		if input == "item_spawn" or input == "attach_item_spawn" then

			if !IsValid(ply) or (!ply:Alive() and !ply:IsAdmin()) then return end

			local spawned_models = {}
			for k, v in ipairs (submodels) do
				local parent = ent
				local model = vis.models[v.role]
				local item_bg
				if v.attach_num then
					model = model[v.attach_num]
					if IsValid(spawned_models[1]) then parent = spawned_models[1] end
				elseif v.role == "item" then
					item_bg = vis.item_bg
				elseif v.role == "stat_clock" then
					if IsValid(spawned_models[1]) then parent = spawned_models[1] end
				elseif v.role == "no_model_fallback" then
					//if this item has no model to show (it only changes bodygroups like gunslinger or service medal, or it has
					//multiple submodels like banners but they're all disabled), then instead spawn an invisible model so that
					//we still have an entity to associate the item with.
					model = "models/empty.mdl" //this comes with tf2, it's actually the dragon's fury projectile, but include a copy with this addon just in case this ceases to exist someday (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/tf/tf_projectile_dragons_fury.cpp#L167)
				end

				local e = CreateItemEntity(model, vis.skin, item_bg, parent)
				if !IsValid(e) then continue end

				table.insert(spawned_models, e)

				if v.role == "stat_clock" then
					local scl = vis.stat_clock_scale or 1
					e:ManipulateBoneScale(e:LookupBone("c_weapon_stattrack"), Vector(scl,scl,scl))
				end

				if e != spawned_models[1] then
					constraint.TF2ItemBrowser_Item_SubModel(spawned_models[1], e, v.role, v.attach_num, ply)
				end
			end
			if !IsValid(spawned_models[1]) then return end

			if IsValid(ent) then
				//Use a one-size-fits-all undo instead of addon-specific undos;
				//for advbone in particular, we want to remove the entity instead of unmerging it
				undo.Create("TF2ItemBrowser_Item")
					for _, e in ipairs (spawned_models) do
						undo.AddEntity(e)
						if e:GetClass() == "prop_physics" then
							ply:AddCleanup("props", e)
						elseif e:GetClass() == "prop_effect" then
							ply:AddCleanup("effects", e)
						end
					end
					undo.SetPlayer(ply)
				undo.Finish("Attached Item (" .. TF2Items.items[data.id].name .. ")") //item name instead of model name because this can change

				for k, v in pairs (vis.ply_bg) do
					//when attaching a new item, we can keep this simple, and just change the ply_bg's the item has listed
					if isstring(k) then k = ent:FindBodygroupByName(k) end //on some items, k is a number already
					ent:SetBodygroup(k, v)
				end

				//timer.Simple(0.1, function() //do this on a timer so the entity isn't still null on the client's end
				//	if !IsValid(e) then return end
					net.Start("TF2ItemBrowser_AttachedItem_SendToCl")
						net.WriteEntity(spawned_models[1])
						net.WriteBool(true) //open upon received
						WriteItemDataTable(data)
					net.Send(ply)
				//end
			end

		elseif input == "attach_item_modify" then

			local e = net.ReadEntity()

			if !IsValid(e) or e:GetParent() != ent or e.TF2ItemBrowser_Item_IsSubModelOf then return end
			
			local submodels_to_remove = table.Copy(e.TF2ItemBrowser_Item_SubModels) or {}
			for k, v in ipairs (submodels) do
				local model = vis.models[v.role]
				local parent = ent
				if v.attach_num then
					model = model[v.attach_num]
					parent = e
				elseif v.role == "stat_clock" then
					parent = e
				elseif v.role == "no_model_fallback" then
					//if this item has no model to show (it only changes bodygroups like gunslinger or service medal, or it has
					//multiple submodels like banner but they're all disabled), then instead spawn an invisible model so that
					//we still have an entity to associate the item with.
					model = "models/empty.mdl" //this comes with tf2, it's actually the dragon's fury projectile, but include a copy with this addon just in case this ceases to exist someday (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/tf/tf_projectile_dragons_fury.cpp#L167)
				end

				local e2
				if k == 1 then
					e2 = e

					//Update bodygroups on base item model
					for k, v in pairs (vis.item_bg) do
						e:SetBodygroup(e:FindBodygroupByName(k), v)
						//don't worry about reverting unlisted item_bg's back to 0, no existing items that use this feature require us to check for these
					end
				else
					if v.role == "item" then MsgN("ERROR: TF2ItemBrowser_Input_SendToSv attach_item_modify tried to add 'item' as submodel, this shouldn't happen!") continue end

					e.TF2ItemBrowser_Item_SubModels = e.TF2ItemBrowser_Item_SubModels or {}
					if v.attach_num then
						e.TF2ItemBrowser_Item_SubModels[v.role] = e.TF2ItemBrowser_Item_SubModels[v.role] or {}
						e2 = e.TF2ItemBrowser_Item_SubModels[v.role][v.attach_num]
					else
						e2 = e.TF2ItemBrowser_Item_SubModels[v.role]
					end

					//If the input enabled a submodel, then create a new entity to use for it
					if !IsValid(e2) then
						e2 = CreateItemEntity(model, vis.skin, nil, parent)
						if !IsValid(e2) then continue end
						if v.role == "stat_clock" then
							local scl = vis.stat_clock_scale or 1
							e2:ManipulateBoneScale(e2:LookupBone("c_weapon_stattrack"), Vector(scl,scl,scl))
						end

						constraint.TF2ItemBrowser_Item_SubModel(e, e2, v.role, v.attach_num, ply)
					end
					submodels_to_remove[v.role] = nil
				end

				//Update the model and skin of each submodel
				if model != e2:GetModel() then
					e2:SetModel(model)
					//For advbonemerge ents, replace the boneinfo table with a new one, because the new model's bones might not match
					if e2.AdvBone_BoneInfo then
						e2.AdvBone_BoneInfo = nil
						e2.AdvBone_BoneInfo = CreateAdvBoneInfoTable(e2, e2:GetParent(), false, true)
						//Make sure the clients get the new boneinfo table
						net.Start("AdvBone_EntBoneInfoTableUpdate_SendToCl")
							net.WriteEntity(e2)
						net.Broadcast()
					end
				end
				e2:SetSkin(vis.skin)
			end
			//If the input disabled a submodel, then get rid of the ent(s) we were using for it
			for role, v in pairs (submodels_to_remove) do
				if istable(v) then
					for k2, v2 in pairs (v) do
						v2:Remove()
					end
				else
					v:Remove()
				end
				e.TF2ItemBrowser_Item_SubModels[role] = nil
			end

			//Check if the bodygroup changes this item applies to the parent ent were modified
			if e.EntityMods and e.EntityMods.TF2ItemBrowser_Item then
				local old_ply_bg = GetItemModelVisuals(e.EntityMods.TF2ItemBrowser_Item).ply_bg
				local all_keys = {}
				table.Merge(all_keys, vis.ply_bg)
				table.Merge(all_keys, old_ply_bg)
				for k, _ in pairs (all_keys) do
					if ent:FindBodygroupByName(k) != -1 and vis.ply_bg[k] != old_ply_bg[k] then
						//If this item's ply_bg's have changed, then we need to reset the parent ent's bodygroups from scratch. 
						//For example, even if this item no longer disables one bodygroup, some other attached item may still 
						//be disabling it. Instead, we have to go through every attached item, and apply their ply_bg's again 
						//to a blank slate parent ent.
						for i = 0, ent:GetNumBodyGroups() do
							ent:SetBodygroup(i, 0)
						end
						for k, child in ipairs (ent:GetChildren()) do
							if child.EntityMods and child.EntityMods.TF2ItemBrowser_Item and !child.TF2ItemBrowser_Item_IsSubModelOf then
								local child_ply_bg
								if child == e then
									child_ply_bg = vis.ply_bg 
								else 
									child_ply_bg = GetItemModelVisuals(child.EntityMods.TF2ItemBrowser_Item).ply_bg
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

			//Reverting bodygroup changes on the parent entity is handled by the entitymod function

			e:Remove()

		elseif input ==  "attach_skin" then

			ent:SetSkin(net.ReadUInt(8))

		end

	end)

	//Constraint used to keep submodels associated with the main item entity between dupes/saves
	function constraint.TF2ItemBrowser_Item_SubModel(Ent1, Ent2, Role, Attach_Num, ply)

		timer.Simple(0, function() //wait a frame, because otherwise easy bonemerge can break this constraint when loaded from a dupe/save
			if !Ent1 or !Ent2 then return end

			Ent1.TF2ItemBrowser_Item_SubModels = Ent1.TF2ItemBrowser_Item_SubModels or {}
			if Attach_Num != nil then
				Ent1.TF2ItemBrowser_Item_SubModels[Role] = Ent1.TF2ItemBrowser_Item_SubModels[Role] or {}
				Ent1.TF2ItemBrowser_Item_SubModels[Role][Attach_Num] = Ent2
			else
				Ent1.TF2ItemBrowser_Item_SubModels[Role] = Ent2
			end
			Ent2.TF2ItemBrowser_Item_IsSubModelOf = Ent1
			Ent1:DeleteOnRemove(Ent2)
			
			//create a dummy ent for the constraint functions to use
			local const = ents.Create("info_target")
			const:Spawn()
			const:Activate()

			constraint.AddConstraintTable(Ent1, const, Ent2)
			
			local ctable = {
				Type = "TF2ItemBrowser_Item_SubModel",
				Ent1 = Ent1,
				Ent2 = Ent2,
				Role = Role,
				Attach_Num = Attach_Num,
				ply = ply,
			}
		
			const:SetTable(ctable)
		
			return const
		end)

	end
	duplicator.RegisterConstraint("TF2ItemBrowser_Item_SubModel", constraint.TF2ItemBrowser_Item_SubModel, "Ent1", "Ent2", "Role", "Attach_Num", "ply")

	duplicator.RegisterEntityModifier("TF2ItemBrowser_Item", function(ply, e, data)

		duplicator.StoreEntityModifier(e, "TF2ItemBrowser_Item", data)

		//When removed, check if this item was applying any bodygroup changes to the parent ent that we want to revert.
		//This is handled here and not in the input receive func, so that we can also run it when removing the item with undo.
		e:CallOnRemove("TF2ItemBrowser_AttachedItem_OnRemove", function(e)
			local ent = e:GetParent()
			if !IsValid(ent) then return end
			if e.EntityMods and e.EntityMods.TF2ItemBrowser_Item and !e.TF2ItemBrowser_Item_IsSubModelOf then
				for k, _ in pairs (GetItemModelVisuals(e.EntityMods.TF2ItemBrowser_Item).ply_bg) do
					//If any ply_bg's were changed, then do the same routine as attach_item_modify above; get every attached 
					//item other than the one we're removing, and apply their ply_bg's again to a blank slate parent ent.
					for i = 0, ent:GetNumBodyGroups() do
						ent:SetBodygroup(i, 0)
					end
					for k, child in ipairs (ent:GetChildren()) do
						if child != e and child.EntityMods and child.EntityMods.TF2ItemBrowser_Item and !child.TF2ItemBrowser_Item_IsSubModelOf then
							for k, v in pairs (GetItemModelVisuals(child.EntityMods.TF2ItemBrowser_Item).ply_bg) do
								if isstring(k) then k = ent:FindBodygroupByName(k) end //on some items, k is a number already
								ent:SetBodygroup(k, v)
							end
						end
					end
					break
				end
			end
		end)

	end)

	net.Receive("TF2ItemBrowser_AttachedItems_GetFromSv", function(_, ply)
		local ent = net.ReadEntity()
		if !IsValid(ent) then return end
		for _, ent2 in ipairs (ent:GetChildren()) do
			if ent2.EntityMods and ent2.EntityMods.TF2ItemBrowser_Item and !ent2.TF2ItemBrowser_Item_IsSubModelOf then
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

	language.Add("undone_TF2ItemBrowser_Item", "Undone Attached Item")
	
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