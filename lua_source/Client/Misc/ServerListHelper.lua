local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local HttpHelper = require("HttpHelper")
local Json = require("dkjson")
local DelayTimer = require("DelayTimer")
local UIUtils = require("UIUtils")
local UITextDef= require("UITextDef")
local UIDef = require("UIDef")
local UIManager = require("UIManager")
local L10N = require("L10N")

local ServerListHelper = {}

local ERROR_CODE = 2

local SERVER_LIST_URL = "https://s3.cn-north-1.amazonaws.com.cn/pirates/dev/servers.json"

local Local_Test_Server_List = {
    { id = 4, name = "本地副本", default = false, hydra = "", hub = "", dungeon = { url = "127.0.0.1:7777", token = "123456", player_id = -1 } },
    { id = 5, name = "内网副本", default = false, hydra = "", hub = "", dungeon = { url = "10.230.10.205:17777", token = "123456", player_id = -1 } },
    { id = 6, name = "tmp", default = false, hydra = "http://pirates-test-hydra-1390747063.cn-north-1.elb.amazonaws.com.cn", hub = "54.223.18.248:1234", dungeon = { url = "10.230.10.205:17777", token = "123456", player_id = -1 } },
}

local RequestServerList = nil
local szServerListURL = nil
local tbRequestServerListTimer
local tbServerListCompleteFunc = nil

local function ShowRetryDialog()
    logwarning("Failed to obtain server list, retry")
    local l10nText = L10N:Format(UITextDef.FAILED_OBTAIN_SERVER_INFO, ERROR_CODE)
    UIUtils.ShowErrorDialog("", l10nText, function()
        UIManager:CloseWnd(UIDef.UI_ERROR_DIALOG, {bNoAnim=true})
        if not tbRequestServerListTimer then
            tbRequestServerListTimer =  DelayTimer:RunNextTick(function()
                tbRequestServerListTimer = nil
                RequestServerList()
            end)
        end
    end)
end

local function PrintServerInfo(tbServerList)
    local szlog = ""
    for i, tbServerData in ipairs(tbServerList) do
        szlog = ""
        szlog = string.format("[ServerList Info] id:%s name:%s hydra:%s hub:%s", tostring(tbServerData.id), tbServerData.name, tbServerData.hydra, tbServerData.hub)
        if tbServerData.dungeon then
            szlog = szlog .. string.format(" dungeon_url:%s", tbServerData.dungeon.url)
        end
        log(szlog)
        GamePlatformMiscLibrary.LogDebug(szlog)
    end
end

RequestServerList = function()
    local bRet = HttpHelper:SendGetRequest(szServerListURL, function(nRetCode, szContent)
        log("ServerListHelper request server list ", nRetCode)
        if nRetCode == HttpHelper.HttpResponseCodes.OK then
            local tbContent = Json.decode(szContent)
            local tbServerList = tbContent.servers

            if(GWithEditor) then
                for i, tbServer in ipairs(Local_Test_Server_List) do
                    table.insert(tbServerList, tbServer)
                end
            end
            GlobalVariableSystem.tbServerList = tbServerList
            PrintServerInfo(tbServerList)
            log("ServerListHelper complete")
            if tbServerListCompleteFunc then
                tbServerListCompleteFunc()
            end
        else
            ShowRetryDialog()
        end
    end)
    if not bRet then
        ShowRetryDialog()
    end
end

function ServerListHelper.RequestServerList(tbCompleteFunc)
    szServerListURL = nil
    tbServerListCompleteFunc = tbCompleteFunc
    szServerListURL = GlobalVariableSystem:GetServerListUrl()
    if(szServerListURL ~= '') then
        szServerListURL = szServerListURL
    else
        szServerListURL = SERVER_LIST_URL
    end
    log("ServerListURL is ", szServerListURL)
    local pGameInstance = GameplayStatics.GetGameInstance(GWorld)
    if pGameInstance and pGameInstance.UpdateUI then
        pGameInstance.UpdateUI:SetMockProgressInfo(85)
    end
    RequestServerList()
end

function ServerListHelper.ClearTimer()
    if tbServerListCompleteFunc then
        DelayTimer:ClearTimer(tbServerListCompleteFunc)
        tbServerListCompleteFunc = nil
    end
end

return ServerListHelper
