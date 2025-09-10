-- Common hero item classes

runfile "/bots/globals.lua"

-- Base item class

Item = {}

function Item:Evaluate()
	if not self.item:IsValid() then
		local items = self.owner.hero:FindItemInBackpack(self.name)
		if #items == 0 then
			return false
		end
		self.item = items[1]

		if not self.item:IsValid() then
			Echo(self.name .. " couldn't find valid item object to evaluate!")
			return false
		end
	end

	return self.item:CanActivate()
end

function Item:Execute()
--	Echo(self.item:GetTypeName() .. " fired<I>!")
	self.owner:OrderItem(self.item)
end

function Item.Create(owner, item)
	local self = ShallowCopy(Item)

	self.item = item
	self.owner = owner
	self.name = item:GetTypeName()

	return self
end

-- Entity targetting item

TargetEnemyItem = {}

function TargetEnemyItem:Evaluate()
	if not Item.Evaluate(self) then
		return false
	end

	self.target = self.owner:GetAttackTarget()
	if self.target == nil then
		return false
	end

	if self.owner.teambot:UnitDistance(self.target, self.owner.hero:GetPosition()) > self.item:GetRange() then
		return false
	end

	return true
end

function TargetEnemyItem:Execute()
--	Echo(self.item:GetTypeName() .. " fired<E>!")
	self.owner:OrderItemEntity(self.item, self.target);
end

function TargetEnemyItem.Create(owner, item)
	local self = Item.Create(owner, item)
	ShallowCopy(TargetEnemyItem, self)
	return self
end

-- Healing Scepter

HealingScepterItem = {}

function HealingScepterItem:Evaluate()
	if not Item.Evaluate(self) then
		return false
	end

	if self.owner:HasBehaviorFlag(BF_NEED_HEAL) then
		return true
	end

	local health = self.owner.hero:GetHealthPercent()
	local charges = self.item:GetCharges()

	if health < 0.6 and charges > 10 then
		return true
	end

	local mana = self.owner.hero:GetManaPercent()

	if mana < 0.35 and charges > 10 then
		return true
	end

	return false
end

function HealingScepterItem.Create(owner, item)
	local self = Item.Create(owner, item)
	ShallowCopy(HealingScepterItem, self)
	return self
end

-- Mask of the Madman

MaskOfTheMadmanItem = {}

function MaskOfTheMadmanItem:Evaluate()
	if not Item.Evaluate(self) then
		return false
	end

	if self.owner.hero:GetHealthPercent() >= 0.7 and self.owner:GetNumAttackers() > 1 then
		return true
	end

	return false
end

function MaskOfTheMadmanItem.Create(owner, item)
	local self = Item.Create(owner, item)
	ShallowCopy(MaskOfTheMadmanItem, self)
	return self
end

-- Defense Buff Items

DefenseBuffItem = {}

function DefenseBuffItem:Evaluate()
	if not Item.Evaluate(self) then
		return false
	end

	local numAttackers = self.owner:GetNumAttackers()
	if numAttackers > 2 or (numAttackers > 0 and self.owner.hero:GetHealthPercent() < 0.5) then
		return true
	end

	return false
end

function DefenseBuffItem.Create(owner, item)
	local self = Item.Create(owner, item)
	ShallowCopy(DefenseBuffItem, self)
	return self
end

-- Stone Skin

StoneSkinItem = {}

function StoneSkinItem:Evaluate()
	if not Item.Evaluate(self) then
		return false
	end

	if self.owner:CheckStunned() then
		return true
	end

	local numAttackers = self.owner:GetNumAttackers()
	if numAttackers > 0 and self.owner.hero:GetHealthPercent() < 0.5 then
		return true
	end

	return false
end

function StoneSkinItem:Execute()
	self.owner:ClearStunned()
	Item.Execute(self)
end

function StoneSkinItem.Create(owner, item)
	local self = Item.Create(owner, item)
	ShallowCopy(StoneSkinItem, self)
	return self
end

-- Staff of Meditation

StaffOfMeditationItem = {}

function StaffOfMeditationItem:Evaluate()
	if not Item.Evaluate(self) then
		return false
	end

	if self.owner.hero:GetHealthPercent() < 0.6 then
		return true
	end

	if self.owner.hero:GetManaPercent() < 0.35 then
		return true
	end

	return false
end

function StaffOfMeditationItem.Create(owner, item)
	local self = Item.Create(owner, item)
	ShallowCopy(StaffOfMeditationItem, self)
	return self
end

-- Ring Of Sorcery

RingOfSorceryItem = {}

function RingOfSorceryItem:Evaluate()
	if not Item.Evaluate(self) then
		return false
	end

	if self.owner:CheckAlliesMana(self.item:GetRange()) < 0.6 then
		return true
	end

	return false
end

function RingOfSorceryItem.Create(owner, item)
	local self = Item.Create(owner, item)
	ShallowCopy(RingOfSorceryItem, self)
	return self
end

-- Escape Item

EscapeItem = {}

function EscapeItem:Evaluate()
	if self.owner.retreatTower == nil then
		return false
	end

	return not self.owner:HasBehaviorFlag(BF_TRYHARD) and Item.Evaluate(self) and (self.owner:HasBehaviorFlag(BF_NEED_HEAL) or self.owner:HasBehaviorFlag(BF_RETREAT)) and self.owner:GetNumEnemyHeroes(1500) > 0
end

function EscapeItem:Execute()
--	Echo(self.item:GetTypeName() .. " fired<ESCAPE>!")
	self.owner:OrderItemPosition(self.item, self.owner.teambot:GetLastSeenPosition(self.owner.retreatTower));
end

function EscapeItem.Create(owner, item)
	local self = Item.Create(owner, item)
	ShallowCopy(EscapeItem, self)
	return self
end

-- Frostfield Plate

FrostfieldPlateItem = {}

function FrostfieldPlateItem:Evaluate()
	if not Item.Evaluate(self) then
		return false
	end

	if self.owner:GetNumEnemyHeroes(450) > 0 then
		return true
	end

	return false
end

function FrostfieldPlateItem.Create(owner, item)
	local self = Item.Create(owner, item)
	ShallowCopy(FrostfieldPlateItem, self)
	return self
end

-- Inertia Boots

InertiaBootsItem = {}

function InertiaBootsItem:Evaluate()
	return Item.Evaluate(self) and self.owner:CheckStunned()
end

function InertiaBootsItem:Execute()
	self.owner:ClearStunned()
	Item.Execute(self)
end

function InertiaBootsItem.Create(owner, item)
	local self = Item.Create(owner, item)
	ShallowCopy(InertiaBootsItem, self)
	return self
end

-- Teleport Boots

TeleportBootsItem = {}

function TeleportBootsItem:Evaluate()
	if not self.owner:HasBehaviorFlag(BF_CHECK_TELEPORT) then
		return false;
	end

	if not Item.Evaluate(self) then
		return false
	end

	local targetPos = self.owner:GetMoveTarget()
	if targetPos == nil then
		return false
	end

	local heroPos = self.owner.hero:GetPosition()
	if Vector2.DistanceSq(heroPos, targetPos) < 6250000 then -- 2500 units
		return false
	end

	if not self.owner:HasBehaviorFlag(BF_CALM) or not self.owner:CanTeleport(500) then
		return false
	end

	self.unitPos = self.owner:GetNearestAllyUnitPosition(targetPos)
	if self.unitPos == nil then
		return false
	end

	local normalTime = self.owner:GetPathTravelTime(heroPos, targetPos)
	local teleportTime = self.owner:GetPathTravelTime(self.unitPos, targetPos) + 4
	if normalTime > teleportTime then
		return true
	else
		self.owner:ClearTeleport()
	end
end

function TeleportBootsItem:Execute()
	self.owner:Teleport("State_TeleportBoots")
--	Echo(self.item:GetTypeName() .. " fired<TELEPORT>!")
	self.owner:OrderItemPosition(self.item, self.unitPos);
end

function TeleportBootsItem.Create(owner, item)
	local self = Item.Create(owner, item)
	ShallowCopy(TeleportBootsItem, self)
	return self
end

-- Assassin's Shroud Item

AssassinsShroudItem = {}

function AssassinsShroudItem:Evaluate()
	return Item.Evaluate(self) and not self.owner:HasBehaviorFlag(BF_TRYHARD) and self.owner:HasBehaviorFlag(BF_NEED_HEAL) and self.owner:GetNumEnemyHeroes(750) > 0
end

function AssassinsShroudItem.Create(owner, item)
	local self = Item.Create(owner, item)
	ShallowCopy(AssassinsShroudItem, self)
	return self
end

-- Regeneration Potion

RegenPotionItem = {}

function RegenPotionItem:Evaluate()
	if self.owner.hero:HasState("State_RegenerationPotion") or self.owner.hero:HasState("State_HealthElixir") then
		return false
	end

	local items = self.owner.hero:FindItemInBackpack("Item_RegenerationPotion")
	if #items == 0 then
		return
	end
	self.item = items[1]

	if not Item.Evaluate(self) then
		return false
	end

	if self.owner.hero:GetHealthPercent() < 0.5 then
		if self.owner:GetNumEnemyHeroes(750) > 0 then
			return true
		else
			items = self.owner.hero:FindItemInBackpack("Item_HealthElixir")
			if #items == 0 then
				return true
			end
		end
	end

	return false
end

function RegenPotionItem.Create(owner, item)
	local self = Item.Create(owner, item)
	ShallowCopy(RegenPotionItem, self)
	return self
end

-- Clarity Potion

ClarityPotionItem = {}

function ClarityPotionItem:Evaluate()
	if self.owner.hero:HasState("State_ClarityPotion") or self.owner.hero:HasState("State_ManaElixir")then
		return false
	end

	local items = self.owner.hero:FindItemInBackpack("Item_ClarityPotion")
	if #items == 0 then
		return
	end
	self.item = items[1]

	if not Item.Evaluate(self) then
		return false
	end

	if self.owner.hero:GetManaPercent() < 0.5 then
		if self.owner:GetNumEnemyHeroes(750) > 0 then
			return true
		else
			items = self.owner.hero:FindItemInBackpack("Item_ManaElixir")
			if #items == 0 then
				return true
			end
		end
	end

	return false
end

function ClarityPotionItem.Create(owner, item)
	local self = Item.Create(owner, item)
	ShallowCopy(ClarityPotionItem, self)
	return self
end

-- Health Elixir

HealthElixirItem = {}

function HealthElixirItem:Evaluate()
	if self.owner.hero:HasState("State_HealthElixir") then
		return false
	end

	if not Item.Evaluate(self) then
		return false
	end

	return self.owner.hero:GetHealthPercent() < 0.5 and self.owner:GetNumEnemyHeroes(750) == 0
end

function HealthElixirItem.Create(owner, item)
	local self = Item.Create(owner, item)
	ShallowCopy(HealthElixirItem, self)
	return self
end

-- Mana Elixir

ManaElixirItem = {}

function ManaElixirItem:Evaluate()
	if self.owner.hero:HasState("State_ManaElixir") then
		return false
	end

	if not Item.Evaluate(self) then
		return false
	end

	return self.owner.hero:GetManaPercent() < 0.5 and self.owner:GetNumEnemyHeroes(750) == 0
end

function ManaElixirItem.Create(owner, item)
	local self = Item.Create(owner, item)
	ShallowCopy(ManaElixirItem, self)
	return self
end

