# frozen_string_literal: true

class Account < ApplicationRecord
  self.inheritance_column = nil

  validates :email, presence: true
  validates :password, presence: true
  validates :type, presence: true, inclusion: { in: %w[--jira --pivotal --gmail --git --caperoma] }

  before_create :destroy_others
  before_create :inform_creation_started
  after_create :inform_creation_finished

  def self.caperoma
    where(type: '--caperoma').first
  end

  def self.jira
    where(type: '--jira').first
  end

  def self.pivotal
    where(type: '--pivotal').first
  end

  def self.gmail
    where(type: '--gmail').first
  end

  def self.git
    where(type: '--git').first
  end

  private

  def destroy_others
    Account.where(type: type).destroy_all
  end

  def inform_creation_started
    puts 'Saving credentials'
  end

  def inform_creation_finished
    puts 'Credentials saved'
  end
end
