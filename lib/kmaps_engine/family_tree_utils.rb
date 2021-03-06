require 'kmaps_engine/progress_bar'

module KmapsEngine
  class FamilyTreeUtils
    include KmapsEngine::ProgressBar
    
    def reset_feature_ancestor_ids(from:, to:, daylight:)
      from_i = from.blank? ? nil : from.to_i
      to_i = to.blank? ? nil : to.to_i
      features = Feature.where(is_public: true).order(:fid)
      features = features.where(['fid >= ?', from_i]) if !from_i.nil?
      features = features.where(['fid <= ?', to_i]) if !to_i.nil?
      i = 0
      self.log.debug { "#{Time.now}: Starting reseting ancestor ids." }
      total = features.size
      puts "#{Time.now}: Reseting ancestor ids for #{total} features about to start..."
      self.wait_if_business_hours(daylight)
      features.each do |f|
        begin
          f.update_ancestor_ids
          self.log.debug { "#{Time.now}: Ancestor ids reset for #{f.pid}." }
          self.progress_bar(num: i, total: total, current: f.pid)
        rescue Exception => e
          STDOUT.flush
          self.log.fatal { "#{Time.now}: An error occured when processing #{Process.pid}:" }
          self.say "#{Time.now}: #{f.pid} ancestor ids reset failed."
          self.log.fatal { e.message }
          self.log.fatal { e.backtrace.join("\n") }
        end
        i += 1
      end
      puts "#{Time.now}: Ancestor ids reset done."
      self.log.debug "#{Time.now}: Resetting ancestor ids done."
    end
    
    def reindex_fids(fids, daylight)
      i = 0
      view = View.get_by_code('roman.scholar')
      total = fids.size
      puts "#{Time.now}: Indexing of #{total} items about to start..."
      self.log.debug { "#{Time.now}: Starting reindexing." }
      self.log.debug { "#{Time.now}: Features to index: #{fids.join(', ')}." }
      self.wait_if_business_hours(daylight)
      fids.each do |fid|
        begin
          f = Feature.get_by_fid(fid)
          if f.queued_index(priority: Flare::IndexerJob::LOW)
            name = f.prioritized_name(view)
            self.log.debug { "#{Time.now}: Reindexed #{name.name if !name.blank?} (#{f.pid})." }
          else
            self.say "#{Time.now}: #{f.pid} failed."
          end
          self.progress_bar(num: i, total: total, current: f.pid)
        rescue Exception => e
          self.log.fatal { "#{Time.now}: An error occured when processing #{Process.pid}:" }
          self.say "#{Time.now}: #{f.pid} failed."
          self.log.fatal { e.message }
          self.log.fatal { e.backtrace.join("\n") }
        end
        i += 1
      end
      puts "#{Time.now}: Reindexing done."
      self.log.debug "#{Time.now}: Reindexing done."
    end
  end
end