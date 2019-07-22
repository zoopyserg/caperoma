# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RSpec.describe ReportRecipient, type: :model do
  describe 'validations' do
    specify do
      ['me@gmail.com', 'dude.due@gmail.com'].each do |value|
        expect(subject).to allow_value(value).for(:email)
      end
    end

    specify do
      ['12345', '', nil].each do |value|
        expect(subject).not_to allow_value(value).for(:email)
      end
    end

    it { expect(subject).to validate_uniqueness_of(:email) }
    it { expect(subject).to validate_presence_of(:email) }
  end
end
