local EnterLastDungeonHelper = {}

local EnterLastDungeonDataTable = require("EnterLastDungeonDataTable")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
local NetworkManager        = dynamic_require("NetworkManager")
local Proto                 = require("ClientProtoNames")
local ProcedureTool         = require("ProcedureTool")
local UISetUtils            = require("UISetUtils")
local SaveGameDef           = require("SaveGameDef")
local GlobalVariableSystem_C= require("GlobalVariableSystem_C")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")

function EnterLastDungeonHelper:GetTitle(nDungeonId)
    return UISetUtils.GetL10NTextByKey(EnterLastDungeonDataTable:GetTitle(nDungeonId))
end

function EnterLastDungeonHelper:GetMessage(nDungeonId)
    return UISetUtils.GetL10NTextByKey(EnterLastDungeonDataTable:GetMessage(nDungeonId))
end

function EnterLastDungeonHelper:IsForceDialog(nDungeonId)
    return EnterLastDungeonDataTable:IsForceDialog(nDungeonId)
end

function EnterLastDungeonHelper:ShouldGotoLastDungeon(tbPacket)
    local bIsInDungeon   = tbPacket.data.dungeon.is_in_dungeon
    local nDungeonId     = tbPacket.data.dungeon.dungeon_template_id
    local bResultArrived = tbPacket.data.dungeon.result_arrived
    local nResultRank    = tbPacket.data.dungeon.result_rank

    local bClientInDungeon = GlobalVariableSystem:IsInDungeon()
    if bClientInDungeon then
        local nSessionId = GlobalVariableSystem:GetDungeonSessionId()
        if tbPacket.data.dungeon.game_session_id ~= nSessionId then
            log("[ReconnectSystem]EnterLastDungeonHelper:ShouldGotoLastDungeon session is dif ", nSessionId)
            bClientInDungeon = false
            GlobalVariableSystem:SetDungeonSessionId(tbPacket.data.dungeon.game_session_id)
        end
    end 
    local bForceEnterDungeon = false

    if bIsInDungeon and not bClientInDungeon and not self:IsForceDialog(nDungeonId) then
        if bResultArrived then
            if nResultRank == 1 then --个人排名第1名说明玩家肯定活着，强拉进去
               bForceEnterDungeon = true
            end
        else
            bForceEnterDungeon = true
        end
    end

    return bForceEnterDungeon
end

function EnterLastDungeonHelper:ShouldShowDialog(tbPacket)
    local bShow = false

    local bIsInDungeon   = tbPacket.data.dungeon.is_in_dungeon
    local bResultArrived = tbPacket.data.dungeon.result_arrived
    local nResultRank    = tbPacket.data.dungeon.result_rank
    local nDungeonId     = tbPacket.data.dungeon.dungeon_template_id

    local tbPlayerSelf     = GamePlayerSelfHelper:Get() 
    local bClientInDungeon = GlobalVariableSystem:IsInDungeon() and tbPlayerSelf and tbPlayerSelf.bReady

    if bIsInDungeon and not bClientInDungeon then
        if self:IsForceDialog(nDungeonId) then
            bShow = true
        else
            if bResultArrived then
                if nResultRank ~= 1 then
                    bShow = true
                end
            end
        end
    end

    return bShow
end

function EnterLastDungeonHelper:EnterLastDungeon(nDungeonId)
    local nTime = ClientShell.GetClient(GWorld):GetSaveGameManager():GetIntData(SaveGameDef.DUNGEON_START_TIME)
    if nTime > 0 then
        GlobalVariableSystem_C:SetEnterDungeonTime(nTime)
    end

    local tbParam = {}
    tbParam.nDungeonId = nDungeonId
    tbParam.bStandalone = false
    if not ProcedureTool:EnterDungeon(tbParam) then
        log("OnEnterLastDungeon failed is disconnected")
        return
    end
    
    local c2s_EnterLastDungeon =
    {
        answer = Proto.c2s_EnterLastDungeon_Answer.YES
    }
    local Socket = NetworkManager:GetHubServerProxy()
    return Socket:SendPacket(Proto.c2s_EnterLastDungeon, c2s_EnterLastDungeon)
end


function EnterLastDungeonHelper:RefuseEnterLastDungeon()

    local c2s_EnterLastDungeon =
    {
        answer = Proto.c2s_EnterLastDungeon_Answer.NO
    }
    local Socket = NetworkManager:GetHubServerProxy()
    return Socket:SendPacket(Proto.c2s_EnterLastDungeon, c2s_EnterLastDungeon)
end

function EnterLastDungeonHelper:AlreadyInDungeon()
    log("OnAlreadyInDungeon")
    local c2s_EnterLastDungeon =
    {
        answer = Proto.c2s_EnterLastDungeon_Answer.ALREADY_IN_DUNGEON
    }
    local Socket = NetworkManager:GetHubServerProxy()
    return Socket:SendPacket(Proto.c2s_EnterLastDungeon, c2s_EnterLastDungeon)
end

function EnterLastDungeonHelper:GetLastDungeonId(tbPacket)
    return tbPacket.data.dungeon.dungeon_template_id
end

function EnterLastDungeonHelper:IsInLastDungeon(tbPacket)
    return tbPacket.data.dungeon.is_in_dungeon
end

return EnterLastDungeonHelper