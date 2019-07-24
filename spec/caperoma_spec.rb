# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Caperoma do
  let!(:project) { create :project, jira_project_id: '123' }

  before { create_capefile('123') }

  describe 'create tasks' do
    context 'title present' do
      let!(:args) { ['bug', '-t', 'awesome bug', '-d', 'some description'] }

      it 'should create' do
        expect do
          Caperoma.create_task(args)
        end.to change {
          Bug.where(
            title: 'awesome bug',
            description: 'some description',
            project_id: project.id
          ).count
        }.by(1)
      end
    end

    context 'title not present but -p can get the title from pivotal', :unstab_api_calls do
      let!(:args) { ['bug', '-p', '1234567'] }

      let(:response_body) { { 'name' => 'awesome bug', 'description' => 'some description' }.to_json }

      it 'should create' do
        faraday = spy('faraday')
        response = spy('response')

        allow(Faraday).to receive(:new).and_return faraday
        allow(Faraday).to receive(:default_adapter)
        allow(faraday).to receive(:get).and_return response
        allow(response).to receive(:body).and_return response_body
        allow(faraday).to receive(:post)
        allow(faraday).to receive(:put)

        expect do
          Caperoma.create_task(args)
        end.to change {
          Bug.where(
            title: 'awesome bug',
            description: 'some description',
            project_id: project.id
          ).count
        }.by(1)
      end
    end

    context 'title not present but -p can get the title from pivotal, but pivotal_id is set in #1234567 format (not just numbers)', :unstab_api_calls do
      let!(:args) { ['bug', '-p', '#1234567'] }

      let(:response_body) { { 'name' => 'awesome bug', 'description' => 'some description' }.to_json }

      it 'should create the same way as it does without #' do
        faraday = spy('faraday')
        response = spy('response')

        allow(Faraday).to receive(:new).and_return faraday
        allow(Faraday).to receive(:default_adapter)
        allow(faraday).to receive(:get).and_return response
        allow(response).to receive(:body).and_return response_body
        allow(faraday).to receive(:post)
        allow(faraday).to receive(:put)

        expect do
          Caperoma.create_task(args)
        end.to change {
          Bug.where(
            title: 'awesome bug',
            description: 'some description',
            project_id: project.id
          ).count
        }.by(1)
      end
    end

  end
end
