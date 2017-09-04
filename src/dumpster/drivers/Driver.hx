package dumpster.drivers;

import dumpster.AST;

interface Driver {
  function get<A:{}>(id:Id<A>, within:CollectionName<A>):Promise<Document<A>>;
  function findOne<A:{}>(within:CollectionName<A>, check:ExprOf<A, Bool>):Promise<Option<Document<A>>>;
  function findAll<A:{}>(within:CollectionName<A>, check:ExprOf<A, Bool>):Promise<Array<Document<A>>>;
  function count<A:{}>(within:CollectionName<A>, check:ExprOf<A, Bool>):Promise<Int>;
  function set<A:{}>(id:Id<A>, within:CollectionName<A>, doc:ExprOf<A, A>, ?options:{ ?ifNotModifiedSince:Date, ?patiently:Bool }):Promise<{ before: Option<Document<A>>, after: Document<A> }>;
  // function updateOne<A:{}>(id:Id<A>, within:CollectionName<A>, check:ExprOf<A, Bool>, ?options:{ ?ifNotModifiedSince:Date, ?patiently:Bool }):Promise<A>;
  // function updateAll<A:{}>(id:Id<A>, within:CollectionName<A>, check:ExprOf<A, Bool>, ?options:{ ?ifNotModifiedSince:Date, ?patiently:Bool }):Promise<A>;
  function shutdown():Promise<Noise>;
}