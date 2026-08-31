#include "Analytics.h"

#include "Misc/OutputDeviceFile.h"
#include "Misc/Paths.h"
#include "HAL/FileManager.h"
#include "Serialization/Archive.h"
#include "Containers/UnrealString.h"
#include "Logging/LogMacros.h"

#include "ProtobufCodec.h"
#include "Util/LuaTableRef.h"
#include "Util/MessageLuaUtil.h"

#include <lua.hpp>

#include <google/protobuf/message.h>
#include <google/protobuf/util/json_util.h>

#include <chrono>

DEFINE_LOG_CATEGORY_STATIC(LogAnalytics, Log, All);

static google::protobuf::util::JsonPrintOptions g_JsonPrintOptions;

static void InitJsonPrintOptions()
{
    auto& opt = g_JsonPrintOptions;
    opt.add_whitespace = false;
    opt.always_print_primitive_fields = true;
    opt.always_print_enums_as_ints = false;
    opt.preserve_proto_field_names = true;
}

FORCEINLINE static int64 GetUnixTimestamp()
{
    using namespace std::chrono;
    auto now = system_clock::now().time_since_epoch();
    return duration_cast<seconds>(now).count();
}

static FArchive* CreateLogFileWriter(const FString& logFileName, FString& outFinalFilename)
{
    outFinalFilename = logFileName;
    uint32 writeFlags = FILEWRITE_AllowRead | FILEWRITE_Append;
    auto ar = IFileManager::Get().CreateFileWriter(*logFileName, writeFlags);
    if (!ar)
    {
        FString filenamePart = FPaths::GetBaseFilename(logFileName, false) + "_";
        FString extensionPart = FPaths::GetExtension(logFileName, true);
        uint32 fileIndex = 2;
        do
        {
            // Continue to increment indices until a valid filename is found
            outFinalFilename = filenamePart + FString::FromInt(fileIndex++) + extensionPart;
            ar = IFileManager::Get().CreateFileWriter(*outFinalFilename, writeFlags);
        } while (!ar);
    }
    return ar;
}

FAnalyticsApi::FAnalyticsApi()
    : logFile_(nullptr)
    , logWriter_(nullptr)
    , initialized_(false)
{
}

FAnalyticsApi::~FAnalyticsApi()
{
}

void FAnalyticsApi::Init(const FString& logFileName)
{
    if (!initialized_)
    {
        UE_LOG(LogAnalytics, Display, TEXT("Start analytics with log file: %s"), *logFileName);

        InitImpl(logFileName);
    }
}

void FAnalyticsApi::Uninit()
{
    if (initialized_)
    {
        UE_LOG(LogAnalytics, Display, TEXT("Shutdown analytics"));

        UninitImpl();
    }
}

void FAnalyticsApi::InitImpl(const FString& logFileName)
{
    if (!initialized_)
    {
        InitJsonPrintOptions();

        logFile_ = CreateLogFileWriter(logFileName, fileName);
        logWriter_ = new FAsyncWriter(*logFile_);

        buffer_.reserve(1024);

        initialized_ = true;
    }
}

void FAnalyticsApi::UninitImpl()
{
    if (initialized_)
    {
        delete logWriter_;
        logWriter_ = nullptr;

        delete logFile_;
        logFile_ = nullptr;

        initialized_ = false;
        fileName.Empty();
    }
}

void FAnalyticsApi::RenameFile(const FString& newFileName)
{
    FString oldFileName = fileName;
    UninitImpl();

    IFileManager& FileManager = IFileManager::Get();
    if (FileManager.FileExists(*oldFileName))
    {
        // rename
        FileManager.Move(*newFileName, *oldFileName);
    }
    InitImpl(newFileName);
}

void FAnalyticsApi::LogEvent(const google::protobuf::Message& e)
{
    // TODO: use google::protobuf::io::StringOutputStream to improve performance
    auto timestamp = GetUnixTimestamp();
    buffer_ += std::to_string(timestamp);
    buffer_ += ' ';
    buffer_ += e.GetDescriptor()->name();
    buffer_ += ' ';
    auto ret = google::protobuf::util::MessageToJsonString(e, &buffer_, g_JsonPrintOptions);
    if (ret.ok())
    {
        buffer_ += '\n';
        logWriter_->Serialize(static_cast<void*>(const_cast<char*>(buffer_.data())), buffer_.size());
    }
    else
    {
        UE_LOG(LogAnalytics, Display, TEXT("Failed converting Message to JSON - %d %s"),
            ret.error_code(), UTF8_TO_TCHAR(ret.error_message().as_string().c_str()));
    }
    buffer_.clear();
}

FAnalyticsLuaApi::FAnalyticsLuaApi()
    : codec_(nullptr)
    , initialized_(false)
{
}

FAnalyticsLuaApi::~FAnalyticsLuaApi()
{
}

void FAnalyticsLuaApi::Init(const FString& pbFileName)
{
    if (!initialized_)
    {
        codec_ = new ProtobufCodec();
        codec_->SetProtoFile(pbFileName, google::protobuf::DescriptorPool::generated_pool(), google::protobuf::MessageFactory::generated_factory());

        initialized_ = true;
    }
}

void FAnalyticsLuaApi::Uninit()
{
    if (initialized_)
    {
        delete codec_;
        codec_ = nullptr;

        initialized_ = false;
    }
}

int FAnalyticsLuaApi::LogEvent(lua_State* L)
{
    const int top = lua_gettop(L);
    if (top != 2)
    {
        luaL_error(L, "Expect 2 args, got %d", top);
        return 0;
    }

    auto str = lua_tostring(L, 1);
    if (!str)
    {
        luaL_error(L, "1st arg not string");
        return 0;
    }

    FString eventName(str);
    FLuaTableRef eventTable(L, 2);

    auto codec = FAnalyticsLuaApi::Instance().codec_;
    auto message = FMessageLuaUtil::LuaTableToMessage(codec, eventName, &eventTable);
    if (message)
    {
        FAnalyticsApi::Instance().LogEvent(*message);
        codec->DestroyMessage(message);
    }
    else
    {
        luaL_error(L, "Event %s not found!", str);
    }

    return 0;
}
