# frozen_string_literal: true

FactoryBot.define do
  factory :report do
    content 'did this and that'
  end

  factory :daily_report, parent: :report, class: 'DailyReport' do
  end

  factory :three_day_report, parent: :report, class: 'ThreeDayReport' do
  end

  factory :retrospective_report, parent: :report, class: 'RetrospectiveReport' do
  end
end
