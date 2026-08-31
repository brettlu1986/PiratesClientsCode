local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase") 
local CameraComponent = luaclass("CameraComponent", GameComponentBaseClass)
local GameCameraSystem = require("GameCameraSystem")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local TeamWatchClientHelper = require("TeamWatchClientHelper")

-- 创建
function CameraComponent:OnCreate(Owner, tbParams)
    CameraComponent.super.OnCreate(self, Owner, tbParams)
    return true
end

-- 销毁
function CameraComponent:OnDestroy()
    CameraComponent.super.OnDestroy()
end

local function IsWatchBattleMode(self)
    local nGroupDef = GameCameraModeGroupDef
    return GameCameraSystem:IsCameraLogicActive(nGroupDef.ViewTeammateShip) 
            or GameCameraSystem:IsCameraLogicActive(nGroupDef.ViewTeammateHuman)
end

local function IsOwnerBeingWatched(self)
    local nServerInsId = self.Owner.nServerInstanceId
    local nWatchId = TeamWatchClientHelper.GetCurrentWatchId() 
    local bIsWatchObject = nServerInsId == nWatchId
    -- log("[ClientWatch], change display:", IsWatchBattleMode(), nWatchId, nServerInsId)
    return IsWatchBattleMode() and bIsWatchObject
end


--处理观战 里面可能发生的切换  1. 人船切换  2.船建造切换
function CameraComponent:OnActorCreated(pUEActor)
    CameraComponent.super.OnActorCreated(self, pUEActor)
    if IsOwnerBeingWatched(self) then
        -- log("[ClientWatch] human ship exchange" )
        local nInstanceId = self.Owner.nServerInstanceId
        EventManager:OnFireEvent(CommonEventDef.EV_REQUEST_CHANGE_WATCH_MATE, nInstanceId)
    end
end

function CameraComponent:OnActorDestroyed(pUEActor)
    CameraComponent.super.OnActorDestroyed(self, pUEActor)
end

return CameraComponent
