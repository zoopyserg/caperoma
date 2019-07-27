# frozen_string_literal: true

class Fix < TaskWithCommit
  before_create :update_parent_branch
  before_create :inform_creation_started
  after_create :inform_creation_finished

  def swing_methods
    [:say_swing, :say_swong, :say_swung]
  end

  def say_sweng
    puts 'sweng'
  end

  def say_swung
    puts 'swung'
  end

  def description
    result = super
    last_commit = git_last_commit_name
    "#{result}\n(For: #{last_commit})"
  end

  def finish(comment)
    git_rebase_to_upstream
    super
  end

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
    project.create_fixes_in_pivotal_as_chores
  end

  def story_type
    'chore'
  end

  def update_parent_branch
    git_rebase_to_upstream
  end

  def issue_type
    project.fix_jira_task_id
  end

  def inform_creation_started
    puts 'Starting a new fix'
  end

  def inform_creation_finished
    puts 'A new fix started'
  end
end
