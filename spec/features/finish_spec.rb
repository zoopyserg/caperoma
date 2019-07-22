# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
ENV['spec_type'] = 'feature'

describe 'Finish' do
  let!(:account) { create :account }
  let!(:project) { create :project }
  let!(:task) { create :task, project: project, finished_at: nil }

  it 'finishes started task' do
    expect do
      `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma finish`
    end.to change {
      Task.unfinished.count
    }.by(-1)
  end
end
