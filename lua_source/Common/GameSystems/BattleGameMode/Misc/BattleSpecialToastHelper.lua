local BattleSpecialToastHelper = {}

BattleSpecialToastHelper.rObjective = nil

function BattleSpecialToastHelper:Init(rObjective)
    self.rObjective = rObjective
end

function BattleSpecialToastHelper:Uninit()
    self.rObjective = nil
end

function BattleSpecialToastHelper.FillToastInfo(
    tbPacket,
    nServerInstanceId,
    nId,
    szParam0, szParam1, szParam2,
    nToastType,
    nCampType,
    nWaitTime)

    assert(tbPacket)

    local tbInfo = tbPacket.tbInfo
    if(tbInfo == nil) then
        tbInfo = {}
        tbPacket.tbInfo = tbInfo
    end

    tbInfo.nToastType = nToastType
    tbInfo.nToastId = nId
    tbInfo.szParam0 = szParam0
    tbInfo.szParam1 = szParam1
    tbInfo.szParam2 = szParam2
    tbInfo.nWaitTime = nWaitTime
    tbInfo.nServerInstanceId = nServerInstanceId
    tbInfo.nCampType = nCampType
end

function BattleSpecialToastHelper:ShowSpecialToast(
    nServerInstanceId,
    nId, szParam0, szParam1, szParam2,
    nToastType, nCampType, nWaitTime)

    local rObjective = self.rObjective
    if(rObjective == nil) then
        return
    end

    BattleSpecialToastHelper.FillToastInfo(rObjective,
        nServerInstanceId,
        nId, szParam0, szParam1, szParam2,
        nToastType, nCampType, nWaitTime)
    rObjective.RepNow()
end



return BattleSpecialToastHelper