-- 所有客户端和服务器replicate相关的回调和绑定都写这，省的武器改了接口或者数据结构导致component改来改去
local HumanWeaponRepHelper = {}

local HumanWeaponMisc = require("HumanWeaponMisc")
local PropName = require("PropName")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
--local GameObjectTypeDef = require("GameObjectTypeDef")

local SlotDef = HumanWeaponMisc.SlotDef
--local IsReplicatedToOwner = PropName.IsReplicatedToOwner
local HumanWeaponType = HumanWeaponMisc.Type

local NO_WEAPON = 0
local INVALID_TEMPLATE_ID = 0
local INVALID_FASHION_ID = 0
--local EMPTY_TABLE = {}


local SlotToTemplatePropName = {
    [SlotDef.PRIMARY]   = PropName.nHumanWeaponPrimaryTemplateId,
    [SlotDef.SECONDARY] = PropName.nHumanWeaponSecondaryTemplateId,
    [SlotDef.MELEE]     = PropName.nHumanWeaponMeleeTemplateId,
    [SlotDef.THROW]     = PropName.nHumanWeaponThrowTemplateId,
}

local SlotToInstancePropName = {
    [SlotDef.PRIMARY]   = PropName.nHumanWeaponPrimaryInstanceId,
    [SlotDef.SECONDARY] = PropName.nHumanWeaponSecondaryInstanceId,
    [SlotDef.MELEE]     = PropName.nHumanWeaponMeleeInstanceId,
    [SlotDef.THROW]     = PropName.nHumanWeaponThrowInstanceId,
}

local SlotToFashionPropName = {
    [SlotDef.PRIMARY]   = PropName.nHumanWeaponPrimaryFashionId,
    [SlotDef.SECONDARY] = PropName.nHumanWeaponSecondaryFashionId,
}


local InstanceIdPropNames = {
    [PropName.nHumanWeaponPrimaryInstanceId] = true,
    [PropName.nHumanWeaponSecondaryInstanceId] = true,
    [PropName.nHumanWeaponMeleeInstanceId] = true,
    [PropName.nHumanWeaponThrowInstanceId] = true,
}

local TempOwnerComponent, rTempComponent, bTempNeedRepNotify, bTempDedicatedServer, bTempStandalone
--local bTempClientSelf
local nTempMaxRepIndex = 0

local tbPostNotifyProperties = {}
local tbPropNameToRepIndex = {}
local tbRepIndexToRepFunc = {}
local tbRepIndexToCustomParam = {}
local tbInstanceIdRepInfo = nil
local nCurrentWeaponRepIndex = nil
local nCallRepStartIndex = nil

local OnPostRepNotify

local function CallRepFunc(OwnerComponent, nRepIndex, rProperty)
    local fnRepCallback = tbRepIndexToRepFunc[nRepIndex]
    if(fnRepCallback) then
        fnRepCallback(OwnerComponent, rProperty:Get(), tbRepIndexToCustomParam[nRepIndex])
    end
end

-- local function GetDebugInfo(tbInfo)
--     local Value = tbInfo:Get()
--     local szValue
--     if(Value == nil) then
--         szValue = "nil"
--     elseif(type(Value) == 'table') then
--         szValue = require("dkjson").encode(Value)
--     else
--         szValue = tostring(Value)
--     end
--     -- if(GetValueFromComponent and GWithEditor) then
--     --     local TempValue = GetValueFromComponent(tbInfo)
--     --     if(type(TempValue) == 'table') then
--     --         logdebug("C:", require("dkjson").encode(TempValue))
--     --         logdebug("L:", require("dkjson").encode(Value))
--     --     end
--     --     if(tbInfo._Owner.pRepComponent:IsValidProperty(tbInfo._nPropertyId)) then
--     --         assert(require("BaseUtil"):CheckEqual(GetValueFromComponent(tbInfo), Value))
--     --     end
--     -- end
--     return string.format("Replication Name: %s, Value: %s, PropertyId: %d, Type: %d",
--         tbInfo._szName,
--         szValue,
--         tbInfo._nPropertyId,
--         tbInfo._Type)
-- end

local function OnRepProperty(OwnerComponent, rProperty)
    local nRepIndex = tbPropNameToRepIndex[rProperty._nPropertyId]
    assert(nRepIndex ~= nil)

    -- log("OnRepProperty Player", OwnerComponent.Owner.szName, GetDebugInfo(rProperty))

    if(GlobalVariableSystem:IsServerLogic()) then
        CallRepFunc(OwnerComponent, nRepIndex, rProperty)
    else
        local tbDirtyRProperty = OwnerComponent.tbDirtyRProperty
        assert(tbDirtyRProperty)

        tbDirtyRProperty[nRepIndex] = rProperty
        tbDirtyRProperty.bDirty = true
    end
end

local function OnRepWeaponFunc(OwnerComponent, tbRepData, szWeaponRepFunc)
    local tbCurrentWeapon = OwnerComponent:GetCurrentWeapon(true)
    if(tbCurrentWeapon == nil) then
        -- 道具刚被删，但notify下来了
        return
    end

    local bWeaponChecked = true
    local nRepWeaponId = nil
    if(tbRepData ~= nil and type(tbRepData) == 'table') then
        nRepWeaponId = tbRepData.weapon_id
        if(nRepWeaponId ~= nil) then
            bWeaponChecked = nRepWeaponId == tbCurrentWeapon:GetInstanceId()
        end
    end

    --logdebug("OnRepWeaponFunc", szWeaponRepFunc, nRepWeaponId == tbCurrentWeapon.nInstanceId)
    if(bWeaponChecked) then
        local fnFunc = tbCurrentWeapon[szWeaponRepFunc]
        if(fnFunc) then
            fnFunc(tbCurrentWeapon, tbRepData)
        end
    -- else
        -- 这里感觉不打log也行吧
        -- logerror(string.format("OnRepWeaponFunc failed, weapon is invalid, client: %d, server: %d",
        --     tbCurrentWeapon.nInstanceId, nRepWeaponId ~= nil and nRepWeaponId or -1))
    end
end

local function BindRep(nProp, DefaultValue, OnRepFunc, CustomParam)
    -- RepSituation         Self    Others
    -- DedicatedServer      no      no
    -- DedicatedClient      some    all
    -- Standalone           some    all

    local fnOnRep
    if(bTempNeedRepNotify and not bTempDedicatedServer) then
        -- if(not bTempClientSelf or IsReplicatedToOwner(nProp)) then
            fnOnRep = OnRepProperty
        -- end
    end

    local rProperty = rTempComponent:BindMethod(nProp, DefaultValue, TempOwnerComponent, fnOnRep, bTempStandalone and fnOnRep ~= nil)

    if(bTempNeedRepNotify and tbPropNameToRepIndex[nProp] == nil) then
        nTempMaxRepIndex = nTempMaxRepIndex + 1
        tbPropNameToRepIndex[nProp] = nTempMaxRepIndex
        tbRepIndexToRepFunc[nTempMaxRepIndex] = OnRepFunc
        tbRepIndexToCustomParam[nTempMaxRepIndex] = CustomParam
        table.insert(tbPostNotifyProperties, nProp)
    end

    return rProperty
end

local function BindWeaponRep(nProp, DefaultValue, szWeaponRepFunc)
    return BindRep(nProp, DefaultValue, OnRepWeaponFunc, szWeaponRepFunc)
end

local function PostInit(OwnerComponent)
    if(tbInstanceIdRepInfo == nil) then
        -- 这里吧id的rep信息记录下来，回调时所有id改变只会触发一次OnRepWeaponChanged
        local nRepIndex
        tbInstanceIdRepInfo = {}
        for InstanceIdPropName, _ in pairs(InstanceIdPropNames) do
            nRepIndex = tbPropNameToRepIndex[InstanceIdPropName]
            tbInstanceIdRepInfo[nRepIndex] = true
        end
        nCurrentWeaponRepIndex = tbPropNameToRepIndex[PropName.nHumanCurrentWeaponInstanceId]
        nCallRepStartIndex = nCurrentWeaponRepIndex + 1
    end

    if(GlobalVariableSystem:IsDedicatedClient()) then
        OwnerComponent.tbDirtyRProperty = {}
        OwnerComponent.Owner.CustomReplicationComponent.Helper:AddPostRepNotifyCallback(
            tbPostNotifyProperties,
            function() OnPostRepNotify(OwnerComponent) end)
    end
end

----------------------------------------------------------------------------------------------------------------------
local function OnRepWeaponChanged(OwnerComponent)
    local rtbTemplateIdBySlot = OwnerComponent.rtbTemplateIdBySlot
    local rtbInstanceIdBySlot = OwnerComponent.rtbInstanceIdBySlot
    local tbWeaponBySlot = OwnerComponent.tbWeaponBySlot
    local tbWeaponById = OwnerComponent.tbWeaponById
    local nCurrentWeapon = OwnerComponent:GetCurrentWeaponInstanceId()
    local bCurrentWeaponChanged = false

    -- 先走Remove，在走Add
    local tbWeapon, nInstanceId, nOldInstanceId
    for nSlot, rInstanceId in pairs(rtbInstanceIdBySlot) do
        nInstanceId = rInstanceId:Get()
        tbWeapon = tbWeaponBySlot[nSlot]
        if(tbWeapon) then
            nOldInstanceId = tbWeapon.nInstanceId
            if(nOldInstanceId ~= nInstanceId and nOldInstanceId ~= 0) then
                OwnerComponent:OnWeaponRemoved(nOldInstanceId)
                if(nCurrentWeapon == nOldInstanceId) then
                    bCurrentWeaponChanged = true
                end
            end
        end
    end

    for nSlot, rInstanceId in pairs(rtbInstanceIdBySlot) do
        nInstanceId = rInstanceId:Get()
        if(nInstanceId ~= NO_WEAPON and tbWeaponById[nInstanceId] == nil) then
            OwnerComponent:OnWeaponAdded(nInstanceId, rtbTemplateIdBySlot[nSlot]:Get(), nSlot)
        end
    end

    return bCurrentWeaponChanged
end

local function OnRepReload(OwnerComponent, nReloading)
    -- 停止让他自己停
    if(nReloading ~= 0) then
        local tbCurrentWeapon = OwnerComponent:GetCurrentWeapon()
        local nCurrentState = OwnerComponent:GetCurrentState()
        if(nCurrentState ~= HumanWeaponStateDef.RELOADING
            and nCurrentState ~= HumanWeaponStateDef.UNHOLDING
            and tbCurrentWeapon and tbCurrentWeapon:IsType(HumanWeaponType.GUN)) then
            OwnerComponent.StateHelper:ChangeState(HumanWeaponStateDef.RELOADING)
        end
    end
end

OnPostRepNotify = function(OwnerComponent)
    if GlobalVariableSystem:IsStandalone() then
        return
    end

    local tbDirtyRProperty = OwnerComponent.tbDirtyRProperty
    assert(tbDirtyRProperty)

    if(not tbDirtyRProperty.bDirty) then
        return
    end

    -- 这东西是为了处理物品交换但currentweapon没变的情况
    -- 当物品产生交换，服务器并不会同步instanceid，这会客户端需要自己重新设置下currentweapon
    local bCurrentWeaponChanged = false

    -- 将所有的instanceId都过一遍，有变的最后在处理
    local rProperty, bWeaponChanged
    for nRepIndex, _ in pairs(tbInstanceIdRepInfo) do
        rProperty = tbDirtyRProperty[nRepIndex]
        if(rProperty) then
            tbDirtyRProperty[nRepIndex] = nil
            bWeaponChanged = true
        end
    end

    if(bWeaponChanged) then
        bCurrentWeaponChanged = OnRepWeaponChanged(OwnerComponent)
    end

    -- 处理current weapon
    local nCurrentWeaponId
    rProperty = tbDirtyRProperty[nCurrentWeaponRepIndex]
    if(rProperty) then
        -- 如果服务器发了currentweapon，那么就不用管交换的情况了
        tbDirtyRProperty[nCurrentWeaponRepIndex] = nil
        nCurrentWeaponId = rProperty:Get()
    elseif(bCurrentWeaponChanged) then
        local nWeaponState = OwnerComponent:GetCurrentState()
        if nWeaponState ~= HumanWeaponStateDef.UNHOLDING and nWeaponState ~= HumanWeaponStateDef.UNHOLDED then
            nCurrentWeaponId = OwnerComponent:GetCurrentWeaponInstanceId()
        end
    end
    local nNewWeaponId = nCurrentWeaponId
    if nNewWeaponId and nNewWeaponId < 0 then
        nNewWeaponId = nNewWeaponId * -1
    end
    if(nNewWeaponId and OwnerComponent:FindWeaponById(nNewWeaponId) == nil) then
        nCurrentWeaponId = 0
    end

    if(nCurrentWeaponId ~= nil) then
        if(OwnerComponent:IsAttacking()) then
            OwnerComponent:CancelAttack()
        end

        if(OwnerComponent:CanChangeWeapon(nCurrentWeaponId)) then
            if(OwnerComponent:GetCurrentWeaponInstanceId() ~= nCurrentWeaponId) or bCurrentWeaponChanged then
                OwnerComponent:OnCurrentWeaponChanged(nCurrentWeaponId, bCurrentWeaponChanged)
            end
        else
            OwnerComponent:SetPendingCurrentWeapon(nCurrentWeaponId)
        end
    end

    -- 后处理其他的
    for i=nCallRepStartIndex, nTempMaxRepIndex do
        rProperty = tbDirtyRProperty[i]
        if(rProperty) then
            tbDirtyRProperty[i] = nil
            CallRepFunc(OwnerComponent, i, rProperty)
        end
    end

    tbDirtyRProperty.bDirty = false
end

function HumanWeaponRepHelper.Init(OwnerComponent)
    TempOwnerComponent = OwnerComponent
    rTempComponent = OwnerComponent.Owner.CustomReplicationComponent
    bTempDedicatedServer = GlobalVariableSystem:IsDedicatedServer()
    bTempStandalone = GlobalVariableSystem:IsStandaloneServer()
    --bTempClientSelf = OwnerComponent.Owner.ObjectType == GameObjectTypeDef.PlayerSelf



    local rtbInstanceIdBySlot = {}
    OwnerComponent.rtbInstanceIdBySlot = rtbInstanceIdBySlot
    local rtbTemplateIdBySlot = {}
    OwnerComponent.rtbTemplateIdBySlot = rtbTemplateIdBySlot

    local rtbFashionIdBySlot = {}
    OwnerComponent.rtbFashionIdBySlot = rtbFashionIdBySlot

    -- templateid和instanceid一般同时下来，只看instanceid就够了，所以这里templateid没有bind回调
    bTempNeedRepNotify = false

    for nSlot, nProp in pairs(SlotToFashionPropName) do
        rtbFashionIdBySlot[nSlot]          = BindRep(nProp, INVALID_FASHION_ID)
    end

    for nSlot, nProp in pairs(SlotToTemplatePropName) do
        rtbTemplateIdBySlot[nSlot]          = BindRep(nProp, INVALID_TEMPLATE_ID)
    end



    -- bind 按照什么顺序，客户端rep就会按照什么顺序触发，服务器直接触发
    -- 注意：回调函数注册过一次就记录到local变量中，不要注册一些动态函数，请参考BindRep
    -- 这里rep到客户端的逻辑比较复杂，列举下情况：
    -- 1. bTempNeedRepNotify直接决定是否有rep回调
    -- 2. PropName里定义的rep类型直接决定了是否会触发回调
    -- 3. 现在DedicatedServer都不会有回调
    -- 4. Rep情况如下表，对于Self来讲得看Prop是否是rep给自己，如果是则需要回调，否则不需要，这个请查看BindRep的实现
    -- RepSituation         Self    Others
    -- DedicatedServer      no      no
    -- DedicatedClient      some    all
    -- Standalone           some    all

    bTempNeedRepNotify = true
    for nSlot, nProp in pairs(SlotToInstancePropName) do
        rtbInstanceIdBySlot[nSlot]              = BindRep(nProp,                                    NO_WEAPON)
    end

    OwnerComponent.rCurrentWeapon               = BindRep(PropName.nHumanCurrentWeaponInstanceId,   0)
    OwnerComponent.rInAiming                    = BindRep(PropName.bHumanWeaponInAiming,            false,          OwnerComponent.OnAimingChanged)
    OwnerComponent.rAttacking                   = BindRep(PropName.bAttacking,                      false,          OwnerComponent.OnRepAttacking)

    -- 第三个参数是直接call到weapon的函数，比如HumanWeaponGunBase_C:OnRepAttackRoute(RepValue)
    OwnerComponent.rHumanGunAttackRoute         = BindWeaponRep(PropName.rHumanGunAttackRoute,          nil,            "OnRepGunAttackRoute")
    OwnerComponent.rHumanGunAttackOnceResult    = BindWeaponRep(PropName.rHumanGunAttackOnceResult,     nil,            "OnRepGunAttackOnceResult")
    OwnerComponent.rHumanGunAttackMultiResult   = BindWeaponRep(PropName.rHumanGunAttackMultiResult,    nil,            "OnRepGunAttackMultiResult")
    OwnerComponent.rHumanMeleeAttackRoute       = BindWeaponRep(PropName.rHumanMeleeAttackRoute,        nil,            "OnRepMeleeAttackRoute")
    OwnerComponent.rHumanMeleeAttackHits        = BindWeaponRep(PropName.rHumanMeleeAttackHits,         nil,            "OnRepMeleeAttackHits")
    OwnerComponent.rHumanThrownState            = BindWeaponRep(PropName.nHumanThrownState,             0,              "OnRepThrownState")

    OwnerComponent.rHumanDualWieldAttack        = BindWeaponRep(PropName.rHumanDualWieldAttack,         nil,            "OnRepDualWieldAttack")
    OwnerComponent.rHumanProjectGunAttackRoute  = BindWeaponRep(PropName.rHumanPorjectGunAttackRoute,   nil,            "OnRepPorjectGunAttackRoute")
    OwnerComponent.rHumanBowPreAttact           = BindWeaponRep(PropName.nHumanBowPreAttack,            0,              "OnHumanBowPreAttact")
    OwnerComponent.rHumanAttackSubState         = BindWeaponRep(PropName.nHumanAttackSubState,          0,              "OnRepAttackSubState")

    -- 将reload放在最后 防止rHumanMeleeAttackRoute 和 reload 同时下来导致播不出动作来
    OwnerComponent.rHumanReloading              = BindRep(PropName.nHumanReloading,                 0,              OnRepReload)
    PostInit(OwnerComponent)
end

function HumanWeaponRepHelper.RefreshWeaponRepData(OwnerComponent)
    assert(OwnerComponent)
    for _, v in pairs(OwnerComponent.rtbInstanceIdBySlot) do
        OnRepProperty(OwnerComponent, v)
    end
    OnRepProperty(OwnerComponent, OwnerComponent.rCurrentWeapon)
    OnRepProperty(OwnerComponent, OwnerComponent.rInAiming)
    OnPostRepNotify(OwnerComponent)
end

return HumanWeaponRepHelper