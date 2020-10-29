local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local IR = R:NewModule('ItemRestocker', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions

-- WoW API / Variables
local BuyMerchantItem = BuyMerchantItem
local GetItemCount = GetItemCount
local GetMerchantNumItems = GetMerchantNumItems
local GetMerchantItemID = GetMerchantItemID

local restockList = {
    [159867] = function() -- Rockskip Mineral Water
        if (
            E.myfaction == 'Alliance' and E.mylevel == 50 and (
                E.myclass == 'PALADIN' or E.myclass == 'PRIEST' or E.myclass == 'SHAMAN' or
                E.myclass == 'MONK' or E.myclass == 'DRUID'
            )
        ) then
            return 20
        end
    end,
    [163784] = function() -- Seafoam Coconut Water
        if (
            E.myfaction == 'Horde' and E.mylevel == 50 and (
                E.myclass == 'PALADIN' or E.myclass == 'PRIEST' or E.myclass == 'SHAMAN' or
                E.myclass == 'MONK' or E.myclass == 'DRUID'
            )
        ) then
            return 20
        end
    end,
    [173859] = function() -- Ethereal Pomegranate
        if (
            E.mylevel == 60 and (
                E.myclass == 'PALADIN' or E.myclass == 'PRIEST' or E.myclass == 'SHAMAN' or
                E.myclass == 'MONK' or E.myclass == 'DRUID'
            )
        ) then
            return 20
        end
    end,
}

function IR:MERCHANT_SHOW()
    for i = 1, GetMerchantNumItems() do
        local itemID = GetMerchantItemID(i)
        if restockList[itemID] then
            local targetCount = restockList[itemID]()
            if targetCount then
                local itemCount = GetItemCount(itemID)
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
