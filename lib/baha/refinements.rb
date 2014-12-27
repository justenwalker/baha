module Baha::Refinements
  refine Hash do
    # Allow hash to use symbol keys or string keys
    def [](key)
      super(key.to_s) || super(key.to_sym)
    end
    # Pick the first key that exists in the hash
    # If none of them exist, return the default
    def pick(keys,default = nil)
      k = keys.find { |x| self.has_key?(x) }
      if not k.nil?
        self[k]
      else
        default
      end
    end
  end
end
