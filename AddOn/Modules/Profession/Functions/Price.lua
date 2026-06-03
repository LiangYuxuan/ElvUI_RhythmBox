local R, E, L, V, P, G = unpack((select(2, ...)))
---@class RhythmBoxProfessionModule
local RP = R:GetModule('Profession')

-- Lua functions
local _G = _G
local ipairs = ipairs

-- WoW API / Variables

---@param itemID number
---@return number?
function RP:GetItemPrice(itemID)
    if itemID == 246450 then -- Artisan's Consortium Gold Star
        local price = _G.RECrystallize_PriceCheckItemID(246449) -- Mentor's Helpful Handiwork
        return price and price * 5 or nil
    end

    local price = _G.RECrystallize_PriceCheckItemID(itemID)
    return price
end

---@param missingNormalReagentInfos CraftingReagentInfo[]
---@param missingModifiedReagentInfos CraftingReagentInfo[]
---@return number
function RP:GetReagentsCostPrice(missingNormalReagentInfos, missingModifiedReagentInfos)
    local costPrice = 0
    for _, reagentInfo in ipairs(missingNormalReagentInfos) do
        if reagentInfo.reagent.itemID then
            local price = self:GetItemPrice(reagentInfo.reagent.itemID)
            if price then
                costPrice = costPrice + price * reagentInfo.quantity
            end
        end
    end
    for _, reagentInfo in ipairs(missingModifiedReagentInfos) do
        if reagentInfo.reagent.itemID then
            local price = self:GetItemPrice(reagentInfo.reagent.itemID)
            if price then
                costPrice = costPrice + price * reagentInfo.quantity
            end
        end
    end

    return costPrice
end
