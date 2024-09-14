local interface = object

mainUI = mainUI or {}
mainUI.savedLocally = mainUI.savedLocally or {}

Profile = {}
Profile.lastIdentID = '' 
Profile.lastResponse = nil
Profile.duplicateEntryTable = {}

local playerProfileAnimStatus = LuaTrigger.GetTrigger('playerProfileAnimStatus')
local loadedAtLeastOneHero = false
	
function playerProfileRegister(object)

	local container					= object:GetWidget('playerProfile')

	local inviteButton				= object:GetWidget('playerProfileInviteButton')
	local addFriendButton			= object:GetWidget('playerProfileAddFriendButton')
	local sendMessageButton			= object:GetWidget('playerProfileSendMessageButton')
	local editNameButton			= object:GetWidget('playerProfileEditNameButton')
	local closeButton				= object:GetWidget('playerProfileCloseButton')

	local primaryGroupName			= object:GetWidget('playerProfilePrimaryGroupName')
	local playerUniqueID			= object:GetWidget('playerProfilePlayerUniqueID')
	local playerProfileEditUniqueIDButton			= object:GetWidget('playerProfileEditUniqueIDButton')
	local playerTitle				= object:GetWidget('playerProfilePlayerTitle')
	local iconEditOverlay			= object:GetWidget('playerProfileIconEditOverlay')

	local playerNameEditPanel		= object:GetWidget('playerProfileNameEditPanel')	-- Edit player's name.  For gems or something!

	local account_icons_listbox		= object:GetWidget('playerProfile_account_icons_listbox')

	local profileInfo				= LuaTrigger.GetTrigger('playerProfileInfo')

	local playerIconContainer		= object:GetWidget('playerProfileIconContainer')
	local playerProfileIconContainerIcon		= object:GetWidget('playerProfileIconContainerIcon')	
	
	playerIconContainer:SetCallback('onmouseover', function(widget)
		simpleTipGrowYUpdate(true, nil, Translate('player_profile_icon_header'), Translate('player_profile_icon_info'))
		libAnims.wobbleStart(playerProfileIconContainerIcon)
	end)
	playerIconContainer:SetCallback('onmouseout', function(widget)
		simpleTipGrowYUpdate(false)
		libAnims.wobbleStop(playerProfileIconContainerIcon)
	end)

	playerIconContainer:SetCallback('onclick', function(widget)
		mainUI.setBreadcrumbsSelected(-1)
		mainUI.BoostToPlayerCard()
		PlaySound('/ui/sounds/launcher/sfx_account_iconopen.wav')
		local playerProfileAnimStatus = LuaTrigger.GetTrigger('playerProfileAnimStatus')
		playerProfileAnimStatus.section = 'iconList'
		playerProfileAnimStatus:Trigger(false)
		mainUI.savedLocally.profileSection1 = playerProfileAnimStatus.section
		SaveState()
	end)	
	
	closeButton:SetCallback('onclick', function(widget)
		local mainPanelStatus	= LuaTrigger.GetTrigger('mainPanelStatus')
		mainPanelStatus.main	= 101
		mainPanelStatus:Trigger(false)
	end)

	inviteButton:RegisterWatchLua('playerProfileInfo', function(widget, trigger) widget:SetVisible(not trigger.viewingSelf) end, false, nil, 'viewingSelf')
	addFriendButton:RegisterWatchLua('playerProfileInfo', function(widget, trigger) widget:SetVisible(not trigger.viewingSelf) end, false, nil, 'viewingSelf')
	sendMessageButton:RegisterWatchLua('playerProfileInfo', function(widget, trigger) widget:SetVisible(not trigger.viewingSelf) end, false, nil, 'viewingSelf')
	
	function Profile.UpdateLadder(profileData)
		
		-- println('^y profileData')
		-- printr(profileData.ladderRankings)

		local ladderData = profileData.ladderRankings or {}
		local top100Data = ladderData.top100Players or {}
		local sortedTop100Data = {}
		local selfLadderInfo = ladderData.currentPlayer or {}

		local ladder_row_scrollbar = GetWidget('ladder_row_scrollbar')
		local ladder_row_scrollbar_vscroll = GetWidget('ladder_row_scrollbar_vscroll')
		
		local oldRows = ladder_row_scrollbar:GetChildren()
		for i,v in pairs(oldRows) do
			if (v) and (v:IsValid()) then
				v:Destroy()
			end
		end
		
		for i,v in pairs(top100Data) do
			if (v) and (v.rank) and tonumber(v.rank) then
				table.insert(sortedTop100Data, v)
			end
		end
		
		table.sort(sortedTop100Data, function(a, b)
			if tonumber(a.rank) and tonumber(b.rank) and tonumber(a.rank) ~= tonumber(b.rank) then
				return tonumber(a.rank) < tonumber(b.rank)
			else
				return false
			end
		end)
		
		local selfInTopTen = false
		local selfInTopOneHundred = false
		if (selfLadderInfo) and (selfLadderInfo.rank) and tonumber(selfLadderInfo.rank) and (tonumber(selfLadderInfo.rank) >= 1) and (tonumber(selfLadderInfo.rank) <= 100) then
			for i,v in pairs(top100Data) do
				if (v.rank) and tonumber(v.rank) and (tonumber(v.rank) >= 1) and (tonumber(v.rank) <= 10) and (IsMe(v.ident_id)) then
					selfInTopTen = true
					break
				elseif (v.rank) and tonumber(v.rank) and (tonumber(v.rank) >= 1) and (tonumber(v.rank) <= 100) and (IsMe(v.ident_id)) then
					selfInTopOneHundred = true		
					break
				end
			end
		end
		
		if (selfLadderInfo) then
			
			mainUI = mainUI or {}
			mainUI.progression = mainUI.progression or {}
			mainUI.progression.stats = mainUI.progression.stats or {}
			mainUI.progression.stats.account = mainUI.progression.stats.account or {}
			mainUI.progression.stats.account.ladderPoints = selfLadderInfo.ladderPoints or 0
			mainUI.progression.stats.account.ladderRank = selfLadderInfo.rank or 0
			
			local lastLadderPoints = 0
			
			if (mainUI.savedLocally) and (mainUI.savedLocally.lib_compete) and (mainUI.savedLocally.lib_compete.ladder) and (mainUI.savedLocally.lib_compete.ladder.lastLadderPoints) then
				lastLadderPoints = mainUI.savedLocally.lib_compete.ladder.lastLadderPoints
			end
			
			if (lastLadderPoints) and (mainUI.progression.stats.account.ladderPoints) then
				local newLadderPoints = mainUI.progression.stats.account.ladderPoints - lastLadderPoints
				PostGame = PostGame or {}
				PostGame.Splash = PostGame.Splash or {}
				PostGame.Splash.modules = PostGame.Splash.modules or {}
				PostGame.Splash.modules.ladder = PostGame.Splash.modules.ladder or {}
				PostGame.Splash.modules.ladder.newLadderPoints = newLadderPoints
			end
			
			mainUI = mainUI or {}
			mainUI.savedLocally = mainUI.savedLocally or {}
			mainUI.savedLocally.lib_compete = mainUI.savedLocally.lib_compete or {}
			mainUI.savedLocally.lib_compete.ladder = mainUI.savedLocally.lib_compete.ladder or {}
			mainUI.savedLocally.lib_compete.ladder.lastLadderRank = mainUI.progression.stats.account.ladderRank
			mainUI.savedLocally.lib_compete.ladder.lastLadderPoints = mainUI.progression.stats.account.ladderPoints
			SaveState()
			
			if (mainUI.featureMaintenance and mainUI.featureMaintenance['ladder']) then
				GetWidget('playerProfileLadderPoints'):SetText('')
			elseif (selfInTopOneHundred) or (selfInTopTen) then
				GetWidget('playerProfileLadderPoints'):SetText(Translate('stat_name_ladder_rank_points_x', 'value', selfLadderInfo.rank, 'value2', selfLadderInfo.ladderPoints))
			else
				GetWidget('playerProfileLadderPoints'):SetText(Translate('stat_name_ladder_points_x', 'value', selfLadderInfo.ladderPoints, 'value2', selfLadderInfo.rank))
			end
			
			if (not selfInTopTen) then
				local elo = selfLadderInfo.elo or 0
				local ladderPoints = tonumber(selfLadderInfo.ladderPoints) or 0
				ladder_row_scrollbar:Instantiate('ladderRow',
					'id', 0,
					'displayname', selfLadderInfo.nickname .. '.' .. selfLadderInfo.uniqid,
					'rank', selfLadderInfo.rank,
					'rating', math.ceil(elo + 1500),
					'points', math.ceil(ladderPoints),
					'color', '0 1 .85 0.12'
				)
			end
			
		end
		
		for i,v in ipairs(sortedTop100Data) do
			local color = '0 .4 1 0.04'
			local elo = tonumber(v.elo) or 0
			local ladderPoints = tonumber(v.ladderPoints) or 0
			if (selfInTopTen) and (IsMe(v.ident_id)) then
				color = '0 1 .85 0.12'
			elseif (i % 2) == 0 then 
				color = '0 .4 1 0.07'
			end
			ladder_row_scrollbar:Instantiate('ladderRow',
				'id', i, -- v.ladderRank, RMM
				'displayname', (v.nickname or '?') .. '.' .. (v.uniqid or '?'),
				'rank', v.rank or '?',
				'rating', math.ceil(elo + 1500),
				'points', math.ceil(ladderPoints),
				'color', color
			)
		end
		
		ladder_row_scrollbar:SetClipAreaToChild()
		ladder_row_scrollbar_vscroll:SetValue(0)
		
		local ranked_session_remaining_days = GetWidget('ranked_session_remaining_days')
		
		local season1EndTimestamp = '1512061140' -- (GMT): Thursday, November 30, 2017 4:59:00 PM
		
		local SystemTrigger = LuaTrigger.GetTrigger('System')
		local currentTimestamp = SystemTrigger.unixTimestamp
		
		local formattedEndTime, formattedRemaining, remainingSeconds = FormatTimeUntil(season1EndTimestamp, currentTimestamp, '%#I:%M %p %B %d, %Y')

		local daysRemaining = math.floor(remainingSeconds / (3600 * 24))	
		daysRemaining = math.ceil(daysRemaining)

		if (daysRemaining > 0) and (daysRemaining < 350) then
			ranked_session_remaining_days:SetText(daysRemaining)
		else
			ranked_session_remaining_days:SetText('0')
		end

	end
	
	function Profile.UpdateProfile(profileData, isMe)
		
		-- println('^y Profile.UpdateProfile ')
		-- printr(profileData)
		
		if (not profileData) or (not profileData.nickname) then
			println('^r profileData is missing ')
			-- printr(profileData)
			return
		end

		local isSelf = (profileData.ident_id == GetIdentID())

		if (isSelf) and (profileData.matchHistoryList) and (profileData.matchHistoryList.matchHistoryList) then
			local sortableTable = {}
			for i,v in pairs(profileData.matchHistoryList.matchHistoryList) do
				table.insert(sortableTable, v)
			end
			table.sort(sortableTable, function(a, b)
				if tonumber(a.timestamp) and tonumber(b.timestamp) and tonumber(a.timestamp) ~= tonumber(b.timestamp) then
					return tonumber(a.timestamp) > tonumber(b.timestamp)
				elseif tonumber(a.match_id) and tonumber(b.match_id) and tonumber(a.match_id) ~= tonumber(b.match_id) then
					return tonumber(a.match_id) > tonumber(b.match_id)
				else
					return false
				end
			end)
			mainUI.watch.recentGameList = sortableTable
		end

		if (not container) or (not container:IsValid()) then
			println('^r Profile thread unterminated - UpdateProfile called on invalid widgets ')
			return
		end		

		local playerProfileLeaverInfo = GetWidget('playerProfileLeaverInfo')
		playerProfileLeaverInfo:UnregisterWatchLua('playerProfileInfo')
		playerProfileLeaverInfo:RegisterWatchLua('playerProfileInfo', function(widget, trigger)
			widget:SetVisible(trigger.viewingSelf)	
		end, false, nil, 'viewingSelf')

		addFriendButton:SetCallback('onclick', function(widget)
			ChatClient.AddFriend(profileData.ident_id)
		end)

		sendMessageButton:SetCallback('onclick', function(widget)
			mainUI.chatManager.InitPrivateMessage(profileData.ident_id, 1, profileData.nickname)
		end)

		inviteButton:SetCallback('onclick', function(widget)
			if (LuaTrigger.GetTrigger('LobbyStatus').inLobby) then
				ChatClient.GameInvite(profileData.ident_id)
			elseif (not LuaTrigger.GetTrigger('HeroSelectMode').isCustomLobby) then
				ChatClient.PartyInvite(profileData.ident_id)
			end
		end)

		-- account icon chooser
		local tempIconData = {}
		local hasActiveAccountIcon = false
		if (profileData.clientAccountIcons) and (profileData.clientAccountIcons.clientAccountIcons) then
			for i, v in pairs(profileData.clientAccountIcons.clientAccountIcons) do
				table.insert(tempIconData, v)
			end
		else
			SevereError('GetProfile - clientAccountIcons missing', 'main_reconnect_thatsucks', '', nil, nil, false)
		end
		
		local failFunction =  function (request)	-- error handler
			SevereError('SetAccountIcon Request Error: ' .. Translate(request:GetError()), 'main_reconnect_thatsucks', '', nil, nil, false)
			return nil
		end
		
		for i, v in pairs(tempIconData) do
			if (v) and (v.stringTableName) and (not Empty(v.stringTableName)) then
				local owned = GetWidget('profile_achievement_icon_'..v.stringTableName..'_owned', nil, true)			
				local icon = GetWidget('profile_achievement_icon_'..v.stringTableName, nil, true)
				local lock = GetWidget('profile_achievement_icon_'..v.stringTableName..'_lock', nil, true)
				local iconhoverBehind = GetWidget('profile_achievement_icon_'..v.stringTableName..'_hoverBehind', nil, true)
				local iconhover = GetWidget('profile_achievement_icon_'..v.stringTableName..'_hover', nil, true)
				local container = GetWidget('profile_achievement_icon_'..v.stringTableName..'_container', nil, true)
				
				if (icon and icon:IsValid()) then
					local index = i
					icon:SetRenderMode('normal')
					owned:SetVisible(true)
					lock:SetVisible(false)
					iconhover:SetBorderColor('#61d5ec')
					iconhoverBehind:SetColor('.4 .9 1 .8')
					iconhoverBehind:SetBorderColor('.4 .9 1 .8')
					
					icon:SetCallback('onclick', function(widget)
						local successFunction =  function (request)	-- response handler
							local responseData = request:GetBody()
							if responseData == nil then
								SevereError('SetAccountIcon - no response data', 'main_reconnect_thatsucks', '', nil, nil, false)
								return nil
							else
								PlaySound('/ui/sounds/launcher/sfx_account_icon.wav')
								local sourceX = widget:GetAbsoluteX()-5
								local sourceY = widget:GetAbsoluteY()-5
								local animwidget = GetWidget('main_header_player_card_icon_anim')
								animwidget:UICmd('SetAbsoluteX('.. sourceX .. ')')
								animwidget:UICmd('SetAbsoluteY('.. sourceY .. ')')
								animwidget:SetTexture((tempIconData[index].localPath) or '$checker')
								animwidget:FadeIn(125)
								animwidget:Sleep(150, function()
									animwidget:SlideY('0s', styles_mainSwapAnimationDuration)
									animwidget:SlideX('0s', styles_mainSwapAnimationDuration)
									libAnims.bounceIn(animwidget, animwidget:GetWidth() * 1.0, animwidget:GetHeight() * 1.0, nil, styles_mainSwapAnimationDuration, 0.1, 350, 0.8, 0.2)
								end)
								Profile.lastIdentID = ''
								GetProfileData()
								return true
							end
						end

						Strife_Web_Requests:SetAccountIcon(successFunction, failFunction, tempIconData[index].productIncrement)
					end)
					
					icon:SetCallback('onmouseout', function(widget)
						simpleTipGrowYUpdate(false)
						iconhover:FadeOut(200)
						iconhoverBehind:FadeOut(200)
						ScaleInPlace(container, '100@', '100%', 150, false, true)
					end)
					
					UpdateCursor(icon, true, { canLeftClick = true})
					
					
					if (tempIconData[index].active) and AtoB(tempIconData[index].active) then
						if (isSelf) then
							hasActiveAccountIcon = true
							GetWidget('main_header_player_card_icon'):Sleep(styles_mainSwapAnimationDuration, function()
								GetWidget('main_header_player_card_icon'):SetTexture(tempIconData[index].localPath or '$checker')
								GetWidget('main_header_player_card_icon_anim'):FadeOut(250)
							end)
						end
					end
				end
			end
		end
		
		if (not hasActiveAccountIcon) and (isSelf) and (tempIconData) and (tempIconData[1]) and (tempIconData[1].productIncrement) then
			Strife_Web_Requests:SetAccountIcon(successFunction, failFunction, tempIconData[1].productIncrement)
		end

		profileInfo.viewingSelf			= isSelf
		profileInfo:Trigger(true)

		playerProfileAnimStatus.viewingSelf			= isSelf
		playerProfileAnimStatus:Trigger(false)

		-- rebuildColumns()	-- Do last, otherwise will end up overwiting IDs
	end


	function GetProfileData(identID, force)

		local isMe = true
		if (identID) then
			isMe = (identID ==  GetIdentID())
		end
		local identID = identID or GetIdentID()

		if (force) or (not Profile.lastIdentID) or (Profile.lastIdentID ~= identID) then
			local successFunction =  function (request)	-- response handler
				local responseData = request:GetBody()
				if responseData == nil or (not responseData.nickname) then
					SevereError('GetProfile - no response data', 'main_reconnect_thatsucks', '', nil, nil, false)
					return nil
				else
					Profile.lastIdentID = identID
					Profile.lastResponse = responseData
					Profile.UpdateProfile(responseData, isMe)
					return true
				end
			end

			local failFunction =  function (request)	-- error handler
				SevereError('GetProfile Request Error: ' .. Translate(request:GetError()), 'main_reconnect_thatsucks', '', nil, nil, false)
				return nil
			end

			if IsValidIdent(identID) then
				Strife_Web_Requests:GetProfile(successFunction, failFunction, identID)
			else
				SevereError('GetProfile Invalid IdentID', 'main_reconnect_thatsucks', '', nil, nil, false)
				return nil
			end

		else
			Profile.UpdateProfile(Profile.lastResponse, isMe)
		end

	end

	GetWidget('playerProfileLeaverInfo'):RegisterWatchLua('LeaverBan', function(widget, trigger)
		local strikes = trigger.strikes
		
		if (strikes <= 0) then
			local value = 45
			GetWidget('playerProfileLeaverStatus_label_1'):SetText('^g' .. Translate('proifile_leaves_standing_good') .. '^*\n' .. Translate('proifile_leaves_standing_desc'))
			groupfcall('playerProfileLeaverInfoPie_markers', function(_, groupWidget) 
				groupWidget:SetRotation(value)
			end)
			GetWidget('playerProfileLeaverInfoPie'):SetValue(1-( value / 360))
			GetWidget('playerProfileLeaverInfoPie_nubbin'):SetColor('green')
		elseif (strikes <= 2) then
			local value = 150 + ((strikes-1) * 80)	
			GetWidget('playerProfileLeaverStatus_label_1'):SetText('^y'..Translate('proifile_leaves_standing_warning') .. '^*\n' .. Translate('proifile_leaves_standing_desc'))
			groupfcall('playerProfileLeaverInfoPie_markers', function(_, groupWidget) 
				groupWidget:SetRotation(value)
			end)
			GetWidget('playerProfileLeaverInfoPie'):SetValue(1-( value / 360))
			GetWidget('playerProfileLeaverInfoPie_nubbin'):SetColor('orange')				
		else
			local value = 240 + (strikes * 15)
			value = math.min(355, value)		
			GetWidget('playerProfileLeaverStatus_label_1'):SetText('^r'..Translate('proifile_leaves_standing_bad') .. '^*\n' .. Translate('proifile_leaves_standing_desc'))
			groupfcall('playerProfileLeaverInfoPie_markers', function(_, groupWidget) 
				groupWidget:SetRotation(value)
			end)	
			GetWidget('playerProfileLeaverInfoPie'):SetValue(1-( value / 360))
			GetWidget('playerProfileLeaverInfoPie_nubbin'):SetColor('red')
		end
		GetWidget('playerProfileLeaverInfoPie_label'):SetText(strikes)

	end, false, nil, 'bannedUntil', 'forgivenessTime', 'nextBanDuration', 'strikes', 'nextBanDuration', 'strikeDurations', 'strikeTimes')	
	
	GetWidget('playerProfileLeaverInfo_hover'):SetCallback('onmouseover', function(widget)

		local tipString 		= ''
		local LeaverBan 		= LuaTrigger.GetTrigger('LeaverBan')
		local UILeaverBan 		= LuaTrigger.GetTrigger('UILeaverBan')
		
		if (UILeaverBan) and (UILeaverBan.remainingBanSeconds) and (UILeaverBan.remainingBanSeconds > 0) then
			tipString = tipString .. Translate('main_leaver_tip_explain_banned', 'value', libNumber.timeFormat((UILeaverBan.remainingBanSeconds) * 1000)) .. '\n'
			tipString = tipString .. '\n'
		end

		-- if (LeaverBan) and (LeaverBan.nextBanDuration ) and (LeaverBan.nextBanDuration  >= 0) then
			-- tipString = tipString .. Translate('main_leaver_tip_explain_next_ban', 'value', libNumber.timeFormat((LeaverBan.nextBanDuration ) * 1000)) .. '\n'
		-- end			
		
		if (LeaverBan) and (LeaverBan.strikeTimes ) and (#LeaverBan.strikeTimes  > 0) then
			tipString = tipString .. Translate('main_leaver_tip_explain_strike_expire2') .. '\n'
			for i,v in pairs(LeaverBan.strikeTimes) do 
				tipString = tipString .. Translate('main_leaver_tip_explain_strike_expire', 'index', i, 'value', FormatDateTime(v, '%#I:%M %p %B %d, %Y', true)).. '\n'
			end
			tipString = tipString .. '\n'
		end		

		if (LeaverBan) and (LeaverBan.strikeDurations ) and (#LeaverBan.strikeDurations  > 0) then
			tipString = tipString .. Translate('main_leaver_tip_explain_strike_penalty2') .. '\n'
			for i,v in pairs(LeaverBan.strikeDurations) do
				tipString = tipString .. Translate('main_leaver_tip_explain_strike_penalty', 'index', i, 'value', libNumber.timeFormat((v) * 1000)) .. '\n'
			end
			tipString = tipString .. '\n'
		end			

		if (LeaverBan) and (LeaverBan.forgivenessTime) and (LeaverBan.forgivenessTime > 0) then
			tipString = tipString .. Translate('main_leaver_tip_explain_strike_forgive', 'value', libNumber.timeFormat((LeaverBan.forgivenessTime) * 1000)) .. '\n'
		end		
		
		simpleTipGrowYUpdate(true, nil, Translate('main_leaver_tip_explain_title'), tipString, 350)
	end)
	
	GetWidget('playerProfileLeaverInfo_hover'):SetCallback('onmouseout', function(widget)
		simpleTipGrowYUpdate(false)
	end)
	
	GetWidget('playerProfileLeaverInfo_hover2'):SetCallback('onmouseover', function(widget)

		local tipString 		= ''
		local LeaverBan 		= LuaTrigger.GetTrigger('LeaverBan')
		local UILeaverBan 		= LuaTrigger.GetTrigger('UILeaverBan')
		
		if (UILeaverBan) and (UILeaverBan.remainingBanSeconds) and (UILeaverBan.remainingBanSeconds > 0) then
			tipString = tipString .. Translate('main_leaver_tip_explain_banned', 'value', libNumber.timeFormat((UILeaverBan.remainingBanSeconds) * 1000)) .. '\n'
			tipString = tipString .. '\n'
		end

		-- if (LeaverBan) and (LeaverBan.nextBanDuration ) and (LeaverBan.nextBanDuration  >= 0) then
			-- tipString = tipString .. Translate('main_leaver_tip_explain_next_ban', 'value', libNumber.timeFormat((LeaverBan.nextBanDuration ) * 1000)) .. '\n'
		-- end			
		
		if (LeaverBan) and (LeaverBan.strikeTimes ) and (#LeaverBan.strikeTimes  > 0) then
			tipString = tipString .. Translate('main_leaver_tip_explain_strike_expire2') .. '\n'
			for i,v in pairs(LeaverBan.strikeTimes) do 
				tipString = tipString .. Translate('main_leaver_tip_explain_strike_expire', 'index', i, 'value', FormatDateTime(v, '%#I:%M %p %B %d, %Y', true)).. '\n'
			end
			tipString = tipString .. '\n'
		end		

		if (LeaverBan) and (LeaverBan.strikeDurations ) and (#LeaverBan.strikeDurations  > 0) then
			tipString = tipString .. Translate('main_leaver_tip_explain_strike_penalty2') .. '\n'
			for i,v in pairs(LeaverBan.strikeDurations) do
				tipString = tipString .. Translate('main_leaver_tip_explain_strike_penalty', 'index', i, 'value', libNumber.timeFormat((v) * 1000)) .. '\n'
			end
			tipString = tipString .. '\n'
		end			

		if (LeaverBan) and (LeaverBan.forgivenessTime) and (LeaverBan.forgivenessTime > 0) then
			tipString = tipString .. Translate('main_leaver_tip_explain_strike_forgive', 'value', libNumber.timeFormat((LeaverBan.forgivenessTime) * 1000)) .. '\n'
		end		
		
		simpleTipGrowYUpdate(true, nil, Translate('main_leaver_tip_explain_title'), tipString, 350)
			
	end)
	
	GetWidget('playerProfileLeaverInfo_hover2'):SetCallback('onmouseout', function(widget)
		simpleTipGrowYUpdate(false)
	end)	

	container:UnregisterWatchLua('mainPanelStatus')
	container:RegisterWatchLua('mainPanelStatus', function(widget, trigger)
		if (trigger.main == 23) then
			local selectedUserIdentID = nil
			if (trigger.selectedUserIdentID) and (not Empty(trigger.selectedUserIdentID)) then
				selectedUserIdentID = trigger.selectedUserIdentID
			end
			GetProfileData(selectedUserIdentID)
			trigger.selectedUserIdentID = ''
		end
	end, false, nil, 'main', 'selectedUserIdentID')

	local lastSelected = 2
	local selectionMap = {quests=5, heroes=2, karma1=3, karma2=4, achievements=1, referafriend=6, strifeapp=7, khanquest=8, ladder=9}
	local sounds = {'progress', 'heroprogress', nil, nil, 'gamequests', 'referfriend', nil, nil, 'ladder'}
	local function setSection(section)
		local playerProfileAnimStatus = LuaTrigger.GetTrigger('playerProfileAnimStatus')
		playerProfileAnimStatus.section = section
		playerProfileAnimStatus:Trigger(false)
		mainUI.savedLocally.profileSection1 = section
		lastSelected = selectionMap[section]
		PlaySound('/ui/sounds/launcher/sfx_account_' .. sounds[lastSelected] .. '.wav')
		mainUI.setBreadcrumbsSelected(lastSelected)
		SaveState()
	end
	
	local breadCrumbsTable = {
		{text='player_profile_progression',       onclick=function(widget) setSection('achievements'      ) end, group="profile_menu_group", id="playerProfileSectionTabAchievements"},
		{text='player_profile_hero_progress', 	  onclick=function(widget) setSection('heroes'      ) end, group="profile_menu_group", id="playerProfileSectionTabHeros"},
		{text='karma_status_1', 	              onclick=function(widget) setSection('karma1(????)') end, group="profile_menu_group", id="playerProfileSectionTabStanding", visible="false"},
		{text='karma_status_2', 	              onclick=function(widget) setSection('karma2(????)') end, group="profile_menu_group", id="playerProfileSectionTabStanding2", visible="false"},
		{text='achievements_gamequests', 	      onclick=function(widget) setSection('quests') end, group="profile_menu_group", id="playerProfileSectionTabQuests", enabled=false, disabledTooltip='party_finder_comingsoon_feature_locked'},
		{text='player_profile_referafriend_title',onclick=function(widget) setSection('referafriend') end, group="profile_menu_group", id="playerProfileSectionTabReferAFriend", visible="false"},
		{text='player_profile_strifeapp_title',   onclick=function(widget) setSection('strifeapp'   ) end, group="profile_menu_group", id="playerProfileSectionTabStrifeApp", visible="false"},
		{text='player_profile_khanquest_manager', onclick=function(widget) setSection('khanquest'   ) end, group="profile_menu_group", id="playerProfileSectionTabKhanquest", visible="false"},
		{text='ladder_title', 					  onclick=function(widget) setSection('ladder'   ) end, group="profile_menu_group", id="playerProfileSectionTabLadder", enabled=false, disabledTooltip='party_finder_comingsoon_feature_locked'}
	}

	-- anim overall
	container:UnregisterWatchLua('mainPanelAnimationStatus')
	container:RegisterWatchLua('mainPanelAnimationStatus', function(widget, trigger)
		local animState = mainSectionAnimState(23, trigger.main, trigger.newMain)
		if animState == 1 then		-- outro
			groupfcall('profile_menu_group', function(_, widget) widget:SetNoClick(1) end)
			groupfcall('profile_animation_widgets', function(_, widget) widget:DoEventN(8) end)
			groupfcall('profile_animation_achievements_widgets', function(_, widget) widget:DoEventN(8) end)
			groupfcall('profile_animation_quests_widgets', function(_, widget) widget:DoEventN(8) end)
			groupfcall('profile_animation_khanquest_widgets', function(_, widget) widget:DoEventN(8) end)
			groupfcall('profile_animation_hero_progress_widgets', function(_, widget) widget:DoEventN(8) end)
			groupfcall('profile_animation_referafriend_widgets', function(_, widget) widget:DoEventN(8) end)
			groupfcall('profile_animation_strifeapp_widgets', function(_, widget) widget:DoEventN(8) end)
			groupfcall('profile_animation_icon_list_widgets', function(_, widget) widget:DoEventN(8) end)
			groupfcall('profile_animation_ladder_widgets', function(_, widget) widget:DoEventN(8) end)
			libThread.threadFunc(function() 
				wait(styles_mainSwapAnimationDuration)
				widget:SetVisible(false)
				groupfcall('profile_menu_group', function(_, widget) widget:SetNoClick(0) end)
			end)
		elseif animState == 2 then			-- fully hidden
			widget:SetVisible(false)
		elseif animState == 3 then			-- intro
			mainUI.initBreadcrumbs(breadCrumbsTable, nil, '42s')
			mainUI.setBreadcrumbsSelected(lastSelected)
			setMainTriggers({
				mainBackground = {blackTop=true}, -- Cover under the navigation
				mainNavigation = {breadCrumbsVisible=true}, -- navigation with breadcrumbs
			})
			
			PlaySound('/ui/sounds/launcher/sfx_account.wav')
			widget:SetVisible(true)
			libThread.threadFunc(function()
				wait(1)
				groupfcall('profile_animation_widgets', function(_, widget) RegisterRadialEase(widget,  508, 555, true) widget:DoEventN(7) end)
				playerProfileAnimStatus:Trigger(true)
			end)
		elseif animState == 4 then									-- fully displayed
			widget:SetVisible(true)
			mainUI.AdaptiveTraining.RecordUtilisationInstanceByFeatureName('profile')
		end
	end, false, nil, 'main', 'newMain', 'lastMain')

	-- sections anim
	local sectionHeroes				= object:GetWidget('playerProfileHeroMastery')
	local sectionQuests				= object:GetWidget('playerProfileQuests')
	local sectionAchievements		= object:GetWidget('playerProfileAchievements')
	local sectionReferAFriend		= object:GetWidget('playerProfileReferAFriend')
	local sectionStrifeApp			= object:GetWidget('playerProfile_strifeapp')
	local sectionStrifeAchievements	= object:GetWidget('playerProfileIconList')
	local sectionLadder				= object:GetWidget('playerProfile_ladder')
	
	
	sectionStrifeAchievements:RegisterWatchLua('playerProfileAnimStatus', function(widget, trigger)
		if (trigger.section == 'iconList') and (trigger.viewingSelf) then
			widget:SetVisible(1)
			groupfcall('profile_animation_icon_list_widgets', function(_, widget) RegisterRadialEase(widget, nil, nil, true) widget:DoEventN(7) end)
			groupfcall('profile_menu_group', function(_, widget) widget:SetNoClick(1) end)
		else
			groupfcall('profile_animation_icon_list_widgets', function(_, widget) widget:DoEventN(8) end)
			libThread.threadFunc(function()
				wait(styles_mainSwapAnimationDuration)
				widget:SetVisible(0)
				groupfcall('profile_menu_group', function(_, widget) widget:SetNoClick(0) end)
			end)
		end
	end, false, nil, 'section', 'viewingSelf')
	
	
	sectionHeroes:RegisterWatchLua('playerProfileAnimStatus', function(widget, trigger)
		if (trigger.section == 'heroes') and (trigger.viewingSelf) then
			widget:SetVisible(1)
			groupfcall('profile_animation_hero_progress_widgets', function(_, widget) RegisterRadialEase(widget, nil, nil, true) widget:DoEventN(7) end)
			groupfcall('profile_menu_group', function(_, widget) widget:SetNoClick(1) end)
		else
			groupfcall('profile_animation_hero_progress_widgets', function(_, widget) widget:DoEventN(8) end)
			libThread.threadFunc(function()
				wait(styles_mainSwapAnimationDuration)
				widget:SetVisible(0)
				groupfcall('profile_menu_group', function(_, widget) widget:SetNoClick(0) end)
			end)
		end
	end, false, nil, 'section', 'viewingSelf')

	sectionQuests:RegisterWatchLua('playerProfileAnimStatus', function(widget, trigger)
		if (trigger.section == 'quests') and (trigger.viewingSelf) then
			widget:SetVisible(1)
			groupfcall('profile_animation_quests_widgets', function(_, widget) RegisterRadialEase(widget) widget:DoEventN(7) end)
			groupfcall('profile_menu_group', function(_, widget) widget:SetNoClick(1) end)
		else
			groupfcall('profile_animation_quests_widgets', function(_, widget) widget:DoEventN(8) end)
			libThread.threadFunc(function()
				wait(styles_mainSwapAnimationDuration)
				widget:SetVisible(0)
				groupfcall('profile_menu_group', function(_, widget) widget:SetNoClick(0) end)
			end)
		end
	end, false, nil, 'section', 'viewingSelf')

	sectionAchievements:RegisterWatchLua('playerProfileAnimStatus', function(widget, trigger)
		if (trigger.section == 'achievements') and (trigger.viewingSelf) then
			widget:SetVisible(1)
			groupfcall('profile_animation_achievements_widgets', function(_, widget) RegisterRadialEase(widget) widget:DoEventN(7) end)
			groupfcall('profile_menu_group', function(_, widget) widget:SetNoClick(1) end)
		else
			groupfcall('profile_animation_achievements_widgets', function(_, widget) widget:DoEventN(8) end)
			libThread.threadFunc(function()
				wait(styles_mainSwapAnimationDuration)
				widget:SetVisible(0)
				groupfcall('profile_menu_group', function(_, widget) widget:SetNoClick(0) end)
			end)
		end
		groupfcall('profile_account_progress_quest_list_progress', function(_, groupWidget) groupWidget:SetVisible(trigger.section == 'achievements') end)
		groupfcall('profile_account_progress_quest_list_vis_progress', function(_, groupWidget) groupWidget:SetVisible(trigger.section == 'achievements') end)
	end, false, nil, 'section', 'viewingSelf')
	
	sectionReferAFriend:RegisterWatchLua('playerProfileAnimStatus', function(widget, trigger)
		if (trigger.section == 'referafriend') and (trigger.viewingSelf) then
			widget:SetVisible(1)
			groupfcall('profile_animation_referafriend_widgets', function(_, widget) RegisterRadialEase(widget) widget:DoEventN(7) end)
			groupfcall('profile_menu_group', function(_, widget) widget:SetNoClick(1) end)
		else
			groupfcall('profile_animation_referafriend_widgets', function(_, widget) widget:DoEventN(8) end)
			libThread.threadFunc(function()
				wait(styles_mainSwapAnimationDuration)
				widget:SetVisible(0)
				groupfcall('profile_menu_group', function(_, widget) widget:SetNoClick(0) end)
			end)
		end
	end, false, nil, 'section', 'viewingSelf')	
	
	sectionStrifeApp:RegisterWatchLua('playerProfileAnimStatus', function(widget, trigger)
		if (trigger.section == 'strifeapp') and (trigger.viewingSelf) then
			widget:SetVisible(1)
			groupfcall('profile_animation_strifeapp_widgets', function(_, widget) RegisterRadialEase(widget) widget:DoEventN(7) end)
			groupfcall('profile_menu_group', function(_, widget) widget:SetNoClick(1) end)
		else
			groupfcall('profile_animation_strifeapp_widgets', function(_, widget) widget:DoEventN(8) end)
			libThread.threadFunc(function()
				wait(styles_mainSwapAnimationDuration)
				widget:SetVisible(0)
				groupfcall('profile_menu_group', function(_, widget) widget:SetNoClick(0) end)
			end)
		end
	end, false, nil, 'section', 'viewingSelf')
	
	sectionLadder:RegisterWatchLua('playerProfileAnimStatus', function(widget, trigger)
		if (trigger.section == 'ladder') and (trigger.viewingSelf) then
			widget:SetVisible(1)
			groupfcall('profile_animation_ladder_widgets', function(_, widget) RegisterRadialEase(widget) widget:DoEventN(7) end)
			groupfcall('profile_menu_group', function(_, widget) widget:SetNoClick(1) end)
		else
			groupfcall('profile_animation_ladder_widgets', function(_, widget) widget:DoEventN(8) end)
			libThread.threadFunc(function()
				wait(styles_mainSwapAnimationDuration)
				widget:SetVisible(0)
				groupfcall('profile_menu_group', function(_, widget) widget:SetNoClick(0) end)
			end)
		end
	end, false, nil, 'section', 'viewingSelf')

	--- player card icon swap
	GetWidget('playerProfileIconContainer'):UnregisterWatchLua('mainPanelAnimationStatus')
	GetWidget('playerProfileIconContainer'):RegisterWatchLua('mainPanelAnimationStatus', function(widget, trigger)
		local animState = mainSectionAnimState(23, trigger.main, trigger.newMain)
		if animState == 1 then
			widget:FadeOut(styles_mainSwapAnimationDuration)
		elseif animState == 2 then
			widget:SetVisible(0)
		elseif animState == 3 then
			widget:FadeIn(styles_mainSwapAnimationDuration)
		elseif animState == 4 then
			widget:SetVisible(1)
		end
	end, false, nil, 'main', 'newMain')

	local sectionHeroes						= object:GetWidget('playerProfileHeroMastery')
	local sectionQuests						= object:GetWidget('playerProfileQuests')
	local sectionAchievements				= object:GetWidget('playerProfileAchievements')
	local sectionReferAFriend				= object:GetWidget('playerProfileReferAFriend')
	local sectionStrifeApp					= object:GetWidget('playerProfile_strifeapp')

	container:RegisterWatchLua('featureMaintenanceTrigger', function(widget, trigger)
        --TheChiprel: While it is a nice concept, featureMaintenance is not ready to be used:
        --  1) there are no required Cvars in client;
        --  2) implementation doesn't check starting values
        --[=====[
		breadCrumbsTable[selectionMap['khanquest']].enabled = not (mainUI.featureMaintenance and mainUI.featureMaintenance['khanquest'])
		breadCrumbsTable[selectionMap['referafriend']].enabled = not (mainUI.featureMaintenance and mainUI.featureMaintenance['referafriend'])
		breadCrumbsTable[selectionMap['strifeapp']].enabled = not (mainUI.featureMaintenance and mainUI.featureMaintenance['strifeapp'])
		breadCrumbsTable[selectionMap['ladder']].enabled = not (mainUI.featureMaintenance and mainUI.featureMaintenance['ladder'])
		breadCrumbsTable[selectionMap['khanquest']].visible = not (mainUI.featureMaintenance and mainUI.featureMaintenance['khanquest'])
		breadCrumbsTable[selectionMap['referafriend']].visible = not (mainUI.featureMaintenance and mainUI.featureMaintenance['referafriend'])
		breadCrumbsTable[selectionMap['strifeapp']].visible = not (mainUI.featureMaintenance and mainUI.featureMaintenance['strifeapp'])
		breadCrumbsTable[selectionMap['ladder']].visible = not (mainUI.featureMaintenance and mainUI.featureMaintenance['ladder'])
		
		-- profile page currently active, enable/disable also
		if (LuaTrigger.GetTrigger('mainPanelStatus').main == mainUI.MainValues.profile and interface:GetWidget('playerProfileSectionTabHeros')) then
			mainUI.setBreadcrumbsEnabled(selectionMap['khanquest'], breadCrumbsTable[selectionMap['khanquest']].enabled)
			mainUI.setBreadcrumbsEnabled(selectionMap['referafriend'], breadCrumbsTable[selectionMap['referafriend']].enabled)
			mainUI.setBreadcrumbsEnabled(selectionMap['strifeapp'], breadCrumbsTable[selectionMap['strifeapp']].enabled)
			mainUI.setBreadcrumbsEnabled(selectionMap['ladder'], breadCrumbsTable[selectionMap['ladder']].enabled)
			mainUI.setBreadcrumbsEnabled(selectionMap['khanquest'], breadCrumbsTable[selectionMap['khanquest']].visible)
			mainUI.setBreadcrumbsEnabled(selectionMap['referafriend'], breadCrumbsTable[selectionMap['referafriend']].visible)
			mainUI.setBreadcrumbsEnabled(selectionMap['strifeapp'], breadCrumbsTable[selectionMap['strifeapp']].visible)
			mainUI.setBreadcrumbsEnabled(selectionMap['ladder'], breadCrumbsTable[selectionMap['ladder']].visible)
		end
        --]=====]
	end, false, nil)

	-- ==
	
	local main_simple_ui_signup_parent 			= object:GetWidget('playerProfileReferAFriend_email_signup_parent')
	local main_simple_ui_signup_input 			= object:GetWidget('playerProfileReferAFriend_email_signup_input')
	local main_simple_ui_signup_submit 			= object:GetWidget('playerProfileReferAFriend_email_signup_submit')
	local main_simple_ui_signup_response 		= object:GetWidget('playerProfileReferAFriend_email_signup_reponse')
	local main_simple_ui_signup_response_label 	= object:GetWidget('playerProfileReferAFriend_email_signup_response_label')

	local function SubmitEmail()
		local email = main_simple_ui_signup_input:GetValue()

		local successFunction = function (request)	-- response handler
			local responseData = request:GetBody()
			if responseData == nil then
				main_simple_ui_signup_response:SetVisible(1)
				main_simple_ui_signup_response_label:SetText(Translate('profile_referafriend_email_fail'))	-- main_simple_email_response_0
				main_simple_ui_signup_response:Sleep(5500, function(widget)
					widget:FadeOut(750)
				end)		
			else
				main_simple_ui_signup_response:SetVisible(1)
				main_simple_ui_signup_response_label:SetText(Translate('profile_referafriend_email_success'))
				main_simple_ui_signup_response:Sleep(4500, function(widget)
					widget:FadeOut(750)
				end)				
				main_simple_ui_signup_input:SetInputLine('')					
			end
		end
		
		local failFunction = function (request)	-- error handler
			main_simple_ui_signup_response:SetVisible(1)
			main_simple_ui_signup_response_label:SetText(Translate('profile_referafriend_email_fail'))	-- main_simple_email_response_0
			main_simple_ui_signup_response:Sleep(5500, function(widget)
				widget:FadeOut(750)
			end)
			main_simple_ui_signup_input:SetInputLine('')			
		end		
		
		Strife_Web_Requests:SendReferAFriendEmail(email, successFunction, failFunction)
		
	end

	main_simple_ui_signup_parent:SetCallback('onevent', function(widget)
		SubmitEmail()
	end)

	main_simple_ui_signup_submit:SetCallback('onclick', function(widget)
		-- main_simpleUI_signup_submit
		main_simple_ui_signup_submit:SetEnabled(0)
		PlaySound('ui/sounds/sfx_ui_login.wav')
		SubmitEmail()
	end)

	main_simple_ui_signup_input:SetCallback('onchange', function(widget)
		local value = widget:GetValue()
		if (value) and (string.len(value) >= 5) and (string.find(value, "@")) then
			main_simple_ui_signup_submit:SetEnabled(1)
		else
			main_simple_ui_signup_submit:SetEnabled(0)
		end
	end)

	main_simple_ui_signup_parent:SetVisible(true)	
	
	GetWidget('playerProfileReferAFriend_referral_link_parent'):SetCallback('onmouseover', function(widget)
		UpdateCursor(widget, true, { canLeftClick = true, canRightClick = false })
	end)
	GetWidget('playerProfileReferAFriend_referral_link_parent'):SetCallback('onmouseout', function(widget)
		UpdateCursor(widget, false, { canLeftClick = true, canRightClick = false })
	end)	
		
	function Profile.UpdateReferralCode(responseData)
		if (responseData) and (responseData.friendReferal) and (responseData.friendReferal.url) then
			local referralLink = responseData.friendReferal.url
			GetWidget('playerProfileReferAFriend_referral_link_label'):SetText(referralLink)
			GetWidget('playerProfileReferAFriend_referral_link_parent'):SetCallback('onclick', function(widget)
				widget:UICmd([[CopyToClipboard(']] .. referralLink .. [[')]])
				GetWidget('playerProfileReferAFriend_referral_link_reponse'):SetVisible(1)
				GetWidget('playerProfileReferAFriend_referral_link_reponse'):Sleep(2500, function(widget)
					widget:FadeOut(750)
				end)		
			end)				
		end	
	end
	
	-- === Strife App
	
	local deviceName = Translate('profile_strifeapp_devicename_dummy')
	local authenticationCode = Translate('profile_strifeapp_authcode_dummy')
	
	GetWidget('playerProfile_strifeapp_authcode_input'):SetCallback('onchange', function(widget)
		if (string.len(widget:GetValue()) > 0) then
			GetWidget('playerProfile_strifeapp_authcode_submit'):SetEnabled(1)
		else
			GetWidget('playerProfile_strifeapp_authcode_submit'):SetEnabled(0)
		end
	end)	
	
	GetWidget('playerProfile_strifeapp_authcode_submit'):SetCallback('onclick', function(widget)
		
		GetWidget('playerProfile_strifeapp_authcode_needcode'):SetVisible(0)	
		
		local deviceName = GetWidget('playerProfile_strifeapp_authcode_input'):GetValue()
		if Empty(deviceName) then
			deviceName = Translate('profile_strifeapp_devicename_dummy')
		end
		
		local successFunction = function(responseData)
			println('^g GetStrifeAppLinkCode successFunction')
			printr(responseData)
			if responseData.GetError then
				printr(responseData:GetError())
			end
			if (responseData.GetBody) and (responseData:GetBody().code) then
				GetWidget('playerProfile_strifeapp_authcode_hascode'):FadeIn(250)	
				
				local authenticationCode = responseData:GetBody().code
				GetWidget('playerProfile_strifeapp_authcode_label'):SetText(authenticationCode)

			else
				GetWidget('playerProfile_strifeapp_authcode_needcode'):FadeIn(250)
			end
		end
		local failFunction = function(responseData)
			GetWidget('playerProfile_strifeapp_authcode_needcode'):FadeIn(250)
			println('^r GetStrifeAppLinkCode failFunction')
			printr(responseData)
			if responseData.GetError then
				printr(responseData:GetError())
			end
			if (responseData.GetBody) then
				printr(responseData:GetBody())
			end
		end			
		
		Strife_Web_Requests:GetStrifeAppLinkCode(successFunction, failFunction, deviceName)		
	end)
	
	GetWidget('playerProfile_strifeapp_authcode_label'):SetText(authenticationCode)
	
	GetWidget('playerProfile_strifeapp_storelink_btn_apple'):SetCallback('onclick', function(widget)
		mainUI.OpenURL(Translate('profile_strifeapp_store_link_apple', 'lang', GetCvarString('host_language')))
	end)
	GetWidget('playerProfile_strifeapp_storelink_btn_apple'):SetCallback('onmouseover', function(widget)
		UpdateCursor(widget, true, { canLeftClick = true, canRightClick = false })
	end)
	GetWidget('playerProfile_strifeapp_storelink_btn_apple'):SetCallback('onmouseout', function(widget)
		UpdateCursor(widget, false, { canLeftClick = true, canRightClick = false })
	end)	
	
	GetWidget('playerProfile_strifeapp_storelink_btn_google'):SetCallback('onclick', function(widget)
		mainUI.OpenURL(Translate('profile_strifeapp_store_link_google', 'lang', GetCvarString('host_language')))
	end)
	GetWidget('playerProfile_strifeapp_storelink_btn_google'):SetCallback('onmouseover', function(widget)
		UpdateCursor(widget, true, { canLeftClick = true, canRightClick = false })
	end)
	GetWidget('playerProfile_strifeapp_storelink_btn_google'):SetCallback('onmouseout', function(widget)
		UpdateCursor(widget, false, { canLeftClick = true, canRightClick = false })
	end)	
	
	GetWidget('playerProfile_strifeapp_authcode_parent'):SetCallback('onshow', function(widget)
		GetWidget('playerProfile_strifeapp_authcode_needcode'):SetVisible(1)
		GetWidget('playerProfile_strifeapp_authcode_hascode'):SetVisible(0)
	end)
	
	local lastStarValue, starThread
	local function HeroProgressSelectedHero(heroEntity, heroInfo)
		
		if (heroEntity) and (not Empty(heroEntity)) and (ValidateEntity(heroEntity)) and (not Empty(GetEntityIconPath(heroEntity))) and (not Empty(GetEntityDisplayName(heroEntity))) then

			local animationDuration = styles_mainSwapAnimationDuration / 3
			local delay = 0

			heroInfo.wins = heroInfo.wins or 0
			heroInfo.winsToNextRank = heroInfo.winsToNextRank or 100001
			heroInfo['ranked_provMatchesRem'] = heroInfo['ranked_provMatchesRem'] or 5
			
			GetWidget('playerProfileHeroProgressEntry_prog_title'):SetText(Translate('player_profile_hero_mastery_progress', 'hero', GetEntityDisplayName(heroEntity)))
			GetWidget('playerProfileHeroProgressFrameMasteredHero'):SetTexture(GetEntityIconPath(heroEntity))

			if (heroInfo.questAwardMastered) then
				GetWidget('playerProfileHeroProgressFrameMasteredEarned'):SetVisible(1)
			else
				GetWidget('playerProfileHeroProgressFrameMasteredEarned'):SetVisible(0)
			end
			if (heroInfo.questAwardDivision1) then
				GetWidget('playerProfileHeroProgressFrameDivision5Earned'):SetVisible(1)
			else
				GetWidget('playerProfileHeroProgressFrameDivision5Earned'):SetVisible(0)
			end
			if (heroInfo.questAwardDivision2) then
				GetWidget('playerProfileHeroProgressFrameDivision4Earned'):SetVisible(1)
			else
				GetWidget('playerProfileHeroProgressFrameDivision4Earned'):SetVisible(0)
			end
			
			GetWidget('playerProfileHeroProgressEntry_prog_nometer'):SetVisible(0)
			
			-- if (mainUI) and (mainUI.progression) and (mainUI.progression.stats) and (mainUI.progression.stats.heroes) and (mainUI.progression.stats.heroes[heroEntity]) and (mainUI.progression.stats.heroes[heroEntity]['pvpRating0']) then
				-- if (mainUI.progression.stats.heroes[heroEntity]['standard_provMatchesRem']) and (mainUI.progression.stats.heroes[heroEntity]['standard_provMatchesRem'] > 0) then
					-- GetWidget('playerProfileHeroProgressEntry_rating_label_1'):SetText(Translate('ranked_division_provisional_wins', 'remaining', mainUI.progression.stats.heroes[heroEntity]['standard_provMatchesRem']))
				-- else
					-- GetWidget('playerProfileHeroProgressEntry_rating_label_1'):SetText(Translate('stat_name_hero_rating_x', 'value', mainUI.progression.stats.heroes[heroEntity]['pvpRating0'], 'hero', GetEntityDisplayName(heroEntity)))
				-- end
				-- GetWidget('playerProfileHeroProgressEntry_rating_parent_1'):SetVisible(1)
			-- else
				GetWidget('playerProfileHeroProgressEntry_rating_parent_1'):SetVisible(0)
			-- end			
			
			if (heroInfo.rank) then
				local rank 		= math.floor(heroInfo.rank)
				local remainder = heroInfo.rank % 1

				if (lastStarValue == (rank + remainder)) then
				
				else

					if (starThread) then
						starThread:kill()
						starThread = nil
					end

					starThread = libThread.threadFunc(function()

						for index = 5,1,-1 do
							GetWidget('playerProfileHeroProgressEntry_level_star_' .. index .. '_2'):ScaleWidth('100@', (animationDuration / 5))
							wait((animationDuration / 5))
						end

						wait((animationDuration / 2))

						for index = 1,5,1 do
							local starCalc = ((1- math.max(0, math.min(1, ((1 + rank - index) + remainder)))))
							GetWidget('playerProfileHeroProgressEntry_level_star_' .. index .. '_2'):ScaleWidth((starCalc * 100) .. '@', animationDuration)
							wait(animationDuration)
						end

						starThread = nil
					end)
					lastStarValue = (rank + remainder)
					if (rank < 5) then
						GetWidget('playerProfileHeroProgressEntry_level_bar'):ScaleWidth(math.max(0, (remainder * 100)) .. '%', animationDuration)
						GetWidget('playerProfileHeroProgressEntry_prog_meter'):SetVisible(1)
						GetWidget('playerProfileHeroProgressEntry_prog_nometer'):SetVisible(0)
					else
						GetWidget('playerProfileHeroProgressEntry_prog_meter'):SetVisible(0)
						GetWidget('playerProfileHeroProgressEntry_prog_nometer'):SetVisible(1)
					end

					GetWidget('playerProfileHeroProgressEntry_label_1'):SetText(Translate('stat_name_hero_wins_x', 'value', heroInfo.wins))
					if (heroInfo.winsToNextRank) and (heroInfo.winsToNextRank < 100000) then
						GetWidget('playerProfileHeroProgressEntry_label_2'):SetText(Translate('stat_name_hero_wins_next_star_x', 'value', heroInfo.winsToNextRank))
					else
						GetWidget('playerProfileHeroProgressEntry_label_2'):SetText(Translate('stat_name_hero_mastered'))
					end

					GetWidget('playerProfileHeroProgressEntry_prog_parent'):SetCallback('onclick', function(widget) end)
					GetWidget('playerProfileHeroProgressEntry_prog_parent'):SetCallback('onmouseover', function(widget)
						GetWidget('playerProfileHeroProgressEntry_prog_hover'):FadeIn(250)
					end)
					GetWidget('playerProfileHeroProgressEntry_prog_parent'):SetCallback('onmouseout', function(widget)
						GetWidget('playerProfileHeroProgressEntry_prog_hover'):FadeOut(250)
					end)
					GetWidget('playerProfileHeroProgressEntry_prog_parent'):RefreshCallbacks()				
					
					GetWidget('playerProfileHeroProgressFrameMastered'):FadeIn(250)	
				end
			else
				if (lastStarValue == (0)) then

				else
					if (starThread) then
						starThread:kill()
						starThread = nil
					end
					starThread = libThread.threadFunc(function()
						for index = 5,1,-1 do
							GetWidget('playerProfileHeroProgressEntry_level_star_' .. index .. '_2'):ScaleWidth('100@', (animationDuration / 3))
							wait((animationDuration / 3))
						end
						starThread = nil
					end)
					lastStarValue = 0
					GetWidget('playerProfileHeroProgressEntry_level_bar'):ScaleWidth(0, animationDuration)
					GetWidget('playerProfileHeroProgressEntry_label_1'):SetText('')
					GetWidget('playerProfileHeroProgressEntry_label_2'):SetText('')
					
					GetWidget('playerProfileHeroProgressEntry_prog_parent'):SetCallback('onclick', function(widget) end)
					GetWidget('playerProfileHeroProgressEntry_prog_parent'):SetCallback('onmouseover', function(widget) end)
					GetWidget('playerProfileHeroProgressEntry_prog_parent'):SetCallback('onmouseout', function(widget) end)
					GetWidget('playerProfileHeroProgressEntry_prog_parent'):RefreshCallbacks()				

					GetWidget('playerProfileHeroProgressFrameMastered'):FadeIn(250)					
				end
			end			
			
			local funzoneparent	= GetWidget('playerProfileHeroFunzone')
	
			if (mainUI) and (mainUI.progression) and (mainUI.progression.stats) and (mainUI.progression.stats.best) and (#mainUI.progression.stats.best > 0) then

				local statsToPullFrom
				if (mainUI.progression.stats.heroes) and (mainUI.progression.stats.heroes[heroEntity]) and (mainUI.progression.stats.heroes[heroEntity].details) then
					statsToPullFrom = {}
					for i,v in pairs(mainUI.progression.stats.heroes[heroEntity].details) do
						if (i == 'apm') or (i == 'creepDamage') or (i == 'heroDamage') or (i == 'kills') or (i == 'bossKills')  or (i == 'buildingDamage')  or (i == 'goldSpent')  or (i == 'creepKills')  or (i == 'goldEarned')  or (i == 'actions')  or (i == 'bossDamage')  or (i == 'assists')  or (i == 'games')  or (i == 'buildingKills')  or (i == 'killstreak')  or (i == 'winner')  or (i == 'deaths')  or (i == 'gpm') then
							table.insert(statsToPullFrom, {entity = heroEntity, value = v, stat = i})
						end
					end
				else
					statsToPullFrom = mainUI.progression.stats.best
				end
				
				local currentFact 	= math.random(1, #statsToPullFrom)
				local hero_model  	= GetWidget('playerProfileHeroFunzone_Model')
				local next_btn  	= GetWidget('playerProfileHeroFunzone_next_btn')
				local label_1  		= GetWidget('playerProfileHeroFunzone_label_1')
				local label_2  		= GetWidget('playerProfileHeroFunzone_label_2')
				local label_3  		= GetWidget('playerProfileHeroFunzone_next_btnLabel')

				local function ShowFunFact(entityName, stat, value)
					-- println('^y ShowFunFact ' .. entityName .. ' | ' .. stat .. ' | ' .. value)
					if (entityName) and ValidateEntity(entityName) and (GetEntityIconPath(entityName)) then
						if (stat ~= 'games') and (games) and (tonumber(games)) and (tonumber(games) > 0) then
							value = value / games
						end						
						if (stat == 'winner') then
							value = math.floor(100 * value) .. '%'
						else
							value = math.floor(value)
						end
						funzoneparent:FadeIn(250)
						hero_model:SetVisible(1)
						hero_model:SetModel(GetPreviewModel(entityName))
						hero_model:SetEffect(GetPreviewPassiveEffect(entityName))
						hero_model:SetModelOrientation(GetPreviewAngles(entityName))
						hero_model:SetModelPosition(GetPreviewPos(entityName))
						hero_model:SetModelScale(GetPreviewScale(entityName) * 0.8)
						hero_model:SetModelSkin(entityName) -- rmm get get and dye info
						if (entityName == 'Hero_Moxie') and GetCvarBool('_ui_catfacts') then
							label_1:SetText(Translate('profile_fun_fact_'..stat))
							label_2:SetText(Translate('profile_fun_fact_catfact') .. ' ' .. Translate('profile_fun_fact_'..stat..'_desc', 'value', value, 'hero', GetEntityDisplayName(entityName)))
							label_3:SetText(Translate('general_unsubscribe'))
						else
							label_1:SetText(Translate('profile_fun_fact_'..stat))
							label_2:SetText(Translate('profile_fun_fact_'..stat..'_desc', 'value', value, 'hero', GetEntityDisplayName(entityName)))
							label_3:SetText(Translate('player_profile_show_another'))
						end
					end
				end

				local factTable = statsToPullFrom[currentFact]
				ShowFunFact(factTable.entity, factTable.stat, factTable.value)

				next_btn:SetCallback('onclick', function()
					currentFact = currentFact + 1
					if (currentFact > #statsToPullFrom) then
						currentFact = 1
					end
					local factTable = statsToPullFrom[currentFact]
					ShowFunFact(factTable.entity, factTable.stat, factTable.value)
				end)

			else
				println('^r playerProfileHeroFunzone ')
				funzoneparent:FadeOut(250)
			end			
			
		end

	end
	
	local function playerProfileHeroMasteryEntryRegister(object, heroListbox, heroEntity, heroInfo)

		if heroEntity and (ValidateEntity(heroEntity)) then

			if (not loadedAtLeastOneHero) then 
				HeroProgressSelectedHero(heroEntity, heroInfo)		
				loadedAtLeastOneHero = true
			end
			
			heroListbox:AddTemplateListItem('playerProfileHeroProgressEntry', heroEntity, 'id', heroEntity, 'icon', GetEntityIconPath(heroEntity), 'heroName', GetEntityDisplayName(heroEntity))

			local button	= object:GetWidget('playerProfileHeroProgressEntry'..heroEntity)			
			local hoverGlow		= object:GetWidget('playerProfileHeroProgressEntry'..heroEntity..'hoverGlow')
			local icon		= object:GetWidget('playerProfileHeroProgressEntry'..heroEntity..'Icon')
			local frame		= object:GetWidget('playerProfileHeroProgressEntry'..heroEntity..'Frame')			
			local hoverInfo	= object:GetWidget('playerProfileHeroProgressEntry'..heroEntity..'Hover')
			local mastered	= object:GetWidget('playerProfileHeroProgressEntry'..heroEntity..'Mastered')
			local name		= object:GetWidget('playerProfileHeroProgressEntry'..heroEntity..'Name')
			local rankIcon	= object:GetWidget('playerProfileHeroProgressEntry'..heroEntity..'RankIcon')

			if heroInfo.rank and heroInfo.rank >= 5 then
				mastered:SetVisible(true)
			else
				mastered:SetVisible(false)
			end

			for i=1,5,1 do
				object:GetWidget('playerProfileHeroProgressEntry'..heroEntity..'Star_'..i):SetVisible(((heroInfo.rank) and (heroInfo.rank >= i)) or false)
			end	
			
			button:SetCallback('onclick', function(widget)
				groupfcall('playerProfileHeroProgressEntryFrames', function(_, groupWidget) 
					groupWidget:SetTexture('/ui/main/shared/textures/iconframe_interactive_txt2.tga')
				end)
				HeroProgressSelectedHero(heroEntity, heroInfo)
				frame:SetTexture('/ui/main/shared/textures/iconframe_interactive_txt2_selected.tga')
				hoverInfo:FadeOut(250)
				hoverGlow:FadeOut(250)
			end)			
			
			button:SetCallback('onmouseover', function(widget)
				if frame:GetTexture() ~= '/ui/main/shared/textures/iconframe_interactive_txt2_selected.tga' then
					hoverInfo:FadeIn(250)
					hoverGlow:FadeIn(250)
					
				end
			end)

			button:SetCallback('onmouseout', function(widget)
				hoverInfo:FadeOut(250)
				hoverGlow:FadeOut(250)
			end)
		
			if heroInfo.ranked_rank and heroInfo.ranked_division and (heroInfo.ranked_division ~= 'provisional') then
				rankIcon:SetVisible(1)
				rankIcon:SetTexture(libCompete.divisions[libCompete.divisionNumberByName[heroInfo.ranked_division]].icon)
			end

		end
	end

	object:GetWidget('playerProfileHeroProgressEntryListbox'):RegisterWatchLua('AccountProgression', function(widget, trigger)

		widget:ClearItems()
		loadedAtLeastOneHero = false
				
		if (mainUI.progression.stats.heroes) and type(mainUI.progression.stats.heroes) == 'table' then
			local tempTable = {}
			for heroEntity,heroInfo in pairs(mainUI.progression.stats.heroes) do
				table.insert(tempTable, {heroEntity = heroEntity, heroInfo = heroInfo})
			end
			if (tempTable) and type(tempTable) == 'table' and #tempTable > 0 then
				table.sort(tempTable, function(a,b) return string.lower(a.heroEntity) < string.lower(b.heroEntity) end)
				for index,heroTable in ipairs(tempTable) do
					playerProfileHeroMasteryEntryRegister(object, widget, heroTable.heroEntity, heroTable.heroInfo)
				end
			end
		end
	end)

	-- Ranked Division and Elo
	object:GetWidget('playerProfileRankInfo'):RegisterWatchLua('AccountProgression', function(widget, trigger)
	
		if (mainUI.progression) and (mainUI.progression.stats) and (mainUI.progression.stats.account) and (mainUI.progression.stats.account.division) and (mainUI.progression.stats.account.divisionIndex) and (mainUI.progression.stats.account.division ~= '') and (mainUI.progression.stats.account.pvpRating0) then
			GetWidget('playerProfileRankInfo'):FadeIn(125)
			
			local pveWins = tonumber(mainUI.progression.stats.account.pveWins) or 0
			local pvpWins = tonumber(mainUI.progression.stats.account.pvpWins) or 0
			
			for i=1,6,1 do
				if (i == mainUI.progression.stats.account.divisionIndex) then
					GetWidget('playerProfileDivision'..i):FadeIn(250)
				else
					GetWidget('playerProfileDivision'..i):SetVisible(0)
				end
			end
			
			GetWidget('playerProfileDivision'):SetText(Translate('ranked_division') .. ' ' .. Translate('ranked_division_' .. mainUI.progression.stats.account.division))
			GetWidget('playerProfileRating'):SetText(Translate('stat_name_pvp_rating_x', 'value', mainUI.progression.stats.account.pvpRating0))
			GetWidget('playerProfileWins'):SetText(Translate('stat_name_total_wins_x', 'value', pveWins + pvpWins))

		else
			GetWidget('playerProfileRankInfo'):FadeOut(125)
		end
	end)	
	
	-- Stats
	object:GetWidget('playerProfileStats_label_1'):RegisterWatchLua('AccountProgression', function(widget, trigger)
		if (mainUI) and (mainUI.progression) and (mainUI.progression.stats) and (mainUI.progression.stats.averageKillsAssists) then
			widget:SetText(math.floor(mainUI.progression.stats.averageKillsAssists))
		else
			widget:SetText('?')
		end
	end)

	object:GetWidget('playerProfileStats_label_2'):RegisterWatchLua('AccountProgression', function(widget, trigger)
		if (mainUI) and (mainUI.progression) and (mainUI.progression.stats) and (mainUI.progression.stats.averageGPM) then
			widget:SetText(math.floor(mainUI.progression.stats.averageGPM))
		else
			widget:SetText('?')
		end
	end)

	object:GetWidget('playerProfileStats_label_3'):RegisterWatchLua('AccountProgression', function(widget, trigger)
		if (mainUI) and (mainUI.progression) and (mainUI.progression.stats) and (mainUI.progression.stats.winPercentage) then
			widget:SetText(math.floor(mainUI.progression.stats.winPercentage * 100) .. '%')
		else
			widget:SetText('?')
		end
	end)

	object:GetWidget('playerProfileStats_label_4'):RegisterWatchLua('AccountProgression', function(widget, trigger)
		if (mainUI) and (mainUI.progression) and (mainUI.progression.stats) and (mainUI.progression.stats.averageDeaths) then
			widget:SetText(math.floor(mainUI.progression.stats.averageDeaths))
		else
			widget:SetText('?')
		end
	end)

	function Profile.OpenProfilePreview()
	
	end
	
	function Profile.CloseProfilePreview()
	
	end	
	
	profileInfo.viewingSelf			= true
	playerProfileAnimStatus.viewingSelf			= true
	playerProfileAnimStatus.section				= mainUI.savedLocally.profileSection1 or 'achievements'
	lastSelected                                = selectionMap[playerProfileAnimStatus.section]
	profileInfo:Trigger(true)
end

playerProfileRegister(object)
