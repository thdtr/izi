# IZI

Plugin do [Claude Code](https://code.claude.com/docs/en/overview) para
quem desenvolve sozinho. Você decide o que construir e aprova as etapas
importantes. O Claude escreve o código e os testes, faz os commits e abre
o PR.

Os padrões já vêm prontos para TypeScript (Node.js ou Bun, normalmente
com Next.js). Se o projeto for em Go, Python ou outra linguagem, o
`/izi:kickoff` troca os comandos pelos do seu projeto.

## Antes de instalar

| Ferramenta | Para que serve aqui |
|---|---|
| [Claude Code](https://code.claude.com/docs/en/quickstart), versão atual | É onde o IZI roda |
| [git](https://git-scm.com/) | Branches e commits |
| [jq](https://jqlang.org/) | Os hooks do IZI leem o JSON que o Claude Code manda para eles. Sem ele, a formatação, o quick gate e a busca por segredos são pulados com um aviso |
| [GitHub CLI (`gh`)](https://cli.github.com/) | Abrir PR e acompanhar o CI. Depois de instalar, rode `gh auth login` e [`gh auth setup-git`](https://cli.github.com/manual/gh_auth_setup-git) |
| [bubblewrap](https://github.com/containers/bubblewrap) e [socat](http://www.dest-unreach.org/socat/) | Só no Linux. O [sandbox do Claude Code](https://code.claude.com/docs/en/sandboxing) precisa deles |
| [gitleaks](https://github.com/gitleaks/gitleaks) (opcional) | Procura senhas e chaves antes de cada commit. Sem ele, essa checagem só roda no CI |

No Windows, veja [Windows e o app desktop](#windows-e-o-app-desktop).

## Instalação

Na sua máquina, uma vez só:

```bash
claude plugin marketplace add thdtr/izi
claude plugin install izi@izi
```

No app desktop, use o **+** ao lado da caixa de mensagem e depois **Add
plugins**, numa sessão local. Se o `izi` não aparecer, rode os dois
comandos acima uma vez num terminal: o terminal e o app desktop usam as
mesmas configurações de plugins.

Em cada projeto, novo ou já em andamento, abra o Claude na pasta dele e
rode:

```text
/izi:kickoff
```

O kickoff lê o que já existe no projeto e só pergunta o que falta. Antes
de criar qualquer arquivo, ele mostra a lista do que vai fazer e espera o
seu ok. No fim, avisa se vale instalar o
[plugin de LSP](https://code.claude.com/docs/en/plugins/code-intelligence)
da sua linguagem e rodar `/run-skill-generator`, que ensina o Claude a
abrir o seu app para conferir o resultado.

Vai entrar num projeto que já usa o IZI? O `.claude/settings.json` dele
liga o plugin, mas não baixa. Adicione o marketplace e rode
`claude plugin install izi@izi --scope project` uma vez.

## Como funciona

```text
/izi:kickoff            1x por projeto: configura tudo e monta o roadmap   (Opus)
/izi:spec "feature"  ✋ entrevista você e escreve docs/specs/<slug>.md;    (Opus)
                        quem vai construir lê a spec e aponta o que falta
/clear
/izi:build <slug>       fatia por fatia: teste, código e commit;           (Sonnet)
                        no fim, uma revisão independente
/izi:ship [prod]     ✋ abre o PR e acompanha o CI; o merge fica com você
```

O ✋ marca onde o Claude para e espera por você: na aprovação da spec e
no merge do PR. No resto ele segue sozinho, e você revisa tudo no PR.

O `/clear` entre a spec e o build limpa a conversa. Assim o build começa
só com a spec, sem arrastar a entrevista inteira junto.

## Qual comando usar

| Situação | Use |
|---|---|
| Feature que envolve decisão sobre dados, permissão ou tela | `/izi:spec`, depois `/izi:build` e `/izi:ship` |
| Mudança pequena que mexe em mais de um arquivo | [Plan mode](https://code.claude.com/docs/en/permission-modes) (`Shift+Tab`, ou o seletor de modo no app desktop) e peça direto |
| Bug, teste quebrado ou ajuste pontual | `/izi:fix "o que está acontecendo"` |
| Mudança trivial, como um texto ou erro de digitação | Peça direto |
| Refactor mecânico em vários arquivos | [`/batch`](https://code.claude.com/docs/en/commands) |
| Limpar o código que mudou | [`/simplify`](https://code.claude.com/docs/en/commands) |
| Duas features ao mesmo tempo | [`claude -w <nome>`](https://code.claude.com/docs/en/worktrees) |
| Implementar as fatias sem ficar olhando | [`/goal`](https://code.claude.com/docs/en/goal) `todas as fatias de docs/specs/<slug>.md marcadas e o gate completo sai com 0` |

## Arquivos que o kickoff cria

```text
AGENTS.md                 fatos do projeto que o Claude lê em toda sessão
CLAUDE.md                 aponta para o AGENTS.md
.claude/settings.json     comandos de checagem, permissões e sandbox
.claude/agents/Explore.md busca no código com um modelo mais barato
.claude/rules/            regras de UI e de testes
docs/PROJECT.md           produto, decisões de arquitetura e roadmap
docs/DESIGN.md            cores, tipografia e padrões visuais (opcional)
docs/specs/<slug>.md      uma spec por feature, escrita pelo /izi:spec
.dependency-cruiser.cjs   regras de arquitetura que o lint confere (TS)
.github/workflows/ci.yml  lint, typecheck, testes, build e busca de segredos
```

As regras de arquitetura usam o
[dependency-cruiser](https://github.com/sverweij/dependency-cruiser), e o
CI roda no [GitHub Actions](https://docs.github.com/en/actions).

Quer deixar uma anotação sua no `AGENTS.md`? Escreva entre `<!--` e
`-->`. O Claude não vê esse trecho.

## O que acontece sem você pedir

| Quando | O quê |
|---|---|
| Depois de cada edição | O arquivo é formatado |
| Antes de cada commit | Tipos, lint e os testes dos arquivos alterados são checados, e o gitleaks procura senhas e chaves. Se algo falhar, o commit é bloqueado e o Claude corrige |
| No fim de cada resposta que deixou código sem commit | A mesma checagem de tipos, lint e testes. Se algo falhar, o Claude corrige antes de parar |
| Em cada PR | O CI roda tudo de novo |

Se o Claude terminar a resposta com uma pergunta para você, a checagem
não força ele a continuar.

Os comandos ficam no bloco `env` do `.claude/settings.json`, em
`IZI_FORMAT` e `IZI_CHECK`. Em TypeScript, o padrão usa
[TypeScript](https://www.typescriptlang.org/),
[Prettier](https://prettier.io/), [ESLint](https://eslint.org/),
[Vitest](https://vitest.dev/) e [pnpm](https://pnpm.io/). Se o seu
projeto usa outras ferramentas, o kickoff ajusta.

## Modelos

| Etapa | Modelo |
|---|---|
| kickoff e spec | Opus |
| build, fix e ship | Sonnet |
| Leitura da spec por quem vai construir | Sonnet |
| Revisão do código contra a spec | Opus |
| Busca no código | Haiku |

O Opus entra onde tem decisão de arquitetura e de escopo. O resto roda no
Sonnet, que sai mais barato. A revisão de bugs no fim do build usa o
[`/code-review`](https://code.claude.com/docs/en/code-review-local) do
próprio Claude Code. Fora dos comandos do IZI, vale o modelo que cada
pessoa escolheu no `/model`.

## Sandbox

O kickoff liga o
[sandbox do Claude Code](https://code.claude.com/docs/en/sandboxing). Com
ele, os comandos que o Claude roda ficam isolados do resto da máquina e
não pedem permissão a cada passo. Por causa disso, algumas coisas mudam:

- Deixe no `.env` local só credenciais de desenvolvimento e de teste. O
  sandbox não consegue diferenciar o Claude lendo o arquivo do seu build
  lendo o arquivo, então a leitura fica liberada. Segredo de produção fica
  no provedor de hospedagem. A pasta `secrets/` continua bloqueada.
- `git push`, `git pull` e `gh pr` rodam fora do sandbox e pedem a sua
  confirmação.
- Comandos que usam Docker ou acessam um serviço no `localhost`, como
  testes contra um Postgres em container, precisam estar em
  `sandbox.excludedCommands`. O kickoff pergunta sobre isso.
- Erros como `EACCES`, `Read-only file system`, `Network is unreachable`
  ou "host not allowed" vêm do sandbox, não do seu código. O Claude foi
  instruído a dizer qual comando falhou e o que mudar no
  `.claude/settings.json`, sem mexer no código.
- As pastas de cache do gerenciador de pacotes mudam conforme o sistema,
  então ficam no `~/.claude/settings.json` de cada pessoa, em
  `sandbox.filesystem.allowWrite`. O kickoff configura a sua máquina; quem
  entrar depois no projeto adiciona as da própria máquina.
- No Linux, enquanto um comando roda no sandbox, caminhos protegidos que
  não existem (`.bashrc`, `.mcp.json`, `.claude/hooks`...) aparecem como
  arquivos não rastreados. É um
  [bug conhecido](https://github.com/anthropics/claude-code/issues/78419).
  O `.gitignore` do kickoff esconde os da raiz, e o Claude é instruído a
  ignorá-los e a adicionar arquivos ao commit pelo nome.

| Se acontecer | Faça |
|---|---|
| O Claude pede acesso a um domínio novo | Aceite, ou adicione o domínio em `sandbox.network.allowedDomains` |
| `pnpm install` falha com `EACCES` numa pasta de cache | Adicione a pasta em `sandbox.filesystem.allowWrite` no seu `~/.claude/settings.json`. A tabela em `plugins/izi/skills/kickoff/reference/sandbox.md` tem os caminhos de cada sistema |
| O `pnpm` trava sem mostrar erro | A versão em `packageManager` no `package.json` não é a mesma que está instalada. Deixe as duas iguais |
| O `pnpm install` falha num pacote que vem com pasta `.vscode/` | Rode você mesmo, no prompt do Claude: `! pnpm install` |
| O "Yes, don't ask again" não fica salvo | Rode `claude doctor` e apague os arquivos de 0 byte que ele listar |
| Um comando que você excluiu continua rodando no sandbox | Peça para o Claude rodar só esse comando, sem `cd`, pipe ou `&&` |

## Windows e o app desktop

O IZI roda no Windows nativo, no terminal e no app desktop.

- Instale o [Git for Windows](https://git-scm.com/download/win): os hooks
  do IZI rodam no Git Bash dele. Depois, instale o jq com
  `winget install jqlang.jq`.
- Os dois precisam estar no `PATH` das variáveis de ambiente do usuário
  ou do sistema. O app desktop não lê o perfil do PowerShell; depois de
  mudar o `PATH`, feche e abra o app de novo.
- O Windows nativo não tem sandbox, então os comandos pedem permissão com
  mais frequência. O modo Auto corta a maior parte desses pedidos.
- Commits feitos pela ferramenta PowerShell passam pelas mesmas checagens
  do Bash, e as mesmas regras de permissão valem.
- No app desktop, os plugins carregam em sessões locais e SSH, não em
  sessões WSL nem na nuvem. Os comandos `/izi:` funcionam igual; troque
  de modo pelo seletor embaixo da caixa de mensagem em vez do `Shift+Tab`.
- O WSL2 também funciona e tem sandbox, como no Linux. Use-o pelo
  terminal, já que o app desktop não carrega plugins lá. Deixe o
  repositório dentro do WSL (`~/`), não em `/mnt/c`.

## Manutenção

- Para atualizar o IZI, abra o `/plugin`, vá em Marketplaces, escolha
  `izi` e depois Update marketplace. Em marketplaces como este, a
  atualização automática vem desligada; para ligar, escolha **Enable
  auto-update** na mesma tela. Cada pessoa faz isso na própria máquina. O
  que mudou em cada versão está no
  [CHANGELOG.md](CHANGELOG.md). Mais detalhes na
  [documentação de plugins](https://code.claude.com/docs/en/plugins/install).
- Quando sair um modelo novo, rode `/doctor prompt-audit` e apague as
  instruções que o modelo já segue sem precisar. Instrução sobrando só
  atrapalha.
- O `/usage` mostra para onde estão indo os seus tokens.
- O CI roda `pnpm audit` toda semana. Para atualizar as dependências
  automaticamente, ative o
  [Dependabot](https://docs.github.com/en/code-security/dependabot) ou o
  [Renovate](https://docs.renovatebot.com/).

## Como contribuir

```text
.claude-plugin/marketplace.json   marketplace "izi"
plugins/izi/
  skills/      kickoff, spec, build, fix, ship
  agents/      reviewer, spec-check
  hooks/       hooks.json
  scripts/     scripts dos hooks
  evals/       casos que medem o que o plugin acrescenta
tests/hooks.sh                    testes dos scripts dos hooks
```

Para testar uma mudança sem publicar, rode
`claude --plugin-dir ./plugins/izi`. Antes de publicar, rode
`claude plugin validate .`. Mudou um script de hook? Rode
`bash tests/hooks.sh`; o CI também roda em Linux, Windows e macOS.

Os [evals](https://code.claude.com/docs/en/plugin-evals) rodam cada caso
com e sem o plugin e mostram a diferença. Rode depois de mudar uma skill
e quando sair um modelo novo:

```bash
cd plugins/izi
claude plugin eval . --scaffold --allow-tools Edit "Bash(git *)"
```

Cada execução gasta do seu plano. Para testar só um caso, use
`--case <nome>`.

### Como publicar uma versão

As cópias instaladas só se atualizam quando o `version` em
`plugins/izi/.claude-plugin/plugin.json` muda. Um commit no `main` sem
versão nova não chega a ninguém.

1. Suba o `version` seguindo [semver](https://semver.org/lang/pt-BR/):
   patch para correção, minor para comportamento novo, major quando um
   projeto configurado pelo kickoff precisa mudar.
2. Adicione uma seção `## <versão> - <data>` no [CHANGELOG.md](CHANGELOG.md).
3. Rode os evals e o `claude plugin validate .`.
4. Faça o merge no `main`. O CI cria a tag `v<versão>` e, num PR, falha
   se o plugin mudou sem versão nova.

## Licença

[MIT](LICENSE)
