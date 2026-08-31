-----------------------------------------------------
-----------------------------------------------------
--File Name    : ChannelSDKSystem.lua
--Author       : Edward J
--Create Time  : 2019-07-08
--Description  :
-----------------------------------------------------
local ChannelSDKSystem          = {}
local GlobalVariableSystem      = dynamic_require("GlobalVariableSystem")
local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")
local dkjson                    = require("dkjson")
local SDKMiscIni                = require("SDKMiscIni")
local SaveGameDef               = require("SaveGameDef")
local UIManager                 = require("UIManager")
local UIDef                     = require("UIDef")
local DelayTimer                = require("DelayTimer")
local SelfEventHelper           = require("SelfEventHelper")
local ClientEventDef            = require("ClientEventDef")
local Proto                     = require("ClientProtoNames")
local UIUtils                   = require("UIUtils")

--member veriable
local SDK_EVENT_TRACK_LEVEL         = 5
local SDK_EVENT_TRACK_LEVEL_NAME    = "player_level_five"
local SDK_EVENT_TRACK_BATTLE        = 1
local SDK_EVENT_TRACK_BATTLE_NAME   = "player_first_battle"
local PROTO_PLATFORM_ENUM           = Proto.c2s_Login_Platform
-- local PROTO_CHANNEL_ENUM            = Proto.c2s_Login_Channel


ChannelSDKSystem.pChannelSdkManager         = nil
ChannelSDKSystem.bCheckScoreAndBind         = nil
ChannelSDKSystem.bPrepareShowScoreDialog    = nil
ChannelSDKSystem.pSaveGameMgr               = nil
ChannelSDKSystem.bScoreShowed               = true
ChannelSDKSystem.bBindShowed                = true
ChannelSDKSystem.DelayTimerHandle           = nil
ChannelSDKSystem.szChannelID                = nil
ChannelSDKSystem.tbChannelProtoEnum         = nil
ChannelSDKSystem.tbPlatformlProtoEnum       = nil
-----------------------------------------------------

local function CheckSdkManagerValid(self)
    local pChannelSdkManager = self.pChannelSdkManager
    if not pChannelSdkManager then
        logerror("[ChannelSDKSystem] CheckSdkManagerValid pChannelSdkManager is invalid!")
        return false
    end
    return true
end

function ChannelSDKSystem:Init()
    local pChannelSdkManager = GlobalVariableSystem:GetChannelSdkManager()
    if pChannelSdkManager then
        self.pChannelSdkManager = pChannelSdkManager
        self.szChannelID = pChannelSdkManager:GetChannel()
    end
    self.bPrepareShowScoreDialog = false
    self.bPrepareShowBindAccount = false
    self.tbChannelProtoEnum = {}
    self.tbPlatformlProtoEnum = {}
    -- local tbChannelProtoEnum = self.tbChannelProtoEnum
    local tbPlatformlProtoEnum = self.tbPlatformlProtoEnum
    self:AddTableVaule(tbPlatformlProtoEnum, "android", PROTO_PLATFORM_ENUM.ANDROID)
    self:AddTableVaule(tbPlatformlProtoEnum, "ios", PROTO_PLATFORM_ENUM.IOS)
    self:AddTableVaule(tbPlatformlProtoEnum, "windows", PROTO_PLATFORM_ENUM.WINDOWS)
    -- self:AddTableVaule(tbChannelProtoEnum, "none", PROTO_CHANNEL_ENUM.NONE)
    -- self:AddTableVaule(tbChannelProtoEnum, "google_play", PROTO_CHANNEL_ENUM.GOOGLE_PLAY)
    -- self:AddTableVaule(tbChannelProtoEnum, "app_store", PROTO_CHANNEL_ENUM.APP_STORE)
    self.pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    self:RecoverData()
    self:BindEvent()
end

function ChannelSDKSystem:Uninit()
    self:SaveData()
    self:ClearTimer()
    self.pSaveGameMgr = nil
    self.pChannelSdkManager = nil
    self:UnbindEvent()
end

function ChannelSDKSystem:BindEvent()
    self.EventHelper = SelfEventHelper()
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_STACK_TOP, self, self.OnUIStackTop)
end

function ChannelSDKSystem:UnbindEvent()
    local EventHelper = self.EventHelper
    if not EventHelper then
        return
    end
    EventHelper:UnregisterEvent(ClientEventDef.EV_UI_STACK_TOP, self, self.OnUIStackTop)
end

function ChannelSDKSystem:GetManager()
    return self.pChannelSdkManager
end

function ChannelSDKSystem:GetChannelID()
    if not CheckSdkManagerValid(self) then
        return ""
    end
    local szChannelID = self.pChannelSdkManager:GetChannel()
    if szChannelID == "NULL" or szChannelID == "" then
        local szPlatformName = GameplayStatics:GetPlatformName()
        log(" eChannelID = " .. tostring(szChannelID) .. " platformName = " .. szPlatformName)
        if szPlatformName == "Android" then
            szChannelID = "INTERNAL_ANDROID"
        elseif szPlatformName == "IOS" then
            szChannelID = "INTERNAL_IOS"
        elseif szPlatformName == "Windows" then
            szChannelID = "INTERNAL_WINDOWS"
        else
            szChannelID = "NONE"
        end
    end
    return szChannelID
end

-- function ChannelSDKSystem:GetProtoChannelIDEnum()
--     --local szChannelID = self.pChannelSdkManager:GetChannel()
--     local szChannelID = SDKMiscIni.tbEGSDK.szchannelName
--     local eChannelID = self.tbChannelProtoEnum[szChannelID]
--     log("szChannelID " .. szChannelID .. " eChannelID = " .. tostring(eChannelID))
--     if szChannelID == "none" then
--         local szPlatformName = GameplayStatics:GetPlatformName()
--         log(" eChannelID = " .. tostring(eChannelID) .. " platformName = " .. szPlatformName)
--         if szPlatformName == "Android" then
--             eChannelID = PROTO_CHANNEL_ENUM.INTERNAL_ANDROID
--         elseif szPlatformName == "IOS" then
--             eChannelID = PROTO_CHANNEL_ENUM.INTERNAL_IOS
--         elseif szPlatformName == "Windows" then
--             eChannelID = PROTO_CHANNEL_ENUM.INTERNAL_WINDOWS
--         else
--             eChannelID = PROTO_CHANNEL_ENUM.NONE
--         end
--     end
--     return eChannelID
-- end

function ChannelSDKSystem:GetProtoChannelString()
    local szChannelID = SDKMiscIni.tbEGSDK.szchannelName
    log("szChannelID " .. szChannelID)
    if szChannelID == "none" then
        local szPlatformName = GameplayStatics:GetPlatformName()
        if szPlatformName == "Android" then
            szChannelID = "INTERNAL_ANDROID"
        elseif szPlatformName == "IOS" then
            szChannelID = "INTERNAL_IOS"
        elseif szPlatformName == "Windows" then
            szChannelID = "INTERNAL_WINDOWS"
        else
            szChannelID = "NONE"
        end
        if GWithEditor then
            szChannelID = "NONE"
        end
    end
    return szChannelID   
end

function ChannelSDKSystem:GetProtoPlatformEnum()
    local szPlatformName = GlobalVariableSystem:GetPlatformName(true)
    local ePlatform = self.tbPlatformlProtoEnum[szPlatformName]
    if not ePlatform or GWithEditor then
        ePlatform = PROTO_PLATFORM_ENUM.UNKNOWN
    end
    return ePlatform
end

function ChannelSDKSystem:AddTableVaule(tab, key, value)
    if not tab then
        logerror("[ChannelSDKSystem] ChannelSDKSystem:AddTableVaule tab is nil!")
        return
    end
    tab[key] = value
end

function ChannelSDKSystem:ClearTimer()
    if self.DelayTimerHandle then
        DelayTimer:ClearTimer(self.DelayTimerHandle)
        self.DelayTimerHandle = nil
    end
end

function ChannelSDKSystem:RecoverData()
    self.bScoreShowed = true
    self.bBindShowed = true
    local pSaveGameMgr = self.pSaveGameMgr
    if not pSaveGameMgr then
        logerror("ChannelSDKSystem:InitSaveData pSaveGameMgr is nil")
        return
    end
    local bScoreShowed = pSaveGameMgr:GetIntData(SaveGameDef.EGSDK_SHOW_SCORE_DIALOG)
    local bBindShowed = pSaveGameMgr:GetIntData(SaveGameDef.EGSDK_SHOW_BIND_DIALOG)
    if not bScoreShowed or bScoreShowed <=0 then
        self.bScoreShowed = false
    end
    if not bBindShowed or bBindShowed <=0 then
        self.bBindShowed = false
    end

end

function ChannelSDKSystem:SaveData()
    local nScoreShowedResult = 0
    if self.bScoreShowed then
        nScoreShowedResult = 1
    end
    local nBindShowedResult = 0
    if self.bBindShowed then
        nBindShowedResult = 1
    end
    local pSaveGameMgr = self.pSaveGameMgr
    pSaveGameMgr:AddIntData(SaveGameDef.EGSDK_SHOW_SCORE_DIALOG, nScoreShowedResult)
    pSaveGameMgr:AddIntData(SaveGameDef.EGSDK_SHOW_BIND_DIALOG, nBindShowedResult)
    pSaveGameMgr:Save()
end

function ChannelSDKSystem:TrackLevel_Five(nlevel)
    log("ChannelSDKSystem:TrackLevel_Five nlevel = " .. tostring(nlevel))
    local pChannelSdkManager = self.pChannelSdkManager
    if not pChannelSdkManager and pChannelSdkManager:IsValidSdk() then
        logerror("ChannelSDKSystem pChannelSdkManager is nil")
        return
    end
    if nlevel == SDK_EVENT_TRACK_LEVEL then
        pChannelSdkManager:CustomEvent(SDK_EVENT_TRACK_LEVEL_NAME)
    end
end

function ChannelSDKSystem:TrackBattle_First(nCount)
    log("ChannelSDKSystem:TrackBattle_First nCount = " .. tostring(nCount))
    local pChannelSdkManager = self.pChannelSdkManager
    if not pChannelSdkManager and pChannelSdkManager:IsValidSdk() then
        logerror("ChannelSDKSystem pChannelSdkManager is nil")
        return
    end
    if nCount == SDK_EVENT_TRACK_BATTLE then
        pChannelSdkManager:CustomEvent(SDK_EVENT_TRACK_BATTLE_NAME)
    end
end

function ChannelSDKSystem:EGSDKPay(szProductId, szProductName, szPayDes, szServerId, szCPUrl, szPrice, szCurrency)
    log("ChannelSDKSystem:EGSDKPay szProductId = " .. szProductId .. " ProductName = " .. szProductName .. " PayDes = " .. szPayDes .. " szServerId = " .. szServerId .. " szCPUrl = " .. szCPUrl)
    local szPlatformName = GameplayStatics:GetPlatformName()
    -- log("szPlatformName = " .. szPlatformName)
    -- log("IsGoogleExist = " .. tostring(GamePlatformMiscLibrary.IsGoogleExist()))
    -- log("IsGoogleApiAvailable = " .. tostring(GamePlatformMiscLibrary.IsGoogleApiAvailable()))
    if (szPlatformName == "Android") then --安卓平台 没有google框架
        if not GamePlatformMiscLibrary.IsGoogleApiAvailable() or not GamePlatformMiscLibrary.IsGoogleExist() then
            return false
        end
    end
    local pChannelSdkManager = self.pChannelSdkManager
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if not CheckSdkManagerValid(self) or not PlayerSelf then
        logerror("ChannelSDKSystem pChannelSdkManager or PlayerSelf is nil")
        return
    end
    szPrice = (szPrice == nil) and "0" or szPrice
    szCurrency = (szCurrency == nil) and "USD" or szCurrency
    local nPlayerId = PlayerSelf.nPlayerId
    local tbPayInfo = {}
    tbPayInfo.roleid = tostring(nPlayerId)
    tbPayInfo.goodsId = szProductId
    tbPayInfo.goodsName = szProductName
    tbPayInfo.payDes = szPayDes
    tbPayInfo.serverId = szServerId
    tbPayInfo.cpUrl = tostring(szCPUrl)
    tbPayInfo.Price = szPrice
    tbPayInfo.Currency = szCurrency
    local szPayInfo = dkjson.encode(tbPayInfo)
    return pChannelSdkManager:Pay(szPayInfo)
end

function ChannelSDKSystem:ShowBindTipsView()
    log("=====ChannelSDKSystem:ShowBindTipsView======")
    local pChannelSdkManager = self.pChannelSdkManager
    if pChannelSdkManager and pChannelSdkManager:IsValidSdk() then
        if not pChannelSdkManager:IsBindAccount() then
            self.bPrepareShowBindAccount = false
            self.bBindShowed = true
            self:SaveData()
            pChannelSdkManager:ShowBindTipsView()
        end
    end
end

function ChannelSDKSystem:ScoreDialogCanShow()
    local pChannelSdkManager = self.pChannelSdkManager
    local szPlatformName = GameplayStatics:GetPlatformName()
    local bIsIos = szPlatformName == "IOS"
    if pChannelSdkManager and pChannelSdkManager:IsValidSdk() then
        if bIsIos and GlobalVariableSystem:IsIosReviewMode() then
            return false
        else
            return false
        end
    end
    return false
end

function ChannelSDKSystem:FBBtnCanShow()
    local pChannelSdkManager = self.pChannelSdkManager
    local szPlatformName = GameplayStatics:GetPlatformName()
    local bIsIos = szPlatformName == "IOS"
    if pChannelSdkManager and pChannelSdkManager:IsValidSdk() then
        if bIsIos and GlobalVariableSystem:IsIosReviewMode() then
            return false
        else
            return true
        end
    end
    return false
end

function ChannelSDKSystem:ShowScoreDialog()
    log("=====ChannelSDKSystem:ShowScoreDialog======")
    local pChannelSdkManager = self.pChannelSdkManager
    if pChannelSdkManager and self:ScoreDialogCanShow() then
        self.bPrepareShowScoreDialog = false
        self.bScoreShowed = true
        self:SaveData()
        pChannelSdkManager:ShowScoreDialog()
    end
end

function ChannelSDKSystem:ShowFacebookWeb()
    local pChannelSdkManager = self.pChannelSdkManager
    if pChannelSdkManager and pChannelSdkManager:IsValidSdk() then
        local szUrl = SDKMiscIni.tbEGSDK.szfacebookUrl
        pChannelSdkManager:OpenHrefWeb(szUrl)
    end
end

function ChannelSDKSystem:SetShowScoreDialogFlag(bPrepare)
    self.bPrepareShowScoreDialog = bPrepare
end

function ChannelSDKSystem:SetShowBindAccount(bPrepare)
    self.bPrepareShowBindAccount = bPrepare
end


function ChannelSDKSystem:GetChannelName()
    if not CheckSdkManagerValid(self) then
        return ""
    end
    return self.pChannelSdkManager:GetChannelName()
end

function ChannelSDKSystem:IsValidSdk()
    if not CheckSdkManagerValid(self) then
        return false
    end
    return self.pChannelSdkManager:IsValidSdk()
end

local function DelayRunCheck(self)
    local bIsTop = UIManager:IsShowTopUI(UIDef.UI_LOBBY)
    if not self.bScoreShowed then
        if bIsTop then
            self:ShowScoreDialog()
        else
            self.bPrepareShowScoreDialog = true
        end
    else
        if not self.bBindShowed then
            if bIsTop then
                self:ShowBindTipsView()
            else
                self.bPrepareShowBindAccount = true
            end
        end
    end
end

function ChannelSDKSystem:CheckPopDialog()
    log("=======ChannelSDKSystem:CheckPopDialog=======")
    self:ClearTimer()
    self.DelayTimerHandle = DelayTimer:RunNextTick(function() 
        self.DelayTimerHandle = nil
        DelayRunCheck(self) end)
end

function ChannelSDKSystem:OnUIStackTop(szWndName)
    if szWndName == UIDef.UI_LOBBY then
        if self.bPrepareShowScoreDialog then
            self:ShowScoreDialog()
        end
        if self.bPrepareShowBindAccount then
            self:ShowBindTipsView()
        end
    end
end

function ChannelSDKSystem:SwitchAccount()
    if not CheckSdkManagerValid(self) then
        return false
    end
    self.pChannelSdkManager:SwitchAccount()
    return true
end

function ChannelSDKSystem:OnCustomerService()
    if not CheckSdkManagerValid(self) then
        return false
    end
    if not self.pChannelSdkManager:OpenFAQWeb() then
        UIUtils.ShowCustomerHelper()    
    end
    return true
end

function ChannelSDKSystem:IsBindAccount()
    if not CheckSdkManagerValid(self) then
        return false
    end
    return self.pChannelSdkManager:IsBindAccount()
end

function ChannelSDKSystem:AssociaAccount()
    if not CheckSdkManagerValid(self) then
        return false
    end
    return self.pChannelSdkManager:AssociaAccount()
end

function ChannelSDKSystem:OpenUCenter()
    if not CheckSdkManagerValid(self) then
        return false
    end
    return self.pChannelSdkManager:OpenUCenter()
end

function ChannelSDKSystem:Logout()
    if not CheckSdkManagerValid(self) then
        return false
    end
    return self.pChannelSdkManager:Logout()
end

return ChannelSDKSystem