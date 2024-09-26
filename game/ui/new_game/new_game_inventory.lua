-- new_game_inventory.lua (12/2014)
-- inventory functionality for the new game ui
local GetTrigger = LuaTrigger.GetTrigger
local interface = object

local function createInventory()
	local inventoryContainers = object:GetGroup('gameInventoryContainers')
	
	local systemTrigger = LuaTrigger.GetTrigger('System')
	if systemTrigger.use54 then
		print ("Using 5:4\n")
		
		for k,v in ipairs(inventoryContainers) do
			v:Instantiate('gameInventory54')
		end
	else
		print ("Using 16:9\n")
		for k,v in ipairs(inventoryContainers) do
			v:Instantiate('gameInventory169')
		end
	end
end
createInventory()

-- Updates the position of the inventory
function updateInventoryPosition()
	local swapSides = 1
	
	if GetCvarBool('ui_swapMinimap') then
		swapSides = -1
	end
	
	local object = gameGetInterface()
	
	local inventoryParent			= object:GetWidget('gameInventoryAnimation')
	local inventoryContainers		= object:GetGroup('gameInventoryContainers')
	
	local flippedContainers			= object:GetGroup('flippedContainers')
	local standardContainers		= object:GetGroup('standardContainers')
	
	local systemTrigger = LuaTrigger.GetTrigger('System')
	local padding = libGeneral.HtoP(0.6)
	
	for k,v in ipairs(inventoryContainers) do
		if (swapSides == 1) then
			v:SetAlign('left')
		else
			v:SetAlign('right')
		end
	end
	
	for k,v in ipairs(flippedContainers) do
		if (swapSides == 1) then
			v:SetVisible(false)
		else
			v:SetVisible(true)
		end
	end
	
	for k,v in ipairs(standardContainers) do
		if (swapSides == 1) then
			v:SetVisible(true)
		else
			v:SetVisible(false)
		end
	end
	
	if (swapSides == 1) then		
		inventoryParent:SetAlign('left')
		inventoryParent:SetX('16.5h')
	else		
		inventoryParent:SetAlign('right')
		inventoryParent:SetX('-17h')
	end
end
updateInventoryPosition()

-- register the inventory slots including boots and consumables
function registerInventory()
	libGeneral.createGroupTrigger('inventoryDragInfo', { 'globalDragInfo.active', 'globalDragInfo.type', 'PlayerCanShop.playerCanShop'})
	
	local consumableIndex = { 103, 104 }
	local bootsIndex = 96
	local backpackIndex = { 97, 98, 99, 100, 101, 102 }

	local function registerInventoryFlip()
		local params = { }

		local count = 1
		for i, index in ipairs(backpackIndex) do
			params[count + 0] = 'ActiveInventory' .. index .. '.exists'
			params[count + 1] = 'ActiveInventory' .. index .. '.isActivatable'
			count = count + 2
		end

		params[count + 0] = 'ModifierKeyStatus.moreInfoKey'
		params[count + 1] = 'gamePanelInfo.shopOpen'

		local inventoryFlipTrigger = libGeneral.createGroupTrigger('inventoryFlip', params)
		object:RegisterWatchLua('inventoryFlip', function(widget, t)
			local item1 = t['ActiveInventory' .. backpackIndex[1]]
			local item2 = t['ActiveInventory' .. backpackIndex[2]]
			local item3 = t['ActiveInventory' .. backpackIndex[3]]
			local item4 = t['ActiveInventory' .. backpackIndex[4]]
			local item5 = t['ActiveInventory' .. backpackIndex[5]]
			local item6 = t['ActiveInventory' .. backpackIndex[6]]

			local moreInfo = t['ModifierKeyStatus'].moreInfoKey
			local shopOpen = t['gamePanelInfo'].shopOpen
			
			-- Doing my thaaaaaang
			-- Actually we're not going to do my thaaaaaang :( bummer dudes and gals
			-- local screenType = '169'
			-- local column1	 = 1
			-- local column2	 = 2
			-- local column3	 = 3
			
			-- local systemTrigger = LuaTrigger.GetTrigger('System')
			-- if systemTrigger.use54 then
				-- screenType = '54'
				
				-- if GetCvarBool('ui_swapMinimap') then
					-- column1	 = 3
					-- column2	 = 4
				-- end
				
				-- local column01 = widget:GetWidget('inventory'..screenType..'_column'..column1)
				-- local column02 = widget:GetWidget('inventory'..screenType..'_column'..column2)
				
				-- if (item1.exists and item1.isActivatable) or (item2.exists and item2.isActivatable) or (item3.exists and item3.isActivatable) or moreInfo or shopOpen then
					-- column01:SetVisible(true)
				-- else
					-- column01:SetVisible(false)
				-- end
				
				-- if (item4.exists and item4.isActivatable) or (item5.exists and item5.isActivatable) or (item6.exists and item6.isActivatable) or moreInfo or shopOpen then
					-- column02:SetVisible(true)
				-- else
					-- column02:SetVisible(false)
				-- end
			-- else
				-- if GetCvarBool('ui_swapMinimap') then
					-- column1	 = 4
					-- column2	 = 5
					-- column3	 = 6
				-- end
				
				-- local column01 = widget:GetWidget('inventory'..screenType..'_column'..column1)
				-- local column02 = widget:GetWidget('inventory'..screenType..'_column'..column2)
				-- local column03 = widget:GetWidget('inventory'..screenType..'_column'..column3)
				
				-- if (item1.exists and item1.isActivatable) or (item2.exists and item2.isActivatable) or moreInfo or shopOpen then
					-- column01:SetVisible(true)
				-- else
					-- column01:SetVisible(false)
				-- end
				
				-- if (item3.exists and item3.isActivatable) or (item4.exists and item4.isActivatable) or moreInfo or shopOpen then
					-- column02:SetVisible(true)
				-- else
					-- column02:SetVisible(false)
				-- end
				
				-- if (item5.exists and item5.isActivatable) or (item6.exists and item6.isActivatable) or moreInfo or shopOpen then
					-- column03:SetVisible(true)
				-- else
					-- column03:SetVisible(false)
				-- end
			-- end
			
		end, true, nil)

	end

	local function registerInventorySlot(trigger, slotPrefix, isConsumable, isBoots, index)
		local inventorySlot 		= object:GetWidget(slotPrefix)
		local inventoryParent 		= object:GetWidget(slotPrefix .. '_parent')
		local inventoryButton 		= object:GetWidget(slotPrefix .. '_button')
		local inventoryIcon 		= object:GetWidget(slotPrefix .. '_icon')
		local inventoryCooldownText = object:GetWidget(slotPrefix .. 'Cooldown')
		local inventoryCooldownPie 	= object:GetWidget(slotPrefix .. 'CooldownPie')
		local inventoryDrag 		= object:GetWidget(slotPrefix .. '_drag')
		local inventoryDrop 		= object:GetWidget(slotPrefix .. 'Drop')
		local inventoryDropTarget	= object:GetWidget(slotPrefix .. 'DragTarget')
		local craftedIcon			= object:GetWidget(slotPrefix .. 'Crafted')
		local craftedBorder			= object:GetWidget(slotPrefix .. 'CraftedBorder')
		local chargesPanel 			= object:GetWidget(slotPrefix .. '_charges')
		local chargesCount 			= object:GetWidget(slotPrefix .. '_chargesCount')
		local moreInfoIcon			= object:GetWidget(slotPrefix .. 'MagnifierMoreInfo')
		
		local inventoryHotkey 		= object:GetWidget(slotPrefix .. 'Key')
		
		inventoryDrop:RegisterWatchLua('ItemCursorVisible', function(widget, trigger)
			widget:SetVisible(trigger.cursorVisible and trigger.hasItem)
		end)	
		
		if isStash then
			inventoryDrop:SetCallback('onclick', function(widget)
				ItemPlaceStash(index)
			end)
		else
			inventoryDrop:SetCallback('onclick', function(widget)
				ItemPlace(index)
			end)
		end		
		
		inventoryDropTarget:SetCallback('onmouseover', function(widget)
			globalDraggerReadTarget(widget, function()
				local dragInfo	= GetTrigger('globalDragInfo')
				local dragType	= dragInfo.type
				
				if dragType == 3 then		-- From Bookmarks
					Shop.PurchaseRemainingComponents(
						GetTrigger('BookmarkQueue'..trigger_gamePanelInfo.shopLastBuyQueueDragged).entity
					)
				elseif dragType == 5 then	-- From regular backpack slot (swapping slots)
					local sourceIndex = trigger_gamePanelInfo.draggedInventoryIndex
					SecondaryAction(sourceIndex)
					ItemPlace(index)
				elseif dragType == 4 then	-- From Shop Items
					Shop.PurchaseRemainingComponents(trigger_gamePanelInfo.shopDraggedItem)
				elseif dragType == 6 then	-- From Stash
					local sourceIndex = trigger_gamePanelInfo.draggedInventoryIndex
					SecondaryActionStash(sourceIndex)
					ItemPlace(index)
				end
			end)
		end)		

		inventoryDropTarget:RegisterWatchLua('inventoryDragInfo', function(widget, groupTrigger)
			local dropType	= groupTrigger['globalDragInfo'].type
			local active 	= groupTrigger['globalDragInfo'].active
			local canShop 	= groupTrigger['PlayerCanShop'].playerCanShop

			widget:SetVisible(active and ((canShop and (((dropType == 3 or dropType == 4) and not trigger_gamePanelInfo.shopDraggedItemOwnedRecipe) or dropType == 6)) or dropType == 5))
		end)

		
		moreInfoIcon:RegisterWatchLua('ModifierKeyStatus', function(widget, modifierKeyStatusTrigger)
			local slotTrigger = LuaTrigger.GetTrigger(trigger)
			widget:SetVisible(modifierKeyStatusTrigger.moreInfoKey and slotTrigger.exists)			
		end, true, nil, 'moreInfoKey')
		
		moreInfoIcon:SetCallback('onclick', function(widget)
			ToggleShop()
		end)
		
		if isConsumable or isBoots then
			local inventoryVisTrigger = libGeneral.createGroupTrigger(slotPrefix .. "slotVis", { trigger .. '.exists', 'ModifierKeyStatus.moreInfoKey', 'gamePanelInfo.shopOpen'})
			inventorySlot:RegisterWatchLua(slotPrefix .. 'slotVis', function(widget, t)
				local exists = t[trigger].exists
				local isActivatable = t[trigger].isActivatable
				local moreInfo = t['ModifierKeyStatus'].moreInfoKey
				local shopOpen = t['gamePanelInfo'].shopOpen				

				widget:FadeIn(200)
				
				if isActivatable and exists then
					inventoryHotkey:SetVisible(true)
				else
					inventoryHotkey:SetVisible(false)
				end
			end, true, nil)
		else
			local inventoryVisTrigger = libGeneral.createGroupTrigger(slotPrefix .. "slotVis", { trigger .. '.exists', 'ModifierKeyStatus.moreInfoKey', 'gamePanelInfo.shopOpen'})
			inventorySlot:RegisterWatchLua(slotPrefix .. 'slotVis', function(widget, t)
				local exists = t[trigger].exists
				local isActivatable = t[trigger].isActivatable
				local moreInfo = t['ModifierKeyStatus'].moreInfoKey
				local shopOpen = t['gamePanelInfo'].shopOpen				

				-- Not doing my thaaaaaang
				-- if (exists and isActivatable) or moreInfo or shopOpen then
					-- widget:SetVisible(true)
					widget:FadeIn(200)
					inventoryHotkey:SetVisible((exists and isActivatable))
				-- else
					-- widget:SetVisible(false)
					-- inventoryHotkey:SetVisible(false)
				-- end
			end, true, nil)		
		end

		gameHelper.registerWatchTexture(inventoryIcon, trigger, 'icon')		
		inventoryButton:RegisterWatchLua(trigger, function(widget, trigger)
				local icon = trigger.icon
				local exists = trigger.exists
				widget:SetVisible(icon ~= "" and icon ~= nil and exists)
			end, true, nil, 'icon', 'exists')

		-- register the charge count 
		chargesPanel:RegisterWatchLua(trigger, function(widget, trigger)
			local charges = trigger.charges
			
			if trigger.exists and charges > 0  then
				chargesPanel:SetVisible(true)
				chargesCount:SetText(charges)
			else
				chargesPanel:SetVisible(false)
			end
		end, true, nil, 'charges', 'exists')

		-- register the backpack recently purchased icon
		local bag = object:GetWidget(slotPrefix .. '_bag')
		bag:RegisterWatchLua(trigger, function(widget, trigger)
			bag:SetVisible(trigger.exists and trigger.purchasedRecently)
		end, true, nil, 'purchasedRecently', 'exists')


		-- register the key
		inventoryHotkey:RegisterWatchLua('ActiveInventory' .. index, function(widget, trigger)
			if (not isBoots and not isConsumable) then
				local bindIndex = LuaTrigger.GetTrigger('ActiveInventory' .. index).activatableBindNumber + 1
				gameHelper.registerBindKey(slotPrefix..'Key', 'ActiveInventory' .. index, 'ActivateUsableItem', bindIndex, true, true)
			else
				local bindIndex = LuaTrigger.GetTrigger('ActiveInventory' .. index).activatableBindNumber + 1
				gameHelper.registerBindKey(slotPrefix..'Key', 'ActiveInventory' .. index, 'ActivateTool', index, true, false)
			end
		end, true, nil, 'activatableBindNumber')
		
		-- register the button 
		inventoryButton:RegisterWatchLua('ActiveInventory' .. index, function(widget, trigger)
			local isActivatable = trigger.isActivatable and trigger.exists

			widget:SetCallback('onclick', function(widget)
				if LuaTrigger.GetTrigger('ModifierKeyStatus').moreInfoKey then
					local inventoryInfo = LuaTrigger.GetTrigger('ActiveInventory'..index)
					local isRecipeCompleted = inventoryInfo.isRecipeCompleted
					local shopActive = LuaTrigger.GetTrigger('ShopActive').isActive
					if (not isRecipeCompleted) and compNameToFilterName[inventoryInfo.entity] then
						if (not shopActive) or trigger_gamePanelInfo.abilityPanel then widget:UICmd("ToggleShop()") end
						interface:GetWidget('game_shop_search_input'):EraseInputLine()
						trigger_gamePanelInfo.selectedShopItem = -1

						trigger_gamePanelInfo.selectedShopItemType = ''
						trigger_gamePanelInfo:Trigger(false)

						ShopUI.ClearFilters()
						trigger_shopFilter.shopCategory	= 'components'
						trigger_shopFilter[compNameToFilterName[inventoryInfo.entity][1]] = true
						trigger_shopFilter:Trigger(false)
					else
						if (not shopActive) or trigger_gamePanelInfo.abilityPanel then widget:UICmd("ToggleShop()") end
						if isRecipeCompleted or inventoryInfo.isRecipeScroll then
							if trigger_gamePanelInfo.selectedShopItem == 0 then
								widget:Sleep(1, function()
									gameShopUpdateRowDataSelectedID(interface)
								end)
							else
								trigger_gamePanelInfo.selectedShopItem = 0
							end
						else
							trigger_gamePanelInfo.selectedShopItem = -1
						end

						trigger_gamePanelInfo.selectedShopItemType = ''
						trigger_gamePanelInfo:Trigger(false)

						ShopUI.ClearFilters()
						trigger_shopFilter.shopCategory	= ''
						trigger_shopFilter:Trigger(false)

						interface:GetWidget('game_shop_search_input'):SetInputLine(inventoryInfo.displayName)
					end					
				elseif isActivatable then
					ActivateTool(index)
					PrimaryAction(index)
				end
			end)

			widget:SetCallback('onrightclick', function(widget)
				SecondaryActionStash(index)
				PlaySound('/ui/sounds/sfx_button_generic.wav')
			end)			
			
			widget:SetCallback('onmouseover', function(widget)
				shopItemTipShow(index, 'ActiveInventory')
			
				if isActivatable then
					UpdateCursor(widget, true, { canLeftClick = isActivatable})
				end
			end)

			widget:SetCallback('onmouseout', function(widget)
				shopItemTipHide()
				
				if isActivatable then
					UpdateCursor(widget, false, { canLeftClick = isActivatable})
				end
			end)
		end, true, nil, 'isActivatable', 'exists')
		
		inventoryButton:SetCallback('onstartdrag', function(widget)
	--		local currentWidth 	= widget:GetWidth()
	--		local currentHeight = widget:GetHeight()
			
	--		widget:SetWidth(currentWidth)
	--		widget:SetHeight(currentHeight)
			
	--		widget:ForceToFront()
			local inventoryInfo = LuaTrigger.GetTrigger('ActiveInventory'..index)
			trigger_gamePanelInfo.shopLastBuyQueueDragged = -1
			trigger_gamePanelInfo.shopLastQuickSlotDragged = -1
			trigger_gamePanelInfo.shopDraggedItem = inventoryInfo.entity
			trigger_gamePanelInfo.shopDraggedItemScroll	= inventoryInfo.isRecipeScroll
			trigger_gamePanelInfo.shopDraggedItemOwnedRecipe = inventoryInfo.isRecipeCompleted
			trigger_gamePanelInfo.draggedInventoryIndex = index
		
			print ("Dragging: " .. inventoryInfo.entity .. '\n')
		end, true, nil)

		inventoryButton:SetCallback('onenddrag', function(widget)
	--		widget:SetParent(inventoryParent)
		end, true, nil)

		globalDraggerRegisterSource(inventoryButton, 5, 'gameDragLayer')


		inventoryCooldownText:RegisterWatchLua('ActiveInventory' .. index, function(widget, trigger)
			local cooldownTime = trigger.remainingCooldownTime
			local percent = trigger.remainingCooldownPercent

			if cooldownTime == 0 or (not trigger.exists) then
				widget:SetVisible(false)
				inventoryCooldownPie:SetVisible(false)
				inventoryIcon:SetRenderMode('normal')
			else
				widget:SetVisible(true)
				inventoryCooldownPie:SetVisible(true)
				widget:SetText(math.ceil(cooldownTime * 0.001) .. 's')
				inventoryCooldownPie:SetValue(percent)
				inventoryIcon:SetRenderMode('grayscale')
			end
		end, true, nil, 'remainingCooldownTime', 'remainingCooldownPercent', 'exists')
		
		craftedIcon:RegisterWatchLua('ActiveInventory' .. index, function(widget, trigger)
			widget:SetVisible(trigger.isPlayerCrafted and trigger.exists)
		end, true, nil, 'isPlayerCrafted', 'exists')
		
		craftedBorder:RegisterWatchLua('ActiveInventory' .. index, function(widget, trigger)
			widget:SetVisible(trigger.isPlayerCrafted and trigger.exists)
		end, true, nil, 'isPlayerCrafted', 'exists')
		--[[

		inventoryRegisterAutocast(object, index)
		inventoryRegisterTargeting(object, index)
		inventoryRegisterRefresh(object, index)
		inventoryRegisterManaTimer(object, index)
		inventoryRegisterCooldown(object, index)
		inventoryRegisterGloss(object, index)
		inventoryRegisterPlayerCrafted(object, index)
		inventoryRegisterMagnifierMoreInfo(object, index)
		inventoryRegisterDrop(object, index)
		inventoryRegisterTimerVert(object, index)
		inventoryRegisterScroll(object, index)

		--]]
	end

	registerInventorySlot('ActiveInventory' .. consumableIndex[1], 'gameItemConsumable1', true, false, consumableIndex[1])
	registerInventorySlot('ActiveInventory' .. consumableIndex[2], 'gameItemConsumable2', true, false, consumableIndex[2])

	registerInventorySlot('ActiveInventory' .. bootsIndex, 'gameItemBoots', false, true, bootsIndex)

	for i=1,#backpackIndex do
		registerInventorySlot('ActiveInventory' .. backpackIndex[i], 'gameItem' .. i, false, false, backpackIndex[i])
		registerInventorySlot('ActiveInventory' .. backpackIndex[i], 'gameItem' .. (i+6), false, false, backpackIndex[i])
	end

	registerInventoryFlip()
end