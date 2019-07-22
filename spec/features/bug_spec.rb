# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
ENV['spec_type'] = 'feature'

describe 'Bug' do
  let!(:project) { create :project, jira_project_id: '123' }

  before { create_capefile('123') }

  context 'pivotal id blank' do
    it 'submits a bug' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma bug -t "awesome bug" -d "some description" `
      end.to change {
        Bug.where(
          title: 'awesome bug',
          description: 'some description',
          project_id: project.id
        ).count
      }.by(1)
    end
  end

  context 'pivotal id present' do
    it 'submits a bug' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma bug --title "awesome bug" --description "some description" -ptid 12345678`
      end.to change {
        Bug.where(
          title: 'awesome bug',
          description: 'some description',
          project_id: project.id,
          pivotal_id: '12345678'
        ).count
      }.by(1)
    end
  end

  context 'pivotal id and additional_time present', :unstub_time_now do
    it 'submits a bug' do
      expect do
        `CAPEROMA_INTEGRATION_TEST=true ruby -I./lib bin/caperoma bug -t "awesome bug" -d "some description" -ptid 12345678 -a 23`
      end.to change {
        Bug.where(
          title: 'awesome bug',
          description: 'some description',
          project_id: project.id,
          pivotal_id: '12345678'
        ).count
      }.by(1)

      time = Time.now
      created = Bug.first.started_at
      time_difference = TimeDifference.between(time, created).in_minutes.to_i

      expect(time_difference).to eq 23
    end
  end
end
