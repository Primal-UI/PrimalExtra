local addonName, addon = ...

addon._G = _G
setfenv(1, addon)

--debug = true
print = function(...)
  if debug then _G.print(...) end
end

local handlerFrame = _G.CreateFrame("Frame")

handlerFrame:SetScript("OnEvent", function(self, event, ...)
  return self[event] and self[event](self, ...)
end)

function handlerFrame:ADDON_LOADED(name)
  if name ~= addonName then return end

  self:UnregisterEvent("ADDON_LOADED")

  ----------------------------------------------------------------------------------------------------------------------
  -- Changes to the WorldMapFrame. -------------------------------------------------------------------------------------

  _G.WorldMapFrame:SetClampRectInsets(0, 0, 0, 0) -- Allow moving the WorldMapFrame all the way down.

  -- Remove the black bars to the sides of the world map.
  _G.BlackoutWorld:SetTexture(0, 0, 0, 0)

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

  ----------------------------------------------------------------------------------------------------------------------
  -- Prevent a new chat tab from being opened when starting a pet battle. Taken from
  -- http://us.battle.net/wow/en/forum/topic/8568959502
  do
    local old = _G.FCFManager_GetNumDedicatedFrames
    function _G.FCFManager_GetNumDedicatedFrames(...)
      return _G.select(1, ...) ~= "PET_BATTLE_COMBAT_LOG" and old(...) or 1
    end
  end
  ----------------------------------------------------------------------------------------------------------------------

  _G.DEFAULT_CHATFRAME_ALPHA = 0.0 -- Don't darken chat frames on mouseover.

  _G.SLASH_NINJA_KITTY_DUEL1 = "/d"
  function _G.SlashCmdList.NINJA_KITTY_DUEL(msg, editbox)
    _G.StartDuel("target")
  end

  _G.SLASH_NINJA_KITTY_RELOAD1 = "/rl"
  function _G.SlashCmdList.NINJA_KITTY_RELOAD(msg, editbox)
    _G.ReloadUI()
  end

  ----------------------------------------------------------------------------------------------------------------------
  -- Redirect error messages -------------------------------------------------------------------------------------------
  do
    _G.UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")

    local frame = _G.CreateFrame("Frame")
    frame:SetScript("OnEvent", function(self, event, ...)
      return self[event](self, ...)
    end)

    function frame:UI_ERROR_MESSAGE(message)
      _G.ChatFrame3:AddMessage(message, 1.0, 0.1, 0.1)
    end

    frame:RegisterEvent("UI_ERROR_MESSAGE")
  end
  ----------------------------------------------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------------------------------------------
  -- Minimap auto-zoom -------------------------------------------------------------------------------------------------
  do
    _G.assert(_G.Minimap)
    local zoomLevel = 3 -- 0 is the widest possible zoom, Minimap:GetZoomLevels() - 1 the narrowest.
    local Minimap = _G.Minimap
    local f = _G.CreateFrame("frame", "minimapZoomerFrame")

    -- The macro conditional 'indoors' doesn't always mean we are using the indoors zoom level and vice versa.
    -- Based on the function 'MinimapRange:GetIndoors()' from the MinimapRange addon.
    local function IsIndoors()
      local currentZoom  = _G.Minimap:GetZoom()
      local indoorsZoom  = _G.tonumber(_G.GetCVar("minimapInsideZoom")) 
      local outdoorsZoom = _G.tonumber(_G.GetCVar("minimapZoom"))

      -- If the zoom levels for indoors and outdoors differ, we already detected whether we are inside or outside.
      if indoorsZoom ~= outdoorsZoom then
	return indoorsZoom == currentZoom
      else
	-- Set the zoom to something different to see what CVar changes. Zoom levels range from 0 to 5, where 0 means
	-- completely zoomed out.
	if currentZoom == 0 then
	  _G.MinimapZoomIn:Click()
	  isIndoors = _G.tonumber(_G.GetCVar("minimapInsideZoom")) ~= indoorsZoom
	  _G.MinimapZoomOut:Click()
	else
	  _G.MinimapZoomOut:Click()
	  isIndoors = _G.tonumber(_G.GetCVar("minimapInsideZoom")) ~= indoorsZoom
	  _G.MinimapZoomIn:Click()
	end
	return isIndoors
      end
    end

    local total
    local function onUpdate(self, elapsed)
      total = total + elapsed
      if total >= 1 then
	--if _G.SecureCmdOptionParse("[outdoors]outdoors;indoors") == "outdoors" then
	if not IsIndoors() then
	  if Minimap:GetZoom() ~= zoomLevel then
	    -- Do it like SexyMap b/c it gets confused otherwise; e.g. doesn't let you zoom out when it thinks it's
	    -- already zoomed out completely. Otherwise we would do Minimap:SetZoom(zoomLevel)
	    for i = 1, 5 do
	      _G.MinimapZoomOut:Click()
	    end
	    for i = 1, zoomLevel do
	      _G.MinimapZoomIn:Click()
	    end
	  end
	else -- We are indoors; zoom out completely.
	  if Minimap:GetZoom() ~= 0 then
	    for i = 1, 5 do
	      _G.MinimapZoomOut:Click()
	    end
	  end
	end
	f:SetScript("OnUpdate", nil)
      end
    end

    -- Fires when the minimap zoom type changes. The client stores separate zoom level settings for both indoor and
    -- outdoor areas; this event fires so that the minimap's zoom level can be changed when the player moves between
    -- such areas. It does not fire when directly setting the minimap's zoom level
    -- (http://wowprogramming.com/docs/events/MINIMAP_UPDATE_ZOOM).
    function f:MINIMAP_UPDATE_ZOOM()
      total = 1
      f:SetScript("OnUpdate", onUpdate)
    end

    function f:PLAYER_ENTERING_WORLD()
      total = 1
      f:SetScript("OnUpdate", onUpdate)
    end

    --[[
    Minimap:HookScript("OnEnter", function(self, motion)
      f:SetScript("OnUpdate", nil)
    end)

    Minimap:HookScript("OnLeave", function(self, motion)
      total = 0
      f:SetScript("OnUpdate", onUpdate)
    end)
    --]]

    f:SetScript("OnEvent", function(self, event, ...)
      return self[event] and self[event](self, ...)
    end)

    f:RegisterEvent("MINIMAP_UPDATE_ZOOM")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
  end
  ----------------------------------------------------------------------------------------------------------------------

  handlerFrame:RegisterEvent("PLAYER_LOGIN")
  handlerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

  --BuffTimer1:SetPoint("TOP", UIParent, "TOP", 0, -128)
  --BuffTimer1:SetScript("OnShow",BuffTimer1.Hide)

  -- I was experimenting with these bindings with the left and right mouse buttons bound to arrow keys and side buttons
  -- (notmally BUTTON4 and BUTTON5 to WoW) being used as left and right mouse buttons. It sucked.
  --SetBinding("LEFT", "STRAFELEFT")
  --SetBinding("RIGHT", "STRAFERIGHT")
  --SetBinding("BUTTON2", "INTERACTMOUSEOVER") -- Could also use TURNORACTION or INTERACTTARGET.

  -- Can't do this.
  --local frame = CreateFrame("BUTTON", "NutsSecureClickHandler", UIParent, "SecureHandlerClickTemplate");
  --frame:SetAttribute("_onclick", [=[RunBinding("SIT");RunMacroText([[/run print("Hello, world!")]])]=])
  --frame:SetAttribute("_onclick", [=[RunBinding("SCREENSHOT")]=])
  --frame:RegisterForClicks("AnyDown")
  --SetBindingClick("`", "NutsSecureClickHandler")

  self.ADDON_LOADED = nil
end

function handlerFrame:PLAYER_LOGIN()
  --[[
  -- Get rid of some messages about raid members choosing a role. Those don't seem to have any message group and thus
  -- can't be filtered normally.

  -- "%s is now %s." (ROLE_CHANGED_INFORM) and "%s is now %s. (Changed by %s.)"
  -- (ROLE_CHANGED_INFORM_WITH_SOURCE) type messages.
  -- See http://wowprogramming.com/utils/xmlbrowser/live/FrameXML/RolePoll.lua and
  -- http://wowprogramming.com/utils/xmlbrowser/test/FrameXML/GlobalStrings.lua
  _G.assert(_G.RoleChangedFrame)
  _G.RoleChangedFrame:UnregisterEvent("ROLE_CHANGED_INFORM")

  -- "%s has chosen: %s" type messages (LFG_ROLE_CHECK_ROLE_CHOSEN).
  -- http://wowprogramming.com/utils/xmlbrowser/live/FrameXML/LFGFrame.lua
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
  _G.assert(_G.ChatFrame6Tab)
  _G.ChatFrame6Tab:Click()
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

  --[[
  _G.C_Timer.After(1, function()
    _G.CONTAINER_OFFSET_Y = 25
  end)
  ]]

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
	  _G.BattlefieldMinimap_LoadUI();
	end
	_G.SetCVar("showBattlefieldMinimap", "1");
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

-- For use in macros.
function _G.NKPrint(message)
  -- This is how to send messages to MikSBT. See LibSink-2.0.
  _G.MikSBT.DisplayMessage(message, _G.MikSBT.DISPLAYTYPE_NOTIFICATION, false, 255, 255, 255, nil, "Ubuntu Medium", 2)
end

handlerFrame:RegisterEvent("ADDON_LOADED")

-- vim: tw=120 sts=2 sw=2 et
