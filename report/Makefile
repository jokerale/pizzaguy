
FILE = report
FILE_CLEAN = *.out *aux *blx.bib *bcf *.run.xml *bbl *blg *log *toc *.ptb *.tod *.fls *.fdb_latexmk *.lof


.PHONY: distclean clean

pdf: report.tex refs.bib
	pdflatex $(FILE)
	bibtex $(FILE)
#	makeindex $(FILE)
	pdflatex $(FILE)
	pdflatex $(FILE)
	
distclean: clean
	rm -f $(FILE).pdf

clean:
	rm -f $(FILE_CLEAN)	