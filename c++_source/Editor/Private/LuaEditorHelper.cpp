#include "LuaEditorHelper.h"
#include "PiratesEditor.h"
#include "Game/GameCommon.h"

#if ENABLE_U4LUA
#include "Game/Lua/GameLuaRoot.h"
#else
#include "GameLuaManager.h"
#endif


struct ULuaEditorHelper::FImplement
{
#if ENABLE_U4LUA
    UGameLuaRoot* GameLuaRoot;
#else
    UGameLuaManager* GameLuaManager;
#endif    
    
    ULuaEditorHelper* EditorHelper;

    FImplement(ULuaEditorHelper *Helper)
#if ENABLE_U4LUA
        : GameLuaRoot(nullptr)
#else
        : GameLuaManager(nullptr)
#endif        
        , EditorHelper(Helper)
    {

    }

    const FString DefaultLauchScriptName = TEXT("EditorMain");

    void InitGameLuaManager()
    {
#if !ENABLE_U4LUA
        GameLuaManager = NewObject<UGameLuaManager>();
        GameLuaManager->Init(FPaths::ProjectContentDir());
        GameLuaManager->AddSearchPath(TEXT("Scripts/Base/"));
        GameLuaManager->AddSearchPath(TEXT("Scripts/Common/"));
        GameLuaManager->AddSearchPath(TEXT("Scripts/Client/"));
        GameLuaManager->AddSearchPath(TEXT("Scripts/BattleServer/"));
        GameLuaManager->AddSearchPath(TEXT("Scripts/Editor/"));
        GameLuaManager->OnWorldChanged(nullptr);

        GameLuaManager->SetGlobalBoolVariable("GWithEditor", true);
        GameLuaManager->SetGlobalBoolVariable("Debug", true);
        GameLuaManager->SetGlobalObjectVariable("GLuaEditorHelper", EditorHelper);
        GameLuaManager->SetIsDedicatedServer(false);
#endif
    }

    void InitGameLuaRoot()
    {
        GameLuaRoot = NewObject<UGameLuaRoot>();
        GameLuaRoot->Init();
        GameLuaRoot->OnCurrentWorldChanged(nullptr);
        GameLuaRoot->SetIsDedicatedServer(false);

        auto Lib = GameLuaRoot->GetLib();
        Lib->SetSearchPath({
            TEXT("Scripts/Base/"),
            TEXT("Scripts/Common/"),
            TEXT("Scripts/Client/"),
            TEXT("Scripts/BattleServer/"),
            TEXT("Scripts/Editor/"),
            });
        Lib->SetGlobalBoolVariable("GWithEditor", true);
        Lib->SetGlobalBoolVariable("Debug", true);
        Lib->SetGlobalObjectVariable("GLuaEditorHelper", EditorHelper);        
    }

    bool Init()
    {
        if (UGameCommon::IsU4LuaEnabled())
        {
            InitGameLuaRoot();
        }
        else
        {
            InitGameLuaManager();
        }
        return true;
    }

    void Uninit()
    {
#if ENABLE_U4LUA
        if (GameLuaRoot)
        {
            GameLuaRoot->Uninit();
            GameLuaRoot = nullptr;
        }
#else
        if (GameLuaManager)
        {
            GameLuaManager->Uninit();
            GameLuaManager = nullptr;
        }
#endif
    }

    void SetStartEnv(bool bPlayInEditor, bool bCommandlet, const FString& Params)
    {
#if ENABLE_U4LUA
        if (GameLuaRoot)
        {
            auto Lib = GameLuaRoot->GetLib();
            Lib->SetGlobalBoolVariable("GPlayInEditor", bPlayInEditor);
            Lib->SetGlobalBoolVariable("GPlayInCommandlet", bCommandlet);
            Lib->SetGlobalStringVariable("GLaunchParams", TCHAR_TO_UTF8(*Params));
        }        
#else
        if (GameLuaManager)
        {
            GameLuaManager->SetGlobalBoolVariable("GPlayInEditor", bPlayInEditor);
            GameLuaManager->SetGlobalBoolVariable("GPlayInCommandlet", bCommandlet);
            GameLuaManager->SetGlobalStringVariable("GLaunchParams", TCHAR_TO_UTF8(*Params));
        }
#endif
    }

    bool PlayInEditor(FString& ErrorMessage)
    {
        FString Temp;
        SetStartEnv(true, false, Temp);

#if ENABLE_U4LUA
        if (GameLuaRoot)
        {
            return GameLuaRoot->GetLib()->DoFileWithError(DefaultLauchScriptName, ErrorMessage);
        }
#else
        if (GameLuaManager)
        {
            return GameLuaManager->DoFile(DefaultLauchScriptName, ErrorMessage);
        }
#endif
        return false;
    }

    bool PlayInCommandlet(const FString& LanuchScript, const FString& Params)
    {
        SetStartEnv(false, true, Params);

        const FString& FileName = LanuchScript.Len() > 0 ? LanuchScript : DefaultLauchScriptName;
#if ENABLE_U4LUA
        if (GameLuaRoot)
        {
            return GameLuaRoot->GetLib()->DoFile(FileName);
        }
#else
        if (GameLuaManager)
        {
            return GameLuaManager->DoFile(FileName);
        }
#endif
        return false;
    }

    void SetIsDedicatedServer(bool bServer)
    {
#if ENABLE_U4LUA
        if (GameLuaRoot)
        {
            GameLuaRoot->SetIsDedicatedServer(bServer);
        }
#else
        if (GameLuaManager)
        {
            GameLuaManager->SetIsDedicatedServer(bServer);
        }
#endif
    }

    void AddReferencedObjects(FReferenceCollector& Collector)
    {
#if ENABLE_U4LUA
        if (GameLuaRoot)
        {
            Collector.AddReferencedObject(GameLuaRoot);
        }
#else
        if (GameLuaManager)
        {
            Collector.AddReferencedObject(GameLuaManager);
        }
#endif     
    }
};

//////////////////////////////////////////////////////////////////////////
ULuaEditorHelper::ULuaEditorHelper(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, Impl(MakeShareable(new FImplement(this)))
{

}

bool ULuaEditorHelper::Init()
{
	return Impl->Init();
}

void ULuaEditorHelper::Uninit()
{
	Impl->Uninit();
}

bool ULuaEditorHelper::PlayInEditor(FString& ErrorMessage)
{
	return Impl->PlayInEditor(ErrorMessage);
}

bool ULuaEditorHelper::PlayInCommandlet(const FString& LanuchScript, const FString& Params)
{
	return Impl->PlayInCommandlet(LanuchScript, Params);
}

void ULuaEditorHelper::SetIsDedicatedServer(bool bServer)
{
	Impl->SetIsDedicatedServer(bServer);
}

void ULuaEditorHelper::AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector)
{
	Super::AddReferencedObjects(InThis, Collector);

	ULuaEditorHelper* Helper = Cast<ULuaEditorHelper>(InThis);
    Helper->Impl->AddReferencedObjects(Collector);
}