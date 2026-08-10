package kernel

import "core:fmt"
import "core:mem"

@(rodata)
Log_Level_Headers := [Log_Level]string {
	.Debug = "DEBUG",
	.Info  = "INFO ",
	.Warn  = "WARN ",
	.Error = "ERROR",
	.Fatal = "FATAL",
}

Log_Level :: enum {
	Debug,
	Info,
	Warn,
	Error,
	Fatal,
}

log_info :: proc "contextless" (args: ..any, location := #caller_location) {
	log(.Info, ..args, location = location)
}

log_infof :: proc "contextless" (fmt_str: string, args: ..any, location := #caller_location) {
	logf(.Info, fmt_str, ..args, location = location)
}

log_error :: proc "contextless" (args: ..any, location := #caller_location) {
	log(.Error, ..args, location = location)
}

log_errorf :: proc "contextless" (fmt_str: string, args: ..any, location := #caller_location) {
	logf(.Error, fmt_str, ..args, location = location)
}

log :: proc "contextless" (
	level: Log_Level,
	args: ..any,
	sep: string = " ",
	location := #caller_location,
) {
	arena_memory: [256]byte = ---
	arena: mem.Arena

	context = {}
	mem.arena_init(&arena, arena_memory[:])
	context.temp_allocator = mem.arena_allocator(&arena)

	text := fmt.tprint(..args, sep = sep)
	_log(level, text, location)
}

logf :: proc "contextless" (
	level: Log_Level,
	fmt_str: string,
	args: ..any,
	location := #caller_location,
) {
	arena_memory: [256]byte = ---
	arena: mem.Arena

	context = {}
	mem.arena_init(&arena, arena_memory[:])
	context.temp_allocator = mem.arena_allocator(&arena)

	text := fmt.tprintf(fmt_str, ..args)
	_log(level, text, location)
}

_log :: proc "contextless" (level: Log_Level, text: string, location := #caller_location) {
	QEMU_DEBUG_PORT :: 0xe9

	arena_memory: [256]byte = ---
	arena: mem.Arena

	context = {}
	mem.arena_init(&arena, arena_memory[:])
	context.temp_allocator = mem.arena_allocator(&arena)

	header := fmt.tprintf(
		"[%v] --- [%v:%v:%v()] ",
		Log_Level_Headers[level],
		_log_get_short_path(location.file_path),
		location.line,
		location.procedure,
	)

	for byte in transmute([]u8)header {
		cpu_port_write_byte(QEMU_DEBUG_PORT, byte)
	}

	for byte in transmute([]u8)text {
		cpu_port_write_byte(QEMU_DEBUG_PORT, byte)
	}

	cpu_port_write_byte(QEMU_DEBUG_PORT, '\n')
}

@(require_results)
_log_get_short_path :: proc "contextless" (path: string) -> string {
	start := 0

	#reverse for char, i in transmute([]u8)path {
		if char == '/' {
			start = i + 1
			break
		}
	}

	return path[start:]
}
