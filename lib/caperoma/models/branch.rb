# frozen_string_literal: true

class Branch < ActiveRecord::Base
  belongs_to :project
  has_many :tasks
end
