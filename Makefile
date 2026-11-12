PREFIX ?= $(HOME)/.local
BINDIR  = $(PREFIX)/bin
SHAREDIR = $(PREFIX)/share/gdal-kit

BIN   = gdalcaps mdim-summary
SHARE = mdim-summary.jq

.PHONY: install uninstall check

install:
	install -d $(BINDIR) $(SHAREDIR)
	for f in $(BIN); do install -m 755 bin/$$f $(BINDIR)/$$f; done
	for f in $(SHARE); do install -m 644 share/gdal-kit/$$f $(SHAREDIR)/$$f; done
	@echo "installed to $(PREFIX); make sure $(BINDIR) is on PATH"

uninstall:
	for f in $(BIN); do rm -f $(BINDIR)/$$f; done
	rm -rf $(SHAREDIR)

# quick smoke test against the GDAL on PATH (uses the repo copies, no install)
check:
	python3 bin/gdalcaps >/dev/null && echo "gdalcaps ok"
	command -v jq >/dev/null && echo '{"name":"/","driver":"MEM"}' | bin/mdim-summary | grep -q "gdal.mdim" && echo "mdim-summary ok"
