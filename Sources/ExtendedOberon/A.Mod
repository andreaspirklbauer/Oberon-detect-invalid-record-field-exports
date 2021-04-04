MODULE A;
  TYPE
    X* = POINTER TO XD;    (*allowed*)
    XD = RECORD
      a*: POINTER TO XD;
    END;                   (*XD must be exported*)

    A1* = ARRAY 10 OF RECORD j*: INTEGER END ;    (*allowed*)
    A2 = ARRAY 10 OF RECORD c*: INTEGER END;    (*A2 must be exported*)

    Y1* = RECORD i*: INTEGER END ;    (*allowed*)
    Y2 = RECORD i*: INTEGER END ;    (*Y2 must be exported*)

    XB = RECORD a, b*: INTEGER END ;     (*XB must be exported*)

    C* = RECORD
          d: RECORD
               e*: ARRAY 10 OF RECORD f*: REAL END
             END ;
             g: RECORD x: REAL END
        END ;   (*d must be exported*)

    D = RECORD
          d: RECORD
               e*: ARRAY 10 OF RECORD f: REAL END
              END
        END ;   (*D and d must be exported*)

    E = RECORD
          d: RECORD
               e: ARRAY 10 OF RECORD f*: REAL END
              END
        END ;   (*E, d and e must be exported*)

    F* = RECORD
      e1*, e2*, e3*: RECORD
        f1*, f2*, f3, f4*: RECORD
          g1*, g2*: RECORD
            e*: ARRAY 10 OF RECORD f: REAL END
          END
        END
      END
    END ;   (*f3 must be exported*)

    R = RECORD i: INTEGER END;
    P = POINTER TO a;
    a* = RECORD i*: INTEGER; next*: P; rec*: R END;

  VAR
    a1: A1;  (*allowed, i.e. a1 must NOT be exported*)
    a2: ARRAY 10 OF RECORD c*: INTEGER END;  (*a2 must be exported*)

    y1: Y1;  (*allowed, i.e. y1 must NOT be exported*)
    y2: RECORD i*: INTEGER END ;  (*y2 must be exported*)
    y3*, y4*, y5*, y6, y7*: RECORD i*: INTEGER END ;  (*y6 must be exported*)

    xa*: POINTER TO XD;  (*allowed*)
    xd*, yd, zd*: RECORD
      a*: POINTER TO XD;
    END;                 (*yd must be exported*)

    c1*, c2, c3*, c4, c5*: RECORD
         d: RECORD
              e: ARRAY 10 OF RECORD f*: REAL END
            END
       END ;   (*c2, c4, d and e must be exported*)

       r*: R;  (*allowed*)
END A.

ORP.Compile A.Mod/s ~
