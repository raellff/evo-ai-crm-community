class Api::V1::SearchController < Api::V1::BaseController
  require_permissions({
    conversations: 'conversations.read',
    messages: 'conversations.read',
    contacts: 'contacts.read'
  })

  before_action :check_index_permission!, only: [:index]

  def index
    @result = search('all')
  end

  def conversations
    @result = search('Conversation')
  end

  def contacts
    @result = search('Contact')
  end

  def messages
    @result = search('Message')
  end


  private

  # The 'all' search spans contacts, conversations and messages, so it
  # demands the read grant of every surface it exposes.
  def check_index_permission!
    check_permission!('contacts.read', :user)
    return if performed?

    check_permission!('conversations.read', :user)
  end

  def search(search_type)
    SearchService.new(
      current_user: Current.user,
      search_type: search_type,
      params: params
    ).perform
  end
end
