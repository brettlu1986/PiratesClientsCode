-----------------------------------------------------
--File Name    : UPSailorDetailItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-19
--Description  : 水手替换时Item/水手装备页面选中时右侧详细Item
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSailorDetailItem = luaclass("UPSailorDetailItem", PrefabBase)

local ItemSystem = require("ItemSystem")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local PropertyComboSystem = require("PropertyComboSystem")
local SelfVerticalListHelper = require("SelfVerticalListHelper")

UPSailorDetailItem.nSailorId = nil

function UPSailorDetailItem:OnLoad()
    self.tbListHelper = SelfVerticalListHelper()
    self.tbListHelper:Init(self, self.pWidgetRef.listProperty)
end

function UPSailorDetailItem:OnUnload()
    self.tbListHelper:Uninit()
    self.tbListHelper = nil
end

function UPSailorDetailItem:SetSailorId(nSailorId)
    self.nSailorId = nSailorId
    local tbTemplate = ItemSystem:GetItemTemplate(nSailorId)
    if not tbTemplate then
        logerror("UPSailorDetailItem SetSailorId failed, tbTemplate is nil, nSailorId = ", nSailorId, debug.traceback())
        return
    end
    self.pWidgetRef.txtName:SetText(tbTemplate.l10nName)
    local tbResTemplate = ItemSystem:GetItemResTemplate(nSailorId)
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgIcon, tbResTemplate.szIconPath:load())
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgGrade, UIResourceDef.SAILOR_GRADE_ICONS[tbTemplate.nGrade + 1]:load())

    local tbDisplayInfoList = PropertyComboSystem:GetPropertyComboDisplayInfoList(tbTemplate.nPropertyComboId)
    self.tbListHelper:SetData(tbDisplayInfoList)
end

function UPSailorDetailItem:GetSailorId()
    return self.nSailorId
end

function UPSailorDetailItem:PlayEnterAnim()
    self.pWidgetRef:PlayAnimation(self.pWidgetRef.animEnter, 0, 1, EUMGSequencePlayMode.Forward, 1)
end

return UPSailorDetailItem