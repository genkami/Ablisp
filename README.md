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
The first word is a *type tag* which indicates a type of an object (which is one of `num`, `text`, `symbol`, `t`, `nil`, or `cons`), and the rest two words represent their actual value (values for `num` and `text`, pointers of child elements for `cons`, etc.).

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

Amber somehow does not support recursive functions, even though the compiler's target language (bash script) does support it.

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
            ...
            callstack_push(ok_val(result))
            continue
        }
        ...
        if is_list_begin() {
            ...
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

#### Problem

There's no way for Amber programs to assign functions to variables.

```
fun incr(x: Num): Num {
    return x + 1
}

// ERROR: Variable 'incr' does not exist
let f = incr
echo f(3)
```

Amber functions are compiled into Bash functions, so theoretically it's possible to call arbitrary functions once we can get their names in compiled Bash scripts. But Amber does not provide a way to do it.

Furthermore, even if we can get the functions' real names in compiled Bash scripts, we still can't call them.
This is because Amber does not have a unified calling convention.

For example, consider the following Amber code:

```
fun first(list: [Num]): Num {
    return list[0]
}
let list = [1, 2, 3]
echo first(list) //=> 1
```

This compiles into the following Bash script:

```
function first__0_v0 {
    local list=("${!1}")
    __AF_first0_v0="${list[0]}";
    return 0
}
__AMBER_ARRAY_0=(1 2 3);
__0_list=("${__AMBER_ARRAY_0[@]}")
first__0_v0 __0_list[@];
__AF_first0_v0__5=$__AF_first0_v0;
echo $__AF_first0_v0__5
```

Here, the Amber function `first` compiles into a Bash function `first__0_v0`, which takes arguments via command-line arguments, and returns the result via a global variable `__AF_first0_v0`.

The problem here is that we can't know where the return value is after calling an arbitrary function.

To describe the problem, assume that we can somehow get a Bash function name of an Amber function.
We can call it by using the [command statement](https://docs.amber-lang.com/basic_syntax/commands).

For example, the previous `first` example can be written in the following way using the command statement:

```
fun first(list: [Num]): Num {
    return list[0]
}
let list = [1, 2, 3]

// NOTE:
// - `$..$` executes arbitrary Bash scripts
// - `unsafe` ignores command results
// - `nameof X` returns the Bash variable name of an amber variable X (X can't be a function)
unsafe $first__0_v0 {nameof list}[@]; echo \$__AF_first0_v0$ //=> 1
```

Now we know that the return value is stored in `$__AF_first0_v0`, so we used that variable name to get the return value.
But how can we know where the return values are stored in general?

In summary, there are two problems that prevents us from having first-class functions in Amber:
- There's no way to either assign a function to a variable, or get a function name in a compiled Bash script.
- Even if we can assign a function to a variable and call it, there's no way to get a return value in general.

#### Solution

To solve the two problems above, I first addresed the problem with return values.

Instead of writing Amber functions like this:

```
fun incr(x: Num): Num {
    return x + 1
}
```

I wrote the functions in the following way:

```
fun incr(): Null {
    let args = get_args()       // args is Result<Pair, Error>
    if result_is_error(args) {
        return null
    }
    let x = cons_car(args)      // get the first argument
    // allocates a new object in the "heap" (or a large Bash array) and stores the result
    let xplus1 = new_num(num_value(x) + 1)
    set_return_value(new_ok(xplus1))
    return null
}
```

where `get_args()` and `set_return_value` passes values to/from functions via a single global variable.

```
// Note again that [Text] is Result<*Object, Error> in Ablisp.
pub fun get_args(): [Text] {
    let args = _funcall_args
    _funcall_args = -1                 // invalidate
    _funcall_retval = default_retval() // invalidate
    return new_ok(args)
}

pub fun set_return_value(result: [Text]): Null {
    _funcall_retval = result
}
```

In this way, Amber functions can follow the same calling convention, although they look a bit ugly.

Now that we solved the issue with calling conventions, it's time to consider how to get a function as a value.

I found that there is a way to get a function name without guessing how the compiler works.
This can be done using a special Bash variable called [FUNCNAME](https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html#index-FUNCNAME).
According to the document, this variable contains "the names of all shell functions currently in the execution call stack".
That means if we can call a function, we can get its name.

But now the next problem arises: How can we call a function before it's actually needed?

To address this question, let's closely take a look at the function definition again:

```
fun incr(): Null {
    let args = get_args()       // args is Result<Pair, Error>
    if result_is_error(args) {
        return null
    }
    ...
}
```

The first several lines show that if `get_args` can return error when we just want to get a function name, we can call the function without actually executinhg the function body.

So I updated `get_args` and added some other functions so that we can call a function to get its name without any side effects.

```
pub fun track_next_funcall(): Null {
    _should_track_next_funcall = true
}

pub fun get_last_funcref(): Text {
    return _last_funcref
}

pub fun get_args(): [Text] {
    if _should_track_next_funcall {
        _should_track_next_funcall = false
        // $FUNCNAME[1] contains the name of the caller
        _last_funcref = unsafe $echo "\$\{FUNCNAME[1]}"$
        return new_err("native_function_tracked", "the function call is tracked")
    }
    ...
    let args = _funcall_args
    ...
    return new_ok(args)
}
```

With these three functions, we can finally get the name of a function:

```
let funcref_incr = "" // pointer to incr

fun incr(): Null {
    let args = get_args()       // args is Result<Pair, Error>
    if result_is_error(args) {
        return null
    }
    ...
}

track_next_funcall()
incr() // returns immediately without doing anything
funcref_incr = get_last_funcref() // returns $FUNCNAME[1] stored in the previous call
```

and call such functions using the "funcref"s:

```
pub fun call_function(funcref: Text, args: Num): [Text] {
    ...
    _funcall_args = args
    ...
    unsafe ${funcref}$   // call a Bash function by its name
    let result = _funcall_retval
    ...
    return result
}

let args = new_cons(new_num(123), new_nil()) // args = [123]
let result = call_function(incr, args)       // returns ok(124)
echo num_value(ok_val(result))               //=> 124
```

Furthermore, having a function reference also helped writing recursive functions:

```
let funcref_fibonacci = "" // defined later

fun fibonacci(): Null {
    let result_args = get_args()
    if result_is_err(result_args) { ... }
    let args = ok_val(result_args)
    let n = num_value(cons_car(args))    // get the first arg
    if n == 1 or n == 2 {
        set_return_value(new_ok(new_num(1)))
        return null
    }

    // call fibonacci(n - 1) recursively
    let args_a = new_cons(new_num(n - 1), new_nil())
    let a = call_function(funcref_fibonacci, args_a)

    // call fibonacci(n - 2) recursively
    let args_b = new_cons(new_num(n - 2), new_nil())
    let b = call_function(funcref_fibonacci, args_b)

    let result = num_value(ok_val(a)) + num_value(ok_val(b))
    set_return_value(new_ok(result))
    return null
}

// initialize funcref to fibonacci
track_next_funcall()
fibonacci()                // stores a funcref and returns immediately
funcref_fibonacci = get_last_funcref()
```

With this way to solve the recursion problem, I was finally able to write a complex recursive functions like `eval_expr()`.

---

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
