local R, E, L, V, P, G = unpack(select(2, ...))
local C = R:NewModule('Checklist', 'AceEvent-3.0')

-- Lua functions

-- WoW API / Variables

local itemRemove = {
    [138478] = true, -- Feast of Ribs
    [138479] = true, -- Potato Stew Feast

    [152998] = true, -- Carefully Hidden Muffin

    [167893] = true, -- Prismatic Crystal
    [167077] = true, -- Scrying Stone

    [162571] = true, -- Soggy Treasure Map
    [162581] = true, -- Yellowed Treasure Map
    [162584] = true, -- Singed Treasure Map
    [162580] = true, -- Fading Treasure Map
}

function C:CheckItems()
    for itemID, checkFunc in pairs(itemRemove) do
        if not self.warnedItem[itemID] and (type(checkFunc) == 'boolean' or checkFunc()) then
            local itemCount = GetItemCount(itemID, true)
            if itemCount and itemCount > 0 then
                local itemName = GetItemInfo(itemID)
                if itemName then
                    local itemCountInBag = GetItemCount(itemID) or 0

                    self.warnedItem[itemID] = true
                    R:Print("Checklist: 物品 %s (背包: %d, 银行: %d) 应该被邮寄、出售或摧毁。", itemName, itemCountInBag, itemCount - itemCountInBag)
                end
            end
        end
    end
end

function C:Initialize()
    self.warnedItem = {}

    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'CheckItems')
    self:RegisterEvent('BAG_UPDATE', 'CheckItems')
end

R:RegisterModule(C:GetName())
