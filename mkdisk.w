% vim: set ai textwidth=80:
\input lib/verbatim
\input cwebmac-ru

\def\version{0.1}
\font\twentycmcsc=cmcsc10 at 20 truept

\datethis

@* ��������.
\vskip 120pt
\centerline{\twentycmcsc mkdisk}
\vskip 20pt
\centerline{������� �������� ������� ������ MKDOS}
\vskip 2pt
\centerline{(������ \version)}
\vskip 10pt
\centerline{Yellow Rabbit}
\vskip 80pt
������� ����� ����� � ������� MKDOS ������� � ���� ��������� �����. ����� ������
800KiB. 
������� ����� ������ ���������� � ���8.
@* ����� ����� ���������.
@c
@<��������� ������������ ������@>@;
@h
@<���������@>@;
@<����������� ���� ������@>@;
@<���������� ����������@>@;
int
main(int argc, char *argv[])
{
	@<������ ���������@>@;
	const char *srcname;
	int i;

	@<��������� ��������� ������@>@;
	@<����������� �������������@>@;
	@<������� ���� ������@>@;
	total_size  = 0;
	cur_src = 0;

	/* ���������� ������������ ��� �������� ����� */
	while ((srcname = config.srcnames[cur_src]) != NULL) {
		@<������� �������� ����@>@;
		handleOneFile(fsrc, fresult);
		fclose(fsrc);
		if (total_size >= DISK_SIZE) {
			PRINTERR("Files are too big\n");
			return(ERR_TOO_BIG);
		}
		++cur_src;
	}
	/* ������� �������� ������� ����� */
	if (createDir(fresult) != 0) {
		return(ERR_CREATE_DIR);
	}
	fclose(fresult);
	@<�������� �������������@>@;
	return(0);
}
@ 
@<��������...@>=
static int cur_src;

@ @<������ ���������@>=
FILE *fsrc, *fresult;

@ @<������� �������� ����@>=
	fsrc = fopen(srcname,"r");
	if (fsrc == NULL) {
		PRINTERR("Can't open %s\n", srcname);
		return(ERR_CANTOPEN);
	}
@ @<������� ���� ������@>=
	fresult = fopen(config.output_filename, "w");
	if (fresult == NULL) {
		PRINTERR("Can't create %s\n", config.output_filename);
		return(ERR_CANTOPEN);
	}
	memset(buf, 0, BLOCK_SIZE);
	for (i = 0; i < DISK_CATALOG_SIZE; ++ i) {
		fwrite(buf, BLOCK_SIZE, 1, fresult);
	}
	/* ������������� ������� �������� */
	memset(dir, 0, sizeof(dir));
	
@ ��������� ������������� ����� ������ � ���8.
@<����������� �������������@>=
	setlocale(LC_ALL, "");
	cd = iconv_open("KOI8-R", nl_langinfo(CODESET));
	if ( cd == (iconv_t)-1) {
		PRINTERR("Can't open encoding converter\n");
		return(ERR_ENCODING);
	}
@ @<�������� �������������@>=
	iconv_close(cd);

@ @<����������...@>=
static iconv_t cd;

@* ���� ���������� � ������ � ������ ��������.
@d MKDOS_ID	0123456
@d MKDOS_DIR_ID 051414
@d MKDOS_FILE_STATUS_NORMAL	00
@d MKDOS_FILE_STATUS_PROTECTED  01
@d MKDOS_FILE_STATUS_LDISK	02	/* ���������� ���� */
@d MKDOS_FILE_STATUS_BAD	0200	/* ������ ���� */
@d MKDOS_FILE_STATUS_DELETED	0377	/* ���������/��������� */
@d DISK_SIZE	1600 /* 1600 512-������� ������  */
@d DISK_CATALOG_SIZE	024	/* ����� ������, ������� ��������� */
@d MKDOS_NUM_FILES 172
@d MKDOS_MAX_NAME_LEN 14

@<����������� ���� ���...@>=
typedef struct _DiskHeader {
	uint8_t		dummy0[030];
	uint16_t	num_files;		/* ���������� ������ */
	uint16_t	num_used_blocks;	/* ���������� ������� ������ */
	uint8_t		dummy1[0400 - 4 - 030];
	uint16_t	mkdos_id;		/* ����� �������������� � ������� MKDOS */
	uint16_t	dir_id;			/* ����� ������� �������� MKDOS */
	uint8_t		dummy2[0466 - 4 - 0400];
	uint16_t	num_blocks;		/* ������� ����� � ������ */
	uint16_t	first_block;		/* ����� ������� ����� �������
						����� */
	uint8_t		dummy3[0500 - 4 - 0466];
} DiskHeader;

typedef struct _DirRecord {
	uint8_t		status;			/* ������ ����� */
	uint8_t		subdir_num;		/* ����� ����������� (0 ---
						������) */
	char		name[MKDOS_MAX_NAME_LEN];		/* ���� [0]==0117, �� ���
	����������, � � ���� ������� ������ ����� ����� ����������� */
	uint16_t	block;			/* ����� ����� */
	uint16_t	block_len;		/* ����� � ������ */
	uint16_t	addr;			/* ����� */
	uint16_t	len;			/* ����� */
} DirRecord;

@ �������� ���������� � ������� ������ � ������ ������� �����.
@c
static int createDir(FILE *fresult) {
	DiskHeader *hdr;
	int i;

	/* ����� 0-�� ���� */
	rewind(fresult);
	memset(buf, 0, BLOCK_SIZE);
	hdr = (DiskHeader*)buf;
	hdr->mkdos_id = MKDOS_ID;
	hdr->dir_id = MKDOS_DIR_ID;
	hdr->num_files = config.num_src;
	hdr->num_used_blocks = DISK_CATALOG_SIZE + total_size;	/* ��� ����� ��� �������
							����� + ������ ������*/
	hdr->num_blocks = DISK_SIZE;
	hdr->first_block = DISK_CATALOG_SIZE;		/* ������ ���� ����� ����� �������� */

	fwrite(buf, sizeof(DiskHeader), 1, fresult);

	for (i = 0; i < config.num_src; ++i) {
		fwrite(dir + i, sizeof(DirRecord), 1, fresult);
	}
	return(0);
}

@* ���������� ���� ������� ����.
@d BLOCK_SIZE 01000
@c
static void
handleOneFile(FILE *fsrc, FILE *fresult) {
	char name[MKDOS_MAX_NAME_LEN + 1], *pname;
	const char *sname;
	size_t slen, dlen;
	int block_len, size, start_block;

	size = 0;
	start_block = total_size + DISK_CATALOG_SIZE;
	while(!feof(fsrc)) {
		block_len = fread(buf, 1, BLOCK_SIZE, fsrc);
		if (block_len == 0) {
			break;
		}
		++total_size;
		size += block_len;
		fwrite(buf, BLOCK_SIZE, 1, fresult);
	}
	PRINTVERB(1, "File: %s, length: %d, total_blocks: %d.\n",
		config.srcnames[cur_src], size, total_size);
	dir[cur_src].block = start_block;	
	dir[cur_src].block_len = total_size - start_block + DISK_CATALOG_SIZE;
	dir[cur_src].addr = 01000;
	dir[cur_src].len = size;

	/* �������������� ��� ����� � ���8 */
	pname = name;
	sname = basename(config.srcnames[cur_src]);
	slen = MKDOS_MAX_NAME_LEN;
	dlen = slen;

	PRINTVERB(2, "Src name:%s, slen:%ld, dst name:%s, dlen:%ld.\n",
		sname, slen, pname, dlen);
	iconv(cd, &sname, &slen, &pname, &dlen);
	PRINTVERB(2, "PSrc:%s, slen:%ld, PDst:%s, dlen:%ld.\n",
		sname, slen, pname, dlen);
	strncpy(dir[cur_src].name, name, MKDOS_MAX_NAME_LEN);
}

@ 
@<��������...@>=
static void handleOneFile(FILE *, FILE *);
static int createDir(FILE *);
static uint8_t buf[BLOCK_SIZE];
static DirRecord dir[MKDOS_NUM_FILES];	/* ������� ����� */
static unsigned int total_size;	/* ����� ����� ������ � ������ */

@* ������ ���������� ��������� ������.

��� ���� ���� ������������ ���������� ������� ��������� ���������� 
{\sl argp}.
@d VERSION "0.9"

@ @<���������@>=
const char *argp_program_version = "mkdisk, " VERSION;
const char *argp_program_bug_address = "<yellowrabbit@@bk.ru>";

@ @<��������...@>=
static char argp_program_doc[] = "Make MKDOS disk image";

@ ������������ ��������� �����:
\smallskip
	\item {} {\tt -o} --- ��� ��������� �����;
	\item {} {\tt -v} --- ����� �������������� ����������.
\smallskip
@<��������...@>=
static struct argp_option options[] = {@|
	{ "output", 'o', "FILENAME", 0, "Output filename"},@|
	{ "verbose", 'v', NULL, 0, "Verbose output"},@!
	{ 0 }@/
};
static error_t parse_opt(int, char*, struct argp_state*);@!
static struct argp argp = {options, parse_opt, NULL, argp_program_doc};

@ ��� ��������� ������������ ��� ��������� ����������� ������� ���������� ��������� ������.
@<�����������...@>=
typedef struct _Arguments {
	int  verbosity;
	char output_filename[FILENAME_MAX]; /* ��� ����� � ������� */
	int  num_src;			/* ���������� �������� ������ */
	char **srcnames;		    /* ����� �������� ������
						srcnames[?] == NULL --> ����� ����*/
} Arguments;

@ @<����������...@>=
static Arguments config = { 0, {0}, 0, NULL, };


@ ������� ������� �������� ������� �������� ���������� ��������� |Arguments| �� ���������
���������� ��������� ������.
@c
static error_t 
parse_opt(int key, char *arg, struct argp_state *state) {
	Arguments *arguments;

	arguments = (Arguments*)state->input;
 switch (key) {
	case 'v':
		++arguments->verbosity;
		break;
	case 'o':
		if (strlen(arg) == 0)
			return(ARGP_ERR_UNKNOWN);
		strncpy(arguments->output_filename, arg, FILENAME_MAX - 1);
		break;
	case ARGP_KEY_ARG:
		/* ����� �������� ������ */
		arguments->srcnames = &state->argv[state->next - 1];
		/* ������������� ������ ���������� */
		state->next = state->argc;

		break;
	default:
		break;
		return(ARGP_ERR_UNKNOWN);
	}
	return(0);
}
@ 
@d ERR_SYNTAX		1
@d ERR_CANTOPEN		2
@d ERR_CANTCREATE	3
@d ERR_TOO_MANY_FILES	4
@d ERR_CREATE_DIR	5
@d ERR_ENCODING		6
@d ERR_TOO_BIG		7
@<��������� ���...@>=
	argp_parse(&argp, argc, argv, 0, 0, &config);@|
	if (config.srcnames == NULL) {
		PRINTERR("No input filenames specified\n");
		return(ERR_SYNTAX);
	}
	for (config.num_src = 0; config.srcnames[config.num_src] != NULL; ++config.num_src) {
		if (config.num_src >= MKDOS_NUM_FILES) {
			PRINTERR("Must be <= %d files.\n", MKDOS_NUM_FILES);
			return(ERR_TOO_MANY_FILES);
		}
	}

@ @<��������� ...@>=
#include <string.h>
#include <stdlib.h>
#include <libgen.h>

#ifdef __linux__
#include <stdint.h>
#endif

#include <locale.h>
#include <langinfo.h>
#include <iconv.h>

#include <argp.h>

@
@<����������...@>=
#define PRINTVERB(level, fmt, a...) (((config.verbosity) >= level) ? printf(\
  (fmt), ## a) : 0)
#define PRINTERR(fmt, a...) fprintf(stderr, (fmt), ## a) 


@* ������.



