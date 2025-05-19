#!/usr/bin/env python3
"""
Log Analyzer for Superfluid Fuzzing Chaos Monkey actions.

Given a (potentially very large) log file where each line is of the form:
    <FunctionName> | <succeeded|reverted>
interleaved with separator lines exactly equal to:
    === STATE RESET ===

This script computes:
1. Functions that always succeed (i.e. never observed to revert).
2. Functions that always revert (i.e. never observed to succeed).
3. Longest contiguous sequences of successful actions (ignoring reset markers and reverts).
4. Writes the top N longest successful sequences to an output text file.

The script streams the log file line-by-line, so it works with gigabyte-sized logs.

Usage:
    python analyze_logs.py /path/to/chaosMonkeyActions.txt \
                          --top 10 \
                          --out top_success_sequences.txt

If --out is omitted, the sequences are written to "top_success_sequences.txt" in the
current directory. If --top is omitted, defaults to 10.
"""
import argparse
import heapq
import os
import re
import sys
from typing import Dict, List, Set, Tuple, FrozenSet

# Pre-compiled regex for performance on huge files.
_LINE_RE = re.compile(r"^\s*([^|]+?)\s*\|\s*(succeeded|reverted)\s*$")
_RESET_LINE = "=== STATE RESET ==="

# Type aliases for clarity.
Sequence = List[str]
TopHeapItem = Tuple[int, int, Sequence]  # (length, insertion_index, sequence)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Analyze chaos monkey log file.")
    parser.add_argument("logfile", help="Path to the log file to analyze.")
    parser.add_argument(
        "--top",
        type=int,
        default=10,
        metavar="N",
        help="Store the top N longest successful sequences (default: 10).",
    )
    parser.add_argument(
        "--out",
        default="top_success_sequences.txt",
        metavar="FILE",
        help="Path to write the top sequences (default: top_success_sequences.txt).",
    )
    return parser.parse_args()


def update_function_stats(
    fn: str,
    outcome: str,
    seen_stats: Dict[str, Set[str]],
):
    """Track observed outcomes for each function name."""
    if fn not in seen_stats:
        seen_stats[fn] = set()
    seen_stats[fn].add(outcome)


def maybe_add_sequence(
    seq: Sequence,
    top_heap: List[TopHeapItem],
    insertion_counter: int,
    top_limit: int,
    seen_sequences: Set[Tuple[str, ...]],
):
    """Add a completed sequence to the min-heap maintaining the top N sequences."""
    if not seq:
        return insertion_counter

    # Convert sequence to tuple for hashability
    seq_tuple = tuple(seq)
    
    # Skip if we've already seen this exact sequence
    if seq_tuple in seen_sequences:
        return insertion_counter
        
    # Mark this sequence as seen
    seen_sequences.add(seq_tuple)

    # Store negatives of length to turn heapq into a max-heap behaviour while keeping
    # pop of smallest (min-heap default). Simpler: keep min-heap of size <= top_limit
    # based on positive length.
    item: TopHeapItem = (len(seq), insertion_counter, list(seq))
    if len(top_heap) < top_limit:
        heapq.heappush(top_heap, item)
    else:
        # If new sequence is longer than the shortest in heap, replace it.
        if len(seq) > top_heap[0][0]:
            heapq.heapreplace(top_heap, item)
    return insertion_counter + 1


def analyze_log(file_path: str, top_n: int) -> Tuple[Set[str], Set[str], List[Sequence], Dict[str, Tuple[int, int]]]:
    """Process the log file and return analysis results."""
    seen_stats: Dict[str, Set[str]] = {}
    # Map function -> [successful_count, total_count]
    outcome_counts: Dict[str, List[int]] = {}

    top_heap: List[TopHeapItem] = []  # Min-heap for the top sequences
    insertion_counter = 0  # Ensures stable ordering for heap items with equal length
    
    # Track seen sequences to avoid duplicates
    seen_sequences: Set[Tuple[str, ...]] = set()

    current_sequence: Sequence = []

    try:
        with open(file_path, "r", encoding="utf-8", errors="replace") as fh:
            for line in fh:
                line = line.rstrip("\n")

                # Skip empty lines quickly.
                if not line:
                    continue

                # Handle reset markers: they break sequences but do not affect stats.
                if line.strip() == _RESET_LINE:
                    insertion_counter = maybe_add_sequence(
                        current_sequence, top_heap, insertion_counter, top_n, seen_sequences
                    )
                    current_sequence = []
                    continue

                match = _LINE_RE.match(line)
                if not match:
                    # Unexpected line format; ignore but terminate current sequence.
                    insertion_counter = maybe_add_sequence(
                        current_sequence, top_heap, insertion_counter, top_n, seen_sequences
                    )
                    current_sequence = []
                    continue

                fn_name, outcome = match.groups()
                update_function_stats(fn_name, outcome, seen_stats)

                # Track per-function success/total counts
                if fn_name not in outcome_counts:
                    outcome_counts[fn_name] = [0, 0]
                outcome_counts[fn_name][1] += 1  # total count
                if outcome == "succeeded":
                    outcome_counts[fn_name][0] += 1  # success count
                    current_sequence.append(fn_name)
                else:  # outcome == "reverted"
                    insertion_counter = maybe_add_sequence(
                        current_sequence, top_heap, insertion_counter, top_n, seen_sequences
                    )
                    current_sequence = []
    finally:
        # At EOF, flush the last sequence if still open.
        insertion_counter = maybe_add_sequence(
            current_sequence, top_heap, insertion_counter, top_n, seen_sequences
        )

    # Derive always-succeed / always-revert sets.
    always_succeed: Set[str] = set()
    always_revert: Set[str] = set()
    for fn, outcomes in seen_stats.items():
        if outcomes == {"succeeded"}:
            always_succeed.add(fn)
        elif outcomes == {"reverted"}:
            always_revert.add(fn)

    # Convert heap to a sorted list of sequences longest-first.
    top_sequences: List[Sequence] = [item[2] for item in sorted(top_heap, key=lambda x: (-x[0], x[1]))]

    # Convert list counts to immutable tuples for return clarity
    counts_tupled: Dict[str, Tuple[int, int]] = {fn: (v[0], v[1]) for fn, v in outcome_counts.items()}

    return always_succeed, always_revert, top_sequences, counts_tupled


def write_sequences(path: str, sequences: List[Sequence]):
    with open(path, "w", encoding="utf-8") as f:
        for idx, seq in enumerate(sequences, 1):
            f.write(f"Sequence #{idx} (length={len(seq)}):\n")
            f.write(", ".join(seq) + "\n\n")


def main():
    args = parse_args()

    if not os.path.isfile(args.logfile):
        print(f"Error: file '{args.logfile}' does not exist.", file=sys.stderr)
        sys.exit(1)

    print("Analyzing log file. This may take a while on very large inputs...")
    always_succeed, always_revert, top_sequences, func_counts = analyze_log(args.logfile, args.top)

    # Summary to stdout
    print("\n=== Analysis Summary ===")
    print(f"Functions that always succeed ({len(always_succeed)}):")
    print(", ".join(sorted(always_succeed)) or "<none>")
    print(f"\nFunctions that always revert ({len(always_revert)}):")
    print(", ".join(sorted(always_revert)) or "<none>")
    if top_sequences:
        longest_len = len(top_sequences[0])
    else:
        longest_len = 0
    print(f"\nLongest successful sequence length: {longest_len}")
    print(f"Top {len(top_sequences)} unique successful sequences written to: {args.out}\n")

    # Print success rate per function (ranked by success %)
    print("Success rate per function (ranked by success %):")
    # Prepare sortable list of (rate, fn, succ, total)
    stats_sorted = []
    for fn, (succ, total) in func_counts.items():
        rate = (succ / total) if total else 0.0
        stats_sorted.append((rate, fn, succ, total))

    # Sort by rate descending, then by function name for stability
    stats_sorted.sort(key=lambda x: (-x[0], x[1]))

    for rate, fn, succ, total in stats_sorted:
        print(f"  {fn}: {succ}/{total} ({rate*100:.2f}%)")

    # Write sequences to file
    write_sequences(args.out, top_sequences)


if __name__ == "__main__":
    main() 