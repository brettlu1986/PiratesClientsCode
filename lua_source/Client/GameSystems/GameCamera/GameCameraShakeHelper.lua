local GameCameraShakeHelper = {}
local GameShakeDataTable = require("GameShakeDataTable")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local MathUtil = require("MathUtil")

local RandomFloat = MathUtil.RandomFloat

local TargetAngle = Vector()
local RecoverAngle = Vector()
local PosOffset = Vector()

local function RandomNegative()
    return KismetMathLibrary.RandomBool() and 1 or -1
end

function GameCameraShakeHelper.GameShake(nShakeId)
    local tbShakeInfo = GameShakeDataTable:GetTemplate(nShakeId)
    if not tbShakeInfo then  
        error("Game ShakeId is not defined in game_shake.tab".. nShakeId)
        return 
    end

    -- log("values :",tbShakeInfo.nVLowerAngle,tbShakeInfo.nVUpperAngle,
    --     tbShakeInfo.nHLowerAngle, tbShakeInfo.nHUpperAngle,
    --     tbShakeInfo.nLowerRollAngle, tbShakeInfo.nUpperRollAngle,
    --     tbShakeInfo.nLowerHOffset, tbShakeInfo.nUpperHOffset,
    --     tbShakeInfo.nLowerVOffset, tbShakeInfo.nUpperVOffset,
    --     tbShakeInfo.nLowerFOffset, tbShakeInfo.nUpperFOffset,
    --     tbShakeInfo.nShakeCountMin, tbShakeInfo.nShakeCountMax,
    --     tbShakeInfo.nLowerFov, tbShakeInfo.nUpperFov, tbShakeInfo.nDecayParam
    -- )
    --垂直方向
    TargetAngle.Y = RandomFloat(tbShakeInfo.nVLowerAngle, tbShakeInfo.nVUpperAngle) * RandomNegative()
    --水平方向
    TargetAngle.X = RandomFloat(tbShakeInfo.nHLowerAngle, tbShakeInfo.nHUpperAngle) * RandomNegative()
    --旋转
    TargetAngle.Z = RandomFloat(tbShakeInfo.nLowerRollAngle, tbShakeInfo.nUpperRollAngle)

    RecoverAngle.X = 0
    RecoverAngle.Y = 0
    RecoverAngle.Z = 0

    --水平方向 
    PosOffset.Y = RandomFloat(tbShakeInfo.nLowerHOffset, tbShakeInfo.nUpperHOffset) * RandomNegative()
    --垂直方向 
    PosOffset.Z = RandomFloat(tbShakeInfo.nLowerVOffset, tbShakeInfo.nUpperVOffset) * RandomNegative()
    --前进方向 
    PosOffset.X = RandomFloat(tbShakeInfo.nLowerFOffset, tbShakeInfo.nUpperFOffset) 

    local nFov = RandomFloat(tbShakeInfo.nLowerFov, tbShakeInfo.nUpperFov)
    local nDecayParam = tbShakeInfo.nDecayParam
    local nShakeCount = math.random(tbShakeInfo.nShakeCountMin, tbShakeInfo.nShakeCountMax)

    -- log("target values :", TargetAngle.X, TargetAngle.Y, TargetAngle.Z, PosOffset.X, PosOffset.Y, PosOffset.Z, nFov, nShakeCount, nDecayParam)
    EventManager:OnFireEvent(ClientEventDef.EV_FIRE_CAMERA_SHAKE, TargetAngle, RecoverAngle, PosOffset, tbShakeInfo.nRecoilDuration, nFov, nDecayParam, nShakeCount, false, false, false)
end


return GameCameraShakeHelper