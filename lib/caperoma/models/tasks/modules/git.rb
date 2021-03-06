# frozen_string_literal: true

module Git
  def git_branch
    `git -C "#{project.folder_path}" checkout -b #{branch}` if enable_git?
  end

  def git_commit(msg)
    `git -C "#{project.folder_path}" add -A && git -C "#{project.folder_path}" commit --allow-empty -m "#{msg}"` if enable_git?
  end

  def git_push
    if enable_git?
      puts 'Pushing the code to Github'

      conn = Faraday.new(url: 'https://api.github.com') do |c|
        c.basic_auth(Account.git.email, Account.git.password)
        c.adapter Faraday.default_adapter
      end

      response = conn.get do |request|
        request.url "/repos/#{project.github_repo}/pulls"
        request.headers['User-Agent'] = 'Caperoma'
        request.headers['Accept'] = 'application/vnd.github.v3+json'
        request.headers['Content-Type'] = 'application/json'
      end

      case response.status
      when 200, 201, 202, 204, 301, 302, 303, 304, 307
        `git -C "#{project.folder_path}" push --set-upstream origin #{git_current_branch}`
      when 401, 403
        puts 'No access to Git. Maybe login or password are incorrect.'
      when 404
        puts "A resource on Git was not found. Maybe the repository name #{project.github_repo} is incorrect."
      else
        puts 'Could not push to Git.'
        puts "Error status: #{response.status}"
        puts "Message from server: #{response.reason_phrase}"
      end
    end
  rescue Faraday::ConnectionFailed
    puts 'Connection failed. Performing the task without pushing to Git.'
  end

  def git_last_commit_name
    `git -C "#{project.folder_path}" log #{parent_branch}..#{branch} --oneline --pretty=format:'%s' --skip=1 -1` if enable_git?
  end

  def git_current_branch
    `git -C "#{project.folder_path}" rev-parse --abbrev-ref HEAD`.gsub("\n", '') if enable_git?
  end

  def git_pull_request
    puts 'Making a pull request'

    pull_request_data = Jbuilder.encode do |j|
      j.title title
      j.body description_for_pull_request
      j.head branch
      j.base parent_branch
    end

    conn = Faraday.new(url: 'https://api.github.com') do |c|
      c.basic_auth(Account.git.email, Account.git.password)
      c.adapter Faraday.default_adapter
    end

    response = conn.post do |request|
      request.url "/repos/#{project.github_repo}/pulls"
      request.body = pull_request_data
      request.headers['User-Agent'] = 'Caperoma'
      request.headers['Accept'] = 'application/vnd.github.v3+json'
      request.headers['Content-Type'] = 'application/json'
    end

    case response.status
    when 200, 201, 202, 204, 301, 302, 303, 304, 307
      puts 'The pull request was sent.'
    when 401, 403
      puts 'No access to Git. Maybe login or password are incorrect.'
    when 404
      puts "A resource on Git not found. Maybe the repository name #{project.github_repo} is incorrect."
    else
      puts 'Could not make a pull request.'
      puts "Error status: #{response.status}"
      puts "Message from server: #{response.reason_phrase}"
    end
  rescue Faraday::ConnectionFailed
    puts 'Connection failed. Performing the task without requests to Git.'
  end

  def git_rebase_to_upstream
    if enable_git?
      has_untracked_files = !`git -C "#{project.folder_path}" ls-files --others --exclude-standard`.empty?
      has_changes = !`git -C "#{project.folder_path}" diff`.empty?
      has_staged_changes = !`git -C "#{project.folder_path}" diff HEAD`.empty?

      changes_were_made = has_untracked_files || has_changes || has_staged_changes

      `git -C "#{project.folder_path}" add -A && git -C "#{project.folder_path}" stash` if changes_were_made

      git_actual_rebase

      `git -C "#{project.folder_path}" stash apply` if changes_were_made
    end
  end

  def git_actual_rebase
    if enable_git?
      pp 'Getting the latest code from Github'

      conn = Faraday.new(url: 'https://api.github.com') do |c|
        c.basic_auth(Account.git.email, Account.git.password)
        c.adapter Faraday.default_adapter
      end

      response = conn.get do |request|
        request.url "/repos/#{project.github_repo}/pulls"
        request.headers['User-Agent'] = 'Caperoma'
        request.headers['Accept'] = 'application/vnd.github.v3+json'
        request.headers['Content-Type'] = 'application/json'
      end

      case response.status
      when 200, 201, 202, 204, 301, 302, 303, 304, 307
        `git -C "#{project.folder_path}" fetch && git -C "#{project.folder_path}" rebase $(git -C "#{project.folder_path}" rev-parse --abbrev-ref --symbolic-full-name @{u})`
      when 401, 403
        puts 'No access to Git. Maybe login or password are incorrect.'
      when 404
        puts "A resource on Git not found. Maybe the repository name #{project.github_repo} is incorrect."
      else
        puts 'Could not get the latest changes from Github.'
        puts "Error status: #{response.status}"
        puts "Message from server: #{response.reason_phrase}"
      end
    end
  rescue Faraday::ConnectionFailed
    puts 'Connection failed. Performing the task without pulling the latest code from Git.'
  end

  def git_checkout(_branch)
    `git -C "#{project.folder_path}" checkout #{_branch}` if enable_git?
  end
end
