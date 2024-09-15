----------------------------------------------------------
--	Name: 		Region Interface Script            		--
--  Copyright 2013 S2 Games								--
----------------------------------------------------------

local _G = getfenv(0)
Strife_Region = _G['Strife_Region'] or {}
local ipairs, pairs, select, string, table, next, type, unpack, tinsert, tconcat, tremove, format, tostring, tonumber, tsort, ceil, floor, sub, find, gfind = _G.ipairs, _G.pairs, _G.select, _G.string, _G.table, _G.next, _G.type, _G.unpack, _G.table.insert, _G.table.concat, _G.table.remove, _G.string.format, _G.tostring, _G.tonumber, _G.table.sort, _G.math.ceil, _G.math.floor, _G.string.sub, _G.string.find, _G.string.gfind
local interface, interfaceName = object, object:GetName()
Strife_Region.regionOverride = GetCvarString('ui_overrideRegion', true)
Strife_Region.activeRegion = nil

-- build_region global, build_os windows, build_arch, build_type
Strife_Region.regionTable = {
		-- dev region
		['s2_development'] = {
			['regionCondition'] = ((GetCvarString('build_branch') == 'dev') and (GetCvarString('host_provider') == 's2')) ,
			['langCodes'] = {
				{code = 'en', flag = '/ui/shared/textures/flags/unitedstates.tga', 	displayName = 'en'},
				{code = 'zh', flag = '/ui/shared/textures/flags/china.tga',			displayName = 'zh'},
				{code = 'th', flag = '/ui/shared/textures/flags/thailand.tga', 		displayName = 'th'},
				{code = 'ru', flag = '/ui/shared/textures/flags/russia.tga', 		displayName = 'ru'},
				{code = 'vi', flag = '/ui/shared/textures/flags/vietnam.tga', 		displayName = 'vi'},
				{code = 'pt_br', flag = '/ui/shared/textures/flags/brazil.tga', 	displayName = 'pt_br'},
				{code = 'fr', flag = '/ui/shared/textures/flags/france.tga', 		displayName = 'fr'},
				{code = 'de', flag = '/ui/shared/textures/flags/germany.tga', 		displayName = 'de'},
				{code = 'es', flag = '/ui/shared/textures/flags/spain.tga', 		displayName = 'es'},
				{code = 'id', flag = '/ui/shared/textures/flags/indonesia.tga', 	displayName = 'id'},
			},
			['isProduction'] = false,
			['isLockedToThisRegion'] = false,
			['allowDevHeroes'] = true,
			['dialogOnSevereError'] = true,
			['alertOnSevereError'] = false,
			['dialogOnMinorError'] = true,
			['dialogOnWebError'] = true,
			['obnoxiousErrorReporting'] = true,
			['useWIPFeatures'] = true,
			['allowIdentSelection'] = true,
			['allowIdentCreation'] = true,
			['allowDisplayNameChange'] = true,
			['allowUniqueIDChange'] = true,
			['showLangChoice'] = true,
			['useAntiAbuse'] = true,
			['allowedLoginMethods'] = {
				-- name			login function		setup function
				{'igames', 		'AttemptS2Login', 	'SetUpS2Login'},
				{'facebook', 	'AttemptS2Login', 	'SetUpS2Login'},
				{'twitter', 	'AttemptS2Login', 	'SetUpS2Login'},
				{'google', 		'AttemptS2Login', 	'SetUpS2Login'},
				--{'steam', 		'AttemptSteamLogin', 	'SetUpSteamLogin'},
			},
			['hideDevWidgets'] = false,
			['enableWebRequests'] = true,
			['enableDevServerTypes'] = true,
			['enableDevMaps'] = true,
			['allowRealPurchases'] = true,
			['buyGemsURL'] = 'https://main.www.s2games.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/payment',
			['strifeWebsiteURL'] = 'https://main.www.strife.com/',
			['strifeSupportURL'] = 'http://support.s2games.com',
			['createAccountURL'] = 'http://www.strife.com/create',
			['purchaseBoostURL'] = 'https://main.www.strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/purchase',
			['forgotPasswordURL'] = 'https://main.www.strife.com/login/',
			['enabledDevAnimations'] = false,
			['new_player_experience'] = true,
			['NPEIsOptional'] = true,
			['NPEIsABOptional'] = true,
			['preview_splash'] = false,
			['enableCloudStorage'] = true,
			['NPEDemo'] = false,
			['NPEDemo2'] = false,
			['EnablecommunityGuides'] = false,
			['UseDoorRewardScreen'] = true,
			['useProgressionVersion83'] = true,
			['disabledFeatures'] = { 'standardrating', 'strifeapp', 'ranked', 'khanquest', 'referafriend' },
			['cvars'] = {
				{'ui_regionalPartner', 'string', 'S2 Games'},
				{'http_printDebugInfo', 'int', '2', true},
				{'php_printDebugInfo', 'bool', 'true', true},
				{'cl_checkForUpdate', 'bool', 'false'},
				{'sv_autoKickAFKPractice', 'bool', 'false'},
				{'sv_autoKickAFKPlayers', 'bool', 'false'},
				{'sv_considerAfkInactive', 'bool', 'false'},
				{'sv_afkAutoKickTime', 'int', '9999999'},
				{'sv_afkTerminationPenalty', 'int', '9999999'},
				{'sv_afkTimeout', 'int', '9999999'},
				{'sv_afkWarningTime', 'int', '9999999'},
				{'g_afkBaseDistance', 'int', '0'},
				{'g_afkWanderRadius', 'int', '0'},
				{'ui_Overhaul', 'bool', 'true', true},
				{'ui_multiWindowChat', 'bool', 'true', true},
				{'shopShowFiltersDefault', 'bool', 'true', true},
			},
			['motd'] = "messages.strife.com/main.motd",
		},

		-- private test
		['s2_private_test'] = {
			['regionCondition'] = ((GetCvarString('build_branch') == 'pt') and (GetCvarString('host_provider') == 's2')) ,
			['langCodes'] = {
				{code = 'en', flag = '/ui/shared/textures/flags/unitedstates.tga', displayName = 'en'},
				{code = 'zh', flag = '/ui/shared/textures/flags/china.tga', displayName = 'zh'},
				{code = 'th', flag = '/ui/shared/textures/flags/thailand.tga', displayName = 'th'},
				{code = 'ru', flag = '/ui/shared/textures/flags/russia.tga', displayName = 'ru'},
				{code = 'vi', flag = '/ui/shared/textures/flags/vietnam.tga', displayName = 'vi'},
				{code = 'pt_br', flag = '/ui/shared/textures/flags/brazil.tga', 	displayName = 'pt_br'},
				{code = 'fr', flag = '/ui/shared/textures/flags/france.tga', 		displayName = 'fr'},
				{code = 'de', flag = '/ui/shared/textures/flags/germany.tga', 		displayName = 'de'},
				{code = 'es', flag = '/ui/shared/textures/flags/spain.tga', 		displayName = 'es'},
				{code = 'id', flag = '/ui/shared/textures/flags/indonesia.tga', 	displayName = 'id'},
			},
			['isProduction'] = false,
			['allowDevHeroes'] = true,
			['dialogOnSevereError'] = true,
			['alertOnSevereError'] = false,
			['dialogOnMinorError'] = true,
			['dialogOnWebError'] = true,
			['obnoxiousErrorReporting'] = false,
			['useWIPFeatures'] = false,
			['allowIdentSelection'] = false,
			['allowIdentCreation'] = false,
			['allowDisplayNameChange'] = false,
			['allowUniqueIDChange'] = false,
			['showLangChoice'] = true,
			['useAntiAbuse'] = true,
			['allowedLoginMethods'] = {
				-- name			login function		setup function
				{'igames', 		'AttemptS2Login', 	'SetUpS2Login'},
				-- {'facebook', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'twitter', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'google', 		'AttemptS2Login', 	'SetUpS2Login'},
			},
			['hideDevWidgets'] = false,
			['enableWebRequests'] = true,
			['enableDevServerTypes'] = true,
			['enableDevMaps'] = true,
			['allowRealPurchases'] = true,
			['buyGemsURL'] = 'https://pt.www.strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/payment',
			['strifeWebsiteURL'] = 'https://pt.www.strife.com',
			['strifeSupportURL'] = 'http://support.s2games.com',
			['createAccountURL'] = 'http://www.strife.com/create',
			['purchaseBoostURL'] = 'https://pt.www.strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/purchase',
			['forgotPasswordURL'] = 'https://pt.www.strife.com/login/',
			['enabledDevAnimations'] = false,
			['new_player_experience'] = true,
			['NPEIsOptional'] = true,
			['NPEIsABOptional'] = true,
			['preview_splash'] = false,
			['enableCloudStorage'] = true,
			['NPEDemo'] = false,
			['NPEDemo2'] = false,
			['EnablecommunityGuides'] = false,
			['UseDoorRewardScreen'] = false,
			['disabledFeatures'] = { 'standardrating', 'strifeapp', 'ranked', 'khanquest', 'referafriend'},
			['cvars'] = {
				{'ui_regionalPartner', 'string', 'S2 Games'},
				{'http_printDebugInfo', 'int', '2', true},
				{'php_printDebugInfo', 'bool', 'true', true},
				{'ui_Overhaul', 'bool', 'true', true},
				{'ui_multiWindowChat', 'bool', 'true', true},
				{'shopShowFiltersDefault', 'bool', 'true', true},
			},
			['motd'] = "messages.strife.com/pt.motd",
		},

		-- staging region
		['s2_staging'] = {
			['regionCondition'] = ((GetCvarString('build_branch') == 'staging') and (GetCvarString('host_provider') == 's2')) ,
			['langCodes'] = {
				{code = 'en', flag = '/ui/shared/textures/flags/unitedstates.tga', displayName = 'en'},
				{code = 'zh', flag = '/ui/shared/textures/flags/china.tga', displayName = 'zh'},
				{code = 'th', flag = '/ui/shared/textures/flags/thailand.tga', displayName = 'th'},
				{code = 'ru', flag = '/ui/shared/textures/flags/russia.tga', displayName = 'ru'},
				{code = 'vi', flag = '/ui/shared/textures/flags/vietnam.tga', displayName = 'vi'},
				{code = 'pt_br', flag = '/ui/shared/textures/flags/brazil.tga', 	displayName = 'pt_br'},
				{code = 'fr', flag = '/ui/shared/textures/flags/france.tga', 		displayName = 'fr'},
				 {code = 'de', flag = '/ui/shared/textures/flags/germany.tga', 		displayName = 'de'},
				{code = 'es', flag = '/ui/shared/textures/flags/spain.tga', 		displayName = 'es'},
			},
			['isProduction'] = false,
			['allowDevHeroes'] = false,
			['dialogOnSevereError'] = false,
			['alertOnSevereError'] = false,
			['dialogOnMinorError'] = false,
			['dialogOnWebError'] = true,
			['obnoxiousErrorReporting'] = false,
			['useWIPFeatures'] = false,
			['allowIdentSelection'] = false,
			['allowIdentCreation'] = false,
			['allowDisplayNameChange'] = false,
			['allowUniqueIDChange'] = false,
			['showLangChoice'] = true,
			['useAntiAbuse'] = true,
			['allowedLoginMethods'] = {
				-- name			login function		setup function
				{'igames', 		'AttemptS2Login', 	'SetUpS2Login'},
				-- {'facebook', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'twitter', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'google', 		'AttemptS2Login', 	'SetUpS2Login'},
			},
			['hideDevWidgets'] = true,
			['enableWebRequests'] = true,
			['enableDevServerTypes'] = false,
			['enableDevMaps'] = false,
			['allowRealPurchases'] = true,
			['buyGemsURL'] = 'https://staging.www.strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/payment',
			['strifeWebsiteURL'] = 'https://staging.www.strife.com',
			['strifeSupportURL'] = 'http://support.s2games.com',
			['createAccountURL'] = 'http://www.strife.com/create',
			['purchaseBoostURL'] = 'https://staging.www.strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/purchase',
			['forgotPasswordURL'] = 'https://staging.www.strife.com/login/',
			['enabledDevAnimations'] = false,
			['new_player_experience'] = true,
			['NPEIsOptional'] = true,
			['NPEIsABOptional'] = true,
			['preview_splash'] = false,
			['enableCloudStorage'] = true,
			['NPEDemo'] = false,
			['NPEDemo2'] = false,
			['EnablecommunityGuides'] = false,
			['UseDoorRewardScreen'] = false,
			['disabledFeatures'] = { 'standardrating', 'strifeapp', 'khanquest', 'ranked', 'referafriend', 'counterstrife'},
			['cvars'] = {
				{'ui_regionalPartner', 'string', 'S2 Games'},
				-- {'http_printDebugInfo', 'int', '0', true},
				-- {'php_printDebugInfo', 'bool', 'false', true},
				{'ui_Overhaul', 'bool', 'true', true},
				{'ui_multiWindowChat', 'bool', 'true', true},
				{'shopShowFiltersDefault', 'bool', 'true', true},
			},
			['motd'] = "messages.strife.com/rc.motd",
		},

		-- release candidate
		['s2_rc'] = {
			['regionCondition'] = ((GetCvarString('build_branch') == 'rc') and (GetCvarString('host_provider') == 's2')) ,
			['langCodes'] = {
				{code = 'en', flag = '/ui/shared/textures/flags/unitedstates.tga', displayName = 'en'},
				{code = 'zh', flag = '/ui/shared/textures/flags/china.tga', displayName = 'zh'},
				{code = 'th', flag = '/ui/shared/textures/flags/thailand.tga', displayName = 'th'},
				{code = 'ru', flag = '/ui/shared/textures/flags/russia.tga', displayName = 'ru'},
				{code = 'vi', flag = '/ui/shared/textures/flags/vietnam.tga', displayName = 'vi'},
				{code = 'pt_br', flag = '/ui/shared/textures/flags/brazil.tga', 	displayName = 'pt_br'},
				{code = 'fr', flag = '/ui/shared/textures/flags/france.tga', 		displayName = 'fr'},
				 {code = 'de', flag = '/ui/shared/textures/flags/germany.tga', 		displayName = 'de'},
				{code = 'es', flag = '/ui/shared/textures/flags/spain.tga', 		displayName = 'es'},
			},
			['isProduction'] = true,
			['allowDevHeroes'] = false,
			['dialogOnSevereError'] = false,
			['alertOnSevereError'] = false,
			['dialogOnMinorError'] = false,
			['dialogOnWebError'] = true,
			['obnoxiousErrorReporting'] = false,
			['useWIPFeatures'] = false,
			['allowIdentSelection'] = false,
			['allowIdentCreation'] = false,
			['allowDisplayNameChange'] = false,
			['allowUniqueIDChange'] = false,
			['showLangChoice'] = true,
			['useAntiAbuse'] = true,
			['allowedLoginMethods'] = {
				-- name			login function		setup function
				{'igames', 		'AttemptS2Login', 	'SetUpS2Login'},
				-- {'facebook', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'twitter', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'google', 		'AttemptS2Login', 	'SetUpS2Login'},
			},
			['hideDevWidgets'] = true,
			['enableWebRequests'] = true,
			['enableDevServerTypes'] = false,
			['enableDevMaps'] = false,
			['allowRealPurchases'] = true,
			['buyGemsURL'] = 'https://rc.www.strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/payment',
			['strifeWebsiteURL'] = 'https://rc.www.strife.com',
			['strifeSupportURL'] = 'http://support.s2games.com',
			['createAccountURL'] = 'http://www.strife.com/create',
			['purchaseBoostURL'] = 'https://rc.www.strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/purchase',
			['forgotPasswordURL'] = 'https://rc.www.strife.com/login/',
			['enabledDevAnimations'] = false,
			['new_player_experience'] = true,
			['NPEIsOptional'] = true,
			['NPEIsABOptional'] = true,
			['preview_splash'] = false,
			['enableCloudStorage'] = true,
			['NPEDemo'] = false,
			['NPEDemo2'] = false,
			['EnablecommunityGuides'] = false,
			['UseDoorRewardScreen'] = false,
			['disabledFeatures'] = { 'standardrating', 'strifeapp',  'khanquest', 'ranked', 'referafriend', 'counterstrife' },
			['cvars'] = {
				{'ui_regionalPartner', 'string', 'S2 Games'},
				-- {'http_printDebugInfo', 'int', '0', true},
				-- {'php_printDebugInfo', 'bool', 'false', true},
				{'ui_Overhaul', 'bool', 'true', true},
				{'ui_multiWindowChat', 'bool', 'true', true},
				{'shopShowFiltersDefault', 'bool', 'false', true},
			},
			['motd'] = "messages.strife.com/rc.motd",
		},

		-- prod crippled, just for updating
		['s2_prod_crippled'] = {
			['regionCondition'] = ((GetCvarString('build_branch') == 'prod_crippled') and (GetCvarString('host_provider') == 's2')) ,
			['langCodes'] = {
				{code = 'en', flag = '/ui/shared/textures/flags/unitedstates.tga', displayName = 'en'},
				-- {code = 'zh', flag = '/ui/shared/textures/flags/china.tga', displayName = 'zh'},
				{code = 'th', flag = '/ui/shared/textures/flags/thailand.tga', displayName = 'th'},
				{code = 'ru', flag = '/ui/shared/textures/flags/russia.tga', displayName = 'ru'},
				{code = 'vi', flag = '/ui/shared/textures/flags/vietnam.tga', displayName = 'vi'},
				{code = 'pt_br', flag = '/ui/shared/textures/flags/brazil.tga', 	displayName = 'pt_br'},
				{code = 'fr', flag = '/ui/shared/textures/flags/france.tga', 		displayName = 'fr'},
				 {code = 'de', flag = '/ui/shared/textures/flags/germany.tga', 		displayName = 'de'},
				{code = 'es', flag = '/ui/shared/textures/flags/spain.tga', 		displayName = 'es'},
			},
			['isProduction'] = true,
			['allowDevHeroes'] = false,
			['dialogOnSevereError'] = false,
			['alertOnSevereError'] = false,
			['dialogOnMinorError'] = false,
			['dialogOnWebError'] = true,
			['obnoxiousErrorReporting'] = false,
			['useWIPFeatures'] = false,
			['allowIdentSelection'] = false,
			['allowIdentCreation'] = false,
			['allowDisplayNameChange'] = false,
			['allowUniqueIDChange'] = false,
			['showLangChoice'] = true,
			['useAntiAbuse'] = true,
			['allowedLoginMethods'] = {
				-- name			login function		setup function
				{'igames', 		'AttemptS2Login', 	'SetUpS2Login'},
				-- {'facebook', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'twitter', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'google', 		'AttemptS2Login', 	'SetUpS2Login'},
			},
			['hideDevWidgets'] = true,
			['enableWebRequests'] = true,
			['enableDevServerTypes'] = false,
			['enableDevMaps'] = false,
			['allowRealPurchases'] = false,
			['buyGemsURL'] = 'https://strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/payment',
			['strifeWebsiteURL'] = 'https://strife.com',
			['strifeSupportURL'] = 'http://support.strife.com',
			['createAccountURL'] = 'http://www.strife.com/create',
			['purchaseBoostURL'] = 'https://strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/purchase',
			['forgotPasswordURL'] = 'https://strife.com/login/',
			['enabledDevAnimations'] = false,
			['NPEDemo'] = false,
			['NPEDemo2'] = false,
			['EnablecommunityGuides'] = false,
			['UseDoorRewardScreen'] = false,
			['disabledFeatures'] = { 'standardrating', 'strifeapp', 'lobby', 'party', 'crafting', 'enchanting', 'pets', 'quests', 'replays', 'rewards', 'stats', 'options', 'spectate', 'khanquest', 'ranked', 'referafriend', 'counterstrife'},
			['new_player_experience'] = false,	-- ehhhhhhhhhhh it's already disabled by checking crippled.  rmm make it only this later on
			['NPEIsOptional'] = true,
			['NPEIsABOptional'] = true,
			['preview_splash'] = false,
			['enableCloudStorage'] = false,
			['crippled'] = true,
			['cvars'] = {
				{'ui_regionalPartner', 'string', 'S2 Games'},
				-- {'http_printDebugInfo', 'int', '0', true},
				-- {'php_printDebugInfo', 'bool', 'false', true},
				{'ui_Overhaul', 'bool', 'true', true},
				{'ui_multiWindowChat', 'bool', 'true', true},
				{'shopShowFiltersDefault', 'bool', 'true', true},
			},
			['motd'] = "messages.strife.com/prod.motd",
		},

		-- s2 production branch *current default*
		['s2_prod'] = {
			['regionCondition'] = ((GetCvarString('build_branch') == 'prod') and (GetCvarString('host_provider') == 's2')) ,
			['langCodes'] = {
				{code = 'en', flag = '/ui/shared/textures/flags/unitedstates.tga', displayName = 'en'},
				{code = 'zh', flag = '/ui/shared/textures/flags/china.tga', displayName = 'zh'},
				{code = 'th', flag = '/ui/shared/textures/flags/thailand.tga', displayName = 'th'},
				{code = 'ru', flag = '/ui/shared/textures/flags/russia.tga', displayName = 'ru'},
				{code = 'vi', flag = '/ui/shared/textures/flags/vietnam.tga', displayName = 'vi'},
				{code = 'pt_br', flag = '/ui/shared/textures/flags/brazil.tga', 	displayName = 'pt_br'},
				{code = 'fr', flag = '/ui/shared/textures/flags/france.tga', 		displayName = 'fr'},
				 {code = 'de', flag = '/ui/shared/textures/flags/germany.tga', 		displayName = 'de'},
				{code = 'es', flag = '/ui/shared/textures/flags/spain.tga', 		displayName = 'es'},
			},
			['isProduction'] = true,
			['allowDevHeroes'] = false,
			['dialogOnSevereError'] = false,
			['alertOnSevereError'] = false,
			['dialogOnMinorError'] = false,
			['dialogOnWebError'] = true,
			['obnoxiousErrorReporting'] = false,
			['useWIPFeatures'] = false,
			['allowIdentSelection'] = false,
			['allowIdentCreation'] = false,
			['allowDisplayNameChange'] = false,
			['allowUniqueIDChange'] = false,
			['showLangChoice'] = true,
			['useAntiAbuse'] = true,
			['allowedLoginMethods'] = {
				-- name			login function		setup function
				{'igames', 		'AttemptS2Login', 	'SetUpS2Login'},
				-- {'facebook', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'twitter', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'google', 		'AttemptS2Login', 	'SetUpS2Login'},
			},
			['hideDevWidgets'] = true,
			['enableWebRequests'] = true,
			['enableDevServerTypes'] = false,
			['enableDevMaps'] = false,
			['allowRealPurchases'] = true,
			['buyGemsURL'] = 'https://strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/payment',
			['strifeWebsiteURL'] = 'https://strife.com',
			['strifeSupportURL'] = 'http://support.strife.com',
			['createAccountURL'] = 'http://www.strife.com/create',
			['purchaseBoostURL'] = 'https://strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/purchase',
			['forgotPasswordURL'] = 'https://strife.com/login/',
			['enabledDevAnimations'] = false,
			['new_player_experience'] = true,
			['NPEIsOptional'] = true,
			['NPEIsABOptional'] = true,
			['preview_splash'] = false,
			['enableCloudStorage'] = true,
			['NPEDemo'] = false,
			['NPEDemo2'] = false,
			['EnablecommunityGuides'] = false,
			['UseDoorRewardScreen'] = false,
			['disabledFeatures'] = { 'standardrating', 'strifeapp',  'khanquest', 'ranked', 'referafriend', 'counterstrife' },
			['cvars'] = {
				{'ui_regionalPartner', 'string', 'S2 Games'},
				-- {'http_printDebugInfo', 'int', '0', true},
				-- {'php_printDebugInfo', 'bool', 'false', true},
				{'ui_Overhaul', 'bool', 'true', true},
				{'ui_multiWindowChat', 'bool', 'true', true},
				{'shopShowFiltersDefault', 'bool', 'false', true},
			},
			['motd'] = "messages.strife.com/prod.motd",
		},

		-- always tutorial1, based off prod
		['demo_tutorial1'] = {
			['regionCondition'] = ((GetCvarString('build_branch') == 'demo_tutorial1') and (GetCvarString('host_provider') == 's2')) ,
			['langCodes'] = {
				{code = 'en', flag = '/ui/shared/textures/flags/unitedstates.tga', displayName = 'en'},
				{code = 'zh', flag = '/ui/shared/textures/flags/china.tga', displayName = 'zh'},
				{code = 'th', flag = '/ui/shared/textures/flags/thailand.tga', displayName = 'th'},
				{code = 'ru', flag = '/ui/shared/textures/flags/russia.tga', displayName = 'ru'},
				-- {code = 'vi', flag = '/ui/shared/textures/flags/vietnam.tga', displayName = 'vi'},
				{code = 'pt_br', flag = '/ui/shared/textures/flags/brazil.tga', 	displayName = 'pt_br'},
				-- {code = 'fr', flag = '/ui/shared/textures/flags/france.tga', 		displayName = 'fr'},
				 {code = 'de', flag = '/ui/shared/textures/flags/germany.tga', 		displayName = 'de'},
				-- {code = 'es', flag = '/ui/shared/textures/flags/spain.tga', 		displayName = 'es'},
			},
			['isProduction'] = true,
			['allowDevHeroes'] = false,
			['dialogOnSevereError'] = false,
			['alertOnSevereError'] = false,
			['dialogOnMinorError'] = false,
			['dialogOnWebError'] = true,
			['obnoxiousErrorReporting'] = false,
			['useWIPFeatures'] = false,
			['allowIdentSelection'] = false,
			['allowIdentCreation'] = false,
			['allowDisplayNameChange'] = false,
			['allowUniqueIDChange'] = false,
			['showLangChoice'] = true,
			['useAntiAbuse'] = true,
			['allowedLoginMethods'] = {
				-- name			login function		setup function
				{'igames', 		'AttemptS2Login', 	'SetUpS2Login'},
				-- {'facebook', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'twitter', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'google', 		'AttemptS2Login', 	'SetUpS2Login'},
			},
			['hideDevWidgets'] = true,
			['enableWebRequests'] = true,
			['enableDevServerTypes'] = false,
			['enableDevMaps'] = false,
			['allowRealPurchases'] = true,
			['buyGemsURL'] = 'https://strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/payment',
			['strifeWebsiteURL'] = 'https://strife.com',
			['strifeSupportURL'] = 'http://support.s2games.com',
			['createAccountURL'] = 'http://www.strife.com/create',
			['purchaseBoostURL'] = 'https://strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/purchase',
			['forgotPasswordURL'] = 'https://strife.com/login/',
			['enabledDevAnimations'] = false,
			['new_player_experience'] = true,
			['NPEIsOptional'] = true,
			['NPEIsABOptional'] = true,
			['preview_splash'] = false,
			['enableCloudStorage'] = true,
			['NPEDemo'] = true,
			['NPEDemo2'] = false,
			['UseDoorRewardScreen'] = false,
			['disabledFeatures'] = { 'standardrating', 'strifeapp', 'quests', 'khanquest', 'ranked', 'referafriend', 'counterstrife'},
			['cvars'] = {
				{'ui_regionalPartner', 'string', 'S2 Games'},
				-- {'http_printDebugInfo', 'int', '0', true},
				-- {'php_printDebugInfo', 'bool', 'false', true},
				{'ui_Overhaul', 'bool', 'true', true},
				{'ui_multiWindowChat', 'bool', 'true', true},
				{'shopShowFiltersDefault', 'bool', 'true', true},
			},
			['motd'] = "messages.strife.com/prod.motd",
		},

		-- always tutorial3, based off prod
		['demo_tutorial3'] = {
			['regionCondition'] = ((GetCvarString('build_branch') == 'demo_tutorial3') and (GetCvarString('host_provider') == 's2')) ,
			['langCodes'] = {
				{code = 'en', flag = '/ui/shared/textures/flags/unitedstates.tga', displayName = 'en'},
				{code = 'zh', flag = '/ui/shared/textures/flags/china.tga', displayName = 'zh'},
				{code = 'th', flag = '/ui/shared/textures/flags/thailand.tga', displayName = 'th'},
				{code = 'ru', flag = '/ui/shared/textures/flags/russia.tga', displayName = 'ru'},
				-- {code = 'vi', flag = '/ui/shared/textures/flags/vietnam.tga', displayName = 'vi'},
				{code = 'pt_br', flag = '/ui/shared/textures/flags/brazil.tga', 	displayName = 'pt_br'},
				-- {code = 'fr', flag = '/ui/shared/textures/flags/france.tga', 		displayName = 'fr'},
				 {code = 'de', flag = '/ui/shared/textures/flags/germany.tga', 		displayName = 'de'},
				-- {code = 'es', flag = '/ui/shared/textures/flags/spain.tga', 		displayName = 'es'},
			},
			['isProduction'] = true,
			['allowDevHeroes'] = false,
			['dialogOnSevereError'] = false,
			['alertOnSevereError'] = false,
			['dialogOnMinorError'] = false,
			['dialogOnWebError'] = true,
			['obnoxiousErrorReporting'] = false,
			['useWIPFeatures'] = false,
			['allowIdentSelection'] = false,
			['allowIdentCreation'] = false,
			['allowDisplayNameChange'] = false,
			['allowUniqueIDChange'] = false,
			['showLangChoice'] = true,
			['useAntiAbuse'] = true,
			['allowSocialMediaAccounts'] = false,
			['hideDevWidgets'] = true,
			['enableWebRequests'] = true,
			['enableDevServerTypes'] = false,
			['enableDevMaps'] = false,
			['allowRealPurchases'] = true,
			['buyGemsURL'] = 'https://strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/payment',
			['strifeWebsiteURL'] = 'https://strife.com',
			['strifeSupportURL'] = 'http://support.s2games.com',
			['createAccountURL'] = 'http://www.strife.com/create',
			['purchaseBoostURL'] = 'https://strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/purchase',
			['forgotPasswordURL'] = 'https://strife.com/login/',
			['enabledDevAnimations'] = false,
			['new_player_experience'] = true,
			['NPEIsOptional'] = true,
			['NPEIsABOptional'] = true,
			['preview_splash'] = false,
			['enableCloudStorage'] = true,
			['NPEDemo'] = false,
			['NPEDemo2'] = true,
			['UseDoorRewardScreen'] = false,
			['disabledFeatures'] = { 'standardrating', 'strifeapp', 'quests', 'khanquest', 'ranked', 'referafriend', 'counterstrife'},
			['cvars'] = {
				{'ui_regionalPartner', 'string', 'S2 Games'},
				-- {'http_printDebugInfo', 'int', '0', true},
				-- {'php_printDebugInfo', 'bool', 'false', true},
				{'ui_Overhaul', 'bool', 'true', true},
				{'ui_multiWindowChat', 'bool', 'true', true},
				{'shopShowFiltersDefault', 'bool', 'true', true},
			},
			['motd'] = "messages.strife.com/prod.motd",
			['loginExecuteFunction'] = 'AttemptS2Login',
			['loginSetUpFunction'] = 'SetUpS2Login',
		},

		-- ======================================
		-- Asiasoft - SEA Regions
		-- ======================================

		-- SEA production branch
		['sea_rc'] = {
			['regionCondition'] = (false),	-- This region cannot be automatically activated, it uses location lookup instead
			['langCodes'] = {
				{code = 'en', flag = '/ui/shared/textures/flags/unitedstates.tga', displayName = 'en'},
				{code = 'zh', flag = '/ui/shared/textures/flags/china.tga', displayName = 'zh'},
				{code = 'th', flag = '/ui/shared/textures/flags/thailand.tga', displayName = 'th'},
				{code = 'ru', flag = '/ui/shared/textures/flags/russia.tga', displayName = 'ru'},
				-- {code = 'vi', flag = '/ui/shared/textures/flags/vietnam.tga', displayName = 'vi'},
				{code = 'pt_br', flag = '/ui/shared/textures/flags/brazil.tga', 	displayName = 'pt_br'},
				-- {code = 'fr', flag = '/ui/shared/textures/flags/france.tga', 		displayName = 'fr'},
				 {code = 'de', flag = '/ui/shared/textures/flags/germany.tga', 		displayName = 'de'},
				-- {code = 'es', flag = '/ui/shared/textures/flags/spain.tga', 		displayName = 'es'},
			},
			['isProduction'] = true,
			['allowDevHeroes'] = false,
			['dialogOnSevereError'] = false,
			['alertOnSevereError'] = false,
			['dialogOnMinorError'] = false,
			['dialogOnWebError'] = true,
			['obnoxiousErrorReporting'] = false,
			['useWIPFeatures'] = false,
			['allowIdentSelection'] = false,
			['allowIdentCreation'] = false,
			['allowDisplayNameChange'] = false,
			['allowUniqueIDChange'] = false,
			['showLangChoice'] = true,
			['useAntiAbuse'] = true,
			['allowedLoginMethods'] = {
				-- name			login function		setup function
				{'asiasoft', 				'AttemptAsiasoftLogin', 			'SetUpAsiasoftLogin'},
				-- {'asiasoft_facebook', 		'AttemptAsiasoftFacebookLogin', 	'SetUpAsiasoftLogin'},
				-- {'igames', 		'AttemptS2Login', 	'SetUpS2Login'},
				-- {'facebook', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'twitter', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'google', 		'AttemptS2Login', 	'SetUpS2Login'},
			},
			['hideDevWidgets'] = true,
			['enableWebRequests'] = true,
			['enableDevServerTypes'] = false,
			['enableDevMaps'] = false,
			['allowRealPurchases'] = true,
			['buyGemsURL'] = 'https://strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/payment',
			['strifeWebsiteURL'] = 'https://strife.com',
			['strifeSupportURL'] = 'http://support.strife.com',
			['createAccountURL'] = 'https://secure2.playpark.com/register/Register.aspx',
			['purchaseBoostURL'] = 'https://strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/purchase',
			['forgotPasswordURL'] = 'https://secure2.playpark.com/MemberPlaypark/resetpw.aspx',
			['enabledDevAnimations'] = false,
			['new_player_experience'] = true,
			['NPEIsOptional'] = true,
			['NPEIsABOptional'] = true,
			['preview_splash'] = false,
			['enableCloudStorage'] = true,
			['NPEDemo'] = false,
			['NPEDemo2'] = false,
			['UseDoorRewardScreen'] = false,
			['disabledFeatures'] = { 'standardrating', 'strifeapp', 'ranked', 'khanquest', 'referafriend', 'counterstrife' },
			['cvars'] = {
				{'ui_regionalPartner', 'string', 'S2 Games'},
				-- {'http_printDebugInfo', 'int', '0', true},
				-- {'php_printDebugInfo', 'bool', 'false', true},
				{'ui_Overhaul', 'bool', 'true', true},
				{'ui_multiWindowChat', 'bool', 'true', true},
				{'shopShowFiltersDefault', 'bool', 'true', true},
			},
			['motd'] = "messages.strife.com/prod.motd",
		},

		-- SEA production branch
		['sea_prod'] = {
			['regionCondition'] = (false),	-- This region cannot be automatically activated, it uses location lookup instead
			['langCodes'] = {
				{code = 'en', flag = '/ui/shared/textures/flags/unitedstates.tga', displayName = 'en'},
				{code = 'zh', flag = '/ui/shared/textures/flags/china.tga', displayName = 'zh'},
				{code = 'th', flag = '/ui/shared/textures/flags/thailand.tga', displayName = 'th'},
				{code = 'ru', flag = '/ui/shared/textures/flags/russia.tga', displayName = 'ru'},
				-- {code = 'vi', flag = '/ui/shared/textures/flags/vietnam.tga', displayName = 'vi'},
				{code = 'pt_br', flag = '/ui/shared/textures/flags/brazil.tga', 	displayName = 'pt_br'},
				-- {code = 'fr', flag = '/ui/shared/textures/flags/france.tga', 		displayName = 'fr'},
				 {code = 'de', flag = '/ui/shared/textures/flags/germany.tga', 		displayName = 'de'},
				-- {code = 'es', flag = '/ui/shared/textures/flags/spain.tga', 		displayName = 'es'},
			},
			['isProduction'] = true,
			['allowDevHeroes'] = false,
			['dialogOnSevereError'] = false,
			['alertOnSevereError'] = false,
			['dialogOnMinorError'] = false,
			['dialogOnWebError'] = true,
			['obnoxiousErrorReporting'] = false,
			['useWIPFeatures'] = false,
			['allowIdentSelection'] = false,
			['allowIdentCreation'] = false,
			['allowDisplayNameChange'] = false,
			['allowUniqueIDChange'] = false,
			['showLangChoice'] = true,
			['useAntiAbuse'] = true,
			['allowedLoginMethods'] = {
				-- name			login function		setup function
				{'asiasoft', 				'AttemptAsiasoftLogin', 			'SetUpAsiasoftLogin'},
				-- {'asiasoft_facebook', 		'AttemptAsiasoftFacebookLogin', 	'SetUpAsiasoftLogin'},
				-- {'igames', 		'AttemptS2Login', 	'SetUpS2Login'},
				-- {'facebook', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'twitter', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'google', 		'AttemptS2Login', 	'SetUpS2Login'},
			},
			['hideDevWidgets'] = true,
			['enableWebRequests'] = true,
			['enableDevServerTypes'] = false,
			['enableDevMaps'] = false,
			['allowRealPurchases'] = true,
			['buyGemsURL'] = 'https://strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/payment',
			['strifeWebsiteURL'] = 'https://www.strife.com',
			['strifeSupportURL'] = 'http://support.s2games.com',
			['createAccountURL'] = 'https://secure2.playpark.com/register/Register.aspx',
			['purchaseBoostURL'] = 'https://strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/purchase',
			['forgotPasswordURL'] = 'https://secure2.playpark.com/MemberPlaypark/resetpw.aspx',
			['enabledDevAnimations'] = false,
			['new_player_experience'] = true,
			['NPEIsOptional'] = true,
			['NPEIsABOptional'] = true,
			['preview_splash'] = false,
			['enableCloudStorage'] = true,
			['NPEDemo'] = false,
			['NPEDemo2'] = false,
			['UseDoorRewardScreen'] = false,
			['disabledFeatures'] = { 'standardrating', 'strifeapp', 'ranked', 'khanquest', 'referafriend', 'counterstrife' },
			['cvars'] = {
				{'ui_regionalPartner', 'string', 'S2 Games'},
				-- {'http_printDebugInfo', 'int', '0', true},
				-- {'php_printDebugInfo', 'bool', 'false', true},
				{'ui_Overhaul', 'bool', 'true', true},
				{'ui_multiWindowChat', 'bool', 'true', true},
				{'shopShowFiltersDefault', 'bool', 'true', true},
			},
			['motd'] = "messages.strife.com/prod.motd",
		},

		-- ======================================
		-- Mail.RU - CIS Regions
		-- ======================================

		['ru_rc'] = {
			['regionCondition'] = ((GetCvarString('build_branch') == 'rc') and (GetCvarString('host_provider') == 'mailru')) ,
			['langCodes'] = {
				{code = 'en', flag = '/ui/shared/textures/flags/unitedstates.tga', displayName = 'en'},
				{code = 'ru', flag = '/ui/shared/textures/flags/russia.tga', displayName = 'ru'},
				{code = 'zh', flag = '/ui/shared/textures/flags/china.tga', displayName = 'zh'},
				{code = 'th', flag = '/ui/shared/textures/flags/thailand.tga', displayName = 'th'},
				-- {code = 'vi', flag = '/ui/shared/textures/flags/vietnam.tga', displayName = 'vi'},
				{code = 'pt_br', flag = '/ui/shared/textures/flags/brazil.tga', 	displayName = 'pt_br'},
				-- {code = 'fr', flag = '/ui/shared/textures/flags/france.tga', 		displayName = 'fr'},
				 {code = 'de', flag = '/ui/shared/textures/flags/germany.tga', 		displayName = 'de'},
				-- {code = 'es', flag = '/ui/shared/textures/flags/spain.tga', 		displayName = 'es'},
			},
			['isProduction'] = true,
			['allowDevHeroes'] = false,
			['dialogOnSevereError'] = false,
			['alertOnSevereError'] = false,
			['dialogOnMinorError'] = false,
			['dialogOnWebError'] = true,
			['obnoxiousErrorReporting'] = false,
			['useWIPFeatures'] = false,
			['allowIdentSelection'] = false,
			['allowIdentCreation'] = false,
			['allowDisplayNameChange'] = false,
			['allowUniqueIDChange'] = false,
			['showLangChoice'] = true,
			['useAntiAbuse'] = true,
			['allowedLoginMethods'] = {
				-- name			login function		setup function
				{'igames', 		'AttemptS2Login', 	'SetUpS2Login'},
				-- {'facebook', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'twitter', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'google', 		'AttemptS2Login', 	'SetUpS2Login'},
			},
			['hideDevWidgets'] = true,
			['enableWebRequests'] = true,
			['enableDevServerTypes'] = false,
			['enableDevMaps'] = false,
			['allowRealPurchases'] = true,
			['buyGemsURL'] = 'https://strife.mail.ru/billing/payment/',
			['strifeWebsiteURL'] = 'https://strife.mail.ru/',
			['strifeSupportURL'] = 'http://games.mail.ru/support/str/#/',
			['createAccountURL'] = 'https://strife.com/create/',
			['purchaseBoostURL'] = 'https://strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/purchase',
			['forgotPasswordURL'] = 'https://strife.com/login/',
			['enabledDevAnimations'] = false,
			['new_player_experience'] = true,
			['NPEIsOptional'] = true,
			['NPEIsABOptional'] = true,
			['preview_splash'] = false,
			['enableCloudStorage'] = false,
			['NPEDemo'] = false,
			['NPEDemo2'] = false,
			['UseDoorRewardScreen'] = false,
			['disabledFeatures'] = { 'standardrating', 'strifeapp', 'ranked', 'khanquest', 'referafriend', 'counterstrife'},
			['cvars'] = {
				{'ui_regionalPartner', 'string', 'mail.ru'},
				-- {'http_printDebugInfo', 'int', '0', true},
				-- {'php_printDebugInfo', 'bool', 'false', true},
				{'ui_Overhaul', 'bool', 'true', true},
				{'ui_multiWindowChat', 'bool', 'true', true},
				{'shopShowFiltersDefault', 'bool', 'true', true},
			},
			['motd'] = "messages.strife.com/rc.motd",
		},

		['ru_prod'] = {
			['regionCondition'] = ((GetCvarString('build_branch') == 'prod') and (GetCvarString('host_provider') == 'mailru')),
			['langCodes'] = {
				{code = 'en', flag = '/ui/shared/textures/flags/unitedstates.tga', displayName = 'en'},
				{code = 'ru', flag = '/ui/shared/textures/flags/russia.tga', displayName = 'ru'},
				{code = 'zh', flag = '/ui/shared/textures/flags/china.tga', displayName = 'zh'},
				{code = 'th', flag = '/ui/shared/textures/flags/thailand.tga', displayName = 'th'},
				-- {code = 'vi', flag = '/ui/shared/textures/flags/vietnam.tga', displayName = 'vi'},
				{code = 'pt_br', flag = '/ui/shared/textures/flags/brazil.tga', 	displayName = 'pt_br'},
				-- {code = 'fr', flag = '/ui/shared/textures/flags/france.tga', 		displayName = 'fr'},
				 {code = 'de', flag = '/ui/shared/textures/flags/germany.tga', 		displayName = 'de'},
				-- {code = 'es', flag = '/ui/shared/textures/flags/spain.tga', 		displayName = 'es'},
			},
			['isProduction'] = true,
			['allowDevHeroes'] = false,
			['dialogOnSevereError'] = false,
			['alertOnSevereError'] = false,
			['dialogOnMinorError'] = false,
			['dialogOnWebError'] = true,
			['obnoxiousErrorReporting'] = false,
			['useWIPFeatures'] = false,
			['allowIdentSelection'] = false,
			['allowIdentCreation'] = false,
			['allowDisplayNameChange'] = false,
			['allowUniqueIDChange'] = false,
			['showLangChoice'] = true,
			['useAntiAbuse'] = true,
			['allowedLoginMethods'] = {
				-- name			login function		setup function
				{'igames', 		'AttemptS2Login', 	'SetUpS2Login'},
				-- {'facebook', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'twitter', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'google', 		'AttemptS2Login', 	'SetUpS2Login'},
			},
			['hideDevWidgets'] = true,
			['enableWebRequests'] = true,
			['enableDevServerTypes'] = false,
			['enableDevMaps'] = false,
			['allowRealPurchases'] = true,
			['buyGemsURL'] = 'http://strife.mail.ru/billing/payment/',
			['strifeWebsiteURL'] = 'https://strife.mail.ru/',
			['strifeSupportURL'] = 'http://games.mail.ru/support/str/#/',
			['createAccountURL'] = 'https://strife.com/create/',
			['purchaseBoostURL'] = 'https://strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/purchase',
			['forgotPasswordURL'] = 'https://strife.com/login/',
			['enabledDevAnimations'] = false,
			['new_player_experience'] = true,
			['NPEIsOptional'] = true,
			['NPEIsABOptional'] = true,
			['preview_splash'] = false,
			['enableCloudStorage'] = false,
			['NPEDemo'] = false,
			['NPEDemo2'] = false,
			['UseDoorRewardScreen'] = false,
			['disabledFeatures'] = { 'standardrating', 'strifeapp', 'ranked', 'khanquest', 'twitch', 'referafriend', 'counterstrife'},
			['cvars'] = {
				{'ui_regionalPartner', 'string', 'S2 Games'},
				-- {'http_printDebugInfo', 'int', '0', true},
				-- {'php_printDebugInfo', 'bool', 'false', true},
				{'ui_Overhaul', 'bool', 'true', true},
				{'ui_multiWindowChat', 'bool', 'true', true},
				{'shopShowFiltersDefault', 'bool', 'true', true},
			},
			['motd'] = "messages.strife.com/prod.motd",
		},

		-- ======================================
		-- YY - China Regions
		-- ======================================

		['yy_china'] = { -- gapp, gov testing region
			['regionCondition'] = ((GetCvarString('build_branch') == 'gapp') and (GetCvarString('host_provider') == 'yy')),
			['langCodes'] = {
				{code = 'en', flag = '/ui/shared/textures/flags/unitedstates.tga', displayName = 'en'},
				{code = 'zh', flag = '/ui/shared/textures/flags/china.tga', displayName = 'zh'},
				{code = 'ru', flag = '/ui/shared/textures/flags/russia.tga', displayName = 'ru'},
				{code = 'th', flag = '/ui/shared/textures/flags/thailand.tga', displayName = 'th'},
				-- {code = 'vi', flag = '/ui/shared/textures/flags/vietnam.tga', displayName = 'vi'},
				{code = 'pt_br', flag = '/ui/shared/textures/flags/brazil.tga', 	displayName = 'pt_br'},
				-- {code = 'fr', flag = '/ui/shared/textures/flags/france.tga', 		displayName = 'fr'},
				 {code = 'de', flag = '/ui/shared/textures/flags/germany.tga', 		displayName = 'de'},
				-- {code = 'es', flag = '/ui/shared/textures/flags/spain.tga', 		displayName = 'es'},
			},
			['isProduction'] = true,
			['isLockedToThisRegion'] = true,
			['allowDevHeroes'] = false,
			['dialogOnSevereError'] = false,
			['alertOnSevereError'] = false,
			['dialogOnMinorError'] = false,
			['dialogOnWebError'] = true,
			['obnoxiousErrorReporting'] = false,
			['useWIPFeatures'] = false,
			['allowIdentSelection'] = false,
			['allowIdentCreation'] = false,
			['allowDisplayNameChange'] = false,
			['allowUniqueIDChange'] = false,
			['showLangChoice'] = true,
			['useAntiAbuse'] = false,
			['allowedLoginMethods'] = {
				-- name			login function		setup function
				{'igames', 		'AttemptS2Login', 	'SetUpS2Login'},
				-- {'facebook', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'twitter', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'google', 		'AttemptS2Login', 	'SetUpS2Login'},
			},
			['hideDevWidgets'] = true,
			['enableWebRequests'] = true,
			['enableDevServerTypes'] = false,
			['enableDevMaps'] = false,
			['allowRealPurchases'] = false,
			['buyGemsURL'] = 'https://strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/payment',
			['strifeWebsiteURL'] = 'http://mh.yy.com/',
			['strifeSupportURL'] = 'http://mh.yy.com/',
			['createAccountURL'] = 'http://mh.yy.com/',
			['purchaseBoostURL'] = 'http://mh.yy.com/',
			['forgotPasswordURL'] = 'http://mh.yy.com/',
			['enabledDevAnimations'] = false,
			['new_player_experience'] = true,
			['NPEIsOptional'] = true,
			['NPEIsABOptional'] = true,
			['preview_splash'] = false,
			['enableCloudStorage'] = false,
			['NPEDemo'] = false,
			['NPEDemo2'] = false,
			['UseDoorRewardScreen'] = false,
			['disabledFeatures'] = { 'standardrating', 'strifeapp', 'voice', 'khanquest', 'scrim', 'twitch_vods', 'twitch_stream', 'howto', 'twitch', 'referafriend', 'ranked', 'referafriend'},
			['cvars'] = {
				{'ui_regionalPartner', 'string', 'S2 Games'},
				-- {'http_printDebugInfo', 'int', '0', true},
				-- {'php_printDebugInfo', 'bool', 'false', true},
				{'ui_Overhaul', 'bool', 'true', true},
				{'ui_multiWindowChat', 'bool', 'true', true},
				{'shopShowFiltersDefault', 'bool', 'true', true},
				{'ui_scoreboardDefaultsToTab', 'bool', 'true'},
			},
			['motd'] = "messages.strife.com/prod.motd",
			['logoOverride'] = "/ui/main/shared/textures/logo_cn.tga",
		},

		['cn_test'] = {
			['regionCondition'] = ((GetCvarString('build_branch') == 'cn_test') and (GetCvarString('host_provider') == 'yy')),
			['langCodes'] = {
				{code = 'en', flag = '/ui/shared/textures/flags/unitedstates.tga', displayName = 'en'},
				{code = 'zh', flag = '/ui/shared/textures/flags/china.tga', displayName = 'zh'},
				{code = 'ru', flag = '/ui/shared/textures/flags/russia.tga', displayName = 'ru'},
				{code = 'th', flag = '/ui/shared/textures/flags/thailand.tga', displayName = 'th'},
				-- {code = 'vi', flag = '/ui/shared/textures/flags/vietnam.tga', displayName = 'vi'},
				{code = 'pt_br', flag = '/ui/shared/textures/flags/brazil.tga', 	displayName = 'pt_br'},
				-- {code = 'fr', flag = '/ui/shared/textures/flags/france.tga', 		displayName = 'fr'},
				 {code = 'de', flag = '/ui/shared/textures/flags/germany.tga', 		displayName = 'de'},
				-- {code = 'es', flag = '/ui/shared/textures/flags/spain.tga', 		displayName = 'es'},
			},
			['isProduction'] = true,
			['isLockedToThisRegion'] = true,
			['allowDevHeroes'] = false,
			['dialogOnSevereError'] = false,
			['alertOnSevereError'] = false,
			['dialogOnMinorError'] = false,
			['dialogOnWebError'] = true,
			['obnoxiousErrorReporting'] = false,
			['useWIPFeatures'] = false,
			['allowIdentSelection'] = false,
			['allowIdentCreation'] = false,
			['allowDisplayNameChange'] = false,
			['allowUniqueIDChange'] = false,
			['showLangChoice'] = true,
			['useAntiAbuse'] = false,
			['allowedLoginMethods'] = {
				-- name			login function		setup function
				{'igames', 		'AttemptS2Login', 	'SetUpS2Login'},
				-- {'facebook', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'twitter', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'google', 		'AttemptS2Login', 	'SetUpS2Login'},
			},
			['hideDevWidgets'] = true,
			['enableWebRequests'] = true,
			['enableDevServerTypes'] = false,
			['enableDevMaps'] = true,
			['allowRealPurchases'] = false,
			['buyGemsURL'] = 'https://strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/payment',
			['strifeWebsiteURL'] = 'http://mh.yy.com/',
			['strifeSupportURL'] = 'http://mh.yy.com/',
			['createAccountURL'] = 'http://mh.yy.com/',
			['purchaseBoostURL'] = 'http://mh.yy.com/',
			['forgotPasswordURL'] = 'http://mh.yy.com/',
			['enabledDevAnimations'] = false,
			['new_player_experience'] = true,
			['NPEIsOptional'] = true,
			['NPEIsABOptional'] = true,
			['preview_splash'] = false,
			['enableCloudStorage'] = false,
			['NPEDemo'] = false,
			['NPEDemo2'] = false,
			['UseDoorRewardScreen'] = false,
			['disabledFeatures'] = { 'standardrating', 'strifeapp', 'voice','khanquest', 'scrim', 'twitch_vods', 'twitch_stream', 'howto', 'twitch', 'referafriend', 'ranked', 'referafriend'},
			['cvars'] = {
				{'ui_regionalPartner', 'string', 'S2 Games'},
				-- {'http_printDebugInfo', 'int', '0', true},
				-- {'php_printDebugInfo', 'bool', 'false', true},
				{'ui_Overhaul', 'bool', 'true', true},
				{'ui_multiWindowChat', 'bool', 'true', true},
				{'shopShowFiltersDefault', 'bool', 'true', true},
				{'ui_scoreboardDefaultsToTab', 'bool', 'true'},
			},
			['motd'] = "yygame.duowan.com/strife/cn_test.motd",
			['logoOverride'] = "/ui/main/shared/textures/logo_cn.tga",
		},

		['cn_rc'] = {
			['regionCondition'] = ((GetCvarString('build_branch') == 'cn_rc') and (GetCvarString('host_provider') == 'yy')),
			['langCodes'] = {
				{code = 'en', flag = '/ui/shared/textures/flags/unitedstates.tga', displayName = 'en'},
				{code = 'zh', flag = '/ui/shared/textures/flags/china.tga', displayName = 'zh'},
				{code = 'ru', flag = '/ui/shared/textures/flags/russia.tga', displayName = 'ru'},
				{code = 'th', flag = '/ui/shared/textures/flags/thailand.tga', displayName = 'th'},
				-- {code = 'vi', flag = '/ui/shared/textures/flags/vietnam.tga', displayName = 'vi'},
				{code = 'pt_br', flag = '/ui/shared/textures/flags/brazil.tga', 	displayName = 'pt_br'},
				-- {code = 'fr', flag = '/ui/shared/textures/flags/france.tga', 		displayName = 'fr'},
				 {code = 'de', flag = '/ui/shared/textures/flags/germany.tga', 		displayName = 'de'},
				-- {code = 'es', flag = '/ui/shared/textures/flags/spain.tga', 		displayName = 'es'},
			},
			['isProduction'] = true,
			['isLockedToThisRegion'] = true,
			['allowDevHeroes'] = false,
			['dialogOnSevereError'] = false,
			['alertOnSevereError'] = false,
			['dialogOnMinorError'] = false,
			['dialogOnWebError'] = true,
			['obnoxiousErrorReporting'] = false,
			['useWIPFeatures'] = false,
			['allowIdentSelection'] = false,
			['allowIdentCreation'] = false,
			['allowDisplayNameChange'] = false,
			['allowUniqueIDChange'] = false,
			['showLangChoice'] = true,
			['useAntiAbuse'] = false,
			['allowedLoginMethods'] = {
				-- name			login function		setup function
				{'igames', 		'AttemptS2Login', 	'SetUpS2Login'},
				-- {'facebook', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'twitter', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'google', 		'AttemptS2Login', 	'SetUpS2Login'},
			},
			['hideDevWidgets'] = true,
			['enableWebRequests'] = true,
			['enableDevServerTypes'] = false,
			['enableDevMaps'] = false,
			['allowRealPurchases'] = false,
			['buyGemsURL'] = 'https://strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/payment',
			['strifeWebsiteURL'] = 'http://mh.yy.com/',
			['strifeSupportURL'] = 'http://mh.yy.com/',
			['createAccountURL'] = 'http://mh.yy.com/',
			['purchaseBoostURL'] = 'http://mh.yy.com/',
			['forgotPasswordURL'] = 'http://mh.yy.com/',
			['enabledDevAnimations'] = false,
			['new_player_experience'] = true,
			['NPEIsOptional'] = true,
			['NPEIsABOptional'] = true,
			['preview_splash'] = false,
			['enableCloudStorage'] = false,
			['NPEDemo'] = false,
			['NPEDemo2'] = false,
			['UseDoorRewardScreen'] = false,
			['disabledFeatures'] = { 'standardrating', 'strifeapp', 'voice','khanquest', 'scrim', 'twitch_vods', 'twitch_stream', 'howto', 'twitch', 'referafriend', 'ranked', 'ladder', 'referafriend'},
			['cvars'] = {
				{'ui_regionalPartner', 'string', 'S2 Games'},
				-- {'http_printDebugInfo', 'int', '0', true},
				-- {'php_printDebugInfo', 'bool', 'false', true},
				{'ui_Overhaul', 'bool', 'true', true},
				{'ui_multiWindowChat', 'bool', 'true', true},
				{'shopShowFiltersDefault', 'bool', 'true', true},
				{'ui_scoreboardDefaultsToTab', 'bool', 'true'},
			},
			['motd'] = "yygame.duowan.com/strife/cn_rc.motd",
			['logoOverride'] = "/ui/main/shared/textures/logo_cn.tga",
		},

		['cn_prod'] = {
			['regionCondition'] = ((GetCvarString('build_branch') == 'cn_prod') and (GetCvarString('host_provider') == 'yy')),
			['langCodes'] = {
				{code = 'en', flag = '/ui/shared/textures/flags/unitedstates.tga', displayName = 'en'},
				{code = 'zh', flag = '/ui/shared/textures/flags/china.tga', displayName = 'zh'},
				{code = 'ru', flag = '/ui/shared/textures/flags/russia.tga', displayName = 'ru'},
				{code = 'th', flag = '/ui/shared/textures/flags/thailand.tga', displayName = 'th'},
				-- {code = 'vi', flag = '/ui/shared/textures/flags/vietnam.tga', displayName = 'vi'},
				{code = 'pt_br', flag = '/ui/shared/textures/flags/brazil.tga', 	displayName = 'pt_br'},
				-- {code = 'fr', flag = '/ui/shared/textures/flags/france.tga', 		displayName = 'fr'},
				 {code = 'de', flag = '/ui/shared/textures/flags/germany.tga', 		displayName = 'de'},
				-- {code = 'es', flag = '/ui/shared/textures/flags/spain.tga', 		displayName = 'es'},
			},
			['isProduction'] = true,
			['isLockedToThisRegion'] = true,
			['allowDevHeroes'] = false,
			['dialogOnSevereError'] = false,
			['alertOnSevereError'] = false,
			['dialogOnMinorError'] = false,
			['dialogOnWebError'] = true,
			['obnoxiousErrorReporting'] = false,
			['useWIPFeatures'] = false,
			['allowIdentSelection'] = false,
			['allowIdentCreation'] = false,
			['allowDisplayNameChange'] = false,
			['allowUniqueIDChange'] = false,
			['showLangChoice'] = true,
			['useAntiAbuse'] = false,
			['allowedLoginMethods'] = {
				-- name			login function		setup function
				{'igames', 		'AttemptS2Login', 	'SetUpS2Login'},
				-- {'facebook', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'twitter', 	'AttemptS2Login', 	'SetUpS2Login'},
				-- {'google', 		'AttemptS2Login', 	'SetUpS2Login'},
			},
			['hideDevWidgets'] = true,
			['enableWebRequests'] = true,
			['enableDevServerTypes'] = false,
			['enableDevMaps'] = false,
			['allowRealPurchases'] = false,
			['buyGemsURL'] = 'https://strife.com/login/gamesession/{accountId}/{sessionKey}/?redirect=/payment',
			['strifeWebsiteURL'] = 'http://mh.yy.com/',
			['strifeSupportURL'] = 'http://mh.yy.com/',
			['createAccountURL'] = 'http://mh.yy.com/',
			['purchaseBoostURL'] = 'http://mh.yy.com/',
			['forgotPasswordURL'] = 'http://mh.yy.com/',
			['enabledDevAnimations'] = false,
			['new_player_experience'] = true,
			['NPEIsOptional'] = true,
			['NPEIsABOptional'] = true,
			['preview_splash'] = false,
			['enableCloudStorage'] = false,
			['NPEDemo'] = false,
			['NPEDemo2'] = false,
			['UseDoorRewardScreen'] = false,
			['disabledFeatures'] = { 'standardrating', 'strifeapp', 'voice', 'khanquest', 'scrim', 'twitch_vods', 'twitch_stream', 'howto', 'twitch', 'referafriend', 'ranked', 'ladder', 'referafriend'},
			['cvars'] = {
				{'ui_regionalPartner', 'string', 'S2 Games'},
				-- {'http_printDebugInfo', 'int', '0', true},
				-- {'php_printDebugInfo', 'bool', 'false', true},
				{'ui_Overhaul', 'bool', 'true', true},
				{'ui_multiWindowChat', 'bool', 'true', true},
				{'shopShowFiltersDefault', 'bool', 'true', true},
				{'ui_scoreboardDefaultsToTab', 'bool', 'true'},
			},
			['motd'] = "yygame.duowan.com/strife/cn_prod.motd",
			['logoOverride'] = "/ui/main/shared/textures/logo_cn.tga",
		},

	}

function Strife_Region:PopulateLanguageSelector(widget)
	if (Strife_Region.regionTable) and (Strife_Region.regionTable[Strife_Region.activeRegion]) and (widget) then
		local prevLang = widget:UICmd("GetSelectedItemName()")
		if Empty(prevLang) then prevLang = GetCvarString('host_language') end
		widget:ClearItems()
		local currentFlag
		for index, langTable in pairs(Strife_Region.regionTable[Strife_Region.activeRegion].langCodes) do
			widget:AddTemplateListItem('windowframe_combobox_lang_item', langTable.code, 'code', langTable.code, 'texture', langTable.flag, 'label', 'lang_'..langTable.displayName)
			if (prevLang == langTable.code) then
				currentFlag = langTable.flag
			end
		end
		widget:Sleep(500, widget:UICmd("SetSelectedItemByValue('"..prevLang.."', false)"))
		-- println(currentFlag)
		groupfcall('main_header_btn_language_icon_group', function(_, widget2) widget2:SetTexture(currentFlag) end)
	end
end

local function UpdateRegionCvars()
	if (Strife_Region.regionTable) and (Strife_Region.regionTable[Strife_Region.activeRegion]) and (Strife_Region.regionTable[Strife_Region.activeRegion].cvars) then
		for index, cvarTable in pairs((Strife_Region.regionTable[Strife_Region.activeRegion].cvars)) do
			if (type(cvarTable[3]) == 'function') then
				--Cvar.CreateCvar(cvarTable[1], cvarTable[2], tostring(cvarTable[3]()) )
				Set(cvarTable[1], tostring(cvarTable[3]()), cvarTable[2], cvarTable[4])
			else
				--Cvar.CreateCvar(cvarTable[1], cvarTable[2], tostring(cvarTable[3]))
				Set(cvarTable[1],  tostring(cvarTable[3]), cvarTable[2], cvarTable[4])
			end
		end
	end
end

local function ActivateRegionPostLoad(_, region)
	Trigger('UIUpdateRegion')
	if (Strife_Region.regionTable[Strife_Region.activeRegion].hideDevWidgets) then
		if interface:GetGroup('strife_dev_widgets_group') then
			for _, widget in pairs(interface:GetGroup('strife_dev_widgets_group')) do
				widget:SetVisible(0)
			end
		end
	else
		if interface:GetGroup('strife_dev_widgets_group') then
			for _, widget in pairs(interface:GetGroup('strife_dev_widgets_group')) do
				widget:SetVisible(1)
			end
		end
	end
	if (Strife_Region.regionTable[Strife_Region.activeRegion].preview_splash) and GetWidget('preview_splash', 'main', true) then
		GetWidget('preview_splash'):SetVisible(1)
		GetWidget('preview_splash'):RegisterWatchLua('mainPanelStatus', function(widget, trigger)
			libGeneral.fade(widget, (trigger.main == 101) and (trigger.gamePhase == 0), 250)
		end, false, nil, 'main', 'gamePhase')
	end
	if (Login) then
		local methodTable = Login.GetSelectedLoginMethodTable()
		if (methodTable) then
			Login.UpdateSelectedLoginMethod(mainUI.savedAnonymously.RegionInfo.lastUsedLoginMethod)
		else
			Login.UpdateSelectedLoginMethod(Strife_Region.regionTable[Strife_Region.activeRegion].allowedLoginMethods[1][1])
		end
		Login.AttemptSetUpLogin()
	end
	local logoLabel = GetWidget('mainLogo_label')
	if (logoLabel) and (Strife_Region.activeRegion) and (not Strife_Region.regionTable[Strife_Region.activeRegion].isProduction) then
		logoLabel:SetText(Translate(GetCvarString('build_branch')))
		logoLabel:FadeIn(250)
	end
end

local function GEOIPActivateRegion(region)
	if (Strife_Region.regionTable) and (Strife_Region.regionTable[region]) and (not ((Strife_Region.activeRegion) and (Strife_Region.regionTable[Strife_Region.activeRegion]) and (Strife_Region.regionTable[Strife_Region.activeRegion].isLockedToThisRegion))) then
		println('^cUI: GEOIP Region is ' .. tostring(region) )
		Strife_Region.activeRegion = region
		-- SetActiveRegion(region)
		UpdateRegionCvars()

		interface:Sleep(1,
			function()
				ActivateRegionPostLoad(_, region)
				FindChildrenClickCallbacks(UIManager.GetActiveInterface())
				LuaTrigger.GetTrigger('LoginStatus'):Trigger(true)
				LuaTrigger.GetTrigger('mainPanelStatus'):Trigger(true)
			end
		)
	else
		println('^cUI: Locked to region - Ignoring GEOIP region of ' .. tostring(region) )
	end
end

function SetUIRegionFromGEOIP(incRegion)
	if (incRegion) and (Strife_Region.activeRegion ~= incRegion) then
		if (Strife_Region.activeRegion) and (Strife_Region.regionTable[Strife_Region.activeRegion].isProduction) then
			GEOIPActivateRegion(incRegion)
		else
			GEOIPActivateRegion(incRegion) -- RMM remove this later
		end
	end
end

local function ActivateRegion(_, region)
	println('^cUI: Region is ' .. tostring(region) )
	if (Strife_Region.regionTable) and (Strife_Region.regionTable[region]) then

		Strife_Region.activeRegion = region
		-- SetActiveRegion(region)
		UpdateRegionCvars()

		interface:Sleep(1,
			function()
				ActivateRegionPostLoad(_, region)
				FindChildrenClickCallbacks(UIManager.GetActiveInterface())
			end
		)

	end
end
-- interface:RegisterWatch('SetActiveRegion', ActivateRegion)

local function UIFindRegion()
	if (Strife_Region.regionOverride) and (not Empty(Strife_Region.regionOverride)) then
		ActivateRegion(nil, Strife_Region.regionOverride)
	elseif (Strife_Region.regionTable) then
		local useDefault = true
		for region, regionTable in pairs(Strife_Region.regionTable) do
			if (regionTable) and (regionTable.regionCondition) then
				useDefault = false
				ActivateRegion(nil, region)
				break
			end
		end
		if (useDefault) then
			ActivateRegion(nil, 's2_prod')
			println('^r UIFindRegion failed, using s2_prod')
		end
	else
		println('^:^r Critical Error: UIFindRegion Region Table Invalid')
	end
	UIFindRegion = nil
end
UIFindRegion()

function interface:StrifeRegionF(func, ...)
	if (Strife_Region[func]) then
		print(Strife_Region[func](self, ...))
	else
		print('StrifeRegionF failed to find: ' .. tostring(func) .. '\n')
	end
end



