-- Prevents the GarrisonMissionAlertFrame and GarrisonBuildingAlertFrame from being shown.
-- http://wowprogramming.com/utils/xmlbrowser/test/FrameXML/AlertFrames.lua

local addonName, addon = ...

setfenv(1, addon)

------------------------------------------------------------------------------------------------------------------------
-- Prevent all MONEY_WON_ALERT_FRAMES from ever showing up.  Instead, add a chat message in the style of the normal
-- money loot messages.  This should also prevent the creation of a lot of frames as only MoneyWonAlertFrame1 is always
-- created and this function will create an extra unnamed frame when there is no unused frame in MONEY_WON_ALERT_FRAMES.
_G.MoneyWonAlertFrame_ShowAlert = function(amount)
  print("MoneyWonAlertFrame_ShowAlert() blocked:", amount)

  local gold   = _G.math.floor(amount / 10000)
  local silver = _G.math.floor((amount - 10000 * gold) / 100)
  local copper = amount % 100

  local goldString   = gold   > 0 and _G.string.format(_G.GOLD_AMOUNT, gold) or ""
  local silverString = silver > 0 and (gold > 0 and ", " or "") .. _G.string.format(_G.SILVER_AMOUNT, silver) or ""
  local copperString = copper > 0 and _G.string.format(", " .. _G.COPPER_AMOUNT, copper) or ""

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

local LOOT_SOURCE_GARRISON_CACHE = 10 -- In wowprogramming.com/utils/xmlbrowser/test/FrameXML/AlertFrames.lua

_G.LootWonAlertFrame_ShowAlert = function(itemLink, quantity, rollType, roll, specId, isCurrency, showFactionBg, source)
  print("LootWonAlertFrame_ShowAlert() blocked:", itemLink, quantity, rollType, roll, specId, isCurrency, showFactionBg,
    source)

  _G.assert(itemLink, quantity, isCurrency)

  -- I think there might actually always be a chat message for this type of alert frame already.  TODO: confirm.
  --[=[

  -- There already is a chat message when looting the Garrison Cache.  There are probably other instances where a
  -- chat message is already added by default.
  if source and source == LOOT_SOURCE_GARRISON_CACHE then return end

  local message

  if isCurrency then
    if quantity == 1 then
      message = _G.string.format(_G.CURRENCY_GAINED, itemLink)
    else
      message = _G.string.format(_G.CURRENCY_GAINED_MULTIPLE, itemLink, quantity)
    end
    local info = _G.ChatTypeInfo["CURRENCY"]
    for i = 1, _G.NUM_CHAT_WINDOWS do
      local chatFrame = _G["ChatFrame" .. i]
      if chatFrame:IsEventRegistered("CHAT_MSG_CURRENCY") then
        chatFrame:AddMessage(message, info.r, info.g, info.b, info.id)
      end
    end
  -- I think there always is a chat message for items.
  --[[
  else
    if quantity == 1 then
      message = _G.string.format(_G.LOOT_ITEM_PUSHED_SELF, itemLink)
    else
      message = _G.string.format(_G.LOOT_ITEM_PUSHED_SELF_MULTIPLE, itemLink, quantity)
    end
  --]]
  end
  --]=]
end

_G.LootUpgradeFrame_ShowAlert = function()
  -- Seems completely useless.  I don't feel like there has to be a chat message to replace it.
  print("LootWonAlertFrame_ShowAlert() blocked")
end

_G.DigsiteCompleteToastFrame_ShowAlert = function(researchBranchId)
  -- Useless.
end

_G.AchievementAlertFrame_ShowAlert = function(...)
  -- The normal achievement notification in chat is enough.
end

-- Replacement for criteria alert frames.  TODO: Test.
_G.CriteriaAlertFrame_ShowAlert = function(achievementId, criteriaId, ...)
  --print("CriteriaAlertFrame_ShowAlert() blocked:", achievementId, criteriaId, ...)

  -- Apparently the second argument passed to this function already is the criteria string now.
  local criteriaString = criteriaId

  --local criteriaString = _G.GetAchievementCriteriaInfoByID(achievementId, criteriaId)

  local info = _G.ChatTypeInfo["ACHIEVEMENT"]
  for i = 1, _G.NUM_CHAT_WINDOWS do
    local chatFrame = _G["ChatFrame" .. i]
    if chatFrame:IsEventRegistered("CHAT_MSG_ACHIEVEMENT") then
      chatFrame:AddMessage("Achievement progress: " .. _G.GetAchievementLink(achievementId) .. ": " .. criteriaString,
        info.r, info.g, info.b, info.id)
    end
  end
end
-- github.com/tekkub/wow-ui-source/blob/ptr/FrameXML/AlertFrames.lua

_G.AlertFrame:UnregisterEvent("GARRISON_BUILDING_ACTIVATABLE") -- GarrisonBuildingAlertFrame
_G.AlertFrame:UnregisterEvent("GARRISON_MISSION_FINISHED") -- GarrisonMissionAlertFrame
_G.AlertFrame:UnregisterEvent("GARRISON_FOLLOWER_ADDED") -- GarrisonFollowerAlertFrame

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
