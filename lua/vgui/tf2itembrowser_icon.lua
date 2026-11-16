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

local icon_paint = Material("vgui/backpack_jewel_paint_splatter.vmt")
local icon_viewmode_pyrovision = Material("vgui/viewmode_pyrovision.vmt")
local icon_viewmode_spooky = Material("vgui/viewmode_spooky_off.vmt")
local icon_unusual = Material("vgui/viewmode_unusual.vmt")
local icon_statclock = Material("vgui/viewmode_statclock.vmt")
local icon_strange = Material("vgui/viewmode_strange.vmt")
local icon_custom = Material("vgui/glyph_steamworkshop.vmt")
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
	//halloween 2026
	unusual_muertopetals_teamc_teamcolor_red = {Vector(-14,-14,-12), Vector(14,14,8)},
	unusual_muertopetals_teamc_teamcolor_blue = {Vector(-14,-14,-12), Vector(14,14,8)},
	unusual_autumnbreeze_parent = {Vector(-18,-18,-15), Vector(18,18,20)},
	unusual_fablefeathers_teamcolor_red = {Vector(-10,-10,-10), Vector(10,10,35)},
	unusual_fablefeathers_teamcolor_blue = {Vector(-10,-10,-10), Vector(10,10,35)},
	unusual_fablefeathers_purple_parent = {Vector(-10,-10,-10), Vector(10,10,35)},
	unusual_boiltoil_purple_parent = {Vector(-8,-8,-6), Vector(8,8,10)},
	unusual_boiltoil_green_parent = {Vector(-8,-8,-6), Vector(8,8,10)},
	unusual_scaredsouls_purple_parent = {Vector(-8,-8,4), Vector(8,8,20)},
	unusual_scaredsouls_green_parent = {Vector(-8,-8,4), Vector(8,8,20)},
	unusual_scaredsouls_orange_parent = {Vector(-8,-8,4), Vector(8,8,20)},
}




local PANEL = {}
local tf = TF2ItemBrowser_Globals
if !tf then return end

function PANEL:Init()

	local icon_size = tf.cv_icon_size:GetInt()
	self:SetSize(tf.item_icon_sizes[icon_size].w, tf.item_icon_sizes[icon_size].h)
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
	tf.SanitizeItemDataTable(data)
	local i = tf.TF2Items.items[data.id] or {}

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
	//try to grab generated custom item icon if it already exists
	if !img_override and i._customitem_bp and file.Exists("tf2itembrowser_customitemicons/" .. i.name .. ".png", "DATA") then
		img_override = "data/tf2itembrowser_customitemicons/" .. i.name .. ".png"
		//don't bother searching data_static for item icons, because gmad doesn't allow them to be uploaded to the workshop in that folder (https://github.com/Facepunch/gmad/blob/master/include/AddonWhiteList.h)
	end
	if data.wp.enabled or data.models.attached_festive or (!self.mat and !img_override and i._customitem_bp) then //paintkits or festivizers might need to re-render from a setting change, but this isn't necessary for custom items
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
		rarity_override = tf.paintkit_rarities[data.wp.id]
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
		if self.data.paint.override[true] and tf.GetDependency("hatpainter") then
			tab.paint = {}
			tab.override = self.data.paint.override[false]
			tab.override_2 = self.data.paint.override[true]
		elseif self.data.paint.override[false] > 0 and tf.GetDependency("hatpainter") then
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
	local i = tf.TF2Items.items[id] or {}

	self:SetData(tf.GetDefaultItemDataTable(id))

end

function PANEL:SetupRandomItemIcon(random_settings) //optional arg to set the random settings to a pre-existing table instead of defaults

	//default to the currently selected class in the filters, except for "none"
	local _, class = TF2ItemBrowser.filters.class:GetSelected()
	if class > 10 then class = 1 end
	self.random = random_settings or {
		class = class,
		paint_chance = 0.5,
		paint_match = true,
		unusual_chance = 0.2,
		unusual_validonly = true,
		wp_chance = 0.5,
		wp_randomwear = true,
		festivizer_chance = 0.2,
		aus_chance = 0.2,
	}

	self.ImageToQueue = "vgui/backpack_custom/random.png"
	self.quality = "unique"
	self.sound_pressed = "ui/item_dueling_pistols_pickup.wav" //like a roulette wheel, you know
	//self.sound_drop = "ui/item_default_drop.wav" //no drop sound - we'll use the drop sound of whatever random item we pick instead

	self.itemname = "Random Item"
	local format = tf.GetPhrase("#ItemTypeDesc")
	if format then
		format = string.Replace(format, "%s1", #TF2ItemBrowser.icons_to_add)
		format = string.Replace(format, "%s2", "Random Item")
	end
	self.itemdesc = {
		{str = format or "", col = tf.desc_colors.level},
		{str = "Spawn an item at random from the current list.\nUse the filter options to the left to narrow down the list of items to pick from!", col = tf.desc_colors.neutral}
	}

end

function PANEL:GenerateRandomItem()

	if !TF2ItemBrowser.icons_to_add or #TF2ItemBrowser.icons_to_add == 0 then
		//no items to randomly pick from, so play a buzzer and stop here
		surface.PlaySound("replay/replaydialog_warn.wav")
		return
	end

	local id = TF2ItemBrowser.icons_to_add[math.random(#TF2ItemBrowser.icons_to_add)]
	local i = tf.TF2Items.items[id]

	local data = tf.GetDefaultItemDataTable(id)

	//if the class setting is set to a class that can equip this item, then use that class' version of the item. otherwise, use a random one.
	if i.used_by_classes[tf.classes[self.random.class].longname] then 
		data.class = self.random.class
	else
		local _, class = table.Random(i.used_by_classes) //second arg is the randomly selected table key
		data.class = tf.class_longname_to_id[class]
	end

	//select a random style; australium styles use a separate probability, so divide styles into australium and non-australium when selecting.
	local did_australium
	if i.visuals and i.visuals.styles and !i._call_styles_animations then
		local styles_normal, styles_aus = {}, {}
		for k, v in SortedPairs (i.visuals.styles) do
			if v.aus_prefix then
				table.insert(styles_aus, k)
			else
				table.insert(styles_normal, k)
			end
		end
		if (#styles_aus > 0 and math.random() <= self.random.aus_chance) or #styles_normal == 0 then
			data.style = table.Random(styles_aus)
			did_australium = true //don't apply paintkits to australiums
		else
			data.style = table.Random(styles_normal)
		end
	end

	//festivizer; don't worry about whether the item has this or not, SanitizeItemDataTable will take care of it
	data.models.attached_festive = math.random() <= self.random.festivizer_chance

	if i.capabilities and i.capabilities.paintable == 1 and math.random() <= self.random.paint_chance then
		local col
		if self.random.paint_match then
			local ent = TF2ItemBrowser:GetEntity()
			if IsValid(ent) then
				//Go through items attached to the browser's selected entity, and grab the first available paint color
				for k, v in pairs (TF2ItemBrowser.atticons.Panels) do
					if !v.data or !istable(v.data) or !v.data.paint.enabled then continue end
					local i2 = tf.TF2Items.items[v.data.id] or {}
					if !(i2._default_paint and v.data.paint.col[false] == i2._default_paint[false]) or v.data.paint.override[false] != 0 then
						col = {[1] = Vector(v.data.paint.col[false])}
						if v.data.paint.col[true] then
							col[2] = Vector(v.data.paint.col[true])
						end
						if v.data.paint.override[false] != 0 then
							col.override = v.data.paint.override[false]
							col.override_2 = v.data.paint.override[true]
						end
						break
					end
				end
			end
		end
		//Select a random paint color
		if !col then
			col = paints[math.random(#paints-1)] //don't pick the last paint, which is the unused halloween spell
		end

		data.paint.enabled = true
		if col.override then
			data.paint.override = {[false] = col.override, [true] = col.override_2}
		else
			data.paint.override = {[false] = 0}
		end
		if col[1] then
			data.paint.col = {[false] = col[1], [true] = col[2]}
		end
	end

	if !did_australium and i._paintkit and tf.GetDependency("wp") and WP.Weapons.IsSupported(i.model_player) and math.random() <= self.random.wp_chance then
		local tab = WP.WarpaintData.GetForWeaponType(WP.Weapons.GetFromModel(i.model_player))
		data.wp.id = tab[math.random(#tab)].id
		data.wp.enabled = true
		if self.random.wp_randomwear then
			data.wp.wear = math.random(1, 5)
		end
	end

	if math.random() <= self.random.unusual_chance then
		local unu_tab, unu_type = tf.GetItemUnusualEffects(id)
		if unu_tab and (!self.random.unusual_validonly 
		or (unu_type == "hat" and i.equip_regions and (i.equip_regions.hat or i.equip_regions.whole_head)) 
		or (unu_type == "wep" and data.wp.enabled)) then
			local tab = unu_tab[math.random(#unu_tab)]
			data.pe_unusual = tab.k
			if unu_type == "hat" and tab.v.attach_to_rootbone then
				//some combinations of hat and unusual effect will want to use "adjust unusual" by default in order to appear 
				//on the head instead of some bad model origin; tell the serverside spawn code to do a special check for this
				data.pe_unusual_offset = 1337 //special value to tell the serverside spawn function to run this check
			end
		end
	end

	tf.SanitizeItemDataTable(data)
	if IsValid(TF2ItemBrowser:GetEntity()) then
		TF2ItemBrowser:DoInput("attach_item_spawn", data, false) //don't open the new item's window, keep the random item window open
	else
		TF2ItemBrowser:DoInput("item_spawn", data)
	end
	//if the item model hasn't been loaded yet, then the game will stutter when loading the model,
	//so wait until the next frame so that the sound doesn't play and then immediately get cut off.
	//the timing is a little tricky here because it won't load until the server receives the spawn input 
	//from the client, but using FrameTime() here works for singleplayer without having a noticeable delay.
	timer.Simple(FrameTime(), function() surface.PlaySound(i.drop_sound or "ui/item_default_drop.wav") end)

end

function PANEL:UpdateItemName()

	//based on https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L610, it's a whopper
	//this is probably way overengineered for our use case, but oh well!

	local i = tf.TF2Items.items[self.data.id]
	if !i then
		if !isstring(self.data.id) then
			return "Unknown Item " .. self.data.id
		else
			return "Unknown Custom Item \"" .. self.data.id .. "\""
		end
	end

	local useProperName = true
	local ignoreWear = false
	local ignoreQuality = false
	if self.data.wp.enabled and self.quality != "strange" and self.quality != "selfmade" then
		//all quality strings are disabled on unusual paintkit items. yes, this appears to actually be the case in-game. what?? (https://steamcommunity.com/sharedfiles/filedetails/?id=3722656440)
		//ignoreQuality = true
	end
	
	// Start with the base name.
	local itemName = tf.GetPhrase(i.item_name) or i.item_name
	if !itemName then
		if !isstring(self.data.id) then
			itemName = i.name or "Item " .. self.data.id //i don't *think* item_name is nil on any item defs? tf2 code here just displays "Unknown Item", but we want to show the id number, and also make a distinction between totally invalid itemdefs and ones that are just missing a name.
		else
			itemName = self.data.id //custom items, on the other hand, can very easily just have the name field left empty, so use the filename as a fallback
		end
	end

	//tf2 code here sets killstreak values, but this addon won't be doing those unless rubat implements $sheenmap someday

	if self.data.models.attached_festive then useProperName = false end

	local quality = ""
	if !ignoreQuality then 
		if self.strange_prefix then
			quality = (tf.GetPhrase(self.strange_prefix) or "") .. (tf.GetPhrase("#Strange_Spacer") or "")
		elseif self.quality != "normal" and self.quality != "paintkitweapon" then //tf2 code here checks nQuality > 0, which only filters out normal quality (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_constants.h#L516)
			if self.quality == "unique" then
				if useProperName and i.propername == 1 then 
					quality = tf.GetPhrase("#TF_Unique_Prepend_Proper") or quality
				end
			else // Any quality besides unique ignores "proper name" articles.
				quality = tf.GetPhrase("#" .. self.quality) or quality
				if quality != "" then quality = quality .. (tf.GetPhrase("#Rarity_Spacer") or "") end
			end
		end

		//tf2 code here sets strange ranks, which we only care about for campaign ranks and handle above, 
		//but also prepends strange rank onto strange unusual items, which in our use cases, only applies 
		//to weapons with both an unusual effect and a stat clock/australium enabled.
		if self.secondary_strange_quality then
			quality = (tf.GetPhrase("#strange") or "") .. " " .. quality
		end
	end

	local australium_skin = ""
	if self.aus_prefix then
		australium_skin = tf.GetPhrase("#ItemNameAustralium") or australium_skin
	end

	local festivized = ""
	if self.data.models.attached_festive then festivized = tf.GetPhrase("#ItemNameFestive") or festivized end

	local qualityformat = ""
	if (self.quality == "normal" or self.quality == "unique" or self.quality == "paintkitweapon" or ignoreQuality) and self.quality != "selfmade" then
		qualityformat = tf.GetPhrase("#ItemNameNormalOrUniqueQualityFormat") or qualityformat
	else
		qualityformat = tf.GetPhrase("#ItemNameQualityFormat") or qualityformat
	end

	//loc_scpy_safe( szQuality, CConstructLocalizedString( pLocalizationProvider->Find( pszQualityFormat ), szQuality, szIsFestivized, szKillStreak, szAustraliumSkin, szDuckBadge ) );
	// Strange Unusual Festive Killstreak Australium ducks
	qualityformat = string.Replace(qualityformat, "%s1", quality)
	qualityformat = string.Replace(qualityformat, "%s2", festivized)
	qualityformat = string.Replace(qualityformat, "%s3", "") //killstreak
	qualityformat = string.Replace(qualityformat, "%s4", australium_skin)
	qualityformat = string.Replace(qualityformat, "%s5", "") //duck journal rank
	quality = qualityformat

	if self.data.wp.enabled and tf.GetDependency("wp") then
		local paintKitStr = WP.Proto.Schema.GetPaintkitByDefindex(self.data.wp.id)
		if paintKitStr and paintKitStr.header then
			paintKitStr = WP.Proto.Localization.GetWarpaintName(paintKitStr.header.name, paintKitStr.locDesctoken)
		else
			paintKitStr = nil
		end
		if paintKitStr then
			//Based off Econ_ConcatPaintKitName (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L543)
			local format = tf.GetPhrase("#ToolPaintKit_ItemDescFormat") or "%s1 %s2"
			format = string.Replace(format, "%s1", paintKitStr)
			format = string.Replace(format, "%s2", itemName)
			itemName = format
		end
	end

	//note: in the tf2 code, at the very top of this method, "ItemNameFormat" is set as the default value, and a comment mentions 
	//using a different format for names with an article, but it never actually does this or changes this value anywhere
	local format = tf.GetPhrase("#ItemNameFormat")
	if format then
		format = string.Replace(format, "%s1", quality)
		format = string.Replace(format, "%s2", itemName)
		format = string.Replace(format, "%s3", "") //craft index
		format = string.Replace(format, "%s4", "") //crate series
		format = string.Replace(format, "%s5", "") //tool target name
		format = string.Replace(format, "%s6", "") //dynamic recipe output name
	else
		format = itemName //in the tf2 code, if it can't find the localization pattern, it just defaults to "Unknown Item" again, but that behavior sucks, we can just use itemName as a fallback (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L1013-L1030)
	end
	return format

end

function PANEL:UpdateItemDescription()

	//based on CEconItemDescription::GenerateDescriptionLines https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L347

	local desc = {}
	local i = tf.TF2Items.items[self.data.id]
	if !i then
		if !isstring(self.data.id) then
			table.insert(desc, {str = "Valve item ID \"" .. self.data.id .. "\" not found.\nThis shouldn't happen, report this bug!", col = tf.desc_colors.neutral})
		else
			table.insert(desc, {str = "Custom item ID \"" .. self.data.id .. "\" not found.\nThis could be from an addon that isn't mounted, a local custom item that was deleted, or another player's custom item from a dupe or save.", col = tf.desc_colors.neutral})
		end
		return desc 
	end

	if self.rarity then
		//Item rarity; based on CEconItemDescription::Generate_ItemRarityDesc https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L1521
		
		local tooltip = "#TFUI_InvTooltip_Rarity"
		if !self.data.wp.enabled then tooltip = "#TFUI_InvTooltip_RarityNoWear" end
		tooltip = tf.GetPhrase(tooltip)
		if tooltip then
			tooltip = string.Replace(tooltip, "%s1", tf.GetPhrase("#" .. tf.TF2Items.rarities[self.rarity].loc_key) or "")
			tooltip = string.Replace(tooltip, "%s2", tf.GetPhrase("#" .. i.item_type_name) or "")
			if !self.data.wp.enabled then
				tooltip = string.Replace(tooltip, "%s3", tf.GetPhrase(wear_strings[0]))
			else
				tooltip = string.Replace(tooltip, "%s3", tf.GetPhrase(wear_strings[self.data.wp.wear]))
			end
			table.insert(desc, {str = tooltip, col = tf.rarity_colors[self.rarity]})
		end
	else
		//Item level; based on CEconItemDescription::Generate_ItemLevelDesc, which calls CEconItemDescription::Generate_ItemLevelDesc_Default (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L1252);
		//the former also has a use case for showing strange ranks in place of levels, but this addon doesn't need those; 
		//all we need from that method is the stat clock attrib, which we'll do below.
		
		local typeName = tf.GetPhrase(i.item_type_name)
		if typeName then
			local level = math.random(i.min_ilevel or 1, i.max_ilevel or 100)

			//tf2 code has a case here where if an item has no typeName, the attribute "force_level_display" can 
			//make it use the "ItemTypeDescNoLevel" format (just "Level X") instead of returning nothing (or doing 
			//any of the below checks), but nothing in items_game uses this attribute, so don't bother

			//tf2 code here also has a case for items with a override_item_level_desc_string attribute that makes
			//them use the "ItemTypeDescCustomLevelString_MvMTour" format (Tour No. X typeName) but nothing uses this

			if i.static_attrs and i.static_attrs["limited quantity item"] == 1 then
				local format = tf.GetPhrase("#ItemTypeDescLimited")
				if format then
					format = string.Replace(format, "%s1", level)
					format = string.Replace(format, "%s2", typeName)
					format = string.Replace(format, "%s3", tf.GetPhrase("#LimitedQualityDesc") or "")
					table.insert(desc, {str = format, col = tf.desc_colors.ItemLimitedQuantity})
				end
			else
				local format = tf.GetPhrase("#ItemTypeDesc")
				if format then
					format = string.Replace(format, "%s1", level)
					format = string.Replace(format, "%s2", typeName)
					table.insert(desc, {str = format, col = tf.desc_colors.level})
				end
			end
		end
	end

	//do statclocks here; in tf2 code, this is done by Generate_ItemLevelDesc calling Generate_ItemLevelDesc_StrangeNameAndStats
	//even if it has a rarity instead; in our case, we can have statclocks even on non-paintkit items, so don't replace the 
	//standard Level X Thing text with this, even if that's what the tf2 code would do if that were possible
	if self.data.models.stat_clock then
		local rank = tf.GetPhrase("#Attrib_stattrakmodule")
		if rank then
			rank = string.Replace(rank, "%s1", tf.GetPhrase("#KillEaterRank0") or "")
		end
		table.insert(desc, {str = rank, col = tf.quality_colors.strange})
	end

	//TF2 code here does Generate_CraftTag, we don't care about this

	//Current style, based on CEconItemDescription::Generate_StyleDesc (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L1268)
	//Only do this if this icon corresponds to a specific item, otherwise do the store-type list of all the styles below
	if self.entity and i.visuals and i.visuals.styles and !i._call_styles_animations then
		local style = tf.GetPhrase(i.visuals.styles[self.data.style].name)
		if style then
			table.insert(desc, {str = string.Replace(tf.GetPhrase("#Econ_Style_Desc") or "", "%s1", style), col = tf.desc_colors.level})
		end
	end

	//Paint name, based on CEconItemDescription::Generate_Painted (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L2402)
	if self.data.paint.enabled and self.data.paint.override[false] == 0 and !(i._default_paint and self.data.paint.col[false] == i._default_paint[false]) then
		local paint = tf.str_custom
		for k, v in ipairs (paints) do
			if v[1] == self.data.paint.col[false] and v[2] == self.data.paint.col[true] then
				paint = tf.GetPhrase(v.name)
				break
			end
		end
		if paint then table.insert(desc, {str = string.Replace(tf.GetPhrase("#Econ_Paint_Name") or "", "%s1", paint or ""), col = tf.desc_colors.level}) end
	end

	//Holiday restriction, based on CEconItemDescription::Generate_HolidayRestriction https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L1447
	//In practice, the only one used by items this addon can spawn is halloween_and_full_moon
	if i.holiday_restriction then
		table.insert(desc, {str = tf.GetPhrase("Econ_holiday_restriction_" .. i.holiday_restriction), col = tf.desc_colors.negative}) //this uses LocalizedAddDescLine in tf2 code, which falls back to the raw string on fail if there's no #, which there isn't for this string (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L1462-L1465)
	end

	//TF2 code here does Generate_SaxxyAwardDesc (specific category an award is for), we don't care about this

	//Item attributes, based approximately on CEconItemDescription::Generate_VisibleAttributes and various related methods (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L3415)
	local sorted_attribs = {}
	local effect_types = { //order from https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_schema.h#L694
		[1] = {name = "unusual", color = tf.quality_colors.rarity4},
		//"strange" is here too, but currently the only attrib that's strange-colored is hidden, so skip this for now
		[2] = {name = "neutral", color = tf.desc_colors.neutral},
		[3] = {name = "positive", color = tf.desc_colors.positive},
		[4] = {name = "negative", color = tf.desc_colors.negative},
	}
	local function SortAttrib(attrib, val)
		if attrib == "set supply crate series" and i.static_attrs["hide crate series number"] then return end //yes, tf2 code does this at the attrib processing level (CEconItemDescription::CVisibleAttributeDisplayer::Finalize (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L3397C6-L3397C64)). dumb!!
		local id = tf.TF2Items.attribute_ids_by_name[attrib]
		local _attrib = tf.TF2Items.attributes[id]
		if !_attrib or !_attrib.description_string or _attrib.hidden == 1 then return end
		local str = tf.GetPhrase(_attrib.description_string)
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
			val = tf.GetPhrase("#Attrib_Particle" .. val)
			if !val then return end
		//value_is_killstreakeffect_index and value_is_killstreak_idleeffect_index work the same as above, but we're not implementing these unless rubat adds $sheenmap someday
		//elseif f == "value_is_or" then
		//	//no changes needed
		elseif f == "value_is_from_lookup_table" then
			if !tf.TF2Items.string_lookups[attrib] then return end
			val = tf.GetPhrase(tf.TF2Items.string_lookups[attrib][val])
			if !val then return end
		end
		if isnumber(val) then val = math.Round(val, 2) end

		str = string.Replace(str, "%s1", val)
		//additional wrapper for halloween spells (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L3643-L3653)
		if _attrib.is_user_generated then
			local ugt = tf.GetPhrase("#Econ_Attrib_UserGeneratedWrapper_" .. tostring(_attrib.is_user_generated))
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
				table.insert(desc, {str = i._display_attributes[type], col = tf.desc_colors[type]})
			end
		end
	end
	
	//TF2 code here does Generate_QualityDesc (extra flavor text for community/self-made items), we don't care about this since no spawnable items use these qualities

	//Item description; based on CEconItemDescription::Generate_ItemDesc https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L1575
	if i.item_description then
		local item_desc = tf.GetPhrase(i.item_description)
		if item_desc then table.insert(desc, {str = item_desc, col = tf.desc_colors.neutral}) end
	end

	//TF2 code here does Generate_Bundle, Generate_GiftedBy, Generate_DuelingMedal, Generate_MapContributor, Generate_MapStampBundleTooltip,
	//Generate_FriendlyHat, Generate_SquadSurplusClaimedBy, Generate_MvmChallenges, Generate_DynamicRecipe, Generate_XifierToolTargetItem,
	//Generate_LootListDesc, Generate_EventDetail; we don't care about any of these

	local done_spacer //this looks better if it shares a spacer with styles/classes below
	//Item set name, loosely based off CEconItemDescription::Generate_ItemSetDesc (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L2696); 
	//TF2 code here lists all the items in the set/collection and set bonus attributes, but we don't care about the latter,
	//and for the former, set items are listed elsewhere in dropdowns where players can actually spawn them
	if i._item_set then
		local item_set = tf.GetPhrase(tf.TF2Items.item_sets[i._item_set].name) or i._item_set
		if !done_spacer then table.insert(desc, {str = "", col = tf.desc_colors.level}) done_spacer = true end
		table.insert(desc, {str = item_set, col = tf.desc_colors.ItemSetName})
	end

	//TF2 code here does Generate_UnusualifierEffectList; we don't care about this

	//Item collection name; same as above, just show the collection name, not its contents like in CEconItemDescription::Generate_CollectionDesc (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_description.cpp#L2810)
	local col = i._item_collection
	if !col and self.data.wp.enabled then
		//Get collection from paintkit
		col = tf.paintkit_ids_to_collections[self.data.wp.id]
	end
	if col then
		col = tf.GetPhrase(tf.TF2Items.item_collections[col].name) or col
		if !done_spacer then table.insert(desc, {str = "", col = tf.desc_colors.level}) done_spacer = true end
		table.insert(desc, {str = col, col = tf.desc_colors.neutral})
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
			for k, _ in SortedPairs (i.visuals.styles) do
				if !str then
					str = (tf.GetPhrase("#Store_AvailableStyles_Header") or "Available Styles:") .. " "
				else
					str = str .. ", "
				end
				str = str .. tf.GetItemStyleName(self.data.id, k)
			end
			if !done_spacer then table.insert(desc, {str = "", col = tf.desc_colors.level}) done_spacer = true end
			table.insert(desc, {str = str, col = tf.desc_colors.level})
		end
		//Do class list here too, so that players can tell which classes can use unfamiliar items
		if !i.used_by_classes.none then
			local str
			if table.Count(i.used_by_classes) == 9 then
				str = (tf.GetPhrase("#Store_ItemDesc_UsedBy") or "Used by:") .. " " .. (tf.GetPhrase("#Store_ItemDesc_AllClasses") or "All Classes")
			else
				for k, v in ipairs (tf.classes) do //add class options in class order; this kind of sucks for listing a lot of classes but oh well
					if i.used_by_classes[v.longname] then
						if !str then
							str = (tf.GetPhrase("#Store_ItemDesc_UsedBy") or "Used by:") .. " "
						else
							str = str .. ", " //manually appending unlocalized commas here is good enough for valve, so it's good enough for us (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/client/tf/vgui/store/v2/tf_store_preview_item2.cpp#L922)
						end
						str = str .. (tf.GetPhrase(v.langstr) or string.NiceName(v.longname))
					end
				end
			end
			if !done_spacer then table.insert(desc, {str = "", col = tf.desc_colors.level}) done_spacer = true end
			table.insert(desc, {str = str, col = tf.desc_colors.level})
		end
		//And item slot
		if i.item_slot then
			local str, class_slots
			for k, v in pairs (i.used_by_classes) do
				if !isnumber(v) then
					class_slots = class_slots or {}
					class_slots[v] = class_slots[v] or {}
					class_slots[v][k] = true
				end
			end
			if class_slots then
				for slot, classes in pairs (class_slots) do
					if !str then
						str = ""
					else
						str = str .. ", "
					end
					str = str .. (tf.GetPhrase("#LoadoutSlot_" .. slot) or slot) .. " ("
					local class_addcomma
					for k, v in ipairs (tf.classes) do
						if classes[v.longname] then
							if class_addcomma then
								str = str .. ", "
							end
							class_addcomma = true
							str = str .. (tf.GetPhrase(v.langstr) or string.NiceName(v.longname))
						end
					end
					str = str .. ")"
				end
			else
				str = i.item_slot
				if str == "head" then str = "misc"
				elseif str == "taunt" then str = "tauntslot" end //the string for LoadoutSlot_Taunt is "Taunt 1"; this is slightly better
				str = tf.GetPhrase("#LoadoutSlot_" .. str) or str
			end
			if !done_spacer then table.insert(desc, {str = "", col = tf.desc_colors.level}) done_spacer = true end
			table.insert(desc, {str = (tf.GetPhrase("#Store_ItemDesc_Slot") or "Slot:") .. " " .. str, col = tf.desc_colors.level})
		end
		//Also list equip regions, to make it clear why items conflict with each other
		if i.equip_regions then
			local str
			for k, v in pairs (i.equip_regions) do
				if !str then
					str = (tf.GetPhrase("#TF_ImportFile_EquipRegionLabel") or "Equip Region") .. ": " //there's no localized version of "equip region" followed by a colon, so we make do 
				else
					str = str .. ", "
				end
				str = str .. string.NiceName(k) //equip regions aren't localized anywhere unfortunately, just show english names all the time
			end
			if !done_spacer then table.insert(desc, {str = "", col = tf.desc_colors.level}) done_spacer = true end
			table.insert(desc, {str = str, col = tf.desc_colors.level})
		end
	end

	//"Grayed out" reason, used when item has a conflict; this is based on CEconItemView::EnsureDescriptionIsBuilt() (https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/econ/econ_item_view.cpp#L650-L674)
	//which is separate from the rest of the item description code
	if self.item_conflict then
		table.insert(desc, {str = "", col = tf.desc_colors.negative})
		table.insert(desc, {str = tf.GetPhrase("#Econ_GreyOutReason_EquipRegionConflict"), col = tf.desc_colors.negative})
	end

	return desc

end

function PANEL:AddItemText(pnl, text, font, col)
	
	local h = 0
	local max_w = tf.popup_w-(tf.popup_pad*2)
	local tab = string.Explode("\n", textWrap(text, font, max_w))
	for k, v in ipairs (tab) do
		//textWrap has an edge case where if a string has two spaces in a row, it won't get the width of the additional space.
		//This is bad because it thinks the text including the double-space is less wide than it is, so it doesn't wrap the
		//text where it should, and returns a string that's too long to fit here. 
		//This happens with: 528 The Short Circuit, 13217 Holographic Harvest Lahsuniya Ratna 2022
		local _w, _ = surface.GetTextSize(v)
		if _w > max_w then
			MsgN("TF2ItemBrowser: got overlong description string: ", v)
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

	pnl:DockPadding(tf.popup_pad,tf.popup_pad,tf.popup_pad,tf.popup_pad) 
	local h = tf.popup_pad*2 + self:AddItemText(pnl, self.itemname, "TF2ItemBrowser_ItemName", tf.rarity_colors[self.rarity] or tf.quality_colors[self.quality])
	for _, v in ipairs (self.itemdesc) do
		h = h + self:AddItemText(pnl, v.str, "TF2ItemBrowser_ItemDesc", v.col)
	end
	--[[pnl:SetWide(tf.popup_w)
	pnl:InvalidateLayout(true)
	pnl:SizeToChildren(false,true)]]
	pnl:SetSize(tf.popup_w,h) //this returns better height for items with descriptions??
	self:PositionPopupPanel(pnl)
	self.popup = pnl
	
	function pnl:Paint(w,h)
		self.Owner:PositionPopupPanel(self)
		tf.LoadoutItemPopupBorder(0,0,w,h)
	end

end

function PANEL:CreateItemModels(data, disable_fallback_model) //data is a separate arg here so it can either use self.data or a custom defined data table

	local models = {}

	local i = tf.TF2Items.items[data.id] or {}
	local vis = tf.GetItemModelVisuals(data)
	//if this icon is for an invalid item (i.e. a custom item from an outdated save), then show the entity's current model in the panel.
	if !tf.TF2Items.items[data.id] and IsValid(self.entity) then
		vis.models.item = self.entity:GetModel()
		data.models.item = true
	end
	local submodels = {}
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
	if #submodels == 0 and table.Count(vis.models) == 0 and !disable_fallback_model and data.class >= 2 and data.class <= 10 then //don't try to show a fallback model for "any" or "none" classes
		table.insert(submodels, {role = "no_model_fallback"})
	end
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
				model = "models/player/" .. tf.classes[data.class].shortname .. ".mdl"
			end
			if data.team then skin = 1 end
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

			if i.visuals and i.visuals.styles and i.visuals.styles[data.style] then
				local anim = i.visuals.styles[data.style]._anim
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
			if data.fx == tf.EFFECT_UBER then
				if !data.team then
					mat = "models/effects/invulnfx_red"
				else
					mat = "models/effects/invulnfx_blue"
				end
			elseif data.fx == tf.EFFECT_GOLD then
				mat = "models/player/shared/gold_player"
			elseif data.fx == tf.EFFECT_ICE then
				mat = "models/player/shared/ice_player"
			elseif i.visuals and i.visuals.material_override then
				mat = i.visuals.material_override
			end
			if mat then ent:SetMaterial(mat) end

			if tf.GetDependency("hatpainter") then
				//paint matproxy
				if data.paint.enabled then
					local col = data.paint.col[data.team] or data.paint.col[false]
					local override = data.paint.override[data.team] or data.paint.override[false]
					if override == 0 then override = nil end
					ent.ProxyentPaintColor = {
						IsValid = function() return true end, 
						Color = Vector(col[1]/255, col[2]/255, col[3]/255),
						Override = override //used by tf.DrawItemModels to update the override color
					}
				end

				//critglow and tf.EFFECT_JARATE matproxy
				local col
				if data.crit.enabled and (v.role == "item" or v.role == "attached" 
				or v.role == "attached_festive" or v.role == "stat_clock") then
					col = data.crit.col[data.team] or data.crit.col[false]
				end
				if data.fx == tf.EFFECT_JARATE then
					col = (col or Vector(1,1,1)) * tf.jarate_colors[data.team]
				end
				if col then
					ent.ProxyentCritGlow = {
						IsValid = function() return true end, 
						Color = col
					}
				end
			end

			//war paint
			if data.wp.enabled and tf.GetDependency("wp") and v.role == "item" then
				local instance
				local weaponType = WP.Weapons.GetFromModel(ent:GetModel())
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
		//tell CreateItemParticles to add particle effects to both base items and fallbacks
		if v.role == "item" or v.role == "no_model_fallback" then
			ent.ShouldAddParticles = v.role
		end
		ent:SetNoDraw(true)
		ent:SetIK(false)
		//disable jigglebones
		for i = 0, ent:GetBoneCount() - 1 do
			ent:ManipulateBoneJiggle(i, 2)
		end
		table.insert(models, ent)
	end
	return models

end

function PANEL:CreateItemParticles(models, bailfunc, data)

	local particles = {}
	local i = tf.TF2Items.items[data.id] or {}
	for _, ent in ipairs (models) do
		if ent.ShouldAddParticles then
			//crit spark particles
			if data.crit.enabled and tf.GetDependency("hatpainter") then
				//if spawning an effect right now could potentially cause a crash, bail out and try again later
				if (data.crit.sparks_rb or data.crit.sparks_c) and (tf.GetDependency("pe+") and table.Count(PEPlus_AddParticles_CrashCheck_ThrottledPCFs) > 0) then
					if bailfunc then bailfunc() end
					return
				end
				if data.crit.sparks_rb then
					local pname = "critgun_weaponmodel_red"
					if data.team then pname = "critgun_weaponmodel_blu" end
					local part = CreateParticleSystem(ent, pname, PATTACH_ABSORIGIN_FOLLOW)
					if IsValid(part) then
						part:SetShouldDraw(false)
						table.insert(particles, part)
					end
				end
				if data.crit.sparks_c then
					local part = CreateParticleSystem(ent, "critgun_weaponmodel_colorable", PATTACH_ABSORIGIN_FOLLOW)
					if IsValid(part) then
						local col = data.crit.col[data.team] or data.crit.col[false]
						col = Vector(65,65,65) + (col * 3)	//we overbrighten the color value (second controlpoint) by a large amount because
						part:AddControlPoint(1, game.GetWorld(), PATTACH_WORLDORIGIN, 0, col)	//crit color values actually tend to be pretty low to avoid overpowering the texture
						part:SetShouldDraw(false)
						table.insert(particles, part)
					end
				end
			end

			//unusual and default particles
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

				local part
				if data.pe_unusual_offset or ent.ShouldAddParticles == "no_model_fallback" then //https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/particle_property.cpp#L594
					ent:InvalidateBoneCache()
					local manip = Vector(0, data.pe_unusual_offset or 0, 0)
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
					if tf.GetDependency("pe+") then
						local pcfs = PEPlus_FindPCFsFromEffect(name)
						if pcfs and pcfs[1] then
							local pcf = PEPlus_GetGamePCF(pcfs[1].pcf, pcfs[1].path)
							PEPlus_AddParticles_CrashCheck[pcf] = PEPlus_AddParticles_CrashCheck[pcf] or {}
							PEPlus_AddParticles_CrashCheck[pcf][part] = true
						end
					end
				end
			end
			if data.pe_def then
				for k, v in ipairs (tf.GetItemDefaultParticleEffects(data)) do
					//if spawning an effect right now could potentially cause a crash, bail out and try again later
					if tf.GetDependency("pe+") and table.Count(PEPlus_AddParticles_CrashCheck_ThrottledPCFs) > 0 then
						if bailfunc then bailfunc() end
						return
					end
					AddEffect(v)
				end
			end
			if data.pe_unusual > 0 then
				local tab = tf.TF2Items.attribute_controlled_attached_particles_all[data.pe_unusual]
				if tab then
					//if spawning an effect right now could potentially cause a crash, bail out and try again later
					if tf.GetDependency("pe+") and table.Count(PEPlus_AddParticles_CrashCheck_ThrottledPCFs) > 0 then
						if bailfunc then bailfunc() end
						return
					end
					AddEffect(tab)
				end
			end
		end
	end
	return particles

end

function PANEL:CreateSpawnPanel()

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

	pnl:DockPadding(tf.popup_pad,tf.popup_pad,tf.popup_pad,tf.popup_pad)
	local name_container = pnl:Add("DPanel")
	name_container:Dock(TOP)
	name_container.Paint = function() end
	//this will be populated in pnl.Refresh()

	local side_margins = (tf.popup_w-300-tf.popup_pad-tf.popup_pad)/2 //force the modelpanel to stay a square, and align all the other controls with it
	local function AddDropdown(label, populatefunc, select_extras)
		local combo = tf.TFStyleVGUI("DComboBox", pnl)
		local _pnl = tf.AddTFLabelToVGUI(combo, label)
		_pnl:Dock(TOP)
		_pnl:DockMargin(side_margins,0,side_margins,tf.betweenitems)
		combo:SetSortItems(false)
		populatefunc(combo)
		function combo.OnSelect(_, index, value, data)
			if select_extras then select_extras(data) end
			combo.value = data
			if pnl.OnSettingChanged then pnl.OnSettingChanged() end
		end
		return combo
	end
	
	if !self.random then
		local i = tf.TF2Items.items[self.data.id] or {}

		local mdl = tf.CreateItemIconModelPanel(pnl)
		pnl.ModelPanel = mdl
		mdl:SetSize(300,300)
		mdl.PaintMargin = 3 //set precisely to cut off the modelpanel at the edges of the GrayDialogBorder
		mdl:DockMargin(side_margins,tf.betweencategories-5,side_margins,tf.betweencategories)
		mdl:Dock(TOP)
		local old_Paint = mdl.Paint
		function mdl:Paint(w,h)
			tf.GrayDialogBorder(0,0,w,h)
			old_Paint(mdl,w,h)
		end
		function mdl:Refresh()
			pnl.Refresh()
		end

		function pnl.Refresh()
			name_container:Clear()
			self:AddItemText(name_container, self.itemname, "TF2ItemBrowser_ItemName", tf.rarity_colors[self.rarity] or tf.quality_colors[self.quality])
			name_container:InvalidateLayout(true)
			name_container:SizeToChildren(false, true)

			//update these every time we open or refresh the panel, since they can change after the icon has been created
			if !IsValid(ent) then 
				self.data.team = TF2ItemBrowser.attopts.team.Value
				local _, f = TF2ItemBrowser.attopts.fx:GetSelected()
				self.data.fx = f
			end
			local vis = tf.GetItemModelVisuals(self.data)

			//Clean up old models and particles
			for k, v in ipairs (mdl.models) do
				if IsValid(v) then v:Remove() end
			end
			for k, v in ipairs (mdl.particles) do
				if IsValid(v) then v:StopEmissionAndDestroyImmediately() end
			end

			mdl.models = self:CreateItemModels(self.data) or {}
			mdl.Entity = mdl.models[1]

			//Only reset the camera if the values returned by tf.DoItemModelCamera have changed (i.e. a model or animation changed)
			local cam = tf.DoItemModelCamera(mdl.models, self)
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
				mdl.old_cam = table.Copy(cam)
				//For custom items, use backpack icon camera values, but only if the displayed model matches the one used by the icon.
				//This override happens after the old_cam check, so that alternative models which return the same results from
				//tf.DoItemModelCamera (i.e. styles that only change material) can also use the backpack icon camera values.
				if mdl.models[1] and i._customitem_bp and !i._customitem_bp.showclass then
					local bpmdl = true
					if i._customitem_bp.mdl then
						for k, v in pairs ({"item", "wearable", "wearable_2"}) do
							if self.data.models[v] and i._customitem_bp.mdl != v then
								bpmdl = false
								break
							end
						end
					end
					if bpmdl then
						local vis2 = tf.GetItemModelVisuals({id = self.data.id, class = tf.class_longname_to_id[i._customitem_bp.class] or self.data.class, team = self.data.team, style = i._customitem_bp.style or self.data.style})
						if i._customitem_bp.mdl then
							if vis2.models[i._customitem_bp.mdl] != vis.models[i._customitem_bp.mdl] then 
								bpmdl = false
							end
						else
							for k, v in pairs ({"item", "wearable", "wearable_2"}) do
								if vis2.models[v] != vis.models[v] then
									bpmdl = false
									break
								end
							end
						end
						if bpmdl then
							cam = i._customitem_bp
							mdl.mdlang = i._customitem_bp.mdlang
						end
					end
					if !bpmdl then
						mdl.mdlang = nil
					end
				else
					mdl.mdlang = nil
				end
				mdl:SetCamPos(Vector(cam.pos)) //use copies of pos/ang, otherwise the values in old_cam will change as the camera moves
				mdl:SetFOV(cam.fov)
				mdl:SetLookAng(Angle(cam.ang))
			end
			if mdl.mdlang and IsValid(mdl.models[1]) then
				mdl.models[1]:SetAngles(mdl.mdlang)
			end

			//Now that we've created and positioned the models, create the particles
			mdl.particles = self:CreateItemParticles(mdl.models, function()
				timer.Simple(0.1, function() if IsValid(pnl) then pnl.Refresh() end end) //bail function
			end, self.data) or {}

			//Hide the class selector if all classes use the same model (i.e. medals)
			//Also compare the bodygroups because of use_per_class_bodygroups.
			local should_show_class = false
			for k, v in pairs (i.used_by_classes) do
				if k != tf.classes[self.data.class].longname then
					//If the item is being equipped to a character and it has class-based item slots, then
					//re-enable the class selector even if the models are the same, just to avoid unintuitive
					//behavior with item slot conflicts (i.e. let the player tell (and change) if they have a
					//primary or secondary shotgun equipped)
					if IsValid(TF2ItemBrowser:GetEntity()) and v != i.used_by_classes[tf.classes[self.data.class].longname] then
						should_show_class = true
						break
					end
					local vis2 = tf.GetItemModelVisuals({id = self.data.id, class = tf.class_longname_to_id[k], team = self.data.team, style = self.data.style})
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
			if IsValid(self.entity) then
				TF2ItemBrowser:UpdateItemConflicts() //for class-based item slot conflicts
				TF2ItemBrowser:DoInput("attach_item_modify", self.entity, self.data)
			end
		end	

		local checks = vgui.Create("Panel", pnl) //container for submodel controls
		checks:SetHeight(20)
		checks:Dock(TOP)
		checks.checks = {}
		for k, v in SortedPairs (self.data.models) do
			local check = tf.TFStyleVGUI("DCheckBoxLabel", checks)
			check.model = k
			local text = string.NiceName(k)
			if k == "item" then
				text = tf.GetPhrase("#Item") or "Item"
			elseif k == "attached_festive" then
				text = tf.GetPhrase("#TF_FestivizerTool") or "Festivizer"
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
		checks:DockMargin(side_margins,0,side_margins,tf.betweencategories)
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

		pnl.class = AddDropdown(tf.GetPhrase("#TF_ImportFile_Models") or "Class:", function(drop)
			for k, v in ipairs (tf.classes) do //add class options in class order
				if i.used_by_classes[v.longname] then
					drop:AddChoice(tf.GetPhrase(v.langstr) or string.NiceName(v.longname), k, self.data.class == k)
				end
			end
		end, function(data)
			self.data.class = data
		end)

		if i.visuals and i.visuals.styles and table.Count(i.visuals.styles) > 1 then
			local name = (tf.GetPhrase("#Context_Style") or "Style") .. ":"
			if i._call_styles_animations then name = (tf.GetPhrase("#TF_ImportFile_AnimationSource") or "Animation") .. ":" end
			local drop = AddDropdown(name, function(drop)
				for k, _ in SortedPairs (i.visuals.styles) do //this starts from 0 so we can't do ipairs
					drop:AddChoice(tf.GetItemStyleName(self.data.id, k), k, self.data.style == k)
				end
			end, function(data)
				self.data.style = data
			end)
			if i._call_styles_animations then drop:SetEnabled(tf.GetDependency("animprop") and (tf.GetDependency("advbone") or !IsValid(TF2ItemBrowser:GetEntity()))) end
		end

		if i.capabilities and i.capabilities.paintable == 1 then
			local drop = AddDropdown(string.Trim(string.Replace(tf.GetPhrase("#Econ_Paint_Name") or "Paint Color:", "%s1", "")), function(drop)
				drop:AddChoice(tf.str_none, nil, !self.data.paint.enabled or (i._default_paint and self.data.paint.col[false] == i._default_paint[false]))
				drop:AddSpacer()
				for k, v in ipairs (paints) do
					local is_selected = self.data.paint.enabled and (self.data.paint.override[false] == v.override or (self.data.paint.col[false] == v[1] and self.data.paint.col[true] == v[2]))
					drop:AddChoice(tf.GetPhrase(v.name) or v.name, v, is_selected)
				end
				if drop:GetText() == "" then drop:SetText(tf.str_custom) end
			end, function(data)
				if !data then
					if i._default_paint then
						self.data.paint.enabled = true
						self.data.paint.col = table.Copy(i._default_paint)
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
					tf.LoadoutItemPopupBorder(0,0,w,h)
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
				text:SetColor(tf.gui_colors.TanLight)
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
						surface.SetDrawColor(tf.gui_colors.LightRed)
					else
						surface.SetDrawColor(tf.gui_colors.TanDark)
					end
					surface.SetMaterial(tf.close_button)
					surface.DrawTexturedRect(0,0,w,h)
				end
				tf.AddTFButtonSounds(close)
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
						name = tf.GetPhrase(data.name) or data.name
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
							_col = tf.gui_colors.LightRed
						elseif button.Hovered then
							_col = tf.gui_colors.TanLight
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
							draw.RoundedBox(c_whole, bd,bd,w-bd-bd,h-bd-bd, tf.gui_colors.TanDarker)
							surface.SetDrawColor(tf.gui_colors.LightRed)
							surface.SetMaterial(tf.close_button_nocircle)
							local w2 = w * 0.75
							local h2 = h * 0.75
							surface.DrawTexturedRect((w-w2)/2, (h-h2)/2, w2, h2)
						end
					end
					tf.AddTFButtonSounds(button)
					//These buttons are too small to add labels to, so do mouseover tooltips instead (but tf2-themed)
					tf.AddTFStyleTooltip(button, name or v)
				end
				icons:SetSize(((size+4)*6)+16, 16+((size+4)*(math.ceil(#drop.Choices/6))))
				icons:InvalidateLayout()

				local col = tf.TFStyleVGUI("DColorMixer", container)
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
					drop:SetText(tf.str_custom)
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
			drop:SetEnabled(tf.GetDependency("hatpainter"))
		end

		//Show critglow option for items that are equipped as non-passive weapons in TF2, and have a valid model to apply it to
		local wep_slots = {primary = true, secondary = true, melee = true, utility = true, pda = true, pda2 = true, building = true}
		if (wep_slots[i.item_slot] and i.anim_slot != "FORCE_NOT_USED" and !i.act_as_wearable and self.data.models.item != nil) or (i.item_slot == "action" and i.act_as_weapon) then
			local drop = AddDropdown("Crit Glow Color:", function(drop) //no tf localization string for this
				drop:AddChoice(tf.str_none, nil, !self.data.crit.enabled)
				drop:AddSpacer()
				for k, v in ipairs (critglows) do
					local is_selected = self.data.crit.enabled and self.data.crit.col[false] == v[1] and self.data.crit.col[true] == v[2]
					drop:AddChoice(tf.GetPhrase(v.name) or v.name, v, is_selected)
				end
				if drop:GetText() == "" then drop:SetText(tf.str_custom) end
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
					tf.LoadoutItemPopupBorder(0,0,w,h)
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
				text:SetColor(tf.gui_colors.TanLight)
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
						surface.SetDrawColor(tf.gui_colors.LightRed)
					else
						surface.SetDrawColor(tf.gui_colors.TanDark)
					end
					surface.SetMaterial(tf.close_button)
					surface.DrawTexturedRect(0,0,w,h)
				end
				tf.AddTFButtonSounds(close)
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
						name = tf.GetPhrase(data.name) or data.name
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
							_col = tf.gui_colors.LightRed
						elseif button.Hovered then
							_col = tf.gui_colors.TanLight
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
							draw.RoundedBox(c_whole, bd,bd,w-bd-bd,h-bd-bd, tf.gui_colors.TanDarker)
							surface.SetDrawColor(tf.gui_colors.LightRed)
							surface.SetMaterial(tf.close_button_nocircle)
							local w2 = w * 0.75
							local h2 = h * 0.75
							surface.DrawTexturedRect((w-w2)/2, (h-h2)/2, w2, h2)
						end
					end
					tf.AddTFButtonSounds(button)
					//These buttons are too small to add labels to, so do mouseover tooltips instead (but tf2-themed)
					tf.AddTFStyleTooltip(button, name or v)
				end
				icons:SetSize(((size+4)*6)+16, 16+((size+4)*(math.ceil(#drop.Choices/6))))
				icons:InvalidateLayout()

				local check = tf.TFStyleVGUI("DCheckBoxLabel", container)
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

				local check = tf.TFStyleVGUI("DCheckBoxLabel", container)
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

				local col = tf.TFStyleVGUI("DColorMixer", container)
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
					drop:SetText(tf.str_custom)
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
			drop:SetEnabled(tf.GetDependency("hatpainter"))
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
			local drop2 = tf.TFStyleVGUI("DComboBox", container)
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
		local unu_tab, unu_type = tf.GetItemUnusualEffects(self.data.id)
		if unu_tab then
			local drop = AddDropdown(string.Trim(tf.GetPhrase("#IT_UnusualTitle") or "Unusual effect:"), function(drop)
				drop:AddChoice(tf.str_none, 0, self.data.pe_unusual == 0)
				drop:AddSpacer()
				for _, tab in ipairs (unu_tab) do
					drop:AddChoice(tf.GetPhrase("#Attrib_Particle" .. tab.k) or tab.v.system, tab.k, self.data.pe_unusual == tab.k)
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
					tf.LoadoutItemPopupBorder(0,0,w,h)
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
				text:SetColor(tf.gui_colors.TanLight)
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
						surface.SetDrawColor(tf.gui_colors.LightRed)
					else
						surface.SetDrawColor(tf.gui_colors.TanDark)
					end
					surface.SetMaterial(tf.close_button)
					surface.DrawTexturedRect(0,0,w,h)
				end
				tf.AddTFButtonSounds(close)
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
					local tab = tf.TF2Items.attribute_controlled_attached_particles_all[data]
					if tab and tab.system then
						local name = tab.system
						if name:EndsWith("_teamcolor_red") and self.data.team then
							name = string.Replace(name, "_teamcolor_red", "_teamcolor_blue")
						end
						if tab.use_suffix_name then name = name .. "_" .. i.particle_suffix end
						
						local pcfs = PEPlus_FindPCFsFromEffect(name)
						if !pcfs then MsgN("TF2ItemBrowser: no pcfs for effect ", name, "?") continue end
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
							name = string.Replace(name, "Summer", tf.GetPhrase("#TF_SteamWorkshop_Tag_Summer") or "Summer")
						elseif string.StartsWith(name, "Halloween") then
							name = string.Replace(name, "Halloween", tf.GetPhrase("#TF_SteamWorkshop_Tag_Halloween") or "Halloween")
						elseif string.StartsWith(name, "Smissmas") then
							name = string.Replace(name, "Smissmas", tf.GetPhrase("#TF_SteamWorkshop_Tag_Smissmas") or "Smissmas")
						elseif name == "Other" then
							name = tf.GetPhrase("#AbuseReport_TypeOther") or "Other" //using this localization string for "Other" items is a stretch but it's the best we've got
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

					search = tf.TFStyleVGUI("DTextEntry", search_holder)
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
				local scroll = tf.TFStyleVGUI("DScrollPanel",icons_holder)
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
				if unu_type == "hat" then
					slider = tf.TFStyleVGUI("DNumSlider", container)
					slider:SetText(tf.GetPhrase("#GameUI_ParticleHatUseHead") or "Adjust Unusual")
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
					slider.DoRightClick = function() end //by default, this opens a dermamenu to copy the slider's value or reset it, but there's no easy way to prevent this from auto-closing the unusual effect menu, so just disable it for now.
					
					//we have a lot of horizontal space to work with, so just place the check to enable the slider to the left of it
					check = tf.TFStyleVGUI("DCheckBox", slider)
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

					if !tf.GetDependency("advbone") then
						slider:SetEnabled(false)
						slider.Label:SetColor(tf.gui_colors.TanDark)
						check:SetEnabled(false)
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
							local col = tf.gui_colors._unu_default
							if icon.Depressed or self.data.pe_unusual == drop.Data[entry.k] then //highlight the currently selected option
								col = tf.gui_colors._unu_depressed
							elseif icon.Hovered then
								col = tf.gui_colors._unu_hovered
							end
							draw.RoundedBox(12, 0,0,w,h, col)

							old_Paint(icon,w,h)
							icon:SetTooltip(nil) //icon's paint func sets the tooltip, so we have to override this here

							//custom appearance for "none" option so it isn't just blank
							if entry.pcf == "" then
								surface.SetDrawColor(tf.gui_colors.LightRed)
								surface.SetMaterial(tf.close_button_nocircle)
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
							label:SetTextColor(tf.gui_colors.TanLight)
							label:SetAutoStretchVertical(true)
							label:SetContentAlignment(5) //center
						end
						tf.AddTFButtonSounds(icon)
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
					if unu_type == "hat" then control_height = control_height + 16 + slider:GetTall() end
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
			drop:SetEnabled(tf.GetDependency("pe+"))
		end

		//Show toggle for default particle effects (cigar smoke, halo effect, earbud notes, etc.)
		local pe_def = tf.GetItemDefaultParticleEffects(self.data)
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
			local check = tf.TFStyleVGUI("DCheckBoxLabel", pnl)
			check:SetText("Add default particle effects (" .. name .. ")")
			check:Dock(TOP)
			check:DockMargin(side_margins,0,side_margins,tf.betweenitems)
			check:SetChecked(self.data.pe_def)
			check.OnChange = function(_, val)
				self.data.pe_def = val
				pnl.OnSettingChanged()
			end
			check:SetEnabled(tf.GetDependency("pe+"))
		end

		if i._paintkit and (!tf.GetDependency("wp") or WP.Weapons.IsSupported(i.model_player)) then
			local drop = AddDropdown((tf.GetPhrase("#TF_ItemPreview_ItemPaintkit") or "War Paint") .. ":", function(drop)
				drop:AddChoice(tf.str_none, nil, self.data.wp.enabled == false)
				drop:AddSpacer()
				if tf.GetDependency("wp") then
					local tab = WP.WarpaintData.GetForWeaponType(WP.Weapons.GetFromModel(i.model_player))
					for k, v in ipairs (tab) do
						//MsgN(v.id, ", ", v.name, ", ", WP.Proto.Localization.GetWarpaintName(v.name, v.locToken), ", ", WP.Proto.Items.GetCollection(v.id, true), ", ", WP.Proto.Items.GetCollectionCategory(v.id))
						drop:AddChoice(WP.Proto.Localization.GetWarpaintName(v.name, v.locToken), v, self.data.wp.enabled and self.data.wp.id == v.id)
					end
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
					tf.LoadoutItemPopupBorder(0,0,w,h)
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
				text:SetColor(tf.gui_colors.TanLight)
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
						surface.SetDrawColor(tf.gui_colors.LightRed)
					else
						surface.SetDrawColor(tf.gui_colors.TanDark)
					end
					surface.SetMaterial(tf.close_button)
					surface.DrawTexturedRect(0,0,w,h)
				end
				tf.AddTFButtonSounds(close)
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
				for k, v in ipairs (tf.paintkit_collections) do
					if category_remaps[v] then v = category_remaps[v] end
					categories[v] = categories[v] or {order = k, items = {}}
				end
				
				for k, v in pairs (drop.Choices) do
					local data = drop.Data[k]
					if data then 
						local cat = tf.paintkit_ids_to_collections[data.id] or "Other"
						if category_remaps[cat] then cat = category_remaps[cat] end
						table.insert(categories[cat].items, {k = k, v = v, data = data})
					end
				end
				//Sort the categories by display order, and discard empty categories
				local cat2 = {}
				for k, v in pairs (categories) do
					if #v.items > 0 then 
						local name = k
						if tf.TF2Items.item_collections[k] then
							name = tf.GetPhrase(tf.TF2Items.item_collections[k].name) or k
						elseif name == "Other" then
							name = tf.GetPhrase("#AbuseReport_TypeOther") or "Other" //using this localization string for "Other" items is a stretch but it's the best we've got
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

					search = tf.TFStyleVGUI("DTextEntry", search_holder)
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
				local scroll = tf.TFStyleVGUI("DScrollPanel",icons_holder)
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

				local entry = tf.TFStyleVGUI("DTextEntry", container, true)
				local entrypnl = tf.AddTFLabelToVGUI(entry, "Seed")
				entrypnl:Dock(TOP)
				entrypnl:DockMargin(0,16,0,0)
				entry:SetNumeric(true)
				entry:SetText(self.data.wp.seed or "1")
				entry.OnEnter = function()
					local val = entry:GetText()
					//Using one of these seed values makes the war paint generate with a random seed, but that isn't
					//immediately obvious to the user, and causes unintuitive behavior where the seed gets randomized
					//again every time the WP is reapplied, so instead replace it with an actual visible random seed.
					//(I'm fairly sure these are the only bad seed values, see WP.RNG.NormalizeSeed)
					if val == "" or val == "0" then
						entry:SetText(tostring(WP.RNG.RandomSeed()))
						entry:OnEnter()
						return
					end
					if val != self.data.wp.seed then 
						self.data.wp.seed = val
						pnl.OnSettingChanged()
					end
				end
				entry.OnFocusChanged = function(_, b) 
					if !b then entry:OnEnter() end
				end
				local button = tf.TFStyleVGUI("DButton", entrypnl)
				button:SetText(tf.GetPhrase("#TF_ItemPreview_PaintkitSeed") or "Randomize")
				button:SizeToContentsX(20)
				button:Dock(RIGHT)
				button:DockMargin(8,0,0,0)
				button.DoClick = function()
					local val = tostring(WP.RNG.RandomSeed())
					entry:SetText(val)
					self.data.wp.seed = val
					pnl.OnSettingChanged()
				end

				local slider = tf.TFStyleVGUI("DNumSlider", container)
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
				slider.DoRightClick = function() end //by default, this opens a dermamenu to copy the slider's value or reset it, but there's no easy way to prevent this from auto-closing the paintkit menu, so just disable it for now.

				//The rest of these paintkit settings are global convars, not saved to the entity, so categorize them separately

				local combo = AddSubDropdown(container)
				local combopnl = tf.AddTFLabelToVGUI(combo, "Texture Resolution (Global)")
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

				local check = tf.TFStyleVGUI("DCheckBoxLabel", container)
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
				help:SetColor(tf.gui_colors.TanLight)
				help:SetText("Non-TF2-accurate wear with higher visual intensity")
				help:Dock(TOP)
				help:DockMargin(22,0,32,0)
				local intensity_help = help

				local slider = tf.TFStyleVGUI("DNumSlider", container)
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
				slider.DoRightClick = function() end //by default, this opens a dermamenu to copy the slider's value or reset it, but there's no easy way to prevent this from auto-closing the paintkit menu, so just disable it for now.

				local check = tf.TFStyleVGUI("DCheckBoxLabel", container)
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
				help:SetColor(tf.gui_colors.TanLight)
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
							local col = tf.gui_colors._unu_default
							local textcol = tf.gui_colors.TanLight
							if (self.data.wp.enabled and entry.data and self.data.wp.id == entry.data.id)
							or (!self.data.wp.enabled and !entry.data) or icon.Depressed then //highlight the currently selected option
								col = tf.gui_colors._unu_depressed
							elseif icon.Hovered then
								col = tf.gui_colors._unu_hovered
							elseif entry.data then
								//Show quality color on text label, but revert to the default color when hovered/selected,
								//because some colors are too hard to read as small text on some of these backgrounds
								textcol = tf.rarity_colors[tf.paintkit_rarities[entry.data.id]] or textcol
							end
							draw.RoundedBox(12, 0,0,w,h, col)
							for k, v in ipairs (icon.labels) do
								v:SetTextColor(textcol)
							end

							icon.Image:PaintAt(0,0,w,h)

							//custom appearance for "none" option so it isn't just blank
							if !entry.data then
								surface.SetDrawColor(tf.gui_colors.LightRed)
								surface.SetMaterial(tf.close_button_nocircle)
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
							label:SetTextColor(tf.gui_colors.TanLight)
							label:SetAutoStretchVertical(true)
							label:SetContentAlignment(5) //center
							table.insert(icon.labels, label)
						end
						tf.AddTFButtonSounds(icon)
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
								table.insert(TF2ItemBrowser.IconRenderQueue, {func = function()
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
									local cam = tf.DoItemModelCamera(models, self)
									render.SetWriteDepthToDestAlpha(false)
									render.Clear(0, 0, 0, 0, true, true)
									tf.DrawItemModels(0, 0, size, size, models, {}, cam.ang, cam.pos, cam.fov)
									local img = render.Capture({format = "png", x = 0, y = 0, w = size, h = size})
									if !file.IsDir("tf2itembrowser_paintkiticons/", "DATA") then 
										file.CreateDir("tf2itembrowser_paintkiticons/")
									end
									if file.Write(iconpath, img) then
										icon:SetMaterial("data/" .. iconpath)
									end
									ent:Remove()
									return true
								end})
								icon:SetMaterial(tf.spinner:GetName())
							end
							if file.Exists("materials/vgui/" .. iconpath, "GAME") then
								//addon includes pre-rendered icons for these so that users won't have to render them,
								//but in case new paintkits are added, they'll be able to render them on their own
								icon:SetMaterial("materials/vgui/" .. iconpath)
							else
								if file.Exists(iconpath, "DATA") then
									icon:SetMaterial("data/" .. iconpath)
								else
									icon.RebuildIconTexture()
								end
								function icon.DoRightClick()
									//local menu = DermaMenu()

									//local opt = menu:AddOption("Re-render", function()
										icon.RebuildIconTexture()
									//end)
									//opt:SetIcon("icon16/picture_save.png")

									//menu:Open()
								end
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
			drop:SetEnabled(tf.GetDependency("wp"))
		end
	else
		local h = 0 //gotta do it this way again to make the multiline item text set the correct height
		h = h + self:AddItemText(name_container, self.itemname, "TF2ItemBrowser_ItemName", tf.rarity_colors[self.rarity] or tf.quality_colors[self.quality])
		//use additemtext for the help text as well, because pnl won't set its height correctly if a DLabel with SetAutoStretchVertical is docked inside
		local str = "\nAll settings here apply to items that support that option - setting paint chance to 100% will paint any random items that are paintable, not filter out items that aren't paintable. For that, use the filter options to the left!"
		if IsValid(TF2ItemBrowser:GetEntity()) then
			str = str .. "\n\nTip: Filter out \"Conflicts with Equipped\" to always generate valid loadouts."
		end
		h = h + self:AddItemText(name_container, str, "TF2ItemBrowser_ItemDesc_Smaller", tf.gui_colors.TanLight)
		name_container:SetHeight(h)
		name_container:DockMargin(0,0,0,tf.betweencategories)

		function pnl.Refresh()
			pnl:InvalidateLayout(true)
			pnl:SizeToChildren(false,true)
			self:PositionPopupPanel(pnl)
		end

		local function AddChanceSlider(label, key, default)
			local slider = tf.TFStyleVGUI("DNumSlider", pnl)
			slider:SetText(label)
			slider:SetMinMax(0, 100)
			slider:SetDecimals(0)
			slider:SetDefaultValue(math.Round(default*100))
			slider:SetValue(math.Round(self.random[key]*100))
			slider:Dock(TOP)
			slider:DockMargin(side_margins,0,side_margins,tf.betweenitems)
			function slider.OnValueChanged(_, val)
				self.random[key] = val/100
			end
			return slider
		end
		local function AddCheckBox(label, key)
			local check = tf.TFStyleVGUI("DCheckBoxLabel", pnl)
			check:SetText(label)
			check:Dock(TOP)
			check:DockMargin(side_margins,0,side_margins,tf.betweencategories)
			check:SetChecked(self.random[key])
			check.OnChange = function(_, val)
				self.random[key] = val
			end
			return check
		end

		local drop = AddDropdown("Prefer class model:", function(drop)
			for k, v in ipairs (tf.classes) do //add all classes in order, except "(none)"
				if k > 10 then continue end
				drop:AddChoice(tf.GetPhrase(v.langstr) or string.NiceName(v.longname), k, self.random.class == k)
				if k == 1 then drop:AddSpacer() end
			end
		end, function(data)
			self.random.class = data
		end)
		drop:GetParent():DockMargin(side_margins,0,side_margins,tf.betweencategories)

		local slider = AddChanceSlider("Paint chance", "paint_chance", 0.5)
		local check = AddCheckBox("Match paint color of other equipped items?", "paint_match")
		if !tf.GetDependency("pe+") then
			slider:SetValue(0)
			slider:SetEnabled(false)
			slider.Label:SetColor(tf.gui_colors.TanDark)
			check:SetChecked(false)
			check:SetEnabled(false)
			self.random.paint_chance = 0
		end

		local slider = AddChanceSlider("Unusual chance", "unusual_chance", 0.2)
		local check = AddCheckBox("Must be headgear or war painted?", "unusual_validonly")
		if !tf.GetDependency("pe+") then
			slider:SetValue(0)
			slider:SetEnabled(false)
			slider.Label:SetColor(tf.gui_colors.TanDark)
			check:SetChecked(false)
			check:SetEnabled(false)
			self.random.unusual_chance = 0
		end

		local slider = AddChanceSlider("War Paint chance", "wp_chance", 0.5)
		local check = AddCheckBox("Random wear level?", "wp_randomwear")
		if !tf.GetDependency("wp") then
			slider:SetValue(0)
			slider:SetEnabled(false)
			slider.Label:SetColor(tf.gui_colors.TanDark)
			check:SetChecked(false)
			check:SetEnabled(false)
			self.random.wp_chance = 0
		end

		AddChanceSlider("Festivizer chance", "festivizer_chance", 0.2)
		AddChanceSlider("Australium chance", "aus_chance", 0.2)
	end

	local button = tf.TFStyleVGUI("DButton", pnl)
	if IsValid(self.entity) then
		button:SetText(string.upper(tf.GetPhrase("#Store_Remove" or "Remove")))
		button.BGColor = tf.gui_colors.LightRed //using this as the neutral unselected color looks a little strange, but we can't use TFOrange as the unselected color because it could trick the player when switching from equip to unequip mode; also this matches the loadout preset buttons in TF2
	elseif IsValid(TF2ItemBrowser:GetEntity()) then
		button:SetText(tf.GetPhrase("#Equip") or "EQUIP")
	else
		button:SetText(string.upper(language.GetPhrase("#spawn") or "spawn")) //tf2's localization files don't have the word "spawn" so this is from gmod's community.properties; hopefully this is translated as the action of spawning (verb) and not the location (noun)
	end
	button:Dock(TOP)
	button:DockMargin(side_margins,tf.betweencategories-tf.betweenitems,side_margins,tf.betweencategories)
	button:SetDoubleClickingEnabled(false) //make the button spam-clickable like spawnicons
	button.DoClick = function()
		if !self.random then
			if IsValid(self.entity) then
				TF2ItemBrowser:DoInput("attach_item_remove", self.entity)
			elseif IsValid(TF2ItemBrowser:GetEntity()) then
				TF2ItemBrowser:DoInput("attach_item_spawn", self.data, true)
			else
				TF2ItemBrowser:DoInput("item_spawn", self.data)
			end
			surface.PlaySound(self.sound_drop)
		else
			self:GenerateRandomItem()
		end
	end
	
	pnl:SetWide(tf.popup_w)
	pnl.Refresh()
	self.popup = pnl
	function pnl:Paint(w,h)
		self.Owner:PositionPopupPanel(self)
		tf.LoadoutItemPopupBorder(0,0,w,h)
	end

	local close = vgui.Create("DButton", pnl)
	close:SetText("")
	close:SetSize(22,22)
	close:SetPos(tf.popup_w-close:GetWide()-12, 12)
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
		pnl:Remove()
	end

	function pnl.OnRemove()
		if !self.random then
			//If this itemicon doesn't correspond to an entity, then revert any changes when we close the spawn panel
			if !IsValid(self.entity) and IsValid(self) then self:SetDefaultData() end //don't run this when the itemicon is being deleted

			//If any of the custom dropdown menus (i.e. paints, unusuals) are currently open, close them
			for _, pnl2 in ipairs (pnl:GetChildren()) do
				for _, pnl3 in ipairs (pnl2:GetChildren()) do
					if IsValid(pnl3.container) then pnl3.container:Remove() end
				end
			end
		else
			//Reset random item settings
			self:SetupRandomItemIcon()
		end
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
		local icon_size = tf.cv_icon_size:GetInt()
		local scale = tf.item_icon_sizes[icon_size].scale
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
		
		//these panels are a bit shorter than they are wide, so cut off the bottom and top of the material to center it
		local diff = (1-(h/w))/2
		local ustart, uend, vstart, vend = 0, 1, 0+diff, 1-diff
		local x, y, w2, h2 = 0, 0, w, h
		if self.mat_smallericon then
			//The rendertarget materials we generate will draw slightly *zoomed in* by default, cutting off the edges on all 
			//sides as if they were rescaled using $basetexturetransform. Drawing them tiled (i.e with 0-to-2 UVs) shows that 
			//the rest of the texture still *exists*, just *outside* of the 0-to-1 UV space, so we can fix this by zooming the 
			//UVs out past 0 and 1, but why does this happen in the first place??
			ustart = -0.0295
			uend = 1.0295
			vstart = math.Remap(vstart, 0, 1, ustart, uend)
			vend = math.Remap(vend, 0, 1, ustart, uend)
			//Draw weapon skin/festivizer rendertarget icons at a slightly smaller size on top of that, to match their appearance in TF2
			w2 = w * 0.9275
			h2 = h * 0.9275
			x = x + (w-w2)/2
			y = y + (h-h2)/2
		end
		
		surface.DrawTexturedRectUV(x,y,w2,h2,ustart,vstart,uend,vend)
		if self.mat_overlay then
			local col = self.data.paint.col[false]
			surface.SetDrawColor(col.x, col.y, col.z, 255)
			surface.SetMaterial(self.mat_overlay)
			surface.DrawTexturedRectUV(x,y,w2,h2,ustart,vstart,uend,vend)
		end
	elseif self.ImageToQueue then
		self.mat_smallericon = nil
		if TF2ItemBrowser_ImageQueuedBefore[self.ImageToQueue] then
			self.mat = Material(self.ImageToQueue, "smooth")
		else
			table.insert(TF2ItemBrowser.ImageQueue, {pnl = self, img = self.ImageToQueue})
		end
		self.ImageToQueue = nil
	elseif self.IconRenderToQueue then
		local i = tf.TF2Items.items[self.data.id] or {}
		local data = table.Copy(self.data)
		//spawnicons should always use red team; in tf2 this is a little inconsistent, and uses team colors for warpaints but always red for model skins; we can't really do this without adding special handling to recreate this bug, so instead try to match all prerendered spawnicons
		data.team = false
		//don't show any visual changes from fx/paint/critglow/unusuals on the icon either, to match TF2's prerendered icons
		data.fx = 0
		data.paint.enabled = false
		data.crit.enabled = false
		data.pe_unusual = 0
		data.pe_def = false
		if i._customitem_bp then
			if i._customitem_bp.style then
				data.style = i._customitem_bp.style
			end
			if i._customitem_bp.class then
				data.class = tf.class_longname_to_id[i._customitem_bp.class]
			end
			if i._customitem_bp.mdl then
				for k, v in ipairs ({"item", "wearable", "wearable_2"}) do
					if data.models[v] != nil then
						data.models[v] = (i._customitem_bp.mdl == v)
					end
				end
			end
		end

		local models
		local function CleanUpModels()
			if models then
				for k, v in ipairs (models) do
					if IsValid(v) then v:Remove() end
				end
			end
		end
		
		self.IconRenderToQueue = nil
		table.insert(TF2ItemBrowser.IconRenderQueue, {pnl = self, func = function()
			//if icon no longer exists, then remove from the queue
			if !IsValid(self) then
				CleanUpModels()
				return true
			end

			if !models then
				models = self:CreateItemModels(data, true) //disable fallback model
				if models and i._customitem_bp then
					//inject class model for i._customitem_bp.showclass
					if i._customitem_bp.showclass then
						local ent = ClientsideModel("models/player/" .. tf.classes[data.class].shortname .. ".mdl", RENDERGROUP_OTHER)
						if IsValid(ent) then
							if models[1] then
								models[1]:SetParent(ent)
								models[1]:AddEffects(EF_BONEMERGE)
							end
							table.insert(models, 1, ent)
							for k, v in pairs (tf.GetItemModelVisuals(data).ply_bg) do
								if isstring(k) then k = ent:FindBodygroupByName(k) end //on some items, k is a number already
								ent:SetBodygroup(k, v)
							end
							ent:SetNoDraw(true)
							ent:SetIK(false)
						end
					end
					//use model angle specified in table
					if IsValid(models[1]) then
						models[1]:SetAngles(i._customitem_bp.mdlang)
					end
				end
			end

			//For war paints and festivizers, use a temporary render target, because these 
			//are just incidental changes to an item and aren't likely to be reused much
			if !i._customitem_bp then
				//if there's nothing to render, then call it done
				if table.Count(models) == 0 then
					self.no_image = true
					CleanUpModels()
					return true
				end

				local rtkey = table.KeyFromValue(TF2ItemBrowser_IconRTs, self)
				if !rtkey then
					for i = 1, 128 do //unnecessary max number of simultaneous rt icons; this is just a safeguard to not generate infinite textures in case this really screws up somehow
						//get first nil key we can find; as icons are removed from this list, they can leave gaps for us to take
						if TF2ItemBrowser_IconRTs[i] == nil then
							TF2ItemBrowser_IconRTs[i] = self
							rtkey = i
							break
						end
					end
				end
				if rtkey == nil then return false end
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
				if rt == nil then MsgN("Failed to create render target ", rtname, "; out of memory?") return false end

				//Don't render the icon until the paintkit material is no longer a placeholder
				if self.data.wp.enabled and tf.GetDependency("wp") then
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
				render.OverrideAlphaWriteEnable(true, true)
				local cam = i._customitem_bp or tf.DoItemModelCamera(models, self)
				render.SetWriteDepthToDestAlpha(false)
				render.Clear(0, 0, 0, 0, true, true)
				tf.DrawItemModels(0, 0, 128, 128, models, {}, cam.ang, cam.pos, cam.fov)
				render.OverrideAlphaWriteEnable(false)
				render.PopRenderTarget()

				local mat = CreateMaterial(rtname, "UnlitGeneric", {
					["$basetexture"] = "color/white",
					["$translucent"] = "1",
					["$vertexcolor"] = "1",
				})
				mat:SetTexture("$basetexture", rt)
				//self:SetMaterial("!" .. rtname)
				self.mat = mat
				self.mat_smallericon = true //we only want to use the smaller icons for weapon skins/festives to make them match TF2, not our custom items

				CleanUpModels()
				return true
			//For custom items, save the icon to a png, because we'll reuse it every time the item is shown in the browser; 
			//reusing these prevents the awful hitching caused by model loading when scrolling down to view them
			else
				render.OverrideAlphaWriteEnable(true, true)
				local cam = i._customitem_bp
				render.SetWriteDepthToDestAlpha(false)
				render.Clear(0, 0, 0, 0, true, true)
				tf.DrawItemModels(0, 0, 128, 128, models, {}, cam.ang, cam.pos, cam.fov)
				render.OverrideAlphaWriteEnable(false)

				local img = render.Capture({format = "png", x = 0, y = 0, w = 128, h = 128})
				if !file.IsDir("tf2itembrowser_customitemicons/", "DATA") then 
					file.CreateDir("tf2itembrowser_customitemicons/")
				end
				if file.Write("tf2itembrowser_customitemicons/" .. i.name .. ".png", img) then
					self.mat = Material("data/tf2itembrowser_customitemicons/" .. i.name .. ".png", "smooth")
				end

				CleanUpModels()
				return true
			end
		end})
	elseif !self.no_image then
		//show loading icon
		surface.SetMaterial(tf.spinner)
		surface.DrawTexturedRect((w/2)-(h/2), 0, h, h)
	end

	if self.icons then
		local icon_size = tf.cv_icon_size:GetInt()
		local size = tf.item_icon_sizes[icon_size].cornericon
		local xpos = w - size - (3 * tf.item_icon_sizes[icon_size].scale) 
		local ypos = 2 * tf.item_icon_sizes[icon_size].scale
		for k, v in ipairs (self.icons) do
			surface.SetMaterial(v.icon)
			//update spell colors if applicable (note: these shouldn't be populated if hatpainter addon isn't found)
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

	//if the item model hasn't been loaded yet, the game will stutter when the spawnpanel is opened,
	//so wait until the next frame so that the sound doesn't play and then immediately get cut off
	timer.Simple(0, function() surface.PlaySound(self.sound_pressed) end)

	self:CreateSpawnPanel()

end

function PANEL:DoRightClick()

	
	//do this on a timer too just to make sure it doesn't sound subtly different from left-click
	timer.Simple(0, function() surface.PlaySound(self.sound_pressed) end) //not tf2-authentic to do this on right click, but feels better this way
	
	local menu = DermaMenu()

	//quick-spawn options, to spawn/equip items quickly without customizing them first, or to unequip items more efficiently
	local str, func
	if self.random then
		func = function() self:GenerateRandomItem() end
	end
	if IsValid(self.entity) then
		str = string.NiceName(string.lower(tf.GetPhrase("#Store_Remove" or "Remove")))
		func = func or function()
			TF2ItemBrowser:DoInput("attach_item_remove", self.entity)
			surface.PlaySound(self.sound_drop)
		end
	elseif IsValid(TF2ItemBrowser:GetEntity()) then
		str = string.NiceName(string.lower(tf.GetPhrase("#Equip") or "EQUIP"))
		func = func or function()
			TF2ItemBrowser:DoInput("attach_item_spawn", self.data, false)
			timer.Simple(FrameTime(), function() surface.PlaySound(self.sound_drop) end) //like GenerateRandomItem, wait a frame just to make sure first-time model loads don't cut the sound off
		end
	else
		str = string.NiceName(string.NiceName(language.GetPhrase("#spawn") or "spawn")) //tf2's localization files don't have the word "spawn" so this is from gmod's community.properties; hopefully this is translated as the action of spawning (verb) and not the location (noun)
		func = func or function()
			TF2ItemBrowser:DoInput("item_spawn", self.data)
			timer.Simple(FrameTime(), function() surface.PlaySound(self.sound_drop) end) //^^
		end
	end
	menu:AddOption(str, func)

	if !self.random then
		if isstring(self.data.id) and tf.PlayerCanEditCustomItems() then
			menu:AddOption("Edit custom item", function()
				TF2ItemBrowser_OpenCustomItemEditor(self.data.id)
			end)

			if tf.TF2Items.items[self.data.id]._customitem_bp then
				menu:AddOption("#spawnmenu.menu.rerender", function()
					//Tell our paint func to queue rendering a custom rendertarget icon
					self.mat = nil
					self.ImageToQueue = nil
					self.IconRenderToQueue = true
				end)
			end
		end

		//also put this debug option here
		//if GetConVarNumber("developer") >= 1 then
			menu:AddSpacer()
			menu:AddOption("Print item data in console", function()
				MsgN("\n\n\n")
				MsgN(self.data.id, " ", tf.TF2Items.items[self.data.id].name)
				PrintTable(tf.TF2Items.items[self.data.id])
			end)
		//end
	end

	self.menu = menu
	menu:Open()
	tf.AddTFStyleToVGUI(menu)

end

tf.AddTFButtonSounds(PANEL)

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

vgui.Register("TF2ItemBrowser_Icon", PANEL, "DButton")