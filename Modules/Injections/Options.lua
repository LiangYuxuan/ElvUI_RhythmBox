local R, E, L, V, P, G = unpack(select(2, ...))
local RI = R:GetModule('Injections')

-- Lua functions

-- WoW API / Variables

P["RhythmBox"]["Injections"] = {
}

local function InjectionsOptions()
    E.Options.args.RhythmBox.args.Injections = {
        order = 3,
        type = 'group',
        name = "插件注入",
        get = function(info) return E.db.RhythmBox.Injections[ info[#info] ] end,
        set = function(info, value) E.db.RhythmBox.Injections[ info[#info] ] = value end,
        args = {},
    }
end
-- tinsert(R.Config, InjectionsOptions)
