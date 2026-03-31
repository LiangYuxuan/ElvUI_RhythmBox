local R, E, L, V, P, G = unpack((select(2, ...)))
local AS = R:NewModule('AbundanceScoreboard', 'AceEvent-3.0', 'AceHook-3.0')

-- Lua functions
local _G = _G
local ipairs, tonumber, tostring = ipairs, tonumber, tostring
local string_match = string.match
local table_insert = table.insert

-- WoW API / Variables
local C_ScenarioInfo_GetScenarioInfo = C_ScenarioInfo.GetScenarioInfo
local C_UIWidgetManager_GetStatusBarWidgetVisualizationInfo = C_UIWidgetManager.GetStatusBarWidgetVisualizationInfo
local C_UIWidgetManager_GetTextColumnRowVisualizationInfo = C_UIWidgetManager.GetTextColumnRowVisualizationInfo
local CreateFrame = CreateFrame

local textColumnRowPattern = '|cnHIGHLIGHT_FONT_COLOR:(%d+)|r(.*)：'
local textColumnRowPatternNoValue = '(.*)：'

local scenarioIDs = {
    [2934] = true, -- Abundance: Skinning Den
    [3093] = true, -- Abundance: Herbalism Cave
    [3095] = true, -- Abundance: Enchanting Crypt
    [3096] = true, -- Abundance: Mining Cave
}

local function parseTextColumnRow(widgetID)
    local widgetInfo = C_UIWidgetManager_GetTextColumnRowVisualizationInfo(widgetID)
    if widgetInfo then
        local text = widgetInfo.entries[1].text

        local countText, labelText = string_match(text, textColumnRowPattern)
        if countText and labelText then
            return tonumber(countText), labelText
        end

        local labelTextOnly = string_match(text, textColumnRowPatternNoValue)
        if labelTextOnly then
            return 0, labelTextOnly
        end

        return 0, text
    end

    return 0, ''
end

local function getBlessingLevel()
    local widgetInfo = C_UIWidgetManager_GetTextColumnRowVisualizationInfo(6874)
    if widgetInfo then
        local text = widgetInfo.entries[1].text
        local levelText = string_match(text, '%d+')
        if levelText then
            return tonumber(levelText)
        end
    end
    return 1
end

---@class AbundanceScoreboardLine
---@field widgetID number
---@field additionalWidgetID number?
---@field multiplier number
---@field alwaysUpdate boolean?
---@field getValue fun(widgetID: number): number
---@field updateFunc fun(lineFrame: table, scoreLines: AbundanceScoreboardLine[])
local scoreLines = {
    -- Abundance Harvest
    {
        widgetID = 6865,
        multiplier = 1,
        getValue = function()
            return 2500
        end,
    },
    -- Materials Harvested
    {
        widgetID = 6866,
        additionalWidgetID = 6849,
        multiplier = 1,
        getValue = function()
            local contributedCount = parseTextColumnRow(6868)
            local widgetInfo = C_UIWidgetManager_GetStatusBarWidgetVisualizationInfo(6849)
            local heldCount = widgetInfo and widgetInfo.barValue or 0
            return contributedCount + heldCount
        end,
    },
    -- Materials Contributed
    {
        widgetID = 6868,
        multiplier = 2,
        getValue = parseTextColumnRow,
    },
    -- Basic Nodes
    {
        widgetID = 6870,
        multiplier = 400,
        getValue = parseTextColumnRow,
    },
    -- Artisan Nodes
    {
        widgetID = 6869,
        multiplier = 2500,
        getValue = parseTextColumnRow,
    },
    -- Large Orbs
    {
        widgetID = 6871,
        multiplier = 200,
        getValue = parseTextColumnRow,
    },
    -- Bonus Events
    {
        widgetID = 6886,
        multiplier = 5000,
        getValue = parseTextColumnRow,
    },
    -- GRAND TOTAL (Event Total x Blessing Bonus)
    {
        widgetID = 6873,
        additionalWidgetID = 6874,
        multiplier = 1,
        alwaysUpdate = true,
        updateFunc = function(lineFrame, scoreLines)
            local total = 0
            for i = 1, #scoreLines - 1 do
                local scoreLine = scoreLines[i]
                total = total + scoreLine.getValue(scoreLine.widgetID) * scoreLine.multiplier
            end

            local blessingLevel = getBlessingLevel()

            lineFrame.count:SetText(tostring(total))
            lineFrame.multiplier:SetText('x' .. blessingLevel)
            lineFrame.total:SetText(tostring(total * blessingLevel))
        end,
    },
}

function AS:UPDATE_UI_WIDGET(event, widgetInfo)
    local updatedWidgetID = event and widgetInfo.widgetID

    local isUpdated = false
    for index, scoreLine in ipairs(scoreLines) do
        ---@cast scoreLine AbundanceScoreboardLine
        if (
            not updatedWidgetID or
            (scoreLine.widgetID == updatedWidgetID or scoreLine.additionalWidgetID == updatedWidgetID)
            or (scoreLine.alwaysUpdate and isUpdated)
        ) then
            if scoreLine.updateFunc then
                scoreLine.updateFunc(self.frame.lines[index], scoreLines)
            else
                local value = scoreLine.getValue and scoreLine.getValue(scoreLine.widgetID) or 0
                self.frame.lines[index].count:SetText(tostring(value))
                self.frame.lines[index].total:SetText(tostring(value * scoreLine.multiplier))
            end

            isUpdated = true
        end
    end
end

function AS:SCENARIO_UPDATE()
    local scenarioInfo = C_ScenarioInfo_GetScenarioInfo()
    if scenarioInfo and scenarioIDs[scenarioInfo.scenarioID] then
        self:RegisterEvent('UPDATE_UI_WIDGET')
        self:UPDATE_UI_WIDGET()
        self.frame:Show()
    else
        self:UnregisterEvent('UPDATE_UI_WIDGET')
        self.frame:Hide()
    end
end

function AS:BuildScoreboard()
    ---@class AbundanceScoreboard: Frame
    local frame = CreateFrame('Frame', 'RhythmBoxAbundanceScoreboard', _G.ObjectiveTrackerFrame)
    frame:SetTemplate('Transparent', true)
    frame:SetFrameStrata('DIALOG')
    frame:ClearAllPoints()
    frame:SetPoint('TOPRIGHT', _G.ObjectiveTrackerFrame, 'TOPLEFT', -10, 0)
    frame:SetSize(340, 180)
    frame:Hide()

    ---@type AbundanceScoreboardLineFrame[]
    frame.lines = {}
    for index, scoreLine in ipairs(scoreLines) do
        ---@cast scoreLine AbundanceScoreboardLine
        local _, labelText = parseTextColumnRow(scoreLine.widgetID)
        local value = scoreLine.getValue and scoreLine.getValue(scoreLine.widgetID) or 0

        ---@class AbundanceScoreboardLineFrame: Frame
        local lineFrame = CreateFrame('Frame', nil, frame)
        lineFrame:SetPoint('TOPLEFT', 10, -10 - (index - 1) * 20)
        lineFrame:SetSize(320, 20)

        local label = lineFrame:CreateFontString(nil, 'ARTWORK')
        label:FontTemplate(nil, 14)
        label:SetJustifyH('LEFT')
        label:SetSize(100, 14)
        label:SetPoint('LEFT', 0, 0)
        label:SetText(labelText)

        local count = lineFrame:CreateFontString(nil, 'ARTWORK')
        count:FontTemplate(nil, 14)
        count:SetJustifyH('LEFT')
        count:SetSize(70, 14)
        count:SetPoint('LEFT', label, 'RIGHT', 0, 0)
        count:SetText(tostring(value))

        local multiplier = lineFrame:CreateFontString(nil, 'ARTWORK')
        multiplier:FontTemplate(nil, 14)
        multiplier:SetJustifyH('LEFT')
        multiplier:SetSize(70, 14)
        multiplier:SetPoint('LEFT', count, 'RIGHT', 0, 0)
        multiplier:SetText('x' .. scoreLine.multiplier)

        local total = lineFrame:CreateFontString(nil, 'ARTWORK')
        total:FontTemplate(nil, 14)
        total:SetJustifyH('RIGHT')
        total:SetSize(80, 14)
        total:SetPoint('LEFT', multiplier, 'RIGHT', 0, 0)
        total:SetText(tostring(value * scoreLine.multiplier))

        lineFrame.label = label
        lineFrame.count = count
        lineFrame.multiplier = multiplier
        lineFrame.total = total

        if scoreLine.updateFunc then
            scoreLine.updateFunc(lineFrame, scoreLines)
        end

        table_insert(frame.lines, lineFrame)
    end

    self.frame = frame
end

function AS:Initialize()
    self:BuildScoreboard()

    self:RegisterEvent('SCENARIO_UPDATE')

    self:SCENARIO_UPDATE()
end

R:RegisterModule(AS:GetName())
