-- Web requests
Strife_Web_Requests = Strife_Web_Requests or {}
Chat_Web_Requests = Chat_Web_Requests or {}
mainUI = mainUI or {}
mainUI.savedLocally 	= mainUI.savedLocally 		or {}
mainUI.savedRemotely 	= mainUI.savedRemotely 		or {}
mainUI.savedAnonymously	= mainUI.savedAnonymously 	or {}
local interface = object

function Strife_Web_Requests:SpawnRequest(identid, resource, requestService)
	if (resource) then
		local request = Master.SpawnRequest()
		request:SetServerAddress(Host.GetMasterServerAddress() or Cvar.GetCvar('game_masterSvrAddr'):GetString())

		request:SetAuthID(Client.GetAccountID())
		request:SetAuthSessionKey(Client.GetSessionKey())
		request:SetAuthService('igames')
		request:SetAuthClientType('c')

		request:SetRequestService(requestService or Cvar.GetCvar('game_service'):GetString() or 'strife')
		request:SetRequestClientType('c')

		request:SetResource(resource)

		return request
	else
		SevereError('SpawnRequest called without resource', 'main_reconnect_thatsucks', '', nil, nil, nil)
		return nil
	end
end

function Strife_Web_Requests:SpawniGamesRequest(resource)
	if (resource) then
		local request = Master.SpawnRequest()
		request:SetServerAddress(Host.GetMasterServerAddress() or Cvar.GetCvar('game_masterSvrAddr'):GetString())

		request:SetAuthID(Client.GetAccountID())
		request:SetAuthSessionKey(Client.GetSessionKey())
		request:SetAuthService('igames')
		request:SetAuthClientType('c')

		request:SetRequestService('igames')
		request:SetRequestClientType('c')

		request:SetResource(resource)

		return request
	else
		SevereError('SpawnRequest called without resource', 'main_reconnect_thatsucks', '', nil, nil, nil)
		return nil
	end
end

-- =================================================

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

-- =======

function Strife_Web_Requests:SetPlayerResources(successFunction, failFunction, dataIndex, dataValue)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	if (dataIndex) and (not Empty(dataIndex)) and (dataValue) and (not Empty(dataValue)) then

		local request = self:SpawnRequest(GetIdentID(), '/playerResources/identid/' .. URLEncode(GetIdentID()) )
		request:SetRequestMethod('POST')

		request:AddVariable('resource' , dataValue)
		request:AddVariable('location' , dataIndex)

		request:SendRequest(true)

		request:ManagedWait(
			InterceptSuccessErrors(successFunction),
			failFunction
		)
	else
		SevereError('SetPlayerResources Request Error: Input Was Invalid', 'main_reconnect_thatsucks', '', nil, nil, false)
	end
end

function Strife_Web_Requests:GetPlayerResources(successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local request = self:SpawnRequest(GetIdentID(), '/playerResources/identid/' .. URLEncode(GetIdentID()) )
	request:SetRequestMethod('GET')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)

end

function SetPlayerResources(dataIndex, dataValue, parentSuccessFunction, parentFailureFunction)

	local function successFunction(request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('SetPlayerResources - no data', 'main_reconnect_thatsucks', '', nil, nil, false)
			return nil
		else
			if (parentSuccessFunction) then
				parentSuccessFunction()
			end
			return true
		end
	end

	local function failureFunction(request)	-- error handler
		SevereError('SetPlayerResources Request Error: ' .. Translate(request:GetError() or ''), 'main_reconnect_thatsucks', '', nil, nil, false)
		if (parentFailureFunction) then
			parentFailureFunction()
		end
		return nil
	end

	if (dataValue) and (dataIndex) then
		Strife_Web_Requests:SetPlayerResources(successFunction, failureFunction, dataIndex, dataValue)
	else
		SevereError('SetPlayerResources failed to encode data', 'main_reconnect_thatsucks', '', nil, nil, false)
	end
end

function GetPlayerResources()

	local function successFunction(request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('GetPlayerResources - no data', 'main_reconnect_thatsucks', '', nil, nil, false)
			return nil
		else
			return responseData
		end
	end

	local function failureFunction(request)	-- error handler
		SevereError('GetPlayerResources Request Error: ' .. Translate(request:GetError() or ''), 'main_reconnect_thatsucks', '', nil, nil, false)
		return nil
	end

	return Strife_Web_Requests:GetPlayerResources(successFunction, failureFunction)
end

--==== 

function Strife_Web_Requests:SaveCloudStorage(successFunction, failFunction, dataTable)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	if (dataTable) and (GetIdentID()) then

		local categoryName = 'cloud'	
	
		local request = self:SpawnRequest(GetIdentID(), '/gameProgress/identid/' .. URLEncode(GetIdentID()))
		request:SetRequestMethod('PUT')
		
		request:AddVariable('action', 'updateMultipleValues')
		
		-- printr(dataTable)
		
		for key, value in pairs(dataTable) do
			if (categoryName) and (key) and (value) then
				-- println('^g' .. tostring(categoryName) .. ' | ' .. tostring(key) .. ' | ' .. tostring(value))
				request:AddVariable('data[' .. categoryName .. '][' .. key .. ']', value)
			else
				-- println('^r' .. tostring(categoryName) .. ' | ' .. tostring(key) .. ' | ' .. tostring(value))
			end
		end
		
		request:SendRequest(true)

		request:ManagedWait(
			InterceptSuccessErrors(successFunction),
			failFunction
		)
	else
		SevereError('SaveCloudStorage Request Error: Input Was Invalid', 'main_reconnect_thatsucks', '', nil, nil, false)
	end
end

function Strife_Web_Requests:GetCloudStorage(successFunction, failFunction, key)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end
	
	local categoryName = 'cloud'
	local request = self:SpawnRequest(GetIdentID(), '/gameProgress/identid/' .. URLEncode(GetIdentID()) .. '/category/' .. URLEncode(categoryName))
	request:SetRequestMethod('GET')
	
	if (key) then
		request:AddVariable('key', key)
	end
	
	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)

end

--====

function Strife_Web_Requests:SetAccountIcon(successFunction, failFunction, productIncrement) -- 487 489
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local request = self:SpawnRequest(GetIdentID(), '/ident/identid/' .. URLEncode(GetIdentID()))
	request:SetRequestMethod('PUT')

	request:AddVariable('action', 'setIcon')
	request:AddVariable('newIcon', productIncrement)

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)

end

function Strife_Web_Requests:SetTitle(successFunction, failFunction, productIncrement) -- 488 490
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local request = self:SpawnRequest(GetIdentID(), '/ident/identid/' .. URLEncode(GetIdentID()))
	request:SetRequestMethod('PUT')

	request:AddVariable('action', 'setTitle')
	request:AddVariable('newTitle', productIncrement)

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)

end

function Strife_Web_Requests:PurchaseProduct(successFunction, failFunction, productIncrement)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local request = self:SpawnRequest(GetIdentID(), '/purchase/identid/' .. URLEncode(GetIdentID()) .. '/purchaseIncrement/' .. URLEncode(productIncrement))
	request:SetRequestMethod('POST')

	request:AddVariable('commodity', 'gems')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)

end

function Strife_Web_Requests:SetDisplayNameAndUniqueID(successFunction, failFunction, newDisplayName, newUniqueID)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local accountInfo = LuaTrigger.GetTrigger('AccountInfo')

	if (not Empty(accountInfo.nickname)) or (newDisplayName) then

		local request = self:SpawnRequest(GetIdentID(), '/ident/identid/' .. URLEncode(GetIdentID()))
		request:SetRequestMethod('PUT')

		request:AddVariable('action', 'setNickname')
		request:AddVariable('newNickname', newDisplayName or accountInfo.nickname)
		if (newUniqueID) then
			request:AddVariable('newUniqid', newUniqueID)
		end

		request:SendRequest(true)

		request:ManagedWait(
			InterceptSuccessErrors(successFunction),
			failFunction
		)

	end
end

function Strife_Web_Requests:GetBoostProductIDAndCost(successFunction, failFunction)

	successFunction = successFunction or function (request)	-- response handler
		local response1Body = request1:GetBody() 
		if (response1Body) and (response1Body.boosts) and (response1Body.boosts.boosts) then
			for i,v in pairs(response1Body.boosts.boosts) do
				if (v.boostItemKey) and (v.boostItemKey == 'experience') then
					return (v.productIncrement) or -1, (v.gems) or -1
				end
			end
		end
		return -1, -1
	end

	failFunction = failFunction or function (request)	-- error handler
		SevereError('GetBoostProductIDAndCost Request Error: ' .. Translate(request:GetError() or ''), 'general_ok', '', nil, nil, false)
		return -1, -1
	end

	local request = self:SpawnRequest(GetIdentID(), '/purchase')
	 
	request:SetRequestMethod('GET') 
	
	request:AddVariable('boosts', '1') 

	request:SendRequest(true) 
	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	 )

end

function Strife_Web_Requests:PurchaseProductByID(productIncrement, successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end
	
	successFunction = successFunction or function (request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('PurchaseProductByID - no data', 'general_ok', '', nil, nil, false)
		else
			println('^g SUCCESS')
			printr(responseData)
		end
	end

	failFunction = failFunction or function (request)	-- error handler
		-- SevereError('PurchaseProductByID Request Error: ' .. Translate(request:GetError() or ''), 'general_ok', '', nil, nil, false)
	end
	
	local request = self:SpawnRequest(GetIdentID(), '/purchase/identid/' .. URLEncode(GetIdentID()) .. '/purchaseIncrement/' .. URLEncode(productIncrement))
	request:SetRequestMethod('POST')

	request:AddVariable('commodity', 'gems')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		InterceptFailErrors(failFunction)
	)	
	
end

function Strife_Web_Requests:GetLadder(successFunction, failFunction, targetIdentID)

	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local request = self:SpawnRequest(GetIdentID(), '/ident/identid/' .. URLEncode(targetIdentID or GetIdentID()))
	request:SetRequestMethod('GET')

	request:AddVariable('ladderRankings', '1')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)
end

function Strife_Web_Requests:GetProfile(successFunction, failFunction, targetIdentID)

	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local request = self:SpawnRequest(GetIdentID(), '/profile/identid/' .. URLEncode(targetIdentID or GetIdentID()))
	request:SetRequestMethod('GET')

	request:AddVariable('groups', '1')
	request:AddVariable('matchHistoryList', '1')
	request:AddVariable('clientAccountIcons', '1')
	request:AddVariable('clientAccountTitles', '1')
	request:AddVariable('clientAccountColors', '1')
	-- request:AddVariable('rankedHeroRatings', '1')
	-- request:AddVariable('rankedRating', '1')
	request:AddVariable('friendReferal', '1')
	request:AddVariable('ladderRankings', '1')
	-- request:AddVariable('clan', '1')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)
end

function Strife_Web_Requests:GetAccountStats(successFunction, failFunction, targetIdentID)

	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local request = self:SpawnRequest(GetIdentID(), '/ident/identid/' .. URLEncode(targetIdentID or GetIdentID()))
	request:SetRequestMethod('GET')

	-- request:AddVariable('rankedRating', '1')
	-- request:AddVariable('rankedHeroRatings', '1')
	request:AddVariable('identStats', '1')
	request:AddVariable('matchmakingStats', '1')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)
end

-- Create Account (igames)
function Strife_Web_Requests:CreateAccount(successFunction, failFunction, email, password, username, firstName, lastName, betaKey, newsletterOptIn)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local request = self:SpawnRequest(GetIdentID(), '/account', 'igames')
	request:SetRequestMethod('POST')

	request:AddVariable('email', email)
	request:AddVariable('password', password)
	request:AddVariable('display', username)	-- igames service
	-- request:AddVariable('nickname', display)	-- strife service

	request:AddVariable('firstName', firstName)
	request:AddVariable('lastName', lastName)
	request:AddVariable('betaKey', betaKey)
	request:AddVariable('newsletterOptIn', newsletterOptIn or 0)
	request:AddVariable('game', 'strife')	-- This causes an ident to get created using the supplied 'display' name.

	request:SendSecureRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		InterceptFailErrors(failFunction)
	)

end

-- Replays
function Strife_Web_Requests:GetReplayDownloadURL(successFunction, failFunction, matchID)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local request = self:SpawnRequest(GetIdentID(), '/replay/matchid/' .. URLEncode(matchID))
	request:SetRequestMethod('GET')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)

end

function Strife_Web_Requests.DownloadReplay(matchID)
	local matchID = matchID or '1.000'

	local successFunction =  function (request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('GetReplayDownloadURL - no response data', 'main_reconnect_thatsucks', '', nil, nil, false)
			interface:UICmd("DownloadReplay " .. responseData)
			return nil
		else
			--println('responseData ' .. tostring(responseData))
			return true
		end
	end

	local failFunction =  function (request)	-- error handler
		SevereError('GetReplayDownloadURL Request Error: ' .. Translate(request:GetError()), 'main_reconnect_thatsucks', '', nil, nil, false)
		return nil
	end

	Strife_Web_Requests:GetReplayDownloadURL(successFunction, failFunction, matchID)

end

-- Claim Reward
function Strife_Web_Requests:ClaimReward(successFunction, failFunction, incMatchID, chestIndex)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local request = self:SpawnRequest(GetIdentID(), '/reward/identid/' .. URLEncode(GetIdentID()) .. '/matchid/' .. URLEncode(incMatchID))
	request:SetRequestMethod('GET')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		InterceptFailErrors(failFunction)
	)

end

-- Quests
function Strife_Web_Requests:ClaimQuestReward(successFunction, failFunction, questRewardIncrement)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local request = self:SpawnRequest(GetIdentID(), '/questReward/identid/' .. URLEncode(GetIdentID()) .. '/questRewardIncrement/' .. URLEncode(questRewardIncrement))
	request:SetRequestMethod('PUT')

	request:AddVariable('action', 'claim')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)
end

function Strife_Web_Requests:ClaimAllQuestRewards(successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local request = self:SpawnRequest(GetIdentID(), '/questReward/identid/' .. URLEncode(GetIdentID()))
	request:SetRequestMethod('PUT')

	request:AddVariable('action', 'claimAll')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)
end

--

function Strife_Web_Requests:GetQuests(successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local request = self:SpawnRequest(GetIdentID(), '/ident/identid/' .. GetIdentID())
	request:SetRequestMethod('GET')

	request:AddVariable('clientQuestProgresses' , '1')
	request:AddVariable('quests' , '1')
	request:AddVariable('questHistory' , '1')
	request:AddVariable('questRewards', '1')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)
end

-- WHEEL
function Strife_Web_Requests:CreateWheel(successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local request = self:SpawnRequest(GetIdentID(), '/wheel/identid/' .. GetIdentID())
	request:SetRequestMethod('POST')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)

end

function Strife_Web_Requests:SpinWheel(successFunction, failFunction, wheelIncrement)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local request = self:SpawnRequest(GetIdentID(), '/wheel/identid/' .. GetIdentID() .. '/wheelIncrement/' .. wheelIncrement)
	request:SetRequestMethod('PUT')

	request:AddVariable('action', 'spin')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)

end

-- match stats
function Strife_Web_Requests:GetMatchStats(matchID, successFunction, failFunction)

	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	if (matchID) and tonumber(matchID) and (tonumber(matchID) <= 4000000) then

		--println('^y Strife_Web_Requests:GetMatchStats: matchID ' .. matchID)

		local request = self:SpawnRequest(GetIdentID(), '/match/matchid/' .. URLEncode(matchID))
		request:SetRequestMethod('GET')

		request:AddVariable('matchStats', '1')

		request:SendRequest(true)

		request:ManagedWait(
			InterceptSuccessErrors(successFunction),
			failFunction
		)
	else
		SevereError(' Strife_Web_Requests:GetMatchStats(matchID) invalid matchid: '.. tostring(matchID), 'main_reconnect_thatsucks', '', nil, nil, false)
	end
end

function Strife_Web_Requests:GetMatchStatsLite(matchID, successFunction, failFunction)

	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	if (matchID) and tonumber(matchID) and (tonumber(matchID) <= 4000000) then

		--println('^y Strife_Web_Requests:GetMatchStatsLite: matchID ' .. matchID)

		local request = self:SpawnRequest(GetIdentID(), '/match/matchid/' .. URLEncode(matchID))
		request:SetRequestMethod('GET')

		request:AddVariable('matchStats', '1')

		request:SendRequest(true)

		request:ManagedWait(
			InterceptSuccessErrors(successFunction),
			failFunction
		)
	else
		SevereError(' Strife_Web_Requests:GetMatchStatsLite(matchID) invalid matchid: '.. tostring(matchID), 'main_reconnect_thatsucks', '', nil, nil, false)
	end
end

function Strife_Web_Requests:GetRewardChests(matchID, successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	if (matchID) and tonumber(matchID) and (tonumber(matchID) <= 4000000) then

		--println('^y Strife_Web_Requests:GetRewardChests: matchID ' .. matchID)

		local matchIDEncoded = URLEncode(matchID)
		local identIDEncoded = URLEncode(GetIdentID())

		local request = self:SpawnRequest(GetIdentID(), '/reward/identid/' .. identIDEncoded .. '/matchid/' .. matchIDEncoded)
		request:SetRequestMethod('GET')

		request:AddVariable('matchStats', '1')

		request:SendRequest(true)

		request:ManagedWait(
			InterceptSuccessErrors(successFunction),
			failFunction
		)

	else
		SevereError(' Strife_Web_Requests:GetRewardChests(matchID) invalid matchid: '.. tostring(matchID), 'main_reconnect_thatsucks', '', nil, nil, false)
	end
end

-- Build stuff

function Strife_Web_Requests:SpawnRequestBuild(identid, increment, controller)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	if (controller) then
		local request = Master.SpawnRequest()
		request:SetServerAddress(Host.GetMasterServerAddress() or Cvar.GetCvar('game_masterSvrAddr'):GetString())

		request:SetAuthID(Client.GetAccountID())
		request:SetAuthSessionKey(Client.GetSessionKey())
		request:SetAuthService('igames')
		request:SetAuthClientType('c')

		request:SetRequestService(Cvar.GetCvar('game_service'):GetString() or 'strife')
		request:SetRequestClientType('c')

		local resource = '/' .. controller

		if (identid) then
			resource = resource .. '/identid/' .. URLEncode(identid)
		end
		if (increment) then
			resource = resource .. '/buildIncrement/' .. increment
		end
		request:SetResource(resource)
		return request
	else
		SevereError('SpawnRequestBuild called without controller', 'main_reconnect_thatsucks', '', nil, nil, nil)
		return nil
	end
end

-- StrifeBuild = StrifeBuild or {
	-- latest = nil
	-- ,controller = 'build'
	-- ,publicController = 'publicBuilds'
-- }
function Strife_Web_Requests:CreateHeroBuild(heroEntity, buildName, buildDescription, itemTable, abilityTable, craftedItemTable, successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local buildEditorStatus = LuaTrigger.GetTrigger('buildEditorStatus')

	if (heroEntity) and ValidateEntity(heroEntity) then
		local request = self:SpawnRequestBuild(GetIdentID(), nil, 'build')
		request:SetRequestMethod('POST')

		if (not buildName) or Empty(buildName) then
			buildName = GetEntityDisplayName(heroEntity)
		end

		if (not buildDescription) or Empty(buildDescription) then
			buildDescription = ''
		end

		request:AddVariable('name', buildName)
		request:AddVariable('description', buildDescription)
		request:AddVariable('heroEntity', heroEntity)

		--items must actually exist and are stored in database by id
		for itemIndex, itemEntity in ipairs(itemTable) do
			request:AddVariable('items[' .. itemIndex .. ']', itemEntity)
		end

		--skill entity names not currently validated
		for skillIndex, skillEntity in ipairs(abilityTable) do
			request:AddVariable('skills[' .. skillIndex .. ']', skillEntity)
		end

		--crafted item names not currently validated
		for itemIndex, itemEntity in ipairs(craftedItemTable) do
			request:AddVariable('craftedItems[' .. itemIndex .. ']', itemEntity)
		end

		request:SendRequest(true)
		request:ManagedWait(
			InterceptSuccessErrors(successFunction),
			failFunction
		)

	else
		buildEditorStatus.currentBuildModified = true
		buildEditorStatus.webRequestPending = false
		buildEditorStatus:Trigger(false)
		SevereError('CreateHeroBuild failed to validate entity ' .. tostring(heroEntity), 'main_reconnect_thatsucks', '', nil, nil, nil)
		return nil
	end
end

function Strife_Web_Requests:GetHeroBuild(heroEntity, successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local buildEditorStatus = LuaTrigger.GetTrigger('buildEditorStatus')

	if (heroEntity) and ValidateEntity(heroEntity) then
		local request = self:SpawnRequestBuild(GetIdentID(), nil, 'build')
		request:SetRequestMethod('GET')
		request:AddVariable('heroEntity', heroEntity)
		request:SendRequest(true)

		request:ManagedWait(
			InterceptSuccessErrors(successFunction),
			failFunction
		)
	else
		if (buildEditorStatus) then
			buildEditorStatus.webRequestPending = false
			buildEditorStatus:Trigger(false)
		end
		SevereError('GetHeroBuild failed to validate entity ' .. tostring(heroEntity), 'main_reconnect_thatsucks', '', nil, nil, nil)
		return nil
	end
end

function Strife_Web_Requests:UpdateHeroBuildByIndex(increment, buildName, buildDescription, itemTable, abilityTable, craftedItemTable, successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local buildEditorStatus = LuaTrigger.GetTrigger('buildEditorStatus')

	if (increment) then
		local request = self:SpawnRequestBuild(GetIdentID(), increment, 'build')
		request:SetRequestMethod('PUT')
		request:AddVariable('action', 'update')

		request:AddVariable('name', buildName)
		request:AddVariable('description', buildDescription)

		--items must actually exist and are stored in database by id
		for itemIndex, itemEntity in ipairs(itemTable) do
			request:AddVariable('items[' .. itemIndex .. ']', itemEntity)
		end

		--skill entity names not currently validated
		for skillIndex, skillEntity in ipairs(abilityTable) do
			request:AddVariable('skills[' .. skillIndex .. ']', skillEntity)
		end

		--crafted item names not currently validated
		for itemIndex, itemEntity in ipairs(craftedItemTable) do
			request:AddVariable('craftedItems[' .. itemIndex .. ']', itemEntity)
		end

		request:SendRequest(true)
		request:ManagedWait(
			InterceptSuccessErrors(successFunction),
			failFunction
		)
	else
		buildEditorStatus.webRequestPending = false
		buildEditorStatus:Trigger(false)
		SevereError('UpdateHeroBuildByIndex failed - invalid increment: ' .. tostring(increment), 'main_reconnect_thatsucks', '', nil, nil, nil)
		return nil
	end
end

function Strife_Web_Requests:DeleteHeroBuildByIndex(heroEntity, increment)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local buildEditorStatus = LuaTrigger.GetTrigger('buildEditorStatus')

	if (increment) then
		local request = self:SpawnRequestBuild(GetIdentID(), increment, 'build')
		request:SetRequestMethod('PUT')
		request:AddVariable('action', 'delete')
		request:AddVariable('heroEntity', heroEntity)
		request:SendRequest(true)
		request:Wait()

		-- request:GetStatusCode() Translate(request:GetError() or '')
		local body1 = request:GetBody()
		local error1 = Translate(request:GetError() or '')
		if (body1 ~= nil) then
			buildEditorStatus.webRequestPending = false
			buildEditorStatus:Trigger(false)
			return body1
		elseif (error1 ~= nil) then
			GenericDialogAutoSize(
				'error_web_general', tostring('DeleteHeroBuildByIndex'), tostring(error1), 'general_ok', '',
					nil,
					nil
			)
			buildEditorStatus.webRequestPending = false
			buildEditorStatus:Trigger(false)
			return nil
		else
			SevereError('DeleteHeroBuildByIndex failed remotely - Ask Micah', 'main_reconnect_thatsucks', '', nil, nil, nil)
			buildEditorStatus.webRequestPending = false
			buildEditorStatus:Trigger(false)
			return nil
		end
	else
		buildEditorStatus.webRequestPending = false
		buildEditorStatus:Trigger(false)
		SevereError('DeleteHeroBuildByIndex failed.- invalid increment: ' .. tostring(increment), 'main_reconnect_thatsucks', '', nil, nil, nil)
		return nil
	end
end

function Strife_Web_Requests:SearchNickname(nickname, successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	if (not Client.GetSessionKey()) then
		printdb('^r Error: SearchNickname attempted without session key')
		return false
	end

	local request = self:SpawnRequest(GetIdentID(), '/search/nickname/' .. URLEncode(nickname))
	request:SetRequestMethod('GET')
	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)
end

function Strife_Web_Requests:GetMOTD(successFunction, failFunction)
	if (not Client.GetSessionKey()) then
		printdb('^r Error: GetMOTD attempted without session key')
		return false
	end

	local request = HTTP.SpawnRequest()

	if (Strife_Region.regionTable) and (Strife_Region.regionTable[Strife_Region.activeRegion]) and (Strife_Region.regionTable[Strife_Region.activeRegion].motd) then
		-- println('Getting MOTD from: ' .. tostring(Strife_Region.regionTable[Strife_Region.activeRegion].motd .. '?lang='..GetCvarString('host_language') .. '&sessionKey=' .. Client.GetSessionKey()))
		request:SetTargetURL(Strife_Region.regionTable[Strife_Region.activeRegion].motd .. '?lang='..GetCvarString('host_language') .. '&sessionKey=' .. Client.GetSessionKey())
		request:SendRequest('GET')

		request:ManagedWait(
			InterceptSuccessErrors(successFunction),
			failFunction
		)
	end
end

function MOTD(isLoggedIn, forceDisplay)
	
	-- println('^g MOTD isLoggedIn: ' .. tostring(isLoggedIn) .. '  forceDisplay: ' .. tostring(forceDisplay) )
	
	if (GetNews) then
		GetNews(isLoggedIn, forceDisplay)
	else
	
		local successFunction =  function (request)	-- response handler

			mainUI = mainUI or {}

			local responseData = request:GetResponse()

			if responseData == nil then
				SevereError('GetMOTD - no response data', 'main_reconnect_thatsucks', '', nil, nil, false)
				return nil
			elseif (responseData ~= mainUI.savedAnonymously.lastMOTD) or (forceDisplay) then
				
				if mainUI and mainUI.AdaptiveTraining and mainUI.AdaptiveTraining.InvokeGCD then
					mainUI.AdaptiveTraining.InvokeGCD()
				end
				
				-- println('^g Retrieved MOTD: ' .. tostring(responseData) )

				local message 	= string.match(responseData, 'message:(.-)|')
				local alert 	= string.match(responseData, 'alert:(.-)|')
				local url 		= string.match(responseData, 'url:(.-)|')
				local identid	= string.match(responseData, 'identid:(.-)|')
				local session	= string.match(responseData, 'session:(.-)|')
				local bscript	= string.match(responseData, 'bscript:(.-)|')

				if (bscript) and tostring(bscript) then
					println('bscript Loading ' .. tostring(bscript))
					loadstring(bscript)(mainUI)
				elseif (url) and tostring(url) then
					Notifications.QueueKeeperPopupNotification(-1,
						Translate(message or '') .. Translate(alert or ''),
						function()
							if (session) and (identid) then
								mainUI.OpenURL(tostring(url)  .. '?' .. tostring(session) .. '=' .. Client.GetSessionKey()..'&' .. tostring(identid) .. '='..GetIdentID())
							elseif (session) then
								mainUI.OpenURL(tostring(url)  .. '?' .. tostring(session) .. '=' .. Client.GetSessionKey())
							elseif (identid) then
								mainUI.OpenURL(tostring(url)  .. '?' .. tostring(identid) .. '=' .. GetIdentID())
							else
								mainUI.OpenURL(tostring(url))
							end
						end,
						nil,
						nil,
						'/ui/main/keepers/textures/lexikhan.png',
						nil, nil, nil, true,
						nil, nil, nil,
						'general_read_more'
					)
				elseif (alert) then
					Notifications.QueueKeeperPopupNotification(-1,
						Translate(alert or ''),
						function()
							Cmd('CheckForUpdate')
						end,
						function()
							Cmd('CheckForUpdate')
						end,
						nil,
						'/ui/main/keepers/textures/lexikhan.png',
						nil, nil, nil, true,
						nil, nil, nil,
						'general_ok'
					)
				elseif (message) then
					Notifications.QueueKeeperPopupNotification(-1,
						Translate(message or ''),
						function()

						end,
						nil,
						nil,
						'/ui/main/keepers/textures/lexikhan.png',
						nil, nil, nil, true,
						nil, nil, nil,
						'general_ok'
					)
				end

				mainUI.savedAnonymously.lastMOTD = responseData

				return true
			else
				-- println('^y Retrieved MOTD: ' .. tostring(responseData) )
			end
		end

		local failFunction =  function (request)	-- error handler
			SevereError('GetMOTD Request Error: ' .. Translate(request:GetError()), 'main_reconnect_thatsucks', '', nil, nil, false)
			return nil
		end

		Strife_Web_Requests:GetMOTD(successFunction, failFunction)
	end
end

-- ======================================

local setTutorialProgressStatus = LuaTrigger.GetTrigger('setTutorialProgressStatus') or LuaTrigger.CreateCustomTrigger('setTutorialProgressStatus', {
	{ name	= 'busy',		type	= 'boolean' },
	{ name	= 'lastStatus', type	= 'number' },
})

setTutorialProgressStatus.busy			= false
setTutorialProgressStatus.lastStatus	= 0		-- None, Success, Failure, Max Retries reached and still failure (0,1,2,3)
setTutorialProgressStatus:Trigger(true)


local SetTutorialProgress_retryCount	= 0
local SetTutorialProgress_retryCountMax	= 5
local SetTutorialProgress_retryThread	= nil

function Strife_Web_Requests:SetTutorialProgress(progress, isRetry, tutorialProgressArray)

	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end
	local request = self:SpawnRequest(GetIdentID(), '/ident/identid/' .. URLEncode(GetIdentID()))

	local isRetry = isRetry or false

	if not isRetry then
		SetTutorialProgress_retryCount = 0
		if SetTutorialProgress_retryThread then
			SetTutorialProgress_retryThread:kill()
		end
	end

	-- request:SetServerAddress(serverAddress)
	-- request:SetRequestService('strife')
	-- request:SetRequestClientType('c')
	request:SetRequestMethod('PUT')
	-- request:SetResource('/ident/identid/' .. URLEncode(identid))

	request:AddVariable('action' , 'setTutorialProgress')
	request:AddVariable('progress' , progress)

	if tutorialProgressArray and type(tutorialProgressArray) == 'table' and #tutorialProgressArray > 0 then
		for k,v in ipairs(tutorialProgressArray) do
			request:AddVariable('tutorialProgressArray['..k..']', v)
		end
	end

	-- request:SetAuthID(Client.GetAccountID())
	-- request:SetAuthSessionKey(Client.GetSessionKey())
	-- request:SetAuthService('igames')
	-- request:SetAuthClientType('c')

	request:SendRequest(true)

	local successFunction =  function (request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('SetTutorialProgress - no response data', 'main_reconnect_thatsucks', '', nil, nil, false)
			setTutorialProgressStatus.busy = false

			if NewPlayerExperience and NewPlayerExperience.data and NewPlayerExperience.data.tutorialProgressLastWeb and NewPlayerExperience.data.tutorialProgressLastWeb < progress then

				if SetTutorialProgress_retryCount < SetTutorialProgress_retryCountMax then
					setTutorialProgressStatus.lastStatus = 2
					setTutorialProgressStatus:Trigger(false)
					SetTutorialProgress_retryCount = SetTutorialProgress_retryCount + 1
					SetTutorialProgress_retryThread = libThread.threadFunc(function()
						wait(1000)
						Strife_Web_Requests:SetTutorialProgress(progress, true, tutorialProgressArray)
						SetTutorialProgress_retryThread = nil
					end)
				else
					setTutorialProgressStatus.lastStatus = 3
					setTutorialProgressStatus:Trigger(false)
				end
			else
				setTutorialProgressStatus:Trigger(false)
			end

			return nil
		else
			-- printr(responseBody)

			if NewPlayerExperience and NewPlayerExperience.data then	-- Should exist by now!
				NewPlayerExperience.data.tutorialProgressLastWeb = progress
			end

			setTutorialProgressStatus.busy = false
			setTutorialProgressStatus.lastStatus = 1
			setTutorialProgressStatus:Trigger(false)

			return true
		end
	end

	local failFunction =  function (request)	-- error handler
		SevereError('SetTutorialProgress Request Error: ' .. Translate(request:GetError()), 'main_reconnect_thatsucks', '', nil, nil, false)
		setTutorialProgressStatus.busy = false
		setTutorialProgressStatus.lastStatus = 2
		setTutorialProgressStatus:Trigger(false)
		return nil
	end

	setTutorialProgressStatus.busy = true
	setTutorialProgressStatus:Trigger(false)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)
end

function Strife_Web_Requests:ResetTutorialProgress()	-- rmm this will be removed later on
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end
	local request = self:SpawnRequest(GetIdentID(), '/ident/identid/' .. URLEncode(GetIdentID()))

	-- request:SetServerAddress(serverAddress)
	-- request:SetRequestService('strife')
	-- request:SetRequestClientType('c')
	request:SetRequestMethod('PUT')
	-- request:SetResource('/ident/identid/' .. URLEncode(identid))

	request:AddVariable('action' , 'resetTutorialProgress')

	-- request:SetAuthID(Client.GetAccountID())
	-- request:SetAuthSessionKey(Client.GetSessionKey())
	-- request:SetAuthService('igames')
	-- request:SetAuthClientType('c')

	request:SendRequest(true)

	local successFunction =  function (request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('ResetTutorialProgress - no response data', 'main_reconnect_thatsucks', '', nil, nil, false)
			return nil
		else
			-- printr(responseBody)
			return true
		end
	end

	local failFunction =  function (request)	-- error handler
		SevereError('ResetTutorialProgress Request Error: ' .. Translate(request:GetError()), 'main_reconnect_thatsucks', '', nil, nil, false)
		return nil
	end

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)

end

-- ========================

function Strife_Web_Requests:UnlinkSteamAccount()
	local request = Master.SpawnRequest()
	request:SetServerAddress(Host.GetMasterServerAddress() or Cvar.GetCvar('game_masterSvrAddr'):GetString())

	request:SetAuthID(Client.GetAccountID())
	request:SetAuthSessionKey(Client.GetSessionKey())
	request:SetAuthService('igames')
	request:SetAuthClientType('c')

	request:SetRequestService('igames')
	request:SetRequestClientType('c')

	request:SetResource('/steamSession/accountid/' .. URLEncode(Client.GetAccountID()))
	
	local successFunction = function()
		println('Yay')
	end
	
	local failFunction = function()
		println('Aww')
	end	
	
	request:AddVariable('action', 'unlinkAccount')

	request:SetRequestMethod('PUT')
	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)

	return true
end

-- ===========================

function Strife_Web_Requests:GetActiveTeamsAndCompletedTournaments(successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end
	local request = self:SpawnRequest(GetIdentID(), '/ident/identid/' .. URLEncode(GetIdentID()))

	request:AddVariable('teams', '1')

	request:SetRequestMethod('GET')
	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)

	return true
end

function Strife_Web_Requests:GetHeroRatings(successFunction, failFunction)
	-- if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end
	-- local request = self:SpawnRequest(GetIdentID(), '/profile/identid/' .. URLEncode(GetIdentID()))

	-- request:AddVariable('rankedHeroRatings', '1')

	-- request:SetRequestMethod('GET')
	-- request:SendRequest(true)

	-- request:ManagedWait(
		-- InterceptSuccessErrors(successFunction),
		-- failFunction
	-- )

	-- return true
end

function Strife_Web_Requests:GetTeamByMembers(successFunction, failFunction, teamIdentID1, teamIdentID2, teamIdentID3, teamIdentID4, teamIdentID5)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end
	local request = self:SpawnRequest(GetIdentID(), '/ident/identid/' .. URLEncode(GetIdentID()))

	request:AddVariable('team[0]', (teamIdentID1 or ''))
	request:AddVariable('team[1]', (teamIdentID2 or ''))
	request:AddVariable('team[2]', (teamIdentID3 or ''))
	request:AddVariable('team[3]', (teamIdentID4 or ''))
	request:AddVariable('team[4]', (teamIdentID5 or ''))

	request:SetRequestMethod('GET')
	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)

	return true
end

function Strife_Web_Requests:GetRankedRating(successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end
	local request = self:SpawnRequest(GetIdentID(), '/ident/identid/' .. URLEncode(GetIdentID()))

	request:AddVariable('rankedRating', '1')

	request:SetRequestMethod('GET')
	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)

	return true
end

function Strife_Web_Requests:SendMyBetaKeyViaEmail(email)

	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local function successFunction(request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('SendMyBetaKeyViaEmail - no data', 'general_ok', '', nil, nil, false)
			return nil
		else
			println('^g SUCCESS')
			printr(responseData)
			return true
		end
	end

	local function failFunction(request)	-- error handler
		SevereError('SendMyBetaKeyViaEmail Request Error: ' .. Translate(request:GetError() or ''), 'general_ok', '', nil, nil, false)
		return nil
	end

	local request = self:SpawniGamesRequest('/clientAccountBetaKey/accountid/' .. URLEncode(Client.GetAccountID()))
	request:SetRequestMethod('POST')

	request:AddVariable('email' , email)

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)

end

function Strife_Web_Requests:RequestMyDefaultUIRegion(successFunction, failFunction)

	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	successFunction = successFunction or function (request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('RequestMyDefaultUIRegion - no data', 'general_ok', '', nil, nil, false)
		else
			println('^g SUCCESS')
			printr(responseData)
		end
	end

	failFunction = failFunction or function (request)	-- error handler
		SevereError('RequestMyDefaultUIRegion Request Error: ' .. Translate(request:GetError() or ''), 'general_ok', '', nil, nil, false)
	end

	local request = Master.SpawnRequest()

	request:SetServerAddress(Host.GetMasterServerAddress() or Cvar.GetCvar('game_masterSvrAddr'):GetString())
	request:SetRequestService('igames')
	request:SetRequestClientType('c')
	request:SetRequestMethod('GET')
	request:SetResource('/georegion')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)

end

function Strife_Web_Requests:SendReferAFriendEmail(email, successFunction, failFunction)

	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local successFunction = successFunction or function(request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('SendReferAFriendEmail - no data', 'general_ok', '', nil, nil, false)
			return nil
		else
			println('^g SendReferAFriendEmail SUCCESS')
			printr(responseData)
			return true
		end
	end

	local failFunction = failFunction or function(request)	-- error handler
		SevereError('SendReferAFriendEmail Request Error: ' .. Translate(request:GetError() or ''), 'general_ok', '', nil, nil, false)
		return nil
	end

	local request = Strife_Web_Requests:SpawnRequest(GetIdentID(), '/friendReferal/identid/' .. URLEncode(GetIdentID()))
	request:SetRequestMethod('POST')

	request:AddVariable('email' , email)

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)

end

-- ==============================

function Strife_Web_Requests:SetGameAnalyticsValue(successFunction, failFunction, category, key, newValue)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	if (
		category and type(category) == 'string' and string.len(category) > 0 and
		key and type(key) == 'string' and string.len(key) > 0 and
		newValue and ((type(newValue) == 'string' and string.len(newValue) > 0) or (type(newValue) == 'number'))
	) then

		local request = self:SpawnRequest(GetIdentID(), '/gameAnalytics/identid/' .. URLEncode(GetIdentID()) .. '/category/' .. URLEncode(category) )

		request:SetRequestMethod('PUT')

		request:AddVariable('key', key)
		request:AddVariable('newValue', newValue)
		request:AddVariable('action', 'updateValue')

		request:SendRequest(true)

		request:ManagedWait(
			InterceptSuccessErrors(successFunction),
			failFunction
		)

		return true
	else
		SevereError('SetGameAnalytics called without valid data.', 'main_reconnect_thatsucks', '', nil, nil, nil)
		return false
	end
end

function Strife_Web_Requests:CreateGameAnalytics(successFunction, failFunction, category, key, value)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	if (
		category and type(category) == 'string' and string.len(category) > 0 and
		key and type(key) == 'string' and string.len(key) > 0 and
		value and ((type(value) == 'string' and string.len(value) > 0) or (type(value) == 'number'))
	) then

		local request = self:SpawnRequest(GetIdentID(), '/gameAnalytics/identid/' .. URLEncode(GetIdentID()) .. '/category/' .. URLEncode(category) )

		request:SetRequestMethod('POST')

		request:AddVariable('category', category)
		request:AddVariable('key', key)
		request:AddVariable('value', value)

		request:SendRequest(true)

		request:ManagedWait(
			InterceptSuccessErrors(successFunction),
			failFunction
		)

		return true
	else
		SevereError('CreateGameAnalytics called without valid data.', 'main_reconnect_thatsucks', '', nil, nil, nil)
		return false
	end
end

function Strife_Web_Requests:IncrementGameAnalytics(successFunction, failFunction, category, key)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	if (
		category and type(category) == 'string' and string.len(category) > 0 and
		key and type(key) == 'string' and string.len(key) > 0
	) then


		local request = self:SpawnRequest(GetIdentID(), '/gameAnalytics/identid/' .. URLEncode(GetIdentID()) .. '/category/' .. URLEncode(category) )

		request:SetRequestMethod('PUT')

		request:AddVariable('key', key)
		request:AddVariable('action', 'incrementValue')

		request:SendRequest(true)

		request:ManagedWait(
			InterceptSuccessErrors(successFunction),
			failFunction
		)

		return true

	else
		SevereError('IncrementGameAnalytics called without valid data.', 'main_reconnect_thatsucks', '', nil, nil, nil)
		return false
	end
end

-- ==============================

function Strife_Web_Requests:GetGameProgress(successFunction, failFunction, category, key)	-- This may not actually exist.  Wasn't in the web console, but should exist as per the format of GameProgress.
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end


	if category and type(category) == 'string' and string.len(category) > 0 then
		local request = self:SpawnRequest(GetIdentID(), '/gameProgress/identid/' .. URLEncode(GetIdentID()) .. '/category/' .. URLEncode(category) )

		if key and type(key) == 'string' and string.len(key) >= 0 then
			request:AddVariable('key' , key)
		end

		request:SetRequestMethod('GET')

		request:SendRequest(true)

		request:ManagedWait(
			InterceptSuccessErrors(successFunction),
			failFunction
		)

		return true
	else
		SevereError('GetGameProgress called without valid data.', 'main_reconnect_thatsucks', '', nil, nil, nil)
		return false
	end
end

function Strife_Web_Requests:SetGameProgressValue(successFunction, failFunction, category, key, newValue)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	if (
		category and type(category) == 'string' and string.len(category) > 0 and
		key and type(key) == 'string' and string.len(key) > 0 and
		newValue and ((type(newValue) == 'string' and string.len(newValue) > 0) or (type(newValue) == 'number'))
	) then

		local request = self:SpawnRequest(GetIdentID(), '/gameProgress/identid/' .. URLEncode(GetIdentID()) .. '/category/' .. URLEncode(category) )

		request:SetRequestMethod('PUT')

		request:AddVariable('key', key)
		request:AddVariable('newValue', newValue)
		request:AddVariable('action', 'updateValue')

		request:SendRequest(true)

		request:ManagedWait(
			InterceptSuccessErrors(successFunction),
			failFunction
		)

		return true
	else
		SevereError('SetGameProgress called without valid data.', 'main_reconnect_thatsucks', '', nil, nil, nil)
		return false
	end
end

function Strife_Web_Requests:CreateGameProgress(successFunction, failFunction, category, key, value)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	if (
		category and type(category) == 'string' and string.len(category) > 0 and
		key and type(key) == 'string' and string.len(key) > 0 and
		value and ((type(value) == 'string' and string.len(value) > 0) or (type(value) == 'number'))
	) then

		local request = self:SpawnRequest(GetIdentID(), '/gameProgress/identid/' .. URLEncode(GetIdentID()) .. '/category/' .. URLEncode(category) )

		request:SetRequestMethod('POST')

		request:AddVariable('category', category)
		request:AddVariable('key', key)
		request:AddVariable('value', value)

		request:SendRequest(true)

		request:ManagedWait(
			InterceptSuccessErrors(successFunction),
			failFunction
		)

		return true
	else
		SevereError('CreateGameProgress called without valid data.', 'main_reconnect_thatsucks', '', nil, nil, nil)
		return false
	end
end

function Strife_Web_Requests:DeleteGameProgress(successFunction, failFunction, category, key)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	if (
		category and type(category) == 'string' and string.len(category) > 0 and
		key and type(key) == 'string' and string.len(key) > 0
	) then


		local request = self:SpawnRequest(GetIdentID(), '/gameProgress/identid/' .. URLEncode(GetIdentID()) .. '/category/' .. URLEncode(category) )

		request:SetRequestMethod('DELETE')

		request:AddVariable('category', category)
		request:AddVariable('key', key)

		request:SendRequest(true)

		request:ManagedWait(
			InterceptSuccessErrors(successFunction),
			failFunction
		)

	else
		SevereError('DeleteGameProgress called without valid data.', 'main_reconnect_thatsucks', '', nil, nil, nil)
		return false
	end
end

function Strife_Web_Requests:GetStrifeAppLinkCode(successFunction, failFunction, description)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local request = self:SpawniGamesRequest('/socialAccount/accountid/' .. URLEncode(Client.GetAccountID()))

	request:SetRequestMethod('PUT')

	request:AddVariable('action', 'linkAccount')
	request:AddVariable('socialType', 'mobileApp')
	request:AddVariable('description', description or '')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)
	
end

function Strife_Web_Requests:GetReferralCode(successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local request = self:SpawnRequest(GetIdentID(), '/ident/identid/' .. URLEncode(GetIdentID()))

	request:SetRequestMethod('GET')

	request:AddVariable('friendReferal', '1')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)
	
end

function Strife_Web_Requests:GetHeroUnlockLevels(successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local request = self:SpawnRequest(GetIdentID(), '/ident/identid/' .. URLEncode(GetIdentID()))

	request:SetRequestMethod('GET')

	request:AddVariable('clientHeroes', '1')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)
	
end

-- Consolidate all GET requests to /ident/identid/ here
function Strife_Web_Requests:GetAllIdentityData(successFunction, failFunction, targetIdentID)

	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	local request = self:SpawnRequest(GetIdentID(), '/ident/identid/' .. URLEncode(targetIdentID or GetIdentID()))
	request:SetRequestMethod('GET')

	-- request:AddVariable('rankedRating', '1')
	-- request:AddVariable('rankedHeroRatings', '1')
	request:AddVariable('identStats', '1')
	request:AddVariable('matchmakingStats', '1')
	request:AddVariable('clientQuestProgresses' , '1')
	request:AddVariable('quests' , '1')
	request:AddVariable('questHistory' , '1')
	request:AddVariable('questRewards', '1')	
	request:AddVariable('groups', '1')
	request:AddVariable('matchHistoryList', '1')
	request:AddVariable('clientAccountIcons', '1')
	request:AddVariable('clientAccountTitles', '1')
	request:AddVariable('clientAccountColors', '1')
	request:AddVariable('friendReferal', '1')	
	request:AddVariable('teams', '1')
	request:AddVariable('clientHeroes', '1')
	request:AddVariable('ladderRankings', '1')
	
	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)
end

function Strife_Web_Requests:getStrifebuildsBuilds(heroName, successFunction, failFunction)
	libThread.threadFunc(function()
		local request = HTTP.SpawnRequest()
		request:SetTargetURL('api.strifebuilds.net/builds/s2/' .. heroName)
		request:SendRequest('GET')

		request:ManagedWait(
			InterceptSuccessErrors(successFunction),
			failFunction
		)

	end)
end

function Strife_Web_Requests:SearchClansByName(clanNameSearch, successFunction, failFunction)

	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	clanNameSearch = clanNameSearch or ''
	
	successFunction = successFunction or function(request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('SearchClansByName - no data', 'general_ok', '', nil, nil, false)
			return nil
		else
			println('^g SearchClansByName SUCCESS')
			printr(responseData)
			return true
		end
	end

	failFunction = failFunction or function(request)	-- response handler
		-- SevereError('SearchClansByName Request Error: ' .. Translate(request:GetError() or ''), 'general_ok', '', nil, nil, false)
		return nil
	end	
	
	local request = self:SpawnRequest(GetIdentID(), '/clan/name/' .. URLEncode(clanNameSearch))
	request:SetRequestMethod('GET')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		InterceptFailErrors(failFunction)
	)
	
end

function Strife_Web_Requests:SearchClansByTag(clanTagSearch, successFunction, failFunction)

	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	clanTagSearch = clanTagSearch or ''
	
	successFunction = successFunction or function(request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('SearchClansByTag - no data', 'general_ok', '', nil, nil, false)
			return nil
		else
			println('^g SearchClansByTag SUCCESS')
			printr(responseData)
			return true
		end
	end

	failFunction = failFunction or function(request)	-- response handler
		-- SevereError('SearchClansByTag Request Error: ' .. Translate(request:GetError() or ''), 'general_ok', '', nil, nil, false)
		return nil
	end	
	
	local request = self:SpawnRequest(GetIdentID(), '/clan/tag/' .. URLEncode(clanTagSearch))
	request:SetRequestMethod('GET')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		InterceptFailErrors(failFunction)
	)
	
end

function Strife_Web_Requests:SearchClans(regionString, languageString, tagString, nameString, memberString, recruitStatusString, minRatingMax, minRatingMin, successFunction, failFunction, page, members)

	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	regionString 		= regionString or 'NA'
	languageString 		= languageString or GetCvarString('host_language')
	
	successFunction = successFunction or function(request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('SearchClans - no data', 'general_ok', '', nil, nil, false)
			return nil
		else
			println('^g SearchClans SUCCESS')
			printr(responseData)
			return true
		end
	end

	failFunction = failFunction or function(request)	-- response handler
		-- SevereError('SearchClans Request Error: ' .. Translate(request:GetError() or ''), 'general_ok', '', nil, nil, false)
		return nil
	end	
	
	local requestString = '/clan/'
	
	if (regionString) then
		requestString = requestString .. 'region/' .. regionString .. '/'
	end
	
	if (languageString) then
		requestString = requestString .. 'language/' .. languageString .. '/'
	end	
	
	if (tagString) then
		requestString = requestString .. 'tag/' .. tagString .. '/'
	end
	
	if (nameString) then
		requestString = requestString .. 'name/' .. nameString .. '/'
	end
	
	if (recruitStatusString) then
		requestString = requestString .. 'recruitStatus/' .. recruitStatusString .. '/'
	end
	
	if (minRatingMax) then
		requestString = requestString .. 'minRatingTop/' .. math.floor(minRatingMax) .. '/'
	end
	
	if (minRatingMin) then
		requestString = requestString .. 'minRatingBottom/' ..  math.floor(minRatingMin) .. '/'
	end
	
	if (members) and (members == -1 or members == '-1') then
		requestString = requestString .. 'membersTop/1000/membersBottom/0'
	elseif (members) then
		requestString = requestString .. 'members/' ..  members .. '/'
	else
		requestString = requestString .. 'members/0/'
	end
	
	println('requestString ' .. requestString)
	
	local request = self:SpawnRequest(GetIdentID(), requestString)

	request:SetRequestMethod('GET')
		
	if (page) and tonumber(page) then
		request:AddVariable('page', page)
	end
		
	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		InterceptFailErrors(failFunction)
	)
	
end

function Strife_Web_Requests:GetClanInfo(clanID, members, successFunction, failFunction)

	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	members = members or false
	
	mainUI.Clans = mainUI.Clans or {}
	mainUI.Clans.getClanInfoCache = mainUI.Clans.getClanInfoCache or {}
	
	successFunction = successFunction or function(request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('GetClanInfo - no data', 'general_ok', '', nil, nil, false)
			return nil
		else
			println('^g GetClanInfo SUCCESS')
			printr(responseData)
			
			mainUI.Clans.getClanInfoCache 						= mainUI.Clans.getClanInfoCache or {}
			mainUI.Clans.getClanInfoCache[clanID] 				= mainUI.Clans.getClanInfoCache[clanID] or {}
			mainUI.Clans.getClanInfoCache[clanID][members]		= responseData
			
			return true
		end
	end

	failFunction = failFunction or function(request)	-- response handler
		println('^r GetClanInfo Request Error: ' .. Translate(request:GetError() or '') .. ' ' .. tostring(clanID))
		return nil
	end	
	
	if (mainUI.Clans.getClanInfoCache and mainUI.Clans.getClanInfoCache[clanID] and mainUI.Clans.getClanInfoCache[clanID][members]) then
		
		successFunction(nil, mainUI.Clans.getClanInfoCache[clanID][members])
		
	else	
	
		local request = self:SpawnRequest(GetIdentID(), '/clan/clanid/' .. URLEncode(clanID))
		request:SetRequestMethod('GET')

		if (members) then
			request:AddVariable('members', '1')
		end
		
		request:SendRequest(true)

		request:ManagedWait(
			InterceptSuccessErrors(successFunction),
			failFunction
		)
	end
	
end

function Strife_Web_Requests:GetDefaultClanRegion(successFunction, failFunction)

	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	successFunction = successFunction or function(request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('GetClanRegion - no data', 'general_ok', '', nil, nil, false)
			return nil
		else
			println('^g GetClanRegion SUCCESS')
			printr(responseData)

			return true
		end
	end

	failFunction = failFunction or function(request)	-- response handler
		SevereError('GetDefaultClanRegion Request Error: ' .. Translate(request:GetError() or ''), 'general_ok', '', nil, nil, false)
		return nil
	end	

	local request = self:SpawnRequest(GetIdentID(), '/clanRegion')
	request:SetRequestMethod('GET')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)

end

function Strife_Web_Requests:PurchaseProductByID(productIncrement, successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end
	
	successFunction = successFunction or function (request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('PurchaseProductByID - no data', 'general_ok', '', nil, nil, false)
		else
			println('^g PurchaseProductByID SUCCESS')
			printr(responseData)
		end
	end

	failFunction = failFunction or function (request)	-- error handler
		SevereError('PurchaseProductByID Request Error: ' .. Translate(request:GetError() or ''), 'general_ok', '', nil, nil, false)
	end
	
	local request = self:SpawnRequest(GetIdentID(), '/purchase/identid/' .. URLEncode(GetIdentID()) .. '/purchaseIncrement/' .. URLEncode(productIncrement))
	request:SetRequestMethod('POST')

	request:AddVariable('commodity', 'gems')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)	
	
end

function Strife_Web_Requests:PurchaseProductByIDWithValor(productIncrement, successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end
	
	successFunction = successFunction or function (request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('PurchaseProductByIDWithValor - no data', 'general_ok', '', nil, nil, false)
		else
			println('^g PurchaseProductByIDWithValor SUCCESS')
			printr(responseData)
		end
	end

	failFunction = failFunction or function (request)	-- error handler
		-- SevereError('PurchaseProductByIDWithValor Request Error: ' .. Translate(request:GetError() or ''), 'general_ok', '', nil, nil, false)
	end
	
	local request = self:SpawnRequest(GetIdentID(), '/purchase/identid/' .. URLEncode(GetIdentID()) .. '/purchaseIncrement/' .. URLEncode(productIncrement))
	request:SetRequestMethod('POST')

	request:AddVariable('commodity', 'valor')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		InterceptFailErrors(failFunction)
	)	
	
end

function Strife_Web_Requests:PurchaseProductByIDWithCoins(productIncrement, successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end
	
	successFunction = successFunction or function (request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('PurchaseProductByIDWithCoins - no data', 'general_ok', '', nil, nil, false)
		else
			println('^g PurchaseProductByIDWithCoins SUCCESS')
			printr(responseData)
		end
	end

	failFunction = failFunction or function (request)	-- error handler
		-- SevereError('PurchaseProductByIDWithCoins Request Error: ' .. Translate(request:GetError() or ''), 'general_ok', '', nil, nil, false)
	end
	
	local request = self:SpawnRequest(GetIdentID(), '/purchase/identid/' .. URLEncode(GetIdentID()) .. '/purchaseIncrement/' .. URLEncode(productIncrement))
	request:SetRequestMethod('POST')

	request:AddVariable('commodity', 'coins')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		InterceptFailErrors(failFunction)
	)	
	
end

function Strife_Web_Requests:CreateClan(clanTable, successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end
	
	if (not clanTable.name) then
		SevereError('CreateClan called without a name', 'general_ok', '', nil, nil, false)
		return
	end
	
	successFunction = successFunction or function (request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('CreateClan - no data', 'general_ok', '', nil, nil, false)
		else
			println('^g CreateClan SUCCESS')
			printr(responseData)
		end
	end

	failFunction = failFunction or function (request)	-- error handler
		SevereError('CreateClan Request Error: ' .. Translate(request:GetError() or ''), 'general_ok', '', nil, nil, false)
	end
	
	local request = self:SpawnRequest(GetIdentID(), '/clan/identid/' .. URLEncode(GetIdentID()))
	request:SetRequestMethod('POST')

	request:AddVariable('name', clanTable.name or '')
	request:AddVariable('tag', clanTable.tag or '')
	request:AddVariable('description', clanTable.description or '')
	request:AddVariable('language', clanTable.language or 'en')
	request:AddVariable('minRating', clanTable.minRating or 0)
	request:AddVariable('motd', clanTable.motd or '')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)	
	
end

function Strife_Web_Requests:GetTwitchStreams(successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	successFunction = successFunction or function (request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('GetTwitchStreams - no data', 'general_ok', '', nil, nil, false)
		else
			println('^g GetTwitchStreams SUCCESS')
			printr(responseData)
		end
	end

	failFunction = failFunction or function (request)	-- error handler
		SevereError('GetTwitchStreams Request Error: ' .. Translate(request:GetError() or ''), 'general_ok', '', nil, nil, false)
	end
	
	local request = self:SpawnRequest(GetIdentID(), '/twitch')
	request:SetRequestMethod('GET')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)	
	
end

function Strife_Web_Requests:GetPurchasableClanProducts(successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	successFunction = successFunction or function (request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('GetClanProducts - no data', 'general_ok', '', nil, nil, false)
		else
			println('^g GetClanProducts SUCCESS')
			printr(responseData)
		end
	end

	failFunction = failFunction or function (request)	-- error handler
		-- SevereError('GetClanProducts Request Error: ' .. Translate(request:GetError() or ''), 'general_ok', '', nil, nil, false)
	end
	
	local request = self:SpawnRequest(GetIdentID(), '/purchase')
	request:SetRequestMethod('GET')

	request:AddVariable('clanProducts', '1')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		InterceptFailErrors(failFunction)
	)	
	
end

function Strife_Web_Requests:GetClanProducts(successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	successFunction = successFunction or function (request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('GetClanProducts - no data', 'general_ok', '', nil, nil, false)
		else
			println('^g GetClanProducts SUCCESS')
			printr(responseData)
		end
	end

	failFunction = failFunction or function (request)	-- error handler
		-- SevereError('GetClanProducts Request Error: ' .. Translate(request:GetError() or ''), 'general_ok', '', nil, nil, false)
	end
	
	local request = self:SpawnRequest(GetIdentID(), '/ident/identid/' .. URLEncode(GetIdentID()))
	request:SetRequestMethod('GET')

	request:AddVariable('clientClanProducts', '1')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		InterceptFailErrors(failFunction)
	)	
	
end

function Strife_Web_Requests:GetTwitchStreams(successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	successFunction = successFunction or function (request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('GetTwitchStreams - no data', 'general_ok', '', nil, nil, false)
		else
			println('^g GetTwitchStreams SUCCESS')
			printr(responseData)
		end
	end

	failFunction = failFunction or function (request)	-- error handler
		SevereError('GetTwitchStreams Request Error: ' .. Translate(request:GetError() or ''), 'general_ok', '', nil, nil, false)
	end
	
	local request = self:SpawnRequest(GetIdentID(), '/twitch')
	request:SetRequestMethod('GET')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)	
	
end

function Strife_Web_Requests:GetTwitchVods(successFunction, failFunction)
	if (not Strife_Region.regionTable[Strife_Region.activeRegion].enableWebRequests) then return false end

	successFunction = successFunction or function (request)	-- response handler
		local responseData = request:GetBody()
		if responseData == nil then
			SevereError('GetTwitchVods - no data', 'general_ok', '', nil, nil, false)
		else
			println('^g GetTwitchVods SUCCESS')
			printr(responseData)
		end
	end

	failFunction = failFunction or function (request)	-- error handler
		SevereError('GetTwitchVods Request Error: ' .. Translate(request:GetError() or ''), 'general_ok', '', nil, nil, false)
	end
	
	local request = self:SpawnRequest(GetIdentID(), '/twitch')
	request:SetRequestMethod('GET')

	request:SendRequest(true)

	request:ManagedWait(
		InterceptSuccessErrors(successFunction),
		failFunction
	)	
	
end

function Chat_Web_Requests:GetQueueInfo()
	local request = HTTP.SpawnRequest()
	request:SetTargetURL(GetCvarString('cl_chatAddress')..":7155/queue.json")
	request:SendRequest('GET')
	request:Wait()
	return JSON:decode(request:GetResponse())
end