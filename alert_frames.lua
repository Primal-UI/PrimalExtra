-- Prevents the GarrisonMissionAlertFrame and GarrisonBuildingAlertFrame from being shown.
-- http://wowprogramming.com/utils/xmlbrowser/test/FrameXML/AlertFrames.lua

local addonName, addon = ...

setfenv(1, addon)

------------------------------------------------------------------------------------------------------------------------
-- Prevent all MONEY_WON_ALERT_FRAMES from ever showing up.  Instead, add a chat message in the style of the normal
-- money loot messages.  This should also prevent the creation of a lot of frames as only MoneyWonAlertFrame1 is always
-- created and this function will create an extra unnamed frame when there is no unused frame in MONEY_WON_ALERT_FRAMES.
_G.MoneyWonAlertFrame_ShowAlert = function(amount)
  local gold   = _G.math.floor(amount / 10000)
  local silver = _G.math.floor((amount - 10000 * gold) / 100)
  local copper = amount % 100

  local goldString = gold > 0 and _G.string.format(_G.GOLD_AMOUNT, gold) .. (silver + copper > 0 and ", " or "") or ""
  local silverString = silver > 0 and _G.string.format(_G.SILVER_AMOUNT, silver) .. (copper > 0 and ", " or "") or ""
  local copperString = copper > 0 and _G.string.format(_G.COPPER_AMOUNT, copper) or ""

  local message = _G.string.format(_G.YOU_LOOT_MONEY .. "%s%s%s", "", goldString, silverString, copperString)

  local info = _G.ChatTypeInfo["MONEY"]
  for i = 1, _G.NUM_CHAT_WINDOWS do
    local chatFrame = _G["ChatFrame" .. i]
    if chatFrame:IsEventRegistered("CHAT_MSG_MONEY") then
      chatFrame:AddMessage(message, info.r, info.g, info.b, info.id)
    end
  end
end
-- http://wowprogramming.com/utils/xmlbrowser/test/FrameXML/AlertFrames.xml
-- http://wowprogramming.com/utils/xmlbrowser/test/FrameXML/AlertFrames.lua
------------------------------------------------------------------------------------------------------------------------

_G.LootWonAlertFrame_ShowAlert = function(...)
  -- TODO.  Display message styled after normal loot message.
  print(...)
end

_G.LootUpgradeFrame_ShowAlert = function() end

_G.AchievementAlertFrame_ShowAlert = function(...)
  print(...)
end

_G.AlertFrame:UnregisterEvent("GARRISON_BUILDING_ACTIVATABLE") -- GarrisonBuildingAlertFrame
_G.AlertFrame:UnregisterEvent("GARRISON_MISSION_FINISHED") -- GarrisonMissionAlertFrame
--_G.AlertFrame:UnregisterEvent("GARRISON_FOLLOWER_ADDED") -- GarrisonFollowerAlertFrame

local frame = _G.CreateFrame("Frame")

frame:SetScript("OnEvent", function(self, event, ...)
  return self[event](self, ...)
end)

function frame:ADDON_LOADED(name)
  -- It's not guaranteed that the first ADDON_LOADED event we see is for this addon. It's possible that this file is
  -- loaded and we get here in response to a different addon having finished loading.
  if name ~= addonName then return end

  -- FIXME: this function still gets called for every single other addon loaded later.  This seems to be caused by
  -- calling LoadAddOn("Blizzard_PVPUI") in this addon's tooltips.lua in response to ADDON_LOADED.
  self:UnregisterEvent("ADDON_LOADED")
  --self.ADDON_LOADED = nil
end

frame:RegisterEvent("ADDON_LOADED")

-- vim: tw=120 sts=2 sw=2 et
