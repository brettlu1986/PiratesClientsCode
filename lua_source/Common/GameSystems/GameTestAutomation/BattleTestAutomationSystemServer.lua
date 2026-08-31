-----------------------------------------------------
--File Name    : BattleTestAutomationSystemServer.lua
--Author       : WuJizhou
--Create Time  : 7/26/2019, 8:59:50 PM
--Description  : BattleTestAutomationSystemServer
-----------------------------------------------------
local Timer                       = require("Timer")
local Proto                       = require("DungeonCommonProtoNames")
local CommonEventDef              = require("CommonEventDef")
--local AIShipDataProvider          = require("BattleTestAutomationAIShipDataProvider")
local SelfEventHelperClass        = require("SelfEventHelper")
local BattleItemDataTable         = require("BattleItemDataTable")
local BattleItemCategoryDef       = require("BattleItemCategoryDef")
local BattleItemSystemServer      = require("BattleItemSystemServer")
local GameTestAutomationLogHelper = require("GameTestAutomationLogHelper")

local NetworkManager              = dynamic_require("NetworkManager")
local GameObjectSystem            = dynamic_require("GameObjectSystem")
--local BattleTemplateActorSystem   = dynamic_require("BattleTemplateActorSystem")

local BattleTestAutomationSystemServer = {}

--local bAddedDynamicNode = false

local SelfEventHelper = nil
local tbAllAutomationTestPlayerIds = {}

local ADD_MATERIAL_TIMER = "ADD_MATERIAL_TIMER"

local function GetPlayer(nPlayerInstanceId)
    local tbPlayer = GameObjectSystem:FindByInstanceId(nPlayerInstanceId)
    return tbPlayer
end

local function IsPlayerAlive(nPlayerInstanceId)
    local tbPlayer = GetPlayer(nPlayerInstanceId)
    if not tbPlayer or tbPlayer:IsDead() then
        return false
    end
    return true
end

local function StopAddMaterialTimer(self)
    Timer.StopOwnerTimer(self, ADD_MATERIAL_TIMER)
end

local function OnFFAFinished(self)
    StopAddMaterialTimer(self)
    local d2c_NotifyClient = {}
    local RPCNetworkProxy = NetworkManager:GetRPCNetworkProxy()
    for _, nPlayerInstanceId in ipairs(tbAllAutomationTestPlayerIds) do
        local tbPlayer = GetPlayer(nPlayerInstanceId)
        if tbPlayer then
            local nUEControllerUniqueId = tbPlayer:GetUEControllerUniqueId()
            RPCNetworkProxy:SendToClient(nUEControllerUniqueId,  Proto.d2c_NotifyClientToQuitDungeon, d2c_NotifyClient)
        end
    end
end

local function StartAddMaterialTimer(self)
    Timer.StartOwnerTimer(self, ADD_MATERIAL_TIMER, function()
        for _, nPlayerInstanceId in ipairs(tbAllAutomationTestPlayerIds) do
            local tbTemplates = BattleItemDataTable:GetTemplatesByCategory(BattleItemCategoryDef.MATERIAL)
            for nTemplateId, tbTemplate in pairs(tbTemplates) do
                if IsPlayerAlive(nPlayerInstanceId) then
                    BattleItemSystemServer:AddItemByTemplate(nPlayerInstanceId, nTemplateId, 100)
                end
            end
        end
    end, 30 , true)
end

-- local function AddAllBuildItemBlueprint(self)
--     for _, nPlayerInstanceId in ipairs(tbAllAutomationTestPlayerIds) do
--         local tbPlayer = GetPlayer(nPlayerInstanceId)
--         if tbPlayer and not tbPlayer:IsDead() then
--             local tbBPTemplateIds = AIShipDataProvider:GetBuildWeaponBlueprints(nPlayerInstanceId)
--             for _, nItemTemplateId in ipairs(tbBPTemplateIds) do
--                 GameTestAutomationLogHelper.LogDebug("Add build bp", nPlayerInstanceId, nItemTemplateId)
--                 BattleItemSystemServer:AddItemByTemplate(nPlayerInstanceId, nItemTemplateId, 1)
--             end
--         end
--     end
-- end

local function OnParachutionEnd(self, tbGameObject)
    StartAddMaterialTimer(self)
end

function BattleTestAutomationSystemServer:StartAutotest(nPlayerInstanceId, tbParams)
    GameTestAutomationLogHelper.LogDebug("BattleTestAutomationSystemServer:StartAutotest")
    -- local tbPlayer = GetPlayer(nPlayerInstanceId)
    -- local pPlayerController = tbPlayer.pUEController
    -- local pUEActor = tbPlayer.pUEActor
    -- local AttachRule = EAttachmentRule.KeepRelative
    -- pPlayerController:K2_AttachToActor(pUEActor, "", AttachRule, AttachRule, AttachRule, false)
    -- pPlayerController:K2_SetActorRelativeLocation(Vector{X = 0, Y = 0, Z = 0}, true, true)
    -- local nShipTemplateId = tbParams["nShipTemplateId"]
    -- if nShipTemplateId then
    --     GameTestAutomationLogHelper.LogDebug("Set Ship Template", nPlayerInstanceId, nShipTemplateId)
    --     AIShipDataProvider:SetShipTemplateIds(nPlayerInstanceId, {nShipTemplateId})
    -- end
    -- local nWeaponTemplateId = tbParams["nWeaponTemplateId"]
    -- if nWeaponTemplateId then
    --     GameTestAutomationLogHelper.LogDebug("Set weapon Template", nPlayerInstanceId, nWeaponTemplateId)
    --     AIShipDataProvider:SetShipWeaponTemplateIds(nPlayerInstanceId, {nWeaponTemplateId})
    -- end
    -- local tbPlayers = {}
    -- table.insert(tbPlayers, tbPlayer)
    -- AutotestSystem:StartTest(tbPlayers, 1)
    -- if not bAddedDynamicNode then
    --     -- PiratesReplicationBPHelpers.AddActorToDynamicNode(pUEActor)
    --     bAddedDynamicNode = true
    -- end
    -- BattleTemplateActorSystem:SetWatchedTarget(tbPlayer, tbPlayer)
    -- table.insert(tbAllAutomationTestPlayerIds, nPlayerInstanceId)
    -- AddAllBuildItemBlueprint(self)
end

function BattleTestAutomationSystemServer:StopAutotest(nPlayerInstanceId)
    -- local tbPlayer = GetPlayer(nPlayerInstanceId)
    -- AutotestSystem:StopTest(tbPlayer)
end

function BattleTestAutomationSystemServer:Activate()
    SelfEventHelper = SelfEventHelperClass()
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_FFA_TEAM_WIN, self, OnFFAFinished)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_FFA_PARACHUTION_END, self, OnParachutionEnd)
    tbAllAutomationTestPlayerIds = {}
    StartAddMaterialTimer(self)
end

function BattleTestAutomationSystemServer:Deactivate()
    StopAddMaterialTimer(self)
    SelfEventHelper:UnregisterAll()
    SelfEventHelper = nil
    tbAllAutomationTestPlayerIds = nil
end

return BattleTestAutomationSystemServer