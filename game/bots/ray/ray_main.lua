-- Custom logic for Ray Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

-- Custom Abilities

-- End Custom Abilities

-- Custom Behavior Tree Functions

local RayBot = {}

function RayBot.Create(object)
    local self = Bot.Create(object)
    ShallowCopy(RayBot, self)
    return self
end

function RayBot:State_Init()
    local abilityQ = TargetPositionAbility.Create(self, self.hero:GetAbility(0))
    local abilityW = TargetPositionAbility.Create(self, self.hero:GetAbility(1))
    -- ability E is passive
    local abilityR = TargetPositionAbility.Create(self, self.hero:GetAbility(3))

    abilityQ.settings.doTargetCreeps = true
    abilityQ.settings.doTargetBosses = true

    self:RegisterAbility(abilityQ)
    self:RegisterAbility(abilityW)
    self:RegisterAbility(abilityR)

    Bot.State_Init(self)
end

-- End Custom Behavior Tree Functions

RayBot.Create(object)

