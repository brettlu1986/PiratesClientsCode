-----------------------------------------------------
--File Name    : ULWatchBattleMateAim.lua
--Description  : 观战准心
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULWatchBattleMateAim = luaclass("ULWatchBattleMateAim", UILogicBase)

local WatchBattleSystem = require("WatchBattleSystem_C")
local BattleItemDataTable = require("BattleItemDataTable")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local BattleItemSystemClient = require("BattleItemSystemClient")
local CommonEventDef = require("CommonEventDef")
local ClientEventDef = require("ClientEventDef")
local HumanWeaponMisc = require("HumanWeaponMisc")
--local HumanMovementStateType = require("HumanMovementStateType")
-- local ShipWeaponCategoryDataTable = require("ShipWeaponCategoryDataTable")
-- local UISetUtils = require("UISetUtils")

ULWatchBattleMateAim.pbAim = nil
ULWatchBattleMateAim.bIsWatchMateMoving = false

local HumanWeaponType = HumanWeaponMisc.Type
local AIM_OFFSET = Margin{Left = 0, Top = 0, Right = 0, Bottom = 0}
local AIM_ANCHOR = Anchors{Minimum=Vector2D{X = 0, Y = 0}, Maximum=Vector2D{X = 1, Y = 1}}

local tbWatchBattleDef = GameCameraModeGroupDef.WatchBattleDef

--human aim

local function RefreshWatchAim(self, bAim)
    if not self.pbAim then  
        return 
    end

    local pNotAimWidget = self.pbAim.pWidgetRef.ovlNotAim
    local pAimWidget = self.pbAim.pWidgetRef.ovlAim

    if bAim then  
        pNotAimWidget:SetVisibility(ESlateVisibility.Collapsed)
        pAimWidget:SetVisibility(ESlateVisibility.HitTestInvisible)
    else  
        pNotAimWidget:SetVisibility(ESlateVisibility.HitTestInvisible)
        pAimWidget:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function RemoveHumanAim(self)
    self.pWidgetRef.imgAimCenter:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if self.pbAim then
        local nChildIndex = self.pWidgetRef.cvsBattle:GetChildIndex(self.pbAim.pWidgetRef)
        self.PrefabHelper:UnbindPrefab(self.pbAim)
        self.pWidgetRef.cvsBattle:RemoveChildAt(nChildIndex)
        self.pbAim = nil
    end
end

local function RefreshHumanWeaponAimRes(self, nWeaponTemplateId)

    self.pWidgetRef.ovlCrosshairs:SetVisibility(ESlateVisibility.Collapsed)

    if nWeaponTemplateId == 0 then
        self.pWidgetRef.imgAimCenter:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        if self.pbAim then
            RemoveHumanAim(self)
        end
        return
    end

    local tbCurrentWatchObj = self.Owner.tbCurrrentWatchObj
    local WeaponComponent = tbCurrentWatchObj.HumanWeaponComponent
    local tbCurrentWeapon = WeaponComponent:GetCurrentWeapon(true)
    if not tbCurrentWeapon then
        if self.pbAim then
            RemoveHumanAim(self)
        end
    end

    if self.pbAim then
        RemoveHumanAim(self)
    end

    local tbTemplate = BattleItemDataTable:GetTemplate(nWeaponTemplateId)
    local szAimRes = tbTemplate.szSightRes
    if not szAimRes or szAimRes == "" then
        return
    end

    local FakeWeaponItem = BattleItemSystemClient:CreateTempItem(nWeaponTemplateId, 1)

    self.pWidgetRef.imgAimCenter:SetVisibility(ESlateVisibility.Collapsed)
    self.pbAim = self.PrefabHelper:CreatePrefab(szAimRes)
    local ObjWidget = self.pbAim.pWidgetRef
    --self.pbAim:SetOwner(self.Parent)
    self.pWidgetRef.cvsBattle:AddChildToCanvas(ObjWidget)

    if tbCurrentWeapon:IsType(HumanWeaponType.GUN) and tbCurrentWeapon:IsAiming() then
        ObjWidget:SetVisibility(ESlateVisibility.Collapsed)
    else
        ObjWidget:SetVisibility(ESlateVisibility.HitTestInvisible)
    end

    local ObjWidgetSlot = ObjWidget.Slot
    ObjWidgetSlot:SetAlignment(Vector2D{X = 0.5, Y = 0.5})
    ObjWidgetSlot:SetAnchors(AIM_ANCHOR)
    ObjWidgetSlot:SetOffsets(AIM_OFFSET)
    self.pbAim:Init(FakeWeaponItem)
end

--人切换武器 会换瞄准的ui
local function OnHumanWeaponChanged(self, nNewWeapon, nLastWeapon, nCharacterInstanceId)
    local tbCurrentWatchObj = self.Owner.tbCurrrentWatchObj
    if nCharacterInstanceId == tbCurrentWatchObj:GetServerInstanceId() then
        local WeaponComponent = tbCurrentWatchObj.HumanWeaponComponent
        if WeaponComponent then
            local nTemplateId = WeaponComponent:GetCurrentWeaponTemplateId()
            RefreshHumanWeaponAimRes(self, nTemplateId)
        end
    end
end

----ship aim
local function RefreshShipWeaponAimRes(self, nWeaponTemplateId)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.imgAimCenter:SetVisibility(ESlateVisibility.Collapsed)
    -- if nWeaponTemplateId == 0 then  --empty hand
    --     pWidgetRef.ovlCrosshairs:SetVisibility(ESlateVisibility.Collapsed)
    -- else
    --     pWidgetRef.ovlCrosshairs:SetVisibility(ESlateVisibility.Collapsed)
    --     local tbTemplate = BattleItemDataTable:GetTemplate(nWeaponTemplateId)
    --     local szCrosshairsPath = ShipWeaponCategoryDataTable:GetCrosshairsRes(tbTemplate.nSubCategory)
    --     if szCrosshairsPath then
    --         UISetUtils.SetImageBrushRes(pWidgetRef.imgCrosshairs, szCrosshairsPath:load(), true)
    --         pWidgetRef.ovlCrosshairs:SetVisibility(ESlateVisibility.HitTestInvisible)
    --     end
    -- end
end

local function OnShipWeaponChanged(self, tbPacket)
    local tbCurrentWatchObj = self.Owner.tbCurrrentWatchObj
    if tbCurrentWatchObj:IsShip() then
        RefreshShipWeaponAimRes(self, tbPacket.template_id)
    end
end
----

--这里是每次只要切换观察者 就会调用的地方
function ULWatchBattleMateAim:RefreshCurrentMateAim()
    local tbCurrentWatchObj = self.Owner.tbCurrrentWatchObj
    local tbWatchInfo = WatchBattleSystem.tbWatchMateInfo
    if tbCurrentWatchObj:IsHuman() then
        RefreshHumanWeaponAimRes(self, tbWatchInfo.weapon_tempId)
    else
        RefreshShipWeaponAimRes(self, tbWatchInfo.weapon_tempId)
    end
end

--开镜切换会触发的地方
local function OnWatchBattleCameraChanged(self, nWatchState, tbParam)
    if nWatchState == tbWatchBattleDef.ChangeAim then
        if tbParam.bIsShip then
            log("[ShipAim] the ship aim changed")
        else
            if tbParam.bInAim then
                RefreshWatchAim(self, true)
            else
                RefreshWatchAim(self, false)
            end
        end
    elseif nWatchState == tbWatchBattleDef.ChangeVehicle then
        if tbParam.bGetIn then   
            self.pWidgetRef.imgAimCenter:SetVisibility(ESlateVisibility.Collapsed)
        else  
            self.pWidgetRef.imgAimCenter:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        end
    end
end

local function OnActorDestroy(self, tbGameObject)
    local tbCurrentWatchObj = self.Owner.tbCurrrentWatchObj
    if tbCurrentWatchObj.nServerInstanceId == tbGameObject.nServerInstanceId and 
        tbCurrentWatchObj:IsHuman() then
        RemoveHumanAim(self)
    end
end

function ULWatchBattleMateAim:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_WATCH_BATTLE_STATE_CHANGE, self, OnWatchBattleCameraChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED, self, OnHumanWeaponChanged)

    --这个事件放在这里主要用来处理 船的武器改变事件
    EventHelper:RegisterEvent(CommonEventDef.EV_MATE_BULLET_CHANGED, self, OnShipWeaponChanged)

    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, OnActorDestroy)
end

function ULWatchBattleMateAim:OnUnload()
    --unload res
end

return ULWatchBattleMateAim