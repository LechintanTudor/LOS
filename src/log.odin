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
	_log_write_char('[')
	_log_write_string(Log_Level_Headers[level])
	_log_write_string("] --- [")
	_log_write_string(_log_get_short_path(location.file_path))
	_log_write_char(':')
	_log_write_string(location.procedure)
	_log_write_char(':')
	_log_write_int(int(location.line))
	_log_write_string("] ")
	_log_write_string(message)
	_log_write_char('\n')
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

_log_write_char :: #force_inline proc "contextless" (c: byte) {
	cpu_port_write_byte(0xe9, c)
}

_log_write_int :: proc "contextless" (n: int) {
	buf: [32]byte
	buf_len := 0

	is_negative := n < 0
	n := abs(n)

	for {
		buf[buf_len] = '0' + byte(n % 10)

		n /= 10
		buf_len += 1

		if n <= 0 || buf_len >= len(buf) {
			break
		}
	}

	if is_negative {
		_log_write_char('-')
	}

	#reverse for c in buf[:buf_len] {
		_log_write_char(c)
	}
}

_log_write_string :: proc "contextless" (str: string) {
	for c in transmute([]u8)str {
		_log_write_char(c)
	}
}
