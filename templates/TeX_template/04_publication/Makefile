.PHONY: all manuscript bib clean clean-manuscript rebuild check-manuscript

LATEXMK ?= latexmk
PDFLATEX ?= pdflatex
BIBTEX ?= bibtex
LATEXMK_OPTS ?= -pdf -interaction=nonstopmode -file-line-error

MAN_TEX ?= main.tex
MAN_DIR ?= .
MAN_BASENAME := $(basename $(notdir $(MAN_TEX)))

all: manuscript

check-manuscript:
	@test -f $(MAN_TEX) || (echo "Error: missing manuscript source $(MAN_TEX)" && exit 1)

bib: check-manuscript
	@echo "Preparing bibliography (pdflatex -> bibtex -> bibtex)..."
	@cd $(MAN_DIR) && $(PDFLATEX) -interaction=nonstopmode -file-line-error $(notdir $(MAN_TEX)) || true
	@cd $(MAN_DIR) && $(BIBTEX) $(MAN_BASENAME) || true
	@cd $(MAN_DIR) && $(BIBTEX) $(MAN_BASENAME) || true
	@echo "Bibliography prepared (main.bbl generated with double bibtex run)."


manuscript: check-manuscript clean-manuscript
	@echo "Building manuscript..."
	@$(MAKE) -s bib
	@cd $(MAN_DIR) && $(LATEXMK) $(LATEXMK_OPTS) -bibtex $(notdir $(MAN_TEX))
	@echo "Manuscript build finished. Output: $(MAN_DIR)/$(notdir $(MAN_TEX:.tex=.pdf))"


clean-manuscript: check-manuscript
	@echo "Cleaning build artifacts (latexmk -c)..."
	-@cd $(MAN_DIR) && $(LATEXMK) -C $(notdir $(MAN_TEX)) || true
	@echo "Removing auxiliary (.aux) and bibliography (.bbl) files that can be rebuilt..."
	-@rm -f $(MAN_DIR)/*.aux $(MAN_DIR)/*.bbl $(MAN_DIR)/*.blg $(MAN_DIR)/*.fls $(MAN_DIR)/*.fdb_latexmk $(MAN_DIR)/*.synctex.gz $(MAN_DIR)/*.out $(MAN_DIR)/*.toc $(MAN_DIR)/*.lof $(MAN_DIR)/*.lot || true
	@echo "Clean complete. You can rebuild removed files with 'make manuscript'."

clean: clean-manuscript

rebuild: check-manuscript
	@echo "Rebuilding from scratch (forced full regeneration)..."
	@$(MAKE) -s clean-manuscript
	@cd $(MAN_DIR) && $(LATEXMK) $(LATEXMK_OPTS) -bibtex -gg $(notdir $(MAN_TEX))
	@echo "Rebuild finished. Output: $(MAN_DIR)/$(MAN_BASENAME).pdf"