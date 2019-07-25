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

    context 'title present and additional time present' do
      let!(:args) { ['bug', '-t', 'awesome bug', '-a', '5'] }

      it 'should create' do
        expect do
          Caperoma.create_task(args)
        end.to change {
          Bug.where(
            title: 'awesome bug',
            project_id: project.id,
            additional_time: 5
          ).count
        }.by(1)
      end
    end

    context 'title present but additional time is invalid' do
      let!(:args) { ['bug', '-t', 'awesome bug', '-a', 'gsov'] }

      it 'should not create' do
        expect do
          Caperoma.create_task(args)
        end.to change {
          Bug.where(
            title: 'awesome bug',
            project_id: project.id
          ).count
        }.by(0)
      end

      it 'should say why it is not starting', :unstub_puts do
        expect(STDOUT).to receive(:puts).with /not_a_number/
        Caperoma.create_task(args)
      end
    end

    context 'title and pivotal id present but pivotal id is invalid' do
      let!(:args) { ['bug', '-t', 'awesome bug', '-p', 'sdklfvnslfkvs'] }

      it 'should create but skip pivotal id' do
        expect do
          Caperoma.create_task(args)
        end.to change {
          Bug.where(
            title: 'awesome bug',
            pivotal_id: nil,
            project_id: project.id
          ).count
        }.by(1)
      end

      it 'should say why it is skipping', :unstub_puts do
        expect(STDOUT).to receive(:puts).with /Pivotal ID needs to be copied from the task in Pivotal/
        allow(STDOUT).to receive(:puts)
        Caperoma.create_task(args)
      end
    end

    context 'title not present but -p can get the title from pivotal', :unstab_api_calls do
      let!(:args) { ['bug', '-p', '1234567'] }

      let(:response_body) { { 'name' => 'awesome bug', 'description' => 'some description' }.to_json }

      it 'should create' do
        response = double('Faraday', body: response_body, status: 200)
        faraday = double('Faraday', post: response)

        allow(Faraday).to receive(:new).and_return faraday
        allow(Faraday).to receive(:default_adapter)

        allow(faraday).to receive(:post).and_return response
        allow(faraday).to receive(:get).and_return response
        allow(faraday).to receive(:put).and_return response

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

    context 'title not present, -p present, but pivotal gave an error', :unstab_api_calls do
      let!(:args) { ['bug', '-p', '1234567'] }

      let(:response_body) { { 'name' => 'awesome bug', 'description' => 'some description' }.to_json }

      before do
        response = double('Faraday', body: response_body, status: 401)
        faraday = double('Faraday', post: response)

        allow(Faraday).to receive(:new).and_return faraday
        allow(Faraday).to receive(:default_adapter)

        allow(faraday).to receive(:post).and_return response
        allow(faraday).to receive(:get).and_return response
        allow(faraday).to receive(:put).and_return response
      end

      it 'should not create' do
        expect do
          Caperoma.create_task(args)
        end.to change {
          Bug.where(
            title: 'awesome bug',
            description: 'some description',
            project_id: project.id
          ).count
        }.by(0)
      end

      it 'should say it could not get access' do
        expect(STDOUT).to receive(:puts).with /No access/
        Caperoma.create_task(args)
      end
    end

    context 'title not present but -p can get the title from pivotal, but pivotal_id is set in #1234567 format (not just numbers)', :unstab_api_calls do
      let!(:args) { ['bug', '-p', '#1234567'] }

      let(:response_body) { { 'name' => 'awesome bug', 'description' => 'some description' }.to_json }

      it 'should create the same way as it does without #' do
        response = double('Faraday', body: response_body, status: 200)
        faraday = double('Faraday', post: response)

        allow(Faraday).to receive(:new).and_return faraday
        allow(Faraday).to receive(:default_adapter)

        allow(faraday).to receive(:post).and_return response
        allow(faraday).to receive(:get).and_return response
        allow(faraday).to receive(:put).and_return response

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
