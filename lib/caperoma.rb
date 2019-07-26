# frozen_string_literal: true

$VERBOSE = nil
require 'active_record'
require 'sqlite3'
require 'action_view'
require 'json'
require 'jbuilder'
require 'time_difference'
require 'net/smtp'
require 'gmail'
require 'faraday'
require 'pp'

DB_SPEC = {
  adapter: 'sqlite3',
  database: ENV['CAPEROMA_TEST'].present? || ENV['CAPEROMA_INTEGRATION_TEST'].present? ? "#{ENV['HOME']}/.caperoma-test.sqlite3" : "#{ENV['HOME']}/.caperoma.sqlite3"
}.freeze

ActiveRecord::Base.establish_connection(DB_SPEC)

require 'caperoma/models/application_record'

require 'caperoma/models/account'
require 'caperoma/models/project'

require 'caperoma/models/tasks/modules/git'
require 'caperoma/models/task'
require 'caperoma/models/tasks/task_with_commit'
require 'caperoma/models/tasks/task_with_separate_branch'
require 'caperoma/models/tasks/chore'
require 'caperoma/models/tasks/bug'
require 'caperoma/models/tasks/fix'
require 'caperoma/models/tasks/feature'
require 'caperoma/models/tasks/meeting'

require 'caperoma/models/report_recipient'

require 'caperoma/models/report'
require 'caperoma/models/reports/daily_report'
require 'caperoma/models/reports/three_day_report'
require 'caperoma/models/reports/retrospective_report'

require 'caperoma/version'

class Caperoma
  def self.setup
    puts 'Initializing Caperoma'
    ActiveRecord::Base.connection.close
    File.delete(DB_SPEC[:database])

    puts 'Creating local database for storing work information'
    ActiveRecord::Base.establish_connection(DB_SPEC)
    ActiveRecord::Schema.define do
      create_table :accounts do |t|
        t.column :username, :string
        t.column :email, :string
        t.column :password, :string
        t.column :type, :string

        t.timestamps
      end

      create_table :projects do |t|
        t.column :name, :string
        t.column :jira_project_id, :string
        t.column :folder_path, :string
        t.column :jira_url, :string
        t.column :jira_project_id, :string
        t.column :github_repo, :string
        t.column :feature_jira_task_id, :string
        t.column :bug_jira_task_id, :string
        t.column :chore_jira_task_id, :string
        t.column :fix_jira_task_id, :string
        t.column :meeting_jira_task_id, :string
        t.column :jira_transition_id_todo, :string
        t.column :jira_transition_id_in_progress, :string
        t.column :jira_transition_id_done, :string
        t.column :pivotal_tracker_project_id, :string
        t.column :create_features_in_pivotal, :boolean
        t.column :create_bugs_in_pivotal, :boolean
        t.column :create_chores_in_pivotal, :boolean
        t.column :create_fixes_in_pivotal_as_chores, :boolean
        t.column :create_meetings_in_pivotal_as_chores, :boolean

        t.timestamps
      end
      add_index :projects, :jira_project_id

      create_table :tasks do |t|
        t.column :project_id, :integer
        t.column :title, :string
        t.column :description, :text
        t.column :url, :text
        t.column :uuid, :string
        t.column :type, :string
        t.column :jira_id, :string
        t.column :jira_key, :string
        t.column :jira_url, :string
        t.column :parent_branch, :string
        t.column :branch, :string
        t.column :pivotal_id, :string
        t.column :additional_time, :integer
        t.column :started_at, :datetime
        t.column :finished_at, :datetime
        t.column :daily_report_id, :integer
        t.column :three_day_report_id, :integer
        t.column :retrospective_report_id, :integer

        t.timestamps
      end
      add_index :tasks, :project_id
      add_index :tasks, :daily_report_id
      add_index :tasks, :three_day_report_id
      add_index :tasks, :retrospective_report_id

      create_table :reports do |t|
        t.column :content, :text
        t.column :tasks_for_tomorrow, :text
        t.column :type, :string

        t.timestamps
      end

      create_table :report_recipients do |t|
        t.column :email, :string

        t.timestamps
      end
    end

    puts 'Done'

    puts "Database with all your data is located at: #{DB_SPEC[:database]}"
  end

  def self.init
    if `git -C "#{project.folder_path}" rev-parse --is-inside-work-tree`.strip == 'true'
      template_path = File.join(File.dirname(__FILE__), '..', 'Capefile.template')
      new_path = `git rev-parse --show-toplevel`.strip + '/Capefile'

      FileUtils.cp template_path, new_path

      puts 'Capefile successfully created.'
      puts 'Please open Capefile and add your Jira/Git/Pivotal settings.'
    else
      puts "You don't seem to be inside a git project. Please go into a folder that has a git repository initiated."
    end
  end

  # TODO: here is project.jira_url. but it has an undefined method project.
  # should move this method to be inside a project (get ids for this project or something).
  def self.get_jira_issue_type_ids
    puts 'Getting issue ids from Jira'

    if Account.jira.present?
      capefile_filename = ENV['CAPEROMA_TEST'].blank? && ENV['CAPEROMA_INTEGRATION_TEST'].blank? ? 'Capefile' : 'Capefile.test'
      if File.exist?(capefile_filename)
        capedata = YAML.load_file(capefile_filename)
        if capedata
          jira_url = capedata['jira_url']
          if jira_url
            puts 'Receiving issue types'
            conn = Faraday.new(url: jira_url) do |c|
              c.basic_auth(Account.jira.email, Account.jira.password)
              c.adapter Faraday.default_adapter
            end

            response = conn.get do |request|
              request.url 'rest/api/3/issuetype.json'
              request.headers['User-Agent'] = 'Caperoma'
              request.headers['Content-Type'] = 'application/json'
            end

            case response.status
            when 200, 201, 202, 204, 301, 302, 303, 304, 307
              puts 'Received these issue types:'

              result = JSON.parse(response.body)

              result.each do |item|
                puts "Name: #{item['name']}, ID: #{item['id']}"
              end
            when 401, 403
              puts 'No access to Jira. Maybe login or api_key are incorrect.'
            when 404
              puts 'Resource not found. Maybe Jira ID is incorrect.'
            else
              puts 'Could not get data from Jira.'
              puts "Error status: #{response.status}"
              puts "Message from server: #{response.reason_phrase}"
            end
          else
            puts 'Please put at least jira url into your Capefile'
          end
        else
          puts 'Can not parse Capfile. Is it formatted properly?'
        end
      else
        puts 'Capefile not found. Are you in the project folder? If yes, run "caperoma init" to create Capefile.'
      end
    else
      puts 'Please set up Jira account first'
    end
  rescue Faraday::ConnectionFailed
    puts 'Connection failed.'
  end

  def self.get_jira_transition_ids
    puts 'Getting transition ids from Jira'

    if Account.jira.present?
      capefile_filename = ENV['CAPEROMA_TEST'].blank? && ENV['CAPEROMA_INTEGRATION_TEST'].blank? ? 'Capefile' : 'Capefile.test'
      if File.exist?(capefile_filename)
        capedata = YAML.load_file(capefile_filename)
        if capedata
          jira_url = capedata['jira_url']
          if jira_url
            jira_project_id = capedata['jira_project_id']

            if jira_project_id
              puts 'Receiving an issue to get transition ids:'

              conn = Faraday.new(url: jira_url) do |c|
                c.basic_auth(Account.jira.email, Account.jira.password)
                c.adapter Faraday.default_adapter
              end

              response = conn.get do |request|
                request.url "rest/api/3/search?jql=project=%22#{jira_project_id}%22"
                request.headers['User-Agent'] = 'Caperoma'
                request.headers['Content-Type'] = 'application/json'
              end

              case response.status
              when 200, 201, 202, 204, 301, 302, 303, 304, 307
                issues = JSON.parse(response.body)['issues']

                if !issues.empty?
                  first_issue = issues[0]
                  first_issue_key = first_issue['key']

                  conn2 = Faraday.new(url: jira_url) do |c|
                    c.basic_auth(Account.jira.email, Account.jira.password)
                    c.adapter Faraday.default_adapter
                  end

                  response2 = conn2.get do |request|
                    request.url "rest/api/3/issue/#{first_issue_key}/transitions"
                    request.headers['User-Agent'] = 'Caperoma'
                    request.headers['Content-Type'] = 'application/json'
                  end

                  case response2.status
                  when 200, 201, 202, 204, 301, 302, 303, 304, 307
                    puts 'Received these transitions:'
                    transitions = JSON.parse(response2.body)['transitions']

                    transitions.each do |transition|
                      pp "Name: #{transition['name']}, ID: #{transition['id']}"
                    end
                  when 401, 403
                    puts 'No access to Jira. Maybe login or api_key are incorrect.'
                  when 404
                    puts 'Resource not found. Maybe Jira ID is incorrect.'
                  else
                    puts 'Could not get data from Jira.'
                    puts "Error status: #{response2.status}"
                    puts "Message from server: #{response2.reason_phrase}"
                  end
                else
                  puts 'Please create at least one issue in this project manually in the browser.'
                end
              when 401, 403
                puts 'No access to Jira. Maybe login or api_key are incorrect.'
              when 404
                puts 'Resource not found. Maybe Jira ID is incorrect.'
              else
                puts 'Could not get data from Jira.'
                puts "Error status: #{response.status}"
                puts "Message from server: #{response.reason_phrase}"
              end
            else
              puts 'Please put jira_project_id into your Capefile'
            end

          else
            puts 'Please put jira_url into your Capefile'
          end
        else
          puts 'Can not parse Capfile. Is it formatted properly?'
        end
      else
        puts 'Capefile not found. Are you in the project folder? If yes, run "caperoma init" to create Capefile.'
      end
    else
      puts 'Please set up Jira account first'
    end
  rescue Faraday::ConnectionFailed
    puts 'Connection failed.'
  end

  def self.drop_db
    puts 'Deleting work history and settings'
    ActiveRecord::Base.connection.close
    File.delete(DB_SPEC[:database])
    puts 'Work history and settings deleted'
  end

  def self.create_task(argv)
    # test if Capefile exists
    capefile_filename = ENV['CAPEROMA_TEST'].blank? && ENV['CAPEROMA_INTEGRATION_TEST'].blank? ? 'Capefile' : 'Capefile.test'

    if File.exist?(capefile_filename)
      capedata = nil
      jira_url = nil
      jira_project_id = nil
      github_repo = nil
      feature_jira_task_id = nil
      bug_jira_task_id = nil
      chore_jira_task_id = nil
      fix_jira_task_id = nil
      meeting_jira_task_id = nil
      jira_transition_id_todo = nil
      jira_transition_id_in_progress = nil
      jira_transition_id_done = nil
      pivotal_tracker_project_id = nil

      create_features_in_pivotal = nil
      create_bugs_in_pivotal = nil
      create_chores_in_pivotal = nil
      create_fixes_in_pivotal_as_chores = nil
      create_meetings_in_pivotal_as_chores = nil

      capedata = YAML.load_file(capefile_filename)
      if capedata
        jira_url = capedata['jira_url']
        jira_project_id = capedata['jira_project_id']
        github_repo = capedata['github_repo']

        jira_issue_type_ids = capedata['jira_issue_type_ids']

        if jira_issue_type_ids
          feature_jira_task_id = jira_issue_type_ids['feature']
          bug_jira_task_id = jira_issue_type_ids['bug']
          chore_jira_task_id = jira_issue_type_ids['chore']
          fix_jira_task_id = jira_issue_type_ids['fix']
          meeting_jira_task_id = jira_issue_type_ids['meeting']
        end

        jira_transition_ids = capedata['jira_transition_ids']

        if jira_transition_ids
          jira_transition_id_todo = jira_transition_ids['todo']
          jira_transition_id_in_progress = jira_transition_ids['in_progress']
          jira_transition_id_done = jira_transition_ids['done']
        end

        pivotal_tracker_project_id = capedata['pivotal_tracker_project_id']

        create_features_in_pivotal = capedata['create_features_in_pivotal']
        create_bugs_in_pivotal = capedata['create_bugs_in_pivotal']
        create_chores_in_pivotal = capedata['create_chores_in_pivotal']
        create_fixes_in_pivotal_as_chores = capedata['create_fixes_in_pivotal_as_chores']
        create_meetings_in_pivotal_as_chores = capedata['create_meetings_in_pivotal_as_chores']

        folder_path = `git rev-parse --show-toplevel`.strip

        # find a project
        title_flag_position = nil
        title = nil
        description_flag_position = nil
        description = nil
        project_id_flag_position = nil
        project_id = nil
        pivotal_id_flag_position = nil
        pivotal_id = nil
        additional_time_flag_position = nil
        additional_time = nil

        title_flag_position = argv.index('-t') || argv.index('--title')
        title = argv[title_flag_position + 1] if title_flag_position
        description_flag_position = argv.index('-d') || argv.index('--description')
        description = argv[description_flag_position + 1] if description_flag_position
        pivotal_id_flag_position = argv.index('-p') || argv.index('-ptid') || argv.index('--pivotal_task_id')
        pivotal_id = argv[pivotal_id_flag_position + 1] if pivotal_id_flag_position
        additional_time_flag_position = argv.index('-a') || argv.index('--additional_time')
        additional_time = argv[additional_time_flag_position + 1] if additional_time_flag_position

        pivotal_id = pivotal_id.gsub(/#/, '') if pivotal_id.present?

        project = Project.all.select { |project| project.jira_project_id == jira_project_id || project.pivotal_tracker_project_id == pivotal_tracker_project_id || project.folder_path == folder_path || project.github_repo == github_repo }.first

        project ||= Project.new

        project.folder_path = folder_path
        project.jira_url = jira_url
        project.jira_project_id = jira_project_id
        project.github_repo = github_repo
        project.feature_jira_task_id = feature_jira_task_id
        project.bug_jira_task_id = bug_jira_task_id
        project.chore_jira_task_id = chore_jira_task_id
        project.fix_jira_task_id = fix_jira_task_id
        project.meeting_jira_task_id = meeting_jira_task_id
        project.jira_transition_id_todo = jira_transition_id_todo
        project.jira_transition_id_in_progress = jira_transition_id_in_progress
        project.jira_transition_id_done = jira_transition_id_done
        project.pivotal_tracker_project_id = pivotal_tracker_project_id
        project.create_features_in_pivotal = create_features_in_pivotal
        project.create_bugs_in_pivotal = create_bugs_in_pivotal
        project.create_chores_in_pivotal = create_chores_in_pivotal
        project.create_fixes_in_pivotal_as_chores = create_fixes_in_pivotal_as_chores
        project.create_meetings_in_pivotal_as_chores = create_meetings_in_pivotal_as_chores
        project.save

        pivotal_data = get_pivotal_data(pivotal_id)
        title ||= pivotal_data[:title]
        description ||= pivotal_data[:description]
        pivotal_id = pivotal_data[:pivotal_id]

        if title
          record = nil

          case argv[0]
          when 'chore'
            record = project.chores.new(title: title, description: description, project_id: project_id, pivotal_id: pivotal_id, additional_time: additional_time)
          when 'bug'
            record = project.bugs.new(title: title, description: description, project_id: project_id, pivotal_id: pivotal_id, additional_time: additional_time)
          when 'feature'
            record = project.features.new(title: title, description: description, project_id: project_id, pivotal_id: pivotal_id, additional_time: additional_time)
          when 'fix'
            record = project.fixes.new(title: title, description: description, project_id: project_id, pivotal_id: pivotal_id, additional_time: additional_time)
          when 'meeting'
            record = project.meetings.new(title: title, description: description, project_id: project_id, pivotal_id: pivotal_id, additional_time: additional_time)
          end

          if record.valid?
            record.save
          else
            puts record.errors.details.to_s
          end
        else
          puts "Title is required. Add -t \"my #{argv[0]} title\" flag."
        end
      else
        puts 'Can not parse Capfile. Is it formatted properly?'
      end
    else
      puts 'Capefile not found. Are you in the project folder? If yes, run "caperoma init" to create Capefile.'
    end
  end

  def self.get_pivotal_data(pivotal_id)
    resulting_hash = { title: nil, description: nil, pivotal_id: pivotal_id }

    if Account.pivotal.present?
      if ENV['CAPEROMA_INTEGRATION_TEST'].blank?
        if pivotal_id.present?

          if pivotal_id.match? /\d+/
            conn = Faraday.new(url: 'https://www.pivotaltracker.com/') do |c|
              c.adapter Faraday.default_adapter
            end

            response = conn.get do |request|
              request.url "services/v5/stories/#{pivotal_id}"
              request.headers['User-Agent'] = 'Caperoma'
              request.headers['Content-Type'] = 'application/json'
              request.headers['X-TrackerToken'] = Account.pivotal.password
            end

            case response.status
            when 200, 201, 202, 204, 301, 302, 303, 304, 307
              result = JSON.parse response.body

              resulting_hash[:title] = result['name']
              resulting_hash[:description] = result['description']
            when 401, 403
              puts 'No access Pivotal. Maybe login or api_key are incorrect.'
            when 404
              puts 'Resource not found. Maybe Pivotal ID is incorrect.'
            else
              puts 'Could not get data from Pivotal.'
              puts "Error status: #{response.status}"
              puts "Message from server: #{response.reason_phrase}"
            end

            resulting_hash
          else
            puts 'Pivotal ID needs to be copied from the task in Pivotal (in either 12345678 or #12345678 format).'
            puts "Pivotal ID you entered was #{pivotal_id}, which does not match the allowed format."
            puts 'Skipping usage of this ID.'
            puts 'Proceeding as if Pivotal ID was not set.'
            puts 'Please start/finish the needed task in Pivotal manually.'

            resulting_hash[:pivotal_id] = nil
          end
        end
      end

      resulting_hash
    else
      puts 'Please set up Pivotal account.'
      resulting_hash
    end
  rescue Faraday::ConnectionFailed
    puts 'Connection failed. Performing the task without requests to Pivotal.'
    resulting_hash
  end

  def self.get_jira_project_ids
    puts 'Getting projects from Jira'

    if Account.jira.present?

      capefile_filename = ENV['CAPEROMA_TEST'].blank? && ENV['CAPEROMA_INTEGRATION_TEST'].blank? ? 'Capefile' : 'Capefile.test'
      if File.exist?(capefile_filename)
        capedata = YAML.load_file(capefile_filename)
        if capedata
          jira_url = capedata['jira_url']
          if jira_url
            conn = Faraday.new(url: jira_url) do |c|
              c.basic_auth(Account.jira.email, Account.jira.password)
              c.adapter Faraday.default_adapter
            end

            response = conn.get do |request|
              request.url 'rest/api/3/project.json'
              request.headers['User-Agent'] = 'Caperoma'
              request.headers['Content-Type'] = 'application/json'
            end

            case response.status
            when 200, 201, 202, 204, 301, 302, 303, 304, 307
              puts 'Received these projects'

              result = JSON.parse(response.body)

              result.each do |project|
                puts "Name: #{project['name']}, jira_project_id: #{project['id']}"
              end
            when 401, 403
              puts 'No access to Jira. Maybe login or api_key are incorrect.'
            when 404
              puts 'Resource not found. Maybe Jira ID is incorrect.'
            else
              puts 'Could not get data from Jira.'
              puts "Error status: #{response.status}"
              puts "Message from server: #{response.reason_phrase}"
            end
          else
            puts 'Please put at least jira url into your Capefile'
          end
        else
          puts 'Can not parse Capfile. Is it formatted properly?'
        end
      else
        puts 'Capefile not found. Are you in the project folder? If yes, run "caperoma init" to create Capefile.'
      end
    else
      puts 'Please set up Jira account first'
    end
  rescue Faraday::ConnectionFailed
    puts 'Connection failed.'
  end

  def self.manage_recipients(argv)
    case argv[1] # flag
    when /^(create|add|--add|--create|-a|-c)$/
      ReportRecipient.create email: argv[2]
    when /^(remove|delete|--remove|--delete|-d|-r)$/
      ReportRecipient.where(email: argv[2]).destroy_all
    when nil
      ReportRecipient.all.each { |x| puts x.email }
    else
      help
    end
  end

  def self.manage_reports(argv)
    case argv[1] # flag
    when /^(daily|-d)$/
      DailyReport.create
    when /^(three_day|-t)$/
      ThreeDayReport.create
    when /^(weekly|-w)$/
      RetrospectiveReport.create
    when 'auto'
      case argv[2] # subflag
      when 'on'
        Report.schedule
      when 'off'
        Report.unschedule
      else
        help
      end
    else
      help
    end
  end

  def self.manage_accounts(argv)
    case argv[1] # flag
    when /^(create|add|--add|--create|-a|-c)$/
      Account.create(type: argv[2], email: argv[3], password: argv[4], username: argv[5])
    when /^(remove|delete|--remove|--delete|-d|-r)$/
      Account.where(type: argv[2]).destroy_all
    when nil
      Account.all.each { |x| puts "#{x.type[2..-1].capitalize}: #{x.email} #{x.password} #{x.username}" }
      puts ''
      puts 'to delete run "caperoma accounts remove "--<type>"'
      puts 'to update run "... accounts --add "--<type>" again'
    else
      help
    end
  end

  def self.help
    puts File.read(File.join(File.dirname(__FILE__), '..', 'HELP'))
  end
end
