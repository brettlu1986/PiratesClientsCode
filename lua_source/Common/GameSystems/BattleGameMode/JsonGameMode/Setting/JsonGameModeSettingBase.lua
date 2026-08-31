local luaclass = require("luaclass")
local JsonGameModeSettingBase = luaclass("JsonGameModeSettingBase")
local DungeonQuitDialogType = require("DungeonQuitDialogType")

JsonGameModeSettingBase.tbGameMode = nil
JsonGameModeSettingBase.tbGameState = nil

function JsonGameModeSettingBase:Init(tbGameMode)
    self.tbGameMode = tbGameMode
    self.tbGameState = tbGameMode:GetGameState()
    return true
end

function JsonGameModeSettingBase:Parse(tbJsonData)
    local nSubId = tbJsonData.SubId
    if(nSubId ~= self.tbGameMode.nSubDungonId) then
        error("GameMode subId is not equal to tabfile, bp subid:"..nSubId..", table subid: "..self.tbGameMode.nSubDungonId)
        return false
    end
    return true
end

function JsonGameModeSettingBase:Uninit()
end

function JsonGameModeSettingBase:StartFirstStep()
end

function JsonGameModeSettingBase:OnPlayerLogin(tbPlayer)
end

function JsonGameModeSettingBase:OnPlayerReLogin(tbPlayer)
end

function JsonGameModeSettingBase:OnPlayerLogout(tbPlayer)
end

function JsonGameModeSettingBase:QuitDungeon(tbPlayer,nQuitReason)
end

function JsonGameModeSettingBase:NotifyPlayerLeave(tbPlayer)
end

function JsonGameModeSettingBase:OnPlayerDead(tbDeadObject)
end

function JsonGameModeSettingBase:OnKickPlayer(tbPlayer)
end

function JsonGameModeSettingBase:OnFindRebornPoint(tbPlayer)
    return self:OnFindPlayerStart(tbPlayer).Transform
end

function JsonGameModeSettingBase:CreateTeam(tbGamePlayer, nGroupIndex)
end


function JsonGameModeSettingBase:OnSpawnPlayerPawn(tbGamePlayer, bPossess)
    return true
end

function JsonGameModeSettingBase:OnFindPlayerStart(tbPlayer)
    local tbJsonStarts = self.tbGameMode.tbJsonTableFile.tbContainer.DungeonPlayerStarts
    local nJsonCount = #tbJsonStarts

    if nJsonCount == 0 then
        error('JsonGameModeSettingBase:OnFindPlayerStart failed, has no player start.')
    end
    
    return tbJsonStarts[1]
end

function JsonGameModeSettingBase:OnSnapshotGameState()
end

function JsonGameModeSettingBase:OnAllStepFinished()
end

function JsonGameModeSettingBase:SetPlayerSelfInfo(tbPrepareInfo)
end

function JsonGameModeSettingBase:OnPostResetAllSteps()
end

function JsonGameModeSettingBase:CanResetAllSteps()
    return false
end

function JsonGameModeSettingBase:OnStepComplete(Step)
end

function JsonGameModeSettingBase:OnStartStep(Step)
end

function JsonGameModeSettingBase:TryResetAllSteps(nSenderUniqueId)
end

function JsonGameModeSettingBase:GetQuitDungeonDialogType()
    return DungeonQuitDialogType.JsonPVE
end

function JsonGameModeSettingBase:OnApproveLogin(szOptions)
    return ""
end

function JsonGameModeSettingBase:OnForceReleaseDungeon()
end

return JsonGameModeSettingBase

