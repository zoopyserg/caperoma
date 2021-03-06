# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
ENV['spec_type'] = 'feature'

describe 'Fix' do
  let!(:project) { create :project, jira_project_id: '123' }

  before { create_capefile('123') }

  context 'pivotal id blank' do
    it 'submits a fix' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma fix -t "awesome work" -d "some description" -ptid 12345678`
      end.to change {
        Fix.where(
          title: 'awesome work',
          description: 'some description',
          project_id: project.id
        ).count
      }.by(1)
    end
  end

  context 'pivotal id present' do
    it 'submits a fix' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma fix -t "awesome work" -d "some description" -ptid 12345678`
      end.to change {
        Fix.where(
          title: 'awesome work',
          description: 'some description',
          project_id: project.id,
          pivotal_id: '12345678'
        ).count
      }.by(1)
    end
  end

  context 'pivotal id present, additional_time present', :unstub_time_now do
    it 'submits a fix' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma fix -t "awesome work" -d "some description" -p 12345678 -a 23`
      end.to change {
        Fix.where(
          title: 'awesome work',
          description: 'some description',
          project_id: project.id,
          pivotal_id: '12345678'
        ).count
      }.by(1)

      time = Time.now
      created = Fix.first.started_at
      time_difference = TimeDifference.between(time, created).in_minutes

      expect(time_difference).to eq 23
    end
  end
end
