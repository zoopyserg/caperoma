# frozen_string_literal: true

class AirbrakeEmailProcessor
  # stub for test env
  def process
    account = Account.gmail
    Gmail.new(account.email, account.password) do |gmail|
      gmail.inbox.emails(:unread, from: 'donotreply@alerts.airbrake.io').select { |email| email.subject.include? '[Ruck.us]' }.each do |email|
        # get reply address
        reply_to = "#{email.to.first.mailbox}@#{email.to.first.host}"

        # generate reply body
        body = ''

        story = PivotalFetcher.get_story_by_title(email.subject)
        if story.present? && story.respond_to?(:url)
          body = "Duplicate of: #{story.url}"
        else
          story = PivotalFetcher.create_story(email.subject, email.body.raw_source[0..1000])
          body = "Created new story: #{story.url}"
        end

        # compose reply email (to get identifiers)
        reply = email.reply do
          subject "Re: #{email.subject}"
          body    body
        end

        # bugfix to make reply work
        new_email = gmail.compose do
          to          reply_to # note it's generated email, not airbrake one
          subject     reply.subject
          in_reply_to reply.in_reply_to
          references  reply.references
          body        reply.body.raw_source
        end

        # deliver reply
        new_email.deliver!

        # archive email
        email.mark(:read)
        email.archive!
      end
    end
  end
end
