-- Potions spellID and design taken from https://wago.io/kxredzlg9 by SnowElysium-夜織雪
-- Lost by hit tracking taken from https://wago.io/QqZFpQSZ4 by Permok

local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local VH = R:NewModule('VisionHelper', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions
local ipairs, floor, format, pairs, unpack, wipe = ipairs, floor, format, pairs, unpack, wipe

-- WoW API / Variables
local C_Map_GetBestMapForUnit = C_Map.GetBestMapForUnit
local C_Map_GetPlayerMapPosition = C_Map.GetPlayerMapPosition
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local CreateFrame = CreateFrame
local GetSpellLink = GetSpellLink
local GetTime = GetTime
local UnitAura = UnitAura
local UnitName = UnitName

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
    },
}

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
            if minute > 14 then
                self.timerText:SetTextColor(63 / 255, 63 / 255, 63 / 255, 1) -- Grey
            elseif minute > 4 then
                self.timerText:SetTextColor(1, 1, 1, 1) -- White
            else
                self.timerText:SetTextColor(252 / 255, 177 / 255, 3 / 255, 1) -- Yellow
            end
            self.timerText:SetText(format("%02d:%02d", minute, restTime - minute * 60))
        end
    end
end

local function ButtonOnClick(self)
    VH:ResetPotionButtons()

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
    wipe(self.chestRecord)
    wipe(self.crystalRecord)

    self.prevLost = 0
    self.crystalCollected = nil
    self:ResetPotionButtons()

    local datas = uiMapID == 1469 and OrgrimmarZones or StormwindZones
    for index, frames in ipairs(self.recordFrames) do
        frames[1].locationDesc:SetTextColor(1, 1, 1, 1)
        frames[1].locationDesc:SetText(datas[index].name)
        frames[1].texture:SetVertexColor(156 / 255, 154 / 255, 138 / 255, 1)
        frames[1].text:SetText("0/" .. datas[index].chest)
        if frames[2] then
            frames[2].texture:SetVertexColor(156 / 255, 154 / 255, 138 / 255, 1)
            frames[2].text:SetText("0/" .. datas[index].crystal)
        end
    end

    self.lostByHit.valueText:SetText(0)
    self.emergencyIndicator.valueText:SetTextColor(1, 1, 1, 1)
    self.emergencyIndicator.valueText:SetText("未触发")
end

function VH:UpdateLocation()
    if not E.MapInfo.x or not E.MapInfo.y then return end

    local currIndex = self:FindMatchingZone(E.MapInfo.x * 100, E.MapInfo.y * 100)
    for index, frames in ipairs(self.recordFrames) do
        if currIndex and currIndex == index then
            frames[1].locationDesc:SetTextColor(252 / 255, 177 / 255, 3 / 255, 1) -- Yellow
            if (self.chestRecord[index] or 0) < StormwindZones[index].chest then
                frames[1].texture:SetVertexColor(208 / 255, 235 / 255, 52 / 255, 1) -- Yellow
            end
            if frames[2] and (self.crystalRecord[index] or 0) < StormwindZones[index].crystal then
                frames[2].texture:SetVertexColor(208 / 255, 235 / 255, 52 / 255, 1) -- Yellow
            end
        elseif self.crystalCollected and currIndex and currIndex == 2 and index == 1 then
            -- in Tainted Zone, and collected more than one crystal, and crystal chest not looted
            frames[1].locationDesc:SetTextColor(1, 1, 1, 1)
            if (self.chestRecord[index] or 0) < StormwindZones[index].chest then
                frames[1].texture:SetVertexColor(235 / 255, 57 / 255, 54 / 255, 1) -- Red
            end
        else
            frames[1].locationDesc:SetTextColor(1, 1, 1, 1)
            if (self.chestRecord[index] or 0) < StormwindZones[index].chest then
                frames[1].texture:SetVertexColor(156 / 255, 154 / 255, 138 / 255, 1)
            end
            if frames[2] and (self.crystalRecord[index] or 0) < StormwindZones[index].crystal then
                frames[2].texture:SetVertexColor(156 / 255, 154 / 255, 138 / 255, 1)
            end
        end
    end
end

function VH:CheckZone()
    local uiMapID = C_Map_GetBestMapForUnit('player')
    if uiMapID and (
        uiMapID == 1469 or -- Vision of Orgrimmar
        uiMapID == 1470    -- Vision of Stormwind
    ) then
        if not self.container:IsShown() then
            self:ResetAll(uiMapID)

            self.timer = self:ScheduleRepeatingTimer('UpdateLocation', .2)

            self:RegisterEvent('UNIT_AURA')
            self:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
            self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
            self.container:Show()
        end
    else
        self:ResetPotionButtons()

        if self.timer then
            self:CancelTimer(self.timer)
            self.timer = nil
        end

        self:UnregisterEvent('UNIT_AURA')
        self:UnregisterEvent('UNIT_SPELLCAST_SUCCEEDED')
        self:UnregisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
        self.container:Hide()
    end
end

function VH:UNIT_AURA(_, unit)
    if unit ~= 'player' then return end

    wipe(self.potionFound)
    for i = 1, 40 do
        local _, _, _, _, _, expirationTime, _, _, _, spellID = UnitAura('player', i, 'HELPFUL')
        if not spellID then
            break
        elseif potionSpellID[spellID] and self.potionButtonMap[spellID] then
            self.potionButtonMap[spellID].expirationTime = expirationTime
            self.potionFound[spellID] = true
        elseif emergencySpellID[spellID] then
            self.emergencyIndicator.valueText:SetTextColor(238 / 255, 71 / 255, 53 / 255, 1)
            self.emergencyIndicator.valueText:SetText("已触发")
        end
    end

    for spellID in pairs(potionSpellID) do
        if not self.potionFound[spellID] and self.potionButtonMap[spellID] and self.potionButtonMap[spellID].expirationTime then
            -- aura removed by player
            self.potionButtonMap[spellID].expirationTime = 0 -- set to zero to let it handle by OnUpdate
        end
    end
end

function VH:UNIT_SPELLCAST_SUCCEEDED(_, unitID, _, spellID)
    if spellID == 306608 and unitID == 'player' then -- Cleansing (Chest)
        local index, data = self:FindMatchingZone(E.MapInfo.x * 100, E.MapInfo.y * 100)
        if not index then
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
    elseif spellID == 143394 then -- Collecting (Crystal)
        self.crystalCollected = true
        local x, y = E.MapInfo.x * 100, E.MapInfo.y * 100
        if unitID ~= 'player' then
            local position = C_Map_GetPlayerMapPosition(E.MapInfo.mapID or 0, unitID)
            if position then
                x, y = position.x * 100, position.y * 100
            end
        end
        local index, data = self:FindMatchingZone(x, y)
        if not index then
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
    local _, subEvent, _, _, _, _, _, destGUID, _, _, _, spellID, spellName, _, amount, _, powerType, altPowerType = CombatLogGetCurrentEventInfo()

    if (
        (subEvent == 'SPELL_ENERGIZE' or subEvent == 'SPELL_PERIODIC_ENERGIZE' or subEvent == 'SPELL_BUILDING_ENERGIZE') and
        destGUID == E.myguid and powerType == Enum_PowerType_Alternate and altPowerType == 554 and
        not visonSpellBlacklist[spellID] and amount and amount < 0
    ) then
        R:Print("理智损失: %s (%d)", GetSpellLink(spellID) or spellName, amount)
        self.prevLost = self.prevLost + amount
        self.lostByHit.valueText:SetText(self.prevLost)
    end
end

function VH:FindMatchingZone(x, y)
    local uiMapID = E.MapInfo.mapID
    if not uiMapID or (uiMapID ~= 1469 and uiMapID ~= 1470) then return end

    for index, data in ipairs(uiMapID == 1469 and OrgrimmarZones or StormwindZones) do
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
    frame.text:SetFont(E.Libs.LSM:Fetch('font', 'Naowh'), 24, 'OUTLINE')
    frame.text:SetTextColor(1, 1, 1, 1)
    frame.text:SetPoint('CENTER', frame, 'CENTER', 0, 0)
    frame.text:SetJustifyH('CENTER')
    frame.text:SetText(defaultText)

    return frame
end

function VH:CreateIndicator(xOffset, yOffset, descText, valueText, r, g, b)
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
    frame.descText:SetFont(E.Libs.LSM:Fetch('font', 'Naowh'), 24, 'OUTLINE')
    frame.descText:SetTextColor(1, 1, 1, 1)
    frame.descText:SetPoint('CENTER', frame, 'CENTER', 0, 0)
    frame.descText:SetJustifyH('CENTER')
    frame.descText:SetText(descText)

    frame.valueText = frame:CreateFontString(nil, 'OVERLAY')
    frame.valueText:SetFont(E.Libs.LSM:Fetch('font', 'Naowh'), 24, 'OUTLINE')
    frame.valueText:SetTextColor(1, 1, 1, 1)
    frame.valueText:SetPoint('LEFT', frame, 'RIGHT', 5, 0)
    frame.valueText:SetJustifyH('LEFT')
    frame.valueText:SetText(valueText)

    return frame
end

function VH:CreatePotionButton(xOffset, yOffset, colorText, r, g, b)
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
    button.colorText:SetFont(E.Libs.LSM:Fetch('font', 'Naowh'), 24, 'OUTLINE')
    button.colorText:SetTextColor(1, 1, 1, 1)
    button.colorText:SetPoint('CENTER', button, 'CENTER', 0, 0)
    button.colorText:SetJustifyH('CENTER')
    button.colorText:SetText(colorText)

    button.timerText = button:CreateFontString(nil, 'OVERLAY')
    button.timerText:SetFont(E.Libs.LSM:Fetch('font', 'Naowh'), 24, 'OUTLINE')
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
            chestFrame.locationDesc:SetFont(E.Libs.LSM:Fetch('font', 'Naowh'), 24, 'OUTLINE')
            chestFrame.locationDesc:SetTextColor(1, 1, 1, 1)
            chestFrame.locationDesc:SetPoint('RIGHT', chestFrame, 'LEFT', 0, 0)
            chestFrame.locationDesc:SetJustifyH('RIGHT')
            chestFrame.locationDesc:SetText(data.name)

            local chestDesc = chestFrame:CreateFontString(nil, 'OVERLAY')
            chestDesc:SetFont(E.Libs.LSM:Fetch('font', 'Naowh'), 24, 'OUTLINE')
            chestDesc:SetTextColor(1, 1, 1, 1)
            chestDesc:SetPoint('BOTTOM', chestFrame, 'TOP', -35, 0)
            chestDesc:SetJustifyH('CENTER')
            chestDesc:SetText("宝箱")

            local crystalDesc = chestFrame:CreateFontString(nil, 'OVERLAY')
            crystalDesc:SetFont(E.Libs.LSM:Fetch('font', 'Naowh'), 24, 'OUTLINE')
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
            chestFrame.locationDesc:SetFont(E.Libs.LSM:Fetch('font', 'Naowh'), 24, 'OUTLINE')
            chestFrame.locationDesc:SetTextColor(1, 1, 1, 1)
            chestFrame.locationDesc:SetPoint('RIGHT', chestFrame, 'LEFT', 0, 0)
            chestFrame.locationDesc:SetJustifyH('RIGHT')
            chestFrame.locationDesc:SetText(data.name)
        end
    end

    self.container:SetSize(400, 280)
    self.container:SetPoint('TOPLEFT', E.UIParent, 'TOPLEFT', 0, -190)
    E:CreateMover(self.container, frameName .. 'Mover', "RhythmBox 惊魂幻象助手", nil, nil, nil, 'ALL,RHYTHMBOX')

    -- address d/c issue in vision, hide the container first, then :CheckZone will register events
    self.container:Hide()

    self.potionButtonMap = {}
    self.chestRecord = {}
    self.crystalRecord = {}

    -- inner usage
    self.potionFound = {}

    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'CheckZone')
    self:RegisterEvent('ZONE_CHANGED', 'CheckZone')
    self:RegisterEvent('ZONE_CHANGED_INDOORS', 'CheckZone')
    self:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'CheckZone')
end

R:RegisterModule(VH:GetName())
