local R, E, L, V, P, G = unpack((select(2, ...)))
local IC = R:NewModule('ItemCleaner', 'AceEvent-3.0', 'AceTimer-3.0')
local TB = R:GetModule('Toolbox')
local S = E:GetModule('Skins')

-- Lua functions
local _G = _G
local error, ipairs, pcall = error, ipairs, pcall
local bit_band = bit.band
local coroutine_create = coroutine.create
local coroutine_resume = coroutine.resume
local coroutine_status = coroutine.status
local coroutine_yield = coroutine.yield
local string_format = string.format
local table_insert = table.insert

-- WoW API / Variables
local C_Bank_FetchPurchasedBankTabData = C_Bank.FetchPurchasedBankTabData
local C_Container_GetContainerItemInfo = C_Container.GetContainerItemInfo
local C_Container_GetContainerNumSlots = C_Container.GetContainerNumSlots
local C_Container_PickupContainerItem = C_Container.PickupContainerItem
local C_Container_UseContainerItem = C_Container.UseContainerItem
local C_Item_GetItemInfo = C_Item.GetItemInfo
local CreateFrame = CreateFrame

local tContains = tContains

local Enum_BagSlotFlags_ClassReagents = Enum.BagSlotFlags.ClassReagents
local Enum_BankType_Account = Enum.BankType.Account
local Enum_BankType_Character = Enum.BankType.Character
local Enum_ItemBind_OnAcquire = Enum.ItemBind.OnAcquire

---@class ItemData
---@field bagID Enum.BagIndex
---@field slotID number
---@field itemID number
---@field iconFileID number
---@field itemLink string
---@field itemName string
---@field classID number
---@field subClassID number
---@field bindType number
---@field expansionID number
---@field isCraftingReagent boolean

local allCharactersExtraAllowItems = {
    166846, -- Spare Parts
    166970, -- Energy Cell
    166971, -- Empty Energy Cell
    168327, -- Chain Ignitercoil
    168832, -- Galvanic Oscillator
    169610, -- S.P.A.R.E. Crate
}

local characterExtraAllowItems = {
    ['小只萌迪凯'] = {
        11754, -- Black Diamond
    },
    ['卡登斯邃光'] = {
        108996, -- Alchemical Catalyst
        109123, -- Crescent Oil
    },
    ['小只大萌术'] = {
        61981, -- Inferno Ink
    },
}

local warbandExtraAllowItems = {
    17056, -- Light Feather
    188957, -- Genesis Mote
    189150, -- Raptora Lattice
    189152, -- Tarachnid Lattice
    189157, -- Glimmer of Animation
    189159, -- Glimmer of Discovery
    189160, -- Glimmer of Focus
    189163, -- Glimmer of Motion
    189166, -- Glimmer of Renewal
    189170, -- Glimmer of Vigilance
    189172, -- Crystallized Echo of the First Song
    189173, -- Eternal Ragepearl
    189175, -- Mawforged Bridle
    189176, -- Protoform Sentience Crown
    190388, -- Lupine Lattice
    202173, -- Magmote
}

local extraUsefulItems = {
    146710, -- Bolt of Shadowcloth
    146711, -- Bolt of Starweave
    146712, -- Wisp-Touched Elderhide
    146713, -- Prime Wardenscale
    146714, -- Hammer of Forgotten Heroes
    166971, -- Empty Energy Cell
    210814, -- Artisan's Acuity
}

local currentExpansion = math.floor(select(4, GetBuildInfo()) / 10000) - 1

local processCoroutine

local function ItemFrameOnEnter(self)
    if not self.itemData then return end

    _G.GameTooltip:Hide()
    _G.GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT', 0, -2)
    _G.GameTooltip:ClearLines()

    _G.GameTooltip:SetHyperlink(self.itemData.itemLink)
    _G.GameTooltip:Show()
end

local function ItemFrameOnLeave(self)
    _G.GameTooltip:Hide()
end

local function ItemFrameOnClick(self, button)
    if not self.itemData then return end

    if button == 'LeftButton' then
        C_Container_PickupContainerItem(self.itemData.bagID, self.itemData.slotID)
    else
        C_Container_UseContainerItem(self.itemData.bagID, self.itemData.slotID)
    end
end

local function OnUpdate(self)
    local status = coroutine_status(processCoroutine)
    if status == 'dead' then
        IC:FinishProcess('empty')
        return
    elseif status == 'suspended' then
        local success, value, total, itemData, allowed, useful = coroutine_resume(processCoroutine)
        if not success then
            IC:FinishProcess('error')
            error(value)
        end

        if not value then
            IC:FinishProcess('success')
            return
        end

        IC.window.progressValue:SetText(string_format("%d/%d (%d%%)", value, total, value / total * 100))

        if itemData then
            local hasRemaingFrame = IC:ReportItem(itemData, allowed, useful)
            if not hasRemaingFrame then
                IC:FinishProcess('cancel')
            end
        end
    end
end

---@param itemData ItemData
---@return boolean | nil
local function CheckIfItemUseful(itemData)
    if itemData.expansionID >= currentExpansion then
        return true
    end

    if tContains(extraUsefulItems, itemData.itemID) then
        return true
    end

    local att = _G.AllTheThings
    att.SetSkipLevel(1)
    local status, group, working = pcall(att.GetCachedSearchResults, att.SearchForLink, itemData.itemLink)
    att.SetSkipLevel(0)

    if not status or working or not group or group.working then
        return nil
    end

    return group.progress < group.total
end

---@param itemData ItemData
---@return boolean
local function CheckIfItemAllowed(itemData)
    local isWarbandBank = itemData.bagID >= 12

    if not isWarbandBank and tContains(allCharactersExtraAllowItems, itemData.itemID) then
        return true
    end

    if not isWarbandBank and characterExtraAllowItems[E.myname] and tContains(characterExtraAllowItems[E.myname], itemData.itemID) then
        return true
    end

    if isWarbandBank and tContains(warbandExtraAllowItems, itemData.itemID) then
        return true
    end

    if not itemData.isCraftingReagent then
        return false
    end

    if itemData.classID ~= 7 then -- Tradeskill
        return false
    end

    if isWarbandBank then
        return itemData.subClassID ~= 1 and -- Parts
            itemData.subClassID ~= 4 and -- Jewelcrafting
            itemData.subClassID ~= 5 and -- Cloth
            itemData.subClassID ~= 12 and -- Enchanting
            itemData.subClassID ~= 16 -- Inscription
    elseif itemData.bindType == Enum_ItemBind_OnAcquire then
        return itemData.subClassID ~= 18 and -- Optional Reagents
            itemData.subClassID ~= 19 -- Finishing Reagents
    elseif E.myname == '小只大萌德' then
        return itemData.subClassID == 12 -- Enchanting
    elseif E.myname == '小只萌迪凯' then
        return itemData.subClassID == 4 -- Jewelcrafting
    elseif E.myname == '卡登斯邃光' then
        return itemData.subClassID == 1 -- Parts
    elseif E.myname == '小只大萌术' then
        return itemData.subClassID == 5 or -- Cloth
            itemData.subClassID == 16 -- Inscription
    end

    return false
end

---@param itemDatas ItemData[]
local function Process(itemDatas)
    local value = 0
    local total = #itemDatas

    while value < total do
        value = value + 1

        local itemData = itemDatas[value]
        local allowed = CheckIfItemAllowed(itemData)
        local useful = CheckIfItemUseful(itemData)
        if allowed and useful then
            coroutine_yield(value, total)
        elseif allowed == false or useful == false then
            coroutine_yield(value, total, itemData, allowed, useful)
        else
            value = value - 1
            coroutine_yield(value, total)
        end
    end
end

---@param bagIDs Enum.BagIndex[]
---@return ItemData[] | nil
function IC:GetAllItemData(bagIDs)
    ---@type ItemData[]
    local itemDatas = {}

    local isVaildInfo = true

    for _, bagID in ipairs(bagIDs) do
        local numSlots = C_Container_GetContainerNumSlots(bagID)
        for slotID = 1, numSlots do
            local itemInfo = C_Container_GetContainerItemInfo(bagID, slotID)
            if itemInfo then
                local itemName, _, _, _, _, _, _, _, _, _, _, classID, subclassID, bindType, expansionID, _, isCraftingReagent = C_Item_GetItemInfo(itemInfo.hyperlink)
                if not itemName then
                    isVaildInfo = false
                end

                table_insert(itemDatas, {
                    bagID = bagID,
                    slotID = slotID,
                    iconFileID = itemInfo.iconFileID,
                    itemID = itemInfo.itemID,
                    itemLink = itemInfo.hyperlink,
                    itemName = itemName,
                    classID = classID,
                    subClassID = subclassID,
                    bindType = bindType,
                    expansionID = expansionID,
                    isCraftingReagent = isCraftingReagent,
                })
            end
        end
    end

    return isVaildInfo and itemDatas or nil
end

---@return Enum.BagIndex[] | nil
function IC:GetReagentBags()
    local characterBankTabData = C_Bank_FetchPurchasedBankTabData(Enum_BankType_Character)
    local accountBankTabData = E.myname == '小只大萌德'
        and C_Bank_FetchPurchasedBankTabData(Enum_BankType_Account)
        or {}

    local bagIDs = {}
    for _, tabData in ipairs(characterBankTabData) do
        if bit_band(tabData.depositFlags, Enum_BagSlotFlags_ClassReagents) > 0 then
            table_insert(bagIDs, tabData.ID)
        end
    end
    for _, tabData in ipairs(accountBankTabData) do
        if bit_band(tabData.depositFlags, Enum_BagSlotFlags_ClassReagents) > 0 then
            table_insert(bagIDs, tabData.ID)
        end
    end
    return bagIDs
end

function IC:FinishProcess(status)
    self.updateFrame:Hide()

    self.window.processButton:Enable()
    if status == 'success' then
        self.window.progressValue:SetTextColor(0, 1, 0, 1)
    elseif status == 'error' then
        self.window.progressValue:SetTextColor(1, 0, 0, 1)
    elseif status == 'cancel' or status == 'empty' then
        self.window.progressValue:SetTextColor(1, 1, 0, 1)
    end
end

function IC:ReportItem(itemData, allowed, useful)
    self.currentItemFrame = self.currentItemFrame + 1
    if self.currentItemFrame > #self.window.itemFrames then
        return false
    end

    local itemFrame = self.window.itemFrames[self.currentItemFrame]
    itemFrame.itemIcon:SetTexture(itemData.iconFileID)
    itemFrame.itemName:SetText(itemData.itemLink)
    itemFrame.itemAllowStatus:SetText(allowed and "允许" or "不许")
    itemFrame.itemAllowStatus:SetTextColor(allowed and 0 or 1, allowed and 1 or 0, 0, 1)
    itemFrame.itemUsefulStatus:SetText(useful and "有用" or "无用")
    itemFrame.itemUsefulStatus:SetTextColor(useful and 0 or 1, useful and 1 or 0, 0, 1)
    itemFrame:Show()

    itemFrame.itemData = itemData

    return self.currentItemFrame < #self.window.itemFrames
end

function IC:StartProcess()
    self.window.processButton:Disable()
    self.window.progressValue:SetText("0/0 (0%)")
    self.window.progressValue:SetTextColor(1, 1, 1, 1)
    self.currentItemFrame = 0
    for _, itemFrame in ipairs(self.window.itemFrames) do
        itemFrame:Hide()
        itemFrame.itemData = nil
    end

    local bagIDs = self:GetReagentBags()
    if not bagIDs then
        self:FinishProcess('empty')
        return
    end

    local itemDatas = self:GetAllItemData(bagIDs)
    if not itemDatas then
        E:Delay(1, self.StartProcess, self)
        return
    end

    processCoroutine = coroutine_create(function()
        Process(itemDatas)
    end)

    self.updateFrame:Show()
end

function IC:BuildWindow()
    local window = CreateFrame('Frame', nil, E.UIParent, 'BackdropTemplate')

    window:SetTemplate('Transparent', true)
    window:SetFrameStrata('DIALOG')
    window:SetPoint('CENTER')
    window:SetSize(600, 550)
    window:Hide()

    local closeButton = CreateFrame('Button', nil, window)
    closeButton:SetSize(32, 32)
    closeButton:SetPoint('TOPRIGHT', 1, 1)
    closeButton:SetScript('OnClick', function()
        window:Hide()
    end)
    S:HandleCloseButton(closeButton)

    local titleText = window:CreateFontString(nil, 'ARTWORK')
    titleText:FontTemplate(nil, 20)
    titleText:SetTextColor(1, 1, 1, 1)
    titleText:SetPoint('CENTER', window, 'TOP', 0, -25)
    titleText:SetJustifyH('CENTER')
    titleText:SetText("Item Cleaner")

    local processButton = CreateFrame('Button', nil, window, 'UIPanelButtonTemplate')
    processButton:SetSize(560, 38)
    processButton:SetPoint('TOP', 0, -40)
    processButton:SetText("清理物品")
    processButton:SetScript('OnClick', function()
        IC:StartProcess()
    end)
    S:HandleButton(processButton)
    window.processButton = processButton

    local progressValue = window:CreateFontString(nil, 'ARTWORK')
    progressValue:ClearAllPoints()
    progressValue:SetPoint('TOP', 0, -85)
    progressValue:SetSize(400, 40)
    progressValue:FontTemplate(nil, 40, 'OUTLINE')
    progressValue:SetTextColor(1, 1, 1, 1)
    progressValue:SetJustifyH('CENTER')
    progressValue:SetText("0/0 (0%)")
    window.progressValue = progressValue

    window.itemFrames = {}
    for i = 1, 10 do
        local itemFrame = CreateFrame('Button', nil, window)
        itemFrame:ClearAllPoints()
        itemFrame:SetPoint('TOP', 0, -85 - i * 40)
        itemFrame:SetSize(560, 40)
        itemFrame:Hide()
        itemFrame:RegisterForClicks('AnyUp')
        itemFrame:SetScript('OnEnter', ItemFrameOnEnter)
        itemFrame:SetScript('OnLeave', ItemFrameOnLeave)
        itemFrame:SetScript('OnClick', ItemFrameOnClick)

        local itemIcon = itemFrame:CreateTexture(nil, 'ARTWORK')
        itemIcon:SetSize(32, 32)
        itemIcon:SetPoint('LEFT', 2, 0)
        itemIcon:SetTexCoord(.1, .9, .1, .9)
        itemFrame.itemIcon = itemIcon

        local itemName = itemFrame:CreateFontString(nil, 'ARTWORK')
        itemName:ClearAllPoints()
        itemName:SetPoint('LEFT', itemIcon, 'RIGHT', 5, 0)
        itemName:SetSize(400, 40)
        itemName:FontTemplate(nil, 20, 'OUTLINE')
        itemName:SetTextColor(1, 1, 1, 1)
        itemFrame.itemName = itemName

        local itemAllowStatus = itemFrame:CreateFontString(nil, 'ARTWORK')
        itemAllowStatus:ClearAllPoints()
        itemAllowStatus:SetPoint('RIGHT', -50, 0)
        itemAllowStatus:SetSize(150, 40)
        itemAllowStatus:FontTemplate(nil, 20, 'OUTLINE')
        itemAllowStatus:SetTextColor(1, 1, 1, 1)
        itemAllowStatus:SetJustifyH('RIGHT')
        itemFrame.itemAllowStatus = itemAllowStatus

        local itemUsefulStatus = itemFrame:CreateFontString(nil, 'ARTWORK')
        itemUsefulStatus:ClearAllPoints()
        itemUsefulStatus:SetPoint('RIGHT', -5, 0)
        itemUsefulStatus:SetSize(150, 40)
        itemUsefulStatus:FontTemplate(nil, 20, 'OUTLINE')
        itemUsefulStatus:SetTextColor(1, 1, 1, 1)
        itemUsefulStatus:SetJustifyH('RIGHT')
        itemFrame.itemUsefulStatus = itemUsefulStatus

        table_insert(window.itemFrames, itemFrame)
    end

    return window
end

function IC:Initialize()
    self.currentItemFrame = 0

    local updateFrame = CreateFrame('Frame')
    updateFrame:Hide()
    updateFrame:SetScript('OnUpdate', OnUpdate)
    self.updateFrame = updateFrame

    local window = self:BuildWindow()
    self.window = window

    TB:RegisterSubWindow(window, 'Item Cleaner')
end

R:RegisterModule(IC:GetName())
