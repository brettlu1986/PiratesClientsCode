#pragma once
#include "KMObject.h"
#include "MapNavMeshCache.h"
#include "LandNavMeshDataManager.generated.h"

UCLASS()
class COMMON_API ULandNavMeshDataManager : public UKMObject
{
    GENERATED_BODY()

public:

    //static FString RootDirectory;
    static FString FileName;

public:

    void Init();

    void Clear();

    const FMapNavMeshCache* GetNavMeshCache() const;

    UFUNCTION()
    void LoadNavMeshData(const FString& MapName);
    

private:

    FMapNavMeshCache CurrentNavMeshCache;
    FString CurrentMapName;

private:

    bool bIsValid;

    void OnPreLoadMap(const FString& InMapName);
    
};