-- From ElvUI_WindTools and ElvUI_LivvenUI

local R, E, L, V, P, G = unpack(select(2, ...))
local ElvUF = ElvUI.oUF

-- Lua functions
local floor, format = floor, format

-- WoW API / Variables
local GetNumGroupMembers = GetNumGroupMembers
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local UnitIsUnit = UnitIsUnit
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType

ElvUF.Tags.Events['power:smart'] = 'UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT UNIT_MAXPOWER'
ElvUF.Tags.Methods['power:smart'] = function(unit)
    local powerType = UnitPowerType(unit)
    local power = UnitPower(unit)
    if power == 0 then
        return ""
    elseif powerType == 0 then -- MANA
        local powerMax = UnitPowerMax(unit)
        local percent = power * 100 / powerMax
        if percent < 10 then
            return format("%.2f%%", percent)
        elseif percent < 100 then
            return format("%.1f%%", percent)
        else
            return format("%.0f%%", percent)
        end
    else
        return format("%d", power)
    end
end

ElvUF.Tags.Events['num:targeting'] = 'UNIT_TARGET PLAYER_TARGET_CHANGED GROUP_ROSTER_UPDATE'
ElvUF.Tags.Methods['num:targeting'] = function(unit)
    if not IsInGroup() then return "" end

    local result = 0
    for i = 1, GetNumGroupMembers() do
        local groupUnit = (IsInRaid() and 'raid' or 'party') .. i
        if UnitIsUnit(groupUnit .. 'target', unit) then
            result = result + 1
        end
    end

    return (result > 0 and result or "")
end

E:AddTagInfo('power:smart', 'RhythmBox', "Display the unit's mana as a percentage, and other power's the current value.")
E:AddTagInfo('num:targeting', 'RhythmBox', "Display the number of group/raid member is targeting the unit.")
