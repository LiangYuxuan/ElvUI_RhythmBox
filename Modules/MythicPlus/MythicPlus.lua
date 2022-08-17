-- This module is designed based on WeakAuras M+Timer (https://wago.io/M+Timer) by Reloe
-- Feature Keystone Announce and Affix Rotation is from AngryKeystones
-- And inspired by GottaGoFast and RUI

local R, E, L, V, P, G = unpack(select(2, ...))
local MP = R:NewModule('MythicPlus', 'AceEvent-3.0', 'AceHook-3.0', 'AceTimer-3.0')

-- Lua functions
local _G = _G
local bit_band = bit.band
local gsub, ipairs, floor, pairs, select, strsplit = gsub, ipairs, floor, pairs, select, strsplit
local strsub, tonumber, tinsert, type, unpack, wipe = strsub, tonumber, tinsert, type, unpack, wipe

-- WoW API / Variables
local C_ChallengeMode_GetActiveChallengeMapID = C_ChallengeMode.GetActiveChallengeMapID
local C_ChallengeMode_GetActiveKeystoneInfo = C_ChallengeMode.GetActiveKeystoneInfo
local C_ChallengeMode_GetCompletionInfo = C_ChallengeMode.GetCompletionInfo
local C_ChallengeMode_GetDeathCount = C_ChallengeMode.GetDeathCount
local C_ChallengeMode_GetMapUIInfo = C_ChallengeMode.GetMapUIInfo
local C_ChallengeMode_IsChallengeModeActive = C_ChallengeMode.IsChallengeModeActive
local C_ChatInfo_RegisterAddonMessagePrefix = C_ChatInfo.RegisterAddonMessagePrefix
local C_ChatInfo_SendAddonMessage = C_ChatInfo.SendAddonMessage
local C_Map_GetBestMapForUnit = C_Map.GetBestMapForUnit
local C_MythicPlus_RequestCurrentAffixes = C_MythicPlus.RequestCurrentAffixes
local C_MythicPlus_RequestMapInfo = C_MythicPlus.RequestMapInfo
local C_MythicPlus_RequestRewards = C_MythicPlus.RequestRewards
local C_Scenario_GetCriteriaInfo = C_Scenario.GetCriteriaInfo
local C_Scenario_GetStepInfo = C_Scenario.GetStepInfo
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local GetTime = GetTime
local GetWorldElapsedTime = GetWorldElapsedTime
local EJ_GetEncounterInfoByIndex = EJ_GetEncounterInfoByIndex
local EJ_GetInstanceForMap = EJ_GetInstanceForMap
local EJ_SelectInstance = EJ_SelectInstance
local EJ_SelectTier = EJ_SelectTier
local InCombatLockdown = InCombatLockdown
local LoadAddOn = LoadAddOn
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitIsFeignDeath = UnitIsFeignDeath
local UnitIsVisible = UnitIsVisible

local tContains = tContains

local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER

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
        startOffset = 3,
        endOffset = 6,
    },
    [234] = { -- Return to Karazhan: Upper
        startOffset = 7,
        endOffset = 10,
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
}

local mapToInstanceID = {
    [1686] = 1187, -- Theater of Pain
    [1692] = 1186, -- Spires of Ascension
    [1993] = 1194, -- Tazavesh
    [813]  = 860,  -- Return to Karazhan
    [814]  = 860,  -- Return to Karazhan
    [815]  = 860,  -- Return to Karazhan
}

local tormentedID = {
    [179446] = true, -- Incinerator Arkolath
    [179890] = true, -- Executioner Varruth
    [179891] = true, -- Soggodon the Breaker
    [179892] = true, -- Oros Coldheart
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
        isTeeming = nil,
        isTormented = true,
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
        tormented = {
            [179446] = true,
            [179892] = true,
        },
        tormentedCount = 2,
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

function MP:RefetchBossName()
    if not self.currentRun or not self.currentRun.uiMapID then return end

    self:FetchBossName()
    if #self.currentRun.bossName > 0 then
        self:SCENARIO_CRITERIA_UPDATE()
    end
end

function MP:FetchBossName()
    if not self.currentRun or not self.currentRun.uiMapID then return end

    wipe(self.currentRun.bossName)

    local startOffset = 1
    local endOffset = 5
    if bossOffset[self.currentRun.mapID] then
        startOffset = bossOffset[self.currentRun.mapID].startOffset
        endOffset = bossOffset[self.currentRun.mapID].endOffset
    end

    _G.EncounterJournal_OpenJournal()
    if _G.EncounterJournalBossButton1 then
        _G.EncounterJournalBossButton1:Click()
        _G.EncounterJournalNavBarHomeButton:Click()
    end
    EJ_SelectTier(9)
    _G.EncounterJournalInstanceSelectDungeonTab:Click()
    local instanceID = mapToInstanceID[self.currentRun.uiMapID] or EJ_GetInstanceForMap(self.currentRun.uiMapID)
    if instanceID == 0 then
        self.currentRun.uiMapID = C_Map_GetBestMapForUnit('player')
        instanceID = EJ_GetInstanceForMap(self.currentRun.uiMapID)
    end
    if instanceID and instanceID ~= 0 then
        EJ_SelectInstance(instanceID)
        for i = startOffset, endOffset do
            local name = EJ_GetEncounterInfoByIndex(i, instanceID)
            if not name then break end

            if self.currentRun.mapID == 227 and i == 3 then -- Return to Karazhan: Lower, Opera Hall
                name = gsub(name, '[:：].*', '')
            end

            self.currentRun.bossName[i - startOffset + 1] = name
        end
        if _G.EncounterJournalBossButton2 then
            _G.EncounterJournalBossButton2:Click()
            _G.EncounterJournalNavBarHomeButton:Click()
        end
        _G.EncounterJournalInstanceSelectDungeonTab:Click()
    else
        R.ErrorHandler("Unable to get encounter journal instance id on map " .. self.currentRun.uiMapID)
    end
    _G.EncounterJournal.CloseButton:Click()

    if #self.currentRun.bossName == 0 then
        self:ScheduleTimer('RefetchBossName', 1)
    end
end

do
    local currentPull = {}
    function MP:CheckPullAndDeath(event, ...)
        local subEvent, destGUID, destName, destFlags, _
        if event == 'COMBAT_LOG_EVENT_UNFILTERED' then
            _, subEvent, _, _, _, _, _, destGUID, destName, destFlags = CombatLogGetCurrentEventInfo()
            if subEvent ~= 'UNIT_DIED' or not destGUID then return end

            if destName and destFlags and bit_band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 then
                if UnitIsFeignDeath(destName) then
                    return
                elseif self.currentRun.playerDeath[destName] then
                    self.currentRun.playerDeath[destName] = self.currentRun.playerDeath[destName] + 1
                else
                    self.currentRun.playerDeath[destName] = 1
                end
                self.deathTable = nil
                return
            elseif self.currentRun.isTormented then
                local npcID = select(6, strsplit('-', destGUID))
                npcID = npcID and tonumber(npcID)

                if npcID and tormentedID[npcID] then
                    self.currentRun.tormented[npcID] = true
                    self.currentRun.tormentedCount = self.currentRun.tormentedCount + 1
                    if self.currentRun.tormentedCount >= 4 and not self.currentRun.tormentedTime then
                        self.currentRun.tormentedTime = self:GetElapsedTime()
                    end
                    C_ChatInfo_SendAddonMessage('RELOE_M+_SYNCH', 'Torments ' .. npcID, 'PARTY')
                    self:SendSignal('CHALLENGE_MODE_CRITERIA_UPDATE')
                end
            end
        end

        if not _G.MDT then return end

        if event == 'ENCOUNTER_END' or event == 'PLAYER_REGEN_ENABLED' or event == 'PLAYER_DEAD' then
            wipe(currentPull)
            self.currentRun.enemyPull = 0
            self:SendSignal('CHALLENGE_MODE_PULL_UPDATE')
            return
        elseif event == 'COMBAT_LOG_EVENT_UNFILTERED' then
            if not currentPull[destGUID] then return end
            currentPull[destGUID] = 'DEAD'
        elseif event == 'UNIT_THREAT_LIST_UPDATE' and InCombatLockdown() then
            local unitID = ...
            if not unitID or not UnitExists(unitID) then return end

            local unitGUID = UnitGUID(unitID)
            if not unitGUID or currentPull[unitGUID] then return end

            local npcID = R:ParseNPCID(unitGUID)
            if not npcID then return end

            local count, _, _, countTeeming = _G.MDT:GetEnemyForces(npcID)
            if not count then return end

            currentPull[unitGUID] = self.currentRun.isTeeming and countTeeming or count
        end

        self.currentRun.enemyPull = 0
        for _, value in pairs(currentPull) do
            if value ~= 'DEAD' then
                self.currentRun.enemyPull = self.currentRun.enemyPull + value
            end
        end
        self:SendSignal('CHALLENGE_MODE_PULL_UPDATE')
    end
end

function MP:CHALLENGE_MODE_COMPLETED()
    local usedTime = select(3, C_ChallengeMode_GetCompletionInfo())
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
        local completed = select(3, C_Scenario_GetCriteriaInfo(index))
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

    local totalQuantity, _, _, quantityString = select(5, C_Scenario_GetCriteriaInfo(numCriteria))
    if quantityString then
        local current = tonumber(strsub(quantityString, 1, -2)) or 0
        if current then
            self.currentRun.enemyCurrent = current
            self.currentRun.enemyTotal = totalQuantity

            if current >= totalQuantity and not self.currentRun.enemyTime then
                self.currentRun.enemyTime = self:GetElapsedTime()
            end

            self:SendSignal('CHALLENGE_MODE_POI_UPDATE')
        end
    end
end

function MP:WORLD_STATE_TIMER_START()
    if not self.currentRun then return end

    if select(2, GetWorldElapsedTime(1)) < 2 then
        self.currentRun.startTime = GetTime()
        self:SendSignal('CHALLENGE_MODE_TIMER_UPDATE')
    end
end

function MP:CHALLENGE_MODE_START()
    local level, affixes = C_ChallengeMode_GetActiveKeystoneInfo()
    local mapID = C_ChallengeMode_GetActiveChallengeMapID()
    local mapName, _, timeLimit = C_ChallengeMode_GetMapUIInfo(mapID)
    local numDeaths, timeLost = C_ChallengeMode_GetDeathCount()

    self.currentRun = {
        inProgress = true,
        level = level,
        affixes = affixes,
        isTeeming = tContains(affixes, 5),
        isTormented = tContains(affixes, 128),
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
        tormented = {},
        tormentedCount = 0,
    }

    self:RegisterEvent('WORLD_STATE_TIMER_START')
    self:RegisterEvent('SCENARIO_POI_UPDATE')
    self:RegisterEvent('SCENARIO_CRITERIA_UPDATE')
    self:RegisterEvent('CHALLENGE_MODE_DEATH_COUNT_UPDATED')
    self:RegisterEvent('CHALLENGE_MODE_COMPLETED')

    self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED', 'CheckPullAndDeath')
    self:RegisterEvent('UNIT_THREAT_LIST_UPDATE', 'CheckPullAndDeath')
    self:RegisterEvent('ENCOUNTER_START', 'CheckPullAndDeath')
    self:RegisterEvent('ENCOUNTER_END', 'CheckPullAndDeath')
    self:RegisterEvent('PLAYER_REGEN_ENABLED', 'CheckPullAndDeath')
    self:RegisterEvent('PLAYER_DEAD', 'CheckPullAndDeath')

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

        self:UnregisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
        self:UnregisterEvent('UNIT_THREAT_LIST_UPDATE')
        self:UnregisterEvent('ENCOUNTER_START')
        self:UnregisterEvent('ENCOUNTER_END')
        self:UnregisterEvent('PLAYER_REGEN_ENABLED')
        self:UnregisterEvent('PLAYER_DEAD')

        self.currentRun = nil

        self:SendSignal('CHALLENGE_MODE_LEAVE')
        return
    end

    if not self.currentRun then
        -- in case of d/c
        self:CHALLENGE_MODE_START()
        C_ChatInfo_SendAddonMessage('RELOE_M+_SYNCH', 'SYNCHPLS', 'PARTY')
    end
    self:WORLD_STATE_TIMER_START()
end

function MP:CHAT_MSG_ADDON(_, prefix, text, _, sender)
    if prefix == 'AngryKeystones' then
        self:SendSignal('CHAT_MSG_ADDON_ANGRY_KEYSTONES', text, sender)
        return
    end
    if prefix ~= 'RELOE_M+_SYNCH' or not self.currentRun then return end

    sender = gsub(sender, '%-[^|]+', '')
    if sender == E.myname or not UnitExists(sender) or not UnitIsVisible(sender) then return end

    if text == 'SYNCHPLS' then
        local replyText = ""
        local count = 0
        for index in pairs(self.currentRun.bossStatus) do
            if self.currentRun.bossTime[index] then
                replyText = replyText .. ' ' .. index .. self.currentRun.bossTime[index]
                    .. ((self.currentRun.bossTime[index] * 100) % 100)
                count = count + 1
            end
        end
        if self.currentRun.tormentedTime then
            local numCriteria = select(3, C_Scenario_GetStepInfo())
            if not numCriteria or numCriteria == 0 then
                numCriteria = #self.currentRun.bossName
            end
            replyText = replyText .. ' ' .. numCriteria .. self.currentRun.tormentedTime
                .. ((self.currentRun.tormentedTime * 100) % 100)
            count = count + 1
        end
        if count > 0 then
            replyText = count .. replyText
            C_ChatInfo_SendAddonMessage('RELOE_M+_SYNCH', replyText, 'PARTY')
        end
        if self.currentRun.isTormented then
            for npcID, status in pairs(self.currentRun.tormented) do
                if status then
                    C_ChatInfo_SendAddonMessage('RELOE_M+_SYNCH', 'Torments ' .. npcID, 'PARTY')
                end
            end
        end
    else
        local textSplit = {strsplit(' ', text)}
        if textSplit[1] == 'Obelisk' then return end

        if textSplit[1] == 'Torments' then
            local npcID = textSplit[2] and tonumber(textSplit[2])
            if not npcID then return end

            if tormentedID[npcID] and not self.currentRun.tormented[npcID] then
                self.currentRun.tormented[npcID] = true
                self.currentRun.tormentedCount = self.currentRun.tormentedCount + 1
                if self.currentRun.tormentedCount >= 4 and not self.currentRun.tormentedTime then
                    self.currentRun.tormentedTime = self:GetElapsedTime()
                end
                self:SendSignal('CHALLENGE_MODE_CRITERIA_UPDATE')
            end
            return
        end

        self:SCENARIO_CRITERIA_UPDATE() -- update boss killing status

        local count = textSplit[1] and tonumber(textSplit[1])
        if not count then return end

        local numCriteria = select(3, C_Scenario_GetStepInfo())
        if not numCriteria or numCriteria == 0 then
            numCriteria = #self.currentRun.bossName
        end
        local haveUpdate
        for i = 1, count do
            local index, newTime, newMS = unpack(textSplit, 3 * i - 1, 3 * i + 1)
            index = index and tonumber(index)
            newTime = newTime and tonumber(newTime)
            newMS = newMS and tonumber(newMS)
            if index and newTime and newMS then
                if floor(newTime) == newTime then
                    newTime = newTime + newMS / 100
                end
                if index <= numCriteria then
                    -- boss
                    if not self.currentRun.bossTime[index] or self.currentRun.bossTime[index] > newTime then
                        self.currentRun.bossTime[index] = newTime
                        haveUpdate = true
                    end
                elseif index == numCriteria + 1 then
                    -- tormented
                    if not self.currentRun.tormentedTime or self.currentRun.tormentedTime > newTime then
                        self.currentRun.tormentedTime = newTime
                        haveUpdate = true
                    end
                end
            end
        end
        if haveUpdate then
            self:SendSignal('CHALLENGE_MODE_CRITERIA_UPDATE')
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
    LoadAddOn('Blizzard_EncounterJournal')
    C_ChatInfo_RegisterAddonMessagePrefix('RELOE_M+_SYNCH')

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

    self:RegisterEvent('PLAYER_ENTERING_WORLD')
    self:RegisterEvent('CHALLENGE_MODE_START')
    self:RegisterEvent('CHAT_MSG_ADDON')
end

R:RegisterModule(MP:GetName())
