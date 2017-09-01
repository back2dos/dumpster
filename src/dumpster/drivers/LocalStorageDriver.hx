package dumpster.drivers;

@:require(js)
class LocalStorageDriver extends MemoryDriver {
  public function new(?options:{ ?prefix:String, ?engine:QueryEngine }) {
    if (options == null) options = {};
    var p = new LocalStoragePersistence(js.Browser.getLocalStorage(), options.prefix);
    super({
      initWith: p.getInitial(),
      engine: options.engine,
      persist: p
    });
  }
}

private class LocalStoragePersistence implements Persistence {
  
  var storage:js.html.Storage;
  var prefix:String;

  public function getInitial():Payload {
    var ret = new Payload();
    for (k in 0...storage.length) {
      var key = storage.key(k);
      switch key.split('.') {
        case [_ == prefix => true, collection, id]:
          
          var o = haxe.Json.parse(storage.getItem(key));

          (switch ret[collection] {
            case null: ret[collection] = [];
            case v: v;
          }).push({
            id: cast id,
            created: Date.fromString(o.created),
            updated: Date.fromString(o.updated),
            data: o.data,
          });
        default:
      }
    }
    return ret;
  }

  public function new(storage, ?prefix:String) {
    this.prefix = switch prefix {
      case null: dumpster.macros.Misc.buildDir();
      case v: v;
    }
    this.storage = storage;
  }
  public function commit<A:{}>(id:Id<A>, collection:CollectionName<A>, payload:A):Promise<Date> {
    var updated = Date.now();
    var key = '$prefix.$collection.$id';
    var created = switch storage.getItem(key) {
      case null: updated;
      case v: Date.fromString(haxe.Json.parse(v).created);
    }

    try {
      storage.setItem(key, haxe.Json.stringify({
        updated: updated.toString(),
        created: created.toString(),
        data: payload,
      }));
      return updated;
    }
    catch (e:Dynamic) {
      return new Error('Failed to store `$collection`.`$id` because $e');
    }
  }
    
  
}