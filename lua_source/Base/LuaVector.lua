--[[
    local LuaVector = require("LuaVector")
    local v1 = LuaVector(4,4,4)
    local v2 = LuaVector(2,2,2)
    local BaseUtil = require("BaseUtil")
    BaseUtil:PrintTable(v1 + v2, 3)
    BaseUtil:PrintTable(v1 - v2, 3)
    BaseUtil:PrintTable(v1 * v2, 3)
    BaseUtil:PrintTable(v1 / v2, 3)
    logdebug(-v1)
    logdebug(v1)
    logdebug(v1 == v1)
    logdebug(v1 == v2)
    logdebug(v2:Size())
    logdebug(v2:SizeSquared())
    logdebug(LuaVector.Distance(v1, v2))
    logdebug(LuaVector.Cross(v1, v2))
]]

local LuaVector = { }

local assert = assert
local sqrt, cos, sin, deg2rad, abs = math.sqrt, math.cos, math.sin, math.rad, math.abs
local makeuevector = KismetMathLibrary.MakeVector
local breakuevector = KismetMathLibrary.BreakVector

local function isnumber(n)
	return type(n) == 'number'
end

local function isvector(v)
	return type(v) == 'table' and (getmetatable(v) == LuaVector)
end

local function new(_x, _y, _z)
    return setmetatable({ x = _x or 0, y = _y or 0, z = _z or 0 }, LuaVector)
end

setmetatable(LuaVector, { __call = function(self, x, y, z)
    return new(x, y, z)
end })


--[[
    metatable override
]]
LuaVector.__index = LuaVector

function LuaVector.__unm(v)
	return new(-v.x, -v.y, -v.z)
end

function LuaVector.__eq(v1, v2)
	return (v1.x == v2.x) and (v1.y == v2.y) and (v1.z == v2.z)
end

function LuaVector.__tostring(v)
	return "("..tonumber(v.x)..", "..tonumber(v.y)..", "..tonumber(v.z)..")"
end

function LuaVector.__add(a, b)
	if isnumber(a) then
		return new(a + b.x, a + b.y, a + b.z)
	elseif isnumber(b) then
		return new(a.x + b, a.y + b, a.z + b)
    else
        assert(isvector(a) and isvector(b), "Add: wrong argument types (<LuaVector> expected)")
        return new(a.x + b.x, a.y + b.y, a.z + b.z)
	end
end

function LuaVector.__sub(a, b)
	if isnumber(a) then
		return new(a - b.x, a - b.y, a * b.z)
	elseif isnumber(b) then
		return new(a.x - b, a.y - b, a.z - b)
    else
        assert(isvector(a) and isvector(b), "Sub: wrong argument types (<LuaVector> expected)")
        return new(a.x - b.x, a.y - b.y, a.z - b.z)
	end
end

function LuaVector.__mul(a, b)
	if isnumber(a) then
		return new(a * b.x, a * b.y, a * b.z)
	elseif isnumber(b) then
		return new(a.x * b, a.y * b, a.z * b)
    else
        assert(isvector(a) and isvector(b), "Mul: wrong argument types (<LuaVector> or <number> expected)")
		return new(a.x * b.x, a.y * b.y, a.z * b.z)
	end
end

function LuaVector.__div(a, b)
    if isnumber(a) then
        return new(a / b.x, a / b.y, a / b.z)
    elseif isnumber(b) then
        return new(a.x / b, a.y / b, a.z / b)
    else
        assert(isvector(a) and isvector(b), "Div: wrong argument types (<LuaVector> or <number> expected)")
        return new(a.x / b.x, a.y / b.y, a.z / b.z)
    end
end


--[[
    vector member function
]]
function LuaVector:Clone()
	return new(self.x, self.y, self.z)
end

function LuaVector:SizeSquared()
	return self.x * self.x + self.y * self.y + self.z * self.z
end

function LuaVector:Size()
	return sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

function LuaVector:NormalizeInplace()
	local l = self:Size()
	if l > 0 then
        self.x, self.y, self.z = self.x / l, self.y / l, self.z / l
    else
        logerror("NormalizeInplace: LuaVector size is zero")
	end
	return self
end

function LuaVector:Normalized()
	return self:Clone():NormalizeInplace()
end

function LuaVector:RotateAngleByAxis(nAngleDeg, tbAxis)
    local Radians = deg2rad(nAngleDeg)

    local s = sin(Radians)
    local c = cos(Radians)

    local xx = tbAxis.x * tbAxis.x
    local yy = tbAxis.y * tbAxis.y
    local zz = tbAxis.z * tbAxis.z

    local xy = tbAxis.x * tbAxis.y
    local yz = tbAxis.y * tbAxis.z
    local zx = tbAxis.z * tbAxis.x

    local xs = tbAxis.x * s
    local ys = tbAxis.y * s
    local zs = tbAxis.z * s

    local omc = 1.0 - c
    return new(
            (omc * xx + c)  * self.x + (omc * xy - zs) * self.y + (omc * zx + ys) * self.z,
            (omc * xy + zs) * self.x + (omc * yy + c)  * self.y + (omc * yz - xs) * self.z,
            (omc * zx - ys) * self.x + (omc * yz + xs) * self.y + (omc * zz + c)  * self.z)
end

function LuaVector:ProjectOn(v)
    assert(isvector(v), "invalid argument: cannot project LuaVector on " .. type(v))
    -- (v * ((*this | v) / (v | v)))
	return (v * (LuaVector.Dot(self, v) / LuaVector.Dot(v, v)))
end

function LuaVector:MirrorOn(v)
	assert(isvector(v), "invalid argument: cannot mirror LuaVector on " .. type(v))
	-- *this - MirrorNormal * (2.f * (*this | MirrorNormal))
	return self - v * (2 * LuaVector.Dot(self, v))
end


--[[
    LuaVector static function
]]
function LuaVector.Distance(v1, v2)
    assert(isvector(v1) and isvector(v2), "Distance: wrong argument types (<LuaVector> expected)")
	local dx = v1.x - v2.x
    local dy = v1.y - v2.y
    local dz = v1.z - v2.z
	return sqrt(dx * dx + dy * dy + dz * dz)
end

function LuaVector.DistSquared(v1, v2)
    assert(isvector(v1) and isvector(v2), "DistSquared: wrong argument types (<LuaVector> expected)")
	local dx = v1.x - v2.x
    local dy = v1.y - v2.y
    local dz = v1.z - v2.z
	return (dx * dx + dy * dy + dz * dz)
end

function LuaVector.Cross(v1, v2)
	assert(isvector(v1) and isvector(v2), "Cross: wrong argument types (<LuaVector> expected)")
	return new(v1.y * v2.z - v1.z * v2.y, v1.z * v2.x - v1.x * v2.z, v1.x * v2.y - v1.y * v2.x)
end

function LuaVector.Dot(v1, v2)
    assert(isvector(v1) and isvector(v2), "Dot: wrong argument types (<LuaVector> expected)")
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
end

function LuaVector.NearlyEqual(v1, v2, tolerance)
	assert(isvector(v1) and isvector(v2), "NearlyEqual: wrong argument types (<LuaVector> expected)")
    tolerance = tolerance or 0.0001
    return (abs(v1.x - v2.x) <= tolerance) and (abs(v1.y - v2.y) <= tolerance) and (abs(v1.y - v2.y) <= tolerance)
end

function LuaVector.ToUEVector(v)
    assert(isvector(v), "Dot: wrong argument types (<LuaVector> expected)")
    return makeuevector(v.x, v.y, v.z)
end

function LuaVector.FromUEVector(pVector)
    return new(breakuevector(pVector))
end

LuaVector.IsVector = isvector

return LuaVector