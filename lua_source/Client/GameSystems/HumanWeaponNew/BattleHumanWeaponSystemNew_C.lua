local luaclass = require("luaclass")
local BattleHumanWeaponSystemNew = require("BattleHumanWeaponSystemNew")
local BattleHumanWeaponSystemNew_C = luaclass("BattleHumanWeaponSystemNew_C", BattleHumanWeaponSystemNew)

local BattleItemCategoryDef = require("BattleItemCategoryDef")
local Proto = require("DungeonCommonProtoNames")
--local CommonEventDef = require("CommonEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local NetworkManager = dynamic_require("NetworkManager")
local HumanWeaponMisc = require("HumanWeaponMisc")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local HumanWeaponHelper = require("HumanWeaponHelper")
local ClientEventDef = require("ClientEventDef")
--local BattleItemSystemClient = require("BattleItemSystemClient")
local CommonEventDef = require("CommonEventDef")
local HumanWeaponRepHelper = require("HumanWeaponRepHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local HumanMovementStateType = require("HumanMovementStateType")
local WeaponRequestFailReasonDef = require("WeaponRequestFailReasonDef")
local HumanWeaponBPType = require("HumanWeaponType")

local HumanWeaponType = HumanWeaponMisc.Type

local function GetWeaponComponent(tbItem)
    local Owner = tbItem:GetOwnerCharacter()
    return Owner.HumanWeaponComponent, Owner
end

local function TryReloadWhenAddAmmo(self, tbItem)
    if tbItem:GetCategory() ~= BattleItemCategoryDef.HUMAN_BULLET then
        return
    end

    local WeaponComponent, Owner = GetWeaponComponent(tbItem)
    if not Owner then
        logerror("BattleHumanWeaponSystem, TryReload error, OwnerCharacter is nil")
        return
    end
    if not WeaponComponent then
        return
    end

    local tbCurrentWeapon = WeaponComponent:GetCurrentWeapon()
    if(not tbCurrentWeapon) then
        return
    end

    local nCurrentInstanceId = WeaponComponent:GetCurrentWeaponInstanceId()
    local tbCurWeapon = BattleItemSystemHelper:GetItem(nCurrentInstanceId, true)
    if not tbCurWeapon then
        return
    end

    if tbCurWeapon:GetCategory() ~= BattleItemCategoryDef.HUMAN_WEAPON then
        return
    end

    -- 捡到子弹了
    local nBulletTemplateId = tbItem:GetTemplateId()
    if nBulletTemplateId ~= tbCurWeapon:GetBulletItemTemplateId() then
        return
    end

    if(tbItem:GetStorageLocation().nOwnerInstanceId == tbCurrentWeapon:GetInstanceId()) then
        -- 这里是枪上的子弹重新上弹，所以要判过去
        return
    end

    local nRemainAmmo, _ = tbCurrentWeapon:GetAmmoInfo()
    local bNeedReload = nRemainAmmo == 0

    if(bNeedReload) then
        self:RequestReload()
    end
end

-- local function OnItemStackCountChanged(self, tbItem)
--     TryReload(self, tbItem)
-- end

function BattleHumanWeaponSystemNew_C:OnItemAdded(tbItem)
    BattleHumanWeaponSystemNew_C.super.OnItemAdded(self, tbItem)

    TryReloadWhenAddAmmo(self, tbItem)
end

function BattleHumanWeaponSystemNew_C:OnItemEquiped(_, tbItem)
    BattleHumanWeaponSystemNew_C.super.OnItemEquiped(self, _, tbItem)

    if(self.bExchangingWeapon or not self:IsWeapon(tbItem)) then
        return
    end

    local nInstanceId = tbItem:GetInstanceId()
    local Component = GetWeaponComponent(tbItem)
    if(Component and Component:GetCurrentWeaponInstanceId() == nInstanceId) then
        -- 重新装了，需要重刷武器
        Component:OnCurrentWeaponChanged(nInstanceId, true)
    end
end

function BattleHumanWeaponSystemNew_C:OnFinishExchange(Item1, Item2)
    if(self.bExchangingWeapon) then
        -- 重新刷下绑定状态
        local Item = Item1 == nil and Item2 or Item1
        local Component = Item:GetOwnerCharacter().HumanWeaponComponent
        if(Component)then
            local nWeaponState = Component:GetCurrentState()
            if nWeaponState ~= HumanWeaponStateDef.UNHOLDING and nWeaponState ~= HumanWeaponStateDef.UNHOLDED then
                Component:OnCurrentWeaponChanged(Component:GetCurrentWeaponInstanceId(), true)
            end
        end
    end

    BattleHumanWeaponSystemNew_C.super.OnFinishExchange(self, Item1, Item2)
end

function BattleHumanWeaponSystemNew_C:OnEquipStackableItem(tbItem, nCount, nChangedCount)
    if(not self:IsWeapon(tbItem)) then
        return
    end

    local WeaponComponent, _ = GetWeaponComponent(tbItem)
    if(not WeaponComponent) then
        return
    end

    local tbCurrentWeapon = WeaponComponent:GetCurrentWeapon()
    if(tbCurrentWeapon == nil or tbCurrentWeapon:GetInstanceId() ~= tbItem:GetInstanceId()) then
        return
    end
    -- logdebug("nCount", nCount, "nChangedCount", nChangedCount)
    assert(tbCurrentWeapon:IsType(HumanWeaponType.GUN))
    if(tbCurrentWeapon:IsWaitingReloadResult() and nChangedCount > 0) then
        -- 发了reload请求，并且回包是增加子弹的，那么认为是reload结果
        tbCurrentWeapon:SetAmmoReloadResult(nCount)
    else
        tbCurrentWeapon:SetCurrentAmmo(nCount)
    end
end

local function OnPlayerSelfReady(self)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if(not PlayerSelf:IsHuman()) then
        return
    end

    -- 根据道具信息恢复所有道具
    local Component = PlayerSelf.HumanWeaponComponent
    -- local tbWeaponItems, tbAttachments, tbWeapon, nInstanceId
    -- tbWeaponItems = BattleItemSystemClient:GetEquippedItems(BattleItemCategoryDef.HUMAN_WEAPON, PlayerSelf:GetServerInstanceId())
    -- for nSlotIndex, tbWeaponItem in pairs(tbWeaponItems) do
    --     nInstanceId = tbWeaponItem:GetInstanceId()
    --     tbWeapon = Component:FindWeaponById(nInstanceId)
    --     if(tbWeapon == nil) then
    --         tbWeapon = Component:OnWeaponAdded(nInstanceId, tbWeaponItem:GetTemplateId(), HumanWeaponHelper.GetWeaponSlot(tbWeaponItem))
    --     end

    --     tbAttachments = BattleItemSystemClient:GetEquippedItems(BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT, nInstanceId)
    --     tbWeapon:UpdateAttachments(tbAttachments)
    -- end

    local nSavedWeapon = HumanWeaponHelper.GetSavedCurrentWeaponFromOwner(PlayerSelf)
    if(nSavedWeapon == nil or nSavedWeapon == 0) then
        return
    end

    if(nSavedWeapon ~= 0) then
        -- 如果instanceid是投掷物，则创建他
        self:TryCreateThrownWeapon(PlayerSelf, nSavedWeapon, true)
    end

    -- 在设置当前武器
    nSavedWeapon = math.abs(nSavedWeapon)
    if(Component:FindWeaponById(nSavedWeapon) ~= nil) then
        Component:OnCurrentWeaponChanged(nSavedWeapon, true)
    end

end

local function OnActorCreated(self, Object)
    local nObjectType = Object.ObjectType
    if(nObjectType ~= GameObjectTypeDef.PlayerOther and nObjectType ~= GameObjectTypeDef.Npc) then
        return
    end
    if(not Object:IsHuman()) then
        return
    end

    -- 把其他玩家的武器刷一边
    HumanWeaponRepHelper.RefreshWeaponRepData(Object.HumanWeaponComponent)
end

function BattleHumanWeaponSystemNew_C:ResponseSetCurrentWeapon(nInstanceId, bForce)
    local PlayerSelf = GamePlayerSelfHelper:Get()

    -- 每次都先存到owner上，防止pawn还没创建包就下来的问题
    HumanWeaponHelper.SaveCurrentWeaponToOwner(PlayerSelf, nInstanceId)

    local Component = self:GetComponent(PlayerSelf)
    if(not Component) then
        return
    end

    if(Component:IsAttacking() and not Component:IsAttackPendingFinished(true)) then
        Component:CancelAttack()
    end

    if(nInstanceId ~= 0) then
        -- 如果instanceid是投掷物，则创建他
        self:TryCreateThrownWeapon(PlayerSelf, nInstanceId, true)
    end

    if(Component:CanChangeWeapon(nInstanceId)) then
        if(Component:GetCurrentWeaponInstanceId() ~= nInstanceId) then
            Component:OnCurrentWeaponChanged(nInstanceId, bForce)
        end
    else
        -- 这里cancelattack可能会延迟切状态，所以让component自己处理
        Component:SetPendingCurrentWeapon(nInstanceId)
    end
end

function BattleHumanWeaponSystemNew_C:ResponseSetThrowStateReset(bReset)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local Component = self:GetComponent(PlayerSelf)
    if Component then
        local tbCurrentWeapon = Component:GetCurrentWeapon()
        if tbCurrentWeapon and tbCurrentWeapon:IsType(HumanWeaponType.THROW) then
            tbCurrentWeapon:SetThrowIsReset(true)
        end
    end
end

local function OnCurrentWeaponChanged(self, nNewWeapon, nLastWeapon, nCharacterInstanceId)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if(PlayerSelf == nil or PlayerSelf:GetServerInstanceId() ~= nCharacterInstanceId) then
        return
    end

    if(nLastWeapon == 0) then
        return
    end

    local Component = PlayerSelf.HumanWeaponComponent
    local tbOldWeapon = Component:FindWeaponById(nLastWeapon)
    if tbOldWeapon == nil then
        return
    end

    if(tbOldWeapon:IsType(HumanWeaponType.THROW)) then
        local tbItem = BattleItemSystemHelper:GetItem(nLastWeapon, true)
        if(tbItem == nil) then
            -- 投掷物已经被删掉了，这里也把武器删了
            --logdebug("Remove thrown weapon without item")
            Component:RemoveWeapon(nLastWeapon)
        end
    end
end

--因为手雷属于背包，背包里的东西在进跳伞的时候只会删除数据，目前没有地方去删除手雷，隐藏的话会
--被从航线船发射之后的显示玩家接口又给显示出来，暂时Hack一下，再隐藏一遍
local function OnShowPlayerSelf(self)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local pUEActor = PlayerSelf.pUEActor
    if pUEActor and isvalidhandle(pUEActor) then
        local ChildActors = pUEActor:GetAttachedActors()
        for _, Child in ipairs(ChildActors) do
            if Child.WeaponType and Child.WeaponType == HumanWeaponBPType.Explosive then
                Child:SetActorHiddenInGame(true)
            end
        end
    end
end

function BattleHumanWeaponSystemNew_C:OnHumanCurrentWeaponChanged(nNewWeapon, nLastWeapon, nCharacterInstanceId)
    if (GlobalVariableSystem:IsServerLogic()) then
        BattleHumanWeaponSystemNew_C.super.OnHumanCurrentWeaponChanged(self, nNewWeapon, nLastWeapon, nCharacterInstanceId)
    end
    OnCurrentWeaponChanged(self, nNewWeapon, nLastWeapon, nCharacterInstanceId)
end

function BattleHumanWeaponSystemNew_C:OnThrowFinished(tbObject, tbWeapon)
    -- if(GlobalVariableSystem:IsServerLogic()) then
    --    BattleHumanWeaponSystemNew_C.super.OnThrowFinished(self, tbObject, tbWeapon)
    --    return
    -- end

    if(tbWeapon:CanThrowNext()) then
        -- 手雷还有剩余，什么都不做
        return
    end

    local nNextThrownItem = self:FindNextThrownWeapon(tbObject:GetServerInstanceId(),
        tbWeapon:GetInstanceId(), tbWeapon:GetTemplateId())
    if(nNextThrownItem == nil or nNextThrownItem == tbWeapon:GetInstanceId()) then
        -- 手雷无剩余，并且客户端查到的下一个手雷是空或者跟tbWeapon一样，那么认为无雷可扔了
        tbObject.HumanWeaponComponent:OnCurrentWeaponChanged(0, true)
    end
end

function BattleHumanWeaponSystemNew_C:Init()
    BattleHumanWeaponSystemNew_C.super.Init(self)

    local EventHelper = self.EventHelper
    --EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT, self, OnItemStackCountChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_READY, self, OnPlayerSelfReady)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, OnActorCreated)
    EventHelper:RegisterEvent(ClientEventDef.EV_PARACHUTE_SHOW_PLAYER, self, OnShowPlayerSelf)
    
    -- EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED, self, self.OnHumanCurrentWeaponChanged)

    return true
end

function BattleHumanWeaponSystemNew_C:Uninit()
    BattleHumanWeaponSystemNew_C.super.Uninit(self)
end

---------------------------------------------------------------------------------------------------
-- UI的口子都从这入
function BattleHumanWeaponSystemNew_C:RequestReload()
    local Component = self:GetComponent(GamePlayerSelfHelper:Get())
    if(Component == nil) then
        return false
    end
    return Component:Reload()
end

function BattleHumanWeaponSystemNew_C:RequestSetAim(bNewAim)
    local Component = self:GetComponent(GamePlayerSelfHelper:Get())
    if(Component == nil) then
        return false
    end
    if(not Component:SetAim(bNewAim)) then
        return false
    end

    if(GlobalVariableSystem:IsServerLogic()) then
        return true
    end

    local tbPacket = {
        weapon_id = Component:GetCurrentWeaponInstanceId(),
        enable = bNewAim,
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanWeaponSetAim, tbPacket)
    return true
end

local function CanChangeWeapon(Owner)
    local HumanMovementStateComponent = Owner.HumanMovementStateComponent
    local MovementState = HumanMovementStateComponent:GetCurrentState()
    if MovementState == HumanMovementStateType.Dying_State or MovementState == HumanMovementStateType.Jumping_SpeelWall then
        return false
    end
    local WeaponComponent = Owner.HumanWeaponComponent
    local nState = WeaponComponent:GetCurrentState()
    local tbCurrentWeapon = WeaponComponent:GetCurrentWeapon()
    local bThrowAttacking = tbCurrentWeapon ~= nil and tbCurrentWeapon:IsType(HumanWeaponType.THROW)
        and nState == HumanWeaponStateDef.ATTACKING
    --拉线的时候 可以吃药打断切空手
    if bThrowAttacking then
        return true
    end

    return nState ~= HumanWeaponStateDef.HOLDING
        -- and nState ~= HumanWeaponStateDef.RELOADING
        and nState ~= HumanWeaponStateDef.ATTACKING
end

function BattleHumanWeaponSystemNew_C:RequestSetCurrentWeapon(nInstanceId, bTemporary)
    local Component = self:GetComponent(GamePlayerSelfHelper:Get())
    if(Component == nil) then
        return false
    end

    if(Component:GetCurrentWeaponInstanceId() == nInstanceId) and Component:GetCurrentState() ~= HumanWeaponStateDef.UNHOLDING then
        return false
    end

    -- UNHOLDING 中允许换武器
    if(not CanChangeWeapon(GamePlayerSelfHelper:Get()) or not Component:CanChangeWeapon(nInstanceId)) then
        return false
    end

    if(GlobalVariableSystem:IsServerLogic()) then
        self:ResponseSetCurrentWeapon(nInstanceId, false)
    else
        local tbWeapon = Component:FindWeaponById(nInstanceId)
        if tbWeapon then
            log("[HumanWeapon] SendSetCurrentWeaponRequest templateId", tbWeapon.nTemplateId, "nInstanceId", nInstanceId)
        end
        HumanWeaponHelper.SendSetCurrentWeaponRequest(nInstanceId, bTemporary)
    end

    return true
end

function BattleHumanWeaponSystemNew_C:RequestUnlock(nLockCounter)
    local Component = self:GetComponent(GamePlayerSelfHelper:Get())
    if(Component == nil) then
        return
    end
    Component:Unlock(nLockCounter)

    if(GlobalVariableSystem:IsServerLogic()) then
        return
    end

    local tbPacket = {
        lock_counter = nLockCounter,
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_HumanWeaponUnlock, tbPacket)
end

function BattleHumanWeaponSystemNew_C:RequestStartAttack()
    local Component = self:GetComponent(GamePlayerSelfHelper:Get())
    if(Component == nil) then
        return
    end
    Component:StartAttack()
end

function BattleHumanWeaponSystemNew_C:RequestFinishAttack()
    local Component = self:GetComponent(GamePlayerSelfHelper:Get())
    if(Component == nil) then
        return
    end
    Component:FinishAttack()
end

function BattleHumanWeaponSystemNew_C:RequestCancelAttack()
    local Component = self:GetComponent(GamePlayerSelfHelper:Get())
    if(Component == nil) then
        return
    end
    Component:CancelAttack()
end

function BattleHumanWeaponSystemNew_C:RequestHoldThrownWeapon(nInstanceId)
    local Component = self:GetComponent(GamePlayerSelfHelper:Get())
    if(Component == nil) then
        return
    end

    if Component:IsAttacking() then
        return WeaponRequestFailReasonDef.IsAttacking
    end

    if not Component:IsTryToHoldSameThrowWeapon(nInstanceId) then
        HumanWeaponHelper.SendHoldThrownWeapon(nInstanceId)
    end

end

function BattleHumanWeaponSystemNew_C:RequestUnholdThrownWeapon()
    local Component = self:GetComponent(GamePlayerSelfHelper:Get())
    if(Component == nil) then
        return
    end

    HumanWeaponHelper.SendUnholdThrownWeapon()
    return
end

function BattleHumanWeaponSystemNew_C:RequestSelectThrownWeapon(nInstanceId)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local Component = self:GetComponent(PlayerSelf)
    if(Component == nil) then
        return
    end

    HumanWeaponHelper.SendSelectThrownWeapon(nInstanceId)
end

function BattleHumanWeaponSystemNew_C:RequestChangeThrowType(bHigh)
    local Component = self:GetComponent(GamePlayerSelfHelper:Get())
    if(Component == nil) then
        return false
    end

    Component:SetIsHighThrow(bHigh)
    local tbCurrentWeapon = Component:GetCurrentWeapon()
    if(tbCurrentWeapon == nil or not tbCurrentWeapon:IsType(HumanWeaponType.THROW)) then
        return false
    end

    return tbCurrentWeapon:SetThrowType(bHigh)
end

---------------------------------------------------------------------------------------------------
-- 其他接口

-- 这口子为恢复ui用的
function BattleHumanWeaponSystemNew_C:SaveThrownWeaponInfo(nTemplateId)
    self.nSavedThrownWeaponTemplateId = nTemplateId
end

function BattleHumanWeaponSystemNew_C:GetSavedThrownWeaponInfo()
    return self.nSavedThrownWeaponTemplateId
end

return BattleHumanWeaponSystemNew_C()