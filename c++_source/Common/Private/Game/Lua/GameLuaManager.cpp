#include "Game/Lua/GameLuaManager.h"
#include "Common.h"

#if !ENABLE_U4LUA
#include "Engine.h"
#include "LuaRoot.h"
#include "HAL/PlatformFilemanager.h"
#include "UELuaStack.hpp"
#include "UELuaMisc.hpp"
#include "UELuaExternalInterface.h"
#include "UELuaStack.hpp"
#include "Network/ProtobufMessageRef.h"
#include "Util/MessageLuaUtil.h"
#include "Containers/Ticker.h"
#include "Util/LuaTableRef.h"
#include "Shell/EngineExtShell.h"
#include "Misc/GameLimitedTimeTaskManager.h"
#include "Game/GameCommon.h"
#include "Game/Lua/LuaCustomDataWrapper.h"
#include "Game/Lua/LuaCustomPackUtil.h"

DECLARE_STATS_GROUP(TEXT("GameLuaLogic"), STATGROUP_GameLuaLogic, STATCAT_Advanced);
DEFINE_LOG_CATEGORY_STATIC(LogGameLua, Log, All);
DEFINE_LOG_CATEGORY_STATIC(LogGameLuaDebug, Log, All);

struct FLuaInterfaceKey {};
struct FLuaRequireFunctionKey {};
struct FLuaErrorCallbackKey {};

#define GET_LUA_INTERFACE(L) FLuaHelper::GetValueByClassKey<FLuaInterfaceKey, FUELuaExternalInterface>(L)
#define GET_GAMELUA_MANAGER(L) FLuaHelper::GetValueByClassKey<UGameLuaManager>(L)
#define GET_PATH_SEARCHER(L) FLuaHelper::GetValueByClassKey<FGameLuaPathSearcher>(L)

//////////////////////////////////////////////////////////////////////////
struct FGlobalVariable
{
    template <typename T>
    static void SetField(lua_State* L, char const* Name, T Value)
    {
        FStackAutoRestore R(L);
        lua_getglobal(L, GLOBAL_TABLE);
        lua_pushstring(L, Name);
        TStack<T>::Push(L, Value);
        lua_rawset(L, -3);
    }

    //template<>
    //static void SetField<UObject*>(lua_State* L, char const* Name, UObject* Value)
    //{
    //    FStackAutoRestore R(L);
    //    lua_getglobal(L, GLOBAL_TABLE);
    //    lua_pushstring(L, Name);
    //    if (1 == FUELuaExternalInterface::PushObjectToLua(L, Value))
    //    {
    //        lua_rawset(L, -3);
    //    }
    //}

    static void Register(lua_State* L)
    {
#if WITH_EDITOR
        SetField<bool>(L, "GWithEditor", GIsEditor);
#else
        SetField<bool>(L, "GWithEditor", false);
#endif

#if UE_BUILD_SHIPPING || UE_BUILD_TEST
        SetField<bool>(L, "GShippingBuild", true);
#else
        SetField<bool>(L, "GShippingBuild", false);
#endif

        SetField<bool>(L, "GEnableNewLua", true);
    }
};

//////////////////////////////////////////////////////////////////////////
struct FGlobalFunction
{
    static void Register(lua_State* L)
    {
        FStackAutoRestore R(L);
        FUELuaExternalInterface::AddLuaSearcher(L, &FGlobalFunction::LuaSearcher);

        lua_getglobal(L, GLOBAL_TABLE);

        lua_pushstring(L, "require");
        lua_rawget(L, -2);
        lua_rawsetp(L, LUA_REGISTRYINDEX, TLuaUniqueKey<FLuaRequireFunctionKey>::Get());        

        // 因为历史原因才这么写，应该写成全局函数
        // string load
        lua_pushstring(L, "");
        lua_getmetatable(L, -1);
        lua_pushstring(L, MF_INDEX);
        lua_rawget(L, -2);
        lua_pushstring(L, "load");
        lua_pushcfunction(L, &FGlobalFunction::LoadObject);
        lua_rawset(L, -3);
        lua_pop(L, 3);

        FLuaHelper(L)
            // lua
#ifdef WITH_EDITOR
            .AddCFunction("require",            &FGlobalFunction::DebugRequire)
#endif
            .AddCFunction("dynamic_require",    &FGlobalFunction::DynamicRequire)
            .AddCFunction("createdelegate",     &FGlobalFunction::CreateDelegate)            
            .AddCFunction("luaholder",          &FGlobalFunction::CreateLuaHolder)
            .AddCFunction("luagc",              &FGlobalFunction::GC)
            .AddCFunction("setluaerrorcallback", &FGlobalFunction::SetLuaErrorCallback)
            .AddCFunction("printluadebuginfo",  &FGlobalFunction::PrintDebugInfo)
            .AddCFunction("getworld",           &FGlobalFunction::GetWorld)
            .AddCFunction("sethooklogenabled",  &FGlobalFunction::SetHookLogEnabled)
            .AddCFunction("sethandlecounttogc", &FGlobalFunction::SetHandleCountToGC)
            .AddCFunction("isvalidhandle",      &FGlobalFunction::IsValidHandle)
            .AddCFunction("binddelegate",       &FUELuaExternalInterface::BindDelegate)
            .AddCFunction("unbinddelegate",     &FUELuaExternalInterface::UnbindDelegate)
            .AddCFunction("calldelegate",       &FUELuaExternalInterface::CallDelegate)

            // proto
            .AddCFunction("exposetable",        &FGlobalFunction::ExposeTable)
            .AddCFunction("msgtoluatable",      &FGlobalFunction::MessageToLuaTable)

            // file operations
            .AddCFunction("getcontentdir",      &FGlobalFunction::GetContentDir)
            .AddCFunction("file_exists",        &FGlobalFunction::GetFileExists)
            .AddCFunction("getfilestring",      &FGlobalFunction::GetFileString)
            .AddCFunction("getabsolutefilestring", &FGlobalFunction::GetAbsoluteFileString)
            
            .AddCFunction("getdirfilepaths",    &FGlobalFunction::GetDirFilePaths)
            .AddCFunction("requirewithfullpath", &FGlobalFunction::RequireWithFullPath)

            // logs
            .AddCFunction("print",              &FGlobalFunction::Log)
            .AddCFunction("log",                &FGlobalFunction::Log)
            .AddCFunction("logwarning",         &FGlobalFunction::LogWarning)
            .AddCFunction("logerror",           &FGlobalFunction::LogError)
            .AddCFunction("logdebug",           &FGlobalFunction::LogDebug)
            .AddCFunction("printscreen",        &FGlobalFunction::PrintScreen)

            // others
            .AddCFunction("getseconds",         &FGlobalFunction::GetSeconds)
            .AddCFunction("rts",                &FGlobalFunction::RecordTimeStart)
            .AddCFunction("rte",                &FGlobalFunction::RecordTimeEnd)
            .AddCFunction("createtask",         &FGlobalFunction::CreateLimitedTimeTask)
            .AddCFunction("destroytask",        &FGlobalFunction::DestroyLimitedTimeTask)
            .AddCFunction("flushtask",          &FGlobalFunction::FlushLimitedTimeTask)
            .AddCFunction("enumtoint",          &FGlobalFunction::EnumToInt)
            .AddCFunction("isinteger",          &FGlobalFunction::IsInteger)
            .AddCFunction("packtowrapper",      &FGlobalFunction::PackToDataWrapper)
            .AddCFunction("unpackfromwrapper",  &FGlobalFunction::UnpackFromDataWrapper)
            //.AddCFunction("cacheallpropertyandfunctions", &FGlobalFunction::CacheAllPropertyAndFunctions)
            .AddCFunction("testemptyfunction",  &FGlobalFunction::TestEmptyFunction)
            .AddCFunction("statbegin",          &FGlobalFunction::StatBegin)
            .AddCFunction("statend",            &FGlobalFunction::StatEnd)
            ;
    }

    // string load
    static int LoadObject(lua_State* L)
    {
        FString Path = TStack<FString>::Get(L, 1);
        if (Path.Len() == 0)
        {
            FUELuaExternalInterface::TriggerLuaError(L, TEXT("LoadAssetFromPath failed, the path is empty."));
            return 1;
        }

        const float PRINT_MAX_TIME = 1.0f;
        double StartTime = FPlatformTime::Seconds();
        UObject* Object = UEngineExtShell::StaticLoadObjectWithoutFlush(Path);
        double DeltaTime = (FPlatformTime::Seconds() - StartTime)*1000.0f;
        if (DeltaTime >= PRINT_MAX_TIME)
        {
            UE_LOG(LogGameLua, Display, TEXT("Lua load object time %f ms, file: %s"), (float)DeltaTime, *Path);
        }
        return FUELuaExternalInterface::PushObjectToLua(L, Object);
    }

    //////////////////////////////////////////////////////////////////////////
    // lua
    static int LuaSearcher(lua_State* L)
    {
        FString ScriptName = TStack<FString>::Get(L, 1);
        FGameLuaPathSearcher* Searcher = GET_PATH_SEARCHER(L);
        check(Searcher);

        FString ScriptFilePath = Searcher->FindFullPath(ScriptName);
        if (ScriptFilePath.Len() == 0)
        {
            UE_LOG(LogGameLua, Display, TEXT("require '%s' is not found in project script paths."), *ScriptName);
            return 0;
        }

        auto FileHandler = FPlatformFileManager::Get().GetPlatformFile().OpenRead(*ScriptFilePath);
        if (!FileHandler)
        {
            UE_LOG(LogGameLua, Error, TEXT("Error opening file '%s'."), *ScriptFilePath);
            return 0;
        }

        void *Buffer = nullptr;
        auto BufferSize = FileHandler->Size();
        if (BufferSize > 0)
        {
            Buffer = FMemory::Malloc(BufferSize);
            FileHandler->Read((uint8*)Buffer, BufferSize);
            delete FileHandler;
        }
        else
        {
            return 0;
        }
        static const FString ScriptFolderName(TEXT("Scripts"));
        static const int Offset = ScriptFolderName.Len();
        luaL_loadbuffer(L, (const char*)Buffer, BufferSize, TCHAR_TO_UTF8(*ScriptFilePath.Mid(ScriptFilePath.Find(ScriptFolderName) + Offset)));
        FMemory::Free(Buffer);
        return 1;
    }

#ifdef WITH_EDITOR

    static void GetLuaSourceAndLineNumber(lua_State* L, int32 Level, FString& FileName, FString& LineNumber)
    {
        FStackAutoRestore R(L);
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
        FString FileName = TStack<FString>::Get(L, 1);
        int Len = FileName.Len();
        if (Len == 0)
        {
            return 0;
        }


        FGameLuaPathSearcher* Searcher = GET_PATH_SEARCHER(L);
        check(Searcher);
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
                if (Searcher->IsFileExisted(NewFilename))
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
                    UE_LOG(LogGameLua, Error, TEXT("[%s->line:%s]try to require a dynamic file [%s] with normal require, please use dynamic_require instead."), *Src, *Line, *FileName);
                }
            }
        }
        lua_pushcfunction(L, &FUELuaExternalInterface::ProcessLuaError);
        int ErrorFuncIndex = lua_gettop(L);
        lua_rawgetp(L, LUA_REGISTRYINDEX, TLuaUniqueKey<FLuaRequireFunctionKey>::Get());
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
        FString FileName = TStack<FString>::Get(L, 1);
        int Len = FileName.Len();
        if (Len == 0)
        {
            return 0;
        }

        bool bChanged = false;
        if (!FileName.EndsWith(TEXT("_S")) && !FileName.EndsWith(TEXT("_C")))
        {
            if (GET_GAMELUA_MANAGER(L)->IsDedicatedServer())
            {
                FileName.AppendChars(TEXT("_S"), 2);
            }
            else
            {
                FileName.AppendChars(TEXT("_C"), 2);
            }
            
            FGameLuaPathSearcher* Searcher = GET_PATH_SEARCHER(L);
            check(Searcher);
            if (Searcher->IsFileExisted(FileName))
            {
                bChanged = true;
            }
        }

        lua_pushcfunction(L, &FUELuaExternalInterface::ProcessLuaError);
        int ErrorFuncIndex = lua_gettop(L);
        lua_rawgetp(L, LUA_REGISTRYINDEX, TLuaUniqueKey<FLuaRequireFunctionKey>::Get());
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

    static int CreateDelegate(lua_State* L)
    {
        return GET_LUA_INTERFACE(L)->CreateDelegate(1, 2, 3);
    }

    static int CreateLuaHolder(lua_State* L)
    {
        return GET_LUA_INTERFACE(L)->CreateLuaHolder(1);
    }

    static int GC(lua_State* L)
    {
        double StartTime = FPlatformTime::Seconds();
        lua_gc(L, LUA_GCCOLLECT, 0);
        UE_LOG(LogGameLua, Display, TEXT("LuaGC time: %f ms."), (float)((FPlatformTime::Seconds() - StartTime)*1000.0f));
        return 0;
    }

    static int SetLuaErrorCallback(lua_State* L)
    {
        check(lua_isfunction(L, 1));
        lua_rawsetp(L, LUA_REGISTRYINDEX, TLuaUniqueKey<FLuaErrorCallbackKey>::Get());
        return 0;
    }

    static void OnLuaError(lua_State* L, const TCHAR* ShortMessage,
        const TCHAR* FullMessage, const TCHAR* Stack)
    {
        UE_LOG(LogGameLua, Error, TEXT("%s\n"), FullMessage);
        auto Top = lua_gettop(L);
        if (lua_rawgetp(L, LUA_REGISTRYINDEX, TLuaUniqueKey<FLuaErrorCallbackKey>::Get()) == LUA_TFUNCTION)
        {
            lua_pushstring(L, "LuaError");
            lua_pushstring(L, TCHAR_TO_UTF8(ShortMessage));
            lua_pushstring(L, TCHAR_TO_UTF8(Stack));
            lua_pcall(L, 3, 0, 0);
        }
        lua_settop(L, Top);
    }

    static int PrintDebugInfo(lua_State* L)
    {
        bool bWithDetail = TStack<bool>::Get(L, 1);
        TArray<FString> Infos;
        GET_LUA_INTERFACE(L)->GetDebugInfo(bWithDetail, Infos);
        for (auto& Info : Infos)
        {
            UE_LOG(LogGameLua, Display, TEXT("%s"), *Info);
        }
        UE_LOG(LogGameLua, Display, TEXT("Lua used memory: %.3f M"), lua_gc(L, LUA_GCCOUNT, 0) / 1024.0f);
        return 0;
    }

    static int GetWorld(lua_State* L)
    {
        UWorld* World = GET_GAMELUA_MANAGER(L)->GetWorld();
        return GET_LUA_INTERFACE(L)->PushObjectToLua(L, World);        
    }

    static int SetHookLogEnabled(lua_State* L)
    {
        check(lua_isboolean(L, 1));
        GET_GAMELUA_MANAGER(L)->SetHookLogEnabled(lua_toboolean(L, 1) != 0);
        return 0;
    }

    static int SetHandleCountToGC(lua_State* L)
    {
        check(lua_isinteger(L, 1));
        GET_GAMELUA_MANAGER(L)->SetHandleCountToGC(lua_tointeger(L, 1));
        return 0;
    }

    static int IsValidHandle(lua_State* L)
    {
        bool bValid = false;
        if (lua_isuserdata(L, 1))
        {
            TUEObjectHandle Handle = TStack<TUEObjectHandle>::Get(L, 1);
            bValid = GET_LUA_INTERFACE(L)->IsValid(Handle);
        }
        lua_pushboolean(L, bValid ? 1 : 0);
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

        ULuaTableRef* TableRefObject = GET_GAMELUA_MANAGER(L)->TableRef;
        luaL_checktype(L, 1, LUA_TTABLE);
        TableRefObject->TableRef = MakeShareable(new FLuaTableRef(L, 1));
        return FUELuaExternalInterface::PushObjectToLua(L, TableRefObject);
    }

    static int MessageToLuaTable(lua_State* L)
    {
        UObject* Object = nullptr;
        if (!FUELuaExternalInterface::GetObjectFromLua(L, 1, Object))
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
        TStack<FString>::Push(L, GetContentAbsoluteDir());
        return 1;
    }

    static int GetFileExists(lua_State* L)
    {
        if (lua_isnil(L, 1))
        {
            lua_pushboolean(L, false);
            return 1;
        }

        auto FilePath = TStack<FString>::Get(L, 1);
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
            UE_LOG(LogGameLua, Error, TEXT("GetFileString Open file failed, %s"), *FileFullPath);
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
            UE_LOG(LogGameLua, Error, TEXT("GetFileString BufferSize is zero %s"), *FileFullPath);
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

        FString FileFullPath = TStack<FString>::Get(L, 1);     
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

        FString FileFullPath = TStack<FString>::Get(L, 1);
        return DoGetFileString(L, FileFullPath);
    }

    static int GetDirFilePaths(lua_State* L)
    {
        if (lua_isnil(L, 1) || lua_isnil(L, 2) || lua_isnil(L, 3))
        {
            lua_pushnil(L);
            return 1;
        }

        FString DirPath = TStack<FString>::Get(L, 1);
        bool bRecursiveSearchFolder = TStack<bool>::Get(L, 2);
        FString FileExtension = TStack<FString>::Get(L, 3);
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

        FString FileData = TStack<FString>::Get(L, -1);
        bool bLoaded = TStack<bool>::Get(L, -2);
        if (!bLoaded)
        {
            return Ret;
        }

        lua_pop(L, 1);
        if (luaL_dostring(L, TCHAR_TO_UTF8(*FileData)))
        {
            UE_LOG(LogGameLua, Error, TEXT("RequireWithFullPath failed: %s"), UTF8_TO_TCHAR(lua_tostring(L, -1)));
            lua_pop(L, 2);
            lua_pushboolean(L, false);
            return 1;
        }
        return 2;
    }

    //////////////////////////////////////////////////////////////////////////
    // logs
    static void GetWorldDesc(lua_State* L, FString& Out)
    {
        UWorld* World = GET_LUA_INTERFACE(L)->GetWorld();
        if (!IsValid(GEngine) || !IsValid(World))
        {
            Out = TEXT("[World NULL]: ");
        }
        else
        {
            auto Mode = GEngine->GetNetMode(World);
            Out = (Mode == NM_Client) ? TEXT("[Client]: ")
                : (Mode == NM_ListenServer) ? TEXT("[ListenServer]: ")
                : (Mode == NM_DedicatedServer) ? TEXT("[DedicatedServer]: ")
                : TEXT("[Standalone]: ");
        }
    }
    static void GetLogString(lua_State* L, FString& Out)
    {
        FStackAutoRestore R(L);
        
        int ArgCount = lua_gettop(L);
        lua_getglobal(L, "tostring");
        int ToStringFunctionIndex = lua_gettop(L);
        for (int ii=1; ii<=ArgCount; ii++)
        {
            if (lua_isstring(L, ii))
            {
                Out.Append(UTF8_TO_TCHAR(lua_tostring(L, ii)));                
            }
            else
            {
                lua_pushvalue(L, ToStringFunctionIndex);
                lua_pushvalue(L, ii);
                lua_pcall(L, 1, 1, 0);
                Out.Append(UTF8_TO_TCHAR(lua_tostring(L, -1)));
                lua_pop(L, 1);
            }
            Out.Append(TEXT(" "));
        }
    }

#define UELOG_MACRO(Category, Verbosity) \
    FString Desc; \
    GetWorldDesc(L, Desc); \
    GetLogString(L, Desc); \
    UE_LOG(Category, Verbosity, TEXT("%s"), *Desc);\
    return 0;

    static int Log(lua_State* L)
    {
        UELOG_MACRO(LogGameLua, Display);
    }

    static int LogWarning(lua_State* L)
    {
        UELOG_MACRO(LogGameLua, Warning);
    }

    static int LogError(lua_State* L)
    {
        UELOG_MACRO(LogGameLua, Error);
    }

    static int LogDebug(lua_State* L)
    {
#if !UE_BUILD_SHIPPING
#if WITH_EDITOR
		UELOG_MACRO(LogGameLuaDebug, Error);
#else
		UELOG_MACRO(LogGameLuaDebug, Display);
#endif
#endif
        return 0;
	}
#undef UELOG_MACRO

    static int PrintScreen(lua_State* L)
    {
        FString Desc;
        GetWorldDesc(L, Desc);
        GetLogString(L, Desc);
        GEngine->AddOnScreenDebugMessage(-1, 10.0f, FColor::Red, Desc);
        return 0;
    }

    //////////////////////////////////////////////////////////////////////////
    // others
    static int GetSeconds(lua_State* L)
    {
        TStack<double>::Push(L, FPlatformTime::Seconds());
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
        UE_LOG(LogGameLua, Log, TEXT("time: %f ms, %s"), fTime, Info.Len() ? *Info : TEXT("No info"));
        return 0;
    }

    static int CreateLimitedTimeTask(lua_State* TempL)
    {
        // param: LuaFunciton, szInfo, nPriority
        class FLuaLimitedTimeTask : public FGameLimitedTimeTask
        {
        public:
            FLuaLimitedTimeTask(UGameLuaManager* InLuaManager, int LuaFunctionIndex, const FString& InInfo)
                : LuaManager(InLuaManager)                
                , Info(InInfo)
                , LuaFunctionRef(-1)
            {
                auto L = LuaManager->GetLuaState();
                check(L);
                check(lua_isfunction(L, LuaFunctionIndex));
                lua_pushvalue(L, LuaFunctionIndex);
                VerifyTable();
                lua_insert(L, -2);
                LuaFunctionRef = luaL_ref(L, -2);
                check(LuaFunctionRef > 0);
                lua_pop(L, 1);
            }

            virtual ~FLuaLimitedTimeTask()
            {
                Cancel();
            }

            bool VerifyTable()
            {
                if (!LuaManager.IsValid())
                {
                    return false;
                }

                auto L = LuaManager->GetLuaState();
                if (!L)
                {
                    return false;
                }

                lua_rawgetp(L, LUA_REGISTRYINDEX, TLuaUniqueKey<FLuaLimitedTimeTask>::Get());
                if (lua_isnil(L, -1))
                {
                    lua_pop(L, 1);
                    lua_newtable(L);
                    lua_pushvalue(L, -1);
                    lua_rawsetp(L, LUA_REGISTRYINDEX, TLuaUniqueKey<FLuaLimitedTimeTask>::Get());
                }
                return true;
            }

            virtual void Process() override
            {                
                if (!VerifyTable())
                {
                    return;
                }

                auto L = LuaManager->GetLuaState();
                check(L);
                auto SavedIndex = lua_gettop(L)-1;
                lua_pushcfunction(L, &FUELuaExternalInterface::ProcessLuaError);
                auto HandleFunctionIndex = lua_gettop(L);

                lua_rawgeti(L, -2, LuaFunctionRef);                
                luaL_unref(L, SavedIndex+1, LuaFunctionRef);
                check(lua_isfunction(L, -1));
                int RetCode = lua_pcall(L, 0, 0, HandleFunctionIndex);
                if (RetCode != LUA_OK)
                {
                    const char *ErrMsg = lua_tostring(L, -1);
                    FString ErrorMessage = UTF8_TO_TCHAR(ErrMsg);
                    UE_LOG(LogGameLua, Error, TEXT("Script internal error: %s"), *ErrorMessage);
                    lua_pop(L, 1);
                }
                lua_settop(L, SavedIndex);
                LuaFunctionRef = -1;
            }

            virtual void Cancel() override
            {
                if (!VerifyTable() || LuaFunctionRef < 0)
                {
                    return;
                }

                auto L = LuaManager->GetLuaState();
                check(L);
                luaL_unref(L, -1, LuaFunctionRef);
                lua_pop(L, 1);
                LuaFunctionRef = -1;
            }

            virtual const FString GetInfo() const override
            {
                return FString::Printf(TEXT("Lua task, info: %s"), *Info);
            }

        private:
            TWeakObjectPtr<UGameLuaManager> LuaManager;
            FString Info;
            int LuaFunctionRef;
        };

        auto L = TempL;
        int nRetCount = 0;
        auto GameLuaManager = FLuaHelper::GetValueByClassKey<UGameLuaManager>(L);
        auto GameCommon = Cast<UGameCommon>(GameLuaManager->GetOuter());
        if (GameCommon && GameCommon->GetTaskManager())
        {
            check(lua_isfunction(L, -3));
            FString Info = TStack<FString>::Get(L, -2);
            int Priority = TStack<int>::Get(L, -1);
            int Handle = GameCommon->GetTaskManager()->AddTask(
                new FLuaLimitedTimeTask(GameLuaManager, -3, Info), Priority, true);
            lua_pushinteger(L, Handle);
            nRetCount = 1;
        }

        return nRetCount;
    }

    static int DestroyLimitedTimeTask(lua_State* L)
    {
        int Handle = TStack<int>::Get(L, -1);
        auto GameLuaManager = FLuaHelper::GetValueByClassKey<UGameLuaManager>(L);
        auto GameCommon = Cast<UGameCommon>(GameLuaManager->GetOuter());
        if (GameCommon && GameCommon->GetTaskManager())
        {
            GameCommon->GetTaskManager()->RemoveTask(Handle);
        }
        return 0;
    }

    static int FlushLimitedTimeTask(lua_State* L)
    {
        int Handle = TStack<int>::Get(L, -1);
        auto GameLuaManager = FLuaHelper::GetValueByClassKey<UGameLuaManager>(L);
        auto GameCommon = Cast<UGameCommon>(GameLuaManager->GetOuter());
        if (GameCommon && GameCommon->GetTaskManager())
        {
            GameCommon->GetTaskManager()->FlushTask(Handle);
        }
        return 0;
    }

    static int EnumToInt(lua_State* L)
    {        
        int Value = GET_LUA_INTERFACE(L)->EnumToInt(-1);
        lua_pushinteger(L, Value);
        return 1;
    }

    static int IsInteger(lua_State* L)
    {
        auto bRet = lua_isinteger(L, -1);
        lua_pushboolean(L, bRet);
        return bRet;
    }

    static int PackToDataWrapper(lua_State* L)
    {
        auto Wrapper = ULuaCustomDataWrapper::Get();
        Wrapper->ClearError();
        TArray<uint8>& TargetData = Wrapper->RawData;
        TargetData.Empty(TargetData.Max());
        FLuaCustomPackUtil::Pack(L, TargetData);
        FUELuaExternalInterface::PushObjectToLua(L, Wrapper);
        return 1;
    }


    static int UnpackFromDataWrapper(lua_State* L)
    {        
        UObject* Temp = nullptr;        
        if (!FUELuaExternalInterface::GetObjectFromLua(L, -1, Temp) || !Cast<ULuaCustomDataWrapper>(Temp))
        {
            FUELuaExternalInterface::TriggerLuaError(L, TEXT("UnpackFromDataWrapper failed, the input wrapper is invalid."));
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
        UGameLuaManager* GameLuaManager = FLuaHelper::GetValueByClassKey<UGameLuaManager>(L);
        if (GameLuaManager->CurrentStatCounter.IsValid())
        {
            UE_LOG(LogGameLua, Error, TEXT("stat command is invalid, last stat is not finished."));
        }
        FName Name = TStack<FName>::Get(L, 1);
        const TStatId StatId = FDynamicStats::CreateStatId<FStatGroup_STATGROUP_GameLuaLogic>(Name);
        GameLuaManager->CurrentStatCounter = MakeShareable(new FScopeCycleCounter(StatId));        
#endif
        return 0;
    }

    static int StatEnd(lua_State* L)
    {
#if STATS
        UGameLuaManager* GameLuaManager = FLuaHelper::GetValueByClassKey<UGameLuaManager>(L);
        GameLuaManager->CurrentStatCounter.Reset();        
#endif
        return 0;
    }

    //static int CacheAllPropertyAndFunctions(lua_State* L)
    //{
    //    FString Name = TStack<FString>::Get(L, 1);
    //    FString PrefixName = TStack<FString>::Get(L, 2);
    //    UStruct* Finded = Cast<UStruct>(StaticFindObject(UObject::StaticClass(), ANY_PACKAGE, *Name));
    //    if (Finded)
    //    {
    //        GET_LUA_INTERFACE(L)->CacheAllPropertyAndFunctions(Finded);
    //    }

    //    return 0;
    //}

    static bool DoFile(lua_State* L, const FString& ScriptName, FString& ErrorMessage)
    {
        FGameLuaPathSearcher* Searcher = FLuaHelper::GetValueByClassKey<FGameLuaPathSearcher>(L);
        check(Searcher);
        FString ScriptFilePath = Searcher->FindFullPath(ScriptName);
        if (ScriptFilePath.Len() == 0)
        {
            ErrorMessage = FString::Printf(TEXT("Get script file path failed: %s"), *ScriptName);
            UE_LOG(LogGameLua, Warning, TEXT("%s"), *ErrorMessage);
            return false;
        }

        bool Ret = true;
        auto FileHandler = FPlatformFileManager::Get().GetPlatformFile().OpenRead(*ScriptFilePath);
        if (!FileHandler)
        {
            ErrorMessage = FString::Printf(TEXT("Error opening file '%s'."), *ScriptFilePath);
            UE_LOG(LogGameLua, Warning, TEXT("%s"), *ErrorMessage);
            return false;
        }
        void *Buffer = nullptr;
        uint32	BufferSize = FileHandler->Size();
        if (BufferSize > 0)
        {
            Buffer = FMemory::Malloc(BufferSize);
            FileHandler->Read((uint8*)Buffer, BufferSize);
            delete FileHandler;
        }
        else
        {
            return true;
        }

        static const FString ScriptFolderName(TEXT("Scripts"));
        static const int Offset = ScriptFolderName.Len();
        lua_pushcfunction(L, &FUELuaExternalInterface::ProcessLuaError);
        auto HandleFunctionIndex = lua_gettop(L);
        luaL_loadbuffer(L, (const char*)Buffer, BufferSize, TCHAR_TO_UTF8(*ScriptFilePath.Mid(ScriptFilePath.Find(ScriptFolderName) + Offset)));
        int RetCode = lua_pcall(L, 0, LUA_MULTRET, HandleFunctionIndex);

        if (RetCode != LUA_OK)
        {
            const char *ErrMsg = lua_tostring(L, -1);
            ErrorMessage = UTF8_TO_TCHAR(ErrMsg);
            UE_LOG(LogGameLua, Error, TEXT("Script internal error: %s"), *ErrorMessage);
            lua_pop(L, 1);
            Ret = false;
        }
        FMemory::Free(Buffer);
        return Ret;
    }

    static bool DoString(lua_State* L, const FString& String, FString& ErrorMessage)
    {
        bool Success = true;
        if (luaL_dostring(L, TCHAR_TO_UTF8(*String))) {
            Success = false;
            ErrorMessage = UTF8_TO_TCHAR(lua_tostring(L, -1));
            lua_pop(L, 1);
        }
        return Success;
    }

    static void RegisterGlobalFunction(lua_State* L, const char* Name, lua_CFunction Function)
    {
        lua_getglobal(L, GLOBAL_TABLE);
        lua_pushstring(L, Name);
        lua_pushcfunction(L, Function);
        lua_rawset(L, -3);
        lua_pop(L, 1);
    }
};
double FGlobalFunction::RecordTime = 0.0f;


//////////////////////////////////////////////////////////////////////////
class FGameLuaHook : public FUELuaHook
{
public:
    FGameLuaHook(UGameLuaManager* Manager)
        : StackIndex(1)
        , EnableLog(false)
        , LuaManager(Manager)
    {

    }

    virtual void OnPreCallUEFunction(lua_State* L, UFunction* Function, int ArgCount) override
    {
        if (EnableLog)
        {
            check(Function);
            UE_LOG(LogGameLua, Warning, TEXT("Stack[%d] CallUEFunction info: %s"),
                StackIndex, *Function->GetFullName());
            ++StackIndex;
        }
    }

    virtual void OnPostCallUEFunction(lua_State* L, UFunction* Function, int RetCount) override
    {
        if (EnableLog)
        {
            --StackIndex;
            check(StackIndex >= 0);
        }
    }

    virtual void OnPreCallLuaFunction(lua_State* L, UFunction* SignatureFunction,
        const TCHAR* DebugInfo, int ArgCount) override
    {
        if (EnableLog)
        {
            check(SignatureFunction);
            UE_LOG(LogGameLua, Warning, TEXT("Stack[%d] CallLuaFunction info: %s"),
                StackIndex, DebugInfo);
            ++StackIndex;
        }
    }

    virtual void OnPostCallLuaFunction(lua_State* L, UFunction* SignatureFunction,
        const TCHAR* DebugInfo, int RetCount) override
    {
        if (EnableLog)
        {
            --StackIndex;
            check(StackIndex >= 0);
        }
    }

    virtual void OnReachedHandleCount(int CurrentHandleCount, int MaxCountToGC) override
    {
        //UE_LOG(LogGameLua, Warning, TEXT("Reached handle count: %d, max count: %d, start lua collect garbage in steps."),
        //    CurrentHandleCount, MaxCountToGC);
        LuaManager->StartLuaCollectGarbageByStep();
    }

    void SetLogEnabled(bool bEnabled)
    {
        EnableLog = bEnabled;
    }

private:
    int StackIndex;
    bool EnableLog;
    UGameLuaManager* LuaManager;
};

//////////////////////////////////////////////////////////////////////////
UGameLuaManager::UGameLuaManager(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
    , bIsDedicatedServer(false)
    , LuaHook(nullptr)
    , LuaRoot(nullptr)
    , TableRef(nullptr)
    , HandleCountToTriggerLuaGC(4096)
    , LuaGCStepSize(1024) // 1m
    , LuaGCStepTime(0.3f)
{

}

bool UGameLuaManager::Init(const FString& ScriptRootPath, const FString& PathCacheFile)
{
    LuaRoot = NewObject<ULuaRoot>(this);
    TableRef = NewObject<ULuaTableRef>(this);
    if (!LuaRoot->Init())
    {
        UE_LOG(LogGameLua, Fatal, TEXT("LuaRoot init failed."));
        return false;
    }

    PathSearcher.Init(ScriptRootPath, LuaFileExtension, PathCacheFile);
    auto LuaInterface = LuaRoot->GetExtenalInterface();
    lua_State* L = LuaInterface->GetLuaState();
    FLuaHelper::SetValueByClassKey<UGameLuaManager>(L, this);
    FLuaHelper::SetValueByClassKey<FLuaInterfaceKey>(L, LuaInterface);
    FLuaHelper::SetValueByClassKey<FGameLuaPathSearcher>(L, &PathSearcher);
    OnWorldChanged(GetWorld());
    LuaInterface->SetLuaErrorCallback(&FGlobalFunction::OnLuaError);
    LuaInterface->SetHandleCountToTriggerHook(HandleCountToTriggerLuaGC);
    SetHookEnabled(true);

    FGlobalVariable::Register(L);
    FGlobalFunction::Register(L);
    return true;
}

void UGameLuaManager::Uninit()
{
    if (LuaRoot)
    {
        if (TableRef)
        {
            TableRef->TableRef.Reset();
            TableRef = nullptr;
        }        
        StopLuaCollectGarbageByStep();
        SetHookEnabled(false);
        LuaRoot->Uninit();
        LuaRoot = nullptr;
    }
    PathSearcher.Uninit();
}

void UGameLuaManager::RegistGlobalFunction(const char* Name, lua_CFunction Function)
{
    FGlobalFunction::RegisterGlobalFunction(GetLuaState(), Name, Function);
}

int UGameLuaManager::GetMemoryUsage()
{
	auto L = GetLuaState();
	return L ? lua_gc(L, LUA_GCCOUNT, 0) : 0;
}

void UGameLuaManager::SetIsDedicatedServer(bool bServer)
{
    bIsDedicatedServer = bServer;
    SetGlobalBoolVariable("GIsDedicatedServer", bIsDedicatedServer);
}

bool UGameLuaManager::DoFile(const FString& ScriptName)
{
    FString Error;
    return DoFile(ScriptName, Error);    
}

bool UGameLuaManager::DoFile(const FString& ScriptName, FString& ErrorMessage)
{
    return FGlobalFunction::DoFile(GetLuaState(), ScriptName, ErrorMessage);
}

bool UGameLuaManager::DoString(const FString& String, FString& OutReturnValue, FString& OutErrorMessage)
{
    auto L = GetLuaState();
    if (!FGlobalFunction::DoString(L, String, OutErrorMessage))
    {
        return false;
    }

    if (lua_isstring(L, -1))
    {
        OutReturnValue = UTF8_TO_TCHAR(lua_tostring(L, -1));
    }
    lua_pop(L, 1);
    return true;
}

void UGameLuaManager::CollectGarbage()
{
    FGlobalFunction::GC(GetLuaState());
}

void UGameLuaManager::AddSearchPath(const FString& Path)
{
    PathSearcher.AddPath(Path);
}

lua_State* UGameLuaManager::GetLuaState()
{
    return LuaRoot->GetExtenalInterface()->GetLuaState();
}

void UGameLuaManager::OnWorldChanged(UWorld* NewWorld)
{
    SetGlobalObjectVariable("GWorld", NewWorld);
}

void UGameLuaManager::SetGlobalObjectVariable(const char* Name, UObject* Value)
{
    //FGlobalVariable::SetField<UObject*>(GetLuaState(), Name, Value);

    lua_State* L = GetLuaState();
    FStackAutoRestore R(L);
    lua_getglobal(L, GLOBAL_TABLE);
    lua_pushstring(L, Name);
    if (1 == FUELuaExternalInterface::PushObjectToLua(L, Value))
    {
        lua_rawset(L, -3);
    }
}

void UGameLuaManager::SetGlobalBoolVariable(const char* Name, bool Value)
{
    FGlobalVariable::SetField<bool>(GetLuaState(), Name, Value);
}

void UGameLuaManager::SetGlobalStringVariable(const char* Name, const char* Value)
{
    FGlobalVariable::SetField<const char*>(GetLuaState(), Name, Value);
}

void UGameLuaManager::SetGlobalTableNewIndexEnabled(bool bEnabled)
{
    LuaRoot->GetExtenalInterface()->SetGlobalTableNewIndexEnabled(bEnabled);
}

void UGameLuaManager::SetHookEnabled(bool bEnabled)
{
    if (bEnabled && !LuaHook)
    {
        LuaHook = new FGameLuaHook(this);
    }
    else if(!bEnabled && LuaHook)
    {
        delete LuaHook;
        LuaHook = nullptr;
    }
    LuaRoot->GetExtenalInterface()->SetLuaHook(LuaHook);
}

void UGameLuaManager::SetHookLogEnabled(bool bEnabled)
{
    LuaHook->SetLogEnabled(bEnabled);
}

void UGameLuaManager::SetHandleCountToGC(int HandleCount)
{
    LuaRoot->GetExtenalInterface()->SetHandleCountToTriggerHook(HandleCount);
}

void UGameLuaManager::StartLuaCollectGarbageByStep()
{
    if (!TickerHandle.IsValid())
    {
        UE_LOG(LogGameLua, Display, TEXT("LuaGC by step started."));
        TickerHandle = FTicker::GetCoreTicker().AddTicker(FTickerDelegate::CreateUObject(this, &UGameLuaManager::Tick), LuaGCStepTime);
    }
}

void UGameLuaManager::StopLuaCollectGarbageByStep()
{
    if (TickerHandle.IsValid())
    {
        FTicker::GetCoreTicker().RemoveTicker(TickerHandle);
        TickerHandle.Reset();
    }
}

bool UGameLuaManager::Tick(float DeltaTime)
{
    if (lua_gc(GetLuaState(), LUA_GCSTEP, LuaGCStepSize))
    {
        UE_LOG(LogGameLua, Display, TEXT("LuaGC by step finished."));
        StopLuaCollectGarbageByStep();
    }

    return true;
}

#undef GET_LUA_INTERFACE
#undef GET_GAMELUA_MANAGER
#undef GET_PATH_SEARCHER

#endif