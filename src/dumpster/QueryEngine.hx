package dumpster;

import dumpster.AST;

interface QueryEngine {
  function compile<O, T>(e:ExprOf<O, T>):O->T;
}

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
      case EField(name): 
        try Reflect.field(doc, name)
        catch (e:Dynamic) null;
      case EIndex(index): 
        try (doc:Dynamic)[index]
        catch (e:Dynamic) null;
      case EConst(v): v;  
      case EIf(cond, cons, alt):
        if (rec(cond)) rec(cons) else rec(alt);
      case EBinop(op, a, b):
        switch op {
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