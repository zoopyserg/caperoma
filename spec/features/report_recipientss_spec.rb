# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
ENV['spec_type'] = 'feature'

describe 'Report' do
  describe 'Add' do
    it 'flag creates report recipient' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma recipients -a dude@example.com`
      end.to change {
        ReportRecipient.where(email: 'dude@example.com').count
      }.by(1)
    end

    it 'command creates report recipient' do
      expect  do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma recipients add dude@example.com`
      end.to change {
        ReportRecipient.where(email: 'dude@example.com').count
      }.by(1)
    end

    it 'command creates report recipient' do
      expect  do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma recipients --add dude@example.com`
      end.to change {
        ReportRecipient.where(email: 'dude@example.com').count
      }.by(1)
    end

    it 'flag creates report recipient' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma recipients -c dude@example.com`
      end.to change {
        ReportRecipient.where(email: 'dude@example.com').count
      }.by(1)
    end

    it 'command creates report recipient' do
      expect  do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma recipients create dude@example.com`
      end.to change {
        ReportRecipient.where(email: 'dude@example.com').count
      }.by(1)
    end

    it 'command creates report recipient' do
      expect  do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma recipients --create dude@example.com`
      end.to change {
        ReportRecipient.where(email: 'dude@example.com').count
      }.by(1)
    end
  end

  describe 'Destroy' do
    let!(:recipient) { create :report_recipient, email: 'dude@example.com' }

    it 'flag removes recipient' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma recipients -r dude@example.com`
      end.to change {
        ReportRecipient.where(email: 'dude@example.com').count
      }.by(-1)
    end

    it 'command removes recipient' do
      expect  do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma recipients remove dude@example.com`
      end.to change {
        ReportRecipient.where(email: 'dude@example.com').count
      }.by(-1)
    end

    it 'command removes recipient' do
      expect  do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma recipients --remove dude@example.com`
      end.to change {
        ReportRecipient.where(email: 'dude@example.com').count
      }.by(-1)
    end

    it 'flag removes recipient' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma recipients -d dude@example.com`
      end.to change {
        ReportRecipient.where(email: 'dude@example.com').count
      }.by(-1)
    end

    it 'command removes recipient' do
      expect  do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma recipients delete dude@example.com`
      end.to change {
        ReportRecipient.where(email: 'dude@example.com').count
      }.by(-1)
    end

    it 'command removes recipient' do
      expect  do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma recipients --delete dude@example.com`
      end.to change {
        ReportRecipient.where(email: 'dude@example.com').count
      }.by(-1)
    end
  end

  describe 'List' do
    let!(:recipient) { create :report_recipient, email: 'dude@example.com' }

    it 'removes recipient' do
      result =  `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma recipients`
      expect(result).to match /dude/
    end
  end
end
