##===- tools/opt/Makefile ----------------------------------*- Makefile -*-===##
#
#                     The LLVM Compiler Infrastructure
#
# This file is distributed under the University of Illinois Open Source
# License. See LICENSE.TXT for details.
#
##===----------------------------------------------------------------------===##

LEVEL := ../..
TOOLNAME := opt
LINK_COMPONENTS := bitreader bitwriter naclbitwriter asmparser irreader instrumentation scalaropts objcarcopts ipo vectorize nacltransforms naclanalysis jsbackend minsfitransforms all-targets codegen

# Support plugins.
NO_DEAD_STRIP := 1

include $(LEVEL)/Makefile.common
