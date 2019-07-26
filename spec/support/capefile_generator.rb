# frozen_string_literal: true

require 'yaml'

def create_capefile(jira_project_id = 12_345)
  capefile_sample_data = {
    'github_repo' => 'owner/repo',
    'jira_url' => 'https://owner.atlassian.net/',
    'jira_project_id' => 10_001,
    'jira_issue_type_ids' => {
      'feature' => 10_101,
      'bug' => 10_103,
      'chore' => 10_100,
      'fix' => 10_101,
      'meeting' => 10_100
    },
    'jira_transition_ids' => {
      'todo' => 11,
      'in_progress' => 21,
      'done' => 31
    },
    'pivotal_tracker_project_id' => 2_374_972,
    'create_features_in_pivotal' => true,
    'create_bugs_in_pivotal' => true,
    'create_chores_in_pivotal' => true,
    'create_fixes_in_pivotal_as_chores' => false,
    'create_meetings_in_pivotal_as_chores' => false
  }
  capefile_sample_data['jira_project_id'] = jira_project_id
  yaml = capefile_sample_data.to_yaml
  File.write 'Capefile.test', yaml
end

def remove_capefile
  File.delete 'Capefile.test' if File.exist? 'Capefile.test'
end
