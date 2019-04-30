local R, E, L, V, P, G = unpack(select(2, ...))
local C = R.Chat

local function chatTable()
    E.Options.args.RhythmBox.args.chat = {
        order = 11,
        type = 'group',
        name = "聊天相关",
        get = function(info) return E.db.RhythmBox.chat[ info[#info] ] end,
        set = function(info, value) E.db.RhythmBox.chat[ info[#info] ] = value end,
        args = {
            name = {
                order = 1,
                type = 'header',
                name = "聊天相关设置",
            },
            enhancedReputation = {
                order = 2,
                type = 'toggle',
                name = "增强声望获取文本",
                desc = "在聊天框声望获取文本后补充该阵营目前的声望情况。",
                set = function(info, value) E.db.RhythmBox.chat[ info[#info] ] = value; C:HandleReputation() end,
            },
            autoTrace = {
                order = 3,
                type = 'toggle',
                name = "声望追踪",
                desc = "当你获得某个阵营的声望时, 将自动追踪此阵营的声望至经验栏位。",
                disabled = function() return not E.db.RhythmBox.chat.enhancedReputation end,
            },
            adFilter = {
                order = 4,
                type = 'toggle',
                name = "休息区屏蔽广告",
                desc = "在休息区域，屏蔽说、喊和表情。",
                set = function(info, value) E.db.RhythmBox.chat[ info[#info] ] = value; C:HandleAD() end,
            },
        },
    }
end
tinsert(R.Config, chatTable)
