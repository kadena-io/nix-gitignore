with (import <nixpkgs> {});
with (import ./. { inherit lib; });

let
  ignores = ''
    0-failing/[\\]

    1-simple/1
    /1-simple/2
    /1-simple/[35^$[]]
    /1-simple/][\]]
    /1-simple/[^a]b

    2-*/[^.]*
    !2-*/1?
    !2-*/30
    !/40
    !50

    3-*/*foo.html
    3-*/**/bar.html

    4-*/\*.html
    4-*/o??ther.html
    4-*/o\?ther.html
    4-*/other.html$
  '';

  source = ./test-tree;

  sourceNixIgnore = gitignoreSource source;

  sourceNixFilterAux = gitignoreFilterSourceAux
    (name: _: (builtins.match ".*/9-?-expected/.*filter$" name) == null)
    "/9-expected/*ignore\n"
    source;

  sourceGit = runCommand "test-tree-git" {} ''
    mkdir -p $out/tmp; cd $out/tmp
    cp -r ${source}/* .; chmod -R u+w .

    cat ${builtins.toFile "nixgitignore-ignores" ignores} > .gitignore
    ${git}/bin/git init
    ${git}/bin/git status --porcelain --ignored | \
      sed -n '/^!! / { s/^...//; p }' | xargs -r rm -r

    rm -r .git
    shopt -s dotglob; cp -r ./* ..
    cd $out; rm -rf tmp
  '';


in {
  debug = gitignoreToPatterns ignores;

  ignores = builtins.toFile "nixgitignore-ignores" ignores;

  nixIgnore    = sourceNixIgnore;
  nixFilterAux = sourceNixFilterAux;
  git          = sourceGit;
}
