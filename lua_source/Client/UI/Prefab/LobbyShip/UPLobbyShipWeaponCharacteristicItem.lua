-----------------------------------------------------
--File Name    : UPLobbyShipWeaponCharacteristicItem.lua
--Author       : chenyixin
--Description  : 舰船武器界面详情UP
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPLobbyShipWeaponCharacteristicItem = luaclass("UPLobbyShipWeaponCharacteristicItem", PrefabBase)

local UISetUtils = require("UISetUtils")

local GetSlateColorFunc = KMUMGLibrary.GetSlateColor

local COLORS = {
    ["Yellow"] = {
        ["SLATE_COLOR"] = GetSlateColorFunc(0.215861, 0.130136, 0.036889, 1.0),
    },
    ["Blue"] = {
        ["SLATE_COLOR"] = GetSlateColorFunc(0.034340, 0.090842, 0.174647, 1.0),
    },
    ["Green"] = {
        ["SLATE_COLOR"] = GetSlateColorFunc(0.057805, 0.141263, 0.036889, 1.0),
    },
    ["Red"] = {
        ["SLATE_COLOR"] = GetSlateColorFunc(0.283149, 0.056128, 0.080220, 1.0),
    },
}

local INDEX_TO_COLOR = {
    [1] = "Yellow",
    [2] = "Blue",
    [3] = "Green",
    [4] = "Red",
}

function UPLobbyShipWeaponCharacteristicItem:OnLoad()
end

function UPLobbyShipWeaponCharacteristicItem:OnUnload()
end

-------------------------------------------------------------------------------

function UPLobbyShipWeaponCharacteristicItem:GetAllColors()
    return COLORS
end

function UPLobbyShipWeaponCharacteristicItem:SetColorByName(szColor)
    if COLORS[szColor] then
        UISetUtils.SetBorderBrushColor(self.pWidgetRef.Border_0, COLORS[szColor])
    else
        log("[LobbyShip] UPLobbyShipWeaponCharacteristicItem:SetColorByName Color is invalid: ", szColor)
    end
end

function UPLobbyShipWeaponCharacteristicItem:SetColorByIndex(nIndex)
    local szColor = ""
    if INDEX_TO_COLOR[nIndex] then
        szColor = INDEX_TO_COLOR[nIndex]
    else
        szColor = INDEX_TO_COLOR[1]
    end

    if COLORS[szColor] then
        UISetUtils.SetBorderBrushColor(self.pWidgetRef.Border_0, COLORS[szColor])
    else
        log("[LobbyShip] UPLobbyShipWeaponCharacteristicItem:SetColorByName Color is invalid: ", szColor)
    end
end

function UPLobbyShipWeaponCharacteristicItem:SetText(szText)
    self.pWidgetRef.KMTextBlock_0:SetText(szText)
end

function UPLobbyShipWeaponCharacteristicItem:SetVisibility(pVisibility)
    self.pWidgetRef:SetVisibility(pVisibility)
end

return  UPLobbyShipWeaponCharacteristicItem