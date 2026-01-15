-- From ElvUI_WindTools
-- https://github.com/fang2hou/ElvUI_WindTools/blob/master/Modules/Interface/EnhancedTooltip.lua

local R, E, L, V, P, G = unpack((select(2, ...)))
local ETT = R:NewModule('EnhancedTooltip', 'AceEvent-3.0', 'AceHook-3.0')
local TT  = E:GetModule('Tooltip')

-- Lua functions
local _G = _G
local format, ipairs, tinsert, select = format, ipairs, tinsert, select
local strupper, strsub, tonumber, tostring, wipe = strupper, strsub, tonumber, tostring, wipe
local table_concat = table.concat

-- WoW API / Variables
local C_AddOns_IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local C_ChallengeMode_GetKeystoneLevelRarityColor = C_ChallengeMode.GetKeystoneLevelRarityColor
local C_ChallengeMode_GetMapTable = C_ChallengeMode.GetMapTable
local C_ChallengeMode_GetMapUIInfo = C_ChallengeMode.GetMapUIInfo
local C_ChallengeMode_GetSpecificDungeonOverallScoreRarityColor = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor
local C_Item_GetItemQualityColor = C_Item.GetItemQualityColor
local C_MythicPlus_GetSeasonBestAffixScoreInfoForMap = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap
local C_PlayerInfo_GetPlayerMythicPlusRatingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary
local CanInspect = CanInspect
local ClearAchievementComparisonUnit = ClearAchievementComparisonUnit
local GetAchievementComparisonInfo = GetAchievementComparisonInfo
local GetAchievementInfo = GetAchievementInfo
local GetComparisonStatistic = GetComparisonStatistic
local GetLFGDungeonInfo = GetLFGDungeonInfo
local GetStatistic = GetStatistic
local GetTime = GetTime
local SetAchievementComparisonUnit = SetAchievementComparisonUnit
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitLevel = UnitLevel

local HideUIPanel = HideUIPanel

local GRAY_FONT_COLOR = GRAY_FONT_COLOR

local maxLevel = GetMaxLevelForPlayerExpansion()

---@class ProgressDungeonInfo
---@field MythicPlus integer|nil
---@field SeasonAchievement string|nil
---@field ChallengeModeMaps table<number, string>|nil

---@class ProgressInfo
---@field raid table<number, table<string, string>>
---@field dungeon ProgressDungeonInfo

---@type table<string, { timer: number, info: ProgressInfo }>
local progressCache = {}

---@type number[]
local challengeMaps = {}
---@type table<number, string>
local challengeMapName = {}
---@type table<number, number>
local challengeMapTimeLimit = {}

local difficulties = {
    {'mythic', "史诗"},
    {'heroic', "英雄"},
    {'normal', "普通"},
    {'lfr',    "随机"},
}

local seasons = {
    ---AUTO_GENERATED LEADING EnhancedTooltipSeasons
    {
        name = 'TWWS1',
        achievements = {20523, 20524, 20525, 20526},
    },
    {
        name = 'TWWS2',
        achievements = {40949, 40950, 41533, 40952, 40951},
    },
    {
        name = 'TWWS3',
        achievements = {42169, 42170, 41973, 42171, 42172},
    },
    {
        name = 'MIDS1',
        achievements = {61254, 61255, 61256, 61257, 61258},
    },
    ---AUTO_GENERATED TAILING EnhancedTooltipSeasons
}

---@type { id: number, name?: string, mythic: number[], heroic: number[], normal: number[], lfr: number[] }[]
local raids = {
    ---AUTO_GENERATED LEADING EnhancedTooltipRaids
    {
        id = 2645, -- Nerub-ar Palace
        mythic = {
            40270, 40274, 40278, 40282, 40286, 40290, 40294, 40298,
        },
        heroic = {
            40269, 40273, 40277, 40281, 40285, 40289, 40293, 40297,
        },
        normal = {
            40268, 40272, 40276, 40280, 40284, 40288, 40292, 40296,
        },
        lfr = {
            40267, 40271, 40275, 40279, 40283, 40287, 40291, 40295,
        },
    },
    {
        id = 2779, -- Liberation of Undermine
        mythic = {
            41302, 41306, 41310, 41314, 41318, 41322, 41326, 41330,
        },
        heroic = {
            41301, 41305, 41309, 41313, 41317, 41321, 41325, 41329,
        },
        normal = {
            41300, 41304, 41308, 41312, 41316, 41320, 41324, 41328,
        },
        lfr = {
            41299, 41303, 41307, 41311, 41315, 41319, 41323, 41327,
        },
    },
    {
        id = 2805, -- Manaforge Omega
        mythic = {
            41636, 41640, 41644, 41648, 41652, 41656, 41660, 41664,
        },
        heroic = {
            41635, 41639, 41643, 41647, 41651, 41655, 41659, 41663,
        },
        normal = {
            41634, 41638, 41642, 41646, 41650, 41654, 41658, 41662,
        },
        lfr = {
            41633, 41637, 41641, 41645, 41649, 41653, 41657, 41661,
        },
    },
    {
        id = 3094, -- The Voidspire
        mythic = {
            61279, 61283, 61287, 61291, 61295, 61299,
        },
        heroic = {
            61278, 61282, 61286, 61290, 61294, 61298,
        },
        normal = {
            61277, 61281, 61285, 61289, 61293, 61297,
        },
        lfr = {
            61276, 61280, 61284, 61288, 61292, 61296,
        },
    },
    {
        id = 3095, -- March on Quel'Danas
        mythic = {
            61303, 61307,
        },
        heroic = {
            61302, 61306,
        },
        normal = {
            61301, 61305,
        },
        lfr = {
            61300, 61304,
        },
    },
    {
        id = 3165, -- The Dreamrift
        mythic = {
            61477,
        },
        heroic = {
            61476,
        },
        normal = {
            61475,
        },
        lfr = {
            61474,
        },
    },
    ---AUTO_GENERATED TAILING EnhancedTooltipRaids
}

function ETT:GetKeyLevelText(mapID, level, duration)
    if not challengeMapTimeLimit[mapID] then
        challengeMapTimeLimit[mapID] = select(3, C_ChallengeMode_GetMapUIInfo(mapID))
    end

    local timeLimit = challengeMapTimeLimit[mapID]
    if timeLimit * .6 >= duration then
        local levelColor = C_ChallengeMode_GetKeystoneLevelRarityColor(level)
        return levelColor:WrapTextInColorCode(level .. '+3')
    elseif timeLimit * .8 >= duration then
        local levelColor = C_ChallengeMode_GetKeystoneLevelRarityColor(level)
        return levelColor:WrapTextInColorCode(level .. '+2')
    elseif timeLimit >= duration then
        local levelColor = C_ChallengeMode_GetKeystoneLevelRarityColor(level)
        return levelColor:WrapTextInColorCode(level .. '+1')
    elseif timeLimit * 1.2 >= duration then
        return GRAY_FONT_COLOR:WrapTextInColorCode(level .. '-1')
    elseif timeLimit * 1.4 >= duration then
        return GRAY_FONT_COLOR:WrapTextInColorCode(level .. '-2')
    else
        return GRAY_FONT_COLOR:WrapTextInColorCode(level .. '-3')
    end
end

function ETT:GetColorLevel(level, levelName, short)
    local color = "ffffffff" -- LFG

    if level == 'mythic' then
        color = "ffa335ee"
    elseif level == 'heroic' then
        color = "ff0070dd"
    elseif level == 'normal' then
        color = "ff1eff00"
    end

    return format("|c%s%s|r", color, short and strupper(strsub(level, 1, 1)) or levelName)
end

function ETT:SetProgressionInfo(guid, tooltip)
    if not progressCache[guid] then return end

    if E.db.RhythmBox.EnhancedTooltip.Raid.Enable then
        tooltip:AddLine(" ")
        tooltip:AddLine("团队副本")
        for _, data in ipairs(raids) do
            local id, raidName = data.id, data.name
            if progressCache[guid].info.raid[id] then
                for _, difficulty in ipairs(difficulties) do
                    local key, difficultyName = difficulty[1], difficulty[2]
                    if progressCache[guid].info.raid[id][key] then
                        tooltip:AddDoubleLine(
                            format("%s %s:", raidName, self:GetColorLevel(key, difficultyName, false)),
                            format("%s%s", self:GetColorLevel(key, difficultyName, true), progressCache[guid].info.raid[id][key]),
                            nil, nil, nil, 1, 1, 1
                        )
                    end
                end
            end
        end
    end

    if E.db.RhythmBox.EnhancedTooltip.Dungeon.Enable then
        tooltip:AddLine(" ")
        tooltip:AddLine("地下城")

        if E.db.RhythmBox.EnhancedTooltip.Dungeon.MythicPlus and progressCache[guid].info.dungeon.MythicPlus then
            tooltip:AddDoubleLine("史诗钥石次数", progressCache[guid].info.dungeon.MythicPlus)
        end

        if E.db.RhythmBox.EnhancedTooltip.Dungeon.SeasonAchievement and progressCache[guid].info.dungeon.SeasonAchievement then
            tooltip:AddDoubleLine("赛季限时成就", progressCache[guid].info.dungeon.SeasonAchievement)
        end

        if E.db.RhythmBox.EnhancedTooltip.Dungeon.ChallengeModeMaps and progressCache[guid].info.dungeon.ChallengeModeMaps then
            for _, mapID in ipairs(challengeMaps) do
                if progressCache[guid].info.dungeon.ChallengeModeMaps[mapID] then
                    tooltip:AddDoubleLine(challengeMapName[mapID], progressCache[guid].info.dungeon.ChallengeModeMaps[mapID])
                end
            end
        end
    end
end

function ETT:UpdateProgression(guid)
    local statFunc = guid == E.myguid and GetStatistic or GetComparisonStatistic

    progressCache[guid] = progressCache[guid] or {}
    progressCache[guid].info =  progressCache[guid].info or {}
    progressCache[guid].timer = GetTime()

    if E.db.RhythmBox.EnhancedTooltip.Raid.Enable then
        progressCache[guid].info.raid = {}
        for _, data in ipairs(raids) do
            progressCache[guid].info.raid[data.id] = {}
            local progress = progressCache[guid].info.raid[data.id]

            for _, difficulty in ipairs(difficulties) do
                local key = difficulty[1]
                local killed = 0
                for _, statID in ipairs(data[key]) do
                    local kills = tonumber(statFunc(statID), 10)
                    if kills and kills > 0 then
                        killed = killed + 1
                    end
                end
                if killed > 0 then
                    progress[key] = format("%d/%d", killed, #data[key])
                    if killed == #data[key] then
                        break
                    end
                end
            end
        end
    end

    if E.db.RhythmBox.EnhancedTooltip.Dungeon.Enable then
        progressCache[guid].info.dungeon = {}

        if E.db.RhythmBox.EnhancedTooltip.Dungeon.MythicPlus then
            progressCache[guid].info.dungeon.MythicPlus = tonumber(statFunc(7399), 10)
        end

        if E.db.RhythmBox.EnhancedTooltip.Dungeon.SeasonAchievement then
            local seasonAchievements = {}
            for _, season in ipairs(seasons) do
                local highest
                if guid == E.myguid then
                    for i = #season.achievements, 1, -1 do
                        if select(4, GetAchievementInfo(season.achievements[i])) then
                            highest = i
                            break
                        end
                    end
                else
                    for i = #season.achievements, 1, -1 do
                        if GetAchievementComparisonInfo(season.achievements[i]) then
                            highest = i
                            break
                        end
                    end
                end

                local colorHex = highest and select(4, C_Item_GetItemQualityColor(highest + 1)) or 'ffee4735'
                tinsert(seasonAchievements, 1, format("|c%s%s|r", colorHex, season.name))
            end

            progressCache[guid].info.dungeon.SeasonAchievement = table_concat(seasonAchievements, ' / ')
        end

        if E.db.RhythmBox.EnhancedTooltip.Dungeon.ChallengeModeMaps then
            if guid == E.myguid then
                progressCache[guid].info.dungeon.ChallengeModeMaps = {}

                for _, mapID in ipairs(challengeMaps) do
                    local affixScores, bestOverAllScore = C_MythicPlus_GetSeasonBestAffixScoreInfoForMap(mapID)
                    if bestOverAllScore and bestOverAllScore > 0 then
                        local keyLevels = "?"
                        for index, data in ipairs(affixScores) do
                            if index == 1 then
                                keyLevels = self:GetKeyLevelText(mapID, data.level, data.durationSec)
                            else
                                keyLevels = keyLevels .. ' / ' .. self:GetKeyLevelText(mapID, data.level, data.durationSec)
                            end
                        end

                        local scoreColor = C_ChallengeMode_GetSpecificDungeonOverallScoreRarityColor(bestOverAllScore)
                        local scoreText = scoreColor:WrapTextInColorCode(tostring(bestOverAllScore))

                        progressCache[guid].info.dungeon.ChallengeModeMaps[mapID] = format('%s (%s)', scoreText, keyLevels)
                    else
                        progressCache[guid].info.dungeon.ChallengeModeMaps[mapID] = '0'
                    end
                end
            else
                local info = C_PlayerInfo_GetPlayerMythicPlusRatingSummary('mouseover')
                if info then
                    progressCache[guid].info.dungeon.ChallengeModeMaps = {}

                    for _, data in ipairs(info.runs) do
                        local mapID = data.challengeModeID
                        local keyLevels = self:GetKeyLevelText(mapID, data.bestRunLevel, data.bestRunDurationMS / 1000)

                        local scoreColor = C_ChallengeMode_GetSpecificDungeonOverallScoreRarityColor(data.mapScore)
                        local scoreText = scoreColor:WrapTextInColorCode(tostring(data.mapScore))

                        progressCache[guid].info.dungeon.ChallengeModeMaps[mapID] = format('%s (%s)', scoreText, keyLevels)
                    end
                else
                    progressCache[guid].timer = 0 -- require fetch later
                end
            end
        end
    end
end

function ETT:CleanProgression()
    wipe(progressCache)
    self:UnregisterEvent('INSPECT_ACHIEVEMENT_READY')
end

function ETT:INSPECT_ACHIEVEMENT_READY(_, guid)
    if self.compareGUID ~= guid then return end

    local unit = 'mouseover'
    if UnitExists(unit) then
        self:UpdateProgression(guid)
        _G.GameTooltip:SetUnit(unit)
    end
    ClearAchievementComparisonUnit()
    self:UnregisterEvent('INSPECT_ACHIEVEMENT_READY')
end

function ETT:AddInspectInfo(_, tooltip, unit, numTries)
    if numTries > 0 or not unit or not CanInspect(unit) then return end

    local level = UnitLevel(unit)
    if not level or level < maxLevel then return end

    local guid = UnitGUID(unit)
    if not progressCache[guid] or (GetTime() - progressCache[guid].timer) > 600 then
        if guid == E.myguid then
            self:UpdateProgression(guid)
        else
            ClearAchievementComparisonUnit()
            if not self.loadedComparison and C_AddOns_IsAddOnLoaded('Blizzard_AchievementUI') then
                _G.AchievementFrame_DisplayComparison(unit)
                HideUIPanel(_G.AchievementFrame)
                ClearAchievementComparisonUnit()
                self.loadedComparison = true
            end

            self.compareGUID = guid
            if SetAchievementComparisonUnit(unit) then
                self:RegisterEvent('INSPECT_ACHIEVEMENT_READY')
            end
            return
        end
    end
    self:SetProgressionInfo(guid, tooltip)
end

P["RhythmBox"]["EnhancedTooltip"] = {
    ["Enable"] = true,
    ["Dungeon"] = {
        ["Enable"] = true,
        ["MythicPlus"] = true,
        ["SeasonAchievement"] = true,
        ["ChallengeModeMaps"] = true,
    },
    ["Raid"] = {
        ["Enable"] = true,
    },
}

R:RegisterOptions(function()
    E.Options.args.RhythmBox.args.EnhancedTooltip = {
        order = 23,
        type = 'group',
        name = "增强鼠标提示",
        get = function(info) return E.db.RhythmBox.EnhancedTooltip[info[#info]] end,
        set = function(info, value) E.db.RhythmBox.EnhancedTooltip[info[#info]] = value end,
        args = {
            Enable = {
                order = 1,
                type = 'toggle',
                name = "启用",
                set = function(info, value) E.db.RhythmBox.EnhancedTooltip[info[#info]] = value; E:StaticPopup_Show('PRIVATE_RL') end,
            },
            Dungeon = {
                name = "地下城",
                order = 2,
                type = 'group',
                guiInline = true,
                get = function(info) return E.db.RhythmBox.EnhancedTooltip.Dungeon[info[#info]] end,
                set = function(info, value) E.db.RhythmBox.EnhancedTooltip.Dungeon[info[#info]] = value; ETT:CleanProgression() end,
                disabled = function() return not E.db.RhythmBox.EnhancedTooltip.Enable or not E.db.RhythmBox.EnhancedTooltip.Dungeon.Enable end,
                args = {
                    Enable = {
                        order = 1,
                        name = "启用",
                        type = 'toggle',
                        disabled = function() return not E.db.RhythmBox.EnhancedTooltip.Enable end,
                    },
                    MythicPlus = {
                        order = 2,
                        name = "史诗钥石次数",
                        type = 'toggle',
                    },
                    SeasonAchievement = {
                        order = 3,
                        name = "赛季限时成就",
                        type = 'toggle',
                    },
                    ChallengeModeMaps = {
                        order = 4,
                        name = "赛季地下城分数",
                        type = 'toggle',
                    },
                },
            },
            Raid = {
                name = "团队副本",
                order = 3,
                type = 'group',
                guiInline = true,
                get = function(info) return E.db.RhythmBox.EnhancedTooltip.Raid[info[#info]] end,
                set = function(info, value) E.db.RhythmBox.EnhancedTooltip.Raid[info[#info]] = value; ETT:CleanProgression() end,
                disabled = function() return not E.db.RhythmBox.EnhancedTooltip.Enable or not E.db.RhythmBox.EnhancedTooltip.Raid.Enable end,
                args = {
                    Enable = {
                        order = 1,
                        name = "启用",
                        type = 'toggle',
                        disabled = function() return not E.db.RhythmBox.EnhancedTooltip.Enable end,
                    },
                },
            },
        },
    }
end)

function ETT:Initialize()
    if not E.db.RhythmBox.EnhancedTooltip.Enable then return end

    local mapChallengeModeIDs = C_ChallengeMode_GetMapTable()
    for _, mapID in ipairs(mapChallengeModeIDs) do
        local name, _, timeLimit = C_ChallengeMode_GetMapUIInfo(mapID)

        tinsert(challengeMaps, mapID)
        challengeMapName[mapID] = name
        challengeMapTimeLimit[mapID] = timeLimit
    end

    for _, data in ipairs(raids) do
        data.name = GetLFGDungeonInfo(data.id)
    end

    self:SecureHook(TT, 'AddInspectInfo')
end

R:RegisterModule(ETT:GetName())
