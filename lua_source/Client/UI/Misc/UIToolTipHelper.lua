
-----------------------------------------------------
--File Name    : UIToolTipHelper.lua
--Author       : Edward J
--Create Time  : 2019-03-12
--Description  : UIToolTipHelper
-----------------------------------------------------
local UIToolTipHelper = {}

-- import require
local UIDef     = require("UIDef")
local UIManager = require("UIManager")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")

-- member variable
UIToolTipHelper.TipType =
{
    ITEM_TIP          = UIDef.UP_LOBBY_ITEM_TIPS,
    TEXT_TIP          = UIDef.UP_TEXT_TIPS,
    SKILL_TIP         = UIDef.UP_NORMAL_SKILL_TIP,
    EQUIP_ITEM_TIP    = UIDef.UP_EQUIP_ITEM_TIP,
    SHIP_MOD_PART_TIP = UIDef.UP_SHIP_MOD_PART_TIP,
    HUB_BUFF_TIP      = UIDef.UP_HUBBUFF_TIP,
    CUSTOM_TIP        = UIDef.UP_CUSTOM_TIP,
    SEASON_TIP        = UIDef.UP_SEASON_TIPS
}

-- public function
function UIToolTipHelper:ShowTip(szTipType, tbTipData, ScreenPos, Size)
    UIManager:OpenWnd(UIDef.UI_TOOL_TIP, {szTipType = szTipType, tbTipData = tbTipData, ScreenPos = ScreenPos, size = Size})
end

function UIToolTipHelper:ShowTipInAutoLayout(szTipType, tbTipData, pTargetWidgetRef)
    if (pTargetWidgetRef == nil) then
        logerror('[UIToolTipHelper] ShowTipAutoLayout failed, ParentWidgetRef == nil.')
        return nil
    end
    local pGeometry = pTargetWidgetRef:GetCachedGeometry()
    local Size = SlateBlueprintLibrary.GetLocalSize(pGeometry)
    local ScreenPos = SlateBlueprintLibrary.LocalToAbsolute(pGeometry, KismetMathLibrary.MakeVector2D(0, 0))
    UIManager:OpenWnd(UIDef.UI_TOOL_TIP,{szTipType = szTipType,tbTipData = tbTipData,ScreenPos = ScreenPos, size = Size})
end

function UIToolTipHelper:ShowCustomTip(szPrefabName, tbTipData, ScreenPos, Size)
    -- body
    if UIManager:IsWndVisible(UIDef.UI_TOOL_TIP) then
        EventManager:OnFireEvent(ClientEventDef.EV_SHOW_TOOL_TIP, szPrefabName, tbTipData, ScreenPos, Size)
    else
        UIManager:OpenWnd(UIDef.UI_TOOL_TIP, {szTipType = szPrefabName,tbTipData = tbTipData,ScreenPos = ScreenPos, size = Size})
    end
end

function UIToolTipHelper:ShowCustomTipInAutoLayout(szPrefabName, tbTipData, pTargetWidgetRef)
    -- body
    if (pTargetWidgetRef == nil) then
        logerror('[UIToolTipHelper] ShowTipAutoLayout failed, ParentWidgetRef == nil.')
        return nil
    end
    local pGeometry = pTargetWidgetRef:GetCachedGeometry()
    local Size = SlateBlueprintLibrary.GetLocalSize(pGeometry)
    local ScreenPos = SlateBlueprintLibrary.LocalToAbsolute(pGeometry, KismetMathLibrary.MakeVector2D(0, -Size.Y))
    if UIManager:IsWndVisible(UIDef.UI_TOOL_TIP) then
        EventManager:OnFireEvent(ClientEventDef.EV_SHOW_TOOL_TIP, szPrefabName, tbTipData, ScreenPos, Size)
    else
        UIManager:OpenWnd(UIDef.UI_TOOL_TIP,{szTipType = szPrefabName, tbTipData = tbTipData, ScreenPos = ScreenPos, size = Size})
    end
    
end

function UIToolTipHelper:HideTip(bForce)
    local tbWnd = UIManager:GetWnd(UIDef.UI_TOOL_TIP)
    if tbWnd then
        if bForce then  
            UIManager:CloseWnd(UIDef.UI_TOOL_TIP)
            return
        end
        
        if tbWnd.DelayTimerHandle then
            tbWnd.bAutoClose = true
        else
            UIManager:CloseWnd(UIDef.UI_TOOL_TIP)
        end
    end
end

return UIToolTipHelper
