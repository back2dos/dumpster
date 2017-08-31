package dumpster.macros;

#if macro
import haxe.macro.Type;
import haxe.macro.Expr;
using tink.MacroApi;

class CollectionBuilder {
  static function build() {
    return tink.macro.BuildCache.getType('dumpster.Collection', function (ctx) {
      var name = ctx.name,
          doc = ctx.type.toComplex();

      return macro class $name extends dumpster.Collection.CollectionBase<$doc, dumpster.Fields<$doc>> {
        
        public function new(name:String, driver) {
          super(cast name, new dumpster.Fields<$doc>(), driver);
        }

        public function updateById(id:String, run:dumpster.Fields<$doc>->dumpster.Patch<$doc>, ?when):tink.core.Promise<$doc> {
          return this.driver.update(id, name, cast run(fields), when);
        }
      };
    });
  }
}
#end