// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "ProceduralMeshComponent.h"
#include "LocalOceanComponent.generated.h"

/**
 * 
 */
UCLASS(ClassGroup = Ship, meta = (BlueprintSpawnableComponent), Blueprintable)
class COMMON_API ULocalOceanComponent : public UActorComponent
{
	GENERATED_BODY()

public:
    UPROPERTY(Category = LocalOcean, EditAnywhere, BlueprintReadWrite)
    TArray<UMaterialInterface*> DebuggingMaterials;


    // The mesh to visualize the sea surface. We can use a default mesh to show the simulation itself or use use a mesh created
    // according to an external source (static mesh component typically).
    UPROPERTY(Transient, Category = LocalOcean, EditAnywhere, BlueprintReadWrite)
    UProceduralMeshComponent* ProceduralMesh;
    
    // The adopted height field resolution. The sizes of the 2D arrays are decided by MAX_HEIGHT_FIELD_SIZE, but only part of it is used.
    UPROPERTY(Category = LocalOcean, EditAnywhere, BlueprintReadWrite)
    int HEIGHT_FIELD_SIZE = 256;

    // The world space units for the distance between 2 adjacent height value.
    UPROPERTY(Category = LocalOcean, EditAnywhere, BlueprintReadWrite)
    float CELL_SIZE = 100.0f;
    
    // How hard the surface can be.
    UPROPERTY(Category = LocalOcean, EditAnywhere, BlueprintReadWrite)
    float FORCE_FACTOR = 1.0f;
    
    // The velocity loss.
    UPROPERTY(Category = LocalOcean, EditAnywhere, BlueprintReadWrite)
    float DAMPING = 0.99f;

    // Use a generated default mesh to visualize the simulation itself(heightfield) when not set.
    UPROPERTY(Category = LocalOcean, EditAnywhere, BlueprintReadWrite)
    UStaticMesh* SourceMesh;

    // Use a generated default mesh to visualize the simulation itself(heightfield) when not set.
    UPROPERTY(Category = LocalOcean, EditAnywhere, BlueprintReadWrite)
    int SourceMeshSectionIndex;


    // The material for the procedural mesh.
    UPROPERTY(Category = LocalOcean, EditAnywhere, BlueprintReadWrite)
    UMaterialInterface* Material;

    //// The switch for some debugging behaviors.
    //UPROPERTY(Category = LocalOcean, EditAnywhere, BlueprintReadWrite)
    //bool Debugging = false;

    // Provided by the external to adjust the simulation.
    UPROPERTY(Category = LocalOcean, EditAnywhere, BlueprintReadWrite)
    float Speed = 0;

    // To normalize the speed.
    UPROPERTY(Category = LocalOcean, EditAnywhere, BlueprintReadWrite)
    float MaxSpeed = 500;

    UPROPERTY(Transient, Category = LocalOcean, EditAnywhere, BlueprintReadWrite)
    bool Debugging = false;

    UPROPERTY(Transient, Category = LocalOcean, EditAnywhere, BlueprintReadWrite)
    int DebuggingMaterialIndex = 0;


    UPROPERTY(Category = LocalOcean, EditAnywhere, BlueprintReadWrite)
    bool Enabled = true;

    UPROPERTY(Category = LocalOcean, EditAnywhere, BlueprintReadWrite)
    float TimeScale = 1.0f;


    // Set the height field value of a location relative to the owner ACTOR.
    UFUNCTION(BlueprintCallable, Category = "LocalOcean")
    void SetHeightFieldAtRelativeXY(float Height, float X, float Y);

    // Set a height field push point at the given WORLD location. Only for 1 frame.
    UFUNCTION(BlueprintCallable, Category = "LocalOcean")
    void SetHeightFieldPushPoint(FVector WorldLocation);

    UFUNCTION(BlueprintCallable, Category = "LocalOcean")
    void SetHeightFieldHollowPoint(FVector WorldLocation);

    // Enable/disable the local ocean.
    UFUNCTION(BlueprintCallable, Category = "LocalOcean")
    void SetEnabled(bool bEnabled);

    // Size of the arrays for simulation.
    static const int MAX_HEIGHT_FIELD_SIZE = 256;


    ULocalOceanComponent(const FObjectInitializer& ObjectInitializer);

    virtual void BeginPlay() override;
    
    virtual void TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction) override;
    
    
private:
    TArray<FVector> Vertices;
    TArray<int32> Triangles;
    TArray<FVector> Normals;
    TArray<FVector2D> UVs;
    TArray<FProcMeshTangent> Tangents;
    TArray<FColor> Colors;

    TArray<int32> InterestingVertexIndices;

    float HalfSize;

    float HeightField0[MAX_HEIGHT_FIELD_SIZE][MAX_HEIGHT_FIELD_SIZE];
    float HeightFieldV0[MAX_HEIGHT_FIELD_SIZE][MAX_HEIGHT_FIELD_SIZE];

    float HeightField1[MAX_HEIGHT_FIELD_SIZE][MAX_HEIGHT_FIELD_SIZE];
    float HeightFieldV1[MAX_HEIGHT_FIELD_SIZE][MAX_HEIGHT_FIELD_SIZE];

    FVector NormalField[MAX_HEIGHT_FIELD_SIZE][MAX_HEIGHT_FIELD_SIZE];

    

    float(*CurrentHeightField)[MAX_HEIGHT_FIELD_SIZE];
    float(*CurrentHeightFieldV)[MAX_HEIGHT_FIELD_SIZE];

    float(*PreviousHeightField)[MAX_HEIGHT_FIELD_SIZE];
    float(*PreviousHeightFieldV)[MAX_HEIGHT_FIELD_SIZE];

    float RecentLocationX;
    float RecentLocationY;

    // The location change since last simulation (frame).
    float OffsetX;
    float OffsetY;

    // Do the simulation for the current frame.
    void Simulate(float DeltaTime);

    void UpdateMesh(float DeltaTime);


    // 2D array access utilities with bilinear feature.
    FORCEINLINE float BilinearReadArray(float(*Array)[MAX_HEIGHT_FIELD_SIZE], float X, float Y)
    {
        int Y0 = FMath::FloorToInt(Y);
        int Y1 = Y0 + 1;
        int X0 = FMath::FloorToInt(X);
        int X1 = X0 + 1;

        float AY0X0 = Y0 < 0 || Y0 >= HEIGHT_FIELD_SIZE || X0 < 0 || X0 >= HEIGHT_FIELD_SIZE ? 0 : Array[Y0][X0];
        float AY0X1 = Y0 < 0 || Y0 >= HEIGHT_FIELD_SIZE || X1 < 0 || X1 >= HEIGHT_FIELD_SIZE ? 0 : Array[Y0][X1];
        float AY1X1 = Y1 < 0 || Y1 >= HEIGHT_FIELD_SIZE || X1 < 0 || X1 >= HEIGHT_FIELD_SIZE ? 0 : Array[Y1][X1];
        float AY1X0 = Y1 < 0 || Y1 >= HEIGHT_FIELD_SIZE || X0 < 0 || X0 >= HEIGHT_FIELD_SIZE ? 0 : Array[Y1][X0];

        return FMath::BiLerp(AY0X0, AY1X0, AY0X1, AY1X1, Y - Y0, X - X0);
    }

    FORCEINLINE float BilinearReadArrayUnsafe(float(*Array)[MAX_HEIGHT_FIELD_SIZE], float X, float Y)
    {
        int Y0 = FMath::FloorToInt(Y);
        int Y1 = Y0 + 1;
        int X0 = FMath::FloorToInt(X);
        int X1 = X0 + 1;

        return FMath::BiLerp(Array[Y0][X0], Array[Y1][X0], Array[Y0][X1], Array[Y1][X1], Y - Y0, X - X0);
    }

    FORCEINLINE FVector BilinearReadArrayVector(FVector(*Array)[MAX_HEIGHT_FIELD_SIZE], float X, float Y)
    {
        int Y0 = FMath::FloorToInt(Y);
        int Y1 = Y0 + 1;
        int X0 = FMath::FloorToInt(X);
        int X1 = X0 + 1;

        FVector AY0X0 = Y0 < 0 || Y0 >= HEIGHT_FIELD_SIZE || X0 < 0 || X0 >= HEIGHT_FIELD_SIZE ? FVector::UpVector : Array[Y0][X0];
        FVector AY0X1 = Y0 < 0 || Y0 >= HEIGHT_FIELD_SIZE || X1 < 0 || X1 >= HEIGHT_FIELD_SIZE ? FVector::UpVector : Array[Y0][X1];
        FVector AY1X1 = Y1 < 0 || Y1 >= HEIGHT_FIELD_SIZE || X1 < 0 || X1 >= HEIGHT_FIELD_SIZE ? FVector::UpVector : Array[Y1][X1];
        FVector AY1X0 = Y1 < 0 || Y1 >= HEIGHT_FIELD_SIZE || X0 < 0 || X0 >= HEIGHT_FIELD_SIZE ? FVector::UpVector : Array[Y1][X0];

        return FMath::BiLerp(AY0X0, AY1X0, AY0X1, AY1X1, Y - Y0, X - X0);
    }

    FORCEINLINE float CloseReadArray(float(*Array)[MAX_HEIGHT_FIELD_SIZE], float X, float Y)
    {
        int YI = Y + 0.5f;
        int XI = X + 0.5f;

        return YI < 0 || YI >= HEIGHT_FIELD_SIZE || XI < 0 || XI >= HEIGHT_FIELD_SIZE ? 0 : Array[YI][XI];
    }

    FORCEINLINE FVector CloseReadArrayVector(FVector(*Array)[MAX_HEIGHT_FIELD_SIZE], float X, float Y)
    {
        int YI = Y + 0.5f;
        int XI = X + 0.5f;

        return YI < 0 || YI >= HEIGHT_FIELD_SIZE || XI < 0 || XI >= HEIGHT_FIELD_SIZE ? FVector::UpVector : Array[YI][XI];
    }

    FORCEINLINE void GetXYFromWorldLocation(FVector WorldLocation, float& X, float& Y)
    {
        FVector Offset = WorldLocation - this->GetOwner()->GetActorLocation();

        X = (Offset.X + HalfSize) / CELL_SIZE;
        Y = (Offset.Y + HalfSize) / CELL_SIZE;
    }
};
