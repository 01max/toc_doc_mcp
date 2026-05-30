# frozen_string_literal: true

module TocdocMcp
  class Error < StandardError
    attr_reader :category

    def initialize(message, category:)
      super(message)
      @category = category
    end
  end

  class ValidationError < Error
    def initialize(message)
      super(message, category: "validation_error")
    end
  end

  class NotFoundError < Error
    def initialize(message = "Requested public resource was not found")
      super(message, category: "not_found")
    end
  end

  class UpstreamError < Error
    def initialize(message = "Upstream public source failed")
      super(message, category: "upstream_error")
    end
  end

  class TimeoutError < Error
    def initialize(message = "Upstream public source timed out")
      super(message, category: "timeout")
    end
  end
end
