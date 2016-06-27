# -*- Mode: Makefile -*-
# Created Thu Aug  4 09:03:50 AKDT 2011
# by Raymond E. Marcil <marcilr@gmail.com>
#
# Makefile for a single-file LaTeX document plus optional BibTeX file.
#
# Comment out the BibTeX run in the `dvi' target if you don't have a
# bibliography.
#
# NOTE: Cygwin's xdvi puts a read lock on the *.dvi file
#       and breaks the build. Haven't found a way around this
#       yet. Setting chmod 666 before/after does not help.
#
# Links
# =====
# Conditional Parts of Makefiles
# A conditional causes part of a makefile to be obeyed or ignored
# depending on the values of variables. Conditionals can compare
# the value of one variable to another, or the value of a variable
# to a constant string. Conditionals control what make actually
# "sees" in the makefile, so they cannot be used to control shell
# commands at the time of execution.
# http://www.chemie.fu-berlin.de/chemnet/use/info/make/make_7.html
#
# Makefile : contains string
# Use of $(findstring find,in)
# Beware freaky syntax
# http://stackoverflow.com/questions/2741708/makefile-contains-string
#
# String comparison inside makefile
# Source for ifeq string comparision syntax
# http://stackoverflow.com/questions/3728372/string-comparison-inside-makefile
#
BIBTEX = /usr/bin/bibtex
CAT    = /bin/cat
CUT    = /usr/bin/cut
DVIPS  = /usr/bin/dvips
GREP   = /bin/grep
LATEX  = /usr/bin/latex
MKDIR  = /bin/mkdir
PS2PDF = /usr/bin/ps2pdf
RM     = /bin/rm
PS2PDF = /usr/bin/ps2pdf
RSYNC  = /usr/bin/rsync
TAR    = /bin/tar

# Determine LaTeX document basename dynamically.
# Rather than hardcoding.
BASENAME = $(shell ls *.tex | sed 's/.tex//g')
# BASENAME = bsdinspect-database


SRC = $(BASENAME).tex
BIB = $(BASENAME).bib
BLG = $(BASENAME).blg
BBL = $(BASENAME).bbl
LOG = $(BASENAME).log
AUX = $(BASENAME).aux
TOC = $(BASENAME).toc
DVI = $(BASENAME).dvi
PS  = $(BASENAME).ps
PDF = $(BASENAME).pdf
LOF = $(BASENAME).lof
LOT = $(BASENAME).lot
OUT = $(BASENAME).out

#
# Get subversion revision number from latex file using:
#   cat nmsConfiguration-schema.tex | grep "svnInfo " | cut -d ' ' -f 4
#
# The 4th column of the svnInfo line is the revision number embedded
# by subversion with:
#   svn propset svn:keywords "Id" nmsConfiguration-schema.tex
#
# If not using subversion this will still work but the revision number
# won't get updated when the document is updated.
#
REVISION:=$(shell $(CAT) $(SRC) | $(GREP) "svnInfo " | $(CUT) -d ' ' -f 4)

#
# If REVISION is defined then include in distribution filename.
#
ifdef REVISION
	BZ2 = $(BASENAME)-$(REVISION).tar.bz2
else
	BZ2 = $(BASENAME).tar.bz2
endif


# Identity non-file targets
.PHONY: all bz2 clean cycle dvi dist install mostly-clean pdf ps

all: cycle

cycle: clean ${DVI} ${PS} ${PDF}

# Remove temporary files, bz2 files, and pdf
clean: mostly-clean
	$(RM) -f  *.bz2 $(PDF)

#
# Remove temporary files, dist directory,
# and files other than bz2 and pdf.
#
mostly-clean:
	$(RM) -f $(LOG) $(LOF) $(AUX) $(TOC) $(DVI) $(PS) 
	$(RM) -f $(BBL) $(BLG) $(LOT) $(OUT)
	$(RM) -rf $(BASENAME)
	$(RM) -f *.aux *.dvi *.lof *.log *.ps *.tmp

# Wrapper targets for humans
dvi: ${DVI}
ps:  ${PS}
pdf: ${PDF}
bz2: $(BZ2)

${DVI}: ${SRC}
	$(LATEX) $(SRC)

# Uncomment this entry if there are \citation entries.
#	$(BIBTEX) $(BASENAME)

# Rerun LaTeX again to get the xrefs right.
	$(LATEX) $(SRC)
	$(LATEX) $(SRC)

${PS}: ${DVI}
# Embed hyperlinks for hyperref package (-z)
# Embed type 1 fonts, optimize for pdf (-Ppdf)
	$(DVIPS) -z -f -Ppdf < $(DVI) > $(PS)
# Embed type 1 fonts.
#	$(DVIPS) -f -Pcmz < $(DVI) > $(PS)
# Embed type 3 (bitmapped) fonts.
#	$(DVIPS) $(DVI) -o

${PDF}: ${PS}
	$(PS2PDF) $(PS)

#
# Build distribution tarball
# The leading slash in "--exclude /$(BASENAME)" means to exclude from the
# working directory only so the $(BASENAME) further down in the hierarchy
# will be included.
# 
# How to exclude a folder from rsync
# http://askubuntu.com/questions/349613/how-to-exclude-a-folder-from-rsync
#
${BZ2}: cycle
	$(MKDIR) $(BASENAME)
	$(RSYNC) -va --stats --progress * --exclude /$(BASENAME) $(BASENAME)
	$(TAR) -cvjpf $(BZ2) $(BASENAME)

# Build distribution tarball
dist: ${BZ2}
	$(RM) -f $(LOG) $(LOF) $(AUX) $(TOC) $(DVI) $(PS)
	$(RM) -f $(BBL) $(BLG) $(LOT) $(OUT)
	$(RM) -rf $(BASENAME)
	$(RM) -f *.aux *.dvi *.lof *.log *.ps *.tmp
