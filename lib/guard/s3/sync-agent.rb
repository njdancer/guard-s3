module Guard
  class S3 < Plugin
    class SyncAgent

      def initialize(options = {})
        @bucket         = options[:bucket]
        @debug          = options[:debug]
        @prefix         = options[:prefix]
        @s3             = options[:s3]
        @s3_permissions = options[:s3_permissions]
        @watchdir       = options[:watchdir]
        @watchers       = options[:watchers]
      end

      def sync
        log "Syncing: calculating differences..."
        remote_files = list_remote
        local_files = list_local

        upload_list = local_files - remote_files
        download_list = remote_files - local_files

        new_upload_count = upload_list.length
        new_download_count = download_list.length

        comparison_list = local_files & remote_files
        comparison_list.each do |file|
          if etag_match? file
            # TODO: Check mtime and update whichever is older
            break
          else
            if File.mtime file > @bucket.objects[file].last_modified
              upload_list << file
            else
              download_list << file
            end
          end
        end

        modified_upload_count = upload_list.length - new_upload_count
        modified_download_count = download_list.length - new_download_count

        log "Syncing: Uploading #{upload_list.length} files(#{new_upload_count} new, #{modified_upload_count} modified)"
        log "Syncing: Downloading #{download_list.length} files(#{new_download_count} new, #{modified_download_count} modified)"

        upload_list.each do |path|
          upload File.join(@watchdir, path), path
        end
        download_list.each do |path|
          download File.join(@watchdir, path), path
        end

      end

      private

      def is_watched?(file)
        @watchers.any? { |watcher| watcher.pattern.match file }
      end

      def etag_match?(file)
        Digest::MD5.hexdigest(File.read(File.join(@watchdir, file))) == @bucket.objects[file].etag.gsub('"','')
      end

      def list_remote
        @bucket.objects.with_prefix(@prefix).to_a.collect(&:key).find_all do |file|
          file[-1] != '/' && is_watched?(file)
        end
      end

      def list_local
        files = Dir["#{@watchdir}/**/*"]
        files = files.find_all do |file|
          File.file? file
        end
        files = files.collect do |file|
          relative_path = file.gsub @watchdir, ""
          if relative_path[0] = '/' then relative_path[0] = '' end
          relative_path
        end
        files = files.find_all do |file|
          is_watched? file
        end
        files
      end

      def upload(file, key)
        log "Uploading: #{key}"
        @bucket.objects[key].write(:file => file, :acl => @s3_permissions)
      end

      def download(file, key)
        log "Downloading: #{key}"
        FileUtils.mkdir_p File.dirname(file)
        File.write(file, @bucket.objects[key].read)
      end

      def log(msg)
        return unless @debug
        puts "[#{Time.now}] #{msg}"
      end

    end
  end
end
