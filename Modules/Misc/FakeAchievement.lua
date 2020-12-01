local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local FA = R:NewModule('FakeAchievement', 'AceEvent-3.0')
local StdUi = LibStub('StdUi')

-- Lua functions
local _G = _G
local bit_band, select, strfind, tinsert, tonumber = bit.band, select, strfind, tinsert, tonumber

-- WoW API / Variables
local C_DateAndTime_GetCurrentCalendarTime = C_DateAndTime.GetCurrentCalendarTime
local GetAchievementInfo = GetAchievementInfo
local UnitGUID = UnitGUID

local MAX_ACHIEVEMENT = 100000

local function EditboxNotEmpty(self)
    return self:GetText() ~= ''
end

function FA:CreateAchievement(aID, unitGUID, year, month, day)
    local aName = select(2, GetAchievementInfo(aID))
    if not aName then return end

    R:Print(
        "虚假成就: |cffffff00|Hachievement:%d:%s:1:%d:%d:%d:4294967295:4294967295:4294967295:4294967295|h[%s]|h|r",
        aID, unitGUID, month, day, year, aName
    )
end

function FA:Initialize()
    local window = StdUi:Window(_G.UIParent, 600, 350, "虚假成就")
    window:SetPoint('CENTER')
    StdUi:EasyLayout(window, { padding = { top = 40 } })

    local AchievementIDEditbox = StdUi:NumericBox(window, 100, 20)
    StdUi:AddLabel(window, AchievementIDEditbox, "成就ID")
    local AheadOfTheCurveButton = StdUi:Button(window, nil, 20, "引领潮流")
    AheadOfTheCurveButton:SetScript('OnClick', function()
        AchievementIDEditbox:SetValue("14460") -- Ahead of the Curve: Sire Denathrius
    end)
    local MythicRaidButton = StdUi:Button(window, nil, 20, "史诗团本")
    MythicRaidButton:SetScript('OnClick', function()
        AchievementIDEditbox:SetValue("14356") -- Mythic: Shriekwing
    end)

    local AchievementDropdown = StdUi:Dropdown(window, 100, 20)
    AchievementDropdown.OnValueChanged = function(_, value)
        if value == '' then return end
        AchievementIDEditbox:SetValue(value)
    end
    AchievementDropdown:SetOptions({})

    local AchievementSearchEditbox = StdUi:SearchEditBox(window, 100, 20, "成就名称")
    StdUi:AddLabel(window, AchievementSearchEditbox, "搜索成就")
    local AchievementSearchButton = StdUi:Button(window, nil, 20, "搜索")
    AchievementSearchButton:SetScript('OnClick', function()
        local patten = AchievementSearchEditbox:GetText()
        local result = {}

        if patten ~= "" then
            for aID = 1, MAX_ACHIEVEMENT do
                local _, name, _, _, _, _, _, _, flags = GetAchievementInfo(aID)
                if name and strfind(name, patten) and (not flags or bit_band(flags, 0x1) == 0) then
                    -- not COUNTER
                    tinsert(result, {
                        text = name,
                        value = aID,
                    })
                end
            end
        end
        AchievementDropdown:SetOptions(result)
    end)

    local SearchRow = window:AddRow({ margin = { top = 20 } })
    SearchRow:AddElement(AchievementSearchEditbox, { column = 10 })
    SearchRow:AddElement(AchievementSearchButton, { column = 2 })

    -- Dropdown Row
    window:AddRow():AddElement(AchievementDropdown)

    local AchievementRow = window:AddRow({ margin = { top = 20 } })
    AchievementRow:AddElement(AchievementIDEditbox, { column = 8 })
    AchievementRow:AddElement(AheadOfTheCurveButton, { column = 2 })
    AchievementRow:AddElement(MythicRaidButton, { column = 2 })

    -- don't like this, disable for now
    --[[
    R:GetModule('Injections'):RegisterInjection(function()
        hooksecurefunc('AchievementButton_OnClick', function(self, _, _, ignoreModifiers)
            if IsModifiedClick() and not ignoreModifiers and window:IsShown() and AchievementIDEditbox:HasFocus() then
                AchievementIDEditbox:SetValue(self.id)
                AchievementButton_ToggleTracking(self.id)
                return
            end
        end)
    end, 'Blizzard_AchievementUI')
    ]]--

    local GUIDEditbox = StdUi:EditBox(window, 100, 20, nil, EditboxNotEmpty)
    StdUi:AddLabel(window, GUIDEditbox, "单位GUID")
    local GUIDSetToPlayer = StdUi:Button(window, nil, 20, "玩家")
    GUIDSetToPlayer:SetScript('OnClick', function()
        GUIDEditbox:SetValue(E.myguid)
    end)
    local GUIDSetToTarget = StdUi:Button(window, nil, 20, "目标")
    GUIDSetToTarget:SetScript('OnClick', function()
        GUIDEditbox:SetValue(UnitGUID('target') or E.myguid)
    end)

    local GUIDRow = window:AddRow({ margin = { top = 20 } })
    GUIDRow:AddElement(GUIDEditbox, { column = 8 })
    GUIDRow:AddElement(GUIDSetToPlayer, { column = 2 })
    GUIDRow:AddElement(GUIDSetToTarget, { column = 2 })

    local DateYearEdit = StdUi:NumericBox(window, 100, 20)
    StdUi:AddLabel(window, DateYearEdit, "年")

    local DateMonthEdit = StdUi:NumericBox(window, 100, 20)
    StdUi:AddLabel(window, DateMonthEdit, "月")
    DateMonthEdit:SetMinValue(1)
    DateMonthEdit:SetMaxValue(12)

    local DateDayEdit = StdUi:NumericBox(window, 100, 20)
    StdUi:AddLabel(window, DateDayEdit, "日")
    DateDayEdit:SetMinValue(1)
    DateDayEdit:SetMaxValue(31)

    -- set default value in this way to workaround with StdUi
    local dateData = C_DateAndTime_GetCurrentCalendarTime()
    AchievementIDEditbox:SetValue("2336") -- Insane in the Membrane
    GUIDEditbox:SetValue(E.myguid)
    DateYearEdit:SetValue(dateData.year)
    DateMonthEdit:SetValue(dateData.month)
    DateDayEdit:SetValue(dateData.monthDay)

    window:AddRow({ margin = { top = 20 } }):AddElements(DateYearEdit, DateMonthEdit, DateDayEdit, { column = 'even' })

    local CreateAchievementButton = StdUi:Button(window, nil, 20, "生成")
    CreateAchievementButton:SetScript('OnClick', function()
        local aID = tonumber(AchievementIDEditbox:GetValue())
        local unitGUID = GUIDEditbox:GetValue()
        local year = tonumber(DateYearEdit:GetValue())
        local month = tonumber(DateMonthEdit:GetValue())
        local day = tonumber(DateDayEdit:GetValue())

        FA:CreateAchievement(aID, unitGUID, year - 2000, month, day)
    end)

    window:AddRow():AddElement(CreateAchievementButton)

    window:DoLayout()
    R:ToolboxRegisterSubWindow(window, "虚假成就")
end

R:RegisterModule(FA:GetName())
