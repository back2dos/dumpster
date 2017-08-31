package dumpster;

typedef ArrayContext<O, T> = {
  item:ExprOf<O, T>, 
  index:ExprOf<O, Int>,
  array:ExprOf<O, Array<T>>,
}

abstract ExprOf<O, T>(ExprData<O, T>) {
  
  inline function new(d) this = d;

  public inline function notNull():ExprOf<O, Bool>
    return EBinop(Neq, this, EConst(null));

  @:from static function ofExprData<O, T>(data:ExprData<O, T>):ExprOf<O, T>
    return new ExprOf(data);
    
  @:op(a + b) static public function add<O, T:Float>(a:ExprOf<O, T>, b:ExprOf<O, T>):ExprOf<O, T> 
    return EBinop(Add, a, b);

  @:commutative @:op(a + b) 
  static public function addConst<O, T:Float>(a:ExprOf<O, T>, b:T):ExprOf<O, T> 
    return EBinop(Add, a, b);

  @:op(a + b) static public function cat<O>(a:ExprOf<O, String>, b:ExprOf<O, String>):ExprOf<O, String> 
    return EBinop(Add, a, b);

  @:commutative @:op(a + b) 
  static public function catConst<O>(a:ExprOf<O, String>, b:String):ExprOf<O, String> 
    return EBinop(Add, a, b);

  @:op(a == b) static public function eq<O, T>(a:ExprOf<O, T>, b:ExprOf<O, T>):ExprOf<O, Bool> 
    return EBinop(Eq, a, b);

  @:commutative
  @:op(a == b) static public function eqConst<O, T>(a:ExprOf<O, T>, b:T):ExprOf<O, Bool> 
    return EBinop(Eq, a, EConst(b));

  @:impl static public function cond<O, R>(condition:ExprData<O, Bool>, consequence:ExprOf<O, R>, alternative:ExprOf<O, R>):ExprOf<O, R>
    return EIf(condition, consequence, alternative);
    
  @:impl static public function fold<O, T, R>(array:ExprData<O, Array<T>>, initial:ExprOf<O, R>, step:{>ArrayContext<O, T>, result:ExprOf<O, R> }->ExprOf<O, R>):ExprOf<O, R>
    return EUnop(ArrayFold(initial, step({
      result: EField(EDoc, 'result'),
      item: EField(EDoc, 'item'),
      index: EField(EDoc, 'index'),
      array: EField(EDoc, 'array'),
    })), array);

  @:impl static public function filter<O, T>(array:ExprData<O, Array<T>>, cond:ArrayContext<O, T>->ExprOf<O, Bool>):ExprOf<O, Array<T>>
    return EUnop(ArrayFilter(cond({
      item: EField(EDoc, 'item'),
      index: EField(EDoc, 'index'),
      array: EField(EDoc, 'array'),
    })), array);    

  @:impl static public function first<O, T>(array:ExprData<O, Array<T>>, cond:ArrayContext<O, T>->ExprOf<O, Bool>):ExprOf<O, Null<T>>
    return EUnop(ArrayFirst(cond({
      item: EField(EDoc, 'item'),
      index: EField(EDoc, 'index'),
      array: EField(EDoc, 'array'),
    })), array);       

  @:from static function ofConst<O, T:JsonConst>(v:T):ExprOf<O, T>
    return EConst(v);
}

@:coreType abstract JsonConst from Int from String from Date from Float from Bool {}

typedef Expr = ExprOf<Dynamic, Dynamic>;
    
enum ExprData<O, T> {
  EDoc;
  EField(target:Expr, name:String);
  EIndex(target:Expr, index:Int);
  EConst(v:Any);
  EIf(cond:Expr, cons:Expr, alt:Expr);
  EBinop(op:Binop, e1:Expr, e2:Expr);
  EUnop(op:Unop, e:Expr);
}

enum Binop {
  Gte;
  Lte;
  Gt;
  Lt;
  Eq;
  Neq;
  Add;
  Subtract;
  Multiply;
  Divide;
  Pow;
  And;
  Or;
  BitAnd;
  BitOr;
  BitXor;
}

enum Unop {
  Not;
  Log;
  BitFlip;
  Neg;
    
  ArrayFold(initial:Any, step:Expr);
  ArrayFirst(check:Expr);
  ArrayForAll(check:Expr);
  ArrayMap(step:Expr);
  ArrayFilter(step:Expr);
    
//   MapFold(initial:Any, step:Expr);
//   MapFirst(check:Expr);
//   MapForAll(check:Expr);
//   MapMap(step:Expr);
//   MapFilter(step:Expr);
  
}