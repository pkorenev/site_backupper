module SiteBackupper
  class PostgresqlBackupper < DatabaseBackupper
    def initialize(destination:, database:, host: nil , port: nil, username: , password:, pg_dump_bin_path: nil, **options )
      @destination = destination
      @database = database
      @host = host
      @port = port
      @username = username
      @password = password
      @options = options
      @pg_dump_bin_path = pg_dump_bin_path.presence || Config.default_pg_dump_bin_path
    end

    def make_dump
      puts "make postgresql dump: destionation: #{@destination}; options: #{@options}"

      command = "#{@pg_dump_bin_path} \"host=#{@host} port=#{@port} dbname=#{@database} user=#{@username} password='#{@password}' \" > #{@destination}"
      puts "Execute: #{command}"
      `#{command}`
    end
  end
end