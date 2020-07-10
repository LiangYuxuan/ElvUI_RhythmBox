local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local MP = R:GetModule('MythicPlus')

-- Lua functions

-- WoW API / Variables

local function MythicPlusOptions()
    E.Options.args.RhythmBox.args.MythicPlus = {
        order = 4,
        type = 'group',
        name = "史诗钥石",
        get = function(info) return E.db.RhythmBox.MythicPlus[ info[#info] ] end,
        set = function(info, value) E.db.RhythmBox.MythicPlus[ info[#info] ] = value end,
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
                    return C_ChallengeMode.IsChallengeModeActive()
                end,
            },
        },
    }
end
tinsert(R.Config, MythicPlusOptions)
