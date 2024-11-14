chatserverAddress = 'localhost'
chatserverPort = 7031

local function StartClientTester(num, chatAddress, chatPort)
	local chatClient = ClientTesterDirectory.StartClientTester()
	chatClient:Login('loadbotemail' .. num .. '@example.com', 'loadBotPassword' .. num, 'LoadBot' .. num, chatAddress, chatPort)
	while (not chatClient:IsLoggedIn()) do yield() end
	return chatClient
end


--
-- MatchmakingTester
--
function MatchmakingTester()
newthread( function()
	
	local heroes = { 'Hero_Vermillion', 'Hero_Caprice', 'Hero_Bo', 'Hero_Ladytinder', 'Hero_Moxie', 'Hero_Rook', 'Hero_Malady', 'Hero_Ace', 'Hero_Vex', 'Hero_Ray' }
	local clients = {}
	for i = 1, 10, 1 do
		clients[i] = StartClientTester(9000 + i, chatserverAddress, chatserverPort)
		clients[i]:StartVoiceClient()
	end
	
	local leader1 = clients[1]
	local leader2 = clients[6]
	
	leader1:CreateParty()
	leader2:CreateParty()
	
	wait(1000)
	
	leader1:SetPartyOption('name', 'Party1')
	leader1:SetPartyOption('region', 'USW')
	
	leader2:SetPartyOption('name', 'Party2')
	leader2:SetPartyOption('region', 'USW')
	
	for i = 2, 5, 1 do
		leader1:InviteToParty(clients[i]:GetIdentID())
		leader2:InviteToParty(clients[i+5]:GetIdentID())
	end
		
	wait(1000)
	
	for i = 1, 10, 1 do
		clients[i]:AcceptLastPartyInvite()
	end
	
	wait(1000)
	
	for i = 1, 10, 1 do
		clients[i]:SetPartyMemberOption('backpack', '')
		clients[i]:SetPartyMemberOption('hero', heroes[i])
		clients[i]:SetPartyMemberOption('pet', 'Familiar_Tortus')
		clients[i]:SetPartyMemberOption('ready', 'true')
	end
	
end)
end
Console.RegisterCommand('MatchmakingTester', MatchmakingTester, 0)
