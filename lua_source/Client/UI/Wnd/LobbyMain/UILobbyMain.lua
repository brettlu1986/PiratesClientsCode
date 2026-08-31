-----------------------------------------------------
--File Name    : UILobbyMain.lua
--Create Time  : 2020-04-16
--Description  : 大厅主界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbyMain = luaclass("UILobbyMain", WndBase)

-- import require
local UIUtils = require("UIUtils")

UILobbyMain.tbLogic = nil

local function CreateLogic(self, szLogicName)
    self.tbLogic[szLogicName] = self.UILogicHelper:CreateUILogic(szLogicName)
end

function UILobbyMain:OnLoad()
    self.tbLogic = {}
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bTopWindow = false
    local PrefabHelper = self.PrefabHelper
    PrefabHelper:BindPrefab(pWidgetRef.pbCutoutScreenAdapter)
    PrefabHelper:BindPrefab(pWidgetRef.pbLobbyCurrencyBar)
    CreateLogic(self, "ULLobbyMatchMakingNew")
    CreateLogic(self, "ULLobbyPlayerInfo")
    CreateLogic(self, "ULLobbySeason")
    CreateLogic(self, "ULLobbySchedule")
    CreateLogic(self, "ULLobbyButton")
    CreateLogic(self, "ULLobbyChatQuickView")
    CreateLogic(self, "ULLobbyDrag")
    CreateLogic(self, "ULLobbyVoiceCtrl")
    CreateLogic(self, "ULLobbySurvey")
end

function UILobbyMain:OnShow()
    self:PlayAnimation("anim_LobbyMainIn", 0, 1, EUMGSequencePlayMode.Forward, 1, function()
        self:PlayAnimation("anim_BeginButtonFx_Loop", 0, 0, EUMGSequencePlayMode.Forward, 1)
    end)
end

function UILobbyMain:OnResume()
    UIUtils.BottomMenuSelect(1)
end

function UILobbyMain:OnPause()
    UIUtils.DestroyAllCommonBtnList()
end

return UILobbyMain
