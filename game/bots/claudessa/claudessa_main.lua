-- Custom logic for Claudessa Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

local BF_CLAUDESSA_SCORCH = BF_USER1

-- Custom Abilities

-- R --
local ScorchAbility = {}

function ScorchAbility:Evaluate()
    if not Ability.Evaluate(self) then
        return false
    end

    if self.owner:HasBehaviorFlag(BF_RETREAT) or self.owner:HasBehaviorFlag(BF_NEED_HEAL) then
        return false
    end

	local _, enemies = self.owner:CheckEngagement(2000)
	if (enemies == nil) or (enemies < 2) then
		return false
	end

    if (self.owner:GetNumEnemyHeroes(self.ability:GetTargetRadius()) < 1) then
        return false
    end

	return true
end

function ScorchAbility.Create(owner, ability)
    local self = Ability.Create(owner, ability)
    ShallowCopy(ScorchAbility, self)
    return self
end

-- End Custom Abilities

-- Custom Behavior Tree Functions

local ClaudessaBot = {}

function ClaudessaBot.Create(object)
    local self = Bot.Create(object)
    ShallowCopy(ClaudessaBot, self)
    return self
end

function ClaudessaBot:State_Init()
    local abilityQ = TargetPositionAbility.Create(self, self.hero:GetAbility(0))
    local abilityW = ShieldAbility.Create(self, self.hero:GetAbility(1))
    -- ability E is passive
    local abilityR = ScorchAbility.Create(self, self.hero:GetAbility(3))

    abilityQ.settings.doTargetBosses = true
    abilityQ.settings.abilityManaSaver = abilityR

    abilityW.settings.abilityManaSaver = abilityR

    self:RegisterAbility(abilityQ)
    self:RegisterAbility(abilityW)
    self:RegisterAbility(abilityR)

    Bot.State_Init(self) 
end

function ClaudessaBot:UpdateBehaviorFlags()
    if self.hero:HasState("State_Claudessa_Ability4_Linger") then
        self:SetBehaviorFlag(BF_CLAUDESSA_SCORCH)
    else
        self:ClearBehaviorFlag(BF_CLAUDESSA_SCORCH)
    end

    Bot.UpdateBehaviorFlags(self)

    if self:HasBehaviorFlag(BF_CLAUDESSA_SCORCH) then
        self:SetBehaviorFlag(BF_TRYHARD)
    end
end

-- End Custom Behavior Tree Functions

ClaudessaBot.Create(object)

