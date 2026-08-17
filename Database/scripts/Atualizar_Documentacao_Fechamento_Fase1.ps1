# =============================================================================
# WMA TRAVEL ERP
# ATUALIZACAO DOCUMENTAL - FECHAMENTO DA FASE 1
#
# Arquivos:
#   Docs/README.md
#   Docs/ROADMAP.md
#   Docs/CHANGELOG.md
#
# SEGURANCA:
#   - Cria backup antes das alteracoes
#   - Nao altera banco de dados
#   - Nao executa git add
#   - Nao executa commit
#   - Nao executa push
#   - Evita duplicacao usando marcadores
# =============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = "E:\WMA Travel ERP"
$DocsDir = Join-Path $ProjectRoot "Docs"

$ReadmeFile = Join-Path $DocsDir "README.md"
$RoadmapFile = Join-Path $DocsDir "ROADMAP.md"
$ChangelogFile = Join-Path $DocsDir "CHANGELOG.md"

$BackupRoot = Join-Path `
    $ProjectRoot `
    "Database\logs\documentation_backup_phase1"

$Date = "17/08/2026"
$IsoDate = "2026-08-17"
$PostgreSQLVersion = "18.4"
$BaselineCommit = "d63800e"

$ReadmeMarker = "<!-- WMA_PHASE_1_CERTIFICATION -->"
$RoadmapMarker = "<!-- WMA_PHASE_1_ROADMAP_CLOSE -->"
$ChangelogMarker = "<!-- WMA_PHASE_1_CHANGELOG_CLOSE -->"

function Write-Section {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    Write-Host ""
    Write-Host "============================================================" `
        -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host "============================================================" `
        -ForegroundColor Cyan
}

function Test-RequiredFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "Arquivo obrigatorio nao encontrado: $Path"
    }

    Write-Host "OK - $Path" -ForegroundColor Green
}

function Add-BlockAfterTitle {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Marker,

        [Parameter(Mandatory = $true)]
        [string]$Block
    )

    $RawContent = Get-Content `
        -Path $Path `
        -Raw `
        -Encoding UTF8

    if ($RawContent.Contains($Marker)) {
        Write-Host `
            "IGNORADO - bloco ja existente em $(Split-Path $Path -Leaf)" `
            -ForegroundColor Yellow

        return
    }

    $Lines = @(
        Get-Content `
            -Path $Path `
            -Encoding UTF8
    )

    $FirstHeadingIndex = -1

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^#\s+') {
            $FirstHeadingIndex = $i
            break
        }
    }

    if ($FirstHeadingIndex -lt 0) {
        throw "Titulo H1 nao encontrado em: $Path"
    }

    $NewContent = @()

    $NewContent += $Lines[0..$FirstHeadingIndex]
    $NewContent += ""
    $NewContent += $Block.TrimEnd()
    $NewContent += ""

    if (($FirstHeadingIndex + 1) -lt $Lines.Count) {
        $NewContent += `
            $Lines[($FirstHeadingIndex + 1)..($Lines.Count - 1)]
    }

    Set-Content `
        -Path $Path `
        -Value $NewContent `
        -Encoding UTF8

    Write-Host `
        "ATUALIZADO - $(Split-Path $Path -Leaf)" `
        -ForegroundColor Green
}

Clear-Host

Write-Section "WMA TRAVEL ERP - FECHAMENTO DOCUMENTAL DA FASE 1"

if (-not (Test-Path $ProjectRoot)) {
    throw "Raiz do projeto nao encontrada: $ProjectRoot"
}

if (-not (Test-Path $DocsDir)) {
    throw "Diretorio Docs nao encontrado: $DocsDir"
}

Set-Location $ProjectRoot

Write-Host ""
Write-Host "=== DOCUMENTOS CORPORATIVOS ===" `
    -ForegroundColor Yellow

Write-Host "README:    $ReadmeFile"
Write-Host "ROADMAP:   $RoadmapFile"
Write-Host "CHANGELOG: $ChangelogFile"

Write-Section "VALIDACAO DOS DOCUMENTOS"

Test-RequiredFile $ReadmeFile
Test-RequiredFile $RoadmapFile
Test-RequiredFile $ChangelogFile

Write-Section "GIT - ESTADO INICIAL"

$GitHead = (git rev-parse --short HEAD).Trim()

if ($LASTEXITCODE -ne 0) {
    throw "Falha ao consultar Git."
}

Write-Host "HEAD atual:           $GitHead"
Write-Host "Baseline certificada: $BaselineCommit"

if ($GitHead -eq $BaselineCommit) {
    Write-Host `
        "OK - HEAD corresponde a baseline certificada." `
        -ForegroundColor Green
}
else {
    Write-Host `
        "ATENCAO - HEAD difere da baseline certificada." `
        -ForegroundColor Yellow
}

Write-Host ""
git status --short

Write-Section "BACKUP DOS DOCUMENTOS"

if (-not (Test-Path $BackupRoot)) {
    New-Item `
        -ItemType Directory `
        -Path $BackupRoot `
        -Force |
        Out-Null
}

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupDir = Join-Path $BackupRoot $Timestamp

New-Item `
    -ItemType Directory `
    -Path $BackupDir `
    -Force |
    Out-Null

Copy-Item `
    -Path $ReadmeFile `
    -Destination (Join-Path $BackupDir "README.md") `
    -Force

Copy-Item `
    -Path $RoadmapFile `
    -Destination (Join-Path $BackupDir "ROADMAP.md") `
    -Force

Copy-Item `
    -Path $ChangelogFile `
    -Destination (Join-Path $BackupDir "CHANGELOG.md") `
    -Force

Write-Host "OK - Backup criado:" -ForegroundColor Green
Write-Host $BackupDir

Write-Section "ATUALIZACAO DO README"

$ReadmeBlock = @"
$ReadmeMarker

## Marco de Certificação da Fase 1

**Status:** CONCLUÍDA E CERTIFICADA  
**Data da certificação:** $Date  
**PostgreSQL:** $PostgreSQLVersion  
**Baseline certificada:** ``$BaselineCommit``  
**Próxima fase:** Fase 2 — Backend e API

A Fase 1 do WMA Travel ERP foi formalmente concluída após a validação da
fundação do banco de dados, incluindo auditoria estrutural, reconstrução
independente, validação de reprodutibilidade e comparação da baseline com o
ambiente reconstruído.

A baseline PostgreSQL certificada passa a constituir a referência histórica
para a evolução do projeto.

Alterações estruturais posteriores deverão ser introduzidas através de
migrations versionadas, documentadas e validadas.

Documentos de referência:

- ``Database/certification/FASE_1_CERTIFICACAO_FINAL.md``
- ``Docs/PHASE_1_TO_PHASE_2_TRANSITION.md``
"@

Add-BlockAfterTitle `
    -Path $ReadmeFile `
    -Marker $ReadmeMarker `
    -Block $ReadmeBlock

Write-Section "ATUALIZACAO DO ROADMAP"

$RoadmapBlock = @"
$RoadmapMarker

## Fase 1 — Fundação e Banco de Dados

**Status:** CONCLUÍDA E CERTIFICADA  
**Conclusão:** $Date  
**PostgreSQL:** $PostgreSQLVersion  
**Baseline:** ``$BaselineCommit``

### Entregas certificadas

- modelagem corporativa do banco;
- padronização SQL;
- schemas e tabelas;
- constraints;
- índices;
- sequences e identity;
- triggers;
- views;
- functions e procedures;
- auditoria estrutural;
- catálogo técnico;
- dicionário de dados;
- baseline SQL;
- reconstrução independente;
- validação de banco limpo;
- validação de reprodutibilidade;
- comparação baseline × rebuild;
- hashes normalizados;
- certificação final.

### Gate de saída

- Baseline certificada: APROVADA
- Estrutura auditada: APROVADA
- Rebuild: APROVADO
- Reprodutibilidade: APROVADA
- Divergências estruturais críticas: 0
- Transição para Fase 2: AUTORIZADA

## Fase 2 — Backend e API

**Status:** PRÓXIMA FASE

A Fase 2 utilizará a baseline certificada como fundação para o desenvolvimento
das camadas de aplicação e integração.
"@

Add-BlockAfterTitle `
    -Path $RoadmapFile `
    -Marker $RoadmapMarker `
    -Block $RoadmapBlock

Write-Section "ATUALIZACAO DO CHANGELOG"

$ChangelogBlock = @"
$ChangelogMarker

## [0.2.0] - $IsoDate

### Added

- certificação definitiva da baseline PostgreSQL;
- certificações das ETAPAS 10.12.3 a 10.12.6;
- certificação global da Fase 1;
- documento formal de transição da Fase 1 para a Fase 2;
- validação de reconstrução independente;
- comparação estrutural baseline × rebuild;
- validação de reprodutibilidade;
- hashes normalizados para certificação.

### Changed

- status da Fase 1 para concluída e certificada;
- referência técnica do banco para PostgreSQL $PostgreSQLVersion;
- governança de alterações estruturais para migrations versionadas;
- preparação formal para início da Fase 2.

### Verified

- 8 schemas;
- 209 tabelas;
- 38 views;
- 206 sequences;
- 1176 constraints;
- 357 índices;
- 64 functions;
- 11 procedures;
- 138 triggers;
- 0 divergências estruturais críticas impeditivas.

### Project

- Fase 1 formalmente encerrada.
- Baseline certificada: ``$BaselineCommit``.
- Transição para Fase 2 autorizada.
"@

Add-BlockAfterTitle `
    -Path $ChangelogFile `
    -Marker $ChangelogMarker `
    -Block $ChangelogBlock

Write-Section "VALIDACAO DOS MARCADORES"

$Checks = @(
    @{
        File = $ReadmeFile
        Marker = $ReadmeMarker
    },
    @{
        File = $RoadmapFile
        Marker = $RoadmapMarker
    },
    @{
        File = $ChangelogFile
        Marker = $ChangelogMarker
    }
)

$AllValid = $true

foreach ($Check in $Checks) {
    $Content = Get-Content `
        -Path $Check.File `
        -Raw `
        -Encoding UTF8

    if ($Content.Contains($Check.Marker)) {
        Write-Host `
            "OK - $(Split-Path $Check.File -Leaf)" `
            -ForegroundColor Green
    }
    else {
        Write-Host `
            "ERRO - marcador ausente: $(Split-Path $Check.File -Leaf)" `
            -ForegroundColor Red

        $AllValid = $false
    }
}

Write-Section "HASHES SHA256"

$UpdatedDocuments = @(
    $ReadmeFile,
    $RoadmapFile,
    $ChangelogFile
)

foreach ($File in $UpdatedDocuments) {
    $Hash = Get-FileHash `
        -Path $File `
        -Algorithm SHA256

    Write-Host ""
    Write-Host "$(Split-Path $File -Leaf)"
    Write-Host "SHA256: $($Hash.Hash)"
}

Write-Section "GIT DIFF --STAT"

git diff --stat

Write-Host ""
Write-Host "=== ARQUIVOS ALTERADOS ===" `
    -ForegroundColor Yellow

git diff --name-only

Write-Section "GIT STATUS FINAL"

git status --short

Write-Section "RESULTADO"

if ($AllValid) {
    Write-Host `
        "DOCUMENTACAO CORPORATIVA ATUALIZADA" `
        -ForegroundColor Green

    Write-Host "STATUS: OK" -ForegroundColor Green
}
else {
    Write-Host `
        "STATUS: FALHA NA VALIDACAO" `
        -ForegroundColor Red

    Write-Host ""
    Write-Host "Backup disponivel em:"
    Write-Host $BackupDir

    exit 1
}

Write-Host ""
Write-Host "Backup:" -ForegroundColor Yellow
Write-Host $BackupDir

Write-Host ""
Write-Host "Nenhum git add, commit ou push foi realizado." `
    -ForegroundColor Yellow

Write-Host `
    "Revise o git diff antes do fechamento definitivo." `
    -ForegroundColor Yellow
