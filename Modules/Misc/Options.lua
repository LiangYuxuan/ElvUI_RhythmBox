local R, E, L, V, P, G = unpack(select(2, ...))
local M = R:GetModule('Misc')
local EDC = R:GetModule('EasyDeleteConfirm')
local FL = R:GetModule('FastLoot')

P["RhythmBox"]["Misc"] = {
    ["EasyDeleteConfirm"] = true,
    ["FastLoot"] = true,
    ["FasterMovieSkip"] = true,
    ["BlockPvP"] = true,
    ["ShowDestination"] = true,
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
            EasyDeleteConfirm = {
                order = 3,
                type = 'toggle',
                name = "自动填入DELETE",
                set = function(info, value) E.db.RhythmBox.Misc[ info[#info] ] = value; EDC:HandleEvent() end,
            },
            FastLoot = {
                order = 4,
                type = 'toggle',
                name = "快速拾取",
                set = function(info, value) E.db.RhythmBox.Misc[ info[#info] ] = value; FL:Initialize() end,
            },
            FasterMovieSkip = {
                order = 5,
                type = 'toggle',
                name = "快速跳过剧情动画/CG",
            },
            BlockPvP = {
                order = 6,
                type = 'toggle',
                name = "禁用PvP按钮",
                hidden = R.Classic,
            },
            ShowDestination = {
                order = 7,
                type = 'toggle',
                name = "总是显示任务最终目的地",
                hidden = R.Classic,
            },
        },
    }
end
tinsert(R.Config, MiscOptions)
