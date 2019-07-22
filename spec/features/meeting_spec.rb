# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
ENV['spec_type'] = 'feature'

describe 'Meeting' do
  let!(:project) { create :project, jira_project_id: '123' }

  before { create_capefile('123') }

  it 'submits a meeting' do
    expect do
      `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma meeting -t "awesome meeting" -d "some description" -a 1`
    end.to change {
      Meeting.where(
        title: 'awesome meeting',
        description: 'some description',
        project_id: project.id
      ).count
    }.by(1)
  end
end
