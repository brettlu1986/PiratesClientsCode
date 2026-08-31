// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "GraphComponent.generated.h"

USTRUCT(BlueprintType)
struct FGraphNode
{
    GENERATED_USTRUCT_BODY()

    //UPROPERTY(BlueprintReadWrite, EditAnywhere)
    //int32 Index;

    UPROPERTY(BlueprintReadWrite, EditAnywhere)
    FVector Location;

    FGraphNode()
    {
        Location = FVector::ZeroVector;
        GridPos = 0;
        Dead = false;
        fRandomRage = 200;
    }

    FGraphNode(float X, float Y, float Z)
    {
        GridPos = 0;
        Dead = false;
		fRandomRage = 200;
        Location = FVector(X, Y, Z);
    }

    FGraphNode(FVector SourceLocation, float fRange)
    {
        GridPos = 0;
        Dead = false;
        Location = SourceLocation;
		fRandomRage = fRange;
    }

    // for run-time path finding.
    TArray<int32> Neighbors;

    UPROPERTY(BlueprintReadWrite, EditAnywhere)
    bool Dead;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	float fRandomRage;

public:
    int32 GridPos;
};

USTRUCT(BlueprintType)
struct FGraphEdge
{
    GENERATED_USTRUCT_BODY()

    UPROPERTY(BlueprintReadWrite, EditAnywhere)
    int32 NodeIndexA;

    UPROPERTY(BlueprintReadWrite, EditAnywhere)
    int32 NodeIndexB;

    FGraphEdge():NodeIndexA(0),
        NodeIndexB(0)
    {}

    FGraphEdge(int32 SourceNodeIndexA, int32 SourceNodeIndexB)
    {
        NodeIndexA = SourceNodeIndexA;
        NodeIndexB = SourceNodeIndexB;
    }
};

UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class COMMON_API UGraphComponent : public UActorComponent
{
	GENERATED_BODY()

public:	
	// Sets default values for this component's properties
    UGraphComponent();

public:
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Graph")
    TArray<FGraphNode> Nodes;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Graph")
    TArray<FGraphEdge> Edges;

    UFUNCTION(BlueprintCallable, Category = "Graph")
    bool InitGrid(int32 inGridSize, int32 inGridCount);

	UFUNCTION(BlueprintCallable, Category = "Graph")
	bool FindOffsetPathSimpleRandom(int32 StartNode, int32 EndNode, TArray<FVector> &OutPath);

    UFUNCTION(BlueprintCallable, Category = "Graph")
    bool FindPathSimpleRandom(int32 StartNode, int32 EndNode, TArray<int32> &OutPath);

    UFUNCTION(BlueprintCallable, Category = "Graph")
    bool FindPathSimpleRandomVec(int32 StartNode, int32 EndNode, TArray<FVector> &OutPath);

    UFUNCTION(BlueprintCallable, Category = "Graph")
    void ApplyOffsetToPath(float Offset, const TArray<FVector> &InPath, TArray<FVector> &OutPath);

    UFUNCTION(BlueprintCallable, BlueprintPure, Category = "Graph")
    FVector GetNearestNodeLocation(FVector Location);

    UFUNCTION(BlueprintCallable, BlueprintPure, Category = "Graph")
    int32 GetNearestNodeIndex(FVector Location);

	UFUNCTION()
	TArray<int32> GetNearestNodeIndexByDistance(FVector Location, int32 fDistance, int32 fNearDistance);

    UFUNCTION(BlueprintCallable, BlueprintPure, Category = "Graph")
    TArray<int32> GetNearestNodeIndexByGrid(FVector Location, bool bSelf = false);

    UFUNCTION(BlueprintCallable, BlueprintPure, Category = "Graph")
    int32 GetRandomNodeIndex();


    UFUNCTION(BlueprintCallable, BlueprintPure, Category = "Graph")
    int32 GetNearestNodeIndexFromList(FVector Location, TArray<int> NodeIndexs, int32 &ListIndex);

    UFUNCTION(BlueprintCallable, Category = "Graph")
    bool FindPathFromList(int32 StartNode, TArray<int> NodeIndexs, TArray<FVector> &OutPath);

    UFUNCTION(BlueprintCallable, BlueprintPure, Category = "Graph")
    bool InSameGrid(FVector Location, FVector OtherLocation);
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Graph")
    bool DebugMode;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Graph")
    float LineThickness;
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Graph")
    float EdgeLineThickness;

protected:
	// Called when the game starts
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

private:
    TSet<int32> CheckedNodes;

    bool SearchSubGraphForPathRandom(int32 StartNode, int32 EndNode, TArray<int32> &OutPath);
		
    void CollectNodeNeighbors();

    int32 GridSize;

    int32 GridCount;
	
};
