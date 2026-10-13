# Escopo da edição pública

## Publicado

Cinco plugins próprios, seis utilitários, exemplos de terminais/tmux, teclado, atalhos/layout e configuração de barra com componentes incluídos ou nativos. Namespace `samiriasbeck.*` preservado como autoria e identificador técnico público, não como conta local ou endereço.

## Deliberadamente fora deste pacote

| Categoria | Motivo / alternativa |
|---|---|
| Credenciais, contas, SSH/VNC e rede privada | Não pertencem a um pacote público; configure seu próprio ambiente |
| Serviços de agentes, pareamento, Home Assistant, dashboards, briefing e backups | Dependem de infraestrutura privada; não são instalados por esta edição |
| Themes, logos, wallpapers e screensavers de marcas | Edição neutra; nenhum asset corporativo redistribuído |
| Plugins de outros autores e binários capturados | Instale pela fonte original e respeite a licença; nenhum código/vendor copiado indiscriminadamente |
| Estado de aplicativos, histórico de navegação, sessões e atalhos pessoais | Dados locais excluídos; exemplos novos sem contas |
| Boot, discos, dual boot, drivers e serviços de sistema | Específicos da máquina; não fazem parte de customização portátil |
| Monitores, orientação automática e captura de teclado entre máquinas | Exigem validação no hardware; sem preset universal |
| Histórico Git dos snapshots privados | Repositório público iniciado do zero |

O prefixo `private_` do chezmoi indica modo de permissão, não prova que o conteúdo seja secreto. Nesta edição ele foi tratado conservadoramente: fontes assim marcadas não foram exportadas automaticamente. O conjunto público é uma seleção documentada, não a alegação de que todas as customizações privadas já foram convertidas.

Arquivos de backup destinados à migração de um computador não são instaladores públicos: o payload de migração foi examinado como fonte de inventário, mas não foi incluído.
