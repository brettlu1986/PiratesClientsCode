// Fill out your copyright notice in the Description page of Project Settings.

#include "KMUnrealEdEngine.h"
#include "PiratesEditor.h"
#include "KMClassDefaultObjectEditTool.h"
#include "LuaEditorHelper.h"
#include "Misc/MessageDialog.h"
#include "GenericPlatform/GenericPlatformMisc.h"
#include "Game/GameEngineExt.h"

struct UKMUnrealEdEngine::FImplement
{
	UKMUnrealEdEngine *Owner;
//	bool IsPlayInEditor;
	UKMClassDefaultObjectEditTool* CDOTool;

	FImplement(UKMUnrealEdEngine *P) 
		: Owner(P)
//		, IsPlayInEditor(false)
		, CDOTool(nullptr)
	{

	}

	~FImplement()
	{
		FEditorDelegates::BeginPIE.RemoveAll(this);
		FEditorDelegates::EndPIE.RemoveAll(this);
	}

	void Init()
	{
// 		FEditorDelegates::BeginPIE.AddRaw(this, &FImplement::OnBeginPIE);
// 		FEditorDelegates::EndPIE.AddRaw(this, &FImplement::OnEndPIE);
		CDOTool = NewObject<UKMClassDefaultObjectEditTool>(Owner);
		CDOTool->Init(Owner);		
	}

	bool OnPreBeginPIE(UWorld* InWorld)
	{
		if (InWorld)
		{
			AWorldSettings* Settings = InWorld->GetWorldSettings();
			if (Settings && Settings->DefaultGameMode)
			{
				TArray<FString> ArtGameModeNames;
				GConfig->GetArray(TEXT("EditoronlyBP"), TEXT("ArtGameModeNames"), ArtGameModeNames, GEditorIni);
				if (ArtGameModeNames.Contains(Settings->DefaultGameMode->GetName()))
				{
					return true;
				}
			}
		}

        bool bSkipLoadConfigs = false;
        GConfig->GetBool(TEXT("/Script/Mock.MockSettings"), TEXT("bSkipLoadConfigs"), bSkipLoadConfigs, GEditorIni);
        if (bSkipLoadConfigs)
        {
            return true;
        }

		ULuaEditorHelper* LuaHelper = NewObject<ULuaEditorHelper>(Owner);
		LuaHelper->Init();
		FString ErrorMessage;
		bool bRet = LuaHelper->PlayInEditor(ErrorMessage);
		if (!bRet)
		{
			FMessageDialog::Open(EAppMsgType::Ok, FText::FromString(FString::Printf(TEXT("数据表导出错误：\n%s"), *ErrorMessage)));
		}
		LuaHelper->Uninit();
        LuaHelper->MarkPendingKill();
		::CollectGarbage(GARBAGE_COLLECTION_KEEPFLAGS);
		return bRet;
	}

// 	void OnBeginPIE(const bool bInSimulateInEditor)
// 	{
// 		IsPlayInEditor = true;
// 	}
// 
// 	void OnEndPIE(const bool bInSimulateInEditor)
// 	{
// 		IsPlayInEditor = false;
// 	}
};

UKMUnrealEdEngine::UKMUnrealEdEngine(const FObjectInitializer& ObjectInitializer): Super(ObjectInitializer)
, Impl(MakeShareable(new FImplement(this)))
{

}

void UKMUnrealEdEngine::Init(IEngineLoop* InEngineLoop)
{
	Super::Init(InEngineLoop);
	Impl->Init();

	//world composition for editor
	FCoreUObjectDelegates::OnCollectingWorldComposition.BindUObject(this, &UKMUnrealEdEngine::OnWorldCompositionCollecting);
}

void UKMUnrealEdEngine::PreExit()
{
	//world composition for editor
	FCoreUObjectDelegates::OnCollectingWorldComposition.Unbind();
}

void UKMUnrealEdEngine::StartPlayInEditorSession(FRequestPlaySessionParams& InRequestParams)
{
    if (Impl->OnPreBeginPIE(GetEditorWorldContext().World()) == false)
    {
		CancelRequestPlaySession();
        return;
    }
	Super::StartPlayInEditorSession(InRequestParams);
}

void UKMUnrealEdEngine::EndPlayMap()
{
	if (GEngine && GEngine->GameViewport)
	{
		Exec(GWorld, TEXT("ShowFlag.Rendering 1"));
	}
	Super::EndPlayMap();
}

void UKMUnrealEdEngine::AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector)
{
	Super::AddReferencedObjects(InThis, Collector);

	UKMUnrealEdEngine* Editor = Cast<UKMUnrealEdEngine>(InThis);
	Collector.AddReferencedObject(Editor->Impl->CDOTool);
}

void UKMUnrealEdEngine::AddReferencedObjects(FReferenceCollector& Collector)
{
	Super::AddReferencedObjects(Collector);
}

UWorld* UKMUnrealEdEngine::GetWorldFromContextObject(const UObject* Object, EGetWorldErrorMode ErrorMode) const
{
	if (Object == nullptr)
	{
		switch (ErrorMode)
		{
		case EGetWorldErrorMode::Assert:
			check(Object);
			break;
		case EGetWorldErrorMode::LogAndReturnNull:
			FFrame::KismetExecutionMessage(TEXT("A null object was passed as a world context object to UEngine::GetWorldFromContextObject()."), ELogVerbosity::Error);
			//UE_LOG(LogEngine, Warning, TEXT("UEngine::GetWorldFromContextObject() passed a nullptr"));
			break;
		case EGetWorldErrorMode::ReturnNull:
			break;
		}
		return nullptr;
	}

	bool bSupported = true;
	UWorld* World = (ErrorMode == EGetWorldErrorMode::Assert) ? Object->GetWorldChecked(/*out*/ bSupported) : Object->GetWorld();
	return World ? World : GWorld;
}


void UKMUnrealEdEngine::OnWorldCompositionCollecting(const FString& PersistentName, TArray<FString>& WorldRoots)
{
	UGameEngineExt::CollectWorldComposition_Editor(PersistentName, WorldRoots);
}