-- (C)2014 S2 Games
-- matchmakingSim.lua
--
-- Matchmaking simulation script
--=============================================================================

include("utils.lua")

local partySizeDist = {
	["1"] = 176.0,
	["2"] = 36.0,
	["3"] = 13.0,
	["4"] = 6.0,
	["5"] = 4.0,
}

local regionDist = {}

if false then
	regionDist = {
		["EU"] 				= 4.0,
		["USE"] 			= 4.0,
		["USW"] 			= 4.0,
		["SEA"] 			= 4.0,
		["EU,USE"] 			= 2.0,
		["EU,USW"] 			= 2.0,
		["EU,SEA"] 			= 2.0,
		["USE,USW"] 		= 4.0,
		["USE,SEA"] 		= 0.5,
		["USW,SEA"] 		= 1.0,
		["EU,USE,USW"] 		= 1.0,
		["EU,USE,SEA"] 		= 0.0,
		["USE,USW,SEA"] 	= 0.0,
		["EU,USE,USW,SEA"] 	= 0.0,
	}
elseif true then
	regionDist = {
		["EU"] 				= 1.0,
		["USE"] 			= 0.0,
		["USW"] 			= 0.0,
		["SEA"] 			= 0.0,
		["EU,USE"] 			= 0.0,
		["EU,USW"] 			= 0.0,
		["EU,SEA"] 			= 0.0,
		["USE,USW"] 		= 0.0,
		["USE,SEA"] 		= 0.0,
		["USW,SEA"] 		= 0.0,
		["EU,USE,USW"] 		= 0.0,
		["EU,USE,SEA"] 		= 0.0,
		["USE,USW,SEA"] 	= 0.0,
		["EU,USE,USW,SEA"] 	= 0.0,
	}
else
	regionDist = {
		["EU"] 				= 1.0,
		["SEA"] 			= 1.0,
		["US"] 				= 1.0,
		["EU,SEA"] 			= 1.0,
		["EU,US"] 			= 1.0,
		["US,SEA"] 			= 1.0,
		["EU,SEA,US"] 		= 1.0,
	}
end

local heroDist = {
	["Hero_Ace"]		= 7.3,
	["Hero_Bastion"]	= 5.9,
	["Hero_Bo"]			= 7.0,
	["Hero_Caprice"]	= 6.7,
	["Hero_Carter"]		= 4.8,
	["Hero_GunSlinger"]	= 0.0,
	["Hero_Hale"]		= 8.0,
	["Hero_Ladytinder"]	= 5.1,
	["Hero_Malady"]		= 6.3,
	["Hero_Minerva"]	= 7.2,
	["Hero_Moxie"]		= 9.0,
	["Hero_Ray"]		= 6.9,
	["Hero_Rook"]		= 10.8,
	["Hero_Tyme"]		= 0.0,
	["Hero_Vermillion"]	= 8.4,
	["Hero_Versat"]		= 0.0,
	["Hero_Vex"]		= 6.6,
}

local queueDist = {
	["pvp"]	= 1.0,
	["pve"]	= 0.0,
}

local gamesPlayedDist = {}

if false then
	gamesPlayedDist = {
		[1] 	= 1.0,
	}
else
	gamesPlayedDist = {
		[1] 	= 362,
		[2] 	= 292,
		[3] 	= 239,
		[4] 	= 206,
		[5] 	= 204,
		[6] 	= 169,
		[7] 	= 166,
		[8] 	= 157,
		[9] 	= 159,
		[10] 	= 152,
		[11] 	= 118,
		[12] 	= 127,
		[13] 	= 118,
		[14] 	= 111,
		[15] 	= 105,
		[16] 	= 85,
		[17] 	= 87,
		[18] 	= 81,
		[19] 	= 75,
		[20] 	= 72,
		[21] 	= 53,
		[22] 	= 58,
		[23] 	= 49,
		[24] 	= 63,
		[25] 	= 44,
		[26] 	= 59,
		[27] 	= 45,
		[28] 	= 37,
		[29] 	= 46,
		[30] 	= 43,
		[31] 	= 43,
		[32] 	= 33,
		[33] 	= 31,
		[34] 	= 20,
		[35] 	= 17,
		[36] 	= 28,
		[37] 	= 28,
		[38] 	= 22,
		[39] 	= 28,
		[40] 	= 20,
		[41] 	= 19,
		[42] 	= 14,
		[43] 	= 13,
		[44] 	= 19,
		[45] 	= 13,
		[46] 	= 12,
		[47] 	= 11,
		[48] 	= 12,
		[49] 	= 17,
		[50] 	= 11,
		[51] 	= 11,
		[52] 	= 12,
		[53] 	= 9,
		[54] 	= 7,
		[55] 	= 13,
		[56] 	= 15,
		[57] 	= 6,
		[58] 	= 2,
		[59] 	= 7,
		[60] 	= 9,
		[61] 	= 9,
		[62] 	= 6,
		[63] 	= 7,
		[64] 	= 5,
		[65] 	= 3,
		[66] 	= 5,
		[67] 	= 6,
		[68] 	= 1,
		[69] 	= 5,
		[70] 	= 6,
		[71] 	= 2,
		[72] 	= 3,
		[73] 	= 4,
		[74] 	= 3,
		[75] 	= 4,
		[76] 	= 4,
		[77] 	= 2,
		[78] 	= 1,
		[79] 	= 5,
		[80] 	= 3,
		[81] 	= 2,
		[82] 	= 2,
		[83] 	= 1,
		[84] 	= 1,
		[85] 	= 3,
		[86] 	= 3,
		[88] 	= 1,
		[89] 	= 1,
		[90] 	= 2,
		[91] 	= 1,
		[92] 	= 1,
		[93] 	= 1,
		[94] 	= 2,
		[95] 	= 3,
		[97] 	= 2,
		[103]	= 1,
		[105]	= 1,
		[106]	= 1,
		[108]	= 1,
		[112]	= 1,
		[115]	= 1,
		[135]	= 1,
		[138]	= 1,
		[143]	= 1,
	}
end

--[[====================
    getAverage
    ====================]]
local function getAverage(dist)
	local totalWeight = 0.0
	local totalValue = 0.0

	for k, v in pairs(dist) do
		totalWeight = totalWeight + v
	end

	for k, v in pairs(dist) do
		totalValue = totalValue + v / totalWeight * k
	end

	return totalValue
end


local numIntervals = 10000
local startParties = 0
local numClientsPerInterval = 750 / 30 / 60 * 2
local numPartiesPerInterval = numClientsPerInterval / getAverage(partySizeDist)
local oldInterval = 0
local virtualClients = {}
local ratingMean = 0
local ratingDeviation = 112


--[[====================
    getTotalWeight
    ====================]]
local function getTotalWeight(dist)
	local totalWeight = 0.0

	for k, v in pairs(dist) do
		totalWeight = totalWeight + v
	end

	return totalWeight
end


--[[====================
    randomFromDist

    Selects a random item from a weighted distribution
    ====================]]
local function randomFromDist(dist)
	local totalWeight = getTotalWeight(dist)
	local roll = RandomFloat(0.0, totalWeight)

	for k, v in pairs(dist) do
		if roll <= v then
			return k
		end

		roll = roll - v
	end

	return nil -- Should never happen
end


--[[====================
    randomUnselectedHero
    ====================]]
local function randomUnselectedHero(party)
	local heroList = ChatServer.GetHeroList()
	local validHeroesSet = {}

	for i, v in ipairs(heroList) do
		validHeroesSet[v] = true
	end

	local selectedHeroes = party:GetSelectedHeroes()

	for i, v in ipairs(selectedHeroes) do
		validHeroesSet[v] = nil
	end

	local validHeroesDist = {}

	for k, v in pairs(validHeroesSet) do
		validHeroesDist[k] = heroDist[k] or 1.0
	end

	return randomFromDist(validHeroesDist)
end


--[[====================
    createParty
    ====================]]
local function createParty(partySimData, region, queue)

	local members = {}

	local party = nil
	local size = #partySimData.members
	
	for i = 1, size, 1 do
		local memberSimData = partySimData.members[i]
		local client = Client.NewVirtual()
		
		local clientIdentID = client:GetIdentID()
		
		if i == 1 then
			party = Party.New(clientIdentID)

			party:SetOption("name", "Virtual Party " .. PartyDirectory.GetCount())
			party:SetOption("region", region)
			party:SetOption("queue", queue)
		end

		client:SetPetSelected(true)

		party:AddClient(client, memberSimData.gamesPlayed, memberSimData.rating)
		party:AddMemberPet(client, "Familiar_Razer")
		party:SetMemberOption(client, "hero", memberSimData.hero)
		party:SetMemberOption(client, "pet", "Familiar_Razer")

		table.insert(members, client)
		table.insert(virtualClients, client)
	end

	for i, v in ipairs(members) do
		party:SetMemberOption(v, "ready", true)
	end
end


--[[====================
    createParties
    ====================]]
local function createParties(numClients)
	local clientsRemaining = numClients
	local numClientsCreated = 0

	while clientsRemaining > 0 do
		local partySimData = Matchmaker.GetRandomPartySimData()
		createParty(partySimData, randomFromDist(regionDist), randomFromDist(queueDist))
		clientsRemaining = clientsRemaining - #partySimData.members
		numClientsCreated = numClientsCreated + #partySimData.members
	end

	return numClientsCreated
end


--[[====================
    simStart
    ====================]]
local function simStart()
	createParties(startParties)
	Matchmaker.SetSimulate(true)
end


--[[====================
    simEnd
    ====================]]
local function simEnd()
	local numUnmatched = 0

	for i, v in ipairs(virtualClients) do
		if not v:IsInGame() then
			numUnmatched = numUnmatched + 1
		end
		
		v:Remove()
	end

	println(numUnmatched .. " of " .. #virtualClients ..  " clients unmatched")

	virtualClients = {}

	Matchmaker.ClearCallbacks()
	Matchmaker.SetSimulate(false)

	Cmd('PrintMatchmakerStatus')
end



--[[====================
    makeOnInterval
    ====================]]
local function makeOnInterval()
	local interval = 0
	local accum = 0

	return function()
		if interval < numIntervals then
			accum = accum + numClientsPerInterval
			local numClients = createParties(math.floor(accum))
			accum = accum - numClients
			interval = interval + 1
		elseif interval == numIntervals then
			simEnd()
			interval = interval + 1
		end
	end
end


--[[====================
    main
    ====================]]
local function main()
	simStart()
end

println("Starting matchmaking simulation")

Matchmaker.LoadPartySimData("~/logs6_party_data_0000.dat")
Matchmaker.RegisterIntervalCallback(makeOnInterval())
Matchmaker.SetBenchmark(true)

newthread(main)
