local luaclass = require("luaclass")
local BattleHumanWeaponSystemNew = luaclass("BattleHumanWeaponSystemNew")

--local Proto = require("DungeonCommonProtoNames")
--local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local SelfEventHelper = require("SelfEventHelper")
local HumanWeaponHelper = require("HumanWeaponHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local HumanWeaponMisc = require("HumanWeaponMisc")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")

--local EMPTY_TABLE = {}
local HumanWeaponType = HumanWeaponMisc.Type
local ABS = math.abs

BattleHumanWeaponSystemNew.EventHelper = nil
BattleHumanWeaponSystemNew.bExchangingWeapon = false
BattleHumanWeaponSystemNew.bNeedCheckCurrentWeapon = false

----------------------------------------------------------------------------------------
-- 通用
function BattleHumanWeaponSystemNew:GetCurrentWeaponWithCheck(tbObject, nInstanceId, bWithEmptyHand)
    if(tbObject == nil) then
        return nil
    end

    local Component = tbObject.HumanWeaponComponent
    if(Component == nil) then
        return nil
    end

    local tbCurrentWeapon = Component:GetCurrentWeapon(bWithEmptyHand)
    if(tbCurrentWeapon == nil or tbCurrentWeapon.nInstanceId ~= nInstanceId) then
        return nil
    end

    return tbCurrentWeapon
end

function BattleHumanWeaponSystemNew:GetComponentWithCheck(tbObject, nInstanceId, bWithEmptyHand)
    local Component = self:GetComponent(tbObject)
    if(Component == nil) then
        return nil
    end
    local tbCurrentWeapon = Component:GetCurrentWeapon(bWithEmptyHand)
    if(tbCurrentWeapon == nil or tbCurrentWeapon.nInstanceId ~= nInstanceId) then
        return nil
    end
    return Component
end

function BattleHumanWeaponSystemNew:GetComponent(tbObject)
    return tbObject ~= nil and tbObject.HumanWeaponComponent or nil
end

function BattleHumanWeaponSystemNew:Reload(tbObject, nInstanceId, nTime)
    local Component = self:GetComponentWithCheck(tbObject, nInstanceId)
    if(Component == nil) then
        return
    end
    Component:Reload(nTime)
end

function BattleHumanWeaponSystemNew:CancelReload(tbObject, nInstanceId)
    local Component = self:GetComponentWithCheck(tbObject, nInstanceId)
    if(Component == nil) then
        return
    end
    Component:CancelReload()
end

function BattleHumanWeaponSystemNew:SetAim(tbObject, nInstanceId, bEnable)
    local Component = self:GetComponentWithCheck(tbObject, nInstanceId)
    if(Component == nil) then
        return
    end
    Component:SetAim(bEnable)
end

function BattleHumanWeaponSystemNew:SetCurrentWeapon(tbObject, nInstanceId, bForce, bTemporary)
    local Component = self:GetComponent(tbObject)
    if(Component == nil) then
        return
    end
    Component:SetCurrentWeapon(nInstanceId, bForce, bTemporary)
end

function BattleHumanWeaponSystemNew:Unlock(tbObject, nLockCounter)
    local Component = self:GetComponent(tbObject)
    if(Component == nil) then
        return
    end
    Component:Unlock(nLockCounter)
end

function BattleHumanWeaponSystemNew:OnAttackStart(tbObject)
    local Component = self:GetComponent(tbObject)
    if(Component == nil) then
        return
    end
    Component:OnAttackStart()
end

function BattleHumanWeaponSystemNew:OnAttackEnd(tbObject)
    local Component = self:GetComponent(tbObject)
    if(Component == nil) then
        return
    end
    Component:OnAttackEnd()
end

----------------------------------------------------------------------------------------
-- 普通枪械攻击
function BattleHumanWeaponSystemNew:RequestGunAttackOnce(tbObject, nInstanceId, nTakerId, StartPos, EndPos, nHitBodyType, nProjectileIndex)
    logdebug("lz attack once 7")
    local tbCurrentWeapon = self:GetCurrentWeaponWithCheck(tbObject, nInstanceId)
    if(tbCurrentWeapon == nil or not tbCurrentWeapon:IsType(HumanWeaponType.GUN)) then
        return
    end
    tbCurrentWeapon:AttackOnceInServer(nTakerId, StartPos, EndPos, nHitBodyType, nil--[[szDamageType]], nProjectileIndex)
end

function BattleHumanWeaponSystemNew:RequestGunAttackMulti(tbObject, nInstanceId, tbTakers, StartPos, tbAttackEnds, tbHitBodyTypes, tbMissEnds, tbIndexes)
    local tbCurrentWeapon = self:GetCurrentWeaponWithCheck(tbObject, nInstanceId)
    if(tbCurrentWeapon == nil or not tbCurrentWeapon:IsType(HumanWeaponType.GUN)) then
        return
    end
    tbCurrentWeapon:AttackMultiInServer(tbTakers, StartPos, tbAttackEnds, tbHitBodyTypes, tbMissEnds, nil--[[tbOriginalHitTypes]], tbIndexes)
end

function BattleHumanWeaponSystemNew:RouteGunAttack(tbObject, nInstanceId, tbNotifies)
    local tbCurrentWeapon = self:GetCurrentWeaponWithCheck(tbObject, nInstanceId)
    if(tbCurrentWeapon == nil or not tbCurrentWeapon:IsType(HumanWeaponType.GUN)) then
        return
    end
    tbCurrentWeapon:RouteAttack(tbNotifies)
end

function BattleHumanWeaponSystemNew:RouteProjectGunAttack(tbObject, nInstanceId, tbNotifies)
    local tbCurrentWeapon = self:GetCurrentWeaponWithCheck(tbObject, nInstanceId)
    if(tbCurrentWeapon == nil or not tbCurrentWeapon:IsType(HumanWeaponType.PROJECTILE)) then
        return
    end
    tbCurrentWeapon:RouteProjectAttack(tbNotifies)
end
function BattleHumanWeaponSystemNew:BowPreAttack(tbObject, nInstanceId)
    local tbCurrentWeapon = self:GetCurrentWeaponWithCheck(tbObject, nInstanceId)
    if(tbCurrentWeapon == nil or not tbCurrentWeapon:IsType(HumanWeaponType.PROJECTILE)) then
        return
    end
    tbCurrentWeapon:BowPreAttack()
end

function BattleHumanWeaponSystemNew:RequestAttackSubstate(tbObject, nInstanceId, nSubstate)
    local tbCurrentWeapon = self:GetCurrentWeaponWithCheck(tbObject, nInstanceId)
    if tbCurrentWeapon == nil then
        return
    end
    tbCurrentWeapon:SetRepAttackSubState(nSubstate)
end

function BattleHumanWeaponSystemNew:OnCancelBowAttack(tbObject, nInstanceId)
    local tbCurrentWeapon = self:GetCurrentWeaponWithCheck(tbObject, nInstanceId)
    if(tbCurrentWeapon == nil or not tbCurrentWeapon:IsType(HumanWeaponType.PROJECTILE) or tbCurrentWeapon.OnCancel == nil) then
        return
    end
    tbCurrentWeapon:OnCancel()
end

----------------------------------------------------------------------------------------
function BattleHumanWeaponSystemNew:RequestAttack(tbObject, nInstanceId, tbTakerIds)
    local tbCurrentWeapon = self:GetCurrentWeaponWithCheck(tbObject, nInstanceId, true)
    if(tbCurrentWeapon == nil) then
        return
    end
    tbCurrentWeapon:AttackInServer(tbTakerIds)
end

function BattleHumanWeaponSystemNew:RouteMeleeAttack(tbObject, nInstanceId, nMontageIndex, bJumping, StartPos, Yaw)
    local tbCurrentWeapon = self:GetCurrentWeaponWithCheck(tbObject, nInstanceId, true)
    if(tbCurrentWeapon == nil) then
        return
    end
    tbCurrentWeapon:RouteAttack(nMontageIndex, bJumping, false, StartPos, Yaw)
end

----------------------------------------------------------------------------------------
-- 投掷物
local function GetThrownWeapon(self, tbObject, nInstanceId)
    local tbCurrentWeapon = self:GetCurrentWeaponWithCheck(tbObject, nInstanceId)
    if(tbCurrentWeapon == nil) then
        return nil
    end
    if(not tbCurrentWeapon:IsType(HumanWeaponType.THROW)) then
        return nil
    end
    return tbCurrentWeapon
end

function BattleHumanWeaponSystemNew:TryCreateThrownWeapon(tbObject, nInstanceId, bDestoryOld)
    local Component = tbObject.HumanWeaponComponent
    assert(Component)

    nInstanceId = ABS(nInstanceId)
    local tbItem = BattleItemSystemHelper:GetItem(nInstanceId, not GlobalVariableSystem:IsServerLogic())
    if(not tbItem or tbItem:GetCategory() ~= BattleItemCategoryDef.HUMAN_THROWN_ITEM) then
        log("[TryCreateThrownWeapon] but item nil")
        return nil
    end

    local tbThrownWeapon = Component:FindWeaponByType(HumanWeaponType.THROW)
    if(tbThrownWeapon and tbThrownWeapon:GetInstanceId() ~= nInstanceId) then
        -- 先把老的删了
        if(bDestoryOld) then
            Component:RemoveWeapon(tbThrownWeapon:GetInstanceId())
            tbThrownWeapon = nil
        end
    end

    if(tbThrownWeapon == nil) then
        -- 没有时创建weapon
        tbThrownWeapon = Component:AddWeapon(nInstanceId, tbItem:GetTemplateId(), HumanWeaponHelper.GetWeaponSlot(tbItem))
        log("[TryCreateThrownWeapon] but create fail? ", tbThrownWeapon == nil)
    end
    log("[TryCreateThrownWeapon] create is nil?", tbThrownWeapon == nil)
    return tbThrownWeapon
end

function BattleHumanWeaponSystemNew:TryDestroyAllThrownWeapon(tbObject)
    local Component = self:GetComponent(tbObject)
    if(Component == nil) then
        return false
    end

    while(true) do
        local tbThrownWeapon = Component:FindWeaponByType(HumanWeaponType.THROW)
        if(tbThrownWeapon == nil) then
            break
        end

        Component:RemoveWeapon(tbThrownWeapon:GetInstanceId())
    end
    return true
end

function BattleHumanWeaponSystemNew:HoldNewThrownWeapon(tbObject, nInstanceId, bForce)
    local Component = tbObject.HumanWeaponComponent
    assert(Component)

    if(self:TryCreateThrownWeapon(tbObject, nInstanceId, true) ~= nil) then
        --logdebug("TryCreateThrownWeapon and SetCurrentWeapon", nInstanceId)
        Component:SetCurrentWeapon(nInstanceId, bForce)
    end
end

function BattleHumanWeaponSystemNew:OnHoldThrownWeapon(tbObject, nInstanceId)
    local Component = self:GetComponent(tbObject)
    if(Component == nil) then
        return
    end

    local bForce = false
    local tbCurrentWeapon = Component:GetCurrentWeapon()
    if(tbCurrentWeapon ~= nil) then
        if(tbCurrentWeapon:GetInstanceId() == nInstanceId) then
            return
        elseif(tbCurrentWeapon:IsType(HumanWeaponType.THROW)) then
            -- 如果是投掷物切投掷物，那么直接切
            bForce = true
        else
            -- 切投掷物前先记下之前的武器，扔完所有投掷物后会尝试恢复
            Component:SaveCurrentWeapon()
        end
    end

    self:HoldNewThrownWeapon(tbObject, nInstanceId, bForce)
end

function BattleHumanWeaponSystemNew:OnUnholdThrownWeapon(tbObject)
    local Component = self:GetComponent(tbObject)
    if(Component == nil) then
        return
    end

    local tbCurrentWeapon = Component:GetCurrentWeapon()
    if(tbCurrentWeapon and tbCurrentWeapon:IsType(HumanWeaponType.THROW)) then
        if Component:IsAttacking() then
            self:OnCancelThrow(tbObject, tbCurrentWeapon.nInstanceId)
        end
    end
    -- 因为ui中要显示，这里就不删了，否则客户端也得删
    --if(self:TryDestroyAllThrownWeapon(tbObject)) then
        Component:SetCurrentWeapon(0)
    --end
end

-- function BattleHumanWeaponSystemNew:OnSelectThrownWeapon(tbObject, nInstanceId)
--     local Component = self:GetComponent(tbObject)
--     if(Component == nil) then
--         return
--     end

--     self:HoldNewThrownWeapon(tbObject, nInstanceId, true)
-- end

function BattleHumanWeaponSystemNew:OnChangeThrowType(tbObject, nInstanceId, bHigh)
    local tbCurrentWeapon = GetThrownWeapon(self, tbObject, nInstanceId)
    if(tbCurrentWeapon == nil or not tbCurrentWeapon:IsType(HumanWeaponType.THROW)) then
        return
    end

    tbCurrentWeapon:OnSetThrowType(bHigh)
end

function BattleHumanWeaponSystemNew:OnCancelThrow(tbObject, nInstanceId)
    local tbCurrentWeapon = GetThrownWeapon(self, tbObject, nInstanceId)
    if(tbCurrentWeapon == nil or not tbCurrentWeapon:IsType(HumanWeaponType.THROW)) then
        return
    end

    tbCurrentWeapon:OnCancel()
end

function BattleHumanWeaponSystemNew:FindNextThrownWeapon(nCharacterInstanceId, nItemInstanceId, nItemTemplateId)
    local bClient = not GlobalVariableSystem:IsServerLogic()
    local tbItem = BattleItemSystemHelper:GetItem(nItemInstanceId, bClient)

    --判断是否需要重新选一个投掷物
    local bNeedReselectItem = false
    if tbItem == nil then
        bNeedReselectItem = true
    else
        -- nItemTemplateId = tbItem:GetTemplateId()
        local tbCharacter = tbItem:GetOwnerCharacter()
        if tbCharacter == nil then
            bNeedReselectItem = true
        elseif tbCharacter:GetServerInstanceId() ~= nCharacterInstanceId then
            bNeedReselectItem = true
        end
        local nCount = tbItem:GetStackCount()
        if nCount == 0 then
            bNeedReselectItem = true
        end
    end
    -- 获取要hold的投掷物id
    local nToHoldThrowItemId = nil
    if bNeedReselectItem then
        local bHasSameTemplateItem = false
        if nItemTemplateId ~= nil then
            local nCount = BattleItemSystemHelper:GetUnequippedItemCount(nCharacterInstanceId, nItemTemplateId, bClient)
            if nCount > 0 then
                bHasSameTemplateItem = true
            end
        end
        if bHasSameTemplateItem then -- 有相同template的直接选择相同template的最小一摞
            nToHoldThrowItemId = BattleItemSystemHelper:GetUnequippedLeastStackCountInstanceId(nCharacterInstanceId, nItemTemplateId, bClient)
        else
            local tbItems = BattleItemSystemHelper:GetUnequippedItemsByCategory(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_THROWN_ITEM, bClient)
            if tbItems ~= nil and #tbItems > 0 then
                table.sort(tbItems, function (tbItem1, tbItem2) return tbItem1:GetPriorty() < tbItem2:GetPriorty() end)
                local nTemplateId = tbItems[1]:GetTemplateId()
                nToHoldThrowItemId = BattleItemSystemHelper:GetUnequippedLeastStackCountInstanceId(nCharacterInstanceId, nTemplateId, bClient)
            end
        end
    else
        nToHoldThrowItemId = nItemInstanceId
    end

    return nToHoldThrowItemId
end

function BattleHumanWeaponSystemNew:OnThrow(tbObject, nInstanceId, tbPos, nTime)
    assert(GlobalVariableSystem:IsServerLogic())
    local tbCurrentWeapon = GetThrownWeapon(self, tbObject, nInstanceId)
    if(tbCurrentWeapon == nil) then
        return
    end
    tbCurrentWeapon:OnThrow(tbPos, false, nTime)
end

function BattleHumanWeaponSystemNew:BeginThrow(tbObject, nInstanceId)
    assert(GlobalVariableSystem:IsServerLogic())
    local tbCurrentWeapon = GetThrownWeapon(self, tbObject, nInstanceId)
    if(tbCurrentWeapon == nil) then
        return
    end
    tbCurrentWeapon:BeginThrow()
end

local function ThrowFinished(self, tbObject, tbWeapon)
    -- 这函数客户端也会执行，理论上不执行也行
    local nWeaponId = tbWeapon:GetInstanceId()

    local nNextWeapon = self:FindNextThrownWeapon(tbObject:GetServerInstanceId(), nWeaponId, tbWeapon:GetTemplateId())
    if(nNextWeapon == nil) then
        local Component = tbWeapon.OwnerComponent
        local nSavedWeapon = Component:GetSavedWeaponIntanceId()
        if(Component:FindWeaponById(nSavedWeapon) ~= nil) then
            -- 都扔完了，把以前的武器恢复了
            Component:SetCurrentWeapon(nSavedWeapon)
        else
            -- 以前的武器找不到了，那么恢复空手
            Component:SetCurrentWeapon(0)
        end
    --相同的id ，代表同类型的多个的下一个，不同id，代表其他投掷物
    else--if(nNextWeapon ~= nWeaponId) then
        -- 如果扔完了，尝试拿下一个手雷，没扔完什么都不变
        self:HoldNewThrownWeapon(tbObject, nNextWeapon, true)
    end
end

function BattleHumanWeaponSystemNew:StandaloneOnThrowFinished(tbObject, tbWeapon)
    ThrowFinished(self, tbObject, tbWeapon)
end

function BattleHumanWeaponSystemNew:OnThrowFinished(tbObject, tbWeapon)
    ThrowFinished(self, tbObject, tbWeapon)
end

function BattleHumanWeaponSystemNew:OnReady(tbObject, nInstanceId, bHigh)
    local tbCurrentWeapon = GetThrownWeapon(self, tbObject, nInstanceId)
    if(tbCurrentWeapon == nil) then
        return
    end
    tbCurrentWeapon:OnReady(bHigh)
end

function BattleHumanWeaponSystemNew:OnExplodeBegin(tbObject, nInstanceId)
    local tbCurrentWeapon = GetThrownWeapon(self, tbObject, nInstanceId)
    if(tbCurrentWeapon == nil) then
        return
    end
    tbCurrentWeapon:OnExplodeBegin()
end

function BattleHumanWeaponSystemNew:DualWieldAttack(tbObject, nInstanceId, bLeftWeapon)
    local tbCurrentWeapon = self:GetCurrentWeaponWithCheck(tbObject, nInstanceId)
    if(tbCurrentWeapon == nil or not tbCurrentWeapon:IsType(HumanWeaponType.DUAL_WIELD)) then
        return
    end
    tbCurrentWeapon:DualWieldAttack(bLeftWeapon)
end

----------------------------------------------------------------------------------------
-- Event处理
local function GetWeaponComponent(tbItem)
    local Owner = tbItem:GetOwnerCharacter()
    return Owner.HumanWeaponComponent
end

function BattleHumanWeaponSystemNew:IsWeapon(tbItem)
    local nCategory = tbItem:GetTemplate().nCategory
    return nCategory == BattleItemCategoryDef.HUMAN_WEAPON
        or nCategory == BattleItemCategoryDef.HUMAN_THROWN_ITEM
end

local function VerifyCurrentWeapon(self, tbItem)
    if(not self.bNeedCheckCurrentWeapon) then
        return
    end

    self.bNeedCheckCurrentWeapon = false
    local Component = GetWeaponComponent(tbItem)
    if(Component and Component:HasNoWeapon()) then
        if not Component.bTemporaryWeapon or not Component:FindWeaponById(Component.nLastWeapon) then 
            Component:SetCurrentWeapon(tbItem:GetInstanceId(), true)
        end
    end
end

local function OnItemEquipBulletWhenAddedFirstTime(self, tbItem)
    if(not self:IsWeapon(tbItem)) then
        return
    end

    VerifyCurrentWeapon(self, tbItem)
end

function BattleHumanWeaponSystemNew:OnItemAdded(tbItem)
    if(not GlobalVariableSystem:IsServerLogic()) then
        return
    end

    if(not self:IsWeapon(tbItem)) then
        return
    end

    if(tbItem:GetTemplate().nCategory ~= BattleItemCategoryDef.HUMAN_THROWN_ITEM) then
        -- local Component = GetWeaponComponent(tbItem)
        -- if(Component and Component:HasNoWeapon()) then
        --     --logdebug("Hold throw when no weapon", tbItem:GetInstanceId())
        --     self:HoldNewThrownWeapon(Component.Owner, tbItem:GetInstanceId(), true)
        -- end
    -- else
        -- 放到这里是为了等additem的包发给客户端后在发setcurrentweapon
        -- 如果是枪是initialItem，那么等OnItemEquipBulletWhenAddedFirstTime到了在设currentweapon，这样到客户端就不用reload了
        if(tbItem.NeedEquipBulletWhenAddedFirstTime == nil or not tbItem:NeedEquipBulletWhenAddedFirstTime()) then
            VerifyCurrentWeapon(self, tbItem)
        end
    end
end

--处理丢弃，投掷物丢弃之后没有切回空手
function BattleHumanWeaponSystemNew:ThrowAwayItemFinished(nCharacterInstanceId, nItemInstanceId, nItemTemplateId, nCount)
    local Object = GameObjectSystem:FindByInstanceId(nCharacterInstanceId)
    if(not Object) then
        return
    end

    local Component = Object.HumanWeaponComponent
    if(not Component) then
        return
    end

    local tbItem = BattleItemSystemHelper:GetItem(nItemInstanceId)
    local tbTemplate = tbItem:GetTemplate()
    local nCategory = tbTemplate.nCategory
    if nCategory == BattleItemCategoryDef.HUMAN_THROWN_ITEM then
        if(Component:GetCurrentWeaponInstanceId() ~= 0) then
            local tbCurrentWeapon = Component:GetCurrentWeapon()
            if(tbCurrentWeapon == nil or tbCurrentWeapon:GetInstanceId() == nItemInstanceId) then
                Component:SetCurrentWeapon(0, true)
            end
        end
    end
end

function BattleHumanWeaponSystemNew:OnItemRemoved(nItemInstanceId, _, nCharacterInstanceId)
    local Object = GameObjectSystem:FindByInstanceId(nCharacterInstanceId)
    if(not Object) then
        return
    end

    local Component = Object.HumanWeaponComponent
    if(not Component) then
        return
    end

    local tbWeapon = Component:FindWeaponById(nItemInstanceId)
    if(tbWeapon and tbWeapon:IsType(HumanWeaponType.THROW)) then
        -- 投掷中的武器会在OnThrowFinish中处理当前武器
        if(not tbWeapon:IsThrowing()) then
            Component:RemoveWeapon(nItemInstanceId)
            --logdebug("Remove throw", nItemInstanceId)
        --else
            --logdebug("Is throwing, delay remove weapon")
        end
        return
    end

    if(Component:GetCurrentWeaponInstanceId() ~= 0) then
        local tbCurrentWeapon = Component:GetCurrentWeapon()
        if(tbCurrentWeapon == nil or tbCurrentWeapon:GetInstanceId() == nItemInstanceId) then
            --logdebug("ResetWeapon", Component, nCharacterInstanceId)
            Component:SetCurrentWeapon(0, true)
        end
    end
end

function BattleHumanWeaponSystemNew:OnItemEquiped(_, tbItem)
    if(not self:IsWeapon(tbItem)) then
        return
    end

    local nInstanceId = tbItem:GetInstanceId()
    local Component = GetWeaponComponent(tbItem)
    if(Component) then
        if(Component:FindWeaponById(nInstanceId) == nil) then
            Component:AddWeapon(nInstanceId, tbItem:GetTemplateId(), HumanWeaponHelper.GetWeaponSlot(tbItem))
        end
        self.bNeedCheckCurrentWeapon = not self.bExchangingWeapon
    end
end


function BattleHumanWeaponSystemNew:OnItemUnequiped(_, tbItem)
    if(not self:IsWeapon(tbItem)) then
        return
    end

    local nInstanceId = tbItem:GetInstanceId()
    local Component = GetWeaponComponent(tbItem)
    if(Component and Component:FindWeaponById(nInstanceId) ~= nil) then
        Component:RemoveWeapon(nInstanceId)
    end
end

function BattleHumanWeaponSystemNew:OnPawnDead(tbDeader)
    if tbDeader and tbDeader:IsHuman()  then
        local HumanWeaponComponent = tbDeader.HumanWeaponComponent
        if(HumanWeaponComponent and HumanWeaponComponent:FindWeaponByType(HumanWeaponType.THROW) ~= nil) then
            local tbThrowWeapon = HumanWeaponComponent:FindWeaponByType(HumanWeaponType.THROW)
            HumanWeaponComponent:RemoveWeapon(tbThrowWeapon.nInstanceId)
        end
    end
end

function BattleHumanWeaponSystemNew:OnAttachmentChanged(Owner, tbItem, tbAttachments)
    local Component = Owner.HumanWeaponComponent
    if(Component == nil) then
        return
    end

    local nInstanceId = tbItem:GetInstanceId()
    local tbEquipWeapon = Component:FindWeaponById(nInstanceId)
    if tbEquipWeapon then
        tbEquipWeapon:UpdateAttachments(tbAttachments)
    end
end

function BattleHumanWeaponSystemNew:IsCurrentWeapon(tbItem)
    local Owner = tbItem:GetOwnerCharacter()
    if(Owner == nil) then
        return false
    end

    local Component = Owner.HumanWeaponComponent
    if(Component) then
        return Component:GetCurrentWeaponInstanceId() == tbItem:GetInstanceId()
    end

    local nCurrentWeapon = HumanWeaponHelper.GetSavedCurrentWeaponFromOwner(Owner)
    return nCurrentWeapon == tbItem:GetInstanceId()
end

function BattleHumanWeaponSystemNew:GetCurrentWeaponInstanceId(Object)
    assert(Object)
    local Component = Object.HumanWeaponComponent
    if(Component) then
        return Component:GetCurrentWeaponInstanceId()
    else
        return HumanWeaponHelper.GetSavedCurrentWeaponFromOwner(Object)
    end
end

function BattleHumanWeaponSystemNew:OnStartExchange(Item1, Item2)
    self.bExchangingWeapon = true
end

function BattleHumanWeaponSystemNew:OnFinishExchange(Item1, Item2)
    -- 服务器不做任何事，毕竟instanceid没变，客户端会处理重新绑定的问题
    self.bExchangingWeapon = false
end

local function OnEndChangeDisplay(self, tbCharacter)
    self.bNeedCheckCurrentWeapon = false

    if not tbCharacter:IsHuman() then
        return
    end

    local nCurrentWeapon = HumanWeaponHelper.GetSavedCurrentWeaponFromOwner(tbCharacter)
    if(nCurrentWeapon == nil or nCurrentWeapon == 0) then
        return
    end

    -- 当前武器肯定是空，这样吧以前存的就冲掉了，防止以后有人用时出问题
    self:SaveCurrentWeaponToOwner(tbCharacter)

    local WeaponComponent = tbCharacter.HumanWeaponComponent
    local nCharacterInstanceId = tbCharacter:GetServerInstanceId()
    assert(WeaponComponent)

    local tbItem = BattleItemSystemHelper:GetItem(nCurrentWeapon)
    if not tbItem or tbItem:GetOwnerCharacterInstanceId() ~= nCharacterInstanceId then
        WeaponComponent:SetCurrentWeapon(0, true)
        return
    end

    if tbItem:GetCategory() == BattleItemCategoryDef.HUMAN_THROWN_ITEM then
        self:OnHoldThrownWeapon(tbCharacter, tbItem:GetInstanceId())
        return
    end
    WeaponComponent:ReloadAllWeaponOnChangeToHuman()
    WeaponComponent:SetCurrentWeapon(nCurrentWeapon, true)
end

function BattleHumanWeaponSystemNew:SaveCurrentWeaponToOwner(Object)
    local Component = Object.HumanWeaponComponent
    assert(Component)
    HumanWeaponHelper.SaveCurrentWeaponToOwner(Object, Component:GetCurrentWeaponInstanceId())
end

function BattleHumanWeaponSystemNew:GetSavedCurrentWeaponFromOwner(Owner)
    return HumanWeaponHelper.GetSavedCurrentWeaponFromOwner(Owner)
end


function BattleHumanWeaponSystemNew:OnHumanCurrentWeaponChanged(nNewWeapon, nLastWeapon, nPlayerInstanceId)
    local tbAttachments = BattleItemSystemHelper:GetEquippedItems(nPlayerInstanceId, BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT, nLastWeapon)
    for _, tbAttachment in pairs(tbAttachments) do
        tbAttachment:Deactivate()
    end

    tbAttachments = BattleItemSystemHelper:GetEquippedItems(nPlayerInstanceId, BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT, nNewWeapon)
    for _, tbAttachment in pairs(tbAttachments) do
        tbAttachment:Activate()
    end
end

local function OnWeaponAttachmentEquipped(self, nPlayerInstanceId, tbAttachmentEquipped)
    local nWeaponInstanceId = tbAttachmentEquipped.tbStorageLocation.nOwnerInstanceId
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    local tbHumanWeaponItem = BattleItemSystemServer:GetItem(nWeaponInstanceId)
    if self:IsCurrentWeapon(tbHumanWeaponItem) then
        tbAttachmentEquipped:Activate()
    end
end

local function OnWeaponAttachmentUnequipped(self, nPlayerInstanceId, tbAttachmentUnequipped)
    local nWeaponInstanceId = tbAttachmentUnequipped.tbStorageLocation.nOwnerInstanceId
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    local tbHumanWeaponItem = BattleItemSystemServer:GetItem(nWeaponInstanceId)
    if self:IsCurrentWeapon(tbHumanWeaponItem) then
        tbAttachmentUnequipped:Deactivate()
    end
end

----------------------------------------------------------------------------------------
function BattleHumanWeaponSystemNew:Init()
    HumanWeaponHelper.Init()

    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper

    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_THROW_FINISHED, self, self.OnThrowFinished)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_STANDALONE_THROW_FINISHED, self, self.StandaloneOnThrowFinished)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED, self, self.OnHumanCurrentWeaponChanged)


    if(GlobalVariableSystem:IsServerLogic()) then
        EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_EQUIP_BULLET_WHEN_ADDED_FIRST_TIME_SERVER, self, OnItemEquipBulletWhenAddedFirstTime)
        EventHelper:RegisterEvent(CommonEventDef.EV_END_CHANGEDISPLAY, self, OnEndChangeDisplay)
        EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_ADD_SERVER, self, self.OnItemAdded)
        EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_REMOVE_SERVER, self, self.OnItemRemoved)
        EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_THROW_AWAY_ITEM_FINISH_SERVER, self, self.ThrowAwayItemFinished)
        EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_ON_EQUIPED_SERVER, self, self.OnItemEquiped)
        EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_ON_UNEQUIPED_SERVER, self, self.OnItemUnequiped)
        EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_ATTACHMENT_CHANGED_SERVER, self, self.OnAttachmentChanged)
        EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
        EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_ATTACHMENT_ON_EQUIPED_SERVER, self, OnWeaponAttachmentEquipped)
        EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_ATTACHMENT_ON_UNEQUIPED_SERVER, self, OnWeaponAttachmentUnequipped)
    else
        local ClientEventDef = require("ClientEventDef")
        EventHelper:RegisterEvent(ClientEventDef.EV_BEFORE_BATTLE_ITEM_EXCHANGE_STORAGE_LOCATION_CLIENT, self, self.OnStartExchange)
        EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_EXCHANGE_STORAGE_LOCATION_CLIENT, self, self.OnFinishExchange)
        EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_WEAPON_ON_EQUIPED_CLIENT, self, self.OnItemEquiped)
        EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_WEAPON_ON_UNEQUIPED_CLIENT, self, self.OnItemUnequiped)
        EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_WEAPON_ATTACHMENT_CHANGED_CLIENT, self, self.OnAttachmentChanged)
    end

    return true
end

function BattleHumanWeaponSystemNew:Uninit()
    self.EventHelper:UnregisterAll()
end

return BattleHumanWeaponSystemNew()