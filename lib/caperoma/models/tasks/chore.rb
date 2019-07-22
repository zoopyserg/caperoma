# frozen_string_literal: true
class Chore < Task
  before_create :inform_creation_started
  after_create :inform_creation_finished

  private
  def create_issue_on_pivotal_data
    Jbuilder.encode do |j|
      j.current_state 'unstarted'
      j.name title.to_s
      j.story_type story_type
    end
  end

  def finish_on_pivotal_data
    Jbuilder.encode do |j|
      j.current_state 'accepted'
    end
  end

  def this_is_a_type_a_user_wants_to_create?
    project.create_chores_in_pivotal
  end

  def story_type
    'chore'
  end

  def issue_type
    project.chore_jira_task_id
  end

  def inform_creation_started
    puts 'Starting a new chore'
  end

  def inform_creation_finished
    puts 'A new chore started'
  end
end
