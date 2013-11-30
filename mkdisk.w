% vim: set ai textwidth=80:
\input lib/verbatim
\input cwebmac-ru

\def\version{0.1}
\font\twentycmcsc=cmcsc10 at 20 truept

\datethis

@* Введение.
\vskip 120pt
\centerline{\twentycmcsc mkdisk}
\vskip 20pt
\centerline{Утилита создания образов дисков MKDOS}
\vskip 2pt
\centerline{(Версия \version)}
\vskip 10pt
\centerline{Yellow Rabbit}
\vskip 80pt
Создает образ диска в формате MKDOS помещая в него указанные файлы. Объем образа
800KiB. 
Русские имена файлов кодируются в КОИ8.
@* Общая схема программы.
@c
@<Включение заголовочных файлов@>@;
@h
@<Константы@>@;
@<Собственные типы данных@>@;
@<Глобальные переменные@>@;
int
main(int argc, char *argv[])
{
	@<Данные программы@>@;
	const char *srcname;
	int i;

	@<Разобрать командную строку@>@;
	@<Подготовить перекодировку@>@;
	@<Создать файл образа@>@;
	total_size  = 0;
	cur_src = 0;

	/* Поочередно обрабатываем все заданные файлы */
	while ((srcname = config.srcnames[cur_src]) != NULL) {
		@<Открыть исходный файл@>@;
		handleOneFile(fsrc, fresult);
		fclose(fsrc);
		if (total_size >= DISK_SIZE) {
			PRINTERR("Files are too big\n");
			return(ERR_TOO_BIG);
		}
		++cur_src;
	}
	/* Создать корневой каталог диска */
	if (createDir(fresult) != 0) {
		return(ERR_CREATE_DIR);
	}
	fclose(fresult);
	@<Очистить перекодировку@>@;
	return(0);
}
@ 
@<Глобальн...@>=
static int cur_src;

@ @<Данные программы@>=
FILE *fsrc, *fresult;

@ @<Открыть исходный файл@>=
	fsrc = fopen(srcname,"r");
	if (fsrc == NULL) {
		PRINTERR("Can't open %s\n", srcname);
		return(ERR_CANTOPEN);
	}
@ @<Создать файл образа@>=
	fresult = fopen(config.output_filename, "w");
	if (fresult == NULL) {
		PRINTERR("Can't create %s\n", config.output_filename);
		return(ERR_CANTOPEN);
	}
	memset(buf, 0, BLOCK_SIZE);
	for (i = 0; i < DISK_CATALOG_SIZE; ++ i) {
		fwrite(buf, BLOCK_SIZE, 1, fresult);
	}
	/* инициализация записей каталога */
	memset(dir, 0, sizeof(dir));
	
@ Требуются переколировка имени файлов в КОИ8.
@<Подготовить перекодировку@>=
	setlocale(LC_ALL, "");
	cd = iconv_open("KOI8-R", nl_langinfo(CODESET));
	if ( cd == (iconv_t)-1) {
		PRINTERR("Can't open encoding converter\n");
		return(ERR_ENCODING);
	}
@ @<Очистить перекодировку@>=
	iconv_close(cd);

@ @<Глобальные...@>=
static iconv_t cd;

@* Сбор информации о файлах и запись каталога.
@d MKDOS_ID	0123456
@d MKDOS_DIR_ID 051414
@d MKDOS_FILE_STATUS_NORMAL	00
@d MKDOS_FILE_STATUS_PROTECTED  01
@d MKDOS_FILE_STATUS_LDISK	02	/* логический диск */
@d MKDOS_FILE_STATUS_BAD	0200	/* плохой блок */
@d MKDOS_FILE_STATUS_DELETED	0377	/* удаленный/свободный */
@d DISK_SIZE	1600 /* 1600 512-байтных блоков  */
@d DISK_CATALOG_SIZE	024	/* число блоков, занятых каталогом */
@d MKDOS_NUM_FILES 172
@d MKDOS_MAX_NAME_LEN 14

@<Собственные типы дан...@>=
typedef struct _DiskHeader {
	uint8_t		dummy0[030];
	uint16_t	num_files;		/* количество файлов */
	uint16_t	num_used_blocks;	/* количество занятых блоков */
	uint8_t		dummy1[0400 - 4 - 030];
	uint16_t	mkdos_id;		/* метка принадлежности к формату MKDOS */
	uint16_t	dir_id;			/* метка формата каталога MKDOS */
	uint8_t		dummy2[0466 - 4 - 0400];
	uint16_t	num_blocks;		/* емкость диска в блоках */
	uint16_t	first_block;		/* номер первого блока первого
						файла */
	uint8_t		dummy3[0500 - 4 - 0466];
} DiskHeader;

typedef struct _DirRecord {
	uint8_t		status;			/* статус файла */
	uint8_t		subdir_num;		/* номер подкаталога (0 ---
						корень) */
	char		name[MKDOS_MAX_NAME_LEN];		/* если [0]==0117, то это
	подкаталог, а в поле статуса указан номер этого подкаталога */
	uint16_t	block;			/* номер блока */
	uint16_t	block_len;		/* длина в блоках */
	uint16_t	addr;			/* адрес */
	uint16_t	len;			/* длина */
} DirRecord;

@ Собираем информацию о входных файлах и создаём каталог диска.
@c
static int createDir(FILE *fresult) {
	DiskHeader *hdr;
	int i;

	/* пишем 0-ой блок */
	rewind(fresult);
	memset(buf, 0, BLOCK_SIZE);
	hdr = (DiskHeader*)buf;
	hdr->mkdos_id = MKDOS_ID;
	hdr->dir_id = MKDOS_DIR_ID;
	hdr->num_files = config.num_src;
	hdr->num_used_blocks = DISK_CATALOG_SIZE + total_size;	/* это блоки под каталог
							диска + размер файлов*/
	hdr->num_blocks = DISK_SIZE;
	hdr->first_block = DISK_CATALOG_SIZE;		/* первый блок сразу после каталога */

	fwrite(buf, sizeof(DiskHeader), 1, fresult);

	for (i = 0; i < config.num_src; ++i) {
		fwrite(dir + i, sizeof(DirRecord), 1, fresult);
	}
	return(0);
}

@* Обработать один входной файл.
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

	/* Конвертировать имя файла в КОИ8 */
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
@<Глобальн...@>=
static void handleOneFile(FILE *, FILE *);
static int createDir(FILE *);
static uint8_t buf[BLOCK_SIZE];
static DirRecord dir[MKDOS_NUM_FILES];	/* Каталог диска */
static unsigned int total_size;	/* Общее число блоков в файлах */

@* Разбор параметров командной строки.

Для этой цели используется достаточно удобная свободная библиотека 
{\sl argp}.
@d VERSION "0.9"

@ @<Константы@>=
const char *argp_program_version = "mkdisk, " VERSION;
const char *argp_program_bug_address = "<yellowrabbit@@bk.ru>";

@ @<Глобальн...@>=
static char argp_program_doc[] = "Make MKDOS disk image";

@ Распознаются следующие опции:
\smallskip
	\item {} {\tt -o} --- имя выходного файла;
	\item {} {\tt -v} --- вывод дополнительной информации.
\smallskip
@<Глобальн...@>=
static struct argp_option options[] = {@|
	{ "output", 'o', "FILENAME", 0, "Output filename"},@|
	{ "verbose", 'v', NULL, 0, "Verbose output"},@!
	{ 0 }@/
};
static error_t parse_opt(int, char*, struct argp_state*);@!
static struct argp argp = {options, parse_opt, NULL, argp_program_doc};

@ Эта структура используется для получения результатов разбора параметров командной строки.
@<Собственные...@>=
typedef struct _Arguments {
	int  verbosity;
	char output_filename[FILENAME_MAX]; /* Имя файла с текстом */
	int  num_src;			/* Количество исходных файлов */
	char **srcnames;		    /* Имена исходных файлов
						srcnames[?] == NULL --> конец имен*/
} Arguments;

@ @<Глобальные...@>=
static Arguments config = { 0, {0}, 0, NULL, };


@ Задачей данного простого парсера является заполнение структуры |Arguments| из указанных
параметров командной строки.
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
		/* Имена исходных файлов */
		arguments->srcnames = &state->argv[state->next - 1];
		/* Останавливаем разбор параметров */
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
@<Разобрать ком...@>=
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

@ @<Включение ...@>=
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
@<Глобальные...@>=
#define PRINTVERB(level, fmt, a...) (((config.verbosity) >= level) ? printf(\
  (fmt), ## a) : 0)
#define PRINTERR(fmt, a...) fprintf(stderr, (fmt), ## a) 


@* Индекс.



