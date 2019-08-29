# utility_belt

This is a collection of code I commonly use that doesn't really justify an
independent life.

Each module is independent of the rest; though trace.d may be a dependency of
any of the others at any given time.

Very short code examples are below; the tests show a more complete picture.

* [container/list.d](#listd): Single/Double-linked list
    * Θ(1) length() property and last-node removal.
    * The List maintains control of the nodes; it's fine for stacks and queues
      but if you need access to the nodes, not just the data, you don't want
      this.
* [ini.d](#inid): Compile-time/runtime INI parser.
    * Easy merging of compile-time and runtime settings.
* [trace.d](#traced): simple debug-only trace function.

## list.d

```d
auto single = SList!int(1, 2, 3);
auto double_ = DList!int(2, 3, 4);

single ~= [4, 5, 6];
assert(single.back() == 6);
```

## ini.d

```d
// Grab compile-time settings; merge with other settings at runtime:
auto defaultConfig = iniConfig(import("defaults.ini"));

auto config = iniConfig(File("my.ini"))
                .withDefaults(defaultConfig);

// Or you can do:
auto config = iniConfig("var=value;var2=value2");
// Other separators:
auto config!':'("var:value;var2:value2");
```

## trace.d

```d
void func1(int a, string b, bool c) {
    trace();
    // prints: *trace: module.func1
}

void func2(int a, string b, bool c) {
    trace("a: ", a, ", b: ", b, ", c": c);
    // If called as func2(1, "b", false),
    // prints: *trace: module.func2- a: 1, b: 2, c: false
}
```
