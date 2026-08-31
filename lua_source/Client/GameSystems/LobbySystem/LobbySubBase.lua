-----------------------------------------------------
--File Name    : LobbySubBase.lua
--Author       : Ran Jie
--Create Time  : 2020-04-26
--Description  : 大厅子系统基类
-----------------------------------------------------

local luaclass = require("luaclass")
local LobbySubBase = luaclass("LobbySubBase")
local LobbySubLevelDataTable = require("LobbySubLevelDataTable")
local SelfEventHelper = require("SelfEventHelper")
local LobbySubLevelHelper = require("LobbySubLevelHelper")
local SoundManager = require("SoundManager")
local ClientEventDef = require("ClientEventDef")

LobbySubBase.nSubType = nil
LobbySubBase.Owner = nil
LobbySubBase.tbRestoreContext = nil

local function LoadSubLevelAsync(self)
    self.SubLevelLoadHelper:LoadSubLevelAsync(self.nSubType)
end


local function LoadSubLevelSync(self)
    self.SubLevelLoadHelper:LoadSubLevelSync(self.nSubType)
end

local function OnViewportResized(self)
    self.SubLevelLoadHelper:OnViewPortChanged(self.nSubType)
end

-----------------override--------------------
function LobbySubBase:Init(Owner, nSubType)
    log("LobbySubBase:Init",nSubType)
    self.Owner = Owner
    self.nSubType = nSubType
    self.EventHelper = SelfEventHelper()
    self.SubLevelLoadHelper = LobbySubLevelHelper()
    self.SubLevelLoadHelper:Init()
end

function LobbySubBase:Uninit()
    log("LobbySubBase:Uninit",self.nSubType)
    self.SubLevelLoadHelper:Uninit()
    self.EventHelper:UnregisterAll()
end

function LobbySubBase:Activate(tbParam)
    log("LobbySubBase:Activate", self.nSubType)
    LoadSubLevelSync(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_VIEWPORT_RESIZED, self, OnViewportResized)
end

function LobbySubBase:Deactivate()
    log("LobbySubBase:Deactivate", self.nSubType)
    self.EventHelper:UnregisterAll()
    self.SubLevelLoadHelper:SetShouldBeVisible(self.nSubType, nil, false)
    -- local UIManager = require("UIManager")
    -- UIManager:ResetCurrentState()
end

function LobbySubBase:SetRestoreContext(tbContext)
    self.tbRestoreContext = tbContext
end

--在这里写恢复的上下文数据
function LobbySubBase:GetRestoreContext()
    return nil
end

function LobbySubBase:PreloadResoucesAsync()
    LoadSubLevelAsync(self)
end

-------------------外部接口--------------------
function LobbySubBase:GetLevelStream(szWndName)
    return self.SubLevelLoadHelper:GetSubLevel(self.nSubType, szWndName)
end

function LobbySubBase:PlayBGMusic(szWndName)
    local tbSubLevelTemplate = LobbySubLevelDataTable:GetTemplate(self.nSubType, szWndName)
    if tbSubLevelTemplate and tbSubLevelTemplate.nBGMId ~= -1 then
        local nBGMId = tbSubLevelTemplate.nBGMId
        local CurrentBackgroundMusic = SoundManager.CurrentBackgroundMusic
        if not CurrentBackgroundMusic or CurrentBackgroundMusic.nID ~= nBGMId then
            SoundManager:PlayBackgroundMusic(nBGMId)
        end
    end
end

function LobbySubBase:SetCamera(szWndName, nCameraIndex)
    self:SetCameraWithBlend(szWndName, nCameraIndex, 0, EViewTargetBlendFunction.VTBlend_Linear, 0)
end

function LobbySubBase:PlayCameraShake(szShakePath)
    self.SubLevelLoadHelper:PlayCameraShake(szShakePath)
end

function LobbySubBase:SetCameraWithBlend(szWndName, nCameraIndex, nBlendTime, pBlendFunction, nBlendExp)
    self.SubLevelLoadHelper:SetCameraWithBlend(self.nSubType, szWndName, nCameraIndex, nBlendTime, pBlendFunction, nBlendExp)
end

function LobbySubBase:SetShouldBeVisible(szWndName, bVisible)
    self.SubLevelLoadHelper:SetShouldBeVisible(self.nSubType, szWndName, bVisible)
end

function LobbySubBase:GetLocationAndRotationByTag(nSubType, szWndName, szActorTag)
    local pLocation, pRotation = self.SubLevelLoadHelper:GetLocationAndRotationByTag(nSubType, szWndName, szActorTag)
    return pLocation, pRotation
end

function LobbySubBase:SetActorSkeletalMeshLightChannel(szWndName, pActor)
    -- self.SubLevelLoadHelper:SetActorSkeletalMeshLightChannel(self.nSubType, szWndName, pActor)
end


return LobbySubBase