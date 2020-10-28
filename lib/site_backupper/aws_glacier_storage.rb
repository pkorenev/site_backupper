require 'aws-sdk-glacier'

module SiteBackupper
  class AwsGlacierStorage < Storage
    def initialize(vault: , access_key: , secret_key: , region: )
      @region = region
      @vault = vault
      @access_key = access_key
      @secret_key = secret_key
    end

    def upload(source_path, description)
      puts "AwsGlacierStorage: upload #{source_path} to #{description}"
      contents = File.read(source_path)
      response = client.upload_archive(
        vault_name: @vault,
        account_id: '-',
        body: contents,
        archive_description: description,
        checksum: Digest::SHA256.hexdigest(contents)
      )

      response
    end

    def client
      credentials = Aws::Credentials.new(@access_key, @secret_key)
      Aws::Glacier::Client.new(
        region: @region,
        credentials: credentials
      )
    end
  end
end