local Human3DItemShowDataHelper = {}

local LobbySubLevelDataTable = require("LobbySubLevelDataTable")
local LobbySubTypeDef = require("LobbySubTypeDef")
local UIDef = require("UIDef")
local ItemDataTable = require("ItemDataTable")
local HumanAvatarDef = require("HumanAvatarDef")
local LobbyWeaponMiscDataTable = require("LobbyWeaponMiscDataTable")
local ItemCategoryDef = require("ItemCategoryDef")
local LobbySystem = require("LobbySystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local HumanAvatarHelper = require("HumanAvatarHelper")
local HumanArmorDef = require("HumanArmorDef")
local UILobbyCaptainHelper = require("UILobbyCaptainHelper")

function Human3DItemShowDataHelper.MakeHumanFashionShowData(nItemTemplateId)
    local tbPlayer = GamePlayerSelfHelper:Get()
    local nAvatarId = tbPlayer.LobbyPropertyComponent:GetAvatarId()
    local tbAppearanceIds = tbPlayer.AppearanceComponent:GetAppearanceIds()

    local tbSubLevelTemplate = LobbySubLevelDataTable:GetTemplate(LobbySubTypeDef.SHOW, UIDef.UI_LOBBY_HUMAN_FASHION_SHOW)
    if not tbSubLevelTemplate then
        logerror("UPLobbyShopDisplayItem, DisplayHumanFashionItem error.")
        return
    end

    local szActorTag = tbSubLevelTemplate.tbActorTag[1]
    if not szActorTag then
        logerror("UPLobbyShopDisplayItem, DisplayHumanFashionItem, szActorTag is invalid.")
        return
    end

    local tbTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    local nFashionType = tbTemplate.nFashionType
    local FashionType = HumanAvatarDef.FashionType
    local tbData = {}
    tbData.nCategory = ItemCategoryDef.FASHION
    tbData.bShowLevel = tbTemplate.bShowLevel

    if tbTemplate.nCategory == ItemCategoryDef.SUIT then
        tbData.tbFashionTemplateIds = tbTemplate.tbSubItemTemplateIds
    else
        tbData.tbFashionTemplateIds = {nItemTemplateId}
    end
    tbData.nTargetTemplateId = nItemTemplateId
    tbData.szAnim = UILobbyCaptainHelper.GetHumanAnimationByFashionTemplateId(nItemTemplateId)
    tbData.tbAppearanceIds = tbAppearanceIds
    tbData.nAvatarId = nAvatarId
    tbData.szActorTag = szActorTag
    tbData.fnGetLocationAndRotatorByTag = function (szTag)
        local tbSubSystem = LobbySystem:GetSub(LobbySubTypeDef.SHOW)
        local pActorLocation, pActorRotation =  tbSubSystem:GetLocationAndRotationByTag(LobbySubTypeDef.SHOW, UIDef.UI_LOBBY_HUMAN_FASHION_SHOW, szTag)
        return pActorLocation, pActorRotation
    end
    if nFashionType ~= FashionType.Basic then
        local nArmorType = HumanAvatarHelper.FashionTypeToArmorType[nFashionType]
        tbData.nArmorType = nArmorType
        tbData.nArmorLevel = HumanArmorDef.MAX_LEVEL
    end
    return tbData
end


function Human3DItemShowDataHelper.MakeHumanWeaponFashionShowData(nItemTemplateId)
    local tbSubLevelTemplate = LobbySubLevelDataTable:GetTemplate(LobbySubTypeDef.SHOW, UIDef.UI_LOBBY_HUMAN_WEAPON_SHOW)
    if not tbSubLevelTemplate then
        logerror("UPLobbyShopDisplayItem, DisplayHumanFashionItem error.")
        return
    end

    local szActorTag = tbSubLevelTemplate.tbActorTag[1]
    if not szActorTag then
        logerror("UPLobbyShopDisplayItem, DisplayHumanFashionItem, szActorTag is invalid.")
        return
    end

    local tbTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    local nWeaponInstanceType = tbTemplate.nSubCategory
    local tbDisplayMiscData = LobbyWeaponMiscDataTable:GetDisplayMiscData(nWeaponInstanceType, LobbyWeaponMiscDataTable.DisplayKey.UICaptain)
    local tbData = {}
    tbData.nCategory = ItemCategoryDef.HUMAN_WEAPON_FASHION
    tbData.nItemTemplateId = nItemTemplateId
    tbData.bShowLevel = tbTemplate.bShowLevel
    tbData.nWeaponInstanceType = nWeaponInstanceType
    tbData.tbDisplayMiscData = tbDisplayMiscData
    tbData.szActorTag = szActorTag
    tbData.tbLightChannel = LobbySubLevelDataTable:GetLightChannelData(LobbySubTypeDef.SHOW, UIDef.UI_LOBBY_HUMAN_WEAPON_SHOW)
    tbData.fnGetLocationAndRotatorByTag = function (szTag)
        local tbSubSystem = LobbySystem:GetSub(LobbySubTypeDef.SHOW)
        local pActorLocation, pActorRotation =  tbSubSystem:GetLocationAndRotationByTag(LobbySubTypeDef.SHOW, UIDef.UI_LOBBY_HUMAN_WEAPON_SHOW, szTag)
        return pActorLocation, pActorRotation
    end

    return tbData
end

return Human3DItemShowDataHelper