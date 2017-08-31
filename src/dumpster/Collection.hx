package dumpster;

import dumpster.AST;

@:genericBuild(dumpster.macros.CollectionBuilder.build())
class Collection<A:{}> {}

class CollectionBase<A:{}, Fields> {
  public var name(default, null):CollectionName<A>;
  public var fields(default, null):Fields;
  
  var driver:Driver;

  function new(name, fields, driver) {
    this.name = name;
    this.fields = fields;
    this.driver = driver;
  }

  public function find(?criterion:Fields->ExprOf<A, Bool>)
    return driver.find(name, switch criterion {
      case null: true;
      case f: f(fields);
    });

  public function findOne(?criterion:Fields->ExprOf<A, Bool>)
    return driver.findOne(name, switch criterion {
      case null: true;
      case f: f(fields);
    });

}