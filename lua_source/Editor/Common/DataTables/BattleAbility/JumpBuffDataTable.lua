-----------------------------------------------------
--File Name    : JumpBuffDataTable.lua
--Author       : Chanyixin
--Description  : 战斗跳跃Buff配置表
-----------------------------------------------------

local JumpBuffDataTable = {}

JumpBuffDataTable.szFileName = "common/battle_ability/jump_buff.tab"

function JumpBuffDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId"                 , "id"                      , -1    , Parser.TypeInt)
    Parser:Define("nSpeedChange"        , "speed_change"            , -1    , Parser.TypeFloat)
    Parser:Define("nZVelocityChange"    , "z_velocity_change"       , -1    , Parser.TypeFloat)
    Parser:Define("nGravityChange"      , "gravity_change"          , -1    , Parser.TypeFloat)
    Parser:Define("nOriginSpeedChange"  , "origin_speed_change"     , -1    , Parser.TypeFloat)
    Parser:Define("nAirDragChange"      , "air_drag_change"         , -1    , Parser.TypeFloat)
    Parser:Define("nAccelChange"        , "accel_change"            , -1    , Parser.TypeFloat)
end

-- [EXPORT BEGIN]
function JumpBuffDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end

-- [EXPORT END]

return JumpBuffDataTable
