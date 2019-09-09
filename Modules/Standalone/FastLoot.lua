-- From ProjectAzilroka
-- https://git.tukui.org/Azilroka/ProjectAzilroka/blob/master/Modules/FasterLoot.lua

local R, E, L, V, P, G = unpack(select(2, ...))

local FL = E:NewModule('RhythmBox_FastLoot', 'AceEvent-3.0')

function FL:LOOT_READY()
    local NumLootItems = GetNumLootItems()
    if NumLootItems == 0 then
        CloseLoot()
        return
    end

    if self.isLooting then
        return
    end

    if (GetCVar('autoLootDefault') == '1' and not IsModifiedClick('AUTOLOOTTOGGLE')) or (GetCVar('autoLootDefault') ~= '1' and IsModifiedClick('AUTOLOOTTOGGLE')) then
        for i = NumLootItems, 1, -1 do
            LootSlot(i)
        end

        self.isLooting = true

        C_Timer.After(.3, function() FL.isLooting = false end)
    end
end

function FL:Initialize()
    self:RegisterEvent('LOOT_READY')
end

local function InitializeCallback()
    FL:Initialize()
end

E:RegisterModule(FL:GetName(), InitializeCallback)
