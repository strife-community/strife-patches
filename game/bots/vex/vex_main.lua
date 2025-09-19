-- Custom logic for Vex Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

local BF_VEX_WORMHOLE = BF_USER1

-- Custom Abilities

local MissileBarrageAbility = {}

function MissileBarrageAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	local num = self.owner:GetNumEnemyHeroes(self.ability:GetRange())
	return nul ~= nil and num  > 1
end

function MissileBarrageAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(MissileBarrageAbility, self)
	return self
end

--

ShieldAbility = {}

function ShieldAbility:Evaluate()
	if not Ability.Evaluate(self) then
		return false
	end

	self.target = self.owner:FindShieldTarget(self.ability:GetRange(), 0.8)
	return self.target ~= nil
end

function ShieldAbility.Create(owner, ability)
	local self = TargetAllyAbility.Create(owner, ability, true)
	ShallowCopy(ShieldAbility, self)
	return self
end

--

local WormHoleAbility = {}

function WormHoleAbility:Evaluate()
	if not self.owner:HasBehaviorFlag(BF_CALM) or self.owner.hero:GetHealthPercent() < 0.8 then
		return false
	end

	if self.owner.teamTarget ~= nil and self.owner.teamTarget.priority >= 50 and self.owner:GetDistanceToTeamTarget() < 2000 then
		return false
	end

	if not Ability.Evaluate(self) then
		return false
	end

	if not self.owner:CanTeleport(500) then
		return false
	end

	self.targetPos = self.owner.teambot:FindOffensiveTeleportTarget(self.owner.hero:GetPosition(), 1, 1, 2000, self.ability:GetRange(), 0.3, 1.0)
	if self.targetPos ~= nil then
		return true
	end

	return false
end

function WormHoleAbility:Execute()
	self.lane = self.owner.teambot:GetNearestLane(self.targetPos)
	return TargetPositionAbility.Execute(self)
end

function WormHoleAbility.Create(owner, ability)
	local self = TargetPositionAbility.Create(owner, ability)
	ShallowCopy(WormHoleAbility, self)
	return self
end

-- End Custom Abilities

-- Custom Behavior Tree Functions

local VexBot = {}

function VexBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(VexBot, self)
	return self
end

function VexBot:State_Init()
	-- Seeker Gun
	local ability = TargetPositionAbility.Create(self, self.hero:GetAbility(0), true)
	self:RegisterAbility(ability)

	-- Missile Barrage
	ability = MissileBarrageAbility.Create(self, self.hero:GetAbility(1))
	self:RegisterAbility(ability)

	-- Energy Shield
	ability = ShieldAbility.Create(self, self.hero:GetAbility(2))
	self:RegisterAbility(ability)

	-- Worm Hole
	ability = WormHoleAbility.Create(self, self.hero:GetAbility(3))
	self:RegisterAbility(ability)

	Bot.State_Init(self)
end

function VexBot:Choose_Match()
	if self:HasBehaviorFlag(BF_VEX_WORMHOLE) then
		-- Ensure the bot does nothing that invalidates its hold order for the duration of the ability
		return "Idle"
	end

	return Bot.Choose_Match(self)
end

function VexBot:UpdateBehaviorFlags()
	if self.hero:HasState("State_Vex_Ability4_Self") then
		self:SetBehaviorFlag(BF_VEX_WORMHOLE)
		return
	else
		self:ClearBehaviorFlag(BF_VEX_WORMHOLE)
	end

	Bot.UpdateBehaviorFlags(self)
end

function VexBot:CheckAbilities()
	if self:HasBehaviorFlag(BF_VEX_WORMHOLE) then
		return
	end

	local time = Game.GetGameTime()
	if time > self.nextAbilityCheck then
		for slot,ability in ipairs(self.abilities) do
			if ability.ability == nil then
				Echo(self:GetName() .. " has nil ability in slot " .. slot)
			elseif ability:Evaluate() then
				ability:Execute()

				-- Make sure we don't do anything else if we just activated wormhole
				if self.hero:HasState("State_Vex_Ability4_Self") then
					self:SetBehaviorFlag(BF_VEX_WORMHOLE)
					return
				end

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

function VexBot:State_Teleport()
	local time = Game.GetGameTime() + 100
	while Game.GetGameTime() < time do
		coroutine.yield()
	end

	-- See if teleport is still channeling
	while self.hero:HasState(self.teleportState) do
		-- Check if enemies are nearby (except for ult, doesn't cancel on damage)
		if not self:HasBehaviorFlag(BF_VEX_WORMHOLE) and self:GetNumEnemyHeroes(500) > 0 then
			break
		end

		coroutine.yield()
	end

	self.teleportState = nil
end

-- End Custom Behavior Tree Functions

VexBot.Create(object)

