-----------------------------------------------------
--File Name    : BuildTipsHelper.lua
--Author       : chenyixin
--Description  : 打开建造tips页面的helper
-----------------------------------------------------
local BuildTipsHelper = {}

local UIDef = require("UIDef")
local UIManager = require("UIManager")
local BattleItemCategoryDef = require("BattleItemCategoryDef")

local szCurOpenWnd = nil

local tbBuildTipsWndName = {
    [BattleItemCategoryDef.SHIP_WEAPON]     = UIDef.UI_BUILD_COMMON_ITEM_TIPS,
    [BattleItemCategoryDef.SHIP_PART]       = UIDef.UI_BUILD_SHIP_PART_TIPS,
    [BattleItemCategoryDef.HUMAN_WEAPON]    = UIDef.UI_BUILD_COMMON_ITEM_TIPS,
    [BattleItemCategoryDef.HUMAN_ARMOR]     = UIDef.UI_BUILD_COMMON_ITEM_TIPS,
    [BattleItemCategoryDef.SHIP]            = UIDef.UI_BUILD_SHIP_TIPS,
}

function BuildTipsHelper.CloseTipsWnd()
    if szCurOpenWnd then
        UIManager:CloseWnd(szCurOpenWnd)
        szCurOpenWnd = nil
    end
end

function BuildTipsHelper.ShowBuildTips(nCategory, nSelectedItemTemplateId, nSlotIndex)
    BuildTipsHelper.CloseTipsWnd()

    local szWndName = tbBuildTipsWndName[nCategory]
    UIManager:OpenWnd(szWndName, {nSelectedItemTemplateId = nSelectedItemTemplateId, nSlotIndex = nSlotIndex})
    szCurOpenWnd = szWndName
end

return BuildTipsHelper