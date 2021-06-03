local R, E, L, V, P, G = unpack(select(2, ...))
local RI = R:GetModule('Injections')

-- Lua functions

-- WoW API / Variables

local override = {
    [6217] = 177715, -- Enchant Chest - Eternal Bounds
    [6210] = 172408, -- Enchant Gloves - Eternal Strength
    [6227] = 172365, -- Enchant Weapon - Ascended Vigor
}

function RI:TinyInspect()
    local LIE = LibStub('LibItemEnchant.7000')

    local originFunc = LIE.GetEnchantItemID

    function LIE:GetEnchantItemID(itemLink)
        local itemID, enchant = originFunc(LIE, itemLink)
        if enchant and override[enchant] then
            return override[enchant], enchant
        end
        return itemID, enchant
    end
end

RI:RegisterInjection(RI.TinyInspect, 'TinyInspect')
