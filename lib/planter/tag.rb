# frozen_string_literal: true

module Planter
  #
  # File tagging module
  #
  # @author Brett Terpstra <me@brettterpstra.com>
  #
  module Tag
    # File tagging class
    class << self
      #
      # Set tags on target file.
      #
      # @param target [String] path to target file
      # @param tags [Array] Array of tags to set
      #
      # @return [Boolean] success
      #
      def set(target, tags)
        return false unless TTY::Which.exist?('xattr')

        tags = [tags] unless tags.is_a?(Array)

        set_tags(target, tags)
        $? == 0
      end

      # Add tags to a directory.
      #
      # @param target [String] The directory to tag.
      # @param tags [Array<String>] The tags to add.
      #
      # @return [Boolean] Success.
      #
      def add(target, tags)
        return false unless TTY::Which.exist?('xattr')

        tags = [tags] unless tags.is_a?(Array)
        existing_tags = get(target)
        tags.concat(existing_tags).uniq!

        set_tags(target, tags)

        res = $? == 0

        if res
          Planter.notify("[Added tags] to #{target}", :debug, above_spinner: true)
        else
          Planter.notify("Failed to add tags to #{target}", :error)
        end

        res
      end

      #
      # Get tags on target file.
      #
      # @param target [String] target file path
      #
      # @return [Array] Array of tags
      #
      def get(target)
        return false unless TTY::Which.exist?('xattr')

        res = `xattr -p com.apple.metadata:_kMDItemUserTags "#{target}" 2>/dev/null`.clean_encode
        return [] if res =~ /no such xattr/ || res.empty?

        tags = Plist.parse_xml(res)

        return false if tags.nil?

        tags
      end

      #
      # Copy tags from one file to another.
      #
      # @param source [String] path to source file
      # @param target [String] path to target file
      #
      # @return [Boolean] success
      #
      def copy(source, target)
        return false unless TTY::Which.exist?('xattr')

        tags = `xattr -px com.apple.metadata:_kMDItemUserTags "#{source}" 2>/dev/null`
        `xattr -wx com.apple.metadata:_kMDItemUserTags "#{tags}" "#{target}"`
        res = $? == 0

        if res
          Planter.notify("[Copied tags] from #{source} to #{target}", :debug, above_spinner: true)
        else
          Planter.notify("Failed to copy tags from #{source} to #{target}", :error)
        end

        res
      end

      private

      #
      # Set tags on target file.
      #
      # @param target [String] file path
      # @param tags   [Array] Array of tags
      #
      # @return [Boolean] success
      #
      # @api private
      #
      def set_tags(target, tags)
        return false unless TTY::Which.exist?('xattr')

        tags.map! { |tag| "<string>#{tag}</string>" }
        `xattr -w com.apple.metadata:_kMDItemUserTags '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
          <array>#{tags.join}</array>
        </plist>' "#{target}"`

        res = $? == 0

        if res
          Planter.notify("[Set tags] on #{target}", :debug, above_spinner: true)
        else
          Planter.notify("Failed to set tags on #{target}", :error)
        end

        res
      end
    end
  end
end
