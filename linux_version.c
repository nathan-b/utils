#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <linux/version.h>

/*
 * Super quick 'n' dirty program to convert version strings
 * (like 5.1.7) to kernel version numbers.
 */

int parse_version_string(char* str, int* ver_out)
{
	int i;
	int len = strlen(str);
	const char* nums[3];
	int numptr = 0;
	const char* s = str;

	for (i = 0; i < len; ++i)
	{
		if (str[i] == '.') 
		{
			if (numptr >= 3)
			{
				return 0;
			}
			str[i] = '\0';
			nums[numptr++] = s;
			s = &str[i + 1];
		}
	}
	nums[2] = s;

	for (i = 0; i < 3; ++i)
	{
		ver_out[i] = atoi(nums[i]);
	}
	return 1;
}

int main(int argc, char** argv)
{
	int i;

	for (i = 1; i < argc; ++i)
	{
		int ver[3];
		if (parse_version_string(argv[i], ver))
		{
			printf("%d\n", KERNEL_VERSION(ver[0], ver[1], ver[2]));
		}
	}

	return 0;
}

