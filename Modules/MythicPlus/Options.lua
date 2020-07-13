local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local MP = R:GetModule('MythicPlus')

-- Lua functions

-- WoW API / Variables

local challengeMapIDs = {
    -- MOP
    2,   -- Temple of the Jade Serpent
    56,  -- Stormstout Brewery
    57,  -- Gate of the Setting Sun
    58,  -- Shado-Pan Monastery
    59,  -- Siege of Niuzao Temple
    60,  -- Mogu'shan Palace
    76,  -- Scholomance
    77,  -- Scarlet Halls
    78,  -- Scarlet Monastery

    -- WoD
    161, -- Skyreach
    163, -- Bloodmaul Slag Mines
    164, -- Auchindoun
    165, -- Shadowmoon Burial Grounds
    166, -- Grimrail Depot
    167, -- Upper Blackrock Spire
    168, -- The Everbloom
    169, -- Iron Docks

    -- LEG
    197, -- Eye of Azshara
    198, -- Darkheart Thicket
    199, -- Black Rook Hold
    200, -- Halls of Valor
    206, -- Neltharion's Lair
    207, -- Vault of the Wardens
    208, -- Maw of Souls
    209, -- The Arcway
    210, -- Court of Stars
    227, -- Return to Karazhan: Lower
    233, -- Cathedral of Eternal Night
    234, -- Return to Karazhan: Upper
    239, -- Seat of the Triumvirate

    -- BfA
    244, -- Atal'Dazar
    245, -- Freehold
    246, -- Tol Dagor
    247, -- The MOTHERLODE!!
    248, -- Waycrest Manor
    249, -- Kings' Rest
    250, -- Temple of Sethraliss
    251, -- The Underrot
    252, -- Shrine of the Storm
    353, -- Siege of Boralus
    369, -- Operation: Mechagon - Junkyard
    370, -- Operation: Mechagon - Workshop
}

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
                    return C_ChallengeMode.IsChallengeModeActive()
                end,
            },
            Space1 = {
                order = 10,
                type = "description",
                name = "",
                width = "full",
            },
            ChallengeMapID = {
                name = "钥石地图",
                order = 11,
                type = 'select',
                desc = "伪造的钥石地图",
                values = {
                    [0] = "不更改",
                },
            },
            Level = {
                name = "钥石等级",
                order = 12,
                type = 'range',
                desc = "伪造的钥石等级（0为不更改）",
                min = 0, max = 999, step = 1,
            },
            SendChatLink = {
                order = 13,
                type = 'execute',
                name = "发送钥石",
                desc = "向聊天中发送向队友共享的钥石。",
                func = function() MP:InsertChatLink() end,
            },
            RestoreDefault = {
                order = 14,
                type = 'execute',
                name = "恢复默认",
                desc = "将本行选项恢复为默认选项。",
                func = function()
                    E.db.RhythmBox.MythicPlus.ChallengeMapID = 0;
                    E.db.RhythmBox.MythicPlus.Level = 0
                end,
            },
        },
    }

    for _, challengeMapID in ipairs(challengeMapIDs) do
        E.Options.args.RhythmBox.args.MythicPlus.args.ChallengeMapID.values[challengeMapID] =
            C_ChallengeMode.GetMapUIInfo(challengeMapID)
    end

end
tinsert(R.Config, MythicPlusOptions)
