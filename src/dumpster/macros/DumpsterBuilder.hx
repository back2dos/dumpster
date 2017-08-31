package dumpster.macros;

#if macro
import haxe.macro.Type;
import haxe.macro.Expr;
using tink.MacroApi;

class DumpsterBuilder {
  static function build() {
    return tink.macro.BuildCache.getType('dumpster.Dumpster', function (ctx) {
      var name = ctx.name,
          doc = ctx.type.toComplex();

      return macro class $name {
        
        public function new(driver) {
          super(cast name, new dumpster.Fields<$doc>(), driver);
        }

      };
    });
  }
}
#end