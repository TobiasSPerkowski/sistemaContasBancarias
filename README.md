# Sistema de Contas Bancárias - Projeto 6 COBOL

Projeto desenvolvido para o programa AceleraMaker com foco em processamento batch, manipulação de arquivos, integração com SQL e simulação de acesso a banco de dados.

## Objetivo

O sistema processa arquivos de clientes e transações bancárias, realizando validações, atualização de saldos, registro de erros e geração de relatórios de execução.

O projeto possui duas implementações:

* **SIMULA.cbl**: versão funcional que simula o banco de dados utilizando arquivos e estruturas em memória.
* **PROJ6.cbl**: versão adaptada para utilização de comandos SQL (`EXEC SQL`), seguindo a especificação do projeto.

Devido às limitações do ambiente TK5/MVS 3.8J, apenas a versão simulada pôde ser executada e validada.

## Estrutura do Projeto

```text
sistemaContasBancarias/
│
├── COBOL/
│   ├── PROJ6.cbl
│   ├── SIMULA.cbl
│   ├── CLIENTE.cpy
│   └── TRANSAC.cpy
│
├── DADOS/
│   ├── CLIENTES.txt
│   └── TRANSAC.txt
│
├── SAIDAS/
│   ├── CLIENTES_OUT.txt
│   ├── ERROS.txt
│   └── LOG.txt
│
└── README.md
```

## Implementações

### SIMULA.cbl

Implementação utilizada para testes e validação do processamento.

Nessa versão, o comportamento esperado do banco de dados é simulado através de:

* carregamento dos clientes em memória;
* busca de clientes em tabela interna (`OCCURS`);
* atualização de saldo em memória;
* geração de arquivos de saída para representar as operações realizadas.

Essa implementação foi utilizada para verificar a lógica de negócio do projeto, já que o ambiente disponível não possui suporte ao DB2.

### PROJ6.cbl

Implementação desenvolvida para atender à especificação do projeto.

Nesta versão foram adicionados:

* comandos `EXEC SQL`;
* consultas `SELECT`;
* operações `INSERT`;
* operações `UPDATE`;
* controle de `COMMIT`;
* tratamento de `ROLLBACK`;
* utilização de `SQLCODE` e `SQLCA`.

Por não haver um subsistema DB2 disponível no ambiente utilizado durante o desenvolvimento, essa versão não pôde ser compilada ou executada.

Seu objetivo é demonstrar como a solução seria implementada em um ambiente COBOL/DB2 real.

## Arquivos de Entrada

### CLIENTES.txt

Arquivo contendo os clientes cadastrados.

Estrutura:

| Campo     | Tamanho |
| --------- | ------- |
| CLI_ID    | 5       |
| CLI_NOME  | 30      |
| CLI_SALDO | 9       |

Exemplo:

```text
00001JOAO SILVA                    000010000
00002MARIA SOUZA                   000025000
00003CARLOS PEREIRA                000005000
```

---

### TRANSAC.txt

Arquivo contendo as movimentações financeiras.

Estrutura:

| Campo     | Tamanho |
| --------- | ------- |
| TRX_ID    | 5       |
| CLI_ID    | 5       |
| TRX_TIPO  | 1       |
| TRX_VALOR | 9       |

Tipos de transação:

* C = Crédito
* D = Débito

Exemplo:

```text
0000100001C000000500
0000200001D000000200
0000300002D000001000
```

## Regras de Negócio

### Clientes

* O nome do cliente é obrigatório.
* Clientes inexistentes são cadastrados.
* Clientes já existentes têm seus dados atualizados.

### Transações

* O cliente deve existir.
* O tipo deve ser C ou D.
* O valor deve ser maior que zero.
* Débitos não podem gerar saldo negativo.
* Créditos são aplicados diretamente ao saldo.

### Tratamento de Erros

As seguintes situações são tratadas:

* cliente inexistente;
* tipo de transação inválido;
* valor zerado;
* saldo insuficiente;
* falhas de acesso ao banco de dados (na versão SQL).

## Arquivos de Saída

### CLIENTES_OUT.txt

Arquivo contendo o resultado do processamento dos clientes.

### ERROS.txt

Arquivo contendo os erros encontrados durante a execução.

Exemplo:

```text
00015 - CLIENTE INEXISTENTE
00027 - SALDO INSUFICIENTE
```

### LOG.txt

Arquivo contendo informações operacionais e estatísticas do processamento.

Exemplo:

```text
===== RELATORIO FINAL =====
CLIENTES LIDOS........: 3
TRANSACOES LIDAS......: 10
TRANSACOES PROCESSADAS: 8
ERROS ENCONTRADOS.....: 2
```

## Fluxo de Execução

O processamento ocorre em três etapas:

1. Ordenação do arquivo de clientes;
2. Ordenação do arquivo de transações;
3. Execução do programa COBOL.

```text
CLIENTES.TXT ----\
                  \
                   --> PROCESSAMENTO --> SAÍDAS
                  /
TRANSAC.TXT -----/
```

## Tecnologias Utilizadas

* COBOL
* Copybooks
* GnuCOBOL

## Autor

Tobias Saueressig
