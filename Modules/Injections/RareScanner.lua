local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local RI = R:GetModule('Injections')

-- Lua functions

-- WoW API / Variables

function RI:RareScanner()
    local RareScanner = LibStub('AceAddon-3.0'):GetAddon('RareScanner')
    RareScanner.db.char.scannerXPos = 1040
    RareScanner.db.char.scannerYPos = 70

    local button = _G.scanner_button
    button:ClearAllPoints()
    button:SetPoint('BOTTOMLEFT', RareScanner.db.char.scannerXPos, RareScanner.db.char.scannerYPos)
end

RI:RegisterInjection(RI.RareScanner, 'RareScanner')
