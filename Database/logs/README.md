# Evidências e logs de execução

Este diretório separa evidências consolidadas versionadas de logs locais detalhados.

## Arquivos versionados

Os arquivos CSV de resumo e divergências fazem parte da certificação da baseline e devem ser preservados:

- `10.12.2.3_V5_hashes_normalizados_resumo.csv`;
- `10.12.2.3_V5_hashes_normalizados_divergencias.csv`.

## Arquivos locais ignorados

Arquivos `*.log` permanecem ignorados pelo Git para evitar crescimento desnecessário do repositório. Os logs
locais intermediários F1-FIN foram removidos após a publicação da evidência final consolidada. O arquivo local
`10.12.2.3_V3_restore.log` deve ser preservado enquanto for citado pela certificação histórica 10.12.2.

Novas certificações devem registrar resultados consolidados em Markdown ou CSV, junto com hashes dos scripts,
em vez de versionar logs extensos do terminal.
