local CurveDef = {}

CurveDef.CurveIds =
{
    CURVE_DISTANCE_TORADIUS_PERCENT = 1,--用于辅助瞄准 修改辅助瞄准球的半径
    CURVE_LOCATION_TORADIUS_DAMAGE  = 2,--用于新的范围伤害衰减计算
}

CurveDef.Type = 
{
    FLOAT           = 1, 
    LINEAR_COLOR    = 2, 
    VECTOR          = 3
}

return CurveDef