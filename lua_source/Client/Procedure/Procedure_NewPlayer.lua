local luaclass = require("luaclass")
local ProcedureBase = require("ProcedureBase")
local Procedure_NewPlayer = luaclass("Procedure_NewPlayer", ProcedureBase)
-- local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local ProcedureTool = require("ProcedureTool")
local ManagerRoot = require("ManagerRoot")
local ManagerGroupDef = require("ManagerGroupDef")
local InteractionHelper = require("InteractionHelper")
local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local MatineeSystem = dynamic_require("MatineeSystem")
-- local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local LOGIN_END_MATINEE_ID = 9
local LOGIN_END_MATINEE_STEP2 = 13
Procedure_NewPlayer.EventHelper = nil
Procedure_NewPlayer.nMatineeStep = 1

function Procedure_NewPlayer:Init()
    Procedure_NewPlayer.super.Init(self)
    self.EventHelper = SelfEventHelper()
end

function Procedure_NewPlayer:Begin()
    Procedure_NewPlayer.super.Begin(self)
    self:BindHubMethod()
    ManagerRoot:InitGroup(ManagerGroupDef.nLoginGroupID, true)

	-- local tbLoginMatinee = MatineeSystem:GetMatinee(CREATE_ROLE_LOOP_FEMALE_MATINEE_ID)
	-- if tbLoginMatinee then
	-- 	tbLoginMatinee:StopMatinee()
	-- end

	-- tbLoginMatinee = MatineeSystem:GetMatinee(CREATE_ROLE_LOOP_MALE_MATINEE_ID)
	-- if tbLoginMatinee then
	-- 	tbLoginMatinee:StopMatinee()
    -- end
    MatineeSystem:Clear()

    self.nMatineeStep = 1
    InteractionHelper:CreateMatinee(LOGIN_END_MATINEE_ID, false, nil, nil, false)

    -- local GamePlayerSelf = GamePlayerSelfHelper:Get()
    -- local pChannelSdkManager = GlobalVariableSystem:GetChannelSdkManager()
    -- local tbCurrentServerData = GlobalVariableSystem.tbCurrentServerData
    -- pChannelSdkManager:SetRoleIdAndName(tostring(GamePlayerSelf:GetPlayerId()), GamePlayerSelf.szName)
    -- pChannelSdkManager:SetServerIDAndName(tbCurrentServerData.id, tbCurrentServerData.name)
    -- pChannelSdkManager:OnCreateRole()
end

function Procedure_NewPlayer:End()
    self:UnbindHubMethod()
end

function Procedure_NewPlayer:OnMatineeEnd()
    if self.nMatineeStep == 1 then
        self.nMatineeStep = 2
        InteractionHelper:CreateMatinee(LOGIN_END_MATINEE_STEP2, false, nil, nil, false)
    else
        ProcedureTool:EnterLocalDungeon(self.Param.dungeon_id)
    end
end

function Procedure_NewPlayer:BindHubMethod()
    self.EventHelper:RegisterEvent(ClientEventDef.EV_INTERACTION_EXIT, self, self.OnMatineeEnd)
end

function Procedure_NewPlayer:UnbindHubMethod()
	self.EventHelper:UnregisterAll()
end

function Procedure_NewPlayer:Uninit()
    self:UnbindHubMethod()
    Procedure_NewPlayer.super.Uninit(self)
end

return Procedure_NewPlayer
