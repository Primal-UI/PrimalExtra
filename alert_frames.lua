-- Prevents the GarrisonMissionAlertFrame and GarrisonBuildingAlertFrame from being shown.
-- http://wowprogramming.com/utils/xmlbrowser/test/FrameXML/AlertFrames.lua

local addonName, addon = ...

setfenv(1, addon)

local frame = _G.CreateFrame("Frame")

frame:SetScript("OnEvent", function(self, event, ...)
  return self[event](self, ...)
end)

function frame:ADDON_LOADED(name)
  -- It's not guaranteed that the first ADDON_LOADED event we see is for this addon. It's possible that this file is
  -- loaded and we get here in response to a different addon having finished loading.
  if name ~= addOnName then return end

  self:UnregisterEvent("ADDON_LOADED")

  _G.AlertFrame:UnregisterEvent("GARRISON_BUILDING_ACTIVATABLE") -- GarrisonBuildingAlertFrame
  _G.AlertFrame:UnregisterEvent("GARRISON_MISSION_FINISHED") -- GarrisonMissionAlertFrame
  --_G.AlertFrame:UnregisterEvent("GARRISON_FOLLOWER_ADDED") -- GarrisonFollowerAlertFrame

  --self.ADDON_LOADED = nil
end

frame:RegisterEvent("ADDON_LOADED")

-- vim: tw=120 sts=2 sw=2 et
