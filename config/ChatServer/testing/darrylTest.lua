include('utils.lua')

chatserverAddress = 'localhost'
chatserverPort = 7031

--
-- StartClient
--
local function StartClient(username, password, identName, chatAddress, chatPort)
	chatClient = ClientTesterDirectory.StartClientTester()
	chatClient:Login(username, password, identName, chatAddress, chatPort)
	return chatClient
end


--
-- StartClientTester
--
local function StartClientTester(num, chatAddress, chatPort)
	local chatClient = StartClient('darrylTest' .. num .. '@emailz.me', 'test123', 'darrylTest' .. num, chatAddress, chatPort)
	while (not chatClient:IsLoggedIn()) do yield() end
	return chatClient
end


--
-- PickmodeTester
--
function PickmodeTester()
newthread( function()
	local party ={
		[1] = { 
			Banned = { ' ' },
			Heroes = { 	'Hero_Vermillion', 'Hero_Caprice', 
					   	'Hero_Ladytinder', 'Hero_Moxie', 'Hero_Rook' },
			clients = { },
			leader = nil,
		},
	
		[2] = {
			Banned 	= { ' ' },
			Heroes 	= {	'Hero_Ace', 'Hero_Vex', 'Hero_Ray', 
					   	'Hero_Shank', 'Hero_Blaze'},
			clients = { },
			leader = nil,
		},
	}

	for i = 1, 5, 1 do
		party[1].clients[i] = StartClientTester(i, chatserverAddress, chatserverPort)
		party[2].clients[i] = StartClientTester(i + 5, chatserverAddress, chatserverPort)
	end

	print ('\nCreating Parties...\n')	

	party[1].leader = party[1].clients[1]
	party[2].leader = party[2].clients[1]
	
	party[1].leader:CreateParty()
	party[2].leader:CreateParty()
	
	wait(1000)
	
	party[1].leader:SetPartyOption('name', 'Party1')
	party[1].leader:SetPartyOption('region', 'USW')
	
	party[2].leader:SetPartyOption('name', 'Party2')
	party[2].leader:SetPartyOption('region', 'USW')
	
	for i = 2, 5, 1 do
		party[1].leader:InviteToParty(party[1].clients[i]:GetIdentID())
		party[2].leader:InviteToParty(party[2].clients[i]:GetIdentID())
	end
		
	wait(2000)

	for i = 2, 5, 1 do
		party[1].clients[i]:AcceptLastPartyInvite()
		party[2].clients[i]:AcceptLastPartyInvite()
	end
	
	wait(2000)

-- Start Captains Mode
	print ('Creating Game...\n')
	-- Start a game lobby with mode:captains
	party[1].leader:CreateGame('map:strife teamsize:5 mode:captainsmode')

	wait(1000)

	-- join game lobby
	party[1].leader:InviteToGame(party[2].leader:GetIdentID())

	wait(1000)

	party[2].leader:AcceptLastGameInvite()

	wait(1000)
	print ('Invites Accepted...\n')

	-- party leaders are captains
	-- everyone ready up to begin banning
	for i=1, 5, 1 do
		party[1].clients[i]:SetGameMemberOption('ready', 'true')
		party[2].clients[i]:SetGameMemberOption('ready', 'true')
	end

	wait(1000)

	print ('Send Match Start...\n')
	
	party[1].leader:StartMatch()

	print ('Waiting for Match to Start...\n')
	while(party[1].leader:GetGameState() ~= 4) do yield() end

	print ('Captains Mode beginning:\n')
	wait(1000)

	print ('Banning Phase\n')
	-- party1 ban
	party[1].leader:SetGameMemberOption('hero', 'Hero_Malady')

	-- party2 ban
	party[2].leader:SetGameMemberOption('hero', 'Hero_Bo')

	wait(1000)

	-- picks
	print ('Captain Pick Phase\n')
	party[1].leader:SetGameMemberOption('hero', party[1].Heroes[1])

	wait(500)

	party[2].leader:SetGameMemberOption('hero', party[2].Heroes[1])
	party[2].leader:SetGameMemberOption('hero', party[2].Heroes[2])
	party[2].leader:SetGameMemberOption('hero', party[2].Heroes[3]) -- should fail

	wait(500)

	party[1].leader:SetGameMemberOption('hero', party[1].Heroes[2])
	party[1].leader:SetGameMemberOption('hero', party[1].Heroes[3])
	party[1].leader:SetGameMemberOption('hero', party[1].Heroes[4]) -- should fail

	wait(500)

	party[2].leader:SetGameMemberOption('hero', party[2].Heroes[3])
	party[2].leader:SetGameMemberOption('hero', party[2].Heroes[4])

	wait(500)

	party[1].leader:SetGameMemberOption('hero', party[1].Heroes[4])
	party[1].leader:SetGameMemberOption('hero', party[1].Heroes[5])

	wait(500)

	party[2].leader:SetGameMemberOption('hero', party[2].Heroes[5])

	wait(1000)

	print ('Team Pick Phase\n')

	-- team picks
	for i = 1, 5, 1 do
		party[1].clients[i]:SetGameMemberOption('backpack', '')
		party[1].clients[i]:SetGameMemberOption('hero', party[1].Heroes[i])
		party[1].clients[i]:SetGameMemberOption('pet', 'Familiar_Tortus')

		party[2].clients[i]:SetGameMemberOption('backpack', '')
		party[2].clients[i]:SetGameMemberOption('hero', party[2].Heroes[i])
		party[2].clients[i]:SetGameMemberOption('pet', 'Familiar_Tortus')
	end

	wait(500)

	print ('Everyone Ready...\n')
	for i = 1, 5, 1 do
		party[1].clients[i]:SetGameMemberOption('ready', 'true')
		party[2].clients[i]:SetGameMemberOption('ready', 'true')
	end	

	print ('Done.\n')
end)
end
Console.RegisterCommand('PickmodeTester', PickmodeTester, 0)

function darrylTest()
newthread ( function() 
	ChatServer.Login('11.000', '121582')
	if not Listen.IsListening() then
		Listen.StartListening(7031)
	end

	if not HTTPServer.IsListening() then
		HTTPServer.StartListening(7080)
	end

	while ChatServer.IsLoggingIn() do yield() end
	if not ChatServer.IsLoggedIn() then return end

	PickmodeTester()
end)
end
Console.RegisterCommand('darrylTest', darrylTest, 0)

println("Loaded Darryl test functions")