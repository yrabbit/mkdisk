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
Линковщик предназначен для получения исполняемых файлов из объектных файлов
ассемблера MACRO-11\footnote{$^1$}{Использовалась BSD-версия ассемблера
Richard'а
Krehbiel'а.}. 
Входными параметрами являются: перечень имен объектных файлов, имя
выходного файла\footnote{$^2$}{На самом деле выходных файлов может быть много,
но указывается только имя файла для основной/стартовой секции.} и несколько управляющих ключей.
На выходе создается исполняемый файл для БК11М.
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
	int i, j;

	@<Разобрать командную строку@>@;

	/* Поочередно обрабатываем все заданные объектные файлы */
	cur_input = 0;
	while ((srcname = config.srcnames[cur_input]) != NULL) {
		@<Открыть объектный файл@>@;
		handleOneFile(fsrc);
		fclose(fsrc);
		++cur_input;
	}
	return(0);
}

@ Номер текущего обрабатываемого объектного файла.
@<Глобальные переменные@>=
static int cur_input;

@ @<Данные программы@>=
FILE *fsrc, *fresult;

@ @<Открыть объектный файл@>=
	fsrc = fopen(srcname,"r");
	if (fsrc== NULL) {
		PRINTERR("Can't open %s\n", srcname);
		return(ERR_CANTOPEN);
	}


@* Разбор параметров командной строки.

Для этой цели используется достаточно удобная свободная библиотека 
{\sl argp}.
@d VERSION "0.6"

@ @<Константы@>=
const char *argp_program_version = "linkbk, " VERSION;
const char *argp_program_bug_address = "<yellowrabbit@@bk.ru>";

@ @<Глобальн...@>=
static char argp_program_doc[] = "Link MACRO-11 object files";

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
	char **srcnames;		    /* Имена исходных файлов
					 objnames[?] == NULL --> конец имен*/
} Arguments;

@ @<Глобальные...@>=
static Arguments config = { 0, {0}, NULL, };


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
		/* Имена объектных файлов */
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
@<Разобрать ком...@>=
	argp_parse(&argp, argc, argv, 0, 0, &config);@|
	if (config.srcnames == NULL) {
		PRINTERR("No input filenames specified\n");
		return(ERR_SYNTAX);
	}

@ @<Включение ...@>=
#include <string.h>
#include <stdlib.h>

#ifdef __linux__
#include <stdint.h>
#endif

#include <argp.h>

@
@<Глобальные...@>=
#define PRINTVERB(level, fmt, a...) (((config.verbosity) >= level) ? printf(\
  (fmt), ## a) : 0)
#define PRINTERR(fmt, a...) fprintf(stderr, (fmt), ## a) 


@* Индекс.



