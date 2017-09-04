package dumpster.drivers;

import dumpster.AST;

interface Driver {
  function get<A>(id:Id<A>, within:CollectionName<A>):Promise<Document<A>>;
  function find<A>(within:CollectionName<A>, check:ExprOf<A, Bool>, ?options:{ ?max:Int }):Promise<Array<Document<A>>>;
  function count<A>(within:CollectionName<A>, check:ExprOf<A, Bool>):Promise<Int>;
  function set<A>(id:Id<A>, within:CollectionName<A>, doc:ExprOf<A, A>, ?options:{ ?ifNotModifiedSince:Date, ?patiently:Bool }):Promise<{ before: Option<Document<A>>, after: Document<A> }>;
  function update<A>(within:CollectionName<A>, check:ExprOf<A, Bool>, doc:ExprOf<A, A>, ?options:{ ?ifNotModifiedSince:Date, ?patiently:Bool, ?max:Int }):Promise<Array<{ before:Document<A>, after:Document<A> }>>;
  function shutdown():Promise<Noise>;
}