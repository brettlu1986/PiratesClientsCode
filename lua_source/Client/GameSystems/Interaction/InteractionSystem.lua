-----------------------------------------------------
--File Name    : InteractionSystem.lua
--Author       : Zuo Kun
--Create Time  : 2017-03-13
--Description  : 交互System
-----------------------------------------------------
local InteractionSystem = {}

local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UIDef = require("UIDef")
local SelfEventHelper = require("SelfEventHelper")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local InteractionRegister = require("InteractionRegister")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local ProtoDC = require("DungeonCommonProtoNames")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local GameObjectTypeDef = require("GameObjectTypeDef")


InteractionSystem.EventHelper = nil

InteractionSystem.nSelectNpcID = 0
-- InteractionSystem.tbInteractionCondations = {}
InteractionSystem.tbInteractions = {}
InteractionSystem.tbInteractionTemplate = nil
InteractionSystem.nInteractionType = 0
InteractionSystem.tbCurrentInteraction = nil
InteractionSystem.tbInteractionInstances = {}


function InteractionSystem:Init()
	self.EventHelper = SelfEventHelper()
	
	self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_REQUEST_INTERACTION, self, self.UIRequestInteractive)
	self.EventHelper:RegisterEvent(ClientEventDef.EV_INTERACTION_CHANGE, self, self.InteractionChange)
	self.EventHelper:RegisterEvent(ClientEventDef.EV_INTERACTION_START, self, self.OnInteractionStart)
	self.EventHelper:RegisterEvent(ClientEventDef.EV_INTERACTION_END, self, self.OnInteractionEnd)
	self.EventHelper:RegisterEvent(ClientEventDef.EV_INTERACTION_ABORT, self, self.OnInteractionAbort)
	-- self.EventHelper:RegisterEvent(ClientEventDef.EV_PRE_LOAD_MAP, self, self.OnPreLoadMap)
	self.EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_LOADING, self, self.OnPreLoadMap)
	-- self.EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_WILD, self, self.OnPreLoadMap)
	self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_COLLECTION_BREAK, self, self.OnCollectionBreak)
	self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)

	-- InteractionRegister:RegisterAllCondation(self)
	InteractionRegister:RegisterAllInteraction(self)
end

function InteractionSystem:Uninit()
	self.EventHelper:UnregisterAll()
	self.EventHelper = nil
	self.tbInteractions = {}

	if self.tbCurrentInteraction  then
		self.tbCurrentInteraction:OnInteractionEnd()
		self.tbCurrentInteraction = nil 
	end		

	for i,v in ipairs(self.tbInteractionInstances) do
		v:OnInteractionEnd()
	end
end

--[[function InteractionSystem:RegisterCondation(InteractionCondationClass)
    table.insert(self.tbInteractionCondations, InteractionCondationClass())
end]]
function InteractionSystem:RegisterInteraction(InteractionClass)
	-- table.insert(self.tbInteractions, InteractionImplementClass())
	local tbImplement = InteractionClass()
	self.tbInteractions[tbImplement.nInteractionType] = tbImplement
end

--交互检查
function InteractionSystem:InteractionChange(isVisible, nInteractionType, pNpc)
	if not pNpc then
		self.nSelectNpcID = 0
		self.EventHelper:FireEvent(ClientEventDef.EV_UI_INTERACTION_VISIBLE, false)
		if self.tbCurrentInteraction and self.tbCurrentInteraction:CanStop() then
			self.tbCurrentInteraction:OnInteractionEnd()
			self.tbCurrentInteraction = nil
		end		
		return
	end
	self.nSelectNpcID = pNpc.nServerInstanceId
	self.EventHelper:FireEvent(ClientEventDef.EV_UI_INTERACTION_VISIBLE, isVisible, nInteractionType, self.nSelectNpcID)

	if GlobalVariableSystem:IsInDungeon() then
		NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_BattleTriggerInteractionNpc, {npc_instanceid = pNpc.nServerInstanceId})
	end
	
end
--UI请求交互
function InteractionSystem:UIRequestInteractive(pNpc)
	if self.tbCurrentInteraction then 
		return 
	end 
	local tbSelectedNpc = pNpc
	if not pNpc then
		local PlayerSelf = GamePlayerSelfHelper:Get()
		if PlayerSelf.ActorSelectorComponent then
			tbSelectedNpc = PlayerSelf.ActorSelectorComponent:GetSelectedNpc(true)
		end
	end
	if tbSelectedNpc then
		self.nSelectNpcID = tbSelectedNpc.nServerInstanceId
		if GlobalVariableSystem:IsInDungeon() then
			local PlayerSelf = GamePlayerSelfHelper:Get()
			NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_BattleStartInteractionNpc, { npc_instanceId = tbSelectedNpc.nServerInstanceId, player_instanceId = PlayerSelf.nServerInstanceId })
		else
			-- NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_NpcDialogue, {actor_id = tbSelectedNpc.nServerInstanceId})
			if tbSelectedNpc.tbNpcTemplateData.nInteractionType == 4 then
				EventManager:OnFireEvent(ClientEventDef.EV_FISHING_REQUEST, tbSelectedNpc.nServerInstanceId)
			elseif tbSelectedNpc.tbNpcTemplateData.nInteractionType > 5 and tbSelectedNpc.tbNpcTemplateData.nInteractionType <= 10 then
				--海上随机采集和陆地采集
				EventManager:OnFireEvent(ClientEventDef.EV_RANDOM_GATHER_START, tbSelectedNpc.nServerInstanceId)
			else
				NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_NpcDialogue, {actor_id = tbSelectedNpc.nServerInstanceId})
			end
		end
	else 
		log("InteractionSystem:UIRequestInteractive nil select npc")
	end
end

-- local function IsInRange( Npc )
-- 	if not Npc or not Npc.tbNpcTemplateData then 
-- 		return true 
-- 	end 
-- 	local nMaxDistance = Npc.tbNpcTemplateData.nDistance
-- 	local PlayerSelf = GamePlayerSelfHelper:Get()
-- 	if Npc.pUEActor then
-- 		local nDistance = PlayerSelf.pUEActor:GetDistanceTo(Npc.pUEActor)
-- 		return (nDistance < nMaxDistance and nDistance > 0) 
-- 	end
-- 	return false 
-- end


function InteractionSystem:OnInteractionStart(nInteractionType, tbParams, inNpc, fnOnInteractionEnd, fnParent)
	log("OnInteractionStart " .. nInteractionType)
	local tbInteraction = self.tbInteractions[nInteractionType]
	if not tbInteraction then 
		return nil 
	end 	
	
	
	local tbNpc = GameObjectSystem:FindByInstanceId(self.nSelectNpcID)
	if inNpc then 
		tbNpc = inNpc
	end 
	if not tbNpc then 
		local PlayerSelf = GamePlayerSelfHelper:Get()
		if PlayerSelf and PlayerSelf.ActorSelectorComponent then
			tbNpc = PlayerSelf.ActorSelectorComponent:GetSelectedNpc(true)
		end
	end 

	-- if tbNpc and not IsInRange(tbNpc) then 
    --     -- EventManager:OnFireEvent(ClientEventDef.EV_INTERACTION_ABORT)
    --     log("Error Npc So Far")
	-- 	return 
	-- end 

	if self.tbCurrentInteraction and tbInteraction:IsSingleInstance() then
		if fnOnInteractionEnd then 
			self.tbCurrentInteraction.OnComplete:Bind(fnOnInteractionEnd, fnParent)
		end 		
		self.tbCurrentInteraction:RefreshInteractionData(tbParams)		
		log("Current Interaction Is Not Completed " .. nInteractionType)
		return nil 
	end

	if not tbInteraction:IsSingleInstance(tbParams) then
		for i,v in ipairs(self.tbInteractionInstances) do
			if not v:IsEnableInteraction(tbNpc, tbParams) then 
				if fnOnInteractionEnd  then 
					v.OnComplete:Bind(fnOnInteractionEnd, fnParent)
				end 			
				v:RefreshInteractionData(tbParams)
				return nil 
			end 
		end
		local tbInstance = tbInteraction()
		tbInstance:Init(self)
		table.insert(self.tbInteractionInstances, tbInstance)
		if fnOnInteractionEnd then 
			tbInstance.OnComplete:Bind(fnOnInteractionEnd, fnParent)
		end 		
		tbInstance:DoInteraction(tbNpc, tbParams)
		return tbInstance 
	else
		self.tbCurrentInteraction = tbInteraction
	end
	
	if not self.tbCurrentInteraction then
		logerror("Error Interaction Type " .. nInteractionType)
		return
	end
	log("nInteractionType " .. nInteractionType)
	self.tbCurrentInteraction:Init(self)
	if fnOnInteractionEnd then 
		self.tbCurrentInteraction.OnComplete:Bind(fnOnInteractionEnd, fnParent)
	end 	
	self.tbCurrentInteraction:DoInteraction(tbNpc, tbParams)
	return tbInteraction
end

function InteractionSystem:RemoveInstance(tbInstance)
	for i, v in ipairs(self.tbInteractionInstances) do
		if tbInstance == v then
			table.remove(self.tbInteractionInstances, i)
		end
	end
end
local function CheckInteractionBtnVisible(self)
	local PlayerSelf = GamePlayerSelfHelper:Get()
	if PlayerSelf and PlayerSelf.ActorSelectorComponent then
		local tbSelectedNpc = PlayerSelf.ActorSelectorComponent:GetSelectedNpc()
		if tbSelectedNpc then
			self.EventHelper:FireEvent(ClientEventDef.EV_UI_INTERACTION_VISIBLE, true, tbSelectedNpc.tbNpcTemplateData.nInteractionType, tbSelectedNpc.nServerInstanceId)
		else 
			self.EventHelper:FireEvent(ClientEventDef.EV_UI_INTERACTION_VISIBLE, false)
		end
	end
end 

function InteractionSystem:OnInteractionAbort(nType)
	if nType then 
		if self.tbCurrentInteraction and self.tbCurrentInteraction.nInteractionType == nType then
			self.tbCurrentInteraction:InteractionAbort()
			self.tbCurrentInteraction = nil
			CheckInteractionBtnVisible(self)
		end 
		return 
	end 
	if self.tbCurrentInteraction then
		self.tbCurrentInteraction:InteractionAbort()
		self.tbCurrentInteraction = nil
	end
	CheckInteractionBtnVisible(self)
end 

function InteractionSystem:OnInteractionEnd()
	if self.tbCurrentInteraction then
		self.tbCurrentInteraction:InteractionEnd()
		self.tbCurrentInteraction = nil
		CheckInteractionBtnVisible(self)
		self.EventHelper:FireEvent(ClientEventDef.EV_INTERACTION_EXIT, true)
	end
end

function InteractionSystem:OnPreLoadMap()
	if self.tbCurrentInteraction then 
		self.tbCurrentInteraction:InteractionAbort()
		self.tbCurrentInteraction = nil
	end 
	self.nSelectNpcID = 0
end


function InteractionSystem:MergeInteraction(nInteractionType)
	if not self.tbCurrentInteraction then
		return true
	end
	
	if self.tbCurrentInteraction.nInteractionType == nInteractionType then
		return true
	end
	
	return false
end

function InteractionSystem:OnChangeInteraction(nServerInstanceId, bIsInteraction)
	
	local tbNpc =  GameObjectSystem:FindByInstanceId(nServerInstanceId)
	if tbNpc ~= nil and tbNpc.HeadInfoComponent  ~= nil then
		tbNpc.bEnableInteraction = bIsInteraction
		if bIsInteraction then
			tbNpc:CreateInteractionTrigger()
		else
			tbNpc:DestroyInteractionTrigger()
		end
		
		tbNpc.HeadInfoComponent:SetWidgetVisibility(UIDef.UP_NPC_HEAD_ICON_WIDGET,bIsInteraction)
	end
end

function InteractionSystem:OnPawnDead(tbDeadActor)
	if tbDeadActor and tbDeadActor.ObjectType == GameObjectTypeDef.PlayerSelf then
		self:OnInteractionAbort()
		self.EventHelper:FireEvent(ClientEventDef.EV_UI_INTERACTION_VISIBLE, false)
        -- NetworkManager:GetRPCNetworkProxy():SendToClient(tbDeadActor:GetUEControllerUniqueId(), ProtoDC.d2c_InteractionEnd)
    end   	
end 

function InteractionSystem:OnCollectionBreak(nNpcServerInstanceId)
	if not nNpcServerInstanceId or not GlobalVariableSystem:IsInDungeon() then 
		return 
	end 
	local tbNpc =  GameObjectSystem:FindByInstanceId(nNpcServerInstanceId)
	if tbNpc ~= nil then							             
		NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_CollectionBreak, { npc_instanceid = nNpcServerInstanceId })
	end
end

function InteractionSystem:OnDungCollectionBreak()
	if self.tbCurrentInteraction then
		self.tbCurrentInteraction:InteractionEnd()
		local PlayerSelf = GamePlayerSelfHelper:Get()
		if PlayerSelf and PlayerSelf.ActorSelectorComponent then
			local tbSelectedNpc = PlayerSelf.ActorSelectorComponent:GetSelectedNpc()
			if tbSelectedNpc then
				self.EventHelper:FireEvent(ClientEventDef.EV_UI_INTERACTION_VISIBLE, true, tbSelectedNpc.tbNpcTemplateData.nInteractionType, tbSelectedNpc.nServerInstanceId)
			end
		end
		self.tbCurrentInteraction = nil
	end
end

return InteractionSystem 