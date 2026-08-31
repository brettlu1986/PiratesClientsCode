local LobbySailorHelper = {}
local ItemSystem = require("ItemSystem")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local UISailorResDataTable = require("UISailorResDataTable")

local tbAnimNames = 
{
    [0] = "anim_Gray",
    [1] = "anim_Green",
    [2] = "anim_Blue",
    [3] = "anim_Purple",
    [4] = "anim_Orange",
}

local nHighGradeStart = 3


function LobbySailorHelper.RefreshSailorItemResState(pEnableWidget, pPattern, bEnable, nSailorId)
    local tbTemplate = ItemSystem:GetItemTemplate(nSailorId)
    local tbResTemplate = ItemSystem:GetItemResTemplate(nSailorId)
    UISetUtils.SetImageBrushRes(pPattern, tbResTemplate.szIconPath:load())
    pEnableWidget:SetVisibility(ESlateVisibility.HitTestInvisible)
    pPattern:SetVisibility(ESlateVisibility.HitTestInvisible)

    local szStoneIcon = UIResourceDef.LOBBY_SAILOR_BG_STONE[tbTemplate.nSubCategory][tbTemplate.nGrade]
    UISetUtils.SetImageBrushRes(pEnableWidget, szStoneIcon:load())

    if bEnable then  
        UISetUtils.SetImageBrushTint(pEnableWidget, UIResourceDef.COLOR.WHITE.SLATE_COLOR)
        UISetUtils.SetImageBrushTint(pPattern, UIResourceDef.LOBBY_SAILOR_PATTERN_COLOR[tbTemplate.nGrade])
    else  
        UISetUtils.SetImageBrushTint(pEnableWidget, UIResourceDef.LOBBY_SAILOR_STONE_DISABLE_COLOR)
        UISetUtils.SetImageBrushTint(pPattern, UIResourceDef.LOBBY_SAILOR_PATTERN_DISABLE_COLOR[tbTemplate.nGrade])
    end
end

function LobbySailorHelper.RefreshSailorMaterialEffect(pRef, pImageFx, nSailorId, pImageHighFx)
    pImageFx:SetVisibility(ESlateVisibility.HitTestInvisible)
    
    local tbTemplate = ItemSystem:GetItemTemplate(nSailorId)

    if tbTemplate.nGrade >= nHighGradeStart then  
        pImageHighFx:SetVisibility(ESlateVisibility.HitTestInvisible)
        UISetUtils.SetImageBrushRes(pImageHighFx, UIResourceDef.LOBBY_SAILOR_HIGH_LEVEL_EFF[tbTemplate.nSubCategory][tbTemplate.nGrade]:load())
    else  
        pImageHighFx:SetVisibility(ESlateVisibility.Collapsed)
    end

    local tbMaterialEffTemplate = UISailorResDataTable:GetTemplate(tbTemplate.nResId)
    local szEffMaterialPath = tbMaterialEffTemplate.szEffectPath
    UISetUtils.SetImageBrushRes(pImageFx, szEffMaterialPath:load())
    pRef:PlayAnimation(pRef[tbAnimNames[tbTemplate.nGrade]], 0, 1, EUMGSequencePlayMode.Forward, 1)
    local tbColorDef = UIResourceDef.LOBBY_SAILOR_STONE_FX_GRADE_COLOR
    pRef:ChangeFxColor(tbColorDef[tbTemplate.nGrade].BaseColor, tbColorDef[tbTemplate.nGrade].EdgeColor)
end 


return LobbySailorHelper