local R, E, L, V, P, G = unpack(select(2, ...))

P["RhythmBox"] = {}

local function CoreOptions()
    E.Options.args.RhythmBox = {
        order = 6,
        type = 'group',
        childGroups = 'tab',
        name = 'Rhythm Box',
        get = function(info) return E.db.RhythmBox.General[ info[#info] ] end,
        set = function(info, value) E.db.RhythmBox.General[ info[#info] ] = value; end,
        args = {
            -- TODO: Put install buttons here
        },
    }
end
tinsert(R.Config, CoreOptions)
