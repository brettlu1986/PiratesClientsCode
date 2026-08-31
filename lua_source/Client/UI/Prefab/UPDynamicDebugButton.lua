-----------------------------------------------------
--File Name    : UPDynamicDebugButton.lua
--Author       : Song Fuhao
--Create Time  : 2017-07-17
--Description  : UPDynamicDebugButton
-----------------------------------------------------

local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPDynamicDebugButton = luaclass("UPDynamicDebugButton", PrefabBase)

UPDynamicDebugButton.pClass = nil
UPDynamicDebugButton.szFunctionName = nil

local function CallFunction( self, bChecked )
    self.pClass[self.szFunctionName](bChecked, GWorld)
    log("[DynamicDebugPanel] Call function ", self.szFunctionName, ", param :", bChecked)
end

local function OnCheckStateChanged( self, bChecked )
    if self.pClass then
        CallFunction(self, bChecked)
        log("[DynamicDebugPanel] State changed, functionName =", self.szFunctionName, ", current state is ", bChecked)
    else
        self.pWidgetRef.cbButton:SetCheckedState(bChecked and ECheckBoxState.Unchecked or ECheckBoxState.Checked)
        log("[DynamicDebugPanel] State change failed, class is nil, FunctionName =", self.szFunctionName)
    end
end

function UPDynamicDebugButton:OnBindEvent( Helper )
    Helper:RegisterCppDelegate(self.pWidgetRef.cbButton.OnCheckStateChanged, self, OnCheckStateChanged)
end

function UPDynamicDebugButton:OnEnter()
    --CallFunction(self, self.pWidgetRef.cbButton:IsChecked())
end

function UPDynamicDebugButton:Init( pClass, szFunctionName )
    self.pClass = pClass
    self.szFunctionName = szFunctionName
    self.pWidgetRef.txtButton:SetText(szFunctionName)
end

return UPDynamicDebugButton
