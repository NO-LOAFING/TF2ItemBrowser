local classes = {"any", "scout", "soldier", "pyro", "demoman", "heavy", "engineer", "medic", "sniper", "spy", "none"}
//our favorite black scottish cyclops is called "demoman" in all item definition keys (used_by_classes, model_player_per_class, etc.), 
//"demo" in model paths, and either one interchangably in equip region names. dumb!!!
for k, v in ipairs (classes) do
	local shortname = v
	if v == "demoman" then shortname = "demo" end
	classes[k] = {shortname = shortname, longname = v}
end


local _s = file.Read("scripts/items/items_game.txt", "tf")
local s = util.KeyValuesToTable(_s)


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

for k, v in pairs (s.items) do
	//clear useless items
	if v.equip_type == "account" then //contracts
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
							table.insert(tab[class.longname], v3.Key)
							break
						end
					end
						
				end
			else
				table.insert(tab["any"], v2.Key)
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

			local iconlist = vgui.Create("DIconLayout", scroll)
			iconlist:Dock(FILL)
			iconlist:SetSpaceY(5)
			iconlist:SetSpaceX(5)
			iconlist.OnChildAdded = nil //this gets called way too many times per frame when adding new icons https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/diconlayout.lua#L138-L151
			

			--[[local filters_holder = window:Add("DPanel")
			filters_holder:DockPadding(8,8,8,8)
			filters_holder:SetWidth(100)
			filters_holder:Dock(LEFT)]]

			local filters = window:Add("DPanel")
			//filters:DockPadding(8,8,8,8)
			filters:DockPadding(24,24,24,24)
			filters:SetWidth(220)
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
				//TODO
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
			check:DockMargin(0,0,0,betweenitems)
			filters.team = check
			check.OnChange = function(_, val)
				//TODO
			end

			local drop = vgui.Create("Panel", filters)
			drop.Label = vgui.Create("DLabel", drop)
			drop.Label:SetText("Class")
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
			for _, kv in ipairs (classes) do //if we don't have an "any" option then we don't have to worry about picking the current class model to spawn from a dropdown, hmm
				drop.Combo:AddChoice(string.NiceName(kv.longname), kv)
			end
			filters.class = drop.Combo
			function drop.Combo.OnSelect(_, index, value, data)
				//TODO
			end

			local drop = vgui.Create("Panel", filters)
			drop.Label = vgui.Create("DLabel", drop)
			drop.Label:SetText("Item Type")
			drop.Label:Dock(LEFT)
			drop.Combo = vgui.Create("DComboBox", drop)
			drop.Combo:SetHeight(25)
			drop.Combo:Dock(FILL)
			drop:SetHeight(25)
			drop:Dock(TOP)
			drop:DockMargin(0,0,0,betweencategories)
			function drop.PerformLayout(_, w, h)
				drop.Label:SetWide(w / 2.4)
			end
			drop.Combo:SetSortItems(false)
			for _, kv in ipairs ({"any", "weapon", "cosmetic", "taunt", "other"}) do
				drop.Combo:AddChoice(string.NiceName(kv), kv)
			end
			filters.type = drop.Combo
			function drop.Combo.OnSelect(_, index, value, data)
				//TODO
			end

			local cat = vgui.Create("DCollapsibleCategory", filters)
			cat:SetLabel("Equip Regions")
			cat:Dock(TOP)
			cat:DockMargin(0,0,0,betweencategories)
			local pnl = vgui.Create("DPanel", cat) //stupid buffer panel to stop DCollapsibleCategory from forcibly running SizeToContents on container, overriding its desired height
			pnl:Dock(TOP)
			pnl.Paint = function() end
			local container = vgui.Create("DScrollPanel", pnl)
			container:Dock(TOP)
			container:SetTall(300)
			container:GetCanvas():DockPadding(4,4,4,4)
			pnl:SizeToContents()
			filters.equip_regions = {}
			for _, class in ipairs (classes) do
				for k, v in ipairs (TF2Items.equip_regions_list[class.longname]) do
					//TODO: when a class is selected, rebuild this list, and don't add checkboxes for classes that are filtered out
					local check = vgui.Create("DCheckBoxLabel", container) //TODO: should use a variant of checkboxes with both (+ (must include)) and (- (must exclude)) options
					check:SetText(string.NiceName(v))
					check:SetHeight(15)
					check:Dock(TOP)
					check:DockMargin(0,0,0,betweenitems)
					container:AddItem(check)
					filters.equip_regions[v] = check
					check.OnChange = function(_, val)
						//TODO
					end
				end
			end
			cat:SetContents(pnl)

			local check = vgui.Create("DCheckBoxLabel", filters) //TODO: should use a variant of checkboxes with both (+ (must include)) and (- (must exclude)) options
			check:SetText("Holiday-Restricted")
			check:SetHeight(15)
			check:Dock(TOP)
			check:DockMargin(0,0,0,betweenitems)
			filters.holiday = check
			check.OnChange = function(_, val)
				//TODO
			end

			local check = vgui.Create("DCheckBoxLabel", filters) //TODO: should use a variant of checkboxes with both (+ (must include)) and (- (must exclude)) options
			check:SetText("Paintable")
			check:SetHeight(15)
			check:Dock(TOP)
			check:DockMargin(0,0,0,betweenitems)
			filters.paint = check
			check.OnChange = function(_, val)
				//TODO
			end

			local check = vgui.Create("DCheckBoxLabel", filters) //TODO: should use a variant of checkboxes with both (+ (must include)) and (- (must exclude)) options
			check:SetText("War Paintable")
			check:SetHeight(15)
			check:Dock(TOP)
			check:DockMargin(0,0,0,betweencategories)
			filters.warpaint = check
			check.OnChange = function(_, val)
				//TODO
			end

			local check = vgui.Create("DCheckBoxLabel", filters) //TODO: should use a variant of checkboxes with both (+ (must include)) and (- (must exclude)) options
			check:SetText("Custom Items")
			check:SetHeight(15)
			check:Dock(TOP)
			check:DockMargin(0,0,0,betweenitems)
			filters.custom = check
			check.OnChange = function(_, val)
				//TODO
			end

			local button = vgui.Create("DButton", filters)
			button:SetText("Add custom item...")
			button:SetHeight(20)
			button:Dock(TOP)
			button:DockMargin(0,0,0,0)
			button.DoClick = function()
				//TODO
			end













			local function RebuildIconList()
				window.icons = {}
				window.icons_to_add = {}
				for k, v in pairs (TF2Items.items) do
					//test, this makes testing faster because it filters out >60% of items; TODO: apply proper filters here eventually
					if v.equip_regions and v.equip_regions.medal then continue end

					table.insert(window.icons_to_add, k)
				end
				window.icons_to_add_key = 1
			end
			RebuildIconList()

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
							item:SetItemID(v)
							self.icons[v] = item
						else
							//We've gone through the whole table, so we're done here, get rid of it
							self.icons_to_add = nil
							self.icons_to_add_key = nil
							break
						end
					end
					//MsgN("self.icons_to_add_key = ", self.icons_to_add_key)
					if self.icons_to_add_key then self.icons_to_add_key = self.icons_to_add_key + iconsperframe end
					//iconlist:Layout()
					scroll:InvalidateLayout()
				end

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
				old_Think(self, ...)
			end



		end
	})




	local PANEL = {}

	AccessorFunc(PANEL, "m_iItemID", "ItemID" )

	local scale = 64/121 //tf2 backpack panels are 121 wide, ours are 64
	function PANEL:Init()

		self:SetSize(64,94*scale)//64*(94/121)) //tf2 backpack panels are 121x94 (???)
		self:SetDoubleClickingEnabled(false)
		self:SetText("")

	end

	function PANEL:SetItemID(i)

		self.m_iItemID = i

		self.ImageToQueue = TF2Items.items[i].image_inventory

		//test
		self:SetTooltip(TF2Items.items[i].name)
		
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

	local BackpackItemBorder = GWEN_CreateTextureBorderScaled(0, 0, 256, 128, 24, 24, 24, 24, Material("vgui/backpack_rect.vmt"), scale)
	local BackpackItemMouseOverBorder = GWEN_CreateTextureBorderScaled(0, 0, 256, 128, 24, 24, 24, 24, Material("vgui/backpack_rect_mouseover.vmt"), scale)
	local BackpackItemSelectedBorder = GWEN_CreateTextureBorderScaled(0, 0, 256, 128, 24, 24, 24, 24, Material("vgui/backpack_rect_selected.vmt"), scale)
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
		end

	end

	function PANEL:DoClick()

		//test
		PrintTable(TF2Items.items[self:GetItemID()])

	end

	vgui.Register("TF2ItemIcon", PANEL, "DButton")

end