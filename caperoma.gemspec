# Generated by juwelier
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Juwelier::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: caperoma 4.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "caperoma".freeze
  s.version = "4.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Serge Vinogradoff".freeze]
  s.date = "2019-07-22"
  s.description = "    Caperoma automates many decisions related to the programming that you often don't realize, and which you can forget hundreds of times during the time of working on the project: \n    - pulling the latest code from upstream before you start working,\n    - remembering from which branch you started the feature to later make a pull request into it,\n    - creating & starting tasks in Jira,\n    - creating & starting tasks in Pivotal,\n    - naming branches,\n    - adding Jira ID into the branch name,\n    - style guide checks,\n    - commits,\n    - naming commits,\n    - adding Jira ID into commit name,\n    - adding Pivotal ID into commit name,\n    - git pushes,\n    - pull requests into correct branches,\n    - stopping tasks in Jira,\n    - stopping tasks in Pivotal,\n    - tracking time,\n    - logging time to Jira,\n    - switching back into the original branch and much more.\n".freeze
  s.email = "sergevinogradoff.caperoma@gmail.com".freeze
  s.executables = ["caperoma".freeze]
  s.extra_rdoc_files = [
    "HELP",
    "README.md"
  ]
  s.files = [
    ".ruby-version",
    "Capefile",
    "Capefile.template",
    "Capefile.test",
    "Gemfile",
    "Gemfile.lock",
    "HELP",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "VERSION",
    "bin/caperoma",
    "caperoma.gemspec",
    "config/crontab",
    "config/schedule.rb",
    "lib/caperoma.rb",
    "lib/caperoma/models/account.rb",
    "lib/caperoma/models/application_record.rb",
    "lib/caperoma/models/branch.rb",
    "lib/caperoma/models/project.rb",
    "lib/caperoma/models/property.rb",
    "lib/caperoma/models/report.rb",
    "lib/caperoma/models/report_recipient.rb",
    "lib/caperoma/models/reports/daily_report.rb",
    "lib/caperoma/models/reports/retrospective_report.rb",
    "lib/caperoma/models/reports/three_day_report.rb",
    "lib/caperoma/models/task.rb",
    "lib/caperoma/models/tasks/bug.rb",
    "lib/caperoma/models/tasks/chore.rb",
    "lib/caperoma/models/tasks/feature.rb",
    "lib/caperoma/models/tasks/fix.rb",
    "lib/caperoma/models/tasks/meeting.rb",
    "lib/caperoma/models/tasks/modules/git.rb",
    "lib/caperoma/models/tasks/task_with_commit.rb",
    "lib/caperoma/models/tasks/task_with_separate_branch.rb",
    "lib/caperoma/services/airbrake_email_processor.rb",
    "lib/caperoma/services/pivotal_fetcher.rb",
    "lib/caperoma/version.rb",
    "spec/caperoma_spec.rb",
    "spec/factories/accounts.rb",
    "spec/factories/branches.rb",
    "spec/factories/projects.rb",
    "spec/factories/report_recipients.rb",
    "spec/factories/reports.rb",
    "spec/factories/tasks.rb",
    "spec/features/bug_spec.rb",
    "spec/features/chore_spec.rb",
    "spec/features/command_unknown_spec.rb",
    "spec/features/config_spec.rb",
    "spec/features/feature_spec.rb",
    "spec/features/finish_spec.rb",
    "spec/features/fix_spec.rb",
    "spec/features/meeting_spec.rb",
    "spec/features/projects_spec.rb",
    "spec/features/report_recipientss_spec.rb",
    "spec/features/reports_spec.rb",
    "spec/features/status_spec.rb",
    "spec/features/version_spec.rb",
    "spec/models/account_spec.rb",
    "spec/models/branch_spec.rb",
    "spec/models/bug_spec.rb",
    "spec/models/chore_spec.rb",
    "spec/models/daily_report_spec.rb",
    "spec/models/feature_spec.rb",
    "spec/models/fix_spec.rb",
    "spec/models/meeting_spec.rb",
    "spec/models/project_spec.rb",
    "spec/models/report_recipient_spec.rb",
    "spec/models/report_spec.rb",
    "spec/models/retrospective_report_spec.rb",
    "spec/models/task_spec.rb",
    "spec/models/task_with_commit_spec.rb",
    "spec/models/task_with_separate_branch_spec.rb",
    "spec/models/three_day_report_spec.rb",
    "spec/spec_helper.rb",
    "spec/support/capefile_generator.rb",
    "spec/support/database_cleaner.rb",
    "spec/support/stubs.rb"
  ]
  s.homepage = "http://github.com/zoopyserg/caperoma".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "Thanks for installing Caperoma! \n Run `caperoma setup` to create the database for your work.".freeze
  s.requirements = ["sqlite".freeze, "git".freeze]
  s.rubygems_version = "3.0.4".freeze
  s.summary = "Automate your workflow with Ruby / Git / Jira / PivotalTracker.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<actionpack>.freeze, ["~> 5.2.3"])
      s.add_runtime_dependency(%q<actionview>.freeze, ["~> 5.2.3"])
      s.add_runtime_dependency(%q<activerecord>.freeze, ["~> 5.2.3"])
      s.add_runtime_dependency(%q<activesupport>.freeze, ["~> 5.2.3"])
      s.add_runtime_dependency(%q<faraday>.freeze, ["~> 0.15.4"])
      s.add_runtime_dependency(%q<gmail>.freeze, ["~> 0.7.1"])
      s.add_runtime_dependency(%q<jbuilder>.freeze, ["~> 2.9.1"])
      s.add_runtime_dependency(%q<pivotal-tracker>.freeze, ["~> 0.5.13"])
      s.add_runtime_dependency(%q<rubocop>.freeze, ["~> 0.73.0"])
      s.add_runtime_dependency(%q<sqlite3>.freeze, ["~> 1.4.1"])
      s.add_runtime_dependency(%q<time_difference>.freeze, ["~> 0.7.0"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_development_dependency(%q<database_cleaner>.freeze, ["~> 1.7.0"])
      s.add_development_dependency(%q<factory_bot_rails>.freeze, ["~> 5.0.2"])
      s.add_development_dependency(%q<rdoc>.freeze, ["~> 6.1.1"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.8.0"])
      s.add_development_dependency(%q<shoulda>.freeze, ["~> 2.11.3"])
      s.add_development_dependency(%q<shoulda-matchers>.freeze, ["~> 4.1.0"])
      s.add_development_dependency(%q<timecop>.freeze, ["~> 0.9.1"])
    else
      s.add_dependency(%q<actionpack>.freeze, ["~> 5.2.3"])
      s.add_dependency(%q<actionview>.freeze, ["~> 5.2.3"])
      s.add_dependency(%q<activerecord>.freeze, ["~> 5.2.3"])
      s.add_dependency(%q<activesupport>.freeze, ["~> 5.2.3"])
      s.add_dependency(%q<faraday>.freeze, ["~> 0.15.4"])
      s.add_dependency(%q<gmail>.freeze, ["~> 0.7.1"])
      s.add_dependency(%q<jbuilder>.freeze, ["~> 2.9.1"])
      s.add_dependency(%q<pivotal-tracker>.freeze, ["~> 0.5.13"])
      s.add_dependency(%q<rubocop>.freeze, ["~> 0.73.0"])
      s.add_dependency(%q<sqlite3>.freeze, ["~> 1.4.1"])
      s.add_dependency(%q<time_difference>.freeze, ["~> 0.7.0"])
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_dependency(%q<database_cleaner>.freeze, ["~> 1.7.0"])
      s.add_dependency(%q<factory_bot_rails>.freeze, ["~> 5.0.2"])
      s.add_dependency(%q<rdoc>.freeze, ["~> 6.1.1"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.8.0"])
      s.add_dependency(%q<shoulda>.freeze, ["~> 2.11.3"])
      s.add_dependency(%q<shoulda-matchers>.freeze, ["~> 4.1.0"])
      s.add_dependency(%q<timecop>.freeze, ["~> 0.9.1"])
    end
  else
    s.add_dependency(%q<actionpack>.freeze, ["~> 5.2.3"])
    s.add_dependency(%q<actionview>.freeze, ["~> 5.2.3"])
    s.add_dependency(%q<activerecord>.freeze, ["~> 5.2.3"])
    s.add_dependency(%q<activesupport>.freeze, ["~> 5.2.3"])
    s.add_dependency(%q<faraday>.freeze, ["~> 0.15.4"])
    s.add_dependency(%q<gmail>.freeze, ["~> 0.7.1"])
    s.add_dependency(%q<jbuilder>.freeze, ["~> 2.9.1"])
    s.add_dependency(%q<pivotal-tracker>.freeze, ["~> 0.5.13"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.73.0"])
    s.add_dependency(%q<sqlite3>.freeze, ["~> 1.4.1"])
    s.add_dependency(%q<time_difference>.freeze, ["~> 0.7.0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<database_cleaner>.freeze, ["~> 1.7.0"])
    s.add_dependency(%q<factory_bot_rails>.freeze, ["~> 5.0.2"])
    s.add_dependency(%q<rdoc>.freeze, ["~> 6.1.1"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.8.0"])
    s.add_dependency(%q<shoulda>.freeze, ["~> 2.11.3"])
    s.add_dependency(%q<shoulda-matchers>.freeze, ["~> 4.1.0"])
    s.add_dependency(%q<timecop>.freeze, ["~> 0.9.1"])
  end
end

