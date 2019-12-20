local R, E, L, V, P, G = unpack(select(2, ...))
local RI = R:GetModule('Injections')

-- Lua functions
local ipairs = ipairs

-- WoW API / Variables
local C_ChallengeMode_GetMapUIInfo = C_ChallengeMode.GetMapUIInfo

P["RhythmBox"]["Injections"] = {
    ["AngryKeystones"] = {
        ["ChallengeMapID"] = 0,
        ["Level"] = 0,
    },
}

local function InjectionsOptions()
    E.Options.args.RhythmBox.args.Injections = {
        order = 3,
        type = 'group',
        name = "插件注入",
        get = function(info) return E.db.RhythmBox.Injections[ info[#info] ] end,
        set = function(info, value) E.db.RhythmBox.Injections[ info[#info] ] = value end,
        args = {
            AngryKeystones = {
                name = "Angry Keystones",
                order = 1,
                type = 'group',
                get = function(info) return E.db.RhythmBox.Injections.AngryKeystones[ info[#info] ] end,
                set = function(info, value) E.db.RhythmBox.Injections.AngryKeystones[ info[#info] ] = value; RI:AngryKeystones_Update() end,
                args = {
                    ChallengeMapID = {
                        name = "钥石地图",
                        order = 1,
                        type = 'select',
                        desc = "伪造的钥石地图",
                        values = {
                            [0] = "不更改",
                        },
                    },
                    Level = {
                        name = "钥石等级",
                        order = 2,
                        type = 'range',
                        desc = "伪造的钥石等级（0为不更改）",
                        min = 0, max = 999, step = 1,
                    },
                },
            },
        },
    }

    for _, challengeMapID in ipairs(RI.ChallengeMapIDs) do
        E.Options.args.RhythmBox.args.Injections.args.AngryKeystones.args.ChallengeMapID.values[challengeMapID] =
            C_ChallengeMode_GetMapUIInfo(challengeMapID)
    end
end
tinsert(R.Config, InjectionsOptions)
