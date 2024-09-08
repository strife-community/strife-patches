mainUI = mainUI or {}
mainUI.news = mainUI.news or {}
mainUI.news.data = mainUI.news.data or {}
mainUI.savedLocally 	= mainUI.savedLocally 		or {}
mainUI.savedRemotely 	= mainUI.savedRemotely 		or {}
local interface = object

local function registerNews(interface)
	-----------
	-- Variables
	-----------
	
	mainUI.news.allComponents = {} -- Holds info for every component we know about
	local curComponents = {} -- Holds info for every active component, which can contain multiple of the same instance
	
	local initialized = false
	function mainUI.news.init()
		-- Load components from remote or local, whichever is more recent
		mainUI.savedLocally.newsComponents = -- mainUI.savedLocally.newsComponents or 
		{
			{name="main_news_stories", x="20s", y="152s", w="606s", h="223s"},
			--{name="main_news_bot_match", x="20s", y="390s", w="606s", h="83s"},
			{name="main_news_discord", x="20s", y="390s", w="606s", h="83s"},
			{name="main_news_progression", x="20s", y="508s", w="606s", h="190s"},			
			revision = 1
		}

		mainUI.savedRemotely.newsComponents = mainUI.savedLocally.newsComponents -- mainUI.savedRemotely.newsComponents or 
		-- if (mainUI.savedLocally) and (mainUI.savedLocally.newsComponents) and (mainUI.savedLocally.newsComponents.revision) and (mainUI.savedRemotely) and (mainUI.savedRemotely.newsComponents) and (mainUI.savedRemotely.newsComponents.revision) and (mainUI.savedLocally.newsComponents.revision >= mainUI.savedRemotely.newsComponents.revision) then
			-- mainUI.savedRemotely.newsComponents = mainUI.savedLocally.newsComponents
		-- end
	end
	
	function mainUI.news.cur()
		return curComponents
	end
	
	-- A component entry should have: ( [optional] (internally set) )
	-- internalName					The name to be used to save/id the component
	-- externalName					The name to show on dialogues etc
	-- singleton					Whether multiple of this component is disallowed
	-- defaultPosition				{x, y, w, h}
	-- [sizeRange]					{minWidth, maxWidth, minHeight, maxHeight}
	-- onLoad()						A function to be called when the component loads, takes (uniqueID)
	-- onRemove()					A function to be called when the component is removed, takes (uniqueID)
	-- getResizableContainer()		A function to be called to get the widget with the resizeable area, takes (uniqueID). Nil means it should be able to be resized.
	-- init()						A function to be called to create the component, takes (parent, x, y, w, h, uniqueID, extraData[if any]). Returns instantiated widget
	-- [onResize()]					A function to be called when resizing the component, takes (w, h, uniqueID)
	-- (internally added) widget	The created component
	-- (internally added) selectionWidget	The widget that blocks clicking to the panel, and allows selection of it
	-- [createConfigWidget]			Extra data is sometimes needed for a component, this allows the component to create it's configuration interface. Takes parent, returns widget
	-- [interpretConfigWidget]		Read data from the created widget to help create the widget. Returns extraData
	
	-----------
	-- Editing
	-----------
	local sizer = interface:GetWidget("main_news_component_sizer")
	local mover = interface:GetWidget("main_news_component_mover")
	local main_news_edit_button = interface:GetWidget("main_news_edit_button")
	local main_news_edit_button_img = interface:GetWidget("main_news_edit_button_img")
	local main_news_component_manager_container = interface:GetWidget("main_news_component_manager_container")
	local editing = false
	local clickToSelectInEditor = false
	local function hideResizer()
		sizer:SetVisible(false)
		mover:SetVisible(false)
		UnwatchLuaTriggerByKey('System', 'newsResizeKey')
	end
	
	function mainUI.news.Reset()
		mainUI.savedRemotely.newsComponents = nil
		mainUI.savedLocally.newsComponents = nil
		Cmd("clear")
		Cmd("reloadinterfaces")
	end
	function mainUI.news.SavePositions()
		local n = 1
		local revision = mainUI.savedRemotely.newsComponents.revision
		mainUI.savedRemotely.newsComponents = {}
		for _,component in pairs(curComponents) do
			local widget = component.widget
			mainUI.savedRemotely.newsComponents[n] = mainUI.savedRemotely.newsComponents[n] or {}
			mainUI.savedRemotely.newsComponents[n].name = component.internalName
			mainUI.savedRemotely.newsComponents[n].extraData = component.extraData
			mainUI.savedRemotely.newsComponents[n].x = pixelsToUnit(widget:GetX(), widget, false, 's')
			mainUI.savedRemotely.newsComponents[n].y = pixelsToUnit(widget:GetY(), widget, true, 's')
			mainUI.savedRemotely.newsComponents[n].w = pixelsToUnit(widget:GetWidth(), widget, false, 's')
			mainUI.savedRemotely.newsComponents[n].h = pixelsToUnit(widget:GetHeight(), widget, true, 's')
			n = n + 1
		end
		mainUI.savedRemotely.newsComponents.revision = revision + 1
		mainUI.savedLocally.newsComponents = mainUI.savedRemotely.newsComponents
	end
	
	function mainUI.news.StartEditing()
		editing = true
		main_news_edit_button_img:SetTexture("/ui/shared/twitch/textures/save_icon.tga")
		main_news_edit_button:Scale('50s', '50s', 50)
		main_news_component_manager_container:FadeIn(125)
		for n,component in pairs(curComponents) do
			local resizableContainer = component.getResizableContainer(n)
			if (not resizableContainer) then
				resizableContainer = component.widget
			end
			if (clickToSelectInEditor) then
				component.selectionWidget = resizableContainer:InstantiateAndReturn("main_news_simple_panel")[1]
				component.selectionWidget:SetCallback('onclick', function(widget)
					mainUI.news.resizeComponent(component.ID)
				end)
			end
		end
	end
	
	function mainUI.news.StopEditing(save, cancel)
		editing = false
		main_news_edit_button_img:SetTexture("/ui/shared/textures/edit.tga")
		main_news_edit_button:Scale('30s', '30s', 50)
		main_news_component_manager_container:FadeOut(125)
		for _,component in ipairs(mainUI.savedRemotely.newsComponents) do
			if (component.selectionWidget and component.selectionWidget:IsValid()) then
				component.selectionWidget:Destroy()
			end
		end
		hideResizer()
		if (save) then
			mainUI.news.SavePositions()
		elseif (cancel) then
			for k, v in pairs(curComponents) do
				mainUI.news.removeComponent(k, true)
			end
			libThread.threadFunc(function()
				wait(1)
				mainUI.news.loadComponents()
			end)
		end
	end
	
	function mainUI.news.ToggleEditing()
		if editing then
			mainUI.news.StopEditing(true)
		else
			mainUI.news.StartEditing()
		end
	end
	
	function mainUI.news.registerComponent(componentEntry)
		mainUI.news.allComponents[componentEntry.internalName] = componentEntry
	end
	function mainUI.news.componentFromID(ID, returnKey)
		for k, v in pairs(curComponents) do
			if (tonumber(v.ID) == tonumber(ID)) then
				if (returnKey) then
					return k
				else
					return v
				end
			end
		end
		println("^rComponent "..ID.." not found!")
	end
	function mainUI.news.componentExists(name)
		for k, v in pairs(curComponents) do
			if (v.internalName == name) then
				return true
			end
		end
		return false
	end
	
	UnwatchLuaTriggerByKey('System', 'newsResizeKey')
	function mainUI.news.resizeComponent(index)
		local component = mainUI.news.componentFromID(index)
		local resizing_widget = component.getResizableContainer(component.ID)
		local canResize = true
		if (not resizing_widget) then
			resizing_widget = component.widget
			canResize = false
		end
		hideResizer()
		local sizer = canResize and sizer or mover
		local sizeRange = component.sizeRange or {0, 999999, 0, 999999}
		for n = 1, 4 do
			sizeRange[n] = sizer:GetWidthFromString(sizeRange[n])
		end
		sizer:SetX(resizing_widget:GetAbsoluteX())
		sizer:SetY(resizing_widget:GetAbsoluteY())
		sizer:SetWidth(resizing_widget:GetWidth())
		sizer:SetHeight(resizing_widget:GetHeight())
		sizer:SetVisible(true)
		
		WatchLuaTrigger('System', function(groupTrigger)
			if (not (resizing_widget and resizing_widget:IsValid())) then return end
			resizing_widget:SetX(sizer:GetAbsoluteX())
			resizing_widget:SetY(sizer:GetAbsoluteY())
			if (canResize) then
				--println(sizer:GetWidth() .. ', ' .. sizer:GetHeight())
				if (sizer:GetWidth() < sizeRange[1]) then sizer:SetWidth( sizeRange[1]) end
				if (sizer:GetWidth() > sizeRange[2]) then sizer:SetWidth( sizeRange[2]) end
				if (sizer:GetHeight()< sizeRange[3]) then sizer:SetHeight(sizeRange[3]) end
				if (sizer:GetHeight()> sizeRange[4]) then sizer:SetHeight(sizeRange[4]) end
				resizing_widget:SetWidth(sizer:GetWidth())
				resizing_widget:SetHeight(sizer:GetHeight())
				if (component.onResize) then
					component.onResize(sizer:GetWidth(), sizer:GetHeight(), component.ID)
				end
			end
		end, 'newsResizeKey')
	end
	
	function mainUI.news.removeComponent(index, isKey)
		hideResizer()
		if (not isKey) then
			index = mainUI.news.componentFromID(index, true)
		end
		curComponents[index].widget:Destroy()
		curComponents[index] = nil
	end
	
	local componentParent = interface:GetWidget('main_news_component_container')
	
	-----------
	-- Loading components
	-----------
	function mainUI.news.loadComponent(name, x, y, w, h, extraData)
		local newComponent = table.copy(mainUI.news.allComponents[name]) -- Load detailed info about widget
		
		local x = x or newComponent.defaultPosition[1]
		local y = y or newComponent.defaultPosition[2]
		local w = w or newComponent.defaultPosition[3]
		local h = h or newComponent.defaultPosition[4]
	
		if (newComponent == nil) then
			SevereError('Component '.. tostring(name) .. " unregistered.. Is it's lua file being loaded?", 'main_reconnect_thatsucks', '', nil, nil, false)
		end
		newComponent.ID = mainUI.news.componentUniqueID
		newComponent.widget = newComponent.init(componentParent, x, y, w, h, newComponent.ID, extraData)
		newComponent.extraData = extraData
		newComponent.onLoad(newComponent.ID)
		mainUI.news.componentManager.AddToList(newComponent)
		mainUI.news.componentUniqueID = mainUI.news.componentUniqueID + 1
		table.insert(curComponents, newComponent)
	end
	
	
	-- Load components which are initially active
	mainUI.news.componentUniqueID = 1
	function mainUI.news.loadComponents()
		mainUI.news.componentManager.ClearList()
		for _, v in pairs(mainUI.savedRemotely.newsComponents) do
			if (v) and (type(v) == 'table') then
				mainUI.news.loadComponent(v.name, v.x, v.y, v.w, v.h, v.extraData)
			end
		end
	end
	
	-----------
	-- Editing
	-----------
	local main_sleeper = interface:GetWidget("main_news_sleeper")
	local main_container = interface:GetWidget("main_news_container")
	
	-- Edit button
	interface:GetWidget("main_news_edit_button"):SetVisible(GetCvarBool('ui_editable_news'))
	
	local selectModeInfo = LuaTrigger.GetTrigger('selectModeInfo') or LuaTrigger.CreateCustomTrigger('selectModeInfo', {
		{ name	= 'queuedMode',		type		= 'string' }
	})
	
	
	main_sleeper:RegisterWatchLua('mainPanelAnimationStatus', function(widget, trigger)
		local animState = mainSectionAnimState(mainUI.MainValues.news, trigger.main, trigger.newMain)
		if animState == 1 then			-- outro
			--mainUI.news.StopEditing()
			fadeWidget(main_container, false)
			animateChildren(componentParent, false)
		elseif animState == 2 then			-- fully hidden
			main_container:SetVisible(false)	
		elseif animState == 3 then		-- intro
			if (not initialized) then
				initialized = true
				mainUI.news.init()
				mainUI.news.loadComponents()
			end
			
			libThread.threadFunc(function()	
				wait(1)
				setMainTriggers({}) -- Default layout
				fadeWidget(main_container, true)
				animateChildren(componentParent, true)
				if (mainUI.savedRemotely.newsComponents) then
					for n = 1, #mainUI.savedRemotely.newsComponents do
						local component = mainUI.savedRemotely.newsComponents[n]
						if (mainUI.news.allComponents[component.name].onShow) then mainUI.news.allComponents[component.name].onShow() end
					end
				else
					println("^yWarning, components not loaded!")
				end
			end)
		elseif animState == 4 then										-- fully displayed

			if (not initialized) then
				initialized = true
				mainUI.news.init()
				mainUI.news.loadComponents()
				
				libThread.threadFunc(function()	
					wait(1)
					setMainTriggers({}) -- Default layout
					fadeWidget(main_container, true)
					animateChildren(componentParent, true)
					if (mainUI.savedRemotely.newsComponents) then
						for n = 1, #mainUI.savedRemotely.newsComponents do
							local component = mainUI.savedRemotely.newsComponents[n]
							if (mainUI.news.allComponents[component.name].onShow) then mainUI.news.allComponents[component.name].onShow() end
						end
					else
						println("^yWarning, components not loaded!")
					end
				end)
			end

			main_container:SetVisible(true)
		end
	end, false, nil, 'main', 'newMain')
end

registerNews(interface)