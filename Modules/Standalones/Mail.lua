local R, E, L, V, P, G = unpack(select(2, ...))
local M = R:NewModule('Mail', 'AceEvent-3.0', 'AceHook-3.0')
local S = E:GetModule('Skins')

-- Lua functions
local _G = _G
local format, pairs, tinsert, unpack = format, pairs, tinsert, unpack

-- WoW API / Variables
local BNGetNumFriends = BNGetNumFriends
local C_BattleNet_GetFriendAccountInfo = C_BattleNet.GetFriendAccountInfo
local CreateFrame = CreateFrame
local GetAutoCompleteRealms = GetAutoCompleteRealms

local CloseDropDownMenus = CloseDropDownMenus
local tContains = tContains

local BNET_CLIENT_WOW = BNET_CLIENT_WOW
local FACTION_ALLIANCE = FACTION_ALLIANCE
local FACTION_HORDE = FACTION_HORDE
local FACTION_NEUTRAL = FACTION_NEUTRAL
local LEVEL = LEVEL
local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE
local WOW_PROJECT_ID = WOW_PROJECT_ID

local goldTemplate = format("[%s %s %s]", GOLD_AMOUNT, SILVER_AMOUNT, COPPER_AMOUNT)
local silverTemplate = format("[%s %s]", SILVER_AMOUNT, COPPER_AMOUNT)
local copperTemplate = format("[%s]", COPPER_AMOUNT)

local goldPattern = '^' .. goldTemplate:gsub('%[', '%%['):gsub('%]', '%%]'):gsub('%%d', '%%d+') .. '$'
local silverPattern = '^' .. silverTemplate:gsub('%[', '%%['):gsub('%]', '%%]'):gsub('%%d', '%%d+') .. '$'
local copperPattern = '^' .. copperTemplate:gsub('%[', '%%['):gsub('%]', '%%]'):gsub('%%d', '%%d+') .. '$'

local function OnMenuClick(_, arg1)
    _G.SendMailNameEditBox:SetText(arg1)
    CloseDropDownMenus()
end

function M:OpenMenu()
    E:SetEasyMenuAnchor(E.EasyMenu, self.openMenuButton)
    _G.EasyMenu(self.menuData, E.EasyMenu, nil, nil, nil, 'MENU')
end

function M:BuildContractData()
    local connectedRealms = GetAutoCompleteRealms()

    local alts = {}
    local allAlts = {}
    for realm, data in pairs(E.global.RhythmBox.Mail.AltList) do
        local shorten = E:ShortenRealm(realm)
        for playerName, playerData in pairs(data) do
            if playerName ~= E.myname or realm ~= E.myrealm then
                local level, class, faction = unpack(playerData)
                local classColor = E:ClassColor(class)
                local list = {
                    text = classColor:WrapTextInColorCode(format(
                        '%s %s%d %s %s', playerName, LEVEL, level,
                        faction == 'Alliance' and FACTION_ALLIANCE or (faction == 'Horde' and FACTION_HORDE or FACTION_NEUTRAL),
                        LOCALIZED_CLASS_NAMES_MALE[class]
                    )),
                    arg1 = realm == E.myrealm and playerName or (playerName .. '-' .. shorten),
                    notCheckable = true, func = OnMenuClick
                }

                if realm == E.myrealm or tContains(connectedRealms, shorten) then
                    tinsert(alts, list)
                end
                tinsert(allAlts, list)
            end
        end
    end

    local battleNetFriends = {}
    local _, numBNetOnline = BNGetNumFriends()
    for i = 1, numBNetOnline do
        local accountInfo = C_BattleNet_GetFriendAccountInfo(i)
        if (
            accountInfo and
            accountInfo.gameAccountInfo.characterName and
            accountInfo.gameAccountInfo.realmName and
            accountInfo.gameAccountInfo.realmDisplayName and
            accountInfo.gameAccountInfo.className and
            accountInfo.gameAccountInfo.clientProgram == BNET_CLIENT_WOW and
            accountInfo.gameAccountInfo.wowProjectID == WOW_PROJECT_ID and
            accountInfo.gameAccountInfo.factionName == E.myfaction and
            (
                accountInfo.gameAccountInfo.realmDisplayName == E.myrealm or
                tContains(connectedRealms, accountInfo.gameAccountInfo.realmName)
            )
        ) then
            local classColor = E:ClassColor(E:UnlocalizedClassName(accountInfo.gameAccountInfo.className))
            tinsert(battleNetFriends, {
                text = classColor:WrapTextInColorCode(format(
                    '%s %s%d %s %s',
                    accountInfo.gameAccountInfo.characterName,
                    LEVEL, accountInfo.gameAccountInfo.characterLevel or 0,
                    E.myLocalizedFaction,
                    accountInfo.gameAccountInfo.className
                )),
                arg1 =
                    accountInfo.gameAccountInfo.realmDisplayName == E.myrealm and
                    accountInfo.gameAccountInfo.characterName or
                    (accountInfo.gameAccountInfo.characterName .. '-' .. accountInfo.gameAccountInfo.realmName),
                notCheckable = true, func = OnMenuClick
            })
        end
    end

    self.menuData = {
        { text = "通讯录", isTitle = true, notCheckable = true },
        { text = "小号", notCheckable = true, hasArrow = true, disabled = #alts == 0, menuList = alts },
        { text = "全部小号", notCheckable = true, hasArrow = true, disabled = #allAlts == 0, menuList = allAlts },
        { text = "战网好友", notCheckable = true, hasArrow = true, disabled = #battleNetFriends == 0, menuList = battleNetFriends },
    }
end

function M:OnMailMoneyChanged()
    local editbox = _G.SendMailSubjectEditBox
    local subject = editbox:GetText()

    if (
        subject == '' or strmatch(subject, goldPattern) or
        strmatch(subject, silverPattern) or strmatch(subject, copperPattern)
    ) then
        local money = MoneyInputFrame_GetCopper(_G.SendMailMoney)
        if money and money > 0 then
            local gold = floor(money / 10000)
            local silver = floor((money - gold * 10000) / 100)
            local copper = mod(money, 100)
            if gold > 0 then
                editbox:SetText(format(goldTemplate, gold, silver, copper))
            elseif silver > 0 then
                editbox:SetText(format(silverTemplate, silver, copper))
            else
                editbox:SetText(format(copperTemplate, copper))
            end
        else
            editbox:SetText('')
        end
    end
end

function M:BuildFrame()
    local button = CreateFrame('Button', 'RhythmBoxMailButton', _G.SendMailFrame)
    button:SetSize(16, 16)
    button:ClearAllPoints()
    button:SetPoint('LEFT', _G.SendMailNameEditBox, 'RIGHT', 5, 0)
    button:SetScript('OnClick', function()
        M:OpenMenu()
    end)

    S:HandleNextPrevButton(button)

    self.openMenuButton = button
end

function M:UpdateAltTable()
    if not E.global.RhythmBox.Mail.AltList[E.myrealm] then
        E.global.RhythmBox.Mail.AltList[E.myrealm] = {}
    end

    E.global.RhythmBox.Mail.AltList[E.myrealm][E.myname] = {E.mylevel, E.myclass, E.myfaction}
end

P["RhythmBox"]["Mail"] = {
}
G["RhythmBox"]["Mail"] = {
    ["AltList"] = {},
}

local function MailOptions()
    E.Options.args.RhythmBox.args.Mail = {
        order = 25,
        type = 'group',
        name = "邮件",
        get = function(info) return E.db.RhythmBox.Mail[info[#info]] end,
        set = function(info, value) E.db.RhythmBox.Mail[info[#info]] = value end,
        args = {
        },
    }
end
tinsert(R.Config, MailOptions)

function M:Initialize()
    self:UpdateAltTable()
    self:BuildFrame()

    self:SecureHookScript(_G.SendMailFrame, "OnShow", "BuildContractData")
    self:SecureHook(_G.SendMailMoney, "onValueChangedFunc", "OnMailMoneyChanged")
end

R:RegisterModule(M:GetName())
