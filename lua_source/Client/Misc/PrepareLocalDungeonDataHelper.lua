-- Purpose: Provide identical method to get property in Wildworld and BattleWorld
local PrepareLocalDungeonDataHelper = {}

local L10N                  = require("L10N")
local BattlePrepareSystem   = require("BattlePrepareSystem")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
local DungeonDataTable      = require("DungeonDataTable")
local CameraGameHelper      = require("CameraGameHelper")
local TutorialDungeonIni    = require("TutorialDungeonIni")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")

function PrepareLocalDungeonDataHelper:PrepareLocalDungeonData(tbParam)
    local nPlayerId = tbParam.nPlayerId
    local tbInfo = BattlePrepareSystem:GetPlayerPrepareInfo(nPlayerId)
    if(tbInfo) then
        return
    end
    
    local PlayerSelf = GamePlayerSelfHelper.Get()
    tbInfo = BattlePrepareSystem:CreatePlayerInfo(
        nPlayerId,
        PlayerSelf.szName,
        PlayerSelf.nHumanTemplateId)
        
    local tbDungeonData = DungeonDataTable:GetTemplate(tbParam.nDungeonId)
    tbInfo:SetInitItemsByGroupId(tbDungeonData.nInitItem)
end
    
function PrepareLocalDungeonDataHelper:PrepareTutorialDungeonData()
    GlobalVariableSystem:SetWithLobby(false)
    CameraGameHelper.SetGyroEnable(false)
    local nFakePlayerId = 100000
    local tbInfo = BattlePrepareSystem:CreatePlayerInfo(nFakePlayerId,
        L10N:ToString(TutorialDungeonIni.l10nDisplayName), TutorialDungeonIni.nHumanId)
    tbInfo:AddShipPreparation(TutorialDungeonIni.tbPreparation)
    tbInfo:FillAvatarByHumanId(tbInfo.nHumanId)
    return tbInfo
end

return PrepareLocalDungeonDataHelper
