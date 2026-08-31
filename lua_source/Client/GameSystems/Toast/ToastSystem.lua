local ToastSystem = {}

local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local Proto = require("DungeonCommonProtoNames")
local L10N = require("L10N")
local UIUtils = require("UIUtils")
local ObjectiveDataTable = require("ObjectiveDataTable")
local UIManager = require("UIManager")
local LoadingSystem = require("LoadingSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

--因为当在loading的时候发送多个toast的时候 只会有显示最后一种 所以加了一个存储表
ToastSystem.tbToastList = nil

function ToastSystem:Init()
    self.tbToastList = {}
end

function ToastSystem:Uninit()
    if self.tbToastList ~= nil then
        for k, v in ipairs(self.tbToastList) do
            table.remove(self.tbToastList, k)
        end
        self.tbToastList = nil
    end

    self:UnbindToastEvent()
end

function ToastSystem:BindToastEvent()
    local fnFunc = self.fnToastCallback
    if(fnFunc) then
        EventManager:BindEvent(ClientEventDef.EV_EXIT_CINEMATIC_MODE, fnFunc)
        EventManager:BindEvent(ClientEventDef.EV_EXIT_LOADING, fnFunc)
    end
end

function ToastSystem:UnbindToastEvent()
    local fnFunc = self.fnToastCallback
    if(fnFunc) then
        self.fnToastCallback = nil
        EventManager:UnBindEvent(ClientEventDef.EV_EXIT_CINEMATIC_MODE, fnFunc)
        EventManager:UnBindEvent(ClientEventDef.EV_EXIT_LOADING, fnFunc)
    end
end

function ToastSystem:ShowToast(nServerInstanceId,
    nid,
    param0, param1, param2,
    ToastType,
    nCampType,
    nWaitTime)

    self:UnbindToastEvent()

    local l10nText = L10N:Format(ObjectiveDataTable:GetTextById(nid),
        param0, param1, param2)
    local tbPlayerSelf = GamePlayerSelfHelper:Get()

    if(UIManager:GetInCinematicMode() or LoadingSystem:GetInLoading()) then
        self.fnToastCallback = function()
            self:UnbindToastEvent()
            for i = 1, #self.tbToastList, 1 do
                local tbTempObject = self.tbToastList[i]
                local TempToastType = tbTempObject.ToastType
                local nTempnServerInstanceId = tbTempObject.nServerInstanceId
                local nTempCampType = tbTempObject.nTempCampType
                if TempToastType == Proto.BattleToastInfo_EToastType.COMMON then
                    UIUtils.ShowToast(tbTempObject.l10nText, tbTempObject.nWaitTime)
                else
                    if (nTempnServerInstanceId == 0) then
                        if nTempCampType == 0 or (nTempCampType ~= 0 and tbPlayerSelf.BattleCampComponent and tbPlayerSelf.BattleCampComponent:GetCampType() == nTempCampType) then
                            UIUtils.ShowSpecialToast(tbTempObject.nid, tbTempObject.l10nText, tbTempObject.nWaitTime, true)
                        end
                    elseif tbPlayerSelf.nServerInstanceId == nTempnServerInstanceId then
                        UIUtils.ShowSpecialToast(tbTempObject.nid, tbTempObject.l10nText, tbTempObject.nWaitTime, false)
                    end
                end
            end
            self.tbToastList = {}
        end
        if self.tbToastList == nil then
            self.tbToastList = {}
        end
        table.insert(self.tbToastList, { nid = nid, l10nText = l10nText, nWaitTime = nWaitTime,
                                        nServerInstanceId = nServerInstanceId, ToastType = ToastType, nCampType = nCampType })
        self:BindToastEvent()
    else
        if ToastType == Proto.BattleToastInfo_EToastType.COMMON then
            UIUtils.ShowToast(l10nText, nWaitTime)
        else
            if (nServerInstanceId == 0) then
                if nCampType == 0 or (nCampType ~= 0 and tbPlayerSelf.BattleCampComponent and tbPlayerSelf.BattleCampComponent:GetCampType() == nCampType) then
                    UIUtils.ShowSpecialToast(nid, l10nText, nWaitTime, true)
                end
            elseif tbPlayerSelf.nServerInstanceId ~= nServerInstanceId then
                UIUtils.ShowSpecialToast(nid, l10nText, nWaitTime, false)
            end

        end
    end
end

return ToastSystem