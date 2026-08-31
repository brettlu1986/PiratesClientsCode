-----------------------------------------------------
--File Name    : HeadIconHelper.lua
--Author       : Chang Nan
--Create Time  : 2017-10-14
--Description  : 玩家头像管理系统
-----------------------------------------------------
local HeadIconResDataTable = require("HeadIconResDataTable")
local AvatarDataTable = require("AvatarDataTable")
local HeadIconHelper = {}

function HeadIconHelper:GetPlayerHeadIconResByAvatar(nId)
    local nIconId = AvatarDataTable:GetTemplate(nId).nHeadIconId
    local szPath = HeadIconResDataTable:GetResPath(nIconId)
    return szPath
end


function HeadIconHelper:GetPlayerHeadIconResByIconId(nId)
    local szPath = HeadIconResDataTable:GetResPath(nId)
    return szPath
end

return HeadIconHelper