#include <errno.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BYTE_ORDER_MAGIC 0x1A2B3C4D
#define SHB_BLOCK_TYPE 0x0A0D0D0A

// Event block types (all others are metadata blocks)
#define EV_BLOCK_TYPE 0x204
#define EV_BLOCK_TYPE_INT 0x8010ABCD
#define EV_BLOCK_TYPE_V2 0x216
#define EV_BLOCK_TYPE_V2_LARGE 0x221

#define EVF_BLOCK_TYPE 0x208
#define EVF_BLOCK_TYPE_V2 0x217
#define EVF_BLOCK_TYPE_V2_LARGE 0x222

typedef struct
{
	uint32_t block_type;
	uint32_t block_total_length;  // Block length, including header and trailer
} block_header;

typedef struct
{
	uint32_t byte_order_magic;
	uint16_t major_version;
	uint16_t minor_version;
	uint64_t section_length;
} section_header;

typedef struct
{
	uint64_t ts_ns;    // Timestamp, in nanoseconds from epoch
	uint64_t tid;      // tid of the thread that generated this event
	uint32_t len;      // Event length, including this header
	uint16_t type;     // Event type
	uint32_t nparams;  // Number of parameters to the event
} event_header;

#pragma pack(1)
typedef struct
{
	uint16_t cpuid;
	uint32_t flags;
	event_header header;
} event_section_header_flags;

#pragma pack(1)
typedef struct
{
	uint16_t cpuid;
	event_header header;
} event_section_header_no_flags;

// Parse through the scap file
int32_t scap_read(const char* filename, bool verbose)
{
	FILE* f = NULL;
	int ret = 0;
	uint32_t buf_len = 10 * 1024 * 1024;  // 10m should be enough for anybody, right?
	uint8_t* readbuf = malloc(buf_len);
	block_header bh;
	section_header sh;
	uint32_t bt;  // Block trailer
	uint32_t num_events = 0;

	// Open the file
	f = fopen(filename, "rb");
	if (!f)
	{
		fprintf(stderr, "Could not open file %s: %d (%s)\n", filename, errno, strerror(errno));
		ret = 1;
		goto done;
	}

	// Read the section header block
	if (fread(&bh, 1, sizeof(bh), f) != sizeof(bh) || fread(&sh, 1, sizeof(sh), f) != sizeof(sh) ||
	    fread(&bt, 1, sizeof(bt), f) != sizeof(bt))
	{
		fprintf(stderr, "Error reading from file %s: %d (%s)\n", filename, errno, strerror(errno));
		ret = 1;
		goto done;
	}
	else
	{
		printf("block_header: block_type=0x%x, block_total_len=%u\n", bh.block_type, bh.block_total_length);
		printf("section_header_block: \n\tbyte_order_magic=0x%x,\n\tversion=%d.%d,\n\tsection_length=%llu (%s)\n",
		       sh.byte_order_magic,
		       sh.major_version,
		       sh.minor_version,
		       sh.section_length,
		       "Do not be alarmed that this value looks insane. It's supposed to.");
		printf("bt=%u\n", bt);

		// Do some sanity checking on the header
		if (bh.block_type != SHB_BLOCK_TYPE)
		{
			fprintf(stderr,
			        "Error reading section header: unexpected block type (%x != %x)\n",
			        bh.block_type,
			        SHB_BLOCK_TYPE);
		}

		if (sh.byte_order_magic != BYTE_ORDER_MAGIC)
		{
			fprintf(stderr,
			        "Error reading section header: byte order magic mismatch (%x != %x)\n",
			        sh.byte_order_magic,
			        BYTE_ORDER_MAGIC);
		}
	}

	// Read all blocks in the capture
	while (1)
	{
		// Read block header
		if (fread(&bh, 1, sizeof(bh), f) != sizeof(bh))
		{
			ret = 0;
			goto done;
		}
		else if (verbose)
		{
			printf("block_header: block_type=0x%x, block_total_len=%u\n", bh.block_type, bh.block_total_length);
		}

		// Read the whole block up to the trailer
		int expected_len = bh.block_total_length - sizeof(bh) - sizeof(bt);
		if (expected_len > buf_len)
		{
			// We're going to need a bigger boat
			free(readbuf);
			readbuf = malloc(expected_len);
			if (!readbuf)
			{
				fprintf(stderr, "Could not allocate %d bytes of buffer memory\n", expected_len);
				ret = 1;
				goto done;
			}
		}
		int read_len = fread(readbuf, 1, expected_len, f);
		if (read_len != expected_len)
		{
			fprintf(stderr, "Could not read block (expected length of %d, got length of %d)\n", expected_len, read_len);
			ret = 1;
			goto done;
		}
		else
		{
			// Process the block
			event_header* pevent = NULL;
			if (bh.block_type == EVF_BLOCK_TYPE || bh.block_type == EVF_BLOCK_TYPE_V2 ||
			    bh.block_type == EVF_BLOCK_TYPE_V2_LARGE)
			{
				++num_events;
				// Flags
				event_section_header_flags* esh = (event_section_header_flags*)readbuf;
				if (verbose)
					printf("\tcpuid=%hu flags=0x%x", esh->cpuid, esh->flags);
				pevent = &esh->header;
			}
			if (bh.block_type == EV_BLOCK_TYPE || bh.block_type == EV_BLOCK_TYPE_V2 ||
			    bh.block_type == EV_BLOCK_TYPE_V2_LARGE)
			{
				++num_events;
				// No flags
				event_section_header_no_flags* esh = (event_section_header_no_flags*)readbuf;
				if (verbose)
					printf("\tcpuid=%d flags=0x0", esh->cpuid);
				pevent = &esh->header;
			}
			if (pevent && verbose)
			{
				printf("\tEvent type=%u, tid=%llu, len=%u\n", pevent->type, pevent->tid, pevent->len);
			}
		}

		// Read the trailer
		read_len = fread(&bt, 1, sizeof(bt), f);
		if (read_len != sizeof(bt))
		{
			fprintf(stderr, "Could not read block trailer: %d (%s)\n", errno, strerror(errno));
			ret = 1;
			goto done;
		}
		if (verbose)
			printf("block trailer: %u\n", bt);
		if (bt != bh.block_total_length)
		{
			fprintf(stderr,
			        "Malformed block: length mismatch between header and trailer (%u != %u)\n",
			        bh.block_total_length,
			        bt);
		}
	}

done:
	if (ret == 0)
	{
		printf("File is correctly formed and contains %u events\n", num_events);
	}
	if (readbuf)
	{
		free(readbuf);
	}
	return ret;
}

void usage(const char* progname)
{
	printf("Usage: %s [-v] <scap file>\n", progname);
}

int main(int argc, char** argv)
{
	// Command line parsing (this is garbage, I know)
	bool verbose = false;
	for (int i = 1; i < argc; ++i)
	{
		if (argv[i][0] == '-')
		{
			switch (argv[i][1])
			{
			case 'v':
				verbose = true;
				break;
			default:
				fprintf(stderr, "Unknown switch %s\n", argv[i]);
				usage(argv[0]);
				return -1;
			}
		}
		else
		{
			printf("Capture file %s\n=======================================\n", argv[i]);
			scap_read(argv[i], verbose);
		}
	}
	return 0;
}
