local EditorLaunchParams = {}

local StringUtil = require("StringUtil")

local tbParamValues = {}

function EditorLaunchParams:Parse(szParams)
    local szKey, szValue
    tbParamValues = {}
    local tbParams = StringUtil.Split(szParams, ",")
    for _, szParam in ipairs(tbParams) do
        szKey, szValue = string.match(szParam, "(%w+):(%w+)")
        if(szKey ~= nil) then
            tbParamValues[szKey] = szValue
        end
    end
end

function EditorLaunchParams:GetParam(szKey)
    return tbParamValues[szKey]
end

return EditorLaunchParams