#pragma once

#include "Templates/UnrealTemplate.h"

#include <string>

extern "C" {
    struct lua_State;
}

namespace google
{
    namespace protobuf
    {
        class Message;
    }
}

class FString;
class FArchive;
class FAsyncWriter;

class ProtobufCodec;

class FAnalyticsApi final : FNoncopyable
{
public:

    static FAnalyticsApi& Instance()
    {
        static FAnalyticsApi instance;
        return instance;
    }

private:

    FAnalyticsApi();
    ~FAnalyticsApi();

public:

    void Init(const FString& logFileName);
    void Uninit();
    void RenameFile(const FString& newFileName);

public:

    void LogEvent(const google::protobuf::Message& e);

private:
    void InitImpl(const FString& logFileName);
    void UninitImpl();

private:

    FArchive* logFile_;
    FAsyncWriter* logWriter_;
    std::string buffer_;
    bool initialized_;
    FString fileName;
};

class FAnalyticsLuaApi final : FNoncopyable
{
public:

    static FAnalyticsLuaApi& Instance()
    {
        static FAnalyticsLuaApi instance;
        return instance;
    }

private:

    FAnalyticsLuaApi();
    ~FAnalyticsLuaApi();

public:

    void Init(const FString& pbFileName);
    void Uninit();

public:

    // Lua API (szEventName, tbEvent)
    static int LogEvent(lua_State* L);

private:

    ProtobufCodec* codec_;
    bool initialized_;
};
