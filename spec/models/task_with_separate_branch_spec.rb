# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RSpec.describe TaskWithSeparateBranch, type: :model do
  describe 'methods' do
    describe '#finish' do
      let(:task) { create :task_with_separate_branch, title: 'title' }

      it 'should commit with generated message' do
        allow_any_instance_of(TaskWithSeparateBranch).to receive(:description_for_pull_request).and_return 'pivotal-url'
        allow_any_instance_of(TaskWithSeparateBranch).to receive(:git_current_branch).and_return 'parent-branch'

        expect(task).to receive(:git_pull_request).with('parent-branch', 'title', 'pivotal-url')
        expect(task).to receive(:git_checkout).with('parent-branch')

        task.finish(nil)
      end
    end

    describe '#pause' do
      let(:task) { create :task_with_separate_branch, title: 'title' }

      it 'should commit with generated message' do
        allow_any_instance_of(TaskWithSeparateBranch).to receive(:description_for_pull_request).and_return 'pivotal-url'
        expect(task).not_to receive(:git_pull_request).with('parent-branch', 'title', 'pivotal-url')
        expect(task).not_to receive(:git_checkout).with('parent-branch')

        task.pause(nil)
      end
    end

    describe '#abort' do
      let(:task) { create :task_with_separate_branch, title: 'title' }

      it 'should commit with generated message' do
        allow_any_instance_of(TaskWithSeparateBranch).to receive(:description_for_pull_request).and_return 'pivotal-url'
        allow_any_instance_of(TaskWithSeparateBranch).to receive(:git_current_branch).and_return 'parent-branch'

        expect(task).not_to receive(:git_pull_request).with('parent-branch', 'title', 'pivotal-url')
        expect(task).to receive(:git_checkout).with('parent-branch')

        task.abort(nil)
      end
    end
  end

  describe 'observers' do
    describe '::update_parent_branch' do
      let(:task) { build :task_with_separate_branch }

      it 'should get latest version of remote branch before switching' do
        expect(task).to receive(:git_rebase_to_upstream)
        task.save!
      end
    end

    describe '::remember_parent_branch' do
      let(:task) { build :task_with_separate_branch }

      it 'should save branch to send pull request to' do
        expect_any_instance_of(TaskWithSeparateBranch).to receive(:git_current_branch).and_return 'parent-branch'
        task.save!
        expect(task.reload.parent_branch).to eq 'parent-branch'
      end
    end

    describe '::new_git_branch' do
      it 'should make a new branch' do
        expect_any_instance_of(TaskWithSeparateBranch).to receive(:branch_name).and_return 'branch-name'
        expect_any_instance_of(TaskWithSeparateBranch).to receive(:git_branch).with('branch-name')

        create :task_with_separate_branch
      end
    end
  end

  describe 'private methods' do
    let!(:task) { create :task_with_separate_branch }

    before { expect(task).to receive(:jira_key).and_return 'RUC-123' }

    describe '#branch_name' do
      it 'should generate branch name' do
        expect(task).to receive(:title).and_return 'Hello World'
        result = task.send(:branch_name)
        expect(result).to eq 'ruc-123-hello-world'
      end

      it 'should cut the long titles' do
        expect(task).to receive(:title).and_return 'Hello World And Welcome To My Really Awesome Project'
        result = task.send(:branch_name)
        expect(result).to eq 'ruc-123-hello-world-and-welcome-t'
      end
    end
  end
end
