local interface = object
local tinsert, tremove, tsort = table.insert, table.remove, table.sort
local GetTrigger = LuaTrigger.GetTrigger
mainUI = mainUI or {}
mainUI.progression = mainUI.progression or {}
mainUI.progression.stats = mainUI.progression.stats or {}
mainUI.savedRemotely 	= mainUI.savedRemotely 	or {}
mainUI.savedRemotely.progression = mainUI.savedRemotely.progression or {}

mainUI.progression.CRAFTING_UNLOCK_LEVEL 	= 4 -- 6
mainUI.progression.RANKED_UNLOCK_LEVEL 		= 25 -- 6 ?
mainUI.progression.KHANQUEST_UNLOCK_LEVEL 	= 1
mainUI.progression.PRIZE_SPIN_UNLOCK_LEVEL 	= 1 -- 6
mainUI.progression.SCRIM_AND_CHALLENGE_UNLOCK_LEVEL 	= 1 -- 6

local AccountProgression = GetTrigger('AccountProgression')

local function ProgressionRegister()	

	AccountProgression.update 					= false
	AccountProgression.newLevelUp 				= false
	AccountProgression.experience 				= 0
	AccountProgression.lastExperience 			= 0
	AccountProgression.level 					= 0
	AccountProgression.lastLevel 				= 0
	AccountProgression.percentToNextLevel 		= 0
	AccountProgression.experienceToNextLevel 	= 0
	AccountProgression.petLevel 				= 0
	AccountProgression.percentToNextPetLevel	= 0
	AccountProgression.accountLevelForNextPetLevel	= 0
	AccountProgression.petAbilityLevel1			= 0
	AccountProgression.petAbilityLevel2			= 0
	AccountProgression.petAbilityLevel3			= 0
	
	mainUI.progression.stats.account 			= mainUI.progression.stats.account or {}
	mainUI.progression.stats.heroes 			= mainUI.progression.stats.heroes or {}	
	mainUI.progression.stats.heroesMastered		= mainUI.progression.stats.heroesMastered or 0
	mainUI.progression.pets 					= mainUI.progression.pets or {}
	mainUI.savedRemotely.progression			= mainUI.savedRemotely.progression or {}
	
	function mainUI.progression.GetAccountLevelFromExperienceRequirement(experience)
		if (mainUI.progressionData.accountValues.accountLevelTable) then
			local lastExperienceRequired = 0
			for accountLevel, experienceRequired in ipairs(mainUI.progressionData.accountValues.accountLevelTable) do
				if (experience == (experienceRequired - lastExperienceRequired)) then
					return accountLevel
				end
				lastExperienceRequired = experienceRequired
			end
			if (#mainUI.progressionData.accountValues.accountLevelTable > 0) then
				return #mainUI.progressionData.accountValues.accountLevelTable + 1
			else
				return -2
			end
		else
			return -1
		end
	end	
	
	function mainUI.progression.GetAccountLevelFromExperience(experience)
		if (mainUI.progressionData.accountValues.accountLevelTable) then
			for accountLevel, experienceRequired in ipairs(mainUI.progressionData.accountValues.accountLevelTable) do
				if (experience < experienceRequired) then
					return accountLevel - 1
				end
			end
			if (#mainUI.progressionData.accountValues.accountLevelTable > 0) then
				return #mainUI.progressionData.accountValues.accountLevelTable
			else
				return -2
			end
		else
			return -1
		end
	end
	
	function mainUI.progression.UpdateProgression()
		mainUI.progressionData.GenerateFakeAccountData()
		
		local accountInfo = GetTrigger('AccountInfo')
		
		local function GetExperienceToNextLevel(currentLevel, currentExperience)
			if (mainUI.progressionData.accountValues.accountLevelTable[currentLevel + 1]) and (mainUI.progressionData.accountValues.accountLevelTable[currentLevel]) then
				local experienceToNextLevel 		= mainUI.progressionData.accountValues.accountLevelTable[currentLevel + 1] - mainUI.progressionData.accountValues.accountLevelTable[currentLevel]
				local currentExperienceToNextLevel 	= currentExperience - mainUI.progressionData.accountValues.accountLevelTable[currentLevel]
				local percentToNextLevel = currentExperienceToNextLevel / experienceToNextLevel
				return experienceToNextLevel, percentToNextLevel
			else
				return 0, 0
			end
		end
		
		local function GetExperienceToNextPetLevel(currentLevel, targetLevel, currentExperience)
			if (mainUI.progressionData.accountValues.accountLevelTable[currentLevel]) and (mainUI.progressionData.accountValues.accountLevelTable[targetLevel]) then
				local experienceToNextLevel 		= mainUI.progressionData.accountValues.accountLevelTable[targetLevel] - mainUI.progressionData.accountValues.accountLevelTable[currentLevel]
				local currentExperienceToNextLevel 	= currentExperience - mainUI.progressionData.accountValues.accountLevelTable[currentLevel]
				local percentToNextLevel = currentExperienceToNextLevel / experienceToNextLevel
				return experienceToNextLevel, percentToNextLevel
			else
				return 0, 0
			end
		end		
		
		local function GetPetAbilityLevel(accountLevel)
			for petLevel, compareAccountLevel in ipairs(mainUI.progressionData.accountValues.petLevelToAccountLevel) do
				if (compareAccountLevel > accountLevel) then
					return petLevel - 1, compareAccountLevel
				end
			end
			return #mainUI.progressionData.accountValues.petLevelToAccountLevel, 0
		end		
		
		local accountLevel = math.max(1, tonumber(accountInfo.accountLevel))
		
		AccountProgression.experience 															= 	tonumber(accountInfo.experience)
		if GetCvarNumber('ui_overrideAccountLevel') and (GetCvarNumber('ui_overrideAccountLevel') > 0) then
			AccountProgression.level 																= 	GetCvarNumber('ui_overrideAccountLevel')
		else
			AccountProgression.level 																= 	tonumber(accountLevel)
		end
		AccountProgression.experienceToNextLevel, AccountProgression.percentToNextLevel 		= 	GetExperienceToNextLevel(AccountProgression.level, AccountProgression.experience)

		local petLevel, accountLevelForNextPetLevel 											=	GetPetAbilityLevel(AccountProgression.level)
		-- println('petLevel ' .. tostring(petLevel))
		-- println('accountLevelForNextPetLevel ' .. tostring(accountLevelForNextPetLevel))
		
		AccountProgression.petLevel 															= 	petLevel or 1
		
		local experienceToNextPetLevel, percentToNextPetLevel									=	GetExperienceToNextPetLevel(AccountProgression.level, accountLevelForNextPetLevel, AccountProgression.experience)
		
		AccountProgression.percentToNextPetLevel 												= percentToNextPetLevel 
		AccountProgression.accountLevelForNextPetLevel 											= accountLevelForNextPetLevel 
		 
		-- printr(mainUI.progressionData.accountValues.petLevelToAccountLevel)
		
		mainUI.savedRemotely = mainUI.savedRemotely or {}
		mainUI.savedRemotely.progression = mainUI.savedRemotely.progression or {}
		
		if (mainUI.savedRemotely.progression.lastExperience) then
			AccountProgression.lastExperience = mainUI.savedRemotely.progression.lastExperience
			AccountProgression.newExperience  = (AccountProgression.experience - mainUI.savedRemotely.progression.lastExperience)
		else
			AccountProgression.lastExperience = AccountProgression.experience
			AccountProgression.newExperience  = 0
		end
		
		if (mainUI.savedRemotely.progression.lastAccountLevel)  and (mainUI.savedRemotely.progression.lastAccountLevel < AccountProgression.level) then
			AccountProgression.lastLevel = mainUI.savedRemotely.progression.lastAccountLevel
			AccountProgression.newLevelUp = true
		else
			AccountProgression.lastLevel = AccountProgression.level
			AccountProgression.newLevelUp = false
		end		
			
		if (GetCvarBool('ui_testPostgame4')) then	
			AccountProgression.lastLevel = AccountProgression.level - 1
			AccountProgression.newLevelUp = true			
			AccountProgression.newExperience = 500
			AccountProgression.experience = AccountProgression.experience + 50
		end
		
		mainUI.savedRemotely.progression.lastExperience		= AccountProgression.experience
		mainUI.savedRemotely.progression.lastAccountLevel	= AccountProgression.level
		
		-- println('AccountProgression.level ' .. AccountProgression.level)
		-- println('AccountProgression.lastLevel ' .. AccountProgression.lastLevel)
		-- println('AccountProgression.newLevelUp ' .. tostring(AccountProgression.newLevelUp))
		-- println('AccountProgression.newExperience ' .. AccountProgression.newExperience)
		-- println('AccountProgression.experience ' .. AccountProgression.experience)
		-- println('AccountProgression.experienceToNextLevel ' .. AccountProgression.experienceToNextLevel)
		-- println('AccountProgression.percentToNextLevel ' .. AccountProgression.percentToNextLevel)
		-- println('AccountProgression.petLevel ' .. AccountProgression.petLevel)
		-- println('AccountProgression.percentToNextPetLevel ' .. AccountProgression.percentToNextPetLevel)		
		
		AccountProgression:Trigger(true)

	end
	
	local function SuperLegitAccountProgressionCalculation(wins)
		if (not wins) or (not tonumber(wins)) then
			return -1
		end			
		local tiers = {
			0, 10, 25,250,500,1000,100000000000000
		}
		for i,v in ipairs(tiers) do
			if (tonumber(wins) >= tonumber(v)) then
			
			else
				local currentTier = i - 1
				local winsOnCurrentTier = wins - tiers[i-1]
				local percentToNextTier = winsOnCurrentTier / (v - tiers[i-1])
				local progressTier = (currentTier + percentToNextTier) - 1
				return progressTier, math.ceil((v - tiers[i-1]) - winsOnCurrentTier)
			end
		end
	end
	
	local function SuperLegitHeroProgressionCalculation(wins)
		if (not wins) or (not tonumber(wins)) then
			return -1
		end			
		local tiers = {
			0, 3, 10,25,50,100,100000000000000
		}
		for i,v in ipairs(tiers) do
			if (tonumber(wins) >= tonumber(v)) then
			
			else
				local currentTier = i - 1
				local winsOnCurrentTier = wins - tiers[i-1]
				local percentToNextTier = winsOnCurrentTier / (v - tiers[i-1])
				local progressTier = (currentTier + percentToNextTier) - 1
				return progressTier, math.ceil((v - tiers[i-1]) - winsOnCurrentTier)	
			end
		end
	end		
	
	function mainUI.progression.UpdateStats(webResponse)
		-- println("^y UpdateStats ")
		-- printr(webResponse)

		if (not webResponse) or (not webResponse.identStats) or (not webResponse.identStats.stats) then
			SevereError('GetAccountStats - no stats', 'main_reconnect_thatsucks', '', nil, nil, false)
			return
		end

		if (not webResponse.identStats.stats.matchmakingIdentStats) then
			-- SevereError('GetAccountStats - no matchmakingIdentStats', 'main_reconnect_thatsucks', '', nil, nil, false)
			return
		end
		
		webResponse.identStats.stats.matchmakingIdentStats.winner = webResponse.identStats.stats.matchmakingIdentStats.winner or 0
		webResponse.identStats.stats.matchmakingIdentStats.games = webResponse.identStats.stats.matchmakingIdentStats.games or 0
		webResponse.identStats.stats.matchmakingIdentStats.kills = webResponse.identStats.stats.matchmakingIdentStats.kills or 0
		webResponse.identStats.stats.matchmakingIdentStats.assists = webResponse.identStats.stats.matchmakingIdentStats.assists or 0
		webResponse.identStats.stats.matchmakingIdentStats.deaths = webResponse.identStats.stats.matchmakingIdentStats.deaths or 0
		webResponse.identStats.stats.matchmakingIdentStats.gpm = webResponse.identStats.stats.matchmakingIdentStats.gpm or 0
		webResponse.identStats.stats.matchmakingIdentStats.creepKills = webResponse.identStats.stats.matchmakingIdentStats.creepKills or 0
		webResponse.identStats.stats.matchmakingIdentStats.bossKills = webResponse.identStats.stats.matchmakingIdentStats.bossKills or 0
		webResponse.identStats.stats.matchmakingIdentStats.buildingKills = webResponse.identStats.stats.matchmakingIdentStats.buildingKills or 0
		webResponse.identStats.stats.matchmakingIdentStats.heroDamage = webResponse.identStats.stats.matchmakingIdentStats.heroDamage or 0
		webResponse.identStats.stats.matchmakingIdentStats.killstreak = webResponse.identStats.stats.matchmakingIdentStats.killstreak or 0
		local matchmakingIdentStats = webResponse.identStats.stats.matchmakingIdentStats

		local rank, winsToNextRank = SuperLegitAccountProgressionCalculation(matchmakingIdentStats.winner or 0)
		
		mainUI.progression.stats.account = mainUI.progression.stats.account or {}
		mainUI.progression.stats.account['wins'] = tonumber(matchmakingIdentStats.winner or 0)
		mainUI.progression.stats.account['losses'] = tonumber(matchmakingIdentStats.winner or 0) - tonumber(matchmakingIdentStats.games or 0)
		mainUI.progression.stats.account['rank'] = rank
		mainUI.progression.stats.account['winsToNextRank'] = winsToNextRank

		local games = math.max(1, matchmakingIdentStats.games)
		
		mainUI.progression.stats.averageKillsAssists			= (matchmakingIdentStats.kills + matchmakingIdentStats.assists) / games
		mainUI.progression.stats.averageDeaths					= matchmakingIdentStats.deaths / games
		mainUI.progression.stats.averageGPM						= matchmakingIdentStats.gpm / games -- you read that right, this is the sum of all GPMs
		mainUI.progression.stats.winPercentage 					= matchmakingIdentStats.winner / games
		mainUI.progression.stats.averageCreepKills 				= matchmakingIdentStats.creepKills / games
		mainUI.progression.stats.averageBossKills 				= matchmakingIdentStats.bossKills / games
		mainUI.progression.stats.averageBuildingKills			= matchmakingIdentStats.buildingKills / games
		mainUI.progression.stats.averageHeroDamage				= matchmakingIdentStats.heroDamage / games
		mainUI.progression.stats.averageKillstreak				= matchmakingIdentStats.killstreak / games
		
		if (not webResponse.identStats.stats.matchmakingHeroStats) then
			SevereError('GetAccountStats - no matchmakingHeroStats', 'main_reconnect_thatsucks', '', nil, nil, false)
			return
		end
		
		local matchmakingHeroStats = webResponse.identStats.stats.matchmakingHeroStats
		
		mainUI.progression.stats.heroesMastered = 0
		
		local sortableHeroStats = {}
		for index, statTable in pairs(matchmakingHeroStats) do
			local heroEntity	= statTable.entityName
			if (heroEntity) and (not Empty(heroEntity)) and ValidateEntity(heroEntity) then
				mainUI.progression.stats.heroes[heroEntity] 						= mainUI.progression.stats.heroes[heroEntity] or {}		
				mainUI.progression.stats.heroes[heroEntity].details 				= statTable
				tinsert(sortableHeroStats, statTable)
			end
		end
		
		local function sortByStat(targetTable, tempTable, stat)
			if tempTable and (#tempTable > 0) then
				tsort(tempTable, function(a, b)
					if tonumber(a[stat]) and tonumber(b[stat]) and tonumber(a.games) and tonumber(b.games) then
						return (tonumber(a[stat]) / math.max(1, tonumber(a.games))) > (tonumber(b[stat]) / math.max(1, tonumber(b.games)))
					else
						return false
					end
				end)
				local bestValue = tonumber(tempTable[1][stat]) or 0
				local bestGames = tonumber(tempTable[1].games) or 0
				local value = bestValue / math.max(1, bestGames)
				if (value > 0) then
					tinsert(targetTable, {
						entity = tempTable[1].entityName,
						stat = stat, 
						value = value,
					})
				end
			end
			return tempTable
		end
		
		mainUI.progression.stats.best = {}
		sortableHeroStats = sortByStat(mainUI.progression.stats.best, sortableHeroStats, 'gpm')
		sortableHeroStats = sortByStat(mainUI.progression.stats.best, sortableHeroStats, 'killstreak')
		sortableHeroStats = sortByStat(mainUI.progression.stats.best, sortableHeroStats, 'kills')
		sortableHeroStats = sortByStat(mainUI.progression.stats.best, sortableHeroStats, 'assists')
		sortableHeroStats = sortByStat(mainUI.progression.stats.best, sortableHeroStats, 'winner')
		sortableHeroStats = sortByStat(mainUI.progression.stats.best, sortableHeroStats, 'creepKills')
		sortableHeroStats = sortByStat(mainUI.progression.stats.best, sortableHeroStats, 'apm')
		sortableHeroStats = sortByStat(mainUI.progression.stats.best, sortableHeroStats, 'bossKills')
		sortableHeroStats = sortByStat(mainUI.progression.stats.best, sortableHeroStats, 'buildingKills')
		sortableHeroStats = sortByStat(mainUI.progression.stats.best, sortableHeroStats, 'heroDamage')
		sortableHeroStats = sortByStat(mainUI.progression.stats.best, sortableHeroStats, 'creepKills')
		
		mainUI.progression.stats.catFacts = {}
		for tempIndex, tempTable in pairs(sortableHeroStats) do
			if (tempTable.entityName == 'Hero_Moxie') then
				sortByStat(mainUI.progression.stats.catFacts, {tempTable}, 'gpm')
				sortByStat(mainUI.progression.stats.catFacts, {tempTable}, 'kills')
				sortByStat(mainUI.progression.stats.catFacts, {tempTable}, 'assists')
				sortByStat(mainUI.progression.stats.catFacts, {tempTable}, 'winner')
				sortByStat(mainUI.progression.stats.catFacts, {tempTable}, 'killstreak')
				sortByStat(mainUI.progression.stats.catFacts, {tempTable}, 'creepKills')
				sortByStat(mainUI.progression.stats.catFacts, {tempTable}, 'apm')
				sortByStat(mainUI.progression.stats.catFacts, {tempTable}, 'bossKills')
				sortByStat(mainUI.progression.stats.catFacts, {tempTable}, 'buildingKills')
				sortByStat(mainUI.progression.stats.catFacts, {tempTable}, 'heroDamage')
				sortByStat(mainUI.progression.stats.catFacts, {tempTable}, 'creepKills')
			end
		end
		
		if (mainUI.progression.stats.catFacts) and (#mainUI.progression.stats.catFacts > 0) and ((math.random(1,50) == 1) or GetCvarBool('ui_dev_catfacts')) then
			mainUI.progression.stats.best = mainUI.progression.stats.catFacts
			Set('_ui_catfacts', 'true', 'bool')
		end
		
		-- Standard Rating

		mainUI 													= mainUI or {}
		mainUI.savedLocally 									= mainUI.savedLocally or {}
		mainUI.savedLocally.lib_compete 						= mainUI.savedLocally.lib_compete or {}								
		mainUI.savedLocally.lib_compete.heroRankings			= mainUI.savedLocally.lib_compete.heroRankings or {}														
					
		PostGame 																	= PostGame or {}
		PostGame.Splash 															= PostGame.Splash or {}		
		PostGame.Splash.modules 													= PostGame.Splash.modules or {}	
		PostGame.Splash.modules.standardPlayProgression								= PostGame.Splash.modules.standardPlayProgression or {}
		
		local matchmakingStats = webResponse.matchmakingStats
		
		if (matchmakingStats) and (matchmakingStats.rating0PerHeroPerMatchType) then
			for rating0index, rating0table in pairs(matchmakingStats.rating0PerHeroPerMatchType) do
				local heroEntity = rating0index
				if (heroEntity) and (not Empty(heroEntity)) and ValidateEntity(heroEntity) then
					
					mainUI 																		= mainUI or {}
					mainUI.savedLocally 														= mainUI.savedLocally or {}
					mainUI.savedLocally.lib_compete 											= mainUI.savedLocally.lib_compete or {}							
					mainUI.savedLocally.lib_compete.heroRankings[heroEntity]					= mainUI.savedLocally.lib_compete.heroRankings[heroEntity] or {}		
					
					PostGame 																	= PostGame or {}
					PostGame.Splash 															= PostGame.Splash or {}		
					PostGame.Splash.modules 													= PostGame.Splash.modules or {}	
					PostGame.Splash.modules.standardPlayProgression								= PostGame.Splash.modules.standardPlayProgression or {}					
					PostGame.Splash.modules.standardPlayProgression[heroEntity] 				= PostGame.Splash.modules.standardPlayProgression[heroEntity] or {}		
					
					local pvpRating0 = tonumber(rating0table.pvp) or 0
					pvpRating0 = pvpRating0 + 1500
					pvpRating0 = math.max(pvpRating0, 0)
					pvpRating0 = math.min(pvpRating0, 3000)
					pvpRating0 = math.ceil(pvpRating0)
					
					local pveRating0 = tonumber(rating0table.pve) or 0
					pveRating0 = pveRating0 + 1500
					pveRating0 = math.max(pveRating0, 0)
					pveRating0 = math.min(pveRating0, 3000)
					pveRating0 = math.ceil(pveRating0)
					
					if ((PostGame.Splash.modules.standardPlayProgression[heroEntity].lastpvpRating0) and (PostGame.Splash.modules.standardPlayProgression[heroEntity].lastpvpRating0 ~= pvpRating0)) or ((PostGame.Splash.modules.standardPlayProgression[heroEntity].lastpveRating0) and (PostGame.Splash.modules.standardPlayProgression[heroEntity].lastpveRating0 ~= pveRating0)) then
						trigger_postGameLoopStatus.standardProgressAvailable	 	= true
						trigger_postGameLoopStatus:Trigger(false)
					end					
					
					mainUI.progression.stats.heroes[heroEntity] 									= mainUI.progression.stats.heroes[heroEntity] or {}
					mainUI.progression.stats.heroes[heroEntity]['pvpRating0'] 						= pvpRating0
					mainUI.progression.stats.heroes[heroEntity]['pveRating0'] 						= pveRating0
					
					PostGame.Splash.modules.standardPlayProgression[heroEntity].lastpvpRating0 		= mainUI.savedLocally.lib_compete.heroRankings[heroEntity].lastpvpRating0 or pvpRating0
					PostGame.Splash.modules.standardPlayProgression[heroEntity].lastpveRating0 		= mainUI.savedLocally.lib_compete.heroRankings[heroEntity].lastpveRating0 or pveRating0
					mainUI.savedLocally.lib_compete.heroRankings[heroEntity].lastpvpRating0 			= pvpRating0 
					mainUI.savedLocally.lib_compete.heroRankings[heroEntity].lastpveRating0 			= pveRating0 

				end			
			end
		end

		local winsReq 		= GetCvarNumber('ui_standardMatchesRequired', true) or 5
		
		if (matchmakingStats) and (matchmakingStats.totalWinsPerHeroPerMatchType) then
			mainUI.progression.stats.heroesMastered = 0
			for heroEntity, winsPerGameTypeTable in pairs(matchmakingStats.totalWinsPerHeroPerMatchType) do
				if (heroEntity) and (not Empty(heroEntity)) and ValidateEntity(heroEntity) then	

					PostGame 																	= PostGame or {}
					PostGame.Splash 															= PostGame.Splash or {}		
					PostGame.Splash.modules 													= PostGame.Splash.modules or {}	
					PostGame.Splash.modules.standardPlayProgression								= PostGame.Splash.modules.standardPlayProgression or {}					
					PostGame.Splash.modules.standardPlayProgression[heroEntity] 				= PostGame.Splash.modules.standardPlayProgression[heroEntity] or {}		
					
					local pvpWins = tonumber(winsPerGameTypeTable.pvp) or 0			
					local pveWins = tonumber(winsPerGameTypeTable.pve) or 0			
					
					mainUI.progression.stats.heroes[heroEntity] 								= mainUI.progression.stats.heroes[heroEntity] or {}
					mainUI.progression.stats.heroes[heroEntity]['pvpWins'] 						= pvpWins
					mainUI.progression.stats.heroes[heroEntity]['pveWins'] 						= pveWins
					mainUI.progression.stats.heroes[heroEntity]['wins'] 						= pvpWins + pveWins
					
					mainUI.progression.stats.heroes[heroEntity]['standard_provMatchesRem'] 		= winsReq - (pvpWins + pveWins)

					local rank, winsToNextRank = SuperLegitHeroProgressionCalculation((pvpWins or 0) + (pveWins or 0))
					if rank >= 5 then
						mainUI.progression.stats.heroesMastered = mainUI.progression.stats.heroesMastered + 1
					end						
					
					mainUI.progression.stats.heroes[heroEntity]['rank'] 				= rank
					mainUI.progression.stats.heroes[heroEntity]['winsToNextRank'] 		= winsToNextRank						
					
				end			
			end
		end		
		
		if (matchmakingStats) and (matchmakingStats.totalLossesPerHeroPerMatchType) then
			for heroEntity, lossesPerGameTypeTable in pairs(matchmakingStats.totalLossesPerHeroPerMatchType) do
				if (heroEntity) and (not Empty(heroEntity)) and ValidateEntity(heroEntity) then		
					
					PostGame 																	= PostGame or {}
					PostGame.Splash 															= PostGame.Splash or {}		
					PostGame.Splash.modules 													= PostGame.Splash.modules or {}	
					PostGame.Splash.modules.standardPlayProgression								= PostGame.Splash.modules.standardPlayProgression or {}					
					PostGame.Splash.modules.standardPlayProgression[heroEntity] 				= PostGame.Splash.modules.standardPlayProgression[heroEntity] or {}		
					
					local pvpLosses = tonumber(lossesPerGameTypeTable.pvp) or 0			
					local pveLosses = tonumber(lossesPerGameTypeTable.pve) or 0			
					
					mainUI.progression.stats.heroes[heroEntity] 									= mainUI.progression.stats.heroes[heroEntity] or {}
					mainUI.progression.stats.heroes[heroEntity]['pvpLosses'] 						= pvpLosses
					mainUI.progression.stats.heroes[heroEntity]['pveLosses'] 						= pveLosses
					mainUI.progression.stats.heroes[heroEntity]['losses'] 							= pvpLosses + pveLosses

				end			
			end
		end			
		
		if (matchmakingStats) and (matchmakingStats.totalWinsPerMatchType) and (matchmakingStats.totalWinsPerMatchType.pvp) then
			local pvpWins = tonumber(matchmakingStats.totalWinsPerMatchType.pvp) or 0
			mainUI.progression.stats.account.pvpWins = pvpWins
		end			
		
		if (matchmakingStats) and (matchmakingStats.totaLossesPerMatchType) and (matchmakingStats.totaLossesPerMatchType.pvp) then
			local pvpLosses = tonumber(matchmakingStats.totaLossesPerMatchType.pvp) or 0
			mainUI.progression.stats.account.pvpLosses = pvpLosses
		end				
		
		if (matchmakingStats) and (matchmakingStats.totalWinsPerMatchType) and (matchmakingStats.totalWinsPerMatchType.pve) then
			local pveWins = tonumber(matchmakingStats.totalWinsPerMatchType.pve) or 0
			mainUI.progression.stats.account.pveWins = pveWins
		end			
		
		if (matchmakingStats) and (matchmakingStats.totaLossesPerMatchType) and (matchmakingStats.totaLossesPerMatchType.pve) then
			local pveLosses = tonumber(matchmakingStats.totaLossesPerMatchType.pve) or 0
			mainUI.progression.stats.account.pveLosses = pveLosses
		end			

		if (matchmakingStats) and (matchmakingStats.rating0PerMatchType) then

			local pvpWins = 0
			if (mainUI.progression) and (mainUI.progression.stats) and (mainUI.progression.stats.account) and (mainUI.progression.stats.account.pvpWins) then
				pvpWins = mainUI.progression.stats.account.pvpWins
			end
			
			local pveWins = 0
			if (mainUI.progression) and (mainUI.progression.stats) and (mainUI.progression.stats.account) and (mainUI.progression.stats.account.pveWins) then
				pveWins = mainUI.progression.stats.account.pveWins
			end			

			mainUI 													= mainUI or {}
			mainUI.savedLocally 									= mainUI.savedLocally or {}
			mainUI.savedLocally.lib_compete 						= mainUI.savedLocally.lib_compete or {}			
			mainUI.savedLocally.lib_compete.account 				= mainUI.savedLocally.lib_compete.account or {}									
			
			local pvpRating0 = tonumber(matchmakingStats.rating0PerMatchType.pvp) or 0
			pvpRating0 = pvpRating0 + 1500
			pvpRating0 = math.max(pvpRating0, 0)
			pvpRating0 = math.min(pvpRating0, 3000)
			pvpRating0 = math.ceil(pvpRating0)

			local pveRating0 = tonumber(matchmakingStats.rating0PerMatchType.pve) or 0
			pveRating0 = pveRating0 + 1500
			pveRating0 = math.max(pveRating0, 0)
			pveRating0 = math.min(pveRating0, 3000)
			pveRating0 = math.ceil(pveRating0)			
			
			local eloToDivision = {	
				{	-- 99% -> 100%
					winRequirement = 300,
					minimumRating = 2230,
					promoteAtRating = 2260,					
					key		= 'diamond',
					icon	= '/ui/main/shared/textures/elo_rank_5.tga',
				},
				{	-- 90% -> 99%
					winRequirement = 50,
					minimumRating = 1639,
					promoteAtRating = 1669,				
					key		= 'gold',
					icon	= '/ui/main/shared/textures/elo_rank_4.tga',
				},	
				{	-- 70% -> 90%
					winRequirement = 25,
					minimumRating =  1535,
					promoteAtRating = 1555,
					key		= 'silver',
					icon	= '/ui/main/shared/textures/elo_rank_3.tga',
				},	
				{	-- 30% -> 70%
					winRequirement = 5,
					minimumRating = 1422,
					promoteAtRating = 1452,					
					key		= 'bronze',
					icon	= '/ui/main/shared/textures/elo_rank_2.tga',
				},				
				{	-- 0% -> 30%
					winRequirement = 5,
					minimumRating = 0,																																							
					promoteAtRating = 0,
					key		= 'slate',
					icon	= '/ui/main/shared/textures/elo_rank_1.tga',
				},
				{	-- Less than 5 wins
					winRequirement = 0,
					minimumRating = 0,																																							
					promoteAtRating = 0,
					maximumRating = 10000,					
					key		= 'provisional',
					icon	= '/ui/main/shared/textures/elo_rank_0.tga',
				},
			}			
			
			local division = 'provisional'
			local divisionIndex = #eloToDivision
			local lastDivision = mainUI.savedLocally.lib_compete.account.division or 'provisional'	
			local lastDivisionIndex = #eloToDivision
			
			for i,divisionTable in ipairs(eloToDivision) do			
				if (divisionTable.key == lastDivision) then
					lastDivisionIndex = i
					break
				end
			end
			
			for i,divisionTable in ipairs(eloToDivision) do
				if (pvpWins >= divisionTable.winRequirement) then
					if (pvpRating0 >= divisionTable.minimumRating) then
						if (pvpRating0 >= divisionTable.promoteAtRating) or (divisionTable.key == lastDivision) then
							division = divisionTable.key
							divisionIndex = i
							break						
						end				
					end
				end
			end

			local status = ''
			if (divisionIndex) and (lastDivisionIndex) then
				if (division == 'provisional') then
					status = 'provisional'
				elseif (divisionIndex < lastDivisionIndex) then
					status = 'promoted'
				elseif (divisionIndex > lastDivisionIndex) then
					status = 'demoted'
				end
			end
			
			mainUI.progression.stats.account.lastDivision 				= mainUI.savedLocally.lib_compete.account.division or division
			mainUI.progression.stats.account.division 					= division
			mainUI.progression.stats.account.divisionIndex 				= divisionIndex
			mainUI.savedLocally.lib_compete.account.division 			= division			
			
			mainUI.progression.stats.account.lastpvpRating0 			= mainUI.savedLocally.lib_compete.account.pvpRating0 or pvpRating0
			mainUI.progression.stats.account.pvpRating0 				= pvpRating0
			mainUI.savedLocally.lib_compete.account.pvpRating0 			= pvpRating0
			
			mainUI.progression.stats.account.lastpveRating0 			= mainUI.savedLocally.lib_compete.account.pveRating0 or pveRating0
			mainUI.progression.stats.account.pveRating0 				= pveRating0
			mainUI.savedLocally.lib_compete.account.pveRating0 			= pveRating0			
			
			local winsReq  = GetCvarNumber('ui_rankedMatchesRequired', true) or 5
			
			PostGame 													= PostGame or {}
			PostGame.Splash 											= PostGame.Splash or {}
			PostGame.Splash.modules										= PostGame.Splash.modules or {}
			PostGame.Splash.modules.rankedPlayProgression 				= PostGame.Splash.modules.rankedPlayProgression or {}
			PostGame.Splash.modules.rankedPlayProgression.lastDivision 	= lastDivision or 'provisional'			
			PostGame.Splash.modules.rankedPlayProgression.lastDivisionIndex = lastDivisionIndex or #eloToDivision
			PostGame.Splash.modules.rankedPlayProgression.division 		= division or lastDivision or 'provisional'			
			PostGame.Splash.modules.rankedPlayProgression.divisionIndex = divisionIndex or #eloToDivision
			PostGame.Splash.modules.rankedPlayProgression.status 		= status		
			PostGame.Splash.modules.rankedPlayProgression.wins 			= pvpWins
			PostGame.Splash.modules.rankedPlayProgression.winsReq 		= winsReq
			
			if (GetCvarNumber('ui_testRankedProgression') == 1) then
				PostGame.Splash.modules.rankedPlayProgression.lastDivision 	= 'provisional'			
				PostGame.Splash.modules.rankedPlayProgression.lastDivisionIndex = #eloToDivision
				PostGame.Splash.modules.rankedPlayProgression.division 		= 'provisional'			
				PostGame.Splash.modules.rankedPlayProgression.divisionIndex = #eloToDivision
				PostGame.Splash.modules.rankedPlayProgression.status 		= 'provisional'		
				PostGame.Splash.modules.rankedPlayProgression.wins 			= 3
				PostGame.Splash.modules.rankedPlayProgression.winsReq 		= 5			
			elseif (GetCvarNumber('ui_testRankedProgression') == 2) then
				PostGame.Splash.modules.rankedPlayProgression.lastDivision 	= 'provisional'			
				PostGame.Splash.modules.rankedPlayProgression.lastDivisionIndex = #eloToDivision
				PostGame.Splash.modules.rankedPlayProgression.division 		= 'slate'			
				PostGame.Splash.modules.rankedPlayProgression.divisionIndex = 5
				PostGame.Splash.modules.rankedPlayProgression.status 		= 'promoted'		
				PostGame.Splash.modules.rankedPlayProgression.wins 			= 5
				PostGame.Splash.modules.rankedPlayProgression.winsReq 		= 5		
			elseif (GetCvarNumber('ui_testRankedProgression') == 3) then
				PostGame.Splash.modules.rankedPlayProgression.lastDivision 	= 'slate'			
				PostGame.Splash.modules.rankedPlayProgression.lastDivisionIndex = 5
				PostGame.Splash.modules.rankedPlayProgression.division 		= 'bronze'			
				PostGame.Splash.modules.rankedPlayProgression.divisionIndex = 4
				PostGame.Splash.modules.rankedPlayProgression.status 		= 'promoted'		
				PostGame.Splash.modules.rankedPlayProgression.wins 			= 5
				PostGame.Splash.modules.rankedPlayProgression.winsReq 		= 5		
			elseif (GetCvarNumber('ui_testRankedProgression') == 4) then
				PostGame.Splash.modules.rankedPlayProgression.lastDivision 	= 'bronze'			
				PostGame.Splash.modules.rankedPlayProgression.lastDivisionIndex = 4
				PostGame.Splash.modules.rankedPlayProgression.division 		= 'silver'			
				PostGame.Splash.modules.rankedPlayProgression.divisionIndex = 3
				PostGame.Splash.modules.rankedPlayProgression.status 		= 'promoted'		
				PostGame.Splash.modules.rankedPlayProgression.wins 			= 50
				PostGame.Splash.modules.rankedPlayProgression.winsReq 		= 5		
			elseif (GetCvarNumber('ui_testRankedProgression') == 5) then
				PostGame.Splash.modules.rankedPlayProgression.lastDivision 	= 'silver'			
				PostGame.Splash.modules.rankedPlayProgression.lastDivisionIndex = 3
				PostGame.Splash.modules.rankedPlayProgression.division 		= 'gold'			
				PostGame.Splash.modules.rankedPlayProgression.divisionIndex = 2
				PostGame.Splash.modules.rankedPlayProgression.status 		= 'promoted'		
				PostGame.Splash.modules.rankedPlayProgression.wins 			= 100
				PostGame.Splash.modules.rankedPlayProgression.winsReq 		= 5			
			elseif (GetCvarNumber('ui_testRankedProgression') == 6) then
				PostGame.Splash.modules.rankedPlayProgression.lastDivision 	= 'gold'			
				PostGame.Splash.modules.rankedPlayProgression.lastDivisionIndex = 2
				PostGame.Splash.modules.rankedPlayProgression.division 		= 'diamond'			
				PostGame.Splash.modules.rankedPlayProgression.divisionIndex = 1
				PostGame.Splash.modules.rankedPlayProgression.status 		= 'promoted'		
				PostGame.Splash.modules.rankedPlayProgression.wins 			= 500
				PostGame.Splash.modules.rankedPlayProgression.winsReq 		= 5					
			elseif (GetCvarNumber('ui_testRankedProgression') == 7) then
				PostGame.Splash.modules.rankedPlayProgression.lastDivision 	= 'diamond'			
				PostGame.Splash.modules.rankedPlayProgression.lastDivisionIndex = 1
				PostGame.Splash.modules.rankedPlayProgression.division 		= 'gold'			
				PostGame.Splash.modules.rankedPlayProgression.divisionIndex = 2
				PostGame.Splash.modules.rankedPlayProgression.status 		= 'demoted'		
				PostGame.Splash.modules.rankedPlayProgression.wins 			= 500
				PostGame.Splash.modules.rankedPlayProgression.winsReq 		= 5							
			end
			
		end		
		
		GetTrigger('AccountProgression'):Trigger(true)		

	end
	
	mainUI.progression = mainUI.progression or {}
	mainUI.progression.progressionLoaded = false
	UnwatchLuaTriggerByKey('mainPanelStatus', 'mainPanelStatusProgressionKey')
	WatchLuaTrigger('mainPanelStatus', function(trigger)
		if (IsFullyLoggedIn(GetIdentID())) then
			if (mainUI) and (mainUI.progression) and (not mainUI.progression.progressionLoaded) and (GetAccountLevelToExperience() and (#GetAccountLevelToExperience() > 0)) then			
				mainUI.progression.progressionLoaded = true
				local successFunction =  function (request)	-- response handler
					local responseData = request:GetBody()
					if responseData == nil or (not responseData.ident_id) then
						mainUI.progression.progressionLoaded = false
						println('^r mainUI.progression.progressionLoaded ' .. tostring(mainUI.progression.progressionLoaded) )
						SevereError('GetAccountStats - no response data', 'main_reconnect_thatsucks', '', nil, nil, false)
						trigger_postGameLoopStatus.requestingAccountProgress = false	
						ProgressionLoadStateTrigger.stateLoaded = false
						ProgressionLoadStateTrigger:Trigger(false)							
						return nil
					else
						mainUI.progression.progressionLoaded = true
						println('^g mainUI.progression.progressionLoaded ' .. tostring(mainUI.progression.progressionLoaded) )
						
						-- Ladder in profile
						if (Profile) and (Profile.UpdateLadder) then
							Profile.UpdateLadder(responseData)
							-- println('^g UpdateLadder Updated')
						else
							println('^r UpdateLadder Not Updated')
						end						
						
						-- Self Profile
						if (Profile) and (Profile.UpdateProfile) then
							Profile.UpdateProfile(responseData)
							-- println('^g Profile Updated')
						else
							println('^r Profile Not Updated')
						end
						
						-- Account progression (Hero mastery, stats, and standard mode rating)
						if (mainUI) and (mainUI.progression) and (mainUI.progression.UpdateStats) then
							mainUI.progression.UpdateStats(responseData)
							-- println('^g Progression UpdateStats Updated')
						else
							println('^r Progression UpdateStats Not Updated')
						end
						
						-- Ranked Play Hero
						if (libCompete) and (libCompete.ranked) and (libCompete.ranked.populateHeroRank) and (responseData.rankedHeroRatings) and type(responseData.rankedHeroRatings) == 'table' then
							for i, v in pairs(responseData.rankedHeroRatings) do
								libCompete.ranked.populateHeroRank(i, v.division, v.rank, v.wins, v.gamesAboveBracket, v.gamesBelowBracket, v.seasonWins, v.seasonLosses)
							end
							-- println('^g rankedHeroRatings Updated')
						else
							println('^r rankedHeroRatings Not Updated')
						end
						
						-- Ranked Play Account (Is this actually a thing? RMM)
						if (libCompete) and (libCompete.ranked) and (libCompete.ranked.populateRank) and (responseData.rankedRating) and type(responseData.rankedRating) == 'table' then
							libCompete.ranked.populateRank(responseData.rankedRating.division, tonumber(responseData.rankedRating.rank))
							-- println('^g populateRank Updated')
						else
							-- println('^r populateRank Not Updated')
						end						
						
						-- Quests
						if (Quests) and (Quests.QuestData) then
							Quests.QuestData(responseData)
							-- println('^g QuestData Updated')
						else
							println('^r QuestData Not Updated')
						end
						
						-- RAF
						if (Profile) and (Profile.UpdateReferralCode) then
							Profile.UpdateReferralCode(responseData)
							-- println('^g UpdateReferralCode Updated')
						else
							println('^r UpdateReferralCode Not Updated')
						end
						
						-- Khanquest
						if (playerProfile_khanquest) and (playerProfile_khanquest.loadProfileSuccess) then
							playerProfile_khanquest.loadProfileSuccess(responseData)
							-- println('^g playerProfile_khanquest loadProfileSuccess Updated')
						else
							println('^r playerProfile_khanquest loadProfileSuccess Not Updated')
						end
						
						SaveState()
						
						mainUI.progression.UpdateProgression()
						
						trigger_postGameLoopStatus.requestingAccountProgress = false							
						
						ProgressionLoadStateTrigger.stateLoaded = true
						ProgressionLoadStateTrigger:Trigger(false)
						
						return true
					end
				end
				
				local failFunction =  function (request)	-- error handler
					mainUI.progression.progressionLoaded = false
					println('^r mainUI.progression.progressionLoaded ' .. tostring(mainUI.progression.progressionLoaded) )					
					SevereError('GetAccountStats Request Error: ' .. Translate(request:GetError()), 'main_reconnect_thatsucks', '', nil, nil, false)
					trigger_postGameLoopStatus.requestingAccountProgress = false	
					ProgressionLoadStateTrigger.stateLoaded = false
					ProgressionLoadStateTrigger:Trigger(false)					
					return nil
				end	
				
				trigger_postGameLoopStatus.requestingAccountProgress = true
				ProgressionLoadStateTrigger.stateLoaded = false
				ProgressionLoadStateTrigger:Trigger(false)	
					
				Strife_Web_Requests:GetAllIdentityData(successFunction, failFunction)	
				
				-- local ladderSuccessFunction =  function (request)	-- response handler
					-- local responseData = request:GetBody()
					-- local responseError = request:GetError()
					-- println('^y Ladder Response')
					-- printr(responseData)
					-- printr(responseError)
				-- end
				
				-- local ladderFailFunction = function(request)
					-- local responseData = request:GetBody()
					-- local responseError = request:GetError()
					-- println('^r Ladder Response Error')
					-- printr(responseData)
					-- printr(responseError)
				-- end
				
				-- Strife_Web_Requests:GetLadder(ladderSuccessFunction, ladderFailFunction)				
			end
			
			if (mainUI) and (mainUI.progression) and (mainUI.progression.UpdateProgression) then
				mainUI.progression.UpdateProgression()
			end
		else
			mainUI.progression.progressionLoaded = false
		end
	end, 'mainPanelStatusProgressionKey', 'hasIdent', 'isLoggedIn', 'isAutoLogin', 'main')
	
	UnwatchLuaTriggerByKey('AccountInfo', 'AccountInfoProgressionKey')
	WatchLuaTrigger('AccountInfo', function(trigger) 
		if (trigger.isIdentPopulated) then
			if (mainUI) and (mainUI.progression) and (mainUI.progression.UpdateProgression) then
				mainUI.progression.UpdateProgression()
			end
		end
	end, 'AccountInfoProgressionKey')	
	
	UnwatchLuaTriggerByKey('UnclaimedRewards', 'UnclaimedRewardsUpdatedProgressionKey')
	WatchLuaTrigger('UnclaimedRewards', function(trigger) 
		if (mainUI) and (mainUI.progression) and (mainUI.progression.UpdateProgression) then
			mainUI.progression.UpdateProgression()
		end
	end, 'UnclaimedRewardsUpdatedProgressionKey')	
	
	UnwatchLuaTriggerByKey('PartyStatus', 'PartyStatusUpdatedProgressionKey')
	WatchLuaTrigger('PartyStatus', function(trigger) 
		if (mainUI) and (mainUI.progression) and (mainUI.progression.UpdateProgression) then
			mainUI.progression.UpdateProgression()
		end
	end, 'PartyStatusUpdatedProgressionKey', 'inParty')
	
	
	-- Hero Unlocks
	mainUI 															= mainUI or {}
	mainUI.progressionData 											= mainUI.progressionData or {}
	mainUI.progressionData.accountValues 							= mainUI.progressionData.accountValues or {}
	mainUI.progressionData.accountValues.heroUnlockProgressionTable = {}
	
	-- local function HideSecretIdentity()
		-- local heroBundlesWithSecretNinja = {}
		-- for i,v in pairs(mainUI.progressionData.accountValues.heroUnlockProgressionTable) do
			-- if (not v.unlocked) and (v.unlockLevel) and (not heroBundlesWithSecretNinja[v.unlockLevel]) then
				-- heroBundlesWithSecretNinja[v.unlockLevel] = true
				-- mainUI.progressionData.accountValues.heroUnlockProgressionTable[i].isSecretCharacter = true
			-- end
		-- end
		-- heroBundlesWithSecretNinja = nil
	-- end
	
	local function GetHeroUnlockProgression(numHeroUnlockLevels)
		local numHeroUnlockLevels = numHeroUnlockLevels or 0
		if (numHeroUnlockLevels) and (numHeroUnlockLevels > 0) then
			for numHeroes=0,numHeroUnlockLevels-1,1 do
				local heroUnlockLevelTrigger = GetTrigger('HeroUnlockLevel' .. numHeroes)
				
				if (heroUnlockLevelTrigger) then
				
					mainUI.progressionData.accountValues.heroUnlockProgressionTable[heroUnlockLevelTrigger.entity] = {}
					mainUI.progressionData.accountValues.heroUnlockProgressionTable[heroUnlockLevelTrigger.entity].entity = heroUnlockLevelTrigger.entity
					mainUI.progressionData.accountValues.heroUnlockProgressionTable[heroUnlockLevelTrigger.entity].unlockLevel = heroUnlockLevelTrigger.unlockLevel
					mainUI.progressionData.accountValues.heroUnlockProgressionTable[heroUnlockLevelTrigger.entity].unlocked = heroUnlockLevelTrigger.unlocked
					
					UnwatchLuaTriggerByKey(('HeroUnlockLevel' .. numHeroes), 'AccountInfoHeroUnlockProgressionKey')
					
					WatchLuaTrigger(('HeroUnlockLevel' .. numHeroes), function(heroUnlockLevelTrigger) 
						mainUI.progressionData.accountValues.heroUnlockProgressionTable[heroUnlockLevelTrigger.entity] = {}
						mainUI.progressionData.accountValues.heroUnlockProgressionTable[heroUnlockLevelTrigger.entity].entity = heroUnlockLevelTrigger.entity
						mainUI.progressionData.accountValues.heroUnlockProgressionTable[heroUnlockLevelTrigger.entity].unlockLevel = heroUnlockLevelTrigger.unlockLevel
						mainUI.progressionData.accountValues.heroUnlockProgressionTable[heroUnlockLevelTrigger.entity].unlocked = heroUnlockLevelTrigger.unlocked
					end, 'AccountInfoHeroUnlockProgressionKey')
				
				end
			end
		end
	end
	
	if (RMM_ENABLE_HERO_UNLOCKS) then
		UnwatchLuaTriggerByKey('AccountInfo', 'AccountInfoHeroUnlockProgressionKey')
		WatchLuaTrigger('AccountInfo', function(trigger) 
			GetHeroUnlockProgression(trigger.numHeroUnlockLevels)
		end, 'AccountInfoHeroUnlockProgressionKey', 'numHeroUnlockLevels')	
	end
	
	function mainUI.progressionData.CanAccessHero(heroEntity)
		local canAccess, requiredLevel, isSecretCharacter = false, -1, false
		if (heroEntity) and (not Empty(heroEntity)) and (ValidateEntity(heroEntity)) and (mainUI.progressionData) and (mainUI.progressionData.accountValues) and (mainUI.progressionData.accountValues.heroUnlockProgressionTable) and (mainUI.progressionData.accountValues.heroUnlockProgressionTable[heroEntity]) then
			canAccess = mainUI.progressionData.accountValues.heroUnlockProgressionTable[heroEntity].unlocked
			requiredLevel = mainUI.progressionData.accountValues.heroUnlockProgressionTable[heroEntity].unlockLevel
			-- isSecretCharacter = mainUI.progressionData.accountValues.heroUnlockProgressionTable[heroEntity].isSecretCharacter
		end
		if (requiredLevel >= 0) then
			return canAccess, requiredLevel, nil, false
		else
			return true, requiredLevel, 'No Hero Match', false
		end
	end	
	
end
ProgressionRegister()
