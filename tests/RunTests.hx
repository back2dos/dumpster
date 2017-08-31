package ;

import dumpster.AST;
import dumpster.*;

using DateTools;
using tink.CoreApi;

class RunTests {

  static function main() {

    var c = new Users('users', new FsDriver({
      path: js.Node.__dirname + '/test',
      engine: new dumpster.QueryEngine.JsEngine()
    }));

    // c.find(function (u) return u.name == 'back2dos').handle(function (o) trace(o.sure()));
    
    // Future.async(function (cb) {
    //   var start = haxe.Timer.stamp();
    //   function loop(counter:Int) {
    //     c.updateById('2', function (doc) return {
    //       image: Std.string(counter)
    //     }, { patiently: true }).handle(function (o) switch o {
    //       case Failure(e): cb(Failure(e));
    //       default:
    //         if (counter > 0) loop(--counter);
    //         else cb(Success(haxe.Timer.stamp() - start));
    //     });
    //   }
    //   loop(5000);
    // }).handle(function (x) trace(Std.string(x)));

    // c.updateById('2', function (doc) return {
    //   image: doc.image + ' 1234'
    // }, { assuming: NotModifiedSince(Date.now().delta(5.minutes())) }).handle(function (o) trace(o.sure()));

    c.find(function (doc) return doc.likes.has(function (l) return l.item == 'haxe'))
      .handle(function (o) trace(o.sure()));

    // f.foo.fold(0, function (o) return o.result + o.item);
    // var c = new Collection<{ foo:Array<Int> }, {}>

    // var doc = {
    //   foo: (EField('foo'):ExprOf<{ foo:Array<Int> }, Array<Int>>)
    // };

    // doc.foo.fold(0, function (entry) return entry.result + entry.result);
    // travix.Logger.println('it works');
    // travix.Logger.exit(0); // make sure we exit properly, which is necessary on some targets, e.g. flash & (phantom)js
  }
  
}