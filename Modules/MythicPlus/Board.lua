local R, E, L, V, P, G = unpack(select(2, ...))
local MP = R:GetModule('MythicPlus')

-- Lua functions
local _G = _G
local format, ipairs, select = format, ipairs, select

-- WoW API / Variables
local C_ChallengeMode_GetAffixInfo = C_ChallengeMode.GetAffixInfo
local C_ChallengeMode_GetGuildLeaders = C_ChallengeMode.GetGuildLeaders
local C_ChallengeMode_GetMapUIInfo = C_ChallengeMode.GetMapUIInfo
local C_MythicPlus_GetCurrentAffixes = C_MythicPlus.GetCurrentAffixes
local CreateFrame = CreateFrame
local IsAddOnLoaded = IsAddOnLoaded
local UnitClass = UnitClass
local UnitName = UnitName

local GameTooltip_Hide = GameTooltip_Hide

local CHALLENGE_MODE_GUILD_BEST_LINE = CHALLENGE_MODE_GUILD_BEST_LINE
local CHALLENGE_MODE_GUILD_BEST_LINE_YOU = CHALLENGE_MODE_GUILD_BEST_LINE_YOU
local CHALLENGE_MODE_POWER_LEVEL = CHALLENGE_MODE_POWER_LEVEL
local NONE = NONE
local UNKNOWN = UNKNOWN

local affixRotation = {
    -- Unknown Rotation in Patch 9.2
}

local weekText = {"本周", "下周", "两周后", "三周后", "四周后"}

local function GuildBestEntryOnEnter(self)
    if not self.leaderInfo then return end
    local info = self.leaderInfo
    local name = C_ChallengeMode_GetMapUIInfo(info.mapChallengeModeID)

    _G.GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	_G.GameTooltip:SetText(name, 1, 1, 1)
	_G.GameTooltip:AddLine(format(CHALLENGE_MODE_POWER_LEVEL, info.keystoneLevel))
    for i = 1, #info.members do
        _G.GameTooltip:AddLine(format(CHALLENGE_MODE_GUILD_BEST_LINE,
            E:ClassColor(info.members[i].classFileName).colorStr,
            info.members[i].name
        ))
	end
	_G.GameTooltip:Show()
end

local function AffixOnEnter(self)
    if not self.affixID then return end

    local name, description = C_ChallengeMode_GetAffixInfo(self.affixID)

    _G.GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    _G.GameTooltip:SetText(name, 1, 1, 1, 1, true)
    _G.GameTooltip:AddLine(description, nil, nil, nil, true)
    _G.GameTooltip:Show()
end

function MP:UpdateGuildBest()
    if not _G.ChallengesFrame.leadersAvailable then return end

    local leaders = C_ChallengeMode_GetGuildLeaders()
    for index, entry in ipairs(self.guildEntry) do
        if leaders[index] then
            local leaderInfo = leaders[index]

            local nameStr = CHALLENGE_MODE_GUILD_BEST_LINE
            if leaderInfo.isYou then
                nameStr = CHALLENGE_MODE_GUILD_BEST_LINE_YOU
            end

            entry.nameText:SetText(format(nameStr,
                E:ClassColor(leaderInfo.classFileName).colorStr,
                leaderInfo.name
            ))
            entry.levelText:SetText(leaderInfo.keystoneLevel)

            entry.leaderInfo = leaderInfo
            entry:Show()
        else
            entry:Hide()
        end
    end
end

function MP:UpdateAffix()
    local currentWeek = nil
    local current = C_MythicPlus_GetCurrentAffixes()

	if current and #current > 0 then
        for index, affixes in ipairs(affixRotation) do
            if affixes[1] == current[1].id and affixes[2] == current[2].id and affixes[3] == current[3].id then
                currentWeek = index
            end
        end
    end

    if currentWeek then
        for index, entry in ipairs(self.affixEntry) do
            local scheduleWeek = (currentWeek - 1 + index) % (#affixRotation)
            if scheduleWeek == 0 then
                scheduleWeek = #affixRotation
            end
            local affixes = affixRotation[scheduleWeek]
            for index, affix in ipairs(affixes) do
                local iconID = select(3, C_ChallengeMode_GetAffixInfo(affix))
                entry.affixes[index].icon:SetTexture(iconID)
                entry.affixes[index].affixID = affix
            end
            entry:Show()
        end
    else
        for _, entry in ipairs(self.affixEntry) do
            entry:Hide()
        end
    end
end

function MP:GetKeystoneText(keystoneMapID, keystoneLevel)
    if keystoneMapID and keystoneLevel then
        local keystoneMapName = C_ChallengeMode_GetMapUIInfo(keystoneMapID)
        return keystoneMapName .. ' (' .. keystoneLevel .. ')'
    else
        return NONE
    end
end

function MP:UpdatePartyKeystone()
    self:FlushPartyKeystone()

    for index, entry in ipairs(self.partyEntry) do
        if index == 1 then
            entry.keystoneText:SetText(self:GetKeystoneText(self.currentKeystoneMapID, self.currentKeystoneLevel))
        else
            local name, realm = UnitName('party' .. (index - 1))
            if name then
                local fullName
                if not realm or realm == "" then
                    fullName = name .. '-' .. E.myrealm
                else
                    fullName = name .. '-' .. realm
                end

                local class = select(2, UnitClass('party' .. (index - 1)))
                if class then
                    entry.nameText:SetTextColor(E:ClassColor(class):GetRGBA())
                else
                    entry.nameText:SetTextColor(1, 1, 1, 1)
                end
                entry.nameText:SetText(name)

                if not self.unitKeystones[fullName] then
                    entry.keystoneText:SetText(UNKNOWN)
                elseif self.unitKeystones[fullName] == 0 then
                    entry.keystoneText:SetText(NONE)
                else
                    entry.keystoneText:SetText(
                        self:GetKeystoneText(self.unitKeystones[fullName][1], self.unitKeystones[fullName][2])
                    )
                end
                entry:Show()
            else
                entry:Hide()
            end
        end
    end
end

function MP:CreateBoardFrame(yOffset, height, titleText)
    local boardFrame = CreateFrame('Frame', nil, self.boardContainer)
    boardFrame:SetSize(250, height)
    boardFrame:SetPoint('TOP', self.boardContainer, 'TOP', 0, yOffset)
    boardFrame:CreateBackdrop('Transparent')

    boardFrame.title = boardFrame:CreateFontString(nil, 'ARTWORK')
    boardFrame.title:FontTemplate(nil, 14)
	boardFrame.title:SetPoint('TOPLEFT', 15, -10)
    boardFrame.title:SetTextColor(1, .8, 0)
	boardFrame.title:SetText(titleText)

	boardFrame.line = boardFrame:CreateTexture(nil, 'ARTWORK')
	boardFrame.line:SetPoint('TOP', 0, -30)
    boardFrame.line:SetSize(235, 2)
    boardFrame.line:SetColorTexture(1, .8, 0, 1)

    return boardFrame
end

function MP:InitBoard()
    self.boardContainer = CreateFrame('Frame', nil, _G.ChallengesFrame)
    self.boardContainer:ClearAllPoints()
    self.boardContainer:SetPoint('TOPLEFT', _G.ChallengesFrame, 'TOPRIGHT', 0, -1)
    self.boardContainer:SetPoint('BOTTOMLEFT', _G.ChallengesFrame, 'BOTTOMRIGHT', 0, 1)
    self.boardContainer:SetWidth(270)
    self.boardContainer:CreateBackdrop('Transparent')

    self.guildFrame = self:CreateBoardFrame(-10, 115, "公会本周记录")
    self.guildEntry = {}
    for i = 1, 4 do
        local entry = CreateFrame('Frame', nil, self.guildFrame)
        entry:SetSize(220, 18)
        entry:SetScript('OnEnter', GuildBestEntryOnEnter)
        entry:SetScript('OnLeave', GameTooltip_Hide)

        entry.nameText = entry:CreateFontString(nil, 'ARTWORK')
        entry.nameText:FontTemplate(nil, 14)
		entry.nameText:SetPoint('LEFT')
        entry.nameText:SetJustifyH('LEFT')
		entry.nameText:SetWordWrap(false)
        entry.nameText:SetText()

        entry.levelText = entry:CreateFontString(nil, 'ARTWORK')
        entry.levelText:FontTemplate(nil, 14)
		entry.levelText:SetPoint('RIGHT')
        entry.levelText:SetJustifyH('RIGHT')
		entry.levelText:SetWordWrap(false)
        entry.levelText:SetTextColor(1, .8, 0)
        entry.levelText:SetText()

        if i == 1 then
            entry:SetPoint('TOP', 0, -37)
        else
            entry:SetPoint('TOP', self.guildEntry[i - 1], 'BOTTOM')
        end

        self.guildEntry[i] = entry
    end

    self.affixFrame = self:CreateBoardFrame(-140, 130, "词缀轮换")
    self.affixEntry = {}
    for i = 1, 5 do
        local entry = CreateFrame('Frame', nil, self.affixFrame)
        entry:SetSize(220, 18)

        entry.text = entry:CreateFontString(nil, 'ARTWORK')
        entry.text:FontTemplate(nil, 14)
        entry.text:SetWidth(120)
		entry.text:SetPoint('LEFT')
        entry.text:SetJustifyH('LEFT')
		entry.text:SetWordWrap(false)
        entry.text:SetTextColor(1, .8, 0)
        entry.text:SetText(weekText[i])

        local affixes = {}
        for j = 3, 1, -1 do
            local affix = CreateFrame('Frame', nil, entry)
            affix:SetSize(16, 16)
            affix:SetScript('OnEnter', AffixOnEnter)
            affix:SetScript('OnLeave', GameTooltip_Hide)

            affix.icon = affix:CreateTexture(nil, 'ARTWORK')
            affix.icon:SetAllPoints()
            affix.icon:SetSize(16, 16)
            affix.icon:SetTexCoord(.1, .9, .1, .9)

            if j == 3 then
                affix:SetPoint('RIGHT')
            else
                affix:SetPoint('RIGHT', affixes[j + 1], 'LEFT', -4, 0)
            end
            affixes[j] = affix
        end
        entry.affixes = affixes

        if i == 1 then
            entry:SetPoint('TOP', 0, -37)
        else
            entry:SetPoint('TOP', self.affixEntry[i - 1], 'BOTTOM')
        end

        self.affixEntry[i] = entry
    end

    self.partyFrame = self:CreateBoardFrame(-285, 130, "队伍钥石信息")
    self.partyEntry = {}
    for i = 1, 5 do
        local entry = CreateFrame('Frame', nil, self.partyFrame)
        entry:SetSize(220, 18)

        entry.nameText = entry:CreateFontString(nil, 'ARTWORK')
        entry.nameText:FontTemplate()
        entry.nameText:SetWidth(120)
		entry.nameText:SetPoint('LEFT')
        entry.nameText:SetJustifyH('LEFT')
		entry.nameText:SetWordWrap(false)
        entry.nameText:SetText()

        entry.keystoneText = entry:CreateFontString(nil, 'ARTWORK')
        entry.keystoneText:FontTemplate()
        entry.keystoneText:SetWidth(180)
		entry.keystoneText:SetPoint('RIGHT')
        entry.keystoneText:SetJustifyH('RIGHT')
		entry.keystoneText:SetWordWrap(false)
        entry.keystoneText:SetText()

        if i == 1 then
            entry:SetPoint('TOP', 0, -35)
            entry.nameText:SetTextColor(E:ClassColor(E.myclass):GetRGBA())
            entry.nameText:SetText(E.myname)
        else
            entry:SetPoint('TOP', self.partyEntry[i - 1], 'BOTTOM')
        end

        self.partyEntry[i] = entry
    end

    self:RegisterSignal('MYTHIC_KEYSTONE_UPDATE', 'UpdatePartyKeystone')
    self:SecureHook('ChallengesFrame_Update', function()
        self:UpdateGuildBest()
        self:UpdateAffix()
        self:UpdatePartyKeystone()
    end)

    self:UpdateGuildBest()
    self:UpdatePartyKeystone()
end

function MP:ADDON_LOADED(_, addonName)
    if addonName == 'Blizzard_ChallengesUI' then
        self:UnregisterEvent('ADDON_LOADED')
        self:InitBoard()
    end
end

function MP:BuildBoard()
    if IsAddOnLoaded('Blizzard_ChallengesUI') then
        self:InitBoard()
    else
        self:RegisterEvent('ADDON_LOADED')
    end
end
