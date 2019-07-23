# frozen_string_literal: true

class Feature < TaskWithSeparateBranch
  before_create :inform_creation_started
  after_create :inform_creation_finished

  private

  def this_is_a_type_a_user_wants_to_create?
    project.create_features_in_pivotal
  end

  def story_type
    'feature'
  end

  def issue_type
    project.feature_jira_task_id
  end

  def inform_creation_started
    puts 'Starting a new feature'
  end

  def inform_creation_finished
    puts 'A new feature started'
  end
end
