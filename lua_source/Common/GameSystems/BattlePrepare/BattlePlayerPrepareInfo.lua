-- 新增参数需考虑联网本，ffa，单机本等需求，所以默认必须有初始值
-- 还有请增加对应的set函数，外面用的时候不要裸设

local luaclass = require("luaclass")
local BattlePlayerPrepareInfo = luaclass("BattlePlayerPrepareInfo")

local LandmarkTypeDef = require("LandmarkTypeDef")
local InitItemDataTable = require("InitItemDataTable")
local BattleItemInitHelper = require("BattleItemInitHelper")
local ShipPreparationHelper = require("ShipPreparationHelper")
local HumanAvatarHelper = require("HumanAvatarHelper")
local HumanDataTable    = require("HumanDataTable")

BattlePlayerPrepareInfo.nPlayerId = 0
BattlePlayerPrepareInfo.szPlayerName = "unknown"
BattlePlayerPrepareInfo.nHumanId = 1
BattlePlayerPrepareInfo.nGroupIndex = 0
BattlePlayerPrepareInfo.nToken = 0
BattlePlayerPrepareInfo.nLevel = 0
BattlePlayerPrepareInfo.nAvatarId = 0
BattlePlayerPrepareInfo.szPlayerSessionId = ""
BattlePlayerPrepareInfo.nX = 0
BattlePlayerPrepareInfo.nY = 0
BattlePlayerPrepareInfo.nZ = 0
BattlePlayerPrepareInfo.nYaw = 0
BattlePlayerPrepareInfo.nFaction = 0
BattlePlayerPrepareInfo.szGuildName = ""
-- BattlePlayerPrepareInfo.tbHumanFashionIds = {}
BattlePlayerPrepareInfo.tbHumanDecorationIds = {}
BattlePlayerPrepareInfo.tbSailorIds = {}
BattlePlayerPrepareInfo.tbPartners = {}
BattlePlayerPrepareInfo.nGrade = 0
BattlePlayerPrepareInfo.nMaxGrade = 0
BattlePlayerPrepareInfo.bNoob = false
BattlePlayerPrepareInfo.szLobbyTeamInfo = ""
BattlePlayerPrepareInfo.nLobbyJoinTime = 0
BattlePlayerPrepareInfo.tbSeason = nil
BattlePlayerPrepareInfo.tbAwardLimited = {}
BattlePlayerPrepareInfo.tbShipPreparationTemplateIds = nil
BattlePlayerPrepareInfo.tbShipSkinIds = {}
BattlePlayerPrepareInfo.tbLandmarkDatas = nil
BattlePlayerPrepareInfo.tbShipInfo = nil
BattlePlayerPrepareInfo.nIndex = 0  -- 这玩意是干嘛的？？
BattlePlayerPrepareInfo.tbInitItems = {}
BattlePlayerPrepareInfo.tbItemBuffs = nil
BattlePlayerPrepareInfo.bIsBot = nil
BattlePlayerPrepareInfo.szChannel = nil
BattlePlayerPrepareInfo.nMatchType = nil
BattlePlayerPrepareInfo.nHumanFashionFlag = 0

-- 初始选择的默认外装
BattlePlayerPrepareInfo.tbAppearancePartData = {}
-- 当前穿着的时装道具templateid
BattlePlayerPrepareInfo.tbFashionItemTemplateIds = {}
-- 人武器时装
BattlePlayerPrepareInfo.tbHumanWeaponFashionTemplateIds = {}


function BattlePlayerPrepareInfo.Create(nPlayerId, szName, nHumanId, nGroupIndex, nToken, szPlayerSessionId)
    assert(nPlayerId ~= nil)
    assert(szName ~= nil)
    assert(nHumanId ~= nil)

    local tbRet = BattlePlayerPrepareInfo()
    tbRet.tbShipInfo = {}
    tbRet.tbShipInfo.nTypeId = -1
    tbRet.nPlayerId = nPlayerId
    tbRet.szPlayerName = szName
    tbRet.nHumanId = nHumanId
    tbRet.nGroupIndex = nGroupIndex ~= nil and nGroupIndex or 0
    tbRet.nToken = nToken ~= nil and nToken or 0
    tbRet.szPlayerSessionId = szPlayerSessionId ~= nil and szPlayerSessionId or ""
    tbRet.tbShipPreparationTemplateIds = {}
    tbRet.tbItemBuffs = {}

    local tbLandmarkDatas = {}
    tbRet.tbLandmarkDatas = tbLandmarkDatas
    for i=1, LandmarkTypeDef.MAX do
        local tbLandmarkData = {}
        tbLandmarkData.id = i
        tbLandmarkData.grade = 0
        table.insert(tbLandmarkDatas, tbLandmarkData)
    end

    return tbRet
end

function BattlePlayerPrepareInfo:SetAppearance(tbAppearanceIds)
    self.tbAppearancePartData = HumanAvatarHelper.ParseToPartDataFromAppearance(tbAppearanceIds)
end

function BattlePlayerPrepareInfo:SetAppearanceFromPartData(tbPartData)
    self.tbAppearancePartData = tbPartData
end

function BattlePlayerPrepareInfo:SetHumanFashion(tbInfo)
    self.tbFashionItemTemplateIds = tbInfo
end

function BattlePlayerPrepareInfo:SetHumanFashionFlag(nFlag)
    self.nHumanFashionFlag = nFlag
end

function BattlePlayerPrepareInfo:SetDecoration(nDecoration)
    self.tbHumanDecorationIds[1] = nDecoration
end

function BattlePlayerPrepareInfo:SetHumanWeaponFashion(tbInfo)
    self.tbHumanWeaponFashionTemplateIds = tbInfo
end

function BattlePlayerPrepareInfo:SetSailorIds(tbInfo)
    self.tbSailorIds = tbInfo
end

function BattlePlayerPrepareInfo:SetPartners(tbInfo)
    self.tbPartners = tbInfo
end

function BattlePlayerPrepareInfo:SetNoob(bNoob)
    self.bNoob = bNoob
end

function BattlePlayerPrepareInfo:SetLobbyTeamInfo(szTeamId, nJoinTime)
    self.szLobbyTeamInfo = szTeamId
    self.nLobbyJoinTime = nJoinTime
end

function BattlePlayerPrepareInfo:SetSeasons(tbSeasons, nTeamModeId)
    local nMaxGrade = -1

    for _, tbCurSeason in pairs(tbSeasons) do
        if tbCurSeason.team_mode == nTeamModeId then
            self.tbSeason = tbCurSeason
            self.nGrade   = tbCurSeason.rank
        end

        nMaxGrade = math.max( nMaxGrade, tbCurSeason.rank)
    end

    self.nMaxGrade = nMaxGrade
end

function BattlePlayerPrepareInfo:SetAwardLimit(tbInfo)
    self.tbAwardLimited = tbInfo
end

function BattlePlayerPrepareInfo:AddShipPreparation(tbInfo)
    if(tbInfo) then
        local tbPreparations = self.tbShipPreparationTemplateIds
        for _, v in pairs(tbInfo) do
            table.insert(tbPreparations, v)
        end
    end
end

function BattlePlayerPrepareInfo:SetDefaultShipPreparation()
    self.tbShipPreparationTemplateIds = {}
    self:AddShipPreparation(ShipPreparationHelper.GetDefaultData())
end

function BattlePlayerPrepareInfo:SetShipSkin(tbInfo)
    self.tbShipSkinIds = tbInfo
end

function BattlePlayerPrepareInfo:SetLandmark(tbInfo)
    self.tbLandmarkDatas = tbInfo
end

function BattlePlayerPrepareInfo:SetInitItems(tbItems)
    assert(tbItems)
    self.tbInitItems = tbItems
    self.tbShipInfo.nTypeId = BattleItemInitHelper.GetShipTypeId(tbItems)
end

function BattlePlayerPrepareInfo:SetDefaultInitItems()
    local tbItems = InitItemDataTable:GetDefaultItems()
    self:SetInitItems(tbItems)
end

function BattlePlayerPrepareInfo:SetInitItemsByGroupId(nGroupId)
    local tbItems = InitItemDataTable:GetItems(nGroupId)
    self:SetInitItems(tbItems)
end

function BattlePlayerPrepareInfo:SetTransform(nX, nY, nZ, nYaw)
    self.nX = nX
    self.nY = nY
    self.nZ = nZ
    self.nYaw = nYaw
end

function BattlePlayerPrepareInfo:SetIndex(nIndex)
    self.nIndex = nIndex
end

function BattlePlayerPrepareInfo:SetItemBuffs(tbBuffs)
    self.tbItemBuffs = tbBuffs
end

function BattlePlayerPrepareInfo:SetIsBot()
    self.bIsBot = true
end

function BattlePlayerPrepareInfo:IsBot()
    return self.bIsBot == true
end

function BattlePlayerPrepareInfo:SetLevel(level)
    self.nLevel = level
end

function BattlePlayerPrepareInfo:SetAvatarId(avatar_id)
    self.nAvatarId = avatar_id
end

function BattlePlayerPrepareInfo:SetChannel(szChannel)
    self.szChannel = szChannel
end

function BattlePlayerPrepareInfo:SetMatchType(nMatchType)
    self.nMatchType = nMatchType
end

function BattlePlayerPrepareInfo:FillAvatarByHumanId(nHumanId)
    local tbHumanResTemplate = HumanDataTable:GetResData(nHumanId)
    self:SetAppearanceFromPartData(tbHumanResTemplate.tbAppearance)
    self:SetHumanFashion(tbHumanResTemplate.tbFashionTemplateIds)
    self:SetHumanFashionFlag(tbHumanResTemplate.nHumanOverrideFlag)
end


function BattlePlayerPrepareInfo:FillHumanWeaponAvatarByHumanId(nHumanId)
    local tbHumanResTemplate = HumanDataTable:GetResData(nHumanId)
    self:SetHumanWeaponFashion(tbHumanResTemplate.tbWeaponFashionTemplateIds)
end

return BattlePlayerPrepareInfo