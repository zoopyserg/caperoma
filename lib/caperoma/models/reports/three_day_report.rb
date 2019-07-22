# frozen_string_literal: true

class ThreeDayReport < Report
  has_many :tasks

  private

  def subject_name
    'Three Day Report'
  end

  def start_day
    Date.today - 2.days
  end

  def end_day
    Date.today
  end
end
