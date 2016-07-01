# -*- Mode: Makefile -*-
# Created Thu Aug  4 09:03:50 AKDT 2011
# by Raymond E. Marcil <rmarcil@gci.com>
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
# git log is so 2005
# git lg definition here   <=== Sweet
# http://fredkschott.com/post/2014/02/git-log-is-so-2005/
#
# Font sizes, families, and styles
# Great latex formatting details here
# https://www.sharelatex.com/learn/Font_sizes,_families,_and_styles
#
# GNU make
# https://www.gnu.org/software/make/manual/make.html#Conditionals
#
# How to print out a variable in makefile
# $(info $$var is [${var}])
# http://stackoverflow.com/questions/16467718/how-to-print-out-a-variable-in-makefile
#
# Including Git Revision Identifiers in LaTeX
# Thore Husfeldt
# Source of "git log -l" syntax for git metadata, Makefile, and syntax
# to include metadata in main latex document
# https://thorehusfeldt.net/2011/05/13/including-git-revision-identifiers-in-latex/
#
# Makefile : contains string
# Use of $(findstring find,in)
# Beware freaky syntax
# http://stackoverflow.com/questions/2741708/makefile-contains-string
#
# Pretty Formats
# git --distributed-even-if-your-workflow-isnt
# Has "git log -l" placeholder details like '%ad' and '%cd'
# for formatting date.
# https://git-scm.com/docs/pretty-formats
#
# String comparison inside makefile
# Source for ifeq string comparision syntax
# http://stackoverflow.com/questions/3728372/string-comparison-inside-makefile
#
# Usage Collection Framework (filexfer)
# http://oss-wiki.operations.gci.com/dev/index.php/Usage_Collection_Framework_(filexfer)
#
BIBTEX = /usr/bin/bibtex
CAT    = /bin/cat
CUT    = /usr/bin/cut
DVIPS  = /usr/bin/dvips
GIT    = /usr/bin/git
GREP   = /bin/grep
LATEX  = /usr/bin/latex
MKDIR  = /bin/mkdir
PS2PDF = /usr/bin/ps2pdf
RM     = /bin/rm
PS2PDF = /usr/bin/ps2pdf
RSYNC  = /usr/bin/rsync
TAR    = /bin/tar
TR     = /usr/bin/tr

# Determine LaTeX document basename dynamically.
# Rather than hardcoding.
BASENAME = $(shell ls *.tex |  grep -v vc | sed 's/.tex//g')
# BASENAME = bsdinspect-database


SRC = $(BASENAME).tex
VC  = $(BASENAME)-vc.tex
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

# Set VERSION file to use.
VERSIONFILE = "VERSION"

#
# Extract major,minor, and debug numbers from VERSION file.
# 1. Look at VERSION file with cat.
# 2. Extract "major =" line with grep.
# 3. Get 2nd field with major using cut.
# 4. Strip spaces with tr.
#
MAJOR = `${CAT} ${VERSIONFILE} | ${GREP} major | ${CUT} -f 2 -d '=' | ${TR} -d " "`
MINOR = `${CAT} ${VERSIONFILE} | ${GREP} minor | ${CUT} -f 2 -d '=' | ${TR} -d " "`
PATCH = `${CAT} ${VERSIONFILE} | ${GREP} patch | ${CUT} -f 2 -d '=' | ${TR} -d " "`

#
# Build VERSION number from MAJOR, MINOR, and PATCH
# The use of shell resolves the cat, grep, cut, and tr commands
# before executing targets.
#
REVISION = $(shell echo ${MAJOR}.${MINOR}.${PATCH})


#
# Get the git SHA-1 hash for the latest commit.
# This is always a 160-bit value.
#
# git-rev-parse - Pick out and massage parameters
#     git rev-parse [ --option ] <args>
#     https://git-scm.com/docs/git-rev-parse
#
# Options
# -------
#    --verify     Verify that exactly one parameter is provided, and that it can
#                 be turned into a raw 20-byte SHA-1 that can be used to access
#                 the object database.  If so, emit it to the standard output;
#                 otherwise, error out.
#
#    --short      Instead of outputting the full SHA-1 values of object names
#                 try to abbreviate them to a shorter unique name. When no
#                 length is specified 7 is used. The minimum length is 4.
#
#    HEAD         Names the commit on which you based the changes in the
#                 working tree. 
#    
#
SHA1:=$(shell $(GIT) rev-parse --verify HEAD)

#
# Get email address of latest commit
#
# How to get (only) author name or email in git given SHA1?
# http://stackoverflow.com/questions/29876342/how-to-get-only-author-name-or-email-in-git-given-sha1
#
EMAIL:=$(shell $(GIT) show -s --format='%ae' $(SHA1))

#
# Generate datestamp password to tex.
#
# Get the committer date %cd
# Did not find any way to get git format this nicely.
# Formatted the old fashioned way.
#
# The git log -1 --format="format:%cd" returns a not so pretty
# datestamp like:
#   $ git log -1 --format="format:%cd"
#   Mon Jun 27 14:11:53 2016 -0800
#
# The lengthly datestamp from "git log -1" needs a bit of cleanup
# to get a cleaner datestamp like "June 27, 2016" for display on
# the title page.
#
# Define make variable at rule execution time
# http://stackoverflow.com/questions/1909188/define-make-variable-at-rule-execution-time
#
$(eval DATE := $(shell $(GIT) log -1 --format="format:%cd"))
$(eval MONTH := $(shell echo $(DATE) | $(CUT) -d' ' -f2))
#$(info 1 - $$MONTH is [${MONTH}])

#
# Following is a series of gnu ifeq statements used like a
# case statement to make a 3-character to full month name
# mapping:
#   Jan   January
#   Feb   February
#   Mar   March
#   Apr   april
#   May   May     <=== Mapping not needed.  Good already
#   Jun   June
#   Jul   July
#   Aug   August
#   Sep   September
#   Oct   October
#   Nov   November
#   Dec   December
#
# Ideally the "git log -1" would support the succint date
# format via placeholder with the --date= option:
#     '%ad': author date (format respects --date= option)
#     '%cd': committer date (format respects --date= option)
#
# However, neither '%ad' or '%cd' appears so support the
# --date= option.  Hence, manual mapping is required.
#
# Notes for ifeq:
# o Does not work under a target.
# o Does not work with tabs.
# o *Must* be in this format.
#

# Check January
ifeq ($(MONTH),Jan)
#  $(info 2 - $$MONTH is ${MONTH})
  $(eval MONTH := $(shell echo "January"))
endif

# Check February
ifeq ($(MONTH),Feb)
#  $(info 2 - $$MONTH is ${MONTH})
  $(eval MONTH := $(shell echo "February"))
endif

# Check March
ifeq ($(MONTH),Mar)
#  $(info 2 - $$MONTH is ${MONTH})
  $(eval MONTH := $(shell echo "March"))
endif

# Check April
ifeq ($(MONTH),Apr)
#  $(info 2 - $$MONTH is ${MONTH})
  $(eval MONTH := $(shell echo "April"))
endif# Check June

#
# No need to check 3-character May.
# It is good to go.
#

# Check June
ifeq ($(MONTH),Jun)
#  $(info 2 - $$MONTH is ${MONTH})
  $(eval MONTH := $(shell echo "June"))
endif

# Check July
ifeq ($(MONTH),Jul)
#  $(info 2 - $$MONTH is ${MONTH})
  $(eval MONTH := $(shell echo "July"))
endif

# Check August
ifeq ($(MONTH),Aug)
#  $(info 2 - $$MONTH is ${MONTH})
  $(eval MONTH := $(shell echo "August"))
endif

# Check September
ifeq ($(MONTH),Sep)
#  $(info 2 - $$MONTH is ${MONTH})
  $(eval MONTH := $(shell echo "September"))
endif

# Check October
ifeq ($(MONTH),Oct)
#  $(info 2 - $$MONTH is ${MONTH})
  $(eval MONTH := $(shell echo "October"))
endif

# Check November
ifeq ($(MONTH),Nov)
#  $(info 2 - $$MONTH is ${MONTH})
  $(eval MONTH := $(shell echo "November"))
endif

# Check December
ifeq ($(MONTH),Dec)
#  $(info 2 - $$MONTH is ${MONTH})
  $(eval MONTH := $(shell echo "December"))
endif

#$(info 3 - $$MONTH is [${MONTH}])
$(eval DAY := $(shell echo $(DATE) | cut -d' ' -f3))
$(eval YEAR := $(shell echo $(DATE) | cut -d' ' -f5))
$(eval DATE := $(shell echo "$(MONTH) $(DAY), $(YEAR)"))


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
#REVISION:=$(shell $(CAT) $(SRC) | $(GREP) "svnInfo " | $(CUT) -d ' ' -f 4)

#
# If REVISION is defined then include in distribution filename.
#
#ifdef REVISION
#	BZ2 = $(BASENAME)-$(REVISION).tar.bz2
#else
#	BZ2 = $(BASENAME).tar.bz2
#endif


# Identity non-file targets
.PHONY: all bz2 clean cycle dvi dist install mostly-clean pdf ps

all: cycle

cycle: clean $(VC) ${DVI} ${PS} ${PDF}

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
# Embed git version control number.
#
# Nice output:
# $ git log --format=fuller
#
# I determined the GITAuthorEmail value above for inclusing in the
# document title page.
#
# Thore Husfeldt
# Including Git Revision Identifiers in LaTeX
# https://thorehusfeldt.net/2011/05/13/including-git-revision-identifiers-in-latex/
#
${VC}: .git/logs/HEAD
	echo "%%% This file is generated by Makefile." > ${VC}
	echo "%%% Do not edit this file!\n%%%" >> ${VC}
	echo "\\gdef\\GITAuthorEmail{${EMAIL}}" >> ${VC}
	echo "\\gdef\\GITRevision{${REVISION}}" >> ${VC}
	git log -1 --format="format:\
		\\gdef\\GITAbrHash{%h}\
		\\gdef\\GITAuthorDate{$(DATE)}\
		\\gdef\\GITAuthorName{%an}" >> ${VC}

#	git log -l --format="format:\
#		\\gdef\\GITAuthorDate{%cd '+%B %d, %Y'}" >> ${VC}

#        git log -l --pretty=format::%h %cd %s" >> ${VC}

#
# Original date format from thorehusfeldt.net/
#
# \\gdef\\GITAuthorDate{%ad}\

#
# Build distribution tarball
# The leading slash in "--exclude /$(BASENAME)" means to exclude from the
# working directory only so the $(BASENAME) further down in the hierarchy
# will be included.
# 
# How to exclude a folder from rsync
# http://askubuntu.com/questions/349613/how-to-exclude-a-folder-from-rsync
#
${BZ2}: mostly-clean
	$(MKDIR) $(BASENAME)
	$(RSYNC) -va --stats --progress * --exclude /$(BASENAME) $(BASENAME)
	$(TAR) -cvjpf $(BZ2) $(BASENAME)

# Build distribution tarball
dist: ${BZ2}
	$(RM) -f $(LOG) $(LOF) $(AUX) $(TOC) $(DVI) $(PS)
	$(RM) -f $(BBL) $(BLG) $(LOT) $(OUT)
	$(RM) -rf $(BASENAME)
	$(RM) -f *.aux *.dvi *.lof *.log *.ps *.tmp
