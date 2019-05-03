-- Original Author: 混乱时雨@NGA
-- Link: https://bbs.nga.cn/read.php?tid=16385126&_ff=200

local R, E, L, V, P, G = unpack(select(2, ...))
local RH = E:NewModule('RhythmBox_RandomHearthstone', 'AceEvent-3.0', 'AceTimer-3.0')

local macroName = '组合传送宏'
local macroTemplate =
"#showtooltip\n" ..
"/use [mod:shift]%s;[mod:ctrl]%s;[mod:alt]%s\n" ..
"/cast %s"

local hearthstoneList = {
    -- 54452,  -- Ethereal Portal
    -- 64488,  -- The Innkeeper's Daughter
    -- 93672,  -- Dark Portal
    -- 142542, -- Tome of Town Portal
    162973, -- Greatfather Winter's Hearthstone
    163045, -- Headless Horseman's Hearthstone
    165669, -- Lunar Elder's Hearthstone
    165670, -- Peddlefeet's Lovely Hearthstone
    165802, -- Noble Gardener's Hearthstone
    166746, -- Fire Eater's Hearthstone
    166747, -- Brewfest Reveler's Hearthstone
}

function RH:UpdateMacro()
    if InCombatLockdown() then
        return self:RegisterEvent('PLAYER_REGEN_ENABLED')
    end

    local hearthstone = GetItemInfo(6948)
    local garrison = GetItemInfo(110560)
    local dalaran = GetItemInfo(140192)
    local whistle = GetItemInfo(141605)

    local tbl = {}
    for _, itemID in ipairs(hearthstoneList) do
        if PlayerHasToy(itemID) then
            tinsert(tbl, itemID)
        end
    end
    if #tbl > 0 then
        hearthstone = GetItemInfo(tbl[random(#tbl)])
    end

    if not (hearthstone and garrison and dalaran and whistle) then
        return self:ScheduleTimer("UpdateMacro", 1)
    end

    local text = format(macroTemplate, garrison, dalaran, whistle, hearthstone)
    local name = GetMacroInfo(macroName)
    if not name then
        CreateMacro(macroName, 'INV_MISC_QUESTIONMARK', text)
    else
        EditMacro(macroName, nil, nil, text)
    end
end

function RH:PLAYER_REGEN_ENABLED()
    self:UnregisterEvent('PLAYER_REGEN_ENABLED')
    self:UpdateMacro()
end

function RH:Initialize()
    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateMacro')
    self:RegisterEvent('NEW_TOY_ADDED', 'UpdateMacro')
    self:UpdateMacro()
end

local function InitializeCallback()
    RH:Initialize()
end

E:RegisterModule(RH:GetName(), InitializeCallback)
