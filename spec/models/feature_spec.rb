# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RSpec.describe Feature, type: :model do
  describe 'inheritence' do
    it { expect(subject).to be_a_kind_of TaskWithSeparateBranch }
  end

  describe 'private methods' do
    describe '#issue_type' do
      let!(:project) { create :project, feature_jira_task_id: '1234' }

      let!(:task) { create :feature, project: project }

      it { expect(task.send(:issue_type)).to eq '1234' }
    end

    describe '#story_type' do
      let!(:task) { create :feature }

      it { expect(task.send(:story_type)).to eq 'feature' }
    end

    describe '#this_is_a_type_a_user_wants_to_create' do
      let!(:project) { create :project, create_features_in_pivotal: true }

      let!(:task) { build :feature, project: project }

      it { expect(task.send(:this_is_a_type_a_user_wants_to_create?)).to be_truthy }
    end
  end
end
