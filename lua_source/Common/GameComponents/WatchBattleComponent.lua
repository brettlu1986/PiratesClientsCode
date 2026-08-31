local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local WatchBattleComponent = luaclass("WatchBattleComponent", GameComponentBase)

local TeamWatchServerHelper = require("TeamWatchServerHelper")
local SelfEventHelper = require("SelfEventHelper")
local CommonEventDef = require("CommonEventDef")
local PropName = require("PropName")

WatchBattleComponent.tbViewers = nil --谁在观战自己
WatchBattleComponent.nCurrentViewId = -1 --当前自己在观战谁

--协议的Handle
WatchBattleComponent.rBattleTeamBaseInfo   = nil
WatchBattleComponent.rBattleTeamHealthInfo = nil
WatchBattleComponent.rBattleTeamStateInfo  = nil
WatchBattleComponent.rBattleTeamPosInfo    = nil
WatchBattleComponent.rBattleTeamSignInfo   = nil
WatchBattleComponent.rTeamPlayersInfo      = nil
WatchBattleComponent.EventHelper           = nil

WatchBattleComponent.tbAllData   = nil --Team完整数据

WatchBattleComponent.bProtoValid = false

local function OnBattleInfoChanged(self, tbPlayer, nTeamId, eType)
    if self.tbAllData and self.tbAllData.nTeamId == nTeamId then  
        self:OnDataChanged(eType)
    end
end

function WatchBattleComponent:OnCreate(Owner, tbParams)
    WatchBattleComponent.super.OnCreate(self, Owner, tbParams)
    self.tbViewers = {}
    return true
end

function WatchBattleComponent:OnActorCreated(pUEActor)
    WatchBattleComponent.super.OnActorCreated(self, pUEActor)
    self.EventHelper = SelfEventHelper()
    self.bProtoValid = true

    local rComponent = self.Owner.CustomReplicationComponent

    self.rBattleTeamBaseInfo = rComponent:BindMethod(PropName.rBattleWatchTeamBaseInfo,
        nil, self, self.OnBattleTeamBaseInfoChanged, false)

    self.rBattleTeamHealthInfo = rComponent:BindMethod(PropName.rBattleWatchTeamHealthInfo,
        nil, self, self.OnBattleTeamHealthInfoChanged, false)

    self.rBattleTeamStateInfo = rComponent:BindMethod(PropName.rBattleWatchTeamStateInfo,
        nil, self, self.OnBattleTeamStateInfoChanged, false)

    self.rBattleTeamPosInfo = rComponent:BindMethod(PropName.rBattleWatchTeamPosInfo,
        nil, self, self.OnBattleTeamPosInfoChanged, false)

    self.rBattleTeamSignInfo = rComponent:BindMethod(PropName.rBattleWatchTeamSignInfo,
        nil, self, self.OnBattleTeamSignInfoChanged, false)

    self.rTeamPlayersInfo = rComponent:BindMethod(PropName.rWatchTeamPlayersInfo,
        nil, self, self.OnTeamPlayersInfoChanged, false)

    self.EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_TEAMINFO_CHANGED, self, OnBattleInfoChanged)
end

function WatchBattleComponent:OnActorDestroyed(pUEActor)
    self.bProtoValid = false
    self.tbAllData = nil
    if self.EventHelper then
        self.EventHelper:UnregisterAll()
    end
    WatchBattleComponent.super.OnActorDestroyed(self, pUEActor)
end

function WatchBattleComponent:OnBattleTeamBaseInfoChanged(_Property, tbBattleTeamBaseInfo)
end

function WatchBattleComponent:OnBattleTeamHealthInfoChanged(_Property, tbBattleTeamHealthInfo)
end

function WatchBattleComponent:OnBattleTeamStateInfoChanged(_Property, tbBattleTeamStateInfo)
end

function WatchBattleComponent:OnBattleTeamPosInfoChanged(_Property, tbBattleTeamPosInfo)
end

function WatchBattleComponent:OnBattleTeamSignInfoChanged(_Property, tbBattleTeamSignInfo)
end

function WatchBattleComponent:OnTeamPlayersInfoChanged(_Property, tbTeamPlayersInfo)
end

function WatchBattleComponent:SetWatchTeamData(tbTeam)
    self.tbAllData  = tbTeam
end

--通过数据发送了变化
function WatchBattleComponent:OnDataChanged(eType)
    if not self.tbAllData or not self.tbAllData.tbTeamData then
        -- logerror("tbAllData is nil,check SetWatchTeamData func.")
        log("[server watch] tbAllData is nil,check SetWatchTeamData func.")
        return
    end

    if not self.bProtoValid then
        log("[server watch] proto not valid return")
        return
    end

    TeamWatchServerHelper.RepBattleTeamData(eType, self.tbAllData, 
    self.rBattleTeamBaseInfo, self.rBattleTeamHealthInfo, self.rBattleTeamStateInfo, self.rBattleTeamPosInfo,
    self.rBattleTeamSignInfo, self.rTeamPlayersInfo)
end

function WatchBattleComponent:Reset()
    if not self.bProtoValid then
        log("[server watch] proto not valid return")
        return
    end

    self.rBattleTeamBaseInfo:Set(nil)
    self.rBattleTeamHealthInfo:Set(nil)
    self.rBattleTeamStateInfo:Set(nil)
    self.rBattleTeamPosInfo:Set(nil)
    self.rBattleTeamSignInfo:Set(nil)
    self.rTeamPlayersInfo:Set(nil)
end

function WatchBattleComponent:OnDestroy()
    self.tbViewers = nil
    WatchBattleComponent.super.OnDestroy(self)
end

local function GetViewerIndex(self, nViewerInsId)
    local tbViewers = self.tbViewers
    local nCount = #tbViewers
    for i = 1, nCount do
        if(tbViewers[i] == nViewerInsId) then
            return i
        end
    end
    return -1
end

function WatchBattleComponent:HasViewers()
    return self.tbViewers and #self.tbViewers > 0 
end

function WatchBattleComponent:AddViewerId(nViewerInsId)
    local nViewIndex = GetViewerIndex(self, nViewerInsId)
    if nViewIndex > 0 then
        return 
    end
    table.insert(self.tbViewers, nViewerInsId)
end

function WatchBattleComponent:RemoveViewerId(nViewerInsId)
    local nViewIndex = GetViewerIndex(self, nViewerInsId)
    if nViewIndex < 0 then  
        return 
    end
    table.remove(self.tbViewers, nViewIndex)
end

function WatchBattleComponent:GetViewers()
    return self.tbViewers
end



return WatchBattleComponent