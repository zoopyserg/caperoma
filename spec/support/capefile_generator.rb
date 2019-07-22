# frozen_string_literal: true
require 'yaml'

CAPEFILE_SAMPLE_DATA = {
  'github_repo' => 'owner/repo',
  'jira_url' => 'https://owner.atlassian.net/',
  'jira_project_id' => 10001,
  'jira_issue_type_ids' => {
    'feature' => 10101,
    'bug' => 10103,
    'chore' => 10100,
    'fix' => 10101,
    'meeting' => 10100,
  },
  'jira_transition_ids' => {
    'todo' => 11,
    'in_progress' => 21,
    'done' => 31,
  },
  'pivotal_tracker_project_id' => 2374972,
  'create_features_in_pivotal' => true,
  'create_bugs_in_pivotal' => true,
  'create_chores_in_pivotal' => true,
  'create_fixes_in_pivotal_as_chores' => false,
  'create_meetings_in_pivotal_as_chores' => false
}

def create_capefile(jira_project_id)
  CAPEFILE_SAMPLE_DATA['jira_project_id'] = jira_project_id
  yaml = CAPEFILE_SAMPLE_DATA.to_yaml
  File.write 'Capefile.test', yaml
end

def remove_capefile
  File.delete 'Capefile.test'
end
