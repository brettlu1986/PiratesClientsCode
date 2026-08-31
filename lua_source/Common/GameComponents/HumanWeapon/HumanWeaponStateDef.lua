local NameToValue = {}
local ValueToString = {}
local MaxValue = 0
local function Define(szName)
    NameToValue[szName] = MaxValue
    ValueToString[MaxValue] = szName
    MaxValue = MaxValue + 1
end
NameToValue.v2s = function(value)
    return value == nil and "nil" or ValueToString[value]
end
local function Init()
    Define("NONE")          -- 初始值
    Define("UNHOLDED")      -- 已经放回背上
    Define("UNHOLDING")     -- 正在放回背上
    Define("HOLDED")        -- 已经持枪
    Define("HOLDING")       -- 从背上拿出来准备持枪
    Define("RELOADING")     -- 上子弹中
    Define("AIMING")        -- 瞄准状态
    Define("ATTACKING")     -- 开火状态，开枪或者近战武器攻击
end
Init()
return NameToValue