package dumpster;

@:genericBuild(dumpster.macros.DumpsterBuilder.build())
class Dumpster<T> {}

class Base {
  var driver:dumpster.drivers.Driver;
  function new(driver)
    this.driver = driver;

  public function shutdown()
    return driver.shutdown();
}