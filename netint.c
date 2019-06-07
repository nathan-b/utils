#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <arpa/inet.h>

int main(int argc, char** argv)
{
	for (int i = 1; i < argc; ++i)
	{
		long val = strtol(argv[i], NULL, 0);
		long lav = htonl(val);
		printf("%li: %li\t0x%lx: 0x%lx\n", val, lav, val, lav);
	}

	return 0;
}

