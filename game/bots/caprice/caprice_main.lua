-- Custom logic for Caprice Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

local QUICK_DRAW_MIN_DISTANCE_TO_TARGET = 300

-- Custom Behavior Tree Functions

local CapriceBot = {}

local QuickDrawAbility = {}

function QuickDrawAbility:Evaluate()
	-- If we need to escape, ignore rest, evaluate
	if EscapeAbility.Evaluate(self) then
		return true
	end

	if not JumpToPositionAbility.Evaluate(self) then
		return false
	end

	local distance_to_target = Vector2.Distance(self.targetPos, self.owner.hero:GetPosition())
    if (distance_to_target < QUICK_DRAW_MIN_DISTANCE_TO_TARGET) then
        return false
    end

    return true
end

function QuickDrawAbility.Create(owner, ability)
	local self = JumpToPositionAbility.Create(owner, ability, false, false, false)
	ShallowCopy(QuickDrawAbility, self)
	return self
end

function CapriceBot.Create(object)
	local self = Bot.Create(object)
	ShallowCopy(CapriceBot, self)
	return self
end

function CapriceBot:State_Init()
    local ability

    -- Quick Draw
	ability = QuickDrawAbility.Create(self, self.hero:GetAbility(3), false)
	self:RegisterAbility(ability)

    -- Anchors
	ability = TargetPositionAbility.Create(self, self.hero:GetAbility(1), true, false, true)
	self:RegisterAbility(ability)

	-- Fire Lager
	ability = TargetPositionAbility.Create(self, self.hero:GetAbility(0), true, false, true)
	self:RegisterAbility(ability)

	Bot.State_Init(self)
end

-- End Custom Behavior Tree Functions

CapriceBot.Create(object)

