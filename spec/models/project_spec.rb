# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RSpec.describe Project, type: :model do
  it { expect(subject).to have_many :branches }
  it { expect(subject).to have_many :chores }
  it { expect(subject).to have_many :bugs }
  it { expect(subject).to have_many :features }
  it { expect(subject).to have_many :meetings }
end
