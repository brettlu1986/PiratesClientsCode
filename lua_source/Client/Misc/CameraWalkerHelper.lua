
local luaclass = require("luaclass")
local CameraWalkerHelper   = luaclass("CameraWalkerHelper")

local MathUtil 	= require("MathUtil")
local SelfTimerHelperClass = require("SelfTimerHelper")

local ZOOM_INTERVAL = 1.0 / 60.0

local ZoomState = {
	In = 0,
	Out = 1,
}

CameraWalkerHelper.pCameraActor = nil
CameraWalkerHelper.pDirectionLightActor = nil
CameraWalkerHelper.ZoomTimer = nil
CameraWalkerHelper.ZoomDuration = 0
CameraWalkerHelper.ZoomState = ZoomState.Out
CameraWalkerHelper.ZoomStateDef = ZoomState
CameraWalkerHelper.InitialLight = nil
CameraWalkerHelper.TimerHelper = SelfTimerHelperClass()
CameraWalkerHelper.CurrentRotator = {
	Pitch = 0,
	Yaw = 0,
}
CameraWalkerHelper.InitialRotator = {
	Pitch = 0,
	Yaw = 0,
}

function CameraWalkerHelper:GetCurrentZoomState()
    return self.ZoomState
end

function CameraWalkerHelper:SetCamera(Camera, DirectionLightActor, CameraIni, FocusPosition)
    self.pCameraActor = Camera
    self.pDirectionLightActor = DirectionLightActor
    if Camera then
        self.tbConfig = { }
        local InitialPosition = self.pCameraActor:K2_GetActorLocation()
        self.ZoomState = ZoomState.Out
        local DirFromCameraToLookAt = KismetMathLibrary.Subtract_VectorVector(FocusPosition, InitialPosition)
        self.tbConfig.max_camera_arm_length = KismetMathLibrary.VSize(DirFromCameraToLookAt)
        local InitialRotator = KismetMathLibrary.Conv_VectorToRotator(DirFromCameraToLookAt)
        self.CurrentRotator.Yaw = math.floor(InitialRotator.Yaw)
        self.CurrentRotator.Pitch = math.floor(InitialRotator.Pitch)

        self.InitialRotator.Yaw = self.CurrentRotator.Yaw
        self.InitialRotator.Pitch = self.CurrentRotator.Pitch

        self.tbConfig.min_camera_arm_length = CameraIni.nMinArmLength
        self.tbConfig.max_pitch_degree = CameraIni.nMaxPitchOffset + self.CurrentRotator.Pitch
        self.tbConfig.min_pitch_degree = CameraIni.nMinPitchOffset + self.CurrentRotator.Pitch
        self.tbConfig.max_yaw_degree = CameraIni.nMaxYawOffset + self.CurrentRotator.Yaw
        self.tbConfig.min_yaw_degree = CameraIni.nMinYawOffset + self.CurrentRotator.Yaw
        self.tbConfig.max_shadow_distance = CameraIni.nMaxLightShadowDistance
        self.tbConfig.min_shadow_distance = CameraIni.nMinLightShadowDistance
        self.tbConfig.zoom_duration = CameraIni.fZoomTime
        self.tbConfig.zoomout_focus_position = FocusPosition

        if self.pDirectionLightActor then
            self.InitialLight = self.pDirectionLightActor.LightComponent.DynamicShadowDistanceStationaryLight
            self.pDirectionLightActor.LightComponent:SetDynamicShadowDistanceStationaryLight(self.tbConfig.max_shadow_distance)
        end

        self:SetCameraPositionWithArmLengthAndLookAt(self.tbConfig.max_camera_arm_length, FocusPosition)
    --    self.pCameraActor:K2_SetActorRotation(Rotator{Pitch = self.CurrentRotator.Pitch, Yaw = self.CurrentRotator.Yaw, Roll = 0}, false)
    end
end

function CameraWalkerHelper:RestoreLight()
    if self.pDirectionLightActor and self.InitialLight then
        self.pDirectionLightActor.LightComponent:SetDynamicShadowDistanceStationaryLight(self.InitialLight)
    end
end

function CameraWalkerHelper:UpdateCamera()
    local tbConfig = self.tbConfig
	if self.ZoomState == ZoomState.Out then
		self:SetCameraPositionWithArmLengthAndLookAt(tbConfig.max_camera_arm_length, tbConfig.zoomout_focus_position)
	else
		self:SetCameraPositionWithArmLengthAndLookAt(tbConfig.min_camera_arm_length, tbConfig.zoomin_focus_position)
    end
    if self.pDirectionLightActor then
        if self.ZoomState == ZoomState.Out then
            self.pDirectionLightActor.LightComponent:SetDynamicShadowDistanceStationaryLight(tbConfig.max_shadow_distance)
        else
            self.pDirectionLightActor.LightComponent:SetDynamicShadowDistanceStationaryLight(tbConfig.min_shadow_distance)
        end
    end
end

function CameraWalkerHelper:SetCameraPositionWithArmLengthAndLookAt(ArmLength, LookAt)
	local CameraTargetRotator = Rotator{Pitch = self.CurrentRotator.Pitch, Yaw = self.CurrentRotator.Yaw, Roll = 0}
	local ForwardVector = KismetMathLibrary.Conv_RotatorToVector(CameraTargetRotator)
	ForwardVector = KismetMathLibrary.Normal(ForwardVector, GDefaultTolerance)
	ForwardVector = KismetMathLibrary.Multiply_VectorFloat(ForwardVector, -ArmLength)
    local CameraTargetPosition =  KismetMathLibrary.Add_VectorVector(LookAt, ForwardVector)
    if self.pCameraActor then
        self.pCameraActor:K2_SetActorLocationAndRotation(CameraTargetPosition, CameraTargetRotator)
    end
end


function CameraWalkerHelper:IsZooming()
	return self.ZoomTimer
end

function CameraWalkerHelper:StopZoom()
	if self.ZoomTimer then
		self.TimerHelper:ClearTimer(self.ZoomTimer)
		self.ZoomTimer = nil
	end
	self.ZoomDuration = 0
end



function CameraWalkerHelper:RotateCamera(Yaw, Pitch)
	if self:IsZooming() or (Yaw == 0 and Pitch == 0) then
		return
    end
    local tbConfig = self.tbConfig
    local max_yaw_change_per_move = tbConfig.max_yaw_change_per_move or 10
    local max_pitch_change_per_move = tbConfig.max_pitch_change_per_move or 10
	Yaw = MathUtil.Clamp(Yaw, -max_yaw_change_per_move, max_yaw_change_per_move)
    Pitch = MathUtil.Clamp(Pitch, -max_pitch_change_per_move, max_pitch_change_per_move)
    self:SetYawAndPitch(self.CurrentRotator.Yaw + Yaw, self.CurrentRotator.Pitch + Pitch)
end

local function Lerp(tbFrom, tbTo, Alpha)
    local EaseFunc = EEasingFunc.EaseOut
    local tbRet = { }
    for i=1,#tbFrom do
        local tbF = tbFrom[i]
        local tbT = tbTo[i]
        local Key = tbF.Key
        if tbF.IsVector then
            local LerpedVector = KismetMathLibrary.VEase(tbF.Value, tbT.Value, Alpha, EaseFunc, 2, 2)
            tbRet[Key] = LerpedVector
        else
            local LerpedValue = KismetMathLibrary.Ease(tbF.Value, tbT.Value, Alpha, EaseFunc, 2, 2)
            tbRet[Key] = LerpedValue
        end
    end
    return tbRet
end

function CameraWalkerHelper:ZoomUpdate()
    local tbConfig = self.tbConfig
	self.ZoomDuration = self.ZoomDuration + ZOOM_INTERVAL
	if self.ZoomDuration >= tbConfig.zoom_duration then
		self:UpdateCamera()
		self:StopZoom()
	else
        local Alpha = MathUtil.Clamp(self.ZoomDuration / tbConfig.zoom_duration, 0, 1)
        local tbLerp = Lerp(self.LerpFrom, self.LerpTo, Alpha)

		if tbLerp.Pitch and tbLerp.Yaw then
			self.CurrentRotator.Yaw = tbLerp.Yaw
			self.CurrentRotator.Pitch = tbLerp.Pitch
		end
		if tbLerp.ArmLength and tbLerp.FocusPosition then
			self:SetCameraPositionWithArmLengthAndLookAt(tbLerp.ArmLength, tbLerp.FocusPosition)
		else
			self:UpdateCamera()
		end
		if tbLerp.ShadowDistance and self.pDirectionLightActor then
			self.pDirectionLightActor.LightComponent:SetDynamicShadowDistanceStationaryLight(tbLerp.ShadowDistance)
		end
	end
end

function CameraWalkerHelper:ZoomCamera(NewZoomState)
	if self:IsZooming() then
		return
    end
    if NewZoomState == ZoomState.In then
        if not self.tbConfig.zoomin_focus_position then
            logerror("zoomin_focus_position is not set...")
            return
        end
    end
	if self.ZoomState ~= NewZoomState then
		self.ZoomState = NewZoomState
        self:StopZoom()
        local tbConfig = self.tbConfig
        if self.ZoomState == ZoomState.Out then
			self.LerpFrom = {
                { Key = "FocusPosition", Value = tbConfig.zoomin_focus_position, IsVector = true },
                { Key = "ArmLength", Value = tbConfig.min_camera_arm_length },
                { Key = "ShadowDistance", Value = tbConfig.min_shadow_distance },
			}
			self.LerpTo = {
                { Key = "FocusPosition", Value = tbConfig.zoomout_focus_position, IsVector = true },
                { Key = "ArmLength", Value = tbConfig.max_camera_arm_length },
                { Key = "ShadowDistance", Value = tbConfig.max_shadow_distance },
			}
		else
			self.LerpFrom = {
                { Key = "FocusPosition", Value = tbConfig.zoomout_focus_position, IsVector = true },
                { Key = "ArmLength", Value = tbConfig.max_camera_arm_length },
                { Key = "ShadowDistance", Value = tbConfig.max_shadow_distance },
			}
			self.LerpTo = {
                { Key = "FocusPosition", Value = tbConfig.zoomin_focus_position, IsVector = true },
                { Key = "ArmLength", Value = tbConfig.min_camera_arm_length },
                { Key = "ShadowDistance", Value = tbConfig.min_shadow_distance },
			}
		end
		self.ZoomTimer = self.TimerHelper:NewTimerMethod(self, self.ZoomUpdate, ZOOM_INTERVAL, true)
    end
end

function CameraWalkerHelper:RestoreCamera()
    if self:IsZooming() then
		return
    end
    local tbConfig = self.tbConfig
	if self.ZoomState == ZoomState.Out then
		self.LerpFrom = {
            { Key = "Yaw", Value = self.CurrentRotator.Yaw },
			{ Key = "Pitch", Value = self.CurrentRotator.Pitch },
		}
		self.LerpTo = {
            { Key = "Yaw", Value = self.InitialRotator.Yaw },
			{ Key = "Pitch", Value = self.InitialRotator.Pitch },
		}
	else
		self.LerpFrom = {
			{ Key = "Yaw", Value = self.CurrentRotator.Yaw },
			{ Key = "Pitch", Value = self.CurrentRotator.Pitch },
			{ Key = "FocusPosition", Value = tbConfig.zoomin_focus_position, IsVector = true },
            { Key = "ArmLength", Value = tbConfig.min_camera_arm_length },
            { Key = "ShadowDistance", Value = tbConfig.min_shadow_distance },
		}
		self.LerpTo = {
			{ Key = "Yaw", Value = self.InitialRotator.Yaw },
			{ Key = "Pitch", Value = self.InitialRotator.Pitch },
            { Key = "FocusPosition", Value = tbConfig.zoomout_focus_position, IsVector = true },
            { Key = "ArmLength", Value = tbConfig.max_camera_arm_length },
            { Key = "ShadowDistance", Value = tbConfig.max_shadow_distance },
		}
		self.ZoomState = ZoomState.Out
	end
	self.ZoomTimer = self.TimerHelper:NewTimerMethod(self, self.ZoomUpdate, ZOOM_INTERVAL, true)
end

function CameraWalkerHelper:SetZoomFocusPosition(ZoomInFocusPosition, ZoomOutFocusPosition)
    self.tbConfig.zoomin_focus_position  = ZoomInFocusPosition
    self.tbConfig.zoomout_focus_position = ZoomOutFocusPosition
end

function CameraWalkerHelper:SetYawAndPitch(Yaw, Pitch)
    local tbConfig = self.tbConfig
    local TargetYaw = MathUtil.Clamp(Yaw, tbConfig.min_yaw_degree, tbConfig.max_yaw_degree)
	local TargetPitch = MathUtil.Clamp(Pitch, tbConfig.min_pitch_degree, tbConfig.max_pitch_degree)
	self.CurrentRotator.Yaw = TargetYaw
	self.CurrentRotator.Pitch = TargetPitch
	self:UpdateCamera()
end

function CameraWalkerHelper:TearDown()
    self:StopZoom()
    self:RestoreLight()
    if self.pCameraActor then
        local tbConfig = self.tbConfig
        self.CurrentRotator.Yaw = self.InitialRotator.Yaw
		self.CurrentRotator.Pitch = self.InitialRotator.Pitch
        self:SetCameraPositionWithArmLengthAndLookAt(tbConfig.max_camera_arm_length, tbConfig.zoomout_focus_position)
    end
end

return CameraWalkerHelper