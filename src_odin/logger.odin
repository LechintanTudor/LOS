package kernel

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:strings"

@(rodata)
Logger_Level_Headers := [?]string {
	00 ..< 10 = "DEBUG",
	10 ..< 20 = "INFO ",
	20 ..< 30 = "WARN ",
	30 ..< 40 = "ERROR",
	40 ..< 50 = "FATAL",
}

@(require_results)
logger_create :: proc "contextless" (lowest := log.Level.Debug) -> runtime.Logger {
	return {procedure = logger_proc, lowest_level = lowest}
}

logger_proc :: proc(
	data: rawptr,
	level: runtime.Logger_Level,
	text: string,
	options: bit_set[runtime.Logger_Option],
	location := #caller_location,
) {
	QEMU_DEBUG_PORT :: 0xe9

	buf: [512]byte = ---
	str := strings.builder_from_bytes(buf[:])

	fmt.sbprintf(
		&str,
		"[%v] --- [%v:%v:%v()] ",
		Logger_Level_Headers[level],
		logger_get_short_path(location.file_path),
		location.line,
		location.procedure,
	)

	for byte in transmute([]u8)strings.to_string(str) {
		cpu_port_write_byte(QEMU_DEBUG_PORT, byte)
	}

	for byte in transmute([]u8)text {
		cpu_port_write_byte(QEMU_DEBUG_PORT, byte)
	}

	cpu_port_write_byte(QEMU_DEBUG_PORT, '\n')
}

@(require_results)
logger_get_short_path :: proc "contextless" (path: string) -> string {
	start := 0

	for char, i in path {
		if char == '/' {
			start = i + 1
		}
	}

	return path[start:]
}
