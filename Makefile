.PHONY: all
all: out/ablisp out/test

out/ablisp: src/*.ab
	mkdir -p out
	amber ./src/ablisp.ab ./out/ablisp

out/test: src/*.ab
	mkdir -p out
	amber ./src/test.ab ./out/test

.PHONY: clean
clean:
	rm -rf out

.PHONY: test
test: out/test
	./out/test
