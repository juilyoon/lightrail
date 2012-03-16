# encoding: utf-8
require File.expand_path('../lib/lightrail/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name         = 'lightrail'
  gem.version      = Lightrail::VERSION
  gem.platform     = Gem::Platform::RUBY
  gem.authors      = ['José Valim', 'Carl Lerche', 'Tony Arcieri']
  gem.email        = ['me@carllerche.com', 'jose.valim@gmail.com', 'tony.arcieri@gmail.com']
  gem.homepage     = 'http://github.com/lightness/lightrail'
  gem.summary      = 'Slim Rails stack for JSON services'
  gem.description  = 'Lightrail slims Rails down to the bare essentials great JSON web services crave'
  gem.files        = `git ls-files`.split("\n")
  gem.require_path = 'lib'
  gem.bindir       = 'bin'
  gem.executables  = %w(lightrail)

  gem.add_development_dependency 'rake'

  # This gives us ActionPack and ActiveSupport
  gem.add_runtime_dependency 'railties', '~> 3.2'
  gem.add_runtime_dependency 'active_model_serializers'
end
