include('utils.lua')

local username = select(1, ...)
local password = select(2, ...)
local chatAddress = select(3, ...)
local chatPort = select(4, ...)

newthread(function ()
	local testChatClient = {}
	SetSystemConsoleTitle('Connecting ' .. username)
	gameServer = ServerTesterDirectory.StartServerTester()
	gameServer:Login(username, password, chatAddress, chatPort)
	SetSystemConsoleTitle('Game Server ' .. username)
end)
