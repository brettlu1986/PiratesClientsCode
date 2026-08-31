local luaclass = require("luaclass")
local CameraLogicBase = require("CameraLogicBase")
local CLSetting = luaclass("CLSetting", CameraLogicBase)

local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local ClientEventDef = require("ClientEventDef")
local GameCameraModeDef = require("GameCameraModeDef")
local SettingCameraDataTable = require("SettingCameraDataTable")
local SettingGyroDataTable = require("SettingGyroDataTable")
local SettingIni = require("SettingIni")
local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")
local HumanMovementStateType = require("HumanMovementStateType")
local PlayerSelfHelper = require("GamePlayerSelfHelper")

CLSetting.nSenseValueType = nil
CLSetting.tbCameraSenseValue = nil
CLSetting.tbGyroSenseValue = nil

CLSetting.nCurMoveXScale = 1
CLSetting.nCurMoveYScale = 1

CLSetting.nMoveScaleX = 1
CLSetting.nMoveScaleY = 1
CLSetting.nAimRate = 2

local tbGroupDef = GameCameraModeGroupDef
local tbModeDef = GameCameraModeDef
local SenseValueDef = GameCameraModeGroupDef.SettingValueType
local SenseTargetDef = GameCameraModeGroupDef.SettingTargetType
local tbCameraSenseCfg = nil
local tbGyroSenseCfg = nil

local BASE_MOVE_SCALE = 0.9

local function GetCameraSettingCfg(nValueType)
    return SettingCameraDataTable:GetTemplate(nValueType)
end

local function GetGyroSenseSettingCfg(nValueType)
    return SettingGyroDataTable:GetTemplate(nValueType)
end

local function IsLockInputState(self)
    local nGroupId = self.Owner.nCurrentGroupId
    return  nGroupId == tbGroupDef.ViewDeadBoxHuman
        or nGroupId == tbGroupDef.ViewDeadBoxShip
        or nGroupId == tbGroupDef.ViewTeammateHuman
        or nGroupId == tbGroupDef.ViewTeammateShip
        or nGroupId == tbGroupDef.NewParachuteLaunchFocus
end

local function InitHandleScaleBySenseSetting(self)
    local nGroupId = self.Owner.nCurrentGroupId
    local nXScale = self.nCurMoveXScale
    local nYScale = self.nCurMoveYScale
    local nSenseValue = nil
    if nGroupId == tbGroupDef.NewParachuteShipping or nGroupId == tbGroupDef.NewParachuteLaunchFocus or nGroupId == tbGroupDef.NewParachuteLaunchPlayer
        or nGroupId == tbGroupDef.NewParachuteTopPoint or nGroupId ==  tbGroupDef.NewParachuteOpenParachute then
        nSenseValue = self.tbCameraSenseValue[SenseTargetDef.Parachute]
    elseif nGroupId == tbGroupDef.HumanNormal or nGroupId == tbGroupDef.HumanSwimming or nGroupId == tbGroupDef.VehicleView then
        nSenseValue = self.tbCameraSenseValue[SenseTargetDef.HumanNotAim]
    elseif nGroupId == tbGroupDef.HumanAiming then
        nSenseValue = self.tbCameraSenseValue[SenseTargetDef.HumanAim]
    elseif nGroupId == tbGroupDef.ShipNormal then
        nSenseValue = self.tbCameraSenseValue[SenseTargetDef.ShipNotAim]
    elseif nGroupId == tbGroupDef.ShipAiming then
        if self.nAimRate == 2 then
            nSenseValue = self.tbCameraSenseValue[SenseTargetDef.ShimAim2]
        elseif self.nAimRate == 4 then
            nSenseValue = self.tbCameraSenseValue[SenseTargetDef.ShipAim4]
        else
            nSenseValue = self.tbCameraSenseValue[SenseTargetDef.ShipAim8]
        end
    end

    nSenseValue = nSenseValue == nil and 1 or nSenseValue
    nXScale = nSenseValue * nXScale
    nYScale = nSenseValue * nYScale
    self.nCurMoveXScale = nXScale
    self.nCurMoveYScale = nYScale
end

local function InitGyroScaleBySenseSetting(self)
    local nGroupId = self.Owner.nCurrentGroupId
    local nSenseValue = nil
    if nGroupId == tbGroupDef.NewParachuteShipping or nGroupId == tbGroupDef.NewParachuteLaunchFocus or nGroupId == tbGroupDef.NewParachuteLaunchPlayer
        or nGroupId == tbGroupDef.NewParachuteTopPoint or nGroupId ==  tbGroupDef.NewParachuteOpenParachute then
        nSenseValue = self.tbGyroSenseValue[SenseTargetDef.Parachute]
    elseif nGroupId == tbGroupDef.HumanNormal or nGroupId == tbGroupDef.HumanSwimming or nGroupId == tbGroupDef.VehicleView then
        nSenseValue = self.tbGyroSenseValue[SenseTargetDef.HumanNotAim]
    elseif nGroupId == tbGroupDef.HumanAiming then
        nSenseValue = self.tbGyroSenseValue[SenseTargetDef.HumanAim]
    elseif nGroupId == tbGroupDef.ShipNormal then
        nSenseValue = self.tbGyroSenseValue[SenseTargetDef.ShipNotAim]
    elseif nGroupId == tbGroupDef.ShipAiming then
        if self.nAimRate == 2 then
            nSenseValue = self.tbGyroSenseValue[SenseTargetDef.ShimAim2]
        elseif self.nAimRate == 4 then
            nSenseValue = self.tbGyroSenseValue[SenseTargetDef.ShipAim4]
        else
            nSenseValue = self.tbGyroSenseValue[SenseTargetDef.ShipAim8]
        end
    end

    nSenseValue = nSenseValue == nil and 1 or nSenseValue
    local GameCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    GameCameraManager.GyroXScale = nSenseValue
    GameCameraManager.GyroYScale = nSenseValue
end

local function IsCrawlState(self)
    local HumanMovementStateComponent = PlayerSelfHelper:Get().HumanMovementStateComponent
    if HumanMovementStateComponent then
        local nMovementState = HumanMovementStateComponent:GetCurrentState()
        return nMovementState == HumanMovementStateType.Crawl_State
    end
    return false
end

function CLSetting:InitHandleParam()
    --这个模式 默认是 肯定会有的
    self.Owner:ActiveCameraMode(tbModeDef.ModeHandleMove, {})
    local GameCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    local pHandleType = EHandleInputType.UseController
    local nGroupId = self.Owner.nCurrentGroupId
    if nGroupId == tbGroupDef.HumanNormal or nGroupId == tbGroupDef.HumanSwimming then
        self.nCurMoveXScale, self.nCurMoveYScale = BASE_MOVE_SCALE, BASE_MOVE_SCALE
        if nGroupId == tbGroupDef.HumanNormal and IsCrawlState(self) then
            pHandleType = EHandleInputType.UseControllerArm
        else
            pHandleType = EHandleInputType.UseControllerArmPitch
        end
    elseif nGroupId == tbGroupDef.NewParachuteOpenParachute then  
        self.nCurMoveXScale, self.nCurMoveYScale = BASE_MOVE_SCALE, BASE_MOVE_SCALE
        pHandleType = EHandleInputType.UseControllerArmPitch
    elseif nGroupId == tbGroupDef.HumanAiming then
        self.nCurMoveXScale, self.nCurMoveYScale = self.nMoveScaleX * BASE_MOVE_SCALE, self.nMoveScaleY * BASE_MOVE_SCALE
        pHandleType = EHandleInputType.UseController
    elseif nGroupId == tbGroupDef.ShipAiming then
        self.nCurMoveXScale, self.nCurMoveYScale = self.nMoveScaleX * BASE_MOVE_SCALE, self.nMoveScaleY * BASE_MOVE_SCALE
        pHandleType = EHandleInputType.UseControllerPitchNegativeArm
    elseif nGroupId == tbGroupDef.ShipNormal  then
        self.nCurMoveXScale, self.nCurMoveYScale = BASE_MOVE_SCALE, BASE_MOVE_SCALE
        pHandleType = EHandleInputType.UseControllerPitchNegativeArm
    elseif nGroupId == tbGroupDef.HumanFreeView  or nGroupId == tbGroupDef.BotHuman then
        self.nCurMoveXScale, self.nCurMoveYScale = self.nMoveScaleX * BASE_MOVE_SCALE, self.nMoveScaleY * BASE_MOVE_SCALE
        pHandleType = EHandleInputType.UseArm
    --新跳伞
    elseif nGroupId == tbGroupDef.NewParachuteShipping or nGroupId == tbGroupDef.NewParachuteLaunchPlayer
        or nGroupId == tbGroupDef.NewParachuteTopPoint or nGroupId == tbGroupDef.VehicleView then
        self.nCurMoveXScale, self.nCurMoveYScale = BASE_MOVE_SCALE, BASE_MOVE_SCALE
        pHandleType = EHandleInputType.UseArm
    end

    -- logdebug("----- handle move scale before::", self.nCurMoveXScale, self.nCurMoveYScale)
    InitHandleScaleBySenseSetting(self)
    InitGyroScaleBySenseSetting(self)
    -- logdebug("----- handle move scale after::", self.nCurMoveXScale, self.nCurMoveYScale)
    GameCameraManager:SetHandleMoveParam(self.nCurMoveXScale, self.nCurMoveYScale, pHandleType)
    GameCameraManager.LockMoveInput = false --死亡镜头不能有划屏操作
    if IsLockInputState(self) then
        GameCameraManager.LockMoveInput = true
    end
end

local function SetCameraSenseValueByTarget(self, nTargetType, nPercent)
    nPercent = nPercent < 0 and 0 or nPercent
    nPercent = nPercent > 1 and 1 or nPercent

    local tbSense = SettingIni.tbSense
    local nRangeMax = tbSense.nMax
    local nRangeMini = tbSense.nMini
    local nRange = nRangeMax - nRangeMini
    local nValue = nRangeMini + nRange * nPercent
    self.tbCameraSenseValue[nTargetType] = nValue
end

local function SetGyroSenseValueByTarget(self, nTargetType, nPercent)
    nPercent = nPercent < 0 and 0 or nPercent
    nPercent = nPercent > 1 and 1 or nPercent

    local tbSense = SettingIni.tbSense
    local nRangeMax = tbSense.nGyroMax
    local nRangeMini = tbSense.nGyroMini
    local nRange = nRangeMax - nRangeMini
    local nValue = nRangeMini + nRange * nPercent
    -- logdebug("set gyro percent :", nRangeMini, nPercent)
    self.tbGyroSenseValue[nTargetType] = nValue
end

local function InitCameraSenseByValueType(self, nValueType)
    if nValueType ~= SenseValueDef.Min and nValueType ~= SenseValueDef.Mid
        and nValueType ~= SenseValueDef.Max then
        return
    end

    local ToValue = function(nValuePercent)
        local tbSense = SettingIni.tbSense
        local nRange = tbSense.nMax - tbSense.nMini
        return nValuePercent * 0.01 * nRange + tbSense.nMini
    end

    self.nSenseValueType = nValueType
    local tbValue = self.tbCameraSenseValue
    tbValue[SenseTargetDef.Parachute] = ToValue(tbCameraSenseCfg[nValueType].Parachute)
    tbValue[SenseTargetDef.HumanNotAim] = ToValue(tbCameraSenseCfg[nValueType].HumanNotAim)
    tbValue[SenseTargetDef.HumanAim] = ToValue(tbCameraSenseCfg[nValueType].HumanAim)
    tbValue[SenseTargetDef.ShipNotAim] = ToValue(tbCameraSenseCfg[nValueType].ShipNotAim)
    tbValue[SenseTargetDef.ShimAim2] = ToValue(tbCameraSenseCfg[nValueType].ShipAim2)
    tbValue[SenseTargetDef.ShipAim4] = ToValue(tbCameraSenseCfg[nValueType].ShipAim4)
    tbValue[SenseTargetDef.ShipAim8] = ToValue(tbCameraSenseCfg[nValueType].ShipAim8)
end

local function InitGyroSenseByValueType(self, nValueType)
    if nValueType ~= SenseValueDef.Min and nValueType ~= SenseValueDef.Mid
        and nValueType ~= SenseValueDef.Max then
        return
    end

    local ToValue = function(nValuePercent)
        local tbSense = SettingIni.tbSense
        local nRange = tbSense.nGyroMax - tbSense.nGyroMini
        return nValuePercent * 0.01 * nRange + tbSense.nGyroMini
    end

    self.nSenseValueType = nValueType
    local tbValue = self.tbGyroSenseValue
    tbValue[SenseTargetDef.Parachute] = ToValue(tbGyroSenseCfg[nValueType].Parachute)
    tbValue[SenseTargetDef.HumanNotAim] = ToValue(tbGyroSenseCfg[nValueType].HumanNotAim)
    tbValue[SenseTargetDef.HumanAim] = ToValue(tbGyroSenseCfg[nValueType].HumanAim)
    tbValue[SenseTargetDef.ShipNotAim] = ToValue(tbGyroSenseCfg[nValueType].ShipNotAim)
    tbValue[SenseTargetDef.ShimAim2] = ToValue(tbGyroSenseCfg[nValueType].ShipAim2)
    tbValue[SenseTargetDef.ShipAim4] = ToValue(tbGyroSenseCfg[nValueType].ShipAim4)
    tbValue[SenseTargetDef.ShipAim8] = ToValue(tbGyroSenseCfg[nValueType].ShipAim8)
end

local function InitCameraSenseValue(self)
    self.tbCameraSenseValue = {}
    self.tbGyroSenseValue = {}

    local SettingCamera = SettingSystemNew:GetInstance(SettingClassType.Setting_Camera)
    local nValueType = SettingCamera:GetGlobalValue()
    if nValueType ~= SenseValueDef.Custom then
        self.nSenseValueType = nValueType
        InitCameraSenseByValueType(self, self.nSenseValueType)
        InitGyroSenseByValueType(self, self.nSenseValueType)
    else
        local tbCameraCfg = SettingCamera:GetCameraSubValues()
        for k, v in pairs(tbCameraCfg) do
            SetCameraSenseValueByTarget(self, v.nKey, v.nValue * 0.01)
        end

        local tbGyroCfg = SettingCamera:GetGyroSubValues()
        for k, v in pairs(tbGyroCfg) do
            SetGyroSenseValueByTarget(self, v.nKey, v.nValue * 0.01)
        end
    end
end

local function ChangeSenseValue(self, nValue)
    InitCameraSenseByValueType(self, nValue)
    InitGyroSenseByValueType(self, nValue)
    self:InitHandleParam()
end

local function ChangeCameraSenseValue(self, nTargetType, nValue)
    SetCameraSenseValueByTarget(self, nTargetType, nValue)
    self:InitHandleParam()
end

local function ChangeGyroSenseValue(self, nTargetType, nValue)
    SetGyroSenseValueByTarget(self, nTargetType, nValue)
    self:InitHandleParam()
end

function CLSetting:OnCreate()
    tbCameraSenseCfg =
    {
        [SenseValueDef.Min] = GetCameraSettingCfg(SenseValueDef.Min),
        [SenseValueDef.Mid] = GetCameraSettingCfg(SenseValueDef.Mid),
        [SenseValueDef.Max] = GetCameraSettingCfg(SenseValueDef.Max),
    }

    tbGyroSenseCfg =
    {
        [SenseValueDef.Min] = GetGyroSenseSettingCfg(SenseValueDef.Min),
        [SenseValueDef.Mid] = GetGyroSenseSettingCfg(SenseValueDef.Mid),
        [SenseValueDef.Max] = GetGyroSenseSettingCfg(SenseValueDef.Max),
    }

    InitCameraSenseValue(self)
end

function CLSetting:OnDestroy()
end

function CLSetting:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHANGE_SENSE_VALUE, self, ChangeSenseValue)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHANGE_CAMERA_SENSE_VALUE, self, ChangeCameraSenseValue)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHANGE_GYRO_SENSE_VALUE, self, ChangeGyroSenseValue)
end

function CLSetting:OnUnbindEvent(EventHelper)
end

return CLSetting