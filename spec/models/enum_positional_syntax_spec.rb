# frozen_string_literal: true

# Regression spec for the enum syntax migration (EVO-2007).
#
# Todos os modelos migraram da sintaxe keyword depreciada `enum nome: {...}` para
# a posicional do Rails 7.1 `enum :nome, {...}`, e as opções `_prefix:`/`_suffix:`
# viraram `prefix:`/`suffix:`. Este spec garante que:
#   1) os enums continuam mapeando os mesmos valores;
#   2) os enums com prefix ainda geram os métodos prefixados (regressão do _prefix);
#   3) a coluna nova `source` (Conversation/Message) funciona — foco do incidente.

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
  describe 'mapeamento preservado' do
    it 'Conversation.sources / Message.sources mantêm live/imported' do
      expect(Conversation.sources).to eq('live' => 0, 'imported' => 1)
      expect(Message.sources).to eq('live' => 0, 'imported' => 1)
    end

    it 'Conversation.statuses e priorities intactos' do
      expect(Conversation.statuses).to eq('open' => 0, 'resolved' => 1, 'pending' => 2, 'snoozed' => 3)
      expect(Conversation.priorities).to include('low' => 0, 'urgent' => 3)
    end

    it 'AgentBot.bot_providers (valores string) intactos' do
      expect(AgentBot.bot_providers).to include('evo_ai_provider' => 'evo_ai', 'webhook_provider' => 'webhook')
    end
  end

  describe 'métodos de source (foco do incidente)' do
    it 'instância responde a live?/imported? e query methods' do
      conv = Conversation.new(source: :imported)
      expect(conv.imported?).to be(true)
      expect(conv.live?).to be(false)
      expect(Conversation).to respond_to(:imported)
      expect(Message).to respond_to(:imported)
    end
  end

  describe 'enums com prefix (regressão do _prefix -> prefix:)' do
    it 'PipelineTask gera métodos prefixados (task_type_/status_/priority_)' do
      task = PipelineTask.new
      expect(task).to respond_to(:task_type_call?)
      expect(task).to respond_to(:status_pending?)
      expect(task).to respond_to(:priority_urgent?)
    end

    it 'Pipeline gera métodos com prefix :visibility' do
      expect(Pipeline.new).to respond_to(:visibility_private?)
    end

    it 'MessageTemplate gera métodos prefixados (template_type_/media_type_)' do
      tmpl = MessageTemplate.new
      expect(tmpl).to respond_to(:template_type_text?)
      expect(tmpl).to respond_to(:media_type_image?)
    end

    it 'ScheduledActionExecutionLog gera status_ prefixado' do
      log = ScheduledActionExecutionLog.new
      expect(log).to respond_to(:status_completed?)
      expect(log).to respond_to(:status_retry_pending?)
    end
  end
end
