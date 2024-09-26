-- new_game_allyEnemyTimers.lua
-- functionality for the ally / enemy / boss timers
local bounceBaldirAnimationThread = nil
local bounceCindaraAnimationThread = nil

local function bounceTimer (widget, animationType)
	if (animationType) then
		animationType:kill()
		animationType = nil
	end
	
	animationType = libThread.threadFunc(function()
			widget:ScaleWidth('4h', 200)
		widget:ScaleHeight('4h', 200)
		
		wait(200)
			widget:ScaleWidth('3.5h', 200)
			widget:ScaleHeight('3.5h', 200)

		animationType = nil
	end)
end

local eventAnimationThread = {}
local function AnimateEvent (widget, isActive, endY)
	if (eventAnimationThread[widget]) then
		eventAnimationThread[widget]:kill()
		eventAnimationThread[widget] = nil
	end
	
	eventAnimationThread[widget] = libThread.threadFunc(function()
		if isActive then
			widget:SetY('-10h')
			widget:SetVisible(0)
			
			wait(50)
			widget:SlideY(endY, 300)
			widget:FadeIn(200)
		else			
			widget:SlideY('-10h', 200)
			widget:FadeOut(150)
		end

		eventAnimationThread[widget] = nil
	end)
end

local function getTimeSinceStart()
	local timeTrigger = LuaTrigger.GetTrigger('MatchTime')
	local gameTime = timeTrigger.matchTime
	if (timeTrigger.isPreMatchPhase) then
		gameTime = -gameTime
	end
	return gameTime
end

-- register the boss and game timer icons
function registerGameTimers()
	local matchTimer 			= object:GetWidget('gameTimer')
	local baldirTimer 			= object:GetWidget('gameCooldownSquareBaldirAnimation')
	local cindaraTimer		 	= object:GetWidget('gameCooldownSquareCindaraAnimation')
	
	local baldirTimerPrefix 	= 'gameCooldownSquareBaldir'
	local cindaraTimerPrefix 	= 'gameCooldownSquareCindara'
	
	local pregameDuration = 60000
	local bossSpawnTime = 60000
	local timeBeforeInitialBossSpawn = pregameDuration + bossSpawnTime

	object:GetWidget('gameTimer'):RegisterWatchLua('MatchTime', function(widget, trigger) 
		if (trigger.matchTime >= 0) and (trigger.matchTime <= 4000000000) then
			widget:SetText(libNumber.timeFormat(trigger.matchTime))
		else
			widget:SetText('')
		end
	end)
	
	local function registerBoss(bossPrefix, trigger)
		local bossPanel 			= object:GetWidget(bossPrefix)
		local bossCooldownLabel 	= object:GetWidget(bossPrefix .. '_cooldownText')
		local bossCooldownPie 		= object:GetWidget(bossPrefix .. '_cooldown')
		local bossCooldownIcon 		= object:GetWidget(bossPrefix .. '_icon')

		-- countdown timer / panel / icon
		bossCooldownLabel:RegisterWatchLua(trigger, function(widget, trigger)
			if trigger.status == 1 then
				bossCooldownIcon:SetRenderMode('normal')
				bossCooldownIcon:SetColor(1, 1, 1, 1)
				widget:SetText(Translate('game_boss_ready'))
				widget:SetVisible(0)
				
				if bossPrefix == cindaraTimerPrefix then
					bounceTimer(cindaraTimer, bounceCindaraAnimationThread)
				else
					bounceTimer(baldirTimer, bounceBaldirAnimationThread)
				end
			else
				bossCooldownIcon:SetRenderMode('grayscale')
				bossCooldownIcon:SetColor(0.7, 0.7, 0.7, 1)
				
				if trigger.respawnCountDown > 0 then				
					widget:SetText(libNumber.timeFormat(trigger.respawnCountDown))
					widget:SetVisible(true)
				else
					widget:SetVisible(false)
				end
			end
		end, true, nil, 'status', 'respawnCountDown')
		
		-- tips
		bossPanel:RegisterWatchLua(trigger, function(widget, trigger)
			widget:SetCallback('onmouseover', function(widget)				
				if bossPrefix == cindaraTimerPrefix then
					simpleTipGrowYUpdate(true, '/npcs/cindara/icon.tga', Translate('tutorial3_hint7'), Translate('tutorial3_tip11_body'), libGeneral.HtoP(32))
				else
					simpleTipGrowYUpdate(true, '/npcs/Baldir_2/icon.tga', Translate('tutorial3_hint4'), Translate('tutorial3_tip10_body'), libGeneral.HtoP(32))
				end
			end)
		end)
		
		bossPanel:SetCallback('onmouseout', function(widget)
			simpleTipGrowYUpdate(false)
		end)

		-- pie chart thingie
		bossCooldownPie:RegisterWatchLua(trigger, function(widget, trigger)
			local respawnCountDown = trigger.respawnCountDown
			local respawnDuration = trigger.respawnDuration

			widget:SetVisible(1 - trigger.status)
			if respawnCountDown > 0 then
				widget:SetVisible(true)
				widget:SetValue((respawnCountDown / respawnDuration))
			else
				widget:SetVisible(false)
			end
		end, true, nil, 'respawnCountDown', 'respawnDuration', 'status')
		
		-- before boss spawn
		bossCooldownPie:RegisterWatchLua('MatchTime', function(widget, trigger)
			local nTime = getTimeSinceStart()
			if (nTime > timeBeforeInitialBossSpawn) then
				bossCooldownPie:UnregisterWatchLua('MatchTime')
				widget:SetVisible(false)
				bossCooldownLabel:SetVisible(false)
				return
			end
			widget:SetVisible((bossSpawnTime-nTime) > 0)
			bossCooldownLabel:SetVisible((bossSpawnTime-nTime) > 0)
			bossCooldownLabel:SetText(libNumber.timeFormat(bossSpawnTime-nTime))
			widget:SetValue(1-((pregameDuration+nTime) / (timeBeforeInitialBossSpawn)))
		end)
	end

	registerBoss(cindaraTimerPrefix, 'SpawnerInfo0')	-- Cindara
	registerBoss(baldirTimerPrefix, 'SpawnerInfo1')		-- Baldir
end


-- register the ally and enemy event icons in the top area
function registerAllyEnemyEvents()
	local function registerHeroEvent(widgetPrefix, trigger, isSelf, isAlly)
		local panel 		= object:GetWidget(widgetPrefix)
		local animation 	= object:GetWidget(widgetPrefix .. '_animation')
		local icon 			= object:GetWidget(widgetPrefix .. '_icon')
		local statusIcon 	= object:GetWidget(widgetPrefix .. '_disconnect')
		local cooldown 		= object:GetWidget(widgetPrefix .. '_cooldownText')
		local voip 			= object:GetWidget(widgetPrefix .. '_void')
		
		local endY = 0 --animation:GetY()
		
		if not isSelf then
			-- entire panel visibility
			panel:RegisterWatchLua(trigger, function(widget, trigger)
				local showPanel = (not trigger.isActive) or (trigger.isDisconnected) or (trigger.isLoading)
				local isExisting = trigger.exists
				
				if isExisting or (trigger.isLoading) then
					AnimateEvent(animation, showPanel, endY)
				else
					AnimateEvent(animation, false, endY)
				end
			end, false, nil, 'exists', 'isActive', 'isDisconnected', 'isLoading')
		else
			-- entire panel visibility
			panel:RegisterWatchLua(trigger, function(widget, trigger)
				local showPanel = (not trigger.isActive)
				local isExisting = trigger.exists
				
				if isExisting then
					AnimateEvent(animation, showPanel, endY)
				else
					AnimateEvent(animation, false, endY)
				end
			end, false, nil, 'exists', 'isActive')
		end
		
		-- icon
		icon:RegisterWatchLua(trigger, function(widget, trigger)
			widget:SetTexture(trigger.iconPath)
			if (not trigger.isActive) or trigger.remainingRespawnTime > 0 then
				icon:SetRenderMode('grayscale')
				icon:SetColor(0.5,0.5,0.5)
			else
				icon:SetRenderMode('normal')
				icon:SetColor(1,1,1)
			end
		end, true, nil, 'iconPath', 'isActive', 'remainingRespawnTime')

		if isAlly or isSelf then
			voip:RegisterWatchLua(trigger, function(widget, trigger)
				voip:SetVisible(trigger.isTalking)
			end, true, 'isTalking')
		end

		if not isSelf then
			-- loading / disconnect icon
			statusIcon:RegisterWatchLua(trigger, function(widget, trigger)
				if trigger.isLoading then
					widget:SetVisible(true)
					widget:SetTexture('/ui/elements:icon_loading')
				elseif trigger.isDisconnected then
					widget:SetVisible(true)
					widget:SetTexture('/ui/elements:disconnect')
				else
					widget:SetVisible(false)
				end
			end, true, nil, 'isLoading', 'isDisconnected')

			-- any text 
			cooldown:RegisterWatchLua(trigger, function (widget, trigger)
				if trigger.isDisconnected and trigger.disconnectTime > 0 then
					widget:SetVisible(true)
					widget:SetText(libNumber.timeFormat(trigger.disconnectTime)..'s')
				elseif trigger.isLoading and trigger.loadingPercent > 0 then
					widget:SetVisible(true)
					widget:SetText(math.floor(trigger.loadingPercent * 100)..'%')
				elseif trigger.remainingRespawnTime > 0 then
					widget:SetVisible(true)
					widget:SetText(math.ceil(trigger.remainingRespawnTime / 1000)..'s')
				else
					widget:SetVisible(false)
				end
			end, true, nil, 'loadingPercent', 'remainingRespawnTime', 'disconnectTime', 'isDisconnected', 'isLoading')
		else
			statusIcon:SetVisible(false)
			cooldown:RegisterWatchLua(trigger, function (widget, trigger)
				if trigger.remainingRespawnTime > 0 then
					widget:SetVisible(true)
					widget:SetText(math.ceil(trigger.remainingRespawnTime / 1000)..'s')
				else
					widget:SetVisible(false)
				end
			end, true, nil, 'remainingRespawnTime')
		end
	end
	
	registerHeroEvent('gameAllyEvent1', 'HeroUnit', true)
	for i=1,5 do
		if i ~= 5 then registerHeroEvent('gameAllyEvent' .. i + 1, 'AllyUnit' .. (i - 1), false, true) end
		registerHeroEvent('gameEnemyEvent' .. i, 'EnemyUnit' .. (i - 1))
	end
end
