local R, E, L, V, P, G = unpack((select(2, ...)))
local QC = R:NewModule('QueensConservatory', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions
local _G = _G
local floor, ipairs, tinsert, tostring = floor, ipairs, tinsert, tostring

-- WoW API / Variables
local C_Item_GetItemCooldown = C_Item.GetItemCooldown
local C_Item_GetItemCount = C_Item.GetItemCount
local C_Item_GetItemInfo = C_Item.GetItemInfo
local C_Item_GetItemQualityColor = C_Item.GetItemQualityColor
local C_Item_IsItemInRange = C_Item.IsItemInRange
local C_Map_GetBestMapForUnit = C_Map.GetBestMapForUnit
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local UnitCanAttack = UnitCanAttack
local UnitGUID = UnitGUID

local CooldownFrame_Set = CooldownFrame_Set
local Item = Item

local catalysts = {
    176921, -- Temporal Leaves
    176922, -- Wild Nightbloom
    176832, -- Wildseed Root Grain
}

local spirits = {
    178881, -- Dutiful Spirit
    178874, -- Martial Spirit
    177698, -- Untamed Spirit
    178882, -- Prideful Spirit
    178880, -- Greater Dutiful Spirit
    178877, -- Greater Martial Spirit
    177699, -- Greater Untamed Spirit
    178883, -- Greater Prideful Spirit
    178879, -- Divine Dutiful Spirit
    178878, -- Divine Martial Spirit
    177700, -- Divine Untamed Spirit
    178884, -- Divine Prideful Spirit
}

function QC:PLAYER_TARGET_CHANGED()
    local unitGUID = UnitGUID('target')
    local npcID = unitGUID and R:ParseNPCID(unitGUID)

    if npcID == 165466 then -- Wildseed of Regrowth
        self.catalystsContainer:Hide()
        self.spiritsContainer:Show()
    elseif npcID == 165480 then -- Anima Catalyst Plot
        self.catalystsContainer:Show()
        self.spiritsContainer:Hide()
    else
        self.catalystsContainer:Hide()
        self.spiritsContainer:Hide()
    end
end

function QC:UpdateItemCount()
    for _, button in ipairs(self.catalysts) do
        local count = C_Item_GetItemCount(button.itemID, nil, true) or 0
        button.count:SetText(count)
    end

    for _, button in ipairs(self.spirits) do
        local count = C_Item_GetItemCount(button.itemID, nil, true) or 0
        button.count:SetText(count)
    end
end

function QC:PLAYER_ENTERING_WORLD()
    local uiMapID = C_Map_GetBestMapForUnit('player')
    if not uiMapID then
        self:ScheduleTimer('PLAYER_ENTERING_WORLD', 1)
        return
    end

    if uiMapID == 1662 then
        -- entering Queen's Conservatory must be out of combat
        self.container:Show()

        self:RegisterEvent('BAG_UPDATE_DELAYED', 'UpdateItemCount')
        self:RegisterEvent('PLAYER_TARGET_CHANGED')
        self:PLAYER_TARGET_CHANGED()
    else
        if self.container:IsShown() then
            -- leaving Queen's Conservatory must be out of combat
            self.container:Hide()
        end

        self:UnregisterEvent('BAG_UPDATE_DELAYED')
        self:UnregisterEvent('PLAYER_TARGET_CHANGED')
    end
end

do
    local function ButtonOnEnter(self)
        _G.GameTooltip:Hide()
        _G.GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT', 0, -2)
        _G.GameTooltip:ClearLines()

        _G.GameTooltip:SetItemByID(self.itemID)
        _G.GameTooltip:Show()
    end

    local function ButtonOnLeave(self)
        _G.GameTooltip:Hide()
    end

    local function ButtonOnUpdate(self)
        local startTime, duration, enable = C_Item_GetItemCooldown(self.itemID)

        CooldownFrame_Set(self.cooldown, startTime, duration, enable)

        if duration and duration > 0 and not enable then
            self.icon:SetVertexColor(.4, .4, .4)
        elseif (not InCombatLockdown() or UnitCanAttack('player', 'target')) and C_Item_IsItemInRange(self.itemID, 'target') == false then
            self.icon:SetVertexColor(.8, .1, .1)
        else
            self.icon:SetVertexColor(1, 1, 1)
        end
    end

    function QC:CreateButton(itemID, parent)
        ---@class QueenConservatoryButton: Button
        local button = CreateFrame('Button', nil, parent, 'SecureActionButtonTemplate, BackdropTemplate')
        button:SetScript('OnEnter', ButtonOnEnter)
        button:SetScript('OnLeave', ButtonOnLeave)
        button:SetScript('OnUpdate', ButtonOnUpdate)

        button:SetSize(40, 40)
        button:SetTemplate('Default')
        button:StyleButton()
        button:EnableMouse(true)
        button:RegisterForClicks('AnyUp', 'AnyDown')

        -- Icon
        button.icon = button:CreateTexture(nil, 'OVERLAY')
        button.icon:SetInside(button, 2, 2)
        button.icon:SetTexCoord(.1, .9, .1, .9)

        -- Count
        button.count = button:CreateFontString(nil, 'OVERLAY')
        button.count:FontTemplate(nil, 18, 'OUTLINE')
        button.count:SetTextColor(1, 1, 1, 1)
        button.count:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', .5 ,0)
        button.count:SetJustifyH('CENTER')

        -- Cooldown
        ---@class QueenConservatoryButtonCooldown: Cooldown
        button.cooldown = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')
        button.cooldown:SetInside(button, 2, 2)
        button.cooldown:SetDrawEdge(false)
        button.cooldown.CooldownOverride = 'actionbar'

        E:RegisterCooldown(button.cooldown)
        E:RegisterPetBattleHideFrames(button, parent)

        button.itemID = itemID
        button:SetAttribute('*type1', 'item')
        button:SetAttribute('*item1', 'item:' .. itemID)

        local itemCount = C_Item_GetItemCount(itemID, nil, true) or 0
        button.count:SetText(tostring(itemCount))

        local _, _, rarity, _, _, _, _, _, _, itemIcon = C_Item_GetItemInfo(itemID)
        if itemIcon then
            local r, g, b = C_Item_GetItemQualityColor((rarity and rarity > 1 and rarity) or 1)

            button:SetBackdropBorderColor(r, g, b)
            button.icon:SetTexture(itemIcon)
        else
            local item = Item:CreateFromItemID(itemID)
            item:ContinueOnItemLoad(function()
                local itemID = item:GetItemID()
                local _, _, rarity, _, _, _, _, _, _, itemIcon = C_Item_GetItemInfo(itemID)
                local r, g, b = C_Item_GetItemQualityColor((rarity and rarity > 1 and rarity) or 1)

                button:SetBackdropBorderColor(r, g, b)
                button.icon:SetTexture(itemIcon)
            end)
        end

        return button
    end
end

function QC:Initialize()
    local frameName = 'RhythmBoxQCContainer'
    local container = CreateFrame('Frame', frameName, E.UIParent)
    container:ClearAllPoints()
    container:SetPoint('LEFT', E.UIParent, 'CENTER', 200, 0)
    container:SetSize(170, 130)
    E:CreateMover(container, frameName .. 'Mover', "Rhythm Box 女王的温室助手", nil, nil, nil, 'ALL,RHYTHMBOX')
    self.container = container

    local catalystsContainer = CreateFrame('Frame', nil, container)
    catalystsContainer:ClearAllPoints()
    catalystsContainer:SetPoint('LEFT')
    catalystsContainer:SetSize(170, 40)
    self.catalystsContainer = catalystsContainer

    self.catalysts = {}
    for index, itemID in ipairs(catalysts) do
        local button = self:CreateButton(itemID, catalystsContainer)
        button:ClearAllPoints()
        button:SetPoint('TOPLEFT', catalystsContainer, 'TOPLEFT', (index - 1) * 43, 0)
        tinsert(self.catalysts, button)
    end

    local spiritsContainer = CreateFrame('Frame', nil, container)
    spiritsContainer:ClearAllPoints()
    spiritsContainer:SetPoint('LEFT')
    spiritsContainer:SetSize(170, 130)
    self.spiritsContainer = spiritsContainer

    self.spirits = {}
    for index, itemID in ipairs(spirits) do
        local button = self:CreateButton(itemID, spiritsContainer)
        button:ClearAllPoints()
        button:SetPoint('TOPLEFT', spiritsContainer, 'TOPLEFT', ((index - 1) % 4) * 43, floor((index - 1) / 4) * -43)
        tinsert(self.spirits, button)
    end

    self:RegisterEvent('PLAYER_ENTERING_WORLD')
end

R:RegisterModule(QC:GetName())
