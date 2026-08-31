

local luaclass = require("luaclass")
local CameraLogicBase = require("CameraLogicBase")
local CLCarronadeView = luaclass("CLCarronadeView", CameraLogicBase)

local DelayTimer = require("DelayTimer")
local CameraIni = require("CameraIni")
local ClientEventDef = require("ClientEventDef")
local GameCameraModeDef = require("GameCameraModeDef")
local PlayerSelfHelper = require("GamePlayerSelfHelper")
local ShipCameraDataTable = require("ShipCameraDataTable")
local ShipFiringOperationDef = require("ShipFiringOperationDef")
local ShipWeaponTemplateDef = require("ShipWeaponTemplateDef")

CLCarronadeView.bCarronadeActive = false
CLCarronadeView.tbTimerObject = nil 

local function ClearTimer(self)
    if self.tbTimerObject then
        DelayTimer:ClearTimer(self.tbTimerObject)
        self.tbTimerObject = nil
    end
end

local function LockInputInTime(self, nTime)
    local GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
    GameCameraManager.LockMoveInput = true
    GameCameraManager.ForbiddenFreeView = true
    ClearTimer(self)
    self.tbTimerObject = DelayTimer:DelayRun(function()
        GameCameraManager.LockMoveInput = false
        GameCameraManager.ForbiddenFreeView = false
    end, nTime)
end

local function GetCurShipTemplateId()
    local PlayerSelf = PlayerSelfHelper:Get()
    return  PlayerSelf:GetShipTemplateId()
end

local function ActiveCarronadeCamera(self, nShipTemplateId, bActive)
    -- logdebug("ActiveCarronadeCamera", nShipTemplateId, bActive)
    local GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
    if not GameCameraManager then return end
    local CameraActor = GameCameraManager:GetPlayerCameraActor()
    if not CameraActor then return end
    local pArm = CameraActor:GetSpringArm()
    if not pArm then return end
    
    local nNeedBlendTime = CameraIni.tbCarronadeActiveCamera.nMoveTime
    local tbShipCameraParam = ShipCameraDataTable:GetShipInitCameraParam(nShipTemplateId)
    if bActive then
        self.Owner:DeactiveMode(GameCameraModeDef.ModeOffsetMove)
        self.Owner:DeactiveMode(GameCameraModeDef.ModeArmLen)
        local OffsetForward = CameraIni.tbCarronadeActiveCamera.nOffsetForward
        local nOffsetUp = CameraIni.tbCarronadeActiveCamera.nOffsetUp
        --nOffsetUp = nOffsetUp - pArm.SocketOffset.Z

        local nCurShipDefaultArmLen = tbShipCameraParam.nArmLength
        local nActiveLen = nCurShipDefaultArmLen + OffsetForward
        OffsetForward =  nActiveLen - pArm.TargetArmLength
        self.Owner:ActiveCameraMode(GameCameraModeDef.ModeOffsetMove, { MoveOffset = Vector{X = 0, Y = 0, Z = nOffsetUp}, nBlendTime = nNeedBlendTime, bNeedBlend = true })
        self.Owner:ActiveCameraMode(GameCameraModeDef.ModeArmLen, { nArmLenToGo = OffsetForward, nBlendTime = nNeedBlendTime})
        LockInputInTime(self, nNeedBlendTime + 0.2)
        self.bCarronadeActive = true
    else
        if self.bCarronadeActive then
            self.Owner:DeactiveMode(GameCameraModeDef.ModeOffsetMove)
            self.Owner:DeactiveMode(GameCameraModeDef.ModeArmLen)

            local nOffsetLen = tbShipCameraParam.nArmLength - pArm.TargetArmLength
            self.Owner:ActiveCameraMode(GameCameraModeDef.ModeOffsetMove, { MoveOffset = Vector{X = 0, Y = 0, Z = 0}, nBlendTime = nNeedBlendTime, bNeedBlend = true })
            self.Owner:ActiveCameraMode(GameCameraModeDef.ModeArmLen, { nArmLenToGo = nOffsetLen, nBlendTime = nNeedBlendTime})
            LockInputInTime(self, nNeedBlendTime + 0.2)
            self.bCarronadeActive = false
        end
    end
end

local function OnShipWeaponFiringOperationChanged(self, tbCharacter, WeaponItem, nFiringOperation)
    if PlayerSelfHelper:IsNotPlayerSelf(tbCharacter) then
        return
    end
    if WeaponItem:GetTemplateType() ~= ShipWeaponTemplateDef.CARRONADE then
        return
    end
    ActiveCarronadeCamera(self, GetCurShipTemplateId(), nFiringOperation == ShipFiringOperationDef.START)
end

-- public function
function CLCarronadeView:OnCreate()
end

function CLCarronadeView:OnDestroy()
    ClearTimer(self)
end

function CLCarronadeView:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SHIP_WEAPON_FIRING_OPERATION_CHANGED_CLIENT, self, OnShipWeaponFiringOperationChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_WATCH_CARRONADE_CAMERA, self, ActiveCarronadeCamera)
end

function CLCarronadeView:OnUnbindEvent(EventHelper)
end

return CLCarronadeView
