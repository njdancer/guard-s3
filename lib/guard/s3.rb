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

    def run_on_additions(paths)
      paths.each do |path|
        file = resolve_file path
        object = resolve_object path
        begin
          if object.exists?
            out_of_sync
          else
            log "Creating: #{object.key}"
            object.write(:file => file, :acl => @s3_permissions)
          end
        rescue Exception => e
          log e.message
        end
      end
    end

    def run_on_modifications(paths)
      paths.each do |path|
        file = resolve_file path
        object = resolve_object path
        begin
          if object.exists?
            if etag_match?(file, object)
              log "Unchanged: #{object.key}"
              # FIXME: update mtime
            else
              log "Updating: #{object.key}"
              object.write(:file => file, :acl => @s3_permissions)
            end
          else
            out_of_sync
          end
        rescue Exception => e
          log e.message
        end
      end
    end

    def run_on_removals(paths)
      paths.each do |path|
        file = resolve_file path
        object = resolve_object path
        begin
          if object.exists?
            log "Removing: #{object.key}"
            object.delete
          else
            out_of_sync
          end
        rescue Exception => e
          log e.message
        end
      end
    end

    def etag_match?(path, object)
      object = @bucket.objects[object] unless object.is_a? AWS::S3::S3Object
      Digest::MD5.hexdigest(File.read(path)) == object.etag.gsub('"','')
    end

    private

    def debug?
      @debug || false
    end

    def log(msg)
      return unless debug?
      puts "[#{Time.now}] #{msg}"
    end

    def resolve_file(path)
      File.join(@watchdir, path)
    end

    def resolve_object(path)
      dest_path = File.join(@prefix, path)
      if dest_path[0] == '/'
        dest_path[0] = ''
      end
      @bucket.objects[dest_path]
    end

    def out_of_sync
      log "Out of sync, forcing full sync."
      sync
    end

    def sync
      # FIXME: run a full sync
      log "Sync not yet implemented. You will need to manually sync this folder form S3."
    end
  end
end
