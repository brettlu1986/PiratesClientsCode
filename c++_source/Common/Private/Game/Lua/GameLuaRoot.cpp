#include "Game/Lua/GameLuaRoot.h"
#include "Common.h"
#include "U4LuaRoot.h"
#include "U4LuaMisc.hpp"
#include "U4LuaStack.hpp"
#include "Engine.h"
#include "HAL/PlatformFilemanager.h"
#include "Network/ProtobufMessageRef.h"
#include "Util/MessageLuaUtil.h"
#include "Containers/Ticker.h"
#include "Util/LuaTableRef.h"
#include "Shell/EngineExtShell.h"
#include "Misc/GameLimitedTimeTaskManager.h"
#include "Game/GameCommon.h"
#include "Game/Lua/LuaCustomDataWrapper.h"
#include "Game/Lua/LuaCustomPackUtil.h"
#include "HAL/PlatformProcess.h"
#include "Http.h"
#include "Misc/FileHelper.h"
#include "HAL/FileManager.h"
#include "HttpManager.h"
#include "Misc/App.h"

DECLARE_STATS_GROUP(TEXT("GameLua"), STATGROUP_GameLua, STATCAT_Advanced);

#define GET_ROOT(L) FU4LuaHelper::GetValueByClassKey<UGameLuaRoot>(L)

#if WITH_EDITOR
struct FRequireChecker
{
    struct FInfo
    {
        FString Key;
        int Memory;

        FInfo()
            : Memory(0)
        {}
        FInfo(const TCHAR* InKey)
            : Key(InKey)
            , Memory(0)
        {}
        void Print()
        {
            UE_LOG(LogLua, Log, TEXT("Name [%s], Memory [%.2f M]"), *Key, Memory / 1024.f);
        }
    };

    template <typename T>
    struct TMore
    {
        FORCEINLINE bool operator()(const T& Lhs, const T& Rhs) const
        {
            return Lhs > Rhs;
        }
    };

    lua_State* L;
    FInfo* Info;
    FString FileName;

    static TArray<FInfo> FilterInfos;
    static TArray<int> MemStack;
    static TSortedMap<int, FString, FDefaultAllocator, TMore<int> > FileMems;
    static bool Enabled;

    FRequireChecker(lua_State* InL, const FString& InFileName)
        : L(InL)
        , Info(nullptr)
        , FileName(InFileName)
    {
        if (!Enabled)
        {
            return;
        }

        lua_gc(L, LUA_GCCOLLECT, 0);
        int CurrentMemory = lua_gc(L, LUA_GCCOUNT, 0);
        MemStack.Push(CurrentMemory);
    }

    ~FRequireChecker()
    {
        if (!Enabled)
        {
            return;
        }

        for (auto& TempInfo : FilterInfos)
        {
            if (FileName.Contains(TempInfo.Key))
            {
                Info = &TempInfo;
                break;
            }
        }

        int LastMem = MemStack.Pop(false);
        lua_gc(L, LUA_GCCOLLECT, 0);
        int DeltaMem = lua_gc(L, LUA_GCCOUNT, 0) - LastMem;
        for (int ii = 0; ii < MemStack.Num(); ii++)
        {
            MemStack[ii] += DeltaMem;
        }
        if (Info)
        {
            Info->Memory += DeltaMem;
        }
        if (FilterInfos.Num() > 0)
        {
            FilterInfos[0].Memory += DeltaMem;
        }
        FileMems.Emplace(DeltaMem, FileName);
    }

    static void VerifyEnabled(bool bIsDedicatedServer)
    {
        FilterInfos.Empty();
        MemStack.Empty();
        FileMems.Empty();
        Enabled = false;

        const TCHAR* SectionKey = TEXT("LuaRequireChecker");
        FString RunMode;
        if (GConfig->GetString(SectionKey, TEXT("RunMode"), RunMode, GEditorIni))
        {
            Enabled = ((RunMode == TEXT("Client") && !bIsDedicatedServer)
                || (RunMode == TEXT("Server") && bIsDedicatedServer));
            if (Enabled)
            {
                TArray<FString> FiterKeys;
                GConfig->GetArray(SectionKey, TEXT("FiterKeys"), FiterKeys, GEditorIni);
                FilterInfos.Emplace(TEXT("All"));
                for (auto& Key : FiterKeys)
                {
                    FilterInfos.Emplace(*Key);
                }
            }
        }
    }

    static int Print(lua_State* L)
    {
        for (auto& Info : FilterInfos)
        {
            Info.Print();
        }

        int Count = lua_isnumber(L, 1) ? lua_tointeger(L, 1) : 0;
        if (Count)
        {
            for (auto Iter = FRequireChecker::FileMems.CreateIterator(); Iter && Count > 0; ++Iter)
            {
                UE_LOG(LogLua, Log, TEXT("Filter [%s], Memory [%.2f M]"), *Iter.Value(), Iter.Key() / 1024.f);
                --Count;
            }
        }
        return 0;
    }
};

TArray<FRequireChecker::FInfo> FRequireChecker::FilterInfos;
TArray<int> FRequireChecker::MemStack;
TSortedMap<int, FString, FDefaultAllocator, FRequireChecker::TMore<int> > FRequireChecker::FileMems;
bool FRequireChecker::Enabled = false;
#endif

//////////////////////////////////////////////////////////////////////////
struct FGameLuaGlobalFunction
{
    U4L_DEFINE_UNIQUE_KEY(FLuaRequireFunctionKey);

    static void Register(lua_State* L)
    {
        U4L_LUA_STACK_AUTO_RESTORE(L);
        lua_getglobal(L, GLOBAL_TABLE);

        lua_pushstring(L, "require");
        lua_rawget(L, -2);
        lua_rawsetp(L, LUA_REGISTRYINDEX, FLuaRequireFunctionKey::Get());

        RenameFunction(L, "isValid",    "isvalidhandle");
        RenameFunction(L, "enum2int",   "enumtoint");

        // 因为历史原因才这么写，应该写成全局函数
        // string load
        lua_pushstring(L, "");
        lua_getmetatable(L, -1);
        lua_pushstring(L, MTK_INDEX);
        lua_rawget(L, -2);
        lua_pushstring(L, "load");
        lua_pushcfunction(L, &FGameLuaGlobalFunction::LoadObject);
        lua_rawset(L, -3);
        lua_pop(L, 3);

        FU4LuaHelper(L)
            // lua
#if WITH_EDITOR
            .AddCFunction("require",            &FGameLuaGlobalFunction::DebugRequire)
            .AddCFunction("printRequireCheckResult", &FRequireChecker::Print)
#endif
            .AddCFunction("dynamic_require",    &FGameLuaGlobalFunction::DynamicRequire)
            .AddCFunction("loadobject",         &FGameLuaGlobalFunction::LoadObject)
            
            // proto
            .AddCFunction("exposetable",        &FGameLuaGlobalFunction::ExposeTable)
            .AddCFunction("msgtoluatable",      &FGameLuaGlobalFunction::MessageToLuaTable)

            // file operations
            .AddCFunction("getcontentdir",      &FGameLuaGlobalFunction::GetContentDir)
            .AddCFunction("file_exists",        &FGameLuaGlobalFunction::GetFileExists)
            .AddCFunction("getfilestring",      &FGameLuaGlobalFunction::GetFileString)
            .AddCFunction("getabsolutefilestring", &FGameLuaGlobalFunction::GetAbsoluteFileString)
            .AddCFunction("getdirfilepaths",    &FGameLuaGlobalFunction::GetDirFilePaths)
            .AddCFunction("requirewithfullpath", &FGameLuaGlobalFunction::RequireWithFullPath)

            // others
            .AddCFunction("getseconds",         &FGameLuaGlobalFunction::GetSeconds)
            .AddCFunction("getframebegintime",  &FGameLuaGlobalFunction::GetFrameBeginTime)
            .AddCFunction("rts",                &FGameLuaGlobalFunction::RecordTimeStart)
            .AddCFunction("rte",                &FGameLuaGlobalFunction::RecordTimeEnd)
            .AddCFunction("packtowrapper",      &FGameLuaGlobalFunction::PackToDataWrapper)
            .AddCFunction("unpackfromwrapper",  &FGameLuaGlobalFunction::UnpackFromDataWrapper)            
            .AddCFunction("testemptyfunction",  &FGameLuaGlobalFunction::TestEmptyFunction)
            .AddCFunction("statbegin",          &FGameLuaGlobalFunction::StatBegin)
            .AddCFunction("statend",            &FGameLuaGlobalFunction::StatEnd)
            .AddCFunction("printMemoryUsage",   &FGameLuaGlobalFunction::PrintMemoryUsage)
            ;
    }

    static void RenameFunction(lua_State*L, const char* OldName, const char* NewName)
    {
        lua_pushstring(L, OldName);
        lua_rawget(L, -2);
        lua_pushstring(L, NewName);
        lua_rotate(L, -2, 1);
        lua_rawset(L, -3);
    }

    //////////////////////////////////////////////////////////////////////////
    // lua
#if WITH_EDITOR
    static void GetLuaSourceAndLineNumber(lua_State* L, int32 Level, FString& FileName, FString& LineNumber)
    {
        U4L_LUA_STACK_AUTO_RESTORE(L);
        lua_getglobal(L, "debug");              // debug
        lua_getfield(L, -1, "getinfo");         // debug, debug.getinfo
        lua_pushinteger(L, Level);              // debug, debug.getinfo, level
        lua_pcall(L, 1, 1, 0);                  // debug, infotable
        lua_getfield(L, -1, "short_src");       // debug, infotable, short_src
        FileName = UTF8_TO_TCHAR(lua_tostring(L, -1));
        lua_pop(L, 1);                          // debug, infotable
        lua_getfield(L, -1, "currentline");     // debug, infotable, currentline
        LineNumber = UTF8_TO_TCHAR(lua_tostring(L, -1));
        lua_pop(L, 3);                          // 
    }

    static int DebugRequire(lua_State* L)
    {
        FString FileName = TU4LStack<FString>::Get(L, 1);
        int Len = FileName.Len();
        if (Len == 0)
        {
            return 0;
        }

        auto& Searcher = GET_ROOT(L)->GetLib()->GetPathSearcher();        
        if (FileName[Len - 2] != TEXT('_')
            && FileName[Len - 1] != TEXT('S')
            && FileName[Len - 1] != TEXT('C'))
        {
            static const TArray<FString> Suffixs = {
                TEXT("_S"),
                TEXT("_C"),
            };
            auto GetBaseLuaName = [&](FString TempFileName)->FString {
                FString BaseName = FPaths::GetCleanFilename(TempFileName);
                BaseName = BaseName.Mid(0, BaseName.Find(TEXT(".")));
                for (const FString& Suffix : Suffixs)
                {
                    int32 FoundIndex = BaseName.Find(Suffix);
                    if (FoundIndex != INDEX_NONE)
                    {
                        BaseName = BaseName.Mid(0, FoundIndex);
                        break;
                    }
                }
                return BaseName;
            };

            bool bDynamicFileExist = false;
            for (const FString& Suffix : Suffixs)
            {
                FString NewFilename = FileName + Suffix;
                if (Searcher.IsFileExisted(NewFilename))
                {
                    bDynamicFileExist = true;
                    break;
                }
            }

            if (bDynamicFileExist)
            {
                FString Src, Line;
                GetLuaSourceAndLineNumber(L, 2, Src, Line);
               
                FString BaseName = GetBaseLuaName(Src);
                if (BaseName != FileName)
                {
                    UE_LOG(LogLua, Error, TEXT("[%s->line:%s]try to require a dynamic file [%s] with normal require, please use dynamic_require instead."), *Src, *Line, *FileName);
                }
            }
        }

        FRequireChecker Checker(L, FileName);

        lua_pushcfunction(L, &UU4LuaLib::ProcessLuaError);
        int ErrorFuncIndex = lua_gettop(L);
        lua_rawgetp(L, LUA_REGISTRYINDEX, FLuaRequireFunctionKey::Get());
        lua_pushvalue(L, 1);
        if (LUA_OK != lua_pcall(L, 1, 1, ErrorFuncIndex))
        {
            return 0;
        }
        lua_remove(L, ErrorFuncIndex);
        return 1;
    }
#endif
    
    static int DynamicRequire(lua_State* L)
    {
        FString FileName = TU4LStack<FString>::Get(L, 1);
        int Len = FileName.Len();
        if (Len == 0)
        {
            return 0;
        }

        bool bChanged = false;
        if (!FileName.EndsWith(TEXT("_S")) && !FileName.EndsWith(TEXT("_C")))
        {
            if (GET_ROOT(L)->IsDedicatedServer())
            {
                FileName.AppendChars(TEXT("_S"), 2);
            }
            else
            {
                FileName.AppendChars(TEXT("_C"), 2);
            }
            
            auto& Searcher = GET_ROOT(L)->GetLib()->GetPathSearcher();            
            if (Searcher.IsFileExisted(FileName))
            {
                bChanged = true;
            }
        }

#if WITH_EDITOR
        FRequireChecker Checker(L, FileName);
#endif

        lua_pushcfunction(L, &UU4LuaLib::ProcessLuaError);
        int ErrorFuncIndex = lua_gettop(L);
        lua_rawgetp(L, LUA_REGISTRYINDEX, FLuaRequireFunctionKey::Get());
        if (bChanged)
        {
            lua_pushstring(L, TCHAR_TO_UTF8(*FileName));
        }
        else
        {
            lua_pushvalue(L, 1);
        }        
        if (LUA_OK != lua_pcall(L, 1, 1, ErrorFuncIndex))
        {
            return 0;
        }
        lua_remove(L, ErrorFuncIndex);
        return 1;
    }

    // string load
    static int LoadObject(lua_State* L)
    {
        FString Path = TU4LStack<FString>::Get(L, 1);
        if (Path.Len() == 0)
        {
            UU4LuaLib::TriggerLuaError(L, TEXT("LoadAssetFromPath failed, the path is empty."));
            return 1;
        }

        const float PRINT_MAX_TIME = 1.0f;
        double StartTime = FPlatformTime::Seconds();
        UObject* Object = UEngineExtShell::StaticLoadObjectWithoutFlush(Path);
        double DeltaTime = (FPlatformTime::Seconds() - StartTime)*1000.0f;
        if (DeltaTime >= PRINT_MAX_TIME)
        {
            UE_LOG(LogLua, Display, TEXT("Lua load object time %f ms, file: %s"), (float)DeltaTime, *Path);
        }
        if (!lua_isnil(L, 2))
        {
            if (TU4LStack<bool>::Get(L, 2))
            {
                UE_LOG(LogLua, Display, TEXT("Lua load object, file: %s, object address: %p"), *Path, Object);
            }
        }
        TU4LStack<UObject*>::Push(L, Object);
        return 1;        
    }

    //////////////////////////////////////////////////////////////////////////
    // proto
    static int ExposeTable(lua_State* L)
    {
        if (lua_isnil(L, 1))
        {
            lua_pushnil(L);
            return 1;
        }

        ULuaTableRef* TableRefObject = GET_ROOT(L)->TableRef;
        luaL_checktype(L, 1, LUA_TTABLE);
        TableRefObject->TableRef = MakeShareable(new FLuaTableRef(L, 1));
        TU4LStack<UObject*>::Push(L, TableRefObject);
        return 1;
    }

    static int MessageToLuaTable(lua_State* L)
    {        
        UObject* Object = TU4LStack<UObject*>::Get(L, 1);
        if (!Object)
        {
            return 0;
        }
        auto MsgRef = Cast<UProtobufMessageRef>(Object);
        if (!MsgRef)
        {
            return 0;
        }        
        return FMessageLuaUtil::MessageToLuaTable(MsgRef->Message, L);
    }

    //////////////////////////////////////////////////////////////////////////
    // file operations
    static FString GetContentAbsoluteDir()
    {
        static FString CachedDir;
        if (CachedDir.Len() == 0)
        {
            FString BasePath = FPaths::GetPath(FPaths::GetProjectFilePath());
            FPaths::NormalizeFilename(BasePath);
            CachedDir = BasePath / TEXT("Content/");
        }
        return CachedDir;
    }

    static int GetContentDir(lua_State* L)
    {
        TU4LStack<FString>::Push(L, GetContentAbsoluteDir());
        return 1;
    }

    static int GetFileExists(lua_State* L)
    {
        if (lua_isnil(L, 1))
        {
            lua_pushboolean(L, false);
            return 1;
        }

        auto FilePath = TU4LStack<FString>::Get(L, 1);
        FString FileFullPath = GetContentAbsoluteDir() + FilePath;
        auto bFileExists = FPlatformFileManager::Get().GetPlatformFile().FileExists(*FileFullPath);
        lua_pushboolean(L, bFileExists);
        return 1;
    }

    static int DoGetFileString(lua_State* L, const FString& FileFullPath)
    {
        auto FileHandler = FPlatformFileManager::Get().GetPlatformFile().OpenRead(*FileFullPath);
        if (!FileHandler)
        {
            UE_LOG(LogLua, Error, TEXT("GetFileString Open file failed, %s"), *FileFullPath);
            lua_pushboolean(L, false);
            return 1;
        }

        void* Buffer = nullptr;
        auto BufferSize = FileHandler->Size();
        if (BufferSize > 0)
        {
            Buffer = FMemory::Malloc(BufferSize + 1);
            FMemory::Memzero(((uint8*)Buffer + BufferSize), 1);
            FileHandler->Read((uint8*)Buffer, BufferSize);
            delete FileHandler;
        }
        else
        {
            UE_LOG(LogLua, Error, TEXT("GetFileString BufferSize is zero %s"), *FileFullPath);
            lua_pushboolean(L, false);
            return 1;
        }

        static const uint8 bom[] = { 239, 187, 191 };
        static const int bomLen = sizeof(bom) / sizeof(char);
        int offset = 0;
        if ((BufferSize > bomLen) && memcmp(Buffer, bom, bomLen) == 0)
        {
            offset = bomLen;
        }

        lua_pushboolean(L, true);
        lua_pushstring(L, (const char*)((uint8*)Buffer + offset));
        FMemory::Free(Buffer);
        return 2;
    }

    static int GetFileString(lua_State* L)
    {
        if (lua_isnil(L, 1))
        {
            lua_pushboolean(L, false);
            return 1;
        }

        FString FileFullPath = TU4LStack<FString>::Get(L, 1);     
        FileFullPath = GetContentAbsoluteDir() + FileFullPath;
        return DoGetFileString(L, FileFullPath);
    }
    
    static int GetAbsoluteFileString(lua_State* L)
    {
        if (lua_isnil(L, 1))
        {
            lua_pushboolean(L, false);
            return 1;
        }

        FString FileFullPath = TU4LStack<FString>::Get(L, 1);
        return DoGetFileString(L, FileFullPath);
    }

    static int GetDirFilePaths(lua_State* L)
    {
        if (lua_isnil(L, 1) || lua_isnil(L, 2) || lua_isnil(L, 3))
        {
            lua_pushnil(L);
            return 1;
        }

        FString DirPath = TU4LStack<FString>::Get(L, 1);
        bool bRecursiveSearchFolder = TU4LStack<bool>::Get(L, 2);
        FString FileExtension = TU4LStack<FString>::Get(L, 3);
        FString FullDirPath = GetContentAbsoluteDir() + DirPath;

        TArray<FString> FoundFileNames;
        if (bRecursiveSearchFolder)
        {
            IFileManager::Get().FindFilesRecursive(FoundFileNames, *FullDirPath, *FileExtension, true, false);
        }
        else
        {
            IFileManager::Get().FindFiles(FoundFileNames, *FullDirPath, *FileExtension);
            for (int ii = 0; ii < FoundFileNames.Num(); ii++)
            {
                FoundFileNames[ii] = FullDirPath / FoundFileNames[ii];
            }
        }

        if (FoundFileNames.Num() == 0)
        {
            lua_pushnil(L);
            return 1;
        }

        lua_newtable(L);
        int NameCount = FoundFileNames.Num();
        for (int ii = 0; ii < NameCount; ii++)
        {
            lua_pushstring(L, TCHAR_TO_UTF8(*FoundFileNames[ii]));
            lua_rawseti(L, -2, ii + 1);
        }
        return 1;
    }

    static int RequireWithFullPath(lua_State* L)
    {
        int Ret = GetFileString(L);
        if (Ret != 2)
        {
            return Ret;
        }

        FString FileData = TU4LStack<FString>::Get(L, -1);
        bool bLoaded = TU4LStack<bool>::Get(L, -2);
        if (!bLoaded)
        {
            return Ret;
        }

        lua_pop(L, 1);
        if (luaL_dostring(L, TCHAR_TO_UTF8(*FileData)))
        {
            UE_LOG(LogLua, Error, TEXT("RequireWithFullPath failed: %s"), UTF8_TO_TCHAR(lua_tostring(L, -1)));
            lua_pop(L, 2);
            lua_pushboolean(L, false);
            return 1;
        }
        return 2;
    }

    //////////////////////////////////////////////////////////////////////////
    // others
    static int GetSeconds(lua_State* L)
    {
        TU4LStack<double>::Push(L, FPlatformTime::Seconds());
        return 1;
    }

    static int GetFrameBeginTime(lua_State* L)
    {
        TU4LStack<double>::Push(L, FApp::GetCurrentTime());
        return 1;
    }

    static double RecordTime;
    static int RecordTimeStart(lua_State* L)
    {
        RecordTime = FPlatformTime::Seconds();
        return 0;
    }

    static int RecordTimeEnd(lua_State* L)
    {
        float fTime = (float)(FPlatformTime::Seconds() - RecordTime)*1000.0f;
        FString Info;
        if (lua_isstring(L, 1))
        {
            Info = UTF8_TO_TCHAR(lua_tostring(L, 1));
        }
        UE_LOG(LogLua, Log, TEXT("time: %f ms, %s"), fTime, Info.Len() ? *Info : TEXT("No info"));
        return 0;
    }

    static int PackToDataWrapper(lua_State* L)
    {
        auto Wrapper = ULuaCustomDataWrapper::Get();
        Wrapper->ClearError();
        TArray<uint8>& TargetData = Wrapper->RawData;
        TargetData.Empty(TargetData.Max());
        FLuaCustomPackUtil::Pack(L, TargetData);
        TU4LStack<UObject*>::Push(L, Wrapper);
        return 1;
    }


    static int UnpackFromDataWrapper(lua_State* L)
    {        
        UObject* Temp = TU4LStack<UObject*>::Get(L, 1);        
        if (!Temp || !Cast<ULuaCustomDataWrapper>(Temp))
        {
            UU4LuaLib::TriggerLuaError(L, TEXT("UnpackFromDataWrapper failed, the input wrapper is invalid."));
            return 0;
        }

        bool bRet = false;
        auto Wrapper = Cast<ULuaCustomDataWrapper>(Temp);
        Wrapper->ClearError();
        TArray<uint8>& SourceData = Wrapper->RawData;
        int ParamCount = 0;
        bRet = FLuaCustomPackUtil::Unpack(L, SourceData, ParamCount);
        Wrapper->SetError(!bRet);
        return ParamCount;
    }

    static int TestEmptyFunction(lua_State* L)
    {
        return 0;
    }

    static int StatBegin(lua_State* L)
    {
#if STATS
        auto CurrentStatCounter = GET_ROOT(L)->CurrentStatCounter;
        if (CurrentStatCounter.IsValid())
        {
            UE_LOG(LogLua, Error, TEXT("stat command is invalid, last stat is not finished."));
        }
        FName Name = TU4LStack<FName>::Get(L, 1);
        const TStatId StatId = FDynamicStats::CreateStatId<FStatGroup_STATGROUP_GameLua>(Name);
        CurrentStatCounter = MakeShareable(new FScopeCycleCounter(StatId));        
#endif
        return 0;
    }

    static int StatEnd(lua_State* L)
    {
#if STATS
        GET_ROOT(L)->CurrentStatCounter.Reset();
#endif
        return 0;
    }

    static int PrintMemoryUsage(lua_State* L)
    {
        bool IncludeLuaState = lua_isboolean(L, 1) ? lua_toboolean(L, 1) == 1 : true;
        UE_LOG(LogLua, Log, TEXT("%s use memory: %.2f M"), 
            IncludeLuaState ? TEXT("All") : TEXT("Plugin"),
            GET_ROOT(L)->GetMemoryUsage(IncludeLuaState)/1000.0f);
        return 0;
    }
};
double FGameLuaGlobalFunction::RecordTime = 0.0f;


//////////////////////////////////////////////////////////////////////////
UGameLuaRoot::UGameLuaRoot(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , bIsDedicatedServer(false)
    , TableRef(nullptr)
{

}

bool UGameLuaRoot::Init()
{
    if (!Super::Init())
    {
        return false;
    }

    TableRef = NewObject<ULuaTableRef>(this);
    auto L = GetLib()->GetLuaState();
    FU4LuaHelper::SetValueByClassKey<UGameLuaRoot>(L, this);
    FGameLuaGlobalFunction::Register(L);
    OnCurrentWorldChanged(GetWorld());
    SetIsDedicatedServer(bIsDedicatedServer);
    GetLib()->SetGlobalBoolVariable("GEnableNewLua", true);
    GetLib()->SetGlobalBoolVariable("GEnableU4Lua", true);
    return true;
}

void UGameLuaRoot::Uninit()
{
    if (TableRef)
    {
        TableRef->TableRef.Reset();
        TableRef = nullptr;
    }

    Super::Uninit();
}

void UGameLuaRoot::SetIsDedicatedServer(bool bServer)
{
    bIsDedicatedServer = bServer;
    GetLib()->SetGlobalBoolVariable("GIsDedicatedServer", bIsDedicatedServer);

#if WITH_EDITOR
    FRequireChecker::VerifyEnabled(bIsDedicatedServer);
#endif
}

void UGameLuaRoot::OnCurrentWorldChanged(UWorld* CurrentWorld)
{
    GetLib()->SetGlobalObjectVariable("GWorld", CurrentWorld);
}

int UGameLuaRoot::GetMemoryUsage(bool IncludeLuaState)
{
    auto L = GetLib()->GetLuaState();
    return (IncludeLuaState ? lua_gc(L, LUA_GCCOUNT, 0) : 0)
        + (int)(GetLib()->GetCoreMemorySize()/1024.0f);
}

void UGameLuaRoot::CollectGarbage()
{
    auto L = GetLib()->GetLuaState();
    double StartTime = FPlatformTime::Seconds();
    lua_gc(L, LUA_GCCOLLECT, 0);
    UE_LOG(LogLua, Display, TEXT("LuaGC time: %f ms."), (float)((FPlatformTime::Seconds() - StartTime)*1000.0f));
}

void UGameLuaRoot::SetHttpRemoteRepository(const FString& URL)
{
    UE_LOG(LogLua, Log, TEXT("SetHttpRemoteRepository: %s"), *URL);

    const FString RemoteFileListName(TEXT("file_list.txt"));
    const FString LocalTempDownloadDir(TEXT("TempLuaFiles"));
    const FString Extension(TEXT("lua"));

    bool Done = false;
    bool WithError = false;
    auto& HttpModule = FHttpModule::Get();
    check(HttpModule.IsHttpEnabled());

    auto CreateGetRequest = [&](const FString& InURL, TFunction<void(const FString&)> Callback) {
        auto Request = HttpModule.CreateRequest();
        Request->SetVerb(TEXT("Get"));
        Request->SetURL(InURL);
        Request->OnProcessRequestComplete().BindLambda([&, Callback](FHttpRequestPtr Req, FHttpResponsePtr Resp, bool SuccessConnected) {
            int32 RetCode = SuccessConnected ? Resp->GetResponseCode() : -1;
            FString Content = SuccessConnected ? Resp->GetContentAsString() : TEXT("Connect failed.");
            if (RetCode != 200)
            {
                UE_LOG(LogLua, Error, TEXT("Http get request failed, code: %d, info: %s"), RetCode, *Content);
                Done = true;
                WithError = true;
                return;
            }

            Callback(Content);
        });
        if (!Request->ProcessRequest())
        {
            UE_LOG(LogLua, Error, TEXT("FAILED to process get request, url: %s"), *URL);
        }
    };

    FString DownloadDir = FPaths::Combine(FPaths::ProjectPersistentDownloadDir(), LocalTempDownloadDir);
    IFileManager::Get().DeleteDirectory(*DownloadDir, false, true);
    IFileManager::Get().MakeDirectory(*DownloadDir);

    TArray<FString> LocalFiles;
    TSet<FString> NeedDownload;
    FString FileListURL = FString::Printf(TEXT("%s/%s"), *URL, *RemoteFileListName);
    CreateGetRequest(FileListURL, [&](const FString& Content) {        
        TArray<FString> TempRemoteFiles;
        Content.ParseIntoArrayLines(TempRemoteFiles);
        for (FString& File : TempRemoteFiles)
        {
            if (FPaths::GetExtension(File) == Extension)
            {
                NeedDownload.Emplace(File);
            }            
        }

        for(FString File : NeedDownload)
        {
            CreateGetRequest(FString::Printf(TEXT("%s/%s"), *URL, *File), [&, File](const FString& FileContent) {
                FString DownloadedFile = FPaths::Combine(DownloadDir, File);
                bool bResult = FFileHelper::SaveStringToFile(FileContent, *DownloadedFile, FFileHelper::EEncodingOptions::ForceUTF8WithoutBOM);
                if (!bResult)
                {
                    Done = true;
                    WithError = true;
                    UE_LOG(LogLua, Error, TEXT("Download lua file failed, can not write file: %s"), *DownloadedFile);
                    return;
                }

                //UE_LOG(LogLua, Log, TEXT("Download lua file successed: %s"), *DownloadedFile);
                NeedDownload.Remove(File);
                LocalFiles.Emplace(DownloadedFile);
                if (NeedDownload.Num() == 0)
                {
                    Done = true;
                }
            });
        }
    });

    double StartTime = FPlatformTime::Seconds();
    const float DeltaTime = 0.033f;
    while (!Done)
    {
        FPlatformProcess::Sleep(DeltaTime);
        HttpModule.GetHttpManager().Tick(DeltaTime);
    }

    if (!WithError)
    {
        GetLib()->GetPathSearcher().SetExternalFiles(LocalFiles);
        UE_LOG(LogLua, Log, TEXT("Download lua file finished, use time: %.2fs"), (float)(FPlatformTime::Seconds()-StartTime));
    }    
}
