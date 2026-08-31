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
local TransporterCameraDataTable = {}

local StringUtil = require("StringUtil")

TransporterCameraDataTable.szFileName = "common/ffa/parachuting/transporter_camera_cfg.tab"

function TransporterCameraDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId",                 "id",               -1,  Parser.TypeInt)
    Parser:Define("szDesc",              "des",              "",  Parser.TypeString)
    Parser:Define("nArmLength",          "arm_length",       -1,  Parser.TypeFloat)
    Parser:Define("nPitchMax",           "pitch_max",        -1,  Parser.TypeFloat)
    Parser:Define("nPitchMin",           "pitch_min",        -1,  Parser.TypeFloat)
    Parser:Define("nInitFov",            "init_fov",       -1,  Parser.TypeFloat)
end

function TransporterCameraDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)

    local szParStr = Parser:Get("arm_location", nil, Parser.TypeString)
    tbNewTemplate.tbArmLocation = StringUtil.ParseDataByComma(szParStr)

    szParStr = Parser:Get("arm_rotation", nil, Parser.TypeString)
    tbNewTemplate.tbArmRotation = StringUtil.ParseDataByComma(szParStr)

    szParStr = Parser:Get("camera_location", nil, Parser.TypeString)
    tbNewTemplate.tbCameraLocation = StringUtil.ParseDataByComma(szParStr)

    szParStr = Parser:Get("camera_rotation", nil, Parser.TypeString)
    tbNewTemplate.tbCameraRotation = StringUtil.ParseDataByComma(szParStr)

    return true
end

-- [EXPORT BEGIN]
local function ToRotator(tbIn)
    return Rotator{Pitch = tonumber(tbIn[1]), Yaw = tonumber(tbIn[2]), Roll = tonumber(tbIn[3])}
end  

local function ToVector(tbIn)
    return Vector{X = tonumber(tbIn[1]), Y = tonumber(tbIn[2]), Z = tonumber(tbIn[3])}
end

function TransporterCameraDataTable:GetTemplate(nTemplateId)
    return self.tbContainer[nTemplateId]
end

function TransporterCameraDataTable:GetTransporterCameraParams(nDummyId)
    local tbDummyConfig = self:GetTemplate(nDummyId)
    if tbDummyConfig then  
        return{
            nArmLength = tbDummyConfig.nArmLength,
            ArmLocation = ToVector(tbDummyConfig.tbArmLocation),
            ArmRotation = ToRotator(tbDummyConfig.tbArmRotation),
            SocketOffset = ToVector(tbDummyConfig.tbCameraLocation),
            CameraRotation = ToRotator(tbDummyConfig.tbCameraRotation),
            nPitchViewMax = tbDummyConfig.nPitchMax,
            nPitchViewMin = tbDummyConfig.nPitchMin,
            nFov = tbDummyConfig.nInitFov
        } 
    end
    return nil
end
-- [EXPORT END]

return TransporterCameraDataTable
