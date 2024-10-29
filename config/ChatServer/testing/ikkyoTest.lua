include('utils.lua')

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


--
-- IkkyoMultiClientTester
--
function IkkyoMultiClientTester()
	newthread( function ()
		
		if not Listen.IsListening() then
			Listen.StartListening(7031)
		end

		if not HTTPServer.IsListening() then
			HTTPServer.StartListening(7080)
		end

		while ChatServer.IsLoggingIn() do yield() end
		if not ChatServer.IsLoggedIn() then return end
		
		StartClient('armadon@s2games.com', 'tempy', 'Armadon', 'localhost', 7031)
		StartClient('behemoth@s2games.com', 'tempy', 'Behemoth', 'localhost', 7031)
	end)
end
Console.RegisterCommand('IkkyoMultiClientTester', IkkyoMultiClientTester, 0)


--
-- IkkyoLobbyGameTester
--
function IkkyoLobbyGameTester()
	newthread( function ()

		if not Listen.IsListening() then
			Listen.StartListening(7031)
		end

		if not HTTPServer.IsListening() then
			HTTPServer.StartListening(7080)
		end
		
		while ChatServer.IsLoggingIn() do yield() end
		if not ChatServer.IsLoggedIn() then return end
		
		StartServer('2.002:1', 'tempy', 'localhost', 7031)
		StartClient('behemoth@s2games.com', 'tempy', 'Behemoth', 'localhost', 7031)
		StartClient('hammerstorm@s2games.com', 'tempy', 'Hammerstorm', 'localhost', 7031)
	end)
end
Console.RegisterCommand('IkkyoLobbyGameTester', IkkyoLobbyGameTester, 0)


println("Loaded Ikkyo test functions")