package dumpster.drivers;

interface Persistence {
  function commit<A:{}>(id:Id<A>, collection:CollectionName<A>, payload:A):Promise<Date>;
}
