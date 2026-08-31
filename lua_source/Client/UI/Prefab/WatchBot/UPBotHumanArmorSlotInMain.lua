
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")

local UPBotHumanArmorSlotInMain = luaclass("UPBotHumanArmorSlotInMain", PrefabBase)
local BattleItemResDataTable = require("BattleItemResDataTable")
local UISetUtils = require("UISetUtils")
local UIFFABackpackHelper = require("UIFFABackpackHelper")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")
local BattleItemDataTable = require("BattleItemDataTable")

UPBotHumanArmorSlotInMain.nSlotIndex = -1
-----------public------------

function UPBotHumanArmorSlotInMain:SetSlotIndex(nIdx)
    self.nSlotIndex = nIdx
end

function UPBotHumanArmorSlotInMain:ShowArmor(nTemplateId, nPercent)
    local pWidgetRef = self.pWidgetRef
    local Visible = ESlateVisibility.SelfHitTestInvisible
    local InVisible = ESlateVisibility.Hidden
    if nTemplateId == 0 then
        pWidgetRef:SetVisibility(InVisible)
    else
        local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
        pWidgetRef:SetVisibility(Visible)
        local tbResTemplate = BattleItemResDataTable:GetTemplate(tbTemplate.nResId)
        pWidgetRef.pgbDurability:SetPercent(1 - nPercent)
        local szRes = tbResTemplate.szIconPath
        if #szRes == 0 then
            logerror("config res id does not have icon path, res id : ", tbTemplate.nResId)
            return
        end
        local pRes = szRes:load()
        UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, pRes)
        UIFFABackpackHelper.SetPartLevel(pWidgetRef.imgLevel, tbTemplate.nGrade)

        local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nTemplateId)
        UISetUtils.SetImageBrushRes(pWidgetRef.imgColour, szColorGradeImg:load())
    end
end

return UPBotHumanArmorSlotInMain