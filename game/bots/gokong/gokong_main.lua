-- Custom logic for HARROWER Bot

runfile "/bots/globals.lua"
runfile "/bots/bot.lua"
runfile "/bots/ability.lua"

local object = getfenv(0).object

local MIN_ULT_BLINK_DISTANCE = 300

local BF_GOKONG_ULT_IN_PROGRESS = BF_USER1
local BF_GOKONG_ULT_CAN_BLINK = BF_USER2
--  TheChiprel: For some reason ability manages to trigger again after ultimate was used but before state was properly applied.
--              I was considering adjusting ability to add a small cooldown but instead decided to stick to creating stub here.
--              This flag is set when ability activates and is cleared once state is set.
local BF_GOKONG_ULT_STUB_FRAME = BF_USER3 


-- Custom Abilities

-- Q --
SpinAbility = {}

function SpinAbility:Evaluate()
    if not Ability.Evaluate(self) then
        return false
    end

    return self.owner:GetNumEnemyHeroes(self.ability:GetTargetRadius()-75) > 0
end

function SpinAbility.Create(owner, ability)
    local self = Ability.Create(owner, ability)
    ShallowCopy(SpinAbility, self)
    return self
end

-- E --
BuffAbility = {}
function BuffAbility:Evaluate()
    if not Ability.Evaluate(self) then
        return false
    end

    if self.owner.threat > 1.2 then
        return false
    end

    return ((self.owner:GetNumEnemyHeroes(600) > 0) or (self.owner:GetNumNeutralBosses(600) > 0))
end

function BuffAbility.Create(owner, ability)
    local self = Ability.Create(owner, ability)
    ShallowCopy(BuffAbility, self)
    return self
end

-- R --
local MonkeyAbility = {}

function MonkeyAbility:Evaluate()
    if not Ability.Evaluate(self) then
        return false
    end 

    if self.owner:HasBehaviorFlag(BF_GOKONG_ULT_IN_PROGRESS) then
        -- Ultimate is active
        if self.owner:HasBehaviorFlag(BF_GOKONG_ULT_CAN_BLINK) then
            local target = self.owner:GetAttackTarget()
            self.targetPos = self.owner.teambot:GetLastSeenPosition(target)
            if (not self.owner:IsPositionUnderEnemyTower(self.targetPos)) then
                return true
            end
        -- else: not enough time have passed, NOTHING TO DO

        end
    elseif (not self.owner:HasBehaviorFlag(BF_GOKONG_ULT_STUB_FRAME)) then
        -- Ultimate is ready but not active
        local allies, enemies = self.owner:CheckEngagement(self.ability:GetRange())
        if (allies ~= nil) and (allies >= 1) or (enemies >= 2) then
            return true
        end
    end

    return false
end

function MonkeyAbility:Execute()
    if self.owner:HasBehaviorFlag(BF_GOKONG_ULT_IN_PROGRESS) then
        TargetPositionAbility.Execute(self)
    else
        Ability.Execute(self)
        self.owner:SetBehaviorFlag(BF_GOKONG_ULT_STUB_FRAME)
    end
end

function MonkeyAbility.Create(owner, ability)
    local self = Ability.Create(owner, ability)
    ShallowCopy(MonkeyAbility, self)
    return self
end

-- End Custom Abilities

-- Custom Behavior Tree Functions

local GoKongBot = {}

function GoKongBot.Create(object)
    local self = Bot.Create(object)
    ShallowCopy(GoKongBot, self)
    return self
end

function GoKongBot:State_Init()
    local abilityQ = SpinAbility.Create(self, self.hero:GetAbility(0))
    local abilityW = JumpToPositionAbility.Create(self, self.hero:GetAbility(1))
    local abilityE = BuffAbility.Create(self, self.hero:GetAbility(2))
    local abilityR = MonkeyAbility.Create(self, self.hero:GetAbility(3))

    self:RegisterAbility(abilityQ)
    self:RegisterAbility(abilityW)
    self:RegisterAbility(abilityE)
    self:RegisterAbility(abilityR)

    Bot.State_Init(self)
end

function GoKongBot:UpdateBehaviorFlags()
    local can_blink = false

    if self.hero:HasState("State_GoKong_Ability4") then
        self:SetBehaviorFlag(BF_GOKONG_ULT_IN_PROGRESS)
        self:ClearBehaviorFlag(BF_GOKONG_ULT_STUB_FRAME)
    else
        self:ClearBehaviorFlag(BF_GOKONG_ULT_IN_PROGRESS)
    end

    if self.hero:HasState("State_GoKong_Ability4_Bot") then
        local target = self:GetAttackTarget()
        if (target ~= nil) then
            local target_position = self.teambot:GetLastSeenPosition(target)
            local distance_to_target = Vector2.Distance(target_position, self.hero:GetPosition())

            if (distance_to_target > MIN_ULT_BLINK_DISTANCE) then
                local threat = self:CalculateThreatLevel(target_position)
                if (threat < 1.2) then
                    can_blink = true
                    --MonkeyAbility.targetPos = target_position
                end
            end
        end
    end

    if (can_blink) then
        self:SetBehaviorFlag(BF_GOKONG_ULT_CAN_BLINK)
    else
        self:ClearBehaviorFlag(BF_GOKONG_ULT_CAN_BLINK)
    end

    Bot.UpdateBehaviorFlags(self)
end

-- End Custom Behavior Tree Functions

GoKongBot.Create(object)

