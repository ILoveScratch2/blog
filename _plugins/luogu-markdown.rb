# frozen_string_literal: true

# Luogu-flavoured Markdown extensions for kramdown, mirroring the syntax that
# @luogu-saver-next/markdown-renderer accepts on Luogu:
#
#   :::info[标题]{title="..." open} … :::   提示块（可折叠）
#   :::align[center|left|right] … :::       块级对齐
#   :::epigraph{author="..."} … :::          题记
#   ::cute-table{tuack}                      紧跟其后的表格加样式
#   单元格内容恰为 ^ < > v                    与相邻单元格合并（\^ \< \> \v 为字面量）
#
# 通过 _config.yml 里的 `kramdown: input: Luogu` 启用。

require "kramdown"
# GFM 是 Jekyll 默认的 kramdown 解析器（提供 ``` 围栏代码块、删除线、表格等）；
# `input: Luogu` 覆盖默认值后必须显式继承它，否则这些语法会全部失效。
require "kramdown-parser-gfm"

module Kramdown
  module Parser
    class Luogu < GFM
      # 开头围栏：至少三个冒号 + 名字，可带 [标签] 和 {属性}
      # 标签里允许 `\]` `\[` 这类转义（洛谷标题常见，如 `\[CSP-S 2022\]`），
      # 否则 `[^\]\n]*` 会在转义括号处提前截断，整行匹配失败。
      CONTAINER_OPEN = /^ {0,3}(:{3,})([A-Za-z][\w-]*)(?:\[((?:\\.|[^\\\]\n])*)\])?(?:\{([^}\n]*)\})?[ \t]*\n/
      # 闭合围栏：整行只有冒号和空白
      FENCE_LINE = /^ {0,3}(:+)[ \t]*\n/
      CUTE_TABLE = /^ {0,3}::cute-table(?:\[((?:\\.|[^\\\]\n])*)\])?(?:\{([^}\n]*)\})?[ \t]*\n/

      # 洛谷允许围栏后跟空格分隔的参数（如 `line-numbers`、`lines=5-6`），但 GFM/kramdown
      # 的 info string 只接受单个 token，遇到空格整块会匹配失败退化成行内代码。
      # 这里放宽为「首个 token 作语言，其余忽略」。分组：\1 围栏 \2 围栏字符
      # \3 语言全串 \4 语言 \5 额外参数 \6 代码正文。
      FENCED_CODEBLOCK_MATCH =
        /^[ ]{0,3}(([~`]){3,})\s*?((\S+?)(?:\?\S*)?)?((?:[ \t]+\S+)*)?\s*?\n(.*?)^[ ]{0,3}\1\2*\s*?\n/m

      # 额外让指令行能打断上一段的惰性续行（与 kramdown 对定义列表的处理一致）。
      # GFM 已按 gfm_quirks 选好 @paragraph_end，这里只做并集。
      LUOGU_PARAGRAPH_END = Regexp.union(
        /^ {0,3}:{3,}[A-Za-z][\w-]*/,
        /^ {0,3}::cute-table/
      )

      ALIGN_DIRECTIONS = %w[center left right].freeze
      MERGE_MARKERS = ["^", "<", ">", "v"].freeze
      TABLE_SECTIONS = %i[thead tbody tfoot].freeze

      def initialize(source, options)
        super
        @block_parsers.unshift(:luogu_container, :luogu_cute_table)
        @paragraph_end = Regexp.union(@paragraph_end, LUOGU_PARAGRAPH_END)
      end

      # :::name[label]{attrs} … :::
      def parse_luogu_container
        return false unless @src.check(self.class::CONTAINER_OPEN)

        saved_pos = @src.save_pos
        start_line = @src.current_line_number
        fence_length = @src[1].length
        name = @src[2]
        label = @src[3]&.gsub(/\\([\[\]{}])/, '\1')
        attribute_string = @src[4]
        @src.pos += @src.matched_size

        body_lines = []
        depths = [fence_length]
        closed = false

        until @src.eos?
          line = @src.scan(/.*\n/) || @src.scan(/.*/)
          break if line.nil?

          # 更内层的容器开头：压栈，整行进 body 交给递归解析
          if (nested = self.class::CONTAINER_OPEN.match(line))
            depths << nested[1].length
            body_lines << line
            next
          end

          # 纯冒号行：够长就闭合最近的一层
          if (fence = self.class::FENCE_LINE.match(line)) && depths.last <= fence[1].length
            depths.pop
            if depths.empty?
              closed = true
              break
            end
          end

          body_lines << line
        end

        unless closed
          @src.revert_pos(saved_pos)
          warning("No closing fence found for :::#{name} on line #{start_line} - showing it literally")
          return false
        end

        attributes = {}
        parse_attribute_list(attribute_string.to_s, attributes)
        build_luogu_block(name, label, attributes, body_lines.join, start_line)
        true
      end
      define_parser(:luogu_container, CONTAINER_OPEN)

      # ::cute-table{tuack} —— 叶子指令，作用于紧随其后的表格
      def parse_luogu_cute_table
        return false unless @src.check(self.class::CUTE_TABLE)

        start_line = @src.current_line_number
        source_line = @src.scan(self.class::CUTE_TABLE)
        @tree.children << new_block_el(
          :eob, nil, nil,
          luogu_cute_table: true,
          luogu_source: source_line,
          location: start_line
        )
        true
      end
      define_parser(:luogu_cute_table, CUTE_TABLE)

      # 覆写 kramdown 的围栏代码块解析，改用本类的宽松 FENCED_CODEBLOCK_MATCH。
      # 复用 GFM 注册的 :codeblock_fenced_gfm（其 handler 名就是 parse_codeblock_fenced）。
      def parse_codeblock_fenced
        return false unless @src.check(self.class::FENCED_CODEBLOCK_MATCH)

        start_line_number = @src.current_line_number
        @src.pos += @src.matched_size
        el = new_block_el(:codeblock, @src[6], nil, location: start_line_number, fenced: true)
        lang = @src[3].to_s.strip
        unless lang.empty?
          el.options[:lang] = lang
          el.attr["class"] = "language-#{@src[4]}"
        end
        @tree.children << el
        true
      end

      protected

      def build_luogu_block(name, label, attributes, body, start_line)
        case name
        when "align"
          direction = ALIGN_DIRECTIONS.include?(label.to_s) ? label.to_s : "center"
          element = new_block_el(
            :html_element, "div",
            { "class" => "md-align-#{direction}" },
            category: :block, content_model: :block, location: start_line
          )
          @tree.children << element
          parse_blocks(element, body)
        when "epigraph"
          element = new_block_el(
            :html_element, "blockquote",
            { "class" => "md-epigraph" },
            category: :block, content_model: :block, location: start_line
          )
          @tree.children << element
          parse_blocks(element, body)
          author = attributes["author"]
          author = label if (author.nil? || author.empty?) && label && !label.empty?
          if author && !author.empty?
            cite = Element.new(:html_element, "cite",
                               { "class" => "md-epigraph-author" }, category: :block)
            cite.children << Element.new(:text, author.to_s)
            element.children << cite
          end
        else
          build_admonition(name, label, attributes, body, start_line)
        end
      end

      def build_admonition(name, label, attributes, body, start_line)
        title = attributes["title"]
        title = label if (title.nil? || title.empty?) && label && !label.empty?
        title = name.upcase if title.nil? || title.empty?
        open_attribute = attributes[:refs]&.include?("open") ? { "open" => "open" } : {}

        container = new_block_el(
          :html_element, "div",
          { "class" => "md-block md-block-#{name}" },
          category: :block, content_model: :block, location: start_line
        )
        details = Element.new(:html_element, "details", open_attribute,
                              category: :block, content_model: :block)
        summary = Element.new(:html_element, "summary", { "class" => "md-title" },
                              category: :block)
        summary.children << Element.new(:text, title.to_s)
        body_element = Element.new(:html_element, "div", { "class" => "md-body" },
                                   category: :block, content_model: :block,
                                   location: start_line + 1)
        details.children << summary << body_element
        container.children << details
        @tree.children << container
        parse_blocks(body_element, body)
      end

      # ---- 整树后处理：在 span 解析之前跑一次，此时表格单元格仍是 :raw_text ----

      def update_tree(element)
        postprocess_tree(@root) if element.equal?(@root)
        super
      end

      def postprocess_tree(element)
        children = element.children
        index = 0
        while index < children.length
          node = children[index]
          if node.type == :eob && node.options[:luogu_cute_table]
            # 跳过中间的空行，寻找紧随其后的表格
            lookahead = index + 1
            lookahead += 1 while children[lookahead]&.type == :blank
            following = children[lookahead]
            if following && following.type == :table
              add_class(following, "cute-table")
              children.delete_at(index)
            else
              paragraph = Element.new(:p, nil, nil, location: node.options[:location])
              paragraph.children << Element.new(:raw_text, node.options[:luogu_source].to_s.strip)
              children[index] = paragraph
              index += 1
            end
          elsif node.type == :table
            postprocess_table(node)
            index += 1
          else
            postprocess_tree(node)
            index += 1
          end
        end
      end

      def postprocess_table(table)
        rows = collect_rows(table)
        return if rows.empty?

        # owners 记录「原始单元格位置 → 幸存单元格」，这样删格后纵向链（^ / v）仍能找到邻居。
        owners = rows.map(&:dup)
        removed = {}

        rows.each_with_index do |row, row_index|
          row.each_with_index do |cell, cell_index|
            next if removed[cell.object_id]

            marker = cell_marker(cell)
            next unless marker

            target =
              case marker
              when "^" then owner_at(owners, removed, row_index - 1, cell_index)
              when "<" then owner_at(owners, removed, row_index, cell_index - 1)
              when ">" then owner_at(owners, removed, row_index, cell_index + 1)
              when "v" then owner_at(owners, removed, row_index + 1, cell_index)
              end
            next unless target

            case marker
            when "^"
              add_class(target, "md-table-merged-cell")
              bump_span(target, "rowspan")
              removed[cell.object_id] = true
              owners[row_index][cell_index] = target
            when "<"
              add_class(target, "md-table-merged-cell")
              bump_span(target, "colspan")
              removed[cell.object_id] = true
              owners[row_index][cell_index] = target
            when ">"
              cell.children = target.children
              add_class(cell, "md-table-merged-cell")
              bump_span(cell, "colspan")
              removed[target.object_id] = true
              owners[row_index][cell_index] = cell
              owners[row_index][cell_index + 1] = cell
            when "v"
              cell.children = target.children
              add_class(cell, "md-table-merged-cell")
              bump_span(cell, "rowspan")
              removed[target.object_id] = true
              owners[row_index][cell_index] = cell
              owners[row_index + 1][cell_index] = cell
            end
          end
        end

        rows.each { |row| row.reject! { |cell| removed[cell.object_id] } }
        rows.each { |row| row.each { |cell| unescape_cell(cell) } }
        repair_alignment(table, rows) unless removed.empty?
      end

      def owner_at(owners, removed, row_index, cell_index)
        return nil if row_index.negative? || cell_index.negative?

        row = owners[row_index]
        return nil unless row

        cell = row[cell_index]
        return nil unless cell
        return nil if removed[cell.object_id]

        cell
      end

      def bump_span(cell, attribute)
        cell.attr[attribute] = span_of(cell, attribute) + 1
      end

      def collect_rows(table)
        rows = []
        table.children.each do |section|
          next unless TABLE_SECTIONS.include?(section.type)

          section.children.each do |row_node|
            rows << row_node.children if row_node.type == :tr
          end
        end
        rows
      end

      def cell_marker(cell)
        children = cell.children
        return nil unless children && children.length == 1

        child = children.first
        return nil unless child.type == :raw_text

        MERGE_MARKERS.include?(child.value) ? child.value : nil
      end

      def unescape_cell(cell)
        cell.children.each do |child|
          next unless child.type == :raw_text

          child.value = child.value.gsub(/\\([\^v])/, '\1')
        end
      end

      def span_of(cell, attribute)
        value = cell.attr[attribute]
        value ? value.to_i : 1
      end

      def add_class(element, extra)
        classes = element.attr["class"].to_s.split
        classes << extra unless classes.include?(extra)
        element.attr["class"] = classes.join(" ")
      end

      # convert_td 用单元格在行内的下标取对齐方式，删格后会错位，
      # 因此按「视觉列」把对齐写成内联 style，并把表格对齐定义重置为默认。
      def repair_alignment(table, rows)
        alignment = table.options[:alignment]
        return unless alignment.is_a?(Array)
        return unless alignment.any? { |value| value && value != :default }

        rows.each do |row|
          column = 0
          row.each do |cell|
            value = alignment[column]
            if value && value != :default
              style_text = "text-align: #{value}"
              existing = cell.attr["style"]
              cell.attr["style"] = existing && !existing.empty? ? "#{existing}; #{style_text}" : style_text
            end
            column += span_of(cell, "colspan")
          end
        end
        table.options[:alignment] = Array.new(alignment.length, :default)
      end
    end
  end
end
