-----------------------------------------------------
--File Name    : ULBattleTeam.lua
--Description  : 战斗组队列表
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULBattleTeam = luaclass("ULBattleTeam", UILogicBase)

local ClientEventDef = require("ClientEventDef")
local ControlModeSystem = require("ControlModeSystem")
local ControlModeDef = require("ControlModeDef")
local TeamWatchClientHelper = require("TeamWatchClientHelper")


ULBattleTeam.OneSecondTimer = nil
ULBattleTeam.nEndTime = nil
ULBattleTeam.nState = nil
ULBattleTeam.nInstanceId = nil
ULBattleTeam.bInWaitTime = false
ULBattleTeam.pbAim = nil
ULBattleTeam.bShowTeamInfoEnable = true

local MAX_TEAM_MEMBER_COUNT = 4

local function SetTeamInfoEnable(self, bEnable)
    self.bShowTeamInfoEnable = bEnable
end

local function RefreshAllTeamMember(self)
    if not self.bShowTeamInfoEnable then
        return
    end
    
    self.pWidgetRef.vboxTeammate:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    
    local tbTeamMemberPrefabList = self.tbTeamMemberPrefabList

    --先设置上基础信息，人名，性别等信息，即使这个人没还有创建出来
    local tbBaseInfos = TeamWatchClientHelper.GetCurrentTeamBaseInfo()
    if tbBaseInfos then
        local nBaseCount = #tbBaseInfos
        for i = 1, nBaseCount do
            local tbTeamMemberPrefab = tbTeamMemberPrefabList[i]
            if tbTeamMemberPrefab then
                tbTeamMemberPrefab:InitData(tbBaseInfos[i], tbBaseInfos[i].nIndex)
            end
        end

        local nPrefabCount = #tbTeamMemberPrefabList
        for i = nBaseCount + 1, nPrefabCount do
            tbTeamMemberPrefabList[i]:HideData()
        end
    end

    local tbTeamInfo = TeamWatchClientHelper.GetCurrentTeamInfo()
    if not tbTeamInfo then
        return
    end

    local nCount = #tbTeamInfo
    for i = 1, nCount do
        local nIndex = tbTeamInfo[i].nIndex
        local tbTeamMemberPrefab = tbTeamMemberPrefabList[nIndex]
        if tbTeamMemberPrefab then
            tbTeamMemberPrefab:SetData(tbTeamInfo[i])
        end
    end
end

local function OnTeamModeInfo(self, tbPacket)
    local nTeamModeId = tbPacket.nTeamModeId
    if nTeamModeId == 1 then
        self.EventHelper:UnregisterAll()
        self.pWidgetRef.vboxTeammate:SetVisibility(ESlateVisibility_Collapsed)
        self.bShowTeamInfoEnable = false
    end
end

function ULBattleTeam:OnLoad()
    self.tbTeamMemberPrefabList = {}
    local PrefabHelper = self.PrefabHelper
    local pWidgetRef = self.pWidgetRef
    self.bShowTeamInfoEnable = true
    for i = 1, MAX_TEAM_MEMBER_COUNT do
        local tbTeamMemberPrefab = PrefabHelper:BindPrefab(pWidgetRef["pbTeammateInfo0"..i])
        table.insert(self.tbTeamMemberPrefabList, tbTeamMemberPrefab)
    end
end

function ULBattleTeam:OnShow()
    RefreshAllTeamMember(self)
    
    local nCount = TeamWatchClientHelper.GetTeamCount()
    OnTeamModeInfo(self, { nTeamModeId = nCount })
end

function ULBattleTeam:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_CHANGED, self, RefreshAllTeamMember)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_ENABLE, self, SetTeamInfoEnable)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_MODE_INFO, self, OnTeamModeInfo)
end

function ULBattleTeam:OnDestroy()
end

function ULBattleTeam:Activate()
    local CurrentMode = ControlModeSystem:GetCurrentModeType()
    if CurrentMode == ControlModeDef.TRANSPORTNEW then
        RefreshAllTeamMember(self)
    end
    for k, v in ipairs(self.tbTeamMemberPrefabList) do
        v:Activate()
    end
end

function ULBattleTeam:Deactivate()
    for k, v in ipairs(self.tbTeamMemberPrefabList) do
        v:Deactivate()
    end
end


return ULBattleTeam