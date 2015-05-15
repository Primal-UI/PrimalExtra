-- Hints taken from "Zone Map Class Colors" (curse.com/addons/wow/zone-map-class-colors) and "Enhanced BG Zone Map"
-- (curse.com/addons/wow/enhanced-bg-zone-map).

local addonName, addon = ...

setfenv(1, addon)

-- From http://wowprogramming.com/utils/xmlbrowser/test/FrameXML/WorldMapFrame.lua
local BLIP_TEX_COORDS = {
  ["WARRIOR"] = { 0, 0.125, 0, 0.25 },
  ["PALADIN"] = { 0.125, 0.25, 0, 0.25 },
  ["HUNTER"] = { 0.25, 0.375, 0, 0.25 },
  ["ROGUE"] = { 0.375, 0.5, 0, 0.25 },
  ["PRIEST"] = { 0.5, 0.625, 0, 0.25 },
  ["DEATHKNIGHT"] = { 0.625, 0.75, 0, 0.25 },
  ["SHAMAN"] = { 0.75, 0.875, 0, 0.25 },
  ["MAGE"] = { 0.875, 1, 0, 0.25 },
  ["WARLOCK"] = { 0, 0.125, 0.25, 0.5 },
  ["DRUID"] = { 0.25, 0.375, 0.25, 0.5 },
  ["MONK"] = { 0.125, 0.25, 0.25, 0.5 }
}

local frame = _G.CreateFrame("Frame")

frame:SetScript("OnEvent", function(self, event, ...)
  return self[event](self, ...)
end)

--[[
function frame:ADDON_LOADED(name)
  if name ~= addonName then return end

  -- This appears to cause all sorts of problems where UnregisterEvent("ADDON_LOADED") had no effect in this and other
  -- handlers.
  local loaded = _G.LoadAddOn("Blizzard_BattlefieldMinimap")
  _G.assert(loaded)

  self.ADDON_LOADED = nil
end
]]

function frame:ADDON_LOADED(name)
  local continue = (name == "Blizzard_BattlefieldMinimap") or
                   (name == addonName and _G.IsAddOnLoaded("Blizzard_BattlefieldMinimap"))

  if not continue then return end

  self:UnregisterEvent("ADDON_LOADED")

  --_G.BATTLEFIELD_TAB_SHOW_DELAY = 2147483647 -- (2^31 - 1). It won't fade in for a long time.
  _G.BATTLEFIELD_TAB_SHOW_DELAY = 0
  _G.BATTLEFIELD_TAB_FADE_TIME = 0
  _G.DEFAULT_BATTLEFIELD_TAB_ALPHA = 1
  _G.BATTLEFIELD_MINIMAP_UPDATE_RATE = 0.02

  _G.BattlefieldMinimapBackground:Hide()
  _G.BattlefieldMinimapCorner:Hide()
  _G.BattlefieldMinimapCloseButton:Hide()

  _G.BattlefieldMinimapTabLeft:Hide()
  _G.BattlefieldMinimapTabMiddle:Hide()
  _G.BattlefieldMinimapTabRight:Hide()
  _G.select(5, _G.BattlefieldMinimapTab:GetRegions()):Hide()

  --[[
  local backdrop = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1,
    insets = { -- distance from the edges of the frame to those of the background texture (in pixels)
      left = 0,
      right = 0,
      top = 0,
      bottom = 0,
    },
  }

  _G.BattlefieldMinimap:SetBackdrop(backdrop)
  _G.BattlefieldMinimap:SetBackdropBorderColor(0, 0, 0)
  _G.BattlefieldMinimap:SetBackdropColor(0, 0, 0, 0)
  ]]

  local borderTop = _G.BattlefieldMinimap:CreateTexture()
  borderTop:SetTexture(0, 0, 0)
  borderTop:SetHeight(1)
  borderTop:SetPoint("TOPLEFT", 0, 0)
  borderTop:SetPoint("TOPRIGHT", -6, 0)
  local borderRight = _G.BattlefieldMinimap:CreateTexture()
  borderRight:SetTexture(0, 0, 0)
  borderRight:SetWidth(1)
  borderRight:SetPoint("TOPRIGHT", -6, 0)
  borderRight:SetPoint("BOTTOMRIGHT", -6, 4)
  local borderBottom = _G.BattlefieldMinimap:CreateTexture()
  borderBottom:SetTexture(0, 0, 0)
  borderBottom:SetHeight(1)
  borderBottom:SetPoint("BOTTOMLEFT", 0, 4)
  borderBottom:SetPoint("BOTTOMRIGHT", -6, 4)
  local borderLeft = _G.BattlefieldMinimap:CreateTexture()
  borderLeft:SetTexture(0, 0, 0)
  borderLeft:SetWidth(1)
  borderLeft:SetPoint("TOPLEFT", 0, 0)
  borderLeft:SetPoint("BOTTOMLEFT", 0, 4)

  --_G.BattlefieldMinimap:SetScale(2)

  self:RegisterEvent("GROUP_ROSTER_UPDATE")

  self.ADDON_LOADED = nil
end

function frame:GROUP_ROSTER_UPDATE()
  -- GetNumGroupMembers() is only evaluated once! That's how for loops work in Lua (http://www.lua.org/pil/4.3.4.html).
  for i = 1, _G.GetNumGroupMembers() do
    local blip = _G["BattlefieldMinimapRaid" .. i]
    if blip then
      local _, class = _G.UnitClass(blip.unit)
      if class then
        blip.icon:SetTexture("Interface\\Minimap\\PartyRaidBlips")
        blip.icon:SetTexCoord(_G.unpack(BLIP_TEX_COORDS[class]))
      end
    end
  end
end

frame:RegisterEvent("ADDON_LOADED")

--[[
Links.
  http://wowprogramming.com/utils/xmlbrowser/test/AddOns/Blizzard_BattlefieldMinimap/Blizzard_BattlefieldMinimap.lua
  http://wowprogramming.com/utils/xmlbrowser/test/AddOns/Blizzard_BattlefieldMinimap/Blizzard_BattlefieldMinimap.xml
]]

-- vim: tw=120 sts=2 sw=2 et
