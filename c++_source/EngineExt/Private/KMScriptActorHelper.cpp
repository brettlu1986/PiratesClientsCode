// Fill out your copyright notice in the Description page of Project Settings.

#include "KMScriptActorHelper.h"
#include "EngineExt.h"
//#include "KMLevelScriptActor.h"
//#include "Engine/LevelStreaming.h"

//DEFINE_LOG_CATEGORY_CLASS(UKMScriptActorHelper, KMScriptActorHelperLog)
//DEFINE_LOG_CATEGORY_CLASS(ULevelStreamingLoadContext, LevelStreamingLoadContextLog)
//
//static const FString LOGIC_LEVEL_PREFIX = TEXT("/LV_");
//
//void ULevelStreamingLoadContext::OnLevelLoaded()
//{
//	if (LevelStreaming.IsValid() && LevelStreaming->IsValidLowLevel())
//	{
//		if (LevelStreaming->GetLoadedLevel())
//		{
//			if (OnLevelLoadedDelegate)
//			{
//				OnLevelLoadedDelegate();
//			}
//			UE_LOG(LevelStreamingLoadContextLog, Log, TEXT("OnLevelLoaded: %s for %s"), *LevelStreaming->GetLoadedLevel()->GetLevelScriptActor()->GetName(), *LevelStreaming->GetName());
//		}
//		else
//		{
//			UE_LOG(LevelStreamingLoadContextLog, Log, TEXT("LoadedLevel cannot be found when OnLevelLoaded was called for %s"), *LevelStreaming->GetName());
//		}
//	}
//	else
//	{
//		UE_LOG(LevelStreamingLoadContextLog, Log, TEXT("Invalid LevelStreaming when OnLevelLoaded was called"));
//	}
//}
//
//void UKMScriptActorHelper::CallOnMatchStartedForAllLevelScripts()
//{
//	int Num = LogicLevelScriptActorArray.Num();
//	for (int i = 0; i < Num; ++i)
//	{
//		auto LevelScript = LogicLevelScriptActorArray[i];
//		if (LevelScript.IsValid() && LevelScript->IsValidLowLevel())
//		{
//			UE_LOG(KMScriptActorHelperLog, Log, TEXT("Call OnMatchStarted:%s"), *LevelScript->GetName());
//			LevelScript->OnMatchStarted();
//		}
//	}
//}
//
//bool UKMScriptActorHelper::IsLogicLevelStreaming(ULevelStreaming *LevelStreaming)
//{
//	bool Ret = false;
//	auto DesiredPackageName = LevelStreaming->GetWorldAssetPackageName();
//	int idx = -1;
//	if (DesiredPackageName.FindLastChar('/', idx))
//	{
//		auto Name = DesiredPackageName.RightChop(idx);
//		Ret = Name.StartsWith(LOGIC_LEVEL_PREFIX);
//	}
//	return Ret;
//}
//
//void UKMScriptActorHelper::AddLogicLevelScriptToArray(ULevel *Level)
//{
//	if (Level)
//	{
//		auto LevelScript = Cast<AKMLevelScriptActor>(Level->GetLevelScriptActor());
//		if (LevelScript)
//		{
//			TWeakObjectPtr<AKMLevelScriptActor> Actor = LevelScript;
//			if (!LogicLevelScriptActorArray.Contains(Actor))
//			{
//				LogicLevelScriptActorArray.Add(Actor);
//			}
//		}
//	}
//}
//
//void UKMScriptActorHelper::ObtainAllLogicLevelActor()
//{
//	UWorld *World = GetWorld();
//	if (!World)
//	{
//		UE_LOG(KMScriptActorHelperLog, Log, TEXT("World is NULL in ObtainAllLogicLevelActor"));
//		return ;
//	}
//
//	auto Levels = World->GetLevels();
//	int LevelNum = Levels.Num();
//	for (int i = 0; i < LevelNum; ++i)
//	{
//		AddLogicLevelScriptToArray(Levels[i]);
//	}
//
//	auto StreamingLevels = World->StreamingLevels;
//	LevelNum = StreamingLevels.Num();
//	for (int i = 0; i < LevelNum; ++i)
//	{
//		auto StreamingLevel = StreamingLevels[i];
//		if (StreamingLevel)
//		{
//			AddLogicLevelScriptToArray(StreamingLevel->GetLoadedLevel());
//		}
//	}
//}
//
//void UKMScriptActorHelper::CheckAllLogicLevelLoaded()
//{
//	bool AllLoaded = true;
//	int Num = LoadingContextArray.Num();
//	for (int i = 0; i < Num; ++i)
//	{
//		auto LevelStreaming = LoadingContextArray[i]->LevelStreaming;
//		if (!LevelStreaming->GetLoadedLevel())
//		{
//			AllLoaded = false;
//			break;
//		}
//	}
//
//	if (AllLoaded)
//	{ 
//		LoadingContextArray.Empty();
//		ObtainAllLogicLevelActor();
//		CheckAllLogicLevelBeginPlay();
//	}
//}
//
//void UKMScriptActorHelper::CheckAllLogicLevelBeginPlay()
//{
//	bool AllBeganPlay = true;
//	int Num = LogicLevelScriptActorArray.Num();
//	for (int i = 0; i < Num; ++i)
//	{
//		auto LevelScript = LogicLevelScriptActorArray[i];
//		if (LevelScript.IsValid() && LevelScript->IsValidLowLevel() 
//			&& !LevelScript->HasActorBegunPlay())
//		{
//			if (!LevelScript->OnBeginPlayDelegate)
//			{
//				LevelScript->OnBeginPlayDelegate = [this] {
//					CheckAllLogicLevelBeginPlay();
//				};
//			}
//			AllBeganPlay = false;
//			break;
//		}                                                                           
//	}
//	if (AllBeganPlay)
//	{ 
//		CallOnMatchStartedForAllLevelScripts();
//	}
//}
//
//void UKMScriptActorHelper::PreprocessAllLevelStreamings()
//{
//	UWorld *World = GetWorld();
//	if (!World)
//	{
//		UE_LOG(KMScriptActorHelperLog, Log, TEXT("World is NULL in PreprocessAllLevelStreamings"));
//		return ;
//	}
//
//	auto StreamingLevels = World->StreamingLevels;
//	int LevelNum = StreamingLevels.Num();
//	for (int i = 0; i < LevelNum; ++i)
//	{
//		auto StreamingLevel = StreamingLevels[i];
//		if (StreamingLevel)
//		{
//			// 只处理LogicLevel，不考虑资源Map
//			if (IsLogicLevelStreaming(StreamingLevel))
//			{
//				if (!StreamingLevel->GetLoadedLevel())
//				{
//					TScriptDelegate<FWeakObjectPtr> Delegate;
//					auto Context = NewObject<ULevelStreamingLoadContext>(this);
//					Context->LevelStreaming = StreamingLevel;
//					Context->OnLevelLoadedDelegate = [this] {
//						CheckAllLogicLevelLoaded();
//					};
//					LoadingContextArray.Add(Context);
//
//					Delegate.BindUFunction(Context, FName("OnLevelLoaded"));
//					StreamingLevel->OnLevelLoaded.Add(Delegate);
//					UE_LOG(KMScriptActorHelperLog, Log, TEXT("Register OnLevelLoaded event for:%s"), *StreamingLevel->GetWorldAssetPackageName());
//				}
//			}
//		}
//	}
//}
//
//void UKMScriptActorHelper::TryCallOnMatchStartedForLevelScript()
//{
//	PreprocessAllLevelStreamings();
//	CheckAllLogicLevelLoaded();
//}
