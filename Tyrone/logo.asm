.MODEL SMALL
.STACK 64
.DATA

;--------- DECLARATIONS

logo01 db "                                   *@.@@ @@ @*@"
      db 10,13,"                               @@@             @@@("
      db "$"

logo02 db 10,13,"                          @@@                       @/("
      db 10,13,"                         @      @@ %&                  @."
      db "$"

logo03  db 10,13,"                       @       @     @                   @,"
      db 10,13,"                    @@         #      @   @@              *@."
      db "$"

logo04  db 10,13,"                    @          @       @ @  @               @@ "
      db 10,13,"                   @           ,             :               @@"
      db "$"

logo05  db 10,13,"                 &@           &              @                @*"
      db 10,13,"                 @           %                @               &,"
      db "$"

logo06  db 10,13,"                @@          %                  @               @."
      db 10,13,"                 @          *.                  @              @@"
      db "$"

logo07  db 10,13,"                 (          ,                   (              @/"
      db 10,13,"                 @         ,                     ,             @@"
      db "$"

logo08  db 10,13,"                @@         @                      (            @"
      db 10,13,"                 @          <                      (          @"
      db "$"

logo09  db 10,13,"                 @@          &                      @         @"
      db 10,13,"                  ,@         /                      @        @@"
      db "$"

logo10 db 10,13,"                   *@       /                        \      @@"
      db 10,13,"                    %@     /                          #   @@"
      db "$"

logo11 db 10,13,"                       @  .                            # @@"
      db 10,13,"                         @                            @@@"
      db "$"

logo12 db 10,13,"                          . @(                     @@"
      db 10,13,"                              @/@@@ @@ @ @@@ @@ @@ @"
      db "$"

.CODE

MAIN PROC

 MOV AX,@DATA
 MOV DS,AX
 
 ;-------------------- PRINT LOGO
 MOV AH,09H
 LEA DX,logo01
 INT 21H
 LEA DX,logo02
 INT 21H
 LEA DX,logo03
 INT 21H
 LEA DX,logo04
 INT 21H
 LEA DX,logo05
 INT 21H 
 LEA DX,logo06
 INT 21H 
 LEA DX,logo07
 INT 21H 
 LEA DX,logo08
 INT 21H 
 LEA DX,logo09
 INT 21H 
 LEA DX,logo10
 INT 21H 
 LEA DX,logo11
 INT 21H 
 LEA DX,logo12
 INT 21H 
 
 ;-------------------- END LOGO
 
 MOV AX,4C00H
 INT 21H
MAIN ENDP
 END MAIN
