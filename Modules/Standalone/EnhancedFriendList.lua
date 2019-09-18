-- From ElvUI_WindTools
-- https://github.com/fang2hou/ElvUI_WindTools/blob/master/Modules/Chat/EnhancedFriendList.lua

local R, E, L, V, P, G = unpack(select(2, ...))
local LSM = E.Libs.LSM
local EFL = E:NewModule('RhythmBox_EnhancedFriendList', 'AceEvent-3.0', 'AceHook-3.0', 'AceTimer-3.0')

-- Lua functions
local format, pairs, tonumber, unpack = format, pairs, tonumber, unpack

-- WoW API / Variables
local BNGetFriendInfo = BNGetFriendInfo
local BNGetGameAccountInfo = BNGetGameAccountInfo
local C_FriendList_GetFriendInfoByIndex = C_FriendList.GetFriendInfoByIndex
local GetLocale = GetLocale
local GetQuestDifficultyColor = GetQuestDifficultyColor

local BNet_GetClientTexture = BNet_GetClientTexture
local BNet_GetValidatedCharacterName = BNet_GetValidatedCharacterName
local FriendsFrame_GetLastOnline = FriendsFrame_GetLastOnline
local FriendsFrame_Update = FriendsFrame_Update

local BNET_CLIENT_WOW = BNET_CLIENT_WOW
local BNET_LAST_ONLINE_TIME = BNET_LAST_ONLINE_TIME
local DEFAULT_AFK_MESSAGE = DEFAULT_AFK_MESSAGE
local DEFAULT_DND_MESSAGE = DEFAULT_DND_MESSAGE
local FACTION_ALLIANCE = FACTION_ALLIANCE
local FACTION_HORDE = FACTION_HORDE
local FACTION_STANDING_LABEL4 = FACTION_STANDING_LABEL4
local FRIENDS_BNET_NAME_COLOR = FRIENDS_BNET_NAME_COLOR
local FRIENDS_BUTTON_TYPE_BNET = FRIENDS_BUTTON_TYPE_BNET
local FRIENDS_BUTTON_TYPE_WOW = FRIENDS_BUTTON_TYPE_WOW
local FRIENDS_GRAY_COLOR = FRIENDS_GRAY_COLOR
local FRIENDS_LIST_OFFLINE = FRIENDS_LIST_OFFLINE
local FRIENDS_LIST_ONLINE = FRIENDS_LIST_ONLINE
local FRIENDS_WOW_NAME_COLOR = FRIENDS_WOW_NAME_COLOR
local LOCALIZED_CLASS_NAMES_FEMALE = LOCALIZED_CLASS_NAMES_FEMALE
local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local UNKNOWN = UNKNOWN
local WOW_PROJECT_ID = WOW_PROJECT_ID

-- GLOBALS: CUSTOM_CLASS_COLORS

local MediaPath = 'Interface\\Addons\\ElvUI_RhythmBox\\Media\\FriendList\\'
EFL.GameIcons = {
    Alliance = {
        Default = BNet_GetClientTexture(BNET_CLIENT_WOW),
        BlizzardChat = 'Interface\\ChatFrame\\UI-ChatIcon-WoW',
        Flat = MediaPath..'GameIcons\\Flat\\Alliance',
        Gloss = MediaPath..'GameIcons\\Gloss\\Alliance',
        Launcher = MediaPath..'GameIcons\\Launcher\\Alliance',
    },
    Horde = {
        Default = BNet_GetClientTexture(BNET_CLIENT_WOW),
        BlizzardChat = 'Interface\\ChatFrame\\UI-ChatIcon-WoW',
        Flat = MediaPath..'GameIcons\\Flat\\Horde',
        Gloss = MediaPath..'GameIcons\\Gloss\\Horde',
        Launcher = MediaPath..'GameIcons\\Launcher\\Horde',
    },
    Neutral = {
        Default = BNet_GetClientTexture(BNET_CLIENT_WOW),
        BlizzardChat = 'Interface\\ChatFrame\\UI-ChatIcon-WoW',
        Flat = MediaPath..'GameIcons\\Flat\\WoW',
        Gloss = MediaPath..'GameIcons\\Gloss\\WoW',
        Launcher = MediaPath..'GameIcons\\Launcher\\WoW',
    },
    D3 = {
        Default = BNet_GetClientTexture(BNET_CLIENT_D3),
        BlizzardChat = 'Interface\\ChatFrame\\UI-ChatIcon-D3',
        Flat = MediaPath..'GameIcons\\Flat\\D3',
        Gloss = MediaPath..'GameIcons\\Gloss\\D3',
        Launcher = MediaPath..'GameIcons\\Launcher\\D3',
    },
    WTCG = {
        Default = BNet_GetClientTexture(BNET_CLIENT_WTCG),
        BlizzardChat = 'Interface\\ChatFrame\\UI-ChatIcon-WTCG',
        Flat = MediaPath..'GameIcons\\Flat\\Hearthstone',
        Gloss = MediaPath..'GameIcons\\Gloss\\Hearthstone',
        Launcher = MediaPath..'GameIcons\\Launcher\\Hearthstone',
    },
    S1 = {
        Default = BNet_GetClientTexture(BNET_CLIENT_SC),
        BlizzardChat = 'Interface\\ChatFrame\\UI-ChatIcon-SC',
        Flat = MediaPath..'GameIcons\\Flat\\SC',
        Gloss = MediaPath..'GameIcons\\Gloss\\SC',
        Launcher = MediaPath..'GameIcons\\Launcher\\SC',
    },
    S2 = {
        Default = BNet_GetClientTexture(BNET_CLIENT_SC2),
        BlizzardChat = 'Interface\\ChatFrame\\UI-ChatIcon-SC2',
        Flat = MediaPath..'GameIcons\\Flat\\SC2',
        Gloss = MediaPath..'GameIcons\\Gloss\\SC2',
        Launcher = MediaPath..'GameIcons\\Launcher\\SC2',
    },
    App = {
        Default = BNet_GetClientTexture(BNET_CLIENT_APP),
        BlizzardChat = 'Interface\\ChatFrame\\UI-ChatIcon-Battlenet',
        Flat = MediaPath..'GameIcons\\Flat\\BattleNet',
        Gloss = MediaPath..'GameIcons\\Gloss\\BattleNet',
        Launcher = MediaPath..'GameIcons\\Launcher\\BattleNet',
    },
    BSAp = {
        Default = BNet_GetClientTexture(BNET_CLIENT_APP),
        BlizzardChat = 'Interface\\ChatFrame\\UI-ChatIcon-Battlenet',
        Flat = MediaPath..'GameIcons\\Flat\\BattleNet',
        Gloss = MediaPath..'GameIcons\\Gloss\\BattleNet',
        Launcher = MediaPath..'GameIcons\\Launcher\\BattleNet',
    },
    Hero = {
        Default = BNet_GetClientTexture(BNET_CLIENT_HEROES),
        BlizzardChat = 'Interface\\ChatFrame\\UI-ChatIcon-HotS',
        Flat = MediaPath..'GameIcons\\Flat\\Heroes',
        Gloss = MediaPath..'GameIcons\\Gloss\\Heroes',
        Launcher = MediaPath..'GameIcons\\Launcher\\Heroes',
    },
    Pro = {
        Default = BNet_GetClientTexture(BNET_CLIENT_OVERWATCH),
        BlizzardChat = 'Interface\\ChatFrame\\UI-ChatIcon-Overwatch',
        Flat = MediaPath..'GameIcons\\Flat\\Overwatch',
        Gloss = MediaPath..'GameIcons\\Gloss\\Overwatch',
        Launcher = MediaPath..'GameIcons\\Launcher\\Overwatch',
    },
    DST2 = {
        Default = BNet_GetClientTexture(BNET_CLIENT_DESTINY2),
        BlizzardChat = 'Interface\\ChatFrame\\UI-ChatIcon-Destiny2',
        Flat = MediaPath..'GameIcons\\Launcher\\Destiny2',
        Gloss = MediaPath..'GameIcons\\Launcher\\Destiny2',
        Launcher = MediaPath..'GameIcons\\Launcher\\Destiny2',
    },
}

EFL.StatusIcons = {
    Default = {
        Online = FRIENDS_TEXTURE_ONLINE,
        Offline = FRIENDS_TEXTURE_OFFLINE,
        DND = FRIENDS_TEXTURE_DND,
        AFK = FRIENDS_TEXTURE_AFK,
    },
    Square = {
        Online = MediaPath..'StatusIcons\\Square\\Online',
        Offline = MediaPath..'StatusIcons\\Square\\Offline',
        DND = MediaPath..'StatusIcons\\Square\\DND',
        AFK = MediaPath..'StatusIcons\\Square\\AFK',
    },
    D3 = {
        Online = MediaPath..'StatusIcons\\D3\\Online',
        Offline = MediaPath..'StatusIcons\\D3\\Offline',
        DND = MediaPath..'StatusIcons\\D3\\DND',
        AFK = MediaPath..'StatusIcons\\D3\\AFK',
    },
}

EFL.ClientColor = {
    S1 = 'C495DD',
    S2 = 'C495DD',
    D3 = 'C41F3B',
    Pro = 'FFFFFF',
    WTCG = 'FFB100',
    Hero = '00CCFF',
    App = '82C5FF',
    BSAp = '82C5FF',
}

function EFL:ClassColor(class)
    for key, value in pairs(LOCALIZED_CLASS_NAMES_MALE) do
        if class == value then
            return (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[key]) or RAID_CLASS_COLORS[key]
        end
    end
    if GetLocale() ~= 'enUS' then
        for key, value in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
            if class == value then
                return (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[key]) or RAID_CLASS_COLORS[key]
            end
        end
    end
end

function EFL:UpdateFriends(button)
    local nameText, nameColor, infoText, Cooperate
    if button.buttonType == FRIENDS_BUTTON_TYPE_WOW then
        local info = C_FriendList_GetFriendInfoByIndex(button.id)
        if info.connected then
            local classc = EFL:ClassColor(info.className) or RAID_CLASS_COLORS['PRIEST']
            local status = info.afk and 'AFK' or (info.dnd and 'DND' or 'Online')
            button.status.SetTexture(EFL.StatusIcons[E.db.RhythmBox.EnhancedFriendList.StatusIconPack][status])
            nameText = format("%s%s|r, %s%s|r", classc:GenerateHexColorMarkup(), info.name, info.level)
            nameColor = FRIENDS_WOW_NAME_COLOR
            Cooperate = true
        else
            button.status:SetTexture(EFL.StatusIcons[E.db.RhythmBox.EnhancedFriendList.StatusIconPack].Offline)
            nameText = info.name
            nameColor = FRIENDS_GRAY_COLOR
        end
        infoText = info.area
    elseif button.buttonType == FRIENDS_BUTTON_TYPE_BNET then
        local _, presenceName, battleTag, _, characterName, bnetIDGameAccount, client, isOnline, lastOnline, isBnetAFK, isBnetDND = BNGetFriendInfo(button.id)
        local realmName, realmID, faction, class, zoneName, level, gameText, isGameAFK, isGameBusy, wowProjectID
        if presenceName then
            nameText = presenceName
            if isOnline then
                characterName = BNet_GetValidatedCharacterName(characterName, battleTag, client)
            end
        else
            nameText = UNKNOWN
        end

        if characterName then
            _, _, _, realmName, realmID, faction, _, class, _, zoneName, level, gameText, _, _, _, _, _, isGameAFK, isGameBusy, _, wowProjectID = BNGetGameAccountInfo(bnetIDGameAccount)
            local classc = EFL:ClassColor(class) or RAID_CLASS_COLORS['PRIEST']
            if client == BNET_CLIENT_WOW then
                local diffColor = "|cFFFFFFFF"
                if level == nil or tonumber(level) == nil then level = 0 end
                if level ~= 0 then
                    local color = GetQuestDifficultyColor(level)
                    diffColor = format("|cFF%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
                end
                nameText = format("%s |cFFFFFFFF(|r%s%s|r, %s%s|r|cFFFFFFFF)|r", nameText, classc:GenerateHexColorMarkup(), characterName, diffColor, level)
                Cooperate = realmID and realmID > 0 and faction == E.myfaction and WOW_PROJECT_ID == wowProjectID
                if R.Classic then
                    Cooperate = Cooperate and realmName == E.myrealm
                end
            else
                nameText = format("|cFF%s%s|r", EFL.ClientColor[client] or "FFFFFF", nameText)
            end
        end

        if isOnline then
            local status = (isBnetAFK or isGameAFK) and 'AFK' or ((isBnetDND or isGameBusy) and 'DND' or 'Online')
            button.status:SetTexture(EFL.StatusIcons[E.db.RhythmBox.EnhancedFriendList.StatusIconPack][status])
            if client == BNET_CLIENT_WOW then
                if not zoneName or zoneName == '' then
                    if gameText and gameText ~= '' then
                        infoText = gameText
                    else
                        infoText = UNKNOWN
                    end
                else
                    if realmName == E.myrealm then
                        infoText = zoneName
                    else
                        infoText = format('%s - %s', zoneName, realmName)
                    end
                end
                button.gameIcon:SetTexture(EFL.GameIcons[faction][E.db.RhythmBox.EnhancedFriendList.GameIcon[faction]])
                if Cooperate then
                    button.gameIcon:SetAlpha(1)
                else
                    button.gameIcon:SetAlpha(0.6)
                end
            else
                infoText = client == 'BSAp' and "移动版" or gameText
                button.gameIcon:SetTexture(EFL.GameIcons[client][E.db.RhythmBox.EnhancedFriendList.GameIcon[client]])
            end
            nameColor = FRIENDS_BNET_NAME_COLOR
        else
            button.status:SetTexture(EFL.StatusIcons[E.db.RhythmBox.EnhancedFriendList.StatusIconPack].Offline)
            nameColor = FRIENDS_GRAY_COLOR
            infoText = lastOnline == 0 and FRIENDS_LIST_OFFLINE or format(BNET_LAST_ONLINE_TIME, FriendsFrame_GetLastOnline(lastOnline))
        end
    end

    if button.summonButton:IsShown() then
        button.gameIcon:SetPoint('TOPRIGHT', -50, -2)
    else
        button.gameIcon:SetPoint('TOPRIGHT', -21, -2)
    end

    if nameText then
        button.name:SetText(nameText)
        button.name:SetTextColor(nameColor:GetRGB())
        button.info:SetText(infoText)
        button.info:SetTextColor(unpack(Cooperate and {1, .96, .45} or {.49, .52, .54}))
        button.name:SetFont(LSM:Fetch('font', E.db.RhythmBox.EnhancedFriendList.NameFont), E.db.RhythmBox.EnhancedFriendList.NameFontSize, E.db.RhythmBox.EnhancedFriendList.NameFontFlag)
        button.info:SetFont(LSM:Fetch('font', E.db.RhythmBox.EnhancedFriendList.InfoFont), E.db.RhythmBox.EnhancedFriendList.InfoFontSize, E.db.RhythmBox.EnhancedFriendList.InfoFontFlag)
        if button.Favorite and button.Favorite:IsShown() then button.Favorite:SetPoint('TOPLEFT', button.name, 'TOPLEFT', button.name:GetStringWidth(), 0); end
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
    ["StatusIconPack"] = "D3",
    ["GameIcon"] = {
        ["App"] = "Launcher",
        ["Alliance"] = "Launcher",
        ["Horde"] = "Launcher",
        ["Neutral"] = "Launcher",
        ["D3"] = "Launcher",
        ["WTCG"] = "Launcher",
        ["S1"] = "Launcher",
        ["S2"] = "Launcher",
        ["BSAp"] = "Launcher",
        ["Hero"] = "Launcher",
        ["Pro"] = "Launcher",
        ["DST2"] = "Launcher",
    }
}

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
                name = "启用"
            },
            General = {
                name = "通用",
                order = 6,
                type = 'group',
                get = function(info) return E.db.RhythmBox.EnhancedFriendList[info[#info]] end,
                set = function(info, value) E.db.RhythmBox.EnhancedFriendList[info[#info]] = value FriendsFrame_Update() end,
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
                            ['NONE'] = "无",
                            ['OUTLINE'] = "轮廓",
                            ['MONOCHROME'] = "黑白",
                            ['MONOCHROMEOUTLINE'] = "黑白轮廓",
                            ['THICKOUTLINE'] = "厚轮廓",
                        },
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
                            ['NONE'] = "无",
                            ['OUTLINE'] = "轮廓",
                            ['MONOCHROME'] = "黑白",
                            ['MONOCHROMEOUTLINE'] = "黑白轮廓",
                            ['THICKOUTLINE'] = "厚轮廓",
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
                },
            },
            GameIcons = {
                name = "游戏图标",
                order = 7,
                type = 'group',
                get = function(info) return E.db.RhythmBox.EnhancedFriendList.GameIcon[info[#info]] end,
                set = function(info, value) E.db.RhythmBox.EnhancedFriendList.GameIcon[info[#info]] = value FriendsFrame_Update() end,
                args = {},
            },
            GameIconsPreview = {
                name = "游戏图标预览",
                order = 8,
                type = 'group',
                args = {},
            },
            StatusIcons = {
                name = "状态图标预览",
                order = 9,
                type = 'group',
                args = {},
            },
        },
    }

    local GameIconsOptions = {
        Alliance = FACTION_ALLIANCE,
        Horde = FACTION_HORDE,
        Neutral = FACTION_STANDING_LABEL4,
        D3 = "暗黑破坏神 III",
        WTCG = "炉石传说",
        S1 = "星际争霸",
        S2 = "星际争霸 II",
        App = "应用",
        BSAp = "手机",
        Hero = "风暴英雄",
        Pro = "守望先锋",
        DST2 = "命运 2",
    }
    local GameIconOrder = {
        Alliance = 1,
        Horde = 2,
        Neutral = 3,
        D3 = 4,
        WTCG = 5,
        S1 = 6,
        S2 = 7,
        App = 8,
        BSAp = 9,
        Hero = 10,
        Pro = 11,
        DST2 = 12,
    }
    local StatusIconsOptions = {
        Online = FRIENDS_LIST_ONLINE,
        Offline = FRIENDS_LIST_OFFLINE,
        DND = DEFAULT_DND_MESSAGE,
        AFK = DEFAULT_AFK_MESSAGE,
    }
    local StatusIconsOrder = {
        Online = 1,
        Offline = 2,
        DND = 3,
        AFK = 4,
    }

    for Key, Value in pairs(GameIconsOptions) do
        E.Options.args.RhythmBox.args.EnhancedFriendList.args.GameIcons.args[Key] = {
            name = Value .. " 图标",
            order = GameIconOrder[Key],
            type = 'select',
            values = {
                ['Default'] = "默认",
                ['BlizzardChat'] = "暴雪聊天风格",
                ['Flat'] = "扁平风格",
                ['Gloss'] = "光泽风格",
                ['Launcher'] = "战网风格",
            },
        }
        E.Options.args.RhythmBox.args.EnhancedFriendList.args.GameIconsPreview.args[Key] = {
            order = GameIconOrder[Key],
            type = 'execute',
            name = Value,
            func = function() return end,
            image = function(info) return EFL.GameIcons[info[#info]][E.db.RhythmBox.EnhancedFriendList.GameIcon[Key]], 32, 32 end,
        }
    end

    -- 排除缺少的 SC1 图标
    E.Options.args.RhythmBox.args.EnhancedFriendList.args.GameIcons.args['S1'].values['Flat'] = nil
    E.Options.args.RhythmBox.args.EnhancedFriendList.args.GameIcons.args['S1'].values['Gloss'] = nil

    for Key, Value in pairs(StatusIconsOptions) do
        E.Options.args.RhythmBox.args.EnhancedFriendList.args.StatusIcons.args[Key] = {
            order = StatusIconsOrder[Key],
            type = 'execute',
            name = Value,
            func = function() return end,
            image = function(info) return EFL.StatusIcons[E.db.RhythmBox.EnhancedFriendList.StatusIconPack][info[#info]], 16, 16 end,
        }
    end
end
tinsert(R.Config, FriendListOptions)

function EFL:Initialize()
    if E.db.RhythmBox.EnhancedFriendList.Enable then
        EFL:SecureHook('FriendsFrame_UpdateFriendButton', 'UpdateFriends')
    end
end

local function InitializeCallback()
    EFL:Initialize()
end

E:RegisterModule(EFL:GetName(), InitializeCallback)
