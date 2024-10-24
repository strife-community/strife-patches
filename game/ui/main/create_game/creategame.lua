-- ================================================================================
-- Create Game (2013 update)
local interface = object

function create_gameRegister(object)
	local container				= object:GetWidget('create_game')
	local closeButton			= object:GetWidget('create_gameClose')
	
	local gameNameBox			= object:GetWidget('create_gameNameBox')
	local serverDropdown		= object:GetWidget('create_gameServerDropdown')
	local serverList			= object:GetWidget('server_list')
	local create_game_select_server_btn			= object:GetWidget('create_game_select_server_btn')
	local modeDropdown		= object:GetWidget('create_gameModeDropdown')
	local modeDropdown_parent		= object:GetWidget('create_gameModeDropdown_parent')
	
	local regionDropdown			= object:GetWidget('create_gameRegionDropdown')
	local mapDropdown				= object:GetWidget('create_gameMapDropdown')
	local mapDropdown_parent		= object:GetWidget('create_gameMapDropdown_parent')
	local teamSizeDropdown			= object:GetWidget('create_gameTeamSizeDropdown')		-- Replace with slider
	-- local refereeCountDropdown		= object:GetWidget('create_gameRefereeCountDropdown')	-- Replace with slider
	local spectatorCountDropdown	= object:GetWidget('create_gameSpectatorCountDropdown')	-- Replace with slider
	local finalHeroesOnlyCheckbox	= object:GetWidget('create_gameFinalHeroesOnly')
	local finalHeroesOnlyCheckbox_parent	= object:GetWidget('create_gameFinalHeroesOnly_parent')
	local testingHeroesOnlyCheckbox	= object:GetWidget('create_gameTestingHeroesOnly')
	local testingHeroesOnlyCheckbox_parent	= object:GetWidget('create_gameTestingHeroesOnly_parent')
	local privateCheckbox	= object:GetWidget('create_gameprivate')
	local privateCheckbox_parent	= object:GetWidget('create_gameprivate_parent')
	local allchatCheckbox	= object:GetWidget('create_gameallchat')
	local allchatCheckbox_parent	= object:GetWidget('create_gameallchat_parent')
	
	local startMatchButton			= object:GetWidget('create_gameStartMatchButton')
	-- local cancelButton				= object:GetWidget('create_gameCancelButton')
	local serverRegion		= Cvar.GetCvar('_gameServerRegion')				or		Cvar.CreateCvar('_gameServerRegion', 'string', '')

	local serverType		= Cvar.GetCvar('_gameServerType')				or		Cvar.CreateCvar('_gameServerType', 'string', 'remote_dedicated')
	local gameMode			= Cvar.GetCvar('_gameMode') 					or 		Cvar.CreateCvar('_gameMode', 'string', 'normal')
	local mapName			= Cvar.GetCvar('_gameMapName')					or		Cvar.CreateCvar('_gameMapName', 'string', 'strife')
	local teamSize			= Cvar.GetCvar('_gameTeamSize')					or		Cvar.CreateCvar('_gameTeamSize', 'int', '5')
	local spectatorCount	= Cvar.GetCvar('_gameSpectatorCount')			or		Cvar.CreateCvar('_gameSpectatorCount', 'int', '0')
	local refereeCount		= Cvar.GetCvar('_gameRefereeCount')				or		Cvar.CreateCvar('_gameRefereeCount', 'int', '0')
	local private			= Cvar.GetCvar('_gamePrivate')					or		Cvar.CreateCvar('_gamePrivate', 'bool', 'false')
	local allchat			= Cvar.GetCvar('_gameAllChat')					or		Cvar.CreateCvar('_gameAllChat', 'bool', 'false')
	local gameName			= Cvar.GetCvar('_gameName')						or		Cvar.CreateCvar('_gameName', 'string', Translate('game_setup_default_game_name'))
	local finalHeroesOnly	= Cvar.GetCvar('_finalHeroesOnly')				or		Cvar.CreateCvar('_finalHeroesOnly', 'bool', 'true')
	local testingHeroesOnly	= Cvar.GetCvar('_testingHeroesOnly')			or		Cvar.CreateCvar('_testingHeroesOnly', 'bool', 'false')
	local optionString		= Cvar.CreateCvar('_gameOptionString', 'string', '')

	local gameOptions		= {		-- Forced and not able to be changed atm.
		noleaver			= false,
		nostats				= true,
		alternatepicks		= false,
		norepick			= false,
		noswap				= false,
		noagility			= false,
		nointelligence		= false,
		nostrength			= false,
		norespawntimer		= false,
		dropitems			= false,
		nopowerups			= false,
		casual				= false,
		allowduplicate		= true,
		shuffleteams		= false,
		tournamentrules		= false,
		hardcore			= false,
		devheroes			= false,
		autobalance			= false,
		verifiedonly		= false
	}
	
	local minPSR			= 0		-- Any
	local maxPSR			= 0		-- Any
	
	local function buildOptionString()
		local optionStringTemp	= ''
		optionStringTemp = (
			'map:'..mapName:GetString()..' '..
			'mode:'..gameMode:GetString()..' '..
			'region:'..serverRegion:GetString()..' '..
			'teamsize:'..teamSize:GetString()..' '..
			'spectators:'..spectatorCount:GetString()..' '
		)
		optionStringTemp = (
			optionStringTemp.. 
			'referees:'..refereeCount:GetString()..' '..
			'private:'..tostring(private:GetBoolean())..' '..
			'allchat:'..tostring(allchat:GetBoolean())..' '..
			'minpsr:'..minPSR..' '..
			'maxpsr:'..maxPSR
		)
		for k,v in pairs(gameOptions) do
			optionStringTemp = optionStringTemp..' '..k..':'..tostring(v)
		end
		if (Strife_Region.regionTable[Strife_Region.activeRegion].allowDevHeroes) then
			optionStringTemp = optionStringTemp .. ' ' .. 'finalheroesonly:' .. tostring(finalHeroesOnly:GetBoolean())
			optionStringTemp = optionStringTemp .. ' ' .. 'testingheroesonly:' .. tostring(testingHeroesOnly:GetBoolean())
		else
			optionStringTemp = optionStringTemp .. ' ' .. 'finalheroesonly:true'
			optionStringTemp = optionStringTemp .. ' ' .. 'testingheroesonly:false'
		end
		println('Create Game Options: ^y' .. optionStringTemp)
		optionString:Set(optionStringTemp)
	end

	container:RegisterWatchLua('mainPanelAnimationStatus', function(widget, trigger)
		if ((trigger.newMain ~= 24) and (trigger.newMain ~= 8)) and (trigger.newMain ~= -1) then			-- outro
			widget:FadeOut(250)
		elseif ((trigger.main ~= 24) and (trigger.main ~= 8)) and ((trigger.newMain ~= 24) and (trigger.newMain ~= 8)) then			-- fully hidden
			widget:SetVisible(false)	
		elseif ((trigger.newMain == 24) or (trigger.newMain == 8)) and (trigger.newMain ~= -1) then		-- intro
			libThread.threadFunc(function()	
				setMainTriggers({}) -- Default background
				wait(1)
				groupfcall('creategame_animation_widgets', function(_, widget) RegisterRadialEase(widget,  508, 555, true) widget:DoEventN(7) end)					
			end)
		elseif ((trigger.main == 24) or (trigger.main == 8)) then										-- fully displayed
			widget:SetVisible(true)	
		end
	end, false, nil, 'main', 'newMain', 'lastMain')	
	
	local function create_gameValidate()	-- Ensure settings are correct before allowing a match to be created
		local serverTypeString	= serverType:GetString()
		local connectionStatus	= LuaTrigger.GetTrigger('ConnectionStatus')
		startMatchButton:SetEnabled(
			string.len(gameName:GetString()) > 0 and
			( serverTypeString == 'local' or serverTypeString == 'practice' or serverTypeString == 'tutorial' or serverTypeString == 'local_dedicated' or serverTypeString == 'remote_automatic' or serverTypeString == 'remote_dedicated' or connectionStatus.isConnected )
		)
	end
	
	gameNameBox:SetInputLine(gameName:GetString())
	
	gameNameBox:SetCallback('onchange', function(widget)
		gameName:Set(widget:GetValue())
		gameName:SetSave(true)
		create_gameValidate()
	end)
	
	privateCheckbox_parent:SetVisible(1)
	privateCheckbox:SetButtonState(private:GetNumber())
	privateCheckbox:SetCallback('onbutton', function(widget)
		PlaySound('/ui/sounds/launcher/sfx_toggle.wav')
		private:Set(widget:GetValue())
		private:SetSave(true)
		create_gameValidate()
	end)		
	
	privateCheckbox:SetCallback('onclick', function(widget)
		-- sound_createGameCheckboxPrivate
		-- PlaySound('/path_to/filename.wav')
	end)
	
	allchatCheckbox_parent:SetVisible(1)
	allchatCheckbox:SetButtonState(allchat:GetNumber())
	allchatCheckbox:SetCallback('onbutton', function(widget)
		PlaySound('/ui/sounds/launcher/sfx_toggle.wav')
		allchat:Set(widget:GetValue())
		allchat:SetSave(true)
		create_gameValidate()
	end)		
	
	allchatCheckbox:SetCallback('onclick', function(widget)
		-- sound_createGameCheckboxAllChat
		-- PlaySound('/path_to/allchat_filename.wav')
	end)
	
	finalHeroesOnlyCheckbox_parent:SetVisible(Strife_Region.regionTable[Strife_Region.activeRegion].allowDevHeroes)
	finalHeroesOnlyCheckbox:SetButtonState(finalHeroesOnly:GetNumber())
	finalHeroesOnlyCheckbox:SetCallback('onbutton', function(widget)
		PlaySound('/ui/sounds/launcher/sfx_toggle.wav')
		finalHeroesOnly:Set(widget:GetValue())
		finalHeroesOnly:SetSave(true)
		create_gameValidate()
	end)
	
	finalHeroesOnlyCheckbox:SetCallback('onclick', function(widget)
		-- sound_createGameCheckboxFinalHeroes
		-- PlaySound('/path_to/filename.wav')
	end)
	
	testingHeroesOnlyCheckbox_parent:SetVisible(Strife_Region.regionTable[Strife_Region.activeRegion].allowDevHeroes)
	testingHeroesOnlyCheckbox:SetButtonState(testingHeroesOnly:GetNumber())
	testingHeroesOnlyCheckbox:SetCallback('onbutton', function(widget)
		PlaySound('/ui/sounds/launcher/sfx_toggle.wav')
		testingHeroesOnly:Set(widget:GetValue())
		testingHeroesOnly:SetSave(true)
		create_gameValidate()	
	end)	
	
	testingHeroesOnlyCheckbox:SetCallback('onclick', function(widget)
		-- sound_createGameCheckboxTestingHeroes
		-- PlaySound('/path_to/filename.wav')
	end)
	
	-- refereeCountDropdown:AddTemplateListItem(style_main_dropdownItem, 0, 'label', '0')
	-- refereeCountDropdown:AddTemplateListItem(style_main_dropdownItem, 1, 'label', '1')
	-- refereeCountDropdown:AddTemplateListItem(style_main_dropdownItem, 2, 'label', '2')
	-- refereeCountDropdown:SetSelectedItemByValue(refereeCount:GetNumber())

	-- spectatorCountDropdown:AddTemplateListItem(style_main_dropdownItem, 0, 'label', '0')
	spectatorCountDropdown:AddTemplateListItem(style_main_dropdownItem, 1, 'label', '1')
	spectatorCountDropdown:AddTemplateListItem(style_main_dropdownItem, 2, 'label', '2')
	spectatorCountDropdown:AddTemplateListItem(style_main_dropdownItem, 3, 'label', '3')
	spectatorCountDropdown:AddTemplateListItem(style_main_dropdownItem, 4, 'label', '4')
	spectatorCountDropdown:AddTemplateListItem(style_main_dropdownItem, 5, 'label', '5')
	spectatorCountDropdown:AddTemplateListItem(style_main_dropdownItem, 6, 'label', '6')
	spectatorCountDropdown:AddTemplateListItem(style_main_dropdownItem, 7, 'label', '7')
	spectatorCountDropdown:AddTemplateListItem(style_main_dropdownItem, 8, 'label', '8')
	spectatorCountDropdown:AddTemplateListItem(style_main_dropdownItem, 9, 'label', '9')
	spectatorCountDropdown:AddTemplateListItem(style_main_dropdownItem, 10, 'label', '10')
	spectatorCountDropdown:SetSelectedItemByValue(spectatorCount:GetNumber())

	-- teamSizeDropdown:AddTemplateListItem(style_main_dropdownItem, 0, 'label', 'game_setup_one_v_one')
	-- teamSizeDropdown:AddTemplateListItem(style_main_dropdownItem, 1, 'label', 'game_setup_one_v_one')
	-- teamSizeDropdown:AddTemplateListItem(style_main_dropdownItem, 2, 'label', 'game_setup_two_v_two')
	-- teamSizeDropdown:AddTemplateListItem(style_main_dropdownItem, 3, 'label', 'game_setup_three_v_three')
	-- teamSizeDropdown:AddTemplateListItem(style_main_dropdownItem, 4, 'label', 'game_setup_four_v_four')
	teamSizeDropdown:AddTemplateListItem(style_main_dropdownItem, 5, 'label', 'game_setup_five_v_five')
	teamSizeDropdown:SetSelectedItemByValue(teamSize:GetNumber())

	spectatorCountDropdown:SetCallback(
		'onselect', function(widget)
			PlaySound('/ui/sounds/launcher/sfx_browser_spectators.wav')
			-- createGameDropdownSpectatorSelect - Spectator count
			-- PlaySound('/soundpath/file.wav')
		
			spectatorCount:Set(widget:GetValue())
			spectatorCount:SetSave(true)
		end
	)
	
	spectatorCountDropdown:SetCallback('onfocus', function(widget)
		PlaySound('/ui/sounds/launcher/sfx_dropdown.wav')
	end)

	-- refereeCountDropdown:SetCallback(
		-- 'onselect', function(widget)
			-- refereeCount:Set(widget:GetValue())
			-- refereeCount:SetSave(true)
		-- end
	-- )

	teamSizeDropdown:SetCallback(
		'onselect', function(widget)
			-- createGameDropdownTeamSizeSelect - Team Size
			-- PlaySound('/soundpath/file.wav')
		
			teamSize:Set(widget:GetValue())
			teamSize:SetSave(true)
		end
	)
	
	teamSizeDropdown:SetCallback('onfocus', function(widget)
		PlaySound('/ui/sounds/launcher/sfx_dropdown.wav')
	end)
	
	--
	
	local function PopulateRegionDropdown(_, trigger)

		regionDropdown:ClearItems()
		
		local trigger = trigger or LuaTrigger.GetTrigger('ChatAvailability')
		local default 
		
		if (trigger) and (trigger.lobby) and (trigger.lobby.enabled) and (trigger.lobby.regions) then
			for k,v in ipairs(trigger.lobby.regions) do
				if (v.enabled) and (v.visible) then
					regionDropdown:AddTemplateListItem(style_main_dropdownItem, v.name, 'label', Translate('game_region_' .. v.name), 'flag', Translate('game_region_flag_' .. v.name))
					if (v.default) then
						default = default or v.name
					end
				end
			end	
		else
			regionDropdown:AddTemplateListItem(style_main_dropdownItem, 'USE', 'label', Translate('game_region_USE'))
			regionDropdown:AddTemplateListItem(style_main_dropdownItem, 'USW', 'label', Translate('game_region_USW'))
			regionDropdown:AddTemplateListItem(style_main_dropdownItem, 'EU', 'label', Translate('game_region_EU'))
			regionDropdown:AddTemplateListItem(style_main_dropdownItem, 'SEA', 'label', Translate('game_region_SEA'))
			regionDropdown:AddTemplateListItem(style_main_dropdownItem, 'GAPP', 'label', Translate('game_region_GAPP'))
		end
		
		if (Empty(serverRegion:GetString())) then
			if (default) then
				regionDropdown:SetSelectedItemByValue(default)
			else
				regionDropdown:SetSelectedItemByIndex(0)
			end
		else
			regionDropdown:SetSelectedItemByValue(serverRegion:GetString())
		end
		
		regionDropdown:SetCallback(
			'onselect', function(widget)
				-- createGameDropdownRegionSelect
				-- PlaySound('/soundpath/file.wav')
				if (LuaTrigger.GetTrigger('mainPanelStatus').main == 24) then
					PlaySound('/ui/sounds/launcher/sfx_browser_region.wav')
				end
				serverRegion:Set(widget:GetValue())
				serverRegion:SetSave(true)
			end
		)
		
		regionDropdown:SetCallback('onfocus', function(widget)
			PlaySound('/ui/sounds/launcher/sfx_dropdown.wav')
		end)
		
	end
	
	container:RegisterWatchLua('ChatAvailability', function(widget, trigger) PopulateRegionDropdown(widget, trigger) end)
	PopulateRegionDropdown()
	
	mapDropdown:ClearItems()

	for k,v in pairs(GetMaps()) do
		mapDropdown:AddTemplateListItem(style_main_dropdownItem, v.fileName, 'label', Translate(v.displayName))
	end
	mapDropdown:SetSelectedItemByValue(mapName:GetString())
	mapDropdown:SetCallback(
		'onselect', function(widget)
			PlaySound('/ui/sounds/launcher/sfx_browser_map.wav')
			-- createGameDropdownMapSelect
			-- PlaySound('/soundpath/file.wav')
			mapName:Set(widget:GetValue())
			mapName:SetSave(true)
		end
	)
	
	mapDropdown:SetCallback('onfocus', function(widget)
		PlaySound('/ui/sounds/launcher/sfx_dropdown.wav')
	end)
	
	if (Strife_Region.regionTable[Strife_Region.activeRegion]) and (Strife_Region.regionTable[Strife_Region.activeRegion].enableDevMaps) then
		mapDropdown_parent:SetVisible(1)
	else
		mapDropdown_parent:SetVisible(0)
	end
	
	modeDropdown:ClearItems()
	modeDropdown:AddTemplateListItem(style_main_dropdownItem, 'normal', 'label', 'game_setup_normal', 'texture', '/ui/main/play/textures/icon_team.tga.tga')
	if ((not mainUI.featureMaintenance) or (not mainUI.featureMaintenance['captainsmode'])) then
		modeDropdown:AddTemplateListItem(style_main_dropdownItem, 'captainsmode', 'label', 'game_setup_captainsmode', 'texture', '/ui/main/play/textures/captainshat.tga', 'color', 'white')
	end
	-- modeDropdown:AddTemplateListItem(style_main_dropdownItem, 'randomdraft', 'label', 'game_setup_random_draft', 'texture', '/ui/_textures/icons/randomdraft.tga', 'color', 'white')
	-- modeDropdown:AddTemplateListItem(style_main_dropdownItem, 'singledraft', 'label', 'game_setup_single_draft', 'texture', '/ui/_textures/icons/singledraft.tga', 'color', 'white')
	-- modeDropdown:AddTemplateListItem(style_main_dropdownItem, 'banningdraft', 'label', 'game_setup_banningdraft', 'texture', '/ui/_textures/icons/banningdraft.tga', 'color', 'white')
	-- modeDropdown:AddTemplateListItem(style_main_dropdownItem, 'banningpick', 'label', 'game_setup_banningpick', 'texture', '/ui/_textures/icons/banningpick.tga', 'color', 'white')
	-- modeDropdown:AddTemplateListItem(style_main_dropdownItem, 'allrandom', 'label', 'mainlobby_label_all_random', 'texture', '/ui/_textures/icons/forcerandom.tga', 'color', 'white')
	modeDropdown:SetSelectedItemByValue(gameMode:GetString())
	
	modeDropdown:SetCallback(
		'onselect', function(widget)
			PlaySound('/ui/sounds/launcher/sfx_browser_mode.wav')
			gameMode:Set(widget:GetValue())
			gameMode:SetSave(true)
		end
	)
	
	modeDropdown:SetCallback('onfocus', function(widget)
		PlaySound('/ui/sounds/launcher/sfx_dropdown.wav')
	end)

	-- if (Strife_Region.regionTable[Strife_Region.activeRegion]) and (Strife_Region.regionTable[Strife_Region.activeRegion].enableDevMaps) then
		-- modeDropdown_parent:SetVisible(1)
	-- else
		-- modeDropdown_parent:SetVisible(0)
	-- end	
	
	
	libGeneral.createGroupTrigger('serverConnectionStatus', { 'LocalServerAvailable', 'ConnectionStatus' })
	
	interface:GetWidget('main_create_game_throbber'):RegisterWatch('HostErrorMessage', function(widget, trigger) 
		widget:SetVisible(false)
	end)	
	
	interface:GetWidget('main_create_game_throbber'):RegisterWatchLua('ConnectionStatus', function(widget, trigger) 
		if (trigger.isConnected) then
			widget:SetVisible(false)
		end
	end)
	
	serverDropdown:RegisterWatchLua('serverConnectionStatus', function(widget, groupTrigger)
		local triggerLocalServer	= groupTrigger[1]
		local triggerConnection		= groupTrigger[2]

		serverDropdown:ClearItems()
		if triggerConnection.isConnected then
			serverDropdown:AddTemplateListItem(style_main_dropdownItem, 'selected', 'label', triggerConnection.serverName)	-- Only one that wouldn't actually have an icon
		end

		serverDropdown:AddTemplateListItem(style_main_dropdownItem, 'remote_dedicated', 'label', 'game_setup_remote_dedicated', 'texture', '/ui/_textures/icons/automatic.tga')
		
		if (Strife_Region.regionTable[Strife_Region.activeRegion]) and (Strife_Region.regionTable[Strife_Region.activeRegion].enableDevServerTypes) then
			
			-- serverDropdown:AddTemplateListItem(style_main_dropdownItem, 'remote_automatic', 'label', 'game_setup_automatic', 'texture', '/ui/_textures/icons/automatic.tga')
			
			if triggerLocalServer.localServerAvailable then
				serverDropdown:AddTemplateListItem(style_main_dropdownItem, 'local', 'label', 'game_setup_local', 'texture', '/ui/_textures/icons/local.tga')
				serverDropdown:AddTemplateListItem(style_main_dropdownItem, 'local_dedicated', 'label', 'game_setup_local_dedicated', 'texture', '/ui/_textures/icons/local.tga')
			end
			
			serverDropdown:AddTemplateListItem(style_main_dropdownItem, 'tutorial', 'label', 'game_setup_tutorial', 'texture', '/ui/_textures/icons/local.tga')
			serverDropdown:AddTemplateListItem(style_main_dropdownItem, 'practice', 'label', 'game_setup_practice', 'texture', '/ui/_textures/icons/local.tga')
			-- serverDropdown:AddTemplateListItem(style_main_dropdownItem, 'browse', 'label', 'game_setup_browse')
			
		end
		
		if (triggerConnection.isConnected) then
			serverDropdown:SetSelectedItemByValue('selected')
		elseif serverDropdown:HasListItem(serverType:GetString()) then
			serverDropdown:SetSelectedItemByValue(serverType:GetString())
		end	

	end)
	
	serverDropdown:SetCallback('onselect', function(widget)
		-- createGameDropdownServerSelect - Select server type (local, practice, etc.)
		-- PlaySound('/soundpath/file.wav')

		if (LuaTrigger.GetTrigger('mainPanelStatus').main == 24) then
			PlaySound('/ui/sounds/launcher/sfx_browser_servertype.wav')
		end
		if (not Empty(widget:GetValue())) and (widget:GetValue() ~= 'selected') and (widget:GetValue() ~= 'browse') then
			serverType:Set(widget:GetValue())
			serverType:SetSave(true)
		end
		create_gameValidate()
		if (GetWidget('create_game'):IsVisible()) and (widget:GetValue() == 'browse') then
			GetWidget('server_browser'):FadeIn(150)
		end
	end)
	
	serverDropdown:SetCallback('onfocus', function(widget)
		PlaySound('/ui/sounds/launcher/sfx_dropdown.wav')
	end)
	
	local selectedServer = ''
	local function SelectServer()
		Connect(selectedServer, true, 'loading', false, false)
		-- interface:UICmd([[Connect(']] .. selectedServer .. [[', '', true);]])
		--CancelServerList()
		GetWidget('server_browser'):SetVisible(false)
		interface:GetWidget('main_create_game_throbber'):FadeIn(250)
	end
	
	serverList:SetCallback('onselect', function(widget)
		selectedServer = widget:GetValue()
		create_game_select_server_btn:SetEnabled(true)
		
		-- createGameServerListEntrySelect - Select server list (hidden atm)
		PlaySound('/ui/sounds/launcher/sfx_browser_choosegame.wav')
	end)
	serverList:SetCallback('ondoubleclick', function(widget)
	
		-- createGameServerListEntryConfirm - Confirm server selection (double-click entry) (hidden atm)
		PlaySound('/ui/sounds/launcher/sfx_browser_join.wav')
	
		selectedServer = widget:GetValue()
		SelectServer()
	end)	
	
	create_game_select_server_btn:SetCallback('onclick', function(widget)	
		-- createGameSelectServer - Create Game Prompt Select Server Button (hidden atm)
		PlaySound('/ui/sounds/launcher/sfx_browser_join.wav')
		SelectServer()
	end)
	
	create_game_select_server_btn:SetCallback('onshow', function(widget)	
		widget:SetEnabled(false)
	end)	
	
	startMatchButton:SetCallback('onclick', function(widget)
		PlaySound('/ui/sounds/launcher/sfx_browser_creategame.wav')
		local connectionStatus	= LuaTrigger.GetTrigger('ConnectionStatus')
		-- createGameCreateButton - Create Game Prompt Create Game Button
		-- PlaySound('/soundpath/file.wav')

		buildOptionString()	
		-- println('serverType:GetString() | ' .. tostring(serverType:GetString()) )
		local serverTypeString = serverType:GetString()
		if (not connectionStatus.isConnected) and (serverTypeString == 'local' or serverTypeString == 'local_dedicated' or serverTypeString == 'remote_dedicated' or serverTypeString == 'practice' or serverTypeString == 'tutorial') then
			print('StartGame\n')
			StartGame(serverTypeString, StripColorCodes(gameName:GetString()), optionString:GetString())
		end
		
	end)
	
	FindChildrenClickCallbacks(container)
end

create_gameRegister(object)
