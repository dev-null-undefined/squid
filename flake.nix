{
  inputs = {
   nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    #nixpkgs.url = "github:dev-null-undefined/nixpkgs/ncurses-debug";
    devshell.url = "github:numtide/devshell/master";
  };

  outputs = { self, nixpkgs, flake-utils, devshell }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ devshell.overlay ];
        };
        libs = with pkgs; [
          perl openldap db cyrus_sasl expat libxml2 openssl libcap pam systemd pkg-config
          automake autoconf libtool gnum4 ed
        ];
      in rec {
        apps = {
          default = {
            type = "app";
            program = self.packages.${system}.ascii-art + "/bin/ascii-art";
          };
        };

        defaultApp = {
          type = "app";
          program = self.packages.${system}.ascii-art + "/bin/ascii-art";
        };

        devShell = pkgs.devshell.mkShell {
          name = "ascii-art";
          imports = [ "${devshell}/extra/language/c.nix" ];
          packages = libs;

          language.c = {
            libraries = libs;
            includes = libs;
            compiler = pkgs.gcc;
          };
          commands = [
            {
              name = "compile";
              category = "c++";
              help = "Optimized compilation with nearly non logging";
              command = "${pkgs.gnumake}/bin/make fast";
            }
            {
              name = "debug";
              category = "c++";
              help = "Faster compilation with more debug info and logging";
              command = "${pkgs.gnumake}/bin/make fast-debug";
            }
            {
              name = "clean";
              category = "c++";
              help =
                "Clean binaries (Run this between all debug and release versions)";
              command = "${pkgs.gnumake}/bin/make clean";
            }
            {
              name = "run";
              category = "testing";
              command = "${pkgs.gnumake}/bin/make run";
            }
            {
              name = "docs";
              category = "c++";
              help = "Generate documentation";
              command = "${pkgs.gnumake}/bin/make docs";
            }
          ];
          bash = {
            extra = ''
              export CPLUS_INCLUDE_PATH="$C_INCLUDE_PATH"
              export LIBRARY_PATH="$LD_LIBRARY_PATH"
            '';
          };
        };

        defaultPackage = self.packages.${system}.ascii-art;

        packages = {

          ascii-art = let
            inherit system;
            pname = "ascii-art";
            version = "v0.1.1";
          in pkgs.stdenv.mkDerivation {
            pname = pname;
            version = version;
            src = pkgs.fetchFromGitHub {
              owner = "dev-null-undefined";
              repo = pname;
              rev = version;
              sha256 = "sha256-vjJIxG1CzwwAOQLe1CJZbkxW+U2Qwa1fKd8SfxQskW4=";
              fetchSubmodules = true;
            };
            buildInputs = [ pkgs.libjpeg_original pkgs.ncurses pkgs.libpng12 ];
            configurePhase = ''
              ${pkgs.gnumake}/bin/make clean
            '';
            buildPhase = ''
              ${pkgs.gnumake}/bin/make fast
            '';
            installPhase = ''
              mkdir -p $out/bin
              mv bin/${pname} $out/bin/
            '';

            meta = with pkgs.lib; {
              homepage = "";
              description = "";
              longDescription = "";
              platforms = platforms.linux;
            };
          };
          default = self.packages.${system}.ascii-art;
        };
      });
}
