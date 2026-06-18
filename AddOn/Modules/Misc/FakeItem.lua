local R, E, L, V, P, G = unpack((select(2, ...)))
local FI = R:NewModule('FakeItem', 'AceEvent-3.0')
local TB = R:GetModule('Toolbox')
local S = E:GetModule('Skins')

-- Lua functions
local error, ipairs, pairs, tonumber, tostring = error, ipairs, pairs, tonumber, tostring
local string_format = string.format
local string_match = string.match
local string_split = string.split
local table_insert = table.insert
local table_remove = table.remove

-- WoW API / Variables
local C_ArtifactUI_GetAppearanceInfoByID = C_ArtifactUI.GetAppearanceInfoByID
local C_ChallengeMode_GetAffixInfo = C_ChallengeMode.GetAffixInfo
local C_ChallengeMode_GetMapUIInfo = C_ChallengeMode.GetMapUIInfo
local C_Item_GetItemNameByID = C_Item.GetItemNameByID
local C_Item_RequestLoadItemDataByID = C_Item.RequestLoadItemDataByID
local C_PetJournal_GetPetInfoBySpeciesID = C_PetJournal.GetPetInfoBySpeciesID
local C_TradeSkillUI_GetRecipeInfo = C_TradeSkillUI.GetRecipeInfo
local ClearCursor = ClearCursor
local CreateFrame = CreateFrame
local GetClassInfo = GetClassInfo
local GetCursorInfo = GetCursorInfo
local GetNumClasses = GetNumClasses
local GetSpecializationInfoByID = GetSpecializationInfoByID
local GetSpecializationInfoForClassID = GetSpecializationInfoForClassID

local ChatFrameUtil_LinkItem = ChatFrameUtil.LinkItem
local Item = Item
local MenuUtil_CreateContextMenu = MenuUtil.CreateContextMenu
local tContains = tContains

local Enum_ItemCreationContext = Enum.ItemCreationContext
local Enum_ItemModification = Enum.ItemModification

local ADD = ADD
local NONE = NONE
local REMOVE = REMOVE
local UNKNOWN = UNKNOWN

local function UpdatePreviewTooltip()
    local itemString = FI:ExportItemString()

    local window = FI.window
    local previewTooltip = window.previewTooltip

    previewTooltip:Hide()
    if not itemString then return end

    previewTooltip:SetOwner(window, 'ANCHOR_NONE')
    previewTooltip:SetPoint('TOPRIGHT', window, 'TOPLEFT', -1, 0)
    previewTooltip:ClearLines()
    previewTooltip:SetHyperlink(itemString)
    previewTooltip:Show()
end

---@class EditBoxWithDiscard: EditBox
---@field lastText string?

---@param self EditBoxWithDiscard
local function EditBoxOnEscapePressed(self)
    local text = self:GetText()
    if text ~= self.lastText then
        self:SetText(self.lastText)
    end

    self:ClearFocus()
end

---@param self EditBoxWithDiscard
local function EditBoxOnEnterPressed(self)
    -- checks will be in OnEditFocusLost

    self:ClearFocus()
end

---@param self EditBoxWithDiscard
local function EditBoxOnEditFocusGained(self)
    self.lastText = self:GetText()

    self:SetBackdropBorderColor(241 / 255, 209 / 255, 138 / 255, 1)
end

---@param self EditBoxWithDiscard
local function EditBoxOnEditFocusLost(self)
    self:SetBackdropBorderColor(0, 0, 0, 1)

    UpdatePreviewTooltip()
end

---@param self EditBoxWithDiscard
local function NumberEditBoxOnEditFocusLost(self)
    local text = self:GetText()
    if text ~= self.lastText then
        local match = string_match(text, '^%-?%d*$')
        if not match then
            self:SetText(self.lastText)
        end
    end

    EditBoxOnEditFocusLost(self)
end

---@param self EditBoxWithDiscard
local function NumberEditBoxOnTextChanged(self)
    local text = self:GetText()
    local match = string_match(text, '^%-?%d*$')
    if match then
        self:SetBackdropBorderColor(241 / 255, 209 / 255, 138 / 255, 1)
    else
        self:SetBackdropBorderColor(247 / 255, 56 / 255, 89 / 255, 1)
    end
end

---@class ItemPayloadValueDefineItemName
---@field type 'item'
---@field itemList number[]

---@class ItemPayloadValueDefineListNoteLeaf
---@field type 'leaf'
---@field value number
---@field name string
---@field color ColorMixin?

---@class ItemPayloadValueDefineListNoteBranch
---@field type 'branch'
---@field name string
---@field color ColorMixin?
---@field children ItemPayloadValueDefineListNoteLeaf[]

---@class ItemPayloadValueDefineCustom
---@field type 'custom'
---@field display fun(value: number): string?

---@alias ItemPayloadValueDefineListNote ItemPayloadValueDefineListNoteLeaf | ItemPayloadValueDefineListNoteBranch

---@class ItemPayloadValueDefineList
---@field type 'list'
---@field notes ItemPayloadValueDefineListNote[]
---@field display table<number, string>

---@alias ItemPayloadValueDefine ItemPayloadValueDefineItemName | ItemPayloadValueDefineList | ItemPayloadValueDefineCustom

---@type ItemPayloadValueDefineItemName
local emptyItemIDDefine = {
    type = 'item',
    itemList = {},
}

---@type ItemPayloadValueDefineList
local enchantIDDefine = {
    type = 'list',
    notes = {
        -- TODO: enchant list from InfoItemLevel
    },
    display = {}, -- TODO: enchant names
}

---@type ItemPayloadValueDefineItemName
local gemIDDefine = {
    type = 'item',
    itemList = {
        -- TODO: gem list, maybe should support branch and leaf
    },
}

---@type ItemPayloadValueDefineCustom
local battlePetSpeciesDefine = {
    type = 'custom',
    display = function(value)
        local speciesName = C_PetJournal_GetPetInfoBySpeciesID(value)
        return speciesName
    end,
}

---@type ItemPayloadValueDefineCustom
local artifactAppearanceIDDefine = {
    type = 'custom',
    display = function(value)
        local _, _, appearanceName = C_ArtifactUI_GetAppearanceInfoByID(value)
        return appearanceName
    end,
}

---@type ItemPayloadValueDefineCustom
local keystoneMapChallengeModeIDDefine = {
    type = 'custom',
    display = function(value)
        local name = C_ChallengeMode_GetMapUIInfo(value)
        return name
    end,
}

---@type ItemPayloadValueDefineCustom
local keystoneAffixDefine = {
    type = 'custom',
    display = function(value)
        local name = C_ChallengeMode_GetAffixInfo(value)
        return name
    end,
}

---@type ItemPayloadValueDefineCustom
local craftingSkillLineAbilityIDDefine = {
    type = 'custom',
    display = function(value)
        local recipeInfo = C_TradeSkillUI_GetRecipeInfo(value)
        return recipeInfo and recipeInfo.name
    end,
}

---@type ItemPayloadValueDefineList
local bonusIDDefine = {
    type = 'list',
    notes = {
        {
            type = 'branch',
            name = '额外属性',
            children = {
                {
                    type = 'leaf',
                    value = 40,
                    name = STAT_AVOIDANCE,
                },
                {
                    type = 'leaf',
                    value = 41,
                    name = STAT_LIFESTEAL,
                },
                {
                    type = 'leaf',
                    value = 42,
                    name = STAT_HASTE,
                },
                {
                    type = 'leaf',
                    value = 43,
                    name = STAT_STURDINESS,
                },
                {
                    type = 'leaf',
                    value = 13534,
                    name = EMPTY_SOCKET_PRISMATIC,
                },
                {
                    type = 'leaf',
                    value = 13668,
                    name = EMPTY_SOCKET_PRISMATIC,
                },
            },
        },
        -- TODO: item upgrade from CrestAchievement
    },
    display = {}, -- TODO: bonus names
}

---@class ItemStringPayloadData
---@field type 'string'
---@field name string

---@class ItemNumberPayloadData
---@field type 'number'
---@field name string
---@field define ItemPayloadValueDefine?

---@class ItemListPayloadData
---@field type 'list'
---@field name string
---@field define ItemPayloadValueDefine?

---@class ItemPairListPayloadData
---@field type 'pairList'
---@field name string
---@field keyDefine ItemPayloadValueDefine?
---@field valueDefine table<number, ItemPayloadValueDefine>?

---@alias ItemPayloadData ItemStringPayloadData | ItemNumberPayloadData | ItemListPayloadData | ItemPairListPayloadData

---@type ItemPayloadData[]
local itemPayloads = {
    {
        type = 'number',
        name = 'itemID',
        define = {
            type = 'item',
            itemList = {},
        },
    },
    {
        type = 'number',
        name = 'enchantID',
        define = enchantIDDefine,
    },
    {
        type = 'number',
        name = 'gemID1',
        define = gemIDDefine,
    },
    {
        type = 'number',
        name = 'gemID2',
        define = gemIDDefine,
    },
    {
        type = 'number',
        name = 'gemID3',
        define = gemIDDefine,
    },
    {
        type = 'number',
        name = 'gemID4',
        define = gemIDDefine,
    },
    {
        type = 'number',
        name = 'suffixID',
    },
    {
        type = 'number',
        name = 'uniqueID',
    },
    {
        type = 'number',
        name = 'linkLevel',
    },
    {
        type = 'number',
        name = 'specializationID',
        define = {
            type = 'list',
            notes = {},
            display = {},
        },
    },
    {
        type = 'number',
        name = 'modifiersMask',
    },
    {
        type = 'number',
        name = 'itemContext',
        define = {
            type = 'list',
            notes = {},
            display = {},
        },
    },
    {
        type = 'list',
        name = 'bonusIDs',
        define = bonusIDDefine,
    },
    {
        type = 'pairList',
        name = 'modifiers',
        keyDefine = {
            type = 'list',
            notes = {},
            display = {},
        },
        valueDefine = {
            [Enum.ItemModification.BattlePetSpecies] = battlePetSpeciesDefine,
            [Enum.ItemModification.ArtifactAppearanceID] = artifactAppearanceIDDefine,
            [Enum.ItemModification.KeystoneMapChallengeModeID] = keystoneMapChallengeModeIDDefine,
            [Enum.ItemModification.KeystoneAffix0] = keystoneAffixDefine,
            [Enum.ItemModification.KeystoneAffix01] = keystoneAffixDefine,
            [Enum.ItemModification.KeystoneAffix02] = keystoneAffixDefine,
            [Enum.ItemModification.KeystoneAffix03] = keystoneAffixDefine,
            [Enum.ItemModification.CraftingSkillLineAbilityID] = craftingSkillLineAbilityIDDefine,
            [Enum.ItemModification.CraftingReagentSlot_0] = emptyItemIDDefine,
            [Enum.ItemModification.CraftingReagentSlot_1] = emptyItemIDDefine,
            [Enum.ItemModification.CraftingReagentSlot_2] = emptyItemIDDefine,
            [Enum.ItemModification.CraftingReagentSlot_3] = emptyItemIDDefine,
            [Enum.ItemModification.CraftingReagentSlot_4] = emptyItemIDDefine,
            [Enum.ItemModification.CraftingReagentSlot_5] = emptyItemIDDefine,
            [Enum.ItemModification.CraftingReagentSlot_6] = emptyItemIDDefine,
            [Enum.ItemModification.CraftingReagentSlot_7] = emptyItemIDDefine,
            [Enum.ItemModification.CraftingReagentSlot_8] = emptyItemIDDefine,
            [Enum.ItemModification.CraftingReagentSlot_9] = emptyItemIDDefine,
            [Enum.ItemModification.CraftingReagentSlot_10] = emptyItemIDDefine,
            [Enum.ItemModification.CraftingReagentSlot_11] = emptyItemIDDefine,
            [Enum.ItemModification.CraftingReagentSlot_12] = emptyItemIDDefine,
            [Enum.ItemModification.CraftingReagentSlot_13] = emptyItemIDDefine,
            [Enum.ItemModification.CraftingReagentSlot_14] = emptyItemIDDefine,
        },
    },
    {
        type = 'list',
        name = 'relic1BonusIDs',
        define = bonusIDDefine,
    },
    {
        type = 'list',
        name = 'relic2BonusIDs',
        define = bonusIDDefine,
    },
    {
        type = 'list',
        name = 'relic3BonusIDs',
        define = bonusIDDefine,
    },
    {
        type = 'string',
        name = 'crafterGUID',
    },
    {
        type = 'number',
        name = 'extraEnchantID',
        define = enchantIDDefine,
    },
}

---@param define ItemPayloadValueDefine
---@param editBox EditBoxWithDiscard
---@param menuButton Button
local function UpdateMenuButtonText(define, editBox, menuButton)
    local value = tonumber(editBox:GetText())
    if not value then
        menuButton:SetText(NONE)
        return
    end

    if define.type == 'item' then
        if value > 0 then
            local itemName = C_Item_GetItemNameByID(value)
            if itemName then
                menuButton:SetText(itemName)
            else
                ---@diagnostic disable-next-line: param-type-mismatch
                menuButton:SetText(value)

                local item = Item:CreateFromItemID(value)
                item:ContinueOnItemLoad(function()
                    local currValue = tonumber(editBox:GetText())
                    if currValue == value then
                        menuButton:SetText(item:GetItemName())
                    end
                end)
            end
        else
            ---@diagnostic disable-next-line: param-type-mismatch
            menuButton:SetText(value)
        end
    elseif define.type == 'list' then
        menuButton:SetText(define.display[value] or UNKNOWN)
    elseif define.type == 'custom' then
        menuButton:SetText(define.display(value) or UNKNOWN)
    else
        menuButton:SetText(UNKNOWN)
    end
end

---@param define ItemPayloadValueDefine
---@param editBox EditBoxWithDiscard
---@param menuButton Button
local function BuildMenuButtonMenu(define, editBox, menuButton)
    local currValue = tonumber(editBox:GetText())

    ---@param data ItemPayloadValueDefineListNoteBranch
    ---@return boolean
    local function IsTextBranch(data)
        if not currValue then return false end

        for _, leaf in ipairs(data.children) do
            if leaf.value == currValue then
                return true
            end
        end

        return false
    end

    local function SetTextBranch()
        -- dummy
    end

    ---@param value number
    ---@return boolean
    local function IsText(value)
        return currValue == value
    end

    ---@param value number
    local function SetText(value)
        ---@diagnostic disable-next-line: param-type-mismatch
        editBox:SetText(value)
        UpdatePreviewTooltip()
    end

    ---@param rootDescription RootMenuDescriptionProxy
    local function MenuGenerator(_, rootDescription)
        if define.type == 'item' then
            for _, itemID in ipairs(define.itemList) do
                local itemName = C_Item_GetItemNameByID(itemID)
                local text = string_format('%s (%d)', itemName or itemID, itemID)

                rootDescription:CreateRadio(text, IsText, SetText, itemID)
            end
        elseif define.type == 'list' then
            for _, note in ipairs(define.notes) do
                if note.type == 'leaf' then
                    local text = string_format('%s (%d)', note.name, note.value)
                    if note.color then
                        text = note.color:WrapTextInColorCode(text)
                    end

                    rootDescription:CreateRadio(text, IsText, SetText, note.value)
                elseif note.type == 'branch' then
                    local branchText = note.name
                    if note.color then
                        branchText = note.color:WrapTextInColorCode(branchText)
                    end

                    local branch = rootDescription:CreateRadio(branchText, IsTextBranch, SetTextBranch, note)
                    for _, leaf in ipairs(note.children) do
                        local leafText = string_format('%s (%d)', leaf.name, leaf.value)
                        if leaf.color then
                            leafText = leaf.color:WrapTextInColorCode(leafText)
                        end

                        branch:CreateRadio(leafText, IsText, SetText, leaf.value)
                    end
                end
            end
        end
    end

    MenuUtil_CreateContextMenu(menuButton, MenuGenerator)
end

---@return string?
function FI:ExportItemString()
    local itemID = tonumber(self.window.payloads[1]:GetValue())
    if not itemID then return end

    local itemList = itemPayloads[1].define.itemList
    if not tContains(itemList, itemID) then
        table_insert(itemList, itemID)

        if #itemList > 10 then
            table_remove(itemList, 1)
        end
    end

    local itemString = 'item'

    for _, row in ipairs(self.window.payloads) do
        itemString = itemString .. ':' .. row:GetValue()
    end

    return itemString
end

---@param itemString string
function FI:HandleItemString(itemString)
    local payloadText = string_match(itemString, 'item:(%d+:[^|]*)')
    if not payloadText then return end

    for _, row in ipairs(self.window.payloads) do
        payloadText = row:SetValue(payloadText)
    end

    UpdatePreviewTooltip()
end

do
    ---@class FakeItemWindowPairListPayloadChildRow: Frame
    ---@field index number
    ---@field removeButton Button
    ---@field using CheckButton
    ---@field label FontString
    ---@field keyEditBox EditBoxWithDiscard
    ---@field valueEditBox EditBoxWithDiscard
    ---@field keyMenuButton Button?
    ---@field valueMenuButton Button?
    ---@field Reset fun(self: FakeItemWindowPairListPayloadChildRow)

    ---@class FakeItemWindowPairListPayloadRow: FakeItemWindowPayloadRow
    ---@field data ItemPairListPayloadData
    ---@field label FontString
    ---@field count FontString
    ---@field addButton Button
    ---@field children FakeItemWindowPairListPayloadChildRow[]
    ---@field UpdateLayout fun(self: FakeItemWindowPairListPayloadRow)

    ---@param self FakeItemWindowPairListPayloadChildRow
    local function Reset(self)
        self.using:SetChecked(true)
        self.keyEditBox:SetText('')
        self.valueEditBox:SetText('')
    end

    ---@param self Button
    local function RemoveButtonOnClick(self)
        ---@type FakeItemWindowPairListPayloadChildRow
        local row = self:GetParent()
        ---@type FakeItemWindowPairListPayloadRow
        local parent = row:GetParent()

        local rowIndex = row.index
        local lastRow = row

        for i = rowIndex + 1, #parent.children do
            local child = parent.children[i]
            if not child:IsShown() then break end

            local prev = parent.children[i - 1]
            prev.using:SetChecked(child.using:GetChecked())
            prev.keyEditBox:SetText(child.keyEditBox:GetText())
            prev.valueEditBox:SetText(child.valueEditBox:GetText())

            lastRow = child
        end

        lastRow:Hide()
        parent:UpdateLayout()
        UpdatePreviewTooltip()
    end

    ---@param self CheckButton
    local function CheckBoxOnClick(self)
        ---@type FakeItemWindowPairListPayloadRow
        local parent = self:GetParent():GetParent()
        parent:UpdateLayout()
        UpdatePreviewTooltip()
    end

    ---@param self EditBoxWithDiscard
    ---@param userInput boolean
    local function KeyOnTextChanged(self, userInput)
        if userInput then
            NumberEditBoxOnTextChanged(self)
        end

        ---@type FakeItemWindowPairListPayloadChildRow
        local row = self:GetParent()

        ---@type FakeItemWindowPairListPayloadRow
        local parent = row:GetParent()

        if row.keyMenuButton then
            ---@type ItemPayloadValueDefine
            local define = parent.data.keyDefine

            UpdateMenuButtonText(define, self, row.keyMenuButton)
        end

        if row.valueMenuButton then
            ---@type table<number, ItemPayloadValueDefine>
            local define = parent.data.valueDefine

            local keyValue = tonumber(row.keyEditBox:GetText())
            if keyValue and define[keyValue] then
                UpdateMenuButtonText(define[keyValue], row.valueEditBox, row.valueMenuButton)
            else
                row.valueMenuButton:SetText(UNKNOWN)
            end
        end
    end

    ---@param self EditBoxWithDiscard
    ---@param userInput boolean
    local function ValueOnTextChanged(self, userInput)
        if userInput then
            NumberEditBoxOnTextChanged(self)
        end

        ---@type FakeItemWindowPairListPayloadChildRow
        local row = self:GetParent()

        if row.valueMenuButton then
            ---@type FakeItemWindowPairListPayloadRow
            local parent = row:GetParent()

            ---@type table<number, ItemPayloadValueDefine>
            local define = parent.data.valueDefine

            local keyValue = tonumber(row.keyEditBox:GetText())
            if keyValue and define[keyValue] then
                UpdateMenuButtonText(define[keyValue], self, row.valueMenuButton)
            else
                row.valueMenuButton:SetText(UNKNOWN)
            end
        end
    end

    ---@param self Button
    local function KeyMenuButtonOnClick(self)
        ---@type FakeItemWindowPairListPayloadChildRow
        local row = self:GetParent()

        ---@type FakeItemWindowPairListPayloadRow
        local parent = row:GetParent()

        ---@type ItemPayloadValueDefine
        local define = parent.data.keyDefine

        BuildMenuButtonMenu(define, row.keyEditBox, self)
    end

    ---@param self Button
    local function ValueMenuButtonOnClick(self)
        ---@type FakeItemWindowPairListPayloadChildRow
        local row = self:GetParent()

        ---@type FakeItemWindowPairListPayloadRow
        local parent = row:GetParent()

        ---@type table<number, ItemPayloadValueDefine>
        local define = parent.data.valueDefine

        local keyValue = tonumber(row.keyEditBox:GetText())
        if keyValue and define[keyValue] then
            BuildMenuButtonMenu(define[keyValue], row.valueEditBox, self)
        end
    end

    ---@param parent FakeItemWindowPairListPayloadRow
    ---@param index number
    ---@return FakeItemWindowPairListPayloadChildRow
    local function BuildChildRow(parent, index)
        ---@type FakeItemWindowPairListPayloadChildRow
        local row = CreateFrame('Frame', nil, parent)
        row:SetSize(480, 49)
        row:SetPoint('TOP', parent, 'TOP', 0, -26 - 51 * (index - 1))

        row.removeButton = CreateFrame('Button', nil, row, 'UIPanelButtonTemplate')
        row.removeButton:SetSize(61, 24)
        row.removeButton:SetPoint('TOPLEFT', row, 'TOPLEFT', 3, 0)
        row.removeButton:SetText(REMOVE)
        row.removeButton:SetScript('OnClick', RemoveButtonOnClick)
        S:HandleButton(row.removeButton)

        row.using = CreateFrame('CheckButton', nil, row)
        row.using:SetSize(24, 24)
        row.using:SetPoint('LEFT', row.removeButton, 'RIGHT', 2, 0)
        row.using:SetChecked(true)
        row.using:SetScript('OnClick', CheckBoxOnClick)
        S:HandleCheckBox(row.using)

        row.label = row:CreateFontString(nil, 'ARTWORK')
        row.label:SetSize(61, 24)
        row.label:SetPoint('LEFT', row.using, 'RIGHT', 2, 0)
        row.label:FontTemplate(nil, 14)
        row.label:SetTextColor(1, 1, 1)
        row.label:SetJustifyH('LEFT')
        row.label:SetJustifyV('MIDDLE')

        row.keyEditBox = CreateFrame('EditBox', nil, row)
        row.keyEditBox:SetSize(parent.data.keyDefine and 80 or 322, 24)
        row.keyEditBox:SetPoint('LEFT', row.label, 'RIGHT', 2, 0)
        row.keyEditBox:SetTemplate('Default')
        row.keyEditBox:SetAutoFocus(false)
        row.keyEditBox:SetFontObject('ChatFontNormal')
        row.keyEditBox:SetScript('OnEscapePressed', EditBoxOnEscapePressed)
        row.keyEditBox:SetScript('OnEnterPressed', EditBoxOnEnterPressed)
        row.keyEditBox:SetScript('OnEditFocusGained', EditBoxOnEditFocusGained)
        row.keyEditBox:SetScript('OnEditFocusLost', NumberEditBoxOnEditFocusLost)
        row.keyEditBox:SetScript('OnTextChanged', KeyOnTextChanged)

        if parent.data.keyDefine then
            row.keyMenuButton = CreateFrame('Button', nil, row, 'UIPanelButtonTemplate')
            row.keyMenuButton:SetSize(240, 24)
            row.keyMenuButton:SetPoint('TOPRIGHT', row, 'TOPRIGHT', -3, 0)
            row.keyMenuButton:SetText(UNKNOWN)
            row.keyMenuButton:SetScript('OnClick', KeyMenuButtonOnClick)
            S:HandleButton(row.keyMenuButton)
        end

        row.valueEditBox = CreateFrame('EditBox', nil, row)
        row.valueEditBox:SetSize(parent.data.valueDefine and 80 or 322, 24)
        row.valueEditBox:SetPoint('TOPLEFT', row.keyEditBox, 'BOTTOMLEFT', 0, -1)
        row.valueEditBox:SetTemplate('Default')
        row.valueEditBox:SetAutoFocus(false)
        row.valueEditBox:SetFontObject('ChatFontNormal')
        row.valueEditBox:SetScript('OnEscapePressed', EditBoxOnEscapePressed)
        row.valueEditBox:SetScript('OnEnterPressed', EditBoxOnEnterPressed)
        row.valueEditBox:SetScript('OnEditFocusGained', EditBoxOnEditFocusGained)
        row.valueEditBox:SetScript('OnEditFocusLost', NumberEditBoxOnEditFocusLost)
        row.valueEditBox:SetScript('OnTextChanged', ValueOnTextChanged)

        if parent.data.valueDefine then
            row.valueMenuButton = CreateFrame('Button', nil, row, 'UIPanelButtonTemplate')
            row.valueMenuButton:SetSize(240, 24)
            row.valueMenuButton:SetPoint('TOPLEFT', row.keyMenuButton, 'BOTTOMLEFT', 0, -1)
            row.valueMenuButton:SetText(UNKNOWN)
            row.valueMenuButton:SetScript('OnClick', ValueMenuButtonOnClick)
            S:HandleButton(row.valueMenuButton)
        end

        row.index = index

        row.Reset = Reset

        return row
    end

    ---@param self FakeItemWindowPairListPayloadRow
    ---@return string
    local function GetValue(self)
        local count = 0
        local result = ''

        for _, child in ipairs(self.children) do
            if not child:IsShown() then break end

            if child.using:GetChecked() then
                local keyText = child.keyEditBox:GetText()
                keyText = #keyText > 0 and keyText or '0'

                local valueText = child.valueEditBox:GetText()
                valueText = #valueText > 0 and valueText or '0'

                count = count + 1
                result = result .. ':' .. keyText .. ':' .. valueText
            end
        end

        if count == 0 then
            return ''
        end

        return count .. result
    end

    ---@param self FakeItemWindowPairListPayloadRow
    ---@param value string
    ---@return string
    local function SetValue(self, value)
        local numText, remain = string_split(':', value, 2)
        local num = tonumber(#numText > 0 and numText or '0')
        local result = { string_split(':', remain or '', num * 2 + 1) }
        local count = #self.children

        for i = 1, num do
            if i <= count then
                local child = self.children[i]
                child:Reset()

                child.keyEditBox:SetText(result[i * 2 - 1])
                child.valueEditBox:SetText(result[i * 2])

                child:Show()
            else
                local child = BuildChildRow(self, i)

                child.keyEditBox:SetText(result[i * 2 - 1])
                child.valueEditBox:SetText(result[i * 2])

                table_insert(self.children, child)
            end
        end

        for i = num + 1, count do
            self.children[i]:Hide()
        end

        self:UpdateLayout()

        return result[num * 2 + 1]
    end

    ---@param self FakeItemWindowPairListPayloadRow
    local function UpdateLayout(self)
        local count = 0
        local height = 24

        for _, child in ipairs(self.children) do
            if not child:IsShown() then break end

            height = height + 51 -- 49 + 2

            if child.using:GetChecked() then
                count = count + 1
                child.label:SetText(tostring(count))
            else
                child.label:SetText('')
            end
        end

        self.count:SetText(tostring(count))
        self:SetHeight(height)

        FI:UpdateWindowLayout()
    end

    ---@param self Button
    local function AddButtonOnClick(self)
        ---@type FakeItemWindowPairListPayloadRow
        local parent = self:GetParent()

        for _, child in ipairs(parent.children) do
            if not child:IsShown() then
                child:Reset()
                child:Show()

                parent:UpdateLayout()
                UpdatePreviewTooltip()
                return
            end
        end

        local child = BuildChildRow(parent, #parent.children + 1)
        table_insert(parent.children, child)
        parent:UpdateLayout()
        UpdatePreviewTooltip()
    end

    ---@param parent FakeItemWindow
    ---@param payloadData ItemPairListPayloadData
    ---@return FakeItemWindowPairListPayloadRow
    function FI:BuildPairListPayloadRow(parent, payloadData)
        ---@type FakeItemWindowPairListPayloadRow
        local row = CreateFrame('Frame', nil, parent)
        row:SetSize(480, 24)

        row.label = row:CreateFontString(nil, 'ARTWORK')
        row.label:SetSize(150, 24)
        row.label:SetPoint('TOPLEFT', row, 'TOPLEFT', 3, 0)
        row.label:FontTemplate(nil, 14)
        row.label:SetTextColor(1, 1, 1)
        row.label:SetJustifyH('LEFT')
        row.label:SetJustifyV('MIDDLE')
        row.label:SetText(payloadData.name)

        row.count = row:CreateFontString(nil, 'ARTWORK')
        row.count:SetSize(80, 24)
        row.count:SetPoint('TOPLEFT', row.label, 'TOPRIGHT', 2, 0)
        row.count:FontTemplate(nil, 14)
        row.count:SetTextColor(1, 1, 1)
        row.count:SetJustifyH('LEFT')
        row.count:SetJustifyV('MIDDLE')
        row.count:SetText('0')

        row.addButton = CreateFrame('Button', nil, row, 'UIPanelButtonTemplate')
        row.addButton:SetSize(240, 24)
        row.addButton:SetPoint('TOPRIGHT', row, 'TOPRIGHT', -3, 0)
        row.addButton:SetText(ADD)
        row.addButton:SetScript('OnClick', AddButtonOnClick)
        S:HandleButton(row.addButton)

        row.children = {}

        row.GetValue = GetValue
        row.SetValue = SetValue
        row.UpdateLayout = UpdateLayout

        row.data = payloadData

        return row
    end
end

do
    ---@class FakeItemWindowListPayloadChildRow: Frame
    ---@field index number
    ---@field removeButton Button
    ---@field using CheckButton
    ---@field label FontString
    ---@field editBox EditBoxWithDiscard
    ---@field menuButton Button?
    ---@field Reset fun(self: FakeItemWindowListPayloadChildRow)

    ---@class FakeItemWindowListPayloadRow: FakeItemWindowPayloadRow
    ---@field data ItemListPayloadData
    ---@field label FontString
    ---@field count FontString
    ---@field addButton Button
    ---@field children FakeItemWindowListPayloadChildRow[]
    ---@field UpdateLayout fun(self: FakeItemWindowListPayloadRow)

    ---@param self FakeItemWindowListPayloadChildRow
    local function Reset(self)
        self.using:SetChecked(true)
        self.editBox:SetText('')
    end

    ---@param self Button
    local function RemoveButtonOnClick(self)
        ---@type FakeItemWindowListPayloadChildRow
        local row = self:GetParent()
        ---@type FakeItemWindowListPayloadRow
        local parent = row:GetParent()

        local rowIndex = row.index
        local lastRow = row

        for i = rowIndex + 1, #parent.children do
            local child = parent.children[i]
            if not child:IsShown() then break end

            local prev = parent.children[i - 1]
            prev.using:SetChecked(child.using:GetChecked())
            prev.editBox:SetText(child.editBox:GetText())

            lastRow = child
        end

        lastRow:Hide()
        parent:UpdateLayout()
        UpdatePreviewTooltip()
    end

    ---@param self CheckButton
    local function CheckBoxOnClick(self)
        ---@type FakeItemWindowListPayloadRow
        local parent = self:GetParent():GetParent()
        parent:UpdateLayout()
        UpdatePreviewTooltip()
    end

    ---@param self EditBoxWithDiscard
    ---@param userInput boolean
    local function OnTextChanged(self, userInput)
        if userInput then
            NumberEditBoxOnTextChanged(self)
        end

        ---@type FakeItemWindowListPayloadChildRow
        local row = self:GetParent()

        if row.menuButton then
            ---@type FakeItemWindowListPayloadRow
            local parent = row:GetParent()

            ---@type ItemPayloadValueDefine
            local define = parent.data.define

            UpdateMenuButtonText(define, self, row.menuButton)
        end
    end

    ---@param self Button
    local function MenuButtonOnClick(self)
        ---@type FakeItemWindowListPayloadChildRow
        local row = self:GetParent()

        ---@type FakeItemWindowListPayloadRow
        local parent = row:GetParent()

        ---@type ItemPayloadValueDefine
        local define = parent.data.define

        BuildMenuButtonMenu(define, row.editBox, self)
    end

    ---@param parent FakeItemWindowListPayloadRow
    ---@param index number
    ---@return FakeItemWindowListPayloadChildRow
    local function BuildChildRow(parent, index)
        ---@type FakeItemWindowListPayloadChildRow
        local row = CreateFrame('Frame', nil, parent)
        row:SetSize(480, 24)
        row:SetPoint('TOP', parent, 'TOP', 0, -26 * index)

        row.removeButton = CreateFrame('Button', nil, row, 'UIPanelButtonTemplate')
        row.removeButton:SetSize(61, 24)
        row.removeButton:SetPoint('LEFT', row, 'LEFT', 3, 0)
        row.removeButton:SetText(REMOVE)
        row.removeButton:SetScript('OnClick', RemoveButtonOnClick)
        S:HandleButton(row.removeButton)

        row.using = CreateFrame('CheckButton', nil, row)
        row.using:SetSize(24, 24)
        row.using:SetPoint('LEFT', row.removeButton, 'RIGHT', 2, 0)
        row.using:SetChecked(true)
        row.using:SetScript('OnClick', CheckBoxOnClick)
        S:HandleCheckBox(row.using)

        row.label = row:CreateFontString(nil, 'ARTWORK')
        row.label:SetSize(61, 24)
        row.label:SetPoint('LEFT', row.using, 'RIGHT', 2, 0)
        row.label:FontTemplate(nil, 14)
        row.label:SetTextColor(1, 1, 1)
        row.label:SetJustifyH('LEFT')
        row.label:SetJustifyV('MIDDLE')

        row.editBox = CreateFrame('EditBox', nil, row)
        row.editBox:SetSize(parent.data.define and 80 or 322, 24)
        row.editBox:SetPoint('LEFT', row.label, 'RIGHT', 2, 0)
        row.editBox:SetTemplate('Default')
        row.editBox:SetAutoFocus(false)
        row.editBox:SetFontObject('ChatFontNormal')
        row.editBox:SetScript('OnEscapePressed', EditBoxOnEscapePressed)
        row.editBox:SetScript('OnEnterPressed', EditBoxOnEnterPressed)
        row.editBox:SetScript('OnEditFocusGained', EditBoxOnEditFocusGained)
        row.editBox:SetScript('OnEditFocusLost', NumberEditBoxOnEditFocusLost)
        row.editBox:SetScript('OnTextChanged', OnTextChanged)

        if parent.data.define then
            row.menuButton = CreateFrame('Button', nil, row, 'UIPanelButtonTemplate')
            row.menuButton:SetSize(240, 24)
            row.menuButton:SetPoint('RIGHT', row, 'RIGHT', -3, 0)
            row.menuButton:SetText(UNKNOWN)
            row.menuButton:SetScript('OnClick', MenuButtonOnClick)
            S:HandleButton(row.menuButton)
        end

        row.index = index

        row.Reset = Reset

        return row
    end

    ---@param self FakeItemWindowListPayloadRow
    ---@return string
    local function GetValue(self)
        local count = 0
        local result = ''

        for _, child in ipairs(self.children) do
            if not child:IsShown() then break end

            if child.using:GetChecked() then
                local text = child.editBox:GetText()

                count = count + 1
                result = result .. ':' .. (#text > 0 and text or '0')
            end
        end

        if count == 0 then
            return ''
        end

        return count .. result
    end

    ---@param self FakeItemWindowListPayloadRow
    ---@param value string
    ---@return string
    local function SetValue(self, value)
        local numText, remain = string_split(':', value, 2)
        local num = tonumber(#numText > 0 and numText or '0')
        local result = { string_split(':', remain or '', num + 1) }
        local count = #self.children

        for i = 1, num do
            if i <= count then
                local child = self.children[i]
                child:Reset()

                child.editBox:SetText(result[i])

                child:Show()
            else
                local child = BuildChildRow(self, i)

                child.editBox:SetText(result[i])

                table_insert(self.children, child)
            end
        end

        for i = num + 1, count do
            self.children[i]:Hide()
        end

        self:UpdateLayout()

        return result[num + 1]
    end

    ---@param self FakeItemWindowListPayloadRow
    local function UpdateLayout(self)
        local count = 0
        local height = 24

        for _, child in ipairs(self.children) do
            if not child:IsShown() then break end

            height = height + 26 -- 24 + 2

            if child.using:GetChecked() then
                count = count + 1
                child.label:SetText(tostring(count))
            else
                child.label:SetText('')
            end
        end

        self.count:SetText(tostring(count))
        self:SetHeight(height)

        FI:UpdateWindowLayout()
    end

    ---@param self Button
    local function AddButtonOnClick(self)
        ---@type FakeItemWindowListPayloadRow
        local parent = self:GetParent()

        for _, child in ipairs(parent.children) do
            if not child:IsShown() then
                child:Reset()
                child:Show()

                parent:UpdateLayout()
                UpdatePreviewTooltip()
                return
            end
        end

        local child = BuildChildRow(parent, #parent.children + 1)
        table_insert(parent.children, child)
        parent:UpdateLayout()
        UpdatePreviewTooltip()
    end

    ---@param parent FakeItemWindow
    ---@param payloadData ItemListPayloadData
    ---@return FakeItemWindowListPayloadRow
    function FI:BuildListPayloadRow(parent, payloadData)
        ---@type FakeItemWindowListPayloadRow
        local row = CreateFrame('Frame', nil, parent)
        row:SetSize(480, 24)

        row.label = row:CreateFontString(nil, 'ARTWORK')
        row.label:SetSize(150, 24)
        row.label:SetPoint('TOPLEFT', row, 'TOPLEFT', 3, 0)
        row.label:FontTemplate(nil, 14)
        row.label:SetTextColor(1, 1, 1)
        row.label:SetJustifyH('LEFT')
        row.label:SetJustifyV('MIDDLE')
        row.label:SetText(payloadData.name)

        row.count = row:CreateFontString(nil, 'ARTWORK')
        row.count:SetSize(80, 24)
        row.count:SetPoint('TOPLEFT', row.label, 'TOPRIGHT', 2, 0)
        row.count:FontTemplate(nil, 14)
        row.count:SetTextColor(1, 1, 1)
        row.count:SetJustifyH('LEFT')
        row.count:SetJustifyV('MIDDLE')
        row.count:SetText('0')

        row.addButton = CreateFrame('Button', nil, row, 'UIPanelButtonTemplate')
        row.addButton:SetSize(240, 24)
        row.addButton:SetPoint('TOPRIGHT', row, 'TOPRIGHT', -3, 0)
        row.addButton:SetText(ADD)
        row.addButton:SetScript('OnClick', AddButtonOnClick)
        S:HandleButton(row.addButton)

        row.children = {}

        row.GetValue = GetValue
        row.SetValue = SetValue
        row.UpdateLayout = UpdateLayout

        row.data = payloadData

        return row
    end
end

do
    ---@class FakeItemWindowNumberPayloadRow: FakeItemWindowPayloadRow
    ---@field data ItemNumberPayloadData
    ---@field label FontString
    ---@field editBox EditBoxWithDiscard
    ---@field menuButton Button?

    ---@param self FakeItemWindowNumberPayloadRow
    ---@return string
    local function GetValue(self)
        local text = self.editBox:GetText()
        if #text <= 0 then
            return ''
        end

        local value = tonumber(text)
        return value > 0 and text or ''
    end

    ---@param self FakeItemWindowNumberPayloadRow
    ---@param value string
    ---@return string
    local function SetValue(self, value)
        local text, remain = string_split(':', value, 2)

        self.editBox:SetText(text)

        return remain
    end

    ---@param self EditBoxWithDiscard
    ---@param userInput boolean
    local function OnTextChanged(self, userInput)
        if userInput then
            NumberEditBoxOnTextChanged(self)
        end

        ---@type FakeItemWindowNumberPayloadRow
        local parent = self:GetParent()

        if parent.menuButton then
            ---@type ItemPayloadValueDefine
            local define = parent.data.define

            UpdateMenuButtonText(define, self, parent.menuButton)
        end
    end

    ---@param self Button
    local function MenuButtonOnClick(self)
        ---@type FakeItemWindowNumberPayloadRow
        local parent = self:GetParent()

        ---@type ItemPayloadValueDefine
        local define = parent.data.define

        BuildMenuButtonMenu(define, parent.editBox, self)
    end

    ---@param parent FakeItemWindow
    ---@param payloadData ItemNumberPayloadData
    ---@return FakeItemWindowNumberPayloadRow
    function FI:BuildNumberPayloadRow(parent, payloadData)
        ---@type FakeItemWindowNumberPayloadRow
        local row = CreateFrame('Frame', nil, parent)
        row:SetSize(480, 24)

        row.label = row:CreateFontString(nil, 'ARTWORK')
        row.label:SetSize(150, 24)
        row.label:SetPoint('TOPLEFT', row, 'TOPLEFT', 3, 0)
        row.label:FontTemplate(nil, 14)
        row.label:SetTextColor(1, 1, 1)
        row.label:SetJustifyH('LEFT')
        row.label:SetJustifyV('MIDDLE')
        row.label:SetText(payloadData.name)

        row.editBox = CreateFrame('EditBox', nil, row)
        row.editBox:SetSize(payloadData.define and 80 or 322, 24)
        row.editBox:SetPoint('TOPLEFT', row.label, 'TOPRIGHT', 2, 0)
        row.editBox:SetTemplate('Default')
        row.editBox:SetAutoFocus(false)
        row.editBox:SetFontObject('ChatFontNormal')
        row.editBox:SetScript('OnEscapePressed', EditBoxOnEscapePressed)
        row.editBox:SetScript('OnEnterPressed', EditBoxOnEnterPressed)
        row.editBox:SetScript('OnEditFocusGained', EditBoxOnEditFocusGained)
        row.editBox:SetScript('OnEditFocusLost', NumberEditBoxOnEditFocusLost)
        row.editBox:SetScript('OnTextChanged', OnTextChanged)

        if payloadData.define then
            row.menuButton = CreateFrame('Button', nil, row, 'UIPanelButtonTemplate')
            row.menuButton:SetSize(240, 24)
            row.menuButton:SetPoint('RIGHT', row, 'RIGHT', -3, 0)
            row.menuButton:SetText(UNKNOWN)
            row.menuButton:SetScript('OnClick', MenuButtonOnClick)
            S:HandleButton(row.menuButton)
        end

        row.GetValue = GetValue
        row.SetValue = SetValue

        row.data = payloadData

        return row
    end
end

do
    ---@class FakeItemWindowStringPayloadRow: FakeItemWindowPayloadRow
    ---@field data ItemStringPayloadData
    ---@field label FontString
    ---@field editBox EditBoxWithDiscard

    ---@param self FakeItemWindowStringPayloadRow
    ---@return string
    local function GetValue(self)
        return self.editBox:GetText()
    end

    ---@param self FakeItemWindowStringPayloadRow
    ---@param value string
    ---@return string
    local function SetValue(self, value)
        local curr, remain = string_split(':', value, 2)

        self.editBox:SetText(curr)

        return remain
    end

    ---@param parent FakeItemWindow
    ---@param payloadData ItemStringPayloadData
    ---@return FakeItemWindowStringPayloadRow
    function FI:BuildStringPayloadRow(parent, payloadData)
        ---@type FakeItemWindowStringPayloadRow
        local row = CreateFrame('Frame', nil, parent)
        row:SetSize(480, 24)

        row.label = row:CreateFontString(nil, 'ARTWORK')
        row.label:SetSize(150, 24)
        row.label:SetPoint('TOPLEFT', row, 'TOPLEFT', 3, 0)
        row.label:FontTemplate(nil, 14)
        row.label:SetTextColor(1, 1, 1)
        row.label:SetJustifyH('LEFT')
        row.label:SetJustifyV('MIDDLE')
        row.label:SetText(payloadData.name)

        row.editBox = CreateFrame('EditBox', nil, row)
        row.editBox:SetSize(324, 24)
        row.editBox:SetPoint('TOPRIGHT', row, 'TOPRIGHT', -3, 0)
        row.editBox:SetTemplate('Default')
        row.editBox:SetAutoFocus(false)
        row.editBox:SetFontObject('ChatFontNormal')
        row.editBox:SetScript('OnEscapePressed', EditBoxOnEscapePressed)
        row.editBox:SetScript('OnEnterPressed', EditBoxOnEnterPressed)
        row.editBox:SetScript('OnEditFocusGained', EditBoxOnEditFocusGained)
        row.editBox:SetScript('OnEditFocusLost', EditBoxOnEditFocusLost)

        row.GetValue = GetValue
        row.SetValue = SetValue

        row.data = payloadData

        return row
    end
end

do
    ---@class FakeItemWindowPayloadRow: Frame
    ---@field GetValue fun(self: FakeItemWindowPayloadRow): string
    ---@field SetValue fun(self: FakeItemWindowPayloadRow, value: string): string

    ---@param parent FakeItemWindow
    ---@param payloadData ItemPayloadData
    ---@return FakeItemWindowPayloadRow
    function FI:BuildPayloadRow(parent, payloadData)
        if payloadData.type == 'string' then
            return self:BuildStringPayloadRow(parent, payloadData)
        end

        if payloadData.type == 'number' then
            return self:BuildNumberPayloadRow(parent, payloadData)
        end

        if payloadData.type == 'list' then
            return self:BuildListPayloadRow(parent, payloadData)
        end

        if payloadData.type == 'pairList' then
            return self:BuildPairListPayloadRow(parent, payloadData)
        end

        error(string_format('unknown payload type %s for field %s', payloadData.type, payloadData.name))
    end
end

do
    local baseHeight = 45 -- payloadAnchor
        + 24 + 10 -- export button and padding
        + 24 + 5 -- clear button and padding
        + 10 -- end of window padding
    local rowSpace = 5

    function FI:UpdateWindowLayout()
        local height = baseHeight + #self.window.payloads * rowSpace
        for _, row in ipairs(self.window.payloads) do
            height = height + row:GetHeight()
        end

        self.window:SetHeight(height)
    end

    function FI:BuildWindow()
        ---@class FakeItemWindow: Frame
        local window = CreateFrame('Frame', 'RhythmBoxFakeItemWindow', E.UIParent, 'BackdropTemplate')
        window:SetTemplate('Transparent', true)
        window:SetFrameStrata('DIALOG')
        window:SetPoint('TOP', E.UIParent, 'CENTER', 0, 650)
        window:SetSize(500, 1) -- placeholder height

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
        titleText:SetText("Fake Item")

        window.previewTooltip = CreateFrame('GameTooltip', 'RhythmBoxFakeItemTooltip', window, 'GameTooltipTemplate')

        local payloadAnchor = CreateFrame('Frame', nil, window)
        payloadAnchor:SetPoint('BOTTOM', window, 'TOP', 0, -45)
        payloadAnchor:SetSize(480, 1)

        ---@type FakeItemWindowPayloadRow[]
        window.payloads = {}

        ---@type Region
        local prev = payloadAnchor
        for _, payloadData in ipairs(itemPayloads) do
            local row = self:BuildPayloadRow(window, payloadData)
            row:ClearAllPoints()
            row:SetPoint('TOP', prev, 'BOTTOM', 0, -rowSpace)
            prev = row

            table_insert(window.payloads, row)
        end

        local importButton = CreateFrame('Button', nil, window, 'UIPanelButtonTemplate')
        importButton:ClearAllPoints()
        importButton:SetAllPoints()
        importButton:SetFrameLevel(importButton:GetFrameLevel() + 10)
        importButton:SetText('导入')
        importButton:SetScript('OnClick', function()
            ---@type 'item', number, string
            local infoType, _, itemLink = GetCursorInfo()
            if infoType ~= 'item' then return end

            self:HandleItemString(itemLink)

            ClearCursor()
        end)
        S:HandleButton(importButton)
        window.importButton = importButton

        local exportButton = CreateFrame('Button', nil, window, 'UIPanelButtonTemplate')
        exportButton:ClearAllPoints()
        exportButton:SetPoint('TOP', prev, 'BOTTOM', 0, -10)
        exportButton:SetSize(480, 24)
        exportButton:SetText('导出')
        exportButton:SetScript('OnClick', function()
            local itemString = self:ExportItemString()
            if not itemString then return end

            ChatFrameUtil_LinkItem(itemString)
        end)
        S:HandleButton(exportButton)

        local clearButton = CreateFrame('Button', nil, window, 'UIPanelButtonTemplate')
        clearButton:ClearAllPoints()
        clearButton:SetPoint('TOP', exportButton, 'BOTTOM', 0, -5)
        clearButton:SetSize(480, 24)
        clearButton:SetText('清空')
        clearButton:SetScript('OnClick', function()
            for _, row in ipairs(window.payloads) do
                row:SetValue('')
            end

            UpdatePreviewTooltip()
        end)
        S:HandleButton(clearButton)

        return window
    end
end

function FI:CURSOR_CHANGED()
    local infoType = GetCursorInfo()
    self.window.importButton:SetShown(infoType == 'item')
end

function FI:Initialize()
    do
        local specializationIDPayload = itemPayloads[10]
        local numClasses = GetNumClasses()
        for classID = 1, numClasses do
            local className, classFile = GetClassInfo(classID)
            ---@type ColorMixin?
            local classColor = E:ClassColor(classFile)

            ---@type ItemPayloadValueDefineListNoteBranch
            local branch = {
                type = 'branch',
                name = className,
                color = classColor,
                children = {},
            }

            for specIndex = 1, 5 do
                local specID = GetSpecializationInfoForClassID(classID, specIndex)
                if specID then
                    local _, specName = GetSpecializationInfoByID(specID)
                    local name = string_format('%s - %s', className, #specName > 0 and specName or '初始')

                    ---@type ItemPayloadValueDefineListNoteLeaf
                    local leaf = {
                        type = 'leaf',
                        value = specID,
                        name = name,
                        color = classColor,
                    }
                    table_insert(branch.children, leaf)

                    specializationIDPayload.define.display[specID] = name
                end
            end
            table_insert(specializationIDPayload.define.notes, branch)
        end
    end

    do
        local itemContextPayload = itemPayloads[12]

        for key, value in pairs(Enum_ItemCreationContext) do
            itemContextPayload.define.display[value] = key
        end
    end

    do
        local modifiersPayload = itemPayloads[14]

        for key, value in pairs(Enum_ItemModification) do
            modifiersPayload.keyDefine.display[value] = key
        end
    end

    for _, payloadData in ipairs(itemPayloads) do
        if payloadData.define and payloadData.define.type == 'item' then
            for _, itemID in ipairs(payloadData.define.itemList) do
                C_Item_RequestLoadItemDataByID(itemID)
            end
        end
    end

    local window = self:BuildWindow()
    TB:RegisterSubWindow(window, 'Fake Item')

    self.window = window

    self:UpdateWindowLayout()

    self:RegisterEvent('CURSOR_CHANGED')
    self:CURSOR_CHANGED()
end

R:RegisterModule(FI:GetName())
