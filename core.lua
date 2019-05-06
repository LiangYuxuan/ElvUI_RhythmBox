local E, L, V, P, G = unpack(ElvUI);
local EP = LibStub('LibElvUIPlugin-1.0')
local addon, Engine = ...

local R = E:NewModule('RhythmBox', 'AceEvent-3.0')
Engine[1] = R
Engine[2] = E
Engine[3] = L
Engine[4] = V
Engine[5] = P
Engine[6] = G

R.Config = {}

P["RhythmBox"] = {}
P["RhythmBox"]["general"] = {}

local function CoreOptions()
    E.Options.args.RhythmBox = {
        order = 1.5,
        type = 'group',
        name = 'Rhythm Box',
        args = {
            name = {
                order = 1,
                type = 'header',
                name = 'Rhythm Box',
            },
            general = {
                order = 2,
                type = 'group',
                name = L["General"],
                get = function(info) return E.db.RhythmBox.general[ info[#info] ] end,
                set = function(info, value) E.db.RhythmBox.general[ info[#info] ] = value; end,
                args = {},
            },
        },
    }
end
tinsert(R.Config, CoreOptions)

function R:AddOptions()
    for _, func in pairs(R.Config) do
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
