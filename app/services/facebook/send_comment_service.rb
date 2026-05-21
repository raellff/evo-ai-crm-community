# Service to send comments on Facebook posts
# Uses Facebook Graph API to post comments or replies to comments
require 'net/http'
require 'uri'

class Facebook::SendCommentService < Base::SendOnChannelService
  private

  def channel_class
    Channel::FacebookPage
  end

  def perform_reply
    return unless message.content.present?

    if reply_to_comment?
      send_reply_to_comment
    else
      send_comment_to_post
    end
  rescue StandardError => e
    Rails.logger.error("Facebook::SendCommentService: Error sending comment: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    Messages::StatusUpdateService.new(message, 'failed', e.message).perform
  end

  def reply_to_comment?
    message.content_attributes&.dig('in_reply_to').present? ||
      message.content_attributes&.dig('in_reply_to_external_id').present?
  end

  def send_comment_to_post
    post_id = conversation.post_id
    unless post_id.present?
      raise StandardError, "Post ID not found for conversation #{conversation.id}"
    end

    Rails.logger.info("Facebook::SendCommentService: Sending comment to post #{post_id}")

    response = send_graph_api_request(
      endpoint: "#{post_id}/comments",
      params: {
        message: message.content,
        access_token: channel.page_access_token
      }
    )

    handle_response(response)
  end

  def send_reply_to_comment
    # Try to get comment_id from in_reply_to_external_id first (Facebook comment ID)
    comment_id = message.content_attributes&.dig('in_reply_to_external_id')

    # If not found, try to find the parent message and get its source_id
    if comment_id.blank?
      parent_message = find_parent_message
      comment_id = parent_message&.source_id
    end

    unless comment_id.present?
      raise StandardError, "Comment ID not found for reply message #{message.id}"
    end

    Rails.logger.info("Facebook::SendCommentService: Sending reply to comment #{comment_id}")

    response = send_graph_api_request(
      endpoint: "#{comment_id}/comments",
      params: {
        message: message.content,
        access_token: channel.page_access_token
      }
    )

    handle_response(response)
  end

  def find_parent_message
    parent_id = message.content_attributes&.dig('in_reply_to')
    return nil unless parent_id.present?

    conversation.messages.find_by(id: parent_id)
  end

  def send_graph_api_request(endpoint:, params:)
    url = "#{MetaBaseUrl.for(:facebook)}/#{endpoint}"

    Rails.logger.info("Facebook::SendCommentService: POST #{url}")
    Rails.logger.debug("Facebook::SendCommentService: Params: #{params.except('access_token').inspect}")

    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30
    http.open_timeout = 10

    request = Net::HTTP::Post.new(uri.path)
    request.set_form_data(params)

    response = http.request(request)

    Rails.logger.info("Facebook::SendCommentService: Response status: #{response.code}")
    Rails.logger.debug("Facebook::SendCommentService: Response body: #{response.body}")

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    Rails.logger.error("Facebook::SendCommentService: Failed to parse JSON response: #{e.message}")
    { 'error' => { 'message' => 'Failed to parse Facebook response', 'code' => 0 } }
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.error("Facebook::SendCommentService: Timeout error: #{e.message}")
    { 'error' => { 'message' => 'Request timed out, please try again later', 'code' => 0 } }
  end

  def handle_response(response)
    if response['error'].present?
      error_message = external_error(response)
      Messages::StatusUpdateService.new(message, 'failed', error_message).perform
      Rails.logger.error("Facebook::SendCommentService: Error from Facebook: #{error_message}")
      return
    end

    # Facebook returns { "id": "comment_id" } on success
    if response['id'].present?
      message.update!(source_id: response['id'])
      Rails.logger.info("Facebook::SendCommentService: Comment sent successfully with ID: #{response['id']}")
    else
      Rails.logger.warn("Facebook::SendCommentService: Unexpected response format: #{response.inspect}")
    end
  end

  def external_error(response)
    error_message = response.dig('error', 'message') || 'Unknown error'
    error_code = response.dig('error', 'code') || 0
    "#{error_code} - #{error_message}"
  end
end

