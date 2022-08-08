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

local mapChallengeModeIDs = {
    166, -- Grimrail Depot
    169, -- Iron Docks
    227, -- Return to Karazhan: Lower
    234, -- Return to Karazhan: Upper
    369, -- Operation: Mechagon - Junkyard
    370, -- Operation: Mechagon - Workshop
    391, -- Tazavesh: Streets of Wonder
    392, -- Tazavesh: So'leah's Gambit
}

local dungeons = {
    {'MythicPlus', "史诗钥石次数"},
    {'SeasonAchi', "赛季限时成就"},
}

local levels = {
    {'Mythic', "史诗"},
    {'Heroic', "英雄"},
    {'Normal', "普通"},
    {'LFR',    "随机"},
}

local tiers = {
    {'SoD',   "统御圣所"},
    {'CN',    "纳斯利亚堡"},
    {'SFO',   "初诞者圣墓"},
}

local database = {
    ['Raid'] = {
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
        ['CN'] = {
            ['Mythic'] = {
                14421, 14425, 14437, 14433, 14429, 14441, 14445, 14449, 14453, 14457,
            },
            ['Heroic'] = {
                14420, 14424, 14436, 14432, 14428, 14440, 14444, 14448, 14452, 14456,
            },
            ['Normal'] = {
                14419, 14423, 14435, 14431, 14427, 14439, 14443, 14447, 14451, 14455,
            },
            ['LFR'] = {
                14422, 14426, 14438, 14434, 14430, 14442, 14446, 14450, 14454, 14458,
            },
        },
        ['SoD'] = {
            ['Mythic'] = {
                15139, 15143, 15147, 15151, 15155, 15159, 15163, 15167, 15172, 15176,
            },
            ['Heroic'] = {
                15138, 15142, 15146, 15150, 15154, 15158, 15162, 15166, 15171, 15175,
            },
            ['Normal'] = {
                15137, 15141, 15145, 15149, 15153, 15157, 15161, 15165, 15170, 15174,
            },
            ['LFR'] = {
                15136, 15140, 15144, 15148, 15152, 15156, 15160, 15164, 15169, 15173,
            },
        },
    },
    ['Dungeon'] = {
        ['MythicPlus'] = 7399,
        ['SeasonAchi'] = {
            {14531, 14532}, -- Season One
            {15077, 15078}, -- Season Two
            {15498, 15499}, -- Season Three
            {15689, 15690}, -- Season Four
        },
    },
}

function ETT:GetColorLevel(level, levelName, short)
    local color = "ff8000" -- LFG

    if level == 'Mythic' then
        color = "a335ee"
    elseif level == 'Heroic' then
        color = "0070dd"
    elseif level == 'Normal' then
        color = "1eff00"
    end

    return format("|cff%s%s|r", color, short and strsub(level, 1, 1) or levelName)
end

function ETT:SetProgressionInfo(guid, tooltip)
    if not progressCache[guid] then return end

    -- find text and update
    local updated = false
    for i = 1, tooltip:NumLines() do
        local leftTip = _G[tooltip:GetName() .. 'TextLeft' .. i]
        local leftTipText = leftTip:GetText()
        local found = false
        if leftTipText then
            if E.db.RhythmBox.EnhancedTooltip.Raid.Enable then
                for _, tierTable in ipairs(tiers) do
                    local tier, tierName = unpack(tierTable)
                    if E.db.RhythmBox.EnhancedTooltip.Raid[tier] then
                        for _, levelTable in ipairs(levels) do
                            local level, levelName = unpack(levelTable)
                            if leftTipText:find(tierName) and leftTipText:find(levelName) then
                                -- update found tooltip text line
                                if progressCache[guid].info.raid[tier][level] then
                                    local rightTip = _G[tooltip:GetName() .. 'TextRight' .. i]
                                    leftTip:SetText(format("%s %s:", tierName, self:GetColorLevel(level, levelName, false)))
                                    rightTip:SetText(format("%s%s", self:GetColorLevel(level, levelName, true), progressCache[guid].info.raid[tier][level]))
                                end
                                found = true
                                updated = true
                                break
                            end
                        end
                        if found then break end
                    end
                end
            end
            if E.db.RhythmBox.EnhancedTooltip.Dungeon.Enable then
                for _, dungeonTable in ipairs(dungeons) do
                    local index, dungeonName = unpack(dungeonTable)
                    if E.db.RhythmBox.EnhancedTooltip.Dungeon[index] then
                        if leftTipText:find(dungeonName) then
                            local rightTip = _G[tooltip:GetName() .. 'TextRight' .. i]
                            leftTip:SetText(dungeonName)
                            rightTip:SetText(progressCache[guid].info.dungeon[index])
                            updated = true
                            break
                        end
                    end
                end
            end
        end
    end
    if updated then return end

    -- add progression tooltip line
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
            if E.db.RhythmBox.EnhancedTooltip.Dungeon[index] then
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
            if E.db.RhythmBox.EnhancedTooltip.Dungeon[k] then
                if k == 'MythicPlus' then
                    progressCache[guid].info.dungeon[k] = statFunc(v)
                elseif k == 'SeasonAchi' then
                    local result = ""
                    for index, tbl in ipairs(v) do
                        local high
                        local conqueror, master = unpack(tbl)
                        local completed = guid == E.myguid and select(4, GetAchievementInfo(master)) or GetAchievementComparisonInfo(master)
                        if completed then
                            high = 15
                        else
                            completed = guid == E.myguid and select(4, GetAchievementInfo(conqueror)) or GetAchievementComparisonInfo(conqueror)
                            high = completed and 10
                        end
                        result = format(
                            index == 1 and "|cff%sS%d|r" or "|cff%sS%d|r / ",
                            high == 15 and "a335ee" or (high == 10 and "0070dd" or "ee4735"),
                            index
                        ) .. result
                    end
                    progressCache[guid].info.dungeon[k] = result
                else
                    local mapID = tonumber(k)
                    if guid == E.myguid then
                        -- player
                        local affixScores, bestOverAllScore = C_MythicPlus_GetSeasonBestAffixScoreInfoForMap(mapID)
                        if affixScores then
                            local bestLevel = 0
                            local finishedSuccess = true
                            for _, data in ipairs(affixScores) do
                                if data.level > bestLevel or (data.level == bestLevel and not finishedSuccess) then
                                    bestLevel = data.level
                                    finishedSuccess = not data.overTime
                                end
                            end
                            if bestLevel > 0 then
                                local scoreColor = C_ChallengeMode_GetSpecificDungeonOverallScoreRarityColor(bestOverAllScore)
                                local levelColor = finishedSuccess and
                                    C_ChallengeMode_GetKeystoneLevelRarityColor(bestLevel) or
                                    GRAY_FONT_COLOR
                                bestOverAllScore = scoreColor:WrapTextInColorCode(bestOverAllScore)
                                bestLevel = levelColor:WrapTextInColorCode(bestLevel)

                                progressCache[guid].info.dungeon[k] = format('%s (%s)', bestOverAllScore, bestLevel)
                            else
                                progressCache[guid].info.dungeon[k] = '0'
                            end
                        else
                            progressCache[guid].info.dungeon[k] = '0'
                        end
                    else
                        -- other player
                        if info then
                            for _, data in ipairs(info.runs) do
                                if data.challengeModeID == mapID then
                                    local scoreColor = C_ChallengeMode_GetSpecificDungeonOverallScoreRarityColor(data.mapScore)
                                    local levelColor = data.finishedSuccess and
                                        C_ChallengeMode_GetKeystoneLevelRarityColor(data.bestRunLevel) or
                                        GRAY_FONT_COLOR
                                    local bestOverAllScore = scoreColor:WrapTextInColorCode(data.mapScore)
                                    local bestLevel = levelColor:WrapTextInColorCode(data.bestRunLevel)

                                    progressCache[guid].info.dungeon[k] = format('%s (%s)', bestOverAllScore, bestLevel)
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

function ETT:AddInspectInfo(_, tooltip, unit)
    if InCombatLockdown() then return end
    if not unit or not CanInspect(unit) then return end

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
        ["SeasonAchi"] = true,
    },
    ["Raid"] = {
        ["Enable"] = true,
        ["CN"] = true,
        ["SoD"] = true,
        ["SFO"] = true,
    },
}

-- Dynamic Generate Current Season Map Pool
for _, mapID in ipairs(mapChallengeModeIDs) do
    local mapIDText = tostring(mapID)

    tinsert(dungeons, {mapIDText, C_ChallengeMode.GetMapUIInfo(mapID)})
    database.Dungeon[mapIDText] = 0 -- dummy, no longer get total kill
    P["RhythmBox"]["EnhancedTooltip"]["Dungeon"][mapIDText] = true
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
    for index, value in ipairs(dungeons) do
        local abbr, name = unpack(value)
        E.Options.args.RhythmBox.args.EnhancedTooltip.args.Dungeon.args[abbr] = {
            order = index + 1,
            name = name,
            type = 'toggle',
        }
    end
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
    self:SecureHook(TT, 'AddInspectInfo')
end

R:RegisterModule(ETT:GetName())
