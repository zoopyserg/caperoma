# frozen_string_literal: true

FactoryBot.define do
  factory :branch do
    project

    sequence(:name) { |n| "ruc-#{n}-branch" }
  end
end
