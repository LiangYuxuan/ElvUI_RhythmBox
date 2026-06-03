local R, E, L, V, P, G = unpack((select(2, ...)))
---@class RhythmBoxProfessionShoppingModule: AceModule
local RPS = R:NewModule('ProfessionShopping', 'AceEvent-3.0', 'AceTimer-3.0', 'AceHook-3.0')
---@type RhythmBoxProfessionModule
local RP = R:GetModule('Profession')
---@type RhythmBoxProfessionOrderModule
local RPO = R:GetModule('ProfessionOrder')
local S = E:GetModule('Skins')

-- Lua functions
local _G = _G
local ipairs, pairs, tostring = ipairs, pairs, tostring
local math_abs = math.abs
local math_floor = math.floor
local math_max = math.max
local string_format = string.format

-- WoW API / Variables
local BuyMerchantItem = BuyMerchantItem
local C_AuctionHouse_GetItemKeyInfo = C_AuctionHouse.GetItemKeyInfo
local C_AuctionHouse_GetQuoteDurationRemaining = C_AuctionHouse.GetQuoteDurationRemaining
local C_AuctionHouse_SendBrowseQuery = C_AuctionHouse.SendBrowseQuery
local C_Item_GetItemCount = C_Item.GetItemCount
local C_Item_GetItemIconByID = C_Item.GetItemIconByID
local C_Item_GetItemQualityByID = C_Item.GetItemQualityByID
local C_Item_GetItemQualityColor = C_Item.GetItemQualityColor
local C_TradeSkillUI_GetItemReagentQualityInfo = C_TradeSkillUI.GetItemReagentQualityInfo
local CreateFrame = CreateFrame
local GetMerchantItemID = GetMerchantItemID
local GetMerchantNumItems = GetMerchantNumItems
local GetMoney = GetMoney
local IsModifiedClick = IsModifiedClick
local IsShiftKeyDown = IsShiftKeyDown

local ChatFrameUtil_LinkItem = ChatFrameUtil.LinkItem
local CreateDataProvider = CreateDataProvider
local CreateScrollBoxListLinearView = CreateScrollBoxListLinearView
local Item = Item
local ScrollUtil_InitScrollBoxListWithScrollBar = ScrollUtil.InitScrollBoxListWithScrollBar

local Enum_AuctionHouseSortOrder_Price = Enum.AuctionHouseSortOrder.Price

-- GLOBALS: C_AuctionHouse.StartCommoditiesPurchase, C_AuctionHouse.ConfirmCommoditiesPurchase, C_AuctionHouse.CancelCommoditiesPurchase

---@class ProfessionShoppingData
---@field frame ProfessionShoppingWindowLine?
---@field itemID number
---@field itemCount number
---@field itemTargetCount number
---@field unitPrice number
---@field isAffordable boolean
---@field itemName string?
---@field isCommodity boolean
---@field auctionPurchasedCount number
---@field isStartedPurchase boolean
---@field auctionPurchasingCount number?
---@field auctionUnitPrice number?
---@field isConfirmedPurchase boolean

---@class ProfessionShoppingWindowLine: Button
---@field isCreated boolean
---@field data ProfessionShoppingData
---@field highlight Texture
---@field itemIcon ProfessionShoppingWindowLineItemIcon
---@field itemName FontString
---@field itemCount FontString
---@field unitPrice FontString
---@field totalPrice FontString

---@type table<number, true>
local pendingItemKeys = {}

---@param a ProfessionShoppingData
---@param b ProfessionShoppingData
local function Compare(a, b)
    return a.itemID < b.itemID
end

---@param data ProfessionShoppingData
---@return boolean
local function IsAffordable(data)
    local unitPrice = data.auctionUnitPrice or data.unitPrice
    local itemMissingCount = data.auctionPurchasingCount or math_max(data.itemTargetCount - (data.itemCount + data.auctionPurchasedCount), 0)
    local isAffordable = (unitPrice * itemMissingCount) <= GetMoney()

    return isAffordable
end

---@param itemID number
---@param itemTargetCount number
---@return ProfessionShoppingData
local function MakeData(itemID, itemTargetCount)
    local itemCount = C_Item_GetItemCount(itemID, true, false, true, true)
    local itemKeyInfo = C_AuctionHouse_GetItemKeyInfo({ itemID = itemID })

    ---@type string?
    local itemName = nil
    ---@type boolean
    local isCommodity = true
    if itemKeyInfo then
        itemName = itemKeyInfo.itemName
        isCommodity = itemKeyInfo.isCommodity
    else
        pendingItemKeys[itemID] = true
    end

    ---@type ProfessionShoppingData
    local data = {
        itemID = itemID,
        itemCount = itemCount,
        itemTargetCount = itemTargetCount,
        unitPrice = RP:GetItemPrice(itemID) or 0,
        isAffordable = true,
        itemName = itemName,
        isCommodity = isCommodity,
        auctionPurchasedCount = 0,
        isStartedPurchase = false,
        isConfirmedPurchase = false,
    }

    data.isAffordable = IsAffordable(data)

    return data
end

local function UpdateShoppingList()
    ---@type table<number, number>
    local itemTargetCounts = {}

    for _, data in RPO.dataProvider:Enumerate() do
        ---@cast data ProfessionOrderData

        if not data.failReason and data.isPending then
            for _, reagentInfo in ipairs(data.missingNormalReagentInfos) do
                local itemID = reagentInfo.reagent.itemID

                if itemID then
                    itemTargetCounts[itemID] = (itemTargetCounts[itemID] or 0) + reagentInfo.quantity
                end
            end

            for _, reagentInfo in ipairs(data.missingModifiedReagentInfos) do
                local itemID = reagentInfo.reagent.itemID

                if itemID then
                    itemTargetCounts[itemID] = (itemTargetCounts[itemID] or 0) + reagentInfo.quantity
                end
            end
        end
    end

    for index, data in RPS.dataProvider:ReverseEnumerate() do
        ---@cast data ProfessionShoppingData

        if not itemTargetCounts[data.itemID] then
            RPS.dataProvider:RemoveIndex(index)
        else
            if data.itemTargetCount ~= itemTargetCounts[data.itemID] then
                data.itemTargetCount = itemTargetCounts[data.itemID]
                data.isAffordable = IsAffordable(data)
                RPS.dataProvider:TriggerEvent('OnValueChanged', data)
            end

            itemTargetCounts[data.itemID] = nil
        end
    end

    for itemID, itemTargetCount in pairs(itemTargetCounts) do
        RPS.dataProvider:Insert(MakeData(itemID, itemTargetCount))
    end
end

local function ClearAllPurchasedCount()
    for _, data in RPS.dataProvider:Enumerate() do
        ---@cast data ProfessionShoppingData

        if data.auctionPurchasedCount and data.auctionPurchasedCount > 0 then
            data.auctionPurchasedCount = 0
            data.isAffordable = IsAffordable(data)

            RPS.dataProvider:TriggerEvent('OnValueChanged', data)
        end
    end
end

---@param itemID number
---@param quantity number
local function StartCommoditiesPurchase(itemID, quantity)
    for _, data in RPS.dataProvider:Enumerate() do
        ---@cast data ProfessionShoppingData

        if data.itemID == itemID and not data.isStartedPurchase then
            data.isStartedPurchase = true
            data.auctionPurchasingCount = quantity
            data.isAffordable = IsAffordable(data)

            RPS.dataProvider:TriggerEvent('OnValueChanged', data)
        elseif data.isStartedPurchase then
            -- another purchase started, cancel old purchase

            data.isStartedPurchase = false
            data.auctionPurchasingCount = nil
            data.auctionUnitPrice = nil
            data.isConfirmedPurchase = false
            data.isAffordable = IsAffordable(data)

            RPS.dataProvider:TriggerEvent('OnValueChanged', data)
        end
    end

    if RPS.priceTimer then
        RPS:CancelTimer(RPS.priceTimer)
        RPS.priceTimer = nil
    end
end

---@param itemID number
---@param quantity number
local function ConfirmCommoditiesPurchase(itemID, quantity)
    ---@param data ProfessionShoppingData
    ---@return boolean
    local function predicate(data)
        return data.itemID == itemID and data.isStartedPurchase and data.auctionPurchasingCount == quantity and data.auctionUnitPrice and not data.isConfirmedPurchase
    end

    ---@type ProfessionShoppingData?
    local data = RPS.dataProvider:FindElementDataByPredicate(predicate)
    if data then
        data.isConfirmedPurchase = true

        RPS.dataProvider:TriggerEvent('OnValueChanged', data)
    end

    if RPS.priceTimer then
        RPS:CancelTimer(RPS.priceTimer)
        RPS.priceTimer = nil
    end
end

local function CancelCommoditiesPurchase()
    for _, data in RPS.dataProvider:Enumerate() do
        ---@cast data ProfessionShoppingData

        if data.isStartedPurchase then
            data.isStartedPurchase = false
            data.auctionPurchasingCount = nil
            data.auctionUnitPrice = nil
            data.isConfirmedPurchase = false
            data.isAffordable = IsAffordable(data)

            RPS.dataProvider:TriggerEvent('OnValueChanged', data)
        end
    end

    if RPS.priceTimer then
        RPS:CancelTimer(RPS.priceTimer)
        RPS.priceTimer = nil
    end
end

function RPS:CancelCommoditiesPurchase()
    C_AuctionHouse.CancelCommoditiesPurchase()

    if self.priceTimer then
        self:CancelTimer(self.priceTimer)
        self.priceTimer = nil
    end
end

function RPS:COMMODITY_PURCHASE_SUCCEEDED()
    ---@param data ProfessionShoppingData
    ---@return boolean
    local function predicate(data)
        return data.isConfirmedPurchase
    end

    ---@type ProfessionShoppingData?
    local data = self.dataProvider:FindElementDataByPredicate(predicate)
    if data then
        data.auctionPurchasedCount = data.auctionPurchasedCount + data.auctionPurchasingCount

        data.isStartedPurchase = false
        data.auctionPurchasingCount = nil
        data.auctionUnitPrice = nil
        data.isConfirmedPurchase = false
        data.isAffordable = IsAffordable(data)

        self.dataProvider:TriggerEvent('OnValueChanged', data)
    end
end

---@param updatedUnitPrice number
function RPS:COMMODITY_PRICE_UPDATED(_, updatedUnitPrice)
    ---@param data ProfessionShoppingData
    ---@return boolean
    local function predicate(data)
        return data.isStartedPurchase
    end

    ---@type ProfessionShoppingData?
    local data = self.dataProvider:FindElementDataByPredicate(predicate)
    if data then
        data.auctionUnitPrice = updatedUnitPrice
        data.isAffordable = IsAffordable(data)

        self.dataProvider:TriggerEvent('OnValueChanged', data)

        if self.priceTimer then
            self:CancelTimer(self.priceTimer)
            self.priceTimer = nil
        end

        local quoteDurationSeconds = C_AuctionHouse_GetQuoteDurationRemaining()
        self.priceTimer = self:ScheduleTimer('CancelCommoditiesPurchase', quoteDurationSeconds)
    end
end

---@param itemID number
function RPS:ITEM_KEY_ITEM_INFO_RECEIVED(_, itemID)
    if not pendingItemKeys[itemID] then return end

    pendingItemKeys[itemID] = nil

    ---@param data ProfessionShoppingData
    ---@return boolean
    local function predicate(data)
        return data.itemID == itemID
    end

    ---@type number?, ProfessionShoppingData
    local index, data = self.dataProvider:FindByPredicate(predicate)
    if index then
        local itemKeyInfo = C_AuctionHouse_GetItemKeyInfo({ itemID = itemID })
        if itemKeyInfo then
            data.itemName = itemKeyInfo.itemName
            data.isCommodity = itemKeyInfo.isCommodity
            -- not affordability change

            self.dataProvider:TriggerEvent('OnValueChanged', data)
        end
    end
end

function RPS:BAG_UPDATE_DELAYED()
    for _, data in self.dataProvider:Enumerate() do
        ---@cast data ProfessionShoppingData

        local itemCount = C_Item_GetItemCount(data.itemID, true, false, true, true)
        if data.itemCount ~= itemCount then
            data.itemCount = itemCount
            data.isAffordable = IsAffordable(data)

            self.dataProvider:TriggerEvent('OnValueChanged', data)
        end
    end
end

function RPS:PLAYER_MONEY()
    for _, data in self.dataProvider:Enumerate() do
        ---@cast data ProfessionShoppingData

        local isAffordable = IsAffordable(data)
        if data.isAffordable ~= isAffordable then
            data.isAffordable = isAffordable

            self.dataProvider:TriggerEvent('OnValueChanged', data)
        end
    end
end

function RPS:MERCHANT_SHOW()
    ---@type table<number, number>
    local restockList = {}

    for _, data in self.dataProvider:Enumerate() do
        ---@cast data ProfessionShoppingData

        restockList[data.itemID] = math_max(data.itemTargetCount - (data.itemCount + data.auctionPurchasedCount), 0)
    end

    for i = 1, GetMerchantNumItems() do
        local itemID = GetMerchantItemID(i)
        if itemID and restockList[itemID] and restockList[itemID] > 0 then
            BuyMerchantItem(i, restockList[itemID])
        end
    end
end

do
    local COLOR_COPPER, COLOR_SILVER, COLOR_GOLD = '|cffeda55f', '|cffc7c7cf', '|cffffd700'
    ---@param money number
    ---@return string
    local function GetMoneyText(money)
        local value = math_abs(money)
        local gold = math_floor(value / 10000)
        local silver = math_floor((value % 10000) / 100)
        local copper = value % 100

		if gold > 0 then
			return string_format('%s%d|r %s%02d|r %s%02d|r', COLOR_GOLD, gold, COLOR_SILVER, silver, COLOR_COPPER, copper)
		elseif silver > 0 then
			return string_format('%s%d|r %s%02d|r', COLOR_SILVER, silver, COLOR_COPPER, copper)
		else
			return string_format('%s%d|r', COLOR_COPPER, copper)
		end
    end

    ---@param frame ProfessionShoppingWindowLine
    ---@param data ProfessionShoppingData
    function RPS:SetupShoppingLine(frame, data)
        frame.data = data
        data.frame = frame

        local itemID = data.itemID
        local itemMissingCount = data.auctionPurchasingCount or math_max(data.itemTargetCount - (data.itemCount + data.auctionPurchasedCount), 0)

        if not data.isAffordable then
            frame:SetBackdropColor(255 / 255, 107 / 255, 107 / 255, 0.1)
        elseif data.isStartedPurchase then
            frame:SetBackdropColor(107 / 255, 203 / 255, 119 / 255, 0.1)
        elseif itemMissingCount <= 0 then
            frame:SetBackdropColor(77 / 255, 150 / 255, 255 / 255, 0.1)
        elseif not data.isCommodity then
            frame:SetBackdropColor(255 / 255, 217 / 255, 61 / 255, 0.1)
        else -- data.isCommodity
            frame:SetBackdropColor(26 / 255, 26 / 255, 26 / 255, 0.1)
        end

        frame.itemName:SetText(data.itemName)
        frame.itemIcon.count:SetText(tostring(itemMissingCount))

        local rarity = C_Item_GetItemQualityByID(itemID)
        local itemIcon = C_Item_GetItemIconByID(itemID)
        if rarity and itemIcon then
            local info = C_TradeSkillUI_GetItemReagentQualityInfo(itemID)
            local r, g, b = C_Item_GetItemQualityColor((rarity and rarity > 1 and rarity) or 1)

            frame.itemIcon:SetBackdropBorderColor(r, g, b)
            frame.itemIcon.icon:SetTexture(itemIcon)
            if info then
                frame.itemIcon.qualityOverlay:SetAtlas(info.iconInventory, true)
            else
                ---@diagnostic disable-next-line: param-type-mismatch
                frame.itemIcon.qualityOverlay:SetAtlas(nil)
            end
        else
            local item = Item:CreateFromItemID(itemID)
            item:ContinueOnItemLoad(function()
                rarity = C_Item_GetItemQualityByID(itemID)
                itemIcon = C_Item_GetItemIconByID(itemID)

                local info = C_TradeSkillUI_GetItemReagentQualityInfo(itemID)
                local r, g, b = C_Item_GetItemQualityColor((rarity and rarity > 1 and rarity) or 1)

                frame.itemIcon:SetBackdropBorderColor(r, g, b)
                frame.itemIcon.icon:SetTexture(itemIcon)
                if info then
                    frame.itemIcon.qualityOverlay:SetAtlas(info.iconInventory, true)
                else
                    ---@diagnostic disable-next-line: param-type-mismatch
                    frame.itemIcon.qualityOverlay:SetAtlas(nil)
                end
            end)
        end

        if data.auctionPurchasedCount > 0 then
            frame.itemCount:SetText(string_format('%d + %d / %d', data.itemCount, data.auctionPurchasedCount, data.itemTargetCount))
        else
            frame.itemCount:SetText(string_format('%d / %d', data.itemCount, data.itemTargetCount))
        end

        local unitPrice = data.auctionUnitPrice or data.unitPrice
        if data.auctionUnitPrice and data.auctionUnitPrice > data.unitPrice then
            local risePercent = (data.auctionUnitPrice - data.unitPrice) / data.unitPrice * 100

            frame.unitPrice:SetText(string_format('x %s (+%.2f%%)', GetMoneyText(unitPrice), risePercent))
        else
            frame.unitPrice:SetText(string_format('x %s', GetMoneyText(unitPrice)))
        end

        local totalPrice = unitPrice * itemMissingCount
        frame.totalPrice:SetText(string_format('= %s', GetMoneyText(totalPrice)))
    end
end

do
    ---@param self ProfessionShoppingWindowLine
    local function LineOnEnter(self)
        self.highlight:Show()

        if not self.data then return end

        _G.GameTooltip:Hide()
        _G.GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        _G.GameTooltip:ClearLines()

        _G.GameTooltip:SetItemByID(self.data.itemID)

        _G.GameTooltip:Show()
    end

    ---@param self ProfessionShoppingWindowLine
    local function LineOnLeave(self)
        self.highlight:Hide()

        _G.GameTooltip:Hide()
    end

    ---@param self ProfessionShoppingWindowLine
    ---@param button string
    local function LineOnClick(self, button)
        if not _G.AuctionHouseFrame or not _G.AuctionHouseFrame:IsVisible() then return end

        local data = self.data

        if button ~= 'RightButton' and IsShiftKeyDown() then
            local itemName = data.itemName
            if itemName then
                _G.AuctionHouseFrame:SetSearchText(itemName)
                C_AuctionHouse_SendBrowseQuery({
                    searchString = itemName,
                    sorts = {
                        sortOrder = Enum_AuctionHouseSortOrder_Price,
                        reverseSort = false,
                    },
                    filters = {},
                })
                _G.AuctionHouseFrame:SetDisplayMode(_G.AuctionHouseFrameDisplayMode.Buy)
            end

            return
        end

        if button == 'RightButton' then
            if data.isStartedPurchase then
                RPS:CancelCommoditiesPurchase()
            end

            return
        end

        if not data.isAffordable then return end

        -- action sent and waiting for event
        if data.isConfirmedPurchase then return end

        if data.isStartedPurchase and data.auctionPurchasingCount and data.auctionUnitPrice then
            C_AuctionHouse.ConfirmCommoditiesPurchase(data.itemID, data.auctionPurchasingCount)
        end

        -- action sent and waiting for event
        if data.isStartedPurchase then return end

        local itemMissingCount = math_max(data.itemTargetCount - (data.itemCount + data.auctionPurchasedCount), 0)
        if itemMissingCount <= 0 then return end

        C_AuctionHouse.StartCommoditiesPurchase(data.itemID, itemMissingCount)
    end

    ---@param self ProfessionShoppingWindowLineItemIcon
    local function ItemIconOnEnter(self)
        ---@type ProfessionShoppingWindowLine
        local parent = self:GetParent()
        local data = parent.data

        _G.GameTooltip:Hide()
        _G.GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        _G.GameTooltip:ClearLines()

        _G.GameTooltip:SetItemByID(data.itemID)

        _G.GameTooltip:Show()
    end

    ---@param self ProfessionShoppingWindowLineItemIcon
    local function ItemIconOnLeave(self)
        _G.GameTooltip:Hide()
    end

    ---@param self ProfessionShoppingWindowLineItemIcon
    local function ItemIconOnClick(self)
        ---@type ProfessionShoppingWindowLine
        local parent = self:GetParent()
        local data = parent.data

        if IsModifiedClick('CHATLINK') then
            ChatFrameUtil_LinkItem(data.itemID)
        end
    end

    ---@param frame ProfessionShoppingWindowLine
    function RPS:BuildShoppingLine(frame)
        frame:SetSize(380, 34)
        frame:SetTemplate('Default')
        frame:RegisterForClicks('AnyUp')

        frame:SetScript('OnEnter', LineOnEnter)
        frame:SetScript('OnLeave', LineOnLeave)
        frame:SetScript('OnClick', LineOnClick)

        local highlight = frame:CreateTexture(nil, 'OVERLAY')
        highlight:ClearAllPoints()
        highlight:SetAllPoints()
        highlight:SetTexture(E.Media.Textures.White8x8)
        highlight:SetVertexColor(1, 1, 1, 0.03)
        highlight:Hide()
        frame.highlight = highlight

        ---@class ProfessionShoppingWindowLineItemIcon: Button
        local itemIcon = CreateFrame('Button', nil, frame, 'BackdropTemplate')
        itemIcon:SetSize(32, 32)
        itemIcon:SetPoint('LEFT', frame, 'LEFT', 1, 0)
        itemIcon:SetTemplate('Default')
        frame.itemIcon = itemIcon

        itemIcon:SetScript('OnEnter', ItemIconOnEnter)
        itemIcon:SetScript('OnLeave', ItemIconOnLeave)
        itemIcon:SetScript('OnClick', ItemIconOnClick)

        itemIcon.icon = itemIcon:CreateTexture(nil, 'ARTWORK')
        itemIcon.icon:SetInside(itemIcon, 2, 2)
        itemIcon.icon:SetTexCoord(.1, .9, .1, .9)

        itemIcon.count = itemIcon:CreateFontString(nil, 'OVERLAY')
        itemIcon.count:SetPoint('BOTTOMRIGHT', itemIcon, 'BOTTOMRIGHT', .5, 0)
        itemIcon.count:FontTemplate(nil, 14, 'OUTLINE')
        itemIcon.count:SetTextColor(1, 1, 1)

        itemIcon.qualityOverlay = itemIcon:CreateTexture(nil, 'OVERLAY')
        itemIcon.qualityOverlay:SetPoint('TOPLEFT', itemIcon, 'TOPLEFT', -3, 2)

        frame.itemName = frame:CreateFontString(nil, 'ARTWORK')
        frame.itemName:SetSize(240, 16)
        frame.itemName:SetPoint('TOPLEFT', frame.itemIcon, 'TOPRIGHT', 1, 0)
        frame.itemName:FontTemplate(nil, 16, 'OUTLINE')
        frame.itemName:SetTextColor(1, 1, 1)
        frame.itemName:SetJustifyH('LEFT')

        frame.itemCount = frame:CreateFontString(nil, 'ARTWORK')
        frame.itemCount:SetSize(120, 16)
        frame.itemCount:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -1, -1)
        frame.itemCount:FontTemplate(nil, 14, 'OUTLINE')
        frame.itemCount:SetTextColor(1, 1, 1)
        frame.itemCount:SetJustifyH('RIGHT')
        frame.itemCount:SetJustifyV('MIDDLE')

        frame.unitPrice = frame:CreateFontString(nil, 'ARTWORK')
        frame.unitPrice:SetSize(240, 16)
        frame.unitPrice:SetPoint('BOTTOMLEFT', frame.itemIcon, 'BOTTOMRIGHT', 1, 0)
        frame.unitPrice:FontTemplate(nil, 14, 'OUTLINE')
        frame.unitPrice:SetTextColor(1, 1, 1)
        frame.unitPrice:SetJustifyH('LEFT')
        frame.unitPrice:SetJustifyV('MIDDLE')

        frame.totalPrice = frame:CreateFontString(nil, 'ARTWORK')
        frame.totalPrice:SetSize(120, 16)
        frame.totalPrice:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -1, -1)
        frame.totalPrice:FontTemplate(nil, 14, 'OUTLINE')
        frame.totalPrice:SetTextColor(1, 1, 1)
        frame.totalPrice:SetJustifyH('RIGHT')
        frame.totalPrice:SetJustifyV('MIDDLE')
    end
end

do
    ---@param self ProfessionShoppingWindowProcessButton
    local function OnEnter(self)
        self.highlight:Show()
    end

    ---@param self ProfessionShoppingWindowProcessButton
    local function OnLeave(self)
        self.highlight:Hide()
    end

    ---@param self ProfessionShoppingWindowProcessButton
    ---@param text string
    local function SetText(self, text)
        self.text:SetText(text)
    end

    function RPS:BuildButton()
        local window = self.window

        ---@class ProfessionShoppingWindowProcessButton: Button
        local button = CreateFrame('Button', nil, window)
        button:SetSize(380, 24)
        button:SetTemplate('Default')

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
        button.text:FontTemplate(nil, 18)
        button.text:SetTextColor(1, 1, 1)

        button.SetText = SetText

        return button
    end
end

function RPS:BuildWindow()
    ---@class ProfessionShoppingWindow: Frame
    local window = CreateFrame('Frame', 'RhythmBoxProfessionShoppingWindow', RPO.window, 'BackdropTemplate')
    window:SetTemplate('Transparent', true)
    window:SetFrameStrata('DIALOG')
    window:SetPoint('TOPLEFT', RPO.window, 'TOPRIGHT', 0, 0)
    window:SetPoint('BOTTOMRIGHT', RPO.window, 'BOTTOMRIGHT', 400, 0)
    self.window = window

    local cleanPurchasedButton = self:BuildButton()
    cleanPurchasedButton:SetPoint('TOP', window, 'TOP', 0, -145)
    cleanPurchasedButton:SetText("清空已购买")
    cleanPurchasedButton:SetScript('OnClick', ClearAllPurchasedCount)
    window.cleanPurchasedButton = cleanPurchasedButton

    local scrollBox = CreateFrame('Frame', nil, window, 'WowScrollBoxList')
    scrollBox:SetPoint('TOPLEFT', window, 'TOPLEFT', 10, -181)
    scrollBox:SetPoint('BOTTOMRIGHT', window, 'BOTTOMRIGHT', -10, 10)
    scrollBox:SetTemplate('Transparent')

    local scrollBar = CreateFrame('EventFrame', nil, window, 'MinimalScrollBar')
    scrollBar:SetPoint('TOPLEFT', scrollBox, 'TOPRIGHT')
    scrollBar:SetPoint('BOTTOMLEFT', scrollBox, 'BOTTOMRIGHT')
    S:HandleScrollBar(scrollBar, nil, nil, 'NoBackdrop')

    local scrollView = CreateScrollBoxListLinearView()
    scrollView:SetElementExtent(34)
    scrollView:SetElementInitializer('Button', function(frame, data)
        if not frame.isCreated then
            self:BuildShoppingLine(frame)
            frame.isCreated = true
        end

        self:SetupShoppingLine(frame, data)
    end)
    scrollView:SetDataProvider(self.dataProvider)
    window.scrollView = scrollView

    ScrollUtil_InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)
end

function RPS:Initialize()
    self.dataProvider = CreateDataProvider()
    self.dataProvider:SetSortComparator(Compare, true)
    -- self.dataProvider:GenerateCallbackEvents({ 'OnValueChanged' })

    self:BuildWindow()

    RPO.dataProvider:RegisterCallback(RPO.dataProvider.Event.OnValueChanged, UpdateShoppingList, self)
    RPO.dataProvider:RegisterCallback(RPO.dataProvider.Event.OnSizeChanged, UpdateShoppingList, self)

    ---@param data ProfessionShoppingData?
    local function OnValueChanged(_, data)
        if data and data.frame then
            self:SetupShoppingLine(data.frame, data)
        end
    end

    self:RegisterEvent('MERCHANT_SHOW')
    self:RegisterEvent('PLAYER_MONEY')
    self:RegisterEvent('BAG_UPDATE_DELAYED')
    self:RegisterEvent('ITEM_KEY_ITEM_INFO_RECEIVED')
    self:RegisterEvent('COMMODITY_PRICE_UPDATED')
    self:RegisterEvent('COMMODITY_PURCHASE_SUCCEEDED')
    self.dataProvider:RegisterCallback(self.dataProvider.Event.OnValueChanged, OnValueChanged, self)

    self:RegisterEvent('AUCTION_HOUSE_CLOSED', 'CancelCommoditiesPurchase')
    self:RegisterEvent('COMMODITY_PRICE_UNAVAILABLE', 'CancelCommoditiesPurchase')
    self:RegisterEvent('COMMODITY_PURCHASE_FAILED', 'CancelCommoditiesPurchase')

    self:SecureHook(_G.C_AuctionHouse, 'StartCommoditiesPurchase', StartCommoditiesPurchase)
    self:SecureHook(_G.C_AuctionHouse, 'ConfirmCommoditiesPurchase', ConfirmCommoditiesPurchase)
    self:SecureHook(_G.C_AuctionHouse, 'CancelCommoditiesPurchase', CancelCommoditiesPurchase)
    self:SecureHook(_G.C_Mail, 'SetOpeningAll', function(openingAll)
        if not openingAll then
            ClearAllPurchasedCount()
        end
    end)
end

R:RegisterModule(RPS:GetName())
