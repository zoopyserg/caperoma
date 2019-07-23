# frozen_string_literal: true

class Project < ApplicationRecord
  has_many :branches
  has_many :chores
  has_many :bugs
  has_many :features
  has_many :meetings
  has_many :fixes

  def folder_path
    (self[:folder_path]).to_s
  end
end
