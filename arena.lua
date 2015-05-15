local addonName, addon = ...

setfenv(1, addon)

local frame = _G.CreateFrame("Frame")

frame:SetScript("OnEvent", function(self, event, ...)
  return self[event](self, ...)
end)

local arena1FramePoint = { _G.NKArena1Frame:GetPoint(1) }
local newArena1FramePoint = { _G.NKTargetFrame:GetPoint(1) }
local otherTargetAurasPoint = { _G.NKAOtherTargetAuras:GetPoint(1) }
local newOtherTargetAurasPoint = { _G.NKAOtherTargetAuras:GetPoint(1) }
newOtherTargetAurasPoint[2] = _G.NKAltTargetFrame
local otherTargetAurasParent = _G.NKAOtherTargetAuras:GetParent()

function frame:PLAYER_ENTERING_WORLD()
  local _, instanceType = _G.IsInInstance()
  if instanceType == "arena" then
    _G.NinjaKittyUF.disableUnitFrame(_G.NKTargetFrame)
    _G.NinjaKittyUF.disableUnitFrame(_G.NKFocusFrame)
    _G.NinjaKittyUF.disableCastFrame(_G.NKFocusCastFrame)
    _G.NKArena1Frame:ClearAllPoints()
    _G.NKArena1Frame:SetPoint(_G.unpack(newArena1FramePoint))
    _G.NinjaKittyUF.enableUnitFrame(_G.NKAltTargetFrame)
    _G.NKAOtherTargetAuras:ClearAllPoints()
    _G.NKAOtherTargetAuras:SetPoint(_G.unpack(newOtherTargetAurasPoint))
    _G.NKAOtherTargetAuras:SetParent(_G.NKAltTargetFrame)
    _G.NKALongTargetBuffs:SetParent(_G.NKAltTargetFrame)
  else
    _G.NinjaKittyUF.enableUnitFrame(_G.NKTargetFrame)
    _G.NinjaKittyUF.enableUnitFrame(_G.NKFocusFrame)
    _G.NinjaKittyUF.enableCastFrame(_G.NKFocusCastFrame)
    _G.NKArena1Frame:ClearAllPoints()
    _G.NKArena1Frame:SetPoint(_G.unpack(arena1FramePoint))
    _G.NinjaKittyUF.disableUnitFrame(_G.NKAltTargetFrame)
    _G.NKAOtherTargetAuras:ClearAllPoints()
    _G.NKAOtherTargetAuras:SetPoint(_G.unpack(otherTargetAurasPoint))
    _G.NKAOtherTargetAuras:SetParent(otherTargetAurasParent)
    _G.NKALongTargetBuffs:SetParent(otherTargetAurasParent)
  end
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")

--[==[
do
  local frame = _G.NKArena1Frame
  _G.assert(frame)
  -- Requires using the "SecureHandlerAttributeTemplate" template.
  --[=[
  frame:SetAttribute("_onattributechanged", [[ -- arguments: self, name, value
    if name == "statehidden" and value ~= hidden then
      print(self:GetName(), name, value)
      hidden = value
    end
  ]])
  frame:Execute([[
    hidden = self:GetAttribute("statehidden")
  ]])
  ]=]
  frame:SetFrameRef("targetFrame", _G.NKTargetFrame)
  frame:Execute([[
    targetFrame = self:GetFrameRef("targetFrame")
    targetFramePoint = newtable()
    targetFramePoint[1], targetFramePoint[2], targetFramePoint[3], targetFramePoint[4],
      targetFramePoint[5] = targetFrame:GetPoint(1)
    newTargetFramePoint = newtable()
    newTargetFramePoint[1] = targetFramePoint[1]
    newTargetFramePoint[2] = targetFramePoint[2]
    newTargetFramePoint[3] = targetFramePoint[3]
    newTargetFramePoint[4] = targetFramePoint[4] + self:GetWidth() + 16 + 32 + 2
    newTargetFramePoint[5] = targetFramePoint[5]
  ]])
  -- Requires using the "SecureHandlerShowHideTemplate" template.
  frame:SetAttribute("_onshow", [[ -- arguments: self
    targetFrame:ClearAllPoints()
    targetFrame:SetPoint(unpack(newTargetFramePoint))
  ]])
  frame:SetAttribute("_onhide", [[ -- arguments: self
    targetFrame:ClearAllPoints()
    targetFrame:SetPoint(unpack(targetFramePoint))
  ]])
end
--]==]

-- vim: tw=120 sw=2 et