local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local CAHI = R:NewModule('CorruptionAHItem', 'AceEvent-3.0', 'AceHook-3.0')
local LCI = LibStub('LibCorruptedItem-1.0')

-- Lua functions
local _G = _G
local format, ipairs, strmatch, strsplit, tonumber = format, ipairs, strmatch, strsplit, tonumber

-- WoW API / Variables
local GetSpellInfo = GetSpellInfo
local IsAddOnLoaded = IsAddOnLoaded

local bonusIDs = {
    [40] = ITEM_MOD_CR_AVOIDANCE_SHORT,
    [41] = ITEM_MOD_CR_LIFESTEAL_SHORT,
    [42] = ITEM_MOD_CR_SPEED_SHORT,
    [43] = ITEM_MOD_CR_STURDINESS_SHORT,
}
local rankText = {"I", "II", "III"}

local function GetItemSplit(itemLink)
    local itemString = strmatch(itemLink, 'item:([%-?%d:]+)')
    if not itemString then return end

    local itemSplit = {strsplit(':', itemString)}

    -- Split data into a table
    for index, value in ipairs(itemSplit) do
        if value == '' then
            itemSplit[index] = 0
        else
            itemSplit[index] = tonumber(value)
        end
    end

    return itemSplit
end

function CAHI:RefreshScrollFrame()
    for _, row in ipairs(_G.AuctionHouseFrame.ItemBuyFrame.ItemList.tableBuilder.rows) do
        if not row.corruption then
            row.corruption = row:CreateFontString(nil, 'OVERLAY')
            row.corruption:FontTemplate(nil, 12)
            row.corruption:SetPoint('LEFT', 300, 0)
            row.corruption:SetTextColor(149 / 255, 109 / 255, 201 / 255)
        end
        if not row.bonus then
            row.bonus = row:CreateFontString(nil, 'OVERLAY')
            row.bonus:FontTemplate(nil, 12)
            row.bonus:SetPoint('LEFT', 475, 0)
            row.bonus:SetTextColor(30 / 255, 1, 0)
        end
        row.corruption:Hide()
        row.bonus:Hide()

        if row.rowData and row.rowData.itemLink then
            local itemSplit = GetItemSplit(row.rowData.itemLink)
            if not itemSplit then return end

            for index = 1, itemSplit[13] do
                local bonusID = itemSplit[13 + index]
                if bonusIDs[bonusID] then
                    row.bonus:SetText(bonusIDs[bonusID])
                    row.bonus:Show()
                else
                    local spellID, rank = LCI:GetCorruptionInfoByBonusID(bonusID)
                    if spellID then
                        local spellName, _, spellIcon = GetSpellInfo(spellID)
                        if spellName then
                            if rank then
                                spellName = spellName .. ' ' .. rankText[rank]
                            end
                            spellName = format("|T%s:14:14:0:0:64:64:5:59:5:59|t %s", spellIcon, spellName)
                            row.corruption:SetText(spellName)
                            row.corruption:Show()
                        end
                    end
                end
            end
        end
    end
end

function CAHI:ADDON_LOADED(_, addonName)
    if addonName == 'Blizzard_AuctionHouseUI' then
        self:UnregisterEvent('ADDON_LOADED')
        self:SecureHook(_G.AuctionHouseFrame.ItemBuyFrame.ItemList, 'RefreshScrollFrame')
    end
end

function CAHI:Initialize()
    if not IsAddOnLoaded('Blizzard_AuctionHouseUI') then
        self:RegisterEvent('ADDON_LOADED')
        return
    end

    self:SecureHook(_G.AuctionHouseFrame.ItemBuyFrame.ItemList, 'RefreshScrollFrame')
end

R:RegisterModule(CAHI:GetName())
