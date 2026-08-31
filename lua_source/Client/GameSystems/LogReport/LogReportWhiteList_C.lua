-- 此处填写仅在Client上ignore的日志匹配规则，支持正则
local LogReportWhiteList_C = {
    -- 杨璟昭会根据这个warning 查哪些shader 没有cache
    "[xsjme]FOpenGLLinkedProgram exceede",
    -- TODO: START TEMP FIX FOR UE-42508  https://issues.unrealengine.com/issue/UE-42508
    "SetActiveLevelCollection attempted to use an out of date",
    --  LogStats 
    "There is no thread with id",   
    --  网络不好，获取不到xxx
    "HTTP request timed out after",
    -- package postload时间过长
    "to ProcessLoadedPackages",
    -- hydra请求超时
    "HTTP request timed out",
    -- hydra返回码错误 
    "invalid HTTP response code received",
    -- hydra请求失败
    "didFailWithError. Http request failed",
    -- ds断开
    "UEngine::BroadcastNetworkFailure",
    "Network Failure: GameNetDriver[ConnectionLost]",
    "GameNetDriver[ConnectionLost]",
    -- 删除角色时出现，不影响
    "UActorChannel::ProcessBunch: ReadContentBlockPayload failed to",
    -- 除了load会造成卡顿外,没有别的影响
    "GetObjectFromNetGUID: Forced blocking load",
    -- 子关卡的worldsetting有几率会创不出来,暂时没影响
    "UActorChannel::ProcessBunch: SerializeNewActor failed to find/spawn actor",
    -- 等梁程处理后打开
    "UActorChannel::ProcessQueuedBunches: Queued bunches for longer than normal",
    -- 等左琨处理后打开
    "Can't Find Animation nTemplateId",
    -- 璟昭处理后打开
    "notified of a touch starting for pointer",
    -- 璟昭处理后打开
    "RenderAssetUpdate is leaking",
    -- 不影响，梁程处理后打开
    "ProcessUntilFinish",
    -- 璟昭处理后打开
    " AsyncLoading QuickReturn AreAllDependentPackagesLoaded"
}

local tbWhiteList = require("LogReportWhiteList")
for _,v in ipairs(tbWhiteList) do
    table.insert(LogReportWhiteList_C, v)
end

return LogReportWhiteList_C