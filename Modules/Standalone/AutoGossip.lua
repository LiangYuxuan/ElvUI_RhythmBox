-- Original Author: p3lim
-- Link: https://wow.curseforge.com/projects/quickquest
-- From: https://github.com/siweia/NDui/blob/master/Interface/AddOns/NDui/Plugins/QuickQuest.lua

local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local AG = E:NewModule('RhythmBox_AutoGossip', 'AceEvent-3.0', 'AceTimer-3.0')

local tooltipName = 'AG_ScanTooltip'
local tooltip = CreateFrame('GameTooltip', tooltipName, nil, 'GameTooltipTemplate')

local function GetNPCID()
    local id = tonumber(strmatch((UnitGUID('npc') or ''), '%-(%d-)%-%x-$'))
    return id
end

local function GetNPCName(npcID)
    tooltip:SetOwner(UIParent, 'ANCHOR_NONE')
    tooltip:SetHyperlink(('unit:Creature-0-0-0-0-%d:0000000000'):format(npcID))
    local line = tooltip:IsShown() and _G[tooltipName .. 'TextLeft1']
    line = line and line:GetText()
    if line and #line > 0 then
        return line
    end
end

local blacklist = {
	[88570]  = true, -- Fate-Twister Tiklal
	[87391]  = true, -- Fate-Twister Seress
	[111243] = true, -- Archmage Lan'dalock
	[103792] = true, -- Griftah (one of his quests is a scam)
	[119388] = true, -- Chieftain Hatuun (repeatable resource quest)
	[124312] = true, -- High Exarch Turalyon (repeatable resource quest)
	[126954] = true, -- High Exarch Turalyon (repeatable resource quest)
	[127037] = true, -- Nabiru (repeatable resource quest)
	[141584] = true, -- Zurvan (Seal of Wartorn Fate, Horde)
	[142063] = true, -- Tezran (Seal of Wartorn Fate, Alliance)
}

local gossipBlacklist = {
    -- Blingtron
    [43929]  = true, -- Blingtron 4000
    [77789]  = true, -- Blingtron 5000
    [101527] = true, -- Blingtron 6000

    -- Bodyguards
    [86945]  = true, -- Aeda Brightdawn (Horde)
    [86933]  = true, -- Vivianne (Horde)
    [86927]  = true, -- Delvar Ironfist (Alliance)
    [86934]  = true, -- Defender Illona (Alliance)
    [86682]  = true, -- Tormmok
    [86964]  = true, -- Leorajh
    [86946]  = true, -- Talonpriest Ishaal

    -- Misc NPCs
    [79740]  = true, -- Warmaster Zog (Horde)
    [79953]  = true, -- Lieutenant Thorn (Alliance)
    [84268]  = true, -- Lieutenant Thorn (Alliance)
    [84511]  = true, -- Lieutenant Thorn (Alliance)
    [84684]  = true, -- Lieutenant Thorn (Alliance)
    [135612] = true, -- Halford Wyrmbane
    [135681] = true, -- Grand Admiral Jes-Tereth
    [135690] = true, -- Dread-Admiral Tattersail
}

local gossipWhitelist = {
    -- Rogue Classhall
    [97004]  = true, -- "Red" Jack Findle
	[96782]  = true, -- Lucian Trias
	[93188]  = true, -- Mongar
    -- followerAssignees
	[135614] = true, -- Master Mathias Shaw
    [138708] = true, -- Garona Halforcen
}

local gossipConfirmList = {
    [57850]  = true, -- Teleportologist Fozlebub
    [55382]  = true, -- Darkmoon Faire Mystic Mage (Horde)
    [54334]  = true, -- Darkmoon Faire Mystic Mage (Alliance)
}

function AG:GOSSIP_SHOW()
    if E.db.RhythmBox.AutoGossip.ShiftKeyIgnore and IsShiftKeyDown() then return end
    local npcID = GetNPCID()
    if not npcID or blacklist[npcID] then return end
    if GetNumGossipActiveQuests() == 0 and GetNumGossipAvailableQuests() == 0 then
        -- no quest active or available
        if gossipBlacklist[npcID] then return end
        local numGossipOptions = GetNumGossipOptions()
        if E.db.RhythmBox.AutoGossip.AutoGossip and numGossipOptions == 1 then
            local _, instance = GetInstanceInfo()
            if instance ~= 'raid' then
                SelectGossipOption(1)
            end
        elseif E.db.RhythmBox.AutoGossip.AutoGossipInnkeeper and numGossipOptions == 2 and GetBindLocation() == GetSubZoneText() then
            -- Innkeeper
            local _, g1, _, g2  = GetGossipOptions()
            if g1 == 'binder' and g2 == 'vendor' then
                SelectGossipOption(2)
            elseif g1 == 'vendor' and g2 == 'binder' then
                SelectGossipOption(1)
            end
        elseif E.db.RhythmBox.AutoGossip.AutoGossipWhitelist and gossipWhitelist[npcID] then
            SelectGossipOption(1)
        end
    end
end

function AG:GOSSIP_CONFIRM(event, index)
    if E.db.RhythmBox.AutoGossip.ShiftKeyIgnore and IsShiftKeyDown() then return end
    local npcID = GetNPCID()
    if E.db.RhythmBox.AutoGossip.AutoGossipConfirm and npcID and gossipConfirmList[npcID] then
        SelectGossipOption(index, '', true)
        StaticPopup_Hide('GOSSIP_CONFIRM')
    end
end

function AG:Initialize()
    self:RegisterEvent('GOSSIP_SHOW')
    self:RegisterEvent('GOSSIP_CONFIRM')
end

P["RhythmBox"]["AutoGossip"] = {
    ["ShiftKeyIgnore"] = true,
    ["AutoGossip"] = true,
    ["AutoGossipInnkeeper"] = true,
    ["AutoGossipWhitelist"] = true,
    ["AutoGossipConfirm"] = true,
}
local tbl = {
    Blacklist = blacklist,
    GossipBlacklist = gossipBlacklist,
    GossipWhitelist = gossipWhitelist,
    GossipConfirmList = gossipConfirmList,
}
for name, value in pairs(tbl) do
    P["RhythmBox"]["AutoGossip"][name] = {}
    for npcID in pairs(value) do
        P["RhythmBox"]["AutoGossip"][name][npcID] = true
    end
end

local function AutoGossipOptions()
    E.Options.args.RhythmBox.args.AutoGossip = {
        order = 4,
        type = 'group',
        name = "自动对话",
        get = function(info) return E.db.RhythmBox.AutoGossip[ info[#info] ] end,
        set = function(info, value) E.db.RhythmBox.AutoGossip[ info[#info] ] = value; end,
        args = {
            AutoGossip = {
                order = 1,
                type = 'toggle',
                name = "自动选择唯一选项",
            },
            AutoGossipInnkeeper = {
                order = 2,
                type = 'toggle',
                name = "自动与已绑定旅店老板交易",
            },
            AutoGossipWhitelist = {
                order = 3,
                type = 'toggle',
                name = "自动与白名单对话",
            },
            AutoGossipConfirm = {
                order = 4,
                type = 'toggle',
                name = "自动确认弹出框",
            },
            ShiftKeyIgnore = {
                order = 5,
                type = 'toggle',
                name = "按下SHIFT键暂时停用",
            },
            Blacklist = {
                order = 6,
                type = 'multiselect',
                name = "NPC黑名单",
                get = function(info, k) return E.db.RhythmBox.AutoGossip.Blacklist[k] end,
                set = function(info, k, v) E.db.RhythmBox.AutoGossip.Blacklist[k] = v end,
                values = {},
            },
            GossipBlacklist = {
                order = 7,
                type = 'multiselect',
                name = "对话NPC黑名单",
                get = function(info, k) return E.db.RhythmBox.AutoGossip.GossipBlacklist[k] end,
                set = function(info, k, v) E.db.RhythmBox.AutoGossip.GossipBlacklist[k] = v end,
                values = {},
            },
            GossipWhitelist = {
                order = 8,
                type = 'multiselect',
                name = "对话NPC白名单",
                get = function(info, k) return E.db.RhythmBox.AutoGossip.GossipWhitelist[k] end,
                set = function(info, k, v) E.db.RhythmBox.AutoGossip.GossipWhitelist[k] = v end,
                values = {},
            },
            GossipConfirmList = {
                order = 9,
                type = 'multiselect',
                name = "弹出框NPC白名单",
                get = function(info, k) return E.db.RhythmBox.AutoGossip.GossipConfirmList[k] end,
                set = function(info, k, v) E.db.RhythmBox.AutoGossip.GossipConfirmList[k] = v end,
                values = {},
            },
        },
    }
    for name, value in pairs(tbl) do
        for npcID in pairs(value) do
            E.Options.args.RhythmBox.args.AutoGossip.args[name].values[npcID] = GetNPCName(npcID) or npcID
        end
    end
end
tinsert(R.Config, AutoGossipOptions)

function AG:UpdateNPCName()
    for name, value in pairs(tbl) do
        for npcID in pairs(value) do
            GetNPCName(npcID) -- fetch npc name
        end
    end
end

local function InitializeCallback()
    AG:Initialize()
    -- don't suck login
    AG:ScheduleTimer("UpdateNPCName", 1)
end

E:RegisterModule(AG:GetName(), InitializeCallback)