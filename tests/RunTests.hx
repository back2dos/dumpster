package ;

using Lambda;
using tink.CoreApi;

import haxe.unit.*;
import dumpster.drivers.*;
import dumpster.QueryEngine;

typedef Foobar = {
  foo:Int,
  bar:Int,
}

class RunTests extends TestCase {
  static function assert(cond:Bool, ?pos:haxe.PosInfos) {
    if (!cond) {
      travix.Logger.println(pos.fileName + '@' + pos.lineNumber + ': assertion failed');
      travix.Logger.exit(500);
    }
    return Noise;
  }

  function testExpr() {

    var x = new dumpster.types.Fields<{ foo: { bar: Int } }>();

    var its:dumpster.types.Fields<{>User, score:Int, o1:Foobar, o2:Foobar }> 
      = new dumpster.types.Fields<{>User, score:Int, o1:Foobar, o2:Foobar }>();
       
    var engines:Array<QueryEngine> = [
      #if js new JsEngine(),#end
      new SimpleEngine()
    ];

    for (e in engines) {
      var o = {
        name: "JohnDoe",
        score: 42,
        image: "example.png",
        email: "john.doe@example.com",
        likes: ["foo", "blargh"],
        o1: {
          foo: 12,
          bar: 13
        },
        o2: {
          foo: 1,
          bar: 2
        },
      }

      inline function yep(expr, ?pos)
        assertTrue(e.compile(expr)(o), pos);

      inline function nope(expr, ?pos)
        assertFalse(e.compile(expr)(o), pos);
        
      yep(its.score > 5);
      nope(its.score < 5);
      
      var copy = e.compile(its.patch({
        o1: its.o2,
        o2: 
          its.o2.with(function (o) return
            its.o2.patch({
              foo: o.bar,
              bar: o.foo,          
            })
          )
      }))(o);

      assertEquals(o.email, copy.email);
      assertEquals(o.o2, copy.o1);
      assertEquals(o.o2.bar, copy.o2.foo);
      assertEquals(o.o2.foo, copy.o2.bar);

      yep(its.score >= 5);
      nope(its.score <= 5);

      yep(its.score >= 42);
      yep(its.score == 42);
      yep(its.score <= 42);

      yep(its.score < 50);
      nope(its.score > 50);

      yep(its.score == 42);
      yep(its.score != 43);

      nope(its.score == 43);
      nope(its.score != 42);

      yep(its.score == its.score * its.score / 42);
      yep(its.score < its.score * its.score / 21);

      yep(its.likes.has(function (i) return i.item == "foo") && its.likes.has(function (i) return i.item == "blargh"));
      yep(its.likes.has(function (i) return i.item == "beep") || its.likes.has(function (i) return i.item == "blargh"));
      yep(its.likes.has(function (i) return i.item == "foo") || its.likes.has(function (i) return i.item == "boop"));
      nope(its.likes.has(function (i) return i.item == "beep") || its.likes.has(function (i) return i.item == "boop"));
      yep(its.likes.first(function (i) return i.item == "foo") + ":blub" == "foo:blub");
      nope(its.o1.foo < its.o2.foo);
    }
  }

  static function main() {

    var runner = new TestRunner();
    runner.add(new RunTests());
    if (!runner.run())
      travix.Logger.exit(500);
    
    var db:Db = new Db(
      #if asys
        new FsDriver()
      #elseif (js && !nodejs)
        new LocalStorageDriver()
      #else
        new MemoryDriver()
      #end
    );
    
    var start = haxe.Timer.stamp();
    var fruit = 'apples,bananas,kiwis,peaches'.split(',');
    var likes = [for (i in 0...1 << fruit.length) 
      [for (f in 0...fruit.length) 
        if (i & (1 << f) != 0) fruit[f]
      ]
    ];

    db.users.set(dumpster.types.Id.ofString('hoho'), function (fields) return fields.patch(
      { email: 'hohoho!' }
    )).handle(function (o) assert(!o.isSuccess()));

    Promise.inParallel([
      for (i in 0...128)
        db.users.set(dumpster.types.Id.ofString('$i'), function (fields) return {
          name: 'User_$i',
          email: 'user.number$i@example.com',
          image: 'none',
          likes: likes[i % likes.length],
        }, { patiently: true })
    ]).next(function (users) {
      assert(users.length == 128);
      return db.users.findAll(function (u) return u.likes.has(function (l) return l.item == 'bananas' || l.item == 'kiwis'));
    }).next(function (users) {
      assert(users.length == 96);

      for (u in users)
        assert(u.data.likes.has('bananas') || u.data.likes.has('kiwis'));

      return Promise.inParallel([
        for (u in users)
          if (u.data.likes.has('bananas') && u.data.likes.has('kiwis')) {
            db.users.set(u.id, function (u) return u.patch({
              likes: ['stuff']
            }));
          }
      ]);
    }).next(function (users) {
      assert(users.length == 32);
      return 
        db.users.findAll(function (u) return u.likes.has(function (l) return l.item == 'stuff'))
          .next(function (users) {
            return assert(users.length == 32);
          });
    }).handle(function (o) {
      db.shutdown().handle(function () {
        travix.Logger.println((if (o.isSuccess()) 'Succeeded' else 'Failed') + ' after ${haxe.Timer.stamp() - start}');
        travix.Logger.exit(if (o.isSuccess()) 0 else 500);
      });
    });
    
  }
  
}