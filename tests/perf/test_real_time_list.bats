#!/usr/bin/env bats

load ../helpers/helper_setup
load ../helpers/helper_measure
load ../helpers/constants

setup() { setup_common; }
teardown() { teardown_common; }

@test "star list - 5 bookmarks" {
    mkdir "$TEST_ROOT/a"
    mkdir "$TEST_ROOT/b"
    mkdir "$TEST_ROOT/c"
    mkdir "$TEST_ROOT/d"
    mkdir "$TEST_ROOT/e"

    star add "$TEST_ROOT/a"
    star add "$TEST_ROOT/b"
    star add "$TEST_ROOT/c"
    star add "$TEST_ROOT/d"
    star add "$TEST_ROOT/e"

    local times=()
    local i=0

    while [[ $i -lt $BTE_ITER_LIST ]]; do
        elapsed=$(time_exec star list)
        times+=("$elapsed")
        i=$((i+=1))
    done

    local mn=$(min "${times[@]}")
    local mx=$(max "${times[@]}")
    local avg=$(mean "${times[@]}")

    printf "%-10s %-15s %-15s %-15s\n" "Metric" "Value" "Threshold" "Pass?" >&3
    printf "%-10s %-15s %-15s %-15s\n" "min" "${mn}ms" "-" "-" >&3
    printf "%-10s %-15s %-15s %-15s\n" "max" "${mx}ms" "${BTE_STAR_LIST_MAX}ms" \
        $([ "$mx" -le "$BTE_STAR_LIST_MAX" ] && echo "✓" || echo "✗") >&3
    printf "%-10s %-15s %-15s %-15s\n" "mean" "${avg}ms" "${BTE_STAR_LIST_MAX}ms" \
        $([ "$avg" -le "$BTE_STAR_LIST_MAX" ] && echo "✓" || echo "✗") >&3
    printf "%-10s %-15s %-15s %-15s\n" "diff" "$((mx - mn))ms" "${BTE_STAR_LIST_MIN_MAX_DIFF}ms" \
        $([ "$((mx - mn))" -le "$BTE_STAR_LIST_MIN_MAX_DIFF" ] && echo "✓" || echo "✗") >&3

    [ "$mx" -le "$BTE_STAR_LIST_MAX" ]
    [ "$avg" -le "$BTE_STAR_LIST_MAX" ]
    [ "$((mx - mn))" -le "$BTE_STAR_LIST_MIN_MAX_DIFF" ]
}

@test "star list - 10 bookmarks" {
    mkdir "$TEST_ROOT/a"
    mkdir "$TEST_ROOT/b"
    mkdir "$TEST_ROOT/c"
    mkdir "$TEST_ROOT/d"
    mkdir "$TEST_ROOT/e"
    mkdir -p "$TEST_ROOT/f/g/h/i/j"

    star add "$TEST_ROOT/a"
    star add "$TEST_ROOT/b"
    star add "$TEST_ROOT/c"
    star add "$TEST_ROOT/d"
    star add "$TEST_ROOT/e"
    star add "$TEST_ROOT/f"
    star add "$TEST_ROOT/f/g"
    star add "$TEST_ROOT/f/g/h"
    star add "$TEST_ROOT/f/g/h/i"
    star add "$TEST_ROOT/f/g/h/i/j"

    local times=()
    local i=0

    while [[ $i -lt $BTE_ITER_LIST ]]; do
        elapsed=$(time_exec star list)
        times+=("$elapsed")
        i=$((i+=1))
    done

    local mn=$(min "${times[@]}")
    local mx=$(max "${times[@]}")
    local avg=$(mean "${times[@]}")

    printf "%-10s %-15s %-15s %-15s\n" "Metric" "Value" "Threshold" "Pass?" >&3
    printf "%-10s %-15s %-15s %-15s\n" "min" "${mn}ms" "-" "-" >&3
    printf "%-10s %-15s %-15s %-15s\n" "max" "${mx}ms" "${BTE_STAR_LIST_MAX}ms" \
        $([ "$mx" -le "$BTE_STAR_LIST_MAX" ] && echo "✓" || echo "✗") >&3
    printf "%-10s %-15s %-15s %-15s\n" "mean" "${avg}ms" "${BTE_STAR_LIST_MAX}ms" \
        $([ "$avg" -le "$BTE_STAR_LIST_MAX" ] && echo "✓" || echo "✗") >&3
    printf "%-10s %-15s %-15s %-15s\n" "diff" "$((mx - mn))ms" "${BTE_STAR_LIST_MIN_MAX_DIFF}ms" \
        $([ "$((mx - mn))" -le "$BTE_STAR_LIST_MIN_MAX_DIFF" ] && echo "✓" || echo "✗") >&3

    [ "$mx" -le "$BTE_STAR_LIST_MAX" ]
    [ "$avg" -le "$BTE_STAR_LIST_MAX" ]
    [ "$((mx - mn))" -le "$BTE_STAR_LIST_MIN_MAX_DIFF" ]
}

@test "star list - 50 bookmarks" {
    echo "Creating directories and starring them." >&3
    mkdir "$TEST_ROOT/d"{1..50}
    for i in {1..50}; do
        star add "$TEST_ROOT/d${i}"
    done
    echo "Finished creating directories and starring them." >&3

    local times=()
    local i=0

    while [[ $i -lt $BTE_ITER_LIST ]]; do
        elapsed=$(time_exec star list)
        times+=("$elapsed")
        i=$((i+=1))
    done

    local mn=$(min "${times[@]}")
    local mx=$(max "${times[@]}")
    local avg=$(mean "${times[@]}")

    printf "%-10s %-15s %-15s %-15s\n" "Metric" "Value" "Threshold" "Pass?" >&3
    printf "%-10s %-15s %-15s %-15s\n" "min" "${mn}ms" "-" "-" >&3
    printf "%-10s %-15s %-15s %-15s\n" "max" "${mx}ms" "${BTE_STAR_LIST_MAX}ms" \
        $([ "$mx" -le "$BTE_STAR_LIST_MAX" ] && echo "✓" || echo "✗") >&3
    printf "%-10s %-15s %-15s %-15s\n" "mean" "${avg}ms" "${BTE_STAR_LIST_MAX}ms" \
        $([ "$avg" -le "$BTE_STAR_LIST_MAX" ] && echo "✓" || echo "✗") >&3
    printf "%-10s %-15s %-15s %-15s\n" "diff" "$((mx - mn))ms" "${BTE_STAR_LIST_MIN_MAX_DIFF}ms" \
        $([ "$((mx - mn))" -le "$BTE_STAR_LIST_MIN_MAX_DIFF" ] && echo "✓" || echo "✗") >&3

    [ "$mx" -le "$BTE_STAR_LIST_MAX" ]
    [ "$avg" -le "$BTE_STAR_LIST_MAX" ]
    [ "$((mx - mn))" -le "$BTE_STAR_LIST_MIN_MAX_DIFF" ]
}
