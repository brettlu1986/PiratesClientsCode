-----------------------------------------------------
--File Name    : UPDebugCustomPanel.lua
--Author       : Song Fuhao
--Create Time  : 2018-04-19
--Description  : Debug自定义面板
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPDebugCustomPanel = luaclass("UPDebugCustomPanel", PrefabBase)

local UIDef = require("UIDef")

local BP_DEBUG_CLASS = "/Game/Game/Ships/Misc/BP_DynamicDebugSwitches.BP_DynamicDebugSwitches_C"
UPDebugCustomPanel.pClassHolder = nil

function UPDebugCustomPanel:OnLoad()
    local pDebugClass = BP_DEBUG_CLASS:load()
    self.pClassHolder = luaholder(pDebugClass)
    local tbFunctionNames = ExtendBlueprintFunctions.GetAllFunctionNameByClass(pDebugClass)
    for _, v in ipairs(tbFunctionNames) do
        if v ~= "MakeStringAssetReference" then
            local tbButton = self.PrefabHelper:CreatePrefab(UIDef.UP_DYNAMIC_DEBUG_BUTTON)
            tbButton:Init(pDebugClass, v)
            self.pWidgetRef.wpCustomContainer:AddChild(tbButton.pWidgetRef)
        end
    end
    self.bCustomPanelInited = true
end

function UPDebugCustomPanel:OnUnload()
    self.pClassHolder = nil
end

return UPDebugCustomPanel
