package dumpster;

typedef ArrayContext<O, T> = {
  var item(default, null):ExprOf<O, T>;
  var index(default, null):ExprOf<O, Int>;
  var array(default, null):ExprOf<O, Array<T>>;
}

abstract ExprOf<O, T>(ExprData<O, T>) from ExprData<O, T> {
  
  inline function new(d) this = d;

  public inline function notNull():ExprOf<O, Bool>
    return EBinop(Neq, this, EConst(null));

  public function with<R>(f:ExprOf<O, T>->R):R
    return f(this);

  @:from static function ofExprData<O, T>(data:ExprData<O, T>):ExprOf<O, T>
    return new ExprOf(data);

  @:op(a && b) static function and<O>(a:ExprOf<O, Bool>, b:ExprOf<O, Bool>):ExprOf<O, Bool> 
    return EBinop(And, a, b);

  @:op(a || b) static function or<O>(a:ExprOf<O, Bool>, b:ExprOf<O, Bool>):ExprOf<O, Bool> 
    return EBinop(Or, a, b);

  @:op(a + b) static function add<O, T:Float>(a:ExprOf<O, T>, b:ExprOf<O, T>):ExprOf<O, T> 
    return EBinop(Add, a, b);

  @:commutative @:op(a + b) 
  static function addConst<O, T:Float>(a:ExprOf<O, T>, b:T):ExprOf<O, T> 
    return EBinop(Add, a, b);


  @:op(a + b) static function cat<O>(a:ExprOf<O, String>, b:ExprOf<O, String>):ExprOf<O, String> 
    return EBinop(Cat, a, b);

  @:commutative @:op(a + b) 
  static function catConst<O>(a:ExprOf<O, String>, b:String):ExprOf<O, String> 
    return EBinop(Cat, a, b);
    

  @:op(a == b) static function eq<O, T>(a:ExprOf<O, T>, b:ExprOf<O, T>):ExprOf<O, Bool> 
    return EBinop(Eq, a, b);

  @:commutative
  @:op(a == b) static function eqConst<O, T>(a:ExprOf<O, T>, b:T):ExprOf<O, Bool> 
    return EBinop(Eq, a, EConst(b));


  @:op(a != b) static function neq<O, T>(a:ExprOf<O, T>, b:ExprOf<O, T>):ExprOf<O, Bool> 
    return EBinop(Neq, a, b);

  @:commutative
  @:op(a != b) static function neqConst<O, T>(a:ExprOf<O, T>, b:T):ExprOf<O, Bool> 
    return EBinop(Neq, a, EConst(b));    


  @:op(a > b) static function gt<O, T:Float>(a:ExprOf<O, T>, b:ExprOf<O, T>):ExprOf<O, Bool> 
    return EBinop(Gt, a, b);

  @:commutative

  @:op(a > b) static function gtConst<O, T:Float>(a:ExprOf<O, T>, b:T):ExprOf<O, Bool> 
    return EBinop(Gt, a, EConst(b));      


  @:op(a >= b) static function gte<O, T:Float>(a:ExprOf<O, T>, b:ExprOf<O, T>):ExprOf<O, Bool> 
    return EBinop(Gte, a, b);

  @:commutative
  @:op(a >= b) static function gteConst<O, T:Float>(a:ExprOf<O, T>, b:T):ExprOf<O, Bool> 
    return EBinop(Gte, a, EConst(b));      


  @:op(a < b) static function lt<O, T:Float>(a:ExprOf<O, T>, b:ExprOf<O, T>):ExprOf<O, Bool> 
    return EBinop(Lt, a, b);

  @:commutative
  @:op(a < b) static function ltConst<O, T:Float>(a:ExprOf<O, T>, b:T):ExprOf<O, Bool> 
    return EBinop(Lt, a, EConst(b));      


  @:op(a <= b) static function lte<O, T:Float>(a:ExprOf<O, T>, b:ExprOf<O, T>):ExprOf<O, Bool> 
    return EBinop(Lte, a, b);

  @:commutative
  @:op(a <= b) static function lteConst<O, T:Float>(a:ExprOf<O, T>, b:T):ExprOf<O, Bool> 
    return EBinop(Lte, a, EConst(b));      


  @:op(a - b) static function substract<O, T:Float>(a:ExprOf<O, T>, b:ExprOf<O, T>):ExprOf<O, T> 
    return EBinop(Subtract, a, b);

  @:commutative
  @:op(a - b) static function substractConst<O, T:Float>(a:ExprOf<O, T>, b:T):ExprOf<O, T> 
    return EBinop(Subtract, a, EConst(b));      


  @:op(a * b) static function multiply<O, T:Float>(a:ExprOf<O, T>, b:ExprOf<O, T>):ExprOf<O, T> 
    return EBinop(Multiply, a, b);

  @:commutative
  @:op(a * b) static function multiplyConst<O, T:Float>(a:ExprOf<O, T>, b:T):ExprOf<O, T> 
    return EBinop(Multiply, a, EConst(b));      


  @:op(a / b) static function divide<O, T:Float>(a:ExprOf<O, T>, b:ExprOf<O, T>):ExprOf<O, Float> 
    return EBinop(Divide, a, b);

  @:commutative
  @:op(a / b) static function divideConst<O, T:Float>(a:ExprOf<O, T>, b:T):ExprOf<O, Float> 
    return EBinop(Divide, a, EConst(b));      

  @:impl static public function cond<O, R>(condition:ExprData<O, Bool>, consequence:ExprOf<O, R>, alternative:ExprOf<O, R>):ExprOf<O, R>
    return EIf(condition, consequence, alternative);

  
    
  @:impl static public function fold<O, T, R>(array:ExprData<O, Array<T>>, initial:ExprOf<O, R>, step:{>ArrayContext<O, T>, var result(default, null):ExprOf<O, R>; }->ExprOf<O, R>):ExprOf<O, R>
    return EUnop(ArrayFold(initial, step({
      result: EField(EDoc, 'result'),
      item: EField(EDoc, 'item'),
      index: EField(EDoc, 'index'),
      array: EField(EDoc, 'array'),
    })), array);

  @:impl static public function filter<O, T>(array:ExprData<O, Array<T>>, cond:ArrayContext<O, T>->ExprOf<O, Bool>):ExprOf<O, Array<T>>
    return EUnop(ArrayFilter(cond(ctx())), array);    

  @:impl static public function map<O, T, R>(array:ExprData<O, Array<T>>, cond:ArrayContext<O, T>->ExprOf<O, R>):ExprOf<O, Array<R>>
    return EUnop(ArrayMap(cond(ctx())), array);    

  static function ctx<O, T>():ArrayContext<O, T>
    return { item: EField(EDoc, 'item'), index: EField(EDoc, 'index'), array: EField(EDoc, 'array') };

  @:impl static public function first<O, T>(array:ExprData<O, Array<T>>, cond:ArrayContext<O, T>->ExprOf<O, Bool>):ExprOf<O, Null<T>>
    return EUnop(ArrayFirst(cond(ctx())), array);       

  @:impl static public function has<O, T>(array:ExprData<O, Array<T>>, cond:ArrayContext<O, T>->ExprOf<O, Bool>):ExprOf<O, Bool>
    return first(array, cond).notNull();

  @:from static function intToFloat<O>(e:ExprOf<O, Int>):ExprOf<O, Float>
    return cast e;

  @:from static function ofObj<O, T:{}>(v:T):ExprOf<O, T>
    return EConst(v);

  @:from static function ofPrimitive<O, T:Primitive>(v:T):ExprOf<O, T>
    return EConst(v);

}

@:coreType abstract Primitive from Int from Float from String from Bool {}

typedef Expr = ExprOf<Dynamic, Dynamic>;
    
enum ExprData<O, T> {
  EDoc;
  EField(target:ExprOf<O, {}>, name:String);
  EIndex(target:ExprOf<O, Array<T>>, index:ExprOf<O, Int>);
  EConst(v:T);
  EIf(cond:ExprOf<O, Bool>, cons:ExprOf<O, T>, alt:ExprOf<O, T>);
  EBinop<L, R>(op:Binop<L, R, T>, e1:ExprOf<O, L>, e2:ExprOf<O, R>);
  EUnop<In>(op:Unop<In, T>, e:ExprOf<O, In>);
}

@:coreType abstract Comparable from Float from Int {}

enum Binop<L, R, T> {
  Gte<T:Comparable>:Binop<T, T, Bool>;
  Lte<T:Comparable>:Binop<T, T, Bool>;
  Gt<T:Comparable>:Binop<T, T, Bool>;
  Lt<T:Comparable>:Binop<T, T, Bool>;
  
  Eq<T>:Binop<T, T, Bool>;
  Neq<T>:Binop<T, T, Bool>;

  Cat:Binop<String, String, String>;

  Add<T:Float>:Binop<T, T, T>;
  Subtract<T:Float>:Binop<T, T, T>;
  Multiply<T:Float>:Binop<T, T, T>;
  Divide<T:Float>:Binop<T, T, Float>;

  Pow<T:Float>:Binop<T, T, T>;
  And:Binop<Bool, Bool, Bool>;
  Or:Binop<Bool, Bool, Bool>;
  BitAnd:Binop<Int, Int, Int>;
  BitOr:Binop<Int, Int, Int>;
  BitXor:Binop<Int, Int, Int>;
}

enum Unop<In, Out> {
  Patch<O, F:{}>(fields:haxe.DynamicAccess<ExprOf<O, Dynamic>>, defaults:F):Unop<F, F>;
  Not:Unop<Bool, Bool>;
  Log<T:Float>:Unop<T, Float>;
  BitFlip:Unop<Int, Int>;
  Neg<T:Float>:Unop<T, T>;
    
  ArrayFold<O, X, R>(initial:ExprOf<O, R>, step:ExprOf<O, R>):Unop<Array<X>, R>;
  ArrayMap<O, X, R>(step:ExprOf<O, R>):Unop<Array<X>, Array<R>>;
  ArrayFirst<O, X>(check:ExprOf<O, Bool>):Unop<Array<X>, X>;
  ArrayForAll<O, X>(check:ExprOf<O, Bool>):Unop<Array<X>, Bool>;
  ArrayFilter<O, X>(check:ExprOf<O, Bool>):Unop<Array<X>, Array<X>>;
    
}