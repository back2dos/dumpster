package dumpster.macros;

#if macro
import tink.macro.BuildCache;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using tink.MacroApi;

class FieldsBuilder {
  static public function getParams(type:String) {
    var params = 
      switch Context.getLocalType() {
        case TInst(_.toString() == type => true, params):    
          params;
        default: throw 'assert';
      }

    var o = params[0];
    var f = switch params {
      case [_]: o;
      case [_, f]: f;
      default: Context.currentPos().error('Invalid number of type parameters');
    }    

    return {
      owner: o,
      fields: f,
    }
  }
  static function build() {

    var params = getParams('dumpster.types.Fields');

    var ret = BuildCache.getType('dumpster.types.Fields', params.fields, function (ctx:BuildContext) {
      
      var name = ctx.name,
          fields = ctx.type.toComplex();

      var _this = macro : dumpster.AST.ExprOf<O, $fields>,
          self = name.asComplexType([TPType(macro : O)]);
      
      var ret = macro class $name<O> {
        public function new(?doc:$_this) 
          this = 
            if (doc == null) dumpster.AST.ExprData.EDoc;
            else doc;

        public function with<R>(f:$self->R)
          return f(cast this);

        public function patch(p:Patch<O, $fields>, ?defaults:$fields):$_this
          return dumpster.AST.ExprData.EUnop(Patch(cast p, defaults), this);

        @:to function toExpr():$_this
          return this;
      }

      ret.meta = [{ name: ':forward', params: [], pos: ctx.pos }];
      ret.kind = TDAbstract(macro : $_this);

      switch ctx.type.reduce() {
        case TAnonymous(_.get().fields => fields):
          for (f in fields) {
            var ct = f.type.toComplex();
            var et = switch f.type.reduce() {
              case TAnonymous(_):
                macro : dumpster.types.Fields<O, $ct>;
              default: 
                macro : dumpster.AST.ExprOf<O, $ct>;
            }
            ret.fields.push({
              name: f.name,
              pos: f.pos,
              access: [APublic],
              kind: FProp("get", "never", et),
            });
            ret.fields.push({
              name: 'get_${f.name}',
              pos: f.pos,
              access: [AInline],
              kind: FFun((macro cast dumpster.AST.ExprData.EField(this, $v{f.name})).func(et)),
            });
          }
        default: 
          ctx.pos.error('Fields must be specified per anonymous type');
      }

      return ret;
    });

    return TPath(ret.getID().asTypePath([TPType(params.owner.toComplex())]));
  }

  
}
#end