-----------------------------------------------------
--File Name    : HomelandUIHelper.lua
--Author       : WuJizhou
--Create Time  : 4/23/2019, 12:24:24 PM
--Description  : HomelandUIHelper
-----------------------------------------------------
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local UIDef = require("UIDef")

local HomelandSceneDataTable = require("HomelandSceneDataTable")
local HomelandSystem = require("HomelandSystem")
local LandmarkStatusDef = require("LandmarkStatusDef")
local LandmarkBuildingUpgradeDataTable = require("LandmarkBuildingUpgradeDataTable")

local HomelandUIHelper = {}

-- @param tbArgs
-- tbArgs.PrefabHelper = nil
-- tbArgs.nBlockId = 1
function HomelandUIHelper.ShowLandmarkUpgradeDialog(tbArgs)
    local PrefabHelper = tbArgs.PrefabHelper
    local nBlockId = tbArgs.nBlockId
    local tbBlockTemplate = HomelandSceneDataTable:GetBlockTemplate(nBlockId)
    local nLandmarkType = tbBlockTemplate.nDefaultLandmarkType
    local nSceneId = HomelandSystem:GetCurrentSceneId()
    local nGrade = HomelandSystem:GetLandmarkGrade(nLandmarkType)

    local Dialog = UIUtils.CreateDialog(UISetUtils.GetL10NTextByKey("HOMELAND_MARK_BUILDING_UPGRADE_DIALOG_TITLE"))
    local pbLandmarkUpgradeView = PrefabHelper:CreatePrefab(UIDef.UP_LANDMARK_UPGRADE_VIEW)
    pbLandmarkUpgradeView:SetViewData(nLandmarkType, nGrade, nSceneId)
    pbLandmarkUpgradeView:SetDialogFrame(Dialog)
    Dialog:SetView(pbLandmarkUpgradeView.pWidgetRef)
    Dialog:SetPositiveButtonVisible(false)
    Dialog:SetNegativeButtonVisible(false)
    Dialog:ShowDialog()
end

-- @param tbArgs
-- tbArgs.nBlockId = 1
function HomelandUIHelper.CanShowUpgradeDialog(tbArgs)
    local nBlockId = tbArgs.nBlockId

    local tbBlockData = HomelandSystem:GetBlockData(nBlockId)
    local nStatus = tbBlockData.nStatus
    if nStatus == LandmarkStatusDef.UPGRADING then
        return false
    end

    local tbBlockTemplate = HomelandSceneDataTable:GetBlockTemplate(nBlockId)
    local nLandmarkType = tbBlockTemplate.nDefaultLandmarkType
    local nMaxGrade = LandmarkBuildingUpgradeDataTable:GetMaxGrade(nLandmarkType)
    local nGrade = HomelandSystem:GetLandmarkGrade(nLandmarkType)
    if nGrade >= nMaxGrade then
        return false
    end

    return true
end

HomelandUIHelper.MiscDef = {}

HomelandUIHelper.MiscDef.SceneStyleState =
{
    Locked   = 0,  --未解锁
    Unlocked = 1,  --已解锁，未拥有
    Owned    = 2,  --已拥有
    InUse    = 3,  --使用中
}

return HomelandUIHelper