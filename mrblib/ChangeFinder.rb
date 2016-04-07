class ChangeFinder
  def initialize(outlier_term, outlier_discount_param, change_point_term, change_point_discount_param, smooth_term)
    @outlier_analyze = ChangeFinder::SDAR.new outlier_term, outlier_discount_param
    @change_point_analyze = ChangeFinder::SDAR.new change_point_term, change_point_discount_param
    @smooth_term = smooth_term.to_i
    @ts_data_buffer = []
  end

  def score x
    # first learning as outlier score
    o = @outlier_analyze.next x

    # smooth outlier score time series data
    @ts_data_buffer.push o
    @ts_data_buffer.shift if @ts_data_buffer.size > @smooth_term
    smoothed_o = Utils.smooth @ts_data_buffer, @smooth_term

    # second learning as change point score
    @change_point_analyze.next smoothed_o
  end

  def learn data
    data.inject([]) { |result, x| result << score(x) }
  end

  def dump
    {:outlier => @outlier_analyze.dump, :change_point => @change_point_analyze.dump, :ts_data_buffer => @ts_data_buffer}
  end

  def restore d
    @outlier_analyze.restore d[:outlier]
    @change_point_analyze.restore d[:change_point]
    @ts_data_buffer = d[:ts_data_buffer]
  end

  def status
    [{:outlier_data => @ts_data_buffer}, @outlier_analyze.show_status, @change_point_analyze.show_status]
  end
end
