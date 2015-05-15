local addonName, addon = ...

setfenv(1, addon)

local frame = _G.CreateFrame("Frame")

frame:SetScript("OnEvent", function(self, event, ...)
  return self[event] and self[event](self, ...)
end)

function frame:ADDON_LOADED(name)
  if name ~= addonName then return end

  self:UnregisterEvent("ADDON_LOADED")

  ----------------------------------------------------------------------------------------------------------------------
  -- auto-zoom ---------------------------------------------------------------------------------------------------------
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
	    -- already zoomed out completely. Otherwise we would do Minimap:SetZoom(zoomLevel).
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
    -- such areas. It does not fire when directly setting the minimap's zoom level. See
    -- http://wowprogramming.com/docs/events/MINIMAP_UPDATE_ZOOM).
    function f:MINIMAP_UPDATE_ZOOM()
      total = 1
      f:SetScript("OnUpdate", onUpdate)
    end

    function f:PLAYER_ENTERING_WORLD()
      total = 1
      f:SetScript("OnUpdate", onUpdate)
    end

    ----[[
    Minimap:HookScript("OnEnter", function(self, motion)
      f:SetScript("OnUpdate", nil)
    end)

    Minimap:HookScript("OnLeave", function(self, motion)
      total = 0
      f:SetScript("OnUpdate", onUpdate)
    end)
    --]]

    f:SetScript("OnEvent", function(self, event, ...)
      return self[event](self, ...)
    end)

    f:RegisterEvent("MINIMAP_UPDATE_ZOOM")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
  end
  ----------------------------------------------------------------------------------------------------------------------

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

    self:RegisterEvent("PLAYER_LOGIN")
  end
  self.ADDON_LOADED = nil
end

function frame:PLAYER_LOGIN()
  -- Allow SexyMap to handle PLAYER_LOGIN.
  _G.C_Timer.After(0.001, function()
    local script = _G.Minimap:GetScript("OnMouseUp")
    _G.Minimap:SetScript("OnMouseUp", function(self, button)
      if button == "RightButton" then
        _G.toggleMinimapBG()
      elseif button == "MiddleButton" then
        _G.RunBinding("TOGGLEBATTLEFIELDMINIMAP")
      elseif button == "Button4" then
        -- ...
      elseif button == "Button5" then
        -- ...
      else
        script(self, button)
      end
    end)
  end)
  self.PLAYER_LOGIN = nil
end

frame:RegisterEvent("ADDON_LOADED")

-- vim: tw=120 sts=2 sw=2 et
