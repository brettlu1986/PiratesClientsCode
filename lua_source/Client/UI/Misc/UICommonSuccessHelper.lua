-----------------------------------------------------
--File Name    : UICommonSuccessHelper.lua
--Author       : Ran Jie
--Create Time  : 2017-04-12
--Description  : UICommonSuccessHelper
-----------------------------------------------------


local UICommonSuccessHelper = {}

local UIManager = require("UIManager")
local UIDef = require("UIDef")


-- member variable
UICommonSuccessHelper.Type =
{
    BUILD_SHIP_SUCCESS = {img = "PaperSprite'/Game/UI/Textures/ArtNumber/Frames/Spr_Art_02.Spr_Art_02'"},
    UNLOCK_SUCCESS = {img = "PaperSprite'/Game/UI/Textures/ArtNumber/Frames/Spr_Art_03.Spr_Art_03'"},
    ENHANCE_SUCCESS = {img = "PaperSprite'/Game/UI/Textures/ArtNumber/Frames/Spr_Art_04.Spr_Art_04'"},
    ENHANCE_FAIL = {img = "PaperSprite'/Game/UI/Textures/ArtNumber/Frames/Spr_Art_07.Spr_Art_07'", bgChange = true, animChange = true, closeEffect = true},
    BUILD_ITEM_SUCCESS = {img = "PaperSprite'/Game/UI/Textures/ArtNumber/Frames/Spr_Art_06.Spr_Art_06'"}
}


-- public function
function UICommonSuccessHelper:ShowTip(szType)
    UIManager:OpenWnd(UIDef.UI_COMMON_SUCCESS,{szType = szType})
end



return UICommonSuccessHelper
