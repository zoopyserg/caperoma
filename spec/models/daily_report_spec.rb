# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RSpec.describe DailyReport, type: :model do
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
        new_report = create :daily_report
        expect(new_report.tasks).to match_array [task3]
      end
    end
  end

  describe 'message format' do
    describe 'subject' do
      let(:report) { create :daily_report }

      specify do
        Timecop.freeze(Time.parse('06/02/2015 15:06')) do
          expect(report.send(:report_subject)).to eq 'Daily Report (Feb 6)'
        end
      end
    end
  end
end
