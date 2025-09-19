-- Team bot brain logic

runfile "/bots/globals.lua"
runfile "/bots/btree.lua"
runfile "/bots/teambotbrain/teamtargets.lua"

local object = getfenv(0).object

TeamBot = {}

function TeamBot.Create(object)
	local self = BTree.Create(object)
	ShallowCopy(TeamBot, self)

	self.needDifficultySet = true

	self.teamBots = {}
	self.krytosState = KRYTOS_INACTIVE

	local filename = "/bots/" .. Game.GetWorldName() .. ".botmetadata"
	Echo("Bot metadata file: " .. filename)
	BotMetaData.RegisterLayer(filename)
	BotMetaData.SetActiveLayer(filename)

	local parms = { team = self:GetTeam(), type = "well" }
	local t = BotMetaData.FindNodesWithProperties(parms)
	self:RegisterWellEntity(t[1]:GetProperty("unit"))
	
	return self
end

function TeamBot:AddTeamTarget(name, type, info, state, lane, prereqs, count, gathernode)
	local target = {}

	target.name = name
	target.level = info.level
	
	if target.level == nil then
		target.level = 1
	end

	target.base_priority = info.priority
	target.priority = target.base_priority
	target.base_min = info.attackers
	target.state = TTS_INVALID
	target.type = state
	target.nodeType = type
	target.lane = lane
	target.prereqs = prereqs
	target.prereqCount = count
	target.initialGatherNode = gathernode

	if info.scriptvar ~= nil then
		GameInfo.SetScriptValue(info.scriptvar, "0", true)
		target.scriptvar = info.scriptvar
	end

	table.insert(self.teamTargets, target)

	return target
end

function TeamBot:AddDefensiveTeamTarget(name, type, info, state, lane, prereqs)
	local target = {}

	target.name = name
	target.level = info.defend_level

	if target.level == nil then
		target.level = 1
	end

	target.base_priority = info.defend_priority
	target.priority = target.base_priority
	target.base_min = 1
	target.state = TTS_INVALID
	target.type = state
	target.nodeType = type
	target.lane = lane
	if lane == nil then
		Echo(name .. " has nil lane")
	end
	target.prereqs = prereqs
	target.prereqCount = count
	target.initialGatherNode = gathernode

	table.insert(self.teamTargets, target)

	return target
end

function TeamBot:Choose_Root()
	self:UpdateDifficulty()
	self:UpdateAwareness()

	local phase = Game.GetGamePhase()
	if phase == GAME_PHASE_ACTIVE then
		return "Match"
	end

	return "Idle"
end

function TeamBot:onthink()
	BTree.onthink(self)

	if Cvar.GetCvar("sv_botDebugTeamTargets"):GetNumber() == self:GetTeam() then
		if self.coDebug == nil or coroutine.status(self.coDebug) == "dead" then
			self.coDebug = coroutine.create(self.DebugTeamTargets)
		end

		local ok, message = coroutine.resume(self.coDebug, self)
		if not ok then
			Echo(message)
		end
	end
end

function TeamBot:State_Idle()

end

function TeamBot:DeactivateTarget(target)
--	Echo("Deactivating target: " .. target.name)

	for name,bot in pairs(self.teamBots) do
		bot:ClearTeamTarget(target)
	end

	target.state = TTS_DORMANT
	if target.timeout ~= nil then
		target.timeout = nil
		target.nextTime = Game.GetGameTime() + 90000
	end
	if target.type ~= T3_ASSIST then
		target.unit = nil
		target.gatherNode = nil
	end
end

function TeamBot:UpdateDifficulty()
	if self.needDifficultySet then
		self:SetupDifficulty()

		local teamID = self:GetTeam()
		local parms = { team = teamID }

		parms["type"] = "tower"
		parms["team"] = "*"
		parms["lane"] = "*"
		parms["lane_index"] = "*"
		t = BotMetaData.FindNodesWithProperties(parms)
		local lane = {}
		for index,node in ipairs(t) do
			self:RegisterTowerEntity(node:GetProperty("lane"), node:GetProperty("unit"), node:GetProperty("lane_index"))
		end

		parms = { type = "base", unit = "*", team = "*" }
		t = BotMetaData.FindNodesWithProperties(parms)
		for index,node in ipairs(t) do
			if node:GetProperty("team") == teamID then
				self:RegisterBaseEntity(node:GetProperty("unit"), true)
			else
				self:RegisterBaseEntity(node:GetProperty("unit"), false)

				self.enemyBasePosition = node:GetPosition()
				local range = node:GetProperty("outerrange")
				if range == nil then
					self.enemyBaseMaxSq = 0
				else
					self.enemyBaseMaxSq = range ^ 2
				end

				local range = node:GetProperty("innerrange")
				if range == nil then
					self.enemyBaseMinSq = 0
				else
					self.enemyBaseMinSq = range ^ 2
				end
			end
		end

		parms = { team_target = "*" }
		self.teamTargets = {}
		t = BotMetaData.FindNodesWithProperties(parms)
		Echo("Targets: " .. self:GetTeamTargetType())
		local targets = TeamTargetProperties[self:GetTeamTargetType()]
		for index,node in ipairs(t) do
			local targetType = node:GetProperty("team_target")
			local targetInfo = targets[targetType]
			if targetInfo == nil then
				Echo("Warning, unknown team target type '" .. targetType .. "', ignoring!")
			else
				local team = node:GetProperty("team")
				if team ~= teamID then
					local type = node:GetProperty("type")
					local state = nil
					if type == "tower" or type == "base" then
						state = T3_PUSH_LANE
					else
						state = T3_ATTACK_TARGET
					end

--					Echo("Attack Target:  " .. node:GetProperty("unit") .. ", type: " .. targetType .. ", reqlevel: " .. targetInfo.level)
					self:AddTeamTarget(node:GetProperty("unit"), node:GetProperty("type"), targetInfo, state, node:GetProperty("lane"), node:GetProperty("team_target_prereq"), node:GetProperty("team_target_prereq_count"), node:GetProperty("initial_gather_node"))
				else
--					Echo("Defend Target:  " .. node:GetProperty("unit") .. ", type: " .. targetType .. ", reqlevel: " .. targetInfo.level)
					local name = node:GetProperty("unit")
					if targetInfo.defend_priority ~= nil then
						self:AddDefensiveTeamTarget(node:GetProperty("unit"), node:GetProperty("type"), targetInfo, T3_DEFEND_TARGET, node:GetProperty("lane"), node:GetProperty("team_target_prereq"))
					end
				end
			end
		end

		parms = { escape = true, lane = "*", team = teamID }
		self.escapeNodes = {}
		t = BotMetaData.FindNodesWithProperties(parms)
		for index,node in ipairs(t) do
			self.escapeNodes[node:GetProperty("lane")] = node
		end

		self:AddTeamTarget("LanePusher", "LanePusher", targets.krytos, T3_LANEPUSHER)

		self.needDifficultySet = false
		self.needAssistUpdate = true
	end

	if self.needAssistUpdate then
		local heroes = Game.GetHeroes(self:GetTeam())
		if #heroes > 0 then
			-- Remove any existing assist targets
			for index,target in ipairs(self.teamTargets) do
				if target.type == T3_ASSIST then
					self:RemoveTarget(target)
				end
			end

			local targets = TeamTargetProperties[self:GetTeamTargetType()]
			heroes = Game.GetHeroes(self:GetTeam())
			for _,hero in ipairs(heroes) do
				Echo("Added assist for " .. hero:GetOwnerPlayerName())
				local target = self:AddTeamTarget("Assist " .. hero:GetOwnerPlayerName(), "hero", targets.assist, T3_ASSIST)
				target.unit = hero
				target.state = TTS_DORMANT
			end

			self.needAssistUpdate = false
		end
	end
end

function TeamBot:State_Match()
	local time = Game.GetGameTime()
	local invalidTargets, dormantTargets, activeTargets = {}, {}, {}

	for _,target in ipairs(self.teamTargets) do
		if target.gatherNode ~= nil then -- Should only be non-nil on active targets
			self:UpdateGatherNode(target)
		end
		
		if target.nextTime == nil or time > target.nextTime then
			if target.state == TTS_ACTIVE then
				table.insert(activeTargets, target)
			elseif target.state == TTS_DORMANT then
				table.insert(dormantTargets, target)
			else
				table.insert(invalidTargets, target)
			end
		end
	end

	for _,target in ipairs(activeTargets) do
		if target.timeout ~= nil and time > target.timeout then
			self:DeactivateTarget(target)
		else
			target.priority = target.base_priority + self:GetTargetPriorityModifier(target.unit)
			self:UpdateParticipants(target)
			if target.type == T3_ATTACK_TARGET or target.type == T3_PUSH_LANE then
				self:UpdateOffensiveTarget(target)
			elseif target.type == T3_DEFEND_TARGET then
				self:UpdateDefensiveTarget(target)
			elseif target.type == T3_LANEPUSHER then
				self:UpdateLanePusher(target)
			elseif target.type == T3_ASSIST then
				self:UpdateAssistTarget(target)
			end
		end

		coroutine.yield()
	end

	for _,target in ipairs(dormantTargets) do
		if self:FindTargetUnit(target) then
			target.priority = target.base_priority + self:GetTargetPriorityModifier(target.unit)

			if target.type == T3_ATTACK_TARGET or target.type == T3_PUSH_LANE then
				self:CheckOffensiveTarget(target)
			elseif target.type == T3_DEFEND_TARGET then
				self:CheckDefensiveTarget(target)
			elseif target.type == T3_LANEPUSHER then
				self:CheckLanePusher(target)
			elseif target.type == T3_ASSIST then
				self:CheckAssistTarget(target)
			end
		end

		coroutine.yield()
	end

	for _,target in ipairs(invalidTargets) do
		if self:CheckTargetPrerequisites(target) then
			target.state = TTS_DORMANT
		end
		coroutine.yield()
	end

	if self.krytosState == KRYTOS_INACTIVE and self:CheckKrytos() then
		self.krytosState = KRYTOS_SPAWNWAIT
	elseif self.krytosState == KRYTOS_SPAWNWAIT and self:GetActiveLanePusher() ~= nil then
		self.krytosState = KRYTOS_ACTIVE
	elseif self.krytosState == KRYTOS_ACTIVE and self:GetActiveLanePusher() == nil then
		self.krytosState = KRYTOS_INACTIVE
	end

	-- Delay pings to keep conflicting targets from being pinged all at once
	if self.nextPingTarget ~= nil and Game.GetGameTime() >= self.nextPingTarget.time then
		self:PingTarget(self.nextPingTarget.target, self.nextPingTarget.pinger)
		self.nextPingTarget = nil
	end
end

function TeamBot:GetTeamLevel()
	local heroes = Game.GetHeroes(self:GetTeam())
	if #heroes == 0 then
		return 0
	end

	local total = 0
	for index,hero in ipairs(heroes) do
		total = total + hero:GetLevel()
	end

	return total / #heroes
end

function TeamBot:CheckTargetPrerequisites(target)
	if self:GetTeamLevel() < target.level then
		return false
	end

	local needed, filled = self:CalculateTargetPrerequisites(target)
	return filled >= needed
end

function TeamBot:CalculateTargetPrerequisites(target)
	if target.prereqs == nil then
		return 0, 0
	end

	local prereqs = Game.ExplodeString(target.prereqs, ",")
	if #prereqs == 0 then
		return 0, 0
	end

	local prereqCount = #prereqs
	if target.type == T3_DEFEND_TARGET and prereqCount > 0 then
		prereqCount = 1
	elseif target.prereqCount ~= nil then
		prereqCount = target.prereqCount
	end

	local count = 0
	for index,name in ipairs(prereqs) do
		local unit = Game.GetUnitByName(name)
		if unit == nil then
			count = count + 1
		end
	end

	return prereqCount, count
end

function TeamBot:GetLaneFront(lane)
	local wavePos,waveDir = self:GetCreepWaveFront(lane)
	local towerPos = self:GetOuterAllyTower(lane):GetPosition()

	if wavePos == nil then
		return towerPos
	end

	if Vector2.Dot(waveDir, towerPos - wavePos) > 0 then
		return towerPos
	else
		return wavePos
	end
end

function TeamBot:CheckOffensiveTarget(target)
	local min_reduction = 0
	if target.nodeType == "boss" then
		local health = self:GetLastSeenHealthPercent(target.unit)
		if health == nil or health <= 0 then
			return
		end

		if target.priority == target.base_priority then
			local desire, numCloseEnemies = self:CheckBossTarget(target.unit, 1000, 3000, 500)
			if desire == nil or (numCloseEnemies < 3 and desire > -1.0) then
				return
			end
		end

		if health < 0.2 then
			min_reduction = 2
		elseif health < 0.6 then
			min_reduction = 1
		end
	end

	local heroes = self:GetSortedHeroes(target.unit)

	-- Check conditions of inactive but valid targets
	target.min = self:DetermineMinParticipants(target.unit)
	if target.min < target.base_min then
		target.min = target.base_min
	end

	target.min = target.min - min_reduction
	if target.min < 0 then
		target.min = 0
	end

	local candidates = {}
	local pinger = nil
	local participants = self:FindParticipants(target.unit, 750)
	local numParticipants = #participants
	local engaged = false
	for _,hero in ipairs(heroes) do
		local bot = hero:GetBotBrain()
		if not bot then
			if target.unit ~= nil and (hero:IsRecentAttacker(target.unit, 5000) or target.unit:IsRecentAttacker(hero, 5000)) then
				engaged = true
			end
		elseif bot:EvaluateTeamTarget(target, true) then
			pinger = hero
			table.insert(candidates, hero)
		end
	end

	if engaged or #candidates + numParticipants >= target.min then
		local levelSum = 0
		for _,hero in ipairs(participants) do
			levelSum = levelSum + hero:GetLevel()
		end

		if target.nodeType == "base" then
			if not self:CheckBaseConditions() then
				return
			end

			target.lane = self:DetermineBaseLane()
			if target.lane == nil then
				return
			end
		end

		for _,hero in ipairs(candidates) do
			if numParticipants >= target.min then
				break
			end

			levelSum = levelSum + hero:GetLevel()
			local bot = hero:GetBotBrain()
			if bot ~= nil then
				pinger = hero
				bot:AcceptTeamTarget(target)
			end

			numParticipants = numParticipants + 1
		end

		if pinger ~= nil and numParticipants > 2 then
			self.nextPingTarget = {}
			self.nextPingTarget.target = target
			self.nextPingTarget.pinger = pinger
			self.nextPingTarget.time = Game.GetGameTime() + 1000
		end
		target.state = TTS_ACTIVE
		if target.nodeType ~= "base" or self:GetEnemyGeneratorCount() > 1 then
			target.timeout = Game.GetGameTime() + 45000
		else
			target.timeout = nil
		end
		target.participants = participants
		target.quitters = 0
		if target.initialGatherNode ~= nil then
			if engaged and self:CheckTargetTap(target.unit) then
				target.gatherNode = nil
			else
				target.gatherNode = BotMetaData.FindNode(target.initialGatherNode)
			end
		end

		if target.scriptvar ~= nil and not self:IsAllBots() then
			GameInfo.SetScriptValue(target.scriptvar, "1", false)
		end
	end
end

function TeamBot:CheckDefensiveTarget(target)
	if target.unit == nil then
		return
	end

	local attackers,defenders,threat
	if target.unit:IsBase() then
		target.min_health = 0
		attackers,defenders,threat = self:CheckBase(1000, 5000)
		target.min = 1
	else
		if target.priority < 50 then
			target.min_health = 0.1
		else
			target.min_health = 0
		end

		if target.unit:GetHealthPercent() <= target.min_health then
			return
		end

		local enemydist = 5000
		if target.priority < 30 then
			enemydist = 1000
		end

		attackers,defenders,threat = self:CheckTower(target.lane, 1000, enemydist)
		target.min = math.ceil(threat) - 1
	end

--	Echo(target.name .. " has " .. attackers .. " attackers and " .. defenders .. " defenders.")
	if attackers == nil or attackers == 0 or (defenders > 0 and threat <= defenders + 1) then
		return
	end

	if target.priority < 30 and attackers < 3 then
		return
	end


--	Echo("Considering team target " .. target.name .. ", want at least " .. math.ceil(threat - 1) .. " heroes")

	local candidates = {}
	local pinger = nil
	local participants = self:FindParticipants(target.unit, 750)
	local heroes = self:GetSortedHeroes(target.unit)
	for _,hero in ipairs(heroes) do
		local bot = hero:GetBotBrain()
		if bot and bot:EvaluateTeamTarget(target, true) then
			pinger = hero
			table.insert(candidates, hero)
		end
	end

	local numParticipants = #participants
	if #candidates + numParticipants >= target.min then
		for _,hero in ipairs(candidates) do
			if numParticipants >= target.min then
				break
			end

			local bot = hero:GetBotBrain()
			if bot ~= nil then
				pinger = hero
				bot:AcceptTeamTarget(target)
			end

			numParticipants = numParticipants + 1
		end

--		Echo("Target " .. target.name .. " activated with " .. defenders .. " participants vs " .. threat .. " threat (" .. attackers .. " attackers)")
		if pinger ~= nil and numParticipants > 2 then
			self.nextPingTarget = {}
			self.nextPingTarget.target = target
			self.nextPingTarget.pinger = pinger
			self.nextPingTarget.time = Game.GetGameTime() + 1000
		end
		target.state = TTS_ACTIVE
		target.participants = participants
		target.quitters = 0
--	else
--		Echo("Rejected target " .. target.name)
	end
end

function TeamBot:CheckLanePusher(target)
	local lanepusher = target.unit
	if lanepusher == nil then
		return
	end
	local health = lanepusher:GetHealthPercent()
	if health ~= nil and lanepusher:GetHealthPercent() <= 0.1 then
		return
	end

	local pos = lanepusher:GetPosition()
	if pos == nil then
		return
	end
	target.lane = self:GetNearestLane(pos, 600)
	local team = self:GetTeam()
	target.ally = (lanepusher:GetTeam() == team)

	for name,bot in pairs(self.teamBots) do
		if bot:EvaluateTeamTarget(target, true) then
			bot:AcceptTeamTarget(target)
		end
	end

	target.state = TTS_ACTIVE
end

function TeamBot:CheckAssistTarget(target)
	local enemies, allies = self:NeedsAssist(target.unit)
	if enemies == nil or enemies == 0  or enemies <= allies then
		return
	end

	local candidates = {}
	local heroes = self:GetSortedHeroes(target.unit)
	local assistPos = self:GetLastSeenPosition(target.unit)
	for _,hero in ipairs(heroes) do
		local distance = Vector2.Distance(hero:GetPosition(), assistPos)
		if distance > 2000 and distance < 5000 then
			if hero ~= target then
				local bot = hero:GetBotBrain()
				if bot and bot:EvaluateTeamTarget(target) then
					table.insert(candidates, bot)
				end
			end
		end
	end

	local num = 0
	if #candidates > 0 then --and #candidates + allies >= enemies then
		for _,bot in ipairs(candidates) do
			if num >= enemies then
				break
			end

			bot:AcceptTeamTarget(target)
			num = num + 1
		end

		target.state = TTS_ACTIVE
		target.activateTime = Game.GetGameTime()

--		Echo("Activating " .. target.name)
	end
end

function TeamBot:FindEmptyEnemyLane()
	local parms = { type = "tower", lane = "*", lane_index = "*" }
	if self:GetTeam() == TEAM_1 then
		parms["team"] = TEAM_2
	else
		parms["team"] = TEAM_1
	end

	local t = BotMetaData.FindNodesWithProperties(parms)
	local lanes = { top = true, middle = true, bottom = true }
	for _,node in ipairs(t) do
		local unit = Game.GetUnitByName(node:GetProperty("unit"))
		if unit ~= nil and unit:IsAlive() then
			lanes[node:GetProperty("lane")] = nil
		end
	end

	local candidates = {}

	for key,value in pairs(lanes) do
		table.insert(candidates, key)
	end
	
	if #candidates == 0 then
		return nil
	end

	local lane = candidates[K2_RAND_UINT(1, #candidates)]
	return lane
end

function TeamBot:CheckTargetUnit(target, minHealthPercent)
	if minHealthPercent == nil then
		minHealthPercent = 0
	end

	if target.unit == nil or not target.unit:IsValid() then
		return false
	end

	local health = self:GetLastSeenHealthPercent(target.unit)
	if health == nil or health <= minHealthPercent then
		return false
	end

	return true
end

function TeamBot:FindTargetUnit(target)
	if target.type == T3_ASSIST then
		local health = self:GetLastSeenHealthPercent(target.unit)
		if health == nil or health <= 0 then
			return false
		end
		
		return true
	end

	local targetUnit
	if target.type == T3_LANEPUSHER then
		targetUnit = self:GetActiveLanePusher()
	else
		targetUnit = self:FindTargetUnitByName(target.name)
	end

	if targetUnit == nil then
		return false
	else
		local health = targetUnit:GetHealth()
		if health ~= nil and health <= 0 then
			return false
		end
	end

	target.unit = targetUnit
	return true
end

function TeamBot:UpdateParticipants(target)
	target.participants = self:FindParticipants(target.unit, 750)
	target.quitters = 0
end

function TeamBot:PingTarget(target, pinger)
	if target.unit == nil or not target.unit:IsValid() then
		return
	end

	local type = "alert"
	local unit = target.unit

	if target.type == T3_ATTACK_TARGET then
		if unit:IsBuilding() then
			type = "attack_building"
		elseif unit:IsHero() then
			type = "attack_hero"
		end
	elseif target.type == T3_DEFEND_TARGET then
		type = "protect_building"
	elseif target.type == T3_PUSH_LANE then
		type = "attack_building"
	end

	Game.SendPing(type, pinger, unit)
end

function TeamBot:UpdateGatherNode(target)
	target.gatherNode = self:CheckGatherNode(target.gatherNode)
	if target.gatherNode == nil then
		self:DeactivateTarget(target)
		return
	end

	if target.unit == nil or not target.unit:IsValid() then
		self:DeactivateTarget(target)
		return
	end

	-- Don't start attacking a target the other team has tapped
	if not self:CheckTargetTap(target.unit) then
		return
	end

	-- Determine if enough bots have gathered there
	local gathered = 0
	local participants = 0
	local pos = target.gatherNode:GetPosition()
	local heroes = Game.GetHeroes(self:GetTeam())
	for _,hero in ipairs(heroes) do
		if hero:IsAlive() then
			if Vector2.Distance(pos, hero:GetPosition()) < 1500 then
				gathered = gathered + 1
			end
		end
	end

	if gathered >= target.min - 1 then
		target.gatherNode = nil
		target.timeout = nil
		return
	end
end

function TeamBot:RegisterBot(bot)
	self.teamBots[bot:GetName()] = bot
	self:RegisterBotBrain(bot)
end

function TeamBot:UpdateOffensiveTarget(target)
	if target.nodeType == "boss" then
		local min_reduction = 0

		local health = self:GetLastSeenHealthPercent(target.unit)
		if health ~= nil then
			if health < 0.2 then
				min_reduction = 2
			elseif health < 0.6 then
				min_reduction = 1
			end

			-- Check conditions of inactive but valid targets
			target.min = self:DetermineMinParticipants(target.unit)
			if target.min < target.base_min then
				target.min = target.base_min
			end

			target.min = target.min - min_reduction
			if target.min < 1 then
				target.min = 1
			end
		end
	end

	if not self:CheckTargetUnit(target) then
--		Echo("Deactivating offensive target " .. target.name .. ", health too low")
		if target.type == T3_PUSH_LANE then
			self:RemoveTarget(target)
		else
			self:DeactivateTarget(target)
		end
	elseif target.timeout ~= nil then
		-- Prevent timing out targets that are actively taking damage
		local time = Game.GetGameTime()
		if target.timeout - time < 10000 then
			if target.unit:RecentlyTakenDamage(1000) then
				target.timeout = time + 10000
			end
		end
	end
end

function TeamBot:UpdateDefensiveTarget(target)
	local attackers,defenders,threat

	if target.nodeType == "base" then
		-- Check the threat to the base
		attackers,defenders,threat = self:CheckBase(1000, 3000)
	else
		-- See if the target unit is still valid
		if not self:CheckTargetUnit(target, target.min_health) then
			self:RemoveTarget(target)
			return
		end

		-- Sanity check for the target lane
		if target.lane == nil then
			self:RemoveTarget(target)
			return
		end

		-- Check the threat to the tower
		attackers,defenders,threat = self:CheckTower(target.lane, 1000, 5000)
	end

	if attackers == 0 then
--		Echo("Deactivating defensive target " .. target.name .. ", no attackers")
		self:DeactivateTarget(target)
		return
	else
		target.min = attackers - 1
		if target.min < 1 then
			target.min = 1
		end
	end

	local numParticipants = #target.participants
	if numParticipants >= target.min then
		return
	end

	local heroes = self:GetSortedHeroes(target.unit)
	for _,hero in ipairs(heroes) do
		local bot = hero:GetBotBrain()
		if bot ~= nil and bot.teamTarget ~= target and bot:EvaluateTeamTarget(target) then
			bot:AcceptTeamTarget(target)
			numParticipants = numParticipants + 1
			if numParticipants >= target.min then
				break
			end
		end
	end
end

function TeamBot:UpdateLanePusher(target)
	local lanepusher = target.unit
	if lanepusher == nil or lanepusher:GetHealthPercent() <= 0.1 then
--		Echo("Deactivating lanepusher target " .. target.name .. ", lanepusher's health too low")
		self:DeactivateTarget(target) --TODO should convert to push/defend
		return
	end

	for name,bot in pairs(self.teamBots) do
		if bot.teamTarget ~= target then
			if bot:EvaluateTeamTarget(target) then
				bot:AcceptTeamTarget(target)
			end
		end
	end
end

function TeamBot:UpdateAssistTarget(target)
	local attackers, allies = self:NeedsAssist(target.unit)
	if attackers == nil or attackers == 0 then
--		Echo("Deactivating " .. target.name)
		self:DeactivateTarget(target)
	end
end

function TeamBot:RemoveTarget(removal)
	self:DeactivateTarget(removal)
	if removal.nodeType == "base" then
		Echo("Refusing to remove base team target:  " .. removal.name)
		return
	end

	for index,target in ipairs(self.teamTargets) do
		if target == removal then
			table.remove(self.teamTargets, index)
			return true
		end
	end

	Echo("Failed to remove team target " .. removal.name)
	return false
end

function TeamBot:DebugTeamTargets()
	local time = Game.GetGameTime()
	for _,target in ipairs(self.teamTargets) do
		local unit = nil
		if target.type == T3_LANEPUSHER then
			unit = self:GetActiveLanePusher()
		else
			unit = self:FindTargetUnitByName(target.name)
		end

		if unit ~= nil then
			local state = "<UNKNOWN>"
			local participants = ""
			local threat = ""
			local prereq = ""
			if target.state == TTS_ACTIVE then
				participants = ", (none)"
				state = "ACTIVE"

				local partyppl = {}
				for name,bot in pairs(self.teamBots) do
					if bot.teamTarget == target then
						table.insert(partyppl, bot)
					end
				end

				if #partyppl > 0 then
					participants = ", ("
					prefix = false
					for _,bot in ipairs(partyppl) do
						if prefix then
							participants = participants .. ", "
						end
						prefix = true
						participants = participants .. bot:GetName()
					end
					participants = participants .. ")"
				end
			elseif target.state == TTS_DORMANT then
				state = "Dormant"
			elseif target.state == TTS_INVALID then
				state = "Invalid"
				threat = "(" .. string.format("%.1f", self:GetTeamLevel()) .. ", req " .. target.level .. ") "

				local needed, filled = self:CalculateTargetPrerequisites(target)

				if needed > 0 then
					prereq = " [pr " .. filled .. " of " .. needed .. "]"
				end

				if self:CheckTargetPrerequisites(target) then
					prereq = prereq .. " EEE"
					target.bad = true
				end

			end

			if target.state ~= TTS_INVALID and target.type == T3_DEFEND_TARGET then
				threat = "(none) "
				if target.lane == nil then
					if target.name ~= "good_base" and target.name ~= "bad_base" then
						threat = "(NO LANE!)"
					else
						local attackers, defenders, attackthreat = self:CheckBase(1000, 3000)
						threat = "(A:" .. attackers .. ", D:" .. defenders .. ", T: " .. string.format("%.3f", attackthreat) .. "), "
					end
				else
					local attackers, defenders, attackthreat = self:CheckTower(target.lane, 1000, 5000)
					if attackers ~= nil then
						threat = "(A:" .. attackers .. ", D:" .. defenders .. ", T: " .. string.format("%.3f", attackthreat) .. "), "
					end
				end
			end

			local minreq = ""
			if target.min ~= nil then
				minreq = "(min: " .. target.min .. ") "
			end

			unit:SetDebugText(state .. ", " .. threat .. string.format("%.3f", target.priority) .. " priority" .. participants .. minreq .. prereq);
		end
		coroutine.yield()
	end
end

function TeamBot:NecessaryForTeamTarget(bot)
	local target = bot.teamTarget
	if #target.participants - target.quitters > target.min then
		target.quitters = target.quitters + 1
		return false
	end

	return true
end

function TeamBot:UnitDistance(unit, pos)
	local unitPos = self:GetLastSeenPosition(unit, true)
	if unitPos == nil then
		return FAR_AWAY
	else
		return Vector2.Distance(unitPos, pos)
	end
end

function TeamBot:UnitDistanceSq(unit, pos)
	local unitPos = self:GetLastSeenPosition(unit, true)
	if unitPos == nil then
		return FAR_AWAY
	else
		return Vector2.DistanceSq(unitPos, pos)
	end
end

function TeamBot:CheckBaseConditions()
	local teamID = self:GetTeam()
	if teamID == 1 then
		teamID = 2
	else
		teamID = 1
	end

	local parms = { team = teamID }

	parms["type"] = "tower"
	parms["team"] = teamID
	parms["lane"] = "*"
	parms["lane_index"] = 3
	t = BotMetaData.FindNodesWithProperties(parms)
	-- Target the base if at least two generators are down
	if #t < 2 then
		return true
	end

	local count = 0
	local heroes = Game.GetHeroes(teamID)
	for _,hero in ipairs(heroes) do
		if hero:IsAlive() then
			count = count + 1
		end
	end

	-- Target the base if at least two enemy heroes are dead
	return count < 4
end

TeamBot.Create(object)
