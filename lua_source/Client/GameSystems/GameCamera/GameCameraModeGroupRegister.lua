local GameCameraModeGroupRegister = {}
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")

-- GameCameraSystem:Register( nGroupId, nGroupCameraParams, nGroupCameraModes)
--nGroupCameraParams
-- @nArmLength     摇臂长度
-- @ArmRotaion    摇臂的角度
-- @ArmLocation   摇臂的位置
-- @SocketOffset  摇臂上相机的位置
-- @CameraRotation 相机的角度
-- @nPitchViewMax  仰角最大值
-- @nPitchViewMin  俯角最小值
--nGroupCameraModes
-- @ModeChangeTargetParam : szAimSocket 瞄准时相机的挂点 AimOffset 相机的偏移
-- @ModeHandleMoveParam : nMoveX 水平移动 nMoveY 垂直移动
-- @ModeOffsetMoveParam : MoveOffset 偏移 nBlendTime 过渡时间 bNeedBlend 是否过渡
-- @ModeShakeParam : nOscillationDuration 震动周期 nOscillationBlendInTime 阵容进入时间  nOscillationBlendOutTime 震动恢复出来时间 RotOscillation 相机震动 x y z三个方向的分量
function GameCameraModeGroupRegister:RegisterGameCameraModeGroup(GameCameraSystem)
    local GroupDef = GameCameraModeGroupDef

    --以下参数 均为有效参数，如果不需要，就不用填，Register里面会用默认值
    --Mode里面的参数 为默认参数， ActiveCameraMode的时候，也可以传入其他参数来替换 默认参数
    GameCameraSystem:Register(
        GroupDef.HumanNormal, 
        { 
            nArmLength = 200, 
            ArmLocation = Vector{X = 0, Y = 0, Z = 75},       
            SocketOffset = Vector{X = 0, Y = 25, Z = 60},
            CameraRotation = Rotator{Pitch = -10, Yaw = 0, Roll = 0},
            nPitchViewMax = 60,
            nPitchViewMin = -70
        },
        {}
    )

    GameCameraSystem:Register(
        GroupDef.ShipNormal, 
        { 
            nArmLength = 4700, 
            ArmLocation = Vector{X = 0, Y = 0, Z = 1730},       
            nPitchViewMax = 20,
            nPitchViewMin = -50
        },
        {}
    )

    GameCameraSystem:Register(
        GroupDef.HumanFreeView, nil, nil
    )

    GameCameraSystem:Register(
        GroupDef.HumanAiming, nil, nil
    )

    GameCameraSystem:Register(
        GroupDef.ShipAiming, nil, nil
    )
  
    GameCameraSystem:Register(GroupDef.ViewDeadBoxHuman, {}, {})
    GameCameraSystem:Register(GroupDef.ViewDeadBoxShip, {}, {})
    GameCameraSystem:Register(GroupDef.ViewShipKiller, {}, {})
    GameCameraSystem:Register(GroupDef.ViewHumanKiller, {}, {})

    GameCameraSystem:Register(GroupDef.BotHuman, 
        { 
            nArmLength = 200, 
            ArmLocation = Vector{X = 0, Y = 0, Z = 130},       
            SocketOffset = Vector{X = 0, Y = 30, Z = 0},
            CameraRotation = Rotator{Pitch = -10, Yaw = 0, Roll = 0},
            nPitchViewMax = 60,
            nPitchViewMin = -70
        },
        {}
    )
    GameCameraSystem:Register(GroupDef.BotShip, 
        { 
            nArmLength = 4700, 
            ArmLocation = Vector{X = 0, Y = 0, Z = 1730},       
            nPitchViewMax = 20,
            nPitchViewMin = -50
        },
        {}
    )

    GameCameraSystem:Register(GroupDef.ViewTeammateHuman, {}, {})
    GameCameraSystem:Register(GroupDef.ViewTeammateShip, {}, {})

    GameCameraSystem:Register(GroupDef.NewParachuteShipping, {}, {})
    GameCameraSystem:Register(GroupDef.NewParachuteLaunchFocus, {}, {})
    GameCameraSystem:Register(
        GroupDef.NewParachuteLaunchPlayer, 
        { 
            nArmLength = 600, 
            ArmRotation = Rotator{Pitch = -40, Yaw = 0, Roll = 0},
            ArmLocation = Vector{X = 0, Y = 0, Z = 0},       
            SocketOffset = Vector{X = 0, Y = 0, Z = 0},
            CameraRotation = Rotator{Pitch = 0, Yaw = 0, Roll = 180},
            nPitchViewMax = 20,
            nPitchViewMin = -88
        },
        {}
    )

    GameCameraSystem:Register(GroupDef.NewParachuteTopPoint, {}, {})
    GameCameraSystem:Register(GroupDef.NewParachuteOpenParachute, {}, {})
    GameCameraSystem:Register(GroupDef.HumanSwimming, {}, {})
    GameCameraSystem:Register(GroupDef.VehicleView, {}, {})
    
end

function GameCameraModeGroupRegister:RegisterHomelandCameraModeGroup(GameCameraSystem)
    local GroupDef = GameCameraModeGroupDef
    GameCameraSystem:Register(
        GroupDef.HumanNormal, 
        { 
            nArmLength = 200, 
            ArmLocation = Vector{X = 0, Y = 0, Z = 75},       
            SocketOffset = Vector{X = 0, Y = 25, Z = 60},
            CameraRotation = Rotator{Pitch = -10, Yaw = 0, Roll = 0},
            nPitchViewMax = 60,
            nPitchViewMin = -70
        },
        {}
    )
    GameCameraSystem:Register(GroupDef.BuildingView, {}, {})
end

return GameCameraModeGroupRegister