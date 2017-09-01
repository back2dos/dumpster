package ;

using Lambda;
using tink.CoreApi;

import dumpster.drivers.*;

class RunTests {
  static function assert(cond:Bool, ?pos:haxe.PosInfos) {
    if (!cond) {
      travix.Logger.println(pos.fileName + '@' + pos.lineNumber + ': assertion failed');
      travix.Logger.exit(500);
    }
    return Noise;
  }

  static function main() {
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

    Promise.inParallel([
      for (i in 0...128)
        db.users.updateById(dumpster.types.Id.ofString('$i'), function (fields) return {
          name: 'User_$i',
          email: 'user.number$i@example.com',
          image: 'none',
          likes: likes[i % likes.length],
        }, { patiently: true })
    ]).next(function (users) {
      assert(users.length == 128);
      return db.users.find(function (u) return u.likes.has(function (l) return l.item == 'bananas' || l.item == 'kiwis'));
    }).next(function (users) {
      assert(users.length == 96);

      for (u in users)
        assert(u.data.likes.has('bananas') || u.data.likes.has('kiwis'));

      return Promise.inParallel([
        for (u in users)
          if (u.data.likes.has('bananas') && u.data.likes.has('kiwis')) {
            db.users.updateById(u.id, function (u) return {
              likes: ['stuff']
            });
          }
      ]);
    }).next(function (users) {
      assert(users.length == 32);
      return 
        db.users.find(function (u) return u.likes.has(function (l) return l.item == 'stuff'))
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