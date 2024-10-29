include('utils.lua')

testChatClient = testChatClient or {}
superVerbose = false

--
-- AppendAutoExec
--
local function AppendAutoExec(autoexec, cmd)
	if autoexec ~= nil and autoexec ~= '' then
		autoexec = autoexec .. ' '
	end
	
	autoexec = autoexec .. cmd .. ';'

	return autoexec
end


--
-- StartClient
--
local function StartClient(username, password, identName, chatAddress, chatPort)
	local autoexec = ''

	autoexec = AppendAutoExec(autoexec, 'Set chatserver_masterServerAddress ' .. ChatServer.GetMasterServerAddress())
	autoexec = AppendAutoExec(autoexec, 'LuaFile multiClientTester.lua ' .. username .. ' ' .. password .. ' ' .. identName .. ' ' .. chatAddress .. ' ' .. chatPort)

	StartInstance('-noconfigwrite -autoexec "' .. autoexec ..'"')
end


--
-- StartClientInSameWindow
--
local function StartClientInSameWindow(username, password, identName, chatAddress, chatPort)
	-- ripped form multClientTester.lua
	local testChatClient = {}	
	testChatClient.username = username
	local chatClient = testChatClient.chatClient
	chatClient = ClientTesterDirectory.StartClientTester()
	chatClient:Login(username, password, identName, chatAddress, chatPort)
	return chatClient
end


--
-- StartServer
--
local function StartServer(username, password, chatAddress, chatPort)
	local autoexec = ''

	autoexec = AppendAutoExec(autoexec, 'Set chatserver_masterServerAddress ' .. ChatServer.GetMasterServerAddress())
	autoexec = AppendAutoExec(autoexec, 'LuaFile multiServerTester.lua ' .. username .. ' ' .. password .. ' ' .. chatAddress .. ' ' .. chatPort)

	StartInstance('-noconfigwrite -autoexec "' .. autoexec ..'"')
end



function MultiClient_DoN(clients, fn, requireConnected)
	for k1,v1 in pairs(clients) do
		if not requireConnected or v1.connected then
			fn(v1)
		end
	end
end

function MultiClient_DoNSquared(clients, fn, requireConnected)
	for k1,v1 in pairs(clients) do
		if not requireConnected or v1.connected then
			for k2, v2 in pairs(clients) do
				if k1~=k2 and (not requireConnected or v2.connected) then
					fn(v1,v2)
				end
			end
		end
	end
end

--
-- MultiClientTester
--
function MultiClientTester(startIdx, stopIdx, address)
	newthread( function ()
		-- Listen.StartListening(7031)
		-- ChatServer.Login('3.000', 'tempy')
		
		-- while ChatServer.IsLoggingIn() do yield() end
		-- if not ChatServer.IsLoggedIn() then return end
		
		-- 1000 bot accounts exist on main s2ogi
		
		local startBatchSize = 20
		
		local clients = {}
		local blahCounter = 0;
		
		while true do
			blahCounter = blahCounter + 1
			
			for i=startIdx,math.min(startIdx+startBatchSize,stopIdx) do
				clients[i] = {}
				local c = clients[i]
				clients[i].index = i
				clients[i].accountName = 'lb' .. i .. '@example.com'
				clients[i].clientTester = StartClientInSameWindow( clients[i].accountName, 'pass', 'LoadBot' .. i, address, 7031)
				--clients[i].clientTester:SetVerbose(true)
				clients[i].connected = false
				clients[i].hasPet = false
				clients[i].requestedPet = false
				clients[i].joinedChannel = false
				clients[i].waited = 0
				--print(TableToMultiLineString(clients[i]) .. '\n')
				
			end
			
			-- 2 client race condition test
			--[[
			if startIdx == 1 then
				for i=1,2 do
					clients[i] = {}
					clients[i].accountName = 'lb' .. 1 .. '@example.com'
					clients[i].clientTester = StartClientInSameWindow( clients[i].accountName, 'pass', 'LoadBot' .. 1, 'localhost', 7030 + i)
					clients[i].connected = false
					clients[i].hasPet = false
					clients[i].requestedPet = false
					print(TableToMultiLineString(clients[i]) .. '\n')
					
					wait(5000)
				end
			end
			]]
			
			startIdx = startIdx + startBatchSize + 1
			
			
			local waitingForS2OGI = true
			while waitingForS2OGI do
			
				wait(1000)
				waitingForS2OGI = false
				
				MultiClient_DoN(clients, function( c )
					c.connected = c.clientTester:IsConnected()
					if not c.connected then
						waitingForS2OGI = true
						c.waited = c.waited + 1
						if c.waited > 35 then
							c.clientTester = StartClientInSameWindow( c.accountName, 'pass', 'LoadBot' .. c.index, address, 7031)
							c.waited = 0
							print('Recreating ' .. c.accountName .. '\n')
						end
					end
				end, false)
			end
		
			--[[
			]]
			
			--[[
			MultiClient_DoN(clients, function( c )
				-- set up our pet (if it needs to be)
				if not c.requestedPet then
					c.requestedPet = true
					GetPets(c.clientTester, function()
						c.hasPet = true
						print('LoadBot' .. c.accountName .. ' creating pet...\n')
						CreatePet(c.clientTester, 'Familiar_Tortus', 'food')
					end,
					function(pet_id)
						c.hasPet = true
						print('LoadBot' .. c.accountName .. ' has pet...\n')
						-- FeedPet(c.clientTester, pet_id, 10)
					end)
				end
			end, true)
			]]
			
			--[[
			MultiClient_DoN(clients, function( c )
				-- target shoelle's testing account with PMs
				-- c.clientTester:PrivateMessage(282002, 'Testing PM ' .. blahCounter)
				
				if not c.joinedChannel then
					c.clientTester:JoinChannel('aoeu' .. tostring(c.index % 25))
					c.joinedChannel = true
				else
					-- c.clientTester:ChannelMessage('aoeu', 'Testing channel ' .. blahCounter)
				end
				
			end, false)
			]]
			
			-- crosstalk
			--[[
			MultiClient_DoNSquared(clients, function( c1, c2 )
				local ident2 = c2.clientTester:GetIdentID()
				c1.clientTester:PrivateMessage(ident2, 'Testing PM to ' .. ident2 .. ' ' ..blahCounter)
			end, true)
			]]
			
			-- friend each other
			--[[
			MultiClient_DoNSquared(clients, function( c1, c2 )
				local ident2 = c2.clientTester:GetIdentID()
				c1.clientTester:AddFriend(ident2)
			end)
			
			-- unfriend each other
			MultiClient_DoNSquared(clients, function( c1, c2 )
				local ident2 = c2.clientTester:GetIdentID()
				c1.clientTester:RemoveFriend(ident2)
			end)
			]]
			
			-- if we have a party invite, accept it!
			--[[
			MultiClient_DoN(clients, function( c )
				c.clientTester:AcceptLastPartyInvite()
			end)
			]]
		end
	end)
end
Console.RegisterCommand('MultiClientTester', MultiClientTester, 3)

local serverAddress = 'main.s2ogi.strife.com'

function GetPets(clientTester, createPetCallback, petExistsCallback)
	local identid = clientTester:GetIdentID()
	local account_id = clientTester:GetAccountID()
	local sessionKey = clientTester:GetSessionKey()

	local request1 = Master.SpawnRequest()

	request1:SetServerAddress(serverAddress)
	request1:SetRequestService('strife')
	request1:SetRequestClientType('c')
	request1:SetRequestMethod('GET')
	request1:SetResource('/pet/identid/' .. URLEncode(identid))

	request1:SetAuthID(account_id)
	request1:SetAuthSessionKey(sessionKey)
	request1:SetAuthService('igames')
	request1:SetAuthClientType('c')
		
	request1:SendRequest(true)
	request1:ManagedWait(function()
		local response1Body = request1:GetBody()
		if superVerbose then println(TableToMultiLineString(response1Body)) end
		if response1Body == nil or
			response1Body["pets"] == nil or
			response1Body["pets"]["pets"] == nil or
			next(response1Body["pets"]["pets"]) == nil then
			createPetCallback()
		else
			local k,v = next(response1Body["pets"]["pets"])
			local pet_id = v["pet_id"]
			if superVerbose then println('Client ' .. identid .. ' has pet pet_id=' .. pet_id) end
			petExistsCallback( pet_id )
		end
	end,
	function()
		println( 'GetPets failed' )
	end)
end

function CreatePet(clientTester, petType, commodity)
	local identid = clientTester:GetIdentID()
	local account_id = clientTester:GetAccountID()
	local sessionKey = clientTester:GetSessionKey()

	local request1 = Master.SpawnRequest()

	request1:SetServerAddress(serverAddress)
	request1:SetRequestService('strife')
	request1:SetRequestClientType('c')
	request1:SetRequestMethod('POST')
	request1:SetResource('/pet/identid/' .. URLEncode(identid))

	request1:SetAuthID(account_id)
	request1:SetAuthSessionKey(sessionKey)
	request1:SetAuthService('igames')
	request1:SetAuthClientType('c')

	request1:AddVariable('petType', petType)
	request1:AddVariable('commodity', commodity)
	request1:SendRequest(true)

	request1:ManagedWait(function()
		if superVerbose then println('CreatePet succeeded for ' .. identid .. ' petType ' .. petType) end
		local response1Body = request1:GetBody()
		if response1Body == nil then return end
		println(TableToMultiLineString(response1Body) .. '\n')
	end,
	function()
		if superVerbose then println('CreatePet failed for ' .. identid .. ' petType ' .. petType) end
	end)	
end


function FeedPet(clientTester, petid, amount)
	local identid = clientTester:GetIdentID()
	local account_id = clientTester:GetAccountID()
	local sessionKey = clientTester:GetSessionKey()
	
	local request1 = Master.SpawnRequest()

	request1:SetServerAddress(serverAddress)
	request1:SetRequestService('strife')
	request1:SetRequestClientType('c')
	request1:SetRequestMethod('PUT')
	request1:SetResource('/pet/identid/' .. URLEncode(identid) .. '/petid/' .. URLEncode(petid))

	request1:SetAuthID(account_id)
	request1:SetAuthSessionKey(sessionKey)
	request1:SetAuthService('igames')
	request1:SetAuthClientType('c')

	request1:AddVariable('action', 'feed')
	request1:AddVariable('feed', amount)
	request1:SendRequest(true)
	request1:ManagedWait(function()
		local response1Body = request1:GetBody()
		if response1Body == nil then return false end
		if superVerbose then println(TableToMultiLineString(response1Body)) end
		return true	
	end, function()
		if superVerbose then println( ' FeedPet failed for ' .. identid ) end
	end)
end

--
-- SingleClientTester
--
function SingleClientTester()
	newthread( function ()
		--[[
		Listen.StartListening(7031)
		
		ChatServer.Login('2.000', 'tempy')
		
		while ChatServer.IsLoggingIn() do yield() end
		if not ChatServer.IsLoggedIn() then return end
		]]
		
		StartClient('ikkyo@s2games.com', 'tempy', 'Ikkyo', '205.204.53.150', 7031)
		--StartClient('armadon@s2games.com', 'tempy', 'Armadon', '205.204.53.150', 7031)
		--StartClient('behemoth@s2games.com', 'tempy', 'Behemoth', '205.204.53.150', 7031)
	end)
end
Console.RegisterCommand('SingleClientTester', SingleClientTester, 0)


--
-- TestChatServer
--
function TestChatServer()
	newthread( function ()
		Listen.StartListening()
		
		ChatServer.Login('3.000', 'tempy')
		
		while ChatServer.IsLoggingIn() do yield() end
		if not ChatServer.IsLoggedIn() then return end
	end)
end
Console.RegisterCommand('TestChatServer', TestChatServer, 0)


--
-- MultiServerTester
--
function MultiServerTester()
	newthread( function ()
		Listen.StartListening()
		
		ChatServer.Login('3.000', 'tempy')
		
		while ChatServer.IsLoggingIn() do yield() end
		if not ChatServer.IsLoggedIn() then return end
		
		StartServer('2.002', 'tempy')
	end)
end
Console.RegisterCommand('MultiServerTester', MultiServerTester, 0)
