# frozen_string_literal: true

FactoryGirl.define do
  factory :project do
    sequence(:name) { |n| "Refactoring some thunk of code ##{n}" }
    sequence(:jira_project_id) { |n| 123_456 + n }
  end
end
