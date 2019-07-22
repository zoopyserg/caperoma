# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
ENV['spec_type'] = 'feature'

describe 'version' do
  it 'outputs the current version' do
    result = `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma -v`
    expect(result).to start_with '4'
  end
end
