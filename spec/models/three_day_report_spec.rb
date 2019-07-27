# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RSpec.describe ThreeDayReport, type: :model do
  describe 'relations' do
    it { expect(subject).to have_many :tasks }
  end

  describe 'callbacks' do
    describe '::asskgn_unreported_tasks' do
      let!(:daily_report1) { create :daily_report }
      let!(:three_day_report1) { create :three_day_report }

      let!(:task1) { create :task, daily_report: daily_report1, three_day_report: nil, finished_at: Time.now }
      let!(:task2) { create :task, daily_report: daily_report1, three_day_report: three_day_report1, finished_at: Time.now }
      let!(:task3) { create :task, daily_report: nil, three_day_report: nil, finished_at: Time.now }
      let!(:task4) { create :task, daily_report: nil, three_day_report: nil, finished_at: nil }

      specify do
        new_report = create :three_day_report
        expect(new_report.tasks).to match_array [task1, task3]
      end
    end
  end

  describe 'message format' do
    describe 'subject' do
      let(:report) { create :three_day_report }

      specify do
        Timecop.freeze(Time.parse('06/02/2015 15:06')) do
          expect(report.send(:report_subject)).to eq 'Three Day Report (Feb 4 - Feb 6)'
        end
      end
    end

    describe 'message body', :unstub_puts do
      let(:report) { create :three_day_report }
      let!(:task1) { create :task, jira_key: 'DOV-2', pivotal_id: 2_345_678, three_day_report: nil, finished_at: 2.days.ago }
      let!(:task2) { create :task, jira_key: 'MOB-8', pivotal_id: 2_345_674, three_day_report: nil, finished_at: 1.day.ago }

      specify do
        expect(report.send(:report_body)).to match /table/
      end
    end
  end
end
