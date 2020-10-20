#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <arpa/inet.h>

typedef struct 
{
	bool hex;
	bool dec;
	bool quiet;
} flags_t;

typedef struct _node
{
	struct _node* next;
	uint64_t val;
} node_t;

#define htonll(x) ((((uint64_t)htonl(x)) << 32) + htonl((x) >> 32))
#define ntohll(x) ((((uint64_t)ntohl(x)) << 32) + ntohl((x) >> 32))

void free_nodes(node_t*);

node_t* read_commandline(int argc, char** argv, flags_t* outflags)
{
	node_t* ret = NULL;
	node_t* curr = NULL;
	if (!outflags)
	{
		return NULL;
	}

	outflags->hex = true;
	outflags->dec = true;
	outflags->quiet = false;

	for (int i = 1; i < argc; ++i)
	{
		if (argv[i][0] == '-')
		{
			switch (argv[i][1])
			{
			case 'd':
				outflags->hex = false;
				outflags->dec = true;
				break;
			case 'h':
				outflags->hex = true;
				outflags->dec = false;
				break;
			case 'q':
				outflags->quiet = true;
				break;
			default:
				fprintf(stderr, "Unknown flag %s\n", argv[i]);
				free_nodes(ret);
				return NULL;
			}
		}
		else
		{
			node_t* n = (node_t*)malloc(sizeof(node_t));
			n->next = NULL;
			n->val = strtoull(argv[i], NULL, 0);
			if(curr == NULL)
			{
				ret = n;
				curr = n;
			}
			else
			{
				curr->next = n;
				curr = n;
			}
		}
	}
	return ret;
}

void free_nodes(node_t* list)
{
	node_t* next = NULL;
	while (list)
	{
		next = list->next;
		free(list);
		list = next;
	}
}

int main(int argc, char** argv)
{
	flags_t flags;
	node_t* list;

	list = read_commandline(argc, argv, &flags);

	while (list != NULL)
	{
		uint64_t lav = htonll(list->val);
		if (flags.dec)
		{
			if (flags.quiet)
			{
				printf("%li", lav);
			}
			else
			{
				printf("%li: %li\t", list->val, lav);
			}
		}
		if (flags.hex)
		{
			if (flags.quiet)
			{
				printf("0x%lx", lav);
			}
			else
			{
				printf("0x%lx: 0x%lx", list->val, lav);
			}
		}
		printf("\n");

		list = list->next;
	}

	return 0;
}

