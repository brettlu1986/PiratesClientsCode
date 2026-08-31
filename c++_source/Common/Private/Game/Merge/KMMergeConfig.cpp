#include "Merge/KMMergeConfig.h"
#include "Common.h"

UKMMergeConfig::UKMMergeConfig(const FObjectInitializer& ObjInitializer)
	:Super(ObjInitializer)
{
	LoadConfig(GetClass(), *GDefaultMergeConfig);
}
