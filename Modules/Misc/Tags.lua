-- From ElvUI_WindTools
-- https://github.com/fang2hou/ElvUI_WindTools/blob/master/Modules/More/EnhancedTags.lua

local R, E, L, V, P, G = unpack(select(2, ...))
local ElvUF = ElvUI.oUF
local RC = LibStub("LibRangeCheck-2.0")

-- Lua functions
local abs, assert, floor, format, gmatch, gsub = abs, assert, floor, format, gmatch, gsub
local strmatch, utf8lower, utf8sub = strmatch, utf8lower, utf8sub

-- WoW API / Variables
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local UnitIsConnected = UnitIsConnected
local UnitIsUnit = UnitIsUnit
local UnitIsGhost = UnitIsGhost
local UnitIsDead = UnitIsDead
local GetNumGroupMembers = GetNumGroupMembers
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitPowerType = UnitPowerType
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitClass = UnitClass
local UnitName = UnitName

-- GLOBALS: _TAGS, Hex, _COLORS

-- luacheck: no unused

local textFormatStyles = {
    ["CURRENT"] = "%s",
    ["CURRENT_MAX"] = "%s - %s",
    ["CURRENT_PERCENT"] =  "%s - %.1f%%",
    ["CURRENT_MAX_PERCENT"] = "%s - %s | %.1f%%",
    ["PERCENT"] = "%.1f%%",
    ["PERCENT_NO_SYMBOL"] = "%.1f",
    ["DEFICIT"] = "-%s"
}

local textFormatStylesNoDecimal = {
    ["CURRENT"] = "%s",
    ["CURRENT_MAX"] = "%s - %s",
    ["CURRENT_PERCENT"] =  "%s - %.0f%%",
    ["CURRENT_MAX_PERCENT"] = "%s - %s | %.0f%%",
    ["PERCENT"] = "%.0f%%",
    ["PERCENT_NO_SYMBOL"] = "%.0f",
    ["DEFICIT"] = "-%s"
}

local shortValueFormat
local function ShortValue(number, noDecimal)
    shortValueFormat = (noDecimal and "%.0f%s" or "%.1f%s")
    if E.db.general.numberPrefixStyle == "METRIC" then
        if abs(number) >= 1e9 then
            return format("%.1f%s", number / 1e9, "G")
        elseif abs(number) >= 1e6 then
            return format("%.1f%s", number / 1e6, "M")
        elseif abs(number) >= 1e3 then
            return format(shortValueFormat, number / 1e3, "k")
        else
            return format("%d", number)
        end
    elseif E.db.general.numberPrefixStyle == "CHINESE" then
        if abs(number) >= 1e8 then
            return format("%.1f%s", number / 1e8, L["Yi"])
        elseif abs(number) >= 1e4 then
            return format("%.1f%s", number / 1e4, L["Wan"])
        else
            return format("%d", number)
        end
    else
        if abs(number) >= 1e9 then
            return format("%.1f%s", number / 1e9, "B")
        elseif abs(number) >= 1e6 then
            return format("%.1f%s", number / 1e6, "M")
        elseif abs(number) >= 1e3 then
            return format(shortValueFormat, number / 1e3, "K")
        else
            return format("%d", number)
        end
    end
end

local function GetFormattedText(min, max, style, noDecimal)
    assert(textFormatStyles[style] or textFormatStylesNoDecimal[style], "CustomTags Invalid format style: "..style)
    assert(min, "CustomTags - You need to provide a current value. Usage: GetFormattedText(min, max, style, noDecimal)")
    assert(max, "CustomTags - You need to provide a maximum value. Usage: GetFormattedText(min, max, style, noDecimal)")

    if max == 0 then max = 1 end

    local chosenFormat
    if noDecimal then
        chosenFormat = textFormatStylesNoDecimal[style]
    else
        chosenFormat = textFormatStyles[style]
    end

    if style == "DEFICIT" then
        local deficit = max - min
        if deficit <= 0 then
            return ""
        else
            return format(chosenFormat, ShortValue(deficit, noDecimal))
        end
    elseif style == "PERCENT" or style == "PERCENT_NO_SYMBOL" then
        return format(chosenFormat, min / max * 100)
    elseif style == "CURRENT" or ((style == "CURRENT_MAX" or style == "CURRENT_MAX_PERCENT" or style == "CURRENT_PERCENT") and min == max) then
        if noDecimal then
            return format(textFormatStylesNoDecimal["CURRENT"], ShortValue(min, noDecimal))
        else
            return format(textFormatStyles["CURRENT"], ShortValue(min, noDecimal))
        end
    elseif style == "CURRENT_MAX" then
        return format(chosenFormat, ShortValue(min, noDecimal), ShortValue(max, noDecimal))
    elseif style == "CURRENT_PERCENT" then
        return format(chosenFormat, ShortValue(min, noDecimal), min / max * 100)
    elseif style == "CURRENT_MAX_PERCENT" then
        return format(chosenFormat, ShortValue(min, noDecimal), ShortValue(max, noDecimal), min / max * 100)
    end
end

local function abbrev(name)
    local letters, lastWord = '', strmatch(name, '.+%s(.+)$')
    if lastWord then
        for word in gmatch(name, '.-%s') do
            local firstLetter = utf8sub(gsub(word, '^[%s%p]*', ''), 1, 1)
            if firstLetter ~= utf8lower(firstLetter) then
                letters = format('%s%s. ', letters, firstLetter)
            end
        end
        name = format('%s%s', letters, lastWord)
    end
    return name
end

-- Add custom tags below

ElvUF.Tags.Events["name:abbrev"] = "UNIT_NAME_UPDATE"
ElvUF.Tags.Methods["name:abbrev"] = function(unit)
    local name = UnitName(unit)
    name = abbrev(name)

    if name and name:find(" ") then
        name = abbrev(name)
    end

    --The value 20 controls how many characters are allowed in the name before it gets truncated. Change it to fit your needs.
    return name ~= nil and E:ShortenString(name, 20) or ""
end

ElvUF.Tags.Events["num:targeting"] = "UNIT_TARGET PLAYER_TARGET_CHANGED GROUP_ROSTER_UPDATE"
ElvUF.Tags.Methods["num:targeting"] = function(unit)
    if not IsInGroup() then return "" end
    local targetedByNum = 0

    --Count the amount of other people targeting the unit
    for i = 1, GetNumGroupMembers() do
        local groupUnit = (IsInRaid() and "raid"..i or "party"..i);
        if (UnitIsUnit(groupUnit.."target", unit) and not UnitIsUnit(groupUnit, "player")) then
            targetedByNum = targetedByNum + 1
        end
    end

    --Add 1 if we"re targeting the unit too
    if UnitIsUnit("playertarget", unit) then
        targetedByNum = targetedByNum + 1
    end

    return (targetedByNum > 0 and targetedByNum or "")
end

ElvUF.Tags.Methods["classcolor:player"] = function()
    local _, unitClass = UnitClass("player")
    local String

    if unitClass then
        String = Hex(_COLORS.class[unitClass])
    else
        String = "|cFFC2C2C2"
    end

    return String
end

ElvUF.Tags.Methods["classcolor:hunter"] = function()
    return Hex(_COLORS.class["HUNTER"])
end

ElvUF.Tags.Methods["classcolor:warrior"] = function()
    return Hex(_COLORS.class["WARRIOR"])
end

ElvUF.Tags.Methods["classcolor:paladin"] = function()
    return Hex(_COLORS.class["PALADIN"])
end

ElvUF.Tags.Methods["classcolor:mage"] = function()
    return Hex(_COLORS.class["MAGE"])
end

ElvUF.Tags.Methods["classcolor:priest"] = function()
    return Hex(_COLORS.class["PRIEST"])
end

ElvUF.Tags.Methods["classcolor:warlock"] = function()
    return Hex(_COLORS.class["WARLOCK"])
end

ElvUF.Tags.Methods["classcolor:shaman"] = function()
    return Hex(_COLORS.class["SHAMAN"])
end

ElvUF.Tags.Methods["classcolor:deathknight"] = function()
    return Hex(_COLORS.class["DEATHKNIGHT"])
end

ElvUF.Tags.Methods["classcolor:demonhunter"] = function()
    return Hex(_COLORS.class["DEMONHUNTER"])
end

ElvUF.Tags.Methods["classcolor:druid"] = function()
    return Hex(_COLORS.class["DRUID"])
end

ElvUF.Tags.Methods["classcolor:monk"] = function()
    return Hex(_COLORS.class["MONK"])
end

ElvUF.Tags.Methods["classcolor:rogue"] = function()
    return Hex(_COLORS.class["ROGUE"])
end

ElvUF.Tags.Methods["classcolor:dk"] = function()
    return Hex(_COLORS.class["DEATHKNIGHT"])
end

ElvUF.Tags.Methods["classcolor:dh"] = function()
    return Hex(_COLORS.class["DEMONHUNTER"])
end


-- 取消百分号
-- 血量 100
ElvUF.Tags.Events["health:percent-nosymbol"] = "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH UNIT_CONNECTION"
ElvUF.Tags.Methods["health:percent-nosymbol"] = function(unit)
    local min, max = UnitHealth(unit), UnitHealthMax(unit)
    local deficit = max - min
    local String

    if UnitIsDead(unit) then
        String = L["Dead"]
    elseif UnitIsGhost(unit) then
        String = L["Ghost"]
    elseif not UnitIsConnected(unit) then
        String = L["Offline"]
    else
        String = GetFormattedText(min, max, "PERCENT_NO_SYMBOL", true)
    end

    return String
end
-- 血量 100 无状态提示
ElvUF.Tags.Events["health:percent-nosymbol-nostatus"] = "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH UNIT_CONNECTION"
ElvUF.Tags.Methods["health:percent-nosymbol-nostatus"] = function(unit)
    local min, max = UnitHealth(unit), UnitHealthMax(unit)
    local deficit = max - min
    local String

    if UnitIsDead(unit) then
        String = "0"
    elseif UnitIsGhost(unit) then
        String = "0"
    elseif not UnitIsConnected(unit) then
        String = "-"
    else
        String = GetFormattedText(min, max, "PERCENT_NO_SYMBOL", true)
    end

    return String
end

-- 取消小数点
-- 血量 100%
ElvUF.Tags.Events["health:percent-short"] = "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH UNIT_CONNECTION"
ElvUF.Tags.Methods["health:percent-short"] = function(unit)
    local min, max = UnitHealth(unit), UnitHealthMax(unit)
    local deficit = max - min
    local String

    if UnitIsDead(unit) then
        String = L["Dead"]
    elseif UnitIsGhost(unit) then
        String = L["Ghost"]
    elseif not UnitIsConnected(unit) then
        String = L["Offline"]
    else
        String = GetFormattedText(min, max, "PERCENT", true)
    end

    return String
end

-- 血量 100% 无状态提示
ElvUF.Tags.Events["health:percent-short-nostatus"] = "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH UNIT_CONNECTION"
ElvUF.Tags.Methods["health:percent-short-nostatus"] = function(unit)
    local min, max = UnitHealth(unit), UnitHealthMax(unit)
    local deficit = max - min
    local String

    if UnitIsDead(unit) then
        String = "0%"
    elseif UnitIsGhost(unit) then
        String = "0%"
    elseif not UnitIsConnected(unit) then
        String = "-"
    else
        String = GetFormattedText(min, max, "PERCENT", true)
    end

    return String
end

-- 血量 120 - 100%
ElvUF.Tags.Events["health:current-percent-short"] = "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH"
ElvUF.Tags.Methods["health:current-percent-short"] = function(unit)
    local min, max = UnitHealth(unit), UnitHealthMax(unit)
    local deficit = max - min
    local String

    if UnitIsDead(unit) then
        String = L["Dead"]
    elseif UnitIsGhost(unit) then
        String = L["Ghost"]
    elseif not UnitIsConnected(unit) then
        String = L["Offline"]
    else
        String = GetFormattedText(min, max, "CURRENT_PERCENT", true)
    end

    return String
end

-- 血量 120 - 100% 无状态提示
ElvUF.Tags.Events["health:current-percent-short-nostatus"] = "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH"
ElvUF.Tags.Methods["health:current-percent-short-nostatus"] = function(unit)
    local min, max = UnitHealth(unit), UnitHealthMax(unit)
    local deficit = max - min
    local String

    if UnitIsDead(unit) then
        String = "0 - 0%"
    elseif UnitIsGhost(unit) then
        String = "0 - 0%"
    elseif not UnitIsConnected(unit) then
        String = "-"
    else
        String = GetFormattedText(min, max, "CURRENT_PERCENT", true)
    end

    return String
end

-- 能量 120 - 100%
ElvUF.Tags.Events["power:current-percent-short"] = "UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT UNIT_MAXPOWER"
ElvUF.Tags.Methods["power:current-percent-short"] = function(unit)
    local pType = UnitPowerType(unit)
    local min, max = UnitPower(unit, pType), UnitPowerMax(unit, pType)
    local String = GetFormattedText(min, max, "CURRENT_PERCENT", true)
    return String
end
-- 能量 100
ElvUF.Tags.Events["power:percent-nosymbol"] = "UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT UNIT_MAXPOWER"
ElvUF.Tags.Methods["power:percent-nosymbol"] = function(unit)
    local pType = UnitPowerType(unit)
    local min, max = UnitPower(unit, pType), UnitPowerMax(unit, pType)
    local String = GetFormattedText(min, max, "PERCENT_NO_SYMBOL", true)
    return String
end
-- 能量 100%
ElvUF.Tags.Events["power:percent-short"] = "UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT UNIT_MAXPOWER"
ElvUF.Tags.Methods["power:percent-short"] = function(unit)
    local pType = UnitPowerType(unit)
    local min, max = UnitPower(unit, pType), UnitPowerMax(unit, pType)
    local String = GetFormattedText(min, max, "PERCENT", true)
    return String
end

-- 距离
ElvUF.Tags.Methods["range"] = function(unit)
    if not unit then return end
    local min, max = RC:GetRange(unit)
    local String = format("%s - %s", min, max)
    return String
end

ElvUF.Tags.Methods["range:expect"] = function(unit)
    if not unit then return end
    local min, max = RC:GetRange(unit)
    local String = format("%s", floor((min+max)/2))
    return String
end
