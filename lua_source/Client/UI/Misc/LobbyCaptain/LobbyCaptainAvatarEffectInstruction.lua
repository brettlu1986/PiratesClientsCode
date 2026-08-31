-----------------------------------------------------
--File Name    : LobbyCaptainAvatarEffectInstruction.lua
--Description  :
-----------------------------------------------------

local luaclass = require("luaclass")
local LobbyCaptainAvatarEffectInstruction = luaclass("LobbyCaptainAvatarEffectInstruction")

local ItemChangedEffectDataTable = require("ItemChangedEffectDataTable")
local UISetUtils = require("UISetUtils")

local MAX_COUNT = 6

function LobbyCaptainAvatarEffectInstruction:Show(tbEffectIds)
    local nCount = #tbEffectIds
    if nCount > 0 then
        local pWidgetRef = self.tbOwner.pWidgetRef
        for idx = 1, MAX_COUNT do
            if idx > nCount then
                pWidgetRef["bdrChangedEffect"..idx]:SetVisibility(ESlateVisibility_Collapsed)
            else
                local nId = tbEffectIds[idx]
                local tbEffectTemplate = ItemChangedEffectDataTable:GetTemplate(nId)
                local l10nName = tbEffectTemplate.l10nName
                local tbBGColor = tbEffectTemplate.tbBackground
                local pBGColor = KMUMGLibrary.GetSlateColor(tbBGColor[1], tbBGColor[2], tbBGColor[3], tbBGColor[4])
                local tbForeColor = tbEffectTemplate.tbForground
                local pForeColor = KMUMGLibrary.GetSlateColor(tbForeColor[1], tbForeColor[2], tbForeColor[3], tbForeColor[4])

                pWidgetRef["txtChangedEffect"..idx]:SetColorAndOpacity(pForeColor)
                pWidgetRef["txtChangedEffect"..idx]:SetText(l10nName)
                UISetUtils.SetBorderBrushTint(pWidgetRef["bdrChangedEffect"..idx], pBGColor)
                pWidgetRef["bdrChangedEffect"..idx]:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
            end
        end
        pWidgetRef["bdrChangedEffects"]:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    else
        self:Hide()
    end
end

function LobbyCaptainAvatarEffectInstruction:Hide()
    self.tbOwner.pWidgetRef["bdrChangedEffects"]:SetVisibility(ESlateVisibility_Collapsed)
end


function LobbyCaptainAvatarEffectInstruction:Init(tbOwner)
    self.tbOwner = tbOwner
    self:Hide()
end

function LobbyCaptainAvatarEffectInstruction:Uninit()
    self.tbOwner = nil
end


return LobbyCaptainAvatarEffectInstruction