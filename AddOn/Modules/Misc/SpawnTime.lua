local R, E, L, V, P, G = unpack((select(2, ...)))
local ST = R:NewModule('SpawnTime', 'AceEvent-3.0')

-- Lua functions
local _G = _G
local date, issecretvalue, select, strsplit, strsub, tonumber = date, issecretvalue, select, strsplit, strsub, tonumber
local bit_band = bit.band

-- WoW API / Variables
local GetServerTime = GetServerTime
local IsShiftKeyDown = IsShiftKeyDown
local UnitGUID = UnitGUID

local TooltipDataProcessor_AddTooltipPostCall = TooltipDataProcessor.AddTooltipPostCall

local Enum_TooltipDataType_Unit = Enum.TooltipDataType.Unit
local NORMAL_FONT_COLOR = NORMAL_FONT_COLOR

local function OnTooltipSetUnit(tooltip)
    if not IsShiftKeyDown() then return end

    if tooltip ~= _G.GameTooltip then return end
    if not tooltip or tooltip:IsForbidden() or not tooltip.NumLines or tooltip:NumLines() == 0 then return end

    local unitID = select(2, tooltip:GetUnit())
    if not unitID or issecretvalue(unitID) then return end

    local unitGUID = UnitGUID(unitID)
    if not unitGUID then return end

    local unitType, _, _, _, _, _, spawnUID = strsplit('-', unitGUID)
    if unitType == 'Creature' or unitType == 'Vehicle' then
        local serverTime = GetServerTime()
        local spawnEpoch = serverTime - (serverTime % 2^23)
        local spawnEpochOffset = bit_band(tonumber(strsub(spawnUID, 5), 16), 0x7fffff)
        -- local spawnIndex = bit.rshift(bit.band(tonumber(strsub(spawnUID, 1, 5), 16), 0xffff8), 3)
        local spawnTime = spawnEpoch + spawnEpochOffset

        if spawnTime > serverTime then
            -- This only occurs if the epoch has rolled over since a unit has spawned.
            spawnTime = spawnTime - ((2^23) - 1)
        end

        local serverTimeData = date('*t', serverTime)
        local spawnTimeData = date('*t', spawnTime)

        local spawnTimeText
        if serverTimeData.yday == spawnTimeData.yday then
            spawnTimeText = date('%H:%M:%S', spawnTime)
        elseif serverTimeData.year == spawnTimeData.year then
            spawnTimeText = date('%m-%d %H:%M:%S', spawnTime)
        else
            spawnTimeText = date('%Y-%m-%d %H:%M:%S', spawnTime)
        end

        local r, g, b = NORMAL_FONT_COLOR:GetRGB()
        tooltip:AddDoubleLine("生成时间", spawnTimeText, r, g, b, 1, 1, 1)
    end
end

function ST:Initialize()
    TooltipDataProcessor_AddTooltipPostCall(Enum_TooltipDataType_Unit, OnTooltipSetUnit)
end

R:RegisterModule(ST:GetName())
