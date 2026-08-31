-----------------------------------------------------
--File Name    : UPDebugShipMoveInputController.lua
--Author       : WuJizhou
--Create Time  : 2018-6-29 11:48:47
--Description  : UPDebugShipMoveInputController
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")

local L10N = require("L10N")
local UPDebugShipMoveInputController = luaclass("UPDebugShipMoveInputController", ListItemBase)

UPDebugShipMoveInputController.nShipMoveControllerType = nil
UPDebugShipMoveInputController.fnCallback = nil
UPDebugShipMoveInputController.tbParams = nil

local function KTToCM(nKTValue)
    local nCMValue = nKTValue * 100 / 1.6
    return nCMValue
end

local function ControlShipMoveValue(nType, nValue)
    nValue = KTToCM(nValue)
    local szCommand = string.format("dm setgeardata %s %s", tostring(nType), tostring(nValue))
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, szCommand, GameplayStatics.GetPlayerController(GWorld, 0))
end

local function OnConfirmed(self)
    local szValue = L10N:ToString(self.pWidgetRef.txtValue:GetText())
    local nValue = tonumber(szValue)
    if nValue ~= nil then
        ControlShipMoveValue(self.nShipMoveControllerType, nValue)
        if self.fnCallback ~= nil then
            self.fnCallback(self.tbParams, nValue)
        end
    end
end



function UPDebugShipMoveInputController:OnRefresh(tbData)
    self.super.OnRefresh(self, tbData)
    if tbData ~= nil then
        self.nShipMoveControllerType = tbData.nType
        self.pWidgetRef.txtName:SetText(tbData.szName)
        self.fnCallback = tbData.fnCallback
        self.tbParams = tbData.tbParams
    end
end
----------life cycle----------
-- function UPDebugShipMoveInputController:OnCreate()
-- end

-- function UPDebugShipMoveInputController:OnDestroy()
-- end

-- function UPDebugShipMoveInputController:OnLoad()
-- end

-- function UPDebugShipMoveInputController:OnUnload()
-- end

-- function UPDebugShipMoveInputController:OnEnter()
-- end

-- function UPDebugShipMoveInputController:OnShow()
-- end

-- function UPDebugShipMoveInputController:OnHide()
-- end

-- function UPDebugShipMoveInputController:OnExit()
-- end

function UPDebugShipMoveInputController:OnBindEvent( EventHelper )
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnConfirm.OnClicked, self, OnConfirmed)
end

-- function UPDebugShipMoveInputController:OnUnbindEvent( EventHelper )
-- end

return UPDebugShipMoveInputController