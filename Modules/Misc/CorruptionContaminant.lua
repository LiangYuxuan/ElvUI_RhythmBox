local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local CC = R:NewModule('CorruptionContaminant', 'AceEvent-3.0', 'AceHook-3.0')
local LCI = LibStub('LibCorruptedItem-1.0')

-- Lua functions
local _G = _G
local strmatch = strmatch

-- WoW API / Variables
local GetItemInfo = GetItemInfo
local GetMerchantItemID = GetMerchantItemID
local GetMerchantNumItems = GetMerchantNumItems

local HEADER_COLON = HEADER_COLON
local MERCHANT_ITEMS_PER_PAGE = MERCHANT_ITEMS_PER_PAGE

local itemPrefix
local rankText = {"I", "II", "III"}

function CC:UpdateItemPrefix()
    local itemName = GetItemInfo(177981)
    if itemName then
        return strmatch(itemName, '(.+' .. HEADER_COLON .. ')') .. '(.+)'
    end
end

function CC:UpdateMerchantInfo()
    if not itemPrefix then
        itemPrefix = self:UpdateItemPrefix()
    end
    if not itemPrefix then return end

    local numItems = GetMerchantNumItems()
    for i = 1, MERCHANT_ITEMS_PER_PAGE do
        local index = (_G.MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE + i
        if index > numItems then return end

        local button = _G['MerchantItem' .. i .. 'ItemButton']
        if not button.levelString then
            button.levelString = button:CreateFontString(nil, 'OVERLAY')
            button.levelString:FontTemplate(nil, 14)
            button.levelString:SetPoint('TOPLEFT', 3, -3)
        end

        local itemID = GetMerchantItemID(index)
        if itemID then
            local _, rank = LCI:GetCorruptionInfoByContaminant(itemID)
            if rank then
                button.levelString:SetText(rankText[rank])
            else
                button.levelString:SetText("")
            end

            local name = _G['MerchantItem' .. i .. 'Name']
            local text = name and name:GetText()
            local newString = text and strmatch(text, itemPrefix)
            if newString then
                name:SetText(newString .. " " .. (rank and rankText[rank] or ""))
            end
        end
    end
end

function CC:Initialize()
    self:SecureHook('MerchantFrame_UpdateMerchantInfo', 'UpdateMerchantInfo')
end

R:RegisterModule(CC:GetName())
