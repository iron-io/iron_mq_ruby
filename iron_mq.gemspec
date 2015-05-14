require File.expand_path('../lib/iron_mq/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Yury Yantsevich", "Travis Reeder"]
  gem.email         = ["yury@iron.io", "travis@iron.io"]
  gem.description   = "Ruby client for IronMQ by www.iron.io"
  gem.summary       = "Ruby client for IronMQ by www.iron.io"
  gem.homepage      = "https://github.com/iron-io/iron_mq_ruby"
  gem.license       = "BSD-2-Clause"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "iron_mq"
  gem.require_paths = ["lib"]
  gem.version       = IronMQ::VERSION

  gem.required_rubygems_version = ">= 1.3.6"
  gem.required_ruby_version = Gem::Requirement.new(">= 1.9")
  gem.add_runtime_dependency "iron_core", ">= 1.0.7"

  gem.add_development_dependency "minitest", ">= 5.0"
  gem.add_development_dependency "rake"
end
