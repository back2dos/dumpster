package dumpster.types;

typedef Document<A> = {
  var id:Id<A>;
  var created:Date;
  var updated:Date;
  var data:A;
}