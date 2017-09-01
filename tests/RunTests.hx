package ;

import dumpster.AST;
import dumpster.*;
import dumpster.drivers.LocalStorageDriver;

using DateTools;
using tink.CoreApi;


class RunTests {

  static function main() {
    var n:Db = new Db(
      new dumpster.drivers.FsDriver()
    );

    Promise.inParallel([
      for (i in 0...1000)
        n.users.updateById(dumpster.types.Id.ofString('$i'), function (fields) return {
          name: 'User_$i',
          email: 'user.number$i@example.com',
          image: 'none',
          likes: [],
        })
    ]).handle(function (x) trace(x.map(function (a) return a.length)));
    //n.users.
    //n.users.find().handle(function (o) trace(Std.string(o)));
    // travix.Logger.println('it works');
    // travix.Logger.exit(0); // make sure we exit properly, which is necessary on some targets, e.g. flash & (phantom)js
  }
  
}