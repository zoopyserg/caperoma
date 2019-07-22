# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
ENV['spec_type'] = 'feature'

describe 'Projects' do
  before { Project.destroy_all }

  it 'displays all projects' do
    project1 = create :project, name: 'MyProj', jira_project_id: '123'
    project2 = create :project, name: 'MyProj2', jira_project_id: '321'

    result = `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma projects`
    expect(result).to eq "#{project1.id}) MyProj (jira_project_id: 123)\n#{project2.id}) MyProj2 (jira_project_id: 321)\n"
    # TODO: it should also include pivotal project id
  end
end
