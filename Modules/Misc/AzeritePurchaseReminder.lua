local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local APR = R:NewModule('AzeritePurchaseReminder', 'AceEvent-3.0')

-- Lua functions
local _G = _G
local select, strsplit = select, strsplit

-- WoW API / Variables
local CreateFrame = CreateFrame
local UnitGUID = UnitGUID

local remindCharacters = {
    ['小只萌猎手'] = true,
    ['卡登斯邃光'] = true,
}

function APR:MERCHANT_SHOW()
    local unitGUID = UnitGUID('npc')
    if not unitGUID then return end

    local npcID = select(6, strsplit('-', unitGUID))
    if not npcID or npcID ~= '149045' then return end

    if remindCharacters[E.myname] then
        self.remindFrame.clickTime = 0
        self.remindFrame:Show()
        self:RegisterEvent('MERCHANT_CLOSED')
    end
end

function APR:MERCHANT_CLOSED()
    self.remindFrame:Hide()
    self:UnregisterEvent('MERCHANT_CLOSED')
end

function APR:Initialize()
    self:RegisterEvent('MERCHANT_SHOW')

    local frame = CreateFrame('Button', nil, _G.MerchantFrame)
    frame:SetFrameStrata('DIALOG')
    frame:ClearAllPoints()
    frame:SetAllPoints()
    frame:EnableMouse(true)
    frame:SetScript('OnClick', function(self)
        self.clickTime = self.clickTime + 1
        if self.clickTime >= 2 then
            self:Hide()
        end
    end)

    frame.texture = frame:CreateTexture(nil, 'BACKGROUND')
    frame.texture:SetAllPoints()
    frame.texture:SetColorTexture(0, 0, 0, 1)
    frame.texture:SetTexCoord(.1, .9, .1, .9)

    frame.colorText = frame:CreateFontString(nil, 'OVERLAY')
    frame.colorText:FontTemplate(nil, 48)
    frame.colorText:SetTextColor(1, 1, 1, 1)
    frame.colorText:SetPoint('CENTER', frame, 'CENTER', 0, 0)
    frame.colorText:SetJustifyH('CENTER')
    frame.colorText:SetText("停止购买")

    frame:Hide()

    self.remindFrame = frame
end

R:RegisterModule(APR:GetName())
