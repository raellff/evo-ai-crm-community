# Encrypt existing plaintext EVOLUTION_HUB_API_KEY rows at rest. This key became
# newly-sensitive (bearer credential — see InstallationConfig::SENSITIVE_NAMES);
# rows written before that change are stored in plaintext. Re-saving each row runs
# InstallationConfig's `before_save :encrypt_sensitive_value`, which produces a
# Fernet 'gAAAAA…' token using the exact same key/format as every other secret.
#
# Idempotent: rows already stored as a Fernet token are skipped, so re-running (or
# a crash + retry) is a clean no-op. The skip check reads the RAW serialized_value
# — NOT InstallationConfig#value — because `value` transparently decrypts sensitive
# keys, which would make encrypted and plaintext rows indistinguishable here.
class EncryptEvolutionHubApiKeyAtRest < ActiveRecord::Migration[7.1]
  # Names that became sensitive and may exist as plaintext at rest. Mirrors
  # InstallationConfig::SENSITIVE_NAMES but pinned here so the migration keeps
  # its intended scope even if that constant changes later.
  NEWLY_SENSITIVE_NAMES = %w[EVOLUTION_HUB_API_KEY].freeze

  def up
    unless table_exists?(:installation_configs)
      say 'installation_configs table missing; skipping encryption backfill', true
      return
    end

    encrypted = 0
    skipped = 0

    InstallationConfig.unscoped.where(name: NEWLY_SENSITIVE_NAMES).find_each do |config|
      encrypt_row(config) ? encrypted += 1 : skipped += 1
    end

    say "Encryption backfill complete: #{encrypted} encrypted, #{skipped} skipped", true
  end

  def down
    # No-op by design. Decrypting on rollback would re-introduce the plaintext-at-rest
    # leak this migration closes; encrypted values still read fine via
    # InstallationConfig#value (decrypt_if_sensitive), so there is nothing to reverse.
    say 'EncryptEvolutionHubApiKeyAtRest#down is a no-op (encrypted values remain readable)', true
  end

  private

  # Encrypts a single row in place. Returns true if it wrote a Fernet token, false
  # if the row was skipped (blank or already encrypted). Reads the RAW serialized
  # value — NOT InstallationConfig#value — so plaintext and ciphertext rows are
  # distinguishable (value would transparently decrypt both).
  def encrypt_row(config)
    serialized = config.serialized_value
    raw = serialized.is_a?(Hash) ? serialized['value'] : nil

    if raw.blank?
      say "  #{config.name} (#{config.id}): blank value; skipping", true
      return false
    end

    if raw.to_s.start_with?('gAAAAA')
      say "  #{config.name} (#{config.id}): already encrypted; skipping", true
      return false
    end

    # Assigning value= then save! guarantees the row is dirty so the UPDATE fires,
    # and the model's before_save encrypts it to a Fernet token.
    config.value = raw
    config.save!
    say "  #{config.name} (#{config.id}): encrypted at rest", true
    true
  rescue StandardError => e
    say "  ✗ #{config.name} (#{config.id}): #{e.message}", true
    raise
  end
end
