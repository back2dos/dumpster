package dumpster.drivers;

import dumpster.drivers.Driver;
import dumpster.AST;
import haxe.DynamicAccess;
import dumpster.QueryEngine.SimpleEngine.shallowCopy;

private class Ephemere implements Persistence {
  public function new() {}
  public function commit<A>(id:Id<A>, collection:CollectionName<A>, payload:A):Promise<Date> 
    return Date.now();
}

class MemoryDriver implements Driver {
  
  var collections:Promise<Payload>;
  var engine:QueryEngine;
  var persistence:Persistence;
  var shutdownProgress:Promise<Noise>;

  public function new(?options:{ ?initWith:Promise<Payload>, ?engine:QueryEngine, ?persist:Persistence }) {
    if (options == null) options = {};
    this.collections = switch options.initWith {
      case null: new Payload();
      case v: v;
    }
    this.engine = switch options.engine {
      case null: new dumpster.QueryEngine.SimpleEngine();
      case v: v;
    }

    this.persistence = switch options.persist {
      case null: new Ephemere();
      case v: v;
    }
  }  

  public function shutdown() {
    if (shutdownProgress == null) {
      collections = new Error('Dumpster is shutting down');
      shutdownProgress = Future.async(
        function (cb) haxe.Timer.delay(cb.bind(Noise), 1000)//TODO: obviously, this could be done a lot better by waiting for all pending commits to finish
      );
    }
    return shutdownProgress;
  }

  static inline function replace<A>(a:Array<A>, old:A, nu:A)
    return switch a.indexOf(old) {
      case -1: false;
      case v: 
        a[v] = nu;
        true;
    }

  static inline function first<A>(a:Array<A>, f:A->Bool) {
    var ret = None;
    for (x in a)
      if (f(x)) {
        ret = Some(x);
        break;
      }
    return ret;
  }

  static inline function byId<Id, A:{ id:Id }>(a:Array<A>, id:Id)
    return first(a, function (o) return o.id == id);

  public function get<A>(id:Id<A>, within:CollectionName<A>):Promise<Document<A>>
    return
      collections.next(function (c) return switch c[within] {
        case null: 
          new Error(NotFound, 'unknown collection `$within`');
        case v: 
          switch byId(v,id) {
            case None: new Error(NotFound, 'unknown collection `$within`');
            case Some(doc): doc;
          }
      });
  
  function doFind<A, Ret>(within:CollectionName<A>, check:ExprOf<A, Bool>, f:Array<Document<A>> -> (A->Bool) -> Ret):Promise<Ret>
    return
      collections.next(function (c) return switch c[within] {
        case null: 
          f([], function (_) return true);
        case v: 
          f.bind(v, engine.compile(check)).catchExceptions();
          
      });

  static function clone<O>(value:O):O
    return switch Type.typeof(value) {
      case TInt | TBool | TFloat | TClass(String) | TUnknown | TFunction | TNull: value;
      case TObject:
        var o:DynamicAccess<Any> = cast value,
            copy = new DynamicAccess();
        for (k in o.keys())
          copy[k] = o[k];
        cast copy;
      case TClass(Array):
        cast [for (x in (cast value : Array<Dynamic>)) clone(x)];
      case TClass(cl):
        var ret = Type.createEmptyInstance(cl);
        for (f in Type.getInstanceFields(cl))
          Reflect.setField(ret, f, Reflect.field(value, f));
        ret;
      case TEnum(e):
        Type.createEnumIndex(e, Type.enumIndex(cast value), clone(Type.enumParameters(cast value)));
    }

  public function find<A>(within:CollectionName<A>, check:ExprOf<A, Bool>, ?options:{ ?max:Int }):Promise<Array<Document<A>>> {
    
    var max = switch options {
      case null | { max: null }: 1 << 30;
      case { max: v }: v;
    }

    if (max <= 0) return [];

    return 
      doFind(within, check, function (docs, f) {
        var ret = [];
        for (d in docs) if (f(d.data)) 
          if (ret.push(Reflect.copy(d)) >= max) break;
        return ret;
      });
  }
  
  public function count<A>(within:CollectionName<A>, check:ExprOf<A, Bool>):Promise<Int> 
    return 
      doFind(within, check, function (docs, f) {
        var ret = 0;
        for (d in docs)
          if (f(d.data)) ret++;
        return ret; 
      });
  
  public function set<A>(id:Id<A>, within:CollectionName<A>, doc:ExprOf<A, A>, ?options:{ ?ifNotModifiedSince:Date, ?patiently:Bool }):Promise<{ before: Option<Document<A>>, after: Document<A> }>
    return 
      collections.next(function (c) {

        return write(
          switch c[within] {
            case null: c[within] = [];
            case v: v;
          },
          id,
          within,
          doc,
          options
        ).next(function (o) return {
          before: switch o.before {
            case null: None;
            case v: Some(v);
          },
          after: o.after,
        });

      });

  function write<A>(
    docs:Array<Document<A>>, 
    id:Id<A>, 
    within:CollectionName<A>, 
    doc:ExprOf<A, A>, 
    ?options:{ ?ifNotModifiedSince:Date, ?patiently:Bool }
  ):Promise<{ before: Document<A>, after: Document<A> }> {

    if (options == null)
      options = {};

    var now = Date.now(),
        old = byId(docs, id);

    var nu = switch old {
      case Some(v): 
        switch options.ifNotModifiedSince {
          case null:
          case d: 
            if (d.getTime() < v.updated.getTime())
              return new Error(Conflict, 'document `$within`.`$id` has been modified since $d');
        }
        var nu = shallowCopy(v);
        replace(docs, v, nu);
        nu;
      case None: 
        var blank = {
          id: id,
          created: now,
          updated: now,
          data: null
        }
        docs.push(blank);
        blank;
    }          

    function rollback() 
      switch old {
        case Some(v):
          replace(docs, nu, v);
        case None:
          docs.remove(nu);
      }

    try {
      nu.data = engine.compile(doc)(nu.data);
    }
    catch (e:Dynamic) {
      rollback();
      return new Error(Std.string(e));
    }

    var commit = persistence.commit(id, within, nu.data);
    commit.handle(function (o) switch o {
      case Success(d): 
        nu.updated = Date.now();
        if (old == None)
          nu.created = nu.updated;
      case Failure(e):
        rollback();
    });

    var ret = {
      before: clone(old.orNull()),
      after: clone(nu),
    }

    return
      if (options.patiently)
        commit.next(function (_) return ret)
      else 
        ret;
        
  }

  public function update<A>(within:CollectionName<A>, check:ExprOf<A, Bool>, changes:ExprOf<A, A>, ?options:{ ?ifNotModifiedSince:Date, ?patiently:Bool, ?max:Int }):Promise<Array<{ before:Document<A>, after:Document<A> }>>
    return doFind(within, check, function (collection, check) {

      var ret = [],
          max = switch options {
            case null | { max: null }: 1 << 30;
            case { max: v }: v;
          }

      for (doc in collection) 
        if (check(doc.data)) 
          ret.push(write(collection, doc.id, within, changes, options));

      return ret;
    }).next(function (promises) return Promise.inParallel(promises));

}