-- new_game (11/2014)
function registerMapFlip()
	local interface = object 

	-- Checks if the player has changes their settings within the options menu
	UnwatchLuaTriggerByKey('optionsTrigger', 'optionsTriggerScreenFeedback')
	WatchLuaTrigger('optionsTrigger', function()
		updateScreenFeedback(interface, Cvar.GetCvar('_game_screenFeedbackVis'):GetBoolean())
		updateMinimapPosition()
		updateInventoryPosition()
		updateStatPosition()
		updateEventsPosition()
		updateGoldPosition()
	end, 'optionsTriggerScreenFeedback')
end

-- call the separate registration functions
registerHealthManaExp()			-- register the center area
registerCooldowns()				-- register the cooldowns above the exp bar
registerInventory()				-- register the inventory slots
registerAbilities()				-- register the player ability slots
registerHeroStats()				-- register the stat boxes
registerGameTimers()			-- register the game and boss timers
registerAllyEnemyEvents()		-- register the other player icons (top area)
registerMinimapButtons()		-- register buttons above the minimap
registerScoreboard()			-- register the score board
registerMapFlip()
