-- From Easy Delete Confirm
-- https://www.curseforge.com/wow/addons/easydeleteconfirm

local R, E, L, V, P, G = unpack((select(2, ...)))
local EDC = R:NewModule('EasyDeleteConfirm', 'AceEvent-3.0')

-- Lua functions
local _G = _G
local select = select

-- WoW API / Variables
local GetCursorInfo = GetCursorInfo

local StaticPopup_FindVisible = StaticPopup_FindVisible

function EDC:DELETE_ITEM_CONFIRM()
    local dialog = StaticPopup_FindVisible('DELETE_GOOD_ITEM') or StaticPopup_FindVisible('DELETE_GOOD_QUEST_ITEM')
    if not dialog or not dialog.deleteItemLink then return end

    local editBox = dialog:GetEditBox()
    if editBox:IsShown() then
        editBox:Hide()
        dialog:GetButton1():Enable()

        local itemLink = select(3, GetCursorInfo())
        dialog.deleteItemLink:SetText(itemLink)
        dialog.deleteItemLink:Show()
    end
end

function EDC:HandleEvent()
    if E.db.RhythmBox.Misc.EasyDeleteConfirm then
        self:RegisterEvent('DELETE_ITEM_CONFIRM')
    else
        self:UnregisterAllEvents()
    end
end

function EDC:Initialize()
    -- create item link container
    local dialog = _G.StaticPopup1

    local deleteItemLink = dialog:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
    deleteItemLink:ClearAllPoints()
    deleteItemLink:SetPoint('CENTER', dialog:GetEditBox())
    deleteItemLink:Hide()
    dialog.deleteItemLink = deleteItemLink

    dialog:HookScript('OnHide', function(self)
        self.deleteItemLink:Hide()
    end)

    self:HandleEvent()
end

R:RegisterModule(EDC:GetName())
