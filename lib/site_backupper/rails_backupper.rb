require "open3"
require 'json'
require 'seven_zip_ruby'

module SiteBackupper
  class RailsBackupper < Backupper
    def initialize(project_directory: , ruby_version:, rails_env: , rvm_home:, backup_path: nil, storage_options: nil )
      @project_directory = project_directory
      @rvm_home = rvm_home
      @ruby_version = ruby_version
      @rails_env = rails_env
      @storage_options = storage_options.presence || Config.default_aws_storage_options
      @backup_path = backup_path
      @backup_folder_path = File.dirname(backup_path)
    end

    def make_archive
      archive_file_path = @backup_path
      database_config = fetch_database_config
      sql_file_path = self.sql_file_path(database_config)
      application_yml_file_path = "#{@project_directory}/config/application.yml"
      files_and_folders_to_copy = ['public/system', 'public/uploads', 'public/ckeditor_assets', 'config/application.yml']

      File.open(archive_file_path, "wb") do |file|
        SevenZipRuby::Writer.open(file) do |szr|
          file_path = relative_to_backup_archive_path(sql_file_path)
          puts file_path
          szr.add_file(file_path, as: File.basename(sql_file_path))

          files_and_folders_to_copy.each do |rel_path|
            source_full_path = "#{@project_directory}/#{rel_path}"
            next unless File.exists?(source_full_path)

            if File.directory?(source_full_path)
              szr.add_directory(source_full_path, as: rel_path)
            else
              szr.add_file(relative_to_backup_archive_path(source_full_path), as: rel_path)
            end
          end
        end
      end
    end

    def upload_archive(remote_path)
      SiteBackupper::AwsS3Storage.new(**@storage_options).upload(@backup_path, remote_path)
    end

    protected

    def find_database
      #`rvm #{@ruby_version} do /usr/bin/env ruby --version`
      #`rvm #{@ruby_version} do #{@project_directory}/bin/bundle exec rails -T`
      #command = "cd #{@project_directory} && rvm #{@ruby_version} do bin/bundle exec rails runner 'puts Rails.env'"
      command = "rvm #{@ruby_version} do #{@project_directory}/bin/bundle exec rake --version"
      puts "Execute: #{command}"
      `#{command}`
      #`ls /`
    end

    def fetch_database_config
      puts run_command "echo $PATH"
      puts run_command "echo $GEM_HOME"
      puts run_command "echo $BUNDLE_GEMFILE"
      #command = "#{ruby_path} #{@project_directory}/bin/bundle --version"
      ruby_code = %Q( puts Rails.configuration.database_configuration["#{@rails_env}"].to_json )
      database_config = JSON.parse(run_code_in_rails_console(ruby_code)).symbolize_keys
      #puts "Execute: #{command}"
      #`#{command}`
    end

    def run_code_in_rails_console(code)
      run_command "cd #{@project_directory} && rails runner '#{code}'"
    end

    def export_env_variables_expression
      env_variables = {
        PATH: path_env_variable,
        GEM_HOME: gem_home,
        BUNDLE_GEMFILE: "#{@project_directory}/Gemfile",
        RAILS_ENV: @rails_env
      }
      "export #{env_variables.map { |k, v| "#{k}=#{v}" }.join(' ') }"
    end

    def ruby_path
      "#{@rvm_home}/rubies/ruby-#{@ruby_version}/bin/ruby"
    end

    def path_env_variable
      #"/home/pasha/.rvm/rubies/ruby-#{@ruby_version}/bin"
      "#{@rvm_home}/gems/ruby-#{@ruby_version}/wrappers:/bin:/usr/bin"
    end

    def gem_home
      "/home/pasha/.rvm/gems/ruby-#{@ruby_version}"
    end

    def run_command(command)
      return if !command || command == ''
      full_command = "#{export_env_variables_expression} && #{command}"
      #puts "Execute: #{full_command}"
      res = `#{full_command}`
      if res.is_a?(String) && res.end_with?("\n")
        res[0, res.length - 1]
      else
        res
      end
    end

    def ruby_script_path(script)
      "#{path_env_variable}/#{script}"
    end

    def make_sql_dump
      database_config = fetch_database_config
      sql_file_path = self.sql_file_path(database_config)
      DatabaseBackupper.make_dump(destination: sql_file_path, **database_config)
    end

    def relative_to_backup_archive_path(path)
      (@backup_folder_path.split('/').length - 1).times.map { '..' }.join('/') + path
    end

    def sql_file_path(database_config)
      "#{@backup_folder_path}/#{database_config[:database]}.sql"
    end
  end
end