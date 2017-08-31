package dumpster;

import dumpster.AST;
import js.Lib.eval;

interface QueryEngine {
  function compile<O, T>(e:ExprOf<O, T>):O->T;
}

#if js
class JsEngine implements QueryEngine {
  public function new() {}
  public function compile<O, T>(e:ExprOf<O, T>):O->T {
    var src = '(function (doc) { return ${js(e)}; })';
    trace(src);
    return eval(src);
  }
  
  static function js(e:Expr)
    return switch (cast e:ExprData<Dynamic, Dynamic>) {
      case EDoc: 'doc';
      case EField(js(_) => obj, field): '$obj.$field';
      case EBinop(op, js(_) => a, js(_) => b): 
        switch op {
          case Gte: '($a >= $b)';
          case Lte: '($a <= $b)';
          case Gt: '($a > $b)';
          case Lt: '($a < $b)';
          case Eq: '($a == $b)';
          case Neq: '($a != $b)';
          case Add: '($a + $b)';
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
      case EIndex(js(_)=> a, i): '$a[$i]';
      case EUnop(op, js(_) => v): 

        function arrayOp(name:String, ret:String) 
          return '($v).$name(function (item, pos, array) {
            var doc = { item: item, pos: pos, array: array };
            return $ret;
          })';  
        
        switch op {
          case Neg: '-$v';
          case Not: '!$v';
          case BitFlip: '~$v';
          case Log: 'Math.log($v)';
          case ArrayFilter(js(_) => cond): 
            arrayOp('filter', cond);
          case ArrayFirst(js(_) => cond):
            arrayOp('find', cond);           
          case ArrayFold(js(_) => cond, js(_) => init):
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
      
    return switch e {
      case EDoc: doc;
      case EField(rec(_) => obj, name): 
        try Reflect.field(obj, name)
        catch (e:Dynamic) null;
      case EIndex(rec(_) => array, index): 
        try array[index]
        catch (e:Dynamic) null;
      case EConst(v): v;  
      case EIf(cond, cons, alt):
        if (rec(cond)) rec(cons) else rec(alt);
      case EBinop(op, a, b):
        switch op {
          case Neq: rec(a) != rec(b);
          case Eq: rec(a) == rec(b);
          case Gte: rec(a) >= rec(b);
          case Lte: rec(a) <= rec(b);
          case Gt: rec(a) > rec(b);
          case Lt: rec(a) < rec(b);
          case Add: rec(a) + rec(b);
          case Subtract: rec(a) - rec(b);
          case Multiply: rec(a) * rec(b);
          case Divide: rec(a) / rec(b);
          case Pow: Math.pow(rec(a), rec(b));
          case And: rec(a) && rec(b);
          case Or: rec(a) || rec(b);
          case BitAnd: rec(a) & rec(b);
          case BitOr: rec(a) | rec(b);
          case BitXor: rec(a) ^ rec(b);
        }
      case EUnop(op, rec(_) => v):
        switch op {
          case Not: !v;
          case BitFlip: ~v;
          case Neg: -v;
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
}