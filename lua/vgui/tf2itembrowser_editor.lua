//for custom item editor's backpack icon preview; the version used by item icons scales with the currently selected icon size, which we don't want here
local BackpackItemBorderUnscaled = GWEN.CreateTextureBorder(0, 0, 256, 128, 24, 24, 24, 24, Material("vgui/backpack_rect_vc.vmt"))
local BackpackItemMouseOverBorderUnscaled = GWEN.CreateTextureBorder(0, 0, 256, 128, 24, 24, 24, 24, Material("vgui/backpack_rect_mouseover_vc.vmt"))

local rtmat = CreateMaterial("TF2ItemBrowser_EditorIconRT", "UnlitGeneric", {
	["$basetexture"] = "color/white",
	["$translucent"] = "1",
	["$vertexcolor"] = "1"
})




local PANEL = {}
local tf = TF2ItemBrowser_Globals
DEFINE_BASECLASS("DFrame")

function PANEL:OpenEditor(id)

	local editor = self
	editor:SetTitle("Custom Item Editor")
	tf.AddTFStyleToVGUI(editor)
	editor:SetSizable(true)
	editor.controls = {}
	if !game.SinglePlayer() then
		function editor:Think(...)
			if !tf.PlayerCanEditCustomItems() then
				editor:Close()
			end
			return BaseClass.Think(self, ...)
		end
	end


	//Dock save/delete/close buttons to bottom of panel
	local button_holder = vgui.Create("Panel", editor)
	local button_1 = tf.TFStyleVGUI("DButton", button_holder)
	button_1:SetText(tf.GetPhrase("#TF_SavePreset") or "SAVE")
	button_1:SizeToContentsX(20)
	button_1.DoClick = function()
		//Open save gui
		local back = vgui.Create("DPanel", editor)
		back:SetSize(editor:GetSize())
		function back:Paint(w,h)
			surface.SetDrawColor(tf.gui_colors.TanDarker.r, tf.gui_colors.TanDarker.g, tf.gui_colors.TanDarker.b, 192)
			surface.DrawRect(0,0,w,h)
		end
		local pnl = vgui.Create("DSizeToContents", editor)
		pnl:DockPadding(20,20,20,20)
		function pnl:Paint(w, h)
			tf.GrayDialogBorder(0,0,w,h)
		end
		function pnl:OnRemove()
			back:Remove()
		end
		pnl:SetSize(650,400)
		pnl:Center()
		editor.SavePopup = pnl

		local text = vgui.Create("DLabel", pnl)
		text:SetFont("TF2ItemBrowser_ItemName_Larger")
		text:SetColor(tf.gui_colors.LightRed)
		text:SetText("Save custom item")
		text:SetContentAlignment(5)
		text:Dock(TOP)

		local entry_holder = vgui.Create("Panel", pnl)
		entry_holder:Dock(TOP)
		entry_holder:DockMargin(0,tf.betweencategories*1.5,0,0)
		entry_holder:SetHeight(28)
		local text = vgui.Create("DLabel", entry_holder)
		text:SetFont("TF2ItemBrowser_ItemName")
		text:SetColor(tf.gui_colors.TanLight)
		text:SetText("Save As:")
		text:SetContentAlignment(6)
		text:SizeToContentsX()
		text:Dock(LEFT)
		text:DockMargin(0,0,8,0)
		local _pnl = vgui.Create("DPanel", entry_holder)
		_pnl:Dock(FILL)
		_pnl:DockPadding(4,4,4,4)
		function _pnl:Paint(w,h)
			draw.RoundedBox(12, 0,0,w,h, color_black)
		end
		local entry = tf.TFStyleVGUI("DTextEntry", _pnl)
		entry:Dock(FILL)
		entry:SetText(editor.SavedName)
		entry:RequestFocus()
		entry:SelectAllText(true)
		local text = vgui.Create("DLabel", _pnl)
		text:SetFont("TF2ItemBrowser_ItemDesc")
		text:SetColor(tf.gui_colors.TanDark)
		text:SetText("data/tf2itembrowser_customitems/")
		text:SizeToContentsX()
		text:Dock(LEFT)
		text:DockMargin(0,0,4,0)
		local text = vgui.Create("DLabel", _pnl)
		text:SetFont("TF2ItemBrowser_ItemDesc")
		text:SetColor(tf.gui_colors.TanDark)
		text:SetText(".txt")
		text:SizeToContentsX()
		text:Dock(RIGHT)
		text:DockMargin(4,0,0,0)

		local text = vgui.Create("DLabel", pnl)
		pnl.errortext = text
		text:SetWrap(true)
		text:SetFont("TF2ItemBrowser_ItemDesc")
		text:SetColor(tf.desc_colors.negative)
		text:SetText("")
		text:Dock(TOP)
		text:SetEnabled(false)
		text:SetTall(0)

		local i = tf.TF2Items.items[editor.SavedName]
		if i and i._file_origin.GAME then
			local text = vgui.Create("DLabel", pnl)
			text:SetWrap(true)
			text:SetAutoStretchVertical(true)
			text:SetFont("TF2ItemBrowser_ItemDesc")
			text:SetColor(tf.quality_colors.unique) //dumb
			if !i._file_origin.DATA then
				text:SetText("NOTE: This item is being loaded from an addon. Saving over it using the same file name will cause your saved item to be loaded instead of the addon item.")
			else
				text:SetText("NOTE: This saved item is overriding an addon item with the same file name.")
			end
			text:Dock(TOP)
			text:DockMargin(0,tf.betweencategories*1.5,0,0)
		end

		local text = vgui.Create("DLabel", pnl)
		text:SetWrap(true)
		text:SetAutoStretchVertical(true)
		text:SetFont("TF2ItemBrowser_ItemDesc")
		text:SetColor(tf.gui_colors.TanLight)
		text:SetText("Tips for developers:\n\n- Custom items in the browser are sorted alphabetically by file name. This means you can keep item sets together by giving them a shared prefix like \"setname_hat\", \"setname_shirt\", and so on.\n\n- To include a custom item in an addon, move the saved file into the addon's \"data_static/tf2itembrowser_customitems/\" folder. If the same file name is in both GMod's data folder AND an addon's data_static folder (i.e. because a player saved over an addon item), the one in the data folder takes priority.")
		text:Dock(TOP)
		text:DockMargin(0,tf.betweencategories*1.5,0,0)

		local button_holder = vgui.Create("Panel", pnl)
		local button_1 = tf.TFStyleVGUI("DButton", button_holder)
		button_1:SetText(tf.GetPhrase("#TF_SavePreset") or "SAVE")
		button_1:SizeToContentsX(20)
		button_1.DoClick = function()
			local i = {}
			for pnl, funcs in pairs (editor.controls) do
				if funcs.Save then funcs.Save(i) end
			end
			i.name = entry:GetText():lower()
			MsgN("\n\n\n")
			PrintTable(i)

			net.Start("TF2ItemBrowser_NewCustomItem_SendToSv")
				net.WriteData(util.Compress(util.TableToJSON(i)))
			net.SendToServer()
		end
		local button_2 = tf.TFStyleVGUI("DButton", button_holder)
		button_2:SetText(string.upper(language.GetPhrase("dialog.cancel")))
		button_2:SizeToContentsX(20)
		button_2.DoClick = function()
			pnl:Remove()
		end
		button_holder:Dock(TOP)
		button_holder:DockMargin(0,tf.betweencategories*1.5,0,0)
		local button_w = math.max(180, button_1:GetWide(), button_2:GetWide()) //make these extra wide to better fill all the space they have, unless some language has a really long word here
		function button_holder:PerformLayout(w, h)
			button_1:SetWide(button_w)
			button_1:SetPos((w/2)-4-button_w, 0)
			button_2:SetWide(button_w)
			button_2:SetPos((w/2)+4, 0)
			button_holder:SizeToChildren(false, true)
		end

		pnl:InvalidateLayout(true)
		function pnl:DoConfirmation(success)
			if success then
				surface.PlaySound("replay/rendercomplete.wav")
				editor.SavedName = entry:GetText():lower() //show this same filename in the save window if we open it again
				pnl:Remove()
			else
				surface.PlaySound("replay/replaydialog_warn.wav")
				local text = pnl.errortext
				text:SetText("Couldn't save \"data/tf2itembrowser_customitems/" .. entry:GetText():lower() .. ".txt\" - bad file name?")
				text:SetEnabled(true)
				text:SetAutoStretchVertical(true)
				text:DockMargin(0,4,0,0)
				pnl:InvalidateLayout(true)
			end
		end
	end
	local button_2 = tf.TFStyleVGUI("DButton", button_holder)
	button_2:SetText(string.upper(tf.GetPhrase("#TF_SteamWorkshop_Delete") or "Delete"))
	button_2:SizeToContentsX(20)
	button_2.DoClick = function()
		//Open delete gui
		local back = vgui.Create("DPanel", editor)
		back:SetSize(editor:GetSize())
		function back:Paint(w,h)
			surface.SetDrawColor(tf.gui_colors.TanDarker.r, tf.gui_colors.TanDarker.g, tf.gui_colors.TanDarker.b, 192)
			surface.DrawRect(0,0,w,h)
		end
		local pnl = vgui.Create("DSizeToContents", editor)
		pnl:DockPadding(20,20,20,20)
		function pnl:Paint(w, h)
			tf.GrayDialogBorder(0,0,w,h)
		end
		function pnl:OnRemove()
			back:Remove()
		end
		pnl:SetSize(500,210)
		pnl:Center()
		editor.SavePopup = pnl

		local text = vgui.Create("DLabel", pnl)
		text:SetFont("TF2ItemBrowser_ItemName_Larger")
		text:SetColor(tf.gui_colors.LightRed)
		text:SetText("Delete custom item")
		text:SetContentAlignment(5)
		text:Dock(TOP)

		local text = vgui.Create("DLabel", pnl)
		text:SetWrap(true)
		text:SetAutoStretchVertical(true)
		text:SetFont("TF2ItemBrowser_ItemDesc")
		text:SetColor(tf.gui_colors.TanLight)
		text:SetText("Are you sure you want to delete \"data/tf2itembrowser_customitems/" .. editor.SavedName .. ".txt\"?\nThis cannot be undone!")
		text:Dock(TOP)
		text:DockMargin(0,tf.betweencategories*1.5,0,0)

		local i = tf.TF2Items.items[editor.SavedName]
		if i and i._file_origin.GAME and i._file_origin.DATA then
			local text = vgui.Create("DLabel", pnl)
			text:SetWrap(true)
			text:SetAutoStretchVertical(true)
			text:SetFont("TF2ItemBrowser_ItemDesc")
			text:SetColor(tf.quality_colors.unique) //dumb
			text:SetText("NOTE: This saved item is overriding an addon item with the same file name. Deleting it will cause the addon item to be loaded instead.")
			text:Dock(TOP)
			text:DockMargin(0,tf.betweencategories,0,0)
		end

		local text = vgui.Create("DLabel", pnl)
		pnl.errortext = text
		text:SetWrap(true)
		text:SetFont("TF2ItemBrowser_ItemDesc")
		text:SetColor(tf.desc_colors.negative)
		text:SetText("")
		text:Dock(TOP)
		text:SetEnabled(false)
		text:SetTall(0)

		local button_holder = vgui.Create("Panel", pnl)
		local button_1 = tf.TFStyleVGUI("DButton", button_holder)
		button_1:SetText(string.upper(tf.GetPhrase("#TF_SteamWorkshop_Delete") or "Delete"))
		button_1:SizeToContentsX(20)
		button_1.DoClick = function()
			net.Start("TF2ItemBrowser_DeleteCustomItem_SendToSv")
				net.WriteString(editor.SavedName)
			net.SendToServer()
		end
		local button_2 = tf.TFStyleVGUI("DButton", button_holder)
		button_2:SetText(string.upper(language.GetPhrase("dialog.cancel")))
		button_2:SizeToContentsX(20)
		button_2.DoClick = function()
			pnl:Remove()
		end
		button_holder:Dock(TOP)
		button_holder:DockMargin(0,tf.betweencategories*1.5,0,0)
		local button_w = math.max(180, button_1:GetWide(), button_2:GetWide()) //make these extra wide to better fill all the space they have, unless some language has a really long word here
		function button_holder:PerformLayout(w, h)
			button_1:SetWide(button_w)
			button_1:SetPos((w/2)-4-button_w, 0)
			button_2:SetWide(button_w)
			button_2:SetPos((w/2)+4, 0)
			button_holder:SizeToChildren(false, true)
		end

		pnl:InvalidateLayout(true)
		function pnl:DoConfirmation(success)
			if success then
				surface.PlaySound("replay/deleted_take.wav")
				if !tf.TF2Items.items[editor.SavedName] or !game.SinglePlayer() then //in multiplayer, the client won't have received the new post-deletion item table yet, so we can't check if deleting the item replaced it with an addon item, or load the addon item with OpenCustomItemEditor if we wanted to. instead, just always close the editor.
					editor:Close()
				else
					TF2ItemBrowser_OpenCustomItemEditor(editor.SavedName)
				end
			else
				surface.PlaySound("replay/replaydialog_warn.wav")
				local text = pnl.errortext
				text:SetText("Error: Couldn't delete \"data/tf2itembrowser_customitems/" .. editor.SavedName .. ".txt\"")
				text:SetEnabled(true)
				text:SetAutoStretchVertical(true)
				text:DockMargin(0,tf.betweenitems,0,0)
				pnl:InvalidateLayout(true)
			end
		end
	end
	function button_2:Think()
		if editor.SavedName == "" then
			self:SetEnabled(false)
			tf.AddTFStyleTooltip(self, "")
		else
			local i = tf.TF2Items.items[editor.SavedName]
			if i and i._file_origin.GAME and !i._file_origin.DATA then
				self:SetEnabled(false)
				tf.AddTFStyleTooltip(self, "This item is being loaded from an addon, and cannot be deleted. Enter\n\"whereis data_static/tf2itembrowser_customitems/" .. editor.SavedName .. ".txt\"\nin console to locate which addon it's being loaded from.")
			else
				self:SetEnabled(true)
				tf.AddTFStyleTooltip(self, "")
			end
		end
	end
	local button_3 = tf.TFStyleVGUI("DButton", button_holder)
	button_3:SetText(string.upper(language.GetPhrase("preset.close")))
	button_3:SizeToContentsX(20)
	button_3.DoClick = function()
		editor:Close()
	end
	button_holder:Dock(BOTTOM)
	button_holder:DockMargin(0,8,0,0)
	local button_w = math.max(180, button_1:GetWide(), button_2:GetWide(), button_3:GetWide()) //make these extra wide to better fill all the space they have, unless some language has a really long word here
	function button_holder:PerformLayout(w, h)
		button_1:SetPos((w/2)-(button_w*1.5)-8, 0)
		button_2:SetPos((w/2)-(button_w/2), 0)
		button_3:SetPos((w/2)+(button_w/2)+8, 0)
		button_1:SetWide(button_w)
		button_2:SetWide(button_w)
		button_3:SetWide(button_w)
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
			draw.RoundedBox(12, 0,0,w,h, tf.gui_colors._options)
		end

		if label then
			local text = vgui.Create("DLabel", box)
			text:SetContentAlignment(7) //top left
			text:SetAutoStretchVertical(true)
			text:SetFont("TF2ItemBrowser_ItemName")
			text:SetColor(tf.gui_colors.TanLight)
			text:SetText(label)
			text:Dock(TOP)
			text:DockMargin(-8,-8,0,tf.betweenitems)
			box.label = text
		end

		return box
	end

	local function AddDropdown(parent, label, subtable, key_to_set, options, default_option_id)
		local combo = tf.TFStyleVGUI("DComboBox", parent)
		local _pnl = tf.AddTFLabelToVGUI(combo, label)
		_pnl:DockMargin(0,tf.betweenitems,0,0)
		_pnl:Dock(TOP)
		combo:SetSortItems(false)
		function combo:PopulateOptions(options)
			local _, old_sel
			if combo.options then
				_, old_sel = combo:GetSelected()
				if old_sel and combo:GetParent():IsVisible() then
					old_sel = combo.options[old_sel].Value
				else
					old_sel = ""
				end
			end
			combo:Clear()
			combo.options = options
			for k, v in ipairs (combo.options) do
				if combo.options[k].PrependSpacer then combo:AddSpacer() end
				combo.options[k].id = combo:AddChoice(v.Label, k)
			end
			if #options > 0 then
				if old_sel then
					//Reselect the previously selected option if it still exists, otherwise select the first one
					for k, v in ipairs (options) do
						if v.Value == old_sel then
							combo:ChooseOptionID(v.id)
							old_sel = nil
							break
						end
					end
					if old_sel then combo:ChooseOptionID(default_option_id or 1) end
				else
					combo:ChooseOptionID(default_option_id or 1)
				end
			end
		end
		combo:PopulateOptions(options or {})
		if key_to_set then
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
		end
		return combo
	end

	local function AddTextEntry(parent, label, subtable, key_to_set, alt_style)
		//dock the textentry into a new panel that only exists to be a container, because otherwise, clicking on a 
		//textentry docked directly into one of our DSizeToContents boxes moves it to the bottom?? why??
		local _pnl = vgui.Create("Panel", parent)
		_pnl:DockMargin(0,tf.betweenitems,0,0)
		_pnl:Dock(TOP)
		_pnl:SetHeight(20)
		local entry = tf.TFStyleVGUI("DTextEntry", _pnl, alt_style)
		entry:Dock(FILL)
		entry:SetPlaceholderText(label)
		tf.AddTFStyleTooltip(entry, label)
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
	local scroll = tf.TFStyleVGUI("DScrollPanel", editor)
	scroll:Dock(FILL)
	local holder = AddColumnHolder(scroll, 3, 8)
	holder:Dock(FILL)
	//fix: make sure that scrolling to change the icon's fov doesn't mistakenly scroll this panel
	local old_OnMouseWheeled = scroll.VBar.OnMouseWheeled
	function scroll.VBar:OnMouseWheeled(dlta)
		if editor.bp.Capturing or editor.bp:IsHovered() then return end
		return old_OnMouseWheeled(self, dlta)
	end


	local box = AddBox(holder.columns[1], language.GetPhrase("#information") .. ":")

	local entry = AddTextEntry(box, tf.GetPhrase("#TF_ImportFile_NameLabel" or "Item Name"), nil, "item_name")
	entry:GetParent():DockMargin(0,0,0,0)

	local lvlstr = tf.GetPhrase("#ItemTypeDesc") or "Level %s1 %s2"
	local s1 = string.find(lvlstr, "%s1", 1, true)
	local s2 = string.find(lvlstr, "%s2", 1, true)
	local lvl_before_type //some languages are formatted as "itemtype level X"
	if s1 and s2 then lvl_before_type = s1 < s2 end
	local strs = {}
	if lvl_before_type then
		strs = string.Split(lvlstr, "%s1")
		local _strs2 = string.Split(strs[2], "%s2")
		strs[2] = nil
		table.Add(strs, _strs2)
	else
		strs = string.Split(lvlstr, "%s2")
		local _strs2 = string.Split(strs[2], "%s1")
		strs[2] = nil
		table.Add(strs, _strs2)
	end
	for k, v in ipairs (strs) do
		strs[k] = string.Trim(v)
	end
	local entry = AddTextEntry(box, tf.GetPhrase("#TF_ImportFile_TypeLabel") or "Item Type", nil, "item_type_name")
	if strs[1] != "" then
		local label = vgui.Create("DLabel", entry:GetParent())
		label:SetColor(tf.gui_colors.TanLight)
		label:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
		label:SetText(strs[1])
		label:SizeToContentsX()
		label:Dock(LEFT)
		label:DockMargin(0,0,4,0)
	end
	local num = tf.TFStyleVGUI("DNumberWang", entry:GetParent(), true)
	if lvl_before_type then
		num:Dock(LEFT)
		num:DockMargin(0,0,4,0)
	else
		num:Dock(RIGHT)
		num:DockMargin(4,0,0,0)
		num:SetZPos(1)
	end
	num:SetWide(50)
	num:SetDecimals(0)
	num:SetMinMax(-math.huge, math.huge) //uncap this, no reason people shouldn't be able to enter level 1337 or other goofy things
	tf.AddTFStyleTooltip(num, (tf.GetPhrase("#TF_Duck_Level") or "Level") .. " (leave blank for random level)")
	editor.controls[num] = {
		Load = function(i)
			if i.max_ilevel then 
				num:SetValue(i.max_ilevel)
			else
				num:SetText("")
			end
		end,
		Save = function(i)
			if tonumber(num:GetText()) != nil then //let players leave this blank for random level
				i.max_ilevel = num:GetValue()
				i.min_ilevel = num:GetValue()
			end
		end
	}
	if strs[2] != "" then
		local label = vgui.Create("DLabel", entry:GetParent())
		label:SetColor(tf.gui_colors.TanLight)
		label:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
		label:SetText(strs[2])
		label:SizeToContentsX()
		if lvl_before_type then
			label:Dock(LEFT)
			label:DockMargin(0,0,4,0)
		else
			label:Dock(RIGHT)
			label:DockMargin(4,0,0,0)
			label:SetZPos(2)
		end
	end
	if strs[3] != "" then
		local label = vgui.Create("DLabel", entry:GetParent())
		label:SetColor(tf.gui_colors.TanLight)
		label:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
		label:SetText(strs[3])
		label:SizeToContentsX()
		label:Dock(RIGHT)
		label:DockMargin(4,0,0,0)
	end
	
	local entry = AddMultilineTextEntry(box, string.TrimRight(tf.GetPhrase("#TF_PublishFile_DescLabel") or "Description:", ":"), nil, "item_description")

	local check = tf.TFStyleVGUI("DCheckBoxLabel", box)
	check:SetText("Add fake attributes?")
	check:DockMargin(0,tf.betweencategories,0,0)
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


	//Checkboxes to select classes in any combination
	local box = AddBox(holder.columns[1], tf.GetPhrase("#Store_ClassFilterLabel") or "Classes:")
	editor.classes = AddColumnHolder(box, 3, 0)
	editor.classes:Dock(TOP)
	editor.classes.checks = {}
	for i = 2, 10 do
		local check = tf.TFStyleVGUI("DCheckBoxLabel", editor.classes.columns[math.fmod(i-2, 3)+1])
		check:Dock(TOP)
		if i > 4 then
			check:DockMargin(0,tf.betweenitems,0,0)
		end
		check:SetText(tf.GetPhrase(tf.classes[i].langstr) or string.NiceName(tf.classes[i].longname))
		editor.classes.checks[tf.classes[i].longname] = check
		//make sure user can read the text if it's cut off
		tf.AddTFStyleTooltip(check.Label, check:GetText())
		local old_IsHovered = check.Label.IsHovered
		function check.Label:IsHovered(...)
			return old_IsHovered(self, ...) or check:IsHovered(...)
		end
		function check:OnChange(val) //Update all controls that are dependent on class selection
			//Only show equip regions for the currently selected class
			editor.equip_regions:UpdateDropdowns()
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
			if i.used_by_classes then //this will be nil when starting with a blank item, but should always be present in saved items
				for class, _ in pairs (i.used_by_classes) do
					if editor.classes.checks[class] then
						editor.classes.checks[class]:SetValue(true)
					end
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

	//Selector for item_slot - this is also used to enable/disable controls that are only used for certain slots
	local combo = AddDropdown(box, "Item Slot", nil, "item_slot", { //not localized; the closest we have is just "Slot:" which doesn't fit here
		{
			Label = tf.GetPhrase("#LoadoutSlot_Misc") or "Cosmetic",
			Value = "misc",
		},
		{
			PrependSpacer = true,
			Label = tf.GetPhrase("#TR_Primary") or "Primary",
			Value = "primary"
		},
		{
			Label = tf.GetPhrase("#TR_Secondary") or "Secondary",
			Value = "secondary"
		},
		{
			Label = tf.GetPhrase("#TR_Melee") or "Melee",
			Value = "melee"
		},
		{
			Label = tf.GetPhrase("#LoadoutSlot_pda") or "Primary PDA",
			Value = "pda"
		},
		{
			Label = tf.GetPhrase("#LoadoutSlot_pda2") or "Secondary PDA",
			Value = "pda2"
		},
		{
			Label = (tf.GetPhrase("#LoadoutSlot_Building") or "Building") .. " (toolbox, " .. string.lower(tf.GetPhrase("#TF_Weapon_Spy_Sapper") or "Sapper") .. ")",
			Value = "building"
		},
		{
			PrependSpacer = true,
			Label = tf.GetPhrase("#LoadoutSlot_Action") or "Action",
			Value = "action"
		},
		{
			Label = (tf.GetPhrase("#LoadoutSlot_Utility") or "Utility") .. " (" .. (tf.GetPhrase("#GameType_Passtime") or "PASS Time") .. " JACK)",
			Value = "utility"
		},
		{
			Label = tf.str_none,
			Load = function(i)
				if !i.item_slot and table.Count(i) > 0 then return true end  //don't default to nil if we're starting from a blank table
			end,
			Save = function(i)
				i.item_slot = nil
			end
		},
	}, 1) //default to cosmetic
	combo:GetParent():DockMargin(0,tf.betweencategories,0,0)
	function combo:OnSelect(index, value, data)
		local val = combo.options[index].Value
		editor.paintable:SetVisible(val == "misc")
		editor.genteel_smoke:SetVisible(val == "misc")
		editor.anim:GetParent():SetVisible(val != "misc" and val != nil)
		holder:InvalidateLayout(true)
	end

	//Selector for weapon anim_slot as well as some relevant pose parameters
	editor.anim = AddDropdown(box, tf.GetPhrase("#TF_ImportFile_AnimationSource") or "Animation", nil, "anim_slot", {
		{
			Label = "Use slot default",
			Load = function(i)
				if !i.anim_slot then return true end  //TODO: will this work?
			end,
			Save = function(i)
				i.anim_slot = nil
			end
		},
		{
			PrependSpacer = true,
			Label = string.NiceName(string.lower(tf.GetPhrase("#tf_zi_ui_passive") or "PASSIVE")), //tf.str_none,
			Value = "FORCE_NOT_USED"
		},
		{
			PrependSpacer = true,
			Label = tf.GetPhrase("#TR_Primary") or "Primary",
			Value = "primary"
		},
		{
			Label = tf.GetPhrase("#TR_Secondary") or "Secondary",
			Value = "secondary"
		},
		{
			Label = tf.GetPhrase("#TR_Melee") or "Melee",
			Value = "melee"
		},
		{
			Label = tf.GetPhrase("#TF_Weapon_PDA_Engineer") or "PDA",
			Value = "pda"
		},
		{
			Label = (tf.GetPhrase("#LoadoutSlot_Building") or "Building") .. " (toolbox, " .. string.lower(tf.GetPhrase("#TF_Weapon_Spy_Sapper") or "Sapper") .. ")",
			Value = "building"
		},
		{
			PrependSpacer = true,
			Label = (tf.GetPhrase("#Item") or "Item") .. " 1 (" .. string.lower(tf.GetPhrase("#TF_Weapon_FlareGun") or "Flare Gun") .. ", " .. string.lower(tf.GetPhrase("#TF_Weapon_Sword") or "Sword") .. ", " .. string.lower(tf.GetPhrase("#TF_Unique_Achievement_LunchBox") or "Sandvich") .. ", " .. string.lower(tf.GetPhrase("#TF_Unique_Achievement_Laser_Pointer") or "Wrangler") .. ", " .. string.lower(tf.GetPhrase("#TF_Jar") or "JAR") .. ", " .. string.lower(tf.GetPhrase("#TF_SharpDresser") or "Sharp Dresser") .. ")",
			Value = "item1"
		},
		{ //item1 for scout drink, applies hand_grip poseparam
			Label = (tf.GetPhrase("#Item") or "Item") .. " 1 (" .. string.lower(tf.GetPhrase("#TF_Class_Name_Scout") or "Scout")  .. " " .. string.lower(tf.GetPhrase("#TF_EnergyDrink") or "Drink") .. ")",
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
			Label = (tf.GetPhrase("#Item") or "Item") .. " 2 (" .. string.lower(tf.GetPhrase("#TF_Unique_Achievement_Scattergun_Double") or "Force-a-Nature") .. ", " .. string.lower(tf.GetPhrase("#TF_Unique_Robot_Arm") or "Gunslinger") .. ", " .. string.lower(tf.GetPhrase("#TF_Unique_Achievement_CompoundBow") or "Huntsman") .. ")",
			Value = "item2"
		},
		{
			Label = (tf.GetPhrase("#Item") or "Item") .. " 4 (" .. string.lower(tf.GetPhrase("#TF_ThermalThruster") or "Thermal Thruster") .. ")",
			Value = "item4"
		},
		//TODO: cow mangler has anim_slot "primary2" but this only has fire/reload anims and i'm not even sure if tf2 uses them; revisit later when we do anim functionality
		{
			Label = (tf.GetPhrase("#TR_Secondary") or "Secondary") .. " 2 (" ..  string.lower(tf.GetPhrase("#TF_BISON") or "BISON")  .. ")",
			Value = "secondary2"
		},
		{
			Label = (tf.GetPhrase("#TR_Melee") or "Melee") .. " - " .. string.lower(tf.GetPhrase("#Store_ItemDesc_AllClasses") or "All Classes"),
			Value = "melee_allclass"
		},
		{ //melee_allclass for bread jars, applies hand_grip poseparam
			Label = (tf.GetPhrase("#TR_Melee") or "Melee") .. " - " .. string.lower(tf.GetPhrase("#Store_ItemDesc_AllClasses") or "All Classes") .. " (" .. string.lower(tf.GetPhrase("#TF_Wearable_Bread") or "Bread")  .. " " .. string.lower(tf.GetPhrase("#TF_Jar") or "JAR") .. ")",
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
			Label = (tf.GetPhrase("#TR_Melee") or "Melee") .. " - " .. string.lower(tf.GetPhrase("#Store_ItemDesc_AllClasses") or "All Classes") .. " (" .. string.lower(tf.GetPhrase("#TF_GasPasser") or "Gas Passer") .. ")",
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
			Label = (tf.GetPhrase("#TR_Melee") or "Melee") .. " - " .. string.lower(tf.GetPhrase("#Store_ItemDesc_AllClasses") or "All Classes") .. " (" .. string.lower(tf.GetPhrase("#TF_Weapon_HotHand") or "Hot Hand") .. ")",
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
			Label = (tf.GetPhrase("#GameType_Passtime") or "PASS Time") .. " JACK",
			Value = "passtime_ball"
		}
		//TOOD: 357 The Half-Zatoichi uses anim_slot "", what's going on there?
	})

	//Dropdowns for equip region - this creates as many dropdowns as needed, 
	//adding an empty one to the list when the existing ones are all filled
	local pnl = vgui.Create("DSizeToContents", box)
	pnl:Dock(TOP)
	pnl:DockMargin(0,tf.betweencategories-tf.betweenitems,0,0)
	editor.equip_regions = pnl
	pnl.drops = {}
	function pnl:GetOptions()
		local options = {}
		table.insert(options, {Label = tf.str_none, Value = "(none)"}) //PopulateOptions old_sel code doesn't like nil values, call the empty value "(none)" instead
		for classid, class in ipairs (tf.classes) do //add class-based equip regions in class order
			if !editor.classes.checks[class.longname] or editor.classes.checks[class.longname]:GetChecked() then
				for k, v in ipairs (tf.TF2Items.equip_regions_list[classid]) do
					table.insert(options, {Label = string.NiceName(v), Value = v, PrependSpacer = (k == 1)})
				end
			end
		end
		return options
	end
	function pnl:UpdateDropdowns()
		//Rebuild the available options to show equip regions for the currently selected classes
		local options = pnl:GetOptions()
		for k, v in ipairs (pnl.drops) do
			v.IsBuilt = nil
			v:PopulateOptions(options)
			v.IsBuilt = true
		end
		//Clear out blank dropdowns except the last one
		local drops_to_remove = {}
		for k, v in ipairs (pnl.drops) do
			if v:GetSelectedID() == 1 and k != #pnl.drops then drops_to_remove[k] = v end
		end
		for k, v in pairs (drops_to_remove) do
			v:GetParent():Remove()
			table.remove(pnl.drops, k)
		end
		for k, v in ipairs (pnl.drops) do
			v:GetParent():Dock(TOP)
		end
		//Make sure we always have a blank dropdown at the end of the list
		if #pnl.drops == 0 or pnl.drops[#pnl.drops]:GetSelectedID() != 1 then
			local drop = pnl:AddDropdown(options)
			drop.IsBuilt = true
		end
		for k, v in pairs (pnl.drops) do
			local text = tf.GetPhrase("#TF_ImportFile_EquipRegionLabel") or "Equip Region"
			if k > 1 then
				text = text .. " " .. tostring(k)
			end
			v:GetParent().Label:SetText(text)
		end
	end
	function pnl:AddDropdown(options)
		local drop = AddDropdown(pnl, "", nil, nil, options)
		table.insert(pnl.drops, drop)
		function drop:OnSelect()
			if self.IsBuilt then
				pnl:UpdateDropdowns()
			end
		end
		return drop
	end
	pnl.LoadOrder = 1 //make sure classes are loaded first
	editor.controls[pnl] = {
		Load = function(i)
			if i.equip_regions then
				local options = pnl:GetOptions()
				for k, v in pairs (i.equip_regions) do
					local drop = pnl:AddDropdown(options)
					for k2, v2 in ipairs (options) do
						if k == v2.Value then
							drop:ChooseOptionID(v2.id)
							break
						end
					end
					drop.IsBuilt = true
				end
			end
			pnl:UpdateDropdowns()
		end,
		Save = function(i)
			for k, v in ipairs (pnl.drops) do
				local _, opt = v:GetSelected()
				if v.options[opt].Value and v.options[opt].Value != "(none)" then
					i.equip_regions = i.equip_regions or {}
					i.equip_regions[v.options[opt].Value] = 1
				end
			end
		end
	}


	//Checkboxes to set player bodygroups
	local box = AddBox(holder.columns[1], language.GetPhrase("#bodygroups") .. ":")
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
			label = "Headphones", // (" .. string.lower(tf.GetPhrase("#TF_Class_Name_Scout") or "Scout") .. ")",
			bgs = {
				scout = "headphones"
			}
		},
		{
			label = "Head", // (" .. string.lower(tf.GetPhrase("#TF_Class_Name_Pyro") or "Pyro") .. ")",
			bgs = {
				pyro = "head"
			}
		},
		{
			label = "Dogtags", // (" .. string.lower(tf.GetPhrase("#TF_Class_Name_Scout") or "Scout") .. ")",
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
			label = "Bullets", // (" .. string.lower(tf.GetPhrase("#TF_Class_Name_HWGuy") or "Heavy") .. ")",
			bgs = {
				heavy = "bullets",
				sniper = {name = "bullets", forced = {darts = 0}} //also forcibly disable sydney sleeper darts if equipped at the same time
			}
		},
		{
			label = "Backpack", // (" .. string.lower(tf.GetPhrase("#TF_Class_Name_Pyro") or "Pyro") .. ", " .. string.lower(tf.GetPhrase("#TF_Class_Name_Medic") or "Medic") .. ")",
			bgs = {
				pyro = "backpack",
				medic = "medic_backpack"
			}
		},
		{
			label = "Hands", // (" .. string.lower(tf.GetPhrase("#TF_Class_Name_HWGuy") or "Heavy") .. ")",
			bgs = {
				heavy = "hands"
			}
		},
		{
			label = "Right hand", // (" .. string.lower(tf.GetPhrase("#TF_Class_Name_Pyro") or "Pyro") .. ", " .. string.lower(tf.GetPhrase("#TF_Class_Name_Engineer") or "Engineer") ..  ")",
			bgs = {
				pyro = "righthand",
				engineer = {name = "rightarm", val = 2} //rightarm 1 is gunslinger
			}
		},
		{
			label = "Shoes", // (" .. string.lower(tf.GetPhrase("#TF_Class_Name_Demoman") or "Demo") .. ", " .. string.lower(tf.GetPhrase("#TF_Class_Name_Scout") or "Scout") ..  ")",
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
				val = bg.val or 1
				bg = bg.name
			end
			keys_by_bg[bg] = {val = val, k = k}
		end
		local check = tf.TFStyleVGUI("DCheckBoxLabel", editor.bodygroups.columns[math.fmod(k-1, 2)+1])
		check:Dock(TOP)
		if k > 2 then
			check:DockMargin(0,tf.betweenitems,0,0)
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
		tf.AddTFStyleTooltip(check.Label, check:GetText())
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
						if bg.forced then
							for k2, v2 in pairs (bg.forced) do
								i.visuals._player_forced_bodygroups = i.visuals._player_forced_bodygroups or {}
								i.visuals._player_forced_bodygroups[k2] = v2
							end
						end
						val = bg.val or 1
						bg = bg.name
					end
					i.visuals.player_bodygroups[bg] = val
				end
			end
		end
	}


	local box = AddBox(holder.columns[2], string.NiceName(language.GetPhrase("#models")) .. ":")

	//Base model
	local entry = AddTextEntry(box, "Item model", "model_player_per_class", "basename") //nil, "model_player") //model_player_per_class.basename accepts the %s token, while model_player doesn't. don't overthink it, just use the former for everything, even single-class items.
	entry:GetParent():DockMargin(0,0,0,0)
	editor.model = entry
	function entry:OnEnter()
		editor.bp_mdl:UpdateVisibility()
		editor.bp:Refresh()
	end

	//Per-class models - gate these behind a checkbox that also only appears if multiple classes are selected
	local check = tf.TFStyleVGUI("DCheckBoxLabel", box)
	check:SetText("Class-specific model paths?")
	check:DockMargin(0,tf.betweenitems,0,0)
	check:Dock(TOP)
	editor.class_models = check
	check.classes = {}
	editor.controls[check] = {
		Load = function(i)
			//Only start off checked if there are already per-class models in the table
			for classid = 2, 10 do
				if i.model_player_per_class and i.model_player_per_class[tf.classes[classid].longname] then
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
			editor.class_models.classes[i]:GetParent():SetVisible(check:GetChecked() and editor.classes.checks[tf.classes[i].longname]:GetChecked() and selected_class_count > 1)
		end
		//Only show the help text if we're showing the class-specific entries
		check.help:SetVisible(selected_class_count > 1 and check:GetChecked())
		//Refresh the backpack icon modelpanel, just in case the currently used model was disabled or something
		editor.bp_mdl:UpdateVisibility()
		editor.bp:Refresh()
	end
	for i = 2, 10 do
		local entry = AddTextEntry(box, "Item model - " .. (tf.GetPhrase(tf.classes[i].langstr) or string.NiceName(tf.classes[i].longname)), "model_player_per_class", tf.classes[i].longname)
		check.classes[i] = entry
		function entry:OnEnter()
			editor.bp_mdl:UpdateVisibility()
			editor.bp:Refresh()
		end
	end
	local help = vgui.Create("DLabel", box)
	help:SetWrap(true)
	help:SetAutoStretchVertical(true)
	help:SetFont("TF2ItemBrowser_ItemDesc_Smaller")
	help:SetColor(tf.gui_colors.TanLight)
	help:SetText("Tip: As an alternative, \"%s\" (percent sign s) in the main model path will be read as the class the item is spawned for - \"hat_%s\" will become \"hat_demo\", \"hat_engineer\", and so on.")
	help:Dock(TOP)
	help:DockMargin(0,tf.betweenitems,0,0)
	check.help = help

	//Paintable toggle
	local check = tf.TFStyleVGUI("DCheckBoxLabel", box)
	editor.paintable = check
	check:Dock(TOP)
	check:DockMargin(0,tf.betweencategories,0,0)
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
	local check = tf.TFStyleVGUI("DCheckBoxLabel", box)
	editor.genteel_smoke = check
	check:Dock(TOP)
	check:DockMargin(0,tf.betweenitems,0,0)
	check:SetText("Add " .. (tf.GetPhrase("#Attrib_Particle28") or "Genteel Smoke") .. " effect\n(requires \"cig_drg_smoke\" attachment)")
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

	//Text entries for attached models - this creates as many entries as needed, 
	//adding an empty one to the list when the existing ones are all filled
	local pnl = vgui.Create("DSizeToContents", box)
	pnl:Dock(TOP)
	pnl:DockMargin(0,tf.betweencategories-tf.betweenitems,0,0)
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
			tf.AddTFStyleTooltip(v, text)
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
	help:SetColor(tf.gui_colors.TanLight)
	help:SetText("Extra models attached to the item, i.e. festive lights, botkillers, flamethrower pilot lights")
	help:Dock(TOP)
	help:DockMargin(0,tf.betweenitems,0,0)

	//Text entries for extra wearables - this works like the above but with a max of 2
	local pnl = vgui.Create("DSizeToContents", box)
	pnl:Dock(TOP)
	pnl:DockMargin(0,tf.betweencategories-tf.betweenitems,0,0)
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
			tf.AddTFStyleTooltip(v, text)
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
			editor.bp_mdl:UpdateVisibility()
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
	help:SetColor(tf.gui_colors.TanLight)
	help:SetText("Extra models attached to the player model, i.e. medigun/banner backpacks, banner flags")
	help:Dock(TOP)
	help:DockMargin(0,tf.betweenitems,0,0)

	//Skin id pickers
	local skins = vgui.Create("Panel", box)
	local _pnl = tf.AddTFLabelToVGUI(skins, "#skin")
	_pnl:DockMargin(0,tf.betweencategories,0,0)
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
		[1] = {label = tf.GetPhrase("#TF_RedTeam_Name") or "RED", subtable = "visuals_red", col = tf.desc_colors.negative},
		[2] = {label = tf.GetPhrase("#TF_BlueTeam_Name") or "BLU", subtable = "visuals_blu", col = tf.desc_colors.positive},
	}
	for k, v in ipairs (_skins) do
		local num = tf.TFStyleVGUI("DNumberWang", skins, true)
		num:SetDecimals(0)
		num:SetMinMax(0, 255) //just assuming this is the max skin count, idk, this is what advbonemerge went with
		num:SetValue(k-1)
		num.FGColor = v.col
		skins["num" .. k] = num
		skins["label" .. k] = tf.AddTFLabelToVGUI(num, v.label)
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


	local box = AddBox(holder.columns[2], (tf.GetPhrase("#TF_ImportFile_IconLabel") or "Backpack Icon") .. ":")

	local bpcontainer = vgui.Create("Panel", box)
	bpcontainer:Dock(TOP)
	local mdl = tf.CreateItemIconModelPanel(bpcontainer)
	mdl.UseTurntableMovement = true
	editor.bp = mdl
	mdl:SetSize(tf.item_icon_sizes[2].w, tf.item_icon_sizes[2].h)
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
		//show mouseover border when hovered, because it's a useful helper for deciding icon size
		if self.Capturing or self:IsHovered() then
			BackpackItemMouseOverBorderUnscaled(0,0,w,h)
		else
			BackpackItemBorderUnscaled(0,0,w,h)
		end

		//due to the difference in aspect ratio, the rendertarget icons we generate for itemicons (which are 128x128 
		//internally) will always render at a different field of view compared to a 121x94 modelpanel like this one,
		//even if they're using the exact same tf.DrawItemModels function with the exact same pos, ang, and fov values.
		//i couldn't figure out the math to "translate" the modelpanel's fov value into one that would turn out the 
		//same as the rendertarget, so instead what we do here is emulate the itemicon's rendertarget code, by drawing 
		//our models onto an identical rendertarget in real time, and then drawing that onto this panel like a backpack
		//icon. this gives results that are 1-to-1 identical to the itemicon's rendertarget.
		if !mdl.models or !mdl.models[1] then return end
		local rt = GetRenderTarget("TF2ItemBrowser_EditorIconRT", 128, 128)
		if rt == nil or rtmat == nil then MsgN("Failed to create render target TF2ItemBrowser_EditorIconRT; out of memory?") return end
		//Render the icon texture
		render.PushRenderTarget(rt, 0, 0, 128, 128)
		render.OverrideAlphaWriteEnable(true, true)
		render.SetWriteDepthToDestAlpha(false)
		render.Clear(0, 0, 0, 0, true, true)
		tf.DrawItemModels(0, 0, 128, 128, mdl.models, {}, mdl.aLookAngle, mdl.vCamPos, mdl.fFOV)
		render.OverrideAlphaWriteEnable(false)
		render.PopRenderTarget()
		rtmat:SetTexture("$basetexture", rt)
		surface.SetMaterial(rtmat)
		//these panels are a bit shorter than they are wide, so cut off the bottom and top of the material to center it
		local diff = (1-(h/w))/2
		surface.DrawTexturedRectUV(0,0,w,h,0,0+diff,1,1-diff)
	end
	tf.AddTFButtonSounds(mdl, true) //hover sound only, not click
	mdl:DockMargin(0,0,8,0)
	mdl:Dock(LEFT)
	bpcontainer:SetHeight(mdl:GetTall())
	mdl.models = {}
	//equivalent of tf.GetItemModelVisuals function that populates models with the ones specified by the editor
	function mdl:GetItemModelVisuals()	
		local _, class = editor.bp_class:GetSelected()
		if class then
			class = tf.class_longname_to_id[editor.bp_class.options[class].Value]
		end
		local _, style = editor.bp_style:GetSelected()
		if style then
			style = editor.styles[editor.bp_style.options[style].Value + 1]
		end
		local skin = editor.skins.num1:GetValue()
		if style and style.skins:GetParent():IsVisible() then
			skin = style.skins.num1:GetValue()
		end

		local model, attached, wearable, wearable_2
		if style and class and style.class_models.classes[class]:GetParent():IsVisible() and style.class_models.classes[class]:GetText() != "" then
			model = style.class_models.classes[class]:GetText()
		elseif style and style.model:GetParent():IsVisible() and style.model:GetText() != "" then
			if class then
				model = string.Replace(style.model:GetText(), "%s", tf.classes[class].shortname)
			else
				model = style.model:GetText()
			end
		elseif class and editor.class_models.classes[class]:GetParent():IsVisible() and editor.class_models.classes[class]:GetText() != "" then
			model = editor.class_models.classes[class]:GetText()
		elseif editor.model:GetText() != "" then
			if class then
				model = string.Replace(editor.model:GetText(), "%s", tf.classes[class].shortname)
			else
				model = editor.model:GetText()
			end
		end
		for k, v in ipairs (editor.attached_models.entries) do
			if v:GetText() != "" then
				attached = attached or {}
				table.insert(attached, v:GetText())
			end
		end
		if editor.extra_wearables.entries[1] and editor.extra_wearables.entries[1]:GetText() != "" then
			wearable = editor.extra_wearables.entries[1]:GetText()
		end
		if editor.extra_wearables.entries[2] and editor.extra_wearables.entries[2]:GetText() != "" then
			wearable_2 = editor.extra_wearables.entries[2]:GetText()
		end

		return {class = class, style = style, skin = skin, item = model, attached = attached, wearable = wearable, wearable_2 = wearable_2}
	end
	function mdl:Refresh(cam_override)
		if !self.HasLoaded then return end

		local previously_had_model = IsValid(mdl.models[1])
		for k, v in ipairs (mdl.models) do
			if IsValid(v) then v:Remove() end
		end
		mdl.models = {}

		local vis = self:GetItemModelVisuals()
		local _, selected_mdl = editor.bp_mdl:GetSelected()
		if selected_mdl then
			selected_mdl = editor.bp_mdl.options[selected_mdl].Value
		end
		if !vis[selected_mdl] then selected_mdl = nil end

		if selected_mdl then
			local ent = ClientsideModel(vis[selected_mdl], RENDERGROUP_OTHER)
			if IsValid(ent) then
				ent:SetSkin(vis.skin)
				table.insert(mdl.models, ent)
				if selected_mdl == "item" then
					if vis.attached then
						for k, v in pairs (vis.attached) do
							local ent = ClientsideModel(v, RENDERGROUP_OTHER)
							if IsValid(ent) then
								ent:SetSkin(vis.skin)
								ent:SetParent(mdl.models[1])
								ent:AddEffects(EF_BONEMERGE)
								table.insert(mdl.models, ent)
							end
						end
					end
				end
			end
		end
		//Class model for preview, if enabled
		if editor.bp_showclass:GetChecked() and vis.class then
			local ent = ClientsideModel("models/player/" .. tf.classes[vis.class].shortname .. ".mdl", RENDERGROUP_OTHER)
			if IsValid(ent) then
				if mdl.models[1] then
					mdl.models[1]:SetParent(ent)
					mdl.models[1]:AddEffects(EF_BONEMERGE)
				end
				table.insert(mdl.models, 1, ent)
				for k, v in ipairs (bodygroups) do
					if editor.bodygroups.checks[k]:GetChecked() or (vis.style and vis.style.bodygroups:IsVisible() and vis.style.bodygroups.checks[k]:GetChecked()) then
						local val = 1
						local bg = v.bgs[tf.classes[vis.class].longname]
						if istable(bg) then 
							val = bg.val or 1
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
		for _, ent in pairs (mdl.models) do
			ent:SetNoDraw(true)
			ent:SetIK(false)
			//disable jigglebones
			for i = 0, ent:GetBoneCount() - 1 do
				ent:ManipulateBoneJiggle(i, 2)
			end
		end
		if mdl.models[1] then
			mdl.models[1]:SetAngles(Angle(editor.bp_mdlang:GetText()))
		end
		mdl.Entity = mdl.models[1]

		//Upon first loading, apply the values of the pos/ang/fov settings instead if applicable, without touching the old_cam stuff
		if cam_override then
			mdl:SetCamPos(Vector(cam_override.pos))
			mdl:SetFOV(cam_override.fov)
			mdl:SetLookAng(Angle(cam_override.ang))
		//Otherwise, we only want to reset the camera position when there was previously no model at all -
		//this means when the player enters a model for the first time, the camera gets moved into a useful position
		//to show up in the icon, but subsequently changing settings like class model or style won't clobber any
		//changes they make to the position.
		elseif !previously_had_model then
			editor.bp_buttons.buttons[1]:DoClick() //best guess
		end
	end
	//to avoid unnecessary Refresh calls as other elements are loading, make sure to do this last
	mdl.LoadOrder = 2
	editor.controls[mdl] = {
		Load = function(i)
			mdl.HasLoaded = true
			mdl:Refresh(i._customitem_bp)
		end
	}

	local entry = AddTextEntry(bpcontainer, "Entity Angles", nil, nil, true)
	editor.bp_mdlang = entry
	entry:GetParent():DockMargin(0,1,0,0) //+1 px at top makes the top and bottom of these 4 controls symmetrical, nice
	function entry:OnChange()
		if mdl.models[1] then
			mdl.models[1]:SetAngles(Angle(self:GetText()))
		end
	end
	editor.controls[entry] = { //make sure to save this as an angle, not a string
		Load = function(i)
			if i._customitem_bp and i._customitem_bp.mdlang then
				entry:SetText(tostring(i._customitem_bp.mdlang))
			else
				entry:SetText(tostring(Angle()))
			end
		end,
		Save = function(i)
			if entry:GetParent():IsVisible() then
				i._customitem_bp = i._customitem_bp or {}
				i._customitem_bp.mdlang = Angle(entry:GetText())
			end
		end
	}

	local entry = AddTextEntry(bpcontainer, "Camera Position", nil, nil, true)
	editor.bp_pos = entry
	entry:GetParent():DockMargin(0,4,0,0)
	function entry:OnChange()
		editor.bp:SetCamPos(Vector(self:GetText()))
	end
	editor.controls[entry] = { //make sure to save this as a vector, not a string
		Load = function(i)
			if i._customitem_bp and i._customitem_bp.pos then
				entry:SetText(tostring(i._customitem_bp.pos))
			end
		end,
		Save = function(i)
			if entry:GetParent():IsVisible() then
				i._customitem_bp = i._customitem_bp or {}
				i._customitem_bp.pos = Vector(entry:GetText())
			end
		end
	}

	local entry = AddTextEntry(bpcontainer, "Camera Angles", nil, nil, true)
	editor.bp_ang = entry
	entry:GetParent():DockMargin(0,4,0,0)
	function entry:OnChange()
		editor.bp:SetLookAng(Angle(self:GetText()))
	end
	editor.controls[entry] = { //make sure to save this as an angle, not a string
		Load = function(i)
			if i._customitem_bp and i._customitem_bp.ang then
				entry:SetText(tostring(i._customitem_bp.ang))
			end
		end,
		Save = function(i)
			if entry:GetParent():IsVisible() then
				i._customitem_bp = i._customitem_bp or {}
				i._customitem_bp.ang = Angle(entry:GetText())
			end
		end
	}

	local num = tf.TFStyleVGUI("DNumberWang", bpcontainer, true) //this space is too small for a slider like in gmod's spawnicon editor
	editor.bp_fov = num
	num:DockMargin(0,4,0,0)
	num:Dock(TOP)
	num:SetDecimals(2)
	num:SetMinMax(0.001, 179)
	num:SetPlaceholderText("Camera FOV")
	tf.AddTFStyleTooltip(num, "Camera FOV")
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

	local button_container = vgui.Create("Panel", box)
	editor.bp_buttons = button_container
	button_container.buttons = {}
	for k, v in ipairs ({
		{text = "Best Guess",
		icon = "icon32/wand.png",
		func = function()
			local cam = tf.DoItemModelCamera(editor.bp.models, nil, true) //nil icon panel arg here because there's no item data table to check yet; only consequence of this is that we can't use the item_camera attachment, which we don't want anyway
			editor.bp:SetCamPos(Vector(cam.pos)) //use copies of pos/ang, otherwise the values in old_cam will change as the camera moves
			editor.bp:SetFOV(cam.fov)
			editor.bp:SetLookAng(Angle(cam.ang))
		end},
		{text = "Front",
		icon = "icon32/hand_point_090.png",
		func = function()
			local campos = Vector(-200, 0, 0)
			editor.bp:SetCamPos(campos)
			editor.bp:SetFOV(45)
			editor.bp:SetLookAng((campos * -1):Angle())
		end},
		{text = "Above",
		icon = "icon32/hand_property.png",
		func = function()
			local campos = Vector(0, 0, 200)
			editor.bp:SetCamPos(campos)
			editor.bp:SetFOV(45)
			editor.bp:SetLookAng((campos * -1):Angle())
		end},
		{text = "Right",
		icon = "icon32/hand_point_180.png",
		func = function()
			local campos = Vector(0, 200, 0)
			editor.bp:SetCamPos(campos)
			editor.bp:SetFOV(45)
			editor.bp:SetLookAng((campos * -1):Angle())
		end},
		{text = "Center",
		icon = "icon32/hand_point_090.png",
		func = function()
			editor.bp:SetCamPos(vector_origin)
			editor.bp:SetFOV(45)
			editor.bp:SetLookAng(Angle( 0, -180, 0 ))
		end},
	}) do
		local button = tf.TFStyleVGUI("DImageButton", button_container)
		button_container.buttons[k] = button
		button:SetImage(v.icon)
		function button:PerformLayout()
			local size = math.min(self:GetSize()) - 4
			self.m_Image:SetSize(size,size)
			self.m_Image:Center()
		end
		function button:DoClick() v.func() end
		button:Dock(LEFT)
		if k > 1 then
			button:DockMargin(8,0,0,0)
		end
		tf.AddTFStyleTooltip(button, v.text)
	end
	function button_container:PerformLayout(w, h)
		w = (w - (8*4)) / 5
		for k, v in ipairs (button_container.buttons) do
			v:SetWide(w)
		end
		//self.label1:SetPos(0,0)
		//self.label2:SetPos(w+8,0)
	end
	button_container:SetTall(24)
	button_container:Dock(TOP)
	button_container:DockMargin(0,8,0,0)

	local drop = AddDropdown(box, "Class to show", "_customitem_bp", "class", {})
	editor.bp_class = drop
	function drop:OnSelect()
		editor.bp_mdl:UpdateVisibility()
		editor.bp:Refresh()
	end
	function drop:UpdateVisibility()
		local options = {}
		for i = 2, 10 do
			if editor.classes.checks[tf.classes[i].longname]:GetChecked() then
				table.insert(options, {
					Label = tf.GetPhrase(tf.classes[i].langstr) or string.NiceName(tf.classes[i].longname),
					Value = tf.classes[i].longname
				})
			end
		end
		drop:GetParent():SetVisible(#options > 1)
		editor.bp_showclass:SetVisible(#options > 0) //set this here as well
		drop:PopulateOptions(options)
		editor.bp_mdl:UpdateVisibility()
		editor.bp:Refresh()
	end
	//make sure to populate the drop's options first before loading, and to do that, we need to load the classes first, so wait for those to finish loading
	drop.LoadOrder = 1
	local old_Load = editor.controls[drop].Load
	editor.controls[drop].Load = function(i)
		drop:UpdateVisibility()
		old_Load(i)
	end

	local drop = AddDropdown(box, "Style to show", "_customitem_bp", "style", {})
	editor.bp_style = drop
	function drop:OnSelect()
		editor.bp_mdl:UpdateVisibility()
		editor.bp:Refresh()
	end
	function drop:UpdateVisibility()
		local options = {}
		for i, style in pairs (editor.styles) do
			local name = style.name:GetText()
			if name == "" then
				name = string.TrimRight(style.label:GetText(), ":")
			end
			table.insert(options, {
				Label = name,
				Value = i-1
			})
		end
		drop:GetParent():SetVisible(#options > 1)
		drop:PopulateOptions(options)
		editor.bp_mdl:UpdateVisibility()
		editor.bp:Refresh()
	end
	//make sure to populate the drop's options first before loading, and to do that, we need to load the styles first, so wait for those to finish loading
	drop.LoadOrder = 1
	local old_Load = editor.controls[drop].Load
	editor.controls[drop].Load = function(i)
		drop:UpdateVisibility()
		old_Load(i)
	end

	local drop = AddDropdown(box, "Model to show", "_customitem_bp", "mdl", {})
	editor.bp_mdl = drop
	function drop:OnSelect()
		editor.bp:Refresh()
	end
	function drop:UpdateVisibility()
		local options = {}
		local vis = editor.bp:GetItemModelVisuals()
		for k, v in ipairs ({"item", "wearable", "wearable_2"}) do
			if vis[v] then
				table.insert(options, {
					Label = string.NiceName(v),
					Value = v
				})
			end
		end
		drop:GetParent():SetVisible(#options > 1)
		drop:PopulateOptions(options)
		editor.bp:Refresh()
	end
	//make sure to populate the drop's options first before loading, and to do that, we need to load the models first, so wait for those to finish loading
	drop.LoadOrder = 1
	local old_Load = editor.controls[drop].Load
	editor.controls[drop].Load = function(i)
		drop:UpdateVisibility()
		old_Load(i)
	end

	local check = tf.TFStyleVGUI("DCheckBoxLabel", box)
	check:SetText("Show class model in icon")
	check:DockMargin(0,tf.betweenitems,0,0)
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

	local drop = AddDropdown(box, "Select sound", nil, "mouse_pressed_sound", {
		{
			Label = "Alien",
			Value = "ui/item_as_parasite_pickup.wav",
		},
		{
			Label = "Bag",
			Value = "ui/item_bag_pickup.wav",
		},
		{
			Label = "Bald head",
			Value = "ui/item_bald_head_pickup.wav",
		},
		{
			Label = "Bottle",
			Value = "ui/item_bottle_pickup.wav",
		},
		{
			Label = "Boxing gloves",
			Value = "ui/item_boxing_gloves_pickup.wav",
		},
		{
			Label = "Cardboard",
			Value = "ui/item_cardboard_pickup.wav",
		},
		{
			Label = "ConTracker",
			Value = "ui/item_contract_tracker_pickup.wav",
		},
		{
			Label = "Crate",
			Value = "ui/item_crate_pickup.wav",
		},
		{
			Label = "Default",
			Value = nil, //"ui/item_default_pickup.wav",
		},
		{
			Label = "Dueling Mini-Game",
			Value = "ui/item_dueling_pistols_pickup.wav",
		},
		{
			Label = "Gooey",
			Value = "ui/item_gooey_pickup.wav",
		},
		{
			Label = "Gun, heavy",
			Value = "ui/item_heavy_gun_pickup.wav",
		},
		{
			Label = "Gun, light",
			Value = "ui/item_light_gun_pickup.wav",
		},
		{
			Label = "Hat",
			Value = "ui/item_hat_pickup.wav",
		},
		{
			Label = "Helmet",
			Value = "ui/item_helmet_pickup.wav",
		},
		{
			Label = "Knife, large",
			Value = "ui/item_knife_large_pickup.wav",
		},
		{
			Label = "Knife, small",
			Value = "ui/item_knife_small_pickup.wav",
		},
		{
			Label = "Leather",
			Value = "ui/item_leather_pickup.wav",
		},
		{
			Label = "Medal",
			Value = "ui/item_medal_pickup.wav",
		},
		{
			Label = "Metal pot",
			Value = "ui/item_metal_pot_pickup.wav",
		},
		{
			Label = "Metal scrap",
			Value = "ui/item_metal_scrap_pickup.wav",
		},
		{
			Label = "Metal, tiny",
			Value = "ui/item_metal_tiny_pickup.wav",
		},
		{
			Label = "Metal weapon",
			Value = "ui/item_metal_weapon_pickup.wav",
		},
		{
			Label = "Night vision goggles",
			Value = "ui/item_nvg_pickup.wav",
		},
		{
			Label = "Pack",
			Value = "ui/item_pack_pickup.wav",
		},
		{
			Label = "Paint can",
			Value = "ui/item_paint_can_pickup.wav",
		},
		{
			Label = "Paper",
			Value = "ui/item_paper_pickup.wav",
		},
		{
			Label = "Pyroland",
			Value = "ui/item_mtp_pickup.wav",
		},
		{
			Label = "Robot arm",
			Value = "ui/item_robot_arm_pickup.wav",
		},
		{
			Label = "Rubber",
			Value = "ui/item_rubber_pickup.wav",
		},
		{
			Label = "Sandwich",
			Value = "ui/item_sandwich_drop.wav", //yes, pickup and drop are swapped for this one
		},
		{
			Label = "Shovel",
			Value = "ui/item_shovel_pickup.wav",
		},
		{
			Label = "Soda can",
			Value = "ui/item_soda_can_pickup.wav",
		},
		{
			Label = "Umbrella",
			Value = "ui/item_umbrella_pickup.wav",
		},
		{
			Label = "Watch",
			Value = "ui/item_watch_pickup.wav",
		},
		{
			Label = "Wooden pole",
			Value = "ui/item_wood_pole_pickup.wav",
		},
		{
			Label = "Wooden weapon",
			Value = "ui/item_wood_weapon_pickup.wav",
		},
	}, 9) //"default" by default
	drop:GetParent():DockMargin(0,tf.betweencategories,0,0)
	function drop:OnSelect()
		if drop.PlaySounds then
			local _, sel = drop:GetSelected()
			if sel then
				surface.PlaySound(drop.options[sel].Value or "ui/item_default_pickup.wav")
			end
		end
	end
	local old_OnMenuOpened = drop.OnMenuOpened
	function drop:OnMenuOpened(menu)
		drop:OnSelect()
		old_OnMenuOpened(self, menu)
	end
	local old_Load = editor.controls[drop].Load
	editor.controls[drop].Load = function(i)
		old_Load(i)
		drop.PlaySounds = true //don't play sound when selecting a value for the first time
	end

	local drop = AddDropdown(box, "Drop sound", nil, "drop_sound", {
		{
			Label = "Alien",
			Value = "ui/item_as_parasite_drop.wav",
		},
		{
			Label = "Bag",
			Value = "ui/item_bag_drop.wav",
		},
		{
			Label = "Bald head",
			Value = "ui/item_bald_head_pickup.wav",
		},
		{
			Label = "Bottle",
			Value = "ui/item_bottle_drop.wav",
		},
		{
			Label = "Boxing gloves",
			Value = "ui/item_boxing_gloves_drop.wav",
		},
		{
			Label = "Cardboard",
			Value = "ui/item_cardboard_drop.wav",
		},
		{
			Label = "ConTracker",
			Value = "ui/item_contract_tracker_drop.wav",
		},
		{
			Label = "Crate",
			Value = "ui/item_crate_drop.wav",
		},
		{
			Label = "Default",
			Value = nil, //"ui/item_default_drop.wav",
		},
		{
			Label = "Gooey",
			Value = "ui/item_gooey_pickup.wav",
		},
		{
			Label = "Gun, heavy",
			Value = "ui/item_heavy_gun_drop.wav",
		},
		{
			Label = "Gun, light",
			Value = "ui/item_light_gun_drop.wav",
		},
		{
			Label = "Hat",
			Value = "ui/item_hat_drop.wav",
		},
		{
			Label = "Helmet",
			Value = "ui/item_helmet_drop.wav",
		},
		{
			Label = "Leather",
			Value = "ui/item_leather_pickup.wav",
		},
		{
			Label = "Medal",
			Value = "ui/item_medal_pickup.wav",
		},
		{
			Label = "Metal pot",
			Value = "ui/item_metal_pot_drop.wav",
		},
		//"ui/item_metal_pot_pickup.wav", //only used as drop sound by 31035 The Dumb Bell because it's sort of bell-like
		{
			Label = "Metal scrap",
			Value = "ui/item_metal_scrap_drop.wav",
		},
		{
			Label = "Metal, tiny",
			Value = "ui/item_metal_tiny_drop.wav",
		},
		{
			Label = "Metal weapon",
			Value = "ui/item_metal_weapon_drop.wav",
		},
		{
			Label = "Pack",
			Value = "ui/item_pack_drop.wav",
		},
		//"ui/item_pack_pickup.wav", //only used as drop sound by 5611 Voodoo-Cursed Bag Of Quicklime, might be a mistake
		{
			Label = "Paint can",
			Value = "ui/item_paint_can_pickup.wav",
		},
		{
			Label = "Paper",
			Value = "ui/item_paper_pickup.wav",
		},
		{
			Label = "Pyroland",
			Value = "ui/item_mtp_drop.wav",
		},
		{
			Label = "Robot arm",
			Value = "ui/item_robot_arm_drop.wav",
		},
		{
			Label = "Rubber",
			Value = "ui/item_rubber_pickup.wav",
		},
		{
			Label = "Sandwich",
			Value = "ui/item_sandwich_pickup.wav", //yes, pickup and drop are swapped for this one
		},
		{
			Label = "Shovel",
			Value = "ui/item_shovel_drop.wav",
		},
		{
			Label = "Soda can",
			Value = "ui/item_soda_can_drop.wav",
		},
		{
			Label = "Umbrella",
			Value = "ui/item_umbrella_pickup.wav",
		},
		{
			Label = "Watch",
			Value = "ui/item_watch_drop.wav",
		},
		{
			Label = "Wooden pole",
			Value = "ui/item_wood_pole_drop.wav",
		},
		{
			Label = "Wooden weapon",
			Value = "ui/item_wood_weapon_drop.wav",
		},
	}, 9) //"default" by default
	function drop:OnSelect()
		if drop.PlaySounds then
			local _, sel = drop:GetSelected()
			if sel then
				surface.PlaySound(drop.options[sel].Value or "ui/item_default_drop.wav")
			end
		end
	end
	local old_OnMenuOpened = drop.OnMenuOpened
	function drop:OnMenuOpened(menu)
		drop:OnSelect()
		old_OnMenuOpened(self, menu)
	end
	local old_Load = editor.controls[drop].Load
	editor.controls[drop].Load = function(i)
		old_Load(i)
		drop.PlaySounds = true //don't play sound when selecting a value for the first time
	end


	local button = tf.TFStyleVGUI("DButton", holder.columns[3])
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

		local box = AddBox(holder.columns[3], tf.GetNumberedStyleString(1) .. ":")
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
		text_holder:DockMargin(-8,-8,0,box.label:GetTall()-text_holder:GetTall())
		box.label:SetParent(text_holder)
		box.label:DockMargin(0,0,0,0)
		box.label:Dock(FILL)
		box.label:SetText(tf.GetNumberedStyleString(i) .. ":")
		local close = vgui.Create("DButton", text_holder)
		close:SetText("")
		close:SetSize(22,22)
		close:Dock(RIGHT)
		close:DockMargin(5,0,5,0)
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
			table.remove(editor.styles, table.KeyFromValue(editor.styles, box))
			close:Remove()
			box:Remove()
			for i, style in ipairs (editor.styles) do
				style.label:SetText(tf.GetNumberedStyleString(i) .. ":")
			end
			//update backpack icon style selector
			editor.bp_style:UpdateVisibility()
			//update backpack icon, just in case we removed the style it was using
			editor.bp_mdl:UpdateVisibility()
			editor.bp:Refresh()
		end


		local entry = AddTextEntry(box, "Style name")
		entry:GetParent():DockMargin(0,tf.betweenitems,side_margin,0)
		box.name = entry
		function entry:OnEnter()
			//update backpack icon style selector
			editor.bp_style:UpdateVisibility()
		end


		local check = tf.TFStyleVGUI("DCheckBoxLabel", box)
		check:SetText("Change models?")
		check:DockMargin(0,tf.betweencategories,side_margin,0)
		check:Dock(TOP)
		box.model_check = check
		function check:OnChange(val)
			box:UpdateVisibility()
			editor.bp_mdl:UpdateVisibility()
			editor.bp:Refresh()
		end

		//Base model
		local entry = AddTextEntry(box, "Item model path")
		entry:GetParent():DockMargin(0,tf.betweenitems,side_margin,0)
		box.model = entry
		function entry:OnEnter()
			editor.bp_mdl:UpdateVisibility()
			editor.bp:Refresh()
		end

		//Per-class models - gate these behind a checkbox that also only appears if multiple classes are selected
		local check = tf.TFStyleVGUI("DCheckBoxLabel", box)
		check:SetText("Class-specific model paths?")
		check:DockMargin(0,tf.betweenitems,side_margin,0)
		check:Dock(TOP)
		box.class_models = check
		check.classes = {}
		function check:OnChange(val)
			box:UpdateVisibility()
		end
		for i = 2, 10 do
			local entry = AddTextEntry(box, tf.GetPhrase(tf.classes[i].langstr) or string.NiceName(tf.classes[i].longname))
			entry:GetParent():DockMargin(0,tf.betweenitems,side_margin,0)
			check.classes[i] = entry
			function entry:OnEnter()
				editor.bp_mdl:UpdateVisibility()
				editor.bp:Refresh()
			end
		end


		local check = tf.TFStyleVGUI("DCheckBoxLabel", box)
		check:SetText("Change skins?")
		check:DockMargin(0,tf.betweencategories,side_margin,0)
		check:Dock(TOP)
		box.skins_check = check
		function check:OnChange(val)
			box:UpdateVisibility()
		end

		//Skin id pickers
		local skins = vgui.Create("Panel", box)
		local _pnl = tf.AddTFLabelToVGUI(skins, "#skin")
		_pnl:DockMargin(0,tf.betweenitems,side_margin,0)
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
			local num = tf.TFStyleVGUI("DNumberWang", skins, true)
			num:SetDecimals(0)
			num:SetMinMax(0, 255) //just assuming this is the max skin count, idk, this is what advbonemerge went with
			num:SetValue(k-1)
			num.FGColor = v.col
			skins["num" .. k] = num
			skins["label" .. k] = tf.AddTFLabelToVGUI(num, v.label)
			if k == 1 then
				function num:OnValueChanged()
					editor.bp:Refresh()
				end
			end
		end


		local check = tf.TFStyleVGUI("DCheckBoxLabel", box)
		check:SetText("Set additional bodygroups?")
		check:DockMargin(0,tf.betweencategories,side_margin,0)
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
			local check = tf.TFStyleVGUI("DCheckBoxLabel", box.bodygroups.columns[math.fmod(k-1, 2)+1])
			check:Dock(TOP)
			check:DockMargin(0,tf.betweenitems,0,0)
			check:SetText(v.label)
			box.bodygroups.checks[k] = check
			function check:OnChange(val)
				//update backpack icon, in case we're using a visible class model there
				editor.bp:Refresh()
			end
			//make sure user can read the text if it's cut off
			tf.AddTFStyleTooltip(check.Label, check:GetText())
			local old_IsHovered = check.Label.IsHovered
			function check.Label:IsHovered(...)
				return old_IsHovered(self, ...) or check:IsHovered(...)
			end
		end


		//Toggle to disable genteel smoke effect
		local check = tf.TFStyleVGUI("DCheckBoxLabel", box)
		check:SetText("Disable " .. (tf.GetPhrase("#Attrib_Particle28") or "Genteel Smoke") .. " effect")
		check:DockMargin(0,tf.betweencategories,side_margin,0)
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
				box.class_models.classes[i]:GetParent():SetVisible(box.model_check:GetChecked() and box.class_models:GetChecked() and editor.classes.checks[tf.classes[i].longname]:GetChecked() and selected_class_count > 1)
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
			editor.bp_mdl:UpdateVisibility()
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
							if v.model_player_per_class[tf.classes[i2].longname] then
								style.class_models:SetChecked(true)
								style.class_models.classes[i2]:SetText(v.model_player_per_class[tf.classes[i2].longname])
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
								style.bodygroups_check:SetChecked(true)
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
						tab2.model_player_per_class[tf.classes[k].longname] = v:GetText()
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
								if bg.forced then
									for k2, v2 in pairs (bg.forced) do
										tab2.additional_forced_bodygroups = tab2.additional_forced_bodygroups or {}
										tab2.additional_forced_bodygroups[k2] = v2
									end
								end
								val = bg.val or 1
								bg = bg.name
							end
							tab2.additional_hidden_bodygroups[bg] = val
						end
					end
				end
				if style.disable_genteel_smoke:IsVisible() and style.disable_genteel_smoke:GetChecked() then
					tab2.use_smoke_particle_effect = 0
				end
				//add the style even if it's empty; users might use one empty "default" style 
				//and another non-default style to add a selection between both options
				tab[i2-1] = tab2
			end
			if table.Count(tab) > 0 then
				i.visuals = i.visuals or {}
				i.visuals.styles = tab
			end
		end,
	}


	//load each control; controls that need to load in a certain order (i.e. backpack icon preview) 
	//can include a LoadOrdervalue to ensure that they load after all the controls with a lower value
	local i = tf.TF2Items.items[id] or {}
	local queuedloads = {}
	editor.LoadOrder = 0
	for pnl, funcs in pairs (editor.controls) do
		if funcs.Load then
			queuedloads[pnl] = funcs.Load
		end
	end
	while table.Count(queuedloads) > 0 do
		if editor.LoadOrder == 10 then MsgN("TF2ItemBrowser_Editor load order screwed up somehow, bailing") break end
		for pnl, Load in pairs (queuedloads) do
			if !pnl.LoadOrder or editor.LoadOrder >= pnl.LoadOrder then
				//MsgN(editor.LoadOrder, " ", pnl.LoadOrder or 0, " loaded ", pnl)
				Load(i)
				queuedloads[pnl] = nil
			end
		end
		editor.LoadOrder = editor.LoadOrder + 1
	end
	//if we're loading an existing file, then pressing the save button should default to saving to the same file that was loaded
	editor.SavedName = id or ""

end

vgui.Register("TF2ItemBrowser_Editor", PANEL, "DFrame")