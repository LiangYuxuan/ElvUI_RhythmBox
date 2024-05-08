local R, E, L, V, P, G = unpack((select(2, ...)))
local IR = R:NewModule('ItemRestocker', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions

-- WoW API / Variables
local C_Item_GetItemCount = C_Item.GetItemCount
local BuyMerchantItem = BuyMerchantItem
local GetMerchantNumItems = GetMerchantNumItems
local GetMerchantItemID = GetMerchantItemID

local restockList = {
    [194684] = function() -- Azure Leywine
        if (
            E.myclass == 'PALADIN' or E.myclass == 'PRIEST' or E.myclass == 'SHAMAN' or
            E.myclass == 'MONK' or E.myclass == 'DRUID' or E.myclass == 'EVOKER'
        ) then
            return 20
        end
    end
}

function IR:MERCHANT_SHOW()
    for i = 1, GetMerchantNumItems() do
        local itemID = GetMerchantItemID(i)
        ---@cast itemID number|nil
        if itemID and restockList[itemID] then
            local targetCount = restockList[itemID]()
            if targetCount then
                local itemCount = C_Item_GetItemCount(itemID)
                if targetCount > itemCount then
                    BuyMerchantItem(i, targetCount - itemCount)
                end
            end
        end
    end
end

function IR:Initialize()
    self:RegisterEvent('MERCHANT_SHOW')
end

R:RegisterModule(IR:GetName())
