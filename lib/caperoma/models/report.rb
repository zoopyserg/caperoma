# frozen_string_literal: true

class Report < ApplicationRecord
  include ActionView::Helpers::TextHelper
  has_many :tasks

  after_initialize :set_variables

  after_create :assign_unreported_tasks
  after_create :send_email, if: :not_test?
  after_create :update_content

  def self.schedule
    # may screw up existing cron tasks
    puts 'Turning on auto reports'
    root = File.dirname __dir__
    crontab_file = File.join root, 'config', 'crontab'
    `crontab #{crontab_file}`
    # > whenever --update-crontab caperoma
    puts 'Auto reports turned on'
  end

  def self.unschedule
    puts 'Turning off auto reports'
    puts 'pending'
    puts 'Auto reports turned off'
  end

  private

  def set_variables
    @smtp = Net::SMTP.new 'smtp.gmail.com', 587
    @smtp.enable_starttls
    @account = Account.gmail
  end

  # most of it is related to email formatting

  def assign_unreported_tasks
    unreported_tasks.update_all(report_sti_key => id)
  end

  def send_email
    @smtp.start('gmail.com', @account.email, @account.password, :login, &send_email_method)
  end

  def send_email_method
    proc { @smtp.send_message(report_msg, @account.email, to_addresses) }
  end

  def unreported_tasks
    Task.finished.where(report_sti_key => nil)
  end

  def report_sti_key
    self.class.to_s.foreign_key
  end

  def update_content
    update content: report_msg
  end

  def reported_tasks
    tasks.finished.order(finished_at: :desc)
  end

  def total_time_spent
    "#{hours_spent}h #{remaining_minutes_spent}m"
  end

  def hours_spent
    (total_time_spent_in_minutes / 60).to_i
  end

  def remaining_minutes_spent
    (total_time_spent_in_minutes - hours_spent * 60).to_i
  end

  def total_time_spent_in_minutes
    reported_tasks.all.collect(&:time_spent_in_minutes).sum
  end

  def not_test?
    ENV['CAPEROMA_INTEGRATION_TEST'].blank? && ENV['CAPEROMA_TEST'].blank?
  end

  def to_addresses
    ReportRecipient.all.collect(&:email)
  end

  def report_msg
    report_msg_content.join("\n")
  end

  def report_msg_content
    ["subject: #{report_subject}", 'Content-Type: text/html; charset=UTF-8', report_body]
  end

  def formatted_day(day)
    day.strftime('%b %-d')
  end

  def formatted_start_day
    formatted_day(start_day)
  end

  def formatted_end_day
    formatted_day(end_day)
  end

  def timeframe
    [formatted_start_day, formatted_end_day].join(' - ')
  end

  def report_subject
    [subject_name, subject_timeframe].join(' ')
  end

  def subject_timeframe
    "(#{timeframe})"
  end

  def report_body
    [
      "\n",
      "<h2>Done during #{timeframe}:</h2>",
      '<br />',
      '<table style="width: 100%;text-align: left;">',
      '<thead>',
      '<tr><th>Jira</th><th>Pivotal</th><th>Title</th><th>Time spent</th></tr>',
      '</thead>',
      '<tbody>',
      reported_tasks_rows,
      '</tbody>',
      '</table>',
      '<br />',
      "<strong>Total time spent during #{timeframe}:</strong> #{total_time_spent}."
    ].flatten.join("\n")
  end

  def reported_tasks_rows
    reported_tasks.collect { |task| table_row(task) }.join("\n")
  end

  def table_row(task)
    '<tr>' + task_row_data(task).collect { |task| '<td>' + task + '</td>' }.join("\n") + '</tr>'
  end

  def task_row_data(task)
    [
      jira_url_or_blank(task),
      pivotal_url_or_blank(task),
      formatted_title(task),
      task.time_spent
    ]
  end

  def formatted_title(task)
    truncate(task.title, length: 90)
  end

  def jira_url_or_blank(task)
    task.jira_key.present? ? jira_formatted_url(task) : ''
  end

  def jira_formatted_url(task)
    "<a href=\"#{task.jira_live_url}\">#{task.jira_key}</a>"
  end

  def pivotal_url_or_blank(task)
    task.pivotal_id.present? ? pivotal_formatted_url(task) : ''
  end

  def pivotal_formatted_url(task)
    "<a href=\"#{task.pivotal_url}\">#{task.pivotal_id}</a>"
  end
end
