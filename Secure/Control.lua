local IMM_UI, L = ...
local UIParent, assert, pairs = UIParent, assert, pairs 
local Registry = L.SecFrameRegistry
----------------------------------
local Control = L:CreateFrame('Button', IMM_UI..'Handle', nil, 'SecureHandlerBaseTemplate, SecureHandlerStateTemplate, SecureHandlerAttributeTemplate, SecureActionButtonTemplate', {
	----------------------------------
	-- Control input handling
	----------------------------------
	Attrib = {
		SetFocusFrame = [[
			if #stack > 0 then
				focusFrame = stack[1]
				--MouseHandle:SetAttribute('blockhandle', true)
				self:SetAttribute('focus', focusFrame)
				self:ClearBindings()
				for binding, identifier in pairs(keys) do
					local key = GetBindingKey(binding)
					if key then
						self:SetBindingClick(true, key, self:GetFrameRef(binding), identifier)
					end
				end
				return true
			else
				focusFrame = nil
				--MouseHandle:SetAttribute('blockhandle', false)
				self:SetAttribute('focus', nil)
				self:ClearBindings()
				return false
			end
		]],

		AddFrame = [[
			local added = self:GetAttribute('add')

			local oldStack = stack
			stack = newtable()

			stack[1] = added

			for _, frame in pairs(oldStack) do
				if frame ~= added then
					stack[#stack + 1] = frame
				end
			end
		]],

		RemoveFrame = [[
			local removed = self:GetAttribute('remove')

			local oldStack = stack
			stack = newtable()

			for _, frame in pairs(oldStack) do
				if frame ~= removed then
					stack[#stack + 1] = frame
				end
			end
		]],

		RefreshFocus = [[
			if control:RunAttribute('SetFocusFrame') then
				--control:CallMethod('SetHintFocus')
				--control:CallMethod('RestoreHints')
				for i=2, #stack do
					control:CallMethod('SetIgnoreFadeFrame', stack[i]:GetName(), false)
				end
				if focusFrame:GetAttribute('hideUI') then
					control:CallMethod('ShowUI')
					control:CallMethod('HideUI',
						focusFrame:GetName(), 
						focusFrame:GetAttribute('hideActionBar'))
				end
			else
				--control:CallMethod('SetHintFocus')
				control:CallMethod('ShowUI')
				--control:CallMethod('HideHintBar')
			end
		]],

		RefreshStack = [[
			if self:GetAttribute('add') then
				control:RunAttribute('AddFrame')
			end

			if self:GetAttribute('remove') then
				control:RunAttribute('RemoveFrame')
			end

			self:SetAttribute('add', nil)
			self:SetAttribute('remove', nil)
		]],
	--------------------------------------------
	},
	{
		StoredHints = {},
		HintBar = {
			Type = 'Frame',
			Strata = 'FULLSCREEN_DIALOG',
			SetParent = UIParent,
			Hide = true,
			Height = 72,
			Point = {'BOTTOM', 0, 0},
			{
				Gradient = {
					Type = 'Texture',
					Setup = {'BACKGROUND'},
					SetColorTexture = {1, 1, 1},
					Height = 72,
					Points = {
						{'BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 0, 0},
						{'BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', 0, 0},
					},
				},
				Active = {},
				Frames = {},
			},
		},
	},
})
local Bar, Hint = Control.HintBar, {}
----------------------------------

local function ControlCallMethodInner(frame, methodName, ...)
    local method = frame[methodName];
    -- Ensure code isn't run securely
    forceinsecure();
    if (type(method) ~= "function") then
        error("Invalid method '" .. methodName .. "'");
        return;
    end
    method(frame, ...); 
end

function Control:CallMethodFromFrame(srcframe, methodName, ...) 
	local frame = _G[srcframe]   
    if (not frame) then
        error("Invalid control handle");
        return;
    end
    if (type(methodName) ~= "string") then
        error("Method name must be a string");
        return;
    end
    -- Use a pcall wrapper here to ensure that execution continues
    -- regardless
    local ok, err =
        securecall(pcall, ControlCallMethodInner, frame, methodName, scrub(...));
    if (err) then
        --print(err)
    end
end

--------------------------------------------

local secure_wrappers = {
	PreClick = [[
		self:SetAttribute('type', nil)
		self:SetAttribute('macrotext', nil)
		self:SetAttribute('clickbutton', nil)
		local frame = stack[1]
		if frame:GetAttribute('useCursor') then
			-- NYI
		elseif frame:GetAttribute('OnInput') then
			if(frame:GetAttribute('currentfocus')) then self:SetAttribute('currentfocus', _G[frame:GetAttribute('currentfocus')]) end
			
			local clickType, clickHandler, clickValue = control:RunFor(frame, frame:GetAttribute('OnInput'), tonumber(button), down)
			if clickType and clickHandler and clickValue then
				if(clickHandler == 'please' and clickValue == 'callmethod') then -- lol
					control:CallMethod('CallMethodFromFrame', frame:GetName(), 'OnInputSecond', button, down)
				else 
					self:SetAttribute('type', clickType)
					self:SetAttribute(clickHandler, clickValue) 
				end
			end
		else
			control:CallMethod('CallMethodFromFrame', frame:GetName(), 'OnInput', button, down, self:GetAttribute('keyname'))  
		end
	]],
}

Control:Execute([[
	Control = self
	stack, keys = newtable(), newtable()
]]) -- (2) (3)

---------------------------------- 

-- If the no bindings are currently being used by the key, GetBindingByKey will return nil, so we will just use
-- SetBinding to set a binding to this key, because we are not able to use an unbinded key here.
local LastBindings = {}
local InputHanders = {}

local cpDatabase, UIKeys

if(ConsolePort) then
	cpDatabase = ConsolePort:GetData()

	UIKeys = {
		[cpDatabase.KEY.UP] = true,
		[cpDatabase.KEY.DOWN] = true,
		[cpDatabase.KEY.LEFT] = true,
		[cpDatabase.KEY.RIGHT] = true,
		[cpDatabase.KEY.SQUARE] = true,
		[cpDatabase.KEY.CIRCLE] = true,
		[cpDatabase.KEY.CROSS] = true,
		[cpDatabase.KEY.TRIANGLE] = true,
		[cpDatabase.KEY.OPTIONS] = true,
		[cpDatabase.KEY.CENTER] = true,
		[cpDatabase.KEY.SHARE] = true
	}
end

local function UpdateBindingsHelper(binding, uikey, btname)
	-- keys [string binding] = [integer key]
	Control:Execute(([[ keys.%s = '%s' ]]):format(binding, uikey))

	local inputHandler, wrapped

	local buttonName = (btname and btname or binding)

	
	for _, obj in pairs(InputHandlers) do  
		if string.match(obj:GetName(), buttonName) then
			inputHandler = obj
			wrapped = true
		end
	end

	if(not inputHandler) then
		inputHandler = CreateFrame('Button', '$parent_'..buttonName, Control, 'SecureActionButtonTemplate')
		inputHandler.binding = binding
	end
	-- Register for any input, since these will simulate integer keys.
	inputHandler:RegisterForClicks('AnyUp', 'AnyDown')
	-- Assume macro initially; input handler may change between macro/click.
	inputHandler:SetAttribute('type', 'macro')
	-- Reference the handler so it can be bound securely.
	Control:SetFrameRef(binding, inputHandler)
	-- Set up click wrappers for the input handlers.
	for name, script in pairs(secure_wrappers) do
		if(not wrapped) then
			Control:WrapScript(inputHandler, name, script) 
		end
	end

	if(not wrapped) then
		table.insert(InputHandlers, inputHandler) 
	end
end

function Control:UpdateBindings()
	if(InCombatLockdown()) then
		-- bindings can only be updated outside combat
		return
	end

	if(not ConsolePort) then
		for k, bind in pairs(LastBindings) do
			-- clear bindings
			SetBinding(bind)
			LastBindings[k] = nil
		end

		if(L.cfg.accept and not GetBindingByKey(L.cfg.accept)) then		
			SetBinding(L.cfg.accept, "TOGGLESHEATH")
			table.insert(LastBindings, L.cfg.accept)
		end
		if(L.cfg.reset and not GetBindingByKey(L.cfg.reset)) then 
			SetBinding(L.cfg.reset, "REPLY")
			table.insert(LastBindings, L.cfg.reset)
		end
		if(L.cfg.goodbye and not GetBindingByKey(L.cfg.goodbye)) then 
			SetBinding(L.cfg.goodbye, "ASSISTTARGET")
			table.insert(LastBindings, L.cfg.goodbye)
		end
	end

	if not InputHandlers then
		InputHandlers = {}
	else
		for _, obj in pairs(InputHandlers) do 
			Control:Execute(([[ keys.%s = nil ]]):format(obj.binding))
		end
	end

	if(ConsolePort) then
		for binding in ConsolePort:GetBindings() do -- (3) (4)
			local UIkey = ConsolePort:GetUIControlKey(binding)
			if UIkey then
				if UIKeys[UIkey] then
					UpdateBindingsHelper(binding, UIkey)
				end
			end
		end
	else
		for i = 1, GetNumBindings() do 
			local command = GetBinding(i); 
			local key1, key2 = GetBindingKey(command)
			if ((key1 == L.cfg.accept or key1 == L.cfg.reset or key1 == L.cfg.goodbye or key1 == "ESCAPE") or (key2 == L.cfg.accept or key2 == L.cfg.reset or key2 == L.cfg.goodbye or key2 == "ESCAPE")) then
				local binding = command
				local keyname
				if(key1 == L.cfg.accept or key1 == L.cfg.reset or key1 == L.cfg.goodbye or key1 == "ESCAPE") then
					keyname = key1
				else
					keyname = key2
				end

				UpdateBindingsHelper(binding, i, keyname == L.cfg.accept and 'AcceptButton' or (keyname == L.cfg.reset and 'ResetButton' or (keyname == L.cfg.goodbye and 'GoodbyeButton' or 'EscapeButton')))
			end
		end
	end
end

----------------------------------
-- Control API
----------------------------------
function L:GetControlHandle() return Control end
----------------------------------

function L:RegisterFrame(frame, ID, useCursor, hideUI, hideActionBar) 
	assert(frame, 'Frame handle does not exist.')
	assert(frame:IsProtected(), 'Frame handle is not protected.')
	assert(frame.Execute, 'Frame handle does not have a base template.')
	assert(not InCombatLockdown(), 'Frame handle cannot be registered in combat.')
	assert(ID, 'Frame handle does not have an ID.') 
	Control:RegisterFrame(frame, ID, useCursor, hideUI, hideActionBar)
	
	return true
end
----------------------------------
Control:SetAttribute('type', 'macro')
Control:RegisterForClicks('AnyUp', 'AnyDown') 

function Control:RegisterFrame(frame, ID, useCursor, hideUI, hideActionBar)
--	frame:Execute(button_identifiers)
	frame:SetAttribute('useCursor', useCursor)
	frame:SetAttribute('hideUI', hideUI)
	frame:SetAttribute('hideActionBar', hideActionBar)
	frame:SetFrameRef('control', self)
	self:SetFrameRef(ID, frame)
	self:WrapScript(frame, 'OnShow', [[
		Control:SetAttribute('add', self)
		control:RunFor(Control, Control:GetAttribute('RefreshStack'))
		control:RunFor(Control, Control:GetAttribute('RefreshFocus'))		
		control:CallMethod('CallMethodFromFrame', Control:GetName(), 'UpdateBindings')
	]])
	self:WrapScript(frame, 'OnHide', [[
		Control:SetAttribute('remove', self)
		control:CallMethod('CallMethodFromFrame', Control:GetName(), 'ClearHintsForFrame')
		control:RunFor(Control, Control:GetAttribute('RefreshStack'))
		control:RunFor(Control, Control:GetAttribute('RefreshFocus'))
	]])
end

----------------------------------
-- UI Fader
----------------------------------

local FadeIn = function (frame, timeToFade, startAlpha, endAlpha, info) 
end

local FadeOut = function (frame, timeToFade, startAlpha, endAlpha, info)
	
end
 
local updateThrottle = 0
local ignoreFrames = {
	[Control] = true,
	[Control.HintBar] = true,
	[AlertFrame] = true,
	--[ArtifactLevelUpToast] = true,
	[ChatFrame1] = true,
	[CastingBarFrame] = true,
	[Minimap] = true,
	[MinimapCluster] = true,
	[GameTooltip] = true,
	--[QuickJoinToastButton] = true,
	[StaticPopup1] = true,
	[StaticPopup2] = true,
	[StaticPopup3] = true,
	[StaticPopup4] = true,
	[SubZoneTextFrame] = true,
	[ShoppingTooltip1] = true,
	[ShoppingTooltip2] = true,
	--[OverrideActionBar] = true,
	--[ObjectiveTrackerFrame] = true,
	[UIErrorsFrame] = true,
	----------------------------------
	['TalkingHeadFrame'] = true,
}
local forceFrames = {
	--['ConsolePortBar'] = true,
	--['MainMenuBar']  = true,
}

local function GetFadeFrames(onlyActionBars)
	local fadeFrames, frameStack = {}
	if onlyActionBars then
		frameStack = {}
		for registeredFrame in pairs(Registry) do
			frameStack[#frameStack + 1] = registeredFrame
		end
		--for _, actionBar in ConsolePort:GetActionBars() do
		--	frameStack[#frameStack + 1] = actionBar
		--end
	else
		frameStack = {UIParent:GetChildren()}
	end
	----------------------------------
	local valid, name, forceChild, ignoreChild, isConsolePortFrame
	----------------------------------
	for i, child in pairs(frameStack) do
		--if not child:IsForbidden() then -- assert this frame isn't forbidden , not sure if this will break anything
			----------------------------------
			valid = false
			name = child:GetName()
			forceChild = name and forceFrames[name]
			ignoreChild = ignoreFrames[child] or ignoreFrames[name]
			isConsolePortFrame = name and name:match('ConsolePort')
			----------------------------------
			if 	( Registry[child] and not ignoreChild ) or
				-- if the frame is in the UI registry and not set to be ignored,
				-- valid when multiple frames are shown simultaneously to fade out unfocused frames.
				( isConsolePortFrame and forceChild ) or
				-- if the frame belongs to the ConsolePort suite and should be faded regardless
				( ( forceChild ) or ( not isConsolePortFrame and not ignoreChild ) ) then
				-- if the frame is forced (action bars), or if the frame is not explicitly ignored
				valid = true
			end
			if valid then
				fadeFrames[child] = child.fadeInfo and child.fadeInfo.endAlpha or child:GetAlpha()
			end
		--end
	end
	return fadeFrames
end

function Control:TrackMouseOver(elapsed)
	updateThrottle = updateThrottle + elapsed
	if updateThrottle > 0.5 then
		if self.fadeFrames then
			for frame, origAlpha in pairs(self.fadeFrames) do
				if frame:IsMouseOver() and frame:IsMouseEnabled() then
					FadeIn(frame, 0.2, frame:GetAlpha(), origAlpha)
				elseif frame:GetAlpha() > 0.1 then
					FadeOut(frame, 0.2, frame:GetAlpha(), 0) 
				end
			end
		else
			self:SetScript('OnUpdate', nil)
		end
		updateThrottle = 0
	end
end

function Control:SetIgnoreFadeFrame(frame, toggleIgnore, fadeInOnFinish)
	local frame = type(frame) == 'string' and _G[frame] or frame
	ignoreFrames[frame] = toggleIgnore
	if toggleIgnore then
		if self.fadeFrames then
			self.fadeFrames[frame] = nil
		end
		if fadeInOnFinish then
			FadeIn(frame, 0.2, frame:GetAlpha(), 1)
		end
	end
end

function Control:HideUI(focusFrame, onlyActionBars)
	if focusFrame then
		self:SetIgnoreFadeFrame(focusFrame, true, true)
	end

	local frames = GetFadeFrames(onlyActionBars)
	for frame in pairs(frames) do
		FadeOut(frame, fadeTime or 0.2, frame:GetAlpha(), 0)
	end
	self.fadeFrames = frames

	updateThrottle = 0
	self:SetScript('OnUpdate', self.TrackMouseOver)
end

function Control:ShowUI()
	if self.fadeFrames then
		for frame, origAlpha in pairs(self.fadeFrames) do
			FadeIn(frame, fadeTime or 0.5, frame:GetAlpha(), origAlpha)
		end
		self.fadeFrames = nil
	end
end


----------------------------------
-- Hint control stubs
---------------------------------- 

function Control:SetHintFocus(forceFrame)
end

function Control:IsHintFocus(frame)
end

function Control:ClearHintsForFrame(forceFrame)
end

function Control:RestoreHints()
end

function Control:HideHintBar()
end

function Control:ResetHintBar()
end

function Control:RegisterHintForFrame(frame, key, text, enabled)
end

function Control:UnregisterHintForFrame(frame, key)
end

function Control:AddHint(key, text)
end

function Control:RemoveHint(key)
end

function Control:GetHintForKey(key)
end

function Control:SetHintDisabled(key)
end

function Control:SetHintEnabled(key)
end