local R, E, L, V, P, G = unpack((select(2, ...)))

local DF = R:NewModule('DarkmoonFaire', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions
local format = format

-- WoW API / Variables
local C_Map_GetBestMapForUnit = C_Map.GetBestMapForUnit
local C_UnitAuras_GetBuffDataByIndex = C_UnitAuras.GetBuffDataByIndex
local C_UnitAuras_GetPlayerAuraBySpellID = C_UnitAuras.GetPlayerAuraBySpellID
local CancelUnitBuff = CancelUnitBuff
local CreateFrame = CreateFrame
local GetTime = GetTime

local expirationTime

local function OnUpdate(self)
    if not expirationTime then
        self:Hide()
        return
    end

    local restTime = expirationTime - GetTime()
    if restTime < 0 then
        expirationTime = nil
        self:Hide()

        for i = 1, 40 do
            local data = C_UnitAuras_GetBuffDataByIndex('player', i, 'HELPFUL')
            if not data then return end

            if data.spellId == 102116 then
                CancelUnitBuff('player', i, 'HELPFUL')
                break
            end
        end

        DF:RegisterEvent('UNIT_AURA')
    else
        self.text:SetText(format("暗月大炮自动降落：%.1f秒", restTime))
    end
end

function DF:UNIT_AURA(_, unit)
    if unit ~= 'player' then return end

    if C_UnitAuras_GetPlayerAuraBySpellID(102116) then
        self:UnregisterEvent('UNIT_AURA')

        expirationTime = GetTime() + E.db.RhythmBox.Misc.CannonballTime
        self.textFrame:Show()
    end
end

function DF:CheckZone()
    local uiMapID = C_Map_GetBestMapForUnit('player')
    if uiMapID == 407 then
        self:RegisterEvent('UNIT_AURA')
    else
        self:UnregisterEvent('UNIT_AURA')
    end
end

function DF:Initialize()
    ---@class DarkmoonFaireTextFrame: Frame
    local textFrame = CreateFrame('Frame', nil, E.UIParent)
    textFrame:ClearAllPoints()
    textFrame:SetPoint('CENTER')
    textFrame:SetSize(100, 200)
    textFrame:SetScript('OnUpdate', OnUpdate)
    textFrame:Hide()
    self.textFrame = textFrame

    textFrame.text = textFrame:CreateFontString(nil, 'OVERLAY')
    textFrame.text:FontTemplate(nil, 24)
    textFrame.text:SetTextColor(1, 1, 1, 1)
    textFrame.text:SetPoint('CENTER')
    textFrame.text:SetJustifyH('CENTER')
    textFrame.text:SetText("")

    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'CheckZone')
    self:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'CheckZone')
end

R:RegisterModule(DF:GetName())
