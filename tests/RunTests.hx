package ;

import dumpster.AST;
import dumpster.*;

using DateTools;
using tink.CoreApi;

typedef User = {
  name:String,
  image:String,
  email:String,
}

class RunTests {

  static function main() {

    var c = new Collection<User>('users', new MemoryDriver({
      initWith: ({
        users: [
          for (i in 0...10) {
            id: Std.string(i),
            updated: Date.now(),
            created:Date.now(),
            data: {
              name: 'back${i}dos',
              image: 'none',
              email: 'back${i}dos@gmail.com',
            }  
          }
        ]
      }:dumpster.MemoryDriver.Payload),
    }));

    // c.find(function (u) return u.name == 'back2dos').handle(function (o) trace(o.sure()));
    
    // Future.async(function (cb) {
    //   var start = haxe.Timer.stamp();
    //   function loop(counter:Int) {
    //     c.updateById('2', function (doc) return {
    //       image: (doc.image == 'none').cond('silly image', 'none')
    //     }).handle(function (o) switch o {
    //       case Failure(e): cb(Failure(e));
    //       default:
    //         if (counter > 0) loop(--counter);
    //         else cb(Success(haxe.Timer.stamp() - start));
    //     });
    //   }
    //   loop(5000);
    // }).handle(function (x) trace(Std.string(x)));

    c.updateById('2', function (doc) return {
      image: doc.image + ' 1234'
    }, { assuming: NotModifiedSince(Date.now().delta(5.minutes())) }).handle(function (o) trace(o.sure()));

    // f.foo.fold(0, function (o) return o.result + o.item);
    // var c = new Collection<{ foo:Array<Int> }, {}>

    // var doc = {
    //   foo: (EField('foo'):ExprOf<{ foo:Array<Int> }, Array<Int>>)
    // };

    // doc.foo.fold(0, function (entry) return entry.result + entry.result);
    travix.Logger.println('it works');
    travix.Logger.exit(0); // make sure we exit properly, which is necessary on some targets, e.g. flash & (phantom)js
  }
  
}