let
  pkgs = import <nixpkgs> {};
  pygraphviz = pkgs.python3Packages.buildPythonPackage {
    name = "pygraphviz-1.3.1";
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/source/p/pygraphviz/pygraphviz-1.3.1.tar.gz";
      md5 = "7f690295dfe77edaa9e552d09d98d279";
    };
    buildInputs = [ pkgs.graphviz-nox pkgs.pkgconfig ];
    doCheck = false;
  };
in pkgs.stdenv.mkDerivation {
  name = "formal-models-env";

  buildInputs = with pkgs; [ pandoc pygraphviz pdf2svg graphviz-nox];
}
