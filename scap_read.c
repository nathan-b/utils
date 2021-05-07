#include <stdio.h>
#include <stdint.h>

typedef struct _block_header
{
    uint32_t block_type;
    uint32_t block_total_length; // Block length, including this header and the trailing 32bits block length.
} block_header;

typedef struct _section_header_block
{
    uint32_t byte_order_magic;
    uint16_t major_version;
    uint16_t minor_version;
    uint64_t section_length;
} section_header_block;

struct ppm_evt_hdr 
{
#ifdef PPM_ENABLE_SENTINEL
    uint32_t sentinel_begin;
#endif
    uint64_t ts; /* timestamp, in nanoseconds from epoch */
    uint64_t tid; /* the tid of the thread that generated this event */
    uint32_t len; /* the event len, including the header */
    uint16_t type; /* the event type */
    uint32_t nparams; /* the number of parameters of the event */
};

#define EV_BLOCK_TYPE 0x204
#define EV_BLOCK_TYPE_V2 0x216
#define EVF_BLOCK_TYPE 0x208
#define EVF_BLOCK_TYPE_V2 0x217

static char big_read_buf[10*1024*1024] = {0};

//
// Parse the headers of a trace file
//
int32_t scap_read(FILE* f)
{
    block_header bh;
    section_header_block sh;
    uint32_t bt;

    //
    // Read the section header block
    //
    if(fread(&bh, 1, sizeof(bh), f) != sizeof(bh) ||
        fread(&sh, 1, sizeof(sh), f) != sizeof(sh) ||
        fread(&bt, 1, sizeof(bt), f) != sizeof(bt))
    {
        printf("error reading from file\n");
        return 1;
    }
    else
    {
        printf("block_header: block_type=0x%x, block_total_len=%u\n", bh.block_type, bh.block_total_length);
        printf("section_header_block: byte_order_magic=0x%x, major_version=%d, minor_version=%d, section_length=%llu\n",
        sh.byte_order_magic, sh.major_version, sh.minor_version, sh.section_length);
        printf("bt=%u\n", bt);
    }

    //
    // Read all block headers
    //
    while(1)
    {
        if(fread(&bh, 1, sizeof(bh), f) != sizeof(bh))
        {
            printf("No more blocks to read\n");
            return 1;
        }
        else
        {
            printf("block_header: block_type=0x%x, block_total_len=%u\n", bh.block_type, bh.block_total_length);
        }
		int expected_len = bh.block_total_length - sizeof(bh);
        // read the whole block including 4 byte trailer and drain into static buf
		int read_len = fread(big_read_buf, 1, expected_len, f);
        if(read_len != expected_len)
        {
            printf("Could not read block (expected length of %d, got length of %d)\n", expected_len, read_len);
            return 1;
        }
        else
        {
            // if event block found, dig out more details
            struct ppm_evt_hdr* pevent = NULL;
            if(bh.block_type == EVF_BLOCK_TYPE || bh.block_type == EVF_BLOCK_TYPE_V2)
            {
                printf("\tcpuid=%d flags=%d", *((uint16_t *)big_read_buf), *((uint32_t*)(big_read_buf+sizeof(uint16_t))));
                pevent = (struct ppm_evt_hdr *)(big_read_buf + sizeof(uint16_t) + sizeof(uint32_t));
            }  
            if(bh.block_type == EV_BLOCK_TYPE || bh.block_type == EV_BLOCK_TYPE_V2)
            {
                printf("\tcpuid=%d flags=0", *((uint16_t *)big_read_buf));
                pevent = (struct ppm_evt_hdr *)(big_read_buf + sizeof(uint16_t));
            }
            if(pevent != NULL)
            {
                printf("\tEvent type=%u, tid=%llu, len=%u\n", pevent->type, pevent->tid, pevent->len);
            }
        }
    }

    return 0;
}

int main (int argc, char **argv)
{
    if(argc != 2)
    {
        printf("Usage: %s <scap file>\n", argv[0]);
        return 1;
    }
    else
    {
        printf("Processing scap file %s ...\n", argv[1]);
        FILE* f = fopen(argv[1], "rb");
        if(f == NULL) 
		{
           printf("Could not open scap file.\n");
           return 1;
        }
        scap_read(f);
    }
    return 0;
}
