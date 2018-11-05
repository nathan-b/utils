#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stdint.h>
#include <stdbool.h>
#include <limits.h>

#define DEFAULT_FORMAT "%b %d, %Y %k:%M:%S"

typedef struct {
	uint8_t radix;
	char* format;
} options;

bool read_int(char* src, int8_t radix, int64_t* int_out)
{
    char *end;
    int64_t i = strtoll(src, &end, radix);
	if (*end != '\0') {
		fprintf(stderr, "Invalid timestamp: %s (%p = '%s') %lld\n", src, end, end, (long long)i);
		return false;
	}

	*int_out = i;
	return true;
}

uint32_t get_time_string(time_t time, const char* format, char* out_str, uint32_t out_len)
{
	struct tm* tinfo = localtime(&time);

	return strftime(out_str, out_len, format, tinfo);
}

bool parse_args(int argc, char** argv, options* opts_out)
{
	opts_out->format = NULL;
	opts_out->radix = 10;

	for (int i = 1; i < argc; ++i) {
		if (argv[i][0] == '-') {
			if (argv[i][1] == 'f') {
				opts_out->format = argv[i + 1];
				++i;
			} else if (argv[i][1] == 'r') {
				int64_t radix;
				read_int(argv[i + 1], 10, &radix);
				if (radix <= UINT8_MAX) {
					opts_out->radix = radix;
				} else {
					fprintf(stderr, "Invalid radix: %s\n", argv[i + 1]);
					return false;
				}
				++i;
			} else {
				fprintf(stderr, "Unknown option %s\n", argv[i]);
				return false;
			}
		}
	}
	return true;
}

int main(int argc, char** argv)
{
	char out_buf[1024] = {0};

	options opts;
	if (!parse_args(argc, argv, &opts)) {
		return -1;
	}

	// Now find any actual timestamp args
	char* format = DEFAULT_FORMAT;
	if (opts.format != NULL) {
		format = opts.format;
	}

	for (int i = 1; i < argc; ++i) {
		if (argv[i][0] == '-') {
			continue;
		}
		uint64_t ts = 0;
		if (!read_int(argv[i], opts.radix, &ts)) {
			return -2;
		}

		uint32_t ts_len = get_time_string(ts, format, out_buf, sizeof(out_buf));
		if (ts_len == 0) {
			fprintf(stderr, "Error converting time string\n");
			return -3;
		}
		printf("%s => %s\n", argv[i], out_buf);
	}
}

