local luaclass = require ("luaclass")
local CppDelegateProcesserBaseClass = require ("CPPDelegateProcessorBase")
local DungeonCppDelegateProcessor = luaclass("DungeonCppDelegateProcessor", CppDelegateProcesserBaseClass)
local BattlePrepareSystem = require("BattlePrepareSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")

local function OnClientReconnect(szAddress, nPlayerId, nToken)
    log("Net reconnect request. szAddress:", szAddress, ". nPlayerId:", nPlayerId, ". nToken:", nToken)
    local tbPrepareInfo = BattlePrepareSystem:GetPlayerPrepareInfo(nPlayerId)
    if not tbPrepareInfo then
        log("OnClientReconnect failed. Player not found. PlayerId:", nPlayerId)
        return
    end

    if tbPrepareInfo.nToken ~= nToken then
        log("OnClientReconnect failed. Token mismatch. PlayerId:", nPlayerId, ".", tbPrepareInfo.nToken, "~=", nToken)
        return
    end

    local GamePlayer = GameObjectSystem:FindPlayerByPlayerId(nPlayerId)
    if not GamePlayer then
        log("OnClientReconnect failed. GamePlayer nil. PlayerId:", nPlayerId)
        return
    end

    local pUEController = GamePlayer.pUEController
    if not pUEController then
        log("OnClientReconnect failed. GamePlayer.pUEController nil. PlayerId:", nPlayerId)
        return
    end

    if ServerShell.GetServer(GWorld):GetDungeonShell():SetClientConnectionAddress(pUEController, szAddress) then
        log("OnClientReconnect set client reconnect info succeed.")
    else
        logerror("OnClientReconnect failed.")
    end
end

function DungeonCppDelegateProcessor:Init()
    DungeonCppDelegateProcessor.super.Init(self)
    -- Register Gameplay Delegate
    local DelegateMgr = CommonShell.GetCommon(GWorld):GetGameDelegateManager()

    -- TODO: regist delegate processor to receive package
    local NetDelegateMgr = DelegateMgr.GameNet
    self:Register(NetDelegateMgr.OnClientReconnect, OnClientReconnect)

    return true
end

return DungeonCppDelegateProcessor