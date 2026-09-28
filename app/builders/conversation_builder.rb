class ConversationBuilder
  pattr_initialize [:params!, :contact_inbox!]

  def perform
    look_up_exising_conversation || create_new_conversation
  end

  private

  def look_up_exising_conversation
    return unless @contact_inbox.inbox.lock_to_single_conversation?

    @contact_inbox.conversations.last
  end

  def create_new_conversation
    # Use find_or_create_by para evitar race conditions
    excluded_params = %i[additional_attributes custom_attributes snoozed_until assignee_id team_id status]
    ::Conversation.find_or_create_by!(conversation_params.except(*excluded_params)) do |conversation|
      conversation.additional_attributes = conversation_params[:additional_attributes]
      conversation.custom_attributes = conversation_params[:custom_attributes]
      conversation.snoozed_until = conversation_params[:snoozed_until]
      conversation.assignee_id = conversation_params[:assignee_id]
      conversation.team_id = conversation_params[:team_id]
      # Only set status if explicitly provided in params, otherwise let determine_conversation_status handle it
      if conversation_params[:status].present?
        conversation.status = conversation_params[:status]
        conversation.status_explicitly_set!
      end
    end
  end

  def conversation_params
    additional_attributes = params[:additional_attributes]&.permit! || {}
    custom_attributes = params[:custom_attributes]&.permit! || {}
    # Only include status if explicitly provided, otherwise let the model's determine_conversation_status handle it
    status = params[:status].present? ? { status: params[:status] } : {}

    # TODO: temporary fallback for the old bot status in conversation, we will remove after couple of releases
    # commenting this out to see if there are any errors, if not we can remove this in subsequent releases
    # status = { status: 'pending' } if status[:status] == 'bot'
    {
      inbox_id: @contact_inbox.inbox_id,
      contact_id: @contact_inbox.contact_id,
      contact_inbox_id: @contact_inbox.id,
      # Used by the public (unauthenticated) API/widget conversation-creation
      # path too, where Current.account is never set — stamp explicitly so
      # AccountScoped's before_validation fallback isn't relied on.
      account_id: @contact_inbox.inbox.account_id,
      additional_attributes: additional_attributes,
      custom_attributes: custom_attributes,
      snoozed_until: params[:snoozed_until],
      assignee_id: params[:assignee_id],
      team_id: params[:team_id]
    }.merge(status)
  end
end
