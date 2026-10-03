class GameData::Item
  alias __azerita_consumed_after_use__ consumed_after_use? unless method_defined?(:__azerita_consumed_after_use__)

  def consumed_after_use?
    return false if @id.to_s.start_with?("TM")
    return __azerita_consumed_after_use__
  end
end