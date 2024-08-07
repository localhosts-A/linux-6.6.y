#!/bin/sh
# Check Arm64 callgraphs are complete in fp mode
# SPDX-License-Identifier: GPL-2.0

lscpu | grep -q "aarch64" || exit 2

PERF_DATA=$(mktemp /tmp/__perf_test.perf.data.XXXXX)
TEST_PROGRAM="perf test -w leafloop"

cleanup_files()
{
	rm -f "$PERF_DATA"
}

trap cleanup_files EXIT TERM INT

# shellcheck disable=SC2086
perf record -o "$PERF_DATA" --call-graph fp -e cycles//u --user-callchains -- $TEST_PROGRAM

# Try opening the file so any immediate errors are visible in the log
perf script -i "$PERF_DATA" -F comm,ip,sym | head -n4

# expected perf-script output if 'leaf' has been inserted correctly:
#
# perf
# 	728 leaf
# 	753 parent
# 	76c leafloop
# ... remaining stack to main() ...

# Each frame is separated by a tab, some spaces and an address
SEP="[[:space:]]+ [[:xdigit:]]+"
perf script -i "$PERF_DATA" -F comm,ip,sym | tr '\n' ' ' | \
	grep -E -q "perf $SEP leaf $SEP parent $SEP leafloop"
