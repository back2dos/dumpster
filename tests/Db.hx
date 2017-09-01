typedef User = {
  name:String,
  image:String,
  email:String,
  likes:Array<String>
}

class Db extends dumpster.Dumpster<{ users: User }> {}