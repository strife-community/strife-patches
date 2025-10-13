-- Custom logic for Carter Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

-- Custom Abilities

-- E --
local RingAbility = {}

function RingAbility:Evaluate()
    if not Ability.Evaluate(self) then
        return false
    end

    return (self.owner:GetNumEnemyHeroes(2 * self.ability:GetTargetRadius()) > 1) or (self.owner:GetNumNeutralBosses(2 * self.ability:GetTargetRadius()) > 0)
end

function RingAbility.Create(owner, ability)
    local self = Ability.Create(owner, ability)
    ShallowCopy(RingAbility, self)
    return self
end

-- End Custom Abilities

-- Custom Behavior Tree Functions

local CarterBot = {}

function CarterBot.Create(object)
    local self = Bot.Create(object)
    ShallowCopy(CarterBot, self)
    return self
end

function CarterBot:State_Init()
    local abilityQ = TargetPositionAbility.Create(self, self.hero:GetAbility(0))
    local abilityW = TargetPositionAbility.Create(self, self.hero:GetAbility(1))
    local abilityE = RingAbility.Create(self, self.hero:GetAbility(2))
    local abilityR = TargetEnemyAbility.Create(self, self.hero:GetAbility(3))

    abilityQ.settings.needClearPath = true
    abilityQ.settings.doTargetBosses = true

    abilityW.doTargetCreeps = true
    abilityW.doTargetBosses = true

    self:RegisterAbility(abilityQ)
    self:RegisterAbility(abilityW)
    self:RegisterAbility(abilityE)
    self:RegisterAbility(abilityR)

    Bot.State_Init(self)

    self.evadeRadius = 750
end

function CarterBot:CalculateThreatLevel(pos)
    return Bot.CalculateThreatLevel(self, pos) + 0.2 -- Nudge threat slightly
end

-- End Custom Behavior Tree Functions

CarterBot.Create(object)

