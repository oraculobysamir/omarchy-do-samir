# Omarchy do Samir

Customizações de produtividade para Omarchy: **launchers, organização de tarefas, widgets de barra, atalhos e terminais**.

Esta é a edição pública e neutra do setup de Samir. Não é um backup completo, uma distribuição ou um instalador automático. O material foi separado de configurações usadas em notebooks e dispositivos portáteis; componentes ligados a contas, rede, clientes e marcas não foram publicados.

## O que tem aqui

| Componente | Função |
|---|---|
| `iniciar` | Escolhe apps, organiza por mesas e retoma sessões sem abrir duplicatas |
| `mosaico` | Grade de aplicativos para mouse, teclado e toque |
| `tarefas` | Projetos e tarefas em pastas, com contexto Markdown compartilhado entre CLIs |
| `discord-3x` | Organiza três clientes Discord em uma mesa |
| `gpd-osk` | Controle de teclado virtual wvkbd compatível, sem incluir o binário |
| `voxtype-log` | Consulta ditados do serviço Voxtype e copia texto |
| Active window + Window titles | Nome do aplicativo e identificação das janelas |
| Downloads + Screenshots | Arquivos recentes com abrir, copiar e arrastar |
| Lock button | Botão de bloqueio na barra |
| Exemplos | Atalhos Hyprland Lua, teclado internacional/ç, layout, terminais e tmux |

## Compatibilidade

Os widgets usam **Omarchy Shell/Quickshell** (`qs.Commons`, `qs.Ui`) e os exemplos de Hyprland usam a **API Lua** (`hl`/`o`). Não são arquivos para colar em qualquer versão do Hyprland, Waybar ou configuração INI antiga. Confirme essas APIs na sua versão do Omarchy antes de usar.

Nesta edição foi feita validação estática, não um teste gráfico em Linux. Não há promessa de compatibilidade com todas as versões, monitores ou dispositivos. O projeto específico de Steam Deck continua separado: [oraculo-steamdeck-omarchy](https://github.com/oraculobysamir/oraculo-steamdeck-omarchy).

## Dependências por módulo

- **Widgets:** Omarchy Shell com API de plugins, Quickshell/Qt Quick, Python 3, `hyprctl`; downloads/capturas também usam GNU `find`, `wl-copy`, `xdg-open`, `uwsm-app` e Nautilus.
- **iniciar:** Bash 4+, GNU coreutils, `jq`, `gum`, Python 3, Hyprland Lua, utilitários de lançamento do Omarchy; `mise` apenas para CLIs gerenciadas por ele. Catálogo público mínimo, sem contas predefinidas.
- **mosaico:** Python 3, PyGObject, GTK 4, libadwaita e Omarchy. Executa comandos do catálogo e dos arquivos `.desktop` locais: adicione apenas entradas confiáveis.
- **tarefas:** Bash 4+, GNU coreutils, `gum`, Python 3 e as CLIs que você instalar. Opções de retomada dependem da versão de cada CLI.
- **discord-3x:** Bash 4+, `jq`, Hyprland Lua, Discord nativo, Chrome e Firefox. Configure as duas entradas de exemplo e crie o perfil Firefox `discord-public` antes de usar. Cada cliente exige seu próprio login.
- **gpd-osk:** build compatível de wvkbd-deck/deck-ux/deskintl, instalado separadamente; aceita `STEAMDECK_OSK_BIN`. As opções do wrapper não são universais para todo wvkbd.
- **voxtype-log:** serviço de usuário `voxtype.service`, systemd/journalctl, GNU awk e `wl-copy`. Não inclui modelo de transcrição, áudio nem configuração de serviço.

## Instalação seletiva

1. Clone este repositório e leia os arquivos que pretende usar.
2. Faça backup dos arquivos de destino. **Não substitua sua pasta `.config` inteira.**
3. Copie somente os módulos escolhidos. Não há `curl | sh`, serviço habilitado ou alteração de sistema automática.

Exemplo para instalar os dois launchers, sem sobrescrever arquivos existentes:

```bash
mkdir -p "$HOME/.local/bin"
cp -n bin/iniciar bin/mosaico "$HOME/.local/bin/"
chmod u+x "$HOME/.local/bin/iniciar" "$HOME/.local/bin/mosaico"
```

Mantenha `~/.local/bin` no PATH. Rode `iniciar --help` para consultar as opções. O catálogo de exemplo é criado na primeira execução caso ainda não exista; edite-o para seus apps.

Para os widgets, copie as pastas desejadas de `plugins/` para `~/.config/omarchy/plugins/`. **Active window depende também de Window titles**, onde está `resolve-apps.py`. Mescle os IDs de `examples/shell.json` no seu próprio `~/.config/omarchy/shell.json`; não substitua seu arquivo inteiro. O botão de bloqueio é opcional: adicione `{"id":"samiriasbeck.lock-button"}` à seção desejada da barra. Recarregue o Shell pela opção suportada na sua versão.

Os arquivos de `examples/hypr/` são trechos a mesclar nos overrides existentes. Não incluem monitor, autostart ou bootstrap. Confira colisões de atalhos e só habilite os que tenham dependências instaladas. O layout `scrolling` também depende da sua versão.

Os exemplos de terminal importam o tema ativo do Omarchy. `examples/XCompose` contém somente a correção de cedilha, e pressupõe o arquivo padrão `/usr/share/omarchy/default/xcompose`. A locale `pt_BR.UTF-8` precisa existir.

## Dados locais e limites

- `iniciar` guarda seleção/sessão em `~/.config/iniciar/` e log em `~/.local/state/iniciar/`. Ao salvar uma sessão configurada com Discord web, pode ler o histórico local do navegador para lembrar a URL do canal. Não envia esses dados; não publique esses arquivos de estado.
- `mosaico` guarda a grade em `~/.config/mosaico/apps.json`.
- `tarefas` cria conteúdo em `~/Projetos` (ou `TAREFAS_DIR`), incluindo links `AGENTS.md`, `CLAUDE.md` e `GEMINI.md` para o contexto da tarefa. Nenhuma CLI é instalada pelo script.
- Widgets consultam arquivos e títulos locais. Downloads assume imagem PNG ao copiar imagem; para outros formatos prefira arrastar o arquivo. Nomes de arquivo com tab/newline não são suportados pelo formato de listagem.
- `voxtype-log` mostra conteúdo de ditados; o modo ao vivo atualiza o clipboard. Não use durante compartilhamento de tela se isso expuser conteúdo privado.

## Desinstalar / voltar atrás

Restaure os arquivos de configuração a partir do seu backup e retire somente os scripts/pastas de plugins que adicionou. Remova os respectivos IDs da barra. Seus dados de tarefas e sessões permanecem locais e não devem ser apagados para desinstalar os launchers.

Veja [escopo e exclusões](docs/ESCOPO.md), [validação](docs/VALIDACAO.md), [contribuição](CONTRIBUTING.md) e [segurança](SECURITY.md).
