local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPBotShipArmorSlotInMain = luaclass("UPBotShipArmorSlotInMain", PrefabBase)

local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemResDataTable = require("BattleItemResDataTable")
local UISetUtils = require("UISetUtils")
local UIFFABackpackHelper = require("UIFFABackpackHelper")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")

UPBotShipArmorSlotInMain.nSlot = -1
UPBotShipArmorSlotInMain.nShipPartInstanceId = -1

function UPBotShipArmorSlotInMain:Init(nSlot)
    self.nSlot = nSlot
    local l10nName = BattleItemDataTable:GetSubCategoryName(BattleItemCategoryDef.SHIP_PART, nSlot)
    self.pWidgetRef.txtName:SetText(l10nName)
end


function UPBotShipArmorSlotInMain:ShowArmor(nTemplateId, nPercent)
    local pWidgetRef = self.pWidgetRef
    local Visible = ESlateVisibility.SelfHitTestInvisible
    local InVisible = ESlateVisibility.Hidden
    if nTemplateId == 0 then
        pWidgetRef:SetVisibility(InVisible)
    else
        local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
        pWidgetRef:SetVisibility(Visible)
        pWidgetRef.pgbDurability:SetPercent(1 - nPercent)

        local tbResTemplate = BattleItemResDataTable:GetTemplate(tbTemplate.nResId)
        if tbResTemplate then
            
            local szItemIconPath = tbResTemplate.szIconPath
            local pRes = szItemIconPath:load()
            if pRes then
                pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
                UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, pRes, true)

                local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nTemplateId)
                UISetUtils.SetImageBrushRes(pWidgetRef.imgColour, szColorGradeImg:load())
            end
        end
        
        pWidgetRef.imgLevel:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        UIFFABackpackHelper.SetPartLevel(pWidgetRef.imgLevel, tbTemplate.nGrade)
    end
end


return UPBotShipArmorSlotInMain