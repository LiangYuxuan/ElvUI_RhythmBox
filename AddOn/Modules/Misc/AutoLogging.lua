local R, E, L, V, P, G = unpack((select(2, ...)))
local AL = R:NewModule('AutoLogging', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions
local ipairs = ipairs

-- WoW API / Variables
local C_ChallengeMode_GetMapTable = C_ChallengeMode.GetMapTable
local GetInstanceInfo = GetInstanceInfo
local LoggingCombat = LoggingCombat
local SetCVar = SetCVar

local instances = {
    ---AUTO_GENERATED LEADING AutoLogging
    -- Dungeons
    [2451] = true, -- Uldaman: Legacy of Tyr
    [2515] = true, -- The Azure Vault
    [2516] = true, -- The Nokhud Offensive
    [2519] = true, -- Neltharus
    [2520] = true, -- Brackenhide Hollow
    [2521] = true, -- Ruby Life Pools
    [2526] = true, -- Algeth'ar Academy
    [2527] = true, -- Halls of Infusion
    [2579] = true, -- Dawn of the Infinite
    [2648] = true, -- The Rookery
    [2649] = true, -- Priory of the Sacred Flame
    [2651] = true, -- Darkflame Cleft
    [2652] = true, -- The Stonevault
    [2660] = true, -- Ara-Kara, City of Echoes
    [2661] = true, -- Cinderbrew Meadery
    [2662] = true, -- The Dawnbreaker
    [2669] = true, -- City of Threads
    [2773] = true, -- Operation: Floodgate
    -- Raids
    [2522] = true, -- Vault of the Incarnates
    [2549] = true, -- Amirdrassil, the Dream's Hope
    [2569] = true, -- Aberrus, the Shadowed Crucible
    [2657] = true, -- Nerub-ar Palace
    [2769] = true, -- Liberation of Undermine
    ---AUTO_GENERATED TAILING AutoLogging
}

function AL:DelayedStopLogging()
    LoggingCombat(false)
    R:Print("停止记录战斗日志")

    self.timer = nil
end

function AL:IsShouldLogging()
    local _, instanceType, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
    if (
        instanceType == 'raid' and instances[instanceID] and
        (difficultyID == 14 or difficultyID == 15 or difficultyID == 16)
    ) then
        return true
    elseif (
        instanceType == 'party' and instances[instanceID] and
        (difficultyID == 8 or difficultyID == 23)
    ) then
        return true, difficultyID == 8
    end
end

function AL:UpdateLogging(event, ...)
    if event == 'PLAYER_ENTERING_WORLD' then
        local isInitialLogin, isReloadingUi = ...
        if not isInitialLogin and not isReloadingUi then
            return
        end
    end

    local isActive = LoggingCombat()
    local shouldLogging, isInstanceMP = self:IsShouldLogging()

    if shouldLogging then
        if self.timer then
            self:CancelTimer(self.timer)
            self.timer = nil
        end

        if not isActive then
            LoggingCombat(true)
            R:Print("开始记录战斗日志")
        end
    elseif isActive then
        -- if last instance is mythic+ and completed, don't delay stop logging
        if not self.isInstanceMP or self.isInstanceMPCompleted then
            if self.timer then
                self:CancelTimer(self.timer)
                self.timer = nil
            end

            LoggingCombat(false)
            R:Print("停止记录战斗日志")
        elseif not self.timer then
            self.timer = self:ScheduleTimer('DelayedStopLogging', 20)
        end
    end

    self.isInstanceMP = isInstanceMP
    self.isInstanceMPCompleted = false
end

function AL:CHALLENGE_MODE_COMPLETED()
    self.isInstanceMPCompleted = true
end

function AL:Initialize()
    SetCVar('advancedCombatLogging', '1')

    local database = R:GetModule('MythicPlus').database
    local mapChallengeModeIDs = C_ChallengeMode_GetMapTable()
    for _, mapChallengeModeID in ipairs(mapChallengeModeIDs) do
        local instanceID = database[mapChallengeModeID][1]
        instances[instanceID] = true
    end

    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateLogging')
    self:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'UpdateLogging')
    self:RegisterEvent('CHALLENGE_MODE_START', 'UpdateLogging')
    self:RegisterEvent('CHALLENGE_MODE_COMPLETED')
end

R:RegisterModule(AL:GetName())
