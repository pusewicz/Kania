#!/usr/bin/env ruby
# frozen_string_literal: true

# Runs the Phase 0 draw-path benchmark matrix: the C baseline and every Swift variant at each
# sprite count, interleaved round-robin so thermal drift hits all of them equally. Prints a
# Markdown table and writes every raw run to Results/raw/<label>.jsonl.
#
# Usage: Scripts/bench.rb [--label NAME] [--runs N] [--counts 100,1000,10000] [--frames N]
#                         [--text-counts 100,1000] [--bin DIR] [--c-bin DIR]
# Build first: swift build -c release (and any KANIA_BENCH_SWIFTFLAGS variant into --bin).

require "json"
require "optparse"
require "fileutils"
require "rbconfig"

ROOT = File.expand_path("..", __dir__)
SWIFT_IMPLS = %w[raw-array raw-buffer overlay-struct overlay-class].freeze

options = {
  label: "local",
  runs: 5,
  counts: [100, 1_000, 10_000],
  text_counts: [100, 1_000],
  frames: 600,
  bin: nil,
  c_bin: nil
}
OptionParser.new do |o|
  o.on("--label NAME") { |v| options[:label] = v }
  o.on("--runs N", Integer) { |v| options[:runs] = v }
  o.on("--counts LIST") { |v| options[:counts] = v.split(",").map(&:to_i) }
  o.on("--text-counts LIST") { |v| options[:text_counts] = v.split(",").map(&:to_i) }
  o.on("--frames N", Integer) { |v| options[:frames] = v }
  o.on("--bin DIR", "directory with SpriteBench") { |v| options[:bin] = v }
  o.on("--c-bin DIR", "directory with SpriteBenchC") { |v| options[:c_bin] = v }
end.parse!

default_bin = `swift build -c release --show-bin-path`.strip
bin = options[:bin] || default_bin
c_bin = options[:c_bin] || bin
exe = RbConfig::CONFIG["host_os"].match?(/mswin|mingw/) ? ".exe" : ""

# Returns the parsed JSON line a single benchmark process prints, or aborts with its output.
def run(command)
  output = IO.popen(command, err: %i[child out], &:read)
  line = output.lines.find { |l| l.start_with?("{") }
  abort "benchmark failed: #{command.join(" ")}\n#{output}" unless $?.success? && line
  JSON.parse(line)
end

cases = options[:counts].flat_map do |count|
  [["c", "sprites", count]] + SWIFT_IMPLS.map { |impl| [impl, "sprites", count] }
end
cases += options[:text_counts].flat_map { |count| [["c", "text", count], ["swift", "text", count]] }

FileUtils.mkdir_p(File.join(ROOT, "Results/raw"))
raw_path = File.join(ROOT, "Results/raw/#{options[:label]}.jsonl")
results = Hash.new { |h, k| h[k] = [] }
File.open(raw_path, "w") do |raw|
  options[:runs].times do |round|
    cases.each do |impl, scene, count|
      common = ["--scene", scene, "--count", count.to_s, "--frames", options[:frames].to_s]
      command =
        if impl == "c"
          [File.join(c_bin, "SpriteBenchC#{exe}"), *common]
        else
          [File.join(bin, "SpriteBench#{exe}"), *common, *(scene == "sprites" ? ["--impl", impl] : [])]
        end
      result = run(command)
      result["round"] = round
      raw.puts(JSON.generate(result))
      results[[impl, scene, count]] << result
      warn format("round %d  %-15s %-7s %6d  submit %.4f ms", round, impl, scene, count,
                  result.dig("submit_ms", "median"))
    end
  end
end

# Median of the per-run medians: robust to one noisy run.
def median(values)
  sorted = values.sort
  sorted[(sorted.size - 1) / 2]
end

puts "| scene | count | impl | submit ms (median) | vs C | per item ns | frame ms (median) | checksum |"
puts "|---|---:|---|---:|---:|---:|---:|---|"
cases.each do |impl, scene, count|
  runs = results[[impl, scene, count]]
  submit = median(runs.map { |r| r.dig("submit_ms", "median") })
  frame = median(runs.map { |r| r.dig("frame_ms", "median") })
  c_submit = median(results[["c", scene, count]].map { |r| r.dig("submit_ms", "median") })
  c_checksum = results[["c", scene, count]].first["checksum"]
  checksums = runs.map { |r| r["checksum"] }.uniq
  parity = checksums == [c_checksum] ? "matches C" : "DIFFERS #{checksums.inspect} vs #{c_checksum}"
  puts format("| %s | %d | %s | %.4f | %+.1f%% | %.1f | %.3f | %s |", scene, count, impl, submit,
              (submit / c_submit - 1) * 100, submit * 1e6 / count, frame, parity)
end
warn "raw runs: #{raw_path}"
