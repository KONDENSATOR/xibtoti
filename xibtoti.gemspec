# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{xibtoti}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Fredrik Andersson"]
  s.date = %q{2011-03-11}
  s.default_executable = %q{xibtoti}
  s.description = %q{Convert iPhone xib-files to Titanium javascript.}
  s.email = %q{fredrik@kondensator.se}
  s.executables = ["xibtoti"]
  s.extra_rdoc_files = ["CHANGELOG", "LICENSE", "README.rdoc", "bin/xibtoti", "lib/config.rb", "lib/converters.rb", "lib/nodes.rb", "lib/session.rb", "lib/xibtoti.rb"]
  s.files = ["CHANGELOG", "LICENSE", "README.rdoc", "Rakefile", "bin/xibtoti", "lib/config.rb", "lib/converters.rb", "lib/nodes.rb", "lib/session.rb", "lib/xibtoti.rb", "xibtoti.gemspec", "Manifest"]
  s.homepage = %q{http://github.com/KONDENSATOR/xibtoti}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Xibtoti", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{xibtoti}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Convert iPhone xib-files to Titanium javascript.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
