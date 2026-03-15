# =============================================================================
# lib/tasks/db.rake
# Rake tasks personalizadas para gestão da base de dados.
# =============================================================================

namespace :db do
  desc "Apaga, recria, migra e carrega seeds — útil em desenvolvimento"
  task reset_and_seed: :environment do
    puts "== A fazer reset completo da DB =="
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
    Rake::Task["db:seed"].invoke
    puts "== Reset concluído! =="
  end

  desc "Mostra o estado de todas as migrations com timestamp"
  task migration_status: :environment do
    puts "\n== Estado das Migrations ==\n\n"
    migrations = ActiveRecord::Base.connection.select_all(
      "SELECT version FROM schema_migrations ORDER BY version DESC"
    ).map { |r| r["version"] }

    ActiveRecord::MigrationContext.new(
      Rails.root.join("db/migrate"),
      ActiveRecord::SchemaMigration.new(ActiveRecord::Base.connection)
    ).migrations.each do |m|
      status = migrations.include?(m.version.to_s) ? "UP  " : "DOWN"
      puts "  #{status}  #{m.version}  #{m.name}"
    end
    puts ""
  end

  desc "Remove ficheiro setupcomplete (força novo db:prepare no próximo boot)"
  task force_setup: :environment do
    setup_file = Rails.root.join("setupcomplete")
    if File.exist?(setup_file)
      File.delete(setup_file)
      puts "Ficheiro 'setupcomplete' removido. O próximo boot irá correr db:prepare."
    else
      puts "Ficheiro 'setupcomplete' não existe."
    end
  end
end
