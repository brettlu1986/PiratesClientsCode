// Fill out your copyright notice in the Description page of Project Settings.

#include "ExtendBlueprintFunctions.h"
#include "Common.h"
#include "JsonConverter/JsonConvertScriptStruct.h"
#include "Particles/ParticleSystemComponent.h"
#include "Kismet/KismetSystemLibrary.h"
#include "Kismet/KismetMathLibrary.h"
#include "Kismet/GameplayStatics.h"
#include "LevelUtils.h"
#include "Engine/LevelScriptBlueprint.h"
#include "LevelSequenceActor.h"
#include "Math/UnitConversion.h"
#include "Game/GameCommon.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "Game/Delegates/PiratesGameMiscDelegate.h"
#include <random>
#include "MovieSceneObjectBindingID.h"
#include "Components/EmitterActivateComponent.h"
#include "Sections/MovieSceneSubSection.h"
#include "Tracks/MovieSceneSubTrack.h"
#include "Util/ComponentInCDOCollector.h"
#include "Shell/EngineExtShell.h"
#include "VisualLogger/VisualLogger.h"
#include "TabFile/Base/TabFile.h"
#include "NavigationSystem.h"
#include "Shell/CommonShell.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "Game/Delegates/PiratesGameMiscDelegate.h"
#include "Engine/InheritableComponentHandler.h"
#include "UObject/UObjectGlobals.h"
#include "KMActor.h"
#include "KMPawn.h"
#include "KMCharacter.h"
#include "Pawns/PiratesMountCharacter.h"
#include "Camera/KMGameCameraManager.h"
#include "TabFile/GameAvatarPartTabFile.h"
#include "Blueprint/WidgetLayoutLibrary.h"
#include "HAL/PlatformApplicationMisc.h"
#include "Game/Battle/PiratesGridTypeManager.h"
#include "AudioDevice.h"
#include "Slate/SGameLayerManager.h"
#include "Framework/Application/SlateApplication.h"
#include "KMParticleSignificance.h"
#include "SocketSubsystem.h"
#include "Landscape.h"
#include "Framework/Application/SlateApplication.h"
#include "Engine/GameInstance.h"
#include "UObject/GarbageCollection.h"
#include "Game/GameEngineExt.h"

#include "ShaderCodeLibrary.h"
#include "ShaderPipelineCache.h"
#include "PakFile/Public/IPlatformFilePak.h"

DEFINE_LOG_CATEGORY_CLASS(UExtendBlueprintFunctions, ExtendBPFuncLibLog);

static int32 GXSJForbidParticleSystemPool = 0;
static FAutoConsoleVariableRef CVarXSJForbidParticleSystemPool(
	TEXT("xsj.ForbidParticleSystemPool"),
	GXSJForbidParticleSystemPool,
	TEXT("Forbid Particle System Pool.")
);

UObject* UExtendBlueprintFunctions::CreateObjectFromBlueprint(TSubclassOf<UObject> UC)
{
	UObject* tempObject = StaticConstructObject_Internal(UC);

	return tempObject;
}

UObject* UExtendBlueprintFunctions::CreateObject(TSubclassOf<UObject> UC, UObject *Outer)
{
	if (!IsValid(UC))
	{
		UE_LOG(ExtendBPFuncLibLog, Error, TEXT("CreateObject failed, UC is null."))
		return nullptr;
	}
    if (!IsValid(Outer))
    {
        Outer = GetTransientPackage();
    }
    UObject* RetObject = NewObject<UObject>(Outer, UC);

    return RetObject;
}


UObject* UExtendBlueprintFunctions::CreateObjectWithName(TSubclassOf<UObject> UC, UObject *Outer, FName Name)
{
	if (!IsValid(Outer))
	{
		Outer = GetTransientPackage();
	}
    UObject* RetObject = NewObject<UObject>(Outer, UC, Name);

	return RetObject;
}

bool UExtendBlueprintFunctions::IsActorOnDedicatedServer(AActor *Actor)
{
	return UKismetSystemLibrary::IsDedicatedServer(Actor);
}

int32 UExtendBlueprintFunctions::GetParticleEmitterCount(UParticleSystemComponent *ParticleComponent)
{
	int32 Ret = 0;
	if (IsValid(ParticleComponent))
	{
		Ret = ParticleComponent->EmitterInstances.Num();
	}
	return Ret;
}

void UExtendBlueprintFunctions::ClientTravel(UObject* WorldContextObject, const FString &TargetMap)
{
	ReturnIfNullUObject(WorldContextObject);
	APlayerController* PlayerController = nullptr;
	UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull);
	if (World != nullptr)
	{
		FConstPlayerControllerIterator Iterator = World->GetPlayerControllerIterator();
		PlayerController = (*Iterator).Get();
		PlayerController->ClientTravel(TargetMap, ETravelType::TRAVEL_Relative);
	}
}

void UExtendBlueprintFunctions::ServerTravel(UObject* WorldContextObject, const FString &TargetMap)
{
	UWorld *World = GEngine->GetWorldFromContextObjectChecked(WorldContextObject);
	auto GameMode = World->GetAuthGameMode();
	if (GameMode)
	{
		GameMode->bUseSeamlessTravel = true;
	}
	World->ServerTravel(TargetMap);
}

int32 UExtendBlueprintFunctions::GetClientConnectionsNum(UObject* WorldContextObject)
{
	UWorld *World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);
	if (World && World->NetDriver)
	{
		return World->NetDriver->ClientConnections.Num();
	}
	else
	{
		return 0;
	}
}

float UExtendBlueprintFunctions::GetMontageSectionLength(const UAnimMontage *Montage, FName SectionName)
{
	float Length = 0.0f;
	do
	{
		if (!Montage)
		{
			break;
		}

		const int32 SectionIndex = Montage->GetSectionIndex(SectionName);
		if (!Montage->IsValidSectionIndex(SectionIndex))
		{
			break;
		}
		Length = Montage->GetSectionLength(SectionIndex);
	} while (false);

	return Length;
}

void UExtendBlueprintFunctions::GetMontageSectionStartEndTime(const UAnimMontage *Montage, FName SectionName, float& OutStartTime, float& OutEndTime)
{
    do
    {
        if (!Montage)
        {
            break;
        }

        const int32 SectionIndex = Montage->GetSectionIndex(SectionName);
        if (!Montage->IsValidSectionIndex(SectionIndex))
        {
            break;
        }
        Montage->GetSectionStartAndEndTime(SectionIndex, OutStartTime, OutEndTime);
    } while (false);

}


float UExtendBlueprintFunctions::GetMontageLength(UAnimMontage *Montage)
{
    if (!Montage)
    {
        return 0;
    }

    float Length = Montage->CalculateSequenceLength();
    return Length;
}

float UExtendBlueprintFunctions::GetAnimSequenceLength(UAnimSequenceBase *AnimSequence)
{
	return AnimSequence->SequenceLength;
}

void UExtendBlueprintFunctions::RefreshBoneTransform(USkeletalMeshComponent *Mesh)
{
	Mesh->RefreshBoneTransforms();
}

UObject* UExtendBlueprintFunctions::LoadObjectFromAssetPath(const FString& Path)
{
	//return StaticLoadObject(UObject::StaticClass(), NULL, *Path);
    return UEngineExtShell::StaticLoadObjectWithoutFlush(Path);
}

UClass* UExtendBlueprintFunctions::LoadClassFromAssetPath(const FString& Path)
{
	return Cast<UClass>(UEngineExtShell::StaticLoadObjectWithoutFlush(Path));
}

void UExtendBlueprintFunctions::Generic_GetContentFromUStruct(void* Structure, const FStructProperty* StructProperty, const FName &PropertyName, bool &Success, FString& Str_R, UObject *&Obj_R, int32 &Int_R, float &Float_R, bool &Bool_R)
{
	Success = JsonConvertScriptStruct::GetScriptStructPropertyContent(Structure, StructProperty, PropertyName, Str_R, Obj_R, Int_R, Float_R, Bool_R);
}

void UExtendBlueprintFunctions::Generic_ConvertScriptStructToJsonStr(void* Structure, const FStructProperty* StructProperty, FString& OutStr)
{
	JsonConvertScriptStruct::ConvertScriptStructToJsonStr(Structure, StructProperty, OutStr);
}

void UExtendBlueprintFunctions::Generic_ConvertJsonStrToScriptStruct(const FString& inStr, void* Structure, const FStructProperty* StructProperty)
{
	JsonConvertScriptStruct::ConvertJsonStrToScriptStruct(inStr, Structure, StructProperty);
}

FString UExtendBlueprintFunctions::ConvertToStorageSizeDesc(int Size)
{
    bool bUseKB = Size < (1024 * 1024);
    double UpdateSizeValue = FUnitConversion::Convert((double)Size, EUnit::Bytes,
        bUseKB ? EUnit::Kilobytes
        : EUnit::Megabytes);
    return FString::Printf(TEXT("%.2f%s"), UpdateSizeValue, bUseKB ? TEXT("KB") : TEXT("MB"));
}

FString UExtendBlueprintFunctions::GetDeviceId()
{
    return FPlatformMisc::GetDeviceId();
}

TArray<AActor *> UExtendBlueprintFunctions::GetConnectedPlayerActors(UObject* WorldContextObject)
{
	APlayerController* LocalPlayerController = NULL;
	TArray<AActor *> ActorArray;
	UWorld *World = GEngine->GetWorldFromContextObjectChecked(WorldContextObject);
	for (FConstPlayerControllerIterator Iterator = World->GetPlayerControllerIterator(); Iterator; ++Iterator)
	{
		APlayerController* PlayerController = (*Iterator).Get();
		if (Cast<UNetConnection>(PlayerController->Player) != NULL)
		{
			// remote player
			APawn* ControlledPawn = PlayerController->GetPawn();
			if (ControlledPawn != nullptr)
			{
				ActorArray.Add(ControlledPawn);
			}
		}
		else
		{
			// local player
			LocalPlayerController = PlayerController;
			APawn* ControlledPawn = PlayerController->GetPawn();
			if (ControlledPawn != nullptr)
			{
				ActorArray.Add(ControlledPawn);
			}
		}
	}
	return ActorArray;
}

void UExtendBlueprintFunctions::ToggleLevelStreaming(UObject* WorldContextObject, bool Enable)
{
	UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);
	if (World != nullptr)
	{
		World->bIsLevelStreamingFrozen = !Enable;
	}
}

AActor* UExtendBlueprintFunctions::FindActorWithNetGUID(UObject* WorldContextObject, uint32 NetGUID)
{
    AActor* RetActor = nullptr;
    FNetworkGUID NetGUIDStruct(NetGUID);
    if (NetGUIDStruct.IsValid() && !NetGUIDStruct.IsDefault())
    {
        UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);
        if (World != nullptr)
        {
            auto NetDriver = World->GetNetDriver();
            RetActor = Cast<AActor>(NetDriver->GuidCache->GetObjectFromNetGUID(NetGUIDStruct, true));
        }
    }
    return RetActor;
}

ULevelStreaming* UExtendBlueprintFunctions::LoadSubLevelDynamic(UObject* WorldContextObject, const FString& PackageName, FVector Location, FRotator Rotation)
{
    ReturnIfNullUObject(WorldContextObject, nullptr);
    ULevelStreaming* StreamingLevel = UGameplayStatics::GetStreamingLevel(WorldContextObject, *PackageName);
    UWorld* const World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);
    ReturnIfNullUObject(World, nullptr);

    if (!IsValid(StreamingLevel))
    {
        //Long Package Name
        FString LongLevelPackageName = FPackageName::FilenameToLongPackageName(PackageName);
        for (int i = 0; i < World->GetStreamingLevels().Num(); i++)
        {
            StreamingLevel = World->GetStreamingLevels()[i];
            if (StreamingLevel->PackageNameToLoad == *LongLevelPackageName)
                return StreamingLevel;
        }

        StreamingLevel = NewObject<ULevelStreamingDynamic>(World, ULevelStreamingDynamic::StaticClass());
        ReturnIfNullUObject(StreamingLevel, nullptr);


        StreamingLevel->SetWorldAssetByPackageName(FName(*LongLevelPackageName));

        // Rename when play in editor
        if (World->IsPlayInEditor())
        {
            FWorldContext WorldContext = GEngine->GetWorldContextFromWorldChecked(World);
            StreamingLevel->RenameForPIE(WorldContext.PIEInstance);
        }


        StreamingLevel->LevelColor = FColor::MakeRandomColor();

        //Set Transform
        StreamingLevel->LevelTransform = FTransform(Rotation, Location);
        StreamingLevel->PackageNameToLoad = *PackageName;

        ReturnIfFalse(FPackageName::DoesPackageExist(StreamingLevel->PackageNameToLoad.ToString(), nullptr, nullptr), nullptr);
        StreamingLevel->PackageNameToLoad = FName(*LongLevelPackageName);
        World->AddStreamingLevel(StreamingLevel);

		//Set Visible
		StreamingLevel->SetShouldBeLoaded(true);
		StreamingLevel->SetShouldBeVisible(true);
		StreamingLevel->bShouldBlockOnLoad = false;
		World->UpdateLevelStreaming();
		/*FLevelUtils::ApplyLevelTransform(World->GetCurrentLevel(), StreamingLevel->LevelTransform, false);*/

    }
    else
    {
        StreamingLevel->SetShouldBeLoaded(true);
        StreamingLevel->SetShouldBeVisible(true);
        World->UpdateLevelStreaming();
    }

    return StreamingLevel;
}

ULevelStreaming* UExtendBlueprintFunctions::LoadSublevelSyncDynamic(UObject* WorldContextObject, const FString& PackageName, FVector Location /* = FVector::ZeroVector */, FRotator Rotation /* = FRotator::ZeroRotator */)
{
	UPackage* LoadedPak = LoadPackage(nullptr, *PackageName, LOAD_None);

	ReturnIfNullUObject(WorldContextObject, nullptr);
	ULevelStreaming* StreamingLevel = UGameplayStatics::GetStreamingLevel(WorldContextObject, *PackageName);
	UWorld* const World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);
	ReturnIfNullUObject(World, nullptr);

	if (!IsValid(StreamingLevel))
	{
        FString LongLevelPackageName = FPackageName::FilenameToLongPackageName(PackageName);
        for (int i = 0; i < World->GetStreamingLevels().Num(); i++)
        {
            StreamingLevel = World->GetStreamingLevels()[i];
            if (StreamingLevel->PackageNameToLoad == *LongLevelPackageName)
                return StreamingLevel;
        }

		StreamingLevel = NewObject<ULevelStreamingDynamic>(World, ULevelStreamingDynamic::StaticClass());
		ReturnIfNullUObject(StreamingLevel, nullptr);

		StreamingLevel->SetWorldAssetByPackageName(FName(*LongLevelPackageName));

		// Rename when play in editor
		if (World->IsPlayInEditor())
		{
			FWorldContext WorldContext = GEngine->GetWorldContextFromWorldChecked(World);
			StreamingLevel->RenameForPIE(WorldContext.PIEInstance);
		}

		//Set Visible
		StreamingLevel->SetShouldBeLoaded(true);
		StreamingLevel->SetShouldBeVisible(true);
		StreamingLevel->bShouldBlockOnLoad = false;
		StreamingLevel->LevelColor = FColor::MakeRandomColor();

		//Set Transform
		StreamingLevel->LevelTransform = FTransform(Rotation, Location);
		StreamingLevel->PackageNameToLoad = *PackageName;

		ReturnIfFalse(FPackageName::DoesPackageExist(StreamingLevel->PackageNameToLoad.ToString(), nullptr, nullptr), nullptr);
		StreamingLevel->PackageNameToLoad = FName(*LongLevelPackageName);
		World->AddStreamingLevel(StreamingLevel);

		World->UpdateLevelStreaming();

	}
	else
	{
		StreamingLevel->SetShouldBeLoaded(true);
		StreamingLevel->SetShouldBeVisible(true);
		World->UpdateLevelStreaming();
	}

	return StreamingLevel;
}

void UExtendBlueprintFunctions::SetLevelClientOnlyVisible(ULevelStreaming* StreamingLevel, bool bClientOnlyVisible)
{
    if (IsValid(StreamingLevel))
    {
        ULevel* Level = StreamingLevel->GetLoadedLevel();
        if (Level != NULL)
        {
            Level->bClientOnlyVisible = bClientOnlyVisible;
        }
    }
}

void UExtendBlueprintFunctions::UnloadSubLevelDynamic(UObject* WorldContextObject, const FString& PackageName)
{
    ReturnIfNullUObject(WorldContextObject);
    FString LongLevelPackageName = FPackageName::FilenameToLongPackageName(PackageName);
    ULevelStreaming* StreamingLevel = UGameplayStatics::GetStreamingLevel(WorldContextObject, *LongLevelPackageName);
    ReturnIfNullUObject(StreamingLevel);

    UWorld* const World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);
    ReturnIfNullUObject(World);

    StreamingLevel->SetShouldBeLoaded(false);
    StreamingLevel->SetShouldBeVisible(false);
	StreamingLevel->bShouldBlockOnUnload = false;
	//使用UE4自己的状态机控制移除streaming
	//此处放弃原来添加的World->RemoveStreamingLevel(StreamingLevel)的逻辑
	StreamingLevel->SetIsRequestingUnloadAndRemoval(true);
    World->UpdateLevelStreaming();

	//此处逻辑去掉，使用UE4自己的状态机控制移除streaming
    //World->RemoveStreamingLevel(StreamingLevel);
}

AActor* UExtendBlueprintFunctions::GetWorldActorByName(UObject* WorldContextObject, const FName& Tag)
{
    UWorld* const World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);
    ReturnIfNullUObject(World, nullptr);

    for (ULevel* Level : World->GetLevels())
    {
        for (AActor* Actor : Level->Actors)
        {
            if (Actor && Actor->Tags.Contains(Tag))
            {
                return Actor;
            }
        }
    }

    return nullptr;
}

AActor* UExtendBlueprintFunctions::GetLevelActorByTag(ULevelStreaming* StreamingLevel, const FName& Tag)
{
    ReturnIfNullUObject(StreamingLevel, nullptr);
    ULevel* LoadedLevel = StreamingLevel->GetLoadedLevel();
    ReturnIfNullUObject(LoadedLevel, nullptr);

    for (AActor* Actor : LoadedLevel->Actors)
    {
        if (Actor && Actor->Tags.Contains(Tag))
        {
            return Actor;
        }
    }
    return nullptr;
}

TArray<AActor*> UExtendBlueprintFunctions::GetLevelActorsByTag(UObject* WorldContextObject, const FName& Tag)
{
    TArray<AActor*> Actors;

    UWorld* const World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);
    ReturnIfNullUObject(World, Actors);

    for (ULevel* Level : World->GetLevels())
    {
        for (AActor* Actor : Level->Actors)
        {
            if (Actor && Actor->Tags.Contains(Tag))
            {
                Actors.Add(Actor);
                //return Actor;
            }
        }
    }

    return Actors;
}

FText UExtendBlueprintFunctions::FormatText(const FText& Fmt, const TArray<FText>& Args)
{
	FFormatOrderedArguments OrderedArgs;
	for (auto IterArgs = Args.CreateConstIterator(); IterArgs; ++IterArgs)
	{
		OrderedArgs.Add(*IterArgs);
	}
	FText returnText = FText::Format(Fmt, OrderedArgs);
	return returnText;
}

FText UExtendBlueprintFunctions::FormatTextByName(const FText& Fmt, const TArray<FString>& Names, const TArray<FText>& Args)
{
	int32 ParamCount = FMath::Min(Names.Num(), Args.Num());
	FFormatNamedArguments NamedArgs;
	for (int i = 0; i < ParamCount; ++i)
	{
		NamedArgs.Add(Names[i], Args[i]);
	}
	FText returnText = FText::Format(Fmt, NamedArgs);
	return returnText;
}

void UExtendBlueprintFunctions::SetCurrentCulture(const FString& Language)
{
	FInternationalization::Get().SetCurrentCulture(Language);
}

const FString& UExtendBlueprintFunctions::GetCurrentCultureName()
{
	return FInternationalization::Get().GetCurrentCulture()->GetName();
}

int32 UExtendBlueprintFunctions::GetObjectUniqueID(UObject* Object)
{
	ReturnIfNullUObject(Object, -1);
	return Object->GetUniqueID();
}


void UExtendBlueprintFunctions::GetActorsInSectorRange(const UObject* WorldContextObject, TSubclassOf<AActor> ActorClass, const FVector& Location, const FRotator& Rotation, float Radius, float Angle, TArray<AActor*>& OutActors)
{
    QUICK_SCOPE_CYCLE_COUNTER(UGameplayStatics_GetAllActorsOfClass);
    OutActors.Reset();

    UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);

    // We do nothing if no is class provided, rather than giving ALL actors!
    if (ActorClass && World)
    {
        for (TActorIterator<AActor> It(World, ActorClass); It; ++It)
        {
            AActor* Actor = *It;
            if (Actor->IsPendingKill())
            {
                continue;
            }
            const FVector& ActorLocation = Actor->GetActorLocation();
            FVector Distance = ActorLocation - Location;
            if (Distance.Size() > Radius)
            {
                continue;
            }
            // check angle
            if (Angle < 360)
            {
                float CurAngle = FMath::RadiansToDegrees(FMath::Acos(Rotation.Vector().CosineAngle2D(Distance)));
                if (CurAngle > Angle / 2)
                {
                    continue;
                }
            }
            OutActors.Add(Actor);
        }
    }
}


void UExtendBlueprintFunctions::GetPawnsInSectorRange(UObject* WorldContextObject, const FVector& Location, const FRotator& Rotation, float Radius, float Angle, TArray<APawn*>& OutPawns)
{
	OutPawns.Empty();

	UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);
	ReturnIfNullUObject(World);

	for (TActorIterator<APawn> It(World, APawn::StaticClass()); It; ++It)
	{
		APawn* Pawn = *It;
		if (Pawn->IsPendingKill())
		{
			continue;
		}
		// check distance
		const FVector& ActorLocation = Pawn->GetActorLocation();
		FVector Distance = ActorLocation - Location;
		if (Distance.Size() > Radius)
		{
			continue;
		}
		// check angle
		if (Angle < 360)
		{
			float CurAngle = FMath::RadiansToDegrees(FMath::Acos(Rotation.Vector().CosineAngle2D(Distance)));
			if (CurAngle > Angle / 2)
			{
				continue;
			}
		}
		OutPawns.Add(Pawn);
	}
}

void UExtendBlueprintFunctions::GetPawnsInCircleRange(UObject* WorldContextObject, const FVector& Location, float Radius, TArray<APawn*>& OutPawns)
{
	return GetPawnsInSectorRange(WorldContextObject, Location, FRotator(), Radius, 360, OutPawns);
}

void UExtendBlueprintFunctions::GetPawnsInRectRange(UObject* WorldContextObject, const FVector& Location, const FRotator& Rotation, const FVector& BoxExtent, TArray<APawn*>& OutPawns)
{
	OutPawns.Empty();

	static FName BoxOverlapComponentsName(TEXT("BoxOverlapComponents"));
	FCollisionQueryParams Params(BoxOverlapComponentsName, false);

	TArray<FOverlapResult> Overlaps;
	UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);
	if (World != nullptr)
	{
		World->OverlapMultiByChannel(Overlaps, Location, Rotation.Quaternion(), ECC_Visibility, FCollisionShape::MakeBox(BoxExtent), Params);
	}

	TArray<UPrimitiveComponent*> OverlapComponents;
	for (int32 OverlapIdx = 0; OverlapIdx < Overlaps.Num(); ++OverlapIdx)
	{
		FOverlapResult const& O = Overlaps[OverlapIdx];
		if (O.Component.IsValid())
		{
			OverlapComponents.Add(O.Component.Get());
		}
	}

	if (OverlapComponents.Num() > 0)
	{
		for (int32 CompIdx = 0; CompIdx < OverlapComponents.Num(); ++CompIdx)
		{
			UPrimitiveComponent* const C = OverlapComponents[CompIdx];
			if (C)
			{
				APawn* const Owner = Cast<APawn>(C->GetOwner());
				if (Owner)
				{
					OutPawns.AddUnique(Owner);
				}
			}
		}
	}
}
FVector UExtendBlueprintFunctions::GetForwardLocationByDistance(const FVector& Location, const FRotator& Rotation, float Distance)
{
	const FVector& ForwardVector = UKismetMathLibrary::GetForwardVector(Rotation);
	const FVector& NormalizeVector = UKismetMathLibrary::Normal(ForwardVector);
	return Location + NormalizeVector * Distance;
}

ALevelSequenceActor* UExtendBlueprintFunctions::GetSequenceActorFromPlayer(ULevelSequencePlayer* InPlayer)
{
    if (!InPlayer)
        return NULL;
    ALevelSequenceActor* LevelSequenceActor = Cast<ALevelSequenceActor>(InPlayer->GetOuter());
    return LevelSequenceActor;
}

void UExtendBlueprintFunctions::GetAllTexture2D(TArray<UTexture2D*>& OutTextures)
{
	OutTextures.Empty();

	for (TObjectIterator<UTexture2D> It; It; ++It)
	{
		UTexture2D* Texture = *It;
		if (!Texture->IsPendingKill())
		{
			OutTextures.Add(Texture);
		}
	}
}

void UExtendBlueprintFunctions::GetAllFunctionNameByClass(TArray<FString>& OutStrings, const UClass* Class)
{
	OutStrings.Empty();
	for (TFieldIterator<UFunction> FuncIt(Class); FuncIt; ++FuncIt)
	{
		UFunction* Function = *FuncIt;
		if ((Function->FunctionFlags & FUNC_BlueprintCallable))
		{
			OutStrings.Add(Function->GetName());
		}
	}
}

void UExtendBlueprintFunctions::SetIntPropertyValueByNames(UObject* Object, int32 Value, const TArray<FString>& PropertyNames)
{
    ReturnIfNullUObject(Object);
    for (const FString& Name: PropertyNames)
    {
        FIntProperty* IntProperty = CastField<FIntProperty>(Object->GetClass()->FindPropertyByName(*Name));
        if (IntProperty)
        {
            int32* KeyPropData = IntProperty->ContainerPtrToValuePtr<int32>(Object);
            if (KeyPropData)
            {
                *KeyPropData = Value;
            }
        }
    }
}

FString UExtendBlueprintFunctions::CallGetDebugStringFunction(AActor* DebuggingActor, const FString& FunctionName, UClass* BPLibClass)
{
    UFunction* func;
    FString result;

    func = BPLibClass ? BPLibClass->FindFunctionByName(FName(*FunctionName)) : nullptr;
    if (func && func->NumParms == 3)
    {
        struct FGetDebugString_Parms
        {
            AActor* DebuggingActor;
            UWorld* World;
            FString OutDebugString;
        } GetDebugStringParams;
        GetDebugStringParams.DebuggingActor = DebuggingActor;
        GetDebugStringParams.World = DebuggingActor->GetWorld();
        BPLibClass->ProcessEvent(func, &GetDebugStringParams);
        result = GetDebugStringParams.OutDebugString;
    }

    return result;
}


float UExtendBlueprintFunctions::CalcFollowingNumberCPP(UObject* WorldContextObject, float TargetValue, float CurrentValue, float DeltaSeconds, float ChangeSpeed, float Min, float Max)
{
    float Delta = TargetValue - CurrentValue;

    return FMath::Clamp(TargetValue - FMath::Sign(Delta) * FMath::Max(0.0f, FMath::Abs(Delta) - DeltaSeconds * ChangeSpeed), Min, Max);
}

void UExtendBlueprintFunctions::UseStaticNavigation()
{
    UNavigationSystemV1::ConfigureAsStatic();
}

bool UExtendBlueprintFunctions::BoxOverlapActors(UObject* WorldContextObject, const FVector BoxPos, FVector BoxExtent, const FRotator Rotation, const TArray<TEnumAsByte<EObjectTypeQuery> > & ObjectTypes, UClass* ActorClassFilter, const TArray<AActor*>& ActorsToIgnore, TArray<AActor*>& OutActors)
{
	OutActors.Empty();

	TArray<UPrimitiveComponent*> OverlapComponents;
	bool bOverlapped = BoxOverlapComponents(WorldContextObject, BoxPos, BoxExtent, Rotation, ObjectTypes, NULL, ActorsToIgnore, OverlapComponents);
	if (bOverlapped)
	{
		UKismetSystemLibrary::GetActorListFromComponentList(OverlapComponents, ActorClassFilter, OutActors);
	}

	return (OutActors.Num() > 0);
}

bool UExtendBlueprintFunctions::BoxOverlapComponents(UObject* WorldContextObject, const FVector BoxPos, FVector BoxExtent, const FRotator Rotation, const TArray<TEnumAsByte<EObjectTypeQuery> > & ObjectTypes, UClass* ComponentClassFilter, const TArray<AActor*>& ActorsToIgnore, TArray<UPrimitiveComponent*>& OutComponents)
{
	OutComponents.Empty();

	static FName BoxOverlapComponentsName(TEXT("BoxOverlapComponents"));
	FCollisionQueryParams Params(BoxOverlapComponentsName, false);
	Params.AddIgnoredActors(ActorsToIgnore);

	TArray<FOverlapResult> Overlaps;

	FCollisionObjectQueryParams ObjectParams;
	for (auto Iter = ObjectTypes.CreateConstIterator(); Iter; ++Iter)
	{
		const ECollisionChannel & Channel = UCollisionProfile::Get()->ConvertToCollisionChannel(false, *Iter);
		ObjectParams.AddObjectTypesToQuery(Channel);
	}

	UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);
	if (World != nullptr)
	{
		World->OverlapMultiByObjectType(Overlaps, BoxPos, Rotation.Quaternion(), ObjectParams, FCollisionShape::MakeBox(BoxExtent), Params);
	}

	for (int32 OverlapIdx = 0; OverlapIdx < Overlaps.Num(); ++OverlapIdx)
	{
		FOverlapResult const& O = Overlaps[OverlapIdx];
		if (O.Component.IsValid())
		{
			if (!ComponentClassFilter || O.Component.Get()->IsA(ComponentClassFilter))
			{
				OutComponents.Add(O.Component.Get());
			}
		}
	}

	return (OutComponents.Num() > 0);
}

FTransform UExtendBlueprintFunctions::ConvertTransformToRelativeFixed(const FTransform& Transform, const FTransform& ParentTransform)
{
    return Transform.GetRelativeTransform(ParentTransform);
}

void UExtendBlueprintFunctions::GetAccurateRealTimeEx(const UObject* WorldContextObject, int32& Seconds, float& PartialSeconds)
{
    UGameplayStatics::GetAccurateRealTime(WorldContextObject, Seconds, PartialSeconds);
}

float UExtendBlueprintFunctions::GetYawFromVector(FVector InVec)
{
    FVector NormalizedVector = InVec.GetSafeNormal();
    return FMath::Atan2(NormalizedVector.Y, NormalizedVector.X) * 180.f / PI;
}

AGameStateBase* UExtendBlueprintFunctions::GetGameState(const UObject* WorldContextObject)
{
	ReturnIfNullptr(WorldContextObject, nullptr);
	UWorld* World = WorldContextObject->GetWorld();
	ReturnIfNullptr(World, nullptr);
    return World->GetGameState();
}

UObject* UExtendBlueprintFunctions::LoadAssetFromAssetPtr(TAssetPtr<UObject> InAssetId)
{
	//FStringAssetReference Reference = InAssetId.ToSoftObjectPath();
	//return Reference.TryLoad();
    return UEngineExtShell::StaticLoadObjectWithoutFlush(InAssetId.ToString());
}

UClass* UExtendBlueprintFunctions::LoadClassAssetFromClassAssetPtr(TAssetSubclassOf<UObject> InAssetId)
{
	//FStringAssetReference Reference = InAssetId.ToSoftObjectPath();
	//return Reference.TryLoad()->GetClass();
    UObject* Object = UEngineExtShell::StaticLoadObjectWithoutFlush(InAssetId.ToString());
    return Object ? Object->GetClass() : nullptr;
}


void UExtendBlueprintFunctions::GetDefaultComponentsByClass(UClass* InActorClass, UClass* InComponentClass,
    TArray<UActorComponent*>& DefaultComponents, TArray<FString>& VariableNames)
{
    // Cast the actor class to a UBlueprintGeneratedClass
    UBlueprintGeneratedClass* ActorBlueprintGeneratedClass = Cast<UBlueprintGeneratedClass>(InActorClass);

    // Use UBrintGeneratedClass->SimpleConstructionScript->GetAllNodes() to get an array of USCS_Nodes
    const TArray<USCS_Node*>& ActorBlueprintNodes = ActorBlueprintGeneratedClass->SimpleConstructionScript->GetAllNodes();

    // Iterate through the array looking for the USCS_Node whose ComponentClass matches the component you're looking for
    for (USCS_Node* Node : ActorBlueprintNodes)
    {
        if (Node->ComponentClass->IsChildOf(InComponentClass))
        {
            // Return cast USCS node's Template into your component class and return it, data's all there
            DefaultComponents.Add(Node->ComponentTemplate);
            VariableNames.Add(Node->GetVariableName().ToString());
        }
    }

}

void UExtendBlueprintFunctions::GetDefaultComponentChildren(UClass* InActorClass, UActorComponent* DefaultComponent,
    UClass* ChildClass,
    TArray<USceneComponent*>& ChildComponents, TArray<FString>& VariableNames)
{
    // Cast the actor class to a UBlueprintGeneratedClass
    UBlueprintGeneratedClass* ActorBlueprintGeneratedClass = Cast<UBlueprintGeneratedClass>(InActorClass);

    // Use UBrintGeneratedClass->SimpleConstructionScript->GetAllNodes() to get an array of USCS_Nodes
    const TArray<USCS_Node*>& ActorBlueprintNodes = ActorBlueprintGeneratedClass->SimpleConstructionScript->GetAllNodes();

    // Iterate through the array looking for the USCS_Node whose ComponentClass matches the component you're looking for
    for (USCS_Node* Node : ActorBlueprintNodes)
    {
        if (Node->ComponentTemplate == DefaultComponent)
        {
            for (USCS_Node* ChildNode : Node->ChildNodes)
            {
                if (ChildNode->ComponentClass->IsChildOf(ChildClass))
                {
                    ChildComponents.Add(Cast<USceneComponent>(ChildNode->ComponentTemplate));
                    VariableNames.Add(ChildNode->GetVariableName().ToString());
                }
            }
        }
    }
}

UActorComponent* UExtendBlueprintFunctions::FindActorComponentInCDO(UClass* InActorClass, const FString& Name,
    bool bFindOverridenComponent, bool bCreateOverridenComponentIfNotFind)
{
#if WITH_EDITOR
	UBlueprintGeneratedClass* BPClass = Cast<UBlueprintGeneratedClass>(InActorClass);
	if (!BPClass)
	{
		return nullptr;
	}

    FComponentInCDOCollector Collector(InActorClass);
	auto TreeNode = Collector.FindNode(*Name);
	return TreeNode ? Collector.GetComponent(*TreeNode, bFindOverridenComponent, bCreateOverridenComponentIfNotFind): nullptr;
#else
    return nullptr;
#endif
}

void UExtendBlueprintFunctions::FindActorChildComponentsInCDO(UClass* InActorClass,
	const FString& ParentName,
    bool bFindOverridenComponent,
    bool bCreateOverridenComponentIfNotFind,
    TArray<UActorComponent*>& OutComponents)
{
#if WITH_EDITOR
	UBlueprintGeneratedClass* BPClass = Cast<UBlueprintGeneratedClass>(InActorClass);
	if (!BPClass)
	{
		return;
	}

    FComponentInCDOCollector Collector(InActorClass);
    auto ParentTreeNode = Collector.FindNode(*ParentName);
	if (ParentTreeNode)
	{
		TArray<const FComponentTreeNodeInCDO*> ChildTreeNodes;
        Collector.FindChildren(*ParentTreeNode, ChildTreeNodes);
		for (int ii=0; ii<ChildTreeNodes.Num(); ii++)
		{
			OutComponents.Add(Collector.GetComponent(*ChildTreeNodes[ii],
                bFindOverridenComponent, bCreateOverridenComponentIfNotFind));
		}
	}
#endif
}

void UExtendBlueprintFunctions::FindActorParentComponentsInCDO(UClass* InActorClass, const FString& Name,
    bool bFindOverridenComponent, bool bCreateOverridenComponentIfNotFind,
    TArray<UActorComponent*>& OutComponents)
{
#if WITH_EDITOR
    UBlueprintGeneratedClass* BPClass = Cast<UBlueprintGeneratedClass>(InActorClass);
    if (!BPClass)
    {
        return;
    }

    FComponentInCDOCollector Collector(InActorClass);
    const FComponentTreeNodeInCDO* Node = Collector.FindNode(*Name);
    while (Node && Node->ParentIndex >= 0 && Node->ParentIndex < Collector.GetNodeCount())
    {
        const FComponentTreeNodeInCDO& ParentNode = Collector.GetNode(Node->ParentIndex);
        UActorComponent* Component = Collector.GetComponent(ParentNode, bFindOverridenComponent, bCreateOverridenComponentIfNotFind);
        if (Component)
        {
            OutComponents.Add(Component);
        }
        Node = &ParentNode;
    }
#endif
}

float UExtendBlueprintFunctions::NormalDistributionRandom(float Mean, float Sigma)
{
	static std::random_device rd;
	static std::mt19937 gen(rd());
	std::normal_distribution<float> d(Mean, Sigma);
	return d(gen);
}

TArray<float> UExtendBlueprintFunctions::SortedMultiNormalDistributionRandom(float Mean, float Sigma, int32 Count)
{
	TArray<float> RetArray;
	for (int i = 0; i < Count; ++i)
	{
		RetArray.Add(NormalDistributionRandom(Mean, Sigma));
	}
	RetArray.Sort();
	return MoveTemp(RetArray);
}

float UExtendBlueprintFunctions::ApplyCustomDamage(AActor* DamagedActor, float BaseDamage, AController* EventInstigator, AActor* DamageCauser, TSubclassOf<UDamageType> DamageTypeClass)
{
	if (DamagedActor && (BaseDamage != 0.f))
	{
		// make sure we have a good damage type
		TSubclassOf<UDamageType> const ValidDamageTypeClass = DamageTypeClass ? DamageTypeClass : TSubclassOf<UDamageType>(UDamageType::StaticClass());
		FPointDamageEvent DamageEvent;
		DamageEvent.DamageTypeClass = ValidDamageTypeClass;

		return DamagedActor->TakeDamage(BaseDamage, DamageEvent, EventInstigator, DamageCauser);
	}

	return 0.f;
}

TArray<UActorComponent*> UExtendBlueprintFunctions::GetComponentsByInterface(AActor* Actor, TSubclassOf<UInterface> Interface)
{
	TArray<UActorComponent*> ValidComponents;
	if (IsValid(Actor))
	{
		const TArray<UActorComponent*>& OwnedComponents = Actor->K2_GetComponentsByClass(UActorComponent::StaticClass());
		for (UActorComponent* Component : OwnedComponents)
		{
			if (Component && Component->GetClass()->ImplementsInterface(Interface))
			{
				ValidComponents.Add(Component);
			}
		}
	}
	return ValidComponents;
}

int32 UExtendBlueprintFunctions::GetUObjectCount()
{
#if UE_GC_TRACK_OBJ_AVAILABLE
	return GUObjectArray.GetObjectArrayNumMinusAvailable();
#else
	return GUObjectArray.GetObjectArrayNum();
#endif
}

int32 UExtendBlueprintFunctions::GetMaxUObjectCount()
{
	int32 MaxUObjects = 2 * 1024 * 1024; // Default to ~2M UObjects
	if (FPlatformProperties::RequiresCookedData())
	{
		// Maximum number of UObjects in cooked game
		GConfig->GetInt(TEXT("/Script/Engine.GarbageCollectionSettings"), TEXT("gc.MaxObjectsInGame"), MaxUObjects, GEngineIni);
	}
	else
	{
#if IS_PROGRAM
		// Maximum number of UObjects for programs can be low
		MaxUObjects = 100000; // Default to 100K for programs
		GConfig->GetInt(TEXT("/Script/Engine.GarbageCollectionSettings"), TEXT("gc.MaxObjectsInProgram"), MaxUObjects, GEngineIni);
#else
		// Maximum number of UObjects in the editor
		GConfig->GetInt(TEXT("/Script/Engine.GarbageCollectionSettings"), TEXT("gc.MaxObjectsInEditor"), MaxUObjects, GEngineIni);
#endif
	}
	return MaxUObjects;
}

void UExtendBlueprintFunctions::GetSkeletalMeshMaterialIndexs(USkeletalMeshComponent* SkeletalMeshComponent, FName MaterialSlotName, TArray<int32>& Indexs)
{
	Indexs.Empty();
	ReturnIfNullptr(SkeletalMeshComponent);
	auto SkeletalMesh = SkeletalMeshComponent->SkeletalMesh;
	ReturnIfNullptr(SkeletalMesh);
	auto& Materials = SkeletalMesh->Materials;
	for (int32 MaterialIndex = 0; MaterialIndex < SkeletalMesh->Materials.Num(); ++MaterialIndex)
	{
		const FSkeletalMaterial &SkeletalMaterial = Materials[MaterialIndex];
		if (SkeletalMaterial.MaterialSlotName == MaterialSlotName)
		{
			Indexs.Add(MaterialIndex);
		}
	}
}


void FindSequenceBindingID(UMovieSceneSequence* Sequener, FString inObjectDisplayName, FMovieSceneSequenceID SequenceID,TArray<FMovieSceneObjectBindingID> &Bindings)
{
    UMovieScene* MovieScene = Sequener->GetMovieScene();
    for (const UMovieSceneTrack* MasterTrack : MovieScene->GetMasterTracks())
    {
        const UMovieSceneSubTrack* SubTrack = Cast<const UMovieSceneSubTrack>(MasterTrack);
        if (SubTrack)
        {
            for (UMovieSceneSection* Section : SubTrack->GetAllSections())
            {
                UMovieSceneSubSection* SubSection = Cast<UMovieSceneSubSection>(Section);
                UMovieSceneSequence* SubSequence = SubSection ? SubSection->GetSequence() : nullptr;
                if (SubSequence)
                {
                    FindSequenceBindingID(SubSequence, inObjectDisplayName, SubSection->GetSequenceID(), Bindings);
                }
            }
        }
    }

    int32 SpawnableCount = MovieScene->GetSpawnableCount();
    for (int32 Index = 0; Index < SpawnableCount; ++Index)
    {
        const FMovieSceneSpawnable& Spawnable = MovieScene->GetSpawnable(Index);
        FGuid ObjectGuid = Spawnable.GetGuid();

        FString DisplayName = Spawnable.GetName();
        if (DisplayName.Equals(inObjectDisplayName))
        {
            FMovieSceneObjectBindingID BindingID(ObjectGuid, SequenceID);
            //return BindingID;
            Bindings.Add(BindingID);
        }
    }

    int32 PossableCount = MovieScene->GetPossessableCount();
    for (int32 Index = 0; Index < PossableCount; Index++)
    {
        const FMovieScenePossessable& Possessable = MovieScene->GetPossessable(Index);
        if (!Sequener->CanRebindPossessable(Possessable))
            continue;

        FGuid ObjectGuid = Possessable.GetGuid();
        FString DisplayName = Possessable.GetName();
        if (DisplayName.Equals(inObjectDisplayName))
        {
            FMovieSceneObjectBindingID BindingID(ObjectGuid, MovieSceneSequenceID::Root);
            //return BindingID;
            Bindings.Add(BindingID);
        }
    }
    //return FMovieSceneObjectBindingID();
}

void UExtendBlueprintFunctions::ReplaceMatineeActor(ULevelSequencePlayer* SequencePlayer, FString inObjectDisplayName, AActor* BindActor)
{
    if (!SequencePlayer || inObjectDisplayName.IsEmpty() || !BindActor)
        return;

    UMovieSceneSequence* Sequener = SequencePlayer->GetSequence();

    UMovieScene* MovieScene = Sequener->GetMovieScene();
    TArray<FMovieSceneObjectBindingID> Bindings;
    FindSequenceBindingID(Sequener, inObjectDisplayName, MovieSceneSequenceID::Root, Bindings);

    ALevelSequenceActor* LevelSequenceActor = GetSequenceActorFromPlayer(SequencePlayer);
    for (int i = 0; i < Bindings.Num(); i++)
    {
        LevelSequenceActor->AddBinding(Bindings[i], BindActor);
    }

    return;
}

TArray<AActor*> UExtendBlueprintFunctions::GetMatineeActor(ULevelSequencePlayer* SequencePlayer, FString inObjectDisplayName)
{
    TArray<AActor*> BindActors;
    if (!SequencePlayer || inObjectDisplayName.IsEmpty())
        return BindActors;

    UMovieSceneSequence* Sequener = SequencePlayer->GetSequence();

    if (Sequener == nullptr)
        return BindActors;

    UMovieScene* MovieScene = Sequener->GetMovieScene();
    TArray<FMovieSceneObjectBindingID> Bindings;
    FindSequenceBindingID(Sequener, inObjectDisplayName, MovieSceneSequenceID::Root, Bindings);

    for (int i = 0; i < Bindings.Num(); i++)
    {
        TArray<UObject*> BoundObjects = SequencePlayer->GetBoundObjects(Bindings[i]);

        for (int j = 0; j < BoundObjects.Num(); j++)
        {
            AActor* pActor = Cast<AActor>(BoundObjects[j]);
            if (pActor)
                BindActors.Add(pActor);
                //return pActor;
        }
    }

    return BindActors;
}


UParticleSystemComponent* UExtendBlueprintFunctions::SpawnEmitterAttachedEx(UParticleSystem* EmitterTemplate, USceneComponent* AttachToComponent, FName AttachPointName, FVector Location, FRotator Rotation, FVector Scale, EAttachLocation::Type LocationType, bool bAutoDestroy, float CustomScale, EPSCPoolMethod PoolingMethod, bool bManageSignificance)
{
	if (AttachToComponent == nullptr)
	{
		UE_LOG(LogScript, Warning, TEXT("UExtendBlueprintFunctions::SpawnEmitterAttachedEx: NULL AttachComponent specified!"));
		return nullptr;
	}
	AActor* OwnerActor = AttachToComponent->GetOwner();
	bool bOwnerActorHidden = IsValid(OwnerActor) && OwnerActor->IsHidden();
	if (GXSJForbidParticleSystemPool != 0)
	{
		PoolingMethod = EPSCPoolMethod::None;
	}
	UParticleSystemComponent* PSC = UGameplayStatics::SpawnEmitterAttached(EmitterTemplate, AttachToComponent, AttachPointName, Location, Rotation, CustomScale, LocationType, bOwnerActorHidden ? false : bAutoDestroy, PoolingMethod);

	if (bOwnerActorHidden)
	{
		UEmitterActivateComponent* EmitterActivateComponent = Cast<UEmitterActivateComponent>(OwnerActor->GetComponentByClass(UEmitterActivateComponent::StaticClass()));
		if(EmitterActivateComponent)
		{
			EmitterActivateComponent->AddEmitterToWaitActivateMap(PSC, bAutoDestroy);
		}
	}
	if (bManageSignificance)
	{
		UKMParticleSignificance::RegisterParticle(PSC);
	}
	return PSC;
}

UParticleSystemComponent* UExtendBlueprintFunctions::SpawnEmitterAtLocationEx(const UObject* WorldContextObject, UParticleSystem* EmitterTemplate, FVector Location, FRotator Rotation, FVector Scale, bool bAutoDestroy, float CustomScale, EPSCPoolMethod PoolingMethod, bool bManageSignificance)
{
	if (GXSJForbidParticleSystemPool != 0)
	{
		PoolingMethod = EPSCPoolMethod::None;
	}
	UParticleSystemComponent* PSC = UGameplayStatics::SpawnEmitterAtLocationKS(WorldContextObject, EmitterTemplate, Location, Rotation, Scale, CustomScale, bAutoDestroy, PoolingMethod);
	if (bManageSignificance)
	{
		UKMParticleSignificance::RegisterParticle(PSC);
	}
	return PSC;
}

void UExtendBlueprintFunctions::DeactivateEmitter(UParticleSystemComponent* ParticleSystemComponent)
{
	ReturnIfNullptr(ParticleSystemComponent);
	if (ParticleSystemComponent->bIsManagingSignificance)
	{
		UKMParticleSignificance::UnRegisterParticle(ParticleSystemComponent);
	}
	AActor* Owner = ParticleSystemComponent->GetOwner();
	ReturnIfNullptr(Owner);
	UEmitterActivateComponent* EmitterActivateComponent = Cast<UEmitterActivateComponent>(Owner->GetComponentByClass(UEmitterActivateComponent::StaticClass()));
	if (EmitterActivateComponent)
	{
		EmitterActivateComponent->RemoveEmitterFromWaitActivateMap(ParticleSystemComponent);
	}
	ParticleSystemComponent->Deactivate();
}

void UExtendBlueprintFunctions::DestroyEmitter(UParticleSystemComponent* ParticleSystemComponent)
{
	ReturnIfNullptr(ParticleSystemComponent);
	if (ParticleSystemComponent->bIsManagingSignificance)
	{
		UKMParticleSignificance::UnRegisterParticle(ParticleSystemComponent);
	}
	if (ParticleSystemComponent->PoolingMethod == EPSCPoolMethod::AutoRelease)
	{
		ParticleSystemComponent->GetWorld()->GetPSCPool().ReclaimWorldParticleSystem(ParticleSystemComponent);
	}
	ParticleSystemComponent->DestroyComponent();
}

void UExtendBlueprintFunctions::RemoveEmitterInPendingList(UParticleSystemComponent * ParticleSystemComponent)
{
	ReturnIfNullptr(ParticleSystemComponent);
	AActor* Owner = ParticleSystemComponent->GetOwner();
	ReturnIfNullptr(Owner);
	UEmitterActivateComponent* EmitterActivateComponent = Cast<UEmitterActivateComponent>(Owner->GetComponentByClass(UEmitterActivateComponent::StaticClass()));
	ReturnIfNullptr(EmitterActivateComponent);
	EmitterActivateComponent->RemoveEmitterFromWaitActivateMap(ParticleSystemComponent);
}

bool UExtendBlueprintFunctions::CheckEmitterIsPending(UParticleSystemComponent * ParticleSystemComponent)
{
	ReturnIfNullptr(ParticleSystemComponent, false);
	AActor* Owner = ParticleSystemComponent->GetOwner();
	ReturnIfNullptr(Owner, false);
	UEmitterActivateComponent* EmitterActivateComponent = Cast<UEmitterActivateComponent>(Owner->GetComponentByClass(UEmitterActivateComponent::StaticClass()));
	ReturnIfNullptr(EmitterActivateComponent, false);
	return EmitterActivateComponent->IsEmitterInActivateMap(ParticleSystemComponent);
}

FSkeletalMaterial UExtendBlueprintFunctions::SetSkeletalMaterial(UPARAM(ref) FSkeletalMaterial& SkeletalMaterial, UMaterialInterface* MaterialInterface)
{
    SkeletalMaterial.MaterialInterface = MaterialInterface;
    return SkeletalMaterial;
}


void UExtendBlueprintFunctions::RemovePostProcessBlendable(UPostProcessComponent* PostProcessComponent, TScriptInterface<IBlendableInterface> InBlendableObject)
{
	if (IsValid(PostProcessComponent))
	{
		PostProcessComponent->Settings.RemoveBlendable(InBlendableObject);
	}
}

void UExtendBlueprintFunctions::FlushLog()
{
	if (GLog)
	{
		GLog->Flush();
	}
}

void UExtendBlueprintFunctions::RemoveActorFromVisualLog(AActor* Actor)
{
#if ENABLE_VISUAL_LOG
    auto& RedirectionMap = FVisualLogger::Get().GetRedirectionMap(Actor);
    RedirectionMap.Remove(Actor);
#endif
}

void UExtendBlueprintFunctions::ToggleStatUnit(UObject* WorldContextObject, bool bEnable)
{
#if !(UE_BUILD_SHIPPING || UE_BUILD_TEST) && !WITH_EDITOR
	auto pCvar = IConsoleManager::Get().FindConsoleVariable(TEXT("t.FrameUnitPrintLogInterval"));
	if (pCvar ? pCvar->GetFloat() > 0.f : false)
	{
		UWorld* World = WorldContextObject->GetWorld();
		UGameViewportClient* lViewportClient = World->GetGameViewport();
		if (lViewportClient->IsStatEnabled(TEXT("unit")) != bEnable)
		{
			UKismetSystemLibrary::ExecuteConsoleCommand(WorldContextObject, TEXT("stat unit"));
		}
	}
#endif
}

void UExtendBlueprintFunctions::ShowCurrentMemoryUsed(UObject* WorldContextObject)
{
#if !(UE_BUILD_SHIPPING || UE_BUILD_TEST) && !WITH_EDITOR
    static const float InvMB = 1.0f / 1024.0f / 1024.0f;
    FPlatformMemoryStats MemoryStats = FPlatformMemory::GetStats();
    float MemCurrent = MemoryStats.UsedPhysical * InvMB;

    FString LevelName = FString(TEXT(""));
    LevelName = WorldContextObject->GetWorld()->GetMapName();

    auto pCvar = IConsoleManager::Get().FindConsoleVariable(TEXT("t.LevelRoutFlag"));
    if (pCvar &&pCvar->GetInt() > 0)
    {
        int32 RouteFlag = pCvar->GetInt();
        LevelName.Append(FString(TEXT("_")));
        LevelName.Append(FString::FromInt(RouteFlag));
    }

    UE_LOG(ExtendBPFuncLibLog, Log, TEXT("MEMORY STAT: MemoryCurrent %.2f MB used in LevelName %s "), MemCurrent, *LevelName);


#endif
}

bool UExtendBlueprintFunctions::IsStatUnitToggled(UObject* WorldContextObject)
{
    UWorld* World = WorldContextObject->GetWorld();
    UGameViewportClient* lViewportClient = World->GetGameViewport();
    if (lViewportClient->IsStatEnabled(TEXT("unit")))
    {
        return true;
    }
    return false;

}

void UExtendBlueprintFunctions::SetActorNetCullDistanceSquared(AActor* Actor, float NetCullDistanceSquared)
{
	ReturnIfNullptr(Actor);
	Actor->NetCullDistanceSquared = NetCullDistanceSquared;
}

void UExtendBlueprintFunctions::GetComponentsInCDOByClass(UClass* InActorClass, TSubclassOf<UActorComponent> InComponentClass, TArray<UActorComponent*>& Components, bool bFindOverridenComponent, bool bCreateOverridenComponentIfNotFind)
{
	Components.Empty();
#if WITH_EDITOR
	FComponentInCDOCollector Collector(InActorClass);
	for (int i = 0; i < Collector.GetNodeCount(); i++)
	{
		const FComponentTreeNodeInCDO& Node = Collector.GetNode(i);
		if (Node.Component && Node.Component->GetClass() && Node.Component->GetClass()->IsChildOf(InComponentClass))
		{
            UActorComponent* OverrideComponent = Collector.GetComponent(Node, bFindOverridenComponent, bCreateOverridenComponentIfNotFind);
            if (OverrideComponent)
            {
                Components.Add(OverrideComponent);
            }
		}
	}
#endif
}

void UExtendBlueprintFunctions::GetChildrenComponentsInCDOByClass(UClass* InActorClass, UActorComponent* ParentComponent, bool bIncludeAllDescendants, TSubclassOf<UActorComponent> InComponentClass, TArray<UActorComponent*>& Components,
    bool bFindOverridenComponent, bool bCreateOverridenComponentIfNotFind)
{
	Components.Empty();
#if WITH_EDITOR
	FComponentInCDOCollector Collector(InActorClass);
	const FComponentTreeNodeInCDO* ParentNode = Collector.FindNodeWithComponent(ParentComponent);
	if (ParentNode)
	{
		if (bIncludeAllDescendants)
		{
			TArray<const FComponentTreeNodeInCDO*> ChildrenNodes;
			Collector.FindChildren(*ParentNode, ChildrenNodes);
			for (int i = 0; i < ChildrenNodes.Num(); i++)
            {
				const FComponentTreeNodeInCDO* Node = ChildrenNodes[i];
				if (Node && Node->Component && Node->Component->GetClass() && Node->Component->GetClass()->IsChildOf(InComponentClass))
				{
                    Components.Add(Collector.GetComponent(*Node,
                        bFindOverridenComponent, bCreateOverridenComponentIfNotFind));
				}
			}
		}
		else
		{
			for (int i = 0; i < ParentNode->ChildIndices.Num(); i++)
			{
                int ChildIndex = ParentNode->ChildIndices[i];
				const FComponentTreeNodeInCDO& Node = Collector.GetNode(ChildIndex);
				if (Node.Component && Node.Component->GetClass() && Node.Component->GetClass()->IsChildOf(InComponentClass))
				{
                    Components.Add(Collector.GetComponent(Node,
                        bFindOverridenComponent, bCreateOverridenComponentIfNotFind));
				}
			}
		}
	}
#endif
}

static bool bGWrDisable = true;
static FAutoConsoleCommand CCmdWorldRendering(
	TEXT("pir.wr"),
	TEXT("flip-flop world rendering"),
	FConsoleCommandDelegate::CreateLambda([]() {
	UGameViewportClient* GameViewportClient = GWorld->GetGameViewport();
	GameViewportClient->bDisableWorldRendering = bGWrDisable;
	bGWrDisable = !bGWrDisable;
})
);

void UExtendBlueprintFunctions::FlipFlopWorldRendering(const UObject* WorldContextObject)
{
    static bool bDisable = true;
    UWorld* World = WorldContextObject->GetWorld();
    if (World)
    {
        UGameViewportClient* GameViewportClient = World->GetGameViewport();
        GameViewportClient->bDisableWorldRendering = bDisable;
        bDisable = !bDisable;
    }
}

void UExtendBlueprintFunctions::FlipFlopFrameUnitPrintLogInterval()
{
#if !(UE_BUILD_SHIPPING || UE_BUILD_TEST) && !WITH_EDITOR
    static auto pCvar = IConsoleManager::Get().FindConsoleVariable(TEXT("t.FrameUnitPrintLogInterval"));
    check(pCvar);
    static bool bLog = false;
    pCvar->Set(bLog ? 1.f : 0.f, EConsoleVariableFlags::ECVF_SetByConsole);
    bLog = !bLog;
#endif
}

static double BlueprintRecordTime;

void UExtendBlueprintFunctions::RecordTimeStart()
{
    BlueprintRecordTime = FPlatformTime::Seconds();

}

void UExtendBlueprintFunctions::RecordTimeEnd(const FString& Msg, float Threshold /* = 0 */)
{
    float fTime = (float)(FPlatformTime::Seconds() - BlueprintRecordTime)*1000.0f;
    if (fTime >= Threshold)
    {
        UE_LOG(ExtendBPFuncLibLog, Log, TEXT("time: %f ms, %s"), fTime, Msg.IsEmpty() ? TEXT("No info") : *Msg);
    }

}

float UExtendBlueprintFunctions::RecordTimeEndWithResult()
{
    float fTime = (float)(FPlatformTime::Seconds() - BlueprintRecordTime) * 1000.0f;
    return fTime;
}

FString UExtendBlueprintFunctions::GetObjectClassName(UObject * Object)
{
    if (Object)
    {
        UClass* Class = Object->GetClass();
        if (Class)
        {
            return Class->GetName();
        }
    }
    return TEXT("None");
}

void UExtendBlueprintFunctions::GetImpactPointFromHitResult(const FHitResult& Hit, FVector& ImpactPoint)
{
	ImpactPoint = Hit.ImpactPoint;
}

void UExtendBlueprintFunctions::GetImpactNormalFromHitResult(const FHitResult& Hit, FVector& ImpactNormal)
{
	ImpactNormal = Hit.ImpactNormal;
}

UPrimitiveComponent* UExtendBlueprintFunctions::GetComponentFromHitResult(const FHitResult& Hit)
{
	return Hit.GetComponent();
}

FString UExtendBlueprintFunctions::GetComponentTemplateNameSuffix()
{
	return UActorComponent::ComponentTemplateNameSuffix;
}

#if WITH_EDITOR
class FTempTabDataFileHelper
{
public:
    static const FString* pKeyColumnName;
    static const TArray<FString>* pTargetColumnNames;

public:
    struct FTempTabData : public TTemplateTabFileData<FTempTabData>
    {
        FString KeyColumnValue;
        TArray<FString> TargetColumnValues;

        FTempTabData()
        {
        }

        TAB_FILE_DATA_SINGLE_KEY(FString, KeyColumnValue);

        bool OnReadData(const FString& ColumnName, const TCHAR* RawValue)
        {
            TargetColumnValues.Push(RawValue);
            return true;
        }

        virtual void RegisterParams() override
        {
            TargetColumnValues.Empty();
            TAB_FILE_DATA_REGISTER(KeyColumnValue, *pKeyColumnName);

            for (int i = 0; i < pTargetColumnNames->Num(); i++)
            {
                TAB_FILE_DATA_REGISTER_CUSTOM_READ((*pTargetColumnNames)[i], OnReadData)
            }
        }
    };

    //////////////////////////////////////////////////////////////////////////
    class FTempTabDataFile : public TTemplateTabFile<FString, FTempTabData>
    {
    public:
        FTempTabDataFile(const FString& FilePath)
            : TabFilePath(FilePath)
        {
        }
        virtual const TCHAR* GetPath() const override
        {
            return *TabFilePath;
        }
    private:
        const FString& TabFilePath;
    };

    //////////////////////////////////////////////////////////////////////////
    FTempTabDataFileHelper(const FString& TableName, const FString& KeyColumnName, const TArray<FString>& TargetColumnNames)
    {
        pKeyColumnName = &KeyColumnName;
        pTargetColumnNames = &TargetColumnNames;
        Table = new FTempTabDataFile(TableName);
    }
    ~FTempTabDataFileHelper()
    {
        if (Table->IsLoaded())
        {
            Table->Unload();
        }
        Table->EditorUnregisterParams();
        delete Table;
    }
    FTempTabDataFile* operator ->()
    {
        return Table;
    }
    FTempTabDataFile* Table;
};

const FString* FTempTabDataFileHelper::pKeyColumnName = nullptr;
const TArray<FString>* FTempTabDataFileHelper::pTargetColumnNames = nullptr;
#endif

bool UExtendBlueprintFunctions::GetColumnValuesFromTableByColumns(const FString& TableName,
    const FString& KeyColumnName, const FString& KeyColumnValue,
    const TArray<FString>& TargetColumnNames, TArray<FString>& OutValue)
{
#if WITH_EDITOR
    OutValue.Empty();
    FTempTabDataFileHelper TabDataFile(TableName, KeyColumnName, TargetColumnNames);

    if (!TabDataFile->Load())
    {
        UE_LOG(ExtendBPFuncLibLog, Error, TEXT("GetColumnValuesFromTableByColumns load failed, TabFile = %s, ColumnName=%s."), *TableName, *KeyColumnName);
        return false;
    }
    auto TabData = TabDataFile->Find(KeyColumnValue);
    if (!TabData)
    {
        //UE_LOG(ExtendBPFuncLibLog, Error, TEXT("GetColumnValuesFromTableByColumns find failed, TabFile = %s, KeyValue=%s."), *TableName, *KeyColumnValue);
        return false;
    }

    OutValue = TabData->TargetColumnValues;

    return true;
#else
    check(0);
    return false;
#endif
}

bool UExtendBlueprintFunctions::GetColumnValueFromTable(const FString& TableName, const FString& KeyColumnName, const FString& KeyColumnValue, const FString& TargetColumnName, FString& OutValue)
{
#if WITH_EDITOR
    const TArray<FString> TargetColumnNames = { TargetColumnName };
    TArray<FString> OutValues;
    if (! GetColumnValuesFromTableByColumns(TableName, KeyColumnName, KeyColumnValue, TargetColumnNames, OutValues))
    {
        UE_LOG(ExtendBPFuncLibLog, Error, TEXT("GetColumnValueFromTable load failed, TabFile = %s"), *TableName);
        return false;
    }
    if (OutValues.Num() <= 0)
    {
        UE_LOG(ExtendBPFuncLibLog, Error, TEXT("GetColumnValueFromTable find failed, TabFile = %s, Key = %s"), *TableName, *KeyColumnValue);
        return false;
    }

    OutValue = OutValues[0];

    return true;
#else
    check(0);
    return false;
#endif
}

bool UExtendBlueprintFunctions::GetColumnValuesFromTableByColumn(const FString& TableName,
    const FString& KeyColumnName, const FString& TargetColumnName, TArray<FString>& OutValue)
{
#if WITH_EDITOR
    const TArray<FString> TargetColumnNames = { TargetColumnName };
    FTempTabDataFileHelper TabDataFile(TableName, KeyColumnName, TargetColumnNames);

    if (!TabDataFile->Load())
    {
        UE_LOG(ExtendBPFuncLibLog, Error, TEXT("GetColumnValuesFromTableByColumn load failed, TabFile = %s."), *TableName);
        return false;
    }

    TArray<FTabFileDataBase*> TabDatas;
    TabDataFile->EditorGetAllData(TabDatas);
    for (int i = 0; i < TabDatas.Num(); i++)
    {
        auto* Data = static_cast<FTempTabDataFileHelper::FTempTabData*>(TabDatas[i]);
        if (Data->TargetColumnValues.Num() <= 0 )
        {
            UE_LOG(ExtendBPFuncLibLog, Error, TEXT("GetColumnValuesFromTableByColumn get data failed, TabFile = %s."), *TableName);
            return false;
        }
        OutValue.Push(Data->TargetColumnValues[0]);
    }

    return true;
#else
    check(0);
    return false;
#endif
}

bool UExtendBlueprintFunctions::IsInsideBox2D(const FBox2D& Box, const FVector2D& Point)
{
    return Box.IsInside(Point);
}

int UExtendBlueprintFunctions::SegmentIntersectWithBox2D(const FVector& SegmentStart, const FVector& SegmentEnd, const FBox2D& Box2D,
    FVector& OutIntersectionPointA, FVector& OutIntersectionPointB)
{
    FVector P1(Box2D.Min.X, Box2D.Min.Y, 0.0f);
    FVector P2(Box2D.Min.X, Box2D.Max.Y, 0.0f);
    FVector P3(Box2D.Max.X, Box2D.Max.Y, 0.0f);
    FVector P4(Box2D.Max.X, Box2D.Min.Y, 0.0f);

    OutIntersectionPointA = FVector(0.0f);
    OutIntersectionPointB = FVector(0.0f);

    int Ret = 0;
    if (FMath::SegmentIntersection2D(SegmentStart, SegmentEnd, P1, P2, Ret == 0 ? OutIntersectionPointA : OutIntersectionPointB))
    {
        ++Ret;
    }
    if (FMath::SegmentIntersection2D(SegmentStart, SegmentEnd, P2, P3, Ret == 0 ? OutIntersectionPointA : OutIntersectionPointB))
    {
        ++Ret;
    }
    if (FMath::SegmentIntersection2D(SegmentStart, SegmentEnd, P3, P4, Ret == 0 ? OutIntersectionPointA : OutIntersectionPointB))
    {
        ++Ret;
    }
    if (FMath::SegmentIntersection2D(SegmentStart, SegmentEnd, P4, P1, Ret == 0 ? OutIntersectionPointA : OutIntersectionPointB))
    {
        ++Ret;
    }
    return Ret;
}

float UExtendBlueprintFunctions::GetVectorToVectorDistance(const FVector& V1, const FVector& V2)
{
    return FVector::Dist(V1, V2);
}

float UExtendBlueprintFunctions::GetVectorToVectorDistanceSquared(const FVector& V1, const FVector& V2)
{
    return FVector::DistSquared2D(V1, V2);
}

bool UExtendBlueprintFunctions::GetLogicIdRangeInEditor(AActor* Actor, bool bRefreshed, int& OutMinId, int& OutMaxId)
{
#if WITH_EDITOR
    OutMinId = 0;
    OutMaxId = 0;

    class FLogicIdTabHelper
    {
    public:
        struct FTempTabData : public TTemplateTabFileData<FTempTabData>
        {
            FString PersistentLevelName;
            FString LogicLevelName;
            int MinId;
            int MaxId;

            FTempTabData()
                : MinId(-1)
                , MaxId(-1)
            {
            }

            TAB_FILE_DATA_DOUBLE_KEY(FString, PersistentLevelName, FString, LogicLevelName);

            virtual void RegisterParams() override
            {
                TAB_FILE_DATA_REGISTER(PersistentLevelName, "persistent_level");
                TAB_FILE_DATA_REGISTER(LogicLevelName, "logic_level");
                TAB_FILE_DATA_REGISTER(MinId, "min_id");
                TAB_FILE_DATA_REGISTER(MaxId, "max_id");
            }
        };

        //////////////////////////////////////////////////////////////////////////
        class FTempTabFile : public TTemplateTabFile<FTempTabData::TKeyType, FTempTabData>
        {
        public:
            FTempTabFile()
            {
            }
            virtual const TCHAR* GetPath() const override
            {
                return TEXT("common/scene/logic_level_id_range.tab");
            }
        };

        //////////////////////////////////////////////////////////////////////////
        FLogicIdTabHelper()
        {
            Table.Load();
        }
        ~FLogicIdTabHelper()
        {
            if (Table.IsLoaded())
            {
                Table.Unload();
            }
            Table.EditorUnregisterParams();
        }
        FTempTabFile& GetTab()
        {
            return Table;
        }
        FTempTabFile Table;
    };
    //////////////////////////////////////////////////////////////////////////

    static FLogicIdTabHelper* Helper = nullptr;
    if (!Helper || bRefreshed)
    {
        if (Helper)
        {
            delete Helper;
        }
        Helper = new FLogicIdTabHelper();
    }

    if (!Actor)
    {
        return false;
    }

    UPackage* Package = Cast<UPackage>(Actor->GetOutermost());
    if (!Package)
    {
        return false;
    }

    UWorld* World = Actor->GetWorld();
    if (!World)
    {
        return false;
    }

    FString PersistentLevelName = UWorld::StripPIEPrefixFromPackageName(World->GetOutermost()->GetName(), World->StreamingLevelsPrefix);
    FString CurrentLevelName = UWorld::StripPIEPrefixFromPackageName(Package->GetName(), World->StreamingLevelsPrefix);

    auto Data = Helper->GetTab().Find(TKeyValuePair<FString, FString>(PersistentLevelName, FPaths::GetCleanFilename(CurrentLevelName)));
    if (!Data)
    {
        return false;
    }

    OutMinId = Data->MinId;
    OutMaxId = Data->MaxId;
    return true;
#else
    check(0);
    return false;
#endif
}

FString UExtendBlueprintFunctions::GetOutermostName(UObject* Object)
{
    auto Outermost = Object ? Object->GetOutermost() : nullptr;
    return Outermost ? Outermost->GetName() : FString();
}

UAudioComponent* UExtendBlueprintFunctions::PlaySoundInClient(UObject* WorldContextObject, USoundBase* Sound, uint8 SoundType, const FVector& Location, AActor* SoundSource)
{
    if (Sound)
    {
        UE_LOG(ExtendBPFuncLibLog, Log, TEXT("PlaySoundInClient, Sound Path = %s"), *(Sound->GetName()));
    }

	UAudioComponent* AudioComponent = nullptr;

	if (SoundSource)
	{
		AudioComponent = UGameplayStatics::SpawnSoundAttached(Sound, SoundSource->GetRootComponent(), NAME_None, Location, FRotator::ZeroRotator, EAttachLocation::KeepWorldPosition);
	}
	else
	{
		AudioComponent = UGameplayStatics::SpawnSoundAtLocation(WorldContextObject, Sound, Location);
	}

    UCommonShell* CommonShell = UCommonShell::GetCommon(WorldContextObject);
    if (CommonShell)
    {
        CommonShell->GetGameDelegateManager()->GameMisc->PlaySound(SoundType, Location, SoundSource);
    }
    return AudioComponent;
}

bool UExtendBlueprintFunctions::RotateNumberInRange(int32 Number, int32 RangeMin, int32 RangeMax, int32& NewNumber)
{
	NewNumber = Number + 1;
	if (NewNumber <= RangeMax)
	{
		return false;
	}
	NewNumber = RangeMin;
	return true;
}

void UExtendBlueprintFunctions::GetComponentFromCDO(TSubclassOf<AActor> InClass, const FString& ComponentName, UActorComponent*& OutComponent)
{
	ReturnIfNullptr(InClass);
	UBlueprintGeneratedClass* BPClass = Cast<UBlueprintGeneratedClass>(InClass);
	ReturnIfNullptr(BPClass);
	UInheritableComponentHandler* InheritableComponentHandler = BPClass->GetInheritableComponentHandler(false);
	ReturnIfNullptr(InheritableComponentHandler);
	const FComponentKey& ComponentKey = InheritableComponentHandler->FindKey(*ComponentName);
	ReturnIfFalse(ComponentKey.IsValid());
	OutComponent = InheritableComponentHandler->GetOverridenComponentTemplate(ComponentKey);
}

void UExtendBlueprintFunctions::SetComponentAllowTickOnDedicatedServer(UActorComponent* Component, bool bAllowTickOnDedicatedServer)
{
    //ReturnIfNullUObject(Component);
    //Component->PrimaryComponentTick.bAllowTickOnDedicatedServer = bAllowTickOnDedicatedServer;
    //Component->RegisterAllComponentTickFunctions(bAllowTickOnDedicatedServer);
}

void UExtendBlueprintFunctions::GetMutableDefaultObject(TSubclassOf<UObject> InClass, UObject*& OutObject)
{
	ReturnIfNullptr(InClass);
	OutObject = GetMutableDefault<UObject>(InClass);
}

FVector UExtendBlueprintFunctions::RandomPointInEllipsoid(float A, float B, float C, float SigmaRatio)
{
	float X = 0;
	float Y = 0;
	float Z = 0;
	float AA_1 = (A > 0) ? (1 / A / A) : 0;
	float BB_1 = (B > 0) ? (1 / B / B) : 0;
	float CC_1 = (C > 0) ? (1 / C / C) : 0;
	if ((AA_1 != 0) || ((BB_1 != 0)) || (CC_1 != 0))
	{
		do
		{
			X = NormalDistributionRandom(0, A * SigmaRatio);
			Y = NormalDistributionRandom(0, B * SigmaRatio);
			Z = NormalDistributionRandom(0, C * SigmaRatio);
		} while ((X * X * AA_1 + Y * Y * BB_1 + Z * Z * CC_1) <= 1.f);
	}
	return FVector(X, Y, Z);
}

FVector UExtendBlueprintFunctions::RandomPointInEllipsoidWithTransform(float A, float B, float C, float SigmaRatio, const FTransform& Transform)
{
	const FVector& Point = RandomPointInEllipsoid(A, B, C, SigmaRatio);
	return Transform.TransformVectorNoScale(Point) + Transform.GetLocation();
}

void UExtendBlueprintFunctions::PreLoadLevelStreamingPackageForPoint(UWorld* InWorld, const FVector& InLoc)
{
	return UGameEngineExt::Get(InWorld)->PreLoadLevelStreamingPackageForPoint(InWorld, InLoc);
}



void UExtendBlueprintFunctions::ResetCharacterSkeletalDrawDistance(UObject* WorldContextObject)
{
	UWorld* const World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);
    int32 NewDistance = AKMCharacter::GetCharacterDrawDis();
	for (ULevel* Level : World->GetLevels())
	{
		for (AActor* Actor : Level->Actors)
		{
			if (AKMCharacter* Character = Cast<AKMCharacter>(Actor))
			{
                Character->ResetSkeletalMeshComponentDrawDistance();
			}
		}
	}
}


void UExtendBlueprintFunctions::PrintDebugMessage(UObject* WorldContextObject, const FString& Category, float TimeToDisplay, FColor DisplayColor, const FString& DebugMessage)
{
#if !(UE_BUILD_SHIPPING || UE_BUILD_TEST)
    UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull);
    FString Prefix;
    if (World)
    {
        if (World->WorldType == EWorldType::PIE)
        {
            switch (World->GetNetMode())
            {
            case NM_Client:
                Prefix = FString::Printf(TEXT("Client %d: "), GPlayInEditorID - 1);
                break;
            case NM_DedicatedServer:
            case NM_ListenServer:
                Prefix = FString::Printf(TEXT("Server: "));
                break;
            case NM_Standalone:
                break;
            }
        }
    }

    const FString FinalDisplayString = Prefix + DebugMessage;
    FString FinalLogString = FinalDisplayString;
    uint32 Key = GetTypeHash(Category);
    GEngine->AddOnScreenDebugMessage((uint64)Key, TimeToDisplay, DisplayColor, FinalLogString, false);
#endif
}

FString UExtendBlueprintFunctions::GetAvatarPartResourceData(int32 PartID, const FString& Key)
{
    auto Part = FGameAvatarPartTabFile::GetSingleton().Find(PartID);
    if (!Part)
    {
        return TEXT("");
    }
    auto& DataArray = Part->Data;
    int iDataCount = DataArray.Num();
    FName KeyName = FName(*Key);
    bool bKeyIsEmpty = Key.IsEmpty();
    for (int i = 0; i < iDataCount; i++)
    {
        if ((bKeyIsEmpty && !DataArray[i].Value.IsEmpty()) || (!bKeyIsEmpty && DataArray[i].Key == KeyName))
        {
            FString Ret = DataArray[i].Value;
            Ret.RemoveFromEnd(TEXT(";"));
            return Ret;
        }
    }
    return TEXT("");
}

const bool UExtendBlueprintFunctions::IsHeadlessClient()
{
#if USE_NULL_RHI
    return true;
#else
    return false;
#endif
}

void UExtendBlueprintFunctions::ChangePlayerMeshTranslationOffset(UCharacterMovementComponent* CharacterMovement, float MeshAdjust)
{
    FNetworkPredictionData_Client_Character* ClientData = CharacterMovement->GetPredictionData_Client_Character();
    if (ClientData)
    {
        ClientData->MeshTranslationOffset -= FVector(0.f, 0.f, MeshAdjust);
        ClientData->OriginalMeshTranslationOffset = ClientData->MeshTranslationOffset;
    }
}

void UExtendBlueprintFunctions::ChangePlayerMeshRotationOffset(UCharacterMovementComponent* CharacterMovement, FRotator Rotation)
{
    FNetworkPredictionData_Client_Character* ClientData = CharacterMovement->GetPredictionData_Client_Character();
    if (ClientData)
    {
        ClientData->MeshRotationTarget = FQuat(Rotation);
    }
    //CharacterMovement->OldBaseQuat = FQuat(Rotation);
}

FVector2D UExtendBlueprintFunctions::GetViewportSizeWithScale(UObject* WorldContextObject)
{
	const FVector2D& ViewportSize = UWidgetLayoutLibrary::GetViewportSize(WorldContextObject);
	float ViewportScale = UWidgetLayoutLibrary::GetViewportScale(WorldContextObject);
	return ViewportSize / ViewportScale;
}

void UExtendBlueprintFunctions::ClipboardCopy(const FString& Str)
{
    FPlatformApplicationMisc::ClipboardCopy(*Str);
}

void UExtendBlueprintFunctions::ClipboardPaste(FString& Dest)
{
    FPlatformApplicationMisc::ClipboardPaste(Dest);
}

FVector UExtendBlueprintFunctions::GetAISafePosition(UObject* WorldContextObject, const FVector& Origin, float Radius, float AddZ, float MinusZ)
{
    UWorld* World = WorldContextObject->GetWorld();

    UPiratesGridTypeManager* GridTypeManager = UCommonShell::GetCommon(WorldContextObject)->GetGridTypeManager();
    // trace down first
    const float ExtendZ = 100;
    FVector NewOrigin = Origin;
    EPiratesGridRegionType RegionType = GridTypeManager->GetRegionType(Origin.X, Origin.Y);
    // if land position is port, we should move to shore, otherwise will get stucked.
    if (RegionType == EPiratesGridRegionType::Port || RegionType == EPiratesGridRegionType::Land || RegionType == EPiratesGridRegionType::Shore)
    {

        if (RegionType == EPiratesGridRegionType::Port)
        {
            FVector2D OutPosition;
            if (GridTypeManager->GetClosestPositionOfRegionType(Origin.X, Origin.Y, EPiratesGridRegionType::Shore, OutPosition))
            {
                NewOrigin.X = OutPosition.X;
                NewOrigin.Y = OutPosition.Y;
            }
        }

        FVector Location = NewOrigin;

        // trace for terrain
        ECollisionChannel CollisionChannel = ECollisionChannel::ECC_WorldStatic;

        FHitResult OutHit;
        FVector WorldOrigin = Location;
        FVector WorldDirection = Location + FVector(0.0f, 0.0f, MinusZ);
        bool bHit = World->LineTraceSingleByChannel(OutHit, WorldOrigin, WorldDirection, CollisionChannel);
        if (bHit && OutHit.IsValidBlockingHit())
        {
            return OutHit.Location + FVector(0, 0, ExtendZ);
        }

        // if not found,trace upside
        WorldOrigin = Location;
        WorldDirection = Location + FVector(0.0f, 0.0f, AddZ);
        bHit = World->LineTraceSingleByChannel(OutHit, WorldOrigin, WorldDirection, CollisionChannel);
        if (bHit && OutHit.IsValidBlockingHit())
        {
            return OutHit.Location + FVector(0, 0, ExtendZ);
        }

    }

    // find a navigable posiiton
    if (Radius > 0)
    {
        UNavigationSystemV1* NavSys = UNavigationSystemV1::GetCurrent(World);
        if (NavSys)
        {
            const unsigned int MaxIterationTime = 5;
            for (size_t i = 0; i < MaxIterationTime; i++)
            {
                FNavLocation ResultLocation;
                if (NavSys->GetRandomPointInNavigableRadius(NewOrigin, Radius, ResultLocation))
                {
                    return ResultLocation.Location + FVector(0, 0, ExtendZ);
                }
                Radius = Radius * 2;
            }
        }
    }

    return Origin;
}

void UExtendBlueprintFunctions::SetLargeCoordPrecisionOptimize(AActor* Actor, bool Value)
{
	TInlineComponentArray<USkeletalMeshComponent*> SkeletalMeshes;
	Actor->GetComponents(SkeletalMeshes);
	for (auto Mesh : SkeletalMeshes)
	{
		Mesh->bUseLargeCoordPrecisionOptimize = Value;
	}
}


void UExtendBlueprintFunctions::HideActorHairComponent(AActor* Actor, bool Value)
{
	TInlineComponentArray<USkeletalMeshComponent*> SkeletalMeshes;
	Actor->GetComponents(SkeletalMeshes);

	for (auto Mesh : SkeletalMeshes)
	{
		if (Mesh->ComponentTags.Contains(FName(TEXT("SkeletalRoot"))))
		{
			continue;
		}
		USkeletalMesh* SkeletalMesh = Mesh->SkeletalMesh;
		for (int32 mIndex = 0; mIndex < SkeletalMesh->Materials.Num(); ++mIndex)
		{
			FString MatSlotName = SkeletalMesh->Materials[mIndex].MaterialSlotName.ToString();
			if (MatSlotName.ToLower().Equals(FString(TEXT("hair"))))
			{
				Mesh->SetVisibility(!Value);
			}
		}
	}

}

void UExtendBlueprintFunctions::GetClassFunctionAndPropertyNames(const FString& Name, TArray<FName>& OutPropertyNames, TArray<FName>& OutFunctionNames)
{
    UStruct* Class = Cast<UStruct>(StaticFindObject(UClass::StaticClass(), ANY_PACKAGE, *Name));
    if (!Class)
    {
        return;
    }

    for (auto* Property = Class->PropertyLink; Property; Property = Property->PropertyLinkNext)
    {
        OutPropertyNames.Add(Property->GetFName());
    }

    TFunction<void(UStruct* Class, TArray<FName>& TempOutFunctionNames)> CollectFunctionRecursively;

    CollectFunctionRecursively = [&](UStruct* Struct, TArray<FName>& TempOutFunctionNames) {
        for (auto* Field = Struct->Children; Field; Field = Field->Next)
        {
            if (Cast<UFunction>(Field))
            {
                FName FunctionName = Field->GetFName();
                TempOutFunctionNames.AddUnique(FunctionName);
            }
        }

        auto SuperStruct = Struct->GetSuperStruct();
        if (SuperStruct && SuperStruct != UObject::StaticClass())
        {
            CollectFunctionRecursively(SuperStruct, TempOutFunctionNames);
        }
    };

    CollectFunctionRecursively(Class, OutFunctionNames);
}

void UExtendBlueprintFunctions::GetEnumPropertyNames(const FString& Name, TArray<FName>& OutPropertyNames)
{
    UEnum* Enum = Cast<UEnum>(StaticFindObject(UEnum::StaticClass(), ANY_PACKAGE, *Name));
    if (!Enum)
    {
        return;
    }

    auto Num = Enum->NumEnums();
    if (auto UserDefinedEnum = Cast<UUserDefinedEnum>(Enum))
    {
        for (int32 i = 0; i < Num; ++i)
        {
            OutPropertyNames.AddUnique(*UserDefinedEnum->GetDisplayNameTextByIndex(i).ToString());
        }
    }
    else
    {
        for (int32 i = 0; i < Num; ++i)
        {
            OutPropertyNames.AddUnique(*Enum->GetNameStringByIndex(i));
        }
    }
}

void UExtendBlueprintFunctions::DumpActiveSounds(UObject* WorldContextObject)
{
#if !UE_BUILD_SHIPPING
    UWorld* World = WorldContextObject->GetWorld();
    if (FAudioDeviceHandle AudioDevice = (World ? World->GetAudioDevice() : GEngine->GetMainAudioDevice()))
    {
        check(false && TEXT("DumpActiveSounds removed."));
        //AudioDevice->DumpActiveSounds();
    }
#endif
}

bool UExtendBlueprintFunctions::IsActorSpeedGreaterThan(AActor *Actor, float Speed, bool bIngoreZ /* = false */)
{
    FVector Velocity = Actor->GetVelocity();
    float CurrentSpeed = bIngoreZ ? Velocity.Size2D() : Velocity.Size();
    return CurrentSpeed > Speed;
}

float UExtendBlueprintFunctions::GetActorSpeed(AActor *Actor, bool bIngoreZ /* = false */)
{
    FVector Velocity = Actor->GetVelocity();
    float CurrentSpeed = bIngoreZ ? Velocity.Size2D() : Velocity.Size();
    return CurrentSpeed;
}

bool UExtendBlueprintFunctions::GetGameConfigBool(const FString& Section, const FString& Key, bool DefaultValue)
{
    bool OutValue = DefaultValue;
    if (GConfig->GetBool(*Section, *Key, OutValue, GGameIni))
    {
        return OutValue;
    }
    else
    {
        return DefaultValue;
    }
}

int UExtendBlueprintFunctions::GetGameConfigInt(const FString& Section, const FString& Key, int DefaultValue)
{
    int OutValue = DefaultValue;
    if (GConfig->GetInt(*Section, *Key, OutValue, GGameIni))
    {
        return OutValue;
    }
    else
    {
        return DefaultValue;
    }
}

int32 UExtendBlueprintFunctions::GetCVarValueOnAnyThreadInt(const FString& CVarStr)
{
	int32 Val = 0;
	TConsoleVariableData<int32>* Var = IConsoleManager::Get().FindTConsoleVariableDataInt(*CVarStr);
	if (Var)
	{
		Val = Var->GetValueOnAnyThread();
	}
	else
	{
		UE_LOG(ExtendBPFuncLibLog, Warning, TEXT("[Pir] Failed to find console variable '%s'."), *CVarStr);
	}
	return Val;
}

float UExtendBlueprintFunctions::GetCVarValueOnAnyThreadFloat(const FString& CVarStr)
{
	float Val = 0.f;
	TConsoleVariableData<float>* Var = IConsoleManager::Get().FindTConsoleVariableDataFloat(*CVarStr);
	if (Var)
	{
		Val = Var->GetValueOnAnyThread();
	}
	else
	{
		UE_LOG(ExtendBPFuncLibLog, Warning, TEXT("[Pir] Failed to find console variable '%s'."), *CVarStr);
	}
	return Val;
}

float UExtendBlueprintFunctions::GetPlatformMilliseconds()
{
    return FPlatformTime::ToMilliseconds64(FPlatformTime::Cycles64());
}

float UExtendBlueprintFunctions::GetSoundMaxDistance(USoundBase* Sound)
{
    if (Sound)
    {
        const FSoundAttenuationSettings* AttenuationSettings = Sound->GetAttenuationSettingsToApply();
        if (AttenuationSettings)
        {
            return AttenuationSettings->GetMaxDimension();
        }
    }
    return 0;
}

void UExtendBlueprintFunctions::ReloadLocalizationResources()
{
	FInternationalization::Get().OnCultureChanged().Broadcast();
}

void UExtendBlueprintFunctions::ScreenToWidgetLocal(UObject* WorldContextObject, const FGeometry& Geometry, FVector2D ScreenPosition, FVector2D& LocalCoordinate)
{
	FVector2D AbsoluteCoordinate;
	ScreenToWidgetAbsolute(WorldContextObject, ScreenPosition, AbsoluteCoordinate);

	LocalCoordinate = Geometry.AbsoluteToLocal(AbsoluteCoordinate);
}


void UExtendBlueprintFunctions::ScreenToWidgetAbsolute(UObject* WorldContextObject, FVector2D ScreenPosition, FVector2D& AbsoluteCoordinate)
{
	UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);
	if (World && World->IsGameWorld())
	{
		if (UGameViewportClient* ViewportClient = World->GetGameViewport())
		{
			TSharedPtr<IGameLayerManager> GameLayerManager = ViewportClient->GetGameLayerManager();
			if (GameLayerManager.IsValid())
			{
				FVector2D ViewportSize;
				ViewportClient->GetViewportSize(ViewportSize);

				const FGeometry& ViewportGeometry = GameLayerManager->GetViewportWidgetHostGeometry();
				const FVector2D ViewportPosition = ViewportGeometry.GetLocalSize() * (ScreenPosition / ViewportSize);

				AbsoluteCoordinate = ViewportGeometry.LocalToAbsolute(ViewportPosition);
				return;
			}
		}
	}

	AbsoluteCoordinate = FVector2D(0, 0);
}

void UExtendBlueprintFunctions::HideVirtualKeyboard()
{
	FSlateApplication::Get().ShowVirtualKeyboard(false, 0);
}

int32 UExtendBlueprintFunctions::CheckAttackIllegal(UObject* WorldContextObject, const FVector& StartPos, const FVector& CameraPos)
{
    TArray<TEnumAsByte<EObjectTypeQuery>> ObjectTypeArray;
    TArray<AActor*> IgnoreActorArray;
    TArray<FHitResult> OutHits;

    ObjectTypeArray.Add(UEngineTypes::ConvertToObjectType(ECC_WorldStatic));

    bool bHit = UKismetSystemLibrary::LineTraceMultiForObjects(WorldContextObject, CameraPos, StartPos, ObjectTypeArray, false, IgnoreActorArray, EDrawDebugTrace::None, OutHits, true);
    if (bHit)
    {
        return -2;      // Might be shooting through a wall
    }

    return 0;
}

bool UExtendBlueprintFunctions::IsModuleLoaded(const FName ModleName)
{
    return FModuleManager::Get().IsModuleLoaded(ModleName);
}

#if ENABLE_DRAW_DEBUG

void DrawDebugSweptSphereEx(const UWorld* InWorld, FVector const& Start, FVector const& End, float Radius, FColor const& Color, bool bPersistentLines, float LifeTime, uint8 DepthPriority)
{
    FVector const TraceVec = End - Start;
    float const Dist = TraceVec.Size();

    FVector const Center = Start + TraceVec * 0.5f;
    float const HalfHeight = (Dist * 0.5f) + Radius;

    FQuat const CapsuleRot = FRotationMatrix::MakeFromZ(TraceVec).ToQuat();
    ::DrawDebugCapsule(InWorld, Center, HalfHeight, Radius, CapsuleRot, Color, bPersistentLines, LifeTime, DepthPriority);
}

#endif

float UExtendBlueprintFunctions::GetCollisionDistance(UObject* WorldContextObject, float Radius, const FVector& From, const FVector& To)
{
    UWorld* World = WorldContextObject->GetWorld();
    static const FName LineTraceName(TEXT("GetCollisionDistance"));
    FCollisionQueryParams Params(LineTraceName, false);
    Params.bFindInitialOverlaps = false;
    AActor* IgnoreActor = Cast<AActor>(WorldContextObject);
    if (IgnoreActor)
    {
        Params.AddIgnoredActor(IgnoreActor);
    }
    FHitResult OutHit;
    ECollisionChannel CollisionChannel = ECollisionChannel::ECC_WorldStatic;
    bool const bHit = World->SweepSingleByChannel(OutHit, From, To, FQuat::Identity, CollisionChannel, FCollisionShape::MakeSphere(Radius), Params);
#if ENABLE_DRAW_DEBUG

    {
        bool bPersistent = true;
        float LifeTime = 10.f;
        FLinearColor TraceColor = FLinearColor::Green;
        FLinearColor TraceHitColor = FLinearColor::Red;
        // @fixme, draw line with thickness = 2.f?
        if (bHit && OutHit.bBlockingHit)
        {
            // Red up to the blocking hit, green thereafter
            ::DrawDebugSweptSphereEx(World, From, OutHit.ImpactPoint, Radius, TraceColor.ToFColor(true), bPersistent, LifeTime, 0);
            ::DrawDebugSweptSphereEx(World, OutHit.ImpactPoint, To, Radius, TraceHitColor.ToFColor(true), bPersistent, LifeTime, 0);
            ::DrawDebugPoint(World, OutHit.ImpactPoint, 16.f, TraceColor.ToFColor(true), bPersistent, LifeTime);
        }
        else
        {
            // no hit means all red
            ::DrawDebugSweptSphereEx(World, From, To, Radius, TraceColor.ToFColor(true), bPersistent, LifeTime, 0);
        }
    }

#endif

    return bHit ? OutHit.Distance : -1;
}

APawn* UExtendBlueprintFunctions::GetHumanCharacter(APawn* Pawn)
{
	if (auto MountCharacter = Cast<APiratesMountCharacter>(Pawn))
	{
		TArray<AActor*> Actors;
		MountCharacter->GetAttachedActors(Actors);
		for (auto Actor : Actors)
		{
			if (auto Character = Cast<AKMCharacter>(Actor))
			{
				return Character;
			}
		}
	}
	return Pawn;
}

/** @RETURN True if weapon trace from Origin hits component VictimComp.  OutHitResult will contain properties of the hit. */
static bool ComponentIsDamageableFromEx(UPrimitiveComponent* VictimComp, FVector const& Origin, AActor const* IgnoredActor, const TArray<AActor*>& IgnoreActors, ECollisionChannel TraceChannel, FHitResult& OutHitResult)
{
	FCollisionQueryParams LineParams(SCENE_QUERY_STAT(ComponentIsVisibleFrom), true, IgnoredActor);
	LineParams.AddIgnoredActors(IgnoreActors);

	// Do a trace from origin to middle of box
	UWorld* const World = VictimComp->GetWorld();
	check(World);

	FVector const TraceEnd = VictimComp->Bounds.Origin;
	FVector TraceStart = Origin;
	if (Origin == TraceEnd)
	{
		// tiny nudge so LineTraceSingle doesn't early out with no hits
		TraceStart.Z += 0.01f;
	}
	bool const bHadBlockingHit = World->LineTraceSingleByChannel(OutHitResult, TraceStart, TraceEnd, TraceChannel, LineParams);
	//::DrawDebugLine(World, TraceStart, TraceEnd, FLinearColor::Red, true);

	// If there was a blocking hit, it will be the last one
	if (bHadBlockingHit)
	{
		if (OutHitResult.Component == VictimComp)
		{
			// if blocking hit was the victim component, it is visible
			return true;
		}
		else
		{
			// if we hit something else blocking, it's not
			UE_LOG(LogDamage, Log, TEXT("Radial Damage to %s blocked by %s (%s)"), *GetNameSafe(VictimComp), *GetNameSafe(OutHitResult.GetActor()), *GetNameSafe(OutHitResult.Component.Get()));
			return false;
		}
	}

	// didn't hit anything, assume nothing blocking the damage and victim is consequently visible
	// but since we don't have a hit result to pass back, construct a simple one, modeling the damage as having hit a point at the component's center.
	FVector const FakeHitLoc = VictimComp->GetComponentLocation();
	FVector const FakeHitNorm = (Origin - FakeHitLoc).GetSafeNormal();		// normal points back toward the epicenter
	OutHitResult = FHitResult(VictimComp->GetOwner(), VictimComp, FakeHitLoc, FakeHitNorm);
	return true;
}


bool UExtendBlueprintFunctions::ApplyRadialDamageWithFalloffEx(const UObject* WorldContextObject, float BaseDamage, float MinimumDamage,const FVector& Origin, float DamageInnerRadius, float DamageOuterRadius, float DamageFalloff, TSubclassOf<class UDamageType> DamageTypeClass, const TArray<AActor*>& IgnoreActors, AActor* DamageCauser, AController* InstigatedByController, ECollisionChannel DamagePreventionChannel, AActor* DamageLauncher)
{
	FCollisionQueryParams SphereParams(SCENE_QUERY_STAT(ApplyRadialDamage), false, DamageCauser);

	SphereParams.AddIgnoredActors(IgnoreActors);

	// query scene to see what we hit
	TArray<FOverlapResult> Overlaps;
	if (UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull))
	{
		World->OverlapMultiByObjectType(Overlaps, Origin, FQuat::Identity, FCollisionObjectQueryParams(FCollisionObjectQueryParams::InitType::AllDynamicObjects), FCollisionShape::MakeSphere(DamageOuterRadius), SphereParams);
	}

	// collate into per-actor list of hit components
	TMap<AActor*, TArray<FHitResult> > OverlapComponentMap;
	for (int32 Idx = 0; Idx < Overlaps.Num(); ++Idx)
	{
		FOverlapResult const& Overlap = Overlaps[Idx];
		AActor* const OverlapActor = Overlap.GetActor();

		if (OverlapActor &&
			OverlapActor->CanBeDamaged() &&
			OverlapActor != DamageCauser &&
			Overlap.Component.IsValid())
		{
			FHitResult Hit;
			if (DamagePreventionChannel == ECC_MAX || ComponentIsDamageableFromEx(Overlap.Component.Get(), Origin, DamageCauser, IgnoreActors, DamagePreventionChannel, Hit))
			{
				TArray<FHitResult>& HitList = OverlapComponentMap.FindOrAdd(OverlapActor);
				HitList.Add(Hit);
			}
		}
	}

	bool bAppliedDamage = false;

	if (OverlapComponentMap.Num() > 0)
	{
		// make sure we have a good damage type
		TSubclassOf<UDamageType> const ValidDamageTypeClass = DamageTypeClass ? DamageTypeClass : TSubclassOf<UDamageType>(UDamageType::StaticClass());

		FRadialDamageEvent DmgEvent;
		DmgEvent.DamageTypeClass = ValidDamageTypeClass;
		DmgEvent.Origin = Origin;
		DmgEvent.Params = FRadialDamageParams(BaseDamage, MinimumDamage, DamageInnerRadius, DamageOuterRadius, DamageFalloff);

		// call damage function on each affected actors
		AActor* LastVictim = nullptr;
		TArray<FHitResult> LastVictimHits;
		for (TMap<AActor*, TArray<FHitResult> >::TIterator It(OverlapComponentMap); It; ++It)
		{
			AActor* const Victim = It.Key();

			if (DamageLauncher && IsValid(DamageLauncher) && Victim == DamageLauncher)
			{
				LastVictim = It.Key();
				LastVictimHits = It.Value();
			}
			else
			{
				TArray<FHitResult> const& ComponentHits = It.Value();
				DmgEvent.ComponentHits = ComponentHits;
				Victim->TakeDamage(BaseDamage, DmgEvent, InstigatedByController, DamageCauser);
			}

			bAppliedDamage = true;
		}

		if (LastVictim && LastVictimHits.Num() != 0)
		{
			DmgEvent.ComponentHits = LastVictimHits;
			LastVictim->TakeDamage(BaseDamage, DmgEvent, InstigatedByController, DamageCauser);
		}
	}

	return bAppliedDamage;
}

static float GetRealDamageWithCurve(const TArray<FHitResult>& Hits, float BaseDamage, UCurveFloat* DamageCurve, const FVector& Origin, float DamageRadius)
{
	float ActualDamage = BaseDamage;
	FVector ClosestHitLoc(0);
	float ClosestHitDistSq = MAX_FLT;
	for (int32 HitIdx = 0; HitIdx < Hits.Num(); ++HitIdx)
	{
		FHitResult const& Hit = Hits[HitIdx];
		float const DistSq = (Hit.ImpactPoint - Origin).SizeSquared();
		if (DistSq < ClosestHitDistSq)
		{
			ClosestHitDistSq = DistSq;
			ClosestHitLoc = Hit.ImpactPoint;
		}
	}


	float DistanceFromEpicenter = FMath::Sqrt(ClosestHitDistSq);
	float ValidatedDist = FMath::Max(0.f, DistanceFromEpicenter);
	if (ValidatedDist > DamageRadius || ValidatedDist <= 0.f)
		ActualDamage = 0.f;

	float DamageScale = DamageCurve->GetFloatValue(ValidatedDist / DamageRadius);
	ActualDamage = DamageScale * BaseDamage;
	return ActualDamage;
}

bool UExtendBlueprintFunctions::ApplyRadialDamageWithCurveEx(const UObject* WorldContextObject, float BaseDamage, const FVector& Origin, float DamageRadius, UCurveFloat* DamageCurve, TSubclassOf<class UDamageType> DamageTypeClass, const TArray<AActor*>& IgnoreActors, AActor* DamageCauser , AController* InstigatedByController , ECollisionChannel DamagePreventionChannel, AActor* DamageLauncher )
{
	FCollisionQueryParams SphereParams(SCENE_QUERY_STAT(ApplyRadialDamage), false, DamageCauser);

	SphereParams.AddIgnoredActors(IgnoreActors);

	// query scene to see what we hit
	TArray<FOverlapResult> Overlaps;
	if (UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull))
	{
		World->OverlapMultiByObjectType(Overlaps, Origin, FQuat::Identity, FCollisionObjectQueryParams(FCollisionObjectQueryParams::InitType::AllDynamicObjects), FCollisionShape::MakeSphere(DamageRadius), SphereParams);
	}

	// collate into per-actor list of hit components
	TMap<AActor*, TArray<FHitResult> > OverlapComponentMap;
	for (int32 Idx = 0; Idx < Overlaps.Num(); ++Idx)
	{
		FOverlapResult const& Overlap = Overlaps[Idx];
		AActor* const OverlapActor = Overlap.GetActor();

		if (OverlapActor &&
			OverlapActor->CanBeDamaged() &&
			OverlapActor != DamageCauser &&
			Overlap.Component.IsValid())
		{
			FHitResult Hit;
			if (DamagePreventionChannel == ECC_MAX || ComponentIsDamageableFromEx(Overlap.Component.Get(), Origin, DamageCauser, IgnoreActors, DamagePreventionChannel, Hit))
			{
				TArray<FHitResult>& HitList = OverlapComponentMap.FindOrAdd(OverlapActor);
				HitList.Add(Hit);
			}
		}
	}

	bool bAppliedDamage = false;

	if (OverlapComponentMap.Num() > 0)
	{
		// make sure we have a good damage type
		TSubclassOf<UDamageType> const ValidDamageTypeClass = DamageTypeClass ? DamageTypeClass : TSubclassOf<UDamageType>(UDamageType::StaticClass());

		FDamageEvent DmgEvent;
		DmgEvent.DamageTypeClass = ValidDamageTypeClass;

		// call damage function on each affected actors
		AActor* LastVictim = nullptr;
		TArray<FHitResult> LastVictimHits;
		float RealDamage = 0.f;
		for (TMap<AActor*, TArray<FHitResult> >::TIterator It(OverlapComponentMap); It; ++It)
		{
			AActor* const Victim = It.Key();

			if (DamageLauncher && IsValid(DamageLauncher) && Victim == DamageLauncher)
			{
				LastVictim = It.Key();
				LastVictimHits = It.Value();
			}
			else
			{
				TArray<FHitResult> const& ComponentHits = It.Value();
				RealDamage = GetRealDamageWithCurve(ComponentHits, BaseDamage, DamageCurve, Origin, DamageRadius);
				Victim->TakeDamage(RealDamage, DmgEvent, InstigatedByController, DamageCauser);
			}

			bAppliedDamage = true;
		}

		if (LastVictim && LastVictimHits.Num() != 0)
		{
			RealDamage = GetRealDamageWithCurve(LastVictimHits, BaseDamage, DamageCurve, Origin, DamageRadius);
			LastVictim->TakeDamage(RealDamage, DmgEvent, InstigatedByController, DamageCauser);
		}
	}

	return bAppliedDamage;
}


FString UExtendBlueprintFunctions::GetClassPathName(UClass* Class)
{
	ReturnIfNullptr(Class, FString());
	return Class->GetPathName();
}

int32 UExtendBlueprintFunctions::GetPing(UObject* WorldContextObject)
{
	int32 MaxPing = 460;
	float PingTimeOut = 2.f;
	GConfig->GetInt(TEXT("Ping"), TEXT("MaxPing"), MaxPing, GGameIni);
	GConfig->GetFloat(TEXT("Ping"), TEXT("PingTimeOut"), PingTimeOut, GGameIni);

	int32 Ping = MaxPing;
	UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull);
	if (World)
	{
		APlayerController* PlayerController = World->GetFirstPlayerController();
		if (PlayerController && PlayerController->PlayerState)
		{
			UNetConnection* NetConnection = PlayerController->GetNetConnection();
			if (NetConnection && NetConnection->GetDriver())
			{
				if ((NetConnection->GetDriver()->GetElapsedTime() - NetConnection->LastReceiveTime) < PingTimeOut)
				{
					Ping = ((int32)PlayerController->PlayerState->GetPing()) * 2;	// PlayerState中的Ping要乘4才是真实值(咱们项目中在PiratesPlayerState上做了优化调整，乘以2即可，超过500ms)
					// Ping = Ping + FMath::RandRange(-2, 2);					// 为了避免Ping值总是4的倍数，做一定的随机
					Ping = FMath::Clamp(Ping, 0, MaxPing);						// 保证Ping值在正常区间
				}
			}
		}
	}
	return Ping;
}

FTransform UExtendBlueprintFunctions::GetComponentSlotRelativeTransform(USceneComponent* Component,const FName& SlotName, const FTransform& ComponentRelativeTransform)
{
    if (Component)
    {
        return ComponentRelativeTransform * Component->GetSocketTransform(SlotName, RTS_Component).Inverse();
    }
    return FTransform::Identity;
}


FString UExtendBlueprintFunctions::GetHost(UObject* WorldContextObject)
{
    if (WorldContextObject)
    {
        if (UWorld* World = WorldContextObject->GetWorld())
        {
            bool bCanBindAll = false;
            TSharedRef<FInternetAddr> LocalIp = ISocketSubsystem::Get(PLATFORM_SOCKETSUBSYSTEM)->GetLocalHostAddr(*GLog, bCanBindAll);

            return LocalIp->IsValid() ? LocalIp->ToString(false) : World->URL.Host;
        }
    }
    return "";
}


FString UExtendBlueprintFunctions::GetPort(UObject* WorldContextObject)
{
    if (WorldContextObject)
    {
        if (UWorld* World = WorldContextObject->GetWorld())
        {
            return FString::FromInt(World->URL.Port);
        }
    }
    return "";
}

void UExtendBlueprintFunctions::AddOnScreenDebugMessage(int32 Key, float TimeToDisplay, FLinearColor DisplayColor, const FString& DebugMessage, bool bNewerOnTop, const FVector2D& TextScale)
{
    GEngine->AddOnScreenDebugMessage(Key, TimeToDisplay, DisplayColor.ToFColor(true), DebugMessage, bNewerOnTop, TextScale);
}

bool UExtendBlueprintFunctions::HasCommandLineParam(const FString& Param)
{
    return FParse::Param(FCommandLine::Get(), *Param);;
}

bool UExtendBlueprintFunctions::CheckIsInSquaredDistance(AActor * ActorA, AActor * ActorB, float SquaredDistance)
{
    ReturnIfNullptr(ActorA, false);
    ReturnIfNullptr(ActorB, false);
    return ActorA->GetSquaredDistanceTo(ActorB) <= SquaredDistance;
}

bool UExtendBlueprintFunctions::IsValidResourcePos(const UObject* WorldContextObject, const FVector& ResourcePos, float StartOffset, float EndOffset, float LandscapeStartOffset, float LandscapeEndOffset, FVector& OutPos)
{
    UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull);
    if (World == nullptr)
    {
        return true;
    }

    //检测是否在距离很小的两层之间
    FVector StartTrace = ResourcePos + FVector(0, 0, StartOffset);
    FVector EndTrace = ResourcePos + FVector(0, 0, EndOffset);
    TArray<AActor*> ActorsToIgnore;
    FHitResult HitResult;
    TArray<TEnumAsByte<EObjectTypeQuery> >  ObjectTypes;
    ObjectTypes.Add(UEngineTypes::ConvertToObjectType(ECollisionChannel::ECC_WorldStatic));
    if (UKismetSystemLibrary::LineTraceSingleForObjects(World, StartTrace, EndTrace, ObjectTypes, false, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true))
    {
        OutPos = HitResult.ImpactPoint;
        return false;
    }

    //检测是否在landscape之下
    StartTrace = ResourcePos + FVector(0, 0, LandscapeStartOffset);
    EndTrace = ResourcePos + FVector(0, 0, LandscapeEndOffset);
    TArray<FHitResult> HitResults;
    if (UKismetSystemLibrary::LineTraceMultiForObjects(World, StartTrace, EndTrace, ObjectTypes, false, ActorsToIgnore, EDrawDebugTrace::None, HitResults, true))
    {
        for (int32 i = 0; i < HitResults.Num(); i++)
        {
            HitResult = HitResults[i];
            if (HitResult.bBlockingHit)
            {
                ALandscape* Landscape = Cast< ALandscape >(HitResult.GetActor());
                if (Landscape != nullptr && HitResult.ImpactPoint.Z > ResourcePos.Z + EndOffset)
                {
                    OutPos = HitResult.ImpactPoint;
                    return false;
                }
            }
        }
    }

    return true;
}

int UExtendBlueprintFunctions::GetFPS()
{
    return (int)(1.0f / FApp::GetDeltaTime());
}

float UExtendBlueprintFunctions::GetAdjustRotationPitch(AActor* Actor, const FVector& HitNormal)
{
    ReturnIfNullptr(Actor, 0);
    const FVector UpVector = Actor->GetActorUpVector();

    FVector RotationAxis = FVector::CrossProduct(UpVector, HitNormal);
    RotationAxis.Normalize();
    float RotationAngleRad = FMath::Acos(FVector::DotProduct(UpVector, HitNormal));
    FQuat Quat = FQuat(RotationAxis, RotationAngleRad);

    FQuat NewQuat = Quat * Actor->GetActorQuat();
    FRotator NewRotator = NewQuat.Rotator();
    return NewRotator.Pitch;
}

void UExtendBlueprintFunctions::SetUseMouseForTouch(bool bUseMouseForTouch)
{
    UInputSettings *InputSettings = GetMutableDefault<UInputSettings>();
    InputSettings->bUseMouseForTouch = bUseMouseForTouch;
    FSlateApplication::Get().SetGameIsFakingTouchEvents(bUseMouseForTouch);
}

APlayerController* UExtendBlueprintFunctions::GetFirstLocalPlayerController(UObject* WorldContextObject)
{
    UGameInstance* GameInstance = UGameplayStatics::GetGameInstance(WorldContextObject);
    ReturnIfNullptr(GameInstance, nullptr)
    return GameInstance->GetFirstLocalPlayerController();
}


void UExtendBlueprintFunctions::UpdateSkeletalComponentAnim(USkeletalMeshComponent* SkeletalMeshComponent)
{
    if (SkeletalMeshComponent->GetAnimationMode() == EAnimationMode::Type::AnimationBlueprint)
    {
        //UAnimInstance* AnimInst = SkeletalMeshComponent->GetAnimInstance();
        //if (AnimInst)
        //{
        //    //AnimInst->Montage_Stop(0.f);
        //    AnimInst->UpdateAnimation(0.f, false);
        //}
        SkeletalMeshComponent->RefreshBoneTransforms();
        SkeletalMeshComponent->RefreshSlaveComponents();
        SkeletalMeshComponent->UpdateComponentToWorld();
    }
}


void UExtendBlueprintFunctions::TestShaderCoreReload()
{
/*
    FPakPlatformFile* PakFileMgr = (FPakPlatformFile*)(FPlatformFileManager::Get().FindPlatformFile(TEXT("PakFile")));
    if (PakFileMgr)
    {
        FString PatchPakPath = FPaths::ProjectPersistentDownloadDir() / TEXT("Patch.pak");
        PakFileMgr->Mount(*PatchPakPath, 5);
    }
    FShaderCodeLibrary::OpenLibrary(FApp::GetProjectName(), FPaths::ProjectContentDir());
*/
}

bool UExtendBlueprintFunctions::IsGarbageCollecting()
{
    return ::IsGarbageCollecting();
}

bool UExtendBlueprintFunctions::LineIntersection(const FVector& BoxOrigin, const FVector& BoxExtent, const FVector& LineStart, const FVector& LineEnd)
{
    FBox Box = FBox::BuildAABB(BoxOrigin, BoxExtent);
    const FVector Direction = LineEnd - LineStart;
    bool Hit = FMath::LineBoxIntersection(Box, LineStart, LineEnd, Direction);
    return Hit;
}

void UExtendBlueprintFunctions::LoadLevelsImmediatelyByLocation(UWorld* InWorld, const FVector& InLoc)
{
	auto GameEngineExt = UGameEngineExt::Get(InWorld);
    if (GameEngineExt)
    {
        //GameEngineExt->UpdatePendingLoadLevelPriority(InWorld, InLoc);
        GameEngineExt->LoadLevelsImmediatelyByLocation(InLoc);
    }
}

#define ANIM_ROOT_FRAME_SCALE 1
#define ONE_SECOND_FRAME 30.0f

void UExtendBlueprintFunctions::ExportRootMotion(const UAnimSequenceBase* RootMotionSouce, float StopTime, TArray<FVector>& OutPosition)
{
    ReturnIfNullUObject(RootMotionSouce);

    const UAnimSequence* pAnimSequence = Cast<UAnimSequence>(RootMotionSouce);
    ReturnIfNullUObject(pAnimSequence);

    if (StopTime > pAnimSequence->SequenceLength)
    {
        StopTime = pAnimSequence->SequenceLength;
    }

    //int BoneIndex = CharacterOwner->GetMesh()->GetBoneIndex(RootBoneName);
    float RootMotionFrame = (pAnimSequence->GetRawNumberOfFrames() * ANIM_ROOT_FRAME_SCALE);
    for (int32 uiFrame = 0; uiFrame < RootMotionFrame; uiFrame++)
    {
        FTransform RootBone;
        float CurrentTime = uiFrame / (ONE_SECOND_FRAME * ANIM_ROOT_FRAME_SCALE);
        pAnimSequence->GetBoneTransform(RootBone, 0, CurrentTime, true);
        FVector Location = RootBone.GetLocation();
        OutPosition.Add(Location);
        if (CurrentTime > StopTime)
        {
            break;
        }
    }
}

bool UExtendBlueprintFunctions::IsPlayingSlotAnimation(const UAnimInstance* AnimInstance, FName SlotNodeName)
{
    for (int32 InstanceIndex = 0; InstanceIndex < AnimInstance->MontageInstances.Num(); InstanceIndex++)
    {
        // check if this is playing
        FAnimMontageInstance* MontageInstance = AnimInstance->MontageInstances[InstanceIndex];
        // make sure what is active right now is transient that we created by request
        if (MontageInstance )
        {
            UAnimMontage* CurMontage = MontageInstance->Montage;
            if (CurMontage)
            {
                const FAnimTrack* AnimTrack = CurMontage->GetAnimationData(SlotNodeName);
                if (AnimTrack)
                {
                    return true;
                }
            }
        }
    }
    return false;
}

float UExtendBlueprintFunctions::GetDirectionFromActor(AActor* StartActor, AActor* TargetActor)
{
    FRotator LookAtRotation = UKismetMathLibrary::FindLookAtRotation(StartActor->GetActorLocation(), TargetActor->GetActorLocation());
    FRotator StartRotation = StartActor->GetActorRotation();
    
    return LookAtRotation.Yaw - StartRotation.Yaw;
}

FString UExtendBlueprintFunctions::GetProjectLogDir()
{
    return FPaths::ProjectLogDir();
}

bool UExtendBlueprintFunctions::WriteFileLines(const TArray<FString>& Lines, const FString& Filename)
{
    return FFileHelper::SaveStringArrayToFile(Lines, *Filename, FFileHelper::EEncodingOptions::ForceUTF8, &IFileManager::Get(), EFileWrite::FILEWRITE_Append);
}