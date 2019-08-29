module test.utility_belt.ini;

import utility_belt.trace : trace;
import utility_belt.ini;

@("IniConfig reads variable/value pairs")
unittest {
    auto config = iniConfig("var=value\nvar2=other value");

    assert(config["var"] == "value");
    assert(config["var2"] == "other value");
}

@("IniConfig allows the '=' symbol in values")
unittest {
    auto config = iniConfig("var=value\nvar2=other= value");

    assert(config["var"] == "value");
    assert(config["var2"] == "other= value");
}

@("IniConfig supports line comments via the ';' character")
unittest {
    auto config = iniConfig("var=value\n; Ignore this line.\nvar2=other value");

    assert(config["var"] == "value");
    assert(config["var2"] == "other value");
}

@("IniConfig does not treat ';' as a comment if not at beginning of line")
unittest {
    auto config = iniConfig("var=value\nvar2=other;value");

    assert(config["var"] == "value");
    assert(config["var2"] == "other;value");
}

@("IniConfig supports section groups")
unittest {
    auto config = iniConfig("var=value\n[Group 1]\nvar2=other value");

    assert(config["var"] == "value");
    assert(config["DEFAULT", "var"] == "value");
    assert(config["Group 1", "var2"] == "other value");
}

@("IniConfig allows blank lines")
unittest {
    auto config = iniConfig("var=value\n\nvar2=other value");

    assert(config["var"] == "value");
    assert(config["var2"] == "other value");
}

@("IniConfig ignores preceding whitespace")
unittest {
    auto config = iniConfig("var=value\n    [Group 1]\n    var2=other value");

    assert(config["var"] == "value");
    assert(config["DEFAULT", "var"] == "value");
    assert(config["Group 1", "var2"] == "other value");
}

@("IniConfig uses the last duplicate value in a section")
unittest {
    auto config = iniConfig("var=value\nvar=other value");
    assert(config["var"] == "other value");
}

@("IniConfig does not overwrite duplicate variables in different sections")
unittest {
    auto config = iniConfig("var=value\n[Group 1]\nvar=other value");

    assert(config["DEFAULT", "var"] == "value");
    assert(config["Group 1", "var"] == "other value");
}

@("IniConfig allows alternate assignment symbols")
unittest {
    auto config = IniConfig!':'("var:value\n\nvar2:other value");

    assert(config["var"] == "value");
    assert(config["var2"] == "other value");
}

@("IniConfig reads settings from a file.")
unittest {
    import std.stdio : File;
    auto config = iniConfig(File("test/test.ini"));

    assert(config["var1"] == "val1");
    assert(config["Group A", "var2"] == "value two");
}

@("Read an ini file at compile-time")
unittest {
    import std.stdio : File;
    enum config = iniConfig(import("test.ini"));

    assert(config["var1"] == "val1");
    assert(config["Group A", "var2"] == "value two");
}

@("Merge two runtime ini files together")
unittest {
    auto defconfig = iniConfig("var1=val1\n[Group A]\nvar2 = value two\n");
    auto config = iniConfig("newvar=newval\n[Group A]\nvar2 = new value\n")
                    .withDefaults(defconfig);

    assert(config["var1"] == "val1");
    assert(config["newvar"] == "newval");
    assert(config["Group A", "var2"] == "new value");
}

@("Merge a compiletime and runtime configuration")
unittest {
    import std.stdio : File;
    enum ctconfig = iniConfig(import("test.ini"));

    auto config = iniConfig("newvar=newval\n[Group A]\nvar2 = new value\n")
                    .withDefaults(ctconfig);

    assert(config["var1"] == "val1");
    assert(config["newvar"] == "newval");
    assert(config["Group A", "var2"] == "new value");
}
