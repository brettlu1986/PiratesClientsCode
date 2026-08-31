--File Name    : MatineeLogicActor.lua
--Author       : Zuo Kun
--Create Time  : 2017-06-09
--Description  : MatineeLogicActor
-----------------------------------------------------
local luaclass = require("luaclass")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local MatineeLogicActor = luaclass("MatineeLogicActor")
local NpcHeadInfoComponent= require("NpcHeadInfoComponent")
local NPCDataTable = require("NPCDataTable")
local L10N = require("L10N")

MatineeLogicActor.pUEActor = nil
MatineeLogicActor.tbTemplateData = nil
MatineeLogicActor.nUniqueId = 0
MatineeLogicActor.nID = 0
MatineeLogicActor.nInstanceId = 0
MatineeLogicActor.DummyObject = nil

local nInstanceId = - 200000
function MatineeLogicActor:BindUEActor(pUEActor, nUniqueId)
	self.nID = pUEActor.nTemplateID
	if self.nID <= 0 then
		return false
	end

    local tbTemplate = NPCDataTable:GetTemplate(self.nID)
    if(tbTemplate == nil) then
        logerror("GameNpc:OnPreCreate failed, nTemplateId:", self.nID)
        return false
    end

	self.pUEActor = pUEActor

	self.nUniqueId = nUniqueId
	self.nInstanceId = nInstanceId
	-- local position = pUEActor:K2_GetActorLocation()
	local tbProtoData = {}
	tbProtoData.instance_id = nInstanceId
	tbProtoData.template_id = self.nID

--[[	local tbTrans = {}
	tbTrans.x = position.X
	tbTrans.y = position.Y
	tbTrans.z = position.Z
	tbTrans.yaw = 0
	tbProtoData.transform = tbTrans]]
	local Dummy = GameObjectSystem:BindDummyByReplicatedData(pUEActor, tbProtoData)
	Dummy.tbNpcTemplateData = tbTemplate
	Dummy.szName = L10N:ToString(tbTemplate.l10nName)

	Dummy.HeadInfoComponent = NpcHeadInfoComponent()
	Dummy.HeadInfoComponent:OnCreate(Dummy)
	Dummy.HeadInfoComponent:OnActorCreated(pUEActor)
	self.DummyObject = Dummy
    nInstanceId = nInstanceId - 1
	return true
end

function MatineeLogicActor:OnDestroyUEActor()
	if self.nID <= 0 then
		return
	end
	self.DummyObject.HeadInfoComponent:OnActorDestroyed(self.pUEActor)
	self.DummyObject.HeadInfoComponent:OnDestroy()
	GameObjectSystem:DestroyDummyInHub(self.nInstanceId)
	self.DummyObject = nil
end


return MatineeLogicActor