-- Selected Player Hero

local function selectedPlayerHeroGetUnitFrame(object, playerType, index)
	if playerType == 'hero' then
		return object:GetWidget('gameInfoSelfContainer')
	elseif playerType == 'ally' then
		return object:GetWidget('gameAlly'..index..'Container')
	elseif playerType == 'enemy' then
		return object:GetWidget('gameEnemy'..index..'Container')
	end

	return false
end

local function floatItemSlots(object, toLeft)
	toLeft = toLeft or false
	local indexMod	= 3
	local slots		= {}
	for row=0,1,1 do
		slots = {}
		for col=(97+(indexMod*row)),(99+(indexMod*row)) do
			table.insert(slots, object:GetWidget('selectedPlayerHeroItem'..col))
		end
		
		if toLeft then
			local newSlots = {}
			for i=#slots,1,-1 do
				table.insert(newSlots, slots[i])
			end
			slots = newSlots
		end
		
		libGeneral.floatRight(slots, libGeneral.HtoP(0.45, true))
	end
end

local function unitIndexToPlayerHeroInfo(unitIndex)
	if unitIndex then
		if LuaTrigger.GetTrigger('HeroUnit').index == unitIndex then
			return 'hero', nil, 'heroKills', 'GoldReport', 'gPM', 'deaths'
		else
			for i=0,3,1 do
				if LuaTrigger.GetTrigger('AllyUnit'..i).index == unitIndex then
					return 'ally', i, nil
				end
			end
			for i=0,4,1 do
				if LuaTrigger.GetTrigger('EnemyUnit'..i).index == unitIndex then
					return 'enemy', i, nil
				end
			end
		end
	end

	return false, false, nil
end

local function playerHeroInfoToMVPP(playerType, index)
	if playerType == 'hero' then
		return 'ally4MVP'
	elseif playerType == 'ally' then
		return 'ally'..index..'MVP'
	elseif playerType == 'enemy' then
		return 'enemy'..index..'MVP'
	end

	return false
end

local function playerHeroInfoToUnitTrigger(playerType, index)
	if playerType == 'hero' then
		return 'PlayerScore'
	elseif playerType == 'ally' then
		return 'AllyUnit'..index
	elseif playerType == 'enemy' then
		return 'EnemyUnit'..index
	end

	return false
end

local function selectedPlayerHeroRegisterItem(object, index)
	local button	= object:GetWidget('selectedPlayerHeroItem'..index)
	
	button:SetCallback('onmouseover', function(widget)
		local itemInfoTrigger = LuaTrigger.GetTrigger('SelectedInventory'..index)
		local unitIndex = LuaTrigger.GetTrigger('SelectedUnits0').index
		local playerType = unitIndexToPlayerHeroInfo(unitIndex)
		if (itemInfoTrigger) and (itemInfoTrigger.icon) and (itemInfoTrigger.exists) then
			shopItemTipShow(index, 'SelectedInventory')
		end
	end)
	
	button:SetCallback('onmouseout', function(widget)
		shopItemTipHide()
	end)
	
	object:GetWidget('selectedPlayerHeroItem'..index..'Body'):RegisterWatchLua('SelectedInventory'..index, function(widget, trigger) widget:SetVisible(trigger.exists) end, false, nil, 'exists')
	object:GetWidget('selectedPlayerHeroItem'..index..'Icon'):RegisterWatchLua('SelectedInventory'..index, function(widget, trigger) widget:SetTexture(trigger.icon) end, false, nil, 'icon')
end

local function selectedPlayerHeroUnregisterSlot(container)
	container:UnregisterAllWatchLuaByKey('selectedPlayerHeroWatch')
end

local function selectedPlayerHeroRegisterSlot(object, unitIndex)
	local playerType, index, killParam, gpmTrigger, gpmParam, deathParam = unitIndexToPlayerHeroInfo(unitIndex)
	
	if playerType then

		killParam = killParam or 'kills'
		deathParam = deathParam or 'death'

		
		local triggerName	= playerHeroInfoToUnitTrigger(playerType, index)
		
		gpmTrigger = gpmTrigger or triggerName
		gpmParam = gpmParam or 'gpm'
		
		local mvpParam		= playerHeroInfoToMVPP(playerType, index)
		
		
		if playerType == 'hero' then
			object:GetWidget('selectedPlayerHeroDeathsContainer'):SetVisible(true)
			object:GetWidget('selectedPlayerHeroGPMContainer'):SetVisible(true)
			object:GetWidget('selectedPlayerHeroVitals'):SetVisible(false)
			object:GetWidget('selectedPlayerHeroItems'):SetVisible(false)
		else
			object:GetWidget('selectedPlayerHeroDeathsContainer'):SetVisible(false)
			object:GetWidget('selectedPlayerHeroGPMContainer'):SetVisible(false)
			object:GetWidget('selectedPlayerHeroVitals'):SetVisible(true)
			object:GetWidget('selectedPlayerHeroItems'):SetVisible(true)
		end
		
		local killLabel		= object:GetWidget('selectedPlayerHeroKills')
		local deathLabel	= object:GetWidget('selectedPlayerHeroDeaths')
		local gpmLabel		= object:GetWidget('selectedPlayerHeroGPM')
		
		local unitFrame	= selectedPlayerHeroGetUnitFrame(gameGetInterface(), playerType, index)
		if unitFrame then
			local container = object:GetWidget('selectedPlayerHero')
			container:Sleep(1, function()

				local frameX, frameWidth = unitFrame:GetAbsoluteX(), unitFrame:GetWidth()
				local containerWidth = container:GetWidth()
				
				local targX	= (
					frameX - (
						(
							math.max(frameWidth, containerWidth) - math.min(frameWidth, containerWidth)
						) / 2
					)
				)
			
				local targPad	= 0
				
				if playerType ~= 'hero' then
					if playerType == 'enemy' then
						if LuaTrigger.GetTrigger('Team').team == 1 then
							targPad = libGeneral.HtoP(-7.75)
							object:GetWidget('selectedPlayerHeroItems'):SetX(libGeneral.HtoP(-2.35))
							object:GetWidget('selectedPlayerHeroItemsBG'):SetHFlip(true)
							object:GetWidget('selectedPlayerHeroItemsBG'):SetX('2s')
							object:GetWidget('selectedPlayerHeroItemsBG'):SetAlign('right')
							object:GetWidget('selectedPlayerHeroExtraInfo'):SetX(libGeneral.HtoP(1.25))
							floatItemSlots(object, true)
							object:GetWidget('selectedPlayerHeroItemsNonBoots'):SetX('44s')

							object:GetWidget('selectedPlayerHeroItem96'):SetAlign('right')
							object:GetWidget('selectedPlayerHeroItem96'):SetX('-101s')
							
						else
							targPad = libGeneral.HtoP(-7.75)
							object:GetWidget('selectedPlayerHeroItems'):SetX(libGeneral.HtoP(-2.35))
							object:GetWidget('selectedPlayerHeroItemsBG'):SetHFlip(true)
							object:GetWidget('selectedPlayerHeroItemsBG'):SetX('2s')
							object:GetWidget('selectedPlayerHeroItemsBG'):SetAlign('right')
							object:GetWidget('selectedPlayerHeroExtraInfo'):SetX(libGeneral.HtoP(1.25))
							floatItemSlots(object, true)
							object:GetWidget('selectedPlayerHeroItemsNonBoots'):SetX('44s')
							
							object:GetWidget('selectedPlayerHeroItem96'):SetAlign('right')
							object:GetWidget('selectedPlayerHeroItem96'):SetX('-101s')
						end
					else
						if LuaTrigger.GetTrigger('Team').team == 2 then
							targPad = libGeneral.HtoP(7.0)
							object:GetWidget('selectedPlayerHeroItems'):SetX(libGeneral.HtoP(3))
							object:GetWidget('selectedPlayerHeroItemsBG'):SetHFlip(false)
							object:GetWidget('selectedPlayerHeroItemsBG'):SetX('-2s')
							object:GetWidget('selectedPlayerHeroItemsBG'):SetAlign('left')	
							object:GetWidget('selectedPlayerHeroExtraInfo'):SetX(0)
							floatItemSlots(object)
							object:GetWidget('selectedPlayerHeroItemsNonBoots'):SetX('8s')
							
							object:GetWidget('selectedPlayerHeroItem96'):SetAlign('left')
							object:GetWidget('selectedPlayerHeroItem96'):SetX('101s')
							

						else
							targPad = libGeneral.HtoP(7.0)
							object:GetWidget('selectedPlayerHeroItems'):SetX(libGeneral.HtoP(3))
							object:GetWidget('selectedPlayerHeroItemsBG'):SetHFlip(false)
							object:GetWidget('selectedPlayerHeroItemsBG'):SetX('-2s')
							object:GetWidget('selectedPlayerHeroItemsBG'):SetAlign('left')	
							object:GetWidget('selectedPlayerHeroExtraInfo'):SetX(0)
							floatItemSlots(object)
							object:GetWidget('selectedPlayerHeroItemsNonBoots'):SetX('8s')
							
							object:GetWidget('selectedPlayerHeroItem96'):SetAlign('left')
							object:GetWidget('selectedPlayerHeroItem96'):SetX('101s')
						end
					end
				end

				local infoBarsAlly	= gameGetWidget('playerInfoBarsAlly')
				local infoBarsEnemy	= gameGetWidget('playerInfoBarsEnemy')
				
				local leftBar	= infoBarsAlly
				local rightBar	= infoBarsEnemy
				
				if leftBar:GetAbsoluteX() > rightBar:GetAbsoluteX() then
					leftBar		= infoBarsEnemy
					rightBar	= infoBarsAlly
				end
				
				local minX	= leftBar:GetAbsoluteX()
				local maxX	= rightBar:GetAbsoluteX() + rightBar:GetWidth() - container:GetWidth()
				
				targX = targX + targPad
				
				local xPos = targX
				
				-- this no-longer fits
				-- local xPos = math.max(math.min(targX, maxX), minX)

				container:SetX(xPos) -- styles_uiSpaceShiftTime

			end)
		
		else
			print('no frame!!! '..tostring(unitFrame)..'\n')
		end
		
		if triggerName then
		
			local scoreTrigger	= LuaTrigger.GetTrigger(triggerName)
			local triggerGPM
			if triggerName ~= gpmTrigger then
				triggerGPM = LuaTrigger.GetTrigger(gpmTrigger)
			else
				triggerGPM = scoreTrigger
			end
			
			killLabel:SetText(scoreTrigger[killParam] + scoreTrigger.assists)
			deathLabel:SetText(scoreTrigger[deathParam])
			gpmLabel:SetText(round(triggerGPM[gpmParam]))
		
			killLabel:RegisterWatchLua(triggerName, function(widget, trigger)	-- + Assists
				widget:SetText(trigger[killParam] + trigger.assists)
			end, false, 'selectedPlayerHeroWatch', killParam, 'assists')
			
			deathLabel:RegisterWatchLua(triggerName, function(widget, trigger)	-- + Assists
				widget:SetText(trigger[deathParam])
			end, false, 'selectedPlayerHeroWatch', deathParam)
			
			gpmLabel:RegisterWatchLua(gpmTrigger, function(widget, trigger)
				widget:SetText(round(trigger[gpmParam]))
			end, false, 'selectedPlayerHeroWatch', gpmParam)
		end
	
	end
end


local function selectedPlayerHeroRegister(object)
	local healthPerPip	= 500
	local widgetVisible	= false

	LuaTrigger.CreateGroupTrigger('selectedUnit0Vis', { 'SelectedUnit.playerSlot', 'SelectedUnit.isHero', 'SelectedUnits0.isVisible', 'ModifierKeyStatus.moreInfoKey' })

	object:GetWidget('selectedPlayerHero'):RegisterWatchLua('selectedUnit0Vis', function(widget, groupTrigger)
	
		local triggerUnit	= groupTrigger['SelectedUnit']
		local triggerUnits0	= groupTrigger['SelectedUnits0']
		local moreInfoKey	= groupTrigger['ModifierKeyStatus'].moreInfoKey
	
		local playerSlot	= triggerUnit.playerSlot
		local isHero		= triggerUnit.isHero
		local showWidget	= (playerSlot and playerSlot >= 0 and isHero and triggerUnits0.isVisible)

		local heroInfoPin 	= GetWidget('gameHeroInfoPin', 'game')
		
		if (showWidget) and (playerSlot == 0) then	
			if not widgetVisible then
				heroInfoPin:SlideY(libGeneral.HtoP(11.75), styles_uiSpaceShiftTime, true)
			else
				heroInfoPin:SetY(libGeneral.HtoP(11.75))
			end
		else	
			heroInfoPin:SlideY(libGeneral.HtoP(3), styles_uiSpaceShiftTime, true)
		end		
		
		if showWidget then
			if not widgetVisible then
				widget:SetVisible(false)
				widget:FadeIn(styles_uiSpaceShiftTime)
				
				widget:SetY(libGeneral.HtoP(-2))
				widget:SlideY(libGeneral.HtoP(8), styles_uiSpaceShiftTime)

				widgetVisible = true
			else
				widget:SetVisible(true)
				widget:SetY(libGeneral.HtoP(8))

			end

		else
			widgetVisible = false
			widget:FadeOut(styles_uiSpaceShiftTime)
			widget:SlideY(libGeneral.HtoP(-2), styles_uiSpaceShiftTime)
		end
		
	end)

	object:GetWidget('selectedPlayerHero'):RegisterWatchLua('SelectedUnits0', function(widget, trigger)
		selectedPlayerHeroUnregisterSlot(widget)
		selectedPlayerHeroRegisterSlot(object, trigger.index)
	end, false, nil, 'index')
	
	object:GetWidget('selectedPlayerHeroPower'):RegisterWatchLua('SelectedUnit', function(widget, trigger)
		widget:SetText(libNumber.round(trigger.power, 0))
	end, false, nil, 'power')
	
	object:GetWidget('selectedPlayerHeroDamage'):RegisterWatchLua('SelectedUnit', function(widget, trigger)
		widget:SetText(math.floor(trigger.damage))
	end, false, nil, 'damage')	-- rmm dps
	
	object:GetWidget('selectedPlayerHeroMitigation'):RegisterWatchLua('SelectedUnit', function(widget, trigger)
		widget:SetText(libNumber.round(trigger.mitigation,1))
	end, false, nil, 'mitigation')
	
	object:GetWidget('selectedPlayerHeroResistance'):RegisterWatchLua('SelectedUnit', function(widget, trigger)
		widget:SetText(libNumber.round(trigger.resistance,1))
	end, false, nil, 'resistance')
	
	object:GetWidget('selectedPlayerHeroHealthBar'):RegisterWatchLua('SelectedUnits0', function(widget, trigger)
		widget:SetWidth(ToPercent(trigger.healthPercent))
	end, false, nil, 'healthPercent')
	
	object:GetWidget('selectedPlayerHeroManaBar'):RegisterWatchLua('SelectedUnits0', function(widget, trigger)
		widget:SetWidth(ToPercent(trigger.manaPercent))
	end, false, nil, 'manaPercent')
	
	object:GetWidget('selectedPlayerHeroHealthMax'):RegisterWatchLua('SelectedUnits0', function(widget, trigger)
		widget:SetText(math.floor(trigger.health))
	end, false, nil, 'health')
	
	object:GetWidget('selectedPlayerHeroManaMax'):RegisterWatchLua('SelectedUnits0', function(widget, trigger)
		widget:SetText(math.floor(trigger.mana))
	end, false, nil, 'mana')

	object:GetWidget('selectedPlayerHeroHealthPips'):RegisterWatchLua('SelectedUnits0', function(widget, trigger)
		local healthMax	= trigger.healthMax
		if healthMax > 4500 then
			widget:SetTexture('/ui/game/alt_info/bar_segment_big_8.tga')
		elseif healthMax >= 3500 then
			widget:SetTexture('/ui/game/alt_info/bar_segment_big_16.tga')
		elseif healthMax > 1500 then
			widget:SetTexture('/ui/game/alt_info/bar_segment_big_32.tga')
		else
			widget:SetTexture('/ui/game/alt_info/bar_segment_big_128.tga')
		end
		widget:SetUScale(500 / healthMax)
	end, false, nil, 'healthMax')
	
	
	object:GetWidget('selectedPlayerHeroExtraInfo'):RegisterWatchLua('ModifierKeyStatus', function(widget, trigger) widget:SetVisible(trigger.moreInfoKey) end, false, nil, 'moreInfoKey')
	
	for i=96,102,1 do
		selectedPlayerHeroRegisterItem(object, i)
	end
	
	--[[
	object:GetWidget('selectedPlayerHeroClose'):SetCallback('onclick', function(widget)
		widget:UICmd("SelectUnit(-1)")
	end)
	--]]
	
end

selectedPlayerHeroRegister(object)