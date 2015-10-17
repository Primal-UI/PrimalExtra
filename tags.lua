local addonName, addon = ...

setfenv(1, addon)

--[[
function TargetHealth(unit, unitOwner) -- Events: UNIT_HEALTH_FREQUENT UNIT_HEALTH UNIT_CONNECTION
  if _G.UnitIsDead(unit) then          -- UNIT_MAXHEALTH
    return "Dead"
  elseif _G.UnitIsGhost(unit) then
    return "Ghost"
  elseif not _G.UnitIsConnected(unit) then
    return "Offline"
  end
  local health = _G.UnitHealth(unit)
  local maxHealth = _G.UnitHealthMax(unit)
  local healthPercent = (100 * health / maxHealth) + 0.5
  if healthPercent <= 40 and healthPercent >= 25 then
    if maxHealth / 1000 >= 10000 then
      return _G.string.format("%dm (%d%%)", _G.math.floor((health + 500000) / 1000000), healthPercent)
    else
      return _G.string.format("%dk (%d%%)", _G.math.floor((health + 500) / 1000), healthPercent)
    end
  else
    if maxHealth / 1000 >= 10000 then
      return _G.string.format("%dm", _G.math.floor((health + 500000) / 1000000))
    else
      return _G.string.format("%dk", _G.math.floor((health + 500) / 1000))
    end
  end
end

function Health(unit, unitOwner) -- Events: UNIT_HEALTH_FREQUENT UNIT_HEALTH UNIT_CONNECTION
                                 -- UNIT_MAXHEALTH
  if _G.UnitIsDead(unit) then
    return "Dead"
  elseif _G.UnitIsGhost(unit) then
    return "Ghost"
  elseif not _G.UnitIsConnected(unit) then
    return "Offline"
  end
  local health = _G.UnitHealth(unit)
  local maxHealth = _G.UnitHealthMax(unit)
  if maxHealth / 1000 >= 10000 then
    return _G.string.format("%dm", _G.math.floor((health + 500000) / 1000000))
  else
    return _G.string.format("%dk", _G.math.floor((health + 500) / 1000))
  end
end

-- Events: UNIT_POWER_FREQUENT UNIT_MAXPOWER UNIT_DISPLAYPOWER
function Power(unit, unitOwner)
  if _G.UnitPowerMax(unit) <= 0 then
    return nil
  elseif _G.UnitIsDeadOrGhost(unit) then
    return 0
  end

  local power = _G.UnitPower(unit)
  local powerType = _G.UnitPowerType(unit)

  if powerType == _G.SPELL_POWER_MANA then
    return _G.string.format("%dk", _G.math.floor((power + 500) / 1000))
  else
    return power
  end
end

-- http://wowprogramming.com/docs/api_types#specID
local specNames = {
  [62]  = "Arcane",
  [63]  = "Fire",
  [64]  = "Frost",
  [65]  = "Holy",
  [66]  = "Prot",
  [70]  = "Ret",
  [71]  = "Arms",
  [72]  = "Fury",
  [73]  = "Prot",
  [102] = "Balance",
  [103] = "Feral",
  [104] = "Guardian",
  [105] = "Resto",
  [250] = "Blood",
  [251] = "Frost",
  [252] = "Unh",
  [253] = "BM",
  [254] = "MM",
  [255] = "Surv",
  [256] = "Disc",
  [257] = "Holy",
  [258] = "Shadow",
  [259] = "Ass",
  [260] = "Combat",
  [260] = "Sub",
  [262] = "Ele",
  [263] = "Enh",
  [264] = "Resto",
  [265] = "Aff",
  [266] = "Demo",
  [267] = "Destro",
  [268] = "BM",
  [269] = "WW",
  [270] = "MW",
}

-- Events: UNIT_NAME_UPDATE ARENA_PREP_OPPONENT_SPECIALIZATIONS UNIT_TARGETABLE_CHANGED
function ArenaSpec(unit, unitOwner)
  local specName = "Unknown"
  --if not IsActiveBattlefieldArena() then return specName end

  for i = 1, _G.GetNumArenaOpponents() do
    if _G.UnitIsUnit(unit, "arena" .. i) then
      local specId = _G.GetArenaOpponentSpec(i)
      if specId then
        --specId, specName = _G.GetSpecializationInfoByID(specId)
	specName = specNames[specId]
      end
    end
  end
  return specName
end
--]]

-- vim: tw=120 sts=2 sw=2 et
