local interface = object
-- new_game_playerhero.lua (12/2014)
-- the center area with health / mana / exp / abilities

-- register the center area interface stuff. 

-- Animate XP Bar level up
local xpAnimationThread = nil

local function animateXPContainer(widget)	
	local endWidth	= widget:GetWidth()
	local endHeight = widget:GetHeight()
	local change 	= 20
	
	if (xpAnimationThread) then
		xpAnimationThread:kill()
		xpAnimationThread = nil
	end
	
	xpAnimationThread = libThread.threadFunc(function()
			widget:Scale(endWidth + change, endHeight + change, 150)
	
		wait(150) -- delay for bounce
			widget:Scale(endWidth, endHeight, 150)

		xpAnimationThread = nil
	end)
end

-- Animate XP Bar Gain
local xpGainAnimationThread = nil

local function animateXPGain(bar, gained, gained_edge, hasLeveled, newXP, lastEXP, animationSpeed, fullBarTime, XPAnimation)	
	if (xpGainAnimationThread) then
		xpGainAnimationThread:kill()
		xpGainAnimationThread = nil
	end
	
	xpGainAnimationThread = libThread.threadFunc(function()
		if hasLeveled then
			--gained:ScaleWidth('100%', 10)
			--gained:FadeIn(10)
			--gained_edge:FadeIn(10)
		
			--wait(10) -- delay for XP increase
				bar:ScaleWidth('100%', animationSpeed)
				
			wait(animationSpeed + 100) -- delay for level increase
				--gained:SetWidth('0%')
				bar:SetWidth('0%')
				
			wait(10) -- delay to make sure the new width is set before animating				
				animateXPContainer(XPAnimation)
		end
		
		--gained:ScaleWidth(ToPercent(newXP), 10)
		--gained:FadeIn(10)
		--gained_edge:FadeIn(10)
	
		--wait(10) -- delay for XP increase
			bar:ScaleWidth(ToPercent(newXP), animationSpeed)
			
		wait(animationSpeed)
			--gained:FadeOut(50)
			--gained_edge:FadeOut(50)

		xpGainAnimationThread = nil
	end)
end

function registerHealthManaExp()	
	local XPAnimation				= object:GetWidget('gameXPAnimation')

	local manaCurrentLabel 			= object:GetWidget('gameOrbManaCurrent')
	local manaTotalLabel 			= object:GetWidget('gameOrbManaTotal')
	local manaOrb 					= object:GetGroup('gameOrbManaPercent')
	local manaOrbEdge				= object:GetWidget('gameOrbManaNoClipPercent')
	local manaOrbEffect				= object:GetWidget('gameOrbManaFillEffect')
	local manaOrbTip		 		= object:GetWidget('gameOrbManaSignButtonTip')

	local healthCurrentLabel 		= object:GetWidget('gameOrbHealthCurrent')
	local healthTotalLabel 			= object:GetWidget('gameOrbHealthTotal')
	local healthOrb 				= object:GetGroup('gameOrbHealthPercent')
	local healthOrbEdge				= object:GetWidget('gameOrbHealthNoClipPercent')
	local healthOrbEffect			= object:GetWidget('gameOrbHealthFillEffect')
	local healthOrbTip		 		= object:GetWidget('gameOrbHealthSignButtonTip')

	local expBar 					= object:GetWidget('gameXPPercent')
	local expBar_gained				= object:GetWidget('gameXPPercent_gained')
	local expBar_gainedEdge			= object:GetWidget('gameXPPercent_gainedEdge')
	local expLevelLabel 			= object:GetWidget('gameLevelCurrent')
	local expLevelBar 				= object:GetWidget('gameXPContainer_leveling')
	local expMaxLevel 				= object:GetWidget('gameXPContainer_max')
	
	local lastEXP					= 0

	gameHelper.registerWatchTextFloor(manaCurrentLabel, 	'HeroUnit', 'mana')
	gameHelper.registerWatchTextFloor(manaTotalLabel, 		'HeroUnit', 'manaMax')
	
	local function orbWidthAtPercent(percent)
		return (12.09372717*math.cos(2.662417908*(percent-.5)))..'h' -- Magical formula of magical width calculation
	end

	for k,v in ipairs(manaOrb) do
		v:RegisterWatchLua('HeroUnit', function(widget, trigger)
			local mana = trigger.mana
			local manaMax = trigger.manaMax
			
			if manaMax > 0 then
				widget:SetHeight(ToPercent(mana / manaMax))
			else
				widget:SetHeight(0)
			end
		end, true, nil, 'mana', 'manaMax')
	end
	
	local oldmanaEdgeVis = false
	local oldManaHeight = 0
	manaOrbEdge:RegisterWatchLua('HeroUnit', function(widget, trigger)
		local mana 				= trigger.mana
		local manaMax 			= trigger.manaMax
		local manaPercent 		= mana/manaMax
		
		-- FadeIn or Out the Edge Object
		if manaPercent == 1 or manaPercent == 0 then
			if oldmanaEdgeVis then
				widget:FadeOut(100)
			end
			oldmanaEdgeVis = false
		else
			if not oldmanaEdgeVis then
				widget:FadeIn(200)
			end
			oldmanaEdgeVis = true
		end
		
		-- Scale Width of the Edge Object
		if manaPercent == 1  or manaPercent == 0 then
			widget:SetWidth('0h')
		else
			if (math.floor(manaOrb[1]:GetHeight()) ~= math.floor(oldManaHeight)) then
				widget:SetWidth(orbWidthAtPercent(manaPercent))
			end
		end
		oldManaHeight = manaOrb[1]:GetHeight()
	end, true, nil, 'mana', 'manaMax')
	
	manaOrbEffect:SetCallback('onshow', function(widget)
		widget:SetEffect('/ui/_effects/new_interface/liquid_blue.effect')
	end)

	gameHelper.registerWatchTextFloor(healthCurrentLabel, 	'HeroUnit', 'health')
	gameHelper.registerWatchTextFloor(healthTotalLabel, 	'HeroUnit', 'healthMax')
	
	for k,v in ipairs(healthOrb) do
		v:RegisterWatchLua('HeroUnit', function(widget, trigger)
			local health = trigger.health
			local healthMax = trigger.healthMax

			if healthMax > 0 then
				widget:SetHeight(ToPercent(health / healthMax))
			else
				widget:SetHeight(0)
			end
		end, true, nil, 'health', 'healthMax')
	end
	
	local oldhealthEdgeVis = false
	local oldHealthHeight = 0
	healthOrbEdge:RegisterWatchLua('HeroUnit', function(widget, trigger)
		local health 				= trigger.health
		local healthMax 			= trigger.healthMax
		local healthPercent 		= health/healthMax
		
		-- FadeIn or Out the Edge Object
		if healthPercent == 1 or healthPercent == 0 then
			if oldhealthEdgeVis then
				widget:FadeOut(100)
			end
			oldhealthEdgeVis = false
		else
			if not oldhealthEdgeVis then
				widget:FadeIn(200)
			end
			oldhealthEdgeVis = true
		end
		
		-- Scale Width of the Edge Object
		if healthPercent == 1  or healthPercent == 0 then
			widget:SetWidth('0h')
		else
			if (math.floor(healthOrb[1]:GetHeight()) ~= math.floor(oldHealthHeight)) then
				widget:SetWidth(orbWidthAtPercent(healthPercent))
			end
		end
		oldHealthHeight = healthOrb[1]:GetHeight()
	end, true, nil, 'health', 'healthMax')
	
	healthOrbEffect:SetCallback('onshow', function(widget)
		widget:SetEffect('/ui/_effects/new_interface/liquid_gold.effect')
	end)
	
	-- Tooltips	
	local manaTipWidget 		= gameGetWidget('mana_tooltip')
	local manaTipIconParent		= gameGetWidget('mana_tipIcon'):GetParent()
	local manaTipName 			= gameGetWidget('mana_tipName')
	local manaTipVal 			= gameGetWidget('mana_tipValue')
	local manaTipDesc 			= gameGetWidget('mana_tipDescription')
	
	manaTipIconParent:SetVisible(false)
	manaTipName:SetX('0.6h')
	
	manaTipName:SetText(Translate('tooltip_total_mana')..' ('..Translate('tooltip_regen')..')')
	manaTipDesc:SetText(Translate('tooltip_total_mana_msg'))
	
	manaTipVal:RegisterWatchLua('HeroUnit', function(widget, trigger)
		local mana	 		= trigger.mana
		local manaMax 		= trigger.manaMax
		local manaRegen 	= trigger.manaRegen
		
		widget:SetText(math.floor(mana)..'/'..math.floor(manaMax)..' (+'..FtoA2(manaRegen, 0, 1)..')')
	end, true, nil, 'manaMax', 'manaRegen')
	
	manaOrbTip:SetCallback('onmouseover', function(widget)
		manaTipWidget:SetVisible(true)
	end)
	
	manaOrbTip:SetCallback('onmouseout', function(widget)
		manaTipWidget:SetVisible(false)
	end)
	
	local healthTipWidget 		= gameGetWidget('health_tooltip')
	local healthTipIconParent	= gameGetWidget('health_tipIcon'):GetParent()
	local healthTipName 		= gameGetWidget('health_tipName')
	local healthTipVal 			= gameGetWidget('health_tipValue')
	local healthTipDesc 		= gameGetWidget('health_tipDescription')
	
	healthTipIconParent:SetVisible(false)
	healthTipName:SetX('0.6h')
		
	healthTipName:SetText(Translate('tooltip_total_health')..' ('..Translate('tooltip_regen')..')')
	healthTipDesc:SetText(Translate('tooltip_total_health_msg'))
	
	healthTipVal:RegisterWatchLua('HeroUnit', function(widget, trigger)
		local health		= trigger.health
		local healthMax 	= trigger.healthMax
		local healthRegen	= trigger.healthRegen
		
		widget:SetText(math.floor(health)..'/'..math.floor(healthMax)..' (+'..FtoA2(healthRegen, 0, 1)..')')
	end, true, nil, 'healthMax', 'healthRegen')
	
	healthOrbTip:SetCallback('onmouseover', function(widget)
		healthTipWidget:SetVisible(true)
	end)
	
	healthOrbTip:SetCallback('onmouseout', function(widget)
		healthTipWidget:SetVisible(false)
	end)

	gameHelper.registerWatchText(expLevelLabel, 'HeroUnit', 'level')

	expBar:RegisterWatchLua('HeroUnit', function(widget, trigger)
		local hasLeveled 	= false		
		local animationSpeed = 200
		
		if (trigger.percentNextLevel - lastEXP) < 0 then
			hasLeveled = true
		end

		animateXPGain(widget, expBar_gained, expBar_gainedEdge, hasLeveled, trigger.percentNextLevel, lastEXP, animationSpeed, fullBarTime, XPAnimation)
		
		lastEXP = trigger.percentNextLevel
	end, true, nil, 'experience')

	expMaxLevel:RegisterWatchLua('HeroUnit', function(widget, trigger)
		local level = trigger.level
		local hero_maxLevel = GetCvarNumber('hero_maxLevel')
		
		widget:SetVisible(level == hero_maxLevel)
		expLevelBar:SetVisible(level ~= hero_maxLevel)
	end, true, nil, 'level')
end


-- register the cooldown icons
function registerCooldowns()
	local stateIndices = {	first = 32, last = 41 }

	local function registerState(widgetPrefix, trigger, index)
		
		libGeneral.createGroupTrigger('heroState'..index..'DurationVisibility', {
			'HeroInventory'..index..'.duration',
			'HeroInventory'..index..'.exists',
			'GamePhase.gamePhase'
		})
	
		libGeneral.createGroupTrigger('heroState'..index..'Visibility', {
			'HeroInventory'..index..'.exists',
			'GamePhase.gamePhase'
		})
		
		local panel = object:GetWidget(widgetPrefix)
		local duration = object:GetWidget(widgetPrefix .. '_cooldownText')
		local icon = object:GetWidget(widgetPrefix .. '_icon')
		local pie = object:GetWidget(widgetPrefix .. '_cooldown')

		pie:RegisterWatchLua(trigger, function(widget, trigger)
			local durationPercent = trigger.durationPercent

			if durationPercent > 0 then
				widget:SetVisible(true)
				widget:SetValue(durationPercent)
			else
				widget:SetVisible(false)
			end
		end, true, nil, 'durationPercent')		
		
		panel:RegisterWatchLua(trigger, function(widget, trigger)
			widget:SetCallback('onmouseover', function(widget)
				if (not Empty(trigger.displayName)) then
					simpleTipGrowYUpdate(true, trigger.icon, trigger.displayName, trigger.description, libGeneral.HtoP(32))
				end
			end)
		end)	-- , false, nil, 'exists'		

		panel:SetCallback('onmouseout', function(widget)
			simpleTipGrowYUpdate(false)
		end)		
		
		panel:RegisterWatchLua('heroState'..index..'Visibility', function(widget, groupTrigger)
			local showWidget = (groupTrigger['HeroInventory'..index].exists and groupTrigger['GamePhase'].gamePhase < 7)
			
			if showWidget then
				panel:FadeIn(200)
			else
				panel:FadeOut(150)
			end
		end)	-- , false, nil, 'exists'

		duration:RegisterWatchLua('heroState'..index..'DurationVisibility', function(widget, groupTrigger)
			local triggerTimer	= groupTrigger['HeroInventory'..index]
			local duration		= triggerTimer.duration
			local gamePhase		= groupTrigger['GamePhase'].gamePhase
			local exists		= (triggerTimer.exists and gamePhase < 7)
			if exists and duration > 0 then
				widget:SetText(math.ceil(duration * 0.001)..'s')
				widget:SetVisible(true)
			else
				widget:SetVisible(false)
			end
			widget:SetVisible(exists and duration > 0)
		end)	-- , false, nil, 'duration', 'exists'

		gameHelper.registerWatchTexture(icon, trigger, 'icon')

		--	pie:RegisterWatchLua('HeroInventory'..index, function(widget, trigger) widget:SetWidth(ToPercent(trigger.durationPercent)) end, false, nil, 'durationPercent')
	end

	for i=stateIndices.first, stateIndices.last, 1 do
		registerState('gameCooldownSquareState' .. i, 'HeroInventory' .. i, i)
	end
end

-- register the four abilites and the pet ability
function registerAbilities()
	local petActiveIndex 	= 18
	local petPassiveIndex 	= 17

	local object = object
	local function registerAbility(widgetPrefix, index, isPet, showRange)
	
		if showRange == nil then 
			showRange = true
		end
	
		local abilityPanel 					= object:GetWidget(widgetPrefix)
		local parent 						= object:GetWidget(widgetPrefix ..'_parent')
		local abilityIcon 					= object:GetWidget(widgetPrefix ..'_icon')
		local abilityLevelUp 				= object:GetWidget(widgetPrefix ..'_levelUp')
	
		local timerBarContainer				= object:GetWidget(widgetPrefix .. 'TimerBarContainer')
		local timerBar 						= object:GetWidget(widgetPrefix .. 'TimerBar')
		
		local abilityManaTimerContainer 	= object:GetWidget(widgetPrefix .. 'ManaTimerContainer')
		local abilityManaTimerBar 			= object:GetWidget(widgetPrefix .. 'ManaTimerBar')
		local abilityManaTimerLabel 		= object:GetWidget(widgetPrefix .. 'ManaTimerLabel')

		local abilityCooldownPie 			= object:GetWidget(widgetPrefix .. 'CooldownPie')
		local abilityCooldownLabel 			= object:GetWidget(widgetPrefix .. 'Cooldown')

		local abilityGloss 					= object:GetWidget(widgetPrefix .. 'Gloss')
		local abilityCanLevel 				= object:GetWidget(widgetPrefix .. 'CanLevel')
		local abilityAutocastIndicator 		= object:GetWidget(widgetPrefix .. 'AutocastIndicator')
		local abilityTargetingIndicator 	= object:GetWidget(widgetPrefix .. 'TargetingIndicator')
		local abilityRefreshEffect 			= object:GetWidget(widgetPrefix .. 'RefreshEffect')
	
		local abilityChargeBarContainer 	= object:GetWidget(widgetPrefix .. 'ChargeBarContainer')
		local abilityChargeBar 				= object:GetWidget(widgetPrefix .. 'ChargeBar')
		local gameXPContainerSpacer			= object:GetWidget('gameXPContainerSpacer')
		
		-- local abilityVerticalBarContainer 	= object:GetWidget(widgetPrefix .. 'VerticalBarContainer')
		-- local abilityVerticalBar			= object:GetWidget(widgetPrefix .. 'VerticalBar')

		local abilityTickContainer 			= object:GetWidget(widgetPrefix .. '_tickContainer')
		local abilityTicks 					= { }
		
		for i=1,6 do
			abilityTicks[i] = 
			{ 
				container	= object:GetWidget(widgetPrefix .. '_tick' .. i .. 'Container'),
				tick 		= object:GetWidget(widgetPrefix .. '_tick' .. i)
			}
		end

		libGeneral.createGroupTrigger('groupTrigger' .. widgetPrefix .. index, {
			'ActiveInventory'..index..'.level',
			'ActiveInventory'..index..'.maxLevel',
			'ActiveInventory'..index..'.isOnCooldown',
			'ActiveInventory'..index..'.needMana',
			'ActiveInventory'..index..'.isDisabled',
			'ActiveUnit.isActive'
		})		
		
		-- parent
		parent:RegisterWatchLua('ActiveInventory' .. (index), function(widget, trigger)
			widget:SetVisible(trigger.exists)
		end, true, nil, 'exists')				
		
		-- Icon
		abilityIcon:RegisterWatchLua('ActiveInventory' .. (index), function(widget, trigger)
			widget:SetTexture(trigger.icon)
		end, true, nil, 'icon')		
		
		abilityIcon:RegisterWatchLua('groupTrigger' .. widgetPrefix .. index, function(widget, groupTrigger)
			local notLeveled = groupTrigger['ActiveInventory'..index].level == 0 and groupTrigger['ActiveInventory'..index].maxLevel > 0
			local onCooldown = groupTrigger['ActiveInventory'..index].isOnCooldown
			local needMana	 = groupTrigger['ActiveInventory'..index].needMana
			local isDisabled = groupTrigger['ActiveInventory'..index].isDisabled
			local isAlive = groupTrigger['ActiveUnit'].isActive
			
			local statusColorR	= 1
			local statusColorG	= 1
			local statusColorB	= 1
			
			if not notLeveled and not onCooldown and not needMana and not isDisabled and (isAlive) then
				widget:SetRenderMode('normal')
   				widget:SetColor(1.0,1.0,1.0)
			else
				widget:SetRenderMode('grayscale')
   				widget:SetColor(0.4,0.4,0.4) 
			end
			
			if notLeveled then
				statusColorR	= styles_inventoryStatusColorUnleveledR
				statusColorG	= styles_inventoryStatusColorUnleveledG
				statusColorB	= styles_inventoryStatusColorUnleveledB
			elseif isDisabled or (not isAlive) then
				statusColorR	= styles_inventoryStatusColorDisabledR
				statusColorG	= styles_inventoryStatusColorDisabledG
				statusColorB	= styles_inventoryStatusColorDisabledB
			elseif needMana then
				statusColorR	= styles_inventoryStatusNeedManaR
				statusColorG	= styles_inventoryStatusNeedManaG
				statusColorB	= styles_inventoryStatusNeedManaB
			end

			widget:SetColor(statusColorR, statusColorG, statusColorB)
			widget:SetTexture(groupTrigger['ActiveInventory'..index].icon)
		end, true, nil)

		
		if isPet then
			abilityLevelUp:SetVisible(false)
		else
			--
			-- level up
			gameHelper.registerWatchVisible(abilityLevelUp, 'ActiveInventory' .. (index), 'canLevelUp', false)
			gameHelper.registerWatchVisible(abilityCanLevel, 'ActiveInventory' .. index, 'canLevelUp', false)

			abilityLevelUp:SetCallback('onclick', function(widget)
				PlaySound('/ui/sounds/sfx_button_generic.wav')
   				widget:UICmd("LevelUpAbility("..index..")")
			end)
			
			abilityLevelUp:SetCallback('onmouseover', function(widget)
				UpdateCursor(widget, true, { canLeftClick = true })
			end)
			
			abilityLevelUp:SetCallback('onmouseout', function(widget)
				UpdateCursor(widget, false, { canLeftClick = true })
			end)

			--
			-- level pips			
			local function inventoryRegisterPrimaryLevelPips(widgetPrefix, index)
				local oldLevel = 0
				for i=1,4,1 do
					object:GetWidget(widgetPrefix .. '_' .. i .. '_leveled'):RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
						if trigger.level > oldLevel then
							oldLevel = trigger.level
						end
						
						if i <= trigger.maxLevel then
							widget:SetVisible(true)
							if trigger.level >= i then
								widget:SetColor(0, 1, 0, 1)
								widget:Sleep(150, function()
									widget:SetColor(1, 1, 1)
									widget:Sleep(150, function()
										widget:SetColor(0, 1, 0, 1)
										widget:Sleep(150, function()
											widget:SetColor(1, 1, 1)
											widget:Sleep(150, function()
												widget:SetColor(0, 1, 0, 1)
												widget:Sleep(150, function()
													widget:SetColor(1, 1, 1)
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
			
			inventoryRegisterPrimaryLevelPips(widgetPrefix, index)
			
			for i=1,4 do
				local levelPip = object:GetWidget(widgetPrefix .. '_' .. i .. '_leveled')
				
				gameHelper.registerWatchVisible(levelPip, 'ActiveInventory' .. (index), 'level', nil, function(val)	
					return i <= val
				end)
				
				
			end		
		end

		-- register key binding
		gameHelper.registerBindKey(widgetPrefix, 'ActiveInventory' .. (index), 'ActivateTool', index)
			
		-- register button 

		if index == petActiveIndex then
			abilityIcon:RegisterWatchLua('ActiveInventory' .. index, function(widget, trigger)
				if trigger.isActivatable then
					widget:SetCallback('onclick', function(widget)
						ActivateTool(index)
					end)
				end
				widget:SetCallback('onmouseover', function(widget)
					if showRange then
						widget:UICmd("ShowRangeIndicator(GetSelectedEntity(), "..index..")")
					end					
					gamePetTipShow()
					UpdateCursor(widget, true, { canLeftClick = true})
				end)

				widget:SetCallback('onmouseout', function(widget)
					if showRange then
						widget:UICmd("HideRangeIndicator()")
					end					
					gamePetTipHide()
					UpdateCursor(widget, false, { canLeftClick = true})
				end)

			end, true, nil, 'isActivatable')
		else
			local scoreboardOpen = false
			abilityIcon:RegisterWatch('gameToggleScoreboard', function(widget, keyDown)
				scoreboardOpen = AtoB(keyDown)				
			end)
			
			abilityIcon:RegisterWatchLua('ActiveInventory' .. index, function(widget, trigger)

				widget:SetCallback('onclick', function(widget)	
					local moreInfo = LuaTrigger.GetTrigger('ModifierKeyStatus').moreInfoKey or scoreboardOpen
					if (trigger.canLevelUp) and (moreInfo) then
						PlaySound('/ui/sounds/sfx_button_generic.wav')
						widget:UICmd("LevelUpAbility("..index..")")						
					elseif trigger.isActivatable then
						ActivateTool(index)
					end	
				end)
				
				widget:SetCallback('onmouseover', function(widget)
					if showRange then
						widget:UICmd("ShowRangeIndicator(GetSelectedEntity(), "..index..")")
					end				
					Trigger('abilityTipShow', 2, index)
					UpdateCursor(widget, true, { canLeftClick = true})
				end)

				widget:SetCallback('onmouseout', function(widget)
					if showRange then
						widget:UICmd("HideRangeIndicator()")
					end					
					Trigger('abilityTipHide')
					UpdateCursor(widget, false, { canLeftClick = true})
				end)

			end, true, nil, 'isActivatable')
		end

		--
		-- mana bar / cooldown / refresh
		libGeneral.createGroupTrigger('gameInventoryManaTime'..index, {
			'ActiveInventory'..index..'.manaCost',
			'ActiveInventory'..index..'.remainingCooldownPercent',
			'ActiveUnit.isActive',
			'ActiveUnit.mana',
			'ActiveUnit.manaRegen'
		})
		
		-- ability refresh effect
		local function playRefreshEffect()
			abilityRefreshEffect:SetVisible(true)
			abilityRefreshEffect:UICmd(
				"SetAnim('idle');"..
				"SetEffect('/ui/_models/refresh/refresh.effect');"
			)
			abilityRefreshEffect:Sleep(1333 * 2, function() abilityRefreshEffect:SetVisible(false) end)
			PlaySound('/shared/sounds/ui/sfx_refresh.wav')
		end
		
		-- checks if the cooldown should still run
		local function checkCooldownPercent(remainingCooldownPercent, abilityCooldownPie, wasOnCooldown, wasManaCount)
			if remainingCooldownPercent > 0 then
				abilityCooldownPie:SetVisible(true)
				abilityCooldownPie:SetValue(remainingCooldownPercent)
				wasOnCooldown = true
				wasManaCount = false
			else
				abilityCooldownPie:SetVisible(false)

				if wasOnCooldown or wasManaCount then
					playRefreshEffect()	
				end
				wasOnCooldown = false
				wasManaCount = false
			end
		end

		local manaTimerInitRemaining	= 0
		local manaTimerInitCurrent 		= 0
		local wasOnCooldown 			= false
		local wasManaCount				= false

		abilityManaTimerBar:RegisterWatchLua('gameInventoryManaTime' .. index, function(widget, groupTrigger)
			local triggerInventory			= groupTrigger['ActiveInventory'..index]
			local triggerUnit				= groupTrigger['ActiveUnit']
			local manaCurrent				= triggerUnit.mana
			local manaRegen					= triggerUnit.manaRegen
			local heroActive				= triggerUnit.isActive
			local manaCost					= triggerInventory.manaCost
			local remainingCooldownPercent	= triggerInventory.remainingCooldownPercent
			local resetTimer = true
		
			if heroActive and manaCost > 0 then
				if remainingCooldownPercent <= 0 then
					if manaCost > manaCurrent then
						abilityManaTimerContainer:SetVisible(true)
						abilityManaTimerLabel:SetVisible(true)
						
						local secondsRemaining = (manaCost - manaCurrent) / manaRegen						
						if secondsRemaining > 0 then
							if manaTimerInitRemaining == 0 then
								manaTimerInitRemaining	= manaCost - manaCurrent
								manaTimerInitCurrent = manaCurrent
							end
							
							widget:SetVisible(true)
							widget:SetWidth(ToPercent(1- math.min((math.max((manaCurrent - manaTimerInitCurrent), 1) / manaTimerInitRemaining), 1)))
							abilityManaTimerLabel:SetText(Round(manaCost - manaCurrent))
							resetTimer = false
							wasManaCount = true
						else
							checkCooldownPercent(remainingCooldownPercent, abilityCooldownPie, wasOnCooldown, wasManaCount)
						end
					else
						checkCooldownPercent(remainingCooldownPercent, abilityCooldownPie, wasOnCooldown, wasManaCount)
					end
				else
					checkCooldownPercent(remainingCooldownPercent, abilityCooldownPie, wasOnCooldown, wasManaCount)
				end
			else
				checkCooldownPercent(remainingCooldownPercent, abilityCooldownPie, wasOnCooldown, wasManaCount)
			end
		
			if resetTimer then
				abilityManaTimerContainer:SetVisible(false)
				abilityManaTimerLabel:SetVisible(false)
				manaTimerInitRemaining = 0
				wasOnCooldown = false
				wasManaCount = false
			end
		end)
	
		abilityCooldownLabel:RegisterWatchLua('ActiveInventory' .. index, function(widget, trigger)
			local cooldownTime = trigger.remainingCooldownTime
			
			widget:SetVisible(cooldownTime > 0)
			widget:SetText(math.ceil(cooldownTime / 1000) .. 's')
		end, true, nil, 'remainingCooldownTime')

		abilityGloss:RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
			widget:SetVisible(trigger.isActivatable and trigger.exists)
		end, false, nil, 'isActivatable', 'exists')			
			
		abilityAutocastIndicator:RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
			widget:SetVisible(trigger.inUse)
		end, false, nil, 'inUse')			
			
		abilityTargetingIndicator:RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
			if (trigger.isActiveSlot) then
				widget:SetVisible(1)
				widget:UICmd([[SetEffect('/ui/_effects/toggle/toggle.effect')]])
			else
				widget:SetVisible(0)
				widget:UICmd([[SetEffect('')]])
			end
		end, false, nil, 'isActiveSlot')		

		abilityRefreshEffect:RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
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
		
		-- vertical timer bar
		timerBar:RegisterWatchLua('ActiveInventory' .. index, function(widget, trigger)
			local timeRemaining = trigger.timer
			widget:SetVisible(timeRemaining > 0)
			if timeRemaining > 0 then
				widget:SetHeight(ToPercent(timeRemaining / trigger.timerDuration))
			end
		end, true, nil, 'timer', 'timerDuration')
		timerBarContainer:RegisterWatchLua('ActiveInventory' .. index, function(widget, trigger)
			local timeRemaining = trigger.timer
			widget:SetVisible(timeRemaining > 0)
		end, true, nil, 'timer', 'timerDuration')
		
		-- charge bar
		abilityChargeBar:RegisterWatchLua('ActiveInventory' .. index, function(widget, trigger)
			local maxCharges = trigger.maxCharges
			if maxCharges > 6 then
				widget:SetWidth(ToPercent(trigger.charges / maxCharges))
			end
		end, true, nil, 'charges', 'maxCharges')
		abilityChargeBarContainer:RegisterWatchLua('ActiveInventory' .. index, function(widget, trigger)
			local maxCharges = trigger.maxCharges
			widget:SetVisible(maxCharges > 6)
		end, true, nil, 'charges', 'maxCharges')

		gameXPContainerSpacer:RegisterWatchLua('ActiveInventory'..index, function(widget, trigger)
			if (trigger.maxCharges > 0) then
				gameXPContainerSpacer:SetHeight("2.5h")
				gameXPContainerSpacer:UnregisterWatchLua('ActiveInventory'..index)
			end
		end, false, nil, 'maxCharges')
		
		-- charge pips
		for i=1,6 do
			abilityTicks[i].container:RegisterWatchLua('ActiveInventory' .. index, function(widget, trigger)
				widget:SetVisible(trigger.maxCharges >= i and trigger.maxCharges <= 6)
			end, true, nil, 'charges', 'maxCharges')

			abilityTicks[i].tick:RegisterWatchLua('ActiveInventory' .. index, function(widget, trigger)
				widget:SetVisible(trigger.charges >= i and trigger.maxCharges >= i and trigger.maxCharges <= 6)
			end, true, nil, 'charges', 'maxCharges')
		end

	end

	registerAbility('gameAbility5', petActiveIndex, true)

	for i = 0, 3 do
		local widgetPrefix = 'gameAbility' .. (i + 1)
		registerAbility(widgetPrefix, i)
	end

	-- register passive pet ability
	gameHelper.registerMiniButton('gamePetPassiveButton', 'ActiveInventory' .. petPassiveIndex, 'icon')

	local cooldown = interface:GetWidget('gamePetPassiveButtonCooldown', nil, true)
	local cooldownPie = interface:GetWidget('gamePetPassiveButtonCooldownPie', nil, true)
	if (cooldown) then
		cooldown:RegisterWatchLua('ActiveInventory' .. petPassiveIndex, function(widget, trigger2)
			widget:SetVisible(trigger2.isOnCooldown)
			widget:SetText(math.ceil(trigger2.remainingCooldownTime / 1000))
		end, false, nil, 'remainingCooldownTime', 'isOnCooldown')
	end	
	if (cooldownPie) then
		cooldownPie:RegisterWatchLua('ActiveInventory' .. petPassiveIndex, function(widget, trigger2)
			widget:SetVisible(trigger2.isOnCooldown)
		end, false, nil, 'remainingCooldownTime', 'isOnCooldown')
	end	

	
end
