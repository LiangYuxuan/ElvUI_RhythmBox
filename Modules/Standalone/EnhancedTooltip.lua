-- From ElvUI_WindTools
-- https://github.com/fang2hou/ElvUI_WindTools/blob/master/Modules/Interface/EnhancedTooltip.lua

local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local ETT = R:NewModule('EnhancedTooltip', 'AceEvent-3.0', 'AceHook-3.0')
local TT  = E:GetModule('Tooltip')

-- Lua functions
local _G = _G
local format, ipairs, pairs, select, strsub = format, ipairs, pairs, select, strsub
local tonumber, unpack, wipe = tonumber, unpack, wipe

-- WoW API / Variables
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

local MAX_PLAYER_LEVEL = MAX_PLAYER_LEVEL

local progressCache = {}

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
    {'EP',    "永恒王宫"},
    {'CoS',   "风暴熔炉"},
    {'BoD',   "达萨罗之战"},
    {'Uldir', "奥迪尔"},
}

local database = {
    ['Raid'] = {
        ['Uldir'] = {
            ['Mythic'] = {
                12789, 12793, 12797, 12801, 12805, 12811, 12816, 12820,
            },
            ['Heroic'] = {
                12788, 12792, 12796, 12800, 12804, 12810, 12815, 12819,
            },
            ['Normal'] = {
                12787, 12791, 12795, 12799, 12803, 12809, 12814, 12818,
            },
            ['LFR'] = {
                12786, 12790, 12794, 12798, 12802, 12808, 12813, 12817,
            },
        },
        ['BoD'] = {
            ['Alliance'] = {
                ['Mythic'] = {
                    13331, 13353, 13348, 13362, 13366, 13370, 13374, 13378, 13382,
                },
                ['Heroic'] = {
                    13330, 13351, 13347, 13361, 13365, 13369, 13373, 13377, 13381,
                },
                ['Normal'] = {
                    13329, 13350, 13346, 13359, 13364, 13368, 13372, 13376, 13380,
                },
                ['LFR'] = {
                    13328, 13349, 13344, 13358, 13363, 13367, 13371, 13375, 13379,
                },
            },
            ['Horde'] = {
                ['Mythic'] = {
                    13331, 13336, 13357, 13374, 13378, 13382, 13362, 13366, 13370,
                },
                ['Heroic'] = {
                    13330, 13334, 13356, 13373, 13377, 13381, 13361, 13365, 13369,
                },
                ['Normal'] = {
                    13329, 13333, 13355, 13372, 13376, 13380, 13359, 13364, 13368,
                },
                ['LFR'] = {
                    13328, 13332, 13354, 13371, 13375, 13379, 13358, 13363, 13367,
                },
            },
        },
        ['CoS'] = {
            ['Mythic'] = {
                13407, 13413,
            },
            ['Heroic'] = {
                13406, 13412,
            },
            ['Normal'] = {
                13405, 13411,
            },
            ['LFR'] = {
                13404, 13408,
            },
        },
        ['EP'] = {
            ['Mythic'] = {
                13590, 13594, 13598, 13603, 13607, 13611, 13615, 13619,
            },
            ['Heroic'] = {
                13589, 13593, 13597, 13602, 13606, 13610, 13614, 13618,
            },
            ['Normal'] = {
                13588, 13592, 13596, 13601, 13605, 13609, 13613, 13617,
            },
            ['LFR'] = {
                13587, 13591, 13595, 13600, 13604, 13608, 13612, 13616,
            },
        },
    },
    ['Dungeon'] = {
        ['MythicPlus'] = 7399,
        ['SeasonAchi'] = {
            {13079, 13080}, -- Season One
            {13448, 13449}, -- Season Two
            {13780, 13781}, -- Season Three
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
                                local rightTip = _G[tooltip:GetName() .. 'TextRight' .. i]
                                leftTip:SetText(format("%s %s:", tierName, self:GetColorLevel(level, levelName, false)))
                                rightTip:SetText(format("%s%s", self:GetColorLevel(level, levelName, true), progressCache[guid].info.raid[tier][level]))
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
                            high == 15 and "a335ee" or (high == 10 and "0070dd" or "ff8000"),
                            index
                        ) .. result
                    end
                    progressCache[guid].info.dungeon[k] = result
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

function ETT:AddInspectInfo(_, tooltip, unit, numTries, r, g, b)
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
        ["Uldir"] = false,
        ["BoD"] = true,
        ["CoS"] = true,
        ["EP"] = true,
    },
}

local function TooltipOptions()
    E.Options.args.RhythmBox.args.EnhancedTooltip = {
        order = 6,
        type = 'group',
        name = "增强鼠标提示",
        get = function(info) return E.db.RhythmBox.EnhancedTooltip[info[#info]] end,
        set = function(info, value) E.db.RhythmBox.EnhancedTooltip[info[#info]] = value end,
        args = {
            Enable = {
                order = 1,
                type = 'toggle',
                name = "启用",
                set = function(info, value) E.db.RhythmBox.EnhancedTooltip[info[#info]] = value; ETT:Initialize() end,
            },
            Dungeon = {
                name = "地下城",
                order = 2,
                type = 'group',
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
    if E.db.RhythmBox.EnhancedTooltip.Enable and not self.hooking then
        self.hooking = true
        self:SecureHook(TT, 'AddInspectInfo')
    elseif self.hooking then
        self.hooking = nil
        self:Unhook(TT, 'AddInspectInfo')
    end
end

R:RegisterModule(ETT:GetName())