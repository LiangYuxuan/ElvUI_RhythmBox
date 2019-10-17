local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local ELP = R:GetModule('EncounterLootPlus')
local S = E:GetModule('Skins')
local db = ELP.db

-- Lua functions
local _G = _G

-- WoW API / Variables
local CreateFrame = CreateFrame
local PlaySound = PlaySound

local EncounterJournal_OnFilterChanged = EncounterJournal_OnFilterChanged

local STAT_CRITICAL_STRIKE = STAT_CRITICAL_STRIKE
local STAT_HASTE = STAT_HASTE
local STAT_VERSATILITY = STAT_VERSATILITY
local STAT_MASTERY = STAT_MASTERY

local function addButton(info, level, text, value, parent, displayText)
    info.text = text
    info.arg1 = value
    info.disabled = nil
    info.checked = db[parent] == value
    info.func = function(self, value)
        db[parent] = value
        _G.ELPFilter:SetText(displayText)
        EncounterJournal_OnFilterChanged(self)
    end
    _G.UIDropDownMenu_AddButton(info, level)
end

local function addSeparator(info, level, text)
    info.text = text
    info.notCheckable = true
    info.arg1 = nil
    info.func =  nil
    info.hasArrow = false
    _G.UIDropDownMenu_AddButton(info, level)
end

local function addParent(info, level, text, value, disabled)
    info.text = text
    info.value = value
    info.disabled = disabled
    info.func = nil
    info.notCheckable = true
    info.hasArrow = not info.disabled
    _G.UIDropDownMenu_AddButton(info, level)
end

local function addSubButton(info, level, text, value, parent, disabled)
    info.text = text
    info.arg1 = value
    info.disabled = disabled
    info.checked = db[parent] == value
    info.func = function(self, value)
        db[parent] = value
        EncounterJournal_OnFilterChanged(self)
    end
    _G.UIDropDownMenu_AddButton(info, level)
end

local function FilterMenu(self, level)
    local info = _G.UIDropDownMenu_CreateInfo()
    if level == 1 then
        addButton(info, level, "当前副本", 0, 'searchRange', "当前副本")
        addButton(info, level, "全部地下城", 2, 'searchRange', "地下城")
        addButton(info, level, "全部团队副本", 1, 'searchRange', "团队副本")
        addButton(info, level, "全部副本", 3, 'searchRange', "所有副本")

        addSeparator(info, level, "其他条件")

        addParent(info, level, "副属性1", 'secondaryStat1', db.searchRange == 0)
        addParent(info, level, "副属性2", 'secondaryStat2', db.searchRange == 0 or db.secondaryStat1 == 0)
        addParent(info, level, "物品等级", 'itemLevel', db.searchRange == 0)
    else
        if _G.UIDROPDOWNMENU_MENU_VALUE == 'secondaryStat1' then
            addSubButton(info, level, "任意", 0, 'secondaryStat1')
            addSubButton(info, level, "+ " .. STAT_CRITICAL_STRIKE, 1, 'secondaryStat1')
            addSubButton(info, level, "+ " .. STAT_HASTE,           2, 'secondaryStat1')
            addSubButton(info, level, "+ " .. STAT_VERSATILITY,     3, 'secondaryStat1')
            addSubButton(info, level, "+ " .. STAT_MASTERY,         4, 'secondaryStat1')
        elseif _G.UIDROPDOWNMENU_MENU_VALUE == 'secondaryStat2' then
            addSubButton(info, level, "任意", 0, 'secondaryStat2')
            addSubButton(info, level, "+ " .. STAT_CRITICAL_STRIKE, 1, 'secondaryStat2', db.secondaryStat1 == 1)
            addSubButton(info, level, "+ " .. STAT_HASTE,           2, 'secondaryStat2', db.secondaryStat1 == 2)
            addSubButton(info, level, "+ " .. STAT_VERSATILITY,     3, 'secondaryStat2', db.secondaryStat1 == 3)
            addSubButton(info, level, "+ " .. STAT_MASTERY,         4, 'secondaryStat2', db.secondaryStat1 == 4)
        elseif _G.UIDROPDOWNMENU_MENU_VALUE == 'itemLevel' then
            addSubButton(info, level, "原始", 0, 'itemLevel')
            for i = 340, 370, 15 do
                addSubButton(info, level, i, i, 'itemLevel')
            end
            for i = 375, 425,  5 do
                addSubButton(info, level, i, i, 'itemLevel')
            end
        end
    end
end

function ELP:HandleMenus()
    local dropdown = CreateFrame('Frame', 'ELPFilterDropdown', _G.EncounterJournalEncounterFrameInfoLootScrollFrame, 'UIDropDownMenuTemplate')
    dropdown:SetID(1)
    dropdown:SetClampedToScreen(true)
    dropdown:Hide()

    local btn = CreateFrame('Button', 'ELPFilter', _G.EncounterJournalEncounterFrameInfoLootScrollFrame, 'EJButtonTemplate')
    btn:SetAlpha(1)
    btn:SetText("当前副本")
    btn:GetFontString():SetTextColor(1, 1, 1)
    btn:Point('LEFT', _G.EncounterJournalEncounterFrameInfoLootScrollFrameFilterToggle, 'RIGHT', 4, 0)
    btn:SetScript('OnClick', function()
        _G.ToggleDropDownMenu(1, nil, dropdown, btn, 5, 0)
        PlaySound(_G.SOUNDKIT.IG_MAINMENU_OPTION)
    end)
    S:HandleButton(btn, true)
    _G.UIDropDownMenu_Initialize(dropdown, FilterMenu, 'MENU')
end
