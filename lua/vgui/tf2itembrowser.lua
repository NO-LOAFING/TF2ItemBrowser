CreateClientConVar("cl_tf2itembrowser_advbone", "0", true, false, "Use advanced bonemerge to attach items", 0, 1)
CreateClientConVar("cl_tf2itembrowser_hidedependencywarning", "0", true, false, "If 1, never show the \"missing addons\" popup when opening the browser", 0, 1)
	
local icon_red = Material("vgui/store/store_redteam.vmt")
local icon_blu = Material("vgui/store/store_blueteam.vmt")




local PANEL = {}
local tf = TF2ItemBrowser_Globals
if !tf then return end
DEFINE_BASECLASS("DFrame")

function PANEL:Init()

	local right_holder = vgui.Create("DPanel", self)
	right_holder.Paint = function() end
	self.Right = right_holder
	local right_scroll = tf.TFStyleVGUI("DScrollPanel", right_holder)
	right_holder:Dock(FILL)
	right_scroll:Dock(FILL)
	self.right_scroll = right_scroll

	local iconlist = vgui.Create("DPanel", right_scroll) //(note: this was a DIconLayout before, but since we already know the size of every icon, it's a lot faster to just use simple math to set the list height and icon locations, instead of all the performance-heavy size calculations used by DIconLayout)
	iconlist.Paint = function() end
	iconlist:Dock(FILL)
	self.iconlist = iconlist

	local old_OnChildAdded = right_scroll.OnChildAdded
	right_scroll.OnChildAdded = nil //don't dock the loading icon inside the scroll panel, just place it on top of it
	local iconlist_loading = vgui.Create("DPanel", right_scroll)
	iconlist_loading:Dock(FILL)
	//iconlist_loading:SetZPos(10) //this needs to render above the iconlist
	iconlist_loading:SetMouseInputEnabled(false)
	function iconlist_loading.Paint(_, w, h)
		local load_text, load_font, load_progress
		if TF2ItemBrowser_RequestCustomItems then
			load_text = "Retrieving custom items..."
			load_progress = 0
		elseif self.icons_to_add_showloader then
			load_text = tostring(self.icons_to_add_key-1) .. " / " .. tostring(self.icons_to_add_showloader)
			load_progress = (self.icons_to_add_key-1)/self.icons_to_add_showloader
		end
		if !load_text then return end
		surface.SetFont("TF2ItemBrowser_ItemDesc")
		local load_w, _ = surface.GetTextSize(load_text)
		load_w = math.max(load_w, 120)

		local w, h = right_scroll:GetSize()
		surface.SetDrawColor(tf.gui_colors.TanDarker.r, tf.gui_colors.TanDarker.g, tf.gui_colors.TanDarker.b, 192)
		surface.DrawRect(0,0,w,h)

		local icon_size = tf.cv_icon_size:GetInt()
		local mid_w, mid_h = (w-right_scroll.VBar:GetWide()-tf.item_icon_sizes[icon_size].gap_w)/2, h/2
		local x = mid_h-62.5
		tf.GrayDialogBorder(mid_w-((load_w+46)/2), x, load_w+46, 125)
		surface.SetMaterial(tf.spinner)
		x = x-6
		surface.DrawTexturedRect(mid_w-50, x, 100, 100)

		surface.SetDrawColor(tf.gui_colors.TanDark)
		x = x+100-11
		surface.DrawRect(mid_w-(load_w/2), x, load_w, 4)
		surface.SetDrawColor(tf.gui_colors.LightRed)
		surface.DrawRect(mid_w-(load_w/2), x, load_w*load_progress, 4)
		x = x+15
		draw.SimpleText(load_text, "TF2ItemBrowser_ItemDesc", mid_w, x, tf.gui_colors.LightRed, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	right_scroll.OnChildAdded = old_OnChildAdded


	local left_holder = vgui.Create("Panel", self)
	left_holder:DockMargin(0,0,8,0) //space for the DHorizonalDivider's control to fit in
	left_holder:Dock(LEFT)
	local left_scroll = tf.TFStyleVGUI("DScrollPanel", left_holder)
	left_scroll:Dock(FILL)

	local filters = vgui.Create("DPanel", left_scroll)
	filters:Dock(TOP)
	filters:DockPadding(16,16,16,16)
	self.filters = filters
	function filters:Paint(w,h)
		draw.RoundedBox(12, 0,0,w,h, tf.gui_colors._options)
	end

	local divider = vgui.Create("DHorizontalDivider", self)
	divider:Dock(FILL)
	divider:SetLeft(left_holder)
	divider:SetRight(right_holder)
	divider:SetDividerWidth(8)
	//divider:SetLeftMin(64)
	divider:SetRightMin(tf.popup_w) //make sure the right side is always wide enough to fit an item popup
	divider:SetLeftWidth(230)


	self:SetTitle("TF2 Item Browser")
	tf.AddTFStyleToVGUI(self)
	self:SetSizable(true)
	local p1, _, p2, _ = self:GetDockPadding()
	local p3, _, p4, _ = left_holder:GetDockPadding()
	self:SetMinWidth(p1 + p2 + p3 + p4 + right_scroll.VBar:GetWide() + right_scroll:GetWide())


	local text_holder = vgui.Create("Panel", filters)
	text_holder:Dock(TOP)
	text_holder:DockMargin(-8,-8,-8,tf.betweenitems)
	local text = vgui.Create("DLabel", text_holder)
	text:SetContentAlignment(7) //top left
	text:SetAutoStretchVertical(true)
	text:SetFont("TF2ItemBrowser_ItemName")
	text:SetColor(tf.gui_colors.TanLight)
	text:SetText((tf.GetPhrase("#chat_filterbutton") or "Filters") .. ":")
	text:Dock(FILL)
	text_holder:SetTall(text:GetTall())
	local text = vgui.Create("DLabel", text_holder)
	text:SetContentAlignment(9) //top right
	text:SetAutoStretchVertical(true)
	text:SetFont("TF2ItemBrowser_ItemName")
	text:SetColor(tf.gui_colors.TanDark)
	text:SetText("")
	text:Dock(FILL)
	self.ItemCountText = text

	local search = tf.TFStyleVGUI("DTextEntry", filters)
	search:Dock(TOP)
	search:DockMargin(0,0,0,tf.betweencategories)
	search:SetPlaceholderText("#spawnmenu.search")
	filters.search = search
	search:SetUpdateOnType(true)
	search.OnValueChange = function()
		timer.Create("TF2ItemBrowser_SearchDelay", 0.5, 1, function()
			if IsValid(self) then self:RebuildIconList() end
		end)
	end

	local function AddDropdownFilter(label, populatefunc, select_extras)
		local combo = tf.TFStyleVGUI("DComboBox", filters)
		local pnl = tf.AddTFLabelToVGUI(combo, label)
		pnl:Dock(TOP)
		pnl:DockMargin(0,0,0,tf.betweenitems)
		combo:SetSortItems(false)
		populatefunc(combo)
		function combo.OnSelect(_, index, value, data)
			if select_extras then select_extras() end
			self:RebuildIconList()
		end
		return combo
	end

	filters.class = AddDropdownFilter(tf.GetPhrase("#TF_Tag_Category_Class") or "Class", function(drop)
		for k, v in ipairs (tf.classes) do //add all classes in order
			drop:AddChoice(tf.GetPhrase(v.langstr) or string.NiceName(v.longname), k, k == 1)
			if k == 1 or k == 10 then drop:AddSpacer() end
		end
	end, function() 
		filters.equip_region:RebuildControls()
		filters.item_set:RebuildControls()
	end)

	filters.item_type = AddDropdownFilter(tf.GetPhrase("#TF_ImportFile_TypeLabel") or "Item Type", function(drop) 
		for k, v in ipairs ({
			{k = tf.str_any,								v = "(any)"}, 
			{k = tf.GetPhrase("#TF_SteamWorkshop_Tag_Weapon") or "Weapon",	v = "weapon"}, 
			{k = tf.GetPhrase("#LoadoutSlot_Misc") or "Cosmetic",		v = "cosmetic"}, 
			--[[{k = tf.GetPhrase("#TF_SteamWorkshop_Tag_Taunt") or "Taunt",	v = "taunt"},]] 
			{k = tf.GetPhrase("#AbuseReport_TypeOther") or "Other",		v = "other"}, //using this localization string for "Other" items is a stretch but it's the best we've got
		}) do
			drop:AddChoice(v.k, v.v, k == 1)
			if k == 1 then drop:AddSpacer() end
		end
	end)

	local equip_regions_populate = function(drop)
		local _, old_choice = drop:GetSelected()
		old_choice = old_choice or "(any)"
		drop.IsRebuilding = true
		drop:Clear()
		drop:AddChoice(tf.str_any, "(any)", old_choice == "(any)")
		for classid, class in ipairs (tf.classes) do //add class-based equip regions in class order
			//If we have a class selected, filter out equip regions for other classes
			local _, selected_classid = filters.class:GetSelected()
			if selected_classid == 1 or classid == 1 or selected_classid == classid then
				local added_spacer = false
				for k, v in ipairs (tf.TF2Items.equip_regions_list[classid]) do
					if !added_spacer then 
						drop:AddSpacer()
						added_spacer = true
					end
					drop:AddChoice(string.NiceName(v), v, old_choice == v)
				end
			end
		end
		//if we had a class-specific region selected, and then switched to a class that doesn't have it, revert to "(any)"
		local _, check = drop:GetSelected()
		if check == nil then drop:ChooseOptionID(1) end
		drop.IsRebuilding = nil
	end
	filters.equip_region = AddDropdownFilter(tf.GetPhrase("#TF_ImportFile_EquipRegionLabel") or "Equip Region", equip_regions_populate)
	filters.equip_region.RebuildControls = equip_regions_populate //make this func externally accessible so we can rebuild it when picking a new class

	local item_sets_populate = function(drop)
		local _, old_choice = drop:GetSelected()
		old_choice = old_choice or "(any)"
		drop.IsRebuilding = true
		drop:Clear()
		drop:AddChoice(tf.str_any, "(any)", old_choice == "(any)")
		local submenus = {}
		//If we have a class selected, only show sets containing items for that class
		local _, selected_classid = filters.class:GetSelected()
		local added_spacer = false
		for _, v in ipairs (tf.sets_ordered) do
			if selected_classid == 1 or tf.TF2Items.item_sets[v]._classes[selected_classid] then
				if !added_spacer then drop:AddSpacer() added_spacer = true end
				local k = tf.GetPhrase(tf.TF2Items.item_sets[v].name) or v
				local cat = tf.TF2Items.item_sets[v]._cat //item sets are further categorized by class because there's so many of them
				local id = drop:AddChoice(k, v, old_choice == v)
				submenus.sets = submenus.sets or {}
				submenus.sets[cat] = submenus.sets[cat] or {}
				table.insert(submenus.sets[cat], {name = k, id = id})
			end
		end
		added_spacer = false
		for _, v in ipairs (tf.collections_ordered) do
			if selected_classid == 1 or tf.TF2Items.item_collections[v]._classes[selected_classid] then
				if !added_spacer then drop:AddSpacer() added_spacer = true end
				local k = tf.GetPhrase(tf.TF2Items.item_collections[v].name) or v
				local id = drop:AddChoice(k, v, old_choice == v)
				submenus.collections = submenus.collections or {}
				table.insert(submenus.collections, {name = k, id = id})
			end
		end
		//Add custom dropdown with submenus, instead of dumping all the sets and collections into one huge list
		function drop:OpenMenu()
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
				local submenu = self.Menu:AddSubMenu(string.NiceName(string.lower(tf.GetPhrase("#Collections") or "COLLECTIONS")))
				for _, tab in ipairs (submenus.collections) do
					local opt = submenu:AddOption(tab.name, function() self:ChooseOption(tab.name, tab.id) end)
					if tab.id == sel then
						opt:SetChecked(true)
						submenu:ScrollToChild(opt)
					end
				end
			end

			local x, y = drop:LocalToScreen(0, drop:GetTall())
			drop.Menu:SetMinimumWidth(drop:GetWide())
			drop.Menu:Open(x, y, false, drop)
			drop:OnMenuOpened(drop.Menu)
		end
		//if we had a class-specific set selected, and then switched to a class that doesn't have it, revert to "(any)"
		local _, check = drop:GetSelected()
		if check == nil then drop:ChooseOptionID(1) end
		drop.IsRebuilding = nil
	end
	filters.item_set = AddDropdownFilter("Set/" .. (tf.GetPhrase("#TF_Tag_Category_Collection") or "Collection"), item_sets_populate) //no tf localization string for "Set" or "Item Set" or the like
	filters.item_set:GetParent():DockMargin(0,0,0,tf.betweencategories)
	filters.item_set.RebuildControls = item_sets_populate //make this func externally accessible so we can rebuild it when picking a new class

	local function AddIncludeExcludeFilter(label) //variant of checkboxes with both (+ (must include)) and (- (must exclude)) options
		local pnl = vgui.Create("DPanel", filters)
		pnl:SetTall(20)
		pnl.Button1 = tf.TFStyleVGUI("DCheckBox", pnl)
		pnl.Button1.OnChange = function(_, val) pnl.OnChange(val, pnl.Button1) end
		pnl.Button2 = tf.TFStyleVGUI("DCheckBox", pnl)
		pnl.Button2.OnChange = function(_, val) pnl.OnChange(val, pnl.Button2) end
		pnl.Button2.NegativeCheck = true //use different visuals
		pnl.Label = vgui.Create("DLabel", pnl)
		pnl.Label:SetText(label)
		pnl.Label:SetMouseInputEnabled(true)
		pnl.Label.DoClick = function()
			//cycle through all 3 states when label is clicked
			local v = pnl:GetValue()
			if v == 0 then pnl.Button1:SetValue(true)
			elseif v == 1 then pnl.Button2:SetValue(true)
			else pnl.Button2:SetValue(false) end
		end 
		pnl.Label:SetColor(tf.gui_colors.Yellow) //same color and font as TFStyleVGUI DCheckBoxLabel
		pnl.Label:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
		pnl.Paint = function() end
		function pnl:PerformLayout()
			self.Button1:SetSize(20, 20)
			self.Button1:SetPos(0, math.floor((self:GetTall() - self.Button1:GetTall()) / 2))

			self.Button2:SetSize(20, 20)
			self.Button2:SetPos(self.Button1:GetWide() + 2, math.floor((self:GetTall() - self.Button2:GetTall()) / 2))

			self.Label:SizeToContents()
			self.Label:SetPos(self.Button1:GetWide() + 2 + self.Button2:GetWide() + 6, math.floor((self:GetTall() - self.Label:GetTall()) / 2))
		end
		function pnl:GetValue()
			if self.Button1:GetChecked() then return 1
			elseif self.Button2:GetChecked() then return -1
			else return 0 end
		end
		function pnl.OnChange(val, button)
			//don't let include and exclude both be checked at once
			if val then
				if button == pnl.Button1 and pnl.Button2:GetChecked() then
					pnl.Button2:SetChecked(false)
				elseif button == pnl.Button2 and pnl.Button1:GetChecked() then
					pnl.Button1:SetChecked(false)
				end
			end
			self:RebuildIconList()
		end
		pnl:Dock(TOP)
		pnl:DockMargin(0,0,0,tf.betweenitems)
		return pnl
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
	filters.tm:DockMargin(0,0,0,tf.betweencategories)
	filters.tm.Button2:SetChecked(true)
	filters.custom = AddIncludeExcludeFilter("Custom items")

	local button = tf.TFStyleVGUI("DButton", filters.custom)
	//filters.custom:SetTall(button:GetTall())
	button:SetText(tf.GetPhrase("#TF_PublishedFiles_Add") or "Add")
	//button:SizeToContentsX(20)
	button:SizeToContentsX(10)
	button:Dock(RIGHT)
	button:DockMargin(0,0,0,0)
	button.DoClick = function()
		TF2ItemBrowser_OpenCustomItemEditor()
	end
	if !game.SinglePlayer() then
		local old_Think = button.Think
		function button:Think()
			if tf.PlayerCanEditCustomItems() then
				self:SetEnabled(true)
				tf.AddTFStyleTooltip(button, "")
			else
				self:SetEnabled(false)
				tf.AddTFStyleTooltip(button, "Custom item editing prohibited by server")
			end
			return old_Think(self)
		end
	end


	function iconlist.PerformLayout(_, w, h)
		//Rebuild the iconlist if resizing it changed the number of columns
		local icon_size = tf.cv_icon_size:GetInt()
		local columns, wide = 0, w
		while true do
			if columns > 0 then wide = wide - tf.item_icon_sizes[icon_size].gap_w end
			wide = wide - tf.item_icon_sizes[icon_size].w
			if wide >= 0 then
				columns = columns + 1
			else
				break
			end
		end
		if columns != iconlist.columns then
			self:RebuildIconList()
		end
	end
	//self:RebuildIconList() gets called automatically by the initial iconlist:PerformLayout() above


	local atticons_holder = vgui.Create("DPanel", right_holder)
	//atticons_holder:DockPadding(0,0,0,0)
	atticons_holder:Dock(BOTTOM)
	self.atticons_holder = atticons_holder
	function atticons_holder:Paint(w,h)
		tf.OutlinedGreyBox(-24,0,w+48,h) //no corners, just the top border
	end

	//This also has a scrollbar just in case some goofball wants to attach more than 10 items to one model
	local atticons = tf.TFStyleVGUI("DHorizontalScroller", atticons_holder)
	atticons:Dock(BOTTOM)
	self.atticons = atticons
	atticons.icons = {}
	atticons.Label = vgui.Create("DLabel", atticons_holder)
	atticons.Label:SetContentAlignment(4) //middle left
	atticons.Label:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
	atticons.Label:SetColor(tf.gui_colors.TanLight)
	atticons.Label:SetText("")
	atticons.Label:Dock(FILL)
	atticons.Label:DockMargin(0,4,0,0)
	function atticons:UpdateSize()
		local icon_size = tf.cv_icon_size:GetInt()
		atticons:SetHeight(tf.item_icon_sizes[icon_size].h)
		atticons:SetOverlap(-tf.item_icon_sizes[icon_size].gap_w)
		atticons_holder:SetTall(tf.item_icon_sizes[icon_size].h + 24)
	end
	atticons:UpdateSize()

	function atticons.AddItem(ent, data, forceopen)
		local item
		if !IsValid(atticons.icons[ent]) then
		item = vgui.Create("TF2ItemBrowser_Icon")
			atticons.icons[ent] = item
			item.entity = ent
			atticons:AddPanel(item)
		else item = atticons.icons[ent] end
		item:SetData(data)
		self:UpdateItemConflicts()
		
		if forceopen then
			atticons:ScrollToChild(item)
			item.OpenNextFrame = true
		end
	end

	local attopts = vgui.Create("DPanel", left_scroll)
	attopts:Dock(TOP)
	attopts:DockMargin(0,8,0,0)
	attopts:DockPadding(16,16,16,16)
	self.attopts = attopts
	function attopts:Paint(w,h)
		draw.RoundedBox(12, 0,0,w,h, tf.gui_colors._options)
	end

	local text = vgui.Create("DLabel", attopts)
	text:SetContentAlignment(7) //top left
	text:SetAutoStretchVertical(true)
	text:SetFont("TF2ItemBrowser_ItemName")
	text:SetColor(tf.gui_colors.TanLight)
	text:SetText(language.GetPhrase("spawnmenu.utilities.settings") .. ":")
	text:Dock(TOP)
	text:DockMargin(-8,-8,0,tf.betweenitems)

	local buttons = vgui.Create("Panel", attopts)
	buttons:Dock(TOP)
	buttons:DockMargin(0,0,0,tf.betweenitems)
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
	tf.AddTFButtonSounds(buttons.Button1)
	buttons.Button2 = vgui.Create("DButton", buttons)
	function buttons.Button2.DoClick() buttons:SetValue(true) end
	function buttons.Button2:Paint(w,h) ButtonPaint(self,w,h,icon_blu, true) end
	buttons.Button2:SetText("")
	tf.AddTFButtonSounds(buttons.Button2)
	function buttons:PerformLayout()
		local w,h = self:GetSize()
		self.Button1:SetSize(42, h)
		self.Button1:SetPos((w/2)-4-42, 0)

		self.Button2:SetSize(42, h)
		self.Button2:SetPos((w/2)+4, 0)
	end
	buttons.SetValue = function(_, val)
		buttons.Value = val
		local ent = self:GetEntity()
		if IsValid(ent) then
			local skintoset
			if ent:GetSkin() % 2 != 0 then
				if !val then skintoset = ent:GetSkin()-1 end //don't change the skin if ent's skin got desynced
			else
				if val then skintoset = ent:GetSkin()+1 end
			end
			if skintoset != nil then
				self:DoInput("attach_par_skin", skintoset)
			end

			//also update tf.EFFECT_JARATE team color
			local _, f = attopts.fx:GetSelected()
			self:DoInput("attach_par_fx", f)

			for ent, pnl in pairs (atticons.icons) do
				if !IsValid(pnl) or !IsValid(ent) then
					atticons.icons[ent] = nil 
				else
					if pnl.data.team != val then
						pnl.data.team = val
						self:DoInput("attach_item_modify", ent, pnl.data)
					end
				end
			end
		end
		if IsValid(self.SpawnPanel) then
			self.SpawnPanel.Refresh()
		end
	end
	buttons.Value = false
	attopts.team = buttons

	local drop = AddDropdownFilter(tf.GetPhrase("#TF_ImportPreview_EffectLabel") or "Effect", function(drop)
		drop:AddChoice(tf.str_none, tf.EFFECT_NONE, true)
		drop:AddChoice(tf.GetPhrase("#TF_ImportPreview_Effect1") or "Uber", tf.EFFECT_UBER)
		drop:AddChoice(tf.GetPhrase("#TF_ImportPreview_Effect2") or "Jarate", tf.EFFECT_JARATE)
		drop:AddChoice("Gold", tf.EFFECT_GOLD) //no localization strings for these two, sad
		drop:AddChoice("Ice", tf.EFFECT_ICE)   //^
	end)
	drop:GetParent():SetParent(attopts)
	drop:GetParent():Dock(TOP)
	attopts.fx = drop
	function drop.OnSelect(_, index, value, data)
		local ent = self:GetEntity()
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
				self:DoInput("attach_par_skin", skintoset)
			end
			
			self:DoInput("attach_par_fx", data)

			for ent, pnl in pairs (atticons.icons) do
				if !IsValid(pnl) or !IsValid(ent) then
					atticons.icons[ent] = nil 
				else
					if pnl.data.fx != data then
						pnl.data.fx = data
						self:DoInput("attach_item_modify", ent, pnl.data)
					end
				end
			end
		end
		if IsValid(self.SpawnPanel) then
			self.SpawnPanel.Refresh()
		end
	end

	local easybone_id, advbone_id
	local drop = AddDropdownFilter("Attach with", function(drop)
		local b = GetConVar("cl_tf2itembrowser_advbone"):GetBool()
		easybone_id = drop:AddChoice("Easy Bonemerge", "0", !b)
		advbone_id = drop:AddChoice("Adv. Bonemerge", "1", b)
	end)
	drop:GetParent():SetParent(attopts)
	drop:GetParent():Dock(TOP)
	function drop.OnSelect(_, index, value, data)
		LocalPlayer():ConCommand("cl_tf2itembrowser_advbone " .. data)
	end

	local check = tf.TFStyleVGUI("DCheckBoxLabel", attopts)
	check:SetText("Small icons")
	check:Dock(TOP)
	check:DockMargin(0,0,0,tf.betweencategories)
	check:SetChecked(tf.cv_icon_size:GetInt() == 1)
	check.OnChange = function(_, val)
		local data = 2
		if val then data = 1 end
		LocalPlayer():ConCommand("cl_tf2itembrowser_iconsize " .. data)
		timer.Simple(0, function()
			atticons:UpdateSize()
		end)
		self:RebuildIconList()
		//Reset all the item icons inside atticons, so that they're rebuilt at the new size
		atticons:Clear()
		net.Start("TF2ItemBrowser_AttachedItems_GetFromSv", true)
			net.WriteEntity(self:GetEntity())
		net.SendToServer()
	end

	local deselect_holder = vgui.Create("Panel", attopts)
	deselect_holder:Dock(TOP)
	self.deselect_holder = deselect_holder

	local button = tf.TFStyleVGUI("DButton", deselect_holder)
	button:SetText("Deselect Model")
	button:Dock(BOTTOM)
	button:DockMargin(0,-button:GetTall(),0,0)
	button:SetVisible(false)
	button.DoClick = function()
		self:SetEntity(NULL)
	end

	local text = vgui.Create("DLabel", deselect_holder)
	text:SetWrap(true)
	text:SetAutoStretchVertical(true)
	text:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
	text:SetColor(tf.gui_colors.TanLight)
	text:SetText("Right-click a model in the context menu to select it and attach items.")
	text:Dock(BOTTOM)
	text:InvalidateLayout()

	//This spot is occupied by either the deselect button or the text explaining how to select a model, with which one is visible
	//changing depending on if a model is selected. It looks ugly if the height of the panel changes on select/deselect, so instead
	//make the space that they share take up the height of whichever item is taller, regardless of visiblity.
	function deselect_holder.PerformLayout(_, w, h)
		button:InvalidateLayout()
		text:InvalidateLayout()
		local _h = math.max(button:GetTall(), text:GetTall())
		if h != _h then deselect_holder:SetTall(_h) return end

		local valid = IsValid(self:GetEntity())
		button:SetVisible(valid)
		//if valid then text:SetText("Deselect " .. self:GetEntity():GetModel()) end
		//text:SetVisible(!valid) //this makes the text autostretch stop working; just make it transparent instead
		if !valid then
			text:SetColor(tf.gui_colors.TanLight)
		else
			text:SetColor(color_transparent)
		end
		attopts:InvalidateLayout(true)
		attopts:SizeToChildren(false,true)
	end

	//if one bonemerge tool is uninstalled, force the selected tool to the one remaining. 
	//if both are uninstalled, blank it out, and hide the text explaining how to select ents for attachment.
	if !tf.GetDependency("advbone") and !tf.GetDependency("easybone") then
		deselect_holder:SetVisible(false)
		drop:SetEnabled(false)
		drop:SetText("")
	elseif !tf.GetDependency("advbone") then
		drop:SetEnabled(false)
		drop:ChooseOptionID(easybone_id)
	elseif !tf.GetDependency("easybone") then
		drop:SetEnabled(false)
		drop:ChooseOptionID(advbone_id)
	end


	//Dependency warning message
	if !GetConVar("cl_tf2itembrowser_hidedependencywarning"):GetBool() and !TF2ItemBrowser_DoneDependencyWarning then
		TF2ItemBrowser_DoneDependencyWarning = true //we only need to show this once per session

		local strs = {}
		if !tf.GetDependency("advbone") then
			if tf.GetDependency("animprop") and tf.GetDependency("easybone") and tf.GetDependency("pe+") then
				table.insert(strs, "\"Advanced Bonemerge Tool\" addon not found. Unusual effects won't be adjustable, and may not attach to items correctly. You also won't be able to animate items like the parachute or jetpack if they're attached to a model.")
			elseif tf.GetDependency("animprop") and tf.GetDependency("easybone") then
				table.insert(strs, "\"Advanced Bonemerge Tool\" addon not found. You won't be able to animate items like the parachute or jetpack if they're attached to a model.")
			elseif tf.GetDependency("pe+") then
				table.insert(strs, "\"Advanced Bonemerge Tool\" addon not found. Unusual effects won't be adjustable, and may not attach to items correctly.")
			end
			if !tf.GetDependency("easybone") then
				table.insert(strs, "\"Advanced Bonemerge Tool\" and \"Easy Bonemerge Tool\" addons both not found. You won't be able to attach items to models.")
			end
		end
		if !tf.GetDependency("hatpainter") then
			table.insert(strs, "\"Hat Painter & Crit Glow Tools\" addon not found. You won't be able to add paint, crit glow, or jarate effects.")
		end
		if !tf.GetDependency("pe+") then
			table.insert(strs, "\"Particle Effects+\" addon not found. You won't be able to add unusual effects or other particle effects.")
		end
		if !tf.GetDependency("wp") then
			table.insert(strs, "\"TF2 Warpaint Tool\" addon not found. You won't be able to apply war paints.")
		end
		if !tf.GetDependency("animprop") then
			table.insert(strs, "\"Animated Props\" addon not found. You won't be able to animate items like the parachute or jetpack.") //this is, like, four items. is this still worth the warning?
		end

		if #strs > 0 then
			local pnl = tf.AddTFPopupOverlay(self, "Missing addons", function(pnl)
				local text = vgui.Create("DLabel", pnl)
				text:SetWrap(true)
				text:SetAutoStretchVertical(true)
				text:SetFont("TF2ItemBrowser_ItemDesc")
				text:SetColor(tf.gui_colors.TanLight)
				text:SetText("")
				for _, str in ipairs (strs) do
					if text:GetText() != "" then text:SetText(text:GetText() .. "\n\n") end
					text:SetText(text:GetText() .. str)
				end
				text:SetText(text:GetText() .. "\n\nYou'll still be able to use the TF2 Item Browser, but these features will be disabled. To subscribe to missing addons, check out the Steam Workshop page!")
				text:Dock(TOP)
				text:DockMargin(0,tf.betweencategories*1.5,0,0)

				local check = tf.TFStyleVGUI("DCheckBoxLabel", pnl)
				check:SetText(tf.GetPhrase("#TF_Competitive_Welcome_DontShow") or "Don't show this again")
				check:SetFont("TF2ItemBrowser_ItemDesc")
				check:Dock(TOP)
				check:DockMargin(70,tf.betweencategories*1.5,0,-tf.betweencategories*1)
				check:SetChecked(tf.cv_icon_size:GetInt() == 1)
				check.OnChange = function(_, val)
					local data = 0
					if val then data = 1 end
					LocalPlayer():ConCommand("cl_tf2itembrowser_hidedependencywarning" .. data)
				end
			end, 
			string.upper(tf.GetPhrase("#TF_OK") or "OK"), function(pnl)
				pnl:Remove()
			end,
			"#problems.open_on_workshop", function(pnl)
				gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=3054174781") //TODO: placeholder url, update this to the correct workshop url once uploaded
			end)
			timer.Simple(0, function() surface.PlaySound("ui/hint.wav") end) //wait until next frame to ensure the sound doesn't get cut off
		end
	end


	filters:InvalidateLayout(true)
	filters:SizeToChildren(false,true)
	deselect_holder:InvalidateLayout(true)
	attopts:InvalidateLayout(true)
	attopts:SizeToChildren(false,true)
	self.DoPostInit = true

	self.ImageQueue = {}
	self.IconRenderQueue = {}

end

//this one is global so it carries over between windows
TF2ItemBrowser_ImageQueuedBefore = TF2ItemBrowser_ImageQueuedBefore or {}
local iconsperframe = 100

function PANEL:RebuildIconList()

	if TF2ItemBrowser_RequestCustomItems or self.filters.equip_region.IsRebuilding or self.filters.item_set.IsRebuilding then return end

	self.iconlist.icons = {}
	self.icons_to_add = {}
	self.icons_to_add_key = 1
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
		//other uncategorized slots are "action" and "utility", along with slotless items like crates
	}
	local function DoIncludeExcludeFilter(f, criteria)
		return (f == 1 and !criteria) or (f == -1 and criteria)
	end
	local f = self.filters.search:GetText()
	if f then
		if f == "" then
			f = nil
		else
			f = string.Explode(" ", f:lower()) //allow searching with multiple search terms
		end
	end

	//required local function copied from https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/extensions/table.lua#L539
	local function getKeys( tbl ) 
		local keys, i = {}, 0

		for k in pairs( tbl ) do
			i = i + 1
			keys[ i ] = k
		end

		return keys
	end
	//modified version of SortedPairs that handles tables with mixed number and string keys;
	//instead of causing errors, strings are sorted after numbers
	local function SortedPairsMixed(pTable, Desc)

		local keys = getKeys( pTable )

		--[[if ( Desc ) then
			table.sort( keys, function( a, b )
				return a > b
			end )
		else]]
			table.sort( keys, function( a, b )
				if type(a) != type(b) then
					return isnumber(a)
				else
					return a < b
				end
			end )
		//end

		local i, key = 1, nil
		return function()
			key, i = keys[ i ], i + 1
			return key, pTable[ key ]
		end

	end

	local icons_to_add_by_id = {}
	for k, v in SortedPairsMixed (tf.TF2Items.items) do
		//this filter is on by default and catches >75% of items, so check this first
		if DoIncludeExcludeFilter(self.filters.tm:GetValue(), v._tm) then continue end

		if f then
			if !v._searchstr then
				//Search by display name, internal name, item type, set/collection, and more
				local str = v.name
				if v.item_name then
					str = str .. " " .. (tf.GetPhrase(v.item_name) or v.item_name)
				end
				if v.item_type_name then
					str = str .. " " .. (tf.GetPhrase(v.item_type_name) or "")
				end
				if v.item_description then
					//this can add irrelevant nonsense sometimes, but can also catch associated words that aren't in any other text. is this worth it?
					str = str .. " " .. (tf.GetPhrase(v.item_description) or "")
				end
				if v._item_set then
					str = str .. " " .. (tf.GetPhrase(tf.TF2Items.item_sets[v._item_set].name) or v._item_set)
				end
				if v._item_collection then
					str = str .. " " .. (tf.GetPhrase(tf.TF2Items.item_collections[v._item_collection].name) or v._item_collection)
				end
				if v._rarity then
					//include the full "(rarity) Grade (item)" string, so that searching for "elite grade" or similar will work, 
					//instead of only just "elite". there's also a localization string available for just the word "grade", but 
					//we use this one instead just in case they're translated differently in some languages.
					local rarity = tf.GetPhrase("#TFUI_InvTooltip_RarityNoWear")
					rarity = string.Replace(rarity, "%s1", tf.GetPhrase("#" .. tf.TF2Items.rarities[v._rarity].loc_key) or "")
					rarity = string.Replace(rarity, "%s2", "")
					rarity = string.Replace(rarity, "%s3", "")
					str = str .. " " .. rarity
				end
				//Add all model paths to the search string so we can search those too
				local mdls = {}
				for class, slot in pairs (v.used_by_classes) do
					str = str .. " " .. class
					for _, mdl in pairs (tf.GetItemModelVisuals({id = k, class = tf.class_longname_to_id[class], style = 0}).models) do
						if !istable(mdl) then //the only model subtables are attached_models and attached_models_festive, which don't contain anything useful for searches, so skip those
							mdls[mdl] = true
							//mdls[string.Replace(mdl, class, "")] = true //don't include class names in model paths because that clutters up searches for class names with irrelevant multi-class items; this still doesn't work very well because of class-specific equip regions, some internal names, and class-specific model paths with "demo" instead of "demoman", so give up and let players search for class by typing the name just like they can with equip regions
						end
					end
					//shotgun has wacky class-based item slots stored in these values
					if !isnumber(slot) and slot != v.item_slot and slot != v.anim_slot then
						str = str .. " " .. slot
					end
				end
				for mdl, _ in pairs (mdls) do
					str = str .. " " .. string.StripExtension(string.GetFileFromFilename(mdl))
				end
				//Add item slots, so players can search for "heavy primary" and so on
				if v.item_slot then
					str = str .. " " .. v.item_slot
				end
				//Add equip regions, so players can search something like "beard" and it works intuitively
				if v.equip_regions then
					for e, _ in pairs (v.equip_regions) do
						str = str .. " " .. e
					end
				end
				//Add styles, such as searching for items that can be "australium"
				if v.visuals and v.visuals.styles and table.Count(v.visuals.styles) > 1 then
					for style_id, _ in pairs (v.visuals.styles) do
						str = str .. " " .. tf.GetItemStyleName(k, style_id)
					end
				end
				v._searchstr = str:lower()
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

		if self.filters.class:GetSelectedID() != 1 then
			local _, f = self.filters.class:GetSelected()
			if !v.used_by_classes[tf.classes[f].longname] then continue end
		end

		if self.filters.item_type:GetSelectedID() != 1 then
			local _, f = self.filters.item_type:GetSelected()
			if (f == "other" and v.item_slot and item_slot_types[v.item_slot]) 
			or (f != "other" and (!v.item_slot or item_slot_types[v.item_slot] != f)) then continue end
		end

		if self.filters.equip_region:GetSelectedID() != 1 then
			local _, f = self.filters.equip_region:GetSelected()
			if !v.equip_regions or !v.equip_regions[f] then continue end
		end

		if self.filters.item_set:GetSelectedID() != 1 then
			local _, f = self.filters.item_set:GetSelected()
			if v._item_set != f and v._item_collection != f then continue end
		end

		if DoIncludeExcludeFilter(self.filters.conflicting:GetValue(), self:GetItemHasConflict(k))
		or DoIncludeExcludeFilter(self.filters.multi_class:GetValue(), table.Count(v.used_by_classes) > 1)
		or DoIncludeExcludeFilter(self.filters.holiday:GetValue(), v.holiday_restriction)
		or DoIncludeExcludeFilter(self.filters.paint:GetValue(), v.capabilities and v.capabilities.paintable == 1)
		or DoIncludeExcludeFilter(self.filters.warpaint:GetValue(), v._paintkit and (!tf.GetDependency("wp") or WP.Weapons.IsSupported(v.model_player)))
		or DoIncludeExcludeFilter(self.filters.custom:GetValue(), isstring(k)) //custom items use id strings, while normal items use id numbers
		then continue end

		icons_to_add_by_id[k] = table.insert(self.icons_to_add, k)
	end
	//Try to scroll back to an item that was previously visible on-screen, so that using something like the "conflicts with equipped"
	//filter maintains continuity between updates instead of always scrolling back to the top.
	local new_scroll_id
	local _, r_a = self.right_scroll:LocalToScreen(0,0)
	local _, r_b = self.right_scroll:LocalToScreen(0, self.right_scroll:GetTall())
	for _, icon in ipairs (self.iconlist:GetChildren()) do
		local _, a = icon:LocalToScreen(0,0)
		local _, b = icon:LocalToScreen(0, icon:GetTall())
		if a <= r_b and b >= r_a then //if top of icon is above bottom of scrollpanel, and bottom of icon is below top of scrollpanel
			local id = icon.data
			if istable(id) then id = id.id end
			if icon.random or icons_to_add_by_id[id] then
				new_scroll_id = id
				break
			end
		end
	end
	if IsValid(self.SpawnPanel) and self.SpawnPanel.Owner:GetParent() == self.iconlist then
		//If an icon is currently selected, just use that one (do this after the icon-on-screen check, 
		//so that if the random button is currently selected, it can override new_scroll_id to nil)
		local icon = self.SpawnPanel.Owner
		local id = icon.data
		if istable(id) then id = id.id end
		if icon.random or icons_to_add_by_id[id] then
			new_scroll_id = id
		end
		//Also, reopen the spawnpanel to the same settings when the icon is recreated
		self.icon_to_reselect = {
			id = id,
			data = icon.data,
			random = icon.random,
		}
	else
		self.icon_to_reselect = nil
	end
	//Check if we want to display a loading progress bar on top of the iconlist
	if #self.icons_to_add >= 4000 then
		//If there's enough icons to add that creating them will cause a substantial FPS drop
		//(i.e. filters are set to allow tournament medals), then display the loading bar 
		//until EVERY icon is added, so that the player can tell what's causing the lag.
		self.icons_to_add_showloader = #self.icons_to_add
	elseif new_scroll_id and icons_to_add_by_id[new_scroll_id] > iconsperframe then
		//Otherwise, if we're scrolling down to an icon that won't be added right away, 
		//then display the loading bar temporarily until that icon is added, 
		//so that the player doesn't just see a blank window for a moment.
		self.icons_to_add_showloader = icons_to_add_by_id[new_scroll_id]
	end
	//Clear the icon list, and resize it to the height of the new list
	self.iconlist:Clear()
	local icon_size = tf.cv_icon_size:GetInt()
	local columns, wide = 0, self.iconlist:GetWide()
	while true do
		if columns > 0 then wide = wide - tf.item_icon_sizes[icon_size].gap_w end
		wide = wide - tf.item_icon_sizes[icon_size].w
		if wide >= 0 then
			columns = columns + 1
		else
			break
		end
	end
	self.iconlist.columns = columns
	local rows = math.floor((#self.icons_to_add)/columns)+1
	self.iconlist:SetHeight((rows*tf.item_icon_sizes[icon_size].h) + ((rows-1)*tf.item_icon_sizes[icon_size].gap_h))
	//Update scrollbar; set the new scroll height, and prevent scrolling or clicking on list items if there's a loading bar
	self.right_scroll:InvalidateLayout(true) //make sure SetScroll below doesn't clamp to the previous height of the iconlist
	if new_scroll_id then
		//MsgN("new scroll id = ", (tf.TF2Items.items[new_scroll_id] or {}).name)
		local row = math.floor(icons_to_add_by_id[new_scroll_id]/self.iconlist.columns)
		local icon_size = tf.cv_icon_size:GetInt()
		//scroll down until the previous top item appears at the top appears at the top of the list
		self.right_scroll.VBar:SetScroll( row*(tf.item_icon_sizes[icon_size].h+tf.item_icon_sizes[icon_size].gap_h) )
		////alt: only scroll down far enough to make the previous top item appear at the bottom of the list
		//self.right_scroll.VBar:SetScroll( (row+1)*(tf.item_icon_sizes[icon_size].h+tf.item_icon_sizes[icon_size].gap_h) - self.right_scroll:GetTall() )
	else
		self.right_scroll.VBar:SetScroll(0)
	end
	self.right_scroll:SetMouseInputEnabled(self.icons_to_add_showloader == nil)
	//if #self.icons_to_add != 1 thens
		//self.ItemCountText:SetText("(" .. tostring(#self.icons_to_add) .. " items)")
		self.ItemCountText:SetText("(" .. string.Replace(tf.GetPhrase("#Store_CartItems") or "%s1 Items", "%s1", tostring(#self.icons_to_add)) .. ")")
	//else
	//	self.ItemCountText:SetText("(" .. tostring(#self.icons_to_add) .. " item)")
	//end

end

function PANEL:Think(...)

	if TF2ItemBrowser_RequestCustomItems then
		net.Start("TF2ItemBrowser_CustomItems_GetFromSv", true)
		net.SendToServer()
	end
	if self.icons_to_add and self.icons_to_add_key then
		//Add random item button to start of iconlist; do this here and not in RebuildIconList so console doesn't complain about adding vgui child during layout
		if self.icons_to_add_key == 1 --[[and #self.icons_to_add > 0]] then //gotta add this to empty lists as well, so that it doesn't awkwardly disappear when updating filters during use
			local item = self.iconlist:Add("TF2ItemBrowser_Icon")
			if self.icon_to_reselect and self.icon_to_reselect.random then
				item:SetupRandomItemIcon(self.icon_to_reselect.random)
				item:CreateSpawnPanel()
				self.icon_to_reselect = nil
			else
				item:SetupRandomItemIcon()
			end
		end
		local icon_size = tf.cv_icon_size:GetInt()
		for k = self.icons_to_add_key, self.icons_to_add_key + iconsperframe - 1 do
			local v = self.icons_to_add[k]
			if self.icons_to_add_showloader and (self.icons_to_add_showloader <= k or !v) then
				//Allow the list to be scrolled and clicked on now that it's done loading
				self.icons_to_add_showloader = nil
				self.right_scroll:SetMouseInputEnabled(true)
			end
			if v then
				local item = self.iconlist:Add("TF2ItemBrowser_Icon")
				local col = k%self.iconlist.columns
				local row = math.floor(k/self.iconlist.columns)
				item:SetPos(col*(tf.item_icon_sizes[icon_size].w+tf.item_icon_sizes[icon_size].gap_w), row*(tf.item_icon_sizes[icon_size].h+tf.item_icon_sizes[icon_size].gap_h))
				item.data = v //this will be populated with the default data table for this item once the icon renders
				self.iconlist.icons[v] = item
				item.item_conflict = self:GetItemHasConflict(v)
				if self.icon_to_reselect and self.icon_to_reselect.id == v then
					item:SetData(self.icon_to_reselect.data)
					item:CreateSpawnPanel()
					self.icon_to_reselect = nil
				end
			else
				//We've gone through the whole table, so we're done here
				//Don't remove self.icons_to_add, this is also used by the random item button
				self.icons_to_add_key = nil
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
			v.pnl.mat = Material(v.img, "smooth")
			if !TF2ItemBrowser_ImageQueuedBefore[v.img] then
				TF2ItemBrowser_ImageQueuedBefore[v.img] = true 
				break //only load one material per frame to prevent bad perf
			end
		end
	end
	for k, v in ipairs (self.IconRenderQueue) do
		if IsValid(v.pnl) then
			local _, y = self.Right:ScreenToLocal(v.pnl:LocalToScreen(0,0))
			if y > self.Right:GetTall() or (y+v.pnl:GetTall()) < 0 then
				//if the icon is offscreen, unqueue it and move on to the next one, without holding up the queue
				table.remove(self.IconRenderQueue, k)
				v.pnl.IconRenderToQueue = true //requeue it if the icon moves back onscreen
				continue
			end
		end
		if v.func() then //func will return false if it's not ready to render yet (i.e. waiting for paintkit texture to generate)
			table.remove(self.IconRenderQueue, k)
		end
		break //only render one icon per frame to prevent bad perf
	end
	//if our selected entity is deleted, then update the attached item list
	if self.atticons_holder and self.atticons_holder:IsVisible() and !IsValid(self:GetEntity()) then
		self:SetEntity(NULL)
	end
	//Make sure to do this after everything is done building (don't just use timers), or it can cause issues where the left scroll area is the wrong size upon opening the browser
	if self.DoPostInit then
		self.filters:InvalidateLayout(true)
		self.filters:SizeToChildren(false,true)
		self.deselect_holder:InvalidateLayout(true)
		self.attopts:InvalidateLayout(true)
		self.attopts:SizeToChildren(false,true)
		self.DoPostInit = nil
	end
	return BaseClass.Think(self, ...)

end

AccessorFunc(PANEL, "m_Entity", "Entity")

function PANEL:SetEntity(ent)

	if !tf.GetDependency("advbone") and !tf.GetDependency("easybone") then ent = NULL end //just in case
	self.m_Entity = ent
	self.atticons:Clear()
	if IsValid(self.SpawnPanel) then self.SpawnPanel:Remove() end

	if IsValid(ent) then
		self.atticons_holder:SetVisible(true)
		self.Right:InvalidateLayout()
		self.deselect_holder:InvalidateLayout()

		local mdl = string.StripExtension(string.GetFileFromFilename(ent:GetModel()))
		//Try to figure out what class the model is, and set the class filter to match
		for k, v in ipairs (tf.classes) do
			if k == 1 or k == 11 then continue end
			if string.find(mdl, v.shortname, 1, true) then
				self.filters.class:ChooseOptionID(k)
				break
			end
		end
		local text = string.lower(tf.GetPhrase("#CurrentlyEquipped") or "CURRENTLY EQUIPPED:")
		text = string.upper(text[1]) .. string.sub(text, 2)
		self.atticons.Label:SetText(text .. " (" .. string.NiceName(mdl) .. ")")

		self.attopts.team:SetValue(ent:GetSkin() % 2 != 0)

		//Try to figure out if the selected ent has fx applied
		self.attopts.fx.IsUpdating = true
		local is_uber_skin = (math.ceil((ent:GetSkin()+1)/2) % 2) == 0
		if is_uber_skin then
			self.attopts.fx:ChooseOptionID(tf.EFFECT_UBER+1)
		elseif IsValid(ent.ProxyentCritGlow) and ent.ProxyentCritGlow:GetSparksJarate() then
			self.attopts.fx:ChooseOptionID(tf.EFFECT_JARATE+1)
		elseif ent:GetMaterial() == "models/player/shared/gold_player" then
			self.attopts.fx:ChooseOptionID(tf.EFFECT_GOLD+1)
		elseif ent:GetMaterial() == "models/player/shared/ice_player" then
			self.attopts.fx:ChooseOptionID(tf.EFFECT_ICE+1)
		else
			self.attopts.fx:ChooseOptionID(tf.EFFECT_NONE+1)
		end
		self.attopts.fx.IsUpdating = nil

		net.Start("TF2ItemBrowser_AttachedItems_GetFromSv", true)
			net.WriteEntity(ent)
		net.SendToServer()
	else
		self.atticons_holder:SetVisible(false)
		self.Right:InvalidateLayout()
		self.deselect_holder:InvalidateLayout()

		//Reset some options that were specific to the selected ent
		self.filters.class:ChooseOptionID(1)
		self.attopts.team:SetValue(false)
		self.attopts.fx.IsUpdating = true
		self.attopts.fx:ChooseOptionID(1)
		self.attopts.fx.IsUpdating = nil
	end
	self:UpdateItemConflicts() //this also gets called by other things like atticons.AddItem(), but this one covers edge cases, like switching directly from an ent with attached items to an ent without attached items

end

function PANEL:UpdateItemConflicts()

	//If there's no entity for items to be equipped to, then there's no item conflicts
	if !IsValid(self:GetEntity()) then
		self.EquipRegionConflicts = nil
		return
	end
	//Get all equip regions occupied by equipped items, and track how many items are occupying each region
	local regions = {}
	for k, v in pairs (self.atticons.icons) do
		local i = tf.TF2Items.items[v.data.id] or {}
		if i.equip_regions then
			for k2, v2 in pairs (i.equip_regions) do
				regions[k2] = (regions[k2] or 0) + 1
				//If this region has an equip_conflicts table, add all of those too 
				//(i.e. if a whole_head item is equipped, occupy the hat region too)
				if tf.TF2Items.equip_conflicts[k2] then
					for k3, v3 in pairs (tf.TF2Items.equip_conflicts[k2]) do
						regions[k3] = (regions[k3] or 0) + 1
					end
				end
				//If this region is inside another region's equip_conflicts table, add that region too
				//(i.e. if a hat item is equipped, occupy the whole_head region too)
				for k3, v3 in pairs (tf.TF2Items.equip_conflicts) do
					for k4, v4 in pairs (v3) do
						if i.equip_regions[k4] then
							regions[k3] = (regions[k3] or 0) + 1
						end
					end
				end
			end
		end
		//Also treat loadout slots as equip regions, so that the random item button can be used to create random loadouts
		local slot = i.item_slot
		if slot and slot != "head" and slot != "misc" then //obviously don't do this for cosmetic items
			//wacky per-class item slot, used by shotgun and base jumper;
			local class_slot = i.used_by_classes[tf.classes[v.data.class].longname]
			if class_slot and !isnumber(class_slot) then slot = class_slot end
			--[[//spy is the only class whose actual internal loadout slots don't match what they appear to be in-game.
			//for our purposes, move revolvers from secondary to primary, and sappers from building to secondary,
			//so that we can do silly randomizer loadouts with this that make intuitive sense.
			if v.data.class == 10 then //spy
				if slot == "secondary" then
					slot = "primary"
				elseif slot == "building" then
					slot = "secondary"
				end
			end]] //ehh, this isn't worth it, this will just cause confusion with listed item slots and custom items
			regions["_"..slot] = (regions["_"..slot] or 0) + 1
		end
	end
	self.EquipRegionConflicts = regions
	//Update all existing icons
	for k, v in pairs (self.atticons.icons) do
		local conflicting = self:GetItemHasConflict(v, true)
		if v.item_conflict != conflicting then
			v.item_conflict = conflicting
			v.itemdesc = v:UpdateItemDescription()
		end
	end
	if self.filters and self.filters.conflicting and self.filters.conflicting:GetValue() != 0 then //can be nil if the window is being closed
		//If we have a filter set to hide conflicting/non-conflicting icons, then rebuild the icon list instead
		self:RebuildIconList()
	elseif self.iconlist and self.iconlist.icons then //can be nil if the window is being closed
		for k, v in pairs (self.iconlist.icons) do
			local conflicting = self:GetItemHasConflict(v)
			if v.item_conflict != conflicting then
				v.item_conflict = conflicting
				//don't update the description if it hasn't built its data table yet
				if istable(v.data) then v.itemdesc = v:UpdateItemDescription() end
			end
		end
	end

end

function PANEL:GetItemHasConflict(item, is_equipped)

	if !self.EquipRegionConflicts then return end
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

	local conflicting
	local i = tf.TF2Items.items[id] or {}
	if i.equip_regions then
		for k, v in pairs (i.equip_regions) do
			//For equipped items, if a region is occupied by *multiple* equipped items, then display a conflict.
			//For unequipped items, if a region is occupied by *any* equipped items, then display a conflict.
			if self.EquipRegionConflicts[k] and (!is_equipped or self.EquipRegionConflicts[k] > 1) then
				conflicting = true
				break
			end
		end
	end
	if !conflicting then
		//Also treat loadout slots as equip regions, so that the random item button can be used to create random loadouts
		local slot = i.item_slot
		if slot and slot != "head" and slot != "misc" then //obviously don't do this for cosmetic items
			//if we're calling this function for an item id number instead of a panel, then we'll have to make an item data table
			local data
			if ispanel(item) then data = item.data end
			if !data or !istable(data) then
				data = tf.GetDefaultItemDataTable(id)
				//tf.SanitizeItemDataTable(data) //this doesn't matter here
			end
			//wacky per-class item slot, used by shotgun and base jumper
			local class_slot = i.used_by_classes[tf.classes[data.class].longname]
			if class_slot and !isnumber(class_slot) then slot = class_slot end
			--[[//spy is the only class whose actual internal loadout slots don't match what they appear to be in-game.
			//for our purposes, move revolvers from secondary to primary, and sappers from building to secondary,
			//so that we can do silly randomizer loadouts with this that make intuitive sense.
			if data.class == 10 then //spy
				if slot == "secondary" then
					slot = "primary"
				elseif slot == "building" then
					slot = "secondary"
				end
			end]] //ehh, this isn't worth it, this will just cause confusion with listed item slots and custom items
			if self.EquipRegionConflicts["_"..slot] and (!is_equipped or self.EquipRegionConflicts["_"..slot] > 1) then
				conflicting = true
			end
		end
	end
	return conflicting
end

function PANEL:DoInput(input, ...)

	net.Start("TF2ItemBrowser_Input_SendToSv", true) //use unreliable channel; if network is clogged, better to not spawn one prop than to crash the server
	
		local args = {...}

		net.WriteUInt(tf.BrowserInputs[input], tf.BrowserInputs_bits)

		if string.StartsWith(input, "attach_") then
			net.WriteEntity(self:GetEntity())
		end

		if input == "item_spawn" or input == "attach_item_spawn" then

			tf.WriteItemDataTable(args[1]) //item data table
			net.WriteBool(GetConVar("cl_tf2itembrowser_advbone"):GetBool())
			if input == "attach_item_spawn" then net.WriteBool(args[2]) end //open spawn panel upon received?

		elseif input == "attach_item_modify" then

			tf.WriteItemDataTable(args[2]) //item data table
			net.WriteBool(GetConVar("cl_tf2itembrowser_advbone"):GetBool())
			net.WriteEntity(args[1]) //item ent to modify

		elseif input == "attach_item_remove" then
		
			net.WriteEntity(args[1]) //item ent to remove

		elseif input == "attach_par_skin" then

			net.WriteUInt(args[1], 8) //skin id

		elseif input == "attach_par_fx" then

			net.WriteUInt(args[1], 3) //tf.EFFECT_ enum

		end

	net.SendToServer()

end

vgui.Register("TF2ItemBrowser", PANEL, "DFrame")