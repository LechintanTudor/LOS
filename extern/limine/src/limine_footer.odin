// odinfmt: disable

COMMON_MAGIC :: [2]u64{
	0xc7b1dd30df4c8b88,
	0x0a82e883a194f07b,
}

REQUESTS_START_MARKER :: [4]u64 {
	0xf6b8f4b39de7d1ae,
	0xfab91a6940fcb9cf,
	0x785c6ed015d3e316,
	0x181e920a7852b9d9,
}

REQUESTS_END_MARKER :: [2]u64{
	0xadc0e0531bb10d03,
	0x9572709f31764c62,
}

BASE_REVISION_TAG :: [2]u64 {
	0xf9562b2d5c95a6c8,
	0x6a7b384944536bdc,
}

LAST_BASE_REVISION :: [3]u64 {
	BASE_REVISION_TAG[0],
	BASE_REVISION_TAG[1],
	6,
}

FRAMEBUFFER_REQUEST_ID :: [4]u64 {
	COMMON_MAGIC[0],
	COMMON_MAGIC[1],
	0x9d5827dcd881dd75,
	0xa3148604f6fab11b,
}

HHDM_REQUEST_ID :: [4]u64{
	COMMON_MAGIC[0],
	COMMON_MAGIC[1],
	0x48dcf1cb8ad2b852,
	0x63984e959a98244b,
}

MEMMAP_REQUEST_ID :: [4]u64 {
	COMMON_MAGIC[0],
	COMMON_MAGIC[1],
	0x67cf3d9d378a806f,
	0xe304acdfc50c3c62,
}

MP_REQUEST_ID :: [4]u64 {
	COMMON_MAGIC[0],
	COMMON_MAGIC[1],
	0x95a67b819a1b857e,
	0xa0b61b723b6a73e0,
}

mp_info :: struct {
	processor_id:   u32,
	lapic_id:       u32,
	reserved:       u64,
	goto_address:   goto_address,
	extra_argument: u64,
}
