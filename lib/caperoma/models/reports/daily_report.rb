# frozen_string_literal: true

class DailyReport < Report
  has_many :tasks

  private

  def subject_name
    'Daily Report'
  end

  def body_heading
    'Today'
  end

  def timeframe
    formatted_day(start_day)
  end

  def start_day
    Date.today
  end
end
