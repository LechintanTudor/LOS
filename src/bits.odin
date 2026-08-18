package kernel

import "base:intrinsics"

U16_MAX :: 1 << 16 - 1

U32_MAX :: 1 << 32 - 1

@(require_results)
bits_log2 :: proc "contextless" (value: $T) -> T
where
	intrinsics.type_is_integer(T),
	intrinsics.type_is_unsigned(T)
{
	return (8 * size_of(T) - 1) - intrinsics.count_leading_zeros(value)
}
