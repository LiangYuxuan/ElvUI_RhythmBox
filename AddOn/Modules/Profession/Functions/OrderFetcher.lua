local R, E, L, V, P, G = unpack((select(2, ...)))
---@class RhythmBoxProfessionModule
local RP = R:GetModule('Profession')

-- Lua functions
local ipairs = ipairs
local table_insert = table.insert
local table_remove = table.remove
local table_wipe = table.wipe

-- WoW API / Variables
local C_CraftingOrders_GetCrafterBuckets = C_CraftingOrders.GetCrafterBuckets
local C_CraftingOrders_GetCrafterOrders = C_CraftingOrders.GetCrafterOrders
local C_CraftingOrders_RequestCrafterOrders = C_CraftingOrders.RequestCrafterOrders
local C_FunctionContainers_CreateCallback = C_FunctionContainers.CreateCallback

local Enum_CraftingOrderResult_Ok = Enum.CraftingOrderResult.Ok
local Enum_CraftingOrderSortType_ItemName = Enum.CraftingOrderSortType.ItemName
local Enum_CraftingOrderSortType_Tip = Enum.CraftingOrderSortType.Tip
local Enum_CraftingOrderType_Guild = Enum.CraftingOrderType.Guild
local Enum_CraftingOrderType_Npc = Enum.CraftingOrderType.Npc
local Enum_CraftingOrderType_Personal = Enum.CraftingOrderType.Personal
local Enum_CraftingOrderType_Public = Enum.CraftingOrderType.Public

local requestOrderTypesChainStart = Enum_CraftingOrderType_Public
local requestOrderTypesChain = {
    [Enum_CraftingOrderType_Public] = Enum_CraftingOrderType_Guild,
    [Enum_CraftingOrderType_Guild] = Enum_CraftingOrderType_Personal,
    [Enum_CraftingOrderType_Personal] = Enum_CraftingOrderType_Npc,
    [Enum_CraftingOrderType_Npc] = nil,
}

---@type fun(result: Enum.CraftingOrderResult, orders: CraftingOrderInfo[])
local callback
---@type CraftingOrderInfo[]
local orders = {}
---@type Enum.Profession
local profession
---@type number[]
local pendingBuckets = {}
---@type FunctionContainer?
local lastRequestCallback

---@param orderType Enum.CraftingOrderType
---@param selectedSkillLineAbility number?
---@param offset integer?
local function RequestOrderByOrderType(orderType, selectedSkillLineAbility, offset)
    if lastRequestCallback then
        lastRequestCallback:Cancel()
    end

    ---@param result Enum.CraftingOrderResult
    ---@param orderTypeCallback Enum.CraftingOrderType
    ---@param displayBuckets boolean
    ---@param expectMoreRows boolean
    ---@param offsetCallback integer
    local function RequestCrafterOrdersCallback(result, orderTypeCallback, displayBuckets, expectMoreRows, offsetCallback)
        if result == Enum_CraftingOrderResult_Ok then
            if displayBuckets then
                local buckets = C_CraftingOrders_GetCrafterBuckets()
                for _, bucket in ipairs(buckets) do
                    table_insert(pendingBuckets, bucket.skillLineAbilityID)
                end

                local nextOrderType = requestOrderTypesChain[orderTypeCallback]
                if #pendingBuckets > 0 then
                    local nextSkillLineAbility = table_remove(pendingBuckets, 1)
                    RequestOrderByOrderType(orderTypeCallback, nextSkillLineAbility)
                elseif nextOrderType then
                    RequestOrderByOrderType(nextOrderType)
                else
                    callback(result, orders)
                end
            else
                local results = C_CraftingOrders_GetCrafterOrders()
                local numOrders = #results
                for _, orderInfo in ipairs(results) do
                    table_insert(orders, orderInfo)
                end

                local nextOrderType = requestOrderTypesChain[orderTypeCallback]
                if expectMoreRows then
                    RequestOrderByOrderType(orderTypeCallback, selectedSkillLineAbility, offsetCallback + numOrders)
                elseif #pendingBuckets > 0 then
                    local nextSkillLineAbility = table_remove(pendingBuckets, 1)
                    RequestOrderByOrderType(orderTypeCallback, nextSkillLineAbility)
                elseif nextOrderType then
                    RequestOrderByOrderType(nextOrderType)
                else
                    callback(result, orders)
                end
            end
        else
            callback(result, orders)
        end
    end

    lastRequestCallback = C_FunctionContainers_CreateCallback(RequestCrafterOrdersCallback)

    local request = {
        orderType = orderType,
        selectedSkillLineAbility = selectedSkillLineAbility,
        searchFavorites = false,
        initialNonPublicSearch = (orderType ~= Enum_CraftingOrderType_Public),
        offset = offset or 0,
        forCrafter = true,
        profession = profession,
        primarySort = {
            sortType = Enum_CraftingOrderSortType_Tip,
            reversed = true,
        },
        secondarySort = {
            sortType = Enum_CraftingOrderSortType_ItemName,
            reversed = false,
        },
        callback = lastRequestCallback,
    }

    C_CraftingOrders_RequestCrafterOrders(request)
end

---@param professionID Enum.Profession
---@param cb fun(result: Enum.CraftingOrderResult, orders: CraftingOrderInfo[])
function RP:GetCraftingOrders(professionID, cb)
    callback = cb
    profession = professionID
    table_wipe(orders)
    table_wipe(pendingBuckets)

    RequestOrderByOrderType(requestOrderTypesChainStart)
end
