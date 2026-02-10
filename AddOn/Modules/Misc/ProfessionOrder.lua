local R, E, L, V, P, G = unpack((select(2, ...)))
local PO = R:NewModule('ProfessionOrder', 'AceEvent-3.0', 'AceTimer-3.0')
local S = E:GetModule('Skins')

-- Lua functions
local _G = _G
local format, ipairs, max, pairs, select, tinsert, tostring, tremove, wipe = format, ipairs, max, pairs, select, tinsert, tostring, tremove, wipe

-- WoW API / Variables
local C_CraftingOrders_ClaimOrder = C_CraftingOrders.ClaimOrder
local C_CraftingOrders_FulfillOrder = C_CraftingOrders.FulfillOrder
local C_CraftingOrders_GetClaimedOrder = C_CraftingOrders.GetClaimedOrder
local C_CraftingOrders_GetCrafterBuckets = C_CraftingOrders.GetCrafterBuckets
local C_CraftingOrders_GetCrafterOrders = C_CraftingOrders.GetCrafterOrders
local C_CraftingOrders_GetCraftingOrderTime = C_CraftingOrders.GetCraftingOrderTime
local C_CraftingOrders_GetOrderClaimInfo = C_CraftingOrders.GetOrderClaimInfo
local C_CraftingOrders_OpenCrafterCraftingOrders = C_CraftingOrders.OpenCrafterCraftingOrders
local C_CraftingOrders_OrderCanBeRecrafted = C_CraftingOrders.OrderCanBeRecrafted
local C_CraftingOrders_ReleaseOrder = C_CraftingOrders.ReleaseOrder
local C_CraftingOrders_RequestCrafterOrders = C_CraftingOrders.RequestCrafterOrders
local C_FunctionContainers_CreateCallback = C_FunctionContainers.CreateCallback
local C_Map_GetBestMapForUnit = C_Map.GetBestMapForUnit
local C_TradeSkillUI_CraftRecipe = C_TradeSkillUI.CraftRecipe
local C_TradeSkillUI_GetBaseProfessionInfo = C_TradeSkillUI.GetBaseProfessionInfo
local C_TradeSkillUI_GetCategoryInfo = C_TradeSkillUI.GetCategoryInfo
local C_TradeSkillUI_GetCraftingOperationInfo = C_TradeSkillUI.GetCraftingOperationInfo
local C_TradeSkillUI_GetCraftingOperationInfoForOrder = C_TradeSkillUI.GetCraftingOperationInfoForOrder
local C_TradeSkillUI_GetDependentReagents = C_TradeSkillUI.GetDependentReagents
local C_TradeSkillUI_GetItemSlotModificationsForOrder = C_TradeSkillUI.GetItemSlotModificationsForOrder
local C_TradeSkillUI_GetProfessionInfoBySkillLineID = C_TradeSkillUI.GetProfessionInfoBySkillLineID
local C_TradeSkillUI_GetReagentSlotStatus = C_TradeSkillUI.GetReagentSlotStatus
local C_TradeSkillUI_GetRecipeInfo = C_TradeSkillUI.GetRecipeInfo
local C_TradeSkillUI_GetRecipeItemQualityInfo = C_TradeSkillUI.GetRecipeItemQualityInfo
local C_TradeSkillUI_GetRecipeSchematic = C_TradeSkillUI.GetRecipeSchematic
local C_TradeSkillUI_IsNearProfessionSpellFocus = C_TradeSkillUI.IsNearProfessionSpellFocus
local C_TradeSkillUI_IsTradeSkillReady = C_TradeSkillUI.IsTradeSkillReady
local C_TradeSkillUI_OpenTradeSkill = C_TradeSkillUI.OpenTradeSkill
local C_TradeSkillUI_RecraftRecipeForOrder = C_TradeSkillUI.RecraftRecipeForOrder
local CreateFrame = CreateFrame
local GetMoney = GetMoney
local GetProfessionInfo = GetProfessionInfo
local GetProfessions = GetProfessions
local IsModifierKeyDown = IsModifierKeyDown

local GetMoneyString = GetMoneyString
local Professions_GetChatIconMarkupForQuality = Professions.GetChatIconMarkupForQuality
local Professions_IsRecipeOnCooldown = Professions.IsRecipeOnCooldown
local ProfessionsFrame_LoadUI = ProfessionsFrame_LoadUI
local SecondsToTime = SecondsToTime
local ShowUIPanel = ShowUIPanel
local tContains = tContains
local tDeleteItem = tDeleteItem

local Constants_ProfessionConsts_PUBLIC_CRAFTING_ORDER_STALE_THRESHOLD = Constants.ProfessionConsts.PUBLIC_CRAFTING_ORDER_STALE_THRESHOLD
local Enum_CraftingOrderReagentsType_All = Enum.CraftingOrderReagentsType.All
local Enum_CraftingOrderResult_Ok = Enum.CraftingOrderResult.Ok
local Enum_CraftingOrderSortType_ItemName = Enum.CraftingOrderSortType.ItemName
local Enum_CraftingOrderSortType_Tip = Enum.CraftingOrderSortType.Tip
local Enum_CraftingOrderType_Guild = Enum.CraftingOrderType.Guild
local Enum_CraftingOrderType_Npc = Enum.CraftingOrderType.Npc
local Enum_CraftingOrderType_Personal = Enum.CraftingOrderType.Personal
local Enum_CraftingOrderType_Public = Enum.CraftingOrderType.Public
local Enum_CraftingReagentType_Modifying = Enum.CraftingReagentType.Modifying
local Enum_TradeskillSlotDataType_ModifiedReagent = Enum.TradeskillSlotDataType.ModifiedReagent

local ERR_TOO_MUCH_GOLD = ERR_TOO_MUCH_GOLD
local OPTIONAL_REAGENT_TOOLTIP_SLOT_LOCKED_FORMAT = OPTIONAL_REAGENT_TOOLTIP_SLOT_LOCKED_FORMAT
local PROFESSIONS_CRAFTER_CANT_CLAIM_OWN = PROFESSIONS_CRAFTER_CANT_CLAIM_OWN
local PROFESSIONS_CRAFTER_CANT_CLAIM_REAGENT_SLOT = PROFESSIONS_CRAFTER_CANT_CLAIM_REAGENT_SLOT
local PROFESSIONS_CRAFTER_CANT_CLAIM_UNLEARNED = PROFESSIONS_CRAFTER_CANT_CLAIM_UNLEARNED
local PROFESSIONS_CRAFTER_OUT_OF_CLAIMS_FMT = PROFESSIONS_CRAFTER_OUT_OF_CLAIMS_FMT
local PROFESSIONS_ORDER_HAS_MINIMUM_QUALITY_FMT = PROFESSIONS_ORDER_HAS_MINIMUM_QUALITY_FMT
local PROFESSIONS_RECIPE_COOLDOWN = PROFESSIONS_RECIPE_COOLDOWN
local UNKNOWN = UNKNOWN

local requestOrderTypesChainStart = Enum_CraftingOrderType_Public
local requestOrderTypesChain = {
    [Enum_CraftingOrderType_Public] = Enum_CraftingOrderType_Guild,
    [Enum_CraftingOrderType_Guild] = Enum_CraftingOrderType_Personal,
    [Enum_CraftingOrderType_Personal] = Enum_CraftingOrderType_Npc,
    [Enum_CraftingOrderType_Npc] = nil,
}

---@param searchValue number
---@param tableName string
---@return string
local function GetEnumOutputText(searchValue, tableName)
    for key, value in pairs(_G.Enum[tableName]) do
        if value == searchValue then
            return searchValue .. ' (Enum.' .. tableName .. '.' .. key .. ')'
        end
    end
    return tostring(searchValue) .. ' (Enum.' .. tableName .. '.Unknown)'
end

---@param order CraftingOrderInfo
---@param recipeInfo TradeSkillRecipeInfo
---@param craftingReagents CraftingReagentInfo[]
---@return CraftingOperationInfo?
function PO:GetOperationInfo(order, recipeInfo, craftingReagents)
    local operationInfo = order.isRecraft
        and C_TradeSkillUI_GetCraftingOperationInfoForOrder(recipeInfo.recipeID, craftingReagents, order.orderID, false)
        or C_TradeSkillUI_GetCraftingOperationInfo(recipeInfo.recipeID, craftingReagents, nil, false)

    return operationInfo
end

---@param order CraftingOrderInfo
---@param schematic CraftingRecipeSchematic
---@return table<number, boolean>, CraftingReagentInfo[]
function PO:GetProvidedReagentInfo(order, schematic)
    ---@type table<number, boolean>
    local reagentSlotProvidedByCustomer = {}
    ---@type CraftingReagentInfo[]
    local craftingReagents = {}

    if order.isRecraft then
        ---@type table<number, CraftingReagentInfo>
        local recraftItemProvidedReagents = {}
        ---@type table<number, boolean>
        local recraftItemProvidedReagentsItemIDs = {}
        ---@type table<number, boolean>
        local providedReagentsItemIDs = {}

        local slotMods = C_TradeSkillUI_GetItemSlotModificationsForOrder(order.orderID)
        for dataSlotIndex, slotMod in ipairs(slotMods) do
            if slotMod.reagent.itemID and slotMod.reagent.itemID > 0 then
                for _, reagentSlotSchematic in ipairs(schematic.reagentSlotSchematics) do
                    if reagentSlotSchematic.dataSlotType == Enum_TradeskillSlotDataType_ModifiedReagent and reagentSlotSchematic.dataSlotIndex == dataSlotIndex then
                        recraftItemProvidedReagents[reagentSlotSchematic.slotIndex] = {
                            reagent = slotMod.reagent,
                            dataSlotIndex = dataSlotIndex,
                            quantity = reagentSlotSchematic.quantityRequired,
                        }
                        recraftItemProvidedReagentsItemIDs[slotMod.reagent.itemID] = true

                        break
                    end
                end
            end
        end

        for _, orderReagentInfo in ipairs(order.reagents) do
            reagentSlotProvidedByCustomer[orderReagentInfo.slotIndex] = true
            providedReagentsItemIDs[orderReagentInfo.reagentInfo.reagent.itemID] = true
        end

        for slotIndex, reagentSlotSchematic in ipairs(schematic.reagentSlotSchematics) do
            if reagentSlotSchematic.dataSlotType == Enum_TradeskillSlotDataType_ModifiedReagent then
                -- item provided by customer in this slot should put in craftingReagents
                for _, orderReagentInfo in ipairs(order.reagents) do
                    if orderReagentInfo.slotIndex == slotIndex then
                        tinsert(craftingReagents, orderReagentInfo.reagentInfo)

                        if recraftItemProvidedReagents[slotIndex] then
                            -- customer provided item overrides the recrafted item
                            recraftItemProvidedReagentsItemIDs[recraftItemProvidedReagents[slotIndex].reagent.itemID] = nil
                            recraftItemProvidedReagents[slotIndex] = nil
                        end
                    end
                end
            end
        end

        local needUpdate = true
        while needUpdate do
            needUpdate = false

            for slotIndex, recraftItemProvidedReagent in pairs(recraftItemProvidedReagents) do
                local reagentItemID = recraftItemProvidedReagent.reagent.itemID
                if reagentItemID and reagentItemID > 0 then
                    local requirementReagents = C_TradeSkillUI_GetDependentReagents(recraftItemProvidedReagent.reagent)

                    local missingRequirement = false
                    for _, reagent in ipairs(requirementReagents) do
                        local itemID = reagent.itemID
                        if itemID and itemID > 0 and not providedReagentsItemIDs[itemID] and not recraftItemProvidedReagentsItemIDs[itemID] then
                            missingRequirement = true
                            break
                        end
                    end

                    if missingRequirement then
                        recraftItemProvidedReagentsItemIDs[reagentItemID] = nil
                        recraftItemProvidedReagents[slotIndex] = nil
                        needUpdate = true
                        break
                    end
                end
            end
        end

        for slotIndex, recraftItemProvidedReagent in pairs(recraftItemProvidedReagents) do
            reagentSlotProvidedByCustomer[slotIndex] = true
            tinsert(craftingReagents, recraftItemProvidedReagent)
        end
    else
        for _, orderReagentInfo in ipairs(order.reagents) do
            reagentSlotProvidedByCustomer[orderReagentInfo.slotIndex] = true
        end

        for slotIndex, reagentSlotSchematic in ipairs(schematic.reagentSlotSchematics) do
            if reagentSlotSchematic.dataSlotType == Enum_TradeskillSlotDataType_ModifiedReagent then
                -- item provided by customer in this slot should put in craftingReagents
                for _, orderReagentInfo in ipairs(order.reagents) do
                    if orderReagentInfo.slotIndex == slotIndex then
                        tinsert(craftingReagents, orderReagentInfo.reagentInfo)
                    end
                end
            end
        end
    end

    return reagentSlotProvidedByCustomer, craftingReagents
end

---@param slotInfo CraftingReagentSlotInfo|nil
---@param recipeInfo TradeSkillRecipeInfo
---@return boolean, string|nil
function PO:GetReagentSlotStatus(slotInfo, recipeInfo)
    if not slotInfo then
        return false
    end

    local locked, lockedReason = C_TradeSkillUI_GetReagentSlotStatus(slotInfo.mcrSlotID, recipeInfo.recipeID, recipeInfo.skillLineAbilityID)
    if locked then
        return true, lockedReason
    end

    if slotInfo.requiredSkillRank <= 0 then
        return false
    end

    local categoryInfo = C_TradeSkillUI_GetCategoryInfo(recipeInfo.categoryID)
    while categoryInfo and not categoryInfo.skillLineCurrentLevel and categoryInfo.parentCategoryID do
        categoryInfo = C_TradeSkillUI_GetCategoryInfo(categoryInfo.parentCategoryID)
    end

    if categoryInfo and categoryInfo.skillLineCurrentLevel then
        if categoryInfo.skillLineCurrentLevel < slotInfo.requiredSkillRank then
            return true, format(OPTIONAL_REAGENT_TOOLTIP_SLOT_LOCKED_FORMAT, slotInfo.requiredSkillRank)
        end
    end

    return false
end

---@param order CraftingOrderInfo
---@param recipeInfo TradeSkillRecipeInfo
---@param schematic CraftingRecipeSchematic
---@param profession Enum.Profession
---@param reagentSlotProvidedByCustomer table<number, boolean>
---@return boolean, string|nil
function PO:CanStartOrder(order, recipeInfo, schematic, profession, reagentSlotProvidedByCustomer)
    -- ProfessionsCrafterOrderViewMixin:UpdateStartOrderButton
    if order.customerGuid == E.myguid then
        return false, PROFESSIONS_CRAFTER_CANT_CLAIM_OWN
    end

    if order.orderType == Enum_CraftingOrderType_Public then
        local claimInfo = C_CraftingOrders_GetOrderClaimInfo(profession)
        if (
            claimInfo and claimInfo.claimsRemaining <= 0
            and max(order.expirationTime - C_CraftingOrders_GetCraftingOrderTime(), 0) > Constants_ProfessionConsts_PUBLIC_CRAFTING_ORDER_STALE_THRESHOLD
        ) then
            return false, format(PROFESSIONS_CRAFTER_OUT_OF_CLAIMS_FMT, SecondsToTime(claimInfo.secondsToRecharge))
        end
    end

    if not recipeInfo.learned or (order.isRecraft and not C_CraftingOrders_OrderCanBeRecrafted(order.orderID)) then
        return false, PROFESSIONS_CRAFTER_CANT_CLAIM_UNLEARNED
    end

    for slotIndex in pairs(reagentSlotProvidedByCustomer) do
        local reagentSlotSchematic = schematic.reagentSlotSchematics[slotIndex]
        if reagentSlotSchematic.reagentType == Enum_CraftingReagentType_Modifying then
            local locked = self:GetReagentSlotStatus(reagentSlotSchematic.slotInfo, recipeInfo)
            if locked then
                return false, PROFESSIONS_CRAFTER_CANT_CLAIM_REAGENT_SLOT
            end
        end
    end

    return true
end

---@param order CraftingOrderInfo
---@param operationInfo CraftingOperationInfo|nil
---@return boolean, string|nil
function PO:CanCreate(order, operationInfo)
    -- ProfessionsCrafterOrderViewMixin:UpdateCreateButton
    if Professions_IsRecipeOnCooldown(order.spellID) then
        return false, PROFESSIONS_RECIPE_COOLDOWN
    end

    -- transaction:HasMetAllRequirements()
    -- in non-npc order case, we always have all reagents provided by customer,
    -- in npc order case, reagents check are handled by other function,
    -- so no need to check reagents here

    if order.minQuality and operationInfo and operationInfo.craftingQuality < order.minQuality then
        local atlas = self:GetQualityAtlas(order.spellID, order.minQuality)
        return false, format(PROFESSIONS_ORDER_HAS_MINIMUM_QUALITY_FMT, atlas)
    end

    return true
end

---@param order CraftingOrderInfo
---@return boolean, string|nil
function PO:CanFulfill(order)
    -- ProfessionsCrafterOrderViewMixin:UpdateFulfillButton
    local maxGold = 99999999999
    if GetMoney() + order.tipAmount - order.consortiumCut > maxGold then
        return false, ERR_TOO_MUCH_GOLD
    end

    return true
end

---@param recipeID number
---@param quality number
---@return string
function PO:GetQualityAtlas(recipeID, quality)
    local info = C_TradeSkillUI_GetRecipeItemQualityInfo(recipeID, quality)
    local atlas = info and Professions_GetChatIconMarkupForQuality(info, true) or ''
    return atlas
end

---@param order CraftingOrderInfo
---@param schematic CraftingRecipeSchematic
---@param operationInfo CraftingOperationInfo|nil
---@param prefix string
---@param postfix string|nil
function PO:PrintOrderInfo(order, schematic, operationInfo, prefix, postfix)
    local orderTypeText = (order.orderType == Enum_CraftingOrderType_Public and "公开")
        or (order.orderType == Enum_CraftingOrderType_Guild and "公会")
        or (order.orderType == Enum_CraftingOrderType_Npc and "客人")
        or (order.orderType == Enum_CraftingOrderType_Personal and "个人")

    local reward = order.tipAmount - order.consortiumCut
    local minQualityAtlas = order.minQuality and order.minQuality > 0
        and self:GetQualityAtlas(order.spellID, order.minQuality)
        or ''
    local craftingQualityAtlas = operationInfo and operationInfo.isQualityCraft
        and self:GetQualityAtlas(order.spellID, operationInfo.craftingQuality)
        or ''

    R:Print(format(
        "%s %s订单 %s %s %s%s +%s %s",
        prefix,
        minQualityAtlas,
        orderTypeText,
        order.customerName or UNKNOWN,
        schematic.name,
        craftingQualityAtlas,
        GetMoneyString(reward),
        postfix or ""
    ))
end

---@param profession Enum.Profession
---@param orders CraftingOrderInfo[]
---@return integer
function PO:HandleOrders(profession, orders)
    for _, order in ipairs(orders) do
        if order.reagentState == Enum_CraftingOrderReagentsType_All then
            local recipeInfo = C_TradeSkillUI_GetRecipeInfo(order.spellID)
            local schematic = C_TradeSkillUI_GetRecipeSchematic(order.spellID, order.isRecraft)
            local reagentSlotProvidedByCustomer, craftingReagents = self:GetProvidedReagentInfo(order, schematic)

            if recipeInfo then
                local operationInfo = self:GetOperationInfo(order, recipeInfo, craftingReagents)

                local canStartOrder, reasonStartOrder = self:CanStartOrder(order, recipeInfo, schematic, profession, reagentSlotProvidedByCustomer)
                local canCreate, reasonCreate = self:CanCreate(order, operationInfo)
                local canFulfill, reasonFulfill = self:CanFulfill(order)

                if canStartOrder and canCreate and canFulfill then
                    tinsert(self.pendingOrderIDs, order.orderID)

                    self:PrintOrderInfo(order, schematic, operationInfo, "可以制作")
                else
                    local reason = reasonStartOrder
                    if not reason and reasonCreate then
                        reason = reasonCreate
                    elseif reason and reasonCreate then
                        reason = reason .. " / " .. reasonCreate
                    elseif reasonCreate then
                        reason = reasonCreate
                    end

                    if not reason and reasonFulfill then
                        reason = reasonFulfill
                    elseif reason and reasonFulfill then
                        reason = reason .. " / " .. reasonFulfill
                    elseif reasonFulfill then
                        reason = reasonFulfill
                    end

                    self:PrintOrderInfo(order, schematic, operationInfo, "无法制作", reason or UNKNOWN)
                end
            else
                self:PrintOrderInfo(order, schematic, nil, "信息缺失")
            end
        elseif (
            order.orderType == Enum_CraftingOrderType_Public
            or order.orderType == Enum_CraftingOrderType_Guild
            or order.orderType == Enum_CraftingOrderType_Personal
        ) then
            local schematic = C_TradeSkillUI_GetRecipeSchematic(order.spellID, order.isRecraft)

            self:PrintOrderInfo(order, schematic, nil, "材料不足")
        -- elseif order.orderType == Enum_CraftingOrderType_Npc then
            -- only handle npc orders without all reagents provided
            -- TODO
        end
    end

    return #orders
end

do
    ---@type number[]
    local pendingBuckets = {}

    ---@param profession Enum.Profession
    ---@param orderType Enum.CraftingOrderType
    ---@param selectedSkillLineAbility number|nil
    ---@param offset integer|nil
    function PO:RequestOrderByOrderType(profession, orderType, selectedSkillLineAbility, offset)
        if not selectedSkillLineAbility and not offset then
            -- very first call or new orderType, clear pending buckets
            wipe(pendingBuckets)
        end

        ---@param result Enum.CraftingOrderResult
        ---@param orderType Enum.CraftingOrderType
        ---@param displayBuckets boolean
        ---@param expectMoreRows boolean
        ---@param offset integer
        local function requestCrafterOrdersCallback(result, orderType, displayBuckets, expectMoreRows, offset)
            if result == Enum_CraftingOrderResult_Ok then
                if displayBuckets then
                    local buckets = C_CraftingOrders_GetCrafterBuckets()
                    for _, bucket in ipairs(buckets) do
                        tinsert(pendingBuckets, bucket.skillLineAbilityID)
                    end

                    local nextOrderType = requestOrderTypesChain[orderType]
                    if #pendingBuckets > 0 then
                        local nextSkillLineAbility = tremove(pendingBuckets, 1)
                        self:RequestOrderByOrderType(profession, orderType, nextSkillLineAbility)
                    elseif nextOrderType then
                        self:RequestOrderByOrderType(profession, nextOrderType)
                    else
                        self.inProgress = false
                        R:Print("专业订单扫描完成。")
                    end
                else
                    local numOrders = self:HandleOrders(profession, C_CraftingOrders_GetCrafterOrders())
                    local nextOrderType = requestOrderTypesChain[orderType]
                    if expectMoreRows then
                        self:RequestOrderByOrderType(profession, orderType, selectedSkillLineAbility, offset + numOrders)
                    elseif #pendingBuckets > 0 then
                        local nextSkillLineAbility = tremove(pendingBuckets, 1)
                        self:RequestOrderByOrderType(profession, orderType, nextSkillLineAbility)
                    elseif nextOrderType then
                        self:RequestOrderByOrderType(profession, nextOrderType)
                    else
                        self.inProgress = false
                        R:Print("专业订单扫描完成。")
                    end
                end
            else
                self.inProgress = false

                local resultText = GetEnumOutputText(result, 'CraftingOrderResult')

                R:Print("专业订单扫描失败: %s", resultText)
            end
        end

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
            callback = C_FunctionContainers_CreateCallback(requestCrafterOrdersCallback),
        }

        C_CraftingOrders_RequestCrafterOrders(request)
    end
end

---@return Enum.Profession?, number?
function PO:GetNearProfessionInfo()
    local professionIndex1, professionIndex2 = GetProfessions()
    local skillLineID1 = professionIndex1 and select(7, GetProfessionInfo(professionIndex1))
    local skillLineID2 = professionIndex2 and select(7, GetProfessionInfo(professionIndex2))
    local professionInfo1 = skillLineID1 and C_TradeSkillUI_GetProfessionInfoBySkillLineID(skillLineID1)
    local professionInfo2 = skillLineID2 and C_TradeSkillUI_GetProfessionInfoBySkillLineID(skillLineID2)
    local nearFocus1 = professionInfo1 and C_TradeSkillUI_IsNearProfessionSpellFocus(professionInfo1.profession)
    local nearFocus2 = professionInfo2 and C_TradeSkillUI_IsNearProfessionSpellFocus(professionInfo2.profession)

    if nearFocus1 then
        return professionInfo1.profession, skillLineID1
    elseif nearFocus2 then
        return professionInfo2.profession, skillLineID2
    end
end

function PO:OrderResponse(event, result, orderID)
    if event == 'CRAFTINGORDERS_CLAIM_ORDER_RESPONSE' then
        if result ~= Enum_CraftingOrderResult_Ok then
            -- remove from pendingOrderIDs when claim failed
            tDeleteItem(self.pendingOrderIDs, orderID)
        end
    elseif event == 'CRAFTINGORDERS_FULFILL_ORDER_RESPONSE' then
        if result == Enum_CraftingOrderResult_Ok then
            -- remove from pendingOrderIDs when fulfill success
            tDeleteItem(self.pendingOrderIDs, orderID)
        end
    end

    -- R:Print("%s %s %s", event, GetEnumOutputText(result, 'CraftingOrderResult'), orderID or 'nil')
end

function PO:OrderUpdated(_, orderID)
    local order = C_CraftingOrders_GetClaimedOrder()
    if order and order.orderID == orderID and order.isFulfillable then
        local profession = self:GetNearProfessionInfo()
        if profession then
            R:Print("正在完成订单...")

            C_CraftingOrders_FulfillOrder(order.orderID, '', profession)
        end
    end

    -- R:Print("%s %s", _, orderID or 'nil')
end

-- function PO:OrderCountUpdated(event, orderType, numOrders)
--     R:Print("%s %s %s", event, GetEnumOutputText(orderType, 'CraftingOrderType'), numOrders)
-- end

function PO:Process()
    local profession, skillLineID = self:GetNearProfessionInfo()

    if not profession or not skillLineID then
        R:Print("请靠近专业工作台。")
        return
    end

    local isReady = C_TradeSkillUI_IsTradeSkillReady()
    local info = C_TradeSkillUI_GetBaseProfessionInfo()

    if not isReady or info.profession ~= profession then
        R:Print("正在获取专业信息...")

        C_TradeSkillUI_OpenTradeSkill(skillLineID)
        C_CraftingOrders_OpenCrafterCraftingOrders()

        isReady = C_TradeSkillUI_IsTradeSkillReady()
        if not isReady then
            return
        end
    end

    local order = C_CraftingOrders_GetClaimedOrder()
    if order then
        if #self.pendingOrderIDs == 0 then
            -- have claimed order before first scanning, handle it first

            self:HandleOrders(profession, { order })
        end

        if tContains(self.pendingOrderIDs, order.orderID) then
            if order.isFulfillable then
                R:Print("正在完成订单...")

                C_CraftingOrders_FulfillOrder(order.orderID, '', profession)
            elseif order.isRecraft then
                R:Print("正在制作订单...")

                C_TradeSkillUI_RecraftRecipeForOrder(order.orderID, order.outputItemGUID)
            else
                R:Print("正在制作订单...")

                C_TradeSkillUI_CraftRecipe(order.spellID, 1, nil, nil, order.orderID)
            end
        else
            R:Print("正在放弃订单...")

            C_CraftingOrders_ReleaseOrder(order.orderID, profession)
        end

        return
    elseif #self.pendingOrderIDs > 0 and not self.inProgress then
        R:Print("正在接受订单...")

        C_CraftingOrders_ClaimOrder(self.pendingOrderIDs[1], profession)

        return
    end

    local isModifierKeyDown = IsModifierKeyDown()

    if self.inProgress and not isModifierKeyDown then
        R:Print("专业订单扫描进行中，请稍后再试。")
        return
    end

    if isModifierKeyDown then
        R:Print("强制扫描专业订单...")
    else
        R:Print("开始扫描专业订单...")
    end

    self.inProgress = true
    wipe(self.pendingOrderIDs)

    self:RequestOrderByOrderType(profession, requestOrderTypesChainStart)
end

do
    -- WoW API / Variables
    local C_CurrencyInfo_GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo
    local C_Item_GetItemNameByID = C_Item.GetItemNameByID

    local dialog = CreateFrame('Frame', nil, UIParent, 'DialogBoxFrame')
    dialog:SetPoint('CENTER')
    dialog:SetSize(600, 500)

    dialog:SetBackdrop({
        bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
        edgeFile = 'Interface\\PVPFrame\\UI-Character-PVP-Highlight',
        edgeSize = 16,
        insets = { left = 8, right = 6, top = 8, bottom = 8 },
    })
    dialog:SetBackdropBorderColor(0, .44, .87, .5)

    dialog:SetMovable(true)
    dialog:SetClampedToScreen(true)
    dialog:SetScript('OnMouseDown', function(frame, button)
        if button == 'LeftButton' then
            frame:StartMoving()
        end
    end)
    dialog:SetScript('OnMouseUp', dialog.StopMovingOrSizing)

    -- ScrollFrame
    local scrollFrame = CreateFrame('ScrollFrame', nil, dialog, 'UIPanelScrollFrameTemplate')
    scrollFrame:SetPoint('LEFT', 16, 0)
    scrollFrame:SetPoint('RIGHT', -32, 0)
    scrollFrame:SetPoint('TOP', 0, -16)
    scrollFrame:SetPoint('BOTTOM', dialog, 'BOTTOM', 0, 50)

    -- EditBox
    local editBox = CreateFrame('EditBox', nil, scrollFrame)
    editBox:SetSize(scrollFrame:GetSize())
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject('ChatFontSmall')
    editBox:SetScript('OnEscapePressed', editBox.ClearFocus)
    scrollFrame:SetScrollChild(editBox)

    -- Resizable
    dialog:SetResizable(true)
    dialog:SetResizeBounds(150, 100)
    local resizeButton = CreateFrame('Button', nil, dialog)
    resizeButton:SetPoint('BOTTOMRIGHT', -6, 7)
    resizeButton:SetSize(16, 16)
    resizeButton:SetNormalTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up')
    resizeButton:SetHighlightTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight')
    resizeButton:SetPushedTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down')

    resizeButton:SetScript('OnMouseDown', function(frame, button)
        if button == 'LeftButton' then
            dialog:StartSizing('BOTTOMRIGHT')
            frame:GetHighlightTexture():Hide()
        end
    end)
    resizeButton:SetScript('OnMouseUp', function(frame)
        dialog:StopMovingOrSizing()
        frame:GetHighlightTexture():Show()
        editBox:SetWidth(scrollFrame:GetWidth())
    end)

    -- DEBUG TODOs
    -- Customer Whisper Status
    -- https://github.com/Gethe/wow-ui-source/blob/13032b07511152adc91684ad00ef07aca24fcbb1/Interface/AddOns/Blizzard_Professions/Blizzard_ProfessionsCrafterOrderView.lua#L156
    -- https://warcraft.wiki.gg/wiki/API_C_ChatInfo.RequestCanLocalWhisperTarget
    -- https://warcraft.wiki.gg/wiki/CAN_LOCAL_WHISPER_TARGET_RESPONSE

    function PO:DebugOutput()
        local orderView = _G.ProfessionsFrame.OrdersPage.OrderView
        local schematicForm = orderView.OrderDetails.SchematicForm
        local transaction = schematicForm.transaction
        local details = schematicForm.Details

        ---@type CraftingOrderInfo
        local order = orderView.order
        ---@type table<number, boolean>
        local reagentSlotProvidedByCustomer = orderView.reagentSlotProvidedByCustomer
        ---@type TradeSkillRecipeInfo
        local recipeInfo = schematicForm.currentRecipeInfo
        ---@type CraftingRecipeSchematic
        local schematic = transaction.recipeSchematic
        ---@type number|nil
        local craftingQuality = details.craftingQualityInfo and details.craftingQualityInfo.quality

        local selfReagentSlotProvidedByCustomer, selfCraftingReagents = self:GetProvidedReagentInfo(order, schematic)
        local selfOperationInfo = self:GetOperationInfo(order, recipeInfo, selfCraftingReagents)

        ---@type number, number
        local recraftItemGUID, recraftOrderID = transaction:GetRecraftAllocation()
        ---@type boolean
        local attemptToApplyConcentration = transaction:IsApplyingConcentration()
        ---@type CraftingReagentInfo[]
        local craftingReagents = transaction:CreateCraftingReagentInfoTbl()
        ---@type string?
        local allocationItemGUID = transaction:GetAllocationItemGUID()
        local operationInfo = recraftOrderID
            and C_TradeSkillUI_GetCraftingOperationInfoForOrder(recipeInfo.recipeID, craftingReagents, recraftOrderID, attemptToApplyConcentration)
            or C_TradeSkillUI_GetCraftingOperationInfo(recipeInfo.recipeID, craftingReagents, allocationItemGUID, attemptToApplyConcentration)

        ---@type table<number, number>
        local exemptedReagents = transaction.exemptedReagents
        local slotModsFromOrderID = C_TradeSkillUI_GetItemSlotModificationsForOrder(order.orderID)

        editBox:SetText('')
        dialog:Show()

        local orderTypeText = GetEnumOutputText(order.orderType, 'CraftingOrderType')
        local reagentStateText = GetEnumOutputText(order.reagentState, 'CraftingOrderReagentsType')
        editBox:Insert('order = \n')
        editBox:Insert('    orderID: ' .. order.orderID .. '\n')
        editBox:Insert('    spellID: ' .. order.spellID .. '\n')
        editBox:Insert('    orderType: ' .. orderTypeText .. '\n')
        editBox:Insert('    expirationTime: ' .. order.expirationTime .. '\n')
        editBox:Insert('    minQuality: ' .. order.minQuality .. '\n')
        editBox:Insert('    tipAmount: ' .. order.tipAmount .. '\n')
        editBox:Insert('    consortiumCut: ' .. order.consortiumCut .. '\n')
        editBox:Insert('    isRecraft: ' .. tostring(order.isRecraft) .. '\n')
        editBox:Insert('    reagentState: ' .. reagentStateText .. '\n')
        editBox:Insert('    customerGuid: ' .. tostring(order.customerGuid) .. '\n')
        editBox:Insert('    reagents = \n')
        for index, orderReagentInfo in ipairs(order.reagents) do
            local sourceText = GetEnumOutputText(orderReagentInfo.source, 'CraftingOrderReagentSource')
            editBox:Insert('        [' .. index .. '] = \n')
            editBox:Insert('            slotIndex: ' .. orderReagentInfo.slotIndex .. '\n')
            editBox:Insert('            source: ' .. sourceText .. '\n')
            editBox:Insert('            isBasicReagent: ' .. tostring(orderReagentInfo.isBasicReagent) .. '\n')
            editBox:Insert('            reagentInfo = \n')
            editBox:Insert('                reagent = \n')
            if orderReagentInfo.reagentInfo.reagent.itemID and orderReagentInfo.reagentInfo.reagent.itemID > 0 then
                local itemName = C_Item_GetItemNameByID(orderReagentInfo.reagentInfo.reagent.itemID) or UNKNOWN
                editBox:Insert('                    itemID: ' .. orderReagentInfo.reagentInfo.reagent.itemID .. ' ' .. itemName .. '\n')
            elseif orderReagentInfo.reagentInfo.reagent.currencyID and orderReagentInfo.reagentInfo.reagent.currencyID > 0 then
                local currencyName = C_CurrencyInfo_GetCurrencyInfo(orderReagentInfo.reagentInfo.reagent.currencyID).name or UNKNOWN
                editBox:Insert('                    currencyID: ' .. orderReagentInfo.reagentInfo.reagent.currencyID .. ' ' .. currencyName .. '\n')
            end
            editBox:Insert('                dataSlotIndex: ' .. orderReagentInfo.reagentInfo.dataSlotIndex .. '\n')
            editBox:Insert('                quantity: ' .. orderReagentInfo.reagentInfo.quantity .. '\n')
        end
        editBox:Insert('    outputItemGUID: ' .. tostring(order.outputItemGUID) .. '\n')

        editBox:Insert('recipeInfo = \n')
        editBox:Insert('    categoryID: ' .. recipeInfo.categoryID .. '\n')
        editBox:Insert('    name: ' .. recipeInfo.name .. '\n')
        editBox:Insert('    learned: ' .. tostring(recipeInfo.learned) .. '\n')
        editBox:Insert('    recipeID: ' .. recipeInfo.recipeID .. '\n')
        editBox:Insert('    skillLineAbilityID: ' .. recipeInfo.skillLineAbilityID .. '\n')

        editBox:Insert('schematic = \n')
        editBox:Insert('    reagentSlotSchematics = \n')
        for index, reagentSlotSchematic in ipairs(schematic.reagentSlotSchematics) do
            local reagentTypeText = GetEnumOutputText(reagentSlotSchematic.reagentType, 'CraftingReagentType')
            local dataSlotTypeText = GetEnumOutputText(reagentSlotSchematic.dataSlotType, 'TradeskillSlotDataType')
            local orderSourceText = GetEnumOutputText(reagentSlotSchematic.orderSource, 'CraftingOrderReagentSource')

            editBox:Insert('        [' .. index .. '] = \n')
            editBox:Insert('            reagents = \n')
            for _, reagent in ipairs(reagentSlotSchematic.reagents) do
                if reagent.itemID and reagent.itemID > 0 then
                    local itemName = C_Item_GetItemNameByID(reagent.itemID) or UNKNOWN
                    editBox:Insert('                itemID: ' .. reagent.itemID .. ' ' .. itemName .. '\n')
                elseif reagent.currencyID and reagent.currencyID > 0 then
                    local currencyName = C_CurrencyInfo_GetCurrencyInfo(reagent.currencyID).name or UNKNOWN
                    editBox:Insert('                currencyID: ' .. reagent.currencyID .. ' ' .. currencyName .. '\n')
                end
            end
            editBox:Insert('            reagentType: ' .. reagentTypeText .. '\n')
            editBox:Insert('            quantityRequired: ' .. reagentSlotSchematic.quantityRequired .. '\n')
            if reagentSlotSchematic.slotInfo then
                editBox:Insert('            slotInfo = \n')
                editBox:Insert('                mcrSlotID: ' .. reagentSlotSchematic.slotInfo.mcrSlotID .. '\n')
                editBox:Insert('                requiredSkillRank: ' .. reagentSlotSchematic.slotInfo.requiredSkillRank .. '\n')
                editBox:Insert('                slotText: ' .. tostring(reagentSlotSchematic.slotInfo.slotText) .. '\n')
            end
            editBox:Insert('            dataSlotType: ' .. dataSlotTypeText .. '\n')
            editBox:Insert('            dataSlotIndex: ' .. reagentSlotSchematic.dataSlotIndex .. '\n')
            editBox:Insert('            slotIndex: ' .. reagentSlotSchematic.slotIndex .. '\n')
            editBox:Insert('            orderSource: ' .. orderSourceText .. '\n')
            editBox:Insert('            required: ' .. tostring(reagentSlotSchematic.required) .. '\n')
            editBox:Insert('            hiddenInCraftingForm: ' .. tostring(reagentSlotSchematic.hiddenInCraftingForm) .. '\n')
        end

        editBox:Insert('reagentSlotProvidedByCustomer = \n')
        for slotIndex, provided in pairs(reagentSlotProvidedByCustomer) do
            editBox:Insert('    [' .. slotIndex .. '] = ' .. tostring(provided) .. '\n')
        end

        editBox:Insert('selfReagentSlotProvidedByCustomer = \n')
        for slotIndex, provided in pairs(selfReagentSlotProvidedByCustomer) do
            editBox:Insert('    [' .. slotIndex .. '] = ' .. tostring(provided) .. '\n')
        end

        editBox:Insert('craftingReagents = \n')
        for index, craftingReagent in ipairs(craftingReagents) do
            editBox:Insert('    [' .. index .. '] = \n')
            editBox:Insert('        reagent = \n')
            if craftingReagent.reagent.itemID and craftingReagent.reagent.itemID > 0 then
                local itemName = C_Item_GetItemNameByID(craftingReagent.reagent.itemID) or UNKNOWN
                editBox:Insert('            itemID: ' .. craftingReagent.reagent.itemID .. ' ' .. itemName .. '\n')
            elseif craftingReagent.reagent.currencyID and craftingReagent.reagent.currencyID > 0 then
                local currencyName = C_CurrencyInfo_GetCurrencyInfo(craftingReagent.reagent.currencyID).name or UNKNOWN
                editBox:Insert('            currencyID: ' .. craftingReagent.reagent.currencyID .. ' ' .. currencyName .. '\n')
            end
            editBox:Insert('        dataSlotIndex: ' .. craftingReagent.dataSlotIndex .. '\n')
            editBox:Insert('        quantity: ' .. craftingReagent.quantity .. '\n')
        end

        editBox:Insert('selfCraftingReagents = \n')
        for index, craftingReagent in ipairs(selfCraftingReagents) do
            editBox:Insert('    [' .. index .. '] = \n')
            editBox:Insert('        reagent = \n')
            if craftingReagent.reagent.itemID and craftingReagent.reagent.itemID > 0 then
                local itemName = C_Item_GetItemNameByID(craftingReagent.reagent.itemID) or UNKNOWN
                editBox:Insert('            itemID: ' .. craftingReagent.reagent.itemID .. ' ' .. itemName .. '\n')
            elseif craftingReagent.reagent.currencyID and craftingReagent.reagent.currencyID > 0 then
                local currencyName = C_CurrencyInfo_GetCurrencyInfo(craftingReagent.reagent.currencyID).name or UNKNOWN
                editBox:Insert('            currencyID: ' .. craftingReagent.reagent.currencyID .. ' ' .. currencyName .. '\n')
            end
            editBox:Insert('        dataSlotIndex: ' .. craftingReagent.dataSlotIndex .. '\n')
            editBox:Insert('        quantity: ' .. craftingReagent.quantity .. '\n')
        end

        if operationInfo then
            editBox:Insert('operationInfo = \n')
            editBox:Insert('    isQualityCraft: ' .. tostring(operationInfo.isQualityCraft) .. '\n')
            editBox:Insert('    quality: ' .. operationInfo.quality .. '\n')
            editBox:Insert('    craftingQuality: ' .. operationInfo.craftingQuality .. '\n')
            editBox:Insert('    concentrationCurrencyID: ' .. operationInfo.concentrationCurrencyID .. '\n')
            editBox:Insert('    concentrationCost: ' .. operationInfo.concentrationCost .. '\n')
        else
            editBox:Insert('operationInfo = nil\n')
        end

        if selfOperationInfo then
            editBox:Insert('selfOperationInfo = \n')
            editBox:Insert('    isQualityCraft: ' .. tostring(selfOperationInfo.isQualityCraft) .. '\n')
            editBox:Insert('    quality: ' .. selfOperationInfo.quality .. '\n')
            editBox:Insert('    craftingQuality: ' .. selfOperationInfo.craftingQuality .. '\n')
            editBox:Insert('    concentrationCurrencyID: ' .. selfOperationInfo.concentrationCurrencyID .. '\n')
            editBox:Insert('    concentrationCost: ' .. selfOperationInfo.concentrationCost .. '\n')
        else
            editBox:Insert('selfOperationInfo = nil\n')
        end

        editBox:Insert('craftingQuality: ' .. tostring(craftingQuality) .. '\n')

        editBox:Insert('recraftItemGUID: ' .. tostring(recraftItemGUID) .. '\n')

        editBox:Insert('recraftOrderID: ' .. tostring(recraftOrderID) .. '\n')

        editBox:Insert('attemptToApplyConcentration: ' .. tostring(attemptToApplyConcentration) .. '\n')

        editBox:Insert('allocationItemGUID: ' .. tostring(allocationItemGUID) .. '\n')

        if exemptedReagents then
            editBox:Insert('exemptedReagents = \n')
            for itemID, dataSlotIndex in pairs(exemptedReagents) do
                editBox:Insert('    [' .. itemID .. '] = ' .. dataSlotIndex .. '\n')
            end
        else
            editBox:Insert('exemptedReagents = nil\n')
        end

        if slotModsFromOrderID then
            editBox:Insert('slotModsFromOrderID = \n')
            for index, slotMod in ipairs(slotModsFromOrderID) do
                editBox:Insert('    [' .. index .. '] = \n')
                editBox:Insert('        reagent = \n')
                if slotMod.reagent.itemID and slotMod.reagent.itemID > 0 then
                    local itemName = C_Item_GetItemNameByID(slotMod.reagent.itemID) or UNKNOWN
                    editBox:Insert('            itemID: ' .. slotMod.reagent.itemID .. ' ' .. itemName .. '\n')
                elseif slotMod.reagent.currencyID and slotMod.reagent.currencyID > 0 then
                    local currencyName = C_CurrencyInfo_GetCurrencyInfo(slotMod.reagent.currencyID).name or UNKNOWN
                    editBox:Insert('            currencyID: ' .. slotMod.reagent.currencyID .. ' ' .. currencyName .. '\n')
                end
                editBox:Insert('        dataSlotIndex: ' .. slotMod.dataSlotIndex .. '\n')
            end
        else
            editBox:Insert('slotModsFromOrderID = nil\n')
        end
    end
end

function PO:CheckProfessionTable()
    local profession = self:GetNearProfessionInfo()
    local isShown = self.quickWindow:IsShown()

    if profession and not isShown then
        _G.UIParent:UnregisterEvent('TRADE_SKILL_SHOW')

        wipe(self.pendingOrderIDs)

        self.quickWindow:Show()
    elseif not profession and isShown then
        _G.UIParent:RegisterEvent('TRADE_SKILL_SHOW')

        self.quickWindow:Hide()
    end
end

function PO:CheckZone()
    local uiMapID = C_Map_GetBestMapForUnit('player')
    if uiMapID == 2339 then -- Dornogal
        if not self.timer then
            self.timer = self:ScheduleRepeatingTimer('CheckProfessionTable', 1)
        end
    else
        if self.timer then
            self:CancelTimer(self.timer)
            self.timer = nil
        end

        self.quickWindow:Hide()
    end
end

function PO:Initialize()
    ---@type number[]
    self.pendingOrderIDs = {}

    R:RegisterAddOnLoad('Blizzard_Professions', function()
        local buttonProcess = CreateFrame('Button', nil, _G.ProfessionsFrame, 'UIPanelButtonTemplate')
        buttonProcess:ClearAllPoints()
        buttonProcess:SetPoint('BOTTOMLEFT', _G.ProfessionsFrame, 'TOPLEFT', 0, 2)
        buttonProcess:SetSize(80, 22)
        buttonProcess:SetText("处理订单")
        buttonProcess:SetScript('OnClick', function()
            PO:Process()
        end)

        S:HandleButton(buttonProcess)

        local buttonDebugOutput = CreateFrame('Button', nil, _G.ProfessionsFrame, 'UIPanelButtonTemplate')
        buttonDebugOutput:ClearAllPoints()
        buttonDebugOutput:SetPoint('BOTTOMLEFT', _G.ProfessionsFrame, 'TOPLEFT', 82, 2)
        buttonDebugOutput:SetSize(80, 22)
        buttonDebugOutput:SetText("调试输出")
        buttonDebugOutput:SetScript('OnClick', function()
            PO:DebugOutput()
        end)

        S:HandleButton(buttonDebugOutput)
    end)

    local window = CreateFrame('Frame', nil, E.UIParent, 'BackdropTemplate')
    window:SetTemplate('Transparent', true)
    window:SetFrameStrata('DIALOG')
    window:SetPoint('TOPLEFT', E.UIParent, 'CENTER', 100, 50)
    window:SetSize(100, 70)
    window:Hide()
    self.quickWindow = window

    local buttonProcess = CreateFrame('Button', nil, window)
    buttonProcess:SetTemplate('Default')
    buttonProcess:StyleButton()
    buttonProcess:ClearAllPoints()
    buttonProcess:SetPoint('TOP', window, 'TOP', 0, -10)
    buttonProcess:SetSize(80, 22)
    buttonProcess:SetScript('OnClick', function()
        PO:Process()
    end)

    buttonProcess.text = buttonProcess:CreateFontString(nil, 'ARTWORK')
    buttonProcess.text:ClearAllPoints()
    buttonProcess.text:SetPoint('CENTER', buttonProcess, 'CENTER', 0, 0)
    buttonProcess.text:SetSize(80, 22)
    buttonProcess.text:FontTemplate()
    buttonProcess.text:SetJustifyH('CENTER')
    buttonProcess.text:SetText("处理订单")

    local buttonOpenProfession = CreateFrame('Button', nil, window)
    buttonOpenProfession:SetTemplate('Default')
    buttonOpenProfession:StyleButton()
    buttonOpenProfession:ClearAllPoints()
    buttonOpenProfession:SetPoint('TOP', window, 'TOP', 0, -40)
    buttonOpenProfession:SetSize(80, 22)
    buttonOpenProfession:SetScript('OnClick', function()
        local _, currentSkillLineID = self:GetNearProfessionInfo()
        if not currentSkillLineID then return end

        ProfessionsFrame_LoadUI()
        C_TradeSkillUI_OpenTradeSkill(currentSkillLineID)

        _G.ProfessionsFrame:SetTab(_G.ProfessionsFrame.recipesTabID)
        ShowUIPanel(_G.ProfessionsFrame)
    end)

    buttonOpenProfession.text = buttonOpenProfession:CreateFontString(nil, 'ARTWORK')
    buttonOpenProfession.text:ClearAllPoints()
    buttonOpenProfession.text:SetPoint('CENTER', buttonOpenProfession, 'CENTER', 0, 0)
    buttonOpenProfession.text:SetSize(80, 22)
    buttonOpenProfession.text:FontTemplate()
    buttonOpenProfession.text:SetJustifyH('CENTER')
    buttonOpenProfession.text:SetText("打开专业")

    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'CheckZone')
    self:RegisterEvent('ZONE_CHANGED', 'CheckZone')
    self:RegisterEvent('ZONE_CHANGED_INDOORS', 'CheckZone')
    self:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'CheckZone')
    self:RegisterEvent('CRAFTINGORDERS_CLAIM_ORDER_RESPONSE', 'OrderResponse')
    self:RegisterEvent('CRAFTINGORDERS_FULFILL_ORDER_RESPONSE', 'OrderResponse')
    self:RegisterEvent('CRAFTINGORDERS_CLAIMED_ORDER_UPDATED', 'OrderUpdated')
end

-- R:RegisterModule(PO:GetName())
