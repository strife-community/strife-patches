-- new_game_common.lua (12/2014)
-- common functions for the new_game files

--																	--
--	gamehelper table of functions to make things a little cleaner	--
--																	--

--				--
-- core defines	--
--				--
local interface = object
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
