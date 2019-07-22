# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
ENV['spec_type'] = 'feature'

describe 'Config' do
  describe 'adding accounts' do
    it 'saves Jira account using -a flag' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma accounts -a --jira "email@example.com" "password123"`
      end.to change {
        Account.where(
          email: 'email@example.com',
          password: 'password123',
          type: '--jira'
        ).count
      }.by(1)
    end

    it 'saves Jira account using add flag' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma accounts add --jira "email@example.com" "password123"`
      end.to change {
        Account.where(
          email: 'email@example.com',
          password: 'password123',
          type: '--jira'
        ).count
      }.by(1)
    end

    it 'saves Jira account using --add flag' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma accounts --add --jira "email@example.com" "password123"`
      end.to change {
        Account.where(
          email: 'email@example.com',
          password: 'password123',
          type: '--jira'
        ).count
      }.by(1)
    end

    it 'saves Jira account using -c flag' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma accounts -c --jira "email@example.com" "password123"`
      end.to change {
        Account.where(
          email: 'email@example.com',
          password: 'password123',
          type: '--jira'
        ).count
      }.by(1)
    end

    it 'saves Jira account using create flag' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma accounts create --jira "email@example.com" "password123"`
      end.to change {
        Account.where(
          email: 'email@example.com',
          password: 'password123',
          type: '--jira'
        ).count
      }.by(1)
    end

    it 'saves Jira account using --create flag' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma accounts --create --jira "email@example.com" "password123"`
      end.to change {
        Account.where(
          email: 'email@example.com',
          password: 'password123',
          type: '--jira'
        ).count
      }.by(1)
    end
  end

  describe 'removing accounts' do
    let!(:account) { create :account, type: '--jira' }

    it 'removes Jira account using -r flag' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma accounts -r --jira`
      end.to change {
        Account.where(
          type: '--jira'
        ).count
      }.by(-1)
    end

    it 'saves Jira account using remove command' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma accounts remove --jira`
      end.to change {
        Account.where(
          type: '--jira'
        ).count
      }.by(-1)
    end

    it 'saves Jira account using --remove command' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma accounts --remove --jira`
      end.to change {
        Account.where(
          type: '--jira'
        ).count
      }.by(-1)
    end

    it 'removes Jira account using -d flag' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma accounts -d --jira`
      end.to change {
        Account.where(
          type: '--jira'
        ).count
      }.by(-1)
    end

    it 'saves Jira account using delete command' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma accounts delete --jira`
      end.to change {
        Account.where(
          type: '--jira'
        ).count
      }.by(-1)
    end

    it 'saves Jira account using --delete command' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma accounts --delete --jira`
      end.to change {
        Account.where(
          type: '--jira'
        ).count
      }.by(-1)
    end
  end

  describe 'listing' do
    let!(:account1) { create :account, type: '--jira', email: 'one@gmail.com' }
    let!(:account2) { create :account, type: '--git', email: 'two@gmail.com' }
    let!(:account3) { create :account, type: '--pivotal', email: 'three@gmail.com' }
    let!(:account4) { create :account, type: '--gmail', email: 'four@gmail.com' }
    let!(:account5) { create :account, type: '--caperoma', email: 'five@gmail.com' }

    it 'should list the accounts' do
      result = `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma accounts`
      expect(result).to match /Jira: one@gmail.com/
      expect(result).to match /Git: two@gmail.com/
      expect(result).to match /Pivotal: three@gmail.com/
      expect(result).to match /Gmail: four@gmail.com/
      expect(result).to match /Caperoma: five@gmail.com/
    end
  end
end
