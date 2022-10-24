local R, E, L, V, P, G = unpack(select(2, ...))
if R.Dragonflight then return end

local EV = R:NewModule('EnchantingVellum', 'AceEvent-3.0', 'AceHook-3.0')

-- Lua functions
local _G = _G
local select, strfind, strlower = select, strfind, strlower

-- WoW API / Variables
local C_TradeSkillUI_GetRecipeDescription = C_TradeSkillUI.GetRecipeDescription
local C_TradeSkillUI_GetRecipeItemLink = C_TradeSkillUI.GetRecipeItemLink
local C_TradeSkillUI_GetTradeSkillLine = C_TradeSkillUI.GetTradeSkillLine
local CreateFrame = CreateFrame
local GetItemCount = GetItemCount
local IsAddOnLoaded = IsAddOnLoaded

local soulbindPattern = strlower(ITEM_SOULBOUND)

function EV:ShouldButtonShow(recipeID)
    if not recipeID then return end

    local parentSkillLineID = select(6, C_TradeSkillUI_GetTradeSkillLine())
    if not parentSkillLineID or parentSkillLineID ~= 333 then return end

    local recipeItemLink = C_TradeSkillUI_GetRecipeItemLink(recipeID)
    if strfind(recipeItemLink, 'item:(%d+)') then return end

    local recipeDescription = C_TradeSkillUI_GetRecipeDescription(recipeID)
    if strfind(strlower(recipeDescription), soulbindPattern) then return end

    return true
end

function EV:OnSetSelectedRecipeID(_, recipeID)
    self.button:SetShown(self:ShouldButtonShow(recipeID))
end

function EV:BAG_UPDATE()
    self.button.count:SetText(GetItemCount(38682))
end

function EV:Toggle()
    local button = CreateFrame('Button', nil, _G.TradeSkillFrame.DetailsFrame, 'SecureActionButtonTemplate, BackdropTemplate')
    button:SetSize(32, 32)
    button:ClearAllPoints()
    button:SetPoint('BOTTOMRIGHT')
    button:Show()
    button:SetScript('OnEnter', function(self)
        _G.GameTooltip:Hide()
        _G.GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT', 0, -2)
        _G.GameTooltip:ClearLines()
        _G.GameTooltip:SetItemByID(38682)
        _G.GameTooltip:Show()
    end)
    button:SetScript('OnLeave', function()
        _G.GameTooltip:Hide()
    end)

    button:SetTemplate('Default')
    button:StyleButton()
    button:EnableMouse(true)
    button:RegisterForClicks('AnyUp')

    -- Icon
    button.icon = button:CreateTexture(nil, 'OVERLAY')
    button.icon:SetInside(button, 2, 2)
    button.icon:SetTexCoord(.1, .9, .1, .9)
    button.icon:SetTexture(237050)

    -- Count
    button.count = button:CreateFontString(nil, 'OVERLAY')
    button.count:SetTextColor(1, 1, 1, 1)
    button.count:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', .5 ,0)
    button.count:SetJustifyH('CENTER')
    button.count:FontTemplate(nil, 18, 'OUTLINE')
    button.count:SetText(GetItemCount(38682))

    button:SetAttribute('type1', 'macro')
    button:SetAttribute('macrotext1', '/run C_TradeSkillUI.CraftRecipe(TradeSkillFrame.DetailsFrame.selectedRecipeID)\n/use item:38682')

    self.button = button

    self:RegisterEvent('BAG_UPDATE')
    self:SecureHook(_G.TradeSkillFrame.DetailsFrame, 'SetSelectedRecipeID', 'OnSetSelectedRecipeID')
end

function EV:ADDON_LOADED(_, addonName)
    if addonName == 'Blizzard_TradeSkillUI' then
        self:UnregisterEvent('Blizzard_TradeSkillUI')
        self:Toggle()
    end
end

function EV:Initialize()
    if IsAddOnLoaded('Blizzard_TradeSkillUI') then
        self:Toggle()
    else
        self:RegisterEvent('ADDON_LOADED')
    end
end

R:RegisterModule(EV:GetName())
