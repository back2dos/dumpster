package dumpster.macros;

using haxe.io.Path;

class Misc {
  macro static public function buildDir() {
    return macro $v{Sys.getCwd().removeTrailingSlashes().withoutDirectory()};
  }
}