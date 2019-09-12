local R, E, L, V, P, G = unpack(select(2, ...))
local M = E:GetModule('RhythmBox_Misc')
local FL = E:GetModule('RhythmBox_FastLoot')

P["RhythmBox"]["Misc"] = {
    ["FastLoot"] = true,
    ["BlockPvP"] = true,
}

local function MiscOptions()
    E.Options.args.RhythmBox.args.Misc = {
        order = 99,
        type = 'group',
        name = "杂项",
        get = function(info) return E.db.RhythmBox.Misc[ info[#info] ] end,
        set = function(info, value) E.db.RhythmBox.Misc[ info[#info] ] = value end,
        args = {
            Install = {
                order = 1,
                type = 'execute',
                name = "设置CVar",
                func = function() M:ConfigCVar() end,
            },
            Space = {
                order = 2,
                type = "description",
                name = "",
                width = "full",
            },
            FastLoot = {
                order = 3,
                type = 'toggle',
                name = "快速拾取",
                set = function(info, value) E.db.RhythmBox.Misc[ info[#info] ] = value; FL:Initialize() end,
            },
            BlockPvP = {
                order = 4,
                type = 'toggle',
                name = "禁用PvP按钮",
            },
        },
    }
end
tinsert(R.Config, MiscOptions)
