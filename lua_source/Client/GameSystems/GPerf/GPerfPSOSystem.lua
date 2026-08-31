-----------------------------------------------------
--File Name    : GPerfPSOSystem.lua
--Author       : WuJizhou
--Create Time  : 12/6/2019, 3:05:20 PM
--Description  : GPerfPSOSystem
-----------------------------------------------------
local GPerfPSOSystem = {}

local StringUtil = require("StringUtil")

GPerfPSOSystem.bEnable = false

local function ParseCommandLineParams(self)
    local szCmdLineStr = KismetSystemLibrary.GetCommandLine()

    if not szCmdLineStr then
        return
    end
    szCmdLineStr = StringUtil.Trim(szCmdLineStr)
    if szCmdLineStr == "" then
        log("GPerfPSOSystem, ParseCommandLineParams, szCmdLineStr is empty ")
        return
    end

    local tbComandParams = StringUtil.Split(szCmdLineStr, "-")
    for _, v in ipairs(tbComandParams) do
        if string.find(v, "logPSO") then
            self.bEnable = true
        end
    end
    log("GPerfPSOSystem, enable : ", self.bEnable)
end

function GPerfPSOSystem:Upload()
    if self.bEnable then
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "gperf psoupload", nil)
    else
        logerror("GPerfPSOSystem, Upload failed, GPerfPSOSystem doesnot enable!")
    end
end

function GPerfPSOSystem:Enable()
    self.bEnable = true
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "gperf psoenable", nil)
end

function GPerfPSOSystem:DeleteAll()
    if self.bEnable then
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "gperf psodeleteall", nil)
    else
        logerror("GPerfPSOSystem, DeleteAll failed, GPerfPSOSystem doesnot enable!")
    end
end

function GPerfPSOSystem:Init()
    ParseCommandLineParams(self)

end

function GPerfPSOSystem:Uninit()

end

return GPerfPSOSystem