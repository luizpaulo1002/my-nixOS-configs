{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  # Nome do ambiente (aparece no terminal se configurado)
  name = "cpp23-dev-env";

  # Pacotes que estarão disponíveis dentro deste shell
  nativeBuildInputs = with pkgs; [
    # Compilador Clang mais recente (suporte C++23)
    llvmPackages_latest.clang
    llvmPackages_latest.bintools
    llvmPackages_latest.lldb # Debugger do LLVM

    # Ferramentas de Build
    cmake
    ninja
    pkg-config
    gnumake

    # Ferramentas Extras
    cppcheck
    valgrind
  ];

  # Bibliotecas necessárias
  buildInputs = with pkgs; [
     boost
     sdl2
     glfw
  ];

  # Variáveis de ambiente configuradas AUTOMATICAMENTE ao entrar no shell
  shellHook = ''
    echo "================================================"
    echo "🛠️  Ambiente de Desenvolvimento C++23 Ativado"
    echo "   Compilador: Clang $(clang --version | head -n1 | awk '{print $3}')"
    echo "================================================"

    # Define Clang como compilador padrão
    export CC="${pkgs.llvmPackages_latest.clang}/bin/clang"
    export CXX="${pkgs.llvmPackages_latest.clang}/bin/clang++"

    # Configura Includes para evitar erros de cabeçalho
    export CPLUS_INCLUDE_PATH="${pkgs.llvmPackages_latest.libstdcxx}/include/c++/${pkgs.gcc.version}:${pkgs.llvmPackages_latest.libstdcxx}/include/c++/${pkgs.gcc.version}/x86_64-unknown-linux-gnu"
  '';
}
