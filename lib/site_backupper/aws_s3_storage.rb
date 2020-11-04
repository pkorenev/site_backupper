require 'aws-sdk-s3'

module SiteBackupper
  class AwsS3Storage < Storage
    def initialize(region: , bucket: , access_key: , secret_key: , storage_class: 'ONEZONE_IA', acl: 'public-read')
      @region = region
      @bucket = bucket
      @access_key = access_key
      @secret_key = secret_key
      @storage_class = storage_class
      @acl = acl
    end

    def upload(source_path, key)
      puts "AwsS3Storage: upload #{source_path} to #{key}"

      File.open(source_path, 'rb') do |file|
        client.put_object(
          bucket: @bucket,
          body: file,
          key: key,
          storage_class: @storage_class,
          acl: @acl
        )
      end
    end

    def client
      credentials = Aws::Credentials.new(@access_key, @secret_key)
      Aws::S3::Client.new(
        region: @region,
        credentials: credentials
      )
    end
  end
end