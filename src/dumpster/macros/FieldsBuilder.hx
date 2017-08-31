package dumpster.macros;

#if macro
import haxe.macro.Type;
using tink.MacroApi;

class FieldsBuilder {
  static function build() {
    return tink.macro.BuildCache.getType('dumpster.Fields', function (ctx) {
      var name = ctx.name;

      var ret = macro class $name {
        public function new() {}
      };

      var doc = ctx.type.toComplex();

      switch ctx.type.reduce() {
        case TAnonymous(_.get().fields => fields):
          for (f in fields) {
            var ct = f.type.toComplex();
            ret.fields.push({
              name: f.name,
              pos: f.pos,
              access: [APublic],
              kind: FProp("default", "null", macro : dumpster.AST.ExprOf<$doc, $ct>, macro dumpster.AST.ExprData.EField(dumpster.AST.ExprData.EDoc, $v{f.name})),
            });
          }
        default: ctx.pos.error('Fields must be specified per anonymous type');
      }
      return ret;
    });
  }
}
#end