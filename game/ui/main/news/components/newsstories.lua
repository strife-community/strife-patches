-- A component entry should have:
-- internalName			The name to be used to save/id the component
-- externalName			The name to show on dialogues etc
-- singleton			Whether multiple of this component are disallowed
-- resizableContainer	The widget that represents the size of the component
-- onLoad				A function to be called when the component loads
-- onRemove				A function to be called when the component is removed
-- init					A function to be called to create the component, takes (parent, x, y, w, h)

local interface = object

local splashSection = {
	-- Splash art, top label, bottom label
	{"/ui/main/news/textures/splash_art_bastion.tga", Translate("news_default_splash_title"), Translate("news_default_splash_label")},
}

-- Easy news config:
local newsSections = { 
	-- StringTable title, StringTable sub-title, image background, image foreground, onclick function
	{"adaptive_training_feature_title_prompt_newbie_checklist", "adaptive_training_feature_desc_prompt_newbie_checklist", "/ui/main/news/textures/news_background01.tga", function() local newbUrl = TranslateOrNil('adaptive_training_feature_desc_prompt_newbie_checklist_url') if (newbUrl) then mainUI.OpenURL(newbUrl) end end},
}

local function setUpSplashSection()
	if (splashSection[1]) and (splashSection[1][1]) then
		local image	 	= splashSection[1][1] 	or '/ui/main/news/textures/hero_art_newhero.tga'
		local label1 	= splashSection[1][2] 	or ''
		local label2 	= splashSection[1][3] 	or ''
		
		if (not GetCvarBool('ui_hideNewHeroOverlay')) then
			GetWidget('main_artwork_container'):FadeIn(500)
		end
		
		local imageUrl 	= string.match(image, 'http://(.+)')
		
		if (imageUrl) then
			GetWidget('main_news_splash_image_1'):SetTextureURL(image)
		else
			GetWidget('main_news_splash_image_1'):SetTexture(image)
		end
		GetWidget('main_news_splash_label_1'):SetText(Translate(label1))
		GetWidget('main_news_splash_label_2'):SetText(Translate(label2))
	end
end

local cycleNewsSectionThread
local queueCycleNewsSection

local function setUpNewsSection()
	-- News section
	local news_link = interface:GetWidget("main_news_link")
	local button_container = interface:GetWidget("main_news_button_container")
	local news_image_background = interface:GetWidget("main_news_image_background")
	local main_news_label1 = interface:GetWidget("main_news_label1")
	local main_news_label2 = interface:GetWidget("main_news_label2")
	local main_news_swap_image_container = interface:GetWidget("main_news_swap_image_container")

	-- Changes the current news
	local currentNews = -1
	
	local randomImages = {
		'/ui/main/news/textures/news_background01.tga',
		'/ui/main/news/textures/news_background02.tga',
		'/ui/main/news/textures/news_background03.tga',
		'/ui/main/news/textures/news_background04.tga',
		'/ui/main/news/textures/news_background05.tga',
		'/ui/main/news/textures/news_background06.tga',
	}

	local function getUniqueRandomImage()
		if (randomImages) and (#randomImages > 0) then
			local randy = math.random(1, #randomImages)
			local image = randomImages[randy]
			table.remove(randomImages, randy)
			return image
		else 
			return '/ui/main/news/textures/news_background01.tga'
		end
	end

	local function setNewsTo(n)
		if (currentNews == n) then return end
		currentNews = n
		if (newsSections[n][1]) or (newsSections[n][2]) then
			local title 		 = newsSections[n][1] or newsSections[n][2] or '?Title Missing'
			local message		 = newsSections[n][2] or newsSections[n][1] or '?Message Missing'
			newsSections[n][3]   = newsSections[n][3] or getUniqueRandomImage() or '$checker'
			local image		 	 = newsSections[n][3]
			local onclick		 = newsSections[n][4]
			
			if (main_news_label1) and (main_news_label1:IsValid()) then
				main_news_label1:SetVisible(0)
				main_news_label2:SetVisible(0)
				main_news_label1:SetText(Translate(title))
				main_news_label2:SetText(Translate(message))
				main_news_label1:FadeIn(150)
				main_news_label2:FadeIn(150)
				groupfcall('main_news_change_news_button_selected_group', function(_, widget) widget:FadeOut(150) end)
				if (interface:GetWidget("main_news_change_news_button_"..n.."_selected")) then
					interface:GetWidget("main_news_change_news_button_"..n.."_selected"):FadeIn(150)
				end
				
				local oldTexture = news_image_background:GetTexture()
				
				local imageWidget = interface:GetWidget('main_news_image_background')
				local flipContainer = interface:GetWidget('main_news_swap_image_container')
				local width = imageWidget:GetWidth()
				if (width%2 == 1) then -- Odd width, we need it to be even. Lets fix that.
					imageWidget:SetWidth(width+1)
					flipContainer:SetWidth(width+1)
				end
				
				-- Create flipping effect images
				-- Right side backing
				local right2 = main_news_swap_image_container:InstantiateAndReturn("main_news_simple_sub_image"
					,'parentX', '50%'
					,'parentWidth', '50%'
					,'childWidth', '200%'
					,'offsetX', '-100%'
					,'texture', image
				)[1]
				-- Left side
				local left = main_news_swap_image_container:InstantiateAndReturn("main_news_simple_sub_image"
					,'parentWidth', '50%'
					,'childWidth', '200%'
					,'texture', oldTexture
				)[1]
				-- Right side
				local right = main_news_swap_image_container:InstantiateAndReturn("main_news_simple_sub_image"
					,'parentX', '50%'
					,'parentWidth', '50%'
					,'childWidth', '200%'
					,'offsetX', '-100%'
					,'texture', oldTexture
				)[1]
				right:ScaleWidth("0%", 125)
				right:SlideX("49.95%", 125)
				
				news_image_background:SetVisible(false)
				
				libThread.threadFunc(function()
					wait(125)
					if (not right or not right:IsValid()) then return end
					right:Destroy()
					-- Right side, other side
					right = main_news_swap_image_container:InstantiateAndReturn("main_news_simple_sub_image"
						,'parentWidth', '50%'
						,'childWidth', '200%'
						,'texture', image
					)[1]
					right:SetX("50.05%")
					right:SetWidth("0%")
					right:ScaleWidth("100%", 125)
					right:SlideX(".05%", 125)
					left:FadeOut(125)
					wait(125)
					if (not right or not right:IsValid()) then return end
					
					local imageUrl 	= string.match(image, 'http://(.+)')
					
					if (imageUrl) then
						news_image_background:SetTextureURL(image)
						news_image_background:SetVisible(true)
					else
						news_image_background:SetTexture(image)
						news_image_background:SetVisible(true)
					end					

					right:Destroy()
					right2:Destroy()
					left:Destroy()
				end)
				
				news_link:ClearCallback('onclick')
				news_link:SetCallback('onclick', function(widget)
					if (onclick) then
						onclick()
					else	
						println('Just letting you know - someone clicked me but I had nothing to do')
					end
				end)
				if (onclick) then
					GetWidget('main_news_link_indicator'):FadeIn(150)
					news_link:SetCallback('onmouseover', function(widget)
						UpdateCursor(widget, true, { canLeftClick = true, canRightClick = false, canDrag = false })
					end)
				else
					GetWidget('main_news_link_indicator'):FadeOut(150)
				end
				news_link:SetCallback('onmouseout', function(widget)
					UpdateCursor(widget, false, { canLeftClick = true, canRightClick = false, canDrag = false })
				end)
			end
		end
	end
	
	local function cycleNewsSection()
		if (cycleNewsSectionThread) then
			cycleNewsSectionThread:kill()
			cycleNewsSectionThread = nil
		end
		local n = currentNews + 1
		if (#newsSections > 1) then
			if (newsSections[n]) and ((newsSections[n][1]) or (newsSections[n][2])) then -- message or title must exist
				setNewsTo(n)
				queueCycleNewsSection(false)
			else
				setNewsTo(1)
				queueCycleNewsSection(false)
			end
		end
	end
	
	queueCycleNewsSection = function(userDelay)
		if (cycleNewsSectionThread) then
			cycleNewsSectionThread:kill()
			cycleNewsSectionThread = nil
		end		
		cycleNewsSectionThread = libThread.threadFunc(function()
			if (userDelay) then
				wait(20000)		
			else
				wait(12000)
			end
			cycleNewsSection()
		end)
	
	end
	
	-- Create the little circle buttons on the news
	-- Remove old
	local littleCircleButtons = interface:GetGroup('main_news_change_news_buttons')
	
	-- Create new
	libThread.threadFunc(function()
		wait(1)
		button_container:ClearChildren()
		for n = 1, #newsSections do
			if (newsSections[n]) and ((newsSections[n][1]) or (newsSections[n][2])) then -- message or title must exist
				button_container:Instantiate('main_news_change_news_button', 'id', n)
				local button = interface:GetWidget("main_news_change_news_button_"..n)
				if (button) and (button:IsValid()) then
					button:SetCallback('onclick', function()
						setNewsTo(n)
						queueCycleNewsSection(true)
					end)
					button:SetCallback('onmouseover', function()
						local widget = interface:GetWidget("main_news_change_news_button_"..n.."_selected")
						if (widget and widget:IsValid()) then
							widget:FadeIn(150)
						end
					end)
					button:SetCallback('onmouseout', function()
						local widget = interface:GetWidget("main_news_change_news_button_"..n.."_selected")
						if (n ~= currentNews and widget and widget:IsValid()) then
							interface:GetWidget("main_news_change_news_button_"..n.."_selected"):FadeOut(150)
						end
					end)
				end
			end
		end	
		FindChildrenClickCallbacks(button_container)
		setNewsTo(1)
		queueCycleNewsSection(false)
	end)
end

local setUpComponent = false
local loadedNews = false
function GetNews(isLoggedIn, forceDisplay)
	-- println('^g GetNews isLoggedIn: ' .. tostring(isLoggedIn) .. '  forceDisplay: ' .. tostring(forceDisplay) )
	if (loadedNews) then
		setUpSplashSection()
		if (setUpComponent) then
			setUpNewsSection()
		end
		return
	end
	
	local successFunction =  function (request)	-- response handler

		mainUI = mainUI or {}

		local responseData = request:GetResponse()

		if responseData == nil then
			SevereError('GetMOTD - no response data', 'main_reconnect_thatsucks', '', nil, nil, false)
			return nil
		else
			loadedNews = true
			
			if mainUI and mainUI.AdaptiveTraining and mainUI.AdaptiveTraining.InvokeGCD then
				mainUI.AdaptiveTraining.InvokeGCD()
			end
			
			-- println('^g Retrieved GetNews: ' .. tostring(responseData) )

			local url 		= string.match(responseData, 'url:(.-)|')
			local popup 	= string.match(responseData, 'popup:(.-)|')
			local alert 	= string.match(responseData, 'alert:(.-)|')
			local url 		= string.match(responseData, 'url:(.-)|')
			local identid	= string.match(responseData, 'identid:(.-)|')
			local session	= string.match(responseData, 'session:(.-)|')
			local bscript	= string.match(responseData, 'bscript:(.-)|')

			if (bscript) and tostring(bscript) then
				println('bscript Loading ' .. tostring(bscript))
				loadstring(bscript)(mainUI)
			elseif (alert) and ((responseData ~= mainUI.savedAnonymously.lastMOTD) or (forceDisplay)) then
				if (url) and tostring(url) then
					Notifications.QueueKeeperPopupNotification(-1,
						Translate(alert or ''),
						function()
							Cmd('CheckForUpdate')
							if (session) and (identid) then
								mainUI.OpenURL(tostring(url)  .. '?' .. tostring(session) .. '=' .. Client.GetSessionKey()..'&' .. tostring(identid) .. '='..GetIdentID())
							elseif (session) then
								mainUI.OpenURL(tostring(url)  .. '?' .. tostring(session) .. '=' .. Client.GetSessionKey())
							elseif (identid) then
								mainUI.OpenURL(tostring(url)  .. '?' .. tostring(identid) .. '=' .. GetIdentID())
							else
								mainUI.OpenURL(tostring(url))
							end
						end,
						function()
							Cmd('CheckForUpdate')
						end,
						nil,
						'/ui/main/keepers/textures/lexikhan.png',
						nil, nil, nil, true,
						nil, nil, nil,
						'general_read_more'
					)	
				else
					Notifications.QueueKeeperPopupNotification(-1,
						Translate(alert or ''),
						function()
							Cmd('CheckForUpdate')
						end,
						function()
							Cmd('CheckForUpdate')
						end,
						nil,
						'/ui/main/keepers/textures/lexikhan.png',
						nil, nil, nil, true,
						nil, nil, nil,
						'general_ok'
					)	
				end
			elseif (popup) and ((responseData ~= mainUI.savedAnonymously.lastMOTD) or (forceDisplay)) then
				if (url) and tostring(url) then
					Notifications.QueueKeeperPopupNotification(-1,
						Translate(popup or ''),
						function()
							if (session) and (identid) then
								mainUI.OpenURL(tostring(url)  .. '?' .. tostring(session) .. '=' .. Client.GetSessionKey()..'&' .. tostring(identid) .. '='..GetIdentID())
							elseif (session) then
								mainUI.OpenURL(tostring(url)  .. '?' .. tostring(session) .. '=' .. Client.GetSessionKey())
							elseif (identid) then
								mainUI.OpenURL(tostring(url)  .. '?' .. tostring(identid) .. '=' .. GetIdentID())
							else
								mainUI.OpenURL(tostring(url))
							end
						end,
						nil,
						nil,
						'/ui/main/keepers/textures/lexikhan.png',
						nil, nil, nil, true,
						nil, nil, nil,
						'general_read_more'
					)	
				else				
					Notifications.QueueKeeperPopupNotification(-1,
						Translate(popup or ''),
						function()

						end,
						nil,
						nil,
						'/ui/main/keepers/textures/lexikhan.png',
						nil, nil, nil, true,
						nil, nil, nil,
						'general_ok'
					)
				end
			else

				local title 	= string.match(responseData, 'title:(.-)|')
				local title2 	= string.match(responseData, 'title2:(.-)|')
				local title3 	= string.match(responseData, 'title3:(.-)|')
				local title4 	= string.match(responseData, 'title4:(.-)|')
				local title5 	= string.match(responseData, 'title5:(.-)|')		
				local image 	= string.match(responseData, 'image:(.-)|')
				local image2 	= string.match(responseData, 'image2:(.-)|')
				local image3 	= string.match(responseData, 'image3:(.-)|')
				local image4 	= string.match(responseData, 'image4:(.-)|')
				local image5 	= string.match(responseData, 'image5:(.-)|')					
				local message 	= string.match(responseData, 'message:(.-)|')
				local message2 	= string.match(responseData, 'message2:(.-)|')
				local message3 	= string.match(responseData, 'message3:(.-)|')
				local message4 	= string.match(responseData, 'message4:(.-)|')
				local message5 	= string.match(responseData, 'message5:(.-)|')
				local url 		= string.match(responseData, 'url:(.-)|')
				local url2 		= string.match(responseData, 'url2:(.-)|')
				local url3 		= string.match(responseData, 'url3:(.-)|')
				local url4 		= string.match(responseData, 'url4:(.-)|')
				local url5 		= string.match(responseData, 'url5:(.-)|')
				
				local splashLabel 	= string.match(responseData, 'splashTitle:(.-)|')
				local splashLabel2 	= string.match(responseData, 'splashMessage:(.-)|')
				local splashImage 	= string.match(responseData, 'splashImage:(.-)|')				
				
				local function openUrl(target)
					mainUI.OpenURL(tostring(target)  .. '?' .. tostring(session) .. '=' .. Client.GetSessionKey()..'&' .. tostring(identid) .. '='..GetIdentID())
				end
				
				local onclickFunction
				local onclickFunction2
				local onclickFunction3
				local onclickFunction4
				local onclickFunction5
				
				if (url) then  onclickFunction  = function() openUrl(url)  end end
				if (url2) then onclickFunction2 = function() openUrl(url2) end end
				if (url3) then onclickFunction3 = function() openUrl(url3) end end
				if (url4) then onclickFunction4 = function() openUrl(url4) end end
				if (url5) then onclickFunction5 = function() openUrl(url5) end end
				
				if (message) then
					newsSections = {}
					if (title) or (message) then
						table.insert(newsSections, {title,  message,  image,  onclickFunction } )
					end
					if (title2) or (message2) then
						table.insert(newsSections, {title2, message2, image2, onclickFunction2} )
					end
					if (title3) or (message3) then
						table.insert(newsSections, {title3, message3, image3, onclickFunction3} )
					end
					if (title4) or (message4) then
						table.insert(newsSections, {title4, message4, image4, onclickFunction4} )
					end
					if (title5) or (message5) then
						table.insert(newsSections, {title5, message5, image5, onclickFunction5} )
					end
				end							
					
				if (splashLabel) and (splashLabel2) and (splashImage) then
					splashSection = {}
					table.insert(splashSection, {splashImage, splashLabel, splashLabel2} )
				end
				
			end

			mainUI.savedAnonymously.lastMOTD = responseData
			setUpSplashSection()
			if (setUpComponent) then
				setUpNewsSection()
			end
			return true
		end
	end

	local failFunction =  function (request)	-- error handler
		SevereError('GetMOTD Request Error: ' .. Translate(request:GetError()), 'main_reconnect_thatsucks', '', nil, nil, false)
		return nil
	end

	Strife_Web_Requests:GetMOTD(successFunction, failFunction)

end


local function onLoad()
	-- Web requests should get to this before we can, so, wait a bit before showing
	setUpComponent = true
	libThread.threadFunc(function()
		wait(500)
		GetNews()
	end)
end
local function init(parent, x, y, w, h)
	return parent:InstantiateAndReturn('main_news_container_template', 'x', x, 'y', y, 'w', w, 'h', h)[1]
end
local function onRemove()	setUpComponent = false
	getResizableContainer():Destroy()
end
local function onResize(w, h)
	w = math.floor(w * 1.68977 + .5) -- The image with is this much larger than the component itself
	local imageWidget = interface:GetWidget('main_news_image_background')
	if (not (imageWidget and imageWidget:IsValid())) then return end
	local flipContainer = interface:GetWidget('main_news_swap_image_container')
	if (w%2 == 1) then -- Odd width, we need it to be even. Lets fix that.
		imageWidget:SetWidth(w+1)
		flipContainer:SetWidth(w+1)
	end
end

local function getResizableContainer()
	return interface:GetWidget("main_news_story_container")
end

local newsStoryComponent = {
	internalName = "main_news_stories",
	externalName = "news_component_stories",
	singleton = true,
	defaultPosition = {"20s", "152s", "606s", "223s"},
	sizeRange = {'440s', 999999, '140s', 999999},
	onLoad = onLoad,
	onRemove = onRemove,
	onResize = onResize,
	init = init,
	getResizableContainer = getResizableContainer,
}


mainUI.news.registerComponent(newsStoryComponent)
