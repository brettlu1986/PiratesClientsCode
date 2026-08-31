local SaveGameDef       = require("SaveGameDef")
local SoundManager      = require("SoundManager")
local EventManager      = require("EventManager")
local ClientEventDef    = require("ClientEventDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
-- local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local SettingSystem = {}
SettingSystem.tbPreChanged   = nil

local CUSTOM_QUALITY_LEVEL = 5

local PAINTINGQUALITYSETTING = {
    -- 阴影效果
    [SaveGameDef.SETTING_SHADOWQUALITY] = {
        nMaxQuality = 2,
        fnGet = function(pRenderSettingManager)
            return pRenderSettingManager:GetShadowQuality() + 1
        end,
        fnSet = function(pRenderSettingManager, nValue)
            pRenderSettingManager:SetShadowQuality(nValue - 1)
        end,
    },
    -- 特效质量
    [SaveGameDef.SETTING_EFFECTQUALITY] = {
        nMaxQuality = 4,
        fnGet = function(pRenderSettingManager)
            return pRenderSettingManager:GetEffectsQuality() + 1
        end,
        fnSet = function(pRenderSettingManager, nValue)
            pRenderSettingManager:SetEffectsQuality(nValue - 1)
        end,        
    },
    -- 植被密度
    [SaveGameDef.SETTING_FOLIAGEQUALITY] = {
        nMaxQuality = 4,
        fnGet = function(pRenderSettingManager)
            return pRenderSettingManager:GetFoliageQuality() + 1
        end,
        fnSet = function(pRenderSettingManager, nValue)
            pRenderSettingManager:SetFoliageQuality(nValue - 1)
        end,        
    },
    -- 背景虚化
    [SaveGameDef.SETTING_DEPTHOFFIELD] = {
        fnGet = function(pRenderSettingManager)
            return pRenderSettingManager:IsDepthOfFieldEnabled()
        end,
        fnSet = function(pRenderSettingManager, bValue)
            pRenderSettingManager:SetDepthOfFieldEnabled(bValue)
        end,        
    },
    -- 光晕
    [SaveGameDef.SETTING_BLOOM] = {
        fnGet = function(pRenderSettingManager)
            return pRenderSettingManager:IsBloomEnabled()
        end,
        fnSet = function(pRenderSettingManager, bValue)
            pRenderSettingManager:SetBloomEnabled(bValue)
        end,        
    },
    -- 加载距离
    [SaveGameDef.SETTING_VIEWDISTANCEQUALITY] = {
        nMaxQuality = 4,
        fnGet = function(pRenderSettingManager)
            return pRenderSettingManager:GetViewDistanceQuality() + 1
        end,
        fnSet = function(pRenderSettingManager, nValue)
            pRenderSettingManager:SetViewDistanceQuality(nValue - 1)
        end,        

    },
}

local BASESETTING = {
    [SaveGameDef.SETTING_MUSIC] = {
        fnGet = function(self, pSaveGameMgr)
            local bValue = pSaveGameMgr:GetBoolDataWithDefault(SaveGameDef.SETTING_MUSIC, true)
            return bValue
        end,
        fnSet = function(self, pSaveGameMgr, bValue, bSave)
            if bSave then
                pSaveGameMgr:AddBoolData(SaveGameDef.SETTING_MUSIC, bValue)
            end
            SoundManager:SetPlayMusic(bValue)
        end,
    },
    [SaveGameDef.SETTING_SOUND] = {
        fnGet = function(self, pSaveGameMgr)
            local bValue = pSaveGameMgr:GetBoolDataWithDefault(SaveGameDef.SETTING_SOUND, true)
            return bValue
        end,
        fnSet = function(self, pSaveGameMgr, bValue, bSave)
            if bSave then
                pSaveGameMgr:AddBoolData(SaveGameDef.SETTING_SOUND, bValue)
            end
            SoundManager:SetPlaySound(bValue)            
        end,        
    },
    [SaveGameDef.SETTING_HEADINFO] = {
        fnGet = function(self, pSaveGameMgr)
            local bValue = pSaveGameMgr:GetBoolDataWithDefault(SaveGameDef.SETTING_HEADINFO, false)
            return bValue
        end,
        fnSet = function(self, pSaveGameMgr, bValue, bSave)
            if bSave then
                pSaveGameMgr:AddBoolData(SaveGameDef.SETTING_HEADINFO, bValue)
            end
            GlobalVariableSystem.bBattleFullHeadInfo = bValue
            if GlobalVariableSystem:IsInDungeon() then  
                self.tbPreChanged[SaveGameDef.SETTING_HEADINFO] = nil
                EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_FULL_HEAD_INFO_STATE_CHANGED, bValue)
            else
                self.tbPreChanged[SaveGameDef.SETTING_HEADINFO] = bValue
            end
        end,
    },
    [SaveGameDef.SETTING_COMMONINPUT] = {
        fnGet = function(self, pSaveGameMgr)
            local nValue = pSaveGameMgr:GetFloatDataWithDefault(SaveGameDef.SETTING_COMMONINPUT, 1)
            return nValue
        end,
        fnSet = function(self, pSaveGameMgr, nValue, bSave)
            if bSave then
                pSaveGameMgr:AddFloatData(SaveGameDef.SETTING_COMMONINPUT, nValue)
            end                

            -- local tbPlayer = GamePlayerSelfHelper:Get()
            -- local CameraControlManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
            -- if tbPlayer and tbPlayer:IsShip() then
            --     self.tbPreChanged[SaveGameDef.SETTING_COMMONINPUT] = nil
            --     CameraControlManager.ShipCameraControlComponent:SetCommonInputScale(nValue)
            -- else
            --     self.tbPreChanged[SaveGameDef.SETTING_COMMONINPUT] = nValue
            -- end                    
        end,
    },
    [SaveGameDef.SETTING_AIMINPUT] = {
        fnGet = function(self, pSaveGameMgr)
            local nValue = pSaveGameMgr:GetFloatDataWithDefault(SaveGameDef.SETTING_AIMINPUT, 1)
            return nValue
        end,
        fnSet = function(self, pSaveGameMgr, nValue, bSave)
            if bSave then
                pSaveGameMgr:AddFloatData(SaveGameDef.SETTING_AIMINPUT, nValue)
            end                                

            -- local tbPlayer = GamePlayerSelfHelper:Get()
            -- local pPlayer = tbPlayer and GamePlayerSelfHelper:GetUEActor()
            -- local CameraControlManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
            -- if GlobalVariableSystem:IsInDungeon() and pPlayer then
            --     self.tbPreChanged[SaveGameDef.SETTING_AIMINPUT] = nil
            --     -- CameraControlManager.ShipCameraControlComponent:SetAimInputScale(nValue)
            -- else
            --     self.tbPreChanged[SaveGameDef.SETTING_AIMINPUT] = nValue
            -- end
        end,
    }
    
}

local function OnPlayerSelfReady(self)
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    for k, v in pairs(self.tbPreChanged) do
        local tbSetting = BASESETTING[k]
        local value = tbSetting.fnGet(self, pSaveGameMgr)
        tbSetting.fnSet(self, pSaveGameMgr, value, false)
    end
end

function SettingSystem:Init()
    self.tbPreChanged = {}
    EventManager:BindEventMethod(ClientEventDef.EV_PLAYERSELF_READY, self, OnPlayerSelfReady)
end

function SettingSystem:Uninit()
    EventManager:UnBindEventMethod(ClientEventDef.EV_PLAYERSELF_READY, self, OnPlayerSelfReady)
    self.tbPreChanged = nil
end

function SettingSystem:LoadUserSetting()
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()

    -- painting
    local pRenderSettingManager = ClientShell.GetClient(GWorld):GetRenderSettingsManager()   
    if pRenderSettingManager ~= nil then 
        local nLevel = pRenderSettingManager:GetQuality() + 1    
        nLevel = pSaveGameMgr:GetIntDataWithDefault(SaveGameDef.SETTING_PAINTINGQUALITY, nLevel)
        if nLevel ~= CUSTOM_QUALITY_LEVEL then
            log("SetUserPaintingQuality ", nLevel)
            pRenderSettingManager:SetQuality(nLevel - 1)        
        else
            for k, v in pairs(PAINTINGQUALITYSETTING) do
                local value
                if v.nMaxQuality ~= nil then
                    value = pSaveGameMgr:GetIntDataWithDefault(k, 0)
                else
                    value = pSaveGameMgr:GetBoolDataWithDefault(k, false)                 
                end
                log("SetUserPaintingSubQuality ", k, value)
                v.fnSet(pRenderSettingManager, value)
            end
        end 
    end

    -- base
    for k, v in pairs(BASESETTING) do
        local value = v.fnGet(self, pSaveGameMgr)
        v.fnSet(self, pSaveGameMgr, value, false)
    end
end 

function SettingSystem:LoadPaintingQuality(pRenderSettingManager, pSaveGameMgr)
    local nQuality = pRenderSettingManager:GetQuality() + 1
    nQuality = pSaveGameMgr:GetIntDataWithDefault(SaveGameDef.SETTING_PAINTINGQUALITY, nQuality)
        
    return nQuality
end

function SettingSystem:SetPaintingQuality(pRenderSettingManager, pSaveGameMgr, nQuality)
    pRenderSettingManager:SetQuality(nQuality - 1)
    pSaveGameMgr:AddIntData(SaveGameDef.SETTING_PAINTINGQUALITY, nQuality)
end

function SettingSystem:SetSubPaintingQuality(pRenderSettingManager, pSaveGameMgr, szKey, value, nQuality, bForce)
    local tbSetting = PAINTINGQUALITYSETTING[szKey]
    
    if nQuality == CUSTOM_QUALITY_LEVEL and bForce then
        tbSetting.fnSet(pRenderSettingManager, value)
    end
    if type(value) == "number" then
        pSaveGameMgr:AddIntData(szKey, value)
    else
        pSaveGameMgr:AddBoolData(szKey, value)
    end
end

function SettingSystem:GetSubPaintingQuality(pRenderSettingManager, pSaveGameMgr, szKey, nQuality)
    local tbSetting = PAINTINGQUALITYSETTING[szKey]
    local Ret
    if nQuality < CUSTOM_QUALITY_LEVEL then
        Ret = tbSetting.fnGet(pRenderSettingManager)
    else
        if tbSetting.nMaxQuality ~= nil then
            Ret = pSaveGameMgr:GetIntDataWithDefault(szKey, 0)
        else
            Ret = pSaveGameMgr:GetBoolDataWithDefault(szKey, false)
        end
    end
    return Ret
end

function SettingSystem:LoadSubPaintingQuality(pRenderSettingManager, pSaveGameMgr, nQuality)
    local tbSubQuality = {}
    for k, v in pairs(PAINTINGQUALITYSETTING) do
        local value = self:GetSubPaintingQuality(pRenderSettingManager, pSaveGameMgr, k, nQuality)
        self:SetSubPaintingQuality(pRenderSettingManager, pSaveGameMgr, k, value, nQuality, false)
        tbSubQuality[k] = value
    end

    return tbSubQuality
end

function SettingSystem:GetSubPaintingMaxQuality(szKey)
    local tbSetting = PAINTINGQUALITYSETTING[szKey]
    return tbSetting and tbSetting.nMaxQuality
end

function SettingSystem:GetSubBaseSettingValue(pSaveGameMgr, szKey)
    local tbSetting = BASESETTING[szKey]
    return tbSetting and tbSetting.fnGet(self, pSaveGameMgr)    
end

function SettingSystem:SetSubBaseSettingValue(pSaveGameMgr, szKey, value)
    local tbSetting = BASESETTING[szKey]
    tbSetting.fnSet(self, pSaveGameMgr, value, true)
end

return SettingSystem