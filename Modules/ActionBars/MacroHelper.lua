local R, E, L, V, P, G = unpack(select(2, ...))
local AB = R:GetModule('ActionBars')

-- Lua functions
local format, ipairs, pairs, select, tinsert, unpack = format, ipairs, pairs, select, tinsert, unpack

-- WoW API / Variables
local C_MountJournal_GetMountInfoByID = C_MountJournal and C_MountJournal.GetMountInfoByID
local CreateMacro = CreateMacro
local EditMacro = EditMacro
local GetItemCount = GetItemCount
local GetItemInfo = GetItemInfo
local GetMacroInfo = GetMacroInfo
local GetNumMacros = GetNumMacros
local GetNumShapeshiftForms = GetNumShapeshiftForms
local GetShapeshiftFormInfo = GetShapeshiftFormInfo
local InCombatLockdown = InCombatLockdown

AB.MountMacroName = '组合坐骑宏'
AB.MountMacro =
'#showtooltip [mod:shift]%3$s;[mod:ctrl]%4$s;[mod:alt]%5$s;%6$s\n' ..
'/cancelform [nomounted,nomod,nocombat,outdoors%1$s]\n' ..
'/use [mod:shift]%3$s;[mod:ctrl]%4$s;[mod:alt]%5$s;%2$s\n' ..
'/run C_MountJournal.SummonByID(0)\n' ..
'/dismount [mounted]\n'
AB.MountTable = {
    382, -- X-53 Touring Rocket
    855, -- Darkwater Skate
    460, -- Grand Expedition Yak
    881, -- Arcanist's Manasaber
}

AB.FixedMacros = {
    ['M自动进组'] = {
        actionSlot = 39, -- MULTIACTIONBAR4BUTTON3
        content = '/w 小只小猎手-拉文凯斯 123',
        icon = 'ACHIEVEMENT_GUILDPERK_GMAIL',
    },
}

AB.CombatMacros = {
    ['回血保命宏'] = {
        actionSlot = 54, -- MULTIACTIONBAR2BUTTON6
        [1] = {
            5512,   -- Healthstone
            156634, -- Silas' Vial of Continuous Curing
            166799, -- Emerald of Vigor
            169451, -- Abyssal Healing Potion
            152494, -- Coastal Healing Potion
        },
        [2] = {
            156634, -- Silas' Vial of Continuous Curing
            166799, -- Emerald of Vigor
            169451, -- Abyssal Healing Potion
            152494, -- Coastal Healing Potion
        },
        template =
        '#showtooltip\n' ..
        '/use %s\n' ..
        '/use [mod:ctrl] %s\n',
        fallback = {5512, 169451},
    },
    ['药水食物宏'] = {
        actionSlot = 55, -- MULTIACTIONBAR2BUTTON7
        ['HEALER'] = {
            [1] = {
                152561, -- Potion of Replenishment
            },
            [2] = {
                152495, -- Coastal Mana Potion
            },
            [3] = {
                113509, -- Conjured Mana Bun
                159867, -- Rockskip Mineral Water
                163784, -- Seafoam Coconut Water
                163692, -- Scroll of Subsistence
            },
            template =
            '#showtooltip\n' ..
            '/use [combat, mod:ctrl] %s; [combat] %s\n' ..
            '/stopmacro [combat]\n' ..
            '/use %s\n',
            fallback = {152561, 152495, 113509},
        },
        ['TANK'] = {
            [1] = {
                168501, -- Superior Steelskin Potion
                152557, -- Steelskin Potion
                163082, -- Coastal Rejuvenation Potion
                166801, -- Sapphire of Brilliance
                142117, -- Potion of Prolonged Power
            },
            [2] = {
                113509, -- Conjured Mana Bun
            },
            template =
            '#showtooltip\n' ..
            '/use [combat] %s\n' ..
            '/stopmacro [combat]\n' ..
            '/use %s\n',
            fallback = {142117, 113509},
        },
        ['DAMAGER'] = {
            [1] = {
                169299, -- Potion of Unbridled Fury
                166801, -- Sapphire of Brilliance
                142117, -- Potion of Prolonged Power
            },
            [2] = {
                113509, -- Conjured Mana Bun
            },
            template =
            '#showtooltip\n' ..
            '/use [combat] %s\n' ..
            '/stopmacro [combat]\n' ..
            '/use %s\n',
            fallback = {142117, 113509},
        },
    },
}

function AB:UpdateMountMacro()
    if InCombatLockdown() then
        self:RegisterEvent('PLAYER_REGEN_ENABLED')
        return
    end

    local mount = {}
    for _, mountID in ipairs(self.MountTable) do
        local creatureName = C_MountJournal_GetMountInfoByID(mountID)
        if not creatureName then
            return self:ScheduleTimer('UpdateMountMacro', 1)
        end
        tinsert(mount, creatureName)
    end

    local broomName = GetItemInfo(37011) -- Magic Broom
    if not broomName then
        return self:ScheduleTimer('UpdateMountMacro', 1)
    end

    local condition = ''
    if E.myclass == 'DRUID' then
        for i = 1, GetNumShapeshiftForms() do
            local spellID = select(4, GetShapeshiftFormInfo(i))
            if spellID == 24858 then -- Moonkin Form
                condition = ',noform:' .. i
                break
            end
        end
    end

    local text = format(self.MountMacro, condition, broomName, unpack(mount))
    local name = GetMacroInfo(self.MountMacroName)
    if not name then
        local numGlobal = GetNumMacros()
        if numGlobal < 72 then
            CreateMacro(self.MountMacroName, 'INV_MISC_QUESTIONMARK', text)
        end
    else
        EditMacro(self.MountMacroName, nil, nil, text)
    end
end

function AB:UpdateFixedMacro()
    if InCombatLockdown() then
        -- should not happen
        self:RegisterEvent('PLAYER_REGEN_ENABLED')
        return
    end

    for macroName, tbl in pairs(self.FixedMacros) do
        local name = GetMacroInfo(macroName)
        if not name then
            local numGlobal = GetNumMacros()
            if numGlobal < 72 then
                CreateMacro(macroName, tbl.icon or 'INV_MISC_QUESTIONMARK', tbl.content)
            end
        else
            EditMacro(macroName, nil, nil, tbl.content)
        end
    end
end

function AB:UpdateCombatMacro()
    if InCombatLockdown() then
        self:RegisterEvent('PLAYER_REGEN_ENABLED')
        return
    end

    for macroName, tbl in pairs(self.CombatMacros) do
        local curr = tbl.template and tbl or tbl[E.myrole]

        if curr then
            local length = #curr
            local result = {}
            for i = 1, length do
                for _, itemID in ipairs(curr[i]) do
                    local count = GetItemCount(itemID)
                    if count and count > 0 then
                        result[i] = GetItemInfo(itemID)
                        break
                    end
                end
            end
            for i = 1, length do
                if not result[i] then
                    local fallback = GetItemInfo(curr.fallback[i])
                    if not fallback then
                        self:ScheduleTimer('UpdateCombatMacro', 1)
                        return
                    end
                    result[i] = fallback
                end
            end

            local text = format(curr.template, unpack(result))
            local name = GetMacroInfo(macroName)
            if not name then
                local numGlobal = GetNumMacros()
                if numGlobal < 72 then
                    CreateMacro(macroName, 'INV_MISC_QUESTIONMARK', text)
                end
            else
                EditMacro(macroName, nil, nil, text)
            end
        end
    end
end

function AB:PLAYER_SPECIALIZATION_CHANGED()
    if E.myclass == 'DRUID' then
        self:UpdateMountMacro()
    end
    self:UpdateCombatMacro()
end

function AB:PLAYER_REGEN_ENABLED()
    self:UnregisterEvent('PLAYER_REGEN_ENABLED')
    self:UpdateCombatMacro()
    self:UpdateFixedMacro()
    self:UpdateMountMacro()
end

function AB:MacroHelper()
    if R.Classic then return end

    self:RegisterEvent('BAG_UPDATE_DELAYED', 'UpdateCombatMacro')
    self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')

    if not InCombatLockdown() then
        self:UpdateCombatMacro()
        self:UpdateFixedMacro()
        self:UpdateMountMacro()
    else
        self:RegisterEvent('PLAYER_REGEN_ENABLED')
    end
end
