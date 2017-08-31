package dumpster;

import dumpster.MemoryDriver.Payload;

using StringTools;
using asys.io.File;
using asys.FileSystem;
using tink.CoreApi;

class FsPersistence implements Persistence {
  static inline function p<T>(p:Promise<T>):Promise<T> return p;
  public var initialState(default, null):Promise<Payload>;
  
  var path:String;

  public function new(path:String) {
    this.path = path;
    this.initialState = p(path.readDirectory())
      .next(function (collections) 
        return Promise.inParallel([
          for (dir in collections)
            p('$path/$dir'.readDirectory()).next(function (documents) 
              return Promise.inParallel([
                for (doc in documents) if (doc.endsWith('.dump.json')) {
                    
                  var file = '$path/$dir/$doc';
                  p(file.stat()).next(function (stat) {
                    return p(file.getContent()).next(function (content):Promise<Document<Dynamic>> {
                      try return ({
                        id: Id.fromFileName(doc),
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

  function doCommit<A:{}>(id:Id<A>, collection:CollectionName<A>, payload:A):Promise<Noise> {
    var dir = '$path/$collection';
    
    function save() {
      var final = '$dir/${id.toFileName()}';
      var tmp = '$final.tmp';
      return p(tmp.saveContent(haxe.Json.stringify(payload, "  ")))
        .next(function (_) return tmp.rename(final));
    }

    return dir.exists().next(
      function (exists) 
        return
          if (exists) save();
          else p(dir.createDirectory()).next(function (_) return save())
    );
  }

  public function commit<A:{}>(id:Id<A>, collection:CollectionName<A>, payload:A):Promise<Date> {
    var key = '$collection.$id';
    var done = 
      switch pending[key] {
        case null:
          doCommit(id, collection, payload);
        case v:
          v.flatMap(function (_) return doCommit(id, collection, payload));
      };

    done.handle(function (_) if (pending[key] == done) pending.remove(key));

    return done.next(function (_) return Date.now());
  }
    
  
}