# frozen_string_literal: true

module Releases
  class ChangeCatalog
    def initialize(path: Rails.root.join("changes"))
      @path = Pathname(path)
    end

    def fragments
      load_paths(path.glob("*.yml"))
    end

    def released_fragments
      archive_path = path.join("archive")
      return {} unless archive_path.directory?

      groups = archive_path.children.select(&:directory?).sort.to_h do |directory|
        Platform::Version.new(directory.basename.to_s)
        [ directory.basename.to_s, load_paths(directory.glob("*.yml")) ]
      end
      duplicates = groups.values.flatten.group_by(&:id).select { |_id, items| items.many? }.keys
      raise DuplicateFragment, "duplicate archived fragment ids: #{duplicates.join(', ')}" if duplicates.any?

      groups.freeze
    end

    private

    attr_reader :path

    def load_paths(paths)
      loaded = paths.sort.map { |file| ChangeFragment.load(file) }
      duplicates = loaded.group_by(&:id).select { |_id, items| items.many? }.keys
      raise DuplicateFragment, "duplicate change fragment ids: #{duplicates.join(', ')}" if duplicates.any?

      loaded.freeze
    end

    class DuplicateFragment < StandardError; end
  end
end
