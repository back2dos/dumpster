package dumpster.drivers;

import dumpster.drivers.Driver;
import dumpster.AST;
import haxe.DynamicAccess;

private class Ephemere implements Persistence {
  public function new() {}
  public function commit<A:{}>(id:Id<A>, collection:CollectionName<A>, payload:A):Promise<Date> 
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

  public function get<A:{}>(id:Id<A>, within:CollectionName<A>):Promise<Document<A>>
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

  public function findOne<A:{}>(within:CollectionName<A>, check:ExprOf<A, Bool>):Promise<Option<Document<A>>>
    return doFind(within, check, function (docs, f) {
      for (d in docs)
        if (f(d.data)) return Some(d);
      return None;
    });
  
  function doFind<A:{}, Ret>(within:CollectionName<A>, check:ExprOf<A, Bool>, f:Array<Document<A>> -> (A->Bool) -> Ret):Promise<Ret>
    return
      collections.next(function (c):Ret return switch c[within] {
        case null: 
          f([], function (_) return true);
        case v: 
          f(v, engine.compile(check));
      });

  public function find<A:{}>(within:CollectionName<A>, check:ExprOf<A, Bool>):Promise<Array<Document<A>>>
    return 
      doFind(within, check, function (docs, f) return [for (d in docs) if (f(d.data)) Reflect.copy(d)]);
  
  public function count<A:{}>(within:CollectionName<A>, check:ExprOf<A, Bool>):Promise<Int> 
    return 
      doFind(within, check, function (docs, f) {
        var ret = 0;
        for (d in docs)
          if (f(d.data)) ret++;
        return ret; 
      });
  
  static function shallowCopy<A:{}>(obj:A):A {
    var d:DynamicAccess<Any> = obj;
    var ret = new DynamicAccess();
    for (k in d.keys())
      ret[k] = d[k];
    return cast ret;
  }

  public function update<A:{}>(id:Id<A>, within:CollectionName<A>, patch:PatchFor<A>, ?options:{ ?assuming:UpdateCondition, ?patiently:Bool }):Promise<A>
    return 
      collections.next(function (c) {
        var v:Array<Document<A>> = 
          switch c[within] {
            case null: c[within] = [];
            case v: v;
          }
        var doc = None;
        if (options == null)
          options = {};
        
        for (d in (v:Array<Document<A>>))
          if (d.id == id) {
            doc = Some(d);
            break;
          }

        function doUpdate(doc:Document<A>):Promise<A> {
          var patch = patch.fields(),
              nu = shallowCopy(doc.data);
          
          var updates = [for (key in patch.keys()) 
            key => engine.compile(patch[key])(doc.data)
          ];

          for (k in updates.keys())
            switch updates[k] {
              case null: Reflect.deleteField(nu, k);
              case v: Reflect.setField(nu, k, v);
            }
          
          var backup = shallowCopy(doc);

          doc.data = nu;
          doc.updated = Date.now();
          if (doc.created == null) {
            doc.created = doc.updated;
            v.push(doc);
          }

          var commit = persistence.commit(id, within, nu);
          commit.handle(function (o) switch o {
            case Success(d): 
              doc.updated = Date.now();
              if (backup.created == null)
                doc.created = doc.updated;
            case Failure(e):
              if (backup.created == null)
                v.remove(doc);
              else {
                doc.data = backup.data;
                doc.updated = backup.updated;
              }
          });

          var copy = Reflect.copy(nu);

          return
            if (options.patiently)
              commit.next(function (_) return copy)
            else 
              copy;
        }
        
        return switch doc {
          case Some(doc): 
            switch options.assuming {
              case NotExists: 
                new Error(Conflict, 'document `$id` already exists in collection `$within`');
              case NotModifiedSince(d) if (d.getTime() < doc.updated.getTime()):
                new Error(Conflict, 'document `$within`.`$id` has changed since $d');
              default: 
                doUpdate(doc);
            }

          case None: 
            switch options.assuming {
              case null | NotExists | NotModifiedSince(_):
                doUpdate({
                  id: id,
                  data: cast {},
                  created: null,
                  updated: null,
                });
              case Exists:
                new Error(NotFound, 'document `$id` not found in collection `$within`');
            }
        }
      }).eager();
}