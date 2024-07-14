TEST_AMBER_FILES := $(wildcard src/*_test.ab)
TEST_BASH_FILES := $(patsubst src/%.ab, out/%.bash, $(TEST_AMBER_FILES))

.PHONY: all
all: out/ablisp $(TEST_BASH_FILES)

out/ablisp: src/*.ab
	mkdir -p out
	amber ./src/ablisp.ab ./out/ablisp

out/%_test.bash: src/%_test.ab
	mkdir -p out
	amber $< $@

.PHONY: clean
clean:
	rm -rf out

.PHONY: test
test: $(TEST_BASH_FILES)
	./test.bash
