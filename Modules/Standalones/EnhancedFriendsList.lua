-- From ProjectAzilroka
-- https://git.tukui.org/Azilroka/ProjectAzilroka/blob/master/Modules/EnhancedFriendsList.lua

local R, E, L, V, P, G = unpack(select(2, ...))
local LSM = E.Libs.LSM
local EFL = R:NewModule('EnhancedFriendsList', 'AceEvent-3.0', 'AceHook-3.0', 'AceTimer-3.0')

-- Lua functions
local format, pairs, select, strmatch, time, unpack = format, pairs, select, strmatch, time, unpack

-- WoW API / Variables
local BNConnected = BNConnected
local C_BattleNet_GetFriendAccountInfo = C_BattleNet and C_BattleNet.GetFriendAccountInfo
local C_FriendList_GetFriendInfoByIndex = C_FriendList.GetFriendInfoByIndex
local GetQuestDifficultyColor = GetQuestDifficultyColor

local AnimateTexCoords = AnimateTexCoords
local FriendsFrame_GetLastOnline = FriendsFrame_GetLastOnline
local FriendsFrame_Update = FriendsFrame_Update
local WrapTextInColorCode = WrapTextInColorCode

local BNET_CLIENT_WOW = BNET_CLIENT_WOW
local BNET_LAST_ONLINE_TIME = BNET_LAST_ONLINE_TIME
local CLASS_ICON_TCOORDS = CLASS_ICON_TCOORDS
local DEFAULT_AFK_MESSAGE = DEFAULT_AFK_MESSAGE
local DEFAULT_DND_MESSAGE = DEFAULT_DND_MESSAGE
local FACTION_ALLIANCE = FACTION_ALLIANCE
local FACTION_HORDE = FACTION_HORDE
local FACTION_STANDING_LABEL4 = FACTION_STANDING_LABEL4
local FRIENDS_BUTTON_TYPE_BNET = FRIENDS_BUTTON_TYPE_BNET
local FRIENDS_BUTTON_TYPE_WOW = FRIENDS_BUTTON_TYPE_WOW
local FRIENDS_LIST_OFFLINE = FRIENDS_LIST_OFFLINE
local FRIENDS_LIST_ONLINE = FRIENDS_LIST_ONLINE
local WOW_PROJECT_CLASSIC = WOW_PROJECT_CLASSIC

local MediaPath = 'Interface/Addons/ElvUI_RhythmBox/Media/EnhancedFriendsList/'
local ONE_MINUTE = 60
local ONE_HOUR = 60 * ONE_MINUTE
local ONE_DAY = 24 * ONE_HOUR
local ONE_MONTH = 30 * ONE_DAY
local ONE_YEAR = 12 * ONE_MONTH

local isBNConnected = BNConnected()

EFL.Icons = {
	Game = {
		Alliance = {
			Name = FACTION_ALLIANCE,
			Order = 1,
			Default = BNet_GetClientTexture(_G.BNET_CLIENT_WOW),
			Launcher = MediaPath .. 'GameIcons/Launcher/Alliance',
		},
		Horde = {
			Name = FACTION_HORDE,
			Order = 2,
			Default = BNet_GetClientTexture(_G.BNET_CLIENT_WOW),
			Launcher = MediaPath .. 'GameIcons/Launcher/Horde',
		},
		Neutral = {
			Name = FACTION_STANDING_LABEL4,
			Order = 3,
			Default = BNet_GetClientTexture(_G.BNET_CLIENT_WOW),
			Launcher = MediaPath .. 'GameIcons/Launcher/WoW',
		},
		App = {
			Name = "App",
			Order = 4,
			Color = '82C5FF',
			Default = BNet_GetClientTexture(_G.BNET_CLIENT_APP),
			Launcher = MediaPath .. 'GameIcons/Launcher/BattleNet',
		},
		BSAp = {
			Name = "移动设备",
			Order = 5,
			Color = '82C5FF',
			Default = BNet_GetClientTexture(_G.BNET_CLIENT_APP),
			Launcher = MediaPath .. 'GameIcons/Launcher/Mobile',
		},
		D3 = {
			Name = "暗黑破坏神 3",
			Color = 'C41F3B',
			Default = BNet_GetClientTexture(_G.BNET_CLIENT_D3),
			Launcher = MediaPath .. 'GameIcons/Launcher/D3',
		},
		WTCG = {
			Name = "炉石传说",
			Color = 'FFB100',
			Default = BNet_GetClientTexture(_G.BNET_CLIENT_WTCG),
			Launcher = MediaPath .. 'GameIcons/Launcher/Hearthstone',
		},
		S1 = {
			Name = "星际争霸",
			Color = 'C495DD',
			Default = BNet_GetClientTexture(_G.BNET_CLIENT_SC),
			Launcher = MediaPath .. 'GameIcons/Launcher/SC',
		},
		S2 = {
			Name = "星际争霸 2",
			Color = 'C495DD',
			Default = BNet_GetClientTexture(_G.BNET_CLIENT_SC2),
			Launcher = MediaPath .. 'GameIcons/Launcher/SC2',
		},
		Hero = {
			Name = "风暴英雄",
			Color = '00CCFF',
			Default = BNet_GetClientTexture(_G.BNET_CLIENT_HEROES),
			Launcher = MediaPath .. 'GameIcons/Launcher/Heroes',
		},
		Pro = {
			Name = "守望先锋",
			Color = 'FFFFFF',
			Default = BNet_GetClientTexture(_G.BNET_CLIENT_OVERWATCH),
			Launcher = MediaPath .. 'GameIcons/Launcher/Overwatch',
		},
		VIPR = {
			Name = "使命召唤 4",
			Color = 'FFFFFF',
			Default = BNet_GetClientTexture(_G.BNET_CLIENT_COD),
			Launcher = MediaPath .. 'GameIcons/Launcher/COD4',
		},
		ODIN = {
			Name = "使命召唤：现代战争",
			Color = 'FFFFFF',
			Default = BNet_GetClientTexture(_G.BNET_CLIENT_COD_MW),
			Launcher = MediaPath .. 'GameIcons/Launcher/CODMW',
		},
		W3 = {
			Name = "魔兽争霸 3：重制版",
			Color = 'FFFFFF',
			Default = BNet_GetClientTexture(_G.BNET_CLIENT_WC3),
			Launcher = MediaPath .. 'GameIcons/Launcher/WC3R',
		},
		LAZR = {
			Name = "使命召唤：现代战争 2",
			Color = 'FFFFFF',
			Default = BNet_GetClientTexture(_G.BNET_CLIENT_COD_MW2),
			Launcher = MediaPath .. 'GameIcons/Launcher/CODMW2',
		},
		ZEUS = {
			Name = "使命召唤：冷战",
			Color = 'FFFFFF',
			Default = BNet_GetClientTexture(_G.BNET_CLIENT_COD_BOCW),
			Launcher = MediaPath .. 'GameIcons/Launcher/CODCW',
		},
	},
	Status = {
		Online = {
			Name = FRIENDS_LIST_ONLINE,
			Order = 1,
			Default = FRIENDS_TEXTURE_ONLINE,
			Square = MediaPath .. 'StatusIcons/Square/Online',
			D3 = MediaPath .. 'StatusIcons/D3/Online',
			Color = {.243, .57, 1},
		},
		Offline = {
			Name = FRIENDS_LIST_OFFLINE,
			Order = 2,
			Default = FRIENDS_TEXTURE_OFFLINE,
			Square = MediaPath .. 'StatusIcons/Square/Offline',
			D3 = MediaPath .. 'StatusIcons/D3/Offline',
			Color = {.486, .518, .541},
		},
		DND = {
			Name = DEFAULT_DND_MESSAGE,
			Order = 3,
			Default = FRIENDS_TEXTURE_DND,
			Square = MediaPath .. 'StatusIcons/Square/DND',
			D3 = MediaPath .. 'StatusIcons/D3/DND',
			Color = {1, 0, 0},
		},
		AFK = {
			Name = DEFAULT_AFK_MESSAGE,
			Order = 4,
			Default = FRIENDS_TEXTURE_AFK,
			Square = MediaPath .. 'StatusIcons/Square/AFK',
			D3 = MediaPath .. 'StatusIcons/D3/AFK',
			Color = {1, 1, 0},
		},
	}
}

local accountInfo = { gameAccountInfo = {} }
function EFL:GetBattleNetInfo(friendIndex)
    accountInfo = C_BattleNet_GetFriendAccountInfo(friendIndex)

    if accountInfo and accountInfo.gameAccountInfo.wowProjectID == WOW_PROJECT_CLASSIC then
        accountInfo.gameAccountInfo.realmDisplayName =
            select(2, strmatch(accountInfo.gameAccountInfo.richPresence, '(.+) %- (.+)'))
    end

    return accountInfo
end

function EFL:CreateTexture(button, type, layer)
    if button.efl and button.efl[type] then
        button.efl[type].Left:SetTexture(LSM:Fetch('statusbar', E.db.RhythmBox.EnhancedFriendsList.Texture))
        button.efl[type].Right:SetTexture(LSM:Fetch('statusbar', E.db.RhythmBox.EnhancedFriendsList.Texture))
        return
    end

    button.efl = button.efl or {}
    button.efl[type] = {}

    button.efl[type].Left = button:CreateTexture(nil, layer)
    button.efl[type].Left:SetWidth(button:GetWidth() / 2)
    button.efl[type].Left:SetHeight(32)
    button.efl[type].Left:SetPoint('LEFT', button, 'CENTER')
    button.efl[type].Left:SetTexture(LSM:Fetch('statusbar', E.db.RhythmBox.EnhancedFriendsList.Texture))

    button.efl[type].Right = button:CreateTexture(nil, layer)
    button.efl[type].Right:SetWidth(button:GetWidth() / 2)
    button.efl[type].Right:SetHeight(32)
    button.efl[type].Right:SetPoint('RIGHT', button, 'CENTER')
    button.efl[type].Right:SetTexture(LSM:Fetch('statusbar', E.db.RhythmBox.EnhancedFriendsList.Texture))
end

function EFL:UpdateFriends(button)
    local nameText, infoText
    local status = 'Offline'
    if button.buttonType == FRIENDS_BUTTON_TYPE_WOW then
        local info = C_FriendList_GetFriendInfoByIndex(button.id)
        if info.connected then
            local name, level, class = info.name, info.level, info.className
            local classFilename = E:UnlocalizedClassName(class)
            local classColor = E:ClassColor(classFilename)
            status = info.dnd and 'DND' or info.afk and 'AFK' or 'Online'
            local diff = level ~= 0 and format('FF%02x%02x%02x', GetQuestDifficultyColor(level).r * 255, GetQuestDifficultyColor(level).g * 255, GetQuestDifficultyColor(level).b * 255) or 'FFFFFFFF'
            nameText = format('%s, %s', WrapTextInColorCode(name, classColor.colorStr), WrapTextInColorCode(level, diff))
            infoText = info.area

            button.gameIcon:Show()
            button.gameIcon:SetTexture('Interface/WorldStateFrame/Icons-Classes')
            button.gameIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[classFilename]))
        else
            nameText = info.name
        end
        button.status:SetTexture(EFL.Icons.Status[status][E.db.RhythmBox.EnhancedFriendsList.StatusIconPack])
    elseif button.buttonType == FRIENDS_BUTTON_TYPE_BNET and isBNConnected then
        local info = EFL:GetBattleNetInfo(button.id)
        if info then
            nameText = info.accountName
            infoText = accountInfo.gameAccountInfo.richPresence ~= '' and accountInfo.gameAccountInfo.richPresence or "移动版"
            if info.gameAccountInfo.isOnline then
                local client = info.gameAccountInfo.clientProgram
                status = (info.isDND or info.gameAccountInfo.isGameBusy) and 'DND' or ((info.isAFK or info.gameAccountInfo.isGameAFK) and 'AFK' or 'Online')

                if client == BNET_CLIENT_WOW then
                    local level = info.gameAccountInfo.characterLevel
                    local characterName = info.gameAccountInfo.characterName
                    local classColor = E:ClassColor(E:UnlocalizedClassName(info.gameAccountInfo.className))
                    if characterName and classColor then
                        local diff = level ~= 0 and format('FF%02x%02x%02x', GetQuestDifficultyColor(level).r * 255, GetQuestDifficultyColor(level).g * 255, GetQuestDifficultyColor(level).b * 255) or 'FFFFFFFF'
                        nameText = format('%s |cFFFFFFFF(|r%s, %s|cFFFFFFFF)|r', nameText, WrapTextInColorCode(characterName, classColor.colorStr), WrapTextInColorCode(level, diff))
                    end

                    if info.gameAccountInfo.wowProjectID == WOW_PROJECT_CLASSIC and info.gameAccountInfo.realmDisplayName ~= E.myrealm then
                        infoText = format('%s - %s', info.gameAccountInfo.areaName or "", info.gameAccountInfo.realmDisplayName or "")
                    elseif info.gameAccountInfo.realmDisplayName == E.myrealm then
                        infoText = info.gameAccountInfo.areaName
                    end

                    local faction = info.gameAccountInfo.factionName
                    button.gameIcon:SetTexture(faction and EFL.Icons.Game[faction][E.db.RhythmBox.EnhancedFriendsList[faction]] or EFL.Icons.Game.Neutral.Launcher)
                else
                    if not EFL.Icons.Game[client] then client = 'BSAp' end
                    nameText = format('|cFF%s%s|r', EFL.Icons.Game[client].Color or 'FFFFFF', nameText)
                    button.gameIcon:SetTexture(EFL.Icons.Game[client][E.db.RhythmBox.EnhancedFriendsList[client]])
                end

                button.gameIcon:SetTexCoord(0, 1, 0, 1)
                button.gameIcon:SetDrawLayer('ARTWORK')
                button.gameIcon:SetAlpha(1)
            else
                local lastOnline = info.lastOnlineTime
                infoText = (not lastOnline or lastOnline == 0 or time() - lastOnline >= ONE_YEAR) and FRIENDS_LIST_OFFLINE or format(BNET_LAST_ONLINE_TIME, FriendsFrame_GetLastOnline(lastOnline))
            end
            button.status:SetTexture(EFL.Icons.Status[status][E.db.RhythmBox.EnhancedFriendsList.StatusIconPack])
        end
    end

    if button.summonButton:IsShown() then
        button.gameIcon:SetPoint('TOPRIGHT', -50, -2)
    else
        button.gameIcon:SetPoint('TOPRIGHT', -21, -2)
    end

    if not button.isUpdateHooked then
        button:HookScript('OnUpdate', function(self, elapsed)
            if button.gameIcon:GetTexture() == MediaPath .. 'GameIcons/Bnet' then
                AnimateTexCoords(self.gameIcon, 512, 256, 64, 64, 25, elapsed, 0.02)
            end
        end)
        button.isUpdateHooked = true
    end

    if nameText then button.name:SetText(nameText) end
    if infoText then button.info:SetText(infoText) end

    local r, g, b = unpack(EFL.Icons.Status[status].Color)
    if E.db.RhythmBox.EnhancedFriendsList.ShowStatusBackground then
        EFL:CreateTexture(button, 'background', 'BACKGROUND')

        button.efl.background.Left:SetGradientAlpha('Horizontal', r, g, b, .15, r, g, b, 0)
        button.efl.background.Right:SetGradientAlpha('Horizontal', r, g, b, .0, r, g, b, .15)

        button.background:Hide()
    end

    if E.db.RhythmBox.EnhancedFriendsList.ShowStatusHighlight then
        EFL:CreateTexture(button, 'highlight', 'HIGHLIGHT')

        button.efl.highlight.Left:SetGradientAlpha('Horizontal', r, g, b, .25, r, g, b, 0)
        button.efl.highlight.Right:SetGradientAlpha('Horizontal', r, g, b, .0, r, g, b, .25)

        button.highlight:SetVertexColor(0, 0, 0, 0)
    end

    button.name:SetFont(LSM:Fetch('font', E.db.RhythmBox.EnhancedFriendsList.NameFont), E.db.RhythmBox.EnhancedFriendsList.NameFontSize, E.db.RhythmBox.EnhancedFriendsList.NameFontFlag)
    button.info:SetFont(LSM:Fetch('font', E.db.RhythmBox.EnhancedFriendsList.InfoFont), E.db.RhythmBox.EnhancedFriendsList.InfoFontSize, E.db.RhythmBox.EnhancedFriendsList.InfoFontFlag)

    if button.Favorite and button.Favorite:IsShown() then
        button.Favorite:ClearAllPoints()
        button.Favorite:SetPoint('TOPLEFT', button.name, 'TOPLEFT', button.name:GetStringWidth(), 0);
    end
end

function EFL:HandleBN()
    isBNConnected = BNConnected()
end

P["RhythmBox"]["EnhancedFriendsList"] = {
    ["Enable"] = true,
    ["NameFont"] = E.db.general.font,
    ["NameFontSize"] = 13,
    ["NameFontFlag"] = "OUTLINE",
    ["InfoFont"] = E.db.general.font,
    ["InfoFontSize"] = 12,
    ["InfoFontFlag"] = "OUTLINE",
    ["StatusIconPack"] = "Default",
    ["ShowStatusHighlight"] = true,
    ["ShowStatusBackground"] = false,
    ["Texture"] = "Solid",
}
for GameIcon in pairs(EFL.Icons.Game) do
    P["RhythmBox"]["EnhancedFriendsList"][GameIcon] = 'Launcher'
end

local function FriendsListOptions()
    E.Options.args.RhythmBox.args.EnhancedFriendsList = {
        order = 12,
        type = 'group',
        name = "增强好友列表",
        get = function(info) return E.db.RhythmBox.EnhancedFriendsList[info[#info]] end,
        set = function(info, value) E.db.RhythmBox.EnhancedFriendsList[info[#info]] = value end,
        args = {
            Enable = {
                order = 1,
                type = 'toggle',
                name = "启用",
                set = function(info, value) E.db.RhythmBox.EnhancedFriendsList[info[#info]] = value; E:StaticPopup_Show('PRIVATE_RL') end,
            },
            General = {
                name = "通用",
                order = 2,
                type = 'group',
                get = function(info) return E.db.RhythmBox.EnhancedFriendsList[info[#info]] end,
                set = function(info, value) E.db.RhythmBox.EnhancedFriendsList[info[#info]] = value; FriendsFrame_Update() end,
                args = {
                    NameFont = {
                        name = "名字字体",
                        order = 1,
                        type = 'select', dialogControl = 'LSM30_Font',
                        desc = "用于 RealID / 角色名 / 等级的字体",
                        values = LSM:HashTable('font'),
                    },
                    NameFontSize = {
                        name = "名字字体大小",
                        order = 2,
                        type = 'range',
                        desc = "用于 RealID / 角色名 / 等级的字体大小",
                        min = 6, max = 22, step = 1,
                    },
                    NameFontFlag = {
                        name = "名字描边",
                        order = 3,
                        type = 'select',
                        desc = "用于 RealID / 角色名 / 等级的字体描边",
                        values = {
                            ['NONE'] = "NONE",
                            ['OUTLINE'] = "OUTLINE",
                            ['MONOCHROME'] = "MONOCHROME",
                            ['MONOCHROMEOUTLINE'] = "MONOCHROMEOUTLINE",
                            ['THICKOUTLINE'] = "THICKOUTLINE",
                        }
                    },
                    InfoFont = {
                        type = 'select', dialogControl = 'LSM30_Font',
                        name = "信息字体",
                        order = 4,
                        desc = "用于 地区 / 服务器名 的字体",
                        values = LSM:HashTable('font'),
                    },
                    InfoFontSize = {
                        name = "信息字体大小",
                        order = 5,
                        desc = "用于 地区 / 服务器名 的字体大小",
                        type = 'range',
                        min = 6, max = 22, step = 1,
                    },
                    InfoFontFlag = {
                        name = "信息字体描边",
                        order = 6,
                        desc = "用于 地区 / 服务器名 的字体描边",
                        type = 'select',
                        values = {
                            ['NONE'] = "NONE",
                            ['OUTLINE'] = "OUTLINE",
                            ['MONOCHROME'] = "MONOCHROME",
                            ['MONOCHROMEOUTLINE'] = "MONOCHROMEOUTLINE",
                            ['THICKOUTLINE'] = "THICKOUTLINE",
                        },
                    },
                    StatusIconPack = {
                        name = "状态图标包",
                        order = 7,
                        desc = "不同的状态图标",
                        type = 'select',
                        values = {
                            ['Default'] = "默认",
                            ['Square'] = "方块风格",
                            ['D3'] = "暗黑破坏神 III",
                        },
                    },
                    ShowStatusBackground = {
                        type = 'toggle',
                        order = 8,
                        name = "显示状态背景",
                    },
                    ShowStatusHighlight = {
                        type = 'toggle',
                        order = 9,
                        name = "显示状态高光",
                    },
                    Texture = {
                        order = 10,
                        type = 'select', dialogControl = 'LSM30_Statusbar',
                        name = "材质",
                        values = LSM:HashTable('statusbar'),
                    },
                },
            },
            GameIcons = {
                name = "游戏图标",
                order = 3,
                type = 'group',
                get = function(info) return E.db.RhythmBox.EnhancedFriendsList[info[#info]] end,
                set = function(info, value) E.db.RhythmBox.EnhancedFriendsList[info[#info]] = value; FriendsFrame_Update() end,
                args = {},
            },
            GameIconsPreview = {
                name = "游戏图标预览",
                order = 4,
                type = 'group',
                args = {},
            },
            StatusIcons = {
                name = "状态图标预览",
                order = 5,
                type = 'group',
                args = {},
            },
        },
    }

    for key, value in pairs(EFL.Icons.Game) do
        E.Options.args.RhythmBox.args.EnhancedFriendsList.args.GameIcons.args[key] = {
            name = value.Name .. " 图标",
            order = value.Order,
            type = 'select',
            values = {
                ['Default'] = "默认",
                ['Launcher'] = "战网风格",
            },
        }
        E.Options.args.RhythmBox.args.EnhancedFriendsList.args.GameIconsPreview.args[key] = {
            order = value.Order,
            type = 'execute',
            name = value.Name,
            func = function() return end,
            image = function(info) return EFL.Icons.Game[info[#info]][E.db.RhythmBox.EnhancedFriendsList[key]], 32, 32 end,
        }
    end

    for Key, Value in pairs(EFL.Icons.Status) do
        E.Options.args.RhythmBox.args.EnhancedFriendsList.args.StatusIcons.args[Key] = {
            order = Value.Order,
            type = 'execute',
            name = Value.Name,
            func = function() return end,
            image = function(info) return EFL.Icons.Status[info[#info]][E.db.RhythmBox.EnhancedFriendsList.StatusIconPack], 16, 16 end,
        }
    end
end
tinsert(R.Config, FriendsListOptions)

function EFL:Initialize()
    EFL:RegisterEvent('BN_CONNECTED', 'HandleBN')
    EFL:RegisterEvent('BN_DISCONNECTED', 'HandleBN')

    self:SecureHook('FriendsFrame_UpdateFriendButton', 'UpdateFriends')
end

R:RegisterModule(EFL:GetName())
