local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULBotMovement = luaclass("ULBotMovement", UILogicBase)
local CommonEventDef = require("CommonEventDef")
local CameraGameHelper = require("CameraGameHelper")
local ClientEventDef = require("ClientEventDef")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local HumanMovementStateType = require("HumanMovementStateType")
local HumanCameraDataTable = require("HumanCameraDataTable")
local HumanWeaponCameraTimeDataTable = require("HumanWeaponCameraTimeDataTable")
-- local StateType = HumanMovementStateType
-- local tbStateOffset =
-- {
--     [StateType.UpRight_State] = 0,
--     [StateType.Crouch_State]  = -25,
--     [StateType.Crawl_State]   = -55,
--     [StateType.Dying_State]   = -25,
-- }


local function ChangeMovementState(self, tbCurrentWatchObj, nLastMoveState, nCurrentState, bBlend)
    if CameraGameHelper.IsNeedMovementBlend(nLastMoveState, nCurrentState) then
        local WeaponComponent = tbCurrentWatchObj.HumanWeaponComponent
        if WeaponComponent then
            local nWeaponID = WeaponComponent:GetCurrentWeaponTemplateId()
            nWeaponID = nWeaponID and nWeaponID or 0
            local nBlendTime = HumanWeaponCameraTimeDataTable:GetMovementCameraTime(nWeaponID, nLastMoveState, nCurrentState)
            local Offset = HumanCameraDataTable:GetMovementCameraOffset(nCurrentState)
            -- Offset.Z = tbStateOffset[nCurrentState]
            local nStatePitchMax, nStatePitchMin = HumanCameraDataTable:GetMovementCameraPitchLimit(nCurrentState)
            self.EventHelper:FireEvent(ClientEventDef.EV_WATCH_BATTLE_STATE_CHANGE, GameCameraModeGroupDef.WatchBattleDef.ChangeMovement, {
                Offset = Offset, nBlendTime = nBlendTime, bNeedBlend = bBlend, nStatePitchMax = nStatePitchMax, nStatePitchMin = nStatePitchMin
            })
        end
    end
end

local function ToWatchMateCorrectViewState(self)
    local tbCurrentWatchObj = self.Owner.tbCurrrentWatchObj
    if (tbCurrentWatchObj:IsHuman()) then  
        local HumanMovementComponent = tbCurrentWatchObj.HumanMovementStateComponent
        local nMovementState = HumanMovementComponent:GetCurrentState()
        if nMovementState == HumanMovementStateType.Crouch_State
            or nMovementState == HumanMovementStateType.Crawl_State
                or nMovementState == HumanMovementStateType.Dying_State then
            ChangeMovementState(self, tbCurrentWatchObj, HumanMovementStateType.UpRight_State, nMovementState, false)
        end
    end
end

local function OnHumanMovementStateChanged(self, tbGamePlayer, nLastMoveState, nCurrentState)
    local tbCurrentWatchObj = self.Owner.tbCurrrentWatchObj
    if tbCurrentWatchObj.nServerInstanceId == tbGamePlayer.nServerInstanceId then  
        ChangeMovementState(self, tbCurrentWatchObj, nLastMoveState, nCurrentState, true)
    end
end

function ULBotMovement:OnLoad()

    ToWatchMateCorrectViewState(self)
    -- bind prefab
end

function ULBotMovement:OnEnter()
    --local Owner = self.Owner
end

function ULBotMovement:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self, OnHumanMovementStateChanged)      
end

function ULBotMovement:OnUnload()
    --unload res
end

return ULBotMovement