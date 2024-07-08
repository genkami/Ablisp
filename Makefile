out/ablisp: src/*.ab
	mkdir -p out
	amber ./src/ablisp.ab ./out/ablisp

.PHONY: clean
clean:
	rm -rf out

.PHONY: test
test:
	amber ./src/test.ab
