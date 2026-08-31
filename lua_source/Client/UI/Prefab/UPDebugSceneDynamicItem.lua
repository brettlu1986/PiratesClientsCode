-----------------------------------------------------
--File Name    : UPDebugSceneDynamicItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-07-02
--Description  : UPDebugSceneDynamicItem
-----------------------------------------------------

local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPDebugSceneDynamicItem = luaclass("UPDebugSceneDynamicItem", PrefabBase)

local function OnClickedBtnCommand(self)
    if self.szCommand then
        -- 此处需要手动取一下
        local PC = ExtendBlueprintFunctions.GetFirstLocalPlayerController(GWorld)
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, self.szCommand, PC)
    end
end

function UPDebugSceneDynamicItem:OnBindEvent(Helper)
    Helper:RegisterCppDelegate(self.pWidgetRef.btnCommand.OnClicked, self, OnClickedBtnCommand)
end

function UPDebugSceneDynamicItem:Init(tbCommand)
    self.szCommand = tbCommand.szCommand
    self.pWidgetRef.txtCommand:SetText(tbCommand.szCommandDisplayName)
end

return UPDebugSceneDynamicItem
