# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'simp/module/repoclosure/version'

Gem::Specification.new do |gem|
  gem.name          = "simp-module-repoclosure"
  gem.version       = Simp::Module::Repoclosure::VERSION
  gem.summary       = %q{Test Puppet modules' dependency declarations with a local Puppet Forge}
  gem.description   = %q{~~Stupidly~~ Admirably direct repoclosure for a Puppet module's `metadata.json`}
  gem.license       = "Apache-2.0"
  gem.authors       = ["Chris Tessmer"]
  gem.email         = "simp@simp-project.org"
  gem.homepage      = "https://github.com/simp/rubygem-simp-module-repoclosure"

  gem.files         = `git ls-files`.split($/)

  `git submodule --quiet foreach --recursive pwd`.split($/).each do |submodule|
    submodule.sub!("#{Dir.pwd}/",'')

    Dir.chdir(submodule) do
      `git ls-files`.split($/).map do |subpath|
        gem.files << File.join(submodule,subpath)
      end
    end
  end
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_development_dependency 'bundler', '~> 1.10'
  gem.add_development_dependency 'rake',    '~> 10.0'
  gem.add_development_dependency 'rspec',   '~> 3.0'
  gem.add_development_dependency 'yard',    '~> 0.8'
  gem.add_runtime_dependency     'r10k',    '~> 2.2'
  gem.add_runtime_dependency     'puppet'
  gem.add_runtime_dependency     'parallel', '~> 1.8'
  gem.add_runtime_dependency     'puppet-forge-server', '~> 1.9'


end
