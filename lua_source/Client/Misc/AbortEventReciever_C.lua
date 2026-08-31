local luaclass = require("luaclass")
local AbortEventReciever = require("AbortEventReciever")
local AbortEventReciever_C = luaclass("AbortEventReciever_C", AbortEventReciever)
local AbortType = require("AbortTypeDefine")
local ClientEventDef = require("ClientEventDef")
local HumanWeaponCalculator = require("HumanWeaponCalculator")
local CommonEventDef = require("CommonEventDef")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

function AbortEventReciever_C:InitEventInfo(Object)
    local bServer = GlobalVariableSystem:IsServerLogic()
    if bServer then
        AbortEventReciever_C.super.InitEventInfo(self,Object)
    end

    -- REGISTEREVENT
    self:Register(AbortType.SHIP_AIM,       self.REGISTEREVENT,         CommonEventDef.EV_ON_SHIP_AIM_STATE_CHANGED)
    -- 人移动
    self:Register(AbortType.HUMAN_MOVE, self.REGISTEREVENT,         ClientEventDef.EV_HUMAN_MOVE_TYPE_CHANGED,
    function(reciever, nMoveType)
        if nMoveType == HumanWeaponCalculator.SpreadEnum.MOVE_RUN then
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
    self:Register(AbortType.HUMAN_PROGRESS_BAR,  self.REGISTEREVENT,  CommonEventDef.EV_PROGRESS_CHANGED,
        function(reciever, nInstanceId, bStart, nProgressBarId, nProgressBarTime)
            local OwnerInstanceId = Object.Owner:GetServerInstanceId()
            if OwnerInstanceId == nInstanceId and bStart then 
                reciever:OnAbort()
            end
        end)     
    -- 人武器状态变化 包含开火 手持投掷物等武器操作
    self:Register(AbortType.HUMAN_WEAPON_STATE_CHANGE,  self.REGISTEREVENT,  CommonEventDef.EV_HUMAN_WEAPON_STATE_CHANGED,
        function(reciever, nState, tbCharacter)
            if Object.Owner == tbCharacter and Object.Owner:IsHuman() then
                if nState == HumanWeaponStateDef.ATTACKING
                    or nState == HumanWeaponStateDef.HOLDING
                    -- or nState == HumanWeaponStateDef.HOLDED
                    -- or nState == HumanWeaponStateDef.RELOADING
                then
                    reciever:OnAbort()
                end
            end
        end)

    -- 开关门
    self:Register(AbortType.DOOR_SWITCHED, self.REGISTEREVENT, ClientEventDef.EV_SHOW_DOOR_SWITCH, 
        function(reciever, tbGameObject, _, nCauserId)
            if nCauserId ~= nil and Object.Owner:GetServerInstanceId() == nCauserId then
                reciever:OnAbort()
            end
        end)        
end

function AbortEventReciever_C:DisplacementCheck(Object)
    -- 只需要服务器或者单机本执行
    local bServer = GlobalVariableSystem:IsServerLogic()
    if bServer then
        AbortEventReciever_C.super.DisplacementCheck(self,Object)
    end
end

return AbortEventReciever_C