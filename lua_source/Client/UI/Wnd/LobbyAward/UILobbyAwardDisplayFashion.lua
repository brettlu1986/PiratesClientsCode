-----------------------------------------------------
--File Name    : UILobbyAwardDisplayFashion.lua
--Author       : Chen Yixin
--Create Time  : 2019-09-26
--Description  : 大厅道具获得展示UI
-----------------------------------------------------
local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UILobbyAwardDisplayFashion = luaclass("UILobbyAwardDisplayFashion", WndBase)

UILobbyAwardDisplayFashion.tbCurrentOpenWndList = nil
UILobbyAwardDisplayFashion.szCurWnd = nil
UILobbyAwardDisplayFashion.ulLobbyAwardDiaplay = nil

-----------------------------------------------------------------------------------------------

function UILobbyAwardDisplayFashion:OnLoad()
    self.OwnerSub = self.tbOpenArgs.OwnerSub
    self.ulLobbyAwardDiaplay = self.UILogicHelper:CreateUILogic("ULLobbyAwardDisplay")
end

function UILobbyAwardDisplayFashion:OnShow()
end

------------------------
-- life cycle
------------------------
function UILobbyAwardDisplayFashion:CreateActor(tbFashionTemplates, fnOnCreateEnd)
    local pActor = self.OwnerSub:CreateHumanActor(tbFashionTemplates)
    if fnOnCreateEnd then
        fnOnCreateEnd()
    end

    return pActor
end

function UILobbyAwardDisplayFashion:UpdateUIDisplay(tbOpenArgs)
    self.ulLobbyAwardDiaplay:UpdateUIDisplay(tbOpenArgs)
end

return UILobbyAwardDisplayFashion