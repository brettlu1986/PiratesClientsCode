local LuaQuaternion = {}

LuaQuaternion.__index = LuaQuaternion

local abs       = math.abs
local sqrt      = math.sqrt
local sin       = math.sin
local cos       = math.cos
local acos      = math.acos
local deg2rad   = math.rad
local assert    = assert
local deg2rad_constant   = math.pi/180.0
local LuaVector = require("Vector")
--local rad2deg   = math.deg
local delta = 0.000001

local function new(x, y, z, w)
	return setmetatable({ x, y, z, w }, LuaQuaternion)
end

local quat_new = new

setmetatable(LuaQuaternion, { __call = function(self, x, y, z, w)
    return quat_new(x, y, z, w)
end })

local function qmul(lhs, rhs)
	local lhs1, lhs2, lhs3, lhs4 = lhs[1], lhs[2], lhs[3], lhs[4]
	local rhs1, rhs2, rhs3, rhs4 = rhs[1], rhs[2], rhs[3], rhs[4]
	return quat_new(
		rhs4 * lhs1 + rhs1 * lhs4 + rhs2 * lhs3 - rhs3 * lhs2,
		rhs4 * lhs2 - rhs1 * lhs3 + rhs2 * lhs4 + rhs3 * lhs1,
		rhs4 * lhs3 + rhs1 * lhs2 - rhs2 * lhs1 + rhs3 * lhs4,
		rhs4 * lhs4 - rhs1 * lhs1 - rhs2 * lhs2 - rhs3 * lhs3
	)
end

local function isquaternion(v)
	return type(v) == 'table' and getmetatable(v) == LuaQuaternion
end

LuaQuaternion.IsQuaternion = isquaternion

function LuaQuaternion.exp(q)
    local angle = sqrt(q[1]*q[1] + q[2]*q[2] + q[3]*q[3])
    local sinAngle = sin(angle)

	local u1, u2, u3 = q[1], q[2], q[3]
    if abs(sinAngle) >= delta then
        local scale = sinAngle / angle
		u1 = q[1] * scale
		u2 = q[2] * scale
		u3 = q[3] * scale
	end
	return quat_new(u1, u2, u3, cos(angle))
end


function LuaQuaternion.log(q)
    local u1, u2, u3 = q[1], q[2], q[3]
    local w = q[4]
    if (abs(w) < 1) then
        local angle = acos(w)
        local sinAngle = sin(angle)
        if abs(sinAngle) > delta then
            local scale = sinAngle / angle
            u1 = q[1] * scale
            u2 = q[2] * scale
            u3 = q[3] * scale
        end
    end
	return quat_new( u1, u2, u3, 0 )
end

function LuaQuaternion.FromRotator(tbRotator)
    local p, y, r = tbRotator.pitch, tbRotator.yaw, tbRotator.roll
    local half_deg2rad = deg2rad_constant * 0.5
	p = p*half_deg2rad
	y = y*half_deg2rad
    r = r*half_deg2rad
    local sp, sy, sr = sin(p), sin(y), sin(r)
    local cp, cy, cr = cos(p), cos(y), cos(r)
	return quat_new(cr*sp*sy - sr*cp*cy, -cr*sp*cy - sr*cp*sy, cr*cp*sy - sr*sp*cy, cr*cp*cy + sr*sp*sy)
end

function LuaQuaternion.FromAngleAndAxis(tbAxis, nAngle)
    local half_a = deg2rad(nAngle) * 0.5
    local s, c = sin(half_a), cos(half_a)
    return quat_new( s * tbAxis.x, s * tbAxis.y , s * tbAxis.z , c)
end

function LuaQuaternion.__unm(q)
	return quat_new( -q[1], -q[2], -q[3], -q[4] )
end

function LuaQuaternion.__add(lhs, rhs)
	return quat_new( lhs[1] + rhs[1], lhs[2] + rhs[2], lhs[3] + rhs[3], lhs[4] + rhs[4] )
end

function LuaQuaternion.__sub(lhs, rhs)
	return quat_new( lhs[1] - rhs[1], lhs[2] - rhs[2], lhs[3] - rhs[3], lhs[4] - rhs[4] )
end

function LuaQuaternion:RotateVector(v)
    local Q = LuaVector(self[1], self[2], self[3])
    local T = LuaVector.Cross(Q, v) * 2
    local RetVector = v + (T * self[4]) + LuaVector.Cross(Q, T)
    return RetVector
end

function LuaQuaternion.__mul(lhs, rhs)
	if type(rhs) == "number" then
        return quat_new( rhs * lhs[1], rhs * lhs[2], rhs * lhs[3], rhs * lhs[4] )
    elseif type(lhs) == "number" then
        return quat_new( lhs * rhs[1], lhs * rhs[2], lhs * rhs[3], lhs * rhs[4] )
    elseif type(rhs) == "table" and LuaVector.IsVector(rhs) then
        return lhs:RotateVector(rhs)
    elseif type(lhs) == "table" and LuaVector.IsVector(lhs) then
        return rhs:RotateVector(rhs)
    else
        -- use reverse order 
		return qmul(rhs, lhs)
	end
end

function LuaQuaternion.__div(lhs, rhs)
    local lhs1, lhs2, lhs3, lhs4 = lhs[1], lhs[2], lhs[3], lhs[4]
    if type(rhs) == "number" then
        return quat_new(
            lhs1/rhs,
            lhs2/rhs,
            lhs3/rhs,
            lhs4/rhs
        )
    end
	return quat_new( lhs1, lhs2, lhs3, lhs4 )
end



function LuaQuaternion.__eq(lhs, rhs)
    assert(isquaternion(lhs) and isquaternion(rhs), "Equal: wrong argument types (<LuaQuaternion> expected)")
	local rvd1, rvd2, rvd3, rvd4 = lhs[1] - rhs[1], lhs[2] - rhs[2], lhs[3] - rhs[3], lhs[4] - rhs[4]
	return rvd1 <= delta and rvd1 >= -delta and
	   rvd2 <= delta and rvd2 >= -delta and
	   rvd3 <= delta and rvd3 >= -delta and
	   rvd4 <= delta and rvd4 >= -delta
end

function LuaQuaternion:Size()
    return sqrt(self[1] * self[1] + self[2] * self[2] + self[3] * self[3] + self[4] * self[4])
end

function LuaQuaternion:SizeSquared()
    return (self[1] * self[1] + self[2] * self[2] + self[3] * self[3] + self[4] * self[4])
end

function LuaQuaternion:__tostring()
    return "("..tonumber(self[1])..","..tonumber(self[2])..","..tonumber(self[3])..","..tonumber(self[4])..")"
end

function LuaQuaternion.FromUEQuaternion(pQuaternion)
    return quat_new(pQuaternion.X, pQuaternion.Y, pQuaternion.Z, pQuaternion.W)
end

return LuaQuaternion