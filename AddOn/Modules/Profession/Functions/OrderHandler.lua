local R, E, L, V, P, G = unpack((select(2, ...)))
---@class RhythmBoxProfessionModule
local RP = R:GetModule('Profession')

-- Lua functions
local ipairs, pairs = ipairs, pairs
local math_huge = math.huge
local math_max = math.max
local string_format = string.format
local table_insert = table.insert

-- WoW API / Variables
local C_CraftingOrders_GetCraftingOrderTime = C_CraftingOrders.GetCraftingOrderTime
local C_CraftingOrders_GetOrderClaimInfo = C_CraftingOrders.GetOrderClaimInfo
local C_CraftingOrders_OrderCanBeRecrafted = C_CraftingOrders.OrderCanBeRecrafted
local C_CurrencyInfo_GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo
local C_Item_GetItemCount = C_Item.GetItemCount
local C_Item_GetItemInfoInstant = C_Item.GetItemInfoInstant
local C_Texture_GetAtlasInfo = C_Texture.GetAtlasInfo
local C_TradeSkillUI_GetCategoryInfo = C_TradeSkillUI.GetCategoryInfo
local C_TradeSkillUI_GetConcentrationCurrencyID = C_TradeSkillUI.GetConcentrationCurrencyID
local C_TradeSkillUI_GetCraftingOperationInfo = C_TradeSkillUI.GetCraftingOperationInfo
local C_TradeSkillUI_GetCraftingOperationInfoForOrder = C_TradeSkillUI.GetCraftingOperationInfoForOrder
local C_TradeSkillUI_GetDependentReagents = C_TradeSkillUI.GetDependentReagents
local C_TradeSkillUI_GetItemSlotModificationsForOrder = C_TradeSkillUI.GetItemSlotModificationsForOrder
local C_TradeSkillUI_GetReagentSlotStatus = C_TradeSkillUI.GetReagentSlotStatus
local C_TradeSkillUI_GetRecipeCooldown = C_TradeSkillUI.GetRecipeCooldown
local C_TradeSkillUI_GetRecipeItemQualityInfo = C_TradeSkillUI.GetRecipeItemQualityInfo
local GetMoney = GetMoney

local CreateAtlasMarkup = CreateAtlasMarkup
local Round = Round
local SecondsToTime = SecondsToTime

local Constants_ProfessionConsts_PUBLIC_CRAFTING_ORDER_STALE_THRESHOLD = Constants.ProfessionConsts.PUBLIC_CRAFTING_ORDER_STALE_THRESHOLD
local Enum_CraftingOrderType_Public = Enum.CraftingOrderType.Public
local Enum_CraftingReagentType_Modifying = Enum.CraftingReagentType.Modifying
local Enum_TradeskillSlotDataType_ModifiedReagent = Enum.TradeskillSlotDataType.ModifiedReagent

local ERR_TOO_MUCH_GOLD = ERR_TOO_MUCH_GOLD
local OPTIONAL_REAGENT_TOOLTIP_SLOT_LOCKED_FORMAT = OPTIONAL_REAGENT_TOOLTIP_SLOT_LOCKED_FORMAT
local PROFESSIONS_CRAFTER_CANT_CLAIM_OWN = PROFESSIONS_CRAFTER_CANT_CLAIM_OWN
local PROFESSIONS_CRAFTER_CANT_CLAIM_REAGENT_SLOT = PROFESSIONS_CRAFTER_CANT_CLAIM_REAGENT_SLOT
local PROFESSIONS_CRAFTER_CANT_CLAIM_UNLEARNED = PROFESSIONS_CRAFTER_CANT_CLAIM_UNLEARNED
local PROFESSIONS_CRAFTER_OUT_OF_CLAIMS_FMT = PROFESSIONS_CRAFTER_OUT_OF_CLAIMS_FMT
local PROFESSIONS_CRAFTING_CONCENTRATION_TOGGLE_DISABLED = PROFESSIONS_CRAFTING_CONCENTRATION_TOGGLE_DISABLED
local PROFESSIONS_ORDER_HAS_MINIMUM_QUALITY_FMT = PROFESSIONS_ORDER_HAS_MINIMUM_QUALITY_FMT
local PROFESSIONS_RECIPE_COOLDOWN = PROFESSIONS_RECIPE_COOLDOWN

---@param order CraftingOrderInfo
---@param schematic CraftingRecipeSchematic
---@return table<number, boolean> reagentSlotProvidedByCustomer, CraftingReagentInfo[] providedNormalReagentInfos, CraftingReagentInfo[] providedModifiedReagentInfos, CraftingReagentInfo[] missingNormalReagentInfos, CraftingReagentInfo[][] missingModifiedReagentInfosReplaces
function RP:GetProvidedReagentInfo(order, schematic)
    ---@type table<number, boolean>
    local reagentSlotProvidedByCustomer = {}
    ---@type CraftingReagentInfo[]
    local providedNormalReagentInfos = {}
    ---@type CraftingReagentInfo[]
    local providedModifiedReagentInfos = {}
    ---@type CraftingReagentInfo[]
    local missingNormalReagentInfos = {}
    ---@type CraftingReagentInfo[][]
    local missingModifiedReagentInfosReplaces = {}

    if order.isRecraft then
        ---@type table<number, CraftingReagentInfo>
        local recraftItemProvidedReagents = {}
        ---@type table<number, boolean>
        local recraftItemProvidedReagentsItemIDs = {}
        ---@type table<number, boolean>
        local recraftItemProvidedReagentsCurrencyIDs = {}
        ---@type table<number, boolean>
        local providedReagentsItemIDs = {}
        ---@type table<number, boolean>
        local providedReagentsCurrencyIDs = {}

        local slotMods = C_TradeSkillUI_GetItemSlotModificationsForOrder(order.orderID)
        for dataSlotIndex, slotMod in ipairs(slotMods) do
            local itemID = slotMod.reagent.itemID
            local currencyID = slotMod.reagent.currencyID
            if (itemID and itemID > 0) or (currencyID and currencyID > 0) then
                for _, reagentSlotSchematic in ipairs(schematic.reagentSlotSchematics) do
                    if reagentSlotSchematic.dataSlotType == Enum_TradeskillSlotDataType_ModifiedReagent and reagentSlotSchematic.dataSlotIndex == dataSlotIndex then
                        recraftItemProvidedReagents[reagentSlotSchematic.slotIndex] = {
                            reagent = slotMod.reagent,
                            dataSlotIndex = dataSlotIndex,
                            quantity = reagentSlotSchematic.quantityRequired,
                        }
                        if itemID and itemID > 0 then
                            recraftItemProvidedReagentsItemIDs[itemID] = true
                        end
                        if currencyID and currencyID > 0 then
                            recraftItemProvidedReagentsCurrencyIDs[currencyID] = true
                        end

                        break
                    end
                end
            end
        end

        for _, orderReagentInfo in ipairs(order.reagents) do
            reagentSlotProvidedByCustomer[orderReagentInfo.slotIndex] = true

            local itemID = orderReagentInfo.reagentInfo.reagent.itemID
            local currencyID = orderReagentInfo.reagentInfo.reagent.currencyID
            if itemID and itemID > 0 then
                providedReagentsItemIDs[itemID] = true
            end
            if currencyID and currencyID > 0 then
                providedReagentsCurrencyIDs[currencyID] = true
            end
        end

        for slotIndex, reagentSlotSchematic in ipairs(schematic.reagentSlotSchematics) do
            if reagentSlotSchematic.dataSlotType == Enum_TradeskillSlotDataType_ModifiedReagent then
                -- recraft order can provide modified reagents through the recrafted item,
                -- which is stored in recraftItemProvidedReagents,
                -- or through order provided reagents, so we need to check both

                local provided = not not recraftItemProvidedReagents[slotIndex]
                for _, orderReagentInfo in ipairs(order.reagents) do
                    if orderReagentInfo.slotIndex == slotIndex then
                        table_insert(providedModifiedReagentInfos, orderReagentInfo.reagentInfo)

                        if recraftItemProvidedReagents[slotIndex] then
                            -- customer provided item overrides the recrafted item
                            local itemID = recraftItemProvidedReagents[slotIndex].reagent.itemID
                            local currencyID = recraftItemProvidedReagents[slotIndex].reagent.currencyID

                            if itemID and itemID > 0 then
                                recraftItemProvidedReagentsItemIDs[itemID] = nil
                            end
                            if currencyID and currencyID > 0 then
                                recraftItemProvidedReagentsCurrencyIDs[currencyID] = nil
                            end
                            recraftItemProvidedReagents[slotIndex] = nil
                        end

                        provided = true
                    end
                end

                if not provided and reagentSlotSchematic.required then
                    ---@type CraftingReagentInfo[]
                    local replace = {}

                    for _, reagent in ipairs(reagentSlotSchematic.reagents) do
                        ---@type CraftingReagentInfo
                        local data = {
                            reagent = reagent,
                            dataSlotIndex = reagentSlotSchematic.dataSlotIndex,
                            quantity = reagentSlotSchematic.quantityRequired,
                        }

                        table_insert(replace, data)
                    end

                    table_insert(missingModifiedReagentInfosReplaces, replace)
                end
            else
                -- recraft order can not provide normal / currency reagents through the recrafted item,
                -- so we can check this just like normal order

                local provided = false
                for _, orderReagentInfo in ipairs(order.reagents) do
                    if orderReagentInfo.slotIndex == slotIndex then
                        table_insert(providedNormalReagentInfos, orderReagentInfo.reagentInfo)
                        provided = true
                    end
                end

                if not provided and reagentSlotSchematic.required then
                    ---@type CraftingReagentInfo
                    local data = {
                        reagent = reagentSlotSchematic.reagents[1],
                        dataSlotIndex = reagentSlotSchematic.dataSlotIndex,
                        quantity = reagentSlotSchematic.quantityRequired,
                    }

                    table_insert(missingNormalReagentInfos, data)
                end
            end
        end

        local needUpdate = true
        while needUpdate do
            needUpdate = false

            for slotIndex, recraftItemProvidedReagent in pairs(recraftItemProvidedReagents) do
                local reagentItemID = recraftItemProvidedReagent.reagent.itemID
                local reagentCurrencyID = recraftItemProvidedReagent.reagent.currencyID
                if (reagentItemID and reagentItemID > 0) or (reagentCurrencyID and reagentCurrencyID > 0) then
                    local requirementReagents = C_TradeSkillUI_GetDependentReagents(recraftItemProvidedReagent.reagent)

                    local missingRequirement = false
                    for _, reagent in ipairs(requirementReagents) do
                        local itemID = reagent.itemID
                        local currencyID = reagent.currencyID
                        if itemID and itemID > 0 then
                            if not providedReagentsItemIDs[itemID] and not recraftItemProvidedReagentsItemIDs[itemID] then
                                missingRequirement = true
                                break
                            end
                        elseif currencyID and currencyID > 0 then
                            if not providedReagentsCurrencyIDs[currencyID] and not recraftItemProvidedReagentsCurrencyIDs[currencyID] then
                                missingRequirement = true
                                break
                            end
                        end
                    end

                    if missingRequirement then
                        if reagentItemID and reagentItemID > 0 then
                            recraftItemProvidedReagentsItemIDs[reagentItemID] = nil
                        end
                        if reagentCurrencyID and reagentCurrencyID > 0 then
                            recraftItemProvidedReagentsCurrencyIDs[reagentCurrencyID] = nil
                        end
                        recraftItemProvidedReagents[slotIndex] = nil
                        needUpdate = true
                        break
                    end
                end
            end
        end

        for slotIndex, recraftItemProvidedReagent in pairs(recraftItemProvidedReagents) do
            reagentSlotProvidedByCustomer[slotIndex] = true
            table_insert(providedModifiedReagentInfos, recraftItemProvidedReagent)
        end
    else
        for _, orderReagentInfo in ipairs(order.reagents) do
            reagentSlotProvidedByCustomer[orderReagentInfo.slotIndex] = true
        end

        for slotIndex, reagentSlotSchematic in ipairs(schematic.reagentSlotSchematics) do
            if reagentSlotSchematic.dataSlotType == Enum_TradeskillSlotDataType_ModifiedReagent then
                local provided = false
                for _, orderReagentInfo in ipairs(order.reagents) do
                    if orderReagentInfo.slotIndex == slotIndex then
                        table_insert(providedModifiedReagentInfos, orderReagentInfo.reagentInfo)
                        provided = true
                    end
                end

                if not provided and reagentSlotSchematic.required then
                    ---@type CraftingReagentInfo[]
                    local replace = {}

                    for _, reagent in ipairs(reagentSlotSchematic.reagents) do
                        ---@type CraftingReagentInfo
                        local data = {
                            reagent = reagent,
                            dataSlotIndex = reagentSlotSchematic.dataSlotIndex,
                            quantity = reagentSlotSchematic.quantityRequired,
                        }

                        table_insert(replace, data)
                    end

                    table_insert(missingModifiedReagentInfosReplaces, replace)
                end
            else
                local provided = false
                for _, orderReagentInfo in ipairs(order.reagents) do
                    if orderReagentInfo.slotIndex == slotIndex then
                        table_insert(providedNormalReagentInfos, orderReagentInfo.reagentInfo)
                        provided = true
                    end
                end

                if not provided and reagentSlotSchematic.required then
                    ---@type CraftingReagentInfo
                    local data = {
                        reagent = reagentSlotSchematic.reagents[1],
                        dataSlotIndex = reagentSlotSchematic.dataSlotIndex,
                        quantity = reagentSlotSchematic.quantityRequired,
                    }

                    table_insert(missingNormalReagentInfos, data)
                end
            end
        end
    end

    return reagentSlotProvidedByCustomer, providedNormalReagentInfos, providedModifiedReagentInfos, missingNormalReagentInfos, missingModifiedReagentInfosReplaces
end

---@param providedModifiedReagentInfos CraftingReagentInfo[]
---@param missingModifiedReagentInfos CraftingReagentInfo[]
---@return CraftingReagentInfo[] craftingReagents
function RP:MergeReagentInfos(providedModifiedReagentInfos, missingModifiedReagentInfos)
    ---@type CraftingReagentInfo[]
    local craftingReagents = {}
    for _, reagentInfo in ipairs(providedModifiedReagentInfos) do
        table_insert(craftingReagents, reagentInfo)
    end
    for _, reagentInfo in ipairs(missingModifiedReagentInfos) do
        table_insert(craftingReagents, reagentInfo)
    end
    return craftingReagents
end

---@param order CraftingOrderInfo
---@param providedModifiedReagentInfos CraftingReagentInfo[]
---@param missingModifiedReagentInfos CraftingReagentInfo[]
---@return CraftingOperationInfo? operationInfo, boolean applyConcentration
function RP:GetOperationInfo(order, providedModifiedReagentInfos, missingModifiedReagentInfos)
    ---@type CraftingReagentInfo[]
    local craftingReagents = self:MergeReagentInfos(providedModifiedReagentInfos, missingModifiedReagentInfos)

    local info = order.isRecraft
        and C_TradeSkillUI_GetCraftingOperationInfoForOrder(order.spellID, craftingReagents, order.orderID, false)
        or C_TradeSkillUI_GetCraftingOperationInfo(order.spellID, craftingReagents, nil, false)

    if not info or not info.isQualityCraft then
        return nil, false
    end

    if order.minQuality and order.minQuality <= info.craftingQuality then
        return info, false
    end

    if order.minQuality and order.minQuality <= info.craftingQuality + 1 then
        local concentrationInfo = C_TradeSkillUI_GetCraftingOperationInfoForOrder(order.spellID, craftingReagents, order.orderID, true)
        return concentrationInfo, true
    end

    return info, false
end

---@param order CraftingOrderInfo
---@param providedModifiedReagentInfos CraftingReagentInfo[]
---@param missingModifiedReagentInfosReplaces CraftingReagentInfo[][]
---@return CraftingReagentInfo[] missingModifiedReagentInfos, CraftingOperationInfo? operationInfo, boolean applyConcentration
function RP:GetOrderDefaultReagentInfo(order, providedModifiedReagentInfos, missingModifiedReagentInfosReplaces)
    ---@type CraftingReagentInfo[]
    local cheapestCraftingReagent = {}
    for _, replace in ipairs(missingModifiedReagentInfosReplaces) do
        local cheapestInfo = replace[1]
        local cheapestPrice = cheapestInfo.reagent.itemID and self:GetItemPrice(cheapestInfo.reagent.itemID) or math_huge

        for _, reagentInfo in ipairs(replace) do
            local price = reagentInfo.reagent.itemID and self:GetItemPrice(reagentInfo.reagent.itemID) or math_huge
            if price < cheapestPrice then
                cheapestInfo = reagentInfo
                cheapestPrice = price
            end
        end

        table_insert(cheapestCraftingReagent, cheapestInfo)
    end

    local operationInfo, applyConcentration = self:GetOperationInfo(order, providedModifiedReagentInfos, cheapestCraftingReagent)
    if not operationInfo or not operationInfo.isQualityCraft then
        return cheapestCraftingReagent, nil, false
    end

    if order.minQuality and order.minQuality <= operationInfo.craftingQuality then
        return cheapestCraftingReagent, operationInfo, applyConcentration
    end

    -- auto apply concentration in self:GetOperationInfo,
    -- if it's still not meet the requirement,
    -- it should not able to meet the requirement with cheapest reagents,
    -- so try max quality reagents

    local maxQualityCraftingReagent = {}
    for _, replace in ipairs(missingModifiedReagentInfosReplaces) do
        table_insert(maxQualityCraftingReagent, replace[#replace])
    end

    -- return anyway since it's handled in self:GetOperationInfo

    return maxQualityCraftingReagent, self:GetOperationInfo(order, providedModifiedReagentInfos, maxQualityCraftingReagent)
end

do
    ---@param slotInfo CraftingReagentSlotInfo|nil
    ---@param recipeInfo TradeSkillRecipeInfo
    ---@return boolean, string|nil
    local function GetReagentSlotStatus(slotInfo, recipeInfo)
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
                return true, string_format(OPTIONAL_REAGENT_TOOLTIP_SLOT_LOCKED_FORMAT, slotInfo.requiredSkillRank)
            end
        end

        return false
    end

    ---@param order CraftingOrderInfo
    ---@param recipeInfo TradeSkillRecipeInfo
    ---@param schematic CraftingRecipeSchematic
    ---@param professionInfo ProfessionInfo
    ---@param reagentSlotProvidedByCustomer table<number, boolean>
    ---@param operationInfo CraftingOperationInfo?
    ---@param applyConcentration boolean
    ---@return string? failReason
    function RP:GetOrderFailReason(order, recipeInfo, schematic, professionInfo, reagentSlotProvidedByCustomer, operationInfo, applyConcentration)
        -- ProfessionsCrafterOrderViewMixin:UpdateStartOrderButton
        if order.customerGuid == E.myguid then
            return PROFESSIONS_CRAFTER_CANT_CLAIM_OWN
        end

        if order.orderType == Enum_CraftingOrderType_Public then
            local claimInfo = C_CraftingOrders_GetOrderClaimInfo(professionInfo.profession)
            if (
                claimInfo and claimInfo.claimsRemaining <= 0
                and math_max(order.expirationTime - C_CraftingOrders_GetCraftingOrderTime(), 0) > Constants_ProfessionConsts_PUBLIC_CRAFTING_ORDER_STALE_THRESHOLD
            ) then
                return string_format(PROFESSIONS_CRAFTER_OUT_OF_CLAIMS_FMT, SecondsToTime(claimInfo.secondsToRecharge))
            end
        end

        if not recipeInfo.learned or (order.isRecraft and not C_CraftingOrders_OrderCanBeRecrafted(order.orderID)) then
            return PROFESSIONS_CRAFTER_CANT_CLAIM_UNLEARNED
        end

        for slotIndex in pairs(reagentSlotProvidedByCustomer) do
            local reagentSlotSchematic = schematic.reagentSlotSchematics[slotIndex]
            if reagentSlotSchematic.reagentType == Enum_CraftingReagentType_Modifying then
                local locked = GetReagentSlotStatus(reagentSlotSchematic.slotInfo, recipeInfo)
                if locked then
                    return PROFESSIONS_CRAFTER_CANT_CLAIM_REAGENT_SLOT
                end
            end
        end

        -- ProfessionsCrafterOrderViewMixin:UpdateCreateButton
        local cooldown, _, charges = C_TradeSkillUI_GetRecipeCooldown(order.spellID)
        if cooldown and charges <= 0 then
            return PROFESSIONS_RECIPE_COOLDOWN
        end

        -- transaction:HasMetAllRequirements()
        -- XXX: check this in other place

        if order.minQuality and operationInfo and operationInfo.craftingQuality < order.minQuality then
            ---@type CraftingQualityInfo
            local info = C_TradeSkillUI_GetRecipeItemQualityInfo(order.spellID, order.minQuality)

            local atlasInfo = C_Texture_GetAtlasInfo(info.iconChat)
            local scale = 0.4
            local width = Round(atlasInfo.width * scale)
            local height = Round(atlasInfo.height * scale)

            local atlas = CreateAtlasMarkup(info.iconChat, width, height)
            return string_format(PROFESSIONS_ORDER_HAS_MINIMUM_QUALITY_FMT, atlas)
        end

        -- ProfessionsConcentrateToggleButtonMixin:HasEnoughConcentration
        if operationInfo and applyConcentration then
            local currencyType = C_TradeSkillUI_GetConcentrationCurrencyID(professionInfo.professionID)
            local currencyInfo = C_CurrencyInfo_GetCurrencyInfo(currencyType)
            if currencyInfo.quantity < operationInfo.concentrationCost then
                return string_format(PROFESSIONS_CRAFTING_CONCENTRATION_TOGGLE_DISABLED, currencyInfo.name)
            end
        end

        -- ProfessionsCrafterOrderViewMixin:UpdateFulfillButton
        local maxGold = 99999999999
        if GetMoney() + order.tipAmount - order.consortiumCut > maxGold then
            return ERR_TOO_MUCH_GOLD
        end

        return nil
    end
end

do
    local knowledgeItemIDs = {
        -- Khaz Algar
        [228724] = 1, -- Flicker of Alchemy Knowledge
		[228725] = 2, -- Glimmer of Alchemy Knowledge
		[228726] = 1, -- Flicker of Blacksmithing Knowledge
		[228727] = 2, -- Glimmer of Blacksmithing Knowledge
		[228728] = 1, -- Flicker of Enchanting Knowledge
		[228729] = 2, -- Glimmer of Enchanting Knowledge
		[228730] = 1, -- Flicker of Engineering Knowledge
		[228731] = 2, -- Glimmer of Engineering Knowledge
		[228732] = 1, -- Flicker of Inscription Knowledge
		[228733] = 2, -- Glimmer of Inscription Knowledge
		[228734] = 1, -- Flicker of Jewelcrafting Knowledge
		[228735] = 2, -- Glimmer of Jewelcrafting Knowledge
		[228736] = 1, -- Flicker of Leatherworking Knowledge
		[228737] = 2, -- Glimmer of Leatherworking Knowledge
		[228738] = 1, -- Flicker of Tailoring Knowledge
		[228739] = 2, -- Glimmer of Tailoring Knowledge
        -- Midnight
		[246320] = 1, -- Flicker of Midnight Alchemy Knowledge
		[246321] = 2, -- Glimmer of Midnight Alchemy Knowledge
		[246322] = 1, -- Flicker of Midnight Blacksmithing Knowledge
		[246323] = 2, -- Glimmer of Midnight Blacksmithing Knowledge
		[246324] = 1, -- Flicker of Midnight Enchanting Knowledge
		[246325] = 2, -- Glimmer of Midnight Enchanting Knowledge
		[246326] = 1, -- Flicker of Midnight Engineering Knowledge
		[246327] = 2, -- Glimmer of Midnight Engineering Knowledge
		[246328] = 1, -- Flicker of Midnight Inscription Knowledge
		[246329] = 2, -- Glimmer of Midnight Inscription Knowledge
		[246330] = 1, -- Flicker of Midnight Jewelcrafting Knowledge
		[246331] = 2, -- Glimmer of Midnight Jewelcrafting Knowledge
		[246332] = 1, -- Flicker of Midnight Leatherworking Knowledge
		[246333] = 2, -- Glimmer of Midnight Leatherworking Knowledge
		[246334] = 1, -- Flicker of Midnight Tailoring Knowledge
		[246335] = 2, -- Glimmer of Midnight Tailoring Knowledge
    }

    ---@param order CraftingOrderInfo
    ---@return boolean contains
    function RP:IsRewardContainsKnowledge(order)
        for _, reward in ipairs(order.npcOrderRewards) do
            if reward.itemLink then
                local itemID = C_Item_GetItemInfoInstant(reward.itemLink)

                if knowledgeItemIDs[itemID] then
                    return true
                end
            end
        end

        return false
    end
end

do
    ---@param reagentInfo CraftingReagentInfo
    ---@return boolean isReady
    local function IsReagentInfoReady(reagentInfo)
        local itemID = reagentInfo.reagent.itemID
        local currencyID = reagentInfo.reagent.currencyID

        if itemID then
            local count = C_Item_GetItemCount(itemID, true, nil, true, true)
            if count < reagentInfo.quantity then
                return false
            end
        elseif currencyID then
            local info = C_CurrencyInfo_GetCurrencyInfo(currencyID)
            if info.quantity < reagentInfo.quantity then
                return false
            end
        end

        return true
    end

    ---@param missingNormalReagentInfos CraftingReagentInfo[]
    ---@param missingModifiedReagentInfos CraftingReagentInfo[]
    ---@return boolean isReady
    function RP:IsReagentReady(missingNormalReagentInfos, missingModifiedReagentInfos)
        for _, reagentInfo in ipairs(missingNormalReagentInfos) do
            local isReady = IsReagentInfoReady(reagentInfo)
            if not isReady then
                return false
            end
        end

        for _, reagentInfo in ipairs(missingModifiedReagentInfos) do
            local isReady = IsReagentInfoReady(reagentInfo)
            if not isReady then
                return false
            end
        end

        return true
    end
end
