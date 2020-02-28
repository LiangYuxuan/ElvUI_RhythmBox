-- From: https://wago.io/kxredzlg9
-- By: SnowElysium-夜織雪

local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local VPH = R:NewModule('VisionPotionHelper', 'AceEvent-3.0')

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
    {"毒药",      85,  238, 85 },
    {"+100 理智", 62,  197, 233},
    {"5% 减伤",   197, 154, 108},
    {"2% 回血",   254, 243, 103},
    {"龙息",      238, 85,  85 },
}

local function ButtonOnEnter(self)
    self.highlight:Show()
end

local function ButtonOnLeave(self)
    self.highlight:Hide()
end

local function ButtonOnClick(self)
    local potionIndex = self.index
    for index, button in ipairs(VPH.buttons) do
        local typeIndex = index - potionIndex + 1
        if typeIndex < 1 then
            typeIndex = typeIndex + 5
        end

        local text, r, g, b = unpack(potionType[typeIndex])
        button.descText:SetTextColor(r / 255, g / 255, b / 255, 1)
        button.descText:SetText(text)
    end
    VPH.container.descText:Hide()
end

function VPH:CheckZone()
    local uiMapID = C_Map_GetBestMapForUnit('player')
    if uiMapID and (
        uiMapID == 1469 or -- Vision of Orgrimmar
        uiMapID == 1470    -- Vision of Stormwind
    ) then
        if not self.container:IsShown() then
            self.container:Show()
            self:Clear()
        end
    else
        self.container:Hide()
    end
end

function VPH:Clear()
    for _, button in ipairs(self.buttons) do
        button.descText:SetText()
    end
    self.container.descText:Show()
end

function VPH:Initialize()
    local frameName = 'RhythmBoxVPHContainer'
    self.container = CreateFrame('Frame', frameName, E.UIParent)

    self.container.descText = self.container:CreateFontString(nil, 'OVERLAY')
    self.container.descText:SetFont(E.Libs.LSM:Fetch('font', 'Naowh'), 24, 'OUTLINE')
    self.container.descText:SetTextColor(1, 1, 1, 1)
    self.container.descText:SetPoint('TOPLEFT', self.container, 'TOPLEFT', 0, 0)
    self.container.descText:SetJustifyH('LEFT')
    self.container.descText:SetText("选择毒药")

    local topPadding = self.container.descText:GetStringHeight() + 2
    self.buttons = {}
    for index, tbl in ipairs(potionColor) do
        local _, name, r, g, b = unpack(tbl)

        local button = CreateFrame('Button', nil, self.container)
        button:ClearAllPoints()
        button:SetPoint('TOPLEFT', self.container, 'TOPLEFT', 0, -40 * (index - 1) - topPadding)
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
        button.highlight:SetTexture(E.Libs.LSM:Fetch('statusbar', 'Solid'))
        button.highlight:SetBlendMode('ADD')
        button.highlight:SetAlpha(.4)
        button.highlight:Hide()

        button.colorText = button:CreateFontString(nil, 'OVERLAY')
        button.colorText:SetFont(E.Libs.LSM:Fetch('font', 'Naowh'), 24, 'OUTLINE')
        button.colorText:SetTextColor(1, 1, 1, 1)
        button.colorText:SetPoint('CENTER', button, 'CENTER', 0, 0)
        button.colorText:SetJustifyH('CENTER')
        button.colorText:SetText(name)

        button.descText = button:CreateFontString(nil, 'OVERLAY')
        button.descText:SetFont(E.Libs.LSM:Fetch('font', 'Naowh'), 24, 'OUTLINE')
        button.descText:SetTextColor(1, 1, 1, 1)
        button.descText:SetPoint('LEFT', button, 'RIGHT', 0, 0)
        button.descText:SetJustifyH('LEFT')
        button.descText:SetText()

        button.index = index
        self.buttons[index] = button
    end

    self.container:SetSize(200, 200 + topPadding + 2)
    self.container:SetPoint('TOPLEFT', E.UIParent, 'TOPLEFT', 0, -250)
    E:CreateMover(self.container, frameName .. 'Mover', "RhythmBox 大幻象药水助手", nil, nil, nil, 'ALL,RHYTHMBOX')

    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'CheckZone')
    self:RegisterEvent('ZONE_CHANGED', 'CheckZone')
    self:RegisterEvent('ZONE_CHANGED_INDOORS', 'CheckZone')
    self:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'CheckZone')
end

R:RegisterModule(VPH:GetName())
