; RUN: llc < %s -mcpu=pwr7 -mattr=+vsx | FileCheck %s

; Also run with -schedule-ppc-vsx-fma-mutation-early as a stress test for the
; live-interval-updating logic.
; RUN: llc < %s -mcpu=pwr7 -mattr=+vsx -schedule-ppc-vsx-fma-mutation-early
target datalayout = "E-m:e-i64:64-n32:64"
target triple = "powerpc64-unknown-linux-gnu"

define void @test1(double %a, double %b, double %c, double %e, double* nocapture %d) #0 {
entry:
  %0 = tail call double @llvm.fma.f64(double %b, double %c, double %a)
  store double %0, double* %d, align 8
  %1 = tail call double @llvm.fma.f64(double %b, double %e, double %a)
  %arrayidx1 = getelementptr inbounds double* %d, i64 1
  store double %1, double* %arrayidx1, align 8
  ret void

; CHECK-LABEL: @test1
; CHECK-DAG: li [[C1:[0-9]+]], 8
; CHECK-DAG: xsmaddmdp 3, 2, 1
; CHECK-DAG: xsmaddadp 1, 2, 4
; CHECK-DAG: stxsdx 3, 0, 7
; CHECK-DAG: stxsdx 1, 7, [[C1]]
; CHECK: blr
}

define void @test2(double %a, double %b, double %c, double %e, double %f, double* nocapture %d) #0 {
entry:
  %0 = tail call double @llvm.fma.f64(double %b, double %c, double %a)
  store double %0, double* %d, align 8
  %1 = tail call double @llvm.fma.f64(double %b, double %e, double %a)
  %arrayidx1 = getelementptr inbounds double* %d, i64 1
  store double %1, double* %arrayidx1, align 8
  %2 = tail call double @llvm.fma.f64(double %b, double %f, double %a)
  %arrayidx2 = getelementptr inbounds double* %d, i64 2
  store double %2, double* %arrayidx2, align 8
  ret void

; CHECK-LABEL: @test2
; CHECK-DAG: li [[C1:[0-9]+]], 8
; CHECK-DAG: li [[C2:[0-9]+]], 16
; CHECK-DAG: xsmaddmdp 3, 2, 1
; CHECK-DAG: xsmaddmdp 4, 2, 1
; CHECK-DAG: xsmaddadp 1, 2, 5
; CHECK-DAG: stxsdx 3, 0, 8
; CHECK-DAG: stxsdx 4, 8, [[C1]]
; CHECK-DAG: stxsdx 1, 8, [[C2]]
; CHECK: blr
}

define void @test3(double %a, double %b, double %c, double %e, double %f, double* nocapture %d) #0 {
entry:
  %0 = tail call double @llvm.fma.f64(double %b, double %c, double %a)
  store double %0, double* %d, align 8
  %1 = tail call double @llvm.fma.f64(double %b, double %e, double %a)
  %2 = tail call double @llvm.fma.f64(double %b, double %c, double %1)
  %arrayidx1 = getelementptr inbounds double* %d, i64 3
  store double %2, double* %arrayidx1, align 8
  %3 = tail call double @llvm.fma.f64(double %b, double %f, double %a)
  %arrayidx2 = getelementptr inbounds double* %d, i64 2
  store double %3, double* %arrayidx2, align 8
  %arrayidx3 = getelementptr inbounds double* %d, i64 1
  store double %1, double* %arrayidx3, align 8
  ret void

; CHECK-LABEL: @test3
; CHECK-DAG: fmr [[F1:[0-9]+]], 1
; CHECK-DAG: li [[C1:[0-9]+]], 24
; CHECK-DAG: li [[C2:[0-9]+]], 16
; CHECK-DAG: li [[C3:[0-9]+]], 8
; CHECK-DAG: xsmaddmdp 4, 2, 1
; CHECK-DAG: xsmaddadp 1, 2, 5

; Note: We could convert this next FMA to M-type as well, but it would require
; re-ordering the instructions.
; CHECK-DAG: xsmaddadp [[F1]], 2, 3

; CHECK-DAG: xsmaddmdp 2, 3, 4
; CHECK-DAG: stxsdx [[F1]], 0, 8
; CHECK-DAG: stxsdx 2, 8, [[C1]]
; CHECK-DAG: stxsdx 1, 8, [[C2]]
; CHECK-DAG: stxsdx 4, 8, [[C3]]
; CHECK: blr
}

define void @test4(double %a, double %b, double %c, double %e, double %f, double* nocapture %d) #0 {
entry:
  %0 = tail call double @llvm.fma.f64(double %b, double %c, double %a)
  store double %0, double* %d, align 8
  %1 = tail call double @llvm.fma.f64(double %b, double %e, double %a)
  %arrayidx1 = getelementptr inbounds double* %d, i64 1
  store double %1, double* %arrayidx1, align 8
  %2 = tail call double @llvm.fma.f64(double %b, double %c, double %1)
  %arrayidx3 = getelementptr inbounds double* %d, i64 3
  store double %2, double* %arrayidx3, align 8
  %3 = tail call double @llvm.fma.f64(double %b, double %f, double %a)
  %arrayidx4 = getelementptr inbounds double* %d, i64 2
  store double %3, double* %arrayidx4, align 8
  ret void

; CHECK-LABEL: @test4
; CHECK-DAG: fmr [[F1:[0-9]+]], 1
; CHECK-DAG: li [[C1:[0-9]+]], 8
; CHECK-DAG: li [[C2:[0-9]+]], 16
; CHECK-DAG: xsmaddmdp 4, 2, 1

; Note: We could convert this next FMA to M-type as well, but it would require
; re-ordering the instructions.
; CHECK-DAG: xsmaddadp 1, 2, 5

; CHECK-DAG: xsmaddadp [[F1]], 2, 3
; CHECK-DAG: stxsdx [[F1]], 0, 8
; CHECK-DAG: stxsdx 4, 8, [[C1]]
; CHECK-DAG: li [[C3:[0-9]+]], 24
; CHECK-DAG: xsmaddadp 4, 2, 3
; CHECK-DAG: stxsdx 4, 8, [[C3]]
; CHECK-DAG: stxsdx 1, 8, [[C2]]
; CHECK: blr
}

declare double @llvm.fma.f64(double, double, double) #0

define void @testv1(<2 x double> %a, <2 x double> %b, <2 x double> %c, <2 x double> %e, <2 x double>* nocapture %d) #0 {
entry:
  %0 = tail call <2 x double> @llvm.fma.v2f64(<2 x double> %b, <2 x double> %c, <2 x double> %a)
  store <2 x double> %0, <2 x double>* %d, align 8
  %1 = tail call <2 x double> @llvm.fma.v2f64(<2 x double> %b, <2 x double> %e, <2 x double> %a)
  %arrayidx1 = getelementptr inbounds <2 x double>* %d, i64 1
  store <2 x double> %1, <2 x double>* %arrayidx1, align 8
  ret void

; CHECK-LABEL: @testv1
; CHECK-DAG: xvmaddmdp 36, 35, 34
; CHECK-DAG: xvmaddadp 34, 35, 37
; CHECK-DAG: li [[C1:[0-9]+]], 16
; CHECK-DAG: stxvd2x 36, 0, 3
; CHECK-DAG: stxvd2x 34, 3, [[C1:[0-9]+]]
; CHECK: blr
}

define void @testv2(<2 x double> %a, <2 x double> %b, <2 x double> %c, <2 x double> %e, <2 x double> %f, <2 x double>* nocapture %d) #0 {
entry:
  %0 = tail call <2 x double> @llvm.fma.v2f64(<2 x double> %b, <2 x double> %c, <2 x double> %a)
  store <2 x double> %0, <2 x double>* %d, align 8
  %1 = tail call <2 x double> @llvm.fma.v2f64(<2 x double> %b, <2 x double> %e, <2 x double> %a)
  %arrayidx1 = getelementptr inbounds <2 x double>* %d, i64 1
  store <2 x double> %1, <2 x double>* %arrayidx1, align 8
  %2 = tail call <2 x double> @llvm.fma.v2f64(<2 x double> %b, <2 x double> %f, <2 x double> %a)
  %arrayidx2 = getelementptr inbounds <2 x double>* %d, i64 2
  store <2 x double> %2, <2 x double>* %arrayidx2, align 8
  ret void

; CHECK-LABEL: @testv2
; CHECK-DAG: xvmaddmdp 36, 35, 34
; CHECK-DAG: xvmaddmdp 37, 35, 34
; CHECK-DAG: li [[C1:[0-9]+]], 16
; CHECK-DAG: li [[C2:[0-9]+]], 32
; CHECK-DAG: xvmaddadp 34, 35, 38
; CHECK-DAG: stxvd2x 36, 0, 3
; CHECK-DAG: stxvd2x 37, 3, [[C1:[0-9]+]]
; CHECK-DAG: stxvd2x 34, 3, [[C2:[0-9]+]]
; CHECK: blr
}

define void @testv3(<2 x double> %a, <2 x double> %b, <2 x double> %c, <2 x double> %e, <2 x double> %f, <2 x double>* nocapture %d) #0 {
entry:
  %0 = tail call <2 x double> @llvm.fma.v2f64(<2 x double> %b, <2 x double> %c, <2 x double> %a)
  store <2 x double> %0, <2 x double>* %d, align 8
  %1 = tail call <2 x double> @llvm.fma.v2f64(<2 x double> %b, <2 x double> %e, <2 x double> %a)
  %2 = tail call <2 x double> @llvm.fma.v2f64(<2 x double> %b, <2 x double> %c, <2 x double> %1)
  %arrayidx1 = getelementptr inbounds <2 x double>* %d, i64 3
  store <2 x double> %2, <2 x double>* %arrayidx1, align 8
  %3 = tail call <2 x double> @llvm.fma.v2f64(<2 x double> %b, <2 x double> %f, <2 x double> %a)
  %arrayidx2 = getelementptr inbounds <2 x double>* %d, i64 2
  store <2 x double> %3, <2 x double>* %arrayidx2, align 8
  %arrayidx3 = getelementptr inbounds <2 x double>* %d, i64 1
  store <2 x double> %1, <2 x double>* %arrayidx3, align 8
  ret void

; Note: There is some unavoidable changeability in this variant.  If the
; FMAs are reordered differently, the algorithm can pick a different
; multiplicand to destroy, changing the register assignment.  There isn't
; a good way to express this possibility, so hopefully this doesn't change
; too often.

; CHECK-LABEL: @testv3
; CHECK-DAG: xxlor [[V1:[0-9]+]], 34, 34
; CHECK-DAG: li [[C1:[0-9]+]], 48
; CHECK-DAG: li [[C2:[0-9]+]], 32
; CHECK-DAG: xvmaddmdp 37, 35, 34
; CHECK-DAG: li [[C3:[0-9]+]], 16

; Note: We could convert this next FMA to M-type as well, but it would require
; re-ordering the instructions.
; CHECK-DAG: xvmaddadp [[V1]], 35, 36

; CHECK-DAG: xvmaddmdp 36, 35, 37
; CHECK-DAG: xvmaddadp 34, 35, 38
; CHECK-DAG: stxvd2x 32, 0, 3
; CHECK-DAG: stxvd2x 36, 3, [[C1]]
; CHECK-DAG: stxvd2x 34, 3, [[C2]]
; CHECK-DAG: stxvd2x 37, 3, [[C3]]
; CHECK: blr
}

define void @testv4(<2 x double> %a, <2 x double> %b, <2 x double> %c, <2 x double> %e, <2 x double> %f, <2 x double>* nocapture %d) #0 {
entry:
  %0 = tail call <2 x double> @llvm.fma.v2f64(<2 x double> %b, <2 x double> %c, <2 x double> %a)
  store <2 x double> %0, <2 x double>* %d, align 8
  %1 = tail call <2 x double> @llvm.fma.v2f64(<2 x double> %b, <2 x double> %e, <2 x double> %a)
  %arrayidx1 = getelementptr inbounds <2 x double>* %d, i64 1
  store <2 x double> %1, <2 x double>* %arrayidx1, align 8
  %2 = tail call <2 x double> @llvm.fma.v2f64(<2 x double> %b, <2 x double> %c, <2 x double> %1)
  %arrayidx3 = getelementptr inbounds <2 x double>* %d, i64 3
  store <2 x double> %2, <2 x double>* %arrayidx3, align 8
  %3 = tail call <2 x double> @llvm.fma.v2f64(<2 x double> %b, <2 x double> %f, <2 x double> %a)
  %arrayidx4 = getelementptr inbounds <2 x double>* %d, i64 2
  store <2 x double> %3, <2 x double>* %arrayidx4, align 8
  ret void

; CHECK-LABEL: @testv4
; CHECK-DAG: xxlor [[V1:[0-9]+]], 34, 34
; CHECK-DAG: xvmaddmdp 37, 35, 34
; CHECK-DAG: li [[C1:[0-9]+]], 16
; CHECK-DAG: li [[C2:[0-9]+]], 32
; CHECK-DAG: xvmaddadp 34, 35, 38

; Note: We could convert this next FMA to M-type as well, but it would require
; re-ordering the instructions.
; CHECK-DAG: xvmaddadp [[V1]], 35, 36

; CHECK-DAG: stxvd2x 32, 0, 3
; CHECK-DAG: stxvd2x 37, 3, [[C1]]
; CHECK-DAG: li [[C3:[0-9]+]], 48
; CHECK-DAG: xvmaddadp 37, 35, 36
; CHECK-DAG: stxvd2x 37, 3, [[C3]]
; CHECK-DAG: stxvd2x 34, 3, [[C2]]
; CHECK: blr
}

declare <2 x double> @llvm.fma.v2f64(<2 x double>, <2 x double>, <2 x double>) #0

attributes #0 = { nounwind readnone }

