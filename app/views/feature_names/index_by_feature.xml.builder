xml.instruct!
xml << render(partial: 'index', formats: [:xml], locals: { names: @names })