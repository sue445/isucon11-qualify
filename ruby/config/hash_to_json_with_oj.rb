require "oj"

::Oj.default_options = { mode: :compat }

module HashToJsonWithOj
  refine(Hash) do
    def to_json
      Oj.dump(self)
    end
  end
end
