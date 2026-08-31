local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpForBornPoint = luaclass("MapOpForBornPoint", MapOpBase)
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UIResourceDef = require("UIResourceDef")
local MapObjType = require("MapObjType")
local ParachutionSystem_C = require("ParachutionSystem_C")
local ParachutingNewIni = require("ParachutingNewIni")

-- MapOpForBornPoint.tbPosList = nil
MapOpForBornPoint.tbPreLoadPrefabList = nil
MapOpForBornPoint.tbPrefabList = nil
MapOpForBornPoint.tbMemberList = nil
-- local MAX_PRE_LOAD_PREFAB_COUNT = 4

local OBJTYPE = {
    SELF = 1, 
    TEAMMEMBER = 2,
    OTHER = 3,
    BOT = 4
}

local OBJCOLOR = {
    [OBJTYPE.SELF] = UIResourceDef.COLOR.BLUE3.SLATE_COLOR ,
    [OBJTYPE.TEAMMEMBER] = UIResourceDef.TEAM_INDEX_SLATECOLOR,
    [OBJTYPE.OTHER] = UIResourceDef.COLOR.RED.SLATE_COLOR,
    [OBJTYPE.BOT] = UIResourceDef.COLOR.RED.SLATE_COLOR
}

local POINT_SIZEX, POINT_SIZEY = 20, 35

local function Clear(self)
    for k, v in pairs(self.tbPrefabList) do
        v:Clear(self.MapOpObj)
    end
end

local function GetTeamMemberIndex(self, nSelfId, nId)
    local BattleTeamComponent = GamePlayerSelfHelper:Get().BattleTeamComponent
    local TeamInfos = BattleTeamComponent.tbBattleTeamInfo and BattleTeamComponent.tbBattleTeamInfo.TeamInfos
    if TeamInfos then
        for i, v in ipairs(TeamInfos) do
            if nId == v.nInstanceId then
                return v.nIndex
            end
        end
    elseif nSelfId == nId then
        return 1
    end
    return 0 
end

local function GetMapObjRes(self, nId, bIsBot)
    local szRes = UIResourceDef.BORN_POINT

    local nSelfId = GamePlayerSelfHelper:GetServerInstanceId() 
    local nMemberIndex = GetTeamMemberIndex(self, nSelfId, nId)
    if nMemberIndex > 0 then
        return szRes, OBJCOLOR[OBJTYPE.TEAMMEMBER][nMemberIndex], nId == nSelfId
    end
    return szRes, OBJCOLOR[OBJTYPE.OTHER]
end

local function CreateBornPos(self, bIsSelf)
    local pbContentObj
    if bIsSelf then
        pbContentObj = self:GetOneObj(MapObjType.SELF_BORN_POINT)
    else
        pbContentObj = self:GetOneObj(MapObjType.BORN_POINT)
    end
    --pbContentObj:SetOwner(self.Parent)
    local ObjWidget = pbContentObj.pWidgetRef
    --self.pWidgetRef.cvsMapContent:AddChildToCanvas(ObjWidget)
    --ObjWidget:SetVisibility(ESlateVisibility.HitTestInvisible)
    local ObjWidgetSlot = ObjWidget.Slot
    ObjWidgetSlot:SetZOrder(bIsSelf and 14 or 13)
    if bIsSelf then
        ObjWidgetSlot:SetAlignment(Vector2D{X = 0.5, Y = 0.5})
    else
        ObjWidgetSlot:SetAlignment(Vector2D{X = 0.5, Y = 1})
    end
    ObjWidgetSlot:SetAutoSize(false)
    --ObjWidgetSlot:SetSize(Vector2D{X=POINT_SIZEX, Y=POINT_SIZEY})

    return pbContentObj
end

-- local function GetBornPos(self, bIsSelf)
--     local tbPreLoad = self.tbPreLoadPrefabList
--     if bIsSelf then
--         return tbPreLoad[1].pbObj
--     else
--         for i = 2, MAX_PRE_LOAD_PREFAB_COUNT do
--             if not tbPreLoad[i].bUsed then
--                 tbPreLoad[i].bUsed = true
--                 return tbPreLoad[i].pbObj
--             end 
--         end
--     end
-- end

local function RefreshBornPos(self, nId, tbPos, bPlayAnimation)
    local pbContentObj = self.tbPrefabList[nId]
    if pbContentObj == nil then
        logwarning("MapOpForBornPoint RefreshBornPos not find up", nId)
        return
    end
    pbContentObj:SetWorldPosition(tbPos.X, tbPos.Y)
    pbContentObj:Refresh(self.MapOpObj)
    if bPlayAnimation then
        pbContentObj:PlaySelectAnimation()
    end
end

local function AddBornPos(self, nId, bIsBot)
    local szRes, pSlateColor, bIsSelf = GetMapObjRes(self, nId, bIsBot)
    local pbContentObj = CreateBornPos(self, bIsSelf)
    local tbData = {szIcon = szRes, SlateColor = pSlateColor, Dimension = Vector2D{X=POINT_SIZEX, Y=POINT_SIZEY}, UISize = {X=POINT_SIZEX, Y=POINT_SIZEY}, bMatchSize = false}    
    pbContentObj:ShowContent(tbData)

    self.tbPrefabList[nId] = pbContentObj
end

local function RemoveBornPos(self, nId)
    local pbContentObj = self.tbPrefabList[nId]
    if pbContentObj == nil then
        return
    end
    pbContentObj:HideContent()
end

local function IsShowBornPos(self, nId)
    if ParachutingNewIni.tbReadyArea.bOtherSelectionPoint then
        return true
    end
    local nSelfId = GamePlayerSelfHelper:GetServerInstanceId() 
    local nMemberIndex = GetTeamMemberIndex(self, nSelfId, nId)
    return nMemberIndex > 0
end

function MapOpForBornPoint:Init(Parent)
    MapOpForBornPoint.super.Init(self, Parent)
    local MapOpObj = self:GetOpObj(UIMapOpPoint)
    MapOpObj:InitParam(self.pWidgetRef, 0, 0, 0)
    MapOpObj:SetEnable(false)
    self.pWidgetRef:RegisterOperation(MapOpObj)

    -- self.tbPreLoadPrefabList = {}
    -- for i = 1, MAX_PRE_LOAD_PREFAB_COUNT do
    --     local pbContentObj = CreateBornPos(self, i == 1)
    --     table.insert(self.tbPreLoadPrefabList, {bUsed = false, pbObj = pbContentObj})
    -- end

    self.tbPrefabList = {}
    self.tbMemberList = {}

    local tbPointes = ParachutionSystem_C:GetSelectionPointes() 
    if tbPointes == nil or #tbPointes == 0 then 
        return
    end
    for i, v in ipairs(tbPointes) do
        self:SetBornPos(v.nInstanceId, {X = v.nX * 1, Y = v.nY * 1}, v.nTransporterId == 0)
    end
end

function MapOpForBornPoint:Reinit()
    MapOpForBornPoint.super.Reinit(self)
    local tbPointes = ParachutionSystem_C:GetSelectionPointes() 
    if tbPointes == nil or #tbPointes == 0 then 
        return
    end
    for i, v in ipairs(tbPointes) do
        self:SetBornPos(v.nInstanceId, {X = v.nX * 1, Y = v.nY * 1}, v.nTransporterId == 0)
    end    
end

function MapOpForBornPoint:Uninit()
    Clear(self)
    self.tbPreLoadPrefabList = nil
    self.tbPrefabList = nil
    self.tbMemberList = nil
    MapOpForBornPoint.super.Uninit(self)
end

function MapOpForBornPoint:SetBornPos(nId, tbPos, bIsBot, bPlayAnimation)
    if nId == nil or tbPos == nil then
        return
    end
    log("select point set born pos 1")

    if IsShowBornPos(self, nId) then
        log("select point set born pos 3")
        if self.tbPrefabList[nId] == nil then
            AddBornPos(self, nId, bIsBot)
        else
            self.tbPrefabList[nId].pWidgetRef.cvsPosPanel:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        end
        log("select point set born pos 4")
        RefreshBornPos(self, nId, tbPos, bPlayAnimation)
        log("select point set born pos 5")
    else
        if self.tbPrefabList[nId] ~= nil then
            RemoveBornPos(self, nId)
        end    
    end
    log("select point set born pos 2")
end

function MapOpForBornPoint:CancelBornPos(nId)
    if self.tbPrefabList[nId] ~= nil then
        log("cance born pos")
        RemoveBornPos(self, nId)
    end    
end

function MapOpForBornPoint:Refresh(bHide)
    local nSelfId = GamePlayerSelfHelper:GetServerInstanceId() 
    local fnIsShow = function(nId)
        if bHide then
            local nMemberIndex = GetTeamMemberIndex(self, nSelfId, nId)
            return nMemberIndex > 0
        else
            return true
        end
    end

    for k, v in pairs(self.tbPrefabList) do
        if fnIsShow(k) then
            v.pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        else
            v.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end

function MapOpForBornPoint:RefreshTeam()
    -- for i, v in ipairs(tbRemoveMembers) do
    --     RemoveBornPos(self, v) 
    -- end
end

return MapOpForBornPoint