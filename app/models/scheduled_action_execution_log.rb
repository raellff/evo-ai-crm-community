# frozen_string_literal: true

# == Schema Information
#
# Table name: scheduled_action_execution_logs
#
#  id                  :bigint           not null, primary key
#  error_details       :jsonb
#  execution_log       :text
#  execution_time_ms   :integer
#  result_message      :text
#  retry_count         :integer          default(0)
#  status              :string(50)       default("completed"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  scheduled_action_id :bigint           not null
#
# Indexes
#
#  idx_exec_logs_action_created                                  (scheduled_action_id,created_at)
#  index_scheduled_action_execution_logs_on_created_at           (created_at)
#  index_scheduled_action_execution_logs_on_scheduled_action_id  (scheduled_action_id)
#  index_scheduled_action_execution_logs_on_status               (status)
#
# Foreign Keys
#
#  fk_rails_...  (scheduled_action_id => scheduled_actions.id)
#
class ScheduledActionExecutionLog < ApplicationRecord
  belongs_to :scheduled_action

  # Statuses
  STATUSES = {
    completed: 'completed',
    failed: 'failed',
    retry_pending: 'retry_pending',
    timeout: 'timeout',
    error: 'error'
  }.freeze

  enum :status, STATUSES, prefix: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :for_action, ->(action_id) { where(scheduled_action_id: action_id) }
  scope :failed, -> { where(status: [:failed, :error, :timeout]) }
  scope :successful, -> { where(status: :completed) }
  # Validations
  validates :scheduled_action_id, presence: true
  validates :status, presence: true

  def success?
    status_completed?
  end

  def failure?
    status_failed? || status_error? || status_timeout?
  end

  def self.log_execution(scheduled_action, execution_time_ms = nil, &block)
    start_time = Time.current
    result = nil
    error = nil

    begin
      result = block.call
    rescue StandardError => e
      error = e
    end

    execution_time = execution_time_ms || ((Time.current - start_time) * 1000).to_i

    status = if error
               error.is_a?(Timeout::Error) ? 'timeout' : 'error'
             elsif result[:success] == false
               'failed'
             else
               'completed'
             end

    create!(
      scheduled_action: scheduled_action,
      status: status,
      result_message: result.is_a?(Hash) ? result[:data]&.to_s : result.to_s,
      error_details: error ? { message: error.message, backtrace: error.backtrace&.first(5) } : {},
      retry_count: scheduled_action.retry_count,
      execution_time_ms: execution_time,
      execution_log: error ? "#{error.class}: #{error.message}" : 'Success'
    )

    raise error if error
    result
  end
end
