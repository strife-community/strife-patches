---------------------------------------------------------- 		
--  Copyright 2013 S2 Games								--
----------------------------------------------------------

--[[
	Pick Hero
		My Builds
		
			Items
			Abilities
			
			Save, Set as default, (Publish?)
			
		Browse Builds
			
			Subscribe
			Set as default
			(Other builds by this submitter?)
	
	Crafted Item Backpacks
		Link Item backpack to heroes
		Global item backpack (show for all heroes)
--]]



local tinsert = table.insert
local GetTrigger = LuaTrigger.GetTrigger
local triggerStatus = LuaTrigger.GetTrigger('selection_Status')
local mainBuildEditor = LuaTrigger.GetTrigger('mainBuildEditor')
local interface = object
local buildEditorBuildTable = {}
local buildEditorItemBuildTable = {}

local buildEditorStatus = LuaTrigger.CreateCustomTrigger('buildEditorStatus',
	{
		{ name	= 'draggedAbilityIndex',		type	= 'number' },
		{ name	= 'draggedSlotIndex',			type	= 'number' },
		{ name	= 'draggedItemSlotIndex',		type	= 'number' },
		{ name	= 'AbilityPointsRemaining1',	type	= 'number' },
		{ name	= 'AbilityPointsRemaining2',	type	= 'number' },
		{ name	= 'AbilityPointsRemaining3',	type	= 'number' },
		{ name	= 'AbilityPointsRemaining4',	type	= 'number' },
		{ name	= 'currentBuildModified',		type	= 'boolean' },
		{ name	= 'editingBuild',				type	= 'boolean' },
		{ name	= 'webRequestPending',			type	= 'boolean' },
		
	}
)

Builds = {}
buildEditorStatus.currentBuildModified			= false
buildEditorStatus.webRequestPending				= false
buildEditorStatus.editingBuild					= false

mainUI.Selection = mainUI.Selection or {}
mainUI.Selection.lastHeroRetrieved = nil
mainUI.Selection.buildInfoTables = nil
mainUI.Selection.abilitiesBuildTables = nil
mainUI.Selection.craftedItemsBuildTables = nil
mainUI.Selection.itemsBuildTables = nil

local loadedLastBuild = false

local function ResetBuild()
	buildEditorBuildTable = {}
	buildEditorItemBuildTable = {}
	buildEditorStatus.AbilityPointsRemaining1 		= 4
	buildEditorStatus.AbilityPointsRemaining2 		= 4
	buildEditorStatus.AbilityPointsRemaining3 		= 4
	buildEditorStatus.AbilityPointsRemaining4 		= 3
	buildEditorStatus.draggedSlotIndex = -1
	buildEditorStatus.draggedAbilityIndex = -1
	buildEditorStatus.draggedItemSlotIndex = -1
end
ResetBuild()

local canLevelAbilityTable
local function UpdateCanLevelAbilityTable()
	
	canLevelAbilityTable = {
		[0] = {
			{requiredLevel = 7, isSpent = false},
			{requiredLevel = 5, isSpent = false},
			{requiredLevel = 3, isSpent = false},
			{requiredLevel = 1, isSpent = false},
			},
		[1] = {
			{requiredLevel = 7, isSpent = false},
			{requiredLevel = 5, isSpent = false},
			{requiredLevel = 3, isSpent = false},
			{requiredLevel = 1, isSpent = false},
			},
		[2] = {
			{requiredLevel = 7, isSpent = false},
			{requiredLevel = 5, isSpent = false},
			{requiredLevel = 3, isSpent = false},
			{requiredLevel = 1, isSpent = false},
			},
		[3] = {
			{requiredLevel = 15, isSpent = false},
			{requiredLevel = 11, isSpent = false},
			{requiredLevel = 6,  isSpent = false},
			},		
	}			

	for slotIndex, buildAbilityIndex in pairs(buildEditorBuildTable) do
		if (canLevelAbilityTable[buildAbilityIndex]) then
			for abilityIndex2, abilityTable2 in ipairs(canLevelAbilityTable[buildAbilityIndex]) do
				if (abilityTable2) and (not abilityTable2.isSpent) and (slotIndex >= abilityTable2.requiredLevel) then
					abilityTable2.isSpent = true	
					break
				end
			end
		else
			println('^r buildAbilityIndex has no canLevelAbilityTable ' .. buildAbilityIndex)
		end
	end
end

local function CanLevelSlot(levelSlot, abilityIndex)
	
	if (not canLevelAbilityTable) then
		UpdateCanLevelAbilityTable()
	end
	
	if (abilityIndex >= 0) then

		for abilityIndex2, abilityTable2 in ipairs(canLevelAbilityTable[abilityIndex]) do 
			if (abilityTable2) and ((not abilityTable2.isSpent) or (buildEditorStatus.draggedSlotIndex == levelSlot)) and (abilityTable2.requiredLevel <= levelSlot) then
				return true
			end
		end
	end
	return false
end

local function UpdateBuild(heroEntityName, webRequestPending)
	if (heroEntityName) then
		mainBuildEditor.buildHeroEntity = heroEntityName
	end

	buildEditorStatus.AbilityPointsRemaining1 		= 4
	buildEditorStatus.AbilityPointsRemaining2 		= 4
	buildEditorStatus.AbilityPointsRemaining3 		= 4
	buildEditorStatus.AbilityPointsRemaining4 		= 3	
	
	local countAbilities = 0
	for index, value in pairs(buildEditorBuildTable) do
		countAbilities = countAbilities + 1
		if (value == 3) then
			buildEditorStatus.AbilityPointsRemaining4 = buildEditorStatus.AbilityPointsRemaining4 - 1
		elseif (value == 2) then
			buildEditorStatus.AbilityPointsRemaining3 = buildEditorStatus.AbilityPointsRemaining3 - 1
		elseif (value == 1) then	
			buildEditorStatus.AbilityPointsRemaining2 = buildEditorStatus.AbilityPointsRemaining2 - 1
		elseif (value == 0) then
			buildEditorStatus.AbilityPointsRemaining1 = buildEditorStatus.AbilityPointsRemaining1 - 1
		end
		GetWidget('buildEditorSlot' .. index .. 'Button'):SetEnabled(value and (value >= 0))
	end
	
	local countItems = 0
	for index, value in pairs(buildEditorItemBuildTable) do	
		countItems = countItems + 1
	end
	--[[
	if (buildEditorStatus.currentBuildModified) then
		GetWidget('build_editor_ability_frame'):SetBorderColor((countAbilities == 15 and "invisible") or "1 0 0 0.6")
		GetWidget('build_editor_item_frame')   :SetBorderColor((countItems      >  0 and "invisible") or "1 0 0 0.6")
	end
	]]
	GetWidget('main_build_editor_save_btn'):SetEnabled( (countAbilities == 15 and (countItems > 0 --[[or (countAbilities == 0)--]])) and (not webRequestPending))
	
	GetWidget('build_editor_item_clear'):SetEnabled(countItems > 0 and not webRequestPending)
	GetWidget('build_editor_ability_clear'):SetEnabled(countAbilities > 0 and not webRequestPending)
	
	fadeWidget(GetWidget('main_build_editor_itemContainer2'), countItems >= 8)
	
end

local function UpdateAbilitySlot(sourceWidget, abilitySlotIndex, draggedAbilityIndex, clearSlot, dontValidate)
	local abilitySlotIndex = tonumber(abilitySlotIndex)
	if (clearSlot) then
		buildEditorBuildTable[abilitySlotIndex] = nil
		UpdateCanLevelAbilityTable()
		sourceWidget:SetTexture('/ui/shared/textures/drag_target.tga')
		sourceWidget:SetWidth('32s')
		sourceWidget:SetHeight('32s')
		sourceWidget:SetRenderMode('grayscale')
		sourceWidget:SetColor('1 1 1 .2')
		UpdateBuild(nil, false)
		return false
	else
		if CanLevelSlot(abilitySlotIndex, draggedAbilityIndex) or (dontValidate) then
			buildEditorBuildTable[abilitySlotIndex] = draggedAbilityIndex
			UpdateCanLevelAbilityTable()
			local triggerIcon = LuaTrigger.GetTrigger('HeroSelectHeroList' .. mainBuildEditor.buildHero)
			if (triggerIcon) then
				local iconPath = triggerIcon['ability' .. (draggedAbilityIndex) .. 'IconPath']
				if (iconPath) and (not Empty(iconPath)) then
					sourceWidget:SetTexture(iconPath)
					sourceWidget:SetWidth('100@')
					sourceWidget:SetHeight('100%')
					sourceWidget:SetRenderMode('normal')
					sourceWidget:SetColor('1 1 1 1')
					UpdateBuild(nil, false)
				end
			end
			return draggedAbilityIndex
		else
			return false
		end
	end
end

local function SetModified()
	if not buildEditorStatus.currentBuildModified and 
	  not (mainBuildEditor.buildNumber == 1 or (loadedLastBuild and mainBuildEditor.buildNumber == #mainUI.Selection.buildInfoTables)) then 
		buildEditorStatus.editingBuild = true
	end
	buildEditorStatus.currentBuildModified = true
	buildEditorStatus:Trigger(false)
end

local function AbilityRegister(index, abilityIndex, triggerName)
	local Icon			=	GetWidget('buildEditor' .. index .. 'Icon')
	local DropTarget	=	GetWidget('buildEditor' .. index .. 'DropTarget')
	local Button		=	GetWidget('buildEditor' .. index .. 'Button')
	local Hotkey		=	GetWidget('buildEditor' .. index .. 'Hotkey')

	Icon:RegisterWatchLua('mainBuildEditor', function(widget, trigger)
		local infoTrigger = LuaTrigger.GetTrigger(triggerName .. trigger.buildHero)
		if (infoTrigger) then
			local iconPath = infoTrigger['ability'..index..'IconPath']
			if (iconPath) and (string.len(iconPath) > 0) then
				widget:SetTexture(iconPath)
			else
				widget:SetTexture('/ui/shared/textures/pack2.tga')
			end
		end
	end, false, nil, 'buildHero')	
	
	local levelPip
	for levelPipIndex = 1,4,1 do
		levelPip		=	GetWidget('buildEditor' .. index .. 'LevelPip' .. levelPipIndex)
		levelPip:RegisterWatchLua('buildEditorStatus', function(widget, trigger)
			widget:SetVisible(trigger['AbilityPointsRemaining' .. abilityIndex] >= levelPipIndex)
		end, false, nil, 'AbilityPointsRemaining'..abilityIndex)
	end
	
	Hotkey:RegisterWatchLua('mainBuildEditor', function(widget, trigger)
		widget:SetText((GetKeybindButton('game', 'ActivateTool', index, 0) or '?'))
	end, false, nil, 'buildHero')
	
	Button:RegisterWatchLua('buildEditorStatus', function(widget, trigger)
		local remainingPoints = trigger['AbilityPointsRemaining' .. abilityIndex]
		widget:SetEnabled(remainingPoints > 0)
		Icon:SetRenderMode((remainingPoints == 0 and 'grayscale') or 'normal')
	end, false, nil, 'AbilityPointsRemaining'..abilityIndex)	
	
	Button:SetCallback('onmouseover', function(widget)
		Trigger('abilityTipShow', 'HeroSelectHeroList', mainBuildEditor.buildHero, abilityIndex-1, "1")
	end)	
	
	Button:SetCallback('onmouseout', function(widget)
		Trigger('abilityTipHide')
	end)	
	
	DropTarget:RegisterWatchLua('globalDragInfo', function(widget, trigger)
		widget:SetVisible(trigger.active and trigger.type == 7)
	end, false, nil, 'active', 'type')

	DropTarget:SetCallback('onmouseover', function(widget)
		globalDraggerReadTarget(widget, function()
			if (buildEditorStatus.draggedSlotIndex >= 0) then
				local slotIcon			=	GetWidget('buildEditorSlot' .. buildEditorStatus.draggedSlotIndex .. 'Icon')
				UpdateAbilitySlot(slotIcon, buildEditorStatus.draggedSlotIndex, -1, true, nil)
				buildEditorStatus.draggedSlotIndex = -1
			end
			UpdateBuild(nil, false)
			SetModified()
		end)
	end)	
	
	Button:SetCallback('onclick', function(widget)
		for slotNumber = 1, 15 do
			if not buildEditorBuildTable[slotNumber] and CanLevelSlot(slotNumber, abilityIndex-1) then
				slotIcon = GetWidget('buildEditorSlot' .. slotNumber .. 'Icon')
				UpdateAbilitySlot(slotIcon, slotNumber, abilityIndex-1, false, nil)
				UpdateBuild(nil, false)
				SetModified()	
				return
			end
		end
	end)

	Button:SetCallback('onrightclick', function(widget) --this doesn't work when all levels have been placed, as the button is disabled.
		for slotNumber = 15, 1,-1 do
			if buildEditorBuildTable[slotNumber] == abilityIndex-1 then
				slotIcon = GetWidget('buildEditorSlot' .. slotNumber .. 'Icon')
				UpdateAbilitySlot(slotIcon, slotNumber, nil, true, nil)
				UpdateBuild(nil, false)
				SetModified()
				return
			end
		end
	end)	
	
	Button:SetCallback('onenddrag', function(widget)	
	end)	
	
	Button:SetCallback('onstartdrag', function(widget)
		buildEditorStatus.draggedAbilityIndex = index
		buildEditorStatus.draggedSlotIndex = -1
		widget:GetParent():GetParent():GetParent():BringToFront()
		widget:GetParent():GetParent():BringToFront()			
	end)	
	
	globalDraggerRegisterSource(Button, 7, 'mainDragLayer')
end

local function AbililtySlotRegister(index)
	local Icon			=	GetWidget('buildEditorSlot' .. index .. 'Icon')
	local DropTarget	=	GetWidget('buildEditorSlot' .. index .. 'DropTarget')
	local Button		=	GetWidget('buildEditorSlot' .. index .. 'Button')
	local Label			=	GetWidget('buildEditorSlot' .. index .. 'Label')
	
	Label:SetText(Translate('general_lvl_short', 'value', index))
	
	Button:SetCallback('onmouseover', function(widget)
		if (buildEditorBuildTable[index]) then
			Trigger('abilityTipShow', 'HeroSelectHeroList', mainBuildEditor.buildHero, buildEditorBuildTable[index], "1")
		end
	end)

	Button:SetCallback('onmouseout', function(widget)
		Trigger('abilityTipHide')
	end)	
	
	DropTarget:RegisterWatchLua('globalDragInfo', function(widget, trigger)
		widget:SetVisible(trigger.active and trigger.type == 7 and CanLevelSlot(index, buildEditorStatus.draggedAbilityIndex))
	end, false, nil, 'active', 'type')

	DropTarget:SetCallback('onmouseover', function(widget)
		globalDraggerReadTarget(widget, function()
			if (buildEditorStatus.draggedAbilityIndex >= 0) then
				UpdateAbilitySlot(Icon, index, buildEditorStatus.draggedAbilityIndex, false, nil)	
			end
			if (buildEditorStatus.draggedSlotIndex >= 0 and buildEditorStatus.draggedSlotIndex ~= index) then
				UpdateAbilitySlot(GetWidget('buildEditorSlot' .. buildEditorStatus.draggedSlotIndex .. 'Icon'), buildEditorStatus.draggedSlotIndex, -1, true, nil)
			end			
			buildEditorStatus.draggedSlotIndex = -1
			UpdateBuild(nil, false)
			SetModified()
		end)
	end)	

	Button:SetCallback('onrightclick', function(widget)	
		local slotIcon			=	GetWidget('buildEditorSlot' .. index .. 'Icon')
		UpdateAbilitySlot(slotIcon, index, -1, true, nil)
		buildEditorStatus.draggedSlotIndex = -1
		UpdateBuild(nil, false)
		Trigger('abilityTipHide')
		SetModified()		
	end)	

	Button:SetCallback('onstartdrag', function(widget)
		buildEditorStatus.currentBuildModified = true
		widget:GetParent():GetParent():GetParent():BringToFront()
		widget:GetParent():GetParent():BringToFront()	
		buildEditorStatus.draggedSlotIndex = index
		buildEditorStatus.draggedAbilityIndex = buildEditorBuildTable[index] or -1
		buildEditorStatus:Trigger(false)
		
		buildEditorBuildTable[index] = nil
		UpdateCanLevelAbilityTable()
		UpdateBuild(nil, false)
		
	end)	

	Button:SetCallback('onenddrag', function(widget)
		local slotIcon			=	GetWidget('buildEditorSlot' .. index .. 'Icon')
		UpdateAbilitySlot(slotIcon, index, -1, true, nil)
		buildEditorStatus:Trigger(false)
	end)	

	globalDraggerRegisterSource(Button, 7, 'mainDragLayer')
	
end


local function UpdateItemSlot(sourceWidget, entityName, itemSlotIndex, clearSlot)
	if (itemSlotIndex < 1 or itemSlotIndex > 15) then
		return
	end
	if (clearSlot) then
		buildEditorItemBuildTable[itemSlotIndex] = nil
		sourceWidget:SetTexture('/ui/shared/textures/pack.tga')
		sourceWidget:SetWidth('80@')
		sourceWidget:SetHeight('80%')
		sourceWidget:SetRenderMode('grayscale')
		UpdateBuild(nil, false)
		return false
	else
		buildEditorItemBuildTable[itemSlotIndex] = entityName 
		if (entityName) and ValidateEntity(entityName) then
			sourceWidget:SetTexture(GetEntityIconPath(entityName))
			sourceWidget:SetWidth('100@')
			sourceWidget:SetHeight('100%')
			sourceWidget:SetRenderMode('normal')
			UpdateBuild(nil, false)
		else
			sourceWidget:SetTexture('/ui/shared/textures/pack.tga')
			sourceWidget:SetWidth('80@')
			sourceWidget:SetHeight('80%')
			sourceWidget:SetRenderMode('grayscale')
			UpdateBuild(nil, false)
		end
	end
end
function buildEditorAddItem(item)
	if (item) and ValidateEntity(item) then
		for i = 1,15 do
			if (not buildEditorItemBuildTable[i]) then
				UpdateItemSlot(GetWidget('build_editor_item_slot_' .. i .. 'Icon'), item, i, false)
				UpdateBuild(nil, false)
				buildEditorStatus.draggedItemSlotIndex = -1
				SetModified()
				return
			end
		end	
	end
end
function buildEditorRemoveItem(item)
	if (item) and ValidateEntity(item) then
		for i = 15,1,-1 do
			if (buildEditorItemBuildTable[i] == item) then
				UpdateItemSlot(GetWidget('build_editor_item_slot_' .. i .. 'Icon'), nil, i, true)
				UpdateBuild(nil, false)
				SetModified()	
				return
			end
		end	
	end
end

-- Clearing buttons
-- items
object:GetWidget('build_editor_item_clear'):SetCallback('onclick', function(widget)
	for i = 15,1,-1 do
		UpdateItemSlot(GetWidget('build_editor_item_slot_' .. i .. 'Icon'), nil, i, true)
	end
	UpdateBuild(nil, false)
	SetModified()
end)

-- abilities
object:GetWidget('build_editor_ability_clear'):SetCallback('onclick', function(widget)
	for i = 15,1,-1 do
		UpdateAbilitySlot(GetWidget('buildEditorSlot' .. i .. 'Icon'), i, i, true, nil)
	end
	UpdateBuild(nil, false)
	SetModified()
end)

local function ItemSlotRegister(index)
	local Icon			=	GetWidget('build_editor_item_slot_' .. index .. 'Icon')
	local DropTarget	=	GetWidget('build_editor_item_slot_' .. index .. 'DropTarget')
	local Button		=	GetWidget('build_editor_item_slot_' .. index .. 'Button')
	
	Button:SetCallback('onmouseover', function(widget)
		UpdateCursor(widget, true, { canLeftClick = true, canRightClick = true, canDrag = true })
	end)	
	
	Button:SetCallback('onmouseout', function(widget)
		UpdateCursor(widget, false, { canLeftClick = true, canRightClick = true, canDrag = true })
	end)	
	
	DropTarget:RegisterWatchLua('globalDragInfo', function(widget, trigger)
		widget:SetVisible(trigger.active and (trigger.type == 4))
	end, false, nil, 'active', 'type')

	DropTarget:SetCallback('onmouseover', function(widget)
		globalDraggerReadTarget(widget, function()
			if (trigger_gamePanelInfo.shopDraggedItem) and ValidateEntity(trigger_gamePanelInfo.shopDraggedItem) then

				UpdateItemSlot(GetWidget('build_editor_item_slot_' .. index .. 'Icon'), trigger_gamePanelInfo.shopDraggedItem, index, false)	
				if (buildEditorStatus.draggedItemSlotIndex > 0) then
					UpdateItemSlot(GetWidget('build_editor_item_slot_' .. buildEditorStatus.draggedItemSlotIndex .. 'Icon'), trigger_gamePanelInfo.shopDraggedItem, buildEditorStatus.draggedItemSlotIndex, true)	
				end
				UpdateBuild(nil, false)
				buildEditorStatus.draggedItemSlotIndex = -1
				SetModified()
			end
		end)
	end)	
	
	Button:SetCallback('onstartdrag', function(widget)
		widget:GetParent():GetParent():GetParent():BringToFront()
		widget:GetParent():GetParent():BringToFront()
		widget:GetParent():BringToFront()
		trigger_gamePanelInfo.shopDraggedItem = buildEditorItemBuildTable[index] or -1
		buildEditorStatus.draggedItemSlotIndex = index
		buildEditorStatus:Trigger(false)				
	end)	
	
	Button:SetCallback('onrightclick', function(widget)		
		UpdateItemSlot(GetWidget('build_editor_item_slot_' .. index .. 'Icon'), trigger_gamePanelInfo.shopDraggedItem, index, true)
		SetModified()
	end)	

	globalDraggerRegisterSource(Button, 4, 'mainDragLayer')		
	
end


local function UpdateBuildEditorWidgets()

	local selection_builds_combobox_auto_btn_1 	= GetWidget('selection_builds_combobox_auto_btn_1')
	local selection_builds_combobox_auto_btn_2 	= GetWidget('selection_builds_combobox_auto_btn_2')
	local main_build_editor_combobox 			= GetWidget('main_build_editor_combobox')
	local selection_builds_combobox 			= GetWidget('main_pregame_customization_builds_combobox')
	
	selection_builds_combobox_auto_btn_1:SetCallback('onshow', function(widget)
		if (triggerStatus.enableAutoBuild) then
			GetWidget('selection_builds_combobox_auto_btn_1Check'):SetVisible(1)
			--widget:SetButtonState(1)
		else
			GetWidget('selection_builds_combobox_auto_btn_1Check'):SetVisible(0)
			--widget:SetButtonState(0)
		end	
	end)
	
	selection_builds_combobox_auto_btn_1:RegisterWatchLua('selection_Status', function(widget, trigger)
		if (triggerStatus.enableAutoBuild) then
			GetWidget('selection_builds_combobox_auto_btn_1Check'):SetVisible(1)
			--widget:SetButtonState(1)
		else
			GetWidget('selection_builds_combobox_auto_btn_1Check'):SetVisible(0)
			--widget:SetButtonState(0)
		end	
	end)	
	
	selection_builds_combobox_auto_btn_1:SetCallback('onclick', function(widget)
		triggerStatus.enableAutoBuild = (not triggerStatus.enableAutoBuild)
		triggerStatus:Trigger(false)
		
		if triggerStatus.enableAutoBuild then
			-- sound_autoItemsChecked
			PlaySound('ui/sounds/sfx_button_generic.wav')
		else
			-- sound_autoItemsUnchecked
			PlaySound('ui/sounds/sfx_button_generic.wav')
		end
		
		local heroEntity = LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo').heroEntityName
		if (heroEntity) then
			mainUI.savedRemotely.heroBuilds = mainUI.savedRemotely.heroBuilds or {}
			mainUI.savedRemotely.heroBuilds[heroEntity] 					= mainUI.savedRemotely.heroBuilds[heroEntity] or {}
			mainUI.savedRemotely.heroBuilds[heroEntity].enableAutoBuild 	= triggerStatus.enableAutoBuild
		end			
		SaveState()
	end)				

	selection_builds_combobox_auto_btn_1:SetCallback('onmouseover', function(widget)
		UpdateCursor(widget, true, { canLeftClick = true, canRightClick = false, canDrag = false })
		simpleTipGrowYUpdate(true, nil, Translate('heroselect_hero_builds_auto'), Translate('heroselect_hero_builds_auto_desc_1'), 250, selection_builds_combobox_auto_btn_1:GetXFromString('30s'))
		if (triggerStatus.enableAutoBuild) then
			GetWidget('selection_builds_combobox_auto_btn_1Check'):SetVisible(1)
			--GetWidget('selection_builds_combobox_auto_btn_1'):SetButtonState(1)
		else
			GetWidget('selection_builds_combobox_auto_btn_1Check'):SetVisible(0)
			--GetWidget('selection_builds_combobox_auto_btn_1'):SetButtonState(0)
		end			
	end)	
	
	selection_builds_combobox_auto_btn_1:SetCallback('onmouseout', function(widget)
		UpdateCursor(widget, false, { canLeftClick = true, canRightClick = false, canDrag = false })
		simpleTipGrowYUpdate(false)
	end)	
	
	selection_builds_combobox_auto_btn_2:SetCallback('onshow', function(widget)
		if (triggerStatus.enableAutoAbilities) then
			GetWidget('selection_builds_combobox_auto_btn_2Check'):SetVisible(1)
			--widget:SetButtonState(1)
		else
			GetWidget('selection_builds_combobox_auto_btn_2Check'):SetVisible(0)
			--widget:SetButtonState(0)
		end	
	end)	
	
	selection_builds_combobox_auto_btn_2:RegisterWatchLua('selection_Status', function(widget, trigger)
		if (triggerStatus.enableAutoAbilities) then
			GetWidget('selection_builds_combobox_auto_btn_2Check'):SetVisible(1)
			--widget:SetButtonState(1)
		else
			GetWidget('selection_builds_combobox_auto_btn_2Check'):SetVisible(0)
			--widget:SetButtonState(0)
		end	
	end)	
	
	selection_builds_combobox_auto_btn_2:SetCallback('onclick', function(widget)
		triggerStatus.enableAutoAbilities = (not triggerStatus.enableAutoAbilities)
		triggerStatus:Trigger(false)
		
		if triggerStatus.enableAutoAbilities then
			-- sound_autoAbilitiesChecked
			-- PlaySound('/path_to/filename.wav')
		else
			-- sound_autoAbilitiesUnchecked
			-- PlaySound('/path_to/filename.wav')
		end
		
		local heroEntity = LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo').heroEntityName
		if (heroEntity) then
			mainUI.savedRemotely.heroBuilds = mainUI.savedRemotely.heroBuilds or {}
			mainUI.savedRemotely.heroBuilds[heroEntity] 						= mainUI.savedRemotely.heroBuilds[heroEntity] or {}
			mainUI.savedRemotely.heroBuilds[heroEntity].enableAutoAbilities 	= triggerStatus.enableAutoAbilities
		end			
		SaveState()
	end)				

	selection_builds_combobox_auto_btn_2:SetCallback('onmouseover', function(widget)
		UpdateCursor(widget, true, { canLeftClick = true, canRightClick = false, canDrag = false })
		simpleTipGrowYUpdate(true, nil, Translate('heroselect_hero_builds_auto'), Translate('heroselect_hero_builds_auto_desc_2'), 250, selection_builds_combobox_auto_btn_2:GetXFromString('30s'))
		if (triggerStatus.enableAutoAbilities) then
			GetWidget('selection_builds_combobox_auto_btn_2Check'):SetVisible(1)
			--GetWidget('selection_builds_combobox_auto_btn_2'):SetButtonState(1)
		else
			GetWidget('selection_builds_combobox_auto_btn_2Check'):SetVisible(0)
			--GetWidget('selection_builds_combobox_auto_btn_2'):SetButtonState(0)
		end		
	end)	
	
	selection_builds_combobox_auto_btn_2:SetCallback('onmouseout', function(widget)
		UpdateCursor(widget, false, { canLeftClick = true, canRightClick = false, canDrag = false })
		simpleTipGrowYUpdate(false)
	end)	
	
	if (triggerStatus.enableAutoBuild) then
		GetWidget('selection_builds_combobox_auto_btn_1Check'):SetVisible(1)
		--GetWidget('selection_builds_combobox_auto_btn_1'):SetButtonState(1)
	else
		GetWidget('selection_builds_combobox_auto_btn_1Check'):SetVisible(0)
		--GetWidget('selection_builds_combobox_auto_btn_1'):SetButtonState(0)
	end	
	
	if (triggerStatus.enableAutoAbilities) then
		GetWidget('selection_builds_combobox_auto_btn_2Check'):SetVisible(1)
		--GetWidget('selection_builds_combobox_auto_btn_2'):SetButtonState(1)
	else
		GetWidget('selection_builds_combobox_auto_btn_2Check'):SetVisible(0)
		--GetWidget('selection_builds_combobox_auto_btn_2'):SetButtonState(0)
	end
	
	-- Populate in builder 
	local function PopulateBuilderDropdown(widget)
		
		widget:SetCallback('onselect', function()
			local value = widget:GetValue()
			if (value) and tonumber(value) and (tonumber(value) >= 0) then
				mainBuildEditor.buildNumber 	 = tonumber(value)	
				--GetWidget('selection_builds_combobox_auto_btn_1'):SetButtonState(0)
				--GetWidget('selection_builds_combobox_auto_btn_2'):SetButtonState(0)
				mainBuildEditor:Trigger(false)
				
				local heroEntity = LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo').heroEntityName
				if (heroEntity) then
					mainUI.savedRemotely.heroBuilds = mainUI.savedRemotely.heroBuilds or {}
					mainUI.savedRemotely.heroBuilds[heroEntity] 					= mainUI.savedRemotely.heroBuilds[heroEntity] or {}
					mainUI.savedRemotely.heroBuilds[heroEntity].default_build 		= tonumber(value)
				end
				
				UpdateSelectedHeroBuild(mainBuildEditor.buildNumber)
				SaveState()
			end
		end)				

		widget:ClearItems()

		if (mainUI.Selection.buildInfoTables) then
			for index, buildTable in ipairs(mainUI.Selection.buildInfoTables) do
				if (buildTable.name) then
					widget:AddTemplateListItem(style_main_dropdownItem, index, 'label', buildTable.name)
				end
			end
		end		
		
		libThread.threadFunc(function()	
			wait(100)
			widget:SetSelectedItemByValue(mainBuildEditor.buildNumber)
		end)
		widget:RegisterWatchLua('mainBuildEditor', function(widget, trigger)
			libThread.threadFunc(function()	
				wait(100)
				widget:SetSelectedItemByValue(mainBuildEditor.buildNumber)
				UpdateSelectedHeroBuild(mainBuildEditor.buildNumber)
			end)
		end, true, nil, 'buildNumber', 'buildHero')			
		
	end
	PopulateBuilderDropdown(selection_builds_combobox)  -- on play screen
	PopulateBuilderDropdown(main_build_editor_combobox)  -- on build editor screen

end

local function GetHeroIndexFromEntity(entityName)
	for heroIndex = 0, 99, 1 do
		local heroInfo = GetTrigger('HeroSelectHeroList' .. heroIndex)
		if (heroInfo) and (heroInfo.entityName ==  entityName) then
			return heroIndex
		elseif not heroInfo.isValid then
			break
		end
	end
	return -1
end

local function RevertEditorHero()
	mainBuildEditor.buildHeroEntity = LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo').heroEntityName
	mainBuildEditor.buildHero = GetHeroIndexFromEntity(mainBuildEditor.buildHeroEntity)
	mainBuildEditor:Trigger(false)
	
	local heroTrigger	= GetTrigger('HeroSelectHeroList'..mainBuildEditor.buildHero)
	--GetWidget('main_build_editor_popup_hero_role_label'):SetText(heroTrigger['description'] or 'Hero description goes here')
	--GetWidget('main_build_editor_popup_hero_name_label'):SetText(heroTrigger['displayName'] or 'Hero Name Here')
end

local remoteBuild = false

local function closeEditor()
	buildEditorStatus.currentBuildModified = false
	buildEditorStatus.webRequestPending = false
	RevertEditorHero()
	triggerStatus:Trigger(false)
	buildEditorStatus:Trigger(false)
	
	resetTrigger('mainBuildEditor')
	mainBuildEditor:Trigger()

	remoteBuild = false
end

local function SaveHeroBuild()
	mainBuildEditor.buildHeroEntity = LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo').heroEntityName
	mainBuildEditor.buildHero = GetHeroIndexFromEntity(mainBuildEditor.buildHeroEntity)
	if (mainBuildEditor.buildHeroEntity) and (not Empty(mainBuildEditor.buildHeroEntity)) and ValidateEntity(mainBuildEditor.buildHeroEntity) then
		
		local buildName = ''
		local buildDescription = ''
		
		if (not Empty(GetWidget('builds_input_textbox'):GetValue())) then
			buildName = GetWidget('builds_input_textbox'):GetValue()
		else
			buildName = Translate('builds_default_name', 'value', 1)
		end
		
		local abilityEntity
		local abilityBuildTable = {}

		for index, value in pairs(buildEditorBuildTable) do	
			abilityEntity = 'Ability_' .. string.sub(mainBuildEditor.buildHeroEntity, 6) .. value
			tinsert(abilityBuildTable, tostring(abilityEntity))
		end
		
		local itemBuildTable = {}		
		
		for n=1, 15 do
			tinsert(itemBuildTable, tostring((buildEditorItemBuildTable[n] or "")))
		end

		local craftedItemTable = {'nil', 'nil', 'nil', 'nil'}
		
		buildEditorStatus.webRequestPending				= true	
		buildEditorStatus:Trigger(false)		
		
		local successFunction =  function (request)	-- response handler
			local body1 = request:GetBody()
			local error1 = Translate(request:GetError())
			if (error1) and (not Empty(error1)) then	
				buildEditorStatus.currentBuildModified = true
				buildEditorStatus.webRequestPending = false
				buildEditorStatus:Trigger(false)		
				GenericDialogAutoSize(
					'error_web_general', tostring('CreateHeroBuild'), tostring(error1), 'general_ok', '', 
						nil,
						nil
				)
				return nil
			else
				GetWidget('main_build_editor_container'):Sleep(150, function()
					buildEditorStatus.currentBuildModified = false
					buildEditorStatus.webRequestPending = false
					buildEditorStatus:Trigger(false)	
					GetWidget('main_build_editor_container'):Sleep(150, function()
						mainUI.Selection.lastHeroRetrieved = nil
						

						local count = 0
						--select new build
						if (mainBuildEditor.buildHeroEntity == LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo').heroEntityName) then
							for _ in pairs(mainUI.Selection.buildInfoTables) do 
								count = count + 1 
							end
							if (not buildEditorStatus.editingBuild) then 
								count = count + 1 
							end --new build has a new list item

							mainUI.savedRemotely.heroBuilds[mainBuildEditor.buildHeroEntity] = mainUI.savedRemotely.heroBuilds[mainBuildEditor.buildHeroEntity] or {}
							mainUI.savedRemotely.heroBuilds[mainBuildEditor.buildHeroEntity].default_build = count
							mainBuildEditor.buildNumber = count -- Normal
						else
							RevertEditorHero()
						end
						LoadHeroBuilds()
					end)
				end)
			end
		end
		
		local editSuccessFunction =  function (request)	-- response handler
			local body1 = request:GetBody()
			local error1 = Translate(request:GetError())
			if (error1) and (not Empty(error1)) then	
				buildEditorStatus.currentBuildModified = true
				buildEditorStatus.webRequestPending = false
				buildEditorStatus:Trigger(false)		
				GenericDialogAutoSize(
					'error_web_general', tostring('CreateHeroBuild'), tostring(error1), 'general_ok', '', 
						nil,
						nil
				)
				return nil
			else
				GetWidget('main_build_editor_container'):Sleep(150, function()
					buildEditorStatus.currentBuildModified = false
					buildEditorStatus.webRequestPending = false
					buildEditorStatus:Trigger(false)	
					GetWidget('main_build_editor_container'):Sleep(150, function()
						mainUI.Selection.lastHeroRetrieved = nil
						LoadHeroBuilds()
					end)
				end)
			end
		end		
		
		local failFunction =  function (request)
			buildEditorStatus.currentBuildModified = true
			buildEditorStatus.webRequestPending = false
			buildEditorStatus:Trigger(false)		
			SevereError('CreateHeroBuild failed remotely', 'main_reconnect_thatsucks', '', nil, nil, nil)
			return nil
		end		

		if (buildEditorStatus.editingBuild) then
			Strife_Web_Requests:UpdateHeroBuildByIndex(mainUI.Selection.buildInfoTables[tonumber(mainBuildEditor.buildNumber)].buildIncrement, buildName, buildDescription, itemBuildTable, abilityBuildTable, craftedItemTable, editSuccessFunction, failFunction)
		else
			Strife_Web_Requests:CreateHeroBuild(mainBuildEditor.buildHeroEntity, buildName, buildDescription, itemBuildTable, abilityBuildTable, craftedItemTable, successFunction, failFunction)
		end
	
	end

	if (remoteBuild) then
		closeEditor()
	end
end

local function ClearHeroBuild()
	
	for index = 1,15,1 do
		UpdateAbilitySlot(GetWidget('buildEditorSlot' .. index .. 'Icon'), index, index, true, nil)
		UpdateItemSlot(GetWidget('build_editor_item_slot_' .. index .. 'Icon'), index, index, true)
	end

	GetWidget('builds_input_textbox'):SetInputLine('')
	
	buildEditorStatus.currentBuildModified = true
	buildEditorStatus.editingBuild = false
	buildEditorStatus:Trigger(false)
	
	GetWidget('main_build_editor_container'):Sleep(1, function()
		UpdateBuild(nil, false)
		buildEditorStatus:Trigger(false)
	end)
end

function LoadBuildFromLink(buildName, buildHeroName, buildInfoTable, abilitiesBuildTable, itemsBuildTable)
	remoteBuild = true
	ClearHeroBuild()
	
	libThread.threadFunc(function()	
	
		Party.OpenedPlayScreen()
		wait(1)
		
		local triggerPanelStatus			= LuaTrigger.GetTrigger('mainPanelStatus')	
		triggerPanelStatus.main				= mainUI.MainValues.preGame		
		triggerPanelStatus:Trigger(false)
		wait(styles_mainSwapAnimationDuration + 1)	
		
		local mainBuildEditor = LuaTrigger.GetTrigger('mainBuildEditor')
		mainBuildEditor.visible = true
		mainBuildEditor:Trigger()
		wait(1)	
		
		mainBuildEditor.buildHero = GetHeroIndexFromEntity(buildInfoTable.heroEntity)
		mainBuildEditor.buildHeroEntity	= buildInfoTable.heroEntity
		mainBuildEditor:Trigger(false)
		
		buildEditorStatus.editingBuild = false
		buildEditorStatus.currentBuildModified 	= true
		buildEditorStatus:Trigger(false)
		
		if (abilitiesBuildTable) then
			for abilityIndex, abilityEntity in pairs(abilitiesBuildTable) do
				local draggedAbilityIndex
				
				if (abilityEntity) then
					draggedAbilityIndex = (string.sub(abilityEntity, -1))
					abilityEntity = (string.sub(abilityEntity, 1, -2))
					abilityEntity = abilityEntity .. (draggedAbilityIndex + 1)
				end				

				if (abilityEntity) and ValidateEntity(abilityEntity) then
					UpdateAbilitySlot(GetWidget('buildEditorSlot' .. abilityIndex .. 'Icon'), tonumber(abilityIndex), tonumber(draggedAbilityIndex), false, true)
				end
				
			end
		else
			println('abilitiesBuildTable is missing ')
		end

		if (itemsBuildTable) then
			for itemIndex, itemEntity in pairs(itemsBuildTable) do
				if (itemEntity) and ValidateEntity(itemEntity) then
					if tonumber(itemIndex) and (tonumber(itemIndex) > 0) then
						UpdateItemSlot(GetWidget('build_editor_item_slot_' .. (itemIndex) .. 'Icon'), itemEntity, tonumber(itemIndex), false)
					end
				end
			end
		else
			println('itemsBuildTable is missing ')	
		end	

		wait(1)
		
		UpdateBuild(buildInfoTable.heroEntity, false)

		mainUI.Selection.buildInfoTables = buildInfoTable
		if (buildInfoTable) then
			if (buildInfoTable.name) then
				GetWidget('builds_input_textbox'):SetInputLine(buildInfoTable.name)
			end
		else
			println('buildInfoTables is missing ')	
		end	

	end)
end

local lastSelectedBuild
function UpdateSelectedHeroBuild(selectedBuild)
	if (lastSelectedBuild == selectedBuild or remoteBuild) then
		return
	end
	
	lastSelectedBuild = selectedBuild
	
	for index = 1,15,1 do
		UpdateAbilitySlot(GetWidget('buildEditorSlot' .. index .. 'Icon'), index, index, true, nil)
	end

	for index = 1,15,1 do
		UpdateItemSlot(GetWidget('build_editor_item_slot_' .. index .. 'Icon'), index, index, true)
	end		
	
	if (mainUI.Selection.abilitiesBuildTables) then
		if (mainUI.Selection.abilitiesBuildTables[tonumber(selectedBuild)]) then
			for abilityIndex, abilityEntity in pairs(mainUI.Selection.abilitiesBuildTables[tonumber(selectedBuild)]) do
				local draggedAbilityIndex
				
				if (abilityEntity) then
					draggedAbilityIndex = (string.sub(abilityEntity, -1))
					abilityEntity = (string.sub(abilityEntity, 1, -2))
					abilityEntity = abilityEntity .. (draggedAbilityIndex + 1)
				end				
				
				if (abilityEntity) and ValidateEntity(abilityEntity) then
					UpdateAbilitySlot(GetWidget('buildEditorSlot' .. abilityIndex .. 'Icon'), tonumber(abilityIndex), tonumber(draggedAbilityIndex), false, true)
				end
				
			end
		else
			-- println('abilitiesBuildTables no build at this ID ' .. selectedBuild)
		end
	else
		println('abilitiesBuildTables is missing ')
	end

	if (mainUI.Selection.itemsBuildTables) then
		if (mainUI.Selection.itemsBuildTables[tonumber(selectedBuild)]) then
			for itemIndex, itemEntity in pairs(mainUI.Selection.itemsBuildTables[tonumber(selectedBuild)]) do
				if (itemEntity) and ValidateEntity(itemEntity) then
					if tonumber(itemIndex) and tonumber(itemIndex) > 0 and tonumber(itemIndex) <= 15 then
						UpdateItemSlot(GetWidget('build_editor_item_slot_' .. (itemIndex) .. 'Icon'), itemEntity, tonumber(itemIndex), false)
					end
				end
			end
		else
			-- println('itemsBuildTables no build at this ID ' .. selectedBuild)
		end
	else
		println('itemsBuildTables is missing ')	
	end	
	
	if (mainUI.Selection.buildInfoTables) then
		if (mainUI.Selection.buildInfoTables[tonumber(selectedBuild)] and not remoteBuild) then
			if (mainUI.Selection.buildInfoTables[tonumber(selectedBuild)].name) then
				GetWidget('builds_input_textbox'):SetInputLine(mainUI.Selection.buildInfoTables[tonumber(selectedBuild)].name)
			end
		else
			-- println('buildInfoTables no build at this ID ' .. selectedBuild)	
		end
	else
		println('buildInfoTables is missing ')	
	end		

	buildEditorStatus.currentBuildModified = false
	buildEditorStatus:Trigger(true)	
	
	GetWidget('main_build_editor_container'):Sleep(1, function()
		UpdateBuild(nil, false)
		buildEditorStatus:Trigger(false)
	end)
end

function LoadHeroBuilds(object, entityName)
	
	lastSelectedBuild = nil
	mainUI.Selection = mainUI.Selection or {}
	local triggerStatus = LuaTrigger.GetTrigger('selection_Status')
	
	local heroEntity = entityName or LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo').heroEntityName

	if (heroEntity) and (not Empty(heroEntity)) and ((not mainUI.Selection.lastHeroRetrieved) or (mainUI.Selection.lastHeroRetrieved ~= heroEntity)) then

		if ValidateEntity(heroEntity) then

			local buildEditorStatus = LuaTrigger.GetTrigger('buildEditorStatus')
			buildEditorStatus.webRequestPending				= true	
			buildEditorStatus:Trigger(false)
			
			local successFunction =  function (request)	-- response handler
				local responseData = request:GetBody()
				if responseData == nil then
					if (buildEditorStatus) then
						buildEditorStatus.webRequestPending = false
						buildEditorStatus:Trigger(false)
					end
					SevereError('GetHeroBuild - no response data', 'main_reconnect_thatsucks', '', nil, nil, false)
					return nil
				else
					if (buildEditorStatus) then
						buildEditorStatus.webRequestPending = false
						buildEditorStatus:Trigger(false)
					end
					local webHeroBuildTable = responseData
					
					local sortedWebHeroBuildTable = {}
					
					if (webHeroBuildTable) then
						for index = 0, 5, 1 do			
							if (webHeroBuildTable[tostring(index)]) then
								tinsert(sortedWebHeroBuildTable, webHeroBuildTable[tostring(index)])
							end
						end
					end
					
					-- These are split once in-game, so we need to seperate them
					mainUI.Selection.buildInfoTables = {}
					mainUI.Selection.abilitiesBuildTables = {}
					mainUI.Selection.itemsBuildTables = {}
					mainUI.Selection.craftedItemsBuildTables = {}

					-- Add default builds
					local defaultAbilityTable = GetDefaultAbilityBuild(heroEntity)
					local defaultAbilityTable2 = {}
					for i,v in pairs(defaultAbilityTable) do
						if tonumber(string.sub(v, -1)) then
							local newIndex = (tonumber(string.sub(v, -1)) - 1)
							v = string.sub(v, 1, -2)
							v = v .. newIndex
							tinsert(defaultAbilityTable2, v)
						else
							println('^r could not modify ability ' .. tostring(v))
						end
					end
					
					local defaultItemTable = GetDefaultItemBuild(heroEntity)			
					

					tinsert(mainUI.Selection.buildInfoTables, {name = Translate('builds_guide'), description = '', heroEntity = (heroEntity)})
					
					if (defaultAbilityTable2) then
						tinsert(mainUI.Selection.abilitiesBuildTables, defaultAbilityTable2)
					end
					if (defaultItemTable) then
						tinsert(mainUI.Selection.itemsBuildTables, defaultItemTable)
					end
					
					-- Add web builds
					if (sortedWebHeroBuildTable) then
						for index, buildTable in ipairs(sortedWebHeroBuildTable) do
							if (buildTable.name) then
								tinsert(mainUI.Selection.buildInfoTables, {name = buildTable.name, description = buildTable.description, buildIncrement = buildTable.buildIncrement, heroEntity = buildTable.heroEntity})
								
								--abilities are sent with a random order
								local sortedAbilities = {}
								--php sends this with an index of 0, so insert it manually.
								local sortedItems = {}
								for n=1,15 do
									sortedAbilities[n] = buildTable.skills[tostring(n)]
								end
								for n=1,15 do
									sortedItems[n] = buildTable.items[tostring(n-1)]
								end
								tinsert(mainUI.Selection.abilitiesBuildTables, sortedAbilities)
								tinsert(mainUI.Selection.itemsBuildTables, sortedItems)
								
								tinsert(mainUI.Selection.craftedItemsBuildTables, buildTable.craftedItems)
							end
						end
					end
					
					-- Also insert our last games build if it is valid (an item or ability)
					loadedLastBuild = false
					if (mainUI.savedLocally.LastBuild and mainUI.savedLocally.LastBuild[heroEntity]) then -- exists
						local buildTable = mainUI.savedLocally.LastBuild[heroEntity]
						if (#buildTable.Items > 0 or #buildTable.Skills > 0) then
							tinsert(mainUI.Selection.buildInfoTables, {name = Translate('builds_last_build'), description = '', heroEntity = (heroEntity)})
							tinsert(mainUI.Selection.abilitiesBuildTables, buildTable.Skills)
							tinsert(mainUI.Selection.itemsBuildTables, buildTable.Items)
							loadedLastBuild = true
						end
					end
					
					local autoItemsDefault		= true
					local autoAbilitiesDefault	= false
					
					local npeTrigger = LuaTrigger.GetTrigger('newPlayerExperience')
					if (RMM_DONT_AUTO_BUILD_TEMP_HAX) or ( (npeTrigger) and (NPE_PROGRESS_TUTORIALCOMPLETE) and (npeTrigger.tutorialProgress < NPE_PROGRESS_TUTORIALCOMPLETE) ) then
						RMM_DONT_AUTO_BUILD_TEMP_HAX = true
						autoItemsDefault = false
					end
					
					if (mainUI.Selection) and (mainUI.savedRemotely.heroBuilds) and (mainUI.savedRemotely.heroBuilds[heroEntity]) and (mainUI.savedRemotely.heroBuilds[heroEntity].default_build) and (mainUI.savedRemotely.heroBuilds[heroEntity].default_build >= 0) then
						if (mainUI.Selection) and (mainUI.Selection.buildInfoTables) and (mainUI.Selection.buildInfoTables[tonumber(mainUI.savedRemotely.heroBuilds[heroEntity].default_build)]) then
							mainBuildEditor.buildNumber 		= mainUI.savedRemotely.heroBuilds[heroEntity].default_build
						else
							mainBuildEditor.buildNumber 		= 1
							SevereError('Saved default build does not exist, using default 1', 'main_reconnect_thatsucks', '', nil, nil, false)
						end

						if (heroEntity) and ( (heroEntity == 'Hero_CapriceTutorial2') or (heroEntity == 'Hero_CapriceTutorial') ) then
							triggerStatus.enableAutoBuild 		= false
						elseif (not RMM_DONT_AUTO_BUILD_TEMP_HAX) and (mainUI.savedRemotely.heroBuilds[heroEntity].enableAutoBuild ~= nil) then
							triggerStatus.enableAutoBuild 		= mainUI.savedRemotely.heroBuilds[heroEntity].enableAutoBuild
						else
							triggerStatus.enableAutoBuild 		= autoItemsDefault
						end
						if mainUI.savedRemotely.heroBuilds[heroEntity].enableAutoAbilities ~= nil then
							triggerStatus.enableAutoAbilities 	= mainUI.savedRemotely.heroBuilds[heroEntity].enableAutoAbilities
						else
							triggerStatus.enableAutoAbilities 	= autoAbilitiesDefault
						end
					else
						mainBuildEditor.buildNumber 		= 1
						triggerStatus.enableAutoBuild 		= autoItemsDefault
						triggerStatus.enableAutoAbilities 	= autoAbilitiesDefault
					end
					
					mainUI.Selection.lastHeroRetrieved = heroEntity
					
					lastSelectedBuild = nil
					UpdateSelectedHeroBuild(mainBuildEditor.buildNumber)
					
					UpdateBuildEditorWidgets()
					buildEditorStatus:Trigger(true)				
					triggerStatus:Trigger(false)						
					
					return true
				end
			end
				
			local failFunction =  function (request)	-- error handler
				if (buildEditorStatus) then
					buildEditorStatus.webRequestPending = false
					buildEditorStatus:Trigger(false)
				end
				SevereError('GetHeroBuild Request Error: ' .. Translate(request:GetError()), 'main_reconnect_thatsucks', '', nil, nil, false)
				return nil
			end						
			
			Strife_Web_Requests:GetHeroBuild(heroEntity, successFunction, failFunction)
			
		else
			SevereError('LoadHeroBuilds failed to validate entity ' .. tostring(heroEntity), 'main_reconnect_thatsucks', '', nil, nil, nil)
		end			
	end

end

function closeItemBuildEditor()
	if (buildEditorStatus.currentBuildModified) then
		libThread.threadFunc(function()	
			wait(10)
			GenericDialogAutoSize(
				'builds_discard_build', 'builds_undo_build_desc', '', 'general_ok', 'general_cancel', 
				function() --reload current build
					lastSelectedBuild = nil
					UpdateSelectedHeroBuild(mainBuildEditor.buildNumber)
					buildEditorStatus.currentBuildModified = false
					buildEditorStatus:Trigger(false)	
					closeEditor()
				end,
				function()
					PlaySound('/ui/sounds/sfx_ui_back.wav')
				end
			)
		end)
	else
		closeEditor()
	end
end


local function updateControls()
	fadeWidget(GetWidget('main_build_editor_combobox_container'), not buildEditorStatus.currentBuildModified)
	fadeWidget(GetWidget('main_build_editor_edit_btn'), not buildEditorStatus.currentBuildModified)
	fadeWidget(GetWidget('main_build_editor_new_btn'), not buildEditorStatus.currentBuildModified)
	fadeWidget(GetWidget('main_build_editor_share_container'), not buildEditorStatus.currentBuildModified and not (mainBuildEditor.buildNumber == 1 or (loadedLastBuild and mainBuildEditor.buildNumber == #mainUI.Selection.buildInfoTables)))
	fadeWidget(GetWidget('main_build_editor_delete_btn'), not buildEditorStatus.currentBuildModified and not (mainBuildEditor.buildNumber == 1 or (loadedLastBuild and mainBuildEditor.buildNumber == #mainUI.Selection.buildInfoTables)))
	fadeWidget(GetWidget('main_build_editor_name_input'), buildEditorStatus.currentBuildModified)
	fadeWidget(GetWidget('main_build_editor_undo_btn'), buildEditorStatus.currentBuildModified)
	fadeWidget(GetWidget('main_build_editor_save_btn'), buildEditorStatus.currentBuildModified)
	
	GetWidget('main_build_editor_combobox_container'):SetEnabled(not buildEditorStatus.webRequestPending)
	GetWidget('main_build_editor_new_btn'):SetEnabled(not buildEditorStatus.webRequestPending)
	GetWidget('main_build_editor_share_container'):SetEnabled(not buildEditorStatus.webRequestPending)
	GetWidget('main_build_editor_delete_btn'):SetEnabled(not buildEditorStatus.webRequestPending)
	GetWidget('main_build_editor_undo_btn'):SetEnabled(not buildEditorStatus.webRequestPending)
	GetWidget('main_build_editor_save_btn'):SetEnabled(not buildEditorStatus.webRequestPending)
	GetWidget('main_build_editor_edit_btn'):SetEnabled(not buildEditorStatus.webRequestPending)
end

local function BuildEditorRegister(object)
	local main_build_editor_sleeper					=	GetWidget('main_build_editor_sleeper')
	--local selection_builds_expanded					=	GetWidget('selection_builds_expanded')
	--local container									=	GetWidget('main_build_editor_popup')
	local main_build_editor_popup_close_btn			=	GetWidget('main_build_editor_popup_close_btn')
	
	local main_build_editor_new_btn					=	GetWidget('main_build_editor_new_btn')
	local main_build_editor_edit_btn				=	GetWidget('main_build_editor_edit_btn')
	local main_build_editor_delete_btn				=	GetWidget('main_build_editor_delete_btn')
	local main_build_editor_save_btn				=	GetWidget('main_build_editor_save_btn')
	local main_build_editor_undo_btn				=	GetWidget('main_build_editor_undo_btn')
	--local builds_input_parent						=	GetWidget('builds_input_parent')
	local main_build_editor_combobox				=	GetWidget('main_build_editor_combobox')
	local main_build_editor_textbox					=	GetWidget('builds_input_textbox')
	local selectedHero = 0
	
	for index = 0,3 do
		AbilityRegister(index, (index + 1), 'HeroSelectHeroList')
	end	
	
	for index = 1,15 do
		AbililtySlotRegister(index)
	end

	for index = 1,15 do
		ItemSlotRegister(index)
	end	

	main_build_editor_popup_close_btn:SetCallback('onclick', function(widget) closeItemBuildEditor() end)
	--[[
	container:RegisterWatchLua('mainPanelStatus', function(widget, trigger)
		-- Reset the build editor. RMM Prompt before discarding - this'll require intercepting the main trigger call.
		-- The best way to do this would be to create a "ChangeMain" function, where you can check for things before actually changing.
		if trigger.main ~= 40 and mainUI.Selection.abilitiesBuildTables then
			lastSelectedBuild = nil
			UpdateSelectedHeroBuild(triggerStatus.selectedBuild)
			closeEditor()
		end
	end)

	container:RegisterWatchLua('buildEditorStatus', function(widget, trigger)
		UpdateBuild(nil, trigger.webRequestPending) 
	end, false, nil, 'webRequestPending')
	
	builds_input_parent:RegisterWatchLua('buildEditorStatus', function(widget, trigger)
		widget:SetVisible(trigger.currentBuildModified)
		widget:SetEnabled(not trigger.webRequestPending)
	end, false, nil, 'currentBuildModified', 'webRequestPending')		
	]]
	main_build_editor_edit_btn:SetCallback('onclick', function()
		buildEditorStatus.currentBuildModified = true
		if mainBuildEditor.buildNumber == 1 or (loadedLastBuild and mainBuildEditor.buildNumber == #mainUI.Selection.buildInfoTables) then
			buildEditorStatus.editingBuild = false
		else
			buildEditorStatus.editingBuild = true
		end
		buildEditorStatus:Trigger(false)
	end)
	
	--delete build
	main_build_editor_delete_btn:SetCallback('onclick', function()	
		GenericDialogAutoSize(
			'builds_delete_build', 'builds_delete_build_desc', '', 'general_ok', 'general_cancel', 
				function()
					mainUI.Selection.lastHeroRetrieved = nil
					Strife_Web_Requests:DeleteHeroBuildByIndex(entityName or LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo').heroEntityName, mainUI.Selection.buildInfoTables[tonumber(mainBuildEditor.buildNumber)].buildIncrement)
					mainBuildEditor.buildNumber = 1
					buildEditorStatus.currentBuildModified = false
					buildEditorStatus.webRequestPending = false
					buildEditorStatus:Trigger(false)
					mainUI.savedRemotely.heroBuilds[entityName or LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo').heroEntityName].default_build = 1
					LoadHeroBuilds()
				end,
				function()
					PlaySound('/ui/sounds/sfx_ui_back.wav')
				end
		)		
	end)
	
	main_build_editor_new_btn:SetCallback('onclick', ClearHeroBuild)
	
	main_build_editor_undo_btn:SetCallback('onclick', function()	
		GenericDialogAutoSize(
			'builds_undo_build', 'builds_undo_build_desc', '', 'general_ok', 'general_cancel', 
				function()
					RevertEditorHero()
					lastSelectedBuild = nil
					UpdateSelectedHeroBuild(mainBuildEditor.buildNumber)
					buildEditorStatus.currentBuildModified = false
					buildEditorStatus:Trigger(false)		
				end,
				function()
					PlaySound('/ui/sounds/sfx_ui_back.wav')
				end
		)			
	end)


	local droptarget = object:GetWidget('main_build_editor_share_droptarget_droptarget')
	local dropparent = object:GetWidget('main_build_editor_share_droptarget_parent')
	local droplabel  = object:GetWidget('main_build_editor_share_label')

	droptarget:SetCallback("ondragenter", function(widget, data, x, y)
		println("DragEnter: ", data, " ", x, " ", y)
	end)
	droptarget:SetCallback("ondragover", function(widget, data, x, y)
		-- println("DragOver: ", data, " ", x, " ", y)
	end)
	droptarget:SetCallback("ondragleave", function(widget, data)
		println("DragLeave: ", data)
	end)
	droptarget:SetCallback("ondrop", function(widget, data, x, y)
		println("Drop: ", data, " ", x, " ", y)
		if (Windows.data) and (Windows.data.friendBeingDraggedIdentID) then
			globalDragInfo = LuaTrigger.GetTrigger('globalDragInfo')
			globalDragInfo.type = 21
			Links.SpawnLink(Windows.data.friendBeingDraggedIdentID, 'pm', Friends['main'].GetFriendDataFromIdentID(Windows.data.friendBeingDraggedIdentID).name, {buildNum=mainBuildEditor.buildNumber})
		end
	end)	
	dropparent:UnregisterWatchLua('MultiWindowDragInfo')
	dropparent:RegisterWatchLua('MultiWindowDragInfo', function(widget, trigger)
		local vis = (MultiWindowDragInfo.active) and (MultiWindowDragInfo.type == 'player')
		widget:SetVisible(vis)
		droplabel:SetVisible(not vis)
	end, false, nil, 'active', 'type')

	
	main_build_editor_sleeper:RegisterWatchLua('buildEditorStatus', function(widget, trigger)
		updateControls()
	end, false, nil, 'editingBuild', 'currentBuildModified', 'webRequestPending')
	
	main_build_editor_save_btn:SetCallback('onclick', SaveHeroBuild)
	
	function Builds.InputOnEnter()
		GetWidget('builds_input_textbox'):SetFocus(false)		
	end
	
	function Builds.InputOnEsc()
		GetWidget('builds_input_textbox'):EraseInputLine()
		GetWidget('builds_input_textbox'):SetFocus(false)	
		GetWidget('builds_input_textbox'):SetVisible(true)
		--GetWidget('build_editor_input_close_button'):SetVisible(0)		
	end
	--[[
	GetWidget('build_editor_input_button'):SetCallback('onclick', function(widget)
		GetWidget('builds_input_textbox'):SetFocus(true)
	end)	
	]]
	--[[
	GetWidget('build_editor_input_close_button'):SetCallback('onclick', function(widget)
		Builds.InputOnEsc()
	end)	
	]]
	GetWidget('builds_input_coverup'):SetVisible(true)
	--GetWidget('build_editor_input_close_button'):SetVisible(0)
	
	GetWidget('builds_input_textbox'):SetCallback('onfocus', function(widget)
		GetWidget('builds_input_coverup'):SetVisible(false)
		--GetWidget('build_editor_input_close_button'):SetVisible(1)
	end)
	
	GetWidget('builds_input_textbox'):SetCallback('onlosefocus', function(widget)
		if string.len(widget:GetValue()) == 0 then
			GetWidget('builds_input_coverup'):SetVisible(true)
			--GetWidget('build_editor_input_close_button'):SetVisible(0)
		end
	end)	
	
	GetWidget('builds_input_textbox'):SetCallback('onhide', function(widget)
		 Builds.InputOnEsc()
	end)	
	
	GetWidget('builds_input_textbox'):SetCallback('onshow', function(widget)
		if (not remoteBuild) then
			if (not buildEditorStatus.editingBuild) then
				widget:SetInputLine(LuaTrigger.GetTrigger('AccountInfo').nickname .. " " .. LuaTrigger.GetTrigger('HeroSelectHeroList' .. mainBuildEditor.buildHero).displayName .. " "..Translate('general_guide'))
			elseif (mainUI.Selection.buildInfoTables and mainUI.Selection.buildInfoTables[tonumber(mainBuildEditor.buildNumber)]) then
				widget:SetInputLine(mainUI.Selection.buildInfoTables[tonumber(mainBuildEditor.buildNumber)].name)
			end
		end
	end)	
	
	GetWidget('builds_input_textbox'):SetCallback('onchange', function(widget)
		if(string.len(widget:GetValue()) > 0) then
			GetWidget('builds_input_coverup'):SetVisible(false)
		else
		
		end
	end)
	
	local lastSelectedHero = -1
	main_build_editor_sleeper:RegisterWatchLua('mainBuildEditor', function(widget, trigger)
		if (trigger.buildHero) and (trigger.buildHero >= 0) and (lastSelectedHero ~= trigger.buildHero) then
			lastSelectedBuild = nil
			ResetBuild()
			local heroEntityName = LuaTrigger.GetTrigger('HeroSelectHeroList' .. trigger.buildHero).entityName
			UpdateBuild(heroEntityName, nil)	
			buildEditorStatus:Trigger(true)
			lastSelectedHero = trigger.buildHero		
		end
	end, true, nil, 'buildHero')
	
	main_build_editor_sleeper:RegisterWatchLua('HeroSelectLocalPlayerInfo', function(widget, trigger)
		LoadHeroBuilds(object, trigger.heroEntityName)
		remoteBuild = false
	end, true, nil, 'heroEntityName')
	-- data links stuff
	
	buildEditorStatus.currentBuildModified			= false	
	buildEditorStatus.webRequestPending				= false	
	buildEditorStatus:Trigger(true)
	
	BuildEditorRegister = nil
end

BuildEditorRegister(object)

-- widgets
main_build_editor_container = object:GetWidget('main_build_editor_container')

local trigger = LuaTrigger.GetTrigger('mainBuildEditor')
local mainShop = LuaTrigger.GetTrigger('mainShop')

-- Visibility via trigger
main_build_editor_container:RegisterWatchLua('mainBuildEditor', function(widget, trigger)
	fadeWidget(widget, trigger.visible)
	updateControls()
	resetTrigger('mainShop')
	mainShop.visible = trigger.visible
	mainShop.bookmarksVisible = false
	mainShop.title = 'builds_step1'
	mainShop.y = '-58s'
	mainShop.mode = 1
	mainShop.valign = 'bottom'
	mainShop.scale = '1'
	mainShop.exclusions = 'crafted'
	mainShop:Trigger()
	
	if (trigger.visible) then
		UpdateSelectedHeroBuild(trigger.buildNumber)
	end
	
	-- Temp fix to to not 'potentially' break in-game shop
	triggerStatus.selectedBuild = trigger.buildNumber
	
end, false, nil, 'visible')

-- Hide on bg click
main_build_editor_container:SetCallback('onclick', function()
	trigger.visible = false
	trigger:Trigger()
end)

