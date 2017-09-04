package dumpster;

import dumpster.AST;
import haxe.DynamicAccess;
#if js
import js.Lib.eval;
#end
interface QueryEngine {
  function compile<O, T>(e:ExprOf<O, T>):O->T;
}

#if js
class JsEngine implements QueryEngine {
  
  public function new() {}

  public function compile<O, T>(e:ExprOf<O, T>):O->T 
    return eval('(function (arrayGet) { return (function (doc) { return ${js(e)}; }); })')(SimpleEngine.arrayGet);
  
  static public function js(e:Expr)
    return switch (cast e:ExprData<Dynamic, Dynamic>) {
      case EDoc: 'doc';
      case EField(js(_) => obj, field): '$obj.$field';
      case EBinop((_:Binop<Dynamic, Dynamic, Dynamic>) => op, js(_) => a, js(_) => b): 
        switch op {
          case Gte: '($a >= $b)';
          case Lte: '($a <= $b)';
          case Gt: '($a > $b)';
          case Lt: '($a < $b)';
          case Eq: '($a == $b)';
          case Neq: '($a != $b)';
          case Cat: '(($a || "") + ($b || ""))';
          case Add : '($a + $b)';
          case Subtract: '($a - $b)';
          case Multiply: '($a * $b)';
          case Divide: '($a / $b)';
          case Pow: 'Math.pow($a, $b)';
          case And: '($a && $b)';
          case Or: '($a || $b)';
          case BitAnd: '($a && $b)';
          case BitOr: '($a | $b)';
          case BitXor: '($a ^ $b)';
        } 
      case EConst(v): haxe.Json.stringify(v);
      case EIf(js(_) => a, js(_) => b, js(_) => c): '($a ? $b : $c)'; 
      case EIndex(js(_)=> a, js(_) => i): '$a[$i]';
      case EUnop((_:Unop<Dynamic, Dynamic>) => op, js(_) => v): 

        function arrayOp(name:String, ret:String) 
          return '($v).$name(function (item, pos, array) {
            var doc = { item: item, pos: pos, array: array };
            return $ret;
          })';  
        
        switch op {
          case Neg: '-$v';
          case Not: '!$v';
          case BitFlip: '~$v';
          case Patch(fields): 
            var body = [for (name in fields.keys())
              'ret.$name = ${js(fields[name])};'
            ].join('\n');
            '(function (ret) {
              $body
              return ret;
            })(Object.assign({}, $v))';
          case Log: 'Math.log($v)';
          case ArrayFilter(js(_) => cond): 
            arrayOp('filter', cond);
          case ArrayFirst(js(_) => cond):
            arrayOp('find', cond);           
          case ArrayFold(js(_) => init, js(_) => cond):
            '$v.reduce(function (result, item, pos, array) {
              var doc = { result: result, item: item, pos: pos, array: array };
              return $cond;
            }, $init)';          
          case ArrayForAll(js(_) => cond):
            arrayOp('every', cond);
          case ArrayMap(js(_) => nu):
            arrayOp('map', nu);
        }
    }
}
#end

class SimpleEngine implements QueryEngine {
  public function new() {}
  public function compile<O, T>(e:ExprOf<O, T>):O->T {
    return function (doc) return evaluate(doc, e);
  }
  static function evaluate(doc:Dynamic, e:Expr):Dynamic {
    var e:ExprData<Dynamic, Dynamic> = cast e;
    inline function rec(e):Dynamic
      return evaluate(doc, e);

    inline function num(e)
      return switch (rec(e) : Float) {
        case Math.isNaN(_) => true: 0;
        case v: v;
      }

    inline function int(e)
      return Std.int(rec(e));
      
    return switch e {
      case EDoc: doc;
      case EField(rec(_) => obj, name): 
        try Reflect.field(obj, name)
        catch (e:Dynamic) null;
      case EIndex(rec(_) => array, rec(_) => index): 
        try arrayGet(array, index)
        catch (e:Dynamic) null;
      case EConst(v): v;  
      case EIf(cond, cons, alt):
        if (rec(cond)) rec(cons) else rec(alt);
      case EBinop((_:Binop<Dynamic, Dynamic, Dynamic>) => op, a, b):
        switch op {
          case Cat: rec(a) + rec(b);
          case Neq: rec(a) != rec(b);
          case Eq: rec(a) == rec(b);
          case Gte: num(a) >= num(b);
          case Lte: num(a) <= num(b);
          case Gt: num(a) > num(b);
          case Lt: num(a) < num(b);
          case Add: num(a) + num(b);
          case Subtract: num(a) - num(b);
          case Multiply: num(a) * num(b);
          case Divide: num(a) / num(b);
          case Pow: Math.pow(num(a), num(b));

          case And: rec(a) && rec(b);
          case Or: rec(a) || rec(b);
          
          case BitAnd: int(a) & int(b);
          case BitOr: int(a) | int(b);
          case BitXor: int(a) ^ int(b);
        }
      case EUnop((_:Unop<Dynamic, Dynamic>) => op, rec(_) => v):
        switch op {
          case Not: !v;
          case BitFlip: ~v;
          case Neg: -v;
          case Patch(fields):
            if (Reflect.isObject(v)) {
              var ret:DynamicAccess<Any> = cast shallowCopy(v);
              for (f in fields.keys())
                ret[f] = rec(fields[f]);
              ret;
            } 
            else
              null;
          case Log: Math.log(v);
          case ArrayMap(step):
            withArray(v, function (a) return 
              [for (i in 0...a.length) 
                evaluate({ 
                  item: a[i], 
                  pos: i,
                  array: a 
                }, step)
              ]
            );
          case ArrayFirst(check):
            withArray(v, function (a) { 
              for (i in 0...a.length) 
                if (evaluate({ 
                  item: a[i], 
                  pos: i,
                  array: a 
                }, check)) return a[i];
              return null;
        	  }); 
          case ArrayForAll(check):
            withArray(v, function (a) { 
              for (i in 0...a.length) 
                if (!evaluate({ 
                  item: a[i], 
                  pos: i,
                  array: a 
                }, check)) return false;
              return true;
        	  });                   
          case ArrayFilter(step):
            withArray(v, function (a) return 
              [for (i in 0...a.length) 
                if (evaluate({ 
                  item: a[i], 
                  pos: i,
                  array: a 
                }, step)) a[i]
              ]
            );                
          case ArrayFold(initial, step):
            withArray(v, function (a) {
              for (i in 0...a.length)
                initial = evaluate({ 
                  item: a[i], 
                  pos: i,
                  result: initial 
                }, step);
              return initial;
            });                
        }
    }
  }
  static function withArray<R>(v:Dynamic, f:Array<Dynamic>->R):R 
    return f(
      try cast (v, Array<Dynamic>)
      catch (e:Dynamic) [v]
    );

  static public function arrayGet<T>(a:Array<T>, index:Int) {
    index = index % a.length;
    if (index < 0) index += a.length;
    return a[index];
  }

  static public function shallowCopy<A:{}>(obj:A):A {
    if (obj == null) return null;
    var d:DynamicAccess<Any> = obj;
    var ret = new DynamicAccess();
    for (k in d.keys())
      ret[k] = d[k];
    return cast ret;
  }
}