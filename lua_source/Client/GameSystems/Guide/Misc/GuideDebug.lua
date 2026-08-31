-----------------------------------------------------
--File Name    : GuideDebug.lua
--Description  : 新手指引打印日志开关
-----------------------------------------------------
local GuideDebug = {}

--member veriable
GuideDebug.DebugLevel =
{
    LOG = 1,
    WARNING = 2,
    ERROR = 3,
}
GuideDebug.bDebugOpen = false
GuideDebug.nLevel = GuideDebug.DebugLevel.LOG

function GuideDebug:OpenDebug(bOpen, nLevel)
    self.bDebugOpen = bOpen
    if(nLevel ~= nil)then
        self.nLevel = nLevel
    end
end

function GuideDebug:DebugLog(szMsg)
    if(not self.bDebugOpen)then
        return
    end
    szMsg = "[Guide] " .. szMsg
    local nLevel = self.nLevel
    if(nLevel == 1)then
        log(szMsg)
    elseif(nLevel == 2)then
        logwarning(szMsg)
    else
        logerror(szMsg)
    end
end

function GuideDebug:Log(szMsg)
    szMsg = "[Guide] " .. szMsg
    log(szMsg)
end

function GuideDebug:LogError(szMsg)
    szMsg = "[Guide] [ERROR] " .. szMsg
    log(szMsg)
end

return GuideDebug
