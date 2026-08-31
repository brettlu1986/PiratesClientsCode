-- 废弃！

local M = {}

-- local GameObjectSystem = require("GameObjectSystem_C")
-- local GameObjectTypeDef = require("GameObjectTypeDef")

-- local PrepareLocalDungeonDataHelper = require("PrepareLocalDungeonDataHelper")
-- local ProcedureTool = require("ProcedureTool")
-- local GlobalVariableSystem = require("GlobalVariableSystem_C")

-- local BattlePlayerPrepareInfoClass = require("BattlePlayerPrepareInfo")
-- local TemplateTypeDef = require("TemplateTypeDef")
-- local BattlePrepareSystem = require("BattlePrepareSystem")
-- local LandmarkTypeDef = require("LandmarkTypeDef")
-- local TutorialDataTable = require("TutorialDataTable")
-- local BattleItemInitHelper = require("BattleItemInitHelper")
-- local TEMPLATE_ID = 650
-- local TemplateData = TutorialDataTable:GetTemplate(TEMPLATE_ID)

-- local PLAYER_NAME = TemplateData.szSelfName
-- local TUTORIAL_DUNGEON_ID = 80000
-- local PLAYER_ID = 1000
-- local TOKEN = 123456
-- local HUBSERVER_ID = 99999

-- local CreateMockPlayerSelf = function()
--     GlobalVariableSystem:SetInDungeon(true)
--     GlobalVariableSystem:SetStandalone(true)

--     local tbCreateData = {}
--     tbCreateData.bCreateComponents = true
--     tbCreateData.bCreateUEActor = false
--     tbCreateData.nTemplateId = -1
--     tbCreateData.nServerInstanceId = 0
--     tbCreateData.nPlayerId = PLAYER_ID
--     tbCreateData.nToken = TOKEN
--     tbCreateData.nTemplateType = TemplateTypeDef.SHIP
--     local PlayerSelf = GameObjectSystem:Create(GameObjectTypeDef.PlayerSelf, tbCreateData, nil)
--     PlayerSelf.nHubServerId = HUBSERVER_ID

--     return PlayerSelf
-- end

-- local PrepareData = function()
--     local nDungeonId = TUTORIAL_DUNGEON_ID

--     local tbNewInfo = BattlePlayerPrepareInfoClass()

--     tbNewInfo.nPlayerId = PLAYER_ID
--     tbNewInfo.szPlayerName = PLAYER_NAME
--     tbNewInfo.nHumanId = GlobalVariableSystem:GetNewRoleAvatarId()
--     tbNewInfo.nGroupIndex = 1

--     tbNewInfo.nToken = TOKEN
--     tbNewInfo.nX = 0
--     tbNewInfo.nY = 0
--     tbNewInfo.nZ = 0
--     tbNewInfo.nYaw = 0

--     tbNewInfo:SetDefaultShipPreparation()

--     tbNewInfo.tbLandmarkDatas = {}
--     for i=1,LandmarkTypeDef.MAX do
--         local tbLandmarkData = {}
--         tbLandmarkData.id = i
--         tbLandmarkData.grade = 0
--         table.insert(tbNewInfo.tbLandmarkDatas, tbLandmarkData)
--     end

--     return nDungeonId, tbNewInfo
-- end

-- function M:EnterTutorialDungeon()
--     GlobalVariableSystem:SetWithoutHub(true)

--     local nDungeonId, tbData = PrepareData()

--     PrepareLocalDungeonDataHelper:PushExternalData(tbData)

--     tbData:SetDefaultInitItems(tbItems)
--     BattlePrepareSystem:AddPlayerPrepareInfo(tbData)
--     ProcedureTool:EnterLocalDungeon(nDungeonId)
-- end

return M
