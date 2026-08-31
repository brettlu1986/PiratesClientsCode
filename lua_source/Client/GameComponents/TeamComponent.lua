-----------------------------------------------------
--File Name    : TeamComponent.lua
--Author       : Ranjie
--Create Time  : 2019-03-08
--Description  : 副本外组队的component
-----------------------------------------------------
local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local TeamComponent = luaclass("TeamComponent", GameComponentBase)

TeamComponent.tbSortedTeamMembersList = nil
TeamComponent.tbTeamMembersMap = nil
TeamComponent.nTeamId = nil
TeamComponent.nLeaderId = nil

-----------------------------------------local function---------------------------------------------
local function SortFunc(self, nPlayerId1, nPlayerId2)
    local tbData1 = self.tbTeamMembersMap[nPlayerId1]
    local tbData2 = self.tbTeamMembersMap[nPlayerId2]
    if not tbData1 or not tbData2 then
        return false
    end
    if tbData1.nJoinTime < tbData2.nJoinTime then
        return true
    else
        return false
    end
end


-----------------------------------------初始化---------------------------------------------

function TeamComponent:OnCreate(Owner, tbParams)
    self.tbSortedTeamMembersList = {}
    self.tbTeamMembersMap = {}
    return true
end

-----------------------------------外部接口-------------------------------------
function TeamComponent:UpdateTeamInfo(nTeamId, nLeaderId)
    self.nTeamId = nTeamId
    self.nLeaderId = nLeaderId
end

function TeamComponent:UpdateTeamLeader(nLeaderId)
    self.nLeaderId = nLeaderId
end

function TeamComponent:ClearTeamMembers()
    self.tbSortedTeamMembersList = {}
    self.tbTeamMembersMap = {}
    self.nTeamId = nil
    self.nLeaderId = nil
end

function TeamComponent:RemoveTeamMembers(nPlayerId)
    self.tbTeamMembersMap[nPlayerId] = nil
    local nRemoveIndex = nil
    for k, v in ipairs(self.tbSortedTeamMembersList) do
        if nPlayerId == v then
            nRemoveIndex = k
            break
        end
    end
    if nRemoveIndex then
        table.remove(self.tbSortedTeamMembersList, nRemoveIndex)
    end
end

function TeamComponent:UpdateTeamMember(tbServerMemberData)
    local nPlayerId = tbServerMemberData.player_id
    local tbTeamMemberData = self.tbTeamMembersMap[nPlayerId]
    if not tbTeamMemberData then
        tbTeamMemberData = {}
        tbTeamMemberData.nPlayerId = nPlayerId
        tbTeamMemberData.nJoinTime = tbServerMemberData.join_time
        self.tbTeamMembersMap[nPlayerId] = tbTeamMemberData
        table.insert(self.tbSortedTeamMembersList, nPlayerId)
        table.sort(self.tbSortedTeamMembersList, function(nPlayerId1, nPlayerId2) SortFunc(self, nPlayerId1, nPlayerId2) end)
    end
    tbTeamMemberData.bIsReady = tbServerMemberData.is_ready
    self.tbTeamMembersMap[nPlayerId] = tbTeamMemberData
end

function TeamComponent:UpdateTeamMemberSummary(tbSummary)
    local tbTeamMemberData = self.tbTeamMembersMap[tbSummary.id]
    if tbTeamMemberData then
        tbTeamMemberData.tbSummary = tbSummary
    end
end

function TeamComponent:UpdateTeamMemberFashion(nPlayerId, tbFashionIds)
    local tbTeamMemberData = self.tbTeamMembersMap[nPlayerId]
    if tbTeamMemberData then
        tbTeamMemberData.tbFashionIds = tbFashionIds
    end
end

function TeamComponent:UpdateTeamMemberReady(nPlayerId, bIsReady)
    local tbTeamMemberData = self.tbTeamMembersMap[nPlayerId]
    if tbTeamMemberData then
        tbTeamMemberData.bIsReady = bIsReady
    end
end

function TeamComponent:GetTeamMemberIds()
    return self.tbSortedTeamMembersList
end

function TeamComponent:GetTeamMemberData(nPlayerId)
    return self.tbTeamMembersMap[nPlayerId]
end

function TeamComponent:IsTeamLeader(nPlayerId)
    return self.nLeaderId == nPlayerId
end

function TeamComponent:GetTeamLeader()
    return self.nLeaderId
end

return TeamComponent
