package dumpster.types;

using StringTools;

abstract Id<A:{}>(String) {
  
  static inline var EXT = '.dump.json';
  
  inline function new(s) this = s;

  @:to public function toString() 
    return this.urlDecode();
  
  public function toFileName()
    return '$this.dump.json';

  static public function fromFileName(s:String)
    return 
      if (s.endsWith(EXT))
        Some(new Id(s.substr(0, s.length - EXT.length)));
      else
        None;

  @:from static public function ofString<T:{}>(s:String):Id<T> {
    var ret = new StringBuf(),
        s = haxe.io.Bytes.ofString(s);
        
    var bytes = s.getData();
    for (i in 0...s.length) {
      var c = haxe.io.Bytes.fastGet(bytes, i);
      if (c >= 'a'.code && c <= 'z'.code || c >= 'A'.code && c <= 'Z'.code || c >= '0'.code && c <= '9'.code)
        ret.addChar(c);
      else {
        ret.addChar('_'.code);
        ret.add(i.hex(2));
      }
    }
    return new Id(ret.toString());
  }

}