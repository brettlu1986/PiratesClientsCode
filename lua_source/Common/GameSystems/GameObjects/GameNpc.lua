-- NPC角色

local luaclass = require("luaclass")
local GameCharacterClass = dynamic_require("GameCharacter")
local GameNpc = luaclass("GameNpc", GameCharacterClass)

local L10N = require("L10N")
local NPCDataTable = require("NPCDataTable")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local GameNpcType = require("GameNpcType")
local TemplateTypeDef = require("TemplateTypeDef")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local NpcInitItemRandomDataTable = require("NpcInitItemRandomDataTable")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local SAILogicDef = require("SAILogicDef")

GameNpc.tbNpcTemplateData = nil
GameNpc.nGroupIndex = nil
GameNpc.nSubGroupIndex = nil
--npc是否可以交互 因为在副本中有可能会改变npc的交互状态 因为原来是读取表里面的数据要不能修改表里的源数据所以加了一个值
GameNpc.bEnableInteraction = false
GameNpc.bIsBoss = false
GameNpc.bIsBattleNPC = false
GameNpc.tbCheckInteraction = nil

-- tbCreateData : 在GOCreateDataHelper:ParseNpcGameModeData(tbJsonData)里生成的
function GameNpc:ParseCreateData(tbCreateData)
    if(not GameNpc.super.ParseCreateData(self, tbCreateData)) then
        return false
    end

    local tbTemplate = NPCDataTable:GetTemplate(self.nTemplateId)
    if(tbTemplate == nil) then
        logerror("GameNpc:OnPreCreate failed, nTemplateId:", self.nTemplateId, debug.traceback(  ))
        return false
    end

    self.tbNpcTemplateData = tbTemplate
    if tbCreateData.szName and string.len(tbCreateData.szName) > 0 then
        self.szName = tbCreateData.szName
    else
        self.szName = L10N:ToString(tbTemplate.l10nName)
    end

    self.nGroupIndex = tbCreateData.nGroupIndex
    self.nSubGroupIndex = tbCreateData.nSubGroupIndex

    self.nTemplateType = tbTemplate.nType
    self.bIsBoss = tbTemplate.bIsBoos or false
    self.bIsBattleNPC = tbTemplate.bIsBattleNPC or false

    if tbTemplate.nInteractionType ~= 0  then
        self.bEnableInteraction = true
    end

    return true
end

function GameNpc:OnPostCreate()
    GameNpc.super.OnPostCreate(self)
    if not GlobalVariableSystem:IsServerLogic() then
        return
    end
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    local tbRandomItems = {}
    local nInitItemRandomGroupId = self.tbNpcTemplateData.nInitItemRandomGroupId
    if nInitItemRandomGroupId > 0 then
        tbRandomItems = NpcInitItemRandomDataTable:GetRandomItems(nInitItemRandomGroupId)
    end

    if self.nTemplateType == TemplateTypeDef.SHIP then
        local tbData = {}
        tbData.nItemTemplateId = self.tbNpcTemplateData.nShipItemId
        tbData.nItemCount = 1
        table.insert(tbRandomItems, 1, tbData)
    end
    if #tbRandomItems > 0 then
        -- local BaseUtil = require("BaseUtil")
        -- BaseUtil:PrintTable(tbRandomItems, 3)
        BattleItemSystemServer:AddInitItems(self:GetServerInstanceId(), tbRandomItems)
    end
    self:CreateAI()

    EventManager:OnFireEvent(CommonEventDef.EV_GAME_OBJECT_ON_NPC_POST_CREATE, self)
end

function GameNpc:GetTemplateId()
    return self.tbNpcTemplateData.nTypeID
end

function GameNpc:GetActorClassByTemplateId(nTemplateId)
    local nTypeId = self.tbNpcTemplateData.nTypeID
    if self:IsShip() then
        local tbTemplate = NPCDataTable:GetTemplate(nTemplateId)
        nTypeId = tbTemplate.nShipTypeId
    end

    local szClassName = GameNpc.super.GetActorClassByTemplateId(self, nTypeId)
    if(szClassName == nil) then
        logerror("GameNpc:GetActorClassByTemplateId failed, npc id:",
            self.tbNpcTemplateData.nTemplateID)
    end
    return szClassName
end

function GameNpc:GetDebugInfo()
    return GameNpc.super.GetDebugInfo(self)
end

function GameNpc:GetGroupIndex()
    return self.nGroupIndex
end

function GameNpc:CreateAI()
    if self.tbNpcTemplateData.nAITemplateGradeId > 0 then
        local AIComponent = self.SAIComponent
        if AIComponent then
            AIComponent:EnableAI(SAILogicDef.NpcBattle)
        else
            error("GameNpc:CreateAI failed. self.pUEActor", self.pUEActor)
        end
    end
end

function GameNpc.StaticCollectResources(tbCreateData, tbCustomData)
    local nNpcId = tbCreateData.nTemplateId
    local tbTemplate = NPCDataTable:GetTemplate(nNpcId)
    if(tbTemplate == nil) then
        logerror("GameNpc:StaticCollectResources failed, npc id:", nNpcId)
        return nil
    end

    local nTemplateType = tbTemplate.nType
    local nTemplateId = tbTemplate.nTypeID
    return GameCharacterClass.StaticGetActorClass(nTemplateType, nTemplateId)
end

function GameNpc:GetNpcType()
    if GlobalVariableSystem:IsInDungeon() then
        if self.tbNpcTemplateData.nType == TemplateTypeDef.SHIP then
            return GameNpcType.BattleShipNpc
        elseif self.tbNpcTemplateData.nType == TemplateTypeDef.HUMAN then
             return GameNpcType.BattleHumanNpc
        elseif self.tbNpcTemplateData.nType == TemplateTypeDef.SHIPCOLLECTION or
            self.tbNpcTemplateData.nType == TemplateTypeDef.HUMANCOLLECTION then
            return GameNpcType.BattleCollection
        else
            return GameNpcType.None
        end
    else
        if self.nTemplateType == TemplateTypeDef.SHIP then
            return GameNpcType.HubShip
        elseif self.nTemplateType == TemplateTypeDef.HUMAN then
            return GameNpcType.HubHuman
        else
            return GameNpcType.None
        end
    end
end

function GameNpc:SetCheckInteractionClass(tbInteractionClass)
	self.tbCheckInteraction = tbInteractionClass()
	self.tbCheckInteraction:Init(self)
end

function GameNpc:CheckCanInteraction()
	if not self.tbCheckInteraction then
		return false
	end
	return self.tbCheckInteraction:CheckCanInteraction()
end

function GameNpc:GetTemplateData()
    return self.tbNpcTemplateData
end

function GameNpc:IsBattleNPC()
    return self.bIsBattleNPC
end

return GameNpc
