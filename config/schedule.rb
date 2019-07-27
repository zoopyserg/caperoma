# frozen_string_literal: true

set :job_template, nil

every :weekday, at: '5:00pm' do
  command 'caperoma report daily'
end

every :wednesday, at: '5:05pm' do
  command 'caperoma report three_day'
end

every :friday, at: '5:05pm' do
  command 'caperoma report three_day'
end

every :friday, at: '5:10pm' do
  command 'caperoma report weekly'
end
