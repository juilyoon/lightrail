require 'lightrail/version'

if ['--version', '-v'].include?(ARGV.first)
  puts "Lightrail #{Lightrail::VERSION}"
  exit(0)
end

if ARGV.first != "new"
  ARGV[0] = "--help"
else
  ARGV.shift
  railsrc = File.join(File.expand_path("~"), ".railsrc")
  if File.exist?(railsrc)
    extra_args_string = File.open(railsrc).read
    extra_args = extra_args_string.split(/\n+/).map {|l| l.split}.flatten
    puts "Using #{extra_args.join(" ")} from #{railsrc}"
    ARGV << extra_args
    ARGV.flatten!
  end
end

require 'rubygems' if ARGV.include?("--dev")
require 'lightrail/generators/app_generator'

Lightrail::Generators::AppGenerator.start