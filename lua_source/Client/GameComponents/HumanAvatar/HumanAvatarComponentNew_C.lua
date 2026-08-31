-----------------------------------------------------
--File Name    : HumanAvatarComponentNew_C.lua
--Author       : WuJizhou
--Create Time  : 4/13/2020, 7:50:39 PM
--Description  : HumanAvatarComponentNew_C
-----------------------------------------------------
local luaclass                  = require("luaclass")
local HumanAvatarComponentNew   = require("HumanAvatarComponentNew")
local HumanAvatarComponentNew_C = luaclass("HumanAvatarComponentNew_C", HumanAvatarComponentNew)

local CppDelegate               = require("CppDelegate")
local EventManager              = require("EventManager")
local GameAvatarHelper          = require("GameAvatarHelper")
local ClientEventDef            = require("ClientEventDef")

local GlobalVariableSystem      = dynamic_require("GlobalVariableSystem")

-- local MERGE_FLAG = true

local function SetMergeSkeletalMeshFlag(pUEActor)
    -- if GlobalVariableSystem.bCancelMerge then
    --     pUEActor.HumanAvatarComponent:SetMergeSkeletalMesh(false)
    -- else
    --     pUEActor.HumanAvatarComponent:SetMergeSkeletalMesh(MERGE_FLAG)
    -- end
end


local function OnUpdateCommit(self)
    if self.Owner then
        EventManager:OnFireEvent(ClientEventDef.EV_HUMAN_AVATAR_COMMIT_FINISHED, self.Owner:GetServerInstanceId())
    end
    -- EngineExtActorShell.SetActorSkeletalMeshLightChannel(self.pHumanActor, false, true, false)
end

local function UnbindCommitDelegate(self)
    if self.CommitDelegate then
        self.CommitDelegate:Unbind()
    end
    self.CommitDelegate = nil
end

local function BindCommitDelegate(self)
    UnbindCommitDelegate(self)
    local pUEActor = self.Owner.pUEActor
    self.CommitDelegate = CppDelegate:Bind(pUEActor.HumanAvatarComponent.OnCommitFinishDelegate, function () OnUpdateCommit(self) end)
end

-- tbNewData: { key:HumanAvatarDef.PartProtoDef, value: part id / color id}
function HumanAvatarComponentNew_C:OnAvatarResDataChanged(rProperty, tbNewData)
    self:RefreshAvatar(tbNewData)
end


function HumanAvatarComponentNew_C:RefreshAvatar(tbData, bMerged)
    local tbPlayer = self.Owner
    if tbPlayer:IsHuman() then
        local pUEActor = tbPlayer.pUEActor
        local pAvatarComponent = pUEActor.HumanAvatarComponent
        if bMerged then
            self:SetMerged(bMerged)
        else
            SetMergeSkeletalMeshFlag(pUEActor)
        end
        GameAvatarHelper.UpdateHumanAvatar(pAvatarComponent, tbData)
    end
end

-- function HumanAvatarComponentNew_C:RefreshAvatarByParams(tbParams, OnUpdateCommit, bMerged)
--     if GlobalVariableSystem:IsInLobby() then
--         self:InitMiscData(tbParams)
--         self:UpdateAll()
--         local tbMiscData = self.tbMiscData
--         local tbData = tbMiscData:GetPartDatas()
--         self:RefreshAvatar(tbData, OnUpdateCommit, bMerged)
--     end
-- end


function HumanAvatarComponentNew_C:SetMerged(bMerged)
    -- local tbPlayer = self.Owner
    -- if tbPlayer:IsHuman() then
    --     local pUEActor = tbPlayer.pUEActor
    --     local pAvatarComponent = pUEActor.HumanAvatarComponent
    --     pAvatarComponent:SetMergeSkeletalMesh(bMerged)
    -- end
end

-------base api from GameComponentBaseClass--------
-- function HumanAvatarComponentNew_C:OnCreate(Owner, tbParams)
--     HumanAvatarComponentNew_C.super.OnCreate(self, Owner, tbParams)
--     return true
-- end

-- function HumanAvatarComponentNew_C:OnDestroy()
--     HumanAvatarComponentNew_C.super.OnDestroy(self)
-- end

-- function HumanAvatarComponentNew_C:GetOwner()
--     return self.super.GetOwner(self)
-- end

-- function HumanAvatarComponentNew_C:OnActorPreCreated(pUEActor)
--     HumanAvatarComponentNew_C.super.OnActorPreCreated(self, pUEActor)
--     if self.Owner:IsHuman() then
--         local tbTemplate = HumanDataTable:GetTemplate(self.Owner:GetTemplateId())
--         local nHumanGender = tbTemplate.nGender
--         if nHumanGender == GenderTypeDefine.MALE then
--             pUEActor:SetGender(ENUM_HumanGender.Male)
--         else
--             pUEActor:SetGender(ENUM_HumanGender.Female)
--         end
--     end
-- end

function HumanAvatarComponentNew_C:OnActorCreated(pUEActor)
    HumanAvatarComponentNew_C.super.OnActorCreated(self, pUEActor)
    BindCommitDelegate(self)
    if GlobalVariableSystem:IsInLobby() then
        self:OnAvatarResDataChanged(nil, self.tbComponentData:GetPartDatas())
    else
        self:RefreshAvatar(self.rHumanAvatarData:Get())
    end

end

function HumanAvatarComponentNew_C:OnActorDestroyed(...)
    UnbindCommitDelegate(self)
    HumanAvatarComponentNew.super.OnActorDestroyed(self, ...)
end

return HumanAvatarComponentNew_C