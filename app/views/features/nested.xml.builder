xml.instruct!
xml << render(partial: 'recursive_nested_feature', formats: [:xml], locals: {feature: @feature})