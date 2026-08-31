local luaclass = require ("luaclass")
local UPMapObjForBornPoint = require("UPMapObjForBornPoint")
local UPMapObjForSelfBornPoint = luaclass("UPMapObjForSelfBornPoint", UPMapObjForBornPoint)

function UPMapObjForSelfBornPoint:PlaySelectAnimation()
    self:StopAnimation("animSelectPoint")
    self:PlayAnimation("animSelectPoint", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

return UPMapObjForSelfBornPoint
