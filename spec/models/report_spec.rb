# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RSpec.describe Report, type: :model do
  describe '#to_addresses' do
    let!(:recipient1) { create :report_recipient, email: 'dude1@example.com' }
    let!(:recipient2) { create :report_recipient, email: 'dude2@example.com' }

    let!(:report) { build :report }

    specify do
      expect(report.send(:to_addresses)).to match_array ['dude1@example.com', 'dude2@example.com']
    end
  end
end
