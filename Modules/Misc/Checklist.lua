local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local C = R:NewModule('Checklist', 'AceEvent-3.0')
local StdUi = LibStub('StdUi')

-- Lua functions

-- WoW API / Variables

--[[
Checklist
Name Type Expiration-Time

任务：
* 物品检查
* 海底实验室周常
* BL
  * 海底日常
  * 旧地图大使任务
  * 海底实验室周常
]]--

function C:LoadChecklist()
    local data = {
        {
            questDesc = "完成Checklist",
            questStatus = "未完成",
            expirationTime = 0,
        },
        {
            questDesc = "完成Checklist",
            questStatus = "未完成",
            expirationTime = 0,
        },
        {
            questDesc = "完成Checklist",
            questStatus = "未完成",
            expirationTime = 0,
        },
    }
    self.checklistTable:SetData(data)

    -- TODO: real checks
end

function C:BuildWindow()
    local window = StdUi:Window(E.UIParent, 500, 500, "Checklist")
    window:SetPoint("CENTER")
    window:SetScript('OnShow', function()
        C:LoadChecklist()
    end)

    local refreshButton = StdUi:Button(window, 100, 24, "刷新Checklist")
    StdUi:GlueTop(refreshButton, window, 0, -40)
    refreshButton:SetScript("OnClick", function()
        C:LoadChecklist()
    end)

    local cols = {
        {
            name   = "任务",
            width  = 300,
            align  = 'LEFT',
            index  = 'questDesc',
            format = 'string',
        },
        {
            name   = "状态",
            width  = 80,
            align  = 'CENTER',
            index  = 'questStatus',
            format = 'string',
        },
        {
            name   = "剩余时间",
            width  = 60,
            align  = 'LEFT',
            index  = 'expirationTime',
            format = 'number'
        },
    }

    local st = StdUi:ScrollTable(window, cols, 14, 24)
    st:EnableSelection(true)
    StdUi:GlueTop(st, window, 0, -100)
    self.checklistTable = st

    R:ToolboxRegisterSubWindow(window, "Checklist")
end

function C:Initialize()
    self:BuildWindow()
end

R:RegisterModule(C:GetName())
