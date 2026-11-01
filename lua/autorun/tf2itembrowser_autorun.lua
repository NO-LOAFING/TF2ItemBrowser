TF2ItemBrowser_Globals = TF2ItemBrowser_Globals or {} //container for various loose values we want to make available to all files
local tf = TF2ItemBrowser_Globals //and a much shorter local name so that it isn't super inconvenient to refer to in code, without potentially conflicting with other addons










//Read TF2 localization files, and use a separate custom function to get TF2 language strings so that we can't
//accidentally conflict with phrases from GMod or other addons that happen to use the same localization tokens.

if CLIENT then
	function tf.GetPhrase(str)
		local result
		if !isstring(str) then return end
		//if str doesn't start with a #, then it might not be a localized string, and in those cases 
		//we should just return the string we were given if we can't find one to localize it to
		if !string.StartsWith(str, "#") then result = str end

		result = tf.lang[string.TrimLeft(string.lower(str), "#")] or result
		return result
	end

	local function UpdateTFLanguageStrings(lang)
		local tab = file.Read("resource/chat_english.txt", "GAME") //also get chat_english for the "#chat_filterbutton" ("Filters") string we need
		if tab then
			tab = util.KeyValuesToTable(tab, true, false)
			tab = tab.tokens
		end
		tf.lang = tab or {}
		local tab = file.Read("resource/tf_english.txt", "tf")
		if tab then
			tab = util.KeyValuesToTable(tab, true, false).tokens
			if tab then
				table.Merge(tf.lang, tab)
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
					table.Merge(tf.lang, tab)
				end
			end
			local tab = file.Read("resource/tf_" .. langs[lang] .. ".txt", "tf")
			if tab then
				tab = util.KeyValuesToTable(tab, true, false).tokens
				if tab then
					table.Merge(tf.lang, tab)
				end
			end
		end
		//Fix KeyValuesToTable returning some strings as numbers if the text contained numbers only (i.e. #TF_TournamentMedal_2014)
		for k, v in pairs (tf.lang) do
			if !isstring(v) then tf.lang[k] = tostring(v) end
		end
		//MsgN("language is now ", lang)
		//note: conveniently, the context menu and all of its contents are reset upon changing languages, so we don't have to worry 
		//about resetting the browser to prevent odd behavior caused by controls still using values from the previous language
		tf.str_any = "(" .. string.lower(tf.GetPhrase("#TF_Any") or "Any") .. ")"
		tf.str_none = "(" .. string.lower(tf.GetPhrase("#TF_ImportPreview_Effect0") or "None") .. ")"
		tf.str_custom = "(" .. string.lower(tf.GetPhrase("#TF_ImportFile_CustomSkin") or "Custom") .. ")"
		if tf.classes then tf.classes[1].langstr = tf.str_any end
	end
	cvars.AddChangeCallback("gmod_language", function(_,_,new) UpdateTFLanguageStrings(new) end, "TF2ItemBrowser")
	UpdateTFLanguageStrings(GetConVar("gmod_language"):GetString())
end










//Global values used by both client and server

tf.classes = {
	{longname = "(any)",	shortname = "(any)",	langstr = tf.str_any},
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
tf.class_longname_to_id = {}
for k, v in ipairs (tf.classes) do
	tf.class_longname_to_id[v.longname] = k
end


tf.EFFECT_NONE = 0
tf.EFFECT_UBER = 1
tf.EFFECT_JARATE = 2
tf.EFFECT_GOLD = 3
tf.EFFECT_ICE = 4
tf.jarate_colors = {
	[false] = Vector(6, 9, 2),
	[true] = Vector(7, 5, 1),
}


function tf.GetDependency(name)

	if name == "pe+" then
		return PEPlus_FindPCFsFromEffect != nil
	elseif name == "hatpainter" then
		return ProxyentPaintColor_PackedRGBToTab != nil
	elseif name == "wp" then
		return istable(WP) and istable(WP.RNG) and istable(WP.Weapons) //"WP" is a pretty generic name, make extra sure it's the one we want
	elseif name == "animprop" then
		return (SERVER and (ConvertEntityToAnimprop != nil)) or duplicator.FindEntityClass("prop_animated") != nil //the latter isn't used in this addon (the only animprop code this addon uses is serverside), but we've got to use *something* for the clientside check
	elseif name == "advbone" then
		return (SERVER and (CreateAdvBonemergeEntity != nil)) or duplicator.FindEntityClass("ent_advbonemerge") != nil //^
	elseif name == "easybone" then
		return (SERVER and (rb655_ApplyBonemerge != nil)) or (CLIENT and file.Exists("weapons/gmod_tool/stools/rb655_easy_bonemerge.lua", "LUA")) //^; this addon really has nothing better to check for clientside
	end

end










//Read and process the TF2 item schema - we also modify some data to make it more convenient for the the addon's usage

local _s = file.Read("scripts/items/items_game.txt", "tf")
if !_s then
	if CLIENT then
		hook.Add("InitPostEntity", "TF2ItemBrowser_MountError", function()
			timer.Simple(1, function()
				notification.AddLegacy("ERROR: TF2 Item Browser couldn't find TF2's items_game.txt, is TF2 not mounted?", NOTIFY_ERROR, 10)
				chat.AddText("ERROR: TF2 Item Browser couldn't find TF2's items_game.txt, is TF2 not mounted?")
			end)
		end)
	else
		MsgN("ERROR: TF2 Item Browser couldn't find TF2's items_game.txt, is TF2 not mounted?")
	end
	TF2ItemBrowser_Globals = nil
	return
end
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
//1057 MvM GateBotLight Scout (and the others) - missing textures and all use the same name, bad localization for names and styles
//30143 tw_demobot_armor (and the others) - placeholder white circle


//Make items inherit values from prefabs, which themselves inherit values from other prefabs, and so on
local tab = {}
local function InheritPrefabValues(k, v, ptab, ptabname)
	//Go through prefabs of prefabs recursively
	if ptab.prefab then
		//Note: Prefabs are read in reverse order (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_schema.cpp#L2940-L2968);
		//see the many, many hats with prefab "no_craft hat", which override hat's craft_class "hat" with no_craft's craft_class ""
		for k2, v2 in ipairs (table.Reverse(string.Explode(" ", ptab.prefab))) do
			if !s.prefabs[v2] then MsgN("TF2ItemBrowser: ", k, " ", v.name, " ", ptabname, " tried to get invalid prefab \"", v2, "\"") continue end
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
	if !istable(v) then
		//check for bad non-table entries in items table, because one time some doofus at valve put the sounds for 31651 Grenadier's Goggles outside the item
		if GetConVarNumber("developer") >= 1 then
			MsgN("TF2ItemBrowser: items table contains bad non-table entry '", v, "', rejecting")
		end
		continue
	end
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
//these are used externally by TF2ItemBrowser_Icon, so make them globally accessible; the rest are only used in building the tf.TF2Items table
tf.paintkit_rarities = {}
tf.paintkit_ids_to_collections = {}

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
			if CLIENT then tab.name = (tf.GetPhrase("#TF_ScoreBoard_KillsLabel") or "Kills:") .. " " .. i end
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
for classid, _ in ipairs (tf.classes) do //sort these by class so we can filter them easily + print class-based ones in class order
	tab[classid] = {}
end
//Also use this opportunity to process item sets and collections in implementation order
tf.sets_ordered = {}
tf.collections_ordered = {}
tf.paintkit_collections = {}

for k, v in ipairs (s2) do
	if v.Key == "equip_regions_list" then
		for k2, v2 in ipairs (v.Value) do
			if istable(v2.Value) then
				local conflict_tab = {}
				for k3, v3 in pairs (v2.Value) do
					for classid, class in ipairs (tf.classes) do
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
						if !s.items[items_by_name[k3]].used_by_classes[tf.classes[classid].longname] then
							_cat[classid] = nil
						end
					end
					//Also keep track of which classes we should show this set for - in case of multi-class items, we still want
					//to list the set when we're filtering for one of the other classes, but categorize it separately.
					s.item_sets[v2.Key]._classes = s.item_sets[v2.Key]._classes or {}
					for class, _ in pairs (s.items[items_by_name[k3]].used_by_classes) do
						s.item_sets[v2.Key]._classes[tf.class_longname_to_id[class]] = true
					end
				end
			end
			if add_set then table.insert(tf.sets_ordered, v2.Key) end
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
								s.item_collections[v2.Key]._classes[tf.class_longname_to_id[class]] = true
							end
						//Also retrieve paintkit rarities and collections here
						elseif paintkit_items_to_ids[k4] then
							local id = paintkit_items_to_ids[k4]
							tf.paintkit_rarities[id] = k3
							tf.paintkit_ids_to_collections[id] = v2.Key
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
							s.item_collections[v2.Key]._classes[tf.class_longname_to_id[class]] = true
						end
					end
				end
			end
			if add_set then table.insert(tf.collections_ordered, v2.Key) end
			if add_paintkit_set then table.insert(tf.paintkit_collections, v2.Key) end
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


tf.TF2Items = s

//Make items with default paint colors (i.e. tournament medals) store them somewhere more easily accessible
//This has to be done on a timer so that we can be sure that Hat Painter's ProxyentPaintColor_PackedRGBToTab function exists
timer.Simple(0, function()
	if tf.GetDependency("hatpainter") then
		for k, v in pairs (tf.TF2Items.items) do
			if v.attributes and v.attributes["set item tint RGB"] then
				tab = {}
				local col = ProxyentPaintColor_PackedRGBToTab(v.attributes["set item tint RGB"].value)
				tab[false] = Vector(col[1], col[2], col[3])
				if v.attributes["set item tint RGB 2"] then
					col = ProxyentPaintColor_PackedRGBToTab(v.attributes["set item tint RGB 2"].value)
					tab[true] = Vector(col[1], col[2], col[3])
				end
				v._default_paint = tab
			end
		end
	end
end)


//Load custom items - items saved by the player will be in the data/ folder, while addons can include their own items in their data_static/ folder.
//These are determined by the server, not clients, because they need to be consistent between all users - if we want this feature to be useful in 
//multiplayer, then we want to have item defs for models that the server has available, not for whatever players happen to have saved on their end.
local function LoadCustomItems()
	if SERVER or game.SinglePlayer() then //in singleplayer, the client has access to the same data folder as the server, so it can just read the files on its own without networking; LocalPlayer():IsListenServerHost() doesn't work here because the player entity is null when we run this on startup
		//Clear any old custom items and repopulate them; it's possible that the change we made was removing one of them
		for k, v in pairs (tf.TF2Items.items) do
			if isstring(k) then tf.TF2Items.items[k] = nil end
		end

		local file_origins = {}
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
					tf.TF2Items.items[name] = f
					//Keep track of whether the item originates from data or data_static; if the 
					//same file path exists in both folders, then keep track of both of them.
					file_origins[name] = file_origins[name] or {}
					file_origins[name][path] = true
				end
			end
		end
		ReadCustomItems("data_static/tf2itembrowser_customitems/", "GAME")
		//in case of a name conflict (i.e. a player saving over an item from an addon), saved items in data folder take priority over addons
		ReadCustomItems("tf2itembrowser_customitems/", "DATA")
		for name, paths in pairs (file_origins) do
			tf.TF2Items.items[name]._file_origin = paths
		end

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
		for k, v in pairs (tf.TF2Items.items) do
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
			//Clear any old custom items and repopulate them; it's possible that the change we made was removing one of them
			for k, v in pairs (tf.TF2Items.items) do
				if isstring(k) then tf.TF2Items.items[k] = nil end
			end
			for k, v in pairs (tab) do
				v.name = tostring(v.name) //items with a number string for a name (i.e. "1") get turned into numbers by tabletojson/jsontotable, so tostring() them to be sure
				tf.TF2Items.items[tostring(k)] = v //same as above
			end
			TF2ItemBrowser_RequestCustomItems = nil
			if IsValid(TF2ItemBrowser) then TF2ItemBrowser:RebuildIconList() end
		end
	end)
end

function tf.PlayerCanEditCustomItems(ply)
	if game.SinglePlayer() then return true end
	if CLIENT then ply = LocalPlayer() end
	if !IsValid(ply) then return false end
	local result = hook.Run("TF2ItemBrowser_PlayerCanEditCustomItems", ply)
	if result == nil then result = true end
	return result
end
if !game.SinglePlayer() then
	local cv_alloweditor = CreateConVar("sv_tf2itembrowser_alloweditor", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Sets which players are allowed to add, edit, and delete custom TF2 items in a multiplayer game (0: no one, 1: super admins only, 2: admins only, 3: everyone)", 0, 3)
	//make this a removable hook just in case there's a server admin plugin somewhere out there that doesn't like the default gmod (super)admin system
	hook.Add("TF2ItemBrowser_PlayerCanEditCustomItems", "default_convar", function(ply)
		local cv = cv_alloweditor:GetInt()
		return (cv >= 1 and ply:IsSuperAdmin()) or (cv >= 2 and ply:IsAdmin()) or cv >= 3
	end)
end

if SERVER then
	util.AddNetworkString("TF2ItemBrowser_NewCustomItem_SendToSv")
	util.AddNetworkString("TF2ItemBrowser_DeleteCustomItem_SendToSv")
	util.AddNetworkString("TF2ItemBrowser_CustomItemsUpdate_SendToCl")

	net.Receive("TF2ItemBrowser_NewCustomItem_SendToSv", function(len, ply)
		local i = util.Decompress(net.ReadData(len/8), 8000) //max 8kb; these are small text files and definitely shouldn't be this large
		if !tf.PlayerCanEditCustomItems(ply) then return end

		local success = false
		if i then
			local tab = util.JSONToTable(i)
			if tab and tab.name and tab.name != "" then //an empty string for a name will save properly, but won't load
				if !file.IsDir("tf2itembrowser_customitems/", "DATA") then 
					file.CreateDir("tf2itembrowser_customitems/")
				end
				success = file.Write("tf2itembrowser_customitems/" .. tab.name .. ".txt", i)
			end
		end

		if success then
			//Rebuild serverside custom items table with the new item, and make players retrieve it
			LoadCustomItems()
			net.Start("TF2ItemBrowser_CustomItemsUpdate_SendToCl")
				net.WriteBool(false) //Other players don't care about confirmation status for this item
			net.SendOmit(ply)
		end
		//Tell the player who sent the file if saving was successful
		net.Start("TF2ItemBrowser_CustomItemsUpdate_SendToCl")
			net.WriteBool(true)
			net.WriteBool(success)
		net.Send(ply)
	end)

	net.Receive("TF2ItemBrowser_DeleteCustomItem_SendToSv", function(len, ply)
		local name = net.ReadString()
		if !tf.PlayerCanEditCustomItems(ply) then return end

		local success = file.Delete("tf2itembrowser_customitems/" .. name .. ".txt")
		
		if success then
			//Rebuild serverside custom items table without the deleted item, and make players retrieve it
			LoadCustomItems()
			net.Start("TF2ItemBrowser_CustomItemsUpdate_SendToCl")
				net.WriteBool(false) //Other players don't care about confirmation status for this item
			net.SendOmit(ply)
		end
		//Tell the player who sent the file if deletion was successful
		net.Start("TF2ItemBrowser_CustomItemsUpdate_SendToCl")
			net.WriteBool(true)
			net.WriteBool(success)
		net.Send(ply)
	end)
else
	net.Receive("TF2ItemBrowser_CustomItemsUpdate_SendToCl", function()
		LoadCustomItems()
		if net.ReadBool() then
			local success = net.ReadBool()
			if IsValid(TF2ItemBrowser_Editor) and IsValid(TF2ItemBrowser_Editor.SavePopup) then
				TF2ItemBrowser_Editor.SavePopup:DoConfirmation(success)
			end
		end
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
	elseif tab[tf.classes[class].longname] then
		return tab[tf.classes[class].longname]
	elseif tab.basename then
		return string.Replace(tab.basename, "%s", tf.classes[class].shortname)
	end
end

//Given an item data table with id, class, team, style, returns a table with the models, skin, and bodygroups to use.
function tf.GetItemModelVisuals(data)

	local i = tf.TF2Items.items[data.id] or {}
	local vis = {
		models = {},
		skin = nil,
		item_bg = {},
		ply_bg = {},
		ply_bg_forced = {},
	}
	local model

	//First go through standard values on the item
	model = GetClassModelWithBasename(i.model_player_per_class, data.class) or i.model_player
	vis.skin = i.default_skin or GetVisualsValue(i, data.team, "skin")
	local classbg = GetVisualsValue(i, data.team, "use_per_class_bodygroups")
	if classbg and classbg == 1 then
		classbg = {scout = 0, sniper = 1, soldier = 2, demoman = 3, medic = 4, heavy = 5, pyro = 6, spy = 7, engineer = 8}
		vis.item_bg["class"] = classbg[tf.classes[data.class].longname]
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
	//Note: this is a custom value used to add a non-style-based equivalent of style.additional_forced_bodygroups to custom items; 
	//if valve ever adds an official item with this same functionality, its value will have a different name from the one saved in 
	//old custom items, and we'll have to add handling for that
	for k, v in pairs (GetVisualsValue(i, data.team, "_player_forced_bodygroups") or {}) do
		vis.ply_bg[k] = v
		vis.ply_bg_forced[k] = true
	end
	//note: there's also visuals.show_player_bodygroup_name, only used by 1098 The Classic with value "bullets", which doesn't appear to do anything

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
		if style.additional_forced_bodygroups then
			for k, v in pairs (style.additional_forced_bodygroups) do
				vis.ply_bg[k] = v
				vis.ply_bg_forced[k] = true
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
		vis.models.taunt_prop = i.taunt.custom_taunt_prop_per_class[tf.classes[data.class].longname]
	end
	if i.static_attrs then
		vis.models.stat_clock = i.static_attrs.weapon_uses_stattrak_module
		vis.stat_clock_scale = i.static_attrs.weapon_stattrak_module_scale
	end

	return vis

end

function tf.GetItemDefaultParticleEffects(data)

	local i = tf.TF2Items.items[data.id] or {}
	local pe_def = {}

	if i.visuals and i.visuals.attached_particlesystems then
		for k, v in pairs(i.visuals.attached_particlesystems) do
			if !tf.GetDependency("pe+") or PEPlus_FindPCFsFromEffect(v.system) then //note: if pe+ is uninstalled, then we can't check the validity of fx - default to adding them all to the list, so that we can display a warning that the item should have fx but isn't able to add them. this means items with invalid fx (eureka effect) will mistakenly show an unusable checkbox for default fx that won't appear when pe+ is installed, but this is harmless.
				table.insert(pe_def, v)
			end
		end
	end
	if i.attributes and i.attributes["attach particle effect static"] then
		local tab = tf.TF2Items.attribute_controlled_attached_particles_all[i.attributes["attach particle effect static"].value]
		if tab and (!tf.GetDependency("pe+") or PEPlus_FindPCFsFromEffect(tab.system)) then
			if CLIENT then
				tab = table.Copy(tab)
				tab._displayname = tf.GetPhrase("#Attrib_Particle" .. i.attributes["attach particle effect static"].value) //can be nil; uses the effect name if so
			end
			table.insert(pe_def, tab)
		end
	end
	if i.attributes and i.attributes["attach particle effect"] then
		local tab = tf.TF2Items.attribute_controlled_attached_particles_all[i.attributes["attach particle effect"].value]
		if tab and (!tf.GetDependency("pe+") or PEPlus_FindPCFsFromEffect(tab.system)) then
			if CLIENT then
				tab = table.Copy(tab)
				tab._displayname = tf.GetPhrase("#Attrib_Particle" .. i.attributes["attach particle effect"].value) //can be nil; uses the effect name if so
			end
			table.insert(pe_def, tab)
		end
	end

	return pe_def

end

function tf.GetItemUnusualEffects(id)

	local i = tf.TF2Items.items[id] or {}
	local tab, type = nil, nil

	//hat unusuals
	if i.item_slot == "misc" or i.item_slot == "head" then //originally i considered limiting this to "hat" and "whole_head" equip regions, and then manually adding overrides for items that can be unusual because they had these regions in the past, but this would require upkeep as regions get changed in the future. instead, just make all cosmetics unusual-able, no matter how absurd. here's the list of items i had, for reference: (Bonk Boy, Soldier's Stash, Exquisite Rack, Coldfront Curbstompers, Pyromancer's Mask, HazMat Headcase, Coffin Kit, Large Luchador, Hunter Heavy, Sleeveless in Siberia, Mining Light, Pencil Pusher, Brainiac Hairpiece, Blighted Beak, Das Hazmattenhatten,  Master's Yellow Belt, Villain's Veil, Soldered Sensei, Le Party Phantom, Noh Mercy, Antlers, Virtual Viewfinder, Polar Pullover, Captain Space Mann)
		for k, v in pairs (tf.TF2Items.attribute_controlled_attached_particles.cosmetic_unusual_effects) do
			if k == 20 or k == 28 or k == 406 then continue end //map stamps, genteel smoke and coin_spin are not unusuals
			if v.system:EndsWith("_teamcolor_blue") then continue end
			tab = tab or {}
			table.insert(tab, {k = k, v = v})
		end
		type = "hat"
	//wep unusuals
	elseif i.particle_suffix then
		for k, v in pairs (tf.TF2Items.attribute_controlled_attached_particles.weapon_unusual_effects) do
			if v.use_suffix_name and (tf.GetDependency("pe+") and !PEPlus_FindPCFsFromEffect(v.system .. "_" .. i.particle_suffix)) then continue end
			tab = tab or {}
			table.insert(tab, {k = k, v = v})
		end
		type = "wep"
	end
	if tab and #tab > 0 then
		return tab, type
	end
end

function tf.GetDefaultItemDataTable(id)

	local data = {
		id = id, 
		class = 11, //default to "none"
		team = TF2ItemBrowser.attopts.team.Value,
		style = 0,

		models = {
			item = true,
			wearable = true,
			wearable_2 = false,
			taunt_prop = false,
			attached_festive = false,
			stat_clock = false,
		},

		//fx
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

		pe_def = tf.GetDependency("pe+"),
		pe_unusual = 0,
		pe_unusual_offset = nil,

		wp = {
			enabled = false,
			id = 0,
			wear = 1,
			seed = "1",
		}
	}

	local i = tf.TF2Items.items[id] or {}

	local _, class = TF2ItemBrowser.filters.class:GetSelected()
	if i.used_by_classes[tf.classes[class].longname] then
		//default to the selected class filter, if applicable
		data.class = class
	else
		//go through classes in order, default to the first one that can use this item
		for k, v in ipairs (tf.classes) do 
			if i.used_by_classes[v.longname] then
				data.class = k
				break
			end
		end
	end

	local _, fx = TF2ItemBrowser.attopts.fx:GetSelected()
	data.fx = fx

	if i.visuals and i.visuals.styles then
		//default to the first style listed; i THINK this is always 0 but let's make extra sure
		for k, v in SortedPairs (i.visuals.styles) do //this starts from 0 so we can't do ipairs
			data.style = k
			break
		end
	end

	if tf.GetDependency("wp") then
		data.wp.seed = tostring(WP.RNG.RandomSeed())
	end

	//tf.SanitizeItemDataTable(data) //every func that uses the data table ends up running Sanitize on it anyway, so don't bother running it twice
	return data

end

function tf.SanitizeItemDataTable(data)

	//submodels that aren't used by this item are set to nil instead of false, so that we know not to add controls for them
	local vis = tf.GetItemModelVisuals(data)
	if !vis.models.item then data.models.item = nil end
	if !vis.models.wearable then data.models.wearable = nil end
	if !vis.models.wearable_2 then data.models.wearable_2 = nil end
	if !vis.models.taunt_prop then data.models.taunt_prop = nil
	elseif !vis.models.item then data.models.taunt_prop = true end
	if !vis.models.attached_festive then data.models.attached_festive = nil end
	if !vis.models.stat_clock then data.models.stat_clock = nil end

	if #tf.GetItemDefaultParticleEffects(data) == 0 then data.pe_def = false end

	local i = tf.TF2Items.items[data.id] or {}
	if i._default_paint and !data.paint.enabled then
		data.paint.enabled = true
		data.paint.col = table.Copy(i._default_paint)
	end

end

if CLIENT then
	function tf.GetItemStyleName(item_id, style_id)
		local i = tf.TF2Items.items[item_id]
		if !i or !i.visuals or !i.visuals.styles then return "INVALID STYLE " .. style_id end
		local style = i.visuals.styles[style_id]
		if !style then return "INVALID STYLE " .. style_id end

		local name = tf.GetPhrase(style.name) or style.name
		if !name then
			if isstring(item_id) then
				name = tf.GetNumberedStyleString(style_id+1)
			elseif style.aus_prefix then
				name = string.Trim(tf.GetPhrase("#ItemNameAustralium") or "#ItemNameAustralium")
			elseif style_id == 0 then //assume this is the non-australium style for weapons with australium
				name = tf.GetPhrase("#TF_style0_normal") or "#TF_style0_normal"
			end
		end
		return name or "BAD UNNAMED STYLE " .. style_id
	end

	//Used for unnamed styles in custom items
	function tf.GetNumberedStyleString(i)
		local str = tf.GetPhrase("#TF_style" .. tostring(i-1))
		if !str then str = (tf.GetPhrase("#Context_Style") or "Style") .. " " .. tostring(i) end
		return str
	end
end










if CLIENT then
	//All common values and funcs used for TF2-themed vgui styling

	tf.LoadoutItemPopupBorder = GWEN.CreateTextureBorder(0, 0, 64, 64, 11, 11, 11, 11, Material("vgui/button_holder_central.vmt"))
	tf.GrayDialogBorder = GWEN.CreateTextureBorder(0, 0, 256, 128, 24, 24, 24, 24, Material("vgui/loadout_rect.vmt"))
	tf.TFThinLineBorder = GWEN.CreateTextureBorder(0, 0, 128, 128, 24, 24, 24, 24, Material("hud/tournament_panel_brown.vmt"))
	tf.OutlinedGreyBox = GWEN.CreateTextureBorder(0, 0, 128, 64, 24, 24, 24, 0, Material("vgui/loadout_round_rect_selected.vmt"))
	tf.item_icon_sizes = {
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
	for k, v in pairs (tf.item_icon_sizes[2]) do //just make a small size that's exactly half the normal size, this works better
		tf.item_icon_sizes[1][k] = v/2//math.Round(v/2)
	end
	tf.cv_icon_size = CreateClientConVar("cl_tf2itembrowser_iconsize", "1", true, false, "Size of icons in TF2 item browser (1 = small, 2 = large)", 1, #tf.item_icon_sizes)

	tf.popup_w = 480 //keep the width consistent between popup panels, so that when we switch from mouseoverpanel to spawnpanel, it maintains the same horizontal position; global because this is used by both TF2ItemBrowser and TF2ItemBrowser_Icon
	tf.popup_pad = 25 //34 would match the padding in tf2's backpack screen, but our text is smaller (13px, from 18px), so scale it down proportionately
	tf.betweenitems = 8
	tf.betweencategories = 20
	tf.spinner = Material("vgui/animated/tf2_logo_hourglass.vmt")
	tf.close_button = Material("vgui/close_button.vmt")
	tf.close_button_nocircle = Material("vgui/glyph_close_x.vmt")
	surface.CreateFont("TF2ItemBrowser_ItemName", {
		font = "TF2 Build",
		size = 20, //these are really wimpy units; this matches the size of the item names when spectating players
		extended = true
	})
	surface.CreateFont("TF2ItemBrowser_ItemName_Larger", {
		font = "TF2 Build",
		size = 32, //larger variant for custom item editor dialog box headers
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
	tf.gui_colors = {
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
	tf.quality_colors = {
		normal		= Color(178,178,178,255),
		rarity1		= Color(77,116,85,255), //genuine
		rarity2		= Color(141,131,75,255), //"customized (unused)"
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
	tf.rarity_colors = {
		default		= Color(131,126,119,255),
		common		= Color(176,195,217,255),
		uncommon	= Color(94,152,217,255),
		rare		= Color(75,105,255,255),
		mythical	= Color(136,71,255,255),
		legendary	= Color(211,44,230,255),
		ancient		= Color(235,75,75,255),
	}
	tf.desc_colors = {
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

	local snd_hover = "ui/item_info_mouseover.wav"
	local snd_click = "tf_buttonclick.wav" //custom path because this gets overridden by hl2 sound
	local snd_release = "tf_buttonclickrelease.wav" //^
	function tf.AddTFButtonSounds(pnl, hoveronly)
		function pnl:OnCursorEntered()
			if !pnl.IsEnabled or pnl:IsEnabled() then
				surface.PlaySound(snd_hover)
			end
		end
		if !hoveronly then
			function pnl:OnDepressed()
				surface.PlaySound(snd_click)
			end
			function pnl:OnReleased()
				surface.PlaySound(snd_release)
			end
		end
	end

	function tf.AddTFStyleToVGUI(pnl, alt_style)
		local class = pnl:GetName()
		if class == "DCheckBox" then
			function pnl:Paint(w,h)
				local x, y = w/2, h/2
				local col = tf.gui_colors.TransparentBlack
				//if !self:IsEnabled() then col = tf.gui_colors.TanDark end //override used in testitembotcontrols.res //actually this looks awful
				surface.SetDrawColor(col)
				surface.DrawRect(0,0,w,h)

				col = tf.gui_colors.Yellow
				if self.NegativeCheck then
					col = tf.gui_colors.LightRed
				elseif !self:IsEnabled() then
					col = tf.gui_colors.TanDark //custom, match the appearance of other disabled vgui elements
				end
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
			tf.AddTFStyleToVGUI(pnl.Button)
			pnl:SetHeight(20)
			function pnl:PerformLayout()
				local x = self.m_iIndent || 0

				self.Button:SetSize( 20, 20 ) //change 1/2
				self.Button:SetPos( x, math.floor( ( self:GetTall() - self.Button:GetTall() ) / 2 ) )

				self.Label:SizeToContents()
				self.Label:SetPos( x + self.Button:GetWide() + 6, math.floor( ( self:GetTall() - self.Label:GetTall() ) / 2 ) ) //+6 to width is change 2/2
			end
			pnl.Label:SetColor(tf.gui_colors.Yellow)
			pnl.Label:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
		elseif class == "DComboBox" then
			pnl:SetColor(tf.gui_colors.TanLight)
			pnl:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
			pnl.DropButton:Remove()
			function pnl:Paint(w,h)
				local col = tf.gui_colors.TanLight
				if !self:IsEnabled() then col = tf.gui_colors.TanDark end //copy how we do disabled checkboxes; the authentic tf2 behavior is to just blank out the box which isn't as readable
				self:SetColor(col)
				surface.SetDrawColor(col)
				surface.DrawOutlinedRect(0,0,w,h,1)

				surface.SetFont("TF2ItemBrowser_GUISymbols")
				local _w, _h = surface.GetTextSize("u")
				draw.SimpleText("u", "TF2ItemBrowser_GUISymbols", w-_w, 0, col) //down-pointing arrow

				local par = self:GetParent()
				if IsValid(par) and IsValid(par.Label) then
					par.Label:SetTextColor(col)
				end
			end
			function pnl:PerformLayout() end
			function pnl:OnMenuOpened(menu)
				tf.AddTFStyleToVGUI(menu)
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
			tf.AddTFStyleToVGUI(pnl:GetVBar())
			for _, v in ipairs (pnl:GetCanvas():GetChildren()) do
				local name = v:GetName()
				if name == "DMenuOption" then
					v:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
					function v:Paint(w, h)
						local col = tf.gui_colors.TanLight
						if self.Hovered or self.Highlight or (self.SubMenu and self.SubMenu:IsVisible()) then
							surface.SetDrawColor(tf.gui_colors.TanLight)
							surface.DrawRect(0,0,w,h)
							col = tf.gui_colors.TanDark
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
						tf.AddTFStyleToVGUI(v.SubMenu)
					end
				elseif name == "DPanel" and v:GetTall() == 1 then //spacer
					function v:Paint(w, h)
						surface.SetDrawColor(tf.gui_colors.TanLight)
						surface.DrawRect(0,0,w,h)
					end
				end
			end
		elseif class == "DButton" or class == "DImageButton" then
			tf.AddTFButtonSounds(pnl)
			//pnl:SetHeight(30) //backpack page button proportions
			pnl:SetHeight(36) //standard button proportions
			pnl:SetFont("TF2ItemBrowser_ItemName")
			pnl.BGColor = tf.gui_colors.TanDark
			pnl.FGColor = tf.gui_colors.TanLight
			pnl.DepressedBGColor = tf.gui_colors.TFOrange
			pnl.DepressedFGColor = tf.gui_colors.TanDarker //same as Black from TF2 clientscheme
			pnl.ArmedBGColor = tf.gui_colors.TFOrange
			pnl.ArmedFGColor = tf.gui_colors.TanLight
			function pnl:Paint(w, h)
				local col = self.BGColor
				local textcol = self.FGColor
				if self:IsEnabled() then
					if self.Depressed then
						col = self.DepressedBGColor
						textcol = self.DepressedFGColor
					elseif self.Hovered then
						col = self.ArmedBGColor
						textcol = self.ArmedFGColor
					end
				else
					textcol = self.DepressedFGColor
				end
				draw.RoundedBox(12, 0,0,w,h, col)
				self:SetColor(textcol)
			end
		elseif class == "DTextEntry" or class == "DNumberWang" then
			pnl:SetHeight(20) //30 would be more accurate proportionately, but it's too big to fit nicely
			if !alt_style then
				//light textbox, modeled after TF2 backpack search
				pnl:SetFont("TF2ItemBrowser_ItemDesc") //_Smaller is too hard to read with dark text on a bright background
				pnl.BGColor = tf.gui_colors.Yellow
				pnl.FGColor = tf.gui_colors.TanDark
			else
				//dark textbox, modeled after TF2 war paint seed entry
				pnl:SetFont("HudSelectionText") //default verdana but slightly larger
				pnl.BGColor = tf.gui_colors.TransparentBlack
				pnl.FGColor = tf.gui_colors.Gray
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
					self:DrawTextEntryText(self.FGColor_Placeholder, tf.gui_colors.Gray, tf.gui_colors.Gray)
				else
					self:DrawTextEntryText(self.FGColor, tf.gui_colors.Gray, tf.gui_colors.Gray)
				end
				if !oldtext then self:SetText("") end
			end
			//note: can't figure out how to modify the appearance of the right-click menu, it might be hard-coded in C++
		elseif class == "DScrollPanel" then
			tf.AddTFStyleToVGUI(pnl:GetVBar())
		elseif class == "DVScrollBar" then
			//ugly default tf2 clientscheme styled scrollbar, this is close enough to what's used by all the scrollbars in tf2 with buttons
			function pnl:Paint(w,h) end
			function pnl.btnUp:Paint(w,h)
				draw.SimpleText("t", "TF2ItemBrowser_GUISymbols", w/2, h/2, tf.gui_colors.Gray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) //up-pointing arrow
			end
			function pnl.btnDown:Paint(w,h)
				draw.SimpleText("u", "TF2ItemBrowser_GUISymbols", w/2, h/2, tf.gui_colors.Gray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) //down-pointing arrow
			end
			function pnl.btnGrip:Paint(w,h)
				surface.SetDrawColor(tf.gui_colors.Gray)
				surface.DrawRect(0,0,w,h)
			end
		elseif class == "DNumSlider" then
			pnl.Label:SetColor(tf.gui_colors.TanLight)
			pnl.Label:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
			pnl:SetHeight(21) //slightly taller to make sure that the taller notches fit
			tf.AddTFStyleToVGUI(pnl.TextArea, true) //use alt style for textentry; TF2 sliders don't have textentries at all, so just go with what looks best
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
				surface.SetDrawColor(tf.gui_colors.Slider_TrackColor)
				surface.DrawRect(4, h/2-2, w-7, 4)
				if pnl:IsEnabled() then
					surface.SetDrawColor(tf.gui_colors.TanLight) //emulate the TanLight color used by unusual position slider (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/client/tf/vgui/class_loadout_panel.cpp#L310)
				else
					surface.SetDrawColor(tf.gui_colors.Slider_DisabledTextColor)
				end
				PaintNotches(8, h/2-1, w-16, 1, self:GetNotches())
			end
			pnl.Slider.Knob:SetTall(16)
			function pnl.Slider.Knob:Paint(w,h)
				if pnl:IsEnabled() then
					surface.SetDrawColor(tf.gui_colors.TanLight) //somehow the unusual position slider's knob color is the same as the tick color. i can't find the code for this, but just go with it.
				else
					surface.SetDrawColor(tf.gui_colors.Slider_DisabledTextColor)
				end
				surface.DrawRect(4,0,w/2+1,h)
			end
		elseif class == "DColorMixer" then
			pnl.label:SetColor(tf.gui_colors.TanLight)
			pnl.label:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
			function pnl.PerformLayout(self, x, y)
				//Modified version of CtrlColor:PerformLayout (https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/gamemode/spawnmenu/controls/ctrlcolor.lua#L13)
				//Only does palette button sizes, doesn't clamp their sizes and resizes them more smoothly
				local ColorRows = #self.Palette:GetChildren() / 3
				self.Palette:SetButtonSize(self:GetWide() / ColorRows)
			end
			tf.AddTFStyleToVGUI(pnl.txtR, true)
			tf.AddTFStyleToVGUI(pnl.txtG, true)
			tf.AddTFStyleToVGUI(pnl.txtB, true)
			pnl.txtR.FGColor = tf.desc_colors.negative
			pnl.txtG.FGColor = tf.quality_colors.selfmade
			pnl.txtB.FGColor = tf.desc_colors.positive
		elseif class == "DHorizontalScroller" then
			//just do something close enough to the visual theme of the clientscheme-styled vertical scrollbar
			function pnl.btnLeft:Paint(w,h)
				surface.SetDrawColor(color_black) //not great but necessary to make the buttons visible against the background
				surface.DrawRect(0,0,w,h)
				draw.SimpleText("w", "TF2ItemBrowser_GUISymbols", (w/2)-1, h/2, tf.gui_colors.Gray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) //left-pointing arrow
			end
			function pnl.btnRight:Paint(w,h)
				surface.SetDrawColor(color_black)
				surface.DrawRect(0,0,w,h)
				draw.SimpleText("8", "TF2ItemBrowser_GUISymbols", w/2, h/2, tf.gui_colors.Gray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) //right-pointing arrow
			end
		elseif class == "DFrame" or class == "TF2ItemBrowser" or class == "TF2ItemBrowser_Editor" then
			local title = pnl:GetTitle()
			local header = 30 //this has to be pretty tall to fit the close button comfortably
			local border = 3
			pnl:SetTitle("")
			pnl:ShowCloseButton(false)
			pnl:DockPadding(border+8, header+8, border+8, border+8)


			local text = vgui.Create("DLabel", pnl)
			text:SetContentAlignment(4) //top middle
			text:SetFont("TF2ItemBrowser_ItemName")
			text:SetColor(tf.gui_colors.LightRed)
			text:SetText(">>")
			text:SizeToContents()
			text:SetPos(8, ((header)/2) - (text:GetTall()/2) + 1)
			local w = text:GetWide()

			local text = vgui.Create("DLabel", pnl)
			text:SetContentAlignment(4) //top middle
			text:SetFont("TF2ItemBrowser_ItemName")
			text:SetColor(tf.gui_colors.TanLight)
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
					surface.SetDrawColor(tf.gui_colors.LightRed)
				else
					surface.SetDrawColor(tf.gui_colors.TanDark)
				end
				surface.SetMaterial(tf.close_button)
				surface.DrawTexturedRect(0,0,w,h)
			end
			tf.AddTFButtonSounds(close)
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
				surface.SetDrawColor(tf.gui_colors._header)
				surface.DrawRect(0,0,w,h)
				//draw main body
				surface.SetDrawColor(tf.gui_colors.TanDarker)
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
	function tf.TFStyleVGUI(class, par, alt_style)
		local pnl = vgui.Create(class, par)
		if IsValid(pnl) then
			tf.AddTFStyleToVGUI(pnl, alt_style)
		end
		return pnl
	end
	function tf.AddTFStyleTooltip(self, text, font, fgcol, bgcol)
		font = font or "TF2ItemBrowser_ItemDesc_Smaller"
		fgcol = fgcol or tf.gui_colors.TanLight
		bgcol = bgcol or color_black
		if !self.TFStyleTooltip then
			local old_Paint = self.Paint
			function self:Paint(w,h,...)
				if self:IsHovered() and self.TFStyleTooltip != "" then
					if !IsValid(TF2ItemBrowser_Tooltip) or TF2ItemBrowser_Tooltip.Owner != self then
						local time = CurTime()
						self.HoverTime = self.HoverTime or time
						if time - self.HoverTime > 0.1 then
							local pnl = vgui.Create("DLabel", g_ContextMenu)
							pnl:SetFont(font)
							pnl:SetText(self.TFStyleTooltip)
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
		self.TFStyleTooltip = text
	end
	//convenience func for adding labels to dropdown dcomboboxes and such
	function tf.AddTFLabelToVGUI(child, label)
		local parent = child:GetParent()
		local pnl = vgui.Create("Panel", parent)
		pnl.Label = vgui.Create("DLabel", pnl)
		pnl.Label:SetColor(tf.gui_colors.TanLight)
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










	//These functions are used for rendering item models by both icons and the editor, so make them global

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
	function tf.DrawItemModels(x, y, w, h, models, particles, ang, CamPos, FOV)

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
			//Update color of halloween spell paints (note: this shouldn't be populated if hatpainter addon isn't found)
			if v.ProxyentPaintColor and v.ProxyentPaintColor.Override then
				v.ProxyentPaintColor.Color = ProxyentPaintColor_GetOverrideColor(v.ProxyentPaintColor.Override)/255
			end
			//Render all models
			v:SetEyeTarget(CamPos)
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

	function tf.DoItemModelCamera(models, icon, dont_rotate_viewangle_with_model)

		local attach
		if models[1] then attach = models[1]:GetAttachment(models[1]:LookupAttachment("icon_camera")) end
		if attach and icon and !isstring(icon.data.id) and !tf.TF2Items.items[icon.data.id]._disable_icon_camera and !icon.data.models.wearable and !icon.data.models.wearable_2 and !icon.data.models.taunt_prop then
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

				
				local _, ViewAngle, fov = nil, Angle( 25, 220, 0 ), 4
				if !dont_rotate_viewangle_with_model then
					//rotate the angle to account for rotated models
					_, ViewAngle = LocalToWorld(vector_origin, ViewAngle, vector_origin, models[1]:GetAngles())
				else
					//we don't need to add this extra bloat if the camera is rotating with the entity because rotated ents already bloat up their bounds a bit
					fov = fov + size * 0.04
				end
				local ViewPos = models[1]:GetPos() + ViewAngle:Forward() * size * -15

				//Apply the changes to the camera
				return {
					pos = ViewPos + middle,
					fov = fov,
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

	function tf.CreateItemIconModelPanel(par)

		local mdl = par:Add("DAdjustableModelPanel")
		mdl.models = {}
		mdl.particles = {}
		mdl.PaintMargin = 0

		//Custom paint func using our tf.DrawItemModels func
		function mdl:Paint(w, h)
			if !mdl.models or !mdl.models[1] or !mdl.particles then return end
			for k, v in ipairs (mdl.particles) do
				//if a particlesystem becomes invalid (i.e. a conflicting effect was loaded) then bail out and refresh the fx
				if !IsValid(v) then mdl:Refresh() break end
			end

			-- Get the panel's scissor rect, and apply it to model render
			local enabled, leftx, topy, rightx, bottomy = surface.GetScissorRect()
			render.SetScissorRect( leftx, topy, rightx, bottomy, enabled )

			local x, y = mdl:LocalToScreen(mdl.PaintMargin, mdl.PaintMargin)
			tf.DrawItemModels(x, y, w-(mdl.PaintMargin*2), h-(mdl.PaintMargin*2), mdl.models, mdl.particles, mdl.aLookAngle, mdl.vCamPos, mdl.fFOV)
			mdl.LastPaint = RealTime() //this is in DModelPanel's Paint func, i'm not sure this does anything any more

			render.SetScissorRect( 0, 0, 0, 0, false )
		end

		//for override
		function mdl:Refresh()
		end

		//Modified OnMousePressed to make the orbit movement account for the rotation of the entity
		local old_OnMousePressed = mdl.OnMousePressed
		function mdl:OnMousePressed( mousecode )
			if self.UseTurntableMovement then return old_OnMousePressed(self, mousecode) end

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
		local old_FirstPersonControls = mdl.FirstPersonControls
		function mdl:FirstPersonControls()
			if self.UseTurntableMovement then return old_FirstPersonControls(self) end

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

		function mdl:OnRemove()
			//Clean up models and particles
			for k, v in ipairs (self.models) do
				if IsValid(v) then v:Remove() end
			end
			for k, v in ipairs (self.particles) do
				if IsValid(v) then v:StopEmissionAndDestroyImmediately() end
			end
		end

		return mdl

	end










	//Make the browser accessible in the context menu

	list.Set("DesktopWindows", "TF2ItemBrowser", {
		title		= "TF2 Items", //"TF2 Item Browser" is just ever-so-slightly too long to fit in the desktop icon's label, hrmph
		icon		= "games/16/tf.png", //TODO: temp, make one that's the correct size later
		width		= 924,
		height		= 691,
		onewindow	= true,
		init		= function(icon, window)
			//Replace the generic DFrame with our custom vgui element
			icon.Window = g_ContextMenu:Add("TF2ItemBrowser")
			TF2ItemBrowser = icon.Window
			icon.Window:SetSize(window:GetSize())
			icon.Window:Center()
			window:Remove()
		end
	})

	//Func used by both the browser and item icons to open the editor
	function TF2ItemBrowser_OpenCustomItemEditor(id)
		if !tf.PlayerCanEditCustomItems() then return end
		if IsValid(TF2ItemBrowser_Editor) then TF2ItemBrowser_Editor:Close() end

		local editor = g_ContextMenu:Add("TF2ItemBrowser_Editor")
		TF2ItemBrowser_Editor = editor
		editor:SetSize(924,720) //TODO: finalize later
		editor:Center()
		editor:OpenEditor(id)
	end
end

properties.Add("tf2itembrowser_select", {
	MenuLabel = "Select with TF2 Item Browser",
	Order = 1,
	MenuIcon = "games/16/tf.png",
	AppendSpacer = true, //doesn't work, lame
	
	Filter = function(self, ent, ply)
		if !IsValid(TF2ItemBrowser) or !IsValid(ent) then return false end
		if !tf.GetDependency("advbone") and !tf.GetDependency("easybone") then return false end //if both bonemerge tools are uninstalled, then we can't attach items, so don't let us select an ent to attach items to
		if !(ent:LookupBone("bip_pelvis") or (IsValid(ent.AttachedEntity) and ent.AttachedEntity:LookupBone("bip_pelvis"))) then return false end //make sure it has the right skeleton to attach tf2 items to
		if !gamemode.Call("CanProperty", ply, "tf2itembrowser_select", ent) then return false end
		return true
	end,

	Action = function(self, ent)
		TF2ItemBrowser:SetEntity(ent)
	end
})










//Networking for browser inputs, including all functionality for spawning items in the world

tf.BrowserInputs = {
	[0] = "item_spawn",
	"attach_item_spawn",
	"attach_item_modify",
	"attach_item_remove",
	"attach_par_skin",
	"attach_par_fx",
}
tf.BrowserInputs_bits = 3 //max 7
tf.BrowserInputs = table.Flip(tf.BrowserInputs)
//How this works:
//- table.Flip sets the table to {channel_sequence = 0}, and so on
//- net.Write retrieves the corresponding number of a string with tf.BrowserInputs[input], then sends that number
//- net.Read gets the number, then retrieves its corresponding string with table.KeyFromValue(tf.BrowserInputs, input)
//This lets us add as many networkable strings to this table as we want, without having to manually assign each one a number.

function tf.WriteItemDataTable(data)
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
		net.WriteString(tostring(data.wp.seed))
	end
end

function tf.ReadItemDataTable()
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
			seed = "1",
		}
		if tf.GetDependency("wp") then
			tab.wp.seed = tostring(WP.RNG.RandomSeed())
		end
	end

	return tab
end

if SERVER then
	util.AddNetworkString("TF2ItemBrowser_Input_SendToSv")
	util.AddNetworkString("TF2ItemBrowser_AttachedItems_GetFromSv")
	util.AddNetworkString("TF2ItemBrowser_AttachedItem_SendToCl")

	//This is defined here because it's used by both the spawn/modify input below, AND the TF2ItemBrowser_Item_DoUnequip func further down
	local function UpdatePlayerBodygroups(e, ent, vis, old_vis, e_being_removed)
		//If this item does anything involving player bodygroups, then we need to reset the parent ent's bodygroups from scratch. For 
		//example, even if we updated this item's style and it no longer disables one bodygroup, some other attached item may still be 
		//disabling it. Instead, we have to go through every attached item, and apply their ply_bg's again to a blank slate parent ent.
		if table.Count(vis.ply_bg) > 0 or (old_vis and table.Count(old_vis.ply_bg) > 0) then
			local bgs = {}
			//31635 Skeleton Crew has this wacky "additional_forced_bodygroups" that actively overrides other items' bodygroups,
			//for the purpose of disabling 230 The Sydney Sleeper's "darts" bodygroup. If we don't do a special check for this,
			//then it becomes dependent on load order - equipping sleeper then crew enables-then-disables the darts as intended, 
			//but equipping crew then sleeper disables-then-enables the darts, causing them to appear when they shouldn't.
			local bgs_forced = {}

			for k, child in ipairs (ent:GetChildren()) do
				if child.EntityMods and child.EntityMods.TF2ItemBrowser_Item and !child.TF2ItemBrowser_Item_IsSubModelOf then
					if e_being_removed and child == e then continue end
					local child_vis
					if child == e then
						child_vis = vis
					else 
						child_vis = tf.GetItemModelVisuals(child.EntityMods.TF2ItemBrowser_Item)
					end
					for k, v in pairs (child_vis.ply_bg) do
						if isstring(k) then k = ent:FindBodygroupByName(k) end //on some items, k is a number already
						if bgs_forced[k] then continue end
						bgs[k] = v
					end
					for k, v in pairs (child_vis.ply_bg_forced) do
						if isstring(k) then k = ent:FindBodygroupByName(k) end
						bgs_forced[k] = true
					end
				end
			end

			for i = 0, ent:GetNumBodyGroups() do
				ent:SetBodygroup(i, 0)
			end
			for k, v in pairs (bgs) do
				ent:SetBodygroup(k, v)
			end
		end
	end

	net.Receive("TF2ItemBrowser_Input_SendToSv", function(_, ply)

		local input = net.ReadUInt(tf.BrowserInputs_bits)
		if !input then return end
		input = table.KeyFromValue(tf.BrowserInputs, input)

		local ent, data, i, vis, merge_type, submodels, effect_mats, forceopen
		if string.StartsWith(input, "attach_") then
			ent = net.ReadEntity()
		end

		if input == "item_spawn" or input == "attach_item_spawn" or input == "attach_item_modify" then
			data = tf.ReadItemDataTable()
			i = tf.TF2Items.items[data.id] or {}
			vis = tf.GetItemModelVisuals(data)
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
				[tf.EFFECT_GOLD] = "models/player/shared/gold_player",
				[tf.EFFECT_ICE] = "models/player/shared/ice_player",
				["red"] = "models/effects/invulnfx_red", //for table.KeyFromValue detection
				["blu"] = "models/effects/invulnfx_blue", //^
			}
			if !data.team then
				effect_mats[tf.EFFECT_UBER] = effect_mats.red
			else
				effect_mats[tf.EFFECT_UBER] = effect_mats.blu
			end
			if i.visuals and i.visuals.material_override then 
				effect_mats[tf.EFFECT_NONE] = i.visuals.material_override 
				effect_mats[tf.EFFECT_JARATE] = i.visuals.material_override
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
				if tf.GetDependency("advbone") and (merge_type or anim or is_fallback) then //fallback models (hatlesses) use a custom boneinfo table to attach unusual effects to the head. since we don't have a good way to switch it from easybone to advbone if the player adds an unusual effect *after* spawning it, fallback models *always* have to use advbone. dumb!!
					local old_e = e
					e = CreateAdvBonemergeEntity(e, parent, ply, false, false, true)
					if !IsValid(e) then return end
					if is_fallback and parent:LookupBone("bip_head") then e.AdvBone_BoneInfo[0].parent = "bip_head" end
					local const = constraint.AdvBoneMerge(parent, e, ply)
					if e != old_e then old_e:Remove() end
				elseif tf.GetDependency("easybone") then
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

			if tf.GetDependency("hatpainter") then
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

				//critglow and tf.EFFECT_JARATE matproxy
				local col
				if data.crit.enabled and (role == "item" or role == "attached" 
				or role == "attached_festive" or role == "stat_clock") then
					col = data.crit.col[data.team] or data.crit.col[false]
				end
				if data.fx == tf.EFFECT_JARATE then
					col = (col or Vector(1,1,1)) * tf.jarate_colors[data.team]
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
					if !tf.GetDependency("pe+") then return end

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

					if data.pe_unusual_offset and tf.GetDependency("advbone") then //https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/particle_property.cpp#L594; yes, this applies to ALL effects attached to the model, even if it makes genteel smoke look dumb (https://www.youtube.com/watch?v=A0CBN92OhrY)
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
							if tab.attach_to_rootbone and tf.GetDependency("advbone") then
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
				if data.pe_unusual > 0 then
					local tab = tf.TF2Items.attribute_controlled_attached_particles_all[data.pe_unusual]
					if tab then 
						if data.pe_unusual_offset == 1337 then
							//If this item is a hat with a randomly assigned unusual effect, then check to 
							//make sure that it has a valid attachment or won't attach to a bad root bone, 
							//otherwise enable "adjust unusual" by default so that it won't look bad.
							if tab.attach_to_rootbone then
								local should_use_offset = true
								local attachment = -1
								if tab.attachment then attachment = e2:LookupAttachment(tab.attachment) end
								if attachment > 0 then
									should_use_offset = false
								else
									local bone = e2:GetBoneName(0)
									if bone == "bip_head" or bone == "prp_helmet" or bone == "prp_hat" then
										should_use_offset = false
									end
								end
								//MsgN(i.name, " has randomly assigned unusual effect ", name, "; should_use_offset = ", should_use_offset)
								if should_use_offset then
									data.pe_unusual_offset = 0
								else
									data.pe_unusual_offset = nil
								end
							else
								data.pe_unusual_offset = nil
							end
							//Update the item data table saved to the entity as well
							if e2.EntityMods and e2.EntityMods.TF2ItemBrowser_Item then
								e2.EntityMods.TF2ItemBrowser_Item.pe_unusual_offset = data.pe_unusual_offset
							end
						end
						AddEffect(tab)
					end
				end
				if data.pe_def then //do this second to make sure we don't spawn a default effect with the 1337 offset
					for k, v in ipairs (tf.GetItemDefaultParticleEffects(data)) do
						AddEffect(v)
					end
				end
			end

			//war paint
			if tf.GetDependency("wp") then
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
						local model, skin = "models/player/" .. tf.classes[data.class].shortname .. ".mdl", 0
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
				if i.visuals and i.visuals.styles and i.visuals.styles[data.style] and tf.GetDependency("animprop") then
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

				UpdatePlayerBodygroups(spawned_models[1], ent, vis)
				//Do parent skin change for zombie skin items
				if i.attributes and i.attributes["player skin override"] and ent:SkinCount() > 4 and ent:GetSkin() <= 3 then
					ent:SetSkin(ent:GetSkin() + 4)
				end

				//in singleplayer, send the message to open the spawn panel to the client immediately because it feels smoother;
				//in multiplayer, we have to do this on a timer to ensure the entity isn't still null on the client's end
				local function SendItem()
					net.Start("TF2ItemBrowser_AttachedItem_SendToCl")
						net.WriteEntity(spawned_models[1])
						net.WriteBool(forceopen) //open spawn panel upon received?
						tf.WriteItemDataTable(data)
					net.Send(ply)
				end
				if game.SinglePlayer() then
					SendItem()
				else
					timer.Simple(0.1, function()
						if !IsValid(spawned_models[1]) then return end
						SendItem()
					end)
				end

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
				if i.visuals and i.visuals.styles and i.visuals.styles[data.style] and tf.GetDependency("animprop") and tf.GetDependency("advbone") then
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
				UpdatePlayerBodygroups(e, ent, vis, tf.GetItemModelVisuals(e.EntityMods.TF2ItemBrowser_Item))
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
				[tf.EFFECT_GOLD] = "models/player/shared/gold_player",
				[tf.EFFECT_ICE] = "models/player/shared/ice_player",
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

			//matproxy stuff for tf.EFFECT_JARATE
			if tf.GetDependency("hatpainter") then
				if fx == tf.EFFECT_JARATE then
					local team = ent:GetSkin() % 2 != 0
					local col = tf.jarate_colors[team]
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

		if e.EntityMods and e.EntityMods.TF2ItemBrowser_Item and !e.TF2ItemBrowser_Item_IsSubModelOf then
			//When unequipped, check if this item was applying any bodygroup changes to the parent ent that we want to revert.
			UpdatePlayerBodygroups(e, ent, tf.GetItemModelVisuals(e.EntityMods.TF2ItemBrowser_Item), nil, true)
			//Undo parent skin change for zombie skin items
			local i = tf.TF2Items.items[e.EntityMods.TF2ItemBrowser_Item.id] or {}
			if i.attributes and i.attributes["player skin override"] and ent:GetSkin() > 3 then
				ent:SetSkin(ent:GetSkin() - 4)
				//but what if the player had *two* equipped and only removed *one*?? this is stupid, who's going to do this?
				for k, child in ipairs (ent:GetChildren()) do
					if child != e and child.EntityMods and child.EntityMods.TF2ItemBrowser_Item and !child.TF2ItemBrowser_Item_IsSubModelOf then
						i = tf.TF2Items.items[child.EntityMods.TF2ItemBrowser_Item.id]
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
					tf.WriteItemDataTable(data)
				net.Send(ply)
			end
		end
	end)
else
	language.Add("undone_TF2ItemBrowser_Item", "Undone Attached Item")
	
	net.Receive("TF2ItemBrowser_AttachedItem_SendToCl", function()
		local ent = net.ReadEntity()
		local forceopen = net.ReadBool()
		local data = tf.ReadItemDataTable()
		if !IsValid(ent) or !IsValid(TF2ItemBrowser) then return end
		local par = TF2ItemBrowser:GetEntity()
		if !IsValid(par) or ent:GetParent() != par then return end

		TF2ItemBrowser.atticons.AddItem(ent, data, forceopen)
	end)
end