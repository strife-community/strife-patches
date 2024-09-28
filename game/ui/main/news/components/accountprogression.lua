-- A component entry should have:
-- internalName			The name to be used to save/id the component
-- externalName			The name to show on dialogues etc
-- singleton			Whether multiple of this component are disallowed
-- resizableContainer	The widget that represents the size of the component
-- onLoad				A function to be called when the component loads
-- onRemove				A function to be called when the component is removed
-- init					A function to be called to create the component, takes (parent, x, y, w, h)

local interface = object
local main_sleeper = interface:GetWidget("main_news_sleeper")

local questsLoaded = false

local currentScreen = 1
local screens = {}

local checkSwap
local swapInterval = 100
local maxSwapInterval = 10000

local function queueCheckSwap()
	libThread.threadFunc(function()
		checkSwap()
	end)
end

local function autoSwapFunc(waitTime)
	swapInterval = maxSwapInterval
	wait(waitTime)
	queueCheckSwap()
end

function mainUI.news.SelectAccountProgressionTabByIndex(targetScreen, fadeTime)
	currentScreen = targetScreen - 1
	checkSwap(fadeTime)
	libThread.fireSingletonThread(autoSwapFunc, maxSwapInterval*2)
end

checkSwap = function(fadeTime)
	if (not (interface and interface:IsValid())) then return end
	libThread.fireSingletonThread(autoSwapFunc, swapInterval)

	local screenArray = {}
	for k,v in pairs(screens) do
		table.insert(screenArray, k);
	end

	if (#screenArray == 0) then return end
	currentScreen = currentScreen + 1
	if currentScreen > #screenArray then
		currentScreen = 1
	end
	for k,v in pairs(screenArray) do
		local widget = interface:GetWidget(v)
		if (widget and widget:IsValid()) then
			fadeWidget(widget, k==currentScreen, fadeTime)
		end
	end
end
checkSwap()

local function setUpAccountProgressionSection()

	-- Unlock section (boost bar etc)
	local function clamp(n, low, high) return math.max( math.min(n, high), low ) end
	
	local unlockable_icons_container = interface:GetWidget("main_accountprogress_upcoming_unlocks_insert")
	local main_news_unlock = interface:GetWidget("main_accountprogress_container")
	local main_accountprogress_visiblility_handler = interface:GetWidget("main_accountprogress_visiblility_handler")
	local back								= interface:GetWidget('main_accountprogress_bar_back')
	local forward							= interface:GetWidget('main_accountprogress_bar_forward')
	local selectedLevel = nil
	local minimum
	
	local function updateAccountProgressionBar(prefix, force)
		local force = force or false
		
		-- return if not actually loaded.
		if ((questsLoaded and not force) or not PostGame or not PostGame.Splash or not PostGame.Splash.modules or not PostGame.Splash.modules.allAccountProgression) then
			return false
		end
		local levelBar							= interface:GetWidget(prefix..'level_bar')
		local playMore							= interface:GetWidget(prefix..'play_more')
		local unlocked_at						= interface:GetWidget(prefix..'unlocked_at')
		local currently_at						= interface:GetWidget(prefix..'currentlevel')
		local bar_leader						= interface:GetWidget(prefix..'bar_leader')
		
		local AccountProgression = LuaTrigger.GetTrigger('AccountProgression')
		
		local rewardsTable = PostGame.Splash.modules.allAccountProgression
		local currentLevel 						= tonumber(AccountProgression.level)
		local nextLevel 						= clamp(tonumber(currentLevel+1), 1, #rewardsTable)
		if (currentLevel == 0 or #rewardsTable == 0) then return false end
		if (currentLevel == #rewardsTable) then return true end
		if (not selectedLevel) then
			selectedLevel = nextLevel
		else
			selectedLevel = clamp(selectedLevel, 1, #rewardsTable)
		end
		local currentRewards					= rewardsTable[selectedLevel]
		
		local hasRequiredExperience = currentRewards and currentRewards.required and currentRewards.required.experience and currentRewards.required.experience.experience and currentRewards.currentProgress
		if selectedLevel == 1 or hasRequiredExperience then
			if (hasRequiredExperience and selectedLevel == nextLevel) then
				local remainingGames = math.ceil(AccountProgression.experienceToNextLevel / (libGeneral.DoIHaveAnAccountExperienceBoost() and 75 or 50))
				local postfix = remainingGames <= 1 and "" or "s"
				playMore:SetText(Translate("postgame_upcoming_unlocks_remaining_game"..postfix, 'value', remainingGames))
				playMore:SetVisible(true)
			else
				playMore:SetVisible(false)
			end
			
			unlocked_at:SetText(Translate("postgame_upcoming_unlocks_header", 'value', selectedLevel))
			
			currently_at:SetText(Translate("postgame_upcoming_unlocks_current_level", 'value', currentLevel))
			
			-- Level pips
			minimum = clamp(selectedLevel-3, 1, #rewardsTable-5)
			for n = 1, 6 do
				interface:GetWidget(prefix..'label_'..n):SetText(minimum+(n-1))
				interface:GetWidget(prefix.."levels_"..n.."_glow"):SetVisible(minimum+n-1 == selectedLevel)
			end
			
			local function barWidth(amount)
				return ((currentLevel-minimum)*20 + amount*20)
			end
			-- Bars
			local width = barWidth(AccountProgression.percentToNextLevel)
			levelBar:SetWidth(clamp(width, 0, 100).."%")
			local inBounds = width >= 0 and width <= 100
			bar_leader:SetVisible(inBounds)
			if (inBounds) then
				bar_leader:SetX(width.."%")
			end
			
			-- Unlockable icons
			unlockable_icons_container:ClearChildren()
			if (currentRewards and currentRewards.rewardCount) then
				for n = 1, currentRewards.rewardCount do
					unlockable_icons_container:Instantiate('main_accountprogress_upcoming_unlock_template', 'index', n, 'texture', currentRewards['rewardIcon'..n], 'tipLabel', currentRewards['rewardText'..n], 'tipLabel2', Translate('quest_type_account_experience_c', 'value', selectedLevel))
				end
			end
			questsLoaded = true
			main_accountprogress_visiblility_handler:FadeIn(250)

		else
			playMore:SetText(Translate("postgame_upcoming_unlocks_remaining_games", 'value', 'ERROR'))
			screens['main_accountprogress_visiblility_handler'] = nil
			return false
		end
		screens['main_accountprogress_visiblility_handler'] = true
		return true
	end
	
	local questsTrigger = LuaTrigger.GetTrigger('questsTrigger')
	if (not questsTrigger) then return end
	main_sleeper:UnregisterWatchLua('AccountProgression')
	main_sleeper:RegisterWatchLua('AccountProgression', function(widget, trigger)
		if (trigger.level > 0) then
			libThread.threadFunc(function()
				wait(10)
				if updateAccountProgressionBar('main_accountprogress_') then
					main_sleeper:UnregisterWatchLua('AccountProgression')
				else
					GetWidget('main_accountprogress_visiblility_handler'):FadeOut(125)
				end
				checkSwap()
			end)
		end

		-- Second screen
		if (mainUI.progression) and (mainUI.progression.stats) and (mainUI.progression.stats.account) and (mainUI.progression.stats.account.division) and (mainUI.progression.stats.account.divisionIndex) and (mainUI.progression.stats.account.division ~= '') and (mainUI.progression.stats.account.pvpRating0) then
			local pveWins = tonumber(mainUI.progression.stats.account.pveWins) or 0
			local pvpWins = tonumber(mainUI.progression.stats.account.pvpWins) or 0
			GetWidget('main_accountprogress_league'):SetTexture(libCompete.divisions[libCompete.divisionNumberByName[mainUI.progression.stats.account.division]].icon)
			GetWidget('main_accountprogress_ELO_label_1'):SetText(Translate('ranked_division') .. ' ' .. Translate('ranked_division_' .. mainUI.progression.stats.account.division))
			if tonumber(mainUI.progression.stats.account.pvpRating0) and (tonumber(mainUI.progression.stats.account.pvpRating0) >= 1530) then
				GetWidget('main_accountprogress_Division'):SetText(Translate('stat_name_pvp_rating_x', 'value', mainUI.progression.stats.account.pvpRating0))
			else
				GetWidget('main_accountprogress_Division'):SetText('')
			end
			GetWidget('main_accountprogress_Rank'):SetText(Translate('news_component_won', 'value', pveWins + pvpWins))

			-- Top Heroes
			local heroTable = {}
			for k,v in pairs(mainUI.progression.stats.heroes) do
				heroTable[k] = v.pvpRating0
			end
			
			local sortedTable = {}
			for k, v in pairsByKeys(heroTable, function(a, b) return heroTable[a]>heroTable[b] end) do
				table.insert(sortedTable, k)
			end
			
			if (sortedTable[1]) and ValidateEntity(sortedTable[1]) then
				GetWidget('main_accountprogress_top_hero_1'):SetTexture(GetEntityIconPath(sortedTable[1]))
			else
				GetWidget('main_accountprogress_top_hero_1'):SetTexture('$invis')
			end			
			if (sortedTable[2]) and ValidateEntity(sortedTable[2]) then
				GetWidget('main_accountprogress_top_hero_2'):SetTexture(GetEntityIconPath(sortedTable[2]))
			else
				GetWidget('main_accountprogress_top_hero_2'):SetTexture('$invis')
			end
			if (sortedTable[3]) and ValidateEntity(sortedTable[3]) then
				GetWidget('main_accountprogress_top_hero_3'):SetTexture(GetEntityIconPath(sortedTable[3]))
			else
				GetWidget('main_accountprogress_top_hero_3'):SetTexture('$invis')
			end
			local ladderPoints = mainUI.progression.stats.account.ladderPoints or 0
			local ladderRank = mainUI.progression.stats.account.ladderRank or 0
			
			if (mainUI.featureMaintenance and mainUI.featureMaintenance['ladder']) then
				ladderPoints = nil
			end
			
			local ladderPointsText = GetWidget('main_accountprogress_LadderPoints')
			local main_accountprogress_Rank = GetWidget('main_accountprogress_Rank')
			local viewLadderBtn = GetWidget('viewLadderBtn')
			if (ladderPoints) and (ladderRank) then
				if (tonumber(ladderRank)) and (tonumber(ladderRank) >= 1) and (tonumber(ladderRank) <= 100) then
					ladderPointsText:SetText(Translate('stat_name_ladder_rank_x_grey', 'value', ladderRank, 'value2', ladderPoints))
				else
					ladderPointsText:SetText(Translate('stat_name_ladder_points_x_grey', 'value', ladderPoints, 'value2', ladderRank))
				end
				main_accountprogress_Rank:SetX('62%')
			else
				main_accountprogress_Rank:SetX('2%')
			end
			fadeWidget(ladderPointsText, ladderPoints)
			fadeWidget(viewLadderBtn, ladderPoints)

			screens['main_accountprogress_visiblility_handler_elo'] = true
		else
			GetWidget('main_accountprogress_visiblility_handler_elo'):FadeOut(125)
			screens['main_accountprogress_visiblility_handler_elo'] = nil
		end
		checkSwap()


	end, false, nil, 'level')			
	main_sleeper:UnregisterWatchLua('questsTrigger')
	main_sleeper:RegisterWatchLua('questsTrigger', function(widget, trigger)
		if (trigger.hasQuestData) then
			libThread.threadFunc(function()
				wait(10)
				if updateAccountProgressionBar('main_accountprogress_') then
					main_sleeper:UnregisterWatchLua('questsTrigger')
				end
			end)
		end
	end, false, nil, 'hasQuestData')
	if (questsTrigger.hasQuestData) then
		libThread.threadFunc(function()
			wait(10)
			if updateAccountProgressionBar('main_accountprogress_', true) then
				main_sleeper:UnregisterWatchLua('questsTrigger')
			end
		end)	
	end
	
	-- Back/forward buttons
	back:SetCallback('onclick', function()
		selectedLevel = selectedLevel - 1
		updateAccountProgressionBar('main_accountprogress_', true)
	end)
	forward:SetCallback('onclick', function()
		selectedLevel = selectedLevel + 1
		updateAccountProgressionBar('main_accountprogress_', true)
	end)
	back:SetCallback(   'onmouseover', function() back:SetColor("1 1 1") end)
	forward:SetCallback('onmouseover', function() forward:SetColor("1 1 1") end)
	back:SetCallback(   'onmouseout' , function() back:SetColor(".6 .6 .6") end)
	forward:SetCallback('onmouseout' , function() forward:SetColor(".6 .6 .6") end)
	
	-- Level pips
	for n = 1, 6 do
		interface:GetWidget("main_accountprogress_levels_"..n.."_clickable"):SetCallback('onmouseover', function()
			interface:GetWidget("main_accountprogress_levels_"..n.."_hover"):SetVisible(true)
		end)
		interface:GetWidget("main_accountprogress_levels_"..n.."_clickable"):SetCallback('onmouseout', function()
			interface:GetWidget("main_accountprogress_levels_"..n.."_hover"):SetVisible(false)
		end)
		interface:GetWidget("main_accountprogress_levels_"..n.."_clickable"):SetCallback('onclick', function()
			selectedLevel = minimum+n-1
			updateAccountProgressionBar('main_accountprogress_', true)
		end)
	end

end


local function onLoad()
	setUpAccountProgressionSection()
end
local function init(parent, x, y, w, h)
	return parent:InstantiateAndReturn('main_accountprogress_container_template', 'x', x, 'y', y, 'w', w, 'h', h)[1]
end
local function onRemove()
	getResizableContainer():Destroy()
end

local function getResizableContainer()
	return nil
end

local newsStoryComponent = {
	internalName = "main_news_progression",
	externalName = "news_component_progression",
	singleton = true,
	defaultPosition = {"20s", "488s", "606s", "190s"},
	onLoad = onLoad,
	onRemove = onRemove,
	init = init,
	getResizableContainer = getResizableContainer,
}


mainUI.news.registerComponent(newsStoryComponent)
