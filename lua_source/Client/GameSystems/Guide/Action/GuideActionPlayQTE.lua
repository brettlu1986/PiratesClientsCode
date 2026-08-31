-----------------------------------------------------
--File Name    : GuideActionPlayQTE.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideAction = require("GuideAction")
local GuideActionPlayQTE = luaclass("GuideActionPlayQTE",GuideAction)

-- local ClientEventDef = require("ClientEventDef")
-- local UIManager = require("UIManager")
-- local UIDef = require("UIDef")
-- local QTEDataTable = require("QTEDataTable")
-- local MatineeSystem = dynamic_require("MatineeSystem")
-- local UIStateDef = require("UIStateDef")

-- --[[
-- note:
-- 按分组顺序播放matinee
-- 当收到玩家点击事件，播放下一段matinee，matinee结束后，当有多组qte时，切换到下一组的第一段matinee
-- --]]

-- GuideActionPlayQTE.nQTEStepIndex = nil
-- GuideActionPlayQTE.nQTEStageIndex = nil
-- GuideActionPlayQTE.nQTECount = nil
-- GuideActionPlayQTE.bReceive = nil
-- GuideActionPlayQTE.tbQTEGroupList = nil
-- GuideActionPlayQTE.CurrentMatinee = nil
-- GuideActionPlayQTE.bReceiveQTE = false

-- local QTE_STEP = 1
-- local QTE_START = 1


-- local function PlayMatinee(self)
--     local tbStageMatinee = self.tbQTEGroupList[self.nQTEStageIndex]
--     if not tbStageMatinee then
--         self:EndAction()
--         return
--     end
--     local nMatineeId = tbStageMatinee[self.nQTEStepIndex]
--     if not nMatineeId then
--         self:EndAction()
--         return
--     end
--     local bLoop = false
--     self:DebugLog("PlayMatinee:self.nQTEStepIndex,self.nQTEStageIndex=",self.nQTEStepIndex,self.nQTEStageIndex)
--     if QTE_STEP == self.nQTEStepIndex and QTE_START == self.nQTEStageIndex then
--         bLoop = true
--     end
--     self:DebugLog("PlayMatinee,nMatineeId, bLoop=",nMatineeId, bLoop)
--     --self.CurrentMatinee = InteractionHelper:CreateMatinee(nMatineeId, bLoop)
--     self.bReceiveQTE = false
--     local function OnPlay()
--         UIManager:PushState(UIStateDef.StateName.UI_MATINEE_STATE, nil)
--         --隐藏空气墙
--         local BlockActos = ExtendBlueprintFunctions.GetLevelActorsByTag(GWorld, "BlockActor")	
-- 		if BlockActos then 
-- 			for i,v in ipairs(BlockActos) do
-- 				v:SetActorHiddenInGame(true)
-- 			end
--         end 
--         --
--     end
--     self.CurrentMatinee = MatineeSystem:PlayMatinee(nMatineeId, bLoop, function() self:OnInteractionEnd() end, OnPlay)
-- end

-- local function LoadQTEData(self)
--     local tbQTEGroup = self.tbTemplate.tbQTEId
--     local tbQTEGroupList = {}
--     for _, v in ipairs(tbQTEGroup) do
--         local tbTemplate = QTEDataTable:GetTemplate(v)
--         if tbTemplate then
--             local tbMatineeList = {}
--             table.insert(tbMatineeList, tbTemplate.nQTEMatineeId)
--             table.insert(tbMatineeList, tbTemplate.nEndMatineeId)
--             table.insert(tbQTEGroupList, tbMatineeList)
--         end
--     end
--     return tbQTEGroupList
-- end

-- function GuideActionPlayQTE:Begin()
--     self.tbQTEGroupList = LoadQTEData(self)
--     if #self.tbQTEGroupList == 0 then
--         return
--     end
--     GuideActionPlayQTE.super.Begin(self)
--     UIManager:CloseWnd(UIDef.UI_GUIDE)
--     self.nQTEStageIndex = 1
--     self.nQTEStepIndex = 1
--     self.EventHelper:RegisterEvent(ClientEventDef.EV_INTERACTION_EXIT, self, self.OnInteractionEnd)
--     self.EventHelper:RegisterEvent(ClientEventDef.EV_ON_MATINEE_QTE_END, self, self.OnReceiveOperateion)
--     PlayMatinee(self)
-- end

-- function GuideActionPlayQTE:OnInteractionEnd()
--     --恢复空气墙
--     local BlockActos = ExtendBlueprintFunctions.GetLevelActorsByTag(GWorld, "BlockActor")	
--     if BlockActos then 
--         for i,v in ipairs(BlockActos) do
--             v:SetActorHiddenInGame(false)
--         end
--     end 
--     --
--     local nQTEStepIndex = self.nQTEStepIndex
--     local nQTEStageIndex = self.nQTEStageIndex
--     local tbQTEGroupList = self.tbQTEGroupList
--     local tbStageMatinee = tbQTEGroupList[self.nQTEStageIndex]
--     self:DebugLog("GuideActionPlayQTE:OnInteractionEnd,stepcount, stagecount,nQTEStepIndex,nQTEStageIndex=", #tbStageMatinee, #tbQTEGroupList, nQTEStepIndex, nQTEStageIndex)
--     if not self.bReceiveQTE then
--         if nQTEStepIndex < #tbStageMatinee then
--             --qte所在matinee未点中时结束
--             self.nQTEStageIndex = 1
--             self.nQTEStepIndex = 1
--             PlayMatinee(self)
--         elseif nQTEStageIndex < #tbQTEGroupList then
--             self.nQTEStageIndex = nQTEStageIndex + 1
--             self.nQTEStepIndex = 1
--             PlayMatinee(self)
--         elseif nQTEStageIndex == #tbQTEGroupList then
--             self:EndAction()
--         end
--     end
    
--     -- if nQTEStepIndex == #tbStageMatinee and nQTEStageIndex < #tbQTEGroupList then
--     --     self.nQTEStageIndex = nQTEStageIndex + 1
--     --     self.nQTEStepIndex = 1
--     --     PlayMatinee(self)
--     -- elseif nQTEStepIndex == #tbStageMatinee and nQTEStageIndex == #tbQTEGroupList then
--     --     self:EndAction()
--     -- end
-- end

-- function GuideActionPlayQTE:OnReceiveOperateion(bIsClick)
--     self:DebugLog("GuideActionPlayQTE:OnReceiveOperateion,bIsClick",bIsClick)
--     if not bIsClick then
--         return
--     end
--     local nQTEStepIndex = self.nQTEStepIndex
--     local nQTEStageIndex = self.nQTEStageIndex
--     local tbStageMatinee = self.tbQTEGroupList[nQTEStageIndex]
    
--     if not tbStageMatinee then
--         self:EndAction()
--         return
--     end
--     self.bReceiveQTE = true
--     self:DebugLog("GuideActionPlayQTE:OnReceiveOperateion,stepcount,nQTEStepIndex,nQTEStageIndex=",#tbStageMatinee,nQTEStepIndex,nQTEStageIndex)
--     if nQTEStepIndex < #tbStageMatinee then
--         self.CurrentMatinee:StopMatinee()
--         self.nQTEStepIndex = nQTEStepIndex + 1
--         PlayMatinee(self)
--     else
--         logwarning("GuideActionPlayQTE:OnReceiveOperateion, no next step matinee, nQTEStageIndex, nQTEStepIndex=", nQTEStageIndex, nQTEStepIndex)
--     end
    
-- end

return GuideActionPlayQTE