local StringUtil = require("StringUtil")

local function GetFilePath(szSceneDir)
    local tbPathArrays = StringUtil.Split(szSceneDir, "GameData/")
    return tbPathArrays[#tbPathArrays]
end

return function(szSceneDir)
    local szErrorInfo;

    if szSceneDir == nil or szSceneDir == "" then
        return "szSceneDir is Empty!"
    end

    local szFilePath = GetFilePath(szSceneDir)
    if szFilePath == nil or szFilePath == "" then
        return "szFilePath is Empty!"
    end

    szErrorInfo = require("PostCheckDropItem")(szFilePath)

    -- 这里未来还可以加别的check
    return szErrorInfo
end