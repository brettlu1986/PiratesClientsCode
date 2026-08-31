-- 此处填写仅在DS上ignore的日志匹配规则，支持正则
local LogReportWhiteList_S = {
    'RPCNetworkManager.*outer cannot provide a valid World', -- by songfuhao, DS刚启动的时候，调用Multicast会打印此警告，导致爆栈
    'Dispatch packet failed, no reciever, packetID:  d2c_MulticastServerLog', -- by songfuhao, 编辑器关闭的时候，会因为发送其他日志报此警告，导致爆栈
    'Notification::ProcessReceivedAcks - Missed Acks',  -- by liangcheng, 漏收了ack，估计是丢包了，无所谓
}

local tbWhiteList = require("LogReportWhiteList")
for _,v in ipairs(tbWhiteList) do
    table.insert(LogReportWhiteList_S, v)
end

return LogReportWhiteList_S