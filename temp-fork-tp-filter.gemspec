# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tty/prompt/version'

Gem::Specification.new do |spec|
  spec.name          = "temp-fork-tp-filter"
  spec.version       = TTY::Prompt::VERSION
  spec.authors       = ["See the tty-prompt website"]
  spec.date          = '2018-01-18'
  spec.email         = [""]
  spec.summary       = %q{Temporary fork of tty-prompt}
  spec.description   = %q{Temporary fork of tty-prompt}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
                          f.match(%r{^(test|spec|features)/})
                        end
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_dependency 'necromancer',  '~> 0.4.0'
  spec.add_dependency 'pastel',       '~> 0.7.0'
  spec.add_dependency 'timers',       '~> 4.1.2'
  spec.add_dependency 'tty-cursor',   '~> 0.5.0'
  spec.add_dependency 'tty-reader',   '~> 0.2.0'

  spec.add_development_dependency 'bundler', '>= 1.5.0', '< 2.0'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
