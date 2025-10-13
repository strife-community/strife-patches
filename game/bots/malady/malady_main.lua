-- Custom logic for Malady Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

-- Custom Abilities

-- E --
local GhostlyVeilAbility = {}

function GhostlyVeilAbility:Evaluate()
    if not Ability.Evaluate(self) then
        return false
    end

    self.v1, self.v2 = self.owner:FindWallVectors(self.ability:GetRange())
    return self.v1 ~= nil
end

function GhostlyVeilAbility.Create(owner, ability)
    local self = VectorAbility.Create(owner, ability)
    ShallowCopy(GhostlyVeilAbility, self)

    self.settings.hasAggro = false

    return self
end

-- End Custom Abilities

-- Custom Behavior Tree Functions

local MaladyBot = {}

function MaladyBot.Create(object)
    local self = Bot.Create(object)
    ShallowCopy(MaladyBot, self)
    return self
end

function MaladyBot:State_Init()
    local abilityQ = TargetPositionAbility.Create(self, self.hero:GetAbility(0))
    local abilityW = TargetPositionAbility.Create(self, self.hero:GetAbility(1))
    local abilityE = GhostlyVeilAbility.Create(self, self.hero:GetAbility(2))
    local abilityR = TargetEnemyAbility.Create(self, self.hero:GetAbility(3))

    abilityQ.settings.doTargetCreeps = true
    abilityQ.settings.doTargetBosses = true

    abilityW.settings.doTargetCreeps = true
    abilityW.settings.doTargetBosses = true

    self:RegisterAbility(abilityQ)
    self:RegisterAbility(abilityW)
    self:RegisterAbility(abilityE)
    self:RegisterAbility(abilityR)

    Bot.State_Init(self)
end

-- End Custom Behavior Tree Functions

MaladyBot.Create(object)

