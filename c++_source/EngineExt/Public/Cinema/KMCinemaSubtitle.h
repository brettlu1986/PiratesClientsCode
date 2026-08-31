//yangjingzhao add for subtitle for cinema
#pragma once

#include "KMCinemaSubtitle.generated.h"
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnSubtitleManagerEvent);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnSubtitleManagerUIEvent, uint32, EventItemID);
USTRUCT(BlueprintType, Blueprintable)
struct FKMSubtitleItem
{
	GENERATED_USTRUCT_BODY()
public:
	FKMSubtitleItem();
	~FKMSubtitleItem() {};

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	float StartTime;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	float DuringTime;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	FString Content;

    UPROPERTY(BlueprintReadWrite, EditAnywhere)
    int ContentID;
};

USTRUCT(BlueprintType, Blueprintable)
struct FKMEventItem
{
    GENERATED_USTRUCT_BODY()
public:
    FKMEventItem():StartTime(0),
    DuringTime(0),
    ContentID(0)
    {};
    ~FKMEventItem() {};

    UPROPERTY(BlueprintReadWrite, EditAnywhere)
    float StartTime;

    UPROPERTY(BlueprintReadWrite, EditAnywhere)
    float DuringTime;


    UPROPERTY(BlueprintReadWrite, EditAnywhere)
    int ContentID;
};


UCLASS(Blueprintable)
class ENGINEEXT_API UKMCinemaSubtitle : public UDataAsset
{
	GENERATED_UCLASS_BODY()
public:
	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	TArray<FKMSubtitleItem> SubtitleItems;

    UPROPERTY(BlueprintReadWrite, EditAnywhere)
    TArray<FKMEventItem> EventItems;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	USoundWave* SoundWave;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	UFont* Font;
};

UCLASS(BlueprintType, Blueprintable)
class ENGINEEXT_API UKMSubtitleManager :public UObject
{
	GENERATED_UCLASS_BODY()

	void StartPlaySubtitleforSequence(const FString& SubtitlePath);

    void StopSubtitle();

    void Restart();

	void DrawSubtitle(UCanvas* InCanvas);

    void SpecialEventTick();

	//标记是否正在绘制某过场动画的字幕
	bool IsInDrawState = false;
    
	//正在绘制的字幕index
	int32 DrawingItemIndex = -1 ;

	//从开始播放计时
	float CinemaStartTime = -1.0f;

    int32 EventItemIndex = -1;

    int32 CurrentEventItemIndex = -1;

    bool IsFirstEvent = true;
public:
    //当前绘制的过场动画字幕
    UPROPERTY()
    UKMCinemaSubtitle* DrawingSubtitle;

    UPROPERTY()
    FVector2D OffsetPosition = FVector2D(0, -50);

    UPROPERTY()
    bool bOutlined = true;

    UPROPERTY()
    FVector2D ShadowOffset = FVector2D(5, 5);

    UPROPERTY()
    FLinearColor ShadowColor = FLinearColor::Black;

    UPROPERTY()
    FLinearColor OutlineColor = FLinearColor::Black;
    UPROPERTY()
    FOnSubtitleManagerEvent OnLoadEnd;

    UPROPERTY()
    FOnSubtitleManagerUIEvent OnEventTrigger;
};
