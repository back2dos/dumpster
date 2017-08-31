package dumpster;

using tink.CoreApi;

interface Persistence {
  function commit<A:{}>(id:Id<A>, collection:CollectionName<A>, payload:A):Promise<Date>;
}
