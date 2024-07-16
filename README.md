# Ablisp

Ablisp is a Lisp-like language written in [amber-lang/amber](https://github.com/amber-lang/amber).

* [Build](#build)
* [Usage](#usage)
* [Examples](#examples)
* [Documentation](#documentation)

---

## Why I made this
I just wanted to know the basic syntax and features of Amber, and I thought writing lisp interpreter is a good way to do it.
Usually, it takes only several hundreds of lines of code to implement a minimal Lisp interpreter.
In addition to that, I've made several Lisp interpreters in the last couple of years for learning purpose.
So I thought it takes just a few hours to write a new one even in a language that I'm not familiar with, which turned out to be completely wrong.

## What makes it difficult to write a Lisp interpreter in Amber?

*Disclaimer: I don't mean to criticize Amber. I just used Amber in a wrong way.*

### No recursive data structures

### No recursion

### Lack of first-class functions

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
