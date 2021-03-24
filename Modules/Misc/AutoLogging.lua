local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local AL = R:NewModule('AutoLogging', 'AceEvent-3.0')

-- Lua functions

-- WoW API / Variables
local GetInstanceInfo = GetInstanceInfo
local LoggingCombat = LoggingCombat
local SetCVar = SetCVar

AL.dungeonList = {
    [2284] = true, -- Sanguine Depths
    [2285] = true, -- Spires of Ascension
    [2286] = true, -- The Necrotic Wake
    [2287] = true, -- Halls of Atonement
    [2289] = true, -- Plaguefall
    [2290] = true, -- Mists of Tirna Scithe
    [2291] = true, -- De Other Side
    [2293] = true, -- Theater of Pain
}

AL.raidList = {
    [2296] = true, -- Castle Nathria
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
        (difficultyID == 8 or difficultyID == 23)
    ) then
        return true
    end
end

function AL:UpdateLogging()
    local isActive = LoggingCombat()
    local shouldLogging = self:IsShouldLogging()

    if not isActive and shouldLogging then
        LoggingCombat(true)
        R:Print("开始记录战斗日志")
    elseif isActive and not shouldLogging then
        LoggingCombat(false)
        R:Print("停止记录战斗日志")
    end
end

function AL:Initialize()
    SetCVar('advancedCombatLogging', 1)

    self:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'UpdateLogging')
    self:RegisterEvent('CHALLENGE_MODE_START', 'UpdateLogging')
    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateLogging')
end

R:RegisterModule(AL:GetName())
