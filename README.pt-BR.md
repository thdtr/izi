# IZI

[Read in English](README.md)

O IZI é um plugin para o [Claude Code](https://code.claude.com/docs/en/overview)
que dá a quem programa um jeito curto e repetível de construir software
com o Claude. Você decide o que vai ser feito e aprova os passos que
importam. O Claude escreve o código e os testes, faz os commits e abre o
PR. Continua funcionando quando entra uma segunda pessoa no projeto.

## O que você precisa

| Ferramenta | Para quê |
|---|---|
| [Claude Code](https://code.claude.com/docs/en/quickstart), no terminal ou no app desktop | É onde o IZI roda |
| [git](https://git-scm.com/) e [GitHub CLI](https://cli.github.com/) | Branches, commits e PRs. Rode `gh auth login` uma vez |
| [jq](https://jqlang.org/) | Os hooks usam para ler o que o Claude Code manda para eles |
| [bubblewrap](https://github.com/containers/bubblewrap) e [socat](http://www.dest-unreach.org/socat/), no Linux | O sandbox precisa deles |
| [gitleaks](https://github.com/gitleaks/gitleaks), opcional | Procura senhas e chaves antes de cada commit |

No Windows você também precisa do Git for Windows. Tem uma seção sobre
isso mais abaixo.

## Instalação

Num terminal, uma vez por máquina

```bash
claude plugin marketplace add thdtr/izi
claude plugin install izi@izi
```

No app desktop não precisa de terminal. Abra uma sessão local, digite
`/plugin marketplace add thdtr/izi`, aceite e instale o `izi` pelos
botões que aparecerem.

Depois abra o Claude na pasta do projeto e rode `/izi:kickoff`. Ele lê o
que já existe, pergunta só o que não consegue descobrir sozinho, mostra
tudo o que pretende mudar e espera o seu ok antes de escrever qualquer
coisa. Se o projeto usava outro jeito de trabalhar (regras do Cursor, uma
pasta de planos, instruções de outro agente), ele diz para onde vai cada
coisa e apaga as sobras num commit separado, que dá para desfazer.

Vai entrar num projeto que já usa o IZI? Instale o plugin com
`claude plugin install izi@izi --scope project`, ou escolha o escopo do
projeto no app desktop, e rode `/izi:kickoff`. Ele só configura a sua
máquina.

## O fluxo

```text
/izi:kickoff          uma vez por projeto
/izi:spec "feature"   o Claude te entrevista e escreve docs/specs/<slug>.md, você aprova
/clear
/izi:build <slug>     fatia por fatia, com teste e commit em cada uma, e no fim uma revisão independente
/izi:ship             abre o PR e espera o CI, o merge fica com você
```

O Claude só para e espera por você na aprovação da spec e no merge. O
resto você revisa no PR.

## Qual comando usar

| Situação | Use |
|---|---|
| Uma feature com decisão sobre dados, permissões ou tela | `/izi:spec`, depois `/izi:build` e `/izi:ship` |
| Um bug, um teste quebrado ou um ajuste pontual | `/izi:fix "o que está acontecendo"` |
| Trabalhar a partir de uma issue do GitHub | `/izi:spec #42` ou `/izi:fix #57` |
| Ver o que vem a seguir, no roadmap e nas issues abertas | `/izi:spec` sozinho |
| Uma mudança pequena em poucos arquivos | [Plan mode](https://code.claude.com/docs/en/permission-modes) e peça direto |
| Um erro de digitação ou de texto | Peça direto |

## O que acontece sozinho

Todo arquivo editado é formatado. Antes de cada commit são checados os
tipos, o lint e os testes do que mudou, e o gitleaks procura segredos. Se
algo falha, o commit é bloqueado e o Claude corrige. A mesma checagem
roda quando uma resposta deixa código sem commit, a não ser que ela
termine com uma pergunta para você. O CI roda tudo de novo em cada PR.

Os comandos ficam no `.claude/settings.json`, em `IZI_FORMAT` e
`IZI_CHECK`, e o kickoff preenche de acordo com a sua stack. Num
repositório com várias stacks eles apontam para `scripts/izi-check.sh` e
`scripts/izi-format.sh`, e uma mudança numa stack só checa aquela stack.

O kickoff e a spec rodam no Opus. Build, fix e ship rodam no Sonnet, e a
busca no código roda no Haiku.

## Trabalhando a dois

Quem trabalha sozinho não nota diferença nenhuma. Quando alguém entra, o
roadmap do `docs/PROJECT.md` continua sendo uma lista curta do que vem a
seguir, e um item conta como feito quando a spec dele está com
`Status: shipped`. Ninguém edita a lista, então os PRs não brigam por
ela. Bugs e ideias vão para as issues do GitHub, e o Claude pergunta
antes de abrir uma. Quem roda `/izi:spec #42` ou `/izi:fix #57` fica como
responsável pela issue, e ela fecha quando o PR entra. O merge é sempre
decisão de uma pessoa, e a única regra obrigatória é o CI verde.

## Sandbox

No Linux, no macOS e no WSL2, o kickoff liga o
[sandbox do Claude Code](https://code.claude.com/docs/en/sandboxing), e
os comandos rodam isolados sem pedir permissão a cada passo. Deixe só
credenciais de desenvolvimento no seu `.env` local. `git push` e `gh pr`
rodam fora do sandbox e perguntam antes. Quando um comando falha com
`EACCES`, `Read-only file system` ou um host bloqueado, é o sandbox, e o
Claude diz o que acrescentar na configuração em vez de mexer no seu
código. As pastas de cache do seu gerenciador de pacotes ficam no
`.claude/settings.local.json`, que fica só na sua máquina.

## Windows e o app desktop

O IZI roda direto no Windows, no terminal e no app desktop. Instale o
[Git for Windows](https://git-scm.com/download/win), porque os hooks
rodam no Git Bash dele, e o jq com `winget install jqlang.jq`. Os dois
precisam estar no PATH das variáveis de ambiente do sistema, porque o app
desktop não lê o perfil do PowerShell, e o app precisa ser reaberto
depois que você muda isso. Se o Claude Code não achar o Git Bash, aponte
a `CLAUDE_CODE_GIT_BASH_PATH` para o `bash.exe` dele.

O Windows não tem sandbox, então o Claude pede permissão com mais
frequência, e o modo Auto resolve boa parte disso. Commits feitos pelo
PowerShell passam pelas mesmas checagens do Bash.

O app desktop carrega plugins em sessões locais e SSH, mas não em sessões
WSL nem na nuvem. Se preferir o WSL, use pelo terminal e deixe o
repositório dentro do WSL, não em `/mnt/c`.

## Atualização

Projetos configurados pelo kickoff já vêm com a atualização automática do
IZI ligada, e a versão nova entra na sua próxima sessão. Para atualizar na
mão, abra o `/plugin`, vá em Marketplaces, escolha `izi` e depois Update
marketplace. O que mudou em cada versão está no
[CHANGELOG.md](CHANGELOG.md).

## Como contribuir

Para testar uma mudança sem publicar, use
`claude --plugin-dir ./plugins/izi`. Antes de abrir um PR, rode
`claude plugin validate .`, `bash tests/hooks.sh` e
`bash tests/templates.sh`. O CI roda os testes no Linux, no macOS e no
Windows. Os [evals](https://code.claude.com/docs/en/plugin-evals) comparam
execuções com e sem o plugin e custam dinheiro, então rode os da skill que
você mudou.

```bash
cd plugins/izi
claude plugin eval . --scaffold --allow-tools Edit --case <nome>
```

Uma cópia instalada só muda quando o `version` em
`plugins/izi/.claude-plugin/plugin.json` muda, então toda mudança precisa
de uma versão nova e de uma entrada no CHANGELOG. O CI confere as duas
coisas e cria a tag depois do merge. Para testar uma branch no app
desktop, feche o app, apague `~/.claude/plugins/cache/izi` e instale de
novo.

## Licença

[MIT](LICENSE)
