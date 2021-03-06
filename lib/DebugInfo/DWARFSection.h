//===-- DWARFSection.h ------------------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_DEBUGINFO_DWARFSECTION_H
#define LLVM_LIB_DEBUGINFO_DWARFSECTION_H

#include "DWARFRelocMap.h"

namespace llvm {

struct DWARFSection {
  StringRef Data;
  RelocAddrMap Relocs;
};

}

#endif
