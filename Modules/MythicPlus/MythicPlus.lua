local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local MP = R:NewModule('MythicPlus', 'AceEvent-3.0', 'AceHook-3.0')

-- Lua functions

-- WoW API / Variables

local bossOffset = {
    [369] = { -- Operation: Mechagon - Junkyard
        startOffset = 1,
        endOffset = 4,
    },
    [370] = { -- Operation: Mechagon - Workshop
        startOffset = 5,
        endOffset = 8,
    },
}

function MP:FormatTime(seconds, tryNoMinute, showMS, alwaysPrefix, showColor)
    local prefix = alwaysPrefix and '+' or ''
    if seconds < 0 then
        prefix = '-'
        seconds = -seconds
    end

    local result
    if not tryNoMinute or seconds >= 60 then
        local minute = floor(seconds / 60)
        local second = showMS and (floor((seconds % 60) * 1000) / 1000) or floor(seconds % 60)
        result = (minute > 9 and minute or ('0' .. minute)) .. ':' .. (second < 10 and ('0' .. second) or second)
    else
        result = (showMS and (floor(seconds * 1000) / 1000) or floor(seconds)) .. 's'
    end

    result = prefix .. result
    if showColor then
        result = (prefix == '-' and '|cFF00FF00' or '|cFFFF0000') .. result .. '|r'
    end
    return result
end

function MP:GetElapsedTime()
    if not self.currentRun then return end

    if self.currentRun.usedTime then
        return self.currentRun.usedTime
    elseif self.currentRun.startTime then
        return GetTime() - self.currentRun.startTime + self.currentRun.timeLost
    else
        return select(2, GetWorldElapsedTime(1))
    end
end

function MP:StartTestMP()
    self.inTestMP = true

    local mapID, uiMapID = 369, 1490 -- Operation: Mechagon - Junkyard
    local mapName, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapID)
    self.currentRun = {
        inProgress = true,
        level = 30,
        affixes = {10, 11, 3, 120},
        mapID = mapID,
        mapName = mapName,
        uiMapID = uiMapID,

        timeLimit = timeLimit,
        timeLimit2 = timeLimit * .8,
        timeLimit3 = timeLimit * .6,

        numDeaths = 4,
        timeLost = 20,
        enemyCurrent = 217,
        enemyTotal = 398,

        startTime = GetTime() - 20 * 60,
        bossName = {},
        bossStatus = {true, nil, true, nil},
        bossTime = {156, nil, 587, nil},
    }

    self:FetchBossName()
    self:UpdateTimer()
end

function MP:EndTestMP()
    self.inTestMP = nil

    self.currentRun.inProgress = false
    self.currentRun.usedTime = self:GetElapsedTime()

    R:Print(
        "已完成+%d的%s，完成时间：%s%s/%s%s，三箱：%s，两箱：%s，一箱：%s。",
        self.currentRun.level, self.currentRun.mapName,
        self.currentRun.usedTime < self.currentRun.timeLimit and "|cFF00FF00" or "|cFFFF0000",
        self:FormatTime(self.currentRun.usedTime, nil, true),
        self:FormatTime(self.currentRun.timeLimit), "|r",
        self:FormatTime(self.currentRun.usedTime - self.currentRun.timeLimit3, nil, true, true, true),
        self:FormatTime(self.currentRun.usedTime - self.currentRun.timeLimit2, nil, true, true, true),
        self:FormatTime(self.currentRun.usedTime - self.currentRun.timeLimit, nil, true, true, true)
    )

    self:UpdateTimer()
end

function MP:FetchBossName()
    if not self.currentRun or not self.currentRun.uiMapID then return end
    if not IsAddOnLoaded('Blizzard_EncounterJournal') then
        self:RegisterEvent('ADDON_LOADED')
        LoadAddOn('Blizzard_EncounterJournal')
        return
    end

    wipe(self.currentRun.bossName)

    local startOffset = 1
    local endOffset = 5
    if bossOffset[self.currentRun.mapID] then
        startOffset = bossOffset[self.currentRun.mapID].startOffset
        endOffset = bossOffset[self.currentRun.mapID].endOffset
    end

    EncounterJournal_OpenJournal()
    if E.mylevel == 120 or E.mylevel == 50 then
        EJ_SelectTier(8)
    elseif level == 60 then
        EJ_SelectTier(9)
    end
    local instanceID = EJ_GetInstanceForMap(self.currentRun.uiMapID)
    EJ_SelectInstance(instanceID)
    for i = startOffset, endOffset do
        local name = EJ_GetEncounterInfoByIndex(i, instanceID)
        if not name then break end

        self.currentRun.bossName[i - startOffset + 1] = name
    end
    HideUIPanel(_G.EncounterJournal)
end

function MP:ADDON_LOADED(_, addonName)
    if addonName == 'Blizzard_EncounterJournal' then
        self:UnregisterEvent('ADDON_LOADED')
        self:FetchBossName()
        self:UpdateTimer()
    end
end

function MP:CHALLENGE_MODE_COMPLETED()
    local usedTime = select(3, C_ChallengeMode.GetCompletionInfo())
    if usedTime ~= 0 then
        self.currentRun.inProgress = false
        self.currentRun.usedTime = usedTime / 1000

        R:Print(
            "已完成+%d的%s，完成时间：%s%s/%s%s，三箱：%s，两箱：%s，一箱：%s。",
            self.currentRun.level, self.currentRun.mapName,
            self.currentRun.usedTime < self.currentRun.timeLimit and "|cFF00FF00" or "|cFFFF0000",
            self:FormatTime(self.currentRun.usedTime, nil, true),
            self:FormatTime(self.currentRun.timeLimit), "|r",
            self:FormatTime(self.currentRun.usedTime - self.currentRun.timeLimit3, nil, true, true, true),
            self:FormatTime(self.currentRun.usedTime - self.currentRun.timeLimit2, nil, true, true, true),
            self:FormatTime(self.currentRun.usedTime - self.currentRun.timeLimit, nil, true, true, true)
        )

        self:UpdateTimer()
    end
end

function MP:CHALLENGE_MODE_DEATH_COUNT_UPDATED()
    local numDeaths, timeLost = C_ChallengeMode.GetDeathCount()
    self.currentRun.numDeaths = numDeaths
    if self:GetElapsedTime() < self.currentRun.timeLimit then
        -- only lost time while in time
        self.currentRun.timeLost = timeLost
    end

    self:UpdateTimer()
end

function MP:SCENARIO_CRITERIA_UPDATE()
    for index in ipairs(self.currentRun.bossName) do
        local completed = select(3, C_Scenario.GetCriteriaInfo(index))
        if completed and not self.currentRun.bossStatus[index] then
            self.currentRun.bossStatus[index] = true
            self.currentRun.bossTime[index] = self:GetElapsedTime()
        end
    end

    self:UpdateTimer()
end

function MP:SCENARIO_POI_UPDATE()
    local steps = select(3, C_Scenario.GetStepInfo())
    if not steps or steps == 0 then return end

    local totalQuantity, _, _, quantityString = select(5, C_Scenario.GetCriteriaInfo(steps))
    if quantityString then
        local current = tonumber(strsub(quantityString, 1, -2)) or 0
        if current then
            self.currentRun.enemyCurrent = current
            self.currentRun.enemyTotal = totalQuantity

            if current >= totalQuantity and not self.currentRun.enemyTime then
                self.currentRun.enemyTime = self:GetElapsedTime()
            end

            self:UpdateTimer()
        end
    end
end

function MP:WORLD_STATE_TIMER_START()
    if not self.currentRun then return end

    if select(2, GetWorldElapsedTime(1)) < 2 then
        self.currentRun.startTime = GetTime()
    end

    self:UpdateTimer()
end

function MP:CHALLENGE_MODE_START()
    local level, affixes = C_ChallengeMode.GetActiveKeystoneInfo()
    local mapID = C_ChallengeMode.GetActiveChallengeMapID()
    local mapName, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapID)
    local numDeaths, timeLost = C_ChallengeMode.GetDeathCount()

    self.currentRun = {
        inProgress = true,
        level = level,
        affixes = affixes,
        mapID = mapID,
        mapName = mapName,
        uiMapID = E.MapInfo.mapID,

        timeLimit = timeLimit,
        timeLimit2 = timeLimit * .8,
        timeLimit3 = timeLimit * .6,

        numDeaths = numDeaths,
        timeLost = timeLost,
        enemyCurrent = 0,
        enemyTotal = 0,

        bossName = {},
        bossStatus = {},
        bossTime = {},
    }

    self:RegisterEvent('WORLD_STATE_TIMER_START')
    self:RegisterEvent('SCENARIO_POI_UPDATE')
    self:RegisterEvent('SCENARIO_CRITERIA_UPDATE')
    self:RegisterEvent('CHALLENGE_MODE_DEATH_COUNT_UPDATED')
    self:RegisterEvent('CHALLENGE_MODE_COMPLETED')

    self:FetchBossName()
    self:UpdateTimer()
end

function MP:PLAYER_ENTERING_WORLD()
    if not C_ChallengeMode.IsChallengeModeActive() then
        self:UnregisterEvent('WORLD_STATE_TIMER_START')
        self:UnregisterEvent('SCENARIO_POI_UPDATE')
        self:UnregisterEvent('SCENARIO_CRITERIA_UPDATE')
        self:UnregisterEvent('CHALLENGE_MODE_DEATH_COUNT_UPDATED')
        self:UnregisterEvent('CHALLENGE_MODE_COMPLETED')

        self.currentRun = nil

        self:HideTimer()
        return
    end

    self:WORLD_STATE_TIMER_START()
end

function MP:Initialize()
    LoadAddOn('Blizzard_EncounterJournal')

    self:BuildTimer()
    self:BuildTooltip()

    self:RegisterEvent('CHALLENGE_MODE_START')
    self:RegisterEvent('PLAYER_ENTERING_WORLD')
end

R:RegisterModule(MP:GetName())
