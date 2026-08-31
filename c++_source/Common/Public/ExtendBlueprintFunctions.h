// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "Kismet/BlueprintFunctionLibrary.h"
#include "ExtendBlueprintFunctions.generated.h"

/**
 *
 */

class UParticleSystemComponent;
class USkeletalMeshComponent;

UCLASS()
class COMMON_API UExtendBlueprintFunctions : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

	DECLARE_LOG_CATEGORY_CLASS(ExtendBPFuncLibLog, Log, All);

	/*
	used to create blueprint class that inherited from object
	*/
	UFUNCTION(BlueprintCallable, meta = (DisplayName = "Create Object From Blueprint", Keywords = "create blueprint object", DeprecatedFunction, DeprecationMessage = "Use ConstructObjectFromClass in Game Category instead"), Category = KMCategory)
	static UObject* CreateObjectFromBlueprint(TSubclassOf<UObject> UC);

    UFUNCTION(BlueprintCallable, meta = (Keywords = "create blueprint object"), Category = KMCategory)
    static UObject* CreateObject(TSubclassOf<UObject> UC, UObject *Outer);


	UFUNCTION(BlueprintCallable, meta = (Keywords = "create blueprint object with name"), Category = KMCategory)
	static UObject* CreateObjectWithName(TSubclassOf<UObject> UC, UObject *Outer, FName Name);

	UFUNCTION(BlueprintPure, Category = KMCategory)
	static bool IsActorOnDedicatedServer(AActor *Actor);

	UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject", DisplayName = "Client Travel", Keywords = "client travel"), Category = KMCategory)
	static void ClientTravel(UObject* WorldContextObject, const FString &TargetMap);

	UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject", DisplayName = "Server Travel", Keywords = "server travel"), Category = KMCategory)
	static void ServerTravel(UObject* WorldContextObject, const FString &TargetMap);

	UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject", DisplayName = "Get Client Connections Num", Keywords = "client connections num"), Category = KMCategory)
	static int32 GetClientConnectionsNum(UObject* WorldContextObject);

	UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject", DisplayName = "Get Connected Actors", Keywords = "get connected actors"), Category = KMCategory)
	static TArray<AActor *> GetConnectedPlayerActors(UObject* WorldContextObject);

	UFUNCTION(BlueprintCallable, BlueprintPure, Category = KMParticles)
	static int32 GetParticleEmitterCount(UParticleSystemComponent *ParticleComponent);

	UFUNCTION(BlueprintPure, meta = (DisplayName = "Get Montage Section Length", SectionName = "Default", Keywords = "get montage section length"), Category = KMCategory)
	static float GetMontageSectionLength(const UAnimMontage *Montage, FName SectionName);

    UFUNCTION(BlueprintPure, meta = (DisplayName = "Get Montage Section Length", SectionName = "Default", Keywords = "get montage section length"), Category = KMCategory)
    static void GetMontageSectionStartEndTime(const UAnimMontage *Montage, FName SectionName, float& OutStartTime, float& OutEndTime);

    UFUNCTION(BlueprintPure, meta = (DisplayName = "Get Montage Length", SectionName = "Default", Keywords = "get montage length"), Category = KMCategory)
    static float GetMontageLength(UAnimMontage *Montage);

	UFUNCTION(BlueprintPure, Category = KMCategory)
	static float GetAnimSequenceLength(UAnimSequenceBase *AnimSequence);

	UFUNCTION(BlueprintCallable, Category = KMCategory)
	static void RefreshBoneTransform(USkeletalMeshComponent *Mesh);

    UFUNCTION()
    static AActor* FindActorWithNetGUID(UObject* WorldContextObject, uint32 NetGUID);

	UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject", DisplayName = "LoadObjectFromAssetPath", Keywords = "load object from asset path"), Category = KMCategory)
	static UObject* LoadObjectFromAssetPath(const FString& Path);

	UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject", DisplayName = "LoadClassFromAssetPath", Keywords = "load class from asset path"), Category = KMCategory)
	static UClass* LoadClassFromAssetPath(const FString& Path);

	UFUNCTION(BlueprintCallable, CustomThunk, meta = (DisplayName = "GetContentFromUStruct", CustomStructureParam = "Structure"), Category = "Json")
	static void GetContentFromUStruct(int32 Structure, const FName &PropertyName, bool &Success, FString& Str_R, UObject *&Obj_R, int32 &Int_R, float &Float_R, bool &Bool_R);

	static void Generic_GetContentFromUStruct(void* Structure, const FStructProperty* StructProperty, const FName &PropertyName, bool &Success, FString& Str_R, UObject *&Obj_R, int32 &Int_R, float &Float_R, bool &Bool_R);
	DECLARE_FUNCTION(execGetContentFromUStruct)
	{
		Stack.StepCompiledIn<FStructProperty>(NULL);
		void* Structure = Stack.MostRecentPropertyAddress;
		FStructProperty* StructProperty = (FStructProperty*)Stack.MostRecentProperty;

		P_GET_PROPERTY_REF(FNameProperty, PropertyName);
		P_GET_PROPERTY_REF(FBoolProperty, Success);
		P_GET_PROPERTY_REF(FStrProperty, Str_R);
		P_GET_PROPERTY_REF(FObjectProperty, Obj_R);
		P_GET_PROPERTY_REF(FIntProperty, Int_R);
		P_GET_PROPERTY_REF(FFloatProperty, Float_R);
		P_GET_PROPERTY_REF(FBoolProperty, Bool_R);

		P_FINISH;
		Generic_GetContentFromUStruct(Structure, StructProperty, PropertyName, Success, Str_R, Obj_R, Int_R, Float_R, Bool_R);
	}

	UFUNCTION(BlueprintCallable, CustomThunk, meta = (DisplayName = "ConvertScriptStructToJsonStr", CustomStructureParam = "Structure"), Category = "Json")
	static void ConvertScriptStructToJsonStr(int32 Structure, FString& OutStr);

	static void Generic_ConvertScriptStructToJsonStr(void* Structure, const FStructProperty* StructProperty, FString& OutStr);
	DECLARE_FUNCTION(execConvertScriptStructToJsonStr)
	{
		Stack.StepCompiledIn<FStructProperty>(NULL);
		void* Structure = Stack.MostRecentPropertyAddress;
		FStructProperty* StructProperty = (FStructProperty*)Stack.MostRecentProperty;

		P_GET_PROPERTY_REF(FStrProperty, OutStr);

		P_FINISH;
        P_NATIVE_BEGIN;
		Generic_ConvertScriptStructToJsonStr(Structure, StructProperty, OutStr);
        P_NATIVE_END;
	}

	UFUNCTION(BlueprintCallable, CustomThunk, meta = (DisplayName = "ConvertJsonStrToScriptStruct", CustomStructureParam = "Structure"), Category = "Json")
	static void ConvertJsonStrToScriptStruct(const FString& Instr, int32 &Structure);
	static void Generic_ConvertJsonStrToScriptStruct(const FString& inStr, void* Structure, const FStructProperty* StructProperty);
	DECLARE_FUNCTION(execConvertJsonStrToScriptStruct)
	{
		P_GET_PROPERTY(FStrProperty, InString);
		Stack.StepCompiledIn<FStructProperty>(NULL);
		void* Structure = Stack.MostRecentPropertyAddress;
		FStructProperty* StructProperty = (FStructProperty*)Stack.MostRecentProperty;

		P_FINISH;
        P_NATIVE_BEGIN;
		Generic_ConvertJsonStrToScriptStruct(InString, Structure, StructProperty);
        P_NATIVE_END;
	}

    UFUNCTION(BlueprintPure, Category = "Game")
    static FString ConvertToStorageSizeDesc(int Size);

    UFUNCTION(BlueprintPure, Category = "Game")
    static FString GetDeviceId();

public:
	/** Enables LevelStreaming */
	UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject"), Category = "Game")
	static void ToggleLevelStreaming(UObject* WorldContextObject, bool Enable);

    UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject"), Category = "Game")
    static ULevelStreaming* LoadSubLevelDynamic(UObject* WorldContextObject, const FString& PackageName, FVector Location = FVector::ZeroVector, FRotator Rotation = FRotator::ZeroRotator);

	//yangjingzhao add
	UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject"), Category = "Game")
	static ULevelStreaming* LoadSublevelSyncDynamic(UObject* WorldContextObject, const FString& PackageName, FVector Location = FVector::ZeroVector, FRotator Rotation = FRotator::ZeroRotator);

	UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject"), Category = "Game")
    static void SetLevelClientOnlyVisible(ULevelStreaming* StreamingLevel, bool bClientOnlyVisible);

    UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject"), Category = "Game")
    static void UnloadSubLevelDynamic(UObject* WorldContextObject, const FString& PackageName);

    UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject"), Category = "Game")
    static AActor* GetLevelActorByTag(ULevelStreaming* StreamingLevel, const FName& Tag);

    UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject"), Category = "Game")
    static TArray<AActor*> GetLevelActorsByTag(UObject* WorldContextObject, const FName& Tag);
    UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject"), Category = "Game")
    static AActor* GetWorldActorByName(UObject* WorldContextObject, const FName& Tag);

	UFUNCTION(BlueprintCallable, Category = "Game")
	static FText FormatText(const FText& Fmt, const TArray<FText>& Args);

	UFUNCTION(BlueprintCallable, Category = "Game")
	static FText FormatTextByName(const FText& Fmt, const TArray<FString>& Names, const TArray<FText>& Args);

	UFUNCTION(BlueprintCallable, Category = "Game")
	static void SetCurrentCulture(const FString& Language);

	UFUNCTION(BlueprintPure, Category = "Game")
	static const FString& GetCurrentCultureName();

	UFUNCTION(BlueprintPure, Category = "Game")
	static int32 GetObjectUniqueID(UObject* Object);

	UFUNCTION(BlueprintPure, meta = (WorldContext = "WorldContextObject"), Category = "Game")
	static void GetPawnsInSectorRange(UObject* WorldContextObject, const FVector& Location, const FRotator& Rotation, float Radius, float Angle, TArray<APawn*>& OutPawns);
    UFUNCTION(BlueprintPure, meta = (WorldContext = "WorldContextObject"), Category = "Game")
    static void GetActorsInSectorRange(const UObject* WorldContextObject, TSubclassOf<AActor> ActorClass, const FVector& Location, const FRotator& Rotation, float Radius, float Angle, TArray<AActor*>& OutActors);
	UFUNCTION(BlueprintPure, meta = (WorldContext = "WorldContextObject"), Category = "Game")
	static void GetPawnsInCircleRange(UObject* WorldContextObject, const FVector& Location, float Radius, TArray<APawn*>& OutPawns);

	UFUNCTION(BlueprintPure, meta = (WorldContext = "WorldContextObject"), Category = "Game")
	static void GetPawnsInRectRange(UObject* WorldContextObject, const FVector& Location, const FRotator& Rotation, const FVector& BoxExtent, TArray<APawn*>& OutPawns);

	UFUNCTION(BlueprintPure, meta = (WorldContext = "WorldContextObject"), Category = "Game")
	static FVector GetForwardLocationByDistance(const FVector& Location, const FRotator& Rotation, float Distance);

    UFUNCTION(BlueprintPure, meta = (WorldContext = "WorldContextObject"), Category = "Game")
    static ALevelSequenceActor* GetSequenceActorFromPlayer(ULevelSequencePlayer* InPlayer);

	UFUNCTION(BlueprintCallable, Category = "Utilities", meta = (WorldContext = "WorldContextObject", DeterminesOutputType = "ObjectClass", DynamicOutputParam = "OutActors"))
	static void GetAllTexture2D(TArray<UTexture2D*>& OutTextures);

	UFUNCTION(BlueprintPure, meta = (WorldContext = "WorldContextObject"), Category = "Game")
	static void GetAllFunctionNameByClass(TArray<FString>& OutStrings, const UClass* Class);

	UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject"), Category = "Game")
	static void SetIntPropertyValueByNames(UObject* Object, int32 Value, const TArray<FString>& PropertyNames);

    UFUNCTION(BlueprintPure, meta = (WorldContext = "WorldContextObject"), Category = "Math")
    static float CalcFollowingNumberCPP(UObject* WorldContextObject, float TargetValue, float CurrentValue, float DeltaSeconds, float ChangeSpeed, float Min, float Max);

    UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject"), Category = "Config")
    static void UseStaticNavigation();


	/**
	* Returns an array of actors that overlap the given axis-aligned box.
	* @param WorldContext	World context
	* @param BoxPos		Center of box.
	* @param BoxExtent		Extents of box.
	* @param Filter		Option to restrict results to only static or only dynamic.  For efficiency.
	* @param ClassFilter	If set, will only return results of this class or subclasses of it.
	* @param ActorsToIgnore		Ignore these actors in the list
	* @param OutActors		Returned array of actors. Unsorted.
	* @return				true if there was an overlap that passed the filters, false otherwise.
	*/
	UFUNCTION(BlueprintCallable, Category = "Collision", meta = (WorldContext = "WorldContextObject", AutoCreateRefTerm = "ActorsToIgnore", DisplayName = "BoxOverlapActorsWithRotation"))
	static bool BoxOverlapActors(UObject* WorldContextObject, const FVector BoxPos, FVector BoxExtent, const FRotator Rotation, const TArray<TEnumAsByte<EObjectTypeQuery> > & ObjectTypes, UClass* ActorClassFilter, const TArray<AActor*>& ActorsToIgnore, TArray<class AActor*>& OutActors);

	/**
	* Returns an array of components that overlap the given axis-aligned box.
	* @param WorldContext	World context
	* @param BoxPos		Center of box.
	* @param BoxExtent		Extents of box.
	* @param Filter		Option to restrict results to only static or only dynamic.  For efficiency.
	* @param ClassFilter	If set, will only return results of this class or subclasses of it.
	* @param ActorsToIgnore		Ignore these actors in the list
	* @param OutActors		Returned array of actors. Unsorted.
	* @return				true if there was an overlap that passed the filters, false otherwise.
	*/
	UFUNCTION(BlueprintCallable, Category = "Collision", meta = (WorldContext = "WorldContextObject", AutoCreateRefTerm = "ActorsToIgnore", DisplayName = "BoxOverlapComponentsWithRotation"))
	static bool BoxOverlapComponents(UObject* WorldContextObject, const FVector BoxPos, FVector Extent, const FRotator Rotation, const TArray<TEnumAsByte<EObjectTypeQuery> > & ObjectTypes, UClass* ComponentClassFilter, const TArray<AActor*>& ActorsToIgnore, TArray<class UPrimitiveComponent*>& OutComponents);

    /**
    * xuweihua: Epic version for this function seems to have messed up the 2 transforms by mistake.
    */
    UFUNCTION(BlueprintPure, BlueprintCallable, meta = (WorldContext = "WorldContextObject"), Category = "Math|Transform")
    static FTransform ConvertTransformToRelativeFixed(const FTransform& Transform, const FTransform& ParentTransform);

    /**
    * xuweihua: Get the accurate time in seconds in a single impure BP function.
    */
    UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject"), Category = "Utilities|Time")
    static void GetAccurateRealTimeEx(const UObject* WorldContextObject, int32& Seconds, float& PartialSeconds);

    /**
    * xuweihua: Sometimes we don't need pitch...
    */
    UFUNCTION(BlueprintPure, BlueprintCallable, meta = (WorldContext = "WorldContextObject"), Category = "Math|Vector2D")
    static float GetYawFromVector(FVector InVec);

    /**
    * xuweihua: Get game state.
    */
    UFUNCTION(BlueprintPure, BlueprintCallable, Category = "Utilities")
    static AGameStateBase* GetGameState(const UObject* WorldContextObject);

    UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject"), Category = "Debug")
    static FString CallGetDebugStringFunction(AActor* DebuggingActor, const FString& FunctionName, UClass* BPLibClass);

	//yjz add for asset reference
	UFUNCTION(BlueprintCallable, Category = "AssetReference")
	static UObject* LoadAssetFromAssetPtr(TAssetPtr<UObject> InAssetId);

	//yjz add for asset reference
	UFUNCTION(BlueprintCallable, Category = "AssetReference")
	static UClass* LoadClassAssetFromClassAssetPtr(TAssetSubclassOf<UObject> InAssetId);


// xwh: Ship utilities for editor
    UFUNCTION(BlueprintCallable, Category = "Utilities")
    static void GetDefaultComponentsByClass(UClass* InActorClass, UClass* InComponentClass,
        TArray<UActorComponent*>& DefaultComponents, TArray<FString>& VariableNames);

    UFUNCTION(BlueprintCallable, Category = "Utilities")
    static void GetDefaultComponentChildren(UClass* InActorClass, UActorComponent* DefaultComponent,
        UClass* ChildClass,
        TArray<USceneComponent*>& ChildComponents, TArray<FString>& VariableNames);

// xwh: Ship utilities for editor ends.

	UFUNCTION(BlueprintPure, Category = "Game", meta = (CallInEditor = "true"))
	static UActorComponent* FindActorComponentInCDO(UClass* InActorClass, const FString& Name,
        bool bFindOverridenComponent, bool bCreateOverridenComponentIfNotFind);

	UFUNCTION(BlueprintPure, Category = "Game", meta = (CallInEditor = "true"))
	static void FindActorChildComponentsInCDO(UClass* InActorClass, const FString& ParentName,
        bool bFindOverridenComponent, bool bCreateOverridenComponentIfNotFind,
        TArray<UActorComponent*>& OutComponents);

    UFUNCTION(BlueprintPure, Category = "Game", meta = (CallInEditor = "true"))
    static void FindActorParentComponentsInCDO(UClass* InActorClass, const FString& Name,
        bool bFindOverridenComponent, bool bCreateOverridenComponentIfNotFind,
        TArray<UActorComponent*>& OutComponents);

	UFUNCTION(BlueprintPure, Category = "Game")
	static float NormalDistributionRandom(float Mean = 0.0f, float Sigma = 1.0f);

	UFUNCTION(BlueprintCallable, Category = "Game")
	static TArray<float> SortedMultiNormalDistributionRandom(float Mean = 0.0f, float Sigma = 1.0f, int32 Count = 1);

	UFUNCTION(BlueprintCallable, BlueprintAuthorityOnly, Category = "Game|Damage")
	static float ApplyCustomDamage(AActor* DamagedActor, float BaseDamage, AController* EventInstigator, AActor* DamageCauser, TSubclassOf<class UDamageType> DamageTypeClass);

	UFUNCTION(BlueprintCallable, Category = "Actor")
	static TArray<UActorComponent*> GetComponentsByInterface(AActor* Actor, TSubclassOf<UInterface> Interface);

	UFUNCTION(BlueprintCallable, Category = "Game")
	static int32 GetUObjectCount();

	UFUNCTION(BlueprintCallable, Category = "Game")
	static int32 GetMaxUObjectCount();

	UFUNCTION(BlueprintCallable, Category = "Game")
	static void GetSkeletalMeshMaterialIndexs(USkeletalMeshComponent* SkeletalMeshComponent, FName MaterialSlotName, TArray<int32>& Indexs);

    UFUNCTION(BlueprintCallable, Category = "Game")
    static void ReplaceMatineeActor(ULevelSequencePlayer* SequencePlayer, FString inObjectDisplayName, AActor* BindActor);

    UFUNCTION(BlueprintCallable, Category = "Game")
    static TArray<AActor*> GetMatineeActor(ULevelSequencePlayer* SequencePlayer, FString inObjectDisplayName);

	UFUNCTION(BlueprintCallable, Category = "Effects|Components|ParticleSystem", meta = (Keywords = "particle system", UnsafeDuringActorConstruction = "true"))
	static UParticleSystemComponent* SpawnEmitterAttachedEx(class UParticleSystem* EmitterTemplate, class USceneComponent* AttachToComponent, FName AttachPointName = NAME_None, FVector Location = FVector(ForceInit), FRotator Rotation = FRotator::ZeroRotator, FVector Scale = FVector(1.f), EAttachLocation::Type LocationType = EAttachLocation::KeepRelativeOffset, bool bAutoDestroy = true, float CustomScale = 1.f, EPSCPoolMethod PoolingMethod = EPSCPoolMethod::None, bool bManageSignificance = false);

	UFUNCTION(BlueprintCallable, Category="Effects|Components|ParticleSystem", meta=(Keywords = "particle system", WorldContext="WorldContextObject", UnsafeDuringActorConstruction = "true"))
	static UParticleSystemComponent* SpawnEmitterAtLocationEx(const UObject* WorldContextObject, UParticleSystem* EmitterTemplate, FVector Location, FRotator Rotation = FRotator::ZeroRotator, FVector Scale = FVector(1.f), bool bAutoDestroy = true, float CustomScale = 1.f, EPSCPoolMethod PoolingMethod = EPSCPoolMethod::None, bool bManageSignificance = false);

	UFUNCTION(BlueprintCallable, Category = "Effects|Components|ParticleSystem")
	static void DeactivateEmitter(UParticleSystemComponent* ParticleSystemComponent);

	UFUNCTION(BlueprintCallable, Category = "Effects|Components|ParticleSystem")
	static void DestroyEmitter(UParticleSystemComponent* ParticleSystemComponent);

	UFUNCTION(BlueprintCallable, Category = "Effects|Components|ParticleSystem")
	static void RemoveEmitterInPendingList(UParticleSystemComponent* ParticleSystemComponent);

	UFUNCTION(BlueprintPure, Category = "Effects|Components|ParticleSystem")
	static bool CheckEmitterIsPending(UParticleSystemComponent* ParticleSystemComponent);

    UFUNCTION(BlueprintCallable, Category = "Game")
    static FSkeletalMaterial SetSkeletalMaterial(UPARAM(ref) FSkeletalMaterial& SkeletalMaterial, UMaterialInterface* MaterialInterface);

	UFUNCTION(BlueprintCallable, Category = "Game")
	static void RemovePostProcessBlendable(UPostProcessComponent* PostProcessComponent, TScriptInterface<IBlendableInterface> InBlendableObject);

	UFUNCTION(BlueprintCallable, Category = "Game")
	static void FlushLog();

    UFUNCTION(BlueprintCallable, Category = "Game")
    static void RemoveActorFromVisualLog(AActor* Actor);

	/** liujun : used for skipping the loading phase when profiling performance */
	UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject"), Category = "Utilities")
	static void ToggleStatUnit(UObject* WorldContextObject, bool bEnable);

    /** luzheng: used to print current used memory in auto test*/
    UFUNCTION()
    static void ShowCurrentMemoryUsed(UObject* WorldContextObject);

    /** luzheng: used to check unit state*/
    UFUNCTION()
    static bool IsStatUnitToggled(UObject* WorldContextObject);

	UFUNCTION(BlueprintCallable)
	static void SetActorNetCullDistanceSquared(AActor* Actor, float NetCullDistanceSquared);

	UFUNCTION(BlueprintCallable, Category = "Editor", meta = (CallInEditor = "true", DeterminesOutputType = "InComponentClass", DynamicOutputParam = "Components"))
	static void GetComponentsInCDOByClass(UClass* InActorClass, TSubclassOf<UActorComponent> InComponentClass, TArray<UActorComponent*>& Components, bool bFindOverridenComponent = false, bool bCreateOverridenComponentIfNotFind = false);

	UFUNCTION(BlueprintCallable, Category = "Editor", meta = (CallInEditor = "true", DeterminesOutputType = "InComponentClass", DynamicOutputParam = "Components"))
	static void GetChildrenComponentsInCDOByClass(UClass* InActorClass, UActorComponent* ParentComponent, bool bIncludeAllDescendants, TSubclassOf<UActorComponent> InComponentClass, TArray<UActorComponent*>& Components,
        bool bFindOverridenComponent = false, bool bCreateOverridenComponentIfNotFind = false);

    /**
    * liujun : disable/enable world rendering
    * in disable mode, the calling of BeginRenderingViewFamily will be skipped in UGameViewportClient::Draw
    * the disable mode will be set the first time this function is being called, then flip-flop in the subsequent calling
    */
    UFUNCTION()
    static void FlipFlopWorldRendering(const UObject* WorldContextObject);

    /** liujun : flip-flop the value of cvar t.FrameUnitPrintLogInterval between 0 and 1 */
    UFUNCTION()
    static void FlipFlopFrameUnitPrintLogInterval();

	UFUNCTION(BlueprintCallable, Category = "Timer")
    static void RecordTimeStart();

    UFUNCTION(BlueprintCallable, Category = "Timer")
    static void RecordTimeEnd(const FString& Msg, float Threshold = 0);

	UFUNCTION(BlueprintCallable, Category = "Timer")
	static float RecordTimeEndWithResult();
	
    UFUNCTION(BlueprintCallable, Category = "Game")
    static FString GetObjectClassName(UObject* Object);

	UFUNCTION(BlueprintCallable, Category = "Game")
	static void GetImpactPointFromHitResult(const FHitResult& Hit, FVector& ImpactPoint);

	UFUNCTION(BlueprintCallable, Category = "Game")
	static void GetImpactNormalFromHitResult(const FHitResult& Hit, FVector& ImpactNormal);

	UFUNCTION(BlueprintCallable, Category = "Game")
	static UPrimitiveComponent* GetComponentFromHitResult(const FHitResult& Hit);

	UFUNCTION(BlueprintPure, Category = "Editor", meta = (CallInEditor = "true"))
	static FString GetComponentTemplateNameSuffix();

    UFUNCTION(BlueprintCallable, Category = "Editor", meta = (CallInEditor = "true"))
    static bool GetColumnValueFromTable(const FString& TableName, const FString& KeyColumnName,
        const FString& KeyColumnValue, const FString& TargetColumnName, FString& OutValue);

    UFUNCTION(BlueprintCallable, Category = "Editor", meta = (CallInEditor = "true"))
    static bool GetColumnValuesFromTableByColumn(const FString& TableName, const FString& KeyColumnName,
        const FString& TargetColumnName, TArray<FString>& OutValue);

    UFUNCTION(BlueprintCallable, Category = "Editor", meta = (CallInEditor = "true"))
    static bool GetColumnValuesFromTableByColumns(const FString& TableName,
        const FString& KeyColumnName, const FString& KeyColumnValue,
        const TArray<FString>& TargetColumnNames, TArray<FString>& OutValue);

    UFUNCTION(BlueprintPure, Category = "Game")
    static bool IsInsideBox2D(const FBox2D& Box, const FVector2D& Point);

    UFUNCTION(BlueprintPure, Category = "Game")
    static int SegmentIntersectWithBox2D(const FVector& SegmentStartA, const FVector& SegmentEndA, const FBox2D& Box2D,
        FVector& OutIntersectionPointA, FVector& OutIntersectionPointB);

    UFUNCTION(BlueprintPure, Category = "Game")
    static float GetVectorToVectorDistance(const FVector& V1, const FVector& V2);

    UFUNCTION(BlueprintPure, Category = "Game")
    static float GetVectorToVectorDistanceSquared(const FVector& V1, const FVector& V2);

    UFUNCTION(BlueprintPure, Category = "Game")
    static bool GetLogicIdRangeInEditor(AActor* Actor, bool Refreshed, int& OutMinId, int& OutMaxId);

    UFUNCTION(BlueprintPure, Category = "Game")
    static FString GetOutermostName(UObject* Object);

    UFUNCTION(BlueprintCallable, meta = (WorldContext = "WorldContextObject"), Category = "Sound")
    static UAudioComponent* PlaySoundInClient(UObject* WorldContextObject, USoundBase* Sound, uint8 SoundType, const FVector& Location, AActor* SoundSource);

	UFUNCTION(BlueprintPure, Category="Math")
	static bool RotateNumberInRange(int32 Value, int32 RangeMin, int32 RangeMax, int32& NewNumber);

	UFUNCTION(BlueprintPure, Category = "Game")
	static void GetComponentFromCDO(TSubclassOf<AActor> InClass, const FString& ComponentName, UActorComponent*& OutComponent);

    UFUNCTION(BlueprintCallable, Category = "Game")
    static void SetComponentAllowTickOnDedicatedServer(UActorComponent* Component, bool bAllowTickOnDedicatedServer);

	UFUNCTION(BlueprintPure, Category = "Game", meta = (DeterminesOutputType = "InClass", DynamicOutputParam = "OutObject"))
	static void GetMutableDefaultObject(TSubclassOf<UObject> InClass, UObject*& OutObject);

	UFUNCTION(BlueprintPure, Category = "Math|Random")
	static FVector RandomPointInEllipsoid(float A, float B, float C, float SigmaRatio);

	UFUNCTION(BlueprintPure, Category = "Math|Random")
	static FVector RandomPointInEllipsoidWithTransform(float A, float B, float C, float SigmaRatio, const FTransform& Transform);

	//preload levels
	UFUNCTION(BlueprintCallable, Category = "Game", meta = (WorldContext = "WorldContextObject"))
	static void PreLoadLevelStreamingPackageForPoint(UWorld* InWorld, const FVector& InLoc);


	//used for change skeletalmeshcomponent draw distance on landing
	UFUNCTION(BlueprintCallable, Category = "Game", meta = (WorldContext = "WorldContextObject"))
	static void ResetCharacterSkeletalDrawDistance(UObject* WorldContextObject);
	//yjz end

    UFUNCTION(BlueprintCallable, Category = "Game", meta = (WorldContext = "WorldContextObject", CallableWithoutWorldContext, AdvancedDisplay = "2", DevelopmentOnly))
    static void PrintDebugMessage(UObject* WorldContextObject, const FString& Category, float TimeToDisplay, FColor DisplayColor, const FString& DebugMessage);

    UFUNCTION(BlueprintCallable, Category = "Game")
    static FString GetAvatarPartResourceData(int32 PartID, const FString& Key);

    UFUNCTION(BlueprintCallable, Category = "Game")
    static const bool IsHeadlessClient();

    UFUNCTION()
    static void ChangePlayerMeshTranslationOffset(UCharacterMovementComponent* CharacterMovement, float MeshAdjust);

    UFUNCTION()
    static void ChangePlayerMeshRotationOffset(UCharacterMovementComponent* CharacterMovement, FRotator Rotation);

	UFUNCTION(BlueprintCallable, Category = "Game")
	static FVector2D GetViewportSizeWithScale(UObject* WorldContextObject);

    UFUNCTION(BlueprintCallable, Category = "Game")
    static void ClipboardCopy(const FString& Str);

    UFUNCTION(BlueprintCallable, Category = "Game")
    static void ClipboardPaste(FString& Dest);

    UFUNCTION(BlueprintCallable, Category = "Game", meta = (WorldContext = "WorldContextObject"))
    static FVector GetAISafePosition(UObject* WorldContextObject, const FVector& Origin, float Radius, float AddZ, float MinusZ);

	UFUNCTION(BlueprintCallable, Category = "Game")
	static void SetLargeCoordPrecisionOptimize(AActor* Actor, bool Value);

	UFUNCTION(BlueprintCallable, Category = "Game")
	static void HideActorHairComponent(AActor* Actor, bool Value);

    UFUNCTION(BlueprintCallable, Category = "Game", meta = (WorldContext = "WorldContextObject"))
    static void GetClassFunctionAndPropertyNames(const FString& Name, TArray<FName>& OutPropertyNames, TArray<FName>& OutFunctionNames);

    UFUNCTION(BlueprintCallable, Category = "Game", meta = (WorldContext = "WorldContextObject"))
    static void GetEnumPropertyNames(const FString& Name, TArray<FName>& OutPropertyNames);

    UFUNCTION(BlueprintCallable, Category = "Dump", meta = (WorldContext = "WorldContextObject"))
    static void DumpActiveSounds(UObject* WorldContextObject);

    UFUNCTION(BlueprintPure, Category = "Actor Speed")
    static bool IsActorSpeedGreaterThan(AActor *Actor, float Speed, bool bIngoreZ = false);


    UFUNCTION(BlueprintPure, Category = "Actor Speed")
    static float GetActorSpeed(AActor *Actor, bool bIngoreZ = false);

    UFUNCTION(BlueprintPure, Category = "Config")
    static bool GetGameConfigBool(const FString& Section, const FString& Key, bool DefaultValue);

    UFUNCTION(BlueprintPure, Category = "Config")
    static int GetGameConfigInt(const FString& Section, const FString& Key, int DefaultValue);

	UFUNCTION(BlueprintCallable, Category = "Game")
	static int32 GetCVarValueOnAnyThreadInt(const FString& CVarStr);

	UFUNCTION(BlueprintCallable, Category = "Game")
	static float GetCVarValueOnAnyThreadFloat(const FString& CVarStr);

    UFUNCTION(BlueprintCallable, Category = "Game")
    static float GetPlatformMilliseconds();

    UFUNCTION(BlueprintPure, Category = "Game")
    static float GetSoundMaxDistance(USoundBase* Sound);

	UFUNCTION(BlueprintCallable, Category = "Game")
	static void ReloadLocalizationResources();

	UFUNCTION(BlueprintPure, Category = "User Interface|Geometry", meta = (WorldContext = "WorldContextObject", DisplayName = "ScreenToLocal"))
	static void ScreenToWidgetLocal(UObject* WorldContextObject, const FGeometry& Geometry, FVector2D ScreenPosition, FVector2D& LocalCoordinate);

	UFUNCTION(BlueprintPure, Category = "User Interface|Geometry", meta = (WorldContext = "WorldContextObject", DisplayName = "ScreenToAbsolute"))
	static void ScreenToWidgetAbsolute(UObject* WorldContextObject, FVector2D ScreenPosition, FVector2D& AbsoluteCoordinate);

    UFUNCTION(BlueprintPure, Category = "Module")
    static bool IsModuleLoaded(const FName ModleName);

	UFUNCTION(BlueprintCallable, Category = "Game")
	static void HideVirtualKeyboard();

    UFUNCTION(BlueprintPure, meta = (WorldContext = "WorldContextObject"), Category = "Game")
    static int32 CheckAttackIllegal(UObject* WorldContextObject, const FVector& StartPos, const FVector& CameraPos);

    UFUNCTION(BlueprintCallable, Category = "Game", meta = (WorldContext = "WorldContextObject"))
    static float GetCollisionDistance(UObject* WorldContextObject, float Radius, const FVector& From, const FVector& To);

	// Returns human character, when is in vehicle, get the human character from vehicle
	UFUNCTION(BlueprintCallable, Category = "Game")
	static class APawn* GetHumanCharacter(class APawn* Pawn);

	UFUNCTION(BlueprintCallable, BlueprintAuthorityOnly, Category = "Game|Damage")
	static bool ApplyRadialDamageWithFalloffEx(const UObject* WorldContextObject, float BaseDamage, float MinimumDamage, const FVector& Origin, float DamageInnerRadius, float DamageOuterRadius, float DamageFalloff, TSubclassOf<class UDamageType> DamageTypeClass, const TArray<AActor*>& IgnoreActors, AActor* DamageCauser = NULL, AController* InstigatedByController = NULL, ECollisionChannel DamagePreventionChannel = ECC_Visibility, AActor* DamageLauncher = NULL);

	UFUNCTION(BlueprintCallable, BlueprintAuthorityOnly, Category = "Game|Damage")
	static bool ApplyRadialDamageWithCurveEx(const UObject* WorldContextObject, float BaseDamage, const FVector& Origin, float DamageRadius, UCurveFloat* DamageCurve, TSubclassOf<class UDamageType> DamageTypeClass, const TArray<AActor*>& IgnoreActors, AActor* DamageCauser = NULL, AController* InstigatedByController = NULL, ECollisionChannel DamagePreventionChannel = ECC_Visibility, AActor* DamageLauncher = NULL);

	UFUNCTION(BlueprintPure, Category = "Game")
	static FString GetClassPathName(UClass* Class);

	UFUNCTION(BlueprintPure, Category = "Game", meta = (WorldContext = "WorldContextObject"))
	static int32 GetPing(UObject* WorldContextObject);

    UFUNCTION(BlueprintPure, Category = "Transform")
    static FTransform GetComponentSlotRelativeTransform(USceneComponent* Component,const FName& SlotName, const FTransform& ComponentRelativeTransform);

    UFUNCTION(BlueprintPure, meta = (WorldContext = "WorldContextObject"))
    static FString GetHost(UObject* WorldContextObject);

    UFUNCTION(BlueprintPure, meta = (WorldContext = "WorldContextObject"))
    static FString GetPort(UObject* WorldContextObject);

    UFUNCTION(BlueprintCallable, Category = "Utilities|String")
    static void AddOnScreenDebugMessage(int32 Key, float TimeToDisplay, FLinearColor DisplayColor, const FString& DebugMessage, bool bNewerOnTop = true, const FVector2D& TextScale = FVector2D::UnitVector);

    UFUNCTION(BlueprintPure, Category = "CommandLine")
    static bool HasCommandLineParam(const FString& Param);

    UFUNCTION(BlueprintPure, Category = "Game")
    static bool CheckIsInSquaredDistance(AActor* ActorA, AActor* ActorB, float SquaredDistance);

    //资源点检测函数
    UFUNCTION(BlueprintCallable, Category = "Editor", meta = (CallInEditor = "true"))
    static bool IsValidResourcePos(const UObject* WorldContextObject, const FVector& ResourcePos, float StartOffset, float EndOffset, float LandscapeStartOffset, float LandscapeEndOffset, FVector& OutPos);

    UFUNCTION(BlueprintPure, Category = "Game")
    static int GetFPS();

    UFUNCTION(BlueprintPure, Category = "Game")
    static float GetAdjustRotationPitch(AActor* Actor, const FVector& HitNormal);

    UFUNCTION(BlueprintCallable, Category = "Game")
    static void SetUseMouseForTouch(bool bUseMouseForTouch);

    UFUNCTION(BlueprintPure, Category = "Game", meta = (WorldContext = "WorldContextObject"))
    static APlayerController* GetFirstLocalPlayerController(UObject* WorldContextObject);

    UFUNCTION(BlueprintCallable, Category = "Game")
    static void UpdateSkeletalComponentAnim(USkeletalMeshComponent* SkeletalMeshComponent);
  
    UFUNCTION(BlueprintCallable, Category = "Game")
    static bool IsGarbageCollecting();


	UFUNCTION(BlueprintCallable, Category = "Game")
    static void TestShaderCoreReload();
    
    UFUNCTION(BlueprintCallable, Category = "Game")
	static bool LineIntersection(const FVector& BoxOrigin, const FVector& BoxExtent, const FVector& LineStart, const FVector& LineEnd);

	UFUNCTION(BlueprintCallable, Category = "Game")
	static void LoadLevelsImmediatelyByLocation(UWorld* InWorld, const FVector& InLoc);

    UFUNCTION(BlueprintCallable, Category = "Game")
    static void ExportRootMotion(const UAnimSequenceBase* RootMotionSouce, float StopTime, TArray<FVector>& OutPosition);

	UFUNCTION(BlueprintCallable, Category = "Game")
	static float GetDirectionFromActor(AActor* StartActor, AActor* TargetActor);

	UFUNCTION(BlueprintPure, Category = "Game")
	static bool IsPlayingSlotAnimation(const class UAnimInstance* AnimInstance, FName SlotNodeName);

    UFUNCTION(BlueprintCallable, Category = "Game")
    static FString GetProjectLogDir();

    UFUNCTION(BlueprintCallable, Category = "Game")
    static bool WriteFileLines(const TArray<FString>& Lines, const FString& Filename);
};
