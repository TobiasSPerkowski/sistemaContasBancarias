       IDENTIFICATION DIVISION.
       PROGRAM-ID. PROJ6.

       ENVIRONMENT DIVISION.

       INPUT-OUTPUT SECTION.

       FILE-CONTROL.

           SELECT ARQ-CLIENTES
               ASSIGN TO '../DADOS/CLIENTES.txt'
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT ARQ-TRANSAC
               ASSIGN TO '../DADOS/TRANSAC.txt'
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT ARQ-CLIENTES-OUT
               ASSIGN TO '../SAIDAS/CLIENTES_OUT.txt'
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT ARQ-ERROS
               ASSIGN TO '../SAIDAS/ERROS.txt'
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT ARQ-LOG
               ASSIGN TO '../SAIDAS/LOG.txt'
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.

       FILE SECTION.

       FD  ARQ-CLIENTES.
       01  REG-IN-CLIENTE.
           05 IN-CLI-ID          PIC 9(5).
           05 IN-CLI-NOME        PIC X(30).
           05 IN-CLI-SALDO       PIC 9(9).
       FD  ARQ-TRANSAC.
       01  REG-IN-TRX.
           05 IN-TRX-CLI-ID      PIC 9(5).
           05 IN-TRX-ID          PIC 9(5).
           05 IN-TRX-TIPO        PIC X.
           05 IN-TRX-VALOR       PIC 9(9).
       FD  ARQ-CLIENTES-OUT.
       01  REG-OUT-CLIENTE.
           05 OUT-CLI-ID         PIC 9(5).
           05 OUT-CLI-NOME       PIC X(30).
           05 OUT-CLI-SALDO      PIC 9(9).
       FD  ARQ-ERROS.
       01  REG-ERRO-OUT           PIC X(150).
       FD  ARQ-LOG.
       01  REG-LOG                PIC X(120).

       WORKING-STORAGE SECTION.

       01  WS-CLIENTE.
           05 CLI-ID           PIC 9(5).
           05 CLI-NOME         PIC X(30).
           05 CLI-SALDO        PIC 9(9).
       01  WS-FLAGS.
           05 WS-EOF-CLIENTES    PIC X VALUE 'N'.
             88 EOF-CLIENTES VALUE 'S'.
           05 WS-EOF-TRX         PIC X VALUE 'N'.
             88 EOF-TRX VALUE 'S'.
       01  WS-CONTADORES.
           05 WS-LIDOS-CLI       PIC 9(7) VALUE 0.
           05 WS-LIDOS-TRX       PIC 9(7) VALUE 0.
           05 WS-PROCESSADOS     PIC 9(7) VALUE 0.
           05 WS-ERROS           PIC 9(7) VALUE 0.
           05 WS-COMMIT-COUNT    PIC 9(3) VALUE 0.
       01  WS-NUM-TXT            PIC ZZZ9.
       01  WS-VALIDACAO.
           05 WS-TRANSAC-VALIDA PIC X VALUE 'S'.
               88 TRANSAC-VALIDA   VALUE 'S'.
               88 TRANSAC-INVALIDA VALUE 'N'.
       01  WS-ERRO-TEXTO PIC X(100).
       01  WS-TABELA-CLIENTES.
       05  WS-CLIENTE OCCURS 100 TIMES.
           10 TAB-CLI-ID      PIC 9(5).
           10 TAB-CLI-NOME    PIC X(30).
           10 TAB-CLI-SALDO   PIC S9(9) COMP.
       01  WS-QTD-CLIENTES       PIC 9(3) VALUE 0.
       01  WS-CLIENTE-ENCONTRADO PIC X VALUE 'N'.
           88 CLIENTE-ENCONTRADO VALUE 'S'.
       01  WS-INDICE-CLIENTE     PIC 9(3).
       01  WS-SQL.
           05 WS-SQLCODE PIC S9(9) COMP VALUE 0.
       01  WS-ESTATISTICAS.
           05 WS-QTD-CREDITOS PIC 9(7) VALUE 0.
           05 WS-QTD-DEBITOS  PIC 9(7) VALUE 0.
           05 WS-TOT-CREDITOS PIC 9(11) VALUE 0.
           05 WS-TOT-DEBITOS  PIC 9(11) VALUE 0.

       PROCEDURE DIVISION.

       MAIN.
           PERFORM INICIALIZA
           PERFORM PROCESSA-CLIENTES
           PERFORM PROCESSA-TRANSAC
           PERFORM GERA-RELATORIO
           PERFORM FINALIZA
           GOBACK.

       INICIALIZA.
           OPEN INPUT  ARQ-CLIENTES
           OPEN INPUT  ARQ-TRANSAC
           OPEN OUTPUT ARQ-CLIENTES-OUT
           OPEN OUTPUT ARQ-LOG
           OPEN OUTPUT ARQ-ERROS.

       PROCESSA-CLIENTES.
           PERFORM UNTIL EOF-CLIENTES
               READ ARQ-CLIENTES
                    AT END
                        SET EOF-CLIENTES TO TRUE
                    NOT AT END
                        ADD 1 TO WS-LIDOS-CLI
                        PERFORM VALIDA-CLIENTE-DUPLICADO
                           IF WS-SQLCODE = 1
                               ADD 1 TO WS-ERROS
                               MOVE SPACES TO REG-ERRO-OUT
                               STRING
                                   IN-CLI-ID
                                   DELIMITED BY SIZE
                                   " - CLIENTE DUPLICADO"
                                   DELIMITED BY SIZE
                                   INTO REG-ERRO-OUT
                               END-STRING
                               WRITE REG-ERRO-OUT
                           ELSE
                               ADD 1 TO WS-QTD-CLIENTES
                               MOVE IN-CLI-ID
                                   TO TAB-CLI-ID(WS-QTD-CLIENTES)
                               MOVE IN-CLI-NOME
                                   TO TAB-CLI-NOME(WS-QTD-CLIENTES)
                               MOVE IN-CLI-SALDO
                                   TO TAB-CLI-SALDO(WS-QTD-CLIENTES)
                           END-IF
                        MOVE IN-CLI-ID
                            TO TAB-CLI-ID(WS-QTD-CLIENTES)  
                        MOVE IN-CLI-NOME
                            TO TAB-CLI-NOME(WS-QTD-CLIENTES) 
                        MOVE IN-CLI-SALDO
                            TO TAB-CLI-SALDO(WS-QTD-CLIENTES) 
               END-READ  
           END-PERFORM.

       BUSCA-CLIENTE.
           MOVE 100 TO WS-SQLCODE
           MOVE 'N' TO WS-CLIENTE-ENCONTRADO
           PERFORM VARYING WS-INDICE-CLIENTE
               FROM 1 BY 1
               UNTIL WS-INDICE-CLIENTE > WS-QTD-CLIENTES
               IF TAB-CLI-ID(WS-INDICE-CLIENTE)
                  = IN-TRX-CLI-ID
                  MOVE 'S' TO WS-CLIENTE-ENCONTRADO
                  MOVE 0 TO WS-SQLCODE
                  EXIT PERFORM
               END-IF
           END-PERFORM.

       VALIDA-CLIENTE-DUPLICADO.
           MOVE 0 TO WS-SQLCODE
           PERFORM VARYING WS-INDICE-CLIENTE
               FROM 1 BY 1
               UNTIL WS-INDICE-CLIENTE > WS-QTD-CLIENTES
               IF TAB-CLI-ID(WS-INDICE-CLIENTE)
                  = IN-CLI-ID
                  MOVE 1 TO WS-SQLCODE
                  EXIT PERFORM
               END-IF
           END-PERFORM.

       ATUALIZA-SALDO.
           IF IN-TRX-TIPO = 'C'
               ADD IN-TRX-VALOR
                    TO TAB-CLI-SALDO(WS-INDICE-CLIENTE)
           ELSE
               SUBTRACT IN-TRX-VALOR
                    FROM TAB-CLI-SALDO(WS-INDICE-CLIENTE)
           END-IF.

       PROCESSA-TRANSAC.
           PERFORM UNTIL EOF-TRX
               READ ARQ-TRANSAC
                   AT END
                       SET EOF-TRX TO TRUE
                   NOT AT END
                       ADD 1 TO WS-LIDOS-TRX
                       PERFORM VALIDA-TRANSAC
                       IF TRANSAC-VALIDA
                           PERFORM EXECUTA-TRANSAC
                       END-IF
               END-READ
           END-PERFORM.

       VALIDA-TRANSAC.
           SET TRANSAC-VALIDA TO TRUE
           PERFORM BUSCA-CLIENTE
           IF WS-SQLCODE = 100
               MOVE "CLIENTE INEXISTENTE"
                   TO WS-ERRO-TEXTO
               SET TRANSAC-INVALIDA TO TRUE
               PERFORM REGISTRA-ERRO
           END-IF
           IF TRANSAC-VALIDA
               IF IN-TRX-TIPO NOT = 'C'
                   AND IN-TRX-TIPO NOT = 'D'
                    MOVE "TIPO INVALIDO"
                        TO WS-ERRO-TEXTO
                    SET TRANSAC-INVALIDA TO TRUE
                    PERFORM REGISTRA-ERRO
               END-IF
           END-IF
           IF TRANSAC-VALIDA
               IF IN-TRX-VALOR = 0
                    MOVE "VALOR ZERADO"
                        TO WS-ERRO-TEXTO
                    SET TRANSAC-INVALIDA TO TRUE
                    PERFORM REGISTRA-ERRO
               END-IF
           END-IF
           IF TRANSAC-VALIDA
               IF IN-TRX-TIPO = 'D'
                    IF IN-TRX-VALOR >
                       TAB-CLI-SALDO(WS-INDICE-CLIENTE)
                        MOVE "SALDO INSUFICIENTE"
                            TO WS-ERRO-TEXTO
                        SET TRANSAC-INVALIDA TO TRUE
                        PERFORM REGISTRA-ERRO
                    END-IF
               END-IF
           END-IF.

       REGISTRA-ERRO.
           ADD 1 TO WS-ERROS
           MOVE SPACES TO REG-ERRO-OUT
           STRING
               IN-TRX-ID
               DELIMITED BY SIZE
               " - "
               DELIMITED BY SIZE
               WS-ERRO-TEXTO
               DELIMITED BY SIZE
               INTO REG-ERRO-OUT
           END-STRING
           WRITE REG-ERRO-OUT.

       EXECUTA-TRANSAC.
           PERFORM ATUALIZA-SALDO
           IF IN-TRX-TIPO = 'C'
              ADD 1 TO WS-QTD-CREDITOS
              ADD IN-TRX-VALOR TO WS-TOT-CREDITOS
           ELSE
              ADD 1 TO WS-QTD-DEBITOS
              ADD IN-TRX-VALOR TO WS-TOT-DEBITOS
           END-IF
           PERFORM INSERE-TRANSACAO
           PERFORM CONTROLE-COMMIT
           ADD 1 TO WS-PROCESSADOS.

       INSERE-TRANSACAO.
           MOVE SPACES TO REG-LOG
           STRING
               "TRX="
               DELIMITED BY SIZE
               IN-TRX-ID
               DELIMITED BY SIZE
               " CLI="
               DELIMITED BY SIZE
               IN-TRX-CLI-ID
               DELIMITED BY SIZE
               " TIPO="
               DELIMITED BY SIZE
               IN-TRX-TIPO
               DELIMITED BY SIZE
               " VALOR="
               DELIMITED BY SIZE
               IN-TRX-VALOR
               DELIMITED BY SIZE
               INTO REG-LOG
           END-STRING
           WRITE REG-LOG.

       CONTROLE-COMMIT.
           ADD 1 TO WS-COMMIT-COUNT
           IF WS-COMMIT-COUNT >= 100
              MOVE
              'COMMIT SIMULADO - 100 REGISTROS'
              TO REG-LOG
              WRITE REG-LOG
              MOVE 0 TO WS-COMMIT-COUNT
           END-IF.

       GERA-RELATORIO.
           MOVE SPACES TO REG-LOG
           MOVE "===== RELATORIO FINAL ====="
                   TO REG-LOG
               WRITE REG-LOG
               MOVE WS-LIDOS-CLI TO WS-NUM-TXT
               MOVE SPACES TO REG-LOG
               STRING
                   "CLIENTES LIDOS........: "
                   DELIMITED BY SIZE
                   WS-NUM-TXT
                   DELIMITED BY SIZE
                   INTO REG-LOG
           END-STRING
               WRITE REG-LOG
               MOVE WS-LIDOS-TRX TO WS-NUM-TXT
               MOVE SPACES TO REG-LOG
               STRING
                   "TRANSACOES LIDAS......: "
                   DELIMITED BY SIZE
                   WS-NUM-TXT
                   DELIMITED BY SIZE
                   INTO REG-LOG
           END-STRING
               WRITE REG-LOG
               MOVE WS-PROCESSADOS TO WS-NUM-TXT
               MOVE SPACES TO REG-LOG
               STRING
                   "TRANSACOES PROCESSADAS: "
                   DELIMITED BY SIZE
                   WS-NUM-TXT
                   DELIMITED BY SIZE
                   INTO REG-LOG
           END-STRING
               WRITE REG-LOG
               MOVE WS-ERROS TO WS-NUM-TXT
               MOVE SPACES TO REG-LOG
               STRING
                   "ERROS ENCONTRADOS.....: "
                   DELIMITED BY SIZE
                   WS-NUM-TXT
                   DELIMITED BY SIZE
                   INTO REG-LOG
           END-STRING
               WRITE REG-LOG
               MOVE WS-QTD-CREDITOS TO WS-NUM-TXT
               MOVE SPACES TO REG-LOG
               STRING
                   "QTD CREDITOS..........: "
                   DELIMITED BY SIZE
                   WS-NUM-TXT
                   DELIMITED BY SIZE
                   INTO REG-LOG
           END-STRING
               WRITE REG-LOG
               MOVE WS-QTD-DEBITOS TO WS-NUM-TXT
               MOVE SPACES TO REG-LOG
               STRING
                   "QTD DEBITOS...........: "
                   DELIMITED BY SIZE
                   WS-NUM-TXT
                   DELIMITED BY SIZE
                   INTO REG-LOG
           END-STRING
               WRITE REG-LOG
               MOVE WS-TOT-CREDITOS TO WS-NUM-TXT
               MOVE SPACES TO REG-LOG
               STRING
                   "TOTAL CREDITOS........: "
                   DELIMITED BY SIZE
                   WS-NUM-TXT
                   DELIMITED BY SIZE
                   INTO REG-LOG
           END-STRING
               WRITE REG-LOG
               MOVE WS-TOT-DEBITOS TO WS-NUM-TXT
               MOVE SPACES TO REG-LOG
               STRING
                   "TOTAL DEBITOS.........: "
                   DELIMITED BY SIZE
                   WS-NUM-TXT
                   DELIMITED BY SIZE
                   INTO REG-LOG
           END-STRING
           WRITE REG-LOG.

       FINALIZA.
           PERFORM VARYING WS-INDICE-CLIENTE
               FROM 1 BY 1
               UNTIL WS-INDICE-CLIENTE > WS-QTD-CLIENTES
               MOVE TAB-CLI-ID(WS-INDICE-CLIENTE)
                   TO OUT-CLI-ID
               MOVE TAB-CLI-NOME(WS-INDICE-CLIENTE)
                   TO OUT-CLI-NOME
               MOVE TAB-CLI-SALDO(WS-INDICE-CLIENTE)
                   TO OUT-CLI-SALDO
               WRITE REG-OUT-CLIENTE
           END-PERFORM.
           CLOSE ARQ-CLIENTES
           CLOSE ARQ-TRANSAC
           CLOSE ARQ-CLIENTES-OUT
           CLOSE ARQ-ERROS
           CLOSE ARQ-LOG.
