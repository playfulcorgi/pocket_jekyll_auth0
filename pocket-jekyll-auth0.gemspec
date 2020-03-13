Gem::Specification.new do |spec|
  spec.name = "pocket-jekyll-auth0"
  spec.version = "0.1.0"
  spec.authors = ["playfulcorgi"]
  spec.homepage = "https://github.com/playfulcorgi/pocket-jekyll-auth0"
  spec.license = "MIT"
  spec.summary = "Pocket Jekyll Auth0."
  spec.files = ["lib/pocket-jekyll-auth0.rb"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.7.0"
  spec.add_dependency 'jekyll'
  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
end
