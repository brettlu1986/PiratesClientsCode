#pragma once

#define EPS (1e-6)
#define FLOAT_EQUAL_ZERO(X) (FMath::Abs(X) < EPS)
#define ZERO_FLOAT (0.f)
#define EMPTY_NUM (0)


// Return Kits
#define ReturnIfNullptr(P, ... )                \
do {                                            \
    if ((P) == nullptr)                         \
    {                                           \
        return __VA_ARGS__;                     \
    }                                           \
} while (0);

#define ReturnIfNullUObject(P, ... )            \
do {			                                \
    if (!IsValid(P) || !P->IsValidLowLevel())   \
    {                                           \
        return __VA_ARGS__;                     \
    }                                           \
} while (0);

#define ReturnIfTrue(P, ... )                   \
do {                                            \
    if (P)                                      \
    {                                           \
        return __VA_ARGS__;                     \
    }                                           \
} while (0);

#define ReturnIfFalse(P, ... )                  \
do {                                            \
    if (!(P))                                     \
    {                                           \
        return __VA_ARGS__;                     \
    }                                           \
} while (0);
