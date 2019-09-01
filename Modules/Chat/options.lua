local R, E, L, V, P, G = unpack(select(2, ...))
local C = E:GetModule('RhythmBox_Chat')

P["RhythmBox"]["Chat"] = {
    ["EnhancedReputation"] = true,
    ["AutoTrace"] = true,
    ["ADFilter"] = true,
}

local function ChatOptions()
    E.Options.args.RhythmBox.args.Chat = {
        order = 2,
        type = 'group',
        name = "聊天相关",
        get = function(info) return E.db.RhythmBox.Chat[ info[#info] ] end,
        set = function(info, value) E.db.RhythmBox.Chat[ info[#info] ] = value end,
        args = {
            Install = {
                order = 1,
                type = 'execute',
                name = L["Setup Chat"],
                desc = L["This part of the installation process sets up your chat windows names, positions and colors."],
                func = function() C:InstallChat() end,
            },
            Space = {
                order = 2,
                type = "description",
                name = "",
                width = "full",
            },
            EnhancedReputation = {
                order = 3,
                type = 'toggle',
                name = "增强声望获取文本",
                desc = "在聊天框声望获取文本后补充该阵营目前的声望情况。",
                set = function(info, value) E.db.RhythmBox.Chat[ info[#info] ] = value; C:HandleReputation() end,
            },
            AutoTrace = {
                order = 4,
                type = 'toggle',
                name = "声望追踪",
                desc = "当你获得某个阵营的声望时, 将自动追踪此阵营的声望至经验栏位。",
                disabled = function() return not E.db.RhythmBox.Chat.EnhancedReputation end,
            },
            AdFilter = {
                order = 5,
                type = 'toggle',
                name = "休息区屏蔽广告",
                desc = "在休息区域，屏蔽说、喊和表情。",
                set = function(info, value) E.db.RhythmBox.Chat[ info[#info] ] = value; C:HandleAD() end,
            },
        },
    }
end
tinsert(R.Config, ChatOptions)
