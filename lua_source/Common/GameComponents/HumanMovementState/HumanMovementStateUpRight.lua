local luaclass = require("luaclass")
local HumanMovementStateBase = dynamic_require("HumanMovementStateBase")
local HumanMovementStateUpRight = luaclass("HumanMovementStateUpRight", HumanMovementStateBase)
local HumanMovementStateType = require("HumanMovementStateType")
local HumanMovementSpeedDataTable = require("HumanMovementSpeedDataTable")

function HumanMovementStateUpRight:Active(tbParams)
    local pUEActor = self.pOwnerActor
    pUEActor.bCanFalling = true
    self:ChangeCapsule()
    self:BlendCameraWithTime()
    local nLastState = self.Owner:GetLastState()
    if nLastState == HumanMovementStateType.Swimming then
        local CharacterMovement = pUEActor.CharacterMovement
        CharacterMovement:SetHumanPreSwimState(true)
        --CharacterMovement:SetMovementMode(EMovementMode.MOVE_Walking, 0)
        --logdebug("SetHumanPreSwimState true1")
    end

    --[[ 跳伞结束时会在HumanMovementStateParachuting:UnActive中
    把BaseSpeed设置为0以解决跳伞落地时有概率出现移动速度过快的问题，切成站立状态时需设置回来，
    否则PC端键盘操作时跳伞结束后可能出现无法移动的现象]]
    self.Owner:SetBaseSpeed(HumanMovementSpeedDataTable:GetTemplate(HumanMovementStateType.UpRight_State).nSpeed)
end

return HumanMovementStateUpRight