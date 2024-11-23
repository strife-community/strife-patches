-- new_game_common.lua (12/2014)
-- common functions for the new_game files

--																	--
--	gamehelper table of functions to make things a little cleaner	--
--																	--

--				--
-- core defines	--
--				--
local interface = object
local floor = math.floor
local ceil	= math.ceil
local max	= math.max
local min	= math.min

gameUI = gameUI or {}
gameUI.playerWasDead = false

mainUI = mainUI or {}
mainUI.savedLocally 	= mainUI.savedLocally 	or {}
mainUI.savedRemotely 	= mainUI.savedRemotely 	or {}
mainUI.minimapFlipped 	= false

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

-- 			
gameHelper = { }
gameHelper = 
{ 
	--
	-- register 'widget' to watch 'triggerParam' of 'trigger'
	-- set widget's text to the value of the trigger
	-- will use default if the trigger param doesn't exist or is empty when default isn't nil
	-- will use call func(trigger[triggerParam]) if func isn't nil
	registerWatchText = function(widget, trigger, triggerParam, default, func)
		widget:RegisterWatchLua(trigger, function(w, t)
			if t[triggerParam] == nil or t[triggerParam] == "" then
				if default ~= nil then
					w:SetText(default)
				end
			else
				if func ~= nil then
					local text = func(t[triggerParam])
					w:SetText(text)
				else
					w:SetText(t[triggerParam])
				end
			end
		end, true, nil, triggerParam)
		if (incTrigger) then
			if incTrigger[triggerParam] == nil or incTrigger[triggerParam] == "" then
				if default ~= nil then
					widget:SetVisible(default)
				end
			else
				if func ~= nil then
					local text = func(incTrigger[triggerParam])
					widget:SetText(text)
				else
					widget:SetText(incTrigger[triggerParam])
				end
			end
		end			
	end,

		--
	-- register 'widget' to watch 'triggerParam' of 'trigger'
	-- set widget's text to the value of the trigger, and floor it with comma formatting
	-- will use default if the trigger param doesn't exist or is empty when default isn't nil
	-- will use call func(trigger[triggerParam]) if func isn't nil
	registerWatchTextFloor = function(widget, trigger, triggerParam, default)
		gameHelper.registerWatchText(widget, trigger, triggerParam, default, function(val) return libNumber.commaFormat(floor(val)) end)
	end,

	--
	-- register 'widget' to watch 'triggerParam' of 'trigger'
	-- set widget visible if the value of trigger[triggerParam] is true
	-- will use default if the trigger param doesn't exist or is empty when default isn't nil
	-- will use call func(trigger[triggerParam]) if func isn't nil
	registerWatchVisible = function(widget, trigger, triggerParam, default, func)
		widget:RegisterWatchLua(trigger, function(w, t)
			if t[triggerParam] == nil or t[triggerParam] == "" then
				if default ~= nil then
					w:SetVisible(default)
				end
			else
				if func ~= nil then
					w:SetVisible(func(t[triggerParam]))
				else
					w:SetVisible(t[triggerParam] ~= nil and t[triggerParam] ~= false)
				end
			end
		end, true, nil, triggerParam)
		local incTrigger = LuaTrigger.GetTrigger(trigger)
		if (incTrigger) then
			if incTrigger[triggerParam] == nil or incTrigger[triggerParam] == "" then
				if default ~= nil then
					widget:SetVisible(default)
				end
			else
				if func ~= nil then
					widget:SetVisible(func(incTrigger[triggerParam]))
				else
					widget:SetVisible(incTrigger[triggerParam] ~= nil and incTrigger[triggerParam] ~= false)
				end
			end
		end		
	end,

	--
	-- register 'widget' to watch 'triggerParam' of 'trigger'
	-- set widget's texture to the value of the trigger
	-- will use default if the trigger param doesn't exist or is empty when default isn't nil
	-- will use call func(trigger[triggerParam]) if func isn't nil
	registerWatchTexture = function(widget, trigger, triggerParam, default, func)
		widget:RegisterWatchLua(trigger, function(w, t)
			if t[triggerParam] == nil or t[triggerParam] == "" then
				if default ~= nil then
					w:SetTexture(default)
				end
			else
				if func ~= nil then
					local texture = func(t[triggerParam])
					w:SetTexture(texture)
				else
					w:SetTexture(t[triggerParam])
				end
			end
		end, true, nil, triggerParam)
		local incTrigger = LuaTrigger.GetTrigger(trigger)
		if (incTrigger) then
			if incTrigger[triggerParam] == nil or incTrigger[triggerParam] == "" then
				if default ~= nil then
					widget:SetTexture(default)
				end
			else
				if func ~= nil then
					local texture = func(incTrigger[triggerParam])
					widget:SetTexture(texture)
				else
					widget:SetTexture(incTrigger[triggerParam])
				end
			end
		end
	end,

	--
	-- register a button from the "minibutton" template
	registerMiniButton = function(widgetPrefix, trigger, triggerParam, onClick)

		local keyStates = 
		{
			widgetPrefix .. "_iconUp",
			widgetPrefix .. "_iconDown",
			widgetPrefix .. "_iconOver"
		}

		for k,widgetName in ipairs(keyStates) do
			local widget = object:GetWidget(widgetName)
			gameHelper.registerWatchTexture(widget, trigger, triggerParam)
		end

		if onClick ~= nil then
			object:GetWidget(widgetPrefix):SetCallback('onclick', onClick)
		end

	end,

	--
	-- register a keybind button from the "key" template
	registerBindKey = function(widgetPrefix, trigger, bindCommand, bindIndex, hideOnNoBind, isItem, startsHidden)
		local hotkeyFontList = {
			'maindyn_14',
			'maindyn_13',
			'maindyn_12',
			'maindyn_11',
			'maindyn_10'
		}

		local hotkeyFontListEnd = hotkeyFontList[#hotkeyFontList]

		local hotkey 		= gameGetWidget(widgetPrefix)
		local button 		= gameGetWidget(widgetPrefix .. 'Button')
		local tip 			= gameGetWidget(widgetPrefix .. 'ButtonTip')
		local backer		= gameGetWidget(widgetPrefix .. 'Backer')
		local disabled		= gameGetWidget(widgetPrefix .. 'Disabled')
	
		if hotkey == nil then
			print (widgetPrefix .. 'HotkeyButton is nil\n')
			return
		end

		local bindingParamName = 'binding1'
		if isItem then
			bindingParamName = 'activatableBinding1'
		end
		
		local function HotKeyUpdate(widget, trigger)
			local binding1			= trigger[bindingParamName]
			local quickBinding1		= trigger.quickBinding1
			local bindingText		= ''
		
			if binding1 and string.len(binding1) > 0 then
				bindingText = binding1
			elseif quickBinding1 and string.len(quickBinding1) > 0 then
				bindingText = quickBinding1
			end
	
			if (string.len(bindingText) == 0 and hideOnNoBind) or startsHidden then
				hotkey:SetVisible(false)
				return
			end

			hotkey:SetVisible(true)

			local w 			= gameGetWidget(widgetPrefix .. 'Label')
			local newFont
			
			if (w) and (w:IsValid()) then
				newFont 		= FitFontToLabel(w, bindingText, hotkeyFontList, false)
			end
			
			local fullLabel		= bindingText

			if not newFont or newFont == hotkeyFontListEnd then
				for i=math.max(1,(string.len(fullLabel) - 3)), 1, -1 do
					bindingText = string.sub(fullLabel, 1, i)..'.'
					
					if (w) and (w:IsValid()) then
						newFont = FitFontToLabel(w, bindingText, hotkeyFontList, false)
					else
						newFont = 'maindyn_10'
					end
					
					if newFont and newFont ~= hotkeyFontListEnd then
						break
					end
				end
			end

			w:SetFont(newFont)
			w:SetText(bindingText)
			
			disabled:SetVisible(not trigger.isActivatable)		
		end
		
		hotkey:RegisterWatchLua(trigger, function(widget, trigger)			
			HotKeyUpdate(widget, trigger)
		end, false, nil, bindingParamName, 'quickBinding1', 'isActivatable')
		
		HotKeyUpdate(hotkey, LuaTrigger.GetTrigger(trigger))
		
		backer:RegisterWatchLua('ModifierKeyStatus', function(widget, trigger)			
			if trigger.moreInfoKey then
				widget:SetColor(styles_colors_hotkeyCanSet)
				widget:SetBorderColor(styles_colors_hotkeyCanSet)
			else
				widget:SetColor('1 1 1 1')
				widget:SetBorderColor('1 1 1 1')		
			end
		end)
		if LuaTrigger.GetTrigger('ModifierKeyStatus').moreInfoKey then
			backer:SetColor(styles_colors_hotkeyCanSet)
			backer:SetBorderColor(styles_colors_hotkeyCanSet)
		else
			backer:SetColor('1 1 1 1')
			backer:SetBorderColor('1 1 1 1')		
		end		
		
		button:RegisterWatchLua('ModifierKeyStatus', function(widget, trigger)
			widget:SetNoClick(not trigger.moreInfoKey)
		end, false)
		button:SetNoClick(1)
		
		button:SetCallback('onclick', function(widget)
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
			
		button:SetCallback('onmouseover', function(widget)
			simpleTipNoFloatUpdate(true, nil, Translate('game_keybind_1'), Translate('game_keybind_2', 'value', GetKeybindButton('game', 'TriggerToggle', 'gameShowMoreInfo', 0)), nil, nil, libGeneral.HtoP(-18), 'center', 'bottom')
			UpdateCursor(widget, true, { canLeftClick = true})
		end)
		
		button:SetCallback('onmouseout', function(widget)
			simpleTipNoFloatUpdate(false)
			UpdateCursor(widget, false, { canLeftClick = true})
		end)
			
		tip:SetCallback('onmouseover', function(widget)
			simpleTipNoFloatUpdate(true, nil, Translate('game_keybind_1'), Translate('game_keybind_2', 'value', GetKeybindButton('game', 'TriggerToggle', 'gameShowMoreInfo', 0)), nil, nil, libGeneral.HtoP(-18), 'center', 'bottom')
			UpdateCursor(widget, true, { canLeftClick = true})
		end)
		
		tip:SetCallback('onmouseout', function(widget)
			simpleTipNoFloatUpdate(false)
			UpdateCursor(widget, false, { canLeftClick = true})
		end)
	end
}

-- Stuff for pausing
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

-- Chat History
local history	 				= object:GetWidget('game_chat_box_popup')
local specHistory				= object:GetWidget('game_spectator_chat_box_popup')
history:SetCallback( 'onshow', function(widget) Trigger('chatHistoryVisible', 'true') end )
history:SetCallback( 'onhide', function(widget) Trigger('chatHistoryVisible', 'false') end )
specHistory:SetCallback( 'onshow', function(widget) Trigger('chatHistoryVisible', 'true') end )
specHistory:SetCallback( 'onhide', function(widget) Trigger('chatHistoryVisible', 'false') end )
