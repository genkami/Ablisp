TEST_AMBER_FILES := $(wildcard src/*_test.ab)
TEST_BASH_FILES := $(patsubst src/%.ab, out/%.bash, $(TEST_AMBER_FILES))

.PHONY: all
all: out/ablisp $(TEST_BASH_FILES)

.PHONY: docs
docs: docs/corelib.md

out/ablisp: src/*.ab
	mkdir -p out
	amber ./src/ablisp.ab ./out/ablisp

out/%_test.bash: src/%_test.ab src/*.ab
	mkdir -p out
	amber $< $@

docs/corelib.md: out/ablisp examples/gen-corelib-doc.lisp
	./out/ablisp examples/gen-corelib-doc.lisp > $@

.PHONY: clean
clean:
	rm -rf out

.PHONY: test
test: $(TEST_BASH_FILES)
	./test.bash
