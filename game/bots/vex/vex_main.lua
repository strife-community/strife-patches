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

	local num = self.owner:GetNumEnemyHeroes(self.ability:GetTargetRadius() - 75) + self.owner:GetNumNeutralBosses(self.ability:GetTargetRadius())
	return (num > 0)
end

function MissileBarrageAbility.Create(owner, ability)
	local self = Ability.Create(owner, ability)
	ShallowCopy(MissileBarrageAbility, self)
	return self
end

--

local WormHoleAbility = {}

function WormHoleAbility:Evaluate()
    if not Ability.Evaluate(self) then
        return false
    end
    
    if self.owner:HasBehaviorFlag(BF_NEED_HEAL) then
        return false
    end

    if not self.owner:CanTeleport(500) then
        return false
    end

    self.targetPos = self.owner.teambot:FindOffensiveTeleportTarget(self.owner.hero:GetPosition(), 1, 500, self.ability:GetRange(), 0.7, 1.2)
    if self.targetPos == nil then
        return false
    end

    if self.owner:IsPositionUnderEnemyTower(self.targetPos) then
        return false
    end

    return true
end

function WormHoleAbility:Execute()
	self.lane = self.owner.teambot:GetNearestLane(self.targetPos)
	return TargetPositionAbility.Execute(self)
end

function WormHoleAbility.Create(owner, ability)
    local self = JumpToPositionAbility.Create(owner, ability)
    ShallowCopy(WormHoleAbility, self)

    self.settings.isEscapeAbility = false

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
    local abilityQ = TargetPositionAbility.Create(self, self.hero:GetAbility(0))
    local abilityW = MissileBarrageAbility.Create(self, self.hero:GetAbility(1))
    local abilityE = ShieldAbility.Create(self, self.hero:GetAbility(2))
    local abilityR = WormHoleAbility.Create(self, self.hero:GetAbility(3))
    
    abilityQ.settings.needClearPath = true
    abilityQ.settings.abilityManaSaver = abilityR

    abilityW.settings.abilityManaSaver = abilityR
    
    abilityE.settings.abilityManaSaver = abilityR

    self:RegisterAbility(abilityQ)
    self:RegisterAbility(abilityW)
    self:RegisterAbility(abilityE)
    self:RegisterAbility(abilityR)

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

