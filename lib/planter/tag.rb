# frozen_string_literal: true

module Planter
  module Tag
    class << self
      def set(target, tags)
        tags = [tags] unless tags.is_a?(Array)

        set_tags(target, tags)
        $? == 0
      end

      # Add tags to a directory.
      #
      # @param dir [String] The directory to tag.
      # @param tags [Array<String>] The tags to add.
      def add(target, tags)
        tags = [tags] unless tags.is_a?(Array)
        existing_tags = get(target)
        tags.concat(existing_tags).uniq!

        set_tags(target, tags)
        $? == 0
      end

      def get(target)
        res = `xattr -p com.apple.metadata:_kMDItemUserTags "#{target}" 2>/dev/null`.clean_encode
        return [] if res =~ /no such xattr/ || res.empty?

        tags = Plist.parse_xml(res)

        return false if tags.nil?

        tags
      end

      def copy(source, target)
        tags = `xattr -px com.apple.metadata:_kMDItemUserTags "#{source}" 2>/dev/null`
        `xattr -wx com.apple.metadata:_kMDItemUserTags "#{tags}" "#{target}"`
        $? == 0
      end

      private

      def set_tags(target, tags)
        tags.map! { |tag| "<string>#{tag}</string>" }
        `xattr -w com.apple.metadata:_kMDItemUserTags '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
          <array>#{tags.join}</array>
        </plist>' "#{target}"`
      end
    end
  end
end
