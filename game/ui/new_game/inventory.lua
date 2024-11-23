-- inventory.lua
-- functions from game2.lua required for things like the courier button in the shop.
--
local GetTrigger = LuaTrigger.GetTrigger

function registerCvarPinButton(object, buttonID, cvarName, moreInfoVis, triggerName, triggerParam, gameInfoParam, tipTitle, tipBody)
	tipTitle	= tipTitle or ''
	tipBody		= tipBody or ''
	moreInfoVis = moreInfoVis or false
	local pin		= object:GetWidget(buttonID..'Pin')
	local pinFlair	= object:GetWidget(buttonID..'PinFlair')
	local button	= object:GetWidget(buttonID)
	local thisCvar	= Cvar.GetCvar(cvarName)
	
	local flairEffectThread
	local function flairEffect(widget, totalSize, length, delay)
		if not widget then return end
		if (flairEffectThread and flairEffectThread:IsValid()) then
			flairEffectThread:kill()
			flairEffectThread = nil
		end
		flairEffectThread = libThread.threadFunc(function()	
			wait(delay)
			widget:SetVisible(true)
			widget:SetWidth('0s')
			widget:SetHeight('0s')
			widget:Scale(totalSize, totalSize, length)
			widget:FadeOut(length)
			libAnims.bounceIn(button, button:GetWidth(), button:GetHeight(), nil, nil, 0.02, 200, 0.8, 0.2)
			flairEffectThread = nil
		end)
	end	
	
	if thisCvar then
	
		local cvarValue = thisCvar:GetBoolean()
		if cvarValue then
			pin:SetColor('#FFDD33')
		else
			pin:SetColor('#00BFFF')
		end

		if triggerName and triggerParam then
			pin:RegisterWatchLua(triggerName, function(widget, trigger)
				if trigger[triggerParam] then
					pin:SetColor('#FFDD33')
				else
					pin:SetColor('#00BFFF')
				end
			end, false, nil, triggerParam)
		end


		button:SetCallback('onclick', function(widget)
			PlaySound('/ui/sounds/sfx_button_generic.wav')
			local newValue = (not thisCvar:GetBoolean())
			local trigger = LuaTrigger.GetTrigger(triggerName)
			thisCvar:Set(tostring(newValue))
			trigger[triggerParam] = newValue
			trigger:Trigger(false)
		end)
		
		button:SetCallback('onmouseover', function(widget)
			simpleTipGrowYUpdate(true, '/ui/elements:pin', Translate(tipTitle), Translate(tipBody), libGeneral.HtoP(32))
		end)
		
		button:SetCallback('onmouseout', function(widget)
			simpleTipGrowYUpdate(false)
		end)

		if moreInfoVis then
		
			if gameInfoParam and string.len(gameInfoParam) > 0 then
				button:RegisterWatchLua('ModifierKeyStatus', function(widget, trigger)					
					if (LuaTrigger.GetTrigger('gamePanelInfo').mapWidgetVis_tabbing) then
						local visible = trigger.moreInfoKey and trigger_gamePanelInfo[gameInfoParam]
						widget:SetVisible(visible)
						local trigger = LuaTrigger.GetTrigger(triggerName)
						if (visible) and ((not trigger) or (not trigger[triggerParam])) then
							flairEffect(pinFlair, '150s', '300', '100')
						end
					else
						widget:SetVisible(false)
					end
				end)
			else
				button:RegisterWatchLua('ModifierKeyStatus', function(widget, trigger)					
					if (LuaTrigger.GetTrigger('gamePanelInfo').mapWidgetVis_tabbing) then
						local visible = trigger.moreInfoKey
						widget:SetVisible(visible)
						local trigger = LuaTrigger.GetTrigger(triggerName)
						if (visible) and ((not trigger) or (not trigger[triggerParam])) then
							flairEffect(pinFlair, '150s', '300', '100')
						end
					else
						widget:SetVisible(false)
					end
				end)
			end
		

		end

	end
end

-- Register level pips for pets as well (level/maxLevel exist?)

local function inventoryRegisterMagnifierMoreInfo(object, index)
	libGeneral.createGroupTrigger('gameInventory'..index..'MagniGroup', { 'ModifierKeyStatus.moreInfoKey', 'ActiveInventory'..index })
	
	object:GetWidget('gameInventory'..index..'MagnifierMoreInfo'):RegisterWatchLua('gameInventory'..index..'MagniGroup', function(widget, groupTrigger)
		local exists	= groupTrigger['ActiveInventory'..index].exists
		local moreInfoKey	= groupTrigger['ModifierKeyStatus'].moreInfoKey
		
		widget:SetVisible(exists and moreInfoKey)
	end)
end

local function inventoryRegisterPurchasedRecently(object, index)
	object:GetWidget('gameInventory'..index..'PurchasedRecently'):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger) widget:SetVisible(trigger.exists and trigger.purchasedRecently) end, false, nil, 'exists', 'purchasedRecently')
end

local function inventoryRegisterPlayerCrafted(object, index)
	object:GetWidget('gameInventory'..index..'Crafted'):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger) widget:SetVisible(trigger.exists and trigger.isPlayerCrafted) end, false, nil, 'exists', 'isPlayerCrafted')
end

local function inventoryRegisterScroll(object, index)
	object:GetWidget('gameInventory'..index..'IconContainer'):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
		if trigger.isRecipeScroll then
			widget:SetWidth('65%')
			widget:SetHeight('65%')
		else
			widget:SetWidth('100%')
			widget:SetHeight('100%')
		end
	end, false, nil, 'isRecipeScroll')

	object:GetWidget('gameInventory'..index..'Scroll'):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger) widget:SetVisible(trigger.exists and trigger.isRecipeScroll) end, false, nil, 'isRecipeScroll', 'exists')
end

local function inventoryRegisterDrop(object, index, isStash)
	isStash = isStash or false
	local drop = object:GetWidget('gameInventory'..index..'Drop')

	drop:RegisterWatchLua('ItemCursorVisible', function(widget, trigger)
		widget:SetVisible(trigger.cursorVisible and trigger.hasItem)
	end)

	drop:RegisterWatchLua('globalDragInfo', function(widget, trigger)
		local dragType = trigger.type
		widget:SetVisible(trigger.active and (dragType == 5 or dragType == 6))
	end, false, nil, 'type', 'active')	
	
	if isStash then
		drop:SetCallback('onclick', function(widget)
			ItemPlaceStash(index)
		end)
	else
		drop:SetCallback('onclick', function(widget)
			ItemPlace(index)
		end)
	end

	local dragTarget = object:GetWidget('gameInventory'..index..'DragTarget')
	
	dragTarget:SetCallback('onmouseover', function(widget)
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

	libGeneral.createGroupTrigger('inventoryDragInfo', { 'globalDragInfo.active', 'globalDragInfo.type', 'PlayerCanShop.playerCanShop'})

	dragTarget:RegisterWatchLua('inventoryDragInfo', function(widget, groupTrigger)
		local dropType	= groupTrigger['globalDragInfo'].type
		local active 	= groupTrigger['globalDragInfo'].active
		local canShop 	= groupTrigger['PlayerCanShop'].playerCanShop

		widget:SetVisible(active and ((canShop and (((dropType == 3 or dropType == 4) and not trigger_gamePanelInfo.shopDraggedItemOwnedRecipe) or dropType == 6)) or dropType == 5))
	end)
end

local function inventoryRegisterCharges(object, index)	-- Items, primarily
	object:GetWidget('gameInventory'..index..'ChargeBacker'):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger) widget:SetVisible(trigger.exists and trigger.charges > 0) end, false, nil, 'charges', 'exists')
	object:GetWidget('gameInventory'..index..'Charges'):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
		local charges = trigger.charges
		if trigger.exists and charges > 0 then
			widget:SetVisible(true)
			widget:SetText(charges)
		else
			widget:SetVisible(false)
		end
	end, false, nil, 'charges', 'exists')
end


local function inventoryRegisterChargePipsPrimary(object, index)	-- Includes bar
	local chargeActive	= false
	-- local chargePip		= object:GetWidget('heroInventory'..index..'ChargePip'..pipID)
	local chargeContainer		= object:GetWidget('gameInventory'..index..'ChargeContainer')
	local chargeBarContainer	= object:GetWidget('gameInventory'..index..'ChargeBarContainer')

	libGeneral.createGroupTrigger('gameInventoryChargeInfo'..index, {
		'ActiveInventory'..index..'.manaCost',
		'ActiveInventory'..index..'.charges',
		'ActiveInventory'..index..'.manaCost',
		'ActiveInventory'..index..'.castCharges',
		'ActiveUnit.mana'
	})

	--[[
		<panel name="gameInventory{id}ChargeBarContainer" style="heroInventoryChargeInset" visible="false">
		<panel name="gameInventory{id}ChargeBar" style="heroInventoryChargeBar"/>
	--]]
	object:GetWidget('gameInventory'..index..'ChargeBar'):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
		local maxCharges = trigger.maxCharges
		if maxCharges > 6 then
			widget:SetWidth(ToPercent(trigger.charges / maxCharges))
		end
	end, false, nil, 'charges', 'maxCharges')
	
	local function GetSpecialHeroPipIcon(heroEntity)
		local heroesWithSpecialIcons = {
			-- ['Hero_Ray'] = {'/heroes/ray/ability_01/icon.tga', '/heroes/ray/ability_01/icon.tga'},
		}
		if heroEntity and heroesWithSpecialIcons[heroEntity] then
			return {heroesWithSpecialIcons[heroEntity][1] or nil, heroesWithSpecialIcons[heroEntity][2] or nil}
		else
			return {nil, nil}
		end
	end
	
	for i=1,6,1 do

		object:GetWidget('gameInventory'..index..'ChargePip'..i):SetCallback('onshow', function(widget)
			local heroEntity = LuaTrigger.GetTrigger('HeroUnit').heroEntity
			widget:SetTexture(GetSpecialHeroPipIcon(heroEntity)[1] or '/ui/game/ability/textures/ability_frame_peg.tga')
		end, false, nil, 'maxCharges')

		object:GetWidget('gameInventory'..index..'ChargeHole'..i):SetCallback('onshow', function(widget)
			local heroEntity = LuaTrigger.GetTrigger('HeroUnit').heroEntity
			widget:SetTexture(GetSpecialHeroPipIcon(heroEntity)[2] or '/ui/game/ability/textures/ability_frame_peg_holes.tga')
			-- widget:SetRenderMode('grayscale')
		end)
		
		object:GetWidget('gameInventory'..index..'ChargeHole'..i):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
			local maxCharges = trigger.maxCharges
			widget:SetVisible(maxCharges >= i and maxCharges <= 6)
		end, false, nil, 'maxCharges')

		object:GetWidget('gameInventory'..index..'ChargePip'..i):RegisterWatchLua('gameInventoryChargeInfo'..index, function(widget, groupTrigger)
			local triggerInventory		= groupTrigger['ActiveInventory'..index]
			local triggerUnit			= groupTrigger['ActiveUnit']
			local charges				= triggerInventory.charges
			local maxCharges			= triggerInventory.maxCharges
			if maxCharges >= i and maxCharges <= 6 then

				local widgetColorR = styles_chargePipR
				local widgetColorG = styles_chargePipG
				local widgetColorB = styles_chargePipB
				widget:SetRenderMode('grayscale')
				if charges >= i then
					widget:SetVisible(true)
					if (triggerInventory.manaCost * i) > triggerUnit.mana then
						widgetColorR = styles_chargePipNeedManaR
						widgetColorG = styles_chargePipNeedManaG
						widgetColorB = styles_chargePipNeedManaB
						widget:SetRenderMode('grayscale')
					else
						widgetColorR = 1	-- styles_chargePipMetR
						widgetColorG = 1	-- styles_chargePipMetG
						widgetColorB = 1	-- styles_chargePipMetB
						widget:SetRenderMode('normal')
					end
				else
					widget:SetVisible(false)
				end
				widget:SetColor(widgetColorR, widgetColorG, widgetColorB)
			else
				widget:SetVisible(false)
			end
		end)

	end

	chargeContainer:RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
		local maxCharges = trigger.maxCharges
		local useBar = (maxCharges > 6)

		chargeBarContainer:SetVisible(useBar)
		widget:SetVisible(maxCharges > 0)
	end, false, nil, 'maxCharges')

end

local function inventoryRegisterCourier(object, index)
	object:GetWidget('gameInventory'..index..'OnCourier'):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
		widget:SetVisible(trigger.isOnCourier and trigger.exists)
	end, false, nil, 'isOnCourier', 'exists')
end

local function inventoryRegisterButtonSimple(object, index, isItem, isPrimary, showRange, suffix)
	suffix = suffix or ''
	isItem = isItem or false
	isPrimary = isPrimary or false
	if showRange == nil then showRange = true end
	local button = object:GetWidget('gameInventory'..index..suffix..'Button')
	local icon = object:GetWidget('gameInventory'..index..suffix..'Icon')
	local gloss = object:GetWidget('gameInventory'..index..suffix..'Gloss')
	
	local buttonInfo = libButton2.register(
		{
			widgets		= {
				button		= button,
				icon		= icon,
				gloss		= gloss
			}
		}, 'abilityButtonPrimary'
	)
	
	local scoreboardOpen = false
	button:RegisterWatch('gameToggleScoreboard', function(widget, keyDown)
		scoreboardOpen = AtoB(keyDown)				
	end)	
	
	button:SetCallback('onclick', function(widget)
		if isItem and LuaTrigger.GetTrigger('ModifierKeyStatus').moreInfoKey then
			local inventoryInfo = LuaTrigger.GetTrigger('ActiveInventory'..index)
			local isRecipeCompleted = inventoryInfo.isRecipeCompleted
			local shopActive = LuaTrigger.GetTrigger('ShopActive').isActive
			if (not isRecipeCompleted) and compNameToFilterName[inventoryInfo.entity] then
				if (not shopActive) or trigger_gamePanelInfo.abilityPanel then widget:UICmd("ToggleShop()") end
				object:GetWidget('game_shop_search_input'):EraseInputLine()
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
						button:Sleep(1, function()
							gameShopUpdateRowDataSelectedID(object)
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

				object:GetWidget('game_shop_search_input'):SetInputLine(inventoryInfo.displayName)
			end
		else

			local levelUpGroupTrigger 		= GetTrigger('gameInventory'..index..'LevelUpButtonVis')
			local activeInventoryTrigger 	= LuaTrigger.GetTrigger('ActiveInventory'..index)

			if isPrimary and ((levelUpGroupTrigger['ModifierKeyStatus'].moreInfoKey) or scoreboardOpen) and (levelUpGroupTrigger['ActiveUnit'].availablePoints > 0) and (levelUpGroupTrigger['ActiveInventory'..index].canLevelUp) then
				PlaySound('/ui/sounds/ui_level_ability.wav', 0.3)
				widget:UICmd("LevelUpAbility("..index..")")					
			elseif isPrimary and LuaTrigger.GetTrigger('ModifierKeyStatus').alt and (activeInventoryTrigger.level > 0) then 

				if (activeInventoryTrigger.remainingCooldownTime > 0) then
					Cmd("TeamChat " .. Translate('ability_on_cooldown_remaing', 'value1', math.ceil(activeInventoryTrigger.remainingCooldownTime/1000), 'value2', activeInventoryTrigger.displayName))
				else
					Cmd("TeamChat " .. Translate('ability_on_cooldown_ready', 'value2', activeInventoryTrigger.displayName))
				end
			
			else
				ActivateTool(index)
				if isItem then
					PrimaryAction(index)
				end			
			end

		end

		PlaySound('/ui/sounds/sfx_button_generic.wav')
	end)

	button:SetCallback('onrightclick', function(widget)
		ActivateToolSecondary(index)
		if isItem then
			SecondaryAction(index)
		end
		PlaySound('/ui/sounds/sfx_button_generic.wav')
	end)
	
	if isItem then
		button:SetCallback('onstartdrag', function(widget)
			local inventoryInfo = LuaTrigger.GetTrigger('ActiveInventory'..index)
			trigger_gamePanelInfo.shopLastBuyQueueDragged = -1
			trigger_gamePanelInfo.shopLastQuickSlotDragged = -1
			trigger_gamePanelInfo.shopDraggedItem = inventoryInfo.entity
			trigger_gamePanelInfo.shopDraggedItemScroll	= inventoryInfo.isRecipeScroll
			trigger_gamePanelInfo.shopDraggedItemOwnedRecipe = inventoryInfo.isRecipeCompleted
			trigger_gamePanelInfo.draggedInventoryIndex = index
		end)
	
		globalDraggerRegisterSource(button, 5, 'gameDragLayer')
	end
	
	button:SetCallback('onmouseover', function(widget)
		if showRange then
			button:UICmd("ShowRangeIndicator(GetSelectedEntity(), "..index..")")
		end
		if isPrimary then
			Trigger('abilityTipShow', 2, index)
			UpdateCursor(button, true, { canLeftClick = true, canRightClick = false })
		elseif isItem then -- rmm shop tip here
			-- Trigger('itemTipShow', 'Active', index)
			local inventoryInfo = LuaTrigger.GetTrigger('ActiveInventory'..index)
			if inventoryInfo.exists then
				shopItemTipShow(index, 'ActiveInventory')
				if object:GetWidget('gameShop_sell_area') then
					object:GetWidget('gameShop_sell_area'):SetVisible(1)
				end
				UpdateCursor(button, true, { canLeftClick = true, canRightClick = true })
			end
		else
			Trigger('inventoryTipSimpleShow', 'Active', index)
		end
	end)

	button:SetCallback('onmouseout', function(widget)
		if showRange then
			button:UICmd("HideRangeIndicator()")
		end

		if isPrimary then
			Trigger('abilityTipHide')
		elseif isItem then
			-- Trigger('itemTipHide')
			shopItemTipHide()
			if object:GetWidget('gameShop_sell_area') then
				local dragTrigger = LuaTrigger.GetTrigger('globalDragInfo')
				local itemCursorTrigger = LuaTrigger.GetTrigger('ItemCursorVisible')
		
				if (itemCursorTrigger.cursorVisible and itemCursorTrigger.hasItem) then
				
				elseif (dragTrigger.active and (dragTrigger.type == 5 or dragTrigger.type == 6)) then
				
				else
					object:GetWidget('gameShop_sell_area'):SetVisible(0)
				end
			end			
		else
			Trigger('inventoryTipSimpleHide')
		end
		UpdateCursor(button, false, { canLeftClick = true, canRightClick = true })
	end)

	button:RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
		buttonInfo.useAnims = (trigger.exists and trigger.isActivatable)
		-- widget:SetEnabled(trigger.exists)
	end, false, nil, 'isActivatable', 'exists')

end

local function inventoryRefreshShow(object, index, suffix, cooldownTime)
	suffix = suffix or ''
	local refreshEffect = object:GetWidget('gameInventory'..index..suffix..'RefreshEffect')
	refreshEffect:SetVisible(true)
	refreshEffect:UICmd(
		"SetAnim('idle');"..
		"SetEffect('/ui/_models/refresh/refresh.effect');"
	)
	refreshEffect:Sleep(1333, function() refreshEffect:SetVisible(false) end)
	PlaySound('/shared/sounds/ui/sfx_refresh.wav')

	if (cooldownTime) and (cooldownTime > 20000) then
		local pulse = object:GetWidget('gameInventory'..index..suffix..'IconPulse')
		if (pulse) then
			pulse:SetVisible(1)
			pulse:SetY('-10h')
			pulse:SetHeight('120%')
			pulse:SetWidth('120%')
			pulse:SlideY('0', 250)
			pulse:Scale('100%', '100%', 250)
			pulse:FadeOut(300)
		end
	end
end

local function inventoryRegisterTimerVert(object, index, suffix)
	suffix = suffix or ''
	object:GetWidget('gameInventory'..index..suffix..'TimerBar'):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
		local timeRemaining = trigger.timer
		widget:SetVisible(timeRemaining > 0)
		if timeRemaining > 0 then
			widget:SetHeight(ToPercent(timeRemaining / trigger.timerDuration))
		end
	end, false, nil, 'timer', 'timerDuration')
end

local function inventoryRegisterManaTimer(object, index, suffix)
	suffix = suffix or ''
	local manaTimerInitRemaining	= 0
	local manaTimerInitCurrent		= 0

	local manaTimerLabel		= object:GetWidget('gameInventory'..index..suffix..'ManaTimerLabel')
	local manaTimerContainer	= object:GetWidget('gameInventory'..index..suffix..'ManaTimerContainer')
	local manaTimerBar			= object:GetWidget('gameInventory'..index..suffix..'ManaTimerBar')
	local wasOnCooldown = false

	libGeneral.createGroupTrigger('gameInventoryManaTime'..index..suffix, {
		'ActiveInventory'..index..'.manaCost',
		'ActiveInventory'..index..'.remainingCooldownPercent',
		'ActiveUnit.isActive',
		'ActiveUnit.mana',
		'ActiveUnit.manaRegen'
	})

	manaTimerBar:RegisterWatchLua('gameInventoryManaTime'..index..suffix, function(widget, groupTrigger)
		local triggerInventory			= groupTrigger['ActiveInventory'..index]
		local triggerUnit				= groupTrigger['ActiveUnit']
		local manaCurrent				= triggerUnit.mana
		local manaRegen					= triggerUnit.manaRegen
		local heroActive				= triggerUnit.isActive
		local manaCost					= triggerInventory.manaCost
		local remainingCooldownPercent	= triggerInventory.remainingCooldownPercent

		if heroActive and manaCost > 0 then
			if remainingCooldownPercent <= 0 then
				if manaCost > manaCurrent then
					manaTimerContainer:SetVisible(true)
					manaTimerLabel:SetVisible(true)
					secondsRemaining = (manaCost - manaCurrent) / manaRegen
					if secondsRemaining > 0 then
						if manaTimerInitRemaining == 0 then
							manaTimerInitRemaining	= manaCost - manaCurrent
							manaTimerInitCurrent	= manaCurrent
						end

						widget:SetWidth(
							ToPercent(
								min((max((manaCurrent - manaTimerInitCurrent), 1) / manaTimerInitRemaining), 1) * -1
							)
						)

						manaTimerLabel:SetText(Round(manaCost - manaCurrent))

					else
						if manaTimerInitRemaining > 0 or wasOnCooldown then
							inventoryRefreshShow(object, index, suffix, triggerInventory.cooldownTime)
						end
						manaTimerContainer:SetVisible(false)
						manaTimerLabel:SetVisible(false)
						manaTimerInitRemaining = 0
						wasOnCooldown = false
					end
				else
					if manaTimerInitRemaining > 0 or wasOnCooldown then
						inventoryRefreshShow(object, index, suffix, triggerInventory.cooldownTime)
					end
					manaTimerContainer:SetVisible(false)
					manaTimerLabel:SetVisible(false)
					manaTimerInitRemaining = 0
					wasOnCooldown = false
				end
			else
				if manaTimerInitRemaining > 0 then
					inventoryRefreshShow(object, index, suffix, triggerInventory.cooldownTime)
				end
				manaTimerContainer:SetVisible(false)
				manaTimerLabel:SetVisible(false)
				manaTimerInitRemaining = 0
				wasOnCooldown = true
			end
		else
			manaTimerContainer:SetVisible(false)
			manaTimerLabel:SetVisible(false)
			manaTimerInitRemaining = 0
		end
	end)

	manaTimerContainer:RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
		if trigger.eventReady > 0 then
			local triggerMana			= LuaTrigger.GetTrigger('ActiveUnit')
			local triggerDescription	= LuaTrigger.GetTrigger('ActiveInventory'..index)

			if triggerMana.mana >= triggerDescription.manaCost then
				inventoryRefreshShow(object, index, suffix, triggerInventory.cooldownTime)
			end
		end
	end, true, nil, 'eventReady')
end

local function inventoryRegisterGloss(object, index, suffix)
	suffix = suffix or ''
	object:GetWidget('gameInventory'..index..suffix..'Gloss'):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
		widget:SetVisible(trigger.isActivatable and trigger.exists)
	end, false, nil, 'isActivatable', 'exists')
end

local function inventoryRegisterCooldown(object, index, suffix)
	suffix = suffix or ''
	object:GetWidget('gameInventory'..index..suffix..'Cooldown'):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
		local remainingCooldownTime = trigger.remainingCooldownTime
		if remainingCooldownTime > 0 then
			widget:SetVisible(true)
			widget:SetText(ceil(remainingCooldownTime / 1000))
		else
			widget:SetVisible(false)
		end
	end, false, nil, 'remainingCooldownTime')

	object:GetWidget('gameInventory'..index..suffix..'CooldownPie'):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
		widget:SetValue(trigger.remainingCooldownPercent)
	end, false, nil, 'remainingCooldownPercent')
end

local function inventoryRegisterAutocast(object, index, suffix)
	suffix = suffix or ''
	object:GetWidget('gameInventory'..index..suffix..'AutocastIndicator'):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
		widget:SetVisible(trigger.inUse)
	end, false, nil, 'inUse')
end

local function inventoryRegisterTargeting(object, index, suffix)
	suffix = suffix or ''
	object:GetWidget('gameInventory'..index..suffix..'TargetingIndicator'):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
		if (trigger.isActiveSlot) then
			widget:SetVisible(1)
			widget:UICmd([[SetEffect('/ui/_effects/toggle/toggle.effect')]])
		else
			widget:SetVisible(0)
			widget:UICmd([[SetEffect('')]])
		end
	end, false, nil, 'isActiveSlot')
end

local function inventoryRegisterRefresh(object, index, suffix)	-- Simple, doesn't care about mana
	suffix = suffix or ''
	object:GetWidget('gameInventory'..index..suffix..'RefreshEffect'):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
		if trigger.eventReady > 0 then
			widget:SetVisible(true)
			widget:UICmd(
				"SetAnim('idle');"..
				"SetEffect('/ui/_models/refresh/refresh.effect');"
			)
			widget:Sleep(1333, function() widget:SetVisible(false) end)
			PlaySound('/shared/sounds/ui/sfx_refresh.wav')
		end
	end, false, nil, 'eventReady')
end

local function inventoryRegisterIcon(object, index, visExists, suffix)
	visExists = visExists or false
	suffix = suffix or ''
	local iconStatus = LuaTrigger.CreateCustomTrigger('gameInventoryIconStatus'..index, {
		{ name	=   'level',		type	= 'number'},
		{ name	=   'maxLevel',		type	= 'number'},
		{ name	=   'needMana',		type	= 'boolean'},
		{ name	=   'isDisabled',	type	= 'boolean'},
		{ name	=   'isOnCooldown',	type	= 'boolean'},
		{ name	=   'icon',			type	= 'string'},
		{ name	=   'exists',		type	= 'boolean'},
		{ name	=   'heroActive',	type	= 'boolean'}
	})

	local icon 				= object:GetWidget('gameInventory'..index..suffix..'Icon')
	local icon_cd 			= object:GetWidget('gameInventory'..index..suffix..'Icon_cd')
	local iconPulse 		= object:GetWidget('gameInventory'..index..suffix..'IconPulse')
	local iconCooldownText 	= object:GetWidget('gameInventory'..index..'Cooldown')

	icon:RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
		iconStatus.level		= trigger.level
		iconStatus.maxLevel		= trigger.maxLevel
		iconStatus.needMana		= trigger.needMana
		iconStatus.isDisabled	= trigger.isDisabled
		iconStatus.isOnCooldown	= trigger.isOnCooldown
		iconStatus.icon			= trigger.icon
		iconStatus.exists		= trigger.exists
		iconStatus:Trigger(false)
	end, false, nil, 'maxLevel', 'level', 'isDisabled', 'needMana', 'isOnCooldown', 'icon', 'exists')

	icon:RegisterWatchLua('ActiveUnit', function(widget, trigger)
		iconStatus.heroActive = trigger.isActive
		iconStatus:Trigger(false)
	end, false, nil, 'isActive')

	icon:RegisterWatchLua('gameInventoryIconStatus'..index, function(widget, trigger)
		local isNotLeveled	= (trigger.level == 0 and trigger.maxLevel > 0)
		local needMana		= trigger.needMana
		local isDisabled	= trigger.isDisabled
		local heroActive	= trigger.heroActive

		local statusColorR	= 1
		local statusColorG	= 1
		local statusColorB	= 1

		if trigger.isOnCooldown or needMana or isDisabled or isNotLeveled or (not heroActive) then
			widget:SetRenderMode('grayscale')
		else
			widget:SetRenderMode('normal')
		end
		
		if (icon_cd) then
			if (trigger.isOnCooldown and trigger.exists) then
				icon_cd:SetVisible(1)
			else
				icon_cd:SetVisible(0)
			end
		end
		
		if (not trigger.exists and iconCooldownText) then
			iconCooldownText:SetVisible(0)
		end
		
		if isNotLeveled then
			statusColorR	= styles_inventoryStatusColorUnleveledR
			statusColorG	= styles_inventoryStatusColorUnleveledG
			statusColorB	= styles_inventoryStatusColorUnleveledB
		elseif isDisabled or (not heroActive) then
			statusColorR	= styles_inventoryStatusColorDisabledR
			statusColorG	= styles_inventoryStatusColorDisabledG
			statusColorB	= styles_inventoryStatusColorDisabledB
		elseif needMana then
			statusColorR	= styles_inventoryStatusNeedManaR
			statusColorG	= styles_inventoryStatusNeedManaG
			statusColorB	= styles_inventoryStatusNeedManaB
		end

		widget:SetColor(statusColorR, statusColorG, statusColorB)
		widget:SetTexture(trigger.icon)
		
		if (icon_cd) then
			icon_cd:SetTexture(trigger.icon)
		end
		
		if visExists then
			if (LuaTrigger.GetTrigger('gamePanelInfo').mapWidgetVis_tabbing) then
				libGeneral.fade(widget, trigger.exists, 175)
			else
				widget:FadeOut(175)
			end
			-- widget:SetVisible(trigger.exists)
		end

	end, true, nil, 'maxLevel', 'level', 'isDisabled', 'needMana', 'isOnCooldown', 'icon', 'exists', 'heroActive' )

	icon:RegisterWatchLua('gameInventoryIconStatus'..index, function(widget, trigger)
		widget:SetTexture(trigger.icon)
		if (icon_cd) then
			icon_cd:SetTexture(trigger.icon)
		end
	end, true, nil, 'icon')

	if (iconPulse) then
		iconPulse:RegisterWatchLua('gameInventoryIconStatus'..index, function(widget, trigger)
			widget:SetTexture(trigger.icon)
		end, true, nil, 'icon')
	end

	iconStatus.level		= 0
	iconStatus.maxLevel		= 0
	iconStatus.needMana		= false
	iconStatus.isDisabled	= false
	iconStatus.isOnCooldown	= false
	iconStatus.icon			= ''
	iconStatus.exists		= false
	iconStatus.heroActive	= true
	
	iconStatus:Trigger(true)
end

mainUI.savedLocally.LastBuild = mainUI.savedLocally.LastBuild or {}
local hero = LuaTrigger.GetTrigger('HeroUnit').heroEntity
if hero ~= nil and hero == "" then -- New game
	if object:GetWidget('game_pushorb_sleeper') then
		object:GetWidget('game_pushorb_sleeper'):RegisterWatchLua('HeroUnit', function(widget, trigger)
			hero = trigger.heroEntity
			mainUI.savedLocally = mainUI.savedLocally or {}
			mainUI.savedLocally.LastBuild = mainUI.savedLocally.LastBuild or {}
			mainUI.savedLocally.LastBuild[hero] = mainUI.savedLocally.LastBuild[hero] or {}
			mainUI.savedLocally.LastBuild[hero].Skills = mainUI.savedLocally.LastBuild[hero].Skills or {}		
			mainUI.savedLocally.LastBuild[hero].Items = mainUI.savedLocally.LastBuild[hero].Items or {}		
			widget:UnregisterWatchLua('HeroUnit')
		end, false, nil, 'heroEntity')
	end
end
local function AbilityLevelled(ability)
	ability = string.sub(ability, 1, -2) .. (tonumber(string.sub(ability, -1))-1)
	mainUI.savedLocally.LastBuild[hero] = mainUI.savedLocally.LastBuild[hero] or {}
	mainUI.savedLocally.LastBuild[hero].Skills = mainUI.savedLocally.LastBuild[hero].Skills or {}
	table.insert(mainUI.savedLocally.LastBuild[hero].Skills, ability)
end

local function inventoryRegisterPrimaryLevelPips(object, index)
	local oldLevel = 0
	for i=1,4,1 do
		object:GetWidget('gameInventory'..index..'LevelPip'..i):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
			if trigger.level > oldLevel then
				AbilityLevelled(trigger.entity)
				oldLevel = trigger.level
			end
			if i <= trigger.maxLevel then
				widget:SetVisible(true)
				if trigger.level >= i then
					widget:SetColor(0, 1, 0, 1)
					widget:Sleep(150, function()
						widget:SetColor(styles_levelPipMetR, styles_levelPipMetG, styles_levelPipMetB)
						widget:Sleep(150, function()
							widget:SetColor(0, 1, 0, 1)
							widget:Sleep(150, function()
								widget:SetColor(styles_levelPipMetR, styles_levelPipMetG, styles_levelPipMetB)
								widget:Sleep(150, function()
									widget:SetColor(0, 1, 0, 1)
									widget:Sleep(150, function()
										widget:SetColor(styles_levelPipMetR, styles_levelPipMetG, styles_levelPipMetB)
									end)
								end)
							end)
						end)
					end)
				else
					widget:SetColor(styles_levelPipR, styles_levelPipG, styles_levelPipB)
				end
			else
				widget:SetVisible(false)
			end
		end, false, nil, 'level', 'maxLevel')
	end
end

local function inventoryRegisterRebindableKey(object, index, isBackpack, suffix, isItem, tabShow)
	suffix 		= suffix or ''
	isBackpack 	= isBackpack or false
	isItem 		= isItem or false
	isItem 		= isBackpack or isItem or false
	tabShow 	= tabShow or false
	
	local button	= object:GetWidget('gameInventory'..index..suffix..'HotkeyButton')
	local backer	= object:GetWidget('gameInventory'..index..suffix..'HotkeyBacker')
	local label		= object:GetWidget('gameInventory'..index..suffix..'Hotkey')
	local buttonTip	= object:GetWidget('gameInventory'..index..suffix..'HotkeyButtonTip')

	libGeneral.createGroupTrigger('gameInventory'..index..suffix..'KeyButtonTipStatus', {
		'ActiveInventory'..index..'.exists',
		'ActiveInventory'..index..'.isActivatable',
		'ModifierKeyStatus.moreInfoKey'
	})
	
	buttonTip:RegisterWatchLua('gameInventory'..index..suffix..'KeyButtonTipStatus', function(widget, groupTrigger)
		local triggerInventory	= groupTrigger['ActiveInventory'..index]
		local exists			= triggerInventory.exists
		local isActivatable		= triggerInventory.isActivatable
		local moreInfoKey		= groupTrigger['ModifierKeyStatus'].moreInfoKey
		
		widget:SetEnabled((exists and ((not isItem) or isActivatable) and (not moreInfoKey)) or false)
	end)
	
	if isItem then
		button:RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
			local showWidget = trigger.exists and trigger.isActivatable

			widget:SetVisible(showWidget)
			label:SetVisible(showWidget)
		end, false, nil, 'exists', 'isActivatable')
	end

	button:RegisterWatchLua('gameInventory'..index..suffix..'KeyButtonTipStatus', function(widget, groupTrigger)
		local triggerInventory	= groupTrigger['ActiveInventory'..index]
		local exists			= triggerInventory.exists
		local isActivatable		= triggerInventory.isActivatable
		local moreInfoKey		= groupTrigger['ModifierKeyStatus'].moreInfoKey
		
		if (moreInfoKey) and ((not isItem) or isActivatable) then
			widget:SetNoClick(0)
		else
			widget:SetNoClick(1)
		end
	end)
	
	if tabShow then
		label:RegisterWatchLua('ModifierKeyStatus', function(widget, trigger)
			local moreInfoKey = trigger.moreInfoKey
			widget:SetVisible(moreInfoKey)
			button:SetVisible(moreInfoKey)
			backer:SetVisible(moreInfoKey)
			buttonTip:SetVisible(moreInfoKey)
		end, false, nil, 'moreInfoKey')
	end

	buttonTip:SetCallback('onmouseover', function(widget)
		simpleTipNoFloatUpdate(true, nil, Translate('game_keybind_1'), Translate('game_keybind_2', 'value', GetKeybindButton('game', 'TriggerToggle', 'gameShowMoreInfo', 0)), nil, nil, libGeneral.HtoP(-18), 'center', 'bottom')
	end)

	buttonTip:SetCallback('onmouseout', function(widget)
		simpleTipNoFloatUpdate(false)
	end)

	button:SetCallback('onmouseover', function(widget)
		simpleTipNoFloatUpdate(true, nil, Translate('game_keybind_1'), Translate('game_keybind_2_no_mod'), nil, nil, libGeneral.HtoP(-18), 'center', 'bottom')
		UpdateCursor(widget, true, { canLeftClick = true, canRightClick = false })
	end)

	button:SetCallback('onmouseout', function(widget)
		simpleTipNoFloatUpdate(false)
		UpdateCursor(widget, false, { canLeftClick = true, canRightClick = false })
	end)

	button:SetCallback('onclick', function(widget)
		local bindCommand	= 'ActivateTool'
		local bindIndex		= index
		
		if isBackpack then
			bindCommand = 'ActivateUsableItem'
			bindIndex	= (LuaTrigger.GetTrigger('ActiveInventory'..index).activatableBindNumber + 1)
		end

		PlaySound('/ui/sounds/sfx_button_generic.wav')

		local binderData			= LuaTrigger.GetTrigger('buttonBinderData')
		local oldButton				= nil
		binderData.allowMoreInfoKey	= false
		binderData.show				= true
		binderData.table			= 'game'
		binderData.action			= bindCommand
		binderData.param			= tostring(bindIndex)
		binderData.keyNum			= 0	-- 0 for leftclick, 1 for rightclick
		binderData.impulse			= false
		binderData.oldButton		= (GetKeybindButton('game', bindCommand, bindIndex, 0) or 'None')
		binderData:Trigger()
	end)
	
	libButton2.register(
		{
			widgets	= {
				button		= button,
				Body		= object:GetWidget('gameInventory'..index..suffix..'Body'),
				Highlight	= object:GetWidget('gameInventory'..index..suffix..'Highlight')
			}
		}, 'key'
	)

	backer:RegisterWatchLua('gameInventory'..index..suffix..'KeyButtonTipStatus', function(widget, groupTrigger)
		
		local triggerInventory	= groupTrigger['ActiveInventory'..index]
		local exists			= triggerInventory.exists
		local isActivatable		= triggerInventory.isActivatable
		local moreInfoKey		= groupTrigger['ModifierKeyStatus'].moreInfoKey		
		
		if moreInfoKey then
			widget:SetColor(styles_colors_hotkeyCanSet)
			widget:SetBorderColor(styles_colors_hotkeyCanSet)
		elseif (isActivatable) then
			widget:SetColor(styles_colors_hotkeyNoSet)
			widget:SetBorderColor(styles_colors_hotkeyNoSet)
		else
			widget:SetColor('.6 .6 .6 1')
			widget:SetBorderColor('.6 .6 .6 1')		
		end
	end)
end

local hotkeyFontList = {
	'maindyn_14',
	'maindyn_13',
	'maindyn_12',
	'maindyn_11',
	'maindyn_10'
}

local hotkeyFontListEnd = hotkeyFontList[#hotkeyFontList]

local function inventoryRegisterHotkeyLabel(object, index, suffix, tabShow)
	suffix = suffix or ''
	tabShow = tabShow or false
	
	local hotkey = object:GetWidget('gameInventory'..index..suffix..'Hotkey')
	
	hotkey:RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
		local binding1			= trigger.binding1
		local quickBinding1		= trigger.quickBinding1
		local bindingText		= ''
	
		if binding1 and string.len(binding1) > 0 then
			bindingText = binding1
		elseif quickBinding1 and string.len(quickBinding1) > 0 then
			bindingText = quickBinding1
		end

		local newFont		= FitFontToLabel(widget, bindingText, hotkeyFontList, false)
		local fullLabel		= bindingText

		if not newFont or newFont == hotkeyFontListEnd then
			for i=math.max(1,(string.len(fullLabel) - 3)), 1, -1 do
				bindingText = string.sub(fullLabel, 1, i)..'.'
				newFont = FitFontToLabel(widget, bindingText, hotkeyFontList, false)
				if newFont and newFont ~= hotkeyFontListEnd then
					break
				end
			end
		end

		widget:SetFont(newFont)
		widget:SetText(bindingText)
		
	end, false, nil, 'binding1', 'quickBinding1')
	
	if tabShow then
		hotkey:RegisterWatchLua('ModifierKeyStatus', function(widget, trigger)
			widget:SetVisible(trigger.moreInfoKey)
		end, false, nil, 'moreInfoKey')
	end
end

local function inventoryRegisterHotkeyLabelUsable(object, index)
	object:GetWidget('gameInventory'..index..'Hotkey'):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
		local activatableBinding1 = trigger.activatableBinding1
		local quickActivatableBinding1 = trigger.quickActivatableBinding1
		
		if activatableBinding1 and string.len(activatableBinding1) > 0 then
			widget:SetText(activatableBinding1)
		elseif quickActivatableBinding1 and string.len(quickActivatableBinding1) > 0 then
			widget:SetText(quickActivatableBinding1)
		else
			widget:SetText('')
		end
	end, false, nil, 'activatableBinding1', 'quickActivatableBinding1')
end


local function inventoryRegisterItem(object, index, isBackpack, isBoots)
	if isBackpack == nil then
		isBackpack = true
	end
	
	isBoots = isBoots or false
	
	inventoryRegisterIcon(object, index, true)
	inventoryRegisterButtonSimple(object, index, true)
	inventoryRegisterAutocast(object, index)
	inventoryRegisterTargeting(object, index)
	inventoryRegisterRefresh(object, index)
	inventoryRegisterManaTimer(object, index)
	inventoryRegisterCooldown(object, index)
	inventoryRegisterGloss(object, index)
	inventoryRegisterRebindableKey(object, index, isBackpack, nil, true)
	inventoryRegisterCourier(object, index)
	inventoryRegisterMagnifierMoreInfo(object, index)
	
	if isBackpack then
		inventoryRegisterHotkeyLabelUsable(object, index)
	else
		inventoryRegisterHotkeyLabel(object, index)
	end

	inventoryRegisterCharges(object, index)
	inventoryRegisterDrop(object, index)
	inventoryRegisterTimerVert(object, index)
	inventoryRegisterScroll(object, index)
	inventoryRegisterPurchasedRecently(object, index)
	inventoryRegisterPlayerCrafted(object, index)

	object:GetWidget('gameInventory'..index..'TimerBacker'):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger) widget:SetVisible(trigger.exists and (trigger.hasTimer or trigger.alwaysShowTimer)) end, false, nil, 'exists', 'alwaysShowTimer', 'hasTimer')
	
	if object:GetWidget('gameInventory'..index..'Containers') then
		object:GetWidget('gameInventory'..index..'Containers'):RegisterWatchLua('gamePanelInfo', function(widget, trigger)
			object:GetWidget('gameInventory'..index..'Containers'):SetVisible(trigger.mapWidgetVis_items)
		end, false, nil, 'mapWidgetVis_items')
	end
	
	if isBackpack then

		libGeneral.createGroupTrigger('gameInventory'..index..'VisInfo', {
			'ActiveInventory'..index..'.exists',
			'ActiveInventory'..index..'.isActivatable',
			'ActiveInventory'..index..'.alwaysShowOnSkillbar',
			'ModifierKeyStatus.moreInfoKey',
			'ShopActive.isActive',
			'GamePhase.gamePhase',
			'gamePanelInfo.backpackVis',
			'gamePanelInfo.mapWidgetVis_tabbing',
		})

		for k,v in ipairs(object:GetGroup('gameInventory'..index..'Containers')) do
			v:RegisterWatchLua('gameInventory'..index..'VisInfo', function(widget, groupTrigger)
				local triggerInventory		= groupTrigger['ActiveInventory'..index]
				local exists				= triggerInventory.exists
				local isActivatable			= triggerInventory.isActivatable
				local alwaysShowOnSkillbar	= triggerInventory.alwaysShowOnSkillbar
				local shopActive			= groupTrigger['ShopActive'].isActive
				local moreInfoKey			= groupTrigger['ModifierKeyStatus'].moreInfoKey
				local backpackVis			= groupTrigger['gamePanelInfo'].backpackVis
				local mapWidgetVis_tabbing	= groupTrigger['gamePanelInfo'].mapWidgetVis_tabbing
				local mapWidgetVis_inventory = groupTrigger['gamePanelInfo'].mapWidgetVis_inventory
				local gamePhase				= groupTrigger['GamePhase'].gamePhase

				libGeneral.fade(widget,
					( (exists and gamePhase < 7 and (isActivatable or alwaysShowOnSkillbar)) or ((moreInfoKey or shopActive or backpackVis) and mapWidgetVis_inventory and mapWidgetVis_tabbing) )
				, styles_uiSpaceShiftTime)
			end)
		end
	else -- not backpack, is consumable/boots instead

		if isBoots then

			libGeneral.createGroupTrigger('gameInventory'..index..'VisInfo', {
				'ActiveInventory'..index..'.exists',
				'ActiveInventory'..index..'.isActivatable',
				'ModifierKeyStatus.moreInfoKey',
				'ShopActive.isActive',
				'GamePhase.gamePhase',
				'gamePanelInfo.backpackVis',
				'gamePanelInfo.mapWidgetVis_tabbing',
			})
			for k,v in ipairs(object:GetGroup('gameInventory'..index..'Containers')) do
				v:RegisterWatchLua('gameInventory'..index..'VisInfo', function(widget, groupTrigger)
					local triggerInventory	= groupTrigger['ActiveInventory'..index]
					local exists			= triggerInventory.exists
					local isActivatable		= triggerInventory.isActivatable
					local shopActive		= groupTrigger['ShopActive'].isActive
					local moreInfoKey		= groupTrigger['ModifierKeyStatus'].moreInfoKey
					local backpackVis		= groupTrigger['gamePanelInfo'].backpackVis
					local mapWidgetVis_inventory		= groupTrigger['gamePanelInfo'].mapWidgetVis_inventory
					local mapWidgetVis_tabbing		= groupTrigger['gamePanelInfo'].mapWidgetVis_tabbing
					local gamePhase			= groupTrigger['GamePhase'].gamePhase
		
					libGeneral.fade(widget,
						(( (exists and isActivatable) or ((moreInfoKey or shopActive or backpackVis) and mapWidgetVis_inventory and mapWidgetVis_tabbing) ) and gamePhase < 7)
					, styles_uiSpaceShiftTime)
				end)

			end
		else	-- consumables
			-- afasfdfd
		end
	end

end

local function inventoryRegisterBasic(object, index, suffix, tabShow)
	suffix = suffix or ''
	tabShow = tabShow or false
	inventoryRegisterIcon(object, index, nil, suffix)
	inventoryRegisterCooldown(object, index, suffix)
	inventoryRegisterButtonSimple(object, index, false, false, false, suffix)
	inventoryRegisterAutocast(object, index, suffix)
	inventoryRegisterTargeting(object, index, suffix)
	inventoryRegisterGloss(object, index, suffix)
	inventoryRegisterTimerVert(object, index, suffix)
	inventoryRegisterManaTimer(object, index, suffix)
	inventoryRegisterHotkeyLabel(object, index, suffix, tabShow)
	inventoryRegisterRebindableKey(object, index, nil, suffix, nil, tabShow)
end

--inventoryRegisterBasic(object, 8, nil, true)
--inventoryRegisterBasic(object, 11, nil, true)

if (shopGetInterface) then
	inventoryRegisterBasic(shopGetInterface(), 11, 'B') --< this is the shop courier icon
end
