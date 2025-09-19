
-- Behavior tree logic for bots

runfile "/bots/globals.lua"
runfile "/bots/btree.lua"
runfile "/bots/items.lua"
runfile "/bots/familiar.lua"

Bot = {}

function Bot.Create(object)
	local self = BTree.Create(object)
	ShallowCopy(Bot, self)

	if Host.IsClient() then
		self.UpdateDebugInfo = self.UpdateDebugInfo_Real
	else
		self.UpdateDebugInfo = self.UpdateDebugInfo_Dummy
	end

	self.lane = "middle"
	self.inLane = false
	self.nearLaneFront = false
	self.laneWaveInBase = true
	self.availableForTeamTarget = false
	self.abilities = {}
	self.items = {}
	self.nextAbilityCheck = 0
	self.clearTeleport = false
	self.threat = 0
	self.lastRelaneTime = 0
	self.evadeRadius = 500
	self.moveToTarget = false
	self.calmTime = 0
	self.nextEvadeTime = 0

	self:ResetBehaviorFlags()
	self:SetBehaviorFlag(BF_INIT)

	self:ResetItems()

	return self
end

function Bot:CheckAbilities()
	local time = Game.GetGameTime()
	if time > self.nextAbilityCheck then
		for slot,ability in ipairs(self.abilities) do
			if ability.ability == nil then
				Echo(self:GetName() .. " has nil ability in slot " .. slot)
			elseif ability:Evaluate() then
				ability:Execute()
				break
			end
		end

		for _,item in ipairs(self.items) do
			if item:Evaluate() then
				item:Execute()
				break
			end
		end

		self.nextAbilityCheck = time + self:GetAbilityCheckTime()
		if self.clearTeleport then
			self:ClearBehaviorFlag(BF_CHECK_TELEPORT)
		end
	end
end

function Bot:onthink()
	self.hero = self:GetHeroUnit()

	self:UpdateBehaviorFlags()

	local oldstate = self.state

	BTree.onthink(self)

	if self.state ~= oldstate then
		self.teambot:LogInfo(self, self.threat)
		self.teambot:LogState(self, oldstate, self.state)
	end

	self:CheckAbilities()
	self:UpdateDebugInfo()
end

function Bot:UpdateDebugInfo_Real()
	if Cvar.GetCvar("sv_botDebugAttackTarget"):GetNumber() > 65535 then -- Larger than any valid game index
		local botname = Cvar.GetCvarString("sv_botDebugThreat")
		if botname ~= "" and self.debugThreatLevel ~= nil then
			self.hero:SetDebugText(self.state .. " (" ..  string.format("%.3f", self.threat) .. ") (Threatening " ..  botname .. ":  " .. string.format("%.3f", self.debugThreatLevel) .. ")")
		else
			local teamTargetName = "<none>"
			if self.teamTarget ~= nil then
				teamTargetName = self.teamTarget.name
			end

			local flags = ""
			if self:HasBehaviorFlag(BF_INIT) then
				flags = flags .. "INIT "
			end

			if self:HasBehaviorFlag(BF_NEED_HEAL) then
				flags = flags .. "HEAL "
			end

			if self:HasBehaviorFlag(BF_CHECK_TELEPORT) then
				flags = flags .. "TELE "
			end

			if self:HasBehaviorFlag(BF_DEFEND) then
				flags = flags .. "DEF "
			end

			if self:HasBehaviorFlag(BF_OUTSIDELANE) then
				flags = flags .. "OUT "
			end

			if self:HasBehaviorFlag(BF_RETREAT) then
				flags = flags .. "RET "
			end

			if self:HasBehaviorFlag(BF_FARM) then
				flags = flags .. "FARM "
			end

			if self:HasBehaviorFlag(BF_TOWER_DIVE) then
				flags = flags .. "DIVE "
			end

			if self:HasBehaviorFlag(BF_TRYHARD) then
				flags = flags .. "TRY "
			end

			if self:HasBehaviorFlag(BF_USER1) then
				flags = flags .. "USER1 "
			end

			if self:HasBehaviorFlag(BF_USER2) then
				flags = flags .. "USER2 "
			end

			if self:HasBehaviorFlag(BF_USER3) then
				flags = flags .. "USER3 "
			end

			if self:HasBehaviorFlag(BF_USER4) then
				flags = flags .. "USER4 "
			end

			if self:HasBehaviorFlag(BF_AGGRO_CREEPS) then
				flags = flags .. "AGCR "
			end

			if self:HasBehaviorFlag(BF_HAZARD) then
				flags = flags .. "HAZ "
			end

			if self:HasBehaviorFlag(BF_ENEMY_BASE) then
				flags = flags .. "BASE "
			end

			if self:HasBehaviorFlag(BF_CALM) then
				flags = flags .. "CALM "
			end

			if self:HasBehaviorFlag(BF_AGGRO_TOWER) then
				flags = flags .. "AGTW "
			end

			self.hero:SetDebugText(self.state .. " (" ..  string.format("%.3f", self.threat) .. ") [" .. self.lane .. " | " .. teamTargetName ..  " | " .. self:GetPersonalityName() .. "] < " .. flags .. ">")
		end
	end
end

function Bot:UpdateDebugInfo_Dummy()

end

function Bot:ClearTeleport()
	self.clearTeleport = true
end

function Bot:EvaluateTeamTarget(target)
--	if target.nodeType == "boss" and target.priority < 55 then
--	if self:GetTeamBotBrain():GetTeam() == 1 then
--		return self:EvaluateTeamTarget_Debug(target)
--	else
--		return self:EvaluateTeamTarget_Normal(target)
--	end
--end
--
--function Bot:EvaluateTeamTarget_Normal(target)
	local hero = self:GetHeroUnit()
	local unit = target.unit
	local dist = Vector2.Distance(hero:GetPosition(), unit:GetPosition())

	if self:HasBehaviorFlag(BF_NEED_HEAL) then
		return false
	end

	if target == self.teamTarget then
		return false
	end

	if self.teamTarget ~= nil and math.ceil(target.priority) <= math.ceil(self.teamTarget.priority) then
		return false
	end

	if target.type == T3_ASSIST and dist < 3000 then
		return true
	end

	if target.priority > 50 or target.type == "boss" then
		return true
	end

	if self:HasBehaviorFlag(BF_RETREAT) or self:HasBehaviorFlag(BF_AGGRO_CREEPS) then
		return false
	end


	local teambot = self:GetTeamBotBrain()
	if hero:GetLevel() < teambot:GetTeamLevel() then
		return false
	end

	if self.teamTarget ~= nil and target.type ~= T3_DEFEND_TARGET then
		return false
	end

	if target.type == T3_DEFEND_TARGET and target.priority < 40 and dist > 6000 then
		return false
	end

	if target.lane == self.lane and self.teamTarget == nil then
		return true
	end

	return self.availableForTeamTarget
end

--function Bot:EvaluateTeamTarget_Debug(target)
--	local hero = self:GetHeroUnit()
--	local unit = target.unit
--	local dist = Vector2.Distance(hero:GetPosition(), unit:GetPosition())
--
--	if self:HasBehaviorFlag(BF_NEED_HEAL) then
--		Echo(self:GetName() .. " rejected team target " .. target.name .. ":  Health too low")
--		return false
--	end
--
--	if target == self.teamTarget then
--		Echo(self:GetName() .. " rejected team target " .. target.name .. ":  Already on this target")
--		return false
--	end
--
--	if self.teamTarget ~= nil and math.ceil(target.priority) <= math.ceil(self.teamTarget.priority) then
--		Echo(self:GetName() .. " rejected team target " .. target.name .. ":  Priority lower than existing target")
--		return false
--	end
--
--	if target.type == T3_ASSIST and dist < 3000 then
--		Echo(self:GetName() .. " ready to assist " .. target.name)
--		return true
--	end
--
--	if target.priority > 50 or target.type == "boss" then
--		Echo(self:GetName() .. " is available for team target " .. target.name .. ":  Ready (High priority target)")
--		return true
--	end
--
--	if self:HasBehaviorFlag(BF_RETREAT) or self:HasBehaviorFlag(BF_AGGRO_CREEPS) then
--		Echo(self:GetName() .. " rejected team target " .. target.name .. ":  Endangered")
--		return false
--	end
--
--
--	local teambot = self:GetTeamBotBrain()
--	if hero:GetLevel() < teambot:GetTeamLevel() then
--		return false
--	end
--
--	if self.teamTarget ~= nil and target.type ~= T3_DEFEND_TARGET then
--		Echo(self:GetName() .. " rejected team target " .. target.name .. ":  Not switching to a non-defensive target")
--		return false
--	end
--
--	Echo(target.name .. " dist is " .. dist .. " (" .. self:GetName() .. ")")
--	if target.type == T3_DEFEND_TARGET and target.priority < 50 and dist > 6000 then
--		Echo(self:GetName() .. " rejected team target " .. target.name .. ":  Too far away (" .. dist .. ") " .. self.lane)
--		return false
--	end
--
--	if target.lane == self.lane and self.teamTarget == nil then
--		return true
--	end
--
--	if self.availableForTeamTarget then
--		Echo(self:GetName() .. " is available for team target " .. target.name .. ":  Ready")
--	else
--		Echo(self:GetName() .. " rejected team target " .. target.name .. ":  Not available [" .. target.priority .. "]")
--	end
--	return self.availableForTeamTarget
--end

function Bot:AcceptTeamTarget(target)
	self.standbyTarget = self.teamTarget

	self.teamTarget = target
	self:SetTeamTarget(target.unit)
	self.availableForTeamTarget = false

	self.moveToTarget = true

--	Echo(self:GetName() .. " accepted team target " .. target.name)

	if target.lane ~= nil then
--		Echo("  in lane " .. target.lane)
		self.lane = target.lane
		self.lastRelaneTime = Game.GetGameTime()
	end
end

function Bot:ClearTeamTarget(target)
	if self.teamTarget ~= nil and target.name == self.teamTarget.name then
		self:SetTeamTarget(nil)
		self.teamTarget = nil

		if self.standbyTarget ~= nil then
			self:AcceptTeamTarget(self.standbyTarget)
			self.standbyTarget = nil
		else
			-- Reset lane for better stability
			self.lane = self.teambot:GetNearestLane(self:GetHeroUnit():GetPosition())
			self.lastRelaneTime = Game.GetGameTime()
		end
	end

	if self.standbyTarget ~= nil and target.name == self.standbyTarget.name then
		self.standbyTarget = nil
	end
end


function Bot:CalculateThreatLevel(pos)
	-- This is here to allow individual bots to customize their threat level
	return self.teambot:CalculateThreatLevel(pos)
end

function Bot:UpdateBehaviorFlags()
	self.availableForTeamTarget = false

	if self:HasBehaviorFlag(BF_INIT) then
		return
	end

	local time = Game.GetGameTime()

	local teambot = self:GetTeamBotBrain()
	if teambot ~= self.teambot then
		self:ResetTeamBot(teambot)
	end

	if self.hero:GetHealth() > 0 then
		self:UpdateAggroCreeps()
	end

	local health_pct = self.hero:GetHealthPercent()
	local healmin, healmax = self:GetHealRange()
	if health_pct < healmin then
		self:SetBehaviorFlag(BF_NEED_HEAL)
	elseif health_pct > healmax then
		self:ClearBehaviorFlag(BF_NEED_HEAL)
	end

	self:UpdateLaneFlag()

	self.threat = self:CalculateThreatLevel(self.hero:GetPosition())
	self:UpdateHazards(self.threat)
	local gameTime = Game.GetGameTime()
	if self.threat > 0.7 then
		self.calmTime = gameTime
	end

	if gameTime - self.calmTime > 2000 then
		self:SetBehaviorFlag(BF_CALM)
	else
		self:ClearBehaviorFlag(BF_CALM)
	end

	if self.threat > self:GetThreatMax() then
		self:SetBehaviorFlag(BF_RETREAT)
		self.threatTime = time
	elseif self.threat <= self:GetThreatMin() then
		if self.threatTime ~= nil and time - self.threatTime > 500 then
			self:ClearBehaviorFlag(BF_RETREAT)
			self.threatTime = nil
		end
	elseif self.threatTime ~= nil then
		self.threatTime = time
	end

	if self.lane ~= "unknown" then
		self.inLane = self.teambot:GetNearestLane(self.hero:GetPosition(), 600) == self.lane
		if self.inLane and 	self:GetDistanceFromLaneFront(self.lane) < 600 then
			self.nearLaneFront = true
		else
			self.nearLaneFront = false
		end
	else
		self.inLane = false
	end

	local wavePos,waveDir = self.teambot:GetCreepWaveFront(self.lane)
	if wavePos == nil then
		self.laneWaveInBase = true
	else
		local tower = self.teambot:GetOuterAllyTower(self.lane)
		local towerPos = tower:GetPosition()
		local towerDir = Vector2.Normalize(towerPos - wavePos)
		self.laneWaveInBase = Vector2.Dot(waveDir, towerDir) > 0
	end

	if self.hero:GetHealth() <= 0 and self.teamTarget ~= nil then
		self:ClearTeamTarget(self.teamTarget)
	elseif self.teamTarget ~= nil and (self.teamTarget.unit == nil or not self.teamTarget.unit:IsValid()) then
		Echo("Clearing invalid team target:  " .. self.teamTarget.name )
		self:ClearTeamTarget(self.teamTarget)
	end

	if self:HasBehaviorFlag(BF_ENEMY_BASE) then
		if Vector2.DistanceSq(self.hero:GetPosition(), self.teambot.enemyBasePosition) > self.teambot.enemyBaseMaxSq then
			self:ClearBehaviorFlag(BF_ENEMY_BASE)
		end
	elseif Vector2.DistanceSq(self.hero:GetPosition(), self.teambot.enemyBasePosition) < self.teambot.enemyBaseMinSq then
		self:SetBehaviorFlag(BF_ENEMY_BASE)
	end

	self:UpdateHazardFlag()
end

function Bot:RegisterAbility(ability)
	table.insert(self.abilities, ability)
end

function Bot:RegisterItem(item)
	local name = item:GetBotItem()
	local typename = item:GetTypeName()

	-- Only register items once
	for _,myItem in ipairs(self.items) do
		if typename == myItem.name then
			return
		end
	end

	local genv = getfenv(0)
	local class = genv[name]
	if class == nil then
		Echo("Failed to find class for item " .. name .. ", not registering")
	else
		local item = class.Create(self, item)
		table.insert(self.items, item)
	end
end

function Bot:Teleport(state)
	self.teleportState = state
	self:OrderEntity(self.hero, "hold")
	self:ClearBehaviorFlag(BF_CHECK_TELEPORT)
end

------------ Root

function Bot:Choose_Root()
	if self:HasBehaviorFlag(BF_INIT) then
		return "Init"
	end

	if self.hero:GetHealth() <= 0 then
		return "Dead"
	end

	if self.teleportState ~= nil then
		return "Teleport"
	end

	local phase = Game.GetGamePhase()
	if phase == GAME_PHASE_PRE_MATCH then
		return "Prematch"
	elseif phase == GAME_PHASE_ACTIVE then
		return "Match"
	end

	return "Idle"
end

------------- Idle

function Bot:State_Idle()

end

------------- Dead

function Bot:State_Dead()

end

------------- Prematch

function Bot:GetDistanceFromLaneFront(lane)
	local pos = self.teambot:GetLaneFront(lane)
	if pos ~= nil then
		return Vector2.Distance(pos, self.hero:GetPosition())
	end

	return 0
end

function Bot:Choose_Prematch()
	local time = Game:GetRemainingPhaseTime()

	if time > 80000 then
		return "Idle"
	elseif time > 30000 then
		return "MoveToGenerator"
	else
		return "Match"
	end
end

------------- Init

function Bot:ResetTeamBot(teambot)
	Echo(self:GetName() .. " resetting for new teambot instance")
	if self.teamTarget ~= nil then
		self:ClearTeamTarget(self.teamTarget)
	end
	teambot:RegisterBot(self)
	self.teambot = teambot
end

function Bot:State_Init()
	self:SelectUnits(self.hero)

	-- Find the team well node
	local query = { type = "well", team = self.hero:GetTeam() }
	local nodes = BotMetaData.FindNodesWithProperties(query)
	if #nodes > 0 then
		self.well = nodes[1]
	end

	self.teambot = self:GetTeamBotBrain()
	self.teambot:RegisterBot(self)
	self.lane = self:GetRecommendedLane()
	self.lastRelaneTime = Game.GetGameTime()

	local ability = HomeTeleportAbility.Create(self, self.hero:GetAbility(8))
	self:RegisterAbility(ability)

	local familiar = self.hero:GetFamiliarTypeName()
	if familiar ~= nil then
		if FamiliarAbilities[familiar] == nil then
			Echo("No familiar support for " .. familiar)
		else
			ability = self.hero:GetAbility(18)
			if ability ~= nil then
				ability = FamiliarAbilities[familiar].Create(self, ability)
				self:RegisterAbility(ability)
			end
		end
	end

	self:ClearBehaviorFlag(BF_INIT)
end

------------- Match

function Bot:NeedToRetreat()
	if self:HasBehaviorFlag(BF_AGGRO_TOWER) then
		-- Even tower aggro beats tryhard mode
		return true
	end

	if self:HasBehaviorFlag(BF_TRYHARD) then
		-- YOLO!
		return false
	end

	if self:HasBehaviorFlag(BF_NEED_HEAL) then 
		return true
	end

	-- Ignore threat if we're defending the base
	if self.teamTarget ~= nil and self.teamTarget.nodeType == "base" then
		return false
	end

	if self:HasBehaviorFlag(BF_RETREAT) then
		return true
	end

	if self:HasBehaviorFlag(BF_AGGRO_CREEPS) then
		return true
	end

--	if self:CheckHazards() then
--		return true
--	end

	return false
end

function Bot:ShouldAttack()
	if self:HasBehaviorFlag(BF_HAZARD) and not self:HasLastHitTarget() then
		self.harassStartTime = nil
		return false
	end

	if self:UpdateAttackTarget(1200, 1800, self.threat) then
		if self:HasBehaviorFlag(BF_FARM) and not self:HasBehaviorFlag(BF_TRYHARD) then
			local time = Game.GetGameTime()
			local target = self:GetAttackTarget()
			local health = target:GetHealthPercent()
			if target:IsCreep() and health ~= nil and health < 0.5 then
				-- Debugging code for viewing last hit targets
--				if self.hero:GetTeam() == 1 then
--					Game.DrawDebugLine(self.hero:GetPosition3D(), target:GetPosition3D(), "green")
--				else
--					Game.DrawDebugLine(self.hero:GetPosition3D(), target:GetPosition3D(), "red")
--				end
				self.harassStartTime = nil
			else
				if self.hero:GetHealthPercent() < 0.6 then
					self.harassStartTime = nil
					return false
				end

				if self.nextHarassTime ~= nil and self.nextHarassTime > time then
					self.harassStartTime = nil
					return false
				end

				if self.harassStartTime ~= nil and time - self.harassStartTime > 2000 then
					self.nextHarassTime = time + 3000
					self.harassStartTime = nil
				end

				if self.harassStartTime == nil then
					self.harassStartTime = time
				end
			end
		end

		return true
	end

	self.harassStartTime = nil
	return false
end

function Bot:Choose_Match()
	if self:NeedToRetreat() then
		return "Retreat"
	elseif self:ShouldAttack() then
		return "AttackTarget"
	elseif self.teamTarget ~= nil then
		return "TeamCombat"
	elseif self:GetNumAllyHeroes() > 2 or self:GetNumEnemyCreeps() > 10 or (self:GetNumEnemyHeroes() == 0 and self.hero:GetLevel() > 4) then
		-- Push if there are three or more allies (including this bot), or if they are more than 10 creeps, or if the lane is empty and the bot is above level 4
		return "PushLane"
	end

	return "FarmLane"
end

------------- MoveToGenerator

function Bot:GetLaneGeneratorNode()
	local query = { type = "tower", team = self.hero:GetTeam(), lane_index = 1, lane = self.lane }
	local nodes = BotMetaData.FindNodesWithProperties(query)
	if #nodes > 0 then
		return nodes[1]
	end
end

function Bot:State_MoveToGenerator()
	if self.lane == nil then
		Echo("State_MoveToGenerator called with no lane")
	end

	self.lane = self:GetRecommendedLane()
	local lane = self.lane
	local node = self:GetLaneGeneratorNode()
	if node == nil then
		Echo("Couldn't find generator node for lane '" .. self.lane .. "'")
		return
	end

	local nextLaneUpdate = Game.GetGameTime() + 500

	if Vector2.Distance(node:GetPosition(), self.hero:GetPosition()) < 500 then
		return
	end

	self:PathToNode(node, 0, self:GetGeneratorApproachOffset(node:GetPosition(), 300))
	while self:FollowPath() do
		local time = Game.GetGameTime()
		if time > nextLaneUpdate then
			self.lane = self:GetRecommendedLane()
			nextLaneUpdate = time + 500
		end

		if self.lane ~= lane then
			return
		end

		coroutine.yield()
	end
end

------------- FarmLane

function Bot:ShouldTowerDive()
	if self:HasBehaviorFlag(BF_AGGRO_TOWER) then
		self.diveTower = nil
		return false
	end

	if not self.teambot:GetAllowTowerDive() then
		self.diveTower = nil
		return false
	end

	local tower = self:GetNearestTower(self.hero:GetPosition(), 5000, false)
	if tower ~= nil and self:CheckTowerDive(tower) then
		self.diveTower = tower
		return true
	else
		self.diveTower = nil
		return false
	end
end

function Bot:UpdateLaneFlag()
	local distance = self:DistanceFromLane(self.lane)
	if distance == nil then
		return false
	else
		if self:HasBehaviorFlag(BF_OUTSIDELANE) then
			if distance < 600 then
				self:ClearBehaviorFlag(BF_OUTSIDELANE)
				return false
			else
				return true
			end
		else
			if distance > 900 then
				self:SetBehaviorFlag(BF_OUTSIDELANE)
				return true
			else
				return false
			end
		end
	end
end

function Bot:Choose_FarmLane()
	local tower = self.teambot:GetOuterAllyTower(self.lane)
	self:SetBehaviorFlag(BF_FARM)

	if self:TowerUnderAttack(tower) then
		self.defendUnit = tower
		return "Defend"
	elseif self:HasBehaviorFlag(BF_OUTSIDELANE) then
		self.availableForTeamTarget = true

		return "EvadeEnemies"
	elseif self:ShouldTowerDive() then
		return "TowerDive"
	else
		self.availableForTeamTarget = true

		if self:HasBehaviorFlag(BF_ENEMY_BASE) then
			return "RetreatFromBase"
		end

		return "EvadeEnemies"
	end
end

------------- EvadeEnemies

function Bot:State_EvadeEnemies()
	local time = Game.GetGameTime()
	if (self.lastRelaneTime == nil or time - self.lastRelaneTime > 30000) and self:GetNumEnemyHeroes(1000) == 0 and self.teamTarget == nil then
		self.lane = self:GetRecommendedLane()
		self.lastRelaneTime = time
	end

	if self.laneWaveInBase then
		local tower = self.teambot:GetOuterAllyTower(self.lane)
		local towerPos = tower:GetPosition()

		local prevTower = self.teambot:GetPreviousTower(tower)
		local offset = nil
		if prevTower ~= nil then
			offset = Vector2.Normalize(towerPos - prevTower:GetPosition()) * 400
		end

		self:PathToUnit(tower, self.evadeRadius, offset)
	else
		local wavePos,waveDir = self.teambot:GetCreepWaveFront(self.lane)
		local offset = -waveDir * (400 + (1.0 - self.hero:GetHealthPercent()) * 800)

		self:PathToLaneFront(self.lane, self.evadeRadius, offset)
	end

	while self:FollowPath() do
		coroutine.yield()
	end
end

------------- RetreatEvade

function Bot:ShouldEvade()
	local time = Game.GetGameTime()
	if self.nextEvadeTime > time then
		return false
	end

	if self.laneWaveInBase then
		return false
	end

	if self:HasBehaviorFlag(BF_OUTSIDELANE) then
		return false
	end

	local wavePos,waveDir = self.teambot:GetCreepWaveFront(self.lane)
	local offset = -waveDir * (400 + (1.0 - self.hero:GetHealthPercent()) * 800)

	-- Check local threat first
	if self.threat > 0.8 then
		self.nextEvadeTime = time + 2000
		return false
	end

	-- Check target location threat
	local threat = self:CalculateThreatLevel(wavePos + offset)
	if threat > 0.8 then
		self.nextEvadeTime = time + 2000
		return false
	end

	return true
end

------------- Retreat

function Bot:Choose_Retreat()
	if self:HasBehaviorFlag(BF_ENEMY_BASE) then
		return "RetreatFromBase"
	end

	local retreatTower = nil
	if self.teamTarget ~= nil and self.teamTarget.type == T3_DEFEND_TARGET then
		retreatTower = self.teamTarget.unit
	end

	if retreatTower == nil then
		if self:HasBehaviorFlag(BF_OUTSIDELANE) then
			retreatTower = self:GetNearestTower(self.hero:GetPosition(), FAR_AWAY, true)
		end

		if retreatTower == nil then
			if self.lane ~= nil then
				retreatTower = self.teambot:GetOuterAllyTower(self.lane)
			else
				retreatTower = self:GetRetreatTower()
			end
		end
		if retreatTower == nil then
			self.retreatTower = nil
			return "RetreatToWell"
		else
			self.retreatTower = retreatTower
		end

		if not retreatTower:IsBase() and not retreatTower:IsRax()then
			while retreatTower:GetHealthPercent() < 0.15 do
				retreatTower = self.teambot:GetPreviousTower(retreatTower)
				if retreatTower == nil then
					self.retreatTower = nil
					return "RetreatToWell"
				else
					self.retreatTower = retreatTower
				end
			end
		end
	else
		self.retreatTower = retreatTower
	end

	if self:TowerUnderAttack(retreatTower) then
		if self.hero:GetHealthPercent() > 0.2 and not self:HasBehaviorFlag(BF_RETREAT) then
			self.defendUnit = self.retreatTower
			return "Defend"
		else
			retreatTower = self.teambot:GetPreviousTower(retreatTower)
			if retreatTower == nil then
				self.retreatTower = nil
				return "RetreatToWell"
			else
				self.retreatTower = retreatTower
			end
		end
	end

	if self:ShouldEvade() then
		return "EvadeEnemies"
	end

	return "RetreatToLaneTower"
end

------------- RetreatToWell

function Bot:State_RetreatToWell()
	self:PathToNode(self.well, self.evadeRadius)
	while self:FollowPath() do
		coroutine.yield()
	end
end

------------- RetreatToLaneTower

function Bot:State_RetreatToLaneTower()
	local retreatTower = self.retreatTower
	if retreatTower == nil then
		return
	end

	local towerPos = retreatTower:GetPosition() 
	local prevTower = self.teambot:GetPreviousTower(retreatTower)
	local offset = nil
	if prevTower == nil then
		offset = Vector2.RandomInRadius(Vector2.Create(0, 0), 500) -- Hover around the base
	else
		offset = Vector2.Normalize(prevTower:GetPosition() - towerPos) * 400
	end

	self:PathToUnit(self.retreatTower, self.evadeRadius, offset)
	while self:FollowPath() do
		coroutine.yield()
	end
end

------------- RetreatFromBase

function Bot:State_RetreatFromBase()
	local lane = self.teambot:DetermineBaseLane()
	if lane == nil then
		lane = self.teambot:GetNearestLane(self.hero:GetPosition())
	end

	self:PathToNode(self.teambot.escapeNodes[lane], self.evadeRadius)
	while self:FollowPath() do
		coroutine.yield()
	end
end

------------- TowerDive

function Bot:State_TowerDive()
	local rangeSq = self.hero:GetEffectiveAttackRange() ^ 2

	self:SetBehaviorFlag(BF_TOWER_DIVE)

	if Vector2.DistanceSq(self.diveTower:GetPosition(), self.hero:GetPosition()) > rangeSq then
		self:PathToUnit(self.diveTower)
		while Vector2.DistanceSq(self.diveTower:GetPosition(), self.hero:GetPosition()) > rangeSq and self:FollowPath() do
			coroutine.yield()
		end

		self:ClearPath()
	end

	local order = self:OrderEntity(self.hero, "attack", self.diveTower)
	while self:GetOrderStatus(order) < ORDER_STATUS_COMPLETE do
		coroutine.yield()
	end
end

function Bot:Leave_TowerDive()
	self:ClearBehaviorFlag(BF_TOWER_DIVE)
end

------------- Defend

function Bot:Choose_Defend()
	self:ClearBehaviorFlag(BF_DEFEND)
	self:ClearBehaviorFlag(BF_FARM)

	if self.moveToTarget then
		local unit = self.defendUnit
	--	Echo(self:GetName() .. " defending " .. unit:GetName())
		local defendRange = unit:GetEffectiveAttackRange()
		if self:HasBehaviorFlag(BF_DEFEND) then
			defendRange = defendRange * 1.5
		end
		defendRange = defendRange + 800

		local distance = self.teambot:UnitDistance(self.defendUnit, self.hero:GetPosition())
		if distance > defendRange then
			self:ClearBehaviorFlag(BF_DEFEND)
			
			if distance > defendRange * 2 and self:GetAttackTarget() ~= nil then
				return "AttackTarget"
			else
				if self:HasBehaviorFlag(BF_ENEMY_BASE) then
					return "RetreatFromBase"
				end

				return "MoveToDefendUnit"
			end
		end

		self.moveToTarget = false
	end

	-- Only attack aggressive enemy heroes
	if self:UpdateAttackTarget(300, 600, self.threat) then
		return "AttackTarget"
	end

	self:SetBehaviorFlag(BF_DEFEND)

	if self.defendTarget ~= nil then
		local health = self.teambot:GetLastSeenHealthPercent(self.defendTarget, true)
		if health == nil or health <= 0 or self.teambot:UnitDistanceSq(self.defendTarget, self.hero:GetPosition()) > 2250000 then -- 1500 ^ 2
			self.defendTarget = nil
		end
	end

	if self.defendTarget == nil then
		self.defendTarget = self:FindDefendTarget(self.defendUnit, 1500)
	end

	if self.defendTarget == nil then
		self.retreatTower = self.defendUnit
		return "RetreatToLaneTower"
	else
		return "DefendOffensive"
	end
end

function Bot:Leave_Defend()
	self:ClearBehaviorFlag(BF_DEFEND)
end

------------- MoveToDefendUnit

function Bot:State_MoveToDefendUnit()
	self:SetBehaviorFlag(BF_CHECK_TELEPORT)

	self:PathToUnit(self.defendUnit, self.evadeRadius)
	while self:FollowPath() do
		coroutine.yield()
	end
end

function Bot:Leave_MoveToDefendUnit()
	self:ClearBehaviorFlag(BF_CHECK_TELEPORT)
end

------------- DefendEvasive

function Bot:State_DefendEvasive()
	self:PathToUnit(self.defendUnit, self.evadeRadius)
	while self:FollowPath() do
		coroutine.yield()
	end
end

------------- DefendOffensive

function Bot:State_DefendOffensive()
	local enemy = self.defendTarget
	local rangeSq = self.hero:GetEffectiveAttackRange() ^ 2

	if self.teambot:UnitDistanceSq(self.defendTarget, self.hero:GetPosition()) > rangeSq then
		self:PathToUnit(self.defendTarget)
		while self.teambot:UnitDistanceSq(self.defendTarget, self.hero:GetPosition()) > rangeSq and self:FollowPath() do
			coroutine.yield()
			enemy = self.defendTarget
		end

		self:ClearPath()
	end

	local order = self:OrderEntity(self.hero, "attack", enemy)
	local nextCheck = Game.GetGameTime() + 1000
	while self:GetOrderStatus(order) < ORDER_STATUS_COMPLETE do
		if Game.GetGameTime() > nextCheck then
			break
		end 
		coroutine.yield()
	end
end

------------- AttackTarget

function Bot:State_AttackTarget()
	local enemy = self:GetAttackTarget()
	local rangeSq = self.hero:GetEffectiveAttackRange() ^ 2

	if self.teambot:UnitDistanceSq(enemy, self.hero:GetPosition()) > rangeSq then
		self:PathToUnit(enemy)
		while self.teambot:UnitDistanceSq(enemy, self.hero:GetPosition()) > rangeSq and self:FollowPath() do
			coroutine.yield()
			enemy = self:GetAttackTarget()
		end

		self:ClearPath()
	end

	local order = self:OrderEntity(self.hero, "attack", enemy)
	while self:GetOrderStatus(order) < ORDER_STATUS_COMPLETE do
		coroutine.yield()
	end	
end

------------- AttackTeamTarget

function Bot:State_AttackTeamTarget()
	local target = self.teamTarget.unit
	local rangeSq = self.hero:GetEffectiveAttackRange() ^ 2

	if Vector2.DistanceSq(target:GetPosition(), self.hero:GetPosition()) > rangeSq then
		self:PathToUnit(target)
		while Vector2.DistanceSq(target:GetPosition(), self.hero:GetPosition()) > rangeSq and self:FollowPath() do
			coroutine.yield()
			target = self:GetAttackTarget()
		end

		self:ClearPath()
	end

	local order = self:OrderEntity(self.hero, "attack", target)
	while self:GetOrderStatus(order) < ORDER_STATUS_COMPLETE do
		coroutine.yield()
	end
end

------------- TeamCombat

function Bot:GetDistanceToTeamTarget()
	if self.teamTarget.unit == nil or not self.teamTarget.unit:IsValid() then
		Echo("No unit for team target " .. self.teamTarget.name)
		return 9999999
	end

	local distance = Vector2.Distance(self.teamTarget.unit:GetPosition(), self.hero:GetPosition())
	return distance
end

function Bot:Choose_TeamCombat()
	self:ClearBehaviorFlag(BF_FARM)

	if self.teamTarget.gatherNode ~= nil then
		return "Gather"
	end

	if self.teamTarget.type == T3_LANEPUSHER then
		if self.teamTarget.ally then
			return "SupportLanePusher"
		else
			self.defendUnit = self.teambot:GetOuterAllyTower(self.teamTarget.lane)
			return "Defend"
		end
	elseif self.teamTarget.type == T3_PUSH_LANE then
		return "PushLane"
	elseif self.teamTarget.type == T3_DEFEND_TARGET then
		if self.moveToTarget or self.teamTarget.nodeType == "base" then
			--self.availableForTeamTarget = true
			self.defendUnit = self.teamTarget.unit
			return "Defend"
		elseif not self:HasBehaviorFlag(BF_HAZARD) and self:UpdateAttackTarget(1200, 1800, self.threat) then
			return "AttackTarget"
--		elseif self:GetDistanceToTeamTarget() > 2500 then
--			return "MoveToTeamTarget"
		else
			--TODO self.availableForTeamTarget = true
			return "PushLane"
		end
	elseif self:GetDistanceToTeamTarget() > self.hero:GetEffectiveAttackRange() then
		if not self:HasBehaviorFlag(BF_HAZARD) and self.threat < 1.0 and self:UpdateAttackTarget(1200, 1800, self.threat) then
			return "AttackTarget"
		elseif self:HasBehaviorFlag(BF_ENEMY_BASE) then
			return "RetreatFromBase"
		end

		return "MoveToTeamTarget"
	elseif self.teamTarget.type == T3_ASSIST then
		if self:UpdateAttackTarget(300, 600, self.threat) then
			return "AttackTarget"
		else
			return "MoveToTeamTarget"
		end
	else
		return "AttackTeamTarget"
	end
end

------------- PushLane

function Bot:CheckCreepTarget()
	if self.creepTarget ~= nil then
		local health = self.teambot:GetLastSeenHealthPercent(self.creepTarget, true)
		if health == nil or health <= 0 then
			self.creepTarget = nil
		elseif Vector2.Distance(self.hero:GetPosition(), self.teambot:GetLastSeenPosition(self.creepTarget)) > 1500 then
			self.creepTarget = nil
		else
			return true
		end
	end
		
	if self.laneWaveInBase or self:NearEnemyTower() then
		self.creepTarget = nil
		return false
	end

	local wavePos,waveDir = self.teambot:GetCreepWaveFront(self.lane)
	if Vector2.Distance(wavePos, self.hero:GetPosition()) > 1000 then
		return false
	end

	self.creepTarget = self:GetNearestEnemyCreep(1000)
	return self.creepTarget ~= nil
end

function Bot:CanLeaveTeamTarget()
	if self.teamTarget == nil then
		return true
	end

	return not self.teambot:NecessaryForTeamTarget(self)
end

function Bot:Choose_PushLane()
	local tower = self.teambot:GetOuterAllyTower(self.lane)
	self:ClearBehaviorFlag(BF_FARM)

	if self:TowerUnderAttack(tower) then
		self.defendUnit = tower
		return "Defend"
	elseif self:HasBehaviorFlag(BF_OUTSIDELANE) and not self:HasBehaviorFlag(BF_ENEMY_BASE) then
		self.availableForTeamTarget = self:CanLeaveTeamTarget()
		return "EvadeEnemies"
	elseif self:ShouldTowerDive() then
		return "TowerDive"
	elseif self:CheckCreepTarget() then
		self.availableForTeamTarget = self:CanLeaveTeamTarget()
		return "PushCreeps"
	else
		self.availableForTeamTarget = self:CanLeaveTeamTarget()

		return "EvadeEnemies"
	end
end

------------- MoveToTeamTarget

function Bot:State_MoveToTeamTarget()
	self:SetBehaviorFlag(BF_CHECK_TELEPORT)
	self:PathToUnit(self.teamTarget.unit, self.evadeRadius)
	while self:FollowPath() do
		coroutine.yield()
	end
end

function Bot:Leave_MoveToTeamTarget()
	self:ClearBehaviorFlag(BF_CHECK_TELEPORT)
end

------------- SupportLanePusher

function Bot:Choose_SupportLanePusher()
	if self:ShouldTowerDive() then
		return "TowerDive"
	elseif self:CheckCreepTarget() then
		return "PushCreeps"
	else
		return "FollowLanePusher"
	end
end

------------- PushCreeps

function Bot:State_PushCreeps()
	local creep = self.creepTarget
	local order = self:OrderEntity(self.hero, "attack", creep)
	while self:GetOrderStatus(order) < ORDER_STATUS_COMPLETE do
		coroutine.yield()
	end
end

------------- FollowLanePusher

function Bot:State_FollowLanePusher()
	self:PathToUnit(self.teamTarget.unit, self.evadeRadius)
	while self:FollowPath() do
		coroutine.yield()
	end
end

------------- Gather

function Bot:State_Gather()
	local node = self.teamTarget.gatherNode

	self:PathToNode(node, self.evadeRadius)
	while self:FollowPath() do
		if node ~= self.teamTarget.gatherNode then
			return
		end
		coroutine.yield()
	end
end

------------- Teleport

function Bot:State_Teleport()
	local time = Game.GetGameTime() + 100
	while Game.GetGameTime() < time do
		coroutine.yield()
	end

	-- See if teleport is still channeling
	while self.hero:HasState(self.teleportState) do
		-- Check if enemies are nearby
		if self:GetNumEnemyHeroes(500) > 0 then
			break
		end

		coroutine.yield()
	end

	self.teleportState = nil
end
