local triggerPanelStatus			= LuaTrigger.GetTrigger('mainPanelStatus')
local triggerPanelAnimationStatus	= LuaTrigger.GetTrigger('mainPanelAnimationStatus')

mainUI = mainUI or {}

libGeneral.createGroupTrigger('navVisAnimGroup', {
	'featureMaintenanceTrigger',
	'mainPanelAnimationStatus.newMain',
	'mainPanelAnimationStatus.main'
})

local function navigationRegister(object)
	local tabNames = {'pets', 'craft', 'play', 'watch'}
	local container = object:GetWidget('main_top_button_container')
	
	-- bread-crumbs
	local main_top_breadcrumb_Container = object:GetWidget('main_top_breadcrumb_Container')
	-- Trigger listener
	container:RegisterWatchLua('mainNavigation', function(widget, trigger)
		fadeWidget(widget, trigger.visible) -- Overall visibility
		fadeWidget(main_top_breadcrumb_Container, trigger.breadCrumbsVisible) -- Bread crumbs visibility
		for i = 1, #tabNames do -- Enabling buttons
			object:GetWidget('main_top_button_'..tabNames[i]..'Button'):SetEnabled(trigger.enabled)
		end
	end)

	local playMains = {mainUI.MainValues.lobby, mainUI.MainValues.preGame, mainUI.MainValues.selectMode, 40}
	-- Big Reds
	local function RegisterButton(widgetName, main, isPlayButton)
		local button	=	GetWidget(widgetName .. 'Button')
		button:SetCallback('onclick', function(self)
			if (triggerPanelStatus.main == main) then
				triggerPanelStatus.main = 101
				if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_home.wav') end
			else
				triggerPanelStatus.main = main
				if (main == 2) then
					if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_pets.wav') end
				elseif (main == 1) then
					if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_craft.wav') end
				elseif (main == 28) then
					if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_watch.wav') end
				elseif (main == 101) then
					if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_home.wav') end
				end
			end
			triggerPanelStatus:Trigger(false)
		end)
		button:RefreshCallbacks()
		local menuButtonImage = object:GetWidget(widgetName.."Background")
		local menuButtonImageCurrent = object:GetWidget(widgetName.."BackgroundCurrent")		
		menuButtonImage:RegisterWatchLua('mainPanelStatus', function(widget, trigger)
			if (isPlayButton) then -- Play button
				local enabled = not IsInTable(playMains, trigger.main)
				widget:SetColor((enabled and 'white') or '1 1 1')				
				menuButtonImageCurrent:SetVisible((enabled and '0') or '1')
			else -- Other top buttons
				local enabled = trigger.main ~= main
				widget:SetColor((enabled and 'white') or '1 1 1')
				menuButtonImageCurrent:SetVisible((enabled and '0') or '1')
				widget:GetParent():GetParent():SetEnabled(enabled)
			end
		end, false, nil, 'main')
	end
	RegisterButton('main_top_button_pets', 2)
	RegisterButton('main_top_button_craft', 1)
	RegisterButton('main_top_button_play', 40, true)
	RegisterButton('main_top_button_watch', 28)
	RegisterButton('main_top_button_menu', 101)

	-- Pets subtext
	local petsSubText = object:GetWidget('main_top_button_petsLabel2')
	local petsSubTextFX = object:GetWidget('main_top_button_petsLabel2FX')
	
	local function isThereAPetToBuy()
		for i=0,20 do
			local petTrigger = LuaTrigger.GetTrigger('CorralPet' .. i)
			if (petTrigger) then
				if (petTrigger.canPurchasePet) and (not petTrigger.isStarterPet) and (not Empty(petTrigger.entityName)) then
					return true
				end
			end
		end
		return false
	end
	
	local function updatePetsSubText(seals)
		seals = seals or LuaTrigger.GetTrigger('Corral').fruit
		if (seals >= 3000) and isThereAPetToBuy() then
			petsSubText:SetText(Translate('crafting_menu_seals_unlock_available'))
			petsSubTextFX:SetVisible(1)
		else
			petsSubText:SetText(Translate('crafting_menu_seals_unlock_unavailable'))
			petsSubTextFX:SetVisible(0)
		end
	end
	updatePetsSubText()
	petsSubText:RegisterWatchLua('Corral', function(widget, trigger)
		updatePetsSubText(trigger.fruit)
	end, false)
	
	-- Crafting subtext
	local craftingSubText = object:GetWidget('main_top_button_craftLabel2')
	local craftingSubTextX = object:GetWidget('main_top_button_craftLabel2FX')
	local function updateCraftingSubText(ore)
		ore = ore or math.floor(LuaTrigger.GetTrigger('CraftingCommodityInfo').oreCount)
		local amountCanMake = math.floor(ore/360)
		if (amountCanMake > 0) then
			craftingSubText:SetText(Translate('crafting_menu_essence_up_to_items', 'value', amountCanMake))
			craftingSubTextX:SetVisible(1)
		else
			craftingSubText:SetText(Translate('crafting_menu_essence_no_items', 'value', (360-ore)))
			craftingSubTextX:SetVisible(0)
		end
	end
	updateCraftingSubText()
	craftingSubText:RegisterWatchLua('CraftingCommodityInfo', function(widget, trigger)
		updateCraftingSubText(math.floor(trigger.oreCount))
	end, false, nil, 'oreCount')
	
	local function canCraft()
		local canCraft = LuaTrigger.GetTrigger('AccountProgression').level >= mainUI.progression.CRAFTING_UNLOCK_LEVEL
		return canCraft
	end
	
	-- Lock crafting if it should be locked
	local craftingButton = object:GetWidget("main_top_button_craftButton")
	craftingButton:RegisterWatchLua('AccountProgression', function(widget, trigger)
		widget:SetEnabled(canCraft())
	end, false, nil)
	
	-- Menu button
	local menuButtonImage = object:GetWidget("main_top_button_menuBackground")
	local menuButtonImageCurrent = object:GetWidget("main_top_button_menuBackgroundCurrent")		
	menuButtonImage:RegisterWatchLua('mainPanelStatus', function(widget, trigger)
		local enabled = trigger.main ~= 101
		widget:SetColor((enabled and 'white') or '1 1 1')
		menuButtonImageCurrent:SetVisible((enabled and '0') or '1')
		widget:GetParent():GetParent():SetEnabled(enabled)
	end, false, nil, 'main')
	
	local function GetPlayState()
		updatePetsSubText()
		
		trigger = LuaTrigger.GetTrigger('mainPanelStatus')
		local gamePhase	= trigger.gamePhase
		local isReady	= trigger.isReady
		local hasIdent	= trigger.hasIdent
		local isLoggedIn	= trigger.isLoggedIn
		local initialPetPicked	= trigger.initialPetPicked
		local getAllIdentGameDataStatus	= trigger.getAllIdentGameDataStatus
		local LeaverBan	= LuaTrigger.GetTrigger('UILeaverBan')
		if (trigger.missedGameAddress and (not Empty(trigger.missedGameAddress))) and (LuaTrigger.GetTrigger('ChatMissedGame').isRewarding) and (not LuaTrigger.GetTrigger('ReconnectInfo').hasLeaver) then	-- game started without you
			return "reconnect"
		elseif (trigger.reconnectShow and trigger.reconnectAddress and (not Empty(trigger.reconnectAddress)) and trigger.reconnectType and (not Empty(trigger.reconnectType)) ) and  (LuaTrigger.GetTrigger('ReconnectInfo').isRewarding) and (not LuaTrigger.GetTrigger('ReconnectInfo').hasLeaver)  then	-- you left a game, it's still going
			return "reconnect2"
		elseif (trigger.updaterState == 1) and (isLoggedIn) and (hasIdent) then
			return "update"
		elseif (LeaverBan) and (LeaverBan.remainingBanSeconds) and (LeaverBan.remainingBanSeconds > 0) then
			return "deserter"
		elseif (isLoggedIn) and (hasIdent) then
			if (not initialPetPicked) and (getAllIdentGameDataStatus ~= 1) then
				return "petSelect"
			elseif (trigger.inQueue) then
				return "searching"
			else
				return ""
			end
		end
		return ""
	end
	
	local playLabel = GetWidget('main_top_button_playLabel')
	local playLabel2 = GetWidget('main_top_button_playLabel2')
	-- play
	local function PlayUpdate()
		playLabel:SetFont('maindyn_40') -- most are 40 and no sub-title
		playLabel2:SetText('')
		
		local state = GetPlayState()
		if (state == "reconnect" or state == "reconnect2") then
			playLabel:SetFont('maindyn_30')
			playLabel:SetText(Translate('general_reconnect'))
		elseif (state == "update") then
			playLabel:SetText(Translate('main_label_update'))
		elseif (state == "deserter") then
			playLabel:SetFont('maindyn_36')
			playLabel:SetText(Translate('main_label_leaver'))
		elseif (state == "petSelect") then
			playLabel:SetText(Translate('temp_signbutton_petselect2'))
			playLabel2:SetText(Translate('temp_signbutton_petselect'))
			playLabel2:SetColor('#fffaf9')
			playLabel2:SetOutlineColor('#ab291b')
		elseif (state == "searching") then
			playLabel:SetText(Translate('general_play'))
			playLabel2:SetText(Translate('mainlobby_label_custom_searching'))
			playLabel2:SetColor('#fffaf9')
			playLabel2:SetOutlineColor('#ab291b')
		else
			playLabel:SetText(Translate('general_play'))
		end
	end

	playLabel:RegisterWatchLua('mainPanelStatus', function(widget, trigger)
		PlayUpdate()
	end, false, nil, 'reconnectShow', 'reconnectType', 'reconnectAddress', 'missedGameAddress', 'inQueue', 'inParty', 'numPlayersInParty', 'gamePhase', 'chatConnectionState', 'isReady', 'hasIdent', 'updaterState', 'initialPetPicked', 'getAllIdentGameDataStatus', 'isLoggedIn', 'main')

	playLabel:RegisterWatchLua('UILeaverBan', function(widget, trigger)
		if (trigger) and (trigger.remainingBanSeconds) and (trigger.remainingBanSeconds > -10) then
			PlayUpdate(widget, LuaTrigger.GetTrigger('mainPanelStatus'), true)
		end
	end, false, nil, 'now', 'bannedUntil', 'remainingBanSeconds')

	local function PlayNowClicked(isRightClick)
		local state = GetPlayState()
		
		local triggerPanelStatus		= LuaTrigger.GetTrigger('mainPanelStatus')
		local LeaverBan					= LuaTrigger.GetTrigger('UILeaverBan')
		local selectModeInfo			= LuaTrigger.GetTrigger('selectModeInfo')
		local PartyStatus				= LuaTrigger.GetTrigger('PartyStatus')
		local LobbyStatus				= LuaTrigger.GetTrigger('LobbyStatus')
		local gamePhase					= LuaTrigger.GetTrigger('GamePhase').gamePhase
		
		
		-- soundEvent - Play Button Clicked

		if (state == "reconnect") then	-- game started without you
			local reconnectAddress = triggerPanelStatus.missedGameAddress
			GenericDialog(
				'main_reconnect_header', '', 'main_reconnect_text', 'general_reconnect', 'general_cancel',
					function()
						-- soundEvent
						Connect(reconnectAddress)
					end,
					function()
						-- soundEvent - Cancel
						if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/sfx_ui_back.wav') end
					end
			)
		elseif (state == "reconnect2") then	-- you left a game, it's still going
			local reconnectType = triggerPanelStatus.reconnectType
			local reconnectAddress = triggerPanelStatus.reconnectAddress
			local text = 'main_reconnect_text'
			-- allow them to reconnect or abandon the game
			if (LuaTrigger.GetTrigger('ReconnectInfo').isRewarding and not LuaTrigger.GetTrigger('ReconnectInfo').hasLeaver) then
				text = 'main_abandon_text'
			end	
			GenericDialog(
				'main_reconnect_header', '', text, 'general_reconnect', 'main_abandon',
					function()
						-- soundEvent
						if reconnectType == 'game' then
							Connect(reconnectAddress)
						elseif reconnectType == 'lobby' then
							ChatClient.JoinGame(reconnectAddress)
						end
					end,
					function()
						ChatClient.AbandonGame(LuaTrigger.GetTrigger('ReconnectInfo').gameUID)
					end)
						
		elseif (state == "update") then
			Party.LeaveParty()
			local UpdateInfo = LuaTrigger.GetTrigger('UpdateInfo')
			if (UpdateInfo.externalPatchMode) then
				GenericDialog(
					Translate('main_label_update'), Translate('main_label_steam_update_avail'), '', Translate('general_quit'), Translate('general_cancel'), 
					function()
						-- soundEvent - Confirm
						if (UpdateInfo.updateAvailable) then
							Cmd('Quit')
						end
					end,
					function()
						-- soundEvent - Cancel
						if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/sfx_ui_back.wav') end
						triggerPanelStatus.main = 101
					end,
					nil,
					nil,
					true
				)
			else
				GenericDialog(
					Translate('main_label_update'), Translate('main_label_update_avail'), '', Translate('general_update'), Translate('general_cancel'), 
					function()
						-- soundEvent - Confirm
						if (UpdateInfo.updateAvailable) then
							Client.Update()
						end
					end,
					function()
						-- soundEvent - Cancel
						if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/sfx_ui_back.wav') end
						triggerPanelStatus.main = 101
					end,
					nil,
					nil,
					true
				)
			end
		elseif (state == "deserter") then
			local formattedRemaining = libNumber.timeFormat((LeaverBan.remainingBanSeconds) * 1000)
			GenericDialog(
				'main_label_leaver', '', Translate('main_label_leaver_long_desc', 'value', formattedRemaining), 'general_ok', '',
					function()
						-- soundEvent
					end,
					nil
			)
		elseif (state == "petSelect") then
			triggerPanelStatus.main = 2
			if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_pets.wav') end
		else -- move to/from play screen
			local currentPage = triggerPanelStatus.main
			local nextPage = nil
			
			local state = mainUI.getPregameState()
			-- Pregame/party
			if state == 'pregame' then
				nextPage = mainUI.MainValues.preGame
			elseif state == 'captains' then
				nextPage = mainUI.MainValues.captainsMode
			elseif state == 'captainsHeroSelect' then
				nextPage = mainUI.MainValues.captainsMode
			elseif state == 'lobby' then
				nextPage = mainUI.MainValues.lobby
			elseif state == 'lobbyHeroSelect' then
				nextPage = mainUI.MainValues.preGame
			elseif state == 'scrim' then
				nextPage = mainUI.MainValues.selectMode
			else
				nextPage = mainUI.MainValues.selectMode
			end
			
			if (currentPage == nextPage) then
				triggerPanelStatus.main = mainUI.MainValues.news
				if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_home.wav') end
			else
				triggerPanelStatus.main = nextPage
				if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_play.wav') end
			end
				
			PlaySound('/ui/sounds/sfx_ui_playbutton.wav')
			
		end
		triggerPanelStatus:Trigger(false)
	end

	GetWidget('main_top_button_playButton'):SetCallback('onclick', function(widget)
		PlayNowClicked(false)
	end)
	GetWidget('main_top_button_playButton'):RefreshCallbacks()
	
	local function CraftingClicked(isRightClick)
		local triggerPanelStatus		= LuaTrigger.GetTrigger('mainPanelStatus')
		if (triggerPanelStatus.main == 1) or (triggerPanelStatus.main == 5) or (triggerPanelStatus.main == 6) then
			triggerPanelStatus.main = 101
			triggerPanelStatus:Trigger(false)
			if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_home.wav') end
		else
			triggerPanelStatus.main = 1
			triggerPanelStatus:Trigger(false)
			if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_craft.wav') end
		end
	end

	GetWidget('main_top_button_craftButton'):SetCallback('onclick', function(widget)
		CraftingClicked(false)
	end)
	
	local lockedWidget = GetWidget('canCraftProgress')
	if lockedWidget then
		libGeneral.createGroupTrigger('craftProgressBarVisWatch', {
			'LoginStatus.isLoggedIn',
			'LoginStatus.hasIdent',
			'AccountInfo.canCraft',
			'AccountInfo.accountLevel',
			'AccountInfo.isIdentPopulated',
			'AccountProgression.level',
			'newPlayerExperience.tutorialComplete',
			'newPlayerExperience.tutorialProgress'
		})

		lockedWidget:RegisterWatchLua('craftProgressBarVisWatch', function(widget, groupTrigger)
			local triggerLogin		= groupTrigger['LoginStatus']
			local triggerAccount	= groupTrigger['AccountInfo']
			local canCraft = canCraft()
			local triggerNPE		= groupTrigger['newPlayerExperience']
			widget:SetVisible(triggerLogin.isLoggedIn and triggerLogin.hasIdent and (triggerNPE.tutorialComplete or triggerNPE.tutorialProgress >= NPE_PROGRESS_FINISHTUT3) and triggerAccount.isIdentPopulated and not canCraft)
		end)
		
		libGeneral.createGroupTrigger('craftProgressBarWatch', {
			'AccountInfo.canCraft',
			'AccountInfo.accountLevel',
			'AccountProgression.percentToNextLevel',
			'AccountProgression.level',
		})

		GetWidget('canCraftProgressBar'):RegisterWatchLua('craftProgressBarWatch', function(widget, groupTrigger)
			local triggerProg		= groupTrigger['AccountProgression']
			local canCraft = canCraft(groupTrigger)
			if not canCraft then
				widget:SetWidth(ToPercent(
					((triggerProg.level-1) + (1-triggerProg.percentToNextLevel/100)) / (mainUI.progression.CRAFTING_UNLOCK_LEVEL-1)
				))
			end
		end)
		
		lockedWidget:SetCallback('onmouseover', function(widget)
			simpleTipGrowYUpdate(true, nil, Translate('navigation_crafting_mustlevelaccount'), Translate('navigation_crafting_mustlevelaccount_tip', 'value', mainUI.progression.CRAFTING_UNLOCK_LEVEL), libGeneral.HtoP(35))
		end)
		lockedWidget:SetCallback('onmouseout', function() 
			simpleTipGrowYUpdate(false)
		end)
	end

	-- Breadcrumbs
	-- Should take an array with { {text='content', onclick=function(widget)}, ...}
	local breadCrumbWidgets = {}
	local lastBreadCrumbsTable = {}
	local main_top_breadcrumb_Parent = object:GetWidget('main_top_breadcrumb_Parent')
	local main_top_breadcrumb_backing = object:GetWidget('main_top_breadcrumb_backing')
	function mainUI.initBreadcrumbs(breadCrumbsTable, minWidth, height)
		lastBreadCrumbsTable = breadCrumbsTable
		breadCrumbWidgets = {}
		
		local minWidth = minWidth or main_top_breadcrumb_Parent:GetWidthFromString('190s');
		main_top_breadcrumb_Parent:ClearChildren()
		for n = 1, #breadCrumbsTable do
			local visible = '1'
			if (breadCrumbsTable[n].visible ~= nil) and ((tostring(breadCrumbsTable[n].visible) == 'false') or (tostring(breadCrumbsTable[n].visible) == '0'))  then
				visible = '0'
			end
			local hasIcon = breadCrumbsTable[n].icon ~= nil
			local widget = main_top_breadcrumb_Parent:InstantiateAndReturn('main_top_breadcrumb_template', 
				'index', n,
				'iconVis', tostring(hasIcon),
				'id', breadCrumbsTable[n].id or ('main_top_breadcrumb_anon_'..n),
				'icon', breadCrumbsTable[n].icon or '',
				'onloadlua', breadCrumbsTable[n].onloadlua or '',
				'iconSize', breadCrumbsTable[n].iconSize or '90',
				'group', breadCrumbsTable[n].group or '',
				'visible', visible,
				
				'text', breadCrumbsTable[n].text and Translate(breadCrumbsTable[n].text) or ''
			)[1]
			breadCrumbWidgets[n] = widget
			if (breadCrumbsTable[n].onclick) then widget:SetCallback('onclick', breadCrumbsTable[n].onclick) end
			if (breadCrumbsTable[n].enabled == false) then
                local disabledTooltip = breadCrumbsTable[n].disabledTooltip or nil
				mainUI.setBreadcrumbsEnabled(n, false, disabledTooltip)
			end
			local width = math.max(GetStringWidth('maindyn_16',breadCrumbsTable[n].text), minWidth)
			width = width + ((hasIcon and main_top_breadcrumb_Parent:GetWidthFromString('16s')) or 0)
			widget:GetWidget('main_top_breadcrumb_'..n..'_width' ):SetWidth(width)
			widget:GetWidget('main_top_breadcrumb_'..n..'_width2'):SetWidth(width)
		end
		FindChildrenClickCallbacks(main_top_breadcrumb_Parent)
	end
	function mainUI.setBreadcrumbsSelected(selected)
		if (not selected) then
			println('^rBreadcrumbs: Call to select null')
			return
		end
		groupfcall('main_top_breadcrumb_selected_group', function(_, widget) 
			fadeWidget(widget, widget:GetName() == "main_top_breadcrumb_".. selected .."_selected", 125)
		end)
	end
	function mainUI.setBreadcrumbsEnabled(index, enabled, disabledTooltip)
		if (breadCrumbWidgets[index]) and (breadCrumbWidgets[index]:GetWidget("main_top_breadcrumb_".. index)) then
			breadCrumbWidgets[index]:GetWidget("main_top_breadcrumb_".. index):SetRenderMode(enabled and 'normal' or 'grayscale')
			breadCrumbWidgets[index]:ClearCallback('onclick')
			breadCrumbWidgets[index]:ClearCallback('onmouseover')
			breadCrumbWidgets[index]:ClearCallback('onmouseout')
			if (enabled) then
				breadCrumbWidgets[index]:SetCallback('onclick', lastBreadCrumbsTable[index].onclick)
				breadCrumbWidgets[index]:SetCallback('onmouseover', function() self:GetWidget('main_top_breadcrumb_'..index..'_over'):FadeIn(140) end)
				breadCrumbWidgets[index]:SetCallback('onmouseout', function() self:GetWidget('main_top_breadcrumb_'..index..'_over'):FadeOut(60) end)
			else
				if (disabledTooltip) then
					breadCrumbWidgets[index]:SetCallback('onmouseover', function() 
						simpleTipGrowYUpdate(true, nil, Translate(disabledTooltip), Translate(disabledTooltip..'_desc'), libGeneral.HtoP(40))
					end)
				end
				breadCrumbWidgets[index]:SetCallback('onmouseout', function() 
					simpleTipGrowYUpdate(false)
				end)			
			end
			FindChildrenClickCallbacks(main_top_breadcrumb_Parent)			
		--else
			--println("^rError: setBreadcrumbsEnabled missing object index: " .. index)
			--printr(breadCrumbWidgets)
		end
	end
end

navigationRegister(object)
