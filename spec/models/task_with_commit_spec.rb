# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RSpec.describe TaskWithCommit, type: :model do
  describe 'inheritence' do
    it { expect(subject).to be_a_kind_of Task }
  end

  describe 'methods' do
    describe '#finish' do
      let!(:task) { create :task_with_commit }

      it 'should commit with generated message' do
        expect_any_instance_of(TaskWithCommit).to receive(:commit_message).and_return 'commit msg'
        expect_any_instance_of(TaskWithCommit).to receive(:commit_rubocop_message).and_return 'rubocop commit msg'

        expect(task).to receive(:git_commit).with('commit msg')
        expect(task).to receive(:git_commit).with('rubocop commit msg')
        expect(task).to receive(:git_push)

        task.finish(nil)
      end
    end

    describe '#pause' do
      let!(:task) { create :task_with_commit }

      it 'should commit with generated message' do
        expect_any_instance_of(TaskWithCommit).to receive(:commit_message).and_return 'commit msg'
        expect_any_instance_of(TaskWithCommit).to receive(:commit_rubocop_message).and_return 'rubocop commit msg'

        expect(task).to receive(:git_commit).with('commit msg')
        expect(task).to receive(:git_commit).with('rubocop commit msg')
        expect(task).to receive(:git_push)

        task.pause(nil)
      end
    end

    describe '#abort' do
      let!(:task) { create :task_with_commit }

      it 'should not commit' do
        expect_any_instance_of(TaskWithCommit).not_to receive(:commit_message)
        expect_any_instance_of(TaskWithCommit).not_to receive(:commit_rubocop_message)

        expect(task).not_to receive(:git_commit).with('commit msg')
        expect(task).not_to receive(:git_push)

        task.abort(nil)
      end
    end
  end

  describe 'private methods' do
    let!(:task) { create :task_with_commit, title: 'Hello World', jira_key: jira_key, pivotal_id: pivotal_id }

    describe '#commit_message' do
      context 'neither jira nor pt id' do
        let(:jira_key) { nil }
        let(:pivotal_id) { nil }

        it 'should generate only title, no jira or pt ids' do
          result = task.send(:commit_message)
          expect(result).to eq 'Hello World'
        end
      end

      context 'jira id but no pt id' do
        let(:jira_key) { 'RUC-123' }
        let(:pivotal_id) { nil }

        it 'should generate commit msg with jira key only' do
          result = task.send(:commit_message)
          expect(result).to eq '[RUC-123] Hello World'
        end
      end

      context 'no jira id, but pt id' do
        let(:jira_key) { nil }
        let(:pivotal_id) { 12_345_678 }

        it 'should generate commit msg with pt id only' do
          result = task.send(:commit_message)
          expect(result).to eq '[#12345678] Hello World'
        end
      end

      context 'both jira id and pt id' do
        let(:jira_key) { 'RUC-123' }
        let(:pivotal_id) { 12_345_678 }

        it 'should append both jira and pivotal ids' do
          result = task.send(:commit_message)
          expect(result).to eq '[RUC-123][#12345678] Hello World'
        end
      end
    end
  end
end
