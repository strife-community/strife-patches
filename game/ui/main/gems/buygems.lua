-- Gem Purchase

-- New Lua function:
-- bool Rmt.PurchasePackage(string purchaseIncrement) 

-- New triggers:
-- GameClientRequestsRmtGetPaymentInfo
-- GameClientRequestsRmtPurchasePackage
-- GameClientRequestsRmtPurchaseCanceled (dumb)
-- GameClientRequestsRmtPurchaseFinishSteam
-- RmtPackage (array)

local MAX_PACKAGE_INT = 7

local function AdjustWidth()
	local packages = 0
	
	for index = 0,MAX_PACKAGE_INT,1 do
		local packageTrigger = LuaTrigger.GetTrigger('RmtPackage'..index)
		if (packageTrigger) and (packageTrigger.amount > 0) then
			packages = packages + 1
		end
	end
	if (packages <= 3) then
		GetWidget('buyGemsWidth'):SetWidth('59h')
	else
		local newWidth = ((packages - 3) * 17.3) + 59
		GetWidget('buyGemsWidth'):SetWidth(newWidth .. 'h')
	end
end

function buyGemsRegisterPackage(object, index)
	local container				= object:GetWidget('buyGemsPackage'..index)
	local button				= object:GetWidget('buyGemsPackage'..index..'Button')
	local icon					= object:GetWidget('buyGemsPackage'..index..'Icon')
	local RMTLabel				= object:GetWidget('buyGemsPackage'..index..'RMTLabel')
	local gemLabel				= object:GetWidget('buyGemsPackage'..index..'GemLabel')
	local BonusGemsParent		= object:GetWidget('buyGemsPackage'..index..'BonusGemsParent')
	local BonusGemLabel			= object:GetWidget('buyGemsPackage'..index..'BonusGemLabel')
	local GemsParent			= object:GetWidget('buyGemsPackage'..index..'GemsParent')
	local gemTrigger 			= LuaTrigger.GetTrigger('RmtPackage'..index)
	
	if (gemTrigger == nil) then
		println('^r^:buyGemsPackage'..index .. ' missing trigger')
		return
	end
	
	if (container == nil) then
		println('^r^:buyGemsPackage'..index)
		return
	end
	
	if (gemTrigger == nil) then
		container:SetVisible(false) 
	end

	container:RegisterWatchLua('RmtPackage'..index, function(widget, trigger) 
		widget:SetVisible(trigger['amount'] > 0) 
		AdjustWidth()
	end, false, nil, 'amount')
	container:SetVisible(gemTrigger['amount'] > 0) 
	
	RMTLabel:RegisterWatchLua('RmtPackage'..index, function(widget, trigger) 
		widget:SetText('$'..FtoA2(trigger['amount'], 2,2)) 
	end, false, nil, 'amount')
	RMTLabel:SetText('$'..FtoA2(gemTrigger['amount'], 2,2)) 
	
	gemLabel:RegisterWatchLua('RmtPackage'..index, function(widget, trigger)
		widget:SetText(trigger['currencyAmount']) 
	end, false, nil, 'amount', 'currencyAmount', 'bonusAmount')
	gemLabel:SetText(gemTrigger['currencyAmount']) 
	
	BonusGemsParent:RegisterWatchLua('RmtPackage'..index, function(widget, trigger)
		if (trigger.bonusAmount >= 1) then
			BonusGemLabel:SetText(math.floor(trigger.bonusAmount))
			widget:FadeIn(125)
		else
			widget:FadeOut(125)
		end
	end, false, nil, 'amount', 'currencyAmount', 'bonusAmount')
	if (gemTrigger.bonusAmount >= 1) then
		BonusGemLabel:SetText(math.floor(gemTrigger.bonusAmount) .. '!')
		BonusGemsParent:FadeIn(125)
	else
		BonusGemsParent:FadeOut(125)
	end
		
	button:SetCallback('onclick', function(widget)

		button:UnregisterWatchLua('GameClientRequestsRmtPurchasePackage')
		button:RegisterWatchLua('GameClientRequestsRmtPurchasePackage', function(widget, trigger)
			widget:SetEnabled(trigger.status ~= 1)
			if (trigger.status == 2) and (trigger.errorMessage) and (not Empty(trigger.errorMessage)) and (trigger.errorMessage ~= 'error_not_found') then
				local errorTable = explode('|', trigger.errorMessage)
				local errorTable2 = {}
				for i,v in ipairs(errorTable) do
					table.insert(errorTable2, Translate(v))
				end
				local errorString = implode2(errorTable2, ' \n', '', '')
				GenericDialogAutoSize(
					'error_web_general', '', tostring(Translate(errorString)), 'general_ok', '',
						nil,
						nil
				)
			end		
			if (trigger.status ~= 1) then
				button:UnregisterWatchLua('GameClientRequestsRmtPurchasePackage')
			end
		end, false, nil)
		
		local gemTrigger = LuaTrigger.GetTrigger('RmtPackage'..index)
		PlaySound('/ui/sounds/sfx_button_generic.wav')
		println('Rmt.PurchasePackage ' .. tostring(gemTrigger.purchaseIncrement))
		Rmt.PurchasePackage(gemTrigger.purchaseIncrement) 
		
		if (Steam) and (Steam.IsOverlayEnabled) and (not Steam.IsOverlayEnabled()) then
			GenericDialogAutoSize(
				Translate('gem_purchase_overlay_error'), Translate('gem_purchase_overlay_error_desc'), '', 'general_ok', '', 
				function()
				end,
				nil,
				nil,
				false,
				true
			)	
		else
			-- mainUI.WatchForGemIncrease()
			-- mainUI.gemPurchaseQueued = true
		end		
		
	end)
	
end

function buyGemsRegister(object)

	local container		= object:GetWidget('buyGems')
	local current		= object:GetWidget('buyGemsCurrent')	-- Currently-owned gems
	local closeButton	= object:GetWidget('buyGemsClose')
	
	local function OpenBuyGemsURL()
		local URL = Strife_Region.regionTable[Strife_Region.activeRegion].buyGemsURL

		URL = string.gsub(URL, "{accountId}", Client.GetAccountID())
		URL = string.gsub(URL, "{identId}", GetIdentID())
		URL = string.gsub(URL, "{sessionKey}", Client.GetSessionKey())
		
		println('Opening Gems URL ' .. tostring(URL) )
		
		mainUI.OpenURL(URL, true, true)
	end
	
	function buyGemsShow()
        -- Disabled buying gems window, since microtransactions are not avaliable
		--container:FadeIn(250)	
	end
	
	function buyGemsClose()
		container:FadeOut(150)
	end

	current:RegisterWatchLua('GemOffer', function(widget, trigger) widget:SetText(trigger.gems) end, false, nil, 'gems')
	
	current:SetText(LuaTrigger.GetTrigger('GemOffer').gems)
	
	for i=0,9,1 do
		local container				= object:GetWidget('buyGemsPackage'..i)
		if (container) then
			container:SetVisible(0)
		end
	end
	
	for i=0,MAX_PACKAGE_INT,1 do
		buyGemsRegisterPackage(object, i)
	end

	AdjustWidth()
	
	closeButton:SetCallback('onclick', function(widget) buyGemsClose() end)
	
	-- current:RegisterWatchLua('GameClientRequestsRmtGetPaymentInfo', function(widget, trigger)
	
	-- end, false, nil)
	
	current:RegisterWatchLua('GameClientRequestsRmtPurchasePackage', function(widget, trigger)
		if (trigger.status ~= 1) then
			-- buyGemsClose()
		end
	end, false, nil)
	
	current:RegisterWatchLua('GameClientRequestsRmtPurchaseCanceled', function(widget, trigger)
		buyGemsClose()
	end, false, nil)
	
	current:RegisterWatchLua('GameClientRequestsRmtPurchaseFinishSteam', function(widget, trigger)
		if (trigger.status ~= 1) then
			buyGemsClose()
		end
	end, false, nil)
	
	current:RegisterWatchLua('newPlayerExperience', function(widget, trigger)
		local triggerNPE		= LuaTrigger.GetTrigger('newPlayerExperience')
		local npeCheckpointComplete = (triggerNPE.tutorialComplete) or (triggerNPE.tutorialProgress >= NPE_PROGRESS_TUTORIALCOMPLETE) or (not NewPlayerExperience) or (not NewPlayerExperience.enabled)	
		
		if (Strife_Region.regionTable[Strife_Region.activeRegion]) and (Strife_Region.regionTable[Strife_Region.activeRegion].allowRealPurchases) and (npeCheckpointComplete) then
			GetWidget('buyGemsPurchasesEnabled'):SetVisible(1)
			GetWidget('buyGemsPurchasesDisabled'):SetVisible(0)
			GetWidget('buyGemsPurchaseTitle'):SetText(Translate('needgems_title'))
		else
			GetWidget('buyGemsPurchasesEnabled'):SetVisible(0)
			GetWidget('buyGemsPurchasesDisabled'):SetVisible(1)
			if (npeCheckpointComplete) then
				GetWidget('buyGemsPurchaseTitle3'):SetText(Translate('needgems_nogemsyet'))
				GetWidget('buyGemsPurchaseTitle'):SetText(Translate('needgems_nogemsyet2'))
			else
				GetWidget('buyGemsPurchaseTitle3'):SetText(Translate('needgems_nogemsyet3'))
				GetWidget('buyGemsPurchaseTitle'):SetText(Translate('needgems_nogemsyet2'))
			end
		end
	end)
	
end

buyGemsRegister(object)