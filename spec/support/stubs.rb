# frozen_string_literal: true

PROJECTS_LIST = [
  {
    'self' => 'http://www.example.com/jira/rest/api/2/project/EX',
    'id' => '123',
    'key' => 'EX',
    'name' => 'Dummy',
    'avatarUrls' => {
      '24x24' => 'http://www.example.com/jira/secure/projectavatar?size=small&pid=10000',
      '16x16' => 'http://www.example.com/jira/secure/projectavatar?size=xsmall&pid=10000',
      '32x32' => 'http://www.example.com/jira/secure/projectavatar?size=medium&pid=10000',
      '48x48' => 'http://www.example.com/jira/secure/projectavatar?size=large&pid=10000'
    },
    'projectCategory' => {
      'self' => 'http://www.example.com/jira/rest/api/2/projectCategory/10000',
      'id' => '10000',
      'name' => 'FIRST',
      'description' => 'First Project Category'
    }
  }
]

JIRA_ISSUE_CREATION = {
  'update' => {
    'worklog' => [{
      'add' => {
        'started' => '2011-07-05T11:05:00.000+0000',
        'timeSpent' => '60m'
      }
    }]
  },
  'fields' => {
    'project' => { 'id' => '10000' },
    'summary' => 'awesome issue',
    'issuetype' => { 'id' => '10000' },
    'assignee' => { 'name' => 'homer' },
    'description' => 'description',
    'components' => [{ 'id' => '10000' }]
  }
}

JIRA_ISSUE_CREATION_RESPONSE = Jbuilder.encode do |j|
  j.id '10000'
  j.key 'TST-24'
  j.self 'http://www.example.com/jira/rest/api/2/issue/10000'
end

PIVOTAL_ISSUE_CREATION_RESPONSE = Jbuilder.encode do |j|
  j.kind 'story'
  j.id '12345678'
  j.created_at '2019-07-03T18:38:59Z'
  j.updated_at '2019-07-04T12:31:04Z'
  j.estimate 2
  j.story_type 'feature'
  j.name 'Feature name'
  j.description 'Feature description'
  j.current_state 'unstarted'
  j.requested_by_id '23456789'
  j.url 'https://www.pivotaltracker.com/story/show/12345678'
  j.project_id 34_567_890
  j.owner_ids ['23456789']
  j.labels []
  j.owned_by_id '234567890'
end

RSpec.configure do |config|
  config.before do |example|
    if example.metadata[:unstub_reports].blank?
      allow_any_instance_of(Report).to receive(:send_email)
    end

    if example.metadata[:unstab_api_calls].blank?
      faraday = spy('faraday')
      allow(Faraday).to receive(:new).and_return faraday
      allow(Faraday).to receive(:default_adapter)
      allow(faraday).to receive(:get)
      allow(faraday).to receive(:post)
      allow(faraday).to receive(:put)
    end

    allow(STDOUT).to receive(:puts) if example.metadata[:unstub_puts].blank?

    if example.metadata[:unstub_time_now].blank?
      allow(Time).to receive(:now).and_return Time.parse('5 April 2014')
    end

    if example.metadata[:unstub_jira_creation].blank?
      allow_any_instance_of(Task).to receive :create_issue_on_jira
    end

    if example.metadata[:unstub_jira_starting].blank?
      allow_any_instance_of(Task).to receive :start_issue_on_jira
    end

    if example.metadata[:unstub_pivotal_creation].blank?
      allow_any_instance_of(Task).to receive :create_issue_on_pivotal
    end

    if example.metadata[:unstub_pivotal_starting].blank?
      allow_any_instance_of(Task).to receive :start_issue_on_pivotal
    end

    if example.metadata[:unstub_key_output].blank?
      allow_any_instance_of(Task).to receive :output_jira_key
    end
  end
end
