module test.utility_belt.container.list;

import std.conv : text;
import utility_belt.container.list;

@("Create SList with one element")
unittest {
    auto l = List!int(5);
    assert(l.front() == 5, l.front().text);
    assert(l.length() == 1);
}

@("Create SList with multiple elements")
unittest {
    auto l = List!int(5, 6, 7);
    assert(l.length() == 3, l.length().text);
    assert(l.back() == 7, l.back().text);
    assert(l.moveFront() == 5, l.front().text);
    assert(l.moveFront() == 6, l.front().text);
    assert(l.front() == 7, l.front().text);
    assert(l.length() == 1, l.length().text);
}

@("Duplicate a list")
unittest {
    auto l1 = List!int(1, 2, 3);
    auto l2 = l1.dup();
    l1.front = 5;
    assert(l2.moveFront() == 1);
    assert(l2.moveFront() == 2);
    assert(l2.front() == 3);
}

@("Iterate over elements via a range")
unittest {
    auto l = List!int(1, 2, 3);
    auto r = l[];
    assert(r.moveFront() == 1);
    assert(r.moveFront() == 2);
    assert(r.moveFront() == 3);
    assert(r.empty());
    assert(l.length == 3);
}

@("Modify the first element")
unittest {
    auto l1 = List!int(5);
    l1.front = 6;
    assert(l1.front() == 6, l1.front().text);

    class C { string s; this(string t) { s = t; } }
    auto l2 = List!C(new C("a"));
    l2.front = new C("b");
    assert(l2.front.s == "b", l2.front.s);
}

@("Modify the last element")
unittest {
    auto l = List!int(5, 6, 7);
    l.back = 1;
    assert(l.back() == 1);
}

@("Insert a node at the front")
unittest {
    auto l = List!int(5);
    l.insertFront(6);
    assert(l.front() == 6, l.front().text);
    assert(l.back() == 5, l.back().text);
    assert(l.length() == 2, l.length().text);
}

@("Concatenate an element")
unittest {
    auto l = List!int(3);
    l ~= 5;
    assert(l.length() == 2);
    assert(l.front() == 3);
    assert(l.back() == 5);

    l = 4 ~ l;
    assert(l.length() == 3);
    assert(l.front() == 4);
}

@("Concatenate a range of elements")
unittest {
    auto l = List!int(3);
    l ~= [5, 6, 7];
    assert(l.length() == 4);
    assert(l.front() == 3);
    assert(l.back() == 7);

    l = [4, 2, 1] ~ l;
    assert(l.length() == 7);
    assert(l.front() == 4, l.front().text);
}

@("Concatenate another list")
unittest {
    auto l = List!int(2, 3);
    auto l2 = List!int(4, 5);

    l ~= l2;
    assert(l.length() == 4, l.length().text);
    assert(l.front() == 2, l.front().text);
    assert(l.back() == 5, l.back().text);

    auto l3 = List!int(9, 8);
    l = l3 ~ l;
    assert(l.length() == 6);
    assert(l.front() == 9);
}

@("Remove the first occurence of an element")
unittest {
    auto l = List!int(1, 2, 3, 2, 3, 2);
    l.remove(2);
    assert(l.length() == 5, l.length().text);
    assert(l.moveFront() == 1);
    assert(l.moveFront() == 3);
    assert(l.moveFront() == 2);
    assert(l.moveFront() == 3);
    assert(l.front() == 2);
}

@("Remove all occurrences of an element")
unittest {
    auto l = List!int(2, 1, 2, 3, 2, 3, 2);
    l.remove(2, true);
    assert(l.length() == 3);
    assert(l.moveFront() == 1);
    assert(l.moveFront() == 3);
    assert(l.front() == 3);
}
