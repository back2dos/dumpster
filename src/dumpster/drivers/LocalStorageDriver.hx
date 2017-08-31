package dumpster.drivers;

@:require(js)
class LocalStorageDriver extends MemoryDriver {
  
}

private class LocalStoragePersistence implements Persistence {
  public function commit<A:{}>(id:Id<A>, collection:CollectionName<A>, payload:A):Promise<Date> 
    return Date.now();
  
}