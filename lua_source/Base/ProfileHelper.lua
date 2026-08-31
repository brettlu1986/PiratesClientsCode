local ProfileHelper = {}

local nStartTime = 0

function ProfileHelper:Push()
    nStartTime = getseconds()
end

function ProfileHelper:Pop( szLog )
    log("[ProfileHelper]", szLog, (getseconds() - nStartTime)*1000,"ms")
end

function ProfileHelper:PopAndPush( szLog )
    self:Pop(szLog)
    self:Push()
end

return ProfileHelper
