-----------------------------------------------------
--File Name    : UPTipBase.lua
--Author       : Edward J
--Create Time  : 2019-03-12
--Description  : UPTipBase
-----------------------------------------------------
local luaclass      = require ("luaclass")
local PrefabBase    = require("PrefabBase")
local UPTipBase     = luaclass("UPTipBase", PrefabBase)

UPTipBase.tbTipData = nil

--public interface
function UPTipBase:OnSetData(tbTipData)
    self.pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if (tbTipData == nil) then
        log('[UI] UPTipBase:SetData failed, tbTipData is nil')
        return
    end
    self.tbTipData = tbTipData
end

function UPTipBase:OnCloseTip()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
end

return UPTipBase
