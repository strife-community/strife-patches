-- End-of-main initialization stuff
-- RMM Move all initialisation here
mainUI 					= mainUI 					or {}
mainUI.savedLocally 	= mainUI.savedLocally 		or {}
mainUI.savedRemotely 	= mainUI.savedRemotely 		or {}
mainUI.savedAnonymously	= mainUI.savedAnonymously 	or {}

ContextMenuTrigger.contextMenuArea = -1
ContextMenuTrigger.selectedUserIsLocalClient = false
ContextMenuTrigger.selectedUserIsFriend = false
ContextMenuTrigger.selectedUserOnlineStatus = false
ContextMenuTrigger.selectedUserIsInGame = false
ContextMenuTrigger.selectedUserIsInParty = false
ContextMenuTrigger.selectedUserIsInLobby = false
ContextMenuTrigger.localClientIsSpectating = false
ContextMenuTrigger.joinableGame = false
ContextMenuTrigger.joinableParty = false
ContextMenuTrigger.spectatableGame = false
ContextMenuTrigger.needToApprove = false
ContextMenuTrigger.selectedUserIdentID = ''
ContextMenuTrigger.gameAddress = ''
ContextMenuTrigger.selectedUserUniqueID = ''
ContextMenuTrigger.selectedUserUsername = ''
ContextMenuTrigger.channelID = ''
ContextMenuTrigger.endMatchSection = -1
ContextMenuTrigger:Trigger(false)

local selectionStatus 				= LuaTrigger.GetTrigger('selection_Status')
local HeroSelectLocalPlayerInfo 	= LuaTrigger.GetTrigger('HeroSelectLocalPlayerInfo')
local heroEntityName 				= HeroSelectLocalPlayerInfo.heroEntityName
local petEntityName 				= HeroSelectLocalPlayerInfo.petEntityName

selectionStatus.selectionSection	= mainUI.Selection.selectionSections.HERO_PICK
if (heroEntityName) and (not Empty(heroEntityName)) and ValidateEntity(heroEntityName) and (petEntityName) and (not Empty(petEntityName)) and ValidateEntity(petEntityName) then  -- Allow recovery from reload
	selectionStatus.selectionComplete	= true
else
	selectionStatus.selectionComplete	= false
end
selectionStatus:Trigger(false)

local socialPanelInfoHovering = LuaTrigger.GetTrigger('socialPanelInfoHovering')

socialPanelInfoHovering.friendHoveringIndex				= -1
socialPanelInfoHovering.friendHoveringIdentID			= -1
socialPanelInfoHovering.friendHoveringUniqueID			= -1
socialPanelInfoHovering.friendHoveringName				= -1
socialPanelInfoHovering.friendHoveringAcceptStatus		= -1
socialPanelInfoHovering.friendHoveringWidgetIndex		= -1
socialPanelInfoHovering.friendHoveringGameAddress		= ''
socialPanelInfoHovering.friendHoveringLabel				= ''
socialPanelInfoHovering.friendHoveringIsPending			= false
socialPanelInfoHovering.friendHoveringIsInLobby			= false
socialPanelInfoHovering.friendHoveringIsInParty			= false
socialPanelInfoHovering.friendHoveringIsInGame			= false
socialPanelInfoHovering.friendHoveringCanSpectate		= false
socialPanelInfoHovering.friendHoveringIsHoveringMenu	= false
socialPanelInfoHovering.friendHoveringIsOnline 			= false
socialPanelInfoHovering.friendHoveringType 				= 0	-- 0 friend, 1 party, 2 teammate (play screen)
socialPanelInfoHovering:Trigger(true)

local playerRankInfo = LuaTrigger.GetTrigger('playerRankInfo')
playerRankInfo.division = 'bronze'
playerRankInfo.rank		= 0
playerRankInfo.rankedUnlocked = false
playerRankInfo:Trigger(true)

local triggerPanelStatus = LuaTrigger.GetTrigger('mainPanelStatus')

if mainUI.savedRemotely.launcherMusicEnabled == nil then
	mainUI.savedRemotely.launcherMusicEnabled = true
end

triggerPanelStatus.hideSecondaryElements = GetCvarBool('ui_PAXDemo') or false
triggerPanelStatus.launcherMusicEnabled = mainUI.savedRemotely.launcherMusicEnabled
triggerPanelStatus:Trigger(true)

LuaTrigger.CreateGroupTrigger('DatabaseProgressionLoadStateGroupTrigger', {
	'DatabaseLoadStateTrigger',
	'mainPanelStatus',
	'ProgressionLoadStateTrigger',
})

WatchLuaTrigger('DatabaseProgressionLoadStateGroupTrigger', function(groupTrigger)
	local trigger = groupTrigger['mainPanelStatus']
	local ProgressionLoadStateTrigger = groupTrigger['ProgressionLoadStateTrigger']
	if IsFullyLoggedIn(GetIdentID()) and (DatabaseLoadStateTrigger) and (DatabaseLoadStateTrigger.stateLoaded) and (ProgressionLoadStateTrigger.stateLoaded) then
		if (mainUI.savedLocally) and (mainUI.savedLocally.lastMatchID) then
			println('^g^: Queued EndMatch ID : ' .. tostring(mainUI.savedLocally.lastMatchID))
			LuaTrigger.GetTrigger('EndMatch'):Trigger(true)
		elseif (mainUI.savedLocally) and (mainUI.savedLocally.speContentComplete) and (mainUI.savedLocally.speContentComplete.bastion1) then
			mainUI.savedLocally.speContentComplete = nil
			SaveState()
			mainUI.ShowSplashScreen('postgame_spe_splash_bastion_1_template')
		elseif (GetCvarBool('ui_testPostgame3')) then
			TestPostGame()
		end
		UnwatchLuaTriggerByKey('DatabaseLoadStateGroupTrigger', 'state_restore_after_login')	
	end
end, 'state_restore_after_login')

WatchLuaTrigger('DatabaseLoadStateGroupTrigger', function(groupTrigger)
	local trigger = LuaTrigger.GetTrigger('mainPanelStatus')
	if IsFullyLoggedIn(GetIdentID()) and (DatabaseLoadStateTrigger) and (DatabaseLoadStateTrigger.stateLoaded) and (trigger) and (trigger.chatConnectionState >= 1) then
		if (mainUI.savedLocally) and (mainUI.savedLocally.notifications) and (#mainUI.savedLocally.notifications > 0) then
			println('^c mainUI.savedLocally.notifications')
			printr(mainUI.savedLocally.notifications)				
			for index, notificationTable in pairs(mainUI.savedLocally.notifications) do
				ChatClient.AddNotification(notificationTable[1], notificationTable[2])
			end
			mainUI.savedLocally.notifications = nil
		end
		UnwatchLuaTriggerByKey('DatabaseLoadStateGroupTrigger', 'notifications_restore_after_login')	
	end
end, 'notifications_restore_after_login')

FindChildrenClickCallbacks(object)

-- Init ui cvars
cvarInit = function(cvarName, cvarType, cvarValue, setSave, forceValue)
	forceValue = forceValue or false
	if setSave == nil then setSave = true end

	if cvarType and cvarValue then
		local thisCvar = Cvar.GetCvar(cvarName)
		if not thisCvar then
			thisCvar = Cvar.CreateCvar(cvarName, cvarType, cvarValue)
		elseif forceValue then
			thisCvar:Set(cvarValue)
		end
		if setSave then
			thisCvar:SetSave(true)
		end
		
		return thisCvar
	end
end

cvarInit('voice_voiceActivation', 'bool', 'false')
cvarInit('ui_swapMinimap', 'bool', 'false')
cvarInit('ui_whisperRequiresFriendship', 'bool', 'false')
cvarInit('ui_challengeRequiresFriendship', 'bool', 'false')
cvarInit('voice_vaThreshold', 'int', '5')
cvarInit('_heroVitalsVis', 'bool', 'false')
cvarInit('_pushOrbVis', 'bool', 'false')
cvarInit('_heroInfoVis', 'bool', 'false')
cvarInit('_backpackVis', 'bool', 'false')
cvarInit('_expWheelVis', 'bool', 'false')
cvarInit('_bossTimerVis', 'bool', 'false')
cvarInit('_game_screenFeedbackVis', 'bool', 'true')
cvarInit('_game_always_show_hero_levels_new', 'bool', 'true')
cvarInit('_game_always_show_hero_names_new', 'bool', 'true')
cvarInit('_game_healthLerping', 'bool', 'true')
cvarInit('_ui_friendNotificationSound', 'bool', 'true')
cvarInit('ui_newUISounds', 'bool', 'true', true, true)

-- Fix for triggers that do not refire on reload
LuaTrigger.GetTrigger('ChatAvailability'):Trigger(false)
LuaTrigger.GetTrigger('LeaverBan'):Trigger(false)
LuaTrigger.GetTrigger('ChatPartySummary'):Trigger(false)
LuaTrigger.GetTrigger('ChatConnectionStatus'):Trigger(true)

setMainTriggers({
	mainBackground = {wheelX='-250s', logoSlide=false, navBackingVisible=false, logoX='750s', logoY='30s', logoWidth='500s', logoHeight='250s'},
	mainNavigation = {visible=false }
})
