local R, E, L, V, P, G = unpack(select(2, ...))
local M = R:GetModule('Misc')
local EDC = R:GetModule('EasyDeleteConfirm')
local FL = R:GetModule('FastLoot')
local TL = R:GetModule('TradeLog')

P["RhythmBox"]["Misc"] = {
    ["EasyDeleteConfirm"] = true,
    ["FastLoot"] = true,
    ["FasterMovieSkip"] = true,
    ["BlockPvP"] = true,
    ["ShowDestination"] = true,
    ["TradeLog"] = true,
    ["TradeLogWhisper"] = false,
}

local function MiscOptions()
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
                desc = "重新设定关键CVar。",
                func = function() M:ConfigCVar() end,
            },
            Space1 = {
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
                hidden = R.Classic,
            },
            ShowDestination = {
                order = 15,
                type = 'toggle',
                name = "显示任务目的地",
                desc = "查看任务详情时，默认显示任务最终目的地。按SHIFT暂时关闭。",
                hidden = R.Classic,
            },
            Space2 = {
                order = 20,
                type = "description",
                name = "",
                width = "full",
            },
            TradeLog = {
                order = 21,
                type = 'toggle',
                name = "交易记录",
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
    }
end
tinsert(R.Config, MiscOptions)
