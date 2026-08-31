-----------------------------------------------------
--File Name    : UPCreateRoleListItem.lua
--Author       : WuJizhou
--Create Time  : 4/22/2020, 4:28:20 PM
--Description  : UPCreateRoleListItem
-----------------------------------------------------
local luaclass                   = require("luaclass")
local PrefabBase                 = require("PrefabBase")
local UPCreateRoleListItem       = luaclass("UPCreateRoleListItem", PrefabBase)

local CreateRoleUIDef            = require("CreateRoleUIDef")
local UISetUtils                 = require("UISetUtils")
local ClientEventDef             = require("ClientEventDef")
local GenderTypeDefine           = require("GenderTypeDefine")
local DefaultAppearanceDataTable = require("DefaultAppearanceDataTable")
local AvatarColorDataTable       = require("AvatarColorDataTable")
local HumanAvatarDef             = require("HumanAvatarDef")

local SlotType = CreateRoleUIDef.SlotType
local PartType = HumanAvatarDef.PartType

UPCreateRoleListItem.pbParent = nil
UPCreateRoleListItem.nIdx = nil
UPCreateRoleListItem.tbData = nil




local function OnSelected(self)
    if not self:IsSelected() then
        self:SelectItem()
    end
    self.EventHelper:FireEvent(ClientEventDef.EV_DEFAULT_APPEARANCE_SELECTED, self.tbData.nId)
end

local function RefreshColor(self, nColorId)
    local tbColor = AvatarColorDataTable:GetTemplate(nColorId)
    local pColor = KMUMGLibrary.GetSlateColor(tbColor.nRed, tbColor.nGreen, tbColor.nBlue, 1)
    UISetUtils.SetButtonBrushTint(self.pWidgetRef.btnIcon, pColor)
end

function UPCreateRoleListItem:IsSelected()
    return self.pbParent:GetSelectIndex() == self.nIdx
end

function UPCreateRoleListItem:SelectItem()
    self.pbParent:SetSelectedIndex(self.nIdx)
end


function UPCreateRoleListItem:SetIndex(nIdx)
    self.nIdx = nIdx
end

function UPCreateRoleListItem:SetParentContainer(pbParent)
    self.pbParent = pbParent
end

function UPCreateRoleListItem:OnRefresh(tbData)
    self.tbData = tbData
    local nId = tbData.nId
    local nGender = tbData.nGender
    local tbTemplate = DefaultAppearanceDataTable:GetData(nId)
    if tbTemplate.nType == SlotType.HairColor then
        local nColorId = tbTemplate.tbData[PartType.HairColor]
        RefreshColor(self, nColorId)
    elseif tbTemplate.nType == SlotType.SkinColor then
        local nColorId = tbTemplate.tbData[PartType.SkinColor]
        RefreshColor(self, nColorId)
    else
        local pRes = nil
        if nGender == GenderTypeDefine.MALE then
            pRes = tbTemplate.szMaleIcon:load()
        else
            pRes = tbTemplate.szFemaleIcon:load()
        end
        UISetUtils.SetButtonBrushRes(self.pWidgetRef.btnIcon, pRes)
    end

    if self:IsSelected() then
        self.pWidgetRef.imgSelect:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.pWidgetRef.imgSelect:SetVisibility(ESlateVisibility.Collapsed)
    end

end


----------life cycle----------
-- function UPCreateRoleListItem:OnCreate()
-- end

-- function UPCreateRoleListItem:OnDestroy()
-- end

function UPCreateRoleListItem:OnLoad()
    self.bSelected = false
end

-- function UPCreateRoleListItem:OnUnload()
-- end

-- function UPCreateRoleListItem:OnEnter()
-- end

-- function UPCreateRoleListItem:OnShow()
-- end

-- function UPCreateRoleListItem:OnHide()
-- end

-- function UPCreateRoleListItem:OnExit()
-- end

function UPCreateRoleListItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnIcon.OnClicked, self, OnSelected)
end

-- function UPCreateRoleListItem:OnUnbindEvent(EventHelper)
-- end

return UPCreateRoleListItem