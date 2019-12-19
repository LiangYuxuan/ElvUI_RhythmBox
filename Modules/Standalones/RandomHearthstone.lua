-- Original Author: 混乱时雨@NGA
-- Link: https://bbs.nga.cn/read.php?tid=16385126&_ff=200

local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local RH = R:NewModule('RandomHearthstone', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions
local ipairs, format, random, tinsert = ipairs, format, random, tinsert

-- WoW API / Variables
local CreateMacro = CreateMacro
local EditMacro = EditMacro
local GetItemInfo = GetItemInfo
local GetMacroInfo = GetMacroInfo
local GetNumMacros = GetNumMacros
local InCombatLockdown = InCombatLockdown
local PlayerHasToy = PlayerHasToy

RH.macroName = '组合传送宏'
RH.macroTemplate =
"#showtooltip\n" ..
"/use [mod:shift]%s;[mod:ctrl]%s;[mod:alt]%s\n" ..
"/cast %s\n"

RH.hearthstoneList = {
    54452,  -- Ethereal Portal
    64488,  -- The Innkeeper's Daughter
    93672,  -- Dark Portal
    142542, -- Tome of Town Portal
    162973, -- Greatfather Winter's Hearthstone
    163045, -- Headless Horseman's Hearthstone
    165669, -- Lunar Elder's Hearthstone
    165670, -- Peddlefeet's Lovely Hearthstone
    165802, -- Noble Gardener's Hearthstone
    166746, -- Fire Eater's Hearthstone
    166747, -- Brewfest Reveler's Hearthstone
    168907, -- Holographic Digitalization Hearthstone
    172179, -- Eternal Traveler's Hearthstone
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
    for _, itemID in ipairs(self.hearthstoneList) do
        if E.db.RhythmBox.RandomHearthstone[itemID] and PlayerHasToy(itemID) then
            tinsert(tbl, itemID)
        end
    end
    if #tbl > 0 then
        hearthstone = GetItemInfo(tbl[random(#tbl)])
    end

    if not (hearthstone and dalaran and garrison and whistle) then
        return self:ScheduleTimer('UpdateMacro', 1)
    end

    local text = format(self.macroTemplate, dalaran, garrison, whistle, hearthstone)
    local name = GetMacroInfo(self.macroName)
    if not name then
        local numGlobal = GetNumMacros()
        if numGlobal < 72 then
            CreateMacro(self.macroName, 'INV_MISC_QUESTIONMARK', text)
        end
    else
        EditMacro(self.macroName, nil, nil, text)
    end
end

function RH:PLAYER_REGEN_ENABLED()
    self:UnregisterEvent('PLAYER_REGEN_ENABLED')
    self:UpdateMacro()
end

P["RhythmBox"]["RandomHearthstone"] = {}
for _, v in ipairs(RH.hearthstoneList) do
    P["RhythmBox"]["RandomHearthstone"][v] = true
end

local function randomHearthTable()
    E.Options.args.RhythmBox.args.RandomHearthstone = {
        order = 24,
        type = 'group',
        name = "随机炉石宏",
        args = {
            List = {
                order = 1,
                type = 'multiselect',
                name = "炉石列表",
                get = function(info, k) return E.db.RhythmBox.RandomHearthstone[k] end,
                set = function(info, k, v) E.db.RhythmBox.RandomHearthstone[k] = v; RH:UpdateMacro() end,
                values = {},
            },
        },
    }
    for _, v in ipairs(RH.hearthstoneList) do
        E.Options.args.RhythmBox.args.RandomHearthstone.args.List.values[v] = GetItemInfo(v) or v
    end
end
tinsert(R.Config, randomHearthTable)

function RH:Initialize()
    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateMacro')
    self:RegisterEvent('NEW_TOY_ADDED', 'UpdateMacro')
    self:UpdateMacro()
end

R:RegisterModule(RH:GetName())
