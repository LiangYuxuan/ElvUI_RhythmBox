local R, E, L, V, P, G = unpack((select(2, ...)))
---@class RhythmBoxProfessionModule
local RP = R:GetModule('Profession')

-- Lua functions
local _G = _G
local ipairs = ipairs

-- WoW API / Variables

---@class SpecialItemPrice
---@field multiplier number
---@field sourceItemID number

---@type table<number, SpecialItemPrice>
local specialItemPrices = {
    [246450] = { -- Artisan's Consortium Gold Star
        multiplier = 5,
        sourceItemID = 246449, -- Mentor's Helpful Handiwork
    },
}

---@param itemID number
---@return number
local function RECrystallizeGetItemPrice(itemID)
    local price = _G.RECrystallize_PriceCheckItemID(itemID)
    return price or 0
end

---@param itemID number
---@return number
local function TradeSkillMasterGetItemPrice(itemID)
    local itemString = 'i:' .. itemID
    local price = _G.TSM_API.GetCustomPriceValue('DBMinBuyout', itemString)
    return price or 0
end

---@param itemID number
---@return number
local function AuctionatorGetItemPrice(itemID)
    local price = _G.Auctionator.API.v1.GetAuctionPriceByItemID('ElvUI_RhythmBox', itemID)
    return price or 0
end

---@param itemID number
---@return number
local function OribosExchangeGetItemPrice(itemID)
    local result = {}
    _G.OEMarketInfo(itemID, result)

    local price = 0
    if result.market and result.market > 0 then
        price = result.market
    elseif result.region and result.region > 0 then
        price = result.region
    end

    return price
end

---@param _itemID number
---@return number
local function DummyGetItemPrice(_itemID)
    return 0
end

local GetItemPrice = E:IsAddOnEnabled('RECrystallize') and RECrystallizeGetItemPrice
    or E:IsAddOnEnabled('TradeSkillMaster') and TradeSkillMasterGetItemPrice
    or E:IsAddOnEnabled('Auctionator') and AuctionatorGetItemPrice
    or E:IsAddOnEnabled('OribosExchange') and OribosExchangeGetItemPrice
    or DummyGetItemPrice

---@param itemID number
---@return number
function RP:GetItemPrice(itemID)
    if specialItemPrices[itemID] then
        local info = specialItemPrices[itemID]
        local sourcePrice = GetItemPrice(info.sourceItemID)
        return sourcePrice * info.multiplier
    end

    return GetItemPrice(itemID)
end

---@param missingNormalReagentInfos CraftingReagentInfo[]
---@param missingModifiedReagentInfos CraftingReagentInfo[]
---@return number
function RP:GetReagentsCostPrice(missingNormalReagentInfos, missingModifiedReagentInfos)
    local costPrice = 0
    for _, reagentInfo in ipairs(missingNormalReagentInfos) do
        if reagentInfo.reagent.itemID then
            local price = self:GetItemPrice(reagentInfo.reagent.itemID)
            costPrice = costPrice + price * reagentInfo.quantity
        end
    end
    for _, reagentInfo in ipairs(missingModifiedReagentInfos) do
        if reagentInfo.reagent.itemID then
            local price = self:GetItemPrice(reagentInfo.reagent.itemID)
            costPrice = costPrice + price * reagentInfo.quantity
        end
    end

    return costPrice
end
