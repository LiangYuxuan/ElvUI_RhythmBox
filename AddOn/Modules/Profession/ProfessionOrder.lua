local R, E, L, V, P, G = unpack((select(2, ...)))
---@class RhythmBoxProfessionOrderModule: AceModule
local RPO = R:NewModule('ProfessionOrder', 'AceEvent-3.0', 'AceTimer-3.0')
---@type RhythmBoxProfessionModule
local RP = R:GetModule('Profession')
local S = E:GetModule('Skins')
local LSM = E.Libs.LSM

-- Lua functions
local _G = _G
local ipairs, pairs, select, tostring = ipairs, pairs, select, tostring
local math_abs = math.abs
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local string_format = string.format
local table_insert = table.insert

-- WoW API / Variables
local C_CraftingOrders_ClaimOrder = C_CraftingOrders.ClaimOrder
local C_CraftingOrders_FulfillOrder = C_CraftingOrders.FulfillOrder
local C_CraftingOrders_GetClaimedOrder = C_CraftingOrders.GetClaimedOrder
local C_CraftingOrders_GetCraftingOrderTime = C_CraftingOrders.GetCraftingOrderTime
local C_CraftingOrders_OpenCrafterCraftingOrders = C_CraftingOrders.OpenCrafterCraftingOrders
local C_CraftingOrders_ReleaseOrder = C_CraftingOrders.ReleaseOrder
local C_CurrencyInfo_GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo
local C_CurrencyInfo_GetCurrencyLink = C_CurrencyInfo.GetCurrencyLink
local C_Item_GetItemIconByID = C_Item.GetItemIconByID
local C_Item_GetItemInfoInstant = C_Item.GetItemInfoInstant
local C_Item_GetItemQualityByID = C_Item.GetItemQualityByID
local C_Item_GetItemQualityColor = C_Item.GetItemQualityColor
local C_ProfSpecs_GetCurrencyInfoForSkillLine = C_ProfSpecs.GetCurrencyInfoForSkillLine
local C_TradeSkillUI_CloseTradeSkill = C_TradeSkillUI.CloseTradeSkill
local C_TradeSkillUI_CraftRecipe = C_TradeSkillUI.CraftRecipe
local C_TradeSkillUI_GetBaseProfessionInfo = C_TradeSkillUI.GetBaseProfessionInfo
local C_TradeSkillUI_GetChildProfessionInfo = C_TradeSkillUI.GetChildProfessionInfo
local C_TradeSkillUI_GetChildProfessionInfos = C_TradeSkillUI.GetChildProfessionInfos
local C_TradeSkillUI_GetConcentrationCurrencyID = C_TradeSkillUI.GetConcentrationCurrencyID
local C_TradeSkillUI_GetItemReagentQualityInfo = C_TradeSkillUI.GetItemReagentQualityInfo
local C_TradeSkillUI_GetProfessionInfoBySkillLineID = C_TradeSkillUI.GetProfessionInfoBySkillLineID
local C_TradeSkillUI_GetRecipeInfo = C_TradeSkillUI.GetRecipeInfo
local C_TradeSkillUI_GetRecipeItemQualityInfo = C_TradeSkillUI.GetRecipeItemQualityInfo
local C_TradeSkillUI_GetRecipeOutputItemData = C_TradeSkillUI.GetRecipeOutputItemData
local C_TradeSkillUI_GetRecipeSchematic = C_TradeSkillUI.GetRecipeSchematic
local C_TradeSkillUI_IsNearProfessionSpellFocus = C_TradeSkillUI.IsNearProfessionSpellFocus
local C_TradeSkillUI_IsTradeSkillReady = C_TradeSkillUI.IsTradeSkillReady
local C_TradeSkillUI_OpenTradeSkill = C_TradeSkillUI.OpenTradeSkill
local C_TradeSkillUI_RecraftRecipeForOrder = C_TradeSkillUI.RecraftRecipeForOrder
local C_TradeSkillUI_SetProfessionChildSkillLineID = C_TradeSkillUI.SetProfessionChildSkillLineID
local CreateFrame = CreateFrame
local GetProfessionInfo = GetProfessionInfo
local GetProfessions = GetProfessions
local GetQuestResetTime = GetQuestResetTime
local IsResting = IsResting
local UnitCastingDuration = UnitCastingDuration

local CreateDataProvider = CreateDataProvider
local CreateScrollBoxListLinearView = CreateScrollBoxListLinearView
local HandleModifiedItemClick = HandleModifiedItemClick
local Item = Item
local ScrollUtil_InitScrollBoxListWithScrollBar = ScrollUtil.InitScrollBoxListWithScrollBar
local tIndexOf = tIndexOf

local Enum_CraftingOrderResult_Ok = Enum.CraftingOrderResult.Ok
local Enum_CraftingOrderType_Npc = Enum.CraftingOrderType.Npc

local PROFESSIONS_CRAFTING_FORM_NOTE_TO_CRAFTER = PROFESSIONS_CRAFTING_FORM_NOTE_TO_CRAFTER
local PROFESSIONS_CUSTOMER_NO_ORDERS = PROFESSIONS_CUSTOMER_NO_ORDERS

local orderTypeTextMap = {
    [Enum.CraftingOrderType.Public] = '公共',
    [Enum.CraftingOrderType.Guild] = '公会',
    [Enum.CraftingOrderType.Personal] = '个人',
    [Enum.CraftingOrderType.Npc] = '客人',
}

---@class ProfessionOrderData
---@field frame ProfessionOrderWindowOrderLine?
---@field order CraftingOrderInfo
---@field recipeInfo TradeSkillRecipeInfo
---@field schematic CraftingRecipeSchematic
---@field rewardPrice number
---@field reagentSlotProvidedByCustomer table<number, boolean>
---@field providedNormalReagentInfos CraftingReagentInfo[]
---@field providedModifiedReagentInfos CraftingReagentInfo[]
---@field missingNormalReagentInfos CraftingReagentInfo[]
---@field missingModifiedReagentInfosReplaces CraftingReagentInfo[][]
---@field missingModifiedReagentInfos CraftingReagentInfo[]
---@field costPrice number
---@field operationInfo CraftingOperationInfo?
---@field applyConcentration boolean
---@field failReason string?
---@field isReagentReady boolean
---@field isClaimed boolean
---@field duration DurationObject?
---@field isPending boolean

---@class ProfessionOrderWindowOrderLine: Button
---@field isCreated boolean
---@field timeElapsed number
---@field data ProfessionOrderData
---@field highlight Texture
---@field progress StatusBar
---@field itemIcon ProfessionOrderWindowOrderLineItemIcon
---@field minQuality Texture
---@field itemName FontString
---@field orderType FontString
---@field remainingTime FontString
---@field orderNote Texture
---@field craftQuality Texture
---@field profitText FontString
---@field rewards ProfessionOrderWindowOrderLineReward[]
---@field rewardText FontString
---@field reagents ProfessionOrderWindowOrderLineReagent[]
---@field costText FontString

---@param searchValue number
---@param tableName string
---@return string
local function GetEnumOutputText(searchValue, tableName)
    for key, value in pairs(_G.Enum[tableName]) do
        if value == searchValue then
            return '(Enum.' .. tableName .. '.' .. key .. ')'
        end
    end
    return tostring(searchValue) .. ' (Enum.' .. tableName .. '.Unknown)'
end

---@param delta number
---@return string
local function GetTimeText(delta)
    local days = math_floor(delta / 86400)
    local hours = math_floor((delta % 86400) / 3600)
    local minutes = math_floor((delta % 3600) / 60)
    local text = string_format('%d:%02d:%02d', days, hours, minutes)
    return text
end

local function buttonOnClickHandleCraftingOrders()
    local profession = RPO.window.professionInfo.profession
    local claimedOrder = C_CraftingOrders_GetClaimedOrder()
    if claimedOrder then
        if claimedOrder.isFulfillable then
            -- known order and fulfillable, fulfill
            C_CraftingOrders_FulfillOrder(claimedOrder.orderID, '', profession)
            RPO:LockOrderWindowButton()
            return
        end

        ---@param data ProfessionOrderData
        ---@return boolean
        local function predicate(data)
            return data.order.orderID == claimedOrder.orderID
        end

        ---@type ProfessionOrderData?
        local data = RPO.dataProvider:FindElementDataByPredicate(predicate)
        if not data or data.failReason or not data.isPending then
            -- unknown order, or unable to fulfill, or not pending, release
            C_CraftingOrders_ReleaseOrder(claimedOrder.orderID, profession)
            RPO:LockOrderWindowButton()
            return
        end

        if not data.isReagentReady then
            -- known order but not ready, release
            C_CraftingOrders_ReleaseOrder(claimedOrder.orderID, profession)
            RPO:LockOrderWindowButton()
            return
        end

        -- no lock until UNIT_SPELLCAST_START found this spellID
        if claimedOrder.isRecraft then
            C_TradeSkillUI_RecraftRecipeForOrder(claimedOrder.orderID, claimedOrder.outputItemGUID, data.missingModifiedReagentInfos, nil, data.applyConcentration)
            return
        else
            C_TradeSkillUI_CraftRecipe(claimedOrder.spellID, 1, data.missingModifiedReagentInfos, nil, claimedOrder.orderID, data.applyConcentration)
            return
        end
    end

    -- no claimed order, try to claim one

    local isConcentrationEnough = RPO.window.isConcentrationEnough

    ---@param data ProfessionOrderData
    ---@return boolean
    local function predicate(data)
        return not data.failReason and data.isReagentReady and data.isPending and (isConcentrationEnough or not data.applyConcentration)
    end

    ---@type ProfessionOrderData?
    local data = RPO.dataProvider:FindElementDataByPredicate(predicate)
    if not data then return end

    C_CraftingOrders_ClaimOrder(data.order.orderID, profession)
    RPO:LockOrderWindowButton()
end

---@param result Enum.CraftingOrderResult
---@param orders CraftingOrderInfo[]
local function callbackGetCraftingOrders(result, orders)
    local window = RPO.window
    local professionInfo = window.professionInfo

    window.loadingSpinner:Hide()

    if result ~= Enum_CraftingOrderResult_Ok then
        window.orderResultText:SetText('获取订单失败: ' .. GetEnumOutputText(result, 'CraftingOrderResult'))

        return
    end

    local claimedOrder = C_CraftingOrders_GetClaimedOrder()
    if claimedOrder then
        -- claimed order is not included in orders, need to add it manually
        table_insert(orders, 1, claimedOrder)
    end

    if #orders == 0 then
        window.orderResultText:SetText(PROFESSIONS_CUSTOMER_NO_ORDERS)

        return
    end

    window.orderResultText:SetText('')

    ---@type ProfessionOrderData[]
    local professionOrders = {}

    local claimedOrderID = claimedOrder and claimedOrder.orderID or nil
    for _, order in ipairs(orders) do
        local recipeInfo = C_TradeSkillUI_GetRecipeInfo(order.spellID)
        local schematic = C_TradeSkillUI_GetRecipeSchematic(order.spellID, order.isRecraft)

        local rewardPrice = order.tipAmount - order.consortiumCut
        for _, reward in ipairs(order.npcOrderRewards) do
            if reward.itemLink then
                local itemID = C_Item_GetItemInfoInstant(reward.itemLink)
                local price = RP:GetItemPrice(itemID)
                rewardPrice = rewardPrice + price * reward.count
            end
        end

        local reagentSlotProvidedByCustomer, providedNormalReagentInfos, providedModifiedReagentInfos, missingNormalReagentInfos, missingModifiedReagentInfosReplaces = RP:GetProvidedReagentInfo(order, schematic)
        local missingModifiedReagentInfos, operationInfo, applyConcentration = RP:GetOrderDefaultReagentInfo(order, providedModifiedReagentInfos, missingModifiedReagentInfosReplaces)
        local costPrice = RP:GetReagentsCostPrice(missingNormalReagentInfos, missingModifiedReagentInfos)
        local failReason = RP:GetOrderFailReason(order, recipeInfo, schematic, professionInfo, reagentSlotProvidedByCustomer, operationInfo, applyConcentration)
        local isReagentReady = RP:IsReagentReady(missingNormalReagentInfos, missingModifiedReagentInfos)
        local isPending = (not failReason) and (
            (rewardPrice >= costPrice)
            or (recipeInfo and recipeInfo.firstCraft)
            or (RP:IsRewardContainsKnowledge(order))
        )

        ---@type ProfessionOrderData
        local data = {
            order = order,
            recipeInfo = recipeInfo,
            schematic = schematic,
            rewardPrice = rewardPrice,
            reagentSlotProvidedByCustomer = reagentSlotProvidedByCustomer,
            providedNormalReagentInfos = providedNormalReagentInfos,
            providedModifiedReagentInfos = providedModifiedReagentInfos,
            missingNormalReagentInfos = missingNormalReagentInfos,
            missingModifiedReagentInfosReplaces = missingModifiedReagentInfosReplaces,
            missingModifiedReagentInfos = missingModifiedReagentInfos,
            costPrice = costPrice,
            operationInfo = operationInfo,
            applyConcentration = applyConcentration,
            failReason = failReason,
            isReagentReady = isReagentReady,
            isClaimed = claimedOrderID and claimedOrderID == order.orderID or false,
            isPending = isPending,
        }
        table_insert(professionOrders, data)
    end

    RPO.dataProvider:InsertTable(professionOrders)
end

local function buttonOnClickGetCraftingOrders()
    local profession = RPO:GetNearProfessionInfo()
    if not profession then return end

    RPO.dataProvider:Flush()

    RPO.window.loadingSpinner:Show()

    RP:GetCraftingOrders(profession, callbackGetCraftingOrders)
end

local function buttonOnClickOpenOrder()
    RPO:OpenOrder()
end

---@param orderID number
function RPO:CRAFTINGORDERS_CLAIMED_ORDER_UPDATED(_, orderID)
    local claimedOrder = C_CraftingOrders_GetClaimedOrder()
    if claimedOrder and claimedOrder.orderID == orderID and claimedOrder.isFulfillable then
        C_CraftingOrders_FulfillOrder(orderID, '', RPO.window.professionInfo.profession)
        self:LockOrderWindowButton()
    end

    -- auto fulfill, so no unlock here,
    -- also it's unlocked by UNIT_SPELLCAST_SUCCEEDED already
end

---@param orderID number
function RPO:CRAFTINGORDERS_REJECT_ORDER_RESPONSE(_, _, orderID)
    -- remove order whatever it's rejected successfully or not

    ---@param data ProfessionOrderData
    ---@return boolean
    local function predicate(data)
        return data.order.orderID == orderID
    end

    ---@type number?
    local index = self.dataProvider:FindByPredicate(predicate)
    if index then
        self.dataProvider:RemoveIndex(index)
    end

    self:UnlockOrderWindowButton()
end

---@param orderID number
function RPO:CRAFTINGORDERS_FULFILL_ORDER_RESPONSE(_, _, orderID)
    -- remove order whatever it's fulfilled successfully or not

    ---@param data ProfessionOrderData
    ---@return boolean
    local function predicate(data)
        return data.order.orderID == orderID
    end

    local index = self.dataProvider:FindByPredicate(predicate)
    if index then
        self.dataProvider:RemoveIndex(index)
    end

    -- some orders will be not possible to do after other order is fulfilled,
    -- like public orders after capacity is reached,
    -- and spells with cooldown or charge,
    -- so check all orders' fail reason to update their status
    local professionInfo = self.window.professionInfo
    for _, data in self.dataProvider:Enumerate() do
        ---@cast data ProfessionOrderData

        local failReason = RP:GetOrderFailReason(data.order, data.recipeInfo, data.schematic, professionInfo, data.reagentSlotProvidedByCustomer, data.operationInfo, data.applyConcentration)
        if data.failReason ~= failReason then
            data.failReason = failReason

            self.dataProvider:TriggerEvent('OnValueChanged', data)
        end
    end

    self:UnlockOrderWindowButton()
end

---@param result Enum.CraftingOrderResult
---@param orderID number
function RPO:CRAFTINGORDERS_RELEASE_ORDER_RESPONSE(_, result, orderID)
    ---@param data ProfessionOrderData
    ---@return boolean
    local function predicate(data)
        return data.order.orderID == orderID
    end

    ---@type number?, ProfessionOrderData
    local index, data = self.dataProvider:FindByPredicate(predicate)
    if index then
        if result == Enum_CraftingOrderResult_Ok then
            data.isClaimed = false
            self.dataProvider:TriggerEvent('OnValueChanged', data)
        else
            -- remove order if it failed to be released
            self.dataProvider:RemoveIndex(index)
        end
    end

    self:UnlockOrderWindowButton()
end

---@param result Enum.CraftingOrderResult
---@param orderID number
function RPO:CRAFTINGORDERS_CLAIM_ORDER_RESPONSE(_, result, orderID)
    ---@param data ProfessionOrderData
    ---@return boolean
    local function predicate(data)
        return data.order.orderID == orderID
    end

    ---@type number?, ProfessionOrderData
    local index, data = self.dataProvider:FindByPredicate(predicate)
    if index then
        if result == Enum_CraftingOrderResult_Ok then
            data.isClaimed = true
            self.dataProvider:TriggerEvent('OnValueChanged', data)
        else
            -- remove order if it failed to be claimed
            self.dataProvider:RemoveIndex(index)
        end
    end

    self:UnlockOrderWindowButton()
end

---@param unitTarget string
function RPO:ClearOrderLineProgress(_, unitTarget)
    if unitTarget ~= 'player' then return end

    for _, data in self.dataProvider:Enumerate() do
        ---@cast data ProfessionOrderData

        if data.duration then
            data.duration = nil

            self.dataProvider:TriggerEvent('OnValueChanged', data)
        end
    end

    self:UnlockOrderWindowButton()
end

---@param unitTarget string
---@param spellID number
function RPO:SetOrderLineProgress(_, unitTarget, _, spellID)
    if unitTarget ~= 'player' then return end

    local claimedOrder = C_CraftingOrders_GetClaimedOrder()
    if not claimedOrder or claimedOrder.spellID ~= spellID then return end

    local claimedOrderID = claimedOrder.orderID

    ---@param data ProfessionOrderData
    ---@return boolean
    local function predicate(data)
        return data.order.orderID == claimedOrderID
    end

    ---@type number?, ProfessionOrderData
    local index, data = self.dataProvider:FindByPredicate(predicate)
    if index then
        data.duration = UnitCastingDuration('player')
        self.dataProvider:TriggerEvent('OnValueChanged', data)
    end

    self:LockOrderWindowButton()
end

function RPO:BAG_UPDATE_DELAYED()
    for _, data in self.dataProvider:Enumerate() do
        ---@cast data ProfessionOrderData

        local isReagentReady = RP:IsReagentReady(data.missingNormalReagentInfos, data.missingModifiedReagentInfos)
        if data.isReagentReady ~= isReagentReady then
            data.isReagentReady = isReagentReady

            self.dataProvider:TriggerEvent('OnValueChanged', data)
        end
    end
end

function RPO:TRADE_SKILL_CLOSE()
    self:UpdateOrderWindow()
end

function RPO:TRADE_SKILL_SHOW()
    _G.UIParent:RegisterEvent('TRADE_SKILL_SHOW')

    self:ScheduleTimer('OpenOrderWindow', 0)
end

function RPO:OnOrderWindowClose()
    self:UnregisterEvent('TRADE_SKILL_SHOW')
    self:UnregisterEvent('TRADE_SKILL_CLOSE')
    self:UnregisterEvent('BAG_UPDATE_DELAYED')
    self:UnregisterEvent('UNIT_SPELLCAST_START')
    self:UnregisterEvent('UNIT_SPELLCAST_SUCCEEDED')
    self:UnregisterEvent('UNIT_SPELLCAST_STOP')
    self:UnregisterEvent('UNIT_SPELLCAST_INTERRUPTED')
    self:UnregisterEvent('CRAFTINGORDERS_CLAIM_ORDER_RESPONSE')
    self:UnregisterEvent('CRAFTINGORDERS_RELEASE_ORDER_RESPONSE')
    self:UnregisterEvent('CRAFTINGORDERS_REJECT_ORDER_RESPONSE')
    self:UnregisterEvent('CRAFTINGORDERS_FULFILL_ORDER_RESPONSE')
    self:UnregisterEvent('CRAFTINGORDERS_CLAIMED_ORDER_UPDATED')

    _G.UIParent:RegisterEvent('TRADE_SKILL_SHOW')

    self.dataProvider:Flush()
end

function RPO:OpenOrder()
    local _, skillLineID = self:GetNearProfessionInfo()
    if not skillLineID then return end

    self:RegisterEvent('TRADE_SKILL_SHOW')
    self:RegisterEvent('TRADE_SKILL_CLOSE')
    self:RegisterEvent('BAG_UPDATE_DELAYED')
    self:RegisterEvent('UNIT_SPELLCAST_START', 'SetOrderLineProgress')
    self:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED', 'ClearOrderLineProgress')
    self:RegisterEvent('UNIT_SPELLCAST_STOP', 'ClearOrderLineProgress')
    self:RegisterEvent('UNIT_SPELLCAST_INTERRUPTED', 'ClearOrderLineProgress')
    self:RegisterEvent('CRAFTINGORDERS_CLAIM_ORDER_RESPONSE')
    self:RegisterEvent('CRAFTINGORDERS_RELEASE_ORDER_RESPONSE')
    self:RegisterEvent('CRAFTINGORDERS_REJECT_ORDER_RESPONSE')
    self:RegisterEvent('CRAFTINGORDERS_FULFILL_ORDER_RESPONSE')
    self:RegisterEvent('CRAFTINGORDERS_CLAIMED_ORDER_UPDATED')

    local isReady = C_TradeSkillUI_IsTradeSkillReady()
    local info = C_TradeSkillUI_GetBaseProfessionInfo()
    if isReady and info.professionID == skillLineID then
        -- already opened with correct base profession, just open order window
        C_CraftingOrders_OpenCrafterCraftingOrders()

        self:OpenOrderWindow()

        return
    end

    -- to prevent default profession window from showing
    _G.UIParent:UnregisterEvent('TRADE_SKILL_SHOW')

    C_TradeSkillUI_OpenTradeSkill(skillLineID)
    C_CraftingOrders_OpenCrafterCraftingOrders()
end

function RPO:CheckProfessionTable()
    if self.window:IsShown() then
        self:UpdateOrderWindow()
        return
    end

    local profession = self:GetNearProfessionInfo()
    local isShown = self.quickWindow:IsShown()

    if profession and not isShown then
        self.quickWindow:Show()
    elseif not profession and isShown then
        self.quickWindow:Hide()
    end
end

function RPO:CheckZone()
    if IsResting() then
        if not self.quickWindowTimer then
            self.quickWindowTimer = self:ScheduleRepeatingTimer('CheckProfessionTable', 0.2)
        end
    else
        if self.quickWindowTimer then
            self:CancelTimer(self.quickWindowTimer)
            self.quickWindowTimer = nil
        end

        self.quickWindow:Hide()

        if self.window:IsShown() then
            self:UpdateOrderWindow()
        end
    end
end

---@return Enum.Profession? profession, number? skillLineID
function RPO:GetNearProfessionInfo()
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

do
    local COLOR_COPPER, COLOR_SILVER, COLOR_GOLD = '|cffeda55f', '|cffc7c7cf', '|cffffd700'
    ---@param money number
    ---@return string
    local function GetMoneyText(money)
        local prefix = money > 0 and '+' or (money < 0 and '-' or '')
        local value = math_abs(money)
        local gold = math_floor(value / 10000)
        local silver = math_floor((value % 10000) / 100)
        local copper = value % 100

		if gold > 0 then
			return string_format('%s %s%d|r %s%02d|r %s%02d|r', prefix, COLOR_GOLD, gold, COLOR_SILVER, silver, COLOR_COPPER, copper)
		elseif silver > 0 then
			return string_format('%s %s%d|r %s%02d|r', prefix, COLOR_SILVER, silver, COLOR_COPPER, copper)
		else
			return string_format('%s %s%d|r', prefix, COLOR_COPPER, copper)
		end
    end

    ---@param frame ProfessionOrderWindowOrderLine
    ---@param data ProfessionOrderData
    function RPO:SetupOrderLine(frame, data)
        frame.data = data
        data.frame = frame

        local order = data.order

        if data.failReason then
            frame:SetBackdropColor(255 / 255, 107 / 255, 107 / 255, 0.1)
        elseif not data.isPending then
            frame:SetBackdropColor(26 / 255, 26 / 255, 26 / 255, 0.1)
        elseif not data.isReagentReady then
            frame:SetBackdropColor(255 / 255, 217 / 255, 61 / 255, 0.1)
        elseif data.isClaimed then
            frame:SetBackdropColor(107 / 255, 203 / 255, 119 / 255, 0.1)
        else -- isPending
            frame:SetBackdropColor(77 / 255, 150 / 255, 255 / 255, 0.1)
        end

        if data.duration then
            frame.progress:SetTimerDuration(data.duration)
        else
            frame.progress:SetMinMaxValues(0, 1)
            frame.progress:SetValue(0)
        end

        frame.itemIcon:UpdateItemIcon()
        frame.itemName:SetText(data.recipeInfo.name)
        frame.orderType:SetText(orderTypeTextMap[order.orderType] or order.orderType)
        frame.orderNote:SetShown(#order.customerNotes > 0)

        if order.orderType == Enum_CraftingOrderType_Npc then
            frame.orderType:SetTextColor(1, 1, 1)
        else
            frame.orderType:SetTextColor(255 / 255, 217 / 255, 61 / 255)
        end

        if order.minQuality and order.minQuality > 0 then
            local info = C_TradeSkillUI_GetRecipeItemQualityInfo(order.spellID, order.minQuality)
            if info then
                frame.minQuality:SetAtlas(info.icon)
            else
                ---@diagnostic disable-next-line: param-type-mismatch
                frame.minQuality:SetAtlas(nil)
            end
        else
            ---@diagnostic disable-next-line: param-type-mismatch
            frame.minQuality:SetAtlas(nil)
        end

        if data.operationInfo then
            local info = C_TradeSkillUI_GetRecipeItemQualityInfo(order.spellID, data.operationInfo.craftingQuality)
            if info then
                frame.craftQuality:SetAtlas(info.icon)
            else
                ---@diagnostic disable-next-line: param-type-mismatch
                frame.craftQuality:SetAtlas(nil)
            end
        else
            ---@diagnostic disable-next-line: param-type-mismatch
            frame.craftQuality:SetAtlas(nil)
        end

        local remainingTime = order.expirationTime - C_CraftingOrders_GetCraftingOrderTime()
        local remainingMinute = math_floor(remainingTime / 60)
        local nextResetMinute = math_floor(GetQuestResetTime() / 60)

        if remainingMinute < nextResetMinute then
            frame.remainingTime:SetTextColor(255 / 255, 107 / 255, 107 / 255)
        elseif remainingMinute == nextResetMinute then
            frame.remainingTime:SetTextColor(255 / 255, 217 / 255, 61 / 255)
        else
            frame.remainingTime:SetTextColor(1, 1, 1)
        end

        frame.remainingTime:SetText(GetTimeText(remainingTime))

        local rewardIndex = 1
        for _, reward in ipairs(order.npcOrderRewards) do
            local rewardFrame = frame.rewards[rewardIndex]
            rewardFrame:SetReward(reward)
            rewardIndex = rewardIndex + 1
        end
        frame.rewards[rewardIndex]:SetRewardFirstCraft(data.recipeInfo.firstCraft)
        for i = rewardIndex + 1, #frame.rewards do
            frame.rewards[i]:SetReward(nil)
        end

        frame.rewardText:SetText(GetMoneyText(data.rewardPrice))

        local reagentIndex = 1
        for _, reagentInfo in ipairs(data.missingNormalReagentInfos) do
            local reagentFrame = frame.reagents[reagentIndex]
            reagentFrame:SetReagent(reagentInfo)
            reagentIndex = reagentIndex + 1
        end
        for _, reagentInfo in ipairs(data.missingModifiedReagentInfos) do
            local reagentFrame = frame.reagents[reagentIndex]
            reagentFrame:SetReagent(reagentInfo)
            reagentIndex = reagentIndex + 1
        end
        frame.reagents[reagentIndex]:SetConcentration(data.applyConcentration and data.operationInfo.concentrationCost)
        for i = reagentIndex + 1, #frame.reagents do
            frame.reagents[i]:SetReagent(nil)
        end

        frame.costText:SetText(GetMoneyText(-data.costPrice))

        frame.profitText:SetText(GetMoneyText(data.rewardPrice - data.costPrice))
    end
end

do
    ---@param self ProfessionOrderWindowOrderLine
    local function LineOnEnter(self)
        self.highlight:Show()

        local failReason = self.data.failReason
        local customerNotes = self.data.order.customerNotes
        if not failReason and #customerNotes <= 0 then return end

        _G.GameTooltip:Hide()
        _G.GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        _G.GameTooltip:ClearLines()

        _G.GameTooltip:AddLine("订单情况")

        if #customerNotes > 0 then
            _G.GameTooltip:AddLine(PROFESSIONS_CRAFTING_FORM_NOTE_TO_CRAFTER, 0.5, 1, 0.5)
            _G.GameTooltip:AddLine(customerNotes, 1, 1, 1)
        end

        if failReason then
            _G.GameTooltip:AddLine('无法制作订单', 1, 0.5, 0.5)
            _G.GameTooltip:AddLine(failReason, 1, 1, 1)
        end

        _G.GameTooltip:Show()
    end

    ---@param self ProfessionOrderWindowOrderLine
    local function LineOnLeave(self)
        self.highlight:Hide()

        _G.GameTooltip:Hide()
    end

    ---@param self ProfessionOrderWindowOrderLine
    local function LineOnClick(self)
        if self.data.failReason then return end

        self.data.isPending = not self.data.isPending

        RPO.dataProvider:TriggerEvent('OnValueChanged', self.data)
    end

    ---@param self ProfessionOrderWindowOrderLine
    ---@param elapsed number
    local function LineOnUpdate(self, elapsed)
        self.timeElapsed = self.timeElapsed + elapsed
        if self.timeElapsed < 1 then return end

        local remainingTime = math_max(self.data.order.expirationTime - C_CraftingOrders_GetCraftingOrderTime(), 60)
        self.remainingTime:SetText(GetTimeText(remainingTime))
    end

    ---@param self ProfessionOrderWindowOrderLineItemIcon
    local function UpdateItemIcon(self)
        ---@type ProfessionOrderWindowOrderLine
        local parent = self:GetParent()
        local data = parent.data

        local itemID = data.schematic.outputItemID
        local itemIcon = data.recipeInfo.icon

        if itemID then
            local rarity = C_Item_GetItemQualityByID(itemID)
            local r, g, b = C_Item_GetItemQualityColor((rarity and rarity > 1 and rarity) or 1)
            self:SetBackdropBorderColor(r, g, b)
        else
            self:SetBackdropBorderColor(0, 0, 0)
        end

        self.icon:SetTexture(itemIcon)
    end

    ---@param self ProfessionOrderWindowOrderLineItemIcon
    local function ItemIconOnEnter(self)
        ---@type ProfessionOrderWindowOrderLine
        local parent = self:GetParent()
        local data = parent.data

        local craftingReagents = RP:MergeReagentInfos(data.providedModifiedReagentInfos, data.missingModifiedReagentInfos)

        _G.GameTooltip:Hide()
        _G.GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        _G.GameTooltip:ClearLines()

        ---@diagnostic disable-next-line: redundant-parameter
        _G.GameTooltip:SetRecipeResultItem(data.order.spellID, craftingReagents, nil, nil, data.operationInfo and data.operationInfo.craftingQualityID or nil)

        _G.GameTooltip:Show()
    end

    ---@param self ProfessionOrderWindowOrderLineItemIcon
    local function ItemIconOnLeave(self)
        _G.GameTooltip:Hide()
    end

    ---@param self ProfessionOrderWindowOrderLineItemIcon
    local function ItemIconOnClick(self)
        ---@type ProfessionOrderWindowOrderLine
        local parent = self:GetParent()
        local data = parent.data

        local craftingReagents = RP:MergeReagentInfos(data.providedModifiedReagentInfos, data.missingModifiedReagentInfos)
        local outputItemInfo = C_TradeSkillUI_GetRecipeOutputItemData(data.order.spellID, craftingReagents, nil, data.operationInfo and data.operationInfo.craftingQualityID or nil)

        HandleModifiedItemClick(outputItemInfo.hyperlink)
    end

    ---@param self ProfessionOrderWindowOrderLineReward
    ---@param rewardInfo CraftingOrderRewardInfo?
    local function SetReward(self, rewardInfo)
        self.reward = rewardInfo
        self.isFirstCraft = nil
        self.firstCraft:Hide()

        if rewardInfo then
            if rewardInfo.itemLink then
                self.count:SetText(rewardInfo.count > 1 and rewardInfo.count or '')

                local itemLink = rewardInfo.itemLink

                local rarity = C_Item_GetItemQualityByID(itemLink)
                local itemIcon = C_Item_GetItemIconByID(itemLink)
                local info = C_TradeSkillUI_GetItemReagentQualityInfo(itemLink)
                if rarity and itemIcon then
                    local r, g, b = C_Item_GetItemQualityColor((rarity and rarity > 1 and rarity) or 1)

                    self:SetBackdropBorderColor(r, g, b)
                    self.icon:SetTexture(itemIcon)
                    if info then
                        self.qualityOverlay:SetAtlas(info.iconInventory, true)
                    else
                        ---@diagnostic disable-next-line: param-type-mismatch
                        self.qualityOverlay:SetAtlas(nil)
                    end
                else
                    local item = Item:CreateFromItemLink(itemLink)
                    item:ContinueOnItemLoad(function()
                        rarity = item:GetItemQuality()

                        local r, g, b = C_Item_GetItemQualityColor((rarity and rarity > 1 and rarity) or 1)

                        self:SetBackdropBorderColor(r, g, b)
                        self.icon:SetTexture(item:GetItemIcon())
                        if info then
                            self.qualityOverlay:SetAtlas(info.iconInventory, true)
                        else
                            ---@diagnostic disable-next-line: param-type-mismatch
                            self.qualityOverlay:SetAtlas(nil)
                        end
                    end)
                end

                self:Show()
            elseif rewardInfo.currencyType then
                local currencyInfo = C_CurrencyInfo_GetCurrencyInfo(rewardInfo.currencyType)
                local r, g, b = C_Item_GetItemQualityColor(currencyInfo.quality)

                self:SetBackdropBorderColor(r, g, b)
                self.icon:SetTexture(currencyInfo.iconFileID)
                self.count:SetText(rewardInfo.count > 1 and rewardInfo.count or '')
                ---@diagnostic disable-next-line: param-type-mismatch
                self.qualityOverlay:SetAtlas(nil)

                self:Show()
            else
                self:Hide()
            end
        else
            self:Hide()
        end
    end

    ---@param self ProfessionOrderWindowOrderLineReward
    ---@param isFirstCraft boolean
    local function SetRewardFirstCraft(self, isFirstCraft)
        self.reward = nil
        self.isFirstCraft = isFirstCraft
        self.firstCraft:Show()

        self:SetBackdropBorderColor(0, 0, 0)
        self.icon:SetTexture(nil)
        self.count:SetText(nil)
        ---@diagnostic disable-next-line: param-type-mismatch
        self.qualityOverlay:SetAtlas(nil)

        self:SetShown(isFirstCraft)
    end

    ---@param self ProfessionOrderWindowOrderLineReward
    local function RewardOnEnter(self)
        if not self.reward then return end

        _G.GameTooltip:Hide()
        _G.GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        _G.GameTooltip:ClearLines()

        if self.reward.itemLink then
            _G.GameTooltip:SetHyperlink(self.reward.itemLink)
        elseif self.reward.currencyType then
            local link = C_CurrencyInfo_GetCurrencyLink(self.reward.currencyType, self.reward.count)

            _G.GameTooltip:SetHyperlink(link)
        end

        _G.GameTooltip:Show()
    end

    ---@param self ProfessionOrderWindowOrderLineReward
    local function RewardOnLeave(self)
        _G.GameTooltip:Hide()
    end

    ---@param self ProfessionOrderWindowOrderLineReagent
    ---@param reagentInfo CraftingReagentInfo?
    local function SetReagent(self, reagentInfo)
        self.reagentInfo = reagentInfo

        if reagentInfo then
            if reagentInfo.reagent.itemID then
                self.count:SetText(reagentInfo.quantity > 1 and reagentInfo.quantity or '')

                local itemID = reagentInfo.reagent.itemID

                local rarity = C_Item_GetItemQualityByID(itemID)
                local itemIcon = C_Item_GetItemIconByID(itemID)
                local info = C_TradeSkillUI_GetItemReagentQualityInfo(itemID)
                if rarity and itemIcon then
                    local r, g, b = C_Item_GetItemQualityColor((rarity and rarity > 1 and rarity) or 1)

                    self:SetBackdropBorderColor(r, g, b)
                    self.icon:SetTexture(itemIcon)
                    if info then
                        self.qualityOverlay:SetAtlas(info.iconInventory, true)
                    else
                        ---@diagnostic disable-next-line: param-type-mismatch
                        self.qualityOverlay:SetAtlas(nil)
                    end
                else
                    local item = Item:CreateFromItemID(itemID)
                    item:ContinueOnItemLoad(function()
                        rarity = item:GetItemQuality()

                        local r, g, b = C_Item_GetItemQualityColor((rarity and rarity > 1 and rarity) or 1)

                        self:SetBackdropBorderColor(r, g, b)
                        self.icon:SetTexture(item:GetItemIcon())
                        if info then
                            self.qualityOverlay:SetAtlas(info.iconInventory, true)
                        else
                            ---@diagnostic disable-next-line: param-type-mismatch
                            self.qualityOverlay:SetAtlas(nil)
                        end
                    end)
                end

                self:Show()
            elseif reagentInfo.reagent.currencyID then
                local currencyInfo = C_CurrencyInfo_GetCurrencyInfo(reagentInfo.reagent.currencyID)
                local r, g, b = C_Item_GetItemQualityColor(currencyInfo.quality)

                self:SetBackdropBorderColor(r, g, b)
                self.icon:SetTexture(currencyInfo.iconFileID)
                self.count:SetText(reagentInfo.quantity > 1 and reagentInfo.quantity or '')
                ---@diagnostic disable-next-line: param-type-mismatch
                self.qualityOverlay:SetAtlas(nil)

                self:Show()
            else
                self:Hide()
            end
        else
            self:Hide()
        end
    end

    ---@param self ProfessionOrderWindowOrderLineReagent
    ---@param concentration number?
    local function SetConcentration(self, concentration)
        self.reagentInfo = nil

        if concentration and concentration > 0 then
            self:SetBackdropBorderColor(0, 0, 0)
            self.icon:SetTexture(5747318) -- Interface\ICONS\UI_Concentration
            self.count:SetText(tostring(concentration))
            ---@diagnostic disable-next-line: param-type-mismatch
            self.qualityOverlay:SetAtlas(nil)
            self:Show()
        else
            self:Hide()
        end
    end

    ---@param self ProfessionOrderWindowOrderLineReagent
    local function ReagentOnEnter(self)
        if not self.reagentInfo then return end

        _G.GameTooltip:Hide()
        _G.GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        _G.GameTooltip:ClearLines()

        if self.reagentInfo.reagent.itemID then
            _G.GameTooltip:SetItemByID(self.reagentInfo.reagent.itemID)
        elseif self.reagentInfo.reagent.currencyID then
            local link = C_CurrencyInfo_GetCurrencyLink(self.reagentInfo.reagent.currencyID, self.reagentInfo.quantity)

            _G.GameTooltip:SetHyperlink(link)
        end

        _G.GameTooltip:Show()
    end

    ---@param self ProfessionOrderWindowOrderLineReagent
    local function ReagentOnLeave(self)
        _G.GameTooltip:Hide()
    end

    ---@param self ProfessionOrderWindowOrderLineReagent
    ---@param button string
    local function ReagentOnClick(self, button)
        ---@type ProfessionOrderWindowOrderLine
        local parent = self:GetParent()
        local data = parent.data

        local index = self.index
        local normalReagentCount = #data.missingNormalReagentInfos

        -- within normal reagents
        if index <= normalReagentCount then return end

        local modifiedIndex = index - normalReagentCount
        local replace = data.missingModifiedReagentInfosReplaces[modifiedIndex]
        if not replace then return end

        local currentReagentIndex = tIndexOf(replace, self.reagentInfo)
        if not currentReagentIndex then return end

        local nextIndex = (currentReagentIndex + 1) % #replace
        if nextIndex == 0 then
            nextIndex = #replace
        end

        if button == 'RightButton' then
            for i, replaceData in ipairs(data.missingModifiedReagentInfosReplaces) do
                data.missingModifiedReagentInfos[i] = replaceData[nextIndex] or replaceData[1]
            end
        else
            data.missingModifiedReagentInfos[modifiedIndex] = replace[nextIndex]
        end

        local costPrice = RP:GetReagentsCostPrice(data.missingNormalReagentInfos, data.missingModifiedReagentInfos)
        local operationInfo, applyConcentration = RP:GetOperationInfo(data.order, data.providedModifiedReagentInfos, data.missingModifiedReagentInfos)
        local failReason = RP:GetOrderFailReason(data.order, data.recipeInfo, data.schematic, RPO.window.professionInfo, data.reagentSlotProvidedByCustomer, operationInfo, applyConcentration)
        local isReagentReady = RP:IsReagentReady(data.missingNormalReagentInfos, data.missingModifiedReagentInfos)

        data.costPrice = costPrice
        data.operationInfo = operationInfo
        data.applyConcentration = applyConcentration
        data.failReason = failReason
        data.isReagentReady = isReagentReady

        RPO.dataProvider:TriggerEvent('OnValueChanged', data)
    end

    ---@param frame ProfessionOrderWindowOrderLine
    function RPO:BuildOrderLine(frame)
        frame.timeElapsed = 0

        frame:SetSize(780, 67)
        frame:SetTemplate('Default')

        frame:SetScript('OnEnter', LineOnEnter)
        frame:SetScript('OnLeave', LineOnLeave)
        frame:SetScript('OnClick', LineOnClick)
        frame:SetScript('OnUpdate', LineOnUpdate)

        local highlight = frame:CreateTexture(nil, 'OVERLAY')
        highlight:ClearAllPoints()
        highlight:SetAllPoints()
        highlight:SetTexture(E.Media.Textures.White8x8)
        highlight:SetVertexColor(1, 1, 1, 0.03)
        highlight:Hide()
        frame.highlight = highlight

        local progress = CreateFrame('StatusBar', nil, frame)
        progress:ClearAllPoints()
        progress:SetAllPoints()
        progress:SetStatusBarTexture(E.Media.Textures.White8x8)
        progress:SetStatusBarColor(0, 1, 22 / 255, 0.1)
        progress:SetPropagateMouseClicks(false)
        progress:SetPropagateMouseMotion(false)
        progress:SetMinMaxValues(0, 1)
        progress:SetValue(0)
        frame.progress = progress

        ---@class ProfessionOrderWindowOrderLineItemIcon: Button
        local itemIcon = CreateFrame('Button', nil, frame, 'BackdropTemplate')
        itemIcon:SetSize(65, 65)
        itemIcon:SetPoint('LEFT', frame, 'LEFT', 1, 0)
        itemIcon:SetTemplate('Default')
        frame.itemIcon = itemIcon

        itemIcon:SetScript('OnEnter', ItemIconOnEnter)
        itemIcon:SetScript('OnLeave', ItemIconOnLeave)
        itemIcon:SetScript('OnClick', ItemIconOnClick)

        itemIcon.icon = itemIcon:CreateTexture(nil, 'ARTWORK')
        itemIcon.icon:SetInside(itemIcon, 2, 2)
        itemIcon.icon:SetTexCoord(.1, .9, .1, .9)

        itemIcon.UpdateItemIcon = UpdateItemIcon

        frame.minQuality = frame:CreateTexture(nil, 'ARTWORK')
        frame.minQuality:SetSize(32, 32)
        frame.minQuality:SetPoint('CENTER', frame.itemIcon, 'TOPRIGHT', 1 + 16, -16)

        frame.itemName = frame:CreateFontString(nil, 'ARTWORK')
        frame.itemName:SetSize(300, 32)
        frame.itemName:SetPoint('TOPLEFT', frame.itemIcon, 'TOPRIGHT', 1 + 32 + 1, 0)
        frame.itemName:FontTemplate(nil, 18, 'OUTLINE')
        frame.itemName:SetTextColor(1, 1, 1)
        frame.itemName:SetJustifyH('LEFT')

        frame.orderType = frame:CreateFontString(nil, 'ARTWORK')
        frame.orderType:SetSize(50, 32)
        frame.orderType:SetPoint('LEFT', frame.itemName, 'RIGHT', 1, 0)
        frame.orderType:FontTemplate(nil, 18, 'OUTLINE')
        frame.orderType:SetTextColor(1, 1, 1)
        frame.orderType:SetJustifyH('LEFT')

        frame.remainingTime = frame:CreateFontString(nil, 'ARTWORK')
        frame.remainingTime:SetSize(100, 32)
        frame.remainingTime:SetPoint('LEFT', frame.orderType, 'RIGHT', 1, 0)
        frame.remainingTime:FontTemplate(nil, 18, 'OUTLINE')
        frame.remainingTime:SetTextColor(1, 1, 1)
        frame.remainingTime:SetJustifyH('LEFT')

        frame.orderNote = frame:CreateTexture(nil, 'ARTWORK')
        frame.orderNote:SetSize(16, 16)
        frame.orderNote:SetPoint('CENTER', frame.remainingTime, 'TOPRIGHT', 1 + 8, -16)
        frame.orderNote:SetTexture(E.Media.Textures.Copy)

        frame.craftQuality = frame:CreateTexture(nil, 'ARTWORK')
        frame.craftQuality:SetSize(32, 32)
        frame.craftQuality:SetPoint('CENTER', frame.itemIcon, 'BOTTOMRIGHT', 1 + 16, 16)

        frame.profitText = frame:CreateFontString(nil, 'ARTWORK')
        frame.profitText:SetSize(120, 32)
        frame.profitText:SetPoint('BOTTOMLEFT', frame.itemIcon, 'BOTTOMRIGHT', 1 + 32 + 1, 0)
        frame.profitText:FontTemplate(nil, 14, 'OUTLINE')
        frame.profitText:SetTextColor(1, 1, 1)
        frame.profitText:SetJustifyH('LEFT')
        frame.profitText:SetJustifyV('MIDDLE')

        frame.rewardText = frame:CreateFontString(nil, 'ARTWORK')
        frame.rewardText:SetSize(120, 32)
        frame.rewardText:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -1, -1)
        frame.rewardText:FontTemplate(nil, 14, 'OUTLINE')
        frame.rewardText:SetTextColor(1, 1, 1)
        frame.rewardText:SetJustifyH('RIGHT')
        frame.rewardText:SetJustifyV('MIDDLE')

        frame.rewards = {}
        for i = 1, 4 do
            ---@class ProfessionOrderWindowOrderLineReward: Button
            local reward = CreateFrame('Button', nil, frame, 'BackdropTemplate')
            reward:SetSize(32, 32)
            reward:SetPoint('RIGHT', frame.rewardText, 'LEFT', -(i - 1) * 33 - 1, 0)
            reward:SetTemplate('Default')
            frame.rewards[i] = reward

            reward:SetScript('OnEnter', RewardOnEnter)
            reward:SetScript('OnLeave', RewardOnLeave)

            reward.icon = reward:CreateTexture(nil, 'ARTWORK')
            reward.icon:SetInside(reward, 2, 2)
            reward.icon:SetTexCoord(.1, .9, .1, .9)

            reward.count = reward:CreateFontString(nil, 'OVERLAY')
            reward.count:SetPoint('BOTTOMRIGHT', reward, 'BOTTOMRIGHT', .5, 0)
            reward.count:FontTemplate(nil, 14, 'OUTLINE')
            reward.count:SetTextColor(1, 1, 1)

            reward.qualityOverlay = reward:CreateTexture(nil, 'OVERLAY')
            reward.qualityOverlay:SetPoint('TOPLEFT', reward, 'TOPLEFT', -3, 2)

            reward.SetReward = SetReward

            ---@type CraftingOrderRewardInfo?
            reward.reward = nil

            reward.firstCraft = reward:CreateTexture(nil, 'ARTWORK')
            reward.firstCraft:SetSize(32, 32)
            reward.firstCraft:SetPoint('CENTER')
            reward.firstCraft:SetAtlas('Professions_Icon_FirstTimeCraft', true)

            reward.SetRewardFirstCraft = SetRewardFirstCraft

            ---@type boolean?
            reward.isFirstCraft = nil

            table_insert(frame.rewards, reward)
        end

        frame.costText = frame:CreateFontString(nil, 'ARTWORK')
        frame.costText:SetSize(120, 32)
        frame.costText:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -1, 1)
        frame.costText:FontTemplate(nil, 14, 'OUTLINE')
        frame.costText:SetTextColor(1, 1, 1)
        frame.costText:SetJustifyH('RIGHT')
        frame.costText:SetJustifyV('MIDDLE')

        frame.reagents = {}
        for i = 1, 8 do
            ---@class ProfessionOrderWindowOrderLineReagent: Button
            local reagent = CreateFrame('Button', nil, frame, 'BackdropTemplate')
            reagent:SetSize(32, 32)
            reagent:SetPoint('RIGHT', frame.costText, 'LEFT', -(i - 1) * 33 - 1, 0)
            reagent:SetTemplate('Default')
            reagent:RegisterForClicks('AnyUp')

            reagent:SetScript('OnEnter', ReagentOnEnter)
            reagent:SetScript('OnLeave', ReagentOnLeave)
            reagent:SetScript('OnClick', ReagentOnClick)

            reagent.icon = reagent:CreateTexture(nil, 'ARTWORK')
            reagent.icon:SetInside(reagent, 2, 2)
            reagent.icon:SetTexCoord(.1, .9, .1, .9)

            reagent.count = reagent:CreateFontString(nil, 'OVERLAY')
            reagent.count:SetPoint('BOTTOMRIGHT', reagent, 'BOTTOMRIGHT', .5, 0)
            reagent.count:FontTemplate(nil, 14, 'OUTLINE')
            reagent.count:SetTextColor(1, 1, 1)

            reagent.qualityOverlay = reagent:CreateTexture(nil, 'OVERLAY')
            reagent.qualityOverlay:SetPoint('TOPLEFT', reagent, 'TOPLEFT', -3, 2)

            reagent.SetReagent = SetReagent
            reagent.SetConcentration = SetConcentration

            ---@type CraftingReagentInfo?
            reagent.reagentInfo = nil
            reagent.index = i

            table_insert(frame.reagents, reagent)
        end

        return frame
    end
end

do
    local isLocked = false

    function RPO:LockOrderWindowButton()
        isLocked = true

        self:UpdateOrderWindow()
    end

    function RPO:UnlockOrderWindowButton()
        isLocked = false

        self:UpdateOrderWindow()
    end

    function RPO:UpdateOrderWindow()
        local window = self.window
        if not window:IsShown() then return end

        local _, skillLineID = self:GetNearProfessionInfo()

        local isReady = C_TradeSkillUI_IsTradeSkillReady()
        local info = C_TradeSkillUI_GetChildProfessionInfo()
        local isCorrectChildProfession = isReady and info.professionID == window.professionInfo.professionID

        if isCorrectChildProfession then
            window.professionInfo = info
        end

        ---@type ProfessionInfo
        local windowProfessionInfo = window.professionInfo
        local isListEmpty = self.dataProvider:IsEmpty()
        local missingPending = true
        local concentrationCost = 0
        for _, data in self.dataProvider:Enumerate() do
            ---@cast data ProfessionOrderData

            if not data.failReason and data.isPending then
                missingPending = false

                if data.applyConcentration and data.operationInfo then
                    concentrationCost = concentrationCost + data.operationInfo.concentrationCost
                end
            end
        end

        local knowledgeCurrencyInfo = C_ProfSpecs_GetCurrencyInfoForSkillLine(windowProfessionInfo.professionID)
        local currencyType = C_TradeSkillUI_GetConcentrationCurrencyID(windowProfessionInfo.professionID)
        local currencyInfo = C_CurrencyInfo_GetCurrencyInfo(currencyType)
        local concentrationRemaining = currencyInfo.quantity - concentrationCost
        local concentrationRemainingDisplay = math_max(concentrationRemaining, 0)
        local concentrationCostDisplay = math_min(concentrationCost, currencyInfo.quantity)

        window.professionSkillBar:SetMinMaxValues(0, windowProfessionInfo.maxSkillLevel + windowProfessionInfo.skillModifier)
        window.professionSkillBar:SetValue(windowProfessionInfo.skillLevel)
        window.professionSkillBar:SetOverlayValue(windowProfessionInfo.skillModifier)
        window.professionSkillBar.leftText:SetText(string_format('%d / %d', windowProfessionInfo.skillLevel, windowProfessionInfo.maxSkillLevel))
        window.professionSkillBar.rightText:SetText(string_format('+%d', windowProfessionInfo.skillModifier))

        window.professionKnowledgeBar:SetOverlayValue(knowledgeCurrencyInfo.numAvailable)
        window.professionKnowledgeBar.rightText:SetText(string_format('+%d', knowledgeCurrencyInfo.numAvailable))

        window.professionConcentrationBar:SetMinMaxValues(0, currencyInfo.maxQuantity)
        window.professionConcentrationBar:SetValue(concentrationRemainingDisplay)
        window.professionConcentrationBar:SetOverlayValue(concentrationCostDisplay)
        window.professionConcentrationBar.leftText:SetText(string_format('%d / %d', currencyInfo.quantity, currencyInfo.maxQuantity))
        window.professionConcentrationBar.rightText:SetText(concentrationCost > 0 and string_format('-%d', concentrationCost) or '')

        if concentrationRemaining >= 0 then
            window.isConcentrationEnough = true
            window.professionConcentrationBar.rightText:SetTextColor(1, 1, 1)
        else
            window.isConcentrationEnough = false
            window.professionConcentrationBar.rightText:SetTextColor(255 / 255, 107 / 255, 107 / 255)
        end

        if not skillLineID then
            -- not near table, should open profession first
            window.processButton:SetText('开启专业')
            window.processButton:SetScript('OnClick', buttonOnClickOpenOrder)
            window.processButton:SetEnabled(false)

            return
        end

        -- near table
        if not isReady then
            -- not opened profession yet, should open profession first
            window.processButton:SetText('开启专业')
            window.processButton:SetScript('OnClick', buttonOnClickOpenOrder)
            window.processButton:SetEnabled(true)

            return
        end

        if (
            skillLineID ~= windowProfessionInfo.parentProfessionID or -- different base profession
            info.professionID ~= windowProfessionInfo.professionID -- different child profession
        ) then
            -- profession opened with wrong profession, should reopen profession
            window.processButton:SetText('更改专业')
            window.processButton:SetScript('OnClick', buttonOnClickOpenOrder)
            window.processButton:SetEnabled(true)

            return
        end

        -- window is opened with correct child profession
        if isListEmpty or missingPending then
            -- no orders or no pending orders
            window.processButton:SetText('获取订单')
            window.processButton:SetScript('OnClick', buttonOnClickGetCraftingOrders)
            window.processButton:SetEnabled(true)

            return
        end

        window.processButton:SetText('处理订单')
        window.processButton:SetScript('OnClick', buttonOnClickHandleCraftingOrders)
        window.processButton:SetEnabled(not isLocked)
    end
end

function RPO:OpenOrderWindow()
    local window = self.window

    local info = C_TradeSkillUI_GetChildProfessionInfo()

    local infos = C_TradeSkillUI_GetChildProfessionInfos()
    if info.professionID ~= infos[1].professionID then
        -- not latest child profession, switch to latest one
        C_TradeSkillUI_SetProfessionChildSkillLineID(infos[1].professionID)
        info = C_TradeSkillUI_GetChildProfessionInfo()
    end

    local professionIcon
    local professionIndex1, professionIndex2 = GetProfessions()
    if professionIndex1 then
        local _, icon, _, _, _, _, skillLineID = GetProfessionInfo(professionIndex1)
        if skillLineID == info.parentProfessionID then
            professionIcon = icon
        end
    end
    if professionIndex2 then
        local _, icon, _, _, _, _, skillLineID = GetProfessionInfo(professionIndex2)
        if skillLineID == info.parentProfessionID then
            professionIcon = icon
        end
    end

    local currentKnowledge, maxKnowledge, currentPerks, maxPerks = RP:GetProfessionKnowledgeInfo(info.professionID)

    self.dataProvider:Flush()

    window.professionInfo = info

    window.professionIcon:SetTexture(professionIcon)
    window.professionName:SetText(info.expansionName .. ' ' .. info.parentProfessionName)

    window.professionKnowledgeBar:SetMinMaxValues(0, maxKnowledge)
    window.professionKnowledgeBar:SetValue(currentKnowledge)
    window.professionKnowledgeBar.leftText:SetText(string_format('%d / %d (%d / %d)', currentKnowledge, maxKnowledge, currentPerks, maxPerks))

    window.loadingSpinner:Hide()

    window.orderResultText:SetText('等待获取订单')

    self:UpdateOrderWindow()

    self.quickWindow:Hide()
    window:Show()
end

do
    ---@param self ProfessionOrderWindowProcessButton
    local function OnDisable(self)
        self.overlay:SetVertexColor(255 / 255, 107 / 255, 107 / 255, 0.1)
    end

    ---@param self ProfessionOrderWindowProcessButton
    local function OnEnable(self)
        self.overlay:SetVertexColor(77 / 255, 150 / 255, 255 / 255, 0.1)
    end

    ---@param self ProfessionOrderWindowProcessButton
    local function OnEnter(self)
        self.highlight:Show()
    end

    ---@param self ProfessionOrderWindowProcessButton
    local function OnLeave(self)
        self.highlight:Hide()
    end

    ---@param self ProfessionOrderWindowProcessButton
    ---@param text string
    local function SetText(self, text)
        self.text:SetText(text)
    end

    function RPO:BuildProcessButton()
        ---@class ProfessionOrderWindowProcessButton: Button
        local button = CreateFrame('Button', nil, self.window)
        button:SetSize(780, 32)
        button:SetTemplate('Default')

        button:SetScript('OnDisable', OnDisable)
        button:SetScript('OnEnable', OnEnable)
        button:SetScript('OnEnter', OnEnter)
        button:SetScript('OnLeave', OnLeave)

        button.overlay = button:CreateTexture(nil, 'ARTWORK')
        button.overlay:ClearAllPoints()
        button.overlay:SetAllPoints()
        button.overlay:SetTexture(E.Media.Textures.White8x8)
        button.overlay:SetVertexColor(77 / 255, 150 / 255, 255 / 255, 0.1)

        button.highlight = button:CreateTexture(nil, 'OVERLAY')
        button.highlight:ClearAllPoints()
        button.highlight:SetAllPoints()
        button.highlight:SetTexture(E.Media.Textures.White8x8)
        button.highlight:SetVertexColor(1, 1, 1, 0.03)
        button.highlight:Hide()

        button.text = button:CreateFontString(nil, 'ARTWORK')
        button.text:SetPoint('CENTER')
        button.text:FontTemplate(nil, 24)
        button.text:SetTextColor(1, 1, 1)

        button.SetText = SetText

        return button
    end
end

do
    ---@param self ProfessionOrderWindowStatusBar
    ---@param value number
    local function SetOverlayValue(self, value)
        if value > 0 then
            local barWidth = self:GetWidth()
            local barValue = self:GetValue()
            local minValue, maxValue = self:GetMinMaxValues()

            local overlayValue = math_min(value, math_max(0, maxValue - barValue))
            local overlayWidth = overlayValue / (maxValue - minValue) * barWidth

            if overlayWidth > 0 then
                self.overlay:ClearAllPoints()
                self.overlay:SetPoint('LEFT', self.statusBar, 'RIGHT', 0, 0)
                self.overlay:SetWidth(overlayWidth)
                self.overlay:Show()
            else
                self.overlay:Hide()
            end
        else
            self.overlay:Hide()
        end
    end

    function RPO:BuildStatusBar()
        ---@class ProfessionOrderWindowStatusBar: StatusBar
        local bar = CreateFrame('StatusBar', nil, self.window)
        bar:SetSize(780, 24)
        bar:SetStatusBarTexture(LSM:Fetch('statusbar', 'Melli'))
        bar:CreateBackdrop()

        bar.statusBar = bar:GetStatusBarTexture()
        bar.statusBar:SetHorizTile(false)
        bar.statusBar:SetVertTile(false)

        bar.overlay = bar:CreateTexture(nil, 'OVERLAY')
        bar.overlay:SetTexture(LSM:Fetch('statusbar', 'Melli'))
        bar.overlay:SetHeight(24)
        bar.overlay:Hide()

        bar.SetOverlayValue = SetOverlayValue

        bar.leftText = bar:CreateFontString(nil, 'OVERLAY')
        bar.leftText:SetPoint('LEFT', bar, 'LEFT', 0, 0)
        bar.leftText:FontTemplate(nil, 14, 'OUTLINE')
        bar.leftText:SetTextColor(1, 1, 1)
        bar.leftText:SetJustifyH('LEFT')

        bar.rightText = bar:CreateFontString(nil, 'OVERLAY')
        bar.rightText:SetPoint('RIGHT', bar, 'RIGHT', 0, 0)
        bar.rightText:FontTemplate(nil, 14, 'OUTLINE')
        bar.rightText:SetTextColor(1, 1, 1)
        bar.rightText:SetJustifyH('RIGHT')

        return bar
    end
end

function RPO:BuildOrderWindow()
    ---@class ProfessionOrderWindow: Frame
    local window = CreateFrame('Frame', 'RhythmBoxProfessionOrderWindow', E.UIParent, 'BackdropTemplate')
    window:SetTemplate('Transparent', true)
    window:SetFrameStrata('DIALOG')
    window:SetPoint('TOP', E.UIParent, 'CENTER', 0, 400)
    window:SetSize(800, 800)
    window:Hide()
    self.window = window

    window:SetScript('OnHide', function()
        self:OnOrderWindowClose()

        C_TradeSkillUI_CloseTradeSkill()
    end)

    ---@type ProfessionInfo?
    window.professionInfo = nil
    ---@type boolean
    window.isConcentrationEnough = true

    local closeButton = CreateFrame('Button', nil, window)
    closeButton:SetSize(32, 32)
    closeButton:SetPoint('TOPRIGHT', 1, 1)
    closeButton:SetScript('OnClick', function()
        window:Hide()
    end)
    S:HandleCloseButton(closeButton)

    local expandButton = CreateFrame('Button', nil, window)
    expandButton:SetSize(32, 32)
    expandButton:SetPoint('TOPRIGHT', -32, -7)
    expandButton:Hide()
    S:HandleNextPrevButton(expandButton, 'down')

    local shrinkButton = CreateFrame('Button', nil, window)
    shrinkButton:SetSize(32, 32)
    shrinkButton:SetPoint('TOPRIGHT', -32, -7)
    S:HandleNextPrevButton(shrinkButton, 'up')

    expandButton:SetScript('OnClick', function()
        window:SetHeight(800)
        expandButton:Hide()
        shrinkButton:Show()
    end)
    shrinkButton:SetScript('OnClick', function()
        window:SetHeight(300)
        shrinkButton:Hide()
        expandButton:Show()
    end)

    local professionIcon = window:CreateTexture(nil, 'ARTWORK')
    professionIcon:SetSize(32, 32)
    professionIcon:SetPoint('TOPLEFT', 10, -10)
    professionIcon:SetTexCoord(.1, .9, .1, .9)
    window.professionIcon = professionIcon

    local professionName = window:CreateFontString(nil, 'ARTWORK')
    professionName:SetPoint('LEFT', professionIcon, 'RIGHT', 5, 0)
    professionName:FontTemplate(nil, 32)
    window.professionName = professionName

    local professionSkillBar = self:BuildStatusBar()
    professionSkillBar:SetPoint('TOPLEFT', professionIcon, 'BOTTOMLEFT', 0, -5)
    professionSkillBar:SetStatusBarColor(16 / 255, 85 / 255, 201 / 255)
    professionSkillBar.overlay:SetVertexColor(16 / 255, 85 / 255, 201 / 255, 0.63)
    window.professionSkillBar = professionSkillBar

    local professionKnowledgeBar = self:BuildStatusBar()
    professionKnowledgeBar:SetPoint('TOPLEFT', professionSkillBar, 'BOTTOMLEFT', 0, -5)
    professionKnowledgeBar:SetStatusBarColor(65 / 255, 166 / 255, 126 / 255)
    professionKnowledgeBar.overlay:SetVertexColor(65 / 255, 166 / 255, 126 / 255, 0.63)
    window.professionKnowledgeBar = professionKnowledgeBar

    local professionConcentrationBar = self:BuildStatusBar()
    professionConcentrationBar:SetPoint('TOPLEFT', professionKnowledgeBar, 'BOTTOMLEFT', 0, -5)
    professionConcentrationBar:SetStatusBarColor(229 / 255, 201 / 255, 95 / 255)
    professionConcentrationBar.overlay:SetVertexColor(229 / 255, 201 / 255, 95 / 255, 0.63)
    window.professionConcentrationBar = professionConcentrationBar

    local processButton = self:BuildProcessButton()
    processButton:SetPoint('TOP', professionConcentrationBar, 'BOTTOM', 0, -10)
    window.processButton = processButton

    local scrollBox = CreateFrame('Frame', nil, window, 'WowScrollBoxList')
    scrollBox:SetPoint('TOPLEFT', processButton, 'BOTTOMLEFT', 0, -10)
    scrollBox:SetPoint('BOTTOMRIGHT', window, 'BOTTOMRIGHT', -10, 10)
    scrollBox:SetTemplate('Transparent')

    local scrollBar = CreateFrame('EventFrame', nil, window, 'MinimalScrollBar')
    scrollBar:SetPoint('TOPLEFT', scrollBox, 'TOPRIGHT')
    scrollBar:SetPoint('BOTTOMLEFT', scrollBox, 'BOTTOMRIGHT')
    S:HandleScrollBar(scrollBar, nil, nil, 'NoBackdrop')

    local scrollView = CreateScrollBoxListLinearView()
    scrollView:SetElementExtent(67)
    scrollView:SetElementInitializer('Button', function(frame, data)
        if not frame.isCreated then
            self:BuildOrderLine(frame)
            frame.isCreated = true
        end

        self:SetupOrderLine(frame, data)
    end)
    scrollView:SetDataProvider(self.dataProvider)
    window.scrollView = scrollView

    ScrollUtil_InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)

    local loadingSpinner = CreateFrame('Frame', nil, window, 'SpinnerTemplate')
    loadingSpinner:SetSize(80, 80)
    loadingSpinner:SetPoint('CENTER', scrollBox, 'CENTER')
    loadingSpinner:Hide()
    window.loadingSpinner = loadingSpinner

    local orderResultText = scrollBox:CreateFontString(nil, 'ARTWORK')
    orderResultText:SetPoint('TOP', scrollBox, 'TOP', 0, -10)
    orderResultText:FontTemplate(nil, 16, 'OUTLINE')
    orderResultText:SetTextColor(1, 1, 1)
    window.orderResultText = orderResultText
end

function RPO:BuildQuickWindow()
    ---@class ProfessionOrderQuickWindow: Frame
    local window = CreateFrame('Frame', nil, E.UIParent, 'BackdropTemplate')
    window:SetTemplate('Transparent', true)
    window:SetFrameStrata('DIALOG')
    window:SetPoint('TOPLEFT', E.UIParent, 'CENTER', 100, 50)
    window:SetSize(100, 70)
    window:Hide()
    self.quickWindow = window

    local buttonOpenOrder = CreateFrame('Button', nil, window, 'UIPanelButtonTemplate')
    buttonOpenOrder:SetTemplate('Default')
    buttonOpenOrder:StyleButton()
    buttonOpenOrder:ClearAllPoints()
    buttonOpenOrder:SetPoint('TOP', window, 'TOP', 0, -10)
    buttonOpenOrder:SetSize(80, 22)
    buttonOpenOrder:SetText("打开订单")
    buttonOpenOrder:SetScript('OnClick', buttonOnClickOpenOrder)
    S:HandleButton(buttonOpenOrder)

    local buttonOpenProfession = CreateFrame('Button', nil, window, 'UIPanelButtonTemplate')
    buttonOpenProfession:SetTemplate('Default')
    buttonOpenProfession:StyleButton()
    buttonOpenProfession:ClearAllPoints()
    buttonOpenProfession:SetPoint('TOP', window, 'TOP', 0, -40)
    buttonOpenProfession:SetSize(80, 22)
    buttonOpenProfession:SetText("打开专业")
    buttonOpenProfession:SetScript('OnClick', function()
        local _, skillLineID = self:GetNearProfessionInfo()
        if not skillLineID then return end

        C_TradeSkillUI_OpenTradeSkill(skillLineID)
    end)
    S:HandleButton(buttonOpenProfession)
end

function RPO:Initialize()
    self.dataProvider = CreateDataProvider()
    self.dataProvider:GenerateCallbackEvents({ 'OnValueChanged' })

    self:BuildQuickWindow()
    self:BuildOrderWindow()

    ---@param data ProfessionOrderData?
    local function OnValueChanged(_, data)
        if data and data.frame then
            self:SetupOrderLine(data.frame, data)
        end
        self:UpdateOrderWindow()
    end

    local function OnSizeChanged()
        self:UpdateOrderWindow()
    end

    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'CheckZone')
    self:RegisterEvent('PLAYER_UPDATE_RESTING', 'CheckZone')
    self.dataProvider:RegisterCallback(self.dataProvider.Event.OnValueChanged, OnValueChanged, self)
    self.dataProvider:RegisterCallback(self.dataProvider.Event.OnSizeChanged, OnSizeChanged, self)

    self:CheckZone()
end

R:RegisterModule(RPO:GetName())
