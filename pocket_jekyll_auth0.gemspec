require_relative 'lib/pocket_jekyll_auth0/version'

Gem::Specification.new do |spec|
  spec.name = "pocket_jekyll_auth0"
  spec.version = Auth0MachineToMachine::VERSION
  spec.authors = ["playfulcorgi"]
  spec.email = ["unrulybeardedweekend@gmail.com"]
  spec.homepage = "https://github.com/playfulcorgi/pocket_jekyll_auth0"
  spec.license = "MIT"
  spec.summary = "Pocket Jekyll Auth0."
  spec.files = ["lib/pocket_jekyll_auth0.rb"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.7.0"
  spec.add_dependency 'jekyll'
end
