-- new_game_scoreboard.lua (12/2014)
-- tab-key scoreboard script

-- Scoreboard Animation Function
local scoreboardAnimationThread = nil

local function LoadUpScoreboard (widget, animateOn, endY)
	
	if (scoreboardAnimationThread) then
		scoreboardAnimationThread:kill()
		scoreboardAnimationThread = nil
	end
	
	scoreboardAnimationThread = libThread.threadFunc(function()
		if animateOn then
			widget:SetVisible(0)
			widget:FadeIn(80)
		else
			widget:FadeOut(50)
		end			
		scoreboardAnimationThread = nil
	end)
end

-- register the scoreboard
function registerScoreboard()
	local scoreBoard 				= object:GetWidget('gameScoreboardContainers')
	local scoreboardAnimation		= object:GetWidget('gameScoreboardContainer')
	local scoreboardY				= scoreboardAnimation:GetY()	
	
	scoreBoard:RegisterWatch('gameToggleScoreboard', function(widget, keyDown)
		if AtoB(keyDown) then
			local heroEntity = LuaTrigger.GetTrigger('HeroUnit').heroEntity
			local isTutorial = (heroEntity == 'Hero_CapriceTutorial') or (heroEntity == 'Hero_CapriceTutorial2')
			if (not isTutorial) then
				widget:FadeIn(80)
				LoadUpScoreboard(scoreboardAnimation, true, scoreboardY)
			end
		else
			widget:FadeOut(50)
			LoadUpScoreboard(scoreboardAnimation, false, scoreboardY)
		end
	end)

	scoreBoard:FadeOut(50)
	LoadUpScoreboard(scoreboardAnimation, false, scoreboardY)	
	
	local scoreBoardAllyTeam 	= scoreBoard:GetWidget('gameScoreboardAllyTeamName')
	local scoreBoardEnemyTeam 	= scoreBoard:GetWidget('gameScoreboardEnemyTeamName')

	local scoreBoardAllyScore	= scoreBoard:GetWidget('gameScoreboardAllyScore')
	local scoreBoardEnemyScore 	= scoreBoard:GetWidget('gameScoreboardEnemyScore')

	local function RegisterBaldirKillsWatch(team, teamnum, numkills)	
		local icon = scoreBoard:GetWidget('gameScoreboard'..team..'BaldirKills'..tostring(numkills))
		icon:UnregisterWatchLua('ScoreboardTeam'..teamnum)
		icon:RegisterWatchLua('ScoreboardTeam'..teamnum, function(widget, trigger)
			if ((trigger.roundScore % 3) >= numkills) then
				icon:SetVisible(1)
			else
				icon:SetVisible(0)
			end
		end, true, nil, 'roundScore')
	end

	scoreBoardAllyTeam:RegisterWatchLua('Team', function(widget, trigger)
		-- todo: strings
		if trigger.team == 2 then
			scoreBoardAllyTeam:SetText(Translate("general_valor"))
			scoreBoardEnemyTeam:SetText(Translate("general_glory"))

			gameHelper.registerWatchText(scoreBoardEnemyScore, 'ScoreboardTeam1', 'totalKills')
			gameHelper.registerWatchText(scoreBoardAllyScore, 'ScoreboardTeam2', 'totalKills')
			
			RegisterBaldirKillsWatch('Ally',  '2', 1)
			RegisterBaldirKillsWatch('Ally',  '2', 2)
			RegisterBaldirKillsWatch('Ally',  '2', 3)
			RegisterBaldirKillsWatch('Enemy', '1', 1)
			RegisterBaldirKillsWatch('Enemy', '1', 2)
			RegisterBaldirKillsWatch('Enemy', '1', 3)	
				
		else
			scoreBoardAllyTeam:SetText(Translate("general_glory"))
			scoreBoardEnemyTeam:SetText(Translate("general_valor"))
	
			gameHelper.registerWatchText(scoreBoardAllyScore, 'ScoreboardTeam1', 'totalKills')
			gameHelper.registerWatchText(scoreBoardEnemyScore, 'ScoreboardTeam2', 'totalKills')
			
			RegisterBaldirKillsWatch('Ally',  '1', 1)
			RegisterBaldirKillsWatch('Ally',  '1', 2)
			RegisterBaldirKillsWatch('Ally',  '1', 3)
			RegisterBaldirKillsWatch('Enemy', '2', 1)
			RegisterBaldirKillsWatch('Enemy', '2', 2)
			RegisterBaldirKillsWatch('Enemy', '2', 3)	
			
		end
	end, true, nil, 'team')
	
	local function GenerateCraftedItemTip(tooltipTriggerIndex, tooltipTrigger)
		local itemInfo = LuaTrigger.GetTrigger(tooltipTrigger..tooltipTriggerIndex)

		if (itemInfo) and (itemInfo.exists) then
			shopItemTipShow(tooltipTriggerIndex, tooltipTrigger)
		end
	end
	
	local function ShowHeroTooltip(sourceWidget, unitTrigger, actuallyTheUnitTrigger, index, unitType)
		
		if (unitType == 'Player') then
			unitType = 'Hero'
		end
		
		local PlayerScore = LuaTrigger.GetTrigger('PlayerScore')
		local height, width = 10, 22

		sourceWidget:GetWidget('game_hero_unitframe_tooltip'):SetVisible(1)
	
		local text = ''
		if (actuallyTheUnitTrigger) and (actuallyTheUnitTrigger.clanTag) and (not Empty(actuallyTheUnitTrigger.clanTag)) then
			text = (('[' .. (actuallyTheUnitTrigger.clanTag or '') ..']') .. (actuallyTheUnitTrigger.playerName or ''))
		elseif (actuallyTheUnitTrigger) then
			text = (trigger.playerName or '')
		end			
		
		if (unitType == 'Hero') then
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_icon'):SetTexture(actuallyTheUnitTrigger.iconPath)
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_player_label'):SetText(text)
			if ValidateEntity(actuallyTheUnitTrigger.heroEntity) then
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_hero_label'):SetText(GetEntityDisplayName(actuallyTheUnitTrigger.heroEntity))
			end
		else
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_icon'):SetTexture(actuallyTheUnitTrigger.iconPath)
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_player_label'):SetText(text)
			if ValidateEntity(actuallyTheUnitTrigger.typeName) then
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_hero_label'):SetText(GetEntityDisplayName(actuallyTheUnitTrigger.typeName))
			end
		end
		
		local function GetIcon(key)
			if (LuaTrigger.GetTrigger(relation .. key .. index).iconPath) and (not Empty(LuaTrigger.GetTrigger(relation .. key .. index).iconPath)) and (LuaTrigger.GetTrigger(relation .. key .. index).isValid) then
				return LuaTrigger.GetTrigger(relation .. key .. index).iconPath
			else
				return '/ui/shared/textures/pack2.tga'
			end
		end

		sourceWidget:GetWidget('game_hero_unitframe_tooltip_kills_label'):UnregisterWatchLuaByKey('tooltip_kills_label')
		if (unitType == 'Hero') then
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
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_kills_label'):SetText(actuallyTheUnitTrigger.kills)
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_kills_label'):RegisterWatchLua(unitTrigger, function(widget2, trigger2)
					widget2:SetText(trigger2.kills)
				end, false, 'tooltip_kills_label', 'kills', 'assists')
			else
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_kills_label'):SetText(actuallyTheUnitTrigger.kills + actuallyTheUnitTrigger.assists)
				sourceWidget:GetWidget('game_hero_unitframe_tooltip_kills_label'):RegisterWatchLua(unitTrigger, function(widget2, trigger2)
					widget2:SetText(trigger2.kills + trigger2.assists)
				end, false, 'tooltip_kills_label', 'kills', 'assists')
			end
		end
		
		sourceWidget:GetWidget('game_hero_unitframe_tooltip_deaths_label'):UnregisterWatchLuaByKey('tooltip_deaths_label')
		if (unitType == 'Hero') then
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
		if (unitType == 'Hero') then
			height = height + 2.2
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_gpm'):SetVisible(1)
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_gpm_label'):SetText(actuallyTheUnitTrigger.gpm)
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_gpm_label'):RegisterWatchLua(unitTrigger, function(widget2, trigger2)
				widget2:SetText(trigger2.gpm)
			end, false, 'tooltip_gpm_label', 'gpm')
		else
			sourceWidget:GetWidget('game_hero_unitframe_tooltip_gpm'):SetVisible(0)
		end			
		
		local gameSelfPower	= sourceWidget:GetWidget('gameSelfPower')
		local gameSelfDPS	= sourceWidget:GetWidget('gameSelfDPS')
		local gameSelfAS	= sourceWidget:GetWidget('gameSelfAS')
		local game_hero_unitframe_tooltip_attackdamage_label	= sourceWidget:GetWidget('game_hero_unitframe_tooltip_attackdamage_label')
		local gameSelfMitigation	= sourceWidget:GetWidget('gameSelfMitigation')
		local gameSelfResistance	= sourceWidget:GetWidget('gameSelfResistance')
		local gameSelfMoveSpeed	= sourceWidget:GetWidget('gameSelfMoveSpeed')

		gameSelfPower:SetText(math.ceil(actuallyTheUnitTrigger.power))
		gameSelfPower:UnregisterWatchLuaByKey('tooltip_power_label')
		gameSelfPower:RegisterWatchLua(unitTrigger, function(widget2, trigger2)
			widget2:SetText(math.ceil(trigger2.power))
		end, false, 'tooltip_power_label', 'power')		
		
		game_hero_unitframe_tooltip_attackdamage_label:SetText(math.ceil(actuallyTheUnitTrigger.damage))
		game_hero_unitframe_tooltip_attackdamage_label:UnregisterWatchLuaByKey('tooltip_damage_label')
		game_hero_unitframe_tooltip_attackdamage_label:RegisterWatchLua(unitTrigger, function(widget2, trigger2)
			widget2:SetText(math.ceil(trigger2.damage))
		end, false, 'tooltip_damage_label', 'damage')		
		
		gameSelfDPS:SetText(math.ceil(actuallyTheUnitTrigger.dps))
		gameSelfDPS:UnregisterWatchLuaByKey('tooltip_dps_label')
		gameSelfDPS:RegisterWatchLua(unitTrigger, function(widget2, trigger2)
			widget2:SetText(math.ceil(trigger2.dps))
		end, false, 'tooltip_dps_label', 'dps')	
		
		gameSelfAS:SetText(math.ceil(actuallyTheUnitTrigger.attackSpeed)..'%')
		gameSelfAS:UnregisterWatchLuaByKey('tooltip_as_label')
		gameSelfAS:RegisterWatchLua(unitTrigger, function(widget2, trigger2)
			widget2:SetText(math.ceil(trigger2.attackSpeed)..'%')
		end, false, 'tooltip_as_label', 'attackSpeed')
		
		gameSelfMitigation:SetText(math.ceil(actuallyTheUnitTrigger.mitigation))
		gameSelfMitigation:UnregisterWatchLuaByKey('tooltip_a_label')
		gameSelfMitigation:RegisterWatchLua(unitTrigger, function(widget2, trigger2)
			widget2:SetText(math.ceil(trigger2.mitigation))
		end, false, 'tooltip_a_label', 'mitigation')	
		
		gameSelfResistance:SetText(math.ceil(actuallyTheUnitTrigger.resistance))
		gameSelfResistance:UnregisterWatchLuaByKey('tooltip_ma_label')
		gameSelfResistance:RegisterWatchLua(unitTrigger, function(widget2, trigger2)
			widget2:SetText(math.ceil(trigger2.resistance))
		end, false, 'tooltip_ma_label', 'resistance')	

		gameSelfMoveSpeed:SetText(math.ceil(actuallyTheUnitTrigger.moveSpeed))
		gameSelfMoveSpeed:UnregisterWatchLuaByKey('tooltip_ms_label')
		gameSelfMoveSpeed:RegisterWatchLua(unitTrigger, function(widget2, trigger2)
			widget2:SetText(math.ceil(trigger2.moveSpeed))
		end, false, 'tooltip_ms_label', 'moveSpeed')					

		sourceWidget:GetWidget('game_hero_unitframe_tooltip'):SetHeight(libGeneral.HtoP(height))
		sourceWidget:GetWidget('game_hero_unitframe_tooltip'):SetWidth(libGeneral.HtoP(width))

	end	
	
	local function HideHeroTooltip(sourceWidget)
		sourceWidget:GetWidget('game_hero_unitframe_tooltip'):SetVisible(0)
	end	
	
	local function registerScoreboardRow(rowType, index, unitTrigger, unitType)

		local rowWidgets = {
			row 		= scoreBoard:GetWidget('gameScoreboardRow' .. rowType .. index),
			rowClick = scoreBoard:GetWidget('gameScoreboard'..rowType..index..'Row'),
			level 	= scoreBoard:GetWidget('gameScoreboard'..rowType..index..'_level'),
			icon 	= scoreBoard:GetWidget('gameScoreboard'..rowType..index..'_icon'),	
			iconlabel 	= scoreBoard:GetWidget('gameScoreboard'..rowType..index..'_iconlabel'),	
			name 	= scoreBoard:GetWidget('gameScoreboard'..rowType..index..'_name'),		
			hero 	= scoreBoard:GetWidget('gameScoreboard'..rowType..index..'_hero'),		
			pet 	= scoreBoard:GetWidget('gameScoreboard'..rowType..index..'_pet'),	
			items	= { },
			itemsCraftedBorder	= { },
			itemsCraftedIcon	= { },
			boots 	= scoreBoard:GetWidget('gameScoreboard'..rowType..index..'_boots'),
			kills 	= scoreBoard:GetWidget('gameScoreboard'..rowType..index..'_kills'),
			assists = scoreBoard:GetWidget('gameScoreboard'..rowType..index..'_assists'),	
			GPM 	= scoreBoard:GetWidget('gameScoreboard'..rowType..index..'_GPM'),

			speaker	= scoreBoard:GetWidget('gameScoreboard'..rowType..index..'_speaker'), 
			mute 	= scoreBoard:GetWidget('gameScoreboard'..rowType..index..'_mute'),
			muted 	= scoreBoard:GetWidget('gameScoreboard'..rowType..index..'_muted'),
			muted_image 	= scoreBoard:GetWidget('gameScoreboard'..rowType..index..'_muted_image'),
			heroparent 		= scoreBoard:GetWidget('gameScoreboard'..rowType..index..'_heroparent'),

			hover	= scoreBoard:GetWidget('gameScoreBoardRow'..rowType..index..'_hover'),
			glow	= scoreBoard:GetWidget('gameScoreboard'..rowType..index..'_glow')
		}
		
		local actuallyTheUnitTrigger = LuaTrigger.GetTrigger(unitTrigger)
		
		for i=1,7 do	
			rowWidgets.items[i] = scoreBoard:GetWidget('gameScoreboard'..rowType..index..'_item' .. i)
			rowWidgets.itemsCraftedBorder[i] = scoreBoard:GetWidget('gameScoreboard'..rowType..index..'_item' .. i..'CraftedBorder')
			rowWidgets.itemsCraftedIcon[i] = scoreBoard:GetWidget('gameScoreboard'..rowType..index..'_item' .. i..'CraftedIcon')
			
			local tooltipTrigger = nil
			local tooltipTriggerIndex = nil
			if unitType == 'Player' then
				tooltipTrigger = 'HeroInventory'
				tooltipTriggerIndex = 96 + (i - 1)
			else
				if unitType == 'Ally' then
					tooltipTrigger = 'AllyInventory' .. (index) ..'_'
					tooltipTriggerIndex = 96 + (i - 1)
				elseif unitType == 'Enemy' then
					tooltipTrigger = 'EnemyInventory' .. index .. '_'
					tooltipTriggerIndex = 96 + (i - 1)
				end
			end
			
			local actuallyTheTooltipTrigger = LuaTrigger.GetTrigger(tooltipTrigger..tooltipTriggerIndex)
			
			rowWidgets.items[i]:RegisterWatchLua(tooltipTrigger..tooltipTriggerIndex, function(widget, trigger)
				local exists = trigger.exists
				widget:SetVisible(exists)
				if exists then
					widget:SetTexture(trigger.icon)
				end
			end, true, nil, 'icon', 'exists')			
			
			rowWidgets.itemsCraftedIcon[i]:RegisterWatchLua(tooltipTrigger..tooltipTriggerIndex, function(widget, trigger)
				widget:SetVisible((trigger.isPlayerCrafted) and trigger.exists)
			end, true, nil, 'isPlayerCrafted', 'exists')	
			
			rowWidgets.itemsCraftedBorder[i]:RegisterWatchLua(tooltipTrigger..tooltipTriggerIndex, function(widget, trigger)
				widget:SetVisible((trigger.isPlayerCrafted) and trigger.exists)
			end, true, nil, 'isPlayerCrafted', 'exists')			
			
			rowWidgets.items[i]:SetCallback('onmouseover', function(widget)
				GenerateCraftedItemTip(tooltipTriggerIndex, tooltipTrigger)
				rowWidgets.hover:SetVisible(true)
				rowWidgets.glow:SetVisible(true)					
			end)			
			
			rowWidgets.items[i]:SetCallback('onmouseout', function(widget)
				simpleTipGrowYUpdate(false)
				shopItemTipHide()
				rowWidgets.hover:SetVisible(false)
				rowWidgets.glow:SetVisible(false)				
			end)
		end

		if actuallyTheUnitTrigger then
			rowWidgets.heroparent:SetVisible(1)
			rowWidgets.heroparent:SetCallback('onmouseover', function(widget)
				rowWidgets.hover:SetVisible(true)
				rowWidgets.glow:SetVisible(true)		
				ShowHeroTooltip(widget, unitTrigger, actuallyTheUnitTrigger, index, unitType)
			end)		
			rowWidgets.heroparent:SetCallback('onmouseout', function(widget)
				HideHeroTooltip(widget)
				simpleTipGrowYUpdate(false)
				shopItemTipHide()
				rowWidgets.hover:SetVisible(false)
				rowWidgets.glow:SetVisible(false)				
			end)			
			rowWidgets.heroparent:SetCallback('onclick', function(widget)
				SelectUnit(actuallyTheUnitTrigger.index)
				rowWidgets.hover:FadeOut(125, function() rowWidgets.hover:FadeIn(125) end)
				rowWidgets.glow:FadeOut(125, function() rowWidgets.glow:FadeIn(125) end)
			end, true, nil, 'exists')		
		else
			rowWidgets.heroparent:SetVisible(0)
		end		
		
		if actuallyTheUnitTrigger and unitType == 'Ally' and (actuallyTheUnitTrigger.clientNumber) and (actuallyTheUnitTrigger.identID) and IsValidIdent(actuallyTheUnitTrigger.identID) and (not IsMe(actuallyTheUnitTrigger.identID)) then
			rowWidgets.muted:SetVisible(1)
			rowWidgets.muted:SetCallback('onmouseover', function(widget)
				rowWidgets.hover:SetVisible(true)
				rowWidgets.glow:SetVisible(true)					
			end)		
			rowWidgets.muted:SetCallback('onmouseout', function(widget)
				simpleTipGrowYUpdate(false)
				shopItemTipHide()
				rowWidgets.hover:SetVisible(false)
				rowWidgets.glow:SetVisible(false)				
			end)			
			rowWidgets.muted:SetCallback('onclick', function(widget)
				local unitTrigger = LuaTrigger.GetTrigger(unitTrigger)
				if (unitTrigger) then
					if (unitTrigger.clientNumber) and (unitTrigger.identID) and (tonumber(unitTrigger.identID)) and (tonumber(unitTrigger.identID) > 0) then
						UIMute(index - 1, unitTrigger.identID, unitTrigger.clientNumber, unitTrigger.name, unitTrigger.uniqueID)
						
						local muteTrigger = LuaTrigger.GetTrigger('mutePlayerInfo')
						muteTrigger.IdentID = unitTrigger.identID
						muteTrigger.muted = ChatClient.IsIgnored(tostring(muteTrigger.IdentID))
						muteTrigger:Trigger(false)
					end
				end
			end, true, nil, 'exists')		
		else
			rowWidgets.muted:SetVisible(0)
		end
		
		-- Register this row, if there's no player then hide it.
		rowWidgets.row:RegisterWatchLua(unitTrigger, function(widget, trigger)
			if trigger.exists then
				widget:SetVisible(1)
			else
				widget:SetVisible(0)
			end
		end, true, nil, 'exists')

		-- register the specific labels and icons for this row
		gameHelper.registerWatchText(rowWidgets.level, 	unitTrigger, 	'level')
		-- gameHelper.registerWatchText(rowWidgets.name, 	unitTrigger, 	'playerName')
		gameHelper.registerWatchText(rowWidgets.GPM, 	unitTrigger, 	'gpm')

		rowWidgets.name:RegisterWatchLua(unitTrigger, function(widget, trigger)
			local text = ''
			if (trigger) and (trigger.clanTag) and (not Empty(trigger.clanTag)) then
				text = (('[' .. (trigger.clanTag or '') ..']') .. (trigger.playerName or ''))
			elseif (trigger) then
				text = (trigger.playerName or '')
			end			
			widget:SetVisible((trigger.isActive) and (text ~= ''))
			widget:SetText(text)
		end, true, nil, 'isActive', 'playerName')			
		
		gameHelper.registerWatchTexture(rowWidgets.icon, 	unitTrigger, 'iconPath')
		gameHelper.registerWatchTexture(rowWidgets.pet, 	unitTrigger, 'familiar', nil, GetEntityIconPath)
		
		rowWidgets.icon:RegisterWatchLua(unitTrigger, function(widget, trigger)
			widget:SetColor(trigger.isActive and "1 1 1 1" or ".3 .3 .3 1")
			widget:SetRenderMode(trigger.isActive and "normal" or "grayscale")
		end, true, nil, 'isActive')
		
		rowWidgets.iconlabel:RegisterWatchLua(unitTrigger, function(widget, trigger)
			widget:SetVisible((not trigger.isActive) and (trigger.remainingRespawnTime > 0))
			widget:SetText(math.floor(trigger.remainingRespawnTime/1000)..'s')
		end, true, nil, 'isActive', 'remainingRespawnTime')		
		
		rowWidgets.pet:RegisterWatchLua(unitTrigger, function(widget, trigger)
			widget:SetVisible(not Empty(trigger.familiar))
		end, true, nil, 'familiar')
		
		rowWidgets.pet:SetCallback('onmouseover', function(widget)
			simpleTipGrowYUpdate(true, GetEntityIconPath(actuallyTheUnitTrigger.familiar), GetEntityDisplayName(actuallyTheUnitTrigger.familiar), Translate('corral_play_pet') .. ' ' .. GetEntityDisplayName(actuallyTheUnitTrigger.familiar), libGeneral.HtoP(32))
			rowWidgets.hover:SetVisible(true)
			rowWidgets.glow:SetVisible(true)		
		end)
		
		rowWidgets.pet:SetCallback('onmouseout', function(widget)
			simpleTipGrowYUpdate(false)
			rowWidgets.hover:SetVisible(false)
			rowWidgets.glow:SetVisible(false)			
		end)

		gameHelper.registerWatchVisible(rowWidgets.speaker,		unitTrigger, 	'isTalking')
	
		-- the player trigger's parameters are slightly different from the ally / enemy triggers
		if unitType == 'Player' then
			gameHelper.registerWatchText(rowWidgets.hero, 		unitTrigger, 	'displayName')
			gameHelper.registerWatchText(rowWidgets.kills, 		'PlayerScore', 	'heroKills')
			gameHelper.registerWatchText(rowWidgets.assists, 	'PlayerScore', 	'assists')
		else
			gameHelper.registerWatchVisible(rowWidgets.muted_image,		unitTrigger, 	'isClientMuted')
			gameHelper.registerWatchVisible(rowWidgets.mute,		unitTrigger, 	'isClientMuted')
			gameHelper.registerWatchText(rowWidgets.hero, 		unitTrigger,	'typeName', nil, GetEntityDisplayName)
			gameHelper.registerWatchText(rowWidgets.kills, 		unitTrigger, 	'kills')
			gameHelper.registerWatchText(rowWidgets.assists, 	unitTrigger, 	'assists')
		end

		rowWidgets.rowClick:SetCallback('onclick', function(widget)
			SelectUnit(actuallyTheUnitTrigger.index)
			rowWidgets.hover:FadeOut(125, function() rowWidgets.hover:FadeIn(125) end)
			rowWidgets.glow:FadeOut(125, function() rowWidgets.glow:FadeIn(125) end)
		end)
		
		rowWidgets.rowClick:SetCallback('onmouseover', function(widget)
			rowWidgets.hover:SetVisible(true)
			rowWidgets.glow:SetVisible(true)
		end)

		rowWidgets.rowClick:SetCallback('onmouseout', function(widget)
			rowWidgets.hover:SetVisible(false)
			rowWidgets.glow:SetVisible(false)
		end)
	end

	-- register the player's row
	registerScoreboardRow('Player', 0, 'HeroUnit', 'Player')

	-- register the other players
	for index=0,3 do
		registerScoreboardRow('Ally', index, 'AllyUnit' .. (index), 'Ally')
	end
	
	for index=0,4 do
		registerScoreboardRow('Enemy', index, 'EnemyUnit' .. (index), 'Enemy')
	end	
	
end