# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
ENV['spec_type'] = 'feature'

describe 'Command unknown' do
  let!(:project) { create :project }

  it 'submits a chore' do
    result = `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma boogie woogie`
    expect(result).to match /Available commands/
  end
end
