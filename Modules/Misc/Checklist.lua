local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local C = R:NewModule('Checklist', 'AceEvent-3.0')
local StdUi = LibStub('StdUi')

-- Lua functions
local format, ipairs, loadstring, pairs, pcall = format, ipairs, loadstring, pairs, pcall
local tinsert, type, unpack = tinsert, type, unpack

-- WoW API / Variables
local C_DateAndTime_GetSecondsUntilWeeklyReset = C_DateAndTime.GetSecondsUntilWeeklyReset
local C_TaskQuest_GetQuestsForPlayerByMapID = C_TaskQuest.GetQuestsForPlayerByMapID
local C_TaskQuest_GetQuestTimeLeftMinutes = C_TaskQuest.GetQuestTimeLeftMinutes
local GetQuestResetTime = GetQuestResetTime
local SecondsToTime = SecondsToTime

local COMPLETE = COMPLETE
local INCOMPLETE = INCOMPLETE

-- BfA Compatible
if not R.Shadowlands then
    local date, time = date, time

    C_DateAndTime_GetSecondsUntilWeeklyReset = function()
        local now = time()
        local nextReset = GetQuestResetTime() + now
        while date('%w', nextReset) ~= '4' do
            nextReset = nextReset + 86400
        end
        return nextReset - now
    end
end

local function SafeFetchExpression(expression)
    local func, err = loadstring('return ' .. expression)
    if not err then
        local status, result = pcall(func)
        return status and result
    end
end

local checks = {
    {
        name = "马蒂瓦斯的实验室",
        event = {
            ['QUEST_TURNED_IN'] = true,
        },
        character = {
            ['拉文凯斯'] = {
                '小只大萌德',
            },
            ['死亡之翼'] = {
                '大只小萌德',
            },
        },
        func = function(_, fullName)
            return
                not not SafeFetchExpression(format('_G.SavedInstances.db.Toons["%s"].Quests[55121]', fullName)),
                C_DateAndTime_GetSecondsUntilWeeklyReset()
        end,
    },
    {
        name = "纳沙塔尔日常",
        event = {
            ['QUEST_TURNED_IN'] = true,
        },
        character = {
            ['拉文凯斯'] = {
                '卡登斯邃光',
            },
            ['死亡之翼'] = {
                '大只小萌德',
            },
        },
        func = function(_, fullName)
            local quests = SafeFetchExpression(format('SavedInstances.db.Toons["%s"].Quests', fullName))
            if not quests then return end

            local count = 0
            for _, questData in pairs(quests) do
                if questData.isDaily and questData.Zone and questData.Zone.mapID and questData.Zone.mapID == 1355 then
                    count = count + 1
                end
            end
            return (count >= 3), GetQuestResetTime()
        end,
    },
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
            local cache = SafeFetchExpression('SavedInstances.db.Emissary.Cache')
            local emissary = SafeFetchExpression('SavedInstances.db.Emissary.Expansion[7]')
            local days = SafeFetchExpression(format('SavedInstances.db.Toons["%s"].Emissary[7].days', fullName))
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
            [50598] = true, -- Zandalari Empire
            [50603] = true, -- Voldunai
            [56120] = true, -- The Unshackled
        },
    },
    {
        name = "世界任务",
        event = {
            ['QUEST_TURNED_IN'] = true,
        },
        character = true,
        func = function(data)
            local quests = C_TaskQuest_GetQuestsForPlayerByMapID(1355) -- Nazjatar
            if not quests then return end

            local result = {}
            for _, questData in pairs(quests) do
                local questID = questData.questId
                if questID and data.questIDs[questID] then
                    tinsert(result, {
                        false, C_TaskQuest_GetQuestTimeLeftMinutes(questID) * 60,
                        data.questIDs[questID] or "纳沙塔尔大扫除",
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
            -- Mage Requires
            [55886] = '赞齐尔残暴者', -- The Zanj'ir Brutalizer
            [55889] = '勇士吉克斯，深渊语者', -- Champion Kyx'zhul the Deepspeaker

            -- Druid Requires
            [55897] = '苏恩，碎奴者', -- Szun, Breaker of Slaves
            [55887] = '勇士奥扎娜，滚雷之箭', -- Champion Alzana, Arrow of Thunder
            [55900] = '卡萨尔，黑暗之刃', -- Kassar, Wielder of Dark Blades
            [55898] = '风暴语者莎兰阿里', -- Tempest-Speaker Shalan'ali
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
