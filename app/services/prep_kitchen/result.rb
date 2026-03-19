module PrepKitchen
  class Result
    attr_reader :data, :error

    def initialize(success:, data: nil, error: nil)
      @success = success
      @data = data
      @error = error
    end

    def success?
      @success
    end

    def self.success(data = nil)
      new(success: true, data: data)
    end

    def self.failure(error)
      new(success: false, error: error)
    end
  end
end
