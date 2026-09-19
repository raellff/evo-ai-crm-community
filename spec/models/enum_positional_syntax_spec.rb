# frozen_string_literal: true

# Regression spec for the enum hardening (EVO-2007).
#
# All models were migrated from the keyword enum syntax `enum name: {...}` to the
# Rails 7.1 positional form `enum :name, {...}`, converting `_prefix:`/`_suffix:`
# into `prefix:`/`suffix:`. On top of that, Conversation#source and Message#source
# declare an explicit `attribute :source, :integer, default: 0` so the models stay
# bootable when the column has not been migrated yet (EVO-1999 deploy scenario).
#
# This spec guarantees that:
#   1) the enums keep mapping the same values;
#   2) enums with prefix still generate the prefixed methods (`_prefix:` regression);
#   3) the new `source` column (Conversation/Message) works — focus of the incident;
#   4) Conversation/Message boot without the source column (EVO-2007 AC 3).

begin
  require 'rails_helper'
rescue LoadError
  RSpec.describe 'Enum positional syntax' do
    it 'has spec scaffold ready' do
      skip 'rails_helper is not available in this workspace snapshot'
    end
  end
end

return unless defined?(Rails)

RSpec.describe 'Enum positional syntax (EVO-2007)', type: :model do
  describe 'mappings preserved' do
    it 'keeps live/imported on Conversation.sources and Message.sources' do
      expect(Conversation.sources).to eq('live' => 0, 'imported' => 1)
      expect(Message.sources).to eq('live' => 0, 'imported' => 1)
    end

    it 'keeps Conversation.statuses and priorities intact' do
      expect(Conversation.statuses).to eq('open' => 0, 'resolved' => 1, 'pending' => 2, 'snoozed' => 3)
      expect(Conversation.priorities).to eq('low' => 0, 'medium' => 1, 'high' => 2, 'urgent' => 3)
    end

    it 'keeps AgentBot.bot_providers (string-backed values) intact' do
      expect(AgentBot.bot_providers).to include('evo_ai_provider' => 'evo_ai', 'webhook_provider' => 'webhook')
    end
  end

  describe 'source predicate and scope methods (incident focus)' do
    it 'answers live?/imported? on instances' do
      conversation = Conversation.new(source: :imported)
      expect(conversation.imported?).to be(true)
      expect(conversation.live?).to be(false)

      message = Message.new(source: :live)
      expect(message.live?).to be(true)
      expect(message.imported?).to be(false)
    end

    it 'defaults source to live' do
      expect(Conversation.new.source).to eq('live')
      expect(Message.new.source).to eq('live')
    end

    it 'generates the live/imported scopes' do
      expect(Conversation.imported.to_sql).to include('source')
      expect(Message.live.to_sql).to include('source')
    end
  end

  describe 'prefixed enums (_prefix -> prefix: regression)' do
    it 'generates PipelineTask task_type_/status_/priority_ methods that answer correctly' do
      task = PipelineTask.new(task_type: :call, status: :pending, priority: :urgent)
      expect(task.task_type_call?).to be(true)
      expect(task.task_type_email?).to be(false)
      expect(task.status_pending?).to be(true)
      expect(task.priority_urgent?).to be(true)
    end

    it 'generates Pipeline methods with the :visibility prefix' do
      expect(Pipeline.new(visibility: :private).visibility_private?).to be(true)
      expect(Pipeline.new(visibility: :team).visibility_private?).to be(false)
    end

    it 'generates MessageTemplate template_type_/media_type_ methods' do
      expect(MessageTemplate.new.template_type_text?).to be(true) # set_defaults assigns 'text'
      expect(MessageTemplate.new(media_type: 'image').media_type_image?).to be(true)
    end

    it 'generates ScheduledActionExecutionLog status_ prefixed methods' do
      log = ScheduledActionExecutionLog.new(status: :retry_pending)
      expect(log.status_retry_pending?).to be(true)
      expect(log.status_completed?).to be(false)
    end
  end

  describe 'boot safety without the source column (EVO-1999 scenario, AC 3)' do
    # `ignored_columns` removes the column from the in-memory schema, which is
    # exactly what the model sees when Puma boots before db:migrate has run.
    def model_without_source_column(table, declare_attribute:)
      Class.new(ApplicationRecord) do
        self.table_name = table
        self.ignored_columns += %w[source]

        attribute :source, :integer, default: 0 if declare_attribute
        enum :source, { live: 0, imported: 1 }
      end
    end

    %w[conversations messages].each do |table|
      it "boots #{table} model and answers imported? when the column is absent" do
        klass = model_without_source_column(table, declare_attribute: true)
        stub_const('BootSafetyModel', klass)

        expect { klass.new }.not_to raise_error
        expect(klass.new.source).to eq('live')
        expect(klass.new.imported?).to be(false)
        expect(klass.new(source: :imported).imported?).to be(true)
      end
    end

    it 'still raises Undeclared attribute type without the explicit attribute (control)' do
      klass = model_without_source_column('conversations', declare_attribute: false)
      stub_const('BootSafetyControlModel', klass)

      expect { klass.new }.to raise_error(RuntimeError, /Undeclared attribute type for enum 'source'/)
    end
  end
end
