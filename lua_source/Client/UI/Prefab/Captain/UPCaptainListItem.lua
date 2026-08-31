-----------------------------------------------------
--File Name    : UPCaptainListItem.lua
--Author       : WuJizhou
--Create Time  : 2/26/2019, 9:56:53 PM
--Description  : UPCaptainListItem
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPCaptainListItem = luaclass("UPCaptainListItem", ListItemBase)

local ItemSystem        = require("ItemSystem")
local UISetUtils        = require("UISetUtils")
local ItemDataTable     = require("ItemDataTable")
local LobbyItemUiHelper = require("LobbyItemUiHelper")

UPCaptainListItem.tbData = nil

local SelfHitTestInvisible = ESlateVisibility.SelfHitTestInvisible
local Collapsed = ESlateVisibility.Collapsed

local function RefreshPutOnState(self)
    if self.tbData.bEquiped then
        self.pWidgetRef.bdrEquiped:SetVisibility(SelfHitTestInvisible)
    else
        self.pWidgetRef.bdrEquiped:SetVisibility(Collapsed)
    end
end

local function RefreshSelectState(self)
    if self.nIndex == self.ListHelper.nSelectedIdx then
        self.pWidgetRef.imgSelected:SetVisibility(SelfHitTestInvisible)
    else
        self.pWidgetRef.imgSelected:SetVisibility(Collapsed)
    end
end

local function RefreshOwnedItem(self, nItemInstanceId)
    local tbItem = ItemSystem:GetItem(nItemInstanceId)
    local pWidgetRef = self.pWidgetRef
    local tbTemplate = tbItem:GetTemplate()
    local nTemplateId = tbTemplate.nId
    local tbResTemplate = ItemDataTable:GetResTemplate(nTemplateId)
    local szRes = tbResTemplate.szIconPath
    local pRes = szRes:load()
    UISetUtils.SetImageBrushRes(pWidgetRef.imgItem, pRes)
    LobbyItemUiHelper.SetGradeColorImage(pWidgetRef, tbTemplate.nGrade)
    if tbItem:HasExpiration() then
        pWidgetRef.imgTime:SetVisibility(SelfHitTestInvisible)
        if tbItem:GetRemainCanUseSeconds() > 0 then
            pWidgetRef.imgBlack:SetVisibility(Collapsed)
        else
            pWidgetRef.imgBlack:SetVisibility(SelfHitTestInvisible)
        end
    else
        pWidgetRef.imgBlack:SetVisibility(Collapsed)
        pWidgetRef.imgTime:SetVisibility(Collapsed)
    end

    if tbTemplate.bCostume then
        pWidgetRef.bdrtxt:SetVisibility(SelfHitTestInvisible)
    else
        pWidgetRef.bdrtxt:SetVisibility(Collapsed)
    end

    local nCount = tbItem:GetStackCount()
    pWidgetRef.txtNumber:SetVisibility(SelfHitTestInvisible)
    pWidgetRef.txtNumber:SetText(nCount)

    pWidgetRef.imgLock:SetVisibility(Collapsed)
    pWidgetRef.bdrPreview:SetVisibility(Collapsed)
    local bVisible = self.tbData.fnCheckHint(nItemInstanceId)
    pWidgetRef.btnSelected:HideTipIcon(not bVisible)
end

local function RefreshNotOwnedItem(self, nTemplateId)
    local pWidgetRef = self.pWidgetRef

    local tbTemplate = ItemSystem:GetItemTemplate(nTemplateId)
    local tbResTemplate = ItemDataTable:GetResTemplate(nTemplateId)
    local szRes = tbResTemplate.szIconPath
    local pRes = szRes:load()
    UISetUtils.SetImageBrushRes(pWidgetRef.imgItem, pRes)
    LobbyItemUiHelper.SetGradeColorImage(pWidgetRef, tbTemplate.nGrade)
    pWidgetRef.imgLock:SetVisibility(SelfHitTestInvisible)
    if tbTemplate.bCostume then
        pWidgetRef.bdrtxt:SetVisibility(SelfHitTestInvisible)
    else
        pWidgetRef.bdrtxt:SetVisibility(Collapsed)
    end
    pWidgetRef.txtNumber:SetVisibility(Collapsed)
    pWidgetRef.imgTime:SetVisibility(Collapsed)

    if self.tbData.bPreview then
        pWidgetRef.bdrPreview:SetVisibility(SelfHitTestInvisible)
    else
        pWidgetRef.bdrPreview:SetVisibility(Collapsed)
    end
    pWidgetRef.imgBlack:SetVisibility(SelfHitTestInvisible)
    -- pWidgetRef.imgItem:SetRenderOpacity(OPACITY_NOT_OWNED)
    pWidgetRef.btnSelected:HideTipIcon(true)
end

local function OnSelected(self)
    self:SelectItem()
    local tbData = self.tbData
    if tbData.fnSelected then
        tbData.fnSelected(tbData)
    end
end

-- tbData结构如下：
-- {bOwned: true,  nInstanceId: xxx, fnSelected: , bPreview :} 或 {bOwned: false, nTemplateId: xxx,  fnSelected: , bPreview :}
function UPCaptainListItem:OnRefresh(tbData)
    if not tbData then
        return
    end
    self.tbData = tbData
    if tbData.bOwned then
        RefreshOwnedItem(self, tbData.nInstanceId)
    else
        RefreshNotOwnedItem(self, tbData.nTemplateId)
    end
    RefreshPutOnState(self)
    RefreshSelectState(self)
end
----------life cycle----------

function UPCaptainListItem:OnBindEvent( EventHelper )
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSelected.OnClicked, self, OnSelected)
end


return UPCaptainListItem