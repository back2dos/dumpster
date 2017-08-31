package dumpster.drivers;

import dumpster.AST;

interface Driver {
  function get<A:{}>(id:Id<A>, collectionName:CollectionName<A>):Promise<Document<A>>;
  function findOne<A:{}>(collectionName:CollectionName<A>, check:ExprOf<A, Bool>):Promise<Option<Document<A>>>;
  function find<A:{}>(collectionName:CollectionName<A>, check:ExprOf<A, Bool>):Promise<Array<Document<A>>>;
  function count<A:{}>(collectionName:CollectionName<A>, check:ExprOf<A, Bool>):Promise<Int>;
  
  function update<A:{}>(id:Id<A>, collectionName:CollectionName<A>, patch:PatchFor<A>, ?options:{ ?assuming:UpdateCondition, ?patiently:Bool }):Promise<A>;
}

enum UpdateCondition {
  Exists;
  NotExists;
  NotModifiedSince(date:Date);
}

abstract PatchFor<A>(haxe.DynamicAccess<ExprOf<A, Dynamic>>) {
  public function fields()
    return this;
}