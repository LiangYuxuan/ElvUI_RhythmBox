local R, E, L, V, P, G = unpack(select(2, ...))
local C = R:GetModule('Chat')

P["RhythmBox"]["Chat"] = {
    ["ADFilter"] = false,
    ["EnhancedLoot"] = true,
    ["EnhancedReputation"] = true,
    ["AutoTrace"] = true,
    ["EnhancedTab"] = true,
    ["UseOfficer"] = false,
    ["WhisperCycle"] = false,
}

local function ChatOptions()
    E.Options.args.RhythmBox.args.Chat = {
        order = 2,
        type = 'group',
        name = "聊天与聊天框",
        get = function(info) return E.db.RhythmBox.Chat[ info[#info] ] end,
        set = function(info, value) E.db.RhythmBox.Chat[ info[#info] ] = value end,
        args = {
            Install = {
                order = 1,
                type = 'execute',
                name = "设定聊天框",
                desc = "此安装步骤将会设定聊天框的名称、位置和颜色。",
                func = function() C:InstallChat() end,
            },
            Space = {
                order = 10,
                type = "description",
                name = "",
                width = "full",
            },
            ADFilter = {
                order = 11,
                type = 'toggle',
                name = "休息区屏蔽广告",
                desc = "在休息区域，屏蔽说、喊和表情，防止广告刷屏。",
                set = function(info, value) E.db.RhythmBox.Chat[ info[#info] ] = value; C:ADFilter() end,
            },
            EnhancedLoot = {
                order = 12,
                type = 'toggle',
                name = "增强战利品获取",
                desc = "对战利品获取文本角色名染色，并对高价值战利品允许鼠标点击角色名密语。",
                set = function(info, value) E.db.RhythmBox.Chat[ info[#info] ] = value; C:Loot() end,
            },
            GroupReputation = {
                order = 20,
                type = 'group',
                name = "声望获取",
                guiInline = true,
                args = {
                    EnhancedReputation = {
                        order = 21,
                        type = 'toggle',
                        name = "增强声望获取文本",
                        desc = "在聊天框声望获取文本后补充该阵营目前的声望情况。",
                        set = function(info, value) E.db.RhythmBox.Chat[ info[#info] ] = value; C:Reputation() end,
                    },
                    AutoTrace = {
                        order = 22,
                        type = 'toggle',
                        name = "声望追踪",
                        desc = "获得某个阵营的声望时, 自动追踪此阵营的声望。",
                        disabled = function() return not E.db.RhythmBox.Chat.EnhancedReputation end,
                    },
                },
            },
            GroupEnhancedTab = {
                order = 30,
                type = 'group',
                name = "增强 Tab",
                guiInline = true,
                args = {
                    EnhancedTab = {
                        order = 31,
                        type = 'toggle',
                        name = "Tab 切换频道",
                        desc = "使用 Tab 键快速切换频道。",
                        set = function(info, value) E.db.RhythmBox.Chat[ info[#info] ] = value; C:EnhancedTab() end,
                    },
                    UseOfficer = {
                        order = 32,
                        type = 'toggle',
                        name = "包括公会官员频道",
                        disabled = function() return not E.db.RhythmBox.Chat.EnhancedTab end,
                    },
                    WhisperCycle = {
                        order = 33,
                        type = 'toggle',
                        name = "密语独立循环",
                        disabled = function() return not E.db.RhythmBox.Chat.EnhancedTab end,
                    },
                },
            },
        },
    }
end
tinsert(R.Config, ChatOptions)
