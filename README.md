# Ablisp

Ablisp is a Lisp-like language written in [amber-lang/amber](https://github.com/amber-lang/amber).

* [Build](#build)
* [Usage](#usage)
* [Examples](#examples)
* [Documentation](#documentation)

---

## Why I made this
I just wanted to know the basic syntax and features of Amber, and I thought writing lisp interpreter is a good way to do it.

Usually, it takes only several hundred lines of code to implement a minimal Lisp interpreter.
In addition to that, I've made several Lisp interpreters in the last couple of years for learning purpose, so I'm kind of used to implement small interpreters.

For those reasons, I thought it would take just a few hours to write a new one even in a language that I'm not familiar with, which turned out to be completely wrong.

## What makes it difficult to write a Lisp interpreter in Amber?

:rotating_light: *Disclaimer: I don't mean to criticize Amber. I just used Amber in a wrong way.*

### No recursive data structures

#### Problem

There's no such thing as a recursive data structure in Amber. There's not even a multi-dimensional array or a simple struct.

```
// OK
let nums = [1, 2, 3]

// ERROR: Arrays cannot be nested due to the Bash limitations
let nested = [[1, 2], [3, 4]]

// ERROR: Expected array value of type 'Num'
let hetero = [1, "a", true]
```

However, recursive data structure is one of the essential part of Lisp because most of the data in Lisp are represented as nested cons cells (or pairs of pointers in other languages).

```lisp
; nums is like `&Pair{ first = 1, second = &Pair{ first = 1, second = &Pair{ first = 3, second = null }}}` in other languages.
(def nums '(1 2 3))
```

#### Solution

I ended up encoding every Lisp object in a single, large array of texts.

```
// src/object.ab
let the_memory = [Text]
...
fun put_object(i: Num, tag: Num, val1: Text, val2: Text): Null {
    the_memory[3 * i] = tag as Text
    the_memory[3 * i + 1] = val1
    the_memory[3 * i + 2] = val2
}
```

Each Ablisp object consists of three words (NOTE: they are literally "words" because of an internal representation of Amber arrays).
The first word is a *type tag* which indicates a type of object (which is one of `num`, `text`, `symbol`, `t`, `nil`, or `cons`), and the rest two words represents their actual value (values for `num` and `text`, pointers of child elements for `cons`, etc.).

So, for example, Ablisp objects are encoded into the following Amber array:

```
the_memory = [
    "0", "123", "",        // tag: num, value: 123
    "1", "hello", "",      // tag: text, value: "hello"
    "6", "123", "456",     // tag: cons, value: pointers to the 123rd and 456th objects in the memory
]
```

And of cource, I had to implement a simple garbage collection on that array.

### No recursion

#### Problem

```
fun fibonacci(i: Num): Num {
    if i == 0 or i == 1 {
        return 1
    } else {
        // ERROR: Function 'fibonacci' does not exist
        let a = fibonacci(i - 1)
        let b = fibonacci(i - 2)
        return a + b
    }
}
```

Amber somehow does not support recursive functions, even though the compiler's target language (bash script) does support it.

This is a big pain point for developing interpreters, because programming languages in general are recursive by nature.

#### Solution

I had to convert most of the algorithms into iterative ones using stack.

```
// NOTE: `Num` means `*Object` and `[Text]` means `Result<*Object, Error>` in Ablisp.
pub fun parse_sexp(): [Text] {
    let stack_base = callstack_current_sp() // like `mov rbp, rsp`
    loop {
        ...
        if is_number_begin() {
            let result = consume_number()
            if result_is_err(result) {
                last_error = result
                break
            }
            callstack_push(ok_val(result))
            continue
        }
        ...
        if is_list_begin() {
            consume_next()
            callstack_push(list_start)
            continue
        }
        ...
        if is_list_end() {
            ...
            loop {
                let top = callstack_pop()
                if top == list_start {
                    break
                }
                ...
                list = new_cons(top, list)
                ...
            }
            ...
            callstack_push(list)
            continue
        }
        ...
    }
    ...
    if result_is_err(last_error) {
        callstack_rewind(stack_base) // like `mov rsp, rbp`
        return last_error
    }
    ...
    let last_value = callstack_pop()
    ...
    return new_ok(last_value)
}
```

After that, I realized that I can bypass the restriction by getting a "pointer" of Amber functions. I'll describe it more deeply in the next section.

### No first-class functions



## Build
You can use a precompiled interpreter by copying `out/ablisp` to somewhere in you `$PATH`.

If you want to build ablisp yourself, you have to install [Amber v0.3.3](https://github.com/amber-lang/amber/releases/tag/0.3.3-alpha) and run the following command to build.

```
$ make out/ablisp
```


## Usage

```
$ ./out/ablisp ./examples/hello.lisp
Hello, world!
```

or

```
$ ./out/ablisp -c '(echo "Hello, world!")'
```

It's TOO slow. It takes around 50s to run a hello world on my laptop, but it works anyway.

## Examples

See [examples](https://github.com/genkami/Ablisp/tree/main/examples) and [Corelib documentation](./docs/corelib.md).

## Documentation

See the [language documentation](./docs/language.md).
