include('utils.lua')

local username = select(1, ...)
local password = select(2, ...)
local identName = select(3, ...)
local chatAddress = select(4, ...)
local chatPort = select(5, ...)

newthread(function ()
	local testChatClient = {}
	SetSystemConsoleTitle('Connecting ' .. username)
	testChatClient.username = username
	local chatClient = testChatClient.chatClient
	chatClient = ClientTesterDirectory.StartClientTester()
	chatClient:Login(username, password, identName, chatAddress, chatPort)
	SetSystemConsoleTitle(username)
end)
