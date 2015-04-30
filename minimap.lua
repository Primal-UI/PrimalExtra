local addonName, addon = ...

setfenv(1, addon)

local frame = _G.CreateFrame("Frame")

frame:SetScript("OnEvent", function(self, event, ...)
  return self[event] and self[event](self, ...)
end)

function frame:ADDON_LOADED(name)
  if name ~= addonName then return end

  self:UnregisterEvent("ADDON_LOADED")

  if _G.IsAddOnLoaded("SexyMap") then
    local f = _G.CreateFrame("frame")
    local total = 0
    local function fadeIn(self, elapsed)
      total = total + elapsed
      if total < 1 then
        --_G.Minimap:SetAlpha(total)
      else
        --_G.Minimap:SetAlpha(1)
        _G.Minimap:SetMaskTexture("Interface\\AddOns\\SexyMap\\shapes\\circle.tga")
        f:SetScript("OnUpdate", nil)
      end
    end
    local function fadeOut(self, elapsed)
      total = total - elapsed
      if total > 0  then
        --Minimap:SetAlpha(total)
      else
        --_G.Minimap:SetAlpha(1)
        _G.Minimap:SetMaskTexture("Interface\\AddOns\\NinjaKittyMedia\\minimap\\shapes\\ninja_kitty_blank.tga")
        f:SetScript("OnUpdate", nil)
      end
    end
    --[[
    _G.Minimap:HookScript("OnEnter", function()
    f:SetScript("OnUpdate", fadeIn)
    end)
    _G.Minimap:HookScript("OnLeave", function()
    f:SetScript("OnUpdate", fadeOut)
    end)
    --]]
    _G.showMinimapBG = function()
      _G.Minimap:SetMaskTexture("Interface\\AddOns\\SexyMap\\shapes\\circle.tga")
      total = total + 3
      f:SetScript("OnUpdate", fadeOut)
    end
    local shown = false
    _G.toggleMinimapBG = function()
      if shown then
        _G.Minimap:SetMaskTexture("Interface\\AddOns\\NinjaKittyMedia\\minimap\\shapes\\ninja_kitty_blank.tga")
      else
        _G.Minimap:SetMaskTexture("Interface\\AddOns\\SexyMap\\shapes\\circle.tga")
      end
      shown = not shown
    end
    -- Minimap_OnClick is the OnMouseUp handler of Minimap. SexyMap overwrites the handler but calls it from there.
    -- TODO: it's kind of annoying that we still ping the minimap with a right click.
    _G.hooksecurefunc("Minimap_OnClick", function()
      local button = _G.GetMouseButtonClicked()
      if button == "RightButton" then
        _G.toggleMinimapBG()
      end
    end)
    -- http://wowprogramming.com/utils/xmlbrowser/test/FrameXML/Minimap.lua
    -- http://wowprogramming.com/utils/xmlbrowser/test/FrameXML/Minimap.xml
  end
  self.ADDON_LOADED = nil
end

frame:RegisterEvent("ADDON_LOADED")

-- vim: tw=120 sts=2 sw=2 et
