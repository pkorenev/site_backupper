module SiteBackupper
  class Backupper
    def initialize(project_directory: , archive_root_directory_name: nil, backup_path: nil, storage_options: nil )
      @project_directory = project_directory
      if archive_root_directory_name.nil?
        @archive_root_directory_name = project_directory.split('/').last
      end
      @storage_options = storage_options.presence || Config.default_aws_storage_options
      @backup_path = backup_path
      @backup_folder_path = File.dirname(backup_path)
    end

    def make_archive(database_config, nginx_config = nil)
      archive_file_path = @backup_path
      make_sql_dump(database_config)
      sql_file_path = self.sql_file_path(database_config)

      if nginx_config.present?
        #build_nginx_main_config
        build_nginx_website_config(nginx_config)
        nginx_website_config_file_path = self.nginx_website_config_file_path
      end

      File.open(archive_file_path, "wb") do |file|
        SevenZipRuby::Writer.open(file) do |szr|
          if sql_file_path
            szr.add_file(sql_file_path, as: @archive_root_directory_name + '/' + File.basename(sql_file_path))
          end

          if nginx_website_config_file_path
            szr.add_file(nginx_website_config_file_path, as: @archive_root_directory_name + '/' + File.basename(nginx_website_config_file_path))
          end

          next unless File.exists?(@project_directory)

          szr.add_directory(@project_directory, as: "#{@archive_root_directory_name}/project")
        end
      end

      cleanup_temp_files(database_config)
    end

    def upload_archive(remote_path)
      SiteBackupper::AwsS3Storage.new(**@storage_options).upload(@backup_path, remote_path)
    end

    def cleanup_temp_files(database_config)
      files_to_remove = []
      files_to_remove << self.sql_file_path(database_config)
      files_to_remove << self.nginx_website_config_file_path

      files_to_remove.select(&:present?).each do |path|
        FileUtils.rm(path)
      end
    end

    def delete_local_archive
      FileUtils.rm(@backup_path)
    end

    protected

    def build_nginx_main_config

    end

    def build_nginx_website_config(nginx_config)
      config_file_path = nginx_website_config_file_path
      File.write(config_file_path, nginx_config[:website_config_source])
    end

    def make_sql_dump(database_config)
      sql_file_path = self.sql_file_path(database_config)
      if sql_file_path.present?
        DatabaseBackupper.make_dump(destination: sql_file_path, **database_config)
      end
    end

    def relative_to_backup_archive_path(path)
      (@backup_folder_path.split('/').length - 1).times.map { '..' }.join('/') + path
    end

    def sql_file_path(database_config)
      return if database_config.blank? || database_config == 'none' || database_config[:adapter] == 'sqlite3'

      "#{@backup_folder_path}/#{database_config[:database]}.sql"
    end

    def nginx_main_config_file_path
      "#{@backup_folder_path}/nginx.conf"
    end

    def nginx_website_config_file_path
      "#{@backup_folder_path}/nginx-server.conf"
    end
  end
end