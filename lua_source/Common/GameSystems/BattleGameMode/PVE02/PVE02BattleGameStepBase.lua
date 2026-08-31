local luaclass = require("luaclass")
local BattleStepBaseClass = require("BattleStepBase")
local PVE02BattleGameStepBase = luaclass("PVE02BattleGameStepBase", BattleStepBaseClass)

local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local SpawnerSystem = require("SpawnerSystem")
local BattleInteractionHelper = require("BattleInteractionHelper")
local D2CHelper = require("D2CHelper")

PVE02BattleGameStepBase.nPreStepStatusId = nil

function PVE02BattleGameStepBase:ParseDummiesJsonData(tbDummyJsonTableFile, nGroupIndex)
    local tbJsonOutput = {}
    if tbDummyJsonTableFile == nil then
        log("No dummy found.")
        return tbJsonOutput
    end
    for _, tbDummy in ipairs(tbDummyJsonTableFile) do
        if tbDummy.GroupIndex == nGroupIndex then
            table.insert(tbJsonOutput, tbDummy)
        end
    end
    log("There are ", #tbJsonOutput, " dummies")
    return tbJsonOutput
end

function PVE02BattleGameStepBase:SpawnDummies(tbInputJsonData)
    local tbInstanceOutput = {}
    if tbInputJsonData == nil then
        log("No dummy need to spawn.")
        return tbInstanceOutput
    end
    for _, tbDummyJson in ipairs(tbInputJsonData) do
        local tbDummyInstance = SpawnerSystem:SpawnById(tbDummyJson.SpawnerId, false)
        assert(tbDummyInstance ~= nil, "Spawn dummy "..tbDummyJson.SpawnerId.."failed")
        table.insert(tbInstanceOutput, tbDummyInstance)
    end
    return tbInstanceOutput
end

function PVE02BattleGameStepBase:DestoryDummies(tbInstances)
    if tbInstances == nil then
        return
    end
    for _, tbDummy in ipairs(tbInstances) do
        GameObjectSystem:DestroyDummyInGameMode(tbDummy:GetUEActorUniqueId())
    end
end

function PVE02BattleGameStepBase:ShowDialog(nDialogId)
    -- 停船
    D2CHelper:MulticastStopMove()

    -- 退出瞄准鱼雷等模式，恢复正常模式
    D2CHelper:MulticastSwitchCommonHandlerMode()

    -- 显示对话
    BattleInteractionHelper:ShowDialog(nDialogId)
end

function PVE02BattleGameStepBase:SetParams(tbGameState, tbTemplateData, tbJsonTableFile)
    self.nPreStepStatusId = tbTemplateData.nPreStepStatusId
end

function PVE02BattleGameStepBase:Start()
    -- 加状态（加血）
    local nPreStepStatusId = self.nPreStepStatusId
    if nPreStepStatusId and nPreStepStatusId > 0 then
        local tbGameObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
        for tbGameObject, _ in pairs(tbGameObjects) do
            if not tbGameObject:IsDead() then
                tbGameObject.BuffComponentServer:AddBuffById(nPreStepStatusId)
            end
        end
    end
    PVE02BattleGameStepBase.super.Start(self)
end

return PVE02BattleGameStepBase
