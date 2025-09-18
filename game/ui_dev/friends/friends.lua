local interfaceName = object:GetName()
local interface = object

Friends = Friends or {}
Friends[interfaceName] = Friends[interfaceName] or {}
Friends[interfaceName].interactionLocked = false
Friends[interfaceName].updateQueued = false
Friends.playerSearchTerm = nil
Friends.searchResults = {}
Friends.autoCompleteResults = {}
Friends.labelTable = {}

ClientInfo = ClientInfo or {}
ClientInfo.duplicateUsernameTable = ClientInfo.duplicateUsernameTable or {}

mainUI = mainUI or {}
mainUI.savedLocally 	= mainUI.savedLocally 		or {}
mainUI.savedRemotely 	= mainUI.savedRemotely 		or {}
mainUI.savedAnonymously	= mainUI.savedAnonymously 	or {}
mainUI.savedRemotely.recentlyPlayedWith = mainUI.savedRemotely.recentlyPlayedWith or {}
mainUI.savedRemotely.friendDatabase = mainUI.savedRemotely.friendDatabase or {}
mainUI.savedRemotely.groupExpanded	= mainUI.savedRemotely.groupExpanded or {}
mainUI.savedRemotely.groupExpanded['recently'] = false
mainUI.savedRemotely.groupExpanded['ignored'] = false
mainUI.savedLocally.friendsSettings = mainUI.savedLocally.friendsSettings or {}

Windows = Windows or {}
Windows.state 			= Windows.state  		or {}
Windows.data 			= Windows.data  		or {}
Windows.data.drag 		= Windows.data.drag  	or {}

local playerTemplate = 'socialclient_friend_longmode_template' -- 'socialclient_friend_iconmode_template' 'socialclient_friend_longmode_template'
local playerTemplateWidth = '208s' -- '98s' '298s' '208s'
local playerTemplateHeight = '45s' -- '98s' '298s' '208s'
local headerTemplate = 'socialclient_im_header_row_template'
local headerTemplateWidth = '100%' 
local headerTemplateHeight = '28s'
local friendsWindowHeight = '684s'
local friendsWindowWidth = '284s'
local defFriendsLauncherX = '990s'
local defFriendsLauncherY = '60s'
local defFriendsWindowWidth = '284s'
local defFriendsWindowHeight = '684s'
local defFriendsWindowX = 0
local defFriendsWindowY = 0
local friendsWindowX = 0
local friendsWindowY = 0

local PartyStatus 				= LuaTrigger.GetTrigger('PartyStatus')
local partyCustomTrigger 		= LuaTrigger.GetTrigger('PartyTrigger')
local partyComboTrigger 		= LuaTrigger.GetTrigger('PartyComboStatus')
local mainPanelStatusDragInfo 	= LuaTrigger.GetTrigger('mainPanelStatusDragInfo')
local clientInfoDrag			= LuaTrigger.GetTrigger('clientInfoDrag')
local partyPlayerInfos 			= LuaTrigger.GetTrigger('PartyPlayerInfos') or libGeneral.createGroupTrigger('PartyPlayerInfos', {'PartyPlayerInfo0', 'PartyPlayerInfo1', 'PartyPlayerInfo2', 'PartyPlayerInfo3', 'PartyPlayerInfo4', 'PartyStatus.queue', 'PartyStatus.wins', 'PartyStatus.losses'})
local clientInfoDrag			= LuaTrigger.GetTrigger('clientInfoDrag')
local globalDragInfo			= LuaTrigger.GetTrigger('globalDragInfo')
local socialPanelInfo 			= LuaTrigger.GetTrigger('socialPanelInfo')
local MultiWindowDragInfo 		= LuaTrigger.GetTrigger('MultiWindowDragInfo')
local socialPanelInfoHovering 	= LuaTrigger.GetTrigger('socialPanelInfoHovering')

local function GetWidget(...)
	return interface:GetWidget(...)
end

local function GetContextMenuTrigger()
	if (interfaceName == 'friends') then
		ContextMenuMultiWindowTrigger.activeMultiWindowWindow = 'friends'
		return LuaTrigger.GetTrigger('ContextMenuMultiWindowTrigger'), 'ContextMenuMultiWindowTrigger'
	elseif (interfaceName == 'main') then
		return LuaTrigger.GetTrigger('ContextMenuTrigger'), 'ContextMenuTrigger'
	end
end

local function mouseInArea(x, y, width, height)
	if (interfaceName == 'friends') then
		local cursorPosX, cursorPosY = Windows.Friends:GetCursorPos()
		return (
			cursorPosX >= x and cursorPosX < (x + width) and
			cursorPosY >= y and cursorPosY < (y + height)
		)
	elseif (interfaceName == 'main') then
		local cursorPosX = Input.GetCursorPosX()
		local cursorPosY = Input.GetCursorPosY()

		return (
			cursorPosX >= x and cursorPosX < (x + width) and
			cursorPosY >= y and cursorPosY < (y + height)
		)		
	end
end

local function mouseInWidgetArea(areaWidget)	-- Allows for custom button functionality, various other interactive widgets (often for mouse L/R up, which needs to occur off the widget)
	return mouseInArea(
		areaWidget:GetAbsoluteX(),
		areaWidget:GetAbsoluteY(),
		areaWidget:GetWidth(),
		areaWidget:GetHeight()
	)
end

local function FriendsRegister(object)

	if (Windows.Friends) then
		Windows.Friends:Close()		
	end
	Windows.Friends = nil
	Windows.state.FriendsVisible = false

	local FriendStatusTriggerUI = LuaTrigger.GetTrigger('FriendStatusTriggerUI') or LuaTrigger.CreateCustomTrigger('FriendStatusTriggerUI', {
			{ name	=   'friendMultiWindowOpen',						type	= 'boolean'},	
			{ name	=   'friendLauncherWindowOpen',						type	= 'boolean'},	
			{ name	=   'friendLastUsedMethod',							type	= 'string'},	
		}
	)	

	local socialclient_im_friendlist 					= GetWidget('socialclient_im_friendlist')
	local socialclient_im_friendlist_scrollbar 			= GetWidget('socialclient_im_friendlist_scrollbar')	
	local socialclient_im_friendlist_parent 			= GetWidget('socialclient_im_friendlist_parent')	
	local social_client_sizingframe 					= GetWidget('social_client_sizingframe')	
	
	local rowIndex = 0
	local headerIndex = 0	
	
	local forceTheNextUpdate = false
	local queuedUpdateThread, attemptUpdateThread, queuedUpdateCount = nil, nil, 0
	Friends[interfaceName].QueueUpdate = function ()
		if (queuedUpdateThread) and (queuedUpdateThread:IsValid()) then
			queuedUpdateThread:kill()	
		end		
		queuedUpdateThread = nil
		queuedUpdateThread = libThread.threadFunc(function()
			queuedUpdateCount = queuedUpdateCount + 1
			if (queuedUpdateCount < 100) and (Friends[interfaceName].updateQueued) then
				wait(100)
				Friends[interfaceName].AttemptUpdate(false, nil)
			else
				Friends[interfaceName].AttemptUpdate(true, nil)
			end
			queuedUpdateThread = nil
		end)
	end
		
	Friends[interfaceName].IsInteractionLocked = function()
		if socialclient_im_friendlist and socialclient_im_friendlist:IsValid() and (socialclient_im_friendlist:IsVisible()) and (mouseInWidgetArea(socialclient_im_friendlist)) then
			Friends[interfaceName].interactionLocked = true
			return true
		else
			Friends[interfaceName].interactionLocked = false
			return false		
		end
	end	
	
	Friends[interfaceName].AttemptUpdate = function(forceUpdateInResponseToUserAction, postUpdateCallback)
		if (not forceTheNextUpdate) and ((not forceUpdateInResponseToUserAction) and Friends[interfaceName].IsInteractionLocked()) then
			Friends[interfaceName].updateQueued = true
			Friends[interfaceName].QueueUpdate()
		elseif (Friends[interfaceName].UpdateFriendsList) then
			if (attemptUpdateThread) and (attemptUpdateThread:IsValid()) then
				attemptUpdateThread:kill()
			end	
			attemptUpdateThread = nil					
			if (queuedUpdateThread) and (queuedUpdateThread:IsValid()) then
				queuedUpdateThread:kill()	
			end		
			queuedUpdateThread = nil				
			queuedUpdateCount = 0
			Friends[interfaceName].updateQueued = false
			attemptUpdateThread = libThread.threadFunc(function()
				wait(1)			
				Friends[interfaceName].UpdateFriendsList(postUpdateCallback)
				attemptUpdateThread = nil
			end)
		end
		forceTheNextUpdate = false
	end		
	
	local _, contextMenuTriggerName = GetContextMenuTrigger()
	
	socialclient_im_friendlist:RegisterWatchLua(contextMenuTriggerName, function(widget, trigger)
		if (trigger.contextMenuArea == -1) then
			forceTheNextUpdate = true
		end
	end, false, 'contextMenuArea')
	
	Friends[interfaceName].OpenFriendsList = function()
		if social_client_sizingframe then
			if (social_client_sizingframe:IsVisible()) then

			else
				PlaySound('/ui/sounds/social/sfx_pane_open.wav')		
				social_client_sizingframe:SetVisible(1)
			end
		end
	end		
	
	Friends[interfaceName].CloseFriendsList = function()
		if social_client_sizingframe then
			if (social_client_sizingframe:IsVisible()) then
				PlaySound('/ui/sounds/social/sfx_pane_close.wav')	
				social_client_sizingframe:SetVisible(0)
			else
			
			end
		end		
	end		

	Friends[interfaceName].ToggleFriendsList = function(forceOpen, forceClose, forceCloseIfLauncher)
		-- println("Friends[" .. interfaceName .. "].ToggleFriendsList")
		Windows.SilentlySpawnFriends()
		if (interfaceName == 'friends') then
			if ((FriendStatusTriggerUI.friendMultiWindowOpen) or (forceClose)) and (not forceOpen) and (not forceCloseIfLauncher) then
				FriendStatusTriggerUI.friendMultiWindowOpen = false				
			else
				FriendStatusTriggerUI.friendMultiWindowOpen = true
				FriendStatusTriggerUI.friendLastUsedMethod = 'window'
				mainUI 													= mainUI or {}
				mainUI.savedLocally 									= mainUI.savedLocally or {}
				mainUI.savedLocally.friendsSettings 					= mainUI.savedLocally.friendsSettings or {}						
				mainUI.savedLocally.friendsSettings.lastMethod = 'window' 
				SaveState()
			end
			FriendStatusTriggerUI:Trigger(true)
		elseif (interfaceName == 'main') then
			if ((FriendStatusTriggerUI.friendLauncherWindowOpen) or (forceClose) or (forceCloseIfLauncher)) and (not forceOpen) then
				FriendStatusTriggerUI.friendLauncherWindowOpen = false
			else
				FriendStatusTriggerUI.friendLauncherWindowOpen = true
				FriendStatusTriggerUI.friendLastUsedMethod = 'launcher'
				mainUI 													= mainUI or {}
				mainUI.savedLocally 									= mainUI.savedLocally or {}
				mainUI.savedLocally.friendsSettings 					= mainUI.savedLocally.friendsSettings or {}						
				mainUI.savedLocally.friendsSettings.lastMethod = 'launcher'
				SaveState()
			end
			FriendStatusTriggerUI:Trigger(true)		
		end
	end		
	
	Friends.ToggleFriendsList = function(forceOpen, forceClose)
	
		-- println('FriendStatusTriggerUI.friendLastUsedMethod: ' .. tostring(FriendStatusTriggerUI.friendLastUsedMethod))
		-- println('FriendStatusTriggerUI.friendMultiWindowOpen ' .. tostring(FriendStatusTriggerUI.friendMultiWindowOpen) )
		-- println('FriendStatusTriggerUI.friendLauncherWindowOpen ' .. tostring(FriendStatusTriggerUI.friendLauncherWindowOpen) )	
	
		if (FriendStatusTriggerUI.friendLastUsedMethod == 'launcher') and (Friends['main'].ToggleFriendsList) then
			Friends['main'].ToggleFriendsList(forceOpen, forceClose)
		elseif (FriendStatusTriggerUI.friendLastUsedMethod == 'window') and (Friends['friends'].ToggleFriendsList) then 
			Friends['friends'].ToggleFriendsList(forceOpen, forceClose)
		else
			println('Friends.ToggleFriendsList doesnt know what to do!')
			println('FriendStatusTriggerUI.friendLastUsedMethod: ' .. tostring(FriendStatusTriggerUI.friendLastUsedMethod))
			println('FriendStatusTriggerUI.friendMultiWindowOpen ' .. tostring(FriendStatusTriggerUI.friendMultiWindowOpen) )
			println('FriendStatusTriggerUI.friendLauncherWindowOpen ' .. tostring(FriendStatusTriggerUI.friendLauncherWindowOpen) )
		end
	end	
	
	Friends[interfaceName].Clicked = function (self, identID, cursorX, cursorY)
		-- println('Clicked identID ' .. tostring(identID) .. ' in ' .. interfaceName)
		
		if (Windows.Friends) and (interfaceName == 'friends') then
			
			local cursorX = cursorX or 0
			local cursorY = cursorY or 0
			local offsetX = cursorX - self:GetX()
			local offsetY = cursorY - self:GetY()		
			
			Windows.data.friendBeingDraggedIdentID = identID

			Windows.Friends:StartDragDrop(
				identID,
				"/ui_dev/friends/draggable_buddy.interface",
				interface:GetWidthFromString('264s'),
				interface:GetHeightFromString('40s'),
				offsetX,
				offsetY,
				function()
					-- println("DragDrop: Drop")
					MultiWindowDragInfo.active = false
					MultiWindowDragInfo.type = ''
					MultiWindowDragInfo:Trigger(true)						
				end,
				function()
					-- println("DragDrop: NoDrop")
					MultiWindowDragInfo.active = false
					MultiWindowDragInfo.type = ''
					MultiWindowDragInfo:Trigger(true)						
				end,
				function()
					-- println("DragDrop: Canceled")
					MultiWindowDragInfo.active = false
					MultiWindowDragInfo.type = ''
					MultiWindowDragInfo:Trigger(true)						
				end
			)
			
			local isOnline = ChatClient.IsOnline(identID)
			
			MultiWindowDragInfo.active = true
			if (isOnline) then
				MultiWindowDragInfo.type = 'player'
			else
				MultiWindowDragInfo.type = 'offlineplayer'
			end
			MultiWindowDragInfo:Trigger(true)
			
		elseif (interfaceName == 'main') then

			local cursorX = cursorX or 0
			local cursorY = cursorY or 0		
			local offsetX = cursorX - self:GetX()
			local offsetY = cursorY - self:GetY()		
			
			Windows.data.friendBeingDraggedIdentID = identID
			
			System.StartDragDrop(
				identID,
				"/ui_dev/friends/draggable_buddy.interface",
				interface:GetWidthFromString('264s'),
				interface:GetHeightFromString('40s'),
				offsetX,
				offsetY,
				function()
					-- println("DragDrop: Drop")
					MultiWindowDragInfo.active = false
					MultiWindowDragInfo.type = ''
					MultiWindowDragInfo:Trigger(true)						
				end,
				function()
					-- println("DragDrop: NoDrop")
					MultiWindowDragInfo.active = false
					MultiWindowDragInfo.type = ''
					MultiWindowDragInfo:Trigger(true)						
				end,
				function()
					-- println("DragDrop: Canceled")
					MultiWindowDragInfo.active = false
					MultiWindowDragInfo.type = ''
					MultiWindowDragInfo:Trigger(true)						
				end
			)
			
			MultiWindowDragInfo.active = true
			MultiWindowDragInfo.type = 'player'
			MultiWindowDragInfo:Trigger(true)	
		
		else

		end		

	end	
	
	Friends[interfaceName].DoubleClicked = function (self, identID)
		println('DoubleClicked identID ' .. tostring(identID))
		if (identID) then
			local friendsClientInfoTrigger = LuaTrigger.GetTrigger('ChatClientInfo' .. string.gsub(identID, '%.', ''))
			if (friendsClientInfoTrigger) then
				mainUI.chatManager.InitPrivateMessage(identID, -1, friendsClientInfoTrigger.name or '')
			end
		end		
	end	
	
	Friends[interfaceName].RightClicked = function (self, identID)
		-- println('RightClicked identID ' .. tostring(identID))
		local ContextMenuTrigger = GetContextMenuTrigger()
		if (identID) then
			local friendsClientInfoTrigger = LuaTrigger.GetTrigger('ChatClientInfo' .. string.gsub(identID, '%.', ''))
			if (friendsClientInfoTrigger) then
				ContextMenuTrigger.selectedUserIdentID 			= friendsClientInfoTrigger.identID
				ContextMenuTrigger.selectedUserUsername 		= friendsClientInfoTrigger.name
				-- ContextMenuTrigger.selectedUserIsInGame			= {inGame}
				-- ContextMenuTrigger.selectedUserIsInParty		= {inParty}
				-- ContextMenuTrigger.selectedUserIsInLobby		= {inLobby}
				-- ContextMenuTrigger.spectatableGame			= {spectatableGame}
				ContextMenuTrigger.contextMenuArea = 1
				ContextMenuTrigger:Trigger(true)
			else
				ContextMenuTrigger.selectedUserIdentID 			= identID
				ContextMenuTrigger.contextMenuArea = 1
				ContextMenuTrigger:Trigger(true)			
			end
		end
	end		

	local identCache = {}
	Friends[interfaceName].GetFriendDataFromIdentID = function (identID)
		if (identCache[identID]) then return (identCache[identID]) end
		for i,v in pairs(Friends.friendData) do
			if (v.identID == identID) then
				identCache[identID] = v
				return v
			end
		end
		return nil
	end

	local autoCompleteIdentCache = {}
	Friends[interfaceName].GetAutoCompleteDataFromIdentID = function (identID)
		if (autoCompleteIdentCache[identID]) then return (autoCompleteIdentCache[identID]) end
		for i,v in pairs(Friends.autoCompleteResults) do
			if (v.identID == identID) then
				autoCompleteIdentCache[identID] = v
				return v
			end
		end
		return nil
	end

	local uniqueIDCache = {}
	function Friends.GetFriendFromUniqueID(uniqueID)
		if (uniqueIDCache[uniqueID]) then return (uniqueIDCache[uniqueID]) end
		local toCheck = IsInTable(Friends.friendData, uniqueID, true)
		if toCheck and toCheck.identID == uniqueID then --IsInTable may have picked up an identID from in another persons name etc.
			uniqueIDCache[uniqueID] = toCheck
			return toCheck
		end
		return nil
	end

	
	Friends[interfaceName].OnStartDrag = function (self, identID)
		MultiWindowDragInfo.active = true
		MultiWindowDragInfo:Trigger(true)
	end
	
	Friends[interfaceName].OnEndDrag = function (self, identID)
		MultiWindowDragInfo.active = false
		MultiWindowDragInfo:Trigger(true)
	end

	Friends[interfaceName].RegisterDropTarget = function (self, index, displayGroup, draggedPlayerIdentID)

		local dropTarget = interface:GetWidget('socialclient_im_friendlist_droptarget_' .. index .. '_droptarget')
		
		dropTarget:SetCallback("ondragenter", function(widget, data, x, y)
			-- println("DragEnter: ", data, " ", x, " ", y)
		end)
		
		dropTarget:SetCallback("ondragover", function(widget, data, x, y)
			-- println("DragOver: ", data, " ", x, " ", y)
		end)
		
		dropTarget:SetCallback("ondragleave", function(widget, data)
			-- println("DragLeave: ", data)
		end)
		
		dropTarget:SetCallback("ondrop", function(widget, data, x, y)
			-- println("Drop: ", data, " ", x, " ", y)
			
			if (displayGroup == 'party') then
				forceTheNextUpdate = true
				local partyCustomTrigger = LuaTrigger.GetTrigger('PartyTrigger')
				ChatClient.PartyInvite(draggedPlayerIdentID)
				partyCustomTrigger.userRequestedParty = true
				partyCustomTrigger:Trigger(false)
				Friends[interfaceName].FriendListPulseFeedback(Translate('friends_friend_sent_party_invite'), '#00FF00')
			else
				if (displayGroup) and (string.len(displayGroup) >= 1) then
					if (displayGroup == 'remove') then
						forceTheNextUpdate = true
						ChatClient.SetFriendLabel(draggedPlayerIdentID, 'Default') 
					else
						forceTheNextUpdate = true
						ChatClient.SetFriendLabel(draggedPlayerIdentID, displayGroup)
					end
				end				
			end
			
		end)		
		
	end
	
	Friends[interfaceName].RegisterFriend = function (self, identID)

		if (self) and (self:IsValid()) then		 

			local function WatchAndUpdateFriendItem(self, identID)

				local friendsClientInfoTrigger = LuaTrigger.GetTrigger('ChatClientInfo' .. string.gsub(identID, '%.', ''))

				local lastRun = -1
				local function UpdateFriendItem(trigger)
					if (lastRun + 100 >= GetTime()) then return end -- Twice in 100 milliseconds, ignore it.
					lastRun = GetTime()
					--println("UpdateFriendItem " .. identID .. " " .. lastRun)

					local friendInfo = Friends[interfaceName].GetFriendDataFromIdentID(identID)
					
					if (friendInfo == nil) then
						println("^rError: no friendInfo for " .. tostring(identID))
					else

						local parentWidget					= GetWidget('socialclient_friend_longmode_template' .. identID)
						local bgWidget						= GetWidget('socialclient_friend_longmode_template' .. identID .. '_bg')
						local hoverWidget					= GetWidget('socialclient_friend_longmode_template' .. identID .. '_hover')
						local hoverOutlineWidget			= GetWidget('socialclient_friend_longmode_template' .. identID .. '_hoverOutline')
						local nameWidget 					= GetWidget('socialclient_friend_longmode_template' .. identID .. '_profile_name')
						local statusIconWidget 				= GetWidget('socialclient_friend_longmode_template' .. identID .. '_profile_status_icon')
						local statusGlowWidget 				= GetWidget('socialclient_friend_longmode_template' .. identID .. '_profile_status_icon_glow')
						local statusTextWidget 				= GetWidget('socialclient_friend_longmode_template' .. identID .. '_profile_status')
						local accountIconWidget 			= GetWidget('socialclient_friend_longmode_template' .. identID .. '_profile_id')
						local voipWidget 					= GetWidget('socialclient_friend_longmode_template' .. identID .. '_voip')
						local accountIconHoverWidget		= GetWidget('socialclient_friend_longmode_template' .. identID .. '_profile_id_hover')
						local groupNameWidget	 			= GetWidget('socialclient_friend_longmode_template' .. identID .. '_profile_groupname')

						local statusColor = '.3 .2 .2 .7'
						local statusText = Translate('friend_online_status_offline')
						local statusIcon = '$checker'
						local userIcon = '/ui/shared/textures/account_icons/default.tga'
						local userName = '???'
						local userNameColor = 'white'
						local secondaryLabel = '???'
						
						local isOnline = true
						
						if (friendInfo) and (friendInfo.isInMyParty) then
							voipWidget:SetVisible(friendInfo.isTalking)
						else
							voipWidget:SetVisible(false)
						end
						
						if (friendInfo) and (friendInfo.isInMyParty) and (friendInfo.isPending) then
							statusColor = '#FF9100' -- orange	
							statusText = Translate('friend_online_status_partypending')
						elseif (trigger) and (trigger.userStatus == 7) and ((friendInfo.acceptStatus == nil) or (friendInfo.acceptStatus == 'approved')) then 
							statusColor = '0.7 0.7 0.7 0.3' -- faded gray
							statusText = Translate('friend_online_status_offline')		
							isOnline = false
						elseif (trigger) and (trigger.userStatus == 3) and ((friendInfo.acceptStatus == nil) or (friendInfo.acceptStatus == 'approved')) then 
							statusColor = '#e82000' -- red
							statusText = Translate('friend_online_status_streaming')										
						elseif (trigger) and (trigger.userStatus == 5) and ((friendInfo.acceptStatus == nil) or (friendInfo.acceptStatus == 'approved')) then 
							statusColor = '#e82000' -- red
							statusText = Translate('friend_online_status_dnd')			
						elseif (trigger) and ((trigger.userStatus == 1)) and (trigger.status == 1) and ((friendInfo.acceptStatus == nil) or (friendInfo.acceptStatus == 'approved')) then
							statusColor = '#138dff' -- blue
							statusText = Translate('friend_online_status_lfg')
						elseif (trigger) and ((trigger.userStatus == 2)) and (trigger.status == 1) and ((friendInfo.acceptStatus == nil) or (friendInfo.acceptStatus == 'approved')) then
							statusColor = '#138dff' -- blue
							statusText = Translate('friend_online_status_lfm')
						elseif (trigger) and ((trigger.userStatus == 4)) and ((friendInfo.acceptStatus == nil) or (friendInfo.acceptStatus == 'approved')) then
							statusColor = '#FFFF00' -- yellow
							statusText = Translate('friend_online_status_afk')	
						elseif (trigger) and ((trigger.status == 2)) and ((friendInfo.acceptStatus == nil) or (friendInfo.acceptStatus == 'approved')) then
							statusColor = '#FFFF00' -- yellow
							statusText = Translate('friend_online_status_idle')										
						elseif (trigger) and (trigger.status == 6) and ((friendInfo.acceptStatus == nil) or (friendInfo.acceptStatus == 'approved')) then 
							statusColor = '#e82000' -- red
							statusText = Translate('friend_online_status_spectating')		 
						elseif (trigger) and (trigger.status == 5) and ((friendInfo.acceptStatus == nil) or (friendInfo.acceptStatus == 'approved')) then 
							statusColor = '#e82000' -- red
							statusText = Translate('friend_online_status_practice')
						elseif (trigger) and (trigger.status == 4) and ((friendInfo.acceptStatus == nil) or (friendInfo.acceptStatus == 'approved')) then 
							statusColor = '#e82000' -- red
							statusText = Translate('friend_online_status_ingame')			
						elseif (trigger) and ((trigger.status == 3) or (friendInfo.isInParty)) and ((friendInfo.acceptStatus == nil) or ((friendInfo.acceptStatus == nil) or (friendInfo.acceptStatus == 'approved'))) then
							statusColor = '#FF9100' -- orange	
							statusText = Translate('friend_online_status_inparty')
						elseif (friendInfo.isInLobby) and ((friendInfo.acceptStatus == nil) or (friendInfo.acceptStatus == 'approved')) then
							statusColor = '#FF9100' -- orange		
							statusText = Translate('friend_online_status_inlobby')						
						elseif (trigger) and (trigger.status == 1) and ((friendInfo.acceptStatus == nil) or (friendInfo.acceptStatus == 'approved')) then
							statusColor = '#b7ff00' -- green
							statusText = Translate('friend_online_status_online')
						elseif (trigger) and (trigger.status == 0) then
							statusColor = '.7 .7 .7 1' -- faded gray red
							statusText = Translate('friend_online_status_offline')
							isOnline = false
						else
							statusColor = '.7 .7 .7 1'
							statusText = Translate('friend_online_status_unknown')
							isOnline = false
						end								

						if (trigger) and (trigger.isStaff) and (friendInfo.icon) and ((friendInfo.icon == '/ui/shared/textures/account_icons/default.tga') or (friendInfo.icon == 'default')) then
							userIcon = '/ui/shared/textures/account_icons/s2staff.tga'
						elseif (friendInfo.icon == 'default') then
							userIcon = '/ui/shared/textures/account_icons/default.tga'
						else
							if friendInfo.icon and string.find(userIcon, '.tga') then
								userIcon = friendInfo.icon or '$invis'
							elseif friendInfo.icon and (not Empty(friendInfo.icon)) then
								userIcon = '/ui/shared/textures/account_icons/' .. friendInfo.icon.. '.tga'
							else
								userIcon = '/ui/shared/textures/account_icons/default.tga'
							end
						end
						
						if (friendInfo.name == nil) then
							println('^rError: This dude has no name')
							printr(friendInfo)
						end
						
						if (not friendInfo.isDuplicate) and (friendInfo.acceptStatus ~= 'pending') then
							userName = friendInfo.name or '?NONAME1?'
						else
							userName = (friendInfo.name  or '?NONAME2?') .. '.' .. (friendInfo.uniqueID  or '?NOUNIQUEID2?')
						end
						
						secondaryLabel = friendInfo.friendNote or friendInfo.uniqueID or ''
						
						if (friendInfo.clanName) and (friendInfo.clanName ~= '') and (string.len(friendInfo.clanName) <= 14) then
							secondaryLabel = secondaryLabel .. ' | ' .. friendInfo.clanName	
						elseif (friendInfo.clanTag and friendInfo.clanTag ~= '') then
							secondaryLabel = secondaryLabel .. ' | ' .. friendInfo.clanTag
						else
							secondaryLabel = secondaryLabel
						end						
						
						if (trigger) and (trigger.isStaff) then
							userNameColor = '#e82000'
						else
							userNameColor = '1 1 1 1'
						end						
						
						local function setColors ()
							if (isOnline) then
								statusIconWidget:SetTexture('/ui/main/shared/textures/user_status_light.tga')
								statusIconWidget:SetVisible(1)
								statusGlowWidget:SetVisible(1)
								bgWidget:SetColor(0.02, 0.07, 0.09, 0.98)
								bgWidget:SetBorderColor(0.02, 0.07, 0.09, 0.98)
								accountIconWidget:SetColor(1, 1, 1, 1)
								groupNameWidget:SetColor(1, 1, 1, 1)
								nameWidget:SetColor(userNameColor)
								statusIconWidget:SetColor(statusColor)
								statusGlowWidget:SetColor(statusColor)
								statusTextWidget:SetColor(statusColor)
							else
								statusIconWidget:SetTexture('/ui/main/shared/textures/user_status_offline.tga')
								statusIconWidget:SetVisible(1)
								statusGlowWidget:SetVisible(0)
								bgWidget:SetColor(0.02, 0.07, 0.09, 0.3)
								bgWidget:SetBorderColor(0.02, 0.07, 0.09, 0.3)
								nameWidget:SetColor(1, 1, 1, 0.3)
								accountIconWidget:SetColor(1, 1, 1, 0.3)
								groupNameWidget:SetColor(1, 1, 1, 0.3)
								statusIconWidget:SetColor(0.4, 0.4, 0.4, 1)
								statusGlowWidget:SetColor(0.4, 0.4, 0.4, 1)
								statusTextWidget:SetColor(0.4, 0.4, 0.4, 1)									
							end	
						end
						
						-- Update Widgets
						statusTextWidget:SetText(statusText)
						nameWidget:SetText(userName)
						groupNameWidget:SetText(secondaryLabel)
						accountIconWidget:SetTexture(userIcon)
						accountIconHoverWidget:SetTexture(userIcon)
						
						setColors()
						
						local contextTrigger, contextTriggerNameString = GetContextMenuTrigger()
						
						local function mouseOverUpdate()
							if (hoverWidget) and (hoverWidget:IsValid()) then
								hoverWidget:FadeIn(200)
								hoverOutlineWidget:FadeIn(200)
								bgWidget:SetColor(0.02, 0.07, 0.09, 0.98)
								bgWidget:SetBorderColor(0.02, 0.07, 0.09, 0.98)
								accountIconWidget:SetColor(1, 1, 1, 1)
								groupNameWidget:SetColor(1, 1, 1, 1)
								nameWidget:SetColor(userNameColor)
								if (not isOnline) then
									statusIconWidget:SetColor(0.7, 0.7, 0.7, 1)
									statusGlowWidget:SetColor(0.7, 0.7, 0.7, 1)
									statusTextWidget:SetColor(0.7, 0.7, 0.7, 1)	
								end
							end					
						end
						
						parentWidget:SetCallback('onmouseover', function(widget)
							if (contextTrigger.contextMenuArea <= 0) then
								mouseOverUpdate()
								UpdateCursor(widget, true, { canLeftClick = true, canRightClick = true, spendGems = false, canDrag = true })
							end
						end)	

						local function mouseOutUpdate()
							if (hoverWidget) and (hoverWidget:IsValid()) then
								hoverWidget:FadeOut(100)
								hoverOutlineWidget:FadeOut(100)
								setColors()
							end
						end
						
						parentWidget:SetCallback('onmouseout', function(widget)
							if (contextTrigger.contextMenuArea <= 0) then
								mouseOutUpdate()
							end
							UpdateCursor(widget, false, { canLeftClick = true, canRightClick = true, spendGems = false, canDrag = true })
						end)	
						
						if (contextTrigger) then
							parentWidget:UnregisterWatchLua(contextTriggerNameString)
							parentWidget:RegisterWatchLua(contextTriggerNameString, function(widget, trigger)
								if (trigger.selectedUserIdentID) and (not Empty(trigger.selectedUserIdentID)) and (trigger.contextMenuArea > 0) then
									if (identID == trigger.selectedUserIdentID) and ((trigger.contextMenuArea == 1) or (trigger.contextMenuArea == 2)) then
										libThread.threadFunc(function()
											wait(1)	
											mouseOverUpdate()
										end)
									else
										mouseOutUpdate()
									end
								else
									mouseOutUpdate()
								end
							end)
						end						
						
						local function AccountIconMouseOut()
							accountIconHoverWidget:ClearCallback('onframe')	
							ScaleInPlace(accountIconWidget,'100@', '100%', 150)
							setColors()		
							accountIconHoverWidget:SetNoClick(0)
							if mouseInWidgetArea(parentWidget) then
							
							else
								hoverWidget:FadeOut(100)
								hoverOutlineWidget:FadeOut(100)								
							end
						end
						
						accountIconHoverWidget:SetCallback('onmouseover', function(widget)
							-- println('accountIconHoverWidget onmouseover')
							if (contextTrigger.contextMenuArea <= 0) then
								ScaleInPlace(accountIconWidget, '160@', '160%', 150)
								hoverWidget:FadeIn(200)
								hoverOutlineWidget:FadeIn(200)
								bgWidget:SetColor(0.02, 0.07, 0.09, 0.98)
								bgWidget:SetBorderColor(0.02, 0.07, 0.09, 0.98)
								accountIconWidget:SetColor(1, 1, 1, 1)
								groupNameWidget:SetColor(1, 1, 1, 1)
								nameWidget:SetColor(userNameColor)
								accountIconHoverWidget:SetNoClick(1)
								accountIconHoverWidget:ClearCallback('onframe')
								accountIconHoverWidget:SetCallback('onframe', function(widget)
									if mouseInWidgetArea(accountIconHoverWidget) then
									else
										AccountIconMouseOut()
									end
								end)
								UpdateCursor(widget, true, { canLeftClick = true, canRightClick = true, spendGems = false, canDrag = true })
							end
						end)	
						
						accountIconHoverWidget:SetCallback('onhide', function(widget)
							AccountIconMouseOut()
						end)

						parentWidget:SetCallback('ondoubleclick', function(widget) -- This requires using a button RMM
							println('ondoubleclick ' .. tostring(identID))
							Friends[interfaceName].DoubleClicked(widget, identID)
						end)
						
						parentWidget:SetCallback('onrightclick', function(widget)
							println('onrightclick ' .. tostring(identID))
							Friends[interfaceName].RightClicked(widget, identID)
						end)		
						
						parentWidget:SetCallback('onstartdrag', function(widget, x, y)
							println('onstartdrag ' .. tostring(identID))
							Friends[interfaceName].Clicked(widget, identID, x, y)
							-- Friends[interfaceName].OnStartDrag(widget, identID, x, y)
						end)		
						
						parentWidget:SetCallback('onenddrag', function(widget, x, y)
							println('onenddrag ' .. tostring(identID))
							-- Friends[interfaceName].OnEndDrag(widget, identID, x, y)
							-- widget:BreakDrag()
						end)						
						
					end
				end
				if (friendsClientInfoTrigger) then
					self:UnregisterWatchLua('ChatClientInfo' .. string.gsub(identID, '%.', ''))
					self:RegisterWatchLua('ChatClientInfo' .. string.gsub(identID, '%.', ''), function(widget, trigger)
						UpdateFriendItem(trigger)
					end, false, nil, 'userStatus', 'status', 'isStaff')
				end
				UpdateFriendItem(friendsClientInfoTrigger)						
			end

			WatchAndUpdateFriendItem(self, identID) 

		end

		-- RMM Add more updates here
		
		-- widgets.dropTarget:UnregisterWatchLua('mainPanelStatusDragInfo')
		-- widgets.dropTarget:RegisterWatchLua('mainPanelStatusDragInfo', function(widget, groupTrigger)
			-- local mainPanelStatus = groupTrigger[1]
			-- local globalDragInfo  = groupTrigger[2]
			-- local clientInfoDrag  = groupTrigger[3]				
			-- widget:SetVisible(globalDragInfo.active and ((globalDragInfo.type == 4) or (globalDragInfo.type == 5) or (globalDragInfo.type == 20) or (globalDragInfo.type == 21)) )
		-- end)					
		
		-- widgets.dropTarget:SetCallback('onmouseover', function(widget)
			-- globalDraggerReadTarget(widget, function()
				-- Links.SpawnLink(data.identID, 'pm', data.name)
			-- end)
			-- Friends.FriendsListCheckLock()
		-- end)	

		-- widgets.userDarken:UnregisterWatchLua('clientInfoDrag')
		-- widgets.userDarken:RegisterWatchLua('clientInfoDrag', function(widget, trigger)
			-- widget:SetVisible(trigger.dragActive and trigger.clientDraggingName == data.name and trigger.clientDraggingUniqueID == data.uniqueID)
		-- end, false, nil, 'clientDraggingName', 'clientDraggingUniqueID', 'dragActive')
		
		-- widgets.userDarken:UnregisterWatchLua('clientInfoDrag')
		-- widgets.userDarken:RegisterWatchLua('clientInfoDrag', function(widget, trigger)
			-- widget:SetVisible(trigger.dragActive and trigger.clientDraggingName == data.name and trigger.clientDraggingUniqueID == data.uniqueID)
		-- end, false, nil, 'clientDraggingName', 'clientDraggingUniqueID', 'dragActive')				
		
		-- widgets.userButton:SetCallback('onstartdrag', function(widget)
			-- clientInfoDrag.clientDraggingName			= data.name
			-- clientInfoDrag.clientDraggingUniqueID		= data.uniqueID
			-- clientInfoDrag.clientDraggingIdentID		= data.identID
			-- clientInfoDrag.clientDraggingCanSpectate	= data.isInGame or false
			-- clientInfoDrag.clientDraggingIsFriend		= data.isFriend or false
			-- clientInfoDrag.clientDraggingIsOnline		= data.isOnline or false
			-- clientInfoDrag.clientDraggingIsInGame		= data.isInGame or false
			-- clientInfoDrag.clientDraggingIsInParty		= data.isInParty or false
			-- clientInfoDrag.joinableGame					= (data.joinableGame or false)
			-- clientInfoDrag.joinableParty				= (data.joinableParty or false)					
			-- clientInfoDrag.spectatableGame				= (data.spectatableGame or false)
			-- clientInfoDrag.dragActive					= true
			-- clientInfoDrag:Trigger(false)
		-- end)
		
		-- widgets.userButton:SetCallback('onenddrag', function(widget)
			-- clientInfoDrag.dragActive			= false
			-- clientInfoDrag:Trigger(false)
		-- end)						
		
		-- widgets.userButton:SetCallback('ondoubleclick', function(widget)
			-- mainUI.chatManager.InitPrivateMessage(data.identID, ContextMenuTrigger.contextMenuArea, data.name)
		-- end)				
		
		-- globalDraggerRegisterSource(widgets.userButton, 12)						

	end	

	Friends[interfaceName].ToggleGroupExpanded = function(displayGroup, postUpdateCallback)
		mainUI.savedRemotely.groupExpanded = mainUI.savedRemotely.groupExpanded or {}
		mainUI.savedRemotely.groupExpanded[displayGroup] = not mainUI.savedRemotely.groupExpanded[displayGroup]
		Friends[interfaceName].AttemptUpdate(true, postUpdateCallback)
	end	
	
	Friends[interfaceName].HeaderClicked = function (self, index, displayGroup)
		-- println('Clicked displayGroup ' .. tostring(displayGroup))
		local function postUpdateCallback()
			if (index) then
				local arrow = GetWidget('socialclient_im_header_row_template' .. index .. '_arrow')
				if (arrow) and (arrow:IsValid()) then
					if (mainUI.savedRemotely) and (mainUI.savedRemotely.groupExpanded) and (mainUI.savedRemotely.groupExpanded[displayGroup]) then
						arrow:SetRotation(-180, 150)
						arrow:Rotate(0, 150)
					else
						arrow:SetRotation(0, 150)
						arrow:Rotate(-180, 150)
					end	
				end
			end
		end		
		Friends[interfaceName].ToggleGroupExpanded(displayGroup, postUpdateCallback)	
	end

	Friends[interfaceName].HeaderOnMouseOver = function (self, index, displayGroup)
		-- println('HeaderOnMouseOver displayGroup ' .. tostring(displayGroup))
	end	
	
	Friends[interfaceName].HeaderOnMouseOut = function (self, index, displayGroup)
		-- println('HeaderOnMouseOut displayGroup ' .. tostring(displayGroup))
	end	
	
	Friends[interfaceName].RegisterHeader = function (self, index, displayGroup)
		
		libThread.threadFunc(function()
			wait(1)		
			
			if (self) and (self:IsValid()) then
			
				local parent 			= GetWidget('socialclient_im_header_row_template' .. index)
				local arrow 			= GetWidget('socialclient_im_header_row_template' .. index .. '_arrow')
				local label 			= GetWidget('socialclient_im_header_row_template' .. index .. '_label')
				local countLabel 		= GetWidget('socialclient_im_header_row_template' .. index .. '_count_label')
				
				-- RMM header callbacks
				
				-- widgets.headerExpandButton:SetCallback('onclick', function(widget)
					-- Friends.ToggleGroupExpanded(data.name)
				-- end)
				-- widgets.headerExpandButton:SetCallback('onmouseover', function(widget)
					-- UpdateCursor(widget, true, { canLeftClick = true, canRightClick = false, canDrag = false })
					-- socialPanelInfoHovering.friendHoveringWidgetIndex 	=	-1
					-- socialPanelInfoHovering:Trigger(false)
					-- Friends.FriendsListCheckLock()
				-- end)	
				-- widgets.headerExpandButton:SetCallback('onmouseout', function(widget)
					-- UpdateCursor(widget, false, { canLeftClick = true, canRightClick = false, canDrag = false })
					-- if (widget:IsVisible()) then
						-- socialPanelInfoHovering.friendHoveringWidgetIndex 	=	-1
						-- socialPanelInfoHovering:Trigger(false)
					-- end		
					-- Friends.FriendsListCheckLock()
				-- end)					

				self:SetCallback('onclick', function(widget, trigger)
					-- println('onclick ' .. tostring(displayGroup))
					Friends[interfaceName].HeaderClicked(widget, index, displayGroup)
				end)	
				self:SetCallback('ondoubleclick', function(widget, trigger)
					-- println('ondoubleclick ' .. tostring(displayGroup))
					Friends[interfaceName].HeaderClicked(widget, index, displayGroup)
				end)
				self:SetCallback('onrightclick', function(widget, trigger)
					-- println('onrightclick ' .. tostring(displayGroup))
					Friends[interfaceName].HeaderClicked(widget, index, displayGroup)
				end)		
				self:SetCallback('onmouseover', function(widget, trigger)
					-- println('onmouseover ' .. tostring(displayGroup))
					Friends[interfaceName].HeaderOnMouseOver(widget, index, displayGroup)
					UpdateCursor(widget, true, { canLeftClick = true, canRightClick = true, spendGems = false })
				end)	
				self:SetCallback('onmouseout', function(widget, trigger)
					-- println('onmouseout ' .. tostring(displayGroup))
					Friends[interfaceName].HeaderOnMouseOut(widget, index, displayGroup)
					UpdateCursor(widget, false, { canLeftClick = true, canRightClick = true, spendGems = false })
				end)	
			end
		end)
		
	end

	local function FriendsUpdateRegister(object)
		
		 Friends[interfaceName].UpdateFriendsList = function(postUpdateCallback)
				
			if (not socialclient_im_friendlist) or (not socialclient_im_friendlist:IsValid()) then
				return
			end
				
			socialclient_im_friendlist:ClearChildren()

			local sortableTable = {}
			Friends.searchResults = {}
			mainUI.savedRemotely = mainUI.savedRemotely or {}
			mainUI.savedRemotely.groupExpanded = mainUI.savedRemotely.groupExpanded or {}
			Friends.labelTable = {}
			mainUI.news = mainUI.news or {}
			mainUI.news.data = mainUI.news.data or {}			
			mainUI.news.data.friendsReadyToPlay = {}
			mainUI.news.data.friendsOnline = {}			
			mainUI.watch.friendsICanSpectate = {}
			
			-- Reset flags
			for i,friendInfo in pairs(Friends.friendData) do
				friendInfo.hiddenViaSearch = false
				friendInfo.hiddenByParty = false
				friendInfo.isInMyParty = false
			end
			
			-- Insert Party Group, hide any entries for this player in other groups
			local playersInParty = 0
			if (Party) and (Party.partyInfos) then
				for i,v in pairs(Party.partyInfos) do
					local friendInfo = v
					if (v) and (v.name) and (not Empty(v.name)) and (v.identID) and (not Empty(v.identID)) and (v.uniqueID) and (not Empty(v.uniqueID)) then	
						playersInParty = playersInParty + 1
					end
				end
				if (playersInParty) and ((playersInParty > 1) or (partyCustomTrigger.userRequestedParty)) or (((MultiWindowDragInfo.active) and (MultiWindowDragInfo.type == 'player')) and ((not PartyStatus.inParty) or (PartyStatus.isPartyLeader))) then 
					sortableTable['party'] = {}
					if (playersInParty) and ((playersInParty > 1) or (partyCustomTrigger.userRequestedParty)) then
						for i,v in pairs(Party.partyInfos) do
							local friendInfo = v
							if (v) and (v.name) and (not Empty(v.name)) and (v.identID) and (not Empty(v.identID)) and (v.uniqueID) and (not Empty(v.uniqueID)) then
								friendInfo.isInMyParty = true
								table.insert(sortableTable['party'], friendInfo)
								if (Friends) and (Friends.friendData) and (Friends.friendData[v.name .. v.uniqueID]) then
									Friends.friendData[v.name .. v.uniqueID].isInMyParty = true
									Friends.friendData[v.name .. v.uniqueID].hiddenByParty = true
								end
							end
						end
					elseif (((MultiWindowDragInfo.active) and (MultiWindowDragInfo.type == 'player'))) and ((not PartyStatus.inParty) or (PartyStatus.isPartyLeader)) and (playersInParty < 5) then
						local friendInfo = Friends[interfaceName].GetFriendDataFromIdentID(GetIdentID())
						if (Windows.data.friendBeingDraggedIdentID) and (not IsMe(Windows.data.friendBeingDraggedIdentID)) and (friendInfo) and (Friends) and (Friends.friendData) then
							friendInfo.isInMyParty = true
							if Friends.friendData[friendInfo.name .. friendInfo.uniqueID] then
								Friends.friendData[friendInfo.name .. friendInfo.uniqueID].isInMyParty = true
								Friends.friendData[friendInfo.name .. friendInfo.uniqueID].hiddenByParty = true
							end
							table.insert(sortableTable['party'], friendInfo)
						else
							table.insert(sortableTable['party'], 'drag_target_only')
						end					
					end
				end
			end			
			
			sortableTable['autocomplete'] = {}
			local countPending = 0
			for i,friendInfo in pairs(Friends.friendData) do
				
				local displayThisFriend = true
				local name = friendInfo.trueName or friendInfo.name
				if (mainUI.savedRemotely) and (mainUI.savedRemotely.friendDatabase) and (mainUI.savedRemotely.friendDatabase[friendInfo.identID]) then
					if (mainUI.savedRemotely.friendDatabase[friendInfo.identID].nicknameOverride) and (not Empty(mainUI.savedRemotely.friendDatabase[friendInfo.identID].nicknameOverride)) then
						friendInfo.name = mainUI.savedRemotely.friendDatabase[friendInfo.identID].nicknameOverride or friendInfo.name or '???'
					end
					if (mainUI.savedRemotely.friendDatabase[friendInfo.identID].friendNote) and (not Empty(mainUI.savedRemotely.friendDatabase[friendInfo.identID].friendNote)) then
						friendInfo.friendNote = mainUI.savedRemotely.friendDatabase[friendInfo.identID].friendNote or friendInfo.friendNote or nil
					end
				end
				
				-- Duplicate usernames, we don't need this until we use the group slot later, at which point this should be appended to the name
				-- if (ClientInfo.duplicateUsernameTable[friendInfo.name]) then
					-- if (not IsInTable(ClientInfo.duplicateUsernameTable[friendInfo.name], friendInfo.uniqueID)) then
						-- tinsert(ClientInfo.duplicateUsernameTable[friendInfo.name], friendInfo.uniqueID)
					-- end
				-- else
					-- ClientInfo.duplicateUsernameTable[friendInfo.name] = {friendInfo.uniqueID}
				-- end				

				local displayGroup = 'online'
				if (friendInfo.acceptStatus == 'pending') then
					displayGroup = 'pending'
					countPending = countPending + 1
				elseif (friendInfo.buddyLabel == 'ignored') or (friendInfo.ignored) then
					displayGroup = 'ignored'
				elseif (friendInfo.buddyLabel == Translate('main_social_groupname_autocomplete')) or (friendInfo.buddyLabel == Translate('autocomplete')) then
					displayGroup = 'autocomplete'	
					displayThisFriend = false
				elseif (friendInfo.buddyLabel == Translate('main_social_groupname_recently')) or (friendInfo.buddyLabel == Translate('recently')) then
					displayGroup = 'recently'
					displayThisFriend = false			
				elseif (friendInfo.acceptStatus ~= 'sent') and ((not friendInfo.isFriend) and (not ((Friends.playerSearchTerm) and (not Empty(Friends.playerSearchTerm))))) then
					displayGroup = 'exfriends'				
					displayThisFriend = false						
				elseif (friendInfo.buddyLabel == 'offline') or (friendInfo.buddyLabel == 'online') or (friendInfo.buddyLabel == 'search') or (friendInfo.buddyLabel == 'autocomplete') or (friendInfo.buddyLabel == 'pending') then
					displayGroup = friendInfo.buddyLabel
				elseif (friendInfo.buddyLabel == 'sent') or (friendInfo.buddyLabel == 'rejected') or (not friendInfo.isOnline) or ((friendInfo.status) and (friendInfo.status == 0)) or ((friendInfo.userStatus) and (friendInfo.userStatus == 7)) then
					displayGroup = 'offline'					
				elseif (friendInfo.buddyLabel == "Friends") or (friendInfo.buddyLabel == "Default") then
					displayGroup = 'online'
				else
					displayGroup = friendInfo.buddyLabel
				end			
				
				-- Steal stuff for Watch
				mainUI.watch = mainUI.watch or {}
				mainUI.watch.friendsICanSpectate = mainUI.watch.friendsICanSpectate or {}
				if (friendInfo) and (friendInfo.identID) and (friendInfo.spectatableGame) then
					table.insert(mainUI.watch.friendsICanSpectate, friendInfo)
				end			
				
				-- Steal stuff for News
				mainUI.news = mainUI.news or {}
				mainUI.news.data = mainUI.news.data or {}
				mainUI.news.data.friendsReadyToPlay = mainUI.news.data.friendsReadyToPlay or {}
				mainUI.news.data.friendsOnline = mainUI.news.data.friendsOnline or {}
				if (friendInfo) and (friendInfo.identID) and (displayThisFriend) and (displayGroup ~= 'offline') then
					if ((friendInfo.userStatus == 1) or (friendInfo.userStatus == 2)) and (friendInfo.status == 1) and ((friendInfo.acceptStatus == nil) or (friendInfo.acceptStatus == 'approved')) then	
						table.insert(mainUI.news.data.friendsReadyToPlay, friendInfo)
					else
						table.insert(mainUI.news.data.friendsOnline, friendInfo)			
					end
				end	
				
				-- Search
				local hiddenViaSearch = false
				if (Friends.playerSearchTerm) and (not Empty(Friends.playerSearchTerm)) then
					hiddenViaSearch = true
					if ((friendInfo.name) and string.find(string.lower(friendInfo.name), string.lower(Friends.playerSearchTerm), 1, true)) or ((friendInfo.trueName) and string.find(string.lower(friendInfo.trueName), string.lower(Friends.playerSearchTerm), 1, true)) then
						hiddenViaSearch = false
						table.insert(Friends.searchResults, friendInfo)
						if (friendInfo.buddyGroup == 'autocomplete') then
							table.insert(sortableTable['autocomplete'], friendInfo)	
						end
					end
				end
				friendInfo.hiddenViaSearch = hiddenViaSearch
				
				if (not hiddenViaSearch) and (not friendInfo.hiddenByParty) and (displayThisFriend) then
					sortableTable[displayGroup] = sortableTable[displayGroup] or {}
					table.insert(sortableTable[displayGroup], friendInfo)
				end
			end
			
			-- Add results from chat server and web autocompletions
			if (Friends.autoCompleteResults) and (Friends.playerSearchTerm) and (not Empty(Friends.playerSearchTerm)) then
				for i,v in pairs(Friends.autoCompleteResults) do
					local name 				= v[1]
					local uniqueID 			= v[2]
					local identID 			= v[3]
					local fromChatServer 	= v[4]
					if (name) and (not Empty(name)) then
						local friendInfo = {}
						friendInfo.name = name
						friendInfo.trueName = name
						friendInfo.uniqueID = uniqueID
						friendInfo.identID = identID
						friendInfo.isOnline = fromChatServer
						friendInfo.buddyLabel = 'autocomplete'
						friendInfo.buddyGroup = 'autocomplete'
						friendInfo.icon = '/ui/shared/textures/account_icons/default.tga'
						friendInfo.userStatus = 0
						friendInfo.status = 0					
						
						table.insert(sortableTable['autocomplete'], friendInfo)					
						
						Friends.friendData 										= Friends.friendData or {}
						Friends.friendData[name..uniqueID] 						= Friends.friendData[name..uniqueID] or friendInfo or {}			
						Friends.friendData[name..uniqueID].name = name
						Friends.friendData[name..uniqueID].uniqueID = uniqueID
						Friends.friendData[name..uniqueID].identID = identID
						Friends.friendData[name..uniqueID].isOnline = fromChatServer
						Friends.friendData[name..uniqueID].isInGame = false
						Friends.friendData[name..uniqueID].buddyLabel = 'autocomplete'
						Friends.friendData[name..uniqueID].buddyGroup = 'autocomplete'
						Friends.friendData[name..uniqueID].icon = '/ui/shared/textures/account_icons/default.tga'
						Friends.friendData[name..uniqueID].userStatus = 0
						Friends.friendData[name..uniqueID].status = 0
					end
						
				end
			end
			
			-- Add recently played with players that are not already friends
			if (mainUI.savedRemotely.recentlyPlayedWith) then
				RemoveFriendsFromRecentlyPlayed()
				local recentPlayer = false
				for _,_ in pairs(mainUI.savedRemotely.recentlyPlayedWith) do
					recentPlayer = true 
					break
				end
				if (recentPlayer) then
					sortableTable['recently'] = {}
					--printr(mainUI.savedRemotely.recentlyPlayedWith)
					for k,v in pairs(mainUI.savedRemotely.recentlyPlayedWith) do
						local name 				= v.name
						local uniqueID 			= v.uniqueID
						local identID 			= v.identID
						local icon 				= v.icon
						local buddyGroup 		= v.buddyGroup
						if (name) and (not Empty(name)) then
							local friendInfo = {}
							friendInfo.name = name
							friendInfo.trueName = name
							friendInfo.uniqueID = uniqueID
							friendInfo.identID = identID
							friendInfo.isOnline = false
							friendInfo.isInGame = false
							friendInfo.buddyLabel = 'recently'
							friendInfo.buddyGroup = buddyGroup or 'recently'
							friendInfo.icon = icon or '/ui/shared/textures/account_icons/default.tga'
							friendInfo.userStatus = 0
							friendInfo.status = 0
							
							table.insert(sortableTable['recently'], friendInfo)		
				
							Friends.friendData 										= Friends.friendData or {}
							Friends.friendData[name..uniqueID] 						= Friends.friendData[name..uniqueID] or friendInfo or {}			
							Friends.friendData[name..uniqueID].name = name
							Friends.friendData[name..uniqueID].uniqueID = uniqueID
							Friends.friendData[name..uniqueID].identID = identID
							Friends.friendData[name..uniqueID].isOnline = false
							Friends.friendData[name..uniqueID].isInGame = false
							Friends.friendData[name..uniqueID].buddyLabel = 'recently'
							Friends.friendData[name..uniqueID].buddyGroup = buddyGroup or 'recently'
							Friends.friendData[name..uniqueID].icon = icon or '/ui/shared/textures/account_icons/default.tga'
							Friends.friendData[name..uniqueID].userStatus = 0
							Friends.friendData[name..uniqueID].status = 0
						end
					end
				else
					mainUI.savedRemotely.groupExpanded['recently'] = false
				end
			else
				mainUI.savedRemotely.groupExpanded['recently'] = false
			end				
			
			-- Sort groups and count players
			local totalPlayerCount = 0
			for _, groupTable in pairs(sortableTable) do
				table.sort(groupTable, function(a,b) 
					if (a.name) and (b.name) then
						return string.lower(a.name) < string.lower(b.name) 
					elseif (a.name) then
						return true
					else
						return false
					end
				end)
				if (#groupTable > 0) then
					totalPlayerCount = totalPlayerCount + #groupTable
				end
			end				
			
			local rowGroups = interface:GetGroup('socialclient_im_friendlist_row_group')
			if (rowGroups) and (#rowGroups > 0) then
				for _,v in pairs(rowGroups) do
					v:SetVisible(0)
					v:Destroy()
				end
			end
			
			local FRIEND_ITEM_WIDTH = socialclient_im_friendlist:GetWidthFromString(playerTemplateWidth)
			rowIndex = 0
			headerIndex = 0
			local spawnedHeaders = {}
			local spawnedRows = {}
			
			local countOnline = 0
			
			local function SpawnFriendsUsingGroupTable(groupTable, displayGroup, onlineGroup)

				local function InstantiatePlayerEntry(rowWidget, interfaceName, friendInfo)
					
					if (onlineGroup) and (friendInfo) and (friendInfo.identID) and (not IsMe(friendInfo.identID)) then
						countOnline = countOnline + 1
					end
					 
					if (not friendInfo.icon) or (not friendInfo.name) or --[[(not friendInfo.buddyGroup) or]] (not friendInfo.identID) or (not friendInfo.uniqueID) then
						println('^r InstantiatePlayerEntry missing data')
						printr(friendInfo)
					elseif (not interface:GetWidget(playerTemplate..friendInfo.identID)) then
						local statusText = friendInfo.buddyLabel or friendInfo.buddyGroup or ''
						
						local insertedWidgets = rowWidget:InstantiateAndReturn(playerTemplate, 'interfaceName', interfaceName, 'index', friendInfo.identID, 'userName', friendInfo.name, 'userNameColor', 'white', 'accountIcon', '/ui/shared/textures/account_icons/default.tga', 'identID', friendInfo.identID, 'statusColor', 'white', 'statusText', statusText, 'secondaryLabel', friendInfo.uniqueID, 'isOnline', 'false')
						local insertedFriendParent = insertedWidgets[1]
						
						if (insertedFriendParent) and (Friends[interfaceName].RegisterFriend) then
							Friends[interfaceName].RegisterFriend(insertedFriendParent, friendInfo.identID)
						end
						
					end
				end
				
				local function InstantiateDropTargetEntry(headerTemplate, interfaceName, headerIndex, displayGroup)
					
					local label = TranslateOrNil('main_social_groupname_addplayer_' .. displayGroup) or Translate('main_social_groupname_addplayer_generic')
					
					if (Windows.data) and (Windows.data.friendBeingDraggedIdentID) and IsMe(Windows.data.friendBeingDraggedIdentID) and (displayGroup == 'party') then
						label = Translate('main_social_groupname_addplayer_self_party')
					end
					
					local insertedWidgets = socialclient_im_friendlist:InstantiateAndReturn('socialclient_im_friendlist_droptarget_template', 'interfaceName', interfaceName, 'index', headerIndex, 'label', label)
					local insertedDropTargetParent = insertedWidgets[1]
					
					if (insertedDropTargetParent) and (Friends[interfaceName].RegisterDropTarget) and (Windows.data) and (Windows.data.friendBeingDraggedIdentID) then
						Friends[interfaceName].RegisterDropTarget(insertedDropTargetParent, headerIndex, displayGroup, Windows.data.friendBeingDraggedIdentID)
					end					
					
				end
				
				local function InstantiateHeaderEntry(headerTemplate, interfaceName, headerIndex, displayGroup)
				
					local headerName = TranslateOrNil('main_social_groupname_' .. displayGroup) or displayGroup or '?No Header'
					local countLabel = ''
					local rotation = 0
					
					if (#groupTable > 0) then
						countLabel = #groupTable .. '/' .. totalPlayerCount
					end
					
					if (mainUI.savedRemotely) and (mainUI.savedRemotely.groupExpanded) and (mainUI.savedRemotely.groupExpanded[displayGroup]) then
						rotation = 0
					else
						rotation = -180
					end				
					
					Friends.labelTable[displayGroup] = true
					
					socialclient_im_friendlist:Instantiate(headerTemplate, 'interfaceName', interfaceName, 'index', headerIndex, 'label', headerName, 'displayGroup', displayGroup, 'rotation', rotation, 'countLabel', countLabel)
					
					if (MultiWindowDragInfo.active) and (MultiWindowDragInfo.type == 'player') and (Windows.data) and (Windows.data.friendBeingDraggedIdentID) then
						
						local friendInfo = Friends[interfaceName].GetFriendDataFromIdentID(Windows.data.friendBeingDraggedIdentID)
						if (friendInfo) and (displayGroup ~= 'offline') and (friendInfo.buddyLabel ~= displayGroup) and (not ((friendInfo.buddyLabel == 'Friends') and (displayGroup == 'online'))) and (not ((friendInfo.buddyLabel == 'Default') and (displayGroup == 'online'))) and (not ((displayGroup == 'party') and (((PartyStatus.inParty) and (not PartyStatus.isPartyLeader)) or (playersInParty >= 5)))) then
							InstantiateDropTargetEntry(headerTemplate, interfaceName, headerIndex, displayGroup)
						end
					end
					
				end
				
				for i,friendInfo in pairs(groupTable) do	
					
					mainUI.savedRemotely.groupExpanded = mainUI.savedRemotely.groupExpanded or {}
					if (mainUI.savedRemotely.groupExpanded[displayGroup] == nil) then
						mainUI.savedRemotely.groupExpanded[displayGroup] = true
					end
					
					if (spawnedHeaders[displayGroup] == nil) then
						headerIndex = headerIndex + 1
						spawnedHeaders[displayGroup] = {}
						table.insert(spawnedHeaders[displayGroup], headerIndex)					
						InstantiateHeaderEntry(headerTemplate, interfaceName, headerIndex, displayGroup)
						-- println('Creating new header ^y' .. tostring(displayGroup) .. ' ^g' .. headerIndex)
					end
					
					if (friendInfo) and (type(friendInfo) == 'table') then
						if (not spawnedRows[displayGroup]) then
							rowIndex = rowIndex + 1
							socialclient_im_friendlist:Instantiate('socialclient_im_friendlist_row_template', 'interfaceName', interfaceName, 'index', rowIndex, 'label', displayGroup)
							InstantiatePlayerEntry(GetWidget('socialclient_im_friendlist_row_' .. rowIndex), interfaceName, friendInfo)
							spawnedRows[displayGroup] = {}
							table.insert(spawnedRows[displayGroup], {index = rowIndex, count = 1})
							-- println('Creating new row cus the header is new ^y' .. tostring(displayGroup) .. ' ^g' .. tostring(rowIndex))
						else
							--[[
							local spawnedFriendItem = false
							for _,rowTable in ipairs(spawnedRows[displayGroup]) do
								local spawnedRowIndex = rowTable.index
								local rowWidget = GetWidget('socialclient_im_friendlist_row_' .. spawnedRowIndex)
								if (rowWidget) then
									local numItems = rowTable.count
									local rowWidth = FRIEND_ITEM_WIDTH * numItems
									if ((rowWidth) <= (socialclient_im_friendlist:GetWidth() - (FRIEND_ITEM_WIDTH * 0.82))) then
										spawnedFriendItem = true
										InstantiatePlayerEntry(GetWidget('socialclient_im_friendlist_row_' .. rowIndex), interfaceName, friendInfo)
										rowTable.count = rowTable.count + 1
										-- println('Inserting into existing row ^y' .. rowTable.count .. ' ' .. tostring(displayGroup) .. ' ^g' .. tostring(rowIndex))
									end
								end
							end
							if (not spawnedFriendItem) then
							]]
								rowIndex = rowIndex + 1
								socialclient_im_friendlist:Instantiate('socialclient_im_friendlist_row_template', 'interfaceName', interfaceName, 'index', rowIndex, 'label', displayGroup)
								InstantiatePlayerEntry(GetWidget('socialclient_im_friendlist_row_' .. rowIndex), interfaceName, friendInfo)
								table.insert(spawnedRows[displayGroup], {index = rowIndex, count = 1})	
								-- println('Creating new row cus the other rows are full ^y' .. tostring(displayGroup) .. ' ^g' .. tostring(rowIndex))
							--end
						end
					end
				end
			end
			
			if (sortableTable) then
				if (sortableTable['search']) then
					SpawnFriendsUsingGroupTable(sortableTable['search'], 'search')
					sortableTable['search'] = nil
				end			
				if (sortableTable['autocomplete']) then
					SpawnFriendsUsingGroupTable(sortableTable['autocomplete'], 'autocomplete')
					sortableTable['autocomplete'] = nil
				end	
				if (sortableTable['party']) then
					SpawnFriendsUsingGroupTable(sortableTable['party'], 'party', true)
					sortableTable['party'] = nil
				end			

				local groupSortableTable = {}
				
				for i,v in pairs(sortableTable) do
					if (i ~= 'offline') and (i ~= 'online')  and(i ~= 'Default') and (i ~= 'search') and (i ~= 'recently') and (i ~= 'party') and (i ~= 'autocomplete')  and (i ~= 'sent') and (i ~= 'pending') and (i ~= 'ignored') and (i ~= 'rejected') then
						table.insert(groupSortableTable, {name = i, grouptable = v})
						v = nil
					end
				end

				table.sort(groupSortableTable, function(a,b) 
					if (a) and (b) and (a.name) and (b.name)  then
						return string.lower(a.name) < string.lower(b.name) 
					elseif (a.name) then
						return true
					else
						return false
					end
				end)			
				
				for i,v in ipairs(groupSortableTable) do
					SpawnFriendsUsingGroupTable(v.grouptable, v.name, true)
				end
				
				if (sortableTable['online']) then
					SpawnFriendsUsingGroupTable(sortableTable['online'], 'online', true)
					sortableTable['online'] = nil
				end
				if (sortableTable['pending']) then
					SpawnFriendsUsingGroupTable(sortableTable['pending'], 'pending')
					sortableTable['pending'] = nil
				end						
				if (sortableTable['offline']) then
					SpawnFriendsUsingGroupTable(sortableTable['offline'], 'offline')
					sortableTable['offline'] = nil
				end	
				-- if (sortableTable['sent']) then
					-- SpawnFriendsUsingGroupTable(sortableTable['sent'], 'sent')
					-- sortableTable['sent'] = nil
				-- end	
				if (sortableTable['recently']) then
					SpawnFriendsUsingGroupTable(sortableTable['recently'], 'recently')
					sortableTable['recently'] = nil
				end		
				if (sortableTable['ignored']) then
					SpawnFriendsUsingGroupTable(sortableTable['ignored'], 'ignored')
					sortableTable['ignored'] = nil
				end		
				if (sortableTable['rejected']) then
					SpawnFriendsUsingGroupTable(sortableTable['rejected'], 'rejected')
					sortableTable['rejected'] = nil
				end					
			end
			
			if (Friends.playerSearchTerm) and (not Empty(Friends.playerSearchTerm)) then
				-- Don't hide hidden groups, we are searching
			else
				for displayGroup, displayGroupTable in pairs(spawnedRows) do
					if (mainUI.savedRemotely) and (mainUI.savedRemotely.groupExpanded) and (mainUI.savedRemotely.groupExpanded[displayGroup] == false) then
						for i,v in pairs(displayGroupTable) do
							local widget = GetWidget('socialclient_im_friendlist_row_' .. v.index)
							if (v.index) and widget then
								widget:SetVisible(0)
							end
						end
					end
				end
			end
			
			if (countOnline) and (countOnline > 0) then
				UIManager.GetInterface('main'):GetWidget('friends_footer_buttonLabel'):SetText(countOnline .. ' ' .. Translate('mainlobby_label_cc_friends'))
			else
				UIManager.GetInterface('main'):GetWidget('friends_footer_buttonLabel'):SetText(Translate('mainlobby_label_cc_friends'))
			end
			
			if (countPending) and (countPending > 0) then
				UIManager.GetInterface('main'):GetWidget('friends_footer_button_notification_label'):SetText(countPending)
				UIManager.GetInterface('main'):GetWidget('friends_footer_button_notification_parent'):SetVisible(1)
				UIManager.GetInterface('main'):GetWidget('friends_footer_buttonBaseIcon'):SetVisible(0)
			else
				UIManager.GetInterface('main'):GetWidget('friends_footer_button_notification_parent'):SetVisible(0)
				UIManager.GetInterface('main'):GetWidget('friends_footer_buttonBaseIcon'):SetVisible(1)
				UIManager.GetInterface('main'):GetWidget('friends_footer_button_notification_label'):SetText('')
			end			
			
			interface:GetWidget('socialclient_friendlist_nofriends_sadface'):SetVisible((headerIndex == 0) and (rowIndex == 0) and ((not Friends.playerSearchTerm) or (Empty(Friends.playerSearchTerm))))
			
			socialclient_im_friendlist_scrollbar:SetMaxValue(headerIndex + rowIndex)
			
			if (postUpdateCallback) then
				postUpdateCallback()
			end
			
			Friends[interfaceName].UpdateScrollPosition(true)

		end
		
	end
	
	function WatchFriend(identID, nameCatUniqueID, infoTable)
		local friendsClientInfoTrigger = LuaTrigger.GetTrigger('ChatClientInfo' .. string.gsub(identID, '%.', ''))
		if (friendsClientInfoTrigger) then
			local lastRun = -1
			local function UpdateFriendData(trigger)
				if (lastRun + 100 >= GetTime()) then return end -- Twice in 100 milliseconds, ignore it.
				lastRun = GetTime()
				--println("UpdateFriendData " .. trigger.identID)

				local userIcon = trigger.accountIconPath
				if (trigger.isStaff) and (trigger.accountIconPath) and ((trigger.accountIconPath == '/ui/shared/textures/account_icons/default.tga') or (trigger.accountIconPath == 'default')) then
					userIcon = '/ui/shared/textures/account_icons/s2staff.tga'
				elseif (trigger.accountIconPath == 'default') then
					userIcon = '/ui/shared/textures/account_icons/default.tga'
				else
					if trigger.accountIconPath and string.find(userIcon, '.tga') then
						userIcon = trigger.accountIconPath or '$invis'
					elseif trigger.accountIconPath and (not Empty(trigger.accountIconPath)) then
						userIcon = '/ui/shared/textures/account_icons/' .. trigger.accountIconPath .. '.tga'
					else
						userIcon = '/ui/shared/textures/account_icons/default.tga'
					end
				end
				if (trigger.name) and (not Empty(trigger.name)) then
					Friends.friendData 										= Friends.friendData or {}
					Friends.friendData[nameCatUniqueID] 					= Friends.friendData[nameCatUniqueID] or {}
					Friends.friendData[nameCatUniqueID].trueName			= trigger.name
					Friends.friendData[nameCatUniqueID].name				= Friends.friendData[nameCatUniqueID].name or trigger.name
					Friends.friendData[nameCatUniqueID].icon				= userIcon
					Friends.friendData[nameCatUniqueID].accountTitle		= trigger.accountTitle
					Friends.friendData[nameCatUniqueID].uniqueID			= trigger.uniqueID 
					Friends.friendData[nameCatUniqueID].status				= trigger.status
					Friends.friendData[nameCatUniqueID].identID				= trigger.identID
					Friends.friendData[nameCatUniqueID].isDND				= trigger.isDND			
					Friends.friendData[nameCatUniqueID].isFriend			= trigger.isFriend			
					Friends.friendData[nameCatUniqueID].isStaff				= trigger.isStaff			
					Friends.friendData[nameCatUniqueID].ready				= trigger.ready			
					Friends.friendData[nameCatUniqueID].accountColor		= trigger.accountColor			
					Friends.friendData[nameCatUniqueID].accountIconPath		= trigger.accountIconPath			
					Friends.friendData[nameCatUniqueID].accountTitle		= trigger.accountTitle			
					Friends.friendData[nameCatUniqueID].status				= trigger.status			
					Friends.friendData[nameCatUniqueID].uiStatus			= trigger.uiStatus			
					Friends.friendData[nameCatUniqueID].userStatus			= trigger.userStatus			
					Friends.friendData[nameCatUniqueID].userStatusMessage	= trigger.userStatusMessage			
					Friends.friendData[nameCatUniqueID].ignored				= trigger.isIgnored		
					Friends.friendData[nameCatUniqueID].spectatableGame		= trigger.inSpectatableGame		
						
					-- Party
					Friends.friendData[nameCatUniqueID].canBePromoted				= trigger.canBePromoted			
					Friends.friendData[nameCatUniqueID].canKickPlayer				= trigger.canKickPlayer			
					Friends.friendData[nameCatUniqueID].canPlayCurrentQueue			= trigger.canPlayCurrentQueue			
					Friends.friendData[nameCatUniqueID].canPlayRanked				= trigger.canPlayRanked			
					Friends.friendData[nameCatUniqueID].isLeader					= trigger.isLeader			
					Friends.friendData[nameCatUniqueID].isLocalPlayer				= trigger.isLocalPlayer			
					Friends.friendData[nameCatUniqueID].isMuted						= trigger.isMuted			
					Friends.friendData[nameCatUniqueID].isPending					= trigger.isPending			
					Friends.friendData[nameCatUniqueID].ready 						= trigger.ready 			
					Friends.friendData[nameCatUniqueID].isReady 					= trigger.ready 			
					Friends.friendData[nameCatUniqueID].isTalking 					= trigger.isTalking 			
					
					-- Clans
					Friends.friendData[nameCatUniqueID].clanID				= trigger.clanID		
					Friends.friendData[nameCatUniqueID].clanName			= trigger.clanName		
					Friends.friendData[nameCatUniqueID].clanRank			= trigger.clanRank		
					Friends.friendData[nameCatUniqueID].clanTag				= trigger.clanTag					
					
					local partyInfoTable = infoTable or GetPartyPlayerDataFromIdentID(trigger.identID)
					
					if (partyInfoTable) then
						Friends.friendData[nameCatUniqueID].gearSetName			= partyInfoTable.gearSetName
						Friends.friendData[nameCatUniqueID].heroDisplayName		= partyInfoTable.heroDisplayName
						Friends.friendData[nameCatUniqueID].heroEntityName		= partyInfoTable.heroEntityName
						Friends.friendData[nameCatUniqueID].heroIconPath		= partyInfoTable.heroIconPath
						Friends.friendData[nameCatUniqueID].petDisplayName		= partyInfoTable.petDisplayName
						Friends.friendData[nameCatUniqueID].petEntityName		= partyInfoTable.petEntityName
						Friends.friendData[nameCatUniqueID].skinName			= partyInfoTable.skinName
					else
						Friends.friendData[nameCatUniqueID].gearSetName			= nil
						Friends.friendData[nameCatUniqueID].heroDisplayName		= nil
						Friends.friendData[nameCatUniqueID].heroEntityName		= nil
						Friends.friendData[nameCatUniqueID].heroIconPath		= nil
						Friends.friendData[nameCatUniqueID].petDisplayName		= nil
						Friends.friendData[nameCatUniqueID].petEntityName		= nil
						Friends.friendData[nameCatUniqueID].skinName			= nil
					end
				end
			end
			UnwatchLuaTriggerByKey('ChatClientInfo' .. string.gsub(identID, '%.', ''), 'FriendChatClientInfo'..string.gsub(identID, '%.', ''))
			WatchLuaTrigger('ChatClientInfo' .. string.gsub(identID, '%.', ''), function(trigger)
				UpdateFriendData(trigger)
				Friends[interfaceName].AttemptUpdate(false, nil)
			end, 'FriendChatClientInfo'..string.gsub(identID, '%.', ''), "accountColor", "accountIconPath", "accountTitle", "canBePromoted", "canKickPlayer", "canPlayCurrentQueue", "canPlayRanked", "identID", "isDND", "isFriend", "isIgnored", "isLeader", "isLocalPlayer", "isMuted", "isPending", "inSpectatableGame", "isTalking", "isStaff", "name", "userStatusMessage", "status", "ready", "uiStatus", "userStatus", "uniqueID")
			UpdateFriendData(friendsClientInfoTrigger)
		end
	end
	
	local function FriendsDataRegister(object)
		Friends.friendData = Friends.friendData or {}
		
		local function addUserData(widget, trigger, isOnline, isInGame, isIgnoreList)
			if (isIgnoreList) then
				isOnline = false
				isInGame = false		
			elseif trigger.ignored == true then
				buddyGroup = 'ignored'					
			elseif trigger.acceptStatus == 'pending' then
				isOnline = false
			elseif trigger.acceptStatus == 'rejected' then
				return	
			elseif (isOnline) then
				if buddyGroup == 'Friends' or buddyGroup == 'Default' or buddyGroup == 'Friend' or buddyGroup == '' then
					if trigger.acceptStatus == 'sent' then
						isOnline = false
						isInGame = false
					elseif isInGame then
						isOnline = true
					elseif isOnline then
					else
						isOnline = false
						isInGame = false					
					end
				end
			else
				isOnline = false
				isInGame = false				
			end

			local accountIcon = trigger.accountIconPath
			if (not accountIcon) or Empty(accountIcon) then
				accountIcon = '/ui/shared/textures/account_icons/default.tga'
			end
			
			local  name 		= trigger.buddyName
			local  uniqueID 	= trigger.buddyUniqueID
			if (name) and (not Empty(name)) then
				Friends.friendData									= Friends.friendData or {}
				Friends.friendData[name .. uniqueID]				= Friends.friendData[name .. uniqueID] or {}
				Friends.friendData[name .. uniqueID].name			= trigger.buddyName
				Friends.friendData[name .. uniqueID].trueName		= trigger.buddyName
				Friends.friendData[name .. uniqueID].buddyGroup		= Translate('friends_default_group')	-- rmm
				Friends.friendData[name .. uniqueID].buddyLabel		= trigger.buddyGroup
				Friends.friendData[name .. uniqueID].icon			= accountIcon
				Friends.friendData[name .. uniqueID].uniqueID		= trigger.buddyUniqueID
				Friends.friendData[name .. uniqueID].acceptStatus	= trigger.acceptStatus
				Friends.friendData[name .. uniqueID].isOnline		= isOnline
				Friends.friendData[name .. uniqueID].isInGame		= isInGame
				Friends.friendData[name .. uniqueID].isInLobby		= trigger.inLobby
				Friends.friendData[name .. uniqueID].isInParty		= trigger.inParty
				Friends.friendData[name .. uniqueID].isFriend		= true
				Friends.friendData[name .. uniqueID].identID		= trigger.buddyIdentID
				Friends.friendData[name .. uniqueID].joinableGame	= trigger.joinableGame
				Friends.friendData[name .. uniqueID].joinableParty	= trigger.joinableParty
				Friends.friendData[name .. uniqueID].ignored		= trigger.ignored
				Friends.friendData[name .. uniqueID].spectatableGame = trigger.spectatableGame

				-- Clans
				-- Friends.friendData[name .. uniqueID].clanID			= trigger.clanID		
				-- Friends.friendData[name .. uniqueID].clanName		= trigger.clanName		
				-- Friends.friendData[name .. uniqueID].clanRank		= trigger.clanRank		
				-- Friends.friendData[name .. uniqueID].clanTag		= trigger.clanTag				
				
				WatchFriend(trigger.buddyIdentID, name .. uniqueID, playerInfo)
			end
		end
		
		object:RegisterWatchLua('FriendListGame', function(widget, trigger) addUserData(widget, trigger, true, true, false) end)
		object:RegisterWatchLua('FriendListOffline', function(widget, trigger) addUserData(widget, trigger, false, false, false) end)
		object:RegisterWatchLua('FriendListOnline', function(widget, trigger) addUserData(widget, trigger, true, false, false) end)
		object:RegisterWatchLua('IgnoredList', function(widget, trigger) addUserData(widget, trigger, false, false, true) end)
		
		object:RegisterWatchLua('FriendListEvent', function(widget, trigger)
			local event = trigger.eventType
			if event == 'ClearItems' then
				for i,v in pairs(Friends.friendData) do
					v.isFriend = false
				end
			elseif event == 'SortListboxSortIndex' then
				Friends[interfaceName].AttemptUpdate(false, nil)
			end
		end)		
		
		object:RegisterWatchLua('MultiWindowDragInfo', function(widget, trigger)
			libThread.threadFunc(function()
				wait(1)		
				Friends[interfaceName].AttemptUpdate(true, nil)
			end)
		end)	
	
		function Friends.StressTestFriends()
			local entry
			for k,v in pairs(Friends.friendData) do
				entry = v
				break
			end

			for n = 1, 600 do
				local entry = table.copy(entry)
				local id = math.random(9999)

				entry.uniqueID = tostring(id)
				entry.identID = math.random(999) .. '.' .. math.random(999)
				entry.name = 'stress'
				entry.acceptStatus = 'approved'

				Friends.friendData['stress' .. id] = entry
			end
		end	
	
	end

	local function FriendsScrollRegister(object)
	
		Friends[interfaceName].UpdateScrollPosition = function(dontAnimate)
			local SCROLL_Y_AMOUNT_ROW = socialclient_im_friendlist:GetHeightFromString(playerTemplateHeight)
			local SCROLL_Y_AMOUNT_HEADER = socialclient_im_friendlist:GetHeightFromString(headerTemplateHeight)
			local scrollValue = tonumber(socialclient_im_friendlist_scrollbar:GetValue()) or 0
			local maxScrollValue = tonumber(socialclient_im_friendlist_scrollbar:GetMaxValue()) or 1
			local maxScrollAmount = ((SCROLL_Y_AMOUNT_ROW * rowIndex) + (SCROLL_Y_AMOUNT_HEADER * headerIndex)) - (GetWidget('socialclient_im_friendlist_parent'):GetHeight() - socialclient_im_friendlist:GetHeightFromString('4s'))
			local scrollAmount = (scrollValue / maxScrollValue) * maxScrollAmount
			if (maxScrollAmount > 0) and (scrollAmount >= -20) then
				socialclient_im_friendlist_scrollbar:FadeIn(125)
				socialclient_im_friendlist_parent:SetWidth('-30s')
				if (dontAnimate) then
					socialclient_im_friendlist:SetY(scrollAmount * -1)		
				else
					socialclient_im_friendlist:SlideY(scrollAmount * -1, 125)
				end
			else
				socialclient_im_friendlist_scrollbar:FadeOut(125)
				socialclient_im_friendlist_parent:SetWidth('100%')
			end
		end
		
		local isUsingHandle = false
		interface:GetWidget('socialclient_im_friendlist_scrollbar_slider_handle'):SetCallback('onmouseover', function(widget)
			isUsingHandle = true
		end)	
		socialclient_im_friendlist_scrollbar:SetCallback('onmouselup', function(widget)
			isUsingHandle = false
		end)		
		
		socialclient_im_friendlist_scrollbar:SetCallback('onslide', function(widget)
			Friends[interfaceName].UpdateScrollPosition(isUsingHandle)
		end)
		Friends[interfaceName].WheelUp = function()
			isUsingHandle = false
			local scrollValue = tonumber(socialclient_im_friendlist_scrollbar:GetValue()) or 0
			socialclient_im_friendlist_scrollbar:SetValue( math.max(0, scrollValue - 1) )
		end
		Friends[interfaceName].WheelDown = function ()
			isUsingHandle = false
			local scrollValue = tonumber(socialclient_im_friendlist_scrollbar:GetValue()) or 0
			local maxScrollValue = tonumber(socialclient_im_friendlist_scrollbar:GetMaxValue()) or 1
			socialclient_im_friendlist_scrollbar:SetValue( math.min(maxScrollValue, scrollValue + 1) )
		end	
		
		local social_client_scroll_catchers = object:GetGroup('social_client_scroll_catchers')
		for _, social_client_scroll_catcher in pairs(social_client_scroll_catchers) do
			social_client_scroll_catcher:SetCallback('onmousewheelup', function(widget)
				 isUsingHandle = false
				 Friends[interfaceName].WheelUp()
			end)
			social_client_scroll_catcher:SetCallback('onmousewheeldown', function(widget)
				isUsingHandle = false
				Friends[interfaceName].WheelDown()
			end)	
		end

	end	

	local function FriendsSearchRegister(object)
		
		local new_friend_window_topbar_search 					= GetWidget('new_friend_window_topbar_search')
		local main_social_friends_searchinput_buffer 			= GetWidget('main_social_friends_searchinput_buffer')
		local main_social_friends_searchinput_coverlabel 		= GetWidget('main_social_friends_searchinput_coverlabel')
		local new_friend_window_topbar_addfriend 				= GetWidget('new_friend_window_topbar_addfriend')
		local main_social_friends_searchinput_button 			= GetWidget('main_social_friends_searchinput_button')
		local main_social_friends_searchinput_close_btn 		= GetWidget('main_social_friends_searchinput_close_btn')
		local main_social_friends_searchinput_frame_highlight 	= GetWidget('main_social_friends_searchinput_frame_highlight')
		local new_friend_window_topbar_invites 					= GetWidget('new_friend_window_topbar_invites')
		local new_friend_window_topbar_invites_label 			= GetWidget('new_friend_window_topbar_invites_label')
		local new_friend_window_topbar_feedback 				= GetWidget('new_friend_window_topbar_feedback')
		local new_friend_window_topbar_feedback_label 			= GetWidget('new_friend_window_topbar_feedback_label')
		local new_friend_window_topbar 							= GetWidget('new_friend_window_topbar')
		local new_friend_window_list 							= GetWidget('new_friend_window_list')
		local new_friend_window_topbar_searchgo 				= GetWidget('new_friend_window_topbar_searchgo')
		local queueAutoCompleteThread
		
		local function QueueAutoComplete(incText)
			local queuedText = incText
			if (queueAutoCompleteThread) and (queueAutoCompleteThread:IsValid()) then
				queueAutoCompleteThread:kill()
			end
			queueAutoCompleteThread = nil			
			queueAutoCompleteThread = libThread.threadFunc(function()
				wait(350)
				if (main_social_friends_searchinput_buffer) and (main_social_friends_searchinput_buffer:IsValid()) then
					local freshText = main_social_friends_searchinput_buffer:GetValue()
					if (freshText) and (string.len(freshText) >= 3) then
					
						Friends.autoCompleteResults = {}

						local successFunction =  function (request)	-- web response handler
							local responseData = request:GetBody()
							if responseData == nil then
								SevereError('SearchNickname - no response data', 'main_reconnect_thatsucks', '', nil, nil, false)
								return nil
							else
								if (responseData) then
									for i,v in pairs(responseData) do
										if (v.ident_id) then
											local data = Friends[interfaceName].GetFriendDataFromIdentID(v.ident_id)
											local autoCompleteData = Friends[interfaceName].GetAutoCompleteDataFromIdentID(v.ident_id)
											if ((Friends.autoCompleteResults) and (#Friends.autoCompleteResults > 0) and (autoCompleteData)) or (data) then	
												if (Friends.friendData[v.nickname..v.uniqid]) and (Friends.friendData[v.nickname..v.uniqid].buddyLabel == Translate('main_social_groupname_autocomplete')) then
													table.insert(Friends.autoCompleteResults, {v.nickname, v.uniqid, v.ident_id, false})
												else
													-- skip this one
												end
											else
												table.insert(Friends.autoCompleteResults, {v.nickname, v.uniqid, v.ident_id, false})
											end
										end
									end
								end
								if (#Friends.autoCompleteResults > 0) then
									Friends[interfaceName].AttemptUpdate(true, nil)
								end

								return true
							end
						end
						
						local failFunction =  function (request)	-- web error handler
							SevereError('SearchNickname Request Error: ' .. Translate(request:GetError()), 'main_reconnect_thatsucks', '', nil, nil, false)
							return nil
						end				
						
						
						local chatServerCallbackFunction =  function (results)	-- chat server response handler
							local responseData = results
							if responseData == nil then
								SevereError('SearchNickname - no response data', 'main_reconnect_thatsucks', '', nil, nil, false)
								return nil
							else
								if (responseData) then
									for i,v in pairs(responseData) do
										local identID = v.identid
										if string.find(identID, '%.') then
										
										else
											identID = string.sub(identID, 1, -4) .. '.' .. string.sub(identID, -3)
										end
										if (identID) and (Friends.friendData) and Friends[interfaceName].GetFriendDataFromIdentID(identID) ~= nil then
											-- skip this one
										else
											table.insert(Friends.autoCompleteResults, {v.nickname, v.uniqid, identID, true})
										end
									end
								end

								-- now ask web for all friends so we can see offline people too
								Strife_Web_Requests:SearchNickname(freshText, successFunction, failFunction)
								return true
							end
						end
					
						-- first ask chatserver for online friends
						Client.GetClientList(freshText, chatServerCallbackFunction)
					else
						Friends.autoCompleteResults = {}
						Friends[interfaceName].AttemptUpdate(true, nil)
					end
				end
				queueAutoCompleteThread = nil
			end)
		end		
		
		local function AttentionPulse(color)
			local color = color or '#da3f3f'
			main_social_friends_searchinput_frame_highlight:SetBorderColor(color)
			main_social_friends_searchinput_frame_highlight:FadeIn(500, function(self) self:FadeOut(500) end)		
		end		
		
		local friendListPulseFeedbackThread
		local friendListPendingInviteThread
		Friends[interfaceName].FriendListPendingInvite = function(trigger)
			
			local color = color or '#da3f3f'
			local text = text or '???'
			
			if (friendListPendingInviteThread) and (friendListPendingInviteThread:IsValid()) then
				friendListPendingInviteThread:kill()
			end
			friendListPendingInviteThread = nil			
			new_friend_window_topbar_invites_label:SetText(Translate('social_game_party_invites_pending', 'value', trigger.partyInvites + trigger.lobbyInvites))
			if ((trigger.partyInvites > 0) or (trigger.lobbyInvites > 0)) then
				friendListPendingInviteThread = libThread.threadFunc(function()
					
					new_friend_window_topbar_invites:SetVisible(0)
					new_friend_window_topbar_invites:SetHeight('0')
					if (friendListPulseFeedbackThread == nil) and (new_friend_window_list) and (new_friend_window_list:IsValid())  then
						new_friend_window_topbar:SetHeight('90s')
						new_friend_window_list:SetY('28s')
						new_friend_window_list:SetHeight('-53s')
					end
					
					wait(1)	
					
					new_friend_window_topbar_feedback_label:SetText(text)
					new_friend_window_topbar_feedback_label:SetColor(color)
					new_friend_window_topbar_invites:ScaleHeight('40s', 125)
					new_friend_window_topbar_invites:FadeIn(125)
					if (friendListPulseFeedbackThread == nil) and (new_friend_window_list) and (new_friend_window_list:IsValid())  then
						new_friend_window_topbar:ScaleHeight('130s', 125)
						new_friend_window_list:SetHeight('-93s')
						new_friend_window_list:SlideY('68s', 125)
					end
					
					friendListPendingInviteThread = nil
				end)
				if (trigger.partyInvites > 0) then
					interface:GetWidget('new_friend_window_topbar_invites'):SetCallback('onclick', function(widget)
						ClickButton(UIManager.GetInterface('main'), 'notification_party_invite')
					end)				
				else
					interface:GetWidget('new_friend_window_topbar_invites'):SetCallback('onclick', function(widget)
						ClickButton(UIManager.GetInterface('main'), 'notification_lobby_invite')
					end)				
				end
			else
				friendListPendingInviteThread = libThread.threadFunc(function()

					new_friend_window_topbar_invites:ScaleHeight('0s', 250)
					new_friend_window_topbar_invites:FadeOut(250)
					if (friendListPulseFeedbackThread == nil) and (new_friend_window_list) and (new_friend_window_list:IsValid())  then
						new_friend_window_topbar:ScaleHeight('90s', 250)						
						new_friend_window_list:SlideY('28s', 250)				
					end
					
					wait(250)	
					
					if (friendListPulseFeedbackThread == nil) and (new_friend_window_list) and (new_friend_window_list:IsValid()) then
						new_friend_window_list:SetHeight('-53s')
					end
					
					friendListPendingInviteThread = nil
				end)			
			end
		end	
		interface:GetWidget('new_friend_window_topbar_invites'):RegisterWatchLua('notificationsTrigger', function(widget, trigger)
			Friends[interfaceName].FriendListPendingInvite(trigger)
		end, false, 'partyInvites', 'lobbyInvites')
		
		interface:GetWidget('new_friend_window_topbar_invites'):SetCallback('onclick', function(widget)
			ClickButton(UIManager.GetInterface('main'), 'notification_party_invite')
		end)
		
		Friends[interfaceName].FriendListPulseFeedback = function(text, color)
			
			local notificationsTrigger = LuaTrigger.GetTrigger('notificationsTrigger')
			local color = color or '#da3f3f'
			local text = text or '???'
			
			if (friendListPulseFeedbackThread) and (friendListPulseFeedbackThread:IsValid()) then
				friendListPulseFeedbackThread:kill()
			end
			friendListPulseFeedbackThread = nil			
			friendListPulseFeedbackThread = libThread.threadFunc(function()
				
				new_friend_window_topbar_feedback:SetVisible(0)
				new_friend_window_topbar_feedback:SetHeight('0')
				
				if  ((notificationsTrigger.partyInvites == 0) and (notificationsTrigger.lobbyInvites == 0)) and (friendListPendingInviteThread == nil) and (new_friend_window_list) and (new_friend_window_list:IsValid())   then
					new_friend_window_topbar:SetHeight('90s')
					new_friend_window_list:SetY('28s')
					new_friend_window_list:SetHeight('-53s')
				end
				
				wait(1)	
				
				new_friend_window_topbar_feedback_label:SetText(text)
				new_friend_window_topbar_feedback_label:SetColor(color)
				new_friend_window_topbar_feedback:ScaleHeight('40s', 125)
				new_friend_window_topbar_feedback:FadeIn(125)
				
				if ((notificationsTrigger.partyInvites == 0) and (notificationsTrigger.lobbyInvites == 0)) and (friendListPendingInviteThread == nil) and (new_friend_window_list) and (new_friend_window_list:IsValid())   then
					new_friend_window_topbar:ScaleHeight('130s', 125)
					new_friend_window_list:SetHeight('-93s')
					new_friend_window_list:SlideY('68s', 125)
				end
				
				wait(2750)	
				
				new_friend_window_topbar_feedback:ScaleHeight('0s', 250)
				new_friend_window_topbar_feedback:FadeOut(250)
				
				if ((notificationsTrigger.partyInvites == 0) and (notificationsTrigger.lobbyInvites == 0)) and (friendListPendingInviteThread == nil) and (new_friend_window_list) and (new_friend_window_list:IsValid())   then
					new_friend_window_topbar:ScaleHeight('90s', 250)
					new_friend_window_list:SlideY('28s', 250)				
				end
				
				wait(250)	
				if ((notificationsTrigger.partyInvites == 0) and (notificationsTrigger.lobbyInvites == 0)) and (friendListPendingInviteThread == nil) and (new_friend_window_list) and (new_friend_window_list:IsValid())  then
					new_friend_window_list:SetHeight('-53s')
				end
				
				friendListPulseFeedbackThread = nil
			end)
		end
		
		main_social_friends_searchinput_buffer:EraseInputLine()		
		main_social_friends_searchinput_buffer:SetCallback('onshow', function(widget)
			if (Friends.playerSearchTerm) and (not Empty(Friends.playerSearchTerm)) then
				main_social_friends_searchinput_buffer:SetInputLine(Friends.playerSearchTerm)
				main_social_friends_searchinput_buffer:SetFocus(true)
			else
				main_social_friends_searchinput_buffer:SetInputLine('')
				main_social_friends_searchinput_buffer:SetFocus(false)			
			end
		end)
		
		main_social_friends_searchinput_buffer:SetCallback('onchange', function(widget)
			local text = main_social_friends_searchinput_buffer:GetValue()
			if (text) then
				Friends.playerSearchTerm = text
				new_friend_window_topbar_searchgo:SetEnabled(not Empty(text))			
				main_social_friends_searchinput_coverlabel:SetVisible(Empty(text))			
				main_social_friends_searchinput_coverlabel:SetText(Translate('general_search'))	
				main_social_friends_searchinput_button:SetVisible((Empty(text)) and (not main_social_friends_searchinput_buffer:HasFocus()))			
				main_social_friends_searchinput_close_btn:SetVisible((not Empty(text)) or (main_social_friends_searchinput_buffer:HasFocus()))		
				Friends[interfaceName].AttemptUpdate(true, nil)
				QueueAutoComplete(text)
				socialclient_im_friendlist_scrollbar:SetValue(0)
				Friends[interfaceName].UpdateScrollPosition()					
			end	
		end)	
	
		main_social_friends_searchinput_buffer:SetCallback('onfocus', function(widget)
			local text = main_social_friends_searchinput_buffer:GetValue()
			new_friend_window_topbar_searchgo:SetVisible(125)	
			if (text) then
				new_friend_window_topbar_searchgo:SetEnabled(not Empty(text))
			end			
			main_social_friends_searchinput_close_btn:FadeIn(125)	
			main_social_friends_searchinput_button:SetVisible(0)
			AttentionPulse('#00c3d6')
			new_friend_window_topbar_search:ScaleWidth('56%', 125)
			main_social_friends_searchinput_close_btn:SlideX('59%', 125)
			main_social_friends_searchinput_button:SlideX('59%', 125)		
			socialclient_im_friendlist_scrollbar:SetValue(0)
			Friends[interfaceName].UpdateScrollPosition()	
		end)
		
		main_social_friends_searchinput_buffer:SetCallback('onlosefocus', function(widget)
			local text = main_social_friends_searchinput_buffer:GetValue()
			if (text) then
				main_social_friends_searchinput_button:SetVisible(Empty(text))		
				main_social_friends_searchinput_close_btn:SetVisible(not Empty(text))	
				new_friend_window_topbar_searchgo:SetVisible(not Empty(text))	
			else
				main_social_friends_searchinput_close_btn:SetVisible(0)	
				new_friend_window_topbar_searchgo:SetVisible(0)	
				main_social_friends_searchinput_button:FadeIn(125)
			end
			new_friend_window_topbar_search:ScaleWidth('48%', 125)
			main_social_friends_searchinput_close_btn:SlideX('51%', 125)
			main_social_friends_searchinput_button:SlideX('51%', 125)
		end)	
		
		Friends[interfaceName].SearchOnEnter = function (self, identID)

			if Friends.autoCompleteResults and (#Friends.autoCompleteResults == 1) then
				local identID = Friends.autoCompleteResults[1][3]
				if (identID) then
					if ChatClient.IsFriend(identID) then
						AttentionPulse('#FFFF00')
						Friends[interfaceName].FriendListPulseFeedback(Translate('friends_friend_already_friend'), '#FFFF00')
					else
						ChatClient.AddFriend(identID)
						Friends[interfaceName].SearchOnEsc()
						Friends[interfaceName].AttemptUpdate(true, nil)
						AttentionPulse('#00FF00')
						Friends[interfaceName].FriendListPulseFeedback(Translate('friends_friend_added_friend'), '#00FF00')
					end
				else
					AttentionPulse('#da3f3f')
					Friends[interfaceName].FriendListPulseFeedback(Translate('friends_friend_not_found'), '#da3f3f')
				end
			elseif Friends.autoCompleteResults and (#Friends.autoCompleteResults > 1) then
				local text = main_social_friends_searchinput_buffer:GetValue()
				local foundExactMatch = false
				for i,v in pairs(Friends.autoCompleteResults) do
					local name 				= v[1]
					local identID 			= v[3]
					if string.lower(name) == string.lower(text) then
						foundExactMatch = true
						if ChatClient.IsFriend(identID) then
							AttentionPulse('#FFFF00')
							Friends[interfaceName].FriendListPulseFeedback(Translate('friends_friend_already_friend'), '#FFFF00')
						else
							ChatClient.AddFriend(identID)
							Friends[interfaceName].SearchOnEsc()
							Friends[interfaceName].AttemptUpdate(true, nil)
							AttentionPulse('#00FF00')
							Friends[interfaceName].FriendListPulseFeedback(Translate('friends_friend_added_friend'), '#00FF00')
						end
						break
					end
				end
				if (foundExactMatch) then
				
				else
					AttentionPulse('#FFFF00')
					Friends[interfaceName].FriendListPulseFeedback(Translate('friends_friend_dupes_found'), '#FFFF00')
				end
			elseif (not Friends.autoCompleteResults) or ((Friends.autoCompleteResults) and (#Friends.autoCompleteResults == 0)) then
				if (Friends.searchResults) and (#Friends.searchResults >= 1) then
					AttentionPulse('#FFFF00')
					Friends[interfaceName].FriendListPulseFeedback(Translate('friends_friend_matching_friends'), '#FFFF00')			
				else
					AttentionPulse('#da3f3f')
					Friends[interfaceName].FriendListPulseFeedback(Translate('friends_friend_not_found'), '#da3f3f')
				end
			else
				AttentionPulse('#FFFF00')
			end
			main_social_friends_searchinput_buffer:SetFocus(false)	
		end		
	
		Friends[interfaceName].SearchOnEsc = function (self, identID)
			main_social_friends_searchinput_buffer:EraseInputLine()
			main_social_friends_searchinput_buffer:SetFocus(false)	
			main_social_friends_searchinput_coverlabel:SetVisible(true)
			main_social_friends_searchinput_coverlabel:SetText(Translate('general_search'))
			main_social_friends_searchinput_button:FadeIn(125)		
			main_social_friends_searchinput_close_btn:SetVisible(0)	
			main_social_friends_searchinput_button:FadeIn(125)
			new_friend_window_topbar_searchgo:SetVisible(0)	
		end		

		main_social_friends_searchinput_button:SetCallback('onclick', function(widget)
			main_social_friends_searchinput_buffer:SetFocus(true)
			main_social_friends_searchinput_coverlabel:SetText(Translate('general_search'))
		end)	
		
		main_social_friends_searchinput_close_btn:SetCallback('onclick', function(widget)
			Friends[interfaceName].SearchOnEsc()
		end)	
		
		new_friend_window_topbar_searchgo:SetCallback('onclick', function(widget)
			Friends[interfaceName].SearchOnEnter()
		end)
		
		new_friend_window_topbar_addfriend:SetCallback('onclick', function(widget)
			main_social_friends_searchinput_buffer:SetFocus(true)
			main_social_friends_searchinput_coverlabel:SetText(Translate('social_action_bar_add_friend'))
		end)		
	
	end
	
	local function FriendLabelInputRegister(object)
		
		local input_coverup							= interface:GetWidget('friends_label_input_coverup')
		local input_textbox							= interface:GetWidget('friends_label_input_textbox')
		local close_input_button					= interface:GetWidget('friends_label_input_close_button')		
		local friends_edit_info_parent 				= interface:GetWidget('friends_edit_info_parent')
		local friends_edit_info_rename_coverup		= interface:GetWidget('friends_edit_info_rename_coverup')
		local friends_edit_info_rename_textbox		= interface:GetWidget('friends_edit_info_rename_textbox')
		local friends_edit_info_rename_close		= interface:GetWidget('friends_edit_info_rename_close')
		local friends_edit_info_notes_coverup		= interface:GetWidget('friends_edit_info_notes_coverup')
		local friends_edit_info_notes_textbox		= interface:GetWidget('friends_edit_info_notes_textbox')
		local friends_edit_info_notes_close			= interface:GetWidget('friends_edit_info_notes_close')
		
		local function UpdateAndDisplayLabelListbox()
			local friends_label_listbox = interface:GetWidget('friends_label_listbox')
			friends_label_listbox:ClearItems()
			friends_label_listbox:AddTemplateListItem(style_main_dropdownItem, 'remove', 'label', Translate('social_action_bar_remove_label'))
			for i,_ in pairs(Friends.labelTable) do			
				if (i) and (i ~= 'search') and (i ~= 'online') and (i ~= 'ingame') and (i ~= '1') and (i ~= 'offline') and (i ~= 'sent') and (i ~= 'pending') and (i ~= 'ignored') and (i ~= 'recently') and (i ~= 'Default') then
					friends_label_listbox:AddTemplateListItem(style_main_dropdownItem, i, 'label', TranslateOrNil('main_social_groupname_' .. i) or i)
				end
			end	
			friends_label_listbox:Sleep(10, function()
				if (selectedGroup) and (not Empty(selectedGroup)) then
					friends_label_listbox:SetSelectedItemByValue(selectedGroup, true)
				else
					friends_label_listbox:SetSelectedItemByValue('remove', true)
					selectedGroup = 'remove'
				end
			end)
		end		
		
		Friends[interfaceName].LabelInputOnEnter = function()
			Friends.SetSelectedLabelInput(input_textbox:GetValue())
			input_textbox:SetFocus(false)
			UpdateAndDisplayLabelListbox()
		end
		
		Friends[interfaceName].LabelInputOnEsc = function()
			input_textbox:EraseInputLine()
			input_textbox:SetFocus(false)	
			input_coverup:SetVisible(true)
			close_input_button:SetVisible(0)		
		end

		close_input_button:SetCallback('onclick', function(widget)
			Friends.LabelInputOnEsc()
		end)	
		
		input_textbox:SetCallback('onfocus', function(widget)
			input_coverup:SetVisible(false)
			close_input_button:SetVisible(1)
		end)
		
		input_textbox:SetCallback('onlosefocus', function(widget)
			if string.len(widget:GetValue()) == 0 then
				input_coverup:SetVisible(true)
				close_input_button:SetVisible(0)
			end
		end)	
		
		input_textbox:SetCallback('onhide', function(widget)
			 Friends.LabelInputOnEsc()
		end)	
		
		input_textbox:SetCallback('onchange', function(widget)
			selectedGroup = widget:GetValue()
		end)
		
		Friends[interfaceName].SetSelectedLabelInput = function(input)	
			if (input) and (string.len(input) >= 1) then
				selectedGroup = input
				Friends.labelTable[selectedGroup] = true
			end
		end
	
		function Friends.SetSelectedLabelInput(input)
			if (FriendStatusTriggerUI.friendMultiWindowOpen) and (Friends['friends']) and (Friends['friends'].SetSelectedLabelInput) then
				Friends['friends'].SetSelectedLabelInput(input)
			else
				Friends['main'].SetSelectedLabelInput(input)
			end				
		end
	
		Friends[interfaceName].EditFriendInfo = function(identID, currentGroup)	
			
		
			local friendInfo = Friends[interfaceName].GetFriendDataFromIdentID(identID)
			
			if (friendInfo) then
				-- println('^g EditFriendInfo ' .. identID .. ' ' .. currentGroup)
			
				selectedGroup = friendInfo.buddyLabel
				renameFriend = nil
				notesFriend = nil
				editFriendID = friendInfo.identID

				interface:GetWidget('friends_edit_info_parent'):FadeIn(250)

				interface:GetWidget('friends_edit_info_label_1'):SetText(Translate('social_action_bar_username', 'value', friendInfo.trueName or friendInfo.name))
				interface:GetWidget('friends_edit_info_label_2'):SetText(Translate('social_action_bar_unique_id', 'value', friendInfo.uniqueID))
				
				if (mainUI.savedRemotely.friendDatabase) and (mainUI.savedRemotely.friendDatabase[editFriendID]) and (mainUI.savedRemotely.friendDatabase[editFriendID].nicknameOverride) and (not Empty(mainUI.savedRemotely.friendDatabase[editFriendID].nicknameOverride)) then
					friends_edit_info_rename_textbox:SetInputLine(mainUI.savedRemotely.friendDatabase[editFriendID].nicknameOverride)
					friends_edit_info_rename_coverup:SetVisible(0)
					renameFriend = mainUI.savedRemotely.friendDatabase[editFriendID].nicknameOverride
				end	
				
				if (mainUI.savedRemotely.friendDatabase) and (mainUI.savedRemotely.friendDatabase[editFriendID]) and (mainUI.savedRemotely.friendDatabase[editFriendID].friendNote) and (not Empty(mainUI.savedRemotely.friendDatabase[editFriendID].friendNote)) then
					friends_edit_info_notes_textbox:SetInputLine(mainUI.savedRemotely.friendDatabase[editFriendID].friendNote)
					friends_edit_info_notes_coverup:SetVisible(0)
					notesFriend = mainUI.savedRemotely.friendDatabase[editFriendID].friendNote
				end				
				
				UpdateAndDisplayLabelListbox(friendInfo)
			else
				println('No friend info for ' .. tostring(identID))
			end
		end
		
		function Friends.EditFriendInfo(identID, currentGroup)
			if (FriendStatusTriggerUI.friendMultiWindowOpen) and (Friends['friends']) and (Friends['friends'].EditFriendInfo) then
				Friends['friends'].EditFriendInfo(identID, currentGroup)
			else
				Friends['main'].EditFriendInfo(identID, currentGroup)
			end
		end
		
		Friends[interfaceName].SetSelectedLabel = function()	
			if (selectedGroup) and (string.len(selectedGroup) >= 1) then
				if (selectedGroup == 'remove') then
					ChatClient.SetFriendLabel(editFriendID, 'Default') 
				else
					ChatClient.SetFriendLabel(editFriendID, selectedGroup)
				end
			end		
		end
		
		function Friends.SetSelectedLabel()
			if (FriendStatusTriggerUI.friendMultiWindowOpen) and (Friends['friends']) and (Friends['friends'].SetSelectedLabel) then
				Friends['friends'].SetSelectedLabel()
			else
				Friends['main'].SetSelectedLabel()
			end			
		end			
		
		--
		
		Friends[interfaceName].RenameInputOnEnter = function()	
			friends_edit_info_rename_textbox:SetFocus(false)
		end		
		function Friends.RenameInputOnEnter()
			if (FriendStatusTriggerUI.friendMultiWindowOpen) and (Friends['friends']) and (Friends['friends'].RenameInputOnEnter) then
				Friends['friends'].RenameInputOnEnter()
			else
				Friends['main'].RenameInputOnEnter()
			end				
		end
		
		Friends[interfaceName].RenameInputOnEsc = function()	
			friends_edit_info_rename_textbox:EraseInputLine()
			friends_edit_info_rename_textbox:SetFocus(false)	
			friends_edit_info_rename_coverup:SetVisible(true)
			friends_edit_info_rename_close:SetVisible(0)		
		end		
		function Friends.RenameInputOnEsc()
			if (FriendStatusTriggerUI.friendMultiWindowOpen) and (Friends['friends']) and (Friends['friends'].RenameInputOnEsc) then
				Friends['friends'].RenameInputOnEsc()
			else
				Friends['main'].RenameInputOnEsc()
			end				
		end

		friends_edit_info_rename_close:SetCallback('onclick', function(widget)
			if (FriendStatusTriggerUI.friendMultiWindowOpen) and (Friends['friends']) and (Friends['friends'].RenameInputOnEsc) then
				Friends['friends'].RenameInputOnEsc()
			else
				Friends['main'].RenameInputOnEsc()
			end					
		end)	
		
		friends_edit_info_rename_textbox:SetCallback('onfocus', function(widget)
			friends_edit_info_rename_coverup:SetVisible(false)
			friends_edit_info_rename_close:SetVisible(1)
		end)
		
		friends_edit_info_rename_textbox:SetCallback('onlosefocus', function(widget)
			if string.len(widget:GetValue()) == 0 then
				friends_edit_info_rename_coverup:SetVisible(true)
				friends_edit_info_rename_close:SetVisible(0)
			end
		end)	
		
		friends_edit_info_rename_textbox:SetCallback('onhide', function(widget)
			if (FriendStatusTriggerUI.friendMultiWindowOpen) and (Friends['friends']) and (Friends['friends'].RenameInputOnEsc) then
				Friends['friends'].RenameInputOnEsc()
			else
				Friends['main'].RenameInputOnEsc()
			end		
		end)	
		
		friends_edit_info_rename_textbox:SetCallback('onchange', function(widget)
			renameFriend = widget:GetValue()
		end)		
		
		--
		
		Friends[interfaceName].NotesInputOnEnter = function()	
			friends_edit_info_notes_textbox:SetFocus(false)
		end		
		function Friends.NotesInputOnEnter()
			if (FriendStatusTriggerUI.friendMultiWindowOpen) and (Friends['friends']) and (Friends['friends'].NotesInputOnEnter) then
				Friends['friends'].NotesInputOnEnter()
			else
				Friends['main'].NotesInputOnEnter()
			end					
		end
		
		Friends[interfaceName].NotesInputOnEsc = function()	
			friends_edit_info_notes_textbox:EraseInputLine()
			friends_edit_info_notes_textbox:SetFocus(false)	
			friends_edit_info_notes_coverup:SetVisible(true)
			friends_edit_info_notes_close:SetVisible(0)		
		end		
		function Friends.NotesInputOnEsc()
			if (FriendStatusTriggerUI.friendMultiWindowOpen) and (Friends['friends']) and (Friends['friends'].NotesInputOnEsc) then
				Friends['friends'].NotesInputOnEsc()
			else
				Friends['main'].NotesInputOnEsc()
			end				
		end

		friends_edit_info_notes_close:SetCallback('onclick', function(widget)
			if (FriendStatusTriggerUI.friendMultiWindowOpen) and (Friends['friends']) and (Friends['friends'].NotesInputOnEsc) then
				Friends['friends'].NotesInputOnEsc()
			else
				Friends['main'].NotesInputOnEsc()
			end	
		end)	
		
		friends_edit_info_notes_textbox:SetCallback('onfocus', function(widget)
			friends_edit_info_notes_coverup:SetVisible(false)
			friends_edit_info_notes_close:SetVisible(1)
		end)
		
		friends_edit_info_notes_textbox:SetCallback('onlosefocus', function(widget)
			if string.len(widget:GetValue()) == 0 then
				friends_edit_info_notes_coverup:SetVisible(true)
				friends_edit_info_notes_close:SetVisible(0)
			end
		end)	
		
		friends_edit_info_notes_textbox:SetCallback('onhide', function(widget)
			if (FriendStatusTriggerUI.friendMultiWindowOpen) and (Friends['friends']) and (Friends['friends'].NotesInputOnEsc) then
				Friends['friends'].NotesInputOnEsc()
			else
				Friends['main'].NotesInputOnEsc()
			end	
		end)	
		
		friends_edit_info_notes_textbox:SetCallback('onchange', function(widget)
			notesFriend = widget:GetValue()
		end)		
		
		--
		
		interface:GetWidget('friends_label_input_textbox_btn_1'):SetCallback('onclick', function(widget) 
			friends_edit_info_parent:FadeOut(125) 
			Friends.SetSelectedLabel()
			mainUI.savedRemotely.friendDatabase = mainUI.savedRemotely.friendDatabase or {}
			if (renameFriend) and (editFriendID) and (not Empty(editFriendID)) then
				if (not Empty(renameFriend)) then
					mainUI.savedRemotely.friendDatabase[editFriendID] = mainUI.savedRemotely.friendDatabase[editFriendID] or {}
					mainUI.savedRemotely.friendDatabase[editFriendID].nicknameOverride = renameFriend
				else
					mainUI.savedRemotely.friendDatabase[editFriendID] = mainUI.savedRemotely.friendDatabase[editFriendID] or {}
					mainUI.savedRemotely.friendDatabase[editFriendID].nicknameOverride = nil				
				end
				SaveState()
			end
			if (notesFriend) and (editFriendID) and (not Empty(editFriendID)) then
				if  (not Empty(notesFriend)) then
					mainUI.savedRemotely.friendDatabase[editFriendID] = mainUI.savedRemotely.friendDatabase[editFriendID] or {}
					mainUI.savedRemotely.friendDatabase[editFriendID].friendNote = notesFriend
				else
					mainUI.savedRemotely.friendDatabase[editFriendID] = mainUI.savedRemotely.friendDatabase[editFriendID] or {}
					mainUI.savedRemotely.friendDatabase[editFriendID].friendNote = ''
				end
				SaveState()
			end			
		end)
		
		interface:GetWidget('friends_label_close_button'):SetCallback('onclick', function(widget) friends_edit_info_parent:FadeOut(125) end)
		interface:GetWidget('friends_label_input_textbox_btn_2'):SetCallback('onclick', function(widget) friends_edit_info_parent:FadeOut(125) end)
	end
	
	local function FriendStatusBoxRegister(object)
		local main_social_player_card_status_dropdown = GetWidget('main_social_player_card_status_dropdown')
		local currentStatus = '0'
		
		main_social_player_card_status_dropdown:SetCallback('onselect', function(widget)
			local selectedStatus = widget:GetValue()
			if (currentStatus ~= selectedStatus) then
				if (selectedStatus == '0') or (selectedStatus == '3') or (selectedStatus == '6') then -- not supporting 3 or 6 yet
					ChatClient.SetNoStatus(Translate('friend_online_userstatus_0_desc'))
				elseif (selectedStatus == '1') then
					ChatClient.SetLookingForParty(Translate('friend_online_userstatus_1_desc'))
				elseif (selectedStatus == '2') then
					ChatClient.SetPartyLookingForMore(Translate('friend_online_userstatus_2_desc'))
				elseif (selectedStatus == '3') then
					ChatClient.SetStreaming(Translate('friend_online_userstatus_3_desc'))
				elseif (selectedStatus == '4') then
					ChatClient.SetAwayFromKeyboard(Translate('friend_online_userstatus_4_desc'))
				elseif (selectedStatus == '5') then
					ChatClient.SetDoNotDisturb(Translate('friend_online_userstatus_5_desc'))
				elseif (selectedStatus == '6') then
					ChatClient.SetStatusesHidden(Translate('friend_online_userstatus_6_desc'))
				elseif (selectedStatus == '7') then
					ChatClient.SetInvisible(Translate('friend_online_userstatus_7_desc'))
				end
			end
		end)
		
		main_social_player_card_status_dropdown:RegisterWatchLua('AccountInfo', function(widget, trigger)
			local identID = trigger.identID
			if (IsFullyLoggedIn(identID)) then
				local localPlayerClientInfo = LuaTrigger.GetTrigger('ChatClientInfo' .. string.gsub(identID, '%.', ''))
				if (localPlayerClientInfo) then

					local lastRun = -1
					local function UpdateLocalPlayerStatus(widget, trigger)
						if (lastRun + 100 >= GetTime()) then return end -- Twice in 100 milliseconds, ignore it.
						lastRun = GetTime()
						--println("UpdateLocalPlayerStatus " .. trigger.identID)

						local userStatus = trigger.userStatus
						if (userStatus == '3') or (userStatus == '6') then -- not supporting 3 or 6 yet
							userStatus = '0'
						end
						if (interface) and (interface:IsValid()) and (interface:GetWidget('main_social_player_card_status_dropdown')) and (interface:GetWidget('main_social_player_card_status_dropdown'):IsValid()) then
							interface:GetWidget('main_social_player_card_status_dropdown'):SetSelectedItemByValue(trigger.userStatus)
							interface:GetWidget('main_social_player_card_status_current_label'):SetText(Translate('friend_online_userstatus_' .. trigger.userStatus))
							interface:GetWidget('main_social_player_card_status_current_icon'):SetColor(Translate('friend_online_userstatus_' .. trigger.userStatus..'_color'))
							interface:GetWidget('main_social_player_card_status_current'):RecalculateSize()
							interface:GetWidget('main_social_player_card_status_current'):RecalculatePosition()							
						end
						currentStatus = userStatus
					end
					UnwatchLuaTriggerByKey('ChatClientInfo' .. string.gsub(identID, '%.', ''), interfaceName .. 'StatusUpdater'..'ChatClientInfo' .. string.gsub(identID, '%.', ''))
					WatchLuaTrigger('ChatClientInfo' .. string.gsub(identID, '%.', ''), function(trigger)
						 UpdateLocalPlayerStatus(main_social_player_card_status_dropdown, trigger)
					end,  interfaceName .. 'StatusUpdater'..'ChatClientInfo' .. string.gsub(identID, '%.', ''), 'userStatus')
					UpdateLocalPlayerStatus(main_social_player_card_status_dropdown, localPlayerClientInfo)
				end
			end
		end)
		
		-- interface:GetWidget('main_social_player_card_status_current'):SetCallback('onclick', function(widget)
			-- interface:GetWidget('main_social_player_card_status_current'):SetVisible(0)	
			-- interface:GetWidget('main_social_player_card_status_dropdown'):SetVisible(1)
			-- interface:GetWidget('main_social_player_card_status_dropdown_listbox'):SetVisible(1)
			-- interface:GetWidget('main_social_player_card_status_dropdown'):SetFocus(true)
		-- end)		
		
		-- main_social_player_card_status_dropdown:SetCallback('onshow', function(widget)

		-- end)		
		
		-- main_social_player_card_status_dropdown:SetCallback('onhide', function(widget)
			-- interface:GetWidget('main_social_player_card_status_dropdown_listbox'):SetVisible(0)
			-- interface:GetWidget('main_social_player_card_status_current'):SetVisible(1)		
		-- end)		
		
		-- main_social_player_card_status_dropdown:SetCallback('onlosefocus', function(widget)
			-- main_social_player_card_status_dropdown:SetVisible(0)
			-- interface:GetWidget('main_social_player_card_status_dropdown_listbox'):SetVisible(0)
			-- interface:GetWidget('main_social_player_card_status_current'):SetVisible(1)		
		-- end)
		
		-- main_social_player_card_status_dropdown:SetVisible(0)
		
		-- interface:GetWidget('main_social_player_card_status_dropdown_listbox'):SetCallback('onhide', function(widget)
			-- main_social_player_card_status_dropdown:SetVisible(0)
			-- interface:GetWidget('main_social_player_card_status_current'):SetVisible(1)
		-- end)
		
	end
	
	FriendStatusBoxRegister(object)
	FriendLabelInputRegister(object)	
	FriendsDataRegister(object)	
	FriendsUpdateRegister(object)
	FriendsScrollRegister(object)
	FriendsSearchRegister(object)
	Friends[interfaceName].AttemptUpdate(true, nil)
	
	Friends.SnapToLauncher = function()
		
		-- println('^c SnapToLauncher ')
		
		if GetCvarBool('ui_friendsCanDockAnywhere') then
			Windows.MoveLauncherFriendListToFriendWindowLocation()
		else
			Windows.MoveLauncherFriendListToDefaultLocation()
		end

		Windows.state.FriendsVisible = false
		FriendStatusTriggerUI.friendLauncherWindowOpen = true		
		FriendStatusTriggerUI.friendMultiWindowOpen = false		
		FriendStatusTriggerUI.friendLastUsedMethod = 'launcher'
		FriendStatusTriggerUI:Trigger(true)		
		mainUI 													= mainUI or {}
		mainUI.savedLocally 									= mainUI.savedLocally or {}
		mainUI.savedLocally.friendsSettings 					= mainUI.savedLocally.friendsSettings or {}				
		mainUI.savedLocally.friendsSettings.lastMethod = 'launcher'
		SaveState()		
	end
	
	Friends.SaveWindowPositionAndSize = function(windowRef, windowFriendsWindowWidget)
		mainUI 													= mainUI or {}
		mainUI.savedLocally 									= mainUI.savedLocally or {}
		mainUI.savedLocally.friendsSettings 					= mainUI.savedLocally.friendsSettings or {}			
		mainUI.savedLocally.friendsSettings.windowX 			= windowRef:GetX()
		mainUI.savedLocally.friendsSettings.windowY 			= windowRef:GetY()
		-- mainUI.savedLocally.friendsSettings.windowHeight 		= windowFriendsWindowWidget:GetHeight()
		-- mainUI.savedLocally.friendsSettings.windowWidth 		= windowFriendsWindowWidget:GetWidth()
		SaveState()	
	end
	
	Friends.SnapToLauncherIfPossible = function()
		
		-- println('^c SnapToLauncherIfPossible ')
		
		local launcherMainInterfaceWidget = UIManager.GetInterface('main')
		local launcherFriendsWindowWidget = UIManager.GetInterface('main'):GetWidget('social_client_sizingframe')
		
		if (Windows.Friends) and (launcherFriendsWindowWidget) then		
			
			local windowFriendsWindowWidget = Windows.Friends:GetInterface('friends'):GetWidget('social_client_sizingframe')
			
			if (windowFriendsWindowWidget) then
				
				local launcherLeftBound, launcherTopBound 		= System.WindowClientToScreen(0, 0)
				local launcherRightBound, launcherBottomBound 	= System.WindowClientToScreen(launcherMainInterfaceWidget:GetWidth(), launcherMainInterfaceWidget:GetHeight()) -- GetScreenWidth(), GetScreenHeight() seem to be using the window they are called from
				
				local friendsWindowLeftBound, friendsWindowTopBound = Windows.Friends:GetX(), Windows.Friends:GetY()
				local friendsWindowRightBound, friendsWindowBottomBound = friendsWindowLeftBound + Windows.Friends:GetWidth(), friendsWindowTopBound + Windows.Friends:GetHeight()
				
				
				if  (friendsWindowLeftBound >= launcherLeftBound) and
					(friendsWindowRightBound <= launcherRightBound) and
					(friendsWindowTopBound >= launcherTopBound) and
					(friendsWindowBottomBound <= launcherBottomBound) then
					Friends.SnapToLauncher()
				end
			end
			Friends.SaveWindowPositionAndSize(Windows.Friends, windowFriendsWindowWidget)
		end		
	end	
	
	local function FriendsLauncherRegister(object)
		
		-- println('^o FriendsLauncherRegister ')		

		social_client_sizingframe:SetCallback('onshow', function(widget)
			Friends[interfaceName].AttemptUpdate(true, nil)
		end)

		social_client_sizingframe:SetCallback('onmouselup', function(widget)
			-- println('^r FriendsLauncherRegister onmouselup ')
			widget:ClearCallback('onframe')
			Friends.SnapToLauncherIfPossible()
		end)	
		
		social_client_sizingframe:SetCallback('onclick', function(widget)
			-- println('^r FriendsLauncherRegister onclick ')
			widget:ClearCallback('onframe')
			Friends.SnapToLauncherIfPossible()
			Friends[interfaceName].AttemptUpdate(true, nil)
		end)
		
		interface:GetWidget('social_client_sizingframe_dragbar_launcher'):SetCallback('onclick', function(widget, x, y)
			Windows.MoveFriendWindowToLauncherFriendListLocation(widget)
			Windows.GoToFriendWindowMode(widget)
			Windows.StartDraggingFriendWindow(widget, x, y)
		end)			
		
		interface:GetWidget('social_client_sizingframe_dragbar_launcher'):SetCallback('onmouseover', function(widget, x, y)
			UpdateCursor(self, true, { canLeftClick = false, canRightClick = false, spendGems = false, canDrag = true })
		end)
		
		interface:GetWidget('social_client_sizingframe_dragbar_launcher'):SetCallback('onmouseout', function(widget, x, y)
			UpdateCursor(self, false, { canLeftClick = false, canRightClick = false, spendGems = false, canDrag = true })
		end)	
		
		social_client_sizingframe:SetAbsoluteX(interface:GetXFromString(defFriendsLauncherX))
		social_client_sizingframe:SetAbsoluteY(interface:GetYFromString(defFriendsLauncherY))
		GetWidget('new_friend_window_topbar_optionsclose'):SetVisible(1)
		
		local function UpdateFriendsFooterToggleButton(widget, trigger)
			if (trigger.authenticated) and (trigger.connected) and (not GetCvarBool('ui_PAXDemo')) then
				widget:FadeIn(500)
				GetWidget('friends_footer_buttonLabel'):FadeIn(250)			
			else
				widget:FadeOut(250)
				GetWidget('friends_footer_buttonLabel'):FadeOut(250)		
			end		
		end

		GetWidget('friends_footer_buttonNotificationBaseIcon'):SetCallback('onshow', function(widget)
			widget:RegisterWatchLua('CountDownSeconds', function(widget, trigger)
				if ((trigger.timeSeconds % 30) == 0) then
					widget:UICmd([[StartAnim(1)]])
					libThread.threadFunc(function()
						wait(3000)
						local widget = GetWidget('friends_footer_buttonNotificationBaseIcon')
						if (widget) then
							widget:UICmd([[StartAnim(0)]])
						end
					end)
				end
			end)
			widget:UICmd([[StartAnim(1)]])
			libThread.threadFunc(function()
				wait(3000)
				local widget = GetWidget('friends_footer_buttonNotificationBaseIcon')
				if (widget) then
					widget:UICmd([[StartAnim(0)]])
				end
			end)			
		end)
		
		GetWidget('friends_footer_buttonNotificationBaseIcon'):SetCallback('onhide', function(widget)
			widget:UnregisterWatchLua('CountDownSeconds')
			widget:UICmd([[StartAnim(0)]])
		end)		
		
		GetWidget('friends_footer_button'):RegisterWatchLua('ChatConnectionStatus', function(widget, trigger)
			UpdateFriendsFooterToggleButton(widget, trigger)
		end, false, nil, 'authenticated', 'connected')	
		
		GetWidget('friends_footer_buttonPartyTime'):RegisterWatchLua('notificationsTrigger', function(widget, trigger)
			if (trigger.partyInvites > 0) then
				widget:SetVisible(1)
			else
				widget:SetVisible(0)
			end	
		end, false, nil, 'partyInvites')		
		
		UpdateFriendsFooterToggleButton(GetWidget('friends_footer_button'), LuaTrigger.GetTrigger('ChatConnectionStatus'))
		
		function Windows.MoveLauncherFriendListToFriendWindowLocation()

			local launcherFriendsWindowWidget = UIManager.GetInterface('main'):GetWidget('social_client_sizingframe')
			
			if (Windows.Friends) and (launcherFriendsWindowWidget) then
				local windowFriendsWindowWidget = Windows.Friends:GetInterface('friends'):GetWidget('social_client_sizingframe')
				if (windowFriendsWindowWidget) then
					local clientX, clientY = System.WindowScreenToClient(Windows.Friends:GetX(), Windows.Friends:GetY())

					launcherFriendsWindowWidget:SetAbsoluteX(clientX)
					launcherFriendsWindowWidget:SetAbsoluteY(clientY)
				end
			end
		end		
		
		function Windows.MoveLauncherFriendListToDefaultLocation()
			local launcherFriendsWindowWidget = UIManager.GetInterface('main'):GetWidget('social_client_sizingframe')
			if (launcherFriendsWindowWidget) then
				launcherFriendsWindowWidget:SetAbsoluteX(UIManager.GetInterface('main'):GetXFromString(defFriendsLauncherX))
				launcherFriendsWindowWidget:SetAbsoluteY(UIManager.GetInterface('main'):GetYFromString(defFriendsLauncherY))
			end
		end			
		
		function Windows.MoveFriendWindowToLauncherFriendListLocation()
			
			-- println('MoveFriendWindowToLauncherFriendListLocation ')
			
			local launcherFriendsWindowWidget = UIManager.GetInterface('main'):GetWidget('social_client_sizingframe')
			
			if (Windows.Friends) and (launcherFriendsWindowWidget) then
				local targetClientX = launcherFriendsWindowWidget:GetAbsoluteX()
				local targetClientY = launcherFriendsWindowWidget:GetAbsoluteY()

				local targetScreenX, targetScreenY = System.WindowClientToScreen(targetClientX, targetClientY)

				Windows.Friends:Move(targetScreenX, targetScreenY)

			end
		end
		
		function Windows.StartDraggingFriendWindow(widget, x, y)
			
			-- println('StartDraggingFriendWindow ')
			
			local launcherFriendsWindowWidget = UIManager.GetInterface('main'):GetWidget('social_client_sizingframe')
			
			if (widget) and (Windows.Friends) and (launcherFriendsWindowWidget) then
				local targetClientX = x - widget:GetX()
				local targetClientY = y - widget:GetY()

				Windows.Friends:StartDrag2(targetClientX, targetClientY, targetClientX, targetClientY, Friends.SnapToLauncherIfPossible)
				
				launcherFriendsWindowWidget:ClearCallback('onframe')

			end
		end		
		
		function Windows.SilentlySpawnFriends()
			-- println('^c SilentlySpawnFriends ')
			local widget = interface
			if (not Windows.Friends) and (not Windows.state.FriendsVisible) then
				local width = widget:GetWidthFromString(friendsWindowWidth)
				local height = widget:GetHeightFromString(friendsWindowHeight)
				Windows.Friends = Windows.Friends or Window.New(
					interface:GetXFromString(friendsWindowX),
					interface:GetYFromString(friendsWindowY),
					width,
					height,
					{
						Window.BORDERLESS,
						Window.THREADED,
						Window.COMPOSITE,
						Window.RESIZABLE,
						-- Window.CENTER,
						Window.HIDDEN,
						Window.POSITION,
					},
					"/ui_dev/friends/friends_window.interface",
					Translate('window_name_strife_friends')
				)
				
				Windows.Friends:SetSizingBounds(widget:GetWidthFromString(defFriendsWindowWidth), (widget:GetHeightFromString(defFriendsWindowHeight) * 0.5), widget:GetWidthFromString(defFriendsWindowWidth), (widget:GetHeightFromString(defFriendsWindowHeight) * 1.5))
				Windows.Friends:SetCloseCallback(function()
					-- println('FRIENDS WINDOW WAS CLOSED 1')
					Windows.Friends = nil
					Windows.state.FriendsVisible = false	
					FriendStatusTriggerUI.friendMultiWindowOpen = false					
					FriendStatusTriggerUI:Trigger(false)
				end)
			end
		end			
		
		function Windows.SpawnFriends(widget)
			-- println('^c SpawnFriends ')
			local widget = widget or interface
			if (Windows.Friends) and (not Windows.state.FriendsVisible) then
				Windows.Friends:Restore()	
				Windows.Friends:MakeFrontActiveWindow()	
				-- Windows.Friends:GetInterface('friends'):GetWidget('social_client_frame_flasher'):FadeIn(250, function(self) self:FadeOut(750) end) 
				Windows.state.FriendsVisible = true
				FriendStatusTriggerUI.friendLauncherWindowOpen = false		
				FriendStatusTriggerUI.friendMultiWindowOpen = true		
				FriendStatusTriggerUI.friendLastUsedMethod = 'window'
				FriendStatusTriggerUI:Trigger(true)
				mainUI 													= mainUI or {}
				mainUI.savedLocally 									= mainUI.savedLocally or {}
				mainUI.savedLocally.friendsSettings 					= mainUI.savedLocally.friendsSettings or {}						
				mainUI.savedLocally.friendsSettings.lastMethod = 'window'
				SaveState()				
			elseif (not Windows.state.FriendsVisible) then
				local width = widget:GetWidthFromString(friendsWindowWidth)
				local height = widget:GetHeightFromString(friendsWindowHeight)
				Windows.Friends = Windows.Friends or Window.New(
					interface:GetXFromString(friendsWindowX),
					interface:GetYFromString(friendsWindowY),
					width,
					height,
					{
						Window.BORDERLESS,
						Window.THREADED,
						Window.COMPOSITE,
						Window.RESIZABLE,
						-- Window.CENTER,
						Window.HIDDEN,
						Window.POSITION,
					},
					"/ui_dev/friends/friends_window.interface",
					Translate('window_name_strife_friends')
				)
				local someoneIsLyingAboutTheirWidth = widget:GetWidthFromString('16s')
				Windows.Friends:SetSizingBounds(widget:GetWidthFromString(defFriendsWindowWidth) + someoneIsLyingAboutTheirWidth, (widget:GetHeightFromString(defFriendsWindowHeight) * 0.5), widget:GetWidthFromString(defFriendsWindowWidth) + someoneIsLyingAboutTheirWidth, (widget:GetHeightFromString(defFriendsWindowHeight) * 1.5))				
				Windows.Friends:SetCloseCallback(function()
					-- println('FRIENDS WINDOW WAS CLOSED 2')
					Windows.Friends = nil
					Windows.state.FriendsVisible = false
					FriendStatusTriggerUI.friendMultiWindowOpen = false					
					FriendStatusTriggerUI:Trigger(false)
				end)				
				FriendStatusTriggerUI.friendLauncherWindowOpen = false		
				FriendStatusTriggerUI.friendMultiWindowOpen = true
				FriendStatusTriggerUI.friendLastUsedMethod = 'window'				
				FriendStatusTriggerUI:Trigger(true)
				mainUI 													= mainUI or {}
				mainUI.savedLocally 									= mainUI.savedLocally or {}
				mainUI.savedLocally.friendsSettings 					= mainUI.savedLocally.friendsSettings or {}						
				mainUI.savedLocally.friendsSettings.lastMethod = 'window'
				SaveState()	
			elseif (Windows.Friends) then
				Windows.Friends:MakeFrontActiveWindow()				
				Windows.Friends:GetInterface('friends'):GetWidget('social_client_frame_flasher'):FadeIn(250, function(self) self:FadeOut(450) end)
			end
		end	
		
		function Windows.ToggleFriends(widget)
			-- println('^c ToggleFriends ')
			if Windows.state.FriendsVisible then
				Windows.state.FriendsVisible = false
				if (Windows.Friends) then
					Windows.Friends:Hide(true)	
				end			
				FriendStatusTriggerUI.friendLauncherWindowOpen = true		
				FriendStatusTriggerUI.friendLastUsedMethod = 'launcher'
				FriendStatusTriggerUI.friendMultiWindowOpen = false		
				FriendStatusTriggerUI:Trigger(false)		
				mainUI 													= mainUI or {}
				mainUI.savedLocally 									= mainUI.savedLocally or {}
				mainUI.savedLocally.friendsSettings 					= mainUI.savedLocally.friendsSettings or {}						
				mainUI.savedLocally.friendsSettings.lastMethod = 'launcher'
				SaveState()					
			else
				Windows.SpawnFriends(widget)
			end
		end	
		
		function Windows.GoToFriendWindowMode(widget)
			-- println('^c GoToFriendWindowMode ')
			Windows.SpawnFriends(widget)
		end		
		
		function Windows.GoToFriendLauncherMode(widget)
			-- println('^c GoToFriendLauncherMode ')
			Windows.state.FriendsVisible = false
			if (Windows.Friends) then
				Windows.Friends:Hide(true)	
			end			
			FriendStatusTriggerUI.friendLauncherWindowOpen = true	
			FriendStatusTriggerUI.friendLastUsedMethod = 'launcher'			
			FriendStatusTriggerUI.friendMultiWindowOpen = false		
			FriendStatusTriggerUI:Trigger(false)	
			mainUI 													= mainUI or {}
			mainUI.savedLocally 									= mainUI.savedLocally or {}
			mainUI.savedLocally.friendsSettings 					= mainUI.savedLocally.friendsSettings or {}					
			mainUI.savedLocally.friendsSettings.lastMethod = 'launcher'
			SaveState()			
		end			
		
		function Windows.CloseFriendWindow(widget)
			-- println('^c CloseFriendWindow ')
			Windows.state.FriendsVisible = false
			if (Windows.Friends) then
				Windows.Friends:Hide(true)	
			end				
			FriendStatusTriggerUI.friendMultiWindowOpen = false		
			FriendStatusTriggerUI:Trigger(false)		
		end			

		social_client_sizingframe:RegisterWatchLua('FriendStatusTriggerUI', function(widget, trigger)
			if (trigger.friendLauncherWindowOpen) then
				Friends[interfaceName].OpenFriendsList()
			else
				if (not trigger.friendMultiWindowOpen) then
					Friends[interfaceName].CloseFriendsList()
				else
					libThread.threadFunc(function()	
						wait(100)
						Friends[interfaceName].CloseFriendsList()
					end)
				end
			end
		end)	
		FriendStatusTriggerUI.friendLauncherWindowOpen = false
		FriendStatusTriggerUI:Trigger(false)			
		
		social_client_sizingframe:RefreshCallbacks()

		local function IsThereRoomForFriendsAndTheLauncher()

			local left, top, right, bottom = System.GetWindowDesktopArea(false)		
			local currentDisplayHeight = bottom - top
			local currentDisplayWidth = right - left
		
			local activeDesktopWindowHeight = currentDisplayHeight
			local activeDesktopWindowWidth = currentDisplayWidth

			local launcherMainInterfaceWidget 					= UIManager.GetInterface('main')
			
			local launcherWidth 								= launcherMainInterfaceWidget:GetWidth()
			local launcherHeight 								= launcherMainInterfaceWidget:GetHeight()
			
			local paddingToEitherSideOfLauncher = (activeDesktopWindowWidth - launcherWidth) / 2
			
			return ( ((interface:GetWidthFromString(friendsWindowWidth) + launcherWidth) <= interface:GetWidthFromString(activeDesktopWindowWidth)) ), ( ((interface:GetWidthFromString(friendsWindowWidth) + launcherWidth) <= (interface:GetWidthFromString(activeDesktopWindowWidth) - paddingToEitherSideOfLauncher)) )
		end
		
		local function ClampFriendsWindowPosition()

			local left, top, right, bottom = System.GetWindowDesktopArea(false)		
			local currentDisplayHeight = bottom - top
			local currentDisplayWidth = right - left		
		
			local launcherMainInterfaceWidget 					= UIManager.GetInterface('main')
			local launcherHeight 								= launcherMainInterfaceWidget:GetHeight()
			local launcherWidth 								= launcherMainInterfaceWidget:GetWidth()
			
			local activeDesktopWindowHeight = currentDisplayHeight
			local activeDesktopWindowWidth = currentDisplayWidth
			
			local isThereRoom, isThereRoomWithPadding = IsThereRoomForFriendsAndTheLauncher()
			
			if isThereRoom and isThereRoomWithPadding then
				defFriendsWindowX = System.GetWindowX() + launcherWidth + 5
				defFriendsWindowY = ((activeDesktopWindowHeight - launcherHeight) / 2) - 1
			else
				defFriendsWindowX = (System.GetWindowX() + launcherWidth + 5) - interface:GetWidthFromString(friendsWindowWidth)
				defFriendsWindowY = ((activeDesktopWindowHeight - launcherHeight) / 2) - 15
			end
			
			if (mainUI.savedLocally.friendsSettings.windowX == nil) then
				mainUI.savedLocally.friendsSettings.windowX = defFriendsWindowX
				-- println('^r mainUI.savedLocally.friendsSettings.windowX ' .. tostring(mainUI.savedLocally.friendsSettings.windowX))
			else
				-- println('^g mainUI.savedLocally.friendsSettings.windowX ' .. tostring(mainUI.savedLocally.friendsSettings.windowX))
			end
			
			if (mainUI.savedLocally.friendsSettings.windowY == nil) then
				mainUI.savedLocally.friendsSettings.windowY = defFriendsWindowY
			end				
				
			local xPositionIsValid = false
			for _, v in pairs(System.GetAllMonitorRects()) do
				if (((interface:GetXFromString(mainUI.savedLocally.friendsSettings.windowX)) + interface:GetWidthFromString(mainUI.savedLocally.friendsSettings.windowWidth)) <= (v.left + v.right)) 
				and (((interface:GetYFromString(mainUI.savedLocally.friendsSettings.windowY)) + interface:GetHeightFromString(mainUI.savedLocally.friendsSettings.windowHeight)) <= (v.top + v.bottom)) then
					xPositionIsValid = true
				end
			end
			
			if (not xPositionIsValid) then
				mainUI.savedLocally.friendsSettings.windowY = defFriendsWindowY
				mainUI.savedLocally.friendsSettings.windowX = defFriendsWindowX
				-- println('^r INVALID - SET TO DEFAULT - mainUI.savedLocally.friendsSettings.windowX ' .. tostring(mainUI.savedLocally.friendsSettings.windowX))
			else
				-- println('^g VALID - Leave as is - mainUI.savedLocally.friendsSettings.windowX ' .. tostring(mainUI.savedLocally.friendsSettings.windowX))
			end
			
			friendsWindowX = mainUI.savedLocally.friendsSettings.windowX
			friendsWindowY = mainUI.savedLocally.friendsSettings.windowY
			
		end		
		
		local function QueueAutoOpenFriendsList()
			UnwatchLuaTriggerByKey('mainPanelStatus', 'mainPanelStatusFriendsAutoOpen')
			WatchLuaTrigger('mainPanelStatus', function(trigger)
				if (trigger.chatConnectionState >= 1) and (trigger.hasIdent) and (trigger.isLoggedIn) and (not trigger.hideSecondaryElements) then
					if (mainUI.savedLocally) and (mainUI.savedLocally.friendsSettings) and (mainUI.savedLocally.friendsSettings.lastState) and (mainUI.savedLocally.friendsSettings.lastState == 'open') then
						FriendStatusTriggerUI.friendLauncherWindowOpen = false
						FriendStatusTriggerUI.friendMultiWindowOpen = true
						FriendStatusTriggerUI:Trigger(true)
					end
					UnwatchLuaTriggerByKey('mainPanelStatus', 'mainPanelStatusFriendsAutoOpen')
				end
			end, 'mainPanelStatusFriendsAutoOpen', 'chatConnectionState', 'hasIdent', 'isLoggedIn', 'hideSecondaryElements')
		end
		
		local function InitialiseAndRestoreFriends(object)
			libThread.threadFunc(function()	

				FriendStatusTriggerUI.friendLauncherWindowOpen = false
				FriendStatusTriggerUI.friendMultiWindowOpen = false	
				
				wait(1)
				mainUI.savedLocally 												= mainUI.savedLocally or {}
				mainUI.savedLocally.friendsSettings 								= mainUI.savedLocally.friendsSettings or {}
				mainUI.savedLocally.friendsSettings.windowHeight 					= mainUI.savedLocally.friendsSettings.windowHeight or friendsWindowHeight
				mainUI.savedLocally.friendsSettings.windowWidth 					= mainUI.savedLocally.friendsSettings.windowWidth or friendsWindowWidth
				mainUI.savedLocally.friendsSettings.lastMethod 						= mainUI.savedLocally.friendsSettings.lastMethod or 'launcher'
				mainUI.savedLocally.friendsSettings.lastState 						= mainUI.savedLocally.friendsSettings.lastState or 'closed'

				friendsWindowHeight													= mainUI.savedLocally.friendsSettings.windowHeight
				friendsWindowWidth 													= mainUI.savedLocally.friendsSettings.windowWidth
				FriendStatusTriggerUI.friendLastUsedMethod 							= mainUI.savedLocally.friendsSettings.lastMethod or 'launcher'						
				
				if (mainUI.savedLocally.friendsSettings.lastMethod == 'window') then
					local isThereRoom, isThereRoomWithPadding = IsThereRoomForFriendsAndTheLauncher()
					if isThereRoom and isThereRoomWithPadding then
						-- println('Open in window from saved settings')
						mainUI.savedLocally.friendsSettings.lastMethod = 'window'
						FriendStatusTriggerUI.friendLastUsedMethod = 'window'							
						ClampFriendsWindowPosition()
						Windows.SilentlySpawnFriends(object)
						QueueAutoOpenFriendsList()
					else
						friendsWindowHeight = defFriendsWindowHeight
						friendsWindowWidth = defFriendsWindowWidth
						local isThereRoom, isThereRoomWithPadding = IsThereRoomForFriendsAndTheLauncher()
						if isThereRoom then
							-- println('Open in window from default settings')
							mainUI.savedLocally.friendsSettings.lastMethod = 'window'
							FriendStatusTriggerUI.friendLastUsedMethod = 'window'							
							ClampFriendsWindowPosition()
							Windows.SilentlySpawnFriends(object)
							QueueAutoOpenFriendsList()
						else
							-- println('Cannot open in window, using launcher instead')
							mainUI.savedLocally.friendsSettings.lastMethod = 'launcher'
							FriendStatusTriggerUI.friendLastUsedMethod = 'launcher'
							ClampFriendsWindowPosition()
							Windows.SilentlySpawnFriends(object)					
						end
					end
				else
					-- println('Open in launcher from user setting')
					mainUI.savedLocally.friendsSettings.lastMethod = 'launcher'
					FriendStatusTriggerUI.friendLastUsedMethod = 'launcher'
					friendsWindowHeight = defFriendsWindowHeight
					friendsWindowWidth = defFriendsWindowWidth					
					ClampFriendsWindowPosition()
					Windows.SilentlySpawnFriends(object)
				end
				
			end)
		end
		
		local ChatConnectionStatus = LuaTrigger.GetTrigger('ChatConnectionStatus')
		if (ChatConnectionStatus.authenticated) and (ChatConnectionStatus.connected) then
			InitialiseAndRestoreFriends(object)		
		else
			social_client_sizingframe:RegisterWatchLua('ChatConnectionStatus', function(widget, trigger)
				if (trigger.authenticated) and (trigger.connected) then
					InitialiseAndRestoreFriends(object)					
				end	
			end, false, nil, 'authenticated', 'connected')			
		end	
		
		-- println('^o /FriendsLauncherRegister ')
		
	end
	
	local function FriendsWindowRegister(object)
			
		-- println('^o FriendsWindowRegister ')	
			
		social_client_sizingframe:SetCallback('onshow', function(widget)
			Friends[interfaceName].AttemptUpdate(true, nil)
		end)			
		
		social_client_sizingframe:SetCallback('onclick', function(widget)
			widget:ClearCallback('onframe')		
		end)			
	
		social_client_sizingframe:SetCallback('onmouselup', function(widget)
			widget:ClearCallback('onframe')		
			Friends.SnapToLauncherIfPossible()
			Friends[interfaceName].AttemptUpdate(true, nil)
		end)		
	
		social_client_sizingframe:SetCallback('onmouseldown', function(widget)
			widget:ClearCallback('onframe')
		end)
		
		social_client_sizingframe:SetCallback('onstartdrag', function(widget)
			widget:ClearCallback('onframe')
		end)
		
		social_client_sizingframe:SetCallback('onenddrag', function(widget)
			-- println('^r FriendsWindowRegister onenddrag ')
			widget:ClearCallback('onframe')
			Friends.SnapToLauncherIfPossible()
			Friends[interfaceName].AttemptUpdate(true, nil)
		end)

		-- == Top drag bar
			
		interface:GetWidget('social_client_sizingframe_dragbar_window_1'):SetCallback('onclick', function(widget, x, y)
			widget:GetParent():GetWindow():StartDrag2(
				x + widget:GetParentAbsoluteX(),
				y + widget:GetParentAbsoluteY(),
				x + widget:GetParentAbsoluteX(),
				y + widget:GetParentAbsoluteY(),
				Friends.SnapToLauncherIfPossible)
			widget:ClearCallback('onframe')
		end)			

		interface:GetWidget('social_client_sizingframe_dragbar_window_1'):SetCallback('onmouseldown', function(widget)
			widget:ClearCallback('onframe')
		end)		
		
		interface:GetWidget('social_client_sizingframe_dragbar_window_1'):SetCallback('onmouselup', function(widget, x, y)
			widget:ClearCallback('onframe')		
			Friends.SnapToLauncherIfPossible()
		end)		
		
		interface:GetWidget('social_client_sizingframe_dragbar_window_1'):SetCallback('onstartdrag', function(widget)
			-- println('^g FriendsWindowRegister onstartdrag ')
			widget:ClearCallback('onframe')
		end)
		
		interface:GetWidget('social_client_sizingframe_dragbar_window_1'):SetCallback('onenddrag', function(widget)
			-- println('^r FriendsWindowRegister onenddrag ')
			widget:ClearCallback('onframe')
			Friends.SnapToLauncherIfPossible()
			Friends[interfaceName].AttemptUpdate(true, nil)
		end)
		
		-- == Bottom Drag Bar
		
		interface:GetWidget('social_client_sizingframe_dragbar_window_2'):SetCallback('onclick', function(widget, x, y)
			widget:GetParent():GetWindow():StartDrag2(
				x + widget:GetParentAbsoluteX(),
				y + widget:GetParentAbsoluteY(),
				x + widget:GetParentAbsoluteX(),
				y + widget:GetParentAbsoluteY(),
				Friends.SnapToLauncherIfPossible)
		end)		
		
		-- ==
		
		interface:GetWidget('friends_window_interface_sizingframe'):SetCallback('onstartdrag', function(widget)
			widget:ClearCallback('onframe')
			-- widget:SetCallback('onframe', function(widget)
				-- Friends[interfaceName].AttemptUpdate(true, nil)
			-- end)
		end)
		
		interface:GetWidget('friends_window_interface_sizingframe'):SetCallback('onenddrag', function(widget)
			widget:ClearCallback('onframe')
			Friends.SnapToLauncherIfPossible()
			Friends[interfaceName].AttemptUpdate(true, nil)
		end)
		
		interface:GetWidget('friends_window_interface_sizingframe'):SetCallback('onmouseldown', function(widget)
			widget:ClearCallback('onframe')
			-- widget:SetCallback('onframe', function(widget)
				-- Friends[interfaceName].AttemptUpdate(true, nil)
			-- end)
		end)
		
		interface:GetWidget('friends_window_interface_sizingframe'):SetCallback('onmouselup', function(widget)
			widget:ClearCallback('onframe')
			Friends.SnapToLauncherIfPossible()
			Friends[interfaceName].AttemptUpdate(true, nil)
		end)		

		interface:GetWidget('friends_window_interface_sizingframe'):SetCallback('onclick', function(widget)
			widget:ClearCallback('onframe')
			-- widget:SetCallback('onframe', function(widget)
				-- Friends[interfaceName].AttemptUpdate(true, nil)
			-- end)		
		end)

		-- ==
	
		social_client_sizingframe:SetX('0s')
		social_client_sizingframe:SetY('0s')		
		GetWidget('new_friend_window_topbar_optionsclose'):SetVisible(1)
		GetWidget('new_friend_window_topbar_optionsmin'):SetVisible(1)
		
		social_client_sizingframe:RegisterWatchLua('FriendStatusTriggerUI', function(widget, trigger)
			if (trigger.friendMultiWindowOpen) then
				mainUI 													= mainUI or {}
				mainUI.savedLocally 									= mainUI.savedLocally or {}
				mainUI.savedLocally.friendsSettings 					= mainUI.savedLocally.friendsSettings or {}
				mainUI.savedLocally.friendsSettings.lastState 			= 'open'
				Friends[interfaceName].OpenFriendsList()
				Windows.GoToFriendWindowMode()
			else
				mainUI 													= mainUI or {}
				mainUI.savedLocally 									= mainUI.savedLocally or {}
				mainUI.savedLocally.friendsSettings 					= mainUI.savedLocally.friendsSettings or {}
				mainUI.savedLocally.friendsSettings.lastState 			= 'closed'				
				
				if (not trigger.friendLauncherWindowOpen) then
					Friends[interfaceName].CloseFriendsList()
					Windows.CloseFriendWindow()
				else
					libThread.threadFunc(function()	
						wait(100)
						Friends[interfaceName].CloseFriendsList()
						Windows.CloseFriendWindow()
					end)
				end				
				
			end
		end)
		FriendStatusTriggerUI.friendMultiWindowOpen = false		
		FriendStatusTriggerUI:Trigger(false)	
		
		social_client_sizingframe:RefreshCallbacks()

		libThread.threadFunc(function()	
			wait(10)		
			ChatClient.ForceInterfaceUpdate()
			wait(100)
			Friends[interfaceName].AttemptUpdate(true, nil)
		end)
		
	end
	
	if (interfaceName == 'friends') then
		FriendsWindowRegister(object)
	elseif (interfaceName == 'main') then
		FriendsLauncherRegister(object)
	end
	
	function Friends.InputOnEnter()
		Friends['main'].SearchOnEnter()
		Friends['friends'].SearchOnEnter()		
	end
	
	function Friends.InputOnEsc()
		Friends['main'].SearchOnEsc()
		Friends['friends'].SearchOnEsc()			
	end	
	
	function Friends.LabelInputOnEnter()
		Friends[interfaceName].LabelInputOnEnter()
	end
	
	function Friends.LabelInputOnEsc()
		Friends[interfaceName].LabelInputOnEsc()		
	end			
	
	-- println('interfaceName ' .. interfaceName)
	
end

FriendsRegister(object)

-- ==================

PlayerCard = PlayerCard or {}
local function InitPlayerCard(object)
			
	GetWidget('new_friend_window_topbar_profile_icon'):RegisterWatchLua('AccountInfo', function(widget, trigger)
		if (trigger.accountIconPath) and (not Empty(trigger.accountIconPath)) then
			widget:SetTexture(trigger.accountIconPath)
		else
			widget:SetTexture('/ui/shared/textures/user_icon.tga')
		end
	end, false, nil, 'accountIconPath')	
	
	GetWidget('new_friend_window_topbar_profile_name'):RegisterWatchLua('AccountInfo', function(widget, trigger) 
		widget:SetText(trigger.nickname) 
		widget:GetWidget('new_friend_window_topbar_profile_uniqueid'):SetText(trigger.uniqueID) 
	end, false, nil, 'nickname', 'uniqueID')	
	
	local function OpenSelfOptions()
		local ContextMenuTrigger = GetContextMenuTrigger()
		local identID = GetIdentID()
		if (identID) then
			local friendsClientInfoTrigger = LuaTrigger.GetTrigger('ChatClientInfo' .. string.gsub(identID, '%.', ''))
			if (friendsClientInfoTrigger) then
				ContextMenuTrigger.selectedUserIdentID 			= friendsClientInfoTrigger.identID
				ContextMenuTrigger.selectedUserUsername 		= friendsClientInfoTrigger.name
				-- ContextMenuTrigger.selectedUserIsInGame			= {inGame}
				-- ContextMenuTrigger.selectedUserIsInParty		= {inParty}
				-- ContextMenuTrigger.selectedUserIsInLobby		= {inLobby}
				-- ContextMenuTrigger.spectatableGame			= {spectatableGame}
				ContextMenuTrigger.contextMenuArea = 1
				ContextMenuTrigger:Trigger(true)
			else
				ContextMenuTrigger.selectedUserIdentID 			= identID
				ContextMenuTrigger.contextMenuArea = 1
				ContextMenuTrigger:Trigger(true)			
			end
		end		
	end
	
	GetWidget('new_friend_window_topbar_profile_name'):SetCallback('onclick', function(widget)	
		OpenSelfOptions()
	end)
	
	GetWidget('new_friend_window_topbar_profile_name'):SetCallback('onrightclick', function(widget)	
		OpenSelfOptions()
	end)	
	
	GetWidget('new_friend_window_topbar_profile_settings'):SetCallback('onclick', function(widget)
		OpenSelfOptions()
	end)
	
	GetWidget('new_friend_window_topbar_profile_settings'):SetCallback('onrightclick', function(widget)
		OpenSelfOptions()
	end)	
	
	GetWidget('new_friend_window_topbar_profile_icon'):SetNoClick(0)
	
	GetWidget('new_friend_window_topbar_profile_icon'):SetCallback('onmouseover', function(widget)
		GetWidget('new_friend_window_topbar_profile_icon_overlay'):SetVisible(true)
	end)
	GetWidget('new_friend_window_topbar_profile_icon'):SetCallback('onmouseout', function(widget)
		GetWidget('new_friend_window_topbar_profile_icon_overlay'):SetVisible(false)
	end)

	GetWidget('new_friend_window_topbar_profile_icon'):SetCallback('onclick', function(widget)
		local triggerPanelStatus = LuaTrigger.GetTrigger('mainPanelStatus')
		if (triggerPanelStatus.main == 23) then
			triggerPanelStatus.main = 101
			triggerPanelStatus:Trigger(false)	
		else
			triggerPanelStatus.main = 23
			mainUI.setBreadcrumbsSelected(-1)
			triggerPanelStatus:Trigger(false)			
			mainUI.BoostToPlayerCard()
			local playerProfileAnimStatus = LuaTrigger.GetTrigger('playerProfileAnimStatus')
			playerProfileAnimStatus.section = 'iconList'
			playerProfileAnimStatus:Trigger(false)
			mainUI.savedLocally.profileSection1 = playerProfileAnimStatus.section
			SaveState()			
		end
	end)	
	
	GetWidget('new_friend_window_topbar_profile_settings'):SetCallback('onshow', function(widget)
		LuaTrigger.GetTrigger('AccountInfo'):Trigger(true)
	end)
	
	libThread.threadFunc(function()
		wait(10)		
		LuaTrigger.GetTrigger('AccountInfo'):Trigger(true)
	end)
	
end

InitPlayerCard(object)
