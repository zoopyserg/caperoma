# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RSpec.describe Fix, type: :model do
  describe 'inheritence' do
    it { expect(subject).to be_a_kind_of TaskWithCommit }
  end

  describe 'transitions' do
    let(:fix) { create :fix }

    it { expect {fix.swing!}.to output(/swing/).to_stdout }
    it { expect {fix.swing!}.to output(/swong/).to_stdout }
    it { expect {fix.swing!}.to output(/swung/).to_stdout }
    it { expect {fix.swing!}.to output(/sweng/).to_stdout }
  end

  describe 'methods' do
    describe 'description' do
      let!(:task) { create :fix, description: 'blah' }

      it 'should append last commit name' do
        allow(task).to receive(:git_last_commit_name).and_return('some great commit')
        expect(task.description).to eq "blah\n(For: some great commit)"
      end
    end
  end

  describe 'observers' do
    describe '::update_parent_branch' do
      let!(:task) { build :task_with_separate_branch }

      it 'should get latest version of remote branch before switching' do
        expect(task).to receive(:git_rebase_to_upstream)
        task.save!
      end
    end
  end

  describe 'private methods' do
    describe '#issue_type' do
      let!(:project) { create :project, fix_jira_task_id: '1234' }

      let!(:task) { create :fix, project: project }

      it { expect(task.send(:issue_type)).to eq '1234' }
    end

    describe '#story_type' do
      let!(:task) { create :fix }

      it { expect(task.send(:story_type)).to eq 'chore' }
    end

    describe '#this_is_a_type_a_user_wants_to_create' do
      let!(:project) { create :project, create_fixes_in_pivotal_as_chores: true }

      let!(:task) { build :fix, project: project }

      it { expect(task.send(:this_is_a_type_a_user_wants_to_create?)).to be_truthy }
    end
  end
end
