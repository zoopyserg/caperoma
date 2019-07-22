# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    sequence(:email) { |n| "email#{n}@example.com" }
    sequence(:password) { |n| "password#{n}" }
    sequence(:username) { |n| "username#{n}" }
    type '--jira'
  end
end
