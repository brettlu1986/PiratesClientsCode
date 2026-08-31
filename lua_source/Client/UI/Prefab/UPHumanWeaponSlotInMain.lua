-----------------------------------------------------
--File Name    : UPHumanWeaponSlotInMain.lua
--Author       : WuJizhou
--Create Time  : 9/7/2018, 4:42:22 PM
--Description  : UPHumanWeaponSlotInMain
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")

local UPHumanWeaponSlotInMain = luaclass("UPHumanWeaponSlotInMain", PrefabBase)
local UISetUtils = require("UISetUtils")
local HumanWeaponDef = require("HumanWeaponDef")
local BattleItemSystemClient = require("BattleItemSystemClient")
local UIResourceDef = require("UIResourceDef")
local BattleHumanWeaponSystemNew = require("BattleHumanWeaponSystemNew_C")
local ClientEventDef = require("ClientEventDef")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")
local L10N = require("L10N")
local BattleItemUIHelper = require("BattleItemUIHelper")

local FireType = HumanWeaponDef.FireType
local OPACITY_ON_SELECTED = 1
local OPACITY_ON_UNSELECTED = 0.7

UPHumanWeaponSlotInMain.nSlotIndex = -1

local tbFireTypeNames = {}
tbFireTypeNames[FireType.Auto]   = UISetUtils.GetL10NTextByKey("UI_STATIC_HUMAN_FIRE_TYPE_AUTO")
tbFireTypeNames[FireType.Single] = UISetUtils.GetL10NTextByKey("UI_STATIC_HUMAN_FIRE_TYPE_SINGLE")
tbFireTypeNames[FireType.Triple] = UISetUtils.GetL10NTextByKey("UI_STATIC_HUMAN_FIRE_TYPE_TRIPLE")

local tbFireTypeIcons = {}
tbFireTypeIcons[FireType.Auto]   = UIResourceDef.FFA_HUMAN_WEAPON_FIRE_TYPE_AUTO
tbFireTypeIcons[FireType.Single] = UIResourceDef.FFA_HUMAN_WEAPON_FIRE_TYPE_SINGLE
tbFireTypeIcons[FireType.Triple] = UIResourceDef.FFA_HUMAN_WEAPON_FIRE_TYPE_TRIPLE

local function OnSlotClicked(self)
    local tbWeaponItem = self.tbWeaponItem
    if tbWeaponItem == nil then
        return
    end
    local PlayerSelf = GamePlayerSelfHelper:Get()

    local OwnerCharacter = tbWeaponItem:GetOwnerCharacter()
    if not OwnerCharacter then
        return
    end
    local HumanWeaponComponent = OwnerCharacter.HumanWeaponComponent
    if not HumanWeaponComponent then
        return
    end
    local nCurrentWeaponId = HumanWeaponComponent:GetCurrentWeaponInstanceId()
    local nNewWeaponId = tbWeaponItem:GetInstanceId()
    nNewWeaponId = nCurrentWeaponId ~= nNewWeaponId and nNewWeaponId or 0
    if not HumanWeaponComponent:CanChangeWeapon(nNewWeaponId) then 
        return 
    end
    PlayerSelf.ProgressBarComponent:ClearRehold()
    BattleHumanWeaponSystemNew:RequestSetCurrentWeapon(nNewWeaponId)
end

local function OnFireTypeBtnClicked(self)

end

local function OnFireTypeChanged(self, nInstanceId)
    if self.tbWeaponItem == nil then
        return
    end
    if self.tbWeaponItem:GetInstanceId() == nInstanceId then
        self:ShowWeapon(self.tbWeaponItem)
    end
end

-----------public------------

function UPHumanWeaponSlotInMain:SetSlotIndex(nIdx)
    self.nSlotIndex = nIdx
    local pWidgetRef = self.pWidgetRef
    -- if HumanWeaponSlotDef.Slots[nIdx] == HumanWeaponDef.WeaponSlotCategory.Melee then
    --     pWidgetRef.txtSlotCategory:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_HUMAN_MELEE_WEAPON"))
    -- elseif HumanWeaponSlotDef.Slots[nIdx] == HumanWeaponDef.WeaponSlotCategory.Ranged then
    --     pWidgetRef.txtSlotCategory:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_HUMAN_RANGED_WEAPON"))
    -- else
    --     pWidgetRef.txtSlotCategory:SetVisibility(ESlateVisibility.Collapsed)
    -- end
    pWidgetRef.txtSlotCategory:SetVisibility(ESlateVisibility.Collapsed)
end

function UPHumanWeaponSlotInMain:Disable()
    local pWidgetRef = self.pWidgetRef
    local InVisible = ESlateVisibility.Hidden
    pWidgetRef.img:SetVisibility(InVisible)
    pWidgetRef.imgColour:SetVisibility(InVisible)
    pWidgetRef.imgLevel:SetVisibility(InVisible)
    pWidgetRef.btnFireType:SetVisibility(InVisible)
    pWidgetRef.chkSlot:SetCheckedState(ECheckBoxState.Unchecked)
    pWidgetRef.hboxBulletInfo:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.txtSlotCategory:SetVisibility(InVisible)
    pWidgetRef:SetRenderOpacity(OPACITY_ON_UNSELECTED)
end

local function SetAmmoCount(self, nCurCount, nTotalCount, bInfinite)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.hboxBulletInfo:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    local szCount
    local pSlateColor
    if bInfinite then
        -- szCount = L10N:Format(L10N:Format(UISetUtils.GetL10NTextByKey("UI_BULLET_COUNT"), nCurCount, UISetUtils.GetL10NTextByKey("UI_INFINITE_BULLET")))
        szCount = L10N:Format(UISetUtils.GetL10NTextByKey("UI_BULLET_COUNT"), nCurCount, nTotalCount)
        pSlateColor = UIResourceDef.COLOR.WHITE.SLATE_COLOR
    else
        szCount = L10N:Format(UISetUtils.GetL10NTextByKey("UI_BULLET_COUNT"), nCurCount, nTotalCount)
            -- 根据子弹数量 设置显示颜色
        if nCurCount == 0 and (not bInfinite and nTotalCount == 0) then
            pSlateColor = UIResourceDef.COLOR.RED.SLATE_COLOR

        else
            pSlateColor = UIResourceDef.COLOR.WHITE.SLATE_COLOR
        end
    end
    pWidgetRef.txtLoadingBulletCount:SetText(szCount)
    pWidgetRef.txtLoadingBulletCount:SetColorAndOpacity(pSlateColor)
    UISetUtils.SetImageBrushTint(pWidgetRef.img, pSlateColor)
end

function UPHumanWeaponSlotInMain:ShowWeapon(tbHumanWeaponItem)
    self.tbWeaponItem = tbHumanWeaponItem
    local pWidgetRef = self.pWidgetRef
    local Visible = ESlateVisibility.SelfHitTestInvisible
    local InVisible = ESlateVisibility.Hidden
    if tbHumanWeaponItem == nil or not tbHumanWeaponItem:GetOwnerCharacter() then
        pWidgetRef.img:SetVisibility(InVisible)
        pWidgetRef.imgColour:SetVisibility(InVisible)
        pWidgetRef.imgLevel:SetVisibility(InVisible)
        pWidgetRef.btnFireType:SetVisibility(InVisible)
        pWidgetRef.chkSlot:SetCheckedState(ECheckBoxState.Unchecked)
        pWidgetRef.hboxBulletInfo:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.txtSlotCategory:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef:SetRenderOpacity(OPACITY_ON_UNSELECTED)
    else
        pWidgetRef.img:SetVisibility(Visible)
        pWidgetRef.imgColour:SetVisibility(Visible)
        pWidgetRef.imgLevel:SetVisibility(Visible)
        pWidgetRef.chkSlot:SetCheckedState(ECheckBoxState.Unchecked)
        pWidgetRef.txtSlotCategory:SetVisibility(ESlateVisibility.Collapsed)
        local tbTemplate = tbHumanWeaponItem:GetTemplate()
        -- 开火制式
        if #tbTemplate.tbFireTypes > 1 and tbHumanWeaponItem:IsCurrentWeapon() then
            pWidgetRef.btnFireType:SetVisibility(ESlateVisibility.Visible)
            local nCurFireType = tbHumanWeaponItem.tbProperty[HumanWeaponDef.Property.FireType]
            UISetUtils.SetButtonBrushRes(pWidgetRef.btnFireType, tbFireTypeIcons[nCurFireType]:load())
            pWidgetRef.txtSlotName:SetText(tbFireTypeNames[nCurFireType])
        else
            pWidgetRef.btnFireType:SetVisibility(ESlateVisibility.Collapsed)
        end
        -- 图标
        local szRes = BattleItemUIHelper.GetWeaponIcon(tbTemplate)
        if szRes ~= nil and #szRes > 0 then
            --local pRes = szRes:load()
            --UISetUtils.SetImageBrushRes(pWidgetRef.img, pRes)
            UISetUtils.SetAsyncImageBrushFromSprite(pWidgetRef.img, szRes, nil)
        else
            logwarning("szIconPath is illegal, res id is ", tbTemplate.nResId)
        end

        -- 子弹数量
        if tbTemplate.nPrimaryCategory == HumanWeaponDef.WeaponPrimaryCategory.Melee or 
        tbTemplate.nDecreaseBulletCount <= 0
        then
            pWidgetRef.hboxBulletInfo:SetVisibility(InVisible)
        else
            -- 枪内子弹数量/背包中适用的子弹数量
            local nCurCount = tbHumanWeaponItem:GetCurrentAmmoCount(true)
            local nTotalCount = tbHumanWeaponItem.tbProperty[HumanWeaponDef.Property.BulletMax]
            local bInfinite = tbHumanWeaponItem:IsBulletInfinite()
            SetAmmoCount(self, nCurCount, nTotalCount, bInfinite)
        end

        --根据是否为当前武器来判断
        local bCurrentWeapon = false
        local HumanWeaponComponent = tbHumanWeaponItem:GetOwnerCharacter().HumanWeaponComponent
        if(HumanWeaponComponent) then
            local nCurrentWeaponId = HumanWeaponComponent:GetCurrentWeaponInstanceId()
            bCurrentWeapon = tbHumanWeaponItem:GetInstanceId() == nCurrentWeaponId
        else
            bCurrentWeapon = tbHumanWeaponItem:IsCurrentWeapon()
        end

        if bCurrentWeapon then
            pWidgetRef.chkSlot:SetCheckedState(ECheckBoxState.Checked)
            pWidgetRef:SetRenderOpacity(OPACITY_ON_SELECTED)
        else
            pWidgetRef.chkSlot:SetCheckedState(ECheckBoxState.Unchecked)
            pWidgetRef:SetRenderOpacity(OPACITY_ON_UNSELECTED)
        end
        local nItemTemplateId = tbHumanWeaponItem:GetTemplateId()
        -- 设置武器品质背景
        pWidgetRef.imgColour:SetVisibility(Visible)
        local szBG = BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
        UISetUtils.SetImageBrushRes(pWidgetRef.imgColour, szBG:load())
        -- 设置武器品质等级
        pWidgetRef.imgLevel:SetVisibility(Visible)
        local nGrade = BattleItemDataTable:GetGrade(nItemTemplateId)
        local szGradeIcon = UIResourceDef.HUMAN_WEAPON_GRADE_ICON[nGrade]
        --UISetUtils.SetImageBrushRes(pWidgetRef.imgLevel, szGradeIcon:load())
        UISetUtils.SetAsyncImageBrushFromSprite(pWidgetRef.imgLevel, szGradeIcon, nil)
    end
end

local function OnGunAttack(self, tbGunWeapon)
    if(not self.tbWeaponItem or tbGunWeapon:GetInstanceId() ~= self.tbWeaponItem:GetInstanceId()) then
        return
    end
    local tbProperty = tbGunWeapon:GetProperty()

    if(tbProperty.nDecreaseBulletCount <= 0) then
        return
    end
    -- 枪内子弹数量/背包中适用的子弹数量
    -- 这里跟上面有些微的不一样，当前子弹数用的是武器的，不是道具的，武器的数量变化要比道具的早些
    local nCurCount = tbGunWeapon:GetCurrentAmmo(true)
    local tbItem = BattleItemSystemHelper:GetItem(tbGunWeapon:GetInstanceId(), true)
    assert(tbItem)
    local nTotalCount = tbItem.tbProperty[HumanWeaponDef.Property.BulletMax]
    -- local nTotalCount = BattleItemSystemClient:GetUnequippedItemCount(tbItem:GetTemplate().nBulletType)
    local bInfinite = tbItem:IsBulletInfinite()
    SetAmmoCount(self, nCurCount, nTotalCount, bInfinite)
end

local function PlayEquipAttachmentAnim(self, nItemTemplateId)
    local pWidgetRef = self.pWidgetRef
    local tbItemResTemplate = BattleItemDataTable:GetResTemplate(nItemTemplateId)
    local szIconPath = tbItemResTemplate.szIconPath
    UISetUtils.SetImageBrushRes(pWidgetRef.imgAttachment, szIconPath:load(), true)
    self:PlayAnimation("animEquip", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

local function OnItemEquipped(self, Item)
    local tbPlayer = GamePlayerSelfHelper:Get()
    if tbPlayer:IsHuman() then
        local nCategory = Item:GetCategory()
        if nCategory == BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT then
            local _, nOwnerInstanceId, _ = Item:SplitAndGetStorageLocation()
            local tbOwnerItem = BattleItemSystemClient:GetItem(nOwnerInstanceId)
            local _, _, nSlotIndex = tbOwnerItem:SplitAndGetStorageLocation()
            if self.nSlotIndex == nSlotIndex then
                PlayEquipAttachmentAnim(self, Item:GetTemplateId())
            end
        end
    end
end

----------life cycle----------

-- function UPHumanWeaponSlotInMain:OnDestroy()
-- end

-- function UPHumanWeaponSlotInMain:OnUnload()
-- end

-- function UPHumanWeaponSlotInMain:OnEnter()
-- end

-- function UPHumanWeaponSlotInMain:OnShow()
-- end

-- function UPHumanWeaponSlotInMain:OnHide()
-- end

-- function UPHumanWeaponSlotInMain:OnExit()
-- end

function UPHumanWeaponSlotInMain:OnBindEvent( EventHelper )
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnBlueprintItem.OnClicked, self, OnSlotClicked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnFireType.OnClicked, self, OnFireTypeBtnClicked)
    EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_WEAPON_FIRE_TYPE_CHANGED_CLIENT, self, OnFireTypeChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_WEAPON_GUN_ATTACK, self, OnGunAttack)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_EQUIPED_CLIENT, self, OnItemEquipped)
end


return UPHumanWeaponSlotInMain