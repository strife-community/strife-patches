include('utils.lua')

testClient = testClient or {}

function TestCustomCommand(s)
	local x = Cmd('set ' .. s)
	
	return x
end
Console.RegisterCommand('TestCustomCommand', TestCustomCommand, 1)

function TestReload()
	return 1, 2, 3, 4
end
Console.RegisterCommand('TestReload', TestReload, 0)

function TestLuaLogin(username, password)
	testClient = {}
	testClient.username = username

	local srp = SRPClient.Create()
	local success
	
	local A
	success, A = srp:Begin(username, password)
	if not success then return end
	
	local request1 = HTTP.SpawnRequest()
	
	request1:SetTargetURL('192.168.1.240/c/igames/session/email/' .. URLEncode(username))
	request1:AddVariable('A', A)
	request1:SendRequest('POST')
	request1:Wait()

	local response1 = PHP.Deserialize(request1:GetResponse())
	local response1Body = response1.body
	
	if reponse1Body == nil then return end
	
	local response1SRP = response1Body.srp
	if response1SRP == nil then return end
	
	local M
	success, M = srp:Middle(response1SRP.salt, response1SRP.B, response1SRP.salt2)
	if not success then return end
	
	local request2 = HTTP.SpawnRequest()
	
	request2:SetTargetURL('192.168.1.240/c/igames/session/email/' .. URLEncode(username))
	request2:AddVariable('proof', M)
	request2:SendRequest('POST')
	request2:Wait()
	
	local response2 = PHP.Deserialize(request2:GetResponse())
	local response2Body = response2.body
	
	if response2Body == nil then return end
	
	local response2SRP = response2Body.srp
	if response2SRP == nil then return end
	
	success = srp:Finish(response2SRP.serverProof)
	if not success then return end
	
	testClient.sessionKey = srp:GetSessionKey()
	testClient.account_id = response2Body.account_id
	testClient.shard = response2Body.shard
	
	return srp:GetSessionKey()
end
Console.RegisterCommand('TestLuaLogin', TestLuaLogin, 2)

function TestLuaLogin2(username, password)
	testClient = {}
	testClient.username = username

	local srp = SRPClient.Create()
	local success
	
	local A
	success, A = srp:Begin(username, password)
	if not success then return end
	
	local request1 = Master.SpawnRequest()
	
	request1:SetServerAddress('192.168.1.240')
	request1:SetService('igames')
	request1:SetClientType('c')
	request1:SetRequestMethod('POST')
	request1:SetResource('/session/email/' .. URLEncode(username))
	request1:AddVariable('A', A)
	request1:SendRequest(true)
	request1:Wait()

	local response1Body = request1:GetBody()
	if response1Body == nil then return end
	
	local response1SRP = response1Body.srp
	if response1SRP == nil then return end
	
	local M
	success, M = srp:Middle(response1SRP.salt, response1SRP.B, response1SRP.salt2)
	if not success then return end
	
	local request2 = Master.SpawnRequest()
	
	request2:SetServerAddress('192.168.1.240')
	request2:SetService('igames')
	request2:SetClientType('c')
	request2:SetRequestMethod('POST')
	request2:SetResource('/session/email/' .. URLEncode(username))
	request2:AddVariable('proof', M)
	request2:SendRequest(true)
	request2:Wait()
	
	local response2Body = request2:GetBody()
	if response2Body == nil then return end
	
	local response2SRP = response2Body.srp
	if response2SRP == nil then return end
	
	success = srp:Finish(response2SRP.serverProof)
	if not success then return end
	
	testClient.sessionKey = srp:GetSessionKey()
	testClient.account_id = response2Body.account_id
	testClient.shard = response2Body.shard
	
	return srp:GetSessionKey()
end
Console.RegisterCommand('TestLuaLogin2', TestLuaLogin2, 2)

function TestLuaSRP(username, password)
	local client = SRPClient.Create()
	local server = SRPServer.Create()
	
	local success
	
	local A
	success, A = client:Begin(username, password)
	if not success then return end
	
	local s
	local B
	local salt2
	success, s, B, salt2 = server:Begin(username, password, A)
	if not success then return end
	
	local M
	success, M = client:Middle(s, B, salt2)
	if not success then return end
	
	local HAMK
	success, HAMK = server:Finish(M)
	if not success then return end
	
	success = client:Finish(HAMK)
	if not success then return end
	
	testClient.sessionKey = client:GetSessionKey()
	
	return client:GetSessionKey()
end
Console.RegisterCommand('TestLuaSRP', TestLuaSRP, 2)

function TestLuaSession()
	local challenge = CryptRandHex(64)
	local hash = SHA256(challenge .. testClient.sessionKey)
	
	local request = Master.SpawnRequest()
	
	request:SetServerAddress('192.168.1.240')
	request:SetService('igames')
	request:SetClientType('s')
	request:SetRequestMethod('GET')
	request:SetResource('/session/accountid/' .. testClient.account_id .. '.' .. testClient.shard)
	request:AddVariable('challenge', challenge)
	request:AddVariable('hash', hash)
	request:SendRequest()
	request:Wait()

	local response1Body = request:GetBody()
	if response1Body == nil then return end
	
	println(TableToMultiLineString(response1Body))
end
Console.RegisterCommand('TestLuaSession', TestLuaSession, 0)
