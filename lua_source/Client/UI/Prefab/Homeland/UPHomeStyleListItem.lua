-----------------------------------------------------
--File Name    : UPHomeStyleListItem.lua
--Author       : WuJizhou
--Create Time  : 5/15/2019, 11:40:24 AM
--Description  : UPHomeStyleListItem
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")

local UPHomeStyleListItem = luaclass("UPHomeStyleListItem", ListItemBase)

local HomelandSceneDataTable = require("HomelandSceneDataTable")
local HomelandUIHelper = require("HomelandUIHelper")
local UISetUtils = require("UISetUtils")

local SceneStyleState = HomelandUIHelper.MiscDef.SceneStyleState

UPHomeStyleListItem.tbData = nil


local function OnClicked(self)
    self:SelectItem()
end

function UPHomeStyleListItem:OnRefresh(tbData)
    local Visible = ESlateVisibility_SelfHitTestInvisible
    local Hidden = ESlateVisibility_Collapsed
    self.tbData = tbData
    local pWidgetRef = self.pWidgetRef
    local nSceneId = tbData.nSceneId
    local nState = tbData.nState
    if nState == SceneStyleState.InUse then
        pWidgetRef.bdrBlack:SetVisibility(Hidden)
        pWidgetRef.kmtxtCurrent:SetVisibility(Visible)
    elseif nState == SceneStyleState.Owned then
        pWidgetRef.bdrBlack:SetVisibility(Hidden)
        pWidgetRef.kmtxtCurrent:SetVisibility(Hidden)
    elseif nState == SceneStyleState.Unlocked then
        pWidgetRef.bdrBlack:SetVisibility(Visible)
        pWidgetRef.imgLock:SetVisibility(Hidden)
        pWidgetRef.kmtxtCurrent:SetVisibility(Hidden)
    else
        pWidgetRef.bdrBlack:SetVisibility(Visible)
        pWidgetRef.imgLock:SetVisibility(Visible)
        pWidgetRef.kmtxtCurrent:SetVisibility(Hidden)
    end
    local tbTemplate = HomelandSceneDataTable:GetSceneTemplate(nSceneId)
    local l10nName = tbTemplate.l10nName
    pWidgetRef.kmtxtName:SetText(l10nName)
    local szIconPath = tbTemplate.szIcon
    UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, szIconPath:load())

    if self:IsSelected() then
        pWidgetRef.imgSelect:SetVisibility(Visible)
    else
        pWidgetRef.imgSelect:SetVisibility(Hidden)
    end
end


----------life cycle----------
-- function UPHomeStyleListItem:OnCreate()
-- endw

-- function UPHomeStyleListItem:OnDestroy()
-- end

-- function UPHomeStyleListItem:OnLoad()
-- end

-- function UPHomeStyleListItem:OnUnload()
-- end

-- function UPHomeStyleListItem:OnEnter()
-- end

-- function UPHomeStyleListItem:OnShow()
-- end

-- function UPHomeStyleListItem:OnHide()
-- end

-- function UPHomeStyleListItem:OnExit()
-- end

function UPHomeStyleListItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSelect.OnClicked, self, OnClicked)
end

-- function UPHomeStyleListItem:OnUnbindEvent(EventHelper)
-- end

return UPHomeStyleListItem