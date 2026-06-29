/* SPDX-License-Identifier: 0BSD */

/* Copyright (C) 2022-2026 Mintsuki and contributors.
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
 * OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
 * CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */
package limine

uuid :: struct {
	a:  u32,
	b:  u16,
	_c: u16,
	d:  [8]u8,
}

MEDIA_TYPE_GENERIC :: 0
MEDIA_TYPE_OPTICAL :: 1
MEDIA_TYPE_TFTP    :: 2

file :: struct {
	revision:        u64,
	address:         rawptr,
	size:            u64,
	path:            cstring,
	_string:         cstring,
	media_type:      u32,
	unused:          u32,
	tftp_ipv4:       [4]u8,
	tftp_port:       u32,
	partition_index: u32,
	mbr_disk_id:     u32,
	gpt_disk_uuid:   uuid,
	gpt_part_uuid:   uuid,
	part_uuid:       uuid,
}

bootloader_info_response :: struct {
	revision: u64,
	name:     cstring,
	version:  cstring,
}

bootloader_info_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^bootloader_info_response,
}

executable_cmdline_response :: struct {
	revision: u64,
	cmdline:  cstring,
}

executable_cmdline_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^executable_cmdline_response,
}

FIRMWARE_TYPE_X86BIOS :: 0
FIRMWARE_TYPE_EFI32   :: 1
FIRMWARE_TYPE_EFI64   :: 2
FIRMWARE_TYPE_SBI     :: 3

firmware_type_response :: struct {
	revision:      u64,
	firmware_type: u64,
}

firmware_type_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^firmware_type_response,
}

stack_size_response :: struct {
	revision: u64,
}

stack_size_request :: struct {
	id:         [4]u64,
	revision:   u64,
	response:   ^stack_size_response,
	stack_size: u64,
}

hhdm_response :: struct {
	revision: u64,
	offset:   u64,
}

hhdm_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^hhdm_response,
}

FRAMEBUFFER_RGB :: 1

video_mode :: struct {
	pitch:            u64,
	width:            u64,
	height:           u64,
	bpp:              u16,
	memory_model:     u8,
	red_mask_size:    u8,
	red_mask_shift:   u8,
	green_mask_size:  u8,
	green_mask_shift: u8,
	blue_mask_size:   u8,
	blue_mask_shift:  u8,
}

framebuffer :: struct {
	address:          rawptr,
	width:            u64,
	height:           u64,
	pitch:            u64,
	bpp:              u16,
	memory_model:     u8,
	red_mask_size:    u8,
	red_mask_shift:   u8,
	green_mask_size:  u8,
	green_mask_shift: u8,
	blue_mask_size:   u8,
	blue_mask_shift:  u8,
	unused:           [7]u8,
	edid_size:        u64,
	edid:             rawptr,

	/* Response revision 1 */
	mode_count: u64,
	modes:      ^^video_mode,
}

framebuffer_response :: struct {
	revision:          u64,
	framebuffer_count: u64,
	framebuffers:      [^]^framebuffer,
}

framebuffer_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^framebuffer_response,
}

FLANTERM_FB_ROTATE_0   :: 0
FLANTERM_FB_ROTATE_90  :: 1
FLANTERM_FB_ROTATE_180 :: 2
FLANTERM_FB_ROTATE_270 :: 3

flanterm_fb_init_params :: struct {
	canvas:              ^u32,
	canvas_size:         u64,
	ansi_colours:        [8]u32,
	ansi_bright_colours: [8]u32,
	default_bg:          u32,
	default_fg:          u32,
	default_bg_bright:   u32,
	default_fg_bright:   u32,
	font:                rawptr,
	font_width:          u64,
	font_height:         u64,
	font_spacing:        u64,
	font_scale_x:        u64,
	font_scale_y:        u64,
	margin:              u64,
	rotation:            u64,
}

flanterm_fb_init_params_response :: struct {
	revision:    u64,
	entry_count: u64,
	entries:     ^^flanterm_fb_init_params,
}

flanterm_fb_init_params_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^flanterm_fb_init_params_response,
}

PAGING_MODE_X86_64_4LVL       :: 0
PAGING_MODE_X86_64_5LVL       :: 1
PAGING_MODE_X86_64_MIN        :: PAGING_MODE_X86_64_4LVL
PAGING_MODE_X86_64_DEFAULT    :: PAGING_MODE_X86_64_4LVL
PAGING_MODE_AARCH64_4LVL      :: 0
PAGING_MODE_AARCH64_5LVL      :: 1
PAGING_MODE_AARCH64_MIN       :: PAGING_MODE_AARCH64_4LVL
PAGING_MODE_AARCH64_DEFAULT   :: PAGING_MODE_AARCH64_4LVL
PAGING_MODE_RISCV_SV39        :: 0
PAGING_MODE_RISCV_SV48        :: 1
PAGING_MODE_RISCV_SV57        :: 2
PAGING_MODE_RISCV_MIN         :: PAGING_MODE_RISCV_SV39
PAGING_MODE_RISCV_DEFAULT     :: PAGING_MODE_RISCV_SV48
PAGING_MODE_LOONGARCH_4LVL    :: 0
PAGING_MODE_LOONGARCH_MIN     :: PAGING_MODE_LOONGARCH_4LVL
PAGING_MODE_LOONGARCH_DEFAULT :: PAGING_MODE_LOONGARCH_4LVL

paging_mode_response :: struct {
	revision: u64,
	mode:     u64,
}

paging_mode_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^paging_mode_response,
	mode:     u64,
	max_mode: u64,
	min_mode: u64,
}

goto_address :: proc "c" (^mp_info)

MP_RESPONSE_X86_64_X2APIC :: (1<<0)

mp_info :: struct {}

mp_response :: struct {
	revision:     u64,
	flags:        u32,
	bsp_lapic_id: u32,
	cpu_count:    u64,
	cpus:         ^^mp_info,
}

MP_REQUEST_X86_64_X2APIC :: (1<<0)

mp_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^mp_response,
	flags:    u64,
}

MEMMAP_USABLE                 :: 0
MEMMAP_RESERVED               :: 1
MEMMAP_ACPI_RECLAIMABLE       :: 2
MEMMAP_ACPI_NVS               :: 3
MEMMAP_BAD_MEMORY             :: 4
MEMMAP_BOOTLOADER_RECLAIMABLE :: 5
MEMMAP_EXECUTABLE_AND_MODULES :: 6
MEMMAP_FRAMEBUFFER            :: 7
MEMMAP_RESERVED_MAPPED        :: 8

memmap_entry :: struct {
	base:   u64,
	length: u64,
	type:   u64,
}

memmap_response :: struct {
	revision:    u64,
	entry_count: u64,
	entries:     ^^memmap_entry,
}

memmap_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^memmap_response,
}

entry_point :: proc "c" ()

entry_point_response :: struct {
	revision: u64,
}

entry_point_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^entry_point_response,
	entry:    entry_point,
}

executable_file_response :: struct {
	revision:        u64,
	executable_file: ^file,
}

executable_file_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^executable_file_response,
}

INTERNAL_MODULE_REQUIRED   :: (1<<0)
INTERNAL_MODULE_COMPRESSED :: (1<<1)

internal_module :: struct {
	path:    cstring,
	_string: cstring,
	flags:   u64,
}

module_response :: struct {
	revision:     u64,
	module_count: u64,
	modules:      ^^file,
}

module_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^module_response,

	/* Request revision 1 */
	internal_module_count: u64,
	internal_modules:      ^^internal_module,
}

rsdp_response :: struct {
	revision: u64,
	address:  rawptr,
}

rsdp_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^rsdp_response,
}

smbios_response :: struct {
	revision: u64,
	entry_32: rawptr,
	entry_64: rawptr,
}

smbios_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^smbios_response,
}

efi_system_table_response :: struct {
	revision: u64,
	address:  rawptr,
}

efi_system_table_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^efi_system_table_response,
}

TPM_EVENT_LOG_FORMAT_TCG_1_2 :: 1
TPM_EVENT_LOG_FORMAT_TCG_2   :: 2

tpm_event_log_response :: struct {
	revision: u64,
	format:   u64,
	size:     u64,
	address:  rawptr,
}

tpm_event_log_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^tpm_event_log_response,
}

efi_memmap_response :: struct {
	revision:     u64,
	memmap:       rawptr,
	memmap_size:  u64,
	desc_size:    u64,
	desc_version: u64,
}

efi_memmap_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^efi_memmap_response,
}

date_at_boot_response :: struct {
	revision:  u64,
	timestamp: i64,
}

date_at_boot_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^date_at_boot_response,
}

executable_address_response :: struct {
	revision:      u64,
	physical_base: u64,
	virtual_base:  u64,
}

executable_address_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^executable_address_response,
}

dtb_response :: struct {
	revision: u64,
	dtb_ptr:  rawptr,
}

dtb_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^dtb_response,
}

riscv_bsp_hartid_response :: struct {
	revision:   u64,
	bsp_hartid: u64,
}

riscv_bsp_hartid_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^riscv_bsp_hartid_response,
}

bootloader_performance_response :: struct {
	revision:   u64,
	reset_usec: u64,
	init_usec:  u64,
	exec_usec:  u64,
}

bootloader_performance_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^bootloader_performance_response,
}

x86_64_keep_iommu_response :: struct {
	revision: u64,
}

x86_64_keep_iommu_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^x86_64_keep_iommu_response,
}

tsc_frequency_response :: struct {
	revision:  u64,
	frequency: u64,
}

tsc_frequency_request :: struct {
	id:       [4]u64,
	revision: u64,
	response: ^tsc_frequency_response,
}

COMMON_MAGIC :: [2]u64{0xc7b1dd30df4c8b88, 0x0a82e883a194f07b}

REQUESTS_START_MARKER :: [4]u64 {
	0xf6b8f4b39de7d1ae,
	0xfab91a6940fcb9cf,
	0x785c6ed015d3e316,
	0x181e920a7852b9d9,
}

REQUESTS_END_MARKER :: [2]u64{0xadc0e0531bb10d03, 0x9572709f31764c62}

FRAMEBUFFER_REQUEST_ID :: [4]u64 {
	COMMON_MAGIC[0],
	COMMON_MAGIC[1],
	0x9d5827dcd881dd75,
	0xa3148604f6fab11b,
}
