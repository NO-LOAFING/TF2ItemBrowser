local classes = {"(any)", "scout", "soldier", "pyro", "demoman", "heavy", "engineer", "medic", "sniper", "spy", "none"}
//our favorite black scottish cyclops is called "demoman" in all item definition keys (used_by_classes, model_player_per_class, etc.), 
//"demo" in model paths, and either one interchangably in equip region names. dumb!!!
for k, v in ipairs (classes) do
	local shortname = v
	if v == "demoman" then shortname = "demo" end
	classes[k] = {shortname = shortname, longname = v}
end


local _s = file.Read("scripts/items/items_game.txt", "tf")
local s = util.KeyValuesToTable(_s)


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
end


//s.equip_regions has multiple "shared" keys that are subtables filled with many different class-specific strings, but these get clobbered by util.KeyValuesToTable, 
//so we have to rescue them. also use this chance to get the implementation order, because it makes the equip region list look nicer.
local s2 = util.KeyValuesToTablePreserveOrder(_s)
local tab = {}
for _, class in ipairs (classes) do //sort these by class so we can filter them easily + print class-based ones in class order
	tab[class.longname] = {}
end

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
		break
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
	
	list.Set("DesktopWindows", "TF2ItemBrowser", {
		title		= "TF2 Item Browser",
		icon		= "games/16/tf.png", //TODO: temp
		width		= 960, //TODO: better values later
		height		= 700,
		onewindow	= true,
		init		= function(widgetIcon, window)

			//window stuff from playermodel selector, how much of this do we care about?
			--[[window:SetTitle( "#smwidget.playermodel_title" )
			window:SetSize( math.min( ScrW() - 16, window:GetWide() ), math.min( ScrH() - 16, window:GetTall() ) )]]
			window:SetSizable(true)
			--[[window:SetMinWidth( window:GetWide() )
			window:SetMinHeight( window:GetTall() )
			window:Center()]]

			function window:Paint(w, h)
				surface.SetDrawColor(bgcol)
				surface.DrawRect(0,0,w,h)
			end


			local scroll = vgui.Create("DScrollPanel", window)
			scroll:Dock(FILL)

			local iconlist = vgui.Create("DPanel", scroll) //(note: this was a DIconLayout before, but since we already know the size of every icon, it's a lot faster to just use simple math to set the list height and icon locations, instead of all the performance-heavy size calculations used by DIconLayout)
			iconlist.Paint = function() end

			local old_OnChildAdded = scroll.OnChildAdded
			scroll.OnChildAdded = nil //don't dock the loading icon inside the scroll panel, just place it on top of it
			local iconlist_loading = vgui.Create("DPanel", scroll)
			iconlist_loading:Dock(FILL)
			iconlist_loading:SetZPos(10) //this needs to render above the iconlist
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


			--[[local filters_holder = window:Add("DPanel")
			filters_holder:DockPadding(8,8,8,8)
			filters_holder:SetWidth(100)
			filters_holder:Dock(LEFT)]]

			local filters = window:Add("DPanel")
			//filters:DockPadding(8,8,8,8)
			filters:DockPadding(24,24,24,24)
			filters:SetWidth(244)
			filters:Dock(LEFT)
			//filters:EnableVerticalScrollbar()
			//filters:Dock(FILL)

			function filters:Paint(w,h)
				//surface.SetDrawColor(255,255,255,255)
				//surface.DrawRect(0,0,w,h)
				TFThinLineBorder(0,0,w,h)
			end

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
				return drop.Combo
			end

			filters.class = AddDropdownFilter("Class", function(self)
				for _, v in ipairs (classes) do
					self:AddChoice(string.NiceName(v.longname), v.longname, v.longname == "(any)")
				end
			end, function() filters.equip_region:RebuildControls() end)

			filters.item_type = AddDropdownFilter("Item Type", function(self) 
				for _, v in ipairs ({"(any)", "weapon", "cosmetic", "taunt", "other"}) do
					self:AddChoice(string.NiceName(v), v, v == "(any)")
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
			filters.equip_region:GetParent():DockMargin(0,0,0,betweencategories)
			
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
				if filters.equip_region.IsRebuilding then return end

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
			TF2ItemBrowser_ImageQueue = {}
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
					for k, v in ipairs (TF2ItemBrowser_ImageQueue) do
						table.remove(TF2ItemBrowser_ImageQueue, k)
						if IsValid(v.pnl) then
							v.pnl.mat = Material(v.img .. ".vmt")
							if !TF2ItemBrowser_ImageQueuedBefore[v.img] then
								TF2ItemBrowser_ImageQueuedBefore[v.img] = true 
								break
							end
						end
					end
					//MsgN("#TF2ItemBrowser_ImageQueue = ", #TF2ItemBrowser_ImageQueue)
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

	end

	function PANEL:SetItemID(i)

		self.m_iItemID = i

		self.ImageToQueue = TF2Items.items[i].image_inventory

		//test
		self:SetTooltip(tostring(i) .. " " .. TF2Items.items[i].name)
		
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
				table.insert(TF2ItemBrowser_ImageQueue, {pnl = self, img = self.ImageToQueue})
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