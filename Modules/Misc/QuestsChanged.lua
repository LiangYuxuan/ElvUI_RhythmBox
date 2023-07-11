-- From: https://github.com/kemayo/wow-questschanged
-- By: Kemayo

local R, E, L, V, P, G = unpack((select(2, ...)))
local QC = R:NewModule('QuestsChanged', 'AceEvent-3.0', 'AceTimer-3.0')
local S = E:GetModule('Skins')
local LDB = E.Libs.LDB
local LDBI = LibStub('LibDBIcon-1.0')

-- Lua functions
local ceil, date, format, time, tinsert = ceil, date, format, time, tinsert

-- WoW API / Variables
local C_QuestLog_GetAllCompletedQuestIDs = C_QuestLog.GetAllCompletedQuestIDs
local C_TooltipInfo_GetHyperlink = C_TooltipInfo.GetHyperlink
local CreateFrame = CreateFrame
local IsLoggedIn = IsLoggedIn

local ValidateFramePosition = ValidateFramePosition

local MERCHANT_PAGE_NUMBER = MERCHANT_PAGE_NUMBER
local UNKNOWN = UNKNOWN

local LOG_WINDOW_PAGE_SIZE = 15

do
    local questNameCache = {}
    function QC:GetQuestName(questID)
        if not questNameCache[questID] then
            local data = C_TooltipInfo_GetHyperlink('quest:' .. questID)
            local name = data and data.lines and data.lines[1] and data.lines[1].leftText

            if name and #name > 0 then
                questNameCache[questID] = name
            end
        end
        return questNameCache[questID]
    end
end

function QC:AddQuest(questID)
    self:GetQuestName(questID)
    tinsert(self.newCompleted, {
        questID = questID,
        completedTime = time(),
        mapID = E.MapInfo.mapID,
        zoneText = E.MapInfo.zoneText,
        subZoneText = E.MapInfo.subZoneText,
        xPos = E.MapInfo.x,
        yPos = E.MapInfo.y,
    })
end

function QC:RemoveQuest(questID)
    self:GetQuestName(questID)
    tinsert(self.newCompleted, {
        questID = questID,
        completedTime = time(),
        mapID = E.MapInfo.mapID,
        zoneText = E.MapInfo.zoneText,
        subZoneText = E.MapInfo.subZoneText,
        xPos = E.MapInfo.x,
        yPos = E.MapInfo.y,
        removed = true,
    })
end

function QC:Update()
    self.currCompleted = C_QuestLog_GetAllCompletedQuestIDs()

    local prev, curr = 1, 1
    while true do
        if not self.prevCompleted[prev] then
            while self.currCompleted[curr] do
                self:AddQuest(self.currCompleted[curr])
                curr = curr + 1
            end
            break
        elseif not self.currCompleted[curr] then
            while self.prevCompleted[prev] do
                self:RemoveQuest(self.prevCompleted[prev])
                prev = prev + 1
            end
            break
        elseif self.prevCompleted[prev] > self.currCompleted[curr] then
            while self.currCompleted[curr] and self.prevCompleted[prev] > self.currCompleted[curr] do
                self:AddQuest(self.currCompleted[curr])
                curr = curr + 1
            end
        elseif self.prevCompleted[prev] < self.currCompleted[curr] then
            while self.prevCompleted[prev] and self.prevCompleted[prev] < self.currCompleted[curr] do
                self:RemoveQuest(self.prevCompleted[prev])
                prev = prev + 1
            end
        else -- self.prevCompleted[prev] == self.currCompleted[curr]
            prev = prev + 1
            curr = curr + 1
        end
    end

    self.prevCompleted = self.currCompleted
    self.timer = nil
end

function QC:PreUpdate()
    if not self.timer then
        self.timer = self:ScheduleTimer('Update', .3)
    end
end

function QC:PLAYER_LOGIN()
    self.prevCompleted = C_QuestLog_GetAllCompletedQuestIDs()
    self.newCompleted = {}

    self:RegisterEvent('QUEST_LOG_UPDATE', 'PreUpdate')
    self:RegisterEvent('ENCOUNTER_LOOT_RECEIVED', 'PreUpdate')
end

function QC:LoadLogWindow()
    local window = self.window
    local questLength = #self.newCompleted
    local pageOffset = (window.currPage - 1) * LOG_WINDOW_PAGE_SIZE
    for i = 1, LOG_WINDOW_PAGE_SIZE do
        local index = questLength - pageOffset - i + 1
        local line = window.lines[i]
        if self.newCompleted[index] then
            local data = self.newCompleted[index]
            local questName = self:GetQuestName(data.questID) or UNKNOWN
            local posText = "-, -"
            if data.xPos and data.yPos then
                posText = format("%.2f, %.2f", data.xPos * 100, data.yPos * 100)
            end

            line.title:SetText(format("%d (%s)%s", data.questID, questName, data.removed and " (移除)" or ""))
            line.completedTime:SetText(date("%H:%M:%S", data.completedTime))
            line.location:SetText(format("%d (%s / %s)", data.mapID, data.zoneText or UNKNOWN, data.subZoneText or UNKNOWN))
            line.coords:SetText(posText)

            line:Show()
        else
            line:Hide()
        end
    end

    window.prevButton:Enable()
    window.nextButton:Enable()
    if window.currPage == 1 then
        window.prevButton:Disable()
    end
    if pageOffset + LOG_WINDOW_PAGE_SIZE > questLength then
        window.nextButton:Disable()
    end

    window.pageText:SetText(
        format(MERCHANT_PAGE_NUMBER, window.currPage, ceil(#self.newCompleted / LOG_WINDOW_PAGE_SIZE) or 1)
    )
end

function QC:BuildLogWindow()
    local window = CreateFrame('Frame', nil, E.UIParent, 'BackdropTemplate')

    window:SetTemplate('Transparent', true)
    window:EnableMouse(true)
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:SetFrameStrata('DIALOG')
    window:SetPoint('TOP', 0, -80)
    window:SetSize(600, 550)
    window:Hide()

    window:RegisterForDrag('LeftButton')
    window:SetScript('OnDragStart', function(self)
        self:StartMoving()
    end)
    window:SetScript('OnDragStop', function(self)
        self:StopMovingOrSizing()
        ValidateFramePosition(self)
    end)

    local closeButton = CreateFrame('Button', nil, window)
    closeButton:SetSize(32, 32)
    closeButton:SetPoint('TOPRIGHT', 1, 1)
    closeButton:SetScript('OnClick', function()
        QC.window:Hide()
    end)
    S:HandleCloseButton(closeButton)

    local pageText = window:CreateFontString(nil, 'OVERLAY')
    pageText:FontTemplate()
    pageText:SetTextColor(1, 1, 1, 1)
    pageText:SetPoint('CENTER', window, 'BOTTOM', 0, 15)
    pageText:SetWidth(150)
    pageText:SetJustifyH('CENTER')
    pageText:SetText(format(MERCHANT_PAGE_NUMBER, 5, 15))
    window.pageText = pageText

    local prevButton = CreateFrame('Button', nil, window)
    prevButton:SetSize(32, 32)
    prevButton:SetPoint('RIGHT', pageText, 'LEFT', -5, 0)
    prevButton:SetScript('OnClick', function()
        window.currPage = (window.currPage - 1) or 1
        QC:LoadLogWindow()
    end)
    window.prevButton = prevButton
    S:HandleNextPrevButton(prevButton, 'left')

    local nextButton = CreateFrame('Button', nil, window)
    nextButton:SetSize(32, 32)
    nextButton:SetPoint('LEFT', pageText, 'RIGHT', 5, 0)
    nextButton:SetScript('OnClick', function()
        window.currPage = window.currPage + 1
        QC:LoadLogWindow()
    end)
    window.nextButton = nextButton
    S:HandleNextPrevButton(nextButton, 'right')

    local titleText = window:CreateFontString(nil, 'OVERLAY')
    titleText:FontTemplate(E.Libs.LSM:Fetch('font', 'Expressway'), 20)
    titleText:SetTextColor(1, 1, 1, 1)
    titleText:SetPoint('CENTER', window, 'TOP', 0, -25)
    titleText:SetJustifyH('CENTER')
    titleText:SetText("QuestsChanged")

    window.lines = {}
    for i = 1, LOG_WINDOW_PAGE_SIZE do
        local line = CreateFrame('Frame', nil, window)
        line:SetPoint('TOPLEFT', window, 'TOPLEFT', 10, -20 - 30 * i)
        line:SetPoint('TOPRIGHT', window, 'TOPRIGHT', -10, -20 - 30 * i)
        line:SetHeight(30)

        line.title = line:CreateFontString(nil, 'OVERLAY')
        line.title:FontTemplate(nil, 15)
        line.title:SetTextColor(1, 210 / 255, 0)
        line.title:SetPoint('TOPLEFT')
        line.title:SetJustifyH('LEFT')

        line.completedTime = line:CreateFontString(nil, 'OVERLAY')
        line.completedTime:FontTemplate(nil, 15)
        line.completedTime:SetWidth(70)
        line.completedTime:SetTextColor(1, 210 / 255, 0)
        line.completedTime:SetPoint('TOPRIGHT')
        line.completedTime:SetJustifyH('RIGHT')

        line.location = line:CreateFontString(nil, 'OVERLAY')
        line.location:FontTemplate(nil, 15)
        line.location:SetTextColor(1, 210 / 255, 0)
        line.location:SetPoint('TOPRIGHT', line.completedTime, 'TOPLEFT', -10, 0)
        line.location:SetJustifyH('RIGHT')

        line.coords = line:CreateFontString(nil, 'OVERLAY')
        line.coords:FontTemplate(nil, 15)
        line.coords:SetTextColor(1, 210 / 255, 0)
        line.coords:SetPoint('TOPRIGHT', line.location, 'BOTTOMRIGHT', 0, 0)
        line.coords:SetJustifyH('RIGHT')

        tinsert(window.lines, line)
    end

    self.window = window
end

function QC:Initialize()
    self:BuildLogWindow()

    local objectDataBlocker = LDB:NewDataObject('RhythmBoxQuestsChanged', {
        type = 'launcher',
        label = 'QuestsChanged',
        icon = 'Interface/Icons/Ability_Spy',
        OnClick = function(_, button)
            if button == 'RightButton' then
                QC.tooltipMin = #QC.newCompleted
            else
                if QC.window:IsShown() then
                    QC.window:Hide()
                else
                    QC.window.currPage = 1
                    QC:LoadLogWindow()
                    QC.window:Show()
                end
            end
        end,
        OnTooltipShow = function(tooltip)
            if tooltip and tooltip.AddLine then
                tooltip:SetText("QuestsChanged")

                local length = #QC.newCompleted
                for i = (QC.tooltipMin or 0) + 1, length do
                    if not QC.newCompleted[i].removed then
                        local data = QC.newCompleted[i]
                        local questName = QC:GetQuestName(data.questID) or UNKNOWN
                        local posText = ""
                        if data.xPos and data.yPos then
                            posText = format(" @ %.2f %.2f", data.xPos * 100, data.yPos * 100)
                        end
                        tooltip:AddDoubleLine(
                            format("%d (%s)", data.questID, questName),
                            format("%d (%s / %s)%s", data.mapID, data.zoneText or UNKNOWN, data.subZoneText or UNKNOWN, posText)
                        )
                    end
                end

                local posText = ""
                if E.MapInfo.x and E.MapInfo.y then
                    posText = format(" @ %.2f %.2f", E.MapInfo.x * 100, E.MapInfo.y * 100)
                end

                tooltip:AddLine(" ")
                tooltip:AddDoubleLine(
                    "位置", format("%d (%s / %s)%s", E.MapInfo.mapID, E.MapInfo.zoneText or UNKNOWN, E.MapInfo.subZoneText or UNKNOWN, posText),
                    247 / 255, 69 / 255, 66 / 255, 247 / 255, 69 / 255, 66 / 255
                )
                tooltip:AddDoubleLine(
                    "左键点击", "显示/隐藏QuestsChanged记录窗口",
                    82 / 255, 251 / 255, 82 / 255, 82 / 255, 251 / 255, 82 / 255
                )
                tooltip:AddDoubleLine(
                    "右键点击", "清除鼠标提示记录",
                    82 / 255, 251 / 255, 82 / 255, 82 / 255, 251 / 255, 82 / 255
                )
                tooltip:Show()
            end
        end,
    })
    LDBI:Register('RhythmBoxQuestsChanged', objectDataBlocker, { hide = false })

    if IsLoggedIn() then
        self:PLAYER_LOGIN()
    else
        self:RegisterEvent('PLAYER_LOGIN')
    end
end

R:RegisterModule(QC:GetName())
