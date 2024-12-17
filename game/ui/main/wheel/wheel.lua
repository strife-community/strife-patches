local function WheelRegister(object)
	
	if ((mainUI.featureMaintenance) and (mainUI.featureMaintenance['prizewheel'])) then
		return
	end
	
	local interface = object
	local tinsert, tremove, tsort, pi, sin, cos = table.insert, table.remove, table.sort, math.pi, math.sin, math.cos

	local wheelTrigger = LuaTrigger.GetTrigger('wheelTrigger') or LuaTrigger.CreateCustomTrigger('wheelTrigger',
		{
			{ name	= 'wheelSpinAvailable',				type	= 'bool' },
			{ name	= 'wheelSpinAvailableFree',			type	= 'bool' },
			{ name	= 'hasWheelData',					type	= 'bool' },
			{ name	= 'wheelClosed',					type	= 'bool' },
			{ name	= 'lastWheel',						type	= 'number' },
		}
	)

	local debug=false

	local function ClearData()

	end

	local function updateCosts(responseData)
		-- println('^gUpdating costs!')
		-- printr(responseData)
		
		wheelTrigger.hasWheelData = true

		local closed = responseData.wheel.closed == 1 or responseData.wheel.closed == '1'
		wheelTrigger.wheelClosed = closed
		
		if (not closed) then
			GetWidget('wheelSpin'):SetVisible(true)
			GetWidget('wheelSpun'):SetVisible(false)
			GetWidget('wheel_mainMessage_highlight'):SetText(Translate('wheel_spin_wheel_freespins'))
			wheelTrigger.wheelSpinAvailable = true
		else
			if (not debug) then
				GetWidget('wheelSpin'):SetVisible(false)
				GetWidget('wheelSpun'):SetVisible(true)
				GetWidget('wheel_mainMessage_highlight'):SetText(Translate('wheel_spin_wheel_nospins'))
			end
			wheelTrigger.wheelSpinAvailable = false
			wheelTrigger.wheelSpinAvailableFree = false
		end
		wheelTrigger:Trigger(false)
	end

	local segments = {}
	local icons = {}
	local globalRotationAddition = -pi/2
	local wheelRotationAddition = pi/8 - 1.34 -- arrow is at an offset, so we offset the wheel to make it match.
	local iconRotationAddition = -1.34 -- arrow is at an offset, so we offset the icons to make it match.

	local function offsetWidgetPolar(widget, angle, distance)
		local x = cos(angle)*distance
		local y = sin(angle)*distance
		--println(widget:GetName().." x: "..x.." y: "..y.." distance: "..distance.." angle: "..angle)
		widget:SetX(x.."s")
		widget:SetY(y.."s")
		widget:SetRotation(angle*180/pi)
	end

	local wheelInfoResponseData
	local function setup()
		if not ((wheelTrigger.lastWheel) and (wheelTrigger.lastWheel > 0)) then
			local successFunction =  function (request)	-- response handler
				local responseData = request:GetBody()
				if responseData == nil then
					SevereError('CreateWheel - no response data', 'main_reconnect_thatsucks', '', nil, nil, false)
					return nil
				else
					wheelInfoResponseData = responseData
					-- printr(responseData)
					wheelTrigger.lastWheel = responseData.wheel.wheelIncrement
					updateCosts(responseData)
					
					wheel_container = GetWidget('wheel_container')
					
					-- wheel creation
					-- create seperators
					-- create icons
					wheel_container:ClearChildren()
					
					--proportions must add to 100
					local numSegments = 0
					for k,v in pairs(responseData.wheel.prizes) do
						numSegments = numSegments + 1
					end
					local currentAngle = 0
					local segmentWidth = GetWidget('wheelOfFortuneImage'):GetWidth()/2
					local segmentHeight = 3
					for n=0, numSegments-1 do
						--local nextAngle = currentAngle + (responseData.wheel.prizes[tostring(n)].probabilityWeight)/100
						local segmentAngle = 2*pi*currentAngle
						--local newSegment = wheel_container:InstantiateAndReturn('wheel_seperator_template', --[['color', colors[n+1], ]]'id', n, 'height', segmentHeight, 'width', segmentWidth)[1]
						--offsetWidgetPolar(newSegment, segmentAngle+globalRotationAddition, segmentWidth/2)
						tinsert(segments, {segmentAngle, segmentWidth/2})
						
						local iconAngle = (2*pi*(currentAngle + 0.2)) + 0.7
						
						-- Teir 3 prizes are a little large and need some extra space
						if (5-tonumber(responseData.wheel.prizes[tostring(n)].tier) == 3) then
							iconAngle = iconAngle - 0.1
						end
						
						local amount = responseData.wheel.prizes[tostring(n)].components['0'].amount
						local resourceType = responseData.wheel.prizes[tostring(n)].components['0'].type
						local texture = ""
						
						if resourceType == 'ore' then texture = "/ui/main/wheel/textures/ore_tier0"..(5-responseData.wheel.prizes[tostring(n)].tier)..".tga" end
						if resourceType == 'food' then texture = "/ui/main/wheel/textures/food_tier0"..(5-responseData.wheel.prizes[tostring(n)].tier)..".tga" end
						if resourceType == 'essence' then texture = "/ui/main/shared/textures/commodity_essence.tga" end
						if resourceType == 'gems' then texture = "/ui/main/shared/textures/gem.tga" end
						local iconSize="160s"
						local newIcon = wheel_container:InstantiateAndReturn('wheel_icon_template', 'id', n, 'texture', texture, 'height', iconSize, 'width', iconSize)[1]
						offsetWidgetPolar(newIcon, iconAngle+globalRotationAddition+iconRotationAddition, 155)
						newIcon:SetVFlip(true)
						tinsert(icons, {iconAngle, segmentWidth/1.25})
						
						currentAngle = currentAngle + 0.2
					end

					return true
				end
			end
			
			local failFunction =  function (request)	-- error handler
				SevereError('CreateWheel Request Error: ' .. Translate(request:GetError() or ''), 'main_reconnect_thatsucks', '', nil, nil, false)
				return nil
			end	
			
			Strife_Web_Requests:CreateWheel(successFunction, failFunction)
		end
	end

	local initialRotation = 0
	local currentRotation = 0
	local winningResource
	local winningResourceX
	local winningResourceY
	local winningResourceRotation
	
	local function SpinWheel()
		GetWidget('wheel_moxie_model'):SetAnim('ability_3')
		GetWidget('wheel_moxie_lightning_effect'):SetEffect('/ui/main/wheel/effects/lightning.effect')
		PlaySound('/heroes/bandito/ability_04/sounds/sfx_state.wav')
		
		--WARNING
		--Obscure-ish math ahead.
		--Calculate a certain point to stop on after a certain time, then use a mathematical function to make it happen
		GetWidget('wheelSpin'):SetVisible(false)
		local successFunction =  function (request)	-- response handler
			local responseData = nil
			if not debug then
				responseData = request:GetBody()
			end
			-- printr(responseData)
			if not debug and responseData == nil then
				SevereError('SpinWheel - no response data', 'main_reconnect_thatsucks', '', nil, nil, false)
				return nil
			else
				local won
				if (debug) then
					won = math.random(5)-1
				else
					won = responseData.wheel.won[tostring(responseData.wheel.progress-1)]
				end
				
				local wheel 	 = GetWidget('wheelOfFortune')
				local wheelImage = GetWidget('wheelOfFortuneImage')
				local wheelGlow	 = GetWidget('wheelOfFortuneGlow')
				local effectType = 1 --land inside, plain and simple.
				local placeToStop
				local index = 0
				local totalTimeToStop
				local spinState = 0 --0:spin up		1:waiting for response/slow down point		2:gradual slowdown
				local rotationSpeed = 0
				local spinUpSpeed = 0.003
				local spinUpCap = 0.25
				local spinDownSpeed = 0.0011
				local adjustedSpinDownSpeed
				
				wheel:UnregisterWatchLua('System')
				wheel:RegisterWatchLua('System', function(widget, trigger)
					
					if spinState == 0 then --spin up
						if (rotationSpeed <= spinUpCap) then 
							rotationSpeed = rotationSpeed + spinUpSpeed
						else --move onto slowdown
							spinState = 1
							initialRotation = currentRotation
							rotationSpeed = spinUpCap
							won = won + 1
							if won >= #segments then won = 0 end
							local sectorAngle = segments[won+1][1]
							local nextSectorAngle = won>=#segments-1 and 0 or segments[won+2][1]
							if nextSectorAngle == 0 then nextSectorAngle = 2*pi end
							--wheel is spinning, not something spining around the wheel, therefore this angle is flipped
							placeToStop = -math.random(sectorAngle*1000, nextSectorAngle*1000)/1000
							
							local timeToStop = rotationSpeed/spinDownSpeed
							local stopAngle = currentRotation+rotationSpeed+timeToStop*rotationSpeed/2
							local offset = placeToStop-(stopAngle%(pi*2))
							local distanceTillStop = timeToStop*rotationSpeed/2
							local totalExtraAngle = distanceTillStop+offset
							local newTimeToSlowDown = 2*totalExtraAngle / spinUpCap
							totalTimeToStop = math.floor(newTimeToSlowDown)
							adjustedSpinDownSpeed = spinUpCap/newTimeToSlowDown
						end
					end
					if spinState == 1 then --waiting for response/slow down point
						--find place to slow down
						if effectType == 1 then --land inside
							rotationSpeed = 0 --we are controlling the rotation from here.
							if (index ~= totalTimeToStop) then
								-- x = V0 t + 1/2 a t^2
								currentRotation = initialRotation+spinUpCap*index - adjustedSpinDownSpeed/2 * math.pow(index,2)+spinUpCap
							else
								rotationSpeed = 0
								spinState = 2
								interface:GetWidget('wheelPrizeContainer'):FadeIn(styles_mainSwapAnimationDuration)
							end
							
							index = index + 1
						end
					end
					if spinState == 2 then --Things have stopped, Show what we won!
						-- Now move the winning resource image into the center on the screen
						won = won - 1
						if won < 0 then
							won = #segments - 1
						end
						-- Set the "You win" labels and icon
						interface:GetWidget("wheelPrizeCount"):SetText(wheelInfoResponseData.wheel.prizes[tostring(won)].components['0'].amount)
						local prize = wheelInfoResponseData.wheel.prizes[tostring(won)].components['0'].type
						local texture = "/ui/main/shared/textures/commodity_shards.tga"
						if prize == "ore" then
							texture = "/ui/main/shared/textures/commodity_essence.tga"
						end
						interface:GetWidget("wheelPrizeResource"):SetTexture(texture)
						
						-- Save the position of the resource so we can move it back later
						wheelResourceTarget = interface:GetWidget("wheelResourceTarget")
						winningResource = interface:GetWidget('wheel_icon'..won)
						winningResourceX = winningResource:GetX()
						winningResourceY = winningResource:GetY()
						winningResourceRotation = winningResource:GetRotation()%360
						
						-- Move the center of the winning resource to "wheelResourceTarget". This is made complicated by the resources alignment.
						winningResource:SetRotation(winningResourceRotation)
						local xOffset = (wheelResourceTarget:GetAbsoluteX() - winningResource:GetAbsoluteX())+winningResource:GetX()
						local yOffset = (wheelResourceTarget:GetAbsoluteY() - winningResource:GetAbsoluteY())+winningResource:GetY()
						winningResource:Rotate(180, 500)
						PlaySound('/heroes/bandito/ability_04/sounds/sfx_refund.wav')
						winningResource:SlideX(xOffset-winningResource:GetParent():GetWidth() /2, 500)
						winningResource:SlideY(yOffset-winningResource:GetParent():GetHeight()/2, 500)
						
						widget:UnregisterWatchLua('System')
						libThread.threadFunc(function()
							wait(200)
							GetWidget('wheel_spin_wheel_btn'):SetEnabled(true)
							if debug then
								updateCosts(wheelInfoResponseData)
							else
								updateCosts(responseData)
							end
						end)
					end
					

					--display rotation if spinning
					if (spinState < 2) then
						currentRotation = currentRotation + rotationSpeed
						wheelImage:SetRotation((180/pi)*(currentRotation+globalRotationAddition+wheelRotationAddition)) --spin main image
						wheelGlow:SetRotation((180/pi)*(currentRotation+globalRotationAddition+wheelRotationAddition)) --spin glowing image
						for n = 1, #segments do --spin added components, segments/icons
							--offsetWidgetPolar(interface:GetWidget('wheel_seperator'..(n-1)), currentRotation+segments[n][1]+globalRotationAddition, segments[n][2])
							offsetWidgetPolar(interface:GetWidget('wheel_icon'..(n-1)), currentRotation+icons[n][1]+globalRotationAddition+iconRotationAddition, 155)
						end
					end

				end, false, nil, 'hostTime')

				return true
			end
		end
		
		local failFunction =  function (request)	-- error handler
			SevereError('SpinWheel Request Error: ' .. Translate(request:GetError() or ''), 'main_reconnect_thatsucks', '', nil, nil, false)
			return nil
		end	
		
		if (debug) then
			successFunction()
		else
			Strife_Web_Requests:SpinWheel(successFunction, failFunction, wheelTrigger.lastWheel)
		end
	end

	GetWidget('wheel_sleeper'):RegisterWatchLua('LoginStatus', function(widget, trigger)
		if (trigger.isLoggedIn) and (trigger.isIdentPopulated) and (trigger.hasIdent) and (not wheelTrigger.hasWheelData) then -- has a spin?
			setup()
		else
			ClearData()
		end
	end, false, nil, 'isLoggedIn', 'hasIdent', 'isIdentPopulated')		

	GetWidget('wheelOfFortuneImage'):SetRotation((globalRotationAddition+wheelRotationAddition)*(180/pi))
	GetWidget('wheelOfFortuneGlow'):SetRotation((globalRotationAddition+wheelRotationAddition)*(180/pi))
	
	wheelTrigger.lastWheel					 = -1
	wheelTrigger.hasWheelData				 = false
	wheelTrigger.wheelSpinAvailable			 = false
	wheelTrigger.wheelSpinAvailableFree		 = false
	wheelTrigger:Trigger(false)
		
	
	interface:GetWidget('wheel_spin_wheel_btn'):SetCallback('onclick', function(widget)
		SpinWheel()
	end)

	function hideSpinnableWheel()
		GetWidget('wheel_background'):FadeOut(styles_mainSwapAnimationDuration)
		GetWidget('wheelOfFortune'):FadeOut(styles_mainSwapAnimationDuration)
	end
		
	local function showSpinnableWheel()
		GetWidget('wheel_moxie_model'):SetModel(GetEntityModel('Hero_Bandito'))
		GetWidget('wheel_moxie_model'):SetEffect(GetPreviewPassiveEffect('Hero_Bandito'))
		GetWidget('wheelOfFortune'):FadeIn(styles_mainSwapAnimationDuration)
		GetWidget('wheel_background'):FadeIn(styles_mainSwapAnimationDuration)
		GetWidget('wheel_moxie_model'):SetY("-1000s")
		GetWidget('wheel_moxie_model'):SetAnim('ability_4')
		
		libThread.threadFunc(function()
			wait(500)
			GetWidget('wheel_moxie_model'):SlideY("-70", 500)
			--PlaySound('/heroes/bandito/sounds/voice/vo_emote_1.wav')
		end)
		
		mainUI.Clans.Toggle(nil, true)
	end
	
	-- buttons
	interface:GetWidget('wheel_leave_wheel_btn'):SetCallback('onclick', function(widget)
		LuaTrigger.GetTrigger('mainPanelStatus').main=101
		LuaTrigger.GetTrigger('mainPanelStatus'):Trigger(false)
	end)
	
	-- main trigger
	local wheelVisible=false
	GetWidget('wheel_sleeper'):RegisterWatchLua('mainPanelStatus', function(widget, trigger)
		local newVisible = (trigger.main == 42)
		if (wheelVisible ~= newVisible) then
			if newVisible then
				libThread.threadFunc(function()
					wait(1)
					setMainTriggers({}) -- Default layout
					showSpinnableWheel()
				end)
			else
				hideSpinnableWheel()
			end
		end
		wheelVisible = newVisible
	end, false, nil, 'main')
end

WheelRegister(object)