local R, E, L, V, P, G = unpack(select(2, ...))
local MP = R:GetModule('MythicPlus')

-- Lua functions
local ipairs = ipairs

-- WoW API / Variables
local C_ChallengeMode_GetMapUIInfo = C_ChallengeMode.GetMapUIInfo
local C_ChallengeMode_IsChallengeModeActive = C_ChallengeMode.IsChallengeModeActive

P["RhythmBox"]["MythicPlus"] = {
    ["ChallengeMapID"] = 0,
    ["Level"] = 0,
}

local function MythicPlusOptions()
    E.Options.args.RhythmBox.args.MythicPlus = {
        order = 4,
        type = 'group',
        name = "史诗钥石",
        get = function(info) return E.db.RhythmBox.MythicPlus[ info[#info] ] end,
        set = function(info, value) E.db.RhythmBox.MythicPlus[ info[#info] ] = value; MP:SendKeystone() end,
        args = {
            ToggleTest = {
                order = 1,
                type = 'execute',
                name = function()
                    if MP.inTestMP then
                        return "停止史诗钥石测试"
                    elseif MP.currentRun then
                        return "结束史诗钥石测试"
                    else
                        return "进行史诗钥石测试"
                    end
                end,
                desc = "模拟进行史诗钥石，测试在史诗钥石地下城中的表现。",
                func = function()
                    if MP.inTestMP then
                        MP:EndTestMP()
                    elseif MP.currentRun then
                        MP.currentRun = nil
                        MP:HideTimer()
                    else
                        MP:StartTestMP()
                    end
                end,
                disabled = function()
                    return C_ChallengeMode_IsChallengeModeActive()
                end,
            },
            Space = {
                order = 10,
                type = "description",
                name = "",
                width = "full",
            },
            GroupFakeKeystone = {
                order = 20,
                type = 'group',
                name = "虚假史诗钥石",
                guiInline = true,
                args = {
                    ChallengeMapID = {
                        name = "钥石地图",
                        order = 21,
                        type = 'select',
                        desc = "伪造的钥石地图",
                        values = {
                            [0] = "不更改",
                        },
                    },
                    Level = {
                        name = "钥石等级",
                        order = 22,
                        type = 'range',
                        desc = "伪造的钥石等级（0为不更改）",
                        min = 0, max = 999, step = 1,
                    },
                    SendChatLink = {
                        order = 23,
                        type = 'execute',
                        name = "发送钥石",
                        desc = "向聊天中发送向队友共享的钥石。",
                        func = function() MP:InsertChatLink() end,
                    },
                    RestoreDefault = {
                        order = 24,
                        type = 'execute',
                        name = "恢复默认",
                        desc = "将本行选项恢复为默认选项。",
                        func = function()
                            E.db.RhythmBox.MythicPlus.ChallengeMapID = 0;
                            E.db.RhythmBox.MythicPlus.Level = 0
                        end,
                    },
                },
            },
        },
    }

    local challengeMapIDs = {}
    for mapID in pairs(MP.database) do
        tinsert(challengeMapIDs, mapID)
    end
    sort(challengeMapIDs)

    for _, challengeMapID in ipairs(challengeMapIDs) do
        E.Options.args.RhythmBox.args.MythicPlus.args.GroupFakeKeystone.args.ChallengeMapID.values[challengeMapID] =
            C_ChallengeMode_GetMapUIInfo(challengeMapID)
    end

end
tinsert(R.Config, MythicPlusOptions)
