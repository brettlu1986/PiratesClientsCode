-----------------------------------------------------
--File Name      : UPActivitySevenDay.lua
--Author         : fangjing split from UISchedule  
--original author: lipengyang
--Create Time    : 2019-8-13
--Description    : 公告
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPAnnouncement = luaclass("UPAnnouncement", PrefabBase)
local SaveGameDef = require("SaveGameDef")

local function SetUseDefaultSaveId(bValue)
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    pSaveGameMgr:SetUseDefaultUserId(bValue)
end

function UPAnnouncement:OnLoad()
end

function UPAnnouncement:OnBindEvent(EventHelper)
end

function UPAnnouncement:OnShow()
    SetUseDefaultSaveId(true)
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    local szContent = pSaveGameMgr:GetStringData(SaveGameDef.LOGIN_ANNOUNCEMENT)
    SetUseDefaultSaveId(false)
    self.pWidgetRef.txtMessage:SetText(szContent)
end

return UPAnnouncement