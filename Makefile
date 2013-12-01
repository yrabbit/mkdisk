# Makefile for cweave, ctangle, plain TeX etc
CTANGLE = ctangle
CWEAVE = cweave
TEX = plain-ru
CFLAGS=-Wall -g
CFLAGS+=-I /usr/local/include
LDFLAGS=-L/usr/local/lib -largp 

all: mkdisk.pdf linkbk

mkdisk.pdf: mkdisk.ps
	gs -sDEVICE=pdfwrite -sOutputFile=mkdisk.pdf -dBATCH -dNOPAUSE mkdisk.ps

mkdisk.ps: mkdisk.dvi
	dvips -j0 mkdisk.dvi -o

mkdisk.dvi: mkdisk.tex
	$(TEX) mkdisk.tex

mkdisk.tex: mkdisk.w
	$(CWEAVE) mkdisk.w

linkbk: mkdisk.c
	CC $(CFLAGS) $(LDFLAGS) mkdisk.c -o mkdisk

mkdisk.c: mkdisk.w
	$(CTANGLE) mkdisk.w

clean:
	-rm -Rf *.c *.o link
	-rm -Rf *.tex *.aux *.log *.toc *.idx *.scn *.dvi *.pdf *.ps

