local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local AL = R:NewModule('AutoLogging', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions

-- WoW API / Variables
local GetInstanceInfo = GetInstanceInfo
local LoggingCombat = LoggingCombat

AL.dungeonList = {
    [1594] = true, -- The MOTHERLODE!!
    [1754] = true, -- Freehold
    [1762] = true, -- Kings' Rest
    [1763] = true, -- Atal'Dazar
    [1771] = true, -- Tol Dagor
    [1822] = true, -- Siege of Boralus
    [1841] = true, -- The Underrot
    [1862] = true, -- Waycrest Manor
    [1864] = true, -- Shrine of the Storm
    [1877] = true, -- Temple of Sethraliss
    [2097] = true, -- Operation: Mechagon
}

AL.raidList = {
    [1861] = true, -- Uldir
    [2070] = true, -- Battle of Dazar'alor
    [2096] = true, -- Crucible of Storms
    [2164] = true, -- The Eternal Palace
    [2217] = true, -- Ny'alotha
}

function AL:IsShouldLogging()
    local _, instanceType, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
    if (
        instanceType == 'raid' and self.raidList[instanceID] and
        (difficultyID == 14 or difficultyID == 15 or difficultyID == 16)
    ) then
        return true
    elseif (
        instanceType == 'party' and self.dungeonList[instanceID] and
        difficultyID == 8
    ) then
        return true
    end
end

function AL:UpdateLogging()
    if self:IsShouldLogging() then
        LoggingCombat(true)
        R:Print("开始记录战斗日志")
    elseif LoggingCombat() then
        LoggingCombat(false)
        R:Print("停止记录战斗日志")
    end
end

function AL:ZONE_CHANGED_NEW_AREA()
    self:ScheduleTimer('UpdateLogging', 2)
end

function AL:CHALLENGE_MODE_START()
    self:ScheduleTimer('UpdateLogging', 1)
end

function AL:Initialize()
    self:RegisterEvent('ZONE_CHANGED_NEW_AREA')
    self:RegisterEvent('CHALLENGE_MODE_START')

    self:ScheduleTimer('UpdateLogging', 2)
end

R:RegisterModule(AL:GetName())
