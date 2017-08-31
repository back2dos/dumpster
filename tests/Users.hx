typedef User = {
  name:String,
  image:String,
  email:String,
  likes:Array<String>
}

class Users extends dumpster.Collection<User> {}