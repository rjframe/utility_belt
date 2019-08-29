/** Provide compile-time and runtime parsing of INI files. */
module utility_belt.ini;

import std.exception : enforce;
import std.stdio : File;

auto iniConfig(File file) {
    return IniConfig!'='(file);
}

auto iniConfig(string configText) {
    return IniConfig!'='(configText);
}

struct IniConfig(char assignmentSymbol = '=') {
    import std.stdio : File;

    this(File file) {
        parseIni(file.byLineCopy());
    }

    this(string configText) {
        import std.string : lineSplitter;
        parseIni(lineSplitter(configText));
    }

    auto opIndex(string variable) {
        return values["DEFAULT"][variable];
    }

    auto opIndex(string group, string variable) {
        return values[group][variable];
    }

    private:

    alias ValuePair = string[string];
    ValuePair[string] values; // Key: group name.

    import std.traits : isArray;
    import std.range.primitives : isInputRange;
    void parseIni(R)(R configText)
            if (isInputRange!R && isArray!(typeof(configText.front()))) {

        string currentGroup = "DEFAULT";
        foreach (line; configText) {
            import std.algorithm.mutation : strip;
            import std.meta : AliasSeq;
            import std.uni : isWhite;

            line = line.strip!isWhite();
            if (line.length == 0 || line[0] == ';')
                continue;
            else if (line [0] == '[') {
                if (line[$-1] != ']')
                    throw new Exception("Invalid group name: " ~ line);
                currentGroup = line[1..$-1];
            } else {
                string variable, value;
                AliasSeq!(variable, value) = getValuePair(line);

                // DMD 2.083.0 (at least) won't do the first at runtime.
                // DMD 2.081.1 to at least 2083.0 segfault on the second.
                if (__ctfe) {
                    values[currentGroup] = [variable: value];
                } else {
                    values[currentGroup][variable] = value;
                }
            }
        }
    }

    auto getValuePair(string line)
        in(line.length > 1)
    {
        foreach (i, ch; line) {
            if (ch == assignmentSymbol) {
                enforce(line.length > i, "No right-hand side of assignment.");
                import std.string : strip;
                import std.typecons : tuple;
                return tuple(line[0..i].strip(), line[i+1..$].strip());
            }
        }
        throw new Exception("Expected variable/value pair; received: " ~ line);
    }

    auto settingsUnder(string group) {
        return values[group].keys();
    }
}

T withDefaults(T)(T thisConfig, T defaultConfig)
        if (is(T == IniConfig!C, char C)) {

    T completeConfig = defaultConfig;
    foreach (group, valuePairs; thisConfig.values) {
        foreach (key, value; valuePairs) {
            completeConfig.values[group][key] = value;
        }
    }
    return completeConfig;
}

