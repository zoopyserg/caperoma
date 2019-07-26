# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
ENV['spec_type'] = 'feature'

describe 'Open' do
  before { create_capefile('123') }

  subject { `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma open myproject` }

  context 'project exists' do
    let!(:project) { create :project, jira_project_id: '123', folder_path: '/path/to/myproject' }

    let(:content) { %r{Changing to /path/to/myproject} }

    it { expect(subject).to match content }
  end

  context 'not a single project did not match' do
    let!(:project) { create :project, jira_project_id: '123', folder_path: '/path/to/hisproject' }

    let(:content) { /Project not found./ }

    it { expect(subject).to match content }
  end

  context 'more than one project matched' do
    let!(:project1) { create :project, jira_project_id: '123', folder_path: '/path/to/myproject1' }
    let!(:project2) { create :project, jira_project_id: '123', folder_path: '/path/to/myproject2' }

    let(:content) { /Found more than one project:/ }

    it { expect(subject).to match content }
  end
end
