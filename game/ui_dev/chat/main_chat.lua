-- Chat Manager
mainUI 					= mainUI 					or {}
mainUI.savedLocally 	= mainUI.savedLocally 		or {}
mainUI.savedRemotely 	= mainUI.savedRemotely 		or {}
mainUI.savedAnonymously	= mainUI.savedAnonymously 	or {}
local interface = object
local tinsert, tremove, tsort = table.insert, table.remove, table.sort
local WINDOW_CHAT_CHANNEL_INSTANCES_MAX 	= 10
local WINDOW_CHAT_IM_INSTANCES_MAX 			= 10
ClientInfo = ClientInfo or {}
ClientInfo.duplicateUsernameTable = ClientInfo.duplicateUsernameTable or {}
mainUI.chatManager = {
	channelBody					= object:GetWidget('chatWindowChannelArea'),
	channelList					= object:GetWidget('mainChannelListbox'),
}

mainUI.chatManager.activeChannels = {}
mainUI.savedLocally.openMemberlists = mainUI.savedLocally.openMemberlists or {}
mainUI.savedLocally.subscribedGroups = mainUI.savedLocally.subscribedGroups or {}
mainUI.chatManager.lastUserJoinedChannel = nil
mainUI.chatManager.lastActiveChannelID = nil
mainUI.chatManager.localActiveChannelInt = 0
mainUI.chatManager.queMyGroupsRebuild = true

mainUI.chatManager.memberlist = {}
mainUI.chatManager.pinnedChannels = {}

Windows 								= Windows or {}
Windows.Chat 							= Windows.Chat or {}
Windows.Chat.IM 						= Windows.Chat.IM or {}
Windows.Chat.Channel 					= Windows.Chat.Channel or {}
Windows.data 							= Windows.data or {}
Windows.data.chat 						= Windows.data.chat or {}
Windows.data.chat.channel 				= Windows.data.chat.channel or {}
Windows.data.chat.im 					= Windows.data.chat.im or {}
Windows.data.chat.channel.widgets 		= Windows.data.chat.channel.widgets or {}
Windows.data.chat.im.widgets 			= Windows.data.chat.im.widgets or {}

local defaultChatWindowWidth 			= '440s'
local defaultChatWindowHeight 			= '280s'
local defaultChatWindowX 			    = ((System.GetWindowX() + interface:GetXFromString('20s')) + (mainUI.chatManager.localActiveChannelInt * interface:GetXFromString('20s'))) .. 's'
local defaultChatWindowY 			    = (((System.GetWindowY() + interface:GetHeight()) - interface:GetHeightFromString(defaultChatWindowHeight)) - interface:GetYFromString('40s')) .. 's'

local function UpdateDefaults()
	defaultChatWindowWidth 			= '440s'
	defaultChatWindowHeight 		= '280s'
	defaultChatWindowX 			    = ((System.GetWindowX() + interface:GetXFromString('20s')) + (mainUI.chatManager.localActiveChannelInt * interface:GetXFromString('20s'))) .. 's'
	defaultChatWindowY 			    = (((System.GetWindowY() + interface:GetHeight()) - interface:GetHeightFromString(defaultChatWindowHeight)) - interface:GetYFromString('40s')) .. 's'
end

local chatUnreadMessageTrigger = LuaTrigger.GetTrigger('ChatUnreadMessageTrigger') or LuaTrigger.CreateCustomTrigger('ChatUnreadMessageTrigger', {
		{ name	=   'updatedChannel',		type	= 'string'},	
	}
)

GetWidget('main_chat_footer_overlay_parent_1'):RegisterWatchLua('notificationsTrigger', function(widget, trigger)
	widget:Sleep(50, function()
		widget:SetX(GetWidget('main_notification_footer_overlay'):GetWidth() + 6)
		widget:SetWidth(widget:GetWidthFromString('840s') - GetWidget('main_notification_footer_overlay'):GetWidth())
	end)
end)

GetWidget('main_chat_footer_overlay_parent_1'):RegisterWatchLua('mainPanelStatus', function(widget, trigger)
	if (trigger.chatConnectionState >= 1) and (trigger.hasIdent) and (trigger.isLoggedIn) and (not trigger.hideSecondaryElements) then
		widget:FadeIn(500)
	else
		widget:FadeOut(250)	
	end
end, false, nil, 'chatConnectionState', 'hasIdent', 'isLoggedIn', 'hideSecondaryElements')

local function FreeInterfaceSlot(messageType, channelID)
	local messageType = messageType or 'channel'
	for i,v in pairs(Windows.data.chat[messageType].widgets) do
		if (v == channelID) then
			Windows.data.chat[messageType].widgets[i] = nil
		end
	end	
end

if (Windows.Chat) and (Windows.Chat.Channel) then
	for i,v in pairs(Windows.Chat.Channel) do
		if (v) and (v:IsValid()) then
			v:Close()
		end
		Windows.Chat.Channel[i] = nil
	end
	Windows.data.chat.channel.widgets = {}
end
if (Windows.Chat) and (Windows.Chat.IM) then
	for i,v in pairs(Windows.Chat.IM) do
		if (v) and (v:IsValid()) then
			v:Close()
		end
		Windows.Chat.IM[i] = nil
	end
	Windows.data.chat.im.widgets = {}
end

local wasStacked = false
local chatAdditionIndex = 1
local dragOffset = 0
local chatPositions = {}
local footerWidgets = {}
local footerParentWidgets = {}
local dragThread
local initMousePos
mainUI.chatManager.justDragged = nil
mainUI.chatManager.draggingWidget = nil
function mainUI.chatManager.startTabDrag(widget)
	mainUI.chatManager.draggingWidget = widget
	dragOffset = widget:GetAbsoluteX()-Input.GetCursorPosX()
	initMousePos = Input.GetCursorPos()
	if (dragThread) then
		dragThread:kill()
		dragThread = nil
	end
	if (#footerWidgets > 10) then return end
	dragThread = libThread.threadFunc(function(thread)
		while (mainUI.chatManager.draggingWidget) do
			widget:SetX(widget:GetX()+ (Input.GetCursorPosX()-widget:GetAbsoluteX()) + dragOffset)
			widget:BringToFront()
			if not mainUI.chatManager.justDragged then
				local xChange = initMousePos.x-Input.GetCursorPosX()
				local yChange = initMousePos.y-Input.GetCursorPosY()
				mainUI.chatManager.justDragged = (xChange*xChange+yChange*yChange)>25 -- mouse moved 5 pixels
			end
			
			local dragX = widget:GetAbsoluteX() + widget:GetWidth()/2
			for i, v in pairs(footerParentWidgets) do
				local otherX = v:GetAbsoluteX() + v:GetWidth()/2
				if (chatPositions[widget] > chatPositions[v] and dragX < otherX
				or  chatPositions[widget] < chatPositions[v] and dragX > otherX) then
					local tmp = chatPositions[widget]
					chatPositions[widget] = chatPositions[v]
					chatPositions[v] = tmp
					mainUI.chatManager.justDragged = true
					RecalculateFooterWidgets()
				end
			end
			wait(17)--about 60 fps
		end
	end)
end
function mainUI.chatManager.stopTabDrag()
	mainUI.chatManager.draggingWidget = nil
	if (dragThread) then
		dragThread:kill()
		dragThread = nil
	end
	RecalculateFooterWidgets()
end
function RecalculateFooterWidgets()	
	if (interface) and (interface:IsValid()) and (interface:GetWidget('main_chat_sleeper')) and (interface:GetWidget('main_chat_sleeper'):IsValid()) then
		interface:GetWidget('main_chat_sleeper'):Sleep(1, function()		
			if (interface:GetWidget('main_chat_sleeper')) and (interface:GetWidget('main_chat_sleeper'):IsValid()) then
				interface:GetWidget('main_chat_sleeper'):Sleep(1, function()
					local footerParent = GetWidget('main_chat_footer_overlay_parent_1')
					
					footerWidgets = {}
					local footerWidgetsChannel = interface:GetGroup('footer_chat_tabs_large_pinned_label_templates_channel')
					local footerWidgetsPM = interface:GetGroup('footer_chat_tabs_large_pinned_label_templates_pm')
					
					if (footerWidgetsChannel) then
						for i,v in pairs(footerWidgetsChannel) do
							tinsert(footerWidgets, v)
						end
					end
					
					if (footerWidgetsPM) then
						for _,v in pairs(footerWidgetsPM) do
							tinsert(footerWidgets, v)
						end
					end
					
					if (#footerWidgets <= 10) then
						
						GetWidget('main_footer_chat_tab_group_1'):SetVisible(0)
						GetWidget('main_footer_chat_tab_group_2'):SetVisible(0)
						
						local main_chat_footer_overlay = GetWidget('main_chat_footer_overlay')
						local footerWidgetWidth = 0
						local footerWidth = footerParent:GetWidth()
						
						local stringWidth
						for i, v in pairs(footerWidgets) do
							v:GetParent():SetParent(main_chat_footer_overlay)
							stringWidth = (GetStringWidth('maindyn_18', v:GetValue()) + libGeneral.HtoP(6.0))
							v:GetParent():SetWidth(math.max(math.min(v:GetWidthFromString('300s'), stringWidth), v:GetWidthFromString('110s')))
							v:GetParent():GetChildren()[4]:SetVisible(1)
							v:SetX('35s')
							v:SetWidth('-50s')
						end				
						
						for i, v in pairs(footerWidgets) do
							footerWidgetWidth = footerWidgetWidth + v:GetParent():GetWidth()
						end
						
						local requiredWidth = footerWidgetWidth - (footerWidth - libGeneral.HtoP(11))
						
						if (requiredWidth > 0) then

							tsort(footerWidgets, function(a,b) 
								return a:GetParent():GetWidth() > b:GetParent():GetWidth()
							end)
							
							-- FIRST SHORTEN TO MINIMUM REQUIRED SIZE FOR LABEL, LONGEST FIRST
							local stringWidth
							for i, v in pairs(footerWidgets) do
								stringWidth = (GetStringWidth('maindyn_18', v:GetValue()) + libGeneral.HtoP(6.0))
								if (v:GetParent():GetWidth()) > (stringWidth) then	
									requiredWidth = requiredWidth - (v:GetParent():GetWidth() - stringWidth)
									v:GetParent():SetWidth(stringWidth)
								end
								if (requiredWidth <= 0) then
									break
								end
							end	
							
							-- THEN ALLOW TRUNCATION 50s
							if (requiredWidth > 0) then
								local newWidth = (footerParent:GetWidth() - libGeneral.HtoP(11)) / #footerWidgets	
								newWidth = math.max(newWidth, footerParent:GetWidthFromString('100s'))
								for i, v in pairs(footerWidgets) do
									if (v:GetParent():GetWidth() > newWidth) then
										requiredWidth = requiredWidth - (v:GetParent():GetWidth() - newWidth)
										v:GetParent():SetWidth(newWidth)
									end
									if (requiredWidth <= 0) then
										break
									end						
								end	
							end
							
							-- THEN HIDE ICONS
							if (requiredWidth > 0) then
								local newWidth = (footerParent:GetWidth() - libGeneral.HtoP(11)) / #footerWidgets			
								for i, v in pairs(footerWidgets) do
									if (v:GetParent():GetWidth() > newWidth) then
										requiredWidth = requiredWidth - (v:GetWidthFromString('30s'))
										v:GetParent():SetWidth(v:GetParent():GetWidth() - v:GetWidthFromString('30s'))
										v:GetParent():GetChildren()[4]:SetVisible(0)
										v:SetX('6s')
										v:SetWidth('-20s')
									end
									if (requiredWidth <= 0) then
										break
									end						
								end	
							end				
							
							-- THEN ALLOW TRUNCATION TO ZERO
							if (requiredWidth > 0) then
								local newWidth = (footerParent:GetWidth() - libGeneral.HtoP(11)) / #footerWidgets	
								for i, v in pairs(footerWidgets) do
									if (v:GetParent():GetWidth() > newWidth) then
										requiredWidth = requiredWidth - (v:GetParent():GetWidth() - newWidth)
										v:GetParent():SetWidth(newWidth)
									end
									if (requiredWidth <= 0) then
										break
									end						
								end	
							end				

						end	
						
						local footerParentWidgets_pm = interface:GetGroup('footer_chat_tabs_large_pinned_templates_pm')
						local footerParentWidgets_channel = interface:GetGroup('footer_chat_tabs_large_pinned_templates_channel')
						footerParentWidgets = {}
									
						if (footerParentWidgets_channel) then
							for i,v in pairs(footerParentWidgets_channel) do
								if (not chatPositions[v]) then
									chatPositions[v] = chatAdditionIndex
									chatAdditionIndex = chatAdditionIndex + 1
								end
								tinsert(footerParentWidgets, v)
							end
						end					
						if (footerParentWidgets_pm) then
							for i,v in pairs(footerParentWidgets_pm) do
								if (not chatPositions[v]) then
									chatPositions[v] = chatAdditionIndex
									chatAdditionIndex = chatAdditionIndex + 1
								end
								tinsert(footerParentWidgets, v)
							end
						end	
						
						tsort(footerParentWidgets, function(a,b) 
							return chatPositions[a]<chatPositions[b]
						end)
						
						local currentX = 0
						if (footerParentWidgets) then
							for i, v in pairs(footerParentWidgets) do
								if (v ~= mainUI.chatManager.draggingWidget) then
									v:SetY('32s')
									if v:GetX() ~= 0 or (currentX == 0) then
										v:SlideX(currentX, 125, true)
									else
										v:SetX(currentX - v:GetWidth())
										v:SlideX(currentX, 125, true)
									end
								end
								if (v:IsVisible()) then
									currentX = currentX + v:GetWidth() + 2
								end
							end
						end
						GetWidget('main_chat_footer_overlay_2'):SlideX(currentX, 125, true)				
						
						if (wasStacked) then
							wasStacked = false
							GetWidget('main_chat_sleeper'):Sleep(1, function()
								RecalculateFooterWidgets()	
							end)
						else
							wasStacked = false
						end

					else
						
						if (footerWidgetsChannel) then
							GetWidget('main_footer_chat_tab_group_1'):SetVisible(1)
							GetWidget('main_footer_chat_tab_group_expanded_1'):SetHeight( (GetWidget('main_footer_chat_tab_group_expanded_1'):GetHeightFromString('34s') * (#footerWidgetsChannel-0.5)))
							local main_footer_chat_tab_group_insert_1 = GetWidget('main_footer_chat_tab_group_insert_1')
							for i, v in pairs(footerWidgetsChannel) do
								v:GetParent():SetParent(main_footer_chat_tab_group_insert_1)
								v:GetParent():GetChildren()[4]:SetVisible(1)
								v:GetParent():SetWidth('300s')	
								v:SetX('35s')
							end
						end
						
						if (footerWidgetsPM) then
							GetWidget('main_footer_chat_tab_group_2'):SetVisible(1)
							GetWidget('main_footer_chat_tab_group_expanded_2'):SetHeight( (GetWidget('main_footer_chat_tab_group_expanded_1'):GetHeightFromString('34s') * #footerWidgetsPM))
							local main_footer_chat_tab_group_insert_2 = GetWidget('main_footer_chat_tab_group_insert_2')
							for i, v in pairs(footerWidgetsPM) do
								v:GetParent():SetParent(main_footer_chat_tab_group_insert_2)
								v:GetParent():GetChildren()[4]:SetVisible(1)
								v:GetParent():SetWidth('300s')	
								v:SetX('35s')
							end				
						end
						
						local footerParentGroupWidgets = interface:GetGroup('footer_chat_tabs_large_pinned_templates_group')
						
						local currentX = 0
						if (footerParentGroupWidgets) then
							for i, v in pairs(footerParentGroupWidgets) do
								if v:GetX() ~= 0 or (currentX == 0) then
									v:SlideX(currentX, 125, true)
								else
									v:SetX(currentX - v:GetWidth())
									v:SlideX(currentX, 125, true)
								end
								if (v:IsVisible()) then
									currentX = currentX + v:GetWidth() + 20
								end
							end
						end
						GetWidget('main_chat_footer_overlay_2'):SlideX(currentX, 125, true)						
						
						local footerParentWidgets_pm = interface:GetGroup('footer_chat_tabs_large_pinned_templates_pm')
						local footerParentWidgets_channel = interface:GetGroup('footer_chat_tabs_large_pinned_templates_channel')

						local currentY = ( GetWidget('main_footer_chat_tab_group_insert_1'):GetHeight() - 36)
						if (footerParentWidgets_channel) then				
							for i, v in pairs(footerParentWidgets_channel) do
								v:SetX(2)
								v:SlideY(currentY, 125, true)
								if (v:IsVisible()) then
									currentY = currentY - (v:GetHeight() + 1)
								end
							end
						end
						
						local currentY = ( GetWidget('main_footer_chat_tab_group_insert_2'):GetHeight() - 36)
						if (footerParentWidgets_pm) then				
							for i, v in pairs(footerParentWidgets_pm) do
								v:SetX(2)
								v:SlideY(currentY, 125, true)
								if (v:IsVisible()) then
									currentY = currentY - (v:GetHeight() + 1)
								end
							end
						end				
						
						wasStacked = true
					end
						
				end)
			end
			FindChildrenClickCallbacks(GetWidget('main_chat_footer_overlay_parent_1'))
			FindChildrenClickCallbacks(GetWidget('main_chat_base'))
		end)
	end
end

function mainUI.chatManager.ChannelJoinInputOnEsc()
	GetWidget('chat_join_channel_input_box'):EraseInputLine()
	GetWidget('chat_join_channel_input_box'):SetFocus(false)
end

function mainUI.chatManager.ChannelJoinInputOnEnter()
	if (string.len(GetWidget('chat_join_channel_input_box'):GetValue()) >= 1) then
		JoinChannel(nil, StripColorCodes(GetWidget('chat_join_channel_input_box'):GetValue()), true)
		GetWidget('chat_join_channel_input_box'):EraseInputLine()
		GetWidget('chat_join_channel_overlay'):SetVisible(0)
		-- sound_chatJoinChannelViaEnter
		-- PlaySound('/path_to/filename.wav')

	end
end

GetWidget('chat_join_channel_input_btn'):SetCallback('onclick', function(widget)
	local input = GetWidget('chat_join_channel_input_box')
	if (input) and (string.len(input:GetValue()) >= 1) then
		JoinChannel(nil, StripColorCodes(input:GetValue()), true)
		input:EraseInputLine()
		GetWidget('chat_join_channel_overlay'):SetVisible(0)
		-- sound_chatJoinChannel
		-- PlaySound('/path_to/filename.wav')
	end
end)

local lastChannelListTable
local function UpdateChannelList(channelListTable, offset)
	local channelListTable = channelListTable or lastChannelListTable
	lastChannelListTable = channelListTable
	offset = offset or 0
	
	local chanSearchMaxViewSize = 10
	local chanSearchMinViewSize = 10 -- grow between a range, not used yet
	local scrollPanel = GetWidget('channelScrollPanel')
	local scrollbar = GetWidget('channelScrollBar')
	local chanCurViewEntries    = 10
	local scrollValue			= 0
	local scrollMax				= 6
	
	local no_results_label = GetWidget('channel_entry_no_results')
	local chat_join_channel_area = GetWidget('chat_join_channel_area')	
	
	for i,v in pairs(channelListTable) do
		if (v.name) and string.find(v.name, 'Scrim_') then
			table.remove(channelListTable, i)
		end
	end
	
	local updateEntry = function(index, visible, v)				

		local container		= chat_join_channel_area:GetWidget('chat_channel_joiner_entry'..index)
		if not container then return end
		if not visible or not v then
			container:SetVisible(0)
			return
		end
		container:SetVisible(1)
		local userBody		= chat_join_channel_area:GetWidget('chat_channel_joiner_entry'..index..'UserBody')
		local userButton	= chat_join_channel_area:GetWidget('chat_channel_joiner_entry'..index..'UserButton')			
		if (v.actionOverride) then
			userButton:SetCallback('onclick', function(widget)
				println('actionOverride')
				v.actionOverride()
				GetWidget('chat_join_channel_overlay'):SetVisible(0)
			end)	
		else
			userButton:SetCallback('onclick', function(widget)
				JoinChannel(v.channelID, v.trueName or v.name, true)
				GetWidget('chat_join_channel_overlay'):SetVisible(0)
			end)
		end
		local ChannelName	= chat_join_channel_area:GetWidget('chat_channel_joiner_entry'..index..'ChannelName')
		local MemberCount	= chat_join_channel_area:GetWidget('chat_channel_joiner_entry'..index..'MemberCount')
		local Topic			= chat_join_channel_area:GetWidget('chat_channel_joiner_entry'..index..'Topic')
		local Language		= chat_join_channel_area:GetWidget('chat_channel_joiner_entry'..index..'Language')
		ChannelName:SetText(Translate(v.name))
		MemberCount:SetText(v.memberCount)
		Topic:SetText(v.topic)
		if (v.language) and (not Empty(v.language)) then
			Language:SetText(v.language)
		else
			Language:SetText(Translate('lang_language'))
		end
		if (v.topic) and (not Empty(v.topic)) then
			Topic:SetText(v.topic)
		else
			Topic:SetText(Translate('general_topic_ns'))
		end		
	end
	
	for i=1,chanSearchMaxViewSize do
		updateEntry(i, false, nil)
	end		

	if (#channelListTable > 0) then
		no_results_label:SetVisible(0)	
		scrollbar:SetVisible(1)	
		for i=1,chanSearchMaxViewSize,1 do
			updateEntry(i, true, channelListTable[i + offset])
		end			

		chanCurViewEntries = math.min(table.maxn(channelListTable), chanSearchMaxViewSize)
		chanCurViewEntries = math.max(chanCurViewEntries, chanSearchMinViewSize)	
		scrollMax = math.max(0, (table.maxn(channelListTable) - chanCurViewEntries))
		scrollValue = math.min(scrollMax, scrollValue)
		scrollbar:SetMaxValue(scrollMax)
		if scrollValue > scrollMax then
			if scrollValue ~= scrollbar:GetValue() then
				scrollbar:SetValue(scrollValue)
			end
		end

		scrollPanel:SetCallback('onmousewheelup', function(widget)
			GetWidget('channelScrollBar'):SetValue(GetWidget('channelScrollBar'):GetValue() - 1)
		end)
		
		scrollPanel:SetCallback('onmousewheeldown', function(widget)
			GetWidget('channelScrollBar'):SetValue(GetWidget('channelScrollBar'):GetValue() + 1)
		end)	
		
	else
		no_results_label:SetVisible(1)	
		scrollbar:SetVisible(0)	
	end

end

function RefreshChannelSearch(searchTerm)

	local chatServerCallbackFunction =  function (results)	-- chat server response handler

		if results == nil then
			return nil
		end
		
		local genericGeneralChannelTable = {
			generalIndex = 4294967296,
			name = '^699'..Translate('default_general'),
			trueName = 'general',
			topic = "",
			isGeneral = true,
			language = "",
			channelID = nil,
			memberCount = 0	
		}

		table.insert(results, genericGeneralChannelTable)
		
		if (mainUI.chatManager.lobbyID) and LuaTrigger.GetTrigger('LobbyStatus').inLobby then
			local genericLobbyChannelTable = {
				actionOverride = function() ChatNewChannel(interface, mainUI.chatManager.lobbyID, mainUI.chatManager.lobbyName, false) end,
				lobbyIndex = 4294967296,
				name = '^699'..Translate(mainUI.chatManager.lobbyName),
				trueName = mainUI.chatManager.lobbyName,
				topic = "",
				isGeneral = false,
				language = "",
				channelID = mainUI.chatManager.lobbyID,
				memberCount = 0	
			}			
			table.insert(results, genericLobbyChannelTable)
		end
		
		if (mainUI.chatManager.partyID) and LuaTrigger.GetTrigger('PartyStatus').inParty then
			local genericPartyChannelTable = {
				actionOverride = function() ChatNewChannel(interface, mainUI.chatManager.partyID, mainUI.chatManager.partyName, false) end,
				lobbyIndex = 4294967296,
				name = '^699'..Translate(mainUI.chatManager.partyName),
				trueName = mainUI.chatManager.partyName,
				topic = "",
				isGeneral = false,
				language = "",
				channelID = mainUI.chatManager.partyID,
				memberCount = 0	
			}			
			table.insert(results, genericPartyChannelTable)
		end		
		
		UpdateChannelList(results, 0)
		
		return true
	end
	
	Client.GetChannelList(searchTerm, chatServerCallbackFunction)
end

local function ChatChannelSearchInputRegister(object)

	ChatChannelSearchInput = {}

	GetWidget('channelScrollBar'):SetCallback('onslide', function(widget)
		-- Update scrolling to this position
		local scrollValue = widget:GetValue()
		UpdateChannelList(nil, scrollValue)
	end)
	
	GetWidget('chat_join_channel_input_box'):SetCallback('onchange', function(widget)
		local hasString = (string.len(widget:GetValue()) > 0)
		GetWidget('chat_join_channel_input_btn'):SetEnabled(hasString)
		local chat_join_channel_input_textbox = GetWidget('chat_join_channel_input_box')

		chat_join_channel_input_textbox:Sleep(350, function()
			RefreshChannelSearch(StripColorCodes(chat_join_channel_input_textbox:GetValue()))
		end)
	end)

	GetWidget('chat_join_channel_input_box'):SetCallback('onfocus', function(widget)
		GetWidget('chat_join_channel_coverup'):SetVisible(false)
	end)

	GetWidget('chat_join_channel_input_box'):SetCallback('onlosefocus', function(widget)
		if string.len(widget:GetValue()) == 0 then
			GetWidget('chat_join_channel_coverup'):SetVisible(true)
		end
	end)

	function OnChatJoinChannelButtonClick()
		local visible = GetWidget('chat_join_channel_overlay'):IsVisible()
		GetWidget('chat_join_channel_overlay'):SetVisible(not visible)
		if not visible then
			RefreshChannelSearch(StripColorCodes(GetWidget('chat_join_channel_input_box'):GetValue()))
			-- sound_chatHideChannelList
			PlaySound('ui/sounds/social/sfx_chat_close.wav')
		else
			-- sound_chatShowChannelList
			PlaySound('ui/sounds/social/sfx_chat_open.wav')
		end
	end	
	
end

ChatChannelSearchInputRegister(object)

mainUI.chatManager.channelAtFrontId = -1 


local function FocusChatWindow(windowRef)
	if windowRef:GetActiveInterface():GetWidget('overlay_chat_channel_window_parent'):IsVisible() then
		local chatUnreadMessageTrigger = LuaTrigger.GetTrigger('ChatUnreadMessageTrigger')
		windowRef:GetActiveInterface():GetWidget('overlay_chat_channel_window_parent'):BringToFront()
		windowRef:GetActiveInterface():GetWidget('overlay_chat_channel_window_input'):SetFocus(true)
		mainUI.chatManager.channelAtFrontId = channelID
		mainUI.chatManager.lastActiveChannelID = channelID	
		chatUnreadMessageTrigger.updatedChannel = '-1'
		chatUnreadMessageTrigger:Trigger(true)			
	end
end

local function isWindowInLauncherBounds(window)
	
	local launcherMainInterfaceWidget = UIManager.GetInterface('main')
	
	if (window) and (window:IsValid()) and (launcherMainInterfaceWidget) and (launcherMainInterfaceWidget:IsValid()) then

		local launcherLeftBound, launcherTopBound 		= System.WindowClientToScreen(0, 0)
		local launcherRightBound, launcherBottomBound 	= System.WindowClientToScreen(launcherMainInterfaceWidget:GetWidth(), launcherMainInterfaceWidget:GetHeight()) -- GetScreenWidth(), GetScreenHeight() seem to be using the window they are called from
		
		local friendsWindowLeftBound, friendsWindowTopBound = window:GetX(), window:GetY()
		local friendsWindowRightBound, friendsWindowBottomBound = friendsWindowLeftBound + window:GetWidth(), friendsWindowTopBound + window:GetHeight()
		
		
		if  (friendsWindowLeftBound >= launcherLeftBound) and
			(friendsWindowRightBound <= launcherRightBound) and
			(friendsWindowTopBound >= launcherTopBound) and
			(friendsWindowBottomBound <= launcherBottomBound) then
			return true
		end	
	end
	return false
end

local function isWindowInLauncherBounds(window)
	
	local launcherMainInterfaceWidget = UIManager.GetInterface('main')
	
	if (window) and (window:IsValid()) and (launcherMainInterfaceWidget) and (launcherMainInterfaceWidget:IsValid()) then

		local launcherLeftBound, launcherTopBound 		= System.WindowClientToScreen(0, 0)
		local launcherRightBound, launcherBottomBound 	= System.WindowClientToScreen(launcherMainInterfaceWidget:GetWidth(), launcherMainInterfaceWidget:GetHeight()) -- GetScreenWidth(), GetScreenHeight() seem to be using the window they are called from
		
		-- local friendsWindowLeftBound, friendsWindowTopBound = window:GetX(), window:GetY()
		-- local friendsWindowRightBound, friendsWindowBottomBound = friendsWindowLeftBound + window:GetWidth(), friendsWindowTopBound + window:GetHeight()
		
		local friendsWindowLeftBound, friendsWindowTopBound, friendsWindowRightBound, friendsWindowBottomBound = window:GetWindowRect()
		
		if  (friendsWindowLeftBound >= launcherLeftBound) and
			(friendsWindowRightBound <= launcherRightBound) and
			(friendsWindowTopBound >= launcherTopBound) and
			(friendsWindowBottomBound <= launcherBottomBound) then
			return true
		end	
	end
	return false
end	

local function DockToLauncherIfPossible(window)
	if (window) and (window:IsValid()) then
		if isWindowInLauncherBounds(window) then
			window:SetOwnerMainWindow()
		else
			window:SetOwner(nil)
		end
	end
end

function mainUI.chatManager.MoveOwnedChatWindowWithLauncherDrag(isDragging, x, y)
	println('^o MoveOwnedChatWindowWithLauncherDrag ' .. tostring(isDragging) .. ' x: ' .. tostring(x) .. ' | y: ' .. tostring(y))
	if (isDragging) then
		for index,window in pairs(Windows.Chat.Channel) do
			if (window) and (window:IsValid()) and (window:HasOwner()) then
				local windowPositionRelativeToLauncherX = window:GetX() - System.GetWindowX()
				local windowPositionRelativeToLauncherY = window:GetY() - System.GetWindowY()
				local windowInterface = window:GetActiveInterface()
				windowInterface:SetCallback('onframe', function()
					window:Move(System.GetWindowX() + windowPositionRelativeToLauncherX, System.GetWindowY() + windowPositionRelativeToLauncherY)
				end)
			end
		end
		for index,window in pairs(Windows.Chat.IM) do
			if (window) and (window:IsValid()) and (window:HasOwner()) then
				local windowPositionRelativeToLauncherX = window:GetX() - System.GetWindowX()
				local windowPositionRelativeToLauncherY = window:GetY() - System.GetWindowY()
				local windowInterface = window:GetActiveInterface()
				windowInterface:SetCallback('onframe', function()
					window:Move(System.GetWindowX() + windowPositionRelativeToLauncherX, System.GetWindowY() + windowPositionRelativeToLauncherY)
				end)
			end
		end		
	else
		for index,window in pairs(Windows.Chat.Channel) do
			if (window) and (window:IsValid()) then
				local windowInterface = window:GetActiveInterface()
				windowInterface:ClearCallback('onframe')				
			end
		end	
		for index,window in pairs(Windows.Chat.IM) do
			if (window) and (window:IsValid()) then
				local windowInterface = window:GetActiveInterface()
				windowInterface:ClearCallback('onframe')				
			end
		end			
	end
end

function mainUI.chatManager.ClickedPinnedChatTab(widget, channelName, channelID, isPrivateMessage, isMinimise, chatType)

	if (chatType) and (chatType == 'pm') then
		isPrivateMessage = true
	end
	
	local chatParent = interface:GetWidget('overlay_chat_' .. chatType .. channelID .. '_parent')
	local chatInput = interface:GetWidget('overlay_chat_' .. chatType .. channelID .. '_input')
	
	if (mainUI.Clans) and (mainUI.savedLocally) then
		mainUI.Clans.mode = mainUI.Clans.mode or mainUI.savedLocally.clansMode or 'launcher'
	end
	
	if (channelID == 'Clan') then -- and (mainUI.Clans) and (mainUI.Clans.mode) and (mainUI.Clans.mode == 'launcher') 
		
		mainUI.Clans.Toggle()	
	
	elseif (Windows.Chat.Channel[channelID]) and (Windows.Chat.Channel[channelID]:IsValid()) and (not isPrivateMessage) then
		
		if (not Windows.Chat.Channel[channelID]:IsVisible()) or (Windows.Chat.Channel[channelID]:IsMinimized())  then		
			
			Windows.Chat.Channel[channelID]:Restore()
			Windows.Chat.Channel[channelID]:Show()
			if (Windows.Chat.Channel[channelID]:IsBehindMainWindow() and (isWindowInLauncherBounds(Windows.Chat.Channel[channelID]))) then
				Windows.Chat.Channel[channelID]:MakeFrontActiveWindow()
			end
			FocusChatWindow(Windows.Chat.Channel[channelID])
			
			mainUI.chatManager.pinnedChannels[channelID] = true
			if (interface) and (interface:IsValid()) and (interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4')) and (interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4'):IsValid()) then
				interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4'):SetTexture('/ui/main/footer/textures/message_bubble_focus.tga')
			end
			mainUI.chatManager.channelAtFrontId = channelID		
			ChatClient.SetChannelPinned(channelID,true)
			local chatUnreadMessageTrigger = LuaTrigger.GetTrigger('ChatUnreadMessageTrigger')
			chatUnreadMessageTrigger.updatedChannel = '-1'
			chatUnreadMessageTrigger:Trigger(true)		
			-- sound_showChatChannel
			PlaySound('ui/sounds/social/sfx_chat_open.wav')
			mainUI.chatManager.lastActiveChannelID  = channelID			
			DockToLauncherIfPossible(Windows.Chat.Channel[channelID])
		
		else
			
			if (Windows.Chat.Channel[channelID]:HasFocus()) or (mainUI.chatManager.channelAtFrontId == channelID) or (isMinimise) then

				if Windows.Chat.Channel[channelID]:HasOwner() then
					Windows.Chat.Channel[channelID]:Hide() 
				else
					Windows.Chat.Channel[channelID]:Minimize() 
				end					
				
				mainUI.chatManager.pinnedChannels[channelID] = false
				ChatClient.SetChannelPinned(channelID,false)
				if (interface) and (interface:IsValid()) and (interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4')) and (interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4'):IsValid()) then
					interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4'):SetTexture('/ui/main/footer/textures/message_bubble.tga')
				end
				
				-- sound_hideChatChannel
				PlaySound('ui/sounds/social/sfx_chat_close.wav')			
			
			else
				
				-- Windows.Chat.Channel[channelID]:MakeFrontActiveWindow()
				FocusChatWindow(Windows.Chat.Channel[channelID])
				
				mainUI.chatManager.pinnedChannels[channelID] = true
				if (interface) and (interface:IsValid()) and (interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4')) and (interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4'):IsValid()) then
					interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4'):SetTexture('/ui/main/footer/textures/message_bubble_focus.tga')
				end
				mainUI.chatManager.channelAtFrontId = channelID		
				ChatClient.SetChannelPinned(channelID,true)
				local chatUnreadMessageTrigger = LuaTrigger.GetTrigger('ChatUnreadMessageTrigger')
				chatUnreadMessageTrigger.updatedChannel = '-1'
				chatUnreadMessageTrigger:Trigger(true)		
				-- sound_showChatChannel
				PlaySound('ui/sounds/social/sfx_chat_open.wav')
				mainUI.chatManager.lastActiveChannelID  = channelID
				
			end
			
			DockToLauncherIfPossible(Windows.Chat.Channel[channelID])
			
		end
		
	elseif (Windows.Chat.IM[channelID]) and (Windows.Chat.IM[channelID]:IsValid()) and (isPrivateMessage) then
	
		if (not Windows.Chat.IM[channelID]:IsVisible()) or (Windows.Chat.IM[channelID]:IsMinimized()) or (Windows.Chat.IM[channelID]:IsBehindMainWindow() and (isWindowInLauncherBounds(Windows.Chat.IM[channelID]))) then
			Windows.Chat.IM[channelID]:Restore()
			Windows.Chat.IM[channelID]:Show()
			if (Windows.Chat.IM[channelID]:IsBehindMainWindow() and (isWindowInLauncherBounds(Windows.Chat.IM[channelID]))) then
				Windows.Chat.IM[channelID]:MakeFrontActiveWindow()
			end
			FocusChatWindow(Windows.Chat.IM[channelID])
			
			mainUI.chatManager.pinnedChannels[channelID] = true
			if (interface) and (interface:IsValid()) and (interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4')) and (interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4'):IsValid()) then
				interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4'):SetTexture('/ui/main/footer/textures/message_bubble_focus.tga')
			end
			mainUI.chatManager.channelAtFrontId = channelID		
			ChatClient.SetChannelPinned(channelID,true)
			local chatUnreadMessageTrigger = LuaTrigger.GetTrigger('ChatUnreadMessageTrigger')
			chatUnreadMessageTrigger.updatedChannel = '-1'
			chatUnreadMessageTrigger:Trigger(true)		
			-- sound_showChatChannel
			PlaySound('ui/sounds/social/sfx_chat_open.wav')
			mainUI.chatManager.lastActiveChannelID  = channelID
			DockToLauncherIfPossible(Windows.Chat.IM[channelID])
			
		else
		
			if (Windows.Chat.IM[channelID]:HasFocus()) or (mainUI.chatManager.channelAtFrontId == channelID) or (isMinimise) then		
				
				if Windows.Chat.IM[channelID]:HasOwner() then
					Windows.Chat.IM[channelID]:Hide() 
				else
					Windows.Chat.IM[channelID]:Minimize() 
				end				
				
				mainUI.chatManager.pinnedChannels[channelID] = false
				ChatClient.SetChannelPinned(channelID,false)
				if (interface) and (interface:IsValid()) and (interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4')) and (interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4'):IsValid()) then
					interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4'):SetTexture('/ui/main/footer/textures/message_bubble.tga')
				end
				
				-- sound_hideChatChannel
				PlaySound('ui/sounds/social/sfx_chat_close.wav')			
			
			else
				
				Windows.Chat.IM[channelID]:MakeFrontActiveWindow()
				FocusChatWindow(Windows.Chat.IM[channelID])
				
				mainUI.chatManager.pinnedChannels[channelID] = true
				if (interface) and (interface:IsValid()) and (interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4')) and (interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4'):IsValid()) then
					interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4'):SetTexture('/ui/main/footer/textures/message_bubble_focus.tga')
				end
				mainUI.chatManager.channelAtFrontId = channelID		
				ChatClient.SetChannelPinned(channelID,true)
				local chatUnreadMessageTrigger = LuaTrigger.GetTrigger('ChatUnreadMessageTrigger')
				chatUnreadMessageTrigger.updatedChannel = '-1'
				chatUnreadMessageTrigger:Trigger(true)		
				-- sound_showChatChannel
				PlaySound('ui/sounds/social/sfx_chat_open.wav')
				mainUI.chatManager.lastActiveChannelID  = channelID
				
			end
			
			DockToLauncherIfPossible(Windows.Chat.IM[channelID])
			
		end		
		
	elseif (chatParent) then

		if (not chatParent:IsVisible()) then
			mainUI.chatManager.pinnedChannels[channelID] = true
			chatParent:FadeIn(150)
			if (interface) and (interface:IsValid()) and (interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4')) and (interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4'):IsValid()) then
				interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4'):SetTexture('/ui/main/footer/textures/message_bubble_focus.tga')
			end
			mainUI.chatManager.channelAtFrontId = channelID		
			chatParent:BringToFront()
			chatInput:SetFocus(true)
			ChatClient.SetChannelPinned(channelID,true)
			local x = math.min(widget:GetX() + widget:GetWidth(), GetScreenWidth() - chatParent:GetWidth() - 10)
			chatParent:SetX(x)
			chatParent:SetY(GetScreenHeight() - (chatParent:GetHeight() + chatParent:GetHeightFromString('60s')) )
			local chatUnreadMessageTrigger = LuaTrigger.GetTrigger('ChatUnreadMessageTrigger')
			chatUnreadMessageTrigger.updatedChannel = '-1'
			chatUnreadMessageTrigger:Trigger(true)		

			
			-- sound_showChatChannel
			PlaySound('ui/sounds/social/sfx_chat_open.wav')
			mainUI.chatManager.lastActiveChannelID  = channelID
		elseif (mainUI.chatManager.channelAtFrontId ~= channelID) and (not isMinimise) then
			mainUI.chatManager.pinnedChannels[channelID] = true
			chatParent:FadeIn(150)
			if (interface) and (interface:IsValid()) and (interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4')) and (interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4'):IsValid()) then
				interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4'):SetTexture('/ui/main/footer/textures/message_bubble_focus.tga')
			end
			mainUI.chatManager.channelAtFrontId = channelID		
			chatParent:BringToFront()
			chatInput:SetFocus(true)
			ChatClient.SetChannelPinned(channelID,true)
			local chatUnreadMessageTrigger = LuaTrigger.GetTrigger('ChatUnreadMessageTrigger')
			chatUnreadMessageTrigger.updatedChannel = '-1'
			chatUnreadMessageTrigger:Trigger(true)			
			
			-- sound_showChatChannel
			PlaySound('ui/sounds/social/sfx_chat_open.wav')
			mainUI.chatManager.lastActiveChannelID  = channelID
		else
			mainUI.chatManager.pinnedChannels[channelID] = false
			ChatClient.SetChannelPinned(channelID,false)
			chatParent:FadeOut(150)
			if (interface) and (interface:IsValid()) and (interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4')) and (interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4'):IsValid()) then
				interface:GetWidget('main_footer_chat_tab_' .. chatType .. channelID .. '_4'):SetTexture('/ui/main/footer/textures/message_bubble.tga')
			end
			
			-- sound_hideChatChannel
			PlaySound('ui/sounds/social/sfx_chat_close.wav')
		end

	else
		println('channelID has no parent: ' .. tostring(channelID) ) 
	end
	RecalculateFooterWidgets()
end

local function AddToMyGroups(channelID, channelName)
	mainUI.savedLocally.subscribedGroups = mainUI.savedLocally.subscribedGroups or {}
	mainUI.savedLocally.subscribedGroups[channelName] = mainUI.savedLocally.subscribedGroups[channelName] or channelID
	SaveState()
end

local function RemoveFromMyGroups(channelID, channelName)
	if (not channelName) then
		for name,id in pairs(mainUI.savedLocally.subscribedGroups) do
			if (id == channelID) then
				channelName = name
				break
			end
		end
	end
	if (channelName) then
		mainUI.savedLocally.subscribedGroups = mainUI.savedLocally.subscribedGroups or {}
		mainUI.savedLocally.subscribedGroups[channelName] = nil
		SaveState()
	end
end

local function LoadMyGroups()
	for channelName, channelID in pairs(mainUI.savedLocally.subscribedGroups) do
		JoinChannel(channelID, channelName)
	end
end

function mainUI.ChatChannelTeamFocusRegister(self, channelID, channelName, type)
	
	local function FocusChatWindow(self, focusInput)
		if GetWidget('overlay_chat_' .. type .. channelID .. '_parent'):IsVisible() then
			if (focusInput) then
				GetWidget('overlay_chat_' .. type .. channelID .. '_parent'):BringToFront()
				GetWidget('overlay_chat_' .. type .. channelID .. '_input'):SetFocus(true)
			end
		end
		groupfcall('overlay_chat_' .. type .. channelID .. '_visobj', function(_, widget) widget:FadeIn(500) end)
		GetWidget('mainChat' .. type .. channelID .. 'Buffer'):SetNoClick(0)
		GetWidget('mainChatinvisible_channelPartyBuffer_scroll', nil, true):SetVisible(1)
		mainUI.chatManager.channelAtFrontId = channelID
		mainUI.chatManager.lastActiveChannelID = channelID	
		chatUnreadMessageTrigger.updatedChannel = '-1'
		chatUnreadMessageTrigger:Trigger(true)		
	end

	local function UnFocusChatWindow(self)
		if (not libGeneral.mouseInWidgetArea(self)) then
			groupfcall('overlay_chat_' .. type .. channelID .. '_visobj', function(_, widget) widget:FadeOut(500) end)
			GetWidget('mainChat' .. type .. channelID .. 'Buffer'):SetNoClick(1)
			GetWidget('mainChatinvisible_channelPartyBuffer_scroll', nil, true):SetVisible(0)
		end
	end	
	
	GetWidget('mainChatinvisible_channelPartyBuffer_scroll', nil, true):SetVisible(0)
	
	GetWidget('overlay_chat_' .. type .. channelID .. '_input'):SetCallback('onmouseout', function()  UnFocusChatWindow(self) end)
	GetWidget('overlay_chat_' .. type .. channelID .. '_input'):SetCallback('onmouseover', function() FocusChatWindow(self) end)
	GetWidget('overlay_chat_' .. type .. channelID .. '_input'):SetCallback('onfocus', function(widget) 
		FocusChatWindow(self, true) 
		Links.lastActiveChatInputBuffer = widget
		mainUI.chatManager.lastActiveChannelID = channelID		
	end)
	GetWidget('overlay_chat_' .. type .. channelID .. '_input'):SetCallback('onlosefocus', function() 
		UnFocusChatWindow(self)	
	end)	
	GetWidget('overlay_chat_' .. type .. channelID .. '_input'):SetCallback('onclick', function() FocusChatWindow(self, true) end)
	GetWidget('overlay_chat_' .. type .. channelID .. '_input'):RefreshCallbacks()
	
	self:SetCallback('onmouseout', function() UnFocusChatWindow(self) end)	
	self:SetCallback('onmouseover', function() FocusChatWindow(self) end)	
	self:SetCallback('onclick', function() FocusChatWindow(self, true) end)	
	self:SetCallback('onfocus', function() FocusChatWindow(self, true) end)	
	self:RefreshCallbacks()
	
	GetWidget('overlay_chat_' .. type .. channelID .. '_input_btn'):SetCallback('onmouseout', function() UnFocusChatWindow(self) end)
	GetWidget('overlay_chat_' .. type .. channelID .. '_input_btn'):SetCallback('onmouseover', function() FocusChatWindow(self) end)
	GetWidget('overlay_chat_' .. type .. channelID .. '_input_btn'):SetCallback('onfocus', function() FocusChatWindow(self, true) end)
	GetWidget('overlay_chat_' .. type .. channelID .. '_input_btn'):SetCallback('onclick', function()
		GetWidget('overlay_chat_' .. type .. channelID .. '_input'):ProcessInputLine()
		FocusChatWindow(self, true)
	end)		
	GetWidget('overlay_chat_' .. type .. channelID .. '_input_btn'):RefreshCallbacks()	
	
	GetWidget('overlay_chat_' .. type .. channelID .. '_frame'):SetCallback('onmouseout', function() UnFocusChatWindow(self) end)	
	GetWidget('overlay_chat_' .. type .. channelID .. '_frame'):SetCallback('onmouseover', function() FocusChatWindow(self) end)	
	GetWidget('overlay_chat_' .. type .. channelID .. '_frame'):SetCallback('onfocus', function() FocusChatWindow(self, true) end)	
	GetWidget('overlay_chat_' .. type .. channelID .. '_frame'):SetCallback('onclick', function() FocusChatWindow(self, true) end)	
	GetWidget('overlay_chat_' .. type .. channelID .. '_frame'):RefreshCallbacks()
		
	GetWidget('overlay_chat_' .. type .. channelID .. '_buffer'):SetCallback('onmouseout', function() UnFocusChatWindow(self) end)	
	GetWidget('overlay_chat_' .. type .. channelID .. '_buffer'):SetCallback('onmouseover', function() FocusChatWindow(self) end)	
	GetWidget('overlay_chat_' .. type .. channelID .. '_buffer'):SetCallback('onfocus', function() FocusChatWindow(self, true) end)	
	GetWidget('overlay_chat_' .. type .. channelID .. '_buffer'):SetCallback('onclick', function() FocusChatWindow(self, true) end)	
	GetWidget('overlay_chat_' .. type .. channelID .. '_buffer'):RefreshCallbacks()
	
	GetWidget('mainChat' .. type .. channelID .. 'Buffer'):SetCallback('onmouseout', function() 
		GetWidget('profile_preview_parent'):FadeOut(50)
		UnFocusChatWindow(self) 
	end)
	GetWidget('mainChat' .. type .. channelID .. 'Buffer'):SetCallback('onmouseover', function() 
		FocusChatWindow(self) 
	end)
	GetWidget('mainChat' .. type .. channelID .. 'Buffer'):SetCallback('onfocus', function() FocusChatWindow(self, true) end)
	GetWidget('mainChat' .. type .. channelID .. 'Buffer'):SetCallback('onclick', function() FocusChatWindow(self, true) end)		
	GetWidget('mainChat' .. type .. channelID .. 'Buffer'):RefreshCallbacks()
	GetWidget('mainChat' .. type .. channelID .. 'Buffer'):SetNoClick(1)

end

function mainUI.ChatChannelFocusRegister(self, channelID, channelName, type)
	
	local function FocusChatWindow(self)
		if GetWidget('overlay_chat_' .. type .. channelID .. '_parent'):IsVisible() then
			GetWidget('overlay_chat_' .. type .. channelID .. '_parent'):BringToFront()
			GetWidget('overlay_chat_' .. type .. channelID .. '_input'):SetFocus(true)
			mainUI.chatManager.channelAtFrontId = channelID
			mainUI.chatManager.lastActiveChannelID = channelID	
			chatUnreadMessageTrigger.updatedChannel = '-1'
			chatUnreadMessageTrigger:Trigger(true)			
		end
	end

	GetWidget('overlay_chat_' .. type .. channelID .. '_input'):SetCallback('onmouseldown', function(widget) FocusChatWindow(self) end )
	GetWidget('overlay_chat_' .. type .. channelID .. '_input'):SetCallback('onmouselup', function(widget) FocusChatWindow(self) end)
	GetWidget('overlay_chat_' .. type .. channelID .. '_input'):SetCallback('onfocus', function(widget) 
		FocusChatWindow(widget) 
		Links.lastActiveChatInputBuffer = widget
		mainUI.chatManager.lastActiveChannelID = channelID		
	end)
	GetWidget('overlay_chat_' .. type .. channelID .. '_input'):SetCallback('onclick', function(widget) FocusChatWindow(self) end)
	GetWidget('overlay_chat_' .. type .. channelID .. '_input'):RefreshCallbacks()
	
	self:SetCallback('onmouseldown', function(self) FocusChatWindow(self) end)
	self:SetCallback('onmouselup', function(self) FocusChatWindow(self) end)
	self:SetCallback('onclick', function(self) FocusChatWindow(self) end)	
	self:SetCallback('onfocus', function(self) FocusChatWindow(self) end)	
	self:SetCallback('onstartdrag', function(self) FocusChatWindow(self) end)	
	self:SetCallback('onenddrag', function(self) FocusChatWindow(self) end)
	self:RefreshCallbacks()
	
	GetWidget('overlay_chat_' .. type .. channelID .. '_input_btn'):SetCallback('onmouseldown', function(self) FocusChatWindow(self) end)
	GetWidget('overlay_chat_' .. type .. channelID .. '_input_btn'):SetCallback('onmouselup', function(self) FocusChatWindow(self) end)
	GetWidget('overlay_chat_' .. type .. channelID .. '_input_btn'):SetCallback('onfocus', function(self) FocusChatWindow(self) end)
	GetWidget('overlay_chat_' .. type .. channelID .. '_input_btn'):SetCallback('onclick', function(self)
		GetWidget('overlay_chat_' .. type .. channelID .. '_input'):ProcessInputLine()
		FocusChatWindow(self)
	end)		
	GetWidget('overlay_chat_' .. type .. channelID .. '_input_btn'):RefreshCallbacks()	
	
	GetWidget('overlay_chat_' .. type .. channelID .. '_frame'):SetCallback('onmouseldown', function(self) FocusChatWindow(self) end)
	GetWidget('overlay_chat_' .. type .. channelID .. '_frame'):SetCallback('onmouselup', function(self) FocusChatWindow(self) end)
	GetWidget('overlay_chat_' .. type .. channelID .. '_frame'):SetCallback('onclick', function(self) FocusChatWindow(self) end)	
	GetWidget('overlay_chat_' .. type .. channelID .. '_frame'):RefreshCallbacks()
		
	GetWidget('overlay_chat_' .. type .. channelID .. '_buffer'):SetCallback('onmouseldown', function(self) FocusChatWindow(self) end)
	GetWidget('overlay_chat_' .. type .. channelID .. '_buffer'):SetCallback('onmouselup', function(self) FocusChatWindow(self) end)
	GetWidget('overlay_chat_' .. type .. channelID .. '_buffer'):SetCallback('onfocus', function(self) FocusChatWindow(self) end)	
	GetWidget('overlay_chat_' .. type .. channelID .. '_buffer'):SetCallback('onclick', function(self) FocusChatWindow(self) end)	
	GetWidget('overlay_chat_' .. type .. channelID .. '_buffer'):RefreshCallbacks()
	
	-- GetWidget('mainChat' .. type .. channelID .. 'Buffer'):SetCallback('onmouseldown', function(self) FocusChatWindow(self) end)
	-- GetWidget('mainChat' .. type .. channelID .. 'Buffer'):SetCallback('onmouselup', function(self) FocusChatWindow(self) end)
	-- GetWidget('mainChat' .. type .. channelID .. 'Buffer'):SetCallback('onfocus', function(self) FocusChatWindow(self) end)
	-- GetWidget('mainChat' .. type .. channelID .. 'Buffer'):SetCallback('onclick', function(self) FocusChatWindow(self) end)		
	-- GetWidget('mainChat' .. type .. channelID .. 'Buffer'):RefreshCallbacks()

end

function LeaveChannel(channelID)
	--println('^y LeaveChannel ' .. channelID)
	local channelLoaded = Windows.Chat.Channel[channelID] and (Windows.Chat.Channel[channelID]:IsValid())
	if channelLoaded then
		RemoveFromMyGroups(channelID, Windows.Chat.Channel[channelID][1])
	end
	ChatClient.LeaveChannel((channelID))
	if channelLoaded then
		Windows.Chat.Channel[channelID]:Close()
	end
	Windows.Chat.Channel[channelID] = nil	
	for i=1, WINDOW_CHAT_CHANNEL_INSTANCES_MAX, 1 do
		if (Windows.data.chat.channel.widgets[i] == channelID) then
			Windows.data.chat.channel.widgets[i] = nil
			break
		end
	end	
	ChatClient.ForceInterfaceUpdate()
	RecalculateFooterWidgets()
	libThread.threadFunc(function()
		wait(50)
		RecalculateFooterWidgets()
	end)	
end

local function LeaveConversation(channelID)
	--println('^y LeaveConversation ' .. channelID)
	ChatClient.LeaveConversation(channelID)
	if (Windows.Chat.IM[channelID]) and (Windows.Chat.IM[channelID]:IsValid()) then
		Windows.Chat.IM[channelID]:Close()
	end
	Windows.Chat.IM[channelID] = nil
	for i=1, WINDOW_CHAT_IM_INSTANCES_MAX, 1 do
		if (Windows.data.chat.im.widgets[i] == channelID) then
			Windows.data.chat.im.widgets[i] = nil
			break
		end
	end		
	ChatClient.ForceInterfaceUpdate()
	RecalculateFooterWidgets()
	libThread.threadFunc(function()
		wait(50)
		RecalculateFooterWidgets()
	end)	
end

local function LeftChannel(channelID)
	--println('^y LeftChannel ' .. tostring(channelID))
	local channelID = tostring(channelID)
	if (mainUI.chatManager) and (mainUI.chatManager.activeChannels) and (mainUI.chatManager.activeChannels[channelID]) and (mainUI.chatManager.activeChannels[channelID][1]) then
		if GetWidget('overlay_chat_' .. mainUI.chatManager.activeChannels[channelID][4] .. channelID .. '_parent', nil, true) then
			GetWidget('overlay_chat_' .. mainUI.chatManager.activeChannels[channelID][4] .. channelID .. '_parent'):SetVisible(false)
			GetWidget('overlay_chat_' .. mainUI.chatManager.activeChannels[channelID][4] .. channelID .. '_parent'):Destroy()
		end
		if GetWidget('main_footer_chat_tab_' .. mainUI.chatManager.activeChannels[channelID][4] .. channelID, nil, true) then
			GetWidget('main_footer_chat_tab_' .. mainUI.chatManager.activeChannels[channelID][4] .. channelID):Destroy()
		end
	end
	mainUI.chatManager.memberlist[channelID] = nil
	mainUI.chatManager.activeChannels[channelID] = nil
	mainUI.chatManager.pinnedChannels[channelID] = nil	
	RecalculateFooterWidgets() 
	libThread.threadFunc(function()
		wait(50)
		RecalculateFooterWidgets()
	end)
end

function JoinChannel(channelID, channelName, subscribe)
	println('^y JoinChannel ' .. tostring(channelID) .. ' ' .. tostring(channelName))
	if subscribe then
		AddToMyGroups(channelID, channelName)
	end
	mainUI.chatManager.lastUserJoinedChannel = channelID or channelName
	mainUI.chatManager.queMyGroupsRebuild = true
	ChatClient.JoinChannel(channelName, channelID)
	ChatClient.ForceInterfaceUpdate()
	RecalculateFooterWidgets()
	libThread.threadFunc(function()
		wait(50)
		RecalculateFooterWidgets()
	end)	
end

function mainUI.LeavePinnedChannel(sourceWidget, channelID)	
	local channelID = tostring(channelID)
	
	if (mainUI.chatManager.activeChannels[channelID]) and (mainUI.chatManager.activeChannels[channelID][1]) then
		if GetWidget('overlay_chat_' .. mainUI.chatManager.activeChannels[channelID][4] .. channelID .. '_parent', nil, true) then
			GetWidget('overlay_chat_' .. mainUI.chatManager.activeChannels[channelID][4] .. channelID .. '_parent'):SetVisible(false)
			GetWidget('overlay_chat_' .. mainUI.chatManager.activeChannels[channelID][4] .. channelID .. '_parent'):Destroy()
		end
		if GetWidget('main_footer_chat_tab_' .. mainUI.chatManager.activeChannels[channelID][4] .. channelID, nil, true) then
			GetWidget('main_footer_chat_tab_' .. mainUI.chatManager.activeChannels[channelID][4] .. channelID):Destroy()
		end			
		if mainUI.chatManager.activeChannels[channelID][4] ~= 'pm' then
			LeaveChannel(channelID)
		else
			LeaveConversation(channelID)
		end
		if (Windows.Chat.Channel) and (Windows.Chat.Channel[channelID]) and (Windows.Chat.Channel[channelID]:IsValid()) then
			FreeInterfaceSlot('channel', channelID)
			Windows.Chat.Channel[channelID]:Close()	
			Windows.Chat.Channel[channelID] = nil
		end
		if (Windows.Chat.IM) and (Windows.Chat.IM[channelID]) and (Windows.Chat.IM[channelID]:IsValid()) then
			FreeInterfaceSlot('im', channelID)
			Windows.Chat.IM[channelID]:Close()	
			Windows.Chat.IM[channelID] = nil
		end			
		mainUI.chatManager.memberlist[channelID] = nil
		mainUI.chatManager.activeChannels[channelID] = nil
		mainUI.chatManager.pinnedChannels[channelID] = nil		
	else
		LeaveChannel(channelID)
	end
end

function mainUI.TeamInputBufferRegister(self, channelID, channelName, chatType)		

	self:SetOutputWidget(GetWidget('mainChat' .. chatType .. channelID .. 'Buffer'))

	self:GetParent():RegisterWatchLua('KeyDown', function(widget, trigger) 	
		if (trigger.enter) then 
			local triggerPanelStatus		= LuaTrigger.GetTrigger('mainPanelStatus')
			if (self:IsVisible()) and (self:HasFocus()) then

			elseif (triggerPanelStatus.main == 40) and (mainUI.chatManager.channelAtFrontId == channelID) then
				if (not self:HasFocus()) then
					self:SetFocus(true)
				end	
			else

			end
		end
	end, true, nil, 'enter')
	
	self:GetParent():RegisterWatchLua('KeyDown', function(widget, trigger) 	
		if (trigger.esc) then
			if (self:HasFocus()) then
				self:SetFocus(false)
			end
		end
	end, true, nil, 'esc')

	self:SetChannelID(tostring(channelID))

end

function mainUI.InputBufferRegister(self, channelID, channelName, chatType)		
	
	self:SetOutputWidget(GetWidget('mainChat' .. chatType .. channelID .. 'Buffer'))

	self:GetParent():RegisterWatchLua('KeyDown', function(widget, trigger) 	
		if (trigger.enter) then
			if (self:IsVisible()) and (self:HasFocus()) then

			elseif (mainUI.chatManager.lastActiveChannelID == channelID) then
				if (self:IsVisible()) and (not self:HasFocus()) then
					-- println('^g EnterPressedTrigger ')
					self:SetFocus(true)
				else
					-- println('^c EnterPressedTrigger 1')
				end		
			else
				-- println('^c EnterPressedTrigger 2')
			end
		end
	end, true, nil, 'enter')
	
	self:GetParent():RegisterWatchLua('KeyDown', function(widget, trigger) 	
		if (trigger.esc) then
			if (self:IsVisible()) and (self:HasFocus()) then
				self:SetFocus(false)
			end
		end
	end, true, nil, 'esc')

	if (chatType == 'channel') or (chatType == 'invisible_channel') then
		-- println(' InputBufferRegister SetChannelID ' .. channelID)
		self:SetChannelID(tostring(channelID)) 
	else
		-- println(' InputBufferRegister SetIdentID ' .. channelID)
		self:SetIdentID(tostring(channelID))
	end
	
	if (channelID == 'Game') then

		self:SetStream('all')
		self:SetInputLine('')
		self:RegisterWatchLua('mainPanelStatus', function(widget, trigger) 
			if (trigger.gamePhase <= 1) then
				widget:SetStream('all')
			else
				widget:SetStream('team')
			end
		end, false, nil, 'gamePhase')	
	
	else
		-- self:SetStream('public')
	end

	mainUI.SlashCommands.RegisterInput(self, channelID, channelName, chatType)

end

function mainUI.OutputBufferRegister(self, channelID, channelName, chatType)				
	
	self:SetInputWidget(GetWidget('overlay_chat_' .. chatType .. channelID .. '_input'))

	-- println('^y OutputBufferRegister ' .. chatType)
	
	if (chatType == 'channel') or (chatType == 'invisible_channel') then
		-- println(' OutputBufferRegister SetChannelID ' .. channelID)
		self:SetChannelID(tostring(channelID)) 
	else
		-- println(' OutputBufferRegister SetIdentID ' .. channelID)
		self:SetIdentID(tostring(channelID))
	end	
	
	if (channelID == 'Game') then
	
		self:SetBaseOverselfCursor('/core/cursors/k_text_select.cursor')
		self:SetBaseSenderOverselfCursor('/core/cursors/arrow.cursor')

		self:SetBaseFormat('{timestamp}{tag}{sender}: {message}')
		self:SetBaseTextColor('#ffffff')
		self:SetBaseSenderTextColor('#88FFff')
		self:SetBaseMessageTextColor('#ffffff')	
	
		self:SetStreamFormat('all', '{timestamp}{tag}{sender}: {message}')
		self:SetStreamTextColor('all', '#ffffff')
		self:SetStreamSenderTextColor('all', '#FFff88')
		self:SetStreamMessageTextColor('all', '#ffffff')
		
		self:SetStreamFormat('team', '{timestamp}{tag}{sender}: {message}')
		self:SetStreamTextColor('team', '#ffffff')
		self:SetStreamSenderTextColor('team', '#88FFff')
		self:SetStreamMessageTextColor('team', '#ffffff')
		
	elseif (channelID == 'Party') then
		
		self:SetBaseOverselfCursor('/core/cursors/k_text_select.cursor')
		self:SetBaseSenderOverselfCursor('/core/cursors/arrow.cursor')

		self:SetBaseFormat('{timestamp}{tag}{sender}: {message}')
		self:SetBaseTextColor('#ffffff')
		self:SetBaseSenderTextColor('#88FFff')
		self:SetBaseMessageTextColor('#ffffff')		
		
		self:SetStreamFormat('all', '{timestamp}{tag}{sender}: {message}')
		self:SetStreamTextColor('all', '#ffffff')
		self:SetStreamSenderTextColor('all', '#FFff88')
		self:SetStreamMessageTextColor('all', '#ffffff')
		
		self:SetStreamFormat('team', '{timestamp}{tag}{sender}: {message}')
		self:SetStreamTextColor('team', '#ffffff')
		self:SetStreamSenderTextColor('team', '#88FFff')
		self:SetStreamMessageTextColor('team', '#ffffff')	
	
		-- self:RegisterWatchLua('HeroSelectInfo', function(widget, trigger)
			-- if (trigger.type == 'party') then
				-- self:SetStream('all')
				-- self:SetInputLine('')
			-- else
				-- self:SetStream('team')
				-- self:SetInputLine('')		
			-- end
		-- end, false, nil, 'type')		
		
	else
		
		self:SetBaseOverselfCursor('/core/cursors/k_text_select.cursor')
		self:SetBaseSenderOverselfCursor('/core/cursors/arrow.cursor')

		self:SetBaseFormat('{timestamp}{tag}{sender}: {message}')
		self:SetBaseTextColor('#ffffff')
		self:SetBaseSenderTextColor('#88FFff')
		self:SetBaseMessageTextColor('#ffffff')
		
		self:SetStreamFormat('public', '{timestamp}{tag}{sender}: {message}')
		self:SetStreamTextColor('public', '#ffffff')
		self:SetStreamSenderTextColor('public', '#88FFff')
		self:SetStreamMessageTextColor('public', '#ffffff')
		-- self:SetStreamOverselfOutline('public', true)
		-- self:SetStreamSenderOverselfOutlineColor('public', 'lime')
		-- self:SetStreamSenderOverselfTextColor('public', '#0000ff')
		-- self:SetStreamSenderOverselfUnderline('public', true)
		-- self:SetStreamMessageOverselfOutlineColor('public', 'blue')
		-- self:SetStreamMessageOverselfUnderline('public', true)
		-- self:SetStreamOverselfColorCodeFactor('public', 0.5)
		-- self:SetStreamOversiblingOutline('public', true)
		-- self:SetStreamOversiblingOutlineColor('public', '#ff0000')
		-- self:SetStreamOversiblingColorCodeFactor('public', 0.5)	
		-- self:SetStreamOversiblingTextColor('public', '#70ff70')
		-- self:SetStreamOversiblingShadowColor('public', '#ffffff')
		-- self:SetStreamSenderOversiblingUnderline('public', true)
		-- self:SetStreamMessageOversiblingOutlineColor('public', 'blue')
		
		self:SetStreamFormat('member', '{timestamp}{member_chat} {sender}: {message}')
		self:SetStreamTextColor('member', '#88FF88')
		self:SetStreamSenderTextColor('member', '#88FF88')
		self:SetStreamMessageTextColor('member', '#88FF88')
		
		self:SetStreamFormat('officer', '{timestamp}{officer_chat} {sender}: {message}')
		self:SetStreamTextColor('officer', '#ffaa00')
		self:SetStreamSenderTextColor('officer', '#ffaa00')
		self:SetStreamMessageTextColor('officer', '#ffaa00')
		
		self:SetBaseSenderOverselfTextColor('#ffff88')
		self:SetBaseMessageOversiblingTextColor('#00bbff')
		self:SetBaseMessageOverselfTextColor('#00bbff')
	end
end

local chatPMLastTime	= {}
local chatPMThrottle	= 5000

object:RegisterWatchLua('ChatPrivateMessage', function(widget, trigger) 
	if (not IsMe(trigger.senderIdentID)) and (not IsOpponent(trigger.senderIdentID)) and (not GetCvarBool('ui_whisperRequiresFriendship') or ChatClient.IsFriend(trigger.senderIdentID)) then
	
		local channelID					 = tostring(trigger.senderIdentID)
		local triggerPanelStatus		= LuaTrigger.GetTrigger('mainPanelStatus')
		local channel_instance			= LuaTrigger.GetTrigger('main_footer_chat_tab_' .. 'pm' .. channelID)
		
		if (not channelID) then
			return
		end

		if (not mainUI.chatManager.activeChannels[channelID]) and (not channel_instance) then
			mainUI.chatManager.InitPrivateMessage(channelID, nil, trigger.senderName)
			
			mainUI.chatManager.pinnedChannels[channelID] = false
			ChatClient.SetChannelPinned(channelID,false)
			interface:GetWidget('main_footer_chat_tab_pm' .. channelID .. '_4'):SetTexture('/ui/main/footer/textures/message_bubble.tga')
		end
		
		if trigger.unread then	
			local chatParent = interface:GetWidget('overlay_chat_' .. 'pm' .. channelID .. '_parent')
			
			if (mainUI.chatManager.pinnedChannels[channelID]) and (mainUI.chatManager.channelAtFrontId == channelID) and (chatParent) and (chatParent:IsVisible()) then
				mainUI.chatManager.unreadMessages[tostring(channelID)] = nil
			else
				if (mainUI.chatManager.unreadMessages[tostring(channelID)]) then
					mainUI.chatManager.unreadMessages[tostring(channelID)] = (mainUI.chatManager.unreadMessages[tostring(channelID)] + 1)
				else
					mainUI.chatManager.unreadMessages[tostring(channelID)] = 1
				end
			end

			if chatParent and ((not chatParent:IsVisible()) or (not LuaTrigger.GetTrigger('System').hasFocus)) then
				local thisTime = GetTime()
				if (not chatPMLastTime['pm'..channelID]) or (thisTime > chatPMLastTime['pm'..channelID] + chatPMThrottle) then
					chatPMLastTime['pm'..channelID] = thisTime
					PlaySound('/ui/sounds/social/sfx_chat_new.wav')
				end
			end
			
		end
		
		chatUnreadMessageTrigger.updatedChannel = channelID
		chatUnreadMessageTrigger:Trigger(true)	
		
	end
	RecalculateFooterWidgets()
end)

function mainUI.chatManager.SaveChatWindowPositionAndSize(self, chatType, channelID)
	
	UpdateDefaults()
	
	local windowRef = self:GetWindow()
	if (windowRef) then
		local windowHeight = windowRef:GetHeight()
		local windowWidth = windowRef:GetWidth()
		local windowX = windowRef:GetX()
		local windowY = windowRef:GetY()
		
		mainUI.savedLocally 														= mainUI.savedLocally or {}
		mainUI.savedLocally.chatSettings 											= mainUI.savedLocally.chatSettings or {}
		mainUI.savedLocally.chatSettings[chatType] 									= mainUI.savedLocally.chatSettings[chatType] or {}
		mainUI.savedLocally.chatSettings[chatType][channelID] 						= mainUI.savedLocally.chatSettings[chatType][channelID] or {}
		mainUI.savedLocally.chatSettings[chatType][channelID].windowHeight 			= windowHeight or mainUI.savedLocally.chatSettings[chatType][channelID].windowHeight 	or defaultChatWindowHeight
		mainUI.savedLocally.chatSettings[chatType][channelID].windowWidth 			= windowWidth or mainUI.savedLocally.chatSettings[chatType][channelID].windowWidth  	or defaultChatWindowWidth
		mainUI.savedLocally.chatSettings[chatType][channelID].windowX 				= windowX or mainUI.savedLocally.chatSettings[chatType][channelID].windowX  		or defaultChatWindowX
		mainUI.savedLocally.chatSettings[chatType][channelID].windowY 				= windowY or mainUI.savedLocally.chatSettings[chatType][channelID].windowY  		or defaultChatWindowY
		SaveState()
	end
end
	
function ChatNewChannel(widget, channelID, channelName, isGameChat)
	
	local channelID					 = tostring(channelID)
	local triggerPanelStatus		= LuaTrigger.GetTrigger('mainPanelStatus')
	local channel_instance			= LuaTrigger.GetTrigger('main_footer_chat_tab_' .. 'channel' .. channelID)
	local isLobbyChat, isPartyChat, isScrimChat, isClanChat 	= false, false, false, false
	
	if (not channelID) or (channelID == '') then
		return
	elseif (channelID == 'Status') then
		return
	elseif (channelID == 'Game') then
		isLobbyChat = true
		mainUI.chatManager.lobbyID = channelID
		mainUI.chatManager.lobbyName = channelName
	elseif (channelID == 'Party') then
		isPartyChat = true
		mainUI.chatManager.partyID = channelID
		mainUI.chatManager.partyName = channelName		
	elseif (channelID == 'Scrim') or (channelName and (channelName == ('Scrim_' .. GetCvarString('host_language'))))  then
		isScrimChat = true	
		ScrimFinder.scrimChannelID = channelID
	elseif (channelID == 'Clan') or (channelName and channelName == ('Clan'))  then
		isClanChat = true
		return		
	end

	if (mainUI.chatManager.activeChannels[channelID]) or (channel_instance) then
		return
	end

	-- println('^666 ChatNewChannel ' .. tostring(channelID) .. ' ' .. tostring(channelName))
	
	mainUI.chatManager.activeChannels[channelID] = {channelName, channelID, isGameChat, 'channel'}	
	mainUI.chatManager.pinnedChannels[channelID] = false
	
	local groupIcon = '/ui/shared/textures/user_icon.tga'
	
	mainUI.savedLocally.subscribedGroups = mainUI.savedLocally.subscribedGroups or {}
	if (mainUI.savedLocally.subscribedGroups) and (mainUI.savedLocally.subscribedGroups[channelName]) and (mainUI.savedLocally.subscribedGroups[channelName].groupIcon) and (not Empty(mainUI.savedLocally.subscribedGroups[channelName].groupIcon)) then
		groupIcon = mainUI.savedLocally.subscribedGroups[channelName].groupIcon
	end

	mainUI.chatManager.localActiveChannelInt = mainUI.chatManager.localActiveChannelInt + 1
	
	UpdateDefaults()
	
	if (not isScrimChat) then
		
		local availableIndex = 0
		for i=1, WINDOW_CHAT_CHANNEL_INSTANCES_MAX, 1 do
			if (Windows.data.chat.channel.widgets[i] == nil) then
				Windows.data.chat.channel.widgets[i] = channelID
				availableIndex = i
				break
			end
		end		
		
		if (availableIndex > 0) then
			-- Strife taskbar footer entry
			if (not GetWidget('main_footer_chat_tab_channel' .. channelID, nil, true)) then
				local chatFooterTabWidgets = GetWidget('main_chat_footer_overlay'):InstantiateAndReturn('footer_chat_tabs_large_pinned', 
					'channelID', channelID,
					'channelName', mainUI.chatManager.activeChannels[channelID][1],
					'type', 'channel'
				)
			end
			
			-- Multiwindow chat window - simple version
			local width 							= widget:GetWidthFromString(defaultChatWindowWidth)
			local height 							= widget:GetHeightFromString(defaultChatWindowHeight)
			local x 								= widget:GetXFromString(defaultChatWindowX)
			local y 								= widget:GetYFromString(defaultChatWindowY)
			
			if (mainUI.savedLocally) and (mainUI.savedLocally.chatSettings) and (mainUI.savedLocally.chatSettings.channel) and (mainUI.savedLocally.chatSettings.channel[channelID]) and (mainUI.savedLocally.chatSettings.channel[channelID].windowHeight) then
				height = mainUI.savedLocally.chatSettings.channel[channelID].windowHeight
			end	
			if (mainUI.savedLocally) and (mainUI.savedLocally.chatSettings) and (mainUI.savedLocally.chatSettings.channel) and (mainUI.savedLocally.chatSettings.channel[channelID]) and (mainUI.savedLocally.chatSettings.channel[channelID].windowWidth) then
				width = mainUI.savedLocally.chatSettings.channel[channelID].windowWidth
			end		
			if (mainUI.savedLocally) and (mainUI.savedLocally.chatSettings) and (mainUI.savedLocally.chatSettings.channel) and (mainUI.savedLocally.chatSettings.channel[channelID]) and (mainUI.savedLocally.chatSettings.channel[channelID].windowX) then
				x = mainUI.savedLocally.chatSettings.channel[channelID].windowX
			end		
			if (mainUI.savedLocally) and (mainUI.savedLocally.chatSettings) and (mainUI.savedLocally.chatSettings.channel) and (mainUI.savedLocally.chatSettings.channel[channelID]) and (mainUI.savedLocally.chatSettings.channel[channelID].windowY) then
				y = mainUI.savedLocally.chatSettings.channel[channelID].windowY
			end		

			local isPositionIsValid = false
			for _, v in pairs(System.GetAllMonitorRects()) do
				if (((interface:GetXFromString(x)) + interface:GetWidthFromString(width)) <= (v.left + v.right)) 
				and (((interface:GetYFromString(y)) + interface:GetHeightFromString(height)) <= (v.top + v.bottom)) then
					isPositionIsValid = true
				end
			end		
			
			if (not isPositionIsValid) then
				width 							= interface:GetWidthFromString(defaultChatWindowWidth)
				height 							= interface:GetHeightFromString(defaultChatWindowHeight)
				x 								= interface:GetXFromString(defaultChatWindowX)
				y 								= interface:GetYFromString(defaultChatWindowY)		
			end			
			
			Windows.data 							= Windows.data 						or {}
			Windows.data.chat 						= Windows.data.chat  				or {}
			Windows.data.chat.channel 				= Windows.data.chat.channel  		or {}
			Windows.data.chat.channel.creatingChannelID   = channelID		
			Windows.data.chat.channel.creatingChannelName = mainUI.chatManager.activeChannels[channelID][1]		
			Windows.Chat 							= Windows.Chat 						or {}
			Windows.Chat.Channel 					= Windows.Chat.Channel 				or {}
		
			Windows.Chat.Channel[channelID] 		= Windows.Chat.Channel[channelID] 	or Window.New(
				x,
				y,
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
					-- Window.MINIMIZED,
					-- Window.APP,
				},
				"/ui_dev/chat/ugh/chat_window_" .. availableIndex .. ".interface",
				Translate(mainUI.chatManager.activeChannels[channelID][1])
			)

			Windows.Chat.Channel[channelID]:SetSizingBounds((widget:GetWidthFromString(defaultChatWindowWidth) * 0.8), (widget:GetHeightFromString(defaultChatWindowHeight) * 0.6), (widget:GetWidthFromString(defaultChatWindowWidth) * 5.0), (widget:GetHeightFromString(defaultChatWindowHeight) * 5.0))
			Windows.Chat.Channel[channelID]:SetCloseCallback(function()
				if (isLobbyChat) or (isPartyChat) then
					Windows.Chat.Channel[channelID] = nil	
					for i=1, WINDOW_CHAT_CHANNEL_INSTANCES_MAX, 1 do
						if (Windows.data.chat.channel.widgets[i] == channelID) then
							Windows.data.chat.channel.widgets[i] = nil
							break
						end
					end	
					ChatClient.ForceInterfaceUpdate()
					RecalculateFooterWidgets()	
					LeftChannel(channelID)
				else
					LeaveChannel(channelID)		
				end
			end)
			
			if (mainUI.chatManager.lastUserJoinedChannel == channelID) or (mainUI.chatManager.lastUserJoinedChannel == channelName) or (mainUI.chatManager.lastUserJoinedChannel == mainUI.chatManager.activeChannels[channelID][1]) then
				mainUI.chatManager.ClickedPinnedChatTab(widget, channelName, channelID, false, false, 'channel') 
			end			
			
		end

	else
	
		if (not GetWidget('overlay_chat_channel' .. channelID ..'_parent', nil, true)) then
			GetWidget('scrim_finder_chat'):Instantiate('scrim_finder_chat_template',
				'channelID', channelID,
				'bufferChannel', channelID,
				'channelName', mainUI.chatManager.activeChannels[channelID][1],
				'group', 'pin_main_chat_channel_outputbuffers',
				'type', 'channel'
			)		
		end	
	
	end
	
	if (isPartyChat) then
	
		if (not GetWidget('overlay_chat_invisible_channel' .. channelID ..'_parent', nil, true)) then
			GetWidget('selection_chat_base'):Instantiate('chat_overlay_channel_invisible_template',
				'channelID', channelID,
				'bufferChannel', channelID,
				'channelName', mainUI.chatManager.activeChannels[channelID][1],
				'group', 'pin_main_chat_channel_outputbuffers',
				'type', 'invisible_channel'
			)	
		end
				
		GetWidget('selection_chat_base'):RegisterWatchLua('PartyComboStatus', function(widget, groupTrigger)
			if ((mainUI.featureMaintenance) and (not mainUI.featureMaintenance['party'])) then

				local partyStatusTrigger				= groupTrigger['PartyStatus']
				local partyCustomTrigger 				= groupTrigger['PartyTrigger']
				local clientInfoDrag  					= groupTrigger['clientInfoDrag']
				local mainPanelAnimationStatus  		= groupTrigger['mainPanelAnimationStatus']
				local mainPanelStatus  					= groupTrigger['mainPanelStatus']
				local selection_Status  				= groupTrigger['selection_Status']

				if (mainPanelAnimationStatus.main > 0) and ((partyStatusTrigger.inParty) and ((partyStatusTrigger.numPlayersInParty > 1) ) or (clientInfoDrag.dragActive and clientInfoDrag.clientDraggingIsOnline)) then
					if (mainPanelAnimationStatus.main ~= 102) or (mainPanelStatus.main ~= 102) or (selection_Status.selectionSection ~= mainUI.Selection.selectionSections.HERO_PICK) then
						if GetWidget('main_footer_chat_tab_channelParty', nil, true) then -- footer button for party chat
							GetWidget('main_footer_chat_tab_channelParty', nil, true):FadeIn(250)
							RecalculateFooterWidgets()
						end
						if GetWidget('overlay_chat_invisible_channelParty_parent', nil, true) then -- hero pick invis party chat
							GetWidget('overlay_chat_invisible_channelParty_parent', nil, true):SetVisible(0)
							RecalculateFooterWidgets()
						end						
					else
						if GetWidget('main_footer_chat_tab_channelParty', nil, true) then	-- footer button for party chat
							-- GetWidget('main_footer_chat_tab_channelParty', nil, true):SetVisible(0)
							RecalculateFooterWidgets()
						end
						-- if GetWidget('overlay_chat_channelParty_parent', nil, true) then	-- regular party chat window
							-- GetWidget('overlay_chat_channelParty_parent', nil, true):SetVisible(0)
							-- RecalculateFooterWidgets()
						-- end
						if GetWidget('overlay_chat_invisible_channelParty_parent', nil, true) then -- hero pick invis party chat
							GetWidget('overlay_chat_invisible_channelParty_parent', nil, true):FadeIn(750)
							RecalculateFooterWidgets()
						end
					end
				else
					if GetWidget('main_footer_chat_tab_channelParty', nil, true) then -- footer button for party chat
						GetWidget('main_footer_chat_tab_channelParty', nil, true):SetVisible(0)
						RecalculateFooterWidgets()
					end
					if GetWidget('overlay_chat_invisible_channelParty_parent', nil, true) then -- hero pick invis party chat
						GetWidget('overlay_chat_invisible_channelParty_parent', nil, true):SetVisible(0)
						RecalculateFooterWidgets()
					end				
				end
			end
		end)		
		
		GetWidget('selection_chat_base'):RegisterWatchLua('MainBGMouseEvent', function(widget, trigger)
			if (trigger.onmouseover) and GetWidget('mainChatinvisible_channelPartyBuffer', nil, true) then
				groupfcall('overlay_chat_invisible_channelParty_visobj', function(_, widget) widget:FadeOut(500) end)
				GetWidget('mainChatinvisible_channelPartyBuffer'):SetNoClick(1)
			end
		end, false, nil, 'onmouseover')
		GetWidget('selection_chat_base'):RefreshCallbacks()		
		
	end

	triggerPanelStatus.chatConnectionState = 2
	triggerPanelStatus:Trigger(false)
	
	RecalculateFooterWidgets()
	
end

local function InitMainChat()
	
	println('UpdateChat')
	
	local function UpdateChat()

		local triggerPanelStatus		= LuaTrigger.GetTrigger('mainPanelStatus')

		if (not triggerPanelStatus.chatConnected) and (triggerPanelStatus.chatConnectionState ~= 0) then

			triggerPanelStatus.chatConnected = true
			
			mainUI.chatManager.localActiveChannelInt = 0
			mainUI.chatManager.queMyGroupsRebuild = true
			
			ChatClient.ForceInterfaceUpdate()	
			
            -- Adding club tab to chat tabs
            -- Disabled until Clubs reimplemented again
			--[=====[
			libThread.threadFunc(function(thread)
				local channelID = 'Clan'
				local npeComplete = (NewPlayerExperience.trigger.tutorialProgress >= NPE_PROGRESS_TUTORIALCOMPLETE) or (NewPlayerExperience.trigger.tutorialComplete) or (not NewPlayerExperience.enabled)
				if (interface) and (interface:IsValid()) and (interface:GetWidget('main_footer_chat_tab_' .. 'channel' .. channelID)) and (interface:GetWidget('main_footer_chat_tab_' .. 'channel' .. channelID):IsValid()) then
					if (npeComplete) then
						interface:GetWidget('main_footer_chat_tab_' .. 'channel' .. channelID):SetVisible(1)
					else
						interface:GetWidget('main_footer_chat_tab_' .. 'channel' .. channelID):SetVisible(0)
					end			
				else
					GetWidget('main_chat_footer_overlay'):InstantiateAndReturn('footer_chat_tabs_large_pinned', 
							'channelID', channelID,
							'channelName', 'Clan',
							'channelDisplayName', Translate('window_name_brawl_club'),
							'type', 'channel'
					)
					if (npeComplete) then
						interface:GetWidget('main_footer_chat_tab_' .. 'channel' .. channelID):SetVisible(1)
						mainUI.chatManager.activeChannels[channelID] = {'Clan', channelID, false, 'channel'}
					else
						interface:GetWidget('main_footer_chat_tab_' .. 'channel' .. channelID):SetVisible(0)
					end				
				end
				wait(1)
				RecalculateFooterWidgets()

			end)
			--]=====]
			
		elseif (triggerPanelStatus.chatConnected) and (triggerPanelStatus.chatConnectionState == 0) then

			triggerPanelStatus.chatConnected = false
			
			mainUI.chatManager.activeChannels = {}
			mainUI.chatManager.localActiveChannelInt = 0
			mainUI.chatManager.queMyGroupsRebuild = true			
			
			groupfcall('footer_chat_tabs_large_pinned_templates_pm', function(index, widget, groupName) widget:Destroy() end)
			groupfcall('footer_chat_tabs_large_pinned_templates_channel', function(index, widget, groupName) widget:Destroy() end)
			groupfcall('chat_overlay_channel_single_templates', function(index, widget, groupName) widget:Destroy() end)
			RecalculateFooterWidgets()

		end	
		
		-- Leave Game Lobby Chats
		-- if (trigger.gamePhase == 0) then
			-- if (mainUI.chatManager.activeChannels['Game']) and (mainUI.chatManager.activeChannels['Game'][1]) then
				  -- mainUI.LeavePinnedChannel(widget, 'Game')
			-- end
		-- end	
	end
	
	interface:GetWidget('main_chat_base'):RegisterWatchLua('mainPanelStatus', function(widget, trigger)
		UpdateChat()
	end)

	interface:RegisterWatchLua(
		'ChatNewChannel', function(sourceWidget, trigger)
			ChatNewChannel(sourceWidget, trigger.channelID, trigger.channelName, 'false')
		end
	)
	
	interface:RegisterWatchLua(
		'ChatLeftChannel', function(sourceWidget, trigger)
			LeftChannel(trigger.channelID, nil)	
		end
	)	

	mainUI.chatManager.unreadMessages = {}

	local flashChannelTabThreads = {}
	
	interface:RegisterWatchLua('ChatUnreadMessageTrigger', function(sourceWidget, trigger)
		local updatedChannel = trigger.updatedChannel
		
		if flashChannelTabThreads[updatedChannel] ~= nil then
			flashChannelTabThreads[updatedChannel]:kill()
			flashChannelTabThreads[updatedChannel] = nil
		end
		
		flashChannelTabThreads[updatedChannel] = libThread.threadFunc(function()
			
			if (updatedChannel) and (updatedChannel ~= '') and (updatedChannel ~= '-1') then
				local function AnimateNewMessage(channelID)
					local channelTable = mainUI.chatManager.activeChannels[tostring(channelID)]
					if (channelTable) then
						if (Windows.Chat.IM[channelID]) and (Windows.Chat.IM[channelID]:IsValid()) then
							Windows.Chat.IM[channelID]:FlashWindow()
						end
						if (Windows.Chat.Channel[channelID]) and (Windows.Chat.Channel[channelID]:IsValid()) then
							Windows.Chat.Channel[channelID]:FlashWindow()
						end						
						for i = 1, 4 do
							local color = '1 1 1 1' -- used to be orange
							if (i%2==0) then  color = '1 1 1 1' end -- used to be blue
							-- note : if we disconnect these widgets will disappear, make sure they exist for each blink
							local w1 = GetWidget('main_footer_chat_tab_' .. channelTable[4] .. '' .. channelID .. '_1', nil, true)
							local w2 = GetWidget('main_footer_chat_tab_' .. channelTable[4] .. '' .. channelID .. '_2', nil, true)
							local w3 = GetWidget('main_footer_chat_tab_' .. channelTable[4] .. '' .. channelID .. '_3', nil, true)
							if w1 and w2 and w3 then
								if (i==1) then
									w1:SetTexture('/ui/main/footer/textures/social_tab_msg_l.tga')
									w2:SetTexture('/ui/main/footer/textures/social_tab_msg_c.tga')
									w3:SetTexture('/ui/main/footer/textures/social_tab_msg_l.tga')	
								end
								w1:SetColor(color)
								w2:SetColor(color)
								w3:SetColor(color)
							end
							
							--flash container too if stacked
							if #footerWidgets > 10 then
								local group = channelTable[4] == 'channel' and 1 or 2
								w1 = GetWidget('main_footer_chat_tab_group_'..group..'_1', nil, true)
								w2 = GetWidget('main_footer_chat_tab_group_'..group..'_2', nil, true)
								w3 = GetWidget('main_footer_chat_tab_group_'..group..'_3', nil, true)
								if w1 and w2 and w3 then
									if (i==1 or i==4) then
										texture = i==1 and '/ui/main/footer/textures/social_tab_msg_' or '/ui/main/footer/textures/social_tab_std_'
										w1:SetTexture(texture..'l.tga')
										w2:SetTexture(texture..'c.tga')
										w3:SetTexture(texture..'r.tga')	
									end
									if (i==4) then  color = '1 1 1 1' end --white
									w1:SetColor(color)
									w2:SetColor(color)
									w3:SetColor(color)
								end
							end
							
							if i<4 then wait(350) end
						end
						flashChannelTabThreads[updatedChannel] = nil		
					end
				end
				AnimateNewMessage(updatedChannel)		
			end
			
			for channelID, v in pairs(mainUI.chatManager.pinnedChannels) do
				if (v) and (mainUI.chatManager.channelAtFrontId == channelID) then
					mainUI.chatManager.unreadMessages[tostring(channelID)] = 0
				end
			end

			if (mainUI.chatManager.channelAtFrontId == 'Clan') then
				mainUI.chatManager.unreadMessages = mainUI.chatManager.unreadMessages or {}
				mainUI.chatManager.unreadMessages['Clan'] = 0
			end			
			
			for channelID, channelTable in pairs(mainUI.chatManager.activeChannels) do
				if GetWidget('main_footer_chat_tab_' .. channelTable[4] .. '' .. channelID, nil, true) then
					if (mainUI.chatManager.unreadMessages[tostring(channelID)]) and (mainUI.chatManager.unreadMessages[tostring(channelID)] > 0) then 
						GetWidget('main_footer_chat_tab_' .. channelTable[4] .. '' .. channelID):SetCallback('onmouseout', function(self)
							GetWidget('main_footer_chat_tab_' .. channelTable[4] .. '' .. channelID .. '_overlay_hover'):FadeOut(125)				
						end)
						GetWidget('main_footer_chat_tab_' .. channelTable[4] .. '' .. channelID):SetCallback('onmouseover', function(self)
							GetWidget('main_footer_chat_tab_' .. channelTable[4] .. '' .. channelID .. '_overlay_hover'):FadeIn(125)				
						end)				
						GetWidget('main_footer_chat_tab_' .. channelTable[4] .. '' .. channelID .. '_1'):SetTexture('/ui/main/footer/textures/social_tab_msg_l.tga')
						GetWidget('main_footer_chat_tab_' .. channelTable[4] .. '' .. channelID .. '_2'):SetTexture('/ui/main/footer/textures/social_tab_msg_c.tga')
						GetWidget('main_footer_chat_tab_' .. channelTable[4] .. '' .. channelID .. '_3'):SetTexture('/ui/main/footer/textures/social_tab_msg_l.tga')
					else
						GetWidget('main_footer_chat_tab_' .. channelTable[4] .. '' .. channelID):SetCallback('onmouseout', function(self)
							GetWidget('main_footer_chat_tab_' .. channelTable[4] .. '' .. channelID .. '_overlay_hover'):FadeOut(125)				
						end)
						GetWidget('main_footer_chat_tab_' .. channelTable[4] .. '' .. channelID):SetCallback('onmouseover', function(self)
							GetWidget('main_footer_chat_tab_' .. channelTable[4] .. '' .. channelID .. '_overlay_hover'):FadeIn(125)				
						end)	
						GetWidget('main_footer_chat_tab_' .. channelTable[4] .. '' .. channelID .. '_1'):SetTexture('/ui/main/footer/textures/social_tab_std_l.tga')
						GetWidget('main_footer_chat_tab_' .. channelTable[4] .. '' .. channelID .. '_2'):SetTexture('/ui/main/footer/textures/social_tab_std_c.tga')
						GetWidget('main_footer_chat_tab_' .. channelTable[4] .. '' .. channelID .. '_3'):SetTexture('/ui/main/footer/textures/social_tab_std_l.tga')			
					end
				end
			end
		end)
	end)
	
	interface:RegisterWatchLua('ChatReceivedClanMessage', function(sourceWidget, trigger)
		local channelID = 'Clan'
		if (mainUI.chatManager.pinnedChannels[channelID]) and (mainUI.chatManager.channelAtFrontId == channelID) then
			mainUI.chatManager.unreadMessages[tostring(channelID)] = nil
		else
			if (mainUI.chatManager.unreadMessages[tostring(channelID)]) then
				mainUI.chatManager.unreadMessages[tostring(channelID)] = (mainUI.chatManager.unreadMessages[tostring(channelID)] + 1)
			else
				mainUI.chatManager.unreadMessages[tostring(channelID)] = 1
			end
		end
		-- println('mainUI.chatManager.unreadMessages ' .. mainUI.chatManager.unreadMessages[tostring(channelID)])
		chatUnreadMessageTrigger.updatedChannel = channelID
		chatUnreadMessageTrigger:Trigger(true)
	end)	
	
	interface:RegisterWatchLua('ChatReceivedChannelMessage', function(sourceWidget, trigger)
		local channelID = trigger.channelID
		if (mainUI.chatManager.pinnedChannels[channelID]) and (mainUI.chatManager.channelAtFrontId == channelID) then
			mainUI.chatManager.unreadMessages[tostring(channelID)] = nil
		else
			if (mainUI.chatManager.unreadMessages[tostring(channelID)]) then
				mainUI.chatManager.unreadMessages[tostring(channelID)] = (mainUI.chatManager.unreadMessages[tostring(channelID)] + 1)
			else
				mainUI.chatManager.unreadMessages[tostring(channelID)] = 1
			end
		end

		chatUnreadMessageTrigger.updatedChannel = channelID
		chatUnreadMessageTrigger:Trigger(true)
	end)	
	
	local function UpdateMemberlist(channelID)
		local channelID = tostring(channelID)
		
		if (not interface:GetWidget('overlay_chat_channel' .. channelID .. '_memberlist_listbox')) then
			return
		end
		
		local lastScrollValue = interface:GetWidget('overlay_chat_channel' .. channelID .. '_memberlist_listbox_vscroll'):GetValue()
		
		-- interface:GetWidget('overlay_chat_channel' .. channelID .. '_memberlist_listbox'):ClearItems() 

		if (not mainUI.chatManager.memberlist[channelID]) then
			return
		end

		-- local indexTable = {}
		-- for i,v in pairs(mainUI.chatManager.memberlist[channelID]) do
			-- tinsert(indexTable, v)
		-- end

		-- table.sort(indexTable, function(a,b) return ( (a.playerName) and (b.playerName) and (string.lower(a.playerName) < string.lower(b.playerName)) ) end) -- using listbox to sort until swap to reuse widget method

		local count = 0
		for identID, accountTable in pairs(mainUI.chatManager.memberlist[channelID]) do
			
			if (interface:GetWidget('overlay_chat_channel' .. channelID .. '_memberlist_listbox'):HasListItem(accountTable.identID)) then
				-- they already exist
			else
				local chatNameColorPath = accountTable.chatNameColorPath

				if (not chatNameColorPath) or Empty(chatNameColorPath) then
					if (accountTable.isStaff) then
						chatNameColorPath = '#e82000'
					else
						chatNameColorPath = 'white'
					end
				end
				
				local accountIconPath = accountTable.accountIconPath

				if (not accountIconPath) or Empty(accountIconPath) then 
					accountIconPath = '/ui/shared/textures/user_icon.tga'
				elseif (accountTable.isStaff) and (accountIconPath) and (accountIconPath == '/ui/shared/textures/account_icons/default.tga') then
					accountIconPath = '/ui/shared/textures/account_icons/s2staff.tga'	
				end

				local playerName = accountTable.playerName
				mainUI.savedRemotely.friendDatabase = mainUI.savedRemotely.friendDatabase or {}
				if (mainUI.savedRemotely.friendDatabase) and (mainUI.savedRemotely.friendDatabase[accountTable.identID]) and (mainUI.savedRemotely.friendDatabase[accountTable.identID].nicknameOverride) then
					playerName = mainUI.savedRemotely.friendDatabase[accountTable.identID].nicknameOverride
				end				
				if (ClientInfo.duplicateUsernameTable[playerName]) then
					if (not IsInTable(ClientInfo.duplicateUsernameTable[playerName], accountTable.uniqueID)) then
						tinsert(ClientInfo.duplicateUsernameTable[playerName], accountTable.uniqueID)
					end
				else
					ClientInfo.duplicateUsernameTable[playerName] = {accountTable.uniqueID}
				end		

				if (#ClientInfo.duplicateUsernameTable[playerName] > 1) then
					playerName = playerName .. '.' .. accountTable.uniqueID
				end

				interface:GetWidget('overlay_chat_channel' .. channelID .. '_memberlist_listbox'):AddTemplateListItemWithSort('memberlist_entry_template', 
					accountTable.identID,
					string.lower(playerName) .. string.lower(accountTable.uniqueID), -- sort index is broken, use name sort instead
					'playerName', playerName,
					'clanName', accountTable.clanName,
					'nameYPosition', ((accountTable.clanName and accountTable.clanName ~= '' and '-0.7h') or ('0.3h')),					
					'labelColor', chatNameColorPath,
					'accountIcon', accountIconPath,
					'identID', accountTable.identID,
					'inGame', accountTable.inGame,
					'inParty', accountTable.inParty,
					'inLobby', accountTable.inLobby,
					'uniqueID', accountTable.uniqueID,
					'isFriend', tostring(ChatClient.IsFriend(accountTable.identID)),
					'joinableParty', tostring(accountTable.joinableParty),
					'joinableGame', tostring(accountTable.joinableGame),
					'gameAddress', tostring(accountTable.gameAddress),
					'channelID', accountTable.channelID,
					'spectatableGame', tostring(accountTable.spectatableGame)
				)	
				
				interface:GetWidget('overlay_chat_channel' .. channelID .. '_memberlist_listbox'):SortListboxSortIndex(0)
			end
			
			count = count + 1
		end

		interface:GetWidget('overlay_chat_channel' .. channelID .. '_memberlist_listbox_vscroll'):SetValue(lastScrollValue)
		
		if interface:GetWidget('overlay_chat_channel' .. channelID .. '_member_label') then
			interface:GetWidget('overlay_chat_channel' .. channelID .. '_member_label'):SetText(count)
		end
	end	
	
	local function ChatChannelMember(sourceWidget, trigger)
		local channelID = tostring(trigger.channelID)

		mainUI.chatManager.memberlist[channelID] = mainUI.chatManager.memberlist[channelID] or {}
		if (trigger.leave) then
			mainUI.chatManager.memberlist[channelID][trigger.identID] = nil
		else
			local identID = string.gsub(trigger.identID, '%.', '')
			local chatClientInfoTrigger = LuaTrigger.GetTrigger('ChatClientInfo' .. identID)
			
			local isStaff = (chatClientInfoTrigger and chatClientInfoTrigger.isStaff) or false

			mainUI.chatManager.memberlist[channelID][trigger.identID] = {
				channelID = channelID,
				playerName = trigger.playerName,
				adminLevel = trigger.adminLevel,
				inGame = tostring(trigger.inGame),
				inParty = 'false', -- tostring(trigger.inParty),
				inLobby = 'false', --  tostring(trigger.inLobby),
				isPremium = trigger.isPremium,
				identID = tostring(trigger.identID),
				uniqueID = tostring(trigger.playerUniqueID),
				chatNameColorString = trigger.accountColor,
				accountIconPath = trigger.accountIconPath,
				accountTitle = trigger.accountTitle,
				joinableParty = trigger.joinableParty,
				joinableGame  = trigger.joinableGame,
				spectatableGame = trigger.spectatableGame,
				clanID = clanID or '0.000',
				clanName = clanName or '',
				clanRank = clanRank or -1,
				clanTag = clanTag or '',				
				leave = trigger.leave,
				isStaff = isStaff,
			}
			
			UpdateMemberlist(channelID)
			
		end
	end
	interface:GetWidget('selection_chat_base'):RegisterWatchLua(
		'ChatChannelMember', function(sourceWidget, trigger)
				ChatChannelMember(sourceWidget, trigger)
			end, --callback
			false --duplicates_allowed
			--key
			--param_indices_to_watch
	)	
	
end

InitMainChat()
InitMainChat = nil

function mainUI.chatManager.InitPrivateMessage(selectedUserIdentID, contextMenuType, selectedUsername, fromWhisper)

	local selectedUserIdentID, contextMenuType, selectedUsername = selectedUserIdentID, contextMenuType, selectedUsername
	
	local channelID					 = tostring(selectedUserIdentID)
	local triggerPanelStatus		= LuaTrigger.GetTrigger('mainPanelStatus')
	local channel_instance			= LuaTrigger.GetTrigger('main_footer_chat_tab_pm' .. channelID)
	
	if (not channelID) then
		RecalculateFooterWidgets()
		return
	end
	
	if (IsMe(channelID)) or (IsOpponent(channelID)) then
		return
	end
	
	if (mainUI.chatManager.activeChannels[channelID]) or (channel_instance) then
		if (not fromWhisper) then
			mainUI.chatManager.ClickedPinnedChatTab(interface:GetWidget('main_footer_chat_tab_pm'..channelID), selectedUsername, channelID, true, nil, 'pm') 
		end
		RecalculateFooterWidgets()
		return
	end
	
	local availableIndex = 0
	for i=1, WINDOW_CHAT_IM_INSTANCES_MAX, 1 do
		if (Windows.data.chat.im.widgets[i] == nil) then
			Windows.data.chat.im.widgets[i] = channelID
			availableIndex = i
			break
		end
	end	
	
	if (availableIndex > 0) then
		mainUI.chatManager.activeChannels[channelID] = {selectedUsername, channelID, false, 'pm'}	
		mainUI.chatManager.pinnedChannels[channelID] = false

		mainUI.chatManager.localActiveChannelInt = mainUI.chatManager.localActiveChannelInt + 1
		
		local chatFooterTabWidgets = GetWidget('main_chat_footer_overlay'):InstantiateAndReturn('footer_chat_tabs_large_pinned', 
			'channelID', channelID,
			'channelName', mainUI.chatManager.activeChannels[channelID][1],
			'channelDisplayName', mainUI.chatManager.activeChannels[channelID][1],
			'showMemberlist', 'false',
			'type', 'pm'
		)
		
		-- Multiwindow chat window - simple version
		local width 							= interface:GetWidthFromString(defaultChatWindowWidth)
		local height 							= interface:GetHeightFromString(defaultChatWindowHeight)
		local x 								= interface:GetHeightFromString(defaultChatWindowX)
		local y 								= interface:GetHeightFromString(defaultChatWindowY)
		
		if (mainUI.savedLocally) and (mainUI.savedLocally.chatSettings) and (mainUI.savedLocally.chatSettings.im) and (mainUI.savedLocally.chatSettings.im[channelID]) and (mainUI.savedLocally.chatSettings.im[channelID].windowHeight) then
			height = mainUI.savedLocally.chatSettings.im[channelID].windowHeight
		end	
		if (mainUI.savedLocally) and (mainUI.savedLocally.chatSettings) and (mainUI.savedLocally.chatSettings.im) and (mainUI.savedLocally.chatSettings.im[channelID]) and (mainUI.savedLocally.chatSettings.im[channelID].windowWidth) then
			width = mainUI.savedLocally.chatSettings.im[channelID].windowWidth
		end		
		if (mainUI.savedLocally) and (mainUI.savedLocally.chatSettings) and (mainUI.savedLocally.chatSettings.im) and (mainUI.savedLocally.chatSettings.im[channelID]) and (mainUI.savedLocally.chatSettings.im[channelID].windowX) then
			x = mainUI.savedLocally.chatSettings.im[channelID].windowX
		end		
		if (mainUI.savedLocally) and (mainUI.savedLocally.chatSettings) and (mainUI.savedLocally.chatSettings.im) and (mainUI.savedLocally.chatSettings.im[channelID]) and (mainUI.savedLocally.chatSettings.im[channelID].windowY) then
			y = mainUI.savedLocally.chatSettings.im[channelID].windowY
		end		
		
		local isPositionIsValid = false
		for _, v in pairs(System.GetAllMonitorRects()) do
			if (((interface:GetXFromString(x)) + interface:GetWidthFromString(width)) <= (v.left + v.right)) 
			and (((interface:GetYFromString(y)) + interface:GetHeightFromString(height)) <= (v.top + v.bottom)) then
				isPositionIsValid = true
			end
		end		
		
		if (not isPositionIsValid) then
			width 							= interface:GetWidthFromString(defaultChatWindowWidth)
			height 							= interface:GetHeightFromString(defaultChatWindowHeight)
			x 								= interface:GetHeightFromString(defaultChatWindowX)
			y 								= interface:GetHeightFromString(defaultChatWindowY)		
		end
		
		Windows.data 							= Windows.data 						or {}
		Windows.data.chat 						= Windows.data.chat  				or {}
		Windows.data.chat.im 					= Windows.data.chat.im  		or {}
		Windows.data.chat.im.creatingChannelID   = channelID		
		Windows.data.chat.im.creatingChannelName = mainUI.chatManager.activeChannels[channelID][1]		
		Windows.Chat 							= Windows.Chat 						or {}
		Windows.Chat.IM 						= Windows.Chat.IM 				or {}

		Windows.Chat.IM[channelID] 		= Windows.Chat.IM[channelID] 	or Window.New(
			x,
			y,
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
				-- Window.MINIMIZED,
				-- Window.APP,
			},
			"/ui_dev/chat/arg/chat_im_" .. availableIndex .. ".interface",
			Translate(mainUI.chatManager.activeChannels[channelID][1])
		)
		
		Windows.Chat.IM[channelID]:SetSizingBounds((interface:GetWidthFromString(defaultChatWindowWidth) * 0.8), (interface:GetHeightFromString(defaultChatWindowHeight) * 0.6), (interface:GetWidthFromString(defaultChatWindowWidth) * 5.0), (interface:GetHeightFromString(defaultChatWindowHeight) * 5.0))
		Windows.Chat.IM[channelID]:SetCloseCallback(function()
			LeaveConversation(channelID)
		end)
		
		if (not mainUI.chatManager.pinnedChannels[channelID]) then
			mainUI.chatManager.ClickedPinnedChatTab(interface:GetWidget('main_footer_chat_tab_pm'..channelID), selectedUsername, channelID, true, nil, 'pm')
		end		
		
	end
	
	RecalculateFooterWidgets()
	
end

-- =======================================================================

function SendPrivateMessage(userID, message)
	if tonumber(userID) then
		ChatClient.SendPrivateMessageToIdentID(tostring(userID), message)
	else
		ChatClient.SendPrivateMessage(userID, message)
	end
end

-- Load subscribed groups
printr(mainUI.savedRemotely.subscribedGroups)

interface:GetWidget('main_chat_sleeper'):RegisterWatchLua('loadComplete', function(widget, trigger)
	LoadMyGroups() -- Database loaded
end, false, nil)
