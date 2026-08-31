
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPDecorationListItem = luaclass("UPDecorationListItem", ListItemBase)
local UISetUtils = require("UISetUtils")
local UILobbyCaptainHelper = require("UILobbyCaptainHelper")
local LobbyItemUiHelper = require("LobbyItemUiHelper")

UPDecorationListItem.tbData = nil

local function OnSelected(self)
    self:SelectItem()
end

function UPDecorationListItem:OnRefresh(tbData)
    local szRes = tbData.tbResTemplate.szIconPath
    local pRes = szRes:load()
    local pWidgetRef = self.pWidgetRef
    UISetUtils.SetImageBrushRes(pWidgetRef.imgItem, pRes)

    if self:IsSelected() then
        pWidgetRef.imgUp:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        pWidgetRef.imgUp:SetVisibility(ESlateVisibility.Collapsed)
    end

    local tbState = UILobbyCaptainHelper.tbCaptainItemState
    if tbData.nEquipState == tbState.EQUIP then  
        pWidgetRef.txtEquiped:SetVisibility(ESlateVisibility.HitTestInvisible)
    else  
        pWidgetRef.txtEquiped:SetVisibility(ESlateVisibility.Collapsed)
    end

    if tbData.nEquipState == tbState.UNGET then  
        LobbyItemUiHelper.SetGradeColorImage(pWidgetRef, 0)
    else  
        LobbyItemUiHelper.SetGradeColorImage(pWidgetRef, tbData.tbTemplate.nGrade)
    end

    local RemainTime = UILobbyCaptainHelper.GetRemainingTime(tbData.nInstanceId)
    if RemainTime and RemainTime > 0 then
        pWidgetRef.imgTimeAndClose:SetVisibility(ESlateVisibility.HitTestInvisible)
    else  
        pWidgetRef.imgTimeAndClose:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPDecorationListItem:OnBindEvent( EventHelper )
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnClicked, self, OnSelected)
end


return UPDecorationListItem