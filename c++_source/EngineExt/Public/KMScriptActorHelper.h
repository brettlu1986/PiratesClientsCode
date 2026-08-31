// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
//#include "UObject/Object.h"
//#include "KMObject.h"
//#include "KMScriptActorHelper.generated.h"

/**
 * 
 */
//
//class UStreamingLevel;
//class AKMLevelScriptActor;
//
//UCLASS()
//class ENGINEEXT_API ULevelStreamingLoadContext : public UObject
//{
//	GENERATED_BODY()
//
//public:
//	TWeakObjectPtr<ULevelStreaming> LevelStreaming;
//
//	UFUNCTION()
//	void OnLevelLoaded();
//
//	TFunction<void()> OnLevelLoadedDelegate;
//	
//private:
//	DECLARE_LOG_CATEGORY_CLASS(LevelStreamingLoadContextLog, Log, All)
//};
//
//UCLASS()
//class ENGINEEXT_API UKMScriptActorHelper : public UKMObject
//{
//	GENERATED_BODY()
//	
//public:
//	void TryCallOnMatchStartedForLevelScript();
//
//private:
//	DECLARE_LOG_CATEGORY_CLASS(KMScriptActorHelperLog, Log, All)
//
//	UPROPERTY()
//	TArray<ULevelStreamingLoadContext *> LoadingContextArray;
//	TArray<TWeakObjectPtr<AKMLevelScriptActor> > LogicLevelScriptActorArray;
//
//	void CallOnMatchStartedForAllLevelScripts();
//	void CallOnMatchStartedWithLevel(ULevel *Level);
//
//	bool IsLogicLevelStreaming(ULevelStreaming *LevelStreaming);
//	void AddLogicLevelScriptToArray(ULevel *Level);
//
//	void CheckAllLogicLevelLoaded();
//	void CheckAllLogicLevelBeginPlay();
//	void ObtainAllLogicLevelActor();
//	void PreprocessAllLevelStreamings();
//};


//UCLASS()
//class ENGINEEXT_API UKMScriptActorHelper : public UKMObject
//{
//	GENERATED_BODY()
//	
//public:
//	void TryCallOnMatchStartedForLevelScript();
//
//private:
//	DECLARE_LOG_CATEGORY_CLASS(KMScriptActorHelperLog, Log, All)
//
//	UPROPERTY()
//	TArray<ULevelStreamingLoadContext *> LoadingContextArray;
//	TArray<TWeakObjectPtr<AKMLevelScriptActor> > LogicLevelScriptActorArray;
//
//	void CallOnMatchStartedForAllLevelScripts();
//	void CallOnMatchStartedWithLevel(ULevel *Level);
//
//	bool IsLogicLevelStreaming(ULevelStreaming *LevelStreaming);
//	void AddLogicLevelScriptToArray(ULevel *Level);
//
//	void CheckAllLogicLevelLoaded();
//	void CheckAllLogicLevelBeginPlay();
//	void ObtainAllLogicLevelActor();
//	void PreprocessAllLevelStreamings();
//};
