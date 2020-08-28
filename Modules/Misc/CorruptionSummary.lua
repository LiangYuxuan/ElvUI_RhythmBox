local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end
if R.Shadowlands then return end

local CS = R:NewModule('CorruptionSummary', 'AceEvent-3.0', 'AceHook-3.0')
local LCI = LibStub('LibCorruptedItem-1.0')

-- Lua functions
local _G = _G
local format, ipairs, next, max, pairs, sort = format, ipairs, next, max, pairs, sort
local strmatch, tinsert, tonumber, unpack, wipe = strmatch, tinsert, tonumber, unpack, wipe

-- WoW API / Variables
local CreateFrame = CreateFrame
local GetInventoryItemLink = GetInventoryItemLink
local GetSpellInfo = GetSpellInfo
local IsCorruptedItem = IsCorruptedItem
local UnitGUID = UnitGUID

local CORRUPTION_DESCRIPTION = CORRUPTION_DESCRIPTION
local CORRUPTION_RESISTANCE_TOOLTIP_LINE = CORRUPTION_RESISTANCE_TOOLTIP_LINE
local CORRUPTION_TOOLTIP_LINE = CORRUPTION_TOOLTIP_LINE
local CORRUPTION_TOOLTIP_TITLE = CORRUPTION_TOOLTIP_TITLE
local NONE = NONE
local TOTAL_CORRUPTION_TOOLTIP_LINE = TOTAL_CORRUPTION_TOOLTIP_LINE

local essenceTextureIDs = {
    [2967101] = true,
    [3193842] = true,
    [3193843] = true,
    [3193844] = true,
    [3193845] = true,
    [3193846] = true,
    [3193847] = true,
}
local cloakResString = "(%d+)%s?" .. ITEM_MOD_CORRUPTION_RESISTANCE
local rankText = {"I", "II", "III"}

local function InspectSummaryOnEnter(self)
    if not self.unitGUID then return end

    local summary, totalCorruption = CS:SummaryCorruption(_G.InspectFrame.unit)
    local resistance = CS:InspectResistance()

    local GameTooltip = _G.GameTooltip
    GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT')
    GameTooltip:ClearLines()
    GameTooltip:AddLine(CORRUPTION_TOOLTIP_TITLE, 1, 1, 1)
    GameTooltip:AddLine(CORRUPTION_DESCRIPTION, 1, .8, 0, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(CORRUPTION_TOOLTIP_LINE, totalCorruption, 1, 1, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine(CORRUPTION_RESISTANCE_TOOLTIP_LINE, resistance, 1, 1, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine(TOTAL_CORRUPTION_TOOLTIP_LINE, max((totalCorruption - resistance), 0), .584, .428, .82, .584, .428, .82)

    CS:AddSummary(summary)

    GameTooltip:Show()
end

local function InspectSummaryOnLeave(self)
    _G.GameTooltip:Hide()
end

function CS:AddSummary(summary)
    _G.GameTooltip:AddLine(" ")
    if next(summary) then
        for _, data in ipairs(summary) do
            local displayText, count = unpack(data)
            _G.GameTooltip:AddLine(count .. " x " .. displayText, .584, .428, .82)
        end
    else
        _G.GameTooltip:AddLine(NONE, .584, .428, .82)
    end
end

do
    local function corruptionCompare(left, right)
        return left[1] < right[1]
    end

    local summary = {}
    local summarySorted = {}
    function CS:SummaryCorruption(unitID)
        wipe(summary)
        wipe(summarySorted)

        local totalCorruption = 0
        for i = 1, 17 do
            local itemLink = GetInventoryItemLink(unitID, i)
            if itemLink and IsCorruptedItem(itemLink) then
                local spellID, rank, value = LCI:GetCorruptionInfo(itemLink)
                if spellID then
                    totalCorruption = totalCorruption + value
                    local spellName, _, spellIcon = GetSpellInfo(spellID)
                    if spellName then
                        if rank then
                            spellName = spellName .. ' ' .. rankText[rank]
                        end
                        spellName = format("|T%s:14:14:0:0:64:64:5:59:5:59|t %s", spellIcon, spellName)
                        summary[spellName] = (summary[spellName] or 0) + 1
                    end
                end
            end
        end
        for displayText, count in pairs(summary) do
            tinsert(summarySorted, {displayText, count})
        end
        sort(summarySorted, corruptionCompare)

        return summarySorted, totalCorruption
    end
end

function CS:InspectResistance()
    local resistance = 0
    local unitID = _G.InspectFrame.unit

    local tooltip = E.ScanTooltip
    tooltip:SetOwner(_G.UIParent, 'ANCHOR_NONE')

    -- Essences
    tooltip:SetInventoryItem(unitID, 2)
    tooltip:Show()
    local _, essences = E:ScanTooltipTextures()
    for _, data in ipairs(essences) do
        if essenceTextureIDs[data[1]] then
            resistance = 10
            break
        end
    end

    -- Cloak
    tooltip:SetInventoryItem(unitID, 15)
    tooltip:Show()
    for i = 1, tooltip:NumLines() do
        local line = _G[tooltip:GetName() .. 'TextLeft' .. i]
        local text = line and line:GetText()
        local value = text and strmatch(text, cloakResString)
        if value then
            resistance = resistance + tonumber(value)
        end
    end

    tooltip:Hide()

    return resistance
end

function CS:UpdateInspect(_, unitGUID)
    if not _G.InspectFrame then return end

    local InspectFrame = _G.InspectFrame
    if not InspectFrame.CorruptionSummary then
        local frame = CreateFrame('Button', nil, InspectFrame)
        frame:SetPoint('BOTTOM', _G.InspectHandsSlot, 'TOP', 0, 10)
        frame:SetSize(50, 50)
        frame:SetScript('OnEnter', InspectSummaryOnEnter)
        frame:SetScript('OnLeave', InspectSummaryOnLeave)

        local texture = frame:CreateTexture()
        texture:SetPoint('TOPRIGHT', 18, 5)
        texture:SetSize(60, 60)
        texture:SetAtlas('bfa-threats-cornereye')

        local highlight = frame:CreateTexture(nil, 'HIGHLIGHT')
        highlight:SetAllPoints(texture)
        highlight:SetAtlas('bfa-threats-cornereye')
        highlight:SetBlendMode('ADD')

        InspectFrame.CorruptionSummary = frame
    end

    if InspectFrame.unit and UnitGUID(InspectFrame.unit) == unitGUID then
        InspectFrame.CorruptionSummary.unitGUID = unitGUID
    else
        InspectFrame.CorruptionSummary.unitGUID = nil
    end
end

function CS:PlayerSummary()
    local summary = self:SummaryCorruption('player')
    self:AddSummary(summary)

    _G.GameTooltip:Show()
end

function CS:Initialize()
    self:SecureHookScript(_G.CharacterStatsPane.ItemLevelFrame.Corruption, 'OnEnter', 'PlayerSummary')
    self:RegisterEvent('INSPECT_READY', 'UpdateInspect')
end

R:RegisterModule(CS:GetName())
