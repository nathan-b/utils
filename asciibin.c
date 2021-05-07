#include <stdio.h>
#include <stdint.h>

uint32_t bin2dec(char* binstr)
{
	uint32_t i = 0, res = 0;

	while (binstr[i])
	{
		res <<= 1;
		if (binstr[i] == '1')
		{
			res |= 0x1;
		}
		++i;
	}
	return res;
}

int main(int argc, char** argv)
{
	uint32_t i;
	for (i = 1; i < argc; ++i)
	{
		uint32_t n = bin2dec(argv[i]);
		char c = (char)n;
		printf("%u = %c\n", n, c);
	}

	return 0;
}

