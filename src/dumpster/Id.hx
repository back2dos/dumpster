package dumpster;

using StringTools;

abstract Id<A:{}>(String) {
  inline function new(s) this = s;
  @:to public function toString() 
    return this.urlDecode();
  
  @:from static public function ofString(s:String) {
    var ret = new StringBuf(),
        s = haxe.io.Bytes.ofString(s);
        
    var bytes = s.getData();
    for (i in 0...s.length) {
      var c = haxe.io.Bytes.fastGet(bytes, i);
      if (c >= 'a'.code && c <= 'z'.code || c >= 'A'.code && c <= 'Z'.code || c >= '0'.code && c <= '9'.code)
        ret.addChar(c);
      else {
        ret.addChar('%'.code);
        ret.add(i.hex(2));
      }
    }
    return new Id(ret.toString());
  }

}