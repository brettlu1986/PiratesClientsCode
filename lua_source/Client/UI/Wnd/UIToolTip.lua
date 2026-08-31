-----------------------------------------------------
--File Name    : UIToolTip.lua
--Author       : Edward J
--Create Time  : 2019-03-12
--Description  : UIToolTip
-----------------------------------------------------
local luaclass        = require("luaclass")
local WndBase         = require("WndBase")
local UIToolTip       = luaclass("UIToolTip", WndBase)

--local UIDef           = require("UIDef")
local UIManager       = require("UIManager")
local DelayTimer      = require("DelayTimer")
local EventManager    = require("EventManager")
local PrefabConfig    = require("PrefabDataTable")
local ClientEventDef  = require("ClientEventDef")
local UIToolTipHelper = require("UIToolTipHelper")

UIToolTip.tbTipData        = nil
UIToolTip.ScreenPos        = nil
UIToolTip.tbPbToolTip      = nil
UIToolTip.tbPbWidgetCache  = nil
UIToolTip.DelayTimerHandle = nil
UIToolTip.bAutoClose       = nil

local PADDING_LEFT   = 4
local PADDING_RIGHT  = 4
local PADDING_TOP    = 2
local PADDING_BOTTOM = 2

local TEMP_COLOR = LinearColor{R = 1, G = 1, B = 1, A = 1}

local function AddUPTipToParent(pbWidget, pParentPanel)
    local pSlot     = pParentPanel:AddChild(pbWidget)
    local pPadding  = pSlot.Padding
    pPadding.Left   = PADDING_LEFT
    pPadding.Top    = PADDING_TOP
    pPadding.Right  = PADDING_RIGHT
    pPadding.Bottom = PADDING_BOTTOM
    pSlot:SetPadding(pPadding)
end

local function CreateOrBindUpTipInternal(self, szPrefabName, szUIPath)
    local PrefabHelper = self.PrefabHelper
    local tbPbScriptCache = self.tbPbToolTip
    local tbPbWidgetCache = self.tbPbWidgetCache
    local pScript = tbPbScriptCache[szPrefabName]
    if pScript ~= nil then
        return pScript, pScript.pWidgetRef
    end

    -- local pbWidget = tbPbWidgetCache[szUIPath]
    -- if pbWidget ~= nil then
    --     pScript = PrefabHelper:BindPrefab(pbWidget, szPrefabName)
    --     tbPbScriptCache[szPrefabName] = pScript
    --     return pScript, pScript.pWidgetRef
    -- end
    local pbWidget = nil
    pScript, pbWidget = PrefabHelper:CreatePrefab(szPrefabName)
    tbPbScriptCache[szPrefabName] = pScript
    tbPbWidgetCache[szUIPath] = pbWidget
    AddUPTipToParent(pbWidget, self.pWidgetRef.ovlBg)
    return pScript, pbWidget
end

local function CreateOrBindUPTip(self, szPrefabName)
    local tbPrefabTemplate = PrefabConfig:GetTemplate(szPrefabName)
    local szUIPath = tbPrefabTemplate.szUIPath
    return CreateOrBindUpTipInternal(self, szPrefabName, szUIPath)
end

-- local function RemoveUPTipFromParent(pbWidget, pParentPanel)
--     pParentPanel:RemoveChild(pbWidget)
-- end

-- local function RemoveAllUPTipFromParent(pParentPanel, tbPbWidgetCache)
--     if tbPbWidgetCache == nil then
--         return
--     end
--     for _, v in pairs(tbPbWidgetCache) do
--         RemoveUPTipFromParent(v, pParentPanel)
--     end
-- end

--public
function UIToolTip:OnBgMouseButtonDown(pGeometry, pMouseEvent)
     local tbTipDataTemp = self.tbTipData
     if (not tbTipDataTemp.bIsShieldBgClick) then
         self:CloseSelf()
     end
    return WidgetBlueprintLibrary.Handled()
end

function UIToolTip:OnAnimCloseFinished()
    UIManager:CloseWnd(self)
end

function UIToolTip:RunNextTick(pbToolTip)
    self.DelayTimerHandle = nil
    local ScreenPos = self.ScreenPos
    local pWidget = self.pWidgetRef
    local Size = self.size
    local TipPos = self:GetValidTipPos(ScreenPos, pWidget, Size)
    pWidget.ovlBg.Slot:SetPosition(Vector2D{X = TipPos.X, Y = TipPos.Y})
    self:SetTipAlpha(1)
    EventManager:OnFireEvent(ClientEventDef.EV_GUIDE_TOOL_TIP_SHOW, true)
    if self.bAutoClose then
        self.DelayTimerHandle = DelayTimer:DelayRun(function() 
            self.DelayTimerHandle = nil
            self:CloseSelf() end, 0.1)
    end
end

function UIToolTip:GetValidTipPos(ScreenPos, pWidget, Size)
    -- body
    if Size == nil then
        Size = {X = 0,Y = 0}
    end
    local nSizeX = Size.X
    local pGeometry = pWidget.btnToolTip:GetCachedGeometry()
    local LocalPos = SlateBlueprintLibrary.AbsoluteToLocal(pGeometry, ScreenPos)
    local nLocalPosX = LocalPos.X
    local nLocalPosY = LocalPos.Y
    local TipSize = pWidget.ovlBg:GetDesiredSize()
    local nTipSizeX = TipSize.X
    local nTipSizeY = TipSize.Y
    local bdrSize = SlateBlueprintLibrary.GetLocalSize(pGeometry)
    local nbdrSizeX = bdrSize.X
    local nbdrSizeY = bdrSize.Y
    local nTipPosX = nLocalPosX
    local nTipPosY = nLocalPosY
    local MiddleX = nbdrSizeX * 0.5
    local MiddexY = nbdrSizeY * 0.05
    if nLocalPosX <= MiddleX and nLocalPosY <= MiddexY then
        nTipPosX = nLocalPosX + nSizeX
        nTipPosY = nLocalPosY
    elseif nLocalPosX > MiddleX and nLocalPosY <= MiddexY then
        nTipPosX = nLocalPosX - nTipSizeX
        nTipPosY = nLocalPosY
    elseif nLocalPosX <= MiddleX and nLocalPosY > MiddexY then
        nTipPosX = nLocalPosX + nSizeX
        nTipPosY = nLocalPosY - nTipSizeY
    elseif nLocalPosX > MiddleX and nLocalPosY > MiddexY then
        nTipPosX = nLocalPosX - nTipSizeX
        nTipPosY = nLocalPosY - nTipSizeY
    end

    local BorderXLeft = 0
    local BorderXRight = nbdrSizeX - nTipSizeX
    local BorderYTop = 0
    local BorderYBottom = nbdrSizeY - nTipSizeY
    if (nTipPosX < BorderXLeft) then
        nTipPosX = BorderXLeft
    elseif (nTipPosX > BorderXRight) then
        nTipPosX = BorderXRight
    end
    if (nTipPosY < BorderYTop) then
        nTipPosY = BorderYTop
    elseif (nTipPosY > BorderYBottom) then
        nTipPosY = BorderYBottom
    end
    return Vector2D{X = nTipPosX, Y = nTipPosY}
end

function UIToolTip:SetTipAlpha(nAlpha)
    local pWidget = self.pWidgetRef
    TEMP_COLOR.A = nAlpha
    pWidget:SetColorAndOpacity(TEMP_COLOR)
end

function UIToolTip:ShowTip(szTipType, tbTipData, ScreenPos, Size)
    local pParentPanel = self.pWidgetRef.ovlBg
    local _, pbTip = CreateOrBindUPTip(self, szTipType)
    AddUPTipToParent(pbTip, pParentPanel)

    if szTipType == UIToolTipHelper.TipType.ITEM_TIP or szTipType == UIToolTipHelper.TipType.TEXT_TIP then
        self.pWidgetRef.cvsTip:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        self.pWidgetRef.cvsTip:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
    local pbToolTip = self.tbPbToolTip[szTipType]
    log("[UI] UIToolTip:ShowTip,szTipType=" .. szTipType)
    self.ScreenPos = ScreenPos
    self.tbTipData = tbTipData
    self.size = Size
    if (pbToolTip ~= nil) then
        pbToolTip:OnSetData(tbTipData)
        self.DelayTimerHandle = DelayTimer:DelayRun(function() self:RunNextTick(pbToolTip) end, 0.1)
    else
        self:CloseSelf()
    end
end

-- function UIToolTip:CloseTip()
--     self:SetTipAlpha(0)
--     for k,v in pairs(self.tbPbToolTip) do
--         logdebug("k=",k)
--         v:OnCloseTip()
--     end
--     EventManager:OnFireEvent(ClientEventDef.EV_TOOL_TIP_HIDE)
--     UIManager:CloseWnd(UIDef.UI_TOOL_TIP)
-- end

--override
function UIToolTip:OnLoad()
    self.tbPbToolTip = {}
    self.tbPbWidgetCache = {}
end

function UIToolTip:OnShow()
    self.bAutoClose = false
    local tbArgs = self.tbOpenArgs
    --local pParentPanel = self.pWidgetRef.ovlBg
    local szTipType = tbArgs.szTipType
    -- local _, pbTip = CreateOrBindUPTip(self, szTipType)
    -- AddUPTipToParent(pbTip, pParentPanel)
    self:ShowTip(szTipType, tbArgs.tbTipData, tbArgs.ScreenPos, tbArgs.size)
end

function UIToolTip:OnHide()
    --local pParentPanel = self.pWidgetRef.ovlBg
    self:SetTipAlpha(0)
    for k,v in pairs(self.tbPbToolTip) do
        v:OnCloseTip()
    end
    --RemoveAllUPTipFromParent(pParentPanel, self.tbPbWidgetCache)
    local pDelayTimerHandle = self.DelayTimerHandle
    if (pDelayTimerHandle ~= nil) then
        DelayTimer:ClearTimer(pDelayTimerHandle)
        pDelayTimerHandle = nil
    end
    EventManager:OnFireEvent(ClientEventDef.EV_TOOL_TIP_HIDE)
end

function UIToolTip:OnBindEvent(Helper)
    Helper:RegisterCppDelegate(self.pWidgetRef.btnToolTip.OnPressed, self, self.OnBgMouseButtonDown)
    Helper:RegisterEvent(ClientEventDef.EV_SHOW_TOOL_TIP, self, self.ShowTip)
end

return UIToolTip
