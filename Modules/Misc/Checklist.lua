local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local C = R:NewModule('Checklist', 'AceEvent-3.0')
local StdUi = LibStub('StdUi')

-- Lua functions
local format, ipairs, loadstring, pairs, pcall = format, ipairs, loadstring, pairs, pcall
local tinsert, type, unpack = tinsert, type, unpack

-- WoW API / Variables
local C_QuestLog_GetTitleForQuestID = C_QuestLog.GetTitleForQuestID
local C_TaskQuest_GetQuestsForPlayerByMapID = C_TaskQuest.GetQuestsForPlayerByMapID
local C_TaskQuest_GetQuestTimeLeftMinutes = C_TaskQuest.GetQuestTimeLeftMinutes
local GetQuestResetTime = GetQuestResetTime
local SecondsToTime = SecondsToTime

local COMPLETE = COMPLETE
local INCOMPLETE = INCOMPLETE

local function SafeFetchExpression(expression)
    local func, err = loadstring('return ' .. expression)
    if not err then
        local status, result = pcall(func)
        return status and result
    end
end

local checks = {
    {
        name = "大使任务",
        event = {
            ['QUEST_TURNED_IN'] = true,
        },
        character = {
            ['死亡之翼'] = {
                '大只小萌德',
            },
        },
        func = function(data, fullName)
            local cache = SafeFetchExpression('SavedInstances[1].db.Emissary.Cache')
            local emissary = SafeFetchExpression('SavedInstances[1].db.Emissary.Expansion[7]')
            local days = SafeFetchExpression(format('SavedInstances[1].db.Toons["%s"].Emissary[7].days', fullName))
            if not emissary then return end

            local result = {}
            for index, questData in ipairs(emissary) do
                if (
                    questData.questID and questData.questID.Horde and
                    data.questIDs[questData.questID.Horde]
                ) then
                    tinsert(result, {
                        days and days[index] and days[index].isComplete,
                        GetQuestResetTime() + 86400 * (index - 1),
                        cache[questData.questID.Horde] or "大使任务",
                    })
                end
            end

            if #result == 0 then
                return true
            elseif #result == 1 then
                local status, expirationTime, name = unpack(result[1])
                return status, expirationTime, name
            end
            return result
        end,

        questIDs = {
            [50602] = true, -- Talanji's Expedition
            [50603] = true, -- Voldunai
        },
    },
    {
        name = "噬渊日常",
        event = {
            ['QUEST_TURNED_IN'] = true,
        },
        character = {
            ['拉文凯斯'] = {
                '小只大萌德',
                '小只萌猎手',
                '卡登斯邃光',
                '小只污妖王',
            },
        },
        func = function(_, fullName)
            local quests = SafeFetchExpression(format('SavedInstances[1].db.Toons["%s"].Quests', fullName))
            if not quests then
                return false, GetQuestResetTime()
            end

            local count = 0
            for _, questData in pairs(quests) do
                if questData.isDaily and questData.Zone and questData.Zone.mapID and questData.Zone.mapID == 1543 then
                    count = count + 1
                end
            end

            return (count >= 3), GetQuestResetTime()
        end,
    },
    {
        name = "真菌枢纽日常",
        event = {
            ['QUEST_TURNED_IN'] = true,
        },
        character = {
            ['拉文凯斯'] = {
                '小只大萌德',
            },
        },
        func = function(_, fullName)
            local quests = SafeFetchExpression(format('SavedInstances[1].db.Toons["%s"].Quests', fullName))
            if not quests then
                return false, GetQuestResetTime()
            end

            local count = 0
            for _, questData in pairs(quests) do
                if questData.isDaily and questData.Zone and questData.Zone.mapID and questData.Zone.mapID == 1819 then
                    count = count + 1
                end
            end

            return (count >= 1), GetQuestResetTime()
        end,
    },
    {
        name = "世界任务",
        event = {
            ['QUEST_TURNED_IN'] = true,
        },
        character = true,
        func = function(data)
            local result = {}

            for uiMapID, targetQuests in pairs(data.questIDs) do
                local quests = C_TaskQuest_GetQuestsForPlayerByMapID(uiMapID)
                if quests then
                    for _, questData in pairs(quests) do
                        local questID = questData.questId
                        if questID and targetQuests[questID] then
                            tinsert(result, {
                                false, C_TaskQuest_GetQuestTimeLeftMinutes(questID) * 60,
                                C_QuestLog_GetTitleForQuestID(questID) or questID,
                            })
                        end
                    end
                end
            end

            if #result == 0 then
                return true
            elseif #result == 1 then
                local status, expirationTime, name = unpack(result[1])
                return status, expirationTime, name
            end
            return result
        end,

        questIDs = {
            [1533] = { -- Bastion
                [59717] = true, -- Things Remembered
                [60858] = true, -- Flight School: Up and Away!
                [60911] = true, -- Flight School: Flapping Frenzy
            },
            [1740] = { -- Ardenweald
                [60475] = true, -- We'll Workshop It
            },
            [1742] = { -- Revendreth
                [59643] = true, -- It's Race Day in the Ramparts!
                [59718] = true, -- Parasol Peril
            },
        },
    },
}

function C:BuildResult(data, characterName, status, expirationTime, title)
    return {
        questName = title or data.name,
        characterName = characterName,
        status = status,
        expirationTime = expirationTime,
        statusText = status and COMPLETE or INCOMPLETE,
        timeText = (not status and expirationTime) and SecondsToTime(expirationTime) or "",
    }
end

function C:ProcessCheck(result, characterName, data, fullName)
    local status, expirationTime, title = data.func(data, fullName)
    if type(status) == 'table' then
        for _, resultData in ipairs(status) do
            local status, expirationTime, title = unpack(resultData)
            tinsert(result, self:BuildResult(data, characterName, status, expirationTime, title))
        end
    else
        tinsert(result, self:BuildResult(data, characterName, status, expirationTime, title))
    end
end

function C:LoadChecklist()
    local result = {}

    for _, data in ipairs(checks) do
        if data.character == true then
            self:ProcessCheck(result, "", data)
        else
            for realmName, realmList in pairs(data.character) do
                for _, characterName in ipairs(realmList) do
                    self:ProcessCheck(result, characterName, data, characterName .. ' - ' .. realmName)
                end
            end
        end
    end

    self.checklistTable:SetData(result)
end

function C:BuildWindow()
    local window = StdUi:Window(E.UIParent, 550, 470, "Checklist")
    window:SetPoint("CENTER")
    window:SetScript('OnShow', function()
        C:LoadChecklist()
    end)

    local refreshButton = StdUi:Button(window, 100, 24, "刷新Checklist")
    StdUi:GlueTop(refreshButton, window, 0, -40)
    refreshButton:SetScript("OnClick", function()
        C:LoadChecklist()
    end)

    local cols = {
        {
            name   = "任务",
            width  = 200,
            align  = 'LEFT',
            index  = 'questName',
            format = 'string',
        },
        {
            name   = "角色",
            width  = 100,
            align  = 'LEFT',
            index  = 'characterName',
            format = 'string',
        },
        {
            name   = "状态",
            width  = 60,
            align  = 'CENTER',
            index  = 'statusText',
            format = 'string',
        },
        {
            name   = "剩余时间",
            width  = 120,
            align  = 'CENTER',
            index  = 'timeText',
            format = 'string'
        },
    }

    local st = StdUi:ScrollTable(window, cols, 14, 24)
    st:EnableSelection(true)
    StdUi:GlueTop(st, window, 0, -100)
    self.checklistTable = st

    R:ToolboxRegisterSubWindow(window, "Checklist")
end

function C:Initialize()
    self:BuildWindow()
end

R:RegisterModule(C:GetName())
