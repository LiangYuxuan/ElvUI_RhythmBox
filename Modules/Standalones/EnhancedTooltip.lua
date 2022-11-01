-- From ElvUI_WindTools
-- https://github.com/fang2hou/ElvUI_WindTools/blob/master/Modules/Interface/EnhancedTooltip.lua

local R, E, L, V, P, G = unpack(select(2, ...))
local ETT = R:NewModule('EnhancedTooltip', 'AceEvent-3.0', 'AceHook-3.0')
local TT  = E:GetModule('Tooltip')

-- Lua functions
local _G = _G
local format, ipairs, pairs, select, strsub = format, ipairs, pairs, select, strsub
local tonumber, unpack, wipe = tonumber, unpack, wipe

-- WoW API / Variables
local C_ChallengeMode_GetKeystoneLevelRarityColor = C_ChallengeMode.GetKeystoneLevelRarityColor
local C_ChallengeMode_GetSpecificDungeonOverallScoreRarityColor = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor
local C_MythicPlus_GetSeasonBestAffixScoreInfoForMap = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap
local C_PlayerInfo_GetPlayerMythicPlusRatingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary
local C_CreatureInfo_GetFactionInfo = C_CreatureInfo.GetFactionInfo
local CanInspect = CanInspect
local ClearAchievementComparisonUnit = ClearAchievementComparisonUnit
local GetAchievementComparisonInfo = GetAchievementComparisonInfo
local GetAchievementInfo = GetAchievementInfo
local GetComparisonStatistic = GetComparisonStatistic
local GetStatistic = GetStatistic
local GetTime = GetTime
local IsAddOnLoaded = IsAddOnLoaded
local InCombatLockdown = InCombatLockdown
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
    {'SFO',   "初诞者圣墓"},
    {'VotI',  "化身巨龙牢窟"},
}

local database = {
    ['Raid'] = {
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
        ['SFO'] = {
            ['Mythic'] = {
                15427, 15439, 15435, 15443, 15431, 15451, 15447, 15455, 15459, 15463, 15467,
            },
            ['Heroic'] = {
                15426, 15438, 15434, 15442, 15430, 15450, 15446, 15454, 15458, 15462, 15466,
            },
            ['Normal'] = {
                15425, 15437, 15433, 15441, 15429, 15449, 15445, 15453, 15457, 15461, 15465,
            },
            ['LFR'] = {
                15424, 15436, 15432, 15440, 15428, 15448, 15444, 15452, 15456, 15460, 15464,
            },
        },
    },
    ['Dungeon'] = {
        ['MythicPlus'] = 7399,
        ['SeasonAchievement'] = {
            {'SLS3', 15496, 15498, 15499, 15506}, -- Shadowlands Season Three
            {'SLS4', 15688, 15689, 15690},        -- Shadowlands Season Four
            {'DFS1', 16647, 16648, 16649, 16650}, -- Dragonflight Season One
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
    local baseScores = {0, 40, 45, 55, 60, 65, 75, 80, 85, 100}
    local levelScore = 5
    local timeThreshold = .4
    local timeModifier = 5
    local depletionPunishment = 5

    function ETT:GetOppositeKeyText(mapID, overallScore, level, duration)
        if not self.challengeMapTimeLimit[mapID] then
            self.challengeMapTimeLimit[mapID] = select(3, C_ChallengeMode.GetMapUIInfo(mapID))
        end

        local timeLimit = self.challengeMapTimeLimit[mapID]
        local score = baseScores[min(level, 10)] + max(0, level - 10) * levelScore
        if timeLimit * (1 - timeThreshold) >= duration then
            score = score + timeModifier
        elseif timeLimit >= duration then
            score = score + timeModifier * ((1 - duration / timeLimit) / timeThreshold)
        elseif timeLimit * (1 + timeThreshold) >= duration then
            score = score + timeModifier * ((1 - duration / timeLimit) / timeThreshold) - depletionPunishment
        else
            score = 0
        end

        local oppositeScore = (overallScore - 1.5 * score) / .5
        if oppositeScore > baseScores[#baseScores] - timeModifier - depletionPunishment then
            if oppositeScore > baseScores[#baseScores] then
                local extraScore = oppositeScore - baseScores[#baseScores]
                local extraLevel = floor(extraScore / levelScore)
                local restScore = extraScore - extraLevel * levelScore

                local levelColor = C_ChallengeMode_GetKeystoneLevelRarityColor(extraLevel + 10)
                return levelColor:WrapTextInColorCode((extraLevel + 10) .. (restScore >= 2.5 and '+2' or '+1'))
            else
                local minusScore = oppositeScore - baseScores[#baseScores] + depletionPunishment

                return GRAY_FONT_COLOR:WrapTextInColorCode('10' .. (minusScore < 2.5 and '-2' or '-1'))
            end
        elseif oppositeScore < baseScores[2] - timeModifier - depletionPunishment then
            -- opposite score lower than min possible, ignores
            return
        else
            for oppositeLevel = #baseScores - 1, 2, -1 do
                if oppositeScore > baseScores[oppositeLevel] then
                    local restScore = oppositeScore - baseScores[oppositeLevel]

                    local levelColor = C_ChallengeMode_GetKeystoneLevelRarityColor(oppositeLevel)
                    return levelColor:WrapTextInColorCode(oppositeLevel .. (restScore >= 2.5 and '+2' or '+1'))
                end
            end
        end
    end
end

function ETT:GetKeyLevelText(mapID, level, duration)
    if not self.challengeMapTimeLimit[mapID] then
        self.challengeMapTimeLimit[mapID] = select(3, C_ChallengeMode.GetMapUIInfo(mapID))
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
            if not self.loadedComparison and IsAddOnLoaded('Blizzard_AchievementUI') then
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

local function TooltipOptions()
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
end
tinsert(R.Config, TooltipOptions)

function ETT:Initialize()
    self.challengeMapTimeLimit = {}

    local mapChallengeModeIDs = C_ChallengeMode.GetMapTable()
    for _, mapID in ipairs(mapChallengeModeIDs) do
        local name, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapID)

        tinsert(dungeons, {mapID, name})
        self.challengeMapTimeLimit[mapID] = timeLimit
        database.Dungeon[mapID] = 0 -- dummy, no longer get total kill
    end

    self:SecureHook(TT, 'AddInspectInfo')
end

R:RegisterModule(ETT:GetName())
