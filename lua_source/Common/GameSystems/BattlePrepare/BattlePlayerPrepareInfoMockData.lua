local BattlePlayerPrepareInfoMockData = {}

local BattlePlayerPrepareInfoClass = require("BattlePlayerPrepareInfo")
local MockDungeonDataTable = require("MockDungeonDataTable")
local LandmarkTypeDef = require("LandmarkTypeDef")

local DEFAULT_HUMAN_ID = 100000

BattlePlayerPrepareInfoMockData.tbPresetBattlePlayerPrepareInfoArray = {}
BattlePlayerPrepareInfoMockData.nCurrentDefaultIdx = 0
BattlePlayerPrepareInfoMockData.nInstanceId = 0

local nHumanId = nil

local function GetHumanIdFromServerGameOptions()
    if not nHumanId then
        if not GWithEditor then
            nHumanId = DEFAULT_HUMAN_ID
            return nHumanId
        end
        local pLevelEditorPlaySettings = ExtendBlueprintFunctions.GetMutableDefaultObject(LevelEditorPlaySettings)
        local szServerGameOptions = pLevelEditorPlaySettings.AdditionalServerGameOptions
        local szHumanId = GameplayStatics.ParseOption(szServerGameOptions, "HumanId")
        nHumanId = tonumber(szHumanId)
        if (not nHumanId) or (nHumanId <= 0) then
            nHumanId = DEFAULT_HUMAN_ID
        end
    end
    return nHumanId
end


function BattlePlayerPrepareInfoMockData:LoadTemplateInfo()
    self.tbPresetBattlePlayerPrepareInfoArray = {}
    local tbMockTemplates = MockDungeonDataTable:GetAllTemplates()
    for nPlayerId, tbMockTemplate in pairs(tbMockTemplates) do
        local tbNewInfo = BattlePlayerPrepareInfoClass()
        tbNewInfo.nPlayerId = tbMockTemplate.nPlayerId
        tbNewInfo.szPlayerSessionId = ""
        tbNewInfo.szPlayerName = tbMockTemplate.szPlayerName
        tbNewInfo.nHumanId = GetHumanIdFromServerGameOptions()
        tbNewInfo.nGroupIndex = tbMockTemplate.nGroupIndex
        tbNewInfo.nToken = tbMockTemplate.nToken
        tbNewInfo.nX = 0
        tbNewInfo.nY = 0
        tbNewInfo.nZ = 0
        tbNewInfo.nYaw = 0
        tbNewInfo.tbShipInfo = {}
        tbNewInfo.tbShipInfo.nTypeId = tbMockTemplate.nShipTemplateId

        tbNewInfo:SetDefaultInitItems()

        -- 配置副本中可建造物品
        tbNewInfo:SetDefaultShipPreparation()

        -- 配置舰船皮肤
        -- tbNewInfo.tbShipSkinIds = { 2060029 }

        -- 配置人饰品
        -- tbNewInfo.tbHumanDecorationIds = {1200004}
        -- tbNewInfo.tbHumanDecorationIds = { 1200019, 1201019, 1202019, 1203019, 1204019, 1205019 }

        -- 配置上阵水手
        -- tbNewInfo.tbSailorIds = { 1520105, 1520105, 1520105, 1520105, 1520105, 1520105, 1520105, 1520105, 1520105, 1520105 }

        -- 配置上阵伙伴
        -- tbNewInfo.tbPartners = {
        --     {
        --         partner_id = 1610001,
        --         level = 6
        --     },
        --     {
        --         partner_id = 1610004,
        --         level = 6
        --     }
        -- }

        tbNewInfo.tbLandmarkDatas = {}
        for i=1,LandmarkTypeDef.MAX do
            local tbLandmarkData = {}
            tbLandmarkData.id = i
            tbLandmarkData.grade = 0
            table.insert(tbNewInfo.tbLandmarkDatas, tbLandmarkData)
        end

        table.insert(self.tbPresetBattlePlayerPrepareInfoArray, tbNewInfo)
    end
end

function BattlePlayerPrepareInfoMockData:GetInstanceInfo(nPlayerId)
    local tbDefaultInfo = self.tbPresetBattlePlayerPrepareInfoArray[self.nCurrentDefaultIdx + 1]
    self.nCurrentDefaultIdx = (self.nCurrentDefaultIdx + 1) % (#self.tbPresetBattlePlayerPrepareInfoArray)
    local tbNewInfo = tbDefaultInfo()
    tbNewInfo.nPlayerId = nPlayerId

    self.nInstanceId  = self.nInstanceId + 1
    tbNewInfo.nX = self.nInstanceId * 3000
    tbNewInfo:FillAvatarByHumanId(tbNewInfo.nHumanId)
    tbNewInfo:FillHumanWeaponAvatarByHumanId(tbNewInfo.nHumanId)
    return tbNewInfo
end

return BattlePlayerPrepareInfoMockData
