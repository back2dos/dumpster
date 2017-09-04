package dumpster.macros;

#if macro
import haxe.macro.Type;
import haxe.macro.Expr;
using tink.MacroApi;

class CollectionBuilder {
  static function build() {
    return tink.macro.BuildCache.getType('dumpster.types.Collection', function (ctx) {
      var name = ctx.name,
          doc = ctx.type.toComplex();

      return macro class $name extends dumpster.types.Collection.CollectionBase<$doc, dumpster.types.Fields<$doc>> {
        
        public function new(name:String, driver) {
          super(cast name, new dumpster.types.Fields<$doc>(), driver);
        }

      };
    });
  }
}
#end