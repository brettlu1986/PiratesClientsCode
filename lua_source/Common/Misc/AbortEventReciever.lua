local luaclass = require("luaclass")
local AbortEventReciever = luaclass("AbortEventReciever")
local AbortType = require("AbortTypeDefine")
local CommonEventDef = require("CommonEventDef")
local SelfEventHelperClass = require("SelfEventHelper")
local HumanMovementStateType = require("HumanMovementStateType")
-- local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
-- local Timer = require("Timer")
local DamageTypeEx = require("DamageTypeEx")
local ProgressBarTableNew = require("ProgressBarTableNew")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
AbortEventReciever.EventHelper = nil
AbortEventReciever.fnCallback = nil
AbortEventReciever.tbAbortTypeToEvent = nil
AbortEventReciever.bHumanCrawlToCrouch = false
AbortEventReciever.bHumanSwim = false
AbortEventReciever.nAbortByMovementType = 0

AbortEventReciever.REGISTEREVENT = 1
AbortEventReciever.REGISTERLUADELEGATE = 2
AbortEventReciever.REGISTERCPPDELEGATE = 3


local BURNING_BUFF_ID_MAP = {
    [70001] = true,
    [80003] = true,
    [80004] = true,
}

local IGNORE_ABORT_DAMAGE_TYPE = {
    [DamageTypeEx.POISON_CIRCLE] = true,
    [DamageTypeEx.HUMAN_FIREBOMB] = true,
    [DamageTypeEx.SHIP_FIRING] = true,
    [DamageTypeEx.SHIP_LEAKING] = true,
    [DamageTypeEx.DROWN] = true,
}

function AbortEventReciever:DefaultFunction()
    self:OnAbort()
end

function AbortEventReciever:Register(nAbortType, nRegister, Event, fnFunc, fnPreparedFunc)
    if not nAbortType or not Event then
        return
    end
    fnFunc = fnFunc ~= nil and fnFunc or self.DefaultFunction
    if not self.tbAbortTypeToEvent[nAbortType] then
        self.tbAbortTypeToEvent[nAbortType] = {}
    end
    local tbAbortEvents = {}
    tbAbortEvents.nRegister = nRegister
    tbAbortEvents.Event = Event
    tbAbortEvents.fnFunc = fnFunc
    tbAbortEvents.fnPreparedFunc = fnPreparedFunc
    table.insert(self.tbAbortTypeToEvent[nAbortType], tbAbortEvents)
end

-- tbAbortTypeToEvent = {
--     [AbortType.DISPLACEMENT] = {
--         {[nRegister] = REGISTEREVENT, [Event] = CommonEventDef.EV_HUMAN_WEAPON_STATE_CHANGED, [fnFunc] = fnFunc},
--         {[nRegister] = REGISTEREVENT, [Event] = CommonEventDef.EV_HUMAN_WEAPON_STATE_CHANGED, [fnFunc] = fnFunc},
--     },
-- }

function AbortEventReciever:InitEventInfo(Object)
    -- REGISTEREVENT
    -- 人船死亡
    self:Register(AbortType.PLAYER_DEAD,  self.REGISTEREVENT,  CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD,
    function(reciever, OnPawnDead)
        if Object.Owner == OnPawnDead then
            reciever:OnAbort()
        end
    end)

    --人船重伤
    self:Register(AbortType.PLAYER_DYING,  self.REGISTEREVENT,  CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DYING_CHANGED,
    function(reciever, tbPlayer, bIsDying)
        if Object.Owner == tbPlayer and bIsDying then
            reciever:OnAbort()
        end
    end)

    -- 人和船被上燃烧弹buff
    self:Register(AbortType.PLAYER_BURN,  self.REGISTEREVENT,  CommonEventDef.EV_ON_BUFF_ADD,
    function(reciever, tbTaker, nBuffId)
        if Object.Owner == tbTaker and BURNING_BUFF_ID_MAP[nBuffId] then
            reciever:OnAbort()
        end
    end)
    -- 人和船被更新燃烧弹buff
    self:Register(AbortType.PLAYER_BURN,  self.REGISTEREVENT,  CommonEventDef.EV_ON_BUFF_REFRESH,
    function(reciever, tbTaker, nBuffId)
        if Object.Owner == tbTaker and BURNING_BUFF_ID_MAP[nBuffId] then
            reciever:OnAbort()
        end
    end)

    -- 人受伤
    self:Register(AbortType.HUMAN_INJURED,  self.REGISTEREVENT,  CommonEventDef.EV_ON_TAKE_DAMAGE,
        function(reciever, tbTaker, tbCauser, nDamage, nDamageType)
            if Object.Owner == tbTaker and Object.Owner:IsHuman() and nDamage > 0 then
                if not IGNORE_ABORT_DAMAGE_TYPE[nDamageType] then
                    if Object.Owner:IsDying() and (nDamageType ~= DamageTypeEx.FALLING) then -- 重伤下只受自然伤害打断，如坠落
                        return
                    end
                    reciever:OnAbort()
                end
            end
        end)
    -- 船受伤
    self:Register(AbortType.SHIP_INJURED,  self.REGISTEREVENT,  CommonEventDef.EV_ON_TAKE_DAMAGE,
        function(reciever, tbTaker, tbCauser, nDamage, nDamageType)
            if Object.Owner == tbTaker and Object.Owner:IsShip() then
                if not IGNORE_ABORT_DAMAGE_TYPE[nDamageType] then
                    local PropertyComponent = Object.Owner.ShipBattlePropertyComponent
                    if PropertyComponent then
                        local tbTemplate = ProgressBarTableNew:GetTemplate(Object:GetCurrentTemplateId())
                        if tbTemplate and (nDamage >= tbTemplate.nShipInterruptedDamage) then
                            reciever:OnAbort()
                        else
                            log("[AbortEventReceiver] SHIP_INJURED abort failed, damage, interruptedDamage", nDamage, tbTemplate and tbTemplate.nShipInterruptedDamage)
                        end
                    end
                end
            end
        end)

    -- -- 人开火 HUMAN_WEAPON_STATE_CHANGE
    -- self:Register(AbortType.HUMAN_FIRE,  self.REGISTEREVENT,  CommonEventDef.EV_HUMAN_WEAPON_STATE_CHANGED,
    --     function(reciever, nState, tbCharacter)
    --         if Object.Owner == tbCharacter then
    --             if nState == HumanWeaponStateDef.ATTACKING then
    --                 reciever:OnAbort()
    --             end
    --         end
    --     end)
    -- 船开火
    self:Register(AbortType.SHIP_FIRE,    self.REGISTEREVENT,  CommonEventDef.EV_ON_SHIP_WEAPON_FIRED_SERVER,
        function(reciever, tbCharacter, tbShipWeaponItem, nFiringCount)
            if Object.Owner == tbCharacter and Object.Owner:IsShip() then
                reciever:OnAbort()
            end
        end)
    -- 船装弹
    self:Register(AbortType.SHIP_BULLET_LOAD,    self.REGISTEREVENT,  CommonEventDef.EV_ON_SHIP_WEAPON_BULLET_LOAD_BEGAN_SERVER,
        function(reciever, tbCharacter, nItemInstanceId, nLoadingTime)
            if Object.Owner == tbCharacter and Object.Owner:IsShip() then
                reciever:OnAbort()
            end
        end)

    -- 人拾取
    self:Register(AbortType.HUMAN_PICK_UP,    self.REGISTEREVENT,  CommonEventDef.EV_BATTLE_ITEM_REQUEST_PICK_UP_SERVER,
        function(reciever, nCharacterInstanceId, nItemInstanceId)
            if Object.Owner:GetServerInstanceId() == nCharacterInstanceId and Object.Owner:IsHuman() then
                reciever:OnAbort()
            end
        end)
    -- 船拾取
    self:Register(AbortType.SHIP_PICK_UP,    self.REGISTEREVENT,  CommonEventDef.EV_BATTLE_ITEM_REQUEST_PICK_UP_SERVER,
        function(reciever, nCharacterInstanceId, nItemInstanceId)
            if Object.Owner:GetServerInstanceId() == nCharacterInstanceId and Object.Owner:IsShip() then
                reciever:OnAbort()
            end
        end)

    -- 人物切瞄准状态
    self:Register(AbortType.HUMAN_WEAPON_STATE_CHANGE,  self.REGISTEREVENT,  CommonEventDef.EV_HUMAN_AIM_CHANGED,
        function(reciever, bAiming, tbCharacter)
            if Object.Owner == tbCharacter and Object.Owner:IsHuman() then
                -- aim为 true， 表示要开镜，这个时候需要打断，因为progress bar会退出开镜，这个时候也打断的话就会吃药不成功
                if bAiming then
                    reciever:OnAbort()
                end
            end
        end)

    -- 趴,趴下时候的起身打断,游泳
    self:Register(AbortType.HUMAN_CRAWL,    self.REGISTEREVENT,  CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED,
        function(reciever, tbCharacter, nOldState, nNewState)
            if Object.Owner == tbCharacter and Object.Owner:IsHuman() then
                if nNewState == HumanMovementStateType.Crawl_State then
                    reciever:OnAbort()
                    return
                end
                if nNewState == HumanMovementStateType.Swimming and not self.bHumanSwim then
                    reciever:OnAbort()
                    return
                end
                if nOldState == HumanMovementStateType.Crawl_State then
                    -- 需要判断是否允许趴变蹲
                    if nNewState == HumanMovementStateType.Crouch_State and not self.bHumanCrawlToCrouch then
                        reciever:OnAbort()
                        return
                    elseif nNewState == HumanMovementStateType.UpRight_State then
                        reciever:OnAbort()
                        return
                    end
                end
            end
        end)

    -- 人武器换位置
    self:Register(AbortType.HUMAN_WEAPON_SLOT_CHANGE,    self.REGISTEREVENT,  CommonEventDef.EV_BATTLE_ITEM_CHANGE_STORAGE_LOCATION_SERVER,
        function(reciever, tbItem)
            if Object.Owner == tbItem:GetOwnerCharacter() and tbItem:GetCategory() == BattleItemCategoryDef.HUMAN_WEAPON then
                reciever:OnAbort()
            end
        end)

    -- 人武器交换位置
    self:Register(AbortType.HUMAN_WEAPON_SLOT_CHANGE,    self.REGISTEREVENT,  CommonEventDef.EV_BEFORE_BATTLE_ITEM_EXCHANGE_STORAGE_LOCATION_SERVER,
        function(reciever, tbItem1, tbItem2)
            if Object.Owner == tbItem1:GetOwnerCharacter() and tbItem1:GetCategory() == BattleItemCategoryDef.HUMAN_WEAPON then
                reciever:OnAbort()
            end
        end)

    -- REGISTERLUADELEGATE
    local DelegateComponent = Object.Owner.DelegateComponent
    if DelegateComponent then
        -- 船移动
        self:Register(AbortType.SHIP_MOVE, self.REGISTERLUADELEGATE, DelegateComponent.OnGearValueChanged,
        function(reciever, pGearValue)
            if pGearValue ~= EShipGear.Stopped then
                self:OnAbort()
            end
        end)

        -- 船升帆降帆
        self:Register(AbortType.SHIP_POSTURE_CHANGE, self.REGISTERLUADELEGATE, DelegateComponent.OnShipInputDataChanged,
        function(reciever, pInputData)
            if pInputData.Posture ~= self.pCurrentShipPosture then
                self:OnAbort()
            end
        end,
        function()
            self.pCurrentShipPosture =  EShipPosture.FullSail
            local pUEActor = Object.Owner.pUEActor
            if pUEActor and pUEActor.ShipMovementComponent then
                self.pCurrentShipPosture = pUEActor.ShipMovementComponent:GetPosture()
            end
        end)

        -- 船转向
        self:Register(AbortType.SHIP_ROTATE, self.REGISTERLUADELEGATE, DelegateComponent.OnShipInputDataChanged,
        function(reciever, pInputData)
            if pInputData.SteerScale ~= 0 then
                self:OnAbort()
            end
        end)
    end

    -- REGISTERCPPDELEGATE
    local pUEActor = Object.Owner.pUEActor
    -- 跳
    self:Register(AbortType.HUMAN_JUMP, self.REGISTERCPPDELEGATE,   pUEActor.MovementModeChangedDelegate,
        function(reciever, pActor, PrevMovementMode, PreviousCustomMode)
            local nCurrentMovementMode = pUEActor.CharacterMovement.MovementMode
            if nCurrentMovementMode == EMovementMode.MOVE_Falling then
                reciever:OnAbort()
            end
        end)

    self:Register(AbortType.HUMAN_DISPLACEMENT, self.REGISTERCPPDELEGATE,   pUEActor.OnPlayerDisplacement,
        function(reciever, bDisplacement)
            if bDisplacement then
                local HumanMovementStateComponent = Object.Owner.HumanMovementStateComponent
                local bNeedAbort = true
                if HumanMovementStateComponent then
                    local nMovementState = HumanMovementStateComponent:GetCurrentState()
                    bNeedAbort = self:CheckNeedAbortByMove(self.nAbortByMovementType, nMovementState)
                end
                if bNeedAbort then
                    reciever:OnAbort()
                end
            end
        end)
    if GlobalVariableSystem:IsDedicatedServer() then 
        self:Register(AbortType.HUMAN_WEAPON_STATE_CHANGE,  self.REGISTEREVENT,  CommonEventDef.EV_HUMAN_WEAPON_STATE_CHANGED,
            function(reciever, nState, tbCharacter)
                local HumanWeaponComponent = Object.Owner.HumanWeaponComponent
                if HumanWeaponComponent and HumanWeaponComponent:IsAttacking() then
                    reciever:OnAbort()
                end
            end)
    end

end

function AbortEventReciever:OnAbort()
    if self.fnCallback then
        self.fnCallback()
    end
    self:Uninit()
end

function AbortEventReciever:RegisterAbortEvent(Object, nRegister, Event, fnFunc)
    if nRegister == self.REGISTEREVENT then
        self.EventHelper:RegisterEvent(Event, self, fnFunc)
    end
    if nRegister == self.REGISTERLUADELEGATE then
        if Event then
            self.EventHelper:RegisterLuaDelegate(Event, fnFunc, self)
        end
    end
    if nRegister == self.REGISTERCPPDELEGATE then
        self.EventHelper:RegisterCppDelegate(Event, self, fnFunc)
    end
end


function AbortEventReciever:Init(Object, tbAbortTypes, fnCallback)
    self.fnCallback = fnCallback
    self.EventHelper = SelfEventHelperClass()
    self.tbAbortTypeToEvent = {}
    self:InitEventInfo(Object)
    for _, nAbortType in pairs(tbAbortTypes) do
        local tbEventFunction = self.tbAbortTypeToEvent[nAbortType]
        if tbEventFunction then
            for _, tbAbortEvent in pairs(tbEventFunction) do
                if tbAbortEvent.fnPreparedFunc then
                    tbAbortEvent.fnPreparedFunc()
                end
                self:RegisterAbortEvent(Object, tbAbortEvent.nRegister, tbAbortEvent.Event, tbAbortEvent.fnFunc)
            end
        -- else
            -- 表中生效的打断 没有对应的事件
            -- logerror("The index of tbAbortTypeToEvent is nil. nAbortTypes:", nAbortType)
        end
    end
    -- end
end

function AbortEventReciever:Uninit()
    self.tbAbortTypeToEvent = nil
    self.fnCallback = nil
    if self.EventHelper then
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil
    end
end

function AbortEventReciever:CheckNeedAbortByMove(nAbortByMovementType, nMovementState)
    return true
end


return AbortEventReciever