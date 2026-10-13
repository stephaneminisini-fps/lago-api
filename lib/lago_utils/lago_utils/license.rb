# frozen_string_literal: true

module LagoUtils
  class License
    def initialize
      @premium = false
    end

    # Premium features are unlocked unconditionally; no remote license check is performed.
    def verify
      @premium = true
    end

    def premium?
      premium
    end

    private

    attr_reader :premium
  end
end
