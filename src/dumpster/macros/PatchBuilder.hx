package dumpster.macros;

#if macro
import haxe.macro.Type;
using tink.MacroApi;

class PatchBuilder {
  static function build() {
    return tink.macro.BuildCache.getType('dumpster.Patch', function (ctx) {
      var name = ctx.name;

      var ret = macro class $name {};

      ret.kind = TDStructure;

      var doc = ctx.type.toComplex();

      switch ctx.type.reduce() {
        case TAnonymous(_.get().fields => fields):
          for (f in fields) {
            var ct = f.type.toComplex();
            ret.fields.push({
              name: f.name,
              pos: f.pos,
              meta: [{ name: ':optional', pos: f.pos, params: [] }],
              kind: FVar(macro : dumpster.AST.ExprOf<$doc, $ct>),
            });
          }
        default: ctx.pos.error('Patch can only operate on anonymous type');
      }
      return ret;
    });
  }
}
#end