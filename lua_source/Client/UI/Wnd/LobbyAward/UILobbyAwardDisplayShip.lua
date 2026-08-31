-----------------------------------------------------
--File Name    : UILobbyAwardDisplayShip.lua
--Author       : Chen Yixin
--Create Time  : 2019-09-26
--Description  : 大厅道具获得展示UI
-----------------------------------------------------
local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UILobbyAwardDisplayShip = luaclass("UILobbyAwardDisplayShip", WndBase)

UILobbyAwardDisplayShip.tbCurrentOpenWndList = nil
UILobbyAwardDisplayShip.szCurWnd = nil
UILobbyAwardDisplayShip.OwnerSub = nil

UILobbyAwardDisplayShip.tbLastPos = nil
UILobbyAwardDisplayShip.tbCurPos = nil
UILobbyAwardDisplayShip.bIsDrag = false
UILobbyAwardDisplayShip.pActor = nil

UILobbyAwardDisplayShip.tbItemTemplate = nil

-----------------------------------------------------------------------------------------------

function UILobbyAwardDisplayShip:OnLoad()
    self.OwnerSub = self.tbOpenArgs.OwnerSub
    self.ulLobbyAwardDiaplay = self.UILogicHelper:CreateUILogic("ULLobbyAwardDisplay")
end

function UILobbyAwardDisplayShip:CreateActor(tbItemTemplate, fnOnCreateEnd)
    local pActor = self.OwnerSub:CreateShipActor(tbItemTemplate, function()
        if fnOnCreateEnd then
            fnOnCreateEnd()
        end
    end)

    return pActor
end

function UILobbyAwardDisplayShip:UpdateUIDisplay(tbOpenArgs)
    self.ulLobbyAwardDiaplay:UpdateUIDisplay(tbOpenArgs)
end

return UILobbyAwardDisplayShip