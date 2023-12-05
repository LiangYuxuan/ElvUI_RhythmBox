-- From ElvUI_WindTools
-- https://github.com/fang2hou/ElvUI_WindTools/blob/master/Modules/Interface/EnhancedTooltip.lua

local R, E, L, V, P, G = unpack((select(2, ...)))
local ETT = R:NewModule('EnhancedTooltip', 'AceEvent-3.0', 'AceHook-3.0')
local TT  = E:GetModule('Tooltip')

-- Lua functions
local _G = _G
local floor, format, ipairs, max, min, pairs, tinsert = floor, format, ipairs, max, min, pairs, tinsert
local select, strsub, tonumber, unpack, wipe = select, strsub, tonumber, unpack, wipe

-- WoW API / Variables
local C_AddOns_IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local C_ChallengeMode_GetKeystoneLevelRarityColor = C_ChallengeMode.GetKeystoneLevelRarityColor
local C_ChallengeMode_GetMapTable = C_ChallengeMode.GetMapTable
local C_ChallengeMode_GetMapUIInfo = C_ChallengeMode.GetMapUIInfo
local C_ChallengeMode_GetSpecificDungeonOverallScoreRarityColor = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor
local C_MythicPlus_GetSeasonBestAffixScoreInfoForMap = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap
local C_PlayerInfo_GetPlayerMythicPlusRatingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary
local C_CreatureInfo_GetFactionInfo = C_CreatureInfo.GetFactionInfo
local CanInspect = CanInspect
local ClearAchievementComparisonUnit = ClearAchievementComparisonUnit
local GetAchievementComparisonInfo = GetAchievementComparisonInfo
local GetAchievementInfo = GetAchievementInfo
local GetComparisonStatistic = GetComparisonStatistic
local GetItemQualityColor = GetItemQualityColor
local GetStatistic = GetStatistic
local GetTime = GetTime
local SetAchievementComparisonUnit = SetAchievementComparisonUnit
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitLevel = UnitLevel
local UnitRace = UnitRace

local HideUIPanel = HideUIPanel

local GRAY_FONT_COLOR = GRAY_FONT_COLOR
local MAX_PLAYER_LEVEL = MAX_PLAYER_LEVEL

local progressCache = {}

local dungeons = {
    {'MythicPlus', "史诗钥石次数"},
    {'SeasonAchievement', "赛季限时成就"},
}

local levels = {
    {'Mythic', "史诗"},
    {'Heroic', "英雄"},
    {'Normal', "普通"},
    {'LFR',    "随机"},
}

local tiers = {
    {'VotI',  "化身巨龙牢窟"},
    {'AtSC',  "亚贝鲁斯，焰影熔炉"},
    {'AtDH',  "阿梅达希尔，梦境之愿"},
}

local database = {
    ['Raid'] = {
        ['AtDH'] = {
            ['Mythic'] = {
                19378, 19379, 19380, 19382, 19381, 19383, 19384, 19385, 19386,
            },
            ['Heroic'] = {
                19369, 19370, 19371, 19373, 19372, 19374, 19375, 19376, 19377,
            },
            ['Normal'] = {
                19360, 19361, 19362, 19364, 19363, 19365, 19366, 19367, 19368,
            },
            ['LFR'] = {
                19348, 19352, 19353, 19355, 19354, 19356, 19357, 19358, 19359,
            },
        },
        ['AtSC'] = {
            ['Mythic'] = {
                18219, 18220, 18221, 18222, 18223, 18224, 18225, 18226, 18227,
            },
            ['Heroic'] = {
                18210, 18211, 18212, 18213, 18214, 18215, 18216, 18217, 18218,
            },
            ['Normal'] = {
                18189, 18190, 18191, 18192, 18194, 18195, 18196, 18197, 18198,
            },
            ['LFR'] = {
                18180, 18181, 18182, 18183, 18184, 18185, 18186, 18188, 18187,
            },
        },
        ['VotI'] = {
            ['Mythic'] = {
                16387, 16389, 16391, 16388, 16390, 16392, 16393, 16394,
            },
            ['Heroic'] = {
                16379, 16381, 16383, 16380, 16382, 16384, 16385, 16386,
            },
            ['Normal'] = {
                16371, 16373, 16375, 16372, 16374, 16376, 16377, 16378,
            },
            ['LFR'] = {
                16359, 16362, 16367, 16361, 16366, 16368, 16369, 16370,
            },
        },
    },
    ['Dungeon'] = {
        ['MythicPlus'] = 7399,
        ['SeasonAchievement'] = {
            {'DFS1', 16647, 16648, 16649, 16650}, -- Dragonflight Season One
            {'DFS2', 17842, 17843, 17844, 17845}, -- Dragonflight Season Two
            {'DFS3', 19009, 19010, 19011, 19012}, -- Dragonflight Season Three
        },
    },
}

function ETT:IsDungeonEnabled(index)
    if index == 'MythicPlus' or index == 'SeasonAchievement' then
        return E.db.RhythmBox.EnhancedTooltip.Dungeon[index]
    else
        return E.db.RhythmBox.EnhancedTooltip.Dungeon.ChallengeModeMaps
    end
end

do
    local baseScores = {0, 40, 45, 50, 55, 60, 75, 80, 85, 90, 97, 104, 111, 128}
    local providedLevel = #baseScores
    local levelScore = 7
    local timeThreshold = .4
    local timeModifier = 5
    local depletionPunishment = 5

    local function GetKeyLevelScoreRange(level)
        local baseScore = baseScores[min(level, providedLevel)] + max(0, level - providedLevel) * levelScore
        return baseScore + timeModifier, baseScore, baseScore - depletionPunishment, baseScore - timeModifier - depletionPunishment
    end

    local function GetExtraScorePostfix(extraScore)
        if extraScore >= 5 then
            return '+3'
        elseif extraScore >= 2.5 then
            return '+2'
        elseif extraScore > 0 then
            return '+1'
        elseif extraScore <= 2.5 then
            return '-1'
        elseif extraScore < 3 then
            return '-2'
        else
            return '-3'
        end
    end

    function ETT:GetOppositeKeyText(mapID, overallScore, level, duration)
        if not self.challengeMapTimeLimit[mapID] then
            self.challengeMapTimeLimit[mapID] = select(3, C_ChallengeMode_GetMapUIInfo(mapID))
        end

        local timeLimit = self.challengeMapTimeLimit[mapID]
        local score = baseScores[min(level, providedLevel)] + max(0, level - providedLevel) * levelScore
        if timeLimit * (1 - timeThreshold) >= duration then
            score = score + timeModifier
        elseif timeLimit >= duration then
            score = score + timeModifier * ((1 - duration / timeLimit) / timeThreshold)
        elseif timeLimit * (1 + timeThreshold) >= duration then
            if level > 20 then
                -- Patch 10.0.5, +20 overtime score
                -- https://www.wowhead.com/news/score-awarded-from-depleted-mythic-keystones-over-20-significantly-nerfed-in-331144
                score = baseScores[min(20, providedLevel)] + max(0, 20 - providedLevel) * levelScore
            end
            score = score + timeModifier * ((1 - duration / timeLimit) / timeThreshold) - depletionPunishment
        else
            score = 0
        end

        local oppositeScore = (overallScore - 1.5 * score) / .5
        local highestLevel = providedLevel
        if oppositeScore > (baseScores[providedLevel] - timeModifier - depletionPunishment) then
            local extraScore = oppositeScore - baseScores[providedLevel] + timeModifier + depletionPunishment
            highestLevel = providedLevel + floor(extraScore / levelScore)
        end

        local result
        for oppositeLevel = highestLevel, 2, -1 do
            local maxScore, baseScore, depleteMax, depleteMin = GetKeyLevelScoreRange(oppositeLevel)
            if oppositeScore > maxScore then
                -- above max possible in current or less levels
                break
            elseif oppositeScore >= baseScore then
                -- favorites in time found in current level
                local restScore = oppositeScore - baseScore
                local levelColor = C_ChallengeMode_GetKeystoneLevelRarityColor(oppositeLevel)
                result = levelColor:WrapTextInColorCode(oppositeLevel .. GetExtraScorePostfix(restScore))
                break
            elseif oppositeScore <= depleteMax and oppositeScore >= depleteMin then
                -- deplete found in current level
                -- don't break to found in time
                local restScore = oppositeScore - baseScore
                result = GRAY_FONT_COLOR:WrapTextInColorCode(oppositeLevel .. GetExtraScorePostfix(restScore))
            end
        end

        return result
    end
end

function ETT:GetKeyLevelText(mapID, level, duration)
    if not self.challengeMapTimeLimit[mapID] then
        self.challengeMapTimeLimit[mapID] = select(3, C_ChallengeMode_GetMapUIInfo(mapID))
    end

    local timeLimit = self.challengeMapTimeLimit[mapID]
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

    if level == 'Mythic' then
        color = "ffa335ee"
    elseif level == 'Heroic' then
        color = "ff0070dd"
    elseif level == 'Normal' then
        color = "ff1eff00"
    end

    return format("|c%s%s|r", color, short and strsub(level, 1, 1) or levelName)
end

function ETT:SetProgressionInfo(guid, tooltip)
    if not progressCache[guid] then return end

    if E.db.RhythmBox.EnhancedTooltip.Raid.Enable then
        tooltip:AddLine(" ")
        tooltip:AddLine("团队副本")
        for _, tierTable in ipairs(tiers) do
            local tier, tierName = unpack(tierTable)
            if E.db.RhythmBox.EnhancedTooltip.Raid[tier] then
                for _, levelTable in ipairs(levels) do
                    local level, levelName = unpack(levelTable)
                    if progressCache[guid].info.raid[tier][level] then
                        tooltip:AddDoubleLine(
                            format("%s %s:", tierName, self:GetColorLevel(level, levelName, false)),
                            format("%s%s", self:GetColorLevel(level, levelName, true), progressCache[guid].info.raid[tier][level]),
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
        for _, dungeonTable in ipairs(dungeons) do
            local index, dungeonName = unpack(dungeonTable)
            if self:IsDungeonEnabled(index) then
                tooltip:AddDoubleLine(dungeonName, progressCache[guid].info.dungeon[index], nil, nil, nil, 1, 1, 1)
            end
        end
    end
end

function ETT:UpdateProgression(guid, faction)
    local statFunc = guid == E.myguid and GetStatistic or GetComparisonStatistic

    progressCache[guid] = progressCache[guid] or {}
    progressCache[guid].info =  progressCache[guid].info or {}
    progressCache[guid].timer = GetTime()

    if E.db.RhythmBox.EnhancedTooltip.Raid.Enable then
        progressCache[guid].info.raid = {}
        for _, tierTable in ipairs(tiers) do
            local tier = tierTable[1]
            if E.db.RhythmBox.EnhancedTooltip.Raid[tier] then
                progressCache[guid].info.raid[tier] = {}
                local bosses = tier == 'BoD' and database.Raid[tier][faction] or database.Raid[tier]

                for _, levelTable in ipairs(levels) do
                    local level = levelTable[1]
                    local killed = 0
                    for _, statId in ipairs(bosses[level]) do
                        local kills = tonumber(statFunc(statId), 10)
                        if kills and kills > 0 then
                            killed = killed + 1
                        end
                    end
                    if killed > 0 then
                        progressCache[guid].info.raid[tier][level] = format("%d/%d", killed, #bosses[level])
                        if killed == #bosses[level] then
                            break
                        end
                    end
                end
            end
        end
    end

    if E.db.RhythmBox.EnhancedTooltip.Dungeon.Enable then
        progressCache[guid].info.dungeon = {}
        local info = guid ~= E.myguid and C_PlayerInfo_GetPlayerMythicPlusRatingSummary('mouseover')
        for k, v in pairs(database.Dungeon) do
            if self:IsDungeonEnabled(k) then
                if k == 'MythicPlus' then
                    progressCache[guid].info.dungeon[k] = statFunc(v)
                elseif k == 'SeasonAchievement' then
                    local result = ""
                    for index, data in ipairs(v) do
                        local highest
                        if guid == E.myguid then
                            for i = 5, 2, -1 do
                                if data[i] and select(4, GetAchievementInfo(data[i])) then
                                    highest = i
                                    break
                                end
                            end
                        else
                            for i = 5, 2, -1 do
                                if data[i] and GetAchievementComparisonInfo(data[i]) then
                                    highest = i
                                    break
                                end
                            end
                        end

                        local _, colorHex
                        if highest then
                            _, _, _, colorHex = GetItemQualityColor(highest)
                        else
                            colorHex = 'ffee4735'
                        end

                        result = format(
                            index == 1 and "|c%s%s|r" or "|c%s%s|r / ",
                            colorHex, data[1]
                        ) .. result
                    end
                    progressCache[guid].info.dungeon[k] = result
                else
                    local mapID = tonumber(k)
                    if guid == E.myguid then
                        -- player
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
                            local scoreText = scoreColor:WrapTextInColorCode(bestOverAllScore)

                            progressCache[guid].info.dungeon[k] = format('%s (%s)', scoreText, keyLevels)
                        else
                            progressCache[guid].info.dungeon[k] = '0'
                        end
                    else
                        -- other player
                        if info then
                            for _, data in ipairs(info.runs) do
                                if data.challengeModeID == mapID then
                                    local keyLevels = self:GetKeyLevelText(mapID, data.bestRunLevel, data.bestRunDurationMS / 1000)
                                    local opposite = self:GetOppositeKeyText(mapID, data.mapScore, data.bestRunLevel, data.bestRunDurationMS / 1000)
                                    if opposite then
                                        keyLevels = keyLevels .. ' / ' .. opposite
                                    end

                                    local scoreColor = C_ChallengeMode_GetSpecificDungeonOverallScoreRarityColor(data.mapScore)
                                    local bestOverAllScore = scoreColor:WrapTextInColorCode(data.mapScore)

                                    progressCache[guid].info.dungeon[k] = format('%s (%s)', bestOverAllScore, keyLevels)
                                    break
                                end
                            end
                            if not progressCache[guid].info.dungeon[k] then
                                progressCache[guid].info.dungeon[k] = '0'
                            end
                        else
                            progressCache[guid].info.dungeon[k] = '?'
                            progressCache[guid].timer = 0 -- require fetch later
                        end
                    end
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
        local race = select(3, UnitRace(unit))
        local faction = race and C_CreatureInfo_GetFactionInfo(race).groupTag
        if faction then
            self:UpdateProgression(guid, faction)
            _G.GameTooltip:SetUnit(unit)
        end
    end
    ClearAchievementComparisonUnit()
    self:UnregisterEvent('INSPECT_ACHIEVEMENT_READY')
end

function ETT:AddInspectInfo(_, tooltip, unit, numTries)
    if numTries > 0 or not unit or not CanInspect(unit) then return end

    local level = UnitLevel(unit)
    if not level or level < MAX_PLAYER_LEVEL then return end

    local guid = UnitGUID(unit)
    if not progressCache[guid] or (GetTime() - progressCache[guid].timer) > 600 then
        if guid == E.myguid then
            self:UpdateProgression(guid, E.myfaction)
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
for _, data in ipairs(tiers) do
    local abbr = unpack(data)
    P["RhythmBox"]["EnhancedTooltip"]["Raid"][abbr] = true
end

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
    for index, value in ipairs(tiers) do
        local abbr, name = unpack(value)
        E.Options.args.RhythmBox.args.EnhancedTooltip.args.Raid.args[abbr] = {
            order = index + 1,
            name = name,
            type = 'toggle',
        }
    end
end)

function ETT:Initialize()
    self.challengeMapTimeLimit = {}

    local mapChallengeModeIDs = C_ChallengeMode_GetMapTable()
    for _, mapID in ipairs(mapChallengeModeIDs) do
        local name, _, timeLimit = C_ChallengeMode_GetMapUIInfo(mapID)

        tinsert(dungeons, {mapID, name})
        self.challengeMapTimeLimit[mapID] = timeLimit
        database.Dungeon[mapID] = 0 -- dummy, no longer get total kill
    end

    self:SecureHook(TT, 'AddInspectInfo')
end

R:RegisterModule(ETT:GetName())
