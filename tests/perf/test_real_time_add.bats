#!/usr/bin/env bats

load ../helpers/helper_setup
load ../helpers/helper_measure
load ../helpers/constants

setup() { setup_common; }
teardown() { teardown_common; }

@test "star add - adding 5 bookmarks one after the other" {
    mkdir "$TEST_ROOT/d"{1..5}

    local times=()
    local i
    local n=1
    while [[ $n -le 5 ]]; do
        i=0
        while [[ $i -lt $BTE_ITER_ADD ]]; do
            elapsed=$(time_exec star add "$TEST_ROOT/d${n}")
            times+=("$elapsed")
            i=$((i+=1))
            star remove "d${n}" &> /dev/null
        done
        star add "$TEST_ROOT/d${n}"
        n=$((n+=1))
    done

    local avg=$(mean "${times[@]}")
    local mn=$(min "${times[@]}")
    local mx=$(max "${times[@]}")

    printf "%-10s %-15s %-15s %-15s\n" "Metric" "Value" "Threshold" "Pass?" >&3
    printf "%-10s %-15s %-15s %-15s\n" "min" "${mn}ms" "-" "-" >&3
    printf "%-10s %-15s %-15s %-15s\n" "max" "${mx}ms" "${BTE_STAR_ADD_MAX}ms" \
        $([ "$mx" -le "$BTE_STAR_ADD_MAX" ] && echo "✓" || echo "✗") >&3
    printf "%-10s %-15s %-15s %-15s\n" "mean" "${avg}ms" "${BTE_STAR_ADD_MAX}ms" \
        $([ "$avg" -le "$BTE_STAR_ADD_MAX" ] && echo "✓" || echo "✗") >&3
    printf "%-10s %-15s %-15s %-15s\n" "diff" "$((mx - mn))ms" "${BTE_STAR_ADD_MIN_MAX_DIFF}ms" \
        $([ "$((mx - mn))" -le "$BTE_STAR_ADD_MIN_MAX_DIFF" ] && echo "✓" || echo "✗") >&3

    [ "$mx" -le "$BTE_STAR_ADD_MAX" ]
    [ "$avg" -le "$BTE_STAR_ADD_MAX" ]
    [ "$((mx - mn))" -le "$BTE_STAR_ADD_MIN_MAX_DIFF" ]
}

@test "star add - adding a 5th bookmark after 4 have already been starred" {
    mkdir "$TEST_ROOT/d"{1..5}

    for i in {1..4}; do
        star add "$TEST_ROOT/d${i}" &> /dev/null
    done

    local times=()
    local i
    while [[ $i -lt $BTE_ITER_LIST ]]; do
        elapsed=$(time_exec star add "$TEST_ROOT/d5")
        times+=("$elapsed")
        i=$((i+=1))
        star remove "d5" &> /dev/null
    done

    local mn=$(min "${times[@]}")
    local mx=$(max "${times[@]}")
    local avg=$(mean "${times[@]}")

    printf "%-10s %-15s %-15s %-15s\n" "Metric" "Value" "Threshold" "Pass?" >&3
    printf "%-10s %-15s %-15s %-15s\n" "min" "${mn}ms" "-" "-" >&3
    printf "%-10s %-15s %-15s %-15s\n" "max" "${mx}ms" "${BTE_STAR_ADD_MAX}ms" \
        $([ "$mx" -le "$BTE_STAR_ADD_MAX" ] && echo "✓" || echo "✗") >&3
    printf "%-10s %-15s %-15s %-15s\n" "mean" "${avg}ms" "${BTE_STAR_ADD_MAX}ms" \
        $([ "$avg" -le "$BTE_STAR_ADD_MAX" ] && echo "✓" || echo "✗") >&3
    printf "%-10s %-15s %-15s %-15s\n" "diff" "$((mx - mn))ms" "${BTE_STAR_ADD_MIN_MAX_DIFF}ms" \
        $([ "$((mx - mn))" -le "$BTE_STAR_ADD_MIN_MAX_DIFF" ] && echo "✓" || echo "✗") >&3

    [ "$mx" -le "$BTE_STAR_ADD_MAX" ]
    [ "$avg" -le "$BTE_STAR_ADD_MAX" ]
    [ "$((mx - mn))" -le "$BTE_STAR_ADD_MIN_MAX_DIFF" ]
}

@test "star add - adding 10 bookmarks one after the other" {
    mkdir "$TEST_ROOT/d"{1..10}

    local times=()
    local i
    local n=1
    while [[ $n -le 10 ]]; do
        i=0
        while [[ $i -lt $BTE_ITER_ADD ]]; do
            elapsed=$(time_exec star add "$TEST_ROOT/d${n}")
            times+=("$elapsed")
            i=$((i+=1))
            star remove "d${n}" &> /dev/null
        done
        star add "$TEST_ROOT/d${n}"
        n=$((n+=1))
    done

    local mn=$(min "${times[@]}")
    local mx=$(max "${times[@]}")
    local avg=$(mean "${times[@]}")

    printf "%-10s %-15s %-15s %-15s\n" "Metric" "Value" "Threshold" "Pass?" >&3
    printf "%-10s %-15s %-15s %-15s\n" "min" "${mn}ms" "-" "-" >&3
    printf "%-10s %-15s %-15s %-15s\n" "max" "${mx}ms" "${BTE_STAR_ADD_MAX}ms" \
        $([ "$mx" -le "$BTE_STAR_ADD_MAX" ] && echo "✓" || echo "✗") >&3
    printf "%-10s %-15s %-15s %-15s\n" "mean" "${avg}ms" "${BTE_STAR_ADD_MAX}ms" \
        $([ "$avg" -le "$BTE_STAR_ADD_MAX" ] && echo "✓" || echo "✗") >&3
    printf "%-10s %-15s %-15s %-15s\n" "diff" "$((mx - mn))ms" "${BTE_STAR_ADD_MIN_MAX_DIFF}ms" \
        $([ "$((mx - mn))" -le "$BTE_STAR_ADD_MIN_MAX_DIFF" ] && echo "✓" || echo "✗") >&3

    [ "$mx" -le "$BTE_STAR_ADD_MAX" ]
    [ "$avg" -le "$BTE_STAR_ADD_MAX" ]
    [ "$((mx - mn))" -le "$BTE_STAR_ADD_MIN_MAX_DIFF" ]
}

@test "star add - adding a 10th bookmark after 9 have already been starred" {
    mkdir "$TEST_ROOT/d"{1..10}

    for i in {1..9}; do
        star add "$TEST_ROOT/d${i}" &> /dev/null
    done

    local times=()
    local i
    while [[ $i -lt $BTE_ITER_LIST ]]; do
        elapsed=$(time_exec star add "$TEST_ROOT/d10")
        times+=("$elapsed")
        i=$((i+=1))
        star remove "d10" &> /dev/null
    done

    local mn=$(min "${times[@]}")
    local mx=$(max "${times[@]}")
    local avg=$(mean "${times[@]}")

    printf "%-10s %-15s %-15s %-15s\n" "Metric" "Value" "Threshold" "Pass?" >&3
    printf "%-10s %-15s %-15s %-15s\n" "min" "${mn}ms" "-" "-" >&3
    printf "%-10s %-15s %-15s %-15s\n" "max" "${mx}ms" "${BTE_STAR_ADD_MAX}ms" \
        $([ "$mx" -le "$BTE_STAR_ADD_MAX" ] && echo "✓" || echo "✗") >&3
    printf "%-10s %-15s %-15s %-15s\n" "mean" "${avg}ms" "${BTE_STAR_ADD_MAX}ms" \
        $([ "$avg" -le "$BTE_STAR_ADD_MAX" ] && echo "✓" || echo "✗") >&3
    printf "%-10s %-15s %-15s %-15s\n" "diff" "$((mx - mn))ms" "${BTE_STAR_ADD_MIN_MAX_DIFF}ms" \
        $([ "$((mx - mn))" -le "$BTE_STAR_ADD_MIN_MAX_DIFF" ] && echo "✓" || echo "✗") >&3

    [ "$mx" -le "$BTE_STAR_ADD_MAX" ]
    [ "$avg" -le "$BTE_STAR_ADD_MAX" ]
    [ "$((mx - mn))" -le "$BTE_STAR_ADD_MIN_MAX_DIFF" ]
}

@test "star add - adding 50 bookmarks one after the other" {
    mkdir "$TEST_ROOT/d"{1..50}

    local times=()
    local i
    local n=1
    while [[ $n -le 50 ]]; do
        i=0
        while [[ $i -lt $BTE_ITER_ADD ]]; do
            elapsed=$(time_exec star add "$TEST_ROOT/d${n}")
            times+=("$elapsed")
            i=$((i+=1))
            star remove "d${n}" &> /dev/null
        done
        star add "$TEST_ROOT/d${n}"
        n=$((n+=1))
    done

    local mn=$(min "${times[@]}")
    local mx=$(max "${times[@]}")
    local avg=$(mean "${times[@]}")

    printf "%-10s %-15s %-15s %-15s\n" "Metric" "Value" "Threshold" "Pass?" >&3
    printf "%-10s %-15s %-15s %-15s\n" "min" "${mn}ms" "-" "-" >&3
    printf "%-10s %-15s %-15s %-15s\n" "max" "${mx}ms" "${BTE_STAR_ADD_MAX}ms" \
        $([ "$mx" -le "$BTE_STAR_ADD_MAX" ] && echo "✓" || echo "✗") >&3
    printf "%-10s %-15s %-15s %-15s\n" "mean" "${avg}ms" "${BTE_STAR_ADD_MAX}ms" \
        $([ "$avg" -le "$BTE_STAR_ADD_MAX" ] && echo "✓" || echo "✗") >&3
    printf "%-10s %-15s %-15s %-15s\n" "diff" "$((mx - mn))ms" "${BTE_STAR_ADD_MIN_MAX_DIFF}ms" \
        $([ "$((mx - mn))" -le "$BTE_STAR_ADD_MIN_MAX_DIFF" ] && echo "✓" || echo "✗") >&3

    [ "$mx" -le "$BTE_STAR_ADD_MAX" ]
    [ "$avg" -le "$BTE_STAR_ADD_MAX" ]
    [ "$((mx - mn))" -le "$BTE_STAR_ADD_MIN_MAX_DIFF" ]
}

@test "star add - adding a 50th bookmark after 49 have already been starred" {
    mkdir "$TEST_ROOT/d"{1..50}

    for i in {1..49}; do
        star add "$TEST_ROOT/d${i}" &> /dev/null
    done

    local times=()
    local i
    while [[ $i -lt $BTE_ITER_LIST ]]; do
        elapsed=$(time_exec star add "$TEST_ROOT/d50")
        times+=("$elapsed")
        i=$((i+=1))
        star remove "d50" &> /dev/null
    done

    local mn=$(min "${times[@]}")
    local mx=$(max "${times[@]}")
    local avg=$(mean "${times[@]}")

    printf "%-10s %-15s %-15s %-15s\n" "Metric" "Value" "Threshold" "Pass?" >&3
    printf "%-10s %-15s %-15s %-15s\n" "min" "${mn}ms" "-" "-" >&3
    printf "%-10s %-15s %-15s %-15s\n" "max" "${mx}ms" "${BTE_STAR_ADD_MAX}ms" \
        $([ "$mx" -le "$BTE_STAR_ADD_MAX" ] && echo "✓" || echo "✗") >&3
    printf "%-10s %-15s %-15s %-15s\n" "mean" "${avg}ms" "${BTE_STAR_ADD_MAX}ms" \
        $([ "$avg" -le "$BTE_STAR_ADD_MAX" ] && echo "✓" || echo "✗") >&3
    printf "%-10s %-15s %-15s %-15s\n" "diff" "$((mx - mn))ms" "${BTE_STAR_ADD_MIN_MAX_DIFF}ms" \
        $([ "$((mx - mn))" -le "$BTE_STAR_ADD_MIN_MAX_DIFF" ] && echo "✓" || echo "✗") >&3

    [ "$mx" -le "$BTE_STAR_ADD_MAX" ]
    [ "$avg" -le "$BTE_STAR_ADD_MAX" ]
    [ "$((mx - mn))" -le "$BTE_STAR_ADD_MIN_MAX_DIFF" ]
}
