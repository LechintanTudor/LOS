package kernel

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

log_info :: proc "contextless" (message: string, location := #caller_location) {
	_log(.Info, message, location)
}

log_error :: proc "contextless" (message: string, location := #caller_location) {
	_log(.Error, message, location)
}

_log :: proc "contextless" (level: Log_Level, message: string, location := #caller_location) {
	fmt_buf: [256]byte = ---
	fmt := fmt_create(fmt_buf[:])

	fmt_write(&fmt, "[")
	fmt_write(&fmt, Log_Level_Headers[level])
	fmt_write(&fmt, "] --- [")
	fmt_write(&fmt, _log_get_short_path(location.file_path))
	fmt_write(&fmt, ":")
	fmt_write(&fmt, location.procedure)
	fmt_write(&fmt, ":")
	fmt_write(&fmt, int(location.line))
	fmt_write(&fmt, "] ")
	fmt_write(&fmt, message)
	fmt_write(&fmt, "\n")

	_log_write_string(fmt_get(fmt))
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

_log_write_string :: proc "contextless" (str: string) {
	for c in transmute([]u8)str {
		cpu_port_write_byte(0xe9, c)
	}
}
