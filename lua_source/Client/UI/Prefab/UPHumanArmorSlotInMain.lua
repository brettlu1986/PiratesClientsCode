-----------------------------------------------------
--File Name    : UPHumanArmorSlotInMain.lua
--Author       : WuJizhou
--Create Time  : 9/7/2018, 4:42:22 PM
--Description  : UPHumanArmorSlotInMain
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")

local UPHumanArmorSlotInMain = luaclass("UPHumanArmorSlotInMain", PrefabBase)
local BattleItemResDataTable = require("BattleItemResDataTable")
local UISetUtils = require("UISetUtils")
local UIFFABackpackHelper = require("UIFFABackpackHelper")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")

UPHumanArmorSlotInMain.nSlotIndex = -1
UPHumanArmorSlotInMain.nArmorInstanceId = nil
-----------public------------

function UPHumanArmorSlotInMain:SetSlotIndex(nIdx)
    self.nSlotIndex = nIdx
end

function UPHumanArmorSlotInMain:ShowArmor(tbArmor)
    local pWidgetRef = self.pWidgetRef
    local Visible = ESlateVisibility.SelfHitTestInvisible
    local InVisible = ESlateVisibility.Hidden
    if tbArmor == nil then
        pWidgetRef:SetVisibility(InVisible)
    else
        self.nArmorInstanceId = tbArmor:GetInstanceId()
        pWidgetRef:SetVisibility(Visible)
        local tbTemplate = tbArmor:GetTemplate()
        local tbResTemplate = BattleItemResDataTable:GetTemplate(tbTemplate.nResId)
        local nTotalDurability = tbTemplate.nDurability
        local nCurrentDurability = tbArmor:GetDurability()
        local nPercent = nCurrentDurability / nTotalDurability
        pWidgetRef.pgbDurability:SetPercent(1 - nPercent)
        local szRes = tbResTemplate.szIconPath
        if #szRes == 0 then
            logerror("config res id does not have icon path, res id : ", tbTemplate.nResId)
            return
        end
        local pRes = szRes:load()
        UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, pRes)
        UIFFABackpackHelper.SetPartLevel(pWidgetRef.imgLevel, tbTemplate.nGrade)

        local nItemTemplateId = tbArmor:GetTemplateId()
        local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
        UISetUtils.SetImageBrushRes(pWidgetRef.imgColour, szColorGradeImg:load())
    end
end

----------life cycle----------

-- function UPHumanArmorSlotInMain:OnDestroy()
-- end

-- function UPHumanArmorSlotInMain:OnUnload()
-- end

-- function UPHumanArmorSlotInMain:OnEnter()
-- end

-- function UPHumanArmorSlotInMain:OnShow()
-- end

-- function UPHumanArmorSlotInMain:OnHide()
-- end

-- function UPHumanArmorSlotInMain:OnExit()
-- end

-- function UPHumanArmorSlotInMain:OnBindEvent( EventHelper )

-- end


return UPHumanArmorSlotInMain