-- (C)2014 S2 Games
-- advantage.lua
--
-- Max advantage callback
--=============================================================================

return function(party, queue, region, activityCount)
	if party.age < 24000 then
		return Matchmaker.WinPercentToElo(0.55), "capped"
	elseif party.age < 120000 then
		return Matchmaker.WinPercentToElo(0.60), "capped"
	elseif party.age < 240000 then
		return Matchmaker.WinPercentToElo(0.65), "capped"
	elseif party.age < 360000 then
		return Matchmaker.WinPercentToElo(0.70), "capped"
	else
		return "max", "uncapped"
	end
end