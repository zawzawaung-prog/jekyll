# frozen_string_literal: true

module Jekyll
  class Profiler
    class Table
      def initialize(stats)
        @stats = stats
      end

      def to_s(n = 50)
        data = data_for_table(n)
        widths = table_widths(data)
        generate_table(data, widths)
      end

      private

      def generate_table(data, widths)
        str = String.new("\n")

        table_head = data.shift
        str << generate_row(table_head, widths)
        str << generate_table_head_border(table_head, widths)

        data.each do |row_data|
          str << generate_row(row_data, widths)
        end

        str << "\n"
        str
      end

      def generate_table_head_border(row_data, widths)
        str = String.new("")

        row_data.each_index do |cell_index|
          str << "-" * widths[cell_index]
          str << "-+-" unless cell_index == row_data.length - 1
        end

        str << "\n"
        str
      end

      def generate_row(row_data, widths)
        str = String.new("")

        row_data.each_with_index do |cell_data, cell_index|
          str << if cell_index.zero?
                   cell_data.ljust(widths[cell_index], " ")
                 else
                   cell_data.rjust(widths[cell_index], " ")
                 end

          str << " | " unless cell_index == row_data.length - 1
        end

        str << "\n"
        str
      end

      def table_widths(data)
        widths = []

        data.each do |row|
          row.each_with_index do |cell, index|
            widths[index] = [ cell.length, widths[index] ].compact.max
          end
        end

        widths
      end

      def data_for_table(n)
        sorted = @stats.sort_by { |_, file_stats| -file_stats[:rendering][:time] }
        sorted = sorted.slice(0, n)

        totals = {
          :rendering => {
            :count => 0,
            :bytes => 0,
            :time  => 0,
          },
          :markdown => {
            :count => 0,
            :bytes => 0,
            :time  => 0,
          },
          :liquid => {
            :bytes => 0,
            :count => 0,
            :time  => 0,
          }
        }

        # "Markdown Count", "Markdown Bytes", "Markdown Time", "Liquid Count", "Liquid Bytes", "Liquid Time"
        table = [["Filename", "Count", "Bytes", "Time"]]

        sorted.each do |filename, file_stats|
          table << build_row(filename, file_stats)

          # :markdown, :liquid
          [:rendering].each do |context|
            [:count, :bytes, :time].each do |metric|
              totals[context][metric] += file_stats[context][metric]
            end
          end
        end

        table << build_row("TOTAL", totals)

        table
      end

      def build_row(filename, file_stats)
        # [
        #   filename,
        # file_stats[:markdown][:count].to_s,
        # format_bytes(file_stats[:markdown][:bytes]),
        # format("%.3f", file_stats[:markdown][:time]),
        #   file_stats[:liquid][:count].to_s,
        #   format_bytes(file_stats[:liquid][:bytes]),
        #   format("%.3f", file_stats[:liquid][:time]),
        # ]
        [
          filename,
          file_stats[:rendering][:count].to_s,
          format_bytes(file_stats[:rendering][:bytes]),
          format("%.3f", file_stats[:rendering][:time]),
        ]
      end

      def format_bytes(bytes)
        bytes /= 1024.0
        format("%.2fK", bytes)
      end
    end
  end
end