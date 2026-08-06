#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "optparse"
require "pathname"
require "fileutils"
require "yaml"

options = {}
OptionParser.new do |parser|
  parser.on("--product-name NAME") { |value| options[:product_name] = value }
  parser.on("--organization NAME") { |value| options[:organization] = value }
  parser.on("--repository SLUG") { |value| options[:repository] = value }
end.parse!
abort "Product name, organization and repository are required" unless %i[product_name organization repository].all? { |key| options[key]&.match?(/\A[\w .-]+\z/) }

root = Pathname(__dir__).join("..").expand_path
source = JSON.parse(root.join("application-starter-manifest.json").read)
adoption = root.join("config/nomotect/adoption.json")
abort "Application Starter has already been initialized" if adoption.exist?

contract = YAML.safe_load(root.join("config/distributions/application_starter.yml").read)
contract.fetch("identity_files").each do |relative|
  path = root.join(relative)
  next unless path.file?

  path.write(path.read.gsub("NomoTect", options.fetch(:product_name)))
end
FileUtils.mkdir_p(adoption.dirname)
adoption.write(JSON.pretty_generate(schema_version: 1, product: options, platform: source.fetch("platform")) + "\n")
unless root.join(".git").directory?
  abort "Could not initialize the private Git repository" unless system("git", "init", "-b", "main", root.to_s)
end
puts "Initialized #{options.fetch(:product_name)} from NomoTect #{source.dig("platform", "version")}."
