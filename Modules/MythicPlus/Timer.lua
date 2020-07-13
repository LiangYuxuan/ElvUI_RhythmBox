local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local MP = R:GetModule('MythicPlus')
local LSM = E.Libs.LSM

-- Lua functions
local format, ipairs, select = format, ipairs, select

-- WoW API / Variables
local C_ChallengeMode_GetAffixInfo = C_ChallengeMode.GetAffixInfo
local CreateFrame = CreateFrame

local mapAbbr = {
    [244] = "AD",
    [245] = "FH",
    [246] = "TD",
    [247] = "ML",
    [248] = "WM",
    [249] = "KR",
    [250] = "ToS",
    [251] = "UR",
    [252] = "SotS",
    [353] = "SoB",
    [369] = "JY",
    [370] = "WS"
}

local function OnUpdate(container)
    local currentRun = MP.currentRun
    local timerBar = container.timerBar

    local elapsed = MP:GetElapsedTime()
    if not elapsed then return end

    timerBar:SetValue(elapsed)
    timerBar.leftText:SetText(MP:FormatTime(elapsed) .. " / " .. MP:FormatTime(currentRun.timeLimit))
    if elapsed > currentRun.timeLimit then
        timerBar:SetStatusBarColor(89 / 255, 90 / 255, 92 / 255)
        timerBar.tick2:Hide()
        timerBar.tick3:Hide()
        timerBar.rightText:SetText("|cFFFF0000+" .. MP:FormatTime(elapsed - currentRun.timeLimit) .. "|r")
        timerBar.remain2Text:Hide()
        timerBar.remain3Text:Hide()
    elseif elapsed > currentRun.timeLimit2 then
        timerBar:SetStatusBarColor(1, 122 / 255, 0)
        timerBar.tick2:Hide()
        timerBar.tick3:Hide()
        timerBar.rightText:SetText(MP:FormatTime(currentRun.timeLimit - elapsed))
        timerBar.remain2Text:Hide()
        timerBar.remain3Text:Hide()
    elseif elapsed > currentRun.timeLimit3 then
        timerBar:SetStatusBarColor(1, 1, 0)
        timerBar.tick3:Hide()
        timerBar.rightText:SetText(MP:FormatTime(currentRun.timeLimit - elapsed))
        timerBar.remain2Text:SetText(MP:FormatTime(currentRun.timeLimit2 - elapsed))
        timerBar.remain3Text:Hide()
    else
        timerBar:SetStatusBarColor(0, 1, 22 / 255)
        timerBar.rightText:SetText(MP:FormatTime(currentRun.timeLimit - elapsed))
        timerBar.remain2Text:SetText(MP:FormatTime(currentRun.timeLimit2 - elapsed))
        timerBar.remain3Text:SetText(MP:FormatTime(currentRun.timeLimit3 - elapsed))
    end
end

function MP:StartTimer()
    local currentRun = self.currentRun

    self.container:Show()
    self.container:SetScript('OnUpdate', OnUpdate)

    self.container.timerBar:SetMinMaxValues(0, currentRun.timeLimit)

    local keyInfo = "+" .. currentRun.level .. " " .. (mapAbbr[currentRun.mapID] or currentRun.mapName) .. " "
    for index, affix in ipairs(currentRun.affixes) do
        local icon = select(3, C_ChallengeMode_GetAffixInfo(affix))
        keyInfo = keyInfo .. "\124T" .. icon .. ":12:12:" .. (1 - index) .. ":0:64:64:6:60:6:60\124t"
    end
    self.container.timerBar.keyInfo:SetText(keyInfo)

    self:UpdateTick()
    self:UpdateDeath()
    self:UpdateBoss()
    self:UpdateEnemy()
end

function MP:UpdateTick()
    self.container.timerBar.tick2:Show()
    self.container.timerBar.tick3:Show()
    self.container.timerBar.remain2Text:Show()
    self.container.timerBar.remain3Text:Show()
end

function MP:UpdateDeath()
    local currentRun = self.currentRun

    local deathInfo = "\124TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:12\124t" .. (currentRun.numDeaths or 0)
    if currentRun.timeLost and currentRun.timeLost > 0 then
        deathInfo = deathInfo .. "(" .. self:FormatTime(currentRun.timeLost, true, nil, true) .. ")"
    end
    self.container.timerBar.deathInfo:SetText(deathInfo)
end

function MP:UpdateBoss()
    local currentRun = self.currentRun
    local bossInfo = self.container.bossInfo

    for index, bossName in ipairs(currentRun.bossName) do
        if currentRun.bossStatus[index] then
            bossInfo[index]:SetTextColor(0, 1, 0)
            bossInfo[index]:SetText(bossName .. " - " .. self:FormatTime(currentRun.bossTime[index]))
        else
            bossInfo[index]:SetTextColor(1, 1, 1)
            bossInfo[index]:SetText(bossName)
        end
    end

    local length = #currentRun.bossName
    if currentRun.level > 10 then
        length = length + 1
        if currentRun.obeliskTime then
            bossInfo[length]:SetTextColor(0, 1, 0)
            bossInfo[length]:SetText("方尖碑 - 4/4 - " .. self:FormatTime(currentRun.obeliskTime))
        else
            bossInfo[length]:SetTextColor(1, 1, 1)
            bossInfo[length]:SetText("方尖碑 - " .. currentRun.obeliskCount .. "/4")
        end
    end

    self.container.bossContainer:SetHeight(20 * length)
    self.container:SetHeight(75 + 20 * length)
end

function MP:UpdateEnemy()
    local currentRun = self.currentRun
    local enemyBar = self.container.enemyBar

    enemyBar:SetMinMaxValues(0, currentRun.enemyTotal)
    enemyBar:SetValue(currentRun.enemyCurrent)
    enemyBar:SetOverlayOffsetValue(currentRun.enemyPull)

    local rightText = currentRun.enemyCurrent .. " / " .. currentRun.enemyTotal
    local percent = currentRun.enemyCurrent * 100 / currentRun.enemyTotal
    local leftText
    if currentRun.enemyTime then
        leftText = format("%.2f%% - |cFF00FF00%s|r", percent, self:FormatTime(currentRun.enemyTime))
    elseif currentRun.enemyPull > 0 then
        leftText = format("%.2f%% (+%.2f%%)", percent, currentRun.enemyPull * 100 / currentRun.enemyTotal)
        rightText = rightText .. " (+" .. currentRun.enemyPull .. ")"
    else
        leftText = format("%.2f%%", percent)
    end

    enemyBar.leftText:SetText(leftText)
    enemyBar.rightText:SetText(rightText)

    if percent <= 33 then
        enemyBar:SetStatusBarColor(1, 68 / 255, 0)
    elseif percent <= 66 then
        enemyBar:SetStatusBarColor(1, 232 / 255, 0)
    elseif percent < 100 then
        enemyBar:SetStatusBarColor(0, 172 / 255, 1)
    else
        enemyBar:SetStatusBarColor(0, 1, 26 / 255)
    end
end

function MP:FinalTimer()
    local currentRun = self.currentRun
    local timerBar = self.container.timerBar

    self.container:SetScript('OnUpdate', nil)

    timerBar:SetValue(currentRun.usedTime)
    timerBar.leftText:SetText(
        (currentRun.usedTime < currentRun.timeLimit and "|cFF00FF00" or "|cFFFF0000") ..
        self:FormatTime(currentRun.usedTime) .. " / " .. MP:FormatTime(currentRun.timeLimit) .. "|r"
    )

    timerBar.rightText:SetText(self:FormatTime(currentRun.usedTime - currentRun.timeLimit, nil, nil, true, true))
    timerBar.remain2Text:SetText(self:FormatTime(currentRun.usedTime - currentRun.timeLimit2, nil, nil, true, true))
    timerBar.remain3Text:SetText(self:FormatTime(currentRun.usedTime - currentRun.timeLimit3, nil, nil, true, true))

    self:UpdateTick()
end

function MP:HideTimer()
    for i = 1, 10 do
        self.container.bossInfo[i]:SetText('')
    end

    self.container:SetScript('OnUpdate', nil)
    self.container:Hide()
end

function MP:CreateFontString(frame, font, fontSize, fontStyle, justifyH)
    local fontString = frame:CreateFontString(nil, 'OVERLAY')
    fontString:FontTemplate(font, fontSize, fontStyle)
    fontString:SetTextColor(1, 1, 1)
    fontString:SetJustifyH(justifyH)

    return fontString
end

function MP:CreateTick(bar, xOffset)
    local tick = bar:CreateTexture(nil, 'ARTWORK')
    tick:SetDrawLayer('ARTWORK', 3)
    tick:SetColorTexture(1, 1, 1, 1)
    tick:SetSize(2, 24)
    tick:SetPoint('LEFT', bar, 'LEFT', xOffset, 0)

    return tick
end

function MP:CreateProgressBar()
    local bar = CreateFrame('StatusBar', nil, self.container)
    bar:SetSize(300, 24)
    bar:SetStatusBarTexture(LSM:Fetch('statusbar', 'Melli'))

    bar.statusBar = bar:GetStatusBarTexture()
    bar.statusBar:SetHorizTile(false)
    bar.statusBar:SetVertTile(false)

    bar.overlay = bar:CreateTexture(nil, 'OVERLAY')
    bar.overlay:SetTexture(LSM:Fetch('statusbar', 'Melli'))
    bar.overlay:SetHeight(24)
    bar.overlay:SetVertexColor(0, 1, 22 / 255, .63)
    bar.overlay:Hide()

    bar.HideOverlay = function(self)
        self.overlay:Hide()
    end

    bar.SetOverlayValue = function(self, value)
        local barWidth = self:GetWidth()
        local statusMin, statusMax = self:GetMinMaxValues()

        self.overlay:ClearAllPoints()
        self.overlay:SetPoint('LEFT', bar.statusBar, 'RIGHT', 0, 0)
        self.overlay:SetPoint('RIGHT', self, 'LEFT', barWidth * value / (statusMax - statusMin), 0)
        self.overlay:Show()
    end

    bar.SetOverlayOffsetValue = function(self, offset)
        local barWidth = self:GetWidth()
        local statusMin, statusMax = self:GetMinMaxValues()

        self.overlay:ClearAllPoints()
        self.overlay:SetPoint('LEFT', bar.statusBar, 'RIGHT', 0, 0)
        self.overlay:SetPoint('RIGHT', self.statusBar, 'RIGHT', barWidth * offset / (statusMax - statusMin), 0)
        self.overlay:Show()
    end

    bar.background = bar:CreateTexture(nil, 'BACKGROUND')
    bar.background:SetTexture(LSM:Fetch('statusbar', 'Melli'))
    bar.background:SetAllPoints()
    bar.background:SetVertexColor(0, 0, 0, .52)

    bar.leftText = self:CreateFontString(bar, nil, 13, 'OUTLINE', 'LEFT')
    bar.leftText:SetPoint('LEFT', bar, 'LEFT', 0, 1)

    bar.rightText = self:CreateFontString(bar, nil, 13, 'OUTLINE', 'RIGHT')
    bar.rightText:SetPoint('RIGHT', bar, 'RIGHT', 0, 1)

    return bar
end

function MP:BuildTimer()
    local frameName = 'RhythmBoxMPTimerContainer'
    local container = CreateFrame('Frame', frameName, E.UIParent)
    self.container = container

    container.timerBar = self:CreateProgressBar()
    container.timerBar:SetPoint('TOP', container, 'TOP', 0, -20)

    container.timerBar.tick2 = self:CreateTick(container.timerBar, 240)
    container.timerBar.remain2Text = self:CreateFontString(container.timerBar, nil, 13, 'OUTLINE', 'RIGHT')
    container.timerBar.remain2Text:SetPoint('RIGHT', container.timerBar, 'LEFT', 240, 0)

    container.timerBar.tick3 = self:CreateTick(container.timerBar, 180)
    container.timerBar.remain3Text = self:CreateFontString(container.timerBar, nil, 13, 'OUTLINE', 'RIGHT')
    container.timerBar.remain3Text:SetPoint('RIGHT', container.timerBar, 'LEFT', 180, 0)

    container.timerBar.keyInfo = self:CreateFontString(container.timerBar, nil, 16, 'OUTLINE', 'LEFT')
    container.timerBar.keyInfo:SetPoint('BOTTOMLEFT', container.timerBar, 'TOPLEFT', 0, 1)

    container.timerBar.deathInfo = self:CreateFontString(container.timerBar, nil, 16, 'OUTLINE', 'RIGHT')
    container.timerBar.deathInfo:SetPoint('BOTTOMRIGHT', container.timerBar, 'TOPRIGHT', 0, 1)

    container.bossContainer = CreateFrame('Frame', nil, container)
    container.bossContainer:SetPoint('TOP', container.timerBar, 'BOTTOM', 0, -5)
    container.bossContainer:SetWidth(300)
    container.bossInfo = {}
    for i = 1, 10 do
        container.bossInfo[i] = self:CreateFontString(container.bossContainer, nil, 16, 'OUTLINE', 'LEFT')
        container.bossInfo[i]:SetPoint('TOPLEFT', container.bossContainer, 'TOPLEFT', 1, -20 * (i - 1))
    end

    container.enemyBar = self:CreateProgressBar()
    container.enemyBar:SetPoint('TOP', container.bossContainer, 'BOTTOM', 0, 0)

    container:ClearAllPoints()
    container:SetPoint('RIGHT', E.UIParent, 'RIGHT', -80, -5)
    container:SetSize(300, 200)
    container:CreateBackdrop('Transparent')
    E:CreateMover(container, frameName .. 'Mover', "RhythmBox 大秘境计时器", nil, nil, nil, 'ALL,RHYTHMBOX')

    self:RegisterSignal('CHALLENGE_MODE_START', 'StartTimer')

    self:RegisterSignal('CHALLENGE_MODE_TIMER_UPDATE', 'UpdateTick')
    self:RegisterSignal('CHALLENGE_MODE_DEATH_UPDATE', 'UpdateDeath')
    self:RegisterSignal('CHALLENGE_MODE_CRITERIA_UPDATE', 'UpdateBoss')
    self:RegisterSignal('CHALLENGE_MODE_POI_UPDATE', 'UpdateEnemy')
    self:RegisterSignal('CHALLENGE_MODE_PULL_UPDATE', 'UpdateEnemy')

    self:RegisterSignal('CHALLENGE_MODE_COMPLETED', 'FinalTimer')
    self:RegisterSignal('CHALLENGE_MODE_LEAVE', 'HideTimer')
end
