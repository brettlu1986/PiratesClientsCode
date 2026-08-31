local luaclass = require("luaclass")
local ProcedureBase = require("ProcedureBase")
local Procedure_ServerList = luaclass("Procedure_ServerList", ProcedureBase)
local ProcedureManager = require("ProcedureManager")
local HttpHelper = require("HttpHelper")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local Json = require("dkjson")
local DelayTimer = require("DelayTimer")
local UIUtils = require("UIUtils")
local UITextDef= require("UITextDef")
local UIDef = require("UIDef")
local UIManager = require("UIManager")

local SERVER_LIST_URL = "https://s3.cn-north-1.amazonaws.com.cn/pirates/dev/servers.json"

local Local_Test_Server_List = {
    { id = 4, name = "本地副本", default = false, hydra = "", hub = "", dungeon = { url = "127.0.0.1:7777", token = "123456", player_id = -1 } },
    { id = 5, name = "内网副本", default = false, hydra = "", hub = "", dungeon = { url = "10.230.10.205:17777", token = "123456", player_id = -1 } },
    { id = 6, name = "tmp", default = false, hydra = "http://pirates-test-hydra-1390747063.cn-north-1.elb.amazonaws.com.cn", hub = "54.223.18.248:1234", dungeon = { url = "10.230.10.205:17777", token = "123456", player_id = -1 } },
}
local RequestServerList = nil

local function ShowRetryDialog(self)
    logwarning("Failed to obtain server list, retry")
    UIUtils.ShowErrorDialog("", UITextDef.FAILED_OBTAIN_SERVER_LIST, function()
        UIManager:CloseWnd(UIDef.UI_ERROR_DIALOG, {bNoAnim=true})
        if not self.RequestServerListTimer then
            self.RequestServerListTimer =  DelayTimer:RunNextTick(function()
                self.RequestServerListTimer = nil
                RequestServerList(self)
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

RequestServerList = function (self)
    local bRet = HttpHelper:SendGetRequest(self.szServerListURL, function(nRetCode, szContent)
        log("Procedure_ServerList request server list ", nRetCode)
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
            log("Procedure_ServerList complete")
            self:Complete(ProcedureManager.Procedure_Login)
            UIManager:CloseWnd(UIDef.UI_LOADING)
        else
            ShowRetryDialog(self)
        end
    end)
    if not bRet then
        ShowRetryDialog(self)
    end
end

function Procedure_ServerList:Begin()
    Procedure_ServerList.super.Begin(self)
    -- -- 重置本地数据存储保存的UserId
	-- ClientShell.GetClient(GWorld):GetSaveGameManager():ResetToDefaultSlot()
    -- ManagerRoot:InitGroup(ManagerGroupDef.nDefaultGroupID, true)
    local szServerListURL = UrlSettings.GetServerListUrl()
    if(szServerListURL and szServerListURL ~= '') then
        self.szServerListURL = szServerListURL
    else
        self.szServerListURL = SERVER_LIST_URL
    end
    log("ServerListURL is ", self.szServerListURL)


    local pGameInstance = GameplayStatics.GetGameInstance(GWorld)
    if pGameInstance and pGameInstance.UpdateUI then
        pGameInstance.UpdateUI:SetMockProgressInfo(85)
    end


    RequestServerList(self)
end


function Procedure_ServerList:End()
	if self.RequestServerListTimer then
		DelayTimer:ClearTimer(self.RequestServerListTimer)
		self.RequestServerListTimer = nil
	end

	Procedure_ServerList.super.End(self)
end

return Procedure_ServerList
