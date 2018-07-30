all: harmonie.svg 

%.svg: %.dot
	mkdir -p svg
	gvpr -c -f gvpr/addtooltips $< | \
	gvpr -c -f gvpr/addshapecolor | \
	gvpr -c -f gvpr/removeCLIMATE | \
	dot -Tsvg -o svg/$@   
#%.pdf:  %.dot
#	dot -Txdot $< | dot2tex | pdflatex
# 	dot2tex --tikzedgelabel $<  | pdflatex 

test:
	gvpr -f gvpr/test harmonie.dot
	gvpr -c -f gvpr/addtooltips harmonie.dot | gvpr -f gvpr/test_missing_tooltips 
	@gvpr -f gvpr/test_missing_hrefs harmonie.dot
	@gvpr -f gvpr/test_invalid_hrefs harmonie.dot
	@echo "---------Cycle check--------"
	@acyclic -nv harmonie.dot || exit 0
sbuinfo:
	gvpr -c -f gvpr/addshapecolor harmonie.dot | gvpr -c -f gvpr/addSBUINFO  | dot -Tsvg -o svg/da2sbuinfo.svg
