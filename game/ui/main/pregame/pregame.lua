-- Just a note in this file, the slots in 'Hero/pet selection' are shared between hero and pets, so, the
-- names such as 'updateHeroInfo' or 'hoverHero' also apply to pet selection also.

-- ================================================================
-- ========================== Variables ===========================
-- ================================================================

local interface = object

RegionSelect = RegionSelect or {}
mainUI 		 = mainUI or {}
mainUI.Pregame 		 = mainUI.Pregame or {}

mainUI.maxHeroSlots				= 59
mainUI.maxHeroTriggers			= 59
mainUI.maxPetSlots				= 20
mainUI.maxCraftedItemSlots		= 24
mainUI.maxCraftedItems			= 99
mainUI.maxGearSets				= 4
mainUI.maxDyeSets				= 8

mainUI.savedRemotely 				= mainUI.savedRemotely 		or {}
mainUI.savedRemotely.heroBuilds 	= mainUI.savedRemotely.heroBuilds 	or {}
mainUI.savedRemotely.petLastSkins 	= mainUI.savedRemotely.petLastSkins or {}

-- These aren't affected by animate children
mainUI.Pregame.specialWidgets = {"main_pregame_skills_container", "main_pregame_hero_info_container", "main_pregame_customization_builds_browse"}

-- Splash
mainUI.Pregame.splashWidgets = {}
mainUI.Pregame.removeAllSplashes = nil

-- Selection
local state 				= 1 -- 1 = hero, 2 = pet, 3 = customize
mainUI.Pregame.heroRoleTable 		= {}
local heroWidgets 			= {}
local petWidgets 			= {}
local numGridColumns 		= 9
local isGridView 			= true
local minHeroRoleValue 		= 3
local lastRole 				= 0
local maxHeroListWidth 		= -1
local selectedHero 			= -1
local selectedPet 			= -1
local petSelection 			= false
local dragThread
local actuallySelectedHero 	= false
local actuallySelectedPet 	= false
mainUI.Pregame.inQueue 		= false

local divisionColors = {
	provisional = '1 1 1 1',
	slate = '0.6 0.6 0.6 1',
	bronze = '0.84 .53 0 1',
	silver = '0.9 0.9 0.95 1',
	gold = '1 .8 .05 1',
	platinum = '0.95 0.95 0.90 1',
	diamond = '0.6 0.89 1 1'
}

local heroInfoShowing 	= {true, true, true, true}
local roles 			= {'All','CC','MagDamage','PhysDamage','Survival','Utility'}
local thread
local autoScrollSpeed 	= 8
local wheelScrollSpeed	= 24
local randomWidget
local tileSizes			= {81, 99, 91, 110} -- width/height, for gridView[1-2] and normal[3-4], in s size.

-- Dye Selection
local dyesPerRow 		= 10
local selectedDye 		= 0
local lastSkinPath
local lastModelPath

-- Skin Selection
local selectedSkin 		= 0
local selectedAvatarDye = {}
local selectedPetSkin 	= 1
local skinWidgets 		= {}
local loadLastValidCosmeticConfig

---------------------------
------- Widgets
---------------------------
local widget = {}

-- Splash
local pregame_loading_background 					= object:GetWidget("pregame_loading_background")
local pregame_splashimage_container 				= object:GetWidget("pregame_splashimage_container")

local splashTrigger 								= LuaTrigger.CreateCustomTrigger('splashTrigger2',{})

-- Timer
local main_pregame_timer_container 					= object:GetWidget("main_pregame_timer_container")
local main_pregame_timer 							= object:GetWidget("main_pregame_timer")

-- Hero/Pet Selection
local main_pregame_sleeper 							= object:GetWidget("main_pregame_sleeper")
local main_pregame_container 						= object:GetWidget("main_pregame_container")
local main_pregame_hero_select_container 			= object:GetWidget("main_pregame_hero_select_container")
local main_pregame_heros_container 					= object:GetWidget("main_pregame_heros_container")
local main_pregame_skills_container 				= object:GetWidget("main_pregame_skills_container")
local main_pregame_hero_info_container 				= object:GetWidget("main_pregame_hero_info_container")
local main_pregame_hero_name_container 				= object:GetWidget("main_pregame_hero_name_container")
local heroselect_toggle_view 						= object:GetWidget("heroselect_toggle_view")
widget.main_pregame_hero_select_grad				= object:GetWidget("main_pregame_hero_select_container_grad")

-- Hero/Pet scrolling
local main_pregame_heros_scroll_parent 				= object:GetWidget("main_pregame_heros_scroll_parent")
local main_pregame_heros_scroll_left 				= object:GetWidget("main_pregame_heros_scroll_left")
local main_pregame_heros_scroll_right 				= object:GetWidget("main_pregame_heros_scroll_right")
local main_pregame_heros_scroll_left_image 			= object:GetWidget("main_pregame_heros_scroll_left_image")
local main_pregame_heros_scroll_right_image 		= object:GetWidget("main_pregame_heros_scroll_right_image")

local slider 										= interface:GetWidget('main_pregame_heros_slider')
local sliderBacking 								= interface:GetWidget('main_pregame_heros_slider_backing')
local sliderContainerWidth 							= interface:GetWidget('main_pregame_heros_slider_container'):GetWidth()

local main_pregame_heros_slider_container_parent 	= object:GetWidget("main_pregame_heros_slider_container_parent")
local heroselect_filter_container 					= object:GetWidget("heroselect_filter_container")
local main_pregame_selection_container 				= object:GetWidget("main_pregame_selection_container")

-- Dye Selection
local main_pregame_dye_selection_container 							= object:GetWidget('main_pregame_dye_selection_container')
local main_pregame_dye_selection_heromodel 							= object:GetWidget('main_pregame_dye_selection_heromodel')
local main_pregame_dye_selection_previous 							= object:GetWidget('main_pregame_dye_selection_previous')
local main_pregame_dye_selection_next 								= object:GetWidget('main_pregame_dye_selection_next')

local main_pregame_customization_die_container 						= object:GetWidget('main_pregame_customization_die_container')
local main_pregame_customization_die_title 							= object:GetWidget('main_pregame_customization_die_title')
local main_pregame_customization_die_cost_container 				= object:GetWidget('main_pregame_customization_die_cost_container')
local main_pregame_customization_die_rental_cost_container 			= object:GetWidget('main_pregame_customization_die_rental_cost_container')
local main_pregame_customization_die_cost_owned 					= object:GetWidget('main_pregame_customization_die_cost_owned')
local main_pregame_customization_die_cost_owned_label 				= object:GetWidget('main_pregame_customization_die_cost_owned_label')
local main_pregame_customization_die_cost 							= object:GetWidget('main_pregame_customization_die_cost')
local main_pregame_customization_die_rental_cost 					= object:GetWidget('main_pregame_customization_die_rental_cost')

local main_pregame_purchase_hero_cosmetic_product_purchase_option_1 = object:GetWidget('main_pregame_purchase_hero_cosmetic_product_purchase_option_1')
local main_pregame_purchase_hero_cosmetic_product_purchase_option_2 = object:GetWidget('main_pregame_purchase_hero_cosmetic_product_purchase_option_2')


-- pet preview and purchasing
local main_pregame_pet_selection_container 			= object:GetWidget('main_pregame_pet_selection_container')
local main_pregame_pet_selection_heromodel 			= object:GetWidget('main_pregame_pet_selection_heromodel')
local main_pregame_pet_selection_previous 			= object:GetWidget('main_pregame_pet_selection_previous')
local main_pregame_pet_selection_next 				= object:GetWidget('main_pregame_pet_selection_next')

local main_pregame_customization_pet_container 		= object:GetWidget('main_pregame_customization_pet_container')
local main_pregame_customization_pet_title 			= object:GetWidget('main_pregame_customization_pet_title')
local main_pregame_customization_pet_cost_container = object:GetWidget('main_pregame_customization_pet_cost_container')
local main_pregame_customization_pet_cost_owned 	= object:GetWidget('main_pregame_customization_pet_cost_owned')
local main_pregame_customization_pet_cost 			= object:GetWidget('main_pregame_customization_pet_cost')

-- Customization
local main_pregame_customization_container 			= object:GetWidget("main_pregame_customization_container")
local main_pregame_customization_skin_container 	= object:GetWidget('main_pregame_customization_skin_container')
local main_pregame_customization_edit_build 		= object:GetWidget('main_pregame_customization_edit_build')
--local main_pregame_customization_new_build 			= object:GetWidget('main_pregame_customization_new_build')
local main_pregame_customization_undo 				= object:GetWidget('main_pregame_customization_undo')
local main_pregame_customization_ready_container 	= object:GetWidget('main_pregame_customization_ready_container')
local main_pregame_customization_ready 				= object:GetWidget('main_pregame_customization_ready')
local main_pregame_customization_readyLabel 		= object:GetWidget('main_pregame_customization_readyLabel')
local main_pregame_customization_readyBody 			= object:GetWidget('main_pregame_customization_readyBody')
local main_pregame_customization_watch_container 	= object:GetWidget('main_pregame_customization_watch_container')
local main_pregame_customization_watch 				= object:GetWidget('main_pregame_customization_watch')
local main_pregame_customization_to_ready 			= object:GetWidget('main_pregame_customization_to_ready')
widget.main_pregame_customization_browseOnline		= object:GetWidget('main_pregame_customization_builds_browse')

-- How-to
local main_pregame_how_to_container 				= object:GetWidget('main_pregame_how_to_container') -- RMM: Causes errors when added to the widget table?
local main_pregame_how_to_browser 					= object:GetWidget('main_pregame_how_to_browser') -- This one too? Why?
local main_pregame_how_to_browser_container 		= object:GetWidget('main_pregame_how_to_browser_container')
-- Capped on local vars, add new widgets to the widget table, and if you need local vars, add some of the above to the table also.

-- Ready Selection
widget.main_pregame_ready_container 				= object:GetWidget('main_pregame_ready_container')
widget.main_pregame_ready_unready 					= object:GetWidget('main_pregame_ready_unready')
widget.main_pregame_ready_review_container 			= object:GetWidget('main_pregame_ready_review_container')

-- Sync
widget.main_pregame_sync_container 					= object:GetWidget('main_pregame_sync_container')

-- Party
widget.main_pregame_party_leave 					= object:GetWidget('main_pregame_party_leave')
widget.main_pregame_party_mode_button 				= object:GetWidget('main_pregame_party_mode_button')
widget.main_pregame_party_container 				= object:GetWidget('main_pregame_party_container')
widget.selection_chat_base 							= object:GetWidget('selection_chat_base')

local shrinkChat
local resetChat

-- General
local heroEntityName

-- ================================================================
-- ========================== Triggers ============================
-- ================================================================
local gamePhaseTrigger = LuaTrigger.GetTrigger('GamePhase')

-- ================================================================
-- ====================== General functions =======================
-- ================================================================
-- Note: Understanding this function's use will make a lot of things easier.
-- In essence, instantiates templates to a parent, using customized parameters from a luaTrigger set.
-- Takes the template parent, the template name, the trigger name (in the form triggerNameX), a function to validate each trigger with,
-- a function returning an array of values to instantiate the widget with, whether to clear the parent, and functions for click, over and out, given X and the trigger
-- Returns the array of instantiated widgets
local function createWidgetArrayFromTriggerSet(parent, template, triggerName, triggerValidFunc, templateArgFunc, clear, functions)
	if clear then
		parent:ClearChildren()
	end
	local array = {}
	for n = 0, 99 do
		local trigger = LuaTrigger.GetTrigger(triggerName..n)
		if (not trigger or not triggerValidFunc(n, trigger)) then
			break
		end
		array[n] = parent:InstantiateAndReturn(template, unpack(templateArgFunc(n, trigger)))[1]
		for k,v in pairs(functions) do
			array[n]:SetCallback(k, function(widget)
				v(n, trigger)
			end)
		end
	end
	FindChildrenClickCallbacks(parent)
	return array
end

-- Breadcrumbs
local refreshBreadcrumbs -- Refresh the sub-navigation

-- Animation
--local animateChildren = fadeWidget

local heroSelectButtonClick
local petSelectButtonClick
local CustomizeSelectButtonClick

-- Client-feedback helper
local function triggerVarChangeOrFunction(triggerName, var, varValue, waitTime, threadKey, failFunc, successFunc)
	local rndString = threadKey or tostring(math.random())
	if (mainUI.Pregame.triggerVarChangeOrFunctionThread) then
		mainUI.Pregame.triggerVarChangeOrFunctionThread:kill()
		mainUI.Pregame.triggerVarChangeOrFunctionThread = nil
	end
	mainUI.Pregame.triggerVarChangeOrFunctionThread = libThread.threadFunc(function()
		wait(waitTime)
		UnwatchLuaTriggerByKey(triggerName, rndString)
		if (failFunc) then failFunc() end
		mainUI.Pregame.triggerVarChangeOrFunctionThread = nil
	end)
	local function succeed()
		UnwatchLuaTriggerByKey(triggerName, rndString)
		mainUI.Pregame.triggerVarChangeOrFunctionThread:kill()
		mainUI.Pregame.triggerVarChangeOrFunctionThread = nil
		if (successFunc) then successFunc() end
	end
	if (LuaTrigger.GetTrigger(triggerName)[var] ~= varValue) then
		UnwatchLuaTriggerByKey(triggerName, rndString)
		WatchLuaTrigger(triggerName, function(trigger)
			if (varValue and trigger[var] == varValue) then
				succeed()
			end
		end, rndString, var)
	else
		succeed()
	end
end

-- Say we want to find X, where HeroSelectHeroListX.entityName is "Hero_Ace", this would be findIndexFromTriggerArray('HeroSelectHeroList', validFunc, 'entityName', 'Hero_Ace')
local function findIndexFromTriggerArray(triggerName, validFunc, var, varValue)
	for n = 0, 99 do
		local trigger = LuaTrigger.GetTrigger(triggerName..n)
		if (not trigger or not validFunc(n, trigger)) then
			break
		end
		if trigger[var] == varValue then
			return n
		end
	end
	return -1
end

local function findPetFromEntityName(entityName)
	return findIndexFromTriggerArray('HeroSelectFamiliarList', function(n, trigger) return trigger.entityName ~= "" end, 'entityName', entityName)
end

local function isLeader()
	return LuaTrigger.GetTrigger('PartyStatus').isPartyLeader
end
local function getQueue()
	if isLeader() then
		return LuaTrigger.GetTrigger('selectModeInfo').queuedMode
	else
		return LuaTrigger.GetTrigger('PartyStatus').queue
	end
end

local function canSelectHero()
	return (LuaTrigger.GetTrigger('GamePhase').gamePhase > 2 and LuaTrigger.GetTrigger('LobbyStatus').inLobby) or LuaTrigger.GetTrigger('PartyStatus').inParty
end

--[[
New items
Where X is an incrementing number
Hero: new_store_hero_X = <EntityName>
HeroSkin: new_store_hero_skin_X = <EntityName>_<Gear name>
HeroSkinDye: new_store_hero_skin_dye_X = <EntityName>_<Gear name>_<Dye name>
e.g.
new_store_hero_1					Hero_Carter
new_store_hero_skin_1				Hero_Carter_uber
new_store_hero_skin_dye_1			Hero_Carter_uber_black
]]
local tinsert = table.insert
local retrievedNewItems = false
local newHeroes = {}
local newSkins = {}
local newDyes = {}

local function getNewItems()
	if (retrievedNewItems) then return end
	retrievedNewItems = true
	for n = 1, 99 do
		local hero = TranslateOrNil('new_store_hero_' .. n)
		local skin = TranslateOrNil('new_store_hero_skin_' .. n)
		local dye = TranslateOrNil('new_store_hero_skin_dye_' .. n)
		if (not (hero or skin or dye)) then -- End of list
			break
		end
		if hero then tinsert(newHeroes, hero) end
		if skin then tinsert(newSkins, skin) end
		if dye then tinsert(newDyes, dye) end
	end
end
getNewItems()

local function isNewHero(entityName)
	return libGeneral.isInTable(newHeroes, entityName)
end
local function isNewSkin(entityName, skinName)
	return libGeneral.isInTable(newSkins, entityName..'_'..skinName)
end
local function isNewDye(entityName, skinName, dyeName)
	return libGeneral.isInTable(newDyes, entityName..'_'..skinName..'_'..dyeName)
end

-- ================================================================
-- ======================== Splash screen =========================
-- ================================================================
local heroSplashSpawnDelayThread
local function updateSplash(image)
	if (heroSplashSpawnDelayThread) then
		heroSplashSpawnDelayThread:kill()
		heroSplashSpawnDelayThread = nil
	end
	if mainUI.Pregame.removeAllSplashes and mainUI.Pregame.removeAllSplashes:IsValid() then
		mainUI.Pregame.removeAllSplashes:kill()
		mainUI.Pregame.removeAllSplashes = nil
	end
	if (image ~= "") then
		heroSplashSpawnDelayThread = libThread.threadFunc(function()
			wait(80)
			local splashWidget = pregame_splashimage_container:InstantiateAndReturn('pregame_splashimage_template', 
				'image', image
			)
			splashWidget[1]:FadeIn(500, function(widget)
				splashTrigger:Trigger(true)
				widget:RegisterWatchLua('splashTrigger2', function()
					widget:Destroy()
				end)
			end)
			table.insert(mainUI.Pregame.splashWidgets, splashWidget[1])
			heroSplashSpawnDelayThread = nil
		end)
	else
		mainUI.Pregame.removeAllSplashes = libThread.threadFunc(function()
			wait(1)
			while (#mainUI.Pregame.splashWidgets > 0) do
				local widget = mainUI.Pregame.splashWidgets[1]
				if widget and widget:IsValid() then
					widget:FadeOut(250)
					libThread.threadFunc(function()
						wait(250)
						widget:Destroy()
					end)
				end
				table.remove(mainUI.Pregame.splashWidgets, 1)
			end
			mainUI.Pregame.removeAllSplashes = nil
		end)
	end
end

-- ================================================================
-- ===================== Hero/pet selection =======================
-- ================================================================

local function getSelected()
	return petSelection and selectedPet or selectedHero
end

local function setSelectedToFirstSelectablePet()
	for n = 0, mainUI.maxPetSlots do
		local trigger = LuaTrigger.GetTrigger('HeroSelectFamiliarList'..n)
		if (trigger and trigger.selectable) then
			selectedPet = n
			break
		end
	end
end

---------------------------
------- Hero Select Horizontal Slider
---------------------------
local function clamp(n, low, high) return math.max( math.min(n, high), low ) end

-- The math in here gets kinda complex
local sliderLastXPosition = 0

local function updateHeroSlider(XDiff, reset, animate)
	if (not reset and isGridView) then return end -- don't scroll in grid view
	
	local XDiff = XDiff + sliderLastXPosition
	local shouldBeVisible = sliderContainerWidth < maxHeroListWidth
	
	if reset then
		-- slider:SetWidth(clamp(100*sliderContainerWidth/maxHeroListWidth, 0, 100) .."%")
		slider:SetX(0)
		sliderLastXPosition = 0
		main_pregame_heros_container:SetX(0)
		main_pregame_heros_scroll_left:SetVisible(false)
		main_pregame_heros_scroll_right:SetVisible(shouldBeVisible)
		slider:SetVisible(shouldBeVisible)
		sliderBacking:SetVisible(shouldBeVisible)
	else
		if not shouldBeVisible then return end
		local XDiff = clamp(XDiff, 0, sliderContainerWidth-slider:GetWidth())
		if (animate) then
			slider:SlideX(XDiff, 100)
			sliderLastXPosition = XDiff
		else
			slider:SetX(XDiff)
			sliderLastXPosition = XDiff
		end
		
		main_pregame_heros_scroll_left:SetVisible(XDiff ~= 0)
		main_pregame_heros_scroll_right:SetVisible(XDiff ~= sliderContainerWidth-slider:GetWidth())
		
		local amountCanMove = sliderContainerWidth-slider:GetWidth()
		if amountCanMove == 0 then
			main_pregame_heros_container:SetX(0)
			main_pregame_heros_scroll_left:SetVisible(0)
			main_pregame_heros_scroll_right:SetVisible(0)
		else
			local newPos = -(maxHeroListWidth-sliderContainerWidth)*XDiff/amountCanMove
			main_pregame_heros_container:SetX(newPos)
		end
	end
	
end

slider:SetCallback('onmouseldown', function(widget)
	local cursorXPos = Input.GetCursorPosX()
	local xPosOnSlider = Input.GetCursorPosX()-widget:GetAbsoluteX()
	
	if (dragThread) then
		dragThread:kill()
		dragThread = nil
	end
	
	dragThread = libThread.threadFunc(function(thread)
		while (true) do
			local newCursorXPos = Input.GetCursorPosX()
			local XDiff = newCursorXPos-cursorXPos
			cursorXPos = newCursorXPos
			updateHeroSlider(XDiff)
			wait(17)--about 60 fps
		end
	end)
end)

slider:SetCallback('onmouselup', function(widget)
	if (dragThread) then
		dragThread:kill()
		dragThread = nil
	end
end)

-- Auto-scrolling tabs
local moveThread

main_pregame_heros_scroll_left:SetCallback('onmouseover', function(widget)
	main_pregame_heros_scroll_left_image:SetTexture('/ui/main/pregame/textures/scroll_tab_over.tga')
	moveThread = libThread.threadFunc(function(thread)
		while (true) do
			updateHeroSlider(-autoScrollSpeed)
			wait(17)--about 60 fps
		end
	end)
end)

main_pregame_heros_scroll_left:SetCallback('onmouseout', function(widget)
	main_pregame_heros_scroll_left_image:SetTexture('/ui/main/pregame/textures/scroll_tab_up.tga')
	if (moveThread) then
		moveThread:kill()
		moveThread = nil
	end
end)

main_pregame_heros_scroll_right:SetCallback('onmouseover', function(widget)
	main_pregame_heros_scroll_right_image:SetTexture('/ui/main/pregame/textures/scroll_tab_over.tga')
	moveThread = libThread.threadFunc(function(thread)
		while (true) do
			updateHeroSlider(autoScrollSpeed)
			wait(17)--about 60 fps
		end
	end)
end)

main_pregame_heros_scroll_right:SetCallback('onmouseout', function(widget)
	main_pregame_heros_scroll_right_image:SetTexture('/ui/main/pregame/textures/scroll_tab_up.tga')
	if (moveThread) then
		moveThread:kill()
		moveThread = nil
	end
end)

---------------------------
------- Hero Filters
---------------------------
local function applyHeroFilter(role)
	local widgetArray = (petSelection and petWidgets) or heroWidgets
	
	if (#widgetArray == 0) then -- Nothing we can do, widgets don't exist yet.
		return
	end
	
	-- Fade out widgets from other group, i.e, if we are selecting pets, fade out hero widgets.
	if (petSelection) then
		if #heroWidgets > 0 then
			for n = 0, #heroWidgets do heroWidgets[n]:SetVisible(false) end
		end
	else
		if #petWidgets > 0 then
			for n = 0, #petWidgets do
				if (petWidgets[n]:IsValid()) then petWidgets[n]:SetVisible(false) end
			end
		end
	end
	
	local role 			= role or lastRole
	lastRole 			= role
	local visNum 		= 0
	
	if (not widgetArray[0] or not widgetArray[0]:IsValid()) then return end
	
	
	if isGridView then
		shrinkChat()
	else
		resetChat()
	end
	
	local tileWidth 	= widgetArray[0]:GetWidth()
	local tileHeight 	= widgetArray[0]:GetHeight()
	
	mainUI.Pregame.applyHeroFilterThreads = mainUI.Pregame.applyHeroFilterThreads or {}
	
	for n = 0, #widgetArray do
		if (mainUI.Pregame.applyHeroFilterThreads[n]) then
			mainUI.Pregame.applyHeroFilterThreads[n]:kill()
			mainUI.Pregame.applyHeroFilterThreads[n] = nil
		end
	
		if (widgetArray[n] == randomWidget or petSelection or role == 0 or mainUI.Pregame.heroRoleTable[n][role] > minHeroRoleValue) then
			local xPos, yPos
			if isGridView then
				xPos = tileWidth*(visNum%numGridColumns)
				yPos = tileHeight*(math.floor(visNum/numGridColumns))
			else
				xPos = tileWidth*visNum
				yPos = 0
			end
		
			if (widgetArray[n]:IsVisible()) then -- This is the sliding effect
				widgetArray[n]:SlideX(xPos, 125)
				widgetArray[n]:SlideY(yPos, 125)
				mainUI.Pregame.applyHeroFilterThreads[n] = libThread.threadFunc(function()
					wait(125)
					if (widgetArray[n] and widgetArray[n]:IsValid()) then
						widgetArray[n]:SetX(xPos)
						widgetArray[n]:SetY(yPos)
					end
					mainUI.Pregame.applyHeroFilterThreads[n] = nil
				end)
			else
				widgetArray[n]:SetX(xPos)
				widgetArray[n]:SetY(yPos)
			end
			fadeWidget(widgetArray[n], true, 125)
			visNum = visNum + 1
		else
			fadeWidget(widgetArray[n], false, 125)
		end
	end
	
	maxHeroListWidth = (visNum+.25)*tileWidth
	updateHeroSlider(0, true)
	
	for n = 0, 5 do -- Change colors of filter buttons
		local postfix = ""
		if n == 0 then
			postfix = 'Text'
			interface:GetWidget("heroselect_filter_"..n..postfix):SetColor((role == n and '#31ceff') or '#3d575e')
		else
			interface:GetWidget("heroselect_filter_"..n..postfix):SetColor((role == n and '#ffffff') or '#3d575e')
		end
	end
end

for n = 0, 5 do
	interface:GetWidget("heroselect_filter_"..n):SetCallback('onclick', function(widget)
		applyHeroFilter(n)
	end)
	interface:GetWidget("heroselect_filter_"..n):SetCallback('onmouseover', function(widget)
		simpleTipGrowYUpdate(true, nil, Translate('heroselect_filter_'..roles[n+1]), Translate('heroselect_filter_'..roles[n+1]..'_tip'), libGeneral.HtoP(40))
	end)
	interface:GetWidget("heroselect_filter_"..n):SetCallback('onmouseout', function(widget)
		simpleTipGrowYUpdate(false)
	end)
end

---------------------------
------- Hero Selection
---------------------------
-- Stats
local main_pregame_stats_container = GetWidget('main_pregame_stats_container')
local function populateStats(hero)
	if (hero == -1) or (petSelection) then
		main_pregame_stats_container:FadeOut(125)
		GetWidget('main_pregame_detailed_skills_container'):FadeOut(125)
		
		main_pregame_stats_container:UnregisterWatch('gameToggleScoreboard')
		main_pregame_stats_container:UnregisterWatch('ModifierKeyStatus')
		
	else
		
		main_pregame_stats_container:UnregisterWatch('gameToggleScoreboard')
		main_pregame_stats_container:UnregisterWatch('ModifierKeyStatus')		
		
		main_pregame_stats_container:FadeIn(125)
		GetWidget('main_pregame_detailed_skills_container'):FadeIn(125)
		
		local trigger 									= LuaTrigger.GetTrigger(('HeroSelectHeroList')..hero)
		local main_pregame_stats_hero_movespeed 		= GetWidget('main_pregame_stats_hero_movespeed')
		-- local main_pregame_stats_hero_initialarmor 	= GetWidget('main_pregame_stats_hero_initialarmor')
		local main_pregame_stats_hero_resistance 		= GetWidget('main_pregame_stats_hero_resistance')
		local main_pregame_stats_hero_attackdamage 		= GetWidget('main_pregame_stats_hero_attackdamage')
		-- local main_pregame_stats_hero_attackrange 	= GetWidget('main_pregame_stats_hero_attackrange')
		-- local main_pregame_stats_hero_critchance 	= GetWidget('main_pregame_stats_hero_critchance')
		-- local main_pregame_stats_hero_critmultiplier = GetWidget('main_pregame_stats_hero_critmultiplier')
		local main_pregame_stats_hero_healthregen 		= GetWidget('main_pregame_stats_hero_healthregen')
		local main_pregame_stats_hero_manaregen 		= GetWidget('main_pregame_stats_hero_manaregen')
		local main_pregame_stats_hero_maxhealth 		= GetWidget('main_pregame_stats_hero_maxhealth')
		local main_pregame_stats_hero_maxmana 			= GetWidget('main_pregame_stats_hero_maxmana')
		
		main_pregame_stats_hero_movespeed:SetText(FtoA2(trigger.moveSpeed, 0, 2))
		main_pregame_stats_hero_attackdamage:SetText(FtoA2(trigger.attackDamage, 0, 2))
		-- main_pregame_stats_hero_attackrange:SetText(trigger.attackRange)
		-- main_pregame_stats_hero_critchance:SetText(trigger.critChance)
		-- main_pregame_stats_hero_critmultiplier:SetText(trigger.critMultiplier)
		-- main_pregame_stats_hero_initialarmor:SetText(FtoA2(trigger.armor, 0, 2) .. '-' .. FtoA2(trigger.armor15, 0, 2))
		main_pregame_stats_hero_resistance:SetText(FtoA2(trigger.resistance, 0, 2))
		main_pregame_stats_hero_healthregen:SetText(FtoA2(trigger.healthRegen, 0, 2) .. '-' .. FtoA2(trigger.healthRegen15, 0, 2))
		main_pregame_stats_hero_manaregen:SetText(FtoA2(trigger.manaRegen, 0, 2) .. '-' .. FtoA2(trigger.manaRegen15, 0, 2))
		main_pregame_stats_hero_maxhealth:SetText(FtoA2(trigger.maxHealth, 0, 2) .. '-' .. FtoA2(trigger.maxHealth15, 0, 2))
		main_pregame_stats_hero_maxmana:SetText(FtoA2(trigger.maxMana, 0, 2) .. '-' .. FtoA2(trigger.maxMana15, 0, 2))

		main_pregame_stats_container:RegisterWatch('gameToggleScoreboard', function(widget, keyDown)
			if AtoB(keyDown) then
				if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_hero_tab.wav') end
				GetWidget('main_pregame_detailed_skills_container'):SlideX('310', 125)
				main_pregame_stats_container:SlideX('15s', 125)
				main_pregame_skills_container:SlideX('-315s', 125)
			else
				main_pregame_stats_container:SlideX('-315s', 125)
				GetWidget('main_pregame_detailed_skills_container'):SlideX('-815s', 125)
				main_pregame_skills_container:SlideX('15s', 125)
			end	
		end)

		main_pregame_stats_container:RegisterWatchLua('ModifierKeyStatus', function(widget, trigger)
			if (trigger.moreInfoKey) then
				if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_hero_tab.wav') end
				GetWidget('main_pregame_detailed_skills_container'):SlideX('310', 125)
				main_pregame_stats_container:SlideX('15s', 125)
				main_pregame_skills_container:SlideX('-315s', 125)
			else
				main_pregame_stats_container:SlideX('-315s', 125)
				GetWidget('main_pregame_detailed_skills_container'):SlideX('-815s', 125)
				main_pregame_skills_container:SlideX('15s', 125)
			end
		end, false)		
		
	end
end

-- Abilities
local function populateAbilities(hero)
	if (hero == -1) then
		main_pregame_skills_container:FadeOut(125)
		GetWidget('main_pregame_stats_tab'):FadeOut(125)
		GetWidget('main_pregame_detailed_skills_container'):FadeOut(125)
	else
		local trigger = LuaTrigger.GetTrigger(((petSelection and 'HeroSelectFamiliarList') or 'HeroSelectHeroList')..hero)
		if (petSelection) then
			local infoNames = {'Active', 'triggered', 'passiveA'}
			for n = 0, 2 do
				interface:GetWidget("main_pregame_skill_"..n.."_image"):SetTexture(trigger[infoNames[n+1]..'Icon'])
				interface:GetWidget("main_pregame_skill_"..n.."_name"):SetText(trigger[infoNames[n+1]..'Name'])
				interface:GetWidget("main_pregame_skill_"..n.."_desc"):SetText(trigger[infoNames[n+1]..'DescriptionSimple'])
				interface:GetWidget("main_pregame_skill_"..n.."_key_container"):SetVisible(n == 0)
				interface:GetWidget("main_pregame_skill_"..n.."_key"):SetText(GetKeybindButton('Game', 'ActivateTool', 18) or '')
			end

			for n = 0, 3 do
				interface:GetWidget("main_pregame_skill_template"..n):SetHeight('74s')
				interface:GetWidget("main_pregame_skill_"..n.."_container"):SetHeight('60s')
				interface:GetWidget("main_pregame_skill_"..n.."_container"):SetWidth('60s')
				interface:GetWidget("main_pregame_skill_"..n.."_name"):SetX('70s')
				interface:GetWidget("main_pregame_skill_"..n.."_desc"):SetX('70s')
				interface:GetWidget("main_pregame_skill_"..n.."_desc"):SetWidth("-76s")
			end

			interface:GetWidget('main_pregame_skill_template3'):SetVisible(false)
			GetWidget('main_pregame_stats_tab'):FadeOut(125)
		else
			for n = 0, 3 do
				interface:GetWidget("main_pregame_skill_"..n.."_image"):SetTexture(trigger['ability'..n..'IconPath'])
				interface:GetWidget("main_pregame_skill_"..n.."_name"):SetText(trigger['ability'..n..'DisplayName'])
				interface:GetWidget("main_pregame_skill_"..n.."_desc"):SetText(trigger['ability'..n..'SimpleDescription'])
				interface:GetWidget("main_pregame_skill_"..n.."_key"):SetText(GetKeybindButton('Game', 'ActivateTool', n) or '')
				interface:GetWidget("main_pregame_skill_"..n.."_key_container"):SetVisible(string.find(trigger['ability'..n..'Description'], "%^444Passive Skill") ~= 1)
			end

			for n = 0, 3 do
				interface:GetWidget("main_pregame_detailed_skill_"..n.."_image"):SetTexture(trigger['ability'..n..'IconPath'])
				interface:GetWidget("main_pregame_detailed_skill_"..n.."_name"):SetText(trigger['ability'..n..'DisplayName'])
				interface:GetWidget("main_pregame_detailed_skill_"..n.."_desc"):SetText(string.gsub(trigger['ability'..n..'Description'], '\n\n', '\n'))
				interface:GetWidget("main_pregame_detailed_skill_"..n.."_key"):SetText(GetKeybindButton('Game', 'ActivateTool', n) or '')
				interface:GetWidget("main_pregame_detailed_skill_"..n.."_key_container"):SetVisible(string.find(trigger['ability'..n..'Description'], "%^444Passive Skill") ~= 1)
			end
			
			for n = 0, 3 do
				interface:GetWidget("main_pregame_skill_template"..n):SetHeight('56s')
				interface:GetWidget("main_pregame_skill_"..n.."_container"):SetHeight('48s')
				interface:GetWidget("main_pregame_skill_"..n.."_container"):SetWidth('48s')
				interface:GetWidget("main_pregame_skill_"..n.."_name"):SetX('58s')
				interface:GetWidget("main_pregame_skill_"..n.."_desc"):SetX('58s')
				interface:GetWidget("main_pregame_skill_"..n.."_desc"):SetWidth("-64s")
			end

			interface:GetWidget('main_pregame_skill_template3'):SetVisible(true)
			GetWidget('main_pregame_stats_tab'):FadeIn(125)
			GetWidget('main_pregame_detailed_skills_container'):FadeIn(125)
		end
		main_pregame_skills_container:FadeIn(125)
	end
end

local function updateHeroInfo(hero)
	if state > 2 then return end
	
	if (hero == -1) then
		fadeWidget(main_pregame_hero_name_container, false)
		main_pregame_hero_info_container:FadeOut(125)
	else
		local partyStatusTrigger = LuaTrigger.GetTrigger('PartyStatus')
		
		fadeWidget(main_pregame_hero_name_container, true)
		local trigger = LuaTrigger.GetTrigger(((petSelection and 'HeroSelectFamiliarList') or 'HeroSelectHeroList')..hero)
		
		-- Title
		interface:GetWidget("main_pregame_hero_name"):SetText(petSelection and GetEntityDisplayName(trigger['entityName']) or trigger.displayName)
		interface:GetWidget("main_pregame_hero_desc"):SetText(trigger.description)

		local info = mainUI.progression.stats.heroes[trigger.entityName]
		if petSelection then -- Pets don't have this
			main_pregame_hero_info_container:FadeOut(10)
			return
		end
		main_pregame_hero_info_container:FadeIn(125)
		
		-- mastery
		local mastery = GetWidget("main_pregame_hero_mastery")
		local masteryFlair = GetWidget("main_pregame_hero_mastered_parent")
		--if (info.rank) then
			local rank 		= (info and info.rank and math.floor(info.rank)) or 0
			local remainder = (info and info.rank and info.rank % 1) or 0
			
			GetWidget("main_pregame_hero_mastery"):SetVisible(rank >= 5)
			GetWidget("main_pregame_hero_mastered"):SetVisible(rank >= 5)
			
			for index = 1,5,1 do
				local starCalc = ((1- math.max(0, math.min(1, ((1 + rank - index) + remainder)))))
				GetWidget('selection_hero_level_star_heropicker_' .. index .. '_2'):ScaleWidth((starCalc * 100) .. '@', 125)
			end		
			
			mastery:SetVisible(((partyStatusTrigger.queue == 'pvp') or (partyStatusTrigger.queue == 'pve')) and (partyStatusTrigger.inParty))
			masteryFlair:SetVisible(((partyStatusTrigger.queue == 'pvp') or (partyStatusTrigger.queue == 'pve')) and (partyStatusTrigger.inParty))			
		
		--else
		--	GetWidget("main_pregame_hero_mastery"):SetVisible(0)
		--	for index = 1,5,1 do
		--		GetWidget('selection_hero_level_star_heropicker_' .. index .. '_2'):ScaleWidth('100@', 125)
		--	end					
		--	mastery:SetVisible(((partyStatusTrigger.queue == 'pvp') or (partyStatusTrigger.queue == 'pve')) and (partyStatusTrigger.inParty))
		--end
		
		if (not info) then
			return
		end
		
		-- type
		if (trigger.attackRange <= 300) then
			interface:GetWidget("main_pregame_hero_attacktype"):SetTexture('/ui/main/shared/textures/melee.tga')
		else
			interface:GetWidget("main_pregame_hero_attacktype"):SetTexture('/ui/main/shared/textures/ranged.tga')
		end		
		
		-- division
		local labelDivision = GetWidget("main_pregame_hero_division_label")
		if (info.ranked_rank) then
			local text = Translate("ranked_division_"..info.ranked_division)
			labelDivision:SetText(text)
			labelDivision:SetColor(divisionColors[info.ranked_division])
			labelDivision:GetParent():SetWidth(getMeasurementFromString(labelDivision, '10s') + GetStringWidth(labelDivision:GetFont(), text))
			labelDivision:GetParent():SetVisible((partyStatusTrigger.queue == 'ranked') and (partyStatusTrigger.inParty))
		else
			labelDivision:GetParent():SetVisible(false)
		end
		
		-- rank
		local labelRank = GetWidget("main_pregame_hero_rank_label")
		if (info.ranked_rank) and (info.ranked_division) then
			labelRank:SetText(info.ranked_rank)
			labelRank:SetColor(divisionColors[info.ranked_division])
			labelRank:GetParent():SetWidth(getMeasurementFromString(labelRank, '10s') + GetStringWidth(labelRank:GetFont(), info.ranked_rank))
			labelRank:GetParent():SetVisible((partyStatusTrigger.queue == 'ranked') and (partyStatusTrigger.inParty))	
		else
			labelRank:GetParent():SetVisible(false)
		end
		
		-- Standard Rating Elo
		local labelStandardRating = GetWidget("main_pregame_hero_elo_label")
		if (false) and (info.pvpRating0) then -- This was intentionally disabled
			labelStandardRating:SetText(info.pvpRating0)
			labelStandardRating:SetColor('white')
			labelStandardRating:GetParent():SetWidth(getMeasurementFromString(labelStandardRating, '10s') + GetStringWidth(labelStandardRating:GetFont(), info.pvpRating0))
			labelStandardRating:GetParent():SetVisible((partyStatusTrigger.queue == 'pvp') and (partyStatusTrigger.inParty))	
		else
			labelStandardRating:GetParent():SetVisible(false)
		end
		
	end
	
end

local initCustomized -- these are for reference, and will be filled later
local loadHeroPrefs

-- Helper functions
local function showSelected()
	if state > 2 then return end
	
	populateAbilities(getSelected())
	populateStats(getSelected())
	
	local trigger = LuaTrigger.GetTrigger(((petSelection and 'HeroSelectFamiliarList') or 'HeroSelectHeroList')..getSelected())
	
	updateSplash((trigger and '/ui/main/shared/concept_art/' .. string.lower(trigger.entityName) .. '_default.jpg') or "")
	updateHeroInfo(getSelected())
	
	-- show/hide filter
	groupfcall('heroselect_filter_container_group', function(_, widget) fadeWidget(widget, not petSelection, 125) end)
	
	-- shop/hide selected
	local prefix = petSelection and 'pet' or ''
	
	groupfcall('main_pregame_hero'..prefix..'_selected_group', function(_, widget) 
		fadeWidget(widget, widget:GetName() == "main_pregame_hero_".. prefix .. getSelected() .."_selected", 125)
	end)
	
	groupfcall('main_pregame_hero'..prefix..'_icon_selected_group', function(_, widget)
		widget:SetColor((widget:GetName() == "main_pregame_hero_".. prefix .. getSelected() .."_icon_selected") and '1 1 1 1' or '.7 .7 .7 .7' )
	end)
end

showSelected()

local toBeSelected = -1

local function selectHero(hero, dontProgress)
	if not canSelectHero() then
		toBeSelected = hero
		return
	end
	
	if petSelection then
		if not LuaTrigger.GetTrigger('HeroSelectFamiliarList'..hero).selectable then return end
		selectedPet = hero
		Corral.SelectPetSlot(selectedPet)
		SpawnFamiliar(LuaTrigger.GetTrigger('HeroSelectFamiliarList'..hero).entityName, 'default')
		actuallySelectedPet = true
	else
		local trigger = LuaTrigger.GetTrigger('HeroSelectHeroList'..hero)
		if not trigger.canSelect then return end
		selectedHero = hero
		SelectHero(trigger.entityName)
		PlaySound(trigger['heroSelectAnnouncement'], 1, 3, 0)
		heroEntityName = trigger.entityName
		actuallySelectedHero = true
	end
	
	if (not dontProgress) then
	
		widget.main_pregame_sync_container:FadeIn(3000)
		if not petSelection then -- Move to pet screen
			if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_hero_select.wav') end
			petSelectButtonClick()
			-- client feedback
			triggerVarChangeOrFunction('HeroSelectLocalPlayerInfo', 'heroEntityName', LuaTrigger.GetTrigger('HeroSelectHeroList'..hero).entityName, 3000, 'selectHero', function()
				actuallySelectedHero = false -- Failed to pick hero!
				actuallySelectedPet = false
				heroSelectButtonClick()
				widget.main_pregame_sync_container:FadeOut(50)
			end, function()
				widget.main_pregame_sync_container:FadeOut(50)
			end)
		else
			if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_pet_select.wav') end
			initCustomized() -- Move to customized screen
			triggerVarChangeOrFunction('HeroSelectLocalPlayerInfo', 'petEntityName', LuaTrigger.GetTrigger('HeroSelectFamiliarList'..hero).entityName, 3000, 'selectPet', function()
				actuallySelectedPet = false -- Failed to pick pet!
				if (state > 2) then
					petSelectButtonClick()
				end
				widget.main_pregame_sync_container:FadeOut(50)
			end, function()
				widget.main_pregame_sync_container:FadeOut(50)
			end)
		end
	end
end

local function hoverHero(hero)
	if state > 2 then return end
	
	populateAbilities(hero)
	populateStats(hero)
	
	local trigger = LuaTrigger.GetTrigger(((petSelection and 'HeroSelectFamiliarList') or 'HeroSelectHeroList')..hero)
	
	updateSplash('/ui/main/shared/concept_art/' .. string.lower(trigger.entityName) .. '_default.jpg')
	updateHeroInfo(hero)
	
	local prefix = petSelection and 'pet' or ''
	
	groupfcall('main_pregame_hero'..prefix..'_selected_group', function(_, widget) 
		fadeWidget(widget, widget:GetName() == "main_pregame_hero_".. prefix .. hero .."_selected", 125)
	end)
	
	groupfcall('main_pregame_hero'..prefix..'_icon_selected_group', function(_, widget)
		widget:SetColor((widget:GetName() == "main_pregame_hero_".. prefix .. hero .."_icon_selected") and '1 1 1 1' or '.7 .7 .7 .7' )
	end)
end

local lastValidSkin, lastValidDye, lastValidPetSkin

---------------------------
------- Create hero widgets
---------------------------
local divisionSlates = {
	provisional = '',
	slate = '/ui/main/pregame/textures/ranked_slate.tga',
	bronze = '/ui/main/pregame/textures/ranked_bronze.tga',
	silver = '/ui/main/pregame/textures/ranked_silver.tga',
	gold = '/ui/main/pregame/textures/ranked_gold.tga',
	platinum = '/ui/main/pregame/textures/ranked_platinum.tga',
	diamond = '/ui/main/pregame/textures/ranked_diamond.tga'
}

local function getHeroRank(trigger)
	local rank = mainUI and mainUI.progression and mainUI.progression.stats and mainUI.progression.stats.heroes and mainUI.progression.stats.heroes[trigger.entityName] and mainUI.progression.stats.heroes[trigger.entityName]['rank']
	return rank
end

local function getHeroDivision(trigger)
	local division = mainUI and mainUI.progression and mainUI.progression.stats and mainUI.progression.stats.heroes and mainUI.progression.stats.heroes[trigger.entityName] and mainUI.progression.stats.heroes[trigger.entityName]['ranked_division']
	return division
end

local function getHeroBacking(trigger)
	if (LuaTrigger.GetTrigger('selectModeInfo').queuedMode == 'ranked') then
		local division = getHeroDivision(trigger)
		if (not division) then return '' end
		return divisionSlates[division]
	else
		local rank = getHeroRank(trigger)
		if (not rank) then return '' end
		rank = math.floor(rank)
		return rank >= 5 and '/ui/shared/textures/account_icons/hp_mastered.tga' or ''
	end
end

local function WhoPickedThatHero(trigger)
	if (trigger.canSelect) then return nil end
	for playerIndex = 0, 3, 1 do
		local heroInfo = LuaTrigger.GetTrigger((isLobby and 'HeroSelectPlayerInfo' or 'PartyPlayerInfo') .. playerIndex)
		if (heroInfo) and (heroInfo.heroEntityName == trigger.entityName) then
			return heroInfo -- player trigger
		end
	end
	return nil
end

local function SelectRandomHeroFromFilter()
	local eligibleTable = {}
	local role = lastRole
	for n = 0, #heroWidgets do
		if (heroWidgets[n] ~= randomWidget and (role == 0 or mainUI.Pregame.heroRoleTable[n][role] > minHeroRoleValue and LuaTrigger.GetTrigger('HeroSelectHeroList'..n).canSelect)) then
			table.insert(eligibleTable, n)
		end
	end
	selectHero(eligibleTable[math.random(1, #eligibleTable)])
end

local destroyPetWidgets
local populatePetList

local function populateHeroList()
	if (#main_pregame_heros_container:GetChildren() > 0) then return end
	main_pregame_heros_container:ClearChildren()
	local tileWidth = getMeasurementFromString(main_pregame_heros_container, '90s')
	heroWidgets = createWidgetArrayFromTriggerSet(
		main_pregame_heros_container, 'main_pregame_hero_template', 'HeroSelectHeroList', 
		function(n, trigger) return trigger.isValid end,
		function(n, trigger)
			mainUI.Pregame.heroRoleTable[n] = {trigger.heroRoleCC, trigger.heroRoleMagDamage, trigger.heroRolePhysDamage, trigger.heroRoleSurvival, trigger.heroRoleUtility}
			local heroBacking = getHeroBacking(trigger)
			local whoPicked = WhoPickedThatHero(trigger)
			return {
				'HeroName', trigger.displayName, 
				'icon', trigger.iconPath, 
				'index', n, 
				'frameTexture', heroBacking,
				'hasFrame', tostring(heroBacking ~= ''),
				'pickedVisible', tostring(not trigger.canSelect),
				'pickedBy', (whoPicked and whoPicked.playerName) or '',
				'isNew', tostring(isNewHero(trigger.entityName)),
				'x', n*tileWidth
			} end,
		true,
		{
			onclick = function(n, trigger) selectHero(n) end, 
			onmouseover = function(n, trigger) hoverHero(n) end, 
			onmouseout = function(n, trigger) showSelected() end,
			onmousewheelup   = function(n, trigger) updateHeroSlider(-wheelScrollSpeed, nil, true) end,
			onmousewheeldown = function(n, trigger) updateHeroSlider( wheelScrollSpeed, nil, true) end,
		}
	)
	
	local function checkPicked(n)
		-- Check if spectating
		if (LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo').teamID == -1) then
			interface:GetWidget('main_pregame_hero_'..n..'_picked'):SetVisible(true)
			interface:GetWidget('main_pregame_hero_'..n..'_picked2'):SetText(Translate('pregame_select_Currently'))
			interface:GetWidget('main_pregame_hero_'..n..'_pickedBy'):SetText(Translate('pregame_select_Spectating'))
			return
		end
		-- Check if someone has the hero
		local trigger = LuaTrigger.GetTrigger('HeroSelectHeroList'..n)
		interface:GetWidget('main_pregame_hero_'..n..'_picked'):SetVisible(not trigger.canSelect)
		if (trigger.canSelect) then return end
		local whoPicked = WhoPickedThatHero(trigger)
		local pickedByString = (whoPicked and whoPicked.playerName) or ''
		interface:GetWidget('main_pregame_hero_'..n..'_picked2'):SetText(pickedByString == "" and "" or Translate('pregame_select_SelectedBy'))
		interface:GetWidget('main_pregame_hero_'..n..'_pickedBy'):SetText(pickedByString)
	end
	
	for n, _ in pairs(heroWidgets) do
		interface:GetWidget('main_pregame_hero_'..n..'_picked'):RegisterWatchLua('HeroSelectHeroList'..n, function(widget, trigger)
			checkPicked(n)
		end, false, nil, 'canSelect')
		
		interface:GetWidget('main_pregame_hero_'..n..'_picked'):RegisterWatchLua('HeroSelectLocalPlayerInfo', function(widget, trigger)
			checkPicked(n)
		end, false, nil, 'teamID')
		checkPicked(n)
	end
	if (#heroWidgets > 0) then
		randomWidget = main_pregame_heros_container:InstantiateAndReturn('main_pregame_hero_template'
			,'HeroName', Translate('heroselect_random')
			,'icon', '/ui/main/postgame/rewards/visuals/doors/question.tga'
			,'index', #heroWidgets+1
			,'x', #heroWidgets*tileWidth
			)[1]
		randomWidget:SetCallback('onclick', function(widget)
			SelectRandomHeroFromFilter()
		end)
		randomWidget:SetCallback('onmouseover', function(widget)
			updateSplash("/ui/main/shared/concept_art/hero_random.jpg")
			updateHeroInfo(-1)
			populateAbilities(-1)
			groupfcall('main_pregame_hero_selected_group', function(_, widget)
				fadeWidget(widget, widget:GetName() == "main_pregame_hero_"..  #heroWidgets .."_selected", 125)
			end)
			groupfcall('main_pregame_hero_icon_selected_group', function(_, widget)
				widget:SetColor((widget:GetName() == "main_pregame_hero_"..  #heroWidgets .."_icon_selected") and '1 1 1 1' or '.7 .7 .7 .7' )
			end)
		end)
		randomWidget:SetCallback('onmouseout', function(widget)
			showSelected()
		end)
	
		table.insert(heroWidgets, randomWidget)
	end
	
	GetWidget('main_pregame_scroll_catcher'):SetCallback('onmousewheelup', function(widget)
		updateHeroSlider(-wheelScrollSpeed, nil, true)
	end)	
	GetWidget('main_pregame_scroll_catcher'):SetCallback('onmousewheeldown', function(widget)
		updateHeroSlider(wheelScrollSpeed, nil, true)
	end)	
	
	if (mainUI.Pregame.populateHeroListThread) then
		mainUI.Pregame.populateHeroListThread:kill()
		mainUI.Pregame.populateHeroListThread = nil
	end
	
	mainUI.Pregame.populateHeroListThread = libThread.threadFunc(function() -- when loading, this needs some time to populate the triggers
		wait(1000)
		for n, w in pairs(heroWidgets) do
			if (w ~= randomWidget) then
				local widget = interface:GetWidget('main_pregame_hero_'..n..'_pickedBy')
				if (widget) then
					whoPicked = WhoPickedThatHero(LuaTrigger.GetTrigger('HeroSelectHeroList'..n))
					local pickedByString = (whoPicked and whoPicked.playerName) or ''
					widget:GetWidget('main_pregame_hero_'..n..'_picked2'):SetText(pickedByString == "" and "" or Translate('pregame_select_SelectedBy'))
					widget:GetWidget('main_pregame_hero_'..n..'_pickedBy'):SetText(pickedByString)
				end
			end
		end
		mainUI.Pregame.populateHeroListThread = nil
	end)
	
	updateHeroSlider(0, true)
	
	
	-- update pets too
	libThread.threadFunc(function()
		destroyPetWidgets()
		populatePetList(true)
	end)
	
end

---------------------------
------- Create pet widgets
--------------------------
destroyPetWidgets = function()
	if (petWidgets) and (#petWidgets > 0) then
		for n = 0, #petWidgets do
			if (petWidgets[n]) and (petWidgets[n]:IsValid()) then
				petWidgets[n]:Destroy()
			end
		end
		petWidgets = {}
		wait(1)
	end
end

local function petWidgetsValid()
	if (#petWidgets == 0) then return false end
	for i,v in pairs(petWidgets) do
		if not (v and v:IsValid()) then return false end
	end
	return true
end

populatePetList = function(force)
	local tileWidth = getMeasurementFromString(main_pregame_heros_container, '90s')
	if (mainUI.Pregame.populatePetListThread) then
		mainUI.Pregame.populatePetListThread:kill()
		mainUI.Pregame.populatePetListThread = nil
	end
	if (petWidgetsValid() and not force) then return end
	mainUI.Pregame.populatePetListThread = libThread.threadFunc(function()
		destroyPetWidgets()
		petWidgets = createWidgetArrayFromTriggerSet(
			main_pregame_heros_container, 'main_pregame_hero_template', 'HeroSelectFamiliarList', 
			function(n, trigger) return trigger.entityName ~= "" end,
			function(n, trigger) return {
				'HeroName', GetEntityDisplayName(trigger['entityName']), 
				'icon', trigger.evolutionIcon1, 
				'x', n*tileWidth,
				'index', n, 
				'prefix', 'pet', 
				'visible', tostring(petSelection), 
				'isLocked', tostring(not trigger.selectable)
			} end,
			false,
			{
				onclick = function(n, trigger) selectHero(n) end, 
				onmouseover = function(n, trigger) hoverHero(n) end, 
				onmouseout = function(n, trigger) showSelected(n) end,
				onmousewheelup   = function(n, trigger) updateHeroSlider(-wheelScrollSpeed, nil, true) end,
				onmousewheeldown = function(n, trigger) updateHeroSlider( wheelScrollSpeed, nil, true) end,
			}
		)
		wait(1)
		applyHeroFilter()
		mainUI.Pregame.populatePetListThread = nil
	end)
	
	-- Select the first selectable pet
	setSelectedToFirstSelectablePet()
end

---------------------------
------- Toggle grid view
---------------------------
local function toggleGridView(justUpdate)
	if not justUpdate then
		isGridView = not isGridView
	
		if (petSelection) then
			if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_pet_view.wav') end
		else
			if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_hero_view.wav') end
		end
	end
	
	fadeWidget(main_pregame_heros_slider_container_parent, not isGridView, 125)
	
	local widgetArray = (petSelection and petWidgets) or heroWidgets
	if (not widgetArray or #widgetArray <= 1) then return end
	local width = isGridView and tileSizes[1] or tileSizes[3]
	local height = isGridView and tileSizes[2] or tileSizes[4]
	for n = 0, #widgetArray do
		widgetArray[n]:SetWidth(width .. 's')
		widgetArray[n]:SetHeight(height .. 's')
	end
	
	local tileWidth = heroWidgets[0]:GetWidth()
	
	local xPos
	local yPos
	if (isGridView) then
		widget.main_pregame_hero_select_grad:FadeOut(125)
		heroselect_toggle_view:SetTexture("/ui/main/pregame/textures/filter_scroll.tga")
		main_pregame_heros_scroll_parent:SetVisible(0)
		main_pregame_hero_select_container:ScaleWidth(tileWidth*(numGridColumns+0.32), 125)
		main_pregame_hero_select_container:ScaleHeight('950s', 125)
		xPos = '298s'
		yPos = (-height+20) * (#widgetArray/numGridColumns) - 40 .. 's'
	else
		widget.main_pregame_hero_select_grad:FadeIn(125)
		heroselect_toggle_view:SetTexture("/ui/main/pregame/textures/attribute_grid.tga")
		main_pregame_heros_scroll_parent:SetVisible(1)
		main_pregame_hero_select_container:ScaleWidth('100%', 125)
		main_pregame_hero_select_container:ScaleHeight('220s', 125)
		xPos = '0s'
		yPos = '0s'
		updateHeroSlider(0, true)
	end

	main_pregame_hero_select_container:SlideX(xPos, 125)
	main_pregame_hero_select_container:SlideY(yPos, 125)
	thread = libThread.threadFunc(function()
		wait(125)
		main_pregame_hero_select_container:SetX(xPos)
		main_pregame_hero_select_container:SetY(yPos)
	end)
	
	-- Organize the portraits
	applyHeroFilter()
end
heroselect_toggle_view:SetCallback('onclick', function(widget)
	toggleGridView()
end)

---------------------------
------- Quick Pick Hero
---------------------------

mainUI.neededRole = nil
mainUI.neededRoleIndex = nil

function QuickPickHero()
	-- Get the hero we need
	if (mainUI.neededRole) and (mainUI.neededRoleIndex) and (mainUI.Pregame.heroRoleTable) then
		local heroesTable = {}
		local recommendedHero = -1
		local highestRole = -1
		local minimum = 4
		for n = 0, #mainUI.Pregame.heroRoleTable do
			-- printr(mainUI.Pregame.heroRoleTable[n])
			local role = mainUI.Pregame.heroRoleTable[n][mainUI.neededRoleIndex]
			if (role) and (role > minimum) and LuaTrigger.GetTrigger('HeroSelectHeroList' .. n).canSelect and (LuaTrigger.GetTrigger('HeroSelectHeroList' .. n).isValid) and (LuaTrigger.GetTrigger('HeroSelectHeroList' .. n).teamName == 'final')  then
				table.insert(heroesTable, n)
			end
		end
		printr(heroesTable)
		if (heroesTable) and (#heroesTable > 0) then
			local randomHeroIndex = math.random(1, #heroesTable)
			local randomHero = heroesTable[randomHeroIndex]
			local heroEntity = LuaTrigger.GetTrigger('HeroSelectHeroList' .. randomHero).entityName
			if (heroEntity) then
				SelectHero(heroEntity)
				selectHero(randomHero)
				
				for index = 0, mainUI.maxPetSlots, 1 do
					local petInfoTrigger = LuaTrigger.GetTrigger('HeroSelectFamiliarList'..index)
					if (petInfoTrigger) and (petInfoTrigger.selectable) then
						petSelection = true
						SpawnFamiliar(petInfoTrigger.entityName, 'default')
						selectHero(index)
						break
					end
				end		
			end
		end
		mainUI.neededRole = nil
		mainUI.neededRoleIndex = nil		
	end
end

function QueueQuickPickHero(neededRole, neededRoleIndex)
	mainUI.neededRole = neededRole
	mainUI.neededRoleIndex = neededRoleIndex
end

---------------------------
------- Recommended Hero Functions
---------------------------
local teamComposition1 = LuaTrigger.GetTrigger('teamComposition1') or LuaTrigger.CreateGroupTrigger(
	'teamComposition1',	{'HeroSelectPlayerInfo0', 'HeroSelectPlayerInfo1', 'HeroSelectPlayerInfo2', 'HeroSelectPlayerInfo3', 'HeroSelectPlayerInfo4', 'HeroSelectLocalPlayerInfo'}
)
local teamComposition2 = LuaTrigger.GetTrigger('teamComposition2') or LuaTrigger.CreateGroupTrigger(
	'teamComposition2',	{'HeroSelectPlayerInfo5','HeroSelectPlayerInfo6','HeroSelectPlayerInfo7','HeroSelectPlayerInfo8','HeroSelectPlayerInfo9','HeroSelectLocalPlayerInfo'}
)
local function InitRecommendedHero(object, container)
	local heroRoleTypes = { 'CC', 'MagDamage', 'PhysDamage', 'Survival', 'Utility' }
	main_pregame_sleeper:UnregisterWatchLua('Team')
	main_pregame_sleeper:RegisterWatchLua('Team', function(widget, trigger)
		local teamID	= trigger.team <= 10 and trigger.team or 1

		if teamID == 1 or teamID == 2 then
			widget:UnregisterWatchLua('teamComposition'..teamID)
			widget:RegisterWatchLua('teamComposition'..teamID, function(widget, groupTrigger)
				-- Exit if not loaded yet
				if #mainUI.Pregame.heroRoleTable == 0 then return end
			
				local HeroSelectLocalPlayerInfo_trigger = groupTrigger[6]
				local roleInfoTrigger	= nil
				local teamInfo	= {groupTrigger[1],groupTrigger[2],groupTrigger[3],groupTrigger[4],groupTrigger[5],	--[[ groupTrigger[6] ]] }

				-- Get ally role values
				local heroSelectAllyRoleTable	= {}
				for k,v in ipairs(heroRoleTypes) do
					heroSelectAllyRoleTable[k]	= {role = v, value = 0}
					for j,l in ipairs(teamInfo) do
						if l.isTeammate then
							heroSelectAllyRoleTable[k].value = heroSelectAllyRoleTable[k].value + l['heroRole'..v]
						end
					end
				end
				
				-- Get the role we need
				local minimum = 9999999
				local neededRole = -1
				local maximum = -1
				for k,v in pairs(heroSelectAllyRoleTable) do
					if v.value < minimum then
						neededRole = k
						minimum = v.value
					end
					maximum = math.max(maximum, v.value)
				end
				
				-- Get the hero we need
				if (mainUI.Pregame.heroRoleTable) then
					local recommendedHero = -1
					local highestRole = -1
					for n = 0, #mainUI.Pregame.heroRoleTable do
						local role = mainUI.Pregame.heroRoleTable[n][neededRole]
						if role > highestRole and LuaTrigger.GetTrigger('HeroSelectHeroList' .. n).canSelect and (LuaTrigger.GetTrigger('HeroSelectHeroList' .. n).isValid) and (LuaTrigger.GetTrigger('HeroSelectHeroList' .. n).teamName == 'final') then
							recommendedHero = n
							highestRole = role
							-- If the best role is unknown, say first pick-able hero
							if (maximum == 0) then break end
						end
					end
					
					-- Show recommended hero
					groupfcall('main_pregame_hero_recommended_group', function(_, widget) 
						fadeWidget(widget, widget:GetName() == "main_pregame_hero_".. recommendedHero .."_recommended", 125)
					end)
					
					if (selectedHero == -1) then
						selectedHero = recommendedHero
						showSelected()
					end
					
					QuickPickHero()
					
				else
					SevereError('Recommended Hero heroRoleTable empty : ' .. tostring(neededHero), 'main_reconnect_thatsucks', '', nil, nil, nil)
				end
			end)
		end
	end)
end
InitRecommendedHero()

---------------------------
------- Trigger populating functions
---------------------------
main_pregame_sleeper:RegisterWatchLua('HeroSelectHeroList0', function(widget, trigger)
	if (trigger.isValid) then
		main_pregame_sleeper:UnregisterWatchLua('HeroSelectHeroList0')
		libThread.threadFunc(function()
			wait(10)
			populateHeroList()
			populatePetList()
			applyHeroFilter(0)
			teamComposition1:Trigger()
			teamComposition2:Trigger()
			toggleGridView(true)
		end)
	end
end, false, nil, 'isValid')

local reloadPetsThread
local function QueuePetReload()
	if (reloadPetsThread and reloadPetsThread:IsValid()) then
		reloadPetsThread:kill()
		reloadPetsThread = nil
	end
	reloadPetsThread = libThread.threadFunc(function()
		wait(1)
		populatePetList(true)
		local curPet = LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo').petEntityName
		if (selectedPet >= 0 and LuaTrigger.GetTrigger('HeroSelectFamiliarList'..selectedPet).entityName ~= curPet) then
			local newIndex = findPetFromEntityName(curPet)
			if (newIndex >= 0) then
				selectedPet = newIndex
			end
		end
	end)
end

for n = 0, mainUI.maxPetSlots do
	local petInfoTrigger = LuaTrigger.GetTrigger('HeroSelectFamiliarList'..n)
	if (petInfoTrigger) then
		main_pregame_sleeper:RegisterWatchLua('HeroSelectFamiliarList'..n, function(widget, trigger)
			QueuePetReload()
		end)
	end
end

-- Populate hero/pets on reload
main_pregame_sleeper:RegisterWatchLua('HeroSelectLocalPlayerInfo', function(widget, trigger)
	main_pregame_sleeper:UnregisterWatchLua('HeroSelectLocalPlayerInfo')
		
	local function findHeroFromEntityName(entityName)
		return findIndexFromTriggerArray('HeroSelectHeroList', function(n, trigger) return trigger.isValid end, 'entityName', entityName)
	end	
	
	libThread.threadFunc(function()
		wait(1)
		println("isReload: "..tostring(isReload))
		if (not isReload) then
			InitSelectionTriggers()
			heroSelectButtonClick()
			
			wait(100)
			if (not LuaTrigger.GetTrigger('PartyStatus').inParty) then
				local triggerPanelStatus = LuaTrigger.GetTrigger('mainPanelStatus')
				triggerPanelStatus.main	= mainUI.MainValues.news
				triggerPanelStatus:Trigger(true)
			end
			
			return false
		end
		
		local heroSet = false
		if (trigger.heroEntityName ~= '' and not actuallySelectedHero) then
			actuallySelectedHero = true
			selectedHero = findHeroFromEntityName(trigger.heroEntityName)
			heroEntityName = trigger.heroEntityName
			println('Found hero to be '..selectedHero)
			heroSet = true
		end
		if (trigger.petEntityName ~= '' and not actuallySelectedPet) then
			actuallySelectedPet = true
			selectedPet = findPetFromEntityName(trigger.petEntityName)
			println('Found pet to be '..selectedPet)
			CustomizeSelectButtonClick()
		elseif (heroSet) then
			petSelectButtonClick()
		end
	end)
end, false, nil, 'heroEntityName', 'petEntityName')

-- ================================================================
-- ======================= Customization ==========================
-- ================================================================
-- Functions to be referenced before initialization
local readyButtonCheck
local populateSkins
local selectDye
local selectSkin
local selectPetSkin
local initPetSkins
local initHeroModels
local showSkin
-- Variabled
local isLobby = false
---------------------------
------- Gem purchase
---------------------------
local purchaseInfo = {}

local function refreshAfterPurchase()
	println('refreshAfterPurchase')
	main_pregame_customization_ready:SetEnabled(1)
	purchaseInfo = {}
	local dye = selectedDye
	local skin = selectedSkin
	populateSkins()
	selectSkin(skin)
	selectDye(dye)
	PlaySound('/ui/sounds/pets/sfx_unlock.wav')
	initPetSkins()
end

local function purchasePetSkin(selectedPet, selectedPetSkin)
	println('^o^: Purchase Pet Skin From Prematch')
	println('selectedPet ' .. selectedPet)
	println('selectedPetSkin ' .. selectedPetSkin)
	local petInfo 				= 	LuaTrigger.GetTrigger('HeroSelectFamiliarList'..selectedPet)
	
	main_pregame_customization_ready:SetEnabled(0)
	main_pregame_customization_ready:UnregisterWatchLua('GameClientRequestsUnlockPetSkin')
	main_pregame_customization_ready:RegisterWatchLua('GameClientRequestsUnlockPetSkin', function(widget, requestStatusTrigger)
			if (requestStatusTrigger.status > 1) then
				mainUI.RefreshProducts(
					function()
						mainUI.savedRemotely 													= mainUI.savedRemotely 									or {}
						mainUI.savedRemotely.petBuilds 											= mainUI.savedRemotely.petBuilds 						or {}
						mainUI.savedRemotely.petBuilds[petInfo.entityName]						= mainUI.savedRemotely.petBuilds[petInfo.entityName] 	or {}
						mainUI.savedRemotely.petBuilds[petInfo.entityName].default_petSkin 		= petInfo['skinName' .. selectedPetSkin]
						mainUI.savedRemotely.petBuilds[petInfo.entityName].default_petSkinIndex	= selectedPetSkinIndex
						SaveState()								
					
						main_pregame_customization_ready:SetEnabled(1)
						println('^g RefreshProducts GameClientRequestsUnlockPetSkin')
						PlaySound('/ui/sounds/pets/sfx_unlock.wav')
						main_pregame_pet_selection_container:SetVisible(false)
						refreshAfterPurchase()
					end
				)
				main_pregame_customization_ready:UnregisterWatchLua('GameClientRequestsUnlockPetSkin')
			end
	end)
	Corral.PurchasePetSkin(petInfo.entityName, petInfo['skinName' .. selectedPetSkin])
	println("Corral.PurchasePetSkin(" .. petInfo.entityName ..", "..petInfo['skinName' .. selectedPetSkin]..")")
end

local function promptToPurchasePetSkin(selectedPet, selectedPetSkin)
	local petInfo 				= 	LuaTrigger.GetTrigger('HeroSelectFamiliarList'..selectedPet)
	if (petInfo) then	
		spendGemsShow(
			function()
				purchasePetSkin(selectedPet, selectedPetSkin)
				main_pregame_pet_selection_container:SetVisible(false)
			end,
			Translate('pet_skin_name_unlock'), 
			TranslateOrNil('pet_skin_name_' .. petInfo.entityName .. '_' .. petInfo['skinName' .. selectedPetSkin]) or GetEntityDisplayName(petInfo.entityName),
			petInfo['skinCost' .. selectedPetSkin], 
			function() loadLastValidCosmeticConfig() main_pregame_pet_selection_container:SetVisible(false) end
		)	
	end
end

local function purchaseSkin(postFunction, hero, name)
	local skinTrigger = LuaTrigger.GetTrigger('HeroSelectHeroAltAvatarList'..selectedSkin)
	main_pregame_customization_ready:SetEnabled(0)
	main_pregame_customization_ready:UnregisterWatchLua('GameClientRequestsUnlockGearSet')
	main_pregame_customization_ready:RegisterWatchLua('GameClientRequestsUnlockGearSet', function(widget, requestStatusTrigger)
		if (requestStatusTrigger.status > 1) then
			mainUI.RefreshProducts(function()
				postFunction()
				main_pregame_dye_selection_container:SetVisible(false)
			end)
			main_pregame_customization_ready:UnregisterWatchLua('GameClientRequestsUnlockGearSet')
		end
		println('GameClientRequestsUnlockGearSet.status ' .. tostring(requestStatusTrigger.status))
	end)
	println('^o GearDatabase.UnlockGearSetWithGems | ' .. tostring(skinTrigger.parentHero) .. ' | ' .. tostring(skinTrigger.name) .. ' | renting: ' .. tostring(purchaseInfo.renting) )
	GearDatabase.UnlockGearSetWithGems(skinTrigger.parentHero, skinTrigger.name, purchaseInfo.renting)
end

local function purchaseDye(hero, set, name)
	local dyeTrigger = LuaTrigger.GetTrigger('HeroSelectHeroGearSkin'..selectedDye)
	main_pregame_customization_ready:UnregisterWatchLua('GameClientRequestsUnlockGearSet')
	main_pregame_customization_ready:RegisterWatchLua('GameClientRequestsUnlockGearSet', function(widget, requestStatusTrigger)
		if (requestStatusTrigger.status > 1) then
			mainUI.RefreshProducts(function()
				refreshAfterPurchase()
				main_pregame_dye_selection_container:SetVisible(false)
			end)
			main_pregame_customization_ready:UnregisterWatchLua('GameClientRequestsUnlockGearSet')
		end
		println('GameClientRequestsUnlockGearSet.status ' .. tostring(requestStatusTrigger.status))
	end)
	println('^o GearDatabase.UnlockDyeWithGems | ' .. tostring(dyeTrigger.parentHero) .. ' | ' .. tostring(dyeTrigger.parentGearSet) .. ' | ' .. tostring(dyeTrigger.name) .. ' | renting: ' .. tostring(purchaseInfo.renting) )
	GearDatabase.UnlockDyeWithGems(dyeTrigger.parentHero, dyeTrigger.parentGearSet, dyeTrigger.name, purchaseInfo.renting)
end

local function purchase(rent)
	purchaseInfo.renting = rent
	if (rent and purchaseInfo.purchasingDye and GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_hero_rent.wav') end
	
	if (purchaseInfo.purchasingDye and purchaseInfo.purchasingSkin) then
		purchaseSkin(purchaseDye)
	elseif(purchaseInfo.purchasingSkin) then
		purchaseSkin(refreshAfterPurchase)
	else
		purchaseDye()
	end
end

---------------------------
------- Ready Button
---------------------------

local readyStatus = {
	PURCHASE = 1,
	FORCE_REGION_SELECT = 2,
	UNREADY = 3,
	READY = 4,
	DBCONNECT = 5,
}
local function getReadyButtonStatus()
	if not (DatabaseLoadStateTrigger and DatabaseLoadStateTrigger.stateLoaded) then return readyStatus.DBCONNECT end -- Not connected to database yet
	local partyStatus = LuaTrigger.GetTrigger('PartyStatus')
	if (not partyStatus.inQueue and not partyStatus.isLocalPlayerReady) then -- get ready
		-- if (purchaseInfo.purchasingSkin or purchaseInfo.purchasingDye) then -- purchase
			-- return readyStatus.PURCHASE
		if isLeader() and not isLobby and (RegionSelect.numUserSelected() == 0 or not RegionSelect or not RegionSelect.seenRegions or not RegionSelect.seenRegions[getQueue()]) then
			return readyStatus.FORCE_REGION_SELECT
		else -- ready up
			return readyStatus.READY
		end
	else -- opt out
		return readyStatus.UNREADY
	end
end

local function updatePurchasePreview()
	
	local originalCost																= purchaseInfo.gemSaving + purchaseInfo.gemTotal
	local gemOffer 																	= LuaTrigger.GetTrigger('GemOffer')
	local currentGems																= gemOffer.gems
	
	-- Purchase
	local parent 																	= GetWidget('main_pregame_purchase_hero_cosmetic_product_purchase_option_parent')	
	local purchase_button 															= GetWidget('main_pregame_customization_purchase_dye_confirm')	
	local purchase_needgems_button 													= GetWidget('main_pregame_purchase_hero_cosmetic_product_needgems_btn_2')	
	local purchase_specialedition_button 											= GetWidget('main_pregame_purchase_hero_cosmetic_product_specialedition_btn_2')	
	local purchase_button_parent 													= GetWidget('main_pregame_purchase_hero_cosmetic_product_purchase_option_2')	
	
	purchase_button:SetCallback('onclick', function(widget)
		purchase(false)
	end)
	purchase_button:SetEnabled(((purchaseInfo.gemTotal >= 0)) or false)
	purchase_button_parent:SetVisible(((purchaseInfo.gemTotal >= 0)) or false)
	purchase_button:SetCallback('onmouseover', function(widget) UpdateCursor(widget, true, { canLeftClick = true, canRightClick = false, spendGems = true }) end)			
	purchase_button:SetCallback('onmouseout', function(widget) UpdateCursor(widget, false, { canLeftClick = true, canRightClick = false, spendGems = true }) end)			
	purchase_needgems_button:SetVisible(((purchaseInfo.gemTotal) and (currentGems) and (purchaseInfo.gemTotal > currentGems)) or false)
	purchase_specialedition_button:SetVisible(purchaseInfo.specialEditionSkin or purchaseInfo.specialEditionDye)

	-- Rental
	local rent_button 															= GetWidget('main_pregame_customization_rent_dye_confirm')	
	local rent_needgems_button 													= GetWidget('main_pregame_purchase_hero_cosmetic_product_needgems_btn_1')	
	local rent_specialedition_button 											= GetWidget('main_pregame_purchase_hero_cosmetic_product_specialedition_btn_1')	
	local rent_button_parent 													= GetWidget('main_pregame_purchase_hero_cosmetic_product_purchase_option_1')		
	
	if (purchaseInfo.gemRentTotal >= 1) and (not (purchaseInfo.specialEditionSkin or purchaseInfo.specialEditionDye)) then
		rent_button:SetCallback('onclick', function(widget)
			purchase(true)
		end)
		rent_button:SetEnabled((((purchaseInfo.gemRentTotal >= 0)) and (purchaseInfo.gemTotal and (purchaseInfo.gemRentTotal < purchaseInfo.gemTotal))) or false)
		rent_button_parent:SetVisible(1)
		rent_button:SetCallback('onmouseover', function(widget) UpdateCursor(widget, true, { canLeftClick = true, canRightClick = false, spendGems = true }) end)		
		rent_button:SetCallback('onmouseout', function(widget) UpdateCursor(widget, false, { canLeftClick = true, canRightClick = false, spendGems = true }) end)		
	else
		rent_button_parent:SetVisible(0)
	end
	rent_needgems_button:SetVisible(( (purchaseInfo.gemRentTotal) and (currentGems) and (purchaseInfo.gemRentTotal > currentGems)) or false)
	rent_specialedition_button:SetVisible(purchaseInfo.specialEditionSkin or purchaseInfo.specialEditionDye)

	local ownership_parent				= GetWidget('main_pregame_purchase_hero_cosmetic_product_ownership_parent')
	local ownership_label				= GetWidget('main_pregame_purchase_hero_cosmetic_product_ownership_label')
	local ownership_bar					= GetWidget('main_pregame_purchase_hero_cosmetic_product_ownership_bar')
	local ownership_bar_leader			= GetWidget('main_pregame_purchase_hero_remaining_duration_bar_new_leader')
	local ownership_tip					= GetWidget('main_pregame_purchase_hero_cosmetic_product_ownership_tip')
	
	-- Current Ownership
	if (originalCost) and (originalCost > 0) and (purchaseInfo.gemTotal) and (purchaseInfo.gemTotal >= 0) and (purchaseInfo.gemRentTotal >= 1) then
		local barWidth = math.min(100, math.max(0, (((originalCost-purchaseInfo.gemTotal)/originalCost)*100)))
		ownership_bar:SetWidth(barWidth .. '%')
		ownership_bar_leader:SetX(barWidth .. '%')
		ownership_parent:SetVisible(1)
		ownership_tip:SetVisible(1)
		ownership_label:SetText(Translate('hallofheroes_item_ownership', 'value', math.floor(barWidth) .. '%'))
	else
		ownership_parent:SetVisible(0)
		ownership_tip:SetVisible(0)
	end
	
end

local function updatePetPreviewPurchaseButton()
    local originalCost																= purchaseInfo.gemSaving + purchaseInfo.gemTotal
    local gemOffer 																	= LuaTrigger.GetTrigger('GemOffer')
    local currentGems																= gemOffer.gems

	local button = GetWidget('main_pregame_customization_purchase_pet_confirm')
	local label = GetWidget('main_pregame_customization_purchase_pet_confirmLabel')
    local needgems_button = GetWidget('main_pregame_purchase_pet_cosmetic_product_needgems_btn_2')
	
	if (purchaseInfo.purchasingPetSkin) then
		label:SetText(Translate('hallofheroes_unlock'))
		button:SetCallback('onclick', function() 
			purchasePetSkin(selectedPet, selectedPetSkin)
		end)
	else
		label:SetText(Translate('general_select'))
		button:SetCallback('onclick', function() GetWidget('main_pregame_pet_selection_container'):FadeOut(125) end)		
	end	
    needgems_button:SetVisible(((purchaseInfo.gemTotal) and (currentGems) and (purchaseInfo.gemTotal > currentGems)) or false)
end

local function updateHowToViewButton(heroTrigger)
	if (heroTrigger) then
		local streamsTable = {}
		
		local heroIndex = 1
		
		for heroIndex = 1,100,1 do
			local getLinkString = TranslateOrNil('watch_hero_howto_link_' .. heroIndex)
			if (getLinkString) then
				local linkTable = explode('|', getLinkString)
				if (linkTable[1]) and (not Empty(linkTable[1])) then
					table.insert(streamsTable, {linkTable[1], linkTable[2]})
				end
			else
				break
			end
		end
		
		local url, entity
		for i,streamTable in pairs(streamsTable) do
			if (streamTable[1]) and (not Empty(streamTable[1])) and ValidateEntity(streamTable[1]) and (streamTable[1] == heroTrigger.entityName) and (streamTable[2]) and (not Empty(streamTable[2])) then
				url = "https://www.youtube.com/embed/".. tostring(streamTable[2]) .. "?autohide=1&amp;autoplay=1&amp;controls=2&amp;fs=0&amp;modestbranding=1&amp;rel=0&amp;showinfo=0"	
				entity = streamTable[1]
				break
			end
		end
		
		if (url) and (entity) then
			GetWidget('main_pregame_customization_watch_label'):SetText(Translate('general_playing') .. ' ' .. GetEntityDisplayName(entity) .. '?')
			GetWidget('main_pregame_customization_watch_container'):SetVisible(1)
			GetWidget('main_pregame_customization_watch'):SetCallback('onclick', function(widget)
				-- main_pregame_how_to_container:FadeIn(250)
				-- main_pregame_how_to_browser_container:SetVisible(false)
				-- main_pregame_how_to_browser:WebBrowserLoadURL(url)
				-- libThread.threadFunc(function()
					-- wait(800)
					-- main_pregame_how_to_browser_container:FadeIn(500)
				-- end)
				libThread.threadFunc(function()
					wait(1)				
					local triggerPanelStatus = LuaTrigger.GetTrigger('mainPanelStatus')
					triggerPanelStatus.launcherMusicEnabled = false
					triggerPanelStatus:Trigger(false)				
					mainUI.OpenURLInLauncher(url)
				end)
			end)
			main_pregame_how_to_container:SetCallback('onclick', function(widget) 
				main_pregame_how_to_browser:WebBrowserStop()
				main_pregame_how_to_browser:WebBrowserClose()
				main_pregame_how_to_container:FadeOut(250)
				local triggerPanelStatus = LuaTrigger.GetTrigger('mainPanelStatus')
				triggerPanelStatus.launcherMusicEnabled = mainUI.savedRemotely.launcherMusicEnabled
				triggerPanelStatus:Trigger(false)					
			end)			
		else
			GetWidget('main_pregame_customization_watch_label'):SetText('')
			GetWidget('main_pregame_customization_watch_container'):SetVisible(0)
		end
	else
		GetWidget('main_pregame_customization_watch_label'):SetText('')
		GetWidget('main_pregame_customization_watch_container'):SetVisible(0)
	end
end	
	

isQueueCountLoopRunning = false
readyButtonCheck = function()
	libThread.threadFunc(function()
		wait(1) -- wait for triggers to update
		local heroTrigger = LuaTrigger.GetTrigger('HeroSelectHeroList'..selectedHero)
		local petTrigger = LuaTrigger.GetTrigger('HeroSelectFamiliarList'..selectedPet)
		local skinTrigger = LuaTrigger.GetTrigger('HeroSelectHeroAltAvatarList'..selectedSkin)
		local dyeTrigger = LuaTrigger.GetTrigger('HeroSelectHeroGearSkin'..selectedDye)

		local heroOk = heroTrigger and heroTrigger.canSelect
		local petOk = petTrigger and petTrigger.selectable and petTrigger['skinOwned'..selectedPetSkin]
		local skinOk = skinTrigger and skinTrigger.canSelect
		local dyeOk = dyeTrigger and dyeTrigger.canSelect
		
		--println(tostring(selectedHero)..' '..tostring(selectedPet)..' '..tostring(selectedSkin)..' '..tostring(selectedDye))
		--println(tostring(heroOk)..' '..tostring(petOk)..' '..tostring(skinOk)..' '..tostring(dyeOk))
		
		main_pregame_customization_ready:SetEnabled((heroOk and petOk) or false)
		-- main_pregame_customization_undo:SetVisible((not (heroOk and petOk and skinOk and dyeOk)) or false)
		
		purchaseInfo.purchaseString = ""
		purchaseInfo.gemTotal = 0
		purchaseInfo.gemRentTotal = 0
		purchaseInfo.gemSaving = 0
		purchaseInfo.purchasingSkin = not skinOk
		purchaseInfo.purchasingDye = not dyeOk
		purchaseInfo.purchasingPetSkin = (not petOk)
		purchaseInfo.renting = false
		purchaseInfo.title = nil
		purchaseInfo.specialEditionSkin = false
		purchaseInfo.specialEditionDye = false
		if (not skinOk) and skinTrigger then
			purchaseInfo.specialEditionSkin = (skinTrigger.gemCost == 0)
			purchaseInfo.gemTotal = purchaseInfo.gemTotal + skinTrigger.gemCost
			purchaseInfo.gemRentTotal = purchaseInfo.gemRentTotal + skinTrigger.rentalGemCost
			purchaseInfo.gemSaving = purchaseInfo.gemSaving + skinTrigger.gemCostReduction
			purchaseInfo.purchaseString = purchaseInfo.purchaseString .. skinTrigger.displayName
			purchaseInfo.title = 'hallofheroes_gearset'
		end
		if (not dyeOk) and dyeTrigger then
			purchaseInfo.specialEditionDye = (dyeTrigger.gemCost == 0)
			purchaseInfo.gemTotal = purchaseInfo.gemTotal + dyeTrigger.gemCost
			purchaseInfo.gemRentTotal = purchaseInfo.gemRentTotal + dyeTrigger.rentalGemCost
			purchaseInfo.gemSaving = purchaseInfo.gemSaving + dyeTrigger.gemCostReduction
			purchaseInfo.purchaseString = purchaseInfo.purchaseString .. " " .. dyeTrigger.displayName
			if (skinOk) then
				purchaseInfo.title = 'hallofheroes_unlockskin'
			else
				purchaseInfo.title = 'hallofheroes_bothset'
			end
		end
		if (skinOk) and (dyeOk) and (not petOk) and petTrigger then
			purchaseInfo.gemTotal = petTrigger.gemCost
			purchaseInfo.purchaseString = TranslateOrNil('pet_skin_name_' .. petTrigger.entityName .. '_' .. petTrigger['skinName' .. selectedPetSkin]) or GetEntityDisplayName(petTrigger.entityName)
			purchaseInfo.title = 'pet_skin_name_unlock_short'
		end		
		
		updatePurchasePreview()
		updatePetPreviewPurchaseButton()
		updateHowToViewButton(heroTrigger)
		
		local status = getReadyButtonStatus()
		if (status == readyStatus.DBCONNECT) then
			main_pregame_customization_readyLabel:SetText(Translate('error_could_not_connect_to_local_database'))		
		elseif (status == readyStatus.PURCHASE) then
			main_pregame_customization_readyLabel:SetText(Translate(purchaseInfo.title))
		elseif (status == readyStatus.FORCE_REGION_SELECT) then
			main_pregame_customization_readyLabel:SetText(Translate('pregame_general_region'))
		elseif (status == readyStatus.UNREADY) then
			main_pregame_customization_readyLabel:SetText(Translate('main_lobby_unready'))
		elseif (status == readyStatus.READY) then
			main_pregame_customization_readyLabel:SetText(Translate('main_lobby_ready'))
		end
		-- Set width of ready button
		local width = main_pregame_customization_ready:GetWidthFromString('40s') + GetStringWidth(main_pregame_customization_readyLabel:GetFont(), main_pregame_customization_readyLabel:GetText())
		width = math.max(main_pregame_customization_ready:GetWidthFromString('220s'), width)
		main_pregame_customization_ready_container:SetWidth(width)
		main_pregame_customization_readyBody:SetWidth('100%')

		-- Pad: Implemented queue size check
		if(status == readyStatus.UNREADY and isQueueCountLoopRunning == false) then
			isQueueCountLoopRunning = true
			libThread.threadFunc(function()
				while(true) do
					local currentStatus = getReadyButtonStatus()
					if( currentStatus == readyStatus.UNREADY) then 
						local currentQueue = LuaTrigger.GetTrigger('PartyStatus').queue
						local queuePlayerCount = 0
						local queueInfo = Chat_Web_Requests:GetQueueInfo()
						for _,queue in pairs(queueInfo) do
							if(queue["queue"] == currentQueue) then
								for _,party in pairs(queue["parties"]) do
									for _ in pairs(party["members"]) do queuePlayerCount = queuePlayerCount + 1 end
								end				
							end
						end
						local countText = (currentQueue=='pvp' and queuePlayerCount < 5) and "< 5" or tostring(queuePlayerCount)
						GetWidget('main_pregame_queue_size_label'):SetText(Translate('pregame_queue_size') .. " " .. countText)
						wait(5000)
					else
						break
					end
				end
				isQueueCountLoopRunning = false
			end)
		end
	end)
end
main_pregame_customization_ready:RegisterWatchLua('HeroSelectHeroGearSkin0', function(widget, trigger)
	readyButtonCheck()
end, false, nil, 'displayName')

main_pregame_customization_readyLabel:RegisterWatchLua('PartyStatus', function(widget, trigger)
	readyButtonCheck()
end, false, nil, 'inQueue', 'isLocalPlayerReady')

local function readyUp()
	local skinTrigger = LuaTrigger.GetTrigger('HeroSelectHeroAltAvatarList'..selectedSkin)
	local dyeTrigger = LuaTrigger.GetTrigger('HeroSelectHeroGearSkin'..selectedDye)
	libThread.threadFunc(function()
		--PlaySound('/ui/sounds/parties/sfx_ready_self.wav')
		if (LuaTrigger.GetTrigger('PartyStatus').isPartyLeader and not isLobby) then
			RegionSelect.setRegionString()
			ChatClient.SetPartyQueue(LuaTrigger.GetTrigger('selectModeInfo').queuedMode)
		end
		SelectHero(LuaTrigger.GetTrigger('HeroSelectHeroList'..selectedHero).entityName)
		local petTrigger = LuaTrigger.GetTrigger('HeroSelectFamiliarList'..selectedPet)
		SpawnFamiliar(petTrigger.entityName, petTrigger['skinName'..(selectedPetSkin)])
		SelectAvatar(skinTrigger.parentHero, skinTrigger.name)
		SelectSkin(skinTrigger.parentHero, skinTrigger.name, dyeTrigger.name)
		Corral.SelectPetSlot(selectedPet)
		Cmd('Ready')
		if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_ready.wav') end
	end)
end

main_pregame_customization_ready:SetCallback('onclick', function(widget)
	local status = getReadyButtonStatus()
	if (status == readyStatus.PURCHASE) then

	elseif (status == readyStatus.FORCE_REGION_SELECT) then
		RegionSelect.showRegions()
	elseif (status == readyStatus.UNREADY) then
		Cmd('unready')
		if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_unready.wav') end
	elseif (status == readyStatus.READY) then
		readyUp()
		if (isLobby) then
			widget:SetEnabled(false)
		end
	end
end)

---------------------------
------- Dye Selection
---------------------------

local function SetModelSkin(widget, modelSkinPath)
	if (modelSkinPath ~= lastSkinPath) then
		widget:SetModelSkin(modelSkinPath)
	end
	lastSkinPath = modelSkinPath
end
local function SetModel(widget, modelPath)
	if (modelPath ~= lastModelPath) then
		local lastAnimTime
		if (widget.GetAnimTime) then
			lastAnimTime = widget:GetAnimTime()
		end
		widget:SetModel(modelPath)
		-- RMM Hero Emotes Here
		if (lastAnimTime) and (lastAnimTime < 4000000000) then
			widget:SetAnimTime(lastAnimTime)
		end
		lastModelPath = modelPath
	end
end

local function DisplayDyePreviewModel(skin, dye, specialEdition)
	local skin = skin or selectedSkin
	local cost = {}
	local rentalCost = {}
	local rentalActive = false
	local ownGear = false
	local ownDye = false
	if (skin) then
		local HeroSelectLocalPlayerInfo = LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo')
		local AltAvatarTrigger = LuaTrigger.GetTrigger('HeroSelectHeroAltAvatarList'..skin)
		ownGear = AltAvatarTrigger.canSelect
		SetModel(main_pregame_dye_selection_heromodel, AltAvatarTrigger.modelPath)
		main_pregame_dye_selection_heromodel:SetEffect(HeroSelectLocalPlayerInfo.previewPassiveEffect)
		main_pregame_dye_selection_heromodel:SetModelOrientation(AltAvatarTrigger.previewAngles)
		main_pregame_dye_selection_heromodel:SetModelPosition(AltAvatarTrigger.previewPos)
		main_pregame_dye_selection_heromodel:SetModelScale(AltAvatarTrigger.previewScale)
		main_pregame_customization_die_title:SetText(AltAvatarTrigger.upgradeDisplayName)
		main_pregame_customization_die_cost_container:SetVisible(false)
		if ((not AltAvatarTrigger.canSelect) and (AltAvatarTrigger.gemCost >= 0)) then
			cost.skin = AltAvatarTrigger.gemCost
		end
		if ((not AltAvatarTrigger.canSelect) and (AltAvatarTrigger.rentalGemCost > 0)) then
			rentalCost.skin = AltAvatarTrigger.rentalGemCost
		end
		if (AltAvatarTrigger.rentCharges > 0) and (AltAvatarTrigger.isRental) then
			rentalActive = true
		end
	end
	if (dye) then
		local AltAvatarTrigger = LuaTrigger.GetTrigger('HeroSelectHeroAltAvatarList'..(skin or 0))
		local dyeTrigger 		= LuaTrigger.GetTrigger('HeroSelectHeroGearSkin' .. dye)
		if (dye == 0) then
			main_pregame_customization_die_title:SetText(AltAvatarTrigger.upgradeDisplayName)
		else
			main_pregame_customization_die_title:SetText(AltAvatarTrigger.upgradeDisplayName .. ' ' .. dyeTrigger.displayName)
		end
		ownDye = dyeTrigger.canSelect
		SetModelSkin(main_pregame_dye_selection_heromodel, dyeTrigger.name)
		if ((not dyeTrigger.canSelect) and (dyeTrigger.gemCost >= 0)) then
			cost.dye = dyeTrigger.gemCost	
		end
		if ((not dyeTrigger.canSelect) and (dyeTrigger.rentalGemCost > 0)) then
			rentalCost.dye = dyeTrigger.rentalGemCost	
		end
		groupfcall('main_pregame_dye_selected_group', function(_, widget) 
			fadeWidget(widget, widget:GetName() == "main_pregame_dye_"..dye.."_selected", 125)
		end)
		if (dyeTrigger.rentCharges > 0) and (dyeTrigger.isRental) then
			rentalActive = true
		end		
	end
	if (cost.dye or cost.skin) then
		if (cost.skin and cost.skin == 0 and (not ownGear)) then
			main_pregame_customization_die_cost_container:SetVisible(false)			
			main_pregame_customization_die_cost_owned:SetVisible(false)	
			GetWidget('main_pregame_customization_die_cost_steamonly'):SetVisible(true)			
		else
			main_pregame_customization_die_cost_container:SetVisible(true)			
			main_pregame_customization_die_cost_owned:SetVisible(false)	
			GetWidget('main_pregame_customization_die_cost_steamonly'):SetVisible(false)	
			if (cost.dye and cost.skin) and (cost.dye > 0) and (cost.skin > 0) then
				main_pregame_customization_die_cost:SetText((cost.skin) .. ' + ' .. (cost.dye))
			else
				main_pregame_customization_die_cost:SetText((cost.skin or 0) + (cost.dye or 0))
			end
		end
	else
		main_pregame_customization_die_cost_container:SetVisible(false)			
		main_pregame_customization_die_cost_owned:SetVisible(true)
		GetWidget('main_pregame_customization_die_cost_steamonly'):SetVisible(false)		
		if (rentalActive) then
			main_pregame_customization_die_cost_owned_label:SetText(Translate('pregame_general_rented'))
		else
			main_pregame_customization_die_cost_owned_label:SetText(Translate('pregame_general_owned'))
		end
	end	
	if (rentalCost.dye or rentalCost.skin) then
		if (cost.skin and cost.skin == 0 and (not ownGear)) then
			main_pregame_customization_die_rental_cost_container:SetVisible(false)			
			main_pregame_purchase_hero_cosmetic_product_purchase_option_1:SetVisible(false)				
		else		
			main_pregame_customization_die_rental_cost_container:SetVisible(true)			
			main_pregame_purchase_hero_cosmetic_product_purchase_option_1:SetVisible(true)			
			if (rentalCost.dye and rentalCost.skin) then
				main_pregame_customization_die_rental_cost:SetText((rentalCost.skin) .. ' + ' .. (rentalCost.dye))
			else
				main_pregame_customization_die_rental_cost:SetText((rentalCost.skin or 0) + (rentalCost.dye or 0))
			end
		end
	else
		main_pregame_customization_die_rental_cost_container:SetVisible(false)			
		main_pregame_purchase_hero_cosmetic_product_purchase_option_1:SetVisible(false)			
	end
end

local numDyes = 0
local function showSelectedDye()
	DisplayDyePreviewModel(nil, selectedDye)
end
local function showDye(dye)
	DisplayDyePreviewModel(nil, dye)
end
selectDye = function(dye, dontColor, isClick)
	dye = clamp(dye, 0, numDyes)
	selectedAvatarDye[selectedSkin] = dye
	local dyeTrigger 		= LuaTrigger.GetTrigger('HeroSelectHeroGearSkin' .. dye)
	local widget = interface:GetWidget('pregame_skin_'..selectedSkin..'_dye_color')
	if widget and not dontColor then widget:SetColor(dyeTrigger.color1) end
	selectedDye = dye
	SelectSkin(dyeTrigger.parentHero, LuaTrigger.GetTrigger('HeroSelectHeroAltAvatarList'..selectedSkin).name, dyeTrigger.name)
	readyButtonCheck()
	showSelectedDye()
	
	if (dyeTrigger.canSelect) then
		if not dontColor and isClick then
			mainUI.savedRemotely.heroBuilds[heroEntityName]['lastDyes'] = mainUI.savedRemotely.heroBuilds[heroEntityName]['lastDyes'] or {}
			mainUI.savedRemotely.heroBuilds[heroEntityName]['lastDyes'][selectedSkin] = {selectedDye, dyeTrigger.color1}
			SaveState()
			if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_hero_dye.wav') end
		end
		lastValidDye = dye
	end
	
end

local function populateDyes()
	local tileWidth = getMeasurementFromString(main_pregame_customization_die_container, '48s')
	local skinTrigger = LuaTrigger.GetTrigger("HeroSelectHeroAltAvatarList"..selectedSkin)
	local dyeWidgets = createWidgetArrayFromTriggerSet(
		main_pregame_customization_die_container, 'pregame_dye_template', 'HeroSelectHeroGearSkin', 
		function(n, trigger) return trigger.name ~= "" end,
		function(n, trigger) 
			local postfix = (trigger.name == trigger.parentHero) and 'default' or trigger.name
			return {
				'color', trigger.color1,
				'x', (n%dyesPerRow) * tileWidth,
				'y', (math.floor(n/dyesPerRow)) * tileWidth,
				'index', n,
				'isNew', tostring(isNewDye(skinTrigger.parentHero, skinTrigger.name, trigger.name)),
				'isLocked', tostring(not trigger.canSelect)
			} end,
		true,
		{
			onclick = function(n, trigger) selectDye(n, nil, true) end,  
			onmouseover = function(n, trigger) GetWidget('main_pregame_dye_'..n..'_hover'):FadeIn(75) end,
			onmouseout = function(n, trigger) GetWidget('main_pregame_dye_'..n..'_hover'):FadeOut(75) showSelectedDye() end,
		}
	)
	numDyes = #dyeWidgets
end

---------------------------
------- Skin selection
---------------------------

showSkin = function (skin) 
	local trigger = LuaTrigger.GetTrigger('HeroSelectHeroAltAvatarList'..skin)
	if not trigger then return end
	local postfix = (trigger.name == trigger.parentHero) and 'default' or trigger.name
	updateSplash('/ui/main/shared/concept_art/' .. string.lower(trigger.parentHero) .. '_' .. postfix .. '.jpg')
	groupfcall('pregame_skin_highlight_group', function(_, widget) 
		fadeWidget(widget, widget:GetName() == "pregame_skin_"..skin.."_highlight", 125)
	end)
	groupfcall('pregame_skin_texture_group', function(_, widget) 
		widget:SetColor(widget:GetName() == "pregame_skin_"..skin.."_image" and '1 1 1' or '.7 .7 .7')
	end)
end
selectSkin = function(skin, isClick)
	skin = clamp(skin, 0, #skinWidgets)
	selectedSkin = skin
	showSkin(selectedSkin)
	local trigger = LuaTrigger.GetTrigger('HeroSelectHeroAltAvatarList'..selectedSkin)
	selectedDye = (trigger.canSelect and selectedAvatarDye[selectedSkin]) or 0
	readyButtonCheck()
	SelectSkin(trigger.parentHero, trigger.name, 'default')
	local postfix = (trigger.name == trigger.parentHero) and 'default' or trigger.name
	SelectAvatar(trigger.parentHero, trigger.name)
	if (trigger.canSelect and isClick) then
		lastValidSkin = skin
		mainUI.savedRemotely.heroBuilds[heroEntityName] = mainUI.savedRemotely.heroBuilds[heroEntityName] or {}
		mainUI.savedRemotely.heroBuilds[heroEntityName].defaultGear = selectedSkin
		SaveState()
		if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_hero_gearset.wav') end
	end
	libThread.threadFunc(function()
		wait(1)
		populateDyes()
		selectDye(selectedDye, true)
	end)
	
	main_pregame_dye_selection_previous:SetVisible(skin > 0)
	main_pregame_dye_selection_next:SetVisible(skin < #skinWidgets)
end

local function openDyeSelection(skin, dye, specialEdition)
	selectSkin(skin, true)
	libThread.threadFunc(function()
		wait(2)
		if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_hero_dye_open.wav') end
		DisplayDyePreviewModel(skin, selectedAvatarDye[selectedSkin], specialEdition)
		main_pregame_dye_selection_container:SetVisible(true)
	end)
end

main_pregame_dye_selection_previous:SetCallback('onclick', function(widget)
	openDyeSelection(selectedSkin - 1)
end)
main_pregame_dye_selection_next:SetCallback('onclick', function(widget)
	openDyeSelection(selectedSkin + 1)
end)

main_pregame_dye_selection_container:SetCallback('onhide', function(widget)
	setMainTriggers({
		mainBackground = {blackTop=true}, -- Cover under the navigation
		mainNavigation = {breadCrumbsVisible=true}, -- navigation with breadcrumbs
	})	
end)

main_pregame_dye_selection_container:SetCallback('onshow', function(widget)
	setMainTriggers({
		mainBackground = {blackTop=false}, -- Cover under the navigation
		mainNavigation = {breadCrumbsVisible=false}, -- navigation with breadcrumbs
	})	
end)

populateSkins = function()
	main_pregame_customization_skin_container:ClearChildren()
	if LuaTrigger.GetTrigger('HeroSelectHeroAltAvatarList0').parentHero == heroEntityName then
		skinWidgets = createWidgetArrayFromTriggerSet(
			main_pregame_customization_skin_container, 'pregame_skin_template', 'HeroSelectHeroAltAvatarList', 
			function(n, trigger) return trigger.name ~= "" end,
			function(n, trigger) 
				local gear = (trigger.name == trigger.parentHero) and '' or '/gear_'..n
				return {
					'texture', string.gsub(trigger.heroSelectPreview, 'heroselect', 'gearselect'),
					'id', n,
					'isLocked', tostring(not trigger.canSelect),
					'isNew', tostring(isNewSkin(trigger.parentHero, trigger.name)),
					'textureColor', (trigger.canSelect) and "white" or ".4 .4 .4 1"
				} end,
			true,
			{
				onclick = function(n, trigger) 
					selectSkin(n, true)
					if (trigger.gemCost == 0) and (not trigger.canSelect) then
						openDyeSelection(n, nil, true)
					elseif (not trigger.canSelect) then
						openDyeSelection(n)
					end 
				end, 
				onmouseover = function(n, trigger) showSkin(n) end, 
				onmouseout = function(n, trigger) showSkin(selectedSkin) end,
			}
		)
		
		for n, _ in pairs(skinWidgets) do
			
			interface:GetWidget('pregame_skin_'..n..'_clicker'):SetCallback('onclick', function(widget)
				local trigger = LuaTrigger.GetTrigger('HeroSelectHeroAltAvatarList'..n)
				selectSkin(n, true) 
				if (not trigger.canSelect) then
					openDyeSelection(n) 
				end
			end)
			interface:GetWidget('pregame_skin_'..n..'_clicker'):SetCallback('onmouseover', function(widget)
				 showSkin(n)
			end)
			interface:GetWidget('pregame_skin_'..n..'_clicker'):SetCallback('onmouseout', function(widget)
				showSkin(selectedSkin)
			end)
			
			interface:GetWidget('pregame_skin_'..n..'_dye'):SetCallback('onmouseover', function(widget)
				 showSkin(n)
			end)
			interface:GetWidget('pregame_skin_'..n..'_dye'):SetCallback('onmouseout', function(widget)
				showSkin(selectedSkin)
			end)			
			
			interface:GetWidget('pregame_skin_'..n..'_dye2'):SetCallback('onmouseover', function(widget)
				 showSkin(n)
			end)
			interface:GetWidget('pregame_skin_'..n..'_dye2'):SetCallback('onmouseout', function(widget)
				showSkin(selectedSkin)
			end)			
			
			interface:GetWidget('pregame_skin_'..n..'_dye'):SetCallback('onclick', function(widget)
				openDyeSelection(n)
			end)
			interface:GetWidget('pregame_skin_'..n..'_dye2'):SetCallback('onclick', function(widget)
				openDyeSelection(n)
			end)
			FindChildrenClickCallbacks(skinWidgets[n])
			skinWidgets[n]:PushToBack()
		end
		if (#skinWidgets > 1 and skinWidgets[0]) then
			skinWidgets[0]:BringToFront()
		end
	end
end
UnwatchLuaTriggerByKey('HeroSelectHeroAltAvatarList0', 'skinUpdate')
WatchLuaTrigger('HeroSelectHeroAltAvatarList0', function(trigger)
	if (state == 3 and trigger.parentHero == heroEntityName) then
		loadHeroPrefs()
	end
end, 'skinUpdate', 'parentHero')

UnwatchLuaTriggerByKey('loadComplete', 'skinUpdate')
WatchLuaTrigger('loadComplete', function(trigger)
	loadHeroPrefs()
end, 'skinUpdate')


---------------------------
------- Pet Skin selection
---------------------------

local function DisplayPetPreviewModel(pet, skin)
	local skin = skin or selectedPetSkin
	local pet = pet or selectedPet
	local cost = {}
	if (skin) then
		local HeroSelectLocalPlayerInfo = LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo')
		local petTrigger = LuaTrigger.GetTrigger('HeroSelectFamiliarList'..pet)
		local name = TranslateOrNil('pet_skin_name_' .. petTrigger.entityName .. '_' .. petTrigger['skinName' .. skin]) or GetEntityDisplayName(petTrigger.entityName)

		main_pregame_pet_selection_heromodel:SetModel(petTrigger['skinModel'..skin])
		local indexForModelInfo = (skin == 1 and 2) or skin
		main_pregame_pet_selection_heromodel:SetModelOrientation(petTrigger['skinModelOrient'..indexForModelInfo])
		main_pregame_pet_selection_heromodel:SetModelPosition(petTrigger['skinModelPos'..indexForModelInfo])
		main_pregame_pet_selection_heromodel:SetModelScale(petTrigger['skinModelScale'..indexForModelInfo] * 2)
		main_pregame_customization_pet_title:SetText(name)
		if (not petTrigger['skinOwned'..skin]) and (petTrigger['skinCost'..skin] > 0) then
			cost.skin = petTrigger['skinCost'..skin]
		end
	end
	
	if (cost.skin) then
		main_pregame_customization_pet_cost_container:SetVisible(true)			
		main_pregame_customization_pet_cost_owned:SetVisible(false)	
		main_pregame_customization_pet_cost:SetText((cost.skin or 0))
	else
		main_pregame_customization_pet_cost_container:SetVisible(false)			
		main_pregame_customization_pet_cost_owned:SetVisible(true)	
	end	
	
end


local function showPetSkin(petSkin)
	groupfcall('pregame_pet_skin_selected_group', function(_, widget) 
		fadeWidget(widget, widget:GetName() == "pregame_pet_skin_".. petSkin .."_selected", 125)
	end)
	groupfcall('pregame_pet_skin_group', function(_, widget) 
		widget:SetColor(widget:GetName() == "pregame_pet_skin_".. petSkin and '1 1 1' or '.7 .7 .7')
	end)
end

selectPetSkin = function(petSkin, isUserClick, preview)
	selectedPetSkin = petSkin
	showPetSkin(selectedPetSkin)
	local petTrigger = LuaTrigger.GetTrigger('HeroSelectFamiliarList'..selectedPet)
	SpawnFamiliar(petTrigger.entityName, petTrigger['skinName'..(selectedPetSkin)])
	readyButtonCheck()
	if (LuaTrigger.GetTrigger('HeroSelectFamiliarList'..selectedPet)['skinOwned'..(selectedPetSkin)] and not preview) then
		lastValidPetSkin = petSkin
		mainUI.savedRemotely = mainUI.savedRemotely or {}
		mainUI.savedRemotely.petLastSkins = mainUI.savedRemotely.petLastSkins or {}
		mainUI.savedRemotely.petLastSkins[petTrigger.entityName] = selectedPetSkin
		SaveState()	
	elseif (isUserClick) then
		DisplayPetPreviewModel(selectedPet, selectedPetSkin)
		main_pregame_pet_selection_container:SetVisible(true)
		if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_pet_skin_select.wav') end
	end
	main_pregame_pet_selection_previous:SetVisible(petSkin ~= 2)
	main_pregame_pet_selection_next:SetVisible(petSkin ~= 3)
end

main_pregame_pet_selection_previous:SetCallback('onclick', function(widget)
	if (selectedPetSkin == 1) then
		selectPetSkin(2, true, true)
	elseif (selectedPetSkin == 3) then
		selectPetSkin(1, true, true)
	end
end)
main_pregame_pet_selection_next:SetCallback('onclick', function(widget)
	if (selectedPetSkin == 2) then
		selectPetSkin(1, true, true)
	elseif (selectedPetSkin == 1) then
		selectPetSkin(3, true, true)
	end
end)

initPetSkins = function()
	local trigger = LuaTrigger.GetTrigger('HeroSelectFamiliarList'..selectedPet)
	for n = 1, 3 do
		interface:GetWidget("pregame_pet_skin_"..n):SetTexture(trigger['skinIcon'..n])
		interface:GetWidget("pregame_pet_skin_"..n..'_locked' ):SetVisible(not (trigger['skinOwned'..n] and trigger['selectable']))
		interface:GetWidget("pregame_pet_skin_"..n..'_locked2'):SetVisible(not (trigger['skinOwned'..n] and trigger['selectable']))
	end
end
for n = 1, 3 do
	interface:GetWidget("pregame_pet_skin_"..n):SetCallback('onclick', function(widget)
		selectPetSkin(n, true)
	end)
	interface:GetWidget("pregame_pet_skin_"..n):SetCallback('onmouseover', function(widget)
		showPetSkin(n)
	end)
	interface:GetWidget("pregame_pet_skin_"..n):SetCallback('onmouseout', function(widget)
		showPetSkin(selectedPetSkin)
	end)
end
FindChildrenClickCallbacks(interface:GetWidget("main_pregame_customization_pet_skin_container"))


main_pregame_pet_selection_container:SetCallback('onhide', function(widget)
	setMainTriggers({
		mainBackground = {blackTop=true}, -- Cover under the navigation
		mainNavigation = {breadCrumbsVisible=true}, -- navigation with breadcrumbs
	})	
end)

main_pregame_pet_selection_container:SetCallback('onshow', function(widget)
	setMainTriggers({
		mainBackground = {blackTop=false}, -- Cover under the navigation
		mainNavigation = {breadCrumbsVisible=false}, -- navigation with breadcrumbs
	})	
end)


loadLastValidCosmeticConfig = function()
	if (selectedSkin == lastValidSkin) then
		if (selectedDye == lastValidDye) then
		
		elseif (lastValidDye) and (selectedSkin) and (interface:GetWidget('pregame_skin_'..selectedSkin..'_dye_color')) then
			local dyeTrigger 		= LuaTrigger.GetTrigger('HeroSelectHeroGearSkin' .. lastValidDye)
			if (dyeTrigger) then
				interface:GetWidget('pregame_skin_'..selectedSkin..'_dye_color'):SetColor(dyeTrigger.color1)	
			end
		end
	else
		local dyeTrigger 		= LuaTrigger.GetTrigger('HeroSelectHeroGearSkin0')
		if (dyeTrigger) and (selectedSkin) and (interface:GetWidget('pregame_skin_'..selectedSkin..'_dye_color')) then 
			interface:GetWidget('pregame_skin_'..selectedSkin..'_dye_color'):SetColor(dyeTrigger.color1)	
		end
	end
	
	selectSkin(lastValidSkin or 0)
	selectDye(lastValidDye or 0)
	selectPetSkin(lastValidPetSkin or 1)
end

main_pregame_customization_undo:SetCallback('onclick', function(widget)
	loadLastValidCosmeticConfig()
end)

GetWidget('main_pregame_purchase_hero_cosmetic_product_purchase_option_3_leave'):SetCallback('onclick', function()
	GetWidget('main_pregame_dye_selection_container'):FadeOut(125)
	loadLastValidCosmeticConfig()
end)

-- Hero
GetWidget('main_pregame_dye_selection_close'):SetCallback('onclick', function()
	GetWidget('main_pregame_dye_selection_container'):FadeOut(125)
	loadLastValidCosmeticConfig()
end)
GetWidget('main_pregame_purchase_hero_cosmetic_product_cancel_btn'):SetCallback('onclick', function()
	GetWidget('main_pregame_dye_selection_container'):FadeOut(125)		
	loadLastValidCosmeticConfig()
end)
GetWidget('main_pregame_dye_selection_backing'):SetCallback('onclick', function()
	GetWidget('main_pregame_dye_selection_container'):FadeOut(125)		
	loadLastValidCosmeticConfig()
end)
-- Pet
GetWidget('main_pregame_pet_selection_close'):SetCallback('onclick', function()
	GetWidget('main_pregame_pet_selection_container'):FadeOut(125)	
	loadLastValidCosmeticConfig()
end)
GetWidget('main_pregame_pet_selection_leave'):SetCallback('onclick', function()
	GetWidget('main_pregame_pet_selection_container'):FadeOut(125)	
	loadLastValidCosmeticConfig()
end)
GetWidget('main_pregame_pet_selection_closeBody'):SetCallback('onclick', function()
	GetWidget('main_pregame_pet_selection_container'):FadeOut(125)	
	loadLastValidCosmeticConfig()
end)
GetWidget('main_pregame_purchase_pet_cosmetic_product_cancel_btn'):SetCallback('onclick', function()
	GetWidget('main_pregame_pet_selection_container'):FadeOut(125)	
	loadLastValidCosmeticConfig()
end)
GetWidget('main_pregame_pet_selection_backing'):SetCallback('onclick', function()
	GetWidget('main_pregame_pet_selection_container'):FadeOut(125)	
	loadLastValidCosmeticConfig()
end)

---------------------------
------- Initialize customized section
---------------------------
loadHeroPrefs = function()
	if not (DatabaseLoadStateTrigger and DatabaseLoadStateTrigger.stateLoaded and LuaTrigger.GetTrigger('HeroSelectHeroAltAvatarList0').parentHero == heroEntityName) then
		return -- Not loaded database/triggers
	end
	-- Load dye settings
	selectedAvatarDye = {}
	local savedPrefs = mainUI.savedRemotely.heroBuilds[heroEntityName]
	if (savedPrefs and savedPrefs['lastDyes']) then
		for k, v in pairs(savedPrefs['lastDyes']) do
			selectedAvatarDye[tonumber(k)] = v[1]
		end
	end
	
	-- Populate widgets
	-- Skins
	populateSkins()
	-- Pet Skins
	initPetSkins()
	
	-- Color dye widgets
	if (savedPrefs and savedPrefs['lastDyes']) then
		for k, v in pairs(savedPrefs['lastDyes']) do
			local widget = interface:GetWidget('pregame_skin_'..k..'_dye_color')
			if widget then widget:SetColor(v[2]) end
		end
	end
	-- Select (possibly loaded)skins
	local savedSkin = savedPrefs and savedPrefs.defaultGear or 0
	local savedDye = (savedPrefs and savedPrefs['lastDyes'] and savedPrefs['lastDyes'][savedSkin] and savedPrefs['lastDyes'][savedSkin][1]) or 0
	selectedDye = savedDye
	selectSkin(savedSkin)
	local petTrigger = LuaTrigger.GetTrigger('HeroSelectFamiliarList'..selectedPet)
	selectPetSkin(petTrigger and petTrigger.entityName and mainUI.savedRemotely.petLastSkins and mainUI.savedRemotely.petLastSkins[petTrigger.entityName] or 1)
	libThread.threadFunc(function()
		wait(1)
		populateDyes()
		selectDye(savedDye or 0, true)
	end)
end

initCustomized = function(ignoreBreadcrumbs)
	state = 3
	if (not ignoreBreadcrumbs) then
		refreshBreadcrumbs()
	end
	local showingReady = not widget.main_pregame_ready_container:IsVisible() and mainUI.Pregame.inQueue
	if (showingReady) then
		initHeroModels()
		shrinkChat()
	else
		resetChat()
	end
	fadeWidget(widget.main_pregame_ready_container, showingReady)
	
	libThread.threadFunc(function()
		if (showingReady) then
			animateChildren(main_pregame_customization_container, false, false, mainUI.Pregame.specialWidgets)
			fadeWidget(main_pregame_hero_name_container, false)
			wait(styles_mainSwapAnimationDuration)
			
			-- Stop back to queue button shrinking
			local buttonBody = interface:GetWidget("main_pregame_customization_to_readyBody")
			buttonBody:SetWidth("100%")
			buttonBody:SetHeight("100%")
		end
		animateChildren(main_pregame_selection_container, false, false, mainUI.Pregame.specialWidgets)
		main_pregame_skills_container:SlideX('-315s', styles_mainSwapAnimationDuration)
		animateChildren(main_pregame_customization_container, true, false, mainUI.Pregame.specialWidgets)
		fadeWidget(main_pregame_hero_name_container, true)
	end)
	
	-- Title
	local trigger = LuaTrigger.GetTrigger('HeroSelectHeroList'..selectedHero)
	interface:GetWidget("main_pregame_hero_name"):SetText(trigger.displayName)
	interface:GetWidget("main_pregame_hero_desc"):SetText(Translate('pregame_customize_step_1'))
	main_pregame_customization_ready:SetEnabled(true)
	resetChat()
	loadHeroPrefs()
	
	readyButtonCheck()
end

function mainUI.openCustomized(hero, pet)
	local trigger = LuaTrigger.GetTrigger('HeroSelectHeroList'..hero)
	selectedHero = hero
	SelectHero(trigger.entityName)
	heroEntityName = trigger.entityName
	selectedPet = pet
	Corral.SelectPetSlot(pet)
	SpawnFamiliar(LuaTrigger.GetTrigger('HeroSelectFamiliarList'..pet).entityName, 'default')
	actuallySelectedPet = true
	
	-- Wait for the game to pick up that we selected our hero. When it does, init customized
	local triggerString = "HeroSelectHeroAltAvatarList0"
	if (LuaTrigger.GetTrigger(triggerString).parentHero == heroEntityName) then
		initCustomized(true)
	else
		main_pregame_sleeper:UnregisterWatchLua(triggerString)
		main_pregame_sleeper:RegisterWatchLua(triggerString, function(widget, trigger)
			if trigger.parentHero == heroEntityName then
				initCustomized(true)
				main_pregame_sleeper:UnregisterWatchLua(triggerString)
			end
		end, false, nil, 'parentHero')
	end
end
main_pregame_customization_to_ready:SetCallback('onclick', function()
	initCustomized()
end)


---------------------------
------- Initialize ready section
---------------------------

local function getHeroTriggerFromIndex(entityName)
	for n = 0, 99 do
		local trigger = LuaTrigger.GetTrigger('HeroSelectHeroList'..n)
		if (not trigger.isValid) then return nil end
		if (trigger.entityName == entityName) then
			return trigger
		end
	end
	return nil
end

initHeroModels = function()
	for n = 0, 4 do
		local trigger = LuaTrigger.GetTrigger((n == 0 and 'HeroSelectLocalPlayerInfo') or 'HeroSelectPlayerInfo'..(n-1))
		if (trigger.heroEntityName ~= '' and trigger.playerName ~= "") then
			local model = GetWidget('main_pregame_ready_heromodel'..n)
			model:SetModel(trigger.previewModel) -- apply skin
			model:SetEffect(trigger.previewPassiveEffect)
			model:SetModelOrientation(trigger.previewAngles)
			model:SetModelPosition(trigger.previewPos)
			model:SetModelScale(trigger.previewScale)
			model:SetModelSkin(trigger.skinName) -- apply dye
			model:SetVisible(true)
			
			GetWidget('main_pregame_ready_empty'..n):SetVisible(false)
		else
			GetWidget('main_pregame_ready_heromodel'..n):SetVisible(false)
			GetWidget('main_pregame_ready_empty'..n):SetVisible(true)
			
			GetWidget('main_pregame_ready_empty'..n..'_invite'):SetCallback('onclick', function(widget)
				Friends.ToggleFriendsList(true)
			end)			
			
		end
	end
end

widget.main_pregame_ready_container:RegisterWatchLua("PartyStatus", function(widget, trigger)
	libThread.threadFunc(function()
		wait(1)
		if (LuaTrigger.GetTrigger('PartyStatus').inQueue and LuaTrigger.GetTrigger('HeroSelectMode').mode ~= 'captains') then
			mainUI.Pregame.inQueue = true
			if (selectedPet) and (selectedPet >= 0) and (selectedPetSkin) then
				GetWidget('main_pregame_ready_pet'):SetTexture(LuaTrigger.GetTrigger('HeroSelectFamiliarList'..selectedPet)['skinIcon'..(selectedPetSkin)])
			end
			GetWidget('main_pregame_ready_gearset'):SetTexture(string.gsub(LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo').heroSelectPreview, 'heroselect', 'gearicon'))
			if (selectedDye) then
				GetWidget('main_pregame_ready_dye_color'):SetColor(LuaTrigger.GetTrigger('HeroSelectHeroGearSkin'..selectedDye).color1)
			end
			GetWidget('main_pregame_ready_guide_name'):SetText(mainUI.Selection.buildInfoTables and mainUI.Selection.buildInfoTables[LuaTrigger.GetTrigger('mainBuildEditor').buildNumber].name or '')
			
			initHeroModels()
			widget:FadeIn(styles_mainSwapAnimationDuration)
			fadeWidget(main_pregame_customization_to_ready, mainUI.Pregame.inQueue)
			shrinkChat()
		elseif (LuaTrigger.GetTrigger('LobbyStatus').state ~= 'finding_server') then
			mainUI.Pregame.inQueue = false
			resetChat()
			widget:FadeOut(styles_mainSwapAnimationDuration)
			fadeWidget(main_pregame_customization_to_ready, mainUI.Pregame.inQueue)
		else
			-- We are in a match, do nothing
			if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_matchfound.wav') end
		end
		refreshBreadcrumbs()
	end)
end, false, nil, 'inQueue')

widget.main_pregame_ready_unready:SetCallback('onclick', function(widget)
	Cmd('unready')
	if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_unready.wav') end
end)

local function createSimpleButton(buttonName, containerName, onclick)
	local button = interface:GetWidget(buttonName)
	local buttonContainer = interface:GetWidget(containerName)
	buttonContainer:SetCallback('onclick', function()
		button:SetTexture('/ui/shared/frames/std_btn_over.tga')
		onclick(button)
	end)
	buttonContainer:SetCallback('onmouseover', function()
		button:SetTexture('/ui/shared/frames/blue_btn_over.tga')
		libAnims.bounceIn(button, button:GetWidth(), button:GetHeight(), nil, nil, 0.02, 200, 0.9, 0.1)
	end)
	buttonContainer:SetCallback('onmouseout', function()
		button:SetTexture('/ui/shared/frames/blue_btn_up.tga')
	end)
end
createSimpleButton('main_pregame_ready_visit_web_button', 'main_pregame_ready_visit_web', function(widget) mainUI.OpenURL(Strife_Region.regionTable[Strife_Region.activeRegion].strifeWebsiteURL or 'http://www.strife.com') end)
createSimpleButton('main_pregame_ready_start_over_button', 'main_pregame_ready_start_over', function()
	Cmd('unready')
	if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_unready.wav') end
	actuallySelectedHero = false
	actuallySelectedPet = false
	selectedSkin = 0
	selectedPetSkin = 1
	state = 1
	petSelection = false
	refreshBreadcrumbs()
	applyHeroFilter()
	showSelected()
	animateChildren(main_pregame_selection_container, true, false, mainUI.Pregame.specialWidgets)
	main_pregame_skills_container:SlideX('15s', styles_mainSwapAnimationDuration)
	animateChildren(main_pregame_customization_container, false, false, mainUI.Pregame.specialWidgets)
end)

widget.main_pregame_ready_review_container:SetCallback('onclick', function()
	initCustomized()
end)


---------------------------
------- Builds selection
---------------------------
main_pregame_customization_edit_build:SetCallback('onclick', function(widget)
	--[[
	local buildEditorStatus = LuaTrigger.GetTrigger('buildEditorStatus')
	buildEditorStatus.selectedHeroIndex = selectedHero
	buildEditorStatus:Trigger()
	]]
	local mainBuildEditor = LuaTrigger.GetTrigger('mainBuildEditor')
	mainBuildEditor.visible = true
	mainBuildEditor.buildHero = selectedHero
	mainBuildEditor.buildNumber = 1
	mainBuildEditor:Trigger()
end)

--[[
main_pregame_customization_new_build:SetCallback('onclick', function(widget)
	local mainBuildEditor = LuaTrigger.GetTrigger('mainBuildEditor')
	mainBuildEditor.visible = true
	mainBuildEditor.buildHero = selectedHero
	mainBuildEditor.buildNumber = 1
	mainBuildEditor:Trigger()
end)
]]
-- ================================================================
-- ======================== Bread crumbs ==========================
-- ================================================================
local function hideCustomizeOverlays()
	main_pregame_dye_selection_container:FadeOut(125)
	main_pregame_pet_selection_container:FadeOut(125)
end

heroSelectButtonClick = function()
	libThread.threadFunc(function()
		if (state == 2) then
			animateChildren(main_pregame_selection_container, false, false, mainUI.Pregame.specialWidgets, 30)
			main_pregame_skills_container:SlideX('-315s', 30)
			fadeWidget(main_pregame_hero_name_container, false, false, {}, 30)
			wait(30)
		end
		state = 1
		refreshBreadcrumbs()
		petSelection = false
		toggleGridView(true)
		showSelected()
		animateChildren(main_pregame_selection_container, true, false, mainUI.Pregame.specialWidgets)
		main_pregame_skills_container:SlideX('15s', styles_mainSwapAnimationDuration)
		fadeWidget(main_pregame_hero_name_container, true)
		animateChildren(main_pregame_customization_container, false, false, mainUI.Pregame.specialWidgets)
		interface:GetWidget('main_pregame_hero_desc'):FadeIn(styles_mainSwapAnimationDuration)
		hideCustomizeOverlays()
	end)
end

petSelectButtonClick = function()
	libThread.threadFunc(function()
		if (state == 1) then
			animateChildren(main_pregame_selection_container, false, false, mainUI.Pregame.specialWidgets, 30)
			main_pregame_skills_container:SlideX('-315s', 30)
			fadeWidget(main_pregame_hero_name_container, false, false, {}, 30)
			wait(30)
		end
		state = 2
		refreshBreadcrumbs()
		petSelection = true
		toggleGridView(true)
		showSelected()
		animateChildren(main_pregame_selection_container, true, false, mainUI.Pregame.specialWidgets)
		main_pregame_skills_container:SlideX('15s', styles_mainSwapAnimationDuration)
		fadeWidget(main_pregame_hero_name_container, true)
		animateChildren(main_pregame_customization_container, false, false, mainUI.Pregame.specialWidgets)
		hideCustomizeOverlays()
	end)
end

CustomizeSelectButtonClick = function()
	initCustomized()
end

function mainUI.changeMode()
	if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_back.wav') end
	libThread.threadFunc(function()
		wait(1)
		local partyTrigger = LuaTrigger.GetTrigger('PartyStatus')
		local trigger = LuaTrigger.GetTrigger('mainPanelStatus')
		if (partyTrigger.isPartyLeader) or (not partyTrigger.inParty) then
			trigger.main = mainUI.MainValues.selectMode
			trigger:Trigger(false)
		end
	end)
end

refreshBreadcrumbs = function()
	if (not mainUI.Pregame.inQueue) then
		local partyTrigger = LuaTrigger.GetTrigger('PartyStatus')
		mainUI.setBreadcrumbsSelected(state+1)
		mainUI.setBreadcrumbsEnabled(1, (partyTrigger.isPartyLeader) or (not partyTrigger.inParty), 'scrim_finder_disabled_host')
		mainUI.setBreadcrumbsEnabled(2, true)
		mainUI.setBreadcrumbsEnabled(3, actuallySelectedHero, 'pregame_breadcrumb_mustchoosehero')
		mainUI.setBreadcrumbsEnabled(4, actuallySelectedPet, 'pregame_breadcrumb_mustchoosepet')
	else
		mainUI.setBreadcrumbsEnabled(1, false, 'pregame_breadcrumb_mustunready')
		mainUI.setBreadcrumbsEnabled(2, false, 'pregame_breadcrumb_mustunready')
		mainUI.setBreadcrumbsEnabled(3, false, 'pregame_breadcrumb_mustunready')
		mainUI.setBreadcrumbsEnabled(4, true)
		mainUI.setBreadcrumbsSelected(widget.main_pregame_ready_container:IsVisible() and 4 or -1)
	end
end

-- ================================================================
-- ==================== Global Reset Function =====================
-- ================================================================
local initSelectionTriggersThread
function InitSelectionTriggers() -- These should be what are made into a trigger if there needs to be one.
	if (mainUI.Pregame.triggerVarChangeOrFunctionThread) then
		mainUI.Pregame.triggerVarChangeOrFunctionThread:kill()
		mainUI.Pregame.triggerVarChangeOrFunctionThread = nil
	end
	if (mainUI.Pregame.populatePetListThread) then
		mainUI.Pregame.populatePetListThread:kill()
		mainUI.Pregame.populatePetListThread = nil
	end
	if (mainUI.Pregame.populateHeroListThread) then
		mainUI.Pregame.populateHeroListThread:kill()
		mainUI.Pregame.populateHeroListThread = nil
	end	
	if (mainUI.Pregame.applyHeroFilterThreads) then
		for _,v in pairs(mainUI.Pregame.applyHeroFilterThreads) do
			if (v) then
				v:kill()
				v = nil
			end
		end
		mainUI.Pregame.applyHeroFilterThreads = {}
	end
	
	if (initSelectionTriggersThread) then
		initSelectionTriggersThread:kill()
		initSelectionTriggersThread = nil
	end	
	selectedHero = -1
	selectedPet = -1
	setSelectedToFirstSelectablePet()
	selectedSkin = 0
	selectedPetSkin = 1
	state = 1
	petSelection = false
	initSelectionTriggersThread = libThread.threadFunc(function()
		wait(1)
		populateHeroList()
		populatePetList()
		wait(5)
		toggleGridView(true)
		teamComposition1:Trigger()
		teamComposition2:Trigger()
		showSelected()
		refreshBreadcrumbs()
		wait(1)
		updateHeroSlider(0, true)
		initSelectionTriggersThread = nil
	end)
end


-- ================================================================
-- ========================= Party info ===========================
-- ================================================================

local function leaveParty() -- Leaves current party/lobby
	if isLobby then
		ChatClient.LeaveGame()
	else
		Party.LeaveParty()
	end
	local trigger = LuaTrigger.GetTrigger('mainPanelStatus')
	trigger.main = mainUI.MainValues.selectMode
	trigger:Trigger()
end

-- Re-select mode button
local selectModeInfo = LuaTrigger.GetTrigger('selectModeInfo') or LuaTrigger.CreateCustomTrigger('selectModeInfo', {
	{ name	= 'queuedMode',		type		= 'string' }
})
local main_pregame_party_mode_label = object:GetWidget("main_pregame_party_mode_label")
main_pregame_party_mode_label:RegisterWatchLua("selectModeInfo", function(widget, trigger)
	widget:SetText(Translate('general_current_mode') .. '\n' .. Translate('pre_play_'..trigger.queuedMode))
end)
main_pregame_party_mode_label:RegisterWatchLua("PartyStatus", function(widget, trigger)
	widget:SetText(Translate('general_current_mode') .. '\n' .. Translate('pre_play_'..trigger.queue))
end, false, nil, 'queue')
main_pregame_party_mode_label:SetText(Translate('general_current_mode') .. '\n' .. Translate('pre_play_'..selectModeInfo.queuedMode))

-- Region selection
object:GetWidget("main_pregame_region_button"):SetCallback('onclick', function(widget)
	if (not isLobby) then
		RegionSelect.showRegions()
	end
end)

object:GetWidget("main_pregame_region_button"):RegisterWatchLua('regionSelectClosed', function(widget, trigger)
	RegionSelect.seenRegions[getQueue()] = true
	readyButtonCheck()
end)
object:GetWidget("main_pregame_region_button"):RegisterWatchLua('regionSelectLoaded', function(widget, trigger)
	readyButtonCheck()
end)

local function setRegionWidgetLabel()
	libThread.threadFunc(function()
		wait(1)
		interface:GetWidget('main_pregame_party_region_label'):SetText(RegionSelect.GetSelectedRegionsString() or '---')
	end)
end

main_pregame_sleeper:RegisterWatchLua('PartyStatus', function(widget, trigger)
	if (RegionSelect.loaded) then
		RegionSelect.initSettings()
		setRegionWidgetLabel()
	else
		main_pregame_sleeper:RegisterWatchLua('regionSelectLoaded', function(widget, trigger)
			main_pregame_sleeper:UnregisterWatchLua('regionSelectLoaded')
			RegionSelect.initSettings()
			setRegionWidgetLabel()
		end)
	end
	if trigger.inParty and toBeSelected >= 0 then
		selectHero(toBeSelected)
		toBeSelected = -1
	end
end, false, nil, "isPartyLeader", "region", "inParty")

main_pregame_sleeper:RegisterWatchLua('regionSelectClosed', function(widget, trigger) -- Kai Todo: Perhaps make this have a server feedback timeout.
	if (isLeader()) then
		setRegionWidgetLabel()
	end
end)

main_pregame_sleeper:RegisterWatchLua('GamePhase', function(widget, trigger)
	if trigger.gamePhase > 2 and toBeSelected >= 0 then
		selectHero(toBeSelected)
		toBeSelected = -1
	end
end, false, nil, "gamePhase")


main_pregame_sleeper:RegisterWatchLua('LobbyGameInfo', function(widget, trigger)
	setRegionWidgetLabel()
end, false, nil, "serverName")

-- Party icons

local function registerPartyIcons()
	-- init party/ally icons
	
	for n = 0, 4 do
		local widget = interface:GetWidget("pregame_team_entry_"..n)
		widget:UnregisterWatchLua('PartyPlayerInfo'..n)
		widget:UnregisterWatchLua('HeroSelectPlayerInfo'..n)
		local triggerString = isLobby and ('HeroSelectPlayerInfo'..n) or ('PartyPlayerInfo'..n)
		
		widget:GetWidget('pregame_team_entry_'..n..'_invite'):SetCallback('onclick', function(widget)
			Friends.ToggleFriendsList(true)
		end)
		
		local function refreshPartyPlayer(trigger)

			local trigger = trigger or LuaTrigger.GetTrigger(triggerString)
			local vis = (trigger.playerName ~= "")
			
			local function OpenContextMenu()
				ContextMenuTrigger = LuaTrigger.GetTrigger('ContextMenuTrigger')
				ContextMenuTrigger.selectedUserIdentID 			= trigger.identID
				ContextMenuTrigger.selectedUserUsername 		= trigger.playerName
				ContextMenuTrigger.selectedUserIsInGame			= true
				ContextMenuTrigger.selectedUserIsInParty		= not isLobby
				ContextMenuTrigger.selectedUserIsInLobby		= isLobby
				ContextMenuTrigger.spectatableGame			= false
				ContextMenuTrigger.contextMenuArea = 1
				ContextMenuTrigger:Trigger(true)			
			end
			
			widget:GetWidget('pregame_team_entry_'..n..'_button'):SetCallback('onclick', function(widget)
				OpenContextMenu()
			end)
			widget:GetWidget('pregame_team_entry_'..n..'_button'):SetCallback('onrightclick', function(widget)
				OpenContextMenu()
			end)
			
			if (isLobby) then
				widget:SetVisible(vis)
			else
				widget:SetVisible(true)
			end
			widget:GetWidget('pregame_team_entry_'..n..'_name'):SetVisible(vis)
			widget:GetWidget('pregame_team_entry_'..n..'_group'):SetVisible(false)
			widget:GetWidget('pregame_team_entry_'..n..'_occupied'):SetVisible(vis)
			widget:GetWidget('pregame_team_entry_'..n..'_voip'):SetVisible(vis and (not isLobby) and trigger.isTalking)
			widget:GetWidget('pregame_team_entry_'..n..'_invite'):SetVisible(not vis)
			widget:GetWidget('pregame_team_entry_'..n..'_ready_container'):SetVisible(vis)
			local droptarget = widget:GetWidget('pregame_team_entry_'..n..'_droptarget_droptarget')
			local dropparent = widget:GetWidget('pregame_team_entry_'..n..'_droptarget_parent')

			if (vis) then
			
				local text = ''
				if (trigger) and (trigger.clanTag) and (not Empty(trigger.clanTag)) then
					text = (('[' .. (trigger.clanTag or '') ..']') .. (trigger.playerName or ''))
				elseif (trigger) then
					text = (trigger.playerName or '')
				end			
			
				if (trigger.isPending) then
					widget:GetWidget('pregame_team_entry_'..n..'_name'):SetText('(' .. text .. ')')
					widget:GetWidget('pregame_team_entry_'..n..'_name'):SetColor('.6 .6 .6 1')
				else
					widget:GetWidget('pregame_team_entry_'..n..'_name'):SetColor('1 1 1 1')
					widget:GetWidget('pregame_team_entry_'..n..'_name'):SetText(text)
				end
				local texture = widget:GetWidget('pregame_team_entry_'..n..'_texture')
				if (trigger.heroIconPath ~= "") then
					texture:SetTexture(trigger.heroIconPath)
					texture:SetVisible(true)
					widget:GetWidget('pregame_team_entry_'..n..'_invite'):SetVisible(true)
				else
					local logo = trigger.accountIconPath
					if (logo == "") then
						logo = "/ui/shared/textures/account_icons/default.tga"
					end
					texture:SetTexture(logo)
					texture:SetVisible(not isLobby)
				end
				widget:GetWidget('pregame_team_entry_'..n..'_ready'):SetVisible(trigger.isReady)
				widget:GetWidget('pregame_team_entry_'..n..'_waiting'):SetVisible(not trigger.isReady)
				dropparent:UnregisterWatchLua('MultiWindowDragInfo')
				dropparent:SetVisible(0)
			else			
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
						local partyCustomTrigger = LuaTrigger.GetTrigger('PartyTrigger')
						ChatClient.PartyInvite(Windows.data.friendBeingDraggedIdentID)
						partyCustomTrigger.userRequestedParty = true
						partyCustomTrigger:Trigger(false)
					end
				end)	
				dropparent:UnregisterWatchLua('MultiWindowDragInfo')
				dropparent:RegisterWatchLua('MultiWindowDragInfo', function(widget, trigger)
					widget:SetVisible((MultiWindowDragInfo.active) and (MultiWindowDragInfo.type == 'player'))
				end, false, nil, 'active', 'type')					
			end
		end
		widget:RegisterWatchLua(triggerString, function(widget, trigger)
			refreshPartyPlayer(trigger)
		end, false, nil, 'playerName', 'heroIconPath', 'isReady', 'isPending')
		refreshPartyPlayer()
	end
end



widget.main_pregame_party_leave:SetCallback('onclick', function(widget)
	if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_leave.wav') end
	leaveParty()
	local mainPanelStatus = LuaTrigger.GetTrigger('mainPanelStatus')
	mainPanelStatus.main = 101
	mainPanelStatus:Trigger(false)
end)
widget.main_pregame_party_mode_button:SetCallback('onclick', function(widget)
	mainUI.changeMode()
end)

-- Timer
main_pregame_timer:RegisterWatchLua('LobbyCountDown', function(widget, trigger)
	widget:SetText(Translate('party_finder_waiting_on_timer') .. ' ' .. libNumber.timeFormat(trigger.timeRemaining))
end, false, nil, 'timeRemaining')

GetWidget('main_pregame_customization_longqueue'):RegisterWatchLua('PartyStatus', function(widget, trigger)
	if (trigger.numPlayersInParty) then
		widget:SetVisible(trigger.numPlayersInParty == 5)
	end
end)

-- Chat
shrinkChat = function()
	widget.selection_chat_base:SlideX('540s', 100)
	widget.selection_chat_base:SlideY('42s', 100)
	widget.selection_chat_base:SetWidth('420s')
	widget.selection_chat_base:SetHeight('180s')
end
resetChat = function()
	widget.selection_chat_base:SlideX('630s', 100)
	widget.selection_chat_base:SlideY('260s', 100)
	widget.selection_chat_base:SetWidth('420s')
	widget.selection_chat_base:SetHeight('250s')
end


function mainUI.Pregame.getSelectedHero()
	return selectedHero
end

-- ================================================================
-- =================== Hide this screen (102) =====================
-- ================================================================

local function hidePregame()
	
	pregame_splashimage_container:FadeOut(styles_mainSwapAnimationDuration)
	pregame_loading_background:FadeOut(styles_mainSwapAnimationDuration)
	animateChildren(main_pregame_selection_container, false, false, mainUI.Pregame.specialWidgets)
	main_pregame_skills_container:SlideX('-315s', styles_mainSwapAnimationDuration)
	animateChildren(main_pregame_customization_container, false, false, mainUI.Pregame.specialWidgets)
	fadeWidget(main_pregame_timer_container, false)
	animateChildren(widget.main_pregame_party_container, false)
	fadeWidget(main_pregame_hero_name_container, false)
	--libThread.threadFunc(function()
		--wait(styles_mainSwapAnimationDuration)
		main_pregame_container:FadeOut(styles_mainSwapAnimationDuration)
	--end)
end

-- ================================================================
-- =================== Show this screen (102) =====================
-- ================================================================
local function showPregame()
	local breadCrumbsTable = {
		{text='general_change_mode', onclick=mainUI.changeMode},
		{text='pregame_general_hero_select', onclick=heroSelectButtonClick},
		{text='pregame_general_pet_select', 	onclick=petSelectButtonClick},
		{text='pregame_general_customize', 	onclick=CustomizeSelectButtonClick}
	}	
	
	mainUI.initBreadcrumbs(breadCrumbsTable)
	refreshBreadcrumbs()
	setMainTriggers({
		mainBackground = {blackTop=true}, -- Cover under the navigation
		mainNavigation = {breadCrumbsVisible=true}, -- navigation with breadcrumbs
	})
	
	animateChildren(main_pregame_selection_container, state <= 2, false, mainUI.Pregame.specialWidgets)
	main_pregame_skills_container:SlideX(state <= 2 and '15s' or '-315s', styles_mainSwapAnimationDuration)
	animateChildren(main_pregame_customization_container, state >= 3, false, mainUI.Pregame.specialWidgets)
	fadeWidget(main_pregame_hero_info_container, state == 1)
	
	isLobby = LuaTrigger.GetTrigger('GamePhase').gamePhase > 2 and LuaTrigger.GetTrigger('LobbyStatus').inLobby and not LuaTrigger.GetTrigger('PartyStatus').inParty
	fadeWidget(main_pregame_timer_container, isLobby)
	fadeWidget(widget.main_pregame_party_mode_button, not isLobby)
	animateChildren(widget.main_pregame_party_container, true)
	fadeWidget(main_pregame_hero_name_container, true)

	if (Strife_Region and Strife_Region.regionTable and Strife_Region.regionTable[Strife_Region.activeRegion] and Strife_Region.regionTable[Strife_Region.activeRegion].EnablecommunityGuides) then
		widget.main_pregame_customization_browseOnline:SetVisible(true)
	else
		widget.main_pregame_customization_browseOnline:SetVisible(false)
	end
	
	if (isLobby) then
		if (RegionSelect.loaded) then
			setRegionWidgetLabel()
		else
			main_pregame_sleeper:RegisterWatchLua('regionSelectLoaded', function(widget, trigger)
				main_pregame_sleeper:UnregisterWatchLua('regionSelectLoaded')
				setRegionWidgetLabel()
			end)
		end
	end
	
	registerPartyIcons()
	
	pregame_splashimage_container:FadeIn(styles_mainSwapAnimationDuration)
	
	libThread.threadFunc(function()
		wait(styles_mainSwapAnimationDuration)
		if (LuaTrigger.GetTrigger('mainPanelStatus').main == mainUI.MainValues.preGame) then
			pregame_loading_background:FadeIn(50)
		end
	end)
	main_pregame_container:FadeIn(styles_mainSwapAnimationDuration)
	--fadeWidget(interface:GetWidget('pregame_team_entry_container'), not isLobby)


	-- This is a workaround for a sporadic bug which stops gameplay.. If there are no heroes to select, or, you're not meant to select them, return to news.
	libThread.threadFunc(function()
		wait(4000) -- 4 seconds: status triggers should be populated
		if (not canSelectHero() and LuaTrigger.GetTrigger('mainPanelStatus').main == mainUI.MainValues.preGame) then
			main_pregame_heros_container:ClearChildren() -- Make sure we have a fresh restart
			LuaTrigger.GetTrigger('mainPanelStatus').main = mainUI.MainValues.news
			LuaTrigger.GetTrigger('mainPanelStatus'):Trigger()
			return
		end

		for n = 1, 4 do -- first 20 seconds, if things aren't loaded, try to load them.
			-- Detect list not populated correctly, and retry
			if (#main_pregame_heros_container:GetChildren() <= 25 and LuaTrigger.GetTrigger('mainPanelStatus').main == mainUI.MainValues.preGame) then
				main_pregame_heros_container:ClearChildren()
				InitSelectionTriggers()
				return
			end
			wait(5000)
		end

	end)
end


local initialized = false
main_pregame_sleeper:RegisterWatchLua('mainPanelAnimationStatus', function(widget, trigger)
	local animState = mainSectionAnimState(mainUI.MainValues.preGame, trigger.main, trigger.newMain)
	if animState == 1 then			-- outro
		hidePregame()
	elseif animState == 2 then			-- fully hidden
		main_pregame_container:SetVisible(false)
	elseif animState == 3 then		-- intro
		libThread.threadFunc(function()	
			wait(1)
			showPregame()
			initialized = true
		end)
	elseif animState == 4 then										-- fully displayed
		if (not initialized) then
			showPregame()
			initialized = true
		end
		main_pregame_container:SetVisible(true)
	end
end, false, nil, 'main', 'newMain')
