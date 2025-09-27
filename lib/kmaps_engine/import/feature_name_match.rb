require 'csv'
module KmapsEngine
  class FeatureNameMatch

    public

    def self.match(source, **options)
      options[:matched_filename] ||= "tmp/matched_name_results.csv"
      options[:unmatched_filename] ||= "tmp/unmatched_name_results.csv"
      matched_filename = Rails.root.join(options[:matched_filename]).to_s
      unmatched_filename = Rails.root.join(options[:unmatched_filename]).to_s
      limit = options[:limit].blank? ? false : options[:limit].to_i
      matched_items = []
      unmatched_items = []
      rows_done = 0
      rows = CSV.read(source, headers: false, col_sep: ",")
      rows.each do |columns|
        if !limit || (rows_done < limit)
          external_id = columns[0].strip
          name = format_name(columns[1])
          if name.is_tibetan_word?
            name = name.tibetan_cleanup
          end
          feature = find_feature_by_name(name)
          if feature.nil?
            second_name = format_name(columns[2]) unless columns[2].blank?
            feature = find_feature_by_name(second_name)
          end
          if feature.nil?
            unmatched_items << columns
          else
            matched_items.push([external_id, feature.fid])
          end
        end
        rows_done += 1
      end
      CSV.open(matched_filename, 'wb') do |csv|
        matched_items.each do |columns|
          csv << columns
        end
      end
      CSV.open(unmatched_filename, 'wb') do |csv|
        unmatched_items.each do |columns|
          csv << columns
        end
      end
      puts "- Found: #{matched_items.length}\n"
      puts "- Not found: #{unmatched_items.length}\n"
      puts "- Wrote matched results to:\n"
      puts "#{matched_filename}\n"
      puts "- Wrote unmatched results to:\n"
      puts "#{unmatched_filename}\n"
    end

    def self.find_feature_by_name(name_str)
      name = FeatureName.where(name: name_str).first
      name&.feature
    end

    def self.format_name(name)
      return nil if name.blank?
      name.strip!
      name.gsub!(/(^\/|\/$)/, '') unless name.nil?
      name
    end
  end
end
