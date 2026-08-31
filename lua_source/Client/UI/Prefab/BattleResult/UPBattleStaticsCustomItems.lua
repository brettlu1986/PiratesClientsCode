-----------------------------------------------------
--File Name    : UPBattleStaticsCustomItems.lua
--Author       : Ran Jie
--Create Time  : 2019-01-22
-----------------------------------------------------
local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPBattleStaticsCustomItems = luaclass("UPBattleStaticsCustomItems", ListItemBase)

local L10N = require("L10N")
local TeamSystem = require("TeamSystem")


function UPBattleStaticsCustomItems:OnRefresh(tbData)
    --logdebug("UPBattleStaticsCustomItems:OnRefresh,tbData=",tbData)
    local pWidgetRef = self.pWidgetRef
    if not tbData then
        pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
        return
    end
    pWidgetRef:SetVisibility(ESlateVisibility_HitTestInvisible)
    local tbTemplate = tbData.tbTemplate
    pWidgetRef.txtName:SetText(tbTemplate.l10DisplayName)
    
    for k, v in ipairs(tbData.tbValueList) do
        
        local nValue = v * tbTemplate.nMultiplyParam / tbTemplate.nDivideParam
        local szValue = nValue
        --logdebug("tbTemplate.nDecimalPointRemain,szValue=",tbTemplate.nDecimalPointRemain,szValue,v,tbTemplate.nMultiplyParam,tbTemplate.nDivideParam)
        if tbTemplate.nDecimalPointRemain > 0 then
            szValue = string.format("%."..tbTemplate.nDecimalPointRemain.."f", nValue)
        else
            szValue = math.tointeger(nValue)
        end
        local DisplayValueText = szValue
        if tbTemplate.l10DisplayValueFormat and tbTemplate.l10DisplayValueFormat.szSourceText ~= "" then
            DisplayValueText = L10N:Format(tbTemplate.l10DisplayValueFormat, szValue)
        end
        --logdebug("tbData.tbValueList,v=",k,v,szValue,DisplayValueText,L10N.NullString,tbTemplate.l10DisplayValueFormat)
        local pValueWidget = pWidgetRef["txtValue"..k]
        if pValueWidget then
            pValueWidget:SetText(DisplayValueText)
        end
    end
    local nTeamMemberCountLimit = TeamSystem:GetTeamMemberCountLimit()
    for i = #tbData.tbValueList + 1, nTeamMemberCountLimit do
        local pValueWidget = pWidgetRef["txtValue"..i]
        if pValueWidget then
            pValueWidget:SetVisibility(ESlateVisibility_Hidden)
        end
    end
end


return UPBattleStaticsCustomItems