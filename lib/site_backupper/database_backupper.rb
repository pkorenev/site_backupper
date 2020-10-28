module SiteBackupper
  class DatabaseBackupper
    def self.make_dump(adapter:, destination: , **options)
      if adapter == 'postgresql'
        PostgresqlBackupper.new(destination: destination, **options).make_dump
      end
    end
  end
end