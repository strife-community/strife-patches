Login = Login or {}
Login.selectedLoginMethod = 'igames'

local interface = object

function loginIdentitiesRegisterIdentity(object, index)
	local button		= object:GetWidget('loginChooseIdentityEntry'..index)
	local label			= object:GetWidget('loginChooseIdentityEntry'..index..'Name')

	label:RegisterWatchLua('IdentIDList', function(widget, trigger) widget:SetText(trigger['identNick' .. index]) end)
	-- button:RegisterWatchLua('', function(widget, trigger) end)
	button:SetCallback('onclick', function(widget)
		PickIdentID(index)
		-- mainLoginSelectIdent
		-- PlaySound('/path_to/filename.wav')
	end)
end

function loginRegister(object)
	local container				= object:GetWidget('main_login_prompt_parent')
	local usernameBox			= object:GetWidget('loginUsernameBox')
	local passwordBox			= object:GetWidget('loginPasswordBox')
	local passwordBoxCover		= object:GetWidget('loginPasswordBoxCover')
	local passwordBoxSaved		= object:GetWidget('loginPasswordBoxSaved')
	local loginButton			= object:GetWidget('main_login_prompt_login')
	local loginQuitButton		= object:GetWidget('loginQuitButton')

	local saveUsernameCheckbox	= object:GetWidget('loginSaveUsernameCheckbox')
	local autoLoginCheckbox		= object:GetWidget('loginAutoCheckbox')

	-- local progressContainer		= object:GetWidget('loginProgressContainer')
	-- local failureContainer		= object:GetWidget('loginFailureContainer')
	-- local failureDescription		= object:GetWidget('loginFailureDescription')
	-- local failureOKButton		= object:GetWidget('loginFailureOKButton')

	local identChoose			= object:GetWidget('loginChooseIdentity')
	local identChooseInput		= object:GetWidget('loginNewIdentityInput')
	local identChooseSubmit		= object:GetWidget('loginNewIdentitySubmit')
	
	local main_login_prompt_username_remember				= object:GetWidget('main_login_prompt_username_remember')
	local main_login_prompt_username_remember_checkbox		= object:GetWidget('main_login_prompt_username_remember_checkbox')
	
	local main_login_prompt_password_remember		= object:GetWidget('main_login_prompt_password_remember')
	local main_login_prompt_password_remember_checkbox		= object:GetWidget('main_login_prompt_password_remember_checkbox')
	
	local main_login_prompt_password_lost		= object:GetWidget('main_login_prompt_password_lost')
	local main_login_prompt_createaccount		= object:GetWidget('main_login_prompt_createaccount')
	local loginAtKeyBox							= object:GetWidget('loginAtKeyBox')

	local rememberName		= Cvar.GetCvar('login_rememberName')		or Cvar.CreateCvar('login_rememberName', 'bool', 'false')
	local rememberPassword	= Cvar.GetCvar('login_rememberPassword')	or Cvar.CreateCvar('login_rememberPassword', 'bool', 'false')
	local username			= Cvar.GetCvar('login_name')				or Cvar.CreateCvar('login_name', 'string', 'false')
	local password			= Cvar.GetCvar('login_password')			or Cvar.CreateCvar('login_password', 'string', 'false')
	local secondary_auth	= Cvar.GetCvar('login_secondary_auth')		or Cvar.CreateCvar('login_secondary_auth', 'string', 'false')
	
	local function validAutoLogin()
		return(
			rememberName:GetBoolean() and
			rememberPassword:GetBoolean() and
			string.len(username:GetString()) > 0 and
			string.len(password:GetString()) > 0
		)
	end	
	
	local canAutoLogin = true
	container:SetCallback('onshow', function()
		container:Sleep(1, function()
			if canAutoLogin and validAutoLogin() then
				println('^o^: Auto Login ')
				Cmd([[Login]])
				canAutoLogin = false
			end	
			if rememberName:GetBoolean() or string.len(username:GetString()) > 0 then
				passwordBox:SetDefaultFocus(true)
				passwordBox:SetFocus(true)
			else
				usernameBox:SetDefaultFocus(true)
				usernameBox:SetFocus(true)
			end			
		end)
	end)
	
	container:SetCallback('onhide', function()
		passwordBox:SetDefaultFocus(false)
		usernameBox:SetDefaultFocus(false)
	end)	
	
	if (Strife_Region.regionTable) and (Strife_Region.regionTable[Strife_Region.activeRegion]) and (Strife_Region.regionTable[Strife_Region.activeRegion].allowIdentSelection) then
		main_login_prompt_password_remember:SetVisible(1)
	else
		rememberPassword:Set('false')
	end
	
	main_login_prompt_username_remember:SetCallback('onclick', function(widget)
		if (rememberName:GetBoolean()) then
			rememberName:Set('false')
		else
			rememberName:Set('true')
		end
		rememberName:SetSave(true)
		if (rememberName:GetBoolean()) then
			main_login_prompt_username_remember_checkbox:SetButtonState(1)
		else
			main_login_prompt_username_remember_checkbox:SetButtonState(0)
			main_login_prompt_password_remember_checkbox:SetButtonState(0)
			rememberPassword:Set('false')
		end
	end)	
	
	main_login_prompt_username_remember_checkbox:SetCallback('onshow', function(widget)
		if (rememberName:GetBoolean()) then
			widget:SetButtonState(1)	
		else
			widget:SetButtonState(0)
		end	
	end)	
	
	main_login_prompt_password_remember:SetCallback('onclick', function(widget)
		if (rememberPassword:GetBoolean()) then
			rememberPassword:Set('false')
		else
			rememberPassword:Set('true')
		end
		rememberPassword:SetSave(true)
		if (rememberPassword:GetBoolean()) then
			main_login_prompt_password_remember_checkbox:SetButtonState(1)
			main_login_prompt_username_remember_checkbox:SetButtonState(1)
			rememberName:Set('true')	
		else
			main_login_prompt_password_remember_checkbox:SetButtonState(0)
		end
	end)	
	
	main_login_prompt_password_remember_checkbox:SetCallback('onshow', function(widget)
		if (rememberPassword:GetBoolean()) then
			widget:SetButtonState(1)	
		else
			widget:SetButtonState(0)
		end	
	end)
	
	local function CheckRemember()
		if rememberName:GetBoolean() and rememberPassword:GetBoolean() then
			username:SetSave(true)
			password:SetSave(true)
		elseif rememberName:GetBoolean() then
			username:SetSave(true)
			password:Set('')
		else
			username:Set('')
			password:Set('')
		end
	end
	
	main_login_prompt_password_lost:SetCallback('onclick', function(widget)
		mainUI.OpenURL(Strife_Region.regionTable[Strife_Region.activeRegion].forgotPasswordURL or 'http://www.strife.com')	
	end)	
	
	main_login_prompt_createaccount:SetCallback('onclick', function(widget)
		if (Strife_Region.regionTable) and (Strife_Region.regionTable[Strife_Region.activeRegion]) and (Strife_Region.regionTable[Strife_Region.activeRegion].new_player_experience) then
			-- NewPlayerExperience.resetTutorial()
			NewPlayerExperience.resetAll()	-- This used to require login
			local mainPanelStatus = LuaTrigger.GetTrigger('mainPanelStatus')
			local loginStatus = LuaTrigger.GetTrigger('LoginStatus')
			if (loginStatus.launchedViaSteam) then
				mainUI.ShowSplashScreen('splash_screen_steam_link')
			elseif NewPlayerExperience.requiresLogin then
				mainUI.OpenURL(Strife_Region.regionTable[Strife_Region.activeRegion].createAccountURL or 'http://www.strife.com')
			else
				mainPanelStatus.main = 0
			end
			mainPanelStatus:Trigger(false)
		end
	end)
	
	container:RegisterWatchLua('IdentIDList', function(widget, trigger, trigger2)
		if (not Empty(trigger['identNick0'])) and Empty(trigger['identNick1']) and (not (Strife_Region.regionTable[Strife_Region.activeRegion].allowIdentSelection)) then
			PickIdentID(0)
		end
	end)

	libGeneral.createGroupTrigger('identChooseTrigger',  {
		'mainPanelStatus.isLoggedIn',
		'mainPanelStatus.hasIdent',
		'mainPanelStatus.gamePhase',
		'mainPanelStatus.main',
		'mainPanelStatus.externalLogin',
		'IdentIDList.identNick0',
		'IdentIDList.identNick1',
		'AccountInfo.tutorialProgress',
		'newPlayerExperience.tutorialProgress'		
	})
	
	identChoose:RegisterWatchLua('identChooseTrigger', function(widget, groupTrigger)
		local trigger 				= groupTrigger['mainPanelStatus']
		local identIDList 			= groupTrigger['IdentIDList']
		local AccountInfo 			= groupTrigger['AccountInfo']
		local newPlayerExperience 	= groupTrigger['newPlayerExperience']
		local LoginStatus 			= LuaTrigger.GetTrigger('LoginStatus')
		
		if ((trigger.isLoggedIn) and (not trigger.hasIdent) and (trigger.main == 0) and (trigger.gamePhase == 0)) and ( ( ((not trigger.externalLogin) or (LoginStatus.launchedViaSteam and (not LoginStatus.loggedInViaSteam))) or (AccountInfo.tutorialProgress > NPE_PROGRESS_ENTEREDNAME) or (newPlayerExperience.tutorialProgress > NPE_PROGRESS_ENTEREDNAME)) or (not Empty(identIDList['identNick1'])) ) then
			if Empty(identIDList['identNick0']) then
				-- show the nicer create ident dialog instead in this case
				widget:FadeOut(250)
				widget:GetWidget('login__enterName'):FadeIn(250)
			else
				widget:FadeIn(250)
				widget:GetWidget('login__enterName'):FadeOut(250)
			end
		else
			widget:FadeOut(250)
			-- widget:GetWidget('login__enterName'):FadeOut(250)
		end
	end, false, nil)
	
	local login__enterName				= object:GetWidget('login__enterName')
	local login__enterName_submit		= object:GetWidget('login__enterName_submit')
	local login__enterName_haveAccount	= object:GetWidget('login__enterName_haveAccount')
	local login__enterName_input		= object:GetWidget('login__enterName_input')

	local function login__enterName_valid()
		local inputValue	= login__enterName_input:GetValue()
		return (inputValue and (string.len(inputValue) > 0) and (not ChatCensor.IsCensored(inputValue)))
	end

	local function login__enterName_submitName()
		local inputValue = login__enterName_input:GetValue()
		Cvar.GetCvar('net_name'):Set(inputValue)
		
		local IdentIDList = LuaTrigger.GetTrigger('IdentIDList')		
		if (not LuaTrigger.GetTrigger('LoginStatus').hasIdent) and ( (not IdentIDList) or (not IdentIDList.identNick0) or (Empty(IdentIDList.identNick0)) ) then
			CreateIdentID(inputValue)
		end
		
		login__enterName_input:EraseInputLine()

		-- login__enterName:FadeOut(250)
	end
	
	login__enterName:SetCallback('onshow', function(widget)
		login__enterName:SetCallback('onframe', function(widget)
			local IdentIDList = LuaTrigger.GetTrigger('IdentIDList')
			if (LuaTrigger.GetTrigger('LoginStatus').isLoggedIn and LuaTrigger.GetTrigger('LoginStatus').hasIdent) then
				login__enterName:ClearCallback('onframe')
				login__enterName_input:EraseInputLine()
				login__enterName:FadeOut(250)

			end			
		end)
	end)
	
	login__enterName:SetCallback('onhide', function(widget)
		login__enterName:ClearCallback('onframe')
	end)	
	

	login__enterName_input:SetCallback('onchange', function(widget)
		login__enterName_submit:SetEnabled(login__enterName_valid())
		if not widget:HasFocus() then
			object:GetWidget('login__enterName_input_coverup'):SetVisible(string.len(widget:GetValue()) <= 0)
		end
	end)

	object:GetWidget('login__enterName_input_coverup'):SetVisible(string.len(login__enterName_input:GetValue()) <= 0)

	login__enterName_input:SetCallback('onfocus', function(widget)
		object:GetWidget('login__enterName_input_coverup'):SetVisible(false)
	end)
	
	login__enterName_input:SetCallback('onlosefocus', function(widget)
		object:GetWidget('login__enterName_input_coverup'):SetVisible(string.len(widget:GetValue()) <= 0)
	end)
	

	login__enterName_submit:SetCallback('onclick', function(widget)
		login__enterName_submitName()
	end)	
	
	function login__enterName_esc()
		login__enterName_input:EraseInputLine()
	end

	function login__enterName_enter()
		if login__enterName_valid() then
			login__enterName_submitName()
		end
	end		

	identChooseInput:SetCallback('onchange', function(widget)
		local inputValue = identChooseInput:GetValue()
		identChooseSubmit:SetEnabled(inputValue and (string.len(inputValue) > 0) and (not ChatCensor.IsCensored(inputValue)))
	end)

	local function loginNewIdentSubmit()
		CreateIdentID(identChooseInput:GetValue())
	end

	function loginNewIdentInputEnter()
		loginNewIdentSubmit()

		-- soundEvent - Login New Identity Textbox Enter
		-- PlaySound('/soundpath/file.wav')
	end

	identChooseSubmit:SetCallback('onclick', function(widget)
		-- soundEvent - New Identity Submit
		-- PlaySound('/soundpath/file.wav')
		loginNewIdentSubmit()
		widget:SetEnabled(0)
		widget:Sleep(5000, function()
			widget:SetEnabled(1)
		end)
	end)

	local savedPassCoverUpdate = LuaTrigger.CreateCustomTrigger(	-- Seems to need at least one param to function
		'loginSavedPassCoverUpdate',
		{
			{ name	= 'update',	type	= 'boolean' }
		}
	)

	local function validForLoginAttempt()
		return(
			string.len(usernameBox:GetValue()) > 0 and
			(
				string.len(passwordBox:GetValue()) > 0 or rememberPassword:GetBoolean()
			)
		)
	end
	
	local randomWaitThread
	local function updateLoginButton(trigger)
		trigger = trigger or LuaTrigger.GetTrigger('LoginStatus')
		local statusTitle = trigger.statusTitle
		if (statusTitle == 'error_request_timed_out') or (statusTitle == 'error_maintenance') then
			GetWidget('main_login_prompt_loginLabel'):SetText(Translate('general_wait'))
			loginButton:SetEnabled(0)
			if (randomWaitThread) then
				randomWaitThread:kill()
				randomWaitThread = nil
			end
			randomWaitThread = libThread.threadFunc(function()	
				local randomWait = math.random(3000,15000)
				wait(randomWait)		
				if (loginButton) and (loginButton:IsValid()) then
					loginButton:SetEnabled(1)
				end
				GetWidget('main_login_prompt_loginLabel'):SetText(Translate('general_login'))
				randomWaitThread = nil
			end)
		else
			loginButton:SetEnabled( validForLoginAttempt() and (not (trigger.isLoggedIn or (statusTitle ~= 'offline' and statusTitle ~= 'failure'))) )
		end
	end
	
	local function updateFormSubmitValid()

		passwordBoxCover:SetVisible(string.len(usernameBox:GetValue()) == 0)
		
		updateLoginButton()
	end

	passwordBoxSaved:RegisterWatchLua('loginSavedPassCoverUpdate', function(widget, trigger)
		passwordBoxSaved:SetVisible(
			string.len(usernameBox:GetValue()) > 0 and
			rememberPassword:GetBoolean() and
			not passwordBox:HasFocus()
		)
	end)

	for i=0,5,1 do
		loginIdentitiesRegisterIdentity(object, i)
	end
	
	function Login.AttemptSteamLink()
		if (Steam) and (Steam.LinkAccount) then
			Steam.LinkAccount()
		else
			println('^rError: Steam object not found: LinkAccount')			
		end
	end	
	
	function Login.AttemptCreateSteamAccount()
		if (Steam) and (Steam.CreateAccount) then
			Steam.CreateAccount()
		else
			println('^rError: Steam object not found: CreateAccount')
		end
	end		
	
	function Login.AttemptS2Login()
		println('^o^: Login.AttemptS2Login()')
		if string.find(username:GetString(), "@") then
			password:Set(BCrypt(passwordBox:GetValue()))
			Cmd([[Login]])	
		else
			GenericDialog(
				'general_error_login', '', Translate('error_account_not_email'), 'general_ok', '',
					function()
					end,
					nil,
					true
			)
		end
	end
	
	function Login.AttemptAsiasoftLogin()
		println('^o^: AttemptAsiasoftLogin ')
		if (AsiaSoft) and (AsiaSoft.Login) then
			AsiaSoft.Login(username:GetString(), passwordBox:GetValue(), loginAtKeyBox:GetValue())
		else
			Login.AttemptS2Login()
		end
	end
	
	function Login.GetSelectedLoginMethodTable()
		for i,v in pairs(Strife_Region.regionTable[Strife_Region.activeRegion].allowedLoginMethods) do
			if (v[1] == Login.selectedLoginMethod) then
				return v
			end
		end
		return nil
	end
	
	function Login.SetUpAsiasoftLogin()
		println('^o SetUpAsiasoftLogin ')
		-- GetWidget('main_login_prompt_atkey'):SetVisible(1)
		-- GetWidget('main_login_prompt_standard_content'):SetY('-50s')
		-- GetWidget('main_login_prompt_login_content'):SetY('50s')
		GetWidget('main_login_prompt_atkey'):SetVisible(0)
		GetWidget('main_login_prompt_standard_content'):SetY('0')
		GetWidget('main_login_prompt_login_content'):SetY('0')			
		
		usernameBox:SetCallback('onchange', function(widget)
			if widget:HasFocus() or not rememberName:GetBoolean() then
				passwordBox:EraseInputLine()
				username:Set(widget:GetValue())
			end

			if username:GetString() ~= widget:GetValue() then
				passwordBox:EraseInputLine()
			end

			updateFormSubmitValid()
			savedPassCoverUpdate:Trigger(true)
		end)		
		
	end
	
	function Login.SetUpS2Login()
		println('^o SetUpS2Login ')
		GetWidget('main_login_prompt_atkey'):SetVisible(0)
		GetWidget('main_login_prompt_standard_content'):SetY('0')
		GetWidget('main_login_prompt_login_content'):SetY('0')	

		usernameBox:SetCallback('onchange', function(widget)
			if widget:HasFocus() or not rememberName:GetBoolean() then
				passwordBox:EraseInputLine()
				username:Set(widget:GetValue())
			end

			if username:GetString() ~= widget:GetValue() then
				passwordBox:EraseInputLine()
			end

			if string.find(widget:GetValue(), "@") then
				GetWidget('main_login_prompt_username_label'):SetColor('white')
			else
				GetWidget('main_login_prompt_username_label'):SetColor('red')
			end		
			
			updateFormSubmitValid()
			savedPassCoverUpdate:Trigger(true)
		end)
		
	end
	
	function Login.AttemptLogin()
		local methodTable = Login.GetSelectedLoginMethodTable()
		if (methodTable) and (methodTable[2]) then	
			Login[methodTable[2]]()
		else
			Login.AttemptS2Login()
		end
	end

	function Login.AttemptSetUpLogin()
		println('^o AttemptSetUpLogin ')
		local methodTable = Login.GetSelectedLoginMethodTable()	
		if (methodTable) and (methodTable[3]) then	
			Login[methodTable[3]]()
		else
			Login.SetUpS2Login()
		end
		GetWidget('main_login_prompt_username_label'):SetColor('white')
	end	
	
	loginButton:SetCallback('onclick', function(widget)
		Login.AttemptLogin()
	end)
	
	loginButton:SetCallback('onrightclick', function(widget)
		-- soundEvent - Login Button Click
		if (GetCvarBool('ui_dev')) then
			hackLogin()
		else
			Login.AttemptLogin()	
		end
	end)	

	usernameBox:SetCallback('onshow', function(widget)
		if string.len(username:GetString()) > 0 and rememberName:GetBoolean() then
			widget:SetInputLine(username:GetString())
			if rememberPassword:GetBoolean() then
				widget:SetFocus(true)
				widget:SetFocus(false)	-- Force clear focus
			else
				passwordBox:SetFocus(true)
			end
		else
			widget:SetFocus(true)
			rememberName:Set('false')
			rememberPassword:Set('false')
			main_login_prompt_password_remember_checkbox:SetButtonState(0)
		end
		updateFormSubmitValid()
		savedPassCoverUpdate:Trigger(true)
	end)

	passwordBox:SetCallback('onchange', function(widget)
		if widget:HasFocus() or not rememberPassword:GetBoolean() then
			if string.len(widget:GetValue()) > 0 then
				password:Set(BCrypt(widget:GetValue()))
			else
				password:Set('')
			end

			savedPassCoverUpdate:Trigger(true)
		end
		updateFormSubmitValid()
	end)
	
	loginButton:RegisterWatchLua('LoginStatus', function(widget, trigger)
		local statusTitle = trigger.statusTitle
		local statusDescription = trigger.statusDescription
		if statusTitle == 'success' then
			-- mainLoginSuccess
			PlaySound('/ui/sounds/sfx_ui_login.wav')
		
		elseif statusTitle == 'identfailure' then
			CameraShake()
			GenericDialog(
				'general_error_login', '', Translate(trigger.statusDescription), 'general_ok', '',
					function()
					end,
					nil,
					true
			)	
			--[[			
			if (object:GetWidget('newPlayerExperience_enterName')) and (NewPlayerExperience) and (NewPlayerExperience.trigger) and (NewPlayerExperience.trigger.tutorialProgress) and (NewPlayerExperience.trigger.tutorialProgress < NPE_PROGRESS_ENTEREDNAME) then
				object:GetWidget('newPlayerExperience_enterName'):SetVisible(1)
			elseif (object:GetWidget('login__enterName')) then
				object:GetWidget('login__enterName'):SetVisible(1)				
			end
			--]]
		elseif statusTitle == 'failure' then
		
			-- mainLoginFailure
			-- PlaySound('/path_to/filename.wav')
		
			if trigger.exitOnFailure then
				CameraShake()
				GenericDialog(
					'general_error_login', '', Translate(trigger.statusDescription), 'general_ok', '',
						function() QuitClient(true) end,
						function() QuitClient(true) end,
						true
				)
			else
				CameraShake()
				GenericDialog(
					'general_error_login', '', Translate(trigger.statusDescription), 'general_ok', '',
						function()
							passwordBox:SetFocus(true)
						end,
						function()
							passwordBox:SetFocus(true)
						end,
						true
				)
				PlaySound('/ui/sounds/sfx_ui_back.wav')
				e('trigger.statusDescription', trigger.statusDescription)
				if (trigger.statusDescription ~= 'error_password_incorrect') and (trigger.statusDescription ~= 'error_account_not_found') then
					MOTD(false)
				end
			end
			-- Too Bad!!!
			if (math.random(1,100) == 100) or (trigger.statusDescription == 'error_account_disabled') or (trigger.statusDescription == 'error_account_suspended') then
				CameraShake()
			end
		end
		updateLoginButton(trigger)

	end, false, nil, 'statusDescription', 'statusTitle', 'isLoggedIn')

	usernameBox:RegisterWatchLua('LoginStatus', function(widget, trigger)
		local isLoggedIn			= trigger.isLoggedIn
		local statusTitle			= trigger.statusTitle

		if trigger.loginChange and isLoggedIn and not rememberName:GetBoolean() then
			widget:EraseInputLine()
		end

		if ((statusTitle ~= 'offline' or statusTitle == 'failure') and not isLoggedIn) then
			widget:SetFocus(false)
		end
	end, false, nil, 'loginChange', 'isLoggedIn', 'statusTitle')

	passwordBox:RegisterWatchLua('LoginStatus', function(widget, trigger)
		local isLoggedIn			= isLoggedIn
		local statusTitle			= trigger.statusTitle

		if trigger.loginChange and trigger.isLoggedIn and not rememberPassword:GetBoolean() then
			widget:EraseInputLine()
		end

		if ((statusTitle ~= 'offline' or statusTitle == 'failure') and not isLoggedIn) then
			widget:SetFocus(false)
		end
	end, false, nil, 'loginChange', 'isLoggedIn', 'statusTitle')

	function loginAtKeyBoxEsc()
		loginAtKeyBox:EraseInputLine()
	end

	function loginAtKeyBoxEnter()
		if validForLoginAttempt() then
			Login.AttemptLogin()
		end
	end	
	
	function loginUserBoxEnter()	-- Call from widget
		passwordBox:SetFocus(true)
		if validForLoginAttempt() then
			Login.AttemptLogin()
		end
	end

	function loginPassBoxEnter()	-- Call from widget
		if validForLoginAttempt() then
			Login.AttemptLogin()
		end
	end

	passwordBox:SetCallback('onfocus', function(widget)
		if passwordBoxCover:IsVisible() then
			widget:EraseInputLine()
		end
		savedPassCoverUpdate:Trigger(true)
	end)

	passwordBox:SetCallback('onlosefocus', function(widget)
		savedPassCoverUpdate:Trigger(true)
	end)

	-- === REGION SELECTION === --
	local main_login_regionselection_combobox 			= GetWidget('main_login_regionselection_combobox')
	local main_login_regionselection_parent 			= GetWidget('main_login_regionselection_parent')
	local main_login_prompt_current_region_change 		= GetWidget('main_login_prompt_current_region_change')
	local main_login_prompt_current_region 				= GetWidget('main_login_prompt_current_region')
	local main_login_prompt_current_region_label 		= GetWidget('main_login_prompt_current_region_label')
	local main_login_regionselection_parent_button_1 	= GetWidget('main_login_regionselection_parent_button_1')
	local main_login_regionselection_parent_button_2 	= GetWidget('main_login_regionselection_parent_button_2')
	local main_login_regionselection_closex 			= GetWidget('main_login_regionselection_closex')
	local main_login_lastRegion							= nil

	local function UpdateRegionCombobox(trigger, countryCode)
		local stringKey 
		if (countryCode) then
			stringKey = FindCountryStringKeyFromISOCode(countryCode)
		end
		main_login_regionselection_combobox:Clear() 
		local selected = false
		for i, v in ipairs(Login.regionsTable) do
			main_login_regionselection_combobox:AddTemplateListItem('simpleDropdownItem', i, 'label', v[1])
			if (mainUI.savedAnonymously) and (mainUI.savedAnonymously.RegionInfo) and (mainUI.savedAnonymously.RegionInfo.lastUsedCountry2) then 
				if (mainUI.savedAnonymously.RegionInfo.lastUsedCountry2 == v[1]) then
					main_login_regionselection_combobox:SetSelectedItemByValue(i, true)
					selected = true
				end
			else
				if (stringKey) and (stringKey == v[1]) then
					main_login_regionselection_combobox:SetSelectedItemByValue(i, true)
					selected = true		
				end
			end
		end
		if (not selected) then
			main_login_regionselection_combobox:SetSelectedItemByIndex(0, false)
		end
		return selected
	end		
	
	main_login_regionselection_parent_button_1:SetCallback('onclick', function(widget)
		main_login_regionselection_parent:FadeOut(250)
		main_login_lastRegion = nil
	end)	
	
	main_login_regionselection_parent_button_2:SetCallback('onclick', function(widget)
		main_login_regionselection_parent:FadeOut(250)
		if (main_login_lastRegion) then
			main_login_regionselection_combobox:SetSelectedItemByValue(main_login_lastRegion, true)
			main_login_lastRegion = nil
		end
	end)	
	
	main_login_regionselection_closex:SetCallback('onclick', function(widget)
		main_login_regionselection_parent:FadeOut(250)
		if (main_login_lastRegion) then
			main_login_regionselection_combobox:SetSelectedItemByValue(main_login_lastRegion, true)
			main_login_lastRegion = nil
		end
	end)	
	
	main_login_prompt_current_region:SetCallback('onclick', function(widget)
		main_login_lastRegion = tonumber(main_login_regionselection_combobox:GetValue())
		main_login_regionselection_parent:FadeIn(250)
	end)

	main_login_regionselection_combobox:SetCallback('onselect', function(widget)
		local index = tonumber(widget:GetValue())
		local countryString = Login.regionsTable[index][1] or '?Country'
		local visibleCountryString = TranslateOrNil('create_acc_country_'..countryString) or TranslateOrNil(countryString) or countryString
		
		mainUI.savedAnonymously									= mainUI.savedAnonymously or {}
		mainUI.savedAnonymously.RegionInfo 						= mainUI.savedAnonymously.RegionInfo or {}
		mainUI.savedAnonymously.RegionInfo.lastUsedCountry2 		= countryString
		SaveState()
		
		main_login_prompt_current_region_label:SetText(Translate('main_login_country') .. ' ' ..visibleCountryString)
		
		SetUIRegionFromGEOIP(Login.regionsTable[index][4])
		
		if (GetWidget('main_login_prompt_current_region_label'):GetWidth() + GetWidget('main_login_prompt_current_region_change'):GetWidth()) >= GetWidget('main_login_prompt_current_region'):GetWidth() then
			GetWidget('main_login_prompt_username_remember'):SetX((-288 - (((GetWidget('main_login_prompt_current_region_label'):GetWidth() + GetWidget('main_login_prompt_current_region_change'):GetWidth())-GetWidget('main_login_prompt_current_region'):GetWidth())))..'s')
		else
			GetWidget('main_login_prompt_username_remember'):SetX('-268s')
		end
		
		main_login_prompt_current_region:SetVisible(1)
	end)
	
	--== Region Selection Login
	if (not ((Strife_Region) and (Strife_Region.activeRegion) and (Strife_Region.regionTable) and (Strife_Region.regionTable[Strife_Region.activeRegion]) and (Strife_Region.regionTable[Strife_Region.activeRegion].isLockedToThisRegion))) then
		if (mainUI.savedAnonymously) and (mainUI.savedAnonymously.RegionInfo) and (mainUI.savedAnonymously.RegionInfo.lastUsedCountry2) then 		-- We had region saved locally already
			println('Loading Saved Region: ' .. tostring(mainUI.savedAnonymously.RegionInfo.lastUsedCountry2))
			main_login_prompt_current_region:SetVisible(1)
			UpdateRegionCombobox(nil, nil)
		else
			if UpdateRegionCombobox(nil, GetCvarString('build_branch')) then 			-- We matched a dev or RC region
				println('Region Matches Dev or RC: ' .. tostring(GetCvarString('build_branch')))
				main_login_prompt_current_region:SetVisible(1)
			else 			-- We must be on a prod region without a saved region, go find which one
				local successFunction = function (request)	-- response handler
					local responseData = request:GetBody()
					if responseData == nil or responseData.country == nil then
						println('Requesting Region from S2OGI: Failed')
						main_login_prompt_current_region:SetVisible(1)
					else
						println('Requesting Region from S2OGI: Success')
						main_login_prompt_current_region:SetVisible(1)
						UpdateRegionCombobox(nil, responseData.country)
					end
				end	
				local failFunction = function (request)	-- error handler
					SevereError('RequestMyDefaultUIRegion Request Error: ' .. Translate(request:GetError() or ''), 'general_ok', '', nil, nil, false)
					println('Requesting Region from S2OGI: Failed')
					main_login_prompt_current_region:SetVisible(1)				
				end			
				Strife_Web_Requests:RequestMyDefaultUIRegion(successFunction, failFunction)
			end
		end
	end
	
	-- === SOCIAL MEDIA === --
	
	function Login.UpdateSelectedLoginMethod(newLoginMethod)
		Login.selectedLoginMethod = newLoginMethod or Login.selectedLoginMethod
	
		mainUI.savedAnonymously										= mainUI.savedAnonymously or {}
		mainUI.savedAnonymously.RegionInfo 							= mainUI.savedAnonymously.RegionInfo or {}
		mainUI.savedAnonymously.RegionInfo.lastUsedLoginMethod 		= newLoginMethod
		SaveState()		
		
		groupfcall('main_login_socialmedia_tabs', function(_, groupWidget) groupWidget:SetVisible(0) end)
		
		for index, loginMethodTable in pairs(Strife_Region.regionTable[Strife_Region.activeRegion].allowedLoginMethods) do
			local methodName = loginMethodTable[1]
			if GetWidget('main_login_socialmedia_tab_' .. methodName, nil, true) then
				GetWidget('main_login_socialmedia_tab_' .. methodName):SetVisible(1)		
				GetWidget('main_login_socialmedia_tab_' .. methodName):SetCallback('onmouseover', function(widget)
					GetWidget('main_login_socialmedia_title_label'):SetText(Translate('main_login_change_' .. methodName))
				end)
				GetWidget('main_login_socialmedia_tab_' .. methodName):SetCallback('onmouseout', function(widget)
					GetWidget('main_login_socialmedia_title_label'):SetText('') -- Translate('main_login_change_type')
				end)
				GetWidget('main_login_socialmedia_tab_' .. methodName):SetCallback('onclick', function(widget)
					Login.UpdateSelectedLoginMethod(methodName, loginMethodTable)
				end)		
			end
		end
	
		if GetWidget('main_login_socialmedia_tab_' .. Login.selectedLoginMethod, nil, true) then
			GetWidget('main_login_socialmedia_tab_' .. Login.selectedLoginMethod):SetVisible(0)						
		end		
		
		GetWidget('main_login_prompt_username_label'):SetText(Translate('main_login_user_' .. Login.selectedLoginMethod))
		
	end

	GetWidget('main_login_socialmedia_parent'):RegisterWatchLua('mainPanelStatus', function(widget, trigger)
		if (not trigger.isLoggedIn) then
			if (Strife_Region.regionTable) and (Strife_Region.regionTable[Strife_Region.activeRegion]) and (Strife_Region.regionTable[Strife_Region.activeRegion].allowedLoginMethods) then
				GetWidget('main_login_socialmedia_parent'):SetVisible(#Strife_Region.regionTable[Strife_Region.activeRegion].allowedLoginMethods > 1)
				if mainUI.savedAnonymously and mainUI.savedAnonymously.RegionInfo and mainUI.savedAnonymously.RegionInfo.lastUsedLoginMethod then 
					Login.selectedLoginMethod = mainUI.savedAnonymously.RegionInfo.lastUsedLoginMethod
					local methodTable = Login.GetSelectedLoginMethodTable()
					if (methodTable) then
						Login.UpdateSelectedLoginMethod(mainUI.savedAnonymously.RegionInfo.lastUsedLoginMethod)
					else
						Login.UpdateSelectedLoginMethod(Strife_Region.regionTable[Strife_Region.activeRegion].allowedLoginMethods[1][1])
					end
				else
					Login.UpdateSelectedLoginMethod(Strife_Region.regionTable[Strife_Region.activeRegion].allowedLoginMethods[1][1])
				end
			else
				GetWidget('main_login_socialmedia_parent'):SetVisible(0)
			end	
		else
			CheckRemember()
		end
	end, false, nil, 'isLoggedIn')	
	
	-- ========= --
	
	LoginExtraInfoTrigger = LoginExtraInfoTrigger or LuaTrigger.CreateCustomTrigger(
		'LoginExtraInfoTrigger',
		{
			{ name	= 'linkingSteamAccount',	type	= 'boolean' },
			{ name	= 'linkedSteamAccount',	type	= 'boolean' }
		}
	)	
	LoginExtraInfoTrigger.linkingSteamAccount = false
	LoginExtraInfoTrigger.linkedSteamAccount = false
	
	if LuaTrigger.GetTrigger('SteamLoginNeedToCreateAccount') then
	
		libGeneral.createGroupTrigger('loginVis', {
			'newPlayerExperience.tutorialProgress',
			'newPlayerExperience.tutorialComplete',
			'newPlayerExperience.npeStarted',
			'newPlayerExperience.showLogin',
			'GamePhase.gamePhase',
			'mainPanelStatus.main',
			'LoginStatus.isLoggedIn',
			'LoginStatus.externalLogin',
			'LoginStatus.launchedViaSteam',
			'LoginStatus.loggedInViaSteam',
			'LoginExtraInfoTrigger.linkingSteamAccount',
			'SteamLoginNeedToCreateAccount'
		})

		container:RegisterWatchLua('loginVis', function(widget, groupTrigger)
			local triggerNewPlayerExperience			= groupTrigger['newPlayerExperience']
			local triggerGamePhase						= groupTrigger['GamePhase']
			local triggerMainPanelStatus				= groupTrigger['mainPanelStatus']
			local LoginStatus							= groupTrigger['LoginStatus']
			local LoginExtraInfoTrigger					= groupTrigger['LoginExtraInfoTrigger']
			local SteamLoginNeedToCreateAccount			= groupTrigger['SteamLoginNeedToCreateAccount']
			
			local showing = false
			if (LoginStatus.launchedViaSteam) then
				if (SteamLoginNeedToCreateAccount.needToCreateAccount) and (not LoginStatus.loggedInViaSteam) and (not LoginExtraInfoTrigger.linkingSteamAccount) and (not LoginExtraInfoTrigger.linkedSteamAccount) then
                    -- Prompt to create account or link existing.
                    -- Disabled, since only creating account with Steam avaliable, creating account right away instead
                    --mainUI.ShowSplashScreen('splash_screen_steam_link')
                    Login.AttemptCreateSteamAccount()
					showing = false
					libGeneral.fade(widget, false, 250)	
				elseif (LoginExtraInfoTrigger.linkingSteamAccount) and (not LoginExtraInfoTrigger.linkedSteamAccount) then
					showing = ( triggerMainPanelStatus.main == 0 and triggerGamePhase.gamePhase == 0 and (not LoginStatus.isLoggedIn) and (((LoginStatus.launchedViaSteam) and (LoginExtraInfoTrigger.linkingSteamAccount)) or (not LoginStatus.externalLogin) or ((LoginStatus.launchedViaSteam) and (not LoginStatus.loggedInViaSteam))))
					libGeneral.fade(widget, showing, 250)
					mainUI.ShowSplashScreen()
				else
					libGeneral.fade(widget, false, 250)
					mainUI.ShowSplashScreen()
				end
			elseif (Strife_Region.regionTable) and (Strife_Region.regionTable[Strife_Region.activeRegion]) and (Strife_Region.regionTable[Strife_Region.activeRegion].crippled) then
				showing = ( triggerMainPanelStatus.main == 0 and triggerGamePhase.gamePhase == 0 and (not LoginStatus.isLoggedIn) and (((LoginStatus.launchedViaSteam) and (LoginExtraInfoTrigger.linkingSteamAccount)) or (not LoginStatus.externalLogin) or ((LoginStatus.launchedViaSteam) and (not LoginStatus.loggedInViaSteam))))
				libGeneral.fade(widget, showing, 250)		
			else
				showing = ( (not NewPlayerExperience.isNPEDemo2()) and triggerMainPanelStatus.main == 0 and triggerGamePhase.gamePhase == 0 and (triggerNewPlayerExperience.tutorialComplete or triggerNewPlayerExperience.tutorialProgress >= NPE_PROGRESS_ACCOUNTCREATED or triggerNewPlayerExperience.showLogin or NewPlayerExperience.requiresLogin) and (not LoginStatus.isLoggedIn) and (((LoginStatus.launchedViaSteam) and (LoginExtraInfoTrigger.linkingSteamAccount)) or (not LoginStatus.externalLogin) or (LoginStatus.launchedViaSteam and (not LoginStatus.loggedInViaSteam))) )
				libGeneral.fade(widget, showing, 250)
			end
			if showing then
				setMainTriggers({
					mainBackground = {wheelX='-250s', logoSlide=false, navBackingVisible=false, logoX='750s', logoY='30s', logoWidth='500s', logoHeight='250s'},
					mainNavigation = {visible=false }
				})
			end
			if (LoginStatus.launchedViaSteam) and (LoginExtraInfoTrigger.linkingSteamAccount) and (LoginStatus.isLoggedIn) and (not LoginStatus.loggedInViaSteam) then
				Login.AttemptSteamLink()
				LoginExtraInfoTrigger.linkingSteamAccount = false
				LoginExtraInfoTrigger.linkedSteamAccount = true
			end		
		end, false)
	
	else
		libGeneral.createGroupTrigger('loginVis', {
			'newPlayerExperience.tutorialProgress',
			'newPlayerExperience.tutorialComplete',
			'newPlayerExperience.npeStarted',
			'newPlayerExperience.showLogin',
			'GamePhase.gamePhase',
			'mainPanelStatus.main',
			'LoginStatus.isLoggedIn',
			'LoginStatus.externalLogin',
			'LoginStatus.launchedViaSteam',
			'LoginStatus.loggedInViaSteam',
			'LoginExtraInfoTrigger.linkingSteamAccount'
		})

		container:RegisterWatchLua('loginVis', function(widget, groupTrigger)
			local triggerNewPlayerExperience			= groupTrigger['newPlayerExperience']
			local triggerGamePhase						= groupTrigger['GamePhase']
			local triggerMainPanelStatus				= groupTrigger['mainPanelStatus']
			local LoginStatus							= groupTrigger['LoginStatus']
			local LoginExtraInfoTrigger					= groupTrigger['LoginExtraInfoTrigger']
			
			local showing
			if (Strife_Region.regionTable) and (Strife_Region.regionTable[Strife_Region.activeRegion]) and (Strife_Region.regionTable[Strife_Region.activeRegion].crippled) then
				showing = ( triggerMainPanelStatus.main == 0 and triggerGamePhase.gamePhase == 0 and (not LoginStatus.isLoggedIn) and (((LoginStatus.launchedViaSteam) and (LoginExtraInfoTrigger.linkingSteamAccount)) or (not LoginStatus.externalLogin) or ((LoginStatus.launchedViaSteam) and (not LoginStatus.loggedInViaSteam))))
				libGeneral.fade(widget, showing, 250)		
			else
				showing = ( (not NewPlayerExperience.isNPEDemo2()) and triggerMainPanelStatus.main == 0 and triggerGamePhase.gamePhase == 0 and (triggerNewPlayerExperience.tutorialComplete or triggerNewPlayerExperience.tutorialProgress >= NPE_PROGRESS_ACCOUNTCREATED or triggerNewPlayerExperience.showLogin or NewPlayerExperience.requiresLogin) and (not LoginStatus.isLoggedIn) and (((LoginStatus.launchedViaSteam) and (LoginExtraInfoTrigger.linkingSteamAccount)) or (not LoginStatus.externalLogin) or (LoginStatus.launchedViaSteam and (not LoginStatus.loggedInViaSteam))) )
				libGeneral.fade(widget, showing, 250)
			end
			if showing then
				setMainTriggers({
					mainBackground = {wheelX='-250s', logoSlide=false, navBackingVisible=false, logoX='750s', logoY='30s', logoWidth='500s', logoHeight='250s'},
					mainNavigation = {visible=false }
				})
			end	
		end, false)
	end
	
	GetWidget('main_login_prompt_eula'):RegisterWatchLua('mainPanelStatus', function(widget, trigger)			
		if (trigger.main == 103) then
			widget:FadeIn(500)
		else 
			widget:FadeOut(500)
		end
	end, false, 'main')
	
	GetWidget('main_login_prompt_eula_ok'):SetCallback('onclick', function()
		mainUI.savedRemotely.tosSigned = CURRENT_TOS_VERSION
		SaveState()
		local mainPanelStatus = LuaTrigger.GetTrigger('mainPanelStatus')					
		mainPanelStatus.main			= 0
		mainPanelStatus:Trigger(true)	
	end)
	
	GetWidget('main_login_prompt_eula_cancel'):SetCallback('onclick', function()
		PromptQuit()		
	end)	
	
end

loginRegister(object)
