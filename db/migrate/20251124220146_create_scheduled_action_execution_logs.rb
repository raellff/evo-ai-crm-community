# frozen_string_literal: true

class CreateScheduledActionExecutionLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :scheduled_action_execution_logs, if_not_exists: true do |t|
      t.references :scheduled_action, null: false, foreign_key: true
      t.string :status, null: false, default: 'completed', limit: 50
      t.text :result_message
      t.jsonb :error_details, default: {}
      t.integer :retry_count, default: 0
      t.integer :execution_time_ms
      t.text :execution_log
      t.timestamps
    end

    # Indexes for querying
    add_index :scheduled_action_execution_logs, [:scheduled_action_id, :created_at],
      name: 'idx_exec_logs_action_created', if_not_exists: true
    add_index :scheduled_action_execution_logs, :status, if_not_exists: true
    add_index :scheduled_action_execution_logs, :created_at, if_not_exists: true
  end
end
