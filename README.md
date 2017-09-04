# DumpsterDB - the fine art of dumping data "somewhere"

Very incomplete, but portable document storage that can run:

- in memory
- in a browser's local storage
- on top of the filesystem as presented by [asys](https://github.com/benmerckx/asys)

Example usage (using `tink_await` and Haxe 4 for succinctness):

```haxe
import dumpster.types.Id;

typedef User = {
  name: String,
  email: String,
}

typedef Issue = {
  title: String,
  description: String,
  priority: Int,
  open: Bool,
  reporter:Id<User>,
  assignee:Null<Id<User>>
}

@async class Test {
  static function main() {
    var tracker = new dumpster.Dumpster<{
      users: User,
      issues: Issue
    }>();

    @await tracker.users.set('john', _ -> {
      name: 'John',
      email: 'john@example.com',
    });

    @await tracker.users.set('jack', _ -> {
      name: 'Jack',
      email: 'jack@example.com',
    });

    @await tracker.issues.set('1', _ -> {
      title: 'Something is broken!',
      description: 'Please Help!!1!!11!!',
      reporter: 'john',
      assignee: 'jack',
      open: true,
      priority: 9999,
      comments: [],
    });

    @await tracker.issues.set('1', issue -> issue.patch({
      open: false,
      comments: issue.comments.concat(["This is not helpful."])
    }));
  }
}
```