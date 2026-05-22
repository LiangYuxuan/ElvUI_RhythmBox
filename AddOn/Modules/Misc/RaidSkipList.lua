local R, E, L, V, P, G = unpack((select(2, ...)))
local RSL = R:NewModule('RaidSkipList', 'AceEvent-3.0')
local TB = R:GetModule('Toolbox')
local S = E:GetModule('Skins')

-- Lua functions
local _G = _G
local ipairs, wipe = ipairs, wipe
local string_format = string.format
local table_insert = table.insert

-- WoW API / Variables
local C_QuestLog_GetNumQuestObjectives = C_QuestLog.GetNumQuestObjectives
local C_QuestLog_IsOnQuest = C_QuestLog.IsOnQuest
local C_QuestLog_IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted
local C_QuestLog_IsQuestFlaggedCompletedOnAccount = C_QuestLog.IsQuestFlaggedCompletedOnAccount
local C_TooltipInfo_GetHyperlink = C_TooltipInfo.GetHyperlink
local CreateFrame = CreateFrame
local GetLFGDungeonInfo = GetLFGDungeonInfo
local GetQuestObjectiveInfo = GetQuestObjectiveInfo

local atlasReady = '|A:ui-lfg-readymark-raid:14:14|a'
local atlasPending = '|A:ui-lfg-pendingmark-raid:14:14|a'
local atlasDecline = '|A:ui-lfg-declinemark-raid:14:14|a'
local atlasWarband = '|A:warbands-icon:14:14|a'

---@class RaidSkipQuestData
---@field dungeonID number
---@field mythicQuestID number
---@field heroicQuestID number
---@field normalQuestID number
---@field attachRaidName boolean

---@type RaidSkipQuestData[]
local database = {
    {
        -- The Voidspire
        dungeonID = 3094,
        -- The Voidspire: Flicker in the Hollow
        mythicQuestID = 94477,
        heroicQuestID = 94476,
        normalQuestID = 94475,
        attachRaidName = false,
    },
    {
        -- Manaforge Omega
        dungeonID = 2805,
        -- Manaforge Omega: A Walking Shadow
        mythicQuestID = 91461,
        heroicQuestID = 91460,
        normalQuestID = 91459,
        attachRaidName = false,
    },
    {
        -- Liberation of Undermine
        dungeonID = 2779,
        -- Liberation of Undermine: Splitting Pairs
        mythicQuestID = 89353,
        heroicQuestID = 89352,
        normalQuestID = 89351,
        attachRaidName = false,
    },
    {
        -- Nerub-ar Palace
        dungeonID = 2645,
        -- Nerub-ar Palace: For Nerubian Eyes Only
        mythicQuestID = 82639,
        heroicQuestID = 82638,
        normalQuestID = 82629,
        attachRaidName = false,
    },
    {
        -- Amirdrassil, the Dream's Hope
        dungeonID = 2502,
        -- Amirdrassil, the Dream's Hope: Up in Smoke
        mythicQuestID = 78602,
        heroicQuestID = 78601,
        normalQuestID = 78600,
        attachRaidName = false,
    },
    {
        -- Aberrus, the Shadowed Crucible
        dungeonID = 2403,
        -- Aberrus, the Shadowed Crucible: Echoes of the Earth-Warder
        mythicQuestID = 76086,
        heroicQuestID = 76085,
        normalQuestID = 76083,
        attachRaidName = false,
    },
    {
        -- Vault of the Incarnates
        dungeonID = 2390,
        -- Vault of the Incarnates: Break a Few Eggs
        mythicQuestID = 71020,
        heroicQuestID = 71019,
        normalQuestID = 71018,
        attachRaidName = false,
    },
    {
        -- Sepulcher of the First Ones
        dungeonID = 2288,
        -- Sepulcher of the First Ones - Heavy is the Crown
        mythicQuestID = 65762,
        heroicQuestID = 65763,
        normalQuestID = 65764,
        attachRaidName = false,
    },
    {
        -- Sanctum of Domination
        dungeonID = 2226,
        -- Sanctum of Domination - Damned If You Don't
        mythicQuestID = 64599,
        heroicQuestID = 64598,
        normalQuestID = 64597,
        attachRaidName = false,
    },
    {
        -- Castle Nathria
        dungeonID = 2095,
        -- Castle Nathria: Getting a Head
        mythicQuestID = 62056,
        heroicQuestID = 62055,
        normalQuestID = 62054,
        attachRaidName = false,
    },
    {
        -- Ny'alotha, the Waking City
        dungeonID = 2033,
        -- Ny'alotha: MOTHER's Guidance
        mythicQuestID = 58375,
        heroicQuestID = 58374,
        normalQuestID = 58373,
        attachRaidName = false,
    },
    {
        -- Antorus, the Burning Throne
        dungeonID = 1640,
        -- Antorus, the Burning Throne: The Heart of Argus
        mythicQuestID = 49135,
        heroicQuestID = 49134,
        normalQuestID = 49133,
        attachRaidName = false,
    },
    {
        -- Antorus, the Burning Throne
        dungeonID = 1640,
        -- Antorus, the Burning Throne: Dark Passage
        mythicQuestID = 49076,
        heroicQuestID = 49075,
        normalQuestID = 49032,
        attachRaidName = false,
    },
    {
        -- Tomb of Sargeras
        dungeonID = 1525,
        -- Tomb of Sargeras: Aegwynn's Path
        mythicQuestID = 47727,
        heroicQuestID = 47726,
        normalQuestID = 47725,
        attachRaidName = false,
    },
    {
        -- The Nighthold
        dungeonID = 1351,
        -- The Nighthold: Talisman of the Shal'dorei
        mythicQuestID = 45383,
        heroicQuestID = 45382,
        normalQuestID = 45381,
        attachRaidName = false,
    },
    {
        -- The Emerald Nightmare
        dungeonID = 1348,
        -- The Emerald Nightmare: Piercing the Veil
        mythicQuestID = 44285,
        heroicQuestID = 44284,
        normalQuestID = 44283,
        attachRaidName = false,
    },
    {
        -- Hellfire Citadel
        dungeonID = 987,
        -- The Fel Spire
        mythicQuestID = 39505,
        heroicQuestID = 39504,
        normalQuestID = 39502,
        attachRaidName = true,
    },
    {
        -- Hellfire Citadel
        dungeonID = 987,
        -- Well of Souls
        mythicQuestID = 39501,
        heroicQuestID = 39500,
        normalQuestID = 39499,
        attachRaidName = true,
    },
    {
        -- Blackrock Foundry
        dungeonID = 898,
        -- Sigil of the Black Hand
        mythicQuestID = 37031,
        heroicQuestID = 37030,
        normalQuestID = 37029,
        attachRaidName = true,
    },
}

---@class TableRowCellDefine
---@field headerText string
---@field width number
---@field justifyH 'LEFT' | 'CENTER' | 'RIGHT'

---@class TableRowDefine
---@field cells TableRowCellDefine[]
---@field height number
---@field fontSize number

---@type TableRowDefine
local tableRowDefine = {
    cells = {
        { headerText = '任务', width = 350, justifyH = 'LEFT' },
        { headerText = '史诗', width = 80, justifyH = 'CENTER' },
        { headerText = '英雄', width = 80, justifyH = 'CENTER' },
        { headerText = '普通', width = 80, justifyH = 'CENTER' },
    },
    height = 24,
    fontSize = 14,
}

---@param cell RaidSkipListCellFrame
---@param questID number
local function UpdateQuestCell(cell, questID)
    wipe(cell.tooltipLines)

    if C_QuestLog_IsQuestFlaggedCompleted(questID) then
        cell:SetText(atlasReady)
    elseif C_QuestLog_IsOnQuest(questID) then
        local isCompletedOnAccount = C_QuestLog_IsQuestFlaggedCompletedOnAccount(questID)
        if isCompletedOnAccount then
            cell:SetText(string_format("%s (%s)", atlasPending, atlasWarband))
        else
            cell:SetText(atlasPending)
        end

        local leaderboardCount = C_QuestLog_GetNumQuestObjectives(questID)
        for i = 1, leaderboardCount do
            local text, _, finished, fulfilled, required = GetQuestObjectiveInfo(questID, i, false)
            if finished then
                table_insert(cell.tooltipLines, { atlasReady, text })
            else
                table_insert(cell.tooltipLines, { string_format("%d/%d", fulfilled, required), text })
            end
        end
    elseif C_QuestLog_IsQuestFlaggedCompletedOnAccount(questID) then
        cell:SetText(atlasWarband)
    else
        cell:SetText(atlasDecline)
    end
end

---@param self RaidSkipListWindow
local function OnWindowShow(self)
    for rowIndex, questData in ipairs(database) do
        local rowFrame = self.questRows[rowIndex]

        local data = C_TooltipInfo_GetHyperlink('quest:' .. questData.normalQuestID)
        local questName = data and data.lines and data.lines[1] and data.lines[1].leftText or questData.normalQuestID

        if questData.attachRaidName then
            local raidName = GetLFGDungeonInfo(questData.dungeonID)
            questName = raidName .. "：" .. questName
        end
        rowFrame.cells[1]:SetText(questName)

        UpdateQuestCell(rowFrame.cells[2], questData.mythicQuestID)
        UpdateQuestCell(rowFrame.cells[3], questData.heroicQuestID)
        UpdateQuestCell(rowFrame.cells[4], questData.normalQuestID)
    end
end

do
    ---@param self RaidSkipListCellFrame
    local function OnEnter(self)
        local parent = self:GetParent()
        local parentOnEnter = parent and parent:GetScript('OnEnter')
        if parentOnEnter then
            parentOnEnter(parent)
        end

        if #self.tooltipLines > 0 then
            _G.GameTooltip:Hide()
            _G.GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
            _G.GameTooltip:ClearLines()

            for _, line in ipairs(self.tooltipLines) do
                _G.GameTooltip:AddDoubleLine(line[1], line[2], nil, nil, nil, 1, 1, 1)
            end

            _G.GameTooltip:Show()
        end
    end

    ---@param self RaidSkipListCellFrame
    local function OnLeave(self)
        local parent = self:GetParent()
        local parentOnLeave = parent and parent:GetScript('OnLeave')
        if parentOnLeave then
            parentOnLeave(parent)
        end

        _G.GameTooltip:Hide()
    end

    ---@param self RaidSkipListCellFrame
    ---@param text string | number | nil
    local function SetText(self, text)
        self.text:SetText(text)
    end

    ---@param parent RaidSkipListRowFrame
    ---@param index number
    function RSL:CreateCellFrame(parent, index)
        local prevWidth = 0
        for i = 1, index - 1 do
            prevWidth = prevWidth + tableRowDefine.cells[i].width
        end

        ---@class RaidSkipListCellFrame: Frame
        local cellFrame = CreateFrame('Frame', nil, parent)
        cellFrame:SetSize(tableRowDefine.cells[index].width, tableRowDefine.height)
        cellFrame:SetPoint('LEFT', prevWidth, 0)

        cellFrame:SetScript('OnEnter', OnEnter)
        cellFrame:SetScript('OnLeave', OnLeave)

        local text = cellFrame:CreateFontString(nil, 'ARTWORK')
        text:FontTemplate(nil, tableRowDefine.fontSize)
        text:ClearAllPoints()
        text:SetPoint(tableRowDefine.cells[index].justifyH)
        text:SetJustifyH(tableRowDefine.cells[index].justifyH)
        text:SetWordWrap(false)
        cellFrame.text = text

        cellFrame.SetText = SetText

        ---@type [string, string][]
        cellFrame.tooltipLines = {}

        return cellFrame
    end
end

do
    ---@param self RaidSkipListRowFrame
    local function OnEnter(self)
        self.highlight:Show()
    end

    ---@param self RaidSkipListRowFrame
    local function OnLeave(self)
        self.highlight:Hide()
    end

    ---@param parent RaidSkipListWindow
    ---@param index number
    ---@param columns number
    function RSL:CreateRowFrame(parent, index, columns)
        local totalWidth = 0
        for _, cellDefine in ipairs(tableRowDefine.cells) do
            totalWidth = totalWidth + cellDefine.width
        end

        ---@class RaidSkipListRowFrame: Frame
        local rowFrame = CreateFrame('Frame', nil, parent)
        rowFrame:SetSize(totalWidth, tableRowDefine.height)
        rowFrame:SetPoint('TOP', 0, -(index + 1) * tableRowDefine.height)

        if index > 0 then
            rowFrame:SetScript('OnEnter', OnEnter)
            rowFrame:SetScript('OnLeave', OnLeave)
        end

        local highlight = rowFrame:CreateTexture(nil, 'OVERLAY')
        highlight:ClearAllPoints()
        highlight:SetAllPoints()
        highlight:SetTexture(E.Media.Textures.White8x8)
        highlight:SetVertexColor(1, 1, 1, 0.03)
        highlight:Hide()
        rowFrame.highlight = highlight

        local background = rowFrame:CreateTexture(nil, 'BACKGROUND')
        background:ClearAllPoints()
        background:SetAllPoints()
        background:SetTexture(E.Media.Textures.White8x8)
        rowFrame.background = background

        if index == 0 then -- Header
            background:SetVertexColor(0, 0, 0, 0.3)
        elseif index % 2 == 1 then
            background:SetVertexColor(0, 0, 0, 0.1)
        else
            background:SetVertexColor(0, 0, 0, 0.02)
        end

        ---@type RaidSkipListCellFrame[]
        rowFrame.cells = {}
        for cellIndex = 1, columns do
            rowFrame.cells[cellIndex] = self:CreateCellFrame(rowFrame, cellIndex)
        end

        return rowFrame
    end
end

function RSL:CreateWindow()
    local columns = #tableRowDefine.cells
    local rows = #database
    local totalWidth = 0
    for _, cellDefine in ipairs(tableRowDefine.cells) do
        totalWidth = totalWidth + cellDefine.width
    end

    ---@class RaidSkipListWindow: Frame
    local window = CreateFrame('Frame', nil, E.UIParent, 'BackdropTemplate')

    window:SetTemplate('Transparent', true)
    window:SetFrameStrata('DIALOG')
    window:SetPoint('CENTER')
    window:SetSize(totalWidth, (rows + 2) * tableRowDefine.height)
    window:Hide()

    window:SetScript('OnShow', OnWindowShow)

    local closeButton = CreateFrame('Button', nil, window)
    closeButton:SetSize(32, 32)
    closeButton:SetPoint('TOPRIGHT', 1, 1)
    closeButton:SetScript('OnClick', function()
        window:Hide()
    end)
    S:HandleCloseButton(closeButton)

    local titleText = window:CreateFontString(nil, 'OVERLAY')
    titleText:FontTemplate(nil, tableRowDefine.fontSize)
    titleText:SetTextColor(1, 1, 1, 1)
    titleText:SetPoint('TOP', window, 'TOP', 0, -5)
    titleText:SetJustifyH('CENTER')
    titleText:SetText("Raid Skip List")

    local headerRow = self:CreateRowFrame(window, 0, columns)
    for cellIndex, cellDefine in ipairs(tableRowDefine.cells) do
        headerRow.cells[cellIndex]:SetText(cellDefine.headerText)
    end

    ---@type RaidSkipListRowFrame[]
    window.questRows = {}
    for rowIndex = 1, rows do
        local rowFrame = self:CreateRowFrame(window, rowIndex, columns)
        window.questRows[rowIndex] = rowFrame
    end

    return window
end

function RSL:Initialize()
    local window = self:CreateWindow()
    TB:RegisterSubWindow(window, 'Raid Skip List')

    for _, questData in ipairs(database) do
        C_TooltipInfo_GetHyperlink('quest:' .. questData.normalQuestID)
    end
end

R:RegisterModule(RSL:GetName())
