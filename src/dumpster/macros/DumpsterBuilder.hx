package dumpster.macros;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
using tink.MacroApi;

class DumpsterBuilder {
  static function build() {
    return tink.macro.BuildCache.getType('dumpster.Dumpster', function (ctx) {
      var name = ctx.name,
          doc = ctx.type.toComplex(),
          fields =
            switch ctx.type.reduce() {
              case TAnonymous(a): a.get().fields;
              default: ctx.pos.error('Dumpster type parameter should be anonymous structure');
            }
      var init = [];
      var ret = macro class $name {
        
        public function new(driver:dumpster.drivers.Driver) $b{init} 

      };

      for (f in fields) {
        var ct = f.type.toComplex(),
            name = f.name;
        ret.fields.push({
          name: name,
          pos: f.pos,
          access: [APublic],
          kind: FProp('default', 'null', macro : dumpster.types.Collection<$ct>)
        });
        init.push(macro this.$name = new dumpster.types.Collection<$ct>($v{name}, driver));
      }

      return ret;
    });
  }
}
#end