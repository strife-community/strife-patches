-- Game 2 (06/2013)
local floor = math.floor
local ceil	= math.ceil
local max	= math.max
local min	= math.min
local interface = object
gameUI = gameUI or {}
gameUI.playerWasDead = false
mainUI = mainUI or {}
mainUI.savedLocally 	= mainUI.savedLocally 	or {}
mainUI.savedRemotely 	= mainUI.savedRemotely 	or {}
mainUI.minimapFlipped 	= false
local MAX_PRIMARY_ABILITIES = 3

local GetTrigger = LuaTrigger.GetTrigger

if interface:GetName() == 'game' then
	function gameGetInterface()
		return interface
	end

	function gameGetWidget(widgetName)
		return interface:GetWidget(widgetName)
	end	
end

function gameToggleShowSkills(widget, keepOpen)
	keepOpen = keepOpen or false
	if trigger_gamePanelInfo.shopOpen then
		if trigger_gamePanelInfo.abilityPanel and (not keepOpen) then
			trigger_gamePanelInfo.shopOpen = false
			if not LuaTrigger.GetTrigger('ShopActive').isActive then
				trigger_gamePanelInfo:Trigger(false)
			end
			widget:UICmd("CloseShop()")
		else
			trigger_gamePanelInfo.abilityPanel = true
			trigger_gamePanelInfo:Trigger(false)
		end
	else
		widget:UICmd("OpenShop()")
		trigger_gamePanelInfo.abilityPanel = true
		trigger_gamePanelInfo.shopOpen = true	-- So shop doesn't try to override this later
		trigger_gamePanelInfo:Trigger(false)
	end
end

local function GameMenuToggle()
	if GetWidget('game_menu_parent', 'game', true) then
		GetWidget('game_menu_parent', 'game', true):SetVisible(not GetWidget('game_menu_parent', 'game', true):IsVisible())
	end
end
object:RegisterWatch('gameToggleMenu', function(widget, keyDown)
	if AtoB(keyDown) then
		GameMenuToggle()
	end
end)

local function EnableScreenEdgeFeedback(object)
	local screenFeedbackActive = 0 			--[[
		9 Dead / Respawn
		7 Crowd Control (stun / poly)
		x Silenced / Disarm
		x Attempt to cast while OOM
		4 ScreenFlashDamage
		3 Damaged (and on screen) / (and off screen)
		x Low Health
		x Levelup
		x Base Under Attack				BuildingAttackAlert / EventBuildingKill
		x Null
	--]]

	local screen_effect_frame_0			= object:GetWidget('screen_effect_frame_0')
	local screen_effect_frame_1			= object:GetWidget('screen_effect_frame_1')
	local screen_effect_frame_2			= object:GetWidget('screen_effect_frame_2')
	local game_deathfx					= object:GetWidget('game_deathfx')

	local game_warning_frame_group_0 = object:GetGroup('game_warning_frame_group_0')
	local game_warning_frame_group_1 = object:GetGroup('game_warning_frame_group_1')
	local game_warning_frame_group_2 = object:GetGroup('game_warning_frame_group_2')

	local heartpulseLastTime	= 0
	local heartbeatMinDuration	= 400
	local heartbeatMultiplier	= 3000
	local heartpulseOn			= false

	local lastHeroHealthPercent		= 1
	local lastDamageAlertTime		= 0

	local totalDamagetLastClear		= 0
	local totalDamagePercent		= 0

	local fadingIn = false

	
	screen_effect_frame_0:UnregisterWatchLua('HeroUnit')
	screen_effect_frame_0:RegisterWatchLua('HeroUnit', function(widget, trigger)

		if ((trigger.health > 0) and (trigger.healthPercent < 0.50)) then

			for index, groupWidget in ipairs(game_warning_frame_group_0) do
				groupWidget:SetColor('1 0 0 ' .. (0.65 - (1.1 * trigger.healthPercent)) )
			end

			widget:SetVisible(1)
		else
			widget:FadeOut(500)
		end
	end, true, nil, 'healthPercent', 'health')
	
	screen_effect_frame_1:UnregisterWatchLua('HeroUnit')
	screen_effect_frame_1:RegisterWatchLua('HeroUnit', function(widget, trigger)

		if (trigger.health > 0 and trigger.healthPercent < 0.42) then

			if not heartpulseOn then
				heartpulseOn = true

				for index, groupWidget in ipairs(game_warning_frame_group_1) do
					groupWidget:SetColor('1 0 0 0.3') -- .. (0.30 - (0.5 * trigger.healthPercent)) )
				end

				widget:FadeIn(150)
				widget:UnregisterWatchLua('System')
				local isFadingIn = false
				widget:RegisterWatchLua('System', function(widget2, trigger2)
					local triggerHealth		= LuaTrigger.GetTrigger('HeroUnit')
					local curTime			= trigger2.hostTime
					local heartbeatDelay	= max(
						heartbeatMinDuration,
						heartbeatMultiplier * triggerHealth.healthPercent
					)

					if ((curTime - (heartbeatDelay)) >= heartpulseLastTime) then

						if (isFadingIn) then
							widget2:FadeOut(heartbeatDelay * 0.99)
							isFadingIn = false
						else
							widget2:FadeIn(heartbeatDelay * 0.99)
							isFadingIn = true
						end

						if (trigger.inCombat) then
							PlaySound('/ui/_effects/heartbeat.wav')
						end

						heartpulseLastTime = curTime

					end
				end, false, nil, 'hostTime')

			end
		elseif (heartpulseOn) then
			heartpulseOn = false
			widget:FadeOut(500)
			widget:UnregisterWatchLua('System')
		end
	end, true, nil, 'health', 'healthPercent', 'inCombat')

	game_deathfx:UnregisterWatchLua('HeroUnit')
	game_deathfx:RegisterWatchLua('HeroUnit', function(widget, trigger)	-- Death and Respawn

		if (trigger.isActive or trigger.deathProtected) then
			Set('vid_postEffectPath', '/core/post/null.posteffect',  'string')

			game_deathfx:FadeOut(125)
			if (screenFeedbackActive <= 9) and (gameUI.playerWasDead) then

				screenFeedbackActive = 9

				local triggerHostTime			= 	LuaTrigger.GetTrigger('System')

				local tempTime = triggerHostTime.hostTime

				if (not trigger.isOnScreen) then

					for index, groupWidget in ipairs(game_warning_frame_group_2) do
						groupWidget:SetColor('0.5 1 0 1.0')
					end
					widget:FadeIn(250)

					widget:UnregisterWatchLua('System')
					widget:RegisterWatchLua('System', function(widget2, trigger2)
						if (trigger2.hostTime > (tempTime + 2500)) then
							widget:FadeOut(500)
							screenFeedbackActive = -1
							widget2:UnregisterWatchLua('System')
						end
					end, false, nil, 'hostTime')

				else

					for index, groupWidget in ipairs(game_warning_frame_group_2) do
						groupWidget:SetColor('0.5 1 0 0.0')
					end
					widget:FadeIn(250)

					widget:UnregisterWatchLua('System')
					widget:RegisterWatchLua('System', function(widget2, trigger2)
						if (trigger2.hostTime > (tempTime + 750)) then
							widget:FadeOut(500)
							screenFeedbackActive = -1
							widget2:UnregisterWatchLua('System')
						end
					end, false, nil, 'hostTime')

				end

			end
			gameUI.playerWasDead = false
		else
			gameUI.playerWasDead = true
			Set('vid_postEffectPath', '/core/post/grayscale_light.posteffect',  'string')
			if (screenFeedbackActive <= 9) then

				screenFeedbackActive = 9

				for index, groupWidget in ipairs(game_warning_frame_group_2) do
					groupWidget:SetColor('1 1 1 0.10')
				end

				game_deathfx:FadeIn(4500)
			end
		end
	end, true, nil, 'isActive', 'deathProtected')

	screen_effect_frame_2:UnregisterWatchLua('HeroUnit')
	screen_effect_frame_2:RegisterWatchLua('HeroUnit', function(widget, trigger)

		local triggerHostTime			= 	LuaTrigger.GetTrigger('System')

		if (screenFeedbackActive <= 7) then
			if (trigger.isImmobilized) or (trigger.isStunned) then
				screenFeedbackActive = 7
				if not widget:IsVisibleSelf() then
					for index, groupWidget in ipairs(game_warning_frame_group_2) do
						groupWidget:SetColor('0 1 1 0.35')
					end
					widget:SetVisible(true)
				end
			elseif (trigger.isSilenced) or (trigger.isPerplexed) or (trigger.isDisarmed) or (trigger.isIsolated) or (trigger.isRestrained)  then
				screenFeedbackActive = 7
				if not widget:IsVisibleSelf() then
					for index, groupWidget in ipairs(game_warning_frame_group_2) do
						groupWidget:SetColor('1 0 1 0.35')
					end
					widget:SetVisible(true)
				end
			elseif (screenFeedbackActive == 7) then
				if widget:IsVisibleSelf() then
					widget:FadeOut(250)
				end
				screenFeedbackActive = -1
			end
		end

		if (triggerHostTime.hostTime > (totalDamagetLastClear + 750)) then
			totalDamagetLastClear = triggerHostTime.hostTime
			totalDamagePercent = 0
		end

		if ((lastHeroHealthPercent - trigger.healthPercent) > 0.00) then
			totalDamagePercent = totalDamagePercent + (lastHeroHealthPercent - trigger.healthPercent)
		end

		if (screenFeedbackActive <= 3) and (trigger.health > 0) and ( ((trigger.isOnScreen) and (totalDamagePercent > 0.03)) or ((not trigger.isOnScreen) and ((totalDamagePercent) > 0.01)) ) then

			screenFeedbackActive = 3

			for index, groupWidget in ipairs(game_warning_frame_group_2) do
				if (trigger.isOnScreen) then
					groupWidget:SetColor('1 0 0 ' .. min(0.85, max(0.10, (totalDamagePercent * 5) ) ))
				else
					groupWidget:SetColor('1 0 0 0.90')
				end
			end

			if (triggerHostTime.hostTime > (lastDamageAlertTime + 550)) then

				lastDamageAlertTime 		= triggerHostTime.hostTime

				if (trigger.isOnScreen) then
					widget:SetVisible(1)
				else
					PlaySound('/ui/_effects/heartbeat.wav')
					widget:SetVisible(1)
				end

				widget:UnregisterWatchLua('System')
				if (trigger.isOnScreen) then
					widget:RegisterWatchLua('System', function(widget2, trigger2)
						if (trigger2.hostTime > (lastDamageAlertTime + 500 + (totalDamagePercent * 3000))) then
							widget:FadeOut(500)
							screenFeedbackActive = -1
							widget2:UnregisterWatchLua('System')
						end
					end, false, nil, 'hostTime')
				else
					widget:RegisterWatchLua('System', function(widget2, trigger2)
						if (trigger2.hostTime > (lastDamageAlertTime + 500)) then
							widget:FadeOut(500)
							screenFeedbackActive = -1
							widget2:UnregisterWatchLua('System')
						end
					end, false, nil, 'hostTime')
				end
			end
		end

		lastHeroHealthPercent = trigger.healthPercent

		if (screenFeedbackActive <= 1) then
			if (trigger.availablePoints > 0) then
				screenFeedbackActive = 1
				for index, groupWidget in ipairs(game_warning_frame_group_2) do
					groupWidget:SetColor('0 1 1 0.1')
				end
				widget:FadeIn(150)
			elseif (screenFeedbackActive == 1) then
				widget:FadeOut(150)
				screenFeedbackActive = -1
			end
		end

	end, true, nil, 'health', 'healthPercent', 'availablePoints', 'isActive', 'inCombat', 'isStunned', 'isImmobilized', 'isPerplexed', 'isRestrained', 'isSilenced', 'isDisarmed', 'isIsolated')

	screen_effect_frame_2:UnregisterWatchLua('BuildingAttackAlert')
	screen_effect_frame_2:RegisterWatchLua('BuildingAttackAlert', function(widget, trigger)

		if (trigger.name) and (trigger.isSameTeam) then

			if (screenFeedbackActive < 2) then

				screenFeedbackActive = 2

				local triggerHostTime			= 	LuaTrigger.GetTrigger('System')

				local tempTime = triggerHostTime.hostTime


				for index, groupWidget in ipairs(game_warning_frame_group_2) do
					groupWidget:SetColor('0.5 0 .5 0.3')
				end
				widget:FadeIn(250)

				widget:UnregisterWatchLua('System')
				widget:RegisterWatchLua('System', function(widget2, trigger2)
					if (trigger2.hostTime > (tempTime + 1500)) then
						widget:FadeOut(500)
						screenFeedbackActive = -1
						widget2:UnregisterWatchLua('System')
					end
				end, false, nil, 'hostTime')

			end
		end
	end)

	screen_effect_frame_2:UnregisterWatchLua('EventNoMana')
	screen_effect_frame_2:RegisterWatchLua('EventNoMana', function(widget, trigger)

		if (screenFeedbackActive < 6) then

			screenFeedbackActive = 6

			local triggerHostTime			= 	LuaTrigger.GetTrigger('System')

			local tempTime = triggerHostTime.hostTime


			for index, groupWidget in ipairs(game_warning_frame_group_2) do
				groupWidget:SetColor('0.0 0.0 .5 0.70')
			end
			widget:FadeIn(125)

			widget:UnregisterWatchLua('System')
			widget:RegisterWatchLua('System', function(widget2, trigger2)
				if (trigger2.hostTime > (tempTime + 750)) then
					widget:FadeOut(125)
					screenFeedbackActive = -1
					widget2:UnregisterWatchLua('System')
				end
			end, false, nil, 'hostTime')

		end
	end)

	screen_effect_frame_2:UnregisterWatchLua('EventOnCooldown')
	screen_effect_frame_2:RegisterWatchLua('EventOnCooldown', function(widget, trigger)

		if (screenFeedbackActive < 5) then

			screenFeedbackActive = 5

			local triggerHostTime			= 	LuaTrigger.GetTrigger('System')

			local tempTime = triggerHostTime.hostTime


			for index, groupWidget in ipairs(game_warning_frame_group_2) do
				groupWidget:SetColor('0.0 0.0 .5 0.35')
			end
			widget:FadeIn(125)

			widget:UnregisterWatchLua('System')
			widget:RegisterWatchLua('System', function(widget2, trigger2)
				if (trigger2.hostTime > (tempTime + 750)) then
					widget:FadeOut(125)
					screenFeedbackActive = -1
					widget2:UnregisterWatchLua('System')
				end
			end, false, nil, 'hostTime')

		end
	end)
end

local function DisableScreenEdgeFeedback(object)
	local screen_effect_frame_0			= object:GetWidget('screen_effect_frame_0')
	local screen_effect_frame_1			= object:GetWidget('screen_effect_frame_1')
	local screen_effect_frame_2			= object:GetWidget('screen_effect_frame_2')
	local game_deathfx					= object:GetWidget('game_deathfx')
	
	screen_effect_frame_0:SetVisible(false)
	screen_effect_frame_1:SetVisible(false)
	screen_effect_frame_2:SetVisible(false)
	game_deathfx:SetVisible(false)
	
	screen_effect_frame_0:UnregisterWatchLua('System')
	screen_effect_frame_1:UnregisterWatchLua('System')
	screen_effect_frame_2:UnregisterWatchLua('System')
	
	screen_effect_frame_0:UnregisterWatchLua('HeroUnit')
	screen_effect_frame_1:UnregisterWatchLua('HeroUnit')
	screen_effect_frame_2:UnregisterWatchLua('HeroUnit')
	screen_effect_frame_2:UnregisterWatchLua('HeroUnit')
	screen_effect_frame_2:UnregisterWatchLua('BuildingAttackAlert')
	screen_effect_frame_2:UnregisterWatchLua('EventNoMana')
	screen_effect_frame_2:UnregisterWatchLua('EventOnCooldown')
end

local function updateScreenFeedback(object, enabled)
	if (enabled) then
		EnableScreenEdgeFeedback(object)
	else
		DisableScreenEdgeFeedback(object)
	end
end
updateScreenFeedback(object, Cvar.GetCvar('_game_screenFeedbackVis'):GetBoolean())

local function updateElementsPosition()
	local swapSides = 1
	if GetCvarBool('ui_swapMinimap') then
		swapSides = -1
	end
	local minimapContainers			= interface:GetGroup('gameMinimapContainers')
	local menuParent = interface:GetWidget('game_menu_parent')
	
	for k,v in ipairs(minimapContainers) do
		if (swapSides == 1) then
			if (v:GetAlign() ~= 'right') then
				v:SetAlign('right')
			end
			v:SetX('0.5h')
		else
			if (v:GetAlign() ~= 'left') then
				v:SetAlign('left')
			end
			v:SetX('-0.5h')
		end
	end
	
	LuaTrigger.GetTrigger('gameArrangeInventoryInfo'):Trigger(true)
	
	if (menuParent) then
		if (swapSides == 1) then
			if (menuParent:GetAlign() ~= 'right') then
				menuParent:SetAlign('right')
			end
			menuParent:SetX('-0.25h')
		else
			if (menuParent:GetAlign() ~= 'left') then
				menuParent:SetAlign('left')
			end
			menuParent:SetX('-2h')
		end
	end
end

UnwatchLuaTriggerByKey('optionsTrigger', 'optionsTriggerScreenFeedback')
WatchLuaTrigger('optionsTrigger', function()
	updateScreenFeedback(interface, Cvar.GetCvar('_game_screenFeedbackVis'):GetBoolean())
	updateElementsPosition()
end, 'optionsTriggerScreenFeedback')

local function gameRegisterBindableHotkey(object, buttonID, onButtonClick, triggerRefresh)
	local button		= object:GetWidget(buttonID..'Button')
	local backer		= object:GetWidget(buttonID..'Backer')
	local body			= object:GetWidget(buttonID..'Body')
	local label			= object:GetWidget(buttonID..'Label')
	local highlight		= object:GetWidget(buttonID..'Highlight')
	local buttonTip		= object:GetWidget(buttonID..'ButtonTip')
	
	triggerRefresh = triggerRefresh or false
	
	button:RegisterWatchLua('ModifierKeyStatus', function(widget, trigger)
		widget:SetNoClick(not trigger.moreInfoKey)
	end, false)

	backer:RegisterWatchLua('ModifierKeyStatus', function(widget, trigger)
		if trigger.moreInfoKey then
			widget:SetColor(styles_colors_hotkeyCanSet)
			widget:SetBorderColor(styles_colors_hotkeyCanSet)
		else
			widget:SetColor(styles_colors_hotkeyNoSet)
			widget:SetBorderColor(styles_colors_hotkeyNoSet)
		end
	end, false)

	buttonTip:SetCallback('onmouseover', function(widget)
		simpleTipNoFloatUpdate(true, nil, Translate('game_keybind_1'), Translate('game_keybind_2', 'value', GetKeybindButton('game', 'TriggerToggle', 'gameShowMoreInfo', 0)), nil, nil, libGeneral.HtoP(-18), 'center', 'bottom')
		
		UpdateCursor(widget, true, { canLeftClick = true})
	end)

	buttonTip:SetCallback('onmouseout', function(widget)
		simpleTipNoFloatUpdate(false)
		UpdateCursor(widget, false, { canLeftClick = true})
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
		onButtonClick(widget, buttonInfo)
	end)
	
	if triggerRefresh then
		label:RegisterWatchLua('gameRefreshKeyLabels', function(widget, trigger)
			widget:DoEvent()			
		end)
	end
end

gameRegisterBindableHotkey(object, 'gameShopHotkey', function()
	local binderData	= LuaTrigger.GetTrigger('buttonBinderData')
	local oldButton		= nil
	binderData.show			= true
	binderData.table		= 'game'
	binderData.action		= 'ToggleShop'
	binderData.param		= ''
	binderData.keyNum		= 0	-- 0 for leftclick, 1 for rightclick
	binderData.impulse		= true
	binderData.oldButton	= (GetKeybindButton('game', 'ToggleShop', '', 0) or 'None')
	binderData:Trigger()
end, true)

object:GetWidget('gameShopHotkey'):RegisterWatchLua('gamePanelInfo', function(widget, trigger)
	widget:SetVisible(trigger.mapWidgetVis_canToggleShop)
end, false, nil, 'mapWidgetVis_canToggleShop')

gameRegisterBindableHotkey(object, 'abilitiesLevelUpButtonKey', function()
	local binderData	= LuaTrigger.GetTrigger('buttonBinderData')
	local oldButton		= nil
	binderData.show			= true
	binderData.table		= 'game'
	binderData.action		= 'TriggerToggle'
	binderData.param		= 'gameShowSkills'
	binderData.keyNum		= 0	-- 0 for leftclick, 1 for rightclick
	binderData.impulse		= false
	binderData.oldButton	= (GetKeybindButton('game', 'TriggerToggle', 'gameShowSkills', 0) or 'None')
	binderData:Trigger()
end, true)

gameRegisterBindableHotkey(object, 'gameMenuButtonKey', function()
	local binderData	= LuaTrigger.GetTrigger('buttonBinderData')
	local oldButton		= nil
	binderData.show			= true
	binderData.table		= 'game'
	binderData.action		= 'TriggerToggle'
	binderData.param		= 'gameToggleMenu'
	binderData.keyNum		= 0	-- 0 for leftclick, 1 for rightclick
	binderData.impulse		= false
	binderData.oldButton	= (GetKeybindButton('game', 'TriggerToggle', 'gameToggleMenu', 0) or 'None')
	binderData:Trigger()
end, true)

local cursorDragDetectAmount = libGeneral.HtoP(3)

function registerRadialCommand(object)
	local waitingThread = nil
	local rotatingThread = nil
	local masterWidget = object:GetWidget("radial_selection_command")
	
	masterWidget:RegisterWatchLua('PingWheelInfo', function(widget, trigger)
		local startX = tonumber(string.sub(trigger.mousePos, 0, string.find(trigger.mousePos, " ")))
		local startY = tonumber(string.sub(trigger.mousePos,    string.find(trigger.mousePos, " ")+1))
		openRadialCommand(1, Input.GetCursorPosX()-startX, Input.GetCursorPosY()-startY, trigger.worldPos, trigger.isMiniMap)
	end)
end

function registerRadialChat(object)
	local waitingThread = nil
	local rotatingThread = nil
	local masterWidget = object:GetWidget("radial_selection_chat")
	
	masterWidget:RegisterWatch('gameShowChatWheel', function(widget, keyDown)
		if AtoB(keyDown) then	
			openRadialChat(1)
		else
			if GameUI.RadialSelection.RadialSelectionOpen['chat'] then
				GameUI.RadialSelection.confirmSelection()
			end
			GameUI.RadialSelection:hide('chat')
		end	
	end)
	
end

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

			if isPrimary and (levelUpGroupTrigger['ModifierKeyStatus'].moreInfoKey) and (levelUpGroupTrigger['ActiveUnit'].availablePoints > 0) and (levelUpGroupTrigger['ActiveInventory'..index].canLevelUp) then
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

	local icon = object:GetWidget('gameInventory'..index..suffix..'Icon')
	local icon_cd = object:GetWidget('gameInventory'..index..suffix..'Icon_cd')
	local iconPulse = object:GetWidget('gameInventory'..index..suffix..'IconPulse')
	local iconCooldownText = object:GetWidget('gameInventory'..index..'Cooldown')

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
if hero == "" then -- New game
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
	suffix = suffix or ''
	isBackpack = isBackpack or false
	isItem = isItem or false
	isItem = isBackpack or isItem or false
	tabShow = tabShow or false
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
				Body		= object:GetWidget('gameInventory'..index..suffix..'HotkeyBody'),
				Highlight	= object:GetWidget('gameInventory'..index..suffix..'HotkeyHighlight')
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

local function inventoryRegisterPet(object)
	local activatableID		= 18
	local passiveActiveID	= 17
	local passiveID			= 16

	LuaTrigger.CreateGroupTrigger('abilityBarPetVis', {
		'gamePanelInfo.mapWidgetVis_abilityBarPet',
		'ActiveInventory18.exists',
		'GamePhase.gamePhase'
	})
	
	for k,v in ipairs(object:GetGroup('gameInventoryPetContainers')) do
		v:RegisterWatchLua('abilityBarPetVis', function(widget, groupTrigger)
			widget:SetVisible(groupTrigger['GamePhase'].gamePhase < 7 and groupTrigger['gamePanelInfo'].mapWidgetVis_abilityBarPet and groupTrigger['ActiveInventory18'].exists)
		end)	-- , false, nil, 'mapWidgetVis_abilityBarPet'
	end
	


	inventoryRegisterIcon(object, activatableID)
	inventoryRegisterCooldown(object, activatableID)
	inventoryRegisterGloss(object, activatableID)
	inventoryRegisterButtonSimple(object, activatableID)
	inventoryRegisterHotkeyLabel(object, activatableID)
	inventoryRegisterRebindableKey(object, activatableID)
	inventoryRegisterTargeting(object, activatableID)

	inventoryRegisterIcon(object, passiveActiveID)
	inventoryRegisterCooldown(object, passiveActiveID)
	inventoryRegisterButtonSimple(object, passiveActiveID)
	inventoryRegisterGloss(object, passiveActiveID)

	object:GetWidget('gameInventory'..passiveActiveID..'IconCover'):RegisterWatchLua('ActiveInventory'..passiveActiveID, function(widget, trigger)
		widget:SetVisible(not trigger.exists)
	end, false, nil, 'exists')

	object:GetWidget('gameInventory'..passiveActiveID..'Lock'):RegisterWatchLua('ActiveInventory'..passiveActiveID, function(widget, trigger)
		widget:SetVisible(not trigger.exists)
	end, false, nil, 'exists')
	--[[
	object:GetWidget('gameInventoryPetIcon'):RegisterWatchLua('ActiveUnit', function(widget, trigger)
		local entityName = trigger.familiar
		if entityName and string.len(entityName) > 0 then
			widget:SetTexture(GetEntityIconPath(entityName))
		end
	end, false, nil, 'familiar')
	--]]

	local tipContainer	= object:GetWidget('gamePetTip')

	function gamePetTipShow()
		tipContainer:SetVisible(true)
	end

	function gamePetTipHide()
		tipContainer:SetVisible(false)
	end

	local petAbilityContainer	= object:GetWidget('gameInventory18Backer')
	petAbilityContainer:SetCallback('onmouseover', function(widget)
		gamePetTipShow()
	end)

	petAbilityContainer:SetCallback('onmouseover', function(widget)
		gamePetTipHide()
	end)


	object:GetWidget('gameInventory'..activatableID..'Button'):SetCallback('onmouseover', function(widget)
		gamePetTipShow()
	end)

	object:GetWidget('gameInventory'..activatableID..'Button'):SetCallback('onmouseout', function(widget)
		gamePetTipHide()
	end)

	object:GetWidget('gameInventory'..passiveActiveID..'Button'):SetCallback('onmouseover', function(widget)
		gamePetTipShow()
	end)

	object:GetWidget('gameInventory'..passiveActiveID..'Button'):SetCallback('onmouseout', function(widget)
		gamePetTipHide()
	end)

	object:GetWidget('gameInventory'..activatableID..'Backer'):SetCallback('onmouseover', function(widget)
		gamePetTipShow()
	end)

	object:GetWidget('gameInventory'..activatableID..'Backer'):SetCallback('onmouseout', function(widget)
		gamePetTipHide()
	end)

	object:GetWidget('gamePetTipDescription'):RegisterWatchLua('HeroUnit', function(widget, trigger)
		widget:SetText(trigger.familiarDescription)
	end, false, nil, 'familiarDescription')

	object:GetWidget('gamePetTipIcon'):RegisterWatchLua('HeroUnit', function(widget, trigger)
		if (trigger.familiar) and ValidateEntity(trigger.familiar) then
			widget:SetTexture(GetEntityIconPath((trigger.familiar)))
		end
	end, false, nil, 'familiar')	
	
	object:GetWidget('gamePetTipActive'):RegisterWatchLua('ActiveInventory'..activatableID, function(widget, trigger) widget:SetVisible(trigger.exists) end, false, nil, 'exists')
	object:GetWidget('gamePetTipActiveName'):RegisterWatchLua('ActiveInventory'..activatableID, function(widget, trigger) widget:SetText(trigger.displayName) end, false, nil, 'displayName')
	object:GetWidget('gamePetTipActiveIcon'):RegisterWatchLua('ActiveInventory'..activatableID, function(widget, trigger) widget:SetTexture(trigger.icon) end, false, nil, 'icon')
	object:GetWidget('gamePetTipActiveDescription'):RegisterWatchLua('ActiveInventory'..activatableID, function(widget, trigger) widget:SetText(trigger.description) end, false, nil, 'description')
	object:GetWidget('gamePetTipActiveCooldown'):RegisterWatchLua('ActiveInventory'..activatableID, function(widget, trigger) widget:SetText(libNumber.timeFormat(trigger.cooldownTime)) end, false, nil, 'cooldownTime')
	object:GetWidget('gamePetTipActiveHotkey'):RegisterWatchLua('ActiveInventory'..activatableID, function(widget, trigger) widget:SetText(trigger.binding1) end, false, nil, 'binding1')

	object:GetWidget('gamePetTipTriggered'):RegisterWatchLua('ActiveInventory'..passiveActiveID, function(widget, trigger) widget:SetVisible(trigger.exists) end, false, nil, 'exists')
	object:GetWidget('gamePetTipTriggeredName'):RegisterWatchLua('ActiveInventory'..passiveActiveID, function(widget, trigger) widget:SetText(trigger.displayName) end, false, nil, 'displayName')
	object:GetWidget('gamePetTipTriggeredIcon'):RegisterWatchLua('ActiveInventory'..passiveActiveID, function(widget, trigger) widget:SetTexture(trigger.icon) end, false, nil, 'icon')
	object:GetWidget('gamePetTipTriggeredDescription'):RegisterWatchLua('ActiveInventory'..passiveActiveID, function(widget, trigger) widget:SetText(trigger.description) end, false, nil, 'description')
	object:GetWidget('gamePetTipTriggeredCooldown'):RegisterWatchLua('ActiveInventory'..passiveActiveID, function(widget, trigger) widget:SetText(libNumber.timeFormat(trigger.cooldownTime)) end, false, nil, 'cooldownTime')

	object:GetWidget('gamePetTipPassive'):RegisterWatchLua('ActiveInventory'..passiveID, function(widget, trigger) widget:SetVisible(trigger.exists) end, false, nil, 'exists')
	object:GetWidget('gamePetTipPassiveName'):RegisterWatchLua('ActiveInventory'..passiveID, function(widget, trigger) widget:SetText(trigger.displayName) end, false, nil, 'displayName')
	object:GetWidget('gamePetTipPassiveIcon'):RegisterWatchLua('ActiveInventory'..passiveID, function(widget, trigger) widget:SetTexture(trigger.icon) end, false, nil, 'icon')
	object:GetWidget('gamePetTipPassiveDescription'):RegisterWatchLua('ActiveInventory'..passiveID, function(widget, trigger) widget:SetText(trigger.description) end, false, nil, 'description')

end

local function inventoryRegisterItem(object, index, isBackpack, isBoots)
	if isBackpack == nil then isBackpack = true end
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

for i=97,102,1 do
	inventoryRegisterItem(object, i)
end

inventoryRegisterItem(object, 103, false)	-- Consumable
inventoryRegisterItem(object, 104, false)	-- Consumable

libGeneral.createGroupTrigger('gameConsumablesVis', {
	'ActiveInventory103.exists',
	'ActiveInventory104.exists',
	'ShopActive.isActive',
	'ModifierKeyStatus.moreInfoKey',
	'gamePanelInfo.backpackVis',
	'gamePanelInfo.mapWidgetVis_tabbing',
	'GamePhase.gamePhase',
})

for k,v in ipairs(object:GetGroup('gameInventoryConsumablesContainers')) do
	v:RegisterWatchLua('gameConsumablesVis', function(widget, groupTrigger)
		local moreInfoKey			= groupTrigger['ModifierKeyStatus'].moreInfoKey
		local inventory103Exists	= groupTrigger['ActiveInventory103'].exists
		local inventory104Exists	= groupTrigger['ActiveInventory104'].exists
		local shopActive			= groupTrigger['ShopActive'].isActive
		local backpackVis			= groupTrigger['gamePanelInfo'].backpackVis
		local mapWidgetVis_inventory			= groupTrigger['gamePanelInfo'].mapWidgetVis_inventory
		local mapWidgetVis_tabbing			= groupTrigger['gamePanelInfo'].mapWidgetVis_tabbing
		local gamePhase				= groupTrigger['GamePhase'].gamePhase

		libGeneral.fade(widget, (gamePhase < 7 and (((moreInfoKey or backpackVis or shopActive) and mapWidgetVis_inventory and mapWidgetVis_tabbing) or inventory103Exists or inventory104Exists)), styles_uiSpaceShiftTime)
	end)
end

inventoryRegisterItem(object, 96, false, true)	-- Boots

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

inventoryRegisterBasic(object, 8, nil, true)
inventoryRegisterBasic(object, 11, nil, true)
inventoryRegisterBasic(shopGetInterface(), 11, 'B')

for k,v in ipairs(object:GetGroup('gameInventory8Containers')) do
	v:RegisterWatchLua('gamePanelInfo', function(widget, trigger)
		widget:SetVisible(trigger.mapWidgetVis_portHomeButton)
	end, false, nil, 'mapWidgetVis_portHomeButton')
end

for k,v in ipairs(object:GetGroup('gameInventory11Containers')) do
	v:RegisterWatchLua('gamePanelInfo', function(widget, trigger)
		widget:SetVisible(trigger.mapWidgetVis_courierButton)
	end, false, nil, 'mapWidgetVis_courierButton')
end

local function inventoryRegisterLevelup(object, index)

	libGeneral.createGroupTrigger('gameInventory'..index..'LevelUpButtonVis', {'ActiveUnit.availablePoints', 'ModifierKeyStatus.moreInfoKey', 'ActiveInventory'..index..'.canLevelUp'})

	object:GetWidget('gameInventory' .. index .. 'LevelUpButton'):SetCallback('onclick', function(widget)
		PlaySound('/ui/sounds/ui_level_ability.wav', 0.3)
		widget:UICmd("LevelUpAbility("..index..")")
	end)	
	
	object:GetWidget('gameInventory' .. index .. 'LevelUpButton'):RegisterWatchLua('gameInventory'..index..'LevelUpButtonVis', function(widget, groupTrigger)
		widget:SetVisible(
			groupTrigger['ModifierKeyStatus'].moreInfoKey and
			groupTrigger['ActiveUnit'].availablePoints > 0 and
			groupTrigger['ActiveInventory'..index].canLevelUp
		)
	end)
	
	object:GetWidget('gameInventory' .. index .. 'LevelUpIcon'):RegisterWatchLua('gameInventory'..index..'LevelUpButtonVis', function(widget, groupTrigger)
		widget:SetVisible(
			groupTrigger['ModifierKeyStatus'].moreInfoKey and
			groupTrigger['ActiveUnit'].availablePoints > 0 and
			groupTrigger['ActiveInventory'..index].canLevelUp
		)
	end)

	object:GetWidget('gameInventory'..index..'CanLevel'):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
		widget:SetVisible(trigger.canLevelUp)
	end, false, nil, 'canLevelUp')	
	
end

local function inventoryRegisterPrimary(object, index) -- hero primary abilities
	inventoryRegisterIcon(object, index)
	inventoryRegisterCooldown(object, index)
	inventoryRegisterButtonSimple(object, index, false, true)
	inventoryRegisterAutocast(object, index)
	inventoryRegisterTargeting(object, index)
	inventoryRegisterGloss(object, index)
	inventoryRegisterTimerVert(object, index)
	inventoryRegisterManaTimer(object, index)
	inventoryRegisterHotkeyLabel(object, index)
	inventoryRegisterRebindableKey(object, index)
	inventoryRegisterChargePipsPrimary(object, index)
	inventoryRegisterLevelup(object, index)

	LuaTrigger.CreateGroupTrigger('gameInventory'..index..'TimerVis', {
		'ActiveInventory'..index..'.alwaysShowTimer',
		'ActiveInventory'..index..'.hasTimer',
		'GamePhase.gamePhase'
	})
	
	for k,v in pairs(object:GetGroup('gameInventory'..index..'Containers')) do
		v:RegisterWatchLua('SPEAbilityUpdate', function(widget, trigger)
			widget:SetVisible(trigger['ShowActiveAbility'..index])
		end, false, nil)
	end
	
	for k,v in pairs(object:GetGroup('gameInventory'..index..'Containers')) do
		v:RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
			widget:SetVisible(trigger.exists)
		end, true, nil, 'exists')
	end	
	
	for k,v in pairs(object:GetGroup('gameInventory'..index..'TimerContainers')) do
		v:RegisterWatchLua('gameInventory'..index..'TimerVis', function(widget, groupTrigger)
			local triggerTimer	= groupTrigger['ActiveInventory'..index]
			widget:SetVisible((groupTrigger['GamePhase'].gamePhase < 7 and (triggerTimer.alwaysShowTimer or triggerTimer.hasTimer)) or false)
		end)	-- , false, nil, 'alwaysShowTimer', 'hasTimer'
	end
	
	if (object:GetWidget('gameInventory'..index..'TimerBarBody')) then
		object:GetWidget('gameInventory'..index..'TimerBarBody'):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger) widget:SetVisible(trigger.hasTimer) end, false, nil, 'hasTimer')
	end
	
	inventoryRegisterPrimaryLevelPips(object, index)
end

for i=0,MAX_PRIMARY_ABILITIES,1 do
	inventoryRegisterPrimary(object, i)
end

	local gameArrangeInventoryParams = {
		'gamePanelInfo.heroVitalsVis',
		'ModifierKeyStatus.moreInfoKey',
		'ShopActive.isActive',
		'gamePanelInfo.aspect',
		'gamePanelInfo.backpackVis',
		'gamePanelInfo.mapWidgetVis_abilityBarPet',
		'gamePanelInfo.mapWidgetVis_tabbing',
		'ActiveInventory18.exists',
	}


	for i=0,MAX_PRIMARY_ABILITIES,1 do
		table.insert(gameArrangeInventoryParams, 'ActiveInventory'..i..'.alwaysShowTimer')
		table.insert(gameArrangeInventoryParams, 'ActiveInventory'..i..'.hasTimer')
	end

	for i=96,104,1 do
		table.insert(gameArrangeInventoryParams, 'ActiveInventory'..i..'.exists')
		if i < 103 then
			table.insert(gameArrangeInventoryParams, 'ActiveInventory'..i..'.isActivatable')
			if i ~= 96 and i ~= 103 and i ~= 104 then
				table.insert(gameArrangeInventoryParams, 'ActiveInventory'..i..'.AlwaysShowOnSkillbar')
			end
		end
	end

	libGeneral.createGroupTrigger('gameArrangeInventoryInfo', gameArrangeInventoryParams)

	object:RegisterWatchLua('gameArrangeInventoryInfo', function(widget, groupTrigger)
		local moreInfoKey			= groupTrigger['ModifierKeyStatus'].moreInfoKey
		local shopActive			= groupTrigger['ShopActive'].isActive
		local triggerGamePanelInfo	= groupTrigger['gamePanelInfo']
		local heroVitalsVis			= triggerGamePanelInfo.heroVitalsVis
		local aspect				= triggerGamePanelInfo.aspect
		local backpackVis			= triggerGamePanelInfo.backpackVis
		local mapWidgetVis_tabbing			= triggerGamePanelInfo.mapWidgetVis_tabbing
		local mapWidgetVis_inventory			= triggerGamePanelInfo.mapWidgetVis_inventory
		
		local triggersInventory = {}
		for i=96,104,1 do
			triggersInventory[i] = groupTrigger['ActiveInventory'..i]
		end

		for i=0,MAX_PRIMARY_ABILITIES,1 do
			triggersInventory[i] = groupTrigger['ActiveInventory'..i]
		end
		local barYOffset				= 0		-- Add at least 4 or 5 if vitals are up
		local barMaxHeight				= 0		-- Height of tallest item in list
		local slotsPrimary				= {}
		local barPrimaryHeight			= 0
		local barPrimaryWidth			= 0
		local barPrimaryYPos			= libGeneral.HtoP(-0.5)
		local slotsBackpack				= {}
		local slotsPrimaryActivatable	= {}
		local slotsPrimaryNoActivate	= {}

		local slotPadding		= libGeneral.HtoP(0.5)

		local narrowAspect		= (aspect <= 1.6)

		local emptySlotValue	= '-'

		for i=97,102,1 do
			if triggersInventory[i].exists and (triggersInventory[i].isActivatable or triggersInventory[i].alwaysShowOnSkillbar) and (not (shopActive or backpackVis)) then
				if triggersInventory[i].isActivatable then
					table.insert(slotsPrimaryActivatable, widget:GetGroup('gameInventory'..i..'Containers'))
				else
					table.insert(slotsPrimaryNoActivate, widget:GetGroup('gameInventory'..i..'Containers'))
				end
			elseif (shopActive or moreInfoKey or backpackVis) and (mapWidgetVis_inventory) then
				table.insert(slotsBackpack, widget:GetGroup('gameInventory'..i..'Containers'))
			end
		end

		if triggersInventory[96].exists and triggersInventory[96].isActivatable and (not (shopActive or backpackVis)) then
			table.insert(slotsPrimaryActivatable, widget:GetGroup('gameInventory96Containers'))
		elseif (shopActive or moreInfoKey or backpackVis)  and (mapWidgetVis_inventory)  then
			table.insert(slotsBackpack, emptySlotValue)
			table.insert(slotsBackpack, widget:GetGroup('gameInventory96Containers'))
			table.insert(slotsBackpack, emptySlotValue)
		end

		if (triggersInventory[103].exists or triggersInventory[104].exists) and (not (shopActive or backpackVis)) then
			table.insert(slotsPrimaryActivatable, widget:GetGroup('gameInventoryConsumablesContainers'))
		elseif (shopActive or moreInfoKey or backpackVis)  and (mapWidgetVis_inventory) then
			table.insert(slotsBackpack, emptySlotValue)
			table.insert(slotsBackpack, widget:GetGroup('gameInventoryConsumablesContainers'))
			table.insert(slotsBackpack, emptySlotValue)
		end

		for k,v in ipairs(slotsPrimaryNoActivate) do
			table.insert(slotsPrimary, v)
		end

		for k,v in ipairs(slotsPrimaryActivatable) do
			table.insert(slotsPrimary, v)
		end

		for i=0,MAX_PRIMARY_ABILITIES,1 do
			if triggersInventory[i].exists and triggersInventory[i].hasTimer or triggersInventory[i].alwaysShowTimer then
				table.insert(slotsPrimary, widget:GetGroup('gameInventory'..i..'TimerContainers'))
			end
			if triggersInventory[i].exists then 
				table.insert(slotsPrimary, widget:GetGroup('gameInventory'..i..'Containers'))
			end
		end

		if triggerGamePanelInfo.mapWidgetVis_abilityBarPet and groupTrigger['ActiveInventory18'].exists then
			table.insert(slotsPrimary, widget:GetGroup('gameInventoryPetContainers'))
		end
		
		for k,v in ipairs(slotsPrimary) do
			barPrimaryHeight	= max(v[1]:GetHeight(), barPrimaryHeight)
			barPrimaryWidth		= barPrimaryWidth + v[1]:GetWidth() + slotPadding
		end

		barPrimaryWidth = barPrimaryWidth - slotPadding

		local barPrimaryWidgetPos = GetScreenWidth() / 2

		if (heroVitalsVis or moreInfoKey) and mapWidgetVis_tabbing then
			barPrimaryYPos = barPrimaryYPos - libGeneral.HtoP(5)
		end

		for k,v in ipairs(slotsPrimary) do
			for j,l in ipairs(v) do
				local offset = 0 -- this is for when the icons are aligned differently.
				if l:GetAlign() == 'right' then offset = -GetScreenWidth()+l:GetWidth() end
				l:SlideX(
					(barPrimaryWidth / -2) + barPrimaryWidgetPos + offset,
					styles_uiSpaceShiftTime
				)
				l:SlideY(
					barPrimaryYPos - (
						(
						max(v[1]:GetHeight(), barPrimaryHeight)
						 - min(v[1]:GetHeight(), barPrimaryHeight)
						) / 2
					)
					, styles_uiSpaceShiftTime
				)
			end

			barPrimaryWidgetPos = barPrimaryWidgetPos + v[1]:GetWidth() + slotPadding
		end

		table.insert(slotsBackpack, emptySlotValue)
		table.insert(slotsBackpack, widget:GetGroup('gameInventoryPinContainers'))
		table.insert(slotsBackpack, emptySlotValue)
		
		local swapSides = 1
		if GetCvarBool('ui_swapMinimap') then
			swapSides = -1
		end
		
		local barBackpackX			= libGeneral.HtoP(0.5) * swapSides
		local barBackpackY			= libGeneral.HtoP(-0.5)

		local barBackpackRow		= 0
		local barBackpackColWidth	= 0
		local barBackpackRowHeight	= libGeneral.HtoP(6.5)

		for k,v in ipairs(slotsBackpack) do
			if v ~= emptySlotValue then
				for j,l in ipairs(v) do
					if (swapSides == 1) then
						if (l:GetAlign() ~= 'left') then
							l:SetAlign('left')
						end
					else
						if (l:GetAlign() ~= 'right') then
							l:SetAlign('right')
						end
					end
					l:SlideX(barBackpackX, styles_uiSpaceShiftTime)
					l:SlideY(
						barBackpackY - (barBackpackRow * barBackpackRowHeight),
						styles_uiSpaceShiftTime
					)

				end
				barBackpackColWidth = max(barBackpackColWidth, v[1]:GetWidth())
			end

			if narrowAspect then
				if v == emptySlotValue then
					barBackpackRow = 0
					barBackpackX	= barBackpackX + (swapSides * barBackpackColWidth) + (swapSides * slotPadding)
					barBackpackColWidth = 0
				else
					barBackpackRow = barBackpackRow + 1
				end

				if barBackpackRow >= 2 then
					barBackpackRow	= 0
					barBackpackX	= barBackpackX + (swapSides * barBackpackColWidth) + (swapSides * slotPadding)
					barBackpackColWidth = 0
				end

			else
				barBackpackX	= barBackpackX + (swapSides * barBackpackColWidth) + (swapSides * slotPadding)
				barBackpackColWidth = 0
			end

		end

	 end)

inventoryRegisterPet(object)

local function gamePlayerInfoBodiesRegister(object, groupName, triggerName, isSelf)
	isSelf = isSelf or false
	local widgetGroup = object:GetGroup(groupName)

	local paramList = {
		{ name	= 'moreInfo',					type	= 'boolean' },
		{ name	= 'exists',						type	= 'boolean' },
		{ name	= 'isActive',					type	= 'boolean' },
		{ name	= 'isDisconnected',				type	= 'boolean' },
		{ name	= 'isLoading',					type	= 'boolean' },
		{ name	= 'index',						type	= 'number' },
		{ name	= 'isAFK',						type	= 'boolean' },
		{ name	= 'isTalking',					type	= 'boolean' },
		{ name	= 'availablePoints',			type	= 'boolean' },
		{ name	= 'heroInfoVis',				type	= 'boolean' },
		{ name	= 'mapWidgetVis_heroInfos',		type	= 'boolean' }
	}

	local visInfo = LuaTrigger.CreateCustomTrigger('infoBodiesVis_'..triggerName, paramList)
	local visGroup	= libGeneral.createGroupTrigger('infoBodiesVisGroup'..triggerName, { 'infoBodiesVis_'..triggerName, 'SelectedUnits0.index', 'SelectedUnits0.isVisible' })

	if isSelf then

		widgetGroup[1]:RegisterWatchLua(triggerName, function(widget, trigger)
			visInfo.exists			= trigger.exists
			visInfo.isActive		= trigger.isActive
			visInfo.index			= trigger.index
			visInfo.availablePoints	= (trigger.availablePoints > 0)
			visInfo:Trigger(false)
		end, false, nil, 'exists', 'isActive', 'availablePoints', 'index')

		object:GetWidget('gameSelfLevelup'):RegisterWatchLua(triggerName, function(widget, trigger)
			widget:SetVisible(trigger.availablePoints > 0 and trigger.isActive)

			local teamTrigger = LuaTrigger.GetTrigger('Team')

			if (teamTrigger.team ~= 1) then
				widget:SetAlign('center')
				widget:SetX(libGeneral.HtoP(0.4))
			else
				widget:SetAlign('center')
				widget:SetX(libGeneral.HtoP(0.4))
			end
		end, false, nil, 'availablePoints', 'isActive')

		object:GetWidget('gameSelfCanLevel'):RegisterWatchLua('HeroUnit', function(widget, trigger)
			widget:SetVisible(trigger.availablePoints > 0)
		end, true, nil, 'availablePoints')

		object:GetWidget('gameSelfLevelup'):SetNoClick(false)
		-- object:GetWidget('gameSelfLevelup'):RegisterWatchLua('ModifierKeyStatus', function(widget, trigger)
			-- widget:SetNoClick(not trigger.moreInfoKey)
		-- end, false, nil, 'moreInfoKey')

		object:GetWidget('gameSelfLevelup'):SetCallback('onclick', function(widget)
			gameToggleShowSkills(widget)
		end)

	else
		widgetGroup[1]:RegisterWatchLua(triggerName, function(widget, trigger)
			visInfo.exists					= trigger.exists
			visInfo.isActive				= trigger.isActive
			visInfo.isDisconnected			= trigger.isDisconnected
			visInfo.isLoading				= trigger.isLoading
			visInfo.isTalking				= trigger.isTalking
			visInfo.index					= trigger.index

			visInfo:Trigger(false)
		end, false, nil, 'exists', 'isActive', 'isLoading', 'isDisconnected', 'isTalking', 'isAFK', 'index')
	end

	widgetGroup[1]:RegisterWatchLua('ModifierKeyStatus', function(widget, trigger)
		visInfo.moreInfo		= trigger.moreInfoKey
		visInfo:Trigger(false)
	end)

	widgetGroup[1]:RegisterWatchLua('gamePanelInfo', function(widget, trigger)
		visInfo.heroInfoVis				= trigger.heroInfoVis
		visInfo.mapWidgetVis_heroInfos	= trigger.mapWidgetVis_heroInfos
		visInfo:Trigger(false)
	end, false, nil, 'heroInfoVis', 'mapWidgetVis_heroInfos')

	local widgetHeight = widgetGroup[1]:GetHeight()

	for k,v in ipairs(widgetGroup) do
		v:RegisterWatchLua('infoBodiesVisGroup'..triggerName, function(widget, groupTrigger)
			local triggerUnitInfo	= groupTrigger['infoBodiesVis_'..triggerName]
			local triggerUnits0		= groupTrigger['SelectedUnits0']
			local unitActive		= triggerUnitInfo.isActive
			if (
				triggerUnitInfo.exists and
				(
					(triggerUnitInfo.mapWidgetVis_heroInfos or (not unitActive)) and 
					(
						(not unitActive) or
						triggerUnitInfo.isDisconnected or
						triggerUnitInfo.isLoading or
						triggerUnitInfo.isTalking or
						triggerUnitInfo.isAFK or
						triggerUnitInfo.availablePoints or
						triggerUnitInfo.moreInfo or
						triggerUnitInfo.heroInfoVis or
						( triggerUnits0.isVisible and triggerUnits0.index == triggerUnitInfo.index) -- RMM Removed for pax
					)
				)
			) then
				widget:FadeIn(styles_uiSpaceShiftTime)
				widget:SlideY(0, styles_uiSpaceShiftTime)
			else
				widget:SlideY(((widgetHeight * -1) - libGeneral.HtoP(2)), styles_uiSpaceShiftTime)
				widget:FadeOut(styles_uiSpaceShiftTime)
			end
		end)
	end

	visInfo.exists						= false
	visInfo.isActive					= false
	visInfo.moreInfo					= false
	visInfo.isDisconnected				= false
	visInfo.isLoading					= false
	visInfo.index						= -1
	visInfo.isAFK						= false
	visInfo.isTalking					= false
	visInfo.availablePoints 			= false
	visInfo.heroInfoVis					= false
	visInfo.mapWidgetVis_heroInfos		= true
	
	visInfo:Trigger(true)
end

local function gamePlayerInfoVoipRegister(object, widgetName, triggerName)
	object:GetWidget(widgetName):RegisterWatchLua(triggerName, function(widget, trigger) widget:SetVisible(trigger.isTalking) end, false, nil, 'isTalking')
end

local function gamePlayerInfoMVPRegister(object, widgetName, paramName, isEnemy, isSelf)
	isEnemy = isEnemy or false
	local icon	= object:GetWidget(widgetName)

	icon:RegisterWatchLua('gamePanelInfo', function(widget, trigger)
		if (trigger[paramName]) then
			widget:FadeIn(1500)
		else
			widget:FadeOut(1500)
		end
	end, false, nil, paramName)

	icon:RegisterWatchLua('Team', function(widget, trigger)
		local sideRight = false
		-- if trigger.team == 1 then
			if isEnemy then
				sideRight = true
			end
		-- else
			-- if not isEnemy then
				-- sideRight = true
			-- end
		-- end

		if sideRight then
			widget:SetHFlip(true)
			widget:SetAlign('left')
			if (isSelf) then
				widget:SetX(libGeneral.HtoP(-1.25))
			else
				widget:SetX(libGeneral.HtoP(-1.25))
			end
		else
			widget:SetHFlip(false)
			widget:SetAlign('right')
			if (isSelf) then
				widget:SetX(libGeneral.HtoP(1.25))
			else
				widget:SetX(libGeneral.HtoP(1.25))
			end
		end
	end)
end

local function gamePlayerInfoDisconnectTimeRegister(object, widgetName, triggerName)
	object:GetWidget(widgetName):RegisterWatchLua(triggerName, function(widget, trigger)
		widget:SetText(libNumber.timeFormat(trigger.disconnectTime))
		widget:SetVisible(trigger.isDisconnected)
	end, false, nil, 'disconnectTime', 'isDisconnected')
end

local function gamePlayerInfoLoadPercentRegister(object, widgetName, triggerName)
	object:GetWidget(widgetName):RegisterWatchLua(triggerName, function(widget, trigger)
		widget:SetText(floor(trigger.loadingPercent * 100)..'%')
		widget:SetVisible(trigger.isLoading)
	end, false, nil, 'loadingPercent', 'isLoading')
end

local function gamePlayerInfoLoadIconRegister(object, widgetName, triggerName)
	object:GetWidget(widgetName):RegisterWatchLua(triggerName, function(widget, trigger)
		widget:SetVisible(trigger.isLoading)
	end, false, nil, 'isLoading')
end

local function gamePlayerInfoDisconnectIconRegister(object, widgetName, triggerName)
	object:GetWidget(widgetName):RegisterWatchLua(triggerName, function(widget, trigger)
		widget:SetVisible(trigger.isDisconnected)
	end, false, nil, 'isDisconnected')
end

local function gamePlayerInfoLevelRegister(object, widgetName, triggerName, isEnemy)
	isEnemy = isEnemy or false
	local label = object:GetWidget(widgetName)
	label:RegisterWatchLua(triggerName, function(widget, trigger)
		widget:SetText(trigger.level)
	end, false, nil, 'level')

	--[[
	label:RegisterWatchLua('Team', function(widget, trigger)

		-- local sideOther = false
		-- if trigger.team == 1 then
			if isEnemy then
				sideOther = true
			end
		-- else
			-- if not isEnemy then
				-- sideOther = true
			-- end
		-- end

		if sideOther then
			widget:SetAlign('right')
			widget:SetX(libGeneral.HtoP(4.5))
		else
			widget:SetAlign('right')
			widget:SetX(libGeneral.HtoP(-4.5))
		end
	end)
	--]]
end

local function gamePlayerInfoAFKRegister(object, widgetName, triggerName)
	object:GetWidget(widgetName):RegisterWatchLua(triggerName, function(widget, trigger)
		widget:SetVisible(trigger.isAFK)
	end, false, nil, 'isAFK')
end

local function gamePlayerInfoMuteIconRegister(object, widgetName, unitTrigger, slotIndex)
	local isEnemy = isEnemy or false
	local icon	= object:GetWidget(widgetName)
	
	local function isMuted(muted)
		if (muted) then
			icon:SetColor('red')
		else
			icon:SetColor('white')
		end
	end
	
	local ident = LuaTrigger.GetTrigger(unitTrigger).identID
	
	icon:RegisterWatchLua(unitTrigger, function(widget, trigger) -- track initial ident
		icon:UnregisterWatchLua(unitTrigger)
		ident = trigger.identID
	end, false, nil, 'identID')
	
	icon:RegisterWatchLua('mutePlayerInfo', function(widget, trigger)
		if (trigger.IdentID == ident) then
			isMuted(trigger.muted)
		end
	end)
	
	
	isMuted(ChatClient.IsIgnored(ident))
	icon:SetCallback('onclick', function(widget)
		local unitTrigger = LuaTrigger.GetTrigger(unitTrigger)
		UIMute(slotIndex, unitTrigger.identID, unitTrigger.clientNumber, unitTrigger.name, unitTrigger.uniqueID)
		
		local muteTrigger = LuaTrigger.GetTrigger('mutePlayerInfo')
		muteTrigger.IdentID = unitTrigger.identID
		muteTrigger.muted = ChatClient.IsIgnored(tostring(muteTrigger.IdentID))
		muteTrigger:Trigger()
		
	end)
	
	icon:RegisterWatchLua('ModifierKeyStatus', function(widget, trigger) 
		if (trigger.moreInfoKey) then		
			widget:FadeIn(200)
		else
			widget:FadeOut(50)
		end
	end)

	icon:RegisterWatchLua('Team', function(widget, trigger)
		local sideRight = false
		-- if trigger.team == 1 then
			if isEnemy then
				sideRight = true
			end
		-- else
			-- if not isEnemy then
				-- sideRight = true
			-- end
		-- end

		if sideRight then
			widget:SetAlign('right')
			widget:SetX(libGeneral.HtoP(1.60))
		else
			widget:SetAlign('left')
			widget:SetX(libGeneral.HtoP(-1.60))
		end
	end)

end

local function gamePlayerInfoDeadIconRegister(object, widgetName, triggerName, isEnemy)
	isEnemy = isEnemy or false
	local icon	= object:GetWidget(widgetName)

	icon:RegisterWatchLua(triggerName, function(widget, trigger)
		widget:SetVisible(not trigger.isActive)
	end, false, nil, 'isActive')

	icon:RegisterWatchLua('Team', function(widget, trigger)
		local sideRight = false
		-- if trigger.team == 1 then
			if isEnemy then
				sideRight = true
			end
		-- else
			-- if not isEnemy then
				-- sideRight = true
			-- end
		-- end

		if sideRight then
			widget:SetAlign('left')
			widget:SetX(libGeneral.HtoP(-1.60))
		else
			widget:SetAlign('right')
			widget:SetX(libGeneral.HtoP(1.60))
		end
	end)
end

local function gamePlayerInfoPingingIconRegister(object, widgetName, triggerName)
	local icon	= object:GetWidget(widgetName)
	
	local clientNumber = LuaTrigger.GetTrigger(triggerName).clientNumber
	local iconThread
	icon:RegisterWatchLua("PlayerPing", function(widget, trigger)
		if trigger.clientNumber == clientNumber then
			if (iconThread and iconThread:IsValid()) then
				iconThread:kill()
				iconThread = nil
			end
			iconThread = libThread.threadFunc(function()
				widget:FadeIn(50)
				wait(2000)
				widget:FadeOut(500)
				iconThread = nil
			end)
		end
	end, false, nil)
end

local function gamePlayerInfoRespawnRegister(object, widgetName, triggerName)
	object:GetWidget(widgetName):RegisterWatchLua(triggerName, function(widget, trigger)
		if (trigger.remainingRespawnTime > 0) then
			widget:SetVisible(not trigger.isActive)
			widget:SetText(math.ceil(trigger.remainingRespawnTime / 1000))
		else
			widget:SetVisible(false)
		end
	end, false, nil, 'isActive', 'remainingRespawnTime')
end

local function gamePlayerInfoIconRegister(object, widgetName, triggerName)
		object:GetWidget(widgetName):RegisterWatchLua(triggerName, function(widget, trigger)
		widget:SetTexture(trigger.iconPath)
		if trigger.isActive then
			widget:SetColor(1,1,1)
			widget:SetRenderMode('normal')
		else
			widget:SetColor(0.5,0.5,0.5)
			widget:SetRenderMode('grayscale')
		end
	end, false, nil, 'iconPath', 'isActive')
end

-- =====================

local function heroRegister(object)
	local vitalsContainers = object:GetGroup('gameHeroVitalsContainers')
	local vitalContainerHeight	= vitalsContainers[1]:GetHeight()
	-- local inventoryPrimaryBars	= object:GetGroup('gameInventoryPrimaryBars')

	gamePlayerInfoBodiesRegister(object, 'gameSelfInfoBodies', 'HeroUnit', true)

	registerCvarPinButton(object, 'gameBackpackPin', '_backpackVis', true, 'gamePanelInfo', 'backpackVis', nil, 'pin_items', 'pin_items_tip')
	registerCvarPinButton(object, 'gameHeroVitalsPin', '_heroVitalsVis', true, 'gamePanelInfo', 'heroVitalsVis', nil, 'pin_vitals', 'pin_vitals_tip')
	registerCvarPinButton(object, 'gamePushOrbPin', '_pushOrbVis', true, 'gamePanelInfo', 'clockExpandedPinned', nil, 'pin_clock', 'pin_clock_tip')
	registerCvarPinButton(object, 'gameBossPin', '_bossTimerVis', true, 'gamePanelInfo', 'boss1ExpandedPinned', nil, 'pin_clock', 'pin_clock_tip')
	registerCvarPinButton(object, 'gameHeroInfoPin', '_heroInfoVis', true, 'gamePanelInfo', 'heroInfoVis', 'mapWidgetVis_heroInfos', 'pin_heroportraits', 'pin_heroportraits_tip')
	
	if (Strife_Region.regionTable[Strife_Region.activeRegion]) and (Strife_Region.regionTable[Strife_Region.activeRegion].disabledFeatures ~= nil)  and (not (type(Strife_Region.regionTable[Strife_Region.activeRegion].disabledFeatures)=='table' and libGeneral.isInTable(Strife_Region.regionTable[Strife_Region.activeRegion].disabledFeatures, 'chat_wheel'))) then
		registerRadialChat(object)
		if not GetCvarBool('cg_ChatWheelEnabled') then
			SetSave('cg_ChatWheelEnabled', 'true', 'bool')
			SetSave('cg_chatWheelOpen', '100', 'int')
		end		
	end
	
	if (Strife_Region.regionTable[Strife_Region.activeRegion]) and (Strife_Region.regionTable[Strife_Region.activeRegion].disabledFeatures ~= nil)  and (not (type(Strife_Region.regionTable[Strife_Region.activeRegion].disabledFeatures)=='table' and libGeneral.isInTable(Strife_Region.regionTable[Strife_Region.activeRegion].disabledFeatures, 'command_wheel'))) then
		registerRadialCommand(object)	
		if not GetCvarBool('cg_CommandDial_Enabled') then
			SetSave('cg_CommandDial_Enabled', 'true', 'bool')
			SetSave('cg_commandDialOpen', '100', 'int')
		end	
	end
	
	--[[
	for k,v in ipairs(inventoryPrimaryBars) do
		v:RegisterWatchLua('gamePanelInfo', function(widget, trigger)
			local yPos = libGeneral.HtoP(-1)
			if trigger.heroVitalsVis or trigger.moreInfoKey then
				yPos = yPos - vitalContainerHeight - libGeneral.HtoP(1)
			end
			widget:SlideY(yPos, styles_uiSpaceShiftTime)
			widget:Sleep(styles_uiSpaceShiftTime, function(widget) widget:SetY(yPos) end)
		end, false, nil, 'heroVitalsVis', 'moreInfoKey')
	end	
	--]]

	for k,v in ipairs(vitalsContainers) do
		v:RegisterWatchLua('gamePanelInfo', function(widget, trigger)
			if (trigger.mapWidgetVis_tabbing) and (trigger.heroVitalsVis or trigger.moreInfoKey) then
				widget:FadeIn(styles_uiSpaceShiftTime)
				widget:SlideY(libGeneral.HtoP(-0.5), styles_uiSpaceShiftTime)
			else
				widget:FadeOut(styles_uiSpaceShiftTime)
				widget:SlideY((widget:GetHeight() + libGeneral.HtoP(0.5)), styles_uiSpaceShiftTime)
			end
		end, false, nil, 'heroVitalsVis', 'moreInfoKey', 'mapWidgetVis_tabbing')
	end


	vitalsContainers[1]:RegisterWatchLua('HeroUnit', function(widget, trigger)
		trigger_gameAllyGPMCompare['ally4GPM'] = trigger.gpm
		trigger_gameAllyGPMCompare:Trigger(false)
	end, false, nil, 'gpm')

	vitalsContainers[1]:RegisterWatchLua('PlayerScore', function(widget, trigger)
		if (trigger_gamePanelInfo.mapWidgetVis_kills) then
			trigger_gameAllyKillAssistsCompare['ally4KillAssists'] = (trigger.heroKills)
		else
			trigger_gameAllyKillAssistsCompare['ally4KillAssists'] = (trigger.heroKills + trigger.assists)
		end
		trigger_gameAllyKillAssistsCompare:Trigger(false)
	end, false, nil, 'heroKills', 'assists')

	gamePlayerInfoIconRegister(object, 'gameSelfIcon', 'HeroUnit')
	gamePlayerInfoRespawnRegister(object, 'gameSelfRespawnTime', 'HeroUnit')

	gamePlayerInfoMVPRegister(object, 'gameSelfMVPIcon', 'ally4MVP', false, true)
	gamePlayerInfoVoipRegister(object, 'gameSelfVoip', 'HeroUnit')

	-- gamePlayerInfoAFKRegister(object, 'gameSelfAFK', 'HeroUnit')
	gamePlayerInfoLevelRegister(object, 'gameSelfLevel', 'HeroUnit')

	gamePlayerInfoDeadIconRegister(object, 'gameSelfDeadIcon', 'HeroUnit', false)


	local killassists	= object:GetWidget('gameSelfKillAssists')
	local GPM			= object:GetWidget('gameSelfGPM')
	local GPMIcon		= object:GetWidget('gameSelfGPMIcon')
	local GPMIconUp1	= object:GetWidget('gameSelfGPMIconUp1')
	local GPMIconUp2	= object:GetWidget('gameSelfGPMIconUp2')
	local killsIcon		= object:GetWidget('gameSelfKillsIcon')
	local deathsIcon	= object:GetWidget('gameSelfDeathsIcon')
	local assistsIcon	= object:GetWidget('gameSelfAssistsIcon')
	
	killassists:RegisterWatchLua('PlayerScore', function(widget, trigger) 
		if (trigger_gamePanelInfo.mapWidgetVis_kills) then
			widget:SetText(trigger.heroKills) 
		else
			widget:SetText(trigger.heroKills + trigger.assists)
		end
	end, false, nil, 'heroKills', 'assists')
	GPM:RegisterWatchLua('HeroUnit', function(widget, trigger)
		widget:SetText(trigger.gpm)
	end, false, nil, 'gpm')

	GPMIcon:RegisterWatchLua('gameAllyGPMCompare', function(widget, trigger)
		local infoTable = {}
		for i=0,4,1 do
			table.insert(infoTable, { index = i, gpm = trigger['ally'..i..'GPM'] })
		end

		table.sort(infoTable, function(a,b) return a.gpm > b.gpm end)
		
		local selfGPMRanking = 5
		for i,v in ipairs(infoTable) do
			if (v.index == 4) then
				selfGPMRanking = i
			end
		end

		if (selfGPMRanking == 1) then
			GPMIconUp1:SetVisible(1)
			GPMIconUp2:SetVisible(1)
			widget:GetWidget('game_hero_unitframe_tooltip_highgpm'):SetVisible(1)
			widget:GetWidget('game_hero_unitframe_tooltip_highgpm_label'):SetText(Translate('game_veryhigh_gpm'))
		elseif (selfGPMRanking == 2) then
			GPMIconUp1:SetVisible(1)
			GPMIconUp2:SetVisible(0)
			widget:GetWidget('game_hero_unitframe_tooltip_highgpm'):SetVisible(1)
			widget:GetWidget('game_hero_unitframe_tooltip_highgpm_label'):SetText(Translate('game_high_gpm'))
		else
			GPMIconUp1:SetVisible(0)
			GPMIconUp2:SetVisible(0)
			widget:GetWidget('game_hero_unitframe_tooltip_highgpm'):SetVisible(0)
		end
	end)

	-- RMM add hero name, player name, inventory

	killassists:RegisterWatchLua('Team', function(widget, trigger)
		local align		= 'left'
		local xPos		= '39@'
		local iconXPos	= '1.0h'
		local iconXPos2	= '-10@'
		local iconXPos3	= '-10@'
		-- if trigger.team == 2 then
			-- align		= 'right'
			-- xPos		= '-32@'
			-- iconXPos	= '-5s'
			-- iconXPos2	= '-10@'
			-- iconXPos3	= '-10@'
		-- end

		killassists:SetX(xPos)
		-- deaths:SetX(xPos)
		-- assists:SetX(xPos)
		GPM:SetX(xPos)
		killassists:SetAlign(align)
		-- deaths:SetAlign(align)
		-- assists:SetAlign(align)
		GPM:SetAlign(align)

		killassists:SetTextAlign(align)
		-- deaths:SetTextAlign(align)
		-- assists:SetTextAlign(align)
		GPM:SetTextAlign(align)

		killsIcon:SetX(iconXPos)
		-- deathsIcon:SetX(iconXPos)
		-- assistsIcon:SetX(iconXPos)
		GPMIcon:SetX(iconXPos)
		GPMIconUp1:SetX(iconXPos2)
		GPMIconUp2:SetX(iconXPos3)

		killsIcon:SetAlign(align)
		-- deathsIcon:SetAlign(align)
		-- assistsIcon:SetAlign(align)
		GPMIcon:SetAlign(align)
		GPMIconUp1:SetAlign(align)
		GPMIconUp2:SetAlign(align)
	end)

	local function ShowHeroTooltip(sourceWidget, relation, index, showInventory)

		local unitTrigger = LuaTrigger.GetTrigger(relation..'Unit'..index)
		local PlayerScore = LuaTrigger.GetTrigger('PlayerScore')
		local height, width = 10, 22

		sourceWidget:GetWidget('game_hero_unitframe_tooltip'):SetVisible(1)
		
		local text = ''
		if (unitTrigger) and (unitTrigger.clanTag) and (not Empty(unitTrigger.clanTag)) then
			text = (('[' .. (unitTrigger.clanTag or '') ..']') .. (unitTrigger.playerName or ''))
		elseif (unitTrigger) then
			text = (trigger.playerName or '')
		end			
		
		if (relation == 'Hero') then
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_icon'):SetTexture(unitTrigger.iconPath)
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_player_label'):SetText(text)
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_hero_label'):SetText(GetEntityDisplayName(unitTrigger.heroEntity))		
		else
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_icon'):SetTexture(unitTrigger.iconPath)
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_player_label'):SetText(text)
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_hero_label'):SetText(unitTrigger.name)
		end
		
		local function GetIcon(key)
			if (LuaTrigger.GetTrigger(relation .. key .. index).iconPath) and (not Empty(LuaTrigger.GetTrigger(relation .. key .. index).iconPath)) and (LuaTrigger.GetTrigger(relation .. key .. index).isValid) then
				return LuaTrigger.GetTrigger(relation .. key .. index).iconPath
			else
				return '/ui/shared/textures/pack2.tga'
			end
		end

		if ((relation == 'Ally') or (relation == 'Enemy')) and (trigger_gamePanelInfo[string.lower(relation)..index..'MVP']) then
			height = height + 3.0
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_mvp'):SetVisible(1)

			if (relation == 'Ally') then
				-- width = width + 4.5 -- not showing ka
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_mvp_label'):UnregisterWatchLuaByKey('tooltip_mvp_label')
				if (trigger_gamePanelInfo.mapWidgetVis_kills) then
					sourceWidget:GetWidget('game_hero_unitframe_tooltip_mvp_label'):SetText(Translate('game_mvp_enemy', 'value', (unitTrigger.kills)))
					sourceWidget:GetWidget('game_hero_unitframe_tooltip_mvp_label'):RegisterWatchLua(relation..'Unit'..index, function(widget2, trigger2)
						widget2:SetText(Translate('game_mvp', 'value', (trigger2.kills)))
					end, false, 'tooltip_mvp_label', 'kills', 'assists')
				else
					sourceWidget:GetWidget('game_hero_unitframe_tooltip_mvp_label'):SetText(Translate('game_mvp_enemy', 'value', (unitTrigger.kills + unitTrigger.assists)))
					sourceWidget:GetWidget('game_hero_unitframe_tooltip_mvp_label'):RegisterWatchLua(relation..'Unit'..index, function(widget2, trigger2)
						widget2:SetText(Translate('game_mvp', 'value', (trigger2.kills + trigger2.assists)))
					end, false, 'tooltip_mvp_label', 'kills', 'assists')
				end
			else
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_mvp_label'):SetText(Translate('game_mvp_enemy'))
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_mvp_label'):UnregisterWatchLuaByKey('tooltip_mvp_label')
			end
		elseif ((relation == 'Hero')) and (trigger_gamePanelInfo['ally4MVP']) then
			height = height + 3.0
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_mvp'):SetVisible(1)

			sourceWidget:GetWidget('game_hero_unitframe_tooltip_mvp_label'):UnregisterWatchLuaByKey('tooltip_mvp_label')
			if (trigger_gamePanelInfo.mapWidgetVis_kills) then
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_mvp_label'):SetText(Translate('game_mvp_enemy', 'value', (PlayerScore.heroKills)))
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_mvp_label'):RegisterWatchLua('PlayerScore', function(widget2, trigger2)
					widget2:SetText(Translate('game_mvp', 'value', (trigger2.heroKills)))
				end, false, 'tooltip_mvp_label', 'heroKills', 'assists')
			else
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_mvp_label'):SetText(Translate('game_mvp_enemy', 'value', (PlayerScore.heroKills + PlayerScore.assists)))
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_mvp_label'):RegisterWatchLua('PlayerScore', function(widget2, trigger2)
					widget2:SetText(Translate('game_mvp', 'value', (trigger2.heroKills + trigger2.assists)))
				end, false, 'tooltip_mvp_label', 'heroKills', 'assists')
			end
		else
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_mvp'):SetVisible(0)
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_mvp_label'):UnregisterWatchLuaByKey('tooltip_mvp_label')
		end

		sourceWidget:GetWidget('game_hero_unitframe_tooltip_kills_label'):UnregisterWatchLuaByKey('tooltip_kills_label')
		if (relation == 'Hero') then
			if (trigger_gamePanelInfo.mapWidgetVis_kills) then
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_kills_label'):SetText(PlayerScore.heroKills)
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_kills_label'):RegisterWatchLua('PlayerScore', function(widget2, trigger2)
					widget2:SetText(trigger2.heroKills)
				end, false, 'tooltip_kills_label', 'heroKills', 'assists')
			else
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_kills_label'):SetText(PlayerScore.heroKills + PlayerScore.assists)
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_kills_label'):RegisterWatchLua('PlayerScore', function(widget2, trigger2)
					widget2:SetText(trigger2.heroKills + trigger2.assists)
				end, false, 'tooltip_kills_label', 'heroKills', 'assists')
			end
		else
			if (trigger_gamePanelInfo.mapWidgetVis_kills) then
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_kills_label'):SetText(unitTrigger.kills)
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_kills_label'):RegisterWatchLua(relation..'Unit'..index, function(widget2, trigger2)
					widget2:SetText(trigger2.kills)
				end, false, 'tooltip_kills_label', 'kills', 'assists')
			else
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_kills_label'):SetText(unitTrigger.kills + unitTrigger.assists)
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_kills_label'):RegisterWatchLua(relation..'Unit'..index, function(widget2, trigger2)
					widget2:SetText(trigger2.kills + trigger2.assists)
				end, false, 'tooltip_kills_label', 'kills', 'assists')
			end
		end
		
		sourceWidget:GetWidget('game_hero_unitframe_tooltip_deaths_label'):UnregisterWatchLuaByKey('tooltip_deaths_label')
		if (relation == 'Hero') then
			height = height + 2.2
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_deaths'):SetVisible(1)
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_deaths_label'):SetText(PlayerScore.deaths)
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_deaths_label'):RegisterWatchLua('PlayerScore', function(widget2, trigger2)
				widget2:SetText(trigger2.deaths)
			end, false, 'tooltip_deaths_label', 'deaths')
		else
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_deaths'):SetVisible(0)
		end		
		
		sourceWidget:GetWidget('game_hero_unitframe_tooltip_gpm_label'):UnregisterWatchLuaByKey('tooltip_gpm_label')
		if (relation == 'Hero') then
			height = height + 2.2
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_gpm'):SetVisible(1)
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_gpm_label'):SetText(unitTrigger.gpm)
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_gpm_label'):RegisterWatchLua(relation..'Unit'..index, function(widget2, trigger2)
				widget2:SetText(trigger2.gpm)
			end, false, 'tooltip_gpm_label', 'gpm')
		else
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_gpm'):SetVisible(0)
		end			
		
		if (relation == 'Hero') then
			if sourceWidget:GetWidget('game_hero_unitframe_tooltip_highgpm'):IsVisibleSelf() then
				height = height + 2.7
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_highgpm_parent'):SetVisible(1)
			else
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_highgpm_parent'):SetVisible(0)
			end
		else
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_highgpm_parent'):SetVisible(0)
		end
		
		local gameSelfPower	= object:GetWidget('gameSelfPower')
		local gameSelfDPS	= object:GetWidget('gameSelfDPS')
		local gameSelfAS	= object:GetWidget('gameSelfAS')
		local game_hero_unitframe_tooltip_attackdamage_label	= object:GetWidget('game_hero_unitframe_tooltip_attackdamage_label')
		local gameSelfMitigation	= object:GetWidget('gameSelfMitigation')
		local gameSelfResistance	= object:GetWidget('gameSelfResistance')
		local gameSelfMoveSpeed	= object:GetWidget('gameSelfMoveSpeed')

		
		gameSelfPower:SetText(math.ceil(unitTrigger.power))
		gameSelfPower:UnregisterWatchLuaByKey('tooltip_power_label')
		gameSelfPower:RegisterWatchLua(relation..'Unit'..index, function(widget2, trigger2)
			widget2:SetText(math.ceil(trigger2.power))
		end, false, 'tooltip_power_label', 'power')		
		
		game_hero_unitframe_tooltip_attackdamage_label:SetText(math.ceil(unitTrigger.damage))
		game_hero_unitframe_tooltip_attackdamage_label:UnregisterWatchLuaByKey('tooltip_damage_label')
		game_hero_unitframe_tooltip_attackdamage_label:RegisterWatchLua(relation..'Unit'..index, function(widget2, trigger2)
			widget2:SetText(math.ceil(trigger2.damage))
		end, false, 'tooltip_damage_label', 'damage')		
		
		gameSelfDPS:SetText(math.ceil(unitTrigger.dps))
		gameSelfDPS:UnregisterWatchLuaByKey('tooltip_dps_label')
		gameSelfDPS:RegisterWatchLua(relation..'Unit'..index, function(widget2, trigger2)
			widget2:SetText(math.ceil(trigger2.dps))
		end, false, 'tooltip_dps_label', 'dps')	
		
		gameSelfAS:SetText(math.ceil(unitTrigger.attackSpeed)..'%')
		gameSelfAS:UnregisterWatchLuaByKey('tooltip_as_label')
		gameSelfAS:RegisterWatchLua(relation..'Unit'..index, function(widget2, trigger2)
			widget2:SetText(math.ceil(trigger2.attackSpeed)..'%')
		end, false, 'tooltip_as_label', 'attackSpeed')
		
		gameSelfMitigation:SetText(math.ceil(unitTrigger.mitigation))
		gameSelfMitigation:UnregisterWatchLuaByKey('tooltip_a_label')
		gameSelfMitigation:RegisterWatchLua(relation..'Unit'..index, function(widget2, trigger2)
			widget2:SetText(math.ceil(trigger2.mitigation))
		end, false, 'tooltip_a_label', 'mitigation')	
		
		gameSelfResistance:SetText(math.ceil(unitTrigger.resistance))
		gameSelfResistance:UnregisterWatchLuaByKey('tooltip_ma_label')
		gameSelfResistance:RegisterWatchLua(relation..'Unit'..index, function(widget2, trigger2)
			widget2:SetText(math.ceil(trigger2.resistance))
		end, false, 'tooltip_ma_label', 'resistance')	

		gameSelfMoveSpeed:SetText(math.ceil(unitTrigger.moveSpeed))
		gameSelfMoveSpeed:UnregisterWatchLuaByKey('tooltip_ms_label')
		gameSelfMoveSpeed:RegisterWatchLua(relation..'Unit'..index, function(widget2, trigger2)
			widget2:SetText(math.ceil(trigger2.moveSpeed))
		end, false, 'tooltip_ms_label', 'moveSpeed')					

		if (showInventory) then
			height = height + 10.9
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_inventory_parent'):SetVisible(1)
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_inventory_0'):SetTexture(GetIcon('Item0Info'))
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_inventory_1'):SetTexture(GetIcon('Item1Info'))
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_inventory_2'):SetTexture(GetIcon('Item2Info'))
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_inventory_3'):SetTexture(GetIcon('Item3Info'))
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_inventory_4'):SetTexture(GetIcon('Item4Info'))
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_inventory_5'):SetTexture(GetIcon('Item5Info'))
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_inventory_6'):SetTexture(GetIcon('Item6Info'))
		else
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_inventory_parent'):SetVisible(0)
		end

		sourceWidget:GetWidget('game_hero_unitframe_tooltip'):SetHeight(libGeneral.HtoP(height))
		sourceWidget:GetWidget('game_hero_unitframe_tooltip'):SetWidth(libGeneral.HtoP(width))

	end

	local function HideHeroTooltip(sourceWidget)
		sourceWidget:GetWidget('game_hero_unitframe_tooltip'):SetVisible(0)
	end

	local primaryContainer
	primaryContainer = object:GetGroup('gameSelfInfoContainers')[1]
	primaryContainer:SetCallback('onmouseover', function()
		if trigger_gamePanelInfo.mapWidgetVis_heroInfos then
			ShowHeroTooltip(object, 'Hero', '', false)
		end
	end)
	primaryContainer:SetCallback('onmouseout', function()
		HideHeroTooltip(object)
	end)
	
	primaryContainer:SetCallback('onclick', function(widget)
		SelectUnit(LuaTrigger.GetTrigger('ActiveUnit').index)
	end)
	
	primaryContainer:RegisterWatchLua('ModifierKeyStatus', function(widget, trigger) widget:SetNoClick(not trigger.moreInfoKey) end)	
	
	for i=0,3,1 do
		primaryContainer = object:GetGroup('gameAlly'..i..'Containers')[1]
		primaryContainer:SetCallback('onmouseover', function()
			ShowHeroTooltip(object, 'Ally', i, true)
		end)
		primaryContainer:SetCallback('onmouseout', function()
			HideHeroTooltip(object)
		end)
		
		primaryContainer:SetCallback('onclick', function(widget)
			SelectUnit(LuaTrigger.GetTrigger('AllyUnit'..i).index)
		end)
		
		primaryContainer:RegisterWatchLua('ModifierKeyStatus', function(widget, trigger) widget:SetNoClick(not trigger.moreInfoKey) end)
	end

	for i=0,4,1 do
		primaryContainer = object:GetGroup('gameEnemy'..i..'Containers')[1]
		primaryContainer:SetCallback('onmouseover', function()
			ShowHeroTooltip(object, 'Enemy', i, true)
		end)
		primaryContainer:SetCallback('onmouseout', function()
			HideHeroTooltip(object)
		end)
		
		primaryContainer:SetCallback('onclick', function(widget)
			print('would attempt to select enemy '..i..' here\n')
			SelectUnit(LuaTrigger.GetTrigger('EnemyUnit'..i).index)
		end)
		primaryContainer:RegisterWatchLua('ModifierKeyStatus', function(widget, trigger) widget:SetNoClick(not trigger.moreInfoKey) end)
	end

	-- self vitals

	object:GetWidget('gameHeroHealthGain'):RegisterWatchLua('HeroUnit', function(widget, trigger)
		widget:SetText('+'..libNumber.round(trigger.healthRegen, 1))
	end, false, nil, 'healthRegen')

	object:GetWidget('gameHeroManaGain'):RegisterWatchLua('HeroUnit', function(widget, trigger)
		widget:SetText('+'..libNumber.round(trigger.manaRegen, 1))
	end, false, nil, 'manaRegen')

	object:GetWidget('gameHeroHealthBar'):RegisterWatchLua('HeroUnit', function(widget, trigger)
		widget:SetWidthP(trigger.healthPercent * 100)
	end, false, nil, 'healthPercent')

	object:GetWidget('gameHeroManaBar'):RegisterWatchLua('HeroUnit', function(widget, trigger)
		widget:SetWidthP(trigger.manaPercent * 100)
	end, false, nil, 'manaPercent')

	object:GetWidget('gameHeroHealthCur'):RegisterWatchLua('HeroUnit', function(widget, trigger)
		widget:SetText(libNumber.commaFormat(floor(trigger.health)))
	end, false, nil, 'health')

	object:GetWidget('gameHeroManaCur'):RegisterWatchLua('HeroUnit', function(widget, trigger)
		widget:SetText(libNumber.commaFormat(floor(trigger.mana)))
	end, false, nil, 'mana')

	object:GetWidget('gameHeroHealthMax'):RegisterWatchLua('HeroUnit', function(widget, trigger)
		widget:SetText(libNumber.commaFormat(trigger.healthMax))
	end, false, nil, 'healthMax')

	object:GetWidget('gameHeroManaMax'):RegisterWatchLua('HeroUnit', function(widget, trigger)
		widget:SetText(libNumber.commaFormat(trigger.manaMax))
	end, false, nil, 'manaMax')

	local heroGoldContainer 		= object:GetWidget('gameHeroGoldContainer')

	object:GetWidget('gameHeroGold'):RegisterWatchLua('HeroUnit', function(widget, trigger)
		widget:SetText(libNumber.commaFormat(trigger.gold))
	end, false, nil, 'gold')
	
	heroGoldContainer:SetCallback('onclick', function(widget)
		widget:UICmd("ToggleShop()")
	end)

end

heroRegister(object)

local function gameAllyRegister(object, index)
	local containers	= object:GetGroup('gameAlly'..index..'Containers')
	local infoOverlay	= object:GetWidget('gameAlly'..index..'InfoOverlay')

	gamePlayerInfoBodiesRegister(object, 'gameAlly'..index..'InfoBodies', 'AllyUnit'..index)
	
	if (infoOverlay) then
		infoOverlay:RegisterWatchLua('infoBodiesVisGroupAllyUnit'..index, function(widget, groupTrigger)
			local selectedInfo		= groupTrigger['SelectedUnits0']
			local selectedVisible	= selectedInfo.isVisible
			local isSelected = false
			
			if selectedVisible then
				local triggerHero		= groupTrigger['infoBodiesVis_AllyUnit'..index]
				local selectedIndex		= selectedInfo.index
				
				if selectedIndex == triggerHero.index then
					isSelected = true
				end
			end
			
			if isSelected then
				widget:SetTexture('/ui/game/unit_frames/textures/unit_frame_cover_selected.tga')
			else
				widget:SetTexture('/ui/game/unit_frames/textures/unit_frame_cover.tga')
			end
		end)
	end
	
	for k,v in ipairs(containers) do
		v:RegisterWatchLua('AllyUnit'..index, function(widget, trigger)
			widget:SetVisible(trigger.exists)
			if k == 1 then
				trigger_gameAllyGPMCompare['ally'..index..'GPM'] = trigger.gpm
				trigger_gameAllyGPMCompare:Trigger(false)
				trigger_gameAllyKillAssistsCompare['ally'..index..'KillAssists'] = (trigger.kills + trigger.assists)
				trigger_gameAllyKillAssistsCompare:Trigger(false)
			end
		end, true, nil, 'exists', 'gpm', 'kills', 'assists', 'identID')
	end

	containers[1]:RegisterWatchLua('AllyUnit'..index, function(widget, trigger)
		if ChatClient.IsIgnored(trigger.identID) then
			if (VoiceClient) then
				VoiceClient.SetMuted(trigger.identID, true)
			end
		end
	end, true, nil, 'identID')
	
	gamePlayerInfoAFKRegister(object, 'gameAlly'..index..'AFK', 'AllyUnit'..index)
	gamePlayerInfoLevelRegister(object, 'gameAlly'..index..'Level', 'AllyUnit'..index)

	gamePlayerInfoDisconnectTimeRegister(object, 'gameAlly'..index..'DisconnectTime', 'AllyUnit'..index)
	gamePlayerInfoLoadPercentRegister(object, 'gameAlly'..index..'LoadPercent', 'AllyUnit'..index)

	gamePlayerInfoDisconnectIconRegister(object, 'gameAlly'..index..'DisconnectIcon', 'AllyUnit'..index)
	gamePlayerInfoLoadIconRegister(object, 'gameAlly'..index..'LoadIcon', 'AllyUnit'..index)

	gamePlayerInfoVoipRegister(object, 'gameAlly'..index..'Voip', 'AllyUnit'..index)

	gamePlayerInfoMVPRegister(object, 'gameAlly'..index..'MVPIcon', 'ally'..index..'MVP', false, false)
	gamePlayerInfoDeadIconRegister(object, 'gameAlly'..index..'DeadIcon', 'AllyUnit'..index, false)
	gamePlayerInfoPingingIconRegister(object, 'gameAlly'..index..'PingingIcon', 'AllyUnit'..index)
	gamePlayerInfoMuteIconRegister(object, 'gameAlly'..index..'MuteIcon', 'AllyUnit'..index, index)

	gamePlayerInfoIconRegister(object, 'gameAlly'..index..'Icon', 'AllyUnit'..index)
	gamePlayerInfoRespawnRegister(object, 'gameAlly'..index..'RespawnTime', 'AllyUnit'..index)

	return containers
end

local function gameEnemyRegister(object, index)
	local containers	= object:GetGroup('gameEnemy'..index..'Containers')
	local infoOverlay	= object:GetWidget('gameEnemy'..index..'InfoOverlay')

	gamePlayerInfoBodiesRegister(object, 'gameEnemy'..index..'InfoBodies', 'EnemyUnit'..index)
	
	if (infoOverlay) then
		infoOverlay:RegisterWatchLua('infoBodiesVisGroupEnemyUnit'..index, function(widget, groupTrigger)
			local selectedInfo		= groupTrigger['SelectedUnits0']
			local selectedVisible	= selectedInfo.isVisible
			local isSelected = false
			
			if selectedVisible then
				local triggerHero		= groupTrigger['infoBodiesVis_EnemyUnit'..index]
				local selectedIndex		= selectedInfo.index
				
				if selectedIndex == triggerHero.index then
					isSelected = true
				end
			end
			
			if isSelected then
				widget:SetTexture('/ui/game/unit_frames/textures/unit_frame_cover_selected.tga')
			else
				widget:SetTexture('/ui/game/unit_frames/textures/unit_frame_cover.tga')
			end
		end)
	end
	
	for k,v in ipairs(containers) do
		v:RegisterWatchLua('EnemyUnit'..index, function(widget, trigger)
			widget:SetVisible(trigger.exists)
			if k == 1 then
				trigger_gameEnemyGPMCompare['enemy'..index..'GPM'] = trigger.gpm
				trigger_gameEnemyGPMCompare:Trigger(false)
				trigger_gameEnemyKillAssistsCompare['enemy'..index..'KillAssists'] = (trigger.kills + trigger.assists)
				trigger_gameEnemyKillAssistsCompare:Trigger(false)
			end
		end, false, nil, 'exists', 'gpm', 'kills', 'assists')
	end

	gamePlayerInfoAFKRegister(object, 'gameEnemy'..index..'AFK', 'EnemyUnit'..index)
	gamePlayerInfoLevelRegister(object, 'gameEnemy'..index..'Level', 'EnemyUnit'..index)

	gamePlayerInfoDisconnectTimeRegister(object, 'gameEnemy'..index..'DisconnectTime', 'EnemyUnit'..index)
	gamePlayerInfoLoadPercentRegister(object, 'gameEnemy'..index..'LoadPercent', 'EnemyUnit'..index, true)

	gamePlayerInfoDisconnectIconRegister(object, 'gameEnemy'..index..'DisconnectIcon', 'EnemyUnit'..index)
	gamePlayerInfoLoadIconRegister(object, 'gameEnemy'..index..'LoadIcon', 'EnemyUnit'..index)

	gamePlayerInfoMVPRegister(object, 'gameEnemy'..index..'MVPIcon', 'enemy'..index..'MVP', true, false)
	gamePlayerInfoDeadIconRegister(object, 'gameEnemy'..index..'DeadIcon', 'EnemyUnit'..index, true)

	gamePlayerInfoIconRegister(object, 'gameEnemy'..index..'Icon', 'EnemyUnit'..index)
	gamePlayerInfoRespawnRegister(object, 'gameEnemy'..index..'RespawnTime', 'EnemyUnit'..index)

	return containers
end

local function gameRegister(object)
	local playerInfoBarsEnemy			= object:GetGroup('playerInfoBarsEnemy')
	local playerInfoBarsAlly			= object:GetGroup('playerInfoBarsAlly')
	local playerInfoContainersEnemy		= {}
	local playerInfoContainersAlly		= {}
	local playerInfoSpacing				= libGeneral.HtoP(1)

	local playerInfoSelfOverlay			= object:GetWidget('gameSelfInfoOverlay')
	local playerInfoSelfIconSpaces		= object:GetGroup('gameSelfInfoIconSpaces')

	local history	 				= object:GetWidget('game_chat_box_popup')
	local specHistory				= object:GetWidget('game_spectator_chat_box_popup')
	
	local minimapContainers		= object:GetGroup('gameMinimapContainers')
	
	for k,v in ipairs(minimapContainers) do
		v:RegisterWatchLua('gamePanelInfo', function(widget, trigger)
			widget:SetVisible(trigger.mapWidgetVis_minimap)
		end, false, nil, 'mapWidgetVis_minimap')
	end

	object:GetWidget('gameMenuButton'):SetCallback('onclick', function()
		object:GetWidget('game_menu_parent'):SetVisible(not object:GetWidget('game_menu_parent'):IsVisible() )
	end)	
	object:GetWidget('gameMenuButtonKey'):RegisterWatchLua('ModifierKeyStatus', function(widget, trigger) widget:SetVisible(trigger.moreInfoKey) end)

	object:GetWidget('gameMenuPing'):SetCallback('onclick', function()
		if GetLocalHeroLocation then
			local worldPos = GetLocalHeroLocation()
			--local startX = tonumber(string.sub(trigger.mousePos, 0, string.find(trigger.mousePos, " ")))
			--local startY = tonumber(string.sub(trigger.mousePos,    string.find(trigger.mousePos, " ")+1))
			if (worldPos) then
				openRadialCommand(1, 0, 0, worldPos, 1)
			end
		end
	end)
	
	history:SetCallback( 'onshow', function(widget) Trigger('chatHistoryVisible', 'true') end )
	history:SetCallback( 'onhide', function(widget) Trigger('chatHistoryVisible', 'false') end )
	specHistory:SetCallback( 'onshow', function(widget) Trigger('chatHistoryVisible', 'true') end )
	specHistory:SetCallback( 'onhide', function(widget) Trigger('chatHistoryVisible', 'false') end )

	-- =====================================
	
	
	local function hideEndgameInventoryWidgets(startIndex, endIndex, suffix)
		local widgetGroup
		if startIndex and endIndex and suffix then
		
			for i=startIndex, endIndex, 1 do
		
				widgetGroup = object:GetGroup('gameInventory'..i..suffix)

				if widgetGroup then
					for _, v in ipairs(widgetGroup) do
						v:SetVisible(false)
					end
				end
			end
		end

	end
	
	object:GetWidget('game_gamephase_watcher'):RegisterWatchLua('GamePhase', function(widget, trigger)
		if (trigger.gamePhase == 7) then

		
			-- Primaries
			hideEndgameInventoryWidgets(0,3,'Containers')
			hideEndgameInventoryWidgets(0,3,'TimerContainers')
		
			
			-- hideEndgameInventoryWidgets(0,150,'Containers')
			--[[
			hideEndgameInventoryWidgets(0,3,'TimerContainers')		-- Primaries
			hideEndgameInventoryWidgets(32,63,'Containers')			-- States
			hideEndgameInventoryWidgets(96,104,'Containers')		-- Items			
			--]]
		
			--[[
			for index = 0,150,1 do
				widgetGroup = object:GetGroup('gameInventory' .. index .. 'Containers')
				if widgetGroup then
					for _, v in ipairs(widgetGroup) do
						v:SetVisible(0)
					end
				end
			end
			
			for index = 0,3,1 do
				widgetGroup = object:GetGroup('gameInventory'..index..'TimerContainers')
				if widgetgroup then
					for _, v in ipairs(widgetGroup) do
						v:SetVisible(0)
					end
				end
			end
			--]]
			
			local widgetGroup = object:GetGroup('gameInventoryPetContainers')
			if (widgetGroup) then
				for _, v in pairs(widgetGroup) do
					v:SetVisible(0)
				end
			end	
			
			local widgetGroup = object:GetGroup('gameHeroVitalsContainers')
			if (widgetGroup) then
				for _, v in pairs(widgetGroup) do
					v:SetVisible(0)
				end
			end
			
			if (mainUI) and (mainUI.Analytics) then
				mainUI.Analytics.AddFeatureFinishInstance()
			end			
			
		end
	end)
	
	-- =====================================

	local pausedIndicator			= object:GetWidget('gamePausedIndicator')
	pausedIndicator:RegisterWatchLua('GameIsPaused', function(widget, trigger)
		local tutorialPauseTrigger = LuaTrigger.GetTrigger("TutorialPause")
		if ((not tutorialPauseTrigger) or (not tutorialPauseTrigger.hidePaused)) then
			widget:SetVisible(trigger.paused)
		end
	end)

	local waitingForPlayersIndicator	= object:GetWidget('waitingForPlayersIndicator')
	if (waitingForPlayersIndicator) then
		waitingForPlayersIndicator:RegisterWatchLua('GameInfo', function(widget, trigger) widget:SetVisible(trigger.waitingForPlayers) end)	
	end
	
	local afkPausedIndicator			= object:GetWidget('afkPausedIndicator')
	afkPausedIndicator:RegisterWatchLua('ClientAFK', function(widget, trigger) 
		if (LuaTrigger.GetTrigger('LobbyStatus').isHost) then
			Cmd('ServerPause')
			widget:SetVisible(1)
		end
	end)	
	
	-- ======================================

	playerInfoSelfOverlay:RegisterWatchLua('infoBodiesVisGroupHeroUnit', function(widget, groupTrigger)
		local selectedInfo		= groupTrigger['SelectedUnits0']
		local selectedVisible	= selectedInfo.isVisible
		local isSelected = false
		
		if selectedVisible then
			local triggerHero		= groupTrigger['infoBodiesVis_HeroUnit']
			local selectedIndex		= selectedInfo.index
			
			if selectedIndex == triggerHero.index then
				isSelected = true
			end
		end
		
		if isSelected then
			widget:SetTexture('/ui/game/unit_frames/textures/unit_frame_cover_me_selected.tga')
		else
			widget:SetTexture('/ui/game/unit_frames/textures/unit_frame_cover_me.tga')
		end
	end)
	
	--[[
	playerInfoSelfOverlay:RegisterWatchLua('Team', function(widget, trigger)
		-- if trigger.team == 2 then
			-- widget:SetHFlip(true)
		-- else
			widget:SetHFlip(false)
		-- end
	end)
	--]]

	-- This is a case for SetFloat (left/right) if I've ever seen one... PM#2026

	for i=0,3,1 do
		playerInfoContainersAlly[i] = gameAllyRegister(object, i)
	end

	for k,v in ipairs(playerInfoSelfIconSpaces) do
		v:RegisterWatchLua('Team', function(widget, trigger)
			-- if trigger.team == 2 then
				-- widget:SetAlign('left')
				-- widget:SetX('8@')
			-- else
				widget:SetAlign('right')
				widget:SetX('-8@')
			-- end
		end)
	end

	local playerInfoContainersSelf = object:GetGroup('gameSelfInfoContainers')

	LuaTrigger.CreateGroupTrigger('allyUnitFramePosInfo', {
		'ActiveUnit.index',
		'AllyUnit0.exists',
		'AllyUnit0.index',
		'AllyUnit1.exists',
		'AllyUnit1.index',
		'AllyUnit2.exists',
		'AllyUnit2.index',
		'AllyUnit3.exists',
		'AllyUnit3.index',
		'SelectedUnit.isHero',
		'SelectedUnit.playerSlot',
		'SelectedUnits0.index',
		'Team.team',
		'ModifierKeyStatus.moreInfoKey'
	})
	
	LuaTrigger.CreateGroupTrigger('enemyUnitFramePosInfo', {
		'EnemyUnit0.exists',
		'EnemyUnit0.index',
		'EnemyUnit1.exists',
		'EnemyUnit1.index',
		'EnemyUnit2.exists',
		'EnemyUnit2.index',
		'EnemyUnit3.exists',
		'EnemyUnit3.index',
		'EnemyUnit4.exists',
		'EnemyUnit4.index',
		'SelectedUnit.isHero',
		'SelectedUnit.playerSlot',
		'SelectedUnits0.index',
		'Team.team'
	})
	
	local function unitFramePos(startX, containers, isSelf, isRightSide, isSelected, withSelectedSelf, withSelectedTeammate, isLast, moreInfoKey)
		isRightSide				= isRightSide or false
		isSelf					= isSelf or false
		isSelected				= isSelected or false
		withSelectedSelf		= withSelectedSelf or false
		withSelectedTeammate	= withSelectedTeammate or false
		startX					= startX or 0
		isLast					= isLast or false
		moreInfoKey				= moreInfoKey or false
		local itemPadding 		= libGeneral.HtoP(1.75)

		if containers and type(containers) == 'table' then
			local baseWidth		= containers[1]:GetWidth()
			local widthBefore	= 0
			local widthAfter	= 0
			
			if isSelected then
				if isSelf then
					if moreInfoKey then
						if isRightSide then
							widthBefore = libGeneral.HtoP(1.25)
							widthAfter = libGeneral.HtoP(1.25)
						else
							widthBefore = libGeneral.HtoP(1.25)
							widthAfter = libGeneral.HtoP(1.25)
						end
					end
				else
					if isRightSide then
						widthBefore = libGeneral.HtoP(11.5)
					else
						widthAfter = libGeneral.HtoP(11.5)
					end
				end
			end
			
			
			
			if withSelectedSelf then
				if moreInfoKey then
					itemPadding = libGeneral.HtoP(1.25)
				end
			elseif withSelectedTeammate then
				itemPadding = libGeneral.HtoP(0.5)
			end
			
			startX = startX + widthBefore
			
			for k,v in ipairs(containers) do
				v:SetX(startX)
			end
			
			-- print('startX for widget is '..startX..'\n')
			
			if (not isLast) then
				startX = startX + itemPadding
			end
			
			return startX + baseWidth + widthAfter
		end
		return 0
	end
	
	local function unitFrameBarPos(selfTeam, barIsAllies, unitInfo, frameBars, moreInfoKey)
		local totalWidth	= 0
		local isRightSide = false
		moreInfoKey = moreInfoKey or false
		-- if selfTeam == 1 then
			isRightSide = (not barIsAllies)
		-- else
			-- isRightSide = (barIsAllies)
		-- end
		
		local posSideMult = -1	-- Left of center (is team 1)
		
		if isRightSide then
			posSideMult = 1	-- Right of center (is team 2)
		end
		
		for i=1,#unitInfo,1 do
			totalWidth = unitFramePos(
				totalWidth,
				unitInfo[i].containers,
				unitInfo[i].isSelf,
				isRightSide,
				unitInfo[i].isSelected,
				unitInfo[i].selectedSelf,
				unitInfo[i].selectedTeammate,
				(i == #unitInfo),
				moreInfoKey
			)
		end
		
		for k,v in ipairs(frameBars) do
			v:SetWidth(totalWidth)
			v:SetX(((totalWidth / 2) + libGeneral.HtoP(10)) * posSideMult)
		end
		
	end
	
	playerInfoContainersSelf[1]:RegisterWatchLua('allyUnitFramePosInfo', function(widget, groupTrigger)
		local unitInfo			= {}
		local selfTeam			= groupTrigger['Team'].team
		local selectedSelf		= false
		local selectedTeammate	= false
		local selectedIndex		= groupTrigger['SelectedUnits0'].index
		local SelectedUnit		= groupTrigger['SelectedUnit']
		local moreInfoKey		= groupTrigger['ModifierKeyStatus'].moreInfoKey
		local selectedValid		= (SelectedUnit.isHero and SelectedUnit.playerSlot >= 0)
		local selectedMember	= -1
		if selectedValid then
			if selectedIndex == groupTrigger['ActiveUnit'].index then
				selectedSelf = true
			else
				for i=0,3,1 do
					if not selectedTeammate and groupTrigger['AllyUnit'..i].exists and selectedIndex == groupTrigger['AllyUnit'..i].index then
						selectedTeammate	= true
						selectedMember		= i
					end
				end
			end
		end
	
		for i=0,3,1 do
			if groupTrigger['AllyUnit'..i].exists then
				table.insert(unitInfo, {
					containers			= playerInfoContainersAlly[i],
					isSelf				= false,
					selectedSelf		= selectedSelf,
					selectedTeammate	= selectedTeammate,
					isSelected			= (selectedMember == i)
				})
			end
		end
		
		
		local selfInfo		= {
			containers			= playerInfoContainersSelf,
			isSelf				= true,
			selectedSelf		= selectedSelf,
			selectedTeammate	= selectedTeammate,
			isSelected			= selectedSelf
		}
		
		-- if selfTeam == 2 then
			-- table.insert(unitInfo, selfInfo)
		-- else
			table.insert(unitInfo, 1, selfInfo)
		-- end
	
		unitFrameBarPos(
			selfTeam,
			true,
			unitInfo,
			playerInfoBarsAlly,
			moreInfoKey
		)

	end)

	playerInfoBarsEnemy[1]:RegisterWatchLua('enemyUnitFramePosInfo', function(widget, groupTrigger)
		local unitInfo			= {}
		local selfTeam			= groupTrigger['Team'].team
		local selectedSelf		= false
		local selectedTeammate	= false
		local selectedIndex		= groupTrigger['SelectedUnits0'].index
		local SelectedUnit		= groupTrigger['SelectedUnit']
		local selectedValid		= (SelectedUnit.isHero and SelectedUnit.playerSlot >= 0)
		local selectedMember	= -1
		
		if selectedValid then
			for i=0,4,1 do
				if not selectedTeammate and groupTrigger['EnemyUnit'..i].exists and selectedIndex == groupTrigger['EnemyUnit'..i].index then
					selectedTeammate	= true
					selectedMember		= i
				end
			end
		end

		for i=0,4,1 do
			if groupTrigger['EnemyUnit'..i].exists then
				table.insert(unitInfo, {
					containers			= playerInfoContainersEnemy[i],
					isSelf				= false,
					selectedSelf		= selectedSelf,
					selectedTeammate	= selectedTeammate,
					isSelected			= (selectedMember == i)
				})
			end
		end
		
		unitFrameBarPos(
			selfTeam,
			false,
			unitInfo,
			playerInfoBarsEnemy
		)
	end)
	
	gameUI.lastAllyMVPUpdate = 0
	playerInfoBarsEnemy[1]:RegisterWatchLua('gameAllyGPMCompare', function(widget, trigger)
		
		local hostTime = GetTrigger('System').hostTime
		
		if ((hostTime - gameUI.lastAllyMVPUpdate) > 60000) then
		
			local infoTable = {}
			for i=0,4,1 do
				table.insert(infoTable, { index = i, gpm = trigger['ally'..i..'GPM'] })
			end

			table.sort(infoTable, function(a,b) return a.gpm > b.gpm end)
			
			local MVPID = infoTable[1].index
			
			
			for i=0,4,1 do
				trigger_gamePanelInfo['ally'..i..'MVP'] = (i == MVPID)
			end
			trigger_gamePanelInfo:Trigger(false)			
			
			gameUI.lastAllyMVPUpdate = hostTime
		end
		
	end)
	
	gameUI.lastEnemyMVPUpdate = 0
	playerInfoBarsEnemy[1]:RegisterWatchLua('gameEnemyGPMCompare', function(widget, trigger)
		
		local hostTime = GetTrigger('System').hostTime
		
		if ((hostTime - gameUI.lastEnemyMVPUpdate) > 60000) then
		
			local infoTable = {}
			for i=0,4,1 do
				table.insert(infoTable, { index = i, gpm = trigger['enemy'..i..'GPM'] })
			end

			table.sort(infoTable, function(a,b) return a.gpm > b.gpm end)

			local MVPID = infoTable[1].index

			for i=0,4,1 do
				trigger_gamePanelInfo['enemy'..i..'MVP'] = (i == MVPID)
			end
			trigger_gamePanelInfo:Trigger(false)
			
			gameUI.lastEnemyMVPUpdate = hostTime
		end
	end)

	for i=0,4,1 do
		playerInfoContainersEnemy[i] = gameEnemyRegister(object, i)
	end
		
	-- RMM Game Connection State Dimmer
	-- GetWidget('game_no_connection_overlay'):RegisterWatchLua('mainPanelStatus', function(widget, trigger)
		-- if (trigger.chatConnectionState <= 0) and (trigger.hasIdent) and (trigger.isLoggedIn) and (not GetCvarBool('ui_dont_require_chat_server')) then
			-- widget:Sleep(500, function()
				-- widget:FadeIn(500)
				-- GetWidget('game_no_connection_overlay_dimmer'):FadeIn(3000)
				-- GetWidget('game_no_connection_overlay_label'):FadeIn(3000)
			-- end)
		-- else
			-- widget:Sleep(1, function() end)
			-- widget:FadeOut(125)		
			-- GetWidget('game_no_connection_overlay_dimmer'):FadeOut(125)
			-- GetWidget('game_no_connection_overlay_label'):FadeOut(125)
		-- end
	-- end, false, nil, 'chatConnectionState', 'hasIdent', 'isLoggedIn')	
	
	FindChildrenClickCallbacks(object)

	object:GetWidget('effect_panel'):RegisterWatchLua('gamePanelInfo', function(widget, trigger)
		widget:SetVisible(trigger.mapWidgetVis_minimap)
	end, false, nil, 'mapWidgetVis_minimap')
	
	function getPlayerUnitFrame(playerType, index)
		if playerType == 'hero' then
			return object:GetWidget('gameInfoSelfContainer')
		elseif playerType == 'ally' then
			return object:GetWidget('gameAlly'..index..'Container')
		elseif playerType == 'enemy' then
			return object:GetWidget('gameEnemy'..index..'Container')
		end

		return false
	end
	
	updateElementsPosition()
end

local function InitializeTwitchTV(object)
	if (Twitch) and (Twitch.SetOverlayInterface) then
		Twitch.SetOverlayInterface('/ui/shared/twitch/twitch.interface')
	end
end
InitializeTwitchTV(object)

object:GetWidget('gameCompass'):RegisterWatchLua('CompassPointer', function(widget, trigger)
	local unitX			= trigger.targetScreenPosLocationX
	local unitY			= trigger.targetScreenPosLocationY
	local compassPad	= libGeneral.HtoP(30)

	widget:SetVisible(
		trigger.isEnabled and (
			(unitX < (0 + compassPad) or unitX > (GetScreenWidth() - compassPad)) or
			(unitY < (0 + compassPad) or unitY > (GetScreenHeight() - compassPad))
		)
	)
	widget:SetX(trigger.compassPositionX)
	widget:SetY(trigger.compassPositionY)
end, false, nil, 'isEnabled', 'compassPositionX', 'compassPositionY', 'targetScreenPosLocationX', 'targetScreenPosLocationY')

object:GetWidget('gameCompassArrow'):RegisterWatchLua('CompassPointer', function(widget, trigger) widget:SetRotation(trigger.degreesFromOrigin * -1) end, false, nil, 'degreesFromOrigin')

gameRegister(object)
--[[
function UIMute(slotIndex, identID, clientNumber, name, uniqueID)
	
	println('^y UIMute slotIndex: ' .. tostring(slotIndex) .. ' | identID: ' .. tostring(identID)  .. ' | clientNumber: ' .. tostring(clientNumber)  .. ' | name: ' .. tostring(name))
	local identID = tostring(identID)
	
	local thisGuyWasMuted = ChatClient.IsIgnored(identID)
	
	if (not thisGuyWasMuted) and ((not identID) or (not IsValidIdent(identID)) or IsMe(identID)) then
		println('^r You cannot mute this identID')
		return
	end	
	
	-- RMM Add These
	-- Mute Chat Wheel
	-- Mute Command Dial
	-- Mute Game Chat
	-- Mute IMs
	-- Mute Channel Chat
		
	mainUI = mainUI or {}
	mainUI.savedLocally.downVoteList = mainUI.savedLocally.downVoteList or {}	
	
	local heroIndex = GetTrigger('AllyUnit'..tostring(slotIndex))
	if heroIndex then 
		heroIndex = heroIndex.index 
	end
	
	if (thisGuyWasMuted) then
		ChatClient.RemoveIgnore(identID)
		mainUI.savedLocally.downVoteList[identID] = false
		VoiceClient.SetMuted(identID, false)
		if clientNumber then UnMutePlayerPings(clientNumber) end
		if (heroIndex) then UnMuteHeroAnnouncements(heroIndex) end
	else
		ChatClient.AddIgnore(identID)
		mainUI.savedLocally.downVoteList[identID] = true
		VoiceClient.SetMuted(identID, true)	
		if clientNumber then MutePlayerPings(clientNumber) end
		if (heroIndex) then MuteHeroAnnouncements(heroIndex) end
	end
end]]
if LuaTrigger.GetTrigger('MapEffect') then
	object:GetWidget("effect_panel"):RegisterWatchLua('MapEffect', function(widget, trigger)
		local x, y = widget:GetMinimapDraw('gameMinimap', trigger.x, 1.0 - trigger.y)
		x = x / GetScreenWidth()
		y = y / GetScreenHeight()
		widget:StartEffect(trigger.effectPath, x, y, trigger.effectColor)
	end, false, nil)
end
