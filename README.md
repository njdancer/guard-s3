# guard-s3

guard-s3 is a simple guard library that syncs local directories with S3 as files are changed.

# Usage

This is a sample Guardfile that will automatically upload all files in the Guard *watchdir* directory into the specified S3 bucket. By default, *watchdir* is the directory from which guard was called, but it can be specified using the `--watchdir/-w` parameter.  See the [guard main documentation for details](https://github.com/guard/guard#guard----).

    opts = {
      :access_key_id      => 'ACCESS_KEY_ID_XXXXXX',
      :secret_access_key  => 'SECRET_ACCESS_KEY_XXXXXXXXXXXXXXXXXXXXXX',
      :bucket             => "mybucket",
      :s3_permissions     => :public_read
    }
    
    guard 's3', opts do
      watch(/.*/)
    end

`prefix` is supported as a an option prefix to the key created on S3. e.g. `/prefix/path/to/file.txt`

# Dependencies

 - guard
 - aws-sdk

# Changelog

### 0.1.3 
  - Added `prefix` to prefix S3 key.
  - Compare file etag and upload if different (or not present).
  - Support Guard v2.
  - Switch to using Amazon aws-sdk for Ruby.

### 0.1.2
 - Fixed `watchdir` behavior. Guard-s3 will now watch and upload from the directory path specified in the Guardfile relative to the guard `watchdir`.