# Evidências e logs de execução

Este diretório separa evidências consolidadas versionadas de logs locais detalhados.

## Arquivos versionados

Os arquivos CSV de resumo e divergências fazem parte da certificação da baseline e devem ser preservados:

- `10.12.2.3_V5_hashes_normalizados_resumo.csv`;
- `10.12.2.3_V5_hashes_normalizados_divergencias.csv`.

## Arquivos locais ignorados

Arquivos `*.log` e o diretório local `F1_FIN/` contêm saídas detalhadas de execução. Eles permanecem ignorados
pelo Git para evitar crescimento desnecessário do repositório. Alguns podem ser citados por certificações
históricas e, por isso, não devem ser apagados automaticamente.

Novas certificações devem registrar resultados consolidados em Markdown ou CSV, junto com hashes dos scripts,
em vez de versionar logs extensos do terminal.
