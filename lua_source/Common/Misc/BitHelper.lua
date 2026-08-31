local BitHelper = {}

-- 获取从右边起第n位的值
function BitHelper:GetBit(value, index)
    return (value >> (index - 1)) & 1
end

local function OrBit(value1, value2)    --或  
    return (value1 == 1 or value2 == 1) and 1 or 0  
end 

local function AndBit(value1, value2)    --与  
    return (value1 == 1 and value2 == 1) and 1 or 0  
end 

local function XorBit(value1, value2)   --异或  
    return (value1 + value2) == 1 and 1 or 0  
end  

local function BaseOp(value1, value2, op) --对每一位进行op运算，然后将值返回  
    if value1 < value2 then  
        value1, value2 = value2, value1  
    end  
    local res = 0  
    local shift = 1  
    while value1 ~= 0 do  
        local ra = value1 % 2    --取得每一位(最右边)  
        local rb = value2 % 2     
        res = shift * op(ra,rb) + res  
        shift = shift * 2  
        value1 = math.modf( value1 / 2)  --右移  
        value2 = math.modf( value2 / 2)  
    end  
    return res  
end

function BitHelper:NotOp(value)  
    return value > 0 and -(value + 1) or -value - 1  
end 

function BitHelper:OrOp(value1, value2)  
    return BaseOp(value1, value2, OrBit)  
end 

function BitHelper:AndOp(value1, value2)
    return BaseOp(value1, value2, AndBit)  
end

function BitHelper:XorOp(value1, value2)  
    return BaseOp(value1, value2, XorBit)  
end

-- x, y 必须小于等于15位(32767),最高位保存符号
function BitHelper:XYToPos(x, y)
    local symbol = x < 0 and 1 or 0
    symbol = symbol << 15
    local posx = self:OrOp(symbol, math.abs(x))
    local high = posx << 16

    symbol = y < 0 and 1 or 0
    symbol = symbol << 15
    local posy = math.abs(y)
    local low = self:OrOp(symbol, posy) 

    local pos = self:OrOp(high, low)
    return pos
end

function BitHelper:PosToXY(pos)
    local high = pos >> 16
    local symbol = high >> 15
    local x = self:AndOp(high, 32767)
    x = x * (symbol > 0 and -1 or 1) 

    local low = self:AndOp(pos, 65535)
    symbol = low >> 15
    local y = self:AndOp(low, 32767)
    y = y * (symbol > 0 and -1 or 1)
    return x, y
end

-- 设置位，为1
function BitHelper:SetBitValue(value, bit)
    return value | (1 << (bit - 1))  
end

-- 设置位，为0
function BitHelper:SetBitZero(value, bit)
    if value == 0 then
        return value
    end

    local index = 0
    local number = 0

    while value ~= 0 do
        index = index + 1  
        local ra = value % 2    --取得每一位(最右边)  
        value = math.modf( value / 2)  --右移
        if index ~= bit then
            number = number + ra * (1 << (index - 1))
        -- else
        --     number = number + 0 * (1 << (index - 1))
        end
    end     

    return number
end

return BitHelper