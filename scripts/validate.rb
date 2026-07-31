#!/usr/bin/env ruby

require "json"
require "pathname"
require "yaml"

ROOT = Pathname.new(__dir__).parent.expand_path
VALID_SCHEMA_TYPES = %w[array boolean integer null number object string].freeze

REQUIRED_FILES = %w[
  SKILL.md
  README.md
  manifest.yaml
  source-resume.json
  user-profile.md
  job-filter-rules.yaml
  workflow.yaml
  report-template.md
  agents/JobHunter.md
  agents/RecruiterReply.md
  agents/RiskGuard.md
  agents/InterviewCoach.md
  agents/CareerStrategist.md
  agents/ResumeEngineer.md
  agents/Orchestrator.md
  schemas/run-input.schema.json
  schemas/run-output.schema.json
  schemas/job-analysis-input.schema.json
  schemas/job-analysis-output.schema.json
  schemas/recruiter-reply-input.schema.json
  schemas/recruiter-reply-output.schema.json
  schemas/risk-evaluation-input.schema.json
  schemas/risk-evaluation-output.schema.json
  memory/applied-history.json
  memory/recruiter-memory.json
  memory/rejected-jobs.json
  memory/interview-record.json
  memory/skill-feedback.json
  memory/career-growth.json
  memory/run-state.json
  prompts/orchestrator.md
  prompts/job-analysis.md
  prompts/recruiter-reply.md
  prompts/introduction.md
  prompts/risk-detection.md
  prompts/interview-preparation.md
  prompts/career-strategy.md
  prompts/resume-optimization.md
  scripts/validate.rb
].freeze

def fail_with(message)
  warn "FAIL: #{message}"
  exit 1
end

def load_yaml(path)
  YAML.safe_load(path.read, permitted_classes: [], permitted_symbols: [], aliases: false)
rescue Psych::Exception => e
  fail_with("invalid YAML #{path.relative_path_from(ROOT)}: #{e.message}")
end

def load_json(path)
  JSON.parse(path.read)
rescue JSON::ParserError => e
  fail_with("invalid JSON #{path.relative_path_from(ROOT)}: #{e.message}")
end

def collect_file_references(value, refs)
  case value
  when Hash
    value.each_value { |item| collect_file_references(item, refs) }
  when Array
    value.each { |item| collect_file_references(item, refs) }
  when String
    refs << value if value.match?(/\A(?!https?:\/\/)[^\s]+\.(?:md|yaml|json|rb)\z/)
  end
end

def validate_reference(reference, source)
  path = Pathname.new(reference)
  fail_with("absolute reference in #{source}: #{reference}") if path.absolute?
  fail_with("parent traversal in #{source}: #{reference}") if path.each_filename.include?("..")
  fail_with("missing reference in #{source}: #{reference}") unless ROOT.join(path).file?
end

def validate_schema_node(node, path)
  case node
  when Hash
    if node.key?("type")
      types = node["type"].is_a?(Array) ? node["type"] : [node["type"]]
      invalid = types - VALID_SCHEMA_TYPES
      fail_with("invalid JSON Schema type at #{path}: #{invalid.join(", ")}") unless invalid.empty?
    end

    if node["required"]
      fail_with("required is not an array at #{path}") unless node["required"].is_a?(Array)
      if node["properties"].is_a?(Hash)
        missing = node["required"] - node["properties"].keys
        fail_with("required property not declared at #{path}: #{missing.join(", ")}") unless missing.empty?
      end
    end

    if node["enum"]
      fail_with("empty or duplicate enum at #{path}") unless node["enum"].is_a?(Array) &&
        !node["enum"].empty? && node["enum"].uniq.length == node["enum"].length
    end

    node.each { |key, value| validate_schema_node(value, "#{path}/#{key}") }
  when Array
    node.each_with_index { |value, index| validate_schema_node(value, "#{path}/#{index}") }
  end
end

missing = REQUIRED_FILES.reject { |file| ROOT.join(file).file? }
fail_with("missing files: #{missing.join(", ")}") unless missing.empty?

Dir.glob(ROOT.join("**/*.yaml")).sort.each { |file| load_yaml(Pathname.new(file)) }
json_documents = {}
Dir.glob(ROOT.join("**/*.json")).sort.each do |file|
  path = Pathname.new(file)
  json_documents[path.relative_path_from(ROOT).to_s] = load_json(path)
end

skill = ROOT.join("SKILL.md").read
frontmatter = skill.match(/\A---\n(.*?)\n---\n/m)
fail_with("SKILL.md frontmatter missing") unless frontmatter
metadata = YAML.safe_load(frontmatter[1], aliases: false)
fail_with("invalid skill name") unless metadata["name"].match?(/\A[a-zA-Z0-9-]+\z/)
fail_with("description must start with 'Use when'") unless metadata["description"].start_with?("Use when")
fail_with("frontmatter exceeds 1024 characters") if frontmatter[1].length > 1024

manifest = load_yaml(ROOT.join("manifest.yaml"))
manifest_refs = []
collect_file_references(manifest, manifest_refs)
manifest_refs.uniq.each { |ref| validate_reference(ref, "manifest.yaml") }

workflow = load_yaml(ROOT.join("workflow.yaml"))
workflow_refs = []
collect_file_references(workflow, workflow_refs)
workflow_refs.uniq.each { |ref| validate_reference(ref, "workflow.yaml") }

Dir.glob(ROOT.join("**/*.md")).sort.each do |file|
  source = Pathname.new(file).relative_path_from(ROOT).to_s
  Pathname.new(file).read.scan(/`([^`\s]+\.(?:md|yaml|json|rb))`/).flatten.each do |ref|
    validate_reference(ref, source)
  end
end

schedule = workflow.fetch("schedule")
actual_times = schedule.fetch("trigger_times")
expected_minutes = (9 * 60).step(19 * 60, 20).to_a
actual_minutes = actual_times.map do |time|
  match = time.match(/\A(\d{2}):(\d{2})\z/)
  fail_with("invalid trigger time: #{time}") unless match
  match[1].to_i * 60 + match[2].to_i
end
fail_with("trigger list is not the complete 20-minute 09:00-19:00 cadence") unless actual_minutes == expected_minutes
%w[13:40 19:00].each do |checkpoint|
  fail_with("required checkpoint missing: #{checkpoint}") unless actual_times.include?(checkpoint)
end

Dir.glob(ROOT.join("schemas/*.schema.json")).sort.each do |file|
  relative = Pathname.new(file).relative_path_from(ROOT).to_s
  schema = json_documents.fetch(relative)
  fail_with("wrong JSON Schema draft in #{relative}") unless schema["$schema"] == "https://json-schema.org/draft/2020-12/schema"
  fail_with("missing JSON Schema id in #{relative}") unless schema["$id"].is_a?(String)
  fail_with("missing JSON Schema title in #{relative}") unless schema["title"].is_a?(String)
  fail_with("schema root must be object in #{relative}") unless schema["type"] == "object"
  validate_schema_node(schema, relative)
end

memory_shapes = {
  "memory/applied-history.json" => "applications",
  "memory/recruiter-memory.json" => "recruiters",
  "memory/rejected-jobs.json" => "rejected",
  "memory/interview-record.json" => "interviews"
}
memory_shapes.each do |file, key|
  value = json_documents.fetch(file)[key]
  fail_with("#{file} must contain #{key} as an array") unless value.is_a?(Array)
end

profile = ROOT.join("user-profile.md").read
[
  "只记录简历明确写出的事实",
  "求职目标与自动化偏好",
  "禁止推断",
  "本地私有副本"
].each do |required_text|
  fail_with("profile boundary missing: #{required_text}") unless profile.include?(required_text)
end

Dir.glob(ROOT.join("**/*")).each do |file|
  next unless File.file?(file)
  local_home_prefix = "/" + "Users/admin/"
  fail_with("package contains an absolute local path: #{file}") if File.read(file).include?(local_home_prefix)
end

puts "PASS: #{REQUIRED_FILES.length} required files"
puts "PASS: #{Dir.glob(ROOT.join("**/*.yaml")).length} YAML files"
puts "PASS: #{json_documents.length} JSON files"
puts "PASS: #{Dir.glob(ROOT.join("schemas/*.schema.json")).length} JSON Schemas"
puts "PASS: 31 schedule triggers from 09:00 to 19:00, including 13:40 and 19:00"
puts "PASS: manifest, workflow, and Markdown references resolve"
