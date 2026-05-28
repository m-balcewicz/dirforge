
.PHONY: all slides clean clean-slides

LATEXMK ?= latexmk
PDFLATEX ?= pdflatex
BIBER ?= biber
BIBTEX ?= bibtex
LATEXMK_OPTS ?= -pdf -interaction=nonstopmode -file-line-error

SLIDE_TEX ?= beamer.tex
SLIDE_DIR ?= .

all: slides


bib-slides:
	@echo "Preparing slides bibliography (pdflatex -> biber -> pdflatex)..."
	@cd $(SLIDE_DIR) && $(PDFLATEX) -interaction=nonstopmode $(notdir $(SLIDE_TEX)) || true
	@cd $(SLIDE_DIR) && $(BIBER) $(basename $(notdir $(SLIDE_TEX))) || true
	@cd $(SLIDE_DIR) && $(PDFLATEX) -interaction=nonstopmode $(notdir $(SLIDE_TEX)) || true
	@echo "Slides bibliography prepared (beamer.bbl generated with biber)."

slides:
	@echo "Building slides (latexmk handles pdflatex + biber automatically)..."
	@cd $(SLIDE_DIR) && $(LATEXMK) $(LATEXMK_OPTS) $(notdir $(SLIDE_TEX)); \
	  EXIT=$$?; \
	  PDF=$(notdir $(SLIDE_TEX:.tex=.pdf)); \
	  if [ "$$EXIT" = "12" ] && [ -f "$$PDF" ]; then \
	    echo "Note: latexmk needed extra passes but PDF was produced successfully."; \
	  elif [ "$$EXIT" != "0" ]; then \
	    exit $$EXIT; \
	  fi
	@echo "Slides build finished. Output: $(SLIDE_DIR)/$(notdir $(SLIDE_TEX:.tex=.pdf))"

clean-slides:
	@echo "Cleaning slides build artifacts..."
	-@cd $(SLIDE_DIR) && $(LATEXMK) -c $(notdir $(SLIDE_TEX)) || true
	-@rm -f $(SLIDE_DIR)/*.bbl $(SLIDE_DIR)/*.bcf $(SLIDE_DIR)/exercises.* || true
	@find $(SLIDE_DIR) -name "*.synctex.gz" -delete || true
	@find $(SLIDE_DIR) -name "*.synctex(busy)" -delete || true
	@find $(SLIDE_DIR) -name "*.fls" -delete || true
	@find $(SLIDE_DIR) -name "*.fdb_latexmk" -delete || true
	@find $(SLIDE_DIR) -name "*.run.xml" -delete || true
	@find $(SLIDE_DIR) -name "*.nav" -delete || true
	@find $(SLIDE_DIR) -name "*.snm" -delete || true
	@find $(SLIDE_DIR) -name "*SAVE-ERROR" -delete || true
	@echo "Slides clean complete. You can rebuild with 'make slides'."


clean: clean-slides
