-----------------------------------------------------
--File Name    : UICommonButtonListContent.lua
--Author       : Edward J
--Create Time  : 2018-03-13
--Description  : UICommonButtonListContent
-----------------------------------------------------
local luaclass           = require("luaclass")
local WndBase            = require("WndBase")
local UICommonButtonListContent = luaclass("UICommonButtonListContent", WndBase)

local UIDef                     = require("UIDef")
local UIManager                 = require("UIManager")
local CommonButtonListTypeDef   = require("CommonButtonListTypeDef")
-----------------------------------------------------
local GetLocalSize    = SlateBlueprintLibrary.GetLocalSize
local LocalToAbsolute = SlateBlueprintLibrary.LocalToAbsolute
local pVector         = KismetMathLibrary.MakeVector2D(0, 0)

UICommonButtonListContent.pBasePanel     = nil
UICommonButtonListContent.tbPrefabScript = {}
-----------------------------------------------------

function UICommonButtonListContent:AddBtnsToBasePanel(pBtnWidget)
    local pSlot = self.pBasePanel:AddChild(pBtnWidget)
    pSlot:SetAutoSize(true)
    return pSlot
end

function UICommonButtonListContent:CreateBtnsList(pTargetWidgetRef, tbArgs, pScreenPos, pSize, nLayoutType)
    assert(pTargetWidgetRef)
    assert(tbArgs)
    assert(self.tbPrefabScript[pTargetWidgetRef] == nil)
    nLayoutType =  nLayoutType == nil and CommonButtonListTypeDef.LayoutType.Cross or nLayoutType
    local pGeometry = pTargetWidgetRef:GetCachedGeometry()
    tbArgs.pScreenPos = pScreenPos or LocalToAbsolute(pGeometry, pVector)
    tbArgs.pSize = pSize or GetLocalSize(pGeometry)
    tbArgs.nLayoutType = nLayoutType
    tbArgs.pUIBasePanel = self.pBasePanel
    local pBtnScript, pBtnWidget = self.PrefabHelper:CreatePrefab(UIDef.UP_COMMONBUTTONLIST)
    self.tbPrefabScript[pTargetWidgetRef] = pBtnScript
    self:AddBtnsToBasePanel(pBtnWidget)
    tbArgs.pTargetWidgetUID = pTargetWidgetRef
    tbArgs.pParent = self
    pBtnScript:OnSetData(tbArgs)
    return pBtnScript
end

function UICommonButtonListContent:ToggleBtnsList(pTargetWidgetRef, tbArgs, pScreenPos, pSize, nLayoutType)
    if (self.tbPrefabScript[pTargetWidgetRef] == nil) then
        self:CreateBtnsList(pTargetWidgetRef, tbArgs, pScreenPos, pSize, nLayoutType)
        return true
    else
        self:DestoryButtonList(pTargetWidgetRef)
        return false
    end
end

function UICommonButtonListContent:DestoryButtonList(pTargetWidgetRef)
    local pBoxPrefabScript = self.tbPrefabScript[pTargetWidgetRef]
    if (pBoxPrefabScript == nil) then
        return false
    end
    self:RemoveBtnBoxFromParent(pBoxPrefabScript)
    self.tbPrefabScript[pTargetWidgetRef] = nil
    self:AutoCloseWnd()
    return true
end

function UICommonButtonListContent:AutoCloseWnd()
    if (next(self.tbPrefabScript) == nil) then
        UIManager:CloseWnd(UIDef.UI_CommonButtonList)
    end
end

function UICommonButtonListContent:RemoveBtnBoxFromParent(pBoxPrefabScript)
    self.pBasePanel:RemoveChild(pBoxPrefabScript.pWidgetRef)
    self.PrefabHelper:UnbindPrefab(pBoxPrefabScript)
end

function UICommonButtonListContent:RemoveAllBtnBoxFromParent()
    for k,v in pairs(self.tbPrefabScript) do
        self:RemoveBtnBoxFromParent(v)
    end
end

function UICommonButtonListContent:OnLoad()
    self.pBasePanel     = nil
    self.tbPrefabScript = {}
end

function UICommonButtonListContent:OnShow()
    self.pBasePanel = self.pWidgetRef.pBasePanel
end

function UICommonButtonListContent:OnHide()
    self:RemoveAllBtnBoxFromParent()
    self.tbPrefabScript = {}
end

return UICommonButtonListContent