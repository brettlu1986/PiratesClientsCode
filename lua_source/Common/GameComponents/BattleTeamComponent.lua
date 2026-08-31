local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local BattleTeamComponent = luaclass("BattleTeamComponent", GameComponentBaseClass)

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleTeamCategoryDefine = require("BattleTeamCategoryDefine")
local TeamWatchServerHelper = require("TeamWatchServerHelper")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local PropName = require("PropName")

local ECategoryType = BattleTeamCategoryDefine.tbCategoryType

BattleTeamComponent.nTeamId = -1

--协议的Handle
BattleTeamComponent.rBattleTeamBaseInfo   = nil
BattleTeamComponent.rBattleTeamHealthInfo = nil
BattleTeamComponent.rBattleTeamStateInfo  = nil
BattleTeamComponent.rBattleTeamPosInfo    = nil
BattleTeamComponent.rBattleTeamSignInfo   = nil
BattleTeamComponent.rTeamPlayersInfo      = nil

--组件对于tbTeamdata是只读的，不允许在Component内进行修改
BattleTeamComponent.tbAllData   = nil --Team完整数据
BattleTeamComponent.tbTeamdata  = nil --兼容保留数据

BattleTeamComponent.bProtoValid = false

function BattleTeamComponent:OnCreate(Owner, tbParams)
    BattleTeamComponent.super.OnCreate(self, Owner, tbParams)
end

function BattleTeamComponent:OnActorCreated(pUEActor)
    BattleTeamComponent.super.OnActorCreated(self, pUEActor)

    log("BattleTeamComponent:OnActorCreated")
    self.bProtoValid = true

    local rComponent = self.Owner.CustomReplicationComponent

    self.rBattleTeamBaseInfo = rComponent:BindMethod(PropName.rBattleTeamBaseInfo,
        {}, self, self.OnBattleTeamBaseInfoChanged, false)

    self.rBattleTeamHealthInfo = rComponent:BindMethod(PropName.rBattleTeamHealthInfo,
        {}, self, self.OnBattleTeamHealthInfoChanged, false)

    self.rBattleTeamStateInfo = rComponent:BindMethod(PropName.rBattleTeamStateInfo,
        {}, self, self.OnBattleTeamStateInfoChanged, false)

    self.rBattleTeamPosInfo = rComponent:BindMethod(PropName.rBattleTeamPosInfo,
        {}, self, self.OnBattleTeamPosInfoChanged, false)

    self.rBattleTeamSignInfo = rComponent:BindMethod(PropName.rBattleTeamSignInfo,
        {}, self, self.OnBattleTeamSignInfoChanged, false)

    self.rTeamPlayersInfo = rComponent:BindMethod(PropName.rTeamPlayersInfo,
    {}, self, self.OnTeamPlayersInfoChanged, false)

    if GlobalVariableSystem:IsServerLogic() then
        self:OnDataChanged(ECategoryType.All)
    end
end

function BattleTeamComponent:OnActorDestroyed(pUEActor)
    log("BattleTeamComponent:OnActorDestroyed")
    self.bProtoValid = false
    BattleTeamComponent.super.OnActorDestroyed(self, pUEActor)
end

function BattleTeamComponent:OnDestroy()
    BattleTeamComponent.super.OnDestroy(self)
end

function BattleTeamComponent:OnBattleTeamBaseInfoChanged(_Property, tbBattleTeamBaseInfo)
end

function BattleTeamComponent:OnBattleTeamHealthInfoChanged(_Property, tbBattleTeamHealthInfo)
end

function BattleTeamComponent:OnBattleTeamStateInfoChanged(_Property, tbBattleTeamStateInfo)
end

function BattleTeamComponent:OnBattleTeamPosInfoChanged(_Property, tbBattleTeamPosInfo)
end

function BattleTeamComponent:OnBattleTeamSignInfoChanged(_Property, tbBattleTeamSignInfo)
end

function BattleTeamComponent:OnTeamPlayersInfoChanged(_Property, tbTeamPlayersInfo)
end

local function FindPlayerDataByInstanceId(self, nPlayerInstanceId)
    for Key, tbData in ipairs(self.tbTeamdata) do
        if tbData.nInstanceId == nPlayerInstanceId then
            return tbData
        end
    end

    return nil
end

--public function.
--设置数据指向，相同队伍的人员指向同一份数据
function BattleTeamComponent:SetTeamData(tbTeam)
    self.tbAllData  = tbTeam
    self.tbTeamdata = tbTeam.tbTeamData
end

--通过数据发送了变化
function BattleTeamComponent:OnDataChanged(eType)
    if not self.tbTeamdata then
        error("tbTeamdata is nil,check SetTeamData func.")
    end

    if not self.bProtoValid then
        return
    end

    TeamWatchServerHelper.RepBattleTeamData(eType, self.tbAllData, 
    self.rBattleTeamBaseInfo, self.rBattleTeamHealthInfo, self.rBattleTeamStateInfo, self.rBattleTeamPosInfo,
    self.rBattleTeamSignInfo, self.rTeamPlayersInfo)

    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_TEAMINFO_CHANGED, self.Owner, self.nTeamId, eType)
end

function BattleTeamComponent:AddToTeam(nTeamId)
    self.nTeamId = nTeamId
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_TEAM_ID_CHANGED, self.Owner, nTeamId)
end

function BattleTeamComponent:RemoveFromTeam()
    self.nTeamId = -1
end

function BattleTeamComponent:GetTeamLeader()
    return self.tbTeamdata and self.tbTeamdata[1]
end

function BattleTeamComponent:GetRecentUsedVehicleId(tbPlayer)
    local nPlayerInstanceId = tbPlayer:GetServerInstanceId()

    local tbData = FindPlayerDataByInstanceId(self, nPlayerInstanceId)
    if tbData then
        return tbData.nVehicleId
    end

    return 0
end

return BattleTeamComponent