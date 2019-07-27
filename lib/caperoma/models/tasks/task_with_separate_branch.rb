# frozen_string_literal: true

class TaskWithSeparateBranch < TaskWithCommit
  before_create :update_parent_branch
  before_create :remember_parent_branch
  after_create :set_branch
  after_create :git_branch

  def finish(comment)
    puts comment
    super
    puts git_pull_request
    puts git_checkout(parent_branch)
  end

  def abort(comment)
    super
    puts git_checkout(parent_branch)
  end

  private

  def description_for_pull_request
    pivotal_url
  end

  def update_parent_branch
    git_rebase_to_upstream
  end

  def remember_parent_branch
    self.parent_branch = git_current_branch
  end

  def set_branch
    update_column :branch, branch_name
  end

  def branch_name
    # E.g.: ruc-123-first-three-four-words
    result = [jira_key, title[0, 25]].join(' ')
    ActiveSupport::Inflector.parameterize(result)
  end
end
