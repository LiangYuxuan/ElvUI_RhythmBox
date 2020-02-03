local R, E, L, V, P, G = unpack(select(2, ...))
local RI = R:GetModule('Injections')

-- Lua functions
local ipairs = ipairs

-- WoW API / Variables
local C_ChallengeMode_GetMapUIInfo = C_ChallengeMode and C_ChallengeMode.GetMapUIInfo

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
                hidden = function() return R.Classic end,
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
                    SendChatLink = {
                        order = 3,
                        type = 'execute',
                        name = "发送钥石",
                        desc = "向聊天中发送向队友共享的钥石。",
                        func = function() RI:InsertChatLink() end,
                    },
                    RestoreDefault = {
                        order = 4,
                        type = 'execute',
                        name = "恢复默认",
                        desc = "将本页选项恢复为默认选项。",
                        func = function()
                            E.db.RhythmBox.Injections.AngryKeystones.ChallengeMapID = 0;
                            E.db.RhythmBox.Injections.AngryKeystones.Level = 0
                        end,
                    },
                },
            },
            --[[
            TomTom = {
                name = "TomTom",
                order = 2,
                type = 'group',
                get = function(info) return E.db.RhythmBox.Injections.TomTom[ info[#info] ] end,
                set = function(info, value) E.db.RhythmBox.Injections.TomTom[ info[#info] ] = value end,
                hidden = function() return R.Classic end,
                args = {
                    AddWaypoints = {
                        order = 1,
                        type = 'execute',
                        name = "设置导航点",
                        desc = "设置预设的TomTom导航点。",
                        func = function() RI:AddWaypoints() end,
                    },
                },
            },
            ]]--
        },
    }

    for _, challengeMapID in ipairs(RI.ChallengeMapIDs) do
        E.Options.args.RhythmBox.args.Injections.args.AngryKeystones.args.ChallengeMapID.values[challengeMapID] =
            C_ChallengeMode_GetMapUIInfo(challengeMapID)
    end
end
tinsert(R.Config, InjectionsOptions)
