-----------------------------------------------------
--File Name    : ULBotBattleTeam.lua
--Description  : 战斗组队列表
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULBotBattleTeam = luaclass("ULBotBattleTeam", UILogicBase)

ULBotBattleTeam.bShowTeamInfoEnable = true

local MAX_TEAM_MEMBER_COUNT = 4

function ULBotBattleTeam:RefreshAllTeamMember(tbBattleTeamInfo)
    if not self.bShowTeamInfoEnable or not self.Owner.tbCurrrentWatchObj then
        return
    end

    if not tbBattleTeamInfo then
        return
    end

    self.pWidgetRef.vboxTeammate:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    local tbTeamMemberPrefabList = self.tbTeamMemberPrefabList
    local nCount = #tbBattleTeamInfo
    for i = 1, nCount do
        local tbTeamMemberPrefab = tbTeamMemberPrefabList[i]
        if tbTeamMemberPrefab then
            tbTeamMemberPrefab:InitData(tbBattleTeamInfo[i], tbBattleTeamInfo[i].nIndex)
            tbTeamMemberPrefab:SetData(tbBattleTeamInfo[i])
        end
    end
    
    for i = nCount + 1, #tbTeamMemberPrefabList do
        tbTeamMemberPrefabList[i]:HideData()
    end
end

function ULBotBattleTeam:OnLoad()
    self.tbTeamMemberPrefabList = {}
    local PrefabHelper = self.PrefabHelper
    local pWidgetRef = self.pWidgetRef
    self.bShowTeamInfoEnable = true
    for i = 1, MAX_TEAM_MEMBER_COUNT do
        local tbTeamMemberPrefab = PrefabHelper:BindPrefab(pWidgetRef["pbTeammateInfo0"..i])
        table.insert(self.tbTeamMemberPrefabList, tbTeamMemberPrefab)
    end
end

return ULBotBattleTeam