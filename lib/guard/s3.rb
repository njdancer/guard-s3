require 'guard'
require 'guard/plugin'
require 'aws/s3'

module Guard
  class S3 < Plugin

    def initialize(options = {})
      super
      @s3 = AWS::S3.new(
        :access_key_id  => options[:access_key_id],
        :secret_access_key => options[:secret_access_key]
      )
      @bucket         = @s3.buckets[options[:bucket]]
      @s3_permissions = options[:s3_permissions]
      @debug          = true
      @watchdir       = options[:watchdir] || Dir.pwd
      @prefix         = options[:prefix]
    end

    def run_on_changes(paths)
      paths.each do |path|
        file = File.join(@watchdir, path)
        dest_path = File.join(@prefix, path)
        dest_key = @bucket.objects[dest_path]
        begin
          if dest_key.exists?
            if etag_match?(file, dest_path)
              log "Unchanged: #{dest_path}"
            else
              log "Updating: #{dest_path}"
              dest_key.write(:file => file, :acl => @s3_permissions)
            end
          else
            log "Creating: #{dest_path}"
            dest_key.write(:file => file, :acl => @s3_permissions)
          end
        rescue Exception => e
          log e.message
        end
      end
    end
    
    def etag_match?(path, key)
      Digest::MD5.hexdigest(File.read(path)) == @bucket.objects[key].etag.gsub('"','')
    end

    private

    def debug?
      @debug || false
    end

    def log(msg)
      return unless debug?
      puts "[#{Time.now}] #{msg}"
    end

  end
end
