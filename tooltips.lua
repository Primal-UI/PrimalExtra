local addonName, addon = ...

setfenv(1, addon)

local plainBackdrop = {
  bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
  tile = false,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
}
-- wowprogramming.com/utils/xmlbrowser/test/FrameXML/ItemRef.xml

-- For GameTooltipTemplate based and other tooltips.
local function restyleTooltip(tooltip)
  tooltip:SetBackdrop(plainBackdrop)
  tooltip:SetBackdropColor(0, 0, 0, .75)
  local originalSetBackdrop = tooltip.SetBackdrop
  tooltip.SetBackdrop = function(self, ...)
    originalSetBackdrop(self, plainBackdrop)
  end
  local originalSetBackdropColor = tooltip.SetBackdropColor
  tooltip.SetBackdropColor = function(self, ...)
    originalSetBackdropColor(self, 0, 0, 0, .75)
  end
  -- Don't ValidateFramePosition().  See wowprogramming.com/utils/xmlbrowser/test/FrameXML/ItemRef.xml
  if tooltip:GetScript("OnDragStop") then
    tooltip:SetScript("OnDragStop", function(self)
      self:StopMovingOrSizing()
      if _G.IsModifiedClick("COMPAREITEMS") then
        _G.GameTooltip_ShowCompareItem(self, true)
        self.comparing = true;
      end
    end)
  end
end

-- See TooltipBorderedFrameTemplate at wowprogramming.com/utils/xmlbrowser/test/SharedXML/SharedUIPanelTemplates.xml
local function restyleTooltipBorderedFrameTemplateBasedTooltip(tooltip)
  tooltip:HookScript("OnShow", function(self)
    self.BorderTopLeft:SetTexture(0, 0, 0, .75)
    self.BorderTopLeft:SetPoint("TOPLEFT", 2, -2)
    --self.BorderTopLeft:SetSize(4, 4)
    self.BorderTopRight:SetTexture(0, 0, 0, .75)
    self.BorderTopRight:SetPoint("TOPRIGHT", -2, -2)
    --self.BorderTopRight:SetSize(4, 4)
    self.BorderBottomRight:SetTexture(0, 0, 0, .75)
    self.BorderBottomRight:SetPoint("BOTTOMRIGHT", -2, 2)
    --self.BorderBottomRight:SetSize(4, 4)
    self.BorderBottomLeft:SetTexture(0, 0, 0, .75)
    self.BorderBottomLeft:SetPoint("BOTTOMLEFT", 2, 2)
    --self.BorderBottomLeft:SetSize(4, 4)
    self.BorderTop:SetTexture(0, 0, 0, .75)
    self.BorderTop:SetPoint("TOPLEFT", 10, -2)
    self.BorderTop:SetPoint("TOPRIGHT", -10, -2)
    --self.BorderTop:SetSize(4, 4)
    self.BorderRight:SetTexture(0, 0, 0, .75)
    self.BorderRight:SetPoint("TOPRIGHT", -2, -10)
    self.BorderRight:SetPoint("BOTTOMRIGHT", -2, 10)
    --self.BorderRight:SetSize(4, 4)
    self.BorderBottom:SetTexture(0, 0, 0, .75)
    self.BorderBottom:SetPoint("BOTTOMLEFT", 10, 2)
    self.BorderBottom:SetPoint("BOTTOMRIGHT", -10, 2)
    --self.BorderBottom:SetSize(4, 4)
    self.BorderLeft:SetTexture(0, 0, 0, .75)
    self.BorderLeft:SetPoint("TOPLEFT", 2, -10)
    self.BorderLeft:SetPoint("BOTTOMLEFT", 2, 10)
    --self.BorderLeft:SetSize(4, 4)
    self.Background:SetTexture(0, 0, 0, .75) -- TODO: just hide everything except this.
  end)
end

local frame = _G.CreateFrame("Frame")

frame:SetScript("OnEvent", function(self, event, ...)
  return self[event] and self[event](self, ...)
end)

function frame:ADDON_LOADED(name)
  if name ~= addonName then return end

  local tooltips = {
    "DropDownList1MenuBackdrop",
    "DropDownList2MenuBackdrop", -- DropDownList3 doesn't get created until it's shown.
    "FriendsTooltip",
    "GameTooltip",
    "ItemRefTooltip",
    "ItemRefShoppingTooltip1",
    "ItemRefShoppingTooltip2",
    _G.QuestScrollFrame.StoryTooltip, -- wowprogramming.com/utils/xmlbrowser/test/FrameXML/QuestMapFrame.xml
    "ShoppingTooltip1",
    "ShoppingTooltip2",
    "WorldMapTooltip",
    "WorldMapCompareTooltip1",
    "WorldMapCompareTooltip2",
  }

  for _, tooltip in _G.ipairs(tooltips) do
    if _G.type(tooltip) == "string" and _G[tooltip] then
      restyleTooltip(_G[tooltip])
    elseif _G.type(tooltip) == "table" then
      restyleTooltip(tooltip)
    else
      _G.error()
    end
  end

  -- This takes care of restyling DropDownList3MenuBackdrop once DropDownList3 is created.
  -- wowprogramming.com/utils/xmlbrowser/test/FrameXML/UIDropDownMenu.xml
  -- wowprogramming.com/utils/xmlbrowser/test/FrameXML/UIDropDownMenu.lua
  _G.hooksecurefunc("UIDropDownMenu_CreateFrames", function(level, index)
    if level >= 3 then
      restyleTooltip(_G["DropDownList" .. level .. "MenuBackdrop"])
    end
  end)

  restyleTooltipBorderedFrameTemplateBasedTooltip(_G.BattlePetTooltip)
  restyleTooltipBorderedFrameTemplateBasedTooltip(_G.FloatingBattlePetTooltip)
  restyleTooltipBorderedFrameTemplateBasedTooltip(_G.FloatingPetBattleAbilityTooltip)

  -- Created by Blizzard_PetBattleUI.
  restyleTooltipBorderedFrameTemplateBasedTooltip(_G.PetBattlePrimaryAbilityTooltip)
  restyleTooltipBorderedFrameTemplateBasedTooltip(_G.PetBattlePrimaryUnitTooltip)

  restyleTooltipBorderedFrameTemplateBasedTooltip(_G.GarrisonFollowerTooltip)
  restyleTooltipBorderedFrameTemplateBasedTooltip(_G.GarrisonFollowerAbilityTooltip)
  restyleTooltipBorderedFrameTemplateBasedTooltip(_G.FloatingGarrisonFollowerTooltip)
  restyleTooltipBorderedFrameTemplateBasedTooltip(_G.FloatingGarrisonFollowerAbilityTooltip)
  restyleTooltipBorderedFrameTemplateBasedTooltip(_G.FloatingGarrisonMissionTooltip)
  restyleTooltipBorderedFrameTemplateBasedTooltip(_G.GarrisonShipyardFollowerTooltip)
  restyleTooltipBorderedFrameTemplateBasedTooltip(_G.FloatingGarrisonShipyardFollowerTooltip)

  -- Literally everything more elegant I could think of to prevent the default UI from changing the tooltip's backdrop
  -- color failed.
  _G.GameTooltip:HookScript("OnUpdate", function(self, elapsed)
    local red, green, blue, alpha = self:GetBackdropColor()
    if red ~= 0 or green ~= 0 or blue ~= 0 or _G.math.abs(alpha - .75) > 0.01 then
      self:SetBackdropColor(0, 0, 0, .75)
    end
  end)

  -- SetAlpha is never called. The tooltip still changes its alpha value while fading.
  --[[do
    local originalSetAlpha = _G.GameTooltip.SetAlpha
    _G.GameTooltip.SetAlpha = function(self, alpha)
      -- ...
    end
  end]]

  -- http://us.battle.net/wow/en/forum/topic/2416153699
  _G.hooksecurefunc(_G.GameTooltip, "FadeOut", function(self)
    self:Hide()
  end)

  -- This (including the comments) is mostly stolen from TipTac (core.lua).
  do
    local tooltipUnit

    _G.GameTooltip:HookScript("OnTooltipSetUnit", function(self)
        tooltipUnit = _G.select(2, self:GetUnit())

        -- Concated unit tokens such as "targettarget" cannot be returned as the unit by GameTooltip:GetUnit() and it
        -- will return as "mouseover", but the "mouseover" unit is still invalid at this point for those unitframes!  To
        -- overcome this problem, we look if the mouse is over a unitframe, and if that unitframe has a unit attribute
        -- set?
        if not tooltipUnit then
          local mouseFocus = _G.GetMouseFocus()
          tooltipUnit = mouseFocus and mouseFocus:GetAttribute("unit")
        end

        -- A mage's mirror images sometimes doesn't return a unit, this would fix it.
        if not tooltipUnit and _G.UnitExists("mouseover") then
          tooltipUnit = "mouseover"
        end

        -- Sometimes when you move your mouse quicky over units in the worldframe, we can get here without a unit.
        if not tooltipUnit then
          self:Hide()
          return
        end

        -- A "mouseover" unit is better to have as we can then safely say the tooltip should no longer show when it
        -- becomes invalid.  Harder to say with a "party2" unit.  This also helps fix the problem that "mouseover" units
        -- aren't valid for group members out of range, a bug that has been in WoW since 3.0.2 I think.
        if _G.UnitIsUnit(tooltipUnit, "mouseover") then
          tooltipUnit = "mouseover"
        end

        -- Az: Sometimes this wasn't getting reset, the fact a cleanup isn't performed at this point, now that it was
        -- moved to "OnTooltipCleared" is very bad, so this is a fix.
        self.fadeOut = nil
    end)

    _G.GameTooltip:HookScript("OnTooltipCleared", function(self)
      tooltipUnit = nil
      self.fadeOut = nil
    end)

    -- http://www.wowinterface.com/forums/showthread.php?t=5301
    _G.GameTooltip:HookScript("OnUpdate", function(self, elapsed)
      if tooltipUnit then
        if not _G.UnitExists(tooltipUnit) then
          self:FadeOut()
        else

        end
      end
      --local name, unit = self:GetUnit()
    end)
  end -- This leaves us with e.g. mailboxes and campfires still fading out instead of hiding instantly.

  -- "QueueStatusFrame" looks like a GameTooltip but is a Frame.  Restyle it as well.
  -- wowprogramming.com/utils/xmlbrowser/test/FrameXML/QueueStatusFrame.xml
  -- wowprogramming.com/utils/xmlbrowser/test/FrameXML/QueueStatusFrame.lua
  local function StyleQueueStatusFrame(self)
    for _, frame in _G.pairs({ self:GetChildren() }) do
      frame:SetBackdrop(nil)
      frame:SetBackdropColor(0, 0, 0, 0)
      frame:SetBackdropBorderColor(0, 0, 0, 0)
    end
    for _, region in _G.pairs({ self:GetRegions() }) do
      if region:GetObjectType() == "Texture" and (region:GetDrawLayer() == "BACKGROUND" or region:GetDrawLayer() ==
	  "BORDER")
      then
        region:Hide()
      end
    end
    self:SetBackdrop(plainBackdrop)
    self:SetBackdropColor(0, 0, 0, .75)
  end

  _G.QueueStatusFrame:SetScript("OnShow", function(self)
    _G.QueueStatusFrame:SetScript("OnUpdate", StyleQueueStatusFrame)
  end)
  _G.QueueStatusFrame:SetScript("OnHide", function(self)
    _G.QueueStatusFrame:SetScript("OnUpdate", nil)
  end)
  --_G.hooksecurefunc("QueueStatusFrame_Update", StyleQueueStatusFrame)

  -- Restyle FrameStackTooltip.
  local function StyleFrameStackTooltip()
    _G.FrameStackTooltip:HookScript("OnShow", function()
      _G.FrameStackTooltip:SetBackdrop(plainBackdrop)
      _G.FrameStackTooltip:SetBackdropColor(0, 0, 0, .75)
    end)
    _G.FrameStackTooltip:SetBackdrop(plainBackdrop)
    _G.FrameStackTooltip:SetBackdropColor(0, 0, 0, .75)
    StyleFrameStackTooltip = function() end
  end

  -- wowprogramming.com/utils/xmlbrowser/test/AddOns/Blizzard_DebugTools/Blizzard_DebugTools.xml
  -- wowprogramming.com/utils/xmlbrowser/test/AddOns/Blizzard_DebugTools/Blizzard_DebugTools.lua
  -- wowprogramming.com/docs/api/hooksecurefunc
  -- wowprogramming.com/utils/xmlbrowser/test/FrameXML/ChatFrame.lua
  _G.hooksecurefunc(_G.SlashCmdList, "FRAMESTACK", StyleFrameStackTooltip)

  _G.GameTooltipStatusBar:Hide()
  _G.GameTooltipStatusBar:SetScript("OnShow", function() _G.GameTooltipStatusBar:Hide() end)

  -- Change the position of GameTooltip.  Partly based on Tipsy (curse.com/addons/wow/tipsy).
  -- wowprogramming.com/utils/xmlbrowser/test/FrameXML/GameTooltip.lua
  _G.hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
    tooltip:SetOwner(parent, "ANCHOR_NONE")
    tooltip:ClearAllPoints()
    --tooltip:SetPoint("BOTTOMRIGHT", _G.UIParent, "BOTTOMRIGHT", -_G.CONTAINER_OFFSET_X, _G.CONTAINER_OFFSET_Y - 6)
    tooltip:SetPoint("BOTTOMRIGHT", _G.UIParent, "BOTTOMRIGHT", 0, 122)
  end)
  --[[
  _G.GameTooltip:SetScript("OnTooltipSetDefaultAnchor", function(self)
    --self:SetOwner(_G.UIParent, "ANCHOR_NONE")
    --self:ClearAllPoints()
    self:SetPoint("BOTTOMRIGHT", _G.UIParent, "BOTTOMRIGHT", -_G.CONTAINER_OFFSET_X,
      _G.CONTAINER_OFFSET_Y - 6)
  end)
  --]]

  self.ADDON_LOADED = function(self, name)
    if name == "Blizzard_PVPUI" then
      restyleTooltip(_G.ConquestTooltip)
    elseif name == "Blizzard_Collections" then -- Used to be called Blizzard_PetJournal
      restyleTooltipBorderedFrameTemplateBasedTooltip(_G.PetJournalPrimaryAbilityTooltip)
      restyleTooltipBorderedFrameTemplateBasedTooltip(_G.PetJournalSecondaryAbilityTooltip)
    elseif name == "Blizzard_EncounterJournal" then
      restyleTooltip(_G.EncounterJournalTooltip)
    elseif name == "Blizzard_DebugTools" then
      restyleTooltip(_G.EventTraceTooltip)
    elseif name == "Blizzard_GarrisonUI" then
      restyleTooltip(_G.GarrisonMissionMechanicTooltip)
      restyleTooltip(_G.GarrisonMissionMechanicFollowerCounterTooltip)
      restyleTooltip(_G.GarrisonShipyardMapMissionTooltip)
      restyleTooltip(_G.GarrisonBonusAreaTooltip)
      restyleTooltipBorderedFrameTemplateBasedTooltip(_G.GarrisonBuildingFrame.BuildingLevelTooltip)
    end
  end
end

frame:RegisterEvent("ADDON_LOADED")

-- Some code was based on TooltipBorderRemover:
-- http://www.wowinterface.com/downloads/info12602-TooltipBorderRemover.html

-- vim: tw=120 sts=2 sw=2 et
