# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
ENV['spec_type'] = 'feature'

describe 'Report' do
  describe 'Daily Report' do
    it 'creates daily report' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma report daily`
      end.to change {
        DailyReport.count
      }.by(1)
    end

    it 'creates daily report' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma report -d`
      end.to change {
        DailyReport.count
      }.by(1)
    end
  end

  describe 'Three Day Report' do
    it 'creates three day report' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma report three_day`
      end.to change {
        ThreeDayReport.count
      }.by(1)
    end

    it 'creates three day report' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma report -t`
      end.to change {
        ThreeDayReport.count
      }.by(1)
    end
  end

  describe 'Weekly Report' do
    it 'creates weekly report' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma report weekly`
      end.to change {
        RetrospectiveReport.count
      }.by(1)
    end

    it 'creates weekly report' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma report -w`
      end.to change {
        RetrospectiveReport.count
      }.by(1)
    end
  end

  describe 'auto' do
    xit 'on'
    xit 'off'
  end
end
