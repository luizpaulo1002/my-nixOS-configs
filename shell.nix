{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "cpp23-dev-env";

  # Ferramentas de compilação e utilitários
  nativeBuildInputs = with pkgs; [
    # Compilador Clang (suporte C++23)
    llvmPackages_latest.clang
    llvmPackages_latest.bintools
    llvmPackages_latest.lldb

    # Build systems
    cmake
    ninja
    pkg-config
    gnumake

    # Análise e Debug
    cppcheck
    valgrind
  ];

  # Bibliotecas
  buildInputs = with pkgs; [
    boost
    SDL2
    glfw
  ];

  shellHook = ''
    echo "================================================"
    echo "Ambiente de Desenvolvimento C++23 Ativado"
    echo "   Compilador: Clang $(clang --version | head -n1 | awk '{print $3}')"
    echo "================================================"

    # Define Clang como compilador padrão
    export CC="clang"
    export CXX="clang++"

    # --- CORREÇÃO DOS INCLUDES ---
    # O Nix geralmente configura isso sozinho através do 'wrapper' do clang.
    # Mas se precisar forçar os headers do GCC (libstdc++), o caminho correto é este:
    export CPLUS_INCLUDE_PATH="${pkgs.gcc.cc}/include/c++/${pkgs.gcc.version}:${pkgs.gcc.cc}/include/c++/${pkgs.gcc.version}/x86_64-unknown-linux-gnu"
  '';
}
