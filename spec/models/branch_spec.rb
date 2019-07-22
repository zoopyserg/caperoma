# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RSpec.describe Branch, type: :model do
  it { expect(subject).to belong_to :project }
  it { expect(subject).to have_many :tasks }
end
