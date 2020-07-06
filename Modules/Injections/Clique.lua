local R, E, L, V, P, G = unpack(select(2, ...))
local RI = R:GetModule('Injections')

-- Lua functions
local _G = _G
local ipairs = ipairs

-- WoW API / Variables

local classNames = {}
for classID = 1, GetNumClasses() do
    local classInfo = C_CreatureInfo.GetClassInfo(classID)
    if classInfo then
        classNames[classInfo.className] = true
    end
end

function RI:Clique()
    local Clique = _G.Clique

    if Clique.db:GetCurrentProfile() ~= E.myLocalizedClass then
        Clique.db:SetProfile(E.myLocalizedClass)
    end

    local profiles = Clique.db:GetProfiles()
    for _, profileName in ipairs(profiles) do
        if not classNames[profileName] then
            Clique.db:DeleteProfile(profileName, true)
        end
    end
end

RI:RegisterInjection(RI.Clique, 'Clique')
