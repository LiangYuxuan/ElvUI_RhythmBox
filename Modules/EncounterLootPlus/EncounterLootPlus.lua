local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule('Skins')
local R = unpack(select(2, ...))
local ELP = R.ELP

-- This module is from abyui's 163UI_EncounterLootPlus
-- https://github.com/aby-ui/repo-base/tree/master/163UI_EncounterLootPlus
-- Thanks to abyui

local db = {
    -- 0 - Not Hooking Blizzard's Default Filter
    -- 1 - All Dungeons
    -- 2 - All Raids
    -- 3 - All Dungeons and Raids
    searchRange = 0, -- search range
    -- 0 - All Secondary Stats
    -- 1 - Critial Strike
    -- 2 - Haste
    -- 3 - Versatility
    -- 4 - Mastery
    secondaryStat1 = 0, -- first secondary stat to search
    secondaryStat2 = 0, -- second secondary stat to search
    itemLevel = 0, -- item level 
    items = {}, -- item stats cache
}
ELP.db = db

function ELP:OnEnable()
    if IsAddOnLoaded('Blizzard_EncounterJournal') then
        self:CreateButton()
    else
        self:RegisterEvent('ADDON_LOADED')
    end
end

function ELP:ADDON_LOADED(event, name)
    if name == 'Blizzard_EncounterJournal' then
        self:UnregisterEvent('ADDON_LOADED')
        self:CreateButton()
    end
end

function ELP:CreateButton()
    local btn = CreateFrame('Button', 'ELPShortcut', EncounterJournalInstanceSelect, 'UIMenuButtonStretchTemplate')
    btn.Text:SetFont(GameFontNormal:GetFont())
    btn:SetAlpha(1)
    btn:SetText("装备搜索")
    btn:Size(btn:GetFontString():GetStringWidth() * 1.5, 32)
    btn:Point('BOTTOMLEFT', _G.EncounterJournal.instanceSelect.LootJournalTab, 'BOTTOMRIGHT', 2, 0)
    btn:SetScript('OnClick', function()
        if self.db.searchRange == 0 then self.db.searchRange = 3 end
        EncounterJournal_DisplayInstance(1023)
        EncounterJournalEncounterFrameInfoLootTab:Click()
        EncounterJournalEncounterFrameInfoLootScrollFrameFilterToggle:Click()
    end)
    S:HandleButton(btn)

    self:HandleMenus()
    self:HandleHooks()
end
