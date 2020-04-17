local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local RI = R:GetModule('Injections')

-- Lua functions
local _G = _G

-- WoW API / Variables

function RI:RareScanner()
    local RareScanner = E.Libs.AceAddon:GetAddon('RareScanner')
    RareScanner.db.char.scannerXPos = 987
    RareScanner.db.char.scannerYPos = 65

    local button = _G.scanner_button
    button:ClearAllPoints()
    button:SetPoint('BOTTOMLEFT', RareScanner.db.char.scannerXPos, RareScanner.db.char.scannerYPos)
end

RI:RegisterInjection(RI.RareScanner, 'RareScanner')
