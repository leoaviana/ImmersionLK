local _, L = ...
local frame = _G[ _ .. 'Frame' ]
----------------------------------
-- Animations to play on show
----------------------------------
local __inAnims = {
	frame.TalkBox.MainFrame.InAnim,
	frame.TalkBox.NameFrame.FadeIn,
--	frame.TalkBox.TextFrame.FadeIn,
	frame.TalkBox.PortraitFrame.FadeIn,
}

local function PlayInAnimations(self, playAnimations)
	if playAnimations and ( self.timeStamp ~= GetTime() ) then
		for _, animation in ipairs(__inAnims) do
			animation:Play()
		end
	end
end

----------------------------------
-- Fade manager
----------------------------------
local __cacheAlphaIgnored = {}
local __staticAlphaIgnored = {
	[AlertFrame]		= true,
	[DressUpFrame]		= true,
--	[LevelUpDisplay] 	= true,
	[StaticPopup1] 		= true,
	[StaticPopup2] 		= true,
	[StaticPopup3] 		= true,
	[StaticPopup4] 		= true,
	[SubZoneTextFrame] 	= true,
	[ShoppingTooltip1] 	= true,
	[ShoppingTooltip2] 	= true,
}
local __staticHideFrames = {
	[MinimapCluster] = true, 
}

if LevelUpDisplay then
	__staticAlphaIgnored[LevelUpDisplay] = true
end

----------------------------------
local FadeIn, FadeOut = L.UIFrameFadeIn, L.UIFrameFadeOut
----------------------------------

----------------------------------

local function SetIgnoreParentAlpha(frame, ignore)
	if(ignore == true) then
		frame.pData = { ["Parent"] = frame:GetParent(), ["Level"] = frame:GetFrameLevel(), ["Strata"] = frame:GetFrameStrata() }
		frame:SetParent(nil);
		frame:SetFrameLevel(frame.pData["Level"])
		frame:SetFrameStrata(frame.pData["Strata"])
	else
		if(frame.pData) then
			frame:SetParent(frame.pData["Parent"]);
			frame:SetFrameLevel(frame.pData["Level"])
			frame:SetFrameStrata(frame.pData["Strata"])
			frame.pData = nil
		end
	end
end

----------------------------------

-- For config to cache certain frames for fade ignore/force.
function L.ToggleIgnoreFrame(frame, ignore)
	if frame then
		__cacheAlphaIgnored[frame] = ignore
		--frame:SetIgnoreParentAlpha(ignore) no wotlk equivalent
		SetIgnoreParentAlpha(frame, ignore)
	end
end

-- Return a list of all frames to ignore and their current
-- setting towards ignoring UIParent's alpha value.
local function GetFramesToIgnore()
	local frames = {}
	-- Store ignore state so it can be reset on release.
	for frame in pairs(__staticAlphaIgnored) do
		--frames[frame] = frame:IsIgnoringParentAlpha()
		frames[frame] = frame.oldp ~= nil
	end
	-- Union with cache.
	for frame, shouldIgnore in pairs(__cacheAlphaIgnored) do
		if shouldIgnore then
			--frames[frame] = frame:IsIgnoringParentAlpha()
			frames[frame] = frame.oldp ~= nil
		end
	end
	return frames
end

-- Restore the temporary changes on release.
local function RestoreFadedFrames(self)
	FadeIn(UIParent, 0.5, UIParent:GetAlpha(), 1)

	local framesToIgnore = self.ignoredFadeFrames
	if framesToIgnore then
		for frame, ignoreParentAlpha in pairs(framesToIgnore) do
			--frame:SetIgnoreParentAlpha(ignoreParentAlpha)
			SetIgnoreParentAlpha(frame, ignoreParentAlpha)
		end
		for frame in pairs(__staticHideFrames) do
			if not __cacheAlphaIgnored[frame] then
				FadeIn(frame, 0.5, frame:GetAlpha(), 1)
				frame:Show()
			end
		end
		self.ignoredFadeFrames = nil
	end
end

----------------------------------
-- Exposed to logic layer
----------------------------------
local function SafeOnFadeOut(frame)
	--if not frame:IsProtected() then
	if not InCombatLockdown() then
		frame:Hide()
	end
end

function frame:FadeIn(fadeTime, playAnimations, ignoreFrameFade)
	fadeTime = fadeTime or 0.2

	self.fadeState = 'in'
	FadeIn(self, fadeTime, self:GetAlpha(), 1)
	--PlayInAnimations(self, playAnimations)

	if not ignoreFrameFade and L('hideui') and not self.ignoredFadeFrames then
		local framesToIgnore = GetFramesToIgnore()

		-- Fade out UIParent
		FadeOut(UIParent, fadeTime, UIParent:GetAlpha(), 0)

		-- Hide frames explicitly 
		for frame in pairs(__staticHideFrames) do
			if not __cacheAlphaIgnored[frame] then
				FadeOut(frame, fadeTime, frame:GetAlpha(), 0, {
					finishedFunc = SafeOnFadeOut;
					finishedArg1 = frame;
				})
			end
		end

		-- Set ignored frames to override the alpha change
		for frame in pairs(framesToIgnore) do
			--frame:SetIgnoreParentAlpha(true)
			SetIgnoreParentAlpha(frame, true)
		end

		self.ignoredFadeFrames = framesToIgnore
	end
end

function frame:TryHide()
	if(not InCombatLockdown()) then
		self:Hide()
	end
end

function frame:FadeOut(fadeTime, ignoreOnTheFly)
	--I am not sure why, but when in combat this will bug.
	--[==[
	if ( self.fadeState ~= 'out' ) then
		FadeOut(self, fadeTime or 1, self:GetAlpha(), 0, {
			finishedFunc = self.TryHide;
			finishedArg1 = self;
		})
		self.fadeState = 'out'
	end
	--]==]

	RestoreFadedFrames(self)
end

----------------------------------
-- Handle GameTooltip special case
----------------------------------
-- If the option to hide UI and to hide tooltip are ticked,
-- user still needs to see the tooltip on an item or reward.
do 	local function GameTooltipAlphaHandler(self)
		if L('hideui') then
			if L('hidetooltip') then
				--self:SetIgnoreParentAlpha(not self:IsOwned(UIParent))

				SetIgnoreParentAlpha(self, not self:IsOwned(UIParent))
			else
				--self:SetIgnoreParentAlpha(true)
				
				SetIgnoreParentAlpha(self, true)
			end
		end
	end

	GameTooltip:HookScript('OnTooltipSetDefaultAnchor', GameTooltipAlphaHandler)
	GameTooltip:HookScript('OnShow', GameTooltipAlphaHandler)

	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(self)
			if self ~= GameTooltip then return end;
			GameTooltipAlphaHandler(self)
		end)
	else
		GameTooltip:HookScript('OnTooltipSetItem', GameTooltipAlphaHandler)
	end
end