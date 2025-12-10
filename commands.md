```markdown
# Comandos Essenciais do NixOS (para lembrar no futuro)

## 1. Atualização e Aplicação de Configurações (nixos-rebuild)


### Aplicar e mudar imediatamente

```bash
sudo nixos-rebuild switch
```

Reconstrói o sistema e adiciona ao bootloader.

### Testar sem gravar no boot (Segurança)

```bash
sudo nixos-rebuild test
```

Bom para quando mexer em drivers de vídeo ou rede. Se o PC travar, basta reiniciar no botão físico.

### Atualizar os canais (Update do sistema)

```bash
sudo nix-channel --update
sudo nixos-rebuild switch
```

Primeiro baixa as definições mais novas dos pacotes, depois aplica a atualização.

## 2. Limpeza e Manutenção (Garbage Collection)

O NixOS guarda tudo (versões antigas de pacotes, configs antigas). O disco enche rápido se não limpar.

### Limpeza Leve (Remove o que não é usado por nenhum perfil)

```bash
sudo nix-collect-garbage
```

### A "Faxina Pesada" (Remove gerações antigas)

```bash
sudo nix-collect-garbage -d
```

O `-d` significa "delete old". Ele apaga todas as gerações anteriores do bootloader. **Cuidado:** perde a capacidade de fazer rollback (voltar atrás) via menu de boot para versões muito antigas.

### Otimizar o Armazenamento (Deduplicação)

```bash
nix-store --optimise
```

Procura arquivos idênticos no `/nix/store` e cria hard links. Pode demorar um pouco, mas economiza muitos Gigabytes.

## 3. Pacotes "Descartáveis" (nix-shell)

Não suja o `configuration.nix` com coisas que vou usar uma vez só.

### Rodar um programa sem instalar

```bash
nix-shell -p htop
```

Baixa o htop, abre um shell com ele disponível. Quando fechar o terminal, o htop "some" do caminho.

### Rodar múltiplos programas

```bash
nix-shell -p python3 nodejs gcc
```

### Verificar se uma biblioteca existe/funciona

Útil para dev C++:

```bash
nix-shell -p llvmPackages_latest.clang
```

## 4. Diagnóstico e Histórico

### Listar gerações do sistema

```bash
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

Mostra quantas versões do sistema tem salvas e a data de criação.

### Voltar para a versão anterior (Rollback rápido)

```bash
sudo nixos-rebuild switch --rollback
```

Se eu dei um switch e quebrou algo, isso desfaz a última operação imediatamente.

### Procurar pacotes (Via terminal)

```bash
nix-env -qaP | grep nome-do-pacote
```

**Exemplo:** `nix-env -qaP | grep clion`. Mostra o nome exato da variável (ex: `nixos.jetbrains.clion`) para por no config.

**Dica:** O site [search.nixos.org](https://search.nixos.org) costuma ser mais rápido e detalhado que esse comando.
```