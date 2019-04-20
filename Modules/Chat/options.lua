local E, L, V, P, G = unpack(ElvUI);
local R = unpack(select(2, ...))
local C = R.Chat

local function chatTable()
	E.Options.args.RhythmBox.args.chat = {
		order = 11,
		type = 'group',
		name = "聊天相关",
        get = function(info) return E.db.RhythmBox.chat[ info[#info] ] end,
        set = function(info, value) E.db.RhythmBox.chat[ info[#info] ] = value; end,
		args = {
			name = {
				order = 1,
				type = 'header',
				name = "聊天相关设置",
            },
			autoTrace = {
				order = 2,
				type = 'toggle',
				name = "声望追踪",
				desc = "当你获得某个阵营的声望时, 将自动追踪此阵营的声望至经验栏位。",
            },
		},
	}
end
tinsert(R.Config, chatTable)
