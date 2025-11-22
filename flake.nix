{
  description = "My Language - A family of 4 programming language dialects";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" ];
        };

        # Build inputs for the project
        buildInputs = with pkgs; [
          rustToolchain
          pkg-config
          openssl
        ] ++ lib.optionals stdenv.isDarwin [
          darwin.apple_sdk.frameworks.Security
          darwin.apple_sdk.frameworks.SystemConfiguration
        ];

        nativeBuildInputs = with pkgs; [
          rustToolchain
          pkg-config
        ];

        # My Language compiler package
        my-lang = pkgs.rustPlatform.buildRustPackage {
          pname = "my-lang";
          version = "0.1.0";

          src = ./.;

          cargoLock = {
            lockFile = ./Cargo.lock;
          };

          inherit buildInputs nativeBuildInputs;

          # RSR compliance: offline-first build
          doCheck = true;

          meta = with pkgs.lib; {
            description = "Compiler for My Language (Me, Solo, Duet, Ensemble)";
            homepage = "https://github.com/Hyperpolymath/me-dialect-playground";
            license = with licenses; [ mit ];  # MIT + Palimpsest v0.8
            maintainers = [];
            platforms = platforms.all;
          };
        };

      in
      {
        # Packages
        packages = {
          default = my-lang;
          my-lang = my-lang;
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          inherit buildInputs;

          nativeBuildInputs = nativeBuildInputs ++ (with pkgs; [
            # Build tools
            just
            cargo-watch
            cargo-edit
            cargo-outdated
            cargo-audit
            cargo-tarpaulin  # Code coverage
            cargo-criterion  # Benchmarking

            # Development tools
            git
            gh  # GitHub CLI

            # Documentation
            mdbook

            # Optional: for LSP development
            nodePackages.vscode-langservers-extracted
          ]);

          # Environment variables
          RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
          RUST_BACKTRACE = "1";

          # RSR compliance metadata
          RSR_LEVEL = "bronze";
          RSR_COMPLIANCE = "true";
          OFFLINE_FIRST = "true";

          shellHook = ''
            echo "🚀 My Language Development Environment"
            echo ""
            echo "Rust version: $(rustc --version)"
            echo "Cargo version: $(cargo --version)"
            echo ""
            echo "Available commands:"
            echo "  just build       - Build the compiler"
            echo "  just test        - Run tests"
            echo "  just check       - Run all checks"
            echo "  just rsr-check   - Verify RSR compliance"
            echo "  just --list      - Show all recipes"
            echo ""
            echo "RSR Compliance: Bronze Level ✓"
            echo ""

            # Verify project structure
            if [ ! -f "Cargo.toml" ]; then
              echo "⚠️  Warning: Cargo.toml not found"
            fi

            # Check for required RSR files
            local missing=0
            for file in LICENSE.txt SECURITY.md CODE_OF_CONDUCT.md MAINTAINERS.md CHANGELOG.md; do
              if [ ! -f "$file" ]; then
                echo "⚠️  Missing RSR file: $file"
                missing=1
              fi
            done

            if [ $missing -eq 0 ]; then
              echo "✓ All RSR compliance files present"
            fi

            echo ""
          '';
        };

        # Apps
        apps = {
          default = {
            type = "app";
            program = "${my-lang}/bin/my-lang";
          };

          my-lang = {
            type = "app";
            program = "${my-lang}/bin/my-lang";
          };
        };

        # Checks (run with `nix flake check`)
        checks = {
          # Build check
          build = my-lang;

          # Test check
          test = pkgs.runCommand "my-lang-tests" {
            nativeBuildInputs = [ rustToolchain ];
            src = ./.;
          } ''
            cargo test --all-features --workspace
            touch $out
          '';

          # Format check
          format = pkgs.runCommand "my-lang-format-check" {
            nativeBuildInputs = [ rustToolchain ];
            src = ./.;
          } ''
            cargo fmt --all -- --check
            touch $out
          '';

          # Lint check
          lint = pkgs.runCommand "my-lang-lint-check" {
            nativeBuildInputs = [ rustToolchain ];
            src = ./.;
          } ''
            cargo clippy --all-features --workspace -- -D warnings
            touch $out
          '';

          # RSR compliance check
          rsr = pkgs.runCommand "my-lang-rsr-check" {
            src = ./.;
          } ''
            # Check required files
            test -f "$src/LICENSE.txt" || (echo "Missing LICENSE.txt" && exit 1)
            test -f "$src/SECURITY.md" || (echo "Missing SECURITY.md" && exit 1)
            test -f "$src/CODE_OF_CONDUCT.md" || (echo "Missing CODE_OF_CONDUCT.md" && exit 1)
            test -f "$src/MAINTAINERS.md" || (echo "Missing MAINTAINERS.md" && exit 1)
            test -f "$src/CHANGELOG.md" || (echo "Missing CHANGELOG.md" && exit 1)
            test -f "$src/.well-known/security.txt" || (echo "Missing security.txt" && exit 1)
            test -f "$src/.well-known/ai.txt" || (echo "Missing ai.txt" && exit 1)
            test -f "$src/.well-known/humans.txt" || (echo "Missing humans.txt" && exit 1)
            test -f "$src/justfile" || (echo "Missing justfile" && exit 1)

            echo "✓ RSR Bronze Level Compliance Verified"
            touch $out
          '';
        };

        # Formatters
        formatter = pkgs.rustfmt;
      }
    );
}
