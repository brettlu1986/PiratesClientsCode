local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbyScheduleShow = luaclass("UILobbyScheduleShow", WndBase)
local LobbySystem = require("LobbySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")

local ACTOR_FILE = "Blueprint'/Game/Game/OtherObject/UI/BP_ScheduleChest.BP_ScheduleChest_C'"

function UILobbyScheduleShow:OnLoad()
    
end

function UILobbyScheduleShow:OnShow()
    local LobbySchedule = LobbySystem:GetSub(LobbySubTypeDef.SCHEDULE)
    LobbySchedule:ShowChestAnimation(ACTOR_FILE, self.tbOpenArgs)
end

function UILobbyScheduleShow:OnBindEvent(EventHelper)

end

function UILobbyScheduleShow:OnUnload()

end

function UILobbyScheduleShow:OnDestroy()
end

return UILobbyScheduleShow
