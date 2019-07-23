# frozen_string_literal: true

class TaskWithCommit < Task
  belongs_to :branch

  def finish(comment)
    super
    git_commit(commit_message)
    # here I should pass the path
    `rubocop -a "#{project.folder_path}"` if ENV['CAPEROMA_INTEGRATION_TEST'].blank? && ENV['CAPEROMA_TEST'].blank?
    git_commit(commit_rubocop_message)
    git_push
  end

  def pause(comment)
    super
    git_commit(commit_message)
    `rubocop -a "#{project.folder_path}"` if ENV['CAPEROMA_INTEGRATION_TEST'].blank? && ENV['CAPEROMA_TEST'].blank?
    git_commit(commit_rubocop_message)
    git_push
  end

  private

  def commit_message
    # E.g.: [RUC-123][#1345231] Some Subject
    string = ''
    string += "[#{jira_key}]" if jira_key.present?
    string += "[##{pivotal_id}]" if pivotal_id.present?
    string += " #{title}"
    string.strip
  end

  def commit_rubocop_message
    string = ''
    string += "[#{jira_key}]" if jira_key.present?
    string += "[##{pivotal_id}]" if pivotal_id.present?
    string += ' Applying good practices'
    string.strip
  end
end
