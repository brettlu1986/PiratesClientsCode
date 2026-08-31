local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local GameObjectSystem_C = require("GameObjectSystem_C")
local CommonEventDef = require("CommonEventDef")
local ProtoRep = require("DungeonRepProtoNames")
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
local UIUtils = require("UIUtils")
local L10N = require("L10N")
local UISetUtils = require("UISetUtils")
local UIManager = require("UIManager")
local UIStateDef = require("UIStateDef")

local PoisonCircleSystem = {}
PoisonCircleSystem.tbPoisonCircleInfo = nil
local TOAST_SHOW_TIME = 3
local ZERO_VECTOR = Vector{X = 0, Y = 0, Z = 0}

PoisonCircleSystem.tbInfo = nil
PoisonCircleSystem.tbMapOp = {}
PoisonCircleSystem.pCurVector = nil
PoisonCircleSystem.nCurRadius = 0
PoisonCircleSystem.pDestVector = nil
PoisonCircleSystem.nDestRadius = 0

local function OnPoisonCircleUpdate(self, tbPacket)
    --进入结算状态 不走毒圈逻辑
    local ActiveUIState = UIManager:GetActiveState()
    if ActiveUIState ~= nil and ActiveUIState.szName == UIStateDef.StateName.UI_FFA_RESULT_STATE then
        return
    end
    self.tbPoisonCircleInfo = tbPacket
    local PoisonCircleTrigger = GameObjectSystem_C:FindByInstanceId(tbPacket.nInstanceId)
    if PoisonCircleTrigger == nil then
        return
    end

    local nState = tbPacket.nStageId
    local tbState = ProtoRep.rFFAPoisonCircleInfo_EStageState
    local nCurrentDSTime = GlobalVariableSystem_C:GetServerTimeUtc()
    log(string.format("Poisoncircle update waitTimeStamp=%f, shrinkTimeStamp=%f, curStamp=%f", tbPacket.nWaitEndTimeStamp, tbPacket.nShrinkEndTimeStamp, nCurrentDSTime))
    local pUEActor = PoisonCircleTrigger.pUEActor
    local pDestVector = Vector2D{X = tbPacket.nNextX, Y = tbPacket.nNextY}
    local pCurVector = Vector2D{X = tbPacket.nCurrentX, Y = tbPacket.nCurrentY}
    local nCurrentRadius = tbPacket.nCurrentRadius

    if nState == tbState.SHRINK then
        local nTime = tbPacket.nCurrentShrinkTime
        local nOverTime = nTime - math.floor(tbPacket.nShrinkEndTimeStamp - nCurrentDSTime)
        if nOverTime > 0 then 
            local nSpeedX = (tbPacket.nNextX - tbPacket.nCurrentX) / nTime
            local nSpeedY = (tbPacket.nNextY - tbPacket.nCurrentY) / nTime
            pCurVector.X = tbPacket.nCurrentX + nSpeedX * nOverTime
            pCurVector.Y = tbPacket.nCurrentY + nSpeedY * nOverTime
            local nSpeedRadius = (tbPacket.nCurrentRadius - tbPacket.nNextRadius) / nTime
            nCurrentRadius = tbPacket.nCurrentRadius - nSpeedRadius * nOverTime
            log(string.format("Poisoncircle shrink update packet(curx=%f, cury=%f, curradius=%d)", tbPacket.nCurrentX, tbPacket.nCurrentY, tbPacket.nCurrentRadius))
            log(string.format("Poisoncircle shrink update adjust curx=%f, cury=%f, curradius=%f)", pCurVector.X, pCurVector.Y, nCurrentRadius))
        elseif nOverTime < 0 then
            log(string.format("Poisoncircle over time is invalid. nCurrentShrinkTime=%d, nShrinkTimeStamp=%f, nCurrentTimeStamp=%f", nTime, tbPacket.nShrinkEndTimeStamp, nCurrentDSTime))
        end
    end
    pUEActor:SyncInfo(pCurVector, nCurrentRadius)
  
    if #self.tbMapOp > 0 then
        for k, v in pairs(self.tbMapOp)do
            --logdebug("AddMapOp1")
            PoisonCircleTrigger.pUEActor.PoisonCircleMapComponent:AddMapOp(v)
        end
        self.tbMapOp = {}
    end
    if nState == tbState.WAIT then
        pUEActor:StopShrink()
        pUEActor:SetMapOpInfo(pCurVector, nCurrentRadius, pDestVector, tbPacket.nNextRadius)
        local nCurrentWaitTime = math.floor(tbPacket.nWaitEndTimeStamp - nCurrentDSTime)
        log("Poisoncircle wait", nCurrentWaitTime)
        if nCurrentWaitTime <= 0 then
            log("Poisoncircle state is WAIT, but wait time is <= 0.")
        else
            local nMinute = math.modf(nCurrentWaitTime / 60)
            local nSeconds = nCurrentWaitTime - nMinute * 60
            local szText
            if nMinute == 0 then
                szText = nSeconds..UISetUtils.GetTextByKey("COMMON_TIME_SECOND")
            elseif nSeconds == 0 then
                local l10nText = L10N:Format(UISetUtils.GetL10NTextByKey("SELFTIMECALCULATEHELPER_L10N_MIN"), nMinute)
                szText = L10N:ToString(l10nText)
            else
                szText = nMinute..UISetUtils.GetTextByKey("COMMON_TIME_MINUTE")
                szText = szText..nSeconds..UISetUtils.GetTextByKey("COMMON_TIME_SECOND")
            end
            UIUtils.ShowSpecialToast(0, L10N:Format(UISetUtils.GetL10NTextByKey("FFA_POISONCIRCLE_WAIT"), szText), TOAST_SHOW_TIME, false)
        end
    elseif nState == tbState.SHRINK then
        local nCurrentShrinkTime = math.floor(tbPacket.nShrinkEndTimeStamp - nCurrentDSTime)
        log("Poisoncircle shrink", nCurrentShrinkTime, tbPacket.nCurrentShrinkTime)
        if nCurrentShrinkTime <= 0 then
            log("Poisoncircle state is SHRINK, but shrink time is <= 0.")
            nCurrentShrinkTime = 0
        else
            PoisonCircleTrigger.pUEActor:StartShrink(pDestVector, tbPacket.nNextRadius, nCurrentShrinkTime)
            UIUtils.ShowSpecialToast(0, UISetUtils.GetL10NTextByKey("FFA_POISONCIRCLE_SHRINK"), TOAST_SHOW_TIME, false)
        end
    elseif nState == tbState.FINISH then
        pUEActor:StopShrink()
    end

    self.tbInfo = {nEndTime = math.floor(tbPacket.nWaitEndTimeStamp), nState = nState,
        nPoisonCircleId = tbPacket.nInstanceId}
    self.pCurVector = pCurVector
    self.nCurRadius = nCurrentRadius
    self.pDestVector = pDestVector
    self.nDestRadius = tbPacket.nNextRadius
    self.EventHelper:FireEvent(ClientEventDef.EV_FFA_POISONCIRCLE_TIMERUPDATE, self.tbInfo)
end

local function OnNewObjectCreate(self, tbGameObject)
    if self.tbPoisonCircleInfo ~= nil and self.tbPoisonCircleInfo.nInstanceId == tbGameObject.nServerInstanceId then
        OnPoisonCircleUpdate(self, self.tbPoisonCircleInfo)
    end
end

local function OnLoadMap(self)
    self.tbInfo = nil
end

local function OnEnterForeground(self)
    if self.tbPoisonCircleInfo == nil then
        return
    end
    OnPoisonCircleUpdate(self, self.tbPoisonCircleInfo)
end

function PoisonCircleSystem:Init()
    self.pCurVector = ZERO_VECTOR
    self.pDestVector = ZERO_VECTOR
	self.EventHelper = SelfEventHelper()
	self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_POISONCIRCLE_UPDATE, self, OnPoisonCircleUpdate)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, OnNewObjectCreate)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_POST_LOAD_MAP, self, OnLoadMap)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_APP_HAS_ENTERED_FOREGROUND, self, OnEnterForeground)

    return true
end

function PoisonCircleSystem:Uninit()
	self.EventHelper:UnregisterAll()
	self.EventHelper = nil
    self.tbPoisonCircleInfo = nil
    self.pDestVector = nil
    self.nDestRadius = 0
end

function PoisonCircleSystem:GetPoisonCircleInfo()
    return self.tbInfo
end

function PoisonCircleSystem:AddMapOp(pMapOpObj)
    if self.tbInfo then
        local PoisonCircleTrigger = GameObjectSystem_C:FindByInstanceId(self.tbInfo.nPoisonCircleId)
        if PoisonCircleTrigger and PoisonCircleTrigger.pUEActor then
            --logdebug("AddMapOp2")
            PoisonCircleTrigger.pUEActor.PoisonCircleMapComponent:AddMapOp(pMapOpObj)
            PoisonCircleTrigger.pUEActor:SetMapOpInfo(self.pCurVector, self.nCurRadius, self.pDestVector, self.nDestRadius)
            return
        end
    end
    table.insert(self.tbMapOp, pMapOpObj)
end

-- function PoisonCircleSystem:ClearMapOp()
--     if self.PoisonCircleTrigger and self.PoisonCircleTrigger.pUEActor then
--         self.PoisonCircleTrigger.pUEActor.PoisonCircleMapComponent:ClearMapOp()
--     else
--         self.tbMapOp = {}
--     end
-- end

function PoisonCircleSystem:RemoveMapOp(pMapOpObj)
    if self.tbInfo then
        local PoisonCircleTrigger = GameObjectSystem_C:FindByInstanceId(self.tbInfo.nPoisonCircleId)
        if PoisonCircleTrigger and PoisonCircleTrigger.pUEActor then
            --local nRemoveUniqueId = ExtendBlueprintFunctions.GetObjectUniqueID(pMapOpObj)
            --logdebug("PoisonCircleSystem:RemoveMapOp1,nRemoveUniqueId,count=", #self.tbMapOp,nRemoveUniqueId)
            PoisonCircleTrigger.pUEActor.PoisonCircleMapComponent:RemoveMapOp(pMapOpObj)

        end
    end
    local nRemoveUniqueId = ExtendBlueprintFunctions.GetObjectUniqueID(pMapOpObj)
    --logdebug("PoisonCircleSystem:RemoveMapOp2,nRemoveUniqueId,count=",nRemoveUniqueId, #self.tbMapOp)
    local nRemoveIndex = nil
    for k, v in pairs(self.tbMapOp)do
        if ExtendBlueprintFunctions.GetObjectUniqueID(v) == nRemoveUniqueId then
            nRemoveIndex = k
            break
        end
    end
    --logdebug("PoisonCircleSystem:RemoveMapOp,nRemoveIndex=",nRemoveIndex)
    if nRemoveIndex then
        table.remove(self.tbMapOp, nRemoveIndex)
    end

end

return PoisonCircleSystem