let
  pkgs = import <nixpkgs> {};
in
  pkgs.stdenv.mkDerivation {
    name = "formal-models-2015";
    buildInputs = with pkgs; [ jekyll ];
  }
