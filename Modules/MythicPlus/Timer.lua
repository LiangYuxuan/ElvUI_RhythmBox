local R, E, L, V, P, G = unpack((select(2, ...)))
local MP = R:GetModule('MythicPlus')
local LSM = E.Libs.LSM

-- Lua functions
local _G = _G
local format, ipairs, pairs, select, sort, tinsert = format, ipairs, pairs, select, sort, tinsert

-- WoW API / Variables
local C_ChallengeMode_GetAffixInfo = C_ChallengeMode.GetAffixInfo
local CreateFrame = CreateFrame
local GetCursorPosition = GetCursorPosition
local UnitClass = UnitClass

local Round = Round

local CHALLENGE_MODE_DEATH_COUNT_TITLE = CHALLENGE_MODE_DEATH_COUNT_TITLE
local CHALLENGE_MODE_DEATH_COUNT_DESCRIPTION = CHALLENGE_MODE_DEATH_COUNT_DESCRIPTION
local HIGHLIGHT_FONT_COLOR = HIGHLIGHT_FONT_COLOR

local enemyTick = {
    [168] = { -- The Everbloom
        Normal = {
            [163] = "门口右边打花前够怪",
            [219] = "老二后够怪",
        },
    },
    [198] = { -- Darkheart Thicket
        Normal = {
            [171] = "树后全打够怪",
            [214] = "尾王前够怪",
        },
    },
    [200] = { -- Halls of Valor
        Normal = {
            [226] = "上楼",
        },
    },
    [210] = { -- Court of Stars
        Normal = {
            [178] = "进门",
        },
    },
    [248] = { -- Waycrest Manor
        Normal = {
            [277] = "下地下二层",
        },
    },
    [400] = { -- The Nokhud Offensive
        Normal = {
            [488] = "尾王前够怪",
        },
    },
    [464] = { -- Dawn of the Infinite: Murozond's Rise
        Normal = {
            [267] = "迷时战场前够怪",
            [310] = "尾王前够怪",
        },
    },
}

local function GetFrameMouseOffset(frame)
    if not frame:IsVisible() then return end

    local x, y = GetCursorPosition()
    local scale = frame:GetEffectiveScale()
    local left, top = frame:GetLeft(), frame:GetTop()
    if not left or not top then return end

    return x / scale - left, -(y / scale - top)
end

local function OnUpdate(container)
    local currentRun = MP.currentRun

    local timerBar = container.timerBar
    local elapsed = MP:GetElapsedTime()
    if elapsed then
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

    local enemyBar = container.enemyBar
    if not enemyBar:IsMouseOver() then
        enemyBar.mouseTick:Hide()
        if MP.showingTooltip then
            _G.GameTooltip:Hide()
            MP.showingTooltip = nil
        end
    else
        local xOffset = GetFrameMouseOffset(enemyBar)
        enemyBar.mouseTick:SetPoint('LEFT', xOffset, 0)
        enemyBar.mouseTick:Show()
        if enemyTick[currentRun.mapID] then
            local initGameTooltip
            local pendingTick = enemyTick[currentRun.mapID][currentRun.isTeeming and 'Teeming' or 'Normal']
            for tickProgress, tickText in pairs(pendingTick) do
                local cursorOffset = tickProgress / currentRun.enemyTotal * 300 - xOffset
                if cursorOffset > -25 and cursorOffset < 25 then
                    if not initGameTooltip then
                        _G.GameTooltip:Hide()
                        _G.GameTooltip:SetOwner(enemyBar.mouseTick, 'ANCHOR_RIGHT')
                        _G.GameTooltip:ClearLines()
                        _G.GameTooltip:AddLine()
                        initGameTooltip = true
                    end
                    local progressOffset = currentRun.enemyCurrent - tickProgress
                    local progressText = tickProgress .. " (" .. progressOffset .. ", " ..
                        (Round(progressOffset / currentRun.enemyTotal * 10000) / 100) .. "%)"
                    if progressOffset >= 0 then
                        _G.GameTooltip:AddDoubleLine(progressText, tickText, 0, 1, 0, 1, 1, 1)
                    else
                        _G.GameTooltip:AddDoubleLine(progressText, tickText, 1, 0, 0, 1, 1, 1)
                    end
                    if currentRun.enemyPull > 0 then
                        local progressOffset = currentRun.enemyCurrent + currentRun.enemyPull - tickProgress
                        local progressText = "(".. progressOffset .. ", " ..
                            (Round(progressOffset / currentRun.enemyTotal * 10000) / 100) .. "%)"
                        if progressOffset >= 0 then
                            _G.GameTooltip:AddDoubleLine(progressText, "^当前", 0, 1, 0, 0, 1, 1)
                        else
                            _G.GameTooltip:AddDoubleLine(progressText, "^当前", 1, 0, 0, 0, 1, 1)
                        end
                    end
                end
            end
            if initGameTooltip then
                _G.GameTooltip:Show()
                MP.showingTooltip = true
            elseif MP.showingTooltip then
                _G.GameTooltip:Hide()
                MP.showingTooltip = nil
            end
        end
    end
end

local function sortDeath(left, right)
    if left.count == right.count then
        return left.name < right.name
    end
    return left.count > right.count
end

local function DeathInfoOnEnter(self)
    if not MP.deathTable then
        local data = {}
        for unitName, count in pairs(MP.currentRun.playerDeath) do
            local classFilename = select(2, UnitClass(unitName))
            local classColor = E:ClassColor(classFilename)
            tinsert(data, {name = unitName, count = count, color = classColor})
        end
        sort(data, sortDeath)

        MP.deathTable = data
    end

    local GameTooltip = _G.GameTooltip
    GameTooltip:Hide()
    GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
    GameTooltip:ClearLines()
    GameTooltip:AddLine()

    GameTooltip:AddLine(format(CHALLENGE_MODE_DEATH_COUNT_TITLE, MP.currentRun.numDeaths), 1, 1, 1)
    GameTooltip:AddLine(format(CHALLENGE_MODE_DEATH_COUNT_DESCRIPTION, MP:FormatTime(MP.currentRun.timeLost, true)))
    if #MP.deathTable > 0 then
        GameTooltip:AddLine(' ')
        for _, data in ipairs(MP.deathTable) do
            local color = data.color or HIGHLIGHT_FONT_COLOR
            GameTooltip:AddDoubleLine(data.name, data.count, color.r, color.g, color.b, HIGHLIGHT_FONT_COLOR:GetRGB())
        end
    end
    GameTooltip:Show()
end

local function DeathInfoOnLeave()
    _G.GameTooltip:Hide()
end

function MP:StartTimer()
    local currentRun = self.currentRun

    self.container:Show()
    self.container:SetScript('OnUpdate', OnUpdate)

    self.container.timerBar:SetMinMaxValues(0, currentRun.timeLimit)

    local mapName = self.database[currentRun.mapID] and self.database[currentRun.mapID][2] or currentRun.mapName
    local keyInfo = "+" .. currentRun.level .. " " .. mapName .. " "
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
    if currentRun.isTormented then
        length = length + 1
        if currentRun.tormentedTime then
            bossInfo[length]:SetTextColor(0, 1, 0)
            bossInfo[length]:SetText("心能 - 4/4 - " .. self:FormatTime(currentRun.tormentedTime))
        else
            bossInfo[length]:SetTextColor(1, 1, 1)
            bossInfo[length]:SetText("心能 - " .. currentRun.tormentedCount .. "/4")
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

    if percent <= 20 then
        enemyBar:SetStatusBarColor(1, 0, 0)
    elseif percent <= 40 then
        enemyBar:SetStatusBarColor(1, 85 / 255, 0)
    elseif percent <= 60 then
        enemyBar:SetStatusBarColor(1, 170 / 255, 0)
    elseif percent <= 80 then
        enemyBar:SetStatusBarColor(1, 1, 0)
    elseif percent < 100 then
        enemyBar:SetStatusBarColor(0, 173 / 255, 1)
    else
        enemyBar:SetStatusBarColor(0, 1, 26 / 255)
    end

    if enemyTick[currentRun.mapID] then
        local pendingTick = enemyTick[currentRun.mapID][currentRun.isTeeming and 'Teeming' or 'Normal']
        local index = 1
        for tickProgress in pairs(pendingTick) do
            if not enemyBar.ticks[index] then
                enemyBar.ticks[index] = self:CreateTick(enemyBar, 0)
            end
            enemyBar.ticks[index]:ClearAllPoints()
            enemyBar.ticks[index]:SetPoint('LEFT', enemyBar, 'LEFT', tickProgress / currentRun.enemyTotal * 300, 0)
            enemyBar.ticks[index]:Show()
            index = index + 1
        end
        if index <= #enemyBar.ticks then
            for i = index, #enemyBar.ticks do
                enemyBar.ticks[i]:Hide()
            end
        end
    else
        for i = 1, #enemyBar.ticks do
            enemyBar.ticks[i]:Hide()
        end
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

    container.timerBar.deathInfo.overlay = CreateFrame('Frame', nil, container.timerBar)
    container.timerBar.deathInfo.overlay:ClearAllPoints()
    container.timerBar.deathInfo.overlay:SetAllPoints(container.timerBar.deathInfo)
    container.timerBar.deathInfo.overlay:SetScript('OnEnter', DeathInfoOnEnter)
    container.timerBar.deathInfo.overlay:SetScript('OnLeave', DeathInfoOnLeave)

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

    container.enemyBar.ticks = {}
    container.enemyBar.mouseTick = self:CreateTick(container.enemyBar, 0)
    container.enemyBar.mouseTick:Hide()

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
