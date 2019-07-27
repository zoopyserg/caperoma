# frozen_string_literal: true

class Task < ActiveRecord::Base
  include Git
  include AASM

  belongs_to :project
  belongs_to :daily_report
  belongs_to :three_day_report
  belongs_to :retrospective_report

  validates :title, presence: true
  validates :pivotal_id, length: { minimum: 6 }, allow_blank: true, numericality: { only_integer: true }
  validates :additional_time, allow_blank: true, numericality: { only_integer: true }

  scope :unfinished, -> { where(finished_at: nil) }
  scope :finished, -> { where.not(finished_at: nil) }

  aasm column: 'state', whiny_transitions: false do
    state :created, initial: true
    state :started
    state :finished
    state :paused
    state :aborted
    state :aborted_without_time

    event :start, binding_events: %i[set_start_time create_jira_in_jira_namespace start_jira_in_jira_namespace create_pivotal_in_pivotal_namespace start_pivotal_in_pivotal_namespace], before: %i[test_if_working say_starting], after: [:say_started] do
      transitions from: :created, to: :started
    end

    event :finish, binding_events: %i[close_jira_in_jira_namespace finish_pivotal_in_pivotal_namespace], before: %i[say_finishing save_finished_time], after: %i[show_time_spent say_finished] do
      transitions from: :started, to: :finished
    end

    event :pause, binding_events: %i[close_jira_in_jira_namespace finish_pivotal_in_pivotal_namespace], before: %i[say_pausing save_finished_time], after: %i[show_time_spent say_paused] do
      transitions from: :started, to: :paused
    end

    event :abort, binding_events: %i[close_jira_in_jira_namespace finish_pivotal_in_pivotal_namespace], before: %i[say_aborting save_finished_time], after: %i[show_time_spent say_aborted] do
      transitions from: :started, to: :aborted
    end

    event :abort_without_time, binding_events: [:close_jira_in_jira_namespace], before: %i[say_aborting_without_time save_finished_time], after: %i[show_time_spent say_aborted_without_time] do
      transitions from: :started, to: :aborted_without_time
    end
  end

  aasm(:jira, namespace: :in_jira_namespace, column: 'jira_state', whiny_transitions: false) do
    state :pending_jira, initial: true
    state :created_jira
    state :started_jira
    state :closed_jira

    event :create_jira, binding_events: %i[show_created_issue_on_jira_status_in_created_issue_on_jira_status_namespace show_no_access_to_create_issue_on_jira_status_in_no_access_to_create_issue_on_jira_status_namespace show_no_connection_trying_to_create_issue_on_jira_status_in_no_connection_trying_to_create_issue_on_jira_status_namespace show_unknown_error_trying_to_create_issue_on_jira_status_in_unknown_error_trying_to_create_issue_on_jira_status_namespace], before: [:say_creating_in_jira], after: [:output_jira_key], guards: %i[not_test? create_on_jira?] do
      transitions from: :pending_jira, to: :created_jira
    end

    event :start_jira, binding_events: %i[show_started_issue_on_jira_statu_in_started_issue_on_jira_statu_namespace show_no_access_to_start_issue_on_jira_statu_in_no_access_to_start_issue_on_jira_statu_namespace show_no_connection_to_start_issue_on_jira_statu_in_no_connection_to_start_issue_on_jira_statu_namespace show_unknown_error_on_starting_issue_on_jira_status_in_unknown_error_on_starting_issue_on_jira_status_namespace], before: [:say_starting_in_jira], guards: %i[not_test? start_on_jira?] do
      transitions from: :created_jira, to: :started_jira
    end

    event :close_jira, binding_events: %i[show_closed_issue_on_jira_statu_in_closed_issue_on_jira_statu_namespace show_no_access_to_close_issue_on_jira_statu_in_no_access_to_close_issue_on_jira_statu_namespace show_no_connection_to_close_issue_on_jira_statu_in_no_connection_to_close_issue_on_jira_statu_namespace show_unknown_error_closing_issue_on_jira_status_in_unknown_error_closing_issue_on_jira_status_namespace], before: [:say_closing_in_jira], guards: :not_test? do
      transitions from: :started_jira, to: :closed_jira
    end
  end

  aasm(:pivotal, namespace: :in_pivotal_namespace, column: 'pivotal_state', whiny_transitions: false) do
    state :pending_pivotal, initial: true
    state :created_pivotal
    state :started_pivotal
    state :finished_pivotal

    event :create_pivotal, binding_events: %i[show_created_issue_on_pivotal_statu_in_created_issue_on_pivotal_statu_namespace show_no_access_trying_to_create_issue_on_pivotal_statu_in_no_access_trying_to_create_issue_on_pivotal_statu_namespace show_no_connection_trying_to_create_issue_on_pivotal_statu_in_no_connection_trying_to_create_issue_on_pivotal_statu_namespace show_unknown_error_trying_to_create_issue_on_pivotal_status_in_unknown_error_trying_to_create_issue_on_pivotal_status_namespace], before: [:say_creating_in_pivotal], guards: %i[not_test? create_on_pivotal?] do
      transitions from: :pending_pivotal, to: :created_pivotal
    end

    event :start_pivotal, binding_events: %i[show_start_on_pivotal_statu_in_start_on_pivotal_statu_namespace show_no_access_to_start_issue_on_pivotal_statu_in_no_access_to_start_issue_on_pivotal_statu_namespace show_no_connection_to_start_issue_on_pivotal_statu_in_no_connection_to_start_issue_on_pivotal_statu_namespace show_unknown_error_on_starting_issue_on_pivotal_status_in_unknown_error_on_starting_issue_on_pivotal_status_namespace], before: [:say_starting_in_pivotal], guards: %i[not_test? start_on_pivotal?] do
      transitions from: :created_pivotal, to: :started_pivotal
    end

    event :finish_pivotal, before: %i[say_finishing_in_pivotal show_finished_on_pivotal_statu_in_finished_on_pivotal_statu_namespace show_no_access_to_finish_on_pivotal_statu_in_no_access_to_finish_on_pivotal_statu_namespace show_no_connection_to_finish_on_pivotal_statu_in_no_connection_to_finish_on_pivotal_statu_namespace show_unknown_error_on_finishing_on_pivotal_status_in_unknown_error_on_finishing_on_pivotal_status_namespace], guards: %i[not_test? finish_on_pivotal?] do
      transitions from: :started_pivotal, to: :finished_pivotal
    end
  end

  aasm(:jira_worklog, namespace: :in_jira_worklog_namespace, column: 'jira_worklog_state', whiny_transitions: false) do
    state :pending_jira_worklog, initial: true
    state :created_jira_worklog

    event :create_jira_worklog, binding_events: %i[show_loged_work_to_jira_statu_in_loged_work_to_jira_statu_namespace show_no_access_to_log_work_to_jira_statu_in_no_access_to_log_work_to_jira_statu_namespace show_no_connection_to_log_work_to_jira_statu_in_no_connection_to_log_work_to_jira_statu_namespace show_unknown_error_loging_work_to_jira_status_in_unknown_error_loging_work_to_jira_status_namespace], before: [:say_logging_started], guards: %i[not_test? should_log_work?] do
      transitions from: :pending_jira_worklog, to: :created_jira_worklog
    end
  end

  aasm(:jira_key, namespace: :in_jira_key_namespace, column: 'jira_key_state', whiny_transitions: false) do
    state :hidden_jira_key, initial: true
    state :shown_jira_key

    event :show_jira_key, before: [:output_jira_key], guards: [:output_jira_key?] do
      transitions from: :hidden_jira_key, to: :shown_jira_key
    end
  end

  aasm(:start_on_pivotal_status, namespace: :in_start_on_pivotal_status_namespace, column: 'start_on_pivotal_status_state', whiny_transitions: false) do
    state :hidden_start_on_pivotal_status, initial: true
    state :shown_start_on_pivotal_status

    event :show_start_on_pivotal_status, before: [:say_started_issue_on_pivotal], guards: [:started_issue_on_pivotal?] do
      transitions from: :hidden_start_on_pivotal_status, to: :shown_start_on_pivotal_status
    end
  end

  aasm(:no_access_to_start_issue_on_pivotal_status, namespace: :in_no_access_to_start_issue_on_pivotal_status_namespace, column: 'no_access_to_start_issue_on_pivotal_status_state', whiny_transitions: false) do
    state :hidden_no_access_to_start_issue_on_pivotal_status, initial: true
    state :shown_no_access_to_start_issue_on_pivotal_status

    event :show_no_access_to_start_issue_on_pivotal_status, before: [:say_no_access_to_start_issue_on_pivotal], guards: [:no_access_to_start_issue_on_pivotal?] do
      transitions from: :hidden_no_access_to_start_issue_on_pivotal_status, to: :shown_no_access_to_start_issue_on_pivotal_status
    end
  end

  aasm(:no_connection_to_start_issue_on_pivotal_status, namespace: :in_no_connection_to_start_issue_on_pivotal_status_namespace, column: 'no_connection_to_start_issue_on_pivotal_status_state', whiny_transitions: false) do
    state :hidden_no_connection_to_start_issue_on_pivotal_status, initial: true
    state :shown_no_connection_to_start_issue_on_pivotal_status

    event :show_no_connection_to_start_issue_on_pivotal_status, before: [:say_no_connection_to_start_issue_on_pivotal], guards: [:no_connection_to_start_issue_on_pivotal?] do
      transitions from: :hidden_no_connection_to_start_issue_on_pivotal_status, to: :shown_no_connection_to_start_issue_on_pivotal_status
    end
  end

  aasm(:unknown_error_on_starting_issue_on_pivotal_status, namespace: :in_unknown_error_on_starting_issue_on_pivotal_status_namespace, column: 'unknown_error_on_starting_issue_on_pivotal_status_state', whiny_transitions: false) do
    state :hidden_unknown_error_on_starting_issue_on_pivotal_status, initial: true
    state :shown_unknown_error_on_starting_issue_on_pivotal_status

    event :show_unknown_error_on_starting_issue_on_pivotal_status, before: [:say_unknown_error_on_starting_issue_on_pivotal], guards: [:unknown_error_on_starting_issue_on_pivotal?] do
      transitions from: :hidden_unknown_error_on_starting_issue_on_pivotal_status, to: :shown_unknown_error_on_starting_issue_on_pivotal_status
    end
  end

  aasm(:finished_on_pivotal_status, namespace: :in_finished_on_pivotal_status_namespace, column: 'finished_on_pivotal_status_state', whiny_transitions: false) do
    state :hidden_finished_on_pivotal_status, initial: true
    state :shown_finished_on_pivotal_status

    event :show_finished_on_pivotal_status, before: [:say_finished_on_pivotal], guards: [:finished_on_pivotal?] do
      transitions from: :hidden_finished_on_pivotal_status, to: :shown_finished_on_pivotal_status
    end
  end

  aasm(:no_access_to_finish_on_pivotal_status, namespace: :in_no_access_to_finish_on_pivotal_status_namespace, column: 'no_access_to_finish_on_pivotal_status_state', whiny_transitions: false) do
    state :hidden_no_access_to_finish_on_pivotal_status, initial: true
    state :shown_no_access_to_finish_on_pivotal_status

    event :show_no_access_to_finish_on_pivotal_status, before: [:say_no_access_to_finish_on_pivotal], guards: [:no_access_to_finish_on_pivotal?] do
      transitions from: :hidden_no_access_to_finish_on_pivotal_status, to: :shown_no_access_to_finish_on_pivotal_status
    end
  end

  aasm(:no_connection_to_finish_on_pivotal_status, namespace: :in_no_connection_to_finish_on_pivotal_status_namespace, column: 'no_connection_to_finish_on_pivotal_status_state', whiny_transitions: false) do
    state :hidden_no_connection_to_finish_on_pivotal_status, initial: true
    state :shown_no_connection_to_finish_on_pivotal_status

    event :show_no_connection_to_finish_on_pivotal_status, before: [:say_no_connection_to_finish_on_pivotal], guards: [:no_connection_to_finish_on_pivotal?] do
      transitions from: :hidden_no_connection_to_finish_on_pivotal_status, to: :shown_no_connection_to_finish_on_pivotal_status
    end
  end

  aasm(:unknown_error_on_finishing_on_pivotal_status, namespace: :in_unknown_error_on_finishing_on_pivotal_status_namespace, column: 'unknown_error_on_finishing_on_pivotal_status_state', whiny_transitions: false) do
    state :hidden_unknown_error_on_finishing_on_pivotal_status, initial: true
    state :shown_unknown_error_on_finishing_on_pivotal_status

    event :show_unknown_error_on_finishing_on_pivotal_status, before: [:say_unknown_error_on_finishing_on_pivotal], guards: [:unknown_error_on_finishing_on_pivotal?] do
      transitions from: :hidden_unknown_error_on_finishing_on_pivotal_status, to: :shown_unknown_error_on_finishing_on_pivotal_status
    end
  end

  aasm(:started_issue_on_jira_status, namespace: :in_started_issue_on_jira_status_namespace, column: 'started_issue_on_jira_status_state', whiny_transitions: false) do
    state :hidden_started_issue_on_jira_status, initial: true
    state :shown_started_issue_on_jira_status

    event :show_started_issue_on_jira_status, before: [:say_started_issue_on_jira], guards: [:started_issue_on_jira?] do
      transitions from: :hidden_started_issue_on_jira_status, to: :shown_started_issue_on_jira_status
    end
  end

  aasm(:no_access_to_start_issue_on_jira_status, namespace: :in_no_access_to_start_issue_on_jira_status_namespace, column: 'no_access_to_start_issue_on_jira_status_state', whiny_transitions: false) do
    state :hidden_no_access_to_start_issue_on_jira_status, initial: true
    state :shown_no_access_to_start_issue_on_jira_status

    event :show_no_access_to_start_issue_on_jira_status, before: [:say_no_access_to_start_issue_on_jira], guards: [:no_access_to_start_issue_on_jira?] do
      transitions from: :hidden_no_access_to_start_issue_on_jira_status, to: :shown_no_access_to_start_issue_on_jira_status
    end
  end

  aasm(:no_connection_to_start_issue_on_jira_status, namespace: :in_no_connection_to_start_issue_on_jira_status_namespace, column: 'no_connection_to_start_issue_on_jira_status_state', whiny_transitions: false) do
    state :hidden_no_connection_to_start_issue_on_jira_status, initial: true
    state :shown_no_connection_to_start_issue_on_jira_status

    event :show_no_connection_to_start_issue_on_jira_status, before: [:say_no_connection_to_start_issue_on_jira], guards: [:no_connection_to_start_issue_on_jira?] do
      transitions from: :hidden_no_connection_to_start_issue_on_jira_status, to: :shown_no_connection_to_start_issue_on_jira_status
    end
  end

  aasm(:unknown_error_on_starting_issue_on_jira_status, namespace: :in_unknown_error_on_starting_issue_on_jira_status_namespace, column: 'unknown_error_on_starting_issue_on_jira_status_state', whiny_transitions: false) do
    state :hidden_unknown_error_on_starting_issue_on_jira_status, initial: true
    state :shown_unknown_error_on_starting_issue_on_jira_status

    event :show_unknown_error_on_starting_issue_on_jira_status, before: [:say_unknown_error_on_starting_issue_on_jira], guards: [:unknown_error_on_starting_issue_on_jira?] do
      transitions from: :hidden_unknown_error_on_starting_issue_on_jira_status, to: :shown_unknown_error_on_starting_issue_on_jira_status
    end
  end

  aasm(:closed_issue_on_jira_status, namespace: :in_closed_issue_on_jira_status_namespace, column: 'closed_issue_on_jira_status_state', whiny_transitions: false) do
    state :hidden_closed_issue_on_jira_status, initial: true
    state :shown_closed_issue_on_jira_status

    event :show_closed_issue_on_jira_status, before: [:say_closed_issue_on_jira], guards: [:closed_issue_on_jira?] do
      transitions from: :hidden_closed_issue_on_jira_status, to: :shown_closed_issue_on_jira_status
    end
  end

  aasm(:no_access_to_close_issue_on_jira_status, namespace: :in_no_access_to_close_issue_on_jira_status_namespace, column: 'no_access_to_close_issue_on_jira_status_state', whiny_transitions: false) do
    state :hidden_no_access_to_close_issue_on_jira_status, initial: true
    state :shown_no_access_to_close_issue_on_jira_status

    event :show_no_access_to_close_issue_on_jira_status, before: [:say_no_access_to_close_issue_on_jira], guards: [:no_access_to_close_issue_on_jira?] do
      transitions from: :hidden_no_access_to_close_issue_on_jira_status, to: :shown_no_access_to_close_issue_on_jira_status
    end
  end

  aasm(:no_connection_to_close_issue_on_jira_status, namespace: :in_no_connection_to_close_issue_on_jira_status_namespace, column: 'no_connection_to_close_issue_on_jira_status_state', whiny_transitions: false) do
    state :hidden_no_connection_to_close_issue_on_jira_status, initial: true
    state :shown_no_connection_to_close_issue_on_jira_status

    event :show_no_connection_to_close_issue_on_jira_status, before: [:say_no_connection_to_close_issue_on_jira], guards: [:no_connection_to_close_issue_on_jira?] do
      transitions from: :hidden_no_connection_to_close_issue_on_jira_status, to: :shown_no_connection_to_close_issue_on_jira_status
    end
  end

  aasm(:unknown_error_closing_issue_on_jira_status, namespace: :in_unknown_error_closing_issue_on_jira_status_namespace, column: 'unknown_error_closing_issue_on_jira_status_state', whiny_transitions: false) do
    state :hidden_unknown_error_closing_issue_on_jira_status, initial: true
    state :shown_unknown_error_closing_issue_on_jira_status

    event :show_unknown_error_closing_issue_on_jira_status, before: [:say_unknown_error_closing_issue_on_jira], guards: [:unknown_error_closing_issue_on_jira?] do
      transitions from: :hidden_unknown_error_closing_issue_on_jira_status, to: :shown_unknown_error_closing_issue_on_jira_status
    end
  end

  aasm(:loged_work_to_jira_status, namespace: :in_loged_work_to_jira_status_namespace, column: 'loged_work_to_jira_status_state', whiny_transitions: false) do
    state :hidden_loged_work_to_jira_status, initial: true
    state :shown_loged_work_to_jira_status

    event :show_loged_work_to_jira_status, before: [:say_loged_work_to_jira], guards: [:loged_work_to_jira?] do
      transitions from: :hidden_loged_work_to_jira_status, to: :shown_loged_work_to_jira_status
    end
  end

  aasm(:no_access_to_log_work_to_jira_status, namespace: :in_no_access_to_log_work_to_jira_status_namespace, column: 'no_access_to_log_work_to_jira_status_state', whiny_transitions: false) do
    state :hidden_no_access_to_log_work_to_jira_status, initial: true
    state :shown_no_access_to_log_work_to_jira_status

    event :show_no_access_to_log_work_to_jira_status, before: [:say_no_access_to_log_work_to_jira], guards: [:no_access_to_log_work_to_jira?] do
      transitions from: :hidden_no_access_to_log_work_to_jira_status, to: :shown_no_access_to_log_work_to_jira_status
    end
  end

  aasm(:no_connection_to_log_work_to_jira_status, namespace: :in_no_connection_to_log_work_to_jira_status_namespace, column: 'no_connection_to_log_work_to_jira_status_state', whiny_transitions: false) do
    state :hidden_no_connection_to_log_work_to_jira_status, initial: true
    state :shown_no_connection_to_log_work_to_jira_status

    event :show_no_connection_to_log_work_to_jira_status, before: [:say_no_connection_to_log_work_to_jira], guards: [:no_connection_to_log_work_to_jira?] do
      transitions from: :hidden_no_connection_to_log_work_to_jira_status, to: :shown_no_connection_to_log_work_to_jira_status
    end
  end

  aasm(:unknown_error_loging_work_to_jira_status, namespace: :in_unknown_error_loging_work_to_jira_status_namespace, column: 'unknown_error_loging_work_to_jira_status_state', whiny_transitions: false) do
    state :hidden_unknown_error_loging_work_to_jira_status, initial: true
    state :shown_unknown_error_loging_work_to_jira_status

    event :show_unknown_error_loging_work_to_jira_status, before: [:say_unknown_error_loging_work_to_jira], guards: [:unknown_error_loging_work_to_jira?] do
      transitions from: :hidden_unknown_error_loging_work_to_jira_status, to: :shown_unknown_error_loging_work_to_jira_status
    end
  end

  aasm(:created_issue_on_pivotal_status, namespace: :in_created_issue_on_pivotal_status_namespace, column: 'created_issue_on_pivotal_status_state', whiny_transitions: false) do
    state :hidden_created_issue_on_pivotal_status, initial: true
    state :shown_created_issue_on_pivotal_status

    event :show_created_issue_on_pivotal_status, before: [:say_created_issue_on_pivotal], after: [:save_data_received_after_created_issue_on_pivotal], guards: [:created_issue_on_pivotal?] do
      transitions from: :hidden_created_issue_on_pivotal_status, to: :shown_created_issue_on_pivotal_status
    end
  end

  aasm(:no_access_trying_to_create_issue_on_pivotal_status, namespace: :in_created_issue_on_pivotal_status_namespace, column: 'no_access_trying_to_create_issue_on_pivotal_status_state', whiny_transitions: false) do
    state :hidden_created_issue_on_pivotal_status, initial: true
    state :shown_created_issue_on_pivotal_status

    event :show_created_issue_on_pivotal_status, before: [:say_no_access_trying_to_create_issue_on_pivotal], guards: [:no_access_trying_to_create_issue_on_pivotal?] do
      transitions from: :hidden_created_issue_on_pivotal_status, to: :shown_created_issue_on_pivotal_status
    end
  end

  aasm(:no_connection_trying_to_create_issue_on_pivotal_status, namespace: :in_created_issue_on_pivotal_status_namespace, column: 'no_connection_trying_to_create_issue_on_pivotal_status_state', whiny_transitions: false) do
    state :hidden_created_issue_on_pivotal_status, initial: true
    state :shown_created_issue_on_pivotal_status

    event :show_created_issue_on_pivotal_status, before: [:say_no_connection_trying_to_create_issue_on_pivotal], guards: [:no_connection_trying_to_create_issue_on_pivotal?] do
      transitions from: :hidden_created_issue_on_pivotal_status, to: :shown_created_issue_on_pivotal_status
    end
  end

  aasm(:unknown_error_trying_to_create_issue_on_pivotal_status, namespace: :in_created_issue_on_pivotal_status_namespace, column: 'unknown_error_trying_to_create_issue_on_pivotal_status_state', whiny_transitions: false) do
    state :hidden_created_issue_on_pivotal_status, initial: true
    state :shown_created_issue_on_pivotal_status

    event :show_created_issue_on_pivotal_status, before: [:say_no_connection_trying_to_create_issue_on_pivotal], guards: [:unknown_error_trying_to_create_issue_on_pivotal?] do
      transitions from: :hidden_created_issue_on_pivotal_status, to: :shown_created_issue_on_pivotal_status
    end
  end

  aasm(:created_issue_on_jira_status, namespace: :in_created_issue_on_pivotal_status_namespace, column: 'created_issue_on_jira_status_state', whiny_transitions: false) do
    state :hidden_created_issue_on_pivotal_status, initial: true
    state :shown_created_issue_on_pivotal_status

    event :show_created_issue_on_pivotal_status, before: [:say_created_issue_on_jira], guards: [:created_issue_on_jira?] do
      transitions from: :hidden_created_issue_on_pivotal_status, to: :shown_created_issue_on_pivotal_status
    end
  end

  aasm(:no_access_to_create_issue_on_jira_status, namespace: :in_created_issue_on_pivotal_status_namespace, column: 'no_access_to_create_issue_on_jira_status_state', whiny_transitions: false) do
    state :hidden_created_issue_on_pivotal_status, initial: true
    state :shown_created_issue_on_pivotal_status

    event :show_created_issue_on_pivotal_status, before: [:say_no_access_to_create_issue_on_jira], after: [:save_data_received_after_creating_issue_on_jira], guards: [:no_access_to_create_issue_on_jira?] do
      transitions from: :hidden_created_issue_on_pivotal_status, to: :shown_created_issue_on_pivotal_status
    end
  end

  aasm(:no_connection_trying_to_create_issue_on_jira_status, namespace: :in_created_issue_on_pivotal_status_namespace, column: 'no_connection_trying_to_create_issue_on_jira_status_state', whiny_transitions: false) do
    state :hidden_created_issue_on_pivotal_status, initial: true
    state :shown_created_issue_on_pivotal_status

    event :show_created_issue_on_pivotal_status, before: [:say_no_connection_trying_to_create_issue_on_jira], guards: [:no_connection_trying_to_create_issue_on_jira?] do
      transitions from: :hidden_created_issue_on_pivotal_status, to: :shown_created_issue_on_pivotal_status
    end
  end

  aasm(:unknown_error_trying_to_create_issue_on_jira_status, namespace: :in_created_issue_on_pivotal_status_namespace, column: 'unknown_error_trying_to_create_issue_on_jira_status_state', whiny_transitions: false) do
    state :hidden_created_issue_on_pivotal_status, initial: true
    state :shown_created_issue_on_pivotal_status

    event :show_created_issue_on_pivotal_status, before: [:say_unknown_error_trying_to_create_issue_on_jira], guards: [:unknown_error_trying_to_create_issue_on_jira?] do
      transitions from: :hidden_created_issue_on_pivotal_status, to: :shown_created_issue_on_pivotal_status
    end
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
    puts 'Finishing current task'
  end

  def say_started
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

  def started_issue_on_pivotal?
    [200, 201, 202, 204, 301, 302, 303, 304, 307].include? start_issue_on_pivotal_response.status
  end

  def say_started_issue_on_pivotal
    puts 'Started the task in Pivotal'
  end

  def no_access_to_start_issue_on_pivotal?
    [401, 403].include? start_issue_on_pivotal_response.status
  end

  def say_no_access_to_start_issue_on_pivotal
    puts "No access to the task ##{pivotal_id} in Pivotal. Maybe login or api_key are incorrect."
  end

  def no_connection_to_start_issue_on_pivotal?
    [404].include? start_issue_on_pivotal_response.status
  end

  def say_no_connection_to_start_issue_on_pivotal
    puts "A task with ID ##{pivotal_id} is not found in Pivotal."
  end

  def unknown_error_on_starting_issue_on_pivotal?
    ![200, 201, 202, 204, 301, 302, 303, 304, 307, 401, 403, 404].include? start_issue_on_pivotal_response.status
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
    [200, 201, 202, 204, 301, 302, 303, 304, 307].include? finish_on_pivotal_response.status
  end

  def say_finished_on_pivotal
    puts 'Finished the task in Pivotal'
  end

  def no_access_to_finish_on_pivotal?
    [401, 403].include? finish_on_pivotal_response.status
  end

  def say_no_access_to_finish_on_pivotal
    puts "No access to the task ##{pivotal_id} in Pivotal. Maybe login or api_key are incorrect."
  end

  def no_connection_to_finish_on_pivotal?
    [404].include?  finish_on_pivotal_response.status
  end

  def say_no_connection_to_finish_on_pivotal
    puts "A task with ID ##{pivotal_id} is not found in Pivotal."
  end

  def unknown_error_on_finishing_on_pivotal?
    ![200, 201, 202, 204, 301, 302, 303, 304, 307, 401, 403, 404].include? finish_on_pivotal_response.status
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
    [200, 201, 202, 204, 301, 302, 303, 304, 307].include? start_issue_on_jiraresponse.status
  end

  def say_started_issue_on_jira
    puts 'Started the issue in Jira'
  end

  def no_access_to_start_issue_on_jira?
    [401, 403].include? start_issue_on_jiraresponse.status
  end

  def say_no_access_to_start_issue_on_jira
    puts "No access to the task #{jira_key} in Jira. Maybe login or api_key are incorrect."
  end

  def no_connection_to_start_issue_on_jira?
    [404].include?  start_issue_on_jiraresponse.status
  end

  def say_no_connection_to_start_issue_on_jira
    puts "A task with ID #{jira_key} is not found in Jira."
  end

  def unknown_error_on_starting_issue_on_jira?
    ![200, 201, 202, 204, 301, 302, 303, 304, 307, 401, 403, 404].include? start_issue_on_jiraresponse.status
  end

  def say_unknown_error_on_starting_issue_on_jira
    puts 'Could not start the issue in Jira.'
    puts "Error status: #{start_issue_on_jiraresponse.status}"
    puts "Message from server: #{start_issue_on_jiraresponse.reason_phrase}"
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
    [200, 201, 202, 204, 301, 302, 303, 304, 307].include? close_issue_on_jira_response.status
  end

  def say_closed_issue_on_jira
    puts 'Closed the issue in Jira'
  end

  def no_access_to_close_issue_on_jira?
    [401, 403].include? close_issue_on_jira_response.status
  end

  def say_no_access_to_close_issue_on_jira
    puts "No access to the task #{jira_key} in Jira. Maybe login or api_key are incorrect."
  end

  def no_connection_to_close_issue_on_jira?
    [404].include?  close_issue_on_jira_response.status
  end

  def say_no_connection_to_close_issue_on_jira
    puts "A task with ID #{jira_key} is not found in Jira."
  end

  def unknown_error_closing_issue_on_jira?
    ![200, 201, 202, 204, 301, 302, 303, 304, 307, 401, 403, 404].include? close_issue_on_jira_response.status
  end

  def say_unknown_error_closing_issue_on_jira
    puts 'Could not close the issue in Jira.'
    puts "Error status: #{close_issue_on_jira_respons.status}"
    puts "Message from server: #{close_issue_on_jira_respons.reason_phrase}"
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
    [200, 201, 202, 204, 301, 302, 303, 304, 307].include? log_work_to_jira_response.status
  end

  def say_loged_work_to_jira
    puts 'Work logged to Jira'
  end

  def no_access_to_log_work_to_jira?
    [401, 403].include?  log_work_to_jira_response.status
  end

  def say_no_access_to_log_work_to_jira
    puts "No access to the task #{jira_key} in Jira. Maybe login or api_key are incorrect."
  end

  def no_connection_to_log_work_to_jira?
    [404].include?  log_work_to_jira_response.status
  end

  def say_no_connection_to_log_work_to_jira
    puts "A task with ID #{jira_key} is not found in Jira."
  end

  def unknown_error_loging_work_to_jira?
    ![200, 201, 202, 204, 301, 302, 303, 304, 307, 401, 403, 404].include? log_work_to_jira_response.status
  end

  def say_unknown_error_loging_work_to_jira
    puts 'Could not log work to Jira.'
    puts "Error status: #{log_work_to_jira_respons.status}"
    puts "Message from server: #{log_work_to_jira_respons.reason_phrase}"
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
    [200, 201, 202, 204, 301, 302, 303, 304, 307].include? create_issue_on_pivotal_response.status
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
    [401, 403].include? create_issue_on_pivotal_response.status
  end

  def say_no_access_trying_to_create_issue_on_pivotal
    puts "No access to the server. Maybe login, api_key or Pivotal Project ID ##{project.pivotal_tracker_project_id} is incorrect."
  end

  def no_connection_trying_to_create_issue_on_pivotal?
    [404].include? create_issue_on_pivotal_response.status
  end

  def say_no_connection_trying_to_create_issue_on_pivotal
    puts "Resource not found. Maybe Pivotal Project ID ##{project.pivotal_tracker_project_id} is incorrect."
  end

  def unknown_error_trying_to_create_issue_on_pivotal?
    ![200, 201, 202, 204, 301, 302, 303, 304, 307, 401, 403, 404].include? create_issue_on_pivotal_response.status
  end

  def say_no_connection_trying_to_create_issue_on_pivotal
    puts 'Could not create the task in Pivotal.'
    puts "Error status: #{response.status}"
    puts "Message from server: #{response.reason_phrase}"
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
    [200, 201, 202, 204, 301, 302, 303, 304, 307].include? create_issue_on_jira_response.status
  end

  def say_created_issue_on_jira
    puts 'Created the issue in Jira'
  end

  def no_access_to_create_issue_on_jira?
    [401, 403].include? create_issue_on_jira_response.status
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
    [404].include? create_issue_on_jira_response.status
  end

  def say_no_connection_trying_to_create_issue_on_jira
    puts "Not found the resource in Jira. Maybe the Jira Project ID #{project.jira_project_id} is incorrect."
  end

  def unknown_error_trying_to_create_issue_on_jira?
    ![200, 201, 202, 204, 301, 302, 303, 304, 307, 401, 403, 404].include? create_issue_on_jira_response.status
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

  def test_if_working
    pp '----------------------------------------------------------------------------------------------------'
    pp 'working'
  end
end
