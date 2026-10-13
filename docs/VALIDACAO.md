# Validação — 2026-10-13

## Verificado

- Sintaxe de 5 scripts Bash e 2 arquivos Python (sem execução dos launchers).
- Parse de 6 arquivos JSON e 1 TOML.
- Cinco manifests de plugins: IDs correspondem às pastas e os entry points existem.
- Quatro verificações do resolvedor de nomes: aplicativo conhecido, fallback vazio, classe de webapp e normalização de texto/bidi.
- Gitleaks no diretório público: nenhum vazamento detectado.
- Busca adicional por caminhos pessoais, emails de conta, IPs internos, tailnet e IDs operacionais: nenhuma ocorrência no pacote final.
- Conteúdo privado não é alcançável pelo histórico: repositório novo, sem importação de commits anteriores.

## Não verificado nesta edição

- Execução gráfica de QML/Quickshell e carregamento do Shell em Linux.
- Compatibilidade da API Lua do compositor com cada versão do Omarchy.
- Aplicação dos exemplos em monitores, terminais e teclados reais.
- Execução ponta a ponta dos launchers, ditado e teclado virtual.

Os resultados não equivalem a homologação de uma instalação. Use módulos seletivamente e envie a versão do ambiente ao reportar problemas. Não foi criada uma configuração universal de hardware.
