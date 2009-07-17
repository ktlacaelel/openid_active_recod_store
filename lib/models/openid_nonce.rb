class OpenidNonce < OpenidAbstract

  # attempt to scan timestamps (integers) first for fast access.
  def self.exists_by_target?(timestamp, salt, target)
    count(:conditions => ['timestamp = ? and target = ? ', timestamp, target]) > 0
  end

end
