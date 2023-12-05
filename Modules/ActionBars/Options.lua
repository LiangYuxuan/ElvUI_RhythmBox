local R, E, L, V, P, G = unpack((select(2, ...)))
local AB = R:GetModule('ActionBars')

P["RhythmBox"]["ActionBars"] = {
}

R:RegisterOptions(function()
    E.Options.args.RhythmBox.args.ActionBars = {
        order = 1,
        type = 'group',
        name = "战斗与动作条",
        get = function(info) return E.db.RhythmBox.ActionBars[ info[#info] ] end,
        set = function(info, value) E.db.RhythmBox.ActionBars[ info[#info] ] = value end,
        args = {
            Install = {
                order = 1,
                type = 'execute',
                name = "设定按键",
                desc = "从默认快捷键设置开始，重新设定快捷键。",
                func = function() AB:InstallActionBars() end,
            },
        },
    }
end)
