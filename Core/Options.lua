local R, E, L, V, P, G = unpack(select(2, ...))

P["RhythmBox"] = {}
P["RhythmBox"]["General"] = {}

local function CoreOptions()
    E.Options.args.RhythmBox = {
        order = 1.5,
        type = 'group',
        childGroups = 'tab',
        name = 'Rhythm Box',
        get = function(info) return E.db.RhythmBox.General[ info[#info] ] end,
        set = function(info, value) E.db.RhythmBox.General[ info[#info] ] = value; end,
        args = {
            Intro = {
                order = 1,
                type = "description",
                name = 'A World of Warcraft addon for personal use.',
            },
        },
    }
end
tinsert(R.Config, CoreOptions)