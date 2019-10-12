-- From ProjectAzilroka
-- https://git.tukui.org/Azilroka/ProjectAzilroka/blob/master/Modules/EnhancedFriendsList.lua

local R, E, L, V, P, G = unpack(select(2, ...))
local LSM = E.Libs.LSM
local EFL = R:NewModule('EnhancedFriendList', 'AceEvent-3.0', 'AceHook-3.0', 'AceTimer-3.0')

-- Lua functions
local format, pairs, strsplit, time, unpack = format, pairs, strsplit, time, unpack

-- WoW API / Variables
local BNGetFriendInfo = BNGetFriendInfo
local BNGetGameAccountInfo = BNGetGameAccountInfo
local C_BattleNet_GetFriendAccountInfo = C_BattleNet and C_BattleNet.GetFriendAccountInfo
local C_FriendList_GetFriendInfoByIndex = C_FriendList.GetFriendInfoByIndex
local GetQuestDifficultyColor = GetQuestDifficultyColor

local AnimateTexCoords = AnimateTexCoords
local BNet_GetClientTexture = BNet_GetClientTexture
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
local WOW_PROJECT_MAINLINE = WOW_PROJECT_MAINLINE

local MediaPath = 'Interface/Addons/ElvUI_RhythmBox/Media/FriendList/'
local ONE_MINUTE = 60
local ONE_HOUR = 60 * ONE_MINUTE
local ONE_DAY = 24 * ONE_HOUR
local ONE_MONTH = 30 * ONE_DAY
local ONE_YEAR = 12 * ONE_MONTH

EFL.Icons = {
    Game = {
        Alliance = {
            Name = FACTION_ALLIANCE,
            Order = 1,
            Default = BNet_GetClientTexture(BNET_CLIENT_WOW),
            BlizzardChat = [[Interface\ChatFrame\UI-ChatIcon-WoW]],
            Flat = MediaPath..[[GameIcons\Flat\Alliance]],
            Gloss = MediaPath..[[GameIcons\Gloss\Alliance]],
            Launcher = MediaPath..[[GameIcons\Launcher\Alliance]],
        },
        Horde = {
            Name = FACTION_HORDE,
            Order = 2,
            Default = BNet_GetClientTexture(BNET_CLIENT_WOW),
            BlizzardChat = [[Interface\ChatFrame\UI-ChatIcon-WoW]],
            Flat = MediaPath..[[GameIcons\Flat\Horde]],
            Gloss = MediaPath..[[GameIcons\Gloss\Horde]],
            Launcher = MediaPath..[[GameIcons\Launcher\Horde]],
        },
        Neutral = {
            Name = FACTION_STANDING_LABEL4,
            Order = 3,
            Default = BNet_GetClientTexture(BNET_CLIENT_WOW),
            BlizzardChat = [[Interface\ChatFrame\UI-ChatIcon-WoW]],
            Flat = MediaPath..[[GameIcons\Flat\WoW]],
            Gloss = MediaPath..[[GameIcons\Gloss\WoW]],
            Launcher = MediaPath..[[GameIcons\Launcher\WoW]],
        },
        D3 = {
            Name = "暗黑破坏神 III",
            Order = 4,
            Color = 'C41F3B',
            Default = BNet_GetClientTexture(BNET_CLIENT_D3),
            BlizzardChat = [[Interface\ChatFrame\UI-ChatIcon-D3]],
            Flat = MediaPath..[[GameIcons\Flat\D3]],
            Gloss = MediaPath..[[GameIcons\Gloss\D3]],
            Launcher = MediaPath..[[GameIcons\Launcher\D3]],
        },
        WTCG = {
            Name = "炉石传说",
            Order = 5,
            Color = 'FFB100',
            Default = BNet_GetClientTexture(BNET_CLIENT_WTCG),
            BlizzardChat = [[Interface\ChatFrame\UI-ChatIcon-WTCG]],
            Flat = MediaPath..[[GameIcons\Flat\Hearthstone]],
            Gloss = MediaPath..[[GameIcons\Gloss\Hearthstone]],
            Launcher = MediaPath..[[GameIcons\Launcher\Hearthstone]],
        },
        S1 = {
            Name = "星际争霸",
            Order = 6,
            Color = 'C495DD',
            Default = BNet_GetClientTexture(BNET_CLIENT_SC),
            BlizzardChat = [[Interface\ChatFrame\UI-ChatIcon-SC]],
            Flat = MediaPath..[[GameIcons\Flat\SC]],
            Gloss = MediaPath..[[GameIcons\Gloss\SC]],
            Launcher = MediaPath..[[GameIcons\Launcher\SC]],
        },
        S2 = {
            Name = "星际争霸 II",
            Order = 7,
            Color = 'C495DD',
            Default = BNet_GetClientTexture(BNET_CLIENT_SC2),
            BlizzardChat = [[Interface\ChatFrame\UI-ChatIcon-SC2]],
            Flat = MediaPath..[[GameIcons\Flat\SC2]],
            Gloss = MediaPath..[[GameIcons\Gloss\SC2]],
            Launcher = MediaPath..[[GameIcons\Launcher\SC2]],
        },
        App = {
            Name = "应用",
            Order = 8,
            Color = '82C5FF',
            Default = BNet_GetClientTexture(BNET_CLIENT_APP),
            BlizzardChat = [[Interface\ChatFrame\UI-ChatIcon-Battlenet]],
            Flat = MediaPath..[[GameIcons\Flat\BattleNet]],
            Gloss = MediaPath..[[GameIcons\Gloss\BattleNet]],
            Launcher = MediaPath..[[GameIcons\Launcher\BattleNet]],
            Animated = MediaPath..[[GameIcons\Bnet]],
        },
        BSAp = {
            Name = "手机",
            Order = 9,
            Color = '82C5FF',
            Default = BNet_GetClientTexture(BNET_CLIENT_APP),
            BlizzardChat = 'Interface\\ChatFrame\\UI-ChatIcon-Battlenet',
            Flat = MediaPath..'GameIcons\\Flat\\BattleNet',
            Gloss = MediaPath..'GameIcons\\Gloss\\BattleNet',
            Launcher = MediaPath..'GameIcons\\Launcher\\BattleNet',
            Animated = MediaPath..'GameIcons\\Bnet',
        },
        Hero = {
            Name = "风暴英雄",
            Order = 10,
            Color = '00CCFF',
            Default = BNet_GetClientTexture(BNET_CLIENT_HEROES),
            BlizzardChat = [[Interface\ChatFrame\UI-ChatIcon-HotS]],
            Flat = MediaPath..[[GameIcons\Flat\Heroes]],
            Gloss = MediaPath..[[GameIcons\Gloss\Heroes]],
            Launcher = MediaPath..[[GameIcons\Launcher\Heroes]],
        },
        Pro = {
            Name = "守望先锋",
            Order = 11,
            Color = 'FFFFFF',
            Default = BNet_GetClientTexture(BNET_CLIENT_OVERWATCH),
            BlizzardChat = [[Interface\ChatFrame\UI-ChatIcon-Overwatch]],
            Flat = MediaPath..[[GameIcons\Flat\Overwatch]],
            Gloss = MediaPath..[[GameIcons\Gloss\Overwatch]],
            Launcher = MediaPath..[[GameIcons\Launcher\Overwatch]],
        },
        DST2 = {
            Name = "命运 2",
            Order = 12,
            Color = 'FFFFFF',
            Default = BNet_GetClientTexture(BNET_CLIENT_DESTINY2),
            BlizzardChat = [[Interface\ChatFrame\UI-ChatIcon-Destiny2]],
            Flat = MediaPath..[[GameIcons\Launcher\Destiny2]],
            Gloss = MediaPath..[[GameIcons\Launcher\Destiny2]],
            Launcher = MediaPath..[[GameIcons\Launcher\Destiny2]],
        },
        VIPR = {
            Name = "使命召唤 4",
            Order = 13,
            Color = 'FFFFFF',
            Default = BNet_GetClientTexture(BNET_CLIENT_COD),
            BlizzardChat = [[Interface\ChatFrame\UI-ChatIcon-CallOfDutyBlackOps4]],
            Flat = MediaPath..[[GameIcons\Launcher\COD4]],
            Gloss = MediaPath..[[GameIcons\Launcher\COD4]],
            Launcher = MediaPath..[[GameIcons\Launcher\COD4]],
        },
    },
    Status = {
        Online = {
            Name = FRIENDS_LIST_ONLINE,
            Order = 1,
            Default = FRIENDS_TEXTURE_ONLINE,
            Square = MediaPath..[[StatusIcons\Square\Online]],
            D3 = MediaPath..[[StatusIcons\D3\Online]],
            Color = {.243, .57, 1},
        },
        Offline = {
            Name = FRIENDS_LIST_OFFLINE,
            Order = 2,
            Default = FRIENDS_TEXTURE_OFFLINE,
            Square = MediaPath..[[StatusIcons\Square\Offline]],
            D3 = MediaPath..[[StatusIcons\D3\Offline]],
            Color = {.486, .518, .541},
        },
        DND = {
            Name = DEFAULT_DND_MESSAGE,
            Order = 3,
            Default = FRIENDS_TEXTURE_DND,
            Square = MediaPath..[[StatusIcons\Square\DND]],
            D3 = MediaPath..[[StatusIcons\D3\DND]],
            Color = {1, 0, 0},
        },
        AFK = {
            Name = DEFAULT_AFK_MESSAGE,
            Order = 4,
            Default = FRIENDS_TEXTURE_AFK,
            Square = MediaPath..[[StatusIcons\Square\AFK]],
            D3 = MediaPath..[[StatusIcons\D3\AFK]],
            Color = {1, 1, 0},
        },
    }
}

-- /dump "["..select(2, strsplit('-', UnitGUID('player'))) .. "] = '" ..GetRealmName().."'"
EFL.ClassicServerNameByID = {
    [4511] = '沙尔图拉',
    [4522] = '雷霆之击',
    [4523] = '法尔班克斯',
    [4533] = '维希度斯',
    [4534] = '帕奇维克',
    [4535] = '比格沃斯',
    [4707] = '霜语',
    [4708] = '水晶之牙',
    [4709] = '维克洛尔',
    [4711] = '巴罗夫',
    [4768] = '毁灭之刃',
    [4771] = '伦鲁迪洛尔',
    [4775] = '骨火',
    [4778] = '祈福',
    [4780] = '觅心者',
    [4788] = '巨人追猎者',
    [4790] = '奎尔塞拉',
    [4792] = '阿什坎迪',
    [4818] = '艾隆纳亚',
    [4821] = '沙顶',
    [4824] = '怒炉',
    [4829] = '安娜丝塔丽',
    [4832] = '雷德',
}

local accountInfo = { gameAccountInfo = {} }
function EFL:GetBattleNetInfo(friendIndex)
    if R.Classic then
        local bnetIDAccount, accountName, battleTag, isBattleTag, _, bnetIDGameAccount, _, isOnline, lastOnline, isBnetAFK, isBnetDND, messageText, noteText, _, messageTime, _, _, canSummonFriend, isFavorite = BNGetFriendInfo(friendIndex)

        if not bnetIDGameAccount then return end

        local hasFocus, characterName, client, realmName, realmID, faction, race, class, _, zoneName, level, gameText, _, _, _, _, _, isGameAFK, isGameBusy, guid, wowProjectID, mobile = BNGetGameAccountInfo(bnetIDGameAccount)

        -- realm id helper
        if realmName and realmName ~= '' and not self.ClassicServerNameByID[realmID] then
            self.ClassicServerNameByID[realmID] = realmName
            R:Print("[%d] = '%s',", realmID, realmName)
        end

        accountInfo.bnetAccountID = bnetIDAccount
        accountInfo.accountName = accountName
        accountInfo.battleTag = battleTag
        accountInfo.isBattleTagFriend = isBattleTag
        accountInfo.isDND = isBnetDND
        accountInfo.isAFK = isBnetAFK
        accountInfo.isFriend = true
        accountInfo.isFavorite = isFavorite
        accountInfo.note = noteText
        accountInfo.rafLinkType = 0
        accountInfo.appearOffline = false
        accountInfo.customMessage = messageText
        accountInfo.lastOnlineTime = lastOnline
        accountInfo.customMessageTime = messageTime

        accountInfo.gameAccountInfo.clientProgram = client or "App"
        accountInfo.gameAccountInfo.richPresence = gameText
        accountInfo.gameAccountInfo.gameAccountID = bnetIDGameAccount
        accountInfo.gameAccountInfo.isOnline = isOnline
        accountInfo.gameAccountInfo.isGameAFK = isGameAFK
        accountInfo.gameAccountInfo.isGameBusy = isGameBusy
        accountInfo.gameAccountInfo.isWowMobile = mobile
        accountInfo.gameAccountInfo.hasFocus = hasFocus
        accountInfo.gameAccountInfo.canSummon = canSummonFriend

        if wowProjectID == WOW_PROJECT_MAINLINE then
            zoneName, realmName = strsplit('-', gameText)
        end

        if client == BNET_CLIENT_WOW then
            accountInfo.gameAccountInfo.characterName = characterName
            accountInfo.gameAccountInfo.factionName = faction ~= '' and faction or nil
            accountInfo.gameAccountInfo.playerGuid = guid
            accountInfo.gameAccountInfo.wowProjectID = wowProjectID
            accountInfo.gameAccountInfo.realmID = realmID
            accountInfo.gameAccountInfo.realmDisplayName = realmName
            accountInfo.gameAccountInfo.realmName = realmName
            accountInfo.gameAccountInfo.areaName = zoneName
            accountInfo.gameAccountInfo.className = class
            accountInfo.gameAccountInfo.characterLevel = level
            accountInfo.gameAccountInfo.raceName = race
        else
            accountInfo.gameAccountInfo.characterName = nil
            accountInfo.gameAccountInfo.factionName = nil
            accountInfo.gameAccountInfo.playerGuid = nil
            accountInfo.gameAccountInfo.wowProjectID = nil
            accountInfo.gameAccountInfo.realmID = nil
            accountInfo.gameAccountInfo.realmDisplayName = nil
            accountInfo.gameAccountInfo.realmName = nil
            accountInfo.gameAccountInfo.areaName = nil
            accountInfo.gameAccountInfo.className = nil
            accountInfo.gameAccountInfo.characterLevel = nil
            accountInfo.gameAccountInfo.raceName = nil
        end

        return accountInfo
    else
        accountInfo = C_BattleNet_GetFriendAccountInfo(friendIndex)

        if accountInfo.gameAccountInfo.wowProjectID == WOW_PROJECT_CLASSIC then
            accountInfo.gameAccountInfo.realmDisplayName = EFL.ClassicServerNameByID[accountInfo.gameAccountInfo.realmID] or accountInfo.gameAccountInfo.realmID
        end

        return accountInfo
    end
end

function EFL:CreateTexture(button, type, layer)
    if button.efl and button.efl[type] then
        button.efl[type].Left:SetTexture(LSM:Fetch('statusbar', E.db.RhythmBox.EnhancedFriendList.Texture))
        button.efl[type].Right:SetTexture(LSM:Fetch('statusbar', E.db.RhythmBox.EnhancedFriendList.Texture))
        return
    end

    button.efl = button.efl or {}
    button.efl[type] = {}

    button.efl[type].Left = button:CreateTexture(nil, layer)
    button.efl[type].Left:SetWidth(button:GetWidth() / 2)
    button.efl[type].Left:SetHeight(32)
    button.efl[type].Left:SetPoint('LEFT', button, 'CENTER')
    button.efl[type].Left:SetTexture(LSM:Fetch('statusbar', E.db.RhythmBox.EnhancedFriendList.Texture))

    button.efl[type].Right = button:CreateTexture(nil, layer)
    button.efl[type].Right:SetWidth(button:GetWidth() / 2)
    button.efl[type].Right:SetHeight(32)
    button.efl[type].Right:SetPoint('RIGHT', button, 'CENTER')
    button.efl[type].Right:SetTexture(LSM:Fetch('statusbar', E.db.RhythmBox.EnhancedFriendList.Texture))
end

function EFL:UpdateFriends(button)
    local nameText, infoText
    local status = 'Offline'
    if button.buttonType == FRIENDS_BUTTON_TYPE_WOW then
        local info = C_FriendList_GetFriendInfoByIndex(button.id)
        if info.connected then
            local name, level, class = info.name, info.level, info.className
            local classColor = R:ClassColorCode(class)
            status = info.dnd and 'DND' or info.afk and 'AFK' or 'Online'
            local diff = level ~= 0 and format('FF%02x%02x%02x', GetQuestDifficultyColor(level).r * 255, GetQuestDifficultyColor(level).g * 255, GetQuestDifficultyColor(level).b * 255) or 'FFFFFFFF'
            nameText = format('%s, %s', WrapTextInColorCode(name, classColor), WrapTextInColorCode(level, diff))
            infoText = info.area

            button.gameIcon:Show()
            button.gameIcon:SetTexture('Interface/WorldStateFrame/Icons-Classes')
            button.gameIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[R:GetClassName(class)]))
        else
            nameText = info.name
        end
        button.status:SetTexture(EFL.Icons.Status[status][E.db.RhythmBox.EnhancedFriendList.StatusIconPack])
    elseif button.buttonType == FRIENDS_BUTTON_TYPE_BNET then
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
                    local classcolor = R:ClassColorCode(info.gameAccountInfo.className)
                    if characterName then
                        local diff = level ~= 0 and format('FF%02x%02x%02x', GetQuestDifficultyColor(level).r * 255, GetQuestDifficultyColor(level).g * 255, GetQuestDifficultyColor(level).b * 255) or 'FFFFFFFF'
                        nameText = format('%s |cFFFFFFFF(|r%s, %s|cFFFFFFFF)|r', nameText, WrapTextInColorCode(characterName, classcolor), WrapTextInColorCode(level, diff))
                    end

                    if info.gameAccountInfo.wowProjectID == WOW_PROJECT_CLASSIC and info.gameAccountInfo.realmDisplayName ~= E.myrealm then
                        infoText = format('%s - %s', info.gameAccountInfo.areaName, info.gameAccountInfo.realmDisplayName)
                    elseif info.gameAccountInfo.realmDisplayName == E.myrealm then
                        infoText = info.gameAccountInfo.areaName
                    end

                    local faction = info.gameAccountInfo.factionName
                    button.gameIcon:SetTexture(faction and EFL.Icons.Game[faction][E.db.RhythmBox.EnhancedFriendList[faction]] or EFL.Icons.Game.Neutral.Launcher)
                else
                    nameText = format('|cFF%s%s|r', EFL.Icons.Game[client].Color or 'FFFFFF', nameText)
                    button.gameIcon:SetTexture(EFL.Icons.Game[client][E.db.RhythmBox.EnhancedFriendList[client]])
                end

                button.gameIcon:SetTexCoord(0, 1, 0, 1)
                button.gameIcon:SetDrawLayer('OVERLAY')
                button.gameIcon:SetAlpha(1)
            else
                local lastOnline = info.lastOnlineTime
                infoText = (not lastOnline or lastOnline == 0 or time() - lastOnline >= ONE_YEAR) and FRIENDS_LIST_OFFLINE or format(BNET_LAST_ONLINE_TIME, FriendsFrame_GetLastOnline(lastOnline))
            end
			button.status:SetTexture(EFL.Icons.Status[status][E.db.RhythmBox.EnhancedFriendList.StatusIconPack])
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
    if E.db.RhythmBox.EnhancedFriendList.ShowStatusBackground then
        EFL:CreateTexture(button, 'background', 'BACKGROUND')

        button.efl.background.Left:SetGradientAlpha('Horizontal', r, g, b, .15, r, g, b, 0)
        button.efl.background.Right:SetGradientAlpha('Horizontal', r, g, b, .0, r, g, b, .15)

        button.background:Hide()
    end

    if E.db.RhythmBox.EnhancedFriendList.ShowStatusHighlight then
        EFL:CreateTexture(button, 'highlight', 'HIGHLIGHT')

        button.efl.highlight.Left:SetGradientAlpha('Horizontal', r, g, b, .25, r, g, b, 0)
        button.efl.highlight.Right:SetGradientAlpha('Horizontal', r, g, b, .0, r, g, b, .25)

        button.highlight:SetVertexColor(0, 0, 0, 0)
    end

    button.name:SetFont(LSM:Fetch('font', E.db.RhythmBox.EnhancedFriendList.NameFont), E.db.RhythmBox.EnhancedFriendList.NameFontSize, E.db.RhythmBox.EnhancedFriendList.NameFontFlag)
    button.info:SetFont(LSM:Fetch('font', E.db.RhythmBox.EnhancedFriendList.InfoFont), E.db.RhythmBox.EnhancedFriendList.InfoFontSize, E.db.RhythmBox.EnhancedFriendList.InfoFontFlag)

    if button.Favorite and button.Favorite:IsShown() then
        button.Favorite:ClearAllPoints()
        button.Favorite:SetPoint('TOPLEFT', button.name, 'TOPLEFT', button.name:GetStringWidth(), 0);
    end
end

P["RhythmBox"]["EnhancedFriendList"] = {
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
for _, GameIcon in pairs({'Alliance', 'Horde', 'Neutral', 'D3', 'WTCG', 'S1', 'S2', 'App', 'BSAp', 'Hero', 'Pro', 'DST2', 'VIPR' }) do
    P["RhythmBox"]["EnhancedFriendList"][GameIcon] = 'Launcher'
end

local function FriendListOptions()
    E.Options.args.RhythmBox.args.EnhancedFriendList = {
        order = 6,
        type = 'group',
        name = "增强好友列表",
        get = function(info) return E.db.RhythmBox.EnhancedFriendList[info[#info]] end,
        set = function(info, value) E.db.RhythmBox.EnhancedFriendList[info[#info]] = value end,
        args = {
            Enable = {
                order = 1,
                type = 'toggle',
                name = "启用",
                set = function(info, value) E.db.RhythmBox.EnhancedFriendList[info[#info]] = value; EFL:Initialize() end,
            },
            General = {
                name = "通用",
                order = 2,
                type = 'group',
                get = function(info) return E.db.RhythmBox.EnhancedFriendList[info[#info]] end,
                set = function(info, value) E.db.RhythmBox.EnhancedFriendList[info[#info]] = value; FriendsFrame_Update() end,
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
                get = function(info) return E.db.RhythmBox.EnhancedFriendList[info[#info]] end,
                set = function(info, value) E.db.RhythmBox.EnhancedFriendList[info[#info]] = value; FriendsFrame_Update() end,
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
        E.Options.args.RhythmBox.args.EnhancedFriendList.args.GameIcons.args[key] = {
            name = value.Name .. " 图标",
            order = value.Order,
            type = 'select',
            values = {
                ['Default'] = "默认",
                ['BlizzardChat'] = "暴雪聊天风格",
                ['Flat'] = "扁平风格",
                ['Gloss'] = "光泽风格",
                ['Launcher'] = "战网风格",
            },
        }
        E.Options.args.RhythmBox.args.EnhancedFriendList.args.GameIconsPreview.args[key] = {
            order = value.Order,
            type = 'execute',
            name = value.Name,
            func = function() return end,
            image = function(info) return EFL.Icons.Game[info[#info]][E.db.RhythmBox.EnhancedFriendList[key]], 32, 32 end,
        }
    end

    E.Options.args.RhythmBox.args.EnhancedFriendList.args.GameIcons.args['App'].values['Animated'] = 'Animated'
    E.Options.args.RhythmBox.args.EnhancedFriendList.args.GameIcons.args['BSAp'].values['Animated'] = 'Animated'

    for Key, Value in pairs(EFL.Icons.Status) do
        E.Options.args.RhythmBox.args.EnhancedFriendList.args.StatusIcons.args[Key] = {
            order = Value.Order,
            type = 'execute',
            name = Value.Name,
            func = function() return end,
            image = function(info) return EFL.Icons.Status[info[#info]][E.db.RhythmBox.EnhancedFriendList.StatusIconPack], 16, 16 end,
        }
    end
end
tinsert(R.Config, FriendListOptions)

function EFL:Initialize()
    if E.db.RhythmBox.EnhancedFriendList.Enable and not self.hooking then
        self.hooking = true
        self:SecureHook('FriendsFrame_UpdateFriendButton', 'UpdateFriends')
    elseif self.hooking then
        self.hooking = nil
        self:Unhook('FriendsFrame_UpdateFriendButton')
        FriendsFrame_Update()
    end
end

R:RegisterModule(EFL:GetName())
