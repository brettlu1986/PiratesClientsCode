-- 势力
local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local FactionComponent = luaclass("FactionComponent", GameComponentBase)
local FactionLevelTable = require("FactionLevelTable")
local FactionDataTable = require("FactionDataTable")
local FactionDef = require("FactionDef")
local UIDef = require("UIDef")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local L10N = require("L10N")

FactionComponent.nCurrentFactionID = FactionDef.Type.FACTION_NONE

-- key : nFactionID
-- value : nContributionPoint
FactionComponent.tbFactionMap = {}

function FactionComponent:OnCreate(Owner, tbParams)
    FactionComponent.super.OnCreate(self, Owner, tbParams)

    if tbParams == nil then
--        logerror('----------------FactionComponent:OnCreate() tbParams is nil')
        return false
    end
    self.nCurrentFactionID = tbParams.faction
    if tbParams.infos then 
        for _, contribution in pairs(tbParams.infos) do
            self.tbFactionMap[contribution.faction] = contribution.point
        end
    end 
    return true
end

function FactionComponent:GetCurrentFactionID()
    return self.nCurrentFactionID
end

function FactionComponent:SetCurrentFactionID(nFactionID)
    self.nCurrentFactionID = nFactionID
    local HeadInfoComponent = self.Owner.HeadInfoComponent
    if HeadInfoComponent then 
        HeadInfoComponent:RefreshWidget(UIDef.UP_NAME_WIDGET)
    end 
end

function FactionComponent:UpdateFactionPoint(nFactionID, nPoint)
    local nOldFactionPoint = self.tbFactionMap[nFactionID]
    self.tbFactionMap[nFactionID] = nPoint
    local szName = self:GetFactionName(nFactionID)
    if nPoint == 0 then     -- 重置
        UIUtils.ShowToast(L10N:Format(UITextDef.FACTION_POINT_RESET, szName))
    elseif nPoint > nOldFactionPoint then -- 增加
        UIUtils.ShowToast(L10N:Format(UITextDef.FACTION_POINT_ADD, szName, nPoint - nOldFactionPoint))
    elseif nPoint < nOldFactionPoint then -- 减少
        UIUtils.ShowToast(L10N:Format(UITextDef.FACTION_POINT_SUB, szName, nOldFactionPoint - nPoint))
    end 
    
end

-- 获得势力贡献值
-- bFind, nContributionPoint
function FactionComponent:GetFactionPoint(nFactionID)
    local nFactionPoint = self.tbFactionMap[nFactionID]
    if nFactionPoint == nil then
        logerror('FactionComponent:GetFactionPoint() : nil faction id : ', nFactionID)
        return false
    end

    return true, nFactionPoint
end

-- 获得势力贡献值信息
-- bFind, ContributionInfo
function FactionComponent:GetFactionInfo(nPoint)
    local tbFactionData = FactionLevelTable:GetTemplate(nPoint)

    if tbFactionData then 
        return true, tbFactionData
    end 
    return false
end

-- 获得当前势力贡献值信息
function FactionComponent:GetCurrentFactionInfo()
    local nFactionPoint = self:GetFactionPoint(self.nCurrentFactionID)
    return self:GetFactionInfo(nFactionPoint)
end

-- 获得势力名字
function FactionComponent:GetFactionName(nFactionID)
    local tbFactionTemplate = FactionDataTable:GetTemplate(nFactionID)
    if tbFactionTemplate == nil then
        logerror('FactionComponent:GetFactionName(), nFactionID : ', nFactionID)
        return nil
    end

    return tbFactionTemplate.szName
end

-- 获得当前势力名称
function FactionComponent:GetCurrentFactionName()
    return self:GetFactionName(self.nCurrentFactionID)
end

function FactionComponent:PrintInfo()
    log('current faction id : ', self.nCurrentFactionID)
    for nFactionID, nFactionPoint in pairs(self.tbFactionMap) do
        log('FactionID id : ', nFactionID, '  FactionPoint : ', nFactionPoint)
    end
end

return FactionComponent
