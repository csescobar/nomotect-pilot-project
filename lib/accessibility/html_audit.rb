module Accessibility
  class HtmlAudit
    Violation = Data.define(:rule, :message)

    def initialize(html)
      @document = Nokogiri::HTML.fragment(html)
    end

    def violations
      duplicate_ids + unlabeled_controls + unnamed_interactives + broken_aria_references + heading_violations
    end

    def valid?
      violations.empty?
    end

    private

    attr_reader :document

    def duplicate_ids
      document.css("[id]").group_by { |node| node["id"] }.filter_map do |id, nodes|
        Violation.new(rule: :duplicate_id, message: "Duplicate id: #{id}") if nodes.size > 1
      end
    end

    def unlabeled_controls
      selector = "input:not([type='hidden']):not([type='submit']):not([type='button']):not([type='reset']):not([type='image']), select, textarea"

      document.css(selector).filter_map do |control|
        next if control["aria-label"].present? || labelled_by?(control)
        next if control["id"].present? && label_for?(control["id"])

        Violation.new(rule: :control_label, message: "Control has no accessible label: #{control.name}##{control['id']}")
      end
    end

    def unnamed_interactives
      document.css("button, a[href], input[type='submit'], input[type='button'], input[type='reset'], input[type='image']").filter_map do |node|
        next if node.text.squish.present? || node["value"].present? || node["alt"].present?
        next if node["aria-label"].present? || labelled_by?(node)

        Violation.new(rule: :accessible_name, message: "Interactive element has no accessible name: #{node.name}")
      end
    end

    def broken_aria_references
      document.css("[aria-labelledby], [aria-describedby], [aria-controls]").flat_map do |node|
        %w[aria-labelledby aria-describedby aria-controls].flat_map do |attribute|
          node[attribute].to_s.split.filter_map do |id|
            next if node_with_id?(id)

            Violation.new(rule: :aria_reference, message: "#{attribute} references missing id: #{id}")
          end
        end
      end
    end

    def heading_violations
      levels = document.css("h1, h2, h3, h4, h5, h6").map { |heading| heading.name.delete_prefix("h").to_i }
      levels.each_cons(2).filter_map do |previous, current|
        Violation.new(rule: :heading_order, message: "Heading level jumps from h#{previous} to h#{current}") if current > previous + 1
      end
    end

    def labelled_by?(node)
      node["aria-labelledby"].to_s.split.any? { |id| node_with_id?(id) }
    end

    def label_for?(id)
      document.xpath(".//label[@for=$id]", nil, id: id).any?
    end

    def node_with_id?(id)
      document.xpath(".//*[@id=$id]", nil, id: id).any?
    end
  end
end
