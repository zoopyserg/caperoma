# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RSpec.describe Account, type: :model do
  describe 'validations' do
    it { expect(subject).to validate_presence_of(:email) }
    it { expect(subject).to validate_presence_of(:password) }
    # TODO: validate username for jira only (use STI)
    it { expect(subject).to validate_presence_of(:type) }
    it { expect(subject).to validate_inclusion_of(:type).in_array(%w[--jira --gmail --caperoma --pivotal --git]) }
  end

  describe 'class methods' do
    let!(:caperoma) { create :account, type: '--caperoma' }
    let!(:gmail) { create :account, type: '--gmail' }
    let!(:jira) { create :account, type: '--jira' }
    let!(:pivotal) { create :account, type: '--pivotal' }
    let!(:git) { create :account, type: '--git' }

    specify '::caperoma' do
      expect(Account.caperoma).to eq caperoma
    end

    specify '::gmail' do
      expect(Account.gmail).to eq gmail
    end

    specify '::jira' do
      expect(Account.jira).to eq jira
    end

    specify '::pivotal' do
      expect(Account.pivotal).to eq pivotal
    end

    specify '::git' do
      expect(Account.git).to eq git
    end
  end

  describe 'observers' do
    it 'should overwrite accounts of same type' do
      create :account, type: '--jira'
      create :account, type: '--jira', email: 'new-email@example.com'

      expect(Account.count).to eq 1
      expect(Account.first.email).to eq 'new-email@example.com'
    end
  end
end
