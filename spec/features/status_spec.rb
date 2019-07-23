# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
ENV['spec_type'] = 'feature'

describe 'Status' do
  context 'not working on anything' do
    it 'should say I am not working' do
      result = `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma status`
      expect(result).to eq "You are not working on anything now.\n"
    end
  end

  context 'working on a feature', :unstub_time_now do
    let!(:account) { create :account }
    let!(:project) { create :project }
    let!(:task) { create :feature, project: project, title: 'my title', jira_key: 'PBO-2', pivotal_id: 12_345_678, finished_at: nil }

    before { task.update_column :started_at, 2.hours.ago }
    before { task.update_column :parent_branch, 'master' }

    it 'should say I am not working' do
      result = `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma status`
      expect(result).to match /Type: Feature/
      expect(result).to match /Title: my title/
      expect(result).to match /Jira ID: PBO-2/
      expect(result).to match /Pivotal ID: 12345678/
      expect(result).to match /Time spent at the moment: 2h/
      expect(result).to match /Pull request will be sent to this branch: master/
    end
  end
end
