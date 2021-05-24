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

-------------------------------------------------------------------------------------

**Diffference between ORP (=official Project Oberon 2013) and ORP1**

```diff
--- FPGAOberon2013/ORP.Mod	2021-05-24 10:06:15.000000000 +0200
+++ Oberon-detect-invalid-record-field-exports/Sources/FPGAOberon2013/ORP1.Mod	2020-11-14 09:44:28.000000000 +0100
@@ -16,7 +16,7 @@
     level, exno, version: INTEGER;
     newSF: BOOLEAN;  (*option flag*)
     expression: PROCEDURE (VAR x: ORG.Item);  (*to avoid forward reference*)
-    Type: PROCEDURE (VAR type: ORB.Type);
+    Type: PROCEDURE (VAR type: ORB.Type; expo: BOOLEAN);
     FormalType: PROCEDURE (VAR typ: ORB.Type; dim: INTEGER);
     modid: ORS.Ident;
     pbsList: PtrBase;   (*list of names of pointer base types*)
@@ -609,26 +609,26 @@
     END
   END IdentList;
 
-  PROCEDURE ArrayType(VAR type: ORB.Type);
+  PROCEDURE ArrayType(VAR type: ORB.Type; expo: BOOLEAN);
     VAR x: ORG.Item; typ: ORB.Type; len: LONGINT;
   BEGIN NEW(typ); typ.form := ORB.NoTyp;
     expression(x);
     IF (x.mode = ORB.Const) & (x.type.form = ORB.Int) & (x.a >= 0) THEN len := x.a
     ELSE len := 1; ORS.Mark("not a valid length")
     END ;
-    IF sym = ORS.of THEN ORS.Get(sym); Type(typ.base);
+    IF sym = ORS.of THEN ORS.Get(sym); Type(typ.base, expo);
       IF (typ.base.form = ORB.Array) & (typ.base.len < 0) THEN ORS.Mark("dyn array not allowed") END
-    ELSIF sym = ORS.comma THEN ORS.Get(sym); ArrayType(typ.base)
+    ELSIF sym = ORS.comma THEN ORS.Get(sym); ArrayType(typ.base, expo)
     ELSE ORS.Mark("missing OF"); typ.base := ORB.intType
     END ;
     typ.size := (len * typ.base.size + 3) DIV 4 * 4;
     typ.form := ORB.Array; typ.len := len; type := typ
   END ArrayType;
 
-  PROCEDURE RecordType(VAR type: ORB.Type);
+  PROCEDURE RecordType(VAR type: ORB.Type; expo: BOOLEAN);
     VAR obj, obj0, new, bot, base: ORB.Object;
       typ, tp: ORB.Type;
-      offset, off, n: LONGINT;
+      offset, off, n: LONGINT; expo0: BOOLEAN;
   BEGIN NEW(typ); typ.form := ORB.NoTyp; typ.base := NIL; typ.mno := -level; typ.nofpar := 0; offset := 0; bot := NIL;
     IF sym = ORS.lparen THEN
       ORS.Get(sym); (*record extension*)
@@ -648,18 +648,19 @@
       Check(ORS.rparen, "no )")
     END ;
     WHILE sym = ORS.ident DO  (*fields*)
-      n := 0; obj := bot;
+      n := 0; obj := bot; expo0 := TRUE;
       WHILE sym = ORS.ident DO
         obj0 := obj;
         WHILE (obj0 # NIL) & (obj0.name # ORS.id) DO obj0 := obj0.next END ;
         IF obj0 # NIL THEN ORS.Mark("mult def") END ;
         NEW(new); ORS.CopyId(new.name); new.class := ORB.Fld; new.next := obj; obj := new; INC(n);
         ORS.Get(sym); CheckExport(new.expo);
+        IF ~new.expo THEN expo0 := FALSE ELSIF ~expo THEN ORS.Mark("invalid field export") END ;
         IF (sym # ORS.comma) & (sym # ORS.colon) THEN ORS.Mark("comma expected")
         ELSIF sym = ORS.comma THEN ORS.Get(sym)
         END
       END ;
-      Check(ORS.colon, "colon expected"); Type(tp);
+      Check(ORS.colon, "colon expected"); Type(tp, expo & expo0);
       IF (tp.form = ORB.Array) & (tp.len < 0) THEN ORS.Mark("dyn array not allowed") END ;
       IF tp.size > 1 THEN offset := (offset+3) DIV 4 * 4 END ;
       offset := offset + n * tp.size; off := offset; obj0 := obj;
@@ -737,7 +738,7 @@
     IF lev # 0 THEN ORS.Mark("ptr base must be global") END
   END CheckRecLevel;
 
-  PROCEDURE Type0(VAR type: ORB.Type);
+  PROCEDURE Type0(VAR type: ORB.Type; expo: BOOLEAN);
     VAR dmy: LONGINT; obj: ORB.Object; ptbase: PtrBase;
   BEGIN type := ORB.intType; (*sync*)
     IF (sym # ORS.ident) & (sym < ORS.array) THEN ORS.Mark("not a type");
@@ -749,9 +750,9 @@
         IF (obj.type # NIL) & (obj.type.form # ORB.NoTyp) THEN type := obj.type END
       ELSE ORS.Mark("not a type or undefined")
       END
-    ELSIF sym = ORS.array THEN ORS.Get(sym); ArrayType(type)
+    ELSIF sym = ORS.array THEN ORS.Get(sym); ArrayType(type, expo)
     ELSIF sym = ORS.record THEN
-      ORS.Get(sym); RecordType(type); Check(ORS.end, "no END")
+      ORS.Get(sym); RecordType(type, expo); Check(ORS.end, "no END")
     ELSIF sym = ORS.pointer THEN
       ORS.Get(sym); Check(ORS.to, "no TO");
       NEW(type);  type.form := ORB.Pointer; type.size := ORG.WordSize; type.base := ORB.intType;
@@ -767,7 +768,7 @@
           NEW(ptbase); ORS.CopyId(ptbase.name); ptbase.type := type; ptbase.next := pbsList; pbsList := ptbase
         END ;
         ORS.Get(sym)
-      ELSE Type(type.base);
+      ELSE Type(type.base, expo);
         IF (type.base.form # ORB.Record) OR (type.base.typobj = NIL) THEN ORS.Mark("must point to named record") END ;
         CheckRecLevel(level)
       END
@@ -806,7 +807,7 @@
       WHILE sym = ORS.ident DO
         ORS.CopyId(id); ORS.Get(sym); CheckExport(expo);
         IF sym = ORS.eql THEN ORS.Get(sym) ELSE ORS.Mark("=?") END ;
-        Type(tp);
+        Type(tp, expo);
         ORB.NewObj(obj, id, ORB.Typ); obj.type := tp; obj.expo := expo; obj.lev := level;
         IF tp.typobj = NIL THEN tp.typobj := obj END ;
         IF expo & (obj.type.form = ORB.Record) THEN obj.exno := exno; INC(exno) ELSE obj.exno := 0 END ;
@@ -824,7 +825,9 @@
     IF sym = ORS.var THEN
       ORS.Get(sym);
       WHILE sym = ORS.ident DO
-        IdentList(ORB.Var, first); Type(tp);
+        IdentList(ORB.Var, first); obj := first; expo := TRUE;
+        WHILE (obj # NIL) & expo DO expo := obj.expo; obj := obj.next END ;
+        Type(tp, expo);
         obj := first;
         WHILE obj # NIL DO
           obj.type := tp; obj.lev := level;
```