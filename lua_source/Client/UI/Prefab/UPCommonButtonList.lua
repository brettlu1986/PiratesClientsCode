-----------------------------------------------------
--File Name    : UPCommonViewButtonBase.lua
--Author       : Edward J
--Create Time  : 2018-03-13
--Description  : UICommonButtonList
-----------------------------------------------------
local luaclass          = require("luaclass")
local PrefabBase        = require("PrefabBase")
local UPCommonButtonList = luaclass("UPCommonButtonList", PrefabBase)

local UIDef                     = require("UIDef")
local CommonButtonListTypeDef   = require("CommonButtonListTypeDef")
-----------------------------------------------------
local PADDING = Margin{Left=4, Right=4, Top=2, Bottom=2}

UPCommonButtonList.CommonButton         = UIDef.UP_LOBBY_TEAM_POP_MENU_ITEM --UIDef.UP_COMMONVIEWBUTTON 
UPCommonButtonList.tbArgs               = nil 
UPCommonButtonList.tbWidgets            = nil
-----------------------------------------------------

local function CrossLayout(pBoxWidget, pUIBasePanel, pScreenPos, pSize) --十字布局法
    -- body
    if pSize == nil then
        pSize = {X = 0,Y = 0}
    end
    local pGeometry = pUIBasePanel:GetCachedGeometry()
    local pLocalPos = SlateBlueprintLibrary.AbsoluteToLocal(pGeometry, pScreenPos)
    local nLocalPosX = pLocalPos.X
    local nLocalPosY = pLocalPos.Y
    local pBoxSize = pBoxWidget:GetDesiredSize()
    local nBoxSizeX = pBoxSize.X
    local nBoxSizeY = pBoxSize.Y
    local bdrSize = SlateBlueprintLibrary.GetLocalSize(pGeometry)
    local nbdrSizeX = bdrSize.X
    local nbdrSizeY = bdrSize.Y
    local nBoxPosX = nLocalPosX
    local nBoxPosY = nLocalPosY
    local MiddleX = nbdrSizeX * 0.5
    local MiddexY = nbdrSizeY * 0.5
    if nLocalPosX <= MiddleX and nLocalPosY  <= MiddexY then --左上
        nBoxPosX = nLocalPosX + pSize.X
        nBoxPosY = nLocalPosY
    elseif nLocalPosX > MiddleX and nLocalPosY <= MiddexY then --右上
        nBoxPosX = nLocalPosX - nBoxSizeX
        nBoxPosY = nLocalPosY
    elseif nLocalPosX <= MiddleX and nLocalPosY > MiddexY then --左下
        nBoxPosX = nLocalPosX + pSize.X
        nBoxPosY = nLocalPosY - nBoxSizeY
    elseif nLocalPosX > MiddleX and nLocalPosY > MiddexY then --右下
        nBoxPosX = nLocalPosX - nBoxSizeX
        nBoxPosY = nLocalPosY - nBoxSizeY
    end

    local nBorderXLeft = 0
    local nBorderXRight = nbdrSizeX - nBoxSizeX
    local nBorderYTop = 0
    local nBorderYBottom = nbdrSizeY - nBoxSizeY
    if (nBoxPosX < nBorderXLeft) then
        nBoxPosX = nBorderXLeft
    elseif (nBoxPosX > nBorderXRight) then
        nBoxPosX = nBorderXRight
    end
    if (nBoxPosY < nBorderYTop) then
        nBoxPosY = nBorderYTop
    elseif (nBoxPosY > nBorderYBottom) then
        nBoxPosY = nBorderYBottom
    end
    pBoxWidget.Slot:SetPosition(Vector2D{X = nBoxPosX, Y = nBoxPosY})
end

local function AbsulotLayout(pBoxWidget, pUIBasePanel, pScreenPos, pSize) --十字布局法
    -- body
    local pGeometry = pUIBasePanel:GetCachedGeometry()
    local pLocalPos = SlateBlueprintLibrary.AbsoluteToLocal(pGeometry, pScreenPos)
    pBoxWidget.Slot:SetPosition(pLocalPos)
end

local function SetPos(self, pUIBasePanel, pScreenPos, pSize, nLayoutType)
    if nLayoutType == CommonButtonListTypeDef.LayoutType.Cross then
        CrossLayout(self.pWidgetRef, pUIBasePanel, pScreenPos, pSize)
    elseif nLayoutType == CommonButtonListTypeDef.LayoutType.Absulot then
        AbsulotLayout(self.pWidgetRef, pUIBasePanel, pScreenPos, pSize)
    end
end

local function InitBtnList(self)
    local fnFunc = function ()
        self:CloseButtonList()
    end

    local tbArgs = self.tbArgs
    for i,v in ipairs(tbArgs.tbBtnsArg) do
        local szBtnType = v.szBtnType
        v.CloseFunc = fnFunc
        local pBtnScript, pBtnWidget = self.PrefabHelper:CreatePrefab(szBtnType)
        self.tbWidgets[i] = pBtnScript
        pBtnScript:OnSetData(v)
        self:AddBtnsToBasePanel(pBtnWidget)
    end
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetRenderOpacity(0)
    self.TimerHelper:RunNextTick(function()
        SetPos(self, tbArgs.pUIBasePanel, tbArgs.pScreenPos, tbArgs.pSize, tbArgs.nLayoutType)
        pWidgetRef:SetRenderOpacity(1)
    end)
end

function UPCommonButtonList:AddBtnsToBasePanel(pBtnWidget)
    local pSlot = self.pWidgetRef.pVerticalBox:AddChild(pBtnWidget)
    pSlot:SetPadding(PADDING)
end

function UPCommonButtonList:GetButton(nIndex)
    return self.tbWidgets[nIndex]
end

function UPCommonButtonList:OnSetData(tbArgs)
    self.tbArgs = tbArgs
    InitBtnList(self)
end

function UPCommonButtonList:OnLoad()
    self.tbArgs = {}
    self.tbWidgets = {}
end

function UPCommonButtonList:OnShow()

end

function UPCommonButtonList:CloseButtonList()
    local tbArg = self.tbArgs
    tbArg.pParent:DestoryButtonList(self.tbArgs.pTargetWidgetUID)
end

return UPCommonButtonList