/** Double or singly-link list structure with niceties.

    Many Θ(n) operations don't need to be; we trade a bit of RAM for performance.

    The API mostly follows the Phobos containers as documented at
    https://dlang.org/phobos/std_container.html
*/
module utility_belt.container.list;

// TODO: Allow opt-in to indexing (keep track of nodes via rbtree or something).

// Convenience aliases:
alias SList(T) = List(T, Link.Single);
alias DList(T) = List(T, Link.Double);

enum Link {
    Single,
    Double
}

struct List(T, Link link = Link.Single) {
    alias Node = ListNode!(T, link);

    // Θ(1)
    this(T t) {
        root = new Node(t);
        last = root;
        len = 1;
    }

    // Θ(n)
    this(T...)(T ts) {
        foreach (node; ts) {
            insertBack(node);
        }
    }

    // Θ(n)
    auto dup() {
        auto newList = typeof(this)();
        foreach (elem; this[]) {
            newList.insertBack(elem);
        }
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

    // Θ(1)
    @property bool empty() { return len == 0; }

    // Θ(1)
    @property size_t length() { return len; }

    // Θ(1)
    @property ref T front() { return root.data; }

    // Θ(1)
    @property void front(scope ref T t) { root.data = t; }

    // Θ(1)
    ref T moveFront() {
        auto tmp = root;
        root = root.next;
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
        // SList: Θ(n-1) , DList: Θ(1)
        // SList could be Θ(1) if repl w/ empty node so prev doesn't need to be
        // touched; may not be worth the extra bookkeeping.
        ref T moveBack() {
            assert(0, "implement");
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
        auto newRoot = new Node(t, root);
        root = newRoot;
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
            last.next = new Node(t);
            last = last.next;
            ++len;
        }
    }

    // Θ(1)
    void removeFront() {
        root = root.next;
        --len;
    }

    static if (link == Link.Double) {
        // Θ(1)
        void removeBack() {
            assert(0, "implement");
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
                --len;
                if (! removeAll) return;
            } else previous = previous.next;
        }
    }

    private:

    size_t len = 0;
    Node root;
    Node last;

    // TODO: DList ReverseRange
    struct Range {
        this(ref Node root) { this.root = root; }

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
}

private:

final class ListNode(T, Link link = Link.Single) {
    static if (link.Double) {
        typeof(this) prev = null;
    }
    typeof(this) next = null;
    T data;

    static if (link == Link.Single) {
        this(ref T t) { data = t; }

        this(ref T t, ref typeof(this) next) {
            data = t;
            this.next = next;
        }
    } else {
        this(ref T t, ref typeof(this) prev) {
            data = t;
            this.prev = prev;
            this.next = next;
        }

        this(ref T t, ref typeof(this) prev, ref typeof(this) next) {
            data = t;
            this.prev = prev;
            this.next = next;
        }
    }
}
