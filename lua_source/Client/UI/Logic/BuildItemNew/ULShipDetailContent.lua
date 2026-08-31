-----------------------------------------------------
--File Name    : ULShipDetailContent.lua
--Author       : zhiyuan
--Create Time  : 2019-09-17
--Description  : 船的详情信息的UI逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULShipDetailContent = luaclass("ULShipDetailContent", UILogicBase)

local SelfVerticalListHelper = require("SelfVerticalListHelper")
local ShipDataDisplayHelper = require("ShipDataDisplayHelper")

ULShipDetailContent.ListHelper = nil
ULShipDetailContent.tbPropertyCategoryExpanded = nil
ULShipDetailContent.tbRawPropertiesData = nil

function ULShipDetailContent:SetShipTemplateId(nItemTemplateId)
    local tbDataDisplayHelper = ShipDataDisplayHelper.New(nItemTemplateId)
    self.tbRawPropertiesData = tbDataDisplayHelper:GetDisplayDataGroup()
end

function ULShipDetailContent:CollapseAllCategory()
    for k, _ in pairs(self.tbPropertyCategoryExpanded) do
        self.tbPropertyCategoryExpanded[k] = false
    end
end

function ULShipDetailContent:UpdateShipProperties()
    local tbDatas = {}
    for i, tbCategoryData in ipairs(self.tbRawPropertiesData) do
        tbCategoryData.bExpanded = self.tbPropertyCategoryExpanded[i]
        table.insert(tbDatas, tbCategoryData)
        if tbCategoryData.bExpanded then
            for _, tbPropertyData in ipairs(tbCategoryData.tbProperties) do
                table.insert(tbDatas, tbPropertyData)
            end
        end
    end
    self.ListHelper:SetData(tbDatas)
end

function ULShipDetailContent:OnLoad()
end

function ULShipDetailContent:InitListHelper(plistShipContent)
    -- 初始化舰船属性列表
    self.tbPropertyCategoryExpanded = {}
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, plistShipContent)
    self.ListHelper.tbExtraDatas.fnToogleCategoryExpanded = function(nCategoryIndex)
        if self.tbPropertyCategoryExpanded[nCategoryIndex] then
            self.tbPropertyCategoryExpanded[nCategoryIndex] =  false
        else
            self.tbPropertyCategoryExpanded[nCategoryIndex] =  true
        end
        self:UpdateShipProperties()
    end
end

function ULShipDetailContent:OnUnload()
    self.ListHelper:Uninit()
    self.ListHelper = nil
end

function ULShipDetailContent:OnBindEvent(EventHelper)
end

return ULShipDetailContent