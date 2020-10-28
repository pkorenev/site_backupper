module SiteBackupper
  class Storage
    def self.upload(adapter:, **options)
      if adapter == 'aws_glacier'
        AwsGlacierStorage.new(destination: destination, **options).make_dump
      end
    end
  end
end