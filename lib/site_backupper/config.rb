module SiteBackupper
  module Config
    def self.option(name)
      define_singleton_method "#{name}=" do |options|
        class_variable_set(:"@@#{name}", options)
      end

      define_singleton_method name do
        begin
          class_variable_get(:"@@#{name}")
        rescue NameError
          nil
        end
      end
    end

    option :default_aws_storage_options
    option :default_pg_dump_bin_path
  end
end