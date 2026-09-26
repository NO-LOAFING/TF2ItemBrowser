local tf_lang, UpdateTFLanguageStrings, GetTFLanguageString, str_any, str_none, str_custom, classes
if CLIENT then
	GetTFLanguageString = function(str)
		local result
		if !isstring(str) then return end
		//if str doesn't start with a #, then it might not be a localized string, and in those cases 
		//we should just return the string we were given if we can't find one to localize it to
		if !string.StartsWith(str, "#") then result = str end

		result = tf_lang[string.TrimLeft(string.lower(str), "#")] or result
		return result
	end

	UpdateTFLanguageStrings = function(lang)
		local tab = file.Read("resource/chat_english.txt", "GAME") //also get chat_english for the "#chat_filterbutton" ("Filters") string we need
		if tab then
			tab = util.KeyValuesToTable(tab, true, false)
			tab = tab.tokens
		end
		tf_lang = tab or {}
		local tab = file.Read("resource/tf_english.txt", "tf")
		if tab then
			tab = util.KeyValuesToTable(tab, true, false).tokens
			if tab then
				table.Merge(tf_lang, tab)
			end
		end
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
			local tab = file.Read("resource/chat_" .. langs[lang] .. ".txt", "GAME")
			if tab then
				tab = util.KeyValuesToTable(tab, true, false).tokens
				if tab then
					table.Merge(tf_lang, tab)
				end
			end
			local tab = file.Read("resource/tf_" .. langs[lang] .. ".txt", "tf")
			if tab then
				tab = util.KeyValuesToTable(tab, true, false).tokens
				if tab then
					table.Merge(tf_lang, tab)
				end
			end
		end
		//Fix KeyValuesToTable returning some strings as numbers if the text contained numbers only (i.e. #TF_TournamentMedal_2014)
		for k, v in pairs (tf_lang) do
			if !isstring(v) then tf_lang[k] = tostring(v) end
		end
		//MsgN("language is now ", lang)
		//note: conveniently, the context menu and all of its contents are reset upon changing languages, so we don't have to worry 
		//about resetting the browser to prevent odd behavior caused by controls still using values from the previous language
		str_any = "(" .. string.lower(GetTFLanguageString("#TF_Any") or "Any") .. ")"
		str_none = "(" .. string.lower(GetTFLanguageString("#TF_ImportPreview_Effect0") or "None") .. ")"
		str_custom = "(" .. string.lower(GetTFLanguageString("#TF_ImportFile_CustomSkin") or "Custom") .. ")"
		if classes then classes[1].langstr = str_any end
	end
	cvars.AddChangeCallback("gmod_language", function(_,_,new) UpdateTFLanguageStrings(new) end, "TF2ItemBrowser")
	UpdateTFLanguageStrings(GetConVar("gmod_language"):GetString())
end










classes = {
	{longname = "(any)",	shortname = "(any)",	langstr = str_any},
	{longname = "scout",	shortname = "scout",	langstr = "#TF_Class_Name_Scout"},
	{longname = "soldier",	shortname = "soldier",	langstr = "#TF_Class_Name_Soldier"},
	{longname = "pyro",	shortname = "pyro",	langstr = "#TF_Class_Name_Pyro"},
	{longname = "demoman",	shortname = "demo",	langstr = "#TF_Class_Name_Demoman"}, //called "demoman" in all item definition keys (used_by_classes, model_player_per_class, etc.), "demo" in all model paths, and either one interchangably in equip region names. dumb!!!
	{longname = "heavy",	shortname = "heavy",	langstr = "#TF_Class_Name_HWGuy"},
	{longname = "engineer",	shortname = "engineer",	langstr = "#TF_Class_Name_Engineer"},
	{longname = "medic",	shortname = "medic",	langstr = "#TF_Class_Name_Medic", extra_equip_region_prefix = "medigun"},
	{longname = "sniper",	shortname = "sniper",	langstr = "#TF_Class_Name_Sniper"},
	{longname = "spy",	shortname = "spy",	langstr = "#TF_Class_Name_Spy"},
	{longname = "none",	shortname = "none",	langstr = "#TF_SelectPlayer_DuelClass_None"},
}
local class_longname_to_id = {}
for k, v in ipairs (classes) do
	class_longname_to_id[v.longname] = k
end

//globals for these too
local EFFECT_NONE = 0
local EFFECT_UBER = 1
local EFFECT_JARATE = 2
local EFFECT_GOLD = 3
local EFFECT_ICE = 4
local jarate = {
	[false] = Vector(6, 9, 2),
	[true] = Vector(7, 5, 1),
}


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
	i.item_name = "Toolbox" //not localized, bad!! how does the word "toolbox" not appear *once* in tf_english??
	i.item_type_name = "Toolbox" //^
	i.image_inventory = "backpack/weapons/w_models/w_toolbox"
end)

//remove redundant copies of items
for _, tab in ipairs ({
	{10, "TF_WEAPON_SHOTGUN_SOLDIER"},
	{11, "TF_WEAPON_SHOTGUN_HWG"},
	{12, "TF_WEAPON_SHOTGUN_PYRO"},
	{23, "TF_WEAPON_PISTOL_SCOUT"},
	{743, "Autogrant Pyrovision Goggles"}, //copy of 744 "Pyrovision Goggles"
	{831, "Promo Red-Tape Recorder"}, //copies of 810-817 (non-promo versions of the same items)
	{832, "Promo Huo Long Heatmaker"},
	{833, "Promo Flying Guillotine"},
	{834, "Promo Neon Annihilator"},
	{835, "Promo Triad Trinket"},
	{836, "Promo Champ Stamp"},
	{837, "Promo Marxman"},
	{838, "Promo Human Cannonball"},
	{1184, "Gloves of Running Urgently MvM"}, //copy of 239 "Gloves of Running Urgently" but has different attributes
	{850, "Deflector"}, //visually the same as minigun, exists as a contrivance for mvm because tracer fx can only be defined in an itemdef
	{30739, "Promo Fear Monger"}, //copy of 30724 "Fear Monger"
	{30740, "Promo Arkham Cowl"}, //copy of 30720 "Arkham Cowl"
	{30741, "Promo The Firefly"}, //copy of 30721 "The Firefly"
	{8936, "Halloween Spellbook Page (Achievement)"}, //copy of 8935 "Halloween Spellbook Page" except it applies different spellbook page in TF2
	{1201, "Poker Visor 2026"}, //copies of 292, 294-298 (original poker night items) but with different names prepended with "Reissued"
	{1202, "TTG Max Pistol - Poker Night 2026"},
	{1203, "TTG Glasses 2026"},
	{1204, "TTG Badge 2026"},
	{1205, "TTG Watch 2026"},
	{1206, "Iron Curtain 2026"},
	{294, "TTG Max Pistol - Poker Night"}, //functionally a copy of 160 TTG Max Pistol, only differences are armory/store stuff
}) do
	SafeAmendItem(tab[1], tab[2], function(i) return "remove" end)
end
s.prefabs.base_paintkit_keylesscase.model_player = nil //these cases all use the same model as the paintkit internally, which is wrong and doesn't match their icon (and isn't even visible anywhere in-game), get rid of them

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

//these specific item models have icon_camera attachments in nonsense positions, don't use them
//SafeAmendItem(527, "The Widowmaker", function(i) i._disable_icon_camera = true end) //this one's borderline but at least the item's visible; also even valve have succumbed to this bad camera placement https://steamcommunity.com/market/listings/440/Festivized%20Professional%20Killstreak%20Widowmaker
SafeAmendItem(528, "The Short Circuit", function(i) i._disable_icon_camera = true end)
SafeAmendItem(588, "The Pomson 6000", function(i) i._disable_icon_camera = true end)
SafeAmendItem(1179, "The Thermal Thruster", function(i) i._disable_icon_camera = true end)

//TODO: better backpack icons (and names?) for:
//1155 TF_WEAPON_PASSTIME GUN - this is the pass time jack, currently uses wrench icon and no name
//1057 MvM GateBotLight Scout (and the others) - missing textures and all use the same name
//30143 tw_demobot_armor (and the others) - placeholder white circle


//Make items inherit values from prefabs, which themselves inherit values from other prefabs, and so on
local tab = {}
local function InheritPrefabValues(k, v, ptab, ptabname)
	//Go through prefabs of prefabs recursively
	if ptab.prefab then
		//Note: Prefabs are read in reverse order (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_schema.cpp#L2940-L2968);
		//see the many, many hats with prefab "no_craft hat", which override hat's craft_class "hat" with no_craft's craft_class ""
		for k2, v2 in ipairs (table.Reverse(string.Explode(" ", ptab.prefab))) do
			if !s.prefabs[v2] then MsgN("TF2ItemSchema: ", k, " ", v.name, " ", ptabname, " tried to get invalid prefab \"", v2, "\"") continue end
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
end
for k, v in pairs (s.items) do
	tab[k] = {}
	InheritPrefabValues(k, v, v, "")
end
s.items = tab


//these have to be done after InheritPrefabValues because some (not all) of these bad values come from prefabs

//these weapon reskins unintentionally inherit australium styles that don't work from their base weapons, get rid of them
SafeAmendItem(266, "The Horseless Headless Horseman's Headtaker", function(i) i.visuals.styles = nil end)
SafeAmendItem(482, "Nessie's Nine Iron", function(i) i.visuals.styles = nil end)
SafeAmendItem(1082, "Festive Eyelander", function(i) i.visuals.styles = nil end)
SafeAmendItem(1085, "Festive Black Box", function(i) i.visuals.styles = nil end)
SafeAmendItem(1149, "Festive SMG 2014", function(i) i.visuals.styles = nil end)

//these weapons (mostly but not entirely reskins) have particle_suffix values even though they lack the attachments for unusual fx
SafeAmendItem(160, "TTG Max Pistol", function(i) i.particle_suffix = nil end)
SafeAmendItem(161, "TTG Sam Revolver", function(i) i.particle_suffix = nil end)
SafeAmendItem(298, "Iron Curtain", function(i) i.particle_suffix = nil end)
SafeAmendItem(638, "The Sharp Dresser", function(i) i.particle_suffix = nil end)
SafeAmendItem(727, "The Black Rose", function(i) i.particle_suffix = nil end)
SafeAmendItem(741, "The Rainblower", function(i) i.particle_suffix = nil end)
SafeAmendItem(772, "Baby Face's Blaster", function(i) i.particle_suffix = nil end)
SafeAmendItem(851, "The AWPer Hand", function(i) i.particle_suffix = nil end)
SafeAmendItem(1007, "Festive Grenade Launcher", function(i) i.particle_suffix = nil end)
SafeAmendItem(1085, "Festive Black Box", function(i) i.particle_suffix = nil end)
SafeAmendItem(1103, "The Back Scatter", function(i) i.particle_suffix = nil end)
SafeAmendItem(30474, "The Nostromo Napalmer", function(i) i.particle_suffix = nil end)
SafeAmendItem(30666, "The C.A.P.P.E.R", function(i) i.particle_suffix = nil end)


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
local paintkit_items_to_ids = {}
local paintkit_rarities = {}
local paintkit_ids_to_collections = {}

for k, v in pairs (s.items) do
	//clear any non-number keys - currently there's only one of these and it's a useless "default" item that gets cleared out anyway, but
	//since we use string keys to tell custom items apart from normal ones, we want to be *absolutely* sure here to avoid things breaking.
	if !isnumber(k) then s.items[k] = nil continue end

	//clear useless contracts
	if v.equip_type == "account" then s.items[k] = nil continue end

	//war paint items are useless as well, but we still need to make a list of them in order to retrieve war paint rarities later
	if v.static_attrs and v.static_attrs.paintkit_proto_def_index then
		paintkit_items_to_ids[v.name] = v.static_attrs.paintkit_proto_def_index
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
			if CLIENT then tab.name = (GetTFLanguageString("#TF_ScoreBoard_KillsLabel") or "Kills:") .. " " .. i end
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
	//Add submodel and selectable inactive/active animations for 1101 The B.A.S.E. Jumper.
	//We hijack the style system to use it for selectable animations, because it already has the model-swap functionality that the parachute needs,
	//and so we don't have to network a whole extra value for like 4 items, but rename the selector to "animation" so that players don't mistake
	//the more obscure anims like the hat ones for actual styles.
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
		v._call_styles_animations = true
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
				name = "#TF_style0_normal"
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
	//Add selectable inactive/active animations for 1179 The Thermal Thruster
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
		v._call_styles_animations = true
	//Add selectable styles for canteens; the default canteen has separate models for each powerup type, while reskins use skin 0 for empty and skin 1 for any powerup.
	elseif v.item_class == "tf_powerup_bottle" then
		if v.attributes["lunchbox adds minicrits"] then //set_weapon_mode
			v.visuals = v.visuals or {}
			v.visuals.styles = {
				[0] = {
					name = "#TF_Quest_Status_Inactive", //Inactive
				},
				[1] = {
					name = "#Attrib_CritBoost_shortdesc",
					model_player = "models/player/items/mvm_loot/all_class/mvm_flask_krit.mdl",
					image_inventory = "backpack/player/items/mvm_loot/all_class/mvm_flask_krit"
				},
				[2] = {
					name = "#Attrib_Ubercharge_shortdesc",
					model_player = "models/player/items/mvm_loot/all_class/mvm_flask_uber.mdl",
					image_inventory = "backpack/player/items/mvm_loot/all_class/mvm_flask_uber"
				},
				[3] = {
					name = "Attrib_RefillAmmo_shortdesc",
					model_player = "models/player/items/mvm_loot/all_class/mvm_flask_ammo.mdl",
					image_inventory = "backpack/player/items/mvm_loot/all_class/mvm_flask_ammo"
				},
				[4] = {
					name = "Attrib_Recall_shortdesc",
					model_player = "models/player/items/mvm_loot/all_class/mvm_flask_tele.mdl",
					image_inventory = "backpack/player/items/mvm_loot/all_class/mvm_flask_tele"
				},
				[5] = {
					name = "Attrib_BuildingInstaUpgrade_shortdesc",
					model_player = "models/player/items/mvm_loot/all_class/mvm_flask_build.mdl",
					image_inventory = "backpack/player/items/mvm_loot/all_class/mvm_flask_build"
				}
			}
		else
			v.visuals = v.visuals or {}
			v.visuals.styles = {
				[0] = {
					name = "#TF_Quest_Status_Inactive", //Inactive
					skin = 0
				},
				[1] = {
					name = "#QuestLog_Active", //"Active"
					skin = 1
				}
			}
		end
	//Add selectable intact/broken styles for demo bottles, caber, neon
	elseif v.item_class == "tf_weapon_bottle" or v.item_class == "tf_weapon_stickbomb" or v.item_class == "tf_weapon_breakable_sign" then
		v.visuals = v.visuals or {}
		v.visuals.styles = {
			[0] = {
				name = "#TF_style0_normal",
				bodygroup = {
					name = "broken",
					submodel_index = 0
				}
			},
			[1] = {
				name = "#TF_Plutonidome_Style1", //Broken
				bodygroup = {
					name = "broken",
					submodel_index = 1
				}
			},
		}
	end
	//Catch items that have a visuals.playback_activity table (148 "Engineer Welding Mask" and 745 "The Infernal Orchestrina") and convert those to selectable animations
	if v.visuals and v.visuals.playback_activity then
		v.visuals.styles = {
			[0] = {
				name = "#TF_style0_normal",
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
		v._call_styles_animations = true
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
					end
				end
				if strange_prefix then name = strange_prefix end
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
	//Clear items that still have no class assigned after the above check, which means they have no model
	//(these are items that only exist in the backpack like tools, craft items, stamps, most crates+keys)
	if !v.used_by_classes then
		//MsgN("group 1: ", k, " ", v.name)
		s.items[k] = nil
	else
		//Also clear items that have a class assigned, but have no model or other visual data 
		//(store bundles, invisible action items like damaged capacitor, class craft tokens)
		if (!v.model_player and !v.model_player_per_class and !v.visuals and !v.taunt) then
			//MsgN("group 2: ", k, " ", v.name)
			s.items[k] = nil
		end
		//Also make sure all used_by_classes keys are uncapitalized, otherwise they won't work (see 252 Dr's Dapper Topper and a few others)
		local tab = {}
		for k, v in pairs (v.used_by_classes) do
			tab[string.lower(k)] = v
		end
		v.used_by_classes = tab
	end


	//Item sets and collections list items by name, not id, so they need to be able to retrieve the item id by name
	items_by_name[v.name] = k
end


//s.equip_regions has multiple "shared" keys that are subtables filled with many different class-specific strings, but these get clobbered by util.KeyValuesToTable, 
//so we have to rescue them. also use this chance to get the implementation order, because it makes the equip region list look nicer.
local tab = {}
for classid, _ in ipairs (classes) do //sort these by class so we can filter them easily + print class-based ones in class order
	tab[classid] = {}
end
//Also use this opportunity to process item sets and collections in implementation order
local sets = {}
local collections = {}
local paintkit_collections = {}

for k, v in ipairs (s2) do
	if v.Key == "equip_regions_list" then
		for k2, v2 in ipairs (v.Value) do
			if istable(v2.Value) then
				local conflict_tab = {}
				for k3, v3 in pairs (v2.Value) do
					for classid, class in ipairs (classes) do
						if string.StartsWith(v3.Key, class.shortname) or (class.extra_equip_region_prefix and string.StartsWith(v3.Key, class.extra_equip_region_prefix)) then
							if used_equip_regions[v3.Key] then
								table.insert(tab[classid], v3.Key)
								conflict_tab[v3.Key] = {}
							end
							break
						end
					end
				end
				//Emulate buggy behavior from TF code that causes all equip regions in the same "shared" table to conflict with each other. 
				//(https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_schema.cpp#L5127-L5131)
				//Ideally, it shouldn't be possible to equip more than one region from each table on a single class, because they're all 
				//class-specific (which is what the TF code had in mind), but some class-specific equip regions are actually on multi-class
				//items, so you can run into situations where a multi-class "sniper_pocket" item like 30607 The Pocket Raiders conflicts 
				//with "spy_coat" items when you try to equip them together in TF2. This is dumb and unintuitive, but we should let players
				//know that these conflicts exist, so that they don't get surprised by them if they build a loadout here and then try to 
				//recreate it in TF2.
				for region1, _ in pairs (conflict_tab) do
					for region2, _ in pairs (conflict_tab) do
						if region1 != region2 then
							conflict_tab[region1][region2] = 1
						end
					end
					s.equip_conflicts[region1] = conflict_tab[region1]
				end
			else
				if used_equip_regions[v2.Key] then table.insert(tab[1], v2.Key) end
			end
		end
	elseif v.Key == "item_sets" then
		for k2, v2 in ipairs (v.Value) do
			local add_set = false //exclude sets that don't contain any spawnable items
			//Unlike collections, item sets are almost always only equippable by a single class, with the exception of a 
			//few sets containing a single multi-class hat. Categorize sets by which class is able to equip *all* the items.
			local _cat = {}
			for i = 2, 10 do
				_cat[i] = true
			end
			for k3, _ in pairs (s.item_sets[v2.Key].items) do
				if s.items[items_by_name[k3]] then
					add_set = true
					s.items[items_by_name[k3]]._item_set = v2.Key
					//Keep track of which class we should categorize this set by
					for classid, _ in pairs (_cat) do
						if !s.items[items_by_name[k3]].used_by_classes[classes[classid].longname] then
							_cat[classid] = nil
						end
					end
					//Also keep track of which classes we should show this set for - in case of multi-class items, we still want
					//to list the set when we're filtering for one of the other classes, but categorize it separately.
					s.item_sets[v2.Key]._classes = s.item_sets[v2.Key]._classes or {}
					for class, _ in pairs (s.items[items_by_name[k3]].used_by_classes) do
						s.item_sets[v2.Key]._classes[class_longname_to_id[class]] = true
					end
				end
			end
			if add_set then table.insert(sets, v2.Key) end
			if table.Count(_cat) == 0 then _cat[1] = true end //fallback for item sets that aren't entirely equippable by any one class? this shouldn't happen.
			for classid, _ in SortedPairs(_cat) do
				s.item_sets[v2.Key]._cat = classid //categorize by the first listed class; there shouldn't be any case where there's more than 1 by this point
				break
			end
		end
	elseif v.Key == "item_collections" then
		for k2, v2 in ipairs (v.Value) do
			local add_set = false //exclude sets that don't contain any spawnable items
			local add_paintkit_set = false
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
							for class, _ in pairs (s.items[items_by_name[k4]].used_by_classes) do
								s.item_collections[v2.Key]._classes[class_longname_to_id[class]] = true
							end
						//Also retrieve paintkit rarities and collections here
						elseif paintkit_items_to_ids[k4] then
							local id = paintkit_items_to_ids[k4]
							paintkit_rarities[id] = k3
							paintkit_ids_to_collections[id] = v2.Key
							add_paintkit_set = true
						end
					end
				else
					if s.items[items_by_name[k3]] then
						add_set = true
						s.items[items_by_name[k3]]._item_collection = v2.Key
						//Also keep track of which classes we should show this set for
						s.item_collections[v2.Key]._classes = s.item_collections[v2.Key]._classes or {}
						for class, _ in pairs (s.items[items_by_name[k3]].used_by_classes) do
							s.item_collections[v2.Key]._classes[class_longname_to_id[class]] = true
						end
					end
				end
			end
			if add_set then table.insert(collections, v2.Key) end
			if add_paintkit_set then table.insert(paintkit_collections, v2.Key) end
		end
	end
end
s.equip_regions_list = tab


//So item attrib displays can get these faster
s.attribute_ids_by_name = {}
for k, v in pairs (s.attributes) do
	s.attribute_ids_by_name[v.name] = k
end

//Make all particle defs easily accessible by id number
s.attribute_controlled_attached_particles_all = {}
for k, v in pairs (s.attribute_controlled_attached_particles) do
	for k2, v2 in pairs (v) do
		s.attribute_controlled_attached_particles_all[k2] = v2
	end
end


TF2Items = s


//Load custom items - items saved by the player will be in the data/ folder, while addons can include their own in their data_static/ folder.
//These are determined by the server, not clients, because they need to be consistent between all users - if we want this feature to be useful in 
//multiplayer, then we want to have item defs for models that the server has available, not for whatever players happen to have saved on their end.
local function LoadCustomItems()
	if SERVER or game.SinglePlayer() then //in singleplayer, the client has access to the same data folder as the server, so it can just read the files on its own without networking; LocalPlayer():IsListenServerHost() doesn't work here because the player entity is null when we run this on startup
		//Clear any old custom items and repopulate them; it's possible that the change we made was removing one of them
		for k, v in pairs (TF2Items.items) do
			if isstring(k) then tab[k] = nil end
		end

		local function ReadCustomItems(dir, path)
			local files, _ = file.Find(dir .. "*.txt", path)
			if !istable(files) then return end
			for _, v in pairs (files) do
				local f = file.Read(dir .. v, path)
				if isstring(f) then
					local name = string.StripExtension(v)
					f = util.JSONToTable(f)
					if !istable(f) then continue end
					f.name = name
					TF2Items.items[name] = f
				end
			end
		end
		ReadCustomItems("data_static/tf2itembrowser_customitems/", "GAME")
		//in case of a name conflict, saved items in data folder take priority over addons
		ReadCustomItems("tf2itembrowser_customitems/", "DATA")

		if CLIENT and IsValid(TF2ItemBrowser) then TF2ItemBrowser:RebuildIconList() end
	else
		//in multiplayer, connecting clients won't have access to the server's data folder, so tell 
		//them to request the table of custom items from the server once they open the browser.
		TF2ItemBrowser_RequestCustomItems = true
	end
end
LoadCustomItems()

if SERVER then
	util.AddNetworkString("TF2ItemBrowser_CustomItems_GetFromSv")
	util.AddNetworkString("TF2ItemBrowser_CustomItems_SendToCl")

	net.Receive("TF2ItemBrowser_CustomItems_GetFromSv", function(_, ply)
		local tab = {}
		for k, v in pairs (TF2Items.items) do
			if isstring(k) then tab[k] = v end
		end

		net.Start("TF2ItemBrowser_CustomItems_SendToCl", true)
			net.WriteData(util.Compress(util.TableToJSON(tab)))
		net.Send(ply)
	end)
else
	net.Receive("TF2ItemBrowser_CustomItems_SendToCl", function(len)
		local tab = util.Decompress(net.ReadData(len/8))
		if !tab then return end
		tab = util.JSONToTable(tab)
		if !tab then return end

		if TF2ItemBrowser_RequestCustomItems then
			for k, v in pairs (tab) do
				TF2Items.items[k] = v
			end
			TF2ItemBrowser_RequestCustomItems = nil
			if IsValid(TF2ItemBrowser) then TF2ItemBrowser:RebuildIconList() end
		end
	end)
end

if SERVER then
	util.AddNetworkString("TF2ItemBrowser_NewCustomItem_SendToSv")
	util.AddNetworkString("TF2ItemBrowser_CustomItemsUpdate_SendToCl")

	net.Receive("TF2ItemBrowser_NewCustomItem_SendToSv", function(len, ply)
		local i = util.Decompress(net.ReadData(len/8), 8000) //max 8kb; these are small text files and definitely shouldn't be this large
		if !i then return end

		//TODO: permissions; only let certain players create new custom items in multiplayer

		local tab = util.JSONToTable(i)
		if !tab or !tab.name then return end //this shouldn't happen
		file.Write("tf2itembrowser_customitems/" .. tab.name .. ".txt", i)

		//Rebuild custom items table with the new item, and make players retrieve it
		LoadCustomItems()
		net.Start("TF2ItemBrowser_CustomItemsUpdate_SendToCl")
		net.Broadcast()
	end)
else
	net.Receive("TF2ItemBrowser_CustomItemsUpdate_SendToCl", function()
		LoadCustomItems()
	end)
end










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
	elseif tab[classes[class].longname] then
		return tab[classes[class].longname]
	elseif tab.basename then
		return string.Replace(tab.basename, "%s", classes[class].shortname)
	end
end

//Given an item data table with id, class, team, style, returns a table with the models, skin, and bodygroups to use.
local function GetItemModelVisuals(data)

	local i = TF2Items.items[data.id] or {}
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
		vis.item_bg["class"] = classbg[classes[data.class].longname]
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
	if i.taunt and i.taunt.custom_taunt_prop_per_class then
		vis.models.taunt_prop = i.taunt.custom_taunt_prop_per_class[classes[data.class].longname]
	end
	if i.static_attrs then
		vis.models.stat_clock = i.static_attrs.weapon_uses_stattrak_module
		vis.stat_clock_scale = i.static_attrs.weapon_stattrak_module_scale
	end

	return vis

end

local function GetItemDefaultParticleEffects(data)

	local i = TF2Items.items[data.id] or {}
	local pe_def = {}

	if i.visuals and i.visuals.attached_particlesystems then
		for k, v in pairs(i.visuals.attached_particlesystems) do
			if PEPlus_FindPCFsFromEffect(v.system) then
				table.insert(pe_def, v)
			end
		end
	end
	if i.attributes and i.attributes["attach particle effect static"] then
		local tab = TF2Items.attribute_controlled_attached_particles_all[i.attributes["attach particle effect static"].value]
		if tab and PEPlus_FindPCFsFromEffect(tab.system) then
			if CLIENT then
				tab = table.Copy(tab)
				tab._displayname = GetTFLanguageString("#Attrib_Particle" .. i.attributes["attach particle effect static"].value) //can be nil; uses the effect name if so
			end
			table.insert(pe_def, tab)
		end
	end
	if i.attributes and i.attributes["attach particle effect"] then
		local tab = TF2Items.attribute_controlled_attached_particles_all[i.attributes["attach particle effect"].value]
		if tab and PEPlus_FindPCFsFromEffect(tab.system) then
			if CLIENT then
				tab = table.Copy(tab)
				tab._displayname = GetTFLanguageString("#Attrib_Particle" .. i.attributes["attach particle effect"].value) //can be nil; uses the effect name if so
			end
			table.insert(pe_def, tab)
		end
	end

	return pe_def

end










local BrowserInputs, BrowserInputs_bits, WriteItemDataTable, ReadItemDataTable //define these here so that window/icon code can access them

if CLIENT then

	local LoadoutItemPopupBorder = GWEN.CreateTextureBorder(0, 0, 64, 64, 11, 11, 11, 11, Material("vgui/button_holder_central.vmt"))
	local GrayDialogBorder = GWEN.CreateTextureBorder(0, 0, 256, 128, 24, 24, 24, 24, Material("vgui/loadout_rect.vmt"))
	local TFThinLineBorder = GWEN.CreateTextureBorder(0, 0, 128, 128, 24, 24, 24, 24, Material("hud/tournament_panel_brown.vmt"))
	local OutlinedGreyBox = GWEN.CreateTextureBorder(0, 0, 128, 64, 24, 24, 24, 0, Material("vgui/loadout_round_rect_selected.vmt"))
	local BackpackItemBorderUnscaled = GWEN.CreateTextureBorder(0, 0, 256, 128, 24, 24, 24, 24, Material("vgui/backpack_rect_vc.vmt")) //for custom item editor's preview; the version used by item icons is defined down in the item icon code and scales with the currently selected icon size
	local item_icon_sizes = {
		--[[{ //attempt at a size that makes the icons 64px like spawnicons; these look good, but it's awkward to switch between this and backpack-sized, because the window never fits both sizes well
			//name = "Small",
			w = 64,
			h = math.Round(94*(64/121)),
			scale = 64/121, //tf2 backpack panels are 121x94 (???); scale ours down proportionately
			gap_h = math.Round(6*(64/121)),
			gap_w = math.Round(9*(64/121)),
			cornericon = math.Round(36*(64/121)),
			rticon_minusw = math.Round(15*(64/121)),
		},]]
		[1] = {},
		[2] = {
			//name = "Medium", //tf2 backpack icon size; these are already huge when placed in the relatively small browser, no need for larger sizes
			w = 121,
			h = 94,
			scale = 1,
			gap_h = 6,
			gap_w = 9,
			cornericon = 36,
			rticon_minusw = 15,
		},
	}
	for k, v in pairs (item_icon_sizes[2]) do //just make a small size that's exactly half the normal size, this works better
		item_icon_sizes[1][k] = v/2//math.Round(v/2)
	end
	local icon_size = CreateClientConVar("cl_tf2itembrowser_iconsize", "1", true, false, "Size of icons in TF2 item browser (1 = small, 2 = large)", 1, #item_icon_sizes):GetInt()
	local popup_w = 480 //keep the width consistent between popup panels, so that when we switch from mouseoverpanel to spawnpanel, it maintains the same horizontal position
	local popup_pad = 25 //34 would match the padding in tf2's backpack screen, but our text is smaller (13px, from 18px), so scale it down proportionately
	local betweenitems = 8
	local betweencategories = 20
	local spinner = Material("vgui/animated/tf2_logo_hourglass.vmt")
	local close_button = Material("vgui/close_button.vmt")
	local close_button_nocircle = Material("vgui/glyph_close_x.vmt")
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
	surface.CreateFont("TF2ItemBrowser_ItemDesc_Smaller", {
		font = "TF2 Secondary",
		size = 15, //even smaller variant only used for control labels like checkboxes; any smaller and it's too hard to read, any larger and there's no room between wearable types for banners
		extended = true
	})
	surface.CreateFont("TF2ItemBrowser_GUISymbols", {
		font = "Marlett", //no idea if this is linux-friendly
		size = 22,
		weight = 0,
		symbol = true
	})
	local gui_colors = {
		TanDark			= Color(117,107,94,255),
		TanLight		= Color(235,226,202,255),
		TanDarker		= Color(46,43,42,255),

		//colors used by CheckButton in tf2_clientscheme.res
		Yellow			= Color(251,235,202,255),
		TransparentBlack	= Color(0,0,0,196),

		Slider_TrackColor	=Color(31,31,31,255),
		Slider_DisabledTextColor=Color(117,117,117,255),

		RedSolid		= Color(192,28,0,255),
		LightRed		= Color(200,80,60,255),
		TFOrange		= Color(145,73,59,255),

		Gray			= Color(178,178,178,255),

		//custom color values not from tf2's clientscheme.res
		_options		= Color(0,0,0,128), //used by option boxes in left side of browser; based on the ones in resource/ui/testitemroot.res

		_unu_default		= Color(0,0,0,128),
		_unu_depressed		= Color(117*.75, 107*.75, 94*.75, 255*.75), //dimmer versions of TanDark used for unusual selector
		_unu_hovered		= Color(117*.2, 107*.2, 94*.2, 255*.2),

		_header			= Color(117*0.535, 107*0.535, 94*0.535, 255), //another darker version of TanDark; used for header and matches item icons
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
		ItemSetName	= Color(225,255,15,255),
		--[[ItemSetItemEquipped	= Color(149,175,12,255),
		ItemSetItemMissing	= Color(139,137,137,255),
		ItemIsotope		= Color(225,255,15,255),
		ItemBundleItem		= Color(149,175,12,255),
		ItemLimitedUse		= Color(0,160,0,255),
		ItemFlag		= Color(117,107,94,255),]]
		ItemLimitedQuantity	= Color(225,209,0,255),
	}
	local icon_paint = Material("vgui/backpack_jewel_paint_splatter.vmt")
	local icon_viewmode_pyrovision = Material("vgui/viewmode_pyrovision.vmt")
	local icon_viewmode_spooky = Material("vgui/viewmode_spooky_off.vmt")
	local icon_unusual = Material("vgui/viewmode_unusual.vmt")
	local icon_statclock = Material("vgui/viewmode_statclock.vmt")
	local icon_strange = Material("vgui/viewmode_strange.vmt")
	local icon_custom = Material("vgui/glyph_steamworkshop.vmt")
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
	local icon_red = Material("vgui/store/store_redteam.vmt")
	local icon_blu = Material("vgui/store/store_blueteam.vmt")

	local function AddTFStyleToVGUI(pnl, alt_style)
		local class = pnl:GetName()
		if class == "DCheckBox" then
			function pnl:Paint(w,h)
				local x, y = w/2, h/2
				local col = gui_colors.TransparentBlack
				if !self:IsEnabled() then col = gui_colors.TanDark end //override used in testitembotcontrols.res
				surface.SetDrawColor(col)
				surface.DrawRect(0,0,w,h)

				col = gui_colors.Yellow
				if self.NegativeCheck then col = gui_colors.LightRed end
				surface.SetDrawColor(col)
				surface.DrawOutlinedRect(0,0,w,h,2)
				
				if self:GetChecked() then
					if self.NegativeCheck then
						//totally overengineered programmatically-generated X symbol because the one in Marlett won't center correctly
						local e = 5 //distance from edge
						local l = 2 //line width
						draw.NoTexture()
						surface.DrawPoly({
							{x=e,y=e+l}, {x=e,y=e}, {x=e+l,y=e}, //upper left corner
							{x=w-e,y=h-e-l}, {x=w-e,y=h-e}, {x=w-e-l,y=h-e} //lower right corner
						})
						surface.DrawPoly({
							{x=w-e-l, y=e}, {x=w-e, y=e}, {x=w-e, y=e+l}, //upper right corner
							{x=e+l, y=h-e}, {x=e, y=h-e}, {x=e, y=h-e-l}} //lower left corner
						)
					else
						//this is how the source engine code draws the *entire* checkbox, just symbols from the Marlett font (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/vgui2/vgui_controls/CheckButton.cpp#L23-L58);
						//we use Draw(OutlinedRect) instead for the box because those symbols don't scale well at this size
						draw.SimpleText("b", "TF2ItemBrowser_GUISymbols", 1, 0, col) //check mark
					end
				end
			end
			pnl:SetSize(20,20)
		elseif class == "DCheckBoxLabel" then
			AddTFStyleToVGUI(pnl.Button)
			pnl:SetHeight(20)
			function pnl:PerformLayout()
				local x = self.m_iIndent || 0

				self.Button:SetSize( 20, 20 ) //change 1/2
				self.Button:SetPos( x, math.floor( ( self:GetTall() - self.Button:GetTall() ) / 2 ) )

				self.Label:SizeToContents()
				self.Label:SetPos( x + self.Button:GetWide() + 6, math.floor( ( self:GetTall() - self.Label:GetTall() ) / 2 ) ) //+6 to width is change 2/2
			end
			pnl.Label:SetColor(gui_colors.Yellow)
			pnl.Label:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
		elseif class == "DComboBox" then
			pnl:SetColor(gui_colors.TanLight)
			pnl:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
			pnl.DropButton:Remove()
			function pnl:Paint(w,h)
				local col = gui_colors.TanLight
				surface.SetDrawColor(col)
				surface.DrawOutlinedRect(0,0,w,h,1)

				surface.SetFont("TF2ItemBrowser_GUISymbols")
				local _w, _h = surface.GetTextSize("u")
				draw.SimpleText("u", "TF2ItemBrowser_GUISymbols", w-_w, 0, col) //down-pointing arrow
			end
			function pnl:PerformLayout() end
			function pnl:OnMenuOpened(menu)
				AddTFStyleToVGUI(menu)
				//Not TF2 related, but every DComboBox here already had this as its OnMenuOpened func, so do this here instead:
				//Add a checkmark to the currently selected option.
				//GetChild uses the number of children including spacers, while SetSelectedID uses the number of children
				//not including spacers, so we have to loop through the whole list like this until we've gone through enough
				//non-spacer children to find the correct one.
				local sel = self:GetSelectedID()
				local sel_read = 0
				for i = 1, menu:ChildCount() do
					local child = menu:GetChild(i)
					if child:GetName() == "DMenuOption" then
						sel_read = sel_read + 1
						if sel_read == sel then
							child:SetChecked(true)
							menu:ScrollToChild(child)
							break
						end
					end
				end
			end
		elseif class == "DMenu" then
			function pnl:Paint(w, h)
				surface.SetDrawColor(color_black) //tf2 does this by having a TransparentBlack background and TransparentBlack buttons? whatever, this is the same
				surface.DrawRect(0,0,w,h)
			end
			AddTFStyleToVGUI(pnl:GetVBar())
			for _, v in ipairs (pnl:GetCanvas():GetChildren()) do
				local name = v:GetName()
				if name == "DMenuOption" then
					v:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
					function v:Paint(w, h)
						local col = gui_colors.TanLight
						if self.Hovered or self.Highlight or (self.SubMenu and self.SubMenu:IsVisible()) then
							surface.SetDrawColor(gui_colors.TanLight)
							surface.DrawRect(0,0,w,h)
							col = gui_colors.TanDark
						end
						self:SetColor(col)
						if self:GetChecked() then
							draw.SimpleText("b", "TF2ItemBrowser_GUISymbols", 4, h/2-10, col) //check mark
						end
						if self.SubMenu then
							draw.SimpleText("8", "TF2ItemBrowser_GUISymbols", w-20, h/2-10, col) //right-pointing arrow
						end
					end
					if v.SubMenu then
						v.SubMenuArrow:Remove()
						AddTFStyleToVGUI(v.SubMenu)
					end
				elseif name == "DPanel" and v:GetTall() == 1 then //spacer
					function v:Paint(w, h)
						surface.SetDrawColor(gui_colors.TanLight)
						surface.DrawRect(0,0,w,h)
					end
				end
			end
		elseif class == "DButton" then
			AddTFButtonSounds(pnl)
			//pnl:SetHeight(30) //backpack page button proportions
			pnl:SetHeight(36) //standard button proportions
			pnl:SetFont("TF2ItemBrowser_ItemName")
			pnl.BGColor = gui_colors.TanDark
			pnl.FGColor = gui_colors.TanLight
			pnl.DepressedBGColor = gui_colors.TFOrange
			pnl.DepressedFGColor = gui_colors.TanDarker //same as Black from TF2 clientscheme
			pnl.ArmedBGColor = gui_colors.TFOrange
			pnl.ArmedFGColor = gui_colors.TanLight
			function pnl:Paint(w, h)
				local col = self.BGColor
				local textcol = self.FGColor
				if self.Depressed then
					col = self.DepressedBGColor
					textcol = self.DepressedFGColor
				elseif self.Hovered then
					col = self.ArmedBGColor
					textcol = self.ArmedFGColor
				end
				draw.RoundedBox(12, 0,0,w,h, col)
				self:SetColor(textcol)
			end
		elseif class == "DTextEntry" or class == "DNumberWang" then
			pnl:SetHeight(20) //30 would be more accurate proportionately, but it's too big to fit nicely
			if !alt_style then
				//light textbox, modeled after TF2 backpack search
				pnl:SetFont("TF2ItemBrowser_ItemDesc") //_Smaller is too hard to read with dark text on a bright background
				pnl.BGColor = gui_colors.Yellow
				pnl.FGColor = gui_colors.TanDark
			else
				//dark textbox, modeled after TF2 war paint seed entry
				pnl:SetFont("HudSelectionText") //default verdana but slightly larger
				pnl.BGColor = gui_colors.TransparentBlack
				pnl.FGColor = gui_colors.Gray
			end
			function pnl:Paint(w,h)
				draw.RoundedBox(12, 0,0,w,h, self.BGColor)
				local oldtext = self:GetText()
				if oldtext == "" then oldtext = nil end
				local str = self:GetPlaceholderText()
				if !oldtext and str then
					if (str:StartsWith("#")) then str = str:sub(2) end
					str = language.GetPhrase(str)
					self:SetText(str)
					self.FGColor_Placeholder = self.FGColor_Placeholder or Color(self.FGColor.r, self.FGColor.g, self.FGColor.b, 160)
					self:DrawTextEntryText(self.FGColor_Placeholder, gui_colors.Gray, gui_colors.Gray)
				else
					self:DrawTextEntryText(self.FGColor, gui_colors.Gray, gui_colors.Gray)
				end
				if !oldtext then self:SetText("") end
			end
			//note: can't figure out how to modify the appearance of the right-click menu, it might be hard-coded in C++
		elseif class == "DScrollPanel" then
			AddTFStyleToVGUI(pnl:GetVBar())
		elseif class == "DVScrollBar" then
			//ugly default tf2 clientscheme styled scrollbar, this is close enough to what's used by all the scrollbars in tf2 with buttons
			function pnl:Paint(w,h) end
			function pnl.btnUp:Paint(w,h)
				draw.SimpleText("t", "TF2ItemBrowser_GUISymbols", w/2, h/2, gui_colors.Gray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) //up-pointing arrow
			end
			function pnl.btnDown:Paint(w,h)
				draw.SimpleText("u", "TF2ItemBrowser_GUISymbols", w/2, h/2, gui_colors.Gray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) //down-pointing arrow
			end
			function pnl.btnGrip:Paint(w,h)
				surface.SetDrawColor(gui_colors.Gray)
				surface.DrawRect(0,0,w,h)
			end
		elseif class == "DNumSlider" then
			pnl.Label:SetColor(gui_colors.TanLight)
			pnl.Label:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
			pnl:SetHeight(21) //slightly taller to make sure that the taller notches fit
			AddTFStyleToVGUI(pnl.TextArea, true) //use alt style for textentry; TF2 sliders don't have textentries at all, so just go with what looks best
			local function PaintNotches( x, y, w, h, num ) //copied wholesale from lua/skins/default.lua, except the notch height and positions are changed (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/skins/default.lua#L940-L958)
				if (!num) then return end
				local space = w / num
				-- Ensure at least 1 px between each notch
				if (space < 2) then
					space = 2
					num = w / space
				end
				for i = 0, math.ceil(num) do
					surface.DrawRect(x + i * space, y + 7, 1, 5)
				end
			end
			function pnl.Slider:Paint(w,h)
				surface.SetDrawColor(gui_colors.Slider_TrackColor)
				surface.DrawRect(4, h/2-2, w-7, 4)
				if pnl:IsEnabled() then
					surface.SetDrawColor(gui_colors.TanLight) //emulate the TanLight color used by unusual position slider (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/client/tf/vgui/class_loadout_panel.cpp#L310)
				else
					surface.SetDrawColor(gui_colors.Slider_DisabledTextColor)
				end
				PaintNotches(8, h/2-1, w-16, 1, self:GetNotches())
			end
			pnl.Slider.Knob:SetTall(16)
			function pnl.Slider.Knob:Paint(w,h)
				if pnl:IsEnabled() then
					surface.SetDrawColor(gui_colors.TanLight) //somehow the unusual position slider's knob color is the same as the tick color. i can't find the code for this, but just go with it.
				else
					surface.SetDrawColor(gui_colors.Slider_DisabledTextColor)
				end
				surface.DrawRect(4,0,w/2+1,h)
			end
		elseif class == "DColorMixer" then
			pnl.label:SetColor(gui_colors.TanLight)
			pnl.label:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
			function pnl.PerformLayout(self, x, y)
				//Modified version of CtrlColor:PerformLayout (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/gamemode/spawnmenu/controls/ctrlcolor.lua#L13)
				//Only does palette button sizes, doesn't clamp their sizes and resizes them more smoothly
				local ColorRows = #self.Palette:GetChildren() / 3
				self.Palette:SetButtonSize(self:GetWide() / ColorRows)
			end
			AddTFStyleToVGUI(pnl.txtR, true)
			AddTFStyleToVGUI(pnl.txtG, true)
			AddTFStyleToVGUI(pnl.txtB, true)
			pnl.txtR.FGColor = desc_colors.negative
			pnl.txtG.FGColor = quality_colors.selfmade
			pnl.txtB.FGColor = desc_colors.positive
		elseif class == "DHorizontalScroller" then
			//just do something close enough to the visual theme of the clientscheme-styled vertical scrollbar
			function pnl.btnLeft:Paint(w,h)
				surface.SetDrawColor(color_black) //not great but necessary to make the buttons visible against the background
				surface.DrawRect(0,0,w,h)
				draw.SimpleText("w", "TF2ItemBrowser_GUISymbols", (w/2)-1, h/2, gui_colors.Gray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) //left-pointing arrow
			end
			function pnl.btnRight:Paint(w,h)
				surface.SetDrawColor(color_black)
				surface.DrawRect(0,0,w,h)
				draw.SimpleText("8", "TF2ItemBrowser_GUISymbols", w/2, h/2, gui_colors.Gray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) //right-pointing arrow
			end
		elseif class == "DFrame" then
			local title = pnl:GetTitle()
			local header = 30 //this has to be pretty tall to fit the close button comfortably
			local border = 3
			pnl:SetTitle("")
			pnl:ShowCloseButton(false)
			pnl:DockPadding(border+8, header+8, border+8, border+8)


			local text = vgui.Create("DLabel", pnl)
			text:SetContentAlignment(4) //top middle
			text:SetFont("TF2ItemBrowser_ItemName")
			text:SetColor(gui_colors.LightRed)
			text:SetText(">>")
			text:SizeToContents()
			text:SetPos(8, ((header)/2) - (text:GetTall()/2) + 1)
			local w = text:GetWide()

			local text = vgui.Create("DLabel", pnl)
			text:SetContentAlignment(4) //top middle
			text:SetFont("TF2ItemBrowser_ItemName")
			text:SetColor(gui_colors.TanLight)
			text:SetText(title)
			text:SizeToContents()
			text:SetPos(8+w+8, ((header)/2) - (text:GetTall()/2) + 1)

			local close = vgui.Create("DButton", pnl)
			close:SetText("")
			close:SetSize(22,22)
			function close:Paint(w,h)
				if self.Depressed then
					surface.SetDrawColor(color_white)
				elseif self.Hovered then
					surface.SetDrawColor(gui_colors.LightRed)
				else
					surface.SetDrawColor(gui_colors.TanDark)
				end
				surface.SetMaterial(close_button)
				surface.DrawTexturedRect(0,0,w,h)
			end
			AddTFButtonSounds(close)
			function close:DoClick()
				pnl:Close()
			end

			function pnl:PerformLayout()
				close:SetPos(self:GetWide()-22-4, 4)
			end

			function pnl:OnMousePressed() //(based off https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/dframe.lua#L208-L224)
				local screenX, screenY = self:LocalToScreen( 0, 0 )

				if ( self.m_bSizable && gui.MouseX() > ( screenX + self:GetWide() - 20 ) && gui.MouseY() > ( screenY + self:GetTall() - 20 ) ) then
					self.Sizing = { gui.MouseX() - self:GetWide(), gui.MouseY() - self:GetTall() }
					self:MouseCapture( true )
					return
				end

				if ( self:GetDraggable() && gui.MouseY() < ( screenY + header ) ) then //the only change; use our taller header height here
					self.Dragging = { gui.MouseX() - self.x, gui.MouseY() - self.y }
					self:MouseCapture( true )
					return
				end
			end

			function pnl:Paint(w, h)
				//draw header and border
				surface.SetDrawColor(gui_colors._header)
				surface.DrawRect(0,0,w,h)
				//draw main body
				surface.SetDrawColor(gui_colors.TanDarker)
				surface.DrawRect(border,header,w-(border*2),h-header-border)
			end

			local old_Think = pnl.Think
			function pnl:Think(...)
				old_Think(self, ...)
				//Do hover cursor for our larger header here (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/dframe.lua#L183)
				local screenX, screenY = self:LocalToScreen(0, 0)
				if --[[self.Hovered and]] gui.MouseY() < (screenY + header) then
					self:SetCursor("sizeall")
				end
			end
		end
	end
	local function TFStyleVGUI(class, par, alt_style)
		local pnl = vgui.Create(class, par)
		if IsValid(pnl) then
			AddTFStyleToVGUI(pnl, alt_style)
		end
		return pnl
	end
	local function AddTFStyleTooltip(self, text, font, fgcol, bgcol)
		font = font or "TF2ItemBrowser_ItemDesc_Smaller"
		fgcol = fgcol or gui_colors.TanLight
		bgcol = bgcol or color_black
		local old_Paint = self.Paint
		function self:Paint(w,h,...)
			if self:IsHovered() then
				if !IsValid(TF2ItemBrowser_Tooltip) or TF2ItemBrowser_Tooltip.Owner != self then
					local time = CurTime()
					self.HoverTime = self.HoverTime or time
					if time - self.HoverTime > 0.1 then
						local pnl = vgui.Create("DLabel", g_ContextMenu)
						pnl:SetFont(font)
						pnl:SetText(text)
						pnl:SetTextColor(fgcol)
						pnl:SetAutoStretchVertical(true)
						pnl:SetContentAlignment(5) //center
						pnl:SetZPos(32767)
						//pnl:DockPadding(4,4,4,4)
						pnl:SizeToContents()
						pnl:SetSize(pnl:GetWide() + 8, pnl:GetTall() + 8)
						pnl:SetMouseInputEnabled(false)

						function pnl:Paint(w,h)
							surface.SetDrawColor(bgcol)
							surface.DrawRect(0,0,w,h)
							//get rid of orphaned tooltips
							if !IsValid(pnl.Owner) then pnl:Remove() end
						end
						
						local x, y = self:LocalToScreen((w/2)-(pnl:GetWide()/2),-pnl:GetTall()+8)
						pnl:SetPos(x,y)
						TF2ItemBrowser_Tooltip = pnl
						pnl.Owner = self
					end
				end
			else
				self.HoverTime = nil
				if IsValid(TF2ItemBrowser_Tooltip) and TF2ItemBrowser_Tooltip.Owner == self then
					TF2ItemBrowser_Tooltip:Remove()
				end
			end
			if old_Paint then old_Paint(self,w,h,...) end
		end
	end
	//convenience func for adding labels to dropdown dcomboboxes and such
	local function AddTFLabelToVGUI(child, label)
		local parent = child:GetParent()
		local pnl = vgui.Create("Panel", parent)
		pnl.Label = vgui.Create("DLabel", pnl)
		pnl.Label:SetColor(gui_colors.TanLight)
		pnl.Label:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
		pnl.Label:SetText(label)
		pnl.Label:Dock(LEFT)
		child:SetParent(pnl)
		child:Dock(FILL)
		pnl:SetHeight(20)
		function pnl.PerformLayout(_, w, h)
			pnl.Label:SetWide(w / 2.4)
		end
		return pnl
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

	local paints = {
		{name = "#TF_Tool_PaintCan_1",	[1] = Vector(114, 158, 66)},	//Indubitably Green
		{name = "#TF_Tool_PaintCan_2",	[1] = Vector(66, 79, 59)},	//Zepheniah's Greed
		{name = "#TF_Tool_PaintCan_3",	[1] = Vector(81, 56, 74)},	//Noble Hatter's Violet
		{name = "#TF_Tool_PaintCan_4",	[1] = Vector(216, 190, 216)},	//Color No. 216-190-216
		{name = "#TF_Tool_PaintCan_5",	[1] = Vector(125, 64, 113)},	//A Deep Commitment to Purple
		{name = "#TF_Tool_PaintCan_6",	[1] = Vector(207, 115, 54)},	//Mann Co. Orange
		{name = "#TF_Tool_PaintCan_7",	[1] = Vector(165, 117, 69)},	//Muskelmannbraun
		{name = "#TF_Tool_PaintCan_8",	[1] = Vector(197, 175, 145)},	//Peculiarly Drab Tincture
		{name = "#TF_Tool_PaintCan_9",	[1] = Vector(105, 77, 58)},	//Radigan Conagher Brown
		{name = "#TF_Tool_PaintCan_10",	[1] = Vector(124, 108, 87)},	//Ye Olde Rustic Colour
		{name = "#TF_Tool_PaintCan_11",	[1] = Vector(231, 181, 59)},	//Australium Gold
		{name = "#TF_Tool_PaintCan_12",	[1] = Vector(126, 126, 126)},	//Aged Moustache Grey
		{name = "#TF_Tool_PaintCan_13",	[1] = Vector(230, 230, 230)},	//An Extraordinary Abundance of Tinge
		{name = "#TF_Tool_PaintCan_14",	[1] = Vector(20, 20, 20)},	//A Distinctive Lack of Hue
		{name = "#TF_Tool_PaintCan_15",	[1] = Vector(255, 105, 180)},	//Pink as Hell
		{name = "#TF_Tool_PaintCan_16",	[1] = Vector(47, 79, 79)},	//A Color Similar to Slate
		{name = "#TF_Tool_PaintCan_17",	[1] = Vector(128, 128, 0)},	//Drably Olive
		{name = "#TF_Tool_PaintCan_18",	[1] = Vector(50, 205, 50)},	//The Bitter Taste of Defeat and Lime
		{name = "#TF_Tool_PaintCan_19",	[1] = Vector(240, 230, 140)},	//The Color of a Gentlemann's Business Pants
		{name = "#TF_Tool_PaintCan_20",	[1] = Vector(233, 150, 122)},	//Dark Salmon Injustice
		{name = "#TF_Tool_PaintCan_21",	[1] = Vector(188, 221, 179)},	//A Mann's Mint
		{name = "#TF_Tool_PaintCan_22",	[1] = Vector(45, 45, 36)},	//After Eight

		{name = "#TF_Tool_PaintCan_TeamColor",	[1] = Vector(184, 56, 59),	[2] = Vector(88, 133, 162)},	//Team Spirit
		{name = "#TF_Tool_PaintCan_TeamColor2",	[1] = Vector(72, 56, 56),	[2] = Vector(56, 66, 72)},	//Operator's Overalls
		{name = "#TF_Tool_PaintCan_TeamColor3",	[1] = Vector(168, 154, 140),	[2] = Vector(131, 159, 163)},	//Waterlogged Lab Coat
		{name = "#TF_Tool_PaintCan_TeamColor4",	[1] = Vector(59, 31, 35),	[2] = Vector(24, 35, 61)},	//Balaclavas Are Forever
		{name = "#TF_Tool_PaintCan_TeamColor5",	[1] = Vector(101, 71, 64),	[2] = Vector(40, 57, 77)},	//An Air of Debonair
		{name = "#TF_Tool_PaintCan_TeamColor6",	[1] = Vector(128, 48, 32),	[2] = Vector(37, 109, 141)},	//The Value of Teamwork
		{name = "#TF_Tool_PaintCan_TeamColor7",	[1] = Vector(195, 108, 45),	[2] = Vector(184, 128, 53)},	//Cream Spirit

		{name = "#TF_HalloweenSpell_Paint_1", override = 3},			//Putrescent Pigmentation
		{name = "#TF_HalloweenSpell_Paint_2", override = 1},			//Die Job
		{name = "#TF_HalloweenSpell_Paint_3", override = 2},			//Chromatic Corruption
		{name = "#TF_HalloweenSpell_Paint_4", override = 4, override_2 = 6},	//Spectral Spectrum
		{name = "#TF_HalloweenSpell_Paint_5", override = 5},			//Sinister Staining
		{name = "Halloween Spell: Afraid of Shadows (unused)", override = 7},	//not localized, bad!!
	}
	local critglows = {
		{name = "Critboost",	[1] = Vector(80, 8, 5),		[2] = Vector(5, 20, 80),	sparks_rb = true},
		{name = "Mini-Crits",	[1] = Vector(226, 150, 62),	[2] = Vector(29, 202, 135),	sparks_rb = false},
		{name = "Hype Mode",	[1] = Vector(50, 2, 48),	sparks_rb = false},
	}
	PrecacheParticleSystem("critgun_weaponmodel_red")
	PrecacheParticleSystem("critgun_weaponmodel_blu")
	PrecacheParticleSystem("critgun_weaponmodel_colorable")
	local wear_strings = {
		[0] = "#TFUI_InvTooltip_None",
		[1] = "#TFUI_InvTooltip_FactoryNew",
		[2] = "#TFUI_InvTooltip_MinimalWear",
		[3] = "#TFUI_InvTooltip_FieldTested",
		[4] = "#TFUI_InvTooltip_WellWorn",
		[5] = "#TFUI_InvTooltip_BattleScared"
	}
	local unusual_icon_overrides = { //used with PEPlus_BoundsToView to set custom camera positions for unusual effect icons
		//series 1
		superrare_confetti_green = {Vector(-25,-25,-50), Vector(25,25,15)},
		superrare_confetti_purple = {Vector(-25,-25,-35), Vector(25,25,40)}, //yes, this is different from green
		superrare_flies = {Vector(-10,-10,-10), Vector(10,10,10)}, //zoom way in to at least *try* to make flies show up in the thumbnail
		//series 2
		unusual_storm = {Vector(-20,-20,-35), Vector(20,20,55)},
		unusual_blizzard = {Vector(-14,-14,-14), Vector(14,14,28)},
		unusual_orbit_nutsnbolts = {Vector(-15,-15,-8), Vector(15,15,19)},
		unusual_orbit_planets = {Vector(-20,-20,-10), Vector(20,20,20)},
		unusual_bubbles = {Vector(-15,-15,-10), Vector(15,15,30)},
		//halloween 2011
		unusual_bubbles_green = {Vector(-15,-15,-10), Vector(15,15,30)},
		//halloween 2012
		unusual_storm_spooky = {Vector(-20,-20,-35), Vector(20,20,55)},
		//robotic boogaloo
		unusual_robot_holo_glow_green = {Vector(-10,-10,-6), Vector(10,10,14)},
		unusual_robot_holo_glow_orange = {Vector(-10,-10,-6), Vector(10,10,14)},
		unusual_robot_orbit_binary = {Vector(-15,-15,0), Vector(15,15,15)},
		unusual_robot_orbit_binary2 = {Vector(-15,-15,0), Vector(15,15,15)},
		unusual_robot_orbiting_sparks = {Vector(-20,-20,-5), Vector(20,20,20)},
		unusual_robot_orbiting_sparks2 = {Vector(-20,-20,-5), Vector(20,20,20)},
		unusual_robot_radioactive = {Vector(-20,-30,-10), Vector(25,10,30)},
		unusual_robot_radioactive2 = {Vector(-20,-30,-10), Vector(25,10,30)},
		//series 3
		unusual_hearts_bubbling = {Vector(-15,-15,-10), Vector(15,15,30)},
		//halloween 2013
		unusual_meteor_shower_parent_orange = {Vector(-20,-20,-20), Vector(20,20,40)},
		unusual_meteor_shower_parent_purple = {Vector(-20,-20,-20), Vector(20,20,40)},
		unusual_meteor_shower_parent_green = {Vector(-20,-20,-20), Vector(20,20,40)},
		//halloween 2014
		unusual_tentmonster_purple_parent = {Vector(-15,-15,0), Vector(15,15,40)},
		unusual_souls_purple_parent = {Vector(-20,-20,-20), Vector(20,20,50)},
		unusual_souls_green_parent = {Vector(-20,-20,-20), Vector(20,20,50)},
		//end of the line
		unusual_eotl_frostbite = {Vector(-13,-13,-10), Vector(13,13,40)},
		unusual_eotl_oribiting_burning_duck_parent = {Vector(-20,-20,-12), Vector(20,20,30)},
		//invasion
		unusual_invasion_atomic_green = {Vector(-22,-22,-18),Vector(22,22,20)},
		unusual_invasion_boogaloop = {Vector(-15,-15,-5), Vector(15,15,20)},
		unusual_invasion_boogaloop_2 = {Vector(-15,-15,-5), Vector(15,15,20)},
		unusual_invasion_boogaloop_3 = {Vector(-15,-15,-5), Vector(15,15,20)},
		unusual_invasion_codex = {Vector(-12,-12,-5), Vector(12,12,20)},
		unusual_invasion_codex_2 = {Vector(-12,-12,-5), Vector(12,12,20)},
		unusual_invasion_nebula = {Vector(-11,-11,-10), Vector(11,11,20)},
		//halloween 2015
		unusual_hw_deathbydisco_parent = {Vector(-7,-7,0), Vector(7,7,30)},
		unusual_mystery_parent = {Vector(-18,-18,0), Vector(18,18,18)},
		unusual_mystery_parent_green = {Vector(-18,-18,0), Vector(18,18,18)},
		//halloween 2016
		unusual_universe = {Vector(-11,-11,0), Vector(11,11,22)},
		unusual_star_green_parent = {Vector(-20,-20,-13), Vector(20,20,40)},
		unusual_star_purple_parent = {Vector(-20,-20,-13), Vector(20,20,40)},
		//halloween 2018
		unusual_bubble_mess_parent_green = {Vector(-20,-20,-20), Vector(20,20,20)},
		unusual_bubble_mess_parent_orange = {Vector(-20,-20,-20), Vector(20,20,20)},
		unusual_bubble_mess_parent_purple = {Vector(-20,-20,-20), Vector(20,20,20)},
		unusual_constellations_blue = {Vector(-13,-13,0), Vector(13,13,42)},
		unusual_constellations_pink = {Vector(-13,-13,0), Vector(13,13,42)},
		unusual_constellations_purple = {Vector(-13,-13,0), Vector(13,13,42)},
		unusual_symbols_parent_fire = {Vector(-20,-20,-20), Vector(20,20,40)},
		unusual_symbols_parent_dead = {Vector(-20,-20,-20), Vector(20,20,40)},
		unusual_symbols_parent_lightning = {Vector(-20,-20,-20), Vector(20,20,40)},
		unusual_crystalball = {Vector(-10,-10,-5), Vector(10,10,35)},
		unusual_psychic_eye = {Vector(-15,-15,-5), Vector(15,15,45)},
		//halloween 2019
		unusual_dimension_parent = {Vector(-12,-12,-8), Vector(12,12,32)},
		unusual_aura_purple_parent = {Vector(-10,-10,-5), Vector(10,10,15)},
		unusual_aura_green_parent = {Vector(-10,-10,-5), Vector(10,10,15)},
		unusual_aura_red_parent = {Vector(-10,-10,-5), Vector(10,10,15)},
		unusual_forest_scene_parent_purple = {Vector(-8,-8,-0), Vector(8,8,20)},
		unusual_forest_scene_parent_green = {Vector(-8,-8,-0), Vector(8,8,20)},
		unusual_vortex_energy_parent_p = {Vector(-10,-10,-15), Vector(10,10,25)},
		unusual_vortex_energy_parent_g = {Vector(-10,-10,-15), Vector(10,10,25)},
		unusual_vortex_energy_parent_o = {Vector(-10,-10,-15), Vector(10,10,25)},
		//smissmas 2019
		unusual_sparkling_lights_parent02 = {Vector(-16,-16,-17), Vector(16,16,25)},
		unusual_icecave_parent = {Vector(-16,-16,-40), Vector(16,16,35)},
		unusual_polygon_teamcolor_red = {Vector(-13,-13,-13), Vector(13,13,26)},
		unusual_polygon_teamcolor_blue = {Vector(-13,-13,-13), Vector(13,13,26)},
		unusual_polygon_green = {Vector(-13,-13,-13), Vector(13,13,26)},
		unusual_polygon_amber = {Vector(-13,-13,-13), Vector(13,13,26)},
		unusual_snowfall_blue = {Vector(-16,-16,-16), Vector(16,16,32)},
		unusual_snowfall_white = {Vector(-16,-16,-16), Vector(16,16,32)},
		unusual_mayor_balloonicorn_teamcolor_red = {Vector(-20,-20,-5), Vector(20,20,25)},
		unusual_mayor_balloonicorn_teamcolor_blue = {Vector(-20,-20,-5), Vector(20,20,25)},
		//summer 2020
		unusual_circling_spell_green_parent = {Vector(-18,-18,-10), Vector(18,18,37)},
		unusual_circling_spell_orange_parent = {Vector(-18,-18,-10), Vector(18,18,37)},
		unusual_circling_spell_purple_parent = {Vector(-18,-18,-10), Vector(18,18,37)},
		unusual_circling_spell_blue_parent = {Vector(-18,-18,-10), Vector(18,18,37)},
		unusual_bees = {Vector(-17,-17,-17), Vector(17,17,17)},
		unusual_playflies_green_parent = {Vector(-20,-20,-10), Vector(20,20,30)},
		unusual_playflies_orange_parent = {Vector(-20,-20,-10), Vector(20,20,30)},
		unusual_playflies_purple_parent = {Vector(-20,-20,-10), Vector(20,20,30)},
		unusual_kaleido_scope_parent = {Vector(-10,-16,-10), Vector(10,0,10)},
		//halloween 2020
		unusual_face_parent_G = {Vector(-16,-16,-10), Vector(16,16,25)},
		unusual_face_parent_O = {Vector(-16,-16,-10), Vector(16,16,25)},
		unusual_face_parent_P = {Vector(-16,-16,-10), Vector(16,16,25)},
		unusual_undead_mayor_balloonicorn = {Vector(-20,-20,-5), Vector(20,20,25)},
		unusual_gargoyle = {Vector(-8,-8,-5), Vector(8,8,27)},
		unusual_gargoyle2 = {Vector(-8,-8,-5), Vector(8,8,27)},
		unusual_candy_parent = {Vector(-10,-10,-5), Vector(10,10,30)},
		unusual_pumpkinhead_parent = {Vector(-15,-15,-10), Vector(15,15,35)},
		//smissmas 2020
		unusual_froststorm_blue_parent = {Vector(-12,-12,-12), Vector(12,12,36)},
		unusual_froststorm_purple_parent = {Vector(-12,-12,-12), Vector(12,12,36)},
		unusual_froststorm_yellow_parent = {Vector(-12,-12,-12), Vector(12,12,36)},
		unusual_swirlybeams_goldpurple_parent = {Vector(-8,-8,-10), Vector(10,10,25)},
		unusual_swirlybeams_pinkblue_parent = {Vector(-8,-8,-10), Vector(10,10,25)},
		unusual_icetornado_blue_parent = {Vector(-16,-16,-5), Vector(16,16,40)},
		unusual_icetornado_purple_parent = {Vector(-16,-16,-5), Vector(16,16,40)},
		unusual_icetornado_white_parent = {Vector(-16,-16,-5), Vector(16,16,40)},
		unusual_genplasmos_parent = {Vector(-12,-12,-6), Vector(12,12,18)},
		unusual_genplasmos_b_parent = {Vector(-12,-12,-6), Vector(12,12,18)},
		unusual_genplasmos_c_parent = {Vector(-12,-12,-6), Vector(12,12,18)},
		unusual_mistletoe_teamcolor_red = {Vector(-16,-16,-7), Vector(16,16,20)},
		unusual_mistletoe_teamcolor_blue = {Vector(-16,-16,-7), Vector(16,16,20)},
		//summer 2021
		unusual_breaker_green_parent = {Vector(-15,-15,-10), Vector(15,15,25)},
		unusual_breaker_orange_parent = {Vector(-15,-15,-10), Vector(15,15,25)},
		unusual_breaker_purple_parent = {Vector(-15,-15,-10), Vector(15,15,25)},
		unusual_magic_stingers_orange_parent = {Vector(-15,-15,-10), Vector(15,15,25)},
		unusual_magic_stingers_pink_parent = {Vector(-15,-15,-10), Vector(15,15,25)},
		unusual_magic_stingers_teamcolor_red = {Vector(-15,-15,-10), Vector(15,15,25)},
		unusual_magic_stingers_teamcolor_blue = {Vector(-15,-15,-10), Vector(15,15,25)},
		unusual_bloomhead_orangepurple_parent = {Vector(-10,-10,-15), Vector(10,10,25)},
		unusual_bloomhead_pinkgreen_parent = {Vector(-10,-10,-15), Vector(10,10,25)},
		//halloween 2021
		unusual_phantomcrown_green_parent = {Vector(-15,-15,-10), Vector(15,15,30)},
		unusual_phantomcrown_purple_parent = {Vector(-15,-15,-10), Vector(15,15,30)},
		unusual_phantomcrown_yellow_parent = {Vector(-15,-15,-10), Vector(15,15,30)},
		unusual_lurking_eyes_parent_g = {Vector(-14,-14,0), Vector(14,14,25)},
		unusual_lurking_eyes_parent_o = {Vector(-14,-14,0), Vector(14,14,25)},
		unusual_lurking_eyes_parent_p = {Vector(-14,-14,0), Vector(14,14,25)},
		//smissmas 2021
		unusual_tree3_yellow_parent = {Vector(-9,-25,-11), Vector(10,-8,11)},
		unusual_tree3_teamcolor_red = {Vector(-9,-25,-11), Vector(10,-8,11)},
		unusual_tree3_teamcolor_blue = {Vector(-9,-25,-11), Vector(10,-8,11)},
		unusual_sparkletree_gold_parent = {Vector(-11,-11,0), Vector(11,11,25)},
		unusual_sparkletree_silver_parent = {Vector(-11,-11,0), Vector(11,11,25)},
		unusual_sparkletree_RGB_parent = {Vector(-11,-11,0), Vector(11,11,25)},
		unusual_fairylights_green_parent = {Vector(-15,-25,0), Vector(15,5,0)},
		unusual_fairylights_purple_parent = {Vector(-15,-25,0), Vector(15,5,0)},
		unusual_spire_star_parent = {Vector(-10,-10,10),Vector(10,10,22)},
		unusual_spire_snowball_parent = {Vector(-10,-10,10),Vector(10,10,22)},
		unusual_spire_firework_teamcolor_red = {Vector(-10,-10,10),Vector(10,10,22)},
		unusual_spire_firework_teamcolor_blue = {Vector(-10,-10,10),Vector(10,10,22)},
		unusual_antlers_gold_parent = {Vector(-5,-22,-3), Vector(5,1,3)},
		unusual_antlers_purple_parent = {Vector(-5,-22,-3), Vector(5,1,3)},
		unusual_antlers_teamcolor_red = {Vector(-5,-22,-3), Vector(5,1,3)},
		unusual_antlers_teamcolor_blue = {Vector(-5,-22,-3), Vector(5,1,3)},
		unusual_festive_lights_lights1_parent = {Vector(-13,-13,-5), Vector(13,13,30)},
		//summer 2022
		unusual_spycrabs_teamcolor_red = {Vector(-12,-12,-20),Vector(12,12,20)},
		unusual_spycrabs_teamcolor_blue = {Vector(-12,-12,-20),Vector(12,12,20)},
		unusual_sprinkles_teamcolor_red = {Vector(-15,-15,-10),Vector(15,15,30)},
		unusual_sprinkles_teamcolor_blue = {Vector(-15,-15,-10),Vector(15,15,30)},
		unusual_sprinkles_rainbow_parent = {Vector(-15,-15,-10),Vector(15,15,30)},
		unusual_liquidmagic_green_parent = {Vector(-12,-12,-5),Vector(12,12,20)},
		unusual_liquidmagic_ocean_parent = {Vector(-12,-12,-5),Vector(12,12,20)},
		unusual_liquidmagic_pink_parent = {Vector(-12,-12,-5),Vector(12,12,20)},
		unusual_firework_blue_red_parent = {Vector(-20,-20,-25), Vector(20,20,50)},
		unusual_firework_green_yellow_parent = {Vector(-20,-20,-25), Vector(20,20,50)},
		unusual_firework_orange_yellow_parent = {Vector(-20,-20,-25), Vector(20,20,50)},
		unusual_firework_pgb_parent = {Vector(-20,-20,-25), Vector(20,20,50)},
		unusual_firework_purple_yellow_parent = {Vector(-20,-20,-25), Vector(20,20,50)},
		unusual_firework_rainbow_parent = {Vector(-20,-20,-25), Vector(20,20,40)},
		unusual_firework_wgb_parent = {Vector(-20,-20,-25), Vector(20,20,50)},
		unusual_lanterns_teamcolor_red = {Vector(-16,-16,-16),Vector(16,16,50)},
		unusual_lanterns_teamcolor_blue = {Vector(-16,-16,-16),Vector(16,16,50)},
		unusual_lanterns_green_parent = {Vector(-16,-16,-16),Vector(16,16,50)},
		unusual_lanterns_yellow_parent = {Vector(-16,-16,-16),Vector(16,16,50)},
		unusual_coldcosmos_parent = {Vector(-8,-8,0), Vector(8,8,28)},
		unusual_helix_parent = {Vector(-12,-15,-8), Vector(12,9,20)},
		unusual_stardust_teamcolor_red = {Vector(-10,-10,-20),Vector(10,10,30)},
		unusual_stardust_teamcolor_blue = {Vector(-10,-10,-20),Vector(10,10,30)},
		unusual_stardust_green_parent = {Vector(-10,-10,-20),Vector(10,10,30)},
		unusual_stardust_orange_parent = {Vector(-10,-10,-20),Vector(10,10,30)},
		unusual_stardust_white_parent = {Vector(-10,-10,-20),Vector(10,10,30)},
		unusual_erupt_alien_parent = {Vector(-11,-11,-11),Vector(11,11,30)},
		unusual_erupt_daydream_parent = {Vector(-11,-11,-11),Vector(11,11,30)},
		unusual_erupt_volcan_parent = {Vector(-11,-11,-11),Vector(11,11,30)},
		unusual_supernova_parent = {Vector(-11,-11,0), Vector(11,11,30)},
		//halloween 2022
		unusual_hauntedforever_teamcolor_red = {Vector(-12.4,-21.4,-12.5), Vector(12.6,8.9,19.3)},
		unusual_hauntedforever_teamcolor_blue = {Vector(-12.4,-21.4,-12.5), Vector(12.6,8.9,19.3)},
		unusual_hauntedforever_green_parent = {Vector(-12.4,-21.4,-12.5), Vector(12.6,8.9,19.3)},
		unusual_hauntedforever_purple_parent = {Vector(-12.4,-21.4,-12.5), Vector(12.6,8.9,19.3)},
		unusual_moths_parent = {Vector(-16,-16,-34), Vector(16,16,25)},
		unusual_eyeboss_parent = {Vector(-13,-13,-15),Vector(13,13,23)},
		//smissmas 2022
		unusual_sheetmusic_gold_parent = {Vector(-10,-10,-6), Vector(10,10,18)},
		unusual_sheetmusic_green_parent = {Vector(-10,-10,-6), Vector(10,10,18)},
		unusual_sheetmusic_silver_parent = {Vector(-10,-10,-6), Vector(10,10,18)},
		unusual_constellation_teamcolor_red = {Vector(-12,-12,-2), Vector(12,12,32)},
		unusual_constellation_teamcolor_blue = {Vector(-12,-12,-2), Vector(12,12,32)},
		unusual_constellation_green_parent = {Vector(-12,-12,-2), Vector(12,12,32)},
		unusual_blood_snow_parent = {Vector(-15,-15,-20), Vector(15,15,30)},
		unusual_aestheticneons_parent = {Vector(-10,-10,0), Vector(10,10,28)},
		//summer 2023
		unusual_hardcarry_teamcolor_red = {Vector(-12,-12,-10), Vector(12,12,24)},
		unusual_hardcarry_teamcolor_blue = {Vector(-12,-12,-10), Vector(12,12,24)},
		unusual_jellyfish_teamcolor_red = {Vector(-23,-23,0), Vector(23,23,35)},
		unusual_jellyfish_teamcolor_blue = {Vector(-23,-23,0), Vector(23,23,35)},
		unusual_jellyfish_green_parent = {Vector(-23,-23,0), Vector(23,23,35)},
		unusual_jellyfish_purple_parent = {Vector(-23,-23,0), Vector(23,23,35)},
		unusual_shootingstar_green_parent = {Vector(-12,-12,-6), Vector(12,12,24)},
		unusual_shootingstar_purple_parent = {Vector(-12,-12,-6), Vector(12,12,24)},
		unusual_shootingstar_orange_parent = {Vector(-12,-12,-6), Vector(12,12,24)},
		unusual_sakura_smokebomb = {Vector(-14,-14,-15), Vector(14,14,22)},
		unusual_australian_riches = {Vector(-15,-15,-15), Vector(15,15,25)},
		unusual_buble_parent = {Vector(-10,-10,-5), Vector(10,10,22.5)},
		unusual_fireflies = {Vector(-14,-14,-14), Vector(14,14,22)},
		unusual_mountainhalo_parent = {Vector(-10,-10,-10), Vector(10,10,25)},
		//halloween 2023
		unusual_risingstar_green_parent = {Vector(-15,-15,-5), Vector(15,15,20)},
		unusual_risingstar_purple_parent = {Vector(-15,-15,-5), Vector(15,15,20)},
		unusual_devilish_teamcolor_red = {Vector(-10,-14,-10), Vector(10,10,18)},
		unusual_devilish_teamcolor_blue = {Vector(-10,-14,-10), Vector(10,10,18)},
		unusual_devilish_green_parent = {Vector(-10,-14,-10), Vector(10,10,18)},
		unusual_devilish_purple_parent = {Vector(-10,-14,-10), Vector(10,10,18)},
		unusual_skullhead_parent = {Vector(-15,-15,0), Vector(15,15,25)},
		unusual_spiderweb_parent = {Vector(-11,-11,0), Vector(11,11,20)},
		unusual_deepsmoke_parent_g = {Vector(-14,-14,-10), Vector(14,14,35)},
		unusual_deepsmoke_parent_o = {Vector(-14,-14,-10), Vector(14,14,35)},
		unusual_deepsmoke_parent_p = {Vector(-14,-14,-10), Vector(14,14,35)},
		//smissmas 2023
		unusual_icearrow_teamcolor_red = {Vector(-10,-5,-15), Vector(17,5,20)},
		unusual_icearrow_teamcolor_blue = {Vector(-10,-5,-15), Vector(17,5,20)},
		unusual_goldarrow_parent = {Vector(-10,-5,-15), Vector(17,5,20)},
		unusual_aestheticsigns_teamcolor_red = {Vector(-10,-10,0), Vector(10,10,30)},
		unusual_aestheticsigns_teamcolor_blue = {Vector(-10,-10,0), Vector(10,10,30)},
		unusual_aestheticsigns_mannco_parent = {Vector(-10,-10,0), Vector(10,10,30)},
		unusual_frosty_flavours_teamcolor_red = {Vector(-15,-15,-10), Vector(15,15,35)},
		unusual_frosty_flavours_teamcolor_blue = {Vector(-15,-15,-10), Vector(15,15,35)},
		unusual_frosty_mint_glow_parent = {Vector(-15,-15,-10), Vector(15,15,40)},
		unusual_northstar_teamcolor_red = {Vector(-10,-10,-2), Vector(10,10,30)},
		unusual_northstar_teamcolor_blue = {Vector(-10,-10,-2), Vector(10,10,30)},
		unusual_northstar_parent_purple = {Vector(-10,-10,-2), Vector(10,10,30)},
		unusual_orbitingstar_parent = {Vector(-13,-13,0), Vector(13,13,20)},
		unusual_firefly_teamcolor_red = {Vector(-15,-15,0), Vector(15,15,44)},
		unusual_firefly_teamcolor_blue = {Vector(-15,-15,0), Vector(15,15,44)},
		unusual_firefly_purple_parent = {Vector(-15,-15,0), Vector(15,15,44)},
		unusual_firefly_green_parent = {Vector(-15,-15,0), Vector(15,15,44)},
		//summer 2024
		unusual_corrodedknight_teamcolor_red = {Vector(-6,-13,-9), Vector(8,2,2)},
		unusual_corrodedknight_teamcolor_blue = {Vector(-6,-13,-9), Vector(8,2,2)},
		unusual_corrodedknight_parent_silver = {Vector(-6,-13,-9), Vector(8,2,2)},
		unusual_corrodedknight_parent_golden = {Vector(-6,-13,-9), Vector(8,2,2)},
		unusual_poseidon_teamcolor_red = {Vector(-10,-13,-10), Vector(10,7,10)},
		unusual_poseidon_teamcolor_blue = {Vector(-10,-13,-10), Vector(10,7,10)},
		unusual_poseidon_parent_green = {Vector(-10,-13,-10), Vector(10,7,10)},
		unusual_poseidon_parent_purple = {Vector(-10,-13,-10), Vector(10,7,10)},
		unusual_cubancigar_parent = {Vector(-12,-12,-11), Vector(12,12,33)},
		unusual_mohawk_teamcolor_red = {Vector(-9,-12,-0), Vector(10,8,15)},
		unusual_mohawk_teamcolor_blue = {Vector(-9,-12,-0), Vector(10,8,15)},
		unusual_mohawk_parent_green = {Vector(-9,-12,-0), Vector(10,8,15)},
		unusual_mohawk_parent_purple = {Vector(-9,-12,-0), Vector(10,8,15)},
		unusual_rare_shine_glow_parent = {Vector(-12,-12,-6), Vector(12,12,22)},
		unusual_horstars_teamcolor_red = {Vector(-11,-11,-11), Vector(11,11,11)},
		unusual_horstars_teamcolor_blue = {Vector(-11,-11,-11), Vector(11,11,11)},
		unusual_electric_parent_white = {Vector(-12,-12,-11), Vector(12,12,13)},
		unusual_electric_parent_gold = {Vector(-12,-12,-11), Vector(12,12,13)},
		unusual_butterflyhead_teamcolor_red = {Vector(-12,-12,-12), Vector(12,12,24)},
		unusual_butterflyhead_teamcolor_blue = {Vector(-12,-12,-12), Vector(12,12,24)},
		unusual_hippieaura_parent = {Vector(-10,-10,-4), Vector(10,10,16)},
		unusual_butterfly_parent = {Vector(-14,-14,-10), Vector(14,14,20)},
		//halloween 2024
		unusual_spectral_fire_parent = {Vector(-9,-9,-0), Vector(9,9,18)},
		unusual_galactic_fire_parent = {Vector(-9,-9,-0), Vector(9,9,18)},
		unusual_frank_green_parent = {Vector(-10,-10,-10), Vector(10,0,10)},
		unusual_frank_purple_parent = {Vector(-10,-10,-10), Vector(10,0,10)},
		unusual_frank_yellow_parent = {Vector(-10,-10,-10), Vector(10,0,10)},
		unusual_skullsmoke_green_parent = {Vector(-12,-12,0), Vector(12,12,20)},
		unusual_skullsmoke_purple_parent = {Vector(-12,-12,0), Vector(12,12,20)},
		unusual_pigeons_green_parent = {Vector(-10,-10,0), Vector(10,10,20)},
		unusual_pigeons_purple_parent = {Vector(-10,-10,0), Vector(10,10,20)},
		unusual_pigeons_white_parent = {Vector(-10,-10,0), Vector(10,10,20)},
		unusual_stove_teamcolor_red = {Vector(-10,-15,0), Vector(10,10,10)},
		unusual_stove_teamcolor_blue = {Vector(-10,-15,0), Vector(10,10,10)},
		unusual_electricfire_teamcolor_red = {Vector(-11,-11,-5), Vector(11,11,20)},
		unusual_electricfire_teamcolor_blue = {Vector(-11,-11,-5), Vector(11,11,20)},
		//smissmas 2024
		unusual_sizzling_parent = {Vector(-11,-11,-12), Vector(11,11,30)},
		unusual_icrown_teamcolor_red = {Vector(-15,-15,-22.5), Vector(15,15,30)},
		unusual_icrown_teamcolor_blue = {Vector(-15,-15,-22.5), Vector(15,15,30)},
		unusual_icrown_parent_purple = {Vector(-15,-15,-22.5), Vector(15,15,30)},
		unusual_timeghosts_parent = {Vector(-15,-15,0), Vector(15,15,16)},
		unusual_aurora_parent = {Vector(-10,-10,0), Vector(10,10,25)},
		unusual_bokehsparkle_parent = {Vector(-13,-13,0), Vector(13,13,12)},
		unusual_playful_purple_parent = {Vector(-12,-12,-8), Vector(12,12,32)},
		unusual_playful_yellow_parent = {Vector(-12,-12,-8), Vector(12,12,32)},
		//summer 2025
		unusual_drunk_parent = {Vector(-12,-12,-11), Vector(12,12,22)},
		unusual_excalibur_teamcolor_red = {Vector(-12,-12,-12), Vector(12,12,15)},
		unusual_excalibur_teamcolor_blue = {Vector(-12,-12,-12), Vector(12,12,15)},
		unusual_excalibur_parent_purple = {Vector(-12,-12,-12), Vector(12,12,15)},
		unusual_uber_teamcolor_red = {Vector(-12,-12,-2), Vector(12,12,12)},
		unusual_uber_teamcolor_blue = {Vector(-12,-12,-2), Vector(12,12,12)},
		unusual_uber_gold_parent = {Vector(-12,-12,-2), Vector(12,12,12)},
		unusual_orbitingbullet_parent = {Vector(-15.5,-15.5,0), Vector(15.5,15.5,0)},
		unusual_typhoon_parent = {Vector(-8,-8,-4), Vector(8,8,26)},
		//halloween 2025
		unusual_ocean_swirl_teamcolor_red = {Vector(-10.5,-10.5,2.5), Vector(10.5,10.5,22.5)},
		unusual_ocean_swirl_teamcolor_blue = {Vector(-10.5,-10.5,2.5), Vector(10.5,10.5,22.5)},
		unusual_ocean_swirl_green_parent = {Vector(-10.5,-10.5,2.5), Vector(10.5,10.5,22.5)},
		unusual_candle_teamcolor_red = {Vector(-10,-10,0), Vector(10,10,25)},
		unusual_candle_teamcolor_blue = {Vector(-10,-10,0), Vector(10,10,25)},
		unusual_deadlyaroma_teamcolor_red = {Vector(-12,-12,0), Vector(12,12,26)},
		unusual_deadlyaroma_teamcolor_blue = {Vector(-12,-12,0), Vector(12,12,26)},
		unusual_deadlyaroma_green_parent = {Vector(-12,-12,0), Vector(12,12,26)},
		unusual_conductor_teamc_teamcolor_red = {Vector(-10,-10,0), Vector(10,10,12)},
		unusual_conductor_teamc_teamcolor_blue = {Vector(-10,-10,0), Vector(10,10,12)},
		unusual_sandy_parent = {Vector(-4,-4,-30), Vector(4,4,0)},
		//smissmas 2025
		unusual_ombre_parent_purple = {Vector(-11,-11,-10), Vector(11,11,30)},
		unusual_ombre_parent_teal = {Vector(-11,-11,-10), Vector(11,11,30)},
		unusual_ombre_parent_spectrum = {Vector(-11,-11,-10), Vector(11,11,30)},
		unusual_calmsnowfall_parent = {Vector(-9,-9,0), Vector(9,9,13)},
		unusual_team_recognition_teamcolor_red = {Vector(-14,-14,-8), Vector(14,14,18)},
		unusual_team_recognition_teamcolor_blue = {Vector(-14,-14,-8), Vector(14,14,18)},
		unusual_classicfortress_teamcolor_red = {Vector(-10,-10,0), Vector(10,10,29)},
		unusual_classicfortress_teamcolor_blue = {Vector(-10,-10,0), Vector(10,10,29)},
		unusual_classicfortress_tflogo_parent = {Vector(-10,-10,0), Vector(10,10,29)},
		unusual_growing_flake_parent_white = {Vector(-13,-13,0), Vector(13,13,26)},
		unusual_growing_flake_parent_purple = {Vector(-13,-13,0), Vector(13,13,26)},
		unusual_growing_flake_parent_twilight = {Vector(-13,-13,0), Vector(13,13,26)},
		unusual_cryogenic_parent = {Vector(-12,-12,-6), Vector(12,12,14)},
		//summer 2026
		unusual_aurora_purple_parent = {Vector(-8,-8,4), Vector(8,8,30)},
		unusual_aurora_teal_parent = {Vector(-8,-8,4), Vector(8,8,30)},
		unusual_aurora_green_parent = {Vector(-8,-8,4), Vector(8,8,30)},
		unusual_vinethorn_teamcolor_red = {Vector(-7,-7,0), Vector(7,7,8)},
		unusual_vinethorn_teamcolor_blue = {Vector(-7,-7,0), Vector(7,7,8)},
		unusual_spaceorbit_parent = {Vector(-10,-16,-10), Vector(10,0,17)},
		unusual_butterfly_teamcolor_red = {Vector(-20,-20,-12), Vector(20,20,30)},
		unusual_butterfly_teamcolor_blue = {Vector(-20,-20,-12), Vector(20,20,30)},
		unusual_butterfly_parent_purple = {Vector(-20,-20,-12), Vector(20,20,30)},
	}
	local DrawItemModels, DoItemModelCamera, CreateItemIconModelPanel

	
	CreateClientConVar("cl_tf2itembrowser_advbone", "0", true, false, "Use advanced bonemerge to attach items", 0, 1)

	list.Set("DesktopWindows", "TF2ItemBrowser", {
		title		= "TF2 Items", //"TF2 Item Browser" is just ever-so-slighly too long to fit in the desktop icon's label, hrmph
		icon		= "games/16/tf.png", //TODO: temp, make one that's the correct size later
		width		= 924,
		height		= 691,
		onewindow	= true,
		init		= function(widgetIcon, window)			

			local right_holder = vgui.Create("DPanel", window)
			right_holder.Paint = function() end
			window.Right = right_holder
			local right_scroll = TFStyleVGUI("DScrollPanel", right_holder)
			right_holder:Dock(FILL)
			right_scroll:Dock(FILL)

			local iconlist = vgui.Create("DPanel", right_scroll) //(note: this was a DIconLayout before, but since we already know the size of every icon, it's a lot faster to just use simple math to set the list height and icon locations, instead of all the performance-heavy size calculations used by DIconLayout)
			iconlist.Paint = function() end
			iconlist:Dock(FILL)

			local old_OnChildAdded = right_scroll.OnChildAdded
			right_scroll.OnChildAdded = nil //don't dock the loading icon inside the scroll panel, just place it on top of it
			local iconlist_loading = vgui.Create("DPanel", right_scroll)
			iconlist_loading:Dock(FILL)
			//iconlist_loading:SetZPos(10) //this needs to render above the iconlist
			iconlist_loading:SetMouseInputEnabled(false)
			function iconlist_loading:Paint(w, h)
				local load_text, load_font, load_progress
				if TF2ItemBrowser_RequestCustomItems then
					load_text = "Retrieving custom items..."
					load_progress = 0
				elseif window.icons_to_add_showloader then
					load_text = tostring(window.icons_to_add_key-1) .. " / " .. tostring(#window.icons_to_add)
					load_progress = (window.icons_to_add_key-1)/#window.icons_to_add
				end
				if !load_text then return end
				surface.SetFont("TF2ItemBrowser_ItemDesc")
				local load_w, _ = surface.GetTextSize(load_text)
				load_w = math.max(load_w, 120)

				local w, h = right_scroll:GetSize()
				surface.SetDrawColor(gui_colors.TanDarker.r, gui_colors.TanDarker.g, gui_colors.TanDarker.b, 192)
				surface.DrawRect(0,0,w,h)

				local mid_w, mid_h = (w-right_scroll.VBar:GetWide()-item_icon_sizes[icon_size].gap_w)/2, h/2
				local x = mid_h-62.5
				GrayDialogBorder(mid_w-((load_w+46)/2), x, load_w+46, 125)
				surface.SetMaterial(spinner)
				x = x-6
				surface.DrawTexturedRect(mid_w-50, x, 100, 100)

				surface.SetDrawColor(gui_colors.TanDark)
				x = x+100-11
				surface.DrawRect(mid_w-(load_w/2), x, load_w, 4)
				surface.SetDrawColor(gui_colors.LightRed)
				surface.DrawRect(mid_w-(load_w/2), x, load_w*load_progress, 4)
				x = x+15
				draw.SimpleText(load_text, "TF2ItemBrowser_ItemDesc", mid_w, x, gui_colors.LightRed, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			right_scroll.OnChildAdded = old_OnChildAdded


			local left_holder = vgui.Create("Panel", window)
			left_holder:DockMargin(0,0,8,0) //space for the DHorizonalDivider's control to fit in
			left_holder:Dock(LEFT)
			local left_scroll = TFStyleVGUI("DScrollPanel", left_holder)
			left_scroll:Dock(FILL)

			local filters = vgui.Create("DPanel", left_scroll)
			filters:Dock(TOP)
			filters:DockPadding(16,16,16,16)
			window.filters = filters
			function filters:Paint(w,h)
				draw.RoundedBox(12, 0,0,w,h, gui_colors._options)
			end

			local divider = vgui.Create("DHorizontalDivider", window)
			divider:Dock(FILL)
			divider:SetLeft(left_holder)
			divider:SetRight(right_holder)
			divider:SetDividerWidth(8)
			//divider:SetLeftMin(64)
			divider:SetRightMin(popup_w) //make sure the right side is always wide enough to fit an item popup
			divider:SetLeftWidth(230)


			window:SetTitle("TF2 Item Browser")
			AddTFStyleToVGUI(window)
			TF2ItemBrowser = window
			window:SetSizable(true)
			local p1, _, p2, _ = window:GetDockPadding()
			local p3, _, p4, _ = left_holder:GetDockPadding()
			window:SetMinWidth(p1 + p2 + p3 + p4 + right_scroll.VBar:GetWide() + right_scroll:GetWide())


			local text_holder = vgui.Create("Panel", filters)
			text_holder:Dock(TOP)
			text_holder:DockMargin(-8,-8,-8,betweenitems)
			local text = vgui.Create("DLabel", text_holder)
			text:SetContentAlignment(7) //top left
			text:SetAutoStretchVertical(true)
			text:SetFont("TF2ItemBrowser_ItemName")
			text:SetColor(gui_colors.TanLight)
			text:SetText((GetTFLanguageString("#chat_filterbutton") or "Filters") .. ":")
			text:Dock(FILL)
			text_holder:SetTall(text:GetTall())
			local text = vgui.Create("DLabel", text_holder)
			text:SetContentAlignment(9) //top right
			text:SetAutoStretchVertical(true)
			text:SetFont("TF2ItemBrowser_ItemName")
			text:SetColor(gui_colors.TanDark)
			text:SetText("")
			text:Dock(FILL)
			window.ItemCountText = text

			local search = TFStyleVGUI("DTextEntry", filters)
			search:Dock(TOP)
			search:DockMargin(0,0,0,betweencategories)
			search:SetPlaceholderText("#spawnmenu.search")
			filters.search = search
			search:SetUpdateOnType(true)
			search.OnValueChange = function()
				timer.Create("TF2ItemBrowser_SearchDelay", 0.5, 1, function()
					if IsValid(window) then window.RebuildIconList() end
				end)
			end

			local function AddDropdownFilter(label, populatefunc, select_extras)
				local combo = TFStyleVGUI("DComboBox", filters)
				local pnl = AddTFLabelToVGUI(combo, label)
				pnl:Dock(TOP)
				pnl:DockMargin(0,0,0,betweenitems)
				combo:SetSortItems(false)
				populatefunc(combo)
				function combo.OnSelect(_, index, value, data)
					if select_extras then select_extras() end
					window.RebuildIconList()
				end
				return combo
			end

			filters.class = AddDropdownFilter(GetTFLanguageString("#TF_Tag_Category_Class") or "Class", function(self)
				for k, v in ipairs (classes) do //add all classes in order
					self:AddChoice(GetTFLanguageString(v.langstr) or string.NiceName(v.longname), k, k == 1)
					if k == 1 or k == 10 then self:AddSpacer() end
				end
			end, function() 
				filters.equip_region:RebuildControls()
				filters.item_set:RebuildControls()
			end)

			filters.item_type = AddDropdownFilter(GetTFLanguageString("#TF_ImportFile_TypeLabel") or "Item Type", function(self) 
				for k, v in ipairs ({
					{k = str_any,								v = "(any)"}, 
					{k = GetTFLanguageString("#TF_SteamWorkshop_Tag_Weapon") or "Weapon",	v = "weapon"}, 
					{k = GetTFLanguageString("#LoadoutSlot_Misc") or "Cosmetic",		v = "cosmetic"}, 
					--[[{k = GetTFLanguageString("#TF_SteamWorkshop_Tag_Taunt") or "Taunt",	v = "taunt"},]] 
					{k = GetTFLanguageString("#AbuseReport_TypeOther") or "Other",		v = "other"}, //using this localization string for "Other" items is a stretch but it's the best we've got
				}) do
					self:AddChoice(v.k, v.v, k == 1)
					if k == 1 then self:AddSpacer() end
				end
			end)

			local equip_regions_populate = function(self)
				local _, old_choice = self:GetSelected()
				old_choice = old_choice or "(any)"
				self.IsRebuilding = true
				self:Clear()
				self:AddChoice(str_any, "(any)", old_choice == "(any)")
				for classid, class in ipairs (classes) do //add class-based equip regions in class order
					//If we have a class selected, filter out equip regions for other classes
					local _, selected_classid = filters.class:GetSelected()
					if selected_classid == 1 or classid == 1 or selected_classid == classid then
						local added_spacer = false
						for k, v in ipairs (TF2Items.equip_regions_list[classid]) do
							if !added_spacer then 
								self:AddSpacer()
								added_spacer = true
							end
							self:AddChoice(string.NiceName(v), v, old_choice == v)
						end
					end
				end
				//if we had a class-specific region selected, and then switched to a class that doesn't have it, revert to "(any)"
				local _, check = self:GetSelected()
				if check == nil then self:ChooseOptionID(1) end
				self.IsRebuilding = nil
			end
			filters.equip_region = AddDropdownFilter(GetTFLanguageString("#TF_ImportFile_EquipRegionLabel") or "Equip Region", equip_regions_populate)
			filters.equip_region.RebuildControls = equip_regions_populate //make this func externally accessible so we can rebuild it when picking a new class

			local item_sets_populate = function(self)
				local _, old_choice = self:GetSelected()
				old_choice = old_choice or "(any)"
				self.IsRebuilding = true
				self:Clear()
				self:AddChoice(str_any, "(any)", old_choice == "(any)")
				local submenus = {}
				//If we have a class selected, only show sets containing items for that class
				local _, selected_classid = filters.class:GetSelected()
				local added_spacer = false
				for _, v in ipairs (sets) do
					if selected_classid == 1 or TF2Items.item_sets[v]._classes[selected_classid] then
						if !added_spacer then self:AddSpacer() added_spacer = true end
						local k = GetTFLanguageString(TF2Items.item_sets[v].name) or v
						local cat = TF2Items.item_sets[v]._cat //item sets are further categorized by class because there's so many of them
						local id = self:AddChoice(k, v, old_choice == v)
						submenus.sets = submenus.sets or {}
						submenus.sets[cat] = submenus.sets[cat] or {}
						table.insert(submenus.sets[cat], {name = k, id = id})
					end
				end
				added_spacer = false
				for _, v in ipairs (collections) do
					if selected_classid == 1 or TF2Items.item_collections[v]._classes[selected_classid] then
						if !added_spacer then self:AddSpacer() added_spacer = true end
						local k = GetTFLanguageString(TF2Items.item_collections[v].name) or v
						local id = self:AddChoice(k, v, old_choice == v)
						submenus.collections = submenus.collections or {}
						table.insert(submenus.collections, {name = k, id = id})
					end
				end
				//Add custom dropdown with submenus, instead of dumping all the sets and collections into one huge list
				function self:OpenMenu()
					self:CloseMenu()
					self.Menu = DermaMenu(false)

					self.Menu:AddOption(self.Choices[1], function() self:ChooseOption(self.Choices[1], 1) end)

					local sel = self:GetSelectedID()
					local done_spacer
					if submenus.sets then
						if !done_spacer then self.Menu:AddSpacer() done_spacer = true end
						local submenu = self.Menu:AddSubMenu("Sets")
						local is_first = true
						for _, cat in SortedPairs (submenus.sets) do
							local done_cat_spacer = is_first
							for _, tab in ipairs (cat) do
								is_first = false
								if !done_cat_spacer then submenu:AddSpacer() done_cat_spacer = true end
								local opt = submenu:AddOption(tab.name, function() self:ChooseOption(tab.name, tab.id) end)				
								if tab.id == sel then
									opt:SetChecked(true)
									submenu:ScrollToChild(opt)
								end
							end
						end
					end
					if submenus.collections then
						if !done_spacer then self.Menu:AddSpacer() done_spacer = true end
						local submenu = self.Menu:AddSubMenu(string.NiceName(string.lower(GetTFLanguageString("#Collections") or "COLLECTIONS")))
						for _, tab in ipairs (submenus.collections) do
							local opt = submenu:AddOption(tab.name, function() self:ChooseOption(tab.name, tab.id) end)
							if tab.id == sel then
								opt:SetChecked(true)
								submenu:ScrollToChild(opt)
							end
						end
					end

					local x, y = self:LocalToScreen(0, self:GetTall())
					self.Menu:SetMinimumWidth(self:GetWide())
					self.Menu:Open(x, y, false, self)
					self:OnMenuOpened(self.Menu)
				end
				//if we had a class-specific set selected, and then switched to a class that doesn't have it, revert to "(any)"
				local _, check = self:GetSelected()
				if check == nil then self:ChooseOptionID(1) end
				self.IsRebuilding = nil
			end
			filters.item_set = AddDropdownFilter("Set/" .. (GetTFLanguageString("#TF_Tag_Category_Collection") or "Collection"), item_sets_populate) //no tf localization string for "Set" or "Item Set" or the like
			filters.item_set:GetParent():DockMargin(0,0,0,betweencategories)
			filters.item_set.RebuildControls = item_sets_populate //make this func externally accessible so we can rebuild it when picking a new class

			local function AddIncludeExcludeFilter(label) //variant of checkboxes with both (+ (must include)) and (- (must exclude)) options
				local self = vgui.Create("DPanel", filters)
				self:SetTall(20)
				self.Button1 = TFStyleVGUI("DCheckBox", self)
				self.Button1.OnChange = function(_, val) self:OnChange(val, self.Button1) end
				self.Button2 = TFStyleVGUI("DCheckBox", self)
				self.Button2.OnChange = function(_, val) self:OnChange(val, self.Button2) end
				self.Button2.NegativeCheck = true //use different visuals
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
				self.Label:SetColor(gui_colors.Yellow) //same color and font as TFStyleVGUI DCheckBoxLabel
				self.Label:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
				self.Paint = function() end
				function self:PerformLayout()
					self.Button1:SetSize(20, 20)
					self.Button1:SetPos(0, math.floor((self:GetTall() - self.Button1:GetTall()) / 2))

					self.Button2:SetSize(20, 20)
					self.Button2:SetPos(self.Button1:GetWide() + 2, math.floor((self:GetTall() - self.Button2:GetTall()) / 2))

					self.Label:SizeToContents()
					self.Label:SetPos(self.Button1:GetWide() + 2 + self.Button2:GetWide() + 6, math.floor((self:GetTall() - self.Label:GetTall()) / 2))
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

			//there's no good localization strings for any of these, unfortunately
			filters.conflicting = AddIncludeExcludeFilter("Conflicts with equipped") //should this be grayed out or something when there's no parent selected to equip items to?
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

			local button = TFStyleVGUI("DButton", filters.custom)
			//filters.custom:SetTall(button:GetTall()) //we can get away with making this smaller because the plus in this font is so small
			button:SetText("+")
			//button:SizeToContentsX(20) //^
			button:SizeToContentsX(10) 
			button:Dock(RIGHT)
			button:DockMargin(0,0,0,0)
			button.DoClick = function()
				window:OpenCustomItemEditor()
			end

			filters:InvalidateLayout(true)
			filters:SizeToChildren(false,true)
			timer.Simple(0.1,function()
				filters:InvalidateLayout(true)
				filters:SizeToChildren(false,true)
			end)


			window.RebuildIconList = function()
				if TF2ItemBrowser_RequestCustomItems or filters.equip_region.IsRebuilding or filters.item_set.IsRebuilding then return end

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
					_custom_weapon = "weapon",
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
						f = string.Explode(" ", f:lower()) //allow searching with multiple search terms
					end
				end
				for k, v in pairs (TF2Items.items) do
					//this filter is on by default and catches >75% of items, so check this first
					if DoIncludeExcludeFilter(filters.tm:GetValue(), v._tm) then continue end

					if f then
						if !v._searchstr then
							//Search by display name, internal name, item type, set/collection, and more
							local str = (GetTFLanguageString(v.item_name) or v.item_name):lower() .. " " .. v.name:lower()
							if v.item_type_name then
								str = str .. " " .. (GetTFLanguageString(v.item_type_name) or ""):lower()
							end
							//if v.item_description then
							//	//this can add irrelevant nonsense sometimes, but can also catch associated words that aren't in any other text. is this worth it?
							//	str = str .. " " .. (GetTFLanguageString(v.item_description) or ""):lower()
							//end
							if v._item_set then
								str = str .. " " .. (GetTFLanguageString(TF2Items.item_sets[v._item_set].name) or v._item_set):lower()
							end
							if v._item_collection then
								str = str .. " " .. (GetTFLanguageString(TF2Items.item_collections[v._item_collection].name) or v._item_collection):lower()
							end
							//Add all model paths to the search string so we can search those too
							local mdls = {}
							for class, _ in pairs (v.used_by_classes) do
								str = str .. " " .. class
								for _, mdl in pairs (GetItemModelVisuals({id = k, class = class_longname_to_id[class], style = 0}).models) do
									if !istable(mdl) then //the only model subtables are attached_models and attached_models_festive, which don't contain anything useful for searches, so skip those
										mdls[mdl] = true
										//mdls[string.Replace(mdl, class, "")] = true //don't include class names in model paths because that clutters up searches for class names with irrelevant multi-class items; this still doesn't work very well because of class-specific equip regions, some internal names, and class-specific model paths with "demo" instead of "demoman", so give up and let players search for class by typing the name just like they can with equip regions
									end
								end
							end
							for mdl, _ in pairs (mdls) do
								str = str .. " " .. string.StripExtension(string.GetFileFromFilename(mdl))
							end
							//And equip regions, so players can search something like "beard" and it works intuitively
							if v.equip_regions then
								for e, _ in pairs (v.equip_regions) do
									str = str .. " " .. e
								end
							end
							v._searchstr = str
						end

						local found
						for k2, v2 in ipairs (f) do
							if !v._searchstr:find(v2, nil, true) then
								break
							elseif k2 == #f then //if we found a match for ALL the search terms, then add it to the results
								found = true
							end
						end
						if !found then continue end
					end

					if filters.class:GetSelectedID() != 1 then
						local _, f = filters.class:GetSelected()
						if !v.used_by_classes[classes[f].longname] then continue end
					end

					if filters.item_type:GetSelectedID() != 1 then
						local _, f = filters.item_type:GetSelected()
						if (f == "other" and v.item_slot and item_slot_types[v.item_slot]) 
						or (f != "other" and (!v.item_slot or item_slot_types[v.item_slot] != f)) then continue end
					end

					if filters.equip_region:GetSelectedID() != 1 then
						local _, f = filters.equip_region:GetSelected()
						if !v.equip_regions or !v.equip_regions[f] then continue end
					end

					if filters.item_set:GetSelectedID() != 1 then
						local _, f = filters.item_set:GetSelected()
						if v._item_set != f and v._item_collection != f then continue end
					end

					if DoIncludeExcludeFilter(filters.conflicting:GetValue(), window:GetItemHasConflict(k))
					or DoIncludeExcludeFilter(filters.multi_class:GetValue(), table.Count(v.used_by_classes) > 1)
					or DoIncludeExcludeFilter(filters.holiday:GetValue(), v.holiday_restriction)
					or DoIncludeExcludeFilter(filters.paint:GetValue(), v.capabilities and v.capabilities.paintable == 1)
					or DoIncludeExcludeFilter(filters.warpaint:GetValue(), v._paintkit and WP.Weapons.IsSupported(v.model_player))
					or DoIncludeExcludeFilter(filters.custom:GetValue(), isstring(k)) //custom items use id strings, while normal items use id numbers
					then continue end

					table.insert(window.icons_to_add, k)
				end
				//If there's enough icons to add that creating them will cause a substantial FPS drop (i.e. filters are set to 
				//allow tournament medals), then display a loading progress bar so that the player can tell what's going on.
				window.icons_to_add_showloader = (#window.icons_to_add >= 4000)
				//Clear the icon list, and resize it to the height of the new list
				iconlist:Clear()
				local columns, wide = 0, iconlist:GetWide()
				while true do
					if columns > 0 then wide = wide - item_icon_sizes[icon_size].gap_w end
					wide = wide - item_icon_sizes[icon_size].w
					if wide >= 0 then
						columns = columns + 1
					else
						break
					end
				end
				iconlist.columns = columns
				local rows = math.floor((#window.icons_to_add-1)/columns)+1
				iconlist:SetHeight((rows*item_icon_sizes[icon_size].h) + ((rows-1)*item_icon_sizes[icon_size].gap_h))
				//Update scrollbar; scroll back to the top, and prevent scrolling or clicking on list items if there's a loading bar
				right_scroll:InvalidateLayout()
				right_scroll.VBar:SetScroll(0)
				right_scroll:SetMouseInputEnabled(!window.icons_to_add_showloader)
				//if #window.icons_to_add != 1 then
					//window.ItemCountText:SetText("(" .. tostring(#window.icons_to_add) .. " items)")
					window.ItemCountText:SetText("(" .. string.Replace(GetTFLanguageString("#Store_CartItems") or "%s1 Items", "%s1", tostring(#window.icons_to_add)) .. ")")
				//else
				//	window.ItemCountText:SetText("(" .. tostring(#window.icons_to_add) .. " item)")
				//end
			end
			function iconlist:PerformLayout(w, h)
				//Rebuild the iconlist if resizing it changed the number of columns
				local columns, wide = 0, w
				while true do
					if columns > 0 then wide = wide - item_icon_sizes[icon_size].gap_w end
					wide = wide - item_icon_sizes[icon_size].w
					if wide >= 0 then
						columns = columns + 1
					else
						break
					end
				end
				if columns != iconlist.columns then
					window.RebuildIconList()
				end
			end
			//window.RebuildIconList() gets called automatically by the initial iconlist:PerformLayout() above


			local old_Think = window.Think
			window.ImageQueue = {}
			window.IconRenderQueue = {}
			//this one is global so it carries over between windows
			TF2ItemBrowser_ImageQueuedBefore = TF2ItemBrowser_ImageQueuedBefore or {}
			local iconsperframe = 100
			function window:Think(...)
				if TF2ItemBrowser_RequestCustomItems then
					net.Start("TF2ItemBrowser_CustomItems_GetFromSv", true)
					net.SendToServer()
				end
				if self.icons_to_add and self.icons_to_add_key then
					for k = self.icons_to_add_key, self.icons_to_add_key + iconsperframe - 1 do
						local v = self.icons_to_add[k]
						if v then
							local item = iconlist:Add("TF2ItemIcon")
							local col = (k-1)%iconlist.columns
							local row = math.floor((k-1)/iconlist.columns)
							item:SetPos(col*(item_icon_sizes[icon_size].w+item_icon_sizes[icon_size].gap_w), row*(item_icon_sizes[icon_size].h+item_icon_sizes[icon_size].gap_h))
							item.data = v //this will be populated with the default data table for this item once the icon renders
							self.icons[v] = item
							item.item_conflict = self:GetItemHasConflict(v)
						else
							//We've gone through the whole table, so we're done here, get rid of it
							self.icons_to_add = nil
							self.icons_to_add_key = nil
							if self.icons_to_add_showloader then
								self.icons_to_add_showloader = nil
								//Allow the list to be scrolled and clicked on now that it's fully loaded
								right_scroll:SetMouseInputEnabled(true)
							end
							break
						end
					end
					//MsgN("self.icons_to_add_key = ", self.icons_to_add_key)
					if self.icons_to_add_key then self.icons_to_add_key = self.icons_to_add_key + iconsperframe end
				end
				for k, v in ipairs (self.ImageQueue) do
					table.remove(self.ImageQueue, k)
					if IsValid(v.pnl) then
						local _, y = self.Right:ScreenToLocal(v.pnl:LocalToScreen(0,0))
						if y > self.Right:GetTall() or (y+v.pnl:GetTall()) < 0 then
							//if the icon is offscreen, unqueue it and move on to the next one, without holding up the queue
							v.pnl.ImageToQueue = v.img //requeue it if the icon moves back onscreen
							continue
						end
						v.pnl.mat = Material(v.img .. ".vmt")
						if !TF2ItemBrowser_ImageQueuedBefore[v.img] then
							TF2ItemBrowser_ImageQueuedBefore[v.img] = true 
							break //only load one material per frame to prevent bad perf
						end
					end
				end
				if self.IconRenderQueue[1] then
					if self.IconRenderQueue[1]() then
						table.remove(self.IconRenderQueue, 1)
					end
				end
				//if our selected entity is deleted, then update the attached item list
				if self.atticons_holder and self.atticons_holder:IsVisible() and !IsValid(self:GetEntity()) then
					self:SetEntity(NULL)
				end
				old_Think(self, ...)
			end


			local atticons_holder = vgui.Create("DPanel", right_holder)
			//atticons_holder:DockPadding(0,0,0,0)
			atticons_holder:Dock(BOTTOM)
			window.atticons_holder = atticons_holder
			function atticons_holder:Paint(w,h)
				OutlinedGreyBox(-24,0,w+48,h) //no corners, just the top border
			end

			//This also has a scrollbar just in case some goofball wants to attach more than 10 items to one model
			local atticons = TFStyleVGUI("DHorizontalScroller", atticons_holder)
			atticons:Dock(BOTTOM)
			window.atticons = atticons
			atticons.icons = {}
			atticons.Label = vgui.Create("DLabel", atticons_holder)
			atticons.Label:SetContentAlignment(4) //middle left
			atticons.Label:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
			atticons.Label:SetColor(gui_colors.TanLight)
			atticons.Label:SetText("")
			atticons.Label:Dock(FILL)
			atticons.Label:DockMargin(0,4,0,0)
			function atticons:UpdateSize()
				atticons:SetHeight(item_icon_sizes[icon_size].h)
				atticons:SetOverlap(-item_icon_sizes[icon_size].gap_w)
				atticons_holder:SetTall(item_icon_sizes[icon_size].h + 24)
			end
			atticons:UpdateSize()

			function atticons:AddItem(ent, data, forceopen)
				local item
				if !IsValid(atticons.icons[ent]) then
				item = vgui.Create("TF2ItemIcon")
					atticons.icons[ent] = item
					item.entity = ent
					atticons:AddPanel(item)
				else item = atticons.icons[ent] end
				item:SetData(data)
				window:UpdateItemConflicts()
				
				if forceopen then
					atticons:ScrollToChild(item)
					item.OpenNextFrame = true
				end
			end

			local attopts = vgui.Create("DPanel", left_scroll)
			attopts:Dock(TOP)
			attopts:DockMargin(0,8,0,0)
			attopts:DockPadding(16,16,16,16)
			window.attopts = attopts
			function attopts:Paint(w,h)
				draw.RoundedBox(12, 0,0,w,h, gui_colors._options)
			end

			local text = vgui.Create("DLabel", attopts)
			text:SetContentAlignment(7) //top left
			text:SetAutoStretchVertical(true)
			text:SetFont("TF2ItemBrowser_ItemName")
			text:SetColor(gui_colors.TanLight)
			text:SetText(language.GetPhrase("spawnmenu.utilities.settings") .. ":")
			text:Dock(TOP)
			text:DockMargin(-8,-8,0,betweenitems)

			local buttons = vgui.Create("Panel", attopts)
			buttons:Dock(TOP)
			buttons:DockMargin(0,0,0,betweenitems)
			buttons:SetTall(26)
			local function ButtonPaint(self, w, h, icon, desired_value)
				//opacity values from TeamNavPanel in inspectionpanel_cosmetic.res
				if buttons.Value == desired_value or self:IsDown() then
					surface.SetDrawColor(255,255,255,255)
				elseif self:IsHovered() then
					surface.SetDrawColor(255,255,255,128)
				else
					surface.SetDrawColor(255,255,255,77)
				end
				surface.SetMaterial(icon)
				surface.DrawTexturedRect(0,0,w,w) //keep aspect ratio the same, cut off the blank bottom of the texture
			end
			buttons.Button1 = vgui.Create("DButton", buttons)
			function buttons.Button1.DoClick() buttons:SetValue(false) end
			function buttons.Button1:Paint(w,h) ButtonPaint(self,w,h,icon_red,false) end
			buttons.Button1:SetText("")
			AddTFButtonSounds(buttons.Button1)
			buttons.Button2 = vgui.Create("DButton", buttons)
			function buttons.Button2.DoClick() buttons:SetValue(true) end
			function buttons.Button2:Paint(w,h) ButtonPaint(self,w,h,icon_blu, true) end
			buttons.Button2:SetText("")
			AddTFButtonSounds(buttons.Button2)
			function buttons:PerformLayout()
				local w,h = self:GetSize()
				self.Button1:SetSize(42, h)
				self.Button1:SetPos((w/2)-4-42, 0)

				self.Button2:SetSize(42, h)
				self.Button2:SetPos((w/2)+4, 0)
			end
			buttons.SetValue = function(_, val)
				buttons.Value = val
				local ent = window:GetEntity()
				if IsValid(ent) then
					local skintoset
					if ent:GetSkin() % 2 != 0 then
						if !val then skintoset = ent:GetSkin()-1 end //don't change the skin if ent's skin got desynced
					else
						if val then skintoset = ent:GetSkin()+1 end
					end
					if skintoset != nil then
						window:DoInput("attach_par_skin", skintoset)
					end

					//also update EFFECT_JARATE team color
					local _, f = attopts.fx:GetSelected()
					window:DoInput("attach_par_fx", f)

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
			buttons.Value = false
			attopts.team = buttons

			local drop = AddDropdownFilter(GetTFLanguageString("#TF_ImportPreview_EffectLabel") or "Effect", function(self)
				self:AddChoice(str_none, EFFECT_NONE, true)
				self:AddChoice(GetTFLanguageString("#TF_ImportPreview_Effect1") or "Uber", EFFECT_UBER)
				self:AddChoice(GetTFLanguageString("#TF_ImportPreview_Effect2") or "Jarate", EFFECT_JARATE)
				self:AddChoice("Gold", EFFECT_GOLD) //no localization strings for these two, sad
				self:AddChoice("Ice", EFFECT_ICE)   //^
			end)
			drop:GetParent():SetParent(attopts)
			drop:GetParent():Dock(TOP)
			attopts.fx = drop
			function drop.OnSelect(_, index, value, data)
				local ent = window:GetEntity()
				if IsValid(ent) then
					if drop.IsUpdating then return end

					local skintoset
					local is_uber_skin = (math.ceil((ent:GetSkin()+1)/2) % 2) == 0
					if data != 1 and is_uber_skin then
						skintoset = ent:GetSkin() - 2
					elseif data == 1 and !is_uber_skin then
						skintoset = ent:GetSkin() + 2
					end
					if skintoset != nil then
						window:DoInput("attach_par_skin", skintoset)
					end
					
					window:DoInput("attach_par_fx", data)

					for ent, pnl in pairs (atticons.icons) do
						if !IsValid(pnl) or !IsValid(ent) then
							atticons.icons[ent] = nil 
						else
							if pnl.data.fx != data then
								pnl.data.fx = data
								TF2ItemBrowser:DoInput("attach_item_modify", ent, pnl.data)
							end
						end
					end
				end
				if IsValid(window.SpawnPanel) then
					window.SpawnPanel.Refresh()
				end
			end

			local drop = AddDropdownFilter("Attach with", function(self)
				local b = GetConVar("cl_tf2itembrowser_advbone"):GetBool()
				self:AddChoice("Easy Bonemerge", "0", !b)
				self:AddChoice("Adv. Bonemerge", "1", b)
			end)
			drop:GetParent():SetParent(attopts)
			drop:GetParent():Dock(TOP)
			function drop.OnSelect(_, index, value, data)
				LocalPlayer():ConCommand("cl_tf2itembrowser_advbone " .. data)
			end

			local check = TFStyleVGUI("DCheckBoxLabel", attopts)
			check:SetText("Small icons")
			check:Dock(TOP)
			check:DockMargin(0,0,0,betweencategories)
			check:SetChecked(icon_size == 1)
			check.OnChange = function(_, val)
				local data = 2
				if val then data = 1 end
				LocalPlayer():ConCommand("cl_tf2itembrowser_iconsize " .. data)
				icon_size = data
				atticons:UpdateSize()
				window.RebuildIconList()
				//Reset all the item icons inside atticons, so that they're rebuilt at the new size
				local icons = {}
				atticons:Clear()
				net.Start("TF2ItemBrowser_AttachedItems_GetFromSv", true)
					net.WriteEntity(window:GetEntity())
				net.SendToServer()
			end

			local deselect_holder = vgui.Create("Panel", attopts)
			deselect_holder:Dock(TOP)

			local button = TFStyleVGUI("DButton", deselect_holder)
			button:SetText("Deselect Model")
			button:Dock(BOTTOM)
			button:DockMargin(0,-button:GetTall(),0,0)
			button:SetVisible(false)
			button.DoClick = function()
				window:SetEntity(NULL)
			end

			local text = vgui.Create("DLabel", deselect_holder)
			text:SetWrap(true)
			text:SetAutoStretchVertical(true)
			text:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
			text:SetColor(gui_colors.TanLight)
			text:SetText("Right-click a model in the context menu to select it and attach items.")
			text:Dock(BOTTOM)
			text:InvalidateLayout()

			//This spot is occupied by either the deselect button or the text explaining how to select a model, with which one is visible
			//changing depending on if a model is selected. It looks ugly if the height of the panel changes on select/deselect, so instead
			//make the space that they share take up the height of whichever item is taller, regardless of visiblity.
			function deselect_holder:PerformLayout(w, h)
				button:InvalidateLayout()
				text:InvalidateLayout()
				local _h = math.max(button:GetTall(), text:GetTall())
				if h != _h then self:SetTall(_h) return end

				local valid = IsValid(window:GetEntity())
				button:SetVisible(valid)
				//if valid then text:SetText("Deselect " .. window:GetEntity():GetModel()) end
				//text:SetVisible(!valid) //this makes the text autostretch stop working; just make it transparent instead
				if !valid then
					text:SetColor(gui_colors.TanLight)
				else
					text:SetColor(color_transparent)
				end
				attopts:InvalidateLayout(true)
				attopts:SizeToChildren(false,true)
			end

			deselect_holder:InvalidateLayout(true)
			attopts:InvalidateLayout(true)
			attopts:SizeToChildren(false,true)
			timer.Simple(0.1,function()
				deselect_holder:InvalidateLayout(true)
				attopts:InvalidateLayout(true)
				attopts:SizeToChildren(false,true)
			end)

			AccessorFunc(window, "m_Entity", "Entity")
			function window:SetEntity(ent)
				window.m_Entity = ent
				atticons:Clear()
				if IsValid(self.SpawnPanel) then self.SpawnPanel:Remove() end

				if IsValid(ent) then
					atticons_holder:SetVisible(true)
					right_holder:InvalidateLayout()
					deselect_holder:InvalidateLayout()

					local mdl = string.StripExtension(string.GetFileFromFilename(ent:GetModel()))
					//Try to figure out what class the model is, and set the class filter to match
					for k, v in ipairs (classes) do
						if k == 1 or k == 11 then continue end
						if string.find(mdl, v.shortname, 1, true) then
							filters.class:ChooseOptionID(k)
							break
						end
					end
					local text = string.lower(GetTFLanguageString("#CurrentlyEquipped") or "CURRENTLY EQUIPPED:")
					text = string.upper(text[1]) .. string.sub(text, 2)
					atticons.Label:SetText(text .. " (" .. string.NiceName(mdl) .. ")")

					attopts.team:SetValue(ent:GetSkin() % 2 != 0)

					//Try to figure out if the selected ent has fx applied
					attopts.fx.IsUpdating = true
					local is_uber_skin = (math.ceil((ent:GetSkin()+1)/2) % 2) == 0
					if is_uber_skin then
						attopts.fx:ChooseOptionID(EFFECT_UBER+1)
					elseif IsValid(ent.ProxyentCritGlow) and ent.ProxyentCritGlow:GetSparksJarate() then
						attopts.fx:ChooseOptionID(EFFECT_JARATE+1)
					elseif ent:GetMaterial() == "models/player/shared/gold_player" then
						attopts.fx:ChooseOptionID(EFFECT_GOLD+1)
					elseif ent:GetMaterial() == "models/player/shared/ice_player" then
						attopts.fx:ChooseOptionID(EFFECT_ICE+1)
					else
						attopts.fx:ChooseOptionID(EFFECT_NONE+1)
					end
					attopts.fx.IsUpdating = nil

					net.Start("TF2ItemBrowser_AttachedItems_GetFromSv", true)
						net.WriteEntity(ent)
					net.SendToServer()
				else
					atticons_holder:SetVisible(false)
					right_holder:InvalidateLayout()
					deselect_holder:InvalidateLayout()

					//Reset some options that were specific to the selected ent
					filters.class:ChooseOptionID(1)
					attopts.team:SetValue(false)
					attopts.fx.IsUpdating = true
					attopts.fx:ChooseOptionID(1)
					attopts.fx.IsUpdating = nil
				end
			end

			function window:UpdateItemConflicts()
				//If there's no entity for items to be equipped to, then there's no item conflicts
				if !IsValid(self:GetEntity()) then
					self.EquipRegionConflicts = nil
					return
				end
				//Get all equip regions occupied by equipped items, and track how many items are occupying each region
				local regions = {}
				for k, v in pairs (atticons.icons) do
					local i = TF2Items.items[v.data.id]
					if !i or !i.equip_regions then continue end
					for k2, v2 in pairs (i.equip_regions) do
						regions[k2] = (regions[k2] or 0) + 1
						//If this region has an equip_conflicts table, add all of those too 
						//(i.e. if a whole_head item is equipped, occupy the hat region too)
						if TF2Items.equip_conflicts[k2] then
							for k3, v3 in pairs (TF2Items.equip_conflicts[k2]) do
								regions[k3] = (regions[k3] or 0) + 1
							end
						end
						//If this region is inside another region's equip_conflicts table, add that region too
						//(i.e. if a hat item is equipped, occupy the whole_head region too)
						for k3, v3 in pairs (TF2Items.equip_conflicts) do
							for k4, v4 in pairs (v3) do
								if i.equip_regions[k4] then
									regions[k3] = (regions[k3] or 0) + 1
								end
							end
						end
					end
				end
				self.EquipRegionConflicts = regions
				//Update all existing icons
				for k, v in pairs (atticons.icons) do
					local conflicting = self:GetItemHasConflict(v, true)
					if v.item_conflict != conflicting then
						v.item_conflict = conflicting
						v.itemdesc = v:UpdateItemDescription()
					end
				end
				if self.filters and self.filters.conflicting and self.filters.conflicting:GetValue() != 0 then //can be nil if the window is being closed
					//If we have a filter set to hide conflicting/non-conflicting icons, then rebuild the icon list instead
					self.RebuildIconList()
				else
					for k, v in pairs (self.icons) do
						local conflicting = self:GetItemHasConflict(v)
						if v.item_conflict != conflicting then
							v.item_conflict = conflicting
							//don't update the description if it hasn't built its data table yet
							if istable(v.data) then v.itemdesc = v:UpdateItemDescription() end
						end
					end
				end
			end

			function window:GetItemHasConflict(item, is_equipped)
				if !window.EquipRegionConflicts then return end
				local id
				if !ispanel(item) then
					//this is an item id
					id = item
				else
					//this is an item icon panel, grab the item id value from its data table
					//it may not have built its data table yet; in this case, the item id value will be in its place
					id = item.data
					if istable(id) then id = id.id end
					if !id then return end
				end

				local i = TF2Items.items[id]
				if !i or !i.equip_regions then return end
				local conflicting
				for k, v in pairs (i.equip_regions) do
					//For equipped items, if a region is occupied by *multiple* equipped items, then display a conflict.
					//For unequipped items, if a region is occupied by *any* equipped items, then display a conflict.
					if window.EquipRegionConflicts[k] and (!is_equipped or window.EquipRegionConflicts[k] > 1) then
						conflicting = true
						break
					end
				end
				return conflicting
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
						if input == "attach_item_spawn" then net.WriteBool(args[2]) end //open spawn panel upon received?

					elseif input == "attach_item_modify" then

						WriteItemDataTable(args[2]) //item data table
						net.WriteBool(GetConVar("cl_tf2itembrowser_advbone"):GetBool())
						net.WriteEntity(args[1]) //item ent to modify

					elseif input == "attach_item_remove" then
					
						net.WriteEntity(args[1]) //item ent to remove

					elseif input == "attach_par_skin" then

						net.WriteUInt(args[1], 8) //skin id

					elseif input == "attach_par_fx" then

						net.WriteUInt(args[1], 3) //EFFECT_ enum

					end

				net.SendToServer()

			end










			function window:OpenCustomItemEditor(id)

				if IsValid(TF2ItemBrowser_Editor) then TF2ItemBrowser_Editor:Close() end

				local editor = g_ContextMenu:Add("DFrame")
				editor:SetSize(920,750) //TODO: finalize later
				editor:SetTitle("Custom Item Editor")
				editor:Center()
				AddTFStyleToVGUI(editor)
				TF2ItemBrowser_Editor = editor
				editor:SetSizable(true)
				editor.controls = {}


				//Dock save and cancel buttons to bottom of panel
				local button_holder = vgui.Create("Panel", editor)
				local button_1 = TFStyleVGUI("DButton", button_holder)
				button_1:SetText(GetTFLanguageString("#TF_CancelSavePreset") or "CANCEL")
				button_1:SizeToContentsX(20)
				button_1.DoClick = function()
					editor:Close()
				end
				local button_2 = TFStyleVGUI("DButton", button_holder)
				button_2:SetText(GetTFLanguageString("#TF_SavePreset") or "SAVE")
				button_2:SizeToContentsX(20)
				button_2.DoClick = function()
					//TODO: make nicer gui for this later
					Derma_StringRequest(
						"Crappy Placeholder Save Dialog", 
						"Enter file name to save the item to\n(name only, no file extension)",
						editor.SavedName,
						function(name)
							local i = {}
							for pnl, funcs in pairs (TF2ItemBrowser_Editor.controls) do
								if funcs.Save then funcs.Save(i) end
							end
							i.name = name
							editor.SavedName = name //show this same filename in the save window if we open it again
							MsgN("\n\n\n")
							PrintTable(i)

							net.Start("TF2ItemBrowser_NewCustomItem_SendToSv")
								net.WriteData(util.Compress(util.TableToJSON(i)))
							net.SendToServer()
						end,
						nil,
						GetTFLanguageString("#TF_SavePreset") or "SAVE"
					)
				end
				button_holder:Dock(BOTTOM)
				button_holder:DockMargin(0,8,0,0)
				local button_w = math.max(180, button_1:GetWide(), button_2:GetWide()) //make these extra wide to better fill all the space they have, unless some language has a really long word here
				function button_holder:PerformLayout(w, h)
					button_1:SetWide(button_w)
					button_1:SetPos((w/2)-4-button_w, 0)
					button_2:SetWide(button_w)
					button_2:SetPos((w/2)+4, 0)
					button_holder:SizeToChildren(false, true)
				end


				local function AddColumnHolder(parent, column_count, column_space)
					local holder = vgui.Create("Panel", parent)
					local columns = {}
					for i = 1, column_count do
						columns[i] = vgui.Create("Panel", holder)
						columns[i]:Dock(LEFT)
						local left_margin = 0
						if i > 1 then left_margin = column_space/2 end
						local right_margin = 0
						if i < column_count then right_margin = column_space/2 end
						columns[i]:DockMargin(left_margin, 0, right_margin, 0)
					end
					function holder:PerformLayout(w, h)
						local holder_w = (w-(column_space*(column_count-1)))/column_count
						for i = 1, column_count do
							columns[i]:SetWide(holder_w)
							columns[i]:InvalidateChildren(true)
							columns[i]:SizeToChildren(false, true)
						end
						holder:SizeToChildren(false, true)
						parent:InvalidateLayout(true)
					end
					holder.columns = columns
					return holder
				end

				local function AddBox(parent, label)
					local box = vgui.Create("DSizeToContents")
					if parent:HasChildren() then
						box:DockMargin(0,8,0,0)
					end
					box:SetParent(parent)
					box:Dock(TOP)
					box:DockPadding(16,16,16,16)
					function box:Paint(w,h)
						draw.RoundedBox(12, 0,0,w,h, gui_colors._options)
					end

					if label then
						local text = vgui.Create("DLabel", box)
						text:SetContentAlignment(7) //top left
						text:SetAutoStretchVertical(true)
						text:SetFont("TF2ItemBrowser_ItemName")
						text:SetColor(gui_colors.TanLight)
						text:SetText(label)
						text:Dock(TOP)
						text:DockMargin(-8,-8,0,betweenitems)
					end

					return box
				end

				local function AddDropdown(parent, label, subtable, key_to_set, options, default_option_id)
					local combo = TFStyleVGUI("DComboBox", parent)
					local _pnl = AddTFLabelToVGUI(combo, label)
					_pnl:DockMargin(0,betweenitems,0,0)
					_pnl:Dock(TOP)
					combo:SetSortItems(false)
					function combo:PopulateOptions(options)
						combo:Clear()
						combo.options = options
						for k, v in ipairs (combo.options) do
							if combo.options[k].PrependSpacer then combo:AddSpacer() end
							combo.options[k].id = combo:AddChoice(v.Label, k)
						end
					end
					combo:PopulateOptions(options)
					editor.controls[combo] = {
						Load = function(i)
							if table.Count(combo.options) == 0 then return end
							local sel
							if subtable then
								i = i[subtable]
							end
							if i then
								for k, v in ipairs (combo.options) do
									if (v.Value and i[key_to_set] == v.Value) or (v.Load and v.Load(i) == true) then
										sel = v.id
										//don't break, multiple options can return true and we want to choose the lowermost one
									end
								end
							end
							if sel == nil then sel = (default_option_id or 1) end
							combo:ChooseOptionID(sel)
						end,
						Save = function(i)
							if !_pnl:IsVisible() or table.Count(combo.options) == 0 then return end
							local _, opt = combo:GetSelected()
							if combo.options[opt].Value then
								if subtable then
									i[subtable] = i[subtable] or {}
									i[subtable][key_to_set] = combo.options[opt].Value
								else
									i[key_to_set] = combo.options[opt].Value
								end
							elseif combo.options[opt].Save then 
								combo.options[opt].Save(i)
							end
						end,
					}
					return combo
				end

				local function AddTextEntry(parent, label, subtable, key_to_set, alt_style)
					//dock the textentry into a new panel that only exists to be a container, because otherwise, clicking on a 
					//textentry docked directly into one of our DSizeToContents boxes moves it to the bottom?? why??
					local _pnl = vgui.Create("Panel", parent)
					_pnl:DockMargin(0,betweenitems,0,0)
					_pnl:Dock(TOP)
					_pnl:SetHeight(20)
					local entry = TFStyleVGUI("DTextEntry", _pnl, alt_style)
					entry:Dock(FILL)
					entry:SetPlaceholderText(label)
					AddTFStyleTooltip(entry, label)
					//most entries won't have an OnEnter func, but include this just in case
					entry.OnFocusChanged = function(_, b) 
						if !b then entry:OnEnter() end
					end
					if key_to_set then
						editor.controls[entry] = {
							Load = function(i)
								local sel
								if subtable then
									i = i[subtable]
								end
								if i and i[key_to_set] then
									entry:SetText(i[key_to_set])
								end
							end,
							Save = function(i)
								if !_pnl:IsVisible() or entry:GetText() == "" then return end
								if subtable then
									i[subtable] = i[subtable] or {}
									i[subtable][key_to_set] = entry:GetText()
								else
									i[key_to_set] = entry:GetText()
								end
							end,
						}
					end
					return entry
				end

				local function AddMultilineTextEntry(parent, label, subtable, key_to_set)
					local entry = AddTextEntry(parent, label, subtable, key_to_set)
					entry:SetMultiline(true)
					//Automatically resize the entry to show all lines
					function entry:OnTextChanged()
						entry:GetParent():SetHeight((19*math.max(1,entry:GetNumLines()))+1)
					end
					local old_Load = editor.controls[entry].Load
					editor.controls[entry].Load = function(i)
						old_Load(i)
						timer.Simple(0, function() entry:OnTextChanged() end)
					end
					return entry
				end


				//Place all other controls in 3 side-by-side columns of equal width
				local scroll = TFStyleVGUI("DScrollPanel", editor)
				scroll:Dock(FILL)
				local holder = AddColumnHolder(scroll, 3, 8)
				holder:Dock(FILL)
				//fix: make sure that scrolling to change the icon's fov doesn't mistakenly scroll this panel
				local old_OnMouseWheeled = scroll.VBar.OnMouseWheeled
				function scroll.VBar:OnMouseWheeled(dlta)
					if editor.bp.Capturing or editor.bp:IsHovered() then return end
					return old_OnMouseWheeled(self, dlta)
				end


				//Unlabeled box for item type and type-specific controls
				local box = AddBox(holder.columns[1])

				//Selector for item_slot - this is also used to enable/disable controls that are only used for certain slots
				local combo = AddDropdown(box, GetTFLanguageString("#TF_ImportFile_TypeLabel") or "Item Type", nil, "item_slot", {
					{
						Label = GetTFLanguageString("#LoadoutSlot_Misc") or "Cosmetic",
						Value = "misc",
					},
					{
						Label = GetTFLanguageString("#TF_SteamWorkshop_Tag_Weapon") or "Weapon",
						Value = "_custom_weapon", //assign custom weapons to a generic "slot" instead of primary/etc to declutter these options just a bit
					},
				})
				combo:GetParent():DockMargin(0,0,0,0)
				function combo:OnSelect(index, value, data)
					local val = combo.options[index].Value
					editor.paintable:SetVisible(val == "misc")
					editor.genteel_smoke:SetVisible(val == "misc")
					editor.anim:GetParent():SetVisible(val == "_custom_weapon")
					holder:InvalidateLayout(true)
				end

				//Paintable toggle
				local check = TFStyleVGUI("DCheckBoxLabel", box)
				editor.paintable = check
				check:Dock(TOP)
				check:DockMargin(0,betweenitems,0,0)
				check:SetText("Paintable")
				editor.controls[check] = {
					Load = function(i)
						if i.capabilities and i.capabilities.paintable then check:SetChecked(true) end
					end,
					Save = function(i)
						if check:IsVisible() and check:GetChecked() then
							i.capabilities = i.capabilities or {}
							i.capabilities.paintable = 1
						end
					end
				}

				//Genteel smoke toggle
				local check = TFStyleVGUI("DCheckBoxLabel", box)
				editor.genteel_smoke = check
				check:Dock(TOP)
				check:DockMargin(0,betweenitems,0,0)
				check:SetText("Add " .. (GetTFLanguageString("#Attrib_Particle28") or "Genteel Smoke") .. " effect\n(requires \"cig_drg_smoke\" attachment)")
				function check:OnChange(val)
					//Toggle visibility of "disable genteel smoke" checkboxes in styles
					for _, style in pairs (editor.styles) do
						style:UpdateVisibility()
					end
					holder:InvalidateLayout(true)
				end
				editor.controls[check] = {
					Load = function(i)
						if i.attributes and i.attributes["attach particle effect static"] and 
						i.attributes["attach particle effect static"].value == 28 then check:SetChecked(true) end
					end,
					Save = function(i)
						if check:IsVisible() and check:GetChecked() then
							i.attributes = i.attributes or {}
							i.attributes["attach particle effect static"] = {
								attribute_class = "set_attached_particle_static",
								value = 28
							}
						end
					end
				}

				//Selector for weapon anim_slot as well as some relevant pose parameters
				editor.anim = AddDropdown(box, "Animation slot", nil, "anim_slot", {
					{
						Label = str_none,
						Value = "FORCE_NOT_USED"
					},
					{
						PrependSpacer = true,
						Label = GetTFLanguageString("#TR_Primary") or "Primary",
						Value = "primary"
					},
					{
						Label = GetTFLanguageString("#TR_Secondary") or "Secondary",
						Value = "secondary"
					},
					{
						Label = GetTFLanguageString("#TR_Melee") or "Melee",
						Value = "melee"
					},
					{
						Label = GetTFLanguageString("#TF_Weapon_PDA_Engineer") or "PDA",
						Value = "pda"
					},
					{
						Label = (GetTFLanguageString("#LoadoutSlot_Building") or "Building") .. " (toolbox, " .. string.lower(GetTFLanguageString("#TF_Weapon_Spy_Sapper") or "Sapper") .. ")",
						Value = "building"
					},
					{
						PrependSpacer = true,
						Label = (GetTFLanguageString("#Item") or "Item") .. " 1 (" .. string.lower(GetTFLanguageString("#TF_Weapon_FlareGun") or "Flare Gun") .. ", " .. string.lower(GetTFLanguageString("#TF_Weapon_Sword") or "Sword") .. ", " .. string.lower(GetTFLanguageString("#TF_Unique_Achievement_LunchBox") or "Sandvich") .. ", " .. string.lower(GetTFLanguageString("#TF_Unique_Achievement_Laser_Pointer") or "Wrangler") .. ", " .. string.lower(GetTFLanguageString("#TF_Jar") or "JAR") .. ", " .. string.lower(GetTFLanguageString("#TF_SharpDresser") or "Sharp Dresser") .. ")",
						Value = "item1"
					},
					{ //item1 for scout drink, applies hand_grip poseparam
						Label = (GetTFLanguageString("#Item") or "Item") .. " 1 (" .. string.lower(GetTFLanguageString("#TF_Class_Name_Scout") or "Scout")  .. " " .. string.lower(GetTFLanguageString("#TF_EnergyDrink") or "Drink") .. ")",
						Load = function(i)
							if i.anim_slot == "item1" and i.visuals and i.visuals.player_poseparam 
							and i.visuals.player_poseparam.r_hand_grip == 16 then return true end
						end,
						Save = function(i)
							i.anim_slot = "item1"
							i.visuals = i.visuals or {}
							i.visuals.player_poseparam = {r_hand_grip = 16}
						end
					},
					{
						Label = (GetTFLanguageString("#Item") or "Item") .. " 2 (" .. string.lower(GetTFLanguageString("#TF_Unique_Achievement_Scattergun_Double") or "Force-a-Nature") .. ", " .. string.lower(GetTFLanguageString("#TF_Unique_Robot_Arm") or "Gunslinger") .. ", " .. string.lower(GetTFLanguageString("#TF_Unique_Achievement_CompoundBow") or "Huntsman") .. ")",
						Value = "item2"
					},
					{
						Label = (GetTFLanguageString("#Item") or "Item") .. " 4 (" .. string.lower(GetTFLanguageString("#TF_ThermalThruster") or "Thermal Thruster") .. ")",
						Value = "item4"
					},
					//TODO: cow mangler has anim_slot "primary2" but this only has fire/reload anims and i'm not even sure if tf2 uses them; revisit later when we do anim functionality
					{
						Label = (GetTFLanguageString("#TR_Secondary") or "Secondary") .. " 2 (" ..  string.lower(GetTFLanguageString("#TF_BISON") or "BISON")  .. ")",
						Value = "secondary2"
					},
					{
						Label = (GetTFLanguageString("#TR_Melee") or "Melee") .. " - " .. string.lower(GetTFLanguageString("#Store_ItemDesc_AllClasses") or "All Classes"),
						Value = "melee_allclass"
					},
					{ //melee_allclass for bread jars, applies hand_grip poseparam
						Label = (GetTFLanguageString("#TR_Melee") or "Melee") .. " - " .. string.lower(GetTFLanguageString("#Store_ItemDesc_AllClasses") or "All Classes") .. " (" .. string.lower(GetTFLanguageString("#TF_Wearable_Bread") or "Bread")  .. " " .. string.lower(GetTFLanguageString("#TF_Jar") or "JAR") .. ")",
						Load = function(i)
							if i.anim_slot == "melee_allclass" and i.visuals and i.visuals.player_poseparam 
							and i.visuals.player_poseparam.r_hand_grip == 13 then return true end
						end,
						Save = function(i)
							i.anim_slot = "melee_allclass"
							i.visuals = i.visuals or {}
							i.visuals.player_poseparam = {r_hand_grip = 13}
						end
					},
					{ //melee_allclass for gas passer, applies a different hand_grip poseparam
						Label = (GetTFLanguageString("#TR_Melee") or "Melee") .. " - " .. string.lower(GetTFLanguageString("#Store_ItemDesc_AllClasses") or "All Classes") .. " (" .. string.lower(GetTFLanguageString("#TF_GasPasser") or "Gas Passer") .. ")",
						Load = function(i)
							if i.anim_slot == "melee_allclass" and i.visuals and i.visuals.player_poseparam 
							and i.visuals.player_poseparam.r_hand_grip == 16 then return true end
						end,
						Save = function(i)
							i.anim_slot = "melee_allclass"
							i.visuals = i.visuals or {}
							i.visuals.player_poseparam = {r_hand_grip = 16}
						end
					},
					{ //melee_allclass for hot hand, applies yet another different hand_grip poseparam as well as arm poseparm
						Label = (GetTFLanguageString("#TR_Melee") or "Melee") .. " - " .. string.lower(GetTFLanguageString("#Store_ItemDesc_AllClasses") or "All Classes") .. " (" .. string.lower(GetTFLanguageString("#TF_Weapon_HotHand") or "Hot Hand") .. ")",
						Load = function(i)
							if i.anim_slot == "melee_allclass" and i.visuals and i.visuals.player_poseparam 
							and i.visuals.player_poseparam.r_arm == 3 and i.visuals.player_poseparam.r_hand_grip == 15 
							then return true end
						end,
						Save = function(i)
							i.anim_slot = "melee_allclass"
							i.visuals = i.visuals or {}
							i.visuals.player_poseparam = {r_arm = 3, r_hand_grip = 15}
						end
					},
					{
						Label = (GetTFLanguageString("#GameType_Passtime") or "PASS Time") .. " JACK",
						Value = "passtime_ball"
					}
					//TOOD: 357 The Half-Zatoichi uses anim_slot "", what's going on there?
				}, 2) //default to "primary" instead of "none" because it'll probably draw the user toward it more


				//Checkboxes to select classes in any combination
				local box = AddBox(holder.columns[1], GetTFLanguageString("#Store_ClassFilterLabel") or "Classes:")
				editor.classes = AddColumnHolder(box, 3, 0)
				editor.classes:Dock(TOP)
				editor.classes.checks = {}
				for i = 2, 10 do
					local check = TFStyleVGUI("DCheckBoxLabel", editor.classes.columns[math.fmod(i-2, 3)+1])
					check:Dock(TOP)
					if i > 4 then
						check:DockMargin(0,betweenitems,0,0)
					end
					check:SetText(GetTFLanguageString(classes[i].langstr) or string.NiceName(classes[i].longname))
					editor.classes.checks[classes[i].longname] = check
					//make sure user can read the text if it's cut off
					AddTFStyleTooltip(check.Label, check:GetText())
					local old_IsHovered = check.Label.IsHovered
					function check.Label:IsHovered(...)
						return old_IsHovered(self, ...) or check:IsHovered(...)
					end
					function check:OnChange(val) //Update all controls that are dependent on class selection
						//Only show equip regions for the currently selected class
						for _, pnl in pairs (editor.equip_regions.checks_by_class[i]) do
							pnl:SetVisible(val)
						end
						//Update visibility of class-specific model fields
						editor.class_models:UpdateVisibility()
						//Enable/disable bodygroup controls to only allow bodygroups used by the currently selected classes
						editor.bodygroups:UpdateVisibility()
						//Also update visibility of class-specific model fields and bodygroups in styles
						for _, style in pairs (editor.styles) do
							style:UpdateVisibility()
						end
						//Update classes listed in backpack icon class dropdown
						editor.bp_class:UpdateVisibility()
						holder:InvalidateLayout(true)
					end
				end
				editor.controls[editor.classes] = {
					Load = function(i)
						if !i.used_by_classes then return end
						for class, _ in pairs (i.used_by_classes) do
							if editor.classes.checks[class] then
								editor.classes.checks[class]:SetValue(true)
							end
						end
					end,
					Save = function(i)
						local tab = {}
						for class, check in pairs (editor.classes.checks) do
							if check:GetChecked() then
								tab[class] = 1
							end
						end
						if table.Count(tab) == 0 then tab = {none = 1} end
						i.used_by_classes = tab
					end
				}


				//Checkboxes to set equip region, again in any combination
				local box = AddBox(holder.columns[1], (GetTFLanguageString("#TF_ImportFile_EquipRegionLabel") or "Equip Region") .. ":" ) //no localization string for "equip regions" plural, oh well
				editor.equip_regions = AddColumnHolder(box, 2, 0)
				editor.equip_regions:Dock(TOP)
				editor.equip_regions.checks_by_class = {}
				editor.equip_regions.all_checks = {}
				for classid, class in ipairs (classes) do //add class-based equip regions in class order
					local checkbox_height
					for k, v in ipairs (TF2Items.equip_regions_list[classid]) do
						local check = TFStyleVGUI("DCheckBoxLabel", editor.equip_regions.columns[math.fmod(k-1, 2)+1])
						check:Dock(TOP)
						if k > 2 then
							check:DockMargin(0,betweenitems,0,0)
						elseif classid > 1 then
							check:DockMargin(0,betweencategories,0,0) //add space between different classes' equip regions
						end
						check:SetText(string.NiceName(v))
						editor.equip_regions.checks_by_class[classid] = editor.equip_regions.checks_by_class[classid] or {}
						editor.equip_regions.checks_by_class[classid][v] = check
						editor.equip_regions.all_checks[v] = check
						checkbox_height = checkbox_height or check:GetTall()
						//make sure user can read the text if it's cut off
						AddTFStyleTooltip(check.Label, check:GetText())
						local old_IsHovered = check.Label.IsHovered
						function check.Label:IsHovered(...)
							return old_IsHovered(self, ...) or check:IsHovered(...)
						end
					end
					//if number of entries is odd, then add another to prevent spacing issues with the next class
					if editor.equip_regions.checks_by_class[classid] and table.Count(editor.equip_regions.checks_by_class[classid]) % 2 != 0 then
						local pnl = vgui.Create("Panel", editor.equip_regions.columns[2])
						pnl:SetHeight(checkbox_height)
						pnl:Dock(TOP)
						pnl:DockMargin(0,betweenitems,0,0)
						editor.equip_regions.checks_by_class[classid]["_FILLER"] = pnl
					end
				end
				editor.controls[editor.equip_regions] = {
					Load = function(i)
						for classid, tab in pairs (editor.equip_regions.checks_by_class) do
							for k, check in pairs (tab) do
								if check.SetValue then check:SetValue(i.equip_regions and i.equip_regions[k]) end
								check:SetVisible(classid == 1 or (i.used_by_classes and i.used_by_classes[classes[classid].longname]))
							end
						end
					end,
					Save = function(i)
						local tab
						for k, check in pairs (editor.equip_regions.all_checks) do
							if check:IsVisible() and check:GetChecked() then
								tab = tab or {}
								tab[k] = 1
							end
						end
						if tab then i.equip_regions = tab end
					end
				}


				local box = AddBox(holder.columns[2], string.NiceName(language.GetPhrase("#models")) .. ":")

				//Base model
				local entry = AddTextEntry(box, "Item model", "model_player_per_class", "basename") //nil, "model_player") //model_player_per_class.basename accepts the %s token, while model_player doesn't. don't overthink it, just use the former for everything, even single-class items.
				entry:GetParent():DockMargin(0,0,0,0)
				editor.model = entry
				function entry:OnEnter()
					editor.bp:Refresh()
				end

				//Per-class models - gate these behind a checkbox that also only appears if multiple classes are selected
				local check = TFStyleVGUI("DCheckBoxLabel", box)
				check:SetText("Class-specific model paths?")
				check:DockMargin(0,betweenitems,0,0)
				check:Dock(TOP)
				editor.class_models = check
				check.classes = {}
				editor.controls[check] = {
					Load = function(i)
						//Only start off checked if there are already per-class models in the table
						for classid = 2, 10 do
							if i.model_player_per_class and i.model_player_per_class[classes[classid].longname] then
								check:SetChecked(true)
								break
							end
						end
						timer.Simple(0, function() check.HasLoaded = true check:UpdateVisibility() end)
					end
				}
				function check:OnChange(val)
					check:UpdateVisibility()
				end
				function check:UpdateVisibility()
					if !self.HasLoaded then return end //make sure the class selector doesn't mistakenly disable stuff during its loading process
					local selected_class_count = 0
					for _, pnl in pairs (editor.classes.checks) do
						if pnl:GetChecked() then selected_class_count = selected_class_count + 1 end
					end
					//Only show the checkbox if multiple classes are selected
					check:SetVisible(selected_class_count > 1)
					//Only show the entry box for each class if the checkbox is selected, the corresponding class is selected, AND multiple classes are selected
					for i = 2, 10 do
						editor.class_models.classes[i]:GetParent():SetVisible(check:GetChecked() and editor.classes.checks[classes[i].longname]:GetChecked() and selected_class_count > 1)
					end
					//Only show the help text if we're showing the class-specific entries
					check.help:SetVisible(selected_class_count > 1 and check:GetChecked())
					//Refresh the backpack icon modelpanel, just in case the currently used model was disabled or something
					editor.bp:Refresh()
				end
				for i = 2, 10 do
					local entry = AddTextEntry(box, "Item model - " .. (GetTFLanguageString(classes[i].langstr) or string.NiceName(classes[i].longname)), "model_player_per_class", classes[i].longname)
					check.classes[i] = entry
					function entry:OnEnter()
						editor.bp:Refresh()
					end
				end
				local help = vgui.Create("DLabel", box)
				help:SetWrap(true)
				help:SetAutoStretchVertical(true)
				help:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
				help:SetColor(gui_colors.TanLight)
				help:SetText("Tip: As an alternative, \"%s\" (percent sign s) in the main model path will be read as the class the item is spawned for - \"hat_%s\" will become \"hat_demo\", \"hat_engineer\", and so on.")
				help:Dock(TOP)
				help:DockMargin(0,betweenitems,0,0)
				check.help = help

				//Text entries for attached models - this creates as many entries as needed, 
				//adding an empty one to the list when the existing ones are all filled
				local pnl = vgui.Create("DSizeToContents", box)
				pnl:Dock(TOP)
				pnl:DockMargin(0,betweencategories-betweenitems,0,0)
				editor.attached_models = pnl
				pnl.entries = {}
				function pnl:UpdateEntries()
					//Clear out blank entries except the last one
					local entries_to_remove = {}
					for k, v in ipairs (pnl.entries) do
						if v:GetText() == "" and k != #pnl.entries then entries_to_remove[k] = v end
					end
					for k, v in pairs (entries_to_remove) do
						v:GetParent():Remove()
						table.remove(pnl.entries, k)
					end
					for k, v in ipairs (pnl.entries) do
						v:Dock(TOP)
					end
					//Make sure we always have a blank entry at the end of the list
					if #pnl.entries == 0 or pnl.entries[#pnl.entries]:GetText() != "" then
						pnl:AddEntry()
					end
					for k, v in pairs (pnl.entries) do
						local text = "Attached model " .. tostring(k)
						v:SetPlaceholderText(text)
						AddTFStyleTooltip(v, text)
					end
				end
				function pnl:AddEntry()
					local entry = AddTextEntry(pnl, "")
					table.insert(pnl.entries, entry)
					local old_OnLoseFocus = entry.OnLoseFocus
					function entry:OnLoseFocus(...)
						pnl:UpdateEntries()
						old_OnLoseFocus(entry, ...) //not running this results in focus getting stuck in such a way that the context menu can't be closed
					end
					function entry:OnEnter()
						editor.bp:Refresh()
					end
					return entry
				end
				editor.controls[pnl] = {
					Load = function(i)
						if i.visuals and i.visuals.attached_models then
							for k, v in pairs (i.visuals.attached_models) do
								local entry = pnl:AddEntry()
								entry:SetText(i.visuals.attached_models[k].model)
							end
						end
						pnl:UpdateEntries()
					end,
					Save = function(i)
						for k, v in ipairs (pnl.entries) do
							if v:GetText() != "" then
								i.visuals = i.visuals or {}
								i.visuals.attached_models = i.visuals.attached_models or {}
								//put these into a sequential table starting with 0, to match the formatting of tf2 items
								table.insert(i.visuals.attached_models, table.Count(i.visuals.attached_models), {model = v:GetText()})
							end
						end
					end
				}
				local help = vgui.Create("DLabel", box)
				help:SetWrap(true)
				help:SetAutoStretchVertical(true)
				help:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
				help:SetColor(gui_colors.TanLight)
				help:SetText("Extra models attached to the item, i.e. festive lights, botkillers, flamethrower pilot lights")
				help:Dock(TOP)
				help:DockMargin(0,betweenitems,0,0)

				//Text entries for extra wearables - this works like the above but with a max of 2
				local pnl = vgui.Create("DSizeToContents", box)
				pnl:Dock(TOP)
				pnl:DockMargin(0,betweencategories-betweenitems,0,0)
				editor.extra_wearables = pnl
				pnl.entries = {}
				function pnl:UpdateEntries()
					//Clear out blank entries except the last one
					local entries_to_remove = {}
					for k, v in ipairs (pnl.entries) do
						if v:GetText() == "" and k != #pnl.entries then entries_to_remove[k] = v end
					end
					for k, v in pairs (entries_to_remove) do
						v:GetParent():Remove()
						table.remove(pnl.entries, k)
					end
					for k, v in ipairs (pnl.entries) do
						v:Dock(TOP)
					end
					//Make sure we always have a blank entry at the end of the list
					if #pnl.entries == 0 or pnl.entries[#pnl.entries]:GetText() != "" then
						pnl:AddEntry()
					end
					for k, v in pairs (pnl.entries) do
						local text = "Extra wearable " .. tostring(k)
						if k == 2 then text = text .. " (max 2)" end
						v:SetPlaceholderText(text)
						AddTFStyleTooltip(v, text)
					end
				end
				function pnl:AddEntry()
					//number of extra wearables has to be capped at 2 due to technical limitations -
					//every spawned item needs to track and network whether each extra_wearable slot 
					//is enabled, whether the item actually uses it or not
					if #pnl.entries > 1 then return end
					local entry = AddTextEntry(pnl, "")
					table.insert(pnl.entries, entry)
					local old_OnLoseFocus = entry.OnLoseFocus
					function entry:OnLoseFocus(...)
						pnl:UpdateEntries()
						old_OnLoseFocus(entry, ...) //not running this results in focus getting stuck in such a way that the context menu can't be closed
					end
					function entry:OnEnter()
						editor.bp:Refresh()
					end
					return entry
				end
				local tab = {"extra_wearable", "extra_wearable_2"}
				editor.controls[pnl] = {
					Load = function(i)
						for k, v in ipairs (tab) do
							if i[v] then
								local entry = pnl:AddEntry()
								if entry then entry:SetText(i[v]) end
							end
						end
						pnl:UpdateEntries()
					end,
					Save = function(i)
						for k, v in ipairs (pnl.entries) do
							if v:GetText() != "" then
								i[tab[k]] = v:GetText()
							end
						end
					end
				}
				local help = vgui.Create("DLabel", box)
				help:SetWrap(true)
				help:SetAutoStretchVertical(true)
				help:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
				help:SetColor(gui_colors.TanLight)
				help:SetText("Extra models attached to the player model, i.e. medigun/banner backpacks, banner flags")
				help:Dock(TOP)
				help:DockMargin(0,betweenitems,0,0)

				//Skin id pickers
				local skins = vgui.Create("Panel", box)
				local _pnl = AddTFLabelToVGUI(skins, "#skin")
				_pnl:DockMargin(0,betweencategories,0,0)
				_pnl:Dock(TOP)
				editor.skins = skins
				function skins:PerformLayout(w, h)
					w = (w - 8) / 2
					self.label1:SetWide(w)
					self.label2:SetWide(w)
					self.label1:SetPos(0,0)
					self.label2:SetPos(w+8,0)
				end
				local _skins = {
					[1] = {label = GetTFLanguageString("#TF_RedTeam_Name") or "RED", subtable = "visuals_red", col = desc_colors.negative},
					[2] = {label = GetTFLanguageString("#TF_BlueTeam_Name") or "BLU", subtable = "visuals_blu", col = desc_colors.positive},
				}
				for k, v in ipairs (_skins) do
					local num = TFStyleVGUI("DNumberWang", skins, true)
					num:SetDecimals(0)
					num:SetMinMax(0, 255) //just assuming this is the max skin count, idk, this is what advbonemerge went with
					num:SetValue(k-1)
					num.FGColor = v.col
					skins["num" .. k] = num
					skins["label" .. k] = AddTFLabelToVGUI(num, v.label)
					editor.controls[num] = {
						Load = function(i)
							if i[v.subtable] and i[v.subtable].skin != nil then
								num:SetValue(i[v.subtable].skin)
							end
						end,
						Save = function(i)
							local val = num:GetValue()
							if val != k-1 then //don't save default values
								i[v.subtable] = i[v.subtable] or {}
								i[v.subtable].skin = val
							end
						end,
					}
					if k == 1 then
						function num:OnValueChanged()
							editor.bp:Refresh()
						end
					end
				end


				//Checkboxes to set player bodygroups
				local box = AddBox(holder.columns[2], GetTFLanguageString("#TF_ImportFile_Bodygroups") or "Bodygroup:")
				editor.bodygroups = AddColumnHolder(box, 2, 0)
				editor.bodygroups:Dock(TOP)
				editor.bodygroups.checks = {}
				local bodygroups = {
					{
						label = "Hat",
						bgs = {
							scout = "hat",
							soldier = "hat",
							engineer = "hat",
							sniper = "hat"
						}
					},
					{
						label = "Headphones", // (" .. string.lower(GetTFLanguageString("#TF_Class_Name_Scout") or "Scout") .. ")",
						bgs = {
							scout = "headphones"
						}
					},
					{
						label = "Head", // (" .. string.lower(GetTFLanguageString("#TF_Class_Name_Pyro") or "Pyro") .. ")",
						bgs = {
							pyro = "head"
						}
					},
					{
						label = "Dogtags", // (" .. string.lower(GetTFLanguageString("#TF_Class_Name_Scout") or "Scout") .. ")",
						bgs = {
							scout = "dogtags"
						}
					},
					{
						label = "Grenades",
						bgs = {
							soldier = "grenades",
							pyro = "grenades",
							demoman = "grenades"
						}
					},
					{
						label = "Bullets", // (" .. string.lower(GetTFLanguageString("#TF_Class_Name_HWGuy") or "Heavy") .. ")",
						bgs = {
							heavy = "bullets"
							//sniper has a bullets bodygroup but it's not useful here, it just enables sydney sleeper darts
						}
					},
					{
						label = "Backpack", // (" .. string.lower(GetTFLanguageString("#TF_Class_Name_Pyro") or "Pyro") .. ", " .. string.lower(GetTFLanguageString("#TF_Class_Name_Medic") or "Medic") .. ")",
						bgs = {
							pyro = "backpack",
							medic = "medic_backpack"
						}
					},
					{
						label = "Hands", // (" .. string.lower(GetTFLanguageString("#TF_Class_Name_HWGuy") or "Heavy") .. ")",
						bgs = {
							heavy = "hands"
						}
					},
					{
						label = "Right hand", // (" .. string.lower(GetTFLanguageString("#TF_Class_Name_Pyro") or "Pyro") .. ", " .. string.lower(GetTFLanguageString("#TF_Class_Name_Engineer") or "Engineer") ..  ")",
						bgs = {
							pyro = "righthand",
							engineer = {name = "rightarm", val = 2} //rightarm 1 is gunslinger
						}
					},
					{
						label = "Shoes", // (" .. string.lower(GetTFLanguageString("#TF_Class_Name_Demoman") or "Demo") .. ", " .. string.lower(GetTFLanguageString("#TF_Class_Name_Scout") or "Scout") ..  ")",
						bgs = {
							scout = "shoes_socks",
							demoman = "shoes",
						}
					},
				}
				local keys_by_bg = {}
				for k, v in ipairs (bodygroups) do
					for class, bg in pairs (v.bgs) do
						local val = 1
						if istable(bg) then 
							val = bg.val
							bg = bg.name
						end
						keys_by_bg[bg] = {val = val, k = k}
					end
					local check = TFStyleVGUI("DCheckBoxLabel", editor.bodygroups.columns[math.fmod(k-1, 2)+1])
					check:Dock(TOP)
					if k > 2 then
						check:DockMargin(0,betweenitems,0,0)
					end
					check:SetText(v.label)
					editor.bodygroups.checks[k] = check
					function check:OnChange(val)
						//Update bodygroups in styles - bodygroups that are already enabled here should be checked and grayed out in styles
						for _, style in pairs (editor.styles) do
							style:UpdateVisibility()
						end
						//Also update backpack icon, in case we're using a visible class model there
						editor.bp:Refresh()
					end
					//make sure user can read the text if it's cut off
					AddTFStyleTooltip(check.Label, check:GetText())
					local old_IsHovered = check.Label.IsHovered
					function check.Label:IsHovered(...)
						return old_IsHovered(self, ...) or check:IsHovered(...)
					end
				end
				function editor.bodygroups:UpdateVisibility()
					if !self.HasLoaded then return end //make sure the class selector doesn't mistakenly disable stuff during its loading process
					//Enable/disable bodygroup controls to only allow bodygroups used by the currently selected classes
					for k, v in ipairs (editor.bodygroups.checks) do
						local selected_classes = 0
						for class, bg in pairs (bodygroups[k].bgs) do
							if editor.classes.checks[class]:GetChecked() then
								selected_classes = selected_classes + 1
							end
						end
						v:SetEnabled(selected_classes > 0)
						v:SetChecked(selected_classes > 0 and v:GetChecked())
					end
				end
				editor.controls[editor.bodygroups] = {
					Load = function(i)
						if i.visuals and i.visuals.player_bodygroups then
							for k, v in pairs (i.visuals.player_bodygroups) do
								if keys_by_bg[k] and v == keys_by_bg[k].val then
									editor.bodygroups.checks[keys_by_bg[k].k]:SetChecked(true)
								end
							end
						end
						timer.Simple(0, function() editor.bodygroups.HasLoaded = true editor.bodygroups:UpdateVisibility() end)
					end,
					Save = function(i)
						for k, v in ipairs (editor.bodygroups.checks) do
							if !v:GetChecked() then continue end
							for class, bg in pairs (bodygroups[k].bgs) do
								if !editor.classes.checks[class]:GetChecked() then continue end
								i.visuals = i.visuals or {}
								i.visuals.player_bodygroups = i.visuals.player_bodygroups or {}
								local val = 1
								if istable(bg) then
									val = bg.val
									bg = bg.name
								end
								i.visuals.player_bodygroups[bg] = val
							end
						end
					end
				}


				local button = TFStyleVGUI("DButton", holder.columns[2])
				button:SetText("Add Style")
				button:Dock(TOP)
				button:DockMargin(0,8,0,0)
				button:SetZPos(1) //keep this below all the styles we create
				function button:DoClick()
					local style = self:AddStyle()
					style.HasLoaded = true
					style:UpdateVisibility()
				end
				editor.styles = {}
				function button:AddStyle()

					local box = AddBox(holder.columns[2])
					local i = table.insert(editor.styles, box)
					//for most of these boxes, we have a thick dockpadding on all sides to make the controls fit inside nicely, while the label at the top
					//uses negative dockmargins to appear closer to the edges at the controls. unfortunately, DSizeToContents doesn't like items within it
					//using negative dockmargins on the right side specifically, which we'd have to do to make the "remove style" button match the label.
					//guess we have to apply the padding to all the controls manually, bah!
					local _a, _b, side_margin, _c = box:GetDockPadding()
					box:DockPadding(_a, _b, 0, _c)
					

					local text_holder = vgui.Create("Panel", box)
					text_holder:SetHeight(22)
					text_holder:Dock(TOP)
					text_holder:DockMargin(-8-3,-8-3,0,betweenitems)
					local entry = TFStyleVGUI("DTextEntry", text_holder)
					entry:SetFont("TF2ItemBrowser_ItemName")
					entry:SetPlaceholderText("Style " .. tostring(i))
					entry:Dock(FILL)
					box.name = entry
					function entry:OnEnter()
						//update backpack icon style selector
						editor.bp_style:UpdateVisibility()
					end

					local close = vgui.Create("DButton", text_holder)
					close:SetText("")
					close:SetSize(22,22)
					close:Dock(RIGHT)
					close:DockMargin(5,0,5,0)
					function close:Paint(w,h)
						if self.Depressed then
							surface.SetDrawColor(color_white)
						elseif self.Hovered then
							surface.SetDrawColor(gui_colors.LightRed)
						else
							surface.SetDrawColor(gui_colors.TanDark)
						end
						surface.SetMaterial(close_button)
						surface.DrawTexturedRect(0,0,w,h)
					end
					AddTFButtonSounds(close)
					function close:DoClick()
						table.remove(editor.styles, table.KeyFromValue(editor.styles, box))
						close:Remove()
						box:Remove()
						for i, style in ipairs (editor.styles) do
							style.name:SetPlaceholderText("Style " .. tostring(i))
						end
						//update backpack icon style selector
						editor.bp_style:UpdateVisibility()
						//update backpack icon, just in case we removed the style it was using
						editor.bp:Refresh()
					end


					local check = TFStyleVGUI("DCheckBoxLabel", box)
					check:SetText("Change models?")
					check:DockMargin(0,betweenitems,side_margin,0)
					check:Dock(TOP)
					box.model_check = check
					function check:OnChange(val)
						box:UpdateVisibility()
						editor.bp:Refresh()
					end

					//Base model
					local entry = AddTextEntry(box, "Item model path")
					entry:GetParent():DockMargin(0,betweenitems,side_margin,0)
					box.model = entry
					function entry:OnEnter()
						editor.bp:Refresh()
					end

					//Per-class models - gate these behind a checkbox that also only appears if multiple classes are selected
					local check = TFStyleVGUI("DCheckBoxLabel", box)
					check:SetText("Class-specific model paths?")
					check:DockMargin(0,betweenitems,side_margin,0)
					check:Dock(TOP)
					box.class_models = check
					check.classes = {}
					function check:OnChange(val)
						box:UpdateVisibility()
					end
					for i = 2, 10 do
						local entry = AddTextEntry(box, GetTFLanguageString(classes[i].langstr) or string.NiceName(classes[i].longname))
						entry:GetParent():DockMargin(0,betweenitems,side_margin,0)
						check.classes[i] = entry
						function entry:OnEnter()
							editor.bp:Refresh()
						end
					end


					local check = TFStyleVGUI("DCheckBoxLabel", box)
					check:SetText("Change skins?")
					check:DockMargin(0,betweencategories,side_margin,0)
					check:Dock(TOP)
					box.skins_check = check
					function check:OnChange(val)
						box:UpdateVisibility()
					end

					//Skin id pickers
					local skins = vgui.Create("Panel", box)
					local _pnl = AddTFLabelToVGUI(skins, "#skin")
					_pnl:DockMargin(0,betweenitems,side_margin,0)
					_pnl:Dock(TOP)
					box.skins = skins
					function skins:PerformLayout(w, h)
						w = (w - 8) / 2
						self.label1:SetWide(w)
						self.label2:SetWide(w)
						self.label1:SetPos(0,0)
						self.label2:SetPos(w+8,0)
					end
					for k, v in ipairs (_skins) do
						local num = TFStyleVGUI("DNumberWang", skins, true)
						num:SetDecimals(0)
						num:SetMinMax(0, 255) //just assuming this is the max skin count, idk, this is what advbonemerge went with
						num:SetValue(k-1)
						num.FGColor = v.col
						skins["num" .. k] = num
						skins["label" .. k] = AddTFLabelToVGUI(num, v.label)
						if k == 1 then
							function num:OnValueChanged()
								editor.bp:Refresh()
							end
						end
					end


					local check = TFStyleVGUI("DCheckBoxLabel", box)
					check:SetText("Set additional bodygroups?")
					check:DockMargin(0,betweencategories,side_margin,0)
					check:Dock(TOP)
					box.bodygroups_check = check
					function check:OnChange(val)
						box:UpdateVisibility()
					end

					//Checkboxes to set player bodygroups
					box.bodygroups = AddColumnHolder(box, 2, 0)
					box.bodygroups:Dock(TOP)
					box.bodygroups:DockMargin(0,0,side_margin,0)
					box.bodygroups.checks = {}
					for k, v in ipairs (bodygroups) do
						local check = TFStyleVGUI("DCheckBoxLabel", box.bodygroups.columns[math.fmod(k-1, 2)+1])
						check:Dock(TOP)
						check:DockMargin(0,betweenitems,0,0)
						check:SetText(v.label)
						box.bodygroups.checks[k] = check
						function check:OnChange(val)
							//update backpack icon, in case we're using a visible class model there
							editor.bp:Refresh()
						end
						//make sure user can read the text if it's cut off
						AddTFStyleTooltip(check.Label, check:GetText())
						local old_IsHovered = check.Label.IsHovered
						function check.Label:IsHovered(...)
							return old_IsHovered(self, ...) or check:IsHovered(...)
						end
					end


					//Toggle to disable genteel smoke effect
					local check = TFStyleVGUI("DCheckBoxLabel", box)
					check:SetText("Disable " .. (GetTFLanguageString("#Attrib_Particle28") or "Genteel Smoke") .. " effect")
					check:DockMargin(0,betweencategories,side_margin,0)
					check:Dock(TOP)
					box.disable_genteel_smoke = check


					function box:UpdateVisibility()
						if !self.HasLoaded then return end //make sure the class selector doesn't mistakenly disable stuff during its loading process
						local selected_class_count = 0
						for _, pnl in pairs (editor.classes.checks) do
							if pnl:GetChecked() then selected_class_count = selected_class_count + 1 end
						end
						//Only show the model entry box (or anything else below) if the model checkbox is selected
						box.model:GetParent():SetVisible(box.model_check:GetChecked())
						//Only show the multi-class checkbox if multiple classes are selected
						box.class_models:SetVisible(box.model_check:GetChecked() and selected_class_count > 1)
						//Only show the entry box for each class if the multi-class checkbox is selected, the corresponding class is selected, AND multiple classes are selected
						for i = 2, 10 do
							box.class_models.classes[i]:GetParent():SetVisible(box.model_check:GetChecked() and box.class_models:GetChecked() and editor.classes.checks[classes[i].longname]:GetChecked() and selected_class_count > 1)
						end

						skins:GetParent():SetVisible(box.skins_check:GetChecked())

						box.bodygroups:SetVisible(box.bodygroups_check:GetChecked())
						for k, v in ipairs (box.bodygroups.checks) do
							if editor.bodygroups.checks[k]:GetChecked() then
								//Bodygroups that are already enabled in the base settings should be checked and grayed out here
								v:SetEnabled(false)
								v:SetChecked(true)
								v.ForceCheckedByBase = true
							else
								//Enable/disable bodygroup controls to only allow bodygroups used by the currently selected classes
								local selected_classes = 0
								for class, bg in pairs (bodygroups[k].bgs) do
									if editor.classes.checks[class]:GetChecked() then
										selected_classes = selected_classes + 1
									end
								end
								v:SetEnabled(selected_classes > 0)
								if v.ForceCheckedByBase then
									v:SetChecked(false)
									v.ForceCheckedByBase = nil
								end
								v:SetChecked(selected_classes > 0 and v:GetChecked())
							end
						end

						box.disable_genteel_smoke:SetVisible(editor.genteel_smoke:GetChecked())

						//Refresh the backpack icon modelpanel, just in case the currently used model/skin/etc. was disabled or something
						editor.bp:Refresh()
					end

					//update backpack icon style selector
					editor.bp_style:UpdateVisibility()

					return box

				end
				editor.controls[button] = {
					Load = function(i)
						if i.visuals and i.visuals.styles then
							for k, v in pairs (i.visuals.styles) do
								local style = button:AddStyle()
								if v.name then style.name:SetText(v.name) end
								if v.model_player_per_class then
									style.model_check:SetChecked(true)
									if v.model_player_per_class.basename then
										style.model:SetText(v.model_player_per_class.basename)
									end
									for i2 = 2, 10 do
										if v.model_player_per_class[classes[i2].longname] then
											style.class_models:SetChecked(true)
											style.class_models.classes[i2]:SetText(v.model_player_per_class[classes[i2].longname])
										end
									end
								end
								if v.skin_red then
									style.skins_check:SetChecked(true)
									style.skins.num1:SetValue(v.skin_red)
								end
								if v.skin_blu then
									style.skins_check:SetChecked(true)
									style.skins.num2:SetValue(v.skin_blu)
								end
								if v.additional_hidden_bodygroups then
									for k, v in pairs (v.additional_hidden_bodygroups) do
										if keys_by_bg[k] and v == keys_by_bg[k].val then
											style.bodygroups.checks[keys_by_bg[k].k]:SetChecked(true)
										end
									end
								end
								if v.use_smoke_particle_effect and v.use_smoke_particle_effect == 0 then
									style.disable_genteel_smoke:SetChecked(true)
								end
								timer.Simple(0, function() style.HasLoaded = true style:UpdateVisibility() end)
							end
						end
					end,
					Save = function(i)
						local tab = {}
						for i2, style in pairs (editor.styles) do
							local tab2 = {}
							if style.name:GetText() != "" then
								tab2.name = style.name:GetText()
							end
							if style.model:GetParent():IsVisible() and style.model:GetText() != "" then
								tab2.model_player_per_class = tab2.model_player_per_class or {}
								tab2.model_player_per_class.basename = style.model:GetText()
							end
							for k, v in pairs (style.class_models.classes) do
								if v:GetParent():IsVisible() and v:GetText() != "" then
									tab2.model_player_per_class = tab2.model_player_per_class or {}
									tab2.model_player_per_class[classes[k].longname] = v:GetText()
								end
							end
							if style.skins:GetParent():IsVisible() then
								if style.skins.num1:GetValue() != editor.skins.num1:GetValue() then 
									tab2.skin_red = style.skins.num1:GetValue()
								end
								if style.skins.num2:GetValue() != editor.skins.num2:GetValue() then 
									tab2.skin_blu = style.skins.num2:GetValue()
								end
							end
							if style.bodygroups:IsVisible() then
								for k, v in ipairs (style.bodygroups.checks) do
									if !v:GetChecked() or v.ForceCheckedByBase then continue end
									for class, bg in pairs (bodygroups[k].bgs) do
										if !editor.classes.checks[class]:GetChecked() then continue end
										tab2.additional_hidden_bodygroups = tab2.additional_hidden_bodygroups or {}
										local val = 1
										if istable(bg) then
											val = bg.val
											bg = bg.name
										end
										tab2.additional_hidden_bodygroups[bg] = val
									end
								end
							end
							if style.disable_genteel_smoke:IsVisible() and style.disable_genteel_smoke:GetChecked() then
								tab2.use_smoke_particle_effect = 0
							end
							//add the style even if it's empty; players might use one empty "default" style 
							//and another non-default style to add a selection between both options
							tab[i2-1] = tab2
						end
						if table.Count(tab) > 0 then
							i.visuals = i.visuals or {}
							i.visuals.styles = tab
						end
					end,
				}


				local box = AddBox(holder.columns[3], (GetTFLanguageString("#TF_ImportFile_IconLabel") or "Backpack Icon") .. ":")

				local bpcontainer = vgui.Create("Panel", box)
				bpcontainer:Dock(TOP)
				local mdl = CreateItemIconModelPanel(bpcontainer)
				editor.bp = mdl
				mdl:SetSize(item_icon_sizes[2].w, item_icon_sizes[2].h)
				local old_Paint = mdl.Paint
				function mdl:Paint(w,h)
					if IsValid(editor.bp_pos) and !editor.bp_pos:IsEditing() and !editor.bp_pos:IsHovered() then
						editor.bp_pos:SetText(tostring(self:GetCamPos()))
					end
					if IsValid(editor.bp_ang) and !editor.bp_ang:IsEditing() and !editor.bp_ang:IsHovered() then
						editor.bp_ang:SetText(tostring(self:GetLookAng()))
					end
					if IsValid(editor.bp_fov) and !editor.bp_fov:IsEditing() and !editor.bp_fov:IsHovered() then
						editor.bp_fov:SetValue(self:GetFOV())
					end
					BackpackItemBorderUnscaled(0,0,w,h)
					return old_Paint(mdl,w,h)
				end
				mdl:DockMargin(0,0,8,0)
				mdl:Dock(LEFT)
				bpcontainer:SetHeight(mdl:GetTall())
				mdl.models = {}
				function mdl:Refresh(cam_override)
					if !self.HasLoaded then return end
					//equivalent of CreateItemModelsAndParticles function that populates models with the ones specified by the editor
					local _, class = editor.bp_class:GetSelected()
					if class then
						class = class_longname_to_id[editor.bp_class.options[class].Value]
					end
					local _, style = editor.bp_style:GetSelected()
					if style then
						style = editor.styles[editor.bp_style.options[style].Value + 1]
					end
					local skin = editor.skins.num1:GetValue()
					if style and style.skins:GetParent():IsVisible() then
						skin = style.skins.num1:GetValue()
					end

					for k, v in ipairs (mdl.models) do
						if IsValid(v) then v:Remove() end
					end
					mdl.models = {}
					//Class model for preview, if enabled
					if editor.bp_showclass:GetChecked() and class then
						local ent = ClientsideModel("models/player/" .. classes[class].shortname .. ".mdl", RENDERGROUP_OTHER)
						if IsValid(ent) then
							table.insert(mdl.models, ent)
							ent.DontUseBoundsForCamera = true
							for k, v in ipairs (bodygroups) do
								if editor.bodygroups.checks[k]:GetChecked() or (style and style.bodygroups.checks[k]:GetChecked()) then
									local val = 1
									local bg = v.bgs[classes[class].longname]
									if istable(bg) then 
										val = bg.val
										bg = bg.name
									end
									if bg then
										bg = ent:FindBodygroupByName(bg)
										ent:SetBodygroup(bg, val)
									end
								end
							end
						end
					end
					//Item model
					local model
					if style and class and style.class_models.classes[class]:GetParent():IsVisible() and style.class_models.classes[class]:GetText() != "" then
						model = style.class_models.classes[class]:GetText()
					elseif style and style.model:GetParent():IsVisible() and style.model:GetText() != "" then
						model = string.Replace(style.model:GetText(), "%s", classes[class].shortname)
					elseif class and editor.class_models.classes[class]:GetParent():IsVisible() and editor.class_models.classes[class]:GetText() != "" then
						model = editor.class_models.classes[class]:GetText()
					elseif editor.model:GetText() != "" then
						model = string.Replace(editor.model:GetText(), "%s", classes[class].shortname)
					end
					if model then
						local ent = ClientsideModel(model, RENDERGROUP_OTHER)
						if IsValid(ent) then
							if IsValid(mdl.models[1]) then
								ent:SetParent(mdl.models[1])
								ent:AddEffects(EF_BONEMERGE)
							else
								ent:SetAngles(Angle(10,130,0)) //make sure this matches CreateItemModelsAndParticles; model angles from resource\ui\econ\itemmodelpanel.res; produces the most game-accurate lighting 
							end
							table.insert(mdl.models, ent)
							mdl.Entity = ent
						end
					end
					//TODO: attachments, options to show wearables instead

					//Only reset the camera if the values returned by DoItemModelCamera have changed (i.e. a model or animation changed)
					local cam = DoItemModelCamera(mdl.models) //no icon panel arg here because there's no item data table to check yet; only consequence of this is that we can't use the item_camera attachment, which we don't want anyway
					local docamera = mdl.old_cam == nil
					if mdl.old_cam then
						for k, v in pairs (cam) do
							if v != mdl.old_cam[k] then
								docamera = true
								break
							end
						end
					end
					if docamera then
						mdl:SetCamPos(Vector(cam.pos)) //use copies of pos/ang, otherwise the values in old_cam will change as the camera moves
						mdl:SetFOV(cam.fov)
						mdl:SetLookAng(Angle(cam.ang))
						mdl.old_cam = cam
					end
					//Upon first loading, apply the values of the pos/ang/fov settings instead if applicable, without touching the old_cam stuff
					if cam_override then
						mdl:SetCamPos(Vector(cam_override.pos))
						mdl:SetFOV(cam_override.fov)
						mdl:SetLookAng(Angle(cam_override.ang))
					end
				end
				editor.controls[mdl] = {
					Load = function(i)
						//to avoid unnecessary Refresh calls as other elements are loading, try to do this last
						timer.Simple(FrameTime(), function()
							mdl.HasLoaded = true
							mdl:Refresh(i._customitem_bp)
						end)
					end
				}

				editor.bp_pos = AddTextEntry(bpcontainer, "Camera Position", "_customitem_bp", "pos", true)
				editor.bp_pos:GetParent():DockMargin(0,0,0,0)
				function editor.bp_pos:OnChange()
					editor.bp:SetCamPos(Vector(self:GetText()))
				end

				editor.bp_ang = AddTextEntry(bpcontainer, "Camera Angles", "_customitem_bp", "ang", true)
				function editor.bp_ang.OnChange()
					editor.bp:SetLookAng(Angle(self:GetText()))
				end

				local num = TFStyleVGUI("DNumberWang", bpcontainer, true) //this space is too small for a slider like in gmod's spawnicon editor
				editor.bp_fov = num
				num:DockMargin(0,betweenitems,0,0)
				num:Dock(TOP)
				num:SetDecimals(2)
				num:SetMinMax(0.001, 179)
				num:SetPlaceholderText("Camera FOV")
				AddTFStyleTooltip(num, "Camera FOV")
				editor.controls[num] = {
					Load = function(i)
						if i._customitem_bp and i._customitem_bp.fov then
							num:SetValue(i._customitem_bp.fov)
						end
					end,
					Save = function(i)
						if num:IsVisible() then
							i._customitem_bp = i._customitem_bp or {}
							i._customitem_bp.fov = num:GetValue()
						end
					end
				}
				function num:OnValueChanged()
					editor.bp:SetFOV(self:GetValue())
				end

				local drop = AddDropdown(box, "Class to show", "_customitem_bp", "class", {})
				editor.bp_class = drop
				function drop:OnSelect()
					editor.bp:Refresh()
				end
				function drop:UpdateVisibility()
					local _, old_sel = drop:GetSelected()
					if old_sel and drop:GetParent():IsVisible() then
						old_sel = drop.options[old_sel].Value
					else
						old_sel = ""
					end
					local options = {}
					for i = 2, 10 do
						if editor.classes.checks[classes[i].longname]:GetChecked() then
							table.insert(options, {
								Label = GetTFLanguageString(classes[i].langstr) or string.NiceName(classes[i].longname),
								Value = classes[i].longname
							})
						end
					end
					drop:GetParent():SetVisible(#options > 1)
					editor.bp_showclass:SetVisible(#options > 0) //set this here as well
					drop:PopulateOptions(options)
					if #options > 0 then
						//Reselect the previously selected option if it still exists, otherwise select the first one
						for k, v in ipairs (options) do
							if v.Value == old_sel then
								drop:ChooseOptionID(v.id)
								old_sel = nil
								break
							end
						end
						if old_sel then drop:ChooseOptionID(1) end
					end
					editor.bp:Refresh()
				end
				local old_Load = editor.controls[entry].Load
				editor.controls[drop].Load = function(i)
					//make sure to populate the drop's options first before loading, and to do that, we need to load the classes first, so wait a frame
					timer.Simple(0, function()
						drop:UpdateVisibility()
						old_Load(i)
					end)
				end

				local drop = AddDropdown(box, "Style to show", "_customitem_bp", "style", {})
				editor.bp_style = drop
				function drop:OnSelect()
					editor.bp:Refresh()
				end
				function drop:UpdateVisibility()
					local _, old_sel = drop:GetSelected()
					if old_sel and drop:GetParent():IsVisible() then
						old_sel = drop.options[old_sel].Value
					else
						old_sel = ""
					end
					local options = {}
					for i, style in pairs (editor.styles) do
						local name = style.name:GetText()
						if name == "" then
							name = "Style " .. tostring(i)
						end
						table.insert(options, {
							Label = name,
							Value = i-1
						})
					end
					drop:GetParent():SetVisible(#options > 1)
					drop:PopulateOptions(options)
					if #options > 0 then
						//Reselect the previously selected option if it still exists, otherwise select the first one
						for k, v in ipairs (options) do
							if v.Value == old_sel then
								drop:ChooseOptionID(v.id)
								old_sel = nil
								break
							end
						end
						if old_sel then drop:ChooseOptionID(1) end
					end
					editor.bp:Refresh()
				end
				editor.controls[drop].Load = function(i)
					//make sure to populate the drop's options first before loading, and to do that, we need to load the styles first, so wait a frame
					timer.Simple(0, function()
						drop:UpdateVisibility()
						old_Load(i)
					end)
				end

				local check = TFStyleVGUI("DCheckBoxLabel", box)
				check:SetText("Show class model in icon")
				check:DockMargin(0,betweenitems,0,0)
				check:Dock(TOP)
				editor.bp_showclass = check
				function check:OnChange(val)
					editor.bp:Refresh()
				end
				editor.controls[check] = {
					Load = function(i)
						if i._customitem_bp and i._customitem_bp.showclass then check:SetChecked(true) end
					end,
					Save = function(i)
						if check:IsVisible() and check:GetChecked() then
							i._customitem_bp = i._customitem_bp or {}
							i._customitem_bp.showclass = 1
						end
					end
				}


				local box = AddBox(holder.columns[3], language.GetPhrase("#information") .. ":")

				local entry = AddTextEntry(box, GetTFLanguageString("#TF_ImportFile_NameLabel" or "Item Name"), nil, "item_name")
				entry:GetParent():DockMargin(0,0,0,0)
				
				local entry = AddMultilineTextEntry(box, string.TrimRight(GetTFLanguageString("#TF_PublishFile_DescLabel") or "Description:", ":"), nil, "item_description")

				local check = TFStyleVGUI("DCheckBoxLabel", box)
				check:SetText("Add fake attributes?")
				check:DockMargin(0,betweencategories,0,0)
				check:Dock(TOP)
				check.entries = {}
				function check:OnChange(val)
					check:UpdateVisibility()
				end
				editor.controls[check] = {
					Load = function(i)
						check:SetChecked(i._display_attributes != nil)
						check:UpdateVisibility()
					end
				}
				function check:UpdateVisibility()
					for k, v in ipairs (check.entries) do
						v:SetVisible(check:GetChecked())
					end
				end
				check.entries[1] = AddMultilineTextEntry(box, "Neutral attributes", "_display_attributes", "neutral"):GetParent()
				check.entries[2] = AddMultilineTextEntry(box, "Positive attributes", "_display_attributes", "positive"):GetParent()
				check.entries[3] = AddMultilineTextEntry(box, "Negative attributes", "_display_attributes", "negative"):GetParent()


				local i = TF2Items.items[id] or {}
				for pnl, funcs in pairs (TF2ItemBrowser_Editor.controls) do
					if funcs.Load then funcs.Load(i) end
				end
				//if we're loading an existing file, then pressing the save button should default to saving to the same file that was loaded
				editor.SavedName = id or ""

			end

		end
	})










	local PANEL = {}

	function PANEL:Init()

		self:SetSize(item_icon_sizes[icon_size].w, item_icon_sizes[icon_size].h)
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
		local i = TF2Items.items[data.id] or {}

		//submodels that aren't used by this item are set to nil instead of false, so that we know not to add controls for them
		local vis = GetItemModelVisuals(data)
		if !vis.models.item then data.models.item = nil end
		if !vis.models.wearable then data.models.wearable = nil end
		if !vis.models.wearable_2 then data.models.wearable_2 = nil end
		if !vis.models.taunt_prop then data.models.taunt_prop = nil
		elseif !vis.models.item then data.models.taunt_prop = true end
		if !vis.models.attached_festive then data.models.attached_festive = nil end
		if !vis.models.stat_clock then data.models.stat_clock = nil end

		if #GetItemDefaultParticleEffects(data) == 0 then data.pe_def = false end

		if !self.default_paint and i.attributes and i.attributes["set item tint RGB"] then
			tab = {}
			local col = ProxyentPaintColor_PackedRGBToTab(i.attributes["set item tint RGB"].value)
			tab[false] = Vector(col[1], col[2], col[3])
			if i.attributes["set item tint RGB 2"] then
				col = ProxyentPaintColor_PackedRGBToTab(i.attributes["set item tint RGB 2"].value)
				tab[true] = Vector(col[1], col[2], col[3])
			end
			self.default_paint = tab
		end
		if self.default_paint and !data.paint.enabled then
			data.paint.enabled = true
			data.paint.col = table.Copy(self.default_paint)
		end

		local img_override
		if i.visuals and i.visuals.styles then
			img_override = i.visuals.styles[data.style].image_inventory
			self.strange_prefix = i.visuals.styles[data.style].strange_prefix
			self.aus_prefix = i.visuals.styles[data.style].aus_prefix
		end 
		img_override = img_override or i.image_inventory
		//remove self from icon render targets; we'll re-add ourself later if needed
		local rtkey = table.KeyFromValue(TF2ItemBrowser_IconRTs, self)
		if rtkey then TF2ItemBrowser_IconRTs[rtkey] = nil end
		if data.wp.enabled or data.models.attached_festive then
			//Tell our paint func to queue rendering a custom rendertarget icon
			self.mat = nil
			self.ImageToQueue = nil
			self.IconRenderToQueue = true
		elseif img_override == nil then
			self.no_image = true
		else
			//Tell our paint func to queue loading a standard icon texture from the game files
			self.IconRenderToQueue = nil
			if !self.mat or self.mat:GetName() != img_override then
				self.mat = nil
				self.ImageToQueue = img_override
			end
			if i.image_inventory_overlay then
				//there aren't many items with overlays, so just load these immediately, no need to queue then
				self.mat_overlay = Material(i.image_inventory_overlay)
			end
		end
		local quality_override
		if data.pe_unusual > 0 then
			quality_override = "rarity4" //unusual
		elseif data.models.stat_clock or self.aus_prefix then
			quality_override = "strange"
		elseif data.wp.enabled then
			quality_override = "paintkit"
		elseif i.item_quality == "normal" and data.models.attached_festive then
			quality_override = "unique"
		end
		self.quality = quality_override or i.item_quality or "unique"
		//Check if an item isn't strange quality, but would still have stat counting enabled (unusual weapons with stat clocks enabled, or 
		//unusual australium weapons) - this is used to add "Strange Unusual" to the item name, and to add the strange corner icon
		self.secondary_strange_quality = self.quality != "strange" and (self.data.models.stat_clock or (i.visuals and i.visuals.styles and i.visuals.styles[self.data.style].aus_prefix))
		local rarity_override
		if data.wp.enabled then
			rarity_override = paintkit_rarities[data.wp.id]
		end
		self.rarity = rarity_override or i._rarity or nil
		self.sound_pressed = i.mouse_pressed_sound or "ui/item_default_pickup.wav"
		self.sound_drop = i.drop_sound or "ui/item_default_drop.wav"

		self.itemname = self:UpdateItemName()
		self.itemdesc = self:UpdateItemDescription()

		//add corner icons; order is from the layout function in tf2 code (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/client/econ/item_model_panel.cpp#L1919-L1952)
		local icons = {}
		if isstring(data.id) then //add our own icon to distinguish custom items
			table.insert(icons, {icon = icon_custom})
		end
		if data.paint.enabled and !self.mat_overlay then //don't show paint icons for tools that display paint color in the image (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/client/econ/item_model_panel.cpp#L3143-L3144)
			//note: in tf2 code, this icon is also used to show decal tool image (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/client/econ/item_model_panel.cpp#L3138-L3141)
			local tab = {icon = icon_paint, paint = self.data.paint.col[false]}
			if self.data.paint.override[true] then
				tab.paint = {}
				tab.override = self.data.paint.override[false]
				tab.override_2 = self.data.paint.override[true]
			elseif self.data.paint.override[false] > 0 then
				tab.override = self.data.paint.override[false]
			elseif self.data.paint.col[true] then
				tab.paint = {self.data.paint.col[false], self.data.paint.col[true]}
			end
			table.insert(icons, tab)
		end
		//tf2 code also has "tf2_icon", which is used for items that originate from another game, i think? what is this even used by, some in-game implementation of inter-game steam trading? (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/client/econ/item_model_panel.cpp#L3162-L3172)
		if i.vision_filter_flags == 1 then
			table.insert(icons, {icon = icon_viewmode_pyrovision})
		elseif i.holiday_restriction == "halloween_or_fullmoon" or i.holiday_restriction == "halloween" then
			table.insert(icons, {icon = icon_viewmode_spooky})
		end
		if self.data.pe_unusual > 0 or (i.attributes and i.attributes["attach particle effect"]) then //not for quality; this shows for non-unusual items with fx (world traveler) but not for unusual items without fx (headtaker) (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/client/econ/item_model_panel.cpp#L3340-L3356)
			table.insert(icons, {icon = icon_unusual})
		end
		if self.quality == "strange" or self.strange_prefix or self.secondary_strange_quality then
			if self.data.models.stat_clock then
				table.insert(icons, {icon = icon_statclock})
			else
				table.insert(icons, {icon = icon_strange})
			end
		end
		//tf2 code has "loaner_icon", which we don't care about
		if #icons == 0 then icons = nil end 
		self.icons = icons

	end

	function PANEL:SetDefaultData()

		//When the icon is first created, it's only assigned an id number, and then when the icon becomes visible, Paint calls this func
		//to populate the data table. This is so we don't have to run all this a thousand times at once for icons we might not even use.
		local id = self.data
		if istable(id) then id = self.data.id end
		local i = TF2Items.items[id] or {}

		local _, class = TF2ItemBrowser.filters.class:GetSelected()
		if class == 1 then
			//go through classes in order, default to the first one that can use this item
			for k, v in ipairs (classes) do 
				if i.used_by_classes[v.longname] then
					class = k
					break
				end
			end
		end

		local team = TF2ItemBrowser.attopts.team.Value

		local style = 0
		if i.visuals and i.visuals.styles then
			//default to the first style listed; i THINK this is always 0 but let's make extra sure
			for k, v in SortedPairs (i.visuals.styles) do //this starts from 0 so we can't do ipairs
				style = k
				break
			end
		end

		local _, fx = TF2ItemBrowser.attopts.fx:GetSelected()

		self:SetData({
			id = id, 
			class = class, 
			team = team,
			style = style,

			models = {
				item = true,
				wearable = true,
				wearable_2 = false,
				taunt_prop = false,
				attached_festive = false,
				stat_clock = false,
			},

			fx = fx,
			paint = {
				enabled = false,
				col = {[false] = Vector(255,255,255)},
				override = {[false] = 0},
			},
			crit = {
				enabled = false,
				col = {[false] = Vector(1,1,1)},
				sparks_rb = false,
				sparks_c = false,
			},

			pe_def = true,
			pe_unusual = 0,
			pe_unusual_offset = nil,

			wp = {
				enabled = false,
				id = 0,
				wear = 1,
				seed = tostring(WP.RNG.RandomSeed()),
			}
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
		if self.data.wp.enabled and self.quality != "strange" and self.quality != "selfmade" then
			//all quality strings are disabled on unusual paintkit items. yes, this appears to actually be the case in-game. what?? (https://steamcommunity.com/sharedfiles/filedetails/?id=3722656440)
			//ignoreQuality = true
		end
		
		// Start with the base name.
		local itemName = GetTFLanguageString(i.item_name) or i.item_name or "Unknown Item" //i don't *think* item_name is nil on any item defs? this is the tf2 code's failsafe for bad item defs

		//tf2 code here sets killstreak values, but this addon won't be doing those unless rubat implements $sheenmap someday

		if self.data.models.attached_festive then useProperName = false end

		local quality = ""
		if !ignoreQuality then 
			if self.strange_prefix then
				quality = (GetTFLanguageString(self.strange_prefix) or "") .. (GetTFLanguageString("#Strange_Spacer") or "")
			elseif self.quality != "normal" and self.quality != "paintkitweapon" then //tf2 code here checks nQuality > 0, which only filters out normal quality (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_constants.h#L516)
				if self.quality == "unique" then
					if useProperName and i.propername == 1 then 
						quality = GetTFLanguageString("#TF_Unique_Prepend_Proper") or quality
					end
				else // Any quality besides unique ignores "proper name" articles.
					quality = GetTFLanguageString("#" .. self.quality) or quality
					if quality != "" then quality = quality .. (GetTFLanguageString("#Rarity_Spacer") or "") end
				end
			end

			//tf2 code here sets strange ranks, which we only care about for campaign ranks and handle above, 
			//but also prepends strange rank onto strange unusual items, which in our use cases, only applies 
			//to weapons with both an unusual effect and a stat clock/australium enabled.
			if self.secondary_strange_quality then
				quality = (GetTFLanguageString("#strange") or "") .. " " .. quality
			end
		end

		local australium_skin = ""
		if self.aus_prefix then
			australium_skin = GetTFLanguageString("#ItemNameAustralium") or australium_skin
		end

		local festivized = ""
		if self.data.models.attached_festive then festivized = GetTFLanguageString("#ItemNameFestive") or festivized end

		local qualityformat = ""
		if (self.quality == "normal" or self.quality == "unique" or self.quality == "paintkitweapon" or ignoreQuality) and self.quality != "selfmade" then
			qualityformat = GetTFLanguageString("#ItemNameNormalOrUniqueQualityFormat") or qualityformat
		else
			qualityformat = GetTFLanguageString("#ItemNameQualityFormat") or qualityformat
		end

		//loc_scpy_safe( szQuality, CConstructLocalizedString( pLocalizationProvider->Find( pszQualityFormat ), szQuality, szIsFestivized, szKillStreak, szAustraliumSkin, szDuckBadge ) );
		// Strange Unusual Festive Killstreak Australium ducks
		qualityformat = string.Replace(qualityformat, "%s1", quality)
		qualityformat = string.Replace(qualityformat, "%s2", festivized)
		qualityformat = string.Replace(qualityformat, "%s3", "") //killstreak
		qualityformat = string.Replace(qualityformat, "%s4", australium_skin)
		qualityformat = string.Replace(qualityformat, "%s5", "") //duck journal rank
		quality = qualityformat

		if self.data.wp.enabled then
			local paintKitStr = WP.Proto.Schema.GetPaintkitByDefindex(self.data.wp.id)
			if paintKitStr and paintKitStr.header then
				paintKitStr = WP.Proto.Localization.GetWarpaintName(paintKitStr.header.name, paintKitStr.locDesctoken)
			else
				paintKitStr = nil
			end
			if paintKitStr then
				//Based off Econ_ConcatPaintKitName (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L543)
				local format = GetTFLanguageString("#ToolPaintKit_ItemDescFormat") or "%s1 %s2"
				format = string.Replace(format, "%s1", paintKitStr)
				format = string.Replace(format, "%s2", itemName)
				itemName = format
			end
		end

		//note: in the tf2 code, at the very top of this method, "ItemNameFormat" is set as the default value, and a comment mentions 
		//using a different format for names with an article, but it never actually does this or changes this value anywhere
		local format = GetTFLanguageString("#ItemNameFormat")
		if format then
			format = string.Replace(format, "%s1", quality)
			format = string.Replace(format, "%s2", itemName)
			format = string.Replace(format, "%s3", "") //craft index
			format = string.Replace(format, "%s4", "") //crate series
			format = string.Replace(format, "%s5", "") //tool target name
			format = string.Replace(format, "%s6", "") //dynamic recipe output name
			return format
		else
			return "Unknown Item" //yeah, again, this is how tf2 code does it, if it can't find the localization pattern then it just defaults to "Unknown Item" even if it found a real name earlier (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L1013-L1030)
		end

	end

	function PANEL:UpdateItemDescription()

		//based on CEconItemDescription::GenerateDescriptionLines https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L347

		local desc = {}
		local i = TF2Items.items[self.data.id]
		if !i then
			if !isstring(self.data.id) then
				table.insert(desc, {str = "Valve item ID \"" .. self.data.id .. "\" not found.\nThis shouldn't happen, report this bug!", col = desc_colors.neutral})
			else
				table.insert(desc, {str = "Custom item ID \"" .. self.data.id .. "\" not found.\nThis could be from an addon that isn't mounted, a local custom item that was deleted, or another player's custom item from a dupe or save.", col = desc_colors.neutral})
			end
			return desc 
		end

		if self.rarity then
			//Item rarity; based on CEconItemDescription::Generate_ItemRarityDesc https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L1521
			
			local tooltip = "#TFUI_InvTooltip_Rarity"
			if !self.data.wp.enabled then tooltip = "#TFUI_InvTooltip_RarityNoWear" end
			tooltip = GetTFLanguageString(tooltip)
			if tooltip then
				tooltip = string.Replace(tooltip, "%s1", GetTFLanguageString("#" .. TF2Items.rarities[self.rarity].loc_key) or "")
				tooltip = string.Replace(tooltip, "%s2", GetTFLanguageString("#" .. i.item_type_name) or "")
				if !self.data.wp.enabled then
					tooltip = string.Replace(tooltip, "%s3", GetTFLanguageString(wear_strings[0]))
				else
					tooltip = string.Replace(tooltip, "%s3", GetTFLanguageString(wear_strings[self.data.wp.wear]))
				end
				table.insert(desc, {str = tooltip, col = rarity_colors[self.rarity]})
			end
		else
			//Item level; based on CEconItemDescription::Generate_ItemLevelDesc, which calls CEconItemDescription::Generate_ItemLevelDesc_Default (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L1252);
			//the former also has a use case for showing strange ranks in place of levels, but this addon doesn't need those; 
			//all we need from that method is the stat clock attrib, which we'll do below.
			
			local typeName = GetTFLanguageString(i.item_type_name)
			if typeName then
				local level = math.random(i.min_ilevel or 1, i.max_ilevel or 1)

				//tf2 code has a case here where if an item has no typeName, the attribute "force_level_display" can 
				//make it use the "ItemTypeDescNoLevel" format (just "Level X") instead of returning nothing (or doing 
				//any of the below checks), but nothing in items_game uses this attribute, so don't bother

				//tf2 code here also has a case for items with a override_item_level_desc_string attribute that makes
				//them use the "ItemTypeDescCustomLevelString_MvMTour" format (Tour No. X typeName) but nothing uses this

				if i.static_attrs and i.static_attrs["limited quantity item"] == 1 then
					local format = GetTFLanguageString("#ItemTypeDescLimited")
					if format then
						format = string.Replace(format, "%s1", level)
						format = string.Replace(format, "%s2", typeName)
						format = string.Replace(format, "%s3", GetTFLanguageString("#LimitedQualityDesc") or "")
						table.insert(desc, {str = format, col = desc_colors.ItemLimitedQuantity})
					end
				else
					local format = GetTFLanguageString("#ItemTypeDesc")
					if format then
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
			local rank = GetTFLanguageString("#Attrib_stattrakmodule")
			if rank then
				rank = string.Replace(rank, "%s1", GetTFLanguageString("#KillEaterRank0") or "")
			end
			table.insert(desc, {str = rank, col = quality_colors.strange})
		end

		//TF2 code here does Generate_CraftTag, we don't care about this

		//Current style, based on CEconItemDescription::Generate_StyleDesc (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L1268)
		//Only do this if this icon corresponds to a specific item, otherwise do the store-type list of all the styles below
		if self.entity and i.visuals and i.visuals.styles and !i._call_styles_animations then
			local style = GetTFLanguageString(i.visuals.styles[self.data.style].name)
			if style then
				table.insert(desc, {str = string.Replace(GetTFLanguageString("#Econ_Style_Desc") or "", "%s1", style), col = desc_colors.level})
			end
		end

		//Paint name, based on CEconItemDescription::Generate_Painted (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L2402)
		if self.data.paint.enabled and self.data.paint.override[false] == 0 and !(self.default_paint and self.data.paint.col[false] == self.default_paint[false]) then
			local paint = str_custom
			for k, v in ipairs (paints) do
				if v[1] == self.data.paint.col[false] and v[2] == self.data.paint.col[true] then
					paint = GetTFLanguageString(v.name)
					break
				end
			end
			if paint then table.insert(desc, {str = string.Replace(GetTFLanguageString("#Econ_Paint_Name") or "", "%s1", paint or ""), col = desc_colors.level}) end
		end

		//Holiday restriction, based on CEconItemDescription::Generate_HolidayRestriction https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L1447
		//In practice, the only one used by items this addon can spawn is halloween_and_full_moon
		if i.holiday_restriction then
			table.insert(desc, {str = GetTFLanguageString("Econ_holiday_restriction_" .. i.holiday_restriction), col = desc_colors.negative}) //this uses LocalizedAddDescLine in tf2 code, which falls back to the raw string on fail if there's no #, which there isn't for this string (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L1462-L1465)
		end

		//TF2 code here does Generate_SaxxyAwardDesc (specific category an award is for), we don't care about this

		//Item attributes, based approximately on CEconItemDescription::Generate_VisibleAttributes and various related methods (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L3415)
		local sorted_attribs = {}
		local effect_types = { //order from https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_schema.h#L694
			[1] = {name = "unusual", color = quality_colors.rarity4},
			//"strange" is here too, but currently the only attrib that's strange-colored is hidden, so skip this for now
			[2] = {name = "neutral", color = desc_colors.neutral},
			[3] = {name = "positive", color = desc_colors.positive},
			[4] = {name = "negative", color = desc_colors.negative},
		}
		local function SortAttrib(attrib, val)
			if attrib == "set supply crate series" and i.static_attrs["hide crate series number"] then return end //yes, tf2 code does this at the attrib processing level (CEconItemDescription::CVisibleAttributeDisplayer::Finalize (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L3397C6-L3397C64)). dumb!!
			local id = TF2Items.attribute_ids_by_name[attrib]
			local _attrib = TF2Items.attributes[id]
			if !_attrib or !_attrib.description_string or _attrib.hidden == 1 then return end
			local str = GetTFLanguageString(_attrib.description_string)
			if !str then return end

			//based on formatting code from CEconAttributeDescription::InternalConstruct (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L3478)
			local f = _attrib.description_format 
			if f == "value_is_additive_percentage" then
				val = val * 100
			//elseif f == "value_is_account_id" then
			//	//not relevant
			//	return
			//elseif f == "value_is_additive" then
			//	//no changes needed
			elseif (f == "value_is_inverted_percentage" and val < 1) then
				val = (1 - val) * 100
			elseif f == "value_is_percentage" or f == "value_is_inverted_percentage" then
				val = (val * 100) - 100
			//elseif f == "value_is_date" then
			//	//not relevant
			//	return
			elseif f == "value_is_particle_index" then
				val = GetTFLanguageString("#Attrib_Particle" .. val)
				if !val then return end
			//value_is_killstreakeffect_index and value_is_killstreak_idleeffect_index work the same as above, but we're not implementing these unless rubat adds $sheenmap someday
			//elseif f == "value_is_or" then
			//	//no changes needed
			elseif f == "value_is_from_lookup_table" then
				if !TF2Items.string_lookups[attrib] then return end
				val = GetTFLanguageString(TF2Items.string_lookups[attrib][val])
				if !val then return end
			end
			if isnumber(val) then val = math.Round(val, 2) end

			str = string.Replace(str, "%s1", val)
			//additional wrapper for halloween spells (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L3643-L3653)
			if _attrib.is_user_generated then
				local ugt = GetTFLanguageString("#Econ_Attrib_UserGeneratedWrapper_" .. tostring(_attrib.is_user_generated))
				if ugt then
					str = string.Replace(ugt, "%s1", str)
				end
			end

			local k = _attrib.effect_type or "neutral"
			sorted_attribs[k] = sorted_attribs[k] or {}
			sorted_attribs[k][id] = str
		end
		if i.attributes then
			for k, v in pairs (i.attributes) do
				SortAttrib(k, v.value)
			end
		end
		if i.static_attrs then
			for k, v in pairs (i.static_attrs) do
				SortAttrib(k, v)
			end
		end
		if self.data.models.attached_festive then SortAttrib("is_festivized", 1) end
		if self.data.paint.enabled and self.data.paint.override[false] > 0 then SortAttrib("SPELL: set item tint RGB", self.data.paint.override[false] - 1) end
		if self.data.pe_unusual > 0 then SortAttrib("attach particle effect", self.data.pe_unusual) end
		//According to comments in CEconItemDescription::CVisibleAttributeDisplayer::SortAttributes() (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L3376),
		//attributes in the same effect_type category (neutral, positive, negative) are sorted by attribute id.
		for k, v in ipairs (effect_types) do
			if sorted_attribs[v.name] then
				for _, attrib in SortedPairs (sorted_attribs[v.name]) do
					table.insert(desc, {str = attrib, col = v.color})
				end
			end
		end

		//Add fake display attributes from custom items; these won't be sorted with real attributes, but no item should have both, so it's fine
		if i._display_attributes then
			for _, type in ipairs ({"neutral", "positive", "negative"}) do
				if i._display_attributes[type] then
					table.insert(desc, {str = i._display_attributes[type], col = desc_colors[type]})
				end
			end
		end
		
		//TF2 code here does Generate_QualityDesc (extra flavor text for community/self-made items), we don't care about this since no spawnable items use these qualities

		//Item description; based on CEconItemDescription::Generate_ItemDesc https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L1575
		if i.item_description then
			local item_desc = GetTFLanguageString(i.item_description)
			if item_desc then table.insert(desc, {str = item_desc, col = desc_colors.neutral}) end
		end

		//TF2 code here does Generate_Bundle, Generate_GiftedBy, Generate_DuelingMedal, Generate_MapContributor, Generate_MapStampBundleTooltip,
		//Generate_FriendlyHat, Generate_SquadSurplusClaimedBy, Generate_MvmChallenges, Generate_DynamicRecipe, Generate_XifierToolTargetItem,
		//Generate_LootListDesc, Generate_EventDetail; we don't care about any of these

		local done_spacer //this looks better if it shares a spacer with styles/classes below
		//Item set name, loosely based off CEconItemDescription::Generate_ItemSetDesc (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L2696); 
		//TF2 code here lists all the items in the set/collection and set bonus attributes, but we don't care about the latter,
		//and for the former, set items are listed elsewhere in dropdowns where players can actually spawn them
		if i._item_set then
			local item_set = GetTFLanguageString(TF2Items.item_sets[i._item_set].name) or i._item_set
			if !done_spacer then table.insert(desc, {str = "", col = desc_colors.level}) done_spacer = true end
			table.insert(desc, {str = item_set, col = desc_colors.ItemSetName})
		end

		//TF2 code here does Generate_UnusualifierEffectList; we don't care about this

		//Item collection name; same as above, just show the collection name, not its contents like in CEconItemDescription::Generate_CollectionDesc (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L2810)
		local col = i._item_collection
		if !col and self.data.wp.enabled then
			//Get collection from paintkit
			col = paintkit_ids_to_collections[self.data.wp.id]
		end
		if col then
			col = GetTFLanguageString(TF2Items.item_collections[col].name) or col
			if !done_spacer then table.insert(desc, {str = "", col = desc_colors.level}) done_spacer = true end
			table.insert(desc, {str = col, col = desc_colors.neutral})
		end

		//TF2 code here does Generate_BonusContentDesc, Generate_ExpirationDesc, Generate_DropPeriodDesc, 
		//Generate_MarketInformation, Generate_DirectX8Warning; we don't care about any of these

		//In TF2 code, Generate_ItemDesc also does a list of styles for store previews; we want to co-opt this to add extra info to items in 
		//the browser that don't correspond to an attached entity. In our use case, it looks better if we do this after item sets instead of
		//further up with item descriptions.
		if !self.entity then
			if i.visuals and i.visuals.styles and table.Count(i.visuals.styles) > 1 and !i._call_styles_animations then
				//valve's method takes up too much space, make this a single line instead
				local str
				for k, v in SortedPairs (i.visuals.styles) do
					local name = GetTFLanguageString(v.name) or v.name
					if !name then
						if v.aus_prefix then
							name = string.Trim(GetTFLanguageString("#ItemNameAustralium") or "#ItemNameAustralium")
						elseif k == 0 then //assume this is the non-australium style for weapons with australium
							name = GetTFLanguageString("#TF_style0_normal") or "#TF_style0_normal"
						end
					end
					if !str then
						str = (GetTFLanguageString("#Store_AvailableStyles_Header") or "Available Styles:") .. " "
					else
						str = str .. ", "
					end
					str = str .. (name or "BAD UNHANDLED STYLE " .. k)
				end
				if !done_spacer then table.insert(desc, {str = "", col = desc_colors.level}) done_spacer = true end
				table.insert(desc, {str = str, col = desc_colors.level})
			end
			//Do class list here too, so that players can tell which classes can use unfamiliar items
			if i.used_by_classes and !i.used_by_classes.none then
				local str
				if table.Count(i.used_by_classes) == 9 then
					str = (GetTFLanguageString("#Store_ItemDesc_UsedBy") or "Used by:") .. " " .. (GetTFLanguageString("#Store_ItemDesc_AllClasses") or "All Classes")
				else
					for k, v in ipairs (classes) do //add class options in class order; this kind of sucks for listing a lot of classes but oh well
						if i.used_by_classes[v.longname] then
							if !str then
								str = (GetTFLanguageString("#Store_ItemDesc_UsedBy") or "Used by:") .. " "
							else
								str = str .. ", " //manually appending unlocalized commas here is good enough for valve, so it's good enough for us (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/client/tf/vgui/store/v2/tf_store_preview_item2.cpp#L922)
							end
							str = str .. (GetTFLanguageString(v.langstr) or string.NiceName(v.longname))
						end
					end
				end
				if !done_spacer then table.insert(desc, {str = "", col = desc_colors.level}) done_spacer = true end
				table.insert(desc, {str = str, col = desc_colors.level})
			end
			//Also list equip regions, to make it clear why items conflict with each other
			if i.equip_regions then
				local str
				for k, v in pairs (i.equip_regions) do
					if !str then
						str = (GetTFLanguageString("#TF_ImportFile_EquipRegionLabel") or "Equip Region") .. ": " //there's no localized version of "equip region" followed by a colon, so we make do 
					else
						str = str .. ", "
					end
					str = str .. string.NiceName(k) //equip regions aren't localized anywhere unfortunately, just show english names all the time
				end
				if !done_spacer then table.insert(desc, {str = "", col = desc_colors.level}) done_spacer = true end
				table.insert(desc, {str = str, col = desc_colors.level})
			end
		end

		//"Grayed out" reason, used when item has a conflict; this is based on CEconItemView::EnsureDescriptionIsBuilt() (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_view.cpp#L650-L674)
		//which is separate from the rest of the item description code
		if self.item_conflict then
			table.insert(desc, {str = "", col = desc_colors.negative})
			table.insert(desc, {str = GetTFLanguageString("#Econ_GreyOutReason_EquipRegionConflict"), col = desc_colors.negative})
		end

		return desc

	end

	function PANEL:AddItemText(pnl, text, font, col)
		
		local h = 0
		local max_w = popup_w-(popup_pad*2)
		local tab = string.Explode("\n", textWrap(text, font, max_w))
		for k, v in ipairs (tab) do
			//textWrap has an edge case where if a string has two spaces in a row, it won't get the width of the additional space.
			//This is bad because it thinks the text including the double-space is less wide than it is, so it doesn't wrap the
			//text where it should, and returns a string that's too long to fit here. 
			//This happens with: 528 The Short Circuit, 13217 Holographic Harvest Lahsuniya Ratna 2022
			local _w, _ = surface.GetTextSize(v)
			if _w > max_w then
				MsgN("got overlong description string: ", v)
				//Find the LAST space in the string to get the word that goes over the limit, and move it into the next line
				local _end, loops = 0, 0
				while true do
					loops = loops + 1
					if loops > 50 then MsgN("whoops") break end
					local _, _end2 = string.find(v, " ", _end+1, true)
					if _end2 != nil then
						_end = _end2
					else
						break
					end
				end
				tab[k+1] = string.sub(v, _end+1) .. " " .. (tab[k+1] or "")
				v = string.sub(v, 1, _end-1)
			end

			local label = pnl:Add("DLabel")
			label:Dock(TOP)
			label:SetFont(font)
			label:SetText(v)
			label:SetTextColor(col)
			label:SetAutoStretchVertical(true)
			label:SetContentAlignment(5) //center
			local _, _h = surface.GetTextSize(v)
			h = h + _h
		end
		return h

	end

	function PANEL:DrawPaintIcon(x, y, w, h, cols)

		//Draws multi-colored paint icons with a diagonal split down the middle, bbased off The Funny CItemMaterialCustomizationIconPanel::DrawQuad (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/client/econ/item_model_panel.cpp#L107 / https://www.youtube.com/watch?v=T-BoDW1_9P4&t=7m4s)
		//note: this function doesn't set the draw texture on its own, so that it can use the paint splat texture (for corner icons) or a solid color (for swatches)

		local fXScale = 1 / #cols
		local fXUpperLowerOffset = fXScale * 0.65
		for i, col in ipairs (cols) do
			i = i-1
			local fXOffsetL = i * fXScale
			local fXOffsetR = (i + 1) * fXScale

			// We shift our coordinates on the top slightly to the right (by fXUpperLowerOffset) and on
			// the bottom slightly to the left (also by fXUpperLowerOffset). The far left side can't move
			// away from 0 and the far right side can't move away from 1, so the edge case handling makes
			// this look uglier than it really is.
			local fXUL, fXUR, fXBL, fXBR
			if i == 0 then
				fXUL = fXOffsetL
				fXBL = fXOffsetL
			else
				fXUL = fXOffsetL + fXUpperLowerOffset
				fXBL = fXOffsetL - fXUpperLowerOffset
			end
			if i == #cols - 1 then
				fXUR = fXOffsetR
				fXBR = fXOffsetR
			else 
				fXUR = fXOffsetR + fXUpperLowerOffset
				fXBR = fXOffsetR - fXUpperLowerOffset
			end

			surface.SetDrawColor(col.x, col.y, col.z, 255)
			surface.DrawPoly({
				{x = x+(w*fXUL), y = y, u = fXUL, v = 0},
				{x = x+(w*fXUR), y = y, u = fXUR, v = 0},
				{x = x+(w*fXBR), y = y+h, u = fXBR, v = 1},
				{x = x+(w*fXBL), y = y+h, u = fXBL, v = 1}
			})
		end
			

	end

	function PANEL:PositionPopupPanel(pnl)

		//Keeps a popup panel contained within the right side of TF2ItemBrowser (never cover up the options list 
		//on the left side) but also centered on this item icon to the extent it can without going out-of-bounds.
		local w, h = pnl:GetSize()
		local i_w, i_h = self:GetSize()
		local x, y = TF2ItemBrowser.Right:ScreenToLocal(self:LocalToScreen(i_w/2, i_h))
		local b_w, b_h = TF2ItemBrowser.Right:GetSize()

		//by default, the panel is positioned below the icon, but won't go past the left side of the browser
		x = math.max(0,x-(w/2)) 
		//if the right side of the panel goes past the right side of the browser, then move it left
		if x+w > b_w then x = x - (x+w-b_w) end
		
		//if the icon is scrolled below the bottom of the list, then move the panel to the bottom of the browser
		if y-i_h > b_h then
			y = b_h-h
		//if the icon is scrolled above the top of the list, then move the panel to the top of the browser
		elseif y < 0 then
			y = 0
		//if the icon is visible, but the bottom of the panel goes beyond the bottom of the browser...
		elseif y+h > b_h then
			//...and it's too tall to fit above or below the icon, then center it the browser over the icon 
			if (y-i_h-h) < 0 then 
				y = (b_h/2)-(h/2)
			//...and it can fit above the icon, then reposition it above the icon
			else
				y = y-i_h-h
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

	//Custom draw func, used by both the DAdjustableModelPanel in the spawn window, and the icon texture renderer used for paintkits and such
	local LocalModelLights = {
		//based off spotlight code from here: https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/client/game_controls/basemodelpanel.cpp#L651-L657
		//which creates a LightDesc using initSpot: https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/public/mathlib/lightdesc.h#L71-L77
		{
			type = MATERIAL_LIGHT_SPOT,
			color = Vector(1,1,1),
			pos = Vector(0,0,200),
			dir = Vector(0,0,-1), //see commented-out version of LocalModelLights below; if model[1]'s pos is 0,0,0, then this value is always the same
			innerAngle = math.deg(0.035),
			outerAngle = math.deg(0.873),
		},
		{}, //blank entries are necessary to override any preexisting lightdescs in these slots
		{},
		{},
	}
	//This is a global function so that the custom item editor can use it as well
	DrawItemModels = function(x, y, w, h, models, particles, ang, CamPos, FOV)

		cam.Start3D(CamPos, ang, FOV, x, y, w, h, 5, 32768)
		render.SuppressEngineLighting(true)
		render.SetLightingOrigin(vector_origin)

		//use lighting from tf2 code (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/client/game_controls/basemodelpanel.cpp#L636-L646)
		//render.ResetModelLighting(0.4, 0.4, 0.4)
		render.SetAmbientLight(0.4, 0.4, 0.4)
		render.SetColorModulation(1, 1, 1)
		render.SetBlend(1)
		//Stupid hack: while these lighting parameters look correct on the vast majority of models, they're consistently too dark on this 
		//*one specific model*, which is a problem because we use it to render almost every paintkit icon. i can't fathom why this is happening,
		//but changing this one value gets us results that look pretty close to the TF2-generated icons when eyeballing it. it'll have to do.
		//Update: i'm pretty sure this is just caused by the lighting parameter issues with gmod warpaints; try removing this when they're resolved
		if models[1].ModelLightingOverride == nil then
			models[1].ModelLightingOverride = models[1]:GetModel() == "models/items/paintkit_tool.mdl" //cache this so that the modelpanel doesn't run this check every single frame
		end
		for i = 0, 5 do
			if !models[1].ModelLightingOverride then
				render.SetModelLighting(i, 0.4, 0.4, 0.4)
			else
				render.SetModelLighting(i, 0.875, 0.875, 0.875)
			end
		end
		//variant of LocalModelLights to use if model is offset
		--[[local mins, maxs = models[1]:GetRenderBounds()
		local pos = Vector(0,0,200)
		local point_at = models[1]:GetPos() + Vector(0,0,(maxs.z-mins.z)*0.75)
		local LocalModelLights = {
			//based off spotlight code from here: https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/client/game_controls/basemodelpanel.cpp#L651-L657
			//which creates a LightDesc using initSpot: https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/public/mathlib/lightdesc.h#L71-L77
			{
				type = MATERIAL_LIGHT_SPOT,
				color = Vector(1,1,1),
				pos = pos,
				dir = (point_at-pos):GetNormalized(),
				innerAngle = math.deg(0.035),
				outerAngle = math.deg(0.873),
			},
			{}, //blank entries are necessary to override any preexisting lightdescs in these slots
			{},
			{},
		}]]
		render.SetLocalModelLights(LocalModelLights)
		render.ClearDepth(false)

		for k, v in ipairs (models) do
			//Update color of halloween spell paints
			if v.ProxyentPaintColor and v.ProxyentPaintColor.Override then
				v.ProxyentPaintColor.Color = ProxyentPaintColor_GetOverrideColor(v.ProxyentPaintColor.Override)/255
			end
			//Render all models
			v:DrawModel()
			v:FrameAdvance(FrameTime())
		end
		//Render particles
		for k, v in ipairs (particles) do
			v:Render()
		end

		render.SuppressEngineLighting(false)
		cam.End3D()

	end

	//This is a global function so that the custom item editor can use it as well
	DoItemModelCamera = function(models, icon)

		local attach
		if models[1] then attach = models[1]:GetAttachment(models[1]:LookupAttachment("icon_camera")) end
		if attach and icon and !isstring(icon.data.id) and !TF2Items.items[icon.data.id]._disable_icon_camera and !icon.data.models.wearable and !icon.data.models.wearable_2 and !icon.data.models.taunt_prop then
			//attach.Ang.r = 0 //allowing roll messes with the modelpanel controls a bit, but makes the default pos look better
			return {
				pos = attach.Pos, 
				fov = 54, //from resource\ui\econ\itemmodelpanel.res
				ang = attach.Ang
			} 
		else
			//copy of PositionSpawnIcon from lua\includes\util\client.lua, except we get the combined bounds of all models
			local mn, mx
			for k, v in ipairs (models) do
				if v.DontUseBoundsForCamera then continue end
				local mn2, mx2 = v:GetRenderBounds()
				mn2, mx2 = v:GetRotatedAABB(mn2, mx2)
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

				//rotate the angle to account for rotated models
				local _, ViewAngle = LocalToWorld(vector_origin, Angle( 25, 220, 0 ), vector_origin, models[1]:GetAngles())
				local ViewPos = models[1]:GetPos() + ViewAngle:Forward() * size * -15

				//Apply the changes to the camera
				return {
					pos = ViewPos + middle,
					fov = 4, // + size * 0.04, //to compensate for GetRotatedAABB bloating up the size a bit, don't add extra fov bloat from size, this isn't necessary for any of these models
					ang = ViewAngle
				}
			end
		end
		//fallback values in case there's no models
		return {
			pos = vector_origin, 
			fov = 90, 
			ang = angle_zero
		}
		
	end

	function PANEL:CreateItemModelsAndParticles(bailfunc)

		local models = {}
		local particles = {}

		local i = TF2Items.items[self.data.id] or {}
		local vis = GetItemModelVisuals(self.data)
		//if this icon is for an invalid item (i.e. a custom item from an outdated save), then show the entity's current model in the panel.
		if !TF2Items.items[self.data.id] and IsValid(self.entity) then
			vis.models.item = self.entity:GetModel()
			self.data.models.item = true
		end
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
					model = "models/player/" .. classes[self.data.class].shortname .. ".mdl"
				end
				if self.data.team then skin = 1 end
				ent = ClientsideModel(model, RENDERGROUP_OTHER)
				if !IsValid(ent) then continue end

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
				if !IsValid(ent) then continue end

				ent:SetSkin(vis.skin)
				if v.role == "item" then
					for k, v in pairs (vis.item_bg) do
						ent:SetBodygroup(ent:FindBodygroupByName(k), v)
					end
					//ent:SetPos(Vector(110,5,5)) //default model pos from CBaseModelPanel, which backpack icons derive from? commented out because this seems to make lighting slightly less game-accurate than only using the below (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/client/game_controls/basemodel_panel.cpp#L95)
					ent:SetAngles(Angle(10,130,0)) //model angles from resource\ui\econ\itemmodelpanel.res; produces the most game-accurate lighting 
					local mins, maxs = ent:GetRenderBounds()
					mins, maxs = ent:GetRotatedAABB(mins, maxs)
					offset_height_base = maxs.z
				elseif v.attach_num then
					ent:SetParent(models[1])
					ent:AddEffects(EF_BONEMERGE)
				elseif v.role == "stat_clock" then
					ent:SetParent(models[1])
					ent:AddEffects(EF_BONEMERGE)
					local scl = vis.stat_clock_scale or 1
					ent:ManipulateBoneScale(ent:LookupBone("c_weapon_stattrack"), Vector(scl,scl,scl))
					//TODO: *maybe* let players set the number shown by the stat clock? this is a really tiny
					//detail, and it would need both its own gui and either a bunch of new materials or a whole 
					//custom matproxy, is this worth the trouble?
				else
					ent:SetAngles(Angle(10,130,0))
					//If we're rendering both the base item and wearables, then reposition wearables above the item
					if offset_height_base then
						local mins, maxs = ent:GetRenderBounds()
						mins, maxs = ent:GetRotatedAABB(mins, maxs)
						offset_height = offset_height_base - mins.z
					end
					if offset_height then
						ent:SetPos(ent:GetPos() + ent:GetAngles():Up() * offset_height)
					//else
					//	ent:SetPos(ent:SetPos(Vector(110,5,5)))
					end
				end

				if i.visuals and i.visuals.styles and i.visuals.styles[self.data.style] then
					local anim = i.visuals.styles[self.data.style]._anim
					if anim and anim[v.role] then
						//we have to give the engine a nudge here to make it load the sequence info for the model, 
						//otherwise LookupSequence won't return anything useful until we spawn the model in the world
						ent:GetSequenceInfo(0)

						ent:ResetSequence(ent:LookupSequence(anim[v.role]))
						local info = ent:GetSequenceInfo(ent:LookupSequence(anim[v.role]))
						ent:SetRenderBounds(info.bbmin, info.bbmax)
					end
				end

				//material overrides
				local mat
				if self.data.fx == EFFECT_UBER then
					if !self.data.team then
						mat = "models/effects/invulnfx_red"
					else
						mat = "models/effects/invulnfx_blue"
					end
				elseif self.data.fx == EFFECT_GOLD then
					mat = "models/player/shared/gold_player"
				elseif self.data.fx == EFFECT_ICE then
					mat = "models/player/shared/ice_player"
				elseif i.visuals and i.visuals.material_override then
					mat = i.visuals.material_override
				end
				if mat then ent:SetMaterial(mat) end

				//paint matproxy
				if self.data.paint.enabled then
					local col = self.data.paint.col[self.data.team] or self.data.paint.col[false]
					local override = self.data.paint.override[self.data.team] or self.data.paint.override[false]
					if override == 0 then override = nil end
					ent.ProxyentPaintColor = {
						IsValid = function() return true end, 
						Color = Vector(col[1]/255, col[2]/255, col[3]/255),
						Override = override //used by DrawItemModels to update the override color
					}
				end

				//critglow and EFFECT_JARATE matproxy
				local col
				if self.data.crit.enabled and (v.role == "item" or v.role == "attached" 
				or v.role == "attached_festive" or v.role == "stat_clock") then
					col = self.data.crit.col[self.data.team] or self.data.crit.col[false]
				end
				if self.data.fx == EFFECT_JARATE then
					col = (col or Vector(1,1,1)) * jarate[self.data.team]
				end
				if col then
					ent.ProxyentCritGlow = {
						IsValid = function() return true end, 
						Color = col
					}
				end

				//crit spark particles
				if self.data.crit.enabled and v.role == "item" then
					if self.data.crit.sparks_rb then
						local pname = "critgun_weaponmodel_red"
						if self.data.team then pname = "critgun_weaponmodel_blu" end
						local part = CreateParticleSystem(ent, pname, PATTACH_ABSORIGIN_FOLLOW)
						if IsValid(part) then
							part:SetShouldDraw(false)
							table.insert(particles, part)
						end
					end
					if self.data.crit.sparks_c then
						local part = CreateParticleSystem(ent, "critgun_weaponmodel_colorable", PATTACH_ABSORIGIN_FOLLOW)
						if IsValid(part) then
							local col = self.data.crit.col[self.data.team] or self.data.crit.col[false]
							col = Vector(65,65,65) + (col * 3)	//we overbrighten the color value (second controlpoint) by a large amount because
							part:AddControlPoint(1, game.GetWorld(), PATTACH_WORLDORIGIN, 0, col)	//crit color values actually tend to be pretty low to avoid overpowering the texture
							part:SetShouldDraw(false)
							table.insert(particles, part)
						end
					end
				end

				//war paint
				if self.data.wp.enabled and v.role == "item"  then
					local instance
					local weaponType = WP.Weapons.GetFromModel(ent:GetModel())
					local _team = 0
					if self.data.team then _team = 1 end

					//war paint instance-building code adapted from lua\weapons\gmod_tool\stools\warpaint.lua's TOOL:LeftClick()
					if weaponType then
						-- Try to build a full multi-layer instance if we have a warpaint ID
						instance = WP.WarpaintData.BuildInstance(
							self.data.wp.id,
							weaponType,
							self.data.wp.seed,
							self.data.wp.wear,
							_team
						)
						if instance then
							-- Set the matIndex since BuildInstance doesn't set it
							instance.matIndex = WP.Weapons.GetMatIndex(weaponType)
						end
					end
					//the fallback looks nothing like how the war paint will ever look in tf2, don't bother	
					--[[-- Fallback to simple instance if multi-layer failed or wasn't available
					if !instance then
						MsgN(i.name, " using warpaint fallback, not good")
						local pattern
						for k, v in pairs (WP.WarpaintData.GetUniqueWarpaints()) do
							if v.id == self.data.wp.id then
								pattern = v.primaryTexture
								break
							end
						end
						instance = WP.WarpaintInstance.New({
							patternId = pattern or "color/white", //adapted from lua\warpaint\ui\cl_pattern_browser.lua's WP.UI.PopulateWarpaintTree(); don't waste reseurces constantly networking a separate var to hold onto the pattern value for this fallback, instead just grab it when it's needed
							seed = self.data.wp.seed,
							wearLevel = self.data.wp.wear,
							wear = WP.RNG.GenerateWearFromSeed(self.data.wp.seed, self.data.wp.wear),
							team = _team,
							weaponType = weaponType,
							matIndex = WP.Weapons.GetMatIndex(weaponType)
						})
					end]]
					if instance then
						//adapted from lua\autorun\client\cl_warpaint_init.lua's net.Receive("WP_Apply"), which is response to net msg sent by tool
						local success = WP.Materials.Apply(ent, instance)
						if success then
							ent:SetSkin(0)
						end
						ent.instance = instance
					end
				end
			end
			//add particle effects to both base items and fallbacks
			if v.role == "item" or v.role == "no_model_fallback" then
				local function AddEffect(tab)
					local name = tab.system
					if name:EndsWith("_teamcolor_red") and self.data.team then
						name = string.Replace(name, "_teamcolor_red", "_teamcolor_blue")
					end
					if tab.use_suffix_name then name = name .. "_" .. i.particle_suffix end
					if i.visuals and i.visuals.styles then
						if (name == "drg_pipe_smoke" and i.visuals.styles[self.data.style].use_smoke_particle_effect == 0)
						or (name == "coin_spin" and i.visuals.styles[self.data.style].use_coin_particle_effect == 0) then
							return
						end
					end

					local part
					if self.data.pe_unusual_offset or v.role == "no_model_fallback" then //https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/particle_property.cpp#L594
						ent:InvalidateBoneCache()
						local manip = Vector(0, self.data.pe_unusual_offset or 0, 0)
						local bone = ent:LookupBone("bip_head")
						if bone then
							manip = -manip
						else
							bone = ent:LookupBone("prp_helmet")
							if !bone then bone = ent:LookupBone("prp_hat") end
							if !bone then bone = 0 end
						end

						part = CreateParticleSystem(ent, name, PATTACH_CUSTOMORIGIN, 0)
						if IsValid(part) then
							part:SetControlPointEntity(0, ent)
							
							ent:DrawModel() //give model a nudge to make GetBoneMatrix return something
							bone = ent:GetBoneMatrix(bone)
							bone:Translate(manip)
							part:SetControlPoint(0, bone:GetTranslation())
							part:SetControlPointOrientation(0, bone:GetAngles())
						end
					else
						//try to use an attachment point by default, or fall back to root bone/origin otherwise (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_entity.cpp#L1749)
						local attachment = -1
						if tab.attachment then attachment = ent:LookupAttachment(tab.attachment) end
						if attachment > 0 then
							part = CreateParticleSystem(ent, name, PATTACH_POINT_FOLLOW, attachment)
						else
							if tab.attach_to_rootbone then
								part = CreateParticleSystem(ent, name, PATTACH_WORLDORIGIN + 1) //PATTACH_ROOTBONE_FOLLOW
							else
								part = CreateParticleSystem(ent, name, PATTACH_ABSORIGIN_FOLLOW)
							end
						end
					end
					if IsValid(part) then
						part:SetShouldDraw(false)
						table.insert(particles, part)
						for i = 1, 5 do
							if tab["control_point_" .. i] then
								local attachment = ent:LookupAttachment(tab["control_point_" .. i])
								if attachment > 0 then
									part:AddControlPoint(i, ent, PATTACH_POINT_FOLLOW, tab["control_point_" .. i]) //unlike CreateParticleSystem, this takes an attachment name, not id number
								end
							end
						end

						//try to add to pe+ crashcheck list; if there's multiple pcfs to associate with this effect,
						//then which one to blame is basically just a guess, but it's better than nothing, since all
						//these fx should only have 1 pcf unless there's a conflict with another game/addon going on
						local pcfs = PEPlus_FindPCFsFromEffect(name)
						if pcfs and pcfs[1] then
							local pcf = PEPlus_GetGamePCF(pcfs[1].pcf, pcfs[1].path)
							PEPlus_AddParticles_CrashCheck[pcf] = PEPlus_AddParticles_CrashCheck[pcf] or {}
							PEPlus_AddParticles_CrashCheck[pcf][part] = true
						end
					end
				end
				if self.data.pe_def then
					for k, v in ipairs (GetItemDefaultParticleEffects(self.data)) do
						//if spawning an effect right now could potentially cause a crash, bail out and try again later
						if table.Count(PEPlus_AddParticles_CrashCheck_ThrottledPCFs) > 0 then
							if bailfunc then bailfunc() end
							return
						end
						AddEffect(v)
					end
				end
				if self.data.pe_unusual > 0 then
					local tab = TF2Items.attribute_controlled_attached_particles_all[self.data.pe_unusual]
					if tab then
						//if spawning an effect right now could potentially cause a crash, bail out and try again later
						if table.Count(PEPlus_AddParticles_CrashCheck_ThrottledPCFs) > 0 then
							if bailfunc then bailfunc() end
							return
						end
						AddEffect(tab)
					end
				end
			end
			ent:SetNoDraw(true)
			ent:SetIK(false)
			table.insert(models, ent)
		end
		return models, particles

	end

	//This is a global function so that the custom item editor can use it as well
	CreateItemIconModelPanel = function(par)

		local mdl = par:Add("DAdjustableModelPanel")
		mdl.models = {}
		mdl.particles = {}
		mdl.PaintMargin = 0

		//Custom paint func using our DrawItemModels func
		function mdl:Paint(w, h)
			
			if !mdl.models or !mdl.models[1] or !mdl.particles then return end
			for k, v in ipairs (mdl.particles) do
				//if a particlesystem becomes invalid (i.e. a conflicting effect was loaded) then bail out and refresh the fx
				if !IsValid(v) then pnl.Refresh() break end
			end

			-- Get the panel's scissor rect, and apply it to model render
			local enabled, leftx, topy, rightx, bottomy = surface.GetScissorRect()
			render.SetScissorRect( leftx, topy, rightx, bottomy, enabled )

			local x, y = mdl:LocalToScreen(mdl.PaintMargin, mdl.PaintMargin)
			DrawItemModels(x, y, w-(mdl.PaintMargin*2), h-(mdl.PaintMargin*2), mdl.models, mdl.particles, mdl.aLookAngle, mdl.vCamPos, mdl.fFOV)
			mdl.LastPaint = RealTime() //this is in DModelPanel's Paint func, i'm not sure this does anything any more

			render.SetScissorRect( 0, 0, 0, 0, false )
		end

		//Modified OnMousePressed to make the orbit movement account for the rotation of the entity
		function mdl:OnMousePressed( mousecode )
			-- input.SetCursorPos does not work while main menu is open
			if ( !MENU_DLL and gui.IsGameUIVisible() ) then return end

			if ( mousecode != MOUSE_LEFT and mousecode != MOUSE_RIGHT ) then return end

			self:SetCursor( "none" )
			self:MouseCapture( true )
			self.Capturing = true
			self.MouseKey = mousecode

			self:SetFirstPerson( true )

			self:CaptureMouse()

			if ( !IsValid( self.Entity ) ) then
				self.OrbitPoint = vector_origin
				self.OrbitDistance = ( self.OrbitPoint - self.vCamPos ):Length()
				return
			end

			-- Helpers for the orbit movement
			local pos = self.Entity:GetPos() //new
			local ang = self.Entity:GetAngles() //new
			local mins, maxs = self.Entity:GetModelBounds()
			mins, maxs = self.Entity:GetRotatedAABB(mins, maxs) //new
			local center = ( mins + maxs ) / 2

			local hit1 = util.IntersectRayWithPlane( self.vCamPos, self.aLookAngle:Forward(), pos, ang:Forward() ) //changed
			self.OrbitPoint = hit1

			local hit2 = util.IntersectRayWithPlane( self.vCamPos, self.aLookAngle:Forward(), pos, ang:Up() ) //changed
			if ( ( !hit1 and hit2 ) or hit2 and hit2:Distance(pos) < hit1:Distance(pos) ) then self.OrbitPoint = hit2 end //changed

			local hit3 = util.IntersectRayWithPlane( self.vCamPos, self.aLookAngle:Forward(), pos, -ang:Right() ) //changed
			if ( ( ( !hit1 or !hit2 ) and hit3 ) or hit3 and hit3:Distance(pos) < hit2:Distance(pos) ) then self.OrbitPoint = hit3 end //changed

			self.OrbitPoint = self.OrbitPoint or center
			self.OrbitDistance = ( self.OrbitPoint - self.vCamPos ):Length()
		end
		//local function required by FirstPersonControls
		local function IsKeyBindDown(cmd)
			-- Yes, this is how engine does it for input.LookupBinding
			for keyCode = 1, BUTTON_CODE_LAST do
				if ( input.LookupKeyBinding( keyCode ) == cmd and input.IsKeyDown( keyCode ) ) then
					return true
				end
			end
			return false
		end
		//Modified FirstPersonControls to make camera movement account for the roll rotation of the camera (required by the wacky rotations set by icon_camera)
		function mdl:FirstPersonControls()
			local x, y = self:CaptureMouse()

			if ( self.MouseKey == MOUSE_LEFT ) then

				//don't scale camera movement with fov for left click (orbit), only right click (pan)
				local scale = 0.1
				x = x * -0.5 * scale
				y = y * 0.5 * scale

				if ( input.IsShiftDown() ) then y = 0 end

				//use RotateAroundAxis instead of just adding the angle, so that it accounts for roll rotation
				self.aLookAngle:RotateAroundAxis(-self.aLookAngle:Right(), y*4)
				self.aLookAngle:RotateAroundAxis(self.aLookAngle:Up(), x*4)

				self.vCamPos = self.OrbitPoint - self.aLookAngle:Forward() * self.OrbitDistance

				return
			end

			local scale = self:GetFOV() / 180
			x = x * -0.5 * scale
			y = y * 0.5 * scale

			-- Look around
			//use RotateAroundAxis instead of just adding the angle, so that it accounts for roll rotation
			self.aLookAngle:RotateAroundAxis(-self.aLookAngle:Right(), y)
			self.aLookAngle:RotateAroundAxis(self.aLookAngle:Up(), x)

			local Movement = vector_origin

			if ( IsKeyBindDown( "+forward" ) or input.IsKeyDown( KEY_UP ) ) then
				Movement = Movement + self.aLookAngle:Forward()
			end

			if ( IsKeyBindDown( "+back" ) or input.IsKeyDown( KEY_DOWN ) ) then
				Movement = Movement - self.aLookAngle:Forward()
			end

			if ( IsKeyBindDown( "+moveleft" ) or input.IsKeyDown( KEY_LEFT ) ) then
				Movement = Movement - self.aLookAngle:Right()
			end

			if ( IsKeyBindDown( "+moveright" ) or input.IsKeyDown( KEY_RIGHT ) ) then
				Movement = Movement + self.aLookAngle:Right()
			end

			if ( IsKeyBindDown( "+jump" ) or input.IsKeyDown( KEY_SPACE ) ) then
				Movement = Movement + self.aLookAngle:Up() //changed
			end

			if ( IsKeyBindDown( "+duck" ) or input.IsKeyDown( KEY_LCONTROL ) ) then
				Movement = Movement -  self.aLookAngle:Up() //changed
			end

			local speed = 0.5
			if ( input.IsShiftDown() ) then speed = 4.0 end

			self.vCamPos = self.vCamPos + Movement * speed * self:GetMovementScale()
		end

		return mdl

	end

	function PANEL:CreateSpawnPanel()

		local i = TF2Items.items[self.data.id] or {}
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
		
		local mdl = CreateItemIconModelPanel(pnl)
		pnl.ModelPanel = mdl
		mdl:SetSize(300,300)
		mdl.PaintMargin = 3 //set precisely to cut off the modelpanel at the edges of the GrayDialogBorder
		side_margins = (popup_w-300-popup_pad-popup_pad)/2 //force this panel to stay a square, and align all the other controls with it
		mdl:DockMargin(side_margins,betweencategories-5,side_margins,betweencategories)
		mdl:Dock(TOP)
		local old_Paint = mdl.Paint
		function mdl:Paint(w,h)
			GrayDialogBorder(0,0,w,h)
			old_Paint(mdl,w,h)
		end

		function pnl.Refresh()
			name_container:Clear()
			self:AddItemText(name_container, self.itemname, "TF2ItemBrowser_ItemName", rarity_colors[self.rarity] or quality_colors[self.quality])
			name_container:InvalidateLayout(true)
			name_container:SizeToChildren(false, true)

			//update these every time we open or refresh the panel, since they can change after the icon has been created
			if !IsValid(ent) then 
				self.data.team = TF2ItemBrowser.attopts.team.Value
				local _, f = TF2ItemBrowser.attopts.fx:GetSelected()
				self.data.fx = f
			end
			local vis = GetItemModelVisuals(self.data)

			for k, v in ipairs (mdl.models) do
				if IsValid(v) then v:Remove() end
			end

			for k, v in ipairs (mdl.particles) do
				if IsValid(v) then v:StopEmissionAndDestroyImmediately() end
			end

			local models, particles = self:CreateItemModelsAndParticles(function()
				timer.Simple(0.1, function() if IsValid(pnl) then pnl.Refresh() end end) //bail function
			end)
			mdl.models = models or {}
			mdl.particles = particles or {}
			mdl.Entity = mdl.models[1]

			//Only reset the camera if the values returned by DoItemModelCamera have changed (i.e. a model or animation changed)
			local cam = DoItemModelCamera(mdl.models, self)
			local docamera = mdl.old_cam == nil
			if mdl.old_cam then
				for k, v in pairs (cam) do
					if v != mdl.old_cam[k] then
						docamera = true
						break
					end
				end
			end
			if docamera then
				mdl:SetCamPos(Vector(cam.pos)) //use copies of pos/ang, otherwise the values in old_cam will change as the camera moves
				mdl:SetFOV(cam.fov)
				mdl:SetLookAng(Angle(cam.ang))
				mdl.old_cam = cam
			end

			//Hide the class selector if all classes use the same model (i.e. medals)
			//Also compare the bodygroups because of use_per_class_bodygroups.
			local should_show_class = false
			if i.used_by_classes then
				for k, v in pairs (i.used_by_classes) do
					if k != classes[self.data.class].longname then
						local vis2 = GetItemModelVisuals({id = self.data.id, class = class_longname_to_id[k], team = self.data.team, style = self.data.style})
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
							if istable(v) then
								for k2, v2 in pairs (v) do
									if vis.models[k][k2] != v2 then
										should_show_class = true
										break
									end
								end
							elseif vis.models[k] != v then
								should_show_class = true
								break
							end
						end
					end
				end
			end
			local par = pnl.class:GetParent()
			if !should_show_class and par:IsVisible() then
				par:SetVisible(false)
				par.stored_margin = {par:GetDockMargin()}
			elseif should_show_team and !par:IsVisible() then
				par:SetVisible(true)
				if par.stored_margin then
					par:DockMargin(par.stored_margin[1], par.stored_margin[2], par.stored_margin[3], par.stored_margin[4])
				end
			end

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
		checks:SetHeight(20)
		checks:Dock(TOP)
		checks.checks = {}
		for k, v in SortedPairs (self.data.models) do
			local check = TFStyleVGUI("DCheckBoxLabel", checks)
			check.model = k
			local text = string.NiceName(k)
			if k == "item" then
				text = GetTFLanguageString("#Item") or "Item"
			elseif k == "attached_festive" then
				text = GetTFLanguageString("#TF_FestivizerTool") or "Festivizer"
			end
			//no tf localization strings for "wearable" or "stat clock", unfortunately
			check:SetText(text)
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
			local combo = TFStyleVGUI("DComboBox", pnl)
			local _pnl = AddTFLabelToVGUI(combo, label)
			_pnl:Dock(TOP)
			_pnl:DockMargin(side_margins,0,side_margins,betweenitems)
			combo:SetSortItems(false)
			populatefunc(combo)
			function combo.OnSelect(_, index, value, data)
				if select_extras then select_extras(data) end
				combo.value = data
				pnl.OnSettingChanged()
			end
			return combo
		end

		pnl.class = AddDropdown(GetTFLanguageString("#TF_ImportFile_Models") or "Class:", function(drop)
			for k, v in ipairs (classes) do //add class options in class order
				if i.used_by_classes and i.used_by_classes[v.longname] then
					drop:AddChoice(GetTFLanguageString(v.langstr) or string.NiceName(v.longname), k, self.data.class == k)
				end
			end
		end, function(data)
			self.data.class = data
		end)

		if i.visuals and i.visuals.styles and table.Count(i.visuals.styles) > 1 then
			local name = (GetTFLanguageString("#Context_Style") or "Style") .. ":"
			if i._call_styles_animations then name = (GetTFLanguageString("#TF_ImportFile_AnimationSource") or "Animation") .. ":" end
			AddDropdown(name, function(drop)
				for k, v in SortedPairs (i.visuals.styles) do //this starts from 0 so we can't do ipairs
					local name = GetTFLanguageString(v.name, true) or v.name
					if !name then
						if v.aus_prefix then
							name = string.Trim(GetTFLanguageString("#ItemNameAustralium") or "#ItemNameAustralium")
						elseif k == 0 then //assume this is the non-australium style for weapons with australium
							name = GetTFLanguageString("#TF_style0_normal") or "#TF_style0_normal"
						end
					end
					drop:AddChoice(name or "BAD UNHANDLED STYLE " .. k, k, self.data.style == k)
				end
			end, function(data)
				self.data.style = data
			end)
		end

		if i.capabilities and i.capabilities.paintable == 1 then
			local drop = AddDropdown(string.Trim(string.Replace(GetTFLanguageString("#Econ_Paint_Name") or "Paint Color:", "%s1", "")), function(drop)
				drop:AddChoice(str_none, nil, !self.data.paint.enabled or (self.default_paint and self.data.paint.col[false] == self.default_paint[false]))
				drop:AddSpacer()
				for k, v in ipairs (paints) do
					local is_selected = self.data.paint.enabled and (self.data.paint.override[false] == v.override or (self.data.paint.col[false] == v[1] and self.data.paint.col[true] == v[2]))
					drop:AddChoice(GetTFLanguageString(v.name) or v.name, v, is_selected)
				end
				if drop:GetText() == "" then drop:SetText(str_custom) end
			end, function(data)
				if !data then
					if self.default_paint then
						self.data.paint.enabled = true
						self.data.paint.col = table.Copy(self.default_paint)
					else
						self.data.paint.enabled = false
						self.data.paint.col = {[false] = Vector(255,255,255)}
					end
					self.data.paint.override = {[false] = 0}
				else
					self.data.paint.enabled = true
					if data.override then
						self.data.paint.override = {[false] = data.override, [true] = data.override_2}
					else
						self.data.paint.override = {[false] = 0}
					end
					if data[1] then
						self.data.paint.col = {[false] = data[1], [true] = data[2]}
					end
				end
			end)
			function drop.OpenMenu()
				//If the menu still exists and hasn't been deleted, then just close it and don't open a new one.
				//This doesn't use the standard drop.Menu value because that would cause the menu to auto-close
				//when an option is selected.
				if IsValid(drop.container) then
					drop.container:Remove()
					return
				end

				local container = vgui.Create("DPanel", TF2ItemBrowser:GetParent())
				container:DockPadding(16,16,16,16)
				function container:Paint(w,h)
					LoadoutItemPopupBorder(0,0,w,h)
				end
				drop.container = container

				//Originally we placed container inside a DermaMenu(), like DProperty_VectorColor does (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/prop_vectorcolor.lua#L95-L98C51),
				//but this didn't work well because col's textentries were impossible to give keyboard focus this way,
				//so instead make the container behave like a DermaMenu.
				CloseDermaMenus()
				container:SetIsMenu(true)
				function container:GetDeleteSelf() return true end
				function container:OnRemove() 
					//fix keyboard focus getting stuck on col's textentries if we remove container while focused
					local chump = vgui.GetKeyboardFocus()
					if IsValid(chump) then chump:KillFocus() end
				end
				RegisterDermaMenuForClose(container)

				local text = vgui.Create("DLabel", container)
				text:SetContentAlignment(7) //top left
				text:SetAutoStretchVertical(true)
				text:SetFont("TF2ItemBrowser_ItemName")
				text:SetColor(gui_colors.TanLight)
				text:SetText(drop:GetParent().Label:GetText())
				text:Dock(TOP)
				text:DockMargin(0,0,0,8)
				text:SizeToContents()

				local close = vgui.Create("DButton", container)
				close:SetText("")
				close:SetSize(22,22)
				function close:Paint(w,h)
					close:SetPos(container:GetWide()-w-12, 12)
					if self.Depressed then
						surface.SetDrawColor(color_white)
					elseif self.Hovered then
						surface.SetDrawColor(gui_colors.LightRed)
					else
						surface.SetDrawColor(gui_colors.TanDark)
					end
					surface.SetMaterial(close_button)
					surface.DrawTexturedRect(0,0,w,h)
				end
				AddTFButtonSounds(close)
				function close:DoClick()
					container:Remove()
				end

				local size = 48
				local icons = vgui.Create("DIconLayout", container)
				icons:Dock(TOP)
				icons:SetSpaceX(4)
				icons:SetSpaceY(4)
				
				for k, v in pairs (drop.Choices) do
					local data = drop.Data[k]
					local button = vgui.Create("DButton", icons)
					button:SetSize(size, size)
					local name, col, col_2
					if data then
						name = GetTFLanguageString(data.name) or data.name
						if data[1] then
							col = data[1]
						end
						if data[2] then
							col_2 = data[2]
						end
					end
					button:SetText("")
					function button.DoClick()
						drop:ChooseOption(v, k)
						container.col.BeingUpdated = true
						local _col = self.data.paint.col[self.data.team] or self.data.paint.col[false]
						container.col:SetColor(Color(_col.x, _col.y, _col.z))
						container.col.BeingUpdated = nil
					end
					local tex_corner16 = surface.GetTextureID("gui/corner16")
					local tex_corner8 = surface.GetTextureID("gui/corner8")
					function button:Paint(w, h)
						//there aren't many border colors that are visible against *all* the paint options;
						//just pick two that work, regardless of tf2-authenticity, and make the more intense
						//one the "selected" color.
						local _col
						if button.Depressed or (drop:GetSelectedID() == k) then //highlight the currently selected option
							_col = gui_colors.LightRed
						elseif button.Hovered then
							_col = gui_colors.TanLight
						end
						if _col then
							draw.RoundedBox(12, 0,0,w,h, _col)
						end

						//if we successfully set a border color, then shrink down the color preview
						//so that the RoundedBox we just drew appears as a border around it.
						local bd = 0
						local c = 12-4
						local c_whole = 12
						local tex = tex_corner16
						local cornerw = (1/12)*c //clip off the edges of these corner textures, so that we can draw the sliced-in-half team colors at an angle that matches DrawPaintIcon
						if _col then
							bd = 4
							c = 8-1
							c_whole = 8
							tex = tex_corner8
							cornerw = (1/8)*c
						end

						local col = col
						local col_2 = col_2
						if (data and data.override) then
							col = ProxyentPaintColor_GetOverrideColor(data.override)
							if data.override_2 then
								col_2 = ProxyentPaintColor_GetOverrideColor(data.override_2)
							end
						end

						if col_2 then
							//there's no good way to get DrawPaintIcon to work with draw.RoundedBox, do this manually instead

							surface.SetDrawColor(col.x, col.y, col.z, 255)
							surface.SetTexture(tex)
							surface.DrawTexturedRectUV(bd,bd, c,c, 0,0,cornerw,cornerw) //top left corner
							surface.DrawTexturedRectUV(bd,h-bd-c, c,c, 0,cornerw,cornerw,0) //bottom left corner
							surface.DrawRect(bd,bd+c,c,h-bd-bd-c-c) //left space between corners
							draw.NoTexture()
							surface.DrawPoly({ //left triangle
								{x = bd+c, y = bd}, //upper left corner
								{x = w-bd-c, y = bd}, //upper right corner
								{x = bd+c, y = h-bd}, //lower left corner
							})

							surface.SetDrawColor(col_2.x, col_2.y, col_2.z, 255)
							surface.SetTexture(tex)
							surface.DrawTexturedRectUV(w-bd-c,bd, c,c, cornerw,0,0,cornerw) //top right corner
							surface.DrawTexturedRectUV(w-bd-c,h-bd-c, c,c, cornerw,cornerw,0,0) //bottom right corner
							surface.DrawRect(w-bd-c,bd+c,c,h-bd-bd-c-c) //right space between corners
							draw.NoTexture()
							surface.DrawPoly({ //right triangle
								{x = w-bd-c, y = bd}, //upper right corner
								{x = w-bd-c, y = h-bd}, //lower right corner
								{x = bd+c, y = h-bd}, //lower left corner
							})
						elseif col then
							//recreating this color table every frame sucks, but
							//it's the only way to handle the color-changing ones
							draw.RoundedBox(c_whole, bd,bd,w-bd-bd,h-bd-bd, {r = col.x, g = col.y, b = col.z, a = 255})
						else
							//custom appearance for "none" option
							draw.RoundedBox(c_whole, bd,bd,w-bd-bd,h-bd-bd, gui_colors.TanDarker)
							surface.SetDrawColor(gui_colors.LightRed)
							surface.SetMaterial(close_button_nocircle)
							local w2 = w * 0.75
							local h2 = h * 0.75
							surface.DrawTexturedRect((w-w2)/2, (h-h2)/2, w2, h2)
						end
					end
					AddTFButtonSounds(button)
					//These buttons are too small to add labels to, so do mouseover tooltips instead (but tf2-themed)
					AddTFStyleTooltip(button, name or v)
				end
				icons:SetSize(((size+4)*6)+16, 16+((size+4)*(math.ceil(#drop.Choices/6))))
				icons:InvalidateLayout()

				local col = TFStyleVGUI("DColorMixer", container)
				col:SetLabel("#tool.colour.color")
				col.label:SetDark(false)
				container.col = col
				col:SetAlphaBar(false)
				local _col = self.data.paint.col[self.data.team] or self.data.paint.col[false]
				col:SetColor(Color(_col.x, _col.y, _col.z))
				col.ValueChanged = function(_, _col)
					if container.col.BeingUpdated then return end
					_col = Vector(_col.r, _col.g, _col.b)
					//0,0,0 (and anything darker than 3,3,3) is used by the vmt to mean "no paint color", which means it'll get overwritten by the hat's
					//default color, so if the player is trying to paint something pure black, then redirect it to a color that actually works.
					if _col.x < 3 and _col.y < 3 and _col.z < 3 then
						_col = Vector(3,3,3)
					end
					self.data.paint.enabled = true
					self.data.paint.override = {[false] = 0}
					self.data.paint.col = {[false] = _col}
					drop.selected = nil //un-highlight the currently selected option
					drop:SetText(str_custom)
					pnl.OnSettingChanged()
				end
				col:DockMargin(0,16,0,0)
				col:InvalidateChildren(true)
				col:Dock(TOP)

				container:SizeToChildren(true, true)
				container:SetHeight(text:GetTall() + 8 + icons:GetTall() + 16 + col:GetTall() + 16 - 4) //why doesn't SizeToChildren do this right?
				container:SetWide(container:GetWide() - 4) //no i don't know where the +4 bloat on either axis comes from
				container:IsMouseInputEnabled(true)
				container:InvalidateLayout()

				local x, y = drop:LocalToScreen(drop:GetWide(), 0)
				if x + container:GetWide() > ScrW() then x = ScrW() - container:GetWide() end
				if y + container:GetTall() > ScrH() then y = ScrH() - container:GetTall() end
				container:SetPos(x, y)
			end
		end

		//Show critglow option for items that are equipped as non-passive weapons in TF2, and have a valid model to apply it to
		local wep_slots = {primary = true, secondary = true, melee = true, utility = true, pda = true, pda2 = true, building = true, _custom_weapon = true}
		if (wep_slots[i.item_slot] and i.anim_slot != "FORCE_NOT_USED" and self.data.models.item != nil) or (i.item_slot == "action" and i.act_as_weapon) then
			local drop = AddDropdown("Crit Glow Color:", function(drop) //no tf localization string for this
				drop:AddChoice(str_none, nil, !self.data.crit.enabled)
				drop:AddSpacer()
				for k, v in ipairs (critglows) do
					local is_selected = self.data.crit.enabled and self.data.crit.col[false] == v[1] and self.data.crit.col[true] == v[2]
					drop:AddChoice(GetTFLanguageString(v.name) or v.name, v, is_selected)
				end
				if drop:GetText() == "" then drop:SetText(str_custom) end
			end, function(data)
				if !data then
					self.data.crit.enabled = false
					self.data.crit.col = {[false] = Vector(1,1,1)}
					self.data.crit.sparks_rb = false 
					self.data.crit.sparks_c = false
				else
					self.data.crit.enabled = true
					self.data.crit.col = {[false] = data[1], [true] = data[2]}
					self.data.crit.sparks_rb = data.sparks_rb
					self.data.crit.sparks_c = false
				end
			end)
			function drop.OpenMenu()
				//If the menu still exists and hasn't been deleted, then just close it and don't open a new one.
				//This doesn't use the standard drop.Menu value because that would cause the menu to auto-close
				//when an option is selected.
				if IsValid(drop.container) then
					drop.container:Remove()
					return
				end

				local container = vgui.Create("DPanel", TF2ItemBrowser:GetParent())
				container:DockPadding(16,16,16,16)
				function container:Paint(w,h)
					LoadoutItemPopupBorder(0,0,w,h)
				end
				drop.container = container

				//Originally we placed container inside a DermaMenu(), like DProperty_VectorColor does (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/prop_vectorcolor.lua#L95-L98C51),
				//but this didn't work well because col's textentries were impossible to give keyboard focus this way,
				//so instead make the container behave like a DermaMenu.
				CloseDermaMenus()
				container:SetIsMenu(true)
				function container:GetDeleteSelf() return true end
				function container:OnRemove() 
					//fix keyboard focus getting stuck on col's textentries if we remove container while focused
					local chump = vgui.GetKeyboardFocus()
					if IsValid(chump) then chump:KillFocus() end
				end
				RegisterDermaMenuForClose(container)

				local text = vgui.Create("DLabel", container)
				text:SetContentAlignment(7) //top left
				text:SetAutoStretchVertical(true)
				text:SetFont("TF2ItemBrowser_ItemName")
				text:SetColor(gui_colors.TanLight)
				text:SetText(drop:GetParent().Label:GetText())
				text:Dock(TOP)
				text:DockMargin(0,0,0,8)
				text:SizeToContents()

				local close = vgui.Create("DButton", container)
				close:SetText("")
				close:SetSize(22,22)
				function close:Paint(w,h)
					close:SetPos(container:GetWide()-w-12, 12)
					if self.Depressed then
						surface.SetDrawColor(color_white)
					elseif self.Hovered then
						surface.SetDrawColor(gui_colors.LightRed)
					else
						surface.SetDrawColor(gui_colors.TanDark)
					end
					surface.SetMaterial(close_button)
					surface.DrawTexturedRect(0,0,w,h)
				end
				AddTFButtonSounds(close)
				function close:DoClick()
					container:Remove()
				end

				//diconlayout and color picker copied from paint dropdown, bah
				local size = 48
				local icons = vgui.Create("DIconLayout", container)
				icons:Dock(TOP)
				icons:SetSpaceX(4)
				icons:SetSpaceY(4)

				for k, v in pairs (drop.Choices) do
					local data = drop.Data[k]
					local button = vgui.Create("DButton", icons)
					button:SetSize(size, size)
					local name, col, col_2
					if data then
						name = GetTFLanguageString(data.name) or data.name
						if name == "" then name = nil end
						if data[1] then
							col = Color(data[1].x, data[1].y, data[1].z, 255) //unlike paint selector, this can just be a Color value because we don't have to worry about animated color-changing paints
						end
						if data[2] then
							col_2 = Color(data[2].x, data[2].y, data[2].z, 255) //^
						end
					end
					button:SetText("")
					function button.DoClick()
						drop:ChooseOption(v, k)
						container.col.BeingUpdated = true
						local _col = self.data.crit.col[self.data.team] or self.data.crit.col[false]
						container.col:SetColor(Color(_col.x, _col.y, _col.z))
						container.col.BeingUpdated = nil
						container.check_c:SetChecked(self.data.crit.sparks_c)
						container.check_rb:SetChecked(self.data.crit.sparks_rb)
					end
					//button paint code also copied almost entirely from paint selector! lame!
					local tex_corner16 = surface.GetTextureID("gui/corner16")
					local tex_corner8 = surface.GetTextureID("gui/corner8")
					function button:Paint(w, h)
						//there aren't many border colors that are visible against *all* the paint options;
						//just pick two that work, regardless of tf2-authenticity, and make the more intense
						//one the "selected" color.
						local _col
						if button.Depressed or (drop:GetSelectedID() == k) then //highlight the currently selected option
							_col = gui_colors.LightRed
						elseif button.Hovered then
							_col = gui_colors.TanLight
						end
						if _col then
							draw.RoundedBox(12, 0,0,w,h, _col)
						end

						//if we successfully set a border color, then shrink down the color preview
						//so that the RoundedBox we just drew appears as a border around it.
						local bd = 0
						local c = 12-4
						local c_whole = 12
						local tex = tex_corner16
						local cornerw = (1/12)*c //clip off the edges of these corner textures, so that we can draw the sliced-in-half team colors at an angle that matches DrawPaintIcon
						if _col then
							bd = 4
							c = 8-1
							c_whole = 8
							tex = tex_corner8
							cornerw = (1/8)*c
						end

						if col_2 then
							//there's no good way to get DrawPaintIcon to work with draw.RoundedBox, do this manually instead

							surface.SetDrawColor(col)
							surface.SetTexture(tex)
							surface.DrawTexturedRectUV(bd,bd, c,c, 0,0,cornerw,cornerw) //top left corner
							surface.DrawTexturedRectUV(bd,h-bd-c, c,c, 0,cornerw,cornerw,0) //bottom left corner
							surface.DrawRect(bd,bd+c,c,h-bd-bd-c-c) //left space between corners
							draw.NoTexture()
							surface.DrawPoly({ //left triangle
								{x = bd+c, y = bd}, //upper left corner
								{x = w-bd-c, y = bd}, //upper right corner
								{x = bd+c, y = h-bd}, //lower left corner
							})

							surface.SetDrawColor(col_2)
							surface.SetTexture(tex)
							surface.DrawTexturedRectUV(w-bd-c,bd, c,c, cornerw,0,0,cornerw) //top right corner
							surface.DrawTexturedRectUV(w-bd-c,h-bd-c, c,c, cornerw,cornerw,0,0) //bottom right corner
							surface.DrawRect(w-bd-c,bd+c,c,h-bd-bd-c-c) //right space between corners
							draw.NoTexture()
							surface.DrawPoly({ //right triangle
								{x = w-bd-c, y = bd}, //upper right corner
								{x = w-bd-c, y = h-bd}, //lower right corner
								{x = bd+c, y = h-bd}, //lower left corner
							})
						elseif col then
							draw.RoundedBox(c_whole, bd,bd,w-bd-bd,h-bd-bd, col)
						else
							//custom appearance for "none" option
							draw.RoundedBox(c_whole, bd,bd,w-bd-bd,h-bd-bd, gui_colors.TanDarker)
							surface.SetDrawColor(gui_colors.LightRed)
							surface.SetMaterial(close_button_nocircle)
							local w2 = w * 0.75
							local h2 = h * 0.75
							surface.DrawTexturedRect((w-w2)/2, (h-h2)/2, w2, h2)
						end
					end
					AddTFButtonSounds(button)
					//These buttons are too small to add labels to, so do mouseover tooltips instead (but tf2-themed)
					AddTFStyleTooltip(button, name or v)
				end
				icons:SetSize(((size+4)*6)+16, 16+((size+4)*(math.ceil(#drop.Choices/6))))
				icons:InvalidateLayout()

				local check = TFStyleVGUI("DCheckBoxLabel", container)
				container.check_rb = check
				check:SetText("Team Sparks")
				check:DockMargin(0,16,0,0)
				check:Dock(TOP)
				check:SetChecked(self.data.crit.sparks_rb)
				check.OnChange = function(_, val)
					self.data.crit.enabled = true
					self.data.crit.sparks_rb = val
					pnl.OnSettingChanged()
				end

				local check = TFStyleVGUI("DCheckBoxLabel", container)
				container.check_c = check
				check:SetText("Colorable Sparks")
				check:DockMargin(0,8,0,0)
				check:Dock(TOP)
				check:SetChecked(self.data.crit.sparks_c)
				check.OnChange = function(_, val)
					self.data.crit.enabled = true
					self.data.crit.sparks_c = val
					pnl.OnSettingChanged()
				end

				local col = TFStyleVGUI("DColorMixer", container)
				col:SetLabel("#tool.colour.color")
				col.label:SetDark(false)
				container.col = col
				col:SetAlphaBar(false)
				local _col = self.data.crit.col[self.data.team] or self.data.crit.col[false]
				col:SetColor(Color(_col.x, _col.y, _col.z))
				col.ValueChanged = function(_, _col)
					if container.col.BeingUpdated then return end
					_col = Vector(_col.r, _col.g, _col.b)
					self.data.crit.enabled = true
					self.data.crit.col = {[false] = _col}
					drop.selected = nil //un-highlight the currently selected option
					drop:SetText(str_custom)
					pnl.OnSettingChanged()
				end
				col:DockMargin(0,16,0,0)
				col:InvalidateChildren(true)
				col:Dock(TOP)

				container:SizeToChildren(true, true)
				container:SetHeight(text:GetTall() + 8 + icons:GetTall() + 16 + col:GetTall() + 16 + container.check_rb:GetTall() + 8 + container.check_c:GetTall() + 16 - 4) //why doesn't SizeToChildren do this right?
				container:SetWide(container:GetWide() - 4) //no i don't know where the +4 bloat on either axis comes from
				container:IsMouseInputEnabled(true)
				container:InvalidateLayout()

				local x, y = drop:LocalToScreen(drop:GetWide(), 0)
				if x + container:GetWide() > ScrW() then x = ScrW() - container:GetWide() end
				if y + container:GetTall() > ScrH() then y = ScrH() - container:GetTall() end
				container:SetPos(x, y)
			end
		end

		local submenu
		local function SubmenuLoseFocus(pnl)
			if IsValid(pnl) and pnl != submenu --[[and !pnl.m_bIsMenuComponent]] then
				local par = pnl:GetParent()
				if !IsValid(par) or SubmenuLoseFocus(par) then
					return true
				end
			end
		end
		hook.Add("VGUIMousePressed", "TF2ItemBrowser_SubMenuLoseFocus", function(pnl, mcode)
			if IsValid(submenu) and SubmenuLoseFocus(pnl) then
				submenu:Remove()
			end
		end)
		local function AddSubDropdown(container)
			local drop2 = TFStyleVGUI("DComboBox", container)
			drop2:Dock(TOP)
			//Copy of the default DComboBox:OpenMenu() but with two changes to allow our dropdown-within-dropdown nonsense to work
			function drop2:OpenMenu(pControlOpener)
				if ( pControlOpener && pControlOpener == self.TextEntry ) then
					return
				end

				-- Don't do anything if there aren't any options..
				if ( #self.Choices == 0 ) then return end

				-- If the menu still exists and hasn't been deleted
				-- then just close it and don't open a new one.
				self:CloseMenu()

				//Change 1 of 2: Make sure that opening this menu doesn't close the parent dropdown, and associate it with the hook above
				if IsValid(submenu) then submenu:Remove() end
				submenu = DermaMenu(true, container)
				self.Menu = submenu

				--[[if ( self:GetSortItems() ) then
					local sorted = {}
					for k, v in pairs( self.Choices ) do
						local val = tostring( v ) --tonumber( v ) || v -- This would make nicer number sorting, but SortedPairsByMemberValue doesn't seem to like number-string mixing
						if ( string.len( val ) > 1 && !tonumber( val ) && val:StartsWith( "#" ) ) then val = language.GetPhrase( val:sub( 2 ) ) end
						table.insert( sorted, { id = k, data = v, label = val } )
					end
					for k, v in SortedPairsByMemberValue( sorted, "label" ) do
						local option = self.Menu:AddOption( v.data, function() self:ChooseOption( v.data, v.id ) end )
						if ( self.ChoiceIcons[ v.id ] ) then
							option:SetIcon( self.ChoiceIcons[ v.id ] )
						end
						if ( self.Spacers[ v.id ] ) then
							self.Menu:AddSpacer()
						end
					end
				else]]
					for k, v in pairs( self.Choices ) do
						//Change 2 of 2: Prevent the option's OnMouseRelease function from auto-closing the parent dropdown (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/dmenuoption.lua#L75-L86)
						local option = self.Menu:AddOption( v )
						option.DoClick = function()
							option.m_MenuClicking = false
							if IsValid(self) then
								self:ChooseOption( v, k )
								self:CloseMenu()
							end
						end
						if ( self.ChoiceIcons[ k ] ) then
							option:SetIcon( self.ChoiceIcons[ k ] )
						end
						if ( self.Spacers[ k ] ) then
							self.Menu:AddSpacer()
						end
					end
				//end

				local x, y = self:LocalToScreen( 0, self:GetTall() )

				self.Menu:SetMinimumWidth( self:GetWide())
				self.Menu:Open( x, y, false, self )

				self:OnMenuOpened( self.Menu )
			end
			return drop2
		end

		//Add unusual effect dropdown
		local u_hat = i.item_slot == "misc" or i.item_slot == "head" //originally i considered limiting this to "hat" and "whole_head" equip regions, and then manually adding overrides for items that can be unusual because they had these regions in the past, but this would require upkeep as regions get changed in the future. instead, just make all cosmetics unusual-able, no matter how absurd. here's the list of items i had, for reference: (Bonk Boy, Soldier's Stash, Exquisite Rack, Coldfront Curbstompers, Pyromancer's Mask, HazMat Headcase, Coffin Kit, Large Luchador, Hunter Heavy, Sleeveless in Siberia, Mining Light, Pencil Pusher, Brainiac Hairpiece, Blighted Beak, Das Hazmattenhatten,  Master's Yellow Belt, Villain's Veil, Soldered Sensei, Le Party Phantom, Noh Mercy, Antlers, Virtual Viewfinder, Polar Pullover, Captain Space Mann)
		local u_wep = i.particle_suffix
		if u_hat or u_wep then
			local drop = AddDropdown(string.Trim(GetTFLanguageString("#IT_UnusualTitle") or "Unusual effect:"), function(drop)
				drop:AddChoice(str_none, 0, self.data.pe_unusual == 0)
				drop:AddSpacer()
				if u_hat then
					for k, v in pairs (TF2Items.attribute_controlled_attached_particles.cosmetic_unusual_effects) do
						if k == 20 or k == 28 then continue end //map stamps and genteel smoke are not unusuals
						if v.system:EndsWith("_teamcolor_blue") then continue end
						drop:AddChoice(GetTFLanguageString("#Attrib_Particle" .. k) or v.system, k, self.data.pe_unusual == k)
					end
				end
				if u_wep then
					for k, v in pairs (TF2Items.attribute_controlled_attached_particles.weapon_unusual_effects) do
						if v.use_suffix_name and !PEPlus_FindPCFsFromEffect(v.system .. "_" .. i.particle_suffix) then continue end
						drop:AddChoice(GetTFLanguageString("#Attrib_Particle" .. k) or v.system, k, self.data.pe_unusual == k)
					end
				end
			end, function(data)
				self.data.pe_unusual = data
			end)
			function drop.OpenMenu()
				//If the menu still exists and hasn't been deleted, then just close it and don't open a new one.
				//This doesn't use the standard drop.Menu value because that would cause the menu to auto-close
				//when an option is selected.
				if IsValid(drop.container) then
					drop.container:Remove()
					return
				end

				local container = vgui.Create("DPanel", TF2ItemBrowser:GetParent())
				container:DockPadding(16,16,16,16)
				function container:Paint(w,h)
					LoadoutItemPopupBorder(0,0,w,h)
				end
				drop.container = container

				//Originally we placed container inside a DermaMenu(), like DProperty_VectorColor does (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/prop_vectorcolor.lua#L95-L98C51),
				//but this didn't work well because col's textentries were impossible to give keyboard focus this way,
				//so instead make the container behave like a DermaMenu.
				CloseDermaMenus()
				container:SetIsMenu(true)
				function container:GetDeleteSelf() return true end
				function container:OnRemove() 
					//fix keyboard focus getting stuck on col's textentries if we remove container while focused
					local chump = vgui.GetKeyboardFocus()
					if IsValid(chump) then chump:KillFocus() end
				end
				RegisterDermaMenuForClose(container)

				local text = vgui.Create("DLabel", container)
				text:SetContentAlignment(7) //top left
				text:SetAutoStretchVertical(true)
				text:SetFont("TF2ItemBrowser_ItemName")
				text:SetColor(gui_colors.TanLight)
				text:SetText(drop:GetParent().Label:GetText())
				text:Dock(TOP)
				text:DockMargin(0,0,0,8)
				text:SizeToContents()

				local close = vgui.Create("DButton", container)
				close:SetText("")
				close:SetSize(22,22)
				function close:Paint(w,h)
					close:SetPos(container:GetWide()-w-12, 12)
					if self.Depressed then
						surface.SetDrawColor(color_white)
					elseif self.Hovered then
						surface.SetDrawColor(gui_colors.LightRed)
					else
						surface.SetDrawColor(gui_colors.TanDark)
					end
					surface.SetMaterial(close_button)
					surface.DrawTexturedRect(0,0,w,h)
				end
				AddTFButtonSounds(close)
				function close:DoClick()
					container:Remove()
				end

				local categories = {}
				for k, v in ipairs ({"Series 1", "Series 2", "Halloween 2011", "Halloween 2012", "Robotic Boogaloo", "Series 3", "Halloween 2013", "Halloween 2014", "End of the Line", "Invasion"}) do
					categories[v] = {order = k, items = {}}
				end
				categories["Other"] = {order = 99999999, items = {}}
				for k, v in pairs (drop.Choices) do
					local data = drop.Data[k]
					local tab = TF2Items.attribute_controlled_attached_particles_all[data]
					if tab and tab.system then
						local name = tab.system
						if name:EndsWith("_teamcolor_red") and self.data.team then
							name = string.Replace(name, "_teamcolor_red", "_teamcolor_blue")
						end
						if tab.use_suffix_name then name = name .. "_" .. i.particle_suffix end

						if data == 406 and name == "coin_spin" then continue end //not an unusual, don't add this one
						
						local pcfs = PEPlus_FindPCFsFromEffect(name)
						if !pcfs then MsgN("no pcfs for effect ", name, "?") continue end
						local has_been_categorized = false
						local entry = {name = name, k = k, v = v}
						for k2, v2 in ipairs (pcfs) do
							local cat
							if v2.pcf == "particles/item_fx.pcf" then
								//All fx introduced before seasonal community updates are in this one pcf, so we have to hard-code their categories
								if data <= 19 then
									cat = "Series 1"
								elseif data <= 36 then
									cat = "Series 2"
								elseif data <= 40 then
									cat = "Halloween 2011"
								elseif data <= 47 then
									cat = "Halloween 2012"
								elseif data <= 62 then //series 3 fx are defined before roboog despite being added a month later?
									cat = "Series 3"
								elseif data <= 72 then
									cat = "Robotic Boogaloo"
								elseif data <= 80 then
									cat = "Halloween 2013"
								elseif data <= 86 then
									cat = "Halloween 2014"
								elseif data <= 90 then
									cat = "End of the Line"
								elseif data <= 99 then
									cat = "Invasion"
								else //this shouldn't happen
									cat = "Other"
								end
							elseif v2.pcf == "particles/invasion_unusuals.pcf" then
								cat = "Invasion"
							else
								//Generate categories for seasonal update pcfs automatically using the file name
								local season
								if string.StartsWith(v2.pcf, "particles/summer") then
									season = "summer"
								elseif string.StartsWith(v2.pcf, "particles/halloween") then
									season = "halloween"
								elseif string.StartsWith(v2.pcf, "particles/smissmas") then
									season = "smissmas"
								end
								if season and string.EndsWith(v2.pcf, "_unusuals.pcf") then
									local pcf = string.TrimLeft(v2.pcf, "particles/" .. season)
									pcf = string.TrimRight(pcf, "_unusuals.pcf")
									//Get the year number from the file path
									if #pcf != 4 then continue end //make sure the only part of the string left is the year; this will stop working in 8000 years
									pcf = tonumber(pcf)
									if !pcf then continue end

									cat = string.NiceName(season) .. " " .. tostring(pcf)
									if season == "summer" then
										season = 1
									elseif season == "halloween" then
										season = 2
									elseif season == "smissmas" then
										season = 3
									end
									categories[cat] = categories[cat] or {order = (pcf*10)+season, items = {}}
								end
							end //Note: This will also need handling for taunt fx pcfs if taunts are ever properly implemented
							if cat then
								entry.pcf = v2.pcf
								entry.path = v2.path
								table.insert(categories[cat].items, entry)
								has_been_categorized = true
								continue
							end
						end
						if !has_been_categorized then
							entry.pcf = pcfs[1].pcf
							entry.path = pcfs[1].path
							table.insert(categories["Other"].items, entry)
						end
					end
				end
				//Sort the categories by display order, and discard empty categories
				local cat2 = {}
				for k, v in pairs (categories) do
					if #v.items > 0 then 
						cat2[v.order] = {name = k, items = v.items}
					end
				end
				categories = cat2
				local function GetDefaultCategory()
					local default_category, fallback_default_category
					//By default, select the category containing the currently selected option
					for k, v in SortedPairs (categories) do
						for _, entry in ipairs (v.items) do
							local data = drop.Data[entry.k]
							if self.data.pe_unusual == data then
								default_category = k
								break
							end
						end
						if default_category then break end
						if !fallback_default_category then fallback_default_category = k end //if no category is selected, fall back to showing the first one
					end
					return default_category or fallback_default_category
				end

				local search_holder, icons
				if table.Count(categories) > 1 then
					search_holder = vgui.Create("DPanel", container) //we have enough horizontal space that we can put the category dropdown and search box next to each other
					search_holder.Paint = function() end
					search_holder:SetHeight(20)
					search_holder:Dock(TOP)
					local drop2, search

					drop2 = AddSubDropdown(search_holder) //calling this "drop" causes issues with the parent drop
					drop2:DockMargin(0,0,8,0)
					drop2:Dock(LEFT)
					drop2:SetSortItems(false)
					local selected = GetDefaultCategory()
					for k, v in SortedPairs (categories) do
						local name = v.name
						if string.StartsWith(name, "Summer") then
							name = string.Replace(name, "Summer", GetTFLanguageString("#TF_SteamWorkshop_Tag_Summer") or "Summer")
						elseif string.StartsWith(name, "Halloween") then
							name = string.Replace(name, "Halloween", GetTFLanguageString("#TF_SteamWorkshop_Tag_Halloween") or "Halloween")
						elseif string.StartsWith(name, "Smissmas") then
							name = string.Replace(name, "Smissmas", GetTFLanguageString("#TF_SteamWorkshop_Tag_Smissmas") or "Smissmas")
						elseif name == "Other" then
							name = GetTFLanguageString("#AbuseReport_TypeOther") or "Other" //using this localization string for "Other" items is a stretch but it's the best we've got
						end
						//No good localization strings for the other ones; there's a "Series" string used for crate series, but 
						//it's not translated the same as unusual series in every language, and the community updates only have
						//one for Invasion, which seems to be a generic community update string (#GameType_Community_Update)
						drop2:AddChoice(name, k, k == selected)
					end
					function drop2.OnSelect(_, index, value, data)
						search:SetText("")
						icons.SelectCategory(data)
					end

					search = TFStyleVGUI("DTextEntry", search_holder)
					search:Dock(FILL)
					search:SetPlaceholderText("#spawnmenu.search")
					search:SetUpdateOnType(true)
					search.OnValueChange = function(_, p)
						timer.Create("TF2ItemBrowser_SearchDelay_UFilter", 0.5, 1, function()
							if IsValid(icons) then
								if #p == 0 then
									//Search is empty, go back to using the category dropdown
									//This uses drop2.ChooseOptionID and not icons.SelectCategory in order to restore the text on the dropdown 
									local selected = GetDefaultCategory()
									for k, v in pairs (drop2.Data) do
										if v == selected then
											drop2:ChooseOptionID(k)
										end
									end
								else
									//Search is populated, stop using categories and show all matching options
									p = p:lower()
									local tab = {}
									for k, v in SortedPairs (categories) do
										for _, entry in ipairs (v.items) do
											if entry.v:lower():find(p, 1, true) then
												table.insert(tab, entry)
											end
										end
									end
									icons.RebuildIcons(tab)
									drop2:SetText("")
								end
							end
						end)
					end
					function search_holder.PerformLayout(_, w, h)
						drop2:SetWide((w/2)-4)
					end
				end

				local icons_holder = vgui.Create("DPanel", container)
				icons_holder.Paint = function() end
				local scroll = TFStyleVGUI("DScrollPanel",icons_holder)
				if search_holder then
					icons_holder:DockMargin(0,8,0,0)
				end
				icons_holder:Dock(TOP)
				scroll:Dock(FILL)

				local size = 128
				icons = vgui.Create("DIconLayout", scroll)
				icons:Dock(FILL)
				icons:SetSpaceX(8)
				icons:SetSpaceY(8)

				local slider
				if u_hat then
					slider = TFStyleVGUI("DNumSlider", container)
					slider:SetText(GetTFLanguageString("#GameUI_ParticleHatUseHead") or "Adjust Unusual")
					slider:SetMinMax(-8, 8) //yes, these are the min/max values (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/client/tf/vgui/class_loadout_panel.cpp#L307)
					slider:SetDefaultValue(0)
					slider:Dock(TOP)
					slider:DockMargin(0,16,0,0)
					slider:SetValue(self.data.pe_unusual_offset or 0)
					slider:SetEnabled(self.data.pe_unusual_offset != nil)
					function slider.OnValueChanged(_, val)
						if self.data.pe_unusual_offset != val and self.data.pe_unusual_offset != nil then
							self.data.pe_unusual_offset = val
							pnl.OnSettingChanged()
						end
					end
					
					//we have a lot of horizontal space to work with, so just place the check to enable the slider to the left of it
					check = TFStyleVGUI("DCheckBox", slider)
					check:DockMargin(0,0,6,0) //+6 on right emulates our custom DCheckBoxLabel style
					check:Dock(LEFT)
					check:SetZPos(-1) //dock this to the left of the slider's label
					check:SetChecked(self.data.pe_unusual_offset != nil)
					check.OnChange = function(_, val)
						if val then
							self.data.pe_unusual_offset = slider:GetValue()
							slider:SetEnabled(true)
						else
							self.data.pe_unusual_offset = nil
							slider:SetEnabled(false)
						end
						pnl.OnSettingChanged()
					end
				end

				function icons.SelectCategory(cat)
					icons.RebuildIcons(table.Copy(categories[cat].items))
				end
				function icons.RebuildIcons(tab)
					icons:Clear()
					//add "none" option to the start of every category or search
					table.insert(tab, 1, {k = 1, v = drop.Choices[1], name = drop.Choices[1], pcf = ""})
					for _, entry in ipairs (tab) do
						//reuse PE+ spawnicons for particle previews because they nicely manage the fx already
						local icon = vgui.Create("ContentIcon_PEPlus", icons)
						icon:Setup(entry.pcf, entry.name, entry.path)
						icon:SetSize(size, size)
						icon.disable_autohide = true //prevent the particle effect from getting auto-removed when the spawnmenu is closed
						icon.disable_icons = true //don't show corner icons for cpoint count or extra info, because they aren't useful here
						icon.disable_defaultcontenticon = true //don't run the default contenticon draw function (draws frame around icon, text label at bottom), we're going to draw our own
						function icon.DoRightClick() end
						function icon:DoClick()
							local pcf = PEPlus_GetGamePCF(self.pcf, self.path)

							//If the icon's effect is currently being overridden by another pcf's effect of the same name, reload the pcf on click instead (copied from PE+ code)
							if self:IsCurrentlyOverridden(pcf, self.name) then
								surface.PlaySound("common/wpn_select.wav")
								PEPlus_AddParticles(pcf, self.name) //crash prevention
							else
								drop:ChooseOption(entry.v, entry.k)
							end
						end
						local override = unusual_icon_overrides[entry.name]
						if override then
							icon.view = PEPlus_BoundsToView(override[1], override[2])
						end
						local old_Paint = icon.Paint
						function icon.Paint(_,w,h)
							//custom background
							local col = gui_colors._unu_default
							if icon.Depressed or self.data.pe_unusual == drop.Data[entry.k] then //highlight the currently selected option
								col = gui_colors._unu_depressed
							elseif icon.Hovered then
								col = gui_colors._unu_hovered
							end
							draw.RoundedBox(12, 0,0,w,h, col)

							old_Paint(icon,w,h)
							icon:SetTooltip(nil) //icon's paint func sets the tooltip, so we have to override this here

							//custom appearance for "none" option so it isn't just blank
							if entry.pcf == "" then
								surface.SetDrawColor(gui_colors.LightRed)
								surface.SetMaterial(close_button_nocircle)
								local w2 = w * 0.75
								local h2 = h * 0.75
								surface.DrawTexturedRect((w-w2)/2, (h-h2)/2, w2, h2)
							end
						end
						//custom text label; this is multiline so do the same textWrap approach as AddItemText
						local tab = {}
						for k, v in ipairs (string.Explode("\n", textWrap(entry.v, "TF2ItemBrowser_ItemDesc_Smaller", size - 8))) do
							//do these in reverse order because we're docking them to the bottom
							table.insert(tab, 1, v)
						end
						for k, v in ipairs (tab) do
							local label = icon:Add("DLabel")
							label:Dock(BOTTOM)
							label:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
							label:SetText(v)
							label:SetTextColor(gui_colors.TanLight)
							label:SetAutoStretchVertical(true)
							label:SetContentAlignment(5) //center
						end
						AddTFButtonSounds(icon)
					end
					local w, h = (size+8)*4, (size+8)*(math.ceil(#tab/4))
					icons:SetSize(w, h)
					icons:InvalidateLayout()
					icons_holder:SetSize(w, h)
					icons_holder:InvalidateLayout()
					scroll:InvalidateLayout()

					//Resize and reposition container whenever the category is changed
					local control_height = 0
					if search_holder then control_height = search_holder:GetTall() + 8 end
					if u_hat then control_height = control_height + 16 + slider:GetTall() end
					container:SetTall(text:GetTall() + 8 + control_height + h + 16 + 16) //why doesn't SizeToChildren do this right?
					if container:GetTall() > ScrH() then
						local diff = container:GetTall() - ScrH()
						icons_holder:SetTall(icons_holder:GetTall() - diff)
						container:SetTall(container:GetTall() - diff)
						w = w + scroll.VBar:GetWide() //SizeToChildren doesn't do this right either; calling it immediately never gets vbar width, while subsequent calls always get vbar width whether it's visible or not
					end
					container:SetWide(w + 16 + 8)

					container:IsMouseInputEnabled(true)
					container:InvalidateLayout()

					local x, y = drop:LocalToScreen(drop:GetWide(), 0)
					if x + container:GetWide() > ScrW() then x = ScrW() - container:GetWide() end
					if y + container:GetTall() > ScrH() then y = ScrH() - container:GetTall() end
					container:SetPos(x, y)
				end
				icons.SelectCategory(GetDefaultCategory())
			end
		end

		//Show toggle for default particle effects (cigar smoke, halo effect, earbud notes, etc.)
		local pe_def = GetItemDefaultParticleEffects(self.data)
		if #pe_def > 0 then
			local names = {}
			for k, v in ipairs (pe_def) do
				names[v._displayname or string.NiceName(v.system)] = true
			end
			local name
			for k, v in pairs (names) do
				if !name then
					name = ""
				else
					name = name .. ", "
				end
				name = name .. k
			end
			local check = TFStyleVGUI("DCheckBoxLabel", pnl)
			check:SetText("Add default particle effects (" .. name .. ")")
			check:Dock(TOP)
			check:DockMargin(side_margins,0,side_margins,betweenitems)
			check:SetChecked(self.data.pe_def)
			check.OnChange = function(_, val)
				self.data.pe_def = val
				pnl.OnSettingChanged()
			end
		end

		if i._paintkit and WP.Weapons.IsSupported(i.model_player) then
			local drop = AddDropdown((GetTFLanguageString("#TF_ItemPreview_ItemPaintkit") or "War Paint") .. ":", function(drop)
				drop:AddChoice(str_none, nil, self.data.wp.enabled == false)
				drop:AddSpacer()
				local tab = WP.WarpaintData.GetForWeaponType(WP.Weapons.GetFromModel(i.model_player))
				for k, v in ipairs (tab) do
					//MsgN(v.id, ", ", v.name, ", ", WP.Proto.Localization.GetWarpaintName(v.name, v.locToken), ", ", WP.Proto.Items.GetCollection(v.id, true), ", ", WP.Proto.Items.GetCollectionCategory(v.id))
					drop:AddChoice(WP.Proto.Localization.GetWarpaintName(v.name, v.locToken), v, self.data.wp.enabled and self.data.wp.id == v.id)
				end
			end, function(data)
				if !data then
					self.data.wp.enabled = false
				else
					self.data.wp.enabled = true
					self.data.wp.id = data.id
				end
				pnl.OnSettingChanged()
			end)
			function drop.OpenMenu()
				//If the menu still exists and hasn't been deleted, then just close it and don't open a new one.
				//This doesn't use the standard drop.Menu value because that would cause the menu to auto-close
				//when an option is selected.
				if IsValid(drop.container) then
					drop.container:Remove()
					return
				end

				local container = vgui.Create("DPanel", TF2ItemBrowser:GetParent())
				container:DockPadding(16,16,16,16)
				function container:Paint(w,h)
					LoadoutItemPopupBorder(0,0,w,h)
				end
				drop.container = container

				//Originally we placed container inside a DermaMenu(), like DProperty_VectorColor does (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/prop_vectorcolor.lua#L95-L98C51),
				//but this didn't work well because col's textentries were impossible to give keyboard focus this way,
				//so instead make the container behave like a DermaMenu.
				CloseDermaMenus()
				container:SetIsMenu(true)
				function container:GetDeleteSelf() return true end
				function container:OnRemove() 
					//fix keyboard focus getting stuck on col's textentries if we remove container while focused
					local chump = vgui.GetKeyboardFocus()
					if IsValid(chump) then chump:KillFocus() end
				end
				RegisterDermaMenuForClose(container)

				local text = vgui.Create("DLabel", container)
				text:SetContentAlignment(7) //top left
				text:SetAutoStretchVertical(true)
				text:SetFont("TF2ItemBrowser_ItemName")
				text:SetColor(gui_colors.TanLight)
				text:SetText(drop:GetParent().Label:GetText())
				text:Dock(TOP)
				text:DockMargin(0,0,0,8)
				text:SizeToContents()

				local close = vgui.Create("DButton", container)
				close:SetText("")
				close:SetSize(22,22)
				function close:Paint(w,h)
					close:SetPos(container:GetWide()-w-12, 12)
					if self.Depressed then
						surface.SetDrawColor(color_white)
					elseif self.Hovered then
						surface.SetDrawColor(gui_colors.LightRed)
					else
						surface.SetDrawColor(gui_colors.TanDark)
					end
					surface.SetMaterial(close_button)
					surface.DrawTexturedRect(0,0,w,h)
				end
				AddTFButtonSounds(close)
				function close:DoClick()
					container:Remove()
				end

				//the pre-paintkit collections actually have very few paintkits per individual weapon, so collapse them 
				//into a single category for each update. also collapse the single-paintkit collections containing dragon 
				//slayer and smissmas sweater into one category, though this doesn't help much.
				local category_remaps = {
					Concealed_killer_collection		= "Operation_gun_mettle_master_collection",
					Craftsmann_collection			= "Operation_gun_mettle_master_collection",
					Teufort_collection			= "Operation_gun_mettle_master_collection",
					Powerhouse_collection			= "Operation_gun_mettle_master_collection",
					tough_break_drop_collection_01		= "operation_tough_break_master_collection",
					tough_break_drop_collection_02		= "operation_tough_break_master_collection",
					tough_break_case_collection_01_pyroland	= "operation_tough_break_master_collection",
					tough_break_case_collection_02_warbirds	= "operation_tough_break_master_collection",
					UniqueSkins_collection			= "Other",
					UniqueFreeSkins_collection		= "Other",
				}
				local categories = {}
				categories["Other"] = {order = 99999999, items = {}}
				for k, v in ipairs (paintkit_collections) do
					if category_remaps[v] then v = category_remaps[v] end
					categories[v] = categories[v] or {order = k, items = {}}
				end
				
				for k, v in pairs (drop.Choices) do
					local data = drop.Data[k]
					if data then 
						local cat = paintkit_ids_to_collections[data.id] or "Other"
						if category_remaps[cat] then cat = category_remaps[cat] end
						table.insert(categories[cat].items, {k = k, v = v, data = data})
					end
				end
				//Sort the categories by display order, and discard empty categories
				local cat2 = {}
				for k, v in pairs (categories) do
					if #v.items > 0 then 
						local name = k
						if TF2Items.item_collections[k] then
							name = GetTFLanguageString(TF2Items.item_collections[k].name) or k
						elseif name == "Other" then
							name = GetTFLanguageString("#AbuseReport_TypeOther") or "Other" //using this localization string for "Other" items is a stretch but it's the best we've got
						end
						cat2[v.order] = {name = name, items = v.items}
					end
				end
				categories = cat2
				local function GetDefaultCategory()
					local default_category, fallback_default_category
					//By default, select the category containing the currently selected option
					for k, v in SortedPairs (categories) do
						for _, entry in ipairs (v.items) do
							if (self.data.wp.enabled and entry.data and entry.data.id == self.data.wp.id)
							or (!self.data.wp.enabled and !entry.data) then
								default_category = k
								break
							end
						end
						if default_category then break end
						if !fallback_default_category then fallback_default_category = k end //if no category is selected, fall back to showing the first one
					end
					return default_category or fallback_default_category
				end

				local search_holder, icons
				if table.Count(categories) > 1 then
					search_holder = vgui.Create("DPanel", container) //we have enough horizontal space that we can put the category dropdown and search box next to each other
					search_holder.Paint = function() end
					search_holder:SetHeight(20)
					search_holder:Dock(TOP)
					local drop2, search

					drop2 = AddSubDropdown(search_holder) //calling this "drop" causes issues with the parent drop
					drop2:DockMargin(0,0,8,0)
					drop2:Dock(LEFT)
					drop2:SetSortItems(false)
					local selected = GetDefaultCategory()
					for k, v in SortedPairs (categories) do
						drop2:AddChoice(v.name, k, k == selected)
					end
					function drop2.OnSelect(_, index, value, data)
						search:SetText("")
						icons.SelectCategory(data)
					end

					search = TFStyleVGUI("DTextEntry", search_holder)
					search:Dock(FILL)
					search:SetPlaceholderText("#spawnmenu.search")
					search:SetUpdateOnType(true)
					search.OnValueChange = function(_, p)
						timer.Create("TF2ItemBrowser_SearchDelay_WPFilter", 0.5, 1, function()
							if IsValid(icons) then
								if #p == 0 then
									//Search is empty, go back to using the category dropdown
									//This uses drop2.ChooseOptionID and not icons.SelectCategory in order to restore the text on the dropdown 
									local selected = GetDefaultCategory()
									for k, v in pairs (drop2.Data) do
										if v == selected then
											drop2:ChooseOptionID(k)
										end
									end
								else
									//Search is populated, stop using categories and show all matching options
									p = p:lower()
									local tab = {}
									for k, v in SortedPairs (categories) do
										for _, entry in ipairs (v.items) do
											if entry.v:lower():find(p, 1, true) then
												table.insert(tab, entry)
											end
										end
									end
									icons.RebuildIcons(tab)
									drop2:SetText("")
								end
							end
						end)
					end
					function search_holder.PerformLayout(_, w, h)
						drop2:SetWide((w/2)-4)
					end
				end

				local icons_holder = vgui.Create("DPanel", container)
				icons_holder.Paint = function() end
				local scroll = TFStyleVGUI("DScrollPanel",icons_holder)
				if search_holder then
					icons_holder:DockMargin(0,8,0,0)
				end
				icons_holder:Dock(TOP)
				scroll:Dock(FILL)

				local size = 128
				icons = vgui.Create("DIconLayout", scroll)
				icons:Dock(FILL)
				icons:SetSpaceX(8)
				icons:SetSpaceY(8)

				local entry = TFStyleVGUI("DTextEntry", container, true)
				local entrypnl = AddTFLabelToVGUI(entry, "Seed")
				entrypnl:Dock(TOP)
				entrypnl:DockMargin(0,16,0,0)
				entry:SetNumeric(true)
				entry:SetText(self.data.wp.seed or "0")
				entry.OnEnter = function()
					local val = entry:GetText()
					if val != self.data.wp.seed then 
						self.data.wp.seed = val
						pnl.OnSettingChanged()
					end
				end
				entry.OnFocusChanged = function(_, b) 
					if !b then entry:OnEnter() end
				end
				local button = TFStyleVGUI("DButton", entrypnl)
				button:SetText(GetTFLanguageString("#TF_ItemPreview_PaintkitSeed") or "Randomize")
				button:SizeToContentsX(20)
				button:Dock(RIGHT)
				button:DockMargin(8,0,0,0)
				button.DoClick = function()
					local val = tostring(WP.RNG.RandomSeed())
					entry:SetText(val)
					self.data.wp.seed = val
					pnl.OnSettingChanged()
				end

				local slider = TFStyleVGUI("DNumSlider", container)
				local wear_slider = slider
				slider:SetText("Wear Level")
				slider:SetMinMax(1, 5)
				slider:SetDecimals(0)
				slider:Dock(TOP)
				slider:DockMargin(0,8,0,0)
				slider:SetValue(self.data.wp.wear or 1)
				function slider.OnValueChanged(_, val)
					val = math.Round(val)
					slider:SetValue(val) //snap to rounded value; if we don't do this, the displayed value will always be rounded *down* and can get out-of-sync with the actual value
					if val != self.data.wp.wear then //only send updates on whole numbers
						self.data.wp.wear = val
						pnl.OnSettingChanged()
					end
				end

				//The rest of these paintkit settings are global convars, not saved to the entity, so categorize them separately

				local combo = AddSubDropdown(container)
				local combopnl = AddTFLabelToVGUI(combo, "Texture Resolution (Global)")
				combopnl:Dock(TOP)
				combopnl:DockMargin(0,16,0,0)
				combo:SetSortItems(false)
				local cv = GetConVar("warpaint_rtt_resolution")
				if cv then cv = cv:GetString() end
				combo:AddChoice("512x512 (Fast)", "512", cv == "512")
				combo:AddChoice("1024x1024 (Balanced)", "1024", cv == "1024")
				combo:AddChoice("2048x2048 (High Quality)", "2048", cv == "2048")
				function combo.OnSelect(_, index, value, data)
					RunConsoleCommand("warpaint_rtt_resolution", tostring(data or value))
					//wait a moment for the convar change to take effect, otherwise the updated skin it generates will use the old 
					//setting. not sure if this is the right approach (are there circumstances where this isn't enough time?), is 
					//there something else we should be using to ensure that the convar is updated before rebuilding?
					timer.Simple(0.1, function()
						if IsValid(pnl) then pnl.OnSettingChanged() end
					end)
				end

				local check = TFStyleVGUI("DCheckBoxLabel", container)
				local intensity_check = check
				check:SetText("Increased Intensity Wears (Global)")
				check:DockMargin(0,8,0,0)
				check:Dock(TOP)
				local cv = GetConVar("warpaint_increased_intensity")
				if cv then cv = cv:GetBool() end
				check:SetChecked(cv)
				check.OnChange = function(_, val)
					if val then val = "1" else val = "0" end
					RunConsoleCommand("warpaint_increased_intensity", val)
					container:UpdateSize()
					//wait a moment for the convar change to take effect (see above)
					timer.Simple(0.1, function()
						if IsValid(pnl) then pnl.OnSettingChanged() end
					end)
				end
				local help = vgui.Create("DLabel", container)
				help:SetWrap(true)
				//help:SetAutoStretchVertical(true) //won't work here, see container:UpdateSize()
				help:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
				help:SetColor(gui_colors.TanLight)
				help:SetText("Non-TF2-accurate wear with higher visual intensity")
				help:Dock(TOP)
				help:DockMargin(22,0,32,0)
				local intensity_help = help

				local slider = TFStyleVGUI("DNumSlider", container)
				local intensity_slider = slider
				slider:SetText("Intensity Multiplier")
				slider:SetMinMax(1, 5)
				slider:SetDefaultValue(1)
				slider:Dock(TOP)
				slider:SetConVar("warpaint_intensity_multiplier")
				function slider.OnValueChanged(_, val)
					val = math.Round(val, 2)
					if val != slider.LastValue then
						if slider.LastValue != nil then //OnValueChanged runs automatically when the slider is first created, don't update pnl unnecessarily when that happens
							//wait a moment for the convar change to take effect (see above)
							timer.Simple(0.1, function()
								if IsValid(pnl) then pnl.OnSettingChanged() end
							end)
							//MsgN("val changed from ", slider.LastValue, " to ", val)
						end
						slider.LastValue = val
					end
				end

				local check = TFStyleVGUI("DCheckBoxLabel", container)
				local scratch_check = check
				check:SetText("Double Scratches")
				check:Dock(TOP)
				local cv = GetConVar("warpaint_double_scratch")
				if cv then cv = cv:GetBool() end
				check:SetChecked(cv)
				check.OnChange = function(_, val)
					if val then val = "1" else val = "0" end
					RunConsoleCommand("warpaint_double_scratch", val)
					container:UpdateSize()
					//wait a moment for the convar change to take effect (see above)
					timer.Simple(0.1, function()
						if IsValid(pnl) then pnl.OnSettingChanged() end
					end)
				end
				local help = vgui.Create("DLabel", container)
				help:SetWrap(true)
				//help:SetAutoStretchVertical(true) //won't work here, see container:UpdateSize()
				help:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
				help:SetColor(gui_colors.TanLight)
				help:SetText("Samples scratch texture twice at different UVs for denser wear patterns")
				help:Dock(TOP)
				help:DockMargin(22+32,0,32,0)
				local scratch_help = help

				function container:UpdateSize()
					//Resize and reposition container whenever the category is changed or intensity controls are toggled
					local control_height = 0
					if search_holder then control_height = search_holder:GetTall() + 8 end
					if intensity_check:GetChecked() then
						intensity_slider:SetHeight(21)
						intensity_slider:DockMargin(32,8,0,0)
						scratch_check:SetHeight(20)
						scratch_check:DockMargin(32,8,0,0)
						//scratch_help:SetAutoStretchVertical(true)
						//scratch_help:InvalidateLayout(true)
						scratch_help:SetTall(20) //default height apparently; can't do AutoStretchVertical here because we can't get an accurate height if we haven't set the container's width yet
						control_height = control_height + 8 + intensity_slider:GetTall() + 8 + scratch_check:GetTall() + scratch_help:GetTall()
					else
						intensity_slider:SetHeight(0)
						intensity_slider:DockMargin(0,0,0,0)
						scratch_check:SetHeight(0)
						scratch_check:DockMargin(0,0,0,0)
						//scratch_help:SetAutoStretchVertical(false)
						scratch_help:SetTall(0)
					end
					local w, h = icons.CurW, icons.CurH
					container:SetTall(text:GetTall() + 8 + control_height + h + 16 + entrypnl:GetTall() + 8 + wear_slider:GetTall() + 16 + combopnl:GetTall() + 8 + intensity_check:GetTall() + intensity_help:GetTall() + 16 + 16) //why doesn't SizeToChildren do this right?
					if container:GetTall() > ScrH() then
						local diff = container:GetTall() - ScrH()
						icons_holder:SetSize(w, h) //set this again to prevent the height from getting clobbered when the "increased intensity wears" check is toggled multiple times
						icons_holder:SetTall(icons_holder:GetTall() - diff)
						container:SetTall(container:GetTall() - diff)
						w = w + scroll.VBar:GetWide() //SizeToChildren doesn't do this right either; calling it immediately never gets vbar width, while subsequent calls always get vbar width whether it's visible or not
					end
					container:SetWide(w + 16 + 8)
					
					container:IsMouseInputEnabled(true)
					container:InvalidateLayout()

					local x, y = drop:LocalToScreen(drop:GetWide(), 0)
					if x + container:GetWide() > ScrW() then x = ScrW() - container:GetWide() end
					if y + container:GetTall() > ScrH() then y = ScrH() - container:GetTall() end
					container:SetPos(x, y)
				end

				function icons.SelectCategory(cat)
					local tab = {}
					for _, entry in ipairs (categories[cat].items) do
						table.insert(tab, entry)
					end
					icons.RebuildIcons(tab)
				end
				function icons.RebuildIcons(tab)
					icons:Clear()
					//add "none" option to the start of every category or search
					table.insert(tab, 1, {k = 1, v = drop.Choices[1]})
					for _, entry in ipairs (tab) do
						local icon = vgui.Create("ContentIcon", icons)
						icon:SetSize(size, size)
						function icon.DoRightClick() end
						function icon:DoClick()
							drop:ChooseOption(entry.v, entry.k)
						end
						icon:SetTooltip(nil)
						function icon.Paint(_,w,h)
							//custom background
							local col = gui_colors._unu_default
							local textcol = gui_colors.TanLight
							if (self.data.wp.enabled and entry.data and self.data.wp.id == entry.data.id)
							or (!self.data.wp.enabled and !entry.data) or icon.Depressed then //highlight the currently selected option
								col = gui_colors._unu_depressed
							elseif icon.Hovered then
								col = gui_colors._unu_hovered
							elseif entry.data then
								//Show quality color on text label, but revert to the default color when hovered/selected,
								//because some colors are too hard to read as small text on some of these backgrounds
								textcol = rarity_colors[paintkit_rarities[entry.data.id]] or textcol
							end
							draw.RoundedBox(12, 0,0,w,h, col)
							for k, v in ipairs (icon.labels) do
								v:SetTextColor(textcol)
							end

							icon.Image:PaintAt(0,0,w,h)

							//custom appearance for "none" option so it isn't just blank
							if !entry.data then
								surface.SetDrawColor(gui_colors.LightRed)
								surface.SetMaterial(close_button_nocircle)
								local w2 = w * 0.75
								local h2 = h * 0.75
								surface.DrawTexturedRect((w-w2)/2, (h-h2)/2, w2, h2)
							end
						end
						//custom text label; this is multiline so do the same textWrap approach as AddItemText
						local tab = {}
						icon.labels = {}
						for k, v in ipairs (string.Explode("\n", textWrap(entry.v, "TF2ItemBrowser_ItemDesc_Smaller", size - 8))) do
							//do these in reverse order because we're docking them to the bottom
							table.insert(tab, 1, v)
						end
						for k, v in ipairs (tab) do
							local label = icon:Add("DLabel")
							label:Dock(BOTTOM)
							label:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
							label:SetText(v)
							label:SetTextColor(gui_colors.TanLight)
							label:SetAutoStretchVertical(true)
							label:SetContentAlignment(5) //center
							table.insert(icon.labels, label)
						end
						AddTFButtonSounds(icon)
						//grab cached spawnicon if it exists, otherwise tell the icon render queue to create one
						local data = drop.Data[entry.k]
						if data and data.id then
							local iconmdl = mdl.models[1]:GetModel()
							local configs = WP.WarpaintData.GetById(data.id)
							for _, config in ipairs(configs) do
								if config.weapon == "paintkit_tool" then
									iconmdl = "models/items/paintkit_tool.mdl"
									break
								end
							end
							local iconpath = "tf2itembrowser_paintkiticons/" .. data.id .. "_" .. string.StripExtension(string.GetFileFromFilename(iconmdl)) .. ".png"
							function icon.RebuildIconTexture()
								local ent = ClientsideModel(iconmdl, RENDERGROUP_OTHER)
								if IsValid(ent) then
									ent:SetAngles(Angle(10,130,0)) //model angles from resource\ui\econ\itemmodelpanel.res; these make lighting subtly better
									ent:SetNoDraw(true)
								end
								table.insert(TF2ItemBrowser.IconRenderQueue, 1, function()
									//if ent is invalid, then remove from the queue
									if !IsValid(ent) then
										return true
									end
									//if icon no longer exists, then remove from the queue
									if !IsValid(icon) then
										ent:Remove()
										return true
									end
									
									//apply paintkit instance to ent; we do this in the render queue func and not 
									//when spawning ent, so that if multiple icons are queued at once, we can 
									//spread out the load times.
									if !ent.WarpaintData then
										local instance
										local weaponType = WP.Weapons.GetFromModel(ent:GetModel())

										//war paint instance-building code adapted from lua\weapons\gmod_tool\stools\warpaint.lua's TOOL:LeftClick()
										if weaponType then
											-- Try to build a full multi-layer instance if we have a warpaint ID
											instance = WP.WarpaintData.BuildInstance(
												data.id,
												weaponType,
												"1", //always use the same seed
												1, //factory new
												0 //always use red team
											)
											if instance then
												-- Set the matIndex since BuildInstance doesn't set it
												instance.matIndex = WP.Weapons.GetMatIndex(weaponType)
											end
										end
										//the fallback looks nothing like how the war paint will ever look in tf2, don't bother	
										--[[-- Fallback to simple instance if multi-layer failed or wasn't available
										if !instance then
											MsgN(i.name, " using warpaint fallback, not good")
											local pattern
											for k, v in pairs (WP.WarpaintData.GetUniqueWarpaints()) do
												if v.id == self.data.wp.id then
													pattern = v.primaryTexture
													break
												end
											end
											instance = WP.WarpaintInstance.New({
												patternId = pattern or "color/white", //adapted from lua\warpaint\ui\cl_pattern_browser.lua's WP.UI.PopulateWarpaintTree(); don't waste reseurces constantly networking a separate var to hold onto the pattern value for this fallback, instead just grab it when it's needed
												seed = self.data.wp.seed,
												wearLevel = self.data.wp.wear,
												wear = WP.RNG.GenerateWearFromSeed(self.data.wp.seed, self.data.wp.wear),
												team = _team,
												weaponType = weaponType,
												matIndex = WP.Weapons.GetMatIndex(weaponType)
											})
										end]]
										if instance then
											//adapted from lua\autorun\client\cl_warpaint_init.lua's net.Receive("WP_Apply"), which is response to net msg sent by tool
											WP.Materials.Apply(ent, instance)
											ent.instance = instance
										else
											//if we failed to instantiate the material, bail out
											return true
										end
									end

									//Don't render the icon until the paintkit material is no longer a placeholder
									local wp_state = WP.Materials.GetForEntity(ent)
									if wp_state == nil then
										//If WP.Materials.GetForEntity got stuck and can't retrieve 
										//the material (usually caused by removing an ent with a WP 
										//material), then reinstantiate it and try again
										WP.Materials.Apply(ent, ent.instance)
										return false
									elseif string.StartsWith(wp_state:GetName(), "warpaint_placeholder") then
										return false
									end

									//Render the icon texture
									local models = {ent}
									local cam = DoItemModelCamera(models, self)
									render.SetWriteDepthToDestAlpha(false)
									render.Clear(0, 0, 0, 0, true, true)
									DrawItemModels(0, 0, size, size, models, {}, cam.ang, cam.pos, cam.fov)
									local img = render.Capture({format = "png", x = 0, y = 0, w = size, h = size})
									if !file.IsDir("tf2itembrowser_paintkiticons/", "DATA") then 
										file.CreateDir("tf2itembrowser_paintkiticons/")
									end
									if file.Write(iconpath, img) then
										icon:SetMaterial("data/" .. iconpath)
									end
									ent:Remove()
									return true
								end)
								icon:SetMaterial(spinner:GetName())
							end
							if file.Exists(iconpath, "DATA") then
								icon:SetMaterial("data/" .. iconpath)
							else
								icon.RebuildIconTexture()
							end
							function icon.DoRightClick()
								////TODO: either get rid of this or turn it into a proper dropdown-within-dropdown
								//local menu = DermaMenu()

								//local opt = menu:AddOption("Re-render", function()
									icon.RebuildIconTexture()
								//end)
								//opt:SetIcon("icon16/picture_save.png")

								//menu:Open()
							end
						end
					end
					local w, h = (size+8)*4, (size+8)*(math.ceil(#tab/4))
					icons:SetSize(w, h)
					icons.CurW, icons.CurH = w, h //used by container:UpdateSize(); GetSize doesn't work there since it changes after invalidating layout; which results in the size changing as the "increased intensity wears" check is toggled
					icons:InvalidateLayout()
					icons_holder:SetSize(w, h)
					icons_holder:InvalidateLayout()
					scroll:InvalidateLayout()

					container:UpdateSize()
				end
				icons.SelectCategory(GetDefaultCategory())
			end
		end

		local button = TFStyleVGUI("DButton", pnl)
		if IsValid(self.entity) then
			button:SetText(string.upper(GetTFLanguageString("#Store_Remove" or "Remove")))
			button.BGColor = gui_colors.LightRed //using this as the neutral unselected color looks a little strange, but we can't use TFOrange as the unselected color because it could trick the player when switching from equip to unequip mode; also this matches the loadout preset buttons in TF2
		elseif IsValid(TF2ItemBrowser:GetEntity()) then
			button:SetText(GetTFLanguageString("#Equip") or "EQUIP")
		else
			button:SetText(GetTFLanguageString("#MMenu_Create") or "CREATE") //this is the closest thing the tf2 localization files have to the verb "spawn"; gmod's community.properties has the word "spawn" but it might be referring to the location (noun) instead which isn't right
		end
		button:Dock(TOP)
		button:DockMargin(side_margins,betweencategories-betweenitems,side_margins,betweencategories)
		button:SetDoubleClickingEnabled(false) //make the button spam-clickable like spawnicons
		button.DoClick = function()
			if IsValid(self.entity) then
				TF2ItemBrowser:DoInput("attach_item_remove", self.entity)
			elseif IsValid(TF2ItemBrowser:GetEntity()) then
				TF2ItemBrowser:DoInput("attach_item_spawn", self.data, true)
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

		local close = vgui.Create("DButton", pnl)
		close:SetText("")
		close:SetSize(22,22)
		close:SetPos(popup_w-close:GetWide()-12, 12)
		function close:Paint(w,h)
			if self.Depressed then
				surface.SetDrawColor(color_white)
			elseif self.Hovered then
				surface.SetDrawColor(gui_colors.LightRed)
			else
				surface.SetDrawColor(gui_colors.TanDark)
			end
			surface.SetMaterial(close_button)
			surface.DrawTexturedRect(0,0,w,h)
		end
		AddTFButtonSounds(close)
		function close:DoClick()
			pnl:Remove()
		end

		function pnl.OnRemove()
			//Clean up models and particles
			for k, v in ipairs (mdl.models) do
				if IsValid(v) then v:Remove() end
			end
			for k, v in ipairs (mdl.particles) do
				if IsValid(v) then v:StopEmissionAndDestroyImmediately() end
			end
			//If this itemicon doesn't correspond to an entity, then revert any changes when we close the spawn panel
			if !IsValid(self.entity) and IsValid(self) then self:SetDefaultData() end //don't run this when the itemicon is being deleted
		end

	end

	//dumb modified version of GWEN.CreateTextureBorder (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/derma/derma_gwen.lua#L6-L56),
	//used to scale down the tf2 backpack textures to match our tiny backpack icons
	local function GWEN_CreateTextureBorderScaled(_xo, _yo, _wo, _ho, l, t, r, b, material_override)

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
			local scale = item_icon_sizes[icon_size].scale
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
	local BackpackItemBorder = GWEN_CreateTextureBorderScaled(0, 0, 256, 128, 24, 24, 24, 24, Material("vgui/backpack_rect_vc.vmt")) //these use custom vmts with $vertexcolor added because surface.SetColor won't work on them otherwise
	local BackpackItemMouseOverBorder = GWEN_CreateTextureBorderScaled(0, 0, 256, 128, 24, 24, 24, 24, Material("vgui/backpack_rect_mouseover_vc.vmt"))
	local BackpackItemSelectedBorder = GWEN_CreateTextureBorderScaled(0, 0, 256, 128, 24, 24, 24, 24, Material("vgui/backpack_rect_selected_vc.vmt"))
	local BackpackItemGreyedOutBorder = GWEN_CreateTextureBorderScaled(0, 0, 256, 128, 24, 24, 24, 24, Material("vgui/backpack_rect_color.vmt"))
	//no need for BackpackItemGreyedOutSelectedBorder, it uses the same material as the standard one
	local col_GrayedOut = Color(46,43,42,255)
	//more here if we decide to do quality colors https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/client/econ/backpack_panel.cpp#L69

	TF2ItemBrowser_IconRTs = {}
	function PANEL:Paint(w, h)

		//This is a newly created icon being drawn for the first time, populate its data table
		if self.data and !istable(self.data) then self:SetDefaultData() end

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

		local col
		if self.item_conflict then col = col_GrayedOut end
		if (IsValid(TF2ItemBrowser.SpawnPanel) and TF2ItemBrowser.SpawnPanel.Owner == self) or IsValid(self.menu) or self:IsDown() then
			BackpackItemSelectedBorder(0,0,w,h,col)
		else
			if !self.item_conflict then
				if self:IsHovered() then
					BackpackItemMouseOverBorder(0,0,w,h)
				else
					BackpackItemBorder(0,0,w,h)
				end
			else
				BackpackItemGreyedOutBorder(0,0,w,h,col)
			end
		end

		if self.mat then
			if self.item_conflict then 
				surface.SetDrawColor(96,96,96,255) //https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/client/econ/item_model_panel.cpp#L823-L830
			else
				surface.SetDrawColor(255,255,255,255)
			end
			surface.SetMaterial(self.mat)
			local x, y, w2, h2 = 0, 0, w, h
			//Draw rendertarget icons at a slightly smaller size to match their appearance in TF2, otherwise they'll butt right up against the edges of the panel
			if self.mat_isrticon then
				local minusw = item_icon_sizes[icon_size].rticon_minusw
				local minush = h*(minusw/w)
				x = x + (minusw/2)
				y = y + (minush/2)
				w2 = w - minusw
				h2 = h - minush
			end
			//these panels are a bit shorter than they are wide, so cut off the bottom and top of the material to center it
			local diff = (1-(h2/w2))/2
			surface.DrawTexturedRectUV(x,y,w2,h2,0,0+diff,1,1-diff)
			if self.mat_overlay then
				local col = self.data.paint.col[false]
				surface.SetDrawColor(col.x, col.y, col.z, 255)
				surface.SetMaterial(self.mat_overlay)
				surface.DrawTexturedRectUV(x,y,w2,h2,0,0+diff,1,1-diff)
			end
		elseif self.ImageToQueue then
			self.mat_isrticon = nil
			if TF2ItemBrowser_ImageQueuedBefore[self.ImageToQueue] then
				self.mat = Material(self.ImageToQueue .. ".vmt")
			else
				table.insert(TF2ItemBrowser.ImageQueue, {pnl = self, img = self.ImageToQueue})
			end
			self.ImageToQueue = nil
		elseif self.IconRenderToQueue then
			self.IconRenderToQueue = nil
			local oldteam = self.data.team
			self.data.team = false //spawnicons should always use red team; in tf2 this is a little inconsistent, and uses team colors for warpaints but always red for model skins; we can't really do this without adding special handling to recreate this bug, so instead try to match all prerendered spawnicons
			local models, particles = self:CreateItemModelsAndParticles(function()
				self.IconRenderToQueue = true //bail function
			end)
			self.data.team = oldteam
			if models then
				local rtkey = table.KeyFromValue(TF2ItemBrowser_IconRTs, self)
				if !rtkey then
					for i = 1, 128 do
						//get first nil key we can find; as icons are removed from this list, they can leave gaps for us to take
						if TF2ItemBrowser_IconRTs[i] == nil then
							TF2ItemBrowser_IconRTs[i] = self
							rtkey = i
							break
						end
					end
				end
				if rtkey == nil then return end
				local rtname = "TF2ItemBrowser_IconRT_" .. tostring(rtkey)
				local rt = GetRenderTarget(rtname, 128, 128)
				--[[local rt = GetRenderTargetEx(rtname, //same texture parameters as all tf2 backpack icon vtfs; commented out because DXT5 keeps generating solid black textures, and using BGRA8888 looks the same as default
					128, 128,
					RT_SIZE_NO_CHANGE,
					MATERIAL_RT_DEPTH_SEPARATE, //MATERIAL_RT_DEPTH_NONE,
					bit.bor(
						256, //TEXTUREFLAGS_NOMIP
						512, //TEXTUREFLAGS_NOLOD
						8192 //TEXTUREFLAGS_EIGHTBITALPHA	
					),
					0,
					IMAGE_FORMAT_BGRA8888//15 //IMAGE_FORMAT_DXT5 	
				)]]
				if rt == nil then MsgN("Failed to create render target ", rtname, "; out of memory?") return end

				local function CleanUpModelsAndParticles()
					for k, v in ipairs (models) do
						if IsValid(v) then v:Remove() end
					end
					for k, v in ipairs (particles) do
						if IsValid(v) then v:StopEmissionAndDestroyImmediately() end
					end
				end

				table.insert(TF2ItemBrowser.IconRenderQueue, 1, function()
					//if ent is invalid, then remove from the queue
					if !models or !IsValid(models[1]) then
						return true
					end
					//if icon no longer exists, then remove from the queue
					if !IsValid(self) then
						CleanUpModelsAndParticles()
						return true
					end

					//Don't render the icon until the paintkit material is no longer a placeholder
					if self.data.wp.enabled then
						local wp_state = WP.Materials.GetForEntity(models[1])
						if wp_state == nil then
							//If WP.Materials.GetForEntity got stuck and can't retrieve the material (usually 
							//caused by removing an ent with a WP material), then reinstantiate it and try again
							WP.Materials.Apply(models[1], models[1].instance)
							return false
						elseif string.StartsWith(wp_state:GetName(), "warpaint_placeholder") then
							return false
						end
					end

					//Render the icon texture
					render.PushRenderTarget(rt, 0, 0, 128, 128)
					local cam = DoItemModelCamera(models, self)
					render.SetWriteDepthToDestAlpha(false)
					render.Clear(0, 0, 0, 0, true, true)
					DrawItemModels(0, 0, 128, 128, models, particles, cam.ang, cam.pos, cam.fov)
					render.PopRenderTarget()

					local mat = CreateMaterial(rtname, "UnlitGeneric", {
						["$basetexture"] = "color/white",
						["$translucent"] = "1",
						["$vertexcolor"] = "1"
					})
					mat:SetTexture("$basetexture", rt)
					//self:SetMaterial("!" .. rtname)
					self.mat = mat
					self.mat_isrticon = true

					CleanUpModelsAndParticles()
					return true
				end)
			end
		elseif !self.no_image then
			//show loading icon
			surface.SetMaterial(spinner)
			surface.DrawTexturedRect((w/2)-(h/2), 0, h, h)
		end

		if self.icons then
			local size = item_icon_sizes[icon_size].cornericon
			local xpos = w - size - (3 * item_icon_sizes[icon_size].scale) 
			local ypos = 2 * item_icon_sizes[icon_size].scale
			for k, v in ipairs (self.icons) do
				surface.SetMaterial(v.icon)
				//update spell colors if applicable
				if v.override_2 then
					v.paint[1] = ProxyentPaintColor_GetOverrideColor(v.override)
					v.paint[2] = ProxyentPaintColor_GetOverrideColor(v.override_2)
				elseif v.override then
					v.paint = ProxyentPaintColor_GetOverrideColor(v.override)
				end
				if v.paint then
					if isvector(v.paint) then
						surface.SetDrawColor(v.paint[1], v.paint[2], v.paint[3])
						surface.DrawTexturedRect(xpos, ypos, size, size)
					else
						self:DrawPaintIcon(xpos, ypos, size, size, v.paint)
					end
				else
					surface.SetDrawColor(255,255,255)
					surface.DrawTexturedRect(xpos, ypos, size, size)
				end
				ypos = ypos + (size * 0.9) //yes, this is how tf2 code does it, the icons overlap each other slightly (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/client/econ/item_model_panel.cpp#L1919-L1952)
			end
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

		surface.PlaySound(self.sound_pressed) //not tf2-authentic to do this on right click, but feels better this way
		local menu = DermaMenu()

		//quick-spawn options, to spawn/equip items quickly without customizing them first, or to unequip items more efficiently
		if IsValid(self.entity) then
			menu:AddOption(string.NiceName(string.lower(GetTFLanguageString("#Store_Remove" or "Remove"))), function()
				TF2ItemBrowser:DoInput("attach_item_remove", self.entity)
				surface.PlaySound(self.sound_drop)
			end)
		elseif IsValid(TF2ItemBrowser:GetEntity()) then
			menu:AddOption(string.NiceName(string.lower(GetTFLanguageString("#Equip") or "EQUIP")), function()
				TF2ItemBrowser:DoInput("attach_item_spawn", self.data, false)
				surface.PlaySound(self.sound_drop)
			end)
		else
			menu:AddOption(string.NiceName(string.lower(GetTFLanguageString("#MMenu_Create") or "CREATE")), function()
				TF2ItemBrowser:DoInput("item_spawn", self.data)
				surface.PlaySound(self.sound_drop)
			end)
		end

		if isstring(self.data.id) then
			menu:AddOption("Edit custom item", function()
				TF2ItemBrowser:OpenCustomItemEditor(self.data.id)
			end)
		end

		//also put this debug option here
		//if GetConVarNumber("developer") >= 1 then
			menu:AddSpacer()
			menu:AddOption("Print item data in console", function()
				MsgN("\n\n\n")
				MsgN(self.data.id, " ", TF2Items.items[self.data.id].name)
				PrintTable(TF2Items.items[self.data.id])
			end)
		//end

		self.menu = menu
		menu:Open()
		AddTFStyleToVGUI(menu)

	end

	AddTFButtonSounds(PANEL)

	function PANEL:OnRemove()

		if IsValid(self.popup) then self.popup:Remove() end

		if self.entity and TF2ItemBrowser.atticons.icons[self.entity] == self then
			TF2ItemBrowser.atticons.icons[self.entity] = nil
			TF2ItemBrowser.atticons:InvalidateLayout()
			TF2ItemBrowser:UpdateItemConflicts()
		end

		//remove self from icon render targets
		local rtkey = table.KeyFromValue(TF2ItemBrowser_IconRTs, self)
		if rtkey then TF2ItemBrowser_IconRTs[rtkey] = nil end

	end

	vgui.Register("TF2ItemIcon", PANEL, "DButton")

end










//Networking for browser inputs
BrowserInputs = {
	[0] = "item_spawn",
	"attach_item_spawn",
	"attach_item_modify",
	"attach_item_remove",
	"attach_par_skin",
	"attach_par_fx",
}
BrowserInputs_bits = 3 //max 7
BrowserInputs = table.Flip(BrowserInputs)
//How this works:
//- table.Flip sets the table to {channel_sequence = 0}, and so on
//- net.Write retrieves the corresponding number of a string with BrowserInputs[input], then sends that number
//- net.Read gets the number, then retrieves its corresponding string with table.KeyFromValue(BrowserInputs, input)
//This lets us add as many networkable strings to this table as we want, without having to manually assign each one a number.

WriteItemDataTable = function(data)
	//normal items have id numbers, custom items have id strings
	net.WriteBool(isstring(data.id))
	if !isstring(data.id) then
		net.WriteUInt(data.id, 15) //max 32767; as of summer 2026 the highest spawnable item id is 31629, so probably a while before we need to increase this
	else
		net.WriteString(data.id)
	end
	net.WriteUInt(data.class, 4)
	net.WriteBool(data.team)
	net.WriteUInt(data.style, 4)

	net.WriteBool(data.models.item)
	net.WriteBool(data.models.wearable)
	net.WriteBool(data.models.wearable_2)
	net.WriteBool(data.models.taunt_prop)
	net.WriteBool(data.models.attached_festive)
	net.WriteBool(data.models.stat_clock)

	net.WriteUInt(data.fx, 3)

	net.WriteBool(data.paint.enabled)
	if data.paint.enabled then
		net.WriteVector(data.paint.col[false])
		net.WriteBool(data.paint.col[true] != nil)
		if data.paint.col[true] != nil then
			net.WriteVector(data.paint.col[true])
		end
		net.WriteUInt(data.paint.override[false], 3)
		net.WriteBool(data.paint.override[true] != nil)
		if data.paint.override[true] != nil then
			net.WriteUInt(data.paint.override[true], 3)
		end
	end
	net.WriteBool(data.crit.enabled)
	if data.crit.enabled then
		net.WriteVector(data.crit.col[false])
		net.WriteBool(data.crit.col[true] != nil)
		if data.crit.col[true] != nil then
			net.WriteVector(data.crit.col[true])
		end
		net.WriteBool(data.crit.sparks_rb)
		net.WriteBool(data.crit.sparks_c)
	end

	net.WriteBool(data.pe_def)
	net.WriteUInt(data.pe_unusual, 10) //max 1023; as of summer 2026 the highest effect id that can be applied to a hat or weapon is 704 - taunt fx go as high as 3229, and killstreakers go all the way up to 22008, but we currently don't need to spawn either of those, so we'll revisit this later if necessary
	net.WriteBool(data.pe_unusual_offset != nil)
	if data.pe_unusual_offset != nil then
		net.WriteFloat(data.pe_unusual_offset)
	end

	net.WriteBool(data.wp.enabled)
	if data.wp.enabled then
		net.WriteUInt(data.wp.id, 10) //max 1023; as of summer 2026 the highest paintkit id is 442, so very unlikely we'll ever need more
		net.WriteUInt(data.wp.wear, 3)
		net.WriteString(data.wp.seed)
	end
end

ReadItemDataTable = function()
	local id
	if !net.ReadBool() then
		id = net.ReadUInt(15)
	else
		id = net.ReadString()
	end

	local tab = {
		id = id,
		class = net.ReadUInt(4),
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

		fx = net.ReadUInt(3),
	}

	if net.ReadBool() then
		tab.paint = {
			enabled = true,
			col = {[false] = net.ReadVector()},
		}
		if net.ReadBool() then
			tab.paint.col[true] = net.ReadVector()
		end
		tab.paint.override = {[false] = net.ReadUInt(3)}
		if net.ReadBool() then
			tab.paint.override[true] = net.ReadUInt(3)
		end
	else
		tab.paint = {
			enabled = false,
			col = {[false] = Vector(255,255,255)},
			override = {[false] = 0},
		}
	end
	if net.ReadBool() then
		tab.crit = {
			enabled = true,
			col = {[false] = net.ReadVector()}
		}
		if net.ReadBool() then
			tab.crit.col[true] = net.ReadVector()
		end
		tab.crit.sparks_rb = net.ReadBool()
		tab.crit.sparks_c = net.ReadBool()
	else
		tab.crit = {
			enabled = false,
			col = {[false] = Vector(1,1,1)},
			sparks_rb = false,
			sparks_c = false,
		}
	end

	tab.pe_def = net.ReadBool()
	tab.pe_unusual = net.ReadUInt(10)
	if net.ReadBool() then
		tab.pe_unusual_offset = net.ReadFloat()
	end

	if net.ReadBool() then
		tab.wp = {
			enabled = true,
			id = net.ReadUInt(10),
			wear = net.ReadUInt(3),
			seed = net.ReadString(),
		}
	else
		tab.wp = {
			enabled = false,
			id = 0,
			wear = 1,
			seed = tostring(WP.RNG.RandomSeed()),
		}
	end

	return tab
end

if SERVER then

	util.AddNetworkString("TF2ItemBrowser_Input_SendToSv")
	util.AddNetworkString("TF2ItemBrowser_AttachedItems_GetFromSv")
	util.AddNetworkString("TF2ItemBrowser_AttachedItem_SendToCl")

	net.Receive("TF2ItemBrowser_Input_SendToSv", function(_, ply)

		local input = net.ReadUInt(BrowserInputs_bits)
		if !input then return end
		input = table.KeyFromValue(BrowserInputs, input)

		local ent, data, i, vis, merge_type, submodels, effect_mats, forceopen
		if string.StartsWith(input, "attach_") then
			ent = net.ReadEntity()
		end

		if input == "item_spawn" or input == "attach_item_spawn" or input == "attach_item_modify" then
			data = ReadItemDataTable()
			i = TF2Items.items[data.id] or {}
			vis = GetItemModelVisuals(data)
			merge_type = net.ReadBool()
			if input == "attach_item_spawn" then forceopen = net.ReadBool() end

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
			//For totally modelless items like gunslinger/hatlesses, always spawn an invisible model to associate the item with,
			//which we'll attach to a ragdoll if there's no ent selected. For items like banners that just have all the submodels
			//toggled off, only spawn an invisible model if we're attaching to an ent (so that we have an item ent that the browser 
			//can use to turn the model back on); otherwise, just spawn nothing, which matches the preview in the spawn panel.
			if #submodels == 0 and (IsValid(ent) or table.Count(vis.models) == 0) then table.insert(submodels, {role = "no_model_fallback"}) end

			effect_mats = {
				[EFFECT_GOLD] = "models/player/shared/gold_player",
				[EFFECT_ICE] = "models/player/shared/ice_player",
				["red"] = "models/effects/invulnfx_red", //for table.KeyFromValue detection
				["blu"] = "models/effects/invulnfx_blue", //^
			}
			if !data.team then
				effect_mats[EFFECT_UBER] = effect_mats.red
			else
				effect_mats[EFFECT_UBER] = effect_mats.blu
			end
			if i.visuals and i.visuals.material_override then 
				effect_mats[EFFECT_NONE] = i.visuals.material_override 
				effect_mats[EFFECT_JARATE] = i.visuals.material_override
			end
		end

		//Spawn the item using the retrieved model, skin and bodygroups. To do this, we mostly just emulate sandbox's CCSpawn function
		//and the various functions it calls (gamemodes/sandbox/gamemode/commands.lua) This is worth doing because it makes sure we run
		//all of the relevant hooks that might want to catch us spawning the prop, and also lets us reuse all of DoPlayerEntitySpawn's 
		//"spawn the prop where the player is looking, and make sure it isn't stuck" code.
		local function CreateItemEntity(model, skin, item_bg, parent, anim, is_fallback)

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

			if anim then
				DisablePropCreateEffect = true
				e = ConvertEntityToAnimprop(e, ply, true, !anim.undo)
				DisablePropCreateEffect = nil

				e:SetChannel1Sequence(e:LookupSequence(anim.anim))
			end
			
			if IsValid(parent) then
				if merge_type or anim or is_fallback then //fallback models (hatlesses) use a custom boneinfo table to attach unusual effects to the head. since we don't have a good way to switch it from easybone to advbone if the player adds an unusual effect *after* spawning it, fallback models *always* have to use advbone. dumb!!
					local old_e = e
					e = CreateAdvBonemergeEntity(e, parent, ply, false, false, true)
					if !IsValid(e) then return end
					if is_fallback and parent:LookupBone("bip_head") then e.AdvBone_BoneInfo[0].parent = "bip_head" end
					local const = constraint.AdvBoneMerge(parent, e, ply)
					if e != old_e then old_e:Remove() end
				else
					e = rb655_ApplyBonemerge(e2, parent) //unlike advbone, this one expects AttachedEntity for prop_effects
				end
			end

			return e

		end

		local function UpdateItemCustomization(e, role)
			local e2 = e.AttachedEntity or e

			//Update material override of each submodel
			local mat = effect_mats[data.fx]
			if mat then
				e2:SetMaterial(mat)
				duplicator.StoreEntityModifier(e2, "material", {MaterialOverride = mat})
			elseif table.KeyFromValue(effect_mats, e2:GetMaterial()) then
				//If the ent's current material is an fx material override we *don't* want to use any more, then clear it, but don't clobber unrelated materials
				e2:SetMaterial("")
				duplicator.ClearEntityModifier(e2, "material")
			end

			//paint matproxy
			if data.paint.enabled then
				local col = data.paint.col[data.team] or data.paint.col[false]
				GiveMatproxyTF2ItemPaint(ply, e, {
					ColorR = col.x,
					ColorG = col.y,
					ColorB = col.z,
					Override = data.paint.override[data.team] or data.paint.override[false]
				})
			elseif e.ProxyentPaintColor then
				if IsValid(e.ProxyentPaintColor) then e.ProxyentPaintColor:Remove() end
				e.ProxyentPaintColor = nil
				duplicator.ClearEntityModifier(e, "MatproxyTF2ItemPaint")
			end

			//critglow and EFFECT_JARATE matproxy
			local col
			if data.crit.enabled and (role == "item" or role == "attached" 
			or role == "attached_festive" or role == "stat_clock") then
				col = data.crit.col[data.team] or data.crit.col[false]
			end
			if data.fx == EFFECT_JARATE then
				col = (col or Vector(1,1,1)) * jarate[data.team]
			end
			if col then
				local function bool_to_num(a) if !a then return 0 else return 1 end end
				GiveMatproxyTF2CritGlow(ply, e, {
					ColorR = col.x,
					ColorG = col.y,
					ColorB = col.z,
					RedSparks = bool_to_num(role == "item" and !data.team and data.crit.sparks_rb),
					BluSparks = bool_to_num(role == "item" and data.team and data.crit.sparks_rb),
					ColorableSparks = bool_to_num(role == "item" and data.crit.sparks_c),
				})
			elseif e.ProxyentCritGlow then
				if IsValid(e.ProxyentCritGlow) then e.ProxyentCritGlow:Remove() end
				e.ProxyentCritGlow = nil
				duplicator.ClearEntityModifier(e, "MatproxyTF2CritGlow")
			end

			//particle effects
			if role == "item" or role == "no_model_fallback" then
				//Get rid of old particle effects
				if e.TF2ItemBrowser_Item_Particles then
					for k, v in pairs (e.TF2ItemBrowser_Item_Particles) do
						if IsValid(k) then
							k:Remove()
						else
							e.TF2ItemBrowser_Item_Particles[k] = nil
						end
					end
				end

				local function AddEffect(tab)
					local name = tab.system
					if name:EndsWith("_teamcolor_red") and data.team then
						name = string.Replace(name, "_teamcolor_red", "_teamcolor_blue")
					end
					if tab.use_suffix_name then name = name .. "_" .. i.particle_suffix end
					if i.visuals and i.visuals.styles then
						if (name == "drg_pipe_smoke" and i.visuals.styles[data.style].use_smoke_particle_effect == 0)
						or (name == "coin_spin" and i.visuals.styles[data.style].use_coin_particle_effect == 0) then
							return
						end
					end

					local pcfs = PEPlus_FindPCFsFromEffect(name)
					if !pcfs then return end
					local pcf, path = pcfs[1].pcf, pcfs[1].path
					local p = PEPlus_SpawnParticle(ply, e:GetPos(), name, pcf, path, true)
					if !IsValid(p) then return end

					if data.pe_unusual_offset then //https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/particle_property.cpp#L594; yes, this applies to ALL effects attached to the model, even if it makes genteel smoke look dumb (https://www.youtube.com/watch?v=A0CBN92OhrY)
						local bone
						if e2:LookupBone("bip_head") then
							bone = "bip_head"
						else
							if e2:LookupBone("prp_helmet") then
								bone = "prp_helmet"
							else
								if e2:LookupBone("prp_hat") then
									bone = "prp_hat"
								else
									bone = e2:GetBoneName(0)
								end
							end
						end
						local manip = Vector(0, data.pe_unusual_offset, 0)
						if bone == "bip_head" or role == "no_model_fallback" then manip = -manip end

						local old_g = p:GetParent()
						local _g = CreateAdvBonemergeEntity(old_g, e, ply, false, false, true)
						_g:ManipulateBonePosition(0, manip, true)
						_g.AdvBone_BoneInfo[0].parent = bone
						if !IsValid(_g) then return end
						local const = constraint.AdvBoneMerge(e, _g, ply)
						if _g != old_g then old_g:Remove() end
					else
						//try to use an attachment point by default, or fall back to root bone/origin otherwise (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_entity.cpp#L1749)
						local attachment = -1
						if tab.attachment then attachment = e2:LookupAttachment(tab.attachment) end
						if attachment > 0 then
							if p.ParticleInfo[0].ent then
								p:AttachToEntity(e, 0, attachment, ply, false)
							end
						else
							if tab.attach_to_rootbone then
								local old_g = p:GetParent()
								local _g = CreateAdvBonemergeEntity(old_g, e, ply, false, false, true)
								_g.AdvBone_BoneInfo[0].parent = e2:GetBoneName(0)
								if !IsValid(_g) then return end
								local const = constraint.AdvBoneMerge(e, _g, ply)
								if _g != old_g then old_g:Remove() end
							else
								if p.ParticleInfo[0].ent then
									p:AttachToEntity(e, 0, 0, ply, false)
								end
							end
						end
					end
					for i = 1, 5 do
						if tab["control_point_" .. i] and p.ParticleInfo[i] and p.ParticleInfo[i].ent then
							local attachment = e:LookupAttachment(tab["control_point_" .. i])
							if attachment > 0 then
								p:AttachToEntity(e, i, attachment, ply, false)
							end
						end
					end
					constraint.TF2ItemBrowser_Item_SubModel(e, p, "peplus", nil, ply)
				end
				if data.pe_def then
					for k, v in ipairs (GetItemDefaultParticleEffects(data)) do
						AddEffect(v)
					end
				end
				if data.pe_unusual > 0 then
					local tab = TF2Items.attribute_controlled_attached_particles_all[data.pe_unusual]
					if tab then AddEffect(tab) end
				end
			end

			//war paint
			if data.wp.enabled and role == "item" then
				local instance
				local weaponType = WP.Weapons.GetFromModel(e:GetModel())
				local _team = 0
				if data.team then _team = 1 end

				//war paint instance-building code adapted from lua\weapons\gmod_tool\stools\warpaint.lua's TOOL:LeftClick()
				if weaponType then
					-- Try to build a full multi-layer instance if we have a warpaint ID
					instance = WP.WarpaintData.BuildInstance(
						data.wp.id,
						weaponType,
						data.wp.seed,
						data.wp.wear,
						_team
					)
					if instance then
						-- Set the matIndex since BuildInstance doesn't set it
						instance.matIndex = WP.Weapons.GetMatIndex(weaponType)
					end
				end
				//the fallback looks nothing like how the war paint will ever look in tf2, don't bother	
				--[[-- Fallback to simple instance if multi-layer failed or wasn't available
				if !instance then
					MsgN(i.name, " using warpaint fallback, not good")
					local pattern
					for k, v in pairs (WP.WarpaintData.GetUniqueWarpaints()) do
						if v.id == data.wp.id then
							pattern = v.primaryTexture
							break
						end
					end
					instance = WP.WarpaintInstance.New({
						patternId = pattern or "color/white", //adapted from lua\warpaint\ui\cl_pattern_browser.lua's WP.UI.PopulateWarpaintTree(); don't waste reseurces constantly networking a separate var to hold onto the pattern value for this fallback, instead just grab it when it's needed
						seed = data.wp.seed,
						wearLevel = data.wp.wear,
						wear = WP.RNG.GenerateWearFromSeed(data.wp.seed, data.wp.wear),
						team = _team,
						weaponType = weaponType,
						matIndex = WP.Weapons.GetMatIndex(weaponType)
					})
				end]]
				local success = WP.Server.ApplyWarpaint(e, instance, ply)
				if success then e:SetSkin(0) end
			elseif e.WarpaintData then
				WP.Server.RemoveWarpaint(e)
			end
		end

		if input == "item_spawn" or input == "attach_item_spawn" then

			if !IsValid(ply) or (!ply:Alive() and !ply:IsAdmin()) then return end

			local spawned_models = {}
			for k, v in ipairs (submodels) do
				local parent = ent
				local model = vis.models[v.role]
				local item_bg, anim, is_fallback
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
					if !IsValid(ent) then
						//if we're spawning a modelless item that isn't attached to anything, then also spawn a 
						//default class ragdoll for it to attach to. this looks less awkward than clicking to 
						//spawn a gunslinger or something and getting an invisible effect, but also makes sure 
						//that spawning unusual hatlesses isn't inconsistent with equipping them to a class.
						local model, skin = "models/player/" .. classes[data.class].shortname .. ".mdl", 0
						if data.team then skin = 1 end
						//again, like CreateItemEntity, we mostly just emulate sandbox's CCSpawn function and the 
						//various functions it calls (gamemodes/sandbox/gamemode/commands.lua) to ensure that we 
						//call all the necessary hooks.
						if gamemode.Call("PlayerSpawnObject", ply, model, skin) and util.IsValidModel(model) and gamemode.Call( "PlayerSpawnRagdoll", ply, model) then
							local rag = DoPlayerEntitySpawn(ply, "prop_ragdoll", model, skin)
							if IsValid(rag) then 
								gamemode.Call("PlayerSpawnedRagdoll", ply, model, rag)
								//DoPropSpawnedEffect(rag)

								undo.Create("prop_ragdoll")
									undo.SetPlayer(ply)
									undo.AddEntity(rag)
								undo.Finish("#prop_ragdoll (" .. tostring( model ) .. ")")
								ply:AddCleanup("ragdolls", rag)

								parent = rag
								//Don't set ent = rag because we don't want to do any of the other 
								//stuff below like adding a separate undo; instead, just do all the
								//playermodel bodygroup stuff again here.
								for k, v in pairs (vis.ply_bg) do
									if isstring(k) then k = rag:FindBodygroupByName(k) end //on some items, k is a number already
									rag:SetBodygroup(k, v)
								end
							end
						end
					end
					is_fallback = true
				end
				//keep this simple, just convert every submodel into an animprop if there's an animation. this is easier than trying 
				//to convert ents back-and-forth between animprops and normal props whenever an animated submodel is toggled on and 
				//off (which is what would happen if you were to spawn the thermal thruster with just the non-animated taunt prop, 
				//and then enable the animated base item afterward). this also conveniently sidesteps the bone position lag that 
				//otherwise happens when merging the base jumper's animated parachute to the non-animated main item.
				if i.visuals and i.visuals.styles and i.visuals.styles[data.style] then
					anim = i.visuals.styles[data.style]._anim
					if anim then
						anim = {anim = anim[v.role] or "", undo = k == 1}
					else
						anim = nil
					end
				end

				local e = CreateItemEntity(model, vis.skin, item_bg, parent, anim, is_fallback)
				if !IsValid(e) then continue end

				table.insert(spawned_models, e)

				if v.role == "stat_clock" then
					local scl = vis.stat_clock_scale or 1
					e:ManipulateBoneScale(e:LookupBone("c_weapon_stattrack"), Vector(scl,scl,scl))
				end

				if e != spawned_models[1] and IsValid(ent) then //only associate item ents together if they're being attached to an entity, not spanwed on the ground
					constraint.TF2ItemBrowser_Item_SubModel(spawned_models[1], e, v.role, v.attach_num, ply)
				end

				//Set material override, paint, critglow, particles
				UpdateItemCustomization(e, v.role)
			end
			if !IsValid(spawned_models[1]) then return end

			if IsValid(ent) then
				//Use a one-size-fits-all undo instead of addon-specific undos;
				//for advbone in particular, we want to remove the entity instead of unmerging it
				undo.Create("TF2ItemBrowser_Item")
					for _, e in ipairs (spawned_models) do
						undo.AddEntity(e)
						//Revert bodygroup changes on the parent entity, and remove submodels
						undo.AddFunction(TF2ItemBrowser_Item_DoUnequip, e)
					end
					undo.SetPlayer(ply)
				undo.Finish("Attached Item (" .. i.name .. ")") //item name instead of model name because this can change

				for k, v in pairs (vis.ply_bg) do
					//when attaching a new item, we can keep this simple, and just change the ply_bg's the item has listed
					if isstring(k) then k = ent:FindBodygroupByName(k) end //on some items, k is a number already
					ent:SetBodygroup(k, v)
				end
				//Do parent skin change for zombie skin items
				if i.attributes and i.attributes["player skin override"] and ent:SkinCount() > 4 and ent:GetSkin() <= 3 then
					ent:SetSkin(ent:GetSkin() + 4)
				end

				//timer.Simple(0.1, function() //do this on a timer so the entity isn't still null on the client's end
				//	if !IsValid(e) then return end
					net.Start("TF2ItemBrowser_AttachedItem_SendToCl")
						net.WriteEntity(spawned_models[1])
						net.WriteBool(forceopen) //open spawn panel upon received?
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
				//keep this simple, just convert every submodel into an animprop if there's an animation. this is easier than trying 
				//to convert ents back-and-forth between animprops and normal props whenever an animated submodel is toggled on and 
				//off (which is what would happen if you were to spawn the thermal thruster with just the non-animated taunt prop, 
				//and then enable the animated base item afterward). this also conveniently sidesteps the bone position lag that 
				//otherwise happens when merging the base jumper's animated parachute to the non-animated main item.
				local anim
				if i.visuals and i.visuals.styles and i.visuals.styles[data.style] then
					anim = i.visuals.styles[data.style]._anim
					if anim then
						anim = {anim = anim[v.role] or "", undo = k == 1}
					else
						anim = nil
					end
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
						e2 = CreateItemEntity(model, vis.skin, nil, parent, anim)
						if !IsValid(e2) then continue end
						if v.role == "stat_clock" then
							local scl = vis.stat_clock_scale or 1
							e2:ManipulateBoneScale(e2:LookupBone("c_weapon_stattrack"), Vector(scl,scl,scl))
						end

						constraint.TF2ItemBrowser_Item_SubModel(e, e2, v.role, v.attach_num, ply)
					end
					submodels_to_remove[v.role] = nil
				end

				if anim and e2:LookupSequence(anim.anim) != e2:GetSequence() then
					e2:SetModel(e2:GetModel()) //e2:LookupSequence can get stuck returning -1 for everything unless we give it a nudge like this
					timer.Simple(0, function() //do this on a timer, otherwise this won't work when changing the entity's model at the same time
						if !IsValid(e2) then return end
						e2:SetChannel1Sequence(e2:LookupSequence(anim.anim))
						e2:SetChannel1PauseFrame(0)
						e2:StartAnimation(1)
					end)
				end

				//Update the model and skin of each submodel
				if model and model != e2:GetModel() then //note: model will be nil here if we're toggling the team on an invalid custom item; just skip this part in that case
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

				//Update material override, paint, critglow, particles
				UpdateItemCustomization(e2, v.role)
			end
			//If the input disabled a submodel, then get rid of the ent(s) we were using for it
			for role, v in pairs (submodels_to_remove) do
				if istable(v) then
					for k2, v2 in pairs (v) do
						if IsValid(v2) then v2:Remove() end
					end
				elseif IsValid(v) then
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

			duplicator.ClearEntityModifier(e, "TF2ItemBrowser_Item") //StoreEntityModifier uses table.Copy, which means values that are present in the old table but absent in the new table will remain (i.e. when switching from a team-colored paint to single-color paint), and we don't want that, so wipe the table
			duplicator.StoreEntityModifier(e, "TF2ItemBrowser_Item", data)

		elseif input == "attach_item_remove" then

			local e = net.ReadEntity()
			if !IsValid(e) or e:GetParent() != ent or e:IsPlayer() then return end
			if !hook.Run("CanTool", ply, {Entity = e}, "remover", ply:GetTool("remover"), 1) then return end
			//TODO: what other hooks should we check to make sure this player is allowed to remove this entity? sandbox doesn't seem to have anything else obvious.

			//Revert bodygroup changes on the parent entity, and remove submodels
			TF2ItemBrowser_Item_DoUnequip(nil, e)

			e:Remove()

		elseif input == "attach_par_skin" then

			ent:SetSkin(net.ReadUInt(8))

		elseif input == "attach_par_fx" then
			
			local fx = net.ReadUInt(3)

			//do material overrides; parent entity only needs these ones
			local effect_mats = {
				[EFFECT_GOLD] = "models/player/shared/gold_player",
				[EFFECT_ICE] = "models/player/shared/ice_player",
			}
			local mat = effect_mats[fx]
			if mat then
				ent:SetMaterial(mat)
				duplicator.StoreEntityModifier(ent, "material", {MaterialOverride = mat})
			elseif table.KeyFromValue(effect_mats, ent:GetMaterial()) then
				//If the ent's current material is an fx material override we *don't* want to use any more, then clear it, but don't clobber unrelated materials
				ent:SetMaterial("")
				duplicator.ClearEntityModifier(ent, "material")
			end

			//matproxy stuff for EFFECT_JARATE
			if fx == EFFECT_JARATE then
				local team = ent:GetSkin() % 2 != 0
				local col = jarate[team]
				GiveMatproxyTF2CritGlow(ply, ent, {
					ColorR = col.x,
					ColorG = col.y,
					ColorB = col.z,
					RedSparks = 0,
					BluSparks = 0,
					ColorableSparks = 0,
					JarateSparks = 1,
					JarateColorableSparks = 0,
				})
			elseif ent.ProxyentCritGlow then
				if IsValid(ent.ProxyentCritGlow) then ent.ProxyentCritGlow:Remove() end
				ent.ProxyentCritGlow = nil
				duplicator.ClearEntityModifier(ent, "MatproxyTF2CritGlow")
			end

		end

	end)

	//This func cleans up various things when unequpping the item, and is only called upon undo or attach_item_remove input. 
	//The intention is that we *only* want to do these things when a player is using the browser to modify a class's loadout 
	//- we don't want submodels deleting themselves if a player is using them as ordinary sandbox props, or bodygroups/skins 
	//spontaneously changing if a player is bonemerging these props manually and then removing them.
	function TF2ItemBrowser_Item_DoUnequip(undotab, e)

		//Note: When a function is assigned to an undo with undo.AddFunction, the undo continues to exist in the queue even 
		//if its ent(s) are removed some other way. This means if we, say, attach 2 items to a model, remove the 2nd one with 
		//the browser's "remove" button, and then press the undo key, this function will get called for the 2nd item that no 
		//longer exists. Returning false here makes it silently skip over the bad undo, remove it from the queue, and move on 
		//to the next one instead, which is what we want. If we didn't do this, the player would press the undo key, see 'Undone 
		//"Attached Item"' for the item that isn't there any more, and have nothing happen, which would be bad and unintuitive.
		if undotab then
			local any_valid
			for k, v in pairs (undotab.Entities) do
				if IsValid(v) then any_valid = true break end
			end
			if !any_valid then return false end
		end

		if !IsValid(e) then return end
		local ent = e:GetParent()
		if !IsValid(ent) then return end

		//When unequipped, check if this item was applying any bodygroup changes to the parent ent that we want to revert.
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
			//Undo parent skin change for zombie skin items
			local i = TF2Items.items[e.EntityMods.TF2ItemBrowser_Item.id] or {}
			if i.attributes and i.attributes["player skin override"] and ent:GetSkin() > 3 then
				ent:SetSkin(ent:GetSkin() - 4)
				//but what if the player had *two* equipped and only removed *one*?? this is stupid, who's going to do this?
				for k, child in ipairs (ent:GetChildren()) do
					if child != e and child.EntityMods and child.EntityMods.TF2ItemBrowser_Item and !child.TF2ItemBrowser_Item_IsSubModelOf then
						i = TF2Items.items[child.EntityMods.TF2ItemBrowser_Item.id]
						if i.attributes and i.attributes["player skin override"] --[[and ent:SkinCount() > 4 and ent:GetSkin() <= 3]] then
							ent:SetSkin(ent:GetSkin() + 4)
							break
						end
					end
				end
			end
		end

		//Remove any existing submodels for the item as well
		if e.TF2ItemBrowser_Item_SubModels then
			for k, v in pairs (e.TF2ItemBrowser_Item_SubModels) do
				if IsValid(v) then v:Remove() end
			end
		end

	end

	//Constraint used to keep submodels associated with the main item entity between dupes/saves
	function constraint.TF2ItemBrowser_Item_SubModel(Ent1, Ent2, Role, Attach_Num, ply)

		timer.Simple(0, function() //wait a frame, because otherwise easy bonemerge can break this constraint when loaded from a dupe/save
			if !Ent1 or !Ent2 then return end

			if Role != "peplus" then
				Ent1.TF2ItemBrowser_Item_SubModels = Ent1.TF2ItemBrowser_Item_SubModels or {}
				if Attach_Num != nil then
					Ent1.TF2ItemBrowser_Item_SubModels[Role] = Ent1.TF2ItemBrowser_Item_SubModels[Role] or {}
					Ent1.TF2ItemBrowser_Item_SubModels[Role][Attach_Num] = Ent2
				else
					Ent1.TF2ItemBrowser_Item_SubModels[Role] = Ent2
				end
				Ent2.TF2ItemBrowser_Item_IsSubModelOf = Ent1
				//No DeleteOnRemove here, that's handled by TF2ItemBrowser_Item_DoUnequip
			else
				//this constraint is also used to associate particle effects with an item; don't do submodel stuff for these
				Ent1.TF2ItemBrowser_Item_Particles = Ent1.TF2ItemBrowser_Item_Particles or {}
				Ent1.TF2ItemBrowser_Item_Particles[Ent2] = true
			end
			
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
		//This entitymod exists to store item data on the entity for other funcs to access, and doesn't do anything on its own
		duplicator.StoreEntityModifier(e, "TF2ItemBrowser_Item", data)
	end)

	net.Receive("TF2ItemBrowser_AttachedItems_GetFromSv", function(_, ply)
		local ent = net.ReadEntity()
		if !IsValid(ent) then return end
		for _, ent2 in ipairs (table.Reverse(ent:GetChildren())) do //note: we reverse the table here so that when we attach items to a model, deselect it, then reselect it again, the items are returned in the same order they were attached in.
			if ent2.EntityMods and ent2.EntityMods.TF2ItemBrowser_Item and !ent2.TF2ItemBrowser_Item_IsSubModelOf then
				local data = ent2.EntityMods.TF2ItemBrowser_Item
				net.Start("TF2ItemBrowser_AttachedItem_SendToCl", true)
					net.WriteEntity(ent2)
					net.WriteBool(false) //don't open spawn panel upon received
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