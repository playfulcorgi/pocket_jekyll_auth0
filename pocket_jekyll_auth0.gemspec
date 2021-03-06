require_relative 'lib/pocket_jekyll_auth0/version'

Gem::Specification.new do |spec|
  spec.name = "pocket_jekyll_auth0"
  spec.version = PocketJekyllAuth0::VERSION
  spec.authors = ["playfulcorgi"]
  spec.email = ["unrulybeardedweekend@gmail.com"]
  spec.homepage = "https://github.com/playfulcorgi/pocket_jekyll_auth0"
  spec.license = "MIT"
  spec.summary = "Pocket Jekyll Auth0."
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.5.0"
  spec.add_runtime_dependency "auth0_machine_to_machine", "~> 0.1.2"
  spec.add_runtime_dependency "jekyll", "~> 4.0.0"
end
