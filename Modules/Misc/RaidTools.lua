local R, E, L, V, P, G = unpack(select(2, ...))
local RT = R:NewModule('RaidTools', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions

-- WoW API / Variables

-- move to config
local sendToChat = true

local function pullOnClick(self)
    if RT.restTime then
        -- Cancel Pull Timer
        RT.restTime = nil
        RT:SendAddOnTimers(0)
        if sendToChat then
            RT:CancelTimer(RT.timer)
            RT:SmartChat(">>> 取消 <<<")
        end
    else
        -- Launch Pull Timer
        RT.restTime = RT:GetTimeToPull()
        RT:SendAddOnTimers(RT.restTime)
        if sendToChat then
            RT.timer = RT:ScheduleRepeatingTimer('RepeatChat', 1)
            RT:RepeatChat(true)
        end
    end
end

local function pullOnEnter(self)
    if RT.restTime then
        self.text:SetText("Cancel")
    else
        local length = RT:GetTimeToPull()
        if length == 1 then
            self.text:SetText("1 second")
        else
            self.text:SetText(length .. " seconds")
        end
    end
end

local function pullOnLeave(self)
    self.text:SetText('Pull Timer')
end

function RT:SmartChat(msg)
    if IsInRaid() then
        if UnitIsGroupLeader('player') or UnitIsGroupAssistant('player') or IsEveryoneAssistant() then
            SendChatMessage(msg, 'RAID_WARNING')
        else
            SendChatMessage(msg, 'RAID')
        end
    elseif (GetNumGroupMembers() or 0) > 1 then
        SendChatMessage(msg, IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and 'INSTANCE_CHAT' or 'PARTY')
    else
        RaidWarningFrame_OnEvent(RaidWarningFrame, 'CHAT_MSG_RAID_WARNING', msg)
        print(msg)
    end
end

function RT:RepeatChat(firstMsg)
    if self.restTime == 0 then
        self:SmartChat(">>> 开始战斗 <<<")
        self.restTime = nil
        self:CancelTimer(self.timer)
        return
    end

    if firstMsg or self.restTime % 5 == 0 or self.restTime == 7 or self.restTime < 5 then
        self:SmartChat("战斗倒计时 " .. self.restTime .. " 秒.")
    end
    self.restTime = self.restTime - 1
end

function RT:SendAddOnTimers(pullTime)
    local isInInstance = IsInGroup(LE_PARTY_CATEGORY_INSTANCE)
    local isInParty = IsInGroup()
    local isInRaid = IsInRaid()
    local playerName = nil
    local chat_type = (isInInstance and 'INSTANCE_CHAT') or (isInRaid and 'RAID') or (isInParty and 'PARTY')
    if not chat_type then
        chat_type = 'WHISPER'
        playerName = UnitName('player')
    end
    local mapID = select(8, GetInstanceInfo())
    local targetName = (UnitExists('target') and UnitIsEnemy('player', 'target')) and UnitName('target') or nil
    C_ChatInfo.SendAddonMessage('BigWigs', 'P^Pull^' .. pullTime, chat_type, playerName)
    if targetName then
        C_ChatInfo.SendAddonMessage('D4', ('PT\t%d\t%d\t%s'):format(pullTime, mapID or -1, targetName), chat_type, playerName)
    else
        C_ChatInfo.SendAddonMessage('D4', ('PT\t%d\t%d'):format(pullTime, mapID or -1), chat_type, playerName)
    end
end

function RT:GetTimeToPull()
    local _, instanceType, difficultyID = GetInstanceInfo()
    if difficultyID == 8 then
        return 3
    elseif instanceType == 'party' then
        return 7
    else
        return 7
    end
end

function RT:UpdateOutlook(event)
    if event == 'PLAYER_REGEN_DISABLED' or InCombatLockdown() or not IsInGroup() then
        self.pullTimer:Hide()
        self.readyCheck:Hide()
    else
        self.pullTimer:Show()
        self.readyCheck:Show()

        if (
            (IsInRaid() and (UnitIsGroupLeader('player') or UnitIsGroupAssistant('player') or IsEveryoneAssistant())) or
            ((GetNumGroupMembers() or 0) > 0 and UnitIsGroupLeader('player'))
        ) then
            -- have permission
            self.readyCheck.icon:SetVertexColor(0, 1, 56 / 255, .75)
        else
            self.readyCheck.icon:SetVertexColor(1, 1, 1, .75)
        end
    end
end

function RT:CreateButton(iconTexture, xOffset, yOffset, text, onClick, onEnter, onLeave)
    local button = CreateFrame('Button', nil, self.mainFrame)

    button:SetSize(115, 23)
    button:SetPoint('TOP', self.mainFrame, 'TOP', xOffset, yOffset)

    button:SetBackdrop({ bgFile = 'Interface/AddOns/WeakAuras/Media/Textures/Square_Smooth_Border' })
    button:SetBackdropColor(0, 0, 0, .8)
    button:SetBackdropBorderColor(0, 0, 0, 0)

    button.icon = button:CreateTexture(nil, 'ARTWORK')
    button.icon:SetTexture(iconTexture)
    button.icon:SetDesaturated(true)
    button.icon:SetHeight(40)
    button.icon:SetWidth(40)
    button.icon:SetPoint('LEFT', button, 'LEFT')

    button.text = button:CreateFontString(nil, 'OVERLAY')
    button.text:SetTextColor(1, 1, 1, .75)
    button.text:SetPoint('RIGHT', button, 'RIGHT')
    button.text:SetJustifyH('RIGHT')
    button.text:FontTemplate('Fonts/ARKai_T.ttf', 16, 'OUTLINE')
    button.text:SetText(text)

    if onClick then
        button:RegisterForClicks('AnyUp')
        button:SetScript('OnClick', onClick)
    end

    if onEnter and onLeave then
        button:SetScript('OnEnter', onEnter)
        button:SetScript('OnLeave', onLeave)
    end

    return button
end

function RT:Initialize()
    -- self:RegisterEvent('ENCOUNTER_START')
    -- self:RegisterEvent('ENCOUNTER_END')

    self:RegisterEvent('PLAYER_REGEN_ENABLED', 'UpdateOutlook')
    self:RegisterEvent('PLAYER_REGEN_DISABLED', 'UpdateOutlook')
    self:RegisterEvent('GROUP_ROSTER_UPDATE', 'UpdateOutlook')

    local frameName = 'RhythmBoxRaidTools'
    self.mainFrame = CreateFrame('Frame', frameName, E.UIParent)
    self.mainFrame:SetSize(115, 100)
    self.mainFrame:SetPoint('TOP', E.UIParent, 'TOP', -575, -10)
    E:CreateMover(self.mainFrame, frameName .. 'Mover', "RhythmBox 团队工具", nil, nil, nil, 'ALL,RHYTHMBOX')

    self.pullTimer = self:CreateButton('Interface/PVPFrame/Icons/PVP-Banner-Emblem-84', 0, -50, 'Pull Timer', pullOnClick, pullOnEnter, pullOnLeave)
    self.readyCheck = self:CreateButton('Interface/Addons/WeakAuras/PowerAurasMedia/Auras/Aura78', 0, -75, 'Ready Check', DoReadyCheck)

    self:UpdateOutlook()
end

R:RegisterModule(RT:GetName())
