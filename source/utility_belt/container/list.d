/** Double or singly-link list structure with niceties.

    Many Θ(n) operations don't need to be; we trade a bit of RAM for performance.

    The API mostly follows the Phobos containers as documented at
    https://dlang.org/phobos/std_container.html
*/
module utility_belt.container.list;

// TODO: Allow opt-in to indexing (keep track of nodes via rbtree or something).

// Convenience aliases:
alias SList(T) = List!(T, Link.Single);
alias DList(T) = List!(T, Link.Double);

enum Link {
    Single,
    Double
}

struct List(T, Link link = Link.Single) {
    alias Node = ListNode!(T, link);

    @disable this();

    // Θ(1)
    this(T t) {
        root = new Node(t);
        last = root;
        len = 1;
    }

    // Θ(n)
    this(T...)(T ts)
        in(ts.length > 0)
    {
        if (root is null) {
            root = new Node(ts[0]);
            last = root;
            len = 1;
        }

        foreach (t; ts[1..$]) {
            insertBack(t);
        }
    }

    // Θ(n)
    auto dup() {
        import std.algorithm.iteration : each;
        auto elems = this[];
        auto newList = typeof(this)(elems.moveFront());
        elems.each!((elem) { newList.insertBack(elem); });
        return newList;
    }

    // Θ(1)
    auto opOpAssign(string op)(T t) if (op == "~") {
        insertBack(t);
        return this;
    }
    auto opBinary(string op)(T t) if (op == "~") {
        insertBack(t);
        return this;
    }
    auto opBinaryRight(string op)(T t) if (op == "~") {
        insertFront(t);
        return this;
    }

    // Θ(1)
    auto opOpAssign(string op)(typeof(this) other) if (op == "~")
        in(other.last.next is null)
        in(last.next is null)
        in(len + other.len > len)
    {
        last.next = other.root;
        static if (link == Link.Double) {
            other.root.prev = last;
        }
        last = other.last;
        len += other.len;
        return this;
    }
    auto opBinary(string op)(typeof(this) other) if (op == "~")
        in(other.last.next is null)
        in(last.next is null)
        in(len + other.len > len)
    {
        last.next = other.root;
        static if (link == Link.Double) {
            other.prev = last;
        }
        last = other.last;
        len += other.len;
        return this;
    }

    // Θ(n[added-elems])
    auto opOpAssign(string op)(T[] ts) if (op == "~") {
        foreach (t; ts) {
            insertBack(t);
        }
        return this;
    }
    auto opBinary(string op)(T[] ts) if (op == "~") {
        foreach (t; ts) {
            insertBack(t);
        }
        return this;
    }
    auto opBinaryRight(string op)(T[] ts) if (op == "~") {
        foreach_reverse (t; ts) {
            insertFront(t);
        }
        return this;
    }

    auto opSlice() { return Range(root); }
    auto range() { return Range(root); }

    static if (link == Link.Double) {
        auto reverseRange() { return ReverseRange(last); }
    }

    // Θ(1)
    @property bool empty() { return len == 0; }

    // Θ(1)
    @property size_t length() { return len; }

    // Θ(1)
    @property ref T front() { return root.data; }

    // Θ(1)
    @property void front(scope ref T t) { root.data = t; }

    // Θ(1)
    ref T moveFront()
    {
        auto tmp = root;
        root = root.next;
        static if (link == Link.Double) {
            root.prev = null;
        }
        --len;
        return tmp.data;
    }

    // Θ(1)
    @property
    ref T back() {
        return last.data;
    }

    // Θ(1)
    @property
    void back(T t) {
        last.data = t;
    }

    static if (link == Link.Double) {
        // Θ(1)
        ref T moveBack()
            in(last.prev !is null)
        {
            auto n = last;
            last = last.prev;
            last.next = null;
            --len;
            return n.data;
        }
    }

    // Θ(1)
    void clear() {
        len = 0;
        Node root = null;
        Node last = null;
    }

    // Θ(1)
    void insert(T t) {
        insertFront(t);
    }

    // Θ(1)
    auto removeAny() {
        return removeFront();
    }

    // Θ(1)
    void insertFront(T t) {
        static if (link == Link.Single) {
            root = new Node(t, root);
        } else {
            root = new Node(t, null, root);
            root.next.prev = root;
        }
        ++len;
    }

    // Θ(1)
    void insertBack(T t) {
        if (this.empty()) {
            root = new Node(t);
            last = root;
            len = 1;
        } else {
            assert(last.next is null);
            static if (link == Link.Single) {
                last.next = new Node(t);
            } else {
                last.next = new Node(t, last, null);
            }
            last = last.next;
            ++len;
        }
    }

    // Θ(1)
    void removeFront() {
        root = root.next;
        static if (link == Link.Double) {
            root.prev = null;
        }
        --len;
    }

    static if (link == Link.Double) {
        // Θ(1)
        void removeBack() {
            last.prev.next = null;
            --len;
        }
    }

    // Phobos: remove a range; us: remove the first instance of the element (or all occurrences).
    // Up to Θ(n)
    void remove(T t, bool removeAll = false) { // TODO: use Flag
        while (front() == t) {
            removeFront();
            if (! removeAll) return;
        }

        auto previous = root;
        while (previous.next !is null) {
            if (previous.next.data == t) {
                previous.next = previous.next.next;
                static if (link == Link.Double) {
                    if (previous.next !is null)
                        previous.next.prev = previous;
                }
                --len;
                if (! removeAll) return;
            } else previous = previous.next;
        }
    }

    private:

    size_t len = 0;
    Node root; invariant(root !is null);
    Node last; invariant(last !is null);

    struct Range {
        this(scope ref Node root) { this.root = root; }

        @property T front() { return root.data; }
        @property bool empty() { return root is null; }
        void popFront() { root = root.next; }

        T moveFront() {
            auto t = front();
            popFront();
            return t;
        }

        private:
        Node root;
    }

    struct ReverseRange {
        this(scope ref Node last) { this.last = last; }

        @property T front() { return last.data; }
        @property bool empty() { return last is null; }
        void popFront() { last = last.prev; }

        T moveFront() {
            auto t = front();
            popFront();
            return t;
        }

        private:
        Node last;
    }
}

private:

final class ListNode(T, Link link = Link.Single) {
    static if (link.Double) {
        typeof(this) prev = null;
    }
    typeof(this) next = null;
    T data;

    this(scope ref T t) { data = t; }

    static if (link == Link.Single) {
        this(scope ref T t, typeof(this) next) {
            data = t;
            this.next = next;
        }
    } else {
        this(scope ref T t, typeof(this) prev, typeof(this) next) {
            data = t;
            this.prev = prev;
            this.next = next;
        }
    }
}
