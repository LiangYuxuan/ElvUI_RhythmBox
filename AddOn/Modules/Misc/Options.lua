local R, E, L, V, P, G = unpack((select(2, ...)))
local M = R:GetModule('Misc')
local EDC = R:GetModule('EasyDeleteConfirm')
local FL = R:GetModule('FastLoot')
local TL = R:GetModule('TradeLog')

-- Lua functions
local _G = _G

-- WoW API / Variables

P["RhythmBox"]["Misc"] = {
    ["EasyDeleteConfirm"] = true,
    ["FastLoot"] = true,
    ["FasterMovieSkip"] = true,
    ["BlockPvP"] = true,
    ["ShowDestination"] = true,
    ["PullTimerSendToChat"] = true,
    ["CannonballTime"] = 6.1,
    ["TradeLog"] = true,
    ["TradeLogWhisper"] = false,
}

R:RegisterOptions(function()
    E.Options.args.RhythmBox.args.Misc = {
        order = 99,
        type = 'group',
        name = "杂项",
        get = function(info) return E.db.RhythmBox.Misc[ info[#info] ] end,
        set = function(info, value) E.db.RhythmBox.Misc[ info[#info] ] = value end,
        args = {
            Install = {
                order = 1,
                type = 'execute',
                name = "设定CVar",
                desc = "在ElvUI安装的基础上，进一步设定CVar。",
                func = function() M:ConfigCVar() end,
            },
            DeveloperConsole = {
                order = 2,
                type = 'execute',
                name = "显示/隐藏控制台",
                func = function() _G.DeveloperConsole:Toggle() end,
            },
            Space = {
                order = 10,
                type = "description",
                name = "",
                width = "full",
            },
            EasyDeleteConfirm = {
                order = 11,
                type = 'toggle',
                name = "自动填入DELETE",
                desc = "删除物品时，自动填入DELETE并提供物品确认。",
                set = function(info, value) E.db.RhythmBox.Misc[ info[#info] ] = value; EDC:HandleEvent() end,
            },
            FastLoot = {
                order = 12,
                type = 'toggle',
                name = "快速拾取",
                desc = "大大加快拾取速度。",
                set = function(info, value) E.db.RhythmBox.Misc[ info[#info] ] = value; FL:Initialize() end,
            },
            FasterMovieSkip = {
                order = 13,
                type = 'toggle',
                name = "快速跳过动画",
                desc = "跳过剧情动画/CG时，自动确认跳过。",
            },
            BlockPvP = {
                order = 14,
                type = 'toggle',
                name = "禁用PvP按钮",
            },
            ShowDestination = {
                order = 15,
                type = 'toggle',
                name = "显示任务目的地",
                desc = "查看任务详情时，默认显示任务最终目的地。按SHIFT暂时关闭。",
            },
            PullTimerSendToChat = {
                order = 16,
                type = 'toggle',
                name = "倒数发送至聊天",
                desc = "将拉怪倒数文本发送至聊天频道。",
            },
            CannonballTime = {
                order = 17,
                type = 'range',
                name = "暗月大炮持续时间",
                desc = "在指定时间后，自动取消暗月大炮的魔法双翼Buff。",
                min = 0, max = 10, step = 0.01,
            },
            GroupTradeLog = {
                order = 20,
                type = 'group',
                name = "交易记录",
                guiInline = true,
                args = {
                    TradeLog = {
                        order = 21,
                        type = 'toggle',
                        name = "聊天框交易记录",
                        desc = "在聊天框记录交易的详细记录。",
                        set = function(info, value) E.db.RhythmBox.Misc[ info[#info] ] = value; TL:Initialize() end,
                    },
                    TradeLogWhisper = {
                        order = 22,
                        type = 'toggle',
                        name = "密语交易记录",
                        desc = "向交易对方密语发送交易记录。",
                        disabled = function() return not E.db.RhythmBox.Misc.TradeLog end,
                    },
                },
            },
        },
    }
end)
