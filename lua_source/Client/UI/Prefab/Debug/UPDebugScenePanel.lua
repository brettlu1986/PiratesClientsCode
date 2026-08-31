-----------------------------------------------------
--File Name    : UPDebugScenePanel.lua
--Author       : Song Fuhao
--Create Time  : 2018-04-19
--Description  : Debug场景面板
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPDebugScenePanel = luaclass("UPDebugScenePanel", PrefabBase)

local UIDef = require("UIDef")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local GMQADataTable = require("GMQADataTable")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local PADDING_TEXT_BLOCK = Margin{Left=0, Top=0, Right=0, Bottom=5}
local PADDING_WRAP_BOX = Margin{Left=0, Top=0, Right=0, Bottom=20}

local function GetCommandGroupList()
    if GlobalVariableSystem:IsInDungeon() then
        return GMQADataTable:GetDungeonCommandGroupList()
    else
        return GMQADataTable:GetLobbyCommandGroupList()
    end
end

local function AddTextBlockToContainer(self, szText)
    local pTextBlock = self.WidgetHelper:CreateWidget(TextBlock)
    local pSlot = self.pWidgetRef.vboxContainer:AddChild(pTextBlock)

    pSlot:SetPadding(PADDING_TEXT_BLOCK)
    pTextBlock:SetText(szText)
    UISetUtils.SetTextblockFont(pTextBlock, UIResourceDef.FFA_FONT_RES_PINGFANG:load(), "Bold")
    UISetUtils.SetTextblockFontSize(pTextBlock, 22)
end

local function AddCommandButtonToGroup(self, pWrapBox, tbCommand)
    local pbCommandButton, pCommandButtonRef = self.PrefabHelper:CreatePrefab(UIDef.UP_DYNAMIC_DEBUG_SCENE_BUTTON)
    pbCommandButton:Init(tbCommand)
    pWrapBox:AddChild(pCommandButtonRef)
end

local function AddCommandButtonGroupToContainer(self, tbCommandList)
    local pWrapBox = self.WidgetHelper:CreateWidget(WrapBox)
    local pSlot = self.pWidgetRef.vboxContainer:AddChild(pWrapBox)
    pSlot:SetPadding(PADDING_WRAP_BOX)
    for _, tbCommand in ipairs(tbCommandList) do
        AddCommandButtonToGroup(self, pWrapBox, tbCommand)
    end
end

function UPDebugScenePanel:OnLoad()
    local tbCommandGroupList = GetCommandGroupList()
    for _, tbGroup in ipairs(tbCommandGroupList) do
        AddTextBlockToContainer(self, tbGroup.szGroupName)
        AddCommandButtonGroupToContainer(self, tbGroup.tbCommandList)
    end
end

return UPDebugScenePanel
