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

$HashTableLines += "| Certificação | SHA-256 |"
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
# WMA Travel ERP — Certificação Final da Fase 1

## Fundação, Modelagem e Certificação do Banco de Dados

**Data da certificação:** $CertificationDate
**Projeto:** WMA Travel ERP
**Fase:** 1 — Fundação e Banco de Dados
**SGBD:** PostgreSQL $PostgreSQLVersion
**Banco de referência:** ``$ReferenceDatabase``
**Banco de reconstrução:** ``$RebuildDatabase``
**Commit baseline certificado:** ``$BaselineCommit``
**Status:** APROVADA

---

## 1. Objetivo

Este documento formaliza o encerramento técnico da Fase 1 do WMA Travel ERP e
consolida as evidências de modelagem, padronização, auditoria, reconstrução,
reprodutibilidade e certificação da baseline PostgreSQL.

## 2. Escopo certificado

A Fase 1 contemplou a construção e validação da fundação de dados do sistema,
incluindo:

- modelagem do banco de dados;
- organização dos schemas;
- tabelas e relacionamentos;
- constraints;
- índices;
- sequences e identity;
- triggers;
- views;
- functions;
- procedures;
- padronização de objetos;
- auditoria estrutural;
- catálogo técnico;
- dicionário de dados;
- baseline SQL;
- processo de reconstrução;
- validação de reprodutibilidade;
- comparação baseline × rebuild;
- certificação final.

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

## 4. Certificações consolidadas

As etapas finais foram formalizadas através das seguintes certificações:

- ETAPA 10.12.2 — certificação definitiva da baseline;
- ETAPA 10.12.3 — certificação do processo de instalação;
- ETAPA 10.12.4 — certificação de reprodutibilidade;
- ETAPA 10.12.5 — certificação de reconstrução em banco limpo;
- ETAPA 10.12.6 — certificação baseline × rebuild.

## 5. Integridade das certificações finais

Os documentos das ETAPAS 10.12.3 a 10.12.6 possuem os seguintes hashes
SHA-256:

$HashTable

Os hashes acima permitem verificar a integridade dos documentos utilizados no
fechamento formal da Fase 1.

## 6. Reprodutibilidade

A baseline oficial foi submetida a processo de reconstrução utilizando banco
independente.

Banco de referência:

``$ReferenceDatabase``

Banco reconstruído:

``$RebuildDatabase``

O ambiente reconstruído foi submetido a inventário, normalização, geração de
hashes e comparação estrutural.

## 7. Divergências

Após normalização e validação das evidências produzidas durante a certificação,
não permaneceram divergências estruturais críticas impeditivas para o
encerramento da Fase 1.

**Divergências estruturais críticas: 0**

## 8. Baseline certificada

O commit utilizado como marco da certificação definitiva da ETAPA 10.12.2 é:

``$BaselineCommit``

Esse commit representa a baseline estrutural certificada antes da inclusão dos
documentos administrativos de fechamento global da Fase 1.

O commit contendo este documento será registrado posteriormente pelo processo
normal de versionamento Git.

## 9. Governança após a Fase 1

A partir deste marco, a baseline certificada não deverá receber alterações
estruturais diretas sem rastreabilidade.

Toda evolução persistente do banco de dados deverá utilizar processo
controlado contendo, quando aplicável:

1. migration SQL versionada;
2. identificação da necessidade;
3. validação em ambiente de desenvolvimento;
4. análise de impacto;
5. auditoria;
6. documentação;
7. commit Git;
8. aplicação controlada;
9. validação pós-aplicação.

A baseline certificada da Fase 1 passa a funcionar como referência histórica
do projeto.

## 10. Decisão final

**FASE 1: APROVADA**

**BANCO DE DADOS: CERTIFICADO**

**BASELINE: CERTIFICADA**

**REPRODUTIBILIDADE: APROVADA**

**DIVERGÃŠNCIAS ESTRUTURAIS CRÃTICAS: 0**

**RECONSTRUÃ‡ÃƒO CONTROLADA: APROVADA**

**TRANSIÃ‡ÃƒO PARA FASE 2: AUTORIZADA**

---

## 11. Encerramento

A Fase 1 do WMA Travel ERP encontra-se formalmente encerrada sob os critérios
técnicos estabelecidos pelo projeto.

A evolução do sistema deverá prosseguir através da Fase 2, preservando a
rastreabilidade e a integridade da baseline certificada.

---

**WMA Travel ERP**
**Fase 1 — Concluída e Certificada**
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
# WMA Travel ERP — Transição da Fase 1 para a Fase 2

## Marco Formal de Governança

**Data:** $CertificationDate
**Fase encerrada:** Fase 1 — Fundação e Banco de Dados
**Próxima fase:** Fase 2 — Backend e API
**PostgreSQL:** $PostgreSQLVersion
**Baseline certificada:** ``$BaselineCommit``

---

## 1. Objetivo

Este documento estabelece o marco formal de transição entre a Fase 1 e a
Fase 2 do WMA Travel ERP.

A partir deste ponto, a fundação do banco de dados deixa de ser tratada como
estrutura em construção e passa a ser tratada como baseline certificada.

## 2. Situação da Fase 1

A Fase 1 foi submetida aos processos de:

- modelagem;
- padronização;
- auditoria;
- inventário;
- reconstrução;
- comparação estrutural;
- validação de reprodutibilidade;
- certificação.

**Status da Fase 1: CONCLUÃDA E CERTIFICADA**

## 3. Baseline

A baseline certificada encontra-se associada ao seguinte marco Git:

``$BaselineCommit``

As certificações posteriores ao commit documentam formalmente o encerramento
da fase sem redefinir silenciosamente a baseline técnica já validada.

## 4. Regra de governança

A partir da Fase 2, alterações estruturais persistentes no banco de dados não
devem ser realizadas diretamente sobre a baseline histórica.

As alterações deverão ser introduzidas através de migrations versionadas e
rastreáveis.

## 5. Fluxo de alteração estrutural

O fluxo padrão passa a ser:

````text
Necessidade de alteração
        |
        v
Migration SQL versionada
        |
        v
Validação em desenvolvimento
        |
        v
Análise de impacto
        |
        v
Auditoria
        |
        v
Commit Git
        |
        v
Aplicação controlada
        |
        v
Validação pós-aplicação
````

## 6. Requisitos mínimos de migration

Cada migration deverá possuir, quando aplicável:

- identificação única;
- descrição da alteração;
- justificativa;
- objetos afetados;
- SQL versionado;
- validação prévia;
- análise de dependências;
- estratégia de rollback quando tecnicamente aplicável;
- evidência de execução;
- validação pós-aplicação.

## 7. Proteção da baseline

A baseline certificada deverá permanecer disponível para:

- auditoria;
- reconstrução;
- comparação;
- investigação de regressões;
- recuperação histórica;
- validação de migrations;
- rastreabilidade.

Não deverá haver alteração silenciosa de arquivos utilizados como referência
histórica da certificação.

## 8. Fase 2

A Fase 2 poderá utilizar a baseline certificada como fundação para o
desenvolvimento das camadas superiores do sistema.

O escopo inicial poderá compreender:

- arquitetura do backend;
- configuração da aplicação;
- conexão com PostgreSQL;
- camada de persistência;
- models;
- schemas de aplicação;
- services;
- API;
- autenticação;
- autorização;
- validações;
- testes;
- documentação técnica da API.

## 9. Gate de transição

Os seguintes critérios encontram-se estabelecidos para autorização da Fase 2:

- baseline certificada;
- estrutura auditada;
- reconstrução validada;
- reprodutibilidade aprovada;
- divergências estruturais críticas iguais a zero;
- certificações finais formalizadas;
- governança de migrations definida.

**GATE FASE 1 -> FASE 2: APROVADO**

## 10. Decisão

A Fase 1 encontra-se formalmente encerrada.

O projeto está autorizado a prosseguir para a Fase 2, mantendo a baseline
certificada como referência histórica e utilizando migrations versionadas
para futuras alterações estruturais.

---

**WMA Travel ERP**
**Transição Fase 1 → Fase 2**
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
