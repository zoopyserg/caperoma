# frozen_string_literal: true

require 'rubygems'
require 'bundler'
require 'fileutils'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  warn e.message
  warn 'Run `bundle install` to install missing gems'
  exit e.status_code
end
require 'rake'

require 'juwelier'
Juwelier::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://guides.rubygems.org/specification-reference/ for more options
  gem.name = 'caperoma'
  gem.homepage = 'http://github.com/zoopyserg/caperoma'
  gem.license = 'MIT'
  gem.summary = %(Automate your workflow with Ruby / Git / Jira / PivotalTracker.)
  gem.description = <<-EOF
    Caperoma automates many decisions related to the programming that you often don't realize, and which you can forget hundreds of times during the time of working on the project:
    - pulling the latest code from upstream before you start working,
    - remembering from which branch you started the feature to later make a pull request into it,
    - creating & starting tasks in Jira,
    - creating & starting tasks in Pivotal,
    - naming branches,
    - adding Jira ID into the branch name,
    - style guide checks,
    - commits,
    - naming commits,
    - adding Jira ID into commit name,
    - adding Pivotal ID into commit name,
    - git pushes,
    - pull requests into correct branches,
    - stopping tasks in Jira,
    - stopping tasks in Pivotal,
    - tracking time,
    - logging time to Jira,
    - switching back into the original branch and much more.
  EOF
  gem.files += FileList['lib/**/*', 'bin/*', '[A-Za-z.]*', 'spec/**/*', 'config/*'].to_a
  gem.bindir = 'bin'
  gem.executables = ['caperoma']

  gem.add_runtime_dependency 'actionpack', '~> 5.2.3'
  gem.add_runtime_dependency 'actionview', '~> 5.2.3'
  gem.add_runtime_dependency 'activerecord', '~> 5.2.3'
  gem.add_runtime_dependency 'activesupport', '~> 5.2.3'
  gem.add_runtime_dependency 'faraday', '~> 0.15.4'
  gem.add_runtime_dependency 'gmail', '~> 0.7.1'
  gem.add_runtime_dependency 'jbuilder', '~> 2.9.1'
  gem.add_runtime_dependency 'pivotal-tracker', '~> 0.5.13'
  gem.add_runtime_dependency 'rubocop', '~> 0.73.0'
  gem.add_runtime_dependency 'sqlite3', '~> 1.4.1'
  gem.add_runtime_dependency 'time_difference', '~> 0.7.0'

  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'database_cleaner', '~> 1.7.0'
  gem.add_development_dependency 'factory_bot_rails', '~> 5.0.2'
  gem.add_development_dependency 'rdoc', '~> 6.1.1'
  gem.add_development_dependency 'rspec', '~> 3.8.0'
  gem.add_development_dependency 'shoulda', '~> 2.11.3'
  gem.add_development_dependency 'shoulda-matchers', '~> 4.1.0'
  gem.add_development_dependency 'timecop', '~> 0.9.1'

  gem.requirements << 'sqlite'
  gem.requirements << 'git'

  gem.extra_rdoc_files = ['README.md', 'HELP']
  gem.version = File.exist?('VERSION') ? File.read('VERSION') : ''

  gem.email = 'sergevinogradoff.caperoma@gmail.com'
  gem.authors = ['Serge Vinogradoff']
  # dependencies defined in Gemfile

  gem.post_install_message = "Thanks for installing Caperoma! \n Run `caperoma setup` to create the database for your work."
  # gem.required_ruby_version = '>= 2.6.3'
end
Juwelier::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task default: :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ''

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "caperoma #{version}"

  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('HELP*')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.include('lib/**/*')
  rdoc.rdoc_files.include('bin/*')
  rdoc.rdoc_files.include('[A-Za-z.]*')
  rdoc.rdoc_files.include('spec/**/*')
  rdoc.rdoc_files.include('config/*')
end
