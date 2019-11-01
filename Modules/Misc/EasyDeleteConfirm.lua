-- From Easy Delete Confirm
-- https://www.curseforge.com/wow/addons/easydeleteconfirm

local R, E, L, V, P, G = unpack(select(2, ...))
local EDC = R:NewModule('EasyDeleteConfirm', 'AceEvent-3.0')

-- Lua functions
local _G = _G
local select = select

-- WoW API / Variables
local GetCursorInfo = GetCursorInfo

function EDC:DELETE_ITEM_CONFIRM()
    if _G.StaticPopup1EditBox:IsShown() then
        _G.StaticPopup1EditBox:Hide()
        _G.StaticPopup1Button1:Enable()

        local link = select(3, GetCursorInfo())

        self.link:SetText(link)
        self.link:Show()
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
    self.link = _G.StaticPopup1:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
    self.link:SetPoint('CENTER', _G.StaticPopup1EditBox)
    self.link:Hide()

    _G.StaticPopup1:HookScript('OnHide', function(self)
        EDC.link:Hide()
    end)

    self:HandleEvent()
end

R:RegisterModule(EDC:GetName())
