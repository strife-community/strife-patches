-- Custom logic for Moxie Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

-- Custom Abilities

-- End Custom Abilities

-- Custom Behavior Tree Functions

local MoxieBot = {}

function MoxieBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(MoxieBot, self)
	return self
end

function MoxieBot:State_Init()
    local abilityQ = TargetEnemyAbility.Create(self, self.hero:GetAbility(0))
    local abilityW = TargetPositionAbility.Create(self, self.hero:GetAbility(1))
    -- ability E is passive
    local abilityR = TargetPositionAbility.Create(self, self.hero:GetAbility(3))

    abilityQ.settings.doTargetBosses = true

    abilityW.settings.doTargetBosses = true
    abilityW.settings.doTargetCreeps = true


    self:RegisterAbility(abilityQ)
    self:RegisterAbility(abilityW)
    self:RegisterAbility(abilityR)

    Bot.State_Init(self)
end

-- End Custom Behavior Tree Functions

MoxieBot.Create(object)

