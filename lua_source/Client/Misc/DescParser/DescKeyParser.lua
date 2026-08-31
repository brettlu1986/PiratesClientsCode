local DescKeyParser = {}

local nTempKeyValue = 1

local tbFunc = {}


local function Define(szNameSpace, szKey, fnGetData)
    local tbNameSpace = DescKeyParser[szNameSpace]
    if not tbNameSpace then
        tbNameSpace = {}
        DescKeyParser[szNameSpace] = tbNameSpace
    end
    if tbNameSpace[szKey] then
        logerror("DescKeyParser", "define duplicated, key : " .. szKey)
        return
    end
    tbNameSpace[szKey] = nTempKeyValue
    tbFunc[nTempKeyValue] = fnGetData
    nTempKeyValue = nTempKeyValue + 1
end



local function Register(szParseFileName)
    local tbParser = require(szParseFileName)
    tbParser.Init(Define)
end


local function Init()
    local DescKeyParserRegister = require("DescKeyParserRegister")
    DescKeyParserRegister.RegisterParsers(Register)
end


function DescKeyParser.GetParseData(szNameSpace, szKey, tbInputData)
    local tbNameSpace = DescKeyParser[szNameSpace]
    if not tbNameSpace then
        logerror("DescKeyParser", "GetParseData error szNameSpace is not defined. namespace: ", szNameSpace)
        return
    end
    local nKeyValue = tbNameSpace[szKey]
    if not nKeyValue then
        logerror("DescKeyParser", "GetParseData error nKeyValue is nil, key : ", szKey)
        return
    end
    local fnGetData = tbFunc[nKeyValue]
    if not fnGetData then
        logerror("DescKeyParser", "GetParseData error nKeyValue is nil, key :  " .. szKey)
        return
    end

    return fnGetData(tbInputData)
end

Init()



return DescKeyParser