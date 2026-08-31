local SeaAdventureHelper = {}

local AwardDataTable = require("AwardDataTable")
local UISetUtils = require("UISetUtils")
local Proto = require("ClientProtoNames")

SeaAdventureHelper.TILE_MAX = 17
SeaAdventureHelper.TILE_START = 0

SeaAdventureHelper.CIRCLE_REWARD_MAX = 3
SeaAdventureHelper.ROLL_TASK_TYPE = 5
SeaAdventureHelper.ROLL_TASK_ID = {1, 2, 3}
SeaAdventureHelper.ROLL_SUB_TASK_ID = 4
SeaAdventureHelper.DICE_ITEM_ID = 2600002
SeaAdventureHelper.UNKNOWN_TILE = 0

SeaAdventureHelper.TILE_TYPE =
{
    START   = 1, 
    UNKNOWN = 2, 
    NORMAL  = 3,
}

SeaAdventureHelper.CIRCLE_REWARD_STATE = 
{
    UNGET  = Proto.RewardState.UNRECEIVED,
    CANGET = Proto.RewardState.RECEIVE,
    GET    = Proto.RewardState.RECEIVED,
}

SeaAdventureHelper.DICE_NUM =
{
    "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity55.Spr_LobbyActivity55'",
    "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity56.Spr_LobbyActivity56'",
    "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity57.Spr_LobbyActivity57'",
    "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity58.Spr_LobbyActivity58'",
    "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity59.Spr_LobbyActivity59'",
    "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_LobbyActivity60.Spr_LobbyActivity60'",
}

SeaAdventureHelper.IMG_NUM = 
{
    [0] = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_Activity_Sell0.Spr_Activity_Sell0'",
    [1] = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_Activity_Sell1.Spr_Activity_Sell1'",
    [2] = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_Activity_Sell2.Spr_Activity_Sell2'",
    [3] = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_Activity_Sell3.Spr_Activity_Sell3'",
    [4] = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_Activity_Sell4.Spr_Activity_Sell4'",
    [5] = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_Activity_Sell5.Spr_Activity_Sell5'",
    [6] = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_Activity_Sell6.Spr_Activity_Sell6'",
    [7] = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_Activity_Sell7.Spr_Activity_Sell7'",
    [8] = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_Activity_Sell8.Spr_Activity_Sell8'",
    [9] = "PaperSprite'/Game/UI/Textures/LobbyActivity/Frames/Spr_Activity_Sell9.Spr_Activity_Sell9'",
}

function SeaAdventureHelper.SetMonthDayImageWithNum(ImgMonth1, ImgMonth2, ImgDay1, ImgDay2, nMonth, nDay)
    local VISIBLE, COLLAPSED = ESlateVisibility.SelfHitTestInvisible, ESlateVisibility.Collapsed
    local nMonth1, nDay1 = nMonth // 10, nDay // 10
    ImgMonth1:SetVisibility(nMonth1 == 0 and COLLAPSED or VISIBLE)
    ImgDay1:SetVisibility(nDay1 == 0 and COLLAPSED or VISIBLE)
    if nMonth1 ~= 0 then 
        UISetUtils.SetImageBrushRes(ImgMonth1, SeaAdventureHelper.IMG_NUM[nMonth1]:load())
    end
    if nDay1 ~= 0 then  
        UISetUtils.SetImageBrushRes(ImgDay1, SeaAdventureHelper.IMG_NUM[nDay1]:load())
    end
    local nMonth2 = nMonth - nMonth1 * 10
    local nDay2 = nDay - nDay1 * 10
    UISetUtils.SetImageBrushRes(ImgMonth2, SeaAdventureHelper.IMG_NUM[nMonth2]:load())
    UISetUtils.SetImageBrushRes(ImgDay2, SeaAdventureHelper.IMG_NUM[nDay2]:load())
end

function SeaAdventureHelper.GetTileRewardsTemplateIds(tbRewardsIds)
    local tbTemplateIds = {}
    local tbCounts = {}
    for _, v in ipairs(tbRewardsIds) do  
        if v ~= 0 then 
            local tbItem = AwardDataTable:GetAwardItem(v)
            table.insert(tbTemplateIds, tbItem[1].nItemId)
            table.insert(tbCounts, tbItem[1].nCount)
        else  
            table.insert(tbTemplateIds, SeaAdventureHelper.UNKNOWN_TILE)
            table.insert(tbCounts, 0)
        end
    end
    return tbTemplateIds, tbCounts
end

function SeaAdventureHelper.GetRewardDiceCount(tbRewards)
    local nCount = 0
    for _, v in pairs(tbRewards) do  
        local tbItem = AwardDataTable:GetAwardItem(v)
        for _, Item in pairs(tbItem) do 
            if Item.nItemId == SeaAdventureHelper.DICE_ITEM_ID then  
                nCount = nCount + Item.nCount
            end
        end
    end
    return nCount
end

--use for test
SeaAdventureHelper.bTest = false
SeaAdventureHelper.tbTestTileItems = 
{
    1201001, 1000003, 1000001, 0,
    1120000, 1120001, 1160002, 1120003, 0,
    2060037, 2060025, 2060033, 1760018, 0, 
    1760009, 2400000, 2410005
}
SeaAdventureHelper.tbTestTileCounts = {1, 1 , 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}

SeaAdventureHelper.tbTestDiceRewards = { 1201001, 1000003, 1000001}

SeaAdventureHelper.tbTestDiceRewardsState = 
{  
    SeaAdventureHelper.CIRCLE_REWARD_STATE.UNGET,
    SeaAdventureHelper.CIRCLE_REWARD_STATE.CANGET,  
    SeaAdventureHelper.CIRCLE_REWARD_STATE.GET,
}


return SeaAdventureHelper