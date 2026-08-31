--只存储队友信息，其他人的信息不保存
local BattleTeammateSystem = {}

--存储队友(包括自己)的信息
BattleTeammateSystem.nTeamId = 0
BattleTeammateSystem.tbInstanceIds = nil
BattleTeammateSystem.nTeamModeId = nil

local function GetBPTeamSystem()
    return GameplayStatics.GetGameState(GWorld).TeamSystem
end

function BattleTeammateSystem:Init()
    self.nTeamId = 0
    self.tbInstanceIds = {}
    return true
end

function BattleTeammateSystem:Uninit()
    self.nTeamId = 0
    self.tbInstanceIds = nil
    self.nTeamModeId   = nil
end

function BattleTeammateSystem:SetPacket(tbPacket)
    local nOldTeamId = self.nTeamId
    local nNewTeamId = tbPacket.nTeamId

    if nOldTeamId ~= nNewTeamId then
        -- for _, curId in pairs(self.tbInstanceIds) do
        --     GetBPTeamSystem():RemoveMemberFromTeam(curId, nOldTeamId)
        -- end
        self.tbInstanceIds = {}
    end

    local tbAddPlayerIds = {}
    local tbRemovePlayerIds = {}

    for _, curId in pairs(tbPacket.tbInstanceIds) do
        local bFound = false

        for __, tempCurId in pairs(self.tbInstanceIds) do
            if curId == tempCurId then
                bFound = true
                break
            end
        end

        if not bFound then
            table.insert(tbAddPlayerIds, curId)
        end
    end

    for _, curId in pairs(self.tbInstanceIds) do
        local bFound = false

        for __, tempCurId in pairs(tbPacket.tbInstanceIds) do
            if curId == tempCurId then
                bFound = true
                break
            end
        end

        if not bFound then
            table.insert(tbRemovePlayerIds, curId)
        end
    end

    -- for _, curId in pairs(tbAddPlayerIds) do
    --     GetBPTeamSystem():AddMemberToTeam(curId, nNewTeamId)
    -- end

    -- for _, curId in pairs(tbRemovePlayerIds) do
    --     GetBPTeamSystem():RemoveMemberFromTeam(curId, nNewTeamId)
    -- end
   
    self.nTeamId = tbPacket.nTeamId
    self.tbInstanceIds = tbPacket.tbInstanceIds
end

function BattleTeammateSystem:CheckTeammateWithSelf(nPlayerInstanceId)
    local bRet = false

    for _, curId in pairs(self.tbInstanceIds) do
        if curId == nPlayerInstanceId then
            bRet = true
            break
        end
    end

    return bRet
end

function BattleTeammateSystem:SetTeamMode(nTeamModeId)
    self.nTeamModeId = nTeamModeId
end

function BattleTeammateSystem:GetTeamMode()
    return self.nTeamModeId
end

function BattleTeammateSystem:SyncBPTeamSystemOnClient(tbTeamPlayersInfo)
    local nTeamId = tbTeamPlayersInfo.nTeamId
    for _, nInstanceId in pairs(tbTeamPlayersInfo.tbInstanceIds) do
        GetBPTeamSystem():AddMemberToTeam(nInstanceId, nTeamId)
    end
end

return BattleTeammateSystem