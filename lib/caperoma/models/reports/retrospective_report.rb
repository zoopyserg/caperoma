# frozen_string_literal: true

class RetrospectiveReport < Report
  has_many :tasks

  private

  def subject_name
    'Weekly Report'
  end

  def start_day
    Date.today.beginning_of_week
  end

  def end_day
    Date.today
  end
end
