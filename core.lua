local E, L, V, P, G = unpack(ElvUI)
local EP = LibStub('LibElvUIPlugin-1.0')
local addon, Engine = ...

-- Lua functions
local pairs = pairs

-- WoW API / Variables

local R = E:NewModule('RhythmBox', 'AceEvent-3.0')
Engine[1] = R
Engine[2] = E
Engine[3] = L
Engine[4] = V
Engine[5] = P
Engine[6] = G

R.Retail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
R.Classic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

R.Config = {}

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
        plugins = {},
    }
end
tinsert(R.Config, CoreOptions)

function R:AddOptions()
    for _, func in pairs(self.Config) do
        func()
    end
end

function R:Initialize()
    EP:RegisterPlugin(addon, self.AddOptions)
end

local function InitializeCallback()
    R:Initialize()
end

E:RegisterModule(R:GetName(), InitializeCallback)
