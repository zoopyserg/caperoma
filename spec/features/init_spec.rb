# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
ENV['spec_type'] = 'feature'

describe 'Init' do
  context 'project not set up' do
    before { remove_capefile }

    it 'should say Capefile is created' do
      result = `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma init`
      expect(result).to match /Capefile successfully created/
    end

    it 'should create Capefile' do
      result = `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma init`
      expect(File).to exist 'Capefile.test'
    end
  end
end
