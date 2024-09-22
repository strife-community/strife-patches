local tinsert = table.insert
local interface = object
local WATCH_STREAM_LIST = "api.twitch.tv/kraken/search/streams?q=strife&limit=100"
local WATCH_VIDEO_LIST = "api.twitch.tv/kraken/videos/top?game=Strife&period=month"

mainUI = mainUI or {}
mainUI.savedLocally 	= mainUI.savedLocally 		or {}
mainUI.savedRemotely 	= mainUI.savedRemotely 		or {}
mainUI.savedAnonymously	= mainUI.savedAnonymously 	or {}
mainUI.savedRemotely.favouritewatchIDs = mainUI.savedRemotely.favouritewatchIDs or {}
mainUI.watch 			= mainUI.watch or {}
mainUI.watch.recentGameList = mainUI.watch.recentGameList or {}
mainUI.watch.myReplays = {}
mainUI.watch.selectedRecentMatchID = ''
mainUI.watch.selectedRecentMatchIndex = -1
mainUI.watch.lastSelectedReplayPath = ''
mainUI.watch.friendsICanSpectate = mainUI.watch.friendsICanSpectate or {}

local tempMatchStatsCache = {}

local function WatchRegister(object)
	local watchStateTrigger = LuaTrigger.GetTrigger('WatchStateTrigger') or LuaTrigger.CreateCustomTrigger('WatchStateTrigger',
		{
			{ name	= 'state',			type	= 'string' },
			{ name	= 'filter',			type	= 'string' },
			{ name	= 'matchComment',	type	= 'string' },
			{ name	= 'matchName',		type	= 'string' },
			{ name	= 'matchID',		type	= 'string' },
			{ name	= 'matchIndex',		type	= 'string' },
			{ name	= 'currentHeroIcon',		type	= 'string' },
			{ name	= 'heroIcon0',		type	= 'string' },
			{ name	= 'heroIcon1',		type	= 'string' },
			{ name	= 'heroIcon2',		type	= 'string' },
			{ name	= 'heroIcon3',		type	= 'string' },
			{ name	= 'heroIcon4',		type	= 'string' },
			{ name	= 'heroIcon5',		type	= 'string' },
			{ name	= 'heroIcon6',		type	= 'string' },
			{ name	= 'heroIcon7',		type	= 'string' },
			{ name	= 'heroIcon8',		type	= 'string' },
			{ name	= 'heroIcon9',		type	= 'string' },
		}
	)
	
	watchStateTrigger.state = mainUI.savedLocally.watchDefaultTab or 'streams'
	watchStateTrigger.matchComment = ''
	watchStateTrigger.matchName = ''
	watchStateTrigger.matchID = ''
	watchStateTrigger.matchIndex = ''
	watchStateTrigger.currentHeroIcon = ''
	watchStateTrigger.heroIcon0 = ''
	watchStateTrigger.heroIcon1 = ''
	watchStateTrigger.heroIcon2 = ''
	watchStateTrigger.heroIcon3 = ''
	watchStateTrigger.heroIcon4 = ''
	watchStateTrigger.heroIcon5 = ''
	watchStateTrigger.heroIcon6 = ''
	watchStateTrigger.heroIcon7 = ''
	watchStateTrigger.heroIcon8 = ''
	watchStateTrigger.heroIcon9 = ''
	watchStateTrigger.filter = mainUI.savedLocally.watchDefaultFilter or 'all'
	watchStateTrigger:Trigger(false)

	local function InterceptFailErrors(oldFailFunction)

		local newFailFunction = function(responseData)
			local responseError = responseData:GetError()

			if (responseError) and (not Empty(responseError)) and (responseError ~= 'error_not_found') then
				local errorTable = explode('|', responseError)
				local errorTable2 = {}
				for i,v in ipairs(errorTable) do
					table.insert(errorTable2, Translate(v))
				end
				local errorString = implode2(errorTable2, ' \n', '', '')
				GenericDialogAutoSize(
					'error_web_general', '', tostring(Translate(errorString)), 'general_ok', '', 
						nil,
						nil
				)
			end

			if (oldFailFunction) then
				oldFailFunction(responseData)
			end		
			
		end
		
		return newFailFunction
	end

	local function InterceptSuccessErrors(oldSuccessFunction)

		local newSuccessFunction = function(responseData)
			local responseError = responseData:GetError()

			if (responseError) and (not Empty(responseError)) and (responseError ~= 'error_not_found') then
				local errorTable = explode('|', responseError)
				local errorTable2 = {}
				for i,v in ipairs(errorTable) do
					table.insert(errorTable2, Translate(v))
				end
				local errorString = implode2(errorTable2, ' \n')
				GenericDialogAutoSize(
					'error_web_general', '', tostring(Translate(errorString)), 'general_ok', '', 
						nil,
						nil
				)
			end
			
			if (oldSuccessFunction) then
				oldSuccessFunction(responseData)
			end
			
		end
		
		return newSuccessFunction
	end

	function Strife_Web_Requests:GetWatchStreams(successFunction, failFunction)
		if (not Client.GetSessionKey()) then
			printdb('^r Error: GetWatchStreams attempted without session key')
			return false
		end

		local request = HTTP.SpawnRequest()
		
		request:SetTargetURL(WATCH_STREAM_LIST)
		request:SendSecureRequest('GET')

		request:ManagedWait(
			InterceptSuccessErrors(successFunction),
			failFunction
		)

	end

	function Strife_Web_Requests:GetWatchVideos(successFunction, failFunction)
		if (not Client.GetSessionKey()) then
			printdb('^r Error: GetWatchVideos attempted without session key')
			return false
		end

		local request = HTTP.SpawnRequest()
		
		request:SetTargetURL(WATCH_VIDEO_LIST)
		request:SendSecureRequest('GET')

		request:ManagedWait(
			InterceptSuccessErrors(successFunction),
			failFunction
		)

	end	
	
	function mainUI.watch.GetFriendsToSpectate()
		
		-- println('^y^: GetFriendsToSpectate ')
		-- printr(mainUI.watch.friendsICanSpectate)
		
		if ((mainUI.featureMaintenance) and ((mainUI.featureMaintenance['watch']) or (mainUI.featureMaintenance['spectate'])) ) then
			if GetWidget('watch_spectate', nil, true) then
				GetWidget('watch_spectate', nil, true):SetVisible(0)
			end
			return
		end

		local streamsTable = mainUI.watch.friendsICanSpectate

		local count = 0

		for index, streamTable in ipairs(streamsTable) do
			if (streamTable) and (streamTable.identID) and (streamTable.trueName or streamTable.name) then

				count = count + 1
				if count > 4 then
					break
				end
				
				local button1		=	GetWidget('watch_spectate_item_' .. index .. '')
				local banner		=	GetWidget('watch_spectate_item_' .. index .. '_banner')
				local parent		=	GetWidget('watch_spectate_item_' .. index .. '_parent')
				local label			=	GetWidget('watch_spectate_item_' .. index .. '_label')
				local button2		=	GetWidget('watch_spectate_item_' .. index .. '_btn')
				
				parent:SetVisible(1)			
				
				label:SetText(streamTable.trueName or streamTable.name or '?')
				
				local function OnClick()
					mainUI.SpectateGame(streamTable.identID)
				end
				
				button1:SetCallback('onclick', OnClick)
				button2:SetCallback('onclick', OnClick)

			end
		end

		for index = math.max(1, count + 1),4,1 do
			if GetWidget('watch_spectate_item_' .. index .. '_parent', nil, false) then
				GetWidget('watch_spectate_item_' .. index .. '_parent'):SetVisible(0)
			end
		end	
		
		GetWidget('watch_spectate_label_1'):SetVisible(count == 0)
		GetWidget('watch_content_spectate_0'):SetVisible(count > 0)

		GetWidget('watch_spectate_count_label_parent'):SetVisible(count > 0)
		GetWidget('watch_spectate_count_label'):SetText(math.floor(count))		
		
	end		
	
	function mainUI.watch.GetTwitchVideos(sortableTableVods)
		
		println('^y^: GetTwitchVideos ')
		
		if (not sortableTableVods) then return end
		
		if ((mainUI.featureMaintenance) and ((mainUI.featureMaintenance['watch']) or (mainUI.featureMaintenance['twitch_vods'])) ) then
			if GetWidget('watch_featured', nil, true) then
				GetWidget('watch_featured', nil, true):SetVisible(0)
			end
			return
		end

		-- printr(sortableTableVods)
		
		if (not sortableTableVods) or (#sortableTableVods == 0) then
			GetWidget('watch_videos_throb'):SetVisible(0)
			GetWidget('watch_videos_label_1'):SetVisible(1)
			GetWidget('watch_content_featured_parent'):SetVisible(0)
			GetWidget('watch_videos_label_1'):SetText(Translate('twitch_nolive_streams'))
		else
			
			GetWidget('watch_videos_throb'):SetVisible(0)
			GetWidget('watch_videos_label_1'):SetVisible(0)		
			GetWidget('watch_content_featured_parent'):SetVisible(1)

			local count = 1
			
			for index, streamTable in ipairs(sortableTableVods) do
				if (streamTable) and (streamTable.channel) and (streamTable.game) and (string.lower(streamTable.game) == 'strife') and (streamTable.title) and (not ChatCensor.IsCensored(streamTable.title)) and (streamTable.url) and (not Empty(streamTable.url)) then
					-- printr(streamTable)

					count = count + 1
					if count > 5 then
						break
					end
					
					local imageUrl
					if (streamTable.preview) and (streamTable.preview.large) then
						imageUrl = string.gsub(streamTable.preview.large, 'https:', 'http:')
					end
					
					local button1		=	GetWidget('watch_featured_item_' .. index .. '')
					local banner		=	GetWidget('watch_featured_item_' .. index .. '_banner')
					local label			=	GetWidget('watch_featured_item_' .. index .. '_label')
					local button2			=	GetWidget('watch_featured_item_' .. index .. '_btn')
					
					if (button1) then
						button1:SetVisible(1)
					end
					
					if banner and banner.SetImageURL and imageUrl then
						banner:SetImageURL(imageUrl)
					elseif banner and banner.SetImage and streamTable.image then
						banner:SetImage(streamTable.image)								
					end
					if (label) then
						label:SetText(streamTable.title)
					end
					
					local function OnClick()
						mainUI.OpenURL(streamTable.url)
					end
					
					if (button1) and (button2) then
						button1:SetCallback('onclick', OnClick)
						button2:SetCallback('onclick', OnClick)
					end
					
				end
			end

			for index = count,4,1 do
				GetWidget('watch_featured_item_' .. index .. ''):SetVisible(0)
			end					

		end

	end	
	
	mainUI.watch.canGetTwitchStreams = true
	
	function mainUI.watch.GetTwitchStreams()
		
		println('^y^: GetTwitchStreams ')
		
		if ((mainUI.featureMaintenance) and ((mainUI.featureMaintenance['watch']) or (mainUI.featureMaintenance['twitch_stream']))) then
			if GetWidget('watch_streams', nil, true) then
				GetWidget('watch_streams', nil, true):SetVisible(0)
			end
			return
		end
		
		local successFunction =  function (request)	-- response handler

			local responseData = request:GetBody()
			if responseData == nil then
				SevereError('watch - no response data', 'main_reconnect_thatsucks', '', nil, nil, false)
				GetWidget('watch_streams_throb'):SetVisible(0)
				GetWidget('watch_streams_label_1'):SetVisible(0)			
				GetWidget('watch_videos_throb'):SetVisible(0)
				GetWidget('watch_videos_label_1'):SetVisible(0)			
				GetWidget('watch_content_featured_parent'):SetVisible(1)				
				return nil
			else
				
				-- printr(responseData)
				
				local sortableTable = {}
				local sortableTableVods = {}
				
				if (responseData.streams) then
					for index, matchTable in pairs(responseData.streams) do
						table.insert(sortableTable, matchTable)
					end
					table.sort(sortableTable, function(a,b) return (a.viewers) > (b.viewers) end)	
				end
				
				if (responseData.vods) then
					for index, matchTable in pairs(responseData.vods) do
						table.insert(sortableTableVods, matchTable)
					end
					table.sort(sortableTableVods, function(a,b) return (a.views) > (b.views) end)	
				end

				mainUI.watch.GetTwitchVideos(sortableTableVods)
				
				if (not sortableTable) or (#sortableTable <= 0) then
					GetWidget('watch_streams_throb'):SetVisible(0)
					GetWidget('watch_streams_label_1'):SetVisible(1)
					GetWidget('watch_streams_label_1'):SetText(Translate('twitch_nolive_streams'))
					SevereError('Failed to decode data GetTwitchStreams ' .. tostring(explodeData), 'main_reconnect_thatsucks', '', nil, nil, false)
				else
					
					GetWidget('watch_streams_throb'):SetVisible(0)
					GetWidget('watch_streams_label_1'):SetVisible(0)					

					local listbox = GetWidget('watch_streams_results_listbox')			
					
					local count = 0
					
					for index, streamTable in ipairs(sortableTable) do
						if (count < 18) and (streamTable) and (streamTable.channel) and (streamTable.game) and (streamTable.channel.status) and (streamTable.preview.large) and (streamTable.viewers) and (string.lower(streamTable.game) == 'strife') and (not ChatCensor.IsCensored(streamTable.channel.display_name)) and (streamTable.channel.url) and (not Empty(streamTable.channel.url)) and (streamTable._id) then
							-- printr(streamTable)

							-- println(streamTable.viewers .. ' | ' .. streamTable.channel.display_name)
							
							count = count + 1
							mainUI.savedRemotely.favouritewatchIDs = mainUI.savedRemotely.favouritewatchIDs or {}
							local isFavourite = ((mainUI.savedRemotely.favouritewatchIDs) and (mainUI.savedRemotely.favouritewatchIDs[streamTable._id]))
							local imageUrl = string.gsub(streamTable.preview.large, 'https:', 'http:')
							
							listbox:AddTemplateListItem(
								'watch_stream_item_template',
								streamTable.channel.url,
								-- string.lower(streamTable._id), -- sort
								'streamName', streamTable.channel.display_name,
								'streamID', streamTable._id,
								'bannerPath', imageUrl,
								'viewers',streamTable.viewers,
								'url',streamTable.channel.url,
								'status', streamTable.channel.status,
								'onmouseoverlua', [[UpdateCursor(self, true, { canLeftClick = true, canRightClick = false })]],
								'onmouseoutlua', [[UpdateCursor(self, false, { canLeftClick = true, canRightClick = false })]],
								'isFavourite', tostring(isFavourite)
							)					
							
						end
					end
					
					GetWidget('main_top_button_watchLabel2'):SetText(Translate('watch_num_live_streams', 'value', math.floor(count + #mainUI.watch.friendsICanSpectate)))
					
					groupfcall('watch_streams_anim_group', function(_, widget) RegisterRadialEase(widget) widget:DoEventN(7) end)
					
				end
				
				return true
			end
		end
		
		local failFunction =  function (request)	-- error handler
			SevereError('watch Request Error: ' .. Translate(request:GetError()), 'main_reconnect_thatsucks', '', nil, nil, false)
			GetWidget('watch_streams_throb'):SetVisible(0)
			GetWidget('watch_streams_label_1'):SetVisible(0)
			GetWidget('watch_videos_throb'):SetVisible(0)
			GetWidget('watch_videos_label_1'):SetVisible(1)
			GetWidget('watch_videos_label_1'):SetText(Translate('twitch_nolive_streams'))
			GetWidget('watch_content_featured_parent'):SetVisible(1)			
			return nil
		end	
		
		if (mainUI.watch.canGetTwitchStreams) then		
		
			local listbox = GetWidget('watch_streams_results_listbox')
			listbox:ClearItems()	
		
			GetWidget('watch_streams_label_1'):SetVisible(1)
			GetWidget('watch_streams_throb'):SetVisible(1)
			GetWidget('watch_streams_label_1'):SetText(Translate('twitch_searching_streams'))	
			
			GetWidget('watch_videos_label_1'):SetVisible(1)
			GetWidget('watch_videos_throb'):SetVisible(1)
			GetWidget('watch_content_featured_parent'):SetVisible(0)
			GetWidget('watch_videos_label_1'):SetText(Translate('twitch_searching_streams'))		
		

			mainUI.watch.canGetTwitchStreams = false
			Strife_Web_Requests:GetTwitchStreams(successFunction, failFunction)
		end
		
	end

	function mainUI.watch.GetHeroHowToVideos()

		if (mainUI.featureMaintenance) and ((mainUI.featureMaintenance['watch']) or (mainUI.featureMaintenance['howto'])) then
			if GetWidget('watch_learn', nil, true) then
				GetWidget('watch_learn', nil, true):SetVisible(0)
			end
			return
		end	
		
		local listbox = GetWidget('watch_howto_results_listbox')
		listbox:ClearItems()
		
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

		for index, streamTable in ipairs(streamsTable) do
			if (streamTable)  then

				if (streamTable[1]) and (not Empty(streamTable[1])) and ValidateEntity(streamTable[1]) then
					if (streamTable[2]) and (not Empty(streamTable[2])) then
						local conceptArtPath = '/ui/main/shared/concept_art/'
						conceptArtPath = conceptArtPath .. string.lower(streamTable[1]) .. '_default.jpg'
						local url = "https://proxy.playstrife.gg/youtube/".. tostring(streamTable[2])
						listbox:AddTemplateListItem(
							'watch_howto_item_template',
							url,
							'streamID', 'howto_'..(streamTable[1]),
							'streamName', GetEntityDisplayName(streamTable[1]),
							'bannerPath', conceptArtPath,
							'url', url,
							'onmouseoverlua', [[UpdateCursor(self, true, { canLeftClick = true, canRightClick = false })]],
							'onmouseoutlua', [[UpdateCursor(self, false, { canLeftClick = true, canRightClick = false })]]
						)	
					else
						local conceptArtPath = '/ui/main/shared/concept_art/'
						conceptArtPath = conceptArtPath .. string.lower(streamTable[1]) .. '_default.jpg'
						local url = 'coming_soon_howto_'..index
						listbox:AddTemplateListItem(
							'watch_howto_item_comingsoon_template',
							url,
							'streamID', 'howto_'..(streamTable[1]),
							'streamName', GetEntityDisplayName(streamTable[1]),
							'bannerPath', conceptArtPath,
							'url', url,
							'onmouseoverlua', [[UpdateCursor(self, true, { canLeftClick = true, canRightClick = false })]],
							'onmouseoutlua', [[UpdateCursor(self, false, { canLeftClick = true, canRightClick = false })]]
						)	
					
					end
				end			

			end
		end

	end	
	
	local replayData
	function mainUI.watch.PopulateReplays(reloadFromCode)
		
		if ((mainUI.featureMaintenance) and ((mainUI.featureMaintenance['watch']) or (mainUI.featureMaintenance['replays'])) ) then
			if GetWidget('watch_replays', nil, true) then
				GetWidget('watch_replays', nil, true):SetVisible(0)
			end
			return
		end		
		
		local watch_gamelist_listbox = GetWidget('watch_gamelist_listbox')
		
		if (reloadFromCode) then
			replayData = GetExtensiveReplayData()
		else
			replayData = replayData or GetExtensiveReplayData()
		end
		mainUI.watch.myReplays = {}
		mainUI.watch.selectedRecentMatchIndex = -1
		
		local function GetReplayInformation(recentGameTable, matchID)
			for index, replayTable in pairs(replayData) do
				local insertMatchID = replayTable.matchid or '0'
				if string.find(insertMatchID, '%.') or (insertMatchID == '0') then
				else
					insertMatchID = string.sub(insertMatchID, 1, -4) .. '.' .. string.sub(insertMatchID, -3)
				end					
				if (insertMatchID == matchID) and (insertMatchID ~= '0') and (matchID ~= '0') then
					recentGameTable.hasReplay = true
					local insertMatchID = matchID or '0'
					if string.find(insertMatchID, '%.') or (insertMatchID == '0') then
					else
						insertMatchID = string.sub(insertMatchID, 1, -4) .. '.' .. string.sub(insertMatchID, -3)
					end							
					recentGameTable.match_id  = insertMatchID
					recentGameTable.stats = replayTable
					replayData[index] = nil
					break
				end
			end	
			return recentGameTable
		end

		for index, recentGameTable in pairs(mainUI.watch.recentGameList) do	--- add matches from recent games, try to find matching replay
			recentGameTable.isRecentGame		= true
			recentGameTable.hasReplay 			= false
			recentGameTable.localPlayerInReplay = true	
			local insertMatchID = recentGameTable.match_id or '0'
			if string.find(insertMatchID, '%.') or (insertMatchID == '0') then
			else
				insertMatchID = string.sub(insertMatchID, 1, -4) .. '.' .. string.sub(insertMatchID, -3)
			end					
			recentGameTable.match_id 			= insertMatchID or '0'	
			recentGameTable.date 				= recentGameTable.date or ''
			recentGameTable.timestamp 			= recentGameTable.timestamp or '1'
			if (recentGameTable) and (recentGameTable.match_id) and (not Empty(recentGameTable.match_id)) and (recentGameTable.match_id ~= '0') then
				recentGameTable = GetReplayInformation(recentGameTable, recentGameTable.match_id)
				tinsert(mainUI.watch.myReplays, recentGameTable)
			else
				-- If a recent match does not have a match ID do not show it, there would be no way to download this replay. Hope they have it stored locally instead.
				println(' skipping recent match ' .. tostring(recentGameTable.match_id))
			end
		end

		for index, replayGameTable in pairs(replayData) do	-- add all remaining replays
			local tempTable = {}
			tempTable.isRecentGame			= false
			tempTable.hasReplay			  	= true
			tempTable.localPlayerInReplay 	= false
			tempTable.date 					= replayGameTable.date or ''
			local insertMatchID = replayGameTable.match_id or '0'
			if string.find(insertMatchID, '%.') or (insertMatchID == '0') then
			else
				insertMatchID = string.sub(insertMatchID, 1, -4) .. '.' .. string.sub(insertMatchID, -3)
			end					
			tempTable.match_id 				= insertMatchID
			tempTable.timestamp 			= replayGameTable.timestamp or '0'
			tempTable.stats = replayGameTable
			tinsert(mainUI.watch.myReplays, tempTable)
		end	

		for index, myReplayTable in pairs(mainUI.watch.myReplays) do	-- scan for local player (by name for now, add identid later)
			local insertMatchID = myReplayTable.match_id or '0'
			if string.find(insertMatchID, '%.') or (insertMatchID == '0') then
			else
				insertMatchID = string.sub(insertMatchID, 1, -4) .. '.' .. string.sub(insertMatchID, -3)
			end				
			if mainUI.savedLocally and tempMatchStatsCache and tempMatchStatsCache[insertMatchID] and tempMatchStatsCache[insertMatchID].matchStats and tempMatchStatsCache[insertMatchID].matchStats.stats then
				local stats = tempMatchStatsCache[insertMatchID].matchStats.stats
				for i,v in pairs(stats) do
					if (v) and (v.nickname) and (v.isMe) and (v.matchmakingHeroStats) and (v.matchmakingHeroStats.entityName) and ValidateEntity(v.matchmakingHeroStats.entityName) then
						myReplayTable.localPlayerInReplay = true
						myReplayTable.localPlayerInfo = {
							heroName = GetEntityDisplayName(v.matchmakingHeroStats.entityName),
							heroicon = GetEntityIconPath(v.matchmakingHeroStats.entityName),
							team = tonumber(v.team),
						}
					end
				end				
			elseif myReplayTable.stats then
				for i = 1,10,1 do
					if (myReplayTable.stats[i]) and (myReplayTable.stats[i].name) and (not Empty(myReplayTable.stats[i].name)) and (myReplayTable.stats[i].name == GetAccountName()) then
						local team
						if (i <= 5) then 
							team = 1
						else
							team = 2
						end
						myReplayTable.localPlayerInReplay = true
						myReplayTable.localPlayerInfo = {
							heroName = myReplayTable.stats[i].heroname,
							heroicon = myReplayTable.stats[i].heroicon,
							team = team,
						}
					end
				end
			end		
		end		

		table.sort(mainUI.watch.myReplays, function(a, b)
			if tonumber(a.timestamp) and tonumber(b.timestamp) and tonumber(a.timestamp) ~= tonumber(b.timestamp) then
				return tonumber(a.timestamp) > tonumber(b.timestamp)
			elseif tonumber(a.match_id) and tonumber(b.match_id) and tonumber(a.match_id) ~= tonumber(b.match_id) then
				return tonumber(a.match_id) > tonumber(b.match_id)				
			else
				return false
			end
		end)
		
		local function Strip(content)
			content = string.gsub(content, "'", "")
			content = string.gsub(content, [[\]], "")
			return content
		end
		
		watch_gamelist_listbox:UICmd([[Clear()]])
		if (mainUI.watch.myReplays) then
			for index,myReplayTable in ipairs(mainUI.watch.myReplays) do
				local timeStamp, timeStamp2, heroIcon, team = '', '', (myReplayTable.localPlayerInReplay and myReplayTable.localPlayerInfo and myReplayTable.localPlayerInfo.heroicon) or '/ui/shared/textures/user_icon.tga', 0
				if (myReplayTable.timestamp) then
					if (tonumber(myReplayTable.timestamp)) and (tonumber(myReplayTable.timestamp) > 1) then
						timeStamp = FormatDateTime(myReplayTable.timestamp, '%#I:%M %p', true)
						timeStamp2 = FormatDateTime(myReplayTable.timestamp, ' %b %d', true)
					elseif (myReplayTable.date) and (not Empty(myReplayTable.date)) then
						timeStamp = myReplayTable.date				
					elseif (myReplayTable.timestamp == '1') then
						timeStamp = Translate('watch_recent_game')
					else
						timeStamp = Translate('watch_local_replay')
					end
				end
				
				local insertMatchID = myReplayTable.match_id or '0'
				if string.find(insertMatchID, '%.') or (insertMatchID == '0') then
				else
					insertMatchID = string.sub(insertMatchID, 1, -4) .. '.' .. string.sub(insertMatchID, -3)
				end				
				
				if (myReplayTable.localPlayerInReplay) and (myReplayTable.localPlayerInfo) then
					heroIcon = myReplayTable.localPlayerInfo.heroicon or '$checker'
					team = myReplayTable.localPlayerInfo.team or 0
				end
				local matchName, matchNote, replayPath = '', '', ''
				if (myReplayTable.stats) and (myReplayTable.stats.path) then
					replayPath = myReplayTable.stats.path
				end
				matchName, matchNote = mainUI.watch.ReturnMatchInfo(replayPath, insertMatchID)
				if (Empty(matchName)) then
					matchName = Translate('player_profile_match') .. ' ' .. myReplayTable.match_id
				end				
				
				if (watchStateTrigger.filter == 'all') or ((watchStateTrigger.filter == 'recent') and (myReplayTable.isRecentGame)) or ((watchStateTrigger.filter == 'downloaded') and (myReplayTable.hasReplay)) then
					watch_gamelist_listbox:AddTemplateListItem('watch_recent_matches_template', index, 
						'index', index,
						'match_id',  insertMatchID,
						'label1',  Strip(matchName),
						'label2', timeStamp,
						'label3', timeStamp2,
						'heroIcon', heroIcon,
						'hasReplay', tostring(myReplayTable.hasReplay),
						'matchName', Strip(matchName),
						'matchNote', Strip(matchNote),
						'replayPath', replayPath,
						'team', team
					)
				end
			end
			libThread.threadFunc(function()	
				wait(styles_mainSwapAnimationDuration)		
				if (watchStateTrigger.matchIndex) and (not Empty(watchStateTrigger.matchIndex)) then
					watch_gamelist_listbox:SetSelectedItemByValue(watchStateTrigger.matchIndex, true)
				else
					watch_gamelist_listbox:SetSelectedItemByIndex(0, true)
				end
				mainUI.watch.UpdateGameListActionButton()
			end)
		else
			SevereError('PopulateReplays - mainUI.watch.myReplays missing', 'main_reconnect_thatsucks', '', nil, nil, false)
		end
		
	end

	local function RegisterReplayList()

		local replay_detailed							= object:GetWidget('replay_detailed')
		local watch_gamelist_main_scoreboard_btn		= object:GetWidget('watch_gamelist_main_scoreboard_btn')
		local watch_gamelist_main_action_btnLabel		= object:GetWidget('watch_gamelist_main_action_btnLabel')
		local replay_scoreboard_close					= object:GetWidget('replay_scoreboard_close')
		local watch_gamelist_main_action_btn			= object:GetWidget('watch_gamelist_main_action_btn')
		local profile_download_replay_progress_bar		= object:GetWidget('profile_download_replay_progress_bar')		
		local watch_gamelist_listbox 					= GetWidget('watch_gamelist_listbox')
		local playerinfoandtime							= GetWidget('replays_matchinfo_playerinfoandtime')
	
		function mainUI.watch.UpdateGameListActionButton(click)
			playerinfoandtime:FadeOut(150)
		
			local ReplayDownload 	= LuaTrigger.GetTrigger('ReplayDownload')
			local ReplayInfoGame 	= LuaTrigger.GetTrigger('ReplayInfoGame')
			local CompatDownload 	= LuaTrigger.GetTrigger('CompatDownload')
			local ManifestDownload 	= LuaTrigger.GetTrigger('ManifestDownload')
			
			mainUI.watch.selectedRecentMatchIndex = tonumber(watch_gamelist_listbox:GetValue()) or ''
			watchStateTrigger.matchID = ''	
			watchStateTrigger.currentHeroIcon = ''
			watchStateTrigger.heroIcon0 = ''
			watchStateTrigger.heroIcon1 = ''
			watchStateTrigger.heroIcon2 = ''
			watchStateTrigger.heroIcon3 = ''
			watchStateTrigger.heroIcon4 = ''
			watchStateTrigger.heroIcon5 = ''
			watchStateTrigger.heroIcon6 = ''
			watchStateTrigger.heroIcon7 = ''
			watchStateTrigger.heroIcon8 = ''
			watchStateTrigger.heroIcon9 = ''
			watchStateTrigger.matchIndex = mainUI.watch.selectedRecentMatchIndex
			watchStateTrigger.matchName = ''
			watchStateTrigger.matchComment = ''			
			watchStateTrigger:Trigger(false)
			local selectedReplayInfo = mainUI.watch.myReplays[mainUI.watch.selectedRecentMatchIndex]
				
			-- printr(mainUI.watch.myReplays)
			-- println('^y mainUI.watch.selectedRecentMatchIndex ' .. tostring(mainUI.watch.selectedRecentMatchIndex))
			-- printr(selectedReplayInfo)
			
			GetWidget('watch_gamelist_main_comment_btn'):SetEnabled(0)	
			GetWidget('watch_gamelist_main_scoreboard_btn'):SetEnabled(0)	

			if ((ReplayDownload.progress == 0) or (ReplayDownload.progress == 1)) and  ((CompatDownload.downloadingPercent == 0) or (CompatDownload.downloadingPercent == 1)) and ((ManifestDownload.downloadingPercent == 0) or (ManifestDownload.downloadingPercent == 1)) then
				GetWidget('watch_gamelist_listbox_blocker'):SetVisible(0)
				-- println('We arent busy downloading')
				if (selectedReplayInfo) and (selectedReplayInfo.hasReplay) and (selectedReplayInfo.stats) and (selectedReplayInfo.stats.path) then					
					-- println('We have a replay with stats')
					-- println('SetReplayInfo ' .. tostring(selectedReplayInfo.stats.path) )
					mainUI.watch.GetMatchInfo()
					mainUI.watch.lastSelectedReplayPath = selectedReplayInfo.stats.path
					SetReplayInfo(selectedReplayInfo.stats.path)
					mainUI.watch.GetMatchStats()
					if (not Empty(ReplayInfoGame.version)) then
						-- println('We have a version')
						if (ReplayInfoGame.isCompatible) then			
							-- println('It is compatible')
							GetWidget('watch_gamelist_main_action_btn'):SetEnabled(1)
							GetWidget('watch_gamelist_main_action_btnLabel'):SetText(Translate('watch_watch_replay'))
							GetWidget('watch_gamelist_main_action_btn'):SetCallback('onclick', function()
								object:UICmd([[ StartReplay(']] .. selectedReplayInfo.stats.path .. [[') ]])
							end)
							if (click) then
								object:UICmd([[ StartReplay(']] .. selectedReplayInfo.stats.path .. [[') ]])
							end
						else
							-- println('It is not compatible')
							GetWidget('watch_gamelist_main_action_btn'):SetEnabled(1)
							GetWidget('watch_gamelist_main_action_btnLabel'):SetText(Translate('watch_make_compatible'))
							GetWidget('watch_gamelist_main_action_btn'):SetCallback('onclick', function()
								object:UICmd([[ DownloadReplayCompat(']] .. ReplayInfoGame.version .. [[') ]])
							end)	
							if (click) then
								object:UICmd([[ DownloadReplayCompat(']] .. ReplayInfoGame.version .. [[') ]])
							end							
						end
					else
						-- println('But it has no version information, we cant do anything')
						GetWidget('watch_gamelist_main_action_btn'):SetEnabled(0)
						GetWidget('watch_gamelist_main_action_btnLabel'):SetText(Translate('watch_no_version'))								
					end
				else
					-- println('We are missing replay info or dont have the replay')
					if (selectedReplayInfo) and (selectedReplayInfo.match_id) and (not Empty(selectedReplayInfo.match_id)) and (selectedReplayInfo.match_id ~= '0') then
						-- println('But we do have a match ID, so we could download it')
						mainUI.watch.GetMatchInfo(nil, selectedReplayInfo.match_id)
						mainUI.watch.GetMatchStats(selectedReplayInfo.match_id)
						GetWidget('watch_gamelist_main_action_btn'):SetEnabled(1)
						GetWidget('watch_gamelist_main_action_btnLabel'):SetText(Translate('watch_download'))
						GetWidget('watch_gamelist_main_action_btn'):SetCallback('onclick', function(widget)
							RequestReplayDownload(selectedReplayInfo.match_id)
						end)	
						if (click) then
							RequestReplayDownload(selectedReplayInfo.match_id)
						end	
					else
						-- println('And we dont have a match ID, we cant do anything')
						GetWidget('watch_gamelist_main_action_btn'):SetEnabled(0)
						GetWidget('watch_gamelist_main_action_btnLabel'):SetText(Translate('watch_no_matchid'))		
					end
				end					
			else
				-- println('We are busy downloading so we cant do anything atm')
				GetWidget('watch_gamelist_main_action_btn'):SetEnabled(0)
				GetWidget('watch_gamelist_main_action_btnLabel'):SetText(Translate('watch_downloading'))
				GetWidget('watch_gamelist_listbox_blocker'):SetVisible(1)
			end
		end		

		GetWidget('watch_gamelist_main_action_btn'):RegisterWatchLua('ReplayInfoGame', function(widget, trigger)
			mainUI.watch.UpdateGameListActionButton()
		end)		
		
		GetWidget('watch_gamelist_main_action_btn'):SetCallback('onclick', function(widget)
			PlaySound('/ui/sounds/launcher/sfx_replay_download.wav')
			mainUI.watch.UpdateGameListActionButton(true)
		end)				
		
		GetWidget('watch_gamelist_listbox'):SetCallback('onclick', function(widget)
			mainUI.watch.UpdateGameListActionButton()
		end)
		
		-- GetWidget('watch_gamelist_listbox'):SetCallback('ondoubleclick', function(widget)
			-- mainUI.watch.UpdateGameListActionButton(true)
		-- end)		
		
		GetWidget('watch_gamelist_listbox'):SetCallback('onselect', function(widget)
			mainUI.watch.UpdateGameListActionButton()
			PlaySound('/ui/sounds/launcher/sfx_replay_select.wav')
		end)
		
		GetWidget('watch_gamelist_listbox'):RegisterWatchLua('ReplayDownload', function(widget, trigger)
			if (trigger.progress == 1) then
				mainUI.watch.PopulateReplays(true)
			end
			mainUI.watch.UpdateGameListActionButton()
		end, true, nil)		
		
		GetWidget('watch_gamelist_listbox'):RegisterWatchLua('CompatDownload', function(widget, trigger)
			mainUI.watch.UpdateGameListActionButton()
		end, true, nil)		

		watch_gamelist_main_action_btn:RegisterWatchLua('ReplayDownloadFailure', function(widget, trigger)
			widget:SetVisible(1)
			GenericDialog(
				'error_download_failed', 'error_download_failed_desc', '', 'general_ok', '',
					nil,
					nil
			) 		
		end, true, nil)
		
		profile_download_replay_progress_bar:RegisterWatchLua('ReplayDownloadFailure', function(widget, trigger)
			widget:SetVisible(0)
			GetWidget('watch_gamelist_listbox_blocker'):SetVisible(0)
		end, true, nil)

		profile_download_replay_progress_bar:RegisterWatchLua('ReplayDownload', function(widget, trigger)
			-- println('ReplayDownload trigger.progress ' .. tostring(trigger.progress) .. ' | ' .. type(trigger.progress))
			widget:SetVisible((tonumber(trigger.progress) > 0) and (tonumber(trigger.progress) < 1))
		end, true, nil)			
		
		GetWidget('profile_download_replay_progress_barBody'):RegisterWatchLua('ReplayDownload', function(widget, trigger)
			-- println('ReplayDownload trigger.progress ' .. tostring(trigger.progress) .. ' | ' .. type(trigger.progress))
			widget:SetWidth(ToPercent(tonumber(trigger.progress)))
		end, true, nil)				
		
		GetWidget('watch_gamelist_listbox_blocker'):RegisterWatchLua('ReplayDownload', function(widget, trigger)
			widget:SetVisible((tonumber(trigger.progress) > 0) and (tonumber(trigger.progress) < 1))
		end, true, nil)	
		
		GetWidget('profile_compat_replay_progress_bar'):RegisterWatchLua('CompatDownload', function(widget, trigger)
			-- println('CompatDownload trigger.downloadingPercent ' .. tostring(trigger.downloadingPercent) .. ' | ' .. type(trigger.downloadingPercent))
			widget:SetVisible(trigger.downloading)
		end, true, nil)		
		
		GetWidget('profile_compat_replay_progress_barBody'):RegisterWatchLua('CompatDownload', function(widget, trigger)
			-- println('CompatDownload trigger.downloadingPercent ' .. tostring(trigger.downloadingPercent) .. ' | ' .. type(trigger.downloadingPercent))
			widget:SetWidth(ToPercent(tonumber(trigger.downloadingPercent)))
		end, true, nil)				
		
		GetWidget('profile_manifest_replay_progress_bar'):RegisterWatchLua('ManifestDownload', function(widget, trigger)
			-- println('ManifestDownload trigger.downloadingPercent ' .. tostring(trigger.downloadingPercent) .. ' | ' .. type(trigger.downloadingPercent))
			widget:SetVisible(trigger.downloading)
		end, true, nil)			
		
		GetWidget('profile_manifest_replay_progress_barBody'):RegisterWatchLua('ManifestDownload', function(widget, trigger)
			-- println('ManifestDownload trigger.downloadingPercent ' .. tostring(trigger.downloadingPercent) .. ' | ' .. type(trigger.downloadingPercent))
			widget:SetWidth(ToPercent(tonumber(trigger.downloadingPercent)))
		end, true, nil)			
		
		-- scoreboard
		GetWidget('replay_outcome_header'):RegisterWatchLua('ReplayInfoGame', function(widget, trigger)
			if (trigger.winner == '1') or (trigger.winner == 1) or (trigger.winner == 'Legion') then
				GetWidget('replay_outcome_header'):SetText(Translate('temp_gamelobby_victory_for') .. ' ' .. Translate('temp_gamelobby_team1'))
			else
				GetWidget('replay_outcome_header'):SetText(Translate('temp_gamelobby_victory_for') .. ' ' .. Translate('temp_gamelobby_team2'))
			end		
		end, true, 'winner')		
		
		local function PopulateScoreboardReplay(object, matchStatsTable)
			local widget = replay_detailed
			if (not matchStatsTable) or (type(matchStatsTable) ~= 'table') or (not matchStatsTable.matchStats) then
				SevereError('PopulateScoreboard called with no matchStats table '.. tostring(matchStatsTable), 'main_reconnect_thatsucks', '', nil, nil, false)
				return nil
			end
			
			-- println('PopulateScoreboardReplay')
			GetWidget('watch_gamelist_main_scoreboard_btn'):SetEnabled(true)

			for playerIndex, playerInfo in pairs(matchStatsTable.matchStats.stats) do
				if (playerInfo) then
					if (not playerInfo.slot) then
						SevereError('playerInfo Player Slot Missing #0: '.. tostring(playerInfo.slot), 'main_reconnect_thatsucks', '', nil, nil, false)
						return
					end
					
					local slot 								= playerInfo.slot
					local postgame_scoreboard_row 			= object:GetWidget('replay_scoreboard_row_' .. slot)
					local bg_1 								= object:GetWidget('replay_scoreboard_row_' .. slot .. '_bg_1')
					local bg_2 								= object:GetWidget('replay_scoreboard_row_' .. slot .. '_bg_2')
					local hero_icon 						= object:GetWidget('replay_scoreboard_row_' .. slot .. '_hero_icon')
					local player_name 						= object:GetWidget('replay_scoreboard_row_' .. slot .. '_player_name')
					local pet_name 							= object:GetWidget('replay_scoreboard_row_' .. slot .. '_pet_name')
					
					local rowlabel_1 						= object:GetWidget('replay_scoreboard_row_' .. slot .. '_rowlabel_1')
					local rowlabel_2 						= object:GetWidget('replay_scoreboard_row_' .. slot .. '_rowlabel_2')
					local rowlabel_3 						= object:GetWidget('replay_scoreboard_row_' .. slot .. '_rowlabel_3')
					local rowlabel_4 						= object:GetWidget('replay_scoreboard_row_' .. slot .. '_rowlabel_4')
					local rowlabel_5 						= object:GetWidget('replay_scoreboard_row_' .. slot .. '_rowlabel_5')

					playerInfo.isBot = (math.floor(tonumber(playerInfo.ident_id)) == 0)
					playerInfo.isMe = (playerInfo.ident_id == GetIdentID())

					if (playerInfo.nickname) then
						if playerInfo.isBot then
							local botName = playerInfo.nickname
							if (botName) then
								if ValidateEntity(botName)  then
									player_name:SetText(GetEntityDisplayName(botName))
								else
									player_name:SetText(Translate(botName))
								end
							else
								player_name:SetText(Translate('general_bot'))
							end
						else
							player_name:SetText(playerInfo.nickname)
						end
					else
						player_name:SetText('')
					end			
						
					if (playerInfo.matchmakingFamiliarStats) then
						local familiarEntity		= tostring(playerInfo.matchmakingFamiliarStats.entityName)
						if ValidateEntity(familiarEntity) then
							local familiarDisplayName	= GetEntityDisplayName(familiarEntity)
							
							if familiarDisplayName and string.len(familiarDisplayName) > 0 then
								pet_name:SetText(Translate('heroselect_withpet', 'petname', familiarDisplayName))
								if (playerInfo.isMe) then
									GetWidget('replay_mini_scoreboard_row_0_pet_icon'):SetTexture(GetEntityIconPath(familiarEntity))
								end
							end
						end
					elseif (not playerInfo.isBot) then
						SevereError('No matchmakingFamiliarStats in EndMatch (gamescoreboard) data', 'main_reconnect_thatsucks', '', nil, nil, false)
					end
					
					if (playerInfo.matchmakingHeroStats) then
						if (playerInfo.matchmakingHeroStats.entityName) and (GetEntityIconPath(playerInfo.matchmakingHeroStats.entityName)) then
							hero_icon:SetTexture(GetEntityIconPath(playerInfo.matchmakingHeroStats.entityName))
							watchStateTrigger['heroIcon' .. playerInfo.slot] = playerInfo.matchmakingHeroStats.entityName or ''
							if (playerInfo.isMe) then
								object:GetWidget('replay_mini_scoreboard_row_0_hero_icon'):SetTexture(GetEntityIconPath(playerInfo.matchmakingHeroStats.entityName))
								watchStateTrigger.currentHeroIcon = GetEntityIconPath(playerInfo.matchmakingHeroStats.entityName)
							end
							watchStateTrigger:Trigger(false)
						end			
					elseif (not playerInfo.isBot) then
						SevereError('No matchmakingHeroStats in EndMatch (gamescoreboard) data', 'main_reconnect_thatsucks', '', nil, nil, false)
					end
					
					rowlabel_1:SetText(playerInfo.heroLevel or '?')			
					rowlabel_2:SetText(playerInfo.kills or '?')
					rowlabel_3:SetText(playerInfo.assists or '?')
					rowlabel_4:SetText(playerInfo.deaths or '?')
					rowlabel_5:SetText(playerInfo.gpm or '?')

					if (playerInfo) and (playerInfo.winner) and (playerInfo.winner == '1') and GetWidget('replay_outcome_header') then
						if (slot) and tonumber(slot) and (tonumber(slot) < 5) then
							GetWidget('replay_outcome_header'):SetText(Translate('temp_gamelobby_victory_for') .. ' ' .. Translate('temp_gamelobby_team1'))
						else
							GetWidget('replay_outcome_header'):SetText(Translate('temp_gamelobby_victory_for') .. ' ' .. Translate('temp_gamelobby_team2'))
						end						
					end
					
					for i=1,7,1 do
						if playerInfo.items['item_'..i] and string.len(playerInfo.items['item_'..i]) > 0 then
							if ValidateEntity(playerInfo.items['item_'..i]) then
								object:GetWidget('replay_scoreboard_inventory_icon_' .. slot .. '_'..i):SetTexture(GetEntityIconPath(playerInfo.items['item_'..i]))
							else
								object:GetWidget('replay_scoreboard_inventory_icon_' .. slot .. '_'..i):SetTexture('$checker')
							end
						elseif playerInfo.items['item'..i] and string.len(playerInfo.items['item'..i]) > 0 then
							if ValidateEntity(playerInfo.items['item'..i]) then
								object:GetWidget('replay_scoreboard_inventory_icon_' .. slot .. '_'..i):SetTexture(GetEntityIconPath(playerInfo.items['item'..i]))
							else
								object:GetWidget('replay_scoreboard_inventory_icon_' .. slot .. '_'..i):SetTexture('$checker')
							end
						else
							object:GetWidget('replay_scoreboard_inventory_icon_' .. slot .. '_'..i):SetTexture(style_item_emptySlot)
						end
					end					
					
					if (playerInfo.isMe) then
						for i=1,7,1 do
							if playerInfo.items['item_'..i] and string.len(playerInfo.items['item_'..i]) > 0 then
								if ValidateEntity(playerInfo.items['item_'..i]) then
									object:GetWidget('replay_mini_scoreboard_inventory_icon_0_'..i):SetTexture(GetEntityIconPath(playerInfo.items['item_'..i]))
								else
									object:GetWidget('replay_mini_scoreboard_inventory_icon_0_'..i):SetTexture('$checker')
								end
							elseif playerInfo.items['item'..i] and string.len(playerInfo.items['item'..i]) > 0 and ValidateEntity(playerInfo.items['item'..i]) then
								if ValidateEntity(playerInfo.items['item'..i]) then
									object:GetWidget('replay_mini_scoreboard_inventory_icon_0_'..i):SetTexture(GetEntityIconPath(playerInfo.items['item'..i]))
								else
									object:GetWidget('replay_mini_scoreboard_inventory_icon_0_'..i):SetTexture('$checker')
								end
							else
								object:GetWidget('replay_mini_scoreboard_inventory_icon_0_'..i):SetTexture(style_item_emptySlot)
							end
						end						
					end
					
				else
					print('no stats for index ' .. playerIndex)
				end
				
			end

		end	

		replay_scoreboard_close:SetCallback('onclick', function(widget)
			widget:GetWidget('replay_detailed'):FadeOut(150)
		end)			

		local lastMatchID = -1
		function mainUI.watch.GetMatchStats(incomingMatchID)

			local matchID = incomingMatchID or LuaTrigger.GetTrigger('ReplayInfoGame').matchID
			local validMatchID = false

			if ((matchID) and (tonumber(matchID)) and (tonumber(matchID) > 0)) and (matchID ~= '0') then
				validMatchID = true
			end

			if (validMatchID) then
				watchStateTrigger.matchID = matchID
				watchStateTrigger:Trigger(false)				
			
				if (lastMatchID ~= matchID) then
					lastMatchID = matchID
	
					local function successFunction(request)	-- response handler
						local responseData
						if request.GetBody then
							responseData = request:GetBody()
						else
							responseData = request
						end
						if responseData == nil or responseData.matchStats == nil or responseData.matchStats.stats == nil then
							SevereError('No Match Stats in EndMatch (replay) data', 'main_reconnect_thatsucks', '', nil, nil, false)
							printr(responseData)
							return nil
						else
							PopulateScoreboardReplay(object, responseData)
							mainUI = mainUI or {}
							mainUI.savedLocally = mainUI.savedLocally or {}
							tempMatchStatsCache = tempMatchStatsCache or {}							
							tempMatchStatsCache[matchID] = responseData
							return true
						end
					end				
					
					local function failureFunction(request)	-- error handler
						SevereError('GetMatchStats (replay) Request Error: ' .. Translate(request:GetError() or ''), 'main_reconnect_thatsucks', '', nil, nil, false)
						return nil
					end				
					
					local insertMe = matchID
					if string.find(insertMe, '%.') or (insertMe == '0') then
					
					else
						insertMe = string.sub(insertMe, 1, -4) .. '.' .. string.sub(insertMe, -3)
					end
					
					if mainUI and mainUI.savedLocally and tempMatchStatsCache and (insertMe) and tempMatchStatsCache[insertMe] then
						println('GetMatchStats from cache ' .. tostring(insertMe))
						successFunction(tempMatchStatsCache[insertMe])
					elseif (insertMe) then
						println('GetMatchStats from web ' .. tostring(insertMe))
						Strife_Web_Requests:GetMatchStats(insertMe, successFunction, failureFunction)
					end					

				else
					local insertMe = matchID
					if string.find(insertMe, '%.') or (insertMe == '0') then
					
					else
						insertMe = string.sub(insertMe, 1, -4) .. '.' .. string.sub(insertMe, -3)
					end				
				
					if mainUI and mainUI.savedLocally and tempMatchStatsCache and (insertMe) and tempMatchStatsCache[insertMe] then
						println('GetMatchStats from cache as same matchid ' .. tostring(insertMe))
						PopulateScoreboardReplay(object, tempMatchStatsCache[insertMe])
					end
					-- println('GetMatchStats skipping ' .. tostring(matchID))				
				end
			else
				println('GetMatchStats invalid match id ' .. tostring(matchID))
			end		
		end
		
		watch_gamelist_main_scoreboard_btn:SetCallback('onclick', function()
			PlaySound('/ui/sounds/launcher/sfx_replay_scoreboard.wav')
			self:GetWidget('replay_detailed'):FadeIn(150)
		end)		
		
	end	
	
	RegisterReplayList()

	local function CommentsInputRegister(object)
		
		local watch_gamelist_main_comment_btn		= object:GetWidget('watch_gamelist_main_comment_btn')		
		local close_parent_button					= object:GetWidget('watch_edit_comment_close_btn')		
		local watch_edit_comment_popup 				= object:GetWidget('watch_edit_comment_popup')
		local watch_edit_comment_rename_coverup		= object:GetWidget('watch_edit_comment_rename_coverup')
		local watch_edit_comment_rename_textbox		= object:GetWidget('watch_edit_comment_rename_textbox')
		local watch_edit_comment_rename_close		= object:GetWidget('watch_edit_comment_rename_close')
		local watch_edit_comment_notes_coverup		= object:GetWidget('watch_edit_comment_notes_coverup')
		local watch_edit_comment_notes_textbox		= object:GetWidget('watch_edit_comment_notes_textbox')
		local watch_edit_comment_notes_close		= object:GetWidget('watch_edit_comment_notes_close')
		local renameMatch
		local notesMatch
		local replayPath
		local replayMatchID
		
		function mainUI.watch.EditMatchInfo(_, matchID)

			renameMatch = nil
			notesMatch = nil
			
			local watchStateMatchID
			if (watchStateTrigger.matchID) and (not Empty(watchStateTrigger.matchID )) then
				watchStateMatchID = watchStateTrigger.matchID
			end
			
			local matchID = matchID or watchStateMatchID or LuaTrigger.GetTrigger('ReplayInfoGame').matchID
			replayMatchID = matchID

			if ((matchID) and (tonumber(matchID)) and (tonumber(matchID) > 0)) and (matchID ~= '0') and (matchID ~= '.0') then
				watch_edit_comment_popup:FadeIn(250)
				GetWidget('watch_gamelist_main_comment_btn'):SetEnabled(1)
				if (mainUI.savedRemotely.matchDatabase) and (mainUI.savedRemotely.matchDatabase[matchID]) and (mainUI.savedRemotely.matchDatabase[matchID].matchNameOverride) and (not Empty(mainUI.savedRemotely.matchDatabase[matchID].matchNameOverride)) then
					watch_edit_comment_rename_textbox:SetInputLine(mainUI.savedRemotely.matchDatabase[matchID].matchNameOverride)
					watch_edit_comment_rename_coverup:SetVisible(0)
					renameMatch = mainUI.savedRemotely.matchDatabase[matchID].matchNameOverride
				end	
				
				if (mainUI.savedRemotely.matchDatabase) and (mainUI.savedRemotely.matchDatabase[matchID]) and (mainUI.savedRemotely.matchDatabase[matchID].matchNote) and (not Empty(mainUI.savedRemotely.matchDatabase[matchID].matchNote)) then
					watch_edit_comment_notes_textbox:SetInputLine(mainUI.savedRemotely.matchDatabase[matchID].matchNote)
					watch_edit_comment_notes_coverup:SetVisible(0)
					notesMatch = mainUI.savedRemotely.matchDatabase[matchID].matchNote
				end

			end
			
		end
		
		function mainUI.watch.GetMatchInfo(_, matchID)
		
			local watchStateMatchID
			if (watchStateTrigger.matchID) and (not Empty(watchStateTrigger.matchID )) then
				watchStateMatchID = watchStateTrigger.matchID
			end		
		
			local matchID = matchID or watchStateMatchID or LuaTrigger.GetTrigger('ReplayInfoGame').matchID
			if ((matchID) and (tonumber(matchID)) and (tonumber(matchID) > 0)) and (matchID ~= '0') and (matchID ~= '.0') then
				GetWidget('watch_gamelist_main_comment_btn'):SetEnabled(1)
				if (mainUI.savedRemotely.matchDatabase) and (mainUI.savedRemotely.matchDatabase[matchID]) and (mainUI.savedRemotely.matchDatabase[matchID].matchNameOverride) and (not Empty(mainUI.savedRemotely.matchDatabase[matchID].matchNameOverride)) then
					watchStateTrigger.matchName = mainUI.savedRemotely.matchDatabase[matchID].matchNameOverride
				else
					watchStateTrigger.matchName = ''
				end
				if (mainUI.savedRemotely.matchDatabase) and (mainUI.savedRemotely.matchDatabase[matchID]) and (mainUI.savedRemotely.matchDatabase[matchID].matchNote) and (not Empty(mainUI.savedRemotely.matchDatabase[matchID].matchNote)) then
					watchStateTrigger.matchComment = mainUI.savedRemotely.matchDatabase[matchID].matchNote
				else
					watchStateTrigger.matchComment = ''
				end
			else
				watchStateTrigger.matchName = ''
				watchStateTrigger.matchComment = ''
			end
			watchStateTrigger:Trigger(false)		
		end
		
		function mainUI.watch.ReturnMatchInfo(path, matchID)
		
			local watchStateMatchID
			if (watchStateTrigger.matchID) and (not Empty(watchStateTrigger.matchID )) then
				watchStateMatchID = watchStateTrigger.matchID
			end			
		
			local matchName, matchNote = '', ''
			local matchID = matchID or watchStateMatchID or LuaTrigger.GetTrigger('ReplayInfoGame').matchID
			if ((matchID) and (tonumber(matchID)) and (tonumber(matchID) > 0)) and (matchID ~= '0') and (matchID ~= '.0') then
				if (mainUI.savedRemotely.matchDatabase) and (mainUI.savedRemotely.matchDatabase[matchID]) and (mainUI.savedRemotely.matchDatabase[matchID].matchNameOverride) and (not Empty(mainUI.savedRemotely.matchDatabase[matchID].matchNameOverride)) then
					matchName = mainUI.savedRemotely.matchDatabase[matchID].matchNameOverride
				end
				if (mainUI.savedRemotely.matchDatabase) and (mainUI.savedRemotely.matchDatabase[matchID]) and (mainUI.savedRemotely.matchDatabase[matchID].matchNote) and (not Empty(mainUI.savedRemotely.matchDatabase[matchID].matchNote)) then
					matchNote = mainUI.savedRemotely.matchDatabase[matchID].matchNote
				end
			end
			return matchName, matchNote
		end		
		
		watch_gamelist_main_comment_btn:SetCallback('onclick', function(widget)
			PlaySound('/ui/sounds/launcher/sfx_replay_note.wav')
			mainUI.watch.EditMatchInfo()
		end)
		
		--
		
		function mainUI.watch.RenameInputOnEnter()
			watch_edit_comment_rename_textbox:SetFocus(false)
		end
		
		function mainUI.watch.RenameInputOnEsc()
			watch_edit_comment_rename_textbox:EraseInputLine()
			watch_edit_comment_rename_textbox:SetFocus(false)	
			watch_edit_comment_rename_coverup:SetVisible(true)
			watch_edit_comment_rename_close:SetVisible(0)		
		end
		
		watch_edit_comment_rename_close:SetCallback('onclick', function(widget)
			mainUI.watch.RenameInputOnEsc()
		end)	
		
		watch_edit_comment_rename_textbox:SetCallback('onfocus', function(widget)
			watch_edit_comment_rename_coverup:SetVisible(false)
			watch_edit_comment_rename_close:SetVisible(1)
		end)
		
		watch_edit_comment_rename_textbox:SetCallback('onlosefocus', function(widget)
			if string.len(widget:GetValue()) == 0 then
				watch_edit_comment_rename_coverup:SetVisible(true)
				watch_edit_comment_rename_close:SetVisible(0)
			end
		end)	
		
		watch_edit_comment_rename_textbox:SetCallback('onhide', function(widget)
			 mainUI.watch.RenameInputOnEsc()
		end)	
		
		watch_edit_comment_rename_textbox:SetCallback('onchange', function(widget)
			renameMatch = widget:GetValue()
		end)		
		
		--
		
		function mainUI.watch.NotesInputOnEnter()
			watch_edit_comment_notes_textbox:SetFocus(false)
		end
		
		function mainUI.watch.NotesInputOnEsc()
			watch_edit_comment_notes_textbox:EraseInputLine()
			watch_edit_comment_notes_textbox:SetFocus(false)	
			watch_edit_comment_notes_coverup:SetVisible(true)
			watch_edit_comment_notes_close:SetVisible(0)		
		end

		watch_edit_comment_notes_close:SetCallback('onclick', function(widget)
			mainUI.watch.NotesInputOnEsc()
		end)	
		
		watch_edit_comment_notes_textbox:SetCallback('onfocus', function(widget)
			watch_edit_comment_notes_coverup:SetVisible(false)
			watch_edit_comment_notes_close:SetVisible(1)
		end)
		
		watch_edit_comment_notes_textbox:SetCallback('onlosefocus', function(widget)
			if string.len(widget:GetValue()) == 0 then
				watch_edit_comment_notes_coverup:SetVisible(true)
				watch_edit_comment_notes_close:SetVisible(0)
			end
		end)	
		
		watch_edit_comment_notes_textbox:SetCallback('onhide', function(widget)
			 mainUI.watch.NotesInputOnEsc()
		end)	
		
		watch_edit_comment_notes_textbox:SetCallback('onchange', function(widget)
			notesMatch = widget:GetValue()
		end)		
		
		--
		
		GetWidget('watch_edit_comment_btn_1'):SetCallback('onclick', function(widget) 
			watch_edit_comment_popup:FadeOut(125) 
			mainUI.savedRemotely.matchDatabase = mainUI.savedRemotely.matchDatabase or {}
			if (renameMatch) and (replayMatchID) and (not Empty(replayMatchID)) then
				println('replayMatchID ' .. replayMatchID)
				if (not Empty(renameMatch)) then
					mainUI.savedRemotely.matchDatabase[replayMatchID] = mainUI.savedRemotely.matchDatabase[replayMatchID] or {}
					mainUI.savedRemotely.matchDatabase[replayMatchID].matchNameOverride = renameMatch
				else
					mainUI.savedRemotely.matchDatabase[replayMatchID] = mainUI.savedRemotely.matchDatabase[replayMatchID] or {}
					mainUI.savedRemotely.matchDatabase[replayMatchID].matchNameOverride = nil				
				end
				SaveState()
			end
			if (notesMatch) and (replayMatchID) and (not Empty(replayMatchID)) then
				if  (not Empty(notesMatch)) then
					mainUI.savedRemotely.matchDatabase[replayMatchID] = mainUI.savedRemotely.matchDatabase[replayMatchID] or {}
					mainUI.savedRemotely.matchDatabase[replayMatchID].matchNote = notesMatch
				else
					mainUI.savedRemotely.matchDatabase[replayMatchID] = mainUI.savedRemotely.matchDatabase[replayMatchID] or {}
					mainUI.savedRemotely.matchDatabase[replayMatchID].matchNote = ''
				end
				SaveState()
			end		
			mainUI.watch.PopulateReplays()		
		end)
		
		GetWidget('watch_edit_comment_btn_2'):SetCallback('onclick', function(widget) watch_edit_comment_popup:FadeOut(125) end)
	
		close_parent_button:SetCallback('onclick', function(widget)
			watch_edit_comment_popup:FadeOut(250)
		end)	
		
	end
	
	CommentsInputRegister(object)	
	
	interface:GetWidget('main_watch_streams_close_button_2'):SetCallback('onclick', function(widget)
		local trigger		= LuaTrigger.GetTrigger('mainPanelStatus')
		if (trigger.hasIdent) then
			trigger.main = 101
		else
			trigger.main = 0
		end		
		trigger:Trigger(false)
	end)
	
	
	-- Breadcrumbs
	local strIndex = {featured=1, replays=2, streams=3, spectate=4, howto=5}
	
	local function setState(state)
		watchStateTrigger.state = state
		watchStateTrigger:Trigger(false)
		mainUI.savedLocally.watchDefaultTab = state
		mainUI.setBreadcrumbsSelected(strIndex[state])
		if (GetCvarBool('ui_newUISounds')) then PlaySound('/ui/sounds/launcher/sfx_watch_'..state..'.wav') end
	end
	
	local breadCrumbsTable = {
		{text='watch_featured',onclick=function(widget) setState('featured') end, group="watch_menu_group", id="watch_featured" },
		{text='watch_replays' ,onclick=function(widget) setState('replays')  end, group="watch_menu_group", id="watch_replays" },
		{text='watch_streams' ,onclick=function(widget) setState('streams')  end, group="watch_menu_group", id="watch_streams" },
		{text='watch_spectate',onclick=function(widget) setState('spectate') end, group="watch_menu_group", id="watch_spectate" },
		{text='watch_howto',   onclick=function(widget) setState('howto')    end, group="watch_menu_group", id="watch_learn" },
	}
	
	local gotReplays = false
	interface:GetWidget('watch'):RegisterWatchLua('mainPanelAnimationStatus', function(widget, trigger)
		if (trigger.newMain ~= 28) and (trigger.newMain ~= -1) then			-- outro
			groupfcall('watch_menu_group', function(_, widget) widget:SetNoClick(1) end)
			groupfcall('watch_animation_widgets', function(_, widget) widget:DoEventN(8) end)	
			groupfcall('watch_featured_anim_group', function(_, widget) widget:DoEventN(8) end)
			groupfcall('watch_replays_anim_group', function(_, widget) widget:DoEventN(8) end)
			groupfcall('watch_streams_anim_group', function(_, widget) widget:DoEventN(8) end)
			groupfcall('watch_spectate_anim_group', function(_, widget) widget:DoEventN(8) end)		
			groupfcall('watch_howto_anim_group', function(_, widget) widget:DoEventN(8) end)		
			libThread.threadFunc(function()	
				wait(styles_mainSwapAnimationDuration)				
				widget:SetVisible(false)
				groupfcall('watch_menu_group', function(_, widget) widget:SetNoClick(0) end)
			end)			
		elseif (trigger.main ~= 28) and (trigger.newMain ~= 28) then			-- fully hidden	
			widget:SetVisible(false)
		elseif (trigger.newMain == 28) and (trigger.newMain ~= -1) then		-- intro
			breadCrumbsTable[1].visible = not ((mainUI.featureMaintenance) and ((mainUI.featureMaintenance['watch']) or (mainUI.featureMaintenance['twitch_vods'])))
			breadCrumbsTable[2].visible = not ((mainUI.featureMaintenance) and ((mainUI.featureMaintenance['watch']) or (mainUI.featureMaintenance['replays'])))
			breadCrumbsTable[3].visible = not ((mainUI.featureMaintenance) and ((mainUI.featureMaintenance['watch']) or (mainUI.featureMaintenance['twitch_stream'])))
			breadCrumbsTable[4].visible = not ((mainUI.featureMaintenance) and ((mainUI.featureMaintenance['watch']) or (mainUI.featureMaintenance['spectate'])))
			breadCrumbsTable[5].visible = not ((mainUI.featureMaintenance) and ((mainUI.featureMaintenance['watch']) or (mainUI.featureMaintenance['howto'])))
			mainUI.initBreadcrumbs(breadCrumbsTable, nil, '42s')
			mainUI.setBreadcrumbsSelected(mainUI.savedLocally.watchDefaultTab and strIndex[mainUI.savedLocally.watchDefaultTab] or 1)
			setMainTriggers({
				mainBackground = {blackTop=true}, -- Cover under the navigation
				mainNavigation = {breadCrumbsVisible=true}, -- navigation with breadcrumbs
			})		
			widget:SetVisible(true)
			if ((mainUI.featureMaintenance) and ((mainUI.featureMaintenance['watch']) or (mainUI.featureMaintenance['twitch_vods']))) then
				watchStateTrigger.state = mainUI.savedLocally.watchDefaultTab or 'replays'
			else
				watchStateTrigger.state = mainUI.savedLocally.watchDefaultTab or 'featured'
			end
			watchStateTrigger:Trigger(true)			
			libThread.threadFunc(function()	
				wait(1)		
				groupfcall('watch_animation_widgets', function(_, widget) RegisterRadialEase(widget,  508, 555, true) widget:DoEventN(7) end)
			end)
		elseif (trigger.main == 28) then										-- fully displayed
			libThread.threadFunc(function()	
				wait(50)						
				if (not gotReplays) and (watchStateTrigger.state == 'replays') then
					gotReplays = true
					mainUI.watch.PopulateReplays()
				end
			end)
			widget:SetVisible(true)
			if (mainUI) and  (mainUI.savedLocally) and  (mainUI.savedLocally.adaptiveTraining) and (mainUI.savedLocally.adaptiveTraining.featureList) and (mainUI.savedLocally.adaptiveTraining.featureList) then
				mainUI.AdaptiveTraining.RecordUtilisationInstanceByFeatureName('watch')
			end
		end
	end, false, nil, 'main', 'newMain', 'lastMain')	

	-- watch_content_menu RMM some menu animation
		
	interface:GetWidget('watch_content_featured'):RegisterWatchLua('WatchStateTrigger', function(widget, trigger)
		if (watchStateTrigger.state == 'featured') then
			widget:SetVisible(1)
			groupfcall('watch_menu_group', function(_, widget) widget:SetNoClick(1) end)
			mainUI.watch.GetTwitchStreams()
			groupfcall('watch_featured_anim_group', function(_, widget) RegisterRadialEase(widget) widget:DoEventN(7) end)
		else
			groupfcall('watch_featured_anim_group', function(_, widget) widget:DoEventN(8) end)
			libThread.threadFunc(function()	
				wait(styles_mainSwapAnimationDuration)		
				widget:SetVisible(0)
				groupfcall('watch_menu_group', function(_, widget) widget:SetNoClick(0) end)
			end)
		end
	end, false, nil, 'state')
		
	interface:GetWidget('watch_content_replays'):RegisterWatchLua('WatchStateTrigger', function(widget, trigger)
		if (watchStateTrigger.state == 'replays') then
			if (not gotReplays) and (LuaTrigger.GetTrigger('mainPanelAnimationStatus').main == 28) then
				gotReplays = true
				mainUI.watch.PopulateReplays()
			end			
			widget:SetVisible(1)
			groupfcall('watch_replays_anim_group', function(_, widget) RegisterRadialEase(widget, 900) widget:DoEventN(7) end)
			groupfcall('watch_menu_group', function(_, widget) widget:SetNoClick(1) end)
		else
			groupfcall('watch_replays_anim_group', function(_, widget) widget:DoEventN(8) end)
			libThread.threadFunc(function()	
				wait(styles_mainSwapAnimationDuration)		
				widget:SetVisible(0)
				groupfcall('watch_menu_group', function(_, widget) widget:SetNoClick(0) end)
			end)			
		end
	end, false, nil, 'state')	

	interface:GetWidget('watch_content_streams'):RegisterWatchLua('WatchStateTrigger', function(widget, trigger)
		if (watchStateTrigger.state == 'streams') then
			widget:SetVisible(1)
			groupfcall('watch_menu_group', function(_, widget) widget:SetNoClick(1) end)
			mainUI.watch.GetTwitchStreams()
			groupfcall('watch_streams_anim_group', function(_, widget) RegisterRadialEase(widget) widget:DoEventN(7) end)
		else
			groupfcall('watch_streams_anim_group', function(_, widget) widget:DoEventN(8) end)
			libThread.threadFunc(function()	
				wait(styles_mainSwapAnimationDuration)		
				widget:SetVisible(0)
				groupfcall('watch_menu_group', function(_, widget) widget:SetNoClick(0) end)
			end)			
		end
	end, false, nil, 'state')	

	interface:GetWidget('watch_content_spectate'):RegisterWatchLua('WatchStateTrigger', function(widget, trigger)
		if (watchStateTrigger.state == 'spectate') then
			widget:SetVisible(1)
			groupfcall('watch_spectate_anim_group', function(_, widget) RegisterRadialEase(widget, nil, nil, true) widget:DoEventN(7) end)
			groupfcall('watch_menu_group', function(_, widget) widget:SetNoClick(1) end)
			mainUI.watch.GetFriendsToSpectate()
		else
			groupfcall('watch_spectate_anim_group', function(_, widget) widget:DoEventN(8) end)
			libThread.threadFunc(function()	
				wait(styles_mainSwapAnimationDuration)		
				widget:SetVisible(0)
				groupfcall('watch_menu_group', function(_, widget) widget:SetNoClick(0) end)
			end)			
		end
	end, false, nil, 'state')
	
	interface:GetWidget('watch_content_howto'):RegisterWatchLua('WatchStateTrigger', function(widget, trigger)
		if (watchStateTrigger.state == 'howto') then
			widget:SetVisible(1)
			groupfcall('watch_howto_anim_group', function(_, widget) RegisterRadialEase(widget, nil, nil, true) widget:DoEventN(7) end)
			groupfcall('watch_menu_group', function(_, widget) widget:SetNoClick(1) end)
			mainUI.watch.GetHeroHowToVideos()
		else
			groupfcall('watch_howto_anim_group', function(_, widget) widget:DoEventN(8) end)
			libThread.threadFunc(function()	
				wait(styles_mainSwapAnimationDuration)		
				widget:SetVisible(0)
				groupfcall('watch_menu_group', function(_, widget) widget:SetNoClick(0) end)
			end)			
		end
	end, false, nil, 'state')

end	
	
WatchRegister(object)
