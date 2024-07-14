#!/bin/bash -eu

pids=()
testcases=()
results=()
for testcase in ./out/*_test.bash; do
    bash "$testcase" &
    pids+=($!)
    testcases+=("$testcase")
    results+=("UNKNOWN")
done

num_failed=0

for ((i=0; i<${#pids[@]}; i++)); do
    pid=${pids[$i]}
    wait $pid
    if [[ $? -eq 0 ]]; then
        results[$i]="PASS"
    else
        results[$i]="FAIL"
        let num_failed++
    fi
done

for ((i=0; i<${#pids[@]}; i++)); do
    echo -e "${results[$i]}\t${testcases[$i]}"
done

if [[ $num_failed -gt 0 ]]; then
    echo "$num_failed out of ${#pids[@]} tests failed"
    exit 1
fi
