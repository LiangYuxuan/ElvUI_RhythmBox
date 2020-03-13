-- Potions part from https://wago.io/kxredzlg9 by SnowElysium-夜織雪
-- Lost by hit part from https://wago.io/JxMRlFNNX by wardensun

local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local VH = R:NewModule('VisionHelper', 'AceEvent-3.0')

-- Lua functions
local ipairs, unpack = ipairs, unpack

-- WoW API / Variables
local C_Map_GetBestMapForUnit = C_Map.GetBestMapForUnit
local CreateFrame = CreateFrame

local potionColor = {
    {'Black',  "黑", 106, 106, 106},
    {'Green',  "绿", 89,  201, 87 },
    {'Red',    "红", 243, 86,  115},
    {'Blue',   "蓝", 64,  126, 221},
    {'Purple', "紫", 174, 56,  175},
}
local potionType = {
    {"毒药", 85,  238, 85 },
    {"理智", 62,  197, 233},
    {"减伤", 197, 154, 108, 315849},
    {"回血", 254, 243, 103, 315845},
    {"龙息", 238, 85,  85,  315817},
}
local potionButtonMap = {}
local potionSpellID = {}
for _, data in ipairs(potionType) do
    if data[5] then
        potionSpellID[data[5]] = true
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
            self.timerText:SetTextColor(238 / 255, 71 / 255, 53 / 255, 1)
            self.timerText:SetText(restTime)
        else
            local minute = floor(restTime / 60)
            if minute > 14 then
                self.timerText:SetTextColor(63 / 255, 63 / 255, 63 / 255, 1)
            else
                self.timerText:SetTextColor(1, 1, 1, 1)
            end
            self.timerText:SetText(format("%02d:%02d", minute, restTime - minute * 60))
        end
    end
end

local function ButtonOnClick(self)
    local potionIndex = self.index
    for index, button in ipairs(VH.buttons) do
        local typeIndex = index - potionIndex + 1
        if typeIndex < 1 then
            typeIndex = typeIndex + 5
        end

        local text, r, g, b, spellID = unpack(potionType[typeIndex])
        button.colorText:SetTextColor(r / 255, g / 255, b / 255, 1)
        button.colorText:SetText(text)
        if spellID then
            potionButtonMap[spellID] = button
            button:SetScript('OnUpdate', ButtonOnUpdate)
        else
            button:SetScript('OnUpdate', nil)
        end
    end
    VH:RegisterEvent('UNIT_AURA')
end

function VH:Reset()
    self:UnregisterEvent('UNIT_AURA')
    self:UnregisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
    self.lostByHit.valueText:SetText(0)
    for index, button in ipairs(self.buttons) do
        button:SetScript('OnUpdate', nil)
        button.expirationTime = nil

        button.colorText:SetTextColor(1, 1, 1, 1)
        button.colorText:SetText(potionColor[index][2])
        button.timerText:SetTextColor(1, 1, 1, 1)
        button.timerText:SetText()
    end
end

function VH:CheckZone()
    local uiMapID = C_Map_GetBestMapForUnit('player')
    if uiMapID and (
        uiMapID == 1469 or -- Vision of Orgrimmar
        uiMapID == 1470    -- Vision of Stormwind
    ) then
        self.prevLost = 0
        self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
        self.container:Show()
    else
        self.container:Hide()
        self:Reset()
    end
end

function VH:UNIT_AURA(event, unit)
    if unit ~= 'player' then return end

    for i = 1, 40 do
        local _, _, _, _, _, expirationTime, _, _, _, spellID = UnitAura('player', i, 'HELPFUL')
        if not spellID then
            break
        elseif potionSpellID[spellID] then
            potionButtonMap[spellID].expirationTime = expirationTime
        end
    end
end

function VH:COMBAT_LOG_EVENT_UNFILTERED()
    local _, subEvent, _, _, _, _, _, destGUID, _, _, _, spellID, _, _, amount, _, powerType, altPowerType = CombatLogGetCurrentEventInfo()

    if (
        (subEvent == 'SPELL_ENERGIZE' or subEvent == 'SPELL_PERIODIC_ENERGIZE' or subEvent == 'SPELL_BUILDING_ENERGIZE') and
        destGUID == E.myguid and powerType == Enum.PowerType.Alternate and altPowerType == 554 and
        spellID ~= 287769 and amount and amount < 0
    ) then
        self.prevLost = self.prevLost + amount
        self.lostByHit.valueText:SetText(self.prevLost)
    end
end

function VH:Initialize()
    local frameName = 'RhythmBoxVHContainer'
    self.container = CreateFrame('Frame', frameName, E.UIParent)

    self.lostByHit = CreateFrame('Button', nil, self.container)
    self.lostByHit:ClearAllPoints()
    self.lostByHit:SetPoint('TOPLEFT', self.container, 'TOPLEFT', 0, 0)
    self.lostByHit:SetSize(70, 40)
    self.lostByHit:EnableMouse(false)

    self.lostByHit.texture = self.lostByHit:CreateTexture(nil, 'BACKGROUND')
    self.lostByHit.texture:SetAllPoints()
    self.lostByHit.texture:SetTexture('Interface/Addons/WeakAuras/Media/Textures/Square_White_Border')
    self.lostByHit.texture:SetTexCoord(.1, .9, .1, .9)
    self.lostByHit.texture:SetVertexColor(92 / 255, 92 / 255, 237 / 255, 1)

    self.lostByHit.descText = self.lostByHit:CreateFontString(nil, 'OVERLAY')
    self.lostByHit.descText:SetFont(E.Libs.LSM:Fetch('font', 'Naowh'), 24, 'OUTLINE')
    self.lostByHit.descText:SetTextColor(1, 1, 1, 1)
    self.lostByHit.descText:SetPoint('CENTER', self.lostByHit, 'CENTER', 0, 0)
    self.lostByHit.descText:SetJustifyH('CENTER')
    self.lostByHit.descText:SetText("额外")

    self.lostByHit.valueText = self.lostByHit:CreateFontString(nil, 'OVERLAY')
    self.lostByHit.valueText:SetFont(E.Libs.LSM:Fetch('font', 'Naowh'), 24, 'OUTLINE')
    self.lostByHit.valueText:SetTextColor(1, 1, 1, 1)
    self.lostByHit.valueText:SetPoint('LEFT', self.lostByHit, 'RIGHT', 5, 0)
    self.lostByHit.valueText:SetJustifyH('LEFT')
    self.lostByHit.valueText:SetText(0)

    self.buttons = {}
    for index, tbl in ipairs(potionColor) do
        local _, name, r, g, b = unpack(tbl)

        local button = CreateFrame('Button', nil, self.container)
        button:ClearAllPoints()
        button:SetPoint('TOPLEFT', self.container, 'TOPLEFT', 0, -40 * index)
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
        button.colorText:SetText(name)

        button.timerText = button:CreateFontString(nil, 'OVERLAY')
        button.timerText:SetFont(E.Libs.LSM:Fetch('font', 'Naowh'), 24, 'OUTLINE')
        button.timerText:SetTextColor(1, 1, 1, 1)
        button.timerText:SetPoint('LEFT', button, 'RIGHT', 5, 0)
        button.timerText:SetJustifyH('LEFT')
        button.timerText:SetText()

        button.index = index
        self.buttons[index] = button
    end

    self.container:SetSize(200, 240)
    self.container:SetPoint('TOPLEFT', E.UIParent, 'TOPLEFT', 0, -230)
    E:CreateMover(self.container, frameName .. 'Mover', "RhythmBox 恩佐斯幻象助手", nil, nil, nil, 'ALL,RHYTHMBOX')

    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'CheckZone')
    self:RegisterEvent('ZONE_CHANGED', 'CheckZone')
    self:RegisterEvent('ZONE_CHANGED_INDOORS', 'CheckZone')
    self:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'CheckZone')
end

R:RegisterModule(VH:GetName())
