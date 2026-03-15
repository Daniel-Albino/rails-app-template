# =============================================================================
# app/jobs/application_job.rb
# =============================================================================

class ApplicationJob < ActiveJob::Base
  # Automaticamente retenta em erros de deadlock
  retry_on ActiveRecord::Deadlocked

  # Descarta jobs com records que não existem mais
  discard_on ActiveJob::DeserializationError

  # Timeout por defeito
  # queue_as :default
end
