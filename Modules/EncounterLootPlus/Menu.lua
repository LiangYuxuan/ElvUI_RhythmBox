local E, L, V, P, G = unpack(ElvUI)
local R = unpack(select(2, ...))
local ELP = R.ELP
local db = ELP.db

local function addButton(info, level, text, value, disabled)
    info.text = text
    info.value = value
    info.disabled = disabled
    info.func = nil
    info.notCheckable = true
    info.hasArrow = not info.disabled
    UIDropDownMenu_AddButton(info, level)
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
    UIDropDownMenu_AddButton(info, level)
end

local function LootFilter_Menu(self, level)
    local info = UIDropDownMenu_CreateInfo()
    if level == 1 then
        addButton(info, level, "装备搜索", 'searchRange')
        addButton(info, level, "副属性1", 'secondaryStat1', db.searchRange == 0)
        addButton(info, level, "副属性2", 'secondaryStat2', db.searchRange == 0 or db.secondaryStat1 == 0)
        addButton(info, level, "物品等级", 'itemLevel', db.searchRange == 0)
    else
        if UIDROPDOWNMENU_MENU_VALUE == 'searchRange' then
            addSubButton(info, level, "当前副本", 0, 'searchRange')
            addSubButton(info, level, "全部地下城", 2, 'searchRange')
            addSubButton(info, level, "全部团队副本", 1, 'searchRange')
            addSubButton(info, level, "全部副本", 3, 'searchRange')
        elseif UIDROPDOWNMENU_MENU_VALUE == 'secondaryStat1' then
            addSubButton(info, level, "任意", 0, 'secondaryStat1')
            addSubButton(info, level, "+ " .. STAT_CRITICAL_STRIKE, 1, 'secondaryStat1')
            addSubButton(info, level, "+ " .. STAT_HASTE,           2, 'secondaryStat1')
            addSubButton(info, level, "+ " .. STAT_VERSATILITY,     3, 'secondaryStat1')
            addSubButton(info, level, "+ " .. STAT_MASTERY,         4, 'secondaryStat1')
        elseif UIDROPDOWNMENU_MENU_VALUE == 'secondaryStat2' then
            addSubButton(info, level, "任意", 0, 'secondaryStat2')
            addSubButton(info, level, "+ " .. STAT_CRITICAL_STRIKE, 1, 'secondaryStat2', db.secondaryStat1 == 1)
            addSubButton(info, level, "+ " .. STAT_HASTE,           2, 'secondaryStat2', db.secondaryStat1 == 2)
            addSubButton(info, level, "+ " .. STAT_VERSATILITY,     3, 'secondaryStat2', db.secondaryStat1 == 3)
            addSubButton(info, level, "+ " .. STAT_MASTERY,         4, 'secondaryStat2', db.secondaryStat1 == 4)
        elseif UIDROPDOWNMENU_MENU_VALUE == 'itemLevel' then
            addSubButton(info, level, "原始", 0, 'itemLevel')
            for i = 340, 370, 15 do
                addSubButton(info, level, i, i, 'itemLevel')
            end
            for i = 375, 425,  5 do
                addSubButton(info, level, i, i, 'itemLevel')
            end
        end
    end

    info.disabled = nil
    EncounterJournal_InitLootFilter(self, level)
end

function ELP:HandleMenus()
    UIDropDownMenu_Initialize(EncounterJournal.encounter.info.lootScroll.lootFilter, LootFilter_Menu, 'MENU')
end
