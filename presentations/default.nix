let
  pkgs = import <nixpkgs> {};
in pkgs.stdenv.mkDerivation {
  name = "formal-models-env";

  buildInputs = with pkgs; [ pandoc pdf2svg nodejs];
}
