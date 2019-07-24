# frozen_string_literal: true

FactoryBot.define do
  factory :task do
    project

    sequence(:title) { |n| "Refactoring some thunk of code ##{n}" }
    sequence(:description) { |n| "This was a very nice task, solved it #{n}" }
    sequence(:jira_key) { |n| "RUC-#{n}" }
    sequence(:url) { |n| "http://www.my_jira_site.com/tasks/RUC-#{n}" }

    started_at Time.now
    finished_at Time.now
  end

  factory :chore, parent: :task, class: 'Chore' do
  end

  factory :meeting, parent: :task, class: 'Meeting' do
  end

  factory :task_with_commit, parent: :task, class: 'TaskWithCommit' do
  end

  factory :fix, parent: :task_with_commit, class: 'Fix' do
  end

  factory :task_with_separate_branch, parent: :task_with_commit, class: 'TaskWithSeparateBranch' do
  end

  factory :feature, parent: :task_with_separate_branch, class: 'Feature' do
  end

  factory :bug, parent: :task_with_separate_branch, class: 'Bug' do
  end
end
