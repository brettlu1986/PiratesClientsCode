-----------------------------------------------------
--File Name    : UPButtonListContent.lua
--Author       : Edward J
--Create Time  : 2018-04-26
--Description  : UPButtonListContent
-----------------------------------------------------
local luaclass              = require("luaclass")
local PrefabBase            = require("PrefabBase")
local UPButtonListContent   = luaclass("UPButtonListContent", PrefabBase)

local UIDef                     = require("UIDef")
local ClientEventDef            = require("ClientEventDef")
local CommonButtonListTypeDef   = require("CommonButtonListTypeDef")
-----------------------------------------------------
local GetLocalSize          = SlateBlueprintLibrary.GetLocalSize
local LocalToAbsolute       = SlateBlueprintLibrary.LocalToAbsolute
local pVector               = KismetMathLibrary.MakeVector2D(0, 0)
local SelfHitTestInvisible  = ESlateVisibility.SelfHitTestInvisible
local Collapsed             = ESlateVisibility.Collapsed

UPButtonListContent.pBasePanel     = nil
UPButtonListContent.pPrefabScript = nil
-----------------------------------------------------

local function OnBtnClose(self)
    self:DestoryButtonList()
end

function UPButtonListContent:AddBtnsToBasePanel(pBtnWidget)
    local pSlot = self.pBasePanel:AddChild(pBtnWidget)
    pSlot:SetAutoSize(true)
    return pSlot
end

function UPButtonListContent:CreateBtnsList(pTargetWidgetRef, tbArgs, nLayoutType)
    assert(pTargetWidgetRef)
    assert(tbArgs)
    self:DestoryButtonList()
    nLayoutType = nLayoutType == nil and CommonButtonListTypeDef.LayoutType.Cross or nLayoutType
    local pGeometry = pTargetWidgetRef:GetCachedGeometry()
    tbArgs.pScreenPos = LocalToAbsolute(pGeometry, pVector)
    tbArgs.pSize = GetLocalSize(pGeometry)
    tbArgs.nLayoutType = nLayoutType
    tbArgs.pUIBasePanel = self.pBasePanel
    local pBtnScript, pBtnWidget = self.PrefabHelper:CreatePrefab(UIDef.UP_COMMONBUTTONLIST)
    self.pPrefabScript = pBtnScript
    self:AddBtnsToBasePanel(pBtnWidget)
    tbArgs.pTargetWidgetUID = pTargetWidgetRef
    tbArgs.pParent = self
    pBtnScript:OnSetData(tbArgs)
    self:Activate()
    return pBtnScript
end

function UPButtonListContent:DestoryButtonList()
    if not self.pPrefabScript then
        return
    end
    self:RemoveBtnBoxFromParent(self.pPrefabScript)
    self.pPrefabScript = nil
    self:Deactivate()
    return true
end

function UPButtonListContent:Activate()
    self.pWidgetRef.cvsContent:SetVisibility(SelfHitTestInvisible)
end

function UPButtonListContent:Deactivate()
    self.pWidgetRef.cvsContent:SetVisibility(Collapsed)
end

function UPButtonListContent:RemoveBtnBoxFromParent(pBoxPrefabScript)
    self.pBasePanel:RemoveChild(pBoxPrefabScript.pWidgetRef)
    self.PrefabHelper:UnbindPrefab(pBoxPrefabScript)
end

function UPButtonListContent:RemoveAllBtnBoxFromParent()
    for k,v in pairs(self.tbPrefabScript) do
        self:RemoveBtnBoxFromParent(v)
    end
end

function UPButtonListContent:OnLoad()
    self.pBasePanel = self.pWidgetRef.pBasePanel
    self:Deactivate()
end

function UPButtonListContent:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnClose.OnClicked, self, OnBtnClose)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHAT_CLOSE_BTNLIST, self, OnBtnClose)
end

return UPButtonListContent