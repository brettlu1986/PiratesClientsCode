-----------------------------------------------------
--File Name    : ULHumanAim.lua
--Description  : 人形准心
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULHumanAim = luaclass("ULHumanAim", UILogicBase)

local BattleItemSystemClient = require("BattleItemSystemClient")
local BattleItemCategoryDef = require("BattleItemCategoryDef")


local AIM_OFFSET = Margin{Left = 0, Top = 0, Right = 0, Bottom = 0}
local AIM_ANCHOR = Anchors{Minimum=Vector2D{X = 0, Y = 0}, Maximum=Vector2D{X = 1, Y = 1}}
local AIM_ZORDER = -1

ULHumanAim.OneSecondTimer = nil
ULHumanAim.nEndTime = nil
ULHumanAim.nState = nil
ULHumanAim.nInstanceId = nil
ULHumanAim.bInWaitTime = false
ULHumanAim.pbAim = nil



local function RemoveAim(self)
    self.pWidgetRef.imgAimCenter:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if self.pbAim then
        local nChildIndex = self.pWidgetRef.cvsHuman:GetChildIndex(self.pbAim.pWidgetRef)
        self.PrefabHelper:UnbindPrefab(self.pbAim)
        self.pWidgetRef.cvsHuman:RemoveChildAt(nChildIndex)
        self.pbAim = nil
    end
end

function ULHumanAim:OnCurrentWeaponChanged(nNewWeapon, nLastWeapon)
    --logdebug("ULHumanAim:OnCurrentWeaponChange,nNewWeapon, nLastWeapon=",nNewWeapon, nLastWeapon)
    if not nNewWeapon then
        if self.pbAim then
            RemoveAim(self)
        end
        return
    end
    if self.pbAim then
        RemoveAim(self)
    end
    if nNewWeapon == 0 then
        return
    end
    local WeaponItem = BattleItemSystemClient:GetItem(nNewWeapon)
    if not WeaponItem then
        -- logerror("ULHumanAim:OnCurrentWeaponChanged weapon is nil, nNewWeapon, nLastWeapon=", nNewWeapon, nLastWeapon)
        return
    end
    local nCategory = WeaponItem:GetCategory()
    if nCategory == BattleItemCategoryDef.HUMAN_WEAPON or nCategory == BattleItemCategoryDef.HUMAN_THROWN_ITEM then
        local szAimRes = WeaponItem:GetSightRes()
        if not szAimRes or szAimRes == "" then
            --logwarning("ULHumanAim:OnCurrentWeaponChanged szAimRes is nil or empty, nNewWeapon, nLastWeapon=", nNewWeapon, nLastWeapon)
            return
        end
        self.pWidgetRef.imgAimCenter:SetVisibility(ESlateVisibility.Collapsed)
        self.pbAim = self.PrefabHelper:CreatePrefab(szAimRes)
        local ObjWidget = self.pbAim.pWidgetRef
        --self.pbAim:SetOwner(self.Parent)
        self.pWidgetRef.cvsHuman:AddChildToCanvas(ObjWidget)
        local ScopeCheckState = self.pWidgetRef.chkAim:GetCheckedState()
        if ScopeCheckState == ECheckBoxState.Checked then
            ObjWidget:SetVisibility(ESlateVisibility.Collapsed)
        else
            ObjWidget:SetVisibility(ESlateVisibility.HitTestInvisible)
        end
        local ObjWidgetSlot = ObjWidget.Slot
        ObjWidgetSlot:SetAlignment(Vector2D{X = 0.5, Y = 0.5})
        ObjWidgetSlot:SetAnchors(AIM_ANCHOR)
        ObjWidgetSlot:SetOffsets(AIM_OFFSET)
        ObjWidgetSlot:SetZOrder(AIM_ZORDER)
        self.pbAim:Init(WeaponItem)
        --self.pbAim:ScaleToTargetSize(true, true)
    end
    
end

function ULHumanAim:Activate()
end

function ULHumanAim:Deactivate()
    RemoveAim(self)
end

function ULHumanAim:HideMeleeAimCenter( bHide )
    if bHide then   
        self.pWidgetRef.imgAimCenter:SetVisibility(ESlateVisibility.Collapsed)
    else  
        self.pWidgetRef.imgAimCenter:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
end

--新接口 替换老的 
function ULHumanAim:RefreshCenterAim(bInhibitAttack, bAim)
    if not self.pbAim then  
        return
    end
    local pNotAimWidget = self.pbAim.pWidgetRef.ovlNotAim
    local pAimWidget = self.pbAim.pWidgetRef.ovlAim

    if bAim then   
        pNotAimWidget:SetVisibility(ESlateVisibility.Collapsed)
        pAimWidget:SetVisibility( bInhibitAttack and ESlateVisibility.Collapsed or ESlateVisibility.SelfHitTestInvisible )
    else   
        pNotAimWidget:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pAimWidget:SetVisibility(ESlateVisibility.Collapsed)
    end
end

return ULHumanAim