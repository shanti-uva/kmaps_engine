require 'kmaps_engine/progress_bar'

module KmapsEngine
  class FlareUtils
    include KmapsEngine::ProgressBar
    
    INTERVAL = 100
    
    def reindex_all(from:, to:, daylight:)
      from_i = from.blank? ? nil : from.to_i
      to_i = to.blank? ? nil : to.to_i
      features = Feature.where(is_public: true).order(:fid)
      features = features.where(['fid >= ?', from_i]) if !from_i.nil?
      features = features.where(['fid <= ?', to_i]) if !to_i.nil?
      count = 0
      current = 0
      self.log.debug { "#{Time.now}: Starting reindexing." }
      ipc_reader, ipc_writer = IO.pipe('ASCII-8BIT')
      ipc_writer.set_encoding('ASCII-8BIT')
      total = features.size
      puts "#{Time.now}: Indexing of #{total} features about to start..."
      STDOUT.flush
      while current< total
        limit = current + INTERVAL
        limit = total if limit > total
        self.wait_if_business_hours(daylight)
        sid = Spawnling.new do
          self.log.debug { "#{Time.now}: Spawning sub-process #{Process.pid}." }
          for i in current...limit
            begin
              f = features[i]
              if f.index
                self.log.debug { "#{Time.now}: Reindexed #{f.pid}." }
              else
                self.say "#{Time.now}: #{f.pid} failed."
              end
              self.progress_bar(num: i, total: total, current: f.pid)
            rescue Exception => e
              STDOUT.flush
              self.log.fatal { "#{Time.now}: An error occured when processing #{Process.pid}:" }
              self.say "#{Time.now}: #{f.pid} failed."
              self.log.fatal { e.message }
              self.log.fatal { e.backtrace.join("\n") }
            end
          end
          Feature.commit
          ipc_hash = { bar: self.bar, num_errors: self.num_errors, valid_point: self.valid_point }
          data = Marshal.dump(ipc_hash)
          ipc_writer.puts(data.length)
          ipc_writer.write(data)
          ipc_writer.flush
          ipc_writer.close
        end
        Spawnling.wait([sid])
        size = ipc_reader.gets
        data = ipc_reader.read(size.to_i)
        ipc_hash = Marshal.load(data)
        self.update_progress_bar(bar: ipc_hash[:bar], num_errors: ipc_hash[:num_errors], valid_point: ipc_hash[:valid_point])
        current = limit
      end
      ipc_writer.close
      puts "#{Time.now}: Reindexing done."
      self.log.debug "#{Time.now}: Reindexing done."
      STDOUT.flush
    end
    
    def reindex_fids(fids, daylight)
      count = 0
      current = 0
      view = View.get_by_code('roman.scholar')
      ipc_reader, ipc_writer = IO.pipe('ASCII-8BIT')
      ipc_writer.set_encoding('ASCII-8BIT')
      total = fids.size
      puts "#{Time.now}: Indexing of #{total} items about to start..."
      self.log.debug { "#{Time.now}: Starting reindexing." }
      self.log.debug { "#{Time.now}: Features to index: #{fids.join(', ')}." }
      STDOUT.flush
      while current<total
        limit = current + INTERVAL
        limit = total if limit > total
        self.wait_if_business_hours(daylight)
        sid = Spawnling.new do
          self.log.debug { "#{Time.now}: Spawning sub-process #{Process.pid}." }
          for i in current...limit
            begin
              fid = fids[i]
              f = Feature.get_by_fid(fid)
              if f.index
                name = f.prioritized_name(view)
                self.log.debug { "#{Time.now}: Reindexed #{name.name if !name.blank?} (#{f.pid})." }
              else
                self.say "#{Time.now}: #{f.pid} failed."
              end
              self.progress_bar(num: i, total: total, current: f.pid)
            rescue Exception => e
              STDOUT.flush
              self.log.fatal { "#{Time.now}: An error occured when processing #{Process.pid}:" }
              self.say "#{Time.now}: #{f.pid} failed."
              self.log.fatal { e.message }
              self.log.fatal { e.backtrace.join("\n") }
            end
          end
          Feature.commit
          ipc_hash = { bar: self.bar, num_errors: self.num_errors, valid_point: self.valid_point }
          data = Marshal.dump(ipc_hash)
          ipc_writer.puts(data.length)
          ipc_writer.write(data)
          ipc_writer.flush
          ipc_writer.close
        end
        Spawnling.wait([sid])
        size = ipc_reader.gets
        data = ipc_reader.read(size.to_i)
        ipc_hash = Marshal.load(data)
        self.update_progress_bar(bar: ipc_hash[:bar], num_errors: ipc_hash[:num_errors], valid_point: ipc_hash[:valid_point])
        current = limit
      end
      ipc_writer.close
      puts "#{Time.now}: Reindexing done."
      self.log.debug "#{Time.now}: Reindexing done."
      STDOUT.flush
    end
  end
end
