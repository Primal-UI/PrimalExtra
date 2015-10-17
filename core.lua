local addonName, addon = ...

addon._G = _G
setfenv(1, addon)

print = function(...)
  _G.print("|cffff7d0a" .. addonName .. "|r:", ...)
end

------------------------------------------------------------------------------------------------------------------------
chatFrames = _G.PrimalCore.chatFrames
------------------------------------------------------------------------------------------------------------------------

onAddonLoaded = {}
onPlayerLogin = {}

local handlerFrame = _G.CreateFrame("Frame")

handlerFrame:SetScript("OnEvent", function(self, event, ...)
  --return self[event](self, ...)
  return self[event] and self[event](self, ...)
end)

function handlerFrame:ADDON_LOADED(name)
  if name ~= addonName then return end

  self:UnregisterEvent("ADDON_LOADED")

  ----------------------------------------------------------------------------------------------------------------------
  -- Changes to the WorldMapFrame. -------------------------------------------------------------------------------------
  _G.WorldMapFrame:SetClampRectInsets(0, 0, 0, 0) -- Allow moving the WorldMapFrame all the way down.

  _G.BlackoutWorld:SetTexture(0, 0, 0, 0) -- Remove the black bars to the sides of the world map.

  local function polishFullscreenMap()
    _G.SetUIPanelAttribute(_G.WorldMapFrame, "area", "center");
    _G.SetUIPanelAttribute(_G.WorldMapFrame, "allowOtherPanels", true)
    _G.WorldMapFrame:ClearAllPoints()
    _G.WorldMapFrame:SetPoint("TOP")
    _G.WorldMapFrame:SetPoint("BOTTOM")
    _G.WorldMapFrame:SetSize(_G.WorldMapFrame.BorderFrame:GetSize())
    _G.WorldMapFrame:EnableKeyboard(false)
    --_G.WorldMapTitleButton:Show()
    --_G.WorldMapFrame:SetMovable(true)
    _G.WorldMapFrame:SetMovable(false)
  end

  _G.hooksecurefunc("WorldMap_ToggleSizeUp", polishFullscreenMap)

  -- Both of this returns garbage at this point: _G.GetCVarBool("miniWorldMap"), _G.WorldMapFrame_InWindowedMode()...
  --if _G.GetCVarBool("miniWorldMap") == false then
    polishFullscreenMap()
    _G.WorldMapFrame.MainHelpButton:Hide() -- Blizzard fails to do this until WorldMap_ToggleSizeUp() is called.
    _G.WorldMapTitleButton:Hide()
    --_G.WorldMapFrame:SetMovable(true)
  --end

  -- http://wowprogramming.com/utils/xmlbrowser/test/FrameXML/WorldMapFrame.xml
  -- http://wowprogramming.com/utils/xmlbrowser/test/FrameXML/WorldMapFrame.lua
  ----------------------------------------------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------------------------------------------
  -- Fades the CompactRaidFrameManager when it doesn't have mouse focus. Some clues were taken from DejaPRFader.
  _G.assert(not _G.CompactRaidFrameManager:GetScript("OnEnter"))
  do
    _G.CompactRaidFrameManager:SetScript("OnEnter", function(self, motion)
      self:SetAlpha(1)
      self:SetScript("OnUpdate", nil)
    end)
    _G.CompactRaidFrameManagerToggleButton:SetScript("OnEnter", function(self, motion)
      _G.CompactRaidFrameManager:SetAlpha(1)
      _G.CompactRaidFrameManager:SetScript("OnUpdate", nil)
    end)
    _G.CompactRaidFrameManager:SetScript("OnLeave", function(self, motion)
      self:SetScript("OnUpdate", function(self)
        if self.collapsed and not self:IsMouseOver() then
          self:SetAlpha(0)
          self:SetScript("OnUpdate", nil)
        end
      end)
    end)
    _G.CompactRaidFrameContainer:HookScript("OnEvent", function(self)
      if not _G.InCombatLockdown() then
        self:SetParent(_G.UIParent) -- This is protected.
      end
    end)
    _G.hooksecurefunc("CompactRaidFrameManager_Expand", function(self)
      self:SetAlpha(1)
    end)
    _G.hooksecurefunc("CompactRaidFrameManager_Collapse", function(self)
      if not self:IsMouseOver() then
        self:SetAlpha(0)
        self:SetScript("OnUpdate", nil)
      end
    end)
    _G.CompactRaidFrameManager:SetAlpha(0)
    if self.collapsed and not self:IsMouseOver() then
      self:SetAlpha(0)
      self:SetScript("OnUpdate", nil)
    end
  end
  ----------------------------------------------------------------------------------------------------------------------

  _G.SLASH_PRIMAL_EXTRA_DUEL1 = "/d"
  function _G.SlashCmdList.PRIMAL_EXTRA_DUEL(msg, editbox)
    _G.StartDuel("target")
  end

  _G.SLASH_PRIMAL_EXTRA_RELOAD1 = "/rl"
  function _G.SlashCmdList.PRIMAL_EXTRA_RELOAD(msg, editbox)
    _G.ReloadUI()
  end

  _G.SLASH_PRIMAL_EXTRA_LOGOUT1 = "/log"
  function _G.SlashCmdList.PRIMAL_EXTRA_LOGOUT(msg, editbox)
    _G.Logout()
  end

  -- http://wowprogramming.com/utils/xmlbrowser/test/FrameXML/ChatFrame.lua
  _G.SLASH_PRIMAL_EXTRA_CALENDAR1 = "/cal"
  _G.SlashCmdList.PRIMAL_EXTRA_CALENDAR = _G.SlashCmdList.CALENDAR

  handlerFrame:RegisterEvent("PLAYER_LOGIN")
  handlerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

  --BuffTimer1:SetPoint("TOP", UIParent, "TOP", 0, -128)
  --BuffTimer1:SetScript("OnShow",BuffTimer1.Hide)

  -- I was experimenting with these bindings with the left and right mouse buttons bound to arrow keys and side buttons
  -- (notmally BUTTON4 and BUTTON5 to WoW) being used as left and right mouse buttons.  It sucked.
  --SetBinding("LEFT", "STRAFELEFT")
  --SetBinding("RIGHT", "STRAFERIGHT")
  --SetBinding("BUTTON2", "INTERACTMOUSEOVER") -- Could also use TURNORACTION or INTERACTTARGET.

  -- Can't do this.
  --local frame = CreateFrame("BUTTON", "NutsSecureClickHandler", UIParent, "SecureHandlerClickTemplate");
  --frame:SetAttribute("_onclick", [=[RunBinding("SIT");RunMacroText([[/run print("Hello, world!")]])]=])
  --frame:SetAttribute("_onclick", [=[RunBinding("SCREENSHOT")]=])
  --frame:RegisterForClicks("AnyDown")
  --SetBindingClick("`", "NutsSecureClickHandler")

  for i = 1, #onAddonLoaded do
    onAddonLoaded[i]()
  end

  self.ADDON_LOADED = nil
end

function handlerFrame:PLAYER_LOGIN()
  for i = 1, #onPlayerLogin do
    onPlayerLogin[i]()
  end
end

local function ToggleWorldStateAlwaysUpFrame()
  _G.assert(_G.WorldStateAlwaysUpFrame and _G.GhostFrame)
  local wSFrame = _G.WorldStateAlwaysUpFrame

  instanceType = (_G.select(2, _G.GetInstanceInfo()))
  if (instanceType == "arena") and wSFrame:IsShown() then
    wSFrame:Hide()
  elseif instanceType ~= "arena" then
    if not wSFrame:IsShown() then wSFrame:Show() end
    if not wSFrame:IsMovable() then
      wSFrame:SetMovable(true)
      wSFrame:ClearAllPoints()
      wSFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 128, 256)
      wSFrame:SetUserPlaced(true)

      _G.GhostFrame:SetMovable(true)
      _G.GhostFrame:ClearAllPoints()
      _G.GhostFrame:SetPoint("TOP", UIParent, 0, -64)
    end
  end
end

function handlerFrame:PLAYER_ENTERING_WORLD()
  ToggleWorldStateAlwaysUpFrame()

  ----------------------------------------------------------------------------------------------------------------------
  -- Changes to the Bags. ----------------------------------------------------------------------------------------------

  --_G.CONTAINER_OFFSET_Y = 25
  _G.UIPARENT_MANAGED_FRAME_POSITIONS.CONTAINER_OFFSET_Y = { baseY = 25, yOffset = 0, bottomEither = actionBarOffset,
    isVar = "yAxis" }

  -- wowprogramming.com/utils/xmlbrowser/test/FrameXML/UIParent.lua
  -- wowprogramming.com/utils/xmlbrowser/test/FrameXML/ContainerFrame.lua

  ----------------------------------------------------------------------------------------------------------------------

  --[[ TODO!
  do
    local wSFrame = _G.WorldStateAlwaysUpFrame
    wSFrame:SetScript("OnEnter", function(self, motion)
      self:SetAlpha(1)
    end)
    wSFrame:SetScript("OnLeave", function(self, motion)
      self:SetAlpha(0)
    end)
    local childFrames = {wSFrame:GetChildren()}
    for _, frame in _G.ipairs(childFrames) do
      frame:SetScript("OnEnter", function(self, motion)
        wSFrame:SetAlpha(1)
      end)
      frame:SetScript("OnLeave", function(self, motion)
        wSFrame:SetAlpha(0)
      end)
    end
  end
  ]]

  ----------------------------------------------------------------------------------------------------------------------
  -- Enable the BattlefieldMinimap if this is a battleground -----------------------------------------------------------
  do
    local _, instanceType = _G.IsInInstance();
    if instanceType == "pvp" then
      -- This is a battleground and the BattlefieldMinimap should never be shown. Show it anyway.
      if _G.GetCVar("showBattlefieldMinimap") == "0" then
	-- http://wowprogramming.com/utils/xmlbrowser/test/FrameXML/WorldMapFrame.lua
	if not _G.BattlefieldMinimap then
	  _G.BattlefieldMinimap_LoadUI()
	end
	_G.SetCVar("showBattlefieldMinimap", "1")
	_G.BattlefieldMinimap:Show()
	_G.WorldMapZoneMinimapDropDown_Update()
      end
    -- The BattlefieldMinimap should be shown in battlegrounds only and this isn't one.
    elseif _G.GetCVar("showBattlefieldMinimap") == "1" and instanceType ~= "pvp" then
      if _G.BattlefieldMinimap and _G.BattlefieldMinimap:IsShown() then
	_G.BattlefieldMinimap:Hide()
	--_G.WorldMapZoneMinimapDropDown_Update() -- Was this function removed? Why did we call it?
      end
    end
  end
  -- See AddOns/Blizzard_BattlefieldMinimap/Blizzard_BattlefieldMinimap.lua
  ----------------------------------------------------------------------------------------------------------------------

  -- TODO: comment or remove this.
  ----------------------------------------------------------------------------------------------------------------------
  local chatTypeGroups = {"SYSTEM", "BN_INLINE_TOAST_ALERT"}
  for _, chatTypeGroup in _G.ipairs(chatTypeGroups) do
    for _, event in _G.ipairs(_G.ChatTypeGroup[chatTypeGroup] or {}) do
      if event then
	_G.ChatFrame1:UnregisterEvent(event)
      end
    end
    for index, value in _G.pairs(_G.ChatFrame1.messageTypeList) do
      if _G.strupper(value) == _G.strupper(chatTypeGroup) then
	print("Removing message group '" .. value .. "' from ChatFrame1: " ..
	      "'ChatFrame1.messageTypeList[" .. index .. "] = nil'")
	_G.ChatFrame1.messageTypeList[index] = nil
      end
    -- http://wowprogramming.com/docs/api/RemoveChatWindowMessages
    _G.RemoveChatWindowMessages(_G.ChatFrame1:GetID(), chatTypeGroup)
    end
  end
  ----------------------------------------------------------------------------------------------------------------------
end

function _G.NKPrint(message) -- For use in macros.
  -- This is how to send messages to MikSBT.  See LibSink-2.0.
  _G.MikSBT.DisplayMessage(message, _G.MikSBT.DISPLAYTYPE_NOTIFICATION, false, 255, 255, 255, nil, "Ubuntu Medium", 2)
end

handlerFrame:RegisterEvent("ADDON_LOADED")

-- vim: tw=120 sts=2 sw=2 et
