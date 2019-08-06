# frozen_string_literal: true

class Task < ActiveRecord::Base
  include Git

  belongs_to :project
  belongs_to :daily_report
  belongs_to :three_day_report
  belongs_to :retrospective_report

  validates :title, presence: true
  validates :pivotal_id, length: { minimum: 6 }, allow_blank: true, numericality: { only_integer: true }
  validates :additional_time, allow_blank: true, numericality: { only_integer: true }

  scope :unfinished, -> { where(finished_at: nil) }
  scope :finished, -> { where.not(finished_at: nil) }

  after_update :say_starting, if: [ :status_changed?, :status_started? ]
  after_update :set_start_time, if: [ :status_changed?, :status_started? ]
  after_update :create_jira, if: [ :status_changed?, :status_started? ]
  after_update :start_jira, if: [ :status_changed?, :status_started? ]
  after_update :create_pivotal, if: [ :status_changed?, :status_started? ]
  after_update :start_pivotal, if: [ :status_changed?, :status_started? ]
  after_update :say_started, if: [ :status_changed?, :status_started? ]

  after_update :say_finishing, if: [ :status_changed?, :status_finished? ]
  after_update :save_finished_time, if: [ :status_changed?, :status_finished? ]
  after_update :close_jira, if: [ :status_changed?, :status_finished? ]
  after_update :finish_pivotal, if: [ :status_changed?, :status_finished? ]
  after_update :show_time_spent, if: [ :status_changed?, :status_finished? ]
  after_update :say_finished, if: [ :status_changed?, :status_finished? ]

  after_update :say_pausing, if: [ :status_changed?, :status_paused? ]
  after_update :close_jira, if: [ :status_changed?, :status_paused? ]
  after_update :finish_pivotal, if: [ :status_changed?, :status_paused? ]
  after_update :save_finished_time, if: [ :status_changed?, :status_paused? ]
  after_update :show_time_spent, if: [ :status_changed?, :status_finished? ]
  after_update :say_paused, if: [ :status_changed?, :status_paused? ]

  after_update :say_aborting, if: [ :status_changed?, :status_aborted? ]
  after_update :close_jira, if: [ :status_changed?, :status_aborted? ]
  after_update :finish_pivotal, if: [ :status_changed?, :status_aborted? ]
  after_update :save_finished_time, if: [ :status_changed?, :status_aborted? ]
  after_update :show_time_spent, if: [ :status_changed?, :status_finished? ]
  after_update :say_aborted, if: [ :status_changed?, :status_aborted? ]

  after_update :say_aborting_without_time, if: [ :status_changed?, :status_aborted_without_time? ]
  after_update :close_jira, if: [ :status_changed?, :status_aborted_without_time? ]
  after_update :save_finished_time, if: [ :status_changed?, :status_aborted_without_time? ]
  after_update :show_time_spent, if: [ :status_changed?, :status_finished? ]
  after_update :say_aborted_without_time, if: [ :status_changed?, :status_aborted_without_time? ]

  after_update :show_created_issue_on_jira_status, if: [:jira_state_changed?, :jira_state_created_jira?, :not_test?, :create_on_jira?]
  after_update :show_no_access_to_create_issue_on_jira_status, if: [:jira_state_changed?, :jira_state_created_jira?, :not_test?, :create_on_jira?]
  after_update :show_no_connection_trying_to_create_issue_on_jira_status, if: [:jira_state_changed?, :jira_state_created_jira?, :not_test?, :create_on_jira?]
  after_update :show_unknown_error_trying_to_create_issue_on_jira_status, if: [:jira_state_changed?, :jira_state_created_jira?, :not_test?, :create_on_jira?]
  after_update :say_creating_in_jira, if: [:jira_state_changed?, :jira_state_created_jira?, :not_test?, :create_on_jira?]
  after_update :output_jira_key, if: [:jira_state_changed?, :jira_state_created_jira?, :not_test?, :create_on_jira?]

  after_update :show_started_issue_on_jira_status, if: [:jira_state_changed?, :jira_state_started_jira?, :not_test?, :start_on_jira?]
  after_update :show_no_access_to_start_issue_on_jira_status, if: [:jira_state_changed?, :jira_state_started_jira?, :not_test?, :start_on_jira?]
  after_update :show_no_connection_to_start_issue_on_jira_status, if: [:jira_state_changed?, :jira_state_started_jira?, :not_test?, :start_on_jira?]
  after_update :show_unknown_error_on_starting_issue_on_jira_status, if: [:jira_state_changed?, :jira_state_started_jira?, :not_test?, :start_on_jira?]
  after_update :say_starting_in_jira, if: [:jira_state_changed?, :jira_state_started_jira?, :not_test?, :start_on_jira?]

  after_update :create_jira_worklog, if: [:jira_state_changed?, :jira_state_closed_jira?, :not_test? ]
  after_update :show_closed_issue_on_jira_status, if: [:jira_state_changed?, :jira_state_closed_jira?, :not_test? ]
  after_update :show_no_access_to_close_issue_on_jira_status, if: [:jira_state_changed?, :jira_state_closed_jira?, :not_test? ]
  after_update :show_no_connection_to_close_issue_on_jira_status, if: [:jira_state_changed?, :jira_state_closed_jira?, :not_test? ]
  after_update :show_unknown_error_closing_issue_on_jira_status, if: [:jira_state_changed?, :jira_state_closed_jira?, :not_test? ]
  after_update :say_closing_in_jira, if: [:jira_state_changed?, :jira_state_closed_jira?, :not_test? ]

  after_update :show_created_issue_on_pivotal_status, if: [:pivotal_state_changed?, :pivotal_state_created_pivotal?, :not_test?, :create_on_pivotal?]
  after_update :show_no_access_trying_to_create_issue_on_pivotal_status, if: [:pivotal_state_changed?, :pivotal_state_created_pivotal?, :not_test?, :create_on_pivotal?]
  after_update :show_no_connection_trying_to_create_issue_on_pivotal_status, if: [:pivotal_state_changed?, :pivotal_state_created_pivotal?, :not_test?, :create_on_pivotal?]
  after_update :show_unknown_error_trying_to_create_issue_on_pivotal_status, if: [:pivotal_state_changed?, :pivotal_state_created_pivotal?, :not_test?, :create_on_pivotal?]
  after_update :say_creating_in_pivotal, if: [:pivotal_state_changed?, :pivotal_state_created_pivotal?, :not_test?, :create_on_pivotal?]

  after_update :show_start_on_pivotal_status, if: [:pivotal_state_changed?, :pivotal_state_started_pivotal?, :not_test?, :start_on_pivotal?]
  after_update :show_no_access_to_start_issue_on_pivotal_status, if: [:pivotal_state_changed?, :pivotal_state_started_pivotal?, :not_test?, :start_on_pivotal?]
  after_update :show_no_connection_to_start_issue_on_pivotal_status, if: [:pivotal_state_changed?, :pivotal_state_started_pivotal?, :not_test?, :start_on_pivotal?]
  after_update :show_unknown_error_on_starting_issue_on_pivotal_status, if: [:pivotal_state_changed?, :pivotal_state_started_pivotal?, :not_test?, :start_on_pivotal?]
  after_update :say_starting_in_pivotal, if: [:pivotal_state_changed?, :pivotal_state_started_pivotal?, :not_test?, :start_on_pivotal?]

  after_update :say_finishing, if: [:pivotal_state_changed?, :pivotal_state_finished_pivotal?, :not_test?, :finish_on_pivotal?]
  after_update :show_finished_on_pivotal_status, if: [:pivotal_state_changed?, :pivotal_state_finished_pivotal?, :not_test?, :finish_on_pivotal?]
  after_update :show_no_access_to_finish_on_pivotal_status, if: [:pivotal_state_changed?, :pivotal_state_finished_pivotal?, :not_test?, :finish_on_pivotal?]
  after_update :show_no_connection_to_finish_on_pivotal_status, if: [:pivotal_state_changed?, :pivotal_state_finished_pivotal?, :not_test?, :finish_on_pivotal?]
  after_update :show_unknown_error_on_finishing_on_pivotal_status, if: [:pivotal_state_changed?, :pivotal_state_finished_pivotal?, :not_test?, :finish_on_pivotal?]

  after_update :show_loged_work_to_jira_status, if: [ :jira_worklog_state_updated?, :jira_worklog_state_created_jira_worklog?, :not_test?, :should_log_work? ]
  after_update :show_no_access_to_log_work_to_jira_status, if: [ :jira_worklog_state_updated?, :jira_worklog_state_created_jira_worklog?, :not_test?, :should_log_work? ]
  after_update :show_no_connection_to_log_work_to_jira_status, if: [ :jira_worklog_state_updated?, :jira_worklog_state_created_jira_worklog?, :not_test?, :should_log_work? ]
  after_update :show_unknown_error_loging_work_to_jira_status, if: [ :jira_worklog_state_updated?, :jira_worklog_state_created_jira_worklog?, :not_test?, :should_log_work? ]
  after_update :say_logging_started, if: [ :jira_worklog_state_updated?, :jira_worklog_state_created_jira_worklog?, :not_test?, :should_log_work? ]

  after_update :output_jira_key, if: [:output_jira_key?, :jira_key_state_updated?, :jira_key_state_shown_jira_key? ]
  after_update :say_started_issue_on_pivotal, if: [:start_on_pivotal_status_state_changed?, :start_on_pivotal_status_state_shown_start_on_pivotal_status?, :started_issue_on_pivotal? ]
  after_update :say_no_access_to_start_issue_on_pivotal, if: [:no_access_to_start_issue_on_pivotal_status_state_changed?, :no_access_to_start_issue_on_pivotal_status_state_shown_no_access_to_start_issue_on_pivotal_status?, :no_access_to_start_issue_on_pivotal?]
  after_update :say_no_connection_to_start_issue_on_pivotal, if: [:no_connection_to_start_issue_on_pivotal_status_state_changed?, :no_connection_to_start_issue_on_pivotal_status_state_shown_no_connection_to_start_issue_on_pivotal_status?, :no_connection_to_start_issue_on_pivotal?]
  after_update :say_unknown_error_on_starting_issue_on_pivotal, if: [:unknown_error_on_starting_issue_on_pivotal_status_state_changed?, :unknown_error_on_starting_issue_on_pivotal_status_state_shown_unknown_error_on_starting_issue_on_pivotal_status?, :unknown_error_on_starting_issue_on_pivotal?]
  after_update :say_finished_on_pivotal, if: [:finished_on_pivotal_status_state_changed?, :finished_on_pivotal_status_state_shown_finished_on_pivotal_status?, :finished_on_pivotal?]
  after_update :say_no_access_to_finish_on_pivotal, if: [:no_access_to_finish_on_pivotal_status_state_changed?, :no_access_to_finish_on_pivotal_status_state_shown_no_access_to_finish_on_pivotal_status?, :no_access_to_finish_on_pivotal?]
  after_update :say_no_connection_to_finish_on_pivotal, if: [:no_connection_to_finish_on_pivotal_status_state_changed?, :no_connection_to_finish_on_pivotal_status_state_shown_no_connection_to_finish_on_pivotal_status?, :no_connection_to_finish_on_pivotal?]
  after_update :say_unknown_error_on_finishing_on_pivotal, if: [:unknown_error_on_finishing_on_pivotal_status_state_changed?, :unknown_error_on_finishing_on_pivotal_status_state_shown_unknown_error_on_finishing_on_pivotal_status?, :unknown_error_on_finishing_on_pivotal?]
  after_update :say_started_issue_on_jira, if: [:started_issue_on_jira_status_state_changed?, :started_issue_on_jira_status_state_shown_started_issue_on_jira_status?, :started_issue_on_jira?]
  after_update :say_no_access_to_start_issue_on_jira, if: [:no_access_to_start_issue_on_jira_status_state_changed?, :no_access_to_start_issue_on_jira_status_state_shown_no_access_to_start_issue_on_jira_status?, :no_access_to_start_issue_on_jira?]
  after_update :say_no_connection_to_start_issue_on_jira, if: [:no_connection_to_start_issue_on_jira_status_state_changed?, :no_connection_to_start_issue_on_jira_status_state_shown_no_connection_to_start_issue_on_jira_status?, :no_connection_to_start_issue_on_jira?]
  after_update :say_unknown_error_on_starting_issue_on_jira, if: [:unknown_error_on_starting_issue_on_jira_status_state_changed?, :unknown_error_on_starting_issue_on_jira_status_state_shown_unknown_error_on_starting_issue_on_jira_status?, :unknown_error_on_starting_issue_on_jira?]
  after_update :say_closed_issue_on_jira, if: [:closed_issue_on_jira_status_state_changed?, :closed_issue_on_jira_status_state_shown_closed_issue_on_jira_status?, :closed_issue_on_jira?]
  after_update :say_no_access_to_close_issue_on_jira, if: [:no_access_to_close_issue_on_jira_status_state_changed?, :no_access_to_close_issue_on_jira_status_state_shown_no_access_to_close_issue_on_jira_status?, :no_access_to_close_issue_on_jira?]
  after_update :say_no_connection_to_close_issue_on_jira, if: [:no_connection_to_close_issue_on_jira_status_state_changed?, :no_connection_to_close_issue_on_jira_status_state_shown_no_connection_to_close_issue_on_jira_status?, :no_connection_to_close_issue_on_jira?]
  after_update :say_unknown_error_closing_issue_on_jira, if: [:unknown_error_closing_issue_on_jira_status_state_changed?, :unknown_error_closing_issue_on_jira_status_state_shown_unknown_error_closing_issue_on_jira_status?, :unknown_error_closing_issue_on_jira?]
  after_update :say_loged_work_to_jira, if: [:loged_work_to_jira_status_state_changed?, :loged_work_to_jira_status_state_shown_loged_work_to_jira_status?, :loged_work_to_jira?]
  after_update :say_no_access_to_log_work_to_jira, if: [:no_access_to_log_work_to_jira_status_state_changed?, :no_access_to_log_work_to_jira_status_state_shown_no_access_to_log_work_to_jira_status?, :no_access_to_log_work_to_jira?]
  after_update :say_no_connection_to_log_work_to_jira, if: [:no_connection_to_log_work_to_jira_status_state_changed?, :no_connection_to_log_work_to_jira_status_state_shown_no_connection_to_log_work_to_jira_status?, :no_connection_to_log_work_to_jira?]
  after_update :say_unknown_error_loging_work_to_jira, if: [:unknown_error_loging_work_to_jira_status_state_changed?, :unknown_error_loging_work_to_jira_status_state_shown_unknown_error_loging_work_to_jira_status?, :unknown_error_loging_work_to_jira?]
  after_update :say_created_issue_on_pivotal, if: [:created_issue_on_pivotal_status_state_changed?, :created_issue_on_pivotal_status_state_shown_created_issue_on_pivotal_status?, :created_issue_on_pivotal?]
  after_update :say_no_access_trying_to_create_issue_on_pivotal, if: [:no_access_trying_to_create_issue_on_pivotal_status_state_changed?, :no_access_trying_to_create_issue_on_pivotal_status_state_shown_no_access_trying_to_create_issue_on_pivotal_status?, :no_access_trying_to_create_issue_on_pivotal?]
  after_update :say_no_connection_trying_to_create_issue_on_pivotal, if: [:no_connection_trying_to_create_issue_on_pivotal_status_state_changed?, :no_connection_trying_to_create_issue_on_pivotal_status_state_shown_no_connection_trying_to_create_issue_on_pivotal_status?, :no_connection_trying_to_create_issue_on_pivotal?]
  after_update :say_no_connection_trying_to_create_issue_on_pivotal, if: [:unknown_error_trying_to_create_issue_on_pivotal_status_state_changed?, :unknown_error_trying_to_create_issue_on_pivotal_status_state_shown_unknown_error_trying_to_create_issue_on_pivotal_status?, :unknown_error_trying_to_create_issue_on_pivotal?]
  after_update :say_created_issue_on_jira, if: [:created_issue_on_jira_status_state_changed?, :created_issue_on_jira_status_state_shown_created_issue_on_jira_status?, :created_issue_on_jira?]
  after_update :say_no_access_to_create_issue_on_jira, if: [:no_access_to_create_issue_on_jira_status_state_changed?, :no_access_to_create_issue_on_jira_status_state_shown_no_access_to_create_issue_on_jira_status?, :no_access_to_create_issue_on_jira?]
  after_update :say_no_connection_trying_to_create_issue_on_jira, if: [:no_connection_trying_to_create_issue_on_jira_status_state_changed?, :no_connection_trying_to_create_issue_on_jira_status_state_shown_no_connection_trying_to_create_issue_on_jira_status?, :no_connection_trying_to_create_issue_on_jira?]
  after_update :say_unknown_error_trying_to_create_issue_on_jira, if: [:unknown_error_trying_to_create_issue_on_jira_status_state_changed?, :unknown_error_trying_to_create_issue_on_jira_status_state_shown_unknown_error_trying_to_create_issue_on_jira_status?, :unknown_error_trying_to_create_issue_on_jira?]

  def start
    self.update state: 'started'
  end

  def finish
    self.update state: 'finished'
  end

  def pause
    self.update state: 'paused'
  end

  def abort
    self.update state: 'aborted'
  end

  def abort_without_time
    self.update state: 'aborted_without_time'
  end

  def create_jira
    self.update jira_state: 'created'
  end

  def start_jira
    self.update jira_state: 'started'
  end

  def close_jira
    self.update jira_state: 'closed'
  end

  def create_pivotal
    self.update :pivotal_state, 'created'
  end

  def start_pivotal
    self.update :pivotal_state, 'started'
  end

  def finish_pivotal
    self.update :pivotal_state, 'finished'
  end

  def create_jira_worklog
    self.update jira_worklog_state: 'created_jira_worklog'
  end

  def show_jira_key
    self.update jira_key_state: 'shown_jira_key'
  end

  def show_start_on_pivotal_status
    self.update start_on_pivotal_status_state: 'shown_start_on_pivotal_status'
  end

  def show_no_access_to_start_issue_on_pivotal_status
    self.update no_access_to_start_issue_on_pivotal_status_state: 'shown_no_access_to_start_issue_on_pivotal_status'
  end

  def show_no_connection_to_start_issue_on_pivotal_status
    self.update no_connection_to_start_issue_on_pivotal_status_state: 'shown_no_connection_to_start_issue_on_pivotal_status'
  end

  def show_unknown_error_on_starting_issue_on_pivotal_status
    self.update unknown_error_on_starting_issue_on_pivotal_status_state: 'shown_unknown_error_on_starting_issue_on_pivotal_status'
  end

  def show_finished_on_pivotal_status
    self.update finished_on_pivotal_status_state: 'shown_finished_on_pivotal_status'
  end

  def show_no_access_to_finish_on_pivotal_status
    self.update no_access_to_finish_on_pivotal_status_state: 'shown_no_access_to_finish_on_pivotal_status'
  end

  def show_no_connection_to_finish_on_pivotal_status
    self.update no_connection_to_finish_on_pivotal_status_state: 'shown_no_connection_to_finish_on_pivotal_status'
  end

  def show_unknown_error_on_finishing_on_pivotal_status
    self.update unknown_error_on_finishing_on_pivotal_status_state: 'shown_unknown_error_on_finishing_on_pivotal_status'
  end

  def show_started_issue_on_jira_status
    self.update started_issue_on_jira_status_state: 'shown_started_issue_on_jira_status'
  end

  def show_no_access_to_start_issue_on_jira_status
    self.update no_access_to_start_issue_on_jira_status_state: 'shown_no_access_to_start_issue_on_jira_status'
  end

  def show_no_connection_to_start_issue_on_jira_status
    self.update no_connection_to_start_issue_on_jira_status_state: 'shown_no_connection_to_start_issue_on_jira_status'
  end

  def show_unknown_error_on_starting_issue_on_jira_status
    self.update unknown_error_on_starting_issue_on_jira_status_state: 'shown_unknown_error_on_starting_issue_on_jira_status'
  end

  def show_closed_issue_on_jira_status
    self.update closed_issue_on_jira_status_state: 'shown_closed_issue_on_jira_status'
  end

  def show_no_access_to_close_issue_on_jira_status
    self.update no_access_to_close_issue_on_jira_status_state: 'shown_no_access_to_close_issue_on_jira_status'
  end

  def show_no_connection_to_close_issue_on_jira_status
    self.update no_connection_to_close_issue_on_jira_status_state: 'shown_no_connection_to_close_issue_on_jira_status'
  end

  def show_unknown_error_closing_issue_on_jira_status
    self.update unknown_error_closing_issue_on_jira_status_state: 'shown_unknown_error_closing_issue_on_jira_status'
  end

  def show_loged_work_to_jira_status
    self.update loged_work_to_jira_status_state: 'shown_loged_work_to_jira_status'
  end

  def show_no_access_to_log_work_to_jira_status
    self.update no_access_to_log_work_to_jira_status_state: 'shown_no_access_to_log_work_to_jira_status'
  end

  def show_no_connection_to_log_work_to_jira_status
    self.update no_connection_to_log_work_to_jira_status_state: 'shown_no_connection_to_log_work_to_jira_status'
  end

  def show_unknown_error_loging_work_to_jira_status
    self.update unknown_error_loging_work_to_jira_status_state: 'shown_unknown_error_loging_work_to_jira_status'
  end

  def show_created_issue_on_pivotal_status
    self.update created_issue_on_pivotal_status_state: 'shown_created_issue_on_pivotal_status'
  end

  def show_no_access_trying_to_create_issue_on_pivotal_status
    self.update no_access_trying_to_create_issue_on_pivotal_status_state: 'shown_no_access_trying_to_create_issue_on_pivotal_status'
  end

  def show_no_connection_trying_to_create_issue_on_pivotal_status
    self.update no_connection_trying_to_create_issue_on_pivotal_status_state: 'shown_no_connection_trying_to_create_issue_on_pivotal_status'
  end

  def show_unknown_error_trying_to_create_issue_on_pivotal_status
    self.update unknown_error_trying_to_create_issue_on_pivotal_status_state: 'shown_unknown_error_trying_to_create_issue_on_pivotal_status'
  end

  def show_created_issue_on_jira_status
    self.update created_issue_on_jira_status_state: 'shown_created_issue_on_jira_status'
  end

  def show_no_access_to_create_issue_on_jira_status
    self.update no_access_to_create_issue_on_jira_status_state: 'shown_no_access_to_create_issue_on_jira_status'
  end

  def show_no_connection_trying_to_create_issue_on_jira_status
    self.update no_connection_trying_to_create_issue_on_jira_status_state: 'shown_no_connection_trying_to_create_issue_on_jira_status'
  end

  def show_unknown_error_trying_to_create_issue_on_jira_status
    self.update unknown_error_trying_to_create_issue_on_jira_status_state: 'shown_unknown_error_trying_to_create_issue_on_jira_status'
  end

  def self.finish_started(comment)
    unfinished.each do |task|
      task.update_column :comment, comment
      task.finish!
    end
  end

  def self.pause_started(comment)
    unfinished.each do |task|
      task.update_column :comment, comment
      task.pause!
    end
  end

  def self.abort_started(comment)
    unfinished.each do |task|
      task.update_column :comment, comment
      task.abort!
    end
  end

  def self.abort_started_without_time(comment)
    unfinished.each do |task|
      task.update_column :comment, comment
      task.abort_without_time!
    end
  end

  def self.status
    if unfinished.empty?
      puts 'You are not working on anything now.'
    else
      unfinished.each do |task|
        puts 'You are working on: '
        puts "Title: #{task.title}"
        puts "Type: #{task.type}"
        puts "Jira ID: #{task.jira_key} (#{task.jira_live_url})." if task.jira_key.present?
        puts "Pivotal ID: #{task.pivotal_id} (#{task.pivotal_url})" if task.pivotal_id.present?
        puts "Time spent at the moment: #{task.time_spent_so_far}"
        puts "Branch with the task: #{task.branch}" if task.branch.present?
        puts "Pull request will be sent to this branch: #{task.parent_branch}" if task.parent_branch.present?
        puts "Project location: #{task.project.folder_path}"
      end
    end
  end

  def time_spent_so_far
    result = TimeDifference.between(started_at, Time.now).in_minutes

    hours = (result / 60).to_i
    minutes = (result - hours * 60).to_i

    "#{hours}h #{minutes}m"
  end

  def time_spent
    result = TimeDifference.between(started_at, finished_at).in_minutes

    hours = (result / 60).to_i
    minutes = (result - hours * 60).to_i

    "#{hours}h #{minutes}m"
  end

  def pivotal_url
    "https://www.pivotaltracker.com/story/show/#{pivotal_id}" if pivotal_id.present?
  end

  def jira_live_url
    "#{project.jira_url}browse/#{jira_key}" if jira_key.present?
  end

  def time_spent_in_minutes
    TimeDifference.between(started_at, finished_at).in_minutes # TODO: test
  end

  private

  def should_log_work?
    time_spent_so_far != '0h 0m' && Account.jira.present?
  end

  def save_finished_time
    update_attribute(:finished_at, Time.now)
  end

  def show_time_spent
    puts time_spent
  end

  def say_starting
    puts 'Starting a task'
  end

  def say_started
    puts 'A task is started'
  end

  def say_finishing
    puts 'Finishing current task'
  end

  def say_finished
    puts 'Current task finished'
  end

  def say_pausing
    puts 'Pausing current task'
  end

  def say_paused
    puts 'Current task paused'
  end

  def say_aborting
    puts 'Aborting current task'
  end

  def say_aborted
    puts 'Current task aborted'
  end

  def say_aborting_without_time
    puts 'Aborting current task without putting time into Jira'
  end

  def say_aborted_without_time
    puts 'Current task aborted without putting time into Jira'
  end

  def say_creating_in_jira
    puts 'Creating an issue in Jira'
  end

  def say_creating_in_pivotal
    puts 'Creating a task in Pivotal'
  end

  def say_starting_in_pivotal
    puts 'Starting the task in Pivotal'
  end

  def say_finishing_in_pivotal
    puts 'Finishing the task in Pivotal'
  end

  def say_starting_in_jira
    puts 'Starting the issue in Jira'
  end

  def say_closing_in_jira
    puts 'Closing the issue in Jira'
  end

  def say_logging_started
    puts 'Logging work to Jira'
  end

  def story_type
    'chore' # default is chore, it's never used directly
  end

  def create_on_jira?
    Account.jira.present?
  end

  def start_on_jira?
    jira_key.present? && Account.jira.present?
  end

  def create_on_pivotal?
    pivotal_id.blank? && this_is_a_type_a_user_wants_to_create? && Account.pivotal.present?
  end

  def start_on_pivotal?
    pivotal_id.present? && Account.pivotal.present?
  end

  def finish_on_pivotal?
    pivotal_id.present? && Account.pivotal.present?
  end

  def this_is_a_type_a_user_wants_to_create?
    false
  end

  def set_start_time
    time = Time.now
    time -= additional_time.to_i.minutes if additional_time.present?
    self.started_at = time
  end

  def output_jira_key
    puts jira_key
  end

  def output_jira_key?
    jira_key.present?
  end

  def start_issue_on_pivotal_data
    Jbuilder.encode do |j|
      j.current_state 'started'
    end
  end

  def pivotal_connection
    @pivotal_connection ||= Faraday.new(url: 'https://www.pivotaltracker.com/') do |c|
      c.adapter Faraday.default_adapter
    end
  end

  def start_issue_on_pivotal_response
    @start_issue_on_pivotal_response ||= pivotal_connection.put do |request|
      request.url "services/v5/stories/#{pivotal_id}"
      request.body = start_issue_on_pivotal_data
      request.headers['User-Agent'] = 'Caperoma'
      request.headers['Content-Type'] = 'application/json'
      request.headers['X-TrackerToken'] = Account.pivotal.password
    end
  end

  def success_status?(status)
    [200, 201, 202, 204, 301, 302, 303, 304, 307].include? status
  end

  def unknown_status?(status)
    ![200, 201, 202, 204, 301, 302, 303, 304, 307, 401, 403, 404].include? status
  end

  def forbidden_status?(status)
    [401, 403].include? status
  end

  def not_found_status?(status)
    [404].include? status
  end

  def started_issue_on_pivotal?
    success_status? start_issue_on_pivotal_response.status
  end

  def say_started_issue_on_pivotal
    puts 'Started the task in Pivotal'
  end

  def no_access_to_start_issue_on_pivotal?
    forbidden_status? start_issue_on_pivotal_response.status
  end

  def say_no_access_to_start_issue_on_pivotal
    puts "No access to the task ##{pivotal_id} in Pivotal. Maybe login or api_key are incorrect."
  end

  def no_connection_to_start_issue_on_pivotal?
    not_found_status? start_issue_on_pivotal_response.status
  end

  def say_no_connection_to_start_issue_on_pivotal
    puts "A task with ID ##{pivotal_id} is not found in Pivotal."
  end

  def unknown_error_on_starting_issue_on_pivotal?
    unknown_status? start_issue_on_pivotal_response.status
  end

  def say_unknown_error_on_starting_issue_on_pivotal
    puts 'Could not start the task in Pivotal.'
    puts "Error status: #{start_issue_on_pivotal_response.status}"
    puts "Message from server: #{start_issue_on_pivotal_response.reason_phrase}"
  end

  # rescue Faraday::ConnectionFailed
  #   puts 'Connection failed. Performing the task without requests to Pivotal.'
  # end

  def finish_on_pivotal_data
    Jbuilder.encode do |j|
      j.current_state 'finished'
    end
  end

  def finish_on_pivotal_response
    @finish_on_pivotal_response ||= pivotal_connection.put do |request|
      request.url "services/v5/stories/#{pivotal_id}"
      request.body = finish_on_pivotal_data
      request.headers['User-Agent'] = 'Caperoma'
      request.headers['Content-Type'] = 'application/json'
      request.headers['X-TrackerToken'] = Account.pivotal.password
    end
  end

  def finished_on_pivotal?
    success_status? finish_on_pivotal_response.status
  end

  def say_finished_on_pivotal
    puts 'Finished the task in Pivotal'
  end

  def no_access_to_finish_on_pivotal?
    forbidden_status? finish_on_pivotal_response.status
  end

  def say_no_access_to_finish_on_pivotal
    puts "No access to the task ##{pivotal_id} in Pivotal. Maybe login or api_key are incorrect."
  end

  def no_connection_to_finish_on_pivotal?
    not_found_status? finish_on_pivotal_response.status
  end

  def say_no_connection_to_finish_on_pivotal
    puts "A task with ID ##{pivotal_id} is not found in Pivotal."
  end

  def unknown_error_on_finishing_on_pivotal?
    unknown_status? finish_on_pivotal_response.status
  end

  def say_unknown_error_on_finishing_on_pivotal
    puts 'Could not finish the task in Pivotal.'
    puts "Error status: #{finish_on_pivotal_response.status}"
    puts "Message from server: #{finish_on_pivotal_response.reason_phrase}"
  end

  # rescue Faraday::ConnectionFailed
  #   puts 'Connection failed. Performing the task without requests to Pivotal.'
  # end

  def start_issue_on_jira_data
    Jbuilder.encode do |j|
      j.transition { j.id project.jira_transition_id_in_progress }
    end
  end

  def start_issue_on_jira_response
    @start_issue_on_jira_response ||= jira_connection.post do |request|
      request.url "rest/api/3/issue/#{jira_key}/transitions"
      request.body = start_issue_on_jira_data
      request.headers['User-Agent'] = 'Caperoma'
      request.headers['Content-Type'] = 'application/json'
    end
  end

  def started_issue_on_jira?
    success_status? start_issue_on_jira_response.status
  end

  def say_started_issue_on_jira
    puts 'Started the issue in Jira'
  end

  def no_access_to_start_issue_on_jira?
    forbidden_status? start_issue_on_jira_response.status
  end

  def say_no_access_to_start_issue_on_jira
    puts "No access to the task #{jira_key} in Jira. Maybe login or api_key are incorrect."
  end

  def no_connection_to_start_issue_on_jira?
    not_found_status? start_issue_on_jira_response.status
  end

  def say_no_connection_to_start_issue_on_jira
    puts "A task with ID #{jira_key} is not found in Jira."
  end

  def unknown_error_on_starting_issue_on_jira?
    unknown_status? start_issue_on_jira_response.status
  end

  def say_unknown_error_on_starting_issue_on_jira
    puts 'Could not start the issue in Jira.'
    puts "Error status: #{start_issue_on_jira_response.status}"
    puts "Message from server: #{start_issue_on_jira_response.reason_phrase}"
  end
  # rescue Faraday::ConnectionFailed
  #   puts 'Connection failed. Performing the task without requests to Jira.'
  # end

  def close_issue_on_jira_data
    Jbuilder.encode do |j|
      j.transition { j.id project.jira_transition_id_done }
    end
  end

  def close_issue_on_jira_response
    @close_issue_on_jira_response ||= jira_connection.post do |request|
      request.url "rest/api/3/issue/#{jira_key}/transitions"
      request.body = close_issue_on_jira_data
      request.headers['User-Agent'] = 'Caperoma'
      request.headers['Content-Type'] = 'application/json'
    end
  end

  def closed_issue_on_jira?
    success_status? close_issue_on_jira_response.status
  end

  def say_closed_issue_on_jira
    puts 'Closed the issue in Jira'
  end

  def no_access_to_close_issue_on_jira?
    forbidden_status? close_issue_on_jira_response.status
  end

  def say_no_access_to_close_issue_on_jira
    puts "No access to the task #{jira_key} in Jira. Maybe login or api_key are incorrect."
  end

  def no_connection_to_close_issue_on_jira?
    not_found_status? close_issue_on_jira_response.status
  end

  def say_no_connection_to_close_issue_on_jira
    puts "A task with ID #{jira_key} is not found in Jira."
  end

  def unknown_error_closing_issue_on_jira?
    unknown_status? close_issue_on_jira_response.status
  end

  def say_unknown_error_closing_issue_on_jira
    puts 'Could not close the issue in Jira.'
    puts "Error status: #{close_issue_on_jira_response.status}"
    puts "Message from server: #{close_issue_on_jira_response.reason_phrase}"
  end
  # rescue Faraday::ConnectionFailed
  #   puts 'Connection failed. Performing the task without requests to Jira.'
  # end

  def log_work_to_jira_data
    Jbuilder.encode do |j|
      j.comment comment
      j.started current_time
      j.timeSpent time_spent
    end
  end

  # create jira work log event
  def log_work_to_jira_response
    @log_work_to_jira_response ||= jira_connection.post do |request|
      request.url "rest/api/3/issue/#{jira_key}/worklog"
      request.body = log_work_to_jira_data(comment)
      request.headers['User-Agent'] = 'Caperoma'
      request.headers['Content-Type'] = 'application/json'
    end
  end

  def loged_work_to_jira?
    success_status? log_work_to_jira_response.status
  end

  def say_loged_work_to_jira
    puts 'Work logged to Jira'
  end

  def no_access_to_log_work_to_jira?
    forbidden_status?  log_work_to_jira_response.status
  end

  def say_no_access_to_log_work_to_jira
    puts "No access to the task #{jira_key} in Jira. Maybe login or api_key are incorrect."
  end

  def no_connection_to_log_work_to_jira?
    not_found_status? log_work_to_jira_response.status
  end

  def say_no_connection_to_log_work_to_jira
    puts "A task with ID #{jira_key} is not found in Jira."
  end

  def unknown_error_loging_work_to_jira?
    unknown_status? log_work_to_jira_response.status
  end

  def say_unknown_error_loging_work_to_jira
    puts 'Could not log work to Jira.'
    puts "Error status: #{log_work_to_jira_response.status}"
    puts "Message from server: #{log_work_to_jira_response.reason_phrase}"
  end
  # rescue Faraday::ConnectionFailed
  #   puts 'Connection failed. Performing the task without requests to Jira.'
  # end

  def current_time
    Time.now.in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00.000+0000')
  end

  def issue_type
    project.feature_jira_task_id
  end

  def create_issue_on_pivotal_data
    Jbuilder.encode do |j|
      j.current_state 'unstarted'
      j.estimate pivotal_estimate == 0 ? 1 : pivotal_estimate
      j.name title.to_s
      j.description description
      j.story_type story_type
    end
  end

  def create_issue_on_pivotal_response
    @create_issue_on_pivotal_response ||= pivotal_connection.post do |request|
      request.url "services/v5/projects/#{project.pivotal_tracker_project_id}/stories"
      request.body = create_issue_on_pivotal_data
      request.headers['User-Agent'] = 'Caperoma'
      request.headers['Content-Type'] = 'application/json'
      request.headers['X-TrackerToken'] = Account.pivotal.password
    end
  end

  def created_issue_on_pivotal?
    success_status? create_issue_on_pivotal_response.status
  end

  def say_created_issue_on_pivotal
    puts 'Created the task in Pivotal'
  end

  def save_data_received_after_created_issue_on_pivotal
    result = JSON.parse create_issue_on_pivotal_response.body

    update_attributes(
      pivotal_id: result['id']
    )
  end

  def no_access_trying_to_create_issue_on_pivotal?
    forbidden_status? create_issue_on_pivotal_response.status
  end

  def say_no_access_trying_to_create_issue_on_pivotal
    puts "No access to the server. Maybe login, api_key or Pivotal Project ID ##{project.pivotal_tracker_project_id} is incorrect."
  end

  def no_connection_trying_to_create_issue_on_pivotal?
    not_found_status?create_issue_on_pivotal_response.status
  end

  def say_no_connection_trying_to_create_issue_on_pivotal
    puts "Resource not found. Maybe Pivotal Project ID ##{project.pivotal_tracker_project_id} is incorrect."
  end

  def unknown_error_trying_to_create_issue_on_pivotal?
    unknown_status? create_issue_on_pivotal_response.status
  end

  def say_no_connection_trying_to_create_issue_on_pivotal
    puts 'Could not create the task in Pivotal.'
    puts "Error status: #{create_issue_on_pivotal_response.status}"
    puts "Message from server: #{create_issue_on_pivotal_response.reason_phrase}"
  end

  # rescue Faraday::ConnectionFailed
  #   puts 'Connection failed. Performing the task without requests to Pivotal.'
  # end

  def create_issue_on_jira_data
    hash = {
      fields: {
        summary: title.to_s,
        issuetype: {
          id: issue_type
        },
        project: {
          id: project.jira_project_id.to_s
        },
        assignee: {
          name: Account.jira.username
        }
      }
    }

    description_hash = {
      type: 'doc',
      version: 1,
      content: [
        {
          type: 'paragraph',
          content: [
            {
              text: description,
              type: 'text'
            }
          ]
        }
      ]
    }

    hash[:fields][:description] = description_hash if description.present?

    hash.to_json
  end

  def jira_connection
    @jira_connection ||= Faraday.new(url: project.jira_url) do |c|
      c.basic_auth(Account.jira.email, Account.jira.password)
      c.adapter Faraday.default_adapter
    end
  end

  def create_issue_on_jira_response
    @create_issue_on_jira_response ||= jira_connection.post do |request|
      request.url 'rest/api/3/issue.json'
      request.body = create_issue_on_jira_data
      request.headers['User-Agent'] = 'Caperoma'
      request.headers['Content-Type'] = 'application/json'
    end
  end

  def created_issue_on_jira?
    success_status? create_issue_on_jira_response.status
  end

  def say_created_issue_on_jira
    puts 'Created the issue in Jira'
  end

  def no_access_to_create_issue_on_jira?
    forbidden_status? create_issue_on_jira_response.status
  end

  def say_no_access_to_create_issue_on_jira
    puts "Forbidden access to the resource in Jira. Maybe login, api_key or Jira project id #{project.jira_project_id} are incorrect."
  end

  def save_data_received_after_creating_issue_on_jira
    result = JSON.parse create_issue_on_jira_response.body

    update_attributes(
      jira_id: result['id'],
      jira_key: result['key'],
      jira_url: result['self']
    )
  end

  def no_connection_trying_to_create_issue_on_jira?
    not_found_status? create_issue_on_jira_response.status
  end

  def say_no_connection_trying_to_create_issue_on_jira
    puts "Not found the resource in Jira. Maybe the Jira Project ID #{project.jira_project_id} is incorrect."
  end

  def unknown_error_trying_to_create_issue_on_jira?
    unknown_status? create_issue_on_jira_response.status
  end

  def say_unknown_error_trying_to_create_issue_on_jira
    puts 'Could not create the issue in Jira.'
    puts "Error status: #{create_issue_on_jira_response.status}"
    puts "Message from server: #{create_issue_on_jira_response.reason_phrase}"
  end
  # rescue Faraday::ConnectionFailed
  #   puts 'Connection failed. Performing the task without requests to Jira.'
  # end

  def not_test?
    ENV['CAPEROMA_INTEGRATION_TEST'].blank?
  end

  def enable_git?
    ENV['CAPEROMA_TEST'].blank? && ENV['CAPEROMA_INTEGRATION_TEST'].blank?
  end

  def status_started?
    status == 'finished'
  end

  def status_finished?
    status == 'finished'
  end
end
