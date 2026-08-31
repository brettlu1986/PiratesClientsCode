#include "Cinema/KMCinemaSubtitle.h"
#include "EngineExt.h"
#include "Engine/AssetManager.h"
DEFINE_LOG_CATEGORY_STATIC(FKMSubtitleItemLog, Log, All)

FKMSubtitleItem::FKMSubtitleItem():StartTime(0),
DuringTime(0),
ContentID(0)
{

}

UKMCinemaSubtitle::UKMCinemaSubtitle(const FObjectInitializer& ObjectInitializer)
	:Super(ObjectInitializer)
{

}

UKMSubtitleManager::UKMSubtitleManager(const FObjectInitializer& ObjectInitializer)
	:Super(ObjectInitializer)
{

}

void UKMSubtitleManager::StartPlaySubtitleforSequence(const FString& SubtitlePath)
{
	if (!GetOuter() || !GetOuter()->GetWorld())
	{
		return;
	}

	//init varibles
	IsInDrawState = true;
	CinemaStartTime = GetOuter()->GetWorld()->GetTimeSeconds();
	DrawingItemIndex = 0;
    EventItemIndex = 0;
    CurrentEventItemIndex = -1;
    IsFirstEvent = true;

	
	TArray<FStringAssetReference> AssetList;
	AssetList.Add(FStringAssetReference(*SubtitlePath));

	TSharedPtr<FStreamableHandle> Handler = UAssetManager::Get().LoadAssetList(AssetList);

	Handler->BindCompleteDelegate(FStreamableDelegate::CreateLambda(
	[=]()
	{
        if (!Handler->GetLoadedAsset())
            return;
		DrawingSubtitle = CastChecked<UKMCinemaSubtitle>(Handler->GetLoadedAsset());

		if (!DrawingSubtitle)
		{
			IsInDrawState = false;
			CinemaStartTime = -1.0f;
			DrawingItemIndex = -1;
		}
        if (OnLoadEnd.IsBound())
        {
            OnLoadEnd.Broadcast();
        }
	}
	
	));

	if (Handler->HasLoadCompleted())
	{
        if (!Handler->GetLoadedAsset())
            return;
		DrawingSubtitle = CastChecked<UKMCinemaSubtitle>(Handler->GetLoadedAsset());

		if (!DrawingSubtitle)
		{
			IsInDrawState = false;
			CinemaStartTime = -1.0f;
			DrawingItemIndex = -1;
		}
        if (OnLoadEnd.IsBound())
        {
            OnLoadEnd.Broadcast();
        }
	}
	
}

void UKMSubtitleManager::Restart()
{
    IsInDrawState = true;
    CinemaStartTime = GetOuter()->GetWorld()->GetTimeSeconds();
    DrawingItemIndex = 0;
    EventItemIndex = 0;
    IsFirstEvent = true;
    CurrentEventItemIndex = -1;
}

void UKMSubtitleManager::SpecialEventTick()
{
    if (EventItemIndex < 0)
        return;


    if (DrawingSubtitle->EventItems.Num() <= 0)
    {
        return;
    }

    //播放完成
    bool bLastItem = (EventItemIndex == DrawingSubtitle->EventItems.Num() - 1);
    float LastingTime = GetOuter()->GetWorld()->GetTimeSeconds() - CinemaStartTime;
    //FKMEventItem currentItem = DrawingSubtitle->EventItems[EventItemIndex];
    bool bPendingFinish = (LastingTime > DrawingSubtitle->EventItems[EventItemIndex].StartTime + DrawingSubtitle->EventItems[EventItemIndex].DuringTime);
    //UE_LOG(FKMSubtitleItemLog, Log, TEXT("currentItem.StartTime %f. DuringTime %f LastingTime %f"), currentItem.StartTime, currentItem.DuringTime, LastingTime);
    if (bLastItem && bPendingFinish)
    {
        EventItemIndex = -1;

        return;
    }

    //如果播放完成 已经到下一条的播放时间 切换到下一条
    if (bPendingFinish && !bLastItem)
    {
        EventItemIndex++;
    }
   
    bool bInplayerItem = (LastingTime < (DrawingSubtitle->EventItems[EventItemIndex].StartTime + DrawingSubtitle->EventItems[EventItemIndex].DuringTime));
    bInplayerItem &= (LastingTime > DrawingSubtitle->EventItems[EventItemIndex].StartTime);

    
    if (CurrentEventItemIndex != EventItemIndex && bInplayerItem)
    {
        CurrentEventItemIndex = EventItemIndex;
        if (OnEventTrigger.IsBound())
        {
            OnEventTrigger.Broadcast(DrawingSubtitle->EventItems[EventItemIndex].ContentID);
        }
        IsFirstEvent = false;
    }
}

void UKMSubtitleManager::StopSubtitle()
{
    DrawingSubtitle = nullptr;
}

void UKMSubtitleManager::DrawSubtitle(UCanvas* InCanvas)
{
	if (!GetOuter() || !GetOuter()->GetWorld())
	{
		return;
	}

	if (!DrawingSubtitle)
	{
		return;
	}

    SpecialEventTick();

	if (!IsInDrawState)
	{
		return;
	}

	if (DrawingSubtitle->SubtitleItems.Num() <= 0)
	{
		return;
	}

	//播放完成
	bool bLastItem = (DrawingItemIndex == DrawingSubtitle->SubtitleItems.Num() - 1);
	float LastingTime = GetOuter()->GetWorld()->GetTimeSeconds() - CinemaStartTime;
	bool bPendingFinish = (LastingTime > (DrawingSubtitle->SubtitleItems[DrawingItemIndex].StartTime + DrawingSubtitle->SubtitleItems[DrawingItemIndex].DuringTime));
	
	if (bLastItem && bPendingFinish)
	{
		IsInDrawState = false;
		//CinemaStartTime = -1.0f;
		DrawingItemIndex = -1;

		return;
	}

	//如果播放完成 已经到下一条的播放时间 切换到下一条
	if (bPendingFinish && !bLastItem)
	{
		DrawingItemIndex++;
	}

	bool bInplayerItem = (LastingTime < (DrawingSubtitle->SubtitleItems[DrawingItemIndex].StartTime + DrawingSubtitle->SubtitleItems[DrawingItemIndex].DuringTime));
	bInplayerItem &= (LastingTime > DrawingSubtitle->SubtitleItems[DrawingItemIndex].StartTime);
	//正常播放过程绘制
	if (bInplayerItem && DrawingSubtitle->Font)
	{
		FString DrawContent = DrawingSubtitle->SubtitleItems[DrawingItemIndex].Content;
		// measure tab width
		FVector2D FontSize = FVector2D(0, 0);
		InCanvas->TextSize(DrawingSubtitle->Font, DrawContent, FontSize.X, FontSize.Y, 1.0f, 1.0f);

		//get viewportsize
		FVector2D ViewportSize = FVector2D(0, 0);
		if (GetOuter()->GetWorld() && GetOuter()->GetWorld()->GetGameViewport())
		{
			GetOuter()->GetWorld()->GetGameViewport()->GetViewportSize(ViewportSize);
		}
		else
		{
			return;
		}

		float FontX = (ViewportSize.X + OffsetPosition.X - FontSize.X) * 0.5;
		float FontY = ViewportSize.Y + OffsetPosition.Y - FontSize.Y;

		FVector2D ScreenPosition = FVector2D(FontX, FontY);

        FCanvasTextItem TextItem(ScreenPosition, FText::FromString(DrawContent), DrawingSubtitle->Font, FLinearColor::White);
		TextItem.HorizSpacingAdjust = 0.0f;
		TextItem.ShadowColor = ShadowColor;
		TextItem.ShadowOffset = ShadowOffset;
		TextItem.bCentreX = false;
		TextItem.bCentreY = false;
		TextItem.bOutlined = bOutlined;
		TextItem.OutlineColor = OutlineColor;
		TextItem.EnableShadow(ShadowColor, ShadowOffset);
		InCanvas->DrawItem(TextItem);

		//InCanvas->DrawText(DrawingSubtitle->Font, FText::FromString(DrawContent), FontX, FontY, 1.0f, 1.0f);
		//InCanvas->K2_DrawText(DrawingSubtitle->Font, DrawContent, FVector2D(FontX, FontY), FLinearColor::White, 0.0f, FLinearColor::Black, FVector2D(5, 5), false, false, true, FLinearColor::Black);
	}
}