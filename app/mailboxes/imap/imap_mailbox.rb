class Imap::ImapMailbox
  include MailboxHelper
  include IncomingEmailValidityHelper
  attr_accessor :channel, :inbox, :conversation, :processed_mail

  def process(mail, channel)
    @inbound_mail = mail
    @channel = channel
    load_inbox
    decorate_mail

    Rails.logger.info("[EMAIL_PROCESS] Processing Email from: #{@processed_mail.original_sender.inspect} : inbox #{@inbox.id} : message_id #{@processed_mail.message_id}")
    Rails.logger.info("[EMAIL_PROCESS] Mail.from: #{mail.from.inspect}, Mail.reply_to: #{mail.reply_to.inspect}")

    # Skip processing email if it belongs to any of the edge cases
    unless incoming_email_from_valid_email?
      Rails.logger.warn("[EMAIL_PROCESS] Skipping email - invalid sender: #{@processed_mail.original_sender.inspect}")
      return
    end

    ActiveRecord::Base.transaction do
      find_or_create_contact
      Rails.logger.info("[EMAIL_PROCESS] Contact found/created: #{@contact.id} (#{@contact.email})")
      find_or_create_conversation
      Rails.logger.info("[EMAIL_PROCESS] Conversation found/created: #{@conversation.id}")
      create_message
      add_attachments_to_message
      Rails.logger.info("[EMAIL_PROCESS] Email processed successfully - Conversation: #{@conversation.id}, Contact: #{@contact.id}")
    end
  end

  private

  def load_inbox
    @inbox = @channel.inbox
  end

  def decorate_mail
    @processed_mail = MailPresenter.new(@inbound_mail)
  end

  def find_conversation_by_in_reply_to
    return if in_reply_to.blank?

    message = @inbox.messages.find_by(source_id: in_reply_to)
    if message.nil?
      @inbox.conversations.where("additional_attributes->>'in_reply_to' = ?", in_reply_to).first
    else
      @inbox.conversations.find(message.conversation_id)
    end
  end

  def find_conversation_by_reference_ids
    return if @inbound_mail.references.blank? && in_reply_to.present?

    message = find_message_by_references

    return if message.nil?

    @inbox.conversations.find(message.conversation_id)
  end

  def in_reply_to
    @processed_mail.in_reply_to
  end

  def find_message_by_references
    message_to_return = nil

    references = Array.wrap(@inbound_mail.references)

    references.each do |message_id|
      message = @inbox.messages.find_by(source_id: message_id)
      message_to_return = message if message.present?
    end
    message_to_return
  end

  def find_or_create_conversation
    @conversation = find_conversation_by_in_reply_to || find_conversation_by_reference_ids || ::Conversation.create!(
      {
        inbox_id: @inbox.id,
        contact_id: @contact.id,
        contact_inbox_id: @contact_inbox.id,
        account_id: @inbox.account_id,
        additional_attributes: {
          source: 'email',
          in_reply_to: in_reply_to,
          mail_subject: @processed_mail.subject,
          initiated_at: {
            timestamp: Time.now.utc
          }
        }
      }
    )
  end

  def find_or_create_contact
    sender_email = @processed_mail.original_sender
    Rails.logger.info("[EMAIL_PROCESS] Looking for contact with email: #{sender_email.inspect}")

    @contact = @inbox.contacts.from_email(sender_email) if sender_email.present?

    if @contact.present?
      Rails.logger.info("[EMAIL_PROCESS] Found existing contact: #{@contact.id} (#{@contact.email})")
      @contact_inbox = ContactInbox.find_by(inbox: @inbox, contact: @contact)
    else
      Rails.logger.info("[EMAIL_PROCESS] Creating new contact for: #{sender_email.inspect}")
      create_contact
    end
  end

  def identify_contact_name
    return processed_mail.sender_name if processed_mail.sender_name.present?
    return nil if processed_mail.from.blank? || processed_mail.from.first.blank?

    email = processed_mail.from.first
    email.split('@').first if email.include?('@')
  rescue StandardError => e
    Rails.logger.warn("[EMAIL_PROCESS] Error identifying contact name: #{e.message}")
    nil
  end
end
