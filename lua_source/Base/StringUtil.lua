local StringUtil = {}

local GetByteCount = function(curByte)
    if curByte>0 and curByte<=127 then
        return 1                                               --1字节字符
    elseif curByte>=192 and curByte<=223 then
        return 2                                               --双字节字符
    elseif curByte>=224 and curByte<=239 then
        return 3                                               --汉字
    elseif curByte>=240 and curByte<=247 then
        return 4                                               --4字节字符
    else
        logerror("StringUtil, invalid character", curByte)
        return 5
    end
end

-- 移除字符串首尾空格
function StringUtil.Trim(szStr)
    if type(szStr) ~= 'string' then
        return szStr
    end
	return (string.gsub(szStr, "^%s*(.-)%s*$", "%1"))
end

function StringUtil.Split(szStr, szDelim)
    if StringUtil.IsEmptyString(szStr) then
        return {}
    end

    if (type(szDelim) ~= 'string') or StringUtil.IsEmptyString(szDelim) then
        return { szStr }
    end
    
    local tbResult = {}
    local nStart = 1
    
    while true do    
        local nPos = string.find(szStr, szDelim, nStart, true) -- plain find
        if not nPos then
            break
        end
    
        table.insert(tbResult, string.sub(szStr, nStart, nPos - 1))
        nStart = nPos + string.len(szDelim)
    end
    
    table.insert(tbResult, string.sub(szStr, nStart))
    return tbResult
end

function StringUtil.StartsWith(szStr, szStart)
    if (type(szStr) ~= 'string') or (type(szStart) ~= 'string') then
        return false
    end
    local nStartLen = string.len(szStart)
    local szRealStart = string.sub( szStr, 1, nStartLen )
    return szStart == szRealStart
end

function StringUtil.GetRealTypeValue( szValue ) -- Only recognize nil, number and string
    if szValue == nil then
        return nil
    end
    local nValue = tonumber(szValue)
    if nValue ~= nil then
        return nValue
    end

    return szValue
end

function StringUtil.ToBool( szValue )
    if szValue == '1'
    or szValue == 'true'
    or szValue == 1
    then
        return true
    end
    return false
end

function StringUtil.ToNumber( szValue, nDefaultValue )
    local nRetValue = tonumber(szValue)
    if nRetValue then
        return nRetValue
    end
    return nDefaultValue and nDefaultValue or 0
end

function StringUtil.IsEmptyString( szValue )
    if not szValue then
        return true
    end
    return string.len(szValue) <= 0
end

function StringUtil.SplitToTable( szStr )
    local lenInByte = #szStr
    local width = 0
    local tbRet = {}
    local i = 1
    local curByte
    local byteCount
    while (i<=lenInByte) 
    do
        curByte = string.byte(szStr, i)
        byteCount = GetByteCount(curByte)

        width = width + 1
        tbRet[width] = string.sub(szStr, i, i+byteCount-1)
        i = i + byteCount
    end
    return tbRet
end

function StringUtil.Length( szStr )
    return #StringUtil.SplitToTable(szStr)
end

function StringUtil.GetPrefix(szStr, nSize)
    local lenInByte = #szStr
    local width = 0
    local i = 1
    local curByte
    local byteCount
    while (i<=lenInByte) 
    do
        curByte = string.byte(szStr, i)
        byteCount = GetByteCount(curByte)
        
        width = width + 1
        i = i + byteCount
        if width >= nSize then
            break
        end
    end

    return string.sub(szStr, 1, i - 1)
end

function StringUtil.ParseDataByComma(szData)
    if(szData == nil) then
        return nil
    end

    local tbTemp = StringUtil.Split(szData, ",")
    if #tbTemp <= 0 then 
        return nil
    end 
    local tbRet = {}
    for _,v in ipairs(tbTemp) do
        table.insert(tbRet, tonumber(v))
    end    
    return tbRet
end

return StringUtil
