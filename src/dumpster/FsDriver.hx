package dumpster;

class FsDriver extends MemoryDriver {
  public function new(options:{ path:String, ?engine:QueryEngine }) {
    var persistence = new FsPersistence(options.path);
    super({
      persist: persistence,
      engine: options.engine,
      initWith: persistence.initialState,
    });
  }
}