# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RSpec.describe Task, type: :model do
  describe 'relations' do
    it { expect(subject).to belong_to :project }
    it { expect(subject).to belong_to :daily_report }
    it { expect(subject).to belong_to :three_day_report }
    it { expect(subject).to belong_to :retrospective_report }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:title) }

    describe 'pivotal_id' do
      it { expect(subject).to allow_value(nil).for(:pivotal_id) }
      it { expect(subject).to allow_value('123456').for(:pivotal_id) }
      it { expect(subject).to allow_value('1234567').for(:pivotal_id) }
      it { expect(subject).to allow_value('12345678').for(:pivotal_id) }
      it { expect(subject).to allow_value('123456789').for(:pivotal_id) }
      it { expect(subject).not_to allow_value('#12345678').for(:pivotal_id) }
      it { expect(subject).not_to allow_value('12').for(:pivotal_id) }
      it { expect(subject).not_to allow_value('123.45678').for(:pivotal_id) }
    end

    describe 'additional_time' do
      it { expect(subject).to allow_value(nil).for(:additional_time) }
      it { expect(subject).to allow_value('12').for(:additional_time) }
      it { expect(subject).to allow_value('123456').for(:additional_time) }
      it { expect(subject).not_to allow_value('#12345678').for(:additional_time) }
      it { expect(subject).not_to allow_value('123.45678').for(:additional_time) }
    end
  end

  describe 'scopes' do
    describe '::unfinished' do
      let!(:started) { create :task, finished_at: nil }
      let!(:finished) { create :task, finished_at: Time.now }

      it 'should return tasks without finished_at time' do
        expect(Task.unfinished).to eq [started]
      end
    end

    describe '::finished' do
      let!(:started) { create :task, finished_at: nil }
      let!(:finished) { create :task, finished_at: Time.now }

      it 'should return tasks without finished_at time' do
        expect(Task.finished).to eq [finished]
      end
    end
  end

  describe 'status changes' do
    let!(:account_jira) { create :account, type: '--jira' }
    let!(:account_pivotal) { create :account, type: '--pivotal' }
    let(:task) { create :task, jira_key: 'PO-2', pivotal_id: pivotal_id }

    let(:response) { double('Faraday', body: JIRA_ISSUE_CREATION_RESPONSE, status: status, reason_phrase: reason_phrase) }
    let(:faraday) { double('Faraday', post: response) }
    let(:status) { 200 }
    let(:reason_phrase) { 'OK' }
    let(:pivotal_id) { '12345678' }

    before do
      allow(Faraday).to receive(:new).and_return faraday
      allow(Faraday).to receive(:default_adapter)
      allow(faraday).to receive(:post).and_return response
      allow(faraday).to receive(:get).and_return response
      allow(faraday).to receive(:put).and_return response
    end

    describe 'workflow' do
      it { expect(task).to transition_from(:created).to(:started).on_event(:start!) }
      it { expect(task).to transition_from(:started).to(:finished).on_event(:finish!) }
      it { expect(task).to transition_from(:started).to(:aborted).on_event(:abort!) }
      it { expect(task).to transition_from(:started).to(:aborted_without_time).on_event(:abort_without_time!) }
      it { expect(task).to transition_from(:started).to(:paused).on_event(:pause!) }
    end

    describe 'jira workflow' do
      it { expect(task).to transition_from(:pending_jira).to(:created_jira).on_event(:create_jira).on(:jira) }
      it { expect(task).to transition_from(:created_jira).to(:started_jira).on_event(:start_jira).on(:jira) }
      it { expect(task).to transition_from(:started_jira).to(:closed_jira).on_event(:close_jira!).on(:jira) }
    end

    describe 'pivotal workflow' do
      context 'creating' do
        let(:pivotal_id) { nil }

        before { allow(task).to receive(:this_is_a_type_a_user_wants_to_create?).and_return true }

        it { expect(task).to transition_from(:pending_pivotal).to(:created_pivotal).on_event(:create_pivotal).on(:pivotal) }
      end

      it { expect(task).to transition_from(:created_pivotal).to(:started_pivotal).on_event(:start_pivotal).on(:pivotal) }
      it { expect(task).to transition_from(:started_pivotal).to(:finished_pivotal).on_event(:finish_pivotal!).on(:pivotal) }
    end

    describe 'jira key' do
      it { expect(task).to transition_from(:hidden_jira_key).to(:shown_jira_key).on_event(:show_jira_key).on(:jira_key) }
    end

    describe 'jira work log' do
      it { expect(task).to transition_from(:pending_jira_worklog).to(:created_jira_worklog).on_event(:create_jira_worklog).on(:jira_worklog) }
    end

    describe 'start_on_pivotal_status' do
      context 'ok' do
        let(:status) { 200 }

        it { expect(task).to transition_from(:hidden_start_on_pivotal_status).to(:shown_start_on_pivotal_status).on_event(:show_start_on_pivotal_status).on(:start_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_no_access_to_start_issue_on_pivotal_status).to(:shown_no_access_to_start_issue_on_pivotal_status).on_event(:show_no_access_to_start_issue_on_pivotal_status).on(:no_access_to_start_issue_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_no_connection_to_start_issue_on_pivotal_status).to(:shown_no_connection_to_start_issue_on_pivotal_status).on_event(:show_no_connection_to_start_issue_on_pivotal_status).on(:no_connection_to_start_issue_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_unknown_error_on_starting_issue_on_pivotal_status).to(:shown_unknown_error_on_starting_issue_on_pivotal_status).on_event(:show_unknown_error_on_starting_issue_on_pivotal_status).on(:unknown_error_on_starting_issue_on_pivotal_status) }
      end

      context 'forbidden' do
        let(:status) { 401 }

        it { expect(task).not_to transition_from(:hidden_start_on_pivotal_status).to(:shown_start_on_pivotal_status).on_event(:show_start_on_pivotal_status).on(:start_on_pivotal_status) }
        it { expect(task).to transition_from(:hidden_no_access_to_start_issue_on_pivotal_status).to(:shown_no_access_to_start_issue_on_pivotal_status).on_event(:show_no_access_to_start_issue_on_pivotal_status).on(:no_access_to_start_issue_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_no_connection_to_start_issue_on_pivotal_status).to(:shown_no_connection_to_start_issue_on_pivotal_status).on_event(:show_no_connection_to_start_issue_on_pivotal_status).on(:no_connection_to_start_issue_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_unknown_error_on_starting_issue_on_pivotal_status).to(:shown_unknown_error_on_starting_issue_on_pivotal_status).on_event(:show_unknown_error_on_starting_issue_on_pivotal_status).on(:unknown_error_on_starting_issue_on_pivotal_status) }
      end

      context 'no access' do
        let(:status) { 404 }

        it { expect(task).not_to transition_from(:hidden_start_on_pivotal_status).to(:shown_start_on_pivotal_status).on_event(:show_start_on_pivotal_status).on(:start_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_no_access_to_start_issue_on_pivotal_status).to(:shown_no_access_to_start_issue_on_pivotal_status).on_event(:show_no_access_to_start_issue_on_pivotal_status).on(:no_access_to_start_issue_on_pivotal_status) }
        it { expect(task).to transition_from(:hidden_no_connection_to_start_issue_on_pivotal_status).to(:shown_no_connection_to_start_issue_on_pivotal_status).on_event(:show_no_connection_to_start_issue_on_pivotal_status).on(:no_connection_to_start_issue_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_unknown_error_on_starting_issue_on_pivotal_status).to(:shown_unknown_error_on_starting_issue_on_pivotal_status).on_event(:show_unknown_error_on_starting_issue_on_pivotal_status).on(:unknown_error_on_starting_issue_on_pivotal_status) }
      end

      context 'unknown error' do
        let(:status) { 500 }

        it { expect(task).not_to transition_from(:hidden_start_on_pivotal_status).to(:shown_start_on_pivotal_status).on_event(:show_start_on_pivotal_status).on(:start_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_no_access_to_start_issue_on_pivotal_status).to(:shown_no_access_to_start_issue_on_pivotal_status).on_event(:show_no_access_to_start_issue_on_pivotal_status).on(:no_access_to_start_issue_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_no_connection_to_start_issue_on_pivotal_status).to(:shown_no_connection_to_start_issue_on_pivotal_status).on_event(:show_no_connection_to_start_issue_on_pivotal_status).on(:no_connection_to_start_issue_on_pivotal_status) }
        it { expect(task).to transition_from(:hidden_unknown_error_on_starting_issue_on_pivotal_status).to(:shown_unknown_error_on_starting_issue_on_pivotal_status).on_event(:show_unknown_error_on_starting_issue_on_pivotal_status).on(:unknown_error_on_starting_issue_on_pivotal_status) }
      end
    end

    describe 'finished_on_pivotal_status' do
      context 'ok' do
        let(:status) { 200 }

        it { expect(task).to transition_from(:hidden_finished_on_pivotal_status).to(:shown_finished_on_pivotal_status).on_event(:show_finished_on_pivotal_status).on(:finished_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_no_access_to_finish_on_pivotal_status).to(:shown_no_access_to_finish_on_pivotal_status).on_event(:show_no_access_to_finish_on_pivotal_status).on(:no_access_to_finish_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_no_connection_to_finish_on_pivotal_status).to(:shown_no_connection_to_finish_on_pivotal_status).on_event(:show_no_connection_to_finish_on_pivotal_status).on(:no_connection_to_finish_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_unknown_error_on_finishing_on_pivotal_status).to(:shown_unknown_error_on_finishing_on_pivotal_status).on_event(:show_unknown_error_on_finishing_on_pivotal_status).on(:unknown_error_on_finishing_on_pivotal_status) }
      end

      context 'forbidden' do
        let(:status) { 401 }

        it { expect(task).not_to transition_from(:hidden_finished_on_pivotal_status).to(:shown_finished_on_pivotal_status).on_event(:show_finished_on_pivotal_status).on(:finished_on_pivotal_status) }
        it { expect(task).to transition_from(:hidden_no_access_to_finish_on_pivotal_status).to(:shown_no_access_to_finish_on_pivotal_status).on_event(:show_no_access_to_finish_on_pivotal_status).on(:no_access_to_finish_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_no_connection_to_finish_on_pivotal_status).to(:shown_no_connection_to_finish_on_pivotal_status).on_event(:show_no_connection_to_finish_on_pivotal_status).on(:no_connection_to_finish_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_unknown_error_on_finishing_on_pivotal_status).to(:shown_unknown_error_on_finishing_on_pivotal_status).on_event(:show_unknown_error_on_finishing_on_pivotal_status).on(:unknown_error_on_finishing_on_pivotal_status) }
      end

      context 'no access' do
        let(:status) { 404 }

        it { expect(task).not_to transition_from(:hidden_finished_on_pivotal_status).to(:shown_finished_on_pivotal_status).on_event(:show_finished_on_pivotal_status).on(:finished_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_no_access_to_finish_on_pivotal_status).to(:shown_no_access_to_finish_on_pivotal_status).on_event(:show_no_access_to_finish_on_pivotal_status).on(:no_access_to_finish_on_pivotal_status) }
        it { expect(task).to transition_from(:hidden_no_connection_to_finish_on_pivotal_status).to(:shown_no_connection_to_finish_on_pivotal_status).on_event(:show_no_connection_to_finish_on_pivotal_status).on(:no_connection_to_finish_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_unknown_error_on_finishing_on_pivotal_status).to(:shown_unknown_error_on_finishing_on_pivotal_status).on_event(:show_unknown_error_on_finishing_on_pivotal_status).on(:unknown_error_on_finishing_on_pivotal_status) }
      end

      context 'unknown error' do
        let(:status) { 500 }

        it { expect(task).not_to transition_from(:hidden_finished_on_pivotal_status).to(:shown_finished_on_pivotal_status).on_event(:show_finished_on_pivotal_status).on(:finished_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_no_access_to_finish_on_pivotal_status).to(:shown_no_access_to_finish_on_pivotal_status).on_event(:show_no_access_to_finish_on_pivotal_status).on(:no_access_to_finish_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_no_connection_to_finish_on_pivotal_status).to(:shown_no_connection_to_finish_on_pivotal_status).on_event(:show_no_connection_to_finish_on_pivotal_status).on(:no_connection_to_finish_on_pivotal_status) }
        it { expect(task).to transition_from(:hidden_unknown_error_on_finishing_on_pivotal_status).to(:shown_unknown_error_on_finishing_on_pivotal_status).on_event(:show_unknown_error_on_finishing_on_pivotal_status).on(:unknown_error_on_finishing_on_pivotal_status) }
      end
    end

    describe 'started_issue_on_jira_status' do
      context 'ok' do
        let(:status) { 200 }

        it { expect(task).to transition_from(:hidden_started_issue_on_jira_status).to(:shown_started_issue_on_jira_status).on_event(:show_started_issue_on_jira_status).on(:started_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_access_to_start_issue_on_jira_status).to(:shown_no_access_to_start_issue_on_jira_status).on_event(:show_no_access_to_start_issue_on_jira_status).on(:no_access_to_start_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_connection_to_start_issue_on_jira_status).to(:shown_no_connection_to_start_issue_on_jira_status).on_event(:show_no_connection_to_start_issue_on_jira_status).on(:no_connection_to_start_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_unknown_error_on_starting_issue_on_jira_status).to(:shown_unknown_error_on_starting_issue_on_jira_status).on_event(:show_unknown_error_on_starting_issue_on_jira_status).on(:unknown_error_on_starting_issue_on_jira_status) }
      end

      context 'forbidden' do
        let(:status) { 401 }

        it { expect(task).not_to transition_from(:hidden_started_issue_on_jira_status).to(:shown_started_issue_on_jira_status).on_event(:show_started_issue_on_jira_status).on(:started_issue_on_jira_status) }
        it { expect(task).to transition_from(:hidden_no_access_to_start_issue_on_jira_status).to(:shown_no_access_to_start_issue_on_jira_status).on_event(:show_no_access_to_start_issue_on_jira_status).on(:no_access_to_start_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_connection_to_start_issue_on_jira_status).to(:shown_no_connection_to_start_issue_on_jira_status).on_event(:show_no_connection_to_start_issue_on_jira_status).on(:no_connection_to_start_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_unknown_error_on_starting_issue_on_jira_status).to(:shown_unknown_error_on_starting_issue_on_jira_status).on_event(:show_unknown_error_on_starting_issue_on_jira_status).on(:unknown_error_on_starting_issue_on_jira_status) }
      end

      context 'no access' do
        let(:status) { 404 }

        it { expect(task).not_to transition_from(:hidden_started_issue_on_jira_status).to(:shown_started_issue_on_jira_status).on_event(:show_started_issue_on_jira_status).on(:started_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_access_to_start_issue_on_jira_status).to(:shown_no_access_to_start_issue_on_jira_status).on_event(:show_no_access_to_start_issue_on_jira_status).on(:no_access_to_start_issue_on_jira_status) }
        it { expect(task).to transition_from(:hidden_no_connection_to_start_issue_on_jira_status).to(:shown_no_connection_to_start_issue_on_jira_status).on_event(:show_no_connection_to_start_issue_on_jira_status).on(:no_connection_to_start_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_unknown_error_on_starting_issue_on_jira_status).to(:shown_unknown_error_on_starting_issue_on_jira_status).on_event(:show_unknown_error_on_starting_issue_on_jira_status).on(:unknown_error_on_starting_issue_on_jira_status) }
      end

      context 'unknown error' do
        let(:status) { 500 }

        it { expect(task).not_to transition_from(:hidden_started_issue_on_jira_status).to(:shown_started_issue_on_jira_status).on_event(:show_started_issue_on_jira_status).on(:started_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_access_to_start_issue_on_jira_status).to(:shown_no_access_to_start_issue_on_jira_status).on_event(:show_no_access_to_start_issue_on_jira_status).on(:no_access_to_start_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_connection_to_start_issue_on_jira_status).to(:shown_no_connection_to_start_issue_on_jira_status).on_event(:show_no_connection_to_start_issue_on_jira_status).on(:no_connection_to_start_issue_on_jira_status) }
        it { expect(task).to transition_from(:hidden_unknown_error_on_starting_issue_on_jira_status).to(:shown_unknown_error_on_starting_issue_on_jira_status).on_event(:show_unknown_error_on_starting_issue_on_jira_status).on(:unknown_error_on_starting_issue_on_jira_status) }
      end
    end

    describe 'closed_issue_on_jira_status' do
      context 'ok' do
        let(:status) { 200 }

        it { expect(task).to transition_from(:hidden_closed_issue_on_jira_status).to(:shown_closed_issue_on_jira_status).on_event(:show_closed_issue_on_jira_status).on(:closed_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_access_to_close_issue_on_jira_status).to(:shown_no_access_to_close_issue_on_jira_status).on_event(:show_no_access_to_close_issue_on_jira_status).on(:no_access_to_close_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_connection_to_close_issue_on_jira_status).to(:shown_no_connection_to_close_issue_on_jira_status).on_event(:show_no_connection_to_close_issue_on_jira_status).on(:no_connection_to_close_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_unknown_error_closing_issue_on_jira_status).to(:shown_unknown_error_closing_issue_on_jira_status).on_event(:show_unknown_error_closing_issue_on_jira_status).on(:unknown_error_closing_issue_on_jira_status) }
      end

      context 'forbidden' do
        let(:status) { 401 }

        it { expect(task).not_to transition_from(:hidden_closed_issue_on_jira_status).to(:shown_closed_issue_on_jira_status).on_event(:show_closed_issue_on_jira_status).on(:closed_issue_on_jira_status) }
        it { expect(task).to transition_from(:hidden_no_access_to_close_issue_on_jira_status).to(:shown_no_access_to_close_issue_on_jira_status).on_event(:show_no_access_to_close_issue_on_jira_status).on(:no_access_to_close_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_connection_to_close_issue_on_jira_status).to(:shown_no_connection_to_close_issue_on_jira_status).on_event(:show_no_connection_to_close_issue_on_jira_status).on(:no_connection_to_close_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_unknown_error_closing_issue_on_jira_status).to(:shown_unknown_error_closing_issue_on_jira_status).on_event(:show_unknown_error_closing_issue_on_jira_status).on(:unknown_error_closing_issue_on_jira_status) }
      end

      context 'no access' do
        let(:status) { 404 }

        it { expect(task).not_to transition_from(:hidden_closed_issue_on_jira_status).to(:shown_closed_issue_on_jira_status).on_event(:show_closed_issue_on_jira_status).on(:closed_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_access_to_close_issue_on_jira_status).to(:shown_no_access_to_close_issue_on_jira_status).on_event(:show_no_access_to_close_issue_on_jira_status).on(:no_access_to_close_issue_on_jira_status) }
        it { expect(task).to transition_from(:hidden_no_connection_to_close_issue_on_jira_status).to(:shown_no_connection_to_close_issue_on_jira_status).on_event(:show_no_connection_to_close_issue_on_jira_status).on(:no_connection_to_close_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_unknown_error_closing_issue_on_jira_status).to(:shown_unknown_error_closing_issue_on_jira_status).on_event(:show_unknown_error_closing_issue_on_jira_status).on(:unknown_error_closing_issue_on_jira_status) }
      end

      context 'unknown error' do
        let(:status) { 500 }

        it { expect(task).not_to transition_from(:hidden_closed_issue_on_jira_status).to(:shown_closed_issue_on_jira_status).on_event(:show_closed_issue_on_jira_status).on(:closed_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_access_to_close_issue_on_jira_status).to(:shown_no_access_to_close_issue_on_jira_status).on_event(:show_no_access_to_close_issue_on_jira_status).on(:no_access_to_close_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_connection_to_close_issue_on_jira_status).to(:shown_no_connection_to_close_issue_on_jira_status).on_event(:show_no_connection_to_close_issue_on_jira_status).on(:no_connection_to_close_issue_on_jira_status) }
        it { expect(task).to transition_from(:hidden_unknown_error_closing_issue_on_jira_status).to(:shown_unknown_error_closing_issue_on_jira_status).on_event(:show_unknown_error_closing_issue_on_jira_status).on(:unknown_error_closing_issue_on_jira_status) }
      end
    end

    describe 'loged_work_to_jira_status' do
      context 'ok' do
        let(:status) { 200 }

        it { expect(task).to transition_from(:hidden_loged_work_to_jira_status).to(:shown_loged_work_to_jira_status).on_event(:show_loged_work_to_jira_status).on(:loged_work_to_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_access_to_log_work_to_jira_status).to(:shown_no_access_to_log_work_to_jira_status).on_event(:show_no_access_to_log_work_to_jira_status).on(:no_access_to_log_work_to_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_connection_to_log_work_to_jira_status).to(:shown_no_connection_to_log_work_to_jira_status).on_event(:show_no_connection_to_log_work_to_jira_status).on(:no_connection_to_log_work_to_jira_status) }
        it { expect(task).not_to transition_from(:hidden_unknown_error_loging_work_to_jira_status).to(:shown_unknown_error_loging_work_to_jira_status).on_event(:show_unknown_error_loging_work_to_jira_status).on(:unknown_error_loging_work_to_jira_status) }
      end

      context 'forbidden' do
        let(:status) { 401 }

        it { expect(task).not_to transition_from(:hidden_loged_work_to_jira_status).to(:shown_loged_work_to_jira_status).on_event(:show_loged_work_to_jira_status).on(:loged_work_to_jira_status) }
        it { expect(task).to transition_from(:hidden_no_access_to_log_work_to_jira_status).to(:shown_no_access_to_log_work_to_jira_status).on_event(:show_no_access_to_log_work_to_jira_status).on(:no_access_to_log_work_to_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_connection_to_log_work_to_jira_status).to(:shown_no_connection_to_log_work_to_jira_status).on_event(:show_no_connection_to_log_work_to_jira_status).on(:no_connection_to_log_work_to_jira_status) }
        it { expect(task).not_to transition_from(:hidden_unknown_error_loging_work_to_jira_status).to(:shown_unknown_error_loging_work_to_jira_status).on_event(:show_unknown_error_loging_work_to_jira_status).on(:unknown_error_loging_work_to_jira_status) }
      end

      context 'no access' do
        let(:status) { 404 }

        it { expect(task).not_to transition_from(:hidden_loged_work_to_jira_status).to(:shown_loged_work_to_jira_status).on_event(:show_loged_work_to_jira_status).on(:loged_work_to_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_access_to_log_work_to_jira_status).to(:shown_no_access_to_log_work_to_jira_status).on_event(:show_no_access_to_log_work_to_jira_status).on(:no_access_to_log_work_to_jira_status) }
        it { expect(task).to transition_from(:hidden_no_connection_to_log_work_to_jira_status).to(:shown_no_connection_to_log_work_to_jira_status).on_event(:show_no_connection_to_log_work_to_jira_status).on(:no_connection_to_log_work_to_jira_status) }
        it { expect(task).not_to transition_from(:hidden_unknown_error_loging_work_to_jira_status).to(:shown_unknown_error_loging_work_to_jira_status).on_event(:show_unknown_error_loging_work_to_jira_status).on(:unknown_error_loging_work_to_jira_status) }
      end

      context 'unknown error' do
        let(:status) { 500 }

        it { expect(task).not_to transition_from(:hidden_loged_work_to_jira_status).to(:shown_loged_work_to_jira_status).on_event(:show_loged_work_to_jira_status).on(:loged_work_to_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_access_to_log_work_to_jira_status).to(:shown_no_access_to_log_work_to_jira_status).on_event(:show_no_access_to_log_work_to_jira_status).on(:no_access_to_log_work_to_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_connection_to_log_work_to_jira_status).to(:shown_no_connection_to_log_work_to_jira_status).on_event(:show_no_connection_to_log_work_to_jira_status).on(:no_connection_to_log_work_to_jira_status) }
        it { expect(task).to transition_from(:hidden_unknown_error_loging_work_to_jira_status).to(:shown_unknown_error_loging_work_to_jira_status).on_event(:show_unknown_error_loging_work_to_jira_status).on(:unknown_error_loging_work_to_jira_status) }
      end
    end

    describe 'created_issue_on_pivotal_status' do
      context 'ok' do
        let(:status) { 200 }

        it { expect(task).to transition_from(:hidden_created_issue_on_pivotal_status).to(:shown_created_issue_on_pivotal_status).on_event(:show_created_issue_on_pivotal_status).on(:created_issue_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_no_access_trying_to_create_issue_on_pivotal_status).to(:shown_no_access_trying_to_create_issue_on_pivotal_status).on_event(:show_no_access_trying_to_create_issue_on_pivotal_status).on(:no_access_trying_to_create_issue_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_no_connection_trying_to_create_issue_on_pivotal_status).to(:shown_no_connection_trying_to_create_issue_on_pivotal_status).on_event(:show_no_connection_trying_to_create_issue_on_pivotal_status).on(:no_connection_trying_to_create_issue_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_unknown_error_trying_to_create_issue_on_pivotal_status).to(:shown_unknown_error_trying_to_create_issue_on_pivotal_status).on_event(:show_unknown_error_trying_to_create_issue_on_pivotal_status).on(:unknown_error_trying_to_create_issue_on_pivotal_status) }
      end

      context 'forbidden' do
        let(:status) { 401 }

        it { expect(task).not_to transition_from(:hidden_created_issue_on_pivotal_status).to(:shown_created_issue_on_pivotal_status).on_event(:show_created_issue_on_pivotal_status).on(:created_issue_on_pivotal_status) }
        it { expect(task).to transition_from(:hidden_no_access_trying_to_create_issue_on_pivotal_status).to(:shown_no_access_trying_to_create_issue_on_pivotal_status).on_event(:show_no_access_trying_to_create_issue_on_pivotal_status).on(:no_access_trying_to_create_issue_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_no_connection_trying_to_create_issue_on_pivotal_status).to(:shown_no_connection_trying_to_create_issue_on_pivotal_status).on_event(:show_no_connection_trying_to_create_issue_on_pivotal_status).on(:no_connection_trying_to_create_issue_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_unknown_error_trying_to_create_issue_on_pivotal_status).to(:shown_unknown_error_trying_to_create_issue_on_pivotal_status).on_event(:show_unknown_error_trying_to_create_issue_on_pivotal_status).on(:unknown_error_trying_to_create_issue_on_pivotal_status) }
      end

      context 'no access' do
        let(:status) { 404 }

        it { expect(task).not_to transition_from(:hidden_created_issue_on_pivotal_status).to(:shown_created_issue_on_pivotal_status).on_event(:show_created_issue_on_pivotal_status).on(:created_issue_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_no_access_trying_to_create_issue_on_pivotal_status).to(:shown_no_access_trying_to_create_issue_on_pivotal_status).on_event(:show_no_access_trying_to_create_issue_on_pivotal_status).on(:no_access_trying_to_create_issue_on_pivotal_status) }
        it { expect(task).to transition_from(:hidden_no_connection_trying_to_create_issue_on_pivotal_status).to(:shown_no_connection_trying_to_create_issue_on_pivotal_status).on_event(:show_no_connection_trying_to_create_issue_on_pivotal_status).on(:no_connection_trying_to_create_issue_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_unknown_error_trying_to_create_issue_on_pivotal_status).to(:shown_unknown_error_trying_to_create_issue_on_pivotal_status).on_event(:show_unknown_error_trying_to_create_issue_on_pivotal_status).on(:unknown_error_trying_to_create_issue_on_pivotal_status) }
      end

      context 'unknown error' do
        let(:status) { 500 }

        it { expect(task).not_to transition_from(:hidden_created_issue_on_pivotal_status).to(:shown_created_issue_on_pivotal_status).on_event(:show_created_issue_on_pivotal_status).on(:created_issue_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_no_access_trying_to_create_issue_on_pivotal_status).to(:shown_no_access_trying_to_create_issue_on_pivotal_status).on_event(:show_no_access_trying_to_create_issue_on_pivotal_status).on(:no_access_trying_to_create_issue_on_pivotal_status) }
        it { expect(task).not_to transition_from(:hidden_no_connection_trying_to_create_issue_on_pivotal_status).to(:shown_no_connection_trying_to_create_issue_on_pivotal_status).on_event(:show_no_connection_trying_to_create_issue_on_pivotal_status).on(:no_connection_trying_to_create_issue_on_pivotal_status) }
        it { expect(task).to transition_from(:hidden_unknown_error_trying_to_create_issue_on_pivotal_status).to(:shown_unknown_error_trying_to_create_issue_on_pivotal_status).on_event(:show_unknown_error_trying_to_create_issue_on_pivotal_status).on(:unknown_error_trying_to_create_issue_on_pivotal_status) }
      end
    end

    describe 'creating issue on jira' do
      context 'ok' do
        let(:status) { 200 }

        it { expect(task).to transition_from(:hidden_created_issue_on_jira_status).to(:shown_created_issue_on_jira_status).on_event(:show_created_issue_on_jira_status).on(:created_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_access_to_create_issue_on_jira_status).to(:shown_no_access_to_create_issue_on_jira_status).on_event(:show_no_access_to_create_issue_on_jira_status).on(:no_access_to_create_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_connection_trying_to_create_issue_on_jira_status).to(:shown_no_connection_trying_to_create_issue_on_jira_status).on_event(:show_no_connection_trying_to_create_issue_on_jira_status).on(:no_connection_trying_to_create_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_unknown_error_trying_to_create_issue_on_jira_status).to(:shown_unknown_error_trying_to_create_issue_on_jira_status).on_event(:show_unknown_error_trying_to_create_issue_on_jira_status).on(:unknown_error_trying_to_create_issue_on_jira_status) }
      end

      context 'forbidden' do
        let(:status) { 401 }

        it { expect(task).not_to transition_from(:hidden_created_issue_on_jira_status).to(:shown_created_issue_on_jira_status).on_event(:show_created_issue_on_jira_status).on(:created_issue_on_jira_status) }
        it { expect(task).to transition_from(:hidden_no_access_to_create_issue_on_jira_status).to(:shown_no_access_to_create_issue_on_jira_status).on_event(:show_no_access_to_create_issue_on_jira_status).on(:no_access_to_create_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_connection_trying_to_create_issue_on_jira_status).to(:shown_no_connection_trying_to_create_issue_on_jira_status).on_event(:show_no_connection_trying_to_create_issue_on_jira_status).on(:no_connection_trying_to_create_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_unknown_error_trying_to_create_issue_on_jira_status).to(:shown_unknown_error_trying_to_create_issue_on_jira_status).on_event(:show_unknown_error_trying_to_create_issue_on_jira_status).on(:unknown_error_trying_to_create_issue_on_jira_status) }
      end

      context 'no connection' do
        let(:status) { 404 }

        it { expect(task).not_to transition_from(:hidden_created_issue_on_jira_status).to(:shown_created_issue_on_jira_status).on_event(:show_created_issue_on_jira_status).on(:created_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_access_to_create_issue_on_jira_status).to(:shown_no_access_to_create_issue_on_jira_status).on_event(:show_no_access_to_create_issue_on_jira_status).on(:no_access_to_create_issue_on_jira_status) }
        it { expect(task).to transition_from(:hidden_no_connection_trying_to_create_issue_on_jira_status).to(:shown_no_connection_trying_to_create_issue_on_jira_status).on_event(:show_no_connection_trying_to_create_issue_on_jira_status).on(:no_connection_trying_to_create_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_unknown_error_trying_to_create_issue_on_jira_status).to(:shown_unknown_error_trying_to_create_issue_on_jira_status).on_event(:show_unknown_error_trying_to_create_issue_on_jira_status).on(:unknown_error_trying_to_create_issue_on_jira_status) }
      end

      context 'unknown error' do
        let(:status) { 500 }

        it { expect(task).not_to transition_from(:hidden_created_issue_on_jira_status).to(:shown_created_issue_on_jira_status).on_event(:show_created_issue_on_jira_status).on(:created_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_access_to_create_issue_on_jira_status).to(:shown_no_access_to_create_issue_on_jira_status).on_event(:show_no_access_to_create_issue_on_jira_status).on(:no_access_to_create_issue_on_jira_status) }
        it { expect(task).not_to transition_from(:hidden_no_connection_trying_to_create_issue_on_jira_status).to(:shown_no_connection_trying_to_create_issue_on_jira_status).on_event(:show_no_connection_trying_to_create_issue_on_jira_status).on(:no_connection_trying_to_create_issue_on_jira_status) }
        it { expect(task).to transition_from(:hidden_unknown_error_trying_to_create_issue_on_jira_status).to(:shown_unknown_error_trying_to_create_issue_on_jira_status).on_event(:show_unknown_error_trying_to_create_issue_on_jira_status).on(:unknown_error_trying_to_create_issue_on_jira_status) }
      end
    end
  end

  describe 'class_methods' do
    let!(:account) { create :account, type: '--jira' }
    let(:faraday) { double('Faraday', post: response) }
    let(:response) { double('Faraday', body: JIRA_ISSUE_CREATION_RESPONSE, status: 200) }

    before { allow(Faraday).to receive(:new).and_return faraday }

    describe '::finish_started' do
      let!(:started) { create :task, finished_at: nil }

      it 'should finish started tasks' do
        expect(started.reload.finished_at).to be_nil

        Task.finish_started(nil)

        expect(started.reload.finished_at).to be_present
      end
    end

    describe '::pause_started' do
      let!(:started) { create :task, finished_at: nil }

      it 'should finish started tasks' do
        expect(started.reload.finished_at).to be_nil

        Task.pause_started(nil)

        expect(started.reload.finished_at).to be_present
      end
    end

    describe '::abort_started' do
      let!(:started) { create :task, finished_at: nil }

      it 'should abort started tasks' do
        expect(started.reload.finished_at).to be_nil

        Task.abort_started(nil)

        expect(started.reload.finished_at).to be_present
      end
    end

    describe '::abort_started_without_time' do
      let!(:started) { create :task, finished_at: nil }

      it 'should abort started tasks without time' do
        expect(started.reload.finished_at).to be_nil

        Task.abort_started_without_time(nil)

        expect(started.reload.finished_at).to be_present
      end
    end
  end

  describe 'methods' do
    let!(:jira_account) { create :account, type: '--jira' }
    let!(:pivotal_account) { create :account, type: '--pivotal' }
    let(:faraday) { double('Faraday', post: response) }
    let(:response) { double('Faraday', body: JIRA_ISSUE_CREATION_RESPONSE, status: 200) }

    let(:task) { create :task, finished_at: nil, pivotal_id: pivotal_id, jira_key: jira_key, additional_time: 5 }

    before { allow(Faraday).to receive(:new).and_return faraday }

    context 'pivotal_id present' do
      let(:pivotal_id) { '12345678' }
      let(:jira_key) { 'KN-5' }

      describe '#start' do
        # STOPPED HERE
        it { expect{ task.start! }.to output(/Starting a task/).to_stdout }
        it { expect{ task.start! }.to change{ task.state }.from('created').to('started') }
        it { expect{ task.start! }.to output(/Creating an issue in Jira/).to_stdout }
        it { expect{ task.start! }.to change{ task.jira_state }.from('pending_jira').to('created_jira') }

        it { expect{ task.start! }.to output(/A task is started/).to_stdout }
      end

      describe '#finish' do
        before { task.start! }

        it { expect{ task.finish! }.to output(/Finishing current task/).to_stdout }
        it { expect{ task.finish! }.to output(/Current task finished/).to_stdout }

        it { expect{ task.finish! }.to output(/Closing the issue in Jira/).to_stdout }

        it 'should finish it and log time' do
          expect(task).to receive :close_jira_in_jira_namespace
          expect(task).to receive :create_jira_worklog_in_jira_worklog_namespace
          expect(task).to receive :finish_pivotal_in_pivotal_namespace
          task.finish
          expect(task.finished_at).to be_present
        end
      end

      describe '#pause' do
        it 'should pause it and log time' do
          expect(task).to receive :close_jira
          expect(task).to receive :create_jira_worklog
          expect(task).to receive :finish_pivotal
          task.pause
          expect(task.finished_at).to be_present
        end
      end

      describe '#abort' do
        it 'should abort it and log time' do
          expect(task).to receive :close_jira
          expect(task).to receive :create_jira_worklog
          expect(task).to receive :finish_pivotal
          task.abort
          expect(task.finished_at).to be_present
        end
      end

      describe '#abort_without_time' do
        it 'should abort it and not log time' do
          expect(task).to receive :close_jira
          expect(task).not_to receive :create_jira_worklog
          expect(task).not_to receive :finish_pivotal
          task.abort_without_time
          expect(task.finished_at).to be_present
        end
      end
    end

    context 'pivotal_id blank' do
      let(:pivotal_id) { nil }
      let(:jira_key) { nil }

      describe '#finish' do
        it 'should finish it and log time' do
          expect(task).to receive :close_jira
          expect(task).to receive :create_jira_worklog
          expect(task).not_to receive :finish_pivotal
          task.finish!
          expect(task.finished_at).to be_present
        end
      end

      describe '#pause' do
        it 'should pause it and log time' do
          expect(task).to receive :close_jira
          expect(task).to receive :create_jira_worklog
          expect(task).not_to receive :finish_pivotal
          task.pause!
          expect(task.finished_at).to be_present
        end
      end

      describe '#abort' do
        it 'should abort it and log time' do
          expect(task).to receive :close_jira
          expect(task).to receive :create_jira_worklog
          expect(task).not_to receive :finish_pivotal
          task.abort!
          expect(task.finished_at).to be_present
        end
      end

      describe '#abort_without_time' do
        it 'should abort it and not log time' do
          expect(task).to receive :close_jira
          expect(task).not_to receive :create_jira_worklog
          expect(task).not_to receive :finish_pivotal
          task.abort_without_time!
          expect(task.finished_at).to be_present
        end
      end
    end

    # TODO: handle cases where jira/pt ids are present, but neither jira nor pt are set up.
  end

  describe 'observers' do
    let!(:project) { create :project, jira_project_id: 135 }

    describe '::set_start_time' do
      let!(:timestamp) { Time.parse('5 April 2014') }
      before { expect(Time).to receive(:now).and_return timestamp }

      context 'no additional time' do
        let(:task) { build :task }
        it 'should set setarted_at time' do
          task.save
          expect(task.reload.started_at).to eq timestamp
        end
      end

      context 'additional time present' do
        let(:task) { build :task, additional_time: '23' }
        it 'should move started_at back to past by X minutes' do
          task.save
          expect(task.reload.started_at).to eq (timestamp - 23.minutes)
        end
      end
    end

    describe '::create_issue_on_jira', :unstub_jira_creation do
      context 'jira account present' do
        let(:task) { create :task }
        let!(:account) { create :account, type: '--jira' }
        let(:faraday) { double('Faraday', post: response) }
        let(:response) { double('Faraday', body: JIRA_ISSUE_CREATION_RESPONSE, status: 200) }

        it 'should create task in Jira after create' do
          expect(Faraday).to receive(:new).and_return faraday

          task.save

          task.reload.tap do |task|
            expect(task.jira_id).to eq '10000'
            expect(task.jira_key).to eq 'TST-24'
            expect(task.jira_url).to eq 'http://www.example.com/jira/rest/api/2/issue/10000'
          end
        end
      end

      context 'jira account present but no internet connection' do
        let(:task) { create :task }
        let!(:account) { create :account, type: '--jira' }
        let(:faraday) { double('Faraday', post: response) }
        let(:response) { double('Faraday', body: JIRA_ISSUE_CREATION_RESPONSE, status: 200) }

        before do
          expect(Faraday).to receive(:new).and_return faraday
          allow(faraday).to receive(:post).and_raise Faraday::ConnectionFailed, [404]
          allow(faraday).to receive(:get).and_raise Faraday::ConnectionFailed, [404]
          allow(faraday).to receive(:put).and_raise Faraday::ConnectionFailed, [404]
        end

        it 'give an error that there is no connection' do
          expect(STDOUT).to receive(:puts).with /Connection failed. Performing the task without requests to Jira./
          task.save
        end

        it 'should still create the task' do
          expect do
            task.save
          end.to change {
            Task.count
          }.by(1)
        end
      end

      context 'jira account present but the returned status was "forbidden"' do
        let(:task) { create :task, jira_key: nil }
        let!(:account) { create :account, type: '--jira' }
        let(:faraday) { double('Faraday', post: response) }
        let(:response) { double('Faraday', body: JIRA_ISSUE_CREATION_RESPONSE, status: 401, reason_phrase: 'not authorized') }

        before do
          expect(Faraday).to receive(:new).and_return faraday
          allow(faraday).to receive(:post).and_return response
          allow(faraday).to receive(:get).and_return response
          allow(faraday).to receive(:put).and_return response
        end

        it 'give an error that there is no connection' do
          expect(STDOUT).to receive(:puts).with /Forbidden access/
          task.save
        end

        it 'should still create the task' do
          expect do
            task.save
          end.to change {
            Task.count
          }.by(1)
        end

        it 'should keep jira_key blank' do
          task.save
          expect(task.reload.jira_key).to be_nil
        end
      end

      context 'jira account present but the returned status was "forbidden"' do
        let(:task) { create :task, jira_key: nil }
        let!(:account) { create :account, type: '--jira' }
        let(:faraday) { double('Faraday', post: response) }
        let(:response) { double('Faraday', body: JIRA_ISSUE_CREATION_RESPONSE, status: 403, reason_phrase: 'not authorized') }

        before do
          expect(Faraday).to receive(:new).and_return faraday
          allow(faraday).to receive(:post).and_return response
          allow(faraday).to receive(:get).and_return response
          allow(faraday).to receive(:put).and_return response
        end

        it 'give an error that there is no connection' do
          expect(STDOUT).to receive(:puts).with /Forbidden access/
          task.save
        end

        it 'should still create the task' do
          expect do
            task.save
          end.to change {
            Task.count
          }.by(1)
        end

        it 'should keep jira_key blank' do
          task.save
          expect(task.reload.jira_key).to be_nil
        end
      end

      context 'jira account present but the returned status was "not found"' do
        let(:task) { create :task, jira_key: nil }
        let!(:account) { create :account, type: '--jira' }
        let(:faraday) { double('Faraday', post: response) }
        let(:response) { double('Faraday', body: JIRA_ISSUE_CREATION_RESPONSE, status: 404, reason_phrase: 'not found') }

        before do
          expect(Faraday).to receive(:new).and_return faraday
          allow(faraday).to receive(:post).and_return response
          allow(faraday).to receive(:get).and_return response
          allow(faraday).to receive(:put).and_return response
        end

        it 'give an error that there is no connection' do
          expect(STDOUT).to receive(:puts).with /Not found/
          task.save
        end

        it 'should still create the task' do
          expect do
            task.save
          end.to change {
            Task.count
          }.by(1)
        end

        it 'should keep jira_key blank' do
          task.save
          expect(task.reload.jira_key).to be_nil
        end
      end

      context 'jira account present but the returned status was unknown error' do
        let(:task) { create :task, jira_key: nil }
        let!(:account) { create :account, type: '--jira' }
        let(:faraday) { double('Faraday', post: response) }
        let(:response) { double('Faraday', body: JIRA_ISSUE_CREATION_RESPONSE, status: 500, reason_phrase: 'server error') }

        before do
          expect(Faraday).to receive(:new).and_return faraday
          allow(faraday).to receive(:post).and_return response
          allow(faraday).to receive(:get).and_return response
          allow(faraday).to receive(:put).and_return response
        end

        it 'give an error that there is no connection' do
          expect(STDOUT).to receive(:puts).with /Could not/
          expect(STDOUT).to receive(:puts).with /500/
          expect(STDOUT).to receive(:puts).with /server error/

          task.save
        end

        it 'should still create the task' do
          expect do
            task.save
          end.to change {
            Task.count
          }.by(1)
        end

        it 'should keep jira_key blank' do
          task.save
          expect(task.reload.jira_key).to be_nil
        end
      end

      context 'jira account not present' do
        let(:task) { create :task }
        let(:faraday) { double('Faraday', post: response) }
        let(:response) { double('Faraday', body: JIRA_ISSUE_CREATION_RESPONSE, status: 200) }

        it 'should not create task in Jira after create' do
          allow(Faraday).to receive(:new).and_return faraday
          expect(task).not_to receive :create_issue_on_jira

          task.save
        end
      end
    end

    describe '::start_jira' do
      let(:task) { build :task, jira_key: jira_key }

      context 'account present, jira id present' do
        let!(:account) { create :account, type: '--jira' }
        let!(:jira_key) { 'OK-1' }

        it 'should start task in Jira after create' do
          expect(task).to receive(:start_jira)

          task.start
        end
      end

      context 'jira id present, account present, no internet connection' do
        let!(:account) { create :account, type: '--jira' }
        let!(:jira_key) { 'OK-1' }
        let(:faraday) { double('Faraday', post: response) }
        let(:response) { double('Faraday', body: JIRA_ISSUE_CREATION_RESPONSE, status: 200) }

        before do
          allow(Faraday).to receive(:new).and_return faraday
          allow(faraday).to receive(:post).and_raise Faraday::ConnectionFailed, [404]
          allow(faraday).to receive(:get).and_raise Faraday::ConnectionFailed, [404]
          allow(faraday).to receive(:put).and_raise Faraday::ConnectionFailed, [404]
        end

        it 'should give the no connection error', :unstub_jira_starting do
          expect(STDOUT).to receive(:puts).with /Connection failed. Performing the task without requests to Jira./
          task.save
        end
      end

      describe 'error codes', :unstub_jira_starting do
        let!(:account) { create :account, type: '--jira' }
        let!(:jira_key) { 'OK-1' }
        let(:faraday) { double('Faraday', post: response) }
        let(:response) { double('Faraday', body: JIRA_ISSUE_CREATION_RESPONSE, status: status, reason_phrase: reason_phrase) }
        let(:status) { 200 }
        let(:reason_phrase) { 'OK' }

        before do
          allow(Faraday).to receive(:new).and_return faraday
          allow(faraday).to receive(:post).and_return response
          allow(faraday).to receive(:get).and_return response
          allow(faraday).to receive(:put).and_return response
        end

        context 'jira id present, account present, but server gave "unouthorized" error' do
          let(:status) { 401 }
          let(:reason_phrase) { 'unauthorized' }

          it 'should say it could not start' do
            expect(STDOUT).to receive(:puts).with /No access/
            task.save
          end
        end

        context 'jira id present, account present, but server gave "unouthorized" error' do
          let(:status) { 403 }
          let(:reason_phrase) { 'unauthorized' }

          it 'should say it could not start' do
            expect(STDOUT).to receive(:puts).with /No access/
            task.save
          end
        end

        context 'jira id present, account present, but server gave "not found" error' do
          let(:status) { 404 }
          let(:reason_phrase) { 'not found' }

          it 'should say it could not start' do
            expect(STDOUT).to receive(:puts).with /not found/
            task.save
          end
        end

        context 'jira id present, account present, but server gave "unknown" error' do
          let(:status) { 500 }
          let(:reason_phrase) { 'server error' }

          it 'should say it could not start' do
            expect(STDOUT).to receive(:puts).with /Could not/
            expect(STDOUT).to receive(:puts).with /500/
            expect(STDOUT).to receive(:puts).with /server error/
            task.save
          end
        end
      end

      context 'account not present, jira id not present' do
        let!(:jira_key) { 'OK-1' }

        it 'should start task in Jira after create' do
          expect(task).not_to receive(:start_issue_on_jira)

          task.save
        end
      end

      context 'account present, jira id present' do
        let!(:account) { create :account, type: '--jira' }
        let!(:jira_key) { nil }

        it 'should start task in Jira after create' do
          expect(task).not_to receive(:start_issue_on_jira)

          task.save
        end
      end

      context 'account not present, jira id not present' do
        let!(:jira_key) { nil }

        it 'should start task in Jira after create' do
          expect(task).not_to receive(:start_issue_on_jira)

          task.save
        end
      end
    end

    describe '::create_issue_on_pivotal', :unstub_pivotal_creation do
      context 'pivotal account present' do
        let(:task) { build :task, pivotal_id: pt_id }
        let!(:account) { create :account, type: '--pivotal' }
        let(:faraday) { double('Faraday', post: response) }
        let(:response) { double('Faraday', body: PIVOTAL_ISSUE_CREATION_RESPONSE, status: status, reason_phrase: reason_phrase) }
        let(:status) { 200 }
        let(:reason_phrase) { 'OK' }

        before { allow(task).to receive(:this_is_a_type_a_user_wants_to_create?).and_return(should_create) }

        context 'PT id present but should not create' do
          let(:pt_id) { '567890123' }
          let(:should_create) { false }

          it 'should not create task in Pivotal' do
            task.save

            task.reload.tap do |task|
              expect(task.pivotal_id).to eq '567890123'
            end
          end
        end

        context 'PT id present and should create' do
          let(:pt_id) { '567890123' }
          let(:should_create) { true }

          it 'should not create task in Pivotal' do
            task.save

            task.reload.tap do |task|
              expect(task.pivotal_id).to eq '567890123'
            end
          end
        end

        context 'PT id present and should create but there is no internet connection' do
          let(:pt_id) { nil }
          let(:should_create) { true }

          before do
            allow(Faraday).to receive(:new).and_return faraday
            allow(faraday).to receive(:post).and_raise Faraday::ConnectionFailed, [404]
            allow(faraday).to receive(:get).and_raise Faraday::ConnectionFailed, [404]
            allow(faraday).to receive(:put).and_raise Faraday::ConnectionFailed, [404]
          end

          it 'should still be nil' do
            task.save

            task.reload.tap do |task|
              expect(task.pivotal_id).to be_blank
            end
          end

          it 'should say there is no connection' do
            expect(STDOUT).to receive(:puts).with /Connection failed. Performing the task without requests to Pivotal./
            task.save
          end

          it 'should still create the task' do
            expect do
              task.save
            end.to change {
              Task.count
            }.by(1)
          end
        end

        context 'PT id blank but should not create' do
          let(:pt_id) { nil }
          let(:should_create) { false }

          it 'should not create task in Pivotal' do
            task.save

            task.reload.tap do |task|
              expect(task.pivotal_id).to eq nil
            end
          end
        end

        context 'PT id blank and should create' do
          let(:pt_id) { nil }
          let(:should_create) { true }

          it 'should create task in Pivotal' do
            expect(Faraday).to receive(:new).and_return faraday
            task.save

            task.reload.tap do |task|
              expect(task.pivotal_id).to eq '12345678'
            end
          end
        end

        context 'PT id blank and should create but got "unauthorized error' do
          let(:pt_id) { nil }
          let(:should_create) { true }
          let(:status) { 401 }
          let(:reason_phrase) { 'unauthorized' }

          before do
            allow(Faraday).to receive(:new).and_return faraday
            allow(faraday).to receive(:post).and_return response
            allow(faraday).to receive(:get).and_return response
            allow(faraday).to receive(:put).and_return response
          end

          it 'should create task in Pivotal' do
            expect do
              task.save
            end.to change {
              Task.count
            }.by(1)
          end

          it 'should keep pivotal id blank' do
            task.save
            task.reload.tap do |task|
              expect(task.pivotal_id).to eq nil
            end
          end

          it 'should say it got an error' do
            expect(STDOUT).to receive(:puts).with /No access/

            task.save
          end
        end

        context 'PT id blank and should create but got "unauthorized error' do
          let(:pt_id) { nil }
          let(:should_create) { true }
          let(:status) { 403 }
          let(:reason_phrase) { 'unauthorized' }

          before do
            allow(Faraday).to receive(:new).and_return faraday
            allow(faraday).to receive(:post).and_return response
            allow(faraday).to receive(:get).and_return response
            allow(faraday).to receive(:put).and_return response
          end

          it 'should create task in Pivotal' do
            expect do
              task.save
            end.to change {
              Task.count
            }.by(1)
          end

          it 'should keep pivotal id blank' do
            task.save
            task.reload.tap do |task|
              expect(task.pivotal_id).to eq nil
            end
          end

          it 'should say it got an error' do
            expect(STDOUT).to receive(:puts).with /No access/

            task.save
          end
        end

        context 'PT id blank and should create but got "not found" error' do
          let(:pt_id) { nil }
          let(:should_create) { true }
          let(:status) { 404 }
          let(:reason_phrase) { 'unauthorized' }

          before do
            allow(Faraday).to receive(:new).and_return faraday
            allow(faraday).to receive(:post).and_return response
            allow(faraday).to receive(:get).and_return response
            allow(faraday).to receive(:put).and_return response
          end

          it 'should create task in Pivotal' do
            expect do
              task.save
            end.to change {
              Task.count
            }.by(1)
          end

          it 'should keep pivotal id blank' do
            task.save
            task.reload.tap do |task|
              expect(task.pivotal_id).to eq nil
            end
          end

          it 'should say it got an error' do
            expect(STDOUT).to receive(:puts).with /not found/

            task.save
          end
        end

        context 'PT id blank and should create but got "some other" error' do
          let(:pt_id) { nil }
          let(:should_create) { true }
          let(:status) { 500 }
          let(:reason_phrase) { 'server error' }

          before do
            allow(Faraday).to receive(:new).and_return faraday
            allow(faraday).to receive(:post).and_return response
            allow(faraday).to receive(:get).and_return response
            allow(faraday).to receive(:put).and_return response
          end

          it 'should create task in Pivotal' do
            expect do
              task.save
            end.to change {
              Task.count
            }.by(1)
          end

          it 'should keep pivotal id blank' do
            task.save
            task.reload.tap do |task|
              expect(task.pivotal_id).to eq nil
            end
          end

          it 'should say it got an error' do
            expect(STDOUT).to receive(:puts).with /Could not/
            expect(STDOUT).to receive(:puts).with /500/
            expect(STDOUT).to receive(:puts).with /server error/

            task.save
          end
        end
      end

      context 'pivotal account blank' do
        let(:task) { build :task, pivotal_id: pt_id }
        let(:faraday) { double('Faraday', post: response) }
        let(:response) { double('Faraday', body: PIVOTAL_ISSUE_CREATION_RESPONSE, status: 200) }

        before { allow(task).to receive(:this_is_a_type_a_user_wants_to_create?).and_return(should_create) }

        context 'PT id present but should not create' do
          let(:pt_id) { '567890123' }
          let(:should_create) { false }

          it 'should not create task in Pivotal' do
            task.save

            task.reload.tap do |task|
              expect(task.pivotal_id).to eq '567890123'
            end
          end
        end

        context 'PT id present but should create' do
          let(:pt_id) { '567890123' }
          let(:should_create) { true }

          it 'should not create task in Pivotal' do
            task.save

            task.reload.tap do |task|
              expect(task.pivotal_id).to eq '567890123'
            end
          end
        end

        context 'PT id blank but should not create' do
          let(:pt_id) { nil }
          let(:should_create) { false }

          it 'should not create task in Pivotal' do
            task.save

            task.reload.tap do |task|
              expect(task.pivotal_id).to eq nil
            end
          end
        end

        context 'PT id blank and should create' do
          let(:pt_id) { nil }
          let(:should_create) { true }

          it 'should create task in Pivotal' do
            allow(Faraday).to receive(:new).and_return faraday
            task.save

            task.reload.tap do |task|
              expect(task.pivotal_id).to be_blank
            end
          end
        end
      end
    end

    describe '::start_pivotal' do
      let(:task) { create :task, pivotal_id: pivotal_id }

      context 'pt id present, pt account present' do
        let(:pivotal_id) { '12345678' }
        let!(:account) { create :account, type: '--pivotal' }

        it 'should start task in pivotal after create' do
          expect(task).to receive(:start_pivotal)

          task.start
        end
      end

      context 'pt id present, pt account present, no internet connection' do
        let(:pivotal_id) { '12345678' }
        let!(:account) { create :account, type: '--pivotal' }
        let(:faraday) { double('Faraday', post: response) }
        let(:response) { double('Faraday', body: PIVOTAL_ISSUE_CREATION_RESPONSE, status: 200) }

        before do
          allow(Faraday).to receive(:new).and_return faraday
          allow(faraday).to receive(:post).and_raise Faraday::ConnectionFailed, [404]
          allow(faraday).to receive(:get).and_raise Faraday::ConnectionFailed, [404]
          allow(faraday).to receive(:put).and_raise Faraday::ConnectionFailed, [404]
        end

        it 'should give the no connection error', :unstub_pivotal_starting do
          expect(STDOUT).to receive(:puts).with /Connection failed. Performing the task without requests to Pivotal./
          task.save
        end
      end

      describe 'error codes', :unstub_pivotal_starting do
        let(:pivotal_id) { '12345678' }
        let!(:account) { create :account, type: '--pivotal' }
        let(:faraday) { double('Faraday', post: response) }
        let(:response) { double('Faraday', body: PIVOTAL_ISSUE_CREATION_RESPONSE, status: status, reason_phrase: reason_phrase) }
        let(:status) { 200 }
        let(:reason_phrase) { 'OK' }

        before do
          allow(Faraday).to receive(:new).and_return faraday
          allow(faraday).to receive(:post).and_return response
          allow(faraday).to receive(:get).and_return response
          allow(faraday).to receive(:put).and_return response
        end

        context 'pt id present, pt account present, "unauthorized" server error' do
          let(:status) { 401 }
          let(:reason_phrase) { 'unauth' }

          it 'should give the no auth error' do
            expect(STDOUT).to receive(:puts).with /No access/
            task.save
          end
        end

        context 'pt id present, pt account present, "unauthorized" server error' do
          let(:status) { 403 }
          let(:reason_phrase) { 'unauth' }

          it 'should give the no auth error' do
            expect(STDOUT).to receive(:puts).with /No access/
            task.save
          end
        end

        context 'pt id present, pt account present, "not found" server error' do
          let(:status) { 404 }
          let(:reason_phrase) { 'not found' }

          it 'should give the not found error' do
            expect(STDOUT).to receive(:puts).with /not found/
            task.save
          end
        end

        context 'pt id present, pt account present, "unknown" server error' do
          let(:status) { 500 }
          let(:reason_phrase) { 'error' }

          it 'should give the error' do
            expect(STDOUT).to receive(:puts).with /Could not/
            expect(STDOUT).to receive(:puts).with /500/
            expect(STDOUT).to receive(:puts).with /error/
            task.save
          end
        end
      end

      context 'pt id blank, pt account present' do
        let(:pivotal_id) { nil }
        let!(:account) { create :account, type: '--pivotal' }

        it 'should not start task in pivotal after create' do
          expect(task).not_to receive(:start_issue_on_pivotal)

          task.save
        end
      end

      context 'pt id present, pt account blank' do
        let(:pivotal_id) { '12345678' }

        it 'should start task in pivotal after create' do
          expect(task).not_to receive(:start_issue_on_pivotal)

          task.save
        end
      end

      context 'pt id blank, pt account blank' do
        let(:pivotal_id) { nil }

        it 'should not start task in pivotal after create' do
          expect(task).not_to receive(:start_issue_on_pivotal)

          task.save
        end
      end
    end

    describe '::output_jira_key', :unstub_key_output, :unstub_puts do
      let(:task) { build :task, jira_key: jira_key }

      context 'jira_key present' do
        let(:jira_key) { 'TST-24' }

        it 'should output ID to STDOUT' do
          expect(STDOUT).to receive(:puts).with('TST-24')
          task.save
        end
      end

      context 'jira_key present' do
        let(:jira_key) { nil }

        it 'should not output ID to STDOUT' do
          expect(STDOUT).not_to receive(:puts).with('TST-24')
          task.save
        end
      end
    end
  end

  describe 'private methods' do
    let!(:project) { create :project, jira_project_id: '123' }
    let!(:account) { create :account, type: '--jira', username: 'someuser' }

    describe '#create_issue_on_jira_data' do
      let!(:task) { create :task, title: 'dupis', description: description, project: project }

      context 'description present' do
        let(:description) { 'bamis' }

        it 'should format hash' do
          allow(task).to receive(:issue_type).and_return '492'
          result = task.send(:create_issue_on_jira_data)
          JSON.parse(result).tap do |format|
            expect(format['fields']['project']['id']).to eq '123'
            expect(format['fields']['issuetype']['id']).to eq '492'
            expect(format['fields']['summary']).to eq 'dupis'
            expect(format['fields']['description']['content'][0]['content'][0]['text']).to eq 'bamis'
            expect(format['fields']['assignee']['name']).to eq 'someuser'
          end
        end
      end

      context 'description not' do
        let(:description) { nil }

        it 'should format hash' do
          allow(task).to receive(:issue_type).and_return '492'
          result = task.send(:create_issue_on_jira_data)
          JSON.parse(result).tap do |format|
            expect(format['fields']['project']['id']).to eq '123'
            expect(format['fields']['issuetype']['id']).to eq '492'
            expect(format['fields']['summary']).to eq 'dupis'
            expect(format['fields']['assignee']['name']).to eq 'someuser'

            expect(format['fields']['description']).to be_nil
          end
        end
      end
    end

    describe '#start_issue_on_jira_data' do
      let!(:project) { create :project, jira_transition_id_in_progress: '12345' }

      let!(:task) { create :task, project: project }

      it 'should format hash' do
        result = task.send(:start_issue_on_jira_data)
        JSON.parse(result).tap do |format|
          expect(format['transition']['id']).to eq '12345'
        end
      end
    end

    describe '#close_issue_on_jira_data' do
      let!(:project) { create :project, jira_transition_id_done: '12345' }

      let!(:task) { create :task, project: project }

      it 'should format hash' do
        result = task.send(:close_issue_on_jira_data)
        JSON.parse(result).tap do |format|
          expect(format['transition']['id']).to eq '12345'
        end
      end
    end

    describe '::close_jira' do
      let(:task) { build :task, jira_key: jira_key }

      let!(:account) { create :account, type: '--jira' }
      let!(:jira_key) { 'OK-1' }
      let(:faraday) { double('Faraday', post: response) }
      let(:response) { double('Faraday', body: JIRA_ISSUE_CREATION_RESPONSE, status: status, reason_phrase: reason_phrase) }
      let(:status) { 200 }
      let(:reason_phrase) { 'OK' }

      before { allow(Faraday).to receive(:new).and_return faraday }

      context 'no internet connection' do
        before do
          allow(faraday).to receive(:post).and_raise Faraday::ConnectionFailed, [404]
          allow(faraday).to receive(:get).and_raise Faraday::ConnectionFailed, [404]
          allow(faraday).to receive(:put).and_raise Faraday::ConnectionFailed, [404]
        end

        it 'should give the no connection error' do
          expect(STDOUT).to receive(:puts).with /Connection failed. Performing the task without requests to Jira./
          task.close_jira
        end
      end

      describe 'error codes', :unstub_jira_starting do
        before do
          allow(faraday).to receive(:post).and_return response
          allow(faraday).to receive(:get).and_return response
          allow(faraday).to receive(:put).and_return response
        end

        context 'server gave "unouthorized" error' do
          let(:status) { 401 }
          let(:reason_phrase) { 'unauthorized' }

          it 'should say it could not start' do
            expect(STDOUT).to receive(:puts).with /No access/
            task.close_jira
          end
        end

        context 'server gave "unouthorized" error' do
          let(:status) { 403 }
          let(:reason_phrase) { 'unauthorized' }

          it 'should say it could not start' do
            expect(STDOUT).to receive(:puts).with /No access/
            task.close_jira
          end
        end

        context 'server gave "not found" error' do
          let(:status) { 404 }
          let(:reason_phrase) { 'not found' }

          it 'should say it could not start' do
            expect(STDOUT).to receive(:puts).with /not found/
            task.close_jira
          end
        end

        context 'server gave "unknown" error' do
          let(:status) { 500 }
          let(:reason_phrase) { 'server error' }

          it 'should say it could not finish' do
            expect(STDOUT).to receive(:puts).with /Could not/
            expect(STDOUT).to receive(:puts).with /500/
            expect(STDOUT).to receive(:puts).with /server error/
            task.close_jira
          end
        end
      end
    end

    describe '#log_work_to_jira_data' do
      let!(:task) { create :task, comment: 'some comment' }

      it 'should format hash' do
        allow(task).to receive(:current_time).and_return 'time'
        allow(task).to receive(:time_spent).and_return 'spent'
        result = task.send(:log_work_to_jira_data)

        JSON.parse(result).tap do |format|
          expect(format['comment']).to eq 'some comment'
          expect(format['started']).to eq 'time'
          expect(format['timeSpent']).to eq 'spent'
        end
      end
    end

    describe '#create_jira_worklog' do
      let(:task) { build :task, jira_key: jira_key }

      context 'no internet connection' do
        let!(:account) { create :account, type: '--jira' }
        let(:jira_key) { 'OK-1' }
        let(:faraday) { double('Faraday', post: response) }
        let(:response) { double('Faraday', body: JIRA_ISSUE_CREATION_RESPONSE, status: 200) }

        before do
          allow(Faraday).to receive(:new).and_return faraday
          allow(faraday).to receive(:post).and_raise Faraday::ConnectionFailed, [404]
          allow(faraday).to receive(:get).and_raise Faraday::ConnectionFailed, [404]
          allow(faraday).to receive(:put).and_raise Faraday::ConnectionFailed, [404]
        end

        it 'should give the no connection error', :unstub_jira_starting do
          task.save
          expect(STDOUT).to receive(:puts).with /Connection failed. Performing the task without requests to Jira./
          task.create_jira_worklog
        end
      end

      describe 'errors', :unstub_jira_starting do
        let!(:account) { create :account, type: '--jira' }
        let(:jira_key) { 'OK-1' }
        let(:faraday) { double('Faraday', post: response) }
        let(:response) { double('Faraday', body: JIRA_ISSUE_CREATION_RESPONSE, status: status, reason_phrase: reason_phrase) }
        let(:status) { 200 }
        let(:reason_phrase) { 'OK' }

        before do
          allow(Faraday).to receive(:new).and_return faraday
          allow(faraday).to receive(:post).and_return response
          allow(faraday).to receive(:get).and_return response
          allow(faraday).to receive(:put).and_return response
        end

        context 'server gave the "unauth" error' do
          let(:status) { 401 }
          let(:reason_phrase) { 'unauth' }

          it 'should give the "unauth" error' do
            task.save
            expect(STDOUT).to receive(:puts).with /No access/
            task.create_jira_worklog
          end
        end

        context 'server gave the "unauth" error' do
          let(:status) { 403 }
          let(:reason_phrase) { 'unauth' }

          it 'should give the "unauth" error' do
            task.save
            expect(STDOUT).to receive(:puts).with /No access/
            task.create_jira_worklog
          end
        end

        context 'server gave the "not found" error' do
          let(:status) { 404 }
          let(:reason_phrase) { 'not found' }

          it 'should give the "unauth" error' do
            task.save
            expect(STDOUT).to receive(:puts).with /not found/
            task.create_jira_worklog
          end
        end

        context 'server gave the "unknown" error' do
          let(:status) { 500 }
          let(:reason_phrase) { 'unknown' }

          it 'should give the "unknown" error' do
            task.save
            expect(STDOUT).to receive(:puts).with /Could not/
            expect(STDOUT).to receive(:puts).with /500/
            expect(STDOUT).to receive(:puts).with /unknown/
            task.create_jira_worklog
          end
        end
      end
    end

    describe '#create_issue_on_pivotal_data' do
      let!(:task) { create :task, title: 'dupis', description: 'bamis', project: project, pivotal_estimate: estimate }

      context 'estimate is present' do
        let(:estimate) { 5 }

        it 'should format hash' do
          allow(task).to receive(:story_type).and_return 'chore'
          result = task.send(:create_issue_on_pivotal_data)
          JSON.parse(result).tap do |format|
            expect(format['current_state']).to eq 'unstarted'
            expect(format['estimate']).to eq 5
            expect(format['name']).to eq 'dupis'
            expect(format['description']).to eq 'bamis'
            expect(format['story_type']).to eq 'chore'
          end
        end
      end

      context 'estimate is not present' do
        let(:estimate) { 0 }

        it 'should format hash' do
          allow(task).to receive(:story_type).and_return 'chore'
          result = task.send(:create_issue_on_pivotal_data)
          JSON.parse(result).tap do |format|
            expect(format['current_state']).to eq 'unstarted'
            expect(format['estimate']).to eq 1
            expect(format['name']).to eq 'dupis'
            expect(format['story_type']).to eq 'chore'
          end
        end
      end
    end

    describe '#finish_on_pivotal_data' do
      let!(:task) { create :task }

      it 'should format hash' do
        allow(task).to receive(:story_type).and_return 'chore'
        result = task.send(:finish_on_pivotal_data)
        JSON.parse(result).tap do |format|
          expect(format['current_state']).to eq 'finished'
        end
      end
    end

    describe '#finish_pivotal' do
      let(:task) { build :task, pivotal_id: pivotal_id }
      let(:pivotal_id) { '12345678' }
      let!(:account) { create :account, type: '--pivotal' }
      let(:faraday) { double('Faraday', post: response) }
      let(:response) { double('Faraday', body: PIVOTAL_ISSUE_CREATION_RESPONSE, status: status, reason_phrase: reason_phrase) }
      let(:status) { 200 }
      let(:reason_phrase) { 'OK' }

      before { allow(Faraday).to receive(:new).and_return faraday }

      context 'pt id present, pt account present, no internet connection' do
        before do
          allow(faraday).to receive(:post).and_raise Faraday::ConnectionFailed, [404]
          allow(faraday).to receive(:get).and_raise Faraday::ConnectionFailed, [404]
          allow(faraday).to receive(:put).and_raise Faraday::ConnectionFailed, [404]
        end

        it 'should give the no connection error', :unstub_pivotal_starting do
          expect(STDOUT).to receive(:puts).with /Connection failed. Performing the task without requests to Pivotal./
          task.finish_pivotal
        end
      end

      describe 'error codes', :unstub_pivotal_starting do
        before do
          allow(faraday).to receive(:post).and_return response
          allow(faraday).to receive(:get).and_return response
          allow(faraday).to receive(:put).and_return response
        end

        context 'pt id present, pt account present, "unauthorized" server error' do
          let(:status) { 401 }
          let(:reason_phrase) { 'unauth' }

          it 'should give the no auth error' do
            expect(STDOUT).to receive(:puts).with /No access/
            task.finish_pivotal
          end
        end

        context 'pt id present, pt account present, "unauthorized" server error' do
          let(:status) { 403 }
          let(:reason_phrase) { 'unauth' }

          it 'should give the no auth error' do
            expect(STDOUT).to receive(:puts).with /No access/
            task.finish_pivotal
          end
        end

        context 'pt id present, pt account present, "not found" server error' do
          let(:status) { 404 }
          let(:reason_phrase) { 'not found' }

          it 'should give the not found error' do
            expect(STDOUT).to receive(:puts).with /not found/
            task.finish_pivotal
          end
        end

        context 'pt id present, pt account present, "unknown" server error' do
          let(:status) { 500 }
          let(:reason_phrase) { 'error' }

          it 'should give the error' do
            expect(STDOUT).to receive(:puts).with /Could not/
            expect(STDOUT).to receive(:puts).with /500/
            expect(STDOUT).to receive(:puts).with /error/
            task.finish_pivotal
          end
        end
      end
    end

    describe '#start_issue_on_pivotal_data' do
      let!(:task) { create :task }

      it 'should format hash' do
        allow(task).to receive(:story_type).and_return 'chore'
        result = task.send(:start_issue_on_pivotal_data)
        JSON.parse(result).tap do |format|
          expect(format['current_state']).to eq 'started'
        end
      end
    end

    describe '#current_time' do
      let!(:task) { create :task, project: project }
      let!(:time) { Time.parse('5 April 2014') }

      it 'should format time' do
        allow(Time).to receive_message_chain(:now, :in_time_zone).and_return time
        result = task.send(:current_time)
        expect(result).to eq '2014-04-05T00:00:00.000+0000'
      end
    end

    describe '#time_spent' do
      let!(:task) { create :task, project: project }
      let!(:start_time) { Time.parse('5 April 2014 1:30PM') }
      let!(:finish_time) { Time.parse('5 April 2014 2:45PM') }

      it 'should return formatted time difference' do
        expect(task).to receive(:started_at).and_return start_time
        expect(task).to receive(:finished_at).and_return finish_time
        result = task.time_spent
        expect(result).to eq '1h 15m'
      end
    end
  end
end
