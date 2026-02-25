-- This module is designed based on WeakAuras M+ Timer (https://wago.io/M+Timer) by Reloe
-- Features try to support multi addons
-- Keystone Announce
-- 1. Angry Keystones (send and receive)
-- 2. Open Raid Library (receive, send by itself)
-- 3. LibKeystone (receive, send by itself)
-- 4. Astral Keys (guild & friends only, not support as we only care party)
-- 5. Key Master (has build-in Open Raid Library fallback)

local R, E, L, V, P, G = unpack((select(2, ...)))
local MP = R:NewModule('MythicPlus', 'AceEvent-3.0', 'AceHook-3.0', 'AceTimer-3.0')

-- Lua functions
local ipairs, floor, select, strfind = ipairs, floor, select, strfind
local strmatch, tonumber, tinsert, type, wipe = strmatch, tonumber, tinsert, type, wipe

-- WoW API / Variables
local C_ChallengeMode_GetActiveChallengeMapID = C_ChallengeMode.GetActiveChallengeMapID
local C_ChallengeMode_GetActiveKeystoneInfo = C_ChallengeMode.GetActiveKeystoneInfo
local C_ChallengeMode_GetChallengeCompletionInfo = C_ChallengeMode.GetChallengeCompletionInfo
local C_ChallengeMode_GetDeathCount = C_ChallengeMode.GetDeathCount
local C_ChallengeMode_GetMapUIInfo = C_ChallengeMode.GetMapUIInfo
local C_ChallengeMode_IsChallengeModeActive = C_ChallengeMode.IsChallengeModeActive
local C_ChatInfo_RegisterAddonMessagePrefix = C_ChatInfo.RegisterAddonMessagePrefix
local C_Map_GetBestMapForUnit = C_Map.GetBestMapForUnit
local C_MythicPlus_RequestCurrentAffixes = C_MythicPlus.RequestCurrentAffixes
local C_MythicPlus_RequestMapInfo = C_MythicPlus.RequestMapInfo
local C_MythicPlus_RequestRewards = C_MythicPlus.RequestRewards
local C_Scenario_GetStepInfo = C_Scenario.GetStepInfo
local C_ScenarioInfo_GetCriteriaInfo = C_ScenarioInfo.GetCriteriaInfo
local GetLFGDungeonEncounterInfo = GetLFGDungeonEncounterInfo
local GetTime = GetTime
local GetWorldElapsedTime = GetWorldElapsedTime

MP.keystoneItemIDs = {
    [138019] = true, -- Legion
    [158923] = true, -- BfA
    [180653] = true, -- SL

    [187786] = true, -- Timeworn Keystone

    [151086] = true, -- Mythic Invitational Keystone
}

MP.currentKeystone = 180653

local bossOffset = {
    [227] = { -- Return to Karazhan: Lower
        startOffset = 1,
        endOffset = 4,
    },
    [234] = { -- Return to Karazhan: Upper
        startOffset = 5,
        endOffset = 8,
    },
    [353] = { -- Siege of Boralus
        startOffset = 2,
        endOffset = 5,
    },
    [369] = { -- Operation: Mechagon - Junkyard
        startOffset = 1,
        endOffset = 4,
    },
    [370] = { -- Operation: Mechagon - Workshop
        startOffset = 5,
        endOffset = 8,
    },
    [391] = { -- Tazavesh: Streets of Wonder
        startOffset = 1,
        endOffset = 5,
    },
    [392] = { -- Tazavesh: So'leah's Gambit
        startOffset = 6,
        endOffset = 8,
    },
    [463] = { -- Dawn of the Infinite: Galakrond's Fall
        startOffset = 1,
        endOffset = 4,
    },
    [464] = { -- Dawn of the Infinite: Murozond's Rise
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

    local mapID, uiMapID = 378, 1663 -- Halls of Atonement
    local mapName, _, timeLimit = C_ChallengeMode_GetMapUIInfo(mapID)
    self.currentRun = {
        inProgress = true,
        level = 40,
        affixes = {10, 11, 3, 128},
        mapID = mapID,
        mapName = mapName,
        uiMapID = uiMapID,

        timeLimit = timeLimit,
        timeLimit2 = timeLimit * .8,
        timeLimit3 = timeLimit * .6,

        numDeaths = 4,
        timeLost = 20,
        enemyCurrent = 217,
        enemyPull = 36,
        enemyTotal = 332,

        startTime = GetTime() - 20 * 60,
        bossName = {},
        bossStatus = {true, true, nil, nil},
        bossTime = {156, 587, nil, nil},
        playerDeath = {
            [E.myname] = 4,
        },
    }

    self:FetchBossName()
    self:SendSignal('CHALLENGE_MODE_START')
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

    self:SendSignal('CHALLENGE_MODE_COMPLETED')
end

function MP:FetchBossName()
    if not self.currentRun or not self.currentRun.mapID or not self.currentRun.uiMapID then return end

    wipe(self.currentRun.bossName)

    local startOffset = 1
    local endOffset = 5
    if bossOffset[self.currentRun.mapID] then
        startOffset = bossOffset[self.currentRun.mapID].startOffset
        endOffset = bossOffset[self.currentRun.mapID].endOffset
    end

    local LFGDungeonID = self.database[self.currentRun.mapID] and self.database[self.currentRun.mapID][2]
    if LFGDungeonID and self.currentRun.mapID ~= 209 then
        -- The Arcway has random boss order, so force to use scenario criteria

        for i = startOffset, endOffset do
            local name = GetLFGDungeonEncounterInfo(LFGDungeonID, i)
            if not name then return end

            self.currentRun.bossName[i - startOffset + 1] = name
        end
    else
        local numCriteria = select(3, C_Scenario_GetStepInfo())

        for index = 1, numCriteria - 1 do
            local data = C_ScenarioInfo_GetCriteriaInfo(index)
            local description = data and data.description
            if not description then return end

            self.currentRun.bossName[index] = description
        end
    end
end

function MP:CHALLENGE_MODE_COMPLETED()
    local info = C_ChallengeMode_GetChallengeCompletionInfo()
    local usedTime = info.time
    if usedTime ~= 0 then
        self.currentRun.inProgress = false
        self.currentRun.usedTime = usedTime / 1000

        self.currentRun.enemyCurrent = self.currentRun.enemyTotal

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

        self:SendSignal('CHALLENGE_MODE_POI_UPDATE')
        self:SendSignal('CHALLENGE_MODE_COMPLETED')
    end
end

function MP:CHALLENGE_MODE_DEATH_COUNT_UPDATED()
    local numDeaths, timeLost = C_ChallengeMode_GetDeathCount()
    self.currentRun.numDeaths = numDeaths
    if self:GetElapsedTime() < self.currentRun.timeLimit then
        -- only lost time while in time
        self.currentRun.timeLost = timeLost
    end

    self:SendSignal('CHALLENGE_MODE_DEATH_UPDATE')
end

function MP:SCENARIO_CRITERIA_UPDATE()
    local numCriteria = select(3, C_Scenario_GetStepInfo())
    if numCriteria - 1 > #self.currentRun.bossName then
        self:FetchBossName()
    end

    for index = 1, numCriteria - 1 do
        local data = C_ScenarioInfo_GetCriteriaInfo(index)
        local completed = data and data.completed
        if completed and not self.currentRun.bossStatus[index] then
            self.currentRun.bossStatus[index] = true
            if not self.currentRun.bossTime[index] then
                self.currentRun.bossTime[index] = self:GetElapsedTime()
            end
        end
    end

    self:SendSignal('CHALLENGE_MODE_CRITERIA_UPDATE')
end

function MP:SCENARIO_POI_UPDATE()
    local numCriteria = select(3, C_Scenario_GetStepInfo())
    if not numCriteria or numCriteria == 0 then return end

    local data = C_ScenarioInfo_GetCriteriaInfo(numCriteria)
    local quantityString = data.quantityString
    local totalQuantity = data.totalQuantity

    local quantity = tonumber(strmatch(quantityString, '%d+'))

    self.currentRun.enemyCurrent = quantity
    self.currentRun.enemyTotal = totalQuantity

    if quantity >= totalQuantity and not self.currentRun.enemyTime then
        self.currentRun.enemyTime = self:GetElapsedTime()
    end

    self:SendSignal('CHALLENGE_MODE_POI_UPDATE')
end

function MP:WORLD_STATE_TIMER_START()
    if not self.currentRun then return end

    if select(2, GetWorldElapsedTime(1)) < 2 then
        self.currentRun.startTime = GetTime()
        self:SendSignal('CHALLENGE_MODE_TIMER_UPDATE')
    end
end

function MP:CHALLENGE_MODE_START()
    local mapID = C_ChallengeMode_GetActiveChallengeMapID()
    ---@cast mapID number

    local level, affixes = C_ChallengeMode_GetActiveKeystoneInfo()
    local mapName, _, timeLimit = C_ChallengeMode_GetMapUIInfo(mapID)
    local numDeaths, timeLost = C_ChallengeMode_GetDeathCount()

    self.currentRun = {
        inProgress = true,
        level = level,
        affixes = affixes,
        mapID = mapID,
        mapName = mapName,
        uiMapID = C_Map_GetBestMapForUnit('player'),

        timeLimit = timeLimit,
        timeLimit2 = timeLimit * .8,
        timeLimit3 = timeLimit * .6,

        numDeaths = numDeaths,
        timeLost = timeLost,
        enemyCurrent = 0,
        enemyPull = 0,
        enemyTotal = 1,

        bossName = {},
        bossStatus = {},
        bossTime = {},
        playerDeath = {},
    }

    self:RegisterEvent('WORLD_STATE_TIMER_START')
    self:RegisterEvent('SCENARIO_POI_UPDATE')
    self:RegisterEvent('SCENARIO_CRITERIA_UPDATE')
    self:RegisterEvent('CHALLENGE_MODE_DEATH_COUNT_UPDATED')
    self:RegisterEvent('CHALLENGE_MODE_COMPLETED')

    self:FetchBossName()
    self:SendSignal('CHALLENGE_MODE_START')

    -- in case of d/c
    self:SCENARIO_CRITERIA_UPDATE()
    self:SCENARIO_POI_UPDATE()
end

function MP:PLAYER_ENTERING_WORLD()
    if not C_ChallengeMode_IsChallengeModeActive() then
        self:UnregisterEvent('WORLD_STATE_TIMER_START')
        self:UnregisterEvent('SCENARIO_POI_UPDATE')
        self:UnregisterEvent('SCENARIO_CRITERIA_UPDATE')
        self:UnregisterEvent('CHALLENGE_MODE_DEATH_COUNT_UPDATED')
        self:UnregisterEvent('CHALLENGE_MODE_COMPLETED')

        self.currentRun = nil

        self:SendSignal('CHALLENGE_MODE_LEAVE')
        return
    end

    if not self.currentRun then
        -- in case of d/c
        self:CHALLENGE_MODE_START()
    end
    self:WORLD_STATE_TIMER_START()
end

do
    local playerFullName = E.myname .. '-' .. E.myrealm

    function MP:CHAT_MSG_ADDON(_, prefix, text, _, sender)
        if not strfind(sender, '-') then
            sender = sender .. '-' .. E.myrealm
        end
        if sender == playerFullName then return end

        if prefix == 'AngryKeystones' then
            self:SendSignal('CHAT_MSG_ADDON_ANGRY_KEYSTONES', text, sender)
            return
        end
    end
end

do
    local eventPool = {}
    function MP:RegisterSignal(signalName, func)
        if type(func) ~= 'function' and not MP[func] then return end

        if not eventPool[signalName] then
            eventPool[signalName] = {}
        end

        tinsert(eventPool[signalName], func)
    end

    function MP:SendSignal(signalName, ...)
        if not eventPool[signalName] then return end

        for _, func in ipairs(eventPool[signalName]) do
            if type(func) == 'function' then
                func(signalName, ...)
            else
                MP[func](MP, signalName, ...)
            end
        end
    end
end

function MP:Initialize()
    C_ChatInfo_RegisterAddonMessagePrefix('WDP_TimerReq')
    C_ChatInfo_RegisterAddonMessagePrefix('WDP_TimerRes')
    C_ChatInfo_RegisterAddonMessagePrefix('WDP_ObjReq')
    C_ChatInfo_RegisterAddonMessagePrefix('WDP_ObjRes')

    E:Delay(3, function()
        C_MythicPlus_RequestCurrentAffixes()
        C_MythicPlus_RequestMapInfo()
        C_MythicPlus_RequestRewards()
    end)

    self:BuildAnnounce()
    self:BuildBoard()

    self:BuildTimer()
    self:BuildAutoReply()
    self:BuildUtility()
    self:BuildPortalName()

    self:RegisterEvent('PLAYER_ENTERING_WORLD')
    self:RegisterEvent('CHALLENGE_MODE_START')
    self:RegisterEvent('CHAT_MSG_ADDON')
end

R:RegisterModule(MP:GetName())
