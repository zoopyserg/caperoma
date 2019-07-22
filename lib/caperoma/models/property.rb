# frozen_string_literal: true

class Property < ApplicationRecord
  validates :name, :value, presence: true
end
