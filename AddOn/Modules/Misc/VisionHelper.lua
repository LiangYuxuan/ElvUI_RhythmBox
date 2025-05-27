-- Potions spellID and design taken from https://wago.io/kxredzlg9 by SnowElysium-夜織雪
-- Lost by hit tracking taken from https://wago.io/QqZFpQSZ4 by Permok

local R, E, L, V, P, G = unpack((select(2, ...)))
local VH = R:NewModule('VisionHelper', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions
local _G = _G
local abs, floor, format, ipairs, pairs = abs, floor, format, ipairs, pairs
local tinsert, tostring, sort, unpack, wipe = tinsert, tostring, sort, unpack, wipe

-- WoW API / Variables
local C_Map_GetBestMapForUnit = C_Map.GetBestMapForUnit
local C_Map_GetPlayerMapPosition = C_Map.GetPlayerMapPosition
local C_Spell_GetSpellLink = C_Spell.GetSpellLink
local C_Spell_GetSpellName = C_Spell.GetSpellName
local C_UnitAuras_GetPlayerAuraBySpellID = C_UnitAuras.GetPlayerAuraBySpellID
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local CreateFrame = CreateFrame
local GetTime = GetTime
local UnitName = UnitName

local utf8len = string.utf8len
local utf8sub = string.utf8sub

local Enum_PowerType_Alternate = Enum.PowerType.Alternate

local potionColor = {
    {'Black',  "黑", 106, 106, 106},
    {'Green',  "绿", 89,  201, 87 },
    {'Red',    "红", 243, 86,  115},
    {'Blue',   "蓝", 64,  126, 221},
    {'Purple', "紫", 174, 56,  175},
}
local potionType = {
    {"毒药"},
    {"理智"},
    {"减伤", 315849},
    {"回血", 315845},
    {"龙息", 315817},
}
local potionSpellID = {}
for _, data in ipairs(potionType) do
    if data[2] then
        potionSpellID[data[2]] = true
    end
end

local emergencySpellID = {
    -- Emergency Cranial Defibrillation
    [304816] = true,
    [317865] = true,
}

local visonSpellBlacklist = {
    [287769] = true, -- N'Zoth's Awareness
    [297176] = true, -- Mind Lost
}

local OrgrimmarZones = {
    {
        name = "虚灵",
        points = {
            {52.0, 68.4},
            {52.0, 72.4},
            {56.0, 72.4},
            {56.0, 68.4},
        },
        chest = 1,
        crystal = 0,
    },
    {
        name = "力量谷",
        points = {
            {43.8, 62.7},
            {47.2, 87.1},
            {55.2, 85.8},
            {52.1, 62.7},
        },
        chest = 3,
        crystal = 2,
    },
    {
        name = "精神谷",
        points = {
            {23.5, 61.7},
            {22.8, 87.9},
            {45.1, 87.5},
            {42.8, 60.0},
        },
        chest = 2,
        crystal = 2,
        questID = 57039,
    },
    {
        name = "智慧谷",
        points = {
            {36.8, 40.7},
            {36.7, 55.3},
            {53.1, 56.3},
            {53.0, 40.7},
        },
        chest = 2,
        crystal = 2,
        questID = 57129,
    },
    {
        name = "暗巷区",
        points = {
            {51.8, 45.4},
            {51.8, 66.0},
            {61.9, 66.0},
            {61.9, 45.6},
        },
        chest = 2,
        crystal = 2,
        questID = 57372,
    },
    {
        name = "荣誉谷",
        points = {
            {61.2, 25.8},
            {63.5, 54.3},
            {77.0, 54.1},
            {77.0, 26.0},
        },
        chest = 2,
        crystal = 2,
        questID = 57001,
    },
}

local StormwindZones = {
    {
        name = "虚灵",
        points = {
            {56.8, 48.1},
            {57.2, 48.9},
            {57.9, 48.2},
            {57.5, 47.3},
        },
        chest = 1,
        crystal = 0,
    },
    {
        name = "教堂区",
        points = {
            {43.3, 51.4},
            {52.2, 66.0},
            {63.7, 53.5},
            {54.9, 36.8},
        },
        chest = 3,
        crystal = 2,
    },
    {
        name = "矮人区",
        points = {
            {56.4, 32.2},
            {65.6, 51.8},
            {74.6, 42.3},
            {66.5, 23.6},
        },
        chest = 2,
        crystal = 2,
        questID = 57153,
    },
    {
        name = "旧城区",
        points = {
            {66.5, 56.3},
            {76.4, 75.7},
            {86.3, 63.8},
            {75.7, 45.0},
        },
        chest = 2,
        crystal = 2,
        questID = 57216,
    },
    {
        name = "贸易区",
        points = {
            {54.3, 67.7},
            {61.8, 82.5},
            {71.4, 71.2},
            {63.4, 57.6},
        },
        chest = 2,
        crystal = 2,
        questID = 57271,
    },
    {
        name = "法师区",
        points = {
            {39.1, 80.5},
            {48.2, 97.4},
            {59.9, 82.5},
            {50.5, 65.8},
        },
        chest = 2,
        crystal = 2,
        questID = 57282,
    },
}

local RevisitedOrgrimmarZones = {
    {
        name = "虚灵",
        points = {
            {52.0, 68.4},
            {52.0, 72.4},
            {56.0, 72.4},
            {56.0, 68.4},
        },
        chest = 0,
        crystal = 0,
    },
    {
        name = "力量谷",
        points = {
            {43.8, 62.7},
            {47.2, 87.1},
            {55.2, 85.8},
            {52.1, 62.7},
        },
        chest = 3,
        crystal = 0,
        clearSightLevel = 1,
    },
    {
        name = "精神谷",
        points = {
            {23.5, 61.7},
            {22.8, 87.9},
            {45.1, 87.5},
            {42.8, 60.0},
        },
        chest = 2,
        crystal = 0,
        questID = 85951,
        clearSightLevel = 2,
    },
    {
        name = "智慧谷",
        points = {
            {36.8, 40.7},
            {36.7, 55.3},
            {53.1, 56.3},
            {53.0, 40.7},
        },
        chest = 2,
        crystal = 0,
        questID = 85952,
        clearSightLevel = 3,
    },
    {
        name = "暗巷区",
        points = {
            {51.8, 45.4},
            {51.8, 66.0},
            {61.9, 66.0},
            {61.9, 45.6},
        },
        chest = 2,
        crystal = 0,
        questID = 85953,
        clearSightLevel = 2,
    },
    {
        name = "荣誉谷",
        points = {
            {61.2, 25.8},
            {63.5, 54.3},
            {77.0, 54.1},
            {77.0, 26.0},
        },
        chest = 2,
        crystal = 0,
        questID = 85950,
        clearSightLevel = 3,
    },
}

local RevisitedStormwindZones = {
    {
        name = "虚灵",
        points = {
            {56.8, 48.1},
            {57.2, 48.9},
            {57.9, 48.2},
            {57.5, 47.3},
        },
        chest = 0,
        crystal = 0,
    },
    {
        name = "教堂区",
        points = {
            {43.3, 51.4},
            {52.2, 66.0},
            {63.7, 53.5},
            {54.9, 36.8},
        },
        chest = 3,
        crystal = 0,
        clearSightLevel = 1,
    },
    {
        name = "矮人区",
        points = {
            {56.4, 32.2},
            {65.6, 51.8},
            {74.6, 42.3},
            {66.5, 23.6},
        },
        chest = 2,
        crystal = 0,
        questID = 85829,
        clearSightLevel = 2,
    },
    {
        name = "旧城区",
        points = {
            {66.5, 56.3},
            {76.4, 75.7},
            {86.3, 63.8},
            {75.7, 45.0},
        },
        chest = 2,
        crystal = 0,
        questID = 85832,
        clearSightLevel = 3,
    },
    {
        name = "贸易区",
        points = {
            {54.3, 67.7},
            {61.8, 82.5},
            {71.4, 71.2},
            {63.4, 57.6},
        },
        chest = 2,
        crystal = 0,
        questID = 85830,
        clearSightLevel = 2,
    },
    {
        name = "法师区",
        points = {
            {39.1, 80.5},
            {48.2, 97.4},
            {59.9, 82.5},
            {50.5, 65.8},
        },
        chest = 2,
        crystal = 0,
        questID = 85831,
        clearSightLevel = 3,
    },
}

local zoneQuestIDs = {}
local zoneConfigs = {
    [1469] = OrgrimmarZones,-- Vision of Orgrimmar
    [1470] = StormwindZones,-- Vision of Stormwind
    [2403] = RevisitedOrgrimmarZones,-- Vision of Orgrimmar
    [2404] = RevisitedStormwindZones,-- Vision of Stormwind
}
for _, config in pairs(zoneConfigs) do
    for _, data in ipairs(config) do
        if data.questID then
            zoneQuestIDs[data.questID] = true
        end
    end
end

local function ButtonOnEnter(self)
    self.highlight:Show()
end

local function ButtonOnLeave(self)
    self.highlight:Hide()
end

local function ButtonOnUpdate(self)
    if self.expirationTime then
        local restTime = floor(self.expirationTime - GetTime())
        if restTime < 0 then
            self.expirationTime = nil

            self.timerText:SetTextColor(1, 1, 1, 1)
            self.timerText:SetText()
        elseif restTime < 60 then
            self.timerText:SetTextColor(238 / 255, 71 / 255, 53 / 255, 1) -- Red
            self.timerText:SetText(restTime)
        else
            local minute = floor(restTime / 60)
            if minute < 5 then
                self.timerText:SetTextColor(252 / 255, 177 / 255, 3 / 255, 1) -- Yellow
            elseif VH.visionStartTime then
                if VH.visionStartTime + 1800 > self.expirationTime then
                    -- current potion buff lasts less than 30 mins after vision started
                    self.timerText:SetTextColor(1, 1, 1, 1) -- White
                else
                    self.timerText:SetTextColor(63 / 255, 63 / 255, 63 / 255, 1) -- Grey
                end
            elseif minute < 15 then -- fallbacks: didn't record start time, maybe after d/c
                self.timerText:SetTextColor(1, 1, 1, 1) -- White
            else
                self.timerText:SetTextColor(63 / 255, 63 / 255, 63 / 255, 1) -- Grey
            end
            self.timerText:SetText(format("%02d:%02d", minute, restTime - minute * 60))
        end
    end
end

local function ButtonOnClick(self)
    VH:ResetPotionButtons()
    VH.potionEffectFound = true

    local potionIndex = self.index
    for index, button in ipairs(VH.buttons) do
        local typeIndex = index - potionIndex + 1
        if typeIndex < 1 then
            typeIndex = typeIndex + 5
        end

        local text, spellID = unpack(potionType[typeIndex])
        button.colorText:SetText(text)
        if spellID then
            VH.potionButtonMap[spellID] = button
            button:SetScript('OnUpdate', ButtonOnUpdate)
        end
    end

    VH:RegisterEvent('UNIT_AURA')
end

local function IndicatorOnEnter(self)
    local gainRecord, lostRecord = VH:GetSortedRecord()

    local GameTooltip = _G.GameTooltip
    GameTooltip:Hide()
    GameTooltip:SetOwner(self, 'ANCHOR_NONE')
    GameTooltip:ClearAllPoints()
    GameTooltip:SetPoint('TOPLEFT', self, 'TOPRIGHT', 2, 0)
    GameTooltip:ClearLines()

    GameTooltip:AddLine("理智技能统计")
    GameTooltip:AddDoubleLine("获得理智", VH.prevGain, 1, 210 / 255, 0, 1, 1, 1)
    for index, data in pairs(gainRecord) do
        local spellID, amount = unpack(data)
        local spellName = C_Spell_GetSpellName(spellID) or spellID
        GameTooltip:AddDoubleLine(index .. ". " .. spellName, format("%d (%.1f%%)", amount, amount / VH.prevGain * 100), 1, 1, 1, 1, 1, 1)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("失去理智", VH.prevLost, 1, 210 / 255, 0, 1, 1, 1)
    for index, data in pairs(lostRecord) do
        local spellID, amount = unpack(data)
        local spellName = C_Spell_GetSpellName(spellID) or spellID
        GameTooltip:AddDoubleLine(index .. ". " .. spellName, format("%d (%.1f%%)", amount, amount / VH.prevLost * 100), 1, 1, 1, 1, 1, 1)
    end

    GameTooltip:Show()
end

local function IndicatorOnLeave(self)
    _G.GameTooltip:Hide()
end

local function IndicatorOnClick(self)
    local gainRecord, lostRecord = VH:GetSortedRecord()

    R:Print("理智技能统计")
    R:Print("%-20s%d", "获得理智", VH.prevGain)
    for index, data in pairs(gainRecord) do
        local spellID, amount = unpack(data)
        local spellLink = C_Spell_GetSpellLink(spellID) or C_Spell_GetSpellName(spellID) or spellID
        R:Print("%d. %-20s%d (%.1f%%)", index, spellLink, amount, amount / VH.prevGain * 100)
    end

    R:Print(" ")
    R:Print("%-20s%d", "失去理智", VH.prevLost)
    for index, data in pairs(lostRecord) do
        local spellID, amount = unpack(data)
        local spellLink = C_Spell_GetSpellLink(spellID) or C_Spell_GetSpellName(spellID) or spellID
        R:Print("%d. %-20s%d (%.1f%%)", index, spellLink, amount, amount / VH.prevLost * 100)
    end
end

function VH:ResetPotionButtons()
    for index, button in ipairs(self.buttons) do
        button:SetScript('OnUpdate', nil)
        button.expirationTime = nil

        button.colorText:SetText(potionColor[index][2])
        button.timerText:SetTextColor(1, 1, 1, 1)
        button.timerText:SetText()
    end
end

function VH:ResetAll(uiMapID)
    wipe(self.potionButtonMap)
    wipe(self.gainRecord)
    wipe(self.lostRecord)
    wipe(self.chestRecord)
    wipe(self.crystalRecord)
    wipe(self.questLog)

    self.prevLost = 0
    self.prevGain = 0
    self.sortedRecordReady = nil
    self.visionStartTime = nil
    self.crystalCollected = nil
    self.potionEffectFound = nil
    self:ResetPotionButtons()

    local clearSightLevel = 0
    if C_UnitAuras_GetPlayerAuraBySpellID(472248) then -- Clear Sight Rank 3
        clearSightLevel = 3
    elseif C_UnitAuras_GetPlayerAuraBySpellID(472246) then -- Clear Sight Rank 2
        clearSightLevel = 2
    elseif C_UnitAuras_GetPlayerAuraBySpellID(472238) then -- Clear Sight Rank 1
        clearSightLevel = 1
    end

    local datas = zoneConfigs[uiMapID]
    for index, frames in ipairs(self.recordFrames) do
        if datas[index].clearSightLevel then
            if clearSightLevel < datas[index].clearSightLevel then
                datas[index].chestBak = datas[index].chest
                datas[index].chest = 0
            elseif datas[index].chestBak then
                datas[index].chest = datas[index].chestBak
                datas[index].chestBak = nil
            end
        end

        frames[1].locationDesc:SetTextColor(1, 1, 1, 1)
        frames[1].locationDesc:SetText(datas[index].name)
        frames[1].texture:SetVertexColor(156 / 255, 154 / 255, 138 / 255, 1)
        frames[1].text:SetText("0/" .. datas[index].chest)
        if frames[2] then
            frames[2].texture:SetVertexColor(156 / 255, 154 / 255, 138 / 255, 1)
            frames[2].text:SetText("0/" .. datas[index].crystal)
        end
    end

    self.lostByHit.valueText:SetText('0')

    if (
        C_UnitAuras_GetPlayerAuraBySpellID(472161) or -- Emergency Cranial Defibrillation
        C_UnitAuras_GetPlayerAuraBySpellID(304815) -- Emergency Cranial Defibrillation
    ) then
        self.emergencyIndicator.valueText:SetTextColor(1, 1, 1, 1)
        self.emergencyIndicator.valueText:SetText("未触发")
    else
        self.emergencyIndicator.valueText:SetTextColor(63 / 255, 63 / 255, 63 / 255, 1)
        self.emergencyIndicator.valueText:SetText("无")
    end
end

function VH:UpdateIndicator()
    -- Update Location Indicator
    local uiMapID = E.MapInfo.mapID
    if E.MapInfo.x and E.MapInfo.y and uiMapID and zoneConfigs[uiMapID] then
        local data = zoneConfigs[uiMapID]
        local currIndex = self:FindMatchingZone(E.MapInfo.x * 100, E.MapInfo.y * 100)
        for index, frames in ipairs(self.recordFrames) do
            if currIndex and currIndex == index then
                if (
                    (not data[index].questID or self.questLog[data[index].questID]) and
                    (self.chestRecord[index] or 0) >= data[index].chest and
                    (not frames[2] or (self.crystalRecord[index] or 0) >= data[index].crystal)
                ) then
                    frames[1].locationDesc:SetTextColor(31 / 255, 219 / 255, 81 / 255, 1) -- Green
                else
                    frames[1].locationDesc:SetTextColor(252 / 255, 177 / 255, 3 / 255, 1) -- Yellow
                end
                if (self.chestRecord[index] or 0) < data[index].chest then
                    frames[1].texture:SetVertexColor(208 / 255, 235 / 255, 52 / 255, 1) -- Yellow
                end
                if frames[2] and (self.crystalRecord[index] or 0) < data[index].crystal then
                    frames[2].texture:SetVertexColor(208 / 255, 235 / 255, 52 / 255, 1) -- Yellow
                end
            elseif self.crystalCollected and currIndex and currIndex == 2 and index == 1 then
                -- in Tainted Zone, and collected more than one crystal
                if (self.chestRecord[index] or 0) < data[index].chest then
                    -- crystal chest not looted
                    frames[1].locationDesc:SetTextColor(1, 1, 1, 1)
                    frames[1].texture:SetVertexColor(235 / 255, 57 / 255, 54 / 255, 1) -- Red
                else
                    -- crystal chest looted
                    frames[1].locationDesc:SetTextColor(63 / 255, 63 / 255, 63 / 255, 1) -- Grey
                end
            else
                if data[index].questID and self.questLog[data[index].questID] == false then
                    -- on quest and not complete and not current zone
                    frames[1].locationDesc:SetTextColor(238 / 255, 71 / 255, 53 / 255, 1) -- Red
                elseif (
                    (not data[index].questID or self.questLog[data[index].questID]) and
                    (self.chestRecord[index] or 0) >= data[index].chest and
                    (not frames[2] or (self.crystalRecord[index] or 0) >= data[index].crystal)
                ) then
                    frames[1].locationDesc:SetTextColor(63 / 255, 63 / 255, 63 / 255, 1) -- Grey
                else
                    frames[1].locationDesc:SetTextColor(1, 1, 1, 1)
                end
                if (self.chestRecord[index] or 0) < data[index].chest then
                    frames[1].texture:SetVertexColor(156 / 255, 154 / 255, 138 / 255, 1)
                end
                if frames[2] and (self.crystalRecord[index] or 0) < data[index].crystal then
                    frames[2].texture:SetVertexColor(156 / 255, 154 / 255, 138 / 255, 1)
                end
            end
        end
    end

    -- Update GameTooltip
    if self.potionEffectFound then
        local text = _G.GameTooltipTextLeft1 and _G.GameTooltipTextLeft1:GetText()
        if not text or text == '' then return end

        if utf8len(text) == 9 then
            local color = utf8sub(text, 6, 6)
            for index, data in ipairs(potionColor) do
                if color == data[2] then
                    _G.GameTooltipTextLeft1:SetText(text .. " (" .. self.buttons[index].colorText:GetText() .. ")")
                    _G.GameTooltip:Show()
                    return
                end
            end
        end
    end
end

function VH:CheckZone()
    local uiMapID = C_Map_GetBestMapForUnit('player')
    if uiMapID and zoneConfigs[uiMapID] then
        if not self.container:IsShown() then
            self:ResetAll(uiMapID)

            self.timer = self:ScheduleRepeatingTimer('UpdateIndicator', .2)

            -- UNIT_AURA registered when button on click
            self:RegisterEvent('UNIT_SPELLCAST_START')
            self:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
            self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
            self:RegisterEvent('QUEST_ACCEPTED')
            self:RegisterEvent('QUEST_TURNED_IN')
            self.container:Show()
        end
    else
        self:ResetPotionButtons()

        if self.timer then
            self:CancelTimer(self.timer)
            self.timer = nil
        end

        self:UnregisterEvent('UNIT_AURA')
        self:UnregisterEvent('UNIT_SPELLCAST_START')
        self:UnregisterEvent('UNIT_SPELLCAST_SUCCEEDED')
        self:UnregisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
        self:UnregisterEvent('QUEST_ACCEPTED')
        self:UnregisterEvent('QUEST_TURNED_IN')
        self.container:Hide()
    end
end

function VH:UNIT_AURA(_, unit)
    if unit ~= 'player' then return end

    for spellID in pairs(potionSpellID) do
        if self.potionButtonMap[spellID] then
            local info = C_UnitAuras_GetPlayerAuraBySpellID(spellID)
            local expirationTime = info and info.expirationTime

            if expirationTime then
                self.potionButtonMap[spellID].expirationTime = expirationTime
            elseif self.potionButtonMap[spellID].expirationTime then
                -- aura removed by player
                self.potionButtonMap[spellID].expirationTime = 0 -- set to zero to let it handle by OnUpdate
            end
        end
    end
end

function VH:UNIT_SPELLCAST_START(_, _, _, spellID)
    if spellID == 311996 then
        self.visionStartTime = GetTime()
        self:UnregisterEvent('UNIT_SPELLCAST_START')
    end
end

function VH:UNIT_SPELLCAST_SUCCEEDED(_, unitID, _, spellID)
    if spellID == 306608 and unitID == 'player' then -- Cleansing (Chest)
        local index, data = self:FindMatchingZone(E.MapInfo.x * 100, E.MapInfo.y * 100)
        if not index or not data then
            -- not matching, is an issue!
            R:Print("WARNING: Chest opened by player, but not matching any zone! Player is at (%.2f, %.2f).", E.MapInfo.x * 100, E.MapInfo.y * 100)
        else
            self.chestRecord[index] = self.chestRecord[index] or 0
            self.chestRecord[index] = self.chestRecord[index] + 1

            if self.chestRecord[index] >= data.chest then
                self.recordFrames[index][1].texture:SetVertexColor(52 / 255, 235 / 255, 82 / 255, 1) -- Green
            end
            self.recordFrames[index][1].text:SetText(self.chestRecord[index] .. "/" .. data.chest)
        end
    elseif (
        spellID == 143394 and
        (unitID == 'player' or unitID == 'party1' or unitID == 'party2' or unitID == 'party3' or unitID == 'party4')
    ) then -- Collecting (Crystal)
        self.crystalCollected = true
        local x, y = E.MapInfo.x * 100, E.MapInfo.y * 100
        if unitID ~= 'player' then
            local position = C_Map_GetPlayerMapPosition(E.MapInfo.mapID or 0, unitID)
            if position then
                x, y = position.x * 100, position.y * 100
            end
        end
        local index, data = self:FindMatchingZone(x, y)
        if not index or not data then
            -- not matching, is an issue!
            R:Print(
                "WARNING: Crystal collected by %s, but not matching any zone! %s is at (%.2f, %.2f).",
                unitID == 'player' and "player" or UnitName(unitID), unitID, x, y
            )
        else
            self.crystalRecord[index] = self.crystalRecord[index] or 0
            self.crystalRecord[index] = self.crystalRecord[index] + 1

            if self.crystalRecord[index] >= data.crystal then
                self.recordFrames[index][2].texture:SetVertexColor(52 / 255, 235 / 255, 82 / 255, 1) -- Green
            end
            self.recordFrames[index][2].text:SetText(self.crystalRecord[index] .. "/" .. data.crystal)
        end
    end
end

function VH:COMBAT_LOG_EVENT_UNFILTERED()
    local _, subEvent, _, _, _, _, _, destGUID, _, _, _, spellID, _, _, amount, _, powerType, altPowerType = CombatLogGetCurrentEventInfo()

    ---@cast spellID number
    if destGUID == E.myguid and emergencySpellID[spellID] then
        self.emergencyIndicator.valueText:SetTextColor(238 / 255, 71 / 255, 53 / 255, 1)
        self.emergencyIndicator.valueText:SetText("已触发")
    elseif (
        (subEvent == 'SPELL_ENERGIZE' or subEvent == 'SPELL_PERIODIC_ENERGIZE' or subEvent == 'SPELL_BUILDING_ENERGIZE') and
        destGUID == E.myguid and powerType == Enum_PowerType_Alternate and altPowerType == 554 and
        not visonSpellBlacklist[spellID] and amount
    ) then
        if amount < 0 then
            self.lostRecord[spellID] = (self.lostRecord[spellID] or 0) + amount
            self.prevLost = self.prevLost + amount
            self.lostByHit.valueText:SetText(tostring(self.prevLost))
        elseif amount > 0 then
            self.gainRecord[spellID] = (self.gainRecord[spellID] or 0) + amount
            self.prevGain = self.prevGain + amount
        end
        self.sortedRecordReady = nil
    end
end

function VH:QUEST_ACCEPTED(_, questID)
    if zoneQuestIDs[questID] then
        self.questLog[questID] = false
    end
end

function VH:QUEST_TURNED_IN(_, questID)
    if zoneQuestIDs[questID] then
        self.questLog[questID] = true
    end
end

function VH:GetSortedRecord()
    if not self.sortedRecordReady then
        wipe(self.sortedGainRecord)
        wipe(self.sortedLostRecord)

        for spellID, amount in pairs(self.gainRecord) do
            tinsert(self.sortedGainRecord, {spellID, amount})
        end
        for spellID, amount in pairs(self.lostRecord) do
            tinsert(self.sortedLostRecord, {spellID, amount})
        end

        self.amountSortFunc = self.amountSortFunc or function(left, right)
            return abs(left[2]) > abs(right[2])
        end
        sort(self.sortedGainRecord, self.amountSortFunc)
        sort(self.sortedLostRecord, self.amountSortFunc)

        self.sortedRecordReady = true
    end

    return self.sortedGainRecord, self.sortedLostRecord
end

function VH:FindMatchingZone(x, y)
    local uiMapID = E.MapInfo.mapID
    if not uiMapID or not zoneConfigs[uiMapID] then return end

    for index, data in ipairs(zoneConfigs[uiMapID]) do
        if self:IsInZone(x, y, data.points) then
            return index, data
        end
    end
end

function VH:IsInZone(x, y, points)
    local direction
    for index, point in ipairs(points) do
        local nextPoint = points[index + 1] or points[1]

        -- vector from current point to next point
        local lineX = nextPoint[1] - point[1]
        local lineY = nextPoint[2] - point[2]

        -- vector from current point to player point
        local vectorX = x - point[1]
        local vectorY = y - point[2]

        local crossProduct = (lineX * vectorY) - (lineY * vectorX)
        if not direction then
            direction = crossProduct
        elseif (direction > 0) ~= (crossProduct > 0) then
            return false
        end
    end
    return true
end

function VH:CreateSimpleIndicator(xOffset, yOffset, width, defaultText, r, g, b)
    ---@class VisionHelperSimpleIndicator: Button
    ---@field locationDesc FontString?
    local frame = CreateFrame('Button', nil, self.container)
    frame:ClearAllPoints()
    frame:SetPoint('TOPLEFT', self.container, 'TOPLEFT', xOffset, yOffset)
    frame:SetSize(width, 40)
    frame:EnableMouse(false)

    frame.texture = frame:CreateTexture(nil, 'BACKGROUND')
    frame.texture:SetAllPoints()
    frame.texture:SetTexture('Interface/Addons/WeakAuras/Media/Textures/Square_White_Border')
    frame.texture:SetTexCoord(.1, .9, .1, .9)
    frame.texture:SetVertexColor(r / 255, g / 255, b / 255, 1)

    frame.text = frame:CreateFontString(nil, 'OVERLAY')
    frame.text:FontTemplate(nil, 24)
    frame.text:SetTextColor(1, 1, 1, 1)
    frame.text:SetPoint('CENTER', frame, 'CENTER', 0, 0)
    frame.text:SetJustifyH('CENTER')
    frame.text:SetText(defaultText)

    return frame
end

function VH:CreateIndicator(xOffset, yOffset, descText, valueText, r, g, b)
    ---@class VisionHelperIndicator: Button
    local frame = CreateFrame('Button', nil, self.container)
    frame:ClearAllPoints()
    frame:SetPoint('TOPLEFT', self.container, 'TOPLEFT', xOffset, yOffset)
    frame:SetSize(70, 40)
    frame:EnableMouse(false)

    frame.texture = frame:CreateTexture(nil, 'BACKGROUND')
    frame.texture:SetAllPoints()
    frame.texture:SetTexture('Interface/Addons/WeakAuras/Media/Textures/Square_White_Border')
    frame.texture:SetTexCoord(.1, .9, .1, .9)
    frame.texture:SetVertexColor(r / 255, g / 255, b / 255, 1)

    frame.descText = frame:CreateFontString(nil, 'OVERLAY')
    frame.descText:FontTemplate(nil, 24)
    frame.descText:SetTextColor(1, 1, 1, 1)
    frame.descText:SetPoint('CENTER', frame, 'CENTER', 0, 0)
    frame.descText:SetJustifyH('CENTER')
    frame.descText:SetText(descText)

    frame.valueText = frame:CreateFontString(nil, 'OVERLAY')
    frame.valueText:FontTemplate(nil, 24)
    frame.valueText:SetTextColor(1, 1, 1, 1)
    frame.valueText:SetPoint('LEFT', frame, 'RIGHT', 5, 0)
    frame.valueText:SetJustifyH('LEFT')
    frame.valueText:SetText(valueText)

    return frame
end

function VH:CreatePotionButton(xOffset, yOffset, colorText, r, g, b)
    ---@class VisionHelperPotionButton: Button
    ---@field index number?
    local button = CreateFrame('Button', nil, self.container)
    button:ClearAllPoints()
    button:SetPoint('TOPLEFT', self.container, 'TOPLEFT', xOffset, yOffset)
    button:SetSize(70, 40)

    button:EnableMouse(true)
    button:RegisterForClicks('AnyUp')
    button:SetScript('OnEnter', ButtonOnEnter)
    button:SetScript('OnLeave', ButtonOnLeave)
    button:SetScript('OnClick', ButtonOnClick)

    button.texture = button:CreateTexture(nil, 'BACKGROUND')
    button.texture:SetAllPoints()
    button.texture:SetTexture('Interface/Addons/WeakAuras/Media/Textures/Square_White_Border')
    button.texture:SetTexCoord(.1, .9, .1, .9)
    button.texture:SetVertexColor(r / 255, g / 255, b / 255, 1)

    button.highlight = button:CreateTexture(nil, 'OVERLAY')
    button.highlight:SetAllPoints()
    button.highlight:SetTexture(E.Media.Textures.White8x8)
    button.highlight:SetBlendMode('ADD')
    button.highlight:SetAlpha(.4)
    button.highlight:Hide()

    button.colorText = button:CreateFontString(nil, 'OVERLAY')
    button.colorText:FontTemplate(nil, 24)
    button.colorText:SetTextColor(1, 1, 1, 1)
    button.colorText:SetPoint('CENTER', button, 'CENTER', 0, 0)
    button.colorText:SetJustifyH('CENTER')
    button.colorText:SetText(colorText)

    button.timerText = button:CreateFontString(nil, 'OVERLAY')
    button.timerText:FontTemplate(nil, 24)
    button.timerText:SetTextColor(1, 1, 1, 1)
    button.timerText:SetPoint('LEFT', button, 'RIGHT', 5, 0)
    button.timerText:SetJustifyH('LEFT')
    button.timerText:SetText()

    return button
end

function VH:Initialize()
    local frameName = 'RhythmBoxVHContainer'
    self.container = CreateFrame('Frame', frameName, E.UIParent)

    self.lostByHit = self:CreateIndicator(0, 0, "额外", "0", 92, 92, 237)
    self.emergencyIndicator = self:CreateIndicator(0, -40, "春哥", "未触发", 247, 234, 54)

    self.lostByHit:SetScript('OnEnter', IndicatorOnEnter)
    self.lostByHit:SetScript('OnLeave', IndicatorOnLeave)
    self.lostByHit:SetScript('OnClick', IndicatorOnClick)

    self.buttons = {}
    for index, tbl in ipairs(potionColor) do
        local _, name, r, g, b = unpack(tbl)

        local button = self:CreatePotionButton(0, -40 * index - 40, name, r, g, b)
        button.index = index

        self.buttons[index] = button
    end

    self.recordFrames = {}
    for index, data in ipairs(StormwindZones) do
        if index == 1 then
            local chestFrame = self:CreateSimpleIndicator(260, -40, 140, "0/" .. data.chest, 156, 154, 138)

            self.recordFrames[index] = {}
            self.recordFrames[index][1] = chestFrame

            chestFrame.locationDesc = chestFrame:CreateFontString(nil, 'OVERLAY')
            chestFrame.locationDesc:FontTemplate(nil, 24)
            chestFrame.locationDesc:SetTextColor(1, 1, 1, 1)
            chestFrame.locationDesc:SetPoint('RIGHT', chestFrame, 'LEFT', 0, 0)
            chestFrame.locationDesc:SetJustifyH('RIGHT')
            chestFrame.locationDesc:SetText(data.name)

            local chestDesc = chestFrame:CreateFontString(nil, 'OVERLAY')
            chestDesc:FontTemplate(nil, 24)
            chestDesc:SetTextColor(1, 1, 1, 1)
            chestDesc:SetPoint('BOTTOM', chestFrame, 'TOP', -35, 0)
            chestDesc:SetJustifyH('CENTER')
            chestDesc:SetText("宝箱")

            local crystalDesc = chestFrame:CreateFontString(nil, 'OVERLAY')
            crystalDesc:FontTemplate(nil, 24)
            crystalDesc:SetTextColor(1, 1, 1, 1)
            crystalDesc:SetPoint('BOTTOM', chestFrame, 'TOP', 35, 0)
            crystalDesc:SetJustifyH('CENTER')
            crystalDesc:SetText("水晶")
        else
            local chestFrame = self:CreateSimpleIndicator(260, -40 * index, 70, "0/" .. data.chest, 156, 154, 138)
            local crystalFrame = self:CreateSimpleIndicator(330, -40 * index, 70, "0/" .. data.crystal, 156, 154, 138)

            self.recordFrames[index] = {}
            self.recordFrames[index][1] = chestFrame
            self.recordFrames[index][2] = crystalFrame

            chestFrame.locationDesc = chestFrame:CreateFontString(nil, 'OVERLAY')
            chestFrame.locationDesc:FontTemplate(nil, 24)
            chestFrame.locationDesc:SetTextColor(1, 1, 1, 1)
            chestFrame.locationDesc:SetPoint('RIGHT', chestFrame, 'LEFT', 0, 0)
            chestFrame.locationDesc:SetJustifyH('RIGHT')
            chestFrame.locationDesc:SetText(data.name)
        end
    end

    self.container:SetSize(400, 280)
    self.container:SetPoint('TOPLEFT', E.UIParent, 'TOPLEFT', 0, -190)
    E:CreateMover(self.container, frameName .. 'Mover', "Rhythm Box 惊魂幻象助手", nil, nil, nil, 'ALL,RHYTHMBOX')

    -- address d/c issue in vision, hide the container first, then :CheckZone will register events
    self.container:Hide()

    self.potionButtonMap = {}
    self.gainRecord = {}
    self.lostRecord = {}
    self.chestRecord = {}
    self.crystalRecord = {}

    -- inner usage
    self.sortedGainRecord = {}
    self.sortedLostRecord = {}
    self.questLog = {}

    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'CheckZone')
    self:RegisterEvent('ZONE_CHANGED', 'CheckZone')
    self:RegisterEvent('ZONE_CHANGED_INDOORS', 'CheckZone')
    self:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'CheckZone')
end

R:RegisterModule(VH:GetName())
