-----------------------------------------------------
--File Name    : UPEquipItemTip.lua
--Author       : WuJizhou
--Create Time  : 2018-2-1 17:40:15
--Description  : UPEquipItemTip
-----------------------------------------------------

local luaclass = require("luaclass")
local UPTipBase = require("UPTipBase")
local UPEquipItemTip = luaclass("UPEquipItemTip", UPTipBase)

UPEquipItemTip.pbTipContentList = nil




----------------------------public function----------------------------

function UPEquipItemTip:SetData(tbTipData)
    UPEquipItemTip.super.SetData(self, tbTipData)
    --{tbTemplate, nStackCount, nItemId, bFirstAward}
    local tbDatas = tbTipData.tbData
    local bHasNil = false
    for nIdx = 1, 2 do
        local tbData = tbDatas[nIdx]
        if tbData == nil then
            bHasNil = true
            self.pbTipContentList[nIdx].pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
        else
            self.pbTipContentList[nIdx].pWidgetRef:SetVisibility(ESlateVisibility.Visible)
            self.pbTipContentList[nIdx]:SetData(tbData)
        end
    end
    if bHasNil then
        self.pWidgetRef.hboxAddition.Slot:SetVerticalAlignment(EVerticalAlignment.VAlign_Bottom)
    else
        self.pWidgetRef.hboxAddition.Slot:SetVerticalAlignment(EVerticalAlignment.VAlign_Top)
    end
end

function UPEquipItemTip:OnLoad()
    UPEquipItemTip.super.OnLoad(self)
    self.pbTipContentList = {}
    for nIdx = 1, 2 do
        self.pbTipContentList[nIdx] = self.PrefabHelper:BindPrefab(self.pWidgetRef["pbTipContent_"..nIdx])
    end

end

return UPEquipItemTip