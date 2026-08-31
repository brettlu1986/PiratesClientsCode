local LuaRotator = { }

LuaRotator.__index = LuaRotator

local square = function(x)
    return x * x
end

local atan2  = math.atan
local asin   = math.asin
local assert = assert

local function new(nPitch, nYaw, nRoll)
    return setmetatable({ pitch = nPitch or 0, yaw = nYaw or 0, roll = nRoll or 0 }, LuaRotator)
end

setmetatable(LuaRotator, { __call = function(self, x, y, z)
    return new(x, y, z)
end })

local function isrotator(v)
    return type(v) == 'table' and type(v.pitch) == 'number' and type(v.yaw) == 'number' and type(v.roll) == 'number' and 
        getmetatable(v) == LuaRotator
end

LuaRotator.IsRotator = isrotator

local function ClampAxis(Angle)
    Angle = Angle % 360
	if Angle < 0 then
        Angle = Angle + 360
    end
	return Angle;
end

local function NormalizeAxis(Angle)
    Angle = ClampAxis(Angle)
    if Angle > 180 then
        Angle = Angle - 360
    end
    return Angle
end

function LuaRotator:Clone()
	return new(self.pitch, self.yaw, self.roll)
end

function LuaRotator.Quaternion(Quaternion)
    local QX, QY, QZ, QW = Quaternion[1], Quaternion[2], Quaternion[3], Quaternion[4]
    local SingularityTest = QZ * QX-QW * QY
	local YawY = 2 * (QW * QZ + QX * QY)
    local YawX = (1 - 2 * (square(QY) + square(QZ)))
    local SINGULARITY_THRESHOLD = 0.4999995
	local RAD_TO_DEG = (180) / math.pi;
    local RetRotator = new(0, 0, 0)
	if SingularityTest < -SINGULARITY_THRESHOLD then
		RetRotator.pitch = -90
		RetRotator.yaw = atan2(YawY, YawX) * RAD_TO_DEG;
		RetRotator.roll = NormalizeAxis(-RetRotator.yaw - (2 * atan2(QX, QW) * RAD_TO_DEG));
	elseif SingularityTest > SINGULARITY_THRESHOLD then
		RetRotator.pitch = 90
		RetRotator.yaw = atan2(YawY, YawX) * RAD_TO_DEG;
		RetRotator.roll = NormalizeAxis(RetRotator.yaw - (2 * atan2(QX, QW) * RAD_TO_DEG));
	else
		RetRotator.pitch = asin(2 * (SingularityTest)) * RAD_TO_DEG;
		RetRotator.yaw = atan2(YawY, YawX) * RAD_TO_DEG;
		RetRotator.roll = atan2(-2 *(QW * QX + QY * QZ), (1 - 2 * (square(QX) + square(QY)))) * RAD_TO_DEG;
    end
    return RetRotator
end

function LuaRotator.__unm(a)
	return new(-a.pitch, -a.yaw, -a.roll)
end

function LuaRotator.__add(a,b)
    assert(isrotator(a) and isrotator(b), "Add: wrong argument types (<LuaRotator> expected)")
	return new(a.pitch + b.pitch, a.yaw + b.yaw, a.roll + b.roll)
end

function LuaRotator.__sub(a,b)
	assert(isrotator(a) and isrotator(b), "Sub: wrong argument types (<LuaRotator> expected)")
	return new(a.pitch - b.pitch, a.yaw - b.yaw, a.roll - b.roll)
end

function LuaRotator.__mul(a,b)
	if type(a) == "number" then
		return new(a * b.pitch, a * b.yaw, a * b.roll)
	elseif type(b) == "number" then
		return new(b * a.pitch, b * a.yaw, b * a.roll)
    else
        assert(isrotator(a) and isrotator(b), "Mul: wrong argument types (can not mul two LuaRotator)")
	end
end

function LuaRotator.__div(a,b)
    if type(a) == "number" then
        return new(b.pitch / a, b.yaw / a, b.roll / a)
    elseif type(b) == "number" then
        return new(a.pitch / b, a.yaw / b, a.roll / b)
    else
        assert(isrotator(a) and isrotator(b), "Div: wrong argument types (can not mul two LuaRotator)")
    end
end

function LuaRotator.__eq(a,b)
	return a.pitch == b.pitch and a.yaw == b.yaw and a.roll == b.roll
end

function LuaRotator:__tostring()
	return "("..tonumber(self.pitch)..","..tonumber(self.yaw)..","..tonumber(self.roll)..")"
end


function LuaRotator:NormalizeInplace()
    self.pitch = NormalizeAxis(self.pitch)
    self.yaw = NormalizeAxis(self.yaw)
    self.roll = NormalizeAxis(self.roll)
    return self
end

function LuaRotator:Normalized()
	return self:Clone():NormalizeInplace()
end

function LuaRotator.ToUERotator(tbRotator)
    return KismetMathLibrary.MakeRotator(tbRotator.roll, tbRotator.pitch, tbRotator.yaw)
end

function LuaRotator.FromUERotator(pRotator)
    return new(pRotator.Pitch, pRotator.Yaw, pRotator.Roll)
end


return LuaRotator