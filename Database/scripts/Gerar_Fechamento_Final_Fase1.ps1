# =============================================================================
# WMA TRAVEL ERP
# FECHAMENTO FORMAL DA FASE 1
#
# Gera:
#   1. Database/certification/FASE_1_CERTIFICACAO_FINAL.md
#   2. Docs/PHASE_1_TO_PHASE_2_TRANSITION.md
#
# PostgreSQL: 18.4
# Data: 17/08/2026
#
# IMPORTANTE:
#   - Nao altera o banco de dados.
#   - Nao executa migrations.
#   - Nao realiza commit.
#   - Nao realiza push.
#   - Nao cria tag Git.
# =============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -----------------------------------------------------------------------------
# CONFIGURACAO
# -----------------------------------------------------------------------------

$ProjectRoot = "E:\WMA Travel ERP"
$DatabaseDir = Join-Path $ProjectRoot "Database"
$CertificationDir = Join-Path $DatabaseDir "certification"
$DocsDir = Join-Path $ProjectRoot "Docs"

$CertificationDate = "17/08/2026"
$PostgreSQLVersion = "18.4"

$ReferenceDatabase = "wma_travel"
$RebuildDatabase = "wma_travel_rebuild_test"

$BaselineCommit = "d63800e"

# -----------------------------------------------------------------------------
# ARQUIVOS DE ENTRADA
# -----------------------------------------------------------------------------

$CertificationFiles = @(
    "10.12.3_CERTIFICACAO_INSTALACAO.md"
    "10.12.4_CERTIFICACAO_REPRODUTIBILIDADE.md"
    "10.12.5_CERTIFICACAO_BANCO_LIMPO.md"
    "10.12.6_CERTIFICACAO_BASELINE_REBUILD.md"
)

# -----------------------------------------------------------------------------
# CABECALHO
# -----------------------------------------------------------------------------

Clear-Host

Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host "WMA TRAVEL ERP" `
    -ForegroundColor Cyan

Write-Host "FECHAMENTO FORMAL DA FASE 1" `
    -ForegroundColor Cyan

Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host ""

# -----------------------------------------------------------------------------
# VALIDACAO DA ESTRUTURA
# -----------------------------------------------------------------------------

Write-Host "=== VALIDACAO DA ESTRUTURA ===" `
    -ForegroundColor Yellow

if (-not (Test-Path $ProjectRoot)) {
    throw "Raiz do projeto nao encontrada: $ProjectRoot"
}

if (-not (Test-Path $DatabaseDir)) {
    throw "Diretorio Database nao encontrado."
}

if (-not (Test-Path $CertificationDir)) {
    throw "Diretorio Database\certification nao encontrado."
}

if (-not (Test-Path $DocsDir)) {
    New-Item `
        -ItemType Directory `
        -Path $DocsDir `
        -Force |
        Out-Null

    Write-Host "CRIADO - Docs" `
        -ForegroundColor Green
}

Set-Location $ProjectRoot

Write-Host "OK - Estrutura principal encontrada." `
    -ForegroundColor Green

# -----------------------------------------------------------------------------
# VALIDACAO DAS CERTIFICACOES 10.12.3 A 10.12.6
# -----------------------------------------------------------------------------

Write-Host ""
Write-Host "=== CERTIFICACOES DE ORIGEM ===" `
    -ForegroundColor Yellow

$CertificationHashes = @()

foreach ($FileName in $CertificationFiles) {

    $FullPath = Join-Path $CertificationDir $FileName

    if (-not (Test-Path $FullPath)) {
        throw "Certificacao obrigatoria nao encontrada: $FileName"
    }

    $Hash = Get-FileHash `
        -Path $FullPath `
        -Algorithm SHA256

    $CertificationHashes += [PSCustomObject]@{
        File = $FileName
        Hash = $Hash.Hash
    }

    Write-Host "OK - $FileName" `
        -ForegroundColor Green
}

# -----------------------------------------------------------------------------
# VALIDAR GIT
# -----------------------------------------------------------------------------

Write-Host ""
Write-Host "=== GIT ===" `
    -ForegroundColor Yellow

$GitHead = (git rev-parse --short HEAD).Trim()

if ($LASTEXITCODE -ne 0) {
    throw "Nao foi possivel consultar o Git."
}

Write-Host "HEAD atual: $GitHead"

Write-Host "Baseline certificada: $BaselineCommit"

if ($GitHead -eq $BaselineCommit) {
    Write-Host "OK - HEAD corresponde ao commit baseline certificado." `
        -ForegroundColor Green
}
else {
    Write-Host `
        "ATENCAO - HEAD atual difere do commit baseline certificado." `
        -ForegroundColor Yellow
}

# -----------------------------------------------------------------------------
# PREPARAR TABELA DE HASHES
# -----------------------------------------------------------------------------

$HashTableLines = @()

$HashTableLines += "| CertificaÃ§Ã£o | SHA-256 |"
$HashTableLines += "| --- | --- |"

foreach ($Item in $CertificationHashes) {
    $HashTableLines += "| ``$($Item.File)`` | ``$($Item.Hash)`` |"
}

$HashTable = $HashTableLines -join "`r`n"

# =============================================================================
# CERTIFICACAO GLOBAL DA FASE 1
# =============================================================================

Write-Host ""
Write-Host "=== CERTIFICACAO GLOBAL DA FASE 1 ===" `
    -ForegroundColor Yellow

$FinalCertificationFile = Join-Path `
    $CertificationDir `
    "FASE_1_CERTIFICACAO_FINAL.md"

$FinalCertificationContent = @"
# WMA Travel ERP â€” CertificaÃ§Ã£o Final da Fase 1

## FundaÃ§Ã£o, Modelagem e CertificaÃ§Ã£o do Banco de Dados

**Data da certificaÃ§Ã£o:** $CertificationDate  
**Projeto:** WMA Travel ERP  
**Fase:** 1 â€” FundaÃ§Ã£o e Banco de Dados  
**SGBD:** PostgreSQL $PostgreSQLVersion  
**Banco de referÃªncia:** ``$ReferenceDatabase``  
**Banco de reconstruÃ§Ã£o:** ``$RebuildDatabase``  
**Commit baseline certificado:** ``$BaselineCommit``  
**Status:** APROVADA

---

## 1. Objetivo

Este documento formaliza o encerramento tÃ©cnico da Fase 1 do WMA Travel ERP e
consolida as evidÃªncias de modelagem, padronizaÃ§Ã£o, auditoria, reconstruÃ§Ã£o,
reprodutibilidade e certificaÃ§Ã£o da baseline PostgreSQL.

## 2. Escopo certificado

A Fase 1 contemplou a construÃ§Ã£o e validaÃ§Ã£o da fundaÃ§Ã£o de dados do sistema,
incluindo:

- modelagem do banco de dados;
- organizaÃ§Ã£o dos schemas;
- tabelas e relacionamentos;
- constraints;
- Ã­ndices;
- sequences e identity;
- triggers;
- views;
- functions;
- procedures;
- padronizaÃ§Ã£o de objetos;
- auditoria estrutural;
- catÃ¡logo tÃ©cnico;
- dicionÃ¡rio de dados;
- baseline SQL;
- processo de reconstruÃ§Ã£o;
- validaÃ§Ã£o de reprodutibilidade;
- comparaÃ§Ã£o baseline Ã— rebuild;
- certificaÃ§Ã£o final.

## 3. Universo estrutural certificado

| Objeto | Quantidade |
| --- | ---: |
| Schemas | 8 |
| Tabelas | 209 |
| Views | 38 |
| Sequences | 206 |
| Constraints | 1176 |
| Ãndices | 357 |
| Functions | 64 |
| Procedures | 11 |
| Triggers | 138 |

## 4. CertificaÃ§Ãµes consolidadas

As etapas finais foram formalizadas atravÃ©s das seguintes certificaÃ§Ãµes:

- ETAPA 10.12.2 â€” certificaÃ§Ã£o definitiva da baseline;
- ETAPA 10.12.3 â€” certificaÃ§Ã£o do processo de instalaÃ§Ã£o;
- ETAPA 10.12.4 â€” certificaÃ§Ã£o de reprodutibilidade;
- ETAPA 10.12.5 â€” certificaÃ§Ã£o de reconstruÃ§Ã£o em banco limpo;
- ETAPA 10.12.6 â€” certificaÃ§Ã£o baseline Ã— rebuild.

## 5. Integridade das certificaÃ§Ãµes finais

Os documentos das ETAPAS 10.12.3 a 10.12.6 possuem os seguintes hashes
SHA-256:

$HashTable

Os hashes acima permitem verificar a integridade dos documentos utilizados no
fechamento formal da Fase 1.

## 6. Reprodutibilidade

A baseline oficial foi submetida a processo de reconstruÃ§Ã£o utilizando banco
independente.

Banco de referÃªncia:

``$ReferenceDatabase``

Banco reconstruÃ­do:

``$RebuildDatabase``

O ambiente reconstruÃ­do foi submetido a inventÃ¡rio, normalizaÃ§Ã£o, geraÃ§Ã£o de
hashes e comparaÃ§Ã£o estrutural.

## 7. DivergÃªncias

ApÃ³s normalizaÃ§Ã£o e validaÃ§Ã£o das evidÃªncias produzidas durante a certificaÃ§Ã£o,
nÃ£o permaneceram divergÃªncias estruturais crÃ­ticas impeditivas para o
encerramento da Fase 1.

**DivergÃªncias estruturais crÃ­ticas: 0**

## 8. Baseline certificada

O commit utilizado como marco da certificaÃ§Ã£o definitiva da ETAPA 10.12.2 Ã©:

``$BaselineCommit``

Esse commit representa a baseline estrutural certificada antes da inclusÃ£o dos
documentos administrativos de fechamento global da Fase 1.

O commit contendo este documento serÃ¡ registrado posteriormente pelo processo
normal de versionamento Git.

## 9. GovernanÃ§a apÃ³s a Fase 1

A partir deste marco, a baseline certificada nÃ£o deverÃ¡ receber alteraÃ§Ãµes
estruturais diretas sem rastreabilidade.

Toda evoluÃ§Ã£o persistente do banco de dados deverÃ¡ utilizar processo
controlado contendo, quando aplicÃ¡vel:

1. migration SQL versionada;
2. identificaÃ§Ã£o da necessidade;
3. validaÃ§Ã£o em ambiente de desenvolvimento;
4. anÃ¡lise de impacto;
5. auditoria;
6. documentaÃ§Ã£o;
7. commit Git;
8. aplicaÃ§Ã£o controlada;
9. validaÃ§Ã£o pÃ³s-aplicaÃ§Ã£o.

A baseline certificada da Fase 1 passa a funcionar como referÃªncia histÃ³rica
do projeto.

## 10. DecisÃ£o final

**FASE 1: APROVADA**

**BANCO DE DADOS: CERTIFICADO**

**BASELINE: CERTIFICADA**

**REPRODUTIBILIDADE: APROVADA**

**DIVERGÃŠNCIAS ESTRUTURAIS CRÃTICAS: 0**

**RECONSTRUÃ‡ÃƒO CONTROLADA: APROVADA**

**TRANSIÃ‡ÃƒO PARA FASE 2: AUTORIZADA**

---

## 11. Encerramento

A Fase 1 do WMA Travel ERP encontra-se formalmente encerrada sob os critÃ©rios
tÃ©cnicos estabelecidos pelo projeto.

A evoluÃ§Ã£o do sistema deverÃ¡ prosseguir atravÃ©s da Fase 2, preservando a
rastreabilidade e a integridade da baseline certificada.

---

**WMA Travel ERP**  
**Fase 1 â€” ConcluÃ­da e Certificada**  
**17/08/2026**
"@

Set-Content `
    -Path $FinalCertificationFile `
    -Value $FinalCertificationContent `
    -Encoding UTF8

Write-Host "OK - $FinalCertificationFile" `
    -ForegroundColor Green

# =============================================================================
# DOCUMENTO DE TRANSICAO FASE 1 -> FASE 2
# =============================================================================

Write-Host ""
Write-Host "=== TRANSICAO FASE 1 -> FASE 2 ===" `
    -ForegroundColor Yellow

$TransitionFile = Join-Path `
    $DocsDir `
    "PHASE_1_TO_PHASE_2_TRANSITION.md"

$TransitionContent = @"
# WMA Travel ERP â€” TransiÃ§Ã£o da Fase 1 para a Fase 2

## Marco Formal de GovernanÃ§a

**Data:** $CertificationDate  
**Fase encerrada:** Fase 1 â€” FundaÃ§Ã£o e Banco de Dados  
**PrÃ³xima fase:** Fase 2 â€” Backend e API  
**PostgreSQL:** $PostgreSQLVersion  
**Baseline certificada:** ``$BaselineCommit``

---

## 1. Objetivo

Este documento estabelece o marco formal de transiÃ§Ã£o entre a Fase 1 e a
Fase 2 do WMA Travel ERP.

A partir deste ponto, a fundaÃ§Ã£o do banco de dados deixa de ser tratada como
estrutura em construÃ§Ã£o e passa a ser tratada como baseline certificada.

## 2. SituaÃ§Ã£o da Fase 1

A Fase 1 foi submetida aos processos de:

- modelagem;
- padronizaÃ§Ã£o;
- auditoria;
- inventÃ¡rio;
- reconstruÃ§Ã£o;
- comparaÃ§Ã£o estrutural;
- validaÃ§Ã£o de reprodutibilidade;
- certificaÃ§Ã£o.

**Status da Fase 1: CONCLUÃDA E CERTIFICADA**

## 3. Baseline

A baseline certificada encontra-se associada ao seguinte marco Git:

``$BaselineCommit``

As certificaÃ§Ãµes posteriores ao commit documentam formalmente o encerramento
da fase sem redefinir silenciosamente a baseline tÃ©cnica jÃ¡ validada.

## 4. Regra de governanÃ§a

A partir da Fase 2, alteraÃ§Ãµes estruturais persistentes no banco de dados nÃ£o
devem ser realizadas diretamente sobre a baseline histÃ³rica.

As alteraÃ§Ãµes deverÃ£o ser introduzidas atravÃ©s de migrations versionadas e
rastreÃ¡veis.

## 5. Fluxo de alteraÃ§Ã£o estrutural

O fluxo padrÃ£o passa a ser:

````text
Necessidade de alteraÃ§Ã£o
        |
        v
Migration SQL versionada
        |
        v
ValidaÃ§Ã£o em desenvolvimento
        |
        v
AnÃ¡lise de impacto
        |
        v
Auditoria
        |
        v
Commit Git
        |
        v
AplicaÃ§Ã£o controlada
        |
        v
ValidaÃ§Ã£o pÃ³s-aplicaÃ§Ã£o
````

## 6. Requisitos mÃ­nimos de migration

Cada migration deverÃ¡ possuir, quando aplicÃ¡vel:

- identificaÃ§Ã£o Ãºnica;
- descriÃ§Ã£o da alteraÃ§Ã£o;
- justificativa;
- objetos afetados;
- SQL versionado;
- validaÃ§Ã£o prÃ©via;
- anÃ¡lise de dependÃªncias;
- estratÃ©gia de rollback quando tecnicamente aplicÃ¡vel;
- evidÃªncia de execuÃ§Ã£o;
- validaÃ§Ã£o pÃ³s-aplicaÃ§Ã£o.

## 7. ProteÃ§Ã£o da baseline

A baseline certificada deverÃ¡ permanecer disponÃ­vel para:

- auditoria;
- reconstruÃ§Ã£o;
- comparaÃ§Ã£o;
- investigaÃ§Ã£o de regressÃµes;
- recuperaÃ§Ã£o histÃ³rica;
- validaÃ§Ã£o de migrations;
- rastreabilidade.

NÃ£o deverÃ¡ haver alteraÃ§Ã£o silenciosa de arquivos utilizados como referÃªncia
histÃ³rica da certificaÃ§Ã£o.

## 8. Fase 2

A Fase 2 poderÃ¡ utilizar a baseline certificada como fundaÃ§Ã£o para o
desenvolvimento das camadas superiores do sistema.

O escopo inicial poderÃ¡ compreender:

- arquitetura do backend;
- configuraÃ§Ã£o da aplicaÃ§Ã£o;
- conexÃ£o com PostgreSQL;
- camada de persistÃªncia;
- models;
- schemas de aplicaÃ§Ã£o;
- services;
- API;
- autenticaÃ§Ã£o;
- autorizaÃ§Ã£o;
- validaÃ§Ãµes;
- testes;
- documentaÃ§Ã£o tÃ©cnica da API.

## 9. Gate de transiÃ§Ã£o

Os seguintes critÃ©rios encontram-se estabelecidos para autorizaÃ§Ã£o da Fase 2:

- baseline certificada;
- estrutura auditada;
- reconstruÃ§Ã£o validada;
- reprodutibilidade aprovada;
- divergÃªncias estruturais crÃ­ticas iguais a zero;
- certificaÃ§Ãµes finais formalizadas;
- governanÃ§a de migrations definida.

**GATE FASE 1 -> FASE 2: APROVADO**

## 10. DecisÃ£o

A Fase 1 encontra-se formalmente encerrada.

O projeto estÃ¡ autorizado a prosseguir para a Fase 2, mantendo a baseline
certificada como referÃªncia histÃ³rica e utilizando migrations versionadas
para futuras alteraÃ§Ãµes estruturais.

---

**WMA Travel ERP**  
**TransiÃ§Ã£o Fase 1 â†’ Fase 2**  
**17/08/2026**
"@

Set-Content `
    -Path $TransitionFile `
    -Value $TransitionContent `
    -Encoding UTF8

Write-Host "OK - $TransitionFile" `
    -ForegroundColor Green

# =============================================================================
# VALIDACAO DOS ARQUIVOS
# =============================================================================

Write-Host ""
Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host "VALIDACAO DOS DOCUMENTOS DE FECHAMENTO" `
    -ForegroundColor Cyan

Write-Host "============================================================" `
    -ForegroundColor Cyan

$GeneratedFiles = @(
    $FinalCertificationFile
    $TransitionFile
)

$AllValid = $true

foreach ($File in $GeneratedFiles) {

    if (Test-Path $File) {

        $Item = Get-Item $File

        Write-Host ""
        Write-Host "OK: $($Item.Name)" `
            -ForegroundColor Green

        Write-Host "Tamanho: $($Item.Length) bytes"

        $Hash = Get-FileHash `
            -Path $File `
            -Algorithm SHA256

        Write-Host "SHA256: $($Hash.Hash)"
    }
    else {

        Write-Host ""
        Write-Host "ERRO: $File" `
            -ForegroundColor Red

        $AllValid = $false
    }
}

# =============================================================================
# GIT STATUS
# =============================================================================

Write-Host ""
Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host "GIT STATUS" `
    -ForegroundColor Cyan

Write-Host "============================================================" `
    -ForegroundColor Cyan

git status --short

# =============================================================================
# RESULTADO FINAL
# =============================================================================

Write-Host ""
Write-Host "============================================================" `
    -ForegroundColor Cyan

if ($AllValid) {

    Write-Host "DOCUMENTOS DE FECHAMENTO GERADOS" `
        -ForegroundColor Green

    Write-Host "STATUS: OK" `
        -ForegroundColor Green
}
else {

    Write-Host "STATUS: FALHA" `
        -ForegroundColor Red

    exit 1
}

Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host ""
Write-Host "IMPORTANTE:" `
    -ForegroundColor Yellow

Write-Host "Nenhum commit ou push foi realizado." `
    -ForegroundColor Yellow

Write-Host "Revise os documentos antes do fechamento Git." `
    -ForegroundColor Yellow
