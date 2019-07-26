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

  before_create :generate_uuid
  before_create :set_start_time

  after_create :create_issue_on_jira, if: :create_on_jira?
  after_create :start_issue_on_jira, if: :start_on_jira?
  after_create :create_issue_on_pivotal, if: :create_on_pivotal?
  after_create :start_issue_on_pivotal, if: :start_on_pivotal?
  after_save :output_jira_key, if: :output_jira_key?

  scope :unfinished, -> { where(finished_at: nil) }
  scope :finished, -> { where.not(finished_at: nil) }

  def self.finish_started(comment)
    puts 'Finishing current task'
    unfinished.each { |task| task.finish(comment) }
    puts 'Current task finished'
  end

  def self.pause_started(comment)
    puts 'Pausing current task'
    unfinished.each { |task| task.pause(comment) }
    puts 'Current task paused'
  end

  def self.abort_started(comment)
    puts 'Aborting current task'
    unfinished.each { |task| task.abort(comment) }
    puts 'Current task aborted'
  end

  def self.abort_started_without_time(comment)
    puts 'Aborting current task without putting time into Jira'
    unfinished.each { |task| task.abort_without_time(comment) }
    puts 'Current task aborted without putting time into Jira'
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

  def finish(comment)
    # full pull request
    update_attribute(:finished_at, Time.now)
    close_issue_on_jira
    log_work_to_jira(comment) if should_log_work?
    finish_on_pivotal if finish_on_pivotal?
    puts time_spent
  end

  def pause(comment = 'Done')
    # finish with commit & push but without pull request
    update_attribute(:finished_at, Time.now)
    close_issue_on_jira
    log_work_to_jira(comment) if should_log_work?
    finish_on_pivotal if finish_on_pivotal?
    puts time_spent
  end

  def abort(comment)
    # finish without commit or push
    update_attribute(:finished_at, Time.now)
    close_issue_on_jira
    log_work_to_jira(comment) if should_log_work?
    finish_on_pivotal if finish_on_pivotal?
    puts time_spent
  end

  def abort_without_time(_comment)
    # finish without commit or push
    update_attribute(:finished_at, Time.now)
    close_issue_on_jira
    # the task closes on Jira, but is still running in Pivotal
    puts time_spent
  end

  def should_log_work?
    time_spent_so_far != '0h 0m' && Account.jira.present?
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

  def story_type
    'chore' # default is chore, it's never used directly
  end

  def create_on_jira?
    Account.jira.present? && not_test?
  end

  def start_on_jira?
    jira_key.present? && Account.jira.present? && not_test?
  end

  def create_on_pivotal?
    pivotal_id.blank? && this_is_a_type_a_user_wants_to_create? && Account.pivotal.present? && not_test?
  end

  def start_on_pivotal?
    pivotal_id.present? && Account.pivotal.present? && not_test?
  end

  def finish_on_pivotal?
    pivotal_id.present? && Account.pivotal.present? && not_test?
  end

  def this_is_a_type_a_user_wants_to_create?
    false
  end

  def generate_uuid
    self.uuid = SecureRandom.uuid
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
    jira_key.present? && not_test?
  end

  def start_issue_on_pivotal_data
    Jbuilder.encode do |j|
      j.current_state 'started'
    end
  end

  def start_issue_on_pivotal
    if not_test?
      puts 'Starting the task in Pivotal'

      conn = Faraday.new(url: 'https://www.pivotaltracker.com/') do |c|
        c.adapter Faraday.default_adapter
      end

      response = conn.put do |request|
        request.url "services/v5/stories/#{pivotal_id}"
        request.body = start_issue_on_pivotal_data
        request.headers['User-Agent'] = 'Caperoma'
        request.headers['Content-Type'] = 'application/json'
        request.headers['X-TrackerToken'] = Account.pivotal.password
      end

      case response.status
      when 200, 201, 202, 204, 301, 302, 303, 304, 307
        puts 'Started the task in Pivotal'
      when 401, 403
        puts "No access to the task ##{pivotal_id} in Pivotal. Maybe login or api_key are incorrect."
      when 404
        puts "A task with ID ##{pivotal_id} is not found in Pivotal."
      else
        puts 'Could not start the task in Pivotal.'
        puts "Error status: #{response.status}"
        puts "Message from server: #{response.reason_phrase}"
      end
    end
  rescue Faraday::ConnectionFailed
    puts 'Connection failed. Performing the task without requests to Pivotal.'
  end

  def finish_on_pivotal_data
    Jbuilder.encode do |j|
      j.current_state 'finished'
    end
  end

  def finish_on_pivotal
    if not_test?
      puts 'Finishing the task in Pivotal'

      conn = Faraday.new(url: 'https://www.pivotaltracker.com/') do |c|
        c.adapter Faraday.default_adapter
      end

      response = conn.put do |request|
        request.url "services/v5/stories/#{pivotal_id}"
        request.body = finish_on_pivotal_data
        request.headers['User-Agent'] = 'Caperoma'
        request.headers['Content-Type'] = 'application/json'
        request.headers['X-TrackerToken'] = Account.pivotal.password
      end

      case response.status
      when 200, 201, 202, 204, 301, 302, 303, 304, 307
        puts 'Finished the task in Pivotal'
      when 401, 403
        puts "No access to the task ##{pivotal_id} in Pivotal. Maybe login or api_key are incorrect."
      when 404
        puts "A task with ID ##{pivotal_id} is not found in Pivotal."
      else
        puts 'Could not finish the task in Pivotal.'
        puts "Error status: #{response.status}"
        puts "Message from server: #{response.reason_phrase}"
      end
    end
  rescue Faraday::ConnectionFailed
    puts 'Connection failed. Performing the task without requests to Pivotal.'
  end

  def start_issue_on_jira_data
    Jbuilder.encode do |j|
      j.transition { j.id project.jira_transition_id_in_progress }
    end
  end

  def start_issue_on_jira
    if not_test?
      puts 'Starting the issue in Jira'

      conn = Faraday.new(url: project.jira_url) do |c|
        c.basic_auth(Account.jira.email, Account.jira.password)
        c.adapter Faraday.default_adapter
      end

      response = conn.post do |request|
        request.url "rest/api/3/issue/#{jira_key}/transitions"
        request.body = start_issue_on_jira_data
        request.headers['User-Agent'] = 'Caperoma'
        request.headers['Content-Type'] = 'application/json'
      end

      case response.status
      when 200, 201, 202, 204, 301, 302, 303, 304, 307
        puts 'Started the issue in Jira'
      when 401, 403
        puts "No access to the task #{jira_key} in Jira. Maybe login or api_key are incorrect."
      when 404
        puts "A task with ID #{jira_key} is not found in Jira."
      else
        puts 'Could not start the issue in Jira.'
        puts "Error status: #{response.status}"
        puts "Message from server: #{response.reason_phrase}"
      end
    end
  rescue Faraday::ConnectionFailed
    puts 'Connection failed. Performing the task without requests to Jira.'
  end

  def close_issue_on_jira_data
    Jbuilder.encode do |j|
      j.transition { j.id project.jira_transition_id_done }
    end
  end

  def close_issue_on_jira
    if not_test?
      puts 'Closing the issue in Jira'

      conn = Faraday.new(url: project.jira_url) do |c|
        c.basic_auth(Account.jira.email, Account.jira.password)
        c.adapter Faraday.default_adapter
      end

      response = conn.post do |request|
        request.url "rest/api/3/issue/#{jira_key}/transitions"
        request.body = close_issue_on_jira_data
        request.headers['User-Agent'] = 'Caperoma'
        request.headers['Content-Type'] = 'application/json'
      end

      case response.status
      when 200, 201, 202, 204, 301, 302, 303, 304, 307
        puts 'Closed the issue in Jira'
      when 401, 403
        puts "No access to the task #{jira_key} in Jira. Maybe login or api_key are incorrect."
      when 404
        puts "A task with ID #{jira_key} is not found in Jira."
      else
        puts 'Could not close the issue in Jira.'
        puts "Error status: #{response.status}"
        puts "Message from server: #{response.reason_phrase}"
      end
    end
  rescue Faraday::ConnectionFailed
    puts 'Connection failed. Performing the task without requests to Jira.'
  end

  def log_work_to_jira_data(comment = 'Done')
    Jbuilder.encode do |j|
      j.comment comment
      j.started current_time
      j.timeSpent time_spent
    end
  end

  def log_work_to_jira(comment = 'Done')
    if not_test?
      puts 'Logging work to Jira'

      conn = Faraday.new(url: project.jira_url) do |c|
        c.basic_auth(Account.jira.email, Account.jira.password)
        c.adapter Faraday.default_adapter
      end

      response = conn.post do |request|
        request.url "rest/api/3/issue/#{jira_key}/worklog"
        request.body = log_work_to_jira_data(comment)
        request.headers['User-Agent'] = 'Caperoma'
        request.headers['Content-Type'] = 'application/json'
      end

      case response.status
      when 200, 201, 202, 204, 301, 302, 303, 304, 307
        puts 'Work logged to Jira'
      when 401, 403
        puts "No access to the task #{jira_key} in Jira. Maybe login or api_key are incorrect."
      when 404
        puts "A task with ID #{jira_key} is not found in Jira."
      else
        puts 'Could not log work to Jira.'
        puts "Error status: #{response.status}"
        puts "Message from server: #{response.reason_phrase}"
      end
    end
  rescue Faraday::ConnectionFailed
    puts 'Connection failed. Performing the task without requests to Jira.'
  end

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

  def create_issue_on_pivotal
    if not_test?
      puts 'Creating a task in Pivotal'

      conn = Faraday.new(url: 'https://www.pivotaltracker.com/') do |c|
        c.adapter Faraday.default_adapter
      end

      response = conn.post do |request|
        request.url "services/v5/projects/#{project.pivotal_tracker_project_id}/stories"
        request.body = create_issue_on_pivotal_data
        request.headers['User-Agent'] = 'Caperoma'
        request.headers['Content-Type'] = 'application/json'
        request.headers['X-TrackerToken'] = Account.pivotal.password
      end

      case response.status
      when 200, 201, 202, 204, 301, 302, 303, 304, 307
        puts 'Created the task in Pivotal'
        result = JSON.parse response.body

        update_attributes(
          pivotal_id: result['id']
        )
      when 401, 403
        puts "No access to the server. Maybe login, api_key or Pivotal Project ID ##{project.pivotal_tracker_project_id} is incorrect."
      when 404
        puts "Resource not found. Maybe Pivotal Project ID ##{project.pivotal_tracker_project_id} is incorrect."
      else
        puts 'Could not create the task in Pivotal.'
        puts "Error status: #{response.status}"
        puts "Message from server: #{response.reason_phrase}"
      end
    end
  rescue Faraday::ConnectionFailed
    puts 'Connection failed. Performing the task without requests to Pivotal.'
  end

  def create_issue_on_jira_data
    { 
      fields: {
        summary: title.to_s, 
        issuetype: {
          id: issue_type 
        },
        project: {
          id: project.jira_project_id.to_s
        },
        description: {
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
        },
        assignee: {
          name: Account.jira.username
        }
      }
    }.to_json
  end

  def create_issue_on_jira
    if not_test?
      puts 'Creating an issue in Jira'

      conn = Faraday.new(url: project.jira_url) do |c|
        c.basic_auth(Account.jira.email, Account.jira.password)
        c.adapter Faraday.default_adapter
      end

      response = conn.post do |request|
        request.url 'rest/api/3/issue.json'
        request.body = create_issue_on_jira_data
        request.headers['User-Agent'] = 'Caperoma'
        request.headers['Content-Type'] = 'application/json'
      end

      case response.status
      when 200, 201, 202, 204, 301, 302, 303, 304, 307
        puts 'Created the issue in Jira'

        result = JSON.parse response.body

        update_attributes(
          jira_id: result['id'],
          jira_key: result['key'],
          jira_url: result['self']
        )
      when 401, 403
        puts "Forbidden access to the resource in Jira. Maybe login, api_key or Jira project id #{project.jira_project_id} are incorrect."
      when 404
        puts "Not found the resource in Jira. Maybe the Jira Project ID #{project.jira_project_id} is incorrect."
      else
        puts 'Could not create the issue in Jira.'
        puts "Error status: #{response.status}"
        puts "Message from server: #{response.reason_phrase}"
      end
    end
  rescue Faraday::ConnectionFailed
    puts 'Connection failed. Performing the task without requests to Jira.'
  end

  def not_test?
    ENV['CAPEROMA_INTEGRATION_TEST'].blank?
  end

  def enable_git?
    ENV['CAPEROMA_TEST'].blank? && ENV['CAPEROMA_INTEGRATION_TEST'].blank?
  end
end
