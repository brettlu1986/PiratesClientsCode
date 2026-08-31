--[[
    DataTable类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    tbContainer: table
    OnEditorParseLine： 解析函数，参数Parser

    可选的变量与函数
    OnEditorParseFinished: 参数无，本DataTable读取完毕后触发
    OnGameRequired: 参数无，游戏运行时第一次require时触发
    OnEditorDefine: 定义导出参数    自定义导出标签：
         导出单行：-- [EXPORT]
         导出多行：-- [EXPORT BEGIN] 和 -- [EXPORT END]
--]]
local HumanCameraDataTable = {}

local StringUtil = require("StringUtil")

HumanCameraDataTable.szFileName = "common/human/human_camera.tab"

-- [EXPORT BEGIN]
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local HumanMovementStateType = require("HumanMovementStateType")

local StateType = HumanMovementStateType
local HumanState = GameCameraModeGroupDef.HumanState
local ZERO_VECTOR = Vector{X = 0, Y = 0, Z = 0}
-- [EXPORT END]

function HumanCameraDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId",                  "id",                    -1,  Parser.TypeInt)
    Parser:Define("nArmLength",           "arm_length",            -1,  Parser.TypeFloat)
    Parser:Define("nPitchMoveScale",      "pitch_move_scale",      -1,  Parser.TypeFloat)
    Parser:Define("nYawMoveScale",        "yaw_move_scale",        -1,  Parser.TypeFloat)
    Parser:Define("nInitFov",             "init_fov",              -1,  Parser.TypeFloat)
    Parser:Define("nUprightPitchMax",     "upright_pitch_max",     -1,  Parser.TypeFloat)
    Parser:Define("nUprightPitchMin",     "upright_pitch_min",     -1,  Parser.TypeFloat)
    Parser:Define("nCrouchPitchMax",      "crouch_pitch_max",      -1,  Parser.TypeFloat)
    Parser:Define("nCrouchPitchMin",      "crouch_pitch_min",      -1,  Parser.TypeFloat)
    Parser:Define("nCrawlPitchMax",       "crawl_pitch_max",       -1,  Parser.TypeFloat)
    Parser:Define("nCrawlPitchMin",       "crawl_pitch_min",       -1,  Parser.TypeFloat)
    Parser:Define("nLookUpLimit",         "lookup_limit",          -1,  Parser.TypeFloat)
    Parser:Define("nLookDownLimit",       "lookdown_limit",        -1,  Parser.TypeFloat)
end

function HumanCameraDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)

    local szParStr = Parser:Get("arm_location", nil, Parser.TypeString)
    tbNewTemplate.tbArmLocation = StringUtil.ParseDataByComma(szParStr)

    szParStr = Parser:Get("camera_location", nil, Parser.TypeString)
    tbNewTemplate.tbCameraLocation = StringUtil.ParseDataByComma(szParStr)

    szParStr = Parser:Get("camera_rotation", nil, Parser.TypeString)
    tbNewTemplate.tbCameraRotation = StringUtil.ParseDataByComma(szParStr)

    szParStr = Parser:Get("to_crouch_offset", nil, Parser.TypeString)
    tbNewTemplate.tbToCrouchOffset = StringUtil.ParseDataByComma(szParStr)

    szParStr = Parser:Get("to_dying_offset", nil, Parser.TypeString)
    tbNewTemplate.tbToDyingOffset = StringUtil.ParseDataByComma(szParStr)

    szParStr = Parser:Get("to_crawl_offset", nil, Parser.TypeString)
    tbNewTemplate.tbToCrawlOffset = StringUtil.ParseDataByComma(szParStr)

    return true
end

-- [EXPORT BEGIN]
local function ToRotator(tbIn)
    return Rotator{Pitch = tonumber(tbIn[1]), Yaw = tonumber(tbIn[2]), Roll = tonumber(tbIn[3])}
end  

local function ToVector(tbIn)
    return Vector{X = tonumber(tbIn[1]), Y = tonumber(tbIn[2]), Z = tonumber(tbIn[3])}
end

function HumanCameraDataTable:GetTemplate(nState)
    return self.tbContainer[nState]
end

function HumanCameraDataTable:GetHumanCameraParam(nState)
    local tbParam = self:GetTemplate(nState)
    if tbParam then  
        return { 
            nArmLength = tbParam.nArmLength, 
            ArmLocation = ToVector(tbParam.tbArmLocation),
            SocketOffset = ToVector(tbParam.tbCameraLocation),
            CameraRotation = ToRotator(tbParam.tbCameraRotation),
            nPitchViewMax = tbParam.nUprightPitchMax,
            nPitchViewMin = tbParam.nUprightPitchMin,
            nLookUpLimit = tbParam.nLookUpLimit,
            nLookDownLimit = tbParam.nLookDownLimit,
            nFov = tbParam.nInitFov
        }
    end
    return nil
end

function HumanCameraDataTable:GetMovementCameraOffset(nCurrentMovementState)
    local tbParam = self:GetTemplate(HumanState.Normal)
    if nCurrentMovementState == StateType.UpRight_State then 
        return ZERO_VECTOR
    elseif nCurrentMovementState == StateType.Crouch_State then  
        return ToVector(tbParam.tbToCrouchOffset)
    elseif nCurrentMovementState == StateType.Dying_State then
        return ToVector(tbParam.tbToDyingOffset)
    elseif nCurrentMovementState == StateType.Crawl_State then  
        return ToVector(tbParam.tbToCrawlOffset)
    end
    return ZERO_VECTOR
end

function HumanCameraDataTable:GetMovementCameraPitchLimit(nCurrentMovementState)
    local tbParam = self:GetTemplate(HumanState.Normal)
    if nCurrentMovementState == StateType.UpRight_State then 
        return tbParam.nUprightPitchMax, tbParam.nUprightPitchMin
    elseif nCurrentMovementState == StateType.Crouch_State 
        or nCurrentMovementState == StateType.Dying_State then  
        return tbParam.nCrouchPitchMax, tbParam.nCrouchPitchMin
    elseif nCurrentMovementState == StateType.Crawl_State then  
        return tbParam.nCrawlPitchMax, tbParam.nCrawlPitchMin
    end
    return tbParam.nUprightPitchMax, tbParam.nUprightPitchMin
end

function HumanCameraDataTable:GetCrouchSocketOffset()
    local tbParam = self:GetTemplate(HumanState.Normal)
    local VectorOrg = ToVector(tbParam.tbCameraLocation)
    local VectorOffset = ToVector(tbParam.tbToCrouchOffset)
    return Vector{ X = VectorOrg.X + VectorOffset.X, Y = VectorOrg.Y + VectorOffset.Y, Z = VectorOrg.Z + VectorOffset.Z }
end


function HumanCameraDataTable:GetCrawlSocketOffset()
    local tbParam = self:GetTemplate(HumanState.Normal)
    local VectorOrg = ToVector(tbParam.tbCameraLocation)
    local VectorOffset = ToVector(tbParam.tbToCrawlOffset)
    return Vector{ X = VectorOrg.X + VectorOffset.X, Y = VectorOrg.Y + VectorOffset.Y, Z = VectorOrg.Z + VectorOffset.Z }
end

function HumanCameraDataTable:GetDyingSocketOffset()
    local tbParam = self:GetTemplate(HumanState.Normal)
    local VectorOrg = ToVector(tbParam.tbCameraLocation)
    local VectorOffset = ToVector(tbParam.tbToDyingOffset)
    return Vector{ X = VectorOrg.X + VectorOffset.X, Y = VectorOrg.Y + VectorOffset.Y, Z = VectorOrg.Z + VectorOffset.Z }
end

-- [EXPORT END]

return HumanCameraDataTable
