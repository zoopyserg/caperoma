# frozen_string_literal: true

class PivotalFetcher
  def self.process(story_id)
    story = get_story(story_id)

    if story.present?
      title = story.name
      description = story.description
      type = story.story_type
      # labels = story.labels # in case I do Critical thing
      # something liek if lables.include?("hot") pass "critical" status to Jira.

      story.update(current_state: 'started', owned_by: 'Serge Vinogradoff')

      args = [type, title, description, story_id] # or args = [type, title, description, "1", story_id] ? I use that 1 in older versions
      case type
      when 'feature'
        Caperoma.feature(args)
      when 'bug'
        Caperoma.bug(args)
      else
        puts 'Unknown story type in Pivotal'
      end

      # copy Jira ID to Pivotal story
      task = Task.where(pivotal_id: story_id).first
      if task.present?
        task.jira_key
        story.notes.create(text: task.jira_key)
      else
        puts 'task does not exist'
      end
    else
      puts 'Did not find a story'
    end
  end

  def self.finish(story_id)
    story = nil

    PivotalTracker::Project.all.each do |project|
      story = project.stories.find(story_id)
      break if story.present?
    end

    story

    if story.present? && story.tasks.all.empty?
      story.update current_state: 'finished'
    end
  end

  def self.create_story(title, description)
    connect

    project_id = 993_892

    # this isn't needed anymore... these are PT ID's of Ruck.us.
    if title.include? '[Ruck.us] Production '
      project_id = 993_892
    elsif title.include? '[Ruck.us] Staging '
      project_id = 1_110_744
    elsif title.include? '[Ruck.us] Staging2 '
      project_id = 1_266_704
    end

    # TODO: icebox, need probably to move to backlog
    project = PivotalTracker::Project.find(project_id)
    story = project.stories.create name: title,
                                   description: description,
                                   requested_by: 'Serge Vinogradoff',
                                   owned_by: 'Serge Vinogradoff',
                                   story_type: 'bug'

    story
  end

  def self.get_story_by_title(title)
    connect

    story = nil

    PivotalTracker::Project.all.each do |project|
      story = project.stories.all.select { |x| x.name == title }.first
      break if story.present?
    end

    story
  end

  def self.get_story(story_id)
    connect

    story = nil

    PivotalTracker::Project.all.each do |project|
      story = project.stories.find(story_id)
      break if story.present?
    end

    story
  end

  def self.connect
    PivotalTracker::Client.token(Account.pivotal.email, Account.pivotal.password)
  end
end
