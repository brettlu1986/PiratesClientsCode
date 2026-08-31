local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULWatchBattleWeapon = luaclass("ULWatchBattleWeapon", UILogicBase)
local BattleItemDataTable = require("BattleItemDataTable")
local WatchBattleSystem = require("WatchBattleSystem_C")
local UISetUtils = require("UISetUtils")
local CommonEventDef = require("CommonEventDef")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local HumanWeaponDef = require("HumanWeaponDef")
local HumanWeaponHelper = require("HumanWeaponHelper")
local UIResourceDef = require("UIResourceDef")
local ClientEventDef = require("ClientEventDef")
local ShipThrownItemSubCategoryDef = require("ShipThrownItemSubCategoryDef")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local ShipWeaponCategoryDataTable = require("ShipWeaponCategoryDataTable")
local ShipWeaponFiringType = require("ShipWeaponFiringType")
local ResourceCacheSystem = require("ResourceCacheSystem")
local BattleItemUIHelper = require("BattleItemUIHelper")

local function RefreshHumanMateWeaponRes(self, nWeaponTemplateId)
    local pWidgetRef = self.pWidgetRef
    self.Owner.pbShipWeaponCannon:SetVisible(false)
    if nWeaponTemplateId == 0 then  --empty hand
        pWidgetRef.imgWeapon:SetVisibility(ESlateVisibility.Collapsed)

        pWidgetRef.ImageThrow:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.ImageWeaponThrow:SetVisibility(ESlateVisibility.Collapsed)

        pWidgetRef.ImageColor:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.ImageLevel:SetVisibility(ESlateVisibility.Collapsed)
    else
        local tbTemplate = BattleItemDataTable:GetTemplate(nWeaponTemplateId)

        local pRes = nil
        local tbResTemplate = BattleItemDataTable:GetResTemplate(nWeaponTemplateId)
        if tbTemplate.nCategory == BattleItemCategoryDef.HUMAN_THROWN_ITEM then
            pWidgetRef.ImageThrow:SetVisibility(ESlateVisibility.HitTestInvisible)
            pWidgetRef.ImageWeaponThrow:SetVisibility(ESlateVisibility.HitTestInvisible)
            pWidgetRef.imgWeapon:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.ImageColor:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.ImageLevel:SetVisibility(ESlateVisibility.Collapsed)
            pRes = tbResTemplate.szIconPath:load()
            UISetUtils.SetImageBrushRes(pWidgetRef.ImageWeaponThrow, pRes)
        else
            pWidgetRef.ImageThrow:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.ImageWeaponThrow:SetVisibility(ESlateVisibility.Collapsed)

            local szBG = BattleItemColorGradeHelper.GetColorGradeImg(nWeaponTemplateId)
            if szBG then
                pWidgetRef.ImageColor:SetVisibility(ESlateVisibility.HitTestInvisible)
                UISetUtils.SetImageBrushRes(pWidgetRef.ImageColor, szBG:load())
            end

            local nGrade = BattleItemDataTable:GetGrade(nWeaponTemplateId)
            if nGrade then
                pWidgetRef.ImageLevel:SetVisibility(ESlateVisibility.HitTestInvisible)
                local szGradeIcon = UIResourceDef.HUMAN_WEAPON_GRADE_ICON[nGrade]
                if szGradeIcon then
                    UISetUtils.SetImageBrushRes(pWidgetRef.ImageLevel, szGradeIcon:load())
                end
            end

            local szRes = BattleItemUIHelper.GetWeaponIcon(tbTemplate)
            if szRes then
                pWidgetRef.imgWeapon:SetVisibility(ESlateVisibility.HitTestInvisible)
                UISetUtils.SetAsyncImageBrushFromSprite(pWidgetRef.imgWeapon, szRes, nil, true)
            else
                logwarning("[ClientWatch] the client res template should exist, weapon template id is: ", nWeaponTemplateId)
            end
        end
    end
end

local function RefreshHumanMateWeaponAmmo(self, nWeaponTemplateId, nAmmoLeft, nAmmoMax)
    local pWidgetRef = self.pWidgetRef
    if nWeaponTemplateId == 0 then  --empty hand
        pWidgetRef.bulletInfo:SetVisibility(ESlateVisibility.Collapsed)
    else
        local tbTemplate = BattleItemDataTable:GetTemplate(nWeaponTemplateId)
        if tbTemplate.nCategory == BattleItemCategoryDef.HUMAN_THROWN_ITEM then
            pWidgetRef.bulletInfo:SetVisibility(ESlateVisibility.HitTestInvisible)
            pWidgetRef.txtSplitLine:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.txtBulletMax:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.txtBulletLeft:SetText(nAmmoLeft)
        else
            local nWeaponCategory = HumanWeaponHelper.GetWeaponCategory(nWeaponTemplateId)
            if tbTemplate.nPrimaryCategory == HumanWeaponDef.WeaponPrimaryCategory.Melee or
                nWeaponCategory == HumanWeaponDef.WeaponCategory.Wand then
                pWidgetRef.bulletInfo:SetVisibility(ESlateVisibility.Collapsed)
            else
                pWidgetRef.bulletInfo:SetVisibility(ESlateVisibility.HitTestInvisible)
                pWidgetRef.txtSplitLine:SetVisibility(ESlateVisibility.HitTestInvisible)
                pWidgetRef.txtBulletMax:SetVisibility(ESlateVisibility.HitTestInvisible)
                pWidgetRef.txtBulletLeft:SetText(nAmmoLeft)
                pWidgetRef.txtBulletMax:SetText(nAmmoMax)
            end
        end
    end
end

local function CheckAndRefreshCaronnadeCameraView(self, bActivate)
    local tbCurrentWatchObj = self.Owner.tbCurrrentWatchObj
    if not tbCurrentWatchObj.pUEActor then  
        return 
    end
    local pComponent = tbCurrentWatchObj.pUEActor.CarronadeComponent
    if bActivate then
        pComponent:PreFire()
    else
        pComponent:CancelFire()
    end
    local nShipTemplateid = tbCurrentWatchObj:GetShipTemplateId()
    self.EventHelper:FireEvent(ClientEventDef.EV_WATCH_CARRONADE_CAMERA, nShipTemplateid, bActivate)
end

local function SetupShipWeaponParam(self, tbTemplate, pComponent, nActiveWeaponSlot)
    local nWeaponSlot = nActiveWeaponSlot
    local nSubCategory = tbTemplate.nSubCategory
    local nWeaponId = -1
    local nBaseDamage = tbTemplate.nBaseDamage
    local nDamageRadius = tbTemplate.nDamageRadius
    local nDamageInnerRadius = tbTemplate.nDamageInnerRadius
    local nMinRadiusDamage = tbTemplate.nMinRadiusDamage
    local bAutoBoom = tbTemplate.bAutoBoom
    local pWeaponSlot = ShipWeaponSlotDef.GetBPEnum(nWeaponSlot)
    local bPairedWeapon = ShipWeaponCategoryDataTable:GetIsPairedWeapon(nSubCategory)
    local pBulletClass = tbTemplate.szBulletRes and ResourceCacheSystem:SyncCacheInDungeon(tbTemplate.szBulletRes)
    local nHalfRotationRange = tbTemplate.nRotationRange / 2
    local pFiringType = ShipWeaponFiringType.GetBPEnum(tbTemplate.nFiringType)
    local nMinFiringRange = tbTemplate.nMinFiringRange
    local nFiringRange = tbTemplate.nFiringRange
    local nBulletSpeed = tbTemplate.nBulletSpeed
    local tbValidWeaponSlotLevel = tbTemplate.tbValidWeaponSlotLevel
    local nTriggerRange = tbTemplate.nTriggerRange
    pComponent:Setup(nWeaponId, nBaseDamage, nDamageRadius, nDamageInnerRadius, nMinRadiusDamage,
                    bAutoBoom, nTriggerRange, pWeaponSlot, bPairedWeapon, pBulletClass, nHalfRotationRange,
                    pFiringType, nMinFiringRange, nFiringRange, nBulletSpeed, tbValidWeaponSlotLevel)
end

local function CheckAndActiveShipWeaponAimAndFireRange(self, nShipWeaponTemplateId, bShipSlotMove, nActiveWeaponSlot)
    log("CheckAndActiveShipWeaponAimAndFireRange:", nShipWeaponTemplateId, bShipSlotMove, nActiveWeaponSlot)
    if not bShipSlotMove then
        return
    end

    local tbPlayer = self.Owner.tbCurrrentWatchObj
    local pUEActor = tbPlayer.pUEActor
    pUEActor.CannonComponent:DeactivateWeapon()
    pUEActor.CarronadeComponent:DeactivateWeapon()
    self.Owner.pbShipWeaponCannon:SetVisible(false)

    local tbTemplate = BattleItemDataTable:GetTemplate(nShipWeaponTemplateId)
    if not tbTemplate then
        return
    end
    if tbTemplate.nCategory == BattleItemCategoryDef.SHIP_THROWN_ITEM then
        if tbTemplate.nSubCategory == ShipThrownItemSubCategoryDef.CARRONADE then
            local pComponent = pUEActor.CarronadeComponent
            local nGravityZ = tbTemplate.nGravityZ
            SetupShipWeaponParam(self, tbTemplate, pComponent, nActiveWeaponSlot)
            pComponent:SetupCarronade(nGravityZ)
            pComponent:ActivateWeapon()
            log("CarronadeComponent:ActiveWeapon")
        end
    else
        local pComponent = pUEActor.CannonComponent
        local nGravityZ = tbTemplate.nGravityZ
        local nBulletLaunchInterval = tbTemplate.nBulletLaunchInterval
        local bConcentratedFiring = tbTemplate.bConcentratedFiring
        local nLeanFactorRatio = tbTemplate.nLeanFactorRatio
        SetupShipWeaponParam(self, tbTemplate, pComponent, nActiveWeaponSlot)
        pUEActor:InitCannonComponentOnClient()
        pComponent:SetupCannon(nGravityZ, nBulletLaunchInterval, bConcentratedFiring, nLeanFactorRatio)
        pComponent:ActivateWeapon()
        log("CannonComponent:ActiveWeapon")
        self.Owner.pbShipWeaponCannon:UpdateCrosshairsImageRes(tbTemplate.nSubCategory)
        self.Owner.pbShipWeaponCannon:SetVisible(true)
    end
end

local function RefreshShipMateWeaponRes(self, nWeaponTemplateId, bShipSlotMove, nShipWeaponSlot)
    local pWidgetRef = self.pWidgetRef

    local tbCurrentWatchObj = self.Owner.tbCurrrentWatchObj
    local bValidShip = false
    if tbCurrentWatchObj and tbCurrentWatchObj.pUEActor and tbCurrentWatchObj:IsShip() then
        bValidShip = true
    end

    if not bValidShip then
        return
    end

    local bHideMast = false


    pWidgetRef.ovlCrosshairs:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.ImageThrow:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.ImageWeaponThrow:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.ImageColor:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.ImageLevel:SetVisibility(ESlateVisibility.Collapsed)

    if nWeaponTemplateId == 0 then
        pWidgetRef.imgWeapon:SetVisibility(ESlateVisibility.Collapsed)
        -- CheckAndRefreshCaronnadeCameraView(self, false)
    else
        local tbResTemplate = BattleItemDataTable:GetResTemplate(nWeaponTemplateId)
        if tbResTemplate and tbResTemplate.szSilhouettePath then
            pWidgetRef.imgWeapon:SetVisibility(ESlateVisibility.HitTestInvisible)
            UISetUtils.SetAsyncImageBrushFromSprite(pWidgetRef.imgWeapon, tbResTemplate.szSilhouettePath, nil, true)
            bHideMast = true
        else
            pWidgetRef.imgWeapon:SetVisibility(ESlateVisibility.Collapsed)
        end

        -- local tbTemplate = BattleItemDataTable:GetTemplate(nWeaponTemplateId)
        -- if (not bValidShip)
        -- or (tbTemplate.nCategory ~= BattleItemCategoryDef.SHIP_THROWN_ITEM)
        -- or (tbTemplate.nSubCategory ~= ShipThrownItemSubCategoryDef.CARRONADE) then
        --     CheckAndRefreshCaronnadeCameraView(self, false)
        -- end
    end

    CheckAndActiveShipWeaponAimAndFireRange(self, nWeaponTemplateId, bShipSlotMove, nShipWeaponSlot )
    if bShipSlotMove then
        tbCurrentWatchObj.pUEActor:SetMastVisible(not bHideMast)
    end
end

local function RefreshShipMateWeaponAmmo(self, nWeaponTemplateId, nAmmoLeft, nAmmoMax)
    local pWidgetRef = self.pWidgetRef
    if nWeaponTemplateId == 0 then
        pWidgetRef.bulletInfo:SetVisibility(ESlateVisibility.Collapsed)
    else
        local tbTemplate = BattleItemDataTable:GetTemplate(nWeaponTemplateId)
        if tbTemplate.nCategory == BattleItemCategoryDef.SHIP_THROWN_ITEM then
            pWidgetRef.bulletInfo:SetVisibility(ESlateVisibility.HitTestInvisible)
            pWidgetRef.txtSplitLine:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.txtBulletMax:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.txtBulletLeft:SetText(nAmmoLeft)
        else
            pWidgetRef.bulletInfo:SetVisibility(ESlateVisibility.HitTestInvisible)
            pWidgetRef.txtSplitLine:SetVisibility(ESlateVisibility.HitTestInvisible)
            pWidgetRef.txtBulletMax:SetVisibility(ESlateVisibility.HitTestInvisible)
            pWidgetRef.txtBulletLeft:SetText(nAmmoLeft)
            pWidgetRef.txtBulletMax:SetText(nAmmoMax)
        end
    end
end

--这里是每次只要切换观察者 就会调用的地方
function ULWatchBattleWeapon:RefreshCurrentMateWeapon()
    if self.Owner.tbLastWatchObj and self.Owner.tbLastWatchObj:IsShip() then
        local pUEActor = self.Owner.tbLastWatchObj.pUEActor
        if pUEActor and pUEActor.CannonComponent then
            pUEActor.CannonComponent:DeactivateWeapon()
        end
    end

    local tbWatchInfo = WatchBattleSystem.tbWatchMateInfo
    local tbCurrentWatchObj = self.Owner.tbCurrrentWatchObj
    local bIsHuman = tbCurrentWatchObj:IsHuman()

    --服务器跟客户端 人船武器info 不一致，强清ui，防止还是没切换前的ui状态
    if tbWatchInfo.is_ship ~= not bIsHuman then
        tbWatchInfo.weapon_tempId = 0
        tbWatchInfo.bullet_count = 0
        tbWatchInfo.bullet_max = 0
    end

    if bIsHuman then
        RefreshHumanMateWeaponRes(self, tbWatchInfo.weapon_tempId)
        RefreshHumanMateWeaponAmmo(self, tbWatchInfo.weapon_tempId, tbWatchInfo.bullet_count, tbWatchInfo.bullet_max)
        --logdebug("watch mate info from server ",tbWatchInfo.weapon_tempId, tbWatchInfo.bullet_count, tbWatchInfo.bullet_max)
    else
        RefreshShipMateWeaponRes(self, tbWatchInfo.weapon_tempId, true, tbWatchInfo.ship_weapon_slot)
        RefreshShipMateWeaponAmmo(self, tbWatchInfo.weapon_tempId, tbWatchInfo.bullet_count, tbWatchInfo.bullet_max)
    end
end

--换武器的时候 需要把武器是图标刷新一下 ， 子弹从服务器下发下来
--这种方式不太好，换武器有个过程，每次换完才走这里，导致跟子弹数目变化不一致
-- local function OnHumanWeaponChanged(self, nNewWeapon, nLastWeapon, nCharacterInstanceId)
--     local tbCurrentWatchObj = self.Owner.tbCurrrentWatchObj
--     if nCharacterInstanceId == tbCurrentWatchObj:GetServerInstanceId() then
--         local WeaponComponent = tbCurrentWatchObj.HumanWeaponComponent
--         local nTemplateId = WeaponComponent:GetCurrentWeaponTemplateId()
--         RefreshHumanMateWeaponRes(self, nTemplateId)
--     end
-- end

--装填，换武器，开枪 当前武器子弹数都可能改变
local function OnMateWeaponAmmoChanged(self, tbPacket)
    local tbCurrentWatchObj = self.Owner.tbCurrrentWatchObj
    if tbCurrentWatchObj:IsHuman() then
        --跟着子弹也一起检查下 看是否需要换武器的图
        RefreshHumanMateWeaponRes(self, tbPacket.template_id)
        RefreshHumanMateWeaponAmmo(self, tbPacket.template_id, tbPacket.bullet_count, tbPacket.bullet_max)
    else
        RefreshShipMateWeaponRes(self, tbPacket.template_id, tbPacket.bShipWeaponSlotMove, tbPacket.ship_weapon_slot)
        RefreshShipMateWeaponAmmo(self, tbPacket.template_id, tbPacket.bullet_count, tbPacket.bullet_max)
    end
end

local function CheckWinAimCamera(self)
    local tbCurrentWatchObj = self.Owner.tbCurrrentWatchObj
    if tbCurrentWatchObj and tbCurrentWatchObj:IsHuman() and tbCurrentWatchObj.HumanWeaponComponent then
        if tbCurrentWatchObj.HumanWeaponComponent:IsAiming() then
            tbCurrentWatchObj.HumanWeaponComponent:ChangeUEActorStateForAim(false, true)
        end
    end
end

function ULWatchBattleWeapon:OnLoad()
    -- bind prefab
end

function ULWatchBattleWeapon:OnEnter()
    --Owner is UIWatchBattle
end

function ULWatchBattleWeapon:OnBindEvent(EventHelper)

    --EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED, self, OnHumanWeaponChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_MATE_BULLET_CHANGED, self, OnMateWeaponAmmoChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_MATE_CARRONADE_ACTIVE_CHANGE, self, CheckAndRefreshCaronnadeCameraView)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHECK_WIN_AIM_CAMERA, self, CheckWinAimCamera)
end

function ULWatchBattleWeapon:OnUnload()
    --unload res
end

return ULWatchBattleWeapon