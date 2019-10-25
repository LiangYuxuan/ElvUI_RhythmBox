local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

-- This Module is not implantable at the moment
-- Currently DressUpFrame using PanningModelSceneMixinTemplate which is not able to switch race
-- The old way that using DressUpModel is corrupted on SetCustomRace
-- The following code is placed here until there's a way to implement it

local ED = R:NewModule('EnhancedDressup', 'AceEvent-3.0')

-- Lua functions
local _G = _G
local pairs, strlower = pairs, strlower

-- WoW API / Variables
local C_CreatureInfo_GetRaceInfo = C_CreatureInfo.GetRaceInfo
local CreateFrame = CreateFrame
local UnitSex = UnitSex

-- local stepTexCoord = .129
-- local skinTexCoord = .015

ED.Races = {
    ['Alliance'] = {
        1,  -- Human
        3,  -- Dwarf
        4,  -- Night Elf
        7,  -- Gnome
        11, -- Draenei
        22, -- Worgen
        24, -- Pandaren
    },
    ['Horde'] = {
        2,  -- Orc
        5,  -- Undead
        6,  -- Tauren
        8,  -- Troll
        9,  -- Goblin
        10, -- Blood Elf
        24, -- Pandaren
    }
}

ED.AlliedRaces = {
    ['Alliance'] = {
        [29] = 4,  -- Void Elf
        [30] = 11, -- Lightforged Draenei
        [32] = 1,  -- Kul Tiran
        [34] = 3,  -- Dark Iron Dwarf
        -- [37] = 7,  -- Mechagnome
    },
    ['Horde'] = {
        [27] = 10, -- Nightborne
        [28] = 6,  -- Highmountain Tauren
        [31] = 8,  -- Zandalari Troll
        -- [35] = 9,  -- Vulpera
        [36] = 2,  -- Mag'har Orc
    }
}

local function RaceButtonOnEnter(self)
    self.highlight:Show()
    -- TODO: handle GameTooltip
end

local function RaceButtonOnLeave(self)
    self.highlight:Hide()
    -- TODO: handle GameTooltip
end

local function RaceButtonOnClick(self)
    _G.DressUpModel:SetCustomRace(self.raceID, self.gender - 1)
end

-- For these races, the names are shortened for the atlas
local fixAtlasNames = {
    ["highmountaintauren"] = "highmountain",
    ["lightforgeddraenei"] = "lightforged",
    ["scourge"] = "undead",
    ["zandalaritroll"] = "zandalari",
}

function ED:UpdateRaceButton(raceID, gender, parent)
    local raceInfo = C_CreatureInfo_GetRaceInfo(raceID)
    local raceName = strlower(raceInfo.clientFileString)
    local atlasID = 'raceicon-' .. (fixAtlasNames[raceName] or raceName) .. '-' .. (gender == 3 and 'female' or 'male')

    if not self.buttons[raceID] then
        local button = CreateFrame('button', nil, parent or E.UIParent)
        button:SetSize(64, 64)
        button.raceID = raceID

        -- Texture
        button.texture = button:CreateTexture(nil, 'ARTWORK')
        R:SetInside(button.texture)

        -- Highlight
        button.highlight = button:CreateTexture(nil, 'HIGHLIGHT')
        button.highlight:SetColorTexture(1, 1, 1, .45)
        R:SetInside(button.highlight)

        button:SetScript('OnEnter', RaceButtonOnEnter)
        button:SetScript('OnLeave', RaceButtonOnLeave)
        button:SetScript('OnClick', RaceButtonOnClick)

        self.buttons[raceID] = button
    end

    self.buttons[raceID].gender = gender
    self.buttons[raceID].texture:SetAtlas(atlasID)
    -- TODO: maybe need skin

    return self.buttons[raceID]
end

function ED:CreateRaceButtons(faction, parent)
    local prevButton
    for i = #self.Races[faction], 1, -1 do
        local button = self:UpdateRaceButton(self.Races[faction][i], self.gender, parent)
        button:ClearAllPoints()
        if not prevButton then
            button:SetPoint('BOTTOMLEFT', _G.DressUpFrame, 'BOTTOMRIGHT', 9, 8)
        else
            button:SetPoint('BOTTOM', prevButton, 'TOP', 0, 8)
        end
        prevButton = button
    end
    for raceID, parentID in pairs(self.AlliedRaces[faction]) do
        local button = self:UpdateRaceButton(raceID, self.gender, parent)
        button:SetPoint('LEFT', self.buttons[parentID], 'RIGHT', 8, 0)
    end
end

function ED:Initialize()
    if true then
        self.frame = CreateFrame('DressUpModel', 'RhythmTest', E.UIParent)
        self.frame:SetUnit("PLAYER")
        self.frame:SetSize(64, 64)
        self.frame:ClearAllPoints()
        self.frame:SetPoint('LEFT', E.UIParent, 'LEFT', 0, 0)

        --[[
        self.frame.texture = self.frame:CreateTexture(nil, 'BACKGROUND')
        self.frame.texture:SetAllPoints()
        -- self.frame.texture:SetTexture(1662186)
        self.frame.texture:SetAtlas('raceicon-bloodelf-female')
        ]]--

        self.frame:Hide()
    end

    self.buttons = {}
    self.faction = E.myfaction
    self.gender = UnitSex('player')

    local EDHolder = CreateFrame('Frame', nil, _G.DressUpFrame)
    EDHolder:ClearAllPoints()
    EDHolder:SetPoint('LEFT', _G.DressUpFrame, 'RIGHT', 0, 0)

    self.AllianceHolder = CreateFrame('Frame', nil, EDHolder)
    self.HordeHolder = CreateFrame('Frame', nil, EDHolder)
    self.AllianceHolder:SetAllPoints()
    self.HordeHolder:SetAllPoints()

    self:CreateRaceButtons('Alliance', self.AllianceHolder)
    self:CreateRaceButtons('Horde', self.HordeHolder)

    if self.faction == 'Alliance' then
        self.HordeHolder:Hide()
    else
        self.AllianceHolder:Hide()
    end
end

-- R:RegisterModule(ED:GetName())
