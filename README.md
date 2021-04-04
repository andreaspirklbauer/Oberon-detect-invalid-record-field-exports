# Oberon-detect-invalid-record-field-exports
Detects when a field of a private record is exported

The following program leads to a stack overflow when compiling A followed by B:

     MODULE A;
       TYPE X* = POINTER TO XD;
         XD = RECORD a*: POINTER TO XD END ;
     END A.

     MODULE B;
       IMPORT A;
       PROCEDURE P*(a: A.X);
       END P;
     END B.

If module A is replaced with

     MODULE A;
       TYPE X* = POINTER TO XD;
         XD = RECORD a*: X END ;
     END A.

no error occurs when compiling module B.

This repository contains various possible ways to detect when a field of a private record is exported during compilation of module A:

**ORP1:** By adding a boolean parameter 'expo' in various procedures in ORP that is passed along when parsing recursive data structures

**ORP2:** By using a global boolean variable 'expo0' in ORP that serves the same purpose as the parameter 'expo' of ORP0

One could also accept A as a "valid" module and try to solve this problem by detecting the error when compiling module B. This, however, is more involved.


---------------------------------------------------------------

**Instructions for Project Oberon 2013 (http://www.projectoberon.com)**

Compile the file [**A.Mod**](Sources/FPGAOberon2013/A.Mod) with the various versions of module ORP found in directory [**Sources/FPGAOberon2013**](Sources/FPGAOberon2013)


**Instruction for Extended Oberon (http://github.com/andreaspirklbauer/Oberon-extended)**

Compile the file [**A.Mod**](Sources/ExtendedOberon/A.Mod) with the various versions of module ORP found in directory [**Sources/ExtendedOberon**](Sources/ExtendedOberon)
