package dumpster.drivers;

#if asys
using StringTools;
using asys.io.File;
using asys.FileSystem;
using haxe.io.Path;

class FsDriver extends MemoryDriver {
  public function new(?options:{ ?path:String, ?engine:QueryEngine }) {
    if (options == null) options = {};
    var persistence = new FsPersistence(switch options.path {
      case null: './dumpster.db';
      case v: v;
    });
    super({
      persist: persistence,
      engine: options.engine,
      initWith: persistence.initialState,
    });
  }
}

private class FsPersistence implements Persistence {
  static inline function p<T>(p:Promise<T>):Promise<T> return p;
  public var initialState(default, null):Promise<Payload>;
  
  var path:String;

  static function ensureDir(path:String):Promise<String> {

    function rec(path:String):Promise<Noise>
      return 
        switch path.removeTrailingSlashes() {
          case '' | '.' | '/':
            Noise;
          case path:
            path.isDirectory().next(function (isDir) return
              if (isDir) Noise
              else rec(path.directory()).next(function (_) return path.createDirectory())
            );        
        }

    return rec(path).next(function (_) return path);
  }

  public function new(path:String) {
    this.path = path;
    this.initialState = ensureDir(path).next(function (_) return path.readDirectory())
      .next(function (collections) 
        return Promise.inParallel([
          for (dir in collections)
            p('$path/$dir'.readDirectory()).next(function (documents) 
              return Promise.inParallel([
                for (doc in documents) switch Id.fromFileName(doc) {
                  case None: continue;
                  case Some(id):
                    
                    var file = '$path/$dir/$doc';
                    p(file.stat()).next(function (stat) {
                      return p(file.getContent()).next(function (content):Promise<Document<Dynamic>> {
                        try return ({
                          id: id,
                          created: stat.ctime,
                          updated: stat.mtime,
                          data: haxe.Json.parse(content),
                        }:Document<Dynamic>)
                        catch (e:Dynamic) 
                          return new Error(422, 'Failed to parse JSON in $file because $e');
                      });
                    });
                }
              ]).next(function (docs) return {
                name: dir,
                docs: docs,
              })
            )
        ]).next(function (collections) {
          var ret = new haxe.DynamicAccess();
          for (c in collections)
            ret[c.name] = c.docs;
          return ret;
        })
      );
    
  }

  var pending = new Map<String, Promise<Noise>>();

  function doCommit<A>(id:Id<A>, collection:CollectionName<A>, payload:A):Promise<Noise> 
    return ensureDir('$path/$collection').next(function (dir) {
      var _final = '$dir/${id.toFileName()}';
      var tmp = '$_final.tmp';
      return p(tmp.saveContent(haxe.Json.stringify(payload, "  ")))
        .next(function (_) return tmp.rename(_final));
    });

  public function commit<A>(id:Id<A>, collection:CollectionName<A>, payload:A):Promise<Date> {
    var key = '$collection.$id';
    var done = 
      switch pending[key] {
        case null:
          doCommit(id, collection, payload);
        case v:
          v.flatMap(function (_) return doCommit(id, collection, payload));
      };

    pending[key] = done;

    done.handle(function (_) if (pending[key] == done) pending.remove(key));

    return done.next(function (_) return Date.now());
  }
    
  
}
#else
@:require(asys)
class FsDriver extends MemoryDriver {
  public function new(options:{ path:String, ?engine:QueryEngine }) {
    super(null);
  }
}
#end