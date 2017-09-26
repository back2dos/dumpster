package dumpster.types;

import dumpster.AST;

@:genericBuild(dumpster.macros.CollectionBuilder.build())
class Collection<A:{}> {}

class CollectionBase<A:{}, Data> {
  public var name(default, null):CollectionName<A>;
  public var fields(default, null):Data;
  
  var driver:dumpster.drivers.Driver;

  function new(name, fields, driver) {
    this.name = name;
    this.fields = fields;
    this.driver = driver;
  }

  public function get(id:Id<A>)
    return driver.get(id, name);

  public function findAll(?criterion:Data->ExprOf<A, Bool>, ?options)
    return driver.find(name, switch criterion {
      case null: true;
      case f: f(fields);
    }, options);

  public function findOne(?criterion:Data->ExprOf<A, Bool>)
    return driver.find(name, switch criterion {
      case null: true;
      case f: f(fields);
    }, { max: 1 }).next(function (a) return switch a {
      case []: None;
      case v: Some(v[0]);
    });

  public function set(id:Id<A>, doc:Data->ExprOf<A, A>, ?options:{ ?ifNotModifiedSince:Date, ?patiently:Bool }):Promise<{ before: Option<Document<A>>, after: Document<A> }>
    return driver.set(id, name, doc(fields), options);

  public function updateOne(criterion:Data->ExprOf<A, Bool>, changes:Data->ExprOf<A, A>, ?o:{ ?ifNotModifiedSince:Date, ?patiently:Bool }) {
    if (o == null) o = {};
    return 
      driver.update(name, criterion(fields), changes(fields), { patiently: o.patiently, ifNotModifiedSince: o.ifNotModifiedSince, max: 1 })
        .next(function (a) return switch a {
          case []: None;
          default: Some(a[0]);
        });
  }

  public function updateAll(criterion:Data->ExprOf<A, Bool>, changes:Data->ExprOf<A, A>, ?options) 
    return driver.update(name, criterion(fields), changes(fields), options);
  

}