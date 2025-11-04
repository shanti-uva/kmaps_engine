xml.instruct!
xml << render(partial: 'recursive_stripped_feature', formats: [:xml], locals: {feature: @feature})