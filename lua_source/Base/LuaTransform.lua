local LuaVector = require("Vector")
local LuaQuaternion = require("Quaternion")
local LuaRotator = require("Rotator")

local LuaTransform = { }

LuaTransform.__index = LuaTransform

local assert = assert


local function new(tbTranslation, tbRotation, tbScale3D)
    local tbQuaternion = tbRotation
    if LuaRotator.IsRotator(tbRotation) then
        tbQuaternion = LuaQuaternion.FromRotator(tbRotation)
    end
    return setmetatable({ translation = tbTranslation or LuaVector(0, 0, 0), 
    rotation = tbQuaternion or LuaQuaternion(0, 0, 0, 1), 
    scale = tbScale3D or LuaVector(1, 1, 1) }, LuaTransform)
end


setmetatable(LuaTransform, { __call = function(self, tbTranslation, tbRotation, tbScale3D)
    return new(tbTranslation, tbRotation, tbScale3D)
end })

local function istransform(v)
    return type(v) == "table" and getmetatable(v) == LuaTransform
end

LuaTransform.IsTransform = istransform

function LuaTransform.__mul(a,b)
    assert(istransform(a) and istransform(b), "Mul: wrong argument types (can not mul two LuaTransform)")
    if a.scale.x > 0 and a.scale.y > 0 and a.scale.z > 0 and b.scale.x > 0 and b.scale.y > 0 and b.scale.z > 0 then
        local newTranslation = b.rotation * (b.scale * a.translation) + b.translation
        local newRotation = b.rotation * a.rotation
        local newScale = a.scale * b.scale
        return new(newTranslation, newRotation, newScale)
    else
        logerror("LuaTransform mul must make sure two LuaTransform`s scale are > 0")
    end
end


function LuaTransform.__eq(a,b)
	return a.translation == b.translation and a.rotation == b.rotation and a.scale == b.scale
end


function LuaTransform:__tostring()
	return "( t=".. tostring(self.translation) ..",r="..tostring(self.rotation)..",s="..tostring(self.scale)..")"
end

function LuaTransform.ToUETransform(tbTransform)
    local pT = tbTransform.translation:ToUEVector()
    local pS = tbTransform.scale:ToUEVector()
    local tbRotation = LuaRotator.Quaternion(tbTransform.rotation)
    local pR = tbRotation:ToUERotator()
    return KismetMathLibrary.MakeTransform(pT, pR, pS)
end

function LuaTransform.FromUETransform(pTransform)
    local pLocation, pRotation, pScale = KismetMathLibrary.BreakTransform(pTransform)
    local tbTranslation = LuaVector.FromUEVector(pLocation)
    local tbQuaternion = LuaQuaternion.FromRotator(LuaRotator(pRotation.Pitch, pRotation.Yaw, pRotation.Roll))
    local tbScale = LuaVector.FromUEVector(pScale)
    return new(tbTranslation, tbQuaternion, tbScale)
end

return LuaTransform