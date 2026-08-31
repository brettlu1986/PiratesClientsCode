//yangjingzhao add for loading in carribean ocean
#pragma once


#include "KMLevelLoadingVolume.generated.h"

// for setting lod bias
DECLARE_DELEGATE_OneParam(FSetStaticMeshLODModel, FString);
//~end

UCLASS(BlueprintType, Blueprintable)
class ENGINEEXT_API AKMLevelLoadingVolume : public APhysicsVolume
{
	GENERATED_UCLASS_BODY()

	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "Level|Loading")
	FString LevelStreamingPath;

	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "Level|Loading")
	FString LowDetailPath;

	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "Level|Loading")
	bool IsForPort = false;

	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "Level|Loading")
	bool IsHighDetail = false;

	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "Level|Loading")
	bool HasLowDetail = false;

	void ActorEnteredVolume1(class AActor* Other);

	void ActorLeavingVolume1(class AActor* Other);

	virtual void NotifyActorBeginOverlap(AActor* OtherActor) override;

	virtual void NotifyActorEndOverlap(AActor* OtherActor) override;

	virtual void BeginPlay() override;

    UFUNCTION()
	void OnLoadCompleted();

	UFUNCTION()
	void OnUnloadCompleted();

	void InitialyLoadLevelStreaming();

public:
    // for setting static mesh lod model
    FSetStaticMeshLODModel SetStaticMeshLODModel;
    //~end

private:

	TArray<FString> TempOtherNames;

	UPROPERTY()
	bool bInvolume = false;

	//处理刚进入大港时的情况；处理后置为true
	//其他情况处理进入volume需要在isInitaillyLoaded为true的情况下进行
	UPROPERTY()
	bool isInitaillyLoaded = false;
};