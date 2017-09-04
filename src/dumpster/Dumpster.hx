package dumpster;

import dumpster.drivers.*;

@:genericBuild(dumpster.macros.DumpsterBuilder.build())
class Dumpster<T> {}

class Base {
  var driver:Driver;
  function new(?driver:Driver)
    this.driver = switch driver {
      case null: new MemoryDriver(); 
      case v: v;
    }

  public function shutdown()
    return driver.shutdown();
}