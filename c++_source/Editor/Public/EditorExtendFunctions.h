#pragma once

#include "Kismet/BlueprintFunctionLibrary.h"
#include "EditorExtendFunctions.generated.h"

UENUM()
enum class FEditorFileChangeState : uint8
{
	Modify,
	New,
	Delete,
};

USTRUCT()
struct FEditorFileChangeInfo
{
	GENERATED_USTRUCT_BODY()

	UPROPERTY()
	FString Path;

	UPROPERTY()
	FEditorFileChangeState State;

	FEditorFileChangeInfo():State(FEditorFileChangeState::Modify)
	{}
	FEditorFileChangeInfo(const FString& Temp, FEditorFileChangeState TempState) :
		Path(Temp), State(TempState)
	{}
};

class ULevelSequence;

UCLASS()
class EDITOR_API UEditorExtendFunctions : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	UFUNCTION()
	static bool SaveStringToFile(const FString& FullPath, const FString& Data);

	UFUNCTION()
	static void CollectPaths(const FString& FullPath, const FString& Extention, bool bRecursively, TArray<FString>& Out);

	UFUNCTION()
	static bool DeleteDirectory(const FString& FullPath);

    UFUNCTION()
    static bool CopyDirectory(const FString& Dest, const FString& Source, bool bDeleteOld);

	UFUNCTION()
	static bool DeleteFile(const FString& FullPath);

	UFUNCTION()
	static bool CopyFile(const FString& Dest, const FString& Source);

	UFUNCTION()
	static bool CheckFileModified(const TArray<FString>& Dirs, 
		const FString& CheckInfoFilePath,
		TArray<FEditorFileChangeInfo>& OutChangedInfo);

	UFUNCTION()
	static bool SaveFileModifiedInfo(const TArray<FString>& Dirs,
		const FString& CheckInfoFilePath);

    UFUNCTION()
    static void ShowMulticastFunction();

    UFUNCTION()
    static void ExportShipConfig(bool bForce = false);

    /**
     * 将SourceFiles中所有文件的内容，合并到TargetFilePath文件中
     */
    UFUNCTION()
    static bool ConcateFiles(const TArray<FString>& SourceFiles, const FString& TargetFilePath);

    /**
     * 非递归的获取某指定路径下的所有directory
     */
    UFUNCTION()
    static void CollectDirs(const FString& FullPath, TArray<FString>& Out);

    UFUNCTION(BlueprintCallable, Category = "Editor")
    static void CollectAssetOrDefaultObjectByDirectory(const FString& FullPath, TArray<UObject*>& Out, bool bAssetObject = true);

	UFUNCTION(BlueprintCallable, Category = "Editor")
	static void SavePackageByClass(UClass* Class);

    UFUNCTION(BlueprintCallable, Category = "Editor")
    static FString GetCurrentPersistentMapName();

	UFUNCTION(BlueprintCallable, Category = "Editor")
	static AActor* AddActorToCurrentLevel(TSubclassOf<AActor> ActorClass, const FTransform& Transform);

    UFUNCTION(BlueprintCallable, Category = "Editor")
    static FString GetCurrentLevelName();

	UFUNCTION(BlueprintCallable, Category = "Editor", meta = (CallInEditor = "true", DeterminesOutputType = "ActorClass", DynamicOutputParam = "SelectedActors"))
	static void GetSelectedActorsInEditor(TSubclassOf<AActor> ActorClass, TArray<AActor*>& SelectedActors);

    UFUNCTION(BlueprintCallable, Category = "Editor")
    static int32 GetMovieSceneLength(ULevelSequence* InLevelSequence);


	UFUNCTION()
	static bool GetFileMD5HashString(const FString& FilePath, FString& OutHashString);
};