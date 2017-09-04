package dumpster.macros;

#if macro
import haxe.macro.Expr;
import haxe.macro.Type;
using tink.MacroApi;

class PatchBuilder {
  static function build() {
    var params = FieldsBuilder.getParams('dumpster.types.Patch');

    var ret = tink.macro.BuildCache.getType('dumpster.types.Patch', params.fields, function (ctx) {
      var name = ctx.name;

      var ret = macro class $name<O> {};

      ret.kind = TDStructure;

      switch ctx.type.reduce() {
        case TAnonymous(_.get().fields => fields):
          for (f in fields) {
            var ct = f.type.toComplex();
            ret.fields.push({
              name: f.name,
              pos: f.pos,
              meta: [{ name: ':optional', pos: f.pos, params: [] }],
              kind: FVar(macro : dumpster.AST.ExprOf<O, $ct>),
            });
          }
        case v: ctx.pos.error('Patch can only operate on anonymous type, but got $v');
      }
      return ret;
    });
    
    return TPath(ret.getID(false).asTypePath([TPType(params.owner.toComplex())]));
  }
}
#end