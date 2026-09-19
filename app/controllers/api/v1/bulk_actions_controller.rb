class Api::V1::BulkActionsController < Api::V1::BaseController
  before_action :check_bulk_action_permission!
  before_action :type_matches?

  def create
    if type_matches?
      result = ::BulkActionsJob.perform_now(
        user: current_user,
        params: permitted_params
      )

      success_response(
        data: result,
        message: 'Bulk action completed successfully',
        status: :created
      )
    else
      error_response(
        ApiErrorCodes::INVALID_PARAMETER,
        'Invalid type. Must be Conversation or Contact'
      )
    end
  end

  private

  # The permission follows the record type being mutated: conversation bulk
  # actions demand conversations.update; contact bulk actions demand
  # contacts.delete, since BulkActionsJob only supports deletion for contacts.
  def check_bulk_action_permission!
    permission_key = params[:type] == 'Conversation' ? 'conversations.update' : 'contacts.delete'
    check_permission!(permission_key, :user)
  end

  def type_matches?
    ['Conversation', 'Contact'].include?(params[:type])
  end

  def permitted_params
    params.permit(:type, :snoozed_until, ids: [], fields: [:status, :assignee_id, :team_id, :action], labels: [add: [], remove: []])
  end
end
