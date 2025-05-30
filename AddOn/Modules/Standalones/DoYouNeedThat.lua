local R, E, L, V, P, G = unpack((select(2, ...)))
local DY = R:NewModule('DoYouNeedThat', 'AceEvent-3.0', 'AceTimer-3.0')
local S = E:GetModule('Skins')

-- Lua functions
local _G = _G
local format, gsub, ipairs, select, strfind = format, gsub, ipairs, select, strfind
local strmatch, strsplit, tinsert, tostring, type = strmatch, strsplit, tinsert, tostring, type

-- WoW API / Variables
local C_Item_DoesItemContainSpec = C_Item.DoesItemContainSpec
local C_Item_GetDetailedItemLevelInfo = C_Item.GetDetailedItemLevelInfo
local C_Item_GetItemIconByID = C_Item.GetItemIconByID
local C_Item_GetItemInfo = C_Item.GetItemInfo
local C_Item_GetItemNameByID = C_Item.GetItemNameByID
local C_Item_GetItemQualityByID = C_Item.GetItemQualityByID
local C_Item_GetItemQualityColor = C_Item.GetItemQualityColor
local C_Item_GetItemUpgradeInfo = C_Item.GetItemUpgradeInfo
local C_Item_IsEquippableItem = C_Item.IsEquippableItem
local C_Item_RequestLoadItemDataByID = C_Item.RequestLoadItemDataByID
local CanInspect = CanInspect
local CreateFrame = CreateFrame
local GetInventoryItemID = GetInventoryItemID
local GetInventoryItemLink = GetInventoryItemLink
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local GetSpecializationInfo = GetSpecializationInfo
local GetTime = GetTime
local IsInInstance = IsInInstance
local IsInRaid = IsInRaid
local NotifyInspect = NotifyInspect
local SendChatMessage = SendChatMessage
local UnitClass = UnitClass
local UnitGUID = UnitGUID
local UnitIsUnit = UnitIsUnit
local UnitTokenFromGUID = UnitTokenFromGUID

local utf8len = string.utf8len
local utf8sub = string.utf8sub

local Enum_ItemBind_OnAcquire = Enum.ItemBind.OnAcquire
local Enum_ItemClass_Armor = Enum.ItemClass.Armor
local Enum_ItemClass_Weapon = Enum.ItemClass.Weapon
local Enum_ItemQuality_Epic = Enum.ItemQuality.Epic
local INVSLOT_FIRST_EQUIPPED = INVSLOT_FIRST_EQUIPPED
local INVSLOT_LAST_EQUIPPED = INVSLOT_LAST_EQUIPPED
local YOU = YOU

local pattern = gsub(LOOT_ITEM, '%%[ds]', '(.+)')

local itemEquipLocToInvSlotID = {
    INVTYPE_HEAD = 1,
    INVTYPE_NECK = 2,
    INVTYPE_SHOULDER = 3,
    INVTYPE_BODY = 4,
    INVTYPE_CHEST = 5,
    INVTYPE_WAIST = 6,
    INVTYPE_LEGS = 7,
    INVTYPE_FEET = 8,
    INVTYPE_WRIST = 9,
    INVTYPE_HAND = 10,
    INVTYPE_FINGER = {11, 12},
    INVTYPE_TRINKET = {13, 14},
    INVTYPE_WEAPON = {16, 17},
    INVTYPE_SHIELD = 17,
    INVTYPE_RANGED = 16,
    INVTYPE_CLOAK = 15,
    INVTYPE_2HWEAPON = 16,
    INVTYPE_TABARD = 19,
    INVTYPE_ROBE = 5,
    INVTYPE_WEAPONMAINHAND = 16,
    INVTYPE_WEAPONOFFHAND = 16,
    INVTYPE_HOLDABLE = 17,
    INVTYPE_THROWN = 16,
    INVTYPE_RANGEDRIGHT = 16,
}

local itemEquipLocToName = {
    INVTYPE_HEAD = '头',
    INVTYPE_NECK = '项链',
    INVTYPE_SHOULDER = '肩膀',
    INVTYPE_CHEST = '胸',
    INVTYPE_WAIST = '腰带',
    INVTYPE_LEGS = '腿',
    INVTYPE_FEET = '鞋子',
    INVTYPE_WRIST = '护腕',
    INVTYPE_HAND = '手',
    INVTYPE_FINGER = '戒指',
    INVTYPE_TRINKET = 'SP',
    INVTYPE_WEAPON = '武器',
    INVTYPE_SHIELD = '盾牌',
    INVTYPE_RANGED = '武器',
    INVTYPE_CLOAK = '披风',
    INVTYPE_2HWEAPON = '武器',
    INVTYPE_ROBE = '胸',
    INVTYPE_WEAPONMAINHAND = '武器',
    INVTYPE_WEAPONOFFHAND = '武器',
    INVTYPE_HOLDABLE = '副手',
    INVTYPE_THROWN = '武器',
    INVTYPE_RANGEDRIGHT = '武器',
}

---@param self DoYouNeedThatLineButton
local function ButtonOnClick(self)
    if self.itemRefName and self.playerFullName then
        SendChatMessage(format('请问%s要吗？', self.itemRefName), 'WHISPER', nil, self.playerFullName)

        self.itemRefName = nil
        self.playerFullName = nil

        self:Disable()
    end
end

---@param self DoYouNeedThatLineItem|DoYouNeedThatLineFullItem
local function ItemFrameOnEnter(self)
    if self.itemLink then
        _G.GameTooltip:Hide()
        _G.GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
        _G.GameTooltip:ClearLines()

        _G.GameTooltip:SetHyperlink(self.itemLink)
        _G.GameTooltip:Show()
    end
end

local function ItemFrameOnLeave()
    _G.GameTooltip:Hide()
end

---@param frame DoYouNeedThatLineItem|DoYouNeedThatLineFullItem
---@param itemLink string|nil
function DY:SetupItemFrame(frame, itemLink)
    if not itemLink then
        frame.itemLink = nil

        frame.icon:SetTexture(134400) -- INV_Misc_QuestionMark
        frame.ilvl:SetText('')
        frame.tier:SetText('')
        if frame.name then
            frame.name:SetText('')
        end

        return
    end

    local itemIcon = C_Item_GetItemIconByID(itemLink)
    local itemLevel = C_Item_GetDetailedItemLevelInfo(itemLink)
    local itemRarity = C_Item_GetItemQualityByID(itemLink)
    local r, g, b = C_Item_GetItemQualityColor((itemRarity and itemRarity > 1 and itemRarity) or 1)

    frame.itemLink = itemLink

    frame.icon:SetTexture(itemIcon)
    frame.ilvl:SetText(tostring(itemLevel))
    frame.ilvl:SetTextColor(r, g, b)

    if frame.name then
        local itemName = C_Item_GetItemNameByID(itemLink)
        frame.name:SetText(itemName)
        frame.name:SetTextColor(r, g, b)
    end

    local info = C_Item_GetItemUpgradeInfo(itemLink)
    if info and info.trackString then
        if utf8len(info.trackString) > 2 then
            frame.tier:SetText(utf8sub(info.trackString, 1, 2))
        else
            frame.tier:SetText(info.trackString)
        end
        frame.tier:SetTextColor(r, g, b)
    else
        frame.tier:SetText('')
    end
end

function DY:AddEntry(itemLink, playerName)
    if not C_Item_IsEquippableItem(itemLink) then return end

    local _, _, itemRarity, _, _, _, _, _, itemEquipLoc, _, _, itemClassID, _, bindType = C_Item_GetItemInfo(itemLink)
    if (
        itemRarity ~= Enum_ItemQuality_Epic or
        (itemClassID ~= Enum_ItemClass_Weapon and itemClassID ~= Enum_ItemClass_Armor) or
        bindType ~= Enum_ItemBind_OnAcquire
    ) then return end

    local itemCanEquip = C_Item_DoesItemContainSpec(itemLink, E.myClassID)
    local itemCanDrop = C_Item_DoesItemContainSpec(itemLink, E.myClassID, (GetSpecializationInfo(E.myspec)))
    if not itemCanEquip then return end

    if self.window.usingLines >= #self.window.lines then
        self:BuildEntryLine()
    end
    self.window.usingLines = self.window.usingLines + 1

    self.window:SetHeight(68 + 32 * self.window.usingLines)
    local line = self.window.lines[self.window.usingLines]
    line:Show()

    local classFilename = select(2, UnitClass(playerName))
    local classColor = E:ClassColor(classFilename)
    line.character:SetTextColor(classColor:GetRGB())

    if strfind(playerName, '-') then
        line.character:SetText(strsplit('-', playerName))
        line.button.playerFullName = playerName
    else
        line.character:SetText(playerName)
        line.button.playerFullName = playerName .. '-' .. E.myrealm
    end

    line.button.itemRefName = itemEquipLocToName[itemEquipLoc] or itemLink
    line.button.text:SetText(itemCanDrop and '需求' or '贪婪')

    self:SetupItemFrame(line.item, itemLink)

    local playerGUID = UnitGUID(playerName)
    if playerGUID and self.partyMember[playerGUID] and self.partyMember[playerGUID].gear then
        local gear = self.partyMember[playerGUID].gear
        local invSlotID = itemEquipLocToInvSlotID[itemEquipLoc]
        if type(invSlotID) == 'table' then
            self:SetupItemFrame(line.gearItem1, gear[invSlotID[1]])

            if gear[invSlotID[2]] then
                self:SetupItemFrame(line.gearItem2, gear[invSlotID[2]])
                line.gearItem2:Show()
            else
                line.gearItem2:Hide()
            end
        elseif gear[invSlotID] then
            self:SetupItemFrame(line.gearItem1, gear[invSlotID])
            line.gearItem2:Hide()
        end
    else
        self:SetupItemFrame(line.gearItem1, nil)
        line.gearItem2:Hide()
    end

    self.window:Show()
end

function DY:ClearEntries()
    self.window.usingLines = 0
    for _, line in ipairs(self.window.lines) do
        line:Hide()
    end
end

function DY:CHAT_MSG_LOOT(_, text)
    local name, itemLink = strmatch(text, pattern)
    if not itemLink or name == YOU then return end

    self:AddEntry(itemLink, name)
end

function DY:INSPECT_READY(_, unitGUID)
    local unitID = UnitTokenFromGUID(unitGUID)
    if not unitID then return end

    if not self.partyMember[unitGUID] then
        self.partyMember[unitGUID] = {
            gear = {},
        }
    end

    local isAllReady = true
    for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        local itemID = GetInventoryItemID(unitID, i)
        local itemLink = GetInventoryItemLink(unitID, i)

        if itemLink then
            self.partyMember[unitGUID].gear[i] = itemLink
        elseif itemID then
            isAllReady = false
            C_Item_RequestLoadItemDataByID(itemID)
        end
    end

    self.partyMember[unitGUID].expiredTime = GetTime() + (isAllReady and 600 or 30)
end

function DY:InspectPartyMember()
    local now = GetTime()

    local prefix = IsInRaid() and 'raid' or 'party'
    local length = prefix == 'party' and GetNumSubgroupMembers() or GetNumGroupMembers()
    for i = 1, length do
        local unitID = prefix .. i
        local unitGUID = UnitGUID(unitID)
        if unitGUID and (prefix ~= 'raid' or not UnitIsUnit(unitID, 'player')) and CanInspect(unitID) then
            local expiredTime = self.partyMember[unitGUID] and self.partyMember[unitGUID].expiredTime
            if not expiredTime or expiredTime < now then
                self:RegisterEvent('INSPECT_READY')
                NotifyInspect(unitID)
                return
            end
        end
    end

    self:UnregisterEvent('INSPECT_READY')
end

function DY:PLAYER_ENTERING_WORLD()
    local inInstance = IsInInstance()
    if inInstance then
        self:RegisterEvent('CHAT_MSG_LOOT')

        if self.timer then
            self:CancelTimer(self.timer)
        end
        self.timer = self:ScheduleRepeatingTimer('InspectPartyMember', 7)
    else
        self:UnregisterEvent('CHAT_MSG_LOOT')

        if self.timer then
            self:CancelTimer(self.timer)
            self.timer = nil
        end
    end
end

function DY:BuildEntryLine()
    local window = self.window
    local index = #window.lines + 1

    ---@class DoYouNeedThatLine: Frame
    local line = CreateFrame('Frame', nil, window)
    line:SetPoint('TOPLEFT', window, 'TOPLEFT', 10, -18 - 32 * index)
    line:SetSize(535, 30)
    line:CreateBackdrop('Transparent')
    line:Hide()

    line.character = line:CreateFontString(nil, 'ARTWORK')
    line.character:ClearAllPoints()
    line.character:SetPoint('LEFT')
    line.character:SetSize(100, 30)
    line.character:FontTemplate(nil, 14)
    line.character:SetJustifyH('RIGHT')

    ---@class DoYouNeedThatLineFullItem: Frame
    ---@field itemLink string
    line.item = CreateFrame('Frame', nil, line)
    line.item:ClearAllPoints()
    line.item:SetPoint('LEFT', line.character, 'RIGHT', 5, 0)
    line.item:SetSize(200, 30)
    line.item:SetScript('OnEnter', ItemFrameOnEnter)
    line.item:SetScript('OnLeave', ItemFrameOnLeave)

    line.item.icon = line.item:CreateTexture(nil, 'ARTWORK')
    line.item.icon:SetSize(30, 30)
    line.item.icon:SetPoint('LEFT')
    line.item.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    line.item.icon:CreateBackdrop()

    line.item.ilvl = line.item:CreateFontString(nil, 'ARTWORK')
    line.item.ilvl:FontTemplate(nil, 14)
    line.item.ilvl:SetPoint('LEFT', line.item.icon, 'RIGHT', 5, 7.5)
    line.item.ilvl:SetHeight(15)
    line.item.ilvl:SetJustifyH('LEFT')

    line.item.tier = line.item:CreateFontString(nil, 'ARTWORK')
    line.item.tier:FontTemplate(nil, 14)
    line.item.tier:SetPoint('LEFT', line.item.ilvl, 'RIGHT', 1, 0)
    line.item.tier:SetHeight(15)
    line.item.tier:SetJustifyH('LEFT')

    line.item.name = line.item:CreateFontString(nil, 'ARTWORK')
    line.item.name:FontTemplate(nil, 14)
    line.item.name:SetPoint('LEFT', line.item.icon, 'RIGHT', 5, -7.5)
    line.item.name:SetSize(165, 15)
    line.item.name:SetJustifyH('LEFT')

    line.arrow = line:CreateTexture(nil, 'ARTWORK')
    line.arrow:ClearAllPoints()
    line.arrow:SetPoint('LEFT', line.item, 'RIGHT', 5, 0)
    line.arrow:SetSize(20, 20)
    line.arrow:SetTexture(E.Media.Textures.ArrowUp)
    line.arrow:SetRotation(-1.57)

    ---@class DoYouNeedThatLineItem: Frame
    ---@field itemLink string
    line.gearItem1 = CreateFrame('Frame', nil, line)
    line.gearItem1:ClearAllPoints()
    line.gearItem1:SetPoint('LEFT', line.arrow, 'RIGHT', 5, 0)
    line.gearItem1:SetSize(70, 30)
    line.gearItem1:SetScript('OnEnter', ItemFrameOnEnter)
    line.gearItem1:SetScript('OnLeave', ItemFrameOnLeave)

    line.gearItem1.icon = line.gearItem1:CreateTexture(nil, 'ARTWORK')
    line.gearItem1.icon:SetSize(30, 30)
    line.gearItem1.icon:SetPoint('LEFT')
    line.gearItem1.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    line.gearItem1.icon:CreateBackdrop()

    line.gearItem1.ilvl = line.gearItem1:CreateFontString(nil, 'ARTWORK')
    line.gearItem1.ilvl:FontTemplate(nil, 14)
    line.gearItem1.ilvl:SetPoint('LEFT', line.gearItem1.icon, 'RIGHT', 5, 7.5)
    line.gearItem1.ilvl:SetSize(35, 30)
    line.gearItem1.ilvl:SetJustifyH('LEFT')

    line.gearItem1.tier = line.gearItem1:CreateFontString(nil, 'ARTWORK')
    line.gearItem1.tier:FontTemplate(nil, 14)
    line.gearItem1.tier:SetPoint('LEFT', line.gearItem1.icon, 'RIGHT', 5, -7.5)
    line.gearItem1.tier:SetSize(35, 30)
    line.gearItem1.tier:SetJustifyH('LEFT')

    ---@class DoYouNeedThatLineItem: Frame
    line.gearItem2 = CreateFrame('Frame', nil, line)
    line.gearItem2:ClearAllPoints()
    line.gearItem2:SetPoint('LEFT', line.gearItem1, 'RIGHT', 5, 0)
    line.gearItem2:SetSize(70, 30)
    line.gearItem2:SetScript('OnEnter', ItemFrameOnEnter)
    line.gearItem2:SetScript('OnLeave', ItemFrameOnLeave)

    line.gearItem2.icon = line.gearItem2:CreateTexture(nil, 'ARTWORK')
    line.gearItem2.icon:SetSize(30, 30)
    line.gearItem2.icon:SetPoint('LEFT')
    line.gearItem2.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    line.gearItem2.icon:CreateBackdrop()

    line.gearItem2.ilvl = line.gearItem2:CreateFontString(nil, 'ARTWORK')
    line.gearItem2.ilvl:FontTemplate(nil, 14)
    line.gearItem2.ilvl:SetPoint('LEFT', line.gearItem2.icon, 'RIGHT', 5, 7.5)
    line.gearItem2.ilvl:SetSize(35, 30)
    line.gearItem2.ilvl:SetJustifyH('LEFT')

    line.gearItem2.tier = line.gearItem2:CreateFontString(nil, 'ARTWORK')
    line.gearItem2.tier:FontTemplate(nil, 14)
    line.gearItem2.tier:SetPoint('LEFT', line.gearItem2.icon, 'RIGHT', 5, -7.5)
    line.gearItem2.tier:SetSize(35, 30)
    line.gearItem2.tier:SetJustifyH('LEFT')

    ---@class DoYouNeedThatLineButton: Button
    ---@field itemRefName string
    ---@field playerFullName string
    line.button = CreateFrame('Button', nil, line)
    line.button:ClearAllPoints()
    line.button:SetPoint('LEFT', line.gearItem2, 'RIGHT', 5, 0)
    line.button:SetSize(50, 30)
    line.button:SetTemplate('Default')
    line.button:StyleButton()
    line.button:SetScript('OnClick', ButtonOnClick)

    line.button.text = line.button:CreateFontString(nil, 'ARTWORK')
    line.button.text:FontTemplate(nil, 14)
    line.button.text:SetPoint('CENTER')
    line.button.text:SetSize(50, 30)
    line.button.text:SetJustifyH('CENTER')

    tinsert(window.lines, line)
end

function DY:BuildFrame()
    ---@class DoYouNeedThatWindow: Frame
    local window = CreateFrame('Frame', nil, E.UIParent, 'BackdropTemplate')
    ---@type DoYouNeedThatLine[]
    window.lines = {}
    window.usingLines = 0

    window:SetTemplate('Transparent', true)
    window:SetFrameStrata('DIALOG')
    window:SetPoint('TOPLEFT', E.UIParent, 'CENTER', 200, 350)
    window:SetSize(555, 132)
    window:Hide()

    window:SetScript('OnHide', function()
        DY:ClearEntries()
    end)

    local closeButton = CreateFrame('Button', nil, window)
    closeButton:SetSize(32, 32)
    closeButton:SetPoint('TOPRIGHT', 1, 1)
    closeButton:SetScript('OnClick', function()
        window:Hide()
    end)
    S:HandleCloseButton(closeButton)

    local titleText = window:CreateFontString(nil, 'OVERLAY')
    titleText:FontTemplate(nil, 20)
    titleText:SetTextColor(1, 1, 1, 1)
    titleText:SetPoint('CENTER', window, 'TOP', 0, -25)
    titleText:SetJustifyH('CENTER')
    titleText:SetText("毛装助手")

    self.window = window

    -- defaults has two pre-build lines
    self:BuildEntryLine()
    self:BuildEntryLine()
end

function DY:Initialize()
    self.partyMember = {}

    self:BuildFrame()

    self:RegisterEvent('PLAYER_ENTERING_WORLD')
    self:RegisterEvent('ENCOUNTER_END', 'ClearEntries')
    self:RegisterEvent('CHALLENGE_MODE_COMPLETED', 'ClearEntries')
end

R:RegisterModule(DY:GetName())
