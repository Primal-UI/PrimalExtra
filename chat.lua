-- TODO: Move messages displayed by ChatFrame_DisplaySystemMessageInPrimary() to the sink.

local addonName, addon = ...

setfenv(1, addon)

_G.DEFAULT_CHATFRAME_ALPHA = 0.0 -- Don't darken chat frames on mouseover.

local trade = chatFrames.trade
local chat  = chatFrames.chat
local sink  = chatFrames.sink

--[[
_G.ChatFrame_DisplaySystemMessageInPrimary = function(messageTag)
  local info = _G.ChatTypeInfo["SYSTEM"]
  _G[trade]:AddMessage(messageTag, info.r, info.g, info.b, info.id)
end
]]

onPlayerLogin[#onPlayerLogin + 1] = function()
  --[[
  -- Get rid of some messages about raid members choosing a role. Those don't seem to have any message group and thus
  -- can't be filtered normally.

  -- "%s is now %s." (ROLE_CHANGED_INFORM) and "%s is now %s. (Changed by %s.)"
  -- (ROLE_CHANGED_INFORM_WITH_SOURCE) type messages.
  -- See http://wowprogramming.com/utils/xmlbrowser/test/FrameXML/RolePoll.lua and
  -- http://wowprogramming.com/utils/xmlbrowser/test/FrameXML/GlobalStrings.lua
  _G.assert(_G.RoleChangedFrame)
  _G.RoleChangedFrame:UnregisterEvent("ROLE_CHANGED_INFORM")

  -- "%s has chosen: %s" type messages (LFG_ROLE_CHECK_ROLE_CHOSEN).
  -- http://wowprogramming.com/utils/xmlbrowser/test/FrameXML/LFGFrame.lua
  _G.assert(_G.LFGEventFrame)
  _G.RoleChangedFrame:UnregisterEvent("LFG_ROLE_CHECK_ROLE_CHOSEN")
  --]]

  --[[
  _G.ChatFrame_AddMessageEventFilter("CHAT_MSG_ADDON", function(self, event, message)
    print(event .. ": " .. message)
    return false
  end)
  --]]

  -- Switch away from ChatFrame1 since it gets spammed by addons and messages that Blizzard failed to assign a chat
  -- group to.
  _G.assert(_G[chatFrames.chat .. "Tab"])
  _G[chatFrames.chat .. "Tab"]:Click()
end

-- Disable drag-to-undock behaviour for all chat frame tabs (similar to ChatTabDockLock and PhanxChat) and disable
-- closing chat frames by clicking their tabs.
------------------------------------------------------------------------------------------------------------------------
local originalOnDragStart = {}

local function lockTab(chatFrame)
  _G.assert(chatFrame)
  _G.assert(chatFrame.GetName)
  _G.assert(chatFrame:GetName())

  if chatFrame == _G.DEFAULT_CHAT_FRAME then return end

  local tab = _G[chatFrame:GetName() .. "Tab"]

  _G.assert(tab)

  -- Disable drag-to-undock behaviour.
  if not originalOnDragStart[tab] then
    originalOnDragStart[tab] = tab:GetScript("OnDragStart")
    tab:SetScript("OnDragStart", function(self)
      if not chatFrame.isDocked then
        originalOnDragStart[self](self)
      end
    end)
  end
end

for i = 1, _G.NUM_CHAT_WINDOWS do
  local chatFrame = _G["ChatFrame" .. i]
  local tab = _G["ChatFrame" .. i .. "Tab"]

  -- Don't close chat frames when clicking their tab with the mouse wheel. Doing stuff when clicking instead of
  -- releasing also seems nice. Chat frame tabs are registered for "LeftButtonUp", "RightButtonUp" and "MiddleButtonUp".
  -- See the ChatTabTemplate definition at wowprogramming.com/utils/xmlbrowser/test/FrameXML/FloatingChatFrame.xml and
  -- FCF_Tab_OnClick() at wowprogramming.com/utils/xmlbrowser/test/FrameXML/FloatingChatFrame.lua.
  tab:RegisterForClicks("LeftButtonDown", "RightButtonDown")

  lockTab(chatFrame)
end

_G.hooksecurefunc("FCF_DockFrame", lockTab)
-- curse.com/addons/wow/chattabdocklock
-- github.com/Phanx/PhanxChat/blob/master/Modules/LockTabs.lua
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
-- Prevent a new chat tab from being opened when starting a pet battle. Taken from
-- us.battle.net/wow/en/forum/topic/8568959502
do
  local old = _G.FCFManager_GetNumDedicatedFrames
  function _G.FCFManager_GetNumDedicatedFrames(...)
    return _G.select(1, ...) ~= "PET_BATTLE_COMBAT_LOG" and old(...) or 1
  end
end
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
-- Redirect error messages ---------------------------------------------------------------------------------------------
do
  _G.UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")

  local frame = _G.CreateFrame("Frame")
  frame:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, ...)
  end)

  function frame:UI_ERROR_MESSAGE(message)
    _G[sink]:AddMessage(message, 1.0, 0.1, 0.1)
  end

  frame:RegisterEvent("UI_ERROR_MESSAGE")
end
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
-- Fade out chat frames (this used to be a WeakAura) -------------------------------------------------------------------
if _G.IsAddOnLoaded("Chatter") then
  local defaultSettings = {
    fade = true,
    timeVisible = 20,
  }
  local settings = _G.setmetatable({
    [sink] = {
      fade = true,
      timeVisible = 10,
    },
    [trade] = {
      fade = false,
    },
  }, {
    __index = function()
      return defaultSettings
    end
  })

  local timers, backgroundFrames = {}, {}

  local alpha = 1.0

  _G.hooksecurefunc("FCF_FadeInChatFrame", function(chatFrame)
    if chatFrame.isTemporary then return end
    if not settings[chatFrame:GetName()].fade then return end
    local background = backgroundFrames[chatFrame:GetName()]
    _G.UIFrameFadeIn(background, _G.CHAT_FRAME_FADE_TIME, background:GetAlpha(), alpha)
  end)

  _G.hooksecurefunc("FCF_FadeOutChatFrame", function(chatFrame)
    if chatFrame.isTemporary then return end
    if not settings[chatFrame:GetName()].fade then return end
    if timers[chatFrame:GetName()] <= 0 then
      if chatFrame.isLocked and (not chatFrame.isDocked or _G.GENERAL_CHAT_DOCK.primary.isLocked) then
        local background = backgroundFrames[chatFrame:GetName()]
        _G.UIFrameFadeOut(background, _G.CHAT_FRAME_FADE_OUT_TIME, background:GetAlpha(), .0)
      end
    end
  end)

  for i = 1, _G.NUM_CHAT_WINDOWS do
    local chatFrame = _G["ChatFrame" .. i]
    local settings = settings["ChatFrame" .. i]
    --local settings = settings["ChatFrame" .. i] or defaultSettings
    if settings.fade then

      local background = nil
      for _, frame in _G.ipairs({chatFrame:GetChildren()}) do
        if frame.id and frame.id == "FRAME_" ..  i then
          background = frame
          break
        end
      end
      _G.assert(background)

      if settings.timeVisible then
        chatFrame:SetTimeVisible(settings.timeVisible) -- This is to late to fade the guild MOTD faster.
      end
      chatFrame:SetFadeDuration(.5)

      backgroundFrames["ChatFrame" .. i] = background
      timers["ChatFrame" .. i] = 0 -- Should be faded.

      alpha = background:GetAlpha()

      -- We will miss the guild message of the day.
      _G.hooksecurefunc(chatFrame, "AddMessage", function(self)
        _G.UIFrameFadeIn(background, _G.CHAT_FRAME_FADE_TIME, background:GetAlpha(), alpha)
        timers[chatFrame:GetName()] = chatFrame:GetTimeVisible()
      end)

      local function showChatFrame(chatFrame)
        if chatFrame:GetNumMessages() == 0 then return end
        if not chatFrame.hasBeenFaded then -- The mouse is not over the chat frame.
          _G.UIFrameFadeIn(background, _G.CHAT_FRAME_FADE_TIME, background:GetAlpha(), alpha)
        end
        timers[chatFrame:GetName()] = chatFrame:GetTimeVisible()
      end

      _G.hooksecurefunc(chatFrame, "PageDown", showChatFrame)
      _G.hooksecurefunc(chatFrame, "PageUp", showChatFrame)
      _G.hooksecurefunc(chatFrame, "ScrollDown", showChatFrame)
      _G.hooksecurefunc(chatFrame, "ScrollToBottom", showChatFrame)
      _G.hooksecurefunc(chatFrame, "ScrollToTop", showChatFrame)
      _G.hooksecurefunc(chatFrame, "ScrollUp", showChatFrame)

      background:SetAlpha(0.0)
    end
    chatFrame:SetFading(settings.fade)
  end

  local f = _G.CreateFrame("Frame")
  local function onUpdate(self, elapsed)
    for i = 1, _G.NUM_CHAT_WINDOWS do
      if settings["ChatFrame" .. i].fade then
        local chatFrame = _G["ChatFrame" .. i]
        local background = backgroundFrames["ChatFrame" .. i]
        _G.assert(chatFrame and background)
        if chatFrame and background and chatFrame:IsVisible() and chatFrame:AtBottom() then
          if timers["ChatFrame" .. i] > 0 then
            timers["ChatFrame" .. i] = timers["ChatFrame" .. i] - elapsed
          end
          -- chatFrame.hasBeenFaded is true when the mouse is over the chat frame.
          local fadeOut = timers["ChatFrame" .. i] <= 0 and not chatFrame.hasBeenFaded and chatFrame.isLocked and
            (not chatFrame.isDocked or _G.GENERAL_CHAT_DOCK.primary.isLocked)
          if fadeOut then
            _G.UIFrameFadeOut(background, _G.CHAT_FRAME_FADE_OUT_TIME, background:GetAlpha(), 0.0)
          end
        end
      end
    end
  end
  f:SetScript("OnUpdate", onUpdate)

  _G.C_Timer.After(.001, function()
    _G[sink]:ScrollDown()
    _G[chat]:ScrollDown()
  end)
end
------------------------------------------------------------------------------------------------------------------------

-- vim: tw=120 sts=2 sw=2 et
