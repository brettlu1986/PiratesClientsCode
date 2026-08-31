local MathUtil = {}

MathUtil.ComparisonMethod = {
    EQUAL_TO                    = 1, -- 等于
	NOT_EQUAL_TO                = 2, -- 不等于
	GREATER_THAN_OR_EQUAL_TO    = 3, -- 大于等于
	LESS_THAN_OR_EQUAL_TO       = 4, -- 小于等于
	GREATER_THAN                = 5, -- 大于
	LESS_THAN                   = 6  -- 小于
}

function MathUtil.ConvertCentimeterToKilometer(nNumInCM)
    return nNumInCM / 100000
end

function MathUtil.Square(x)
    return x * x
end

function MathUtil.Power(x, n)
    local result = 1
    while n ~= 0 do
        if n % 2 ~= 0 then
            result = result * x
        end
        n = n >> 1
        x = x * x
    end
    return result
end

function MathUtil.Sign(x)
    if x > 0 then
        return 1
    elseif x < 0 then
        return -1
    end
    return 0
end

function MathUtil.Clamp(nValue, nMin, nMax)
    if nValue > nMax then
        return nMax
    end
    if nValue < nMin then
        return nMin
    end
    return nValue
end

function MathUtil.Round(nValue)
    return math.floor(nValue + 0.5)
end

function MathUtil.RandomFloat(lower, greater)
    return lower + math.random()  * (greater - lower);
end

function MathUtil.CompareValue( nMethod, nValueA, nValueB )
    local ComparisonMethod = MathUtil.ComparisonMethod
    if nMethod == ComparisonMethod.EQUAL_TO then
        return nValueA == nValueB
    elseif nMethod == ComparisonMethod.NOT_EQUAL_TO then
        return nValueA ~= nValueB
    elseif nMethod == ComparisonMethod.GREATER_THAN_OR_EQUAL_TO then
        return nValueA >= nValueB
    elseif nMethod == ComparisonMethod.LESS_THAN_OR_EQUAL_TO then
        return nValueA <= nValueB
    elseif nMethod == ComparisonMethod.GREATER_THAN then
        return nValueA > nValueB
    elseif nMethod == ComparisonMethod.LESS_THAN then
        return nValueA < nValueB
    end
    logwarning("MathUtil.CompareValue method type invalid.")
    return false
end

return MathUtil
