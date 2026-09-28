class ApplicationJob < ActiveJob::Base
  # https://api.rubyonrails.org/v5.2.1/classes/ActiveJob/Exceptions/ClassMethods.html
  discard_on ActiveJob::DeserializationError do |job, error|
    Rails.logger.info("Skipping #{job.class} with #{
      job.instance_variable_get(:@serialized_arguments)
    } because of ActiveJob::DeserializationError (#{error.message})")
  end

  # EVO-1551 round 4 — root-cause fix, now bug-for-bug corrected.
  # `Current.account` is populated by `EvoAuthConcern` only on the HTTP
  # pipeline. Sidekiq threads inherit nothing, so any job that ends up
  # calling `ContactPiiMasker.account_flag_enabled?` (directly or via a
  # model's `push_event_data`) used to fail-open and ship raw PII.
  #
  # The original fix stashed `RuntimeConfig.account` (a plain Hash) in
  # `Current.account` itself — but `AccountScoped#default_scope` (added
  # later, for multi-account-tenancy) calls `.id` on whatever
  # `Current.account` holds, so every job touching an AccountScoped model
  # (Inbox, Conversation, User, ...) started raising
  # `NoMethodError: undefined method 'id' for an instance of Hash` and dying
  # mid-`perform` — e.g. `DeleteObjectJob` destroying a channel/inbox,
  # leaving its phone_number/website_token behind and blocking reconnection.
  #
  # Fix: keep stashing the same Hash, once per job, for the exact same PII
  # reason — just in a slot `AccountScoped` never reads, so it can't corrupt
  # its "fails open when unset" contract for `Current.account` itself.
  around_perform do |_job, block|
    needed_account = Current.pii_mask_runtime_account.nil?
    Current.pii_mask_runtime_account = RuntimeConfig.account if needed_account
    block.call
  ensure
    Current.pii_mask_runtime_account = nil if needed_account
  end
end
