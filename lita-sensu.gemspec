Gem::Specification.new do |spec|
  spec.name          = "lita-sensu"
  spec.version       = "0.2.0"
  spec.authors       = ["Justin Lambert"]
  spec.email         = ["jlambert@eml.cc"]
  spec.description   = "Lita plugin to interact with sensu"
  spec.summary       = "Lita plugin to interact with sensu"
  spec.homepage      = "https://github.com/jlambert121/lita-sensu"
  spec.license       = "Apache-2.0"
  spec.metadata      = { "lita_plugin_type" => "handler" }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 4.3"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rspec", ">= 3.0.0"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "coveralls"
end
